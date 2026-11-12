# SPDX-License-Identifier: LGPL-2.1-or-later

# ***************************************************************************
# *   Copyright (c) 2017 sliptonic <shopinthewoods@gmail.com>               *
# *                                                                         *
# *   This file is part of the FreeCAD CAx development system.              *
# *                                                                         *
# *   This program is free software; you can redistribute it and/or modify  *
# *   it under the terms of the GNU Lesser General Public License (LGPL)    *
# *   as published by the Free Software Foundation; either version 2 of     *
# *   the License, or (at your option) any later version.                   *
# *   for detail see the LICENCE text file.                                 *
# *                                                                         *
# *   FreeCAD is distributed in the hope that it will be useful,            *
# *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
# *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
# *   GNU Lesser General Public License for more details.                   *
# *                                                                         *
# *   You should have received a copy of the GNU Library General Public     *
# *   License along with FreeCAD; if not, write to the Free Software        *
# *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  *
# *   USA                                                                   *
# *                                                                         *
# ***************************************************************************


from typing import Any, Dict, List, Optional

from Path.Post.Processor import PostProcessor
from Path.Post.CAMErrors import CAMValueError
from Path.Post.Processor import PostProcessor, SCOPE_JOB, SCOPE_MACHINE

import Path
import FreeCAD
import fnmatch
from FreeCAD import Units
from Machine.models.machine import OutputUnits

translate = FreeCAD.Qt.translate

DEBUG = False
if DEBUG:
    Path.Log.setLevel(Path.Log.Level.DEBUG, Path.Log.thisModule())
    Path.Log.trackModule(Path.Log.thisModule())
else:
    Path.Log.setLevel(Path.Log.Level.INFO, Path.Log.thisModule())

# Define some types that are used throughout this file.
Values = Dict[str, Any]

POST_TYPE = "machine"

class Makera(PostProcessor):
    """
    The Makera CNC post processor class.

    Targets a Makera CNC machine running a smoothieware-based controller.
    Two things make this controller different from a "generic" 3 axis mill:

    - It has no support for canned drilling cycles (G81/G82/G83) or for
      tool length offsets (G43), so both are expanded/suppressed rather
      than being emitted directly.

    """

    GCodeSupported_Stock = set(
    "G0 G00 G1 G01 G2 G02 G3 G03 G4 G04 G10 G17 G18 G19 G20 G21 G28 G29 G30 G38 G38.2 G38.3 G38.4 G38.5 G38.6 G53 G54 "
    "M1 M2 M3 M4 M5 M6 M7 M8 M9 M30 M220 M223 M321 M323 M324 M325 M331 M331.1 M331.2 M331.3 M331.4 M332 M332.1 M332.2 M332.3 M332.4 "
    "M485 M485.1 M485.2 M485.3 M485.4 M485.5 M485.6 M485.7 M485.8 M485.9 M485.10 M486.1 " 
    "M491 M600 M670 M801 M802 M811 M812 M821 M822"
    .rstrip().split(
        " "
    )
    )
    ""

    GCodeSupported_Community = GCodeSupported_Stock.union(set(
        "G55 G56 G57 G58 G59 G90 G92.4 G93 G94 G95 " 
        "M97 M98 M98.1 M99 M118 M118.1 "
        "M460 M460.1 M460.2 M460.3 M461 M462 M463 M464 M465 M465.1 M465.2 M466 M466.1 M467 M469 M469.1 M469.2 M469.3 M469.4 M469.5 M469.6 M480 "
        " M491.1 M493.3 M600.1 "
    .rstrip().split(
            " "
        )
    ))


    @classmethod
    def get_common_property_schema(cls):
        """Override common properties with Makera-specific defaults."""
        common_props = super().get_common_property_schema()

        for prop in common_props:
            if prop["name"] == "file_extension":
                prop["default"] = "cnc"
            elif prop["name"] == "supports_tool_radius_compensation":
                prop["default"] = False
            elif prop["name"] == "supported_commands":
                prop["default"] = "\n".join(cls.GCodeSupported_Community)
            elif prop["name"] == "ignored_commands":
                prop["default"] = "G43"
            elif prop["name"] == "preamble":
                prop["default"] = "G90 G94\nG17"
            elif prop["name"] == "postamble":
                prop["default"] = "M05\nG17 G90\nG28\nM30\n"
            elif prop["name"] == "pre_tool_change":
                # Stop the spindle before every tool change.
                prop["default"] = "M05"
            elif prop["name"] == "output_tool_length_offset":
                # Makera has no G43 support.
                prop["default"] = False
            elif prop["name"] == "translate_drill_cycles":
                # Makera can't run canned cycles; expand them to G0/G1/G4 moves.
                prop["default"] = True
            elif prop["name"] == "drill_cycles_to_translate":
                prop["default"] = "G81\nG82\nG83"
            elif prop["name"] == "parameter_order":
                # Makera doesn't want K on the XY plane (arcs need work),
                # and has no H/D (tool length offset) or C axis support.
                prop["default"] = "XYZABIJFSTQRL"
            elif prop["name"] == "axis_precision":
                prop["default"] = 5
            elif prop["name"] == "feed_precision":
                prop["default"] = 5
            elif prop["name"] == "spindle_decimals":
                prop["default"] = 0

        return common_props

    @classmethod
    def get_property_schema(cls):
        """Return schema for Makera-specific configurable properties."""
        return [
            {
                "name": "verbose_upload",
                "type": "bool",
                "scope": SCOPE_JOB,
                "runtime": True,
                "label": translate("CAM", "Verbose Upload Logging"),
                "default": False,
                "help": translate(
                    "CAM", "Print progress messages while uploading G-code to the machine."
                ),
            },
            {
                "name": "use_auto_vacuum",
                "type": "bool",
                "scope": SCOPE_JOB,
                "label": translate("CAM", "Auto Vacuum"),
                "default": False,
                "help": translate(
                    "CAM", "Enable auto vacuum mode (vacuum follows spindle)"
                ),
            },
            {
                "name": "use_auto_blow",
                "type": "bool",
                "scope": SCOPE_JOB,
                "label": translate("CAM", "Auto Blow (Z1)"),
                "default": False,
                "help": translate(
                    "CAM", "Enable auto blow on Z1. The spindle fan will always run with this minimum power while the spindle is on."
                ),
            },
            {
                "name": "use_ionizer",
                "type": "bool",
                "scope": SCOPE_JOB,
                "label": translate("CAM", "Auto Ionizer (Z1)"),
                "default": False,
                "help": translate(
                    "CAM", "Turn on the ionizer on Z1 at start of file"
                ),
            },
            {
                "name": "run_cleaning",
                "type": "bool",
                "scope": SCOPE_JOB,
                "label": translate("CAM", "Cleaning Cycle(Z1)"),
                "default": False,
                "help": translate(
                    "CAM", "Enable auto blow on Z1. The spindle fan will always run with this minimum power while the spindle is on."
                ),
            },
            {
                "name": "ext_onOffAtStartAndEnd",
                "type": "bool",
                "scope": SCOPE_JOB,
                "label": translate("CAM", "Turn On Ext Port at the start of the file and off at the end of the file"),
                "default": False,
                "help": translate(
                    "CAM", "Turn On Ext Port When Spindle is On"
                ),
            },
            {
                "name": "ext_for_air",
                "type": "bool",
                "scope": SCOPE_JOB,
                "label": translate("CAM", "Turn On Ext Port When Mist Coolant On"),
                "default": False,
                "help": translate(
                    "CAM", "Turn On Ext Port instead of running a M7 command When Mist Coolant is On"
                ),
            },
            {
                "name": "ext_port_percent",
                "type": "float",
                "scope": SCOPE_JOB,
                "label": translate("CAM", "Percentage for Ext Port when Used With Spindle or Air"),
                "default": 80,
                "min": 0.0,
                "max": 100.0,
                "decimals": 1,
                "help": translate(
                    "CAM", "Percentage for Ext Port when Used With Spindle or Air"
                ),
            },
            {
                "name": "header_type",
                "scope": SCOPE_MACHINE,
                "type": "choice",
                "label": translate("CAM", "Header Style"),
                "default": "Studio",
                "choices": ["Studio", "Community"],
                "help": translate(
                    "CAM",
                    "Style for tool and stock information to header. Studio emits the "
                    ";@MKR|... block, Community emits the (@FC|...) comments.",
                ),
            },
            {
                "name": "makera_machine_id",
                "scope": SCOPE_MACHINE,
                "type": "string",
                "label": translate("CAM", "Makera Machine ID"),
                "default": "Z1",
                "help": translate("CAM", "Value of id= in the ;@MKR|MACHINE line."),
            },
            {
                "name": "makera_machine_name",
                "scope": SCOPE_MACHINE,
                "type": "string",
                "label": translate("CAM", "Makera Machine Name"),
                "default": "Makera Z1",
                "help": translate("CAM", "Value of name= in the ;@MKR|MACHINE line."),
            },
            {
                "name": "makera_material_name1",
                "scope": SCOPE_JOB,
                "type": "string",
                "label": translate("CAM", "Makera Material (category)"),
                "default": "",
                "help": translate("CAM", "e.g. Wood. Left empty it is omitted."),
            },
            {
                "name": "makera_material_name2",
                "scope": SCOPE_JOB,
                "type": "string",
                "label": translate("CAM", "Makera Material (type)"),
                "default": "",
                "help": translate("CAM", "e.g. Hardwood. Left empty it is omitted."),
            },
            {
                "name": "makera_material_name3",
                "scope": SCOPE_JOB,
                "type": "string",
                "label": translate("CAM", "Makera Material (other)"),
                "default": "other",
                "help": translate("CAM", "Value of name3= in the ;@MKR|MATERIAL line."),
            },
            {
                "name": "makera_max_feedrate",
                "scope": SCOPE_MACHINE,
                "type": "float",
                "label": translate("CAM", "Makera Max Feed Rate"),
                "default": 4000.0,
                "min": 0.0,
                "max": 100000.0,
                "decimals": 0,
                "help": translate("CAM", "Value of the ;@MKR|MAXFEEDRATE line."),
            },
        ]

    def _merge_machine_config(self):
        super()._merge_machine_config()
        self.values["TRANSLATE_DRILL_CYCLES"] = True

    def __init__(
        self,
        job,
        tooltip=translate("CAM", "Makera CNC post processor"),
        tooltipargs=[],
        units="Metric",
        tool_controllers = None,
        
    ):
        super().__init__(
            job=job,
            tooltip=tooltip,
            tooltipargs=tooltipargs,
            units=units,
        )
        Path.Log.debug("Makera post processor initialized.")

    def init_values(self, values: Values):
        super().init_values(values)
        #
        # Makera doesn't want K on the XY plane (arcs need work), and has no
        # H/D (tool length offset) or C axis support. This is also set via
        # the "parameter_order" property default above; both are kept so the
        # order is correct however the values dict gets (re)built.
        #
        values["PARAMETER_ORDER"] = "XYZABIJFSTQRL"

        values["POSTPROCESSOR_FILE_NAME"] = __name__

        # Load runtime-only properties (not part of get_common_property_schema
        # merging) from machine configuration if available.
        if self._machine and hasattr(self._machine, "postprocessor_properties"):
            props = self._machine.postprocessor_properties
            values["VERBOSE_UPLOAD"] = props.get("verbose_upload", False)
        else:
            values["VERBOSE_UPLOAD"] = False

        # Tracks the last-known spindle speed so it can be stamped onto every
        # cutting move (see _inject_spindle_speed()).
        self._last_spindle_speed: Optional[float] = None

    # ------------------------------------------------------------------
    # Tools/stock/origin dump
    # ------------------------------------------------------------------
    #
    # This is consumed by downstream shop-floor tooling to know which
    # settings apply to a program before it's run.
    #
    # Emits:
    # - a "(@FC|TOOL|number=...|name=...|diameter=...|...)" comment for
    #   every tool used by the job, in the header.
    # - one "(@FC|STOCK|...)" comment that describes the stock size and shape
    # - one "(@FC|ORIGIN|...)" comment that describes the WCS origin placement


    def _build_header(self, postables):
        gcodeheader = super()._build_header(postables)
        self.tool_controllers = []
        if self.values["OUTPUT_HEADER"] and self.values.get("LIST_TOOLS_IN_HEADER", True):
            self.tool_controllers = self._collect_tool_controllers(postables)

        return gcodeheader
    
    def _tool_header_entry(self, tool_controller):
        """Rich tool descriptor for the header"""
        line = self._format_tool_table_line(tool_controller)  # "(@FC|TOOL|number=N|...)"
        fields = [f for f in line.split("|")]
        return "|".join(fields)

    def _collect_tool_controllers(self, postables):
        """Return only the ToolControllers actually used in the posted
        output (not every tool defined on the job), ordered by tool number.
        """
        used_numbers = set()
        for _section_name, sublist in postables:
            for item in sublist:
                if item.item_type == "tool_controller":
                    number = (item.data or {}).get("tool_number")
                    if number is None:
                        number = getattr(item.source, "ToolNumber", None)
                    if number is not None:
                        used_numbers.add(int(number))

        if not used_numbers:
            return []

        by_number = {}

        if self._job is not None and hasattr(self._job, "Tools"):
            for tc in getattr(self._job.Tools, "Group", None) or []:
                if hasattr(tc, "ToolNumber") and int(tc.ToolNumber) in used_numbers:
                    by_number[int(tc.ToolNumber)] = tc

        for op in self._operations or []:
            tc = getattr(op, "ToolController", None)
            if tc is not None and hasattr(tc, "ToolNumber"):
                number = int(tc.ToolNumber)
                if number in used_numbers:
                    by_number.setdefault(number, tc)

        return [by_number[number] for number in sorted(by_number)]

    def _quantity_value(self, value, is_angle=False):
        """Convert a FreeCAD Quantity / number / unit-string to a float
        in the current output units (or degrees, for angles)."""
        if value is None or value == "":
            return None

        if is_angle:
            unit = "deg"
        else:
            unit = "in" if self.values["OUTPUT_UNITS"] == OutputUnits.IMPERIAL else "mm"

        try:
            if hasattr(value, "getValueAs"):
                return float(value.getValueAs(unit))
            quantity = Units.Quantity(value)
            if hasattr(quantity, "getValueAs"):
                return float(quantity.getValueAs(unit))
        except Exception:
            pass
        try:
            return float(str(value).split()[0])
        except Exception:
            return None

    @staticmethod
    def _append_fc_field(parts, key, value, precision=None):
        if value is None:
            return
        if isinstance(value, float):
            if precision is not None:
                text = format(value, "." + str(precision) + "f").rstrip("0").rstrip(".")
            else:
                text = format(value, ".6g")
            if text == "-0":
                text = "0"
            parts.append("%s=%s" % (key, text))
        else:
            text = str(value).replace("|", "/").strip()
            if text:
                parts.append("%s=%s" % (key, text))

    @staticmethod
    def _tool_bit_dict(tool):
        """Return ToolBit.to_dict() when available (parameters + attributes)."""
        proxy = getattr(tool, "Proxy", None)
        if proxy is None or not hasattr(proxy, "to_dict"):
            return {}
        try:
            data = proxy.to_dict()
        except Exception:
            return {}
        return data if isinstance(data, dict) else {}

    @staticmethod
    def _tool_type_name(tool, bit_dict):
        """Return FreeCAD's native ShapeType (e.g. Endmill, Ballend, Drill)."""
        shape = getattr(tool, "ShapeType", None)
        if shape:
            return str(shape)

        shape = bit_dict.get("shape-type")
        if shape:
            return str(shape)

        return "unknown"

    @staticmethod
    def _tool_param(tool, bit_dict, *names):
        """Prefer live ToolBit properties, then serialized parameters."""
        parameters = bit_dict.get("parameter") or {}
        for name in names:
            if hasattr(tool, name):
                value = getattr(tool, name)
                if value is not None and value != "":
                    return value
            if name in parameters and parameters[name] is not None and parameters[name] != "":
                return parameters[name]
        return None

    def _collect_tool_data(self, tool_controller):
        """Gather the tool fields shared by the (@FC|TOOL) and ;@MKR|TOOL lines.

        Returns a dict; "tool" is None when the controller has no tool.
        """
        number = int(getattr(tool_controller, "ToolNumber", 0) or 0)
        tool = getattr(tool_controller, "Tool", None)
        if tool is None:
            return {"number": number, "tool": None}

        bit_dict = self._tool_bit_dict(tool)
        attributes = bit_dict.get("attribute") or {}

        name = (
            attributes.get("Description")
            or attributes.get("description")
            or getattr(tool, "Label", None)
            or getattr(tool_controller, "Label", "")
        )
        vendor = attributes.get("Vendor") or attributes.get("vendor") or ""
        product_id = bit_dict.get("id") or attributes.get("ProductId") or ""
        type_name = self._tool_type_name(tool, bit_dict)

			 

        diameter = self._quantity_value(self._tool_param(tool, bit_dict, "Diameter"))
        shank = self._quantity_value(
            self._tool_param(tool, bit_dict, "ShankDiameter", "ShaftDiameter")
        )
        tip = self._quantity_value(self._tool_param(tool, bit_dict, "TipDiameter"))
        corner = self._quantity_value(
            self._tool_param(tool, bit_dict, "CornerRadius", "FlatRadius", "CuttingRadius")
        )
        flute = self._quantity_value(
            self._tool_param(tool, bit_dict, "CuttingEdgeHeight", "CuttingEdgeLength")
        )
        length = self._quantity_value(self._tool_param(tool, bit_dict, "Length"))
        shoulder = self._quantity_value(
            self._tool_param(tool, bit_dict, "NeckLength", "ShoulderLength")
        )
        pitch = self._quantity_value(self._tool_param(tool, bit_dict, "Pitch"))
        cutting_edge_angle = self._quantity_value(
            self._tool_param(tool, bit_dict, "CuttingEdgeAngle", "cuttingAngle"), is_angle=True
        )
        tip_angle = self._quantity_value(
            self._tool_param(tool, bit_dict, "TipAngle"), is_angle=True
        )
        taper_angle = self._quantity_value(
            self._tool_param(tool, bit_dict, "TaperAngle"), is_angle=True
        )

        return {
            "number": number,
            "tool": tool,
            "name": name,
            "vendor": vendor,
            "product_id": product_id,
            "type_name": type_name,
            "diameter": diameter,
            "shank": shank,
            "tip": tip,
            "corner": corner,
            "flute": flute,
            "length": length,
            "shoulder": shoulder,
            "pitch": pitch,
            "cutting_edge_angle": cutting_edge_angle,
            "tip_angle": tip_angle,
            "taper_angle": taper_angle,
        }

    def _format_tool_table_line(self, tool_controller):
        """Build one (@FC|TOOL|k=v|...) comment for a ToolController."""
        data = self._collect_tool_data(tool_controller)
        number = data["number"]
        if data["tool"] is None:
            return "(@FC|TOOL|number=%d|type=unknown)" % number

        name = data["name"]
        vendor = data["vendor"]
        product_id = data["product_id"]
        type_name = data["type_name"]
        diameter = data["diameter"]
        shank = data["shank"]
        tip = data["tip"]
        corner = data["corner"]
        flute = data["flute"]
        length = data["length"]
        shoulder = data["shoulder"]
        pitch = data["pitch"]
        cutting_edge_angle = data["cutting_edge_angle"]
        tip_angle = data["tip_angle"]
        taper_angle = data["taper_angle"]
        precision = self.values["AXIS_PRECISION"]

        parts = ["@FC|TOOL"]
        self._append_fc_field(parts, "number", number)
        self._append_fc_field(parts, "name", name)
        self._append_fc_field(parts, "vendor", vendor)
        self._append_fc_field(parts, "id", product_id)
        self._append_fc_field(parts, "type", type_name)
        self._append_fc_field(parts, "diameter", diameter, precision)
        self._append_fc_field(parts, "shankdiameter", shank, precision)
        self._append_fc_field(parts, "tipdiameter", tip, precision)
        self._append_fc_field(parts, "cornerradius", corner, precision)
        self._append_fc_field(parts, "flutelength", flute, precision)
        self._append_fc_field(parts, "shoulderlength", shoulder, precision)
        self._append_fc_field(parts, "length", length, precision)
        self._append_fc_field(parts, "pitch", pitch, precision)
        self._append_fc_field(parts, "cuttingedgeangle", cutting_edge_angle, precision)
        self._append_fc_field(parts, "tipangle", tip_angle, precision)
        self._append_fc_field(parts, "taperangle", taper_angle, precision)

        return "(" + "|".join(parts) + ")"

    # ------------------------------------------------------------------
    # Stock / origin dump
    # ------------------------------------------------------------------
    #
    # Machine-readable stock / origin header records.
    #
    # Examples:
    # (@FC|STOCK|id=box|width=150|depth=100|height=10)
    # (@FC|STOCK|id=cylinder|width=70|depth=70|height=50|diameter=70)
    # (@FC|ORIGIN|type_name=topFrontLeft|x=-75|y=-50|z=5)
    #
    # STOCK:
    #   - id: FreeCAD stock type mapped to box or cylinder
    #   - width/depth/height: WCS X/Y/Z extents
    #   - diameter: outer diameter for cylinder (from Radius, else inferred)
    #   - omitted when stock is missing or not a box/cylinder (e.g. unknown solid)
    #
    # ORIGIN:
    #   - type_name: stock-box point (27 points) when the origin sits on that
    #     grid (or "custom"), ex: topFrontLeft, bottomBackRight
    #   - x/y/z: WCS origin relative to the stock center

    @staticmethod
    def _stock_type_name(stock):
        """Return FreeCAD's StockType string, with property-based fallbacks."""
        if stock is None:
            return ""

        stock_type = getattr(stock, "StockType", None)
        if stock_type:
            return str(stock_type)

        if hasattr(stock, "Length") and hasattr(stock, "Width") and hasattr(stock, "Height"):
            return "CreateBox"
        if hasattr(stock, "Radius") and hasattr(stock, "Height"):
            return "CreateCylinder"
        if hasattr(stock, "ExtXneg") and hasattr(stock, "ExtZpos"):
            return "FromBase"
        return ""

    @staticmethod
    def _stock_id_from_type(stock_type):
        """Map FreeCAD stock types onto the Fusion-compatible box/cylinder ids."""
        if stock_type in ("CreateBox", "FromBase"):
            return "box"
        if stock_type == "CreateCylinder":
            return "cylinder"
        return None

    def _stock_bound_box(self, stock):
        """Return the stock Shape BoundBox when it has positive X/Y/Z extents."""
        shape = getattr(stock, "Shape", None)
        if shape is None:
            return None

        box = getattr(shape, "BoundBox", None)
        if box is None:
            return None

        try:
            if hasattr(box, "isValid") and not box.isValid():
                return None
        except Exception:
            return None

        try:
            dx = float(box.XLength)
            dy = float(box.YLength)
            dz = float(box.ZLength)
        except Exception:
            return None

        if dx != dx or dy != dy or dz != dz:
            return None
        if not (dx > 0 and dy > 0 and dz > 0):
            return None
        return box

    @staticmethod
    def _infer_radial_diameter(width, depth, height):
        xy = abs(width - depth)
        xz = abs(width - height)
        yz = abs(depth - height)
        if xy <= xz and xy <= yz:
            return (width + depth) / 2
        if xz <= yz:
            return (width + height) / 2
        return (depth + height) / 2

    def _stock_diameter(self, stock, width, depth, height):
        radius = self._quantity_value(getattr(stock, "Radius", None))
        if radius is not None and radius > 0:
            return radius * 2
        return self._infer_radial_diameter(width, depth, height)

    @staticmethod
    def _classify_origin_side(origin_from_center, half_size, tolerance):
        if not (half_size > 0):
            return 0 if abs(origin_from_center) <= tolerance else None

        sides = (-1, 0, 1)
        positions = (-half_size, 0.0, half_size)
        best_side = 0
        best_dist = abs(origin_from_center - positions[1])
        for side, position in zip(sides, positions):
            dist = abs(origin_from_center - position)
            if dist < best_dist:
                best_dist = dist
                best_side = side
        return best_side if best_dist <= tolerance else None

    @staticmethod
    def _origin_type_name(x_side, y_side, z_side):
        if x_side is None or y_side is None or z_side is None:
            return "custom"

        parts = []
        if z_side < 0:
            parts.append("bottom")
        elif z_side > 0:
            parts.append("top")
        if y_side < 0:
            parts.append("front")
        elif y_side > 0:
            parts.append("back")
        if x_side < 0:
            parts.append("left")
        elif x_side > 0:
            parts.append("right")

        if not parts:
            return "center"

        name = parts[0]
        for part in parts[1:]:
            name += part[0].upper() + part[1:]
        if len(parts) == 1:
            name += "Center"
        return name

    def _stock_origin_data(self):
        """Return stock/origin values in output units, or None when unavailable."""
        stock = getattr(self._job, "Stock", None) if self._job is not None else None
        stock_id = self._stock_id_from_type(self._stock_type_name(stock))
        if not stock_id:
            return None

        box = self._stock_bound_box(stock)
        if box is None:
            return None

        width = self._quantity_value(Units.Quantity(float(box.XLength), "mm"))
        depth = self._quantity_value(Units.Quantity(float(box.YLength), "mm"))
        height = self._quantity_value(Units.Quantity(float(box.ZLength), "mm"))
        origin_x = self._quantity_value(
            Units.Quantity(-((float(box.XMin) + float(box.XMax)) / 2), "mm")
        )
        origin_y = self._quantity_value(
            Units.Quantity(-((float(box.YMin) + float(box.YMax)) / 2), "mm")
        )
        origin_z = self._quantity_value(
            Units.Quantity(-((float(box.ZMin) + float(box.ZMax)) / 2), "mm")
        )
        if None in (width, depth, height, origin_x, origin_y, origin_z):
            return None

        diameter = None
		   
				
				  
				  
					
        if stock_id == "cylinder":
		  
            diameter = self._stock_diameter(stock, width, depth, height)
	

        half_x = width / 2
        half_y = depth / 2
        half_z = height / 2
        tol_floor = self._quantity_value(Units.Quantity(0.05, "mm"))
        if tol_floor is None:
            tol_floor = 0.05
        tol = max(tol_floor, 0.002 * max(width, depth, height))
        type_name = self._origin_type_name(
            self._classify_origin_side(origin_x, half_x, tol),
            self._classify_origin_side(origin_y, half_y, tol),
            self._classify_origin_side(origin_z, half_z, tol),
        )

        return {
            "stock": stock,
            "stock_id": stock_id,
            "width": width,
            "depth": depth,
            "height": height,
            "diameter": diameter,
            "type_name": type_name,
            "origin_x": origin_x,
            "origin_y": origin_y,
            "origin_z": origin_z,
        }

    def _format_stock_header_lines(self):
        """Build (@FC|STOCK|...) and (@FC|ORIGIN|...) comments, or an empty list."""
        data = self._stock_origin_data()
        if data is None:
            return []

        precision = self.values["AXIS_PRECISION"]
        stock_parts = ["@FC|STOCK"]
        self._append_fc_field(stock_parts, "id", data["stock_id"])
        self._append_fc_field(stock_parts, "width", data["width"], precision)
        self._append_fc_field(stock_parts, "depth", data["depth"], precision)
        self._append_fc_field(stock_parts, "height", data["height"], precision)
        if data["diameter"] is not None:
            self._append_fc_field(stock_parts, "diameter", data["diameter"], precision)

        origin_parts = ["@FC|ORIGIN"]
        self._append_fc_field(origin_parts, "type_name", data["type_name"])
        self._append_fc_field(origin_parts, "x", data["origin_x"], precision)
        self._append_fc_field(origin_parts, "y", data["origin_y"], precision)
        self._append_fc_field(origin_parts, "z", data["origin_z"], precision)

        return [
            "(" + "|".join(stock_parts) + ")",
            "(" + "|".join(origin_parts) + ")",
        ]

    # ------------------------------------------------------------------
    # Makera Studio style header (;@MKR|...)
    # ------------------------------------------------------------------
    #
    # Selected with the "header_type" property ("Studio"). Reuses the same tool and
    # stock/origin data as the (@FC|...) records, which remain the default.

    MKR_SCHEMA_VERSION = "1.0.0"
    MKR_CAM_ID = "MakeraStudio"
    MKR_CAM_NAME = "MakeraStudio"
    MKR_CAM_VERSION = "0.0.0.4"

    # FreeCAD ShapeType (lower case, no spaces/dashes/underscores) -> Makera
    # Studio tool type. Valid Studio types: Ball Nose, Bull Nose, Flat End,
    # V-Bit, Engraving, Drill, Thread, Tapered Ball Nose, None.
    MKR_TOOL_TYPES = {
        "endmill": "Flat End",
        "ballend": "Ball Nose",
        "bullnose": "Bull Nose",
        "vbit": "V-Bit",
        "chamfer": "V-Bit",
        "engraver": "Engraving",
        "drill": "Drill",
        "threadmill": "Thread",
        "tap": "Thread",
    }

    def _mkr_tool_type(self, data):
        """Map the FreeCAD tool shape onto a Makera Studio tool type."""
        shape = str(data["type_name"]).lower().replace(" ", "").replace("-", "").replace("_", "")
        type_name = self.MKR_TOOL_TYPES.get(shape, "None")
        if type_name == "Ball Nose" and data["taper_angle"]:
            type_name = "Tapered Ball Nose"
        return type_name

    def _makera_prop(self, name, default):
        """Read a bundle property (Processor stores them UPPERCASE in self.values)."""
        value = (getattr(self, "values", None) or {}).get(name.upper())
        if value is None:
            machine = getattr(self, "_machine", None)
            props = getattr(machine, "postprocessor_properties", None) or {}
            value = props.get(name)
        return default if value is None else value

    def _use_makera_header(self):
        return self._makera_prop("header_type", "Studio") == "Studio"

    def _mkr_line(self, record, fields=None, precision=None):
        """Build ;@MKR|RECORD|k=v|... where fields is a list of (key, value)."""
        parts = ["@MKR|" + record]
        for key, value in fields or []:
            self._append_fc_field(parts, key, value, precision)
        return ";" + "|".join(parts)

    def _mkr_tool_line(self, tool_controller):
        data = self._collect_tool_data(tool_controller)
        number = data["number"]
        if data["tool"] is None:
            return self._mkr_line("TOOL", [("number", number), ("type", "None")])

        precision = self.values["AXIS_PRECISION"]
        type_name = self._mkr_tool_type(data)
        tip_angle = data["tip_angle"] or data["cutting_edge_angle"] or data["taper_angle"]
        half_angle = tip_angle / 2 if tip_angle else 0.0

        diameter = data["diameter"]
        tip = data["tip"]
        if tip is None:
            tip = diameter

        return self._mkr_line(
            "TOOL",
            [
                ("number", number),
                ("id", data["product_id"]),
                ("name", data["name"]),
                ("type", type_name),
                ("handlediameter", data["shank"] if data["shank"] is not None else diameter),
                ("sticklength", 0.0),
                ("shoulderlength", data["shoulder"] if data["shoulder"] is not None else 0.0),
                ("flutelength", data["flute"] if data["flute"] is not None else 0.0),
                ("diameter", diameter),
                ("tipdiameter", tip),
                ("cornerradius", data["corner"] if data["corner"] is not None else 0.0),
                ("angle", 0.0),
                ("halfAngle", float(half_angle)),
            ],
            precision,
        )

    @staticmethod
    def _parse_cycle_time(text):
        """Parse a FreeCAD CycleTime string ("hh:mm:ss") into seconds, or None."""
        try:
            fields = [float(p) for p in str(text).strip().split(":")]
        except Exception:
            return None
        if not 1 < len(fields) <= 3:
            return None
        seconds = 0.0
        for value in fields:
            seconds = seconds * 60 + value
        return seconds

    def _mkr_operations(self):
        """Active operations that have a tool controller, in posting order."""
        result = []
        for op in self._operations or []:
            tc = getattr(op, "ToolController", None)
            if tc is None or not hasattr(tc, "ToolNumber"):
                continue
            if getattr(op, "Active", True) is False:
                continue
            result.append((op, tc))
        return result

    def _mkr_postable_operations(self, postables):
        """(operation, tool controller) pairs in the order they will be posted.

        Used for both the TOOLPATH header records and the per-operation
        TOOLPATH_START markers so the numbering always agrees.
        """
        result = []
        for _section_name, sublist in postables:
            for item in sublist:
                if item.item_type != "operation":
                    continue
                op = item.source
                tc = getattr(op, "ToolController", None)
                if tc is None or not hasattr(tc, "ToolNumber"):
                    continue
                result.append((op, tc))
        return result

    def _mkr_toolpath_start_text(self, number, tool_controller):
        """Two comment lines opening an operation: marker + "T<n>-<tool name>"."""
        data = self._collect_tool_data(tool_controller)
        tool_number = data["number"]
        name = data.get("name") or getattr(tool_controller, "Label", "") or ""
        name = str(name).replace("|", "/").strip()
        return (
            ";@MKR|TOOLPATH_START|toolpath_number=%d\n" % number
            + "; T%d-%s\n" % (tool_number, name)
        )

    def _mkr_insert_toolpath_markers(self, postables):
        """Insert the TOOLPATH_START marker at the top of every operation.

        When the operation is preceded by its tool change, the marker goes in
        front of the tool change so it opens the whole operation.
        """
        number = 0
        for _section_name, sublist in postables:
            new_sublist = []
            for item in sublist:
                if item.item_type == "operation":
                    tc = getattr(item.source, "ToolController", None)
                    if tc is not None and hasattr(tc, "ToolNumber"):
                        number += 1
                        marker = self._make_postable(
                            "Post: makera toolpath start", self._mkr_toolpath_start_text(number, tc)
                        )
                        at = len(new_sublist)
                        if new_sublist and new_sublist[-1].item_type == "tool_controller":
                            at -= 1
                        new_sublist.insert(at, marker)
                new_sublist.append(item)
            sublist[:] = new_sublist

    def _format_makera_header_lines(self, operations=None):
        """Build the full ;@MKR|BEGIN ... ;@MKR|END block as a list of lines.

        operations: [(op, tool controller)] in posting order; defaults to the job's operations.
        """
        lines = [";@MKR|BEGIN"]
        lines.append(self._mkr_line("SCHEMA", [("v", self.MKR_SCHEMA_VERSION)]))
        lines.append(
            self._mkr_line(
                "MACHINE",
                [
                    ("id", self._makera_prop("makera_machine_id", "Z1")),
                    ("name", self._makera_prop("makera_machine_name", "Makera Z1")),
                ],
            )
        )

        material = [
            ("name3", self._makera_prop("makera_material_name3", "other")),
            ("name1", self._makera_prop("makera_material_name1", "")),
            ("name2", self._makera_prop("makera_material_name2", "")),
        ]
        # id is intentionally emitted empty, which _append_fc_field would drop
        material_line = self._mkr_line("MATERIAL", material)
        lines.append(material_line.replace("|MATERIAL", "|MATERIAL|id=", 1))

        precision = self.values["AXIS_PRECISION"]
        try:
            stock = self._stock_origin_data()
        except Exception as exc:
            FreeCAD.Console.PrintWarning("Failed to dump stock/origin: %s\n" % exc)
            stock = None
        if stock is not None:
            stock_id = "cylinder" if stock["stock_id"] == "cylinder" else "cuboid"
            fields = [
                ("id", stock_id),
                ("length", stock["width"]),  # WCS X extent
                ("width", stock["depth"]),  # WCS Y extent
                ("height", stock["height"]),
            ]
            if stock["diameter"] is not None:
                fields.append(("diameter", stock["diameter"]))
            lines.append(self._mkr_line("STOCK", fields, precision))
            lines.append(
                self._mkr_line(
                    "ORIGIN",
                    [
                        ("id", "0"),
                        ("type_name", stock["type_name"]),
                        ("x", stock["origin_x"]),
                        ("y", stock["origin_y"]),
                        ("z", stock["origin_z"]),
                    ],
                    precision,
                )
            )

        lines.append(
            self._mkr_line(
                "CAM",
                [("id", self.MKR_CAM_ID), ("name", self.MKR_CAM_NAME), ("v", self.MKR_CAM_VERSION)],
            )
        )
        imperial = self.values["OUTPUT_UNITS"] == OutputUnits.IMPERIAL
        lines.append(self._mkr_line("UNIT", [("value", "inch" if imperial else "mm")]))
        lines.append(
            self._mkr_line(
                "MAXFEEDRATE",
                [("value", float(self._makera_prop("makera_max_feedrate", 4000.0)))],
                precision,
            )
        )

        for tool_controller in getattr(self, "tool_controllers", None) or []:
            try:
                lines.append(self._mkr_tool_line(tool_controller))
            except Exception as exc:
                FreeCAD.Console.PrintWarning(
                    "Failed to dump tool T%s: %s\n" % (getattr(tool_controller, "ToolNumber", "?"), exc)
                )

        if operations is None:
            operations = self._mkr_operations()
        times = [self._parse_cycle_time(getattr(op, "CycleTime", None)) for op, _ in operations]
        times = [t for t in times if t is not None]
        if times:
            lines.append(self._mkr_line("TIME", [("seconds", float(sum(times)))], 2))

        for index, (op, tc) in enumerate(operations, start=1):
            tool_number = int(tc.ToolNumber)
            lines.append(
                self._mkr_line(
                    "TOOLPATH",
                    [
                        ("number", index),
                        ("tool_number", tool_number),
                        ("name", "[T%d]%s" % (tool_number, getattr(op, "Label", ""))),
                    ],
                )
            )

        lines.append(";@MKR|END")
        return lines

    def _expand_prefix(self, postables):
        """Add prefix to each section"""

        # collect in order
        prefix = []

        # must be first
        # optimization can start after _build_header lines
        prefix.append(self._make_postable("Post: start optimizable", [], {"optimizable": False}))

        # OUTPUT_HEADER
        # built first: it also collects self.tool_controllers for the Studio block
        gcodeheader = self._build_header(postables)

        # Makera Studio header: first thing in the file, above the (Machine: ...) line
        use_studio = self._use_makera_header() and self.values["OUTPUT_HEADER"]
        if use_studio:
            try:
                operations = self._mkr_postable_operations(postables) or None
                for line in self._format_makera_header_lines(operations):
                    prefix.append(self._make_postable("", line + "\n"))
                self._mkr_insert_toolpath_markers(postables)
            except Exception as exc:
                FreeCAD.Console.PrintWarning("Failed to build Makera header: %s\n" % exc)

        # SAFETYBLOCK
        # must be before any possible commands
        if (lines := self.values["SAFETYBLOCK"]) is not None and lines != "":
            prefix.append(self._make_postable("Post: safetyblock", lines))
        if commands := gcodeheader.Path.Commands:
            prefix.append(self._make_postable("Post: header", commands))
        if not self._use_makera_header():
            controllers = getattr(self, "tool_controllers", None) or []
            for tool_controller in controllers:
                try:
                    prefix.append(self._make_postable("", self._format_tool_table_line(tool_controller) + "\n"))
                except Exception as exc:
                    FreeCAD.Console.PrintWarning("Failed to dump tool T%s: %s\n" % (getattr(tool_controller, "ToolNumber", "?"), exc))

            try:
                for line in self._format_stock_header_lines():
                    prefix.append(self._make_postable("", line + "\n"))
            except Exception as exc:
                FreeCAD.Console.PrintWarning("Failed to dump stock/origin: %s\n" % exc)
        
        if self._machine.postprocessor_properties.get("use_ionizer", False):
            prefix.append(self._make_postable("","M331.4"))
        if self._machine.postprocessor_properties.get("use_auto_blow", False):
            prefix.append(self._make_postable("","M331.1 S30"))
        if self._machine.postprocessor_properties.get("use_auto_vacuum", False):
            prefix.append(self._make_postable("","M331"))
        if self._machine.postprocessor_properties.get("run_cleaning", False):
            prefix.append(self._make_postable("","M331.2"))
        
        # optimization can start now
        prefix.append(self._make_postable("Post: start optimizable", [], {"optimizable": True}))
        
                
        # PREAMBLE
        if (lines := self.values["PREAMBLE"]) is not None and lines != "":
            prefix.append(self._make_postable("Post: preamble", lines))
            
        

        # OUTPUT_UNITS
        if unit_command := self._collect_unit_command():
            prefix.append(self._make_postable("Post: units", unit_command))

        # FIXME: PRE_JOB should be per-job, but there is no 'job' item, so fallback to every section
        # see _expand_pre_job()
        if (lines := self.values["PRE_JOB"]) is not None and lines != "":
            prefix.append(self._make_postable("Post: prejob", lines))

        for _, section in postables:
            if prefix:
                section[:0] = prefix  # prepend

    def convert_command_to_gcode(self, command: Path.Command):
        props = self._machine.postprocessor_properties
       
        if command.Name == 'M7' and props.get("ext_for_air", False):
            return "\nM851 S" + str(props.get("ext_port_percent", 80)) + "\n" + super().convert_command_to_gcode(command) + "\n"
        if command.Name == 'M9' and props.get("ext_for_air", False):
            return "M852\n" + super().convert_command_to_gcode(command) + "\n"
        
        return super().convert_command_to_gcode(command)

    def _expand_trailing_lines(self, postables):
        """Append post_job and postamble lines, to each section."""
        trailing = []
        if (lines := self.values["POST_JOB"]) is not None and lines != "":
            trailing.append(self._make_postable("Post: post_job", lines))
        if self._machine.postprocessor_properties.get("ext_onOffAtStartAndEnd", False):
            trailing.append(self._make_postable("","M852"))
        if self._machine.postprocessor_properties.get("use_ionizer", False):
            trailing.append(self._make_postable("","M332.4"))
        if (lines := self.values["POSTAMBLE"]) is not None and lines != "":
            trailing.append(self._make_postable("Post: postamble", lines))

        if trailing:
            for _, section in postables:
                section.extend(trailing)

    # ------------------------------------------------------------------
    # Spindle Speed changes make new line with M3 S#
    # ------------------------------------------------------------------

    def _spindle_prefix_line(self, command: Path.Command):
        #Return a standalone M3 line when spindle speed changes
        params = command.Parameters
        if "S" in params:
            speed = params["S"]
            if speed != self._last_spindle_speed:
                m3_command = Path.Command("M3", {"S": speed})
                return super()._convert_spindle_command(m3_command) + "\n"
        elif self._last_spindle_speed is not None:
            speed = self._last_spindle_speed

        return ""


    def _strip_spindle_param(self, command: Path.Command):
        if "S" not in command.Parameters:
            return command
        new_params = dict(command.Parameters)
        del new_params["S"]
        return Path.Command(command.Name, new_params, dict(command.Annotations))

    def _convert_linear_move(self, command: Path.Command):
        prefix = self._spindle_prefix_line(command)
        return prefix + super()._convert_linear_move(self._strip_spindle_param(command))

    def _convert_arc_move(self, command: Path.Command):
        prefix = self._spindle_prefix_line(command)
        return prefix + super()._convert_arc_move(self._strip_spindle_param(command))

    def _convert_tool_change(self, command: Path.Command):
        # A tool change means a new spindle speed is coming; don't carry the
        # old one forward onto moves before the next M3/M4.
        self._last_spindle_speed = None
        tool_number = int(command.Parameters.get("T", None))
        return f"T{tool_number} M6"


        #return super()._convert_tool_change(command)

    # ------------------------------------------------------------------
    # Sanity checks
    # ------------------------------------------------------------------

    def get_sanity_checks(self, job):
        squawks = []
        return squawks

    @property
    def tooltip(self):
        tooltip: str = """
        This is a postprocessor file for the CAM workbench.
        It is used to take a pseudo-gcode fragment from a CAM object
        and output 'real' GCode suitable for a Makera CNC machine with
        a smoothieware based controller.

        Canned drilling cycles (G81/G82/G83) are automatically expanded to
        G0/G1/G4 moves, and tool length offsets (G43) are suppressed, since
        the controller supports neither natively. The current spindle speed
        is repeated on every cutting move.

        """
        return tooltip
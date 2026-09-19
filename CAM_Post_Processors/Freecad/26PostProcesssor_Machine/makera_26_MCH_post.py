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

class Makera_26_Mch(PostProcessor):
    """
    The Makera CNC post processor class.

    Targets a Makera CNC machine running a smoothieware-based controller.
    Two things make this controller different from a "generic" 3 axis mill:

    - It has no support for canned drilling cycles (G81/G82/G83) or for
      tool length offsets (G43), so both are expanded/suppressed rather
      than being emitted directly.

    """

    @classmethod
    def get_common_property_schema(cls):
        """Override common properties with Makera-specific defaults."""
        common_props = super().get_common_property_schema()

        for prop in common_props:
            if prop["name"] == "file_extension":
                prop["default"] = "cnc"
            elif prop["name"] == "supports_tool_radius_compensation":
                prop["default"] = False
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
                "runtime": True,
                "label": translate("CAM", "Verbose Upload Logging"),
                "default": False,
                "help": translate(
                    "CAM", "Print progress messages while uploading G-code to the machine."
                ),
            },
            {
                "name": "ext_onOffAtStartAndEnd",
                "type": "bool",
                "label": translate("CAM", "Turn On Ext Port at the start of the file and off at the end of the file"),
                "default": False,
                "help": translate(
                    "CAM", "Turn On Ext Port When Spindle is On"
                ),
            },
            {
                "name": "ext_for_air",
                "type": "bool",
                "label": translate("CAM", "Turn On Ext Port When Mist Coolant On"),
                "default": False,
                "help": translate(
                    "CAM", "Turn On Ext Port instead of running a M7 command When Mist Coolant is On"
                ),
            },
            {
                "name": "ext_port_percent",
                "type": "float",
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
                "name": "min_feed_rate",
                "type": "float",
                "label": translate("CAM", "Minimum Feed Rate"),
                "default": 5.0,
                "min": 0.0,
                "max": 100000.0,
                "decimals": 2,
                "help": translate(
                    "CAM",
                    "Feed rates (in the current output units/min) below this value "
                    "abort posting - this usually indicates a missing feed rate.",
                ),
            },
            {
                "name": "min_spindle_speed",
                "type": "float",
                "label": translate("CAM", "Minimum Spindle Speed"),
                "default": 5.0,
                "min": 0.0,
                "max": 20000.0,
                "decimals": 0,
                "help": translate(
                    "CAM",
                    "Spindle speeds (in RPM) below this value abort posting - this "
                    "usually indicates a missing spindle speed.",
                ),
            },
        ]

    def __init__(
        self,
        job,
        tooltip=translate("CAM", "Makera CNC post processor"),
        tooltipargs=[],
        units="Metric",
        tool_controllers = None,
        lastop = None,
        
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
            values["MIN_FEED_RATE"] = props.get("min_feed_rate", 5.0)
            values["MIN_SPINDLE_SPEED"] = props.get("min_spindle_speed", 5.0)
        else:
            values["VERBOSE_UPLOAD"] = False
            values["MIN_FEED_RATE"] = 5.0
            values["MIN_SPINDLE_SPEED"] = 5.0

        # Tracks the last-known spindle speed so it can be stamped onto every
        # cutting move (see _inject_spindle_speed()).
        self._last_spindle_speed: Optional[float] = None

    # ------------------------------------------------------------------
    # Tool table dump
    # ------------------------------------------------------------------
    #
    # Emits a "(@FC|TOOL|number=...|name=...|diameter=...|...)" comment for
    # every tool used by the job, in the header. This is consumed by
    # downstream shop-floor tooling to know which tools a program needs
    # before it's run.
    
    
    def _build_header(self, postables):
        gcodeheader = super()._build_header(postables)
        gcodeheader.Path.Commands.append('test')

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

    def _format_tool_table_line(self, tool_controller):
        """Build one (@FC|TOOL|k=v|...) comment for a ToolController."""
        number = int(getattr(tool_controller, "ToolNumber", 0) or 0)
        tool = getattr(tool_controller, "Tool", None)
        if tool is None:
            return "(@FC|TOOL|number=%d|type=unknown)" % number

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

        precision = self.values["AXIS_PRECISION"]

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

    def _expand_prefix(self, postables):
        """Add prefix to each section"""

        # collect in order
        prefix = []

        # must be first
        # optimization can start after _build_header lines
        prefix.append(self._make_postable("Post: start optimizable", [], {"optimizable": False}))

        # SAFETYBLOCK
        # must be before any possible commands
        if (lines := self.values["SAFETYBLOCK"]) is not None and lines != "":
            prefix.append(self._make_postable("Post: safetyblock", lines))

        # OUTPUT_HEADER
        gcodeheader = self._build_header(postables)
        if commands := gcodeheader.Path.Commands:
            prefix.append(self._make_postable("Post: header", commands))
        
        controllers = self.tool_controllers
        for tool_controller in controllers:
            try:
                prefix.append(self._make_postable("", self._format_tool_table_line(tool_controller) + "\n"))
            except Exception as exc:
                FreeCAD.Console.PrintWarning("Failed to dump tool T%s: %s\n" % (getattr(tool_controller, "ToolNumber", "?"), exc))
        
        
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
        if self._is_custom_gcode_operation():
            op = self._operation
            
            if op == self.lastop:
                return ""
            self.lastop = op
            #revert modal state
            for key in self._modal_state:
                self._modal_state[key] = None
            out = '(Custom: ' + op.Label + ')\n'
            for line in getattr(op, "Gcode"):
                out += line + '\n'
            out += '(End '+ op.Label + ')\n'
            return out
            #return command.toGCode()
       
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
        if (lines := self.values["POSTAMBLE"]) is not None and lines != "":
            trailing.append(self._make_postable("Post: postamble", lines))

        if trailing:
            for _, section in postables:
                section.extend(trailing)



    def _is_custom_gcode_operation(self):
        op = self._operation
        return op is not None and hasattr(op, "Gcode")

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


    def _check_feed_rate(self, command: Path.Command):
        if "F" not in command.Parameters:
            return
        feed_value = float(self.format_parameter("F", command.Parameters["F"]))
        if feed_value < self.values["MIN_FEED_RATE"]:
            raise CAMValueError(
                f"Feed rate {feed_value} is below the configured minimum "
                f"({self.values['MIN_FEED_RATE']}) - posting aborted. This usually "
                "means a feed rate is missing.",
                job=self._job,
                operation=self._operation,
                command=command,
            )

    def _convert_linear_move(self, command: Path.Command):
        self._check_feed_rate(command)
        prefix = self._spindle_prefix_line(command)
        return prefix + super()._convert_linear_move(self._strip_spindle_param(command))

    def _convert_arc_move(self, command: Path.Command):
        self._check_feed_rate(command)
        prefix = self._spindle_prefix_line(command)
        return prefix + super()._convert_arc_move(self._strip_spindle_param(command))

    def _convert_spindle_command(self, command: Path.Command):
        if command.Name in ("M3", "M03", "M4", "M04") and "S" in command.Parameters:
            speed = command.Parameters["S"]
            self._last_spindle_speed = speed
            speed_value = float(self.format_parameter("S", speed))
            if speed_value < self.values["MIN_SPINDLE_SPEED"]:
                raise CAMValueError(
                    f"Spindle speed {speed_value} is below the configured minimum "
                    f"({self.values['MIN_SPINDLE_SPEED']}) - posting aborted. This "
                    "usually means a spindle speed is missing.",
                    job=self._job,
                    operation=self._operation,
                    command=command,
                )
        return super()._convert_spindle_command(command)

    def _convert_tool_change(self, command: Path.Command):
        # A tool change means a new spindle speed is coming; don't carry the
        # old one forward onto moves before the next M3/M4.
        self._last_spindle_speed = None
        return super()._convert_tool_change(command)

    # ------------------------------------------------------------------
    # Sanity checks
    # ------------------------------------------------------------------

    def get_sanity_checks(self, job):
        squawks = []

        supports_tool_radius_comp = self.values.get("SUPPORTS_TOOL_RADIUS_COMPENSATION", False)
        if not supports_tool_radius_comp:
            operations = getattr(job.Operations, "Group", [])
            for op in operations:
                if hasattr(op, "Path") and op.Path:
                    for cmd in op.Path.Commands:
                        if hasattr(cmd, "Name") and cmd.Name in ["G41", "G42"]:
                            squawks.append(
                                self._create_squawk(
                                    "WARNING",
                                    f"Tool radius compensation ({cmd.Name}) used in "
                                    f"'{op.Label}' but not supported by the Makera "
                                    "controller.",
                                )
                            )
                            break
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
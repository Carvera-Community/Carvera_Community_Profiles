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


import argparse
import datetime
import Path.Post.Utils as PostUtils
import PathScripts.PathUtils as PathUtils
import FreeCAD
from FreeCAD import Units
import shlex
from builtins import open as pyopen

TOOLTIP = """
Version 1.1.0
This is a postprocessor file for the Path workbench. It is used to
take a pseudo-G-code fragment outputted by a Path object, and output
real G-code suitable for a makera cnc machine with a smoothieware based controller. This postprocessor, once placed
in the appropriate PathScripts folder, can be used directly from inside
FreeCAD, via the GUI importer or via python scripts with:

import makera_legacy_post
makera_legacy_post.export(object,"/path/to/file.ncc","")
"""

now = datetime.datetime.now()

parser = argparse.ArgumentParser(prog="linuxcnc", add_help=False)
parser.add_argument("--header", action="store_true", help="output headers (default)")
parser.add_argument("--no-header", action="store_true", help="suppress header output")
parser.add_argument("--comments", action="store_true", help="output comment (default)")
parser.add_argument("--no-comments", action="store_true", help="suppress comment output")
parser.add_argument("--line-numbers", action="store_true", help="prefix with line numbers")
parser.add_argument(
    "--no-line-numbers",
    action="store_true",
    help="don't prefix with line numbers (default)",
)
parser.add_argument(
    "--show-editor",
    action="store_true",
    help="pop up editor before writing output (default)",
)
parser.add_argument(
    "--no-show-editor",
    action="store_true",
    help="don't pop up editor before writing output",
)
parser.add_argument("--precision", default="4", help="number of digits of precision, default=4")
parser.add_argument(
    "--preamble",
    help='set commands to be issued before the first command, default="G90 G94\nG17"',
)
parser.add_argument(
    "--postamble",
    help='set commands to be issued after the last command, default="M05\nG17 G90\nG28\nM30"',
)
parser.add_argument("--IP_ADDR", help="IP Address for machine target machine")
parser.add_argument(
    "--verbose",
    action="store_true",
    help='verbose output for debugging, default="False"',
)

TOOLTIP_ARGS = parser.format_help()

# These globals set common customization preferences
OUTPUT_COMMENTS = True
OUTPUT_HEADER = True
IP_ADDR = None
VERBOSE = False

SPINDLE_SPEED = 0.0

if FreeCAD.GuiUp:
    SHOW_EDITOR = True
else:
    SHOW_EDITOR = False
MODAL = False  # if true commands are suppressed if the same as previous line.
COMMAND_SPACE = " "
LINENR = 100  # line number starting value

# These globals will be reflected in the Machine configuration of the project
UNITS = "G21"  # G21 for metric, G20 for us standard
UNIT_SPEED_FORMAT = "mm/min"
UNIT_FORMAT = "mm"

MACHINE_NAME = "Makera CNC Machine"
CORNER_MIN = {"x": 0, "y": 0, "z": 0}
CORNER_MAX = {"x": 500, "y": 300, "z": 300}
MOTION_MODE = "G90"
DRILL_RETRACT_MODE = (
    "G98"  # Default value of drill retractations (CURRENT_Z) other possible value is G99
)
CURRENT_X = 0
CURRENT_Y = 0
CURRENT_Z = 0

# Preamble text will appear at the beginning of the GCODE output file.
PREAMBLE = """G90 G94
G17
"""

# Postamble text will appear following the last operation.
POSTAMBLE = """M05
G17 G90
G28
M30
"""


# Pre operation text will be inserted before every operation
PRE_OPERATION = """"""

# Post operation text will be inserted after every operation
POST_OPERATION = """"""

# Tool Change commands will be inserted before a tool change
TOOL_CHANGE = """M05 \n"""

# Number of digits after the decimal point
PRECISION = 5

MOTION_COMMANDS = [
    "G0",
    "G00",
    "G1",
    "G01",
    "G2",
    "G02",
    "G3",
    "G03",
]  # Motion gCode commands definition


def _iter_path_objects(obj):
    """Yield obj and every nested Group member (Job / Compound / Operation)."""
    yield obj
    if hasattr(obj, "Group"):
        for child in obj.Group:
            for nested in _iter_path_objects(child):
                yield nested


def collect_tool_controllers(objectslist):
    """Return ToolControllers used by the posted objects, keyed by tool number."""
    by_number = {}
    jobs = set()

    for root in objectslist:
        for pathobj in _iter_path_objects(root):
            tc = getattr(pathobj, "ToolController", None)
            if tc is not None and hasattr(tc, "ToolNumber"):
                by_number[int(tc.ToolNumber)] = tc

            try:
                job = PathUtils.findParentJob(pathobj)
            except Exception:
                job = None
            if job is not None:
                jobs.add(job)

    for job in jobs:
        tools = getattr(job, "Tools", None)
        group = getattr(tools, "Group", None) if tools is not None else None
        if not group:
            continue
        for tc in group:
            if hasattr(tc, "ToolNumber"):
                by_number.setdefault(int(tc.ToolNumber), tc)

    return [by_number[number] for number in sorted(by_number)]


def _quantity_value(value, unit):
    """Convert a FreeCAD Quantity / number / unit-string to a float in `unit`."""
    if value is None or value == "":
        return None
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


def _tool_type_name(tool, bit_dict):
    """Return FreeCAD's native ShapeType (e.g. Endmill, Ballend, Drill).

    Modern ToolBits always expose ShapeType. If it is missing, prefer the
    serialized shape-type from to_dict(); otherwise emit unknown.
    """
    shape = getattr(tool, "ShapeType", None)
    if shape:
        return str(shape)

    shape = bit_dict.get("shape-type")
    if shape:
        return str(shape)

    return "unknown"


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


def format_tool_table_line(tool_controller):
    """Build one (@FC|TOOL|k=v|...) comment for a ToolController."""
    number = int(getattr(tool_controller, "ToolNumber", 0) or 0)
    tool = getattr(tool_controller, "Tool", None)
    if tool is None:
        return "(@FC|TOOL|number=%d|type=unknown)" % number

    bit_dict = _tool_bit_dict(tool)
    attributes = bit_dict.get("attribute") or {}

    name = (
        attributes.get("Description")
        or attributes.get("description")
        or getattr(tool, "Label", None)
        or getattr(tool_controller, "Label", "")
    )
    vendor = attributes.get("Vendor") or attributes.get("vendor") or ""
    product_id = bit_dict.get("id") or attributes.get("ProductId") or ""
    type_name = _tool_type_name(tool, bit_dict)

    diameter = _quantity_value(_tool_param(tool, bit_dict, "Diameter"), UNIT_FORMAT)
    shank = _quantity_value(
        _tool_param(tool, bit_dict, "ShankDiameter", "ShaftDiameter"), UNIT_FORMAT
    )
    tip = _quantity_value(_tool_param(tool, bit_dict, "TipDiameter"), UNIT_FORMAT)
    corner = _quantity_value(
        _tool_param(tool, bit_dict, "CornerRadius", "FlatRadius", "CuttingRadius"),
        UNIT_FORMAT,
    )
    flute = _quantity_value(
        _tool_param(tool, bit_dict, "CuttingEdgeHeight", "CuttingEdgeLength"),
        UNIT_FORMAT,
    )
    length = _quantity_value(_tool_param(tool, bit_dict, "Length"), UNIT_FORMAT)
    shoulder = _quantity_value(
        _tool_param(tool, bit_dict, "NeckLength", "ShoulderLength"), UNIT_FORMAT
    )
    pitch = _quantity_value(_tool_param(tool, bit_dict, "Pitch"), UNIT_FORMAT)
    cutting_edge_angle = _quantity_value(
        _tool_param(tool, bit_dict, "CuttingEdgeAngle", "cuttingAngle"), "deg"
    )
    tip_angle = _quantity_value(_tool_param(tool, bit_dict, "TipAngle"), "deg")
    taper_angle = _quantity_value(_tool_param(tool, bit_dict, "TaperAngle"), "deg")

    parts = ["@FC|TOOL"]
    _append_fc_field(parts, "number", number)
    _append_fc_field(parts, "name", name)
    _append_fc_field(parts, "vendor", vendor)
    _append_fc_field(parts, "id", product_id)
    _append_fc_field(parts, "type", type_name)
    _append_fc_field(parts, "diameter", diameter, PRECISION)
    _append_fc_field(parts, "shankdiameter", shank, PRECISION)
    _append_fc_field(parts, "tipdiameter", tip, PRECISION)
    _append_fc_field(parts, "cornerradius", corner, PRECISION)
    _append_fc_field(parts, "flutelength", flute, PRECISION)
    _append_fc_field(parts, "shoulderlength", shoulder, PRECISION)
    _append_fc_field(parts, "length", length, PRECISION)
    _append_fc_field(parts, "pitch", pitch, PRECISION)
    _append_fc_field(parts, "cuttingedgeangle", cutting_edge_angle, PRECISION)
    _append_fc_field(parts, "tipangle", tip_angle, PRECISION)
    _append_fc_field(parts, "taperangle", taper_angle, PRECISION)

    return "(" + "|".join(parts) + ")"


def dump_tool_table(objectslist):
    """Return G-code comment lines describing every tool used in the job."""
    controllers = collect_tool_controllers(objectslist)
    if not controllers:
        return ""

    lines = []
    for tool_controller in controllers:
        try:
            lines.append(format_tool_table_line(tool_controller) + "\n")
        except Exception as exc:
            FreeCAD.Console.PrintWarning(
                "Failed to dump tool T%s: %s\n"
                % (getattr(tool_controller, "ToolNumber", "?"), exc)
            )
    return "".join(lines)


def processArguments(argstring):
    global OUTPUT_HEADER
    global OUTPUT_COMMENTS
    global SHOW_EDITOR
    global IP_ADDR
    global VERBOSE
    global PRECISION
    global PREAMBLE
    global POSTAMBLE
    global UNITS
    global UNIT_SPEED_FORMAT
    global UNIT_FORMAT

    try:
        args = parser.parse_args(shlex.split(argstring))

        if args.no_header:
            OUTPUT_HEADER = False
        if args.header:
            OUTPUT_HEADER = True
        if args.no_comments:
            OUTPUT_COMMENTS = False
        if args.comments:
            OUTPUT_COMMENTS = True
        if args.no_show_editor:
            SHOW_EDITOR = False
        if args.show_editor:
            SHOW_EDITOR = True
        print("Show editor = %d" % SHOW_EDITOR)
        PRECISION = args.precision
        if args.preamble is not None:
            PREAMBLE = args.preamble
        if args.postamble is not None:
            POSTAMBLE = args.postamble
        if args.inches:
            UNITS = "G20"
            UNIT_SPEED_FORMAT = "in/min"
            UNIT_FORMAT = "in"

        IP_ADDR = args.IP_ADDR
        VERBOSE = args.verbose

    except Exception:
        return False

    return True


def export(objectslist, filename, argstring):
    processArguments(argstring)
    global UNITS
    for obj in objectslist:
        if not hasattr(obj, "Path"):
            FreeCAD.Console.PrintError(
                "the object "
                + obj.Name
                + " is not a path. Please select only path and Compounds.\n"
            )
            return

    FreeCAD.Console.PrintMessage("postprocessing...\n")
    gcode = ""

    # Find the machine.
    # The user my have overridden post processor defaults in the GUI.  Make
    # sure we're using the current values in the Machine Def.
    myMachine = None
    for pathobj in objectslist:
        if hasattr(pathobj, "MachineName"):
            myMachine = pathobj.MachineName
        if hasattr(pathobj, "MachineUnits"):
            if pathobj.MachineUnits == "Metric":
                UNITS = "G21"
            else:
                UNITS = "G20"
    if myMachine is None:
        FreeCAD.Console.PrintWarning("No machine found in this selection\n")

    # write header
    if OUTPUT_HEADER:
        gcode += "(Exported by FreeCAD)\n"
        gcode += "(Post Processor: " + __name__ + ")\n"
        gcode += "(Output Time:" + str(now) + ")\n"
        gcode += dump_tool_table(objectslist)

    # Write the preamble
    if OUTPUT_COMMENTS:
        gcode += "(begin preamble)\n"
    for line in PREAMBLE.splitlines(True):
        for xline in line.split("\\n"):
            gcode += xline
            gcode += "\n"
    gcode += "\n" + UNITS + "\n"

    for obj in objectslist:

        # do the pre_op
        if OUTPUT_COMMENTS:
            gcode +=  "(begin operation: " + obj.Label + ")\n"
        for line in PRE_OPERATION.splitlines(True):
            for xline in line.split("\\n"):
                gcode += xline
                gcode += "\n"

        gcode += parse(obj)

        # do the post_op
        if OUTPUT_COMMENTS:
            gcode += "(finish operation: " + obj.Label + ")\n"
        for line in POST_OPERATION.splitlines(True):
            for xline in line.split("\\n"):
                gcode += xline
                gcode += "\n"

    # do the post_amble

    if OUTPUT_COMMENTS:
        gcode += "(begin postamble)\n"
    for line in POSTAMBLE.splitlines(True):
        for xline in line.split("\\n"):
            gcode += xline
            gcode += "\n"
    gcode += "\n" + UNITS + "\n"

    if SHOW_EDITOR:
        dia = PostUtils.GCodeEditorDialog()
        dia.editor.setText(gcode)
        result = dia.exec_()
        if result:
            final = dia.editor.toPlainText()
        else:
            final = gcode
    else:
        final = gcode

    if IP_ADDR is not None:
        sendToSmoothie(IP_ADDR, final, filename)
    else:

        if not filename == "-":
            gfile = pyopen(filename, "w")
            gfile.write(final)
            gfile.close()

    FreeCAD.Console.PrintMessage("done postprocessing.\n")
    return final


def sendToSmoothie(ip, GCODE, fname):
    import sys
    import socket
    import os

    fname = os.path.basename(fname)
    FreeCAD.Console.PrintMessage("sending to makera: {}\n".format(fname))

    f = GCODE.rstrip()
    filesize = len(f)
    # make connection to sftp server
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(4.0)
    s.connect((ip, 115))
    tn = s.makefile(mode="rw")

    # read startup prompt
    ln = tn.readline()
    if not ln.startswith("+"):
        FreeCAD.Console.PrintMessage("Failed to connect with sftp: {}\n".format(ln))
        sys.exit()

    if VERBOSE:
        print("RSP: " + ln.strip())

    # Issue initial store command
    tn.write("STOR OLD /sd/" + fname + "\n")
    tn.flush()

    ln = tn.readline()
    if not ln.startswith("+"):
        FreeCAD.Console.PrintError("Failed to create file: {}\n".format(ln))
        sys.exit()

    if VERBOSE:
        print("RSP: " + ln.strip())

    # send size of file
    tn.write("SIZE " + str(filesize) + "\n")
    tn.flush()

    ln = tn.readline()
    if not ln.startswith("+"):
        FreeCAD.Console.PrintError("Failed: {}\n".format(ln))
        sys.exit()

    if VERBOSE:
        print("RSP: " + ln.strip())

    cnt = 0
    # now send file
    for line in f.splitlines(1):
        tn.write(line)
        if VERBOSE:
            cnt += len(line)
            print("SND: " + line.strip())
            print(str(cnt) + "/" + str(filesize) + "\r", end="")

    tn.flush()

    ln = tn.readline()
    if not ln.startswith("+"):
        FreeCAD.Console.PrintError("Failed to save file: {}\n".format(ln))
        sys.exit()

    if VERBOSE:
        print("RSP: " + ln.strip())

    # exit
    tn.write("DONE\n")
    tn.flush()
    tn.close()

    FreeCAD.Console.PrintMessage("Upload complete\n")


def parse(pathobj):
    global SPINDLE_SPEED
    import sys
    out = ""
    lastcommand = None
    precision_string = "." + str(PRECISION) + "f"

    # params = ['X','Y','Z','A','B','I','J','K','F','S'] #This list control
    # the order of parameters
    # linuxcnc doesn't want K properties on XY plane  Arcs need work.
    params = ["X", "Y", "Z", "A", "B", "I", "J", "F", "S", "T", "Q", "R", "L"]

    if hasattr(pathobj, "Group"):  # We have a compound or project.
        # if OUTPUT_COMMENTS:
        #     out +=  "(compound: " + pathobj.Label + ")\n"
        for p in pathobj.Group:
            out += parse(p)
        return out
    else:  # parsing simple path

        # fix for custom gcode operations
        if hasattr(pathobj, "Gcode"):
            for line in pathobj.Gcode:
                out += line.rstrip("\n") + "\n"
            return out

        # groups might contain non-path things like stock.
        if not hasattr(pathobj, "Path"):
            return out

        # if OUTPUT_COMMENTS:
        #     out +=  "(" + pathobj.Label + ")\n"

        for c in PathUtils.getPathWithPlacement(pathobj).Commands:
            outstring = []
            command = c.Name
            outstring.append(command)
            # if modal: only print the command if it is not the same as the
            # last one
            if MODAL is True:
                if command == lastcommand:
                    outstring.pop(0)

            # Now add the remaining parameters in order
            for param in params:
                if param in c.Parameters:
                    if param == "F":
                        if c.Name not in [
                            "G0",
                            "G00",
                        ]:  # linuxcnc doesn't use rapid speeds
                            speed = Units.Quantity(c.Parameters["F"], FreeCAD.Units.Velocity)
                            if float(speed.getValueAs(UNIT_SPEED_FORMAT))<5 :
                                FreeCAD.Console.PrintError(
                                    "feed rate of zero found. Posting cancelled"
                                )
                                sys.exit()

                            outstring.append(
                                param
                                + format(
                                    float(speed.getValueAs(UNIT_SPEED_FORMAT)),
                                    precision_string,
                                )
                            )
                    elif param == "T":
                        outstring.append(param + str(int(c.Parameters["T"])))
                    elif param == "S":
                        outstring.append(param + str(c.Parameters["S"]))
                        SPINDLE_SPEED = c.Parameters["S"]
                        if SPINDLE_SPEED <5 :
                            FreeCAD.Console.PrintError(
                                "spindle speed of zero found"
                            )
                            sys.exit()
                    else:
                        pos = Units.Quantity(c.Parameters[param], FreeCAD.Units.Length)
                        outstring.append(
                            param + format(float(pos.getValueAs(UNIT_FORMAT)), precision_string)
                        )
            if command in ["G1", "G01", "G2", "G02", "G3", "G03"]:
                outstring.append("S" + str(SPINDLE_SPEED))
                if SPINDLE_SPEED <5 :
                    FreeCAD.Console.PrintError(
                        "spindle speed of zero found"
                    )
            # Memorizes the current position for calculating the related movements and the withdrawal plan
            if command in MOTION_COMMANDS:
                if "X" in c.Parameters:
                    CURRENT_X = Units.Quantity(c.Parameters["X"], FreeCAD.Units.Length)
                if "Y" in c.Parameters:
                    CURRENT_Y = Units.Quantity(c.Parameters["Y"], FreeCAD.Units.Length)
                if "Z" in c.Parameters:
                    CURRENT_Z = Units.Quantity(c.Parameters["Z"], FreeCAD.Units.Length)

            if command in ("G98", "G99"):
                DRILL_RETRACT_MODE = command
                # Erase the line we just translated
                outstring = ["(start canned drilling cycle"] + outstring + [")"]
            if command in ("G80"):
                outstring = ["(end canned drilling cycle"] + outstring + [")"]
            if command in ("G90", "G91"):
                MOTION_MODE = command
                
            if command in ("G81", "G82", "G83"):
                out += drill_translate(outstring, command, c.Parameters)
                # Erase the line we just translated
                outstring = []
            # store the latest command
            lastcommand = command

            # Check for Tool Change:
            if command == "M6":
                # if OUTPUT_COMMENTS:
                #     out += "(begin toolchange)\n"
                for line in TOOL_CHANGE.splitlines(True):
                    out +=  line

            if command == "message":
                if OUTPUT_COMMENTS is False:
                    out = []
                else:
                    outstring.pop(0)  # remove the command

            # prepend a line number and append a newline
            if len(outstring) >= 1:

                # append the line to the final output
                for w in outstring:
                    out += w + COMMAND_SPACE
                out = out.strip() + "\n"

        return out


def drill_translate(outstring, cmd, params):
    global DRILL_RETRACT_MODE
    global MOTION_MODE
    global CURRENT_X
    global CURRENT_Y
    global CURRENT_Z
    global UNITS
    global UNIT_FORMAT
    global UNIT_SPEED_FORMAT

    strFormat = "." + str(PRECISION) + "f"
    trBuff = ""

    if OUTPUT_COMMENTS:  # Comment the original command
        outstring[0] = "(" + outstring[0]
        outstring[-1] = outstring[-1] + ")"
        trBuff += format_outstring(outstring) + "\n"

    # cycle conversion
    # currently only cycles in XY are provided (G17)
    # other plains ZX (G18) and  YZ (G19) are not dealt with : Z drilling only.
    param_X = Units.Quantity(params["X"], FreeCAD.Units.Length)
    param_Y = Units.Quantity(params["Y"], FreeCAD.Units.Length)
    param_Z = Units.Quantity(params["Z"], FreeCAD.Units.Length)
    param_R = Units.Quantity(params["R"], FreeCAD.Units.Length)
    # R less than Z is error
    if param_R < param_Z:
        trBuff += "(drill cycle error: R less than Z )\n"
        return trBuff

    if MOTION_MODE == "G91":  # G91 relative movements, (not generated by CAM WB drilling)
        param_X += CURRENT_X
        param_Y += CURRENT_Y
        param_Z += CURRENT_Z
        param_R += param_Z

    # NIST-RS274
    # 3.5.20 Set Canned Cycle Return Level — G98 and G99
    # When the spindle retracts during canned cycles, there is a choice of how far it retracts: (1) retract
    # perpendicular to the selected plane to the position indicated by the R word, or (2) retract
    # perpendicular to the selected plane to the position that axis was in just before the canned cycle
    # started (unless that position is lower than the position indicated by the R word, in which case use
    # the R word position).
    # To use option (1), program G99. To use option (2), program G98. Remember that the R word has
    # different meanings in absolute distance mode and incremental distance mode.
    # """

    if DRILL_RETRACT_MODE == "G99":
        clear_Z = param_R
    if DRILL_RETRACT_MODE == "G98" and CURRENT_Z >= param_R:
        clear_Z = CURRENT_Z
    else:
        clear_Z = param_R

    strG0_clear_Z = "G0 Z" + format(float(clear_Z.getValueAs(UNIT_FORMAT)), strFormat) + "\n"
    strG0_param_R = "G0 Z" + format(float(param_R.getValueAs(UNIT_FORMAT)), strFormat) + "\n"

    # get the other parameters
    drill_feedrate = Units.Quantity(params["F"], FreeCAD.Units.Velocity)
    strF_Feedrate = " F" + format(float(drill_feedrate.getValueAs(UNIT_SPEED_FORMAT)), ".2f") + "\n"

    if cmd == "G83":
        drill_Step = Units.Quantity(params["Q"], FreeCAD.Units.Length)
        a_bit = (
            drill_Step * 0.05
        )  # NIST 3.5.16.4 G83 Cycle:  "current hole bottom, backed off a bit."
    elif cmd == "G82":
        drill_DwellTime = params["P"]

    # wrap this block to ensure machine MOTION_MODE is restored in case of error
    try:
        if MOTION_MODE == "G91":
            trBuff += "G90\n"  # force absolute coordinates during cycles

        # NIST-RS274
        # 3.5.16.1 Preliminary and In-Between Motion
        # At the very beginning of the execution of any of the canned cycles, with the XY-plane selected, if
        # the current Z position is below the R position, the Z-axis is traversed to the R position. This
        # happens only once, regardless of the value of L.
        # In addition, at the beginning of the first cycle and each repeat, the following one or two moves are
        # made:
        # 1. a straight traverse parallel to the XY-plane to the given XY-position,
        # 2. a straight traverse of the Z-axis only to the R position, if it is not already at the R position.

        if CURRENT_Z < param_R:
            trBuff += strG0_param_R
        trBuff += (
            "G0 X"
            + format(float(param_X.getValueAs(UNIT_FORMAT)), strFormat)
            + " Y"
            + format(float(param_Y.getValueAs(UNIT_FORMAT)), strFormat)
            + "\n"
        )
        if CURRENT_Z > param_R:
            trBuff += strG0_param_R

        last_Stop_Z = param_R

        # drill moves
        if cmd in ("G81", "G82"):
            trBuff += (
                "G1 Z"
                + format(float(param_Z.getValueAs(UNIT_FORMAT)), strFormat)
                + strF_Feedrate
            )
            # pause where applicable
            if cmd == "G82":
                trBuff += "G4 P" + str(drill_DwellTime) + "\n"
            trBuff += strG0_clear_Z
        else:  # 'G83'
            if params["Q"] != 0:
                while 1:
                    if last_Stop_Z != clear_Z:
                        clearance_depth = (
                            last_Stop_Z + a_bit
                        )  # rapid move to just short of last drilling depth
                        trBuff += (
                            "G0 Z"
                            + format(
                                float(clearance_depth.getValueAs(UNIT_FORMAT)),
                                strFormat,
                            )
                            + "\n"
                        )
                    next_Stop_Z = last_Stop_Z - drill_Step
                    if next_Stop_Z > param_Z:
                        trBuff += (
                            "G1 Z"
                            + format(float(next_Stop_Z.getValueAs(UNIT_FORMAT)), strFormat)
                            + strF_Feedrate
                        )
                        trBuff += strG0_clear_Z
                        last_Stop_Z = next_Stop_Z
                    else:
                        trBuff += (
                            "G1 Z"
                            + format(float(param_Z.getValueAs(UNIT_FORMAT)), strFormat)
                            + strF_Feedrate
                        )
                        trBuff += strG0_clear_Z
                        break

    except Exception as e:
        pass

    if MOTION_MODE == "G91":
        trBuff += "G91"  # Restore if changed

    return trBuff

def format_outstring(strTable):
    global COMMAND_SPACE
    # construct the line for the final output
    s = ""
    for w in strTable:
        s += w + COMMAND_SPACE
    s = s.strip()
    return s

# print(__name__ + " gcode postprocessor loaded.")

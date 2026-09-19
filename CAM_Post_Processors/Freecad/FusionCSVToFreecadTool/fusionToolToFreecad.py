#!/usr/bin/env python3
import csv
import json
import os
import re
import unicodedata
import argparse

# ------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------
parser = argparse.ArgumentParser(description="Convert tool CSVs to .fctb/.fctl")
parser.add_argument(
    "--overwrite",
    choices=["overwrite", "append", "skip"],
    default="append",
    help="File handling mode: overwrite | append | skip"
)
parser.add_argument(
    "--dry-run",
    action="store_true",
    help="Perform a trial run with no file writes"
)
args = parser.parse_args()

MODE = args.overwrite
DRY_RUN = args.dry_run

# ------------------------------------------------------------
# Output directories
# ------------------------------------------------------------
output_dir = "output"
bit_dir = os.path.join(output_dir, "Bit")
library_dir = os.path.join(output_dir, "Library")

os.makedirs(bit_dir, exist_ok=True)
os.makedirs(library_dir, exist_ok=True)

# ------------------------------------------------------------
# Summary counters
# ------------------------------------------------------------
summary = {
    "created": 0,
    "overwritten": 0,
    "skipped": 0,
    "appended": 0,
}

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
def safe_filename(name):
    """Sanitize a filename to be safe across platforms."""
    name = unicodedata.normalize("NFKD", name)
    name = re.sub(r'(?u)[^-\w.]', '_', name)
    name = name.strip(" .")
    name = re.sub(r'__+', '_', name)

    reserved = {
        "CON", "PRN", "AUX", "NUL",
        *(f"COM{i}" for i in range(1, 10)),
        *(f"LPT{i}" for i in range(1, 10))
    }
    base = name.split('.')[0].upper()
    if base in reserved:
        name = "_" + name

    return name or "unnamed"

def format_with_units(value, source_unit):
    """
    Convert numeric values from mm or inch source units
    and automatically choose the best output unit. Freecad expects micrometers 
    below 0.1mm and microinches below 0.005 inch
    """

    if value is None or value == "":
        return None

    try:
        v = float(value)
    except ValueError:
        return None

    source_unit = source_unit.lower()

    if source_unit == "millimeters":
        if abs(v) < 0.1:
            return f"{v * 1000:.2f} \u00b5m"
        else:
            return f"{v:.3f} mm"
    if source_unit == "inches":
        if abs(v) < 0.005:
            return f"{v * 1_000_000:.1f} µin"
        else:
            return f"{v:.4f} in"
    if abs(v) < 0.1:
        return f"{v * 1000:.2f} \u00b5m"
    return f"{v:.3f} mm"

def resolve_conflict(path):
    """
    Apply overwrite mode rules:
    - overwrite: return original path
    - skip: return None if file already exists
    - append: return new path like name_1.ext
    """
    exists = os.path.exists(path)

    if MODE == "overwrite":
        if exists:
            summary["overwritten"] += 1
        return path

    if not exists:
        return path

    if MODE == "skip":
        summary["skipped"] += 1
        return None

    if MODE == "append":
        base, ext = os.path.splitext(path)
        i = 1
        new_path = f"{base}_{i}{ext}"
        while os.path.exists(new_path):
            i += 1
            new_path = f"{base}_{i}{ext}"

        summary["appended"] += 1
        return new_path


# ------------------------------------------------------------
# Main conversion logic
# ------------------------------------------------------------
def convert_row_to_json(row):
    def get_value(key):
        return row.get(key, "").strip()
    parameter = {}
    name = f"Makera_{get_value('Description (tool_description)')}_{get_value('Preset Name (preset_name)')}".strip()

    toolType = get_value('Type (tool_type)')
    shape = "endmill.fcstd"
    toolTypeOut = "Endmill"

    unit =  get_value("Unit (tool_unit)").lower()
    
    if toolType == 'drill':
        shape = "drill.fcstd"
        toolTypeOut = "Endmill"
    if toolType == 'ball end mill':
        shape = "ballend.fcstd"
        toolTypeOut = "Ballend"
    if toolType == 'chamfer mill':
        desc = get_value("Description (tool_description)").lower()
        if "chamfer" in desc:
            shape = "chamfer.fcstd"
            toolTypeOut = "Chamfer"
        else:
            shape = "v-bit.fcstd"
            toolTypeOut = "VBit"
    if toolType == 'thread mill':
        shape = "thread-mill.fcstd"
        toolTypeOut = "ThreadMill"
    if toolType == 'bull nose end mill':
        shape = "bullnose.fcstd"
        toolTypeOut = "Bullnose"
    
    if toolType == 'tap right hand':
      shape = "tap.fcstd"
      toolTypeOut = "Tap"
      parameter["SpindleDirection"] = "Forward"

    if toolType == 'tap left hand':
      shape = "tap.fcstd"
      toolTypeOut = "Tap"
      parameter["SpindleDirection"] = "Reverse"

    if toolType == 'slot mill':
      shape = "slittingsaw.fcstd"
      toolTypeOut = "SlittingSaw"

    if toolType == 'reamer':
      shape = "reamer.fcstd"
      toolTypeOut = "Reamer"

    if toolType == 'dovetail mill':
      shape = "dovetail.fcstd"
      toolTypeOut = "Dovetail"


    
    chipload = get_value("Feed per Tooth (tool_feedPerTooth)")
    if toolType == 'drill' or not chipload:
        chipload = get_value("Plunge Feed per Revolution (tool_feedPerRevolution)")
    formatted = format_with_units(chipload, unit)
    if formatted:
        parameter["Chipload"] = formatted
    
    cutting_edge_height = get_value("Flute Length (tool_fluteLength)")
    if cutting_edge_height:
        if toolType == 'slot mill':
            formatted = format_with_units(cutting_edge_height, unit)
            if formatted:
                parameter["BladeThickness"] = formatted
        else:
            formatted = format_with_units(cutting_edge_height, unit)
            if formatted:
                parameter["CuttingEdgeHeight"] = formatted
                parameter["CuttingEdgeLength"] = formatted
                

    diameter = get_value("Diameter (tool_diameter)")
    formatted = format_with_units(diameter, unit)
    if formatted:
        parameter["Diameter"] = formatted

    length = get_value("Overall Length (tool_overallLength)")
    if length:
        formatted = format_with_units(length, unit)
        if formatted:
            parameter["Length"] = formatted
        
    cornerRadius = get_value("Corner Radius (tool_cornerRadius)")
    if cornerRadius:
        formatted = format_with_units(cornerRadius, unit)
        if formatted:
            parameter["CornerRadius"] = formatted
    
    pitch = get_value("Thread Pitch (tool_threadPitch)")
    if pitch:
        formatted = format_with_units(pitch, unit)
        if formatted:
            parameter["Pitch"] = formatted
          
    tipAngle = get_value("Tip Angle (tool_tipAngle)")
    if tipAngle:
        parameter["CuttingEdgeAngle"] = tipAngle
    else:
        tipAngle = get_value("Taper Angle (tool_taperAngle)")
    if tipAngle:
        try:
            angle_value = float(tipAngle)
            parameter["CuttingEdgeAngle"] = angle_value * 2
        except ValueError:
            parameter["CuttingEdgeAngle"] = tipAngle

    TipDiameter = get_value("Tip Diameter (tool_tipDiameter)")
    if TipDiameter:
        formatted = format_with_units(TipDiameter, unit)
        if formatted:
            parameter["TipDiameter"] = formatted

    cuttingAngle = get_value("Thread Profile Angle (tool_threadProfileAngle)")
    if cuttingAngle:
        parameter["cuttingAngle"] = cuttingAngle

    crest = get_value("Thread Tip Width (tool_threadTipWidth)")
    if crest:
        formatted = format_with_units(crest, unit)
        if formatted:
            parameter["Crest"] = formatted

    parameter["ShankDiameter"] = get_value("Shaft Diameter (tool_shaftDiameter)")
    parameter["Material"] = "Carbide"
    parameter["Flutes"] = get_value("Number of Flutes (tool_numberOfFlutes)")

    
    attribute = {}
    def add_attr(key, csv_key):
        val = get_value(csv_key)
        if val:
            attribute[key] = val

    add_attr("ToolType", "Type (tool_type)")
    add_attr("Description", "Description (tool_description)")
    add_attr("Vendor", "Holder Vendor (holder_vendor)")
    add_attr("ProductLink", "Holder Product Link (holder_productLink)")
    add_attr("cutting_feedrate", "Cutting Feedrate (tool_feedCutting)")
    add_attr("lead_in_feedrate", "Lead-In Feedrate (tool_feedEntry)")
    add_attr("plunge_feedrate", "Plunge Feedrate (tool_feedPlunge)")
    add_attr("ramp_feedrate", "Ramp Feedrate (tool_feedRamp)")
    add_attr("rampAngle", "Ramp Angle (tool_rampAngle)")
    add_attr("spindleSpeed", "Spindle Speed (tool_spindleSpeed)")
    add_attr("stepdown", "Stepdown (tool_stepdown)")
    add_attr("stepover", "Stepover (tool_stepover)")

    return {
        "version": 2,
        "name": name,
        "shape": shape,
        "shape-type": toolTypeOut,
        "parameter": parameter,
        "attribute": attribute
    }


# ------------------------------------------------------------
# Process all CSVs
# ------------------------------------------------------------
input_dir = "."

for filename in os.listdir(input_dir):
    if filename.lower().endswith(".csv"):
        csv_path = os.path.join(input_dir, filename)
        print(f"Processing {csv_path} ...")

        tool_list = []
        nr = 1

        with open(csv_path, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)

            for row in reader:
                tool_json = convert_row_to_json(row)

                json_filename = safe_filename(tool_json["name"]) + ".fctb"
                filepath = os.path.join(bit_dir, json_filename)
                final_path = resolve_conflict(filepath)

                if final_path and not DRY_RUN:
                    with open(final_path, "w", encoding="utf-8") as out_f:
                        json.dump(tool_json, out_f, indent=2)
                    summary["created"] += 1

                if final_path:
                    tool_list.append({
                        "nr": nr,
                        "path": os.path.basename(final_path)
                    })
                    nr += 1

        # Write the .fctl file
        fctl_name = os.path.splitext(filename)[0] + ".fctl"
        fctl_path = os.path.join(library_dir, fctl_name)
        fctl_final = resolve_conflict(fctl_path)

        fctl_json = {
            "label": os.path.splitext(filename)[0],
            "tools": tool_list,
            "version": 1
        }

        if fctl_final and not DRY_RUN:
            with open(fctl_final, "w", encoding="utf-8") as fctl_out:
                json.dump(fctl_json, fctl_out, indent=2)
            summary["created"] += 1

# ------------------------------------------------------------
# Summary output
# ------------------------------------------------------------
print("\n========== SUMMARY ==========")
print(f"Mode:        {MODE}")
print(f"Dry run:     {DRY_RUN}")
print(f"Created:     {summary['created']}")
print(f"Overwritten: {summary['overwritten']}")
print(f"Appended:    {summary['appended']}")
print(f"Skipped:     {summary['skipped']}")
print("================================\n")


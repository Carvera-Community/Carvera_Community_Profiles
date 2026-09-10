#!/usr/bin/env python3
"""Check or update only the three missing thread-mill geometry parameters."""
import argparse
from copy import deepcopy
import json
from pathlib import Path
import re
import sys

from threadmill_geometry import DEFAULT_LIBRARY, mm, source_tools, threadmill_parameters

FREECAD = Path(__file__).resolve().parents[1]
MATERIALS = {"Aluminum", "Brass", "Copper", "Hardwood", "Plastic", "Softwood"}


def raw_mm(value):
    # Existing .fctb shank diameters have no unit and are implicitly millimeters.
    parts = str(value).strip().split()
    if len(parts) == 1:
        return mm(parts[0], "millimeters", "fctb dimension")
    units = {"mm": "millimeters", "in": "inches"}
    if len(parts) != 2 or parts[1] not in units:
        raise ValueError("Unsupported .fctb dimension: " + str(value))
    return mm(parts[0], units[parts[1]], "fctb dimension")


def plan(bit_dir, library):
    sources = source_tools(str(library))
    changes, seen = [], set()
    paths = sorted(Path(bit_dir).glob("Makera_Carvera_M*_Threadmill_*.fctb"))
    for path in paths:
        match = re.fullmatch(r"Makera_(Carvera_M\d+(?:\.\d+)?_Threadmill)_([^/]+)\.fctb", path.name)
        if not match or match[2] not in MATERIALS:
            raise ValueError("Unexpected thread-mill variant: " + path.name)
        description, material = match[1].replace("_", " "), match[2]
        if description not in sources or (description, material) in seen:
            raise ValueError("Unknown or duplicate source: " + path.name)
        seen.add((description, material))
        source = sources[description]
        before = path.read_bytes()
        data = json.loads(before)
        if Path(data.get("shape", "")).stem != "thread-mill":
            raise ValueError("Unexpected shape: " + path.name)
        declared = data.get("attribute", {}).get("Description", description)
        if declared != description:
            raise ValueError("Description mismatch: " + path.name)
        params = data["parameter"]
        for field, attribute in (("Diameter", "diameter"), ("Length", "overall-length"),
                                 ("ShankDiameter", "shaft-diameter"), ("Pitch", "thread-pitch")):
            if abs(raw_mm(params[field]) - mm(source[attribute], source["unit"], attribute)) > mm("0.0001", "millimeters", "tolerance"):
                raise ValueError("Main geometry differs from HSM: " + path.name + " / " + field)
        row = {"Unit (tool_unit)": source["unit"],
               "Description (tool_description)": description,
               "Diameter (tool_diameter)": source["diameter"],
               "Overall Length (tool_overallLength)": source["overall-length"]}
        correction = threadmill_parameters(row, library)
        after = deepcopy(data)
        after["parameter"].update(correction)
        if after != data:
            # Patch just three properties in place; keep every other byte intact.
            text = before.decode("utf-8")
            start = text.index('"parameter"')
            end = text.index("}", start)
            block = text[start:end]
            for key, value in correction.items():
                pattern = r'("' + re.escape(key) + r'"\s*:\s*)"[^"]*"'
                if re.search(pattern, block):
                    block = re.sub(pattern, lambda m: m[1] + json.dumps(value), block, count=1)
                else:
                    anchor = re.search(r'(?m)^(\s*)"ShankDiameter"\s*:', block)
                    if not anchor:
                        raise ValueError("Cannot locate insertion point: " + path.name)
                    newline = "\r\n" if "\r\n" in block else "\n"
                    addition = anchor[1] + json.dumps(key) + ": " + json.dumps(value) + "," + newline
                    block = block[:anchor.start()] + addition + block[anchor.start():]
            result = (text[:start] + block + text[end:]).encode("utf-8")
            if json.loads(result) != after:
                raise ValueError("Unexpected JSON modification: " + path.name)
            changes.append((path, before, result))
    expected = {(name, material) for name in sources for material in MATERIALS}
    if seen != expected:
        raise ValueError("Incomplete variant coverage: expected %d, found %d" % (len(expected), len(seen)))
    return changes, len(seen)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Update files (default: check only)")
    parser.add_argument("--bit-dir", type=Path, default=FREECAD / "Tools" / "Bit")
    parser.add_argument("--library", type=Path, default=DEFAULT_LIBRARY)
    args = parser.parse_args()
    try:
        changes, count = plan(args.bit_dir, args.library)
        if changes and not args.write:
            print("%d/%d definitions need updating." % (len(changes), count))
            return 1
        if args.write:
            written = []
            try:
                for path, before, after in changes:
                    if path.read_bytes() != before:
                        raise RuntimeError("File changed during validation: " + str(path))
                    # Keep the original available even if an individual write fails.
                    written.append((path, before))
                    path.write_bytes(after)
            except Exception:
                for path, before in written:
                    path.write_bytes(before)
                raise
        print("%d definitions checked; %d updated." % (count, len(changes) if args.write else 0))
        return 0
    except (OSError, ValueError, KeyError, RuntimeError) as exc:
        print("ERROR: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())

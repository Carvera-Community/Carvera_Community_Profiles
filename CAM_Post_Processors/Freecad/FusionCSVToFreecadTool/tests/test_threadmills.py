"""Run with python3 -m unittest discover -s <this directory> -v; no FreeCAD needed."""
from copy import deepcopy
from decimal import Decimal
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

MODULE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODULE_DIR))
from threadmill_geometry import DEFAULT_LIBRARY, csv_value, source_tools, threadmill_parameters
from sync_threadmills import plan, raw_mm

FIELDS = {"NeckDiameter", "NeckLength", "Crest"}


def row(**values):
    data = {"tool_description": "Carvera M3 Threadmill", "tool_type": "thread mill",
            "tool_unit": "millimeters", "tool_diameter": "2.42", "tool_overallLength": "38",
            "tool_shaftDiameter": "3.175", "tool_threadPitch": "0.5"}
    data.update(values)
    return {"Label (" + k + ")": v for k, v in data.items()}


class ThreadMillUnitTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.library = Path(self.tmp.name) / "geometry.hsmlib"
        namespace = "http://www.hsmworks.com/xml/2004/cnc/tool-library"
        root = ET.Element("tool-library", xmlns=namespace)
        tool = ET.SubElement(root, "tool", type="thread mill", unit="millimeters")
        ET.SubElement(tool, "description").text = "Carvera M3 Threadmill"
        ET.SubElement(tool, "body", {"diameter": "2.42", "overall-length": "38",
                      "shaft-diameter": "3.175", "thread-pitch": "0.5",
                      "shoulder-diameter": "1.553975", "shoulder-length": "9",
                      "thread-tip-type": "point"})
        ET.ElementTree(root).write(self.library, encoding="utf-16", xml_declaration=True)

    def test_missing_csv_dimensions_use_utf16_hsm_source(self):
        self.assertEqual(threadmill_parameters(row(), self.library),
                         {"NeckDiameter": "1.553975 mm", "NeckLength": "9 mm", "Crest": "0 mm"})

    def test_explicit_csv_preserves_precision_without_hsm_file(self):
        data = row(tool_shoulderDiameter="0.2969873", tool_shoulderLength="3",
                   tool_threadTipType="point")
        result = threadmill_parameters(data, Path(self.tmp.name) / "missing")
        self.assertEqual(result["NeckDiameter"], "0.2969873 mm")

    def test_csv_inches_are_not_treated_as_mm(self):
        data = row(tool_unit="inches", tool_diameter="0.125", tool_overallLength="1.5",
                   tool_shoulderDiameter="0.04", tool_shoulderLength="0.25", tool_threadTipType="point")
        result = threadmill_parameters(data, self.library)
        self.assertEqual(result, {"NeckDiameter": "1.016 mm", "NeckLength": "6.35 mm", "Crest": "0 mm"})

    def test_point_ignores_inactive_tip_width(self):
        data = row(tool_shoulderDiameter="1.553975", tool_shoulderLength="9",
                   tool_threadTipType="point", tool_threadTipWidth="0.1")
        self.assertEqual(threadmill_parameters(data, self.library)["Crest"], "0 mm")

    def test_explicit_flat_tip_width_is_preserved(self):
        data = row(tool_shoulderDiameter="1.553975", tool_shoulderLength="9",
                   tool_threadTipType="flat", tool_threadTipWidth="0.075")
        self.assertEqual(threadmill_parameters(data, self.library)["Crest"], "0.075 mm")

    def test_unknown_source_is_rejected_not_guessed(self):
        with self.assertRaisesRegex(ValueError, "Incomplete"):
            threadmill_parameters(row(tool_description="Custom M3"), self.library)

    def test_stale_source_diameter_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "mismatch"):
            threadmill_parameters(row(tool_diameter="2.6"), self.library)

    def test_invalid_or_nonfinite_dimensions_are_rejected(self):
        for diameter in ("NaN", "Infinity", "-1", "0", "3"):
            with self.subTest(diameter=diameter), self.assertRaises(ValueError):
                threadmill_parameters(row(tool_shoulderDiameter=diameter,
                                         tool_shoulderLength="9", tool_threadTipType="point"), self.library)

    def test_blank_csv_value_and_duplicate_columns(self):
        self.assertEqual(csv_value({"Col (tool_shoulderDiameter)": None}, "tool_shoulderDiameter"), "")
        with self.assertRaises(ValueError):
            csv_value({"A (tool_shoulderDiameter)": "1", "B (tool_shoulderDiameter)": "2"}, "tool_shoulderDiameter")


    def test_m3_csv_rounding_preserves_hsm_precision(self):
        data = row(tool_shoulderDiameter="1.55397", tool_shoulderLength="9",
                   tool_threadTipType="point")
        self.assertEqual(threadmill_parameters(data, self.library, prefer_library=True),
                         {"NeckDiameter": "1.553975 mm", "NeckLength": "9 mm", "Crest": "0 mm"})

    def test_known_tool_conflicting_neck_is_rejected(self):
        data = row(tool_shoulderDiameter="1.6", tool_shoulderLength="9",
                   tool_threadTipType="point")
        with self.assertRaisesRegex(ValueError, "dimension mismatch"):
            threadmill_parameters(data, self.library, prefer_library=True)

    def test_unknown_tool_with_complete_csv_still_works(self):
        data = row(tool_description="Custom M3", tool_shoulderDiameter="1.4",
                   tool_shoulderLength="8", tool_threadTipType="point")
        self.assertEqual(threadmill_parameters(data, self.library, prefer_library=True)["NeckDiameter"], "1.4 mm")

    def test_prefer_library_without_library_accepts_complete_csv(self):
        data = row(tool_shoulderDiameter="1.55397", tool_shoulderLength="9",
                   tool_threadTipType="point")
        result = threadmill_parameters(data, Path(self.tmp.name)/"missing", prefer_library=True)
        self.assertEqual(result["NeckDiameter"], "1.55397 mm")

    def test_known_tool_conflicting_tip_type_is_rejected(self):
        data = row(tool_shoulderDiameter="1.55397", tool_shoulderLength="9",
                   tool_threadTipType="flat", tool_threadTipWidth="0.1")
        with self.assertRaisesRegex(ValueError, "tip type mismatch"):
            threadmill_parameters(data, self.library, prefer_library=True)

class RepositoryTests(unittest.TestCase):
    def test_every_shipped_variant_matches_source(self):
        changes, count = plan(MODULE_DIR.parent / "Tools" / "Bit", DEFAULT_LIBRARY)
        self.assertEqual(count, 48)
        self.assertEqual(changes, [], "Run sync_threadmills.py --write")
        sources = source_tools(str(DEFAULT_LIBRARY))
        self.assertEqual(len(sources), 8)
        for path in (MODULE_DIR.parent / "Tools" / "Bit").glob("Makera_Carvera_M*_Threadmill_*.fctb"):
            data = json.loads(path.read_bytes())
            name = path.stem.removeprefix("Makera_").rsplit("_", 1)[0].replace("_", " ")
            body = sources[name]
            for key, source_key in (("NeckDiameter", "shoulder-diameter"), ("NeckLength", "shoulder-length")):
                with self.subTest(file=path.name, parameter=key):
                    self.assertEqual(raw_mm(data["parameter"][key]), Decimal(body[source_key]))
            self.assertEqual(body["thread-tip-type"], "point")
            self.assertEqual(raw_mm(data["parameter"]["Crest"]), Decimal(0))

    def test_sync_is_minimal_and_idempotent(self):
        original_dir = MODULE_DIR.parent / "Tools" / "Bit"
        with tempfile.TemporaryDirectory() as tmp:
            copies = Path(tmp)
            originals = {}
            for file in original_dir.glob("Makera_Carvera_M*_Threadmill_*.fctb"):
                data = json.loads(file.read_bytes())
                for field in FIELDS:
                    data["parameter"].pop(field, None)
                text = json.dumps(data, indent=2)
                (copies / file.name).write_text(text, encoding="utf-8")
                originals[file.name] = data
            changes, count = plan(copies, DEFAULT_LIBRARY)
            self.assertEqual(len(changes), count)
            for path, before, after in changes:
                data = json.loads(after)
                stripped = deepcopy(data)
                for field in FIELDS:
                    stripped["parameter"].pop(field)
                self.assertEqual(stripped, originals[path.name])
                path.write_bytes(after)
            self.assertEqual(plan(copies, DEFAULT_LIBRARY)[0], [])

    def test_converter_regeneration_changes_only_thread_geometry(self):
        # Run the real CSVs through the old and patched converter in temporary dirs.
        converter = MODULE_DIR / "fusionToolToFreecad.py"
        source = converter.read_text(encoding="utf-8")
        import_line = "from threadmill_geometry import threadmill_parameters\n"
        update = '    if toolType == "thread mill":\n        parameter.update(threadmill_parameters(row, args.threadmill_library, prefer_library=True))\n\n'
        self.assertEqual(source.count(import_line), 1)
        self.assertEqual(source.count(update), 1)
        baseline = source.replace(import_line, "", 1).replace(update, "", 1)
        csv_dir = DEFAULT_LIBRARY.parent.parent / "csv"
        csv_files = sorted(csv_dir.glob("*.csv"))
        self.assertTrue(csv_files, "Missing source CSVs")
        with tempfile.TemporaryDirectory() as tmp:
            before, after = Path(tmp) / "before", Path(tmp) / "after"
            before.mkdir()
            after.mkdir()
            baseline_file = Path(tmp) / "baseline.py"
            baseline_file.write_text(baseline, encoding="utf-8")
            for directory, program in ((before, baseline_file), (after, converter)):
                for csv in csv_files:
                    shutil.copy2(csv, directory / csv.name)
                result = subprocess.run([sys.executable, str(program), "--overwrite", "overwrite"],
                                        cwd=directory, capture_output=True, text=True, timeout=120)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            previous = {p.name: json.loads(p.read_bytes()) for p in (before / "output" / "Bit").glob("*.fctb")}
            updated = {p.name: json.loads(p.read_bytes()) for p in (after / "output" / "Bit").glob("*.fctb")}
            self.assertEqual(previous.keys(), updated.keys())
            corrected = 0
            for name, data in updated.items():
                old = previous[name]
                if data["shape"] != "thread-mill.fcstd":
                    self.assertEqual(data, old, name)
                    continue
                corrected += 1
                shipped = json.loads((MODULE_DIR.parent / "Tools" / "Bit" / name).read_bytes())
                for field in FIELDS:
                    self.assertEqual(raw_mm(data["parameter"][field]), raw_mm(shipped["parameter"][field]), name)
                for document in (data, old):
                    for field in FIELDS:
                        document["parameter"].pop(field, None)
                self.assertEqual(data, old, name)
            self.assertEqual(corrected, 48)
            old_libraries = {p.name: p.read_bytes() for p in (before / "output" / "Library").glob("*.fctl")}
            new_libraries = {p.name: p.read_bytes() for p in (after / "output" / "Library").glob("*.fctl")}
            self.assertEqual(old_libraries, new_libraries)


if __name__ == "__main__":
    unittest.main()

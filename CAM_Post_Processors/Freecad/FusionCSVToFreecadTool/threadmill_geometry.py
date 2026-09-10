"""Translate Fusion thread-mill geometry without inheriting FreeCAD defaults."""
from decimal import Decimal, InvalidOperation
from functools import lru_cache
from pathlib import Path
import xml.etree.ElementTree as ET

DEFAULT_LIBRARY = (Path(__file__).resolve().parents[2] / "Fusion360-profiles"
                   / "Tool Files" / "hsmlib" / "Makera Thread Mills.hsmlib")
UNIT_MM = {"millimeters": Decimal("1"), "inches": Decimal("25.4")}


def csv_value(row, parameter):
    """Match the Fusion parameter identifier, not a localized column label."""
    suffix = "(" + parameter + ")"
    values = {str(value).strip() for key, value in row.items()
              if key and key.endswith(suffix) and value is not None
              and str(value).strip()}
    if len(values) > 1:
        raise ValueError("Conflicting CSV columns for " + parameter)
    return next(iter(values), "")


def number(value, label):
    try:
        result = Decimal(str(value))
    except (InvalidOperation, ValueError) as exc:
        raise ValueError("Invalid numeric value for " + label) from exc
    if not result.is_finite():
        raise ValueError("Non-finite numeric value for " + label)
    return result


def mm(value, unit, label):
    if unit not in UNIT_MM:
        raise ValueError("Unsupported tool unit: " + repr(unit))
    return number(value, label) * UNIT_MM[unit]


def quantity(value):
    # Avoid the generic exporter's 3-decimal rounding for the small necks.
    text = format(value, "f")
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return (text if value else "0") + " mm"


@lru_cache(maxsize=4)
def source_tools(library):
    """Read the existing HSM library, including its declared XML encoding."""
    tools = {}
    for tool in ET.parse(library).getroot().findall("{*}tool"):
        if tool.get("type") != "thread mill":
            continue
        description = tool.findtext("{*}description", "").strip()
        body = tool.find("{*}body")
        if not description or body is None or description in tools:
            raise ValueError("Missing or duplicate thread-mill source: " + description)
        tools[description] = {"unit": tool.get("unit", ""), **body.attrib}
    if not tools:
        raise ValueError("No thread mills in " + str(library))
    return tools


def threadmill_parameters(row, library=None, *, prefer_library=False):
    """Return explicit geometry, optionally preserving a known HSM tool's precision.

    With prefer_library, named HSM tools are used only after cross-checking CSV
    dimensions. CSV exports are rounded to six significant digits; accept at
    most half a unit in that last digit, not an arbitrary geometry tolerance.
    Unknown tools with complete CSV geometry do not require an HSM entry.
    """
    get = lambda key: csv_value(row, key)
    unit = get("tool_unit").lower()
    description = get("tool_description")
    neck = get("tool_shoulderDiameter")
    length = get("tool_shoulderLength")
    tip = get("tool_threadTipType").lower()
    width = get("tool_threadTipWidth")
    source = None
    library_path = Path(library or DEFAULT_LIBRARY)
    needs_source = (not neck or not length or (not tip and not width)
                    or (tip != "point" and not width))
    if (prefer_library and library_path.is_file()) or needs_source:
        source = source_tools(str(library_path)).get(description)
    if needs_source and source is None:
        raise ValueError("Incomplete thread-mill geometry: " + description)

    if source is not None:
        for key, attribute in (("tool_diameter", "diameter"),
                               ("tool_shaftDiameter", "shaft-diameter"),
                               ("tool_overallLength", "overall-length"),
                               ("tool_threadPitch", "thread-pitch")):
            value = get(key)
            if value and abs(mm(value, unit, key) - mm(source[attribute], source["unit"], attribute)) > Decimal("0.0001"):
                raise ValueError("CSV/HSM geometry mismatch: " + description + " / " + key)
        source_tip = source.get("thread-tip-type", "").lower()
        if prefer_library and tip and source_tip and tip != source_tip:
            raise ValueError("CSV/HSM tip type mismatch: " + description)
        if not tip:
            tip = source_tip

    def dimension(value, attribute):
        if value:
            explicit = mm(value, unit, attribute)
            if not prefer_library or source is None or attribute not in source:
                return explicit
            precise = mm(source[attribute], source["unit"], attribute)
            # Compare in the CSV unit. A tiny epsilon covers the binary-to-
            # decimal rounding tie seen for M3: 1.553975 -> 1.55397.
            source_in_csv_unit = precise / UNIT_MM[unit]
            last_digit = Decimal(10) ** (source_in_csv_unit.adjusted() - 5)
            allowed = (last_digit / 2 + abs(source_in_csv_unit) * Decimal("1e-12")) * UNIT_MM[unit]
            if abs(explicit - precise) > allowed:
                raise ValueError("CSV/HSM dimension mismatch: " + description + " / " + attribute)
            return precise
        if source is None or attribute not in source:
            raise ValueError("Missing thread-mill dimension: " + attribute)
        return mm(source[attribute], source["unit"], attribute)

    neck_mm = dimension(neck, "shoulder-diameter")
    length_mm = dimension(length, "shoulder-length")
    crest_mm = Decimal(0) if tip == "point" else dimension(width, "thread-tip-width")
    diameter_mm = mm(get("tool_diameter"), unit, "tool_diameter")
    overall_mm = mm(get("tool_overallLength"), unit, "tool_overallLength")
    if not Decimal(0) < neck_mm < diameter_mm:
        raise ValueError("Thread-mill neck must be positive and smaller than cutting diameter")
    if not Decimal(0) < length_mm < overall_mm or crest_mm < 0:
        raise ValueError("Invalid thread-mill neck length or crest")
    return {"NeckDiameter": quantity(neck_mm),
            "NeckLength": quantity(length_mm), "Crest": quantity(crest_mm)}

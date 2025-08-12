/**
  Copyright (C) 2012-2022 by Autodesk, Inc.
  All rights reserved.

  Grbl post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2022-12-05 16:47:31 $

  FORKID {D897E9AA-349A-4011-AA01-06B6CCC181EB}
*/

description = "Makera Carvera Community Post v1.2.0";

vendor = "Makera";
vendorUrl = "https://www.makera.com";
legal = "Copyright (C) 2012-2022 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

extension = "cnc";
setCodePage("ascii");

capabilities =
  CAPABILITY_MILLING | CAPABILITY_JET | CAPABILITY_MACHINE_SIMULATION;
tolerance = spatial(0.002, MM);

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
// The following manual NC commands are supported by this post:
//      Dwell                  -pause for x seconds
//      Stop                   -pause and wait for input from tne user
//      Comment                -write a comment into the file
//      Measure Tool           -run a tool length offset calibration on the current tool
//      Tool Break Control     -run a tool break test. Requires the community firmware
//      Pass Through           -send the contents of the input box directly to the machine

// Useful Pass Through Commands
//      M98.1 "nameOfFile"
//      M98 P2002
//

// The following ACTION commands are supported by this post.
//
//     RapidA:#             -rapids the a axis to degree position
//     SaferA:#             -Moves the z axis up to its clearance position then moves the a axis
//     SafeZ                -Go to a safe z height (same height as the clearance position)
//     SpindleOff           -turns the spindle off
//     Clearance            -goes to carvea clearance position
//     ClearAutoLevel       -clears the auto level data from the machine
//     ResetFeedOverride    -resets the spindle override value to 100%
//     FeedOverride:#       -sets the feed override to a given percent. Useful for vetting new programs as well as speeding up an entire set of operations quickly
//     AirOn                -Turns the compressed air on
//     AirOff               -Turns the compressed air off
//     VacOn                -Turns on the vacuum
//     VacOff               -Turns off the vacuum
//     AutoVacOn            -turns on auto vacuum
//     AutoVacOff           -turns off auto vacuum
//     LightOn              -turns on the light
//     LightOff             -turns off the light
//     ExtOn                -Enables External Control at 100% (M851 S100)
//     ExtOff               -Disables External Control (M852)
//     ShrinkA              -Shrinks the A axis with offset 0, so A365 will turn into A5

//
///////////////////////////////////////////////////////////////////////////////

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);

allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
highFeedrate = unit == MM ? 3000 : 140;

// user-defined properties
properties = {
  writeMachine: {
    title: "Write machine",
    description: "Output the machine settings in the header of the code.",
    group: "formats",
    type: "boolean",
    value: true,
    scope: "post",
  },
  writeTools: {
    title: "Write tool list",
    description: "Output a tool list in the header of the code.",
    group: "formats",
    type: "boolean",
    value: true,
    scope: "post",
  },
  returnClearance: {
    title: "Return Clearance",
    description: "Return to clearance position when the job is finished.",
    group: "homePositions",
    type: "boolean",
    value: true,
    scope: "post",
  },
  showSequenceNumbers: {
    title: "Use sequence numbers",
    description:
      "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
    group: "formats",
    type: "enum",
    values: [
      { title: "Yes", id: "true" },
      { title: "No", id: "false" },
      { title: "Only on tool change", id: "toolChange" },
    ],
    value: "false",
    scope: "post",
  },
  sequenceNumberStart: {
    title: "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group: "formats",
    type: "integer",
    value: 10,
    scope: "post",
  },
  sequenceNumberIncrement: {
    title: "Sequence number increment",
    description:
      "The amount by which the sequence number is incremented by in each block.",
    group: "formats",
    type: "integer",
    value: 1,
    scope: "post",
  },
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group: "formats",
    type: "boolean",
    value: true,
    scope: "post",
  },
  splitFile: {
    title: "Split file",
    description: "Select your desired file splitting option.",
    group: "preferences",
    type: "enum",
    values: [
      { title: "No splitting", id: "none" },
      { title: "Split by tool", id: "tool" },
      { title: "Split by toolpath", id: "toolpath" },
    ],
    value: "none",
    scope: "post",
  },
  splitFileHeader: {
    title: "Write Tool# and Header To Each Split By Toolpath File",
    description: "Write Tool# and Header To Each Split By Toolpath File",
    group: "preferences",
    type: "boolean",
    value: true,
    scope: "post",
  },
  defaultUseExternalControl: {
    title: "Spindle-based External Control",
    description:
      "Turn the external PWM control on/off when the spindle is turned on/off.",
    group: "preferences",
    type: "boolean",
    value: true,
    scope: "post",
  },
  useExtForAirCoolant: {
    title: "Use Ext For Air Coolant",
    description:
      "Turn the external PWM control on/off when the air coolant is turned on/off.",
    group: "preferences",
    type: "boolean",
    value: false,
    scope: "post",
  },
  manualToolChangeBehavior: {
    title: "Manual Tool Change Behavior",
    description:
      "If you are using the Carvera Air, choose the Carvera Air option. If you are using the carvera community firmware, that option will allow you to use tools 0-99. If you are using the stock carvera firmware on the non air variant, choose the fusion manual tool changes to generate tool changes when a tool number is greater than 6, the shank size changes, or the tool is marked for manual tool change. If you want the default behavior for the Carvera where it alarms on any tool number greater than 6, choose the first option",
    group: "preferences",
    type: "enum",
    values: [
      { title: "Error On More Than 6 Tools", id: "error6" },
      { title: "Fusion Manual Tool Changes", id: "fusionMtc" },
      { title: "Carvera Community Tool Changes", id: "carvcomMtc" },
      { title: "Carvera Air Tool Changes", id: "carvAirMtc" },
    ],
    value: "carvAirMtc",

    scope: "post",
  },
  useShankSizeForManualChange: {
    title: "Write Manual Tool Changes when Shank Size Changes",
    description: "",
    group: "preferences",
    type: "boolean",
    value: true,
    scope: "post",
  },
  firmwareType: {
    title: "Carvera Machine Firmware Type",
    description: "Select the firmware type installed on your machine.",
    group: "preferences",
    type: "enum",
    values: [
      { title: "Stock Firmware", id: "stock" },
      { title: "Community Firmware", id: "community" },
    ],
    value: "community",
    scope: "post",
  },
  probeSensorType: {
    title: "Probe Sensor Type",
    description:
      "Set to NO (normally open) or NC (normally closed). If this value does not match the probe sensor it is guaranteed to cause a crash.",
    group: "preferences",
    type: "enum",
    values: [
      { title: "NC (normally closed)", id: "NC" },
      { title: "NO (normally open)", id: "NO" },
    ],
    value: "NO",
    scope: "post",
  },
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  // @TODO: Fusion does not accept decimals, i.e. 59.1-3, which are the temporary WCS values (not stored in the machine and not persisted across reboots/restarts
  wcs: [{ name: "Standard", format: "G", range: [54, 59] }],
};

var numberOfToolSlots = 999999;
var previousToolChangeWasManual = false;
var subprograms = new Array();

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
// {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
var coolants = [
  { id: COOLANT_FLOOD, on: 8 },
  { id: COOLANT_MIST },
  { id: COOLANT_THROUGH_TOOL },
  { id: COOLANT_AIR, on: 7 },
  { id: COOLANT_AIR_THROUGH_TOOL },
  { id: COOLANT_SUCTION },
  { id: COOLANT_FLOOD_MIST },
  { id: COOLANT_FLOOD_THROUGH_TOOL },
  { id: COOLANT_OFF, off: 9 },
];

var gFormat = createFormat({ prefix: "G", decimals: 1 });
var mFormat = createFormat({ prefix: "M", decimals: 0 });

var xyzFormat = createFormat({
  decimals: unit == MM ? 3 : 4,
  type: FORMAT_REAL,
  minDigitsRight: 1,
});
var rFormat = xyzFormat; //radius
var abcFormat = createFormat({ decimals: 3, forceDecimal: true, scale: DEG });
var feedFormat = createFormat({
  decimals: unit == MM ? 1 : 2,
  type: FORMAT_REAL,
  minDigitsRight: 1,
});
var inverseTimeFormat = createFormat({ decimals: 3, forceDecimal: true });
var toolFormat = createFormat({ decimals: 0 });
var toolDiameterFormat = createFormat({
  decimals: unit == MM ? 3 : 4,
});
var rpmFormat = createFormat({ decimals: 0 });
var pwmFormat = createFormat({ decimals: 0, maximum: 100, minimum: 0 });
var secFormat = createFormat({ decimals: 3, forceDecimal: true }); // seconds - range 0.001-1000
var taperFormat = createFormat({ decimals: 1, scale: DEG });
var integerFormat = createFormat({ decimals: 0 });
var angleFormat = createFormat({ decimals: 0, scale: DEG });

var xOutput = createVariable({ prefix: "X" }, xyzFormat);
var yOutput = createVariable({ prefix: "Y" }, xyzFormat);
var zOutput = createVariable(
  {
    onchange: function () {
      retracted = false;
    },
    prefix: "Z",
  },
  xyzFormat
);
var aOutput = createVariable({ prefix: "A" }, abcFormat);
var bOutput = createVariable({ prefix: "B" }, abcFormat);
var cOutput = createVariable({ prefix: "C" }, abcFormat);
var feedOutput = createVariable({ prefix: "F" }, feedFormat);
var inverseTimeOutput = createVariable(
  { prefix: "F", force: true },
  inverseTimeFormat
);
var pwmOutput = createVariable({ prefix: "S", force: true }, pwmFormat);
var sOutput = createVariable({ prefix: "S", force: true }, rpmFormat);

// circular output
var iOutput = createVariable({ prefix: "I" }, xyzFormat);
var jOutput = createVariable({ prefix: "J" }, xyzFormat);
var kOutput = createVariable({ prefix: "K" }, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal(
  {
    onchange: function () {
      gMotionModal.reset();
    },
  },
  gFormat
); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G93-94
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var forceSpindleSpeed = false;
var currentWorkOffset;
// specifies that the tool has been retracted to the safe plane
// NB: writeRetract() is what sets this to true
var retracted = false;

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  if (getProperty("showSequenceNumbers") == "true") {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    writeWords(arguments);
  }
}

function formatComment(text) {
  return "(" + String(text).replace(/[()]/g, "") + ")";
}

/**
  Writes the specified block - used for tool changes only.
*/
function writeToolBlock() {
  var show = getProperty("showSequenceNumbers");
  setProperty(
    "showSequenceNumbers",
    show == "true" || show == "toolChange" ? "true" : "false"
  );
  writeBlock(arguments);
  setProperty("showSequenceNumbers", show);
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

/** AllowCustomCodeToBeWritten -Fae*/
function onPassThrough(text) {
  writeBlock(text);
}

/** Custom Actions -Fae*/
function onParameter(name, value) {
  var invalid = false;
  if (name == "action") {
    if (String(value).toUpperCase() == "SPINDLEOFF") {
      writeBlock("M5 (Spindle Off)");
    } else if (String(value).toUpperCase() == "CLEARANCE") {
      writeBlock("G28 (Go to clearance)");
    } else if (String(value).toUpperCase() == "CLEARAUTOLEVEL") {
      writeBlock("M370 (clear autolevel)");
    } else if (String(value).toUpperCase() == "RESETFEEDOVERRIDE") {
      writeBlock("M220 S100 (Reset Feed Speed override)");
    } else if (String(value).toUpperCase() == "AIRON") {
      writeBlock("M7 (Compressed Air On)");
    } else if (String(value).toUpperCase() == "AIROFF") {
      writeBlock("M9 (Compressed Air Off)");
    } else if (String(value).toUpperCase() == "VACON") {
      writeBlock("M801 S100 (Vacuum On)");
    } else if (String(value).toUpperCase() == "VACOFF") {
      writeBlock("M802 (Vacuum Off)");
    } else if (String(value).toUpperCase() == "AUTOVACON") {
      writeBlock("M331 (Turn On Auto Vacuum)");
    } else if (String(value).toUpperCase() == "AUTOVACOFF") {
      writeBlock("M332 (Turn Off Auto Vacuum)");
    } else if (String(value).toUpperCase() == "LIGHTON") {
      writeBlock("M821 (Turn On Light)");
    } else if (String(value).toUpperCase() == "LIGHTOFF") {
      writeBlock("M822 (Turn Off Light)");
    } else if (String(value).toUpperCase() == "EXTON") {
      writeBlock("M851 S100 (External Control On 100)");
    } else if (String(value).toUpperCase() == "EXTOFF") {
      writeBlock("M852 (External Control Off)");
    } else if (String(value).toUpperCase() == "SHRINKA") {
      writeBlock("G92.4 A0 S0 (shrink the a axis so A365 becomes A5)");
    } else if (String(value).toUpperCase() == "SAFEZ") {
      writeBlock("G53 G0 Z -2. (Goto Safe Height In Z)");
    } else {
      var sText1 = String(value);
      var sText2 = new Array();
      sText2 = sText1.split(":");
      if (sText2.length == 2) {
        if (sText2[0].toUpperCase() == "RAPIDA") {
          if (sText2[1].match(/^-?\d+$/)) {
            writeBlock("G0A" + sText2[1] + "(Rapid movement on a axis)");
          } else {
            invalid = true;
          }
        } else if (sText2[0].toUpperCase() == "SAFERA") {
          if (sText2[1].match(/^-?\d+$/)) {
            writeBlock("G53 G0 Z -2. (Goto Safe Height In Z)");
            writeBlock("G0A" + sText2[1] + "(Rapid movement on a axis)");
          } else {
            invalid = true;
          }
        } else if (sText2[0].toUpperCase() == "FEEDOVERRIDE") {
          if (sText2[1].match(/^-?\d+$/)) {
            writeBlock(
              "M220 S" +
                sText2[1] +
                "(Globally sets the feed speed to " +
                sText2[1] +
                " percent. Useful for vetting a program the first time you run it. Remember to run M220 S100 when you are done with the program or restart the machine)"
            );
          } else {
            invalid = true;
          }
        }
      } else {
        invalid = true;
      }
    }
    if (invalid) {
      error(
        localize("Invalid action parameter: ") + sText2[0] + ":" + sText2[1]
      );
      return;
    }
  }
}

// Start of machine configuration logic
var compensateToolLength = false; // add the tool length to the pivot distance for nonTCP rotary heads

// internal variables, do not change
var receivedMachineConfiguration;
var operationSupportsTCP;
var multiAxisFeedrate;

function activateMachine() {
  // disable unsupported rotary axes output
  if (
    !machineConfiguration.isMachineCoordinate(0) &&
    typeof aOutput != "undefined"
  ) {
    aOutput.disable();
  }
  if (
    !machineConfiguration.isMachineCoordinate(1) &&
    typeof bOutput != "undefined"
  ) {
    bOutput.disable();
  }
  if (
    !machineConfiguration.isMachineCoordinate(2) &&
    typeof cOutput != "undefined"
  ) {
    cOutput.disable();
  }

  // setup usage of multiAxisFeatures
  useMultiAxisFeatures =
    getProperty("useMultiAxisFeatures") != undefined
      ? getProperty("useMultiAxisFeatures")
      : typeof useMultiAxisFeatures != "undefined"
      ? useMultiAxisFeatures
      : false;
  useABCPrepositioning =
    getProperty("useABCPrepositioning") != undefined
      ? getProperty("useABCPrepositioning")
      : typeof useABCPrepositioning != "undefined"
      ? useABCPrepositioning
      : false;

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // don't need to modify any settings for 3-axis machines
  }

  // save multi-axis feedrate settings from machine configuration
  var mode = machineConfiguration.getMultiAxisFeedrateMode();
  var type =
    mode == FEED_INVERSE_TIME
      ? machineConfiguration.getMultiAxisFeedrateInverseTimeUnits()
      : mode == FEED_DPM
      ? machineConfiguration.getMultiAxisFeedrateDPMType()
      : DPM_STANDARD;
  multiAxisFeedrate = {
    mode: mode,
    maximum: machineConfiguration.getMultiAxisFeedrateMaximum(),
    type: type,
    tolerance:
      mode == FEED_DPM
        ? machineConfiguration.getMultiAxisFeedrateOutputTolerance()
        : 0,
    bpwRatio:
      mode == FEED_DPM
        ? machineConfiguration.getMultiAxisFeedrateBpwRatio()
        : 1,
  };

  // setup of retract/reconfigure  TAG: Only needed until post kernel supports these machine config settings
  if (receivedMachineConfiguration && machineConfiguration.performRewinds()) {
    safeRetractDistance = machineConfiguration.getSafeRetractDistance();
    safePlungeFeed = machineConfiguration.getSafePlungeFeedrate();
    safeRetractFeed = machineConfiguration.getSafeRetractFeedrate();
  }
  if (
    typeof safeRetractDistance == "number" &&
    getProperty("safeRetractDistance") != undefined &&
    getProperty("safeRetractDistance") != 0
  ) {
    safeRetractDistance = getProperty("safeRetractDistance");
  }

  if (machineConfiguration.isHeadConfiguration()) {
    compensateToolLength =
      typeof compensateToolLength == "undefined" ? false : compensateToolLength;
  }

  if (machineConfiguration.isHeadConfiguration() && compensateToolLength) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var section = getSection(i);
      if (section.isMultiAxis()) {
        machineConfiguration.setToolLength(getBodyLength(section.getTool())); // define the tool length for head adjustments
        section.optimizeMachineAnglesByMachine(
          machineConfiguration,
          OPTIMIZE_AXIS
        );
      }
    }
  } else {
    optimizeMachineAngles2(OPTIMIZE_AXIS);
  }
}

function getBodyLength(tool) {
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (tool.number == section.getTool().number) {
      return section.getParameter(
        "operation:tool_overallLength",
        tool.bodyLength + tool.holderLength
      );
    }
  }
  return tool.bodyLength + tool.holderLength;
}

function dumpToolInformation() {
  // dump tool information
  writeln(""); // empty line
  writeComment("Tool Information:");
  var zRanges = {};
  if (is3D()) {
    var numberOfSections = getNumberOfSections();
    for (var i = 0; i < numberOfSections; ++i) {
      var section = getSection(i);
      var zRange = section.getGlobalZRange();
      var tool = section.getTool();
      if (zRanges[tool.number]) {
        zRanges[tool.number].expandToRange(zRange);
      } else {
        zRanges[tool.number] = zRange;
      }
    }
  }

  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      var comment =
        "T" +
        toolFormat.format(tool.number) +
        "  " +
        tool.description +
        "  " +
        tool.vendor +
        "  " +
        tool.productId +
        "  " +
        "D=" +
        xyzFormat.format(tool.diameter) +
        " " +
        localize("CR") +
        "=" +
        xyzFormat.format(tool.cornerRadius);
      if (tool.taperAngle > 0 && tool.taperAngle < Math.PI) {
        comment +=
          " " +
          localize("TAPER") +
          "=" +
          taperFormat.format(tool.taperAngle) +
          localize("deg");
      }
      if (zRanges[tool.number]) {
        comment +=
          " - " +
          localize("ZMIN") +
          "=" +
          xyzFormat.format(zRanges[tool.number].getMinimum());
      }
      comment += " - " + getToolTypeName(tool.type);
      writeComment(comment);
    }
  }
  writeln(""); // empty line
}

function defineMachine() {
  if (false) {
    // note: setup your machine here
    var aAxis = createAxis({
      coordinate: 0,
      table: true,
      axis: [1, 0, 0],
      cyclic: true,
      tcp: false,
    });
    machineConfiguration = new MachineConfiguration(aAxis);

    setMachineConfiguration(machineConfiguration);
    if (receivedMachineConfiguration) {
      warning(
        localize(
          "The provided CAM machine configuration is overwritten by the postprocessor."
        )
      );
      receivedMachineConfiguration = false; // CAM provided machine configuration is overwritten
    }
  }

  if (!receivedMachineConfiguration) {
    // multiaxis settings
    if (machineConfiguration.isHeadConfiguration()) {
      machineConfiguration.setVirtualTooltip(false); // translate the pivot point to the virtual tool tip for nonTCP rotary heads
    }

    // retract / reconfigure
    var performRewinds = false; // set to true to enable the rewind/reconfigure logic
    if (performRewinds) {
      machineConfiguration.enableMachineRewinds(); // enables the retract/reconfigure logic
      safeRetractDistance = unit == IN ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
      safeRetractFeed = unit == IN ? 20 : 500; // retract feed rate
      safePlungeFeed = unit == IN ? 10 : 250; // plunge feed rate
      machineConfiguration.setSafeRetractDistance(safeRetractDistance);
      machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
      machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
      var stockExpansion = new Vector(
        toPreciseUnit(0.1, IN),
        toPreciseUnit(0.1, IN),
        toPreciseUnit(0.1, IN)
      ); // expand stock XYZ values
      machineConfiguration.setRewindStockExpansion(stockExpansion);
    }

    // multi-axis feedrates
    if (machineConfiguration.isMultiAxisConfiguration()) {
      machineConfiguration.setMultiAxisFeedrate(
        FEED_DPM, // FEED_INVERSE_TIME or FEED_DPM,
        99999.999, // maximum output value for inverse time feed rates
        DPM_COMBINATION, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
        0.5, // tolerance to determine when the DPM feed has changed
        unit == MM ? 1.0 : 0.1 // ratio of rotary accuracy to linear accuracy for DPM calculations
      );
      setMachineConfiguration(machineConfiguration);
    }

    /* home positions */
    // machineConfiguration.setHomePositionX(toPreciseUnit(0, IN));
    // machineConfiguration.setHomePositionY(toPreciseUnit(0, IN));
    // machineConfiguration.setRetractPlane(toPreciseUnit(0, IN));
  }
}
// End of machine configuration logic

function onOpen() {
  // define and enable machine configuration
  receivedMachineConfiguration = machineConfiguration.isReceived();

  if (typeof defineMachine == "function") {
    defineMachine(); // hardcoded machine configuration
  }
  activateMachine(); // enable the machine optimizations and settings

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  if (programName) {
    writeComment("Program Name: " + programName);
  }
  if (programComment) {
    writeComment("Program Comment: " + programComment);
  }

  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var description = machineConfiguration.getDescription();

  if (getProperty("writeMachine") && (vendor || model || description)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (description) {
      writeComment("  " + localize("description") + ": " + description);
    }
  }

  // dump tool information
  if (getProperty("writeTools")) {
    dumpToolInformation();
  }

  if (getNumberOfSections() > 0 && getSection(0).workOffset == 0) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(
          localize(
            "Using multiple work offsets is not possible if the initial work offset is 0."
          )
        );
        return;
      }
    }
  }

  if (getProperty("splitFile") != "none") {
    writeComment(localize("***THIS FILE DOES NOT CONTAIN NC CODE***"));
    return;
  }

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94));
  writeBlock(gPlaneModal.format(17));

  switch (unit) {
    case IN:
      writeBlock(gUnitModal.format(20));
      break;
    case MM:
      writeBlock(gUnitModal.format(21));
      break;
  }
}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  feedOutput.reset();
}

function isProbeOperation() {
  return (
    hasParameter("operation-strategy") &&
    getParameter("operation-strategy") == "probe"
  );
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function defineWorkPlane(_section, _setWorkPlane) {
  var abc = new Vector(0, 0, 0);
  if (machineConfiguration.isMultiAxisConfiguration()) {
    // use 5-axis indexing for multi-axis mode
    abc = _section.isMultiAxis()
      ? _section.getInitialToolAxisABC()
      : getWorkPlaneMachineABC(_section.workPlane);
    if (_section.isMultiAxis()) {
      cancelTransformation();
      if (_setWorkPlane) {
        forceWorkPlane();
        positionABC(abc, true);
      }
    } else {
      abc = getWorkPlaneMachineABC(_section.workPlane);
      if (_setWorkPlane) {
        setWorkPlane(abc);
      }
    }
  } else {
    // pure 3D
    var remaining = _section.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return abc;
    }
    setRotation(remaining);
  }
  if (currentSection && currentSection.getId() == _section.getId()) {
    operationSupportsTCP =
      currentSection.getOptimizedTCPMode() == OPTIMIZE_NONE;
    if (
      !currentSection.isMultiAxis() &&
      (useMultiAxisFeatures ||
        isSameDirection(
          machineConfiguration.getSpindleAxis(),
          currentSection.workPlane.forward
        ))
    ) {
      operationSupportsTCP = false;
    }
  }
  return abc;
}

function setWorkPlane(abc) {
  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (
    !(
      currentWorkPlaneABC == undefined ||
      abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
      abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
      abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z)
    )
  ) {
    return; // no change
  }

  positionABC(abc, true);
  if (!currentSection.isMultiAxis()) {
    onCommand(COMMAND_LOCK_MULTI_AXIS);
  }
  currentWorkPlaneABC = abc;
}

function positionABC(abc, force) {
  if (typeof unwindABC == "function") {
    unwindABC(abc);
  }
  if (force) {
    forceABC();
  }
  var a = aOutput.format(abc.x);
  var b = bOutput.format(abc.y);
  var c = cOutput.format(abc.z);
  if (a || b || c) {
    if (!retracted) {
      if (typeof moveToSafeRetractPosition == "function") {
        moveToSafeRetractPosition();
      } else {
        writeRetract(Z);
      }
    }
    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
    gMotionModal.reset();
    writeBlock(gMotionModal.format(0), a, b, c);
    setCurrentABC(abc); // required for machine simulation
  }
}

function getWorkPlaneMachineABC(workPlane) {
  var W = workPlane; // map to global frame

  var currentABC = isFirstSection()
    ? new Vector(0, 0, 0)
    : getCurrentDirection();
  var abc = machineConfiguration.getABCByPreference(
    W,
    currentABC,
    ABC,
    PREFER_PREFERENCE,
    ENABLE_ALL
  );

  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
    return new Vector();
  }

  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") +
        ":" +
        conditional(
          machineConfiguration.isMachineCoordinate(0),
          " A" + abcFormat.format(abc.x)
        ) +
        conditional(
          machineConfiguration.isMachineCoordinate(1),
          " B" + abcFormat.format(abc.y)
        ) +
        conditional(
          machineConfiguration.isMachineCoordinate(2),
          " C" + abcFormat.format(abc.z)
        )
    );
  }

  var tcp = false;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }

  return abc;
}

// Parse the TLO value from a comment
function parseTLO(comment) {
  if (!comment) {
    return null; // Return null if no comment exists
  }

  // Match the pattern TLO:X, where X is a letter or a number
  var match = comment.match(/TLO:([AMam0-9.-]+)/);
  if (match) {
    return match[1];
  }
  return null;
}

function onSection() {
  var insertToolCall =
    isFirstSection() ||
    (currentSection.getForceToolChange &&
      currentSection.getForceToolChange()) ||
    tool.number != getPreviousSection().getTool().number ||
    (getProperty("splitFile") == "toolpath" && getProperty("splitFileHeader"));

  var splitHere =
    getProperty("splitFile") == "toolpath" ||
    (getProperty("splitFile") == "tool" && insertToolCall);

  retracted = false; // specifies that the tool has been retracted to the safe plane
  var newWorkOffset =
    isFirstSection() ||
    getPreviousSection().workOffset != currentSection.workOffset ||
    splitHere; // work offset changes
  var newWorkPlane =
    isFirstSection() ||
    !isSameDirection(
      getPreviousSection().getGlobalFinalToolAxis(),
      currentSection.getGlobalInitialToolAxis()
    ) ||
    (currentSection.isOptimizedForMachine() &&
      getPreviousSection().isOptimizedForMachine() &&
      Vector.diff(
        getPreviousSection().getFinalToolAxisABC(),
        currentSection.getInitialToolAxisABC()
      ).length > 1e-4) ||
    (!machineConfiguration.isMultiAxisConfiguration() &&
      currentSection.isMultiAxis()) ||
    (!getPreviousSection().isMultiAxis() && currentSection.isMultiAxis()) ||
    (getPreviousSection().isMultiAxis() && !currentSection.isMultiAxis()) ||
    splitHere; // force newWorkPlane between indexing and simultaneous operations
  if (insertToolCall || newWorkOffset || newWorkPlane) {
    // stop spindle before retract during tool change
    if (insertToolCall && !isFirstSection()) {
      onCommand(COMMAND_STOP_SPINDLE);
    }
    if (getProperty("splitFile") == "none" || isRedirecting()) {
      writeRetract(Z);
    }
  }

  writeln("");

  if (splitHere) {
    if (!isFirstSection()) {
      setCoolant(COOLANT_OFF);

      onImpliedCommand(COMMAND_END);
      onCommand(COMMAND_STOP_SPINDLE);
      writeRetract(X, Y, Z);

      writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
      if (isRedirecting()) {
        closeRedirection();
      }
    }

    var subprogram;
    if (getProperty("splitFile") == "toolpath") {
      var comment;
      if (hasParameter("operation-comment")) {
        comment = getParameter("operation-comment");
      } else {
        comment = getCurrentSectionId();
      }
      subprogram =
        programName +
        "_" +
        (subprograms.length + 1) +
        "_" +
        comment +
        "_" +
        "T" +
        tool.number;
    } else {
      subprogram =
        programName + "_" + (subprograms.length + 1) + "_" + "T" + tool.number;
    }

    subprograms.push(subprogram);

    var path = FileSystem.getCombinedPath(
      FileSystem.getFolderPath(getOutputPath()),
      String(subprogram).replace(/[<>:"/\\|?*]/g, "") + "." + extension
    );

    writeComment(
      localize(
        "Load tool number " + tool.number + " and subprogram " + subprogram
      )
    );

    redirectToFile(path);

    if (programName) {
      writeComment(programName);
    }
    if (programComment) {
      writeComment(programComment);
    }
    // Absolute coordinates and feed per min
    writeBlock("G90 G94 G17");

    switch (unit) {
      case IN:
        writeBlock("G20");
        break;
      case MM:
        writeBlock("G21");
        break;
    }
  }

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment("Start of operation: " + comment);
    }
  }

  if (insertToolCall) {
    if (
      getProperty("splitFile") == "toolpath" &&
      getProperty("splitFileHeader")
    ) {
      dumpToolInformation();
    }

    setCoolant(COOLANT_OFF);

    if (tool.number > numberOfToolSlots) {
      warning(localize("Tool number exceeds maximum value."));
    }

    var tloValue = parseTLO(tool.comment); //A is automatic and is the default, M is manual setting (C=0), a number set the value directly (H=-14)

    var e_manualToolChangeBehavior = getProperty("manualToolChangeBehavior");

    if (tool.number > 6 && e_manualToolChangeBehavior == "error6") {
      error(
        localize(
          "Carvera does not support tool numbers greater than 6 by default. Use one of the manual tool change post processor settings"
        )
      );
    }

    if (e_manualToolChangeBehavior == "carvAirMtc") {
      //any tool number accepted
      writeToolBlock(mFormat.format(6), "T" + toolFormat.format(tool.number));

      if (tool.comment) {
        writeComment(tool.comment);
      }
    } else if (e_manualToolChangeBehavior == "carvcomMtc") {
      if (tloValue) {
        if (tloValue === "A") {
          writeToolBlock(
            mFormat.format(6),
            "T" + toolFormat.format(tool.number) + " C1"
          );
        } else if (tloValue === "M") {
          writeToolBlock(
            mFormat.format(6),
            "T" + toolFormat.format(tool.number) + " C0"
          );
        } else {
          var tloFloat = parseFloat(tloValue);
          if (!isNaN(tloFloat)) {
            writeToolBlock(
              mFormat.format(6),
              "T" + toolFormat.format(tool.number) + " H" + tloFloat
            );
          } else {
            writeToolBlock(
              mFormat.format(6),
              "T" + toolFormat.format(tool.number)
            );
          }
        }
      } else {
        writeToolBlock(mFormat.format(6), "T" + toolFormat.format(tool.number));
      }
    } else if (tool.number > 6 || tool.manualToolChange) {
      writeComment("Manual Tool Change To #" + toolFormat.format(tool.number));
      if (tool.manualToolChange) {
        writeComment(
          "as a result of manual tool change selected in tool settings"
        );
      }
      performStockManualToolChange(tloValue);
    } else if (
      !isFirstSection() &&
      getProperty("useShankSizeForManualChange") &&
      Math.abs(
        tool.shaftDiameter - getPreviousSection().getTool().shaftDiameter
      ) > 0.001
    ) {
      writeComment("Manual Tool Change To #" + toolFormat.format(tool.number));
      writeComment("as a result of tool shank size change");
      performStockManualToolChange(tloValue);
    } else {
      if (
        previousToolChangeWasManual &&
        e_manualToolChangeBehavior == "fusionMtc"
      ) {
        writeComment(
          "Manual Tool Removal as a result of previous manual tool change"
        );
        writeComment("setup for tool change");
        writeBlock("G28");
        writeComment(
          "Paused. Prepare to remove tool from collet. Pressing play will release collet"
        );
        writeBlock(mFormat.format(27));
        writeBlock(mFormat.format(600));
        writeBlock("M490.2");
        writeComment(
          "Paused. Pressing play will resume program. The program expects an empty collet after this point."
        );
        writeBlock(mFormat.format(27));
        writeBlock(mFormat.format(600));
        writeBlock("M493.2 T-1");
      }
      writeToolBlock(mFormat.format(6), "T" + toolFormat.format(tool.number));

      if (tool.comment) {
        writeComment(tool.comment);
      }
      previousToolChangeWasManual = false;
      var showToolZMin = false;
      if (showToolZMin) {
        if (is3D()) {
          var numberOfSections = getNumberOfSections();
          var zRange = currentSection.getGlobalZRange();
          var number = tool.number;
          for (var i = currentSection.getId() + 1; i < numberOfSections; ++i) {
            var section = getSection(i);
            if (section.getTool().number != number) {
              break;
            }
            zRange.expandToRange(section.getGlobalZRange());
          }
          writeComment(localize("ZMIN") + "=" + zRange.getMinimum());
        }
      }
    }
  }

  var spindleChanged =
    tool.type != TOOL_PROBE &&
    (insertToolCall ||
      forceSpindleSpeed ||
      isFirstSection() ||
      rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent()) ||
      tool.clockwise != getPreviousSection().getTool().clockwise);
  if (spindleChanged) {
    forceSpindleSpeed = false;
    if (spindleSpeed < 1) {
      error(localize("Spindle speed out of range."));
    }
    if (spindleSpeed > 99999) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
    if (getProperty("defaultUseExternalControl")) {
      writeBlock(mFormat.format(851), pwmOutput.format(100));
    }
    writeBlock(
      sOutput.format(spindleSpeed),
      mFormat.format(tool.clockwise ? 3 : 4)
    );
  }

  // wcs
  if (insertToolCall) {
    // force work offset when changing tool
    currentWorkOffset = undefined;
  }

  if (currentSection.workOffset != currentWorkOffset) {
    writeBlock(currentSection.wcs);
    currentWorkOffset = currentSection.workOffset;
  }

  var abc = defineWorkPlane(currentSection, true);

  forceXYZ();

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  forceXYZ();

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }
  }

  if (insertToolCall || retracted) {
    var lengthOffset = tool.lengthOffset;
    if (lengthOffset > numberOfToolSlots) {
      error(localize("Length offset out of range."));
      return;
    }

    gMotionModal.reset();
    writeBlock(gPlaneModal.format(17));

    if (!machineConfiguration.isHeadConfiguration()) {
      if (!isFirstOperationProbeZ()) {
        writeBlock(
          gAbsIncModal.format(90),
          gMotionModal.format(0),
          xOutput.format(initialPosition.x),
          yOutput.format(initialPosition.y)
        );
        writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
      }
    } else {
      writeBlock(
        gAbsIncModal.format(90),
        gMotionModal.format(0),
        xOutput.format(initialPosition.x),
        yOutput.format(initialPosition.y),
        zOutput.format(initialPosition.z)
      );
    }
  } else {
    writeBlock(
      gAbsIncModal.format(90),
      gMotionModal.format(0),
      xOutput.format(initialPosition.x),
      yOutput.format(initialPosition.y)
    );
  }
}

function performStockManualToolChange(tloValue) {
  if (tool.comment) {
    writeComment(tool.comment);
  }

  writeComment("Setup for tool change");
  if (previousToolChangeWasManual || isFirstSection()) {
    writeBlock("G28");
    writeComment(
      "Paused. Prepare to remove tool from collet. Pressing play will release collet"
    );
    writeBlock(mFormat.format(27));
    writeBlock(mFormat.format(600));
    writeBlock("M490.2 (Open Collet)");
  } else {
    writeBlock("T-1 M6");
    writeBlock("G28");
  }

  previousToolChangeWasManual = true;

  writeComment(
    "Paused. Prepare to add new tool to collet. Pressing play will close collet"
  );
  writeBlock(mFormat.format(27));
  writeBlock(mFormat.format(600));
  writeBlock("M490.1 (Close Collet)");

  var tloFloat = parseFloat(tloValue);

  if (tloValue == "M" || !isNaN(tloFloat)) {
    writeComment(
      "Paused. Use the manual control interface to set the tool length."
    );
    writeComment(
      "Pressing play will goto the clearance position, then continue the program."
    );
    writeBlock(mFormat.format(27));
    writeBlock(mFormat.format(600));
    writeBlock("G28 (Move To Clearance)");
  } else {
    writeComment(
      "Paused. Pressing play will calibrate the tool length and continue the program"
    );
    writeBlock(mFormat.format(27));
    writeBlock(mFormat.format(600));
    writeBlock("M493.2T1 (Set tool number to 1 so TLO can be set)");
    writeBlock("M491 (Calibrate Tool Length)");
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(
    gFormat.format(4),
    "P" +
      secFormat.format(seconds) +
      "(pause for " +
      secFormat.format(seconds) +
      "seconds)"
  );
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
}

function calculateWCS(offset) {
  return wcsDefinitions.wcs[0].range[0] + offset - 1;
}

// ====================================================== //
// ================ BEGIN CYCLE HANDLERS ================ //
// ====================================================== //

// baseCycleHandler defines all known cycle types and establishes default
// handlers. If new probe or cycle types appear, they should be added here. To
// add implementations, extend makeraFirmwareCycleHandler or
// communityFirmwareCycleHandler, or roll a new one.
//
// several pre-calculated fields are set up on handler, please refer to them in
// your implementations.
function baseCycleHandler(cycle, tool) {
  var handler = {
    probeRadius: tool.diameter / 2,
    // Set in the UI as "Measure Feedrate" on the Tool tab.
    // Note from Fusion docs: "If the probe is set up to perform two touches,
    // the first touch is at the Lead-In Feedrate and the second touch is at
    // the Measure Feedrate."
    measureFeed: currentSection.getParameter("operation:tool_feedProbeMeasure"),
    // Set in the UI as "Link Feedrate", on the Tool tab.
    linkFeed: currentSection.getParameter("operation:tool_feedProbeLink"),
    // Set in the UI as "Lead-In Feedrate", on the Tool tab.
    entryFeed: currentSection.getParameter("operation:tool_feedEntry"),
    // Shown in the UI as "WCS to be updated". This cannot be set directly in
    // the operation dialog under the Actions tab, it is derived from the
    // WCS of the setup that the operation is part of.
    drivingWcs: currentSection.workOffset,
    // Set in the UI as "WCS" on the Actions tab.
    // This is the WCS that will be updated with the probe results.
    // "Override Driving WCS" checkbox in the Actions tab must be checked
    // for this option to be set and to have any effect.
    targetWcs: currentSection.probeWorkOffset,
    // Set in the UI by checking the "Override Driving WCS" checkbox in the Actions tab.
    updateDrivingWCS: getParameter("operation:probe_overrideWorkOffset"),
    approach1: cycle.approach1 == "positive" ? 1 : -1,
    approach2: cycle.approach2 == "positive" ? 1 : -1,
    // The type of sensor in use, normally open (NO), or normally closed (NC).
    // This is configured in the post processor parameters.
    probeSensorType: getProperty("probeSensorType"),
  };

  // probeMove constructs functions that move the probe at a specified rate in
  // absolute mode. Coordinates are given as maps of the form {x:n, y:n, z:n}.
  // Giving two or more coordinates will execute multiple separate moves.
  // protected = true uses G moves based on sensor type, which will stop in the
  // event of a collision.
  const probeMove = (motion, feed, absolute = true) => {
    return (...axes) => {
      for (const { x, y, z } of axes) {
        const args = [
          motion.startsWith("G38.")
            ? null
            : gAbsIncModal.format(absolute ? 90 : 91),
          motion,
        ].filter(Boolean);

        forceXYZ();
        x && args.push(xOutput.format(x));
        y && args.push(yOutput.format(y));
        z && args.push(zOutput.format(z));

        feedOutput.reset();
        if (feed) args.push(feedOutput.format(feed));

        writeBlock.apply(null, args);
      }
    };
  };

  // Absolute moves
  handler.absoluteRapidMove = probeMove(gFormat.format(0), null, true);
  handler.absoluteMove = probeMove(gFormat.format(1), handler.entryFeed, true);

  // Relative moves without probing.
  handler.relativeMove = probeMove(gFormat.format(1), handler.entryFeed, false);
  handler.safeRelativeMove = probeMove(
    gFormat.format(handler.probeSensorType == "NC" ? 38.5 : 38.3),
    handler.entryFeed,
    false
  );

  // Relative moves with probing.
  handler.measureMoveFast = probeMove(
    gFormat.format(handler.probeSensorType == "NC" ? 38.4 : 38.2),
    handler.measureFeed * 2,
    false
  );
  handler.measureMoveSlow = probeMove(
    gFormat.format(handler.probeSensorType == "NC" ? 38.4 : 38.2),
    handler.measureFeed,
    false
  );

  // updateWCS updates the WCS for this probe using the axis and WCS offset provided,
  // but only if updateDrivingWCS is true.
  handler.updateWCS = (axis, offset) => {
    if (!handler.updateDrivingWCS) return;

    writeBlock(
      gFormat.format(10),
      `L20 P${handler.targetWcs}`,
      axis.format(offset)
    );
  };

  handler.extractAxisAndDistance = (options) => {
    const axis = ["x", "y", "z"].find(
      (axis) =>
        Object.keys(options).includes(axis) && options[axis] !== undefined
    );

    if (!axis) {
      error(localize("Error determining axis for probing operation."));
      return null;
    }

    const distance = options[axis];
    if (!distance || isNaN(distance)) {
      error(localize("Invalid distance for probing operation."));
      return null;
    }

    return { axis, distance };
  };

  // touchProbe measures on the provided axis in the direction indicated by the sign of the value.
  // It double-taps and leaves the probe touching the material after the second touch.
  handler.touchProbe = (options) => {
    const { axis, distance } = handler.extractAxisAndDistance(options);

    handler.measureMoveFast({ [axis]: distance });
    handler.relativeMove({ [axis]: -Math.sign(distance) * tool.diameter });
    handler.measureMoveSlow({
      [axis]: Math.sign(distance) * tool.diameter * 2,
    });
  };

  // touchUpdateRetract probes using the handler.touchProbe function,
  // then updates either the WCS or the provided variable,
  // and finally retracts the probe away from the surface
  // by the specified retract distance.
  // If a retract distance is not specified, it defaults to the approach
  // distance for the cycle.
  handler.touchUpdateRetract = (options) => {
    handler.touchProbe(options);

    const currentWCSPositions = {
      x: "#5041",
      y: "#5042",
      z: "#5043",
    };

    const { axis, distance } = handler.extractAxisAndDistance(options);

    if (Object.keys(options).includes("variable")) {
      // If a variable is provided, update it with the probe result.
      const variable = options.variable.replace("#", "");
      const sign = distance < 0 ? "-" : "+";
      writeBlock(
        `#${variable} = [${currentWCSPositions[axis]} ${sign} ${handler.probeRadius}]`
      );
    } else {
      // Otherwise, update the WCS for the current axis.
      const output = [xOutput, yOutput, zOutput].find((o) =>
        o.format(0).startsWith(axis.toUpperCase())
      );

      handler.updateWCS(output, -Math.sign(distance) * handler.probeRadius);
    }

    // Retract away from the surface.
    const retractDistance =
      options.retractDistance ||
      options.approachDistance ||
      cycle.probeClearance ||
      tool.diameter ||
      2;

    handler.relativeMove({
      [axis]: -Math.sign(distance) * retractDistance,
    });
  };

  var probingCycleTypes = [
    "probing-x",
    "probing-y",
    "probing-z",
    "probing-x-wall",
    "probing-y-wall",
    "probing-x-channel",
    "probing-y-channel",
    "probing-x-channel-with-island",
    "probing-y-channel-with-island",
    "probing-xy-circular-boss",
    "probing-xy-circular-partial-boss",
    "probing-xy-circular-hole",
    "probing-xy-circular-partial-hole",
    "probing-xy-circular-hole-with-island",
    "probing-xy-circular-partial-hole-with-island",
    "probing-xy-rectangular-boss",
    "probing-xy-rectangular-hole",
    "probing-xy-rectangular-hole-with-island",
    "probing-xy-inner-corner",
    "probing-xy-outer-corner",
    "probing-x-plane-angle",
    "probing-y-plane-angle",
  ];

  // If a probe cycle is not implemented and falls back to the baseCycleHandler,
  // we throw an error.
  probingCycleTypes.forEach(function (v) {
    handler[v] = (x, y, z) => {
      error(localize(`Probing cycle '${v}' is not supported by Carvera.`));
    };
  });

  var drillingCycleTypes = [
    "drilling",
    "counter-boring",
    "chip-breaking",
    "deep-drilling",
    "break-through-drilling",
    "gun-drilling",
    "tapping",
    "left-tapping",
    "right-tapping",
    "tapping-with-chip-breakinreaming",
    "boring",
    "stop-boring",
    "fine-boring",
    "back-boring",
    "circular-pocket-milling",
    "thread-milling",
  ];

  // For drilling cycles we just call expandCyclePoint
  drillingCycleTypes.forEach(function (v) {
    handler[v] = function (x, y, z) {
      expandCyclePoint(x, y, z);
    };
  });

  return handler;
}

// makeraFirmwareCycleHandler sets up handlers for the probe cycle types supported by the stock firmware.
// These are limited to basic operations that set a WCS coincident to a face.
function makeraFirmwareCycleHandler(cycle, tool) {
  const handler = baseCycleHandler(cycle, tool);

  const handlers = {
    "probing-x": (x, y, z) => {
      const probeDatum = x + handler.approach1 * cycle.probeClearance;
      handler.safeRelativeMove({ z: -cycle.depth });
      handler.touchProbe({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });
      handler.updateWCS(xOutput, probeDatum);
      handler.absoluteMove({ x: x });
    },
    "probing-y": (x, y, z) => {
      const probeDatum = y + handler.approach1 * cycle.probeClearance;
      handler.safeRelativeMove({ z: -cycle.depth });
      handler.touchProbe({
        y: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });
      handler.updateWCS(yOutput, probeDatum);
      handler.absoluteMove({ y: y });
    },
    "probing-z": (x, y, z) => {
      const probeDatum = z - cycle.depth;
      // Prove all the way down
      handler.touchProbe({ z: -120 });
      handler.updateWCS(zOutput, probeDatum);
    },
    "probing-xy-outer-corner": (x, y, z) => {
      const offset = cycle.probeClearance;
      const probeDatumX = x + handler.approach1 * offset;
      const probeDatumY = y + handler.approach2 * offset;

      // Move to start depth
      handler.safeRelativeMove({ z: -cycle.depth });

      // Probing X: move up in Y, probe in X, return to X, return to Y
      writeComment(`probing x surface`);
      handler.safeRelativeMove({ y: handler.approach2 * offset * 2 });
      handler.touchProbe({
        x: handler.approach1 * (offset + cycle.probeOvertravel),
      });
      handler.updateWCS(xOutput, probeDatumX);
      handler.absoluteMove({ x: x }, { y: y });

      // Probing Y: move up in X, probe in Y, return to Y, return to X
      writeComment(`probing y surface`);
      handler.safeRelativeMove({ x: handler.approach1 * offset * 2 });
      handler.touchProbe({
        y: handler.approach2 * (offset + cycle.probeOvertravel),
      });
      handler.updateWCS(yOutput, probeDatumY);
      handler.absoluteMove({ y: y }, { x: x });
    },
    "probing-xy-inner-corner": (x, y, z) => {
      const offset = cycle.probeClearance;
      const probeDatumX = x + handler.approach1 * offset;
      const probeDatumY = y + handler.approach2 * offset;

      // Move to start depth
      handler.safeRelativeMove({ z: -cycle.depth });

      writeComment(`probing x surface`);
      handler.touchProbe({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });
      handler.updateWCS(xOutput, probeDatumX);
      handler.absoluteMove({ x: x });

      writeComment(`probing y surface`);
      handler.touchProbe({
        y: handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel),
      });
      handler.updateWCS(yOutput, probeDatumY);
      handler.absoluteMove({ y: y });
    },
  };

  return { ...handler, ...handlers };
}

// communityFirmwareCycleHandler sets up handlers for the probe cycle types
// supported by the community firmware.
function communityFirmwareCycleHandler(cycle, tool) {
  const handler = baseCycleHandler(cycle, tool);

  const widthProbe = (options) => {
    writeComment(`Width probe with double tap - ${options.direction}`);

    function probeAxis(axis) {
      if (!options[axis]) return;

      const value = options[axis];
      const probeApproach =
        options.direction.toLowerCase() === "inward"
          ? -handler.approach1
          : handler.approach1;

      // Move to the first side
      handler.safeRelativeMove({
        [axis]:
          handler.approach1 *
          (value / 2 + probeApproach * options.approachDistance),
      });

      // Move down to probe depth
      handler.safeRelativeMove({ z: -options.depth });

      // Probe the first side and store the result in #101.
      handler.touchUpdateRetract({
        [axis]: probeApproach * (options.approachDistance + options.overtravel),
        variable: "#101",
      });

      // Retract up to the clearance height.
      handler.relativeMove({ z: options.depth });

      // Move across to the other side
      handler.safeRelativeMove({
        [axis]:
          2 *
          ((-handler.approach1 * value) / 2 +
            probeApproach * options.approachDistance),
      });

      // Move down to the probing height again
      handler.safeRelativeMove({ z: -options.depth });

      // Probe the second side and store the result in #102.
      handler.touchUpdateRetract({
        [axis]: -probeApproach * (value / 2 + options.approachDistance),
        variable: "#102",
      });

      // Retract up to the clearance height.
      handler.safeRelativeMove({ z: options.depth });

      // Move to axis midpoint
      writeBlock(
        gAbsIncModal.format(90),
        gFormat.format(1),
        `${axis.toUpperCase()}[[#101+#102]/2]`
      );

      // WCS update
      if (handler.updateDrivingWCS) {
        writeBlock(
          gFormat.format(10),
          `L20 P${handler.targetWcs}`,
          `${axis.toUpperCase()}0`
        );
      }
    }

    ["x", "y"].forEach(probeAxis);
  };

  const angleProbe = (options) => {
    writeComment(`Angle probe with double tap`);

    // Move down to the probing height.
    handler.safeRelativeMove({ z: -options.depth });

    const angleRadians = (options.nominalAngle * Math.PI) / 180;

    const probeAxis = (axis) => {
      if (!options[axis]) return;

      // Convert to cartesian.
      const xTravel = (options[axis] / 2) * Math.cos(angleRadians);
      const yTravel = (options[axis] / 2) * Math.sin(angleRadians);
      const probeArgs = {
        r: options.approachDistance,
        [axis]:
          handler.approach1 * (options.approachDistance + options.overtravel),
      };

      // Move to the first side.
      handler.safeRelativeMove({
        x: xTravel,
        y: yTravel,
      });

      // Probe with double tap.
      handler.touchProbe(probeArgs);

      // Save current position x and y in #101 and #102 respectively.
      writeBlock("#101 = #5021");
      writeBlock("#102 = #5022");

      // Retract away from the surface.
      handler.relativeMove({
        [axis]: -handler.approach1 * options.approachDistance,
      });

      // Move across to the other side.
      handler.safeRelativeMove({
        x: -2 * xTravel,
        y: -2 * yTravel,
      });

      // Probe again.
      handler.touchProbe(probeArgs);

      // Store the angle in #103.
      writeBlock(`#103=atan[[#5022-#102]/[#5021 - #101]]`);

      // Retract away from the surface.
      handler.relativeMove({
        [axis]: -handler.approach1 * options.approachDistance,
      });

      // Return to the midpoint.
      handler.relativeMove({
        x: xTravel,
        y: yTravel,
      });

      // Set the WCS rotation.
      if (handler.updateDrivingWCS) {
        const offset = axis == "x" ? "- 90" : "";
        writeBlock(
          gFormat.format(10),
          `L20 P${handler.targetWcs}`,
          `R[abs[#103 ${offset}]]`
        );
      }
    };

    ["x", "y"].forEach(probeAxis);
  };

  const handlers = {
    "probing-x": (x, y, z) => {
      // Move to the probing height, stop on contact.
      handler.safeRelativeMove({ z: cycle.bottom - z });

      handler.touchUpdateRetract({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });
    },
    "probing-x-channel": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
      });
    },
    "probing-x-channel-with-island": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
      });
    },
    "probing-x-wall": (x, y, z) => {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
      });
    },
    "probing-y": (x, y, z) => {
      // Move to the probing height, stop on contact.
      handler.safeRelativeMove({ z: cycle.bottom - z });

      handler.touchUpdateRetract({
        y: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });
    },
    "probing-y-channel": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        y: cycle.width1,
      });
    },
    "probing-y-channel-with-island": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        y: cycle.width1,
      });
    },
    "probing-y-wall": (x, y, z) => {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        y: cycle.width1,
      });
    },
    "probing-z": (x, y, z) => {
      const probeDepth = isFirstOperationProbeZ()
        ? handler.approach1 * 120
        : handler.approach1 *
          (cycle.depth + cycle.probeClearance + cycle.probeOvertravel);

      handler.touchProbe({
        z: probeDepth,
      });

      handler.updateWCS(zOutput, 0);
    },
    "probing-xy-inner-corner": (x, y, z) => {
      // Move down to the probing height.
      handler.safeRelativeMove({ z: cycle.bottom - z });

      // Probe the X.
      handler.touchUpdateRetract({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });

      // Probe the Y.
      handler.touchUpdateRetract({
        y: handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel),
      });
    },
    "probing-xy-rectangular-boss": (x, y, z) => {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width2,
      });
    },
    "probing-xy-circular-boss": (x, y, z) => {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width1,
      });
    },
    "probing-xy-circular-hole": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width1,
      });
    },
    "probing-xy-circular-hole-with-island": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width1,
      });
    },
    "probing-xy-rectangular-hole": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width2,
      });
    },
    "probing-xy-rectangular-hole-with-island": (x, y, z) => {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width2,
      });
    },
    "probing-xy-outer-corner": (x, y, z) => {
      // Move down to the probing height.
      handler.safeRelativeMove({ z: cycle.bottom - z });

      // Move along the y to the position where we'll probe the x.
      handler.safeRelativeMove({
        y: handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel),
      });

      handler.touchUpdateRetract({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });

      // Move back to the original y position.
      handler.relativeMove({
        y: -handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel),
      });

      // Move along the x to the position where we'll probe the y.
      handler.safeRelativeMove({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });

      handler.touchUpdateRetract({
        y: handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel),
      });

      // Move back to the original x position.
      handler.relativeMove({
        x: -handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel),
      });
    },
    "probing-x-plane-angle": (x, y, z) => {
      angleProbe({
        nominalAngle: cycle.nominalAngle,
        approachDistance: cycle.probeClearance,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        x: cycle.probeSpacing,
      });
    },
    "probing-y-plane-angle": (x, y, z) => {
      angleProbe({
        nominalAngle: cycle.nominalAngle,
        approachDistance: cycle.probeClearance,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        y: cycle.probeSpacing,
      });
    },
  };

  // Set up aliases for similar probing strategies.
  return { ...handler, ...handlers };
}

// Reference to this cycle, cleaned up at end
var cycleHandler = null;

// onCycle will set up the global cycleHandler.
function onCycle() {
  if (getProperty("firmwareType") == "community") {
    cycleHandler = communityFirmwareCycleHandler(cycle, tool);
  } else {
    cycleHandler = makeraFirmwareCycleHandler(cycle, tool);
  }

  writeComment(`Begin ${cycleType}`);
  writeComment(
    `WCS used during probing: G${calculateWCS(cycleHandler.drivingWcs)}`
  );
  if (cycleHandler.updateDrivingWCS) {
    writeComment(
      `WCS that will be updated: G${calculateWCS(cycleHandler.targetWcs)}`
    );
  }
}

// onCycleEnd currently just logs.
function onCycleEnd() {
  cycleHandler = null;
  writeComment("End " + cycleType);

  forceAny();
}

// Copied from heidenhain.cps, just enough to make the test in onCyclePoint work.
function getForwardDirection(_section) {
  if (_section.isMultiAxis()) {
    return _section.workPlane.forward;
  }
  return getRotation().forward;
}

function isFirstOperationProbeZ() {
  return (
    isFirstSection() &&
    currentSection.getParameter("operation:probingType") == "probing-z"
  );
}

// onCyclePoint dispatches to a cycle handler based on the cycleType.
function onCyclePoint(x, y, z) {
  // Check spindle orientation vs forward direction of this section. We can't, for instance,
  // have the probe attempt to come in sideways as is done in the default probing strategies sample.
  if (
    !isSameDirection(
      machineConfiguration.getSpindleAxis(),
      getForwardDirection(currentSection)
    )
  ) {
    error(
      localize(
        "direction of " +
          cycleType +
          " is not in same direction as spindle axis"
      )
    );
    return;
  }

  if (cycleHandler[cycleType] == null) {
    warning(localize(cycleType + " has no handler and will be expanded"));
    expandCyclePoint(x, y, z);
  }

  // If the first operation is a Z probe, we blocked the X,Y,Z rapid in onSection, so
  // we need to do the initial X,Y move here. Then the probe will go do its thing.
  if (isFirstOperationProbeZ()) {
    cycleHandler.absoluteMove({ x: x, y: y });
  } else {
    cycleHandler.absoluteMove({ x: x, y: y, z: z });
  }

  // Call the handler for this cycleType
  cycleHandler[cycleType](x, y, z);

  // Retract in to the cycle clearance height.
  cycleHandler.absoluteRapidMove({ z: cycle.clearance });
}

// ====================================================== //
// ================= END CYCLE HANDLERS ================= //
// ====================================================== //

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(
        localize(
          "Radius compensation mode cannot be changed at rapid traversal."
        )
      );
      return;
    }

    if (isFirstOperationProbeZ()) {
      writeBlock(gMotionModal.format(0), x, y);
    } else {
      writeBlock(gMotionModal.format(0), x, y, z);
    }

    feedOutput.reset();
  }
}

function onLinear(_x, _y, _z, feed) {
  // at least one axis is required
  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    xOutput.reset();
    yOutput.reset();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = feedOutput.format(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode is not supported."));
      return;
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) {
      // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}

function getFeed(f) {
  if (getProperty("useG95")) {
    return feedOutput.format(f / spindleSpeed); // use feed value
  }
  if (typeof activeMovements != "undefined" && activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return (
          settings.parametricFeeds.feedOutputVariable +
          (settings.parametricFeeds.firstFeedParameter + feedContext.id)
        );
      }
    }
    currentFeedId = undefined; // force parametric feed next time
  }
  return feedOutput.format(f); // use feed value
}

// <<<<< INCLUDED FROM include_files/onLinear_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onRapid5D_fanuc.cpi
function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (pendingRadiusCompensation >= 0) {
    error(
      localize("Radius compensation mode cannot be changed at rapid traversal.")
    );
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine()
    ? aOutput.format(_a)
    : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine()
    ? bOutput.format(_b)
    : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine()
    ? cOutput.format(_c)
    : toolVectorOutputK.format(_c);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    feedOutput.reset();
  }
}
// <<<<< INCLUDED FROM include_files/onRapid5D_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onLinear5D_fanuc.cpi
function onLinear5D(_x, _y, _z, _a, _b, _c, feed, feedMode) {
  if (pendingRadiusCompensation >= 0) {
    error(
      localize(
        "Radius compensation cannot be activated/deactivated for 5-axis move."
      )
    );
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine()
    ? aOutput.format(_a)
    : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine()
    ? bOutput.format(_b)
    : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine()
    ? cOutput.format(_c)
    : toolVectorOutputK.format(_c);
  if (feedMode == FEED_INVERSE_TIME) {
    feedOutput.reset();
  }
  var f =
    feedMode == FEED_INVERSE_TIME
      ? inverseTimeOutput.format(feed)
      : getFeed(feed);
  var fMode =
    feedMode == FEED_INVERSE_TIME ? 93 : getProperty("useG95") ? 95 : 94;

  if (x || y || z || a || b || c) {
    writeBlock(
      gFeedModeModal.format(fMode),
      gMotionModal.format(1),
      x,
      y,
      z,
      a,
      b,
      c,
      f
    );
  } else if (f) {
    if (getNextRecord().isMotion()) {
      // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), f);
    }
  }
}

function forceCircular(plane) {
  switch (plane) {
    case PLANE_XY:
      xOutput.reset();
      yOutput.reset();
      iOutput.reset();
      jOutput.reset();
      break;
    case PLANE_ZX:
      zOutput.reset();
      xOutput.reset();
      kOutput.reset();
      iOutput.reset();
      break;
    case PLANE_YZ:
      yOutput.reset();
      zOutput.reset();
      jOutput.reset();
      kOutput.reset();
      break;
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  // one of X/Y and I/J are required and likewise

  if (pendingRadiusCompensation >= 0) {
    error(
      localize(
        "Radius compensation cannot be activated/deactivated for a circular move."
      )
    );
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
      case PLANE_XY:
        forceCircular(getCircularPlane());
        writeBlock(
          gPlaneModal.format(17),
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          iOutput.format(cx - start.x),
          jOutput.format(cy - start.y),
          feedOutput.format(feed)
        );
        break;
      case PLANE_ZX:
        forceCircular(getCircularPlane());
        writeBlock(
          gPlaneModal.format(18),
          gMotionModal.format(clockwise ? 2 : 3),
          zOutput.format(z),
          iOutput.format(cx - start.x),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      case PLANE_YZ:
        forceCircular(getCircularPlane());
        writeBlock(
          gPlaneModal.format(19),
          gMotionModal.format(clockwise ? 2 : 3),
          yOutput.format(y),
          jOutput.format(cy - start.y),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      default:
        linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
      case PLANE_XY:
        forceCircular(getCircularPlane());
        writeBlock(
          gPlaneModal.format(17),
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          iOutput.format(cx - start.x),
          jOutput.format(cy - start.y),
          feedOutput.format(feed)
        );
        break;
      case PLANE_ZX:
        forceCircular(getCircularPlane());
        writeBlock(
          gPlaneModal.format(18),
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          iOutput.format(cx - start.x),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      case PLANE_YZ:
        forceCircular(getCircularPlane());
        writeBlock(
          gPlaneModal.format(19),
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          jOutput.format(cy - start.y),
          kOutput.format(cz - start.z),
          feedOutput.format(feed)
        );
        break;
      default:
        linearize(tolerance);
    }
  }
}

// <<<<< INCLUDED FROM include_files/onCircular_fanuc.cpi
// >>>>> INCLUDED FROM include_files/workPlaneFunctions_fanuc.cpi
var gRotationModal = createOutputVariable(
  {
    current: 69,
    onchange: function () {
      state.twpIsActive = gRotationModal.getCurrent() != 69;
      if (typeof probeVariables != "undefined") {
        probeVariables.outputRotationCodes =
          probeVariables.probeAngleMethod == "G68";
      }
      machineSimulation({}); // update machine simulation TWP state
    },
  },
  gFormat
);

var currentWorkPlaneABC = undefined;
function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

var mapCommand = {
  COMMAND_STOP: 0,
  COMMAND_END: 2,
  COMMAND_SPINDLE_CLOCKWISE: 3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE: 4,
  COMMAND_STOP_SPINDLE: 5,
};

function onCommand(command) {
  switch (command) {
    case COMMAND_STOP:
      writeBlock(mFormat.format(600));
      forceSpindleSpeed = true;
      forceCoolant = true;
      if (getProperty("defaultUseExternalControl")) {
        writeBlock(mFormat.format(852));
      }
      return;
    case COMMAND_STOP_SPINDLE:
      writeBlock(mFormat.format(5));
      forceSpindleSpeed = true;
      forceCoolant = true;
      if (getProperty("defaultUseExternalControl")) {
        writeBlock(mFormat.format(852));
      }
      return;
    case COMMAND_OPTIONAL_STOP:
      writeComment("Optional Stop Start");
      writeBlock(mFormat.format(1));
      forceSpindleSpeed = true;
      forceCoolant = true;
      if (getProperty("defaultUseExternalControl")) {
        writeBlock(mFormat.format(852));
      }
      writeComment("Optional Stop End");
      return;
    case COMMAND_START_SPINDLE:
      if (getProperty("defaultUseExternalControl")) {
        writeBlock(mFormat.format(851), pwmOutput.format(100));
      }
      onCommand(
        tool.clockwise
          ? COMMAND_SPINDLE_CLOCKWISE
          : COMMAND_SPINDLE_COUNTERCLOCKWISE
      );
      return;
    case COMMAND_LOCK_MULTI_AXIS:
      return;
    case COMMAND_UNLOCK_MULTI_AXIS:
      return;
    case COMMAND_TOOL_MEASURE:
      writeComment("Calibrate TLO");
      writeBlock(mFormat.format(490));
      return;
    case COMMAND_BREAK_CONTROL:
      writeComment("Tool Break Test");
      writeBlock("M491.1");
      return;
  }

  var stringId = getCommandStringId(command);
  var mcode = mapCommand[stringId];
  if (mcode != undefined) {
    writeBlock(mFormat.format(mcode));
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  if (currentSection.isMultiAxis()) {
    writeBlock(gFeedModeModal.format(94)); // inverse time feed off
  }
  writeBlock(gPlaneModal.format(17));
  if (!isLastSection() && getNextSection().getTool().coolant != tool.coolant) {
    setCoolant(COOLANT_OFF);
  }
  forceAny();
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  var retractAxes = new Array(false, false, false);
  validate(arguments.length != 0, "No axis specified for writeRetract().");

  for (i in arguments) {
    retractAxes[arguments[i]] = true;
  }

  if (retractAxes[0] && retractAxes[1] && retractAxes[2]) {
    if (getProperty("returnClearance")) {
      writeBlock(gFormat.format(28));
    }
  } else if (retractAxes[0]) {
    gMotionModal.reset();
    writeBlock(
      gAbsIncModal.format(90),
      gFormat.format(53),
      gMotionModal.format(0),
      "Z" + xyzFormat.format(toPreciseUnit(-3, MM))
    );
  }
}

var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;
var forceCoolant = false;

function setCoolant(coolant) {
  var coolantCodes = getCoolantCodes(coolant);
  if (Array.isArray(coolantCodes)) {
    if (singleLineCoolant) {
      writeBlock(coolantCodes.join(getWordSeparator()));
    } else {
      for (var c in coolantCodes) {
        writeBlock(coolantCodes[c]);
      }
    }
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant) {
  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (tool.type == TOOL_PROBE) {
    // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (
    coolant == currentCoolantMode &&
    (!forceCoolant || coolant == COOLANT_OFF)
  ) {
    return undefined; // coolant is already active
  }
  if (
    coolant != COOLANT_OFF &&
    currentCoolantMode != COOLANT_OFF &&
    coolantOff != undefined &&
    !forceCoolant
  ) {
    if (Array.isArray(coolantOff)) {
      for (var i in coolantOff) {
        multipleCoolantBlocks.push(coolantOff[i]);
      }
    } else {
      multipleCoolantBlocks.push(coolantOff);
    }
  }
  forceCoolant = false;

  var m;
  var coolantCodes = {};
  for (var c in coolants) {
    // find required coolant codes into the coolants array
    if (coolants[c].id == coolant) {
      coolantCodes.on = coolants[c].on;
      if (coolants[c].off != undefined) {
        coolantCodes.off = coolants[c].off;
        break;
      } else {
        for (var i in coolants) {
          if (coolants[i].id == COOLANT_OFF) {
            coolantCodes.off = coolants[i].off;
            break;
          }
        }
      }
    }
  }
  if (coolant == COOLANT_OFF) {
    m = !coolantOff ? coolantCodes.off : coolantOff;
    if (
      currentCoolantMode == COOLANT_AIR &&
      getProperty("useExtForAirCoolant")
    ) {
      currentCoolantMode = coolant;
      return [mFormat.format(852)];
    }
  } else {
    coolantOff = coolantCodes.off;
    if (coolant == COOLANT_AIR && getProperty("useExtForAirCoolant")) {
      currentCoolantMode = coolant;
      return ["M851S100"];
    }

    m = coolantCodes.on;
  }

  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  } else {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(m[i]);
      }
    } else {
      multipleCoolantBlocks.push(m);
    }
    currentCoolantMode = coolant;
    for (var i in multipleCoolantBlocks) {
      if (typeof multipleCoolantBlocks[i] == "number") {
        multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
      }
    }
    return multipleCoolantBlocks; // return the single formatted coolant value
  }
  return undefined;
}

// Start of onRewindMachine logic
/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c) {
  return false;
}

/** Retract to safe position before indexing rotaries. */
function onMoveToSafeRetractPosition() {
  writeRetract(Z);
}

/** Rotate axes to new position above reentry position */
function onRotateAxes(_x, _y, _z, _a, _b, _c) {
  // position rotary axes
  xOutput.disable();
  yOutput.disable();
  zOutput.disable();
  invokeOnRapid5D(_x, _y, _z, _a, _b, _c);
  setCurrentABC(new Vector(_a, _b, _c));
  xOutput.enable();
  yOutput.enable();
  zOutput.enable();
}

/** Return from safe position after indexing rotaries. */
function onReturnFromSafeRetractPosition(_x, _y, _z) {
  // position in XY
  forceXYZ();
  xOutput.reset();
  yOutput.reset();
  zOutput.disable();
  invokeOnRapid(_x, _y, _z);

  // position in Z
  zOutput.enable();
  invokeOnRapid(_x, _y, _z);
}
// End of onRewindMachine logic

function onClose() {
  setCoolant(COOLANT_OFF);

  if (machineConfiguration.isMultiAxisConfiguration()) {
    positionABC(new Vector(0, 0, 0), true);
  }
  onImpliedCommand(COMMAND_END);
  onCommand(COMMAND_STOP_SPINDLE);
  writeRetract(X, Y, Z);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
  if (isRedirecting()) {
    closeRedirection();
  }
  previousToolChangeWasManual = false;
}

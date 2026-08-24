/**
  Copyright (C) 2012-2022 by Autodesk, Inc.
  All rights reserved.

  Grbl post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2022-12-05 16:47:31 $

  FORKID {D897E9AA-349A-4011-AA01-06B6CCC181EB}
*/

description = "Makera Carvera Community Post v1.4.6";

vendor = "Makera";
vendorUrl = "https://www.makera.com";
legal = "Copyright (C) 2012-2022 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

extension = "cnc";
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_JET | CAPABILITY_MACHINE_SIMULATION;
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
highFeedrate = (unit == MM ? 3000 : 140);

// user-defined properties
properties = {
  writeMachine: {
    title      : "Write machine",
    description: "Output the machine settings in the header of the code.",
    group      : "4. File Structure",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  writeTools: {
    title      : "Write tool list",
    description: "Output a tool list in the header of the code.",
    group      : "4. File Structure",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  returnClearance: {
    title      : "Return to Clearance",
    description: "Return to clearance position when the job is finished.",
    group      : "4. File Structure",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  separateWordsWithSpace: {
    title      : "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group      : "4. File Structure",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  splitFile: {
    title      : "Split file",
    description: "Select your desired file splitting option.",
    group      : "4. File Structure",
    type       : "enum",
    values     : [
      {title:"No splitting", id:"none"},
      {title:"Split by tool", id:"tool"},
      {title:"Split by toolpath", id:"toolpath"}
    ],
    value: "none",
    scope: "post"
  },
  splitFileHeader: {
    title      : "Write Tool# and Header To Each Split By Toolpath File",
    description: "Write Tool# and Header To Each Split By Toolpath File",
    group      : "4. File Structure",
    type       : "boolean",
    value: true,
    scope: "post"
  },
  writeMKRHeader: {
    title      : "Write MKR Header for MakeraStudio",
    description: "Write MKR Header for MakeraStudio",
    group      : "4. File Structure",
    type       : "boolean",
    value: true,
    scope: "post"
  },
  laserEtchPower: {
    title      : "Laser etch power",
    description: "Sets the laser etch power.",
    group      : "3. Laser",
    type       : "number",
    value      : 0.1,
    scope      : "post"
  },
  laserPower: {
    title      : "Laser power",
    description: "Sets the laser power.",
    group      : "3. Laser",
    type       : "number",
    value      : 1,
    scope      : "post"
  },
  rotate4thAxisRelativeToModelPlane: {
    title      : "Automatic rotation of the 4th Axis",
    description: "If you are using the free version of fusion: Automatically rotates the 4th axis between consecutive setups. This means that the X-axis of the part has to be the rotation axis for the A axis. It will calculates the difference between consecutive model planes and automatically rotate the A axis accordingly between each setup. Setup 1 will be treated as the A-axis rotation of 0.",
    group      : "2. Free version enhancements",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useManual4thAxisRotations: {
    title      : "Use Manual NC Code to rotate A axis",
    description: "If you are using the free version of fusion and the manual NC to set A axis rotations, set this to true. Note that it will no longer put a G0 A0 at the top of every operation so you have to define a axis rotations manually, it will not automatically rotate to zero at the start of the file",
    group      : "2. Free version enhancements",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  
  
  defaultUseExternalControl: {
    title      : "Spindle-based External Control",
    description: "Turn the external PWM control on/off when the spindle is turned on/off.",
    group      : "1. Preferences",
    type       : "boolean",
    value: true,
    scope: "post"
  },
  useExtForAirCoolant: {
    title      : "Use Ext For Air Coolant",
    description: "Turn the external PWM control on/off when the air coolant is turned on/off.",
    group      : "1. Preferences",
    type       : "boolean",
    value: false,
    scope: "post"
  },
    manualToolChangeBehavior: {
    title      : "Manual Tool Change Behavior",
    description: "If you are using community firmware, select the community firmware option. If you are using a stock machine, choose the relavent option. The Stock C1 with manual tool changes will add code to do manual tool changes on tool numbers greater than 6 or the tool is marked for manual change, with the option to set up manual tool changes when the shank size changes. The community firmware does this automatically",
    group      : "1. Preferences",
    type       : "enum",
    values     : [
      {title:"Stock Air/Z1", id:"carvAirMtc"},
      {title:"Stock C1", id:"error6"},
      {title:"Stock C1 with Manual Tool Changes", id:"fusionMtc"},
      {title:"Carvera Community", id:"carvcomMtc", description:"works on both the C1 and Air and allows the use of the collet changes and offset tool support."},
   
    ],
    value: "carvAirMtc",


    scope: "post"
  },
  
  yAxisSafePosition: {
    title      : "Safe Y-axis position for A-axis rotation",
    description: "The Y-axis position to move to when performing a safe A-axis rotation. A value of 0 means that the Y-axis will not be moved during A-axis rotations. This setting can be left default for normal operation.",
    group      : "1. Preferences",
    type       : "integer",
    value      : -100,
    scope      : "post"
  },
  useToolCommentForChangeParameters: {
    title      : "Community Firmware Offset Tool Change Support",
    description: "Community Firmware: Use the tool comment field to add parameters to the tool change command (e.g. M6 T1 X-12 R3, where \"X-12 R3\" is in the comment field). This allows the user to probe face mills",
    group      : "1. Preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  issueColletChangeOnShankSizeChange: {
    title      : "Community Firmware Collet Changes",
    description: "Community Firmware: Add info about the collet to use to tool change commands. (e.g. M6 T1 S1, where \"S1\" is the collet change parameter)",
    group      : "1. Preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  wcs          : [
    {name:"Standard", format:"G", range:[54, 59]}
  ]
};

var numberOfToolSlots = 9999;
var previousToolChangeWasManual = false;
var subprograms = new Array();
var laser_used = false;

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
// {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
var coolants = [
  {id:COOLANT_FLOOD, on:8},
  {id:COOLANT_MIST},
  {id:COOLANT_THROUGH_TOOL},
  {id:COOLANT_AIR, on:[400,7]},
  {id:COOLANT_AIR_THROUGH_TOOL},
  {id:COOLANT_SUCTION},
  {id:COOLANT_FLOOD_MIST},
  {id:COOLANT_FLOOD_THROUGH_TOOL},
  {id:COOLANT_OFF, off:[400,9]}
];

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var rFormat = xyzFormat; //radius
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var feedFormat = createFormat({decimals:0});
var inverseTimeFormat = createFormat({decimals:3, forceDecimal:true});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var powerFormat = createFormat({decimals:2});
var pwmFormat = createFormat({decimals:0, maximum:100, minimum:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000
var taperFormat = createFormat({decimals:1, scale:DEG});
var integerFormat = createFormat({decimals:0});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({onchange:function () {retracted = false;}, prefix:"Z"}, xyzFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var inverseTimeOutput = createVariable({prefix:"F", force:true}, inverseTimeFormat);
var pwmOutput = createVariable({prefix:"S", force:true}, pwmFormat);
var sOutput = createVariable({prefix:"S"}, rpmFormat);
var powerOutput = createOutputVariable({prefix:"S"}, powerFormat);

// circular output
var iOutput = createVariable({prefix:"I"}, xyzFormat);
var jOutput = createVariable({prefix:"J"}, xyzFormat);
var kOutput = createVariable({prefix:"K"}, xyzFormat);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G93-94
var gUnitModal = createOutputVariable({}, gFormat); // modal group 6 // G20-21

var fourthAxisRotationPreviousLocation = undefined;

var WARNING_WORK_OFFSET = 0;

// collected state
var forceSpindleSpeed = false;
var currentWorkOffset;
var retracted = false; // specifies that the tool has been retracted to the safe plane

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }

  writeWords(arguments);
}

function formatComment(text) {
  return "(" + String(text).replace(/[()]/g, "") + ")";
}

/** Standard collet diameters in mm (order: 6.35 before 6 to match correctly). Map to S1-S5; do not change S numbering. */
var STANDARD_SHAFT_DIAMETERS_MM = [3, 3.175, 4, 6.35, 6, 8];
var STANDARD_SHAFT_TOLERANCE_MM = 0.01;

/**
  Analyse tool.shaft sections: if any section diameter matches 3.175, 4, 6, 6.35 or 8 mm, return that value in mm.
  getDiameter(i) is in current unit (MM or IN); comparison is in mm.
  Returns the matching standard diameter (number) or undefined if no match / no shaft.
*/
function getMatchingShaftDiameterMm(tool) {
  if (!tool.shaft || !tool.shaft.hasSections()) {
    return undefined;
  }
  var n = tool.shaft.getNumberOfSections();
  for (var i = 0; i < n; ++i) {
    var dia = tool.shaft.getDiameter(i);
    var diaMm = (unit == MM) ? Number(dia) : (Number(dia) * 25.4);
    if (isNaN(diaMm)) continue;
    for (var j = 0; j < STANDARD_SHAFT_DIAMETERS_MM.length; ++j) {
      if (Math.abs(diaMm - STANDARD_SHAFT_DIAMETERS_MM[j]) <= STANDARD_SHAFT_TOLERANCE_MM) {
        return STANDARD_SHAFT_DIAMETERS_MM[j];
      }
    }
  }
  return undefined;
}

/**
  Get shaft diameter in mm for a tool: prefer segment match (3/3.175/4/6/6.35/8), else tool.shaftDiameter in mm.
*/
function getToolShaftDiameterMm(tool) {
  var match = getMatchingShaftDiameterMm(tool);
  if (match !== undefined) return match;
  var raw = (typeof tool.shaftDiameter === "number") ? tool.shaftDiameter : 0;
  return (unit == MM) ? raw : (raw * 25.4);
}

/**
  Shaft diameter in current document units.
*/
function getShaftDiameter(tool) {
  var diaMm = getToolShaftDiameterMm(tool);
  return (unit == MM) ? diaMm : (diaMm / 25.4);
}

/**
  Returns S1-S5 parameter for tool change when shank diameter changed.
  DO NOT CHANGE THIS NUMBERING: S1=3.175mm, S2=4mm, S3=6mm, S4=6.35mm, S5=8mm.
  diameterMm in mm. Returns "" if no match.
*/
function getShankSizeSuffix(diameterMm) {
  var d = Number(diameterMm);
  if (isNaN(d)) return "";
  var tol = STANDARD_SHAFT_TOLERANCE_MM;
  if (Math.abs(d - 3) <= tol) return "S1";
  if (Math.abs(d - 3.175) <= tol) return "S2";
  if (Math.abs(d - 4) <= tol) return "S3";
  if (Math.abs(d - 6.35) <= tol) return "S5";
  if (Math.abs(d - 6) <= tol) return "S4";
  if (Math.abs(d - 8) <= tol) return "S6";
  return "";
}

/**
  Writes the specified block - used for tool changes only.
*/
function writeToolBlock() {
  writeBlock(arguments);
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
    if (value == "pierce"){
      return;//nothing special happens
    }
    if (String(value).toUpperCase() == "SPINDLEOFF"){
      writeBlock("M5 (Spindle Off)")
    } else if (String(value).toUpperCase() == "CLEARANCE"){
      writeBlock("G28 (Go to clearance)")
    } else if (String(value).toUpperCase() == "CLEARAUTOLEVEL"){
      writeBlock("M370 (clear autolevel)")
    } else if (String(value).toUpperCase() == "RESETFEEDOVERRIDE"){
      writeBlock("M220 S100 (Reset Feed Speed override)")
    } else if (String(value).toUpperCase() == "AIRON"){
      writeBlock(mFormat.format(400));
      writeBlock("M7 (Compressed Air On)")
    } else if (String(value).toUpperCase() == "AIROFF"){
      writeBlock(mFormat.format(400));
      writeBlock("M9 (Compressed Air Off)")
    } else if (String(value).toUpperCase() == "VACON"){
      writeBlock(mFormat.format(400));
      writeBlock("M801 S100 (Vacuum On)")
    } else if (String(value).toUpperCase() == "VACOFF"){
      writeBlock(mFormat.format(400));
      writeBlock("M802 (Vacuum Off)")
    } else if (String(value).toUpperCase() == "AUTOVACON"){
      writeBlock(mFormat.format(400));
      writeBlock("M331 (Turn On Auto Vacuum)")
    } else if (String(value).toUpperCase() == "AUTOVACOFF"){
      writeBlock(mFormat.format(400));
      writeBlock("M332 (Turn Off Auto Vacuum)")
    } else if (String(value).toUpperCase() == "LIGHTON"){
      writeBlock(mFormat.format(400));
      writeBlock("M821 (Turn On Light)")
    } else if (String(value).toUpperCase() == "LIGHTOFF"){
      writeBlock(mFormat.format(400));
      writeBlock("M822 (Turn Off Light)")
    } else if (String(value).toUpperCase() == "EXTON"){
      writeBlock(mFormat.format(400));
      writeBlock("M851 S100 (External Control On 100)")
    } else if (String(value).toUpperCase() == "EXTOFF"){
      writeBlock(mFormat.format(400));
      writeBlock("M852 (External Control Off)")
    } else if (String(value).toUpperCase() == "SHRINKA"){
      writeBlock("G92.4 A0 S0 (shrink the a axis so A365 becomes A5)")
    } else if (String(value).toUpperCase() == "SAFEZ"){
      writeBlock("G53 G0 Z -2. (Goto Safe Height In Z)")
    } else {
      var sText1 = String(value);
      var sText2 = new Array();
      sText2 = sText1.split(":");
      if (sText2.length == 2) {
        if (sText2[0].toUpperCase() == "RAPIDA") {
          if (sText2[1].match(/^-?\d+$/)){
            writeBlock("G0A"+sText2[1] + "(Rapid movement on a axis)")
          } else{
            invalid = true;
          }

        } else if (sText2[0].toUpperCase() == "SAFERA") {
          if (sText2[1].match(/^-?\d+$/)){
            writeBlock("G53 G0 Z -2. (Goto Safe Height In Z)")
            gMotionModal.reset();
            safeYPosition = getProperty("yAxisSafePosition");
            writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Y" + xyzFormat.format(toPreciseUnit(safeYPosition, MM)), "Z" + xyzFormat.format(toPreciseUnit(-3, MM)));
            writeBlock("G0A"+sText2[1] + "(Rapid movement on a axis)")
          } else{
            invalid = true;
          }
        } else if (sText2[0].toUpperCase() == "FEEDOVERRIDE") {
          if (sText2[1].match(/^-?\d+$/)){
            writeBlock("M220 S"+sText2[1] + "(Globally sets the feed speed to "+ sText2[1] +" percent. Useful for vetting a program the first time you run it. Remember to run M220 S100 when you are done with the program or restart the machine)")
          } else{
            invalid = true;
          }
        }



      } else {
        invalid = true;
      }

    }
    if (invalid) {
      error(localize("Invalid action parameter: ") + sText2[0] + ":" + sText2[1]);
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
  if (!machineConfiguration.isMachineCoordinate(0) && (typeof aOutput != "undefined")) {
    aOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(1) && (typeof bOutput != "undefined")) {
    bOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(2) && (typeof cOutput != "undefined")) {
    cOutput.disable();
  }

  // setup usage of multiAxisFeatures
  useMultiAxisFeatures = getProperty("useMultiAxisFeatures") != undefined ? getProperty("useMultiAxisFeatures") :
    (typeof useMultiAxisFeatures != "undefined" ? useMultiAxisFeatures : false);
  useABCPrepositioning = getProperty("useABCPrepositioning") != undefined ? getProperty("useABCPrepositioning") :
    (typeof useABCPrepositioning != "undefined" ? useABCPrepositioning : false);

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // don't need to modify any settings for 3-axis machines
  }

  // save multi-axis feedrate settings from machine configuration
  var mode = machineConfiguration.getMultiAxisFeedrateMode();
  var type = mode == FEED_INVERSE_TIME ? machineConfiguration.getMultiAxisFeedrateInverseTimeUnits() :
    (mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateDPMType() : DPM_STANDARD);
  multiAxisFeedrate = {
    mode     : mode,
    maximum  : machineConfiguration.getMultiAxisFeedrateMaximum(),
    type     : type,
    tolerance: mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateOutputTolerance() : 0,
    bpwRatio : mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateBpwRatio() : 1
  };

  // setup of retract/reconfigure  TAG: Only needed until post kernel supports these machine config settings
  if (receivedMachineConfiguration && machineConfiguration.performRewinds()) {
    safeRetractDistance = machineConfiguration.getSafeRetractDistance();
    safePlungeFeed = machineConfiguration.getSafePlungeFeedrate();
    safeRetractFeed = machineConfiguration.getSafeRetractFeedrate();
  }
  if (typeof safeRetractDistance == "number" && getProperty("safeRetractDistance") != undefined && getProperty("safeRetractDistance") != 0) {
    safeRetractDistance = getProperty("safeRetractDistance");
  }

  if (machineConfiguration.isHeadConfiguration()) {
    compensateToolLength = typeof compensateToolLength == "undefined" ? false : compensateToolLength;
  }

  if (machineConfiguration.isHeadConfiguration() && compensateToolLength) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var section = getSection(i);
      if (section.isMultiAxis()) {
        machineConfiguration.setToolLength(getBodyLength(section.getTool())); // define the tool length for head adjustments
        section.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS);
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
      return section.getParameter("operation:tool_overallLength", tool.bodyLength + tool.holderLength);
    }
  }
  return tool.bodyLength + tool.holderLength;
}

/**
  Append " KEY=value" when value is a finite number.
  By default requires value > 0; pass allowZero=true to also accept 0 (e.g. tip diameter).
*/
function appendToolField(comment, key, value, format, allowZero) {
  if (typeof value != "number" || isNaN(value)) {
    return comment;
  }
  if (allowZero ? value < 0 : value <= 0) {
    return comment;
  }
  return comment + " " + key + "=" + format.format(value);
}

/**
  Dump one comment line per tool for the header tool list.

  Layout:
  T<n>  <description>  <vendor>  <productId>  D=<diameter>
    [CR=<corner radius>] [SD=<shaft>] [TD=<tip>] [FL=<flute>] [SL=<shoulder>]
    [BL=<body>] [TP=<pitch>] [TAPER=<angle>deg] [- ZMIN=<z>] - <toolTypeName>

  See https://cam.autodesk.com/posts/reference/classTool.html
*/
function dumpToolInformation() {
  var zRanges = {};
  if (is3D()) {
    var numberOfSections = getNumberOfSections();
    for (var i = 0; i < numberOfSections; ++i) {
      var section = getSection(i);
      var zRange = section.getGlobalZRange();
      var sectionTool = section.getTool();
      if (zRanges[sectionTool.number]) {
        zRanges[sectionTool.number].expandToRange(zRange);
      } else {
        zRanges[sectionTool.number] = zRange;
      }
    }
  }

  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      var comment = "T" + toolFormat.format(tool.number) + "  " +
        tool.description + "  " +
        tool.vendor + "  " +
        tool.productId + "  " +
        "D=" + xyzFormat.format(tool.diameter);

      // Extra geometry
      comment = appendToolField(comment, "CR", tool.cornerRadius, xyzFormat);
      comment = appendToolField(comment, "SD", getShaftDiameter(tool), xyzFormat);
      comment = appendToolField(comment, "TD", tool.tipDiameter, xyzFormat, true);
      comment = appendToolField(comment, "FL", tool.fluteLength, xyzFormat);
      comment = appendToolField(comment, "SL", tool.shoulderLength, xyzFormat);
      comment = appendToolField(comment, "BL", tool.bodyLength, xyzFormat);
      comment = appendToolField(comment, "TP", tool.threadPitch, xyzFormat);

      if ((tool.taperAngle > 0) && (tool.taperAngle < Math.PI)) {
        comment += " TAPER=" + taperFormat.format(tool.taperAngle) + "deg";
      }

      if (zRanges[tool.number]) {
        comment += " - ZMIN=" + xyzFormat.format(zRanges[tool.number].getMinimum());
      }

      comment += " - " + getToolTypeName(tool.type);
      writeComment(comment);
    }
  }
}

function dumpMKRHeader(machineConfiguration) {
  writeln(";@MKR|BEGIN");
  writeln(";@MKR|SCHEMA|v=1.0.0");

  if (machineConfiguration.getVendor() === "Makera" && (machineConfiguration.getModel() || "").substr(0, 3) === "Z1 ") {
    writeln(";@MKR|MACHINE|id=Z1|name=Makera Z1");
  }

  var tools = getToolTable();
  for (var i = 0; i < tools.getNumberOfTools(); ++i) {
    var tool = tools.getTool(i);
    var comment = ";@MKR|TOOL|number=" + toolFormat.format(tool.number);
    comment += "|name=" + tool.description;
    writeln(comment)
  }

  writeln(";@MKR|END")
  writeln("")
}

function defineMachine() {
  if (false) { // note: setup your machine here
    var aAxis = createAxis({coordinate:0, table:true, axis:[1, 0, 0], cyclic:true, tcp:false});
    machineConfiguration = new MachineConfiguration(aAxis);

    setMachineConfiguration(machineConfiguration);
    if (receivedMachineConfiguration) {
      warning(localize("The provided CAM machine configuration is overwritten by the postprocessor."));
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
      safeRetractDistance = (unit == IN) ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
      safeRetractFeed = (unit == IN) ? 20 : 500; // retract feed rate
      safePlungeFeed = (unit == IN) ? 10 : 250; // plunge feed rate
      machineConfiguration.setSafeRetractDistance(safeRetractDistance);
      machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
      machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
      var stockExpansion = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN)); // expand stock XYZ values
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

function onOpen(section) {
  // define and enable machine configuration
  receivedMachineConfiguration = machineConfiguration.isReceived();

  if (typeof defineMachine == "function") {
    defineMachine(); // hardcoded machine configuration
  }
  activateMachine(); // enable the machine optimizations and settings

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  // Unfortunately these needs to be first for MakeraStudio to see it
  if (getProperty("writeMKRHeader")) {
    dumpMKRHeader(machineConfiguration);
  }

  if (programName) {
    writeComment(programName);
  }
  if (programComment) {
    writeComment(programComment);
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
      writeComment("  " + localize("description") + ": "  + description);
    }
  }

  var currentSection = getSection(0);

  // dump tool information
  if (getProperty("writeTools")) {
    dumpToolInformation();
  }







  function wcsComment(text) {
    writeln("( " + text + " )");
  }

  function fmtZ(val) {
    return xyzFormat.format(val) + (unit == MM ? " mm" : " in");
  }

  var bbox     = currentSection.getBoundingBox();
  var stockTop = currentSection.getParameter("operation:stockZHigh", 0);
  var stockBot = currentSection.getParameter("operation:stockZLow",  0);

  // WCS Z origin is at Z=0 in WCS space; compare against known references
  var wcsZ = 0;
  var tol  = spatial(0.001, MM);
  var zRef;
  var tzMax = -999999;
  var tzMin =  999999;
  var custom = false;
  for (var i = 0; i < getNumberOfSections(); i++) {
    var s = getSection(i);
    if (s.workOffset == currentSection.workOffset) {
      var zRange = s.getGlobalZRange();
      if (zRange.getMaximum() > tzMax) { tzMax = zRange.getMaximum(); }
      if (zRange.getMinimum() < tzMin) { tzMin = zRange.getMinimum(); }
    }
  }
  if (Math.abs(wcsZ - stockTop) < tol) {
    zRef = "Stock Top";
  } else if (Math.abs(wcsZ - stockBot) < tol) {
    zRef = "Stock Bottom";
  } else {
    custom = true;
    var dStockTop = wcsZ - stockTop;
    zRef = "Selected Point"
         + " | " + fmtZ(Math.abs(dStockTop)) + (dStockTop < 0 ? " below" : " above") + " Stock Top"
  }

  

  var sep = "===================================================";
  wcsComment(sep);
  wcsComment("  Z Origin Set To   : " + zRef);
  wcsComment("  Stock Height                    : " + fmtZ(stockTop-stockBot));
  if (custom){
    wcsComment("  Stock Above Origin            : " + fmtZ(stockTop));
    wcsComment("  Stock Below Origin            : " + fmtZ(stockBot));
    wcsComment("  Toolpath Z Maximum from origin: " + fmtZ(tzMax));
    wcsComment("  Toolpath Z Min from origin: " + fmtZ(tzMin));
    wcsComment("  Toolpath Z Maximum from Stock Top: " + fmtZ(tzMax + dStockTop));
    wcsComment("  Toolpath Z Min from Stock Top: " + fmtZ(tzMin + dStockTop));
  } else {
    wcsComment("  Toolpath Z Maximum from " + zRef + ": " + fmtZ(tzMax));
    wcsComment("  Toolpath Z Min from " + zRef + ": " + fmtZ(tzMin));
  }
  wcsComment("");
  wcsComment(sep);
  writeln("");

  var partAttachPoint = currentSection.getPartAttachPoint();
  var modelPlane = currentSection.getModelPlane();

  var right   = modelPlane.right;
  var up      = modelPlane.up;
  // Derive the true Z axis from right and up instead of using forward
  var forward = Vector.cross(right, up);

  var localPartAttachPoint = new Vector(
    Vector.dot(partAttachPoint, right),
    Vector.dot(partAttachPoint, up),
    Vector.dot(partAttachPoint, forward)
  );
  var xoffset = -localPartAttachPoint.x;
  var yoffset = -localPartAttachPoint.y;
  var zoffset = -localPartAttachPoint.z;
  
  wcsComment("The following values are based on the part position info used in fusion and can be used to roughly align the machine offset from anchor 1 if you use that feature.");
  wcsComment("  X Offset   : " + fmtZ(xoffset));
  wcsComment("  Y Offset   : " + fmtZ(yoffset));

  writeln("");
  wcsComment(sep);
  writeln("");




  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
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
  return hasParameter("operation-strategy") &&
    (getParameter("operation-strategy") == "probe");
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

var currentAAngle = 0;
var previousAAngle = 0;
var toolOrientationUsed = false;

function defineWorkPlane(_section, _setWorkPlane) {
  var abc = new Vector(0, 0, 0);
  if (machineConfiguration.isMultiAxisConfiguration()) { // use 5-axis indexing for multi-axis mode
    abc = _section.isMultiAxis() ? _section.getInitialToolAxisABC() : getWorkPlaneMachineABC(_section.workPlane);
    if (_section.isMultiAxis()) {
      cancelTransformation();
      if (_setWorkPlane) {
        forceWorkPlane();
        positionABC(abc, true);
      }
    } else {
      abc = getWorkPlaneMachineABC(_section.workPlane);
      if (_setWorkPlane) {
        var tol = 1e-6;
        if (!getProperty("useManual4thAxisRotations")||(Math.abs(abc.x) > tol || Math.abs(abc.y) > tol || Math.abs(abc.z) > tol)||toolOrientationUsed){
          setWorkPlane(abc);
          toolOrientationUsed = true;
      }
      }
    }
  
  } else { // pure 3D
    // Inject a 4th axis rotation if the WCS and model plane are not aligned
    if (getProperty("rotate4thAxisRelativeToModelPlane")) {
      var currOrigin = currentSection.modelOrigin;

      if (!currOrigin) {
        error(localize("Unable to resolve WCS origin in world space."));
				 
      }

      if (fourthAxisRotationPreviousLocation === undefined) {
        fourthAxisRotationPreviousLocation = new Vector(currOrigin.x, currOrigin.y, currOrigin.z);
      } else {
        var dx = fourthAxisRotationPreviousLocation.x - currOrigin.x;
        var dy = fourthAxisRotationPreviousLocation.y - currOrigin.y;
        var dz = fourthAxisRotationPreviousLocation.z - currOrigin.z;
        if ((dx * dx + dy * dy + dz * dz) > 1e-12) {
          error(localize("Origin must be in the same location when automatic 4th axis rotation is used"));
        }
      }

      previousAAngle = currentAAngle;
      currentAAngle = calculateAAxisRotation();

      if(Math.abs(currentAAngle - previousAAngle) > 0.001) { // Only rotate if the angle change is relevant to avoid unnecessary retracts and moves
        writeComment("Retracting to safe position for possible A axis rotation");
        writeRetract(Z, Y);
        var angle = Math.round(currentAAngle * 1000) / 1000;
        writeBlock(gAbsIncModal.format(90), gFormat.format(54), gFormat.format(0), "A" + angle, formatComment("Rotate the A axis to align WCS and model plane"));
      }
    } else {
      var abc = getWorkPlaneMachineABC(_section.workPlane);

      if (_setWorkPlane) {
          writeRetract(Z);
        positionABC(abc, true);
      }
    }
    if (currentSection && (currentSection.getId() == _section.getId())) {
      operationSupportsTCP = currentSection.getOptimizedTCPMode() == OPTIMIZE_NONE;
      if (!currentSection.isMultiAxis() && (useMultiAxisFeatures || isSameDirection(machineConfiguration.getSpindleAxis(), currentSection.workPlane.forward))) {
        operationSupportsTCP = false;
      }
    }
  }
  return abc;
}

// Calculates the angle between previous model plane and a [current] model plane for A axis rotation
function calculateAAxisRotation() {
  var relativeAngle = signedXPlaneRotationDeg(currentSection.getModelPlane());

  return normalizeDegrees(relativeAngle);
}

var rotationStartForward = null;
function signedXPlaneRotationDeg(plane) {

  if (rotationStartForward == null) { // First setup, set the initial plane and don't rotate
    rotationStartForward = plane.forward;
    return 0;
  }
  var planeForward = plane.forward;

  var dot = Vector.dot(rotationStartForward, planeForward);
  if (dot > 1) dot = 1;
  if (dot < -1) dot = -1;

  var theta = Math.acos(dot); // 0..pi

  // sign by X of cross(aForward, bForward)
  var cross = Vector.cross(rotationStartForward, planeForward);
  var sign = (cross.x >= 0) ? 1 : -1;
  
  return normalizeDegrees(radToDeg(theta) * sign);
}

// Convert radians to degrees
function radToDeg(theta) {
  return theta * 180.0 / Math.PI;
}

// normalize to (-180,180)
function normalizeDegrees(deg) {
  while (deg < -180) deg += 360;
  while (deg > 180) deg -= 360;
  return deg;
}

function setWorkPlane(abc) {
  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
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
    var a_axis_offset = parseFloat(a.substring(1));
    if (!isNaN(a_axis_offset)) {
      writeBlock("G92.4 A" + a_axis_offset + " R0 (shrink the a axis so A365 becomes A5)")
    }
    writeBlock(gMotionModal.format(0), a, b, c);
    setCurrentABC(abc); // required for machine simulation
  }
}

function getWorkPlaneMachineABC(workPlane) {
  var W = workPlane; // map to global frame

  var currentABC = isFirstSection() ? new Vector(0, 0, 0) : getCurrentDirection();
  var abc = machineConfiguration.getABCByPreference(W, currentABC, ABC, PREFER_PREFERENCE, ENABLE_ALL);

  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
    return new Vector();
  }

  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
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
  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number) || (getProperty("splitFile") == "toolpath" && getProperty("splitFileHeader"));

  var splitHere = getProperty("splitFile") == "toolpath" || (getProperty("splitFile") == "tool" && insertToolCall);

  retracted = false; // specifies that the tool has been retracted to the safe plane
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset) ||
    splitHere; // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis()) ||
    (currentSection.isOptimizedForMachine() && getPreviousSection().isOptimizedForMachine() &&
      Vector.diff(getPreviousSection().getFinalToolAxisABC(), currentSection.getInitialToolAxisABC()).length > 1e-4) ||
    (!machineConfiguration.isMultiAxisConfiguration() && currentSection.isMultiAxis()) ||
    (!getPreviousSection().isMultiAxis() && currentSection.isMultiAxis() ||
      getPreviousSection().isMultiAxis() && !currentSection.isMultiAxis()) ||
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
      subprogram = programName + "_" + (subprograms.length + 1) + "_" + comment + "_" + "T" + tool.number;
    } else {
      subprogram = programName + "_" + (subprograms.length + 1) + "_" + "T" + tool.number;
    }

    subprograms.push(subprogram);

    var path = FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), String(subprogram).replace(/[<>:"/\\|?*]/g, "") + "." + extension);

    writeComment(localize("Load tool number " + tool.number + " and subprogram " + subprogram));

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
      writeComment(comment);
    }
  }

  if (insertToolCall) {

    if(getProperty("splitFile") == "toolpath" && getProperty("splitFileHeader")) {
      dumpToolInformation();
    }

    setCoolant(COOLANT_OFF);

    // Shank diameter change: add S1-S5 to M6 when shaft diameter changed (S1=3.175mm, S2=4mm, S3=6mm, S4=6.35mm, S5=8mm; do not change numbering)
    // Use shaft segments (Tool tab) to match standard diameter; fallback to tool.shaftDiameter
    var shaftDiameterMm = getToolShaftDiameterMm(tool);
    var prevShaftMm = !isFirstSection() ? getToolShaftDiameterMm(getPreviousSection().getTool()) : 0;
    var shankDiameterChanged = !isFirstSection() && (Math.abs(shaftDiameterMm - prevShaftMm) > 0.001);
    var shaftParam = (shankDiameterChanged || isFirstSection()) ? getShankSizeSuffix(shaftDiameterMm) : "";

    if (tool.number > numberOfToolSlots) {
      warning(localize("Tool number exceeds maximum value."));
    }

    if (tool.type == TOOL_LASER_CUTTER){
      writeToolBlock(mFormat.format(321));
      writeBlock("M106")
      laser_used = true;
      return;
    }

    if (laser_used){
      writeBlock("M5");
      writeBlock("M107");
      writeBlock("M322");
      laser_used = false;
    }

    var tloValue = parseTLO(tool.comment);//A is automatic and is the default, M is manual setting (C=0), a number set the value directly (H=-14)

    var e_manualToolChangeBehavior = getProperty("manualToolChangeBehavior");

    if(tool.number > 6 && e_manualToolChangeBehavior == "error6") {
      error(localize("Carvera does not support tool numbers greater than 6 by default. Use one of the manual tool change post processor settings"));
    }

    if (e_manualToolChangeBehavior == "carvAirMtc"){ //any tool number accepted
      var toolChangeParameters = "";
      if (getProperty("useToolCommentForChangeParameters")){
        toolChangeParameters = tool.comment;
      }
      if (getProperty("issueColletChangeOnShankSizeChange")){
        toolChangeParameters = toolChangeParameters + " " + shaftParam;
      }

      writeBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " " + toolChangeParameters);

      if (tool.comment && !getProperty("useToolCommentForChangeParameters")) {
        writeComment(tool.comment);
      }
    } else if (e_manualToolChangeBehavior == "carvcomMtc"){

      if (tloValue && !getProperty("useToolCommentForChangeParameters")) {
        if (tloValue === "A") {
            writeBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " C1");
        } else if (tloValue === "M") {
          writeBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " C0");  
        } else {
            var tloFloat = parseFloat(tloValue);
            if (!isNaN(tloFloat)) {
                writeBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " H" + tloFloat);
                writeToolBlock(mFormat.format(6), "T" + toolFormat.format(tool.number) + " H" + tloFloat);
            } else {
                writeBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6));
            }
        }
      } else {
        var toolChangeParameters = "";
        if (getProperty("useToolCommentForChangeParameters")){
          toolChangeParameters = tool.comment;
        }
        if (getProperty("issueColletChangeOnShankSizeChange")){
          toolChangeParameters = toolChangeParameters + " " + shaftParam;
        }
        writeBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " " + toolChangeParameters);
      }
    }else if (tool.number > 6 || tool.manualToolChange) {
      writeComment("Manual Tool Change To #" + toolFormat.format(tool.number));
      if (tool.manualToolChange) {
        writeComment("as a result of manual tool change selected in tool settings");
      }
      performStockManualToolChange(tloValue);
    } else {
        if (previousToolChangeWasManual && e_manualToolChangeBehavior == "fusionMtc") {
		      writeComment("Manual Tool Removal as a result of previous manual tool change");
          writeComment("setup for tool change");
          writeBlock("G28");
          writeComment("Paused. Prepare to remove tool from collet. Pressing play will release collet");
          writeBlock(mFormat.format(27));
          writeBlock(mFormat.format(600));
          writeBlock("M490.2");
          writeComment("Paused. Pressing play will resume program. The program expects an empty collet after this point.");
          writeBlock(mFormat.format(27));
          writeBlock(mFormat.format(600));
          writeBlock("M493.2 T-1");

        }
        writeBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6));

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

  var spindleChanged = tool.type != TOOL_PROBE &&
    (insertToolCall || forceSpindleSpeed || isFirstSection() ||
    (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
    (tool.clockwise != getPreviousSection().getTool().clockwise));
  if (spindleChanged) {
    forceSpindleSpeed = false;
    writeComment(tool.type);
    if (spindleSpeed < 1 && tool.type != TOOL_LASER_CUTTER) {
      error(localize("Spindle speed out of range."));
    }
    if (spindleSpeed > 99999) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
    if (getProperty("defaultUseExternalControl")) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(851), pwmOutput.format(100));
    }
    writeBlock(
      sOutput.format(spindleSpeed), mFormat.format(tool.clockwise ? 3 : 4)
    );
  }

  // wcs
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }
  if (currentSection.type == TYPE_JET) {
    if (tool.type != TOOL_LASER_CUTTER) {
      error(localize("The CNC does not support the required tool/process. Only laser cutting is supported."));
    }

    switch (currentSection.jetMode) {
    case JET_MODE_THROUGH:
    case JET_MODE_ETCHING:
    case JET_MODE_VAPORIZE:
      break;
    default:
      error(localize("Unsupported cutting mode."));
    }
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
      writeBlock(
        gAbsIncModal.format(90),
        gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
      );
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
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
  writeJetCodes(true);
}

function performStockManualToolChange(tloValue) {


  if (tool.comment) {
    writeComment(tool.comment);
  }

  writeComment("Setup for tool change");
  if (previousToolChangeWasManual || isFirstSection()) {
    writeBlock("G28");
    writeComment("Paused. Prepare to remove tool from collet. Pressing play will release collet");
    writeBlock(mFormat.format(27));
    writeBlock(mFormat.format(600));
    writeBlock("M490.2 (Open Collet)");

  } else {
    writeBlock("T-1 M6");
    writeBlock("G28");
  }


  previousToolChangeWasManual = true;

  writeComment("Paused. Prepare to add new tool to collet. Pressing play will close collet");
  writeBlock(mFormat.format(27));
  writeBlock(mFormat.format(600));
  writeBlock("M490.1 (Close Collet)");

  var tloFloat = parseFloat(tloValue);

  if (tloValue == "M" || !isNaN(tloFloat)) {
    writeComment("Paused. Use the manual control interface to set the tool length.");
    writeComment("Pressing play will goto the clearance position, then continue the program.");
    writeBlock(mFormat.format(27));
    writeBlock(mFormat.format(600));
    writeBlock("G28 (Move To Clearance)");

  } else {
    writeComment("Paused. Pressing play will calibrate the tool length and continue the program");
    writeBlock(mFormat.format(27));
    writeBlock(mFormat.format(600));
    writeBlock("M493.2T1 (Set tool number to 1 so TLO can be set)");
    writeBlock("M491 (Calibrate Tool Length)");
  }
}

function writeJetCodes(mode) {
  if (currentSection.type == TYPE_JET && tool.type == TOOL_LASER_CUTTER) {
    writeBlock(mFormat.format(mode ? 3 : 5)); // activate/deactivate laser
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "P" + secFormat.format(seconds) + "(pause for "+ secFormat.format(seconds) +"seconds)");
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed), mFormat.format(tool.clockwise ? 3 : 4));
}

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
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    }
    writeBlock(gMotionModal.format(0), x, y, z, currentSection.type == TYPE_JET ? powerOutput.format(0) : "");
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
      writeBlock(gMotionModal.format(1), x, y, z, f, currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f, currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
    }
  }
}

function onPower(power) {
  powerOutput.reset();
}

function getPower() {
  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    return getProperty("laserPower");
  case JET_MODE_ETCHING:
    return getProperty("laserEtchPower");
  case JET_MODE_VAPORIZE:
  default:
    error(localize("Laser cutting mode is not supported."));
  }
  return 0;
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
        return settings.parametricFeeds.feedOutputVariable + (settings.parametricFeeds.firstFeedParameter + feedContext.id);
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
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine() ? aOutput.format(_a) : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine() ? bOutput.format(_b) : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine() ? cOutput.format(_c) : toolVectorOutputK.format(_c);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    feedOutput.reset();
  }
}
// <<<<< INCLUDED FROM include_files/onRapid5D_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onLinear5D_fanuc.cpi
function onLinear5D(_x, _y, _z, _a, _b, _c, feed, feedMode) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine() ? aOutput.format(_a) : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine() ? bOutput.format(_b) : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine() ? cOutput.format(_c) : toolVectorOutputK.format(_c);
  if (feedMode == FEED_INVERSE_TIME) {
    feedOutput.reset();
  }
  var f = feedMode == FEED_INVERSE_TIME ? inverseTimeOutput.format(feed) : getFeed(feed);
  var fMode = feedMode == FEED_INVERSE_TIME ? 93 : getProperty("useG95") ? 95 : 94;

  if (x || y || z || a || b || c) {
    writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), x, y, z, a, b, c, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
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
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
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
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), iOutput.format(cx - start.x), jOutput.format(cy - start.y), feedOutput.format(feed), currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
      break;
    case PLANE_ZX:
      forceCircular(getCircularPlane());
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), zOutput.format(z), iOutput.format(cx - start.x), kOutput.format(cz - start.z), feedOutput.format(feed), currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
      break;
    case PLANE_YZ:
      forceCircular(getCircularPlane());
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), yOutput.format(y), jOutput.format(cy - start.y), kOutput.format(cz - start.z), feedOutput.format(feed), currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      forceCircular(getCircularPlane());
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), jOutput.format(cy - start.y), feedOutput.format(feed), currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
      break;
    case PLANE_ZX:
      forceCircular(getCircularPlane());
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), kOutput.format(cz - start.z), feedOutput.format(feed), currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
      break;
    case PLANE_YZ:
      forceCircular(getCircularPlane());
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y), kOutput.format(cz - start.z), feedOutput.format(feed), currentSection.type == TYPE_JET ? powerOutput.format(power ? getPower() : 0) : "");
      break;
    default:
      linearize(tolerance);
    }
  }
}

// <<<<< INCLUDED FROM include_files/onCircular_fanuc.cpi
// >>>>> INCLUDED FROM include_files/workPlaneFunctions_fanuc.cpi
var gRotationModal = createOutputVariable({current : 69,
  onchange: function () {
    state.twpIsActive = gRotationModal.getCurrent() != 69;
    if (typeof probeVariables != "undefined") {
      probeVariables.outputRotationCodes = probeVariables.probeAngleMethod == "G68";
    }
    machineSimulation({}); // update machine simulation TWP state
  }}, gFormat);

var currentWorkPlaneABC = undefined;
function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

var mapCommand = {
  COMMAND_STOP                    : 0,
  COMMAND_END                     : 2,
  COMMAND_SPINDLE_CLOCKWISE       : 3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE: 4,
  COMMAND_STOP_SPINDLE            : 5
};

function onCommand(command) {
  switch (command) {
  case COMMAND_STOP:
    writeComment("Stop");
    writeBlock(mFormat.format(600));
    forceSpindleSpeed = true;
    forceCoolant = true;
    if (getProperty("defaultUseExternalControl")) {
      writeBlock(mFormat.format(400));
      
      writeBlock(mFormat.format(852));
    }
    return;
  case COMMAND_POWER_ON:
    return;
  case COMMAND_POWER_OFF:
    return;

  case COMMAND_BREAK_CONTROL:
    writeComment("Tool Break Test");
    writeBlock("M491.1");
    return;

  case COMMAND_STOP_SPINDLE:
    writeBlock(mFormat.format(5));
    forceSpindleSpeed = true;
    forceCoolant = true;
    if (getProperty("defaultUseExternalControl")) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(852));
    }
    return;
  case COMMAND_OPTIONAL_STOP:
    writeComment("Optional Stop Start");
    writeBlock(mFormat.format(1));
    forceSpindleSpeed = true;
    forceCoolant = true;
    if (getProperty("defaultUseExternalControl")) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(852));
    }
    writeComment("Optional Stop End");
    return;
  case COMMAND_START_SPINDLE:
    if (getProperty("defaultUseExternalControl")) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(851), pwmOutput.format(100));
    }
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
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
  if (!isLastSection() && (getNextSection().getTool().coolant != tool.coolant)) {
    setCoolant(COOLANT_OFF);
  }
  writeJetCodes(false);
  forceAny();
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  var retractAxes = new Array(false, false, false);
  validate(arguments.length != 0, "No axis specified for writeRetract().");

  for (i in arguments) {
    retractAxes[arguments[i]] = true;
  }

  safeYPosition = getProperty("yAxisSafePosition");

  if (retractAxes[0] && retractAxes[1] && retractAxes[2]) {
    if (getProperty("returnClearance")) {
      writeBlock(gFormat.format(28));
    }
  } else if (retractAxes[1] && retractAxes[2] && safeYPosition != 0) {
    gMotionModal.reset();
    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Y" + xyzFormat.format(toPreciseUnit(safeYPosition, MM)), "Z" + xyzFormat.format(toPreciseUnit(-3, MM)));
  } else if (retractAxes[0]) {
    gMotionModal.reset();
    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Z" + xyzFormat.format(toPreciseUnit(-3, MM)));
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
  if (tool.type == TOOL_PROBE) { // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode && (!forceCoolant || coolant == COOLANT_OFF)) {
    return undefined; // coolant is already active
  }
  if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolantOff != undefined) && !forceCoolant) {
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
  for (var c in coolants) { // find required coolant codes into the coolants array
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
    if (currentCoolantMode == COOLANT_AIR && getProperty("useExtForAirCoolant")) {
      currentCoolantMode = coolant;
      return [mFormat.format(400), mFormat.format(852)];
    }
  } else {
    coolantOff = coolantCodes.off;
    if (coolant == COOLANT_AIR && getProperty("useExtForAirCoolant")) {
      currentCoolantMode = coolant;
      return [mFormat.format(400), "M851S100"];
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
  if (laser_used){
    writeBlock("M322");
  }
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

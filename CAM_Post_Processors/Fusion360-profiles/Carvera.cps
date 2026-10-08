/**
  Copyright (C) 2012-2022 by Autodesk, Inc.
  All rights reserved.

  Grbl post processor configuration.

  $Revision: 43162 $
  $Date: 2026-10-06 00:00:00 $

  FORKID {D897E9AA-349A-4011-AA01-06B6CCC181EB}
*/

description = "Makera Carvera Community Probing Post v2.0.0";
longDescription = "The Carvera Community Post with Fusion WCS probing (stock and community firmware), Ext PWM appliances, actions, and per-operation probing and laser settings. Guide: Carvera_Probing_Post.md next to this file.";

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
//      Stop                   -pause and wait for input from the user
//      Optional Stop          -M1. Requires the community firmware
//      Comment                -write a comment into the file
//      Display Message        -pause with the message (M118 to the console on the community firmware)
//      Print Message          -the message as a comment (and M118 on the community firmware)
//      Call Program           -run a macro: a number N runs /sd/gcodes/macros/N.cnc (M98 PN),
//                              a name runs that file in /sd/gcodes/ (M98.1). Requires the community firmware
//      Measure Tool           -run a tool length offset calibration on the current tool (M491)
//      Tool Break Control     -run a tool break test. Requires the community firmware
//      Pass Through           -send the contents of the input box directly to the machine, unchecked


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
//     ResetFeedOverride    -resets the feed override value to 100%
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
//     EnableFlexComp       -Enables flex compensation (M380.3). Requires the community firmware
//     DisableFlexComp      -Disables flex compensation (M380). Requires the community firmware

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
// Post properties are shown in these numbered groups, in this order. Fusion's
// own "(Built-in)" properties follow in a group of their own.
groupDefinitions = {
  machine        : {title:"1. Machine and firmware", description:"The firmware on the machine, and settings that depend on it.", collapsed:false, order:1},
  toolChanges    : {title:"2. Tool changes", description:"How tool changes are written.", collapsed:false, order:2},
  externalControl: {title:"3. External control (Ext port)", description:"When the Ext port is switched on and off.", collapsed:false, order:3},
  probeSettings  : {title:"4. Probing", description:"Probe input, probe feeds and their warning, and what WCS probing writes.", collapsed:false, order:4},
  aAxis          : {title:"5. A axis (4th axis)", description:"A-axis rotation between setups, including the options for the free (personal use) version of Fusion.", collapsed:false, order:5},
  laser          : {title:"6. Laser", description:"Laser power.", collapsed:false, order:6},
  programOutput  : {title:"7. Program output", description:"What the file contains, how it ends, and how it is split.", collapsed:false, order:7},
  lineFormat     : {title:"8. Line format", description:"Word spacing and sequence numbers.", collapsed:false, order:8},
  actions        : {title:"9. Actions", description:"Actions at the start, at every tool change and at the end; before and after an operation. The same action names as Manual NC Action.", collapsed:false, order:9}
};

// What switches an Ext appliance with "Enable PWM-based Ext": nothing, the
// spindle, or one of Fusion's coolant modes (see extCoolantSwitches).
function extSwitchChoices() {
  return [
    {title:"Not connected", id:"none"},
    {title:"With the spindle", id:"spindle"},
    {title:"Coolant: Air", id:"air"},
    {title:"Coolant: Air through tool", id:"airThroughTool"},
    {title:"Coolant: Mist", id:"mist"},
    {title:"Coolant: Suction", id:"suction"},
    {title:"Coolant: Flood", id:"flood"},
    {title:"Coolant: Through tool", id:"throughTool"},
    {title:"Coolant: Flood and mist", id:"floodMist"},
    {title:"Coolant: Flood and through tool", id:"floodThroughTool"}
  ];
}

// The per-operation "Before / After this operation" choices: actions without a
// value, Pause (its message is the operation name), and machine macros 1 to 9.
function operationActionChoices() {
  var names = ["LightOn", "LightOff", "Pause", "SafeZ", "Clearance", "SpindleOff", "AirOn", "AirOff", "VacOn", "VacOff",
    "ExtOn", "ExtOff", "ExtOn:Air", "ExtOff:Air", "ExtOn:ShopVac", "ExtOff:ShopVac", "ExtOn:Mist", "ExtOff:Mist", "ExtOn:Other", "ExtOff:Other",
    "EnableFlexComp", "DisableFlexComp", "LoadAutoLevel", "ClearAutoLevel", "ResetFeedOverride"];
  var choices = [{title:"Nothing", id:"none"}];
  for (var i = 0; i < names.length; ++i) {
    choices.push({title:names[i], id:names[i]});
  }
  for (var i = 1; i <= 9; ++i) {
    choices.push({title:"Macro:" + i + " (machine macro " + i + ", community firmware only)", id:"Macro:" + i});
  }
  return choices;
}

// The per-operation laser power choices: Same as Post Process dialog, then
// 0% to 100% in 1% steps (the post writes the power to two decimals).
// Laser power in percent for the Post Process dialog; the value is the percentage.
// "Save results to variables, starting at": Don't save, or a first variable the post leaves
// free (the firmware's #101-#120 and #501-#520; the post uses #101-#111 and #120).
function resultVariableChoices() {
  var values = [{title:"Don't save", id:"off"}];
  for (var number = 112; number <= 119; ++number) {
    values.push({title:"#" + number + " (RAM)", id:String(number)});
  }
  for (number = 501; number <= 520; ++number) {
    values.push({title:"#" + number + " (EEPROM)", id:String(number)});
  }
  return values;
}

function laserPowerPercentChoices() {
  var values = [];
  for (var percent = 0; percent <= 100; ++percent) {
    values.push({title:percent + "%", id:String(percent)});
  }
  return values;
}

function laserPowerChoices() {
  var values = [{title:"Same as Post Process dialog", id:"post"}];
  for (var percent = 0; percent <= 100; ++percent) {
    values.push({title:percent + "%, for this operation", id:String(percent)});
  }
  return values;
}

properties = {
  firmwareType: {
    title      : "Carvera Machine Firmware Type",
    description: "Select the firmware type installed on your machine.",
    group      : "machine",
    type       : "enum",
    values     : [
      {title:"Stock Firmware", id:"stock"},
      {title:"Community Firmware", id:"community"}
    ],
    value      : "community",
    scope      : "post"
  },
  loadFlexComp: {
    title      : "Load/Enable X-Axis Flex Compensation (community firmware only)",
    description: "Load and enable X-Axis Flex Compensation (M380.3) at the start of the program. Community firmware only: the stock firmware has no M380, so nothing is written for it.",
    group      : "machine",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
    manualToolChangeBehavior: {
    title      : "Manual Tool Change Behavior",
    description: "If you are using community firmware, select the community firmware option. If you are using a stock machine, choose the relavent option. The Stock C1 with manual tool changes will add code to do manual tool changes on tool numbers greater than 6 or the tool is marked for manual change, with the option to set up manual tool changes when the shank size changes. The community firmware does this automatically",
    group      : "toolChanges",
    type       : "enum",
    values     : [
      {title:"Stock Air/Z1", id:"carvAirMtc"},
      {title:"Stock C1", id:"error6"},
      {title:"Stock C1 with Manual Tool Changes", id:"fusionMtc"},
      {title:"Carvera Community (community firmware only)", id:"carvcomMtc", description:"works on both the C1 and Air and allows the use of the collet changes and offset tool support."},
   
    ],
    value: "carvAirMtc",


    scope: "post"
  },
  issueColletChangeOnShankSizeChange: {
    title      : "Collet changes (community firmware only)",
    description: "Add the collet to use to tool change commands (e.g. M6 T1 S1, where \"S1\" is the collet change parameter). The stock firmware ignores it, so posting stops with an error for the stock firmware.",
    group      : "toolChanges",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useToolCommentForChangeParameters: {
    title      : "Tool change parameters from tool comment (community firmware only)",
    description: "Use the tool comment field to add parameters to the tool change command (e.g. M6 T1 X-12 R3, where \"X-12 R3\" is in the comment field). This allows the user to probe face mills. The stock firmware ignores them, so posting stops with an error for the stock firmware.",
    group      : "toolChanges",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  
  
  defaultUseExternalControl: {
    title      : "Spindle-based External Control",
    description: "Turn the external PWM control on/off when the spindle is turned on/off. Ignored when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "boolean",
    value: true,
    scope: "post"
  },
  useExtForAirCoolant: {
    title      : "Use Ext For Air Coolant",
    description: "Turn the external PWM control on/off when the air coolant is turned on/off. It replaces M7/M9, so the machine's own air valve is not switched. Ignored when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "boolean",
    value: false,
    scope: "post"
  },
  usePwmExt: {
    title      : "Enable PWM-based Ext",
    description: "Switch the Ext port with a PWM value for each appliance below. Each appliance is switched by a coolant mode or with the spindle; when several are on, the port gets the sum of their values, so a PWM decoder on the port can switch each one. The port is off during pauses and tool changes. When ticked, 'Spindle-based External Control' and 'Use Ext For Air Coolant' are ignored, and the program starts with M332.3 (the firmware's Auto Ext Out off).",
    group      : "externalControl",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  extAirSwitch: {
    title      : "Air: switched by",
    description: "When the Air appliance on the Ext port is on. A coolant mode: on in operations with that coolant. With the spindle: on while the spindle or laser runs. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "enum",
    values     : extSwitchChoices(),
    value      : "air",
    scope      : "post"
  },
  extAirDuty: {
    title      : "Air: PWM value (%)",
    description: "The PWM value (0 to 100%) the Air appliance adds to the Ext port while it is on. Without a decoder, use 100. With a decoder, keep each value low enough that the appliances that are on together add up to 100 or less; posting warns when they do not. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "integer",
    value      : 100,
    range      : [0, 100],
    scope      : "post"
  },
  extShopVacSwitch: {
    title      : "Shop vac: switched by",
    description: "When the Shop vac appliance on the Ext port is on. A coolant mode: on in operations with that coolant. With the spindle: on while the spindle or laser runs. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "enum",
    values     : extSwitchChoices(),
    value      : "suction",
    scope      : "post"
  },
  extShopVacDuty: {
    title      : "Shop vac: PWM value (%)",
    description: "The PWM value (0 to 100%) the Shop vac appliance adds to the Ext port while it is on. Without a decoder, use 100. With a decoder, keep each value low enough that the appliances that are on together add up to 100 or less; posting warns when they do not. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "integer",
    value      : 100,
    range      : [0, 100],
    scope      : "post"
  },
  extMistSwitch: {
    title      : "Mist: switched by",
    description: "When the Mist appliance on the Ext port is on. A coolant mode: on in operations with that coolant. With the spindle: on while the spindle or laser runs. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "enum",
    values     : extSwitchChoices(),
    value      : "mist",
    scope      : "post"
  },
  extMistDuty: {
    title      : "Mist: PWM value (%)",
    description: "The PWM value (0 to 100%) the Mist appliance adds to the Ext port while it is on. Without a decoder, use 100. With a decoder, keep each value low enough that the appliances that are on together add up to 100 or less; posting warns when they do not. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "integer",
    value      : 100,
    range      : [0, 100],
    scope      : "post"
  },
  extOtherSwitch: {
    title      : "Other: switched by",
    description: "When the Other appliance on the Ext port is on. A coolant mode: on in operations with that coolant. With the spindle: on while the spindle or laser runs. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "enum",
    values     : extSwitchChoices(),
    value      : "none",
    scope      : "post"
  },
  extOtherDuty: {
    title      : "Other: PWM value (%)",
    description: "The PWM value (0 to 100%) the Other appliance adds to the Ext port while it is on. Without a decoder, use 100. With a decoder, keep each value low enough that the appliances that are on together add up to 100 or less; posting warns when they do not. Used only when 'Enable PWM-based Ext' is ticked.",
    group      : "externalControl",
    type       : "integer",
    value      : 100,
    range      : [0, 100],
    scope      : "post"
  },
  probeSensorType: {
    title      : "Probe Sensor Type",
    description: "Stock firmware: set to NO (normally open) or NC (normally closed) to match the probe; a mismatch halts the machine at the first probe move. Community firmware: the post always probes with G38.2/G38.3; an NC probe is set up in the firmware configuration instead.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"NC (normally closed)", id:"NC"},
      {title:"NO (normally open)", id:"NO"}
    ],
    value      : "NO",
    scope      : "post"
  },
  probeTipDiameter: {
    title      : "Probe tip diameter",
    description: "The ball diameter subtracted from single-surface and corner probe results. Fusion tool diameter: the probe tool's diameter in Fusion. Machine calibration (#150): the diameter calibrated on the machine with M460/M460.1, read by the firmware when the program runs (community firmware only; calibrate first). Applies to every probing operation. One operation can change it on its Post Properties tab.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Fusion tool diameter", id:"tool"},
      {title:"Machine calibration (#150) (community firmware only)", id:"machine"}
    ],
    value      : "tool",
    scope      : "post"
  },
  probeTipDiameterOperation: {
    title      : "Probe tip diameter",
    description: "The ball diameter this operation subtracts from its result. Same as Post Process dialog: use the setting chosen when posting.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Same as Post Process dialog", id:"post"},
      {title:"Fusion tool diameter, for this operation", id:"tool"},
      {title:"Machine calibration (#150), for this operation (community firmware only)", id:"machine"}
    ],
    value      : "post",
    scope      : "operation",
    enabled    : "probing"
  },
  useFirmwareOCodes: {
    title      : "Use firmware O-codes (community firmware 2.2.0c or later)",
    description: "Lets probing operations act on Fusion's checks (operation Actions tab: Out of position, Wrong size, Angle askew, set to 'Stop and display message') and on Print results. A failed check shows a message and pauses (M600); abort the program in the Controller, or resume to carry on. Print results shows each measured value on the Controller console. Unticked, any of those settings stops posting, so none is ignored. Not for the stock firmware, which has no O-codes and would always pause.",
    group      : "probeSettings",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  probeCheckAction: {
    title      : "Failed probe check",
    description: "What a probing operation does when one of Fusion's checks fails (needs 'Use firmware O-codes'). Ignore and continue: the checks are left out, and the operation writes its result without stopping (Print results and saved results still work). Pause: show a message and pause; abort in the Controller, or resume to carry on. Pause, then probe again: show a message, raise Z, move to the park position and pause; fix the part, then resume and the operation probes again, up to 'Probe attempts' times. While paused, do not change the WCS, and leave the head high: resume moves straight back to the park position. Applies to every probing operation. One operation can change it on its Post Properties tab.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Ignore and continue", id:"ignore"},
      {title:"Pause", id:"pause"},
      {title:"Pause, then probe again", id:"reprobe"}
    ],
    value      : "ignore",
    scope      : "post"
  },
  probeCheckActionOperation: {
    title      : "Failed probe check",
    description: "What this operation does when one of its checks fails. Same as Post Process dialog: use the setting chosen when posting.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Same as Post Process dialog", id:"post"},
      {title:"Ignore and continue, for this operation", id:"ignore"},
      {title:"Pause, for this operation", id:"pause"},
      {title:"Pause, then probe again, for this operation", id:"reprobe"}
    ],
    value      : "post",
    scope      : "operation",
    enabled    : "probing"
  },
  probeCheckAttempts: {
    title      : "Probe attempts",
    description: "With 'Pause, then probe again': how many times an operation probes before its last pause, after which resuming carries on with the out-of-tolerance result.",
    group      : "probeSettings",
    type       : "integer",
    value      : 3,
    range      : [2, 9],
    scope      : "post"
  },
  probeParkPosition: {
    title      : "Park position",
    description: "Where the head waits during a 'Pause, then probe again' pause. Machine clearance position: G28, which on the Carvera goes to the clearance position in the machine's configuration (coordinate.clearance_x/y/z). Custom: raise Z to machine Z-3, then move to Park position X and Y.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Machine clearance position", id:"machine"},
      {title:"Custom", id:"custom"}
    ],
    value      : "machine",
    scope      : "post"
  },
  probeParkX: {
    title      : "Park position X (machine)",
    description: "With Park position 'Custom': the machine X the head moves to, after raising Z to machine Z-3. Carvera Air clearance position: X-5 Y-21; Carvera C1: X-75 Y-3.",
    group      : "probeSettings",
    type       : "number",
    value      : -5,
    range      : [-400, 0],
    scope      : "post"
  },
  probeParkY: {
    title      : "Park position Y (machine)",
    description: "With Park position 'Custom': the machine Y the head moves to. See Park position X.",
    group      : "probeSettings",
    type       : "number",
    value      : -21,
    range      : [-300, 0],
    scope      : "post"
  },
  probePrintPrefix: {
    title      : "Print results prefix",
    description: "Text put in front of each Print results line on the Controller console, for example RESULT. Empty: none.",
    group      : "probeSettings",
    type       : "string",
    value      : "",
    scope      : "post"
  },
  probeResultVariable: {
    title      : "Save results to variables, starting at",
    description: "Saves each value this operation measures, as its deviation from the model (measured minus model, mm or degrees), to machine variables starting at this number, one per value in the order Print results shows them. #112 to #119 (RAM): kept until the machine restarts. #501 to #520 (EEPROM): kept permanently, each one written to EEPROM. The community firmware's other variables are taken: #1 to #30 by subprograms, #101 to #111 and #120 by this post's probing. Don't save (default): nothing is saved. Community firmware only.",
    group      : "probeSettings",
    type       : "enum",
    values     : resultVariableChoices(),
    value      : "off",
    scope      : "operation",
    enabled    : "probing"
  },
  probeResult: {
    title      : "Probe result",
    description: "The coordinate the probed feature gets after probing. Modelled position (recommended): the feature keeps the coordinates it has in your Fusion model. Example: a boss drawn at X135 Y45 still reads X135 Y45 after probing, and the origin moves only by how far the real part is from the model. Every toolpath in the setup then still lines up with the part, and several probes (X from one face, Y from another, Z from the top) can set the same origin. Set feature to 0: the probed face, centre or corner becomes 0 (the boss centre reads X0 Y0), so the origin moves onto it. Use it only when the setup's origin in Fusion is that same feature, where both choices give the same result; otherwise toolpaths cut in the wrong place. This is what the Community Post always did. Applies to every probing operation. One operation can change it on its Post Properties tab.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Modelled position", id:"model"},
      {title:"Set feature to 0", id:"zero"}
    ],
    value      : "model",
    scope      : "post"
  },
  probeResultOperation: {
    title      : "Probe result",
    description: "The coordinate this operation's probed feature gets after probing. Modelled position: the coordinates it has in your Fusion model (recommended). Set feature to 0: the feature becomes 0, so the origin moves onto it; use it only when the setup's origin is that feature. Same as Post Process dialog: use the setting chosen when posting.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Same as Post Process dialog", id:"post"},
      {title:"Modelled position, for this operation", id:"model"},
      {title:"Set feature to 0, for this operation", id:"zero"}
    ],
    value      : "post",
    scope      : "operation",
    enabled    : "probing"
  },
  writeProbeResults: {
    title      : "Write probe results to WCS",
    description: "Write each WCS probing result to the WCS of the setup the operation belongs to. Off (default): the operation probes but changes no WCS (Print results, saved results and checks still work). Applies to every probing operation. One operation can change it on its Post Properties tab.",
    group      : "probeSettings",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  writeProbeResultsOperation: {
    title      : "Write probe results to WCS",
    description: "Whether this operation writes its probing result to the WCS of its setup. Same as Post Process dialog: use the setting chosen when posting.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Same as Post Process dialog", id:"post"},
      {title:"Yes, for this operation", id:"yes"},
      {title:"No, for this operation", id:"no"}
    ],
    value      : "post",
    scope      : "operation",
    enabled    : "probing"
  },
  probeFeeds: {
    title      : "Probe feeds",
    description: "The feeds probing operations move at, taken from the probe tool's feeds in Fusion. Slow: positioning moves at the slower of the Link and Lead-In feeds, the first touch at twice the Measure feed, the second touch at the Measure feed. Fusion's feeds: positioning moves at the Link feed, the first touch at the Lead-In feed, the second touch at the Measure feed. Applies to every probing operation. One operation can change it on its Post Properties tab.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Slow", id:"slow"},
      {title:"Fusion's feeds", id:"fusion"}
    ],
    value      : "slow",
    scope      : "post"
  },
  probeFeedsOperation: {
    title      : "Probe feeds",
    description: "The feeds this operation moves at. Same as Post Process dialog: use the setting chosen when posting.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Same as Post Process dialog", id:"post"},
      {title:"Slow, for this operation", id:"slow"},
      {title:"Fusion's feeds, for this operation", id:"fusion"}
    ],
    value      : "post",
    scope      : "operation",
    enabled    : "probing"
  },
  probeFeedWarningLimit: {
    title      : "Warn when probe moves are faster than (mm/min)",
    description: "Any probe positioning move or touch faster than this, with either Probe feeds setting, gives a warning when posting and a pause with a message on the machine. 100 to 2000 mm/min: the machine's top speed is 2000 (Z) to 3000 (X, Y), so a higher limit would never warn. Posting stops with an error outside this range.",
    group      : "probeSettings",
    type       : "number",
    value      : 1000,
    range      : [100, 2000],
    scope      : "post"
  },
  probeFeedWarningPause: {
    title      : "Pause for high-speed probe moves",
    description: "When the machine pauses with the high-speed probe move message. Once per file: one pause at the start of the program, covering every probing operation in it. Before each operation: a pause before every probing operation with probe moves faster than the warning limit. No pause: the machine does not pause or show the message. Posting always warns, whatever this setting.",
    group      : "probeSettings",
    type       : "enum",
    values     : [
      {title:"Once per file", id:"file"},
      {title:"Before each operation", id:"operation"},
      {title:"No pause", id:"none"}
    ],
    value      : "file",
    scope      : "post"
  },

  yAxisSafePosition: {
    title      : "Safe Y-axis position for A-axis rotation",
    description: "The Y-axis position to move to when performing a safe A-axis rotation. A value of 0 means that the Y-axis will not be moved during A-axis rotations. This setting can be left default for normal operation.",
    group      : "aAxis",
    type       : "integer",
    value      : -100,
    scope      : "post"
  },
  rotate4thAxisRelativeToModelPlane: {
    title      : "Automatic rotation of the 4th Axis",
    description: "If you are using the free version of fusion: Automatically rotates the 4th axis between consecutive setups. This means that the X-axis of the part has to be the rotation axis for the A axis. It will calculates the difference between consecutive model planes and automatically rotate the A axis accordingly between each setup. Setup 1 will be treated as the A-axis rotation of 0.",
    group      : "aAxis",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useManual4thAxisRotations: {
    title      : "Use Manual NC Code to rotate A axis",
    description: "If you are using the free version of fusion and the manual NC to set A axis rotations, set this to true. Note that it will no longer put a G0 A0 at the top of every operation so you have to define a axis rotations manually, it will not automatically rotate to zero at the start of the file",
    group      : "aAxis",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  laserPower: {
    title      : "Laser power",
    description: "The laser power for through cuts, in percent of full power. Applies to every laser operation. One operation can change it on its Post Properties tab.",
    group      : "laser",
    type       : "enum",
    values     : laserPowerPercentChoices(),
    value      : "100",
    scope      : "post"
  },
  laserPowerOperation: {
    title      : "Laser power",
    description: "The laser power for through cuts for this operation, in percent of full power. Same as Post Process dialog: use the setting chosen when posting.",
    group      : "laser",
    type       : "enum",
    values     : laserPowerChoices(),
    value      : "post",
    scope      : "operation",
    enabled    : "jet2d"
  },
  laserEtchPower: {
    title      : "Laser etch power",
    description: "The laser power for etching, in percent of full power. Applies to every laser operation. One operation can change it on its Post Properties tab.",
    group      : "laser",
    type       : "enum",
    values     : laserPowerPercentChoices(),
    value      : "10",
    scope      : "post"
  },
  laserEtchPowerOperation: {
    title      : "Laser etch power",
    description: "The laser power for etching for this operation, in percent of full power. Same as Post Process dialog: use the setting chosen when posting.",
    group      : "laser",
    type       : "enum",
    values     : laserPowerChoices(),
    value      : "post",
    scope      : "operation",
    enabled    : "jet2d"
  },
  writeMachine: {
    title      : "Write machine",
    description: "Output the machine settings in the header of the code.",
    group      : "programOutput",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  writeTools: {
    title      : "Write tool list",
    description: "Output a tool list in the header of the code.",
    group      : "programOutput",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  writeStock: {
    title      : "Write stock and origin",
    description: "Output machine-readable stock size and WCS origin placement in the header (after the tool list).",
    group      : "programOutput",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  returnClearance: {
    title      : "Return to Clearance",
    description: "Return to clearance position when the job is finished.",
    group      : "programOutput",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  splitFile: {
    title      : "Split file",
    description: "No splitting: one file. Split by tool: a new file at each tool change. Split by toolpath: a file per operation; each file starts with its tool change and the header (tool information and stock), so it can run on its own. Split by toolpath, no header: a file per operation with a tool change only when the tool changes.",
    group      : "programOutput",
    type       : "enum",
    values     : [
      {title:"No splitting", id:"none"},
      {title:"Split by tool", id:"tool"},
      {title:"Split by toolpath", id:"toolpath"},
      {title:"Split by toolpath, no header", id:"toolpathNoHeader"}
    ],
    value: "none",
    scope: "post"
  },
  separateWordsWithSpace: {
    title      : "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group      : "lineFormat",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  showSequenceNumbers: {
    title      : "Use sequence numbers",
    description: "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on the tool change (M6 and laser M321) blocks only, and 'No' disables the output of sequence numbers. Community firmware only: the stock firmware ignores numbered G, M, T and S lines, so posting stops with an error for the stock firmware unless this is 'No'.",
    group      : "lineFormat",
    type       : "enum",
    values     : [
      {title:"Yes (community firmware only)", id:"true"},
      {title:"No", id:"false"},
      {title:"Only on tool change (community firmware only)", id:"toolChange"}
    ],
    value      : "false",
    scope      : "post"
  },
  sequenceNumberStart: {
    title      : "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group      : "lineFormat",
    type       : "integer",
    value      : 10,
    scope      : "post"
  },
  sequenceNumberIncrement: {
    title      : "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group      : "lineFormat",
    type       : "integer",
    value      : 1,
    scope      : "post"
  },
  actionsAtStart: {
    title      : "Actions at start",
    description: "Actions written at the start of the program (of each file when the file is split). Separate actions with ';', for example: LightOn; Message:Clamps checked?. The same names as Manual NC Action; an unknown action stops posting.",
    group      : "actions",
    type       : "string",
    value      : "",
    scope      : "post"
  },
  actionsBeforeToolChange: {
    title      : "Actions before every tool change",
    description: "Actions written before every tool change (the first one too), after the coolant is switched off and before M6. Separate actions with ';'. The same names as Manual NC Action.",
    group      : "actions",
    type       : "string",
    value      : "",
    scope      : "post"
  },
  actionsAtToolChange: {
    title      : "Actions after every tool change",
    description: "Actions written after every tool change, before the spindle starts. Separate actions with ';'. The same names as Manual NC Action.",
    group      : "actions",
    type       : "string",
    value      : "",
    scope      : "post"
  },
  actionsAtEnd: {
    title      : "Actions at end",
    description: "Actions written at the end of the program (of each file when the file is split), after the spindle stops and the machine retracts, before M30. Separate actions with ';'. The same names as Manual NC Action.",
    group      : "actions",
    type       : "string",
    value      : "",
    scope      : "post"
  },
  actionBeforeOperation: {
    title      : "Before this operation",
    description: "An action written before this operation: after any tool change, before the spindle starts. Pause shows the operation name. More actions: put them in the operation name in square brackets, for example Pocket1 [LightOn] [Pause:Check clamps].",
    group      : "actions",
    type       : "enum",
    values     : operationActionChoices(),
    value      : "none",
    scope      : "operation"
  },
  actionAfterOperation: {
    title      : "After this operation",
    description: "An action written at the end of this operation. Pause shows the operation name.",
    group      : "actions",
    type       : "enum",
    values     : operationActionChoices(),
    value      : "none",
    scope      : "operation"
  }
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  // @TODO: Fusion does not accept decimals, i.e. 59.1-3, which are the temporary WCS values (not stored in the machine and not persisted across reboots/restarts
  wcs          : [
    {name:"Standard", format:"G", range:[54, 59]}
  ]
};

var numberOfToolSlots = 999999;
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
  {id:COOLANT_AIR_THROUGH_TOOL, on: "M811 S100", off: "M812"}, // spindle fan 100% for z1
  {id:COOLANT_SUCTION},
  {id:COOLANT_FLOOD_MIST},
  {id:COOLANT_FLOOD_THROUGH_TOOL},
  {id:COOLANT_OFF, off:[400,9]}
];

var gFormat = createFormat({prefix:"G", decimals:1});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var feedFormat = createFormat({decimals:0});
var inverseTimeFormat = createFormat({decimals:3, forceDecimal:true});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var powerFormat = createFormat({decimals:2});
var pwmFormat = createFormat({decimals:0, maximum:100, minimum:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000
var taperFormat = createFormat({decimals:1, scale:DEG});
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

var toolVectorOutputI = createVariable({prefix:"I"}, xyzFormat);
var toolVectorOutputJ = createVariable({prefix:"J"}, xyzFormat);
var toolVectorOutputK = createVariable({prefix:"K"}, xyzFormat);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G93-94
var gUnitModal = createOutputVariable({}, gFormat); // modal group 6 // G20-21

var fourthAxisRotationPreviousLocation = undefined;

// collected state
var forceSpindleSpeed = false;
var currentWorkOffset;
var retracted = false; // specifies that the tool has been retracted to the safe plane
// Both firmwares discard a file line longer than 128 characters with only a
// console warning (Player.cpp: "lines up to 128 characters are allowed").
var maximumLineLength = 128;
var checkLineLength = true;

/**
  Writes the specified block.
*/
// The next N number; set in onOpen from the sequence number properties.
var sequenceNumber;

function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  var numbered = getProperty("showSequenceNumbers") == "true";
  var line = (numbered ? "N" + sequenceNumber + " " : "") + text;
  if (checkLineLength && line.length > maximumLineLength) {
    error(localize("This line is longer than " + maximumLineLength + " characters. The firmware skips such lines without stopping, so posting stops: ") + line);
    return;
  }

  if (numbered) {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    writeWords(arguments);
  }
}

function formatComment(text) {
  return "(" + String(text).replace(/[()]/g, "") + ")";
}

/** Standard collet diameters in mm (order: 6.35 before 6 to match correctly). Map to S1-S6; do not change S numbering. */
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
  Returns S1-S6 parameter for tool change when shank diameter changed.
  DO NOT CHANGE THIS NUMBERING (firmware M6 S): S1=3mm, S2=3.175mm, S3=4mm, S4=6mm, S5=6.35mm, S6=8mm.
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

// Names the post that made the file. The "Machine" header comes from the Fusion
// machine definition, so it cannot tell which post ran. onOpen declares its own
// local "description", so this has to live outside onOpen.
function writePostIdentity() {
  writeComment("Post: " + description);
}

/** AllowCustomCodeToBeWritten -Fae*/
function onPassThrough(text) {
  checkLineLength = false; // Pass-through text is written as typed, unchecked
  writeBlock(text);
  checkLineLength = true;
}

/** Custom Actions -Fae*/
function onParameter(name, value) {
  var invalid = false;
  if (name == "display") { // Manual NC Display message
    writeOperatorMessage(String(value), true);
    return;
  }
  if (String(name).toLowerCase() == "print") { // Manual NC Print message
    writeOperatorMessage(String(value), false);
    return;
  }
  if (name == "call-subprogram") { // Manual NC Call program
    writeCallProgram(String(value));
    return;
  }
  if (name == "action") {
    if (writeNewAction(String(value))) {
      return;
    }
    if (value == "pierce"){
      return;//nothing special happens
    }
    if (String(value).toUpperCase() == "SPINDLEOFF"){
      writeBlock("M5 (Spindle Off)")
      forceSpindleSpeed = true; // the next operation starts the spindle again
      spindleRunning = false;
      updateExt();
    } else if (String(value).toUpperCase() == "CLEARANCE"){
      writeBlock("G28 (Go to clearance)")
      forceXYZ();
      gMotionModal.reset();
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
      if (currentCoolantMode == COOLANT_AIR) {
        currentCoolantMode = COOLANT_OFF; // so the next operation with air coolant writes M7 again
      }
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
      extDuty = 100;
    } else if (String(value).toUpperCase() == "EXTOFF"){
      writeBlock(mFormat.format(400));
      writeBlock("M852 (External Control Off)")
      extDuty = 0;
    } else if (String(value).toUpperCase() == "SHRINKA"){
      writeBlock("G92.4 A0 S0 (shrink the a axis so A365 becomes A5)")
    } else if (String(value).toUpperCase() == "SAFEZ"){
      writeBlock("G53 G0 Z -2. (Goto Safe Height In Z)")
      forceXYZ();
      gMotionModal.reset();
    } else if ((String(value).toUpperCase() == "ENABLEFLEXCOMP" || String(value).toUpperCase() == "DISABLEFLEXCOMP") &&
      getProperty("firmwareType") != "community") {
      warning(localize("Flex compensation (" + value + ") needs the community firmware. The stock firmware has no M380, so nothing is written."));
    } else if (String(value).toUpperCase() == "ENABLEFLEXCOMP") {
      writeBlock("M380.3 (Enable Flex Compensation)");
    } else if (String(value).toUpperCase() == "DISABLEFLEXCOMP") {
      writeBlock("M380 (Disable Flex Compensation)");
    } else {
      var sText1 = String(value);
      var sText2 = new Array();
      sText2 = sText1.split(":");
      if (sText2.length == 2) {
        if (sText2[0].toUpperCase() == "RAPIDA") {
          if (sText2[1].match(/^-?\d+$/)){
            writeBlock("G0A"+sText2[1] + "(Rapid movement on a axis)")
            forceABC();
            gMotionModal.reset();
          } else{
            invalid = true;
          }

        } else if (sText2[0].toUpperCase() == "SAFERA") {
          if (sText2[1].match(/^-?\d+$/)){
            writeBlock("G53 G0 Z -2. (Goto Safe Height In Z)")
            gMotionModal.reset();
            var safeYPosition = getProperty("yAxisSafePosition");
            if (safeYPosition != 0) { // 0: Y is not moved (the property's description)
              writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Y" + xyzFormat.format(toPreciseUnit(safeYPosition, MM)), "Z" + xyzFormat.format(toPreciseUnit(-3, MM)));
            }
            writeBlock("G0A"+sText2[1] + "(Rapid movement on a axis)")
            forceXYZ();
            forceABC();
            gMotionModal.reset();
          } else{
            invalid = true;
          }
        } else if (sText2[0].toUpperCase() == "FEEDOVERRIDE") {
          if (sText2[1].match(/^-?\d+$/)){
            // The firmware skips lines over 128 characters, so the comment stays short.
            writeBlock("M220 S"+sText2[1] + "(Feed override "+ sText2[1] +" percent until M220 S100 or a restart)");
          } else{
            invalid = true;
          }
        } else {
          invalid = true;
        }



      } else {
        invalid = true;
      }

    }
    if (invalid) {
      error(localize("Invalid action \"" + value + "\". " + validActions));
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
  writeln(""); // empty line
  writeComment("Tool Information:");
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
  writeln(""); // empty line
}

/**
  Machine-readable stock / origin header records.

  Examples:
  (@F360|STOCK|id=box|width=150|depth=100|height=10)
  (@F360|STOCK|id=cylinder|width=70|depth=70|height=50|diameter=70)
  (@F360|ORIGIN|type_name=topFrontLeft|x=-75|y=-50|z=5)

  STOCK:
    - id: Fusion stock-type (box, cylinder, or tube)
    - width/depth/height: WCS X/Y/Z extents (Fusion Width/Depth/Height)
    - diameter: outer diameter for cylinder/tube (Fusion stock-diameter, else inferred)
    - omitted when Fusion stock-type is missing or not box/cylinder/tube (e.g. from-solid)

  ORIGIN:
    - type_name: Fusion stock-box point (27 points) when the origin sits on that grid (or "custom"), ex: topFrontLeft, bottomBackRight
    - x/y/z: WCS origin relative to the stock center
*/
function isValidStockBox(box) {
  if (!box || (box.lower == undefined) || (box.upper == undefined)) {
    return false;
  }
  var dx = box.upper.x - box.lower.x;
  var dy = box.upper.y - box.lower.y;
  var dz = box.upper.z - box.lower.z;
  if (typeof dx != "number" || typeof dy != "number" || typeof dz != "number") {
    return false;
  }
  if (isNaN(dx) || isNaN(dy) || isNaN(dz)) {
    return false;
  }
  return (dx > 0) && (dy > 0) && (dz > 0);
}

function getStockBoundingBox() {
  var box;
  if (typeof getWorkpiece == "function") {
    try {
      box = getWorkpiece();
    } catch (e) {
      box = undefined;
    }
    if (isValidStockBox(box)) {
      return box;
    }
  }

  if ((typeof hasGlobalParameter == "function") &&
      hasGlobalParameter("stock-lower-x") && hasGlobalParameter("stock-upper-x") &&
      hasGlobalParameter("stock-lower-y") && hasGlobalParameter("stock-upper-y") &&
      hasGlobalParameter("stock-lower-z") && hasGlobalParameter("stock-upper-z")) {
    box = new BoundingBox(
      new Vector(
        getGlobalParameter("stock-lower-x"),
        getGlobalParameter("stock-lower-y"),
        getGlobalParameter("stock-lower-z")
      ),
      new Vector(
        getGlobalParameter("stock-upper-x"),
        getGlobalParameter("stock-upper-y"),
        getGlobalParameter("stock-upper-z")
      )
    );
    if (isValidStockBox(box)) {
      return box;
    }
  }

  if (getNumberOfSections() > 0) {
    var section = getSection(0);
    var xLow = section.getParameter("operation:stockXLow", NaN);
    var xHigh = section.getParameter("operation:stockXHigh", NaN);
    var yLow = section.getParameter("operation:stockYLow", NaN);
    var yHigh = section.getParameter("operation:stockYHigh", NaN);
    var zLow = section.getParameter("operation:stockZLow", NaN);
    var zHigh = section.getParameter("operation:stockZHigh", NaN);
    if (!isNaN(xLow) && !isNaN(xHigh) && !isNaN(yLow) && !isNaN(yHigh) && !isNaN(zLow) && !isNaN(zHigh)) {
      box = new BoundingBox(new Vector(xLow, yLow, zLow), new Vector(xHigh, yHigh, zHigh));
      if (isValidStockBox(box)) {
        return box;
      }
    }
  }

  return undefined;
}

function getFusionStockType() {
  if ((typeof hasGlobalParameter == "function") && hasGlobalParameter("stock-type")) {
    return String(getGlobalParameter("stock-type")).toLowerCase();
  }
  return "";
}

function stockIdFromFusionType(fusionType) {
  if ((fusionType == "box") || (fusionType == "cylinder") || (fusionType == "tube")) {
    return fusionType;
  }
  return undefined;
}

function getPositiveGlobalNumber(name) {
  if ((typeof hasGlobalParameter != "function") || !hasGlobalParameter(name)) {
    return undefined;
  }
  var value = Number(getGlobalParameter(name));
  if ((typeof value != "number") || isNaN(value) || !(value > 0)) {
    return undefined;
  }
  return value;
}

function inferRadialDiameter(width, depth, height) {
  var xy = Math.abs(width - depth);
  var xz = Math.abs(width - height);
  var yz = Math.abs(depth - height);
  if ((xy <= xz) && (xy <= yz)) {
    return (width + depth) / 2;
  }
  if (xz <= yz) {
    return (width + height) / 2;
  }
  return (depth + height) / 2;
}

function getStockDiameter(width, depth, height) {
  var diameter = getPositiveGlobalNumber("stock-diameter");
  if (diameter != undefined) {
    return diameter;
  }
  return inferRadialDiameter(width, depth, height);
}

function classifyOriginSide(originFromCenter, halfSize, tolerance) {
  if (!(halfSize > 0)) {
    return (Math.abs(originFromCenter) <= tolerance) ? 0 : undefined;
  }
  var sides = [-1, 0, 1];
  var positions = [-halfSize, 0, halfSize];
  var bestSide = 0;
  var bestDist = Math.abs(originFromCenter - positions[1]);
  var i;
  for (i = 0; i < sides.length; ++i) {
    var dist = Math.abs(originFromCenter - positions[i]);
    if (dist < bestDist) {
      bestDist = dist;
      bestSide = sides[i];
    }
  }
  return (bestDist <= tolerance) ? bestSide : undefined;
}

function originTypeName(xSide, ySide, zSide) {
  if ((xSide == undefined) || (ySide == undefined) || (zSide == undefined)) {
    return "custom";
  }
  var parts = [];
  if (zSide < 0) {
    parts.push("bottom");
  } else if (zSide > 0) {
    parts.push("top");
  }
  if (ySide < 0) {
    parts.push("front");
  } else if (ySide > 0) {
    parts.push("back");
  }
  if (xSide < 0) {
    parts.push("left");
  } else if (xSide > 0) {
    parts.push("right");
  }
  if (parts.length == 0) {
    return "center";
  }
  var name = parts[0];
  var i;
  for (i = 1; i < parts.length; ++i) {
    name += parts[i].charAt(0).toUpperCase() + parts[i].substring(1);
  }
  if (parts.length == 1) {
    name += "Center";
  }
  return name;
}

function dumpStockInformation() {
  var stockId = stockIdFromFusionType(getFusionStockType());
  if (!stockId) {
    return;
  }

  var box = getStockBoundingBox();
  if (!isValidStockBox(box)) {
    return;
  }

  var width = box.upper.x - box.lower.x;
  var depth = box.upper.y - box.lower.y;
  var height = box.upper.z - box.lower.z;
  var originX = -((box.lower.x + box.upper.x) / 2);
  var originY = -((box.lower.y + box.upper.y) / 2);
  var originZ = -((box.lower.z + box.upper.z) / 2);
  var stockParts = [
    "@F360",
    "STOCK",
    "id=" + stockId,
    "width=" + xyzFormat.format(width),
    "depth=" + xyzFormat.format(depth),
    "height=" + xyzFormat.format(height)
  ];
  if ((stockId == "cylinder") || (stockId == "tube")) {
    stockParts.push("diameter=" + xyzFormat.format(getStockDiameter(width, depth, height)));
  }
  writeComment(stockParts.join("|"));

  var halfX = width / 2;
  var halfY = depth / 2;
  var halfZ = height / 2;
  var tol = Math.max(spatial(0.05, MM), 0.002 * Math.max(width, depth, height));
  var xSide = classifyOriginSide(originX, halfX, tol);
  var ySide = classifyOriginSide(originY, halfY, tol);
  var zSide = classifyOriginSide(originZ, halfZ, tol);
  var typeName = originTypeName(xSide, ySide, zSide);
  var originParts = [
    "@F360",
    "ORIGIN",
    "type_name=" + typeName,
    "x=" + xyzFormat.format(originX),
    "y=" + xyzFormat.format(originY),
    "z=" + xyzFormat.format(originZ)
  ];
  writeComment(originParts.join("|"));
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

  sequenceNumber = getProperty("sequenceNumberStart");

  // Sequence numbers: the stock firmware ignores a numbered G, M, T or S line,
  // so none may be used. The community firmware drops a numbered line that
  // has axis words but no G word, so every motion block carries its G word.
  if (getProperty("showSequenceNumbers") != "false") {
    if (getProperty("firmwareType") != "community") {
      error(localize("Sequence numbers are not supported by the stock firmware, which ignores numbered G, M, T and S lines. Set 'Use sequence numbers' to 'No'."));
      return;
    }
    if (getProperty("showSequenceNumbers") == "true") {
      gMotionModal.setControl(CONTROL_FORCE);
    }
  }

  // Tool change settings the stock firmware cannot carry out: its M6 reads only T.
  if (getProperty("firmwareType") != "community") {
    var communityOnly = [];
    if (getProperty("manualToolChangeBehavior") == "carvcomMtc") {
      communityOnly.push("'Manual Tool Change Behavior' is 'Carvera Community'");
    }
    if (getProperty("issueColletChangeOnShankSizeChange")) {
      communityOnly.push("'Collet changes' is ticked");
    }
    if (getProperty("useToolCommentForChangeParameters")) {
      communityOnly.push("'Tool change parameters from tool comment' is ticked");
    }
    if (communityOnly.length > 0) {
      error(localize("The stock firmware ignores everything but T in a tool change (M6), but " + communityOnly.join(", and ") + ". Change these, or set 'Carvera Machine Firmware Type' to 'Community Firmware'."));
      return;
    }
  } else if ({carvAirMtc: 1, error6: 1, fusionMtc: 1}[getProperty("manualToolChangeBehavior")]) {
    // D2 (F-9): the user chose a posting warning, not an error or a new default.
    var stockChoices = {carvAirMtc: "Stock Air/Z1", error6: "Stock C1", fusionMtc: "Stock C1 with Manual Tool Changes"};
    warning(localize("'Carvera Machine Firmware Type' is 'Community Firmware' but 'Manual Tool Change Behavior' is '" +
      stockChoices[getProperty("manualToolChangeBehavior")] + "', a stock firmware option. The tool comment's TLO setting (A, M or a number) is then not written" +
      {carvAirMtc: "", error6: ", and a tool above 6 stops posting", fusionMtc: ", and a tool above 6 gets a comment instead of M6"}[getProperty("manualToolChangeBehavior")] +
      ". Set it to 'Carvera Community (community firmware only)' unless you mean to."));
  }

  if (programName) {
    writeComment("Program Name: " + programName);
  }
  if (programComment) {
    writeComment("Program Comment: " + programComment);
  }
  writePostIdentity();

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

  if (getProperty("writeStock")) {
    dumpStockInformation();
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

  warnFastProbeMoves();
  if (getProperty("usePwmExt")) {
    checkPwmExt();
  }
  if (getProperty("useFirmwareOCodes") && getProperty("firmwareType") != "community") {
    error(localize("'Use firmware O-codes' needs the community firmware 2.2.0c or later. The stock firmware ignores O-code lines, so every check would pause. Untick it, or set the firmware to community."));
    return;
  }
  checkActionConflicts(getSettingActions("actionsAtStart", "Actions at start"), "Actions at start");
  checkActionConflicts(getSettingActions("actionsBeforeToolChange", "Actions before every tool change"), "Actions before every tool change");
  checkActionConflicts(getSettingActions("actionsAtToolChange", "Actions after every tool change"), "Actions after every tool change");
  checkActionConflicts(getSettingActions("actionsAtEnd", "Actions at end"), "Actions at end");

  if (getProperty("splitFile") != "none") {
    writeComment(localize("***THIS FILE DOES NOT CONTAIN NC CODE***"));
    return;
  }

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94));
  writeBlock(gPlaneModal.format(17));

  // The stock firmware has no M380 (it answers "ok" and does nothing).
  if (getProperty("loadFlexComp") != false && getProperty("firmwareType") == "community") {
    writeBlock("M380.3 (Enable Flex Compensation)");
  }
  if (getProperty("usePwmExt")) {
    writeBlock("M332.3 (Auto Ext Out off: the post switches Ext)");
  }
  writeActions(getSettingActions("actionsAtStart", "Actions at start"));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }

  if (getProperty("probeFeedWarningPause") == "file") {
    writeFileProbePause(0, getNumberOfSections() - 1);
  }
}

// Warn when posting if any probing operation moves the probe faster than the
// warning limit, whatever the "Probe feeds" and pause settings. No setting
// turns this warning off.
function warnFastProbeMoves() {
  // Above the machine's top speed no probe move could count as fast, which would
  // switch the warning off (decision 0007). Fusion's range is not relied on.
  var limit = getProperty("probeFeedWarningLimit");
  if (!(limit >= 100 && limit <= 2000)) {
    error(localize("'Warn when probe moves are faster than (mm/min)' must be 100 to 2000 mm/min. It is " + limit + "."));
    return;
  }
  var operations = [];
  var fastest = 0;
  for (var i = 0; i < getNumberOfSections(); ++i) {
    if (isFastProbeSection(getSection(i))) {
      operations.push(getSectionComment(getSection(i)));
      fastest = Math.max(fastest, getFastestProbeFeed(getSection(i)));
    }
  }
  if (operations.length > 0) {
    warning(localize("High-speed probe moves") + ": " + operations.length + " " + localize("probing operation(s) move the probe at up to") + " " + feedFormat.format(fastest) + " mm/min, " +
      localize("faster than the warning limit of") + " " + feedFormat.format(getProperty("probeFeedWarningLimit")) + " mm/min: " + operations.join(", ") + ". " +
      {file:localize("The program pauses once, at its start, with a message."),
        operation:localize("The program pauses with a message before each of them."),
        none:localize("The program does not pause: Pause for high-speed probe moves is set to No pause.")}[getProperty("probeFeedWarningPause")]);
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

// The value of a setting that applies to every operation and can be changed for
// one operation (decision 0008): <name> in the Post Process dialog, and the
// drop-down <name>Operation on the operation's Post Properties tab, which wins
// unless it is "Same as Post Process dialog". "yes" and "no" are true and false.
// With a section, the value for that section (for scans in onOpen, guide p.122);
// without, the value for the operation being posted.
function getOperationSetting(name, section) {
  var value = section ? section.getProperty(name + "Operation") : getProperty(name + "Operation");
  if (value === undefined || value == "post") {
    return getProperty(name);
  }
  return value == "yes" ? true : (value == "no" ? false : value);
}

function isProbeOperation() {
  return hasParameter("operation-strategy") &&
    (getParameter("operation-strategy") == "probe");
}

function isProbeSection(section) {
  return section.hasParameter("operation-strategy") &&
    (section.getParameter("operation-strategy") == "probe");
}

// The feeds a probing section moves at, set by the "Probe feeds" property from
// the probe tool's Link, Lead-In and Measure feeds in Fusion.
function getProbeFeeds(section) {
  var feed = function (name) {
    return section.hasParameter(name) ? section.getParameter(name) : undefined;
  };
  var link = feed("operation:tool_feedProbeLink");
  var entry = feed("operation:tool_feedEntry");
  var measure = feed("operation:tool_feedProbeMeasure");
  if (getOperationSetting("probeFeeds", section) == "fusion") {
    // Fusion: "the first touch is at the Lead-In Feedrate and the second touch
    // is at the Measure Feedrate."
    return {positioning:link || entry, firstTouch:entry || measure * 2, secondTouch:measure};
  }
  return {positioning:(link && entry) ? Math.min(link, entry) : (link || entry), firstTouch:measure * 2, secondTouch:measure};
}

// The fastest probe positioning move or touch of a section in mm/min, or 0 when
// it is not a probing section.
function getFastestProbeFeed(section) {
  if (!isProbeSection(section)) {
    return 0;
  }
  var feeds = getProbeFeeds(section);
  var fastest = 0;
  var all = [feeds.positioning, feeds.firstTouch, feeds.secondTouch];
  for (var i = 0; i < all.length; ++i) {
    if (typeof all[i] == "number" && all[i] > fastest) {
      fastest = all[i];
    }
  }
  return unit == MM ? fastest : fastest * 25.4;
}

function isFastProbeSection(section) {
  return getFastestProbeFeed(section) > getProperty("probeFeedWarningLimit");
}

function getSectionComment(section) {
  return section.hasParameter("operation-comment") ? section.getParameter("operation-comment") : "operation " + (section.getId() + 1);
}

// Pause on the machine with a message about high-speed probe moves. The message
// must not contain ";" or "(", which start a comment on the machine. With no
// operation, the pause covers the whole file and is the only one in it.
function writeFastProbePause(fastest, operation) {
  var speeds = "up to " + feedFormat.format(fastest) + " mm/min, faster than the warning limit of " + feedFormat.format(getProperty("probeFeedWarningLimit")) + " mm/min";
  var message;
  writeComment("WARNING: HIGH-SPEED PROBE MOVES");
  if (operation) {
    writeComment("Probing operation " + operation + " moves the probe at " + speeds + ".");
    message = "High-speed probe moves in " + operation + ": " + speeds + ". Press resume to continue.";
  } else {
    writeComment("This file moves the probe at " + speeds + ".");
    writeComment("More than one probing operation in this file may have high-speed probe moves. This message is not shown again.");
    message = "High-speed probe moves: " + speeds + ". This file may contain more than one high-speed probing operation. This message is not shown again. Press resume to continue.";
  }
  writeComment("Paused. Check the probe and the part. Pressing play continues the program.");
  writeConsoleMessage(message);
  writeBlock(mFormat.format(600));
}

// M118 prints the message in the controller's console. The stock firmware has
// no M118 (and neither firmware shows M117), so there the comments are the
// message. A long message is split over several M118 lines, because the
// firmware skips lines over 128 characters.
function writeConsoleMessage(message) {
  if (getProperty("firmwareType") != "community") {
    return;
  }
  var words = String(message).replace(/[;()]/g, "").split(" ");
  var line = "";
  for (var i = 0; i < words.length; ++i) {
    if (line && (line + " " + words[i]).length > 100) {
      writeBlock("M118 " + line);
      line = "";
    }
    line = line ? line + " " + words[i] : words[i];
  }
  if (line) {
    writeBlock("M118 " + line);
  }
}

// Manual NC Display message (pause) and Print message (no pause).
function writeOperatorMessage(message, pause) {
  writeComment(message);
  writeConsoleMessage(message);
  if (pause) {
    writeStop();
  }
}

// M600 pause. With spindle-based External Control, Ext is switched off before
// the pause: the firmware stops the spindle while paused, but not Ext. The next
// operation starts the spindle, and so Ext, again.
function writeStop() {
  if (useSpindleExt()) {
    writeBlock(mFormat.format(400));
    writeBlock(mFormat.format(852));
  }
  spindleRunning = false;
  setExtDuty(0);
  writeBlock(mFormat.format(600));
  forceSpindleSpeed = true;
  forceCoolant = true;
}

// Manual NC Call program: a number N runs /sd/gcodes/macros/N.cnc (M98 PN),
// any other name runs that file in /sd/gcodes/ (M98.1). Community firmware only.
function writeCallProgram(program) {
  program = program.replace(/^\s+|\s+$/g, "");
  if (getProperty("firmwareType") != "community") {
    warning(localize("Call program \"" + program + "\" needs the community firmware (M98). The stock firmware has no M98, so nothing is written."));
    return;
  }
  if (!program || program.indexOf("\"") >= 0) {
    error(localize("Call program \"" + program + "\": enter a macro number, or a file name in /sd/gcodes/ without quotes."));
    return;
  }
  writeComment("Call program " + program);
  if (/^\d+$/.test(program) && parseInt(program, 10) > 0) {
    writeBlock(mFormat.format(98), "P" + parseInt(program, 10));
  } else {
    writeBlock("M98.1 \"" + program + "\"");
  }
}

// Actions (decision 0009 F6). One set of names for Manual NC Action, the
// "Actions at ..." settings, the "Before / After this operation" drop-downs and
// [tags] in operation names. Unknown or malformed actions stop posting.
var validActions = "Valid actions: SpindleOff, Clearance, ClearAutoLevel, LoadAutoLevel, ResetFeedOverride, AirOn, AirOff, VacOn, VacOff, AutoVacOn, AutoVacOff, LightOn, LightOff, ExtOn, ExtOff, ShrinkA, SafeZ, EnableFlexComp, DisableFlexComp, Pause, Pause:<message>, Message:<text>, Macro:<number or file name>, ExtOn:<appliance>, ExtOff:<appliance>, ExtAuto:<appliance>, RapidA:<degrees>, SaferA:<degrees>, FeedOverride:<percent>. Degrees and percent are whole numbers; appliances are Air, ShopVac, Mist, Other.";
var plainActions = ["PIERCE", "SPINDLEOFF", "CLEARANCE", "CLEARAUTOLEVEL", "LOADAUTOLEVEL", "RESETFEEDOVERRIDE", "AIRON", "AIROFF", "VACON", "VACOFF",
  "AUTOVACON", "AUTOVACOFF", "LIGHTON", "LIGHTOFF", "EXTON", "EXTOFF", "SHRINKA", "SAFEZ", "ENABLEFLEXCOMP", "DISABLEFLEXCOMP", "PAUSE"];

/** Returns {key, arg} (key in capitals), or undefined when the text is not a valid action. */
function parseAction(text) {
  text = String(text).replace(/^\s+|\s+$/g, "");
  var colon = text.indexOf(":");
  var key = (colon < 0 ? text : text.substr(0, colon)).replace(/\s+$/, "").toUpperCase();
  if (colon < 0) {
    return plainActions.indexOf(key) >= 0 ? {key:key} : undefined;
  }
  var arg = text.substr(colon + 1).replace(/^\s+|\s+$/g, "");
  switch (key) {
  case "RAPIDA":
  case "SAFERA":
  case "FEEDOVERRIDE":
    return /^-?\d+$/.test(arg) ? {key:key, arg:arg} : undefined;
  case "PAUSE":
  case "MESSAGE":
    return arg ? {key:key, arg:arg} : undefined;
  case "MACRO":
    return (arg && arg.indexOf("\"") < 0) ? {key:key, arg:arg} : undefined;
  case "EXTON":
  case "EXTOFF":
  case "EXTAUTO":
    return getExtAppliance(arg) ? {key:key, arg:getExtAppliance(arg).name} : undefined;
  }
  return undefined;
}

function getExtAppliance(name) {
  for (var i = 0; i < extAppliances.length; ++i) {
    if (extAppliances[i].name.replace(/\s+/g, "").toUpperCase() == String(name).replace(/\s+/g, "").toUpperCase()) {
      return extAppliances[i];
    }
  }
  return undefined;
}

function checkAction(text, source) {
  if (!parseAction(text)) {
    error(localize("Invalid action \"" + text + "\" (" + source + "). " + validActions));
  }
}

/** Writes one action, with a comment naming where it came from. */
function writeAction(text, source) {
  checkAction(text, source);
  text = String(text).replace(/^\s+|\s+$/g, "");
  writeComment("Action " + (text.length > 40 ? text.substr(0, 37) + "..." : text) + ": " + source);
  onParameter("action", text);
}

/** The actions added in Phase F, called from onParameter("action"). Returns false for the others. */
function writeNewAction(text) {
  var action = parseAction(text);
  if (!action) {
    return false;
  }
  switch (action.key) {
  case "LOADAUTOLEVEL":
    writeBlock("M375 (Load the autolevel grid)"); // both firmwares (stock CartGridStrategy.cpp:453)
    return true;
  case "PAUSE":
    writeOperatorMessage(action.arg ? action.arg : "Pause", true);
    return true;
  case "MESSAGE":
    writeOperatorMessage(action.arg, false);
    return true;
  case "MACRO":
    writeCallProgram(action.arg);
    return true;
  case "EXTON":
  case "EXTOFF":
  case "EXTAUTO":
    if (!action.arg) {
      return false; // ExtOn / ExtOff: the whole port
    }
    if (!getProperty("usePwmExt")) {
      error(localize("Action \"" + text + "\" needs 'Enable PWM-based Ext' ticked."));
      return true;
    }
    extForced[getExtAppliance(action.arg).id] = action.key == "EXTON" ? true : (action.key == "EXTOFF" ? false : undefined);
    updateExt();
    return true;
  }
  return false;
}

// What an action switches, to find contradictions: {name, state}, or undefined.
function getActionSwitch(text) {
  var action = parseAction(text);
  var pairs = {LIGHTON:["light", "on"], LIGHTOFF:["light", "off"], AIRON:["air", "on"], AIROFF:["air", "off"],
    VACON:["vacuum", "on"], VACOFF:["vacuum", "off"], AUTOVACON:["auto vacuum", "on"], AUTOVACOFF:["auto vacuum", "off"],
    ENABLEFLEXCOMP:["flex compensation", "on"], DISABLEFLEXCOMP:["flex compensation", "off"],
    EXTON:["Ext port", "on"], EXTOFF:["Ext port", "off"], EXTAUTO:["Ext port", "auto"]};
  if (!action || !pairs[action.key]) {
    return undefined;
  }
  var p = pairs[action.key];
  return {name:(action.arg ? "Ext " + action.arg : p[0]), state:p[1]};
}

/** Stops posting when two actions at one point switch the same thing to different states. */
function checkActionConflicts(actions, where) {
  for (var i = 0; i < actions.length; ++i) {
    checkAction(actions[i].text, actions[i].source);
  }
  for (var i = 0; i < actions.length; ++i) {
    var a = getActionSwitch(actions[i].text);
    for (var j = i + 1; a && j < actions.length; ++j) {
      var b = getActionSwitch(actions[j].text);
      if (b && a.name == b.name && a.state != b.state) {
        error(localize(where + ": \"" + actions[i].text + "\" (" + actions[i].source + ") and \"" + actions[j].text + "\" (" + actions[j].source + ") switch the " + a.name + " both ways. Remove one."));
        return;
      }
    }
  }
}

/** The actions in a ';'-separated setting. */
function getSettingActions(name, source) {
  var list = [];
  var parts = String(getProperty(name) || "").split(";");
  for (var i = 0; i < parts.length; ++i) {
    if (parts[i].replace(/\s+/g, "")) {
      list.push({text:parts[i].replace(/^\s+|\s+$/g, ""), source:source});
    }
  }
  return list;
}

/** The "Before / After this operation" drop-down of a section, and for Before, the [tags] in its name. */
function getOperationActions(section, before) {
  var list = [];
  var operation = String(getSectionComment(section)).replace(/\s*\[[^\]]*\]/g, ""); // without the [tags]
  var choice = section.getProperty(before ? "actionBeforeOperation" : "actionAfterOperation");
  if (choice && choice != "none") {
    list.push({text:(choice == "Pause" ? "Pause:" + (before ? "Before " : "After ") + operation : choice), source:(before ? "Before" : "After") + " this operation"});
  }
  if (before && section.hasParameter("operation-comment")) {
    var tags = String(section.getParameter("operation-comment")).match(/\[[^\]]*\]/g) || [];
    for (var i = 0; i < tags.length; ++i) {
      list.push({text:tags[i].substr(1, tags[i].length - 2), source:"operation name tag"});
    }
  }
  return list;
}

function writeActions(actions) {
  for (var i = 0; i < actions.length; ++i) {
    writeAction(actions[i].text, actions[i].source);
  }
}

// Manual NC between operations is held here and written in onSection, after
// the retract and in that operation's file (guide p.208). Action text is
// checked when it arrives. Pass-through is held too but written as typed.
var manualNC = [];
function onManualNC(command, value) {
  if (command == COMMAND_ACTION) {
    var lines = String(value).split(/\r?\n/);
    for (var i = 0; i < lines.length; ++i) {
      if (lines[i].replace(/\s+/g, "")) {
        checkAction(lines[i], "Manual NC");
        manualNC.push({command:command, value:lines[i]});
      }
    }
  } else {
    manualNC.push({command:command, value:value});
  }
  if (getCurrentSectionId() != -1) {
    executeManualNC();
  }
}

function getManualNCActions() {
  var list = [];
  for (var i = 0; i < manualNC.length; ++i) {
    if (manualNC[i].command == COMMAND_ACTION) {
      list.push({text:manualNC[i].value, source:"Manual NC"});
    }
  }
  return list;
}

function executeManualNC() {
  var commands = manualNC;
  manualNC = [];
  for (var i = 0; i < commands.length; ++i) {
    if (commands[i].command == COMMAND_ACTION) {
      writeAction(commands[i].value, "Manual NC");
    } else {
      expandManualNC(commands[i].command, commands[i].value);
    }
  }
}

// The high-speed pause for the sections from index first to last, once per file.
function writeFileProbePause(first, last) {
  var fastest = 0;
  for (var i = first; i <= last; ++i) {
    if (isFastProbeSection(getSection(i))) {
      fastest = Math.max(fastest, getFastestProbeFeed(getSection(i)));
    }
  }
  if (fastest > 0) {
    writeFastProbePause(fastest);
  }
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

// "Split by toolpath" and "Split by toolpath, no header" both write a file per operation.
function isSplitByToolpath() {
  return getProperty("splitFile") == "toolpath" || getProperty("splitFile") == "toolpathNoHeader";
}

function onSection() {
  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number) || getProperty("splitFile") == "toolpath";

  var splitHere = isSplitByToolpath() || (getProperty("splitFile") == "tool" && insertToolCall);

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
      writeActions(getSettingActions("actionsAtEnd", "Actions at end"));

      writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
      if (isRedirecting()) {
        closeRedirection();
      }
    }

    var subprogram;
    if (isSplitByToolpath()) {
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
    if (getProperty("usePwmExt")) {
      writeBlock("M332.3 (Auto Ext Out off: the post switches Ext)");
    }
    writeActions(getSettingActions("actionsAtStart", "Actions at start"));

    // Each split file pauses once for the high-speed probe moves in it: this
    // section only, or every section up to the next tool change.
    if (getProperty("probeFeedWarningPause") == "file") {
      var last = currentSection.getId();
      while (getProperty("splitFile") == "tool" && last + 1 < getNumberOfSections() &&
        getSection(last + 1).getTool().number == tool.number) {
        ++last;
      }
      writeFileProbePause(currentSection.getId(), last);
    }
  }



  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment("Start of operation: " + comment);
    }
  }

  if (getProperty("probeFeedWarningPause") == "operation" && isFastProbeSection(currentSection)) {
    writeFastProbePause(getFastestProbeFeed(currentSection), getSectionComment(currentSection));
  }

  var beforeToolChangeActions = insertToolCall ? getSettingActions("actionsBeforeToolChange", "Actions before every tool change") : [];
  var toolChangeActions = insertToolCall ? getSettingActions("actionsAtToolChange", "Actions after every tool change") : [];
  var beforeActions = getOperationActions(currentSection, true);
  checkActionConflicts(getManualNCActions().concat(toolChangeActions, beforeActions), "Before operation \"" + getSectionComment(currentSection) + "\"");
  executeManualNC();

  if (insertToolCall) {

    if(getProperty("splitFile") == "toolpath") {
      dumpToolInformation();
      if (getProperty("writeStock")) {
        dumpStockInformation();
      }
    }

    setCoolant(COOLANT_OFF);
    writeActions(beforeToolChangeActions);

    // Shank diameter change: add S1-S6 to M6 when shaft diameter changed (S1=3mm, S2=3.175mm, S3=4mm, S4=6mm, S5=6.35mm, S6=8mm; do not change numbering)
    // Use shaft segments (Tool tab) to match standard diameter; fallback to tool.shaftDiameter
    var shaftDiameterMm = getToolShaftDiameterMm(tool);
    var prevShaftMm = !isFirstSection() ? getToolShaftDiameterMm(getPreviousSection().getTool()) : 0;
    var shankDiameterChanged = !isFirstSection() && (Math.abs(shaftDiameterMm - prevShaftMm) > 0.001);
    var shaftParam = (shankDiameterChanged || isFirstSection()) ? getShankSizeSuffix(shaftDiameterMm) : "";

    if (tool.number > numberOfToolSlots) {
      warning(localize("Tool number exceeds maximum value."));
    }

    if (laser_used && tool.type != TOOL_LASER_CUTTER){
      writeBlock("M5");
      writeBlock("M107");
      writeBlock("M322");
      laser_used = false;
    }

    var tloValue = parseTLO(tool.comment);//A is automatic and is the default, M is manual setting (C=0), a number set the value directly (H=-14)

    var e_manualToolChangeBehavior = getProperty("manualToolChangeBehavior");

    if(tool.number > 6 && e_manualToolChangeBehavior == "error6" && tool.type != TOOL_LASER_CUTTER) {
      error(localize("Carvera does not support tool numbers greater than 6 by default. Use one of the manual tool change post processor settings"));
    }

    if (tool.type == TOOL_LASER_CUTTER){
      // No return here: the rest of onSection (WCS, Ext, position, M3) applies to the laser too
      writeToolBlock(mFormat.format(321));
      writeBlock("M106")
      laser_used = true;
    } else if (e_manualToolChangeBehavior == "carvAirMtc"){ //any tool number accepted
      var toolChangeParameters = "";
      if (getProperty("useToolCommentForChangeParameters")){
        toolChangeParameters = tool.comment;
      }
      if (getProperty("issueColletChangeOnShankSizeChange")){
        toolChangeParameters = toolChangeParameters + " " + shaftParam;
      }

      writeToolBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " " + toolChangeParameters);

      if (tool.comment && !getProperty("useToolCommentForChangeParameters")) {
        writeComment(tool.comment);
      }
    } else if (e_manualToolChangeBehavior == "carvcomMtc"){

      if (tloValue && !getProperty("useToolCommentForChangeParameters")) {
        if (tloValue === "A") {
            writeToolBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " C1");
        } else if (tloValue === "M") {
          writeToolBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " C0");  
        } else {
            var tloFloat = parseFloat(tloValue);
            if (!isNaN(tloFloat)) {
                writeToolBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " H" + tloFloat);
            } else {
                writeToolBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6));
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
        writeToolBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6) + " " + toolChangeParameters);
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
        writeToolBlock("T" + toolFormat.format(tool.number) +  mFormat.format(6));

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
  writeActions(toolChangeActions.concat(beforeActions));

  var spindleChanged = tool.type != TOOL_PROBE &&
    (insertToolCall || forceSpindleSpeed || isFirstSection() ||
    (tool.type != TOOL_LASER_CUTTER && rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
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
    if (useSpindleExt()) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(851), pwmOutput.format(100));
    }
    spindleRunning = true;
    updateExt();
    if (tool.type != TOOL_LASER_CUTTER) { // the laser is switched on by writeJetCodes
      writeBlock(
        sOutput.format(spindleSpeed), mFormat.format(tool.clockwise ? 3 : 4)
      );
    }
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
      if (!isFirstOperationProbeZ()) {
        writeBlock(
          gAbsIncModal.format(90),
          gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
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

function calculateWCS(offset) {
  return wcsDefinitions.wcs[0].range[0] + offset - 1;
}

// ====================================================== //
// ================ BEGIN CYCLE HANDLERS ================ //
// ====================================================== //

// getSign returns 1, -1 or the value itself (0 or NaN), like Math.sign.
function getSign(value) {
  return value > 0 ? 1 : (value < 0 ? -1 : value);
}

// axisValue returns an object with one property, e.g. axisValue("x", 2) is {x:2}.
function axisValue(axis, value) {
  var result = {};
  result[axis] = value;
  return result;
}

// mergeObjects returns a new object with the own properties of every argument,
// later arguments overriding earlier ones.
function mergeObjects() {
  var result = {};
  for (var i = 0; i < arguments.length; ++i) {
    for (var key in arguments[i]) {
      if (Object.prototype.hasOwnProperty.call(arguments[i], key)) {
        result[key] = arguments[i][key];
      }
    }
  }
  return result;
}

// baseCycleHandler defines all known cycle types and establishes default
// handlers. If new probe or cycle types appear, they should be added here. To
// add implementations, extend makeraFirmwareCycleHandler or
// communityFirmwareCycleHandler, or roll a new one.
//
// several pre-calculated fields are set up on handler, please refer to them in
// your implementations.
function baseCycleHandler(cycle, tool) {
  var handler = {
    // Set in the UI as "Lead-In Feedrate", on the Tool tab. Probing operations
    // take their feeds from getProbeFeeds instead.
    entryFeed: currentSection.getParameter("operation:tool_feedEntry")
  };

  // probeMove constructs functions that move the probe at a specified rate in
  // absolute mode. Coordinates are given as maps of the form {x:n, y:n, z:n}.
  // Giving two or more coordinates will execute multiple separate moves.
  // protected = true uses G moves based on sensor type, which will stop in the
  // event of a collision.
  var probeMove = function (motion, feed, absolute) {
    if (absolute === undefined) {
      absolute = true;
    }
    return function () {
      for (var i = 0; i < arguments.length; ++i) {
        var x = arguments[i].x;
        var y = arguments[i].y;
        var z = arguments[i].z;
        var args = [
          motion.indexOf("G38.") == 0
            ? null
            : gAbsIncModal.format(absolute ? 90 : 91),
          motion
        ].filter(Boolean);

        // A coordinate of 0 is a real position in an absolute move, so test for a
        // number, not for truth. In a relative move 0 means no motion on that axis.
        var axisWords = args.length;
        forceXYZ();
        if (typeof x == "number" && (absolute || x != 0)) args.push(xOutput.format(x));
        if (typeof y == "number" && (absolute || y != 0)) args.push(yOutput.format(y));
        if (typeof z == "number" && (absolute || z != 0)) args.push(zOutput.format(z));
        if (args.length == axisWords) {
          continue; // nothing to move; a block without X, Y or Z is an error on the machine
        }

        feedOutput.reset();
        if (feed) args.push(feedOutput.format(feed));

        writeBlock.apply(null, args);
      }
    };
  };

  // Probing operations move at the feeds the "Probe feeds" property picks;
  // other cycles position at the Lead-In feed.
  var probeFeeds = isProbeOperation() ? getProbeFeeds(currentSection) : undefined;
  var positioningFeed = probeFeeds ? probeFeeds.positioning : handler.entryFeed;
  handler.positioningFeed = positioningFeed;

  // Absolute moves
  handler.absoluteRapidMove = probeMove(gFormat.format(0), null, true);
  handler.absoluteMove = probeMove(gFormat.format(1), positioningFeed, true);

  // Relative moves without probing.
  handler.relativeMove = probeMove(gFormat.format(1), positioningFeed, false);

  if (isProbeOperation()) {
    handler = mergeObjects(handler, {
      probeRadius: tool.diameter / 2,
      // The WCS the probe moves in; printed as "WCS used during probing".
      // With "Override driving WCS" ticked on the operation's Actions tab,
      // this is the WCS chosen there.
      drivingWcs: currentSection.workOffset || 1,
      // The WCS the probe result is written to; printed as "WCS that will be
      // updated". This is Fusion's probe output work offset: the WCS of the
      // setup the operation belongs to. It does not depend on the override
      // checkbox. A work offset of 0 is WCS 1 (wcsDefinitions.useZeroOffset is
      // false), never P0, which the firmware takes as the active WCS.
      targetWcs: currentSection.probeWorkOffset || 1,
      // The "Write probe results to WCS" property, as set for this operation
      // (or for the post when the operation does not override it).
      writeProbeResults: getOperationSetting("writeProbeResults") != false,
      // The "Probe result" property: write the modelled position, or set the
      // probed feature to 0.
      setFeatureToZero: getOperationSetting("probeResult") == "zero",
      // The "Probe tip diameter" property: subtract the firmware's calibrated
      // radius (#150/2) instead of the Fusion tool's from touch results.
      useMachineTipDiameter: getOperationSetting("probeTipDiameter") == "machine",
      approach1: cycle.approach1 == "positive" ? 1 : -1,
      approach2: cycle.approach2 == "positive" ? 1 : -1,
      // The type of sensor in use, normally open (NO), or normally closed (NC).
      // This is configured in the post processor parameters. The community
      // firmware handles an NC probe in its configuration, after which contact
      // reads as triggered, so it always probes as NO.
      probeSensorType: getProperty("firmwareType") == "community" ? "NO" : getProperty("probeSensorType")
    });

    if (getProperty("firmwareType") == "community" && getProperty("probeSensorType") == "NC" && !warnedProbeSensorType) {
      warning(localize("Probe Sensor Type NC is ignored for the community firmware, which probes with G38.2/G38.3. Set an NC probe up in the firmware configuration."));
      warnedProbeSensorType = true;
    }

    handler.safeRelativeMove = probeMove(
      gFormat.format(handler.probeSensorType == "NC" ? 38.5 : 38.3),
      positioningFeed,
      false
    );

    // Relative moves with probing.
    handler.measureMoveFast = probeMove(
      gFormat.format(handler.probeSensorType == "NC" ? 38.4 : 38.2),
      probeFeeds.firstTouch,
      false
    );
    handler.measureMoveSlow = probeMove(
      gFormat.format(handler.probeSensorType == "NC" ? 38.4 : 38.2),
      probeFeeds.secondTouch,
      false
    );

    // setCyclePoint records the cycle point for featurePosition. It is called
    // from onCyclePoint before the cycle type's handler runs.
    handler.setCyclePoint = function (x, y, z) {
      handler.cyclePoint = {x: x, y: y, z: z};
    };

    // Fusion's checks on the operation's Actions tab (decision 0003, F5-a): the
    // tolerance of each one set to "Stop and display message", and Print results.
    // "Failed probe check" Ignore and continue leaves every check out.
    handler.ignoreChecks = getOperationSetting("probeCheckAction") == "ignore";
    handler.tolerance = handler.ignoreChecks ? {} : {
      position: cycle.outOfPositionAction == "stop-message" ? (cycle.tolerancePosition || 0) : undefined,
      size: cycle.wrongSizeAction == "stop-message" ? (cycle.toleranceSize || 0) : undefined,
      angle: cycle.angleAskewAction == "stop-message" ? (cycle.toleranceAngle || 0) : undefined
    };
    if (handler.ignoreChecks && (cycle.outOfPositionAction == "stop-message" || cycle.wrongSizeAction == "stop-message" ||
      cycle.angleAskewAction == "stop-message")) {
      warning(localize("Operation \"" + getSectionComment(currentSection) + "\": its checks are left out ('Failed probe check' is 'Ignore and continue')."));
    }
    handler.printResults = !!cycle.printResults;
    // Item 16 stage 2 (decision 0003 addendum 2). reprobe: a failed check parks,
    // pauses and probes again from the cycle point, in an O-code repeat loop.
    handler.reprobe = getOperationSetting("probeCheckAction") == "reprobe" && !isFirstOperationProbeZ() &&
      (handler.tolerance.position !== undefined || handler.tolerance.size !== undefined || handler.tolerance.angle !== undefined);
    // 0: Don't save (id "off"), and nothing is written. Otherwise the id is the first variable number.
    handler.resultVariable = getProperty("probeResultVariable") == "off" ? 0 : (parseInt(getProperty("probeResultVariable"), 10) || 0);

    // writeResult prints a measured value (Print results), and pauses with a
    // message when it is further from the model than the check's tolerance.
    // measured is a firmware expression, read when the line runs, so it must
    // come straight after the measurement (G38 waits for the move to end).
    handler.writeResult = function (kind, label, measured, nominal) {
      var operation = String(getSectionComment(currentSection)).substr(0, 40);
      var model = nominal < 0 ? "+" + xyzFormat.format(-nominal) : "-" + xyzFormat.format(nominal);
      if (handler.printResults) {
        writeConsoleMessage((getProperty("probePrintPrefix") ? getProperty("probePrintPrefix") + " " : "") + operation + ": " + label + ", model " + xyzFormat.format(nominal) + kindUnit(kind) + ", measured:");
        writeBlock("M118.1 P[" + measured + "]");
      }
      var tolerance = handler.tolerance[kind];
      if (tolerance !== undefined) {
        var block = "O" + (100 + probeCheckCount++);
        var more = operation + ": " + label + " more than " + xyzFormat.format(tolerance) + kindUnit(kind) + " from the model";
        writeOCodeLine(block + " if [abs[" + measured + model + "] gt " + xyzFormat.format(tolerance) + "]");
        if (handler.reprobe) {
          // Attempts left: park, pause, return to the cycle point and probe again.
          // The return ends in G90, as the loop top does, so both paths agree.
          var attempts = getProperty("probeCheckAttempts");
          var retry = "O" + (100 + probeCheckCount++);
          writeOCodeLine(retry + " if [#120 lt " + attempts + "]");
          writeConsoleMessage(more + ". Fix the part, keep the WCS, then resume to probe again.");
          if (getProperty("probeParkPosition") == "custom") {
            writeBlock("G90", gFormat.format(53), gFormat.format(0), "Z" + xyzFormat.format(-3));
            writeBlock(gFormat.format(53), gFormat.format(0), "X" + xyzFormat.format(getProperty("probeParkX")), "Y" + xyzFormat.format(getProperty("probeParkY")));
          } else {
            // The firmware finishes G28's moves before it reads the next line: the
            // player feeds one line per main loop (Player.cpp), and ATCHandler's
            // main loop waits for the G28 moves to end.
            writeBlock(gFormat.format(28));
          }
          writeBlock(mFormat.format(600));
          writeBlock("G90", gFormat.format(0), "X" + xyzFormat.format(handler.cyclePoint.x), "Y" + xyzFormat.format(handler.cyclePoint.y));
          writeBlock(gFormat.format(38.3), "Z[" + xyzFormat.format(handler.cyclePoint.z) + "-#5043]", "F" + xyzFormat.format(handler.positioningFeed));
          writeOCodeLine(handler.attemptsLoop + " continue");
          writeOCodeLine(retry + " endif");
          writeConsoleMessage(more + " after " + attempts + " attempts. Abort in the Controller, or resume.");
        } else {
          writeConsoleMessage(more + ". Abort in the Controller, or resume.");
        }
        writeBlock(mFormat.format(600));
        writeOCodeLine(block + " endif");
      }
      // Save the deviation from the model, after the check: a re-probe does not save.
      if (handler.resultVariable) {
        var number = handler.resultVariable++;
        if (!((number >= 112 && number <= 119) || (number >= 501 && number <= 520))) {
          error(localize("Operation \"" + getSectionComment(currentSection) + "\": 'Save results to variables, starting at' would use #" + number +
            ". This operation saves one variable per measured value; they must all lie in 112 to 119 or 501 to 520."));
          return;
        }
        writeBlock("#" + number + " = [" + measured + model + "]");
      }
    };

    // beginAttempts and endAttempts wrap the cycle in the re-probe loop.
    // #120 counts the attempts; a failed check with attempts left continues the loop.
    handler.beginAttempts = function () {
      if (handler.reprobe) {
        handler.attemptsLoop = "O" + (100 + probeCheckCount++);
        writeBlock("#120 = 0");
        writeOCodeLine(handler.attemptsLoop + " repeat [" + getProperty("probeCheckAttempts") + "]");
        writeBlock("#120 = [#120+1]");
        writeBlock(gAbsIncModal.format(90));
      }
    };
    handler.endAttempts = function () {
      if (handler.reprobe) {
        writeOCodeLine(handler.attemptsLoop + " break");
        writeOCodeLine(handler.attemptsLoop + " endrepeat");
      }
    };

    // featurePosition returns the coordinate to write for a feature that lies
    // offset from the cycle point along axis: its modelled position, or 0 with
    // "Set feature to 0".
    handler.featurePosition = function (axis, offset) {
      return handler.setFeatureToZero ? 0 : handler.cyclePoint[axis] + offset;
    };

    // updateWCS updates the WCS for this probe using the axis and WCS offset provided,
    // unless "Write probe results to WCS" is off.
    handler.updateWCS = function (axis, offset) {
      if (!handler.writeProbeResults) return;

      // The axis output is modal: a value equal to the last one written would be
      // left out, giving a G10 that writes nothing. Reset it so the word is always written.
      if (typeof offset != "string") {
        axis.reset();
      }

      // The stock firmware works out G10 L20 Pn from the active WCS, not WCS n, so
      // a result written to another WCS comes out wrong. Select WCS n for the write
      // and return to the WCS the probe moves in. No motion. A work offset of 0 is
      // Fusion's default, WCS 1.
      var drivingWcs = handler.drivingWcs || 1;
      var switchWcs = getProperty("firmwareType") == "stock" &&
        handler.targetWcs > 0 && handler.targetWcs != drivingWcs;
      if (switchWcs) {
        writeBlock(gFormat.format(calculateWCS(handler.targetWcs)));
      }
      writeBlock(
        gFormat.format(10),
        "L20 P" + handler.targetWcs,
        typeof offset == "string" ? offset : axis.format(offset)
      );
      if (switchWcs) {
        writeBlock(gFormat.format(calculateWCS(drivingWcs)));
      }
    };

    handler.extractAxisAndDistance = function (options) {
      var axis;
      var axes = ["x", "y", "z"];
      for (var i = 0; i < axes.length; ++i) {
        if (Object.keys(options).indexOf(axes[i]) != -1 && options[axes[i]] !== undefined) {
          axis = axes[i];
          break;
        }
      }

      if (!axis) {
        error(localize("Error determining axis for probing operation."));
        return null;
      }

      var distance = options[axis];
      if (!distance || isNaN(distance)) {
        error(localize("Invalid distance for probing operation."));
        return null;
      }

      return { axis: axis, distance: distance };
    };

    // touchProbe measures on the provided axis in the direction indicated by the sign of the value.
    // It double-taps and leaves the probe touching the material after the second touch.
    handler.touchProbe = function (options) {
      var probe = handler.extractAxisAndDistance(options);
      var axis = probe.axis;
      var distance = probe.distance;
      // back off between the two touches by no more than the approach distance,
      // so the probe never backs into a wall the approach left room for
      var tapBackOff = Math.min(cycle.probeClearance, tool.diameter);
      if (!(tapBackOff > 0)) {
        tapBackOff = tool.diameter;
      }

      handler.measureMoveFast(axisValue(axis, distance));
      handler.relativeMove(axisValue(axis, -getSign(distance) * tapBackOff));
      handler.measureMoveSlow(axisValue(axis, getSign(distance) * tapBackOff * 2));
    };

    // touchUpdateRetract probes using the handler.touchProbe function,
    // then updates either the WCS or the provided variable,
    // and finally retracts the probe away from the surface
    // by the specified retract distance.
    // If a retract distance is not specified, it defaults to the approach
    // distance for the cycle.
    handler.touchUpdateRetract = function (options) {
      handler.touchProbe(options);

      var currentWCSPositions = {
        x: "#5041",
        y: "#5042",
        z: "#5043"
      };

      var probe = handler.extractAxisAndDistance(options);
      var axis = probe.axis;
      var distance = probe.distance;

      if (Object.keys(options).indexOf("variable") != -1) {
        // If a variable is provided, update it with the probe result.
        var variable = options.variable.replace("#", "");
        var sign = distance < 0 ? "-" : "+";
        writeBlock(
          "#" + variable + " = [" + currentWCSPositions[axis] + " " + sign + " " + handler.probeRadius + "]"
        );
      } else {
        // Otherwise, update the WCS for the current axis.
        var output;
        var outputs = [xOutput, yOutput, zOutput];
        for (var i = 0; i < outputs.length; ++i) {
          if (outputs[i].format(0).indexOf(axis.toUpperCase()) == 0) {
            output = outputs[i];
            break;
          }
        }

        // Fusion starts the probe with the ball surface the approach distance
        // from the face, so the face lies approach distance + probe radius
        // from the cycle point. Write the ball centre at contact.
        var faceOffset = getSign(distance) * (cycle.probeClearance + handler.probeRadius);
        // The touched face: the ball centre at contact (#5041-#5043, this WCS) plus the radius.
        var radius = handler.useMachineTipDiameter ? "#150/2" : xyzFormat.format(handler.probeRadius);
        handler.writeResult("position", axis.toUpperCase() + " face", currentWCSPositions[axis] + (getSign(distance) > 0 ? "+" : "-") + radius,
          handler.cyclePoint[axis] + faceOffset);
        var face = handler.featurePosition(axis, faceOffset);
        if (handler.useMachineTipDiameter) {
          // Let the firmware subtract its calibrated radius: X[face - #150/2].
          handler.updateWCS(output, axis.toUpperCase() + "[" + xyzFormat.format(face) +
            (getSign(distance) > 0 ? "-" : "+") + "#150/2]");
        } else {
          handler.updateWCS(output, face - getSign(distance) * handler.probeRadius);
        }
      }

      // Retract away from the surface.
      var retractDistance =
        options.retractDistance ||
        options.approachDistance ||
        cycle.probeClearance ||
        tool.diameter ||
        2;

      handler.relativeMove(axisValue(axis, -getSign(distance) * retractDistance));
    };
  }

  if (isProbeOperation()) {
    handler[cycleType] = function (x, y, z) {
      error(localize("Probing cycle '" + cycleType + "' is not supported by Carvera."));
    };
    handler[cycleType].unsupported = true; // replaced by the target's handler when it has one (onCycle checks)
  }

  return handler;
}

// makeraFirmwareCycleHandler sets up handlers for the probe cycle types supported by the stock firmware.
// These are limited to basic operations that set a WCS coincident to a face.
function makeraFirmwareCycleHandler(cycle, tool) {
  var handler = baseCycleHandler(cycle, tool);

  var handlers = {
    "probing-x": function (x, y, z) {
      var probeDatum = handler.featurePosition("x", handler.approach1 * (cycle.probeClearance + handler.probeRadius)) -
        handler.approach1 * handler.probeRadius;
      handler.safeRelativeMove({ z: -cycle.depth });
      handler.touchProbe({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel)
      });
      handler.updateWCS(xOutput, probeDatum);
      handler.absoluteMove({ x: x });
    },
    "probing-y": function (x, y, z) {
      var probeDatum = handler.featurePosition("y", handler.approach1 * (cycle.probeClearance + handler.probeRadius)) -
        handler.approach1 * handler.probeRadius;
      handler.safeRelativeMove({ z: -cycle.depth });
      handler.touchProbe({
        y: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel)
      });
      handler.updateWCS(yOutput, probeDatum);
      handler.absoluteMove({ y: y });
    },
    "probing-z": function (x, y, z) {
      var probeDatum = handler.featurePosition("z", -cycle.depth);
      if (isFirstOperationProbeZ()) {
        // The work Z is unknown: search the whole way.
        handler.touchProbe({ z: -120 });
      } else {
        // Move fast (protected) to the approach distance above the modelled surface,
        // then touch over approach distance + overtravel.
        var descent = cycle.depth - cycle.probeClearance;
        if (descent > 0) {
          handler.safeRelativeMove({ z: -descent });
        }
        handler.touchProbe({ z: -(Math.min(cycle.depth, cycle.probeClearance) + cycle.probeOvertravel) });
      }
      handler.updateWCS(zOutput, probeDatum);
    },
    "probing-xy-outer-corner": function (x, y, z) {
      var offset = cycle.probeClearance;
      var probeDatumX = handler.featurePosition("x", handler.approach1 * (offset + handler.probeRadius)) -
        handler.approach1 * handler.probeRadius;
      var probeDatumY = handler.featurePosition("y", handler.approach2 * (offset + handler.probeRadius)) -
        handler.approach2 * handler.probeRadius;

      // Move to start depth
      handler.safeRelativeMove({ z: -cycle.depth });

      // Step sideways past the corner before each touch. The start is c + r outside
      // both faces, so 2(c + r) puts the whole ball the approach distance past the
      // corner, whatever the overtravel (which only limits how far a touch searches).
      var cornerStep = 2 * (cycle.probeClearance + handler.probeRadius);

      // Probing X: move up in Y, probe in X, return to X, return to Y
      writeComment("probing x surface");
      handler.safeRelativeMove({ y: handler.approach2 * cornerStep });
      handler.touchProbe({
        x: handler.approach1 * (offset + cycle.probeOvertravel)
      });
      handler.updateWCS(xOutput, probeDatumX);
      handler.absoluteMove({ x: x }, { y: y });

      // Probing Y: move up in X, probe in Y, return to Y, return to X
      writeComment("probing y surface");
      handler.safeRelativeMove({ x: handler.approach1 * cornerStep });
      handler.touchProbe({
        y: handler.approach2 * (offset + cycle.probeOvertravel)
      });
      handler.updateWCS(yOutput, probeDatumY);
      handler.absoluteMove({ y: y }, { x: x });
    },
    "probing-xy-inner-corner": function (x, y, z) {
      var offset = cycle.probeClearance;
      var probeDatumX = handler.featurePosition("x", handler.approach1 * (offset + handler.probeRadius)) -
        handler.approach1 * handler.probeRadius;
      var probeDatumY = handler.featurePosition("y", handler.approach2 * (offset + handler.probeRadius)) -
        handler.approach2 * handler.probeRadius;

      // Move to start depth
      handler.safeRelativeMove({ z: -cycle.depth });

      writeComment("probing x surface");
      handler.touchProbe({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel)
      });
      handler.updateWCS(xOutput, probeDatumX);
      handler.absoluteMove({ x: x });

      writeComment("probing y surface");
      handler.touchProbe({
        y: handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel)
      });
      handler.updateWCS(yOutput, probeDatumY);
      handler.absoluteMove({ y: y });
    }
  };

  return mergeObjects(handler, handlers);
}

// communityFirmwareCycleHandler sets up handlers for the probe cycle types
// supported by the community firmware.
function communityFirmwareCycleHandler(cycle, tool) {
  var handler = baseCycleHandler(cycle, tool);

  var widthProbe = function (options) {
    writeComment("Width probe with double tap - " + options.direction);

    function probeAxis(axis) {
      if (!options[axis]) return;

      var value = options[axis];
      var probeApproach =
        options.direction.toLowerCase() === "inward"
          ? -handler.approach1
          : handler.approach1;
      // Fusion's approach distance is from the ball surface to the face, so the
      // ball centre starts approach distance + probe radius from the face.
      var startDistance = options.approachDistance + handler.probeRadius;

      // Move to the first side
      handler.safeRelativeMove(axisValue(axis,
        handler.approach1 *
        (value / 2 + probeApproach * startDistance)
      ));

      // Move down to probe depth
      handler.safeRelativeMove({ z: -options.depth });

      // Probe the first side and store the result in #101.
      var firstSide = axisValue(axis, probeApproach * (options.approachDistance + options.overtravel));
      firstSide.variable = "#101";
      handler.touchUpdateRetract(firstSide);

      // Retract up to the clearance height, unless the feature has no island
      // (D3): then cross at the probing depth, protected, which saves the lift.
      if (!options.crossAtDepth) {
        handler.relativeMove({ z: options.depth });
      }

      // Move across to the other side, the mirror of the first start
      handler.safeRelativeMove(axisValue(axis,
        2 *
        ((-handler.approach1 * value) / 2 +
          probeApproach * startDistance)
      ));

      // Move down to the probing height again
      if (!options.crossAtDepth) {
        handler.safeRelativeMove({ z: -options.depth });
      }

      // Probe the second side and store the result in #102. The start mirrors the
      // first, so the touch travels the same approach distance + overtravel.
      var secondSide = axisValue(axis, -probeApproach * (options.approachDistance + options.overtravel));
      secondSide.variable = "#102";
      handler.touchUpdateRetract(secondSide);

      // Retract up to the clearance height.
      handler.safeRelativeMove({ z: options.depth });

      // Move to axis midpoint
      writeBlock(
        gAbsIncModal.format(90),
        gFormat.format(1),
        axis.toUpperCase() + "[[#101+#102]/2]"
      );

      // #101 and #102 are the two faces.
      handler.writeResult("size", axis.toUpperCase() + " width", "abs[#102-#101]", value);
      handler.writeResult("position", axis.toUpperCase() + " centre", "[#101+#102]/2", handler.cyclePoint[axis]);

      // WCS update: the centre is the cycle point.
      if (handler.writeProbeResults) {
        writeBlock(
          gFormat.format(10),
          "L20 P" + handler.targetWcs,
          axis.toUpperCase() + xyzFormat.format(handler.featurePosition(axis, 0))
        );
      }
    }

    ["x", "y"].forEach(probeAxis);
  };

  var angleProbe = function (options) {
    writeComment("Angle probe with double tap");

    // Move down to the probing height.
    handler.safeRelativeMove({ z: -options.depth });

    var angleRadians = (options.nominalAngle * Math.PI) / 180;

    var probeAxis = function (axis) {
      if (!options[axis]) return;

      // Convert to cartesian.
      var xTravel = (options[axis] / 2) * Math.cos(angleRadians);
      var yTravel = (options[axis] / 2) * Math.sin(angleRadians);
      var probeArgs = { r: options.approachDistance };
      probeArgs[axis] = handler.approach1 * (options.approachDistance + options.overtravel);
      // The probe travels along the axis but the wall is at the nominal angle, so the
      // approach distance (normal to the wall) is longer along the axis. Back off by
      // that length to return exactly to the start.
      var normal = axis == "x" ? Math.abs(Math.sin(angleRadians)) : Math.abs(Math.cos(angleRadians));
      var backOff = normal > 1e-6 ? options.approachDistance / normal : options.approachDistance;

      // Move to the first side.
      handler.safeRelativeMove({
        x: xTravel,
        y: yTravel
      });

      // Probe with double tap.
      handler.touchProbe(probeArgs);

      // Save current position x and y in #101 and #102 respectively.
      writeBlock("#101 = #5021");
      writeBlock("#102 = #5022");

      // Retract away from the surface.
      handler.relativeMove(axisValue(axis, -handler.approach1 * backOff));

      // Move across to the other side.
      handler.safeRelativeMove({
        x: -2 * xTravel,
        y: -2 * yTravel
      });

      // Probe again.
      handler.touchProbe(probeArgs);

      // Store the wall's deviation from its nominal angle in #103: the step between
      // the two touches, rotated back by the nominal angle, is (along, across) the
      // nominal wall. "along" is about the probe spacing, so it is never 0, and
      // atan keeps the sign.
      var cosN = String(Math.round(Math.cos(angleRadians) * 1e6) / 1e6);
      var sinN = String(Math.round(Math.sin(angleRadians) * 1e6) / 1e6);
      writeBlock(
        "#103=atan[[[#5022-#102]*" + cosN + "-[#5021-#101]*" + sinN + "]" +
        "/[[#5021-#101]*" + cosN + "+[#5022-#102]*" + sinN + "]]"
      );

      // Retract away from the surface.
      handler.relativeMove(axisValue(axis, -handler.approach1 * backOff));

      // Return to the midpoint.
      handler.relativeMove({
        x: xTravel,
        y: yTravel
      });

      handler.writeResult("angle", "Wall angle deviation", "#103", 0);

      // Set the WCS rotation to the measured deviation.
      if (handler.writeProbeResults) {
        writeBlock(
          gFormat.format(10),
          "L20 P" + handler.targetWcs,
          "R[#103]"
        );
      }
    };

    ["x", "y"].forEach(probeAxis);
  };

  // Decision 0004: Fusion's two-point corner probing (probeSpacing > 0). Each wall
  // is touched twice, probeSpacing apart, the second touch further from the
  // corner. The corner is where the two measured walls meet; R is the mean of the
  // two walls' deviations. X, Y and R go in one G10 (the firmware applies R first,
  // Robot.cpp:663). Scratch: the X wall's first face point and slope dx/dy
  // (#101-#103), the Y wall's and slope dy/dx (#104-#106), the corner (#107, #108),
  // R (#109), the probe's offset from the corner (#110, #111).
  var twoPointCorner = function (outer) {
    var a1 = handler.approach1;
    var a2 = handler.approach2;
    var spacing = cycle.probeSpacing;
    var travel = cycle.probeClearance + cycle.probeOvertravel;
    var radius = handler.useMachineTipDiameter ? "#150/2" : xyzFormat.format(handler.probeRadius);
    // an outer corner starts c + r outside both faces: step past the corner first
    var step = outer ? 2 * (cycle.probeClearance + handler.probeRadius) : 0;
    var face = function (centre, sign) {
      return "[" + centre + (sign > 0 ? "+" : "-") + radius + "]";
    };
    writeComment("Two-point corner, spacing " + xyzFormat.format(spacing));

    // X wall: away from the corner is +a2 past an outer corner, -a2 inside an inner one.
    var alongX = outer ? a2 : -a2;
    handler.safeRelativeMove({ y: a2 * step });
    handler.touchProbe({ x: a1 * travel });
    writeBlock("#101 = " + face("#5041", a1));
    writeBlock("#102 = #5042");
    handler.relativeMove({ x: -a1 * cycle.probeClearance });
    handler.safeRelativeMove({ y: alongX * spacing });
    handler.touchProbe({ x: a1 * travel });
    writeBlock("#103 = [" + face("#5041", a1) + "-#101]/[#5042-#102]");
    handler.relativeMove({ x: -a1 * cycle.probeClearance });
    handler.safeRelativeMove({ y: -(a2 * step + alongX * spacing) });

    // Y wall
    var alongY = outer ? a1 : -a1;
    handler.safeRelativeMove({ x: a1 * step });
    handler.touchProbe({ y: a2 * travel });
    writeBlock("#104 = #5041");
    writeBlock("#105 = " + face("#5042", a2));
    handler.relativeMove({ y: -a2 * cycle.probeClearance });
    handler.safeRelativeMove({ x: alongY * spacing });
    handler.touchProbe({ y: a2 * travel });
    writeBlock("#106 = [" + face("#5042", a2) + "-#105]/[#5041-#104]");
    handler.relativeMove({ y: -a2 * cycle.probeClearance });
    handler.safeRelativeMove({ x: -(a1 * step + alongY * spacing) });

    writeBlock("#107 = [#101+#103*[#105-#102-#106*#104]]/[1-#103*#106]");
    writeBlock("#108 = [#105+#106*[#107-#104]]");
    writeBlock("#109 = [atan[#106]-atan[#103]]/2");

    var cornerOffset = cycle.probeClearance + handler.probeRadius;
    handler.writeResult("position", "Corner X", "#107", handler.cyclePoint.x + a1 * cornerOffset);
    handler.writeResult("position", "Corner Y", "#108", handler.cyclePoint.y + a2 * cornerOffset);
    handler.writeResult("angle", "Corner angle", "#109", 0);

    if (handler.writeProbeResults) {
      // The probe's position in the new WCS: the corner's, plus its offset rotated by -R.
      writeBlock("#110 = [#5041-#107]");
      writeBlock("#111 = [#5042-#108]");
      var cornerX = xyzFormat.format(handler.featurePosition("x", a1 * cornerOffset));
      var cornerY = xyzFormat.format(handler.featurePosition("y", a2 * cornerOffset));
      writeBlock(
        gFormat.format(10),
        "L20 P" + handler.targetWcs,
        "X[" + cornerX + "+cos[#109]*#110+sin[#109]*#111]",
        "Y[" + cornerY + "-sin[#109]*#110+cos[#109]*#111]",
        "R[#109]"
      );
    }
  };

  // Partial circular probing: three touches along the radii at Fusion's angles
  // A, B and C (degrees from +X). The ball centres at contact lie on a circle with
  // the feature's centre; its radius is the feature's minus (hole) or plus (boss)
  // the probe radius. Scratch: the first ball centre (#101, #102), the second and
  // third relative to it (#103-#106), twice the cross product (#107), the centre
  // relative to the first (#108, #109), the diameter (#110).
  // inward: a boss, touched towards the centre. lift: rise to the cycle height
  // between touches (a boss or an island is in the way).
  var partialCircle = function (inward, lift) {
    var angles = [cycle.partialCircleAngleA, cycle.partialCircleAngleB, cycle.partialCircleAngleC];
    var startRadius = cycle.width1 / 2 + (inward ? 1 : -1) * (cycle.probeClearance + handler.probeRadius);
    var travel = cycle.probeClearance + cycle.probeOvertravel;
    var tapBackOff = Math.min(cycle.probeClearance, tool.diameter);
    if (!(tapBackOff > 0)) {
      tapBackOff = tool.diameter;
    }
    var round = function (v) {
      return Math.round(v * 1e6) / 1e6;
    };
    var unit = function (angle) {
      var radians = (angle * Math.PI) / 180;
      return {x: round(Math.cos(radians)), y: round(Math.sin(radians))};
    };
    var along = function (u, distance) {
      return {x: u.x * distance, y: u.y * distance};
    };
    writeComment("Partial circle probe with double tap - " + (inward ? "inward" : "outward"));

    var at = {x: 0, y: 0}; // the probe's nominal offset from the cycle point, in X and Y
    for (var k = 0; k < 3; ++k) {
      var u = unit(angles[k]);
      var start = along(u, startRadius);
      var dir = inward ? -1 : 1;
      if (k > 0 && lift) {
        handler.safeRelativeMove({z: cycle.depth});
      }
      handler.safeRelativeMove({x: start.x - at.x, y: start.y - at.y});
      if (k == 0 || lift) {
        handler.safeRelativeMove({z: -cycle.depth});
      }
      handler.measureMoveFast(along(u, dir * travel));
      handler.relativeMove(along(u, -dir * tapBackOff));
      handler.measureMoveSlow(along(u, dir * tapBackOff * 2));
      if (k == 0) {
        writeBlock("#101 = #5041");
        writeBlock("#102 = #5042");
      } else {
        writeBlock("#" + (101 + 2 * k) + " = [#5041-#101]");
        writeBlock("#" + (102 + 2 * k) + " = [#5042-#102]");
      }
      // Back along the touch to its start.
      handler.absoluteMove({x: handler.cyclePoint.x + start.x, y: handler.cyclePoint.y + start.y});
      at = start;
    }
    handler.safeRelativeMove({z: cycle.depth});

    writeBlock("#107 = [2*[#103*#106-#104*#105]]");
    writeBlock("#108 = [[#106*[#103*#103+#104*#104]-#104*[#105*#105+#106*#106]]/#107]");
    writeBlock("#109 = [[#103*[#105*#105+#106*#106]-#105*[#103*#103+#104*#104]]/#107]");
    var tip = handler.useMachineTipDiameter ? "#150" : xyzFormat.format(2 * handler.probeRadius);
    writeBlock("#110 = [2*sqrt[#108*#108+#109*#109]" + (inward ? "-" : "+") + tip + "]");

    // Move to the measured centre.
    writeBlock(gAbsIncModal.format(90), gFormat.format(1), "X[#101+#108]", "Y[#102+#109]");

    handler.writeResult("size", "Diameter", "#110", cycle.width1);
    handler.writeResult("position", "X centre", "[#101+#108]", handler.cyclePoint.x);
    handler.writeResult("position", "Y centre", "[#102+#109]", handler.cyclePoint.y);

    // WCS update: the centre is the cycle point.
    if (handler.writeProbeResults) {
      writeBlock(
        gFormat.format(10),
        "L20 P" + handler.targetWcs,
        "X" + xyzFormat.format(handler.featurePosition("x", 0)),
        "Y" + xyzFormat.format(handler.featurePosition("y", 0))
      );
    }
  };

  var handlers = {
    "probing-x": function (x, y, z) {
      // Move to the probing height, stop on contact.
      handler.safeRelativeMove({ z: cycle.bottom - z });

      handler.touchUpdateRetract({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel)
      });
    },
    "probing-x-channel": function (x, y, z) {
      widthProbe({
        direction: "outward",
        crossAtDepth: true,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1
      });
    },
    "probing-x-channel-with-island": function (x, y, z) {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1
      });
    },
    "probing-x-wall": function (x, y, z) {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1
      });
    },
    "probing-y": function (x, y, z) {
      // Move to the probing height, stop on contact.
      handler.safeRelativeMove({ z: cycle.bottom - z });

      handler.touchUpdateRetract({
        y: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel)
      });
    },
    "probing-y-channel": function (x, y, z) {
      widthProbe({
        direction: "outward",
        crossAtDepth: true,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        y: cycle.width1
      });
    },
    "probing-y-channel-with-island": function (x, y, z) {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        y: cycle.width1
      });
    },
    "probing-y-wall": function (x, y, z) {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        y: cycle.width1
      });
    },
    "probing-z": function (x, y, z) {
      if (isFirstOperationProbeZ()) {
        // The work Z is unknown: search the whole way.
        handler.touchProbe({ z: handler.approach1 * 120 });
      } else {
        // Move fast (protected) to the approach distance above the modelled surface,
        // z - depth + c, then touch over approach distance + overtravel, as the
        // reference post does, instead of touching slowly all the way from z.
        var descent = cycle.depth - cycle.probeClearance;
        if (descent > 0) {
          handler.safeRelativeMove({ z: handler.approach1 * descent });
        }
        handler.touchProbe({
          z: handler.approach1 * (Math.min(cycle.depth, cycle.probeClearance) + cycle.probeOvertravel)
        });
      }

      if (isFirstOperationProbeZ()) {
        if (handler.tolerance.position !== undefined || handler.printResults || handler.resultVariable) {
          warning(localize("The first operation is a Z probe: the work Z is not known yet, so its Out of position check, Print results and saved results are skipped."));
        }
      } else {
        handler.writeResult("position", "Z face", "#5043", handler.cyclePoint.z - cycle.depth);
      }
      handler.updateWCS(zOutput, handler.featurePosition("z", -cycle.depth));
    },
    "probing-xy-inner-corner": function (x, y, z) {
      // Move down to the probing height.
      handler.safeRelativeMove({ z: cycle.bottom - z });
      if (cycle.probeSpacing > 0) {
        twoPointCorner(false);
        return;
      }

      // Probe the X.
      handler.touchUpdateRetract({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel)
      });

      // Probe the Y.
      handler.touchUpdateRetract({
        y: handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel)
      });
    },
    "probing-xy-rectangular-boss": function (x, y, z) {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width2
      });
    },
    "probing-xy-circular-boss": function (x, y, z) {
      widthProbe({
        direction: "inward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width1
      });
    },
    "probing-xy-circular-hole": function (x, y, z) {
      widthProbe({
        direction: "outward",
        crossAtDepth: true,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width1
      });
    },
    "probing-xy-circular-hole-with-island": function (x, y, z) {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width1
      });
    },
    "probing-xy-circular-partial-boss": function (x, y, z) {
      partialCircle(true, true);
    },
    "probing-xy-circular-partial-hole": function (x, y, z) {
      partialCircle(false, false);
    },
    "probing-xy-circular-partial-hole-with-island": function (x, y, z) {
      partialCircle(false, true);
    },
    "probing-xy-rectangular-hole": function (x, y, z) {
      widthProbe({
        direction: "outward",
        crossAtDepth: true,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width2
      });
    },
    "probing-xy-rectangular-hole-with-island": function (x, y, z) {
      widthProbe({
        direction: "outward",
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        approachDistance: cycle.probeClearance,
        x: cycle.width1,
        y: cycle.width2
      });
    },
    "probing-xy-outer-corner": function (x, y, z) {
      // Move down to the probing height.
      handler.safeRelativeMove({ z: cycle.bottom - z });
      if (cycle.probeSpacing > 0) {
        twoPointCorner(true);
        return;
      }

      // Step sideways past the corner before each touch. The start is c + r outside
      // both faces, so 2(c + r) puts the whole ball the approach distance past the
      // corner, whatever the overtravel (which only limits how far a touch searches).
      var cornerStep = 2 * (cycle.probeClearance + handler.probeRadius);

      // Move along the y to the position where we'll probe the x.
      handler.safeRelativeMove({
        y: handler.approach2 * cornerStep
      });

      handler.touchUpdateRetract({
        x: handler.approach1 * (cycle.probeClearance + cycle.probeOvertravel)
      });

      // Move back to the original y position.
      handler.relativeMove({
        y: -handler.approach2 * cornerStep
      });

      // Move along the x to the position where we'll probe the y.
      handler.safeRelativeMove({
        x: handler.approach1 * cornerStep
      });

      handler.touchUpdateRetract({
        y: handler.approach2 * (cycle.probeClearance + cycle.probeOvertravel)
      });

      // Move back to the original x position.
      handler.relativeMove({
        x: -handler.approach1 * cornerStep
      });
    },
    "probing-x-plane-angle": function (x, y, z) {
      angleProbe({
        nominalAngle: cycle.nominalAngle,
        approachDistance: cycle.probeClearance,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        x: cycle.probeSpacing
      });
    },
    "probing-y-plane-angle": function (x, y, z) {
      angleProbe({
        nominalAngle: cycle.nominalAngle,
        approachDistance: cycle.probeClearance,
        overtravel: cycle.probeOvertravel,
        depth: cycle.depth,
        y: cycle.probeSpacing
      });
    }
  };

  // Set up aliases for similar probing strategies.
  return mergeObjects(handler, handlers);
}

// O-code checks (decision 0003). Each check block gets its own label, O100 up.
var probeCheckCount = 0;

function kindUnit(kind) {
  return kind == "angle" ? " deg" : " mm";
}

// An O-code line: never numbered (the firmware does not see an O-code after N),
// no comment (it would become part of the condition), at most 128 characters.
function writeOCodeLine(text) {
  if (text.length > maximumLineLength) {
    error(localize("O-code line longer than " + maximumLineLength + " characters: " + text));
    return;
  }
  writeln(text);
}

// The checks and Print results set on a probing operation that this post can
// act on only with "Use firmware O-codes" on the community firmware.
function checkProbeChecks(handler) {
  var set = [];
  if (handler.tolerance.position !== undefined) {
    set.push("Out of position");
  }
  if (handler.tolerance.size !== undefined) {
    set.push("Wrong size");
  }
  if (handler.tolerance.angle !== undefined) {
    set.push("Angle askew");
  }
  for (var kind in handler.tolerance) {
    if (handler.tolerance[kind] !== undefined && !(handler.tolerance[kind] > 0)) {
      error(localize("Operation \"" + getSectionComment(currentSection) + "\": the " + kind + " tolerance is not set. Enter a tolerance above 0 on the operation's Actions tab."));
      return;
    }
  }
  if (handler.printResults) {
    set.push("Print results");
  }
  if (handler.resultVariable && getProperty("firmwareType") != "community") {
    error(localize("Operation \"" + getSectionComment(currentSection) + "\": 'Save results to variables, starting at' needs the community firmware (# variables). Set it to Don't save on the operation's Post Properties tab, or set the firmware to community."));
    return;
  }
  if (set.length && !(getProperty("useFirmwareOCodes") && getProperty("firmwareType") == "community")) {
    error(localize("Operation \"" + getSectionComment(currentSection) + "\" has " + set.join(", ") + " set. These need 'Use firmware O-codes' ticked and the community firmware 2.2.0c or later. Tick it, or set them off on the operation's Actions tab."));
  }
}

// Reference to this cycle, cleaned up at end
var cycleHandler = null;
var warnedProbeSensorType = false;

// onCycle will set up the global cycleHandler.
function onCycle() {
  // Other cycles (drilling, tapping, boring, ...) are expanded by onCyclePoint,
  // exactly as in the Community Post, which has no cycle handlers.
  if (!isProbeOperation()) {
    return;
  } else {
    // Current cycle is a probing cycle.
    if (getProperty("firmwareType") == "community") {
      cycleHandler = communityFirmwareCycleHandler(cycle, tool);
    } else {
      if (getOperationSetting("probeTipDiameter") == "machine") {
        error(localize("Probe tip diameter 'Machine calibration (#150)' needs the community firmware. Set it to 'Fusion tool diameter' for the stock firmware, in the Post Process dialog or on this operation's Post Properties tab."));
        return;
      }
      cycleHandler = makeraFirmwareCycleHandler(cycle, tool);
    }

    if ((cycleType == "probing-xy-inner-corner" || cycleType == "probing-xy-outer-corner") && cycle.probeSpacing > 0 &&
      getProperty("firmwareType") != "community") {
      error(localize("Operation \"" + getSectionComment(currentSection) + "\": two-point corner probing needs the community firmware (WCS rotation and # variables). Untick it on the operation, or set the firmware to community."));
      return;
    }
    if (cycleType.indexOf("probing-xy-circular-partial-") == 0 && getProperty("firmwareType") == "community") {
      // Three points closer than this give a poorly defined centre.
      var angles = [cycle.partialCircleAngleA, cycle.partialCircleAngleB, cycle.partialCircleAngleC];
      for (var i = 0; i < 3; ++i) {
        for (var j = i + 1; j < 3; ++j) {
          if (!(Math.abs((((angles[i] - angles[j]) % 360) + 540) % 360 - 180) >= 1)) {
            error(localize("Operation \"" + getSectionComment(currentSection) + "\": the three partial circle angles must be at least 1 degree apart."));
            return;
          }
        }
      }
    }
    // Item 18: stop before anything is written, naming the cycle and what the target supports.
    if (cycleHandler[cycleType].unsupported) {
      var supported = [];
      for (var name in cycleHandler) {
        if (name.indexOf("probing-") == 0 && !cycleHandler[name].unsupported) {
          supported.push(name);
        }
      }
      error(localize("Operation \"" + getSectionComment(currentSection) + "\": the probing cycle '" + cycleType + "' is not supported by this post for the " +
        getProperty("firmwareType") + " firmware." + (cycleType.indexOf("partial") >= 0 ? " Partial circular probing needs the community firmware (# variables)." : "") +
        " Supported: " + supported.join(", ") + "."));
      return;
    }
    checkProbeChecks(cycleHandler);

    writeComment("Begin " + cycleType);
    writeComment(
      "WCS used during probing: G" + calculateWCS(cycleHandler.drivingWcs)
    );
    if (cycleHandler.writeProbeResults) {
      writeComment(
        "WCS that will be updated: G" + calculateWCS(cycleHandler.targetWcs)
      );
    }
  }
}

// onCycleEnd ends a probing cycle.
function onCycleEnd() {
  if (!isProbeOperation()) {
    return;
  }
  cycleHandler = null;
  writeComment("End " + cycleType);

  // the handlers write their motion with gFormat, so the modal G0/G1 state is unknown
  gMotionModal.reset();
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
  // Not a probing cycle: let Fusion expand it into plain moves, before any move
  // of our own (a G1 to the cycle point would plunge to the hole bottom).
  if (!isProbeOperation()) {
    expandCyclePoint(x, y, z);
    return;
  }

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

  // If the first operation is a Z probe, we blocked the X,Y,Z rapid in onSection, so
  // we need to do the initial X,Y move here. Then the probe will go do its thing.
  if (isFirstOperationProbeZ()) {
    cycleHandler.absoluteMove({ x: x, y: y });
  } else {
    // Approach the cycle point as Autodesk's reference post does: going up, Z first;
    // going down, X/Y first, then a protected G38.3 down to z. If anything is in
    // the way the probe stops on it, and the next probe move halts because the
    // probe is already triggered (both firmwares), instead of a G1 pushing on.
    var current = getCurrentPosition();
    var tolerance = 0.0005; // below the 3 decimals written
    if (z > current.z + tolerance) {
      cycleHandler.absoluteMove({ z: z });
    }
    if (Math.abs(x - current.x) > tolerance || Math.abs(y - current.y) > tolerance) {
      cycleHandler.absoluteMove({ x: x, y: y });
    }
    if (z < current.z - tolerance) {
      cycleHandler.safeRelativeMove({ z: z - current.z });
    }
  }

  // Call the handler for this cycleType
  cycleHandler.setCyclePoint(x, y, z);
  cycleHandler.beginAttempts();
  cycleHandler[cycleType](x, y, z);
  cycleHandler.endAttempts();

  // Retract in to the cycle clearance height. A first-operation Z probe that
  // writes another WCS, or writes nothing, leaves the WCS the probe moves in with
  // its old, unprobed Z, so an absolute retract there could go down. Writing
  // nothing: retract to machine Z-3, the clearance height (the user's choice).
  // Writing another WCS: retract by the distance from the probed surface,
  // modelled at z - depth, to the clearance height.
  var notWritten = isFirstOperationProbeZ() && !cycleHandler.writeProbeResults;
  var otherWcs = isFirstOperationProbeZ() && cycleHandler.targetWcs > 0 && cycleHandler.targetWcs != (cycleHandler.drivingWcs || 1);
  if (notWritten) {
    warning(localize("The first operation is a Z probe with 'Write probe results to WCS' off: no Z is set. It lifts to machine Z-3 (G53), and later operations use G" +
      calculateWCS(cycleHandler.drivingWcs || 1) + "'s old Z."));
  } else if (otherWcs) {
    warning(localize("The first operation is a Z probe that moves in G" + calculateWCS(cycleHandler.drivingWcs || 1) + " and writes its result to G" + calculateWCS(cycleHandler.targetWcs) +
      ". G" + calculateWCS(cycleHandler.drivingWcs || 1) + "'s Z is not probed, so later operations that move in it use its old Z."));
  }
  if (notWritten) {
    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gFormat.format(0), "Z" + xyzFormat.format(-3));
    forceXYZ();
  } else if (otherWcs) {
    forceXYZ();
    writeBlock(gAbsIncModal.format(91), gFormat.format(0), zOutput.format(cycle.clearance - (z - cycle.depth)));
    writeBlock(gAbsIncModal.format(90));
    forceXYZ();
  } else {
    cycleHandler.absoluteRapidMove({ z: cycle.clearance });
  }
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
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    }
    if (isFirstOperationProbeZ()) {
      writeBlock(gMotionModal.format(0), x, y);
    } else {
      writeBlock(gMotionModal.format(0), x, y, z, currentSection.type == TYPE_JET ? powerOutput.format(0) : "");
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

// Laser power 0 to 1: the operation's percentage, or the Post Process dialog value.
function getLaserPower(name) {
  var value = getOperationSetting(name);
  return typeof value == "string" ? parseInt(value, 10) / 100 : value;
}

function getPower() {
  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    return getLaserPower("laserPower");
  case JET_MODE_ETCHING:
    return getLaserPower("laserEtchPower");
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
    writeStop();
    return;
  case COMMAND_POWER_ON:
    return;
  case COMMAND_POWER_OFF:
    return;

  case COMMAND_BREAK_CONTROL:
    if (getProperty("firmwareType") != "community") {
      // The stock firmware ignores the .1 and runs a full tool length calibration.
      warning(localize("Tool break control needs the community firmware. On the stock firmware M491.1 runs a full tool length calibration, so nothing is written."));
      return;
    }
    writeComment("Tool Break Test");
    writeBlock("M491.1");
    return;

  case COMMAND_STOP_SPINDLE:
    writeBlock(mFormat.format(5));
    forceSpindleSpeed = true;
    forceCoolant = true;
    if (useSpindleExt()) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(852));
    }
    spindleRunning = false;
    setExtDuty(0); // Ext is off during tool changes; the next operation switches it on again
    return;
  case COMMAND_OPTIONAL_STOP:
    if (getProperty("firmwareType") != "community") {
      warning(localize("Optional stop needs the community firmware. The stock firmware has no M1, so nothing is written."));
      return;
    }
    writeComment("Optional Stop Start");
    if (useSpindleExt()) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(852));
    }
    spindleRunning = false;
    setExtDuty(0);
    writeBlock(mFormat.format(1));
    forceSpindleSpeed = true;
    forceCoolant = true;
    writeComment("Optional Stop End");
    return;
  case COMMAND_START_SPINDLE:
    if (useSpindleExt()) {
      writeBlock(mFormat.format(400));
      writeBlock(mFormat.format(851), pwmOutput.format(100));
    }
    spindleRunning = true;
    updateExt();
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_TOOL_MEASURE:
    writeComment("Calibrate TLO");
    writeBlock(mFormat.format(491));
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
  writeActions(getOperationActions(currentSection, false));
  forceAny();
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  var retractAxes = new Array(false, false, false);
  validate(arguments.length != 0, "No axis specified for writeRetract().");

  for (var i in arguments) {
    retractAxes[arguments[i]] = true;
  }

  var safeYPosition = getProperty("yAxisSafePosition");

  if (retractAxes[0] && retractAxes[1] && retractAxes[2]) {
    if (getProperty("returnClearance")) {
      writeBlock(gFormat.format(28));
    }
  } else if (retractAxes[1] && retractAxes[2] && safeYPosition != 0) { // Y and Z
    gMotionModal.reset();
    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Y" + xyzFormat.format(toPreciseUnit(safeYPosition, MM)), "Z" + xyzFormat.format(toPreciseUnit(-3, MM)));
  } else if (retractAxes[2]) { // Z only
    gMotionModal.reset();
    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Z" + xyzFormat.format(toPreciseUnit(-3, MM)));
  }
}

var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;
var forceCoolant = false;

// Ext port. The old settings apply only when 'Enable PWM-based Ext' is unticked.
function useSpindleExt() {
  return !getProperty("usePwmExt") && getProperty("defaultUseExternalControl");
}

function useExtForAir() {
  return !getProperty("usePwmExt") && getProperty("useExtForAirCoolant");
}

// PWM-based Ext: each appliance adds its PWM value to the port while it is on.
var extDuty = 0; // the value the port is at
var spindleRunning = false;
var extForced = {}; // appliance id -> true (ExtOn:<appliance>) or false (ExtOff:<appliance>)
var extAppliances = [
  {name:"Air", id:"extAir"},
  {name:"Shop vac", id:"extShopVac"},
  {name:"Mist", id:"extMist"},
  {name:"Other", id:"extOther"}
];

function getCoolantSwitchId(coolant) {
  switch (coolant) {
  case COOLANT_AIR: return "air";
  case COOLANT_AIR_THROUGH_TOOL: return "airThroughTool";
  case COOLANT_MIST: return "mist";
  case COOLANT_SUCTION: return "suction";
  case COOLANT_FLOOD: return "flood";
  case COOLANT_THROUGH_TOOL: return "throughTool";
  case COOLANT_FLOOD_MIST: return "floodMist";
  case COOLANT_FLOOD_THROUGH_TOOL: return "floodThroughTool";
  }
  return "off";
}

/** The appliances that are on with this coolant mode, and the spindle running or not. */
function getExtAppliances(coolant, spindle) {
  var on = [];
  for (var i = 0; i < extAppliances.length; ++i) {
    var trigger = getProperty(extAppliances[i].id + "Switch");
    var forced = extForced[extAppliances[i].id];
    if (forced === true || (forced === undefined && ((trigger == "spindle" && spindle) || (trigger != "spindle" && trigger == getCoolantSwitchId(coolant))))) {
      on.push(extAppliances[i]);
    }
  }
  return on;
}

function getExtDuty(appliances) {
  var duty = 0;
  for (var i = 0; i < appliances.length; ++i) {
    duty += getProperty(appliances[i].id + "Duty");
  }
  return Math.min(duty, 100);
}

function setExtDuty(duty) {
  if (!getProperty("usePwmExt") || duty == extDuty) {
    return;
  }
  writeBlock(mFormat.format(400)); // M851/M852 act when read
  if (duty > 0) {
    writeBlock(mFormat.format(851), pwmOutput.format(duty));
  } else {
    writeBlock(mFormat.format(852));
  }
  extDuty = duty;
}

function updateExt() {
  if (getProperty("usePwmExt")) {
    setExtDuty(getExtDuty(getExtAppliances(currentCoolantMode, spindleRunning)));
  }
}

/** onOpen: checks the PWM values, and warns when the values that are on together do not add up. */
function checkPwmExt() {
  var connected = 0;
  for (var i = 0; i < extAppliances.length; ++i) {
    var duty = getProperty(extAppliances[i].id + "Duty");
    if (!(duty >= 0 && duty <= 100 && duty == Math.floor(duty))) {
      error(localize("'" + extAppliances[i].name + ": PWM value (%)' is " + duty + ". Enter a whole number from 0 to 100."));
      return;
    }
    if (getProperty(extAppliances[i].id + "Switch") != "none") {
      ++connected;
    }
  }
  if (connected == 0) {
    warning(localize("'Enable PWM-based Ext' is ticked, but every appliance is set to Not connected, so the Ext port stays off."));
  }
  var sets = {}; // sum -> the appliances that give it
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    var probe = section.getTool().type == TOOL_PROBE;
    var on = getExtAppliances(probe ? COOLANT_OFF : section.getTool().coolant, !probe);
    if (on.length == 0) {
      continue;
    }
    var names = [];
    var sum = 0;
    for (var j = 0; j < on.length; ++j) {
      names.push(on[j].name);
      sum += getProperty(on[j].id + "Duty");
    }
    names = names.join(" + ");
    var operation = section.hasParameter("operation-comment") ? section.getParameter("operation-comment") : String(i + 1);
    if (sum > 100) {
      warning(localize("Operation \"" + operation + "\": the Ext port PWM values of " + names + " add up to " + sum + "%. The port gets 100%. Lower the values so they add up to 100 or less."));
    }
    if (sets[sum] != undefined && sets[sum] != names) {
      warning(localize("Operation \"" + operation + "\": " + names + " and " + sets[sum] + " both give the Ext port " + Math.min(sum, 100) + "%, so a decoder cannot tell them apart. Give the appliances different PWM values."));
    }
    sets[sum] = names;
  }
}

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
    updateExt();
    return undefined;
  }
  updateExt();
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
    if (currentCoolantMode == COOLANT_AIR && useExtForAir()) {
      currentCoolantMode = coolant;
      return [mFormat.format(400), mFormat.format(852)];
    }
  } else {
    coolantOff = coolantCodes.off;
    if (coolant == COOLANT_AIR && useExtForAir()) {
      currentCoolantMode = coolant;
      return [mFormat.format(400), "M851S100"];
    }

    m = coolantCodes.on;
  }

  if (!m && getProperty("usePwmExt") && getExtAppliances(coolant, false).length) {
    currentCoolantMode = coolant; // no M-code: only the Ext port appliances switch (updateExt)
    for (var i in multipleCoolantBlocks) {
      if (typeof multipleCoolantBlocks[i] == "number") {
        multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
      }
    }
    return multipleCoolantBlocks.length ? multipleCoolantBlocks : undefined;
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
  executeManualNC(); // Manual NC after the last operation
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
  writeActions(getSettingActions("actionsAtEnd", "Actions at end"));
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
  if (isRedirecting()) {
    closeRedirection();
  }
  previousToolChangeWasManual = false;
}

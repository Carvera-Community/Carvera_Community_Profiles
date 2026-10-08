# Carvera Community Probing Post v2.0.0

The Community Fusion 360 post (`Carvera.cps`) with WCS probing, Ext PWM appliances, actions, and per-operation probing and laser settings.

- Install: as `Carvera.cps` in the [README](../../README.md#install-postprocessor). Fusion lists it as **Makera Carvera Community Probing Post v2.0.0**.
- Firmware: set **Carvera Machine Firmware Type** to match the machine. Community is the default.

## Contents

1. [Settings: who overrides whom](#1-settings-who-overrides-whom)
2. [Risks by property](#2-risks-by-property)
3. [Stock firmware](#3-stock-firmware)
4. [Community firmware](#4-community-firmware)
5. [First operation a Z probe](#5-first-operation-a-z-probe)
6. [Machine probe tip calibration](#6-machine-probe-tip-calibration)
7. [Ext PWM](#7-ext-pwm)
8. [Failed probe check](#8-failed-probe-check)
9. [Override driving WCS](#9-override-driving-wcs)
10. [Write probe results to WCS](#10-write-probe-results-to-wcs)
11. [Probe result: Modelled position or Set feature to 0](#11-probe-result-modelled-position-or-set-feature-to-0)
12. [Park position](#12-park-position)
13. [Laser power](#13-laser-power)
14. [Upgrading from v1.4.6](#14-upgrading-from-v146)
15. [Test part: Probing_Strategies.f3z](#15-test-part-probing_strategiesf3z)

## 1. Settings: who overrides whom

Highest first:

| Level | Where | Applies to |
|---|---|---|
| Posting errors | — | A setting the firmware cannot carry out stops posting, whatever else is set |
| Operation | Operation → Post Properties tab | That operation. "Same as Post Process dialog" (the default) defers to the dialog |
| Post Process dialog | Post Process → Properties | Every operation |
| Fusion operation fields | Operation tabs (feeds, checks, Print results, override WCS) | Read by the post; some need post settings (below) |

Settings that switch others off or depend on them:

| Setting | Effect on others |
|---|---|
| Carvera Machine Firmware Type = Stock | Community-only settings stop posting (§3) |
| Enable PWM-based Ext ticked | Spindle-based External Control and Use Ext For Air Coolant are ignored |
| Use firmware O-codes unticked | Fusion checks set to "Stop and display message" and Print results stop posting, unless Failed probe check is Ignore and continue (checks are left out; Print still needs O-codes) |
| Failed probe check = Ignore and continue | Probe attempts and Park position are unused |
| Failed probe check ≠ Pause, then probe again | Probe attempts, Park position, Park X/Y unused |
| Park position = Machine clearance position | Park position X/Y unused |
| Write probe results to WCS = Off | Probe result has no effect (nothing is written); Print, Save and checks still run |
| Probe tip diameter = Machine calibration | Fusion's probe tool diameter is not used for results |
| Pause for high-speed probe moves = No pause | The posting warning still appears |
| Split file = Split by toolpath | Each file gets its own header, Actions at start and Actions at end |

Action order around a tool change: coolant off → **Actions before every tool change** → `M6` → **Actions after every tool change** → **Before this operation** → spindle on → operation → **After this operation**. Tags in the operation name (`Pocket1 [LightOn] [Pause:Check clamps]`) run with Before this operation.

## 2. Risks by property

| Property | Setting | Risk | When |
|---|---|---|---|
| Write probe results to WCS | Off (default) | Probing changes nothing; later toolpaths run in the old WCS | Always: turn it on to set the WCS |
| Write probe results to WCS | On | The WCS moves to the probed part | A bad touch (chip, wrong face) moves the WCS; use checks |
| Probe result | Set feature to 0 | Toolpaths cut in the wrong place | The setup origin in Fusion is not the probed feature |
| Probe result | Modelled position | None beyond the model | The part must match the model near the probed feature |
| Failed probe check | Ignore and continue (default) | An out-of-tolerance result is written without stopping | A displaced or wrong part; Write on |
| Failed probe check | Pause | Resume carries on with the bad result | Operator resumes instead of aborting |
| Failed probe check | Pause, then probe again | Head collides on return | WCS changed or head lowered while paused |
| Probe attempts | — | After the last attempt, the bad result is used | Part still wrong |
| Probe tip diameter | Machine calibration | Results off by the error in #150 | Not calibrated, or another stylus fitted since |
| Probe feeds | Fusion's feeds | Fast touches: overshoot, stylus damage | Lead-In or Measure feeds high in the tool |
| Warn when probe moves are faster than | High limit | Fast moves without a pause | Pause = No pause |
| Probe Sensor Type | Wrong (stock) | Machine halts at the first probe move | Stock firmware only |
| Save results to variables | #501–#520 | EEPROM wear; old values remain | Saved on every run |
| Park position | Custom | Collision at the park X/Y | X/Y over a clamp or fixture |
| First operation Z probe, write Off | — | Later operations use the old Z | §5 |
| Override driving WCS | — | Probe moves in a WCS that is not set | §9 |
| Enable PWM-based Ext | Values add over 100 | Wrong appliance on (decoder) | Several appliances on together |
| Laser power | Set from an older build | Invalid value | §13 |
| Use sequence numbers | Yes / Only on tool change | Stock ignores numbered lines | Stops posting on stock |

## 3. Stock firmware

| Status | What |
|---|---|
| Expected to work | X, Y, Z, inner corner and outer corner probing (single point); Write probe results, Probe result, Probe feeds, high-speed pause, Probe tip diameter = Fusion tool diameter; Probe Sensor Type NO/NC; result to another WCS (the post switches WCS around `G10 L20`); Failed probe check = Ignore and continue; Actions (those with stock codes); Display/Print message as comments + pause; Laser power; Split file |
| May work (in firmware source, not machine-tested) | Enable PWM-based Ext (`M851 S`, `M332.3` exist in stock source) |
| Will not work (posting stops) | Width, channel, wall, boss, hole, island, partial circular, angle probing; two-point corners; Use firmware O-codes; Failed probe check = Pause / Pause, then probe again with any check set; Print results; Save results to variables; Machine calibration (#150); Use sequence numbers; Collet changes; Tool change parameters from tool comment; Manual Tool Change Behavior = Carvera Community |
| Will not work (skipped, warning) | Flex compensation (`M380.3`), Tool break (`M491.1`), Optional stop (`M1`), Call program (`M98`), console messages (`M118`) |

## 4. Community firmware

Community-only features and how to turn them on:

| Feature | Set |
|---|---|
| All 22 probing cycles, incl. partial circular and angle | Nothing extra |
| Two-point corners | Fusion: corner operation, probe spacing > 0 |
| Fusion checks (Out of position, Wrong size, Angle askew) | Fusion Actions tab: "Stop and display message"; dialog: Use firmware O-codes; Failed probe check = Pause or Pause, then probe again |
| Print results | Fusion Actions tab: Print results; Use firmware O-codes. Optional Print results prefix |
| Save results | Operation: Save results to variables (deviation from model, one variable per value) |
| Machine tip diameter | Probe tip diameter = Machine calibration (#150) (§6) |
| Collet changes, tool comment parameters, sequence numbers | Their properties |

Look out for:

- **Firmware 2.2.0c or later** for O-codes. Older community firmware ignores `O` lines: every check would pause.
- **Taken variables:** `#1`–`#30` (subprograms), `#101`–`#111` and `#120` (this post's probing). Don't use them in macros that run between probes.
- **Partial circular:** angles at least 1° apart; Fusion's approach distance must fit between the probed wall and an island.
- **NC probe:** set in the firmware config; the post always uses `G38.2/G38.3`.
- **While paused** (Pause, then probe again): don't change the WCS or lower the head.

## 5. First operation a Z probe

At the start, the head is at an unknown height relative to the WCS that has not yet been probed. A normal retract (`G0 Z<clearance>` in the WCS) uses that WCS's old Z, which may lie below the head: the retract can go **down**.

| Case | Retract | Why |
|---|---|---|
| Writes to the WCS it moves in | `G0 Z<clearance>` in the WCS | Its Z was just set |
| Writes nothing (Write probe results Off) | `G90 G53 G0 Z-3` | Machine Z-3 is near the top whatever any WCS holds: always upward. Warning: later operations use the old Z |
| Writes another WCS (override) | `G91 G0 Z<lift>` relative | The moving WCS is still unset; warning |

Moves after the cycle in that operation carry no Z.

## 6. Machine probe tip calibration

1. On the Controller, with the probe fitted, centre it in a bore of known size.
2. Run `M460 X<d> Y<d>` (bore), `M460.2 X<d>` (boss) or `M460.3` (anchor 2). The diameter goes to `#150`.
3. To keep it after a restart: `config-set sd zprobe.probe_tip_diameter <value>`.
4. In Fusion, Post Process → **Probe tip diameter** = **Machine calibration (#150)** (or per operation).
5. Post. Results now subtract `#150/2` on the machine, read when the program runs.

Notes: community firmware only. Recalibrate after changing stylus. Diameter results (bosses, holes) also use it.

## 7. Ext PWM

**Hardware**

- Ext port: a PWM output switched by `M851 S<0–100>` / `M852`. On the Air it runs at 50 Hz.
- One appliance: a relay or SSR on the port; use PWM value 100.
- Several appliances: a PWM decoder that switches a channel per duty band. Set each appliance's PWM value so the ones on together add up to a unique total of 100 or less.
- HALT cuts the port.

**Setup**

1. Post Process → 3. External control → tick **Enable PWM-based Ext**.
2. For each appliance (Air, Shop vac, Mist, Other): **switched by** = a coolant mode, With the spindle, or Not connected.
3. Set each **PWM value (%)**.

**Behaviour and caveats**

- Program start writes `M332.3` (firmware's own Auto Ext Out off).
- The port gets the sum of the appliances that are on; over 100 is clamped, with a warning. Two sets with the same sum give a warning (decoder can't tell them apart).
- Off during pauses and tool changes; back on after.
- Probing operations switch no appliances.
- Ticked: **Spindle-based External Control** and **Use Ext For Air Coolant** are ignored. Unticked: they work as before.
- Actions: `ExtOn` / `ExtOff` switch the whole port (100% / off); `ExtOn:Air`, `ExtOff:ShopVac` etc. switch one appliance in the sum.

## 8. Failed probe check

Applies to Fusion's Out of position, Wrong size and Angle askew checks set to "Stop and display message".

| Option | On the machine |
|---|---|
| **Ignore and continue** (default) | Checks are left out (posting warns). The result is written if Write is on. Print and Save still work. Posts on stock |
| **Pause** | Message, then `M600`. Abort in the Controller, or resume to continue with the result |
| **Pause, then probe again** | Message, Z up, move to the park position, pause. Fix the part, resume: the operation probes again. After **Probe attempts** tries, the last pause resumes with the out-of-tolerance result |

- Pause options need community firmware 2.2.0c+ and **Use firmware O-codes**.
- A first-operation Z probe never re-probes; it pauses as **Pause**.
- Set per operation on its Post Properties tab.

## 9. Override driving WCS

Fusion probing operation → Actions tab → **Override driving WCS**: the probe *moves* in the WCS chosen there, while the result is still written to the setup's WCS. Each probe operation prints both: "WCS used during probing" and "WCS that will be updated".

Use: probe a part from a roughly set fixture WCS (e.g. G59) and write the exact offset to the setup WCS (e.g. G54).

Implications:

- The driving WCS must be set closely enough that the probe reaches the part safely.
- The result never goes to the driving WCS.
- Stock firmware writes `G10 L20` to the *active* WCS; the post switches to the target, writes, and switches back.
- First operation Z probe that writes another WCS: relative lift and warning (§5).

## 10. Write probe results to WCS

| Setting | Result |
|---|---|
| **Off** (default) | The operation probes, checks, prints and saves, but changes no WCS. Use it to verify a part or record measurements |
| **On** | The result is written with `G10 L20 P<n>` to the WCS of the setup the operation belongs to |

Per operation: "Same as Post Process dialog", "Yes, for this operation", "No, for this operation".

Implications: with Off, later operations run in whatever the WCS held before. A first-operation Z probe with Off lifts to machine Z-3 (§5).

## 11. Probe result: Modelled position or Set feature to 0

What coordinate the probed feature gets. Example: a boss drawn at X135 Y45, real part 0.3 mm off in X.

| | **Modelled position** (default) | **Set feature to 0** |
|---|---|---|
| Boss centre after probing | X135 Y45, as in the model | X0 Y0 |
| WCS origin | Stays at the Fusion setup origin, moved 0.3 mm to follow the part | Moves onto the boss |
| Following toolpaths (programmed from the setup origin) | Cut in the right place | Cut 135 / 45 mm away, unless the setup origin is the boss |
| Several probes (X, Y, Z from different faces) | Build the same origin together | Each moves the origin onto its own feature |

- Use **Modelled position** unless the setup origin is the probed feature itself; then both give the same result.
- **Set feature to 0** is what the Community Post always did.
- Only matters with Write probe results on.

## 12. Park position

Used only by **Pause, then probe again**: where the head waits for you to fix the part.

| Option | Move |
|---|---|
| **Machine clearance position** (default) | `G28`: the clearance position from the machine's `config.txt` (`coordinate.clearance_x/y/z`), Z first |
| **Custom** | `G90 G53 G0 Z-3`, then `G53 G0 X<Park X> Y<Park Y>` (machine coordinates). Defaults X-5 Y-21 (Air clearance); C1: X-75 Y-3 |

Resume returns from the park position straight to the probe start: leave the head high.

## 13. Laser power

| | v1.4.6 | v2.0.0 |
|---|---|---|
| Laser power (dialog) | Number 0–1 (default 1) | Drop-down 0–100% (default 100%) |
| Laser etch power (dialog) | Number 0–1 (default 0.1) | Drop-down 0–100% (default 10%) |
| Per operation | — | Laser power / Laser etch power: Same as Post Process dialog, or 0–100% |

The S word is unchanged (percent / 100). Settings saved as numbers by an older build are not valid choices: set both once in the dialog.

Laser operations also now get their WCS, positioning, `M3` and Ext like other operations.

## 14. Upgrading from v1.4.6

1. **Write probe results to WCS** is Off: turn it on (dialog or operation) where probing must set the WCS.
2. **Probe result** is Modelled position: check §11; choose Set feature to 0 for the old behaviour.
3. Set **Laser power** and **Laser etch power** once.
4. "Write Tool# and Header To Each Split By Toolpath File" is gone: Split file has **Split by toolpath** (with header) and **Split by toolpath, no header**.
5. Re-post every probing program: probe moves were fixed (starts, overtravel, corner step, protected approaches).
6. If posting stops, the message names the setting and the fix.

## 15. Test part: Probing_Strategies.f3z

`Probing_Strategies.f3z` (same folder): a Fusion design with one operation for each Fusion probing strategy (single surfaces, walls, channels, bosses, holes, corners, plane angles, partial circular), set up for the Carvera's 3D probe.

1. In Fusion: File → Open → Open from my computer → `Probing_Strategies.f3z`.
2. Manufacture workspace → select the operations → Post Process with this post.
3. Check the output, or run it on the machine with the part in place.

Tested on a Carvera Air, community firmware, with the part in its expected position and offset 2 mm from it.

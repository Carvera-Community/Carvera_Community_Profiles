(1001)
(Machine)
(  vendor: Makera)
(  model: Carvera 3-axis Community Version 1.17)
(  description: Makera Carvera 3-axis Community Version 1.17)
(T7  Test Probe      D=2 CR=1 - ZMIN=-23 - probe)
G90 G94
G17
G21

(probing-z)
M6 T7
G54
G0 X-60 Y-60
Z25.08
(begin probing-z - carveraStock firmware - target WCS 1)
G1 Z5.08 F500
(begin touchProbe)
G38.2 Z-20.08 F200
G38.3 Z4 F500
G38.2 Z-20.08 F100
(end touchProbe)
G10 L20 P1 Z-15
G1 Z5.08 F500
(end probing-z)
G0 X-60 Y-60 Z25.08

(probing-x)
Z55
X-77 Y-60
(begin probing-x - carveraStock firmware - target WCS 1)
G1 Z5 F500
G38.3 Z-22 F500
(begin touchProbe)
G38.2 X14.16 F200
G38.3 X-4 F500
G38.2 X14.16 F100
(end touchProbe)
G10 L20 P1 X-72
G1 X-77 F500
G1 Z5 F500
(end probing-x)
G0 X-77 Y-60 Z55

(probing-y)
X-60 Y-77
Z25.08
(begin probing-y - carveraStock firmware - target WCS 1)
G1 Z5.08 F500
G38.3 Z-22.08 F500
(begin touchProbe)
G38.2 Y14.16 F200
G38.3 Y-4 F500
G38.2 Y14.16 F100
(end touchProbe)
G10 L20 P1 Y-72
G1 Y-77 F500
G1 Z5.08 F500
(end probing-y)
G0 X-60 Y-77 Z25.08

(probing-xy-outer-corner)
X-77 Y-77
Z25.08
(begin probing-xy-outer-corner - carveraStock firmware - target WCS 1)
G1 Z5.08 F500
G38.3 Z-22.08 F500
(probing x surface)
G38.3 Y10 F500
(begin touchProbe)
G38.2 X15.16 F200
G38.3 X-4 F500
G38.2 X15.16 F100
(end touchProbe)
G10 L20 P1 X-72
G1 X-77 F500
G1 Y-77 F500
(probing y surface)
G38.3 X10 F500
(begin touchProbe)
G38.2 Y15.16 F200
G38.3 Y-4 F500
G38.2 Y15.16 F100
(end touchProbe)
G10 L20 P1 Y-72
G1 Y-77 F500
G1 X-77 F500
G1 Z5.08 F500
(end probing-xy-outer-corner)
G0 X-77 Y-77 Z25.08

(probing-xy-inner-corner)
X-37 Y-67
Z25.08
(begin probing-xy-inner-corner - carveraStock firmware - target WCS 1)
G1 Z5.08 F500
G38.3 Z-28.08 F500
(probing x surface)
(begin touchProbe)
G38.2 X-14.16 F200
G38.3 X4 F500
G38.2 X-14.16 F100
(end touchProbe)
G10 L20 P1 X-42
G1 X-37 F500
(probing y surface)
(begin touchProbe)
G38.2 Y-14.16 F200
G38.3 Y4 F500
G38.2 Y-14.16 F100
(end touchProbe)
G10 L20 P1 Y-72
G1 Y-67 F500
G1 Z5.08 F500
(end probing-xy-inner-corner)
G0 X-37 Y-67 Z25.08
M5
G28
M30


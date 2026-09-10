# FreeCAD thread-mill geometry

The converter must export `NeckDiameter`, `NeckLength` and `Crest` explicitly.
For the shipped tools these correspond to the HSM body's `shoulder-diameter`,
`shoulder-length` and point-tip declaration. The source is:

`CAM_Post_Processors/Fusion360-profiles/Tool Files/hsmlib/Makera Thread Mills.hsmlib`

CSV fields are read by their Fusion parameter identifiers. For known tools,
use the HSM dimensions after checking the description, main dimensions and
CSV neck geometry. Allow only six-significant-digit CSV rounding; preserve
the full HSM precision. Unknown tools with complete CSV geometry still work.
Missing fields require a matching HSM entry. Missing or conflicting source geometry is an error, not an
invitation to keep FreeCAD template defaults. No dimensions are guessed from
the tool's M-size.

Keep `fusionToolToFreecad.py` and `threadmill_geometry.py` together. Within the
repository the HSM fallback is found automatically. For a standalone copy,
pass `--threadmill-library /path/to/Makera\ Thread\ Mills.hsmlib`, or provide
complete neck and tip geometry in the CSV. Normal conversion still reads CSVs
from the current working directory and writes to `output`.

Only the neck dimensions and point-tip crest are corrected. Feeds, speeds,
other parameters and shape files are not changed. The exact source precision
is kept for the small necks. Numeric lengths from millimeters and inches are
converted to explicit millimeter quantities for these three parameters.

From the repository root (Python 3.9 or later, standard library only):

```sh
# Read-only consistency check against HSM source.
python3 CAM_Post_Processors/Freecad/FusionCSVToFreecadTool/sync_threadmills.py

# Apply the three-parameter correction to the committed .fctb files.
# Use a clean Git worktree and review the resulting diff.
python3 CAM_Post_Processors/Freecad/FusionCSVToFreecadTool/sync_threadmills.py --write

# Unit tests, source consistency, idempotence and full CSV regeneration.
python3 -m unittest discover \
  -s CAM_Post_Processors/Freecad/FusionCSVToFreecadTool/tests \
  -p test_threadmills.py -v
```

Changing `Crest` may change thread-milling radii. Reload library tools and
recompute/check existing operations before machining. A valid simplified
solid is not a certification of the physical tool, clearances or G-code.

---
name: import-from-eagle-to-kicad
description: >-
  Guide a user through importing an Autodesk Eagle design (.sch/.brd) into KiCad and cleaning it
  up. Covers reading the Eagle XML, building a warning-free layer map, the GUI import, the
  save-on-import gotcha, and the standard post-import board DRC + schematic ERC fixes. Use whenever
  the user wants to import/convert/migrate an Eagle project into KiCad, or is debugging a failed or
  partial Eagle import (e.g. "the schematic didn't import", missing board outline, fresh-import DRC
  errors). Ships an `eagle_kicad_tools.py` helper (stdlib-only) for the scriptable steps.
---

# Importing an Eagle project into KiCad

You are guiding a (possibly non-EE) user. The Eagle import itself is **GUI-only** — neither
`kicad-cli` nor the KiCad MCP can perform it. Your job: **prepare** (parse the Eagle XML, build the
layer map — scriptable), **instruct** the GUI steps with exact click-paths, then **clean up and
verify** the result on disk (scriptable). Work through the phases in order. Commit (or have the user
commit) the as-imported baseline first, then each fix as its own scoped commit.

## The tool

A stdlib-only helper lives at `<skill-dir>/eagle_kicad_tools.py`. Run analysis commands freely;
the **edit** commands mutate a file in place, so make sure it's committed/backed up first (they print
the parenthesis balance after — it must stay 0).

```
python3 <skill-dir>/eagle_kicad_tools.py <command> ...
  summary <f.sch>                 outline-layer <f.brd>      layer-scan <f.brd>
  propose-layer-map <f.brd>       refint <f.sch>             nonascii <f.sch>
  pad-positions <f.kicad_pcb> [--ref R]                      solve-transform <f.brd> <pcb>
  paren-check <f>                 bisect <f.sch> <N> <out.sch>
  set-pad-net <pcb> --ref R --pad P --net NET
  remove-block <pcb> --head '(segment' --contains S [S ...]
  ignore-severities <f.kicad_pro> --rules a,b,c
  name-user-layers <pcb> --map "User.1|front|Name;User.2|back|Name;User.3|user|Name"
```

For everything about **driving KiCad itself** — the three edit/verify paths (direct file edit, the
MCP `kicad` server, the `kipy` IPC API), running DRC/ERC, the "KiCad is open → File → Revert" hazard,
the headless-ERC bug + fixed fork build, and the context7 doc sources — **load the `kicad-interaction`
skill**. This skill covers only the steps *specific to an Eagle import*; it does not repeat those rules.

---

## Phase 0 — Understand the source
`summary <f.sch>` → Eagle version, sheet/part counts, libraries. Eagle ≥ v6 files are XML; no Eagle
license needed. If ground-truth connectivity matters, capture the Eagle netlist (schematic
`<pinref>` ↔ board `<contactref>`) into a `NETLIST.md` up front — it makes verification provable.

## Phase 1 — Find the board-outline layer (CRITICAL)
`outline-layer <f.brd>` → the layer whose wires span the whole board. **Trap:** it's often a custom
`Outline` layer (e.g. 120), **not** `Dimension` (20). Map **that** layer to `Edge.Cuts`, or the board
imports with no edge.

## Phase 2 — Attribute every populated layer, and GET THE USER'S APPROVAL
Every Eagle layer that carries graphics must be mapped, or the import warns "Ignoring a wire … not
mapped". Run **`propose-layer-map <f.brd>`** — it lists every populated layer and proposes a target:
the detected outline → `Edge.Cuts`, standard layers by the table below, and **every leftover parked on
a `User.n` layer with a suggested meaningful name and KiCad layer type** (so the design never ends up
with cryptic, unlabeled `User.1…6`). Standard correspondence:

| Eagle | KiCad | Eagle | KiCad |
|---|---|---|---|
| `Top*`/`Bottom*` | `F.Cu`/`B.Cu` | `tStop`/`bStop` | `F.Mask`/`B.Mask` |
| `tNames`/`bNames`, `tPlace`/`bPlace` | `F./B.Silkscreen` | `tCream`/`bCream` | `F.Paste`/`B.Paste` |
| `tValues`/`bValues`, `tDocu`/`bDocu` | `F.Fab`/`B.Fab` | `tGlue`/`bGlue` | `F./B.Adhesive` |
| **`Outline` (custom edge)**, `Dimension` | `Edge.Cuts` | `tKeepout`/`bKeepout` | `F./B.Courtyard` |
| `Unrouted` | `User.Drawings` | `dxf`/`Reference`/`Document` | `User.Comments` |

**Leftovers with no standard KiCad equivalent → `User.1…9`** — but don't leave them bare. Give each a
**descriptive name** and the correct **KiCad layer type**:
- **Auxiliary** (`user`) — annotation with no side: `Measures`/dimensions, `Descript`/docu text.
- **Off-board, front** (`front`) / **Off-board, back** (`back`) — side-specific *non-fab* layers:
  `tRestrict`/`bRestrict` (copper keepout), `tNoCream`/`bNoCream` (no-paste). ⚠️ These types are
  **documentation labels only — no fab effect**; real paste/copper live on `F.Paste`/`B.Paste`/`*.Cu`.
- **Watch for mis-named Eagle layers:** e.g. Eagle layer **131** (the standard `tNoCream` slot) is
  sometimes mis-named `"132"`; it's the top counterpart of `bNoCream` (#132), *not* junk — rename it
  `tNoCream`. The proposer can't infer this from a garbled name, so eyeball coincident rectangles.

**Present the full scheme to the user and get explicit approval of names + types before importing** —
they may prefer different names. `propose-layer-map` prints a ready-to-apply
`name-user-layers --map "…"` string; save it for Phase 4. If the import dialog can save a layer
mapping preset, have the user save it too.

## Phase 3 — Run the import (user, GUI)
Tell the user: **File → Import → Non-KiCad Project** → select the `.sch` (the `.brd` must be beside
it, same basename) → choose a **fresh empty destination directory** → apply the Phase-2 mapping in the
layer dialog (this dialog is the *board* half only; the schematic has no layer map).

### ⚠️ THE SAVE GOTCHA — state this up front, it's the #1 time-sink
The importer **parses both board and schematic and loads them into memory**, but **auto-saves
neither**, and it raises the schematic editor first then the board, so **the board window shadows the
schematic window** (looks like only the board imported). Any reload-from-disk ("Switch to Schematic
Editor") throws **"…kicad_sch not found"** because the schematic is only in memory.
**Resolution — tell the user:** after the import, **save the PCB → move/close its window → save the
schematic** (or just **close KiCad**, which prompts to save both). Either persists all files.

### If the schematic truly won't import — diagnose, don't thrash
- It is **not** a layer-mapping issue (schematic has no layer map). `Outline→Edge.Cuts` is board-only.
- `refint <f.sch>` → a dangling part→library reference can crash the converter.
- `nonascii <f.sch>` → umlauts/`°`/`×`/`®`; usually harmless (descriptions import fine) but cheap to
  rule out by transliterating to ASCII and re-importing.
- `bisect <f.sch> 1 out.sch` (then 2) → import each to localize the failing sheet/element.
- Capture the real error: quit KiCad fully (single-instance), then
  `/Applications/KiCad/KiCad.app/Contents/MacOS/kicad 2>&1 | tee /tmp/kicad.log` and re-import.
- Read the source if needed: `eeschema/sch_io/eagle/sch_io_eagle.cpp`, `kicad/import_proj.cpp`,
  `eeschema/files-io.cpp`, `eeschema/cross-probing.cpp`.

## Phase 4 — Name & type the User layers, then document the map
The importer parks leftovers on **generic `User.1…9` with no name and `Auxiliary` type** — it does
**not** apply the names/types approved in Phase 2. Apply them now, either way (both reliable):
- **GUI:** PCB Editor → **File → Board Setup → Board Editor Layers** → for each user row set the
  **Name** and the **Type** dropdown (Auxiliary / Off-board front / Off-board back) → OK → **Ctrl+S**.
- **On disk (KiCad closed):** run the `name-user-layers` string from Phase 2, e.g.
  `name-user-layers <f.kicad_pcb> --map "User.1|front|tRestrict.Keepout.Top;User.3|user|Measures.Dims;…"`
  — it rewrites the rows in `(layers …)` to `(39 "User.1" front "tRestrict.Keepout.Top")` (type token
  is `user`/`front`/`back`); leaves the body `(layer "User.n")` references untouched. `paren-check` after.

**Then document the mapping** — it's the only record of what the User layers mean. Write a `README.md`
in the KiCad project dir with a table (*KiCad layer | name | type | Eagle layer (#) | content | what
it is*), note the front/back-is-label-only caveat and any mis-named layers, and add a one-line pointer
in any project `CLAUDE.md`. Commit the renames + docs as one scoped commit.

## Phase 5 — Clean the board (scriptable; commit each fix)
`run_drc`, then work by category below. Follow the file-edit discipline from the `kicad-interaction`
skill after each edit (re-open the project, re-DRC, confirm `paren-check` is 0).

- **`shorting_items` + `solder_mask_bridge` on a fine-pitch part** — Eagle NC/aux pads import with no
  net while their stubs keep the pin-name net → false short. The DRC location sits on the pad; map pad
  number → stub net, then `set-pad-net <pcb> --ref IC1 --pad 14 --net IN14` for each. Restores the
  original connectivity; changes no copper.
- **`invalid_outline` ("not a closed shape")** — stray `fp_line`/`gr_line` on `Edge.Cuts` (often
  connector body marks from `Dimension→Edge.Cuts`) branch the outline. Delete them, e.g.
  `remove-block <pcb> --head '(fp_line' --contains '(start 0 -5.588)' 'Edge.Cuts'`.
- **`track_dangling`** — leftover GND antenna stubs that dead-end in free space. Get coords from the
  warnings, identify the segment's UUID, `remove-block <pcb> --head '(segment' --contains '<uuid>'`.
  Prefer deleting stubs over silencing `track_dangling` globally (keep it catching real opens).
- **`copper_edge_clearance` at edge-launch connectors (SMA)** — copper reaches the edge by design.
  Add a **scoped** rule to `<project>.kicad_dru`. Imported footprints often lack a courtyard, so scope
  **by net** (find the connector pad nets via `pad-positions --ref X1`), using `A.NetName || B.NetName`
  (edge-clearance is checked in either order):
  ```
  (version 1)
  (rule "Edge-launch connectors may reach the board edge"
  	(condition "A.NetName == 'GND' || A.NetName == 'N$2' || A.NetName == 'N$3' ||
  	            B.NetName == 'GND' || B.NetName == 'N$2' || B.NetName == 'N$3'")
  	(constraint edge_clearance (min 0mm)))
  ```
- **Cosmetic noise** (`text_height`, `via_dangling`, `silk_*`, a benign `courtyards_overlap`) — these
  are inherent to Eagle imports. `ignore-severities <f.kicad_pro> --rules text_height,via_dangling,silk_overlap,silk_over_copper,silk_edge_clearance,courtyards_overlap`.
  Don't silence reflexively — fix root causes where cheap, document why in the commit.
- **Caveats on "0 violations":** imported zones are **unfilled** — have the user do **Edit → Fill All
  Zones (`B`)**; and with no schematic netlist linked, DRC checks **geometry only**, not connectivity.

## Phase 6 — Clean the schematic (ERC)
Routine fresh-import items (none mean a bad import): add **`PWR_FLAG`** to each power net (Eagle has no
equivalent); add **no-connect flags** to intentionally-unconnected pins; clear **dangling wire stubs**;
**configure the footprint library**. Eagle schematics import **with real wires** (not all-labels), so
the layout is faithful but messy — readability polish is optional/later; ERC correctness first.

## Phase 7 — Verify & hand off
`run_drc` → 0 errors; `run_erc` → drive clean. **Diff the netlist against an authoritative source** so
connectivity is provably faithful, not just rule-clean. Gitignore generated artifacts (`*.kicad_prl`,
`~*.lck`, `.history/`, `*_drc_violations.json`, `*_2d_view.*`).

**KiCad-open hazard** (the `File → Revert` dance for on-disk edits) and the **headless-ERC bug** (use
the fixed fork build to verify ERC) both apply throughout the cleanup phases — see the
`kicad-interaction` skill.

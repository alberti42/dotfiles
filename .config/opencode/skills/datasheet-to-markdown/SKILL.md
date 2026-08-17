---
name: datasheet-to-markdown
description: Convert an electronics datasheet PDF (or similar technical PDF) into clean, LLM-ready markdown with extracted specs, tables, and figures — WITHOUT OCR-ing figures. Use whenever the user wants to turn a datasheet/PDF into markdown for agent consumption, extract a parts spec table, or pull figures/schematics out of a datasheet.
---

# Datasheet → Markdown

Convert a datasheet PDF into a markdown file plus extracted images, so an agent
can read specs, tables, and figures without parsing the PDF.

## When to use

The user gives a datasheet PDF (or names one, e.g. `log200.pdf`) and wants it as
markdown — to read specs/tables, feed it to an LLM, or extract figures. Also fits
other text-heavy technical PDFs (app notes, reference manuals).
## How to run (do this — don't reimplement)

A ready, tested converter lives next to this file at `scripts/convert_datasheet.py`,
relative to this skill's base directory (the runtime tells you the absolute base
directory when the skill loads — prepend it). Run it directly; you do **not** need to
read its source to use it.

```bash
python3 "<skill-dir>/scripts/convert_datasheet.py" {{DATASHEET}} {{IMPORT_DIR}}
```

- `{{DATASHEET}}` — path to the PDF (e.g. `log200.pdf`)
- `{{IMPORT_DIR}}` — output directory, created if missing (e.g. `./log200_md`)

Options:
- `--dpi N` — image render resolution (default `200`; raise to `300` for dense schematics)
- `--image-format {png,jpg}` — default `png`
- `--no-figure-index` — skip building the figure-caption index
- `--split-spec-columns` — split merged MIN/TYP/MAX spec cells into three real
  columns (see "Splitting MIN/TYP/MAX" below). Off by default.

Example (the canonical case):
```bash
python3 "<skill-dir>/scripts/convert_datasheet.py" log200.pdf ./log200_md
```

The script prints a summary. Sanity-check it: `noise blocks` must be `0`, and
`failed_pages` must be empty. If `failed_pages` is non-empty, those pages fell back
and may be missing tables — tell the user which. With `--split-spec-columns`, also
report the `spec split` line (geometry vs fallback %) to the user.

## Splitting MIN/TYP/MAX (`--split-spec-columns`)

By default, Electrical Characteristics tables keep MIN/TYP/MAX values merged in one
cell as `a<br>b` (the source PDF has no column rules there). `--split-spec-columns`
separates them into three real `MIN | TYP | MAX` columns.

It does NOT blindly split on `<br>` (that can't tell whether `±30<br>±125` is
MIN/TYP or TYP/MAX). Instead it reads the **x-position** of every value from the PDF
and bins it against the MIN/TYP/MAX header positions — so a lone value lands in its
correct column (e.g. a max-only limit goes to MAX, not TYP). Rows whose values can't
be matched to the geometry fall back to a count rule (1→TYP, 2→TYP/MAX, 3→MIN/TYP/MAX).

The summary reports how many rows were placed by geometry vs the fallback rule
(e.g. `114/128 rows placed by geometry (89%)`). Validated: LOG200 89%, OPA211 64%
(the rest fall back; spot-checked correct). **Tell the user the geometry %** so they
know the confidence — fallback rows on 2-value cells are the ones to double-check
against the PDF. Tables stay valid markdown (row widths normalised, UNIT kept last).

## Output (written into `{{IMPORT_DIR}}`)

| File | Contents |
|---|---|
| `<stem>.md` | Full datasheet markdown: tables as markdown tables (parameter name repeated per row), figures as `![](images/...)` refs, TI hyperlinks preserved. |
| `images/` | Extracted figures, schematics, pinouts, equations and full plot-pages as PNGs. |
| `<stem>_figures.md` | Index of figure captions (`Figure N-M. Title`) with source page — captions are otherwise only visible *inside* the rendered images. |

(`<stem>` is the PDF filename without extension, e.g. `log200`.)

## Prerequisites

Needs `pymupdf4llm` (which pulls in `pymupdf`). If the import fails:
```bash
pip install pymupdf4llm
```
It installs into the active Python (here: pyenv `py313`). It is a **library only** —
there is no `pymupdf4llm` CLI, so `which pymupdf4llm` will find nothing; that's normal.

## Why it works this way (hard-won — do not "improve" by re-enabling these)

- **Classic engine, not the default layout engine.** `pymupdf4llm.to_markdown`
  defaults to a layout engine that wraps each figure's embedded vector text in
  `----- Start of picture text -----` blocks. On multi-plot datasheet pages this
  scrambles side-by-side plots into garbage (`25 25 / 20 20 / Devices (%)`). The
  script uses the classic engine (`pymupdf4llm.helpers.pymupdf_rag`), which omits
  in-figure text and renders each plot page as one clean image with captions baked in.
- **No figure OCR.** The noise above is embedded *text*, not OCR — `use_ocr=False`
  does NOT fix it (that was tested). We deliberately never OCR figures: their content
  is preserved as images, and captions are recovered from the PDF text layer.
- **Page-by-page conversion with table-strategy fallback.** The classic engine raises
  `min() arg is empty` on a degenerate table if given the whole document at once. The
  script isolates each page and degrades the table strategy (`lines_strict` → `lines`
  → `None`) until one succeeds.

## Known limitations (state these to the user when relevant)

- **MIN/TYP/MAX columns merge by default.** In Electrical Characteristics tables,
  stacked spec values land in one cell as `a<br>b` because the source PDF has no
  column rules there — the main spec-misread risk. Pass `--split-spec-columns` to
  separate them (geometry-based; see above). Without that flag, treat merged cells
  with care.
- **Equations are images, not LaTeX.** They are vector objects, extracted as PNGs. For
  machine-usable formulas, source the MathML from the vendor's HTML datasheet viewer
  (e.g. TI's `<script type="math/mml">` fragments) instead.
- **Wrapped figure captions are stitched.** When a caption wraps to a second line in
  the PDF (its continuation lands in a separate text block), the converter rejoins it
  using block geometry — same font/size, directly below, horizontally overlapping — so
  `…(Top View)` is recovered in full rather than clipped to `…(Top`. Axis labels and
  stats like `n = 32` are excluded by that same geometry test.

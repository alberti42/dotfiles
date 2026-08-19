---
name: arxiv-paper
description: Fetch an arXiv paper's LaTeX source from a URL or id, cache it under $XDG_CACHE_HOME/arXiv/<id>v<N>/, load the main .tex into context, and discuss the physics with the user. Use whenever the user gives an arxiv.org/abs/... or arxiv.org/pdf/... link (or a bare arXiv id) and wants to read, summarize, or talk about the paper.
---

# Discuss an arXiv paper from its source

The user gives an arXiv URL (`https://arxiv.org/abs/<id>`, `https://arxiv.org/pdf/<id>`)
or a bare id. Fetch the LaTeX **source** (not the PDF), cache it, read the main `.tex`,
and be ready to discuss the paper.

## How to run (do this — don't reimplement)

A tested helper lives next to this file as `fetch_arxiv.sh` (prepend this skill's
base directory, which the runtime gives you when the skill loads). It does the
parse → resolve-version → cache-check → download → extract → detect-main steps:

```bash
bash <skill-dir>/fetch_arxiv.sh "<url-or-id>"
```

It prints a `key=value` block — **parse it, don't re-derive the paths yourself**:

```
ARXIV_ID=2606.24869v2
CACHE_DIR=/Users/.../.cache/arXiv/2606.24869v2
STATUS=cached|downloaded|pdf-only
SVG=ok:<n>/<total> | missing-tools:<csv> | partial:... | none
MAIN_TEX=<absolute path> | AMBIGUOUS | NONE
TEX_CANDIDATES:
<one path per line>
```

## What the script guarantees

- **Version is always explicit.** If the URL has no version, the current one is
  resolved via the arXiv API, so the cache dir is e.g. `2606.24869v2/`. Distinct
  versions get distinct directories.
- **Cache-first.** `STATUS=cached` means it was already on disk — nothing was
  downloaded. `STATUS=downloaded` means it was just fetched.
- **Source formats handled:** gzipped tarball (the usual case), a single gzipped
  `.tex`, or a PDF-only submission (`STATUS=pdf-only`).
- **Atomic:** an interrupted download never leaves a half-populated cache dir.
- **Figures converted to SVG.** At import time, every figure source that *can't*
  be displayed directly is converted to SVG — PDF (via `mutool`) and EPS/PS (via
  `epstopdf` → `mutool`). Raster formats that already render (`png`, `jpeg`/`jpg`,
  `gif`, `tiff`/`tif`, `xbm`, `xpm`, `pbm`/`pgm`/`ppm`/`pnm`, `svg`, `webp`) are
  left untouched. Single-page sources become `<base>.svg`; multipage ones become
  `<base>-1.svg`, `<base>-2.svg`, … Originals are kept.
- **Figures normalized for display.** Every SVG in the cache dir is then post-
  processed by `normalize_svg.py` (see below): a fixed on-screen width (600 px,
  override with `SVG_TARGET_WIDTH`) and an opaque **white background** (override
  with `SVG_BG`, e.g. `SVG_BG=none`). Both steps are idempotent and self-heal
  older caches, so re-running the fetch script fixes previously imported papers.
  Needs `python3`; if absent, the `SVG=` line gains ` unnormalized:no-python3`
  and the figures are simply left as converted.

## After running

1. **Pick the main `.tex`:**
   - `MAIN_TEX=<path>` → use it directly.
   - `MAIN_TEX=AMBIGUOUS` → several `\documentclass` files exist and none has an
     obvious name. **Ask the user to choose** from `TEX_CANDIDATES`; don't guess.
   - `MAIN_TEX=NONE` → no `.tex` found. If `STATUS=pdf-only`, tell the user the
     source isn't available and offer to read the PDF instead (the PDF was cached
     as `paper.pdf` in `CACHE_DIR`).

2. **Check `SVG`:** if it is `missing-tools:<csv>`, some figures couldn't be
   converted because those tools aren't installed (`mutool` → `brew install
   mupdf-tools`; `epstopdf` → a TeX distribution like MacTeX/TeX Live). Tell the
   user which to install and that the affected figures won't render until then;
   offer to re-run once available. **Do not** silently fall back to another
   converter. `ok`/`none` need no action; `partial:...` means some sources failed
   to convert despite the tools being present — mention it if a figure is missing.

3. **Read the main `.tex`** into context. (If `SVG=` carries an
   `unnormalized:no-python3` suffix, figures still render — just small and with a
   transparent background; mention it only if the user complains.) Papers commonly `\input{}` / `\include{}`
   section files and a `.bib` — read those referenced files too if you need them to
   answer. Figures are images and need no reading.

4. **Name the session.** If a `set_session_name` tool is available, call it once to
   title the session after the paper, in the format:

   ```
   [<ARXIV_ID>] <paper title>
   ```

   e.g. `[2606.24869v2] Fault-Tolerant Quantum Error Correction`. Use `ARXIV_ID`
   verbatim from the fetch script (it is already version-pinned) and the title from
   the main `.tex` `\title{…}` (strip LaTeX macros and collapse line breaks; keep it
   concise). If no such tool exists in this environment, skip this step silently.

5. **Discuss the physics** with the user: summarize the result, explain methods,
   answer questions, locate equations/sections.

## Producing a summary

When the user asks for a **summary** of the paper, unless they specify
otherwise, the default is a *detailed* summary — not a terse abstract-level
recap. Apply all of the following:

- **Be detailed and include the math.** Reproduce the key results with both
  **inline** (`\(…\)`) and **displayed** (`\[…\]`) equations, following the
  math-delimiter rules below. Don't just describe an equation in prose — show
  it. Define the symbols the first time they appear.
- **Embed relevant figures in context.** When a figure supports the point being
  made, place it inline in that part of the summary (not collected at the end)
  using the figure markup below. Show the `.svg`, on its own line.
- **Link important statements to the source.** Every substantive claim, result,
  or definition should carry a clickable markdown link back to the paragraph,
  equation, or section it comes from in the `.tex` manuscript, using the
  source-reference format below. Prefer linking the exact line of the relevant
  equation/paragraph over a coarse section reference.

If the user asks for something shorter or different (e.g. "one paragraph", "no
equations", "just the method"), follow their instruction instead.

## Formatting guidelines

**Source references:** when citing a location in the paper, format it as a
markdown link with the **absolute path wrapped in angle brackets** so it is
clickable in the chat buffer:

```
[main.tex:95](</absolute/path/to/main.tex#L95>)
```

Include a brief description when it adds context, e.g.
`[main.tex:95 (Hamiltonian definition)](</absolute/path/to/main.tex#L95>)`.
Always prefer substantive references over bare line numbers — mentioning the
equation label, section title, or concept helps the user decide whether to
click. Use the absolute path from `CACHE_DIR`/`MAIN_TEX` reported by the
fetch script; never use a relative path.

**Figures:** when a figure is relevant to the discussion, show it with
markdown image syntax, the **absolute path wrapped in angle brackets**, on
its own line (not inline):

```
![](</absolute/path/to/Figures/fig1_v9.svg>)
```

The angle brackets are CommonMark's syntax for a destination that may contain
spaces (`<…>`), so the markup stays valid markdown: it renders as an image in
the chat buffer *and* in any standard markdown viewer when the transcript is
saved or copy-and-pasted — and it keeps working when a figure path contains a
space (a bare `![](…)` would break at the first space in a standard viewer).
Always point at the **`.svg`**, never the source `.pdf` (PDFs don't render).
Use the path from `CACHE_DIR`. For a multipage source PDF, pick the right
page: `<base>-<n>.svg`.

**Math delimiters:** write inline math with `\(` … `\)` delimiters, e.g.
`\(\hat{H}\lvert\psi\rangle = E\lvert\psi\rangle\)` — **not** markdown inline-code
backticks. Use `\[` … `\]` (or `$$`) for displayed equations.

## Fixing figures in an existing cache

`normalize_svg.py` (next to this file) is also a standalone CLI, useful to
retrofit every already-imported paper in one go:

```bash
python3 <skill-dir>/normalize_svg.py "${XDG_CACHE_HOME:-$HOME/.cache}/arXiv" --width 600
```

It takes files and/or directories (recursive `*.svg`), plus `--color`
(default `white`, `none` disables), `--width N` (omit to leave sizes alone),
`--dry-run`, `-q`, and `--backup` (off by default; writes `<file>.svg.bak`,
never overwriting an existing backup).

## Notes

- `XDG_CACHE_HOME` defaults to `~/.cache` when unset.
- Old-style ids (`hep-th/9901001`) are handled best-effort; the `/` is flattened to
  `_` in the directory name.
- Be polite to arXiv: the cache-first design means each paper is fetched once.

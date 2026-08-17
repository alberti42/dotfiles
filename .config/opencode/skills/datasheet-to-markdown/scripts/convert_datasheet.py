#!/usr/bin/env python3
"""Convert an electronics datasheet PDF to clean markdown + extracted images.

Uses pymupdf4llm's CLASSIC engine (pymupdf4llm.helpers.pymupdf_rag), NOT the
default layout engine. The layout engine wraps every figure's embedded text in
"----- Start of picture text -----" blocks, which scrambles multi-plot pages
into garbage (e.g. "25 25 / 20 20 / Devices (%) Devices (%)"). The classic
engine instead omits in-figure text and renders each plot page as a single
image with its captions baked in. This is intentional: we do NOT OCR figures.

Output written to EXPORT_DIR:
  <stem>.md            full datasheet markdown (tables as markdown tables,
                       figures as ![](images/...) refs, TI hyperlinks kept)
  images/              extracted figure/schematic/equation images (PNG)
  <stem>_figures.md    index of figure captions ("Figure N-M. Title") with
                       the source page, recovered from the PDF text layer
                       (captions are otherwise only visible inside the images)

Usage:
    python convert_datasheet.py DATASHEET.pdf EXPORT_DIR [--dpi N] [--no-figure-index]

Requires: pymupdf4llm, pymupdf  (pip install pymupdf4llm)
"""
import argparse
import os
import re
import sys
from collections import defaultdict
from pathlib import Path


def _md_cells(line: str) -> list:
    """Split a markdown table row into cells, preserving leading/trailing empties."""
    parts = line.rstrip().split("|")
    if parts and parts[0] == "":
        parts = parts[1:]
    if parts and parts[-1] == "":
        parts = parts[:-1]
    return [p.strip() for p in parts]


def _geo_value_columns(page):
    """Recover MIN/TYP/MAX assignment from PDF geometry for one page.

    Datasheets place MIN/TYP/MAX values at distinct x-positions even when the
    PDF has no column rules (so the markdown extractor merges them into one
    `a<br>b` cell). We read the MIN/TYP/MAX/UNIT header word x-centres, derive
    column boundaries, and bin every numeric word into its column. Returns a
    list of rows (top-to-bottom), each a list of (value_str, column) pairs, or
    None if this page has no MIN/TYP/MAX header (i.e. not a spec table).
    """
    words = page.get_text("words")  # (x0,y0,x1,y1,word,block,line,wno)
    hdr = {}
    for w in words:
        if w[4] in ("MIN", "TYP", "MAX", "UNIT") and w[4] not in hdr:
            hdr[w[4]] = (w[0] + w[2]) / 2
    if not {"MIN", "TYP", "MAX"} <= hdr.keys():
        return None
    xmin, xtyp, xmax = hdr["MIN"], hdr["TYP"], hdr["MAX"]
    xunit = hdr.get("UNIT", xmax + (xmax - xtyp))
    b0 = xmin - (xtyp - xmin)   # left edge of value band
    b1 = (xmin + xtyp) / 2      # MIN | TYP boundary
    b2 = (xtyp + xmax) / 2      # TYP | MAX boundary
    b3 = (xmax + xunit) / 2     # right edge (before UNIT)
    rows = defaultdict(list)
    for x0, y0, x1, y1, w, *_ in words:
        cx = (x0 + x1) / 2
        if b0 <= cx <= b3 and any(c.isdigit() for c in w):
            col = "MIN" if cx < b1 else "TYP" if cx < b2 else "MAX"
            rows[round(y0)].append((cx, w, col))
    return [[(w, col) for cx, w, col in sorted(r)] for _, r in sorted(rows.items())]


def split_spec_columns(page, md: str):
    """Split a merged "MIN TYP MAX" markdown column into three real columns.

    Operates on one page's markdown using that page's geometry (see
    _geo_value_columns). Each merged cell's values are matched against the
    geometry rows to place them in the correct MIN/TYP/MAX column (this is what
    disambiguates 2-value cells, which a blind <br>-split cannot). Rows with no
    geometry match fall back to a count rule (1->TYP, 2->TYP/MAX, 3->MIN/TYP/MAX)
    and are counted as `fallback`. Row widths are normalised so the table stays
    valid markdown (UNIT kept last). Returns (new_md, n_matched, n_fallback).
    """
    geo = _geo_value_columns(page)
    if not geo:
        return md, 0, 0
    lines = md.split("\n")
    out, i, matched, fallback = [], 0, 0, 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("|") and re.search(r"MIN\s+TYP\s+MAX", line):
            hc = _md_cells(line)
            comb = next((j for j, c in enumerate(hc)
                         if re.search(r"MIN\s+TYP\s+MAX", c)), None)
            if comb is None:
                out.append(line); i += 1; continue
            tbl = [line]; j = i + 1
            while j < len(lines) and lines[j].startswith("|"):
                tbl.append(lines[j]); j += 1
            width = len(hc) + 2  # one column becomes three
            ptr = 0
            for ri, row in enumerate(tbl):
                rc = _md_cells(row)
                if len(rc) <= comb:
                    out.append(row); continue
                if ri == 0:
                    rc[comb:comb + 1] = ["MIN", "TYP", "MAX"]
                elif ri == 1:
                    rc[comb:comb + 1] = ["---", "---", "---"]
                else:
                    raw = rc[comb]
                    vals = [v.strip() for v in raw.split("<br>") if v.strip()]
                    mn = tp = mx = ""
                    if vals:
                        match = None
                        for k in range(ptr, min(ptr + 8, len(geo))):
                            if [v for v, _ in geo[k]] == vals:
                                match = geo[k]; ptr = k + 1; break
                        if match:
                            for v, col in match:
                                if col == "MIN":
                                    mn = v
                                elif col == "TYP":
                                    tp = v
                                else:
                                    mx = v
                            matched += 1
                        else:  # geometry didn't match -> documented count rule
                            if len(vals) == 1:
                                tp = vals[0]
                            elif len(vals) >= 3:
                                mn, tp, mx = vals[:3]
                            else:
                                tp, mx = vals
                            fallback += 1
                    rc[comb:comb + 1] = [mn, tp, mx]
                    # drop ragged duplicate value cells the extractor sometimes emits
                    rc = [c for ci, c in enumerate(rc)
                          if not (ci > comb + 2 and c == raw)]
                if len(rc) > width:        # keep UNIT (last) when trimming extras
                    rc = rc[:width - 1] + [rc[-1]]
                elif len(rc) < width:
                    rc = rc + [""] * (width - len(rc))
                out.append("|" + "|".join(rc) + "|")
            i = j
        else:
            out.append(line); i += 1
    return "\n".join(out), matched, fallback


_FIG_RE = re.compile(r"^Figure\s+(\d+(?:-\d+)?)\.")


def extract_captions(page):
    """Yield (number, caption) for every "Figure N-M." on `page`.

    A caption that wraps to a second line in the PDF lands in a SEPARATE text
    line (often a separate block), so a single-line grab clips it (e.g. "...(Top"
    instead of "...(Top View)"). We rebuild the full caption from line geometry: a
    continuation line shares the caption's font+size, starts within ~one line
    below it, and overlaps it horizontally. This excludes axis labels (far below)
    and stats like "n = 32" (regular weight, above), and — because two captions in
    a two-column figure layout sit side-by-side (same y, non-overlapping x) — it
    keeps them separate rather than concatenating them. Works for both numbering
    styles: "Figure 1." (older) and "Figure 5-1." (section-numbered).
    """
    lines = []
    for b in page.get_text("dict")["blocks"]:
        if "lines" not in b:
            continue
        for l in b["lines"]:
            spans = l["spans"]
            if not spans:
                continue
            txt = re.sub(r"\s+", " ",
                         "".join(s["text"] for s in spans)).strip()
            if txt:
                lines.append({"bbox": l["bbox"], "font": spans[0]["font"],
                              "size": round(spans[0]["size"], 1), "txt": txt})
    lines.sort(key=lambda l: (round(l["bbox"][1]), l["bbox"][0]))

    out = []
    for i, ln in enumerate(lines):
        if not _FIG_RE.match(ln["txt"]):
            continue
        cap = ln["txt"]
        cur = ln
        # Greedily stitch continuation lines below the caption.
        for k in lines[i + 1:]:
            x0, y0, x1, y1 = k["bbox"]
            cx0, cy0, cx1, cy1 = cur["bbox"]
            same_style = k["font"] == cur["font"] and k["size"] == cur["size"]
            below = 0 <= y0 - cy1 <= cur["size"] * 1.2
            overlaps_x = x0 < cx1 and x1 > cx0
            if same_style and below and overlaps_x and not _FIG_RE.match(k["txt"]):
                cap = f"{cap} {k['txt']}"
                cur = k
            elif below and overlaps_x:
                break  # something else sits directly under the caption — stop
        out.append((_FIG_RE.match(cap).group(1), cap))
    # Lines are in reading order (left-to-right); sort by figure number so the
    # index stays numerically ordered (e.g. 5-27 before 5-28).
    out.sort(key=lambda nc: [int(p) for p in nc[0].split("-")])
    return out


def convert(pdf_path: str, export_dir: str, dpi: int = 200,
            image_format: str = "png", figure_index: bool = True,
            split_spec: bool = False) -> dict:
    """Convert `pdf_path` into `export_dir`. Returns a summary dict."""
    try:
        import pymupdf
        import pymupdf4llm.helpers.pymupdf_rag as rag  # classic engine
    except ImportError as e:
        raise SystemExit(
            f"error: required package not installed ({e.name}).\n"
            f"  run: pip install pymupdf4llm")

    pdf_path = os.fspath(pdf_path)
    export = Path(export_dir)
    images_dir = export / "images"
    images_dir.mkdir(parents=True, exist_ok=True)
    stem = Path(pdf_path).stem

    doc = pymupdf.open(pdf_path)

    # Convert PAGE-BY-PAGE. The classic engine raises "min() arg is empty" on a
    # degenerate table when fed the whole document at once, so we isolate pages
    # and degrade the table strategy until one works.
    parts, failed_pages = [], []
    split_matched = split_fallback = 0
    for i in range(doc.page_count):
        last_err = None
        page_md = None
        for strategy in ("lines_strict", "lines", None):
            try:
                page_md = rag.to_markdown(
                    doc, pages=[i], write_images=True,
                    image_path=str(images_dir), image_format=image_format,
                    dpi=dpi, table_strategy=strategy, show_progress=False)
                break
            except Exception as e:  # noqa: BLE001 - try next strategy
                last_err = e
        if page_md is None:
            failed_pages.append((i + 1, repr(last_err)))
            parts.append(f"\n<!-- page {i + 1}: extraction fallback failed -->\n")
            continue
        if split_spec:
            page_md, m, f = split_spec_columns(doc[i], page_md)
            split_matched += m
            split_fallback += f
        parts.append(page_md)

    md = "\n".join(parts)

    # Normalise image refs to be relative to the .md file (which lives in
    # EXPORT_DIR), regardless of the absolute path pymupdf4llm wrote.
    md = re.sub(r"\]\((?:[^)]*/)?(images/[^)]+\.(?:png|jpe?g))\)", r"](\1)", md)
    md = re.sub(r"\n{3,}", "\n\n", md)  # collapse runs of blank lines

    md_path = export / f"{stem}.md"
    md_path.write_text(md, encoding="utf-8")

    # Recover figure captions from the PDF text layer (they survive only inside
    # the rendered images otherwise). Pattern: "Figure N-M. <caption text>".
    figures = []
    if figure_index:
        seen = set()
        for pno in range(doc.page_count):
            for num, cap in extract_captions(doc[pno]):
                if num in seen:  # de-dupe (same caption repeats across text runs)
                    continue
                seen.add(num)
                figures.append((pno + 1, cap))
        fig_lines = [f"# {stem} — Figure index\n"]
        for page, cap in figures:
            fig_lines.append(f"- (p.{page}) {cap}")
        (export / f"{stem}_figures.md").write_text("\n".join(fig_lines) + "\n",
                                                   encoding="utf-8")

    n_images = len(list(images_dir.glob(f"*.{image_format}")))
    n_table_rows = sum(1 for line in md.splitlines() if line.startswith("|"))

    return {
        "markdown": str(md_path),
        "images_dir": str(images_dir),
        "n_images": n_images,
        "n_table_rows": n_table_rows,
        "n_figures": len(figures),
        "n_pages": doc.page_count,
        "failed_pages": failed_pages,
        "picture_text_noise": md.count("picture text"),  # expect 0
        "split_spec": split_spec,
        "split_matched": split_matched,
        "split_fallback": split_fallback,
    }


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Convert a datasheet PDF to markdown + images (no figure OCR).")
    p.add_argument("datasheet", help="path to the datasheet PDF")
    p.add_argument("export_dir", help="output directory (created if missing)")
    p.add_argument("--dpi", type=int, default=200, help="image render DPI (default 200)")
    p.add_argument("--image-format", default="png", choices=["png", "jpg"],
                   help="extracted image format (default png)")
    p.add_argument("--no-figure-index", action="store_true",
                   help="skip building the <stem>_figures.md caption index")
    p.add_argument("--split-spec-columns", action="store_true",
                   help="split merged MIN/TYP/MAX spec cells into 3 columns "
                        "using PDF geometry (see SKILL.md for caveats)")
    args = p.parse_args(argv)

    if not os.path.isfile(args.datasheet):
        p.error(f"datasheet not found: {args.datasheet}")

    summary = convert(args.datasheet, args.export_dir, dpi=args.dpi,
                      image_format=args.image_format,
                      figure_index=not args.no_figure_index,
                      split_spec=args.split_spec_columns)

    print(f"markdown      : {summary['markdown']}")
    print(f"images        : {summary['n_images']} files in {summary['images_dir']}/")
    print(f"table rows    : {summary['n_table_rows']}")
    print(f"figures index : {summary['n_figures']} captions")
    print(f"pages         : {summary['n_pages']}")
    print(f"noise blocks  : {summary['picture_text_noise']} (expect 0)")
    if summary["split_spec"]:
        total = summary["split_matched"] + summary["split_fallback"]
        pct = (100 * summary["split_matched"] // total) if total else 0
        print(f"spec split    : {summary['split_matched']}/{total} rows placed by "
              f"geometry ({pct}%); {summary['split_fallback']} by fallback rule")
    if summary["failed_pages"]:
        print(f"WARNING: pages with failed extraction: {summary['failed_pages']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

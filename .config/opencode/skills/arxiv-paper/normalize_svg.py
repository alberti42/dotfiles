#!/usr/bin/env python3
"""Normalize SVG figures for display in a chat buffer.

Two independent, idempotent steps are applied to the root <svg> element:

1. **Opaque background** (``--color``, default ``white``; ``none`` disables).
   LaTeX-derived figures are transparent with black ink, which is unreadable on
   a dark background, so

       <rect id="arxiv-bg" x=… y=… width=… height=… fill="white"/>

   is inserted as the first child, sized from the ``viewBox`` when present (so a
   non-zero origin is covered) and ``0,0 100%x100%`` otherwise.

2. **On-screen width** (``--width N``, off unless given).  Agent shells render an
   SVG at its intrinsic width, and arXiv figure sources are frequently tiny.
   The root ``width``/``height`` are rewritten to N px (height follows the aspect
   ratio); the ``viewBox`` is left untouched so the vector content just scales.

Both steps are safe to re-run: the background is keyed on the ``id="arxiv-bg"``
marker and the width rewrite is a fixed point.

Usage:
    normalize_svg.py FILE_OR_DIR [...] [--width 600] [--color white] [--backup]

Directories are searched recursively for ``*.svg``.  With ``--backup`` a
``<file>.svg.bak`` copy is written before the first modification (an existing
backup is never overwritten).
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

MARKER = 'id="arxiv-bg"'
ROOT_SVG_RE = re.compile(r"<svg\b[^>]*?>", re.IGNORECASE)
VIEWBOX_RE = re.compile(
    r'\bviewBox="\s*([-\d.eE]+)[,\s]+([-\d.eE]+)[,\s]+([-\d.eE]+)[,\s]+([-\d.eE]+)\s*"',
    re.IGNORECASE,
)
WIDTH_RE = re.compile(r'\bwidth="([\d.]+)"')
HEIGHT_RE = re.compile(r'\bheight="([\d.]+)"')


def iter_svgs(paths: list[Path]):
    for p in paths:
        if p.is_dir():
            yield from sorted(p.rglob("*.svg"))
        elif p.suffix.lower() == ".svg":
            yield p
        else:
            print(f"skip (not an .svg): {p}", file=sys.stderr)


def _fmt(value: float) -> str:
    """Format like printf %g: no trailing zeros, no needless decimal point."""
    return f"{value:g}"


def add_background(text: str, color: str) -> str:
    if not color or color == "none" or MARKER in text:
        return text
    m = ROOT_SVG_RE.search(text)
    if m is None:
        return text
    vb = VIEWBOX_RE.search(m.group(0))
    x, y, w, h = vb.groups() if vb else ("0", "0", "100%", "100%")
    rect = f'<rect {MARKER} x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}"/>'
    return text[: m.end()] + rect + text[m.end() :]


def set_width(text: str, target: float) -> str:
    m = ROOT_SVG_RE.search(text)
    if m is None:
        return text
    tag = m.group(0)
    mw, mh = WIDTH_RE.search(tag), HEIGHT_RE.search(tag)
    if not (mw and mh):  # missing or unit-bearing dimensions -> leave alone
        return text
    w, h = float(mw.group(1)), float(mh.group(1))
    if w <= 0:
        return text
    new_tag = WIDTH_RE.sub(f'width="{_fmt(target)}"', tag, count=1)
    new_tag = HEIGHT_RE.sub(f'height="{_fmt(target * h / w)}"', new_tag, count=1)
    return text[: m.start()] + new_tag + text[m.end() :]


def normalize(path: Path, color: str, width: float | None, backup: bool, dry_run: bool) -> str:
    """Return one of: 'changed', 'unchanged', 'no-root', 'error'."""
    try:
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
    except OSError as exc:
        print(f"error reading {path}: {exc}", file=sys.stderr)
        return "error"

    if ROOT_SVG_RE.search(text) is None:
        print(f"no <svg> root tag: {path}", file=sys.stderr)
        return "no-root"

    new_text = add_background(text, color)
    if width is not None:
        new_text = set_width(new_text, width)

    if new_text == text:
        return "unchanged"
    if dry_run:
        return "changed"

    try:
        if backup:
            bak = path.with_suffix(path.suffix + ".bak")  # foo.svg -> foo.svg.bak
            if not bak.exists():
                shutil.copy2(path, bak)
        path.write_text(new_text, encoding="utf-8", errors="surrogateescape")
    except OSError as exc:
        print(f"error writing {path}: {exc}", file=sys.stderr)
        return "error"
    return "changed"


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Add an opaque background and/or normalize the width of SVG files."
    )
    ap.add_argument("paths", nargs="+", type=Path, help="SVG files or directories")
    ap.add_argument(
        "--color", default="white", help="background colour, or 'none' (default: white)"
    )
    ap.add_argument(
        "--width", type=float, default=None, help="target on-screen width in px (default: leave as is)"
    )
    ap.add_argument(
        "--backup", action="store_true", help="keep a <file>.svg.bak copy (default: no backups)"
    )
    ap.add_argument("--dry-run", action="store_true", help="report without writing")
    ap.add_argument("-q", "--quiet", action="store_true", help="only print the summary")
    args = ap.parse_args()

    if args.width is not None and args.width <= 0:
        ap.error("--width must be positive")

    counts = {"changed": 0, "unchanged": 0, "no-root": 0, "error": 0}
    for svg in iter_svgs(args.paths):
        result = normalize(svg, args.color, args.width, args.backup, args.dry_run)
        counts[result] += 1
        if not args.quiet and result in ("changed", "unchanged"):
            print(f"{result:>9}: {svg}")

    if not args.quiet or counts["error"]:
        tag = " (dry run)" if args.dry_run else ""
        print(
            f"{counts['changed']} changed{tag}, {counts['unchanged']} already normalized, "
            f"{counts['no-root']} without root <svg>, {counts['error']} errors"
        )
    return 1 if counts["error"] else 0


if __name__ == "__main__":
    sys.exit(main())

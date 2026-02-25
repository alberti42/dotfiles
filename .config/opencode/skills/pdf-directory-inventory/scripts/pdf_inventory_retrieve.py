#!/usr/bin/env python3
"""Retrieve entries from _pdf_probe.md by index.

This is a mechanical helper for delegation workflows.

Supported selectors:
- --retrieve 1
- --retrieve 3..9
- --retrieve all

Optionally trim excerpt output using --max-lines.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


PROBE_FILENAME = "_pdf_probe.md"


@dataclass
class Entry:
    index: int
    header_line: str
    lines: list[str]


_HDR_RE = re.compile(r"^##\s+(\d+)\.\s+.*\{[0-9a-fA-F-]{36}\}\s*$")


def _parse_entries(text: str) -> list[Entry]:
    lines = (text or "").splitlines(keepends=True)
    entries: list[Entry] = []
    cur_idx: int | None = None
    cur_header: str | None = None
    cur_lines: list[str] = []

    for line in lines:
        m = _HDR_RE.match(line.rstrip("\n"))
        if m:
            if cur_idx is not None:
                entries.append(Entry(cur_idx, cur_header or "", cur_lines))
            cur_idx = int(m.group(1))
            cur_header = line
            cur_lines = [line]
            continue

        if cur_idx is not None:
            cur_lines.append(line)

    if cur_idx is not None:
        entries.append(Entry(cur_idx, cur_header or "", cur_lines))

    return entries


def _parse_selector(s: str, *, max_index: int) -> set[int]:
    s = (s or "").strip().lower()
    if s == "all":
        return set(range(1, max_index + 1))

    if ".." in s:
        a, b = s.split("..", 1)
        try:
            start = int(a)
            end = int(b)
        except ValueError:
            raise ValueError("invalid range selector")
        if start <= 0 or end <= 0 or end < start:
            raise ValueError("invalid range selector")
        return set(range(start, end + 1))

    try:
        one = int(s)
    except ValueError:
        raise ValueError("invalid selector")
    if one <= 0:
        raise ValueError("invalid selector")
    return {one}


def _trim_excerpt(lines: list[str], *, max_lines: int) -> list[str]:
    if max_lines < 0:
        return lines
    if max_lines == 0:
        out: list[str] = []
        in_excerpt_block = False
        for ln in lines:
            if ln.startswith("```text"):
                in_excerpt_block = True
                out.append(ln)
                continue
            if in_excerpt_block and ln.startswith("```"):
                in_excerpt_block = False
                out.append(ln)
                continue
            if in_excerpt_block:
                continue
            out.append(ln)
        return out

    out = []
    in_text_block = False
    excerpt_count = 0
    for ln in lines:
        if ln.startswith("```text"):
            in_text_block = True
            excerpt_count = 0
            out.append(ln)
            continue
        if in_text_block and ln.startswith("```"):
            in_text_block = False
            out.append(ln)
            continue
        if in_text_block:
            # Count only non-empty excerpt lines.
            if ln.strip():
                excerpt_count += 1
            if excerpt_count <= max_lines:
                out.append(ln)
            continue
        out.append(ln)
    return out


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--dir", default=".", help="Directory containing _pdf_probe.md (default: .)"
    )
    ap.add_argument(
        "--retrieve",
        required=True,
        help="Entry selector: N, A..B, or all",
    )
    ap.add_argument(
        "--max-lines",
        type=int,
        default=-1,
        help="Trim excerpt to at most N lines per entry; -1 disables trimming (default: -1)",
    )
    ns = ap.parse_args(argv)

    root = Path(ns.dir).resolve()
    probe = root / PROBE_FILENAME
    if not probe.exists() or not probe.is_file():
        print(f"Missing {PROBE_FILENAME} in: {root}", file=sys.stderr)
        return 2

    text = probe.read_text(encoding="utf-8", errors="replace")
    entries = _parse_entries(text)
    if not entries:
        print("No entries found in _pdf_probe.md", file=sys.stderr)
        return 1

    max_index = max(e.index for e in entries)
    try:
        want = _parse_selector(str(ns.retrieve), max_index=max_index)
    except ValueError as e:
        print(f"Invalid --retrieve value: {e}", file=sys.stderr)
        return 2

    any_out = False
    for e in entries:
        if e.index not in want:
            continue
        lines = e.lines
        if ns.max_lines >= 0:
            lines = _trim_excerpt(lines, max_lines=int(ns.max_lines))
        sys.stdout.write("".join(lines))
        if lines and not lines[-1].endswith("\n"):
            sys.stdout.write("\n")
        any_out = True

    if not any_out:
        print("No matching entries", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Preflight dependency check for pdf-directory-inventory.

This is meant to fail fast when OpenCode is launched in the wrong Python
environment or when required executables are missing.
"""

from __future__ import annotations

import argparse
import importlib
import shutil
import sys


MIN_PYTHON = (3, 10)

# These scripts are intentionally dependency-light; keep this list small.
REQUIRED_IMPORTS = [
    "argparse",
    "dataclasses",
    "hashlib",
    "os",
    "pathlib",
    "re",
    "shutil",
    "subprocess",
    "sys",
    "tempfile",
    "uuid",
]

# External executables used by the shipped scripts.
REQUIRED_BINS = [
    "pdftotext",
]

OPTIONAL_BINS = [
    "pdfinfo",
]

OCR_PRIMARY_BIN = "ocrmypdf"
OCR_FALLBACK_BINS = ["pdftoppm", "tesseract", "qpdf"]


def _have(bin_name: str) -> bool:
    return shutil.which(bin_name) is not None


def _check_import(mod: str) -> str | None:
    try:
        importlib.import_module(mod)
    except Exception as e:
        return f"{mod}: {e}"
    return None


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        prog="check_deps.py",
        description=(
            "Fail-fast dependency check for pdf-directory-inventory. "
            "Verifies Python version, required imports, and required executables on PATH."
        ),
    )
    ap.parse_args(argv)

    problems: list[str] = []
    notes: list[str] = []

    if sys.version_info < MIN_PYTHON:
        problems.append(
            "Python too old: "
            f"need >= {MIN_PYTHON[0]}.{MIN_PYTHON[1]}, "
            f"got {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        )

    for mod in REQUIRED_IMPORTS:
        err = _check_import(mod)
        if err:
            problems.append(f"Cannot import {err}")

    for b in REQUIRED_BINS:
        if not _have(b):
            problems.append(f"Missing executable on PATH: {b}")

    have_ocr_path = _have(OCR_PRIMARY_BIN) or all(_have(b) for b in OCR_FALLBACK_BINS)
    if not have_ocr_path:
        problems.append(
            "Missing OCR tooling: need 'ocrmypdf' OR all of "
            + ", ".join(repr(x) for x in OCR_FALLBACK_BINS)
        )

    for b in OPTIONAL_BINS:
        if not _have(b):
            notes.append(
                f"Optional executable missing: {b} (PDF metadata will be limited)"
            )

    if problems:
        print("Dependency check failed.", file=sys.stderr)
        print(f"Python: {sys.executable}", file=sys.stderr)
        print(f"Version: {sys.version.split()[0]}", file=sys.stderr)
        for p in problems:
            print(f"- {p}", file=sys.stderr)
        print("", file=sys.stderr)
        print(
            "Fix: start OpenCode from the correct Python environment (activate your venv/conda) "
            "and ensure required tools are installed and on PATH, then re-run this check:",
            file=sys.stderr,
        )
        print(
            "python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/check_deps.py",
            file=sys.stderr,
        )
        return 1

    print("Dependency check OK.")
    for n in notes:
        print(f"Note: {n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

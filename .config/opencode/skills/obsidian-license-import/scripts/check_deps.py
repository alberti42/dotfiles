#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path


REQUIRED_CMDS = [
    "ocrmypdf",
    "pdftotext",
    "tesseract",
]

DEFAULT_OUT_DIR = Path("/Users/andrea/Obsidian/Work/12 Software licenses")


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Check dependencies for obsidian-license-import skill"
    )
    ap.parse_args()

    missing: list[str] = []
    for cmd in REQUIRED_CMDS:
        if shutil.which(cmd) is None:
            missing.append(cmd)

    if not DEFAULT_OUT_DIR.exists():
        missing.append(f"output-dir-missing:{DEFAULT_OUT_DIR}")
    else:
        try:
            test = DEFAULT_OUT_DIR / ".write_test.tmp"
            test.write_text("ok\n", encoding="utf-8")
            test.unlink()
        except Exception:
            missing.append(f"output-dir-not-writable:{DEFAULT_OUT_DIR}")

    if missing:
        sys.stderr.write("Missing requirements:\n")
        for m in missing:
            sys.stderr.write(f"- {m}\n")
        sys.stderr.write("\n")
        sys.stderr.write(
            "Fix: ensure required CLI tools are installed and the output directory exists/writable.\n"
        )
        return 1

    print("OK: dependencies available")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

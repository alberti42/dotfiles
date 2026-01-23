#!/usr/bin/env python
"""Inject a fast-scan hook into pyenv-virtualenvs.

This script is meant to be idempotent and robust across pyenv updates.
It inserts a small shell hook right after the argument parsing loop
(so that `--complete` and flag parsing still work).
"""

import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} /path/to/pyenv-virtualenvs", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    if not path.exists():
        print(f"inject: file not found: {path}", file=sys.stderr)
        return 1

    marker = "# PYENV_VIRTUALENV_FAST_SCAN"
    hook = (
        "\n# PYENV_VIRTUALENV_FAST_SCAN\n"
        "if [ -n \"${PYENV_VIRTUALENV_FAST_SCAN:-}\" ] && [ -r \"${PYENV_VIRTUALENV_FAST_SCAN}\" ]; then\n"
        "  exec \"${BASH:-bash}\" \"${PYENV_VIRTUALENV_FAST_SCAN}\" \"$@\"\n"
        "fi\n"
    )

    text = path.read_text()
    # Bail if already injected.
    if marker in text:
        return 0

    lines = text.splitlines(True)
    out:list[str] = []
    in_loop = False
    inserted = False

    # Insert after the `for arg; do ... done` loop that parses args.
    for line in lines:
        out.append(line)
        if re.match(r"^\s*for\s+arg\s*;\s*do\s*$", line):
            in_loop = True
            continue
        if in_loop and re.match(r"^\s*done\s*$", line):
            out.append(hook)
            inserted = True
            in_loop = False

    if not inserted:
        print("inject: arg parsing loop not found; aborting", file=sys.stderr)
        return 1

    path.write_text("".join(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

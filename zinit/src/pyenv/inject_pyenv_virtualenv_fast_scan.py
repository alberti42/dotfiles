#!/usr/bin/env python

import re
import sys

path = sys.argv[1]
marker = "# PYENV_VIRTUALENV_FAST_SCAN"
hook = (
    "\n# PYENV_VIRTUALENV_FAST_SCAN\n"
    "if [ -n \"${PYENV_VIRTUALENV_FAST_SCAN:-}\" ] && [ -r \"${PYENV_VIRTUALENV_FAST_SCAN}\" ]; then\n"
    "  exec \"${BASH:-bash}\" \"${PYENV_VIRTUALENV_FAST_SCAN}\" \"$@\"\n"
    "fi\n"
)

text = open(path, "r").read()
if marker in text:
    sys.exit(0)

lines = text.splitlines(True)
out = []
inloop = False
inserted = False

for line in lines:
    out.append(line)
    if re.match(r"^\s*for\s+arg\s*;\s*do\s*$", line):
        inloop = True
        continue
    if inloop and re.match(r"^\s*done\s*$", line):
        out.append(hook)
        inserted = True
        inloop = False

if not inserted:
    sys.stderr.write("inject: arg parsing loop not found; aborting\n")
    sys.exit(1)

open(path, "w").write("".join(out))

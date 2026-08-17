#!/usr/bin/env python3
"""Decode a DokuWiki `core_getMedia` result into an image file on disk.

`mcp__dokuwiki__core_getMedia` returns the media as base64 text. For large
files the harness saves that text to a tool-results file instead of returning
it inline; either way this script turns it into a viewable image.

Usage:
    python3 decode_media.py <input> <output.png>

<input>  : path to a file containing the base64 (the tool-results .txt the
           harness wrote), OR "-" to read base64 from stdin.
<output> : path to write the decoded binary (e.g. a .png in the scratchpad).

The input may be raw base64, a JSON string, or a JSON object containing a
base64 field ("base64"/"data"/"content") — all are handled.
"""
import base64
import json
import sys


def extract_b64(raw: str) -> str:
    raw = raw.strip()
    try:
        obj = json.loads(raw)
        if isinstance(obj, str):
            return obj.strip()
        if isinstance(obj, dict):
            for k in ("base64", "data", "content", "media"):
                if k in obj and isinstance(obj[k], str):
                    return obj[k].strip()
    except (json.JSONDecodeError, ValueError):
        pass
    return raw.strip().strip('"')


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    raw = sys.stdin.read() if src == "-" else open(src, "r").read()
    data = base64.b64decode(extract_b64(raw))
    with open(dst, "wb") as fh:
        fh.write(data)
    print(f"wrote {len(data)} bytes to {dst}; header={data[:8]!r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

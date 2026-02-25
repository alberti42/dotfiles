#!/usr/bin/env python3
"""Generate a mechanical probe file (_pdf_probe.md) for PDFs in a directory.

This script is intentionally dependency-light and deterministic:
- Enumerate top-level PDFs (sorted by filename, case-insensitive)
- Exclude PDFs already in the attachments directory
- For each PDF, compute a deterministic doc UUID from the file SHA256
- Extract basic metadata via `pdfinfo` (if available)
- Extract a text excerpt via `pdftotext` and include up to --max-lines lines

Output: _pdf_probe.md written atomically in the target directory.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path


PROBE_FILENAME = "_pdf_probe.md"


def _have(bin_name: str) -> bool:
    return shutil.which(bin_name) is not None


def _run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )


def _sha256_hex(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _doc_uuid_from_sha256_hex(sha256_hex: str) -> str:
    # Deterministic UUID derived from a deterministic input string.
    return str(uuid.uuid5(uuid.NAMESPACE_URL, sha256_hex))


def _human_bytes(n: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    x = float(n)
    for u in units:
        if x < 1024.0 or u == units[-1]:
            if u == "B":
                return f"{int(x)} {u}"
            return f"{x:.1f} {u}"
        x /= 1024.0
    return f"{n} B"


def _clean_one_line(s: str) -> str:
    s = (s or "").replace("\r", " ").replace("\n", " ")
    s = re.sub(r"\s+", " ", s).strip()
    return s


@dataclass(frozen=True)
class PdfMeta:
    pages: int | None
    title: str | None
    author: str | None
    subject: str | None
    creator: str | None
    producer: str | None


def _parse_pdfinfo(stdout: str) -> PdfMeta:
    # pdfinfo output is key: value per line.
    kv: dict[str, str] = {}
    for line in (stdout or "").splitlines():
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        k = _clean_one_line(k)
        v = _clean_one_line(v)
        if k:
            kv[k] = v

    pages: int | None = None
    if "Pages" in kv:
        try:
            pages = int(re.findall(r"\d+", kv["Pages"])[0])
        except Exception:
            pages = None

    return PdfMeta(
        pages=pages,
        title=kv.get("Title") or None,
        author=kv.get("Author") or None,
        subject=kv.get("Subject") or None,
        creator=kv.get("Creator") or None,
        producer=kv.get("Producer") or None,
    )


def _get_pdf_meta(path: Path) -> PdfMeta:
    if not _have("pdfinfo"):
        return PdfMeta(None, None, None, None, None, None)
    cp = _run(["pdfinfo", str(path)])
    if cp.returncode != 0:
        return PdfMeta(None, None, None, None, None, None)
    return _parse_pdfinfo(cp.stdout)


def _extract_excerpt_lines(path: Path, *, max_lines: int, max_pages: int) -> list[str]:
    if max_lines <= 0:
        return []
    if not _have("pdftotext"):
        raise RuntimeError("pdftotext not found (install poppler)")

    # Use a bounded page range to keep extraction time stable.
    cmd = [
        "pdftotext",
        "-f",
        "1",
        "-l",
        str(max(1, max_pages)),
        "-nopgbrk",
        str(path),
        "-",
    ]
    cp = _run(cmd)
    if cp.returncode != 0:
        # Often indicates encryption/bad PDF.
        raise RuntimeError((cp.stderr or "").strip() or "pdftotext failed")

    out_lines: list[str] = []
    for raw in (cp.stdout or "").splitlines():
        line = raw.rstrip()
        if not line.strip():
            continue
        out_lines.append(line)
        if len(out_lines) >= max_lines:
            break
    return out_lines


def _iter_pdfs(root: Path) -> list[Path]:
    return [
        p
        for p in sorted(root.glob("*.pdf"), key=lambda x: x.name.casefold())
        if p.is_file()
    ]


def _attachments_dirname_from_note_name(note_name: str) -> str:
    note_name = (note_name or "").strip()
    if not note_name:
        raise ValueError("note_name is empty")
    return f"{note_name} (attachments)"


def _title_for_entry(path: Path, meta: PdfMeta) -> str:
    if meta.title:
        t = _clean_one_line(meta.title)
        if t:
            return t
    return path.stem


def _write_probe(root: Path, *, note_name: str, max_lines: int, max_pages: int) -> Path:
    attachments_dirname = _attachments_dirname_from_note_name(note_name)
    pdfs = [p for p in _iter_pdfs(root) if p.parent.name != attachments_dirname]

    tmp_dir = root
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        newline="\n",
        prefix=PROBE_FILENAME + ".",
        suffix=".tmp",
        dir=str(tmp_dir),
        delete=False,
    ) as tf:
        tmp_path = Path(tf.name)

        tf.write(f"# PDF probe\n\n")
        tf.write(f"- Note name: {note_name}\n")
        tf.write(f"- Attachments dir: {attachments_dirname}/\n")
        tf.write(f"- PDFs found: {len(pdfs)}\n")
        tf.write(f"- Excerpt max lines: {max_lines}\n")
        tf.write(f"- Excerpt max pages: {max_pages}\n\n")

        if not pdfs:
            tf.write("(No PDFs found.)\n")
            tf.flush()
            os.fsync(tf.fileno())
            return tmp_path

        for idx, pdf in enumerate(pdfs, start=1):
            st = pdf.stat()
            sha = _sha256_hex(pdf)
            doc_uuid = _doc_uuid_from_sha256_hex(sha)
            meta = _get_pdf_meta(pdf)
            title = _title_for_entry(pdf, meta)

            tf.write(f"## {idx}. {title} {{{doc_uuid}}}\n\n")
            tf.write(f"- File: {pdf.name}\n")
            tf.write(f"- Size: {_human_bytes(st.st_size)} ({st.st_size} bytes)\n")
            if meta.pages is not None:
                tf.write(f"- Pages: {meta.pages}\n")
            tf.write(f"- SHA256: {sha}\n")

            # Only include metadata fields when present.
            if meta.author:
                tf.write(f"- Author: {_clean_one_line(meta.author)}\n")
            if meta.subject:
                tf.write(f"- Subject: {_clean_one_line(meta.subject)}\n")
            if meta.creator:
                tf.write(f"- Creator: {_clean_one_line(meta.creator)}\n")
            if meta.producer:
                tf.write(f"- Producer: {_clean_one_line(meta.producer)}\n")

            tf.write("\n")
            tf.write("Excerpt:\n\n")

            try:
                excerpt = _extract_excerpt_lines(
                    pdf, max_lines=max_lines, max_pages=max_pages
                )
            except Exception as e:
                excerpt = []
                tf.write(f"(Excerpt extraction failed: {e})\n")

            if excerpt:
                tf.write("```text\n")
                for line in excerpt:
                    tf.write(line + "\n")
                tf.write("```\n")
            else:
                tf.write("(No extractable text found in excerpt range.)\n")

            tf.write("\n")

        tf.flush()
        os.fsync(tf.fileno())

    return tmp_path


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=".", help="Directory containing PDFs (default: .)")
    ap.add_argument(
        "--extract",
        action="store_true",
        help="Generate _pdf_probe.md in the target directory",
    )
    ap.add_argument(
        "--note-name",
        required=True,
        help="NOTE_NAME base used for attachments directory exclusion",
    )
    ap.add_argument(
        "--max-lines",
        type=int,
        default=50,
        help="Maximum excerpt lines per PDF entry (default: 50)",
    )
    ap.add_argument(
        "--max-pages",
        type=int,
        default=10,
        help="Maximum pages to scan for excerpt text (default: 10)",
    )
    ns = ap.parse_args(argv)

    if not ns.extract:
        print("Nothing to do (missing --extract)", file=sys.stderr)
        return 2

    root = Path(ns.dir).resolve()
    if not root.exists() or not root.is_dir():
        print(f"Not a directory: {root}", file=sys.stderr)
        return 2

    if not _have("pdftotext"):
        print("Missing dependency: pdftotext", file=sys.stderr)
        return 2
    # pdfinfo is optional.

    if ns.max_lines < 0:
        print("--max-lines must be >= 0", file=sys.stderr)
        return 2
    if ns.max_pages <= 0:
        print("--max-pages must be >= 1", file=sys.stderr)
        return 2

    try:
        tmp_path = _write_probe(
            root,
            note_name=str(ns.note_name),
            max_lines=int(ns.max_lines),
            max_pages=int(ns.max_pages),
        )
    except Exception as e:
        print(f"Failed to generate probe: {e}", file=sys.stderr)
        return 1

    final_path = root / PROBE_FILENAME
    try:
        os.replace(tmp_path, final_path)
    except Exception as e:
        print(f"Failed to write {PROBE_FILENAME}: {e}", file=sys.stderr)
        try:
            tmp_path.unlink(missing_ok=True)  # py>=3.8
        except Exception:
            pass
        return 1

    print(f"Wrote {final_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

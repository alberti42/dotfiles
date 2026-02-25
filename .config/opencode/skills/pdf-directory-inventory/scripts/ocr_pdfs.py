#!/usr/bin/env python3
"""OCR PDFs in a directory when they have no extractable text.

Strategy:
- Detect text with `pdftotext` on the first few pages.
- If text is missing, OCR in-place.
- Prefer `ocrmypdf` when installed; otherwise fall back to Poppler + Tesseract + qpdf.

This script is intended as a pragmatic helper for an AI-driven inventory workflow.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


DEFAULT_ATTACHMENTS_DIRNAME = "pdf_inventory (attachments)"


def _run(cmd: list[str], *, quiet: bool = False) -> subprocess.CompletedProcess[str]:
    stdout = subprocess.DEVNULL if quiet else subprocess.PIPE
    stderr = subprocess.PIPE
    return subprocess.run(cmd, check=False, text=True, stdout=stdout, stderr=stderr)


def _have(bin_name: str) -> bool:
    return shutil.which(bin_name) is not None


def _pdftotext_has_text(path: Path, pages: int) -> bool:
    # Using stdout with '-' keeps this dependency-free (no pypdf needed).
    cmd = [
        "pdftotext",
        "-f",
        "1",
        "-l",
        str(max(1, pages)),
        "-nopgbrk",
        str(path),
        "-",
    ]
    cp = _run(cmd)
    if cp.returncode != 0:
        # Encrypted/broken PDFs often fail here.
        return False
    text = cp.stdout or ""
    text = re.sub(r"\s+", " ", text).strip()
    # Heuristic: require some alnum; ignore boilerplate whitespace.
    return len(re.findall(r"[A-Za-z0-9]", text)) >= 25


def _ocr_with_ocrmypdf(inp: Path, out: Path, *, lang: str) -> None:
    # --skip-text avoids touching already-searchable PDFs.
    cmd = [
        "ocrmypdf",
        "--skip-text",
        "--language",
        lang,
        str(inp),
        str(out),
    ]
    cp = _run(cmd, quiet=True)
    if cp.returncode != 0:
        raise RuntimeError((cp.stderr or "").strip() or "ocrmypdf failed")


def _page_num_from_name(p: Path) -> int:
    # pdftoppm uses prefix-<pagenum>.png with 1-based numbering
    m = re.search(r"-(\d+)\.[A-Za-z0-9]+$", p.name)
    return int(m.group(1)) if m else 10**9


def _ocr_with_tesseract_fallback(inp: Path, out: Path, *, lang: str, dpi: int) -> None:
    if not _have("pdftoppm"):
        raise RuntimeError("pdftoppm not found (install poppler)")
    if not _have("tesseract"):
        raise RuntimeError("tesseract not found")
    if not _have("qpdf"):
        raise RuntimeError("qpdf not found")

    with tempfile.TemporaryDirectory(prefix="pdf-ocr-") as td:
        tdir = Path(td)
        prefix = tdir / "page"

        cp = _run(
            ["pdftoppm", "-r", str(dpi), "-png", str(inp), str(prefix)], quiet=True
        )
        if cp.returncode != 0:
            raise RuntimeError((cp.stderr or "").strip() or "pdftoppm failed")

        images = sorted(tdir.glob("page-*.png"), key=_page_num_from_name)
        if not images:
            raise RuntimeError("no images produced by pdftoppm")

        page_pdfs: list[Path] = []
        for img in images:
            base = img.with_suffix("")  # tesseract adds .pdf
            cp = _run(["tesseract", str(img), str(base), "pdf", "-l", lang], quiet=True)
            if cp.returncode != 0:
                raise RuntimeError(
                    (cp.stderr or "").strip() or f"tesseract failed on {img.name}"
                )
            page_pdf = base.with_suffix(".pdf")
            if not page_pdf.exists():
                raise RuntimeError(f"tesseract did not write {page_pdf.name}")
            page_pdfs.append(page_pdf)

        merge_cmd = [
            "qpdf",
            "--empty",
            "--pages",
            *[str(p) for p in page_pdfs],
            "--",
            str(out),
        ]
        cp = _run(merge_cmd, quiet=True)
        if cp.returncode != 0:
            raise RuntimeError((cp.stderr or "").strip() or "qpdf merge failed")


def _iter_pdfs(root: Path) -> list[Path]:
    out: list[Path] = []
    for p in sorted(root.glob("*.pdf"), key=lambda x: x.name.lower()):
        if p.is_file():
            out.append(p)
    return out


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=".", help="Directory containing PDFs (default: .)")
    ap.add_argument(
        "--attachments-dirname",
        default=DEFAULT_ATTACHMENTS_DIRNAME,
        help=(
            "Name of attachments directory to ignore (default: "
            f"{DEFAULT_ATTACHMENTS_DIRNAME!r})"
        ),
    )
    ap.add_argument(
        "--inplace", action="store_true", help="OCR in-place (default behavior)"
    )
    ap.add_argument(
        "--pages-check", type=int, default=3, help="Pages to check for text"
    )
    ap.add_argument(
        "--lang", default="eng", help="Tesseract/OCR language(s), e.g. eng+deu"
    )
    ap.add_argument(
        "--dpi", type=int, default=300, help="DPI for fallback rasterization"
    )
    ns = ap.parse_args(argv)

    if not str(ns.attachments_dirname).strip():
        print("--attachments-dirname must be non-empty", file=sys.stderr)
        return 2

    root = Path(ns.dir).resolve()
    if not root.exists() or not root.is_dir():
        print(f"Not a directory: {root}", file=sys.stderr)
        return 2

    # Note: _iter_pdfs() is top-level only; this is an additional safeguard if the
    # attachments folder is passed via --dir.
    attachments_dirname = str(ns.attachments_dirname)
    pdfs = [p for p in _iter_pdfs(root) if p.parent.name != attachments_dirname]
    if not pdfs:
        print(f"No PDFs found in: {root}")
        return 0

    have_ocrmypdf = _have("ocrmypdf")
    if not have_ocrmypdf:
        # This is informational; we can still proceed with fallback.
        print(
            "Note: ocrmypdf not found; using fallback (pdftoppm+tesseract+qpdf) when needed."
        )

    changed = 0
    skipped = 0
    failed = 0

    for p in pdfs:
        try:
            if _pdftotext_has_text(p, ns.pages_check):
                skipped += 1
                continue

            tmp_out = p.with_name(p.name + ".ocr-tmp.pdf")
            if tmp_out.exists():
                tmp_out.unlink()

            if have_ocrmypdf:
                _ocr_with_ocrmypdf(p, tmp_out, lang=ns.lang)
            else:
                _ocr_with_tesseract_fallback(p, tmp_out, lang=ns.lang, dpi=ns.dpi)

            if tmp_out.exists() and tmp_out.stat().st_size > 0:
                os.replace(tmp_out, p)
                changed += 1
            else:
                raise RuntimeError("OCR produced no output")

        except Exception as e:
            failed += 1
            print(f"OCR failed: {p.name}: {e}", file=sys.stderr)
            try:
                tmp = p.with_name(p.name + ".ocr-tmp.pdf")
                if tmp.exists():
                    tmp.unlink()
            except Exception:
                pass

    print(f"Done. OCRed={changed}, already-text={skipped}, failed={failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

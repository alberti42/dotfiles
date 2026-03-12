#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from email import policy
from email.parser import BytesParser
from pathlib import Path


JUNK_NAMES = {
    ".ds_store",
    "thumbs.db",
    "desktop.ini",
}


def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def run(cmd: list[str]) -> None:
    p = subprocess.run(
        cmd, check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if p.returncode != 0:
        raise RuntimeError(
            "Command failed:\n"
            + "  "
            + " ".join(cmd)
            + "\n\n"
            + (p.stderr.strip() or p.stdout.strip())
        )


def strip_html(s: str) -> str:
    s = re.sub(r"<script[\s\S]*?</script>", "", s, flags=re.IGNORECASE)
    s = re.sub(r"<style[\s\S]*?</style>", "", s, flags=re.IGNORECASE)
    s = re.sub(r"<[^>]+>", " ", s)
    s = re.sub(r"\s+", " ", s)
    return s.strip()


def extract_eml_text(src: Path) -> str:
    msg = BytesParser(policy=policy.default).parsebytes(src.read_bytes())
    headers = []
    for k in ("Date", "From", "To", "Cc", "Bcc", "Subject"):
        v = msg.get(k)
        if v:
            headers.append(f"{k}: {v}")

    parts: list[str] = []
    if msg.is_multipart():
        for part in msg.walk():
            ctype = part.get_content_type()
            if ctype == "text/plain":
                try:
                    parts.append(part.get_content())
                except Exception:
                    pass
    else:
        try:
            parts.append(msg.get_content())
        except Exception:
            pass

    if not parts:
        # Fallback: try HTML.
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/html":
                    try:
                        parts.append(strip_html(part.get_content()))
                    except Exception:
                        pass
        else:
            if msg.get_content_type() == "text/html":
                try:
                    parts.append(strip_html(msg.get_content()))
                except Exception:
                    pass

    body = "\n\n".join(p.strip() for p in parts if p and p.strip())
    return "\n".join(headers + ["", body]).strip() + "\n"


def pdf_to_text(pdf: Path, out_txt: Path) -> None:
    out_txt.parent.mkdir(parents=True, exist_ok=True)
    # pdftotext writes directly to the output path.
    run(["pdftotext", "-nopgbrk", str(pdf), str(out_txt)])


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description="Extract searchable text from a purchase bundle"
    )
    ap.add_argument("--import-dir", required=True)
    ap.add_argument("--out-dir", default="")
    ap.add_argument("--force", action="store_true")
    ns = ap.parse_args(argv)

    import_dir = Path(ns.import_dir).expanduser().resolve()
    if not import_dir.exists() or not import_dir.is_dir():
        raise SystemExit(f"IMPORT_DIR not found or not a directory: {import_dir}")

    out_dir = (
        Path(ns.out_dir).expanduser().resolve()
        if ns.out_dir
        else (import_dir / "_extracted")
    )
    if out_dir.exists() and ns.force:
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    ocr_dir = out_dir / "ocr"
    txt_dir = out_dir / "txt"
    ocr_dir.mkdir(parents=True, exist_ok=True)
    txt_dir.mkdir(parents=True, exist_ok=True)

    manifest: list[dict] = []

    for root, dirs, files in os.walk(import_dir):
        # Skip the output dir if it lives under import_dir.
        rel_root = Path(root).resolve()
        if out_dir in rel_root.parents or rel_root == out_dir:
            continue

        for fn in files:
            src = Path(root) / fn
            rel = src.relative_to(import_dir)
            low = fn.lower()

            if low in JUNK_NAMES or low.startswith("._"):
                continue

            entry: dict = {
                "path": str(rel),
                "sha256": sha256_file(src),
                "size": src.stat().st_size,
                "kind": "binary",
                "text": None,
                "ocr_pdf": None,
            }

            try:
                if low.endswith(".pdf"):
                    entry["kind"] = "pdf"
                    out_txt = txt_dir / (rel.as_posix().replace("/", " - ") + ".txt")
                    out_txt.parent.mkdir(parents=True, exist_ok=True)
                    pdf_to_text(src, out_txt)
                    txt = out_txt.read_text(encoding="utf-8", errors="replace").strip()
                    if len(txt) < 30:
                        ocr_pdf = ocr_dir / (rel.as_posix().replace("/", "__"))
                        ocr_pdf.parent.mkdir(parents=True, exist_ok=True)
                        run(["ocrmypdf", "--skip-text", str(src), str(ocr_pdf)])
                        pdf_to_text(ocr_pdf, out_txt)
                        entry["ocr_pdf"] = str(ocr_pdf.relative_to(out_dir))
                    entry["text"] = str(out_txt.relative_to(out_dir))
                    entry["kind"] = "pdf"

                elif low.endswith(".eml"):
                    entry["kind"] = "eml"
                    out_txt = txt_dir / (rel.as_posix().replace("/", " - ") + ".txt")
                    out_txt.parent.mkdir(parents=True, exist_ok=True)
                    out_txt.write_text(extract_eml_text(src), encoding="utf-8")
                    entry["text"] = str(out_txt.relative_to(out_dir))

                elif low.endswith(".txt"):
                    entry["kind"] = "txt"
                    out_txt = txt_dir / (rel.as_posix().replace("/", " - ") + ".txt")
                    out_txt.parent.mkdir(parents=True, exist_ok=True)
                    out_txt.write_text(
                        src.read_text(encoding="utf-8", errors="replace"),
                        encoding="utf-8",
                    )
                    entry["text"] = str(out_txt.relative_to(out_dir))

                elif low.endswith(".html") or low.endswith(".htm"):
                    entry["kind"] = "html"
                    raw = src.read_text(encoding="utf-8", errors="replace")
                    out_txt = txt_dir / (rel.as_posix().replace("/", " - ") + ".txt")
                    out_txt.parent.mkdir(parents=True, exist_ok=True)
                    out_txt.write_text(strip_html(raw) + "\n", encoding="utf-8")
                    entry["text"] = str(out_txt.relative_to(out_dir))

            except Exception as e:
                entry["error"] = str(e)

            manifest.append(entry)

    manifest_path = out_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )

    all_path = out_dir / "ALL.txt"
    with all_path.open("w", encoding="utf-8") as out:
        for e in manifest:
            out.write("=" * 80 + "\n")
            out.write(f"FILE: {e['path']}\n")
            out.write(f"KIND: {e.get('kind')}\n")
            if e.get("text"):
                txtp = out_dir / str(e["text"])
                out.write("\n")
                try:
                    out.write(txtp.read_text(encoding="utf-8", errors="replace"))
                except Exception:
                    out.write("(failed to read extracted text)\n")
            out.write("\n")

    print(str(all_path))
    print(str(manifest_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

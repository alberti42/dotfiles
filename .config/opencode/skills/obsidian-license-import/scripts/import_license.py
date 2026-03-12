#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import os
import re
import shutil
import sys
import unicodedata
import uuid
from pathlib import Path


JUNK_LOWER = {
    ".ds_store",
    "thumbs.db",
    "desktop.ini",
}

JUNK_SUFFIXES = (
    ".swp",
    ".tmp",
    ".part",
    ".crdownload",
)


def slugify_filename(s: str) -> str:
    s = (s or "").strip()
    # Obsidian wikilink safety + readability.
    # - '#' in wikilinks is treated as a heading separator.
    # - '^' is treated as a block reference separator.
    # - '|' is treated as an alias separator.
    # - '[' and ']' can interfere with wiki link syntax.
    # - ':' is safe on macOS but awkward; use ' - ' for readability.
    s = unicodedata.normalize("NFC", s)
    s = s.replace(":", " - ")
    s = s.replace("|", " - ")
    s = s.replace("[", "(").replace("]", ")")
    s = s.replace("^", " ")

    # Handle '#' carefully:
    # - '# 123' / '#123' -> 'No 123'
    # - 'C#' / 'F#' -> 'Csharp' / 'Fsharp'
    s = re.sub(r"#\s*(\d+)", r" No \1", s)
    s = re.sub(r"([A-Za-z])#(?!\w)", r"\1sharp", s)
    s = s.replace("#", " No ")

    s = s.replace(os.sep, "-")
    s = re.sub(r"[\x00-\x1f]", " ", s)
    s = re.sub(r"[\\/:*?\"<>|]", "-", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s or "Untitled"


def nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s)


def now_local_iso() -> str:
    return dt.datetime.now().astimezone().isoformat(timespec="seconds")


def parse_purchase_dt(purchase_date: str, purchase_time: str) -> dt.datetime:
    tz = dt.datetime.now().astimezone().tzinfo
    if tz is None:
        tz = dt.timezone.utc
    d = dt.date.fromisoformat(purchase_date)
    t = dt.time.fromisoformat(purchase_time)
    return dt.datetime(d.year, d.month, d.day, t.hour, t.minute, t.second, tzinfo=tz)


def yaml_quote(s: str) -> str:
    s = s.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{s}"'


def should_skip(rel: Path) -> bool:
    name = rel.name
    low = name.lower()
    if low in JUNK_LOWER:
        return True
    if low.startswith("._"):
        return True
    if low.endswith(JUNK_SUFFIXES):
        return True
    if low.startswith("~$"):
        return True
    return False


def dest_name_for_rel(rel: Path) -> str:
    # Flatten subdirs into a single filename prefix.
    if len(rel.parts) == 1:
        return slugify_filename(rel.name)
    prefix = " - ".join(rel.parts[:-1])
    return slugify_filename(prefix + " - " + rel.name)


def ensure_unique_filename(name: str, used: set[str]) -> str:
    if name not in used:
        return name
    p = Path(name)
    stem = p.stem
    suf = p.suffix
    i = 2
    while True:
        cand = f"{stem} ({i}){suf}"
        if cand not in used:
            return cand
        i += 1


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description="Create an Obsidian purchase note and copy bundle files"
    )
    ap.add_argument("--import-dir", required=True)
    ap.add_argument("--note-name", required=True)
    ap.add_argument("--purchase-date", required=True)
    ap.add_argument("--purchase-time", default="12:00:00")
    ap.add_argument(
        "--out-dir", default="/Users/andrea/Obsidian/Work/12 Software licenses"
    )

    ap.add_argument("--version", default="")
    ap.add_argument("--vendor", default="")
    ap.add_argument("--amount", default="")
    ap.add_argument("--currency", default="")
    ap.add_argument("--registered-email", default="")
    ap.add_argument("--licensed-to", default="")
    ap.add_argument("--license-key", default="")

    ns = ap.parse_args(argv)

    import_dir = Path(ns.import_dir).expanduser().resolve()
    if not import_dir.exists() or not import_dir.is_dir():
        sys.stderr.write(f"IMPORT_DIR not found or not a directory: {import_dir}\n")
        return 2

    out_dir = Path(ns.out_dir).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    purchase_date = (ns.purchase_date or "").strip()
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", purchase_date):
        sys.stderr.write("purchase-date must be YYYY-MM-DD\n")
        return 2

    purchase_time = (ns.purchase_time or "").strip() or "12:00:00"
    if not re.fullmatch(r"\d{2}:\d{2}:\d{2}", purchase_time):
        sys.stderr.write("purchase-time must be HH:MM:SS\n")
        return 2

    note_name = nfc(ns.note_name.strip())
    created_dt = parse_purchase_dt(purchase_date, purchase_time)
    created = created_dt.astimezone().isoformat(timespec="seconds")
    modified = now_local_iso()

    stem = slugify_filename(f"{created_dt.date().isoformat()} {note_name}")
    note_path = out_dir / f"{stem}.md"
    attach_dir = out_dir / f"{stem} (attachments)"
    attach_dir.mkdir(parents=True, exist_ok=True)

    copied: list[tuple[str, str]] = []
    skipped: list[str] = []
    used: set[str] = set()

    for root, dirs, files in os.walk(import_dir):
        # Skip generated directories inside IMPORT_DIR.
        dirs[:] = [d for d in dirs if d not in {"_extracted"} and not d.startswith(".")]
        dirs.sort()
        files.sort()

        for fn in files:
            src = Path(root) / fn
            rel = src.relative_to(import_dir)
            if should_skip(rel):
                skipped.append(str(rel))
                continue

            dest_name = dest_name_for_rel(rel)
            dest_name = ensure_unique_filename(dest_name, used)
            used.add(dest_name)

            dst = attach_dir / dest_name
            shutil.copy2(src, dst)
            copied.append((rel.as_posix(), dest_name))

    fm: list[str] = ["---"]
    fm.append(f"created: {created}")
    fm.append(f"modified: {modified}")
    fm.append("tags:")
    fm.append('  - "#Purchase/Software"')
    fm.append(f"uuid: {uuid.uuid4()}")

    def add_if(key: str, val: str) -> None:
        v = (val or "").strip()
        if v:
            fm.append(f"{key}: {yaml_quote(nfc(v))}")

    # Intentionally keep YAML minimal; store details in Markdown sections.
    fm.append("---")

    body: list[str] = []
    body.append(f"# {note_name}")
    body.append("")

    lk = (ns.license_key or "").strip()
    if lk:
        body.append("> [!secret]- License key")
        body.append("> ```text")
        for line in nfc(lk).splitlines() or [""]:
            body.append("> " + line)
        body.append("> ```")
        body.append("")

    body.append("## Purchase")
    body.append("")
    body.append(f"- Ordered at: {created}")
    if ns.vendor.strip():
        body.append(f"- Vendor: {nfc(ns.vendor.strip())}")
    if ns.amount.strip() or ns.currency.strip():
        body.append(
            f"- Amount: {nfc(ns.amount.strip())} {nfc(ns.currency.strip())}".rstrip()
        )
    if ns.version.strip():
        body.append(f"- Version: {nfc(ns.version.strip())}")
    if ns.registered_email.strip():
        body.append(f"- Registered email: {nfc(ns.registered_email.strip())}")
    if ns.licensed_to.strip():
        body.append(f"- Licensed to: {nfc(ns.licensed_to.strip())}")
    body.append("")

    body.append("## Attachments")
    body.append("")
    attach_dir_name = f"{stem} (attachments)"
    for src_rel, dest_name in sorted(copied, key=lambda x: x[1].lower()):
        disp = nfc(dest_name)
        target = f"{attach_dir_name}/{dest_name}"
        body.append(f"- [[{target}|{disp}]]")
    body.append("")

    body.append("## Notes")
    body.append("")
    body.append("(add notes here)")
    body.append("")

    note_text = "\n".join(fm + [""] + body).rstrip() + "\n"
    note_path.write_text(note_text, encoding="utf-8")

    print(str(note_path))
    for src_rel, dest_name in copied:
        if src_rel != dest_name:
            print(f"RENAMED: {src_rel} -> {dest_name}")
    for s in sorted(set(skipped)):
        print(f"SKIPPED: {s}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

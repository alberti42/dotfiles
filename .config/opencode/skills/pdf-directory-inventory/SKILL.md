---
name: pdf-directory-inventory
description: Inventory/review all PDFs in the current directory by extracting text (prefer @pdf_inventory.py when present), OCRing scanned/textless PDFs, writing a human-readable Markdown index (pdf_inventory.md) with one section per PDF and Obsidian-style links, and moving the inventoried PDFs into a 'pdf_inventory (attachments)' folder.
---

Inventory PDFs in the current working directory.

Do this workflow:

1) Identify PDFs to inventory

- Work on top-level `*.pdf` in the current directory.
- Ignore PDFs already inside `pdf_inventory (attachments)/`.

2) OCR PDFs that do not contain extractable text

- Prefer `ocrmypdf` when available.
- If `ocrmypdf` is not available, use the fallback pipeline (Poppler + Tesseract + qpdf) via the helper script shipped with this skill.

Run (in the directory containing the PDFs):

```bash
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/ocr_pdfs.py --inplace --lang eng
```

Notes:

- Use `--lang eng+deu` (or similar) when documents are multilingual.
- If a PDF is encrypted or OCR fails, leave it as-is and mention the limitation in the final `pdf_inventory.md` entry.

3) Extract text cues for summarization

- If `pdf_inventory.py` exists in the directory, use it to generate a compact probe file:

```bash
python3 pdf_inventory.py
```

This produces `_pdf_probe.md` with: page count, size, metadata, TOC cues, and short text snippets.

- If `pdf_inventory.py` is missing or fails, fall back to Poppler:

```bash
pdfinfo "file.pdf"
pdftotext -f 1 -l 3 -nopgbrk "file.pdf" -
```

4) Write `pdf_inventory.md`

- Create a Markdown file named exactly `pdf_inventory.md` in the current directory.
- Start with a short 1-3 sentence intro describing what this inventory covers.
- For each PDF, write a section matching this pattern (linked, not embedded):

```md
# <Human Title>

- Link: [[pdf_inventory (attachments)/<File Name>.pdf|<File Name>.pdf]]
- Pages: <N>; Size: <Human size>

<2-6 sentences: what this document is, intended audience/context, key topics.>

<Optional: 1 short paragraph on how/when to use it.>
```

Guidelines for the human summary:

- Prefer concrete nouns and scope: "course handout", "manual", "invoice bundle", "slides", "paper", "policy".
- Use TOC cues (if present) to list the main modules/topics in a single sentence.
- If OCR was needed, mention that it was OCR'd (and note any quality issues if obvious).

5) Move inventoried PDFs into `pdf_inventory (attachments)`

- Create the directory if it does not exist.
- Move each inventoried `*.pdf` (top-level) into `pdf_inventory (attachments)/`.
- Ensure file names in the folder match the links written in `pdf_inventory.md`.

Recommended move command (handles spaces):

```bash
mkdir -p "pdf_inventory (attachments)"
for f in ./*.pdf; do [ -e "$f" ] || break; mv "$f" "pdf_inventory (attachments)/"; done
```

Leave `pdf_inventory.md` in the current directory. Keeping `_pdf_probe.md` is fine (it is machine-generated support material).

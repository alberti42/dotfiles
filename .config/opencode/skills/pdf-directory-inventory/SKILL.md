---
name: pdf-directory-inventory
description: Inventory/review all PDFs in the current directory by OCRing scanned/textless PDFs, mechanically extracting a probe file (_pdf_probe.md) for summarization, writing a human-readable Markdown note ({{NOTE_NAME}}.md) with one section per PDF and Obsidian-style links, and moving the inventoried PDFs into a '{{NOTE_NAME}} (attachments)' folder. Requires the user to specify NOTE_NAME.
---

Inventory PDFs in the current working directory.

Treat the Python scripts shipped with this skill as tools:

- Do NOT open/read `scripts/*.py` during execution.
- Do NOT guess flags or behavior.
- Only run the commands documented in this file (CLI reference is the source of truth).

Do this workflow:

0) Require NOTE_NAME (hard stop)

- The user MUST specify `NOTE_NAME='...'` (or equivalent instruction) before you do anything.
- If `NOTE_NAME` is not specified, STOP and ask the user for it.
- Use:
  - Note: `{{NOTE_NAME}}.md`
  - Attachments directory: `{{NOTE_NAME}} (attachments)/`

1) Preflight: check dependencies (fail fast)

- Run the dependency check script FIRST (after NOTE_NAME is known).
- If it fails, STOP and instruct the user to start OpenCode from the correct Python environment (common mistake).

Run:

```bash
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/check_deps.py
```

After this dependency check succeeds, create a TODO list (using the TODO tool) for the remaining workflow steps.
Keep harmonization/deduplication as an explicit TODO item so the user can add special instructions for that part.

Execution pacing:

- STOP immediately after creating the TODO list to let the user adjust it.
- Then proceed one TODO item at a time.
- After completing each TODO item/step, STOP and invite feedback; update the TODO list accordingly before continuing.

2) Identify PDFs to inventory

- Work on top-level `*.pdf` in the current directory.
- Ignore PDFs already inside `{{NOTE_NAME}} (attachments)/`.

3) OCR PDFs that do not contain extractable text

- Prefer `ocrmypdf` when available.
- If OCR cannot run (missing dependencies or errors), STOP and ask the user.

Run (in the directory containing the PDFs):

```bash
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/ocr_pdfs.py --inplace --lang eng --attachments-dirname "{{NOTE_NAME}} (attachments)"
```

Notes:

- Use `--lang eng+deu` (or similar) when documents are multilingual.
- If a PDF is encrypted or OCR fails, leave it as-is and mention the limitation in the final `{{NOTE_NAME}}.md` entry.

4) Extract text cues for summarization

- This step MUST be fully mechanical: do not read PDF contents into the model context before `_pdf_probe.md` exists.
- Use the extractor script shipped with this skill to generate `_pdf_probe.md`.
- If the extractor script is missing or fails, STOP and ask the user.

Run:

```bash
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/pdf_inventory_extract.py --extract --note-name "{{NOTE_NAME}}" --max-lines 50
```

This produces `_pdf_probe.md` with deterministic, grep-friendly entries and excerpts (up to `--max-lines` lines per PDF; fewer for small documents).

5) Write `{{NOTE_NAME}}.md`

- Create or update a Markdown file named exactly `{{NOTE_NAME}}.md` in the current directory.
- The note MUST start with a YAML frontmatter block.

If creating a new note, write this YAML frontmatter first:

```YAML
---
created: <NOW in ISO-8601 with timezone>
modified: <NOW in ISO-8601 with timezone>
tags:
  - "#Documents"
uuid: <NEW UUID>
---
```

If updating an existing note:

- If a `uuid:` already exists in the YAML frontmatter, KEEP it unchanged.
- If no `uuid:` exists, add a new one.
- Update `modified:` to now (ISO-8601 with timezone).
- Keep `created:` unchanged if present; if missing, add it.
- Ensure `tags:` includes `"#Documents"` (preserve any other tags).

If the existing file starts with a YAML block but it is malformed/ambiguous, STOP and ask the user (do not rewrite the note).

- Start with a short 1-3 sentence intro describing what this inventory covers.
- For each PDF, write a section matching this pattern (linked, not embedded):

```md
# <Human Title>

- Link: [[{{NOTE_NAME}} (attachments)/<File Name>.pdf|<File Name>.pdf]]
- Pages: <N>; Size: <Human size>
- Probe: <N> {<doc_uuid>}

<2-6 sentences: what this document is, intended audience/context, key topics.>

<Optional: 1 short paragraph on how/when to use it.>
```

Guidelines for the human summary:

- Prefer concrete nouns and scope: "course handout", "manual", "invoice bundle", "slides", "paper", "policy".
- Use TOC cues (if present) to list the main modules/topics in a single sentence.
- If OCR was needed, mention that it was OCR'd (and note any quality issues if obvious).

5b) Deduplicate and harmonize entries

- Use `_pdf_probe.md` as the source of truth for identity.
- Each entry in `{{NOTE_NAME}}.md` MUST include `Probe: <N> {<doc_uuid>}`.
- If two entries in `{{NOTE_NAME}}.md` have the same `{<doc_uuid>}`, they are duplicates.

Duplicate handling rules:

- Do not delete PDFs and do not rewrite filenames without asking the user.
- Merge duplicate note sections into one:
  - Keep one `<Human Title>` (choose the clearer/more specific title).
  - Keep all distinct PDF links as a list (one per filename).
  - Keep a single `Probe: <N> {<doc_uuid>}` line.
  - Merge descriptions without repeating identical sentences.
- If a note entry is missing a `Probe:` line or has an invalid/missing UUID, STOP and ask the user (do not guess).

Harmonization rules:

- Ensure every entry follows the same bullet order: `Link`, `Pages/Size`, `Probe`.
- Ensure spacing and link format are consistent.

6) Move inventoried PDFs into `{{NOTE_NAME}} (attachments)`

- Create the directory if it does not exist: `{{NOTE_NAME}} (attachments)/`.
- Move each inventoried `*.pdf` (top-level) into `{{NOTE_NAME}} (attachments)/`.
- Ensure file names in the folder match the links written in `{{NOTE_NAME}}.md`.

Recommended move command (handles spaces):

```bash
mkdir -p "{{NOTE_NAME}} (attachments)"
for f in ./*.pdf; do [ -e "$f" ] || break; mv "$f" "{{NOTE_NAME}} (attachments)/"; done
```

Leave `{{NOTE_NAME}}.md` in the current directory. Keeping `_pdf_probe.md` is fine (it is machine-generated support material).

## CLI reference (do not load script code)

All commands run from the directory containing the PDFs.

```bash
# Preflight: check dependencies
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/check_deps.py

# Note: do not read/inspect scripts/*.py. Use these commands as-is.

# OCR (skip already-searchable PDFs)
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/ocr_pdfs.py \
  --inplace \
  --lang eng \
  --attachments-dirname "{{NOTE_NAME}} (attachments)"

# Extract mechanical probe (creates/overwrites _pdf_probe.md)
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/pdf_inventory_extract.py \
  --extract \
  --note-name "{{NOTE_NAME}}" \
  --max-lines 50

# Retrieve entries from _pdf_probe.md for delegated review
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/pdf_inventory_retrieve.py --retrieve 1
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/pdf_inventory_retrieve.py --retrieve 3..9 --max-lines 25
python3 ~/.config/opencode/skills/pdf-directory-inventory/scripts/pdf_inventory_retrieve.py --retrieve all
```

## Appendix: Script --help output (keep in sync)

This appendix mirrors the scripts' `--help` output so the agent can treat them as tools without reading `scripts/*.py`.
If script help changes, update this appendix.

### check_deps.py --help

```text
usage: check_deps.py [-h]

Fail-fast dependency check for pdf-directory-inventory. Verifies Python
version, required imports, and required executables on PATH.

options:
  -h, --help  show this help message and exit
```

### ocr_pdfs.py --help

```text
usage: ocr_pdfs.py [-h] [--dir DIR]
                   [--attachments-dirname ATTACHMENTS_DIRNAME] [--inplace]
                   [--pages-check PAGES_CHECK] [--lang LANG] [--dpi DPI]

options:
  -h, --help            show this help message and exit
  --dir DIR             Directory containing PDFs (default: .)
  --attachments-dirname ATTACHMENTS_DIRNAME
                        Name of attachments directory to ignore (default:
                        'pdf_inventory (attachments)')
  --inplace             OCR in-place (default behavior)
  --pages-check PAGES_CHECK
                        Pages to check for text
  --lang LANG           Tesseract/OCR language(s), e.g. eng+deu
  --dpi DPI             DPI for fallback rasterization
```

### pdf_inventory_extract.py --help

```text
usage: pdf_inventory_extract.py [-h] [--dir DIR] [--extract]
                                --note-name NOTE_NAME [--max-lines MAX_LINES]
                                [--max-pages MAX_PAGES]

options:
  -h, --help            show this help message and exit
  --dir DIR             Directory containing PDFs (default: .)
  --extract             Generate _pdf_probe.md in the target directory
  --note-name NOTE_NAME
                        NOTE_NAME base used for attachments directory
                        exclusion
  --max-lines MAX_LINES
                        Maximum excerpt lines per PDF entry (default: 50)
  --max-pages MAX_PAGES
                        Maximum pages to scan for excerpt text (default: 10)
```

### pdf_inventory_retrieve.py --help

```text
usage: pdf_inventory_retrieve.py [-h] [--dir DIR] --retrieve RETRIEVE
                                 [--max-lines MAX_LINES]

options:
  -h, --help            show this help message and exit
  --dir DIR             Directory containing _pdf_probe.md (default: .)
  --retrieve RETRIEVE   Entry selector: N, A..B, or all
  --max-lines MAX_LINES
                        Trim excerpt to at most N lines per entry; -1 disables
                        trimming (default: -1)
```

# Agents Notes: pdf-directory-inventory skill

This file documents the intent, constraints, and operating model for the global OpenCode skill `pdf-directory-inventory`.
It exists so we can return later and extend the workflow without re-deriving the core ideas.

## Goal

Inventory all top-level PDFs in a directory into a single Obsidian-friendly Markdown note, while keeping the extraction phase fully mechanical.

Outputs (templated):

- Note: `{{NOTE_NAME}}.md`
- Attachments: `{{NOTE_NAME}} (attachments)/`
- Mechanical probe: `_pdf_probe.md`

## Non-negotiable constraints

- Require `NOTE_NAME` (hard stop): if the user does not specify `NOTE_NAME='...'`, do nothing and ask.
- Fail fast: once `NOTE_NAME` is known, run `scripts/check_deps.py` before OCR/extraction so we don't crash mid-work.
- Treat shipped scripts as tools: do not read/inspect `scripts/*.py` during execution; rely on `SKILL.md` CLI reference.
- Keep the docs in sync: `SKILL.md` CLI reference and "Appendix: Script --help output" must match the scripts' actual `--help` output.
- No fallbacks: if required scripts/tools are missing or fail, stop and ask (do not silently switch pipelines).
- Mechanical extraction first: the agent must not ingest PDF contents into its own context until `_pdf_probe.md` exists.
- Determinism: probe entries must be easy to grep and slice by index for future delegation.

## Four shipped scripts

All live in `pdf-directory-inventory/scripts/`.

1) `check_deps.py`

- Purpose: fail-fast dependency check (common issue: wrong Python environment / missing tools).

2) `ocr_pdfs.py`

- Purpose: make scanned/textless PDFs searchable before extraction.
- Key behavior: can ignore an attachments directory via `--attachments-dirname` (so it does not touch already-archived PDFs).

3) `pdf_inventory_extract.py`

- Purpose: generate `_pdf_probe.md` mechanically.
- Key behaviors:
  - Lists top-level PDFs (sorted by filename casefold).
  - Excludes PDFs in `{{NOTE_NAME}} (attachments)/`.
  - Computes SHA256 of the PDF and derives a deterministic UUID (UUIDv5 of the hash).
  - Writes entries with grep-friendly headings:
    - `## 1. <Title> {<doc_uuid>}`
    - `## 2. ...`
  - Extracts excerpt text via `pdftotext` and includes up to `--max-lines` lines (default 50).
  - Writes `_pdf_probe.md` atomically (temp file then rename).

4) `pdf_inventory_retrieve.py`

- Purpose: slice `_pdf_probe.md` into deterministic blocks for future delegation.
- Supported selectors:
  - `--retrieve 1`
  - `--retrieve 3..9`
  - `--retrieve all`
- Optional trimming: `--max-lines` trims only the excerpt block per entry.

## Note format requirements

`{{NOTE_NAME}}.md` must start with YAML frontmatter.

- On create:
  - `created`: now (ISO-8601 with timezone)
  - `modified`: now (ISO-8601 with timezone)
  - `tags`: include `"#Documents"`
  - `uuid`: new UUID
- On update:
  - Keep existing `uuid` if present.
  - Update `modified`.
  - Keep `created`.
  - Ensure `"#Documents"` is present in tags.
- If YAML frontmatter is present but malformed/ambiguous: stop and ask.

Each per-PDF section must include the probe identity line:

- `Probe: <N> {<doc_uuid>}`

## Deduplication/harmonization model

Identity source of truth is `_pdf_probe.md`.

- If two note entries have the same `{<doc_uuid>}`, they are duplicates.
- Merge duplicate note sections; do not delete PDFs and do not rename files without asking.
- Normalize bullet order across entries: `Link`, `Pages/Size`, `Probe`.

## Subagents (optional, not required)

The current skill does not require subagents.

The probe + retrieve design exists so we can later delegate blocks (e.g. 5 entries at a time) to reviewer subagents.
If/when we do that, the orchestrator should use `pdf_inventory_retrieve.py` to pass only a bounded block to a reviewer.

## Validation

- `skill-creator/scripts/quick_validate.py` validates the skill metadata.
- If the host Python is externally managed (PEP 668), run validation in a temporary venv.

## Using skill-creator

Agents working on this skill can and should use the `skill-creator` skill for:

- Updating `SKILL.md` structure/wording without breaking conventions.
- Adding new scripts or extending workflows while preserving constraints.
- Running lightweight validation to catch packaging/format issues early.

## Known follow-ups (future)

- Add clearer CLI reference examples for `--dir` and `--max-pages`.
- Keep the dependency check script short and dependency-free.
- Consider making excerpt extraction more robust for PDFs with unusual layout (still deterministic).

---
name: obsidian-license-import
description: Import a new software license purchase bundle (PDF invoices, .eml emails, misc docs) from a local directory into the Obsidian folder /Users/andrea/Obsidian/Work/12 Software licenses as a single Markdown note plus a '(attachments)' folder with wikilinks. Use when the user provides IMPORT_DIR and NOTE_NAME and wants metadata extracted (purchase date, app name, version, vendor, order/invoice IDs, amount/currency) without putting license keys in YAML.
---

Treat the Python scripts shipped with this skill as tools:

- Do NOT open/read `scripts/*.py` during execution.
- Do NOT guess flags or behavior.
- Only run the commands documented in this file (the CLI reference below is the source of truth).

Strict rules (no improvisation):

- Hard-stop if `IMPORT_DIR` is missing.
- If `NOTE_NAME` is missing, propose choices and ask the user to pick one (hard-stop until the user chooses).
- Hard-stop if purchase date cannot be extracted confidently; ask the user for `PURCHASE_DATE=YYYY-MM-DD`.
- Never put license keys or activation codes in YAML frontmatter.
- Never echo secrets in chat output (do not paste keys/codes into the conversation).
- Store secrets ONLY in the note body using an Obsidian callout blockquote, collapsed by default.

Required exact format for a license key:

````markdown
> [!secret]- License key
> ```text
> SECRET-NUMBER-HERE
> ```
````

Rules for secrets:

- Every line in the callout (including the fenced code block) must start with `>`.
- Put the secret value inside a fenced code block with info string `text`.
- If multiple secrets exist (e.g. activation code, customer number), use separate callouts with clear titles.
- Do not repeat the secret elsewhere in the note (not in YAML, not in attachments list, not in extracted-text summaries).
- Always COPY files from `IMPORT_DIR` into the note's `(attachments)` folder (do not move or delete).
- Attachment filenames are sanitized mechanically by `import_license.py` to avoid broken Obsidian wikilinks when names contain characters like `#`, `^`, `|`, `[`, `]`, `:`.
- Do NOT attempt to predict or construct the final attachment filenames or link targets; `import_license.py` writes links based on the actual written filenames.
- Skipped files (junk/temp) must be reported in chat output, not written into the note.

Target location:

- Notes live in: `/Users/andrea/Obsidian/Work/12 Software licenses`
- One purchase note + one sibling attachments folder.

Naming:

- Note filename: `YYYY-MM-DD NOTE_NAME.md` (date derived from `created`)
- Attachments folder: `YYYY-MM-DD NOTE_NAME (attachments)/`

YAML frontmatter schema (minimal + non-sensitive; ISO timestamps required):

```yaml
---
created: 2026-03-06T20:01:08+01:00   # order time (local timezone)
modified: 2026-03-06T23:11:54+01:00  # import time (current local time)
tags:
  - "#Purchase/Software"
uuid: <uuid-v4>
---
```

Important:

- `created` and `modified` MUST be full ISO 8601 timestamps including timezone offset, with seconds:
  - `YYYY-MM-DDTHH:MM:SS±HH:MM`
- `created` MUST be the order time.
- `modified` SHOULD be the current time at import.

Purchase datetime extraction rules:

- Preferred source: order confirmation email (`.eml`) Date header.
- Convert to local timezone when writing `created`.
- If you only have a date (no time), use the conventional time `12:00:00` (noon) local time.
- If purchase date cannot be extracted confidently, stop and ask the user for `PURCHASE_DATE=YYYY-MM-DD`.

Body sections (recommended):

- `> [!secret]- License key` callout (only if a key/code is found or the user provides it)
- `## Purchase` (human-readable extracted fields)
- `## Attachments` (wikilinks)
- `## Notes` (optional)

Do this workflow:

0) Require inputs (hard stop)

- Require `IMPORT_DIR=/absolute/path/to/folder`.

NOTE_NAME selection (always use OpenCode question UI when NOTE_NAME not provided):

- If the user already provided `NOTE_NAME=...`, use it as-is.
- If the user did NOT provide NOTE_NAME:
  - Run step (2) first to extract `{{IMPORT_DIR}}/_extracted/ALL.txt`.
  - Generate 3-6 NOTE_NAME proposals using:
    - user-provided hints in the request (app name; perpetual vs subscription; year/edition; upgrade/renewal)
    - invoice/product titles and email subjects found in `ALL.txt`
  - Present proposals via an interactive choice prompt (best guess first, marked as Recommended).
  - The choice prompt must allow free-text entry (OpenCode adds a "Type your own answer" option automatically).
  - Do not include the date in NOTE_NAME; the date is derived from `created` and used in the filename separately.

Examples of realistic NOTE_NAME proposals (do not enforce a fixed vocabulary; these are just patterns):

- `Carbon Copy Cloner 7`
- `Carbon Copy Cloner 7 (Perpetual)`
- `Little Snitch (Subscription 2026)`
- `Little Snitch 2026`
- `JetBrains All Products Pack`
- `JetBrains All Products Pack (Subscription)`

1) Preflight (fail fast)

Run:

```bash
python3 ~/.config/opencode/skills/obsidian-license-import/scripts/check_deps.py
```

If it fails, stop and tell the user what is missing.

2) Extract text bundle (for search)

Run:

```bash
python3 ~/.config/opencode/skills/obsidian-license-import/scripts/extract_bundle_text.py \
  --import-dir "{{IMPORT_DIR}}"
```

Then search within `{{IMPORT_DIR}}/_extracted/ALL.txt` using `rg`/`grep` to extract:

- purchase datetime (preferred: `.eml` Date header)
- version (optional)
- vendor (optional)
- amount + currency (optional)
- license key (if present; do not store in YAML)

If purchase date is missing/ambiguous: stop and ask the user for `PURCHASE_DATE=YYYY-MM-DD`.

If time is missing: set `PURCHASE_TIME=12:00:00`.

3) Create the note and copy attachments

Run:

```bash
python3 ~/.config/opencode/skills/obsidian-license-import/scripts/import_license.py \
  --import-dir "{{IMPORT_DIR}}" \
  --note-name "{{NOTE_NAME}}" \
  --purchase-date "{{PURCHASE_DATE}}" \
  --purchase-time "{{PURCHASE_TIME}}" \
  --version "{{VERSION}}" \
  --vendor "{{VENDOR}}" \
  --amount "{{AMOUNT}}" \
  --currency "{{CURRENCY}}" \
  --registered-email "{{REGISTERED_EMAIL}}" \
  --licensed-to "{{LICENSED_TO}}" \
  --license-key "{{LICENSE_KEY}}"
```

Only pass optional flags when values are known.

4) Report skipped files in chat

The import script prints:

- `RENAMED: <src> -> <dest>` for files whose copied attachment filename differs from the original relative path.
- `SKIPPED: <relative path>` for junk/temp files.

Relay these lists in chat (do not write them into the note).

CLI reference

- `check_deps.py`
  - `python3 .../check_deps.py`
  - Exit code 0 if dependencies available; non-zero otherwise.

- `extract_bundle_text.py`
  - `--import-dir DIR` (required)
  - `--out-dir DIR` (optional; default `DIR/_extracted`)
  - `--force` (optional; overwrite out-dir)
  - Outputs:
    - `OUT_DIR/ALL.txt`
    - `OUT_DIR/manifest.json`

- `import_license.py`
  - `--import-dir DIR` (required)
  - `--note-name NAME` (required)
  - `--purchase-date YYYY-MM-DD` (required)
  - `--purchase-time HH:MM:SS` (optional; default `12:00:00` local)
  - `--out-dir DIR` (optional; default `/Users/andrea/Obsidian/Work/12 Software licenses`)
  - Optional metadata flags:
    - `--version`, `--vendor`, `--amount`, `--currency`, `--registered-email`, `--licensed-to`
  - Optional secrets:
    - `--license-key` stores the value ONLY in the note body as:

      ````markdown
      > [!secret]- License key
      > ```text
      > <value>
      > ```
      ````

      Never store the value in YAML and never print it in chat.
  - Prints:
    - note path
    - lines `SKIPPED: <relative path>` for junk/temp files

## Appendix: Script --help output

This appendix mirrors the scripts' `--help` output so the agent can treat them as tools. The agent does not need and should not read `scripts/*.py`.

### check_deps.py

```text
usage: check_deps.py [-h]

Check dependencies for obsidian-license-import skill

options:
  -h, --help  show this help message and exit
```

### extract_bundle_text.py

```text
usage: extract_bundle_text.py [-h] --import-dir IMPORT_DIR [--out-dir OUT_DIR]
                              [--force]

Extract searchable text from a purchase bundle

options:
  -h, --help            show this help message and exit
  --import-dir IMPORT_DIR
  --out-dir OUT_DIR
  --force
```

### import_license.py

```text
usage: import_license.py [-h] --import-dir IMPORT_DIR --note-name NOTE_NAME
                         --purchase-date PURCHASE_DATE
                         [--purchase-time PURCHASE_TIME] [--out-dir OUT_DIR]
                         [--version VERSION] [--vendor VENDOR]
                         [--amount AMOUNT] [--currency CURRENCY]
                         [--registered-email REGISTERED_EMAIL]
                         [--licensed-to LICENSED_TO]
                         [--license-key LICENSE_KEY]

Create an Obsidian purchase note and copy bundle files

options:
  -h, --help            show this help message and exit
  --import-dir IMPORT_DIR
  --note-name NOTE_NAME
  --purchase-date PURCHASE_DATE
  --purchase-time PURCHASE_TIME
  --out-dir OUT_DIR
  --version VERSION
  --vendor VENDOR
  --amount AMOUNT
  --currency CURRENCY
  --registered-email REGISTERED_EMAIL
  --licensed-to LICENSED_TO
  --license-key LICENSE_KEY
```

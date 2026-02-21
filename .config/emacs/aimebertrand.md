# SUMMARY: Key Packages in Aimé Bertrand’s Emacs Config

This document is written for humans who want to understand the *main building blocks* of Aimé Bertrand’s Emacs configuration (the `dotemacs` repo) without reading every module.

It focuses on:

- The packages that define how Emacs *feels* (UI, completion, keybindings)
- The packages that implement the workflows described in the 2021 write-up: https://macowners.club/posts/favorite-apps-tools-2/
- Practical notes about external dependencies and what commonly breaks on bootstrap

It is intentionally *not* a full inventory of every package in `timu-bits-package-list`.

## Mental Model (What This Config Is “Made Of”)

- **Modal editing** (Vim-like) with Evil
- **Completion-first navigation** (fuzzy / narrowing) with Vertico + Consult + Orderless (+ metadata from Marginalia)
- **A custom look** (themes + modeline + fonts) via `timu-*` theme family and `timu-line`
- **Workflow modules**: Git (Magit), mail (mu4e), RSS (elfeed), file management (Dired), IDE features (LSP, completion, diagnostics)

## Packages By Workflow (Mapped to the 2021 Post)

### IDE

The 2021 post calls out: file tree, completion/docs, syntax checking, debugging.

- `dired` (built-in): directory editor (file tree as a buffer)
- `treemacs`: project/file tree sidebar (visual file tree)
- `neotree`: alternative file tree sidebar

- `company`: in-buffer completion framework (completion popup for code/text)
- `lsp-mode`: client for Language Server Protocol (code navigation, completion, docs)
- `eglot`: alternative LSP client (lighter, integrates well with built-ins)

- `flycheck`: on-the-fly diagnostics (syntax errors, lint warnings)
- `dap-mode`: Debug Adapter Protocol (debugging UI on top of LSP ecosystem)

Related “IDE feel” packages commonly used alongside the above:

- `corfu`: completion UI (small, in-buffer completion menu)
- `cape`: completion-at-point extensions (adds more completion sources)
- `eldoc-box`: shows ElDoc documentation in a child frame (hover docs)
- `tree-sitter`, `tree-sitter-langs`: incremental parsing for better highlighting/structure in supported languages

### File Manager

The post emphasizes Dired as editable buffers + powerful narrowing.

- `dired` (built-in): file manager as a text buffer; supports renames, deletes, copy, permissions, etc.
- `dired-subtree`: expand/collapse subdirectories inline inside a Dired buffer
- `dired-narrow`: narrow/filter the current Dired listing interactively
- `all-the-icons-dired`: file icons in Dired buffers
- `peep-dired`: quick preview of files while moving through Dired

For image browsing (like the post’s thumbnail screenshots):

- `image-dired` (built-in): thumbnail view + navigation for images

### Git Client

- `magit`: Git porcelain inside Emacs (status, staging, history, branches)
- `forge`: integrates Git forges (GitHub/GitLab) into Magit (issues, PRs)
- `diff-hl`: shows VCS diff indicators in the fringe (added/changed lines)
- `transient`: key-driven popup menus (used heavily by Magit; also useful elsewhere)

### Email Client

In the post this is mu4e-based.

- `mu4e` (from the external `mu` project): the Emacs mail UI
- `mu4e-column-faces`: per-column faces/colors in mu4e headers
- `mu4e-thread-folding`: fold/unfold message threads in headers view

External tools commonly required for the “mail pipeline”:

- `mu` (system package): mail indexer and the provider of mu4e
- `isync` / `mbsync` (system package): IMAP sync into a local Maildir
- `msmtp` (system package): SMTP sending

### RSS Reader

- `elfeed`: RSS/Atom reader inside Emacs
- `elfeed-org`: manage Elfeed feeds from an Org file

### PDF Tools

- `pdf-tools`: PDF rendering/annotation inside Emacs (replaces/augments built-in DocView)
- `pdfgrep`: search text in PDFs via an external `pdfgrep` binary (fast searching)

Common “PDF + notes” extensions (if you use Org workflows):

- `org-noter`: take structured notes linked to document locations
- `org-noter-pdftools`: tighter integration between org-noter and pdf-tools
- `org-pdftools`: helper functions around pdf-tools for Org link integration

### Docker Client

- `docker`: manage containers/images/volumes/networks in Emacs
- `docker-compose-mode`: editing support for `docker-compose.yml`
- `dockerfile-mode`: editing support for `Dockerfile`
- `docker-tramp`: open files *inside containers* using TRAMP

### Writing / Notes

The post is Org-centric, but the repo also has a Denote workflow.

- `org` (built-in / can be upgraded): outlining + markup + agenda + capture
- `org-roam`: networked notes (backlinks + database)
- `org-bullets`: prettier Org headings
- `org-download`: drag/drop or paste images into Org files
- `org-remark`: highlight/annotate documents and keep notes about highlights

Export/publishing stack referenced in the post:

- `ox-hugo`: export Org to Hugo-compatible Markdown
- `ox-pandoc`: export via Pandoc

Denote-based note-taking (alternative to org-roam):

- `denote`: note naming + linking scheme
- `consult-denote`: Consult UI for Denote notes
- `denote-menu`: list/manage notes
- `denote-org`: Org helpers for Denote

### Terminal / Shell

- `eshell` (built-in): Emacs shell (Elisp-based)
- `vterm`: fast terminal emulator inside Emacs (requires a compiled module)
- `multi-vterm`: manage multiple vterm buffers
- `eshell-vterm`: embed vterm inside eshell workflows

Usability/polish:

- `esh-autosuggest`: fish-like autosuggestions for eshell
- `eshell-syntax-highlighting`: highlight commands in eshell
- `dwim-shell-command`: run shell commands “do what I mean” on the current context

### Navigation / Completion (The “Modern Emacs Feel”)

This is the biggest “presentation” difference versus stock Emacs.

- `vertico`: vertical minibuffer completion UI
- `orderless`: flexible matching style (type space-separated patterns)
- `marginalia`: richer annotations for completion candidates
- `consult`: a suite of fast, consistent narrowing commands (buffers, grep, lines, etc.)
- `embark`: context actions for minibuffer candidates (act on the thing you selected)
- `embark-consult`: glue between embark and consult

Complementary navigation helpers:

- `avy`: jump to visible text by typing a short key sequence
- `ace-window`: fast window switching
- `ace-link`: quickly open links in help/info/eww buffers
- `imenu-list`: persistent Imenu sidebar for code structure

### UI / Look and Feel

The “dark macOS-inspired” vibe in the screenshots comes from a small number of choices:

- `timu-macos-theme`, `timu-spacegrey-theme`, `timu-caribbean-theme`, `timu-rouge-theme`: custom theme family
- `timu-line`: custom modeline package
- `mixed-pitch`: mix fixed/variable pitch fonts in the same buffer (used e.g. in mu4e view)
- `all-the-icons`: icon set used by multiple UI packages
- `all-the-icons-completion`: icons in minibuffer completion (pairs with marginalia)
- `which-key`: displays available keybindings after you start a key sequence
- `helpful`: richer help buffers (better than default `describe-*` output)
- `minions`: hide/show minor modes in the modeline

### “AI / Chat” Tools (present in the package list)

These are optional and not required for the core Emacs feel.

- `gptel`: chat/completions from LLM providers (various backends)
- `chatgpt-shell`: REPL-like ChatGPT interface
- `dall-e-shell`: image-generation shell interface
- `ob-chatgpt-shell`, `ob-dall-e-shell`: Org Babel blocks for the above

## Glossary: Short Descriptions (Quick Lookup)

This glossary lists the most “identity-defining” packages and what they do.

### Editing

- `evil`: Vim-style modal editing (normal/insert/visual states)
- `evil-collection`: Evil keybindings for many Emacs modes
- `evil-surround`: add/change/delete surrounding delimiters (quotes/brackets/etc.)
- `undo-tree`: visualizes undo history as a tree

### Completion & actions

- `vertico`: completion UI in minibuffer
- `orderless`: matching algorithm for completion
- `marginalia`: annotations in completion lists
- `consult`: search/narrow commands for buffers, files, lines, ripgrep, etc.
- `embark`: “act on candidate” (open, copy, export, etc.)
- `corfu`: completion popup at point (in buffers)
- `cape`: extra completion sources

### IDE core

- `eglot`: LSP client
- `lsp-mode`: LSP client (more features, more surface area)
- `company`: completion framework
- `flycheck`: diagnostics/linting
- `dap-mode`: debugging UI

### File management

- `dired` (built-in): directory editor
- `dired-subtree`: expand directories inline in Dired
- `dired-narrow`: filter Dired buffer
- `all-the-icons-dired`: icons in Dired
- `peep-dired`: preview files while navigating

### Git

- `magit`: Git UI
- `forge`: GitHub/GitLab integration for Magit
- `diff-hl`: diff markers in the fringe
- `transient`: popup key menus

### Mail

- `mu4e` (external): email UI
- `mu4e-column-faces`: per-column styling
- `mu4e-thread-folding`: fold threads

### RSS

- `elfeed`: RSS reader
- `elfeed-org`: define feeds in Org

### PDF

- `pdf-tools`: PDF viewer/annotator (requires `epdfinfo` build)
- `org-noter`: notes linked to document positions

### Docker

- `docker`: manage docker resources
- `docker-tramp`: open container files via TRAMP
- `dockerfile-mode`: Dockerfile editing
- `docker-compose-mode`: docker-compose editing

### Writing / notes

- `org`: outlining/notes/tasks/export system
- `org-roam`: linked notes with backlinks
- `ox-hugo`: export Org to Hugo Markdown
- `denote`: lightweight note system (filenames + metadata + links)

### UI polish

- `timu-macos-theme`: custom macOS-like theme
- `timu-line`: custom modeline
- `mixed-pitch`: variable-pitch text with fixed-pitch code
- `which-key`: keybinding discovery
- `helpful`: better help buffers
- `all-the-icons-completion`: icons in completion

## Notes on “Why Bootstrapping Can Be Hard” (From Practical Experience)

- Some packages require *system binaries* or *compiled helpers* (mu4e, pdf-tools, vterm).
- Some packages have moved/changed availability across MELPA/ELPA over time.
  - Example encountered in practice: `emacsql-sqlite-module` may be unavailable.
- Some modules in the public repo reference a private `timu-personal` module and variables.

## Where to Look in the Repo (If You Want to Learn the Style)

- UI + theme switching + fonts: `libraries/timu-ui.el`
- Package list and module loading order: `libraries/timu-bits.el`
- Completion/navigation setup: `libraries/timu-nav.el`
- Programming setup: `libraries/timu-prog.el`
- Dired/file management: `libraries/timu-dired.el`
- Git: `libraries/timu-git.el`
- Mail: `libraries/timu-mu4e.el`

# Dotfiles — zsh / zinit plugin system

Personal dotfiles repo. The zsh environment is managed entirely by **zinit**. This
document captures the conventions so that any edit to `.zshrc` or to a plugin
wrapper stays consistent with the rest of the setup.

> `AGENTS.md` and `*.zwc` are git-ignored (see `.gitignore`) — this file is
> local-only, and compiled zsh files are never committed.

## Layout & entry points

| Path | Role |
|------|------|
| `zsh/.zshenv` → `~/.zshenv` | Runs for **all** shells. Sets `DOTFILES_DIR`, XDG vars, `PATH`, and defines the bootstrap helpers (below). |
| `zsh/.zshrc` → `~/.zshrc` | **Interactive** shells only. The main plugin loader — read this first to see load order. |
| `zinit/src/zinit/zinit.zsh` | zinit itself; sourced at the very top of `.zshrc`. |
| `zinit/src/<tool>/<tool>.zsh` | Per-tool **wrapper snippets** (see below). |

Symlink model: `~/.config/dotfiles` → this repo, and `DOTFILES_DIR=$HOME/.config/dotfiles`.
Individual dotfiles are symlinked into `$HOME` / `~/.config`. So everywhere in the
configs, reference files via `$DOTFILES_DIR/...`.

## Bootstrap helpers (set up by `zsh/.zshenv`)

Everything is byte-compiled to `.zwc` for fast startup. Three helpers drive this.
`__zcompile_if_needed` is defined inline in `zsh/.zshenv`; the other two live in
co-located files under `zinit/src/zinit/` that `.zshenv` compiles-and-sources during
early bootstrap (`__zcompile_if_needed_and_source.zsh`, `__safe_one_off_load.zsh`):

- **`__zcompile_if_needed <file>`** — compile-only. Ensures a fresh `<file>.zwc`
  exists (`zcompile -Uz`, rebuilt whenever the source is newer, `-nt`). Used in the
  early bootstrap right before a plain `builtin source` of the same file.
- **`__zcompile_if_needed_and_source <file>`** — the workhorse: compile-if-stale,
  then `source`. **This is how every wrapper snippet is loaded from `.zshrc`.**
  (zsh transparently loads the `.zwc` when you `source` the `.zsh` path.)
- **`_safe_one_off_load <fn> [args…]`** — run `<fn>` exactly once under `set -e`,
  forwarding any extra args, then `unfunction` it. Used inside install/load hooks
  for one-shot setup that shouldn't linger as a defined function.

`zcompile -Uz`: `-U` = do **not** expand aliases at compile time (avoids surprises);
`-z` = zsh-native autoload semantics.

## Two ways a tool is added

### A. Inline one-liner — for a release binary that needs no extra setup
A single line in `.zshrc`:
```zsh
zinit <ices> for @owner/repo
```
Real examples in `.zshrc`: `jq`, `ripgrep`, `7zip`, `just`, `superfile`. e.g.
```zsh
zinit from"gh-r" lbin'jq-* -> jq' null lucid wait light-mode for @jqlang/jq
zinit binary lucid light-mode wait from'gh-r' lbin'**/rg(.exe|) -> rg' \
  cp"ripgrep*/doc/rg.1 -> $ZINIT[MAN_DIR]/man1/rg.1" for @BurntSushi/ripgrep
```

### B. Wrapper snippet — anything with config, hooks, or init code
Create `zinit/src/<tool>/<tool>.zsh`, keep its config and any hook scripts
**co-located in the same directory** (self-contained), and load it from `.zshrc`:
```zsh
__zcompile_if_needed_and_source "$DOTFILES_DIR/zinit/src/<tool>/<tool>.zsh"
```
Real examples: `starship`, `eza`, `glow`, `vivid`, `btop`, `neovim`, `fzf`, `yazi`.

## zinit ice reference (the ones this repo actually uses)

- **Source control**: `light-mode`, `lucid` (quiet), `null` / `as'null'` (don't
  source plugin files — for pure binaries), `nocompile`, `depth=1`, `blockf`
  (block a plugin from touching `fpath`, for completion plugins).
- **Turbo / lazy**: `wait` or staged `wait'0a'` / `'0b'` / `'0c'` (load after the
  first prompt). **Prompts are loaded WITHOUT `wait`** (synchronously) so they are
  ready on the very first line. The prompt is now **starship** (`starship/starship.zsh`),
  which replaced powerlevel10k — the p10k load (and its instant-prompt block) is kept
  commented in `.zshrc` for easy rollback.
- **Binaries**: `from'gh-r'` (download the platform release asset),
  `lbin'<glob> -> <name>'` (symlink the binary onto `PATH`), `extract'!'`,
  `binary`, `cp'src -> dst'` (e.g. man pages into `$ZINIT[MAN_DIR]`).
- **Git plugins**: `from'gh'`, `id-as'...'`, `compile'<pattern>'`, `nocompile'!'`.
- **Releases**: `latest-release` — newest release for source repos; provided by the
  `@alberti42/zinit-annex-latest-release` annex.
- **Completions**: `completions` ice + `_<name>` files; `:zinit-tmp-subst-compdef
  alias=cmd` to share a command's completion with an alias (see `l=eza`, `ll=eza`,
  `tree=eza` in `eza/eza.zsh`).
- **Hooks**: `atinit` (before load), `atload` (after load), `atclone` (on install),
  `atpull'%atclone'` (on update → rerun the atclone steps).

Annexes are loaded near the top of `.zshrc` **before** any package and are required
for the ices above (`binary-symlink`, `patch-dl`, `bin-gem-node`, `latest-release`).
Completion system is finalized once at the end via `zicompinit; zicdreplay`.

## Hook idioms

- **Find a sibling file from inside a snippet**: `${${(%):-%x}:a:h}/<file>` —
  `${(%):-%x}` is the current file's path, `:a:h` its absolute directory. Used to
  point `atclone` at a co-located hook script and to locate co-located config.
- **One-shot hook**: define `__<tool>_<phase>_hook` then run it with
  `_safe_one_off_load __<tool>_<phase>_hook` (auto-unfunctions). See `eza`/`glow`/`vivid`.
- **`atclone` runs with cwd = the plugin's install dir**, so invoke the freshly
  extracted binary as `./<bin>` rather than relying on `PATH`.

## CRITICAL gotchas (learned the hard way)

1. **Globals in wrapper snippets MUST use `typeset -g` (or `export`).** Wrappers are
   sourced from *inside* the `__zcompile_if_needed_and_source` function, so a plain
   `FOO=bar` becomes function-local and **vanishes when that function returns**.
2. **Quote style in an ice string decides expansion time.** Double-quoted
   `atload"…$VAR…"` expands `$VAR` *now* (at source time) and bakes the value into
   the stored ice string; single-quoted `atload'…$VAR…'` defers to *load time*. If a
   hook would otherwise depend on a variable that isn't in scope at load time, bake
   the value in at source time with double quotes.
3. **Functions defined in a sourced snippet are always global** regardless of the
   sourcing scope — so functions need no `typeset -g`, only variables (gotcha #1).
4. **Don't re-check/recompile machine-generated files at load time.** If a file and
   its `.zwc` are written together (e.g. by an `atclone` step) and never hand-edited,
   a plain `source` is enough — zsh uses the `.zwc` automatically. A staleness check
   only earns its keep for files a human edits.

## Adding a new tool — checklist

1. Inline one-liner (A) for a no-config release binary; wrapper snippet (B) otherwise.
2. Wrapper: create `zinit/src/<tool>/<tool>.zsh`; co-locate config + hook scripts.
3. `from'gh-r' lbin'…'` for release binaries; `_safe_one_off_load` for one-shot init;
   `${${(%):-%x}:a:h}` to reference sibling files.
4. Load it from `.zshrc` with `__zcompile_if_needed_and_source`.
5. `typeset -g` / `export` for any global the snippet sets.
6. Verify (below).

## Verifying & iterating

- **Syntax check**: `zsh -n path/to/file.zsh`
- **Real load**: `zsh -ic 'exit'` (sources the full interactive config)
- **Force a clean reinstall** (reruns `atclone`): `zinit delete --yes <owner/repo>`,
  then open a new interactive shell.
- **Update** (reruns `atpull` = `atclone`): `zinit update <owner/repo>`

---
name: mpl-nonblock
description: Integrate mpl-nonblock for nonblocking Matplotlib workflows in IPython-driven, script-based exploration.
license: MIT
metadata:
  author: Andrea Alberti (2026)
  package_repo: https://github.com/alberti42/mpl-nonblock
  version: 1.1.0
---

# Skill: mpl-nonblock

Use this skill when integrating `mpl-nonblock` into Python code that uses
Matplotlib from a script-based workflow driven by IPython (re-run scripts, keep
multiple native windows responsive).

This package complements Matplotlib. It does not replace Matplotlib APIs for
creating figures; it provides small helpers to make nonblocking workflows pleasant.

## Agent defaults (important)

- **Assume Matplotlib is available**. `mpl-nonblock` is a Matplotlib companion.
- **Keep integration explicit** (no backend guessing, no large fallback stacks).
- **Avoid duplicated plotting code**. Write plotting once; call `refresh(fig)` or
  `show()` to keep windows responsive.
- **Ask about terminal-run behavior**: should scripts call `show(block=True)` at
  the end to keep windows open?

Suggested question to ask the user (only when relevant):

- "When the script is run non-interactively (e.g. `python script.py`), should it
  wait once at the end (press Enter) to keep plot windows open?"

## Install (pin recommended)

Only install if the user explicitly asks for it; the package may already be available in the environment. Ask the user whether a specific release should be pinned (recommended for reproducibility and to avoid future incompatibilities). If unsure, prefer pinning the latest known-good release.

```bash
uv pip install "mpl-nonblock @ git+https://github.com/alberti42/mpl-nonblock.git@v1.1.0"
# or (if `uv` is not available)
pip install "mpl-nonblock @ git+https://github.com/alberti42/mpl-nonblock.git@v1.1.0"
```

# Unpinned (installs current default-branch HEAD; not recommended for reproducibility)

```bash
pip install "mpl-nonblock @ git+https://github.com/alberti42/mpl-nonblock.git"
```

## Backend Selection (explicit)

Backend selection is intentionally explicit:

- In IPython: use `%matplotlib ...` (e.g. `%matplotlib macosx` on macOS, `%matplotlib tk` on Linux).
- In scripts: call `matplotlib.use(...)` before importing `matplotlib.pyplot`.

For cross-platform scripts:

```python
import matplotlib
from mpl_nonblock import recommended_backend

matplotlib.use(recommended_backend(), force=True)
import matplotlib.pyplot as plt
```

## API Reference

### `recommended_backend(macos="macosx", linux="TkAgg", windows="TkAgg", other="TkAgg") -> str`

Returns a backend name recommendation for `sys.platform`. This does not call
`matplotlib.use()`; it keeps backend selection explicit.

### `refresh(fig, *, pause=0.001, in_foreground=False) -> ShowStatus`

Nonblocking refresh for a specific figure (useful in loops).

- Call it after you changed what is plotted (after `ax.plot(...)`, `ax.cla()`,
  `line.set_ydata(...)`, etc.).
- `in_foreground=True` tries to bring the window to the foreground (best-effort,
  backend-dependent).

### `show(*, block=False, pause=0.001) -> ShowStatus`

Drop-in replacement for `matplotlib.pyplot.show(block=...)` with a different default:

- defaults to `block=False`.
- `show(block=False)` is a global "GUI tick" (pumps GUI events and therefore affects
  all open figures).
- `show(block=True)` is the terminal-run fallback to keep windows open at program end.

### `is_interactive()`

Returns `True` when running inside IPython/Jupyter or a REPL-ish session.
Checks IPython, `sys.ps1`, and `sys.flags.interactive`.

### `diagnostics()`

Returns a dict with backend info, IPython state, and environment variables
(`DISPLAY`, `WAYLAND_DISPLAY`). Useful for debugging "nothing shows up" problems.

## Patterns

### Loop updates (recommended)

```python
import matplotlib.pyplot as plt

from mpl_nonblock import refresh

fig1, ax1 = plt.subplots(num="A", clear=True)
fig2, ax2 = plt.subplots(num="B", clear=True)

for k in range(200):
    ax1.cla(); ax1.plot([0, 1], [0, k])
    ax2.cla(); ax2.plot([0, 1], [k, 0])

    refresh(fig1)
    refresh(fig2)
```

### Script that works both interactively and standalone

```python
import matplotlib.pyplot as plt

from mpl_nonblock import is_interactive, refresh, show

fig, ax = plt.subplots(num="Result", clear=True)
ax.plot(x, y)

refresh(fig)

if not is_interactive():
    # Terminal-run fallback: keep windows open after the script ends.
    show(block=True)
```

## Troubleshooting

If nothing shows up, run:

```python
from mpl_nonblock import diagnostics
print(diagnostics())
```

Or from the command line:

```bash
mpl-nonblock-diagnose
```

Common fixes:
- **IPython on macOS**: run `%matplotlib macosx` before your script.
- **IPython on Linux**: run `%matplotlib qt` (or `%matplotlib tk`).
- **Headless / Agg backend**: no window can open; use `fig.savefig(...)` instead.

#!/usr/bin/env python3
"""Generate a cached, sourceable snapshot of an interactive shell environment.

This script runs an interactive login shell (default: zsh) to obtain the
environment variables that would be present in an interactive terminal session,
then writes a POSIX sh-compatible file containing `export KEY='value'` lines.

Default output path:
  $XDG_CACHE_HOME/zsh/interactive-shell-env.sh
  (or ~/.cache/zsh/interactive-shell-env.sh)

Rationale:
  - GUI/daemon processes often start with a minimal environment (PATH, XDG vars,
    pyenv shims, etc.). Sourcing the generated file in a launcher script makes
    service environments more consistent.
"""

from __future__ import annotations

import argparse
import os
import re
import shlex
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def sh_quote(value: str) -> str:
    """Return a POSIX-sh-safe single-quoted string."""

    return "'" + value.replace("'", "'\"'\"'") + "'"


def parse_env0(raw: bytes) -> dict[str, str]:
    """Parse `env -0` output, tolerating leading noise printed to stdout.

    Shell init files sometimes print to stdout before `env -0` runs. That would
    corrupt the stream. This parser recovers by searching for the first
    plausible KEY= occurrence within each NUL-delimited chunk.
    """

    env: dict[str, str] = {}
    key_re = re.compile(rb"^[A-Za-z_][A-Za-z0-9_]*$")
    key_find_re = re.compile(rb"(?:^|[\r\n])([A-Za-z_][A-Za-z0-9_]*)=")

    def add_kv(kb: bytes, vb: bytes) -> None:
        if not key_re.match(kb):
            return
        try:
            k = kb.decode("utf-8", "surrogateescape")
            v = vb.decode("utf-8", "surrogateescape")
        except Exception:
            return
        env[k] = v

    for part in raw.split(b"\x00"):
        if not part:
            continue
        k, sep, v = part.partition(b"=")
        if sep and key_re.match(k):
            add_kv(k, v)
            continue

        m = key_find_re.search(part)
        if not m:
            continue
        start = m.start(1)
        recovered = part[start:]
        rk, rsep, rv = recovered.partition(b"=")
        if rsep:
            add_kv(rk, rv)

    return env


def filter_env(env: dict[str, str]) -> dict[str, str]:
    """Select variables using an allowlist, excluding a blocklist."""

    allow_exact = {
        "PATH",
        "LANG",
        "LC_ALL",
        "LC_TIME",
        "EDITOR",
        "PAGER",
        "LESS",
        "MANPAGER",
        "INFOPATH",
        "LS_COLORS",
        "JAVA_HOME",
        "SSH_AUTH_SOCK",
        "PYENV_ROOT",
        "PYENV_SHELL",
        "PYENV_VIRTUALENV_FAST_SCAN",
        "CARGO_HOME",
        "RUSTUP_HOME",
        "HOMEBREW_PREFIX",
        "HOMEBREW_CELLAR",
        "HOMEBREW_REPOSITORY",
        "XDG_CACHE_HOME",
        "XDG_CONFIG_HOME",
        "XDG_DATA_HOME",
        "ZSH_CACHE_DIR",
        "ZPFX",
        "EZA_CONFIG_DIR",
        "DISPLAY",
    }

    allow_prefix = (
        "XDG_",
        "ZAC_",
        "PYENV_",
        "FZF_",
        "Z_OC_",
        "LC_",
    )

    block_exact = {
        "_",
        "PWD",
        "OLDPWD",
        "SHLVL",
        "SHELL",
        "TMPDIR",
        "TERM",
        "TERM_PROGRAM",
        "TERM_PROGRAM_VERSION",
        "TMUX",
        "TMUX_PANE",
        "COLORTERM",
        "SECURITYSESSIONID",
        "COMMAND_MODE",
        "LaunchInstanceID",
        "XPC_FLAGS",
        "XPC_SERVICE_NAME",
        "__CF_USER_TEXT_ENCODING",
        "__CFBundleIdentifier",
        "PMSPEC",
        "PYENV_VERSION",
        "PYENV_VIRTUAL_ENV",
        "PYENV_ACTIVATE_SHELL",
        "VIRTUAL_ENV",
    }

    block_prefix = (
        "WEZTERM_",
        "P9K_",
        "_P9K_",
    )

    secret_pat = re.compile(
        r"(TOKEN|SECRET|PASSWORD|PASS|API_KEY|AUTH|BEARER|COOKIE)", re.I
    )

    def allowed(k: str) -> bool:
        return (k in allow_exact) or any(k.startswith(p) for p in allow_prefix)

    def blocked(k: str) -> bool:
        if k in block_exact:
            return True
        if any(k.startswith(p) for p in block_prefix):
            return True
        if secret_pat.search(k):
            return True
        if k.startswith("_"):
            return True
        return False

    selected: dict[str, str] = {}
    for k, v in env.items():
        if not allowed(k):
            continue
        if blocked(k):
            continue
        selected[k] = v
    return selected


def default_output_path() -> Path:
    cache_home = os.environ.get("XDG_CACHE_HOME") or str(Path.home() / ".cache")
    return Path(cache_home) / "zsh" / "interactive-shell-env.sh"


def run_shell_env(shell: str, quiet: bool) -> bytes:
    cmd = [shell, "-lic", "command env -0"]
    stderr = subprocess.DEVNULL if quiet else None
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=stderr, check=True)
    except FileNotFoundError as e:
        raise SystemExit(f"Shell not found: {shell}") from e
    except subprocess.CalledProcessError as e:
        raise SystemExit(f"Shell command failed: {shlex.join(cmd)}") from e
    return p.stdout


def write_exports(path: Path, env: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    lines = [
        "# Generated by gen-interactive-shell-env.py\n",
        f"# UTC: {now}\n",
        "# shellcheck shell=sh\n",
        "\n",
    ]
    for k in sorted(env.keys()):
        lines.append(f"export {k}={sh_quote(env[k])}\n")

    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        delete=False,
        dir=str(path.parent),
        prefix=path.name + ".",
        suffix=".tmp",
    ) as f:
        tmp_name = f.name
        f.writelines(lines)

    os.chmod(tmp_name, 0o600)
    os.replace(tmp_name, path)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--output", default=None, help="Output file path")
    ap.add_argument("--shell", default="zsh", help="Shell to run (default: zsh)")
    ap.add_argument("--dry-run", action="store_true", help="Print selected KEY=VALUE")
    ap.add_argument("--quiet", action="store_true", help="Suppress shell init stderr")
    args = ap.parse_args(argv)

    out = Path(args.output) if args.output else default_output_path()

    raw = run_shell_env(args.shell, quiet=args.quiet)
    env = parse_env0(raw)
    selected = filter_env(env)

    if args.dry_run:
        for k in sorted(selected.keys()):
            print(f"{k}={selected[k]}")
        return 0

    write_exports(out, selected)
    print(str(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

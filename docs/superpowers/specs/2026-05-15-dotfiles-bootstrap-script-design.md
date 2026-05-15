# Dotfiles bootstrap script — design

**Date:** 2026-05-15
**Status:** Approved (design); pending spec review

## Goal

A single, idempotent, cross-platform (Linux + macOS) `bootstrap.sh` at the
repo root that takes a fresh machine to a fully working setup: dependencies
installed, stow packages symlinked, a Nerd Font installed, and tmux plugins
bootstrapped — in one command, safe to re-run.

## Decisions (from brainstorming)

- **Scope:** full bootstrap — deps + stow + tpm/plugins + font.
- **Idempotency:** safe to re-run; skip already-installed tools; conflicting
  *real* files auto-backed-up to `<path>.pre-stow.bak` (never destructive,
  never interactive).
- **Font:** install JetBrainsMono Nerd Font into the OS font directory and
  refresh the cache; do **not** touch any terminal-emulator configuration
  (machine/DE-specific and fragile — established the hard way on
  2026-05-15; see `memory/terminal-nerd-font.md`).
- **Third-party tools** (oh-my-posh, nvm/node, oh-my-zsh, zinit): install via
  each project's official installer (brew where available, else the
  documented `curl | bash`), each guarded so re-runs skip if present.
- **Structure:** approach A — one well-factored `bootstrap.sh` at repo root
  (not a `lib/` split, not a Makefile).

## Architecture

Single bash script at the repo root. `set -euo pipefail`. Structured as
small, independently-runnable, idempotent functions invoked in order by
`main()`. Constants (font release/version, repo URL, package list) defined
once at the top. Usable both locally (`./bootstrap.sh`) and remotely
(`curl … | bash`, which clones the repo and re-execs from it).

## Components (functions, in execution order)

1. **`detect_os`** — `OS=linux|macos` from `uname`; `PKG` → `apt-get` or
   `brew`. Unsupported OS exits with a clear message.
2. **`ensure_repo`** — if not already inside the dotfiles repo, clone
   `https://github.com/AcacioTelechi/dotfiles.git` to `~/dotfiles` and
   re-exec from there.
3. **`install_pkgs`** — core deps via the OS package manager:
   `git stow zsh tmux neovim ripgrep zoxide curl`. On macOS, ensure
   Homebrew exists first (official installer if missing). Skip any tool
   already on `PATH` (`command -v`).
4. **`install_third_party`** — guarded official installers, each skipped if
   already present:
   - `oh-my-posh` — brew on macOS; official script to `~/.local/bin` on Linux.
   - `nvm` + LTS `node` — official nvm install script, then `nvm install --lts`.
   - `oh-my-zsh` — unattended official script (`RUNZSH=no CHSH=no`).
   - `zinit` — official install script.
5. **`stow_packages`** — for `nvim tmux zsh`: pre-scan targets; any real
   file/dir that is not already the correct symlink → moved to
   `<path>.pre-stow.bak`; then `stow -t "$HOME" -R <pkg>`.
6. **`install_font`** — download JetBrainsMono Nerd Font (pinned release tag)
   to `~/.local/share/fonts/` (Linux → `fc-cache -f`) or `~/Library/Fonts/`
   (macOS). Skip if already installed.
7. **`bootstrap_tmux`** — clone `tpm` to `~/.config/tmux/plugins/tpm` if
   absent; install plugins headlessly via `tpm/bin/install_plugins`.
8. **`main`** — runs the above in order; prints a summary plus manual
   reminders: select the font *or* keep plain `Monospace` + fontconfig
   fallback (per the font lesson); then `exec zsh`.

## Data flow

No shared state files. Strict ordering (deps → third-party → stow → font →
tmux plugins). Each function is independently runnable for debugging.

## Error handling

- `set -euo pipefail`; `trap` on `ERR` prints the failing step + line number.
- Every install guarded by `command -v` / path existence → idempotent.
- Stow conflicts auto-backed-up; never destructive, never prompts.
- `sudo` only for `apt-get` on Linux. macOS/brew and all user-space
  installers run unprivileged. Script refuses to run as root (`$EUID` check).
- Non-fatal steps (font, tpm) emit a warning and continue rather than abort
  the whole run; fatal steps (deps, stow) abort.

## CLI

- `bootstrap.sh` — full run.
- `bootstrap.sh --dry-run` — print every action without executing.
- `bootstrap.sh -h|--help` — usage.

## Testing

- `bash -n bootstrap.sh` syntax check; `shellcheck` clean.
- Idempotency: a documented second-run check (must be a no-op).
- `--dry-run` exercised in the spec's acceptance notes.
- Manual smoke test in a throwaway Linux container and a macOS VM
  (documented, not automated — this repo has no CI).

## Scope boundaries (YAGNI / explicitly out)

- No terminal-emulator configuration; no GNOME/dconf/gsettings.
- No Windows/WSL support.
- No uninstall/teardown command.
- No config templating — stow symlinks only.

## Follow-up (after script lands)

- Reconcile `README.md`'s Fonts section to JetBrainsMono + "plain Monospace
  + fontconfig fallback" (currently documents Meslo, which double-spaces on
  the current GNOME Terminal/VTE — see `memory/terminal-nerd-font.md`).
- Replace the README's manual apt bootstrap block with a pointer to
  `bootstrap.sh`.

#!/usr/bin/env bash
set -eEuo pipefail   # E (errtrace): ERR trap is inherited by functions/subshells

# ---- Constants ------------------------------------------------------------
REPO_URL="https://github.com/AcacioTelechi/dotfiles.git"
REPO_DIR="$HOME/dotfiles"
FONT_VERSION="v3.2.1"
FONT_NAME="JetBrainsMono"
STOW_PACKAGES="nvim tmux zsh"
CORE_PKGS="git stow zsh tmux neovim ripgrep zoxide curl"

DRY_RUN=0
SHOW_HELP=0

# ---- Output helpers -------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# run CMD...  — execute, or just print when DRY_RUN=1
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN: %s\n' "$*"
    return 0
  fi
  "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

OS=""
PKG=""
detect_os() {
  local u
  u="${BOOTSTRAP_UNAME:-$(uname -s)}"
  case "$u" in
    Linux)  OS="linux"; PKG="apt-get" ;;
    Darwin) OS="macos"; PKG="brew" ;;
    *) die "unsupported OS: '$u' (Linux and macOS only)" ;;
  esac
}

# backup_if_conflict PATH — if PATH is a real (non-symlink) file/dir,
# move it aside to PATH.pre-stow.bak. Symlinks and missing paths: no-op.
backup_if_conflict() {
  local p="$1"
  if [ -L "$p" ]; then return 0; fi
  if [ -e "$p" ]; then
    if [ -e "$p.pre-stow.bak" ]; then
      warn "backup already exists; leaving $p in place (not overwriting $p.pre-stow.bak)"
      return 0
    fi
    run mv "$p" "$p.pre-stow.bak"
    log "backed up existing $p -> $p.pre-stow.bak"
  fi
  return 0
}

# stow_packages — let stow ITSELF report genuine conflicts (simulate
# mode), back up only those, then (re)stow. Idempotent by construction:
# an already-stowed package reports zero conflicts, so a re-run backs up
# nothing and just re-creates the same links.
#
# Why not walk files and pre-compute targets? Because stow tree-folds a
# package dir into a single directory symlink. After that, a per-file
# target like ~/.config/tmux/tmux.conf is a REAL file reached THROUGH a
# folded parent symlink — its own `-L` test is false — so a naive
# backup-then-restow would mv the real repo file into *.pre-stow.bak on
# re-run, corrupting the dotfiles. Delegating conflict detection to stow
# avoids reimplementing (incorrectly) what stow already knows.
stow_packages() {
  have stow || die "stow not installed (install_pkgs should have handled this)"
  [ -d "$REPO_DIR" ] || die "REPO_DIR not found: $REPO_DIR"
  local pkg line rel
  for pkg in $STOW_PACKAGES; do
    # `stow -n -R` (simulate) writes conflict lines to stderr (hence 2>&1);
    # a process substitution's exit status is not checked by set -e, so no
    # || true is needed. Conflict lines look like:
    #   * existing target is neither a link nor a directory: .zshrc
    while IFS= read -r line; do
      case "$line" in
        *"existing target is "*": "*)
          # Drop everything up to & including the first ": " AFTER the
          # static "existing target is " phrase (non-greedy via #), then
          # drop any " => source" suffix stow appends for the
          # "stowed to a different package" phrasing. Robust to paths
          # that themselves contain ": ".
          rel="${line#*existing target is *: }"
          rel="${rel%% => *}"
          backup_if_conflict "$HOME/$rel"
          ;;
      esac
    done < <(stow -n -R -d "$REPO_DIR" -t "$HOME" "$pkg" 2>&1)
    run stow -R -d "$REPO_DIR" -t "$HOME" "$pkg"
    log "stowed $pkg"
  done
}

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--dry-run] [-h|--help]

Idempotent cross-platform (Linux/macOS) dotfiles bootstrap:
installs deps, stows packages, installs a Nerd Font, bootstraps tmux plugins.

  --dry-run   print every action without executing it
  -h, --help  show this help
EOF
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      -h|--help) usage; SHOW_HELP=1; return 0 ;;
      *) die "unknown argument: $1 (try --help)" ;;
    esac
    shift
  done
}

on_err() { warn "failed at line $1 (last step did not complete)"; }

main() {
  trap 'on_err $LINENO' ERR
  parse_args "$@"
  [ "$SHOW_HELP" -eq 1 ] && exit 0
  [ "${EUID:-$(id -u)}" -ne 0 ] || die "do not run as root; sudo is used only where needed"
  detect_os
  log "detected OS=$OS PKG=$PKG"
  log "bootstrap starting (dry-run=$DRY_RUN)"
  # subsequent tasks wire steps in here
  log "bootstrap done"
}

# Allow the test harness to source helpers without running main.
if [ "${BOOTSTRAP_SOURCE_ONLY:-0}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

main "$@"

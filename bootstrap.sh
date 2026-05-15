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
    run mv "$p" "$p.pre-stow.bak"
    log "backed up existing $p -> $p.pre-stow.bak"
  fi
  return 0
}

# stow_packages — back up conflicts, then (re)stow each package.
stow_packages() {
  have stow || die "stow not installed (install_pkgs should have handled this)"
  local pkg f target
  for pkg in $STOW_PACKAGES; do
    # Every tracked file under pkg/ maps to $HOME/<relpath-after-pkg>
    while IFS= read -r f; do
      target="$HOME/${f#"$pkg"/}"
      backup_if_conflict "$target"
    done < <(cd "$REPO_DIR" && find "$pkg" -type f -not -path '*/.git/*')
    run stow -d "$REPO_DIR" -t "$HOME" -R "$pkg"
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

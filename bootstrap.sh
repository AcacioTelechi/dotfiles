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

ensure_homebrew() {
  have brew && return 0
  log "installing Homebrew"
  # The curl MUST stay inside the single-quoted sh -c string so it runs
  # only when run() actually executes — otherwise $(...) would expand
  # (and hit the network) even under --dry-run.
  run sh -c \
    '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
}

install_pkgs() {
  if [ "$OS" = "linux" ]; then
    run sudo apt-get update
    # shellcheck disable=SC2086  # word-split CORE_PKGS into separate args
    run sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $CORE_PKGS
  else
    ensure_homebrew
    # shellcheck disable=SC2086  # word-split CORE_PKGS into separate args
    run brew install $CORE_PKGS
  fi
}

install_third_party() {
  # oh-my-posh
  if have oh-my-posh; then
    log "oh-my-posh present, skipping"
  elif [ "$OS" = "macos" ]; then
    run brew install jandedobbeleer/oh-my-posh/oh-my-posh
  else
    log "installing oh-my-posh"
    # shellcheck disable=SC2016  # literal: curl runs at exec time, not now
    run sh -c \
      'curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"'
  fi

  # nvm + LTS node
  if [ -d "$HOME/.nvm" ]; then
    log "nvm present, skipping"
  else
    # shellcheck disable=SC2016  # literal: curl runs at exec time, not now
    run sh -c \
      'curl -fsSLo- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
  fi
  # shellcheck disable=SC2016  # literal: $HOME expands in child bash, not now
  run bash -c '. "$HOME/.nvm/nvm.sh" 2>/dev/null && nvm install --lts || true'

  # oh-my-zsh (unattended)
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "oh-my-zsh present, skipping"
  else
    # shellcheck disable=SC2016  # literal: curl runs at exec time, not now
    run sh -c \
      'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  fi

  # zinit
  if [ -d "$HOME/.local/share/zinit/zinit.git" ]; then
    log "zinit present, skipping"
  else
    # shellcheck disable=SC2016  # literal: curl runs at exec time, not now
    run sh -c \
      'bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"'
  fi
}

install_font() {
  local dir zip url _tmpdir
  if [ "$OS" = "macos" ]; then
    dir="$HOME/Library/Fonts"
  else
    dir="$HOME/.local/share/fonts"
  fi
  # shellcheck disable=SC2012  # glob existence check, not parsing ls
  if ls "$dir"/JetBrainsMono*NerdFont*.ttf >/dev/null 2>&1; then
    log "JetBrainsMono Nerd Font already installed in $dir, skipping"
    return 0
  fi
  url="https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/$FONT_NAME.zip"
  # mktemp only in the live path so --dry-run has zero side effects;
  # dry-run uses a deterministic placeholder path (never created).
  if [ "$DRY_RUN" -eq 0 ]; then
    _tmpdir="$(mktemp -d)"
  else
    _tmpdir="${TMPDIR:-/tmp}"
  fi
  zip="$_tmpdir/$FONT_NAME.zip"
  run mkdir -p "$dir"
  run curl -fsSLo "$zip" "$url"
  run unzip -o "$zip" -d "$dir"
  if [ "$OS" = "linux" ]; then
    run fc-cache -f "$dir"
  fi
  if [ "$DRY_RUN" -eq 0 ]; then
    rm -rf "$_tmpdir"
  fi
  log "installed $FONT_NAME Nerd Font to $dir"
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

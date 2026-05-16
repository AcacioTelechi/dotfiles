#!/usr/bin/env bash
# Dependency-free test harness for bootstrap.sh pure helpers.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../bootstrap.sh"
PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
notok(){ FAIL=$((FAIL+1)); printf 'NOT OK - %s\n' "$1"; }
assert_eq() { # desc expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else notok "$1 (expected [$2] got [$3])"; fi
}

# Source helpers only (no main()).
BOOTSTRAP_SOURCE_ONLY=1 . "$SCRIPT"

# --- run() respects DRY_RUN ---
DRY_RUN=1
out="$(run touch /tmp/should_not_exist_$$ 2>&1)"
assert_eq "run() prints in dry-run" "DRY-RUN: touch /tmp/should_not_exist_$$" "$out"
if [ ! -e "/tmp/should_not_exist_$$" ]; then
  ok "run() does not execute in dry-run"
else
  notok "run() executed despite dry-run"
fi

# --- detect_os ---
BOOTSTRAP_UNAME="Linux" detect_os
assert_eq "detect_os Linux -> OS"  "linux" "$OS"
assert_eq "detect_os Linux -> PKG" "apt-get" "$PKG"
BOOTSTRAP_UNAME="Darwin" detect_os
assert_eq "detect_os Darwin -> OS"  "macos" "$OS"
assert_eq "detect_os Darwin -> PKG" "brew"  "$PKG"
( BOOTSTRAP_UNAME="Plan9" detect_os ) 2>/dev/null \
  && notok "detect_os should reject unknown OS" \
  || ok "detect_os rejects unknown OS"

# --- backup_if_conflict ---
TMP="$(mktemp -d)"
DRY_RUN=0   # prior run() tests left DRY_RUN=1; backup_if_conflict uses `run mv`
# Case A: real file -> backed up
echo original > "$TMP/.zshrc"
backup_if_conflict "$TMP/.zshrc"
if [ ! -e "$TMP/.zshrc" ] && [ -f "$TMP/.zshrc.pre-stow.bak" ]; then
  ok "backup_if_conflict moves real file to .pre-stow.bak"
else
  notok "backup_if_conflict did not back up real file"
fi
# Case B: nonexistent path -> no-op, returns 0, no stray .bak
if backup_if_conflict "$TMP/.does-not-exist" \
   && [ ! -e "$TMP/.does-not-exist.pre-stow.bak" ]; then
  ok "backup_if_conflict no-op on missing path"
else
  notok "backup_if_conflict errored or created stray .bak on missing path"
fi
# Case C: existing symlink -> left alone (stow -R handles its own links)
ln -s /tmp "$TMP/.link"
backup_if_conflict "$TMP/.link"
if [ -L "$TMP/.link" ] && [ ! -e "$TMP/.link.pre-stow.bak" ]; then
  ok "backup_if_conflict leaves symlinks alone"
else
  notok "backup_if_conflict touched a symlink"
fi
rm -rf "$TMP"

# --- stow_packages conflict parsing (mocked stow) ---
DRY_RUN=0
SB="$(mktemp -d)"            # sandbox HOME
RB="$(mktemp -d)"            # fake repo dir
BIN="$(mktemp -d)"           # fake stow on PATH
mkdir -p "$RB/fakepkg"
# real conflicting targets the parser must back up:
printf x > "$SB/.simple"
printf y > "$SB/.weird: name"
printf z > "$SB/.diffpkg"
cat > "$BIN/stow" <<'EOS'
#!/usr/bin/env bash
# -n present => simulate: emit the 3 GNU-stow conflict phrasings on stderr, exit 1
for a in "$@"; do [ "$a" = "-n" ] && sim=1; done
if [ "${sim:-0}" = 1 ]; then
  {
    echo "WARNING! stowing fakepkg would cause conflicts:"
    echo "  * existing target is neither a link nor a directory: .simple"
    echo "  * existing target is neither a link nor a directory: .weird: name"
    echo "  * existing target is stowed to a different package: .diffpkg => ../other/.diffpkg"
  } >&2
  exit 1
fi
exit 0   # real `stow -R` no-op
EOS
chmod +x "$BIN/stow"
(
  PATH="$BIN:$PATH" HOME="$SB" REPO_DIR="$RB" STOW_PACKAGES="fakepkg"
  export HOME REPO_DIR STOW_PACKAGES
  PATH="$BIN:$PATH" bash -c '
    BOOTSTRAP_SOURCE_ONLY=1 . '"$HERE/../bootstrap.sh"'
    REPO_DIR="'"$RB"'"; STOW_PACKAGES="fakepkg"; DRY_RUN=0
    stow_packages
  '
)
if [ -f "$SB/.simple.pre-stow.bak" ] \
   && [ -f "$SB/.weird: name.pre-stow.bak" ] \
   && [ -f "$SB/.diffpkg.pre-stow.bak" ] \
   && [ ! -e "$SB/.simple" ] && [ ! -e "$SB/.weird: name" ] && [ ! -e "$SB/.diffpkg" ]; then
  ok "stow_packages backs up all conflicts incl. ': ' and '=> src' phrasings"
else
  notok "stow_packages parser failed to back up a conflict path correctly"
fi
rm -rf "$SB" "$RB" "$BIN"

# --- install_pkgs (dry-run) ---
DRY_RUN=1
OS="linux"; PKG="apt-get"
out="$(install_pkgs 2>&1)"
echo "$out" | grep -q 'DRY-RUN: sudo apt-get update' \
  && ok "install_pkgs(linux) runs apt-get update" \
  || notok "install_pkgs(linux) missing apt-get update"
echo "$out" | grep -q 'DRY-RUN: sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git stow zsh tmux neovim ripgrep fzf zoxide curl' \
  && ok "install_pkgs(linux) installs CORE_PKGS" \
  || notok "install_pkgs(linux) missing CORE_PKGS install"
OS="macos"; PKG="brew"
out="$(install_pkgs 2>&1)"
echo "$out" | grep -q 'DRY-RUN: brew install git stow zsh tmux neovim ripgrep fzf zoxide curl' \
  && ok "install_pkgs(macos) brew install CORE_PKGS" \
  || notok "install_pkgs(macos) missing brew install"
echo "$out" | grep -qF 'DRY-RUN: sh -c /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
  && ok "install_pkgs(macos) defers curl under dry-run (no network)" \
  || notok "install_pkgs(macos) may have expanded \$(curl) under dry-run"
DRY_RUN=0

# --- install_third_party (dry-run, all guarded by have/path) ---
DRY_RUN=1
OS="linux"
TMPHOME="$(mktemp -d)"; OLDHOME="$HOME"; export HOME="$TMPHOME"
# Stub: pretend none of the tools exist by emptying PATH lookups for them.
out="$( PATH="/usr/bin:/bin" install_third_party 2>&1 )"
echo "$out" | grep -q 'oh-my-posh' && ok "third_party mentions oh-my-posh" || notok "no oh-my-posh"
echo "$out" | grep -q 'nvm' && ok "third_party mentions nvm" || notok "no nvm"
echo "$out" | grep -q 'ohmyzsh\|oh-my-zsh' && ok "third_party mentions oh-my-zsh" || notok "no oh-my-zsh"
echo "$out" | grep -q 'zinit' && ok "third_party mentions zinit" || notok "no zinit"
export HOME="$OLDHOME"; rm -rf "$TMPHOME"; DRY_RUN=0; OS=""

# --- install_font (dry-run, both OSes) ---
DRY_RUN=1
TMPHOME="$(mktemp -d)"; OLDHOME="$HOME"; export HOME="$TMPHOME"
OS="linux"
out="$(install_font 2>&1)"
echo "$out" | grep -q "$TMPHOME/.local/share/fonts" \
  && ok "install_font(linux) targets ~/.local/share/fonts" \
  || notok "install_font(linux) wrong target"
echo "$out" | grep -q "fc-cache" \
  && ok "install_font(linux) refreshes font cache" \
  || notok "install_font(linux) no fc-cache"
OS="macos"
out="$(install_font 2>&1)"
echo "$out" | grep -q "DRY-RUN: brew install --cask font-jetbrains-mono-nerd-font" \
  && ok "install_font(macos) uses the Homebrew nerd-font cask" \
  || notok "install_font(macos) not using brew cask"
echo "$out" | grep -qE "fc-cache|curl |unzip " \
  && notok "install_font(macos) must NOT curl/unzip/fc-cache (cask only)" \
  || ok "install_font(macos) cask path skips curl/unzip/fc-cache"
# linux idempotency: pretend already installed
OS="linux"
mkdir -p "$TMPHOME/.local/share/fonts"
touch "$TMPHOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf"
out="$(install_font 2>&1)"
echo "$out" | grep -qi "skip" \
  && ok "install_font(linux) skips when already installed" \
  || notok "install_font(linux) not idempotent"
export HOME="$OLDHOME"; rm -rf "$TMPHOME"; DRY_RUN=0; OS=""

# --- bootstrap_tmux (dry-run) ---
DRY_RUN=1
TMPHOME="$(mktemp -d)"; OLDHOME="$HOME"; export HOME="$TMPHOME"
out="$(bootstrap_tmux 2>&1)"
echo "$out" | grep -q "plugins/tpm" \
  && ok "bootstrap_tmux clones tpm" || notok "bootstrap_tmux no tpm clone"
echo "$out" | grep -q "install_plugins" \
  && ok "bootstrap_tmux installs plugins" || notok "bootstrap_tmux no plugin install"
export HOME="$OLDHOME"; rm -rf "$TMPHOME"; DRY_RUN=0

# --- end-to-end dry run via the script entrypoint ---
e2e="$(BOOTSTRAP_UNAME=Linux bash "$SCRIPT" --dry-run 2>&1)"
echo "$e2e" | grep -q "bootstrap starting" && ok "e2e: starts" || notok "e2e: no start"
echo "$e2e" | grep -q "bootstrap done"     && ok "e2e: finishes" || notok "e2e: no finish"
echo "$e2e" | grep -qi "JetBrainsMono Nerd Font\|fontconfig fallback" \
  && ok "e2e: prints font reminder" || notok "e2e: missing font reminder"

# --- ensure_repo: no-op when already inside the repo ---
DRY_RUN=1
REPO_DIR_BAK="$REPO_DIR"
# Simulate "already in repo": REPO_DIR exists and is a git repo (this checkout)
REPO_DIR="$HERE/.."
out="$(ensure_repo 2>&1)"
echo "$out" | grep -qi "clone" \
  && notok "ensure_repo should NOT clone when already in repo" \
  || ok "ensure_repo no-op inside existing repo"
REPO_DIR="$REPO_DIR_BAK"; DRY_RUN=0

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

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
DRY_RUN=0
TMP="$(mktemp -d)"
# Case A: real file -> backed up
echo original > "$TMP/.zshrc"
backup_if_conflict "$TMP/.zshrc"
[ ! -e "$TMP/.zshrc" ] && [ -f "$TMP/.zshrc.pre-stow.bak" ] \
  && ok "backup_if_conflict moves real file to .pre-stow.bak" \
  || notok "backup_if_conflict did not back up real file"
# Case B: nonexistent path -> no-op, no error
backup_if_conflict "$TMP/.does-not-exist" \
  && ok "backup_if_conflict no-op on missing path" \
  || notok "backup_if_conflict errored on missing path"
# Case C: existing symlink -> left alone (stow -R handles it)
ln -s /tmp "$TMP/.link"
backup_if_conflict "$TMP/.link"
[ -L "$TMP/.link" ] && [ ! -e "$TMP/.link.pre-stow.bak" ] \
  && ok "backup_if_conflict leaves symlinks alone" \
  || notok "backup_if_conflict touched a symlink"
rm -rf "$TMP"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

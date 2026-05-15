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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

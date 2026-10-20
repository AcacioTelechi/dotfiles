#!/usr/bin/env bash
# Dependency-free test harness for wake_claude pure helpers.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../bin/.local/bin/wake_claude"
PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
notok(){ FAIL=$((FAIL+1)); printf 'NOT OK - %s\n' "$1"; }
assert_eq() { # desc expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else notok "$1 (expected [$2] got [$3])"; fi
}

# Source helpers only (no main()).
WAKE_CLAUDE_SOURCE_ONLY=1 . "$SCRIPT"
set +e

# --- sanitize ---
assert_eq "sanitize keeps safe chars" "my_app-2" "$(sanitize "my_app-2")"
assert_eq "sanitize replaces unsafe"  "my-proj-v2-x" "$(sanitize "my proj.v2/x")"
assert_eq "sanitize trims dashes"     "app" "$(sanitize "/app/")"

# --- sd_quote ---
assert_eq "sd_quote wraps args"     '"a" "b c"' "$(sd_quote a "b c")"
assert_eq "sd_quote escapes quotes" '"say \"hi\""' "$(sd_quote 'say "hi"')"
assert_eq "sd_quote escapes % and \$" '"100%% $$HOME"' "$(sd_quote '100% $HOME')"

# --- render_unit ---
unit="$(render_unit app "/srv/my app" /opt/bin/claude /usr/bin/tmux --spawn worktree)"
echo "$unit" | grep -qx 'Type=forking' \
  && ok "unit is Type=forking" || notok "unit not Type=forking"
echo "$unit" | grep -qx 'WorkingDirectory=/srv/my app' \
  && ok "unit WorkingDirectory is the raw path" || notok "bad WorkingDirectory"
echo "$unit" | grep -qx 'Environment=WAKE_CLAUDE=1' \
  && ok "unit sets WAKE_CLAUDE=1" || notok "unit missing WAKE_CLAUDE"
echo "$unit" | grep -q '^Environment="PATH=/opt/bin:' \
  && ok "unit PATH starts with claude's dir" || notok "unit PATH missing claude dir"
echo "$unit" | grep -q '"-L" "claude-rc-app" "new-session" "-d" "-s" "app"' \
  && ok "unit uses dedicated tmux socket + session" || notok "bad tmux new-session"
echo "$unit" | grep -q '"/opt/bin/claude remote-control --name app --spawn worktree"' \
  && ok "unit passes extra claude args" || notok "extra args not passed"
echo "$unit" | grep -q '^ExecStop="/usr/bin/tmux" "-L" "claude-rc-app" "kill-server"' \
  && ok "unit stops its own tmux server" || notok "bad ExecStop"
echo "$unit" | grep -qx 'Restart=always' \
  && ok "unit restarts always" || notok "unit missing Restart=always"

# Validate with systemd when available.
if command -v systemd-analyze >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  render_unit app "$TMP" "$(command -v true)" "$(command -v true)" > "$TMP/claude-rc-app.service"
  if systemd-analyze --user verify "$TMP/claude-rc-app.service" 2>&1 | grep -q "claude-rc-app"; then
    notok "systemd-analyze rejects unit"
  else
    ok "systemd-analyze accepts unit"
  fi
  rm -rf "$TMP"
fi

# --- CLI ---
bash "$SCRIPT" --help | grep -q "Usage: wake_claude" \
  && ok "--help prints usage" || notok "--help missing usage"
bash "$SCRIPT" bogus 2>/dev/null \
  && notok "unknown arg should fail" || ok "unknown arg fails"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

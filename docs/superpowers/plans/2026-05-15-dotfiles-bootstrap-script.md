# Dotfiles Bootstrap Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single idempotent, cross-platform (Linux/macOS) `bootstrap.sh` that takes a fresh machine to a working dotfiles setup in one command.

**Architecture:** One bash script at the repo root, `set -euo pipefail`, composed of small idempotent functions run by `main()`. A central `run()` wrapper makes every side-effecting action honor `--dry-run` and ERR tracing. Pure-logic helpers (`detect_os`, `backup_if_conflict`, `have`) are unit-tested with a dependency-free bash harness; `bash -n` and `shellcheck` are CI-less gates.

**Tech Stack:** bash, GNU stow, apt-get (Linux) / Homebrew (macOS), tpm, official installers (oh-my-posh, nvm, oh-my-zsh, zinit), JetBrainsMono Nerd Font.

---

## File Structure

- Create: `bootstrap.sh` — the entire bootstrap (repo root, executable).
- Create: `tests/bootstrap_test.sh` — dependency-free bash test harness for pure helpers.
- Modify: `README.md` — replace manual apt block with a `bootstrap.sh` pointer; reconcile Fonts section to JetBrainsMono + plain-Monospace-fallback.

Constants live at the top of `bootstrap.sh`: `REPO_URL`, `FONT_VERSION`, `FONT_NAME`, `STOW_PACKAGES`, `CORE_PKGS`.

Testing strategy: pure helpers are sourced by the test harness via `BOOTSTRAP_SOURCE_ONLY=1` (script defines functions then returns instead of running `main`). Side-effecting functions are exercised in dry-run with `PATH` stubs and a temp `HOME`.

---

### Task 1: Script skeleton, sourcing guard, `run()` wrapper, CLI, ERR trap

**Files:**
- Create: `bootstrap.sh`
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/bootstrap_test.sh`:

```bash
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
[ ! -e "/tmp/should_not_exist_$$" ] && ok "run() does not execute in dry-run" \
  || notok "run() executed despite dry-run"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — `bootstrap.sh` does not exist (`No such file or directory`).

- [ ] **Step 3: Write minimal implementation**

Create `bootstrap.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# ---- Constants ------------------------------------------------------------
REPO_URL="https://github.com/AcacioTelechi/dotfiles.git"
REPO_DIR="$HOME/dotfiles"
FONT_VERSION="v3.2.1"
FONT_NAME="JetBrainsMono"
STOW_PACKAGES="nvim tmux zsh"
CORE_PKGS="git stow zsh tmux neovim ripgrep zoxide curl"

DRY_RUN=0

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
      -h|--help) usage; exit 0 ;;
      *) die "unknown argument: $1 (try --help)" ;;
    esac
    shift
  done
}

on_err() { warn "failed at line $1 (last step did not complete)"; }

main() {
  trap 'on_err $LINENO' ERR
  parse_args "$@"
  [ "${EUID:-$(id -u)}" -ne 0 ] || die "do not run as root; sudo is used only where needed"
  log "bootstrap starting (dry-run=$DRY_RUN)"
  # subsequent tasks wire steps in here
  log "bootstrap done"
}

# Allow the test harness to source helpers without running main.
if [ "${BOOTSTRAP_SOURCE_ONLY:-0}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

main "$@"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — `2 passed, 0 failed`.

- [ ] **Step 5: Lint gates**

Run: `bash -n bootstrap.sh && chmod +x bootstrap.sh tests/bootstrap_test.sh`
Run (if available): `command -v shellcheck >/dev/null && shellcheck bootstrap.sh tests/bootstrap_test.sh`
Expected: no syntax errors; shellcheck clean (or absent).

- [ ] **Step 6: Commit**

```bash
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): script skeleton, run() wrapper, CLI, ERR trap"
```

---

### Task 2: `detect_os` helper

**Files:**
- Modify: `bootstrap.sh` (add `detect_os`, call from `main`)
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test**

Append before the summary `printf` in `tests/bootstrap_test.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — `detect_os: command not found`.

- [ ] **Step 3: Write minimal implementation**

Add to `bootstrap.sh` after `have()`:

```bash
OS=""
PKG=""
detect_os() {
  local u="${BOOTSTRAP_UNAME:-$(uname -s)}"
  case "$u" in
    Linux)  OS="linux"; PKG="apt-get" ;;
    Darwin) OS="macos"; PKG="brew" ;;
    *) die "unsupported OS: $u (Linux and macOS only)" ;;
  esac
}
```

Add `detect_os` as the first call in `main` after the root check:

```bash
  detect_os
  log "detected OS=$OS PKG=$PKG"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — all assertions including the 3 new ones.

- [ ] **Step 5: Lint + commit**

```bash
bash -n bootstrap.sh
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): add detect_os (Linux/macOS)"
```

---

### Task 3: `backup_if_conflict` + `stow_packages`

**Files:**
- Modify: `bootstrap.sh`
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test**

Append to `tests/bootstrap_test.sh`:

```bash
# --- backup_if_conflict ---
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — `backup_if_conflict: command not found`.

- [ ] **Step 3: Write minimal implementation**

Add to `bootstrap.sh`:

```bash
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
    done < <(cd "$REPO_DIR" && find "$pkg" -type f -not -path '*/.git/*' | sed "s|^|$REPO_DIR/|" | sed "s|$REPO_DIR/||")
    run stow -d "$REPO_DIR" -t "$HOME" -R "$pkg"
    log "stowed $pkg"
  done
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — Cases A/B/C ok.

- [ ] **Step 5: Lint + commit**

```bash
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh || true
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): stow_packages with auto-backup of conflicts"
```

---

### Task 4: `install_pkgs` (apt/brew, Homebrew bootstrap on macOS)

**Files:**
- Modify: `bootstrap.sh`
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test (dry-run, PATH-stubbed)**

Append to `tests/bootstrap_test.sh`:

```bash
# --- install_pkgs (dry-run) ---
DRY_RUN=1
OS="linux"; PKG="apt-get"
out="$(install_pkgs 2>&1)"
echo "$out" | grep -q 'DRY-RUN: sudo apt-get update' \
  && ok "install_pkgs(linux) runs apt-get update" \
  || notok "install_pkgs(linux) missing apt-get update"
echo "$out" | grep -q 'DRY-RUN: sudo apt-get install -y git stow zsh tmux neovim ripgrep zoxide curl' \
  && ok "install_pkgs(linux) installs CORE_PKGS" \
  || notok "install_pkgs(linux) missing CORE_PKGS install"
OS="macos"; PKG="brew"
out="$(install_pkgs 2>&1)"
echo "$out" | grep -q 'DRY-RUN: brew install git stow zsh tmux neovim ripgrep zoxide curl' \
  && ok "install_pkgs(macos) brew install CORE_PKGS" \
  || notok "install_pkgs(macos) missing brew install"
DRY_RUN=0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — `install_pkgs: command not found`.

- [ ] **Step 3: Write minimal implementation**

Add to `bootstrap.sh`:

```bash
ensure_homebrew() {
  have brew && return 0
  log "installing Homebrew"
  run /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_pkgs() {
  if [ "$OS" = "linux" ]; then
    run sudo apt-get update
    run sudo apt-get install -y $CORE_PKGS
  else
    ensure_homebrew
    run brew install $CORE_PKGS
  fi
}
```

(Per-tool `have` skipping is unnecessary: `apt-get`/`brew install` are themselves idempotent and exit 0 for already-installed packages. The whole step is still skippable via `--dry-run`.)

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — all 3 install_pkgs assertions.

- [ ] **Step 5: Lint + commit**

```bash
bash -n bootstrap.sh
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): install_pkgs via apt-get/brew (+Homebrew bootstrap)"
```

---

### Task 5: `install_third_party` (oh-my-posh, nvm/node, oh-my-zsh, zinit)

**Files:**
- Modify: `bootstrap.sh`
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test**

Append to `tests/bootstrap_test.sh`:

```bash
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
export HOME="$OLDHOME"; rm -rf "$TMPHOME"; DRY_RUN=0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — `install_third_party: command not found`.

- [ ] **Step 3: Write minimal implementation**

Add to `bootstrap.sh`:

```bash
install_third_party() {
  # oh-my-posh
  if have oh-my-posh; then
    log "oh-my-posh present, skipping"
  elif [ "$OS" = "macos" ]; then
    run brew install jandedobbeleer/oh-my-posh/oh-my-posh
  else
    run sh -c \
      'curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"'
  fi

  # nvm + LTS node
  if [ -d "$HOME/.nvm" ]; then
    log "nvm present, skipping"
  else
    run sh -c \
      'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
  fi
  run bash -c '. "$HOME/.nvm/nvm.sh" 2>/dev/null && nvm install --lts || true'

  # oh-my-zsh (unattended)
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "oh-my-zsh present, skipping"
  else
    run sh -c \
      'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  fi

  # zinit
  if [ -d "$HOME/.local/share/zinit/zinit.git" ]; then
    log "zinit present, skipping"
  else
    run sh -c \
      'bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"'
  fi
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — oh-my-posh / nvm / oh-my-zsh / zinit all mentioned in dry-run output.

- [ ] **Step 5: Lint + commit**

```bash
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh || true
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): install_third_party via official installers (guarded)"
```

---

### Task 6: `install_font` (JetBrainsMono Nerd Font, per-OS path)

**Files:**
- Modify: `bootstrap.sh`
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test**

Append to `tests/bootstrap_test.sh`:

```bash
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
echo "$out" | grep -q "$TMPHOME/Library/Fonts" \
  && ok "install_font(macos) targets ~/Library/Fonts" \
  || notok "install_font(macos) wrong target"
# idempotency: pretend already installed
mkdir -p "$TMPHOME/Library/Fonts"
touch "$TMPHOME/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"
out="$(install_font 2>&1)"
echo "$out" | grep -qi "skip" \
  && ok "install_font skips when already installed" \
  || notok "install_font not idempotent"
export HOME="$OLDHOME"; rm -rf "$TMPHOME"; DRY_RUN=0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — `install_font: command not found`.

- [ ] **Step 3: Write minimal implementation**

Add to `bootstrap.sh`:

```bash
install_font() {
  local dir zip url
  if [ "$OS" = "macos" ]; then
    dir="$HOME/Library/Fonts"
  else
    dir="$HOME/.local/share/fonts"
  fi
  if ls "$dir"/JetBrainsMono*NerdFont*.ttf >/dev/null 2>&1; then
    log "JetBrainsMono Nerd Font already installed in $dir, skipping"
    return 0
  fi
  url="https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/$FONT_NAME.zip"
  zip="$(mktemp -d)/$FONT_NAME.zip"
  run mkdir -p "$dir"
  run curl -fLo "$zip" "$url"
  run unzip -o "$zip" -d "$dir"
  if [ "$OS" = "linux" ]; then
    run fc-cache -f "$dir"
  fi
  log "installed $FONT_NAME Nerd Font to $dir"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — linux target, fc-cache, macos target, and skip-when-installed.

- [ ] **Step 5: Lint + commit**

```bash
bash -n bootstrap.sh
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): install_font (JetBrainsMono Nerd Font, per-OS)"
```

---

### Task 7: `bootstrap_tmux` + wire `main()` + final summary

**Files:**
- Modify: `bootstrap.sh`
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test**

Append to `tests/bootstrap_test.sh`:

```bash
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
echo "$e2e" | grep -qi "select it.*or.*Monospace\|fallback" \
  && ok "e2e: prints font reminder" || notok "e2e: missing font reminder"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — `bootstrap_tmux: command not found` and e2e missing font reminder.

- [ ] **Step 3: Write minimal implementation**

Add to `bootstrap.sh`:

```bash
bootstrap_tmux() {
  local tpm="$HOME/.config/tmux/plugins/tpm"
  if [ -d "$tpm" ]; then
    log "tpm present, skipping clone"
  else
    run git clone https://github.com/tmux-plugins/tpm "$tpm"
  fi
  run "$tpm/bin/install_plugins"
}

print_summary() {
  cat <<EOF

────────────────────────────────────────────────────────────
Bootstrap complete.

Next steps (manual, intentionally not automated):
  • Terminal font: either select "JetBrainsMono Nerd Font" in your
    terminal emulator, OR keep a plain Monospace font and rely on
    fontconfig fallback for glyphs. Do NOT set a Nerd Font as the
    primary font if you hit double-spaced text (see README Fonts).
  • Start a fresh shell:  exec zsh
  • Inside tmux, plugins are already installed; reload with: prefix + r
────────────────────────────────────────────────────────────
EOF
}
```

Replace the placeholder comment in `main` with the wired pipeline:

```bash
  detect_os
  log "detected OS=$OS PKG=$PKG"
  ensure_repo
  install_pkgs
  install_third_party
  stow_packages
  install_font   || warn "font step failed (non-fatal); see README Fonts"
  bootstrap_tmux || warn "tmux plugin step failed (non-fatal)"
  print_summary
  log "bootstrap done"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — `bootstrap_tmux` assertions + e2e start/finish/font-reminder.

Note: `ensure_repo` is implemented in Task 8; until then, add a temporary
stub `ensure_repo() { :; }` near the top so `main` is runnable. Task 8
replaces it.

- [ ] **Step 5: Lint + commit**

```bash
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh tests/bootstrap_test.sh || true
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): bootstrap_tmux, wire main(), final summary"
```

---

### Task 8: `ensure_repo` (clone + re-exec when run remotely)

**Files:**
- Modify: `bootstrap.sh` (replace the `ensure_repo` stub)
- Test: `tests/bootstrap_test.sh`

- [ ] **Step 1: Write the failing test**

Append to `tests/bootstrap_test.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/bootstrap_test.sh`
Expected: FAIL — current stub `ensure_repo() { :; }` produces no output, so the
assertion passes only by accident; replace the test expectation by first
making the stub `log "clone ..."` to see RED, then implement Step 3. (If the
stub already returns nothing, this test is GREEN trivially — proceed to Step 3
to implement real behavior and keep it GREEN.)

- [ ] **Step 3: Write minimal implementation**

Replace the `ensure_repo` stub in `bootstrap.sh` with:

```bash
# ensure_repo — if not already inside the dotfiles repo, clone it and
# re-exec the bootstrap from the clone. Idempotent.
ensure_repo() {
  if [ -d "$REPO_DIR/.git" ]; then
    log "using existing repo at $REPO_DIR"
    return 0
  fi
  # Are we already running from inside a dotfiles checkout?
  local self_dir
  self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -d "$self_dir/.git" ] && [ -f "$self_dir/bootstrap.sh" ]; then
    REPO_DIR="$self_dir"
    log "running from repo checkout at $REPO_DIR"
    return 0
  fi
  log "cloning $REPO_URL -> $REPO_DIR"
  run git clone "$REPO_URL" "$REPO_DIR"
  if [ "$DRY_RUN" -eq 0 ]; then
    exec bash "$REPO_DIR/bootstrap.sh" $([ "$DRY_RUN" -eq 1 ] && echo --dry-run)
  fi
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/bootstrap_test.sh`
Expected: PASS — `ensure_repo no-op inside existing repo`, all prior assertions still green.

- [ ] **Step 5: Full gate + commit**

```bash
bash -n bootstrap.sh
command -v shellcheck >/dev/null && shellcheck bootstrap.sh tests/bootstrap_test.sh || true
bash tests/bootstrap_test.sh
# Real idempotency smoke: a second dry-run end-to-end must stay 0-failure
BOOTSTRAP_UNAME=Linux bash bootstrap.sh --dry-run >/dev/null && echo "e2e dry-run OK"
git add bootstrap.sh tests/bootstrap_test.sh
git commit -m "feat(bootstrap): ensure_repo (clone + re-exec when remote)"
```

---

### Task 9: README reconciliation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the manual Bootstrap block**

In `README.md`, replace the contents of the "Bootstrap (fresh machine)" code block with:

````markdown
```sh
# one command — Linux or macOS, idempotent, safe to re-run
git clone https://github.com/AcacioTelechi/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh          # add --dry-run to preview
```

`bootstrap.sh` installs dependencies (apt/brew), stows `nvim tmux zsh`
(backing up any conflicting real files to `*.pre-stow.bak`), installs
oh-my-posh / nvm+node / oh-my-zsh / zinit, installs JetBrainsMono Nerd
Font, and bootstraps tmux plugins. It does **not** change your terminal
emulator's settings.
````

- [ ] **Step 2: Reconcile the Fonts section**

In `README.md` Fonts section, replace the Meslo download + `gsettings font 'MesloLGS Nerd Font 12'` guidance with:

````markdown
`bootstrap.sh` installs **JetBrainsMono Nerd Font**. Setting it as your
terminal font is manual and emulator-specific. On this machine's GNOME
Terminal/VTE, patched Nerd Font *families* render every character
double-spaced — so the working configuration is to keep the profile font
as plain `Monospace` and let fontconfig fall back to the installed Nerd
Font for glyphs. See the Troubleshooting row "Tofu boxes / double-spacing".
````

- [ ] **Step 3: Verify links/anchors still resolve**

Run: `grep -n 'Fonts\|bootstrap.sh' README.md`
Expected: the `#fonts` anchor references and the new `bootstrap.sh` mention are present and consistent; no dangling reference to the deleted Meslo gsettings command.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: point bootstrap at bootstrap.sh; reconcile Fonts to JetBrainsMono"
```

---

## Self-Review

**1. Spec coverage:**
- Full bootstrap (deps+stow+tpm+font) → Tasks 4,5,3,6,7 ✓
- Idempotent + auto-backup → `backup_if_conflict` Task 3; `have`/path guards Tasks 4–8 ✓
- Font, no terminal config → Task 6 + summary Task 7 + README Task 9 ✓
- Official installers for 3rd-party → Task 5 ✓
- Single `bootstrap.sh`, approach A → Task 1 ✓
- `--dry-run`, `--help`, ERR trap, no-root → Task 1 ✓
- Cross-platform apt/brew + Homebrew bootstrap → Tasks 2,4 ✓
- Testing: `bash -n`, shellcheck, idempotency, dry-run → every task's lint step + Task 8 e2e ✓
- Follow-ups (README) → Task 9 ✓
- Out-of-scope (no dconf/Windows/uninstall/templating) → honored; no task adds them ✓

**2. Placeholder scan:** No "TBD/TODO/handle edge cases". The only forward
reference (`ensure_repo` used in Task 7, implemented Task 8) is explicitly
bridged with a named stub and called out in Task 7 Step 4.

**3. Type/name consistency:** `run`, `have`, `log/warn/die`, `OS`, `PKG`,
`REPO_DIR`, `STOW_PACKAGES`, `CORE_PKGS`, `FONT_VERSION`, `FONT_NAME`,
`backup_if_conflict`, `detect_os`, `install_pkgs`, `install_third_party`,
`stow_packages`, `install_font`, `bootstrap_tmux`, `ensure_repo`,
`print_summary` — names used identically across all tasks. `BOOTSTRAP_UNAME`
test override matches `detect_os`. `BOOTSTRAP_SOURCE_ONLY` guard matches the
harness sourcing in Task 1.

# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a *stow package* whose internal structure mirrors
the path relative to `$HOME`.

```
dotfiles/
├── nvim/.config/nvim/{init.lua,lazy-lock.json}   → ~/.config/nvim/
├── tmux/.config/tmux/tmux.conf                    → ~/.config/tmux/
├── zsh/{.zshrc,.zprofile}                         → ~/.zshrc, ~/.zprofile
└── ohmyposh/.config/ohmyposh/base.toml           → ~/.config/ohmyposh/
```

## Prerequisites

`bootstrap.sh` installs all of these automatically; the table documents what/why for manual setups.

| Tool | Why | Install (Ubuntu) |
|------|-----|------------------|
| `git` | clone this repo | `sudo apt-get install -y git` |
| `stow` | symlink the packages | `sudo apt-get install -y stow` |
| `zsh` | shell | `sudo apt-get install -y zsh` |
| `tmux` (≥ 3.1) | multiplexer; config uses `terminal-features` | `sudo apt-get install -y tmux` |
| `neovim` | editor | `sudo apt-get install -y neovim` |
| `ripgrep` | telescope `live_grep` | `sudo apt-get install -y ripgrep` |
| `zoxide` | smart `cd` (`z`) in zsh | `sudo apt-get install -y zoxide` |
| Node | `pyright` LSP server | via nvm (already configured in `.zshrc`) |
| `oh-my-posh` | zsh prompt | see <https://ohmyposh.dev/docs/installation/linux> |
| A **Nerd Font** | prompt/icon glyphs | see [Fonts](#fonts) below |

## Bootstrap (fresh machine)

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

For partial or manual use, `stow -t ~ <pkg>` creates symlinks from `$HOME`
into this repo — the commands below are an alternative to `bootstrap.sh`
for when you only need specific packages.

### Useful stow commands

```sh
stow -t ~ nvim          # link the nvim package
stow -R -t ~ nvim          # re-stow (after adding/removing files)
stow -D -t ~ nvim          # unlink (remove the symlinks)
stow -nv -t ~ nvim          # dry-run: show what would happen
```

## Packages

### nvim
- Plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim) (auto-bootstraps on first launch).
- Leader key is `Space`.
- Plugins (all lazy-loaded via `event`/`keys`):
  - `catppuccin` — colorscheme
  - `telescope.nvim` (+ `plenary`, `fzf-native`) — fuzzy finder, loads on
    first `<leader>f*` keypress; uses the `keys =` spec (not top-level
    `require`) so it never blocks startup.
  - `nvim-treesitter` — syntax/indent, auto-installs parsers
  - `mason.nvim` + `mason-lspconfig` + `nvim-lspconfig` — LSP; `lua_ls`
    and `pyright` installed automatically (pyright needs Node on `PATH`)
  - `nvim-cmp` + `LuaSnip` — completion
  - `which-key.nvim` — popup of keybindings after `<leader>`
- Keymaps: `<leader>ff/fg/fb/fh` (find files / grep / buffers / help);
  on LSP attach — `gd`, `gr`, `K`, `<leader>rn`, `<leader>ca`.
- First launch downloads plugins (`make` runs for `fzf-native`, Treesitter
  parsers + Mason servers download); let the lazy.nvim UI finish.
- `live_grep` needs `ripgrep` on `PATH` (`sudo apt-get install -y ripgrep`).

### tmux
- Prefix remapped `C-b` → `C-a`.
- True-color (`RGB`) so oh-my-posh / nvim colors render inside tmux.
- `escape-time 10` and `focus-events on` for a lag-free Neovim experience.
- Mouse on, vi copy-mode, 1-based indexing, 50k scrollback.
- Reload without restarting: `prefix` then `r`.
- Theme: [`catppuccin/tmux`](https://github.com/catppuccin/tmux) pinned to
  `#v2.3.0` (v2 API — composes the status bar from modules: session on the
  left, app + date/time on the right; `mocha` flavor, `rounded` tabs).
  **Renders Nerd Font glyphs** (window flags, separators) — without a Nerd
  Font the status bar shows tofu boxes; see [Fonts](#fonts).
- Plugins via [tpm](https://github.com/tmux-plugins/tpm) (cloned to
  `~/.config/tmux/plugins/`, git-ignored): `vim-tmux-navigator`
  (`C-h/j/k/l` across tmux panes **and** nvim splits — needs the nvim-side
  plugin too), `tmux-resurrect` + `tmux-continuum` (auto save/restore
  sessions across reboots), `catppuccin/tmux` (theme, above).
  **One-time (only if not using `bootstrap.sh`, which does this for you):**
  clone tpm, then `prefix` + `I` inside tmux to install:
  ```sh
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
  ```

### zsh
- `oh-my-zsh` + `zinit` (syntax-highlighting, autosuggestions, completions),
  `fzf` keybindings, `oh-my-posh` prompt.
- zinit plugins are **deferred** (`zinit ice wait lucid`) so the prompt
  paints before they attach — faster startup. They appear a split-second
  after the first prompt; this is expected.
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) for smart `cd`:
  `z <partial>` jumps to your most-used matching dir. Init is guarded by
  `command -v zoxide` so a missing binary never breaks the shell —
  install it with `sudo apt-get install -y zoxide`.
- **oh-my-posh init is guarded by `_OMP_INITIALIZED`.** Re-`source`-ing
  `.zshrc` in the same shell re-wraps ZLE widgets and stacks
  `_omp_call_widget` until `FUNCNEST` blows
  (`maximum nested function level reached`). The guard makes re-sourcing a
  no-op. **To test changes, open a new shell (`exec zsh`), don't
  `source ~/.zshrc`.**
- **fzf** key-bindings/completion are sourced portably: `fzf --zsh` when
  available (fzf ≥ 0.48), else the apt (`/usr/share/doc/fzf/examples`) or
  Homebrew (`$(brew --prefix)/opt/fzf/shell`) paths — all guarded by
  `command -v fzf` so a missing binary never breaks startup.

### ohmyposh
- `oh-my-posh` prompt theme. `.zshrc` initialises it with
  `--config ~/.config/ohmyposh/base.toml`; that file is tracked here so a
  fresh machine gets the real prompt (without it oh-my-posh prints
  `CONFIG NOT FOUND` and the prompt renders as tofu).

## Fonts

oh-my-posh's theme uses Nerd Font glyphs. Without a Nerd Font you get tofu
boxes (``).

`bootstrap.sh` installs **JetBrainsMono Nerd Font** (macOS: the
`font-jetbrains-mono-nerd-font` Homebrew cask, brew-managed/upgradable;
Linux: the pinned nerd-fonts release zip into `~/.local/share/fonts`).
**Pointing your terminal at it is a manual, per-OS step the script does
not do** — and the correct approach differs by platform:

**macOS (Terminal.app / iTerm2):** set the terminal's font directly to
**JetBrainsMono Nerd Font Mono** (Terminal.app → Settings → Profiles →
Text → Font → Change…). macOS has no fontconfig glyph-fallback, so a plain
`Monospace` font stays tofu — the terminal font itself must be the Nerd
Font. macOS terminals do **not** have the VTE double-spacing bug, so this
is safe and is the recommended setup. If powerline separators look clipped
with the `Mono` variant, use plain **JetBrainsMono Nerd Font**.

**Linux (GNOME Terminal / VTE):** do the opposite — keep the profile font
as plain `Monospace` and let **fontconfig** fall back to the installed
Nerd Font for glyphs. Selecting a patched Nerd Font *family* as the VTE
terminal font triggers a bug that renders every character double-spaced
(`t o t a l`); see the Troubleshooting row of the same name.

Either way, terminal font changes apply to **new terminal windows** only.

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `module 'telescope.builtin' not found` on nvim start | Something `require`s telescope at the top level before lazy.nvim installs it. Telescope must be loaded via its `keys =` spec — never `require('telescope.builtin')` at file scope. |
| `live_grep`: "ripgrep not found" | `sudo apt-get install -y ripgrep` |
| `pyright` LSP doesn't start | Needs Node on `PATH`; with nvm run `nvm use` (or `nvm alias default <ver>`) before launching nvim. |
| tmux `prefix + I` does nothing | tpm not cloned — `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`. |
| Tofu boxes `` in prompt **or tmux status bar** | No Nerd Font (or terminal not set to use it) — see [Fonts](#fonts). |
| `_omp_call_widget: maximum nested function level reached` | You re-`source`d `.zshrc`. Open a new shell (`exec zsh`); the `_OMP_INITIALIZED` guard prevents recurrence. |
| Every character double-spaced (`t o t a l`) | Patched Nerd Font *families* set as the terminal font cause this on GNOME Terminal/VTE. Working fix: keep the terminal profile font as plain `Monospace`; fontconfig falls back to the installed Nerd Font for glyphs automatically. |
| `stow` creates `~/config` instead of `~/.config/nvim` | Package structure too shallow. A file at `~/.config/nvim/init.lua` must live at `dotfiles/nvim/.config/nvim/init.lua`. |

## Conventions

- One stow package per tool, named after the tool.
- Inside a package, recreate the file's path **relative to `$HOME`**
  (`~/.config/x/y` → `dotfiles/<pkg>/.config/x/y`).
- Backups (`*.bak`), history, and `.zcompdump*` are git-ignored — never commit
  them.

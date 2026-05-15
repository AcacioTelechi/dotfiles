# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a *stow package* whose internal structure mirrors
the path relative to `$HOME`.

```
dotfiles/
├── nvim/.config/nvim/{init.lua,lazy-lock.json}   → ~/.config/nvim/
├── tmux/.config/tmux/tmux.conf                    → ~/.config/tmux/
└── zsh/{.zshrc,.zprofile}                         → ~/.zshrc, ~/.zprofile
```

## Prerequisites

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
# 1. clone
git clone https://github.com/AcacioTelechi/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. (optional) back up anything stow would clobber
for f in ~/.zshrc ~/.zprofile ~/.config/nvim ~/.config/tmux; do
  [ -e "$f" ] && [ ! -L "$f" ] && mv "$f" "$f.pre-stow.bak"
done

# 3. symlink every package into $HOME
stow -t ~ nvim tmux zsh

# 4. start a fresh shell
exec zsh
```

`stow -t ~ <pkg>` creates symlinks from `$HOME` into this repo. Re-running it
is safe and idempotent — it adopts links that already point here.

### Useful stow commands

```sh
stow  -t ~ nvim          # link the nvim package
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
  **One-time:** clone tpm, then `prefix` + `I` inside tmux to install:
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

## Fonts

oh-my-posh's theme uses Nerd Font glyphs. Without a Nerd Font you get tofu
boxes (``).

```sh
mkdir -p ~/.local/share/fonts/NerdFonts
curl -fLo /tmp/Meslo.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
unzip -o /tmp/Meslo.zip -d ~/.local/share/fonts/NerdFonts/Meslo
fc-cache -f ~/.local/share/fonts
```

Then set your **terminal emulator's** font to a Meslo Nerd Font variant (the
font is a terminal-app setting, not a dotfile). GNOME Terminal, default
profile, via CLI:

```sh
P="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \"'\")/"
gsettings set "$P" use-system-font false
gsettings set "$P" font 'MesloLGS Nerd Font 12'
```

Font changes apply to **new terminal windows**.

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `module 'telescope.builtin' not found` on nvim start | Something `require`s telescope at the top level before lazy.nvim installs it. Telescope must be loaded via its `keys =` spec — never `require('telescope.builtin')` at file scope. |
| `live_grep`: "ripgrep not found" | `sudo apt-get install -y ripgrep` |
| `pyright` LSP doesn't start | Needs Node on `PATH`; with nvm run `nvm use` (or `nvm alias default <ver>`) before launching nvim. |
| tmux `prefix + I` does nothing | tpm not cloned — `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`. |
| Tofu boxes `` in prompt **or tmux status bar** | No Nerd Font (or terminal not set to use it) — see [Fonts](#fonts). |
| `_omp_call_widget: maximum nested function level reached` | You re-`source`d `.zshrc`. Open a new shell (`exec zsh`); the `_OMP_INITIALIZED` guard prevents recurrence. |
| Every character double-spaced (`t o t a l`) | Terminal font metrics — try the **non-`Mono`** `MesloLGS Nerd Font`; if a plain font also doubles, the issue is the terminal/tmux, not the font. |
| `stow` creates `~/config` instead of `~/.config/nvim` | Package structure too shallow. A file at `~/.config/nvim/init.lua` must live at `dotfiles/nvim/.config/nvim/init.lua`. |

## Conventions

- One stow package per tool, named after the tool.
- Inside a package, recreate the file's path **relative to `$HOME`**
  (`~/.config/x/y` → `dotfiles/<pkg>/.config/x/y`).
- Backups (`*.bak`), history, and `.zcompdump*` are git-ignored — never commit
  them.

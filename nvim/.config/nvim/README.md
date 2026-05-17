# Neovim — AstroNvim v6

This is an [AstroNvim](https://astronvim.com) v6 configuration, managed as a
GNU stow package in this dotfiles repo (`~/.config/nvim` symlinks here).

Customizations live in the template override files:

- `lua/community.lua` — catppuccin colorscheme + Lua/Python/TS/JSON language packs
- `lua/plugins/astroui.lua` — colorscheme selection
- `lua/plugins/astrocore.lua` — personal vim options and keymaps
- `lua/polish.lua` — `~/.vim/undodir` creation
- `lua/plugins/user.lua` — extra plugins (vim-tmux-navigator)

Migration design/plan: `docs/superpowers/specs/` and `docs/superpowers/plans/`.

-- ============================================================================
-- KEYMAPS
-- ============================================================================
vim.g.mapleader = " "

vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- ============================================================================
-- OPTIONS
-- ===========================================================================
vim.opt.number = true -- line number
vim.opt.relativenumber = true -- relative line numbers
vim.opt.cursorline = true -- highlight current line
vim.opt.wrap = false -- do not wrap lines by default
vim.opt.scrolloff = 10 -- keep 10 lines above/below cursor
vim.opt.sidescrolloff = 10 -- keep 10 lines to left/right of cursor

vim.opt.tabstop = 2 -- tabwidth
vim.opt.shiftwidth = 2 -- indent width
vim.opt.softtabstop = 2 -- soft tab stop not tabs on tab/backspace
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.smartindent = true -- smart auto-indent
vim.opt.autoindent = true -- copy indent from current line

vim.opt.ignorecase = true -- case insensitive search
vim.opt.smartcase = true -- case sensitive if uppercase in string
vim.opt.hlsearch = true -- highlight search matches
vim.opt.incsearch = true -- show matches as you type

vim.opt.signcolumn = "yes" -- always show a sign column
vim.opt.colorcolumn = "100" -- show a column at 100 position chars
vim.opt.showmatch = true -- highlights matching brackets
vim.opt.cmdheight = 1 -- single line command line
vim.opt.completeopt = "menuone,noinsert,noselect" -- completion options
vim.opt.showmode = false -- do not show the mode, instead have it in statusline
vim.opt.pumheight = 10 -- popup menu height
vim.opt.pumblend = 10 -- popup menu transparency
vim.opt.winblend = 0 -- floating window transparency
vim.opt.conceallevel = 2 -- obsidian requirement
vim.opt.concealcursor = "" -- do not hide cursorline in markup
vim.opt.lazyredraw = true -- do not redraw during macros
vim.opt.synmaxcol = 300 -- syntax highlighting limit
vim.opt.fillchars = { eob = " " } -- hide "~" on empty lines

--- Undodir
local undodir = vim.fn.expand("~/.vim/undodir")
if 
	vim.fn.isdirectory(undodir) == 0 -- create undodir if nonexistent
then
	vim.fn.mkdir(undodir, "p")
end

vim.opt.backup = false -- do not create backup files
vim.opt.writebackup = false -- do not create bak files
vim.opt.swapfile = false -- do not create swapfile
vim.opt.undofile = true -- do create an undo files
vim.opt.undodir = undodir -- set the undo directory
vim.opt.updatetime = 300 -- faster Completion
vim.opt.timeoutlen = 500 -- timeout duration
vim.opt.ttimeoutlen = 0 -- key code timeout
vim.opt.autoread = true -- auto-reload changes if outside of neovim
vim.opt.autowrite = false -- do not auto-save

-- Other
vim.opt.hidden = true -- allow hidden buffers
vim.opt.errorbells = false -- no error sounds
vim.opt.backspace = "indent,eol,start" -- better backspace behaviour
vim.opt.autochdir = false -- do not autochange directories
vim.opt.iskeyword:append("-") -- include - in words
vim.opt.path:append("**") -- include subdirs in search
vim.opt.selection = "inclusive" -- include last char in selection
vim.opt.mouse = "a" -- enable mouse support
vim.opt.clipboard:append("unnamedplus") -- use system clipboard
vim.opt.modifiable = true -- allow buffer modifications
vim.opt.encoding = "utf-8" -- set encoding


vim.opt.guicursor =
	"n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175" -- cursor blinking and settings

-- Folding: requires treesitter available at runtime; safe fallback if not
vim.opt.foldmethod = "expr" -- use expression for folding
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- use treesitter for folding
vim.opt.foldlevel = 99 -- start with all folds open

vim.opt.splitbelow = true -- horizontal splits go below
vim.opt.splitright = true -- vertical splits go right

vim.opt.wildmenu = true -- tab completion
vim.opt.wildmode = "longest:full,full" -- complete longest common match, full completion list, cycle through with Tab
vim.opt.diffopt:append("linematch:60") -- improve diff display
vim.opt.redrawtime = 10000 -- increase neovim redraw tolerance
vim.opt.maxmempattern = 20000 -- increase max memory


-- ============================================================================
-- STATUSLINE
-- ============================================================================

-- Git branch function with caching and Nerd Font icon
local cached_branch = ""
local last_check = 0
local function git_branch()
	local now = vim.loop.now()
	if now - last_check > 5000 then -- Check every 5 seconds
		cached_branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
		last_check = now
	end
	if cached_branch ~= "" then
		return " \u{e725} " .. cached_branch .. " " -- nf-dev-git_branch
	end
	return ""
end

-- File type with Nerd Font icon
local function file_type()
	local ft = vim.bo.filetype
	local icons = {
		lua = "\u{e620} ", -- nf-dev-lua
		python = "\u{e73c} ", -- nf-dev-python
		javascript = "\u{e74e} ", -- nf-dev-javascript
		typescript = "\u{e628} ", -- nf-dev-typescript
		javascriptreact = "\u{e7ba} ",
		typescriptreact = "\u{e7ba} ",
		html = "\u{e736} ", -- nf-dev-html5
		css = "\u{e749} ", -- nf-dev-css3
		scss = "\u{e749} ",
		json = "\u{e60b} ", -- nf-dev-json
		markdown = "\u{e73e} ", -- nf-dev-markdown
		vim = "\u{e62b} ", -- nf-dev-vim
		sh = "\u{f489} ", -- nf-oct-terminal
		bash = "\u{f489} ",
		zsh = "\u{f489} ",
		rust = "\u{e7a8} ", -- nf-dev-rust
		go = "\u{e724} ", -- nf-dev-go
		c = "\u{e61e} ", -- nf-dev-c
		cpp = "\u{e61d} ", -- nf-dev-cplusplus
		java = "\u{e738} ", -- nf-dev-java
		php = "\u{e73d} ", -- nf-dev-php
		ruby = "\u{e739} ", -- nf-dev-ruby
		swift = "\u{e755} ", -- nf-dev-swift
		kotlin = "\u{e634} ",
		dart = "\u{e798} ",
		elixir = "\u{e62d} ",
		haskell = "\u{e777} ",
		sql = "\u{e706} ",
		yaml = "\u{f481} ",
		toml = "\u{e615} ",
		xml = "\u{f05c} ",
		dockerfile = "\u{f308} ", -- nf-linux-docker
		gitcommit = "\u{f418} ", -- nf-oct-git_commit
		gitconfig = "\u{f1d3} ", -- nf-fa-git
		vue = "\u{fd42} ", -- nf-md-vuejs
		svelte = "\u{e697} ",
		astro = "\u{e628} ",
	}

	if ft == "" then
		return " \u{f15b} " -- nf-fa-file_o
	end

	return ((icons[ft] or " \u{f15b} ") .. ft)
end

-- File size with Nerd Font icon
local function file_size()
	local size = vim.fn.getfsize(vim.fn.expand("%"))
	if size < 0 then
		return ""
	end
	local size_str
	if size < 1024 then
		size_str = size .. "B"
	elseif size < 1024 * 1024 then
		size_str = string.format("%.1fK", size / 1024)
	else
		size_str = string.format("%.1fM", size / 1024 / 1024)
	end
	return " \u{f016} " .. size_str .. " " -- nf-fa-file_o
end

-- Mode indicators with Nerd Font icons
local function mode_icon()
	local mode = vim.fn.mode()
	local modes = {
		n = " \u{f121}  NORMAL",
		i = " \u{f11c}  INSERT",
		v = " \u{f0168} VISUAL",
		V = " \u{f0168} V-LINE",
		["\22"] = " \u{f0168} V-BLOCK",
		c = " \u{f120} COMMAND",
		s = " \u{f0c5} SELECT",
		S = " \u{f0c5} S-LINE",
		["\19"] = " \u{f0c5} S-BLOCK",
		R = " \u{f044} REPLACE",
		r = " \u{f044} REPLACE",
		["!"] = " \u{f489} SHELL",
		t = " \u{f120} TERMINAL",
	}
	return modes[mode] or (" \u{f059} " .. mode)
end

_G.mode_icon = mode_icon
_G.git_branch = git_branch
_G.file_type = file_type
_G.file_size = file_size

vim.cmd([[
  highlight StatusLineBold gui=bold cterm=bold
]])

-- Function to change statusline based on window focus
local function setup_dynamic_statusline()
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		callback = function()
			vim.opt_local.statusline = table.concat({
				"  ",
				"%#StatusLineBold#",
				"%{v:lua.mode_icon()}",
				"%#StatusLine#",
				" \u{e0b1} %f %h%m%r", -- nf-pl-left_hard_divider
				"%{v:lua.git_branch()}",
				"\u{e0b1} ", -- nf-pl-left_hard_divider
				"%{v:lua.file_type()}",
				"\u{e0b1} ", -- nf-pl-left_hard_divider
				"%{v:lua.file_size()}",
				"%=", -- Right-align everything after this
				" \u{f017} %l:%c  %P ", -- nf-fa-clock_o for line/col
			})
		end,
	})
	vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })

	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		callback = function()
			vim.opt_local.statusline = "  %f %h%m%r \u{e0b1} %{v:lua.file_type()} %=  %l:%c   %P "
		end,
	})
end

setup_dynamic_statusline()

-- ============================================================================
-- PLUGINS
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", --latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{
		'nvim-telescope/telescope.nvim', version = '*',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
		},
		-- lazy-loaded: telescope only loads on first use of these keys
		keys = {
			{ '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
			{ '<leader>fg', '<cmd>Telescope live_grep<cr>',  desc = 'Live grep' },
			{ '<leader>fb', '<cmd>Telescope buffers<cr>',    desc = 'Buffers' },
			{ '<leader>fh', '<cmd>Telescope help_tags<cr>',  desc = 'Help tags' },
		},
		config = function()
			require('telescope').setup()
			-- use the fzf-native we build for much faster sorting
			pcall(require('telescope').load_extension, 'fzf')
		end,
	},

	-- Treesitter: accurate syntax highlighting + indentation
	{
		'nvim-treesitter/nvim-treesitter',
		build = ':TSUpdate',
		event = { 'BufReadPost', 'BufNewFile' },
		config = function()
			require('nvim-treesitter.configs').setup({
				ensure_installed = {
					'lua', 'vim', 'vimdoc', 'bash',
					'python', 'json', 'yaml', 'markdown',
				},
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- Git signs in the gutter + inline blame
	{
		'lewis6991/gitsigns.nvim',
		event = { 'BufReadPost', 'BufNewFile' },
		config = function()
			require('gitsigns').setup({
				on_attach = function(bufnr)
					local gs = require('gitsigns')
					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
					end
					-- navigation
					map('n', ']c', function() gs.nav_hunk('next') end, 'Next hunk')
					map('n', '[c', function() gs.nav_hunk('prev') end, 'Prev hunk')
					-- actions
					map('n', '<leader>gs', gs.stage_hunk, 'Stage hunk')
					map('n', '<leader>gr', gs.reset_hunk, 'Reset hunk')
					map('n', '<leader>gp', gs.preview_hunk, 'Preview hunk')
					map('n', '<leader>gb', function() gs.blame_line({ full = true }) end, 'Blame line')
					map('n', '<leader>gB', gs.toggle_current_line_blame, 'Toggle line blame')
					map('n', '<leader>gd', gs.diffthis, 'Diff this')
				end,
			})
		end,
	},

	-- File tree: toggleable sidebar explorer
	{
		'nvim-tree/nvim-tree.lua',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		-- lazy-loaded: only loads on first use of the toggle key
		keys = {
			{ '<leader>e', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle file tree' },
		},
		config = function()
			require('nvim-tree').setup()
		end,
	},

	-- LSP: mason installs servers, lspconfig wires them up
	{
		'neovim/nvim-lspconfig',
		event = { 'BufReadPre', 'BufNewFile' },
		dependencies = {
			{ 'williamboman/mason.nvim', config = true },
			'williamboman/mason-lspconfig.nvim',
			'hrsh7th/cmp-nvim-lsp',
		},
		config = function()
			require('mason-lspconfig').setup({
				ensure_installed = { 'lua_ls', 'pyright' },
			})
			local caps = require('cmp_nvim_lsp').default_capabilities()
			local lsp = require('lspconfig')
			-- explicit per-server setup (stable across mason-lspconfig v1/v2)
			lsp.lua_ls.setup({
				capabilities = caps,
				settings = { Lua = { diagnostics = { globals = { 'vim' } } } },
			})
			lsp.pyright.setup({ capabilities = caps })

			vim.api.nvim_create_autocmd('LspAttach', {
				callback = function(ev)
					local b = { buffer = ev.buf }
					vim.keymap.set('n', 'gd', vim.lsp.buf.definition, b)
					vim.keymap.set('n', 'gr', vim.lsp.buf.references, b)
					vim.keymap.set('n', 'K',  vim.lsp.buf.hover, b)
					vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, b)
					vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, b)
				end,
			})
		end,
	},

	-- Completion (makes LSP actually usable)
	{
		'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		dependencies = {
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-buffer',
			'hrsh7th/cmp-path',
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip',
		},
		config = function()
			local cmp = require('cmp')
			local luasnip = require('luasnip')
			cmp.setup({
				snippet = {
					expand = function(args) luasnip.lsp_expand(args.body) end,
				},
				mapping = cmp.mapping.preset.insert({
					['<C-Space>'] = cmp.mapping.complete(),
					['<CR>']      = cmp.mapping.confirm({ select = true }),
					['<Tab>']     = cmp.mapping.select_next_item(),
					['<S-Tab>']   = cmp.mapping.select_prev_item(),
				}),
				sources = {
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
					{ name = 'buffer' },
					{ name = 'path' },
				},
			})
		end,
	},

	-- which-key: popup of available keybindings after <leader>
	{
		'folke/which-key.nvim',
		event = 'VeryLazy',
		config = function() require('which-key').setup() end,
	},
	
	-- Vim tmux navigator
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
		    "TmuxNavigateLeft",
		    "TmuxNavigateDown",
		    "TmuxNavigateUp",
		    "TmuxNavigateRight",
		    "TmuxNavigatePrevious",
		    "TmuxNavigatorProcessList",
		  },
		keys = {
		    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
		    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
		    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
		    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
		    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},
}
local opts = {}

require("lazy").setup(plugins, opts)

require("catppuccin").setup()
vim.cmd.colorscheme("catppuccin")

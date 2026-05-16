-- ============================================================================
-- KEYMAPS
-- ============================================================================
vim.g.mapleader = " "

vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.keymap.set("n", "<A-h>", "<<", { desc = "Indent left" })
vim.keymap.set("n", "<A-l>", ">>", { desc = "Indent right" })
vim.keymap.set("v", "<A-h>", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", "<A-l>", ">gv", { desc = "Indent right and reselect" })

vim.keymap.set("n", "<S-A-j>", ":t.<CR>", { desc = "Duplicate line down" })
vim.keymap.set("n", "<S-A-k>", ":t.-1<CR>", { desc = "Duplicate line up" })
vim.keymap.set("v", "<S-A-j>", ":t '><CR>gv=gv", { desc = "Duplicate selection down" })
vim.keymap.set("v", "<S-A-k>", ":t '<-1<CR>gv=gv", { desc = "Duplicate selection up" })

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


-- Statusline is provided by lualine.nvim (configured in the plugins section).

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

	-- Statusline (replaces the old hand-rolled one)
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		event = 'VeryLazy',
		config = function()
			require('lualine').setup({
				options = {
					theme = 'auto', -- auto-detects the active catppuccin colorscheme
					icons_enabled = true,
					globalstatus = true,
					section_separators = { left = '', right = '' },
					component_separators = { left = '', right = '' },
				},
				sections = {
					lualine_a = { 'mode' },
					lualine_b = { 'branch', 'diff', 'diagnostics' },
					lualine_c = { { 'filename', path = 1 } },
					lualine_x = { 'filetype', { 'filesize' }, 'encoding' },
					lualine_y = { 'progress' },
					lualine_z = { 'location' },
				},
			})
		end,
	},
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
		branch = 'master', -- classic API; `main` branch dropped require('nvim-treesitter.configs')
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

	-- Completion: blink.cmp (replaces nvim-cmp)
	{
		'saghen/blink.cmp',
		event = 'InsertEnter',
		version = '*', -- release tag ships a prebuilt fuzzy binary
		dependencies = {
			{ 'L3MON4D3/LuaSnip', dependencies = { 'rafamadriz/friendly-snippets' } },
		},
		config = function()
			require('blink.cmp').setup({
				keymap = {
					preset = 'none',
					['<C-Space>'] = { 'show', 'hide' },
					['<CR>'] = { 'accept', 'fallback' },
					['<C-j>'] = { 'select_next', 'fallback' },
					['<C-k>'] = { 'select_prev', 'fallback' },
					['<Tab>'] = { 'snippet_forward', 'fallback' },
					['<S-Tab>'] = { 'snippet_backward', 'fallback' },
				},
				appearance = { nerd_font_variant = 'mono' },
				completion = { menu = { auto_show = true } },
				sources = { default = { 'lsp', 'path', 'buffer', 'snippets' } },
				snippets = {
					expand = function(snippet)
						require('luasnip').lsp_expand(snippet)
					end,
				},
				fuzzy = {
					implementation = 'prefer_rust',
					prebuilt_binaries = { download = true },
				},
			})
		end,
	},

	-- LSP + linting/formatting (efm) + diagnostics
	{
		'neovim/nvim-lspconfig',
		event = { 'BufReadPre', 'BufNewFile' },
		dependencies = {
			{ 'williamboman/mason.nvim', config = true },
			'williamboman/mason-lspconfig.nvim',
			'WhoIsSethDaniel/mason-tool-installer.nvim',
			'creativenull/efmls-configs-nvim',
			'saghen/blink.cmp', -- ensures blink is loaded before capabilities are read
			'nvim-telescope/telescope.nvim', -- LSP pickers below use telescope
		},
		config = function()
			local augroup = vim.api.nvim_create_augroup('UserLsp', { clear = true })

			-- LSP servers (matched to installed languages)
			require('mason-lspconfig').setup({
				ensure_installed = { 'lua_ls', 'pyright', 'ts_ls', 'efm' },
			})
			-- non-LSP linter/formatter binaries efm shells out to
			require('mason-tool-installer').setup({
				ensure_installed = {
					'stylua', 'selene',            -- lua (selene = prebuilt binary; luacheck needs luarocks)
					'black', 'flake8',             -- python
					'prettierd', 'eslint_d',       -- js/ts
					'fixjson',                     -- json
				},
			})

			-- Diagnostics UI
			local diagnostic_signs = {
				Error = " ",
				Warn = " ",
				Hint = "",
				Info = "",
			}
			vim.diagnostic.config({
				virtual_text = { prefix = "●", spacing = 4 },
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
						[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
						[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
						[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
					},
				},
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = true,
					header = "",
					prefix = "",
					focusable = false,
					style = "minimal",
				},
			})

			-- rounded borders on hover/signature popups
			do
				local orig = vim.lsp.util.open_floating_preview
				function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
					opts = opts or {}
					opts.border = opts.border or "rounded"
					return orig(contents, syntax, opts, ...)
				end
			end

			local function lsp_on_attach(ev)
				local client = vim.lsp.get_client_by_id(ev.data.client_id)
				if not client then
					return
				end

				local bufnr = ev.buf
				local builtin = require('telescope.builtin')
				local opts = { noremap = true, silent = true, buffer = bufnr }
				-- which-key reads `desc`; merge it into the shared opts per map
				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
				end

				map("n", "<leader>gd", builtin.lsp_definitions, "Goto definition (Telescope)")
				map("n", "<leader>gD", vim.lsp.buf.definition, "Goto definition")
				map("n", "<leader>gS", function()
					vim.cmd("vsplit")
					vim.lsp.buf.definition()
				end, "Goto definition (vsplit)")

				map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
				map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")

				map("n", "<leader>D", function()
					vim.diagnostic.open_float({ scope = "line" })
				end, "Line diagnostics")
				map("n", "<leader>d", function()
					vim.diagnostic.open_float({ scope = "cursor" })
				end, "Cursor diagnostics")
				map("n", "<leader>nd", function()
					vim.diagnostic.jump({ count = 1 })
				end, "Next diagnostic")
				map("n", "<leader>pd", function()
					vim.diagnostic.jump({ count = -1 })
				end, "Prev diagnostic")

				map("n", "K", vim.lsp.buf.hover, "Hover docs")

				-- telescope-backed LSP pickers
				map("n", "<leader>fd", builtin.lsp_definitions, "Find definitions")
				map("n", "<leader>fr", builtin.lsp_references, "Find references")
				map("n", "<leader>ft", builtin.lsp_type_definitions, "Find type definitions")
				map("n", "<leader>fs", builtin.lsp_document_symbols, "Document symbols")
				map("n", "<leader>fw", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")
				map("n", "<leader>fi", builtin.lsp_implementations, "Find implementations")

				-- VSCode-style + explicit format keybinds (efm provides formatting)
				map({ "n", "v" }, "<S-A-f>", function()
					vim.lsp.buf.format({ async = true })
				end, "Format buffer (VSCode-style)")
				map({ "n", "v" }, "<leader>cf", function()
					vim.lsp.buf.format({ async = true })
				end, "Format buffer")

				if client:supports_method("textDocument/codeAction", bufnr) then
					map("n", "<leader>oi", function()
						vim.lsp.buf.code_action({
							context = { only = { "source.organizeImports" }, diagnostics = {} },
							apply = true,
							bufnr = bufnr,
						})
						vim.defer_fn(function()
							vim.lsp.buf.format({ bufnr = bufnr })
						end, 50)
					end, "Organize imports")
				end
			end

			vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

			vim.keymap.set("n", "<leader>q", function()
				vim.diagnostic.setloclist({ open = true })
			end, { desc = "Open diagnostic list" })
			vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

			-- nvim 0.11 API: vim.lsp.config merges over nvim-lspconfig's
			-- shipped defaults; vim.lsp.enable activates the servers.
			vim.lsp.config('*', {
				capabilities = require('blink.cmp').get_lsp_capabilities(),
			})
			vim.lsp.config('lua_ls', {
				settings = {
					Lua = {
						diagnostics = { globals = { 'vim' } },
						telemetry = { enable = false },
					},
				},
			})
			vim.lsp.config('pyright', {})
			vim.lsp.config('ts_ls', {})

			do
				local selene = require('efmls-configs.linters.selene')
				local stylua = require('efmls-configs.formatters.stylua')
				local flake8 = require('efmls-configs.linters.flake8')
				local black = require('efmls-configs.formatters.black')
				local prettier_d = require('efmls-configs.formatters.prettier_d')
				local eslint_d = require('efmls-configs.linters.eslint_d')
				local fixjson = require('efmls-configs.formatters.fixjson')

				vim.lsp.config('efm', {
					filetypes = {
						'lua',
						'python',
						'javascript',
						'javascriptreact',
						'typescript',
						'typescriptreact',
						'json',
						'jsonc',
					},
					init_options = { documentFormatting = true },
					settings = {
						languages = {
							lua = { selene, stylua },
							python = { flake8, black },
							javascript = { eslint_d, prettier_d },
							javascriptreact = { eslint_d, prettier_d },
							typescript = { eslint_d, prettier_d },
							typescriptreact = { eslint_d, prettier_d },
							json = { fixjson },
							jsonc = { fixjson },
						},
					},
				})
			end

			vim.lsp.enable({ 'lua_ls', 'pyright', 'ts_ls', 'efm' })
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

vim.g.mapleader = " "

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

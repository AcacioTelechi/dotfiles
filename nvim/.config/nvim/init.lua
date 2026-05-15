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
}
local opts = {}

require("lazy").setup(plugins, opts)

require("catppuccin").setup()
vim.cmd.colorscheme("catppuccin")

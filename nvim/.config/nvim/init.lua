vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=bob:name",
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
	        -- optional but recommended
        	{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
	    }
	}
}
local opts = {}

require("lazy").setup(plugins, opts)

--Telescope: require lazily inside callbacks so it loads only after lazy.nvim installs it
vim.keymap.set('n', '<leader>ff', function() require('telescope.builtin').find_files() end, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', function() require('telescope.builtin').live_grep() end, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', function() require('telescope.builtin').buffers() end, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', function() require('telescope.builtin').help_tags() end, { desc = 'Telescope help tags' })

require("catppuccin").setup()
vim.cmd.colorscheme("catppuccin")

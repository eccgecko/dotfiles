-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Enable mouse in all modes
vim.opt.mouse = "a"

-- Enable more colours
vim.opt.termguicolors = true

-- Enable matching if/fi, do/done, etc. with %
-- vim.cmd("packadd! matchit")

-- Force OSC52 as the clipboard provider, bypassing auto-detection.
-- This ensures Neovim uses OSC52 escape sequences regardless of whether
-- other clipboard tools (xclip, pbcopy, etc.) are present on the system.
vim.g.clipboard = "osc52"

-- Route all yank/delete/put operations through the + register automatically,
-- so you don't have to prefix every yank with "+. Without this line, a plain
-- 'y' goes to the unnamed register and never triggers the OSC52 provider.
vim.o.clipboard = "unnamedplus"

-- Plugins
require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,        -- Load immediately at startup, not on demand
    priority = 1000,     -- Load before other plugins so colors are ready
    config = function()
      vim.cmd("colorscheme tokyonight")
    end,
  },
  {
    "andymass/vim-matchup",
    event = "BufReadPost",  -- Load when a file is opened
    config = function()
      -- Enable highlighting of matching keywords (if/fi, do/done, etc.)
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
})

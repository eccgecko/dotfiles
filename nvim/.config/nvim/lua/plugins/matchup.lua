return {
  -- disable built-in matchit and matchparen since vim-matchup supersedes them
  { "matchit", enabled = false },
  { "matchparen", enabled = false },

  -- add vim-matchup
  {
    "andymass/vim-matchup",
    ---@type matchup.Config
    opts = {
      matchparen = {
        offscreen = { method = "popup" },
      },
      treesitter = {
        stopline = 500,
      },
    },
  },

  -- enable treesitter-powered matching and quote tracking for vim-matchup
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      matchup = {
        enable = true,
        enable_quotes = true,
      },
    },
  },
}

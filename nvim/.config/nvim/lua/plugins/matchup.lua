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
}

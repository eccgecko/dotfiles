return {
  -- disable built-in matchit and matchparen since vim-matchup supersedes them
  { "matchit", enabled = false },
  { "matchparen", enabled = false },

  -- add vim-matchup
  {
    "andymass/vim-matchup",
    event = "BufReadPost",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
}

return {
  { "matchit", enabled = false },
  { "matchparen", enabled = false },

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

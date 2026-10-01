---@type LazySpec
return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      -- 17 ms is approximately 60 frames per second.
      time_interval = 17,

      -- Keep the animation quick and responsive instead of floaty.
      stiffness = 0.8,
      trailing_stiffness = 0.6,
      damping = 0.8,
      max_length = 20,
      distance_stop_animating = 0.1,
    },
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>pl"] = { "<Cmd>Lazy<CR>", desc = "Plugin manager" },
        },
      },
    },
  },
}

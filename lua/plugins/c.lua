---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = {
      treesitter = {
        ensure_installed = { "c" },
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    opts = {
      servers = { "clangd" },
    },
  },
}

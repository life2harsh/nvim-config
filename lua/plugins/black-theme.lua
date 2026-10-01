---@type LazySpec
return {
  {
    "AstroNvim/astrotheme",
    opts = {
      style = {
        transparent = false,
      },
      palettes = {
        astrodark = {
          ui = {
            base = "#000000",
            inactive_base = "#000000",
            tabline = "#000000",
            statusline = "#000000",
            tool = "#000000",
            float = "#000000",
            split = "#141414",
            current_line = "#080808",
            prompt = "#080808",
            highlight = "#101010",
            selection = "#1A1A1A",
            menu_selection = "#1A1A1A",
            border = "#262626",
          },
          term = {
            background = "#000000",
          },
        },
      },
    },
  },
  {
    "AstroNvim/astroui",
    opts = {
      colorscheme = "astrodark",
    },
  },
}

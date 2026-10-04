return {
  -- Disable LazyVim default colorscheme plugins
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },

  {
    "shaunsingh/nord.nvim",
    event = { "VeryLazy" },
    config = function()
      vim.g.nord_disable_background = true
      vim.g.nord_italic = false

      local function set_normal_mode_foreground()
        local cursor_line_nr = vim.api.nvim_get_hl(0, { name = "CursorLineNr", link = false })
        vim.api.nvim_set_hl(0, "NormalMode", { fg = cursor_line_nr.fg })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "nord",
        callback = set_normal_mode_foreground,
      })

      if vim.g.colors_name == "nord" then
        set_normal_mode_foreground()
      end
    end,
    on_highlights = function(hl, c)
      hl.TabLineFill = { bg = c.none }
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "nord",
    },
  },
}

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

      local function set_nord_highlights()
        local cursor_line_nr = vim.api.nvim_get_hl(0, { name = "CursorLineNr", link = false })
        vim.api.nvim_set_hl(0, "NormalMode", { fg = cursor_line_nr.fg })

        local colors = require("nord.colors")
        local dropbar_highlights = {
          -- Dropbar's highlight resets inherit StatusLine inside lualine_c.
          StatusLine = { fg = colors.nord4_gui, bg = colors.nord1_gui },
          StatusLineNC = { fg = colors.nord4_gui, bg = colors.nord1_gui },
          WinBar = { fg = colors.nord4_gui, bg = colors.none },
          WinBarNC = { fg = colors.nord3_gui_bright, bg = colors.none },
          DropBarIconUIPickPivot = { fg = colors.nord0_gui, bg = colors.nord13_gui, bold = true },
          DropBarCurrentContext = { bg = colors.nord2_gui, bold = true },
          DropBarHover = { bg = colors.nord1_gui },
          DropBarMenuCurrentContext = { bg = colors.nord2_gui, bold = true },
          DropBarMenuHoverEntry = { bg = colors.nord1_gui },
        }
        for group, highlight in pairs(dropbar_highlights) do
          vim.api.nvim_set_hl(0, group, highlight)
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "nord",
        callback = set_nord_highlights,
      })

      if vim.g.colors_name == "nord" then
        set_nord_highlights()
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

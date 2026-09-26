local bufferline = require("bufferline")

return {
  {
    "akinsho/bufferline.nvim",

    opts = function(_, opts)
      opts.options.always_show_bufferline = true

      opts.options.style_preset = {
        bufferline.style_preset.no_italic,
        bufferline.style_preset.minimal,
      }

      opts.options.separator_style = { "", "" }

      for _, offset in ipairs(opts.options.offsets or {}) do
        if offset.filetype == "snacks_layout_box" then
          offset.text = "Explorer"
          offset.highlight = "Directory"
          offset.text_align = "left"
          offset.separator = true
        end
      end
    end,
  },

  {
    "mawkler/modicator.nvim",
    event = "VeryLazy",

    init = function()
      vim.o.termguicolors = true
      vim.o.number = true
      vim.o.cursorline = true

      vim.o.cursorlineopt = "number"
    end,

    opts = {
      show_warnings = false,

      highlights = {
        defaults = {
          bold = false,
          italic = false,
        },

        use_cursorline_background = false,
      },

      integration = {
        lualine = {
          enabled = true,
          mode_section = nil,
          highlight = "bg",
        },
      },
    },

    config = function(_, opts)
      local modicator = require("modicator")
      modicator.setup(opts)

      local function set_mode_backgrounds()
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
        local text_color = normal.bg or 0x2e3440

        for _, mode in ipairs(modicator.modes) do
          local name = mode .. "Mode"
          local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
          if hl.fg then
            if mode == "Normal" then
              hl.bg = nil
            else
              hl.bg = hl.fg
              hl.fg = text_color
            end
            hl.reverse = nil
            vim.api.nvim_set_hl(0, name, hl)
          end
        end

        vim.api.nvim_set_hl(0, "CursorLineSign", { link = "CursorLineNr" })
        modicator.set_cursor_line_highlight(modicator.hl_name_from_mode(vim.api.nvim_get_mode().mode))
      end

      set_mode_backgrounds()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_mode_backgrounds })
    end,
  },
}

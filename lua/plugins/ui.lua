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
  },
}

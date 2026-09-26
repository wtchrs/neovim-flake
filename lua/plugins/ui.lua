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
}

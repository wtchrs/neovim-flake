local bufferline = require("bufferline")

return {
  {
    "Bekaboo/dropbar.nvim",

    opts = {
      sources = {
        path = {
          relative_to = function(buf)
            return LazyVim.root.get({ buf = buf })
          end,
        },
      },
    },

    config = function(_, opts)
      require("dropbar").setup(opts)

      local dropbar_api = require("dropbar.api")
      vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
      vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
      vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
    end,
  },

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

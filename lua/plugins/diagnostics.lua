return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,

    opts = {
      preset = "modern",

      transparent_bg = false,
      transparent_cursorline = false,

      options = {
        show_source = {
          enabled = false,
          if_many = true,
        },

        show_code = true,

        throttle = 20,

        multilines = {
          enabled = true,
          always_show = true,
          trim_whitespaces = true,
          severity = {
            vim.diagnostic.severity.ERROR,
          },
        },

        show_all_diags_on_cursorline = true,

        show_related = {
          enabled = true,
          max_count = 2,
        },

        enable_on_insert = false,
        enable_on_select = false,

        overflow = {
          mode = "wrap",
          padding = 0,
        },

        add_messages = {
          messages = true,
          display_count = false,
          show_multiple_glyphs = true,
        },

        override_open_float = true,

        virt_texts = {
          priority = 2048,
        },
      },
    },
  },
}

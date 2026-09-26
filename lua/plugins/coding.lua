return {
  {
    "xzbdmw/colorful-menu.nvim",
    opts = {
      ls = {
        lua_ls = {
          arguments_hl = "@comment",
        },
        gopls = {
          align_type_to_right = true,
          preserve_type_when_truncate = true,
        },
        ts_ls = {
          extra_info_hl = "@comment",
        },
        vtsls = {
          extra_info_hl = "@comment",
        },
        ["rust-analyzer"] = {
          extra_info_hl = "@comment",
          align_type_to_right = true,
          preserve_type_when_truncate = true,
        },
        clangd = {
          extra_info_hl = "@comment",
          align_type_to_right = true,
          preserve_type_when_truncate = true,
        },
      },
    },
  },

  {
    "saghen/blink.cmp",
    lazy = false,

    dependencies = {
      "xzbdmw/colorful-menu.nvim",
    },

    opts = function(_, opts)
      local draw = opts.completion.menu.draw

      draw.columns = {
        { "kind_icon" },
        { "label", gap = 1 },
      }

      draw.components = draw.components or {}

      draw.components.label = {
        text = function(ctx)
          return require("colorful-menu").blink_components_text(ctx)
        end,
        highlight = function(ctx)
          return require("colorful-menu").blink_components_highlight(ctx)
        end,
      }
    end,
  },

  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      views = {
        hover = {
          border = {
            padding = { 0, 1 },
          },
        },
      },
    },
  },
}

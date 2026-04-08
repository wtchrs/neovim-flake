return {
  {
    "saghen/blink.cmp",
    lazy = false,
    opts = {
      completion = {
        menu = {
          border = "rounded",
        },
        documentation = {
          window = {
            border = "rounded",
          },
        },
      },
    },
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

  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Load all default LSP configs
      local s = {}
      for _, f in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
        table.insert(s, vim.fn.fnamemodify(f, ":t:r"))
      end
      vim.lsp.enable(s)
    end,
  },
}

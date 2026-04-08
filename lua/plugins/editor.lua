return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
  },

  {
    "folke/which-key.nvim",
    opts = {
      win = {
        border = "rounded",
      },
    },
  },

  {
    "snacks.nvim",
    opts = {
      picker = {
        sources = { explorer = { layout = { auto_hide = { "input" } } } },
        win = { input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } } },
      },
      scroll = { enabled = false },
    },
  },

  {
    "dstein64/vim-startuptime",
  },
}

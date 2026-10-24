return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      {
        "<leader>gD",
        "<cmd>CodeDiff<cr>",
        desc = "Review Git changes",
      },
    },
    opts = {
      highlights = {
        line_insert = "#40494b",
        line_delete = "#443b46",
        char_insert = "#515d57",
        char_delete = "#5a424d",
      },
      diff = {
        layout = "side-by-side",
      },
      explorer = {
        auto_refresh = true,
      },
    },
  },
}

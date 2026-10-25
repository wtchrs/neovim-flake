return {
  {
    -- IME integration
    "keaising/im-select.nvim",
    config = function()
      require("im_select").setup({
        set_default_events = { "InsertLeave", "CmdlineLeave", "VimEnter", "FocusGained" },
      })
    end,
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
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            icons = { git = { ignored = "" } },
            formatters = { file = { git_status_hl = true } },
            layout = {
              auto_hide = { "input" },
              cycle = false,
            },
            format = function(item, picker)
              local format = require("snacks.picker.format")
              local ret = format.file(item, picker)
              -- Ignored directories pass their ignored state down to their children.
              -- Open directories can have no status even when they are ignored.
              if not item.status then
                local node = item
                while node do
                  if node.ignored then
                    vim.list_extend(ret, format.file_git_status({ status = "!!" }, picker))
                    break
                  end
                  node = node.parent
                end
              end
              -- Porcelain XY: index changes first, working-tree changes second.
              -- Keep the staged icon and append the unstaged status for mixed files.
              if not item.dir and item.status and item.status:match("^[MADRCT][MADRCT]$") then
                local status = require("snacks.picker.source.git").git_status(item.status)
                if not status.unmerged then
                  local unstaged = format.file_git_status({ status = " " .. item.status:sub(2, 2) }, picker)
                  for _, chunk in ipairs(ret) do
                    if chunk.virt_text and chunk.virt_text[1][2] == "SnacksPickerGitStatusStaged" then
                      vim.list_extend(chunk.virt_text, unstaged[1].virt_text)
                      break
                    end
                  end
                end
              end
              return ret
            end,
          },
        },
        win = { input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } } },
      },
      scroll = { enabled = false },
    },
  },

  {
    "RaafatTurki/hex.nvim",
    config = function()
      require("hex").setup()
    end,
  },

  {
    "OXY2DEV/markview.nvim",
    -- Markview handles deferred rendering internally.
    lazy = false,
    dependencies = { "nvim-mini/mini.icons" },

    opts = {
      preview = {
        enable = false,
        map_gx = false,
        icon_provider = "mini",
        filetypes = { "markdown", "typst" },

        modes = { "n", "no", "c" },
      },
    },

    keys = {
      { "<leader>mp", "<cmd>Markview toggle<cr>", ft = "markdown", desc = "Toggle Markdown Preview" },
      { "<leader>ms", "<cmd>Markview splitToggle<cr>", ft = "markdown", desc = "Toggle Markdown Split Preview" },
      { "<leader>mh", "<cmd>Markview hybridToggle<cr>", ft = "markdown", desc = "Toggle Markdown Hybrid Mode" },
    },
  },

  { "dstein64/vim-startuptime" },
}

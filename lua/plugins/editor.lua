local function navigate(direction, pane_flag, edge, window_command)
  -- Floating picker windows must navigate relative to their containing split.
  local window = vim.api.nvim_get_current_win()
  local config = vim.api.nvim_win_get_config(window)
  while config.relative == "win" do
    window = config.win
    config = vim.api.nvim_win_get_config(window)
  end

  local neighbor = vim.api.nvim_win_call(window, function()
    return vim.fn.win_getid(vim.fn.winnr(direction))
  end)
  if neighbor ~= window then
    vim.api.nvim_set_current_win(neighbor)
    return
  end

  if not vim.env.TMUX or not vim.env.TMUX_PANE then
    return
  end

  if not window_command then
    vim.fn.system({ "tmux", "select-pane", "-t", vim.env.TMUX_PANE, pane_flag })
    return
  end

  vim.fn.system({
    "tmux",
    "if-shell",
    "-F",
    "-t",
    vim.env.TMUX_PANE,
    "#{pane_at_" .. edge .. "}",
    window_command,
    "select-pane -t " .. vim.env.TMUX_PANE .. " " .. pane_flag,
  })
end

return {
  {
    -- TMUX integration
    "christoomey/vim-tmux-navigator",
    init = function()
      -- The plugin's defaults would overwrite the custom Lazy key mappings on load.
      vim.g.tmux_navigator_no_mappings = 1
    end,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      {
        "<C-h>",
        function()
          navigate("h", "-L", "left", "previous-window")
        end,
      },
      {
        "<C-j>",
        function()
          navigate("j", "-D")
        end,
      },
      {
        "<C-k>",
        function()
          navigate("k", "-U")
        end,
      },
      {
        "<C-l>",
        function()
          navigate("l", "-R", "right", "next-window")
        end,
      },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
    },
  },

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
            win = {
              list = {
                keys = {
                  ["<c-j>"] = false,
                  ["<c-k>"] = false,
                },
              },
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

  { "dstein64/vim-startuptime" },
}

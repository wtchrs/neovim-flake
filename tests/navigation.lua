vim.schedule(function()
  local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "vim-tmux-navigator" } })
    local plugin = require("lazy.core.config").plugins["vim-tmux-navigator"]
    local keys = require("lazy.core.plugin").values(plugin, "keys", false)

    for _, key in ipairs(keys) do
      if key[1] == "<C-h>" or key[1] == "<C-l>" then
        local mapping = vim.fn.maparg(key[1], "n", false, true)
        assert(type(key[2]) == "function", key[1] .. " must use custom pane/window navigation")
        assert(mapping.callback == key[2], key[1] .. " was overwritten during plugin loading")
      end
    end

    vim.env.TMUX = nil
    vim.env.TMUX_PANE = nil

    local function press(key)
      vim.v.errmsg = ""
      vim.api.nvim_feedkeys(vim.keycode(key), "xt", false)
      assert(vim.v.errmsg == "", key .. ": " .. vim.v.errmsg)
    end

    vim.cmd("only")
    vim.cmd("leftabove vsplit")
    local left_window = vim.api.nvim_get_current_win()
    press("<C-l>")
    assert(vim.api.nvim_get_current_win() ~= left_window, "Ctrl+l must move to the right split")
    press("<C-h>")
    assert(vim.api.nvim_get_current_win() == left_window, "Ctrl+h must move to the left split")
    vim.cmd("only")
    press("<C-h>")
    press("<C-l>")
    assert(vim.api.nvim_get_current_win() == left_window, "Standalone Neovim must stay at the split edge")

    vim.cmd("leftabove split")
    local top_window = vim.api.nvim_get_current_win()
    press("<C-j>")
    local bottom_window = vim.api.nvim_get_current_win()
    assert(bottom_window ~= top_window, "Ctrl+j must move to the bottom split")
    press("<C-k>")
    assert(vim.api.nvim_get_current_win() == top_window, "Ctrl+k must move to the top split")
    press("<C-\\>")
    assert(vim.api.nvim_get_current_win() == bottom_window, "Ctrl+backslash must select the previous split")
    press("<C-\\>")
    assert(vim.api.nvim_get_current_win() == top_window, "Ctrl+backslash must toggle between splits")
    vim.cmd("only")
    press("<C-j>")
    press("<C-k>")
    assert(vim.api.nvim_get_current_win() == top_window, "Standalone Neovim must stay at the vertical split edge")

    vim.o.columns = 160
    vim.o.lines = 48
    local editor_window = vim.api.nvim_get_current_win()
    local explorer_positions = {
      { position = "left", edge_key = "<C-h>", editor_key = "<C-l>" },
      { position = "right", edge_key = "<C-l>", editor_key = "<C-h>" },
    }
    for _, case in ipairs(explorer_positions) do
      local picker = Snacks.picker.explorer({ layout = { layout = { position = case.position } } })
      assert(
        vim.wait(3000, function()
          return picker.list.win:valid()
        end),
        "Explorer must open"
      )
      picker:focus("list")
      local explorer_window = vim.api.nvim_get_current_win()
      press(case.edge_key)
      assert(vim.api.nvim_get_current_win() == explorer_window, "Explorer must stay at its outer edge without tmux")
      press(case.editor_key)
      assert(vim.api.nvim_get_current_win() == editor_window, "Explorer must navigate inward to the editor")
      press(case.edge_key)
      assert(vim.api.nvim_get_current_win() == explorer_window, "Editor must navigate back into the explorer")
      picker:close()
    end

    local explorer_cwd = vim.fn.tempname()
    vim.fn.mkdir(explorer_cwd, "p")
    for _, name in ipairs({ "first", "second", "third" }) do
      vim.fn.writefile({}, explorer_cwd .. "/" .. name)
    end
    local vertical_neighbors = {
      { split = "botright split", key = "<C-j>" },
      { split = "topleft split", key = "<C-k>" },
    }
    for _, case in ipairs(vertical_neighbors) do
      -- Background status refreshes can reset the selected row during key input.
      local picker = Snacks.picker.explorer({
        cwd = explorer_cwd,
        follow_file = false,
        watch = false,
        diagnostics = false,
        git_status = false,
      })
      assert(
        vim.wait(3000, function()
          return picker.list.win:valid() and picker.list:count() >= 3
        end),
        "Explorer must open"
      )
      vim.api.nvim_set_current_win(editor_window)
      vim.cmd(case.split)
      local neighbor_window = vim.api.nvim_get_current_win()
      picker:focus("list")
      press(case.key)
      assert(vim.api.nvim_get_current_win() == neighbor_window, "Explorer list must navigate to the vertical split")
      for _, mode_prefix in ipairs({ "", "i" }) do
        picker:focus("input", { show = true })
        assert(
          vim.wait(1000, function()
            return picker.input.win:valid()
              and vim.api.nvim_get_current_win() == picker.input.win.win
              and picker.list:count() >= 3
              and not picker:is_active()
          end),
          "Search input must receive focus"
        )
        vim.cmd.stopinsert()
        local input_window = vim.api.nvim_get_current_win()
        picker.list:move(2, true)
        press(mode_prefix .. "<C-j>")
        assert(picker.list.cursor == 3, "Search input Ctrl+j must move down the list")
        assert(vim.api.nvim_get_current_win() == input_window, "Search input Ctrl+j must preserve input focus")
        press(mode_prefix .. "<C-k>")
        assert(picker.list.cursor == 2, "Search input Ctrl+k must move up the list")
        assert(vim.api.nvim_get_current_win() == input_window, "Search input Ctrl+k must preserve input focus")
      end
      picker:close()
      vim.api.nvim_set_current_win(editor_window)
      vim.cmd("only")
    end
    vim.fn.delete(explorer_cwd, "rf")
    print("Navigation: explorer list focus movement and search input list movement passed")
  end, debug.traceback)

  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)

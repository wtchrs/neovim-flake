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
    print("Navigation: mappings survive plugin loading; hjkl and previous-split key input passed")
  end, debug.traceback)

  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)

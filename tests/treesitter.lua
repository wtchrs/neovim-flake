-- Run against the wrapped package with empty XDG data/cache/state directories.
vim.schedule(function()
  local ok, err = xpcall(function()
    local plugin = require("lazy.core.config").plugins["nvim-treesitter"]
    local opts = require("lazy.core.plugin").values(plugin, "opts", false)
    assert(#opts.ensure_installed == 0, "LazyVim/extras must not request parser installation")
    assert(opts.install_dir:match("^/nix/store/"), "Treesitter must use the Nix runtime")

    require("lazy").load({ plugins = { "nvim-treesitter" } })

    local installed = require("nvim-treesitter").get_installed("parsers")
    for _, lang in ipairs({ "lua", "nix", "python", "rust", "go", "typescript", "tsx", "markdown" }) do
      assert(vim.tbl_contains(installed, lang), lang .. " parser is missing")
      assert(LazyVim.treesitter.have(lang), "LazyVim does not recognize " .. lang)
    end

    local fixtures = {
      lua = { "local answer = 42", "return answer" },
      nix = { "{", "  answer = 42;", "}" },
    }
    for lang, lines in pairs(fixtures) do
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].filetype = lang

      local parser = vim.treesitter.get_parser(buf, lang)
      local tree = parser:parse()[1]
      assert(not tree:root():has_error(), lang .. " fixture failed to parse")
      assert(vim.treesitter.highlighter.active[buf], lang .. " highlighting did not start")

      local query = assert(vim.treesitter.query.get(lang, "highlights"))
      local captures = 0
      for _ in query:iter_captures(tree:root(), buf, 0, -1) do
        captures = captures + 1
      end
      assert(captures > 0, lang .. " highlight query produced no captures")

      local paths = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", true)
      assert(#paths > 0 and paths[1]:match("^/nix/store/"), lang .. " parser is not loaded from Nix")
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    local data = vim.fn.stdpath("data")
    assert(vim.fn.isdirectory(data .. "/site/parser") == 0, "Writable parser directory was created")
    assert(vim.fn.isdirectory(data .. "/site/queries") == 0, "Writable query directory was created")
    local messages = vim.api.nvim_exec2("messages", { output = true }).output
    assert(not messages:find("Downloading tree%-sitter"), "Runtime parser download was attempted")
    print("Treesitter: Nix parsers, queries, and automatic highlighting passed")
  end, debug.traceback)

  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)

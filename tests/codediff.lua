-- Run against the wrapped package with empty XDG data/cache/state directories.
vim.schedule(function()
  local watcher
  local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "codediff.nvim" } })

    local binary = vim.fn.exepath("codediff-watcher")
    assert(binary:match("^/nix/store/"), "codediff-watcher is missing from the wrapped PATH")
    local installer = require("codediff.core.installer.watcher")
    local resolved
    installer.ensure(function(path, install_error)
      assert(not install_error, install_error)
      resolved = path
    end)
    assert(resolved == binary, "CodeDiff did not select the bundled watcher")

    local repository = vim.fn.tempname()
    vim.fn.mkdir(repository, "p")
    local fixture = repository .. "/tracked.txt"
    vim.fn.writefile({ "before" }, fixture)
    local commands = {
      { "git", "init", "--quiet", repository },
      { "git", "-C", repository, "add", "tracked.txt" },
      {
        "git",
        "-C",
        repository,
        "-c",
        "user.name=Test",
        "-c",
        "user.email=test@example.com",
        "commit",
        "--quiet",
        "-m",
        "fixture",
      },
    }
    for _, command in ipairs(commands) do
      local result = vim.system(command, { text = true }):wait()
      assert(result.code == 0, result.stderr)
    end

    watcher = require("codediff.core.watcher")
    local ready
    local refreshed = false
    local watcher_error
    local unsubscribe = watcher.subscribe(repository, {
      on_ready = function(message)
        ready = message
      end,
      on_refresh = function(message)
        if message.worktree then
          refreshed = true
        end
      end,
      on_error = function(message)
        watcher_error = message
      end,
    })

    assert(
      vim.wait(12000, function()
        return ready ~= nil or watcher_error ~= nil
      end),
      "codediff-watcher did not become ready"
    )
    assert(not watcher_error, watcher_error)
    assert(ready.binary_version == installer.VERSION, "Bundled watcher version does not match the plugin")

    vim.fn.writefile({ "after" }, fixture)
    assert(
      vim.wait(5000, function()
        return refreshed or watcher_error ~= nil
      end),
      "codediff-watcher did not detect a worktree change"
    )
    assert(not watcher_error, watcher_error)
    unsubscribe()
    print("CodeDiff: bundled watcher discovery, startup, and worktree refresh passed")
  end, debug.traceback)

  if watcher then
    watcher.stop_all()
  end
  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)

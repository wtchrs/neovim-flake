-- Run with nvim --headless -u NONE -i NONE '+lua dofile("tests/lintinfo.lua")'.
vim.opt.runtimepath:prepend(vim.env.LINTINFO_RUNTIME or (vim.fn.getcwd() .. "/local/lintinfo.nvim"))

local lintinfo = require("lintinfo")
local root = vim.fn.tempname()
local dirs = {}
for _, name in ipairs({ "global", "tab", "window", "linter" }) do
  dirs[name] = root .. "/" .. name
  vim.fn.mkdir(dirs[name], "p")
end

local function snapshot()
  local state = { global = vim.fn.getcwd(-1, -1), tabs = {}, windows = {} }
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tab)
    state.tabs[tab] = { cwd = vim.fn.getcwd(-1, nr), scope = vim.fn.haslocaldir(-1, nr) }
    for index, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      state.windows[win] = { cwd = vim.fn.getcwd(index, nr), scope = vim.fn.haslocaldir(index, nr) }
    end
  end
  return state
end

local failures = {}
local count = 0
for _, collector in ipairs({ "collect_active", "collect_all_configured" }) do
  for _, scope in ipairs({ "global", "tab", "window" }) do
    for _, raises in ipairs({ false, true }) do
      for _, same_cwd in ipairs({ false, true }) do
        local label = ("%s / %s / error=%s / same_cwd=%s"):format(collector, scope, raises, same_cwd)
        local ok, err = xpcall(function()
          vim.cmd("silent tabonly!")
          vim.cmd("silent only!")
          vim.cmd.cd(dirs.global)
          -- Observe both another window and another tab during restoration.
          vim.cmd("vnew")
          vim.cmd("tabnew")
          vim.cmd("tabprevious")
          if scope ~= "global" then
            vim.cmd.tcd(dirs.tab)
          end
          if scope == "window" then
            vim.cmd.lcd(dirs.window)
          end
          local before = snapshot()
          local target = same_cwd and vim.fn.getcwd() or dirs.linter
          local calls = 0
          local dir_events = 0
          local autocmd = vim.api.nvim_create_autocmd({ "DirChanged", "DirChangedPre" }, {
            callback = function()
              dir_events = dir_events + 1
            end,
          })
          local bin = root .. "/missing-executable"
          package.loaded.lint = {
            linters_by_ft = { lua = { "fixture" } },
            linters = {
              fixture = {
                cwd = target,
                cmd = function(...)
                  calls = calls + 1
                  assert(select("#", ...) == 0, "cmd received arguments")
                  assert(vim.fn.getcwd() == target, "cmd evaluated outside linter cwd")
                  if raises then
                    error("fixture command failed")
                  end
                  return bin
                end,
              },
            },
          }
          vim.bo.filetype = "lua"
          local collected, info = pcall(lintinfo[collector])
          vim.api.nvim_del_autocmd(autocmd)
          -- Check state even when collection throws (the old unpack bug).
          local after = snapshot()
          assert(
            vim.deep_equal(before, after),
            "cwd path or scope changed: before=" .. vim.inspect(before) .. " after=" .. vim.inspect(after)
          )
          assert(collected, tostring(info))
          assert(info.ok, info.error)
          assert(calls == 1, "cmd was not evaluated exactly once")
          assert(dir_events == 0, "cwd evaluation emitted directory autocmds")
          local status = info.status.fixture
          if raises then
            assert(status.kind == "cmd_error", "cmd error was not collected")
            assert(status.error:find("fixture command failed", 1, true), "cmd error was lost")
          else
            assert(status.kind == "missing", "missing executable was not reported")
            assert(status.cmd == bin and status.bin == bin, "cmd return value was lost")
          end
        end, debug.traceback)
        count = count + 1
        if not ok then
          failures[#failures + 1] = label .. "\n" .. err
        end
      end
    end
  end
end

vim.cmd.cd(vim.env.TMPDIR or "/tmp")
vim.fn.delete(root, "rf")
if #failures > 0 then
  vim.api.nvim_err_writeln(table.concat(failures, "\n\n"))
  vim.cmd("cquit 1")
else
  print(("LintInfo: %d command evaluation and cwd restoration cases passed"):format(count))
  vim.cmd("qa!")
end

-- Start the bundled jdtls through LazyVim's Java extra and verify the Nix-provided integration.
vim.schedule(function()
  local ok, err = xpcall(function()
    local plugins = require("lazy.core.config").plugins
    assert(plugins["nvim-jdtls"], "nvim-jdtls is missing")

    local jdtls_path = vim.fn.exepath("jdtls")
    assert(jdtls_path:match("^/nix/store/"), "jdtls must come from Nix: " .. jdtls_path)

    -- An unbuilt project keeps the server offline; Maven or Gradle imports would download.
    local fixture = vim.fn.tempname()
    vim.fn.mkdir(fixture .. "/.git", "p")
    vim.fn.mkdir(fixture .. "/src", "p")
    local filename = fixture .. "/src/Main.java"
    vim.fn.writefile({ "public class Main {", "  public static void main(String[] args) {}", "}" }, filename)
    vim.cmd.edit(vim.fn.fnameescape(filename))
    local buf = vim.api.nvim_get_current_buf()

    local client
    local initialized = vim.wait(45000, function()
      client = vim.lsp.get_clients({ name = "jdtls", bufnr = buf })[1]
      return client ~= nil and client.initialized
    end, 200)
    assert(initialized, "jdtls failed to initialize: " .. vim.api.nvim_exec2("messages", { output = true }).output)
    assert(client.config.root_dir == fixture, "Unexpected jdtls root: " .. tostring(client.config.root_dir))
    assert(client.server_capabilities.completionProvider, "jdtls did not advertise completion support")
    assert(
      client.config.capabilities.textDocument.completion.completionItem.snippetSupport,
      "blink.cmp capabilities missing"
    )

    local lombok_arg = "--jvm-arg=-javaagent:" .. vim.g.jdtls_lombok_jar
    assert(vim.tbl_contains(client.config.cmd, lombok_arg), "Lombok agent missing from jdtls command")
    assert(vim.fn.filereadable(vim.g.jdtls_lombok_jar) == 1, "Bundled Lombok jar is missing")

    local bundles = client.config.init_options.bundles
    local has_debug, has_test = false, false
    for _, jar in ipairs(bundles) do
      assert(jar:match("^/nix/store/") and vim.fn.filereadable(jar) == 1, "Unreadable bundle: " .. jar)
      local name = vim.fs.basename(jar)
      assert(name ~= "jacocoagent.jar", "jacocoagent.jar must not be bundled")
      assert(name ~= "com.microsoft.java.test.runner-jar-with-dependencies.jar", "Test runner jar must not be bundled")
      if name:match("^com%.microsoft%.java%.debug%.plugin%-") then
        has_debug = true
      end
      if name:match("^com%.microsoft%.java%.test%.plugin%-") then
        has_test = true
      end
    end
    assert(has_debug, "Java debug bundle missing")
    assert(has_test, "Java test bundle missing")

    local dap = require("dap")
    assert(dap.adapters.java, "jdtls DAP adapter missing")
    for _, lhs in ipairs({ "<leader>co", "<leader>tt", "<leader>tr", "<leader>tT" }) do
      assert(vim.fn.maparg(lhs, "n", false, true).buffer == 1, lhs .. " keymap missing")
    end

    client:stop(true)
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.fn.delete(fixture, "rf")
    print("Java: jdtls startup, Lombok, debug/test bundles, DAP, and keymaps passed")
  end, debug.traceback)

  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)

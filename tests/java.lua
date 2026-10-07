-- Verify the packaged LazyVim integration without accepting JetBrains' EULA.
vim.schedule(function()
  local ok, err = xpcall(function()
    local plugins = require("lazy.core.config").plugins
    assert(not plugins["nvim-jdtls"], "nvim-jdtls must be disabled")
    assert(plugins["nvim-intellij-lsp"], "IntelliJ client plugin is missing")

    require("lazy").load({ plugins = { "nvim-lspconfig" } })
    local lsp_opts = require("lazy.core.plugin").values(plugins["nvim-lspconfig"], "opts", false)
    assert(lsp_opts.servers.jdtls.enabled == false, "LazyVim must not enable jdtls")
    assert(not vim.lsp.is_enabled("jdtls"), "jdtls was enabled")
    assert(vim.lsp.is_enabled("intellij"), "IntelliJ LSP was not enabled")

    local config = vim.lsp.config.intellij
    assert(vim.deep_equal(config.filetypes, { "java" }), "Unexpected IntelliJ filetypes")
    assert(config.capabilities.textDocument.completion.completionItem.snippetSupport, "blink.cmp capabilities missing")
    assert(config.handlers["workspace/configuration"], "JetBrains settings handler missing")
    assert(config.on_init and config.before_init, "JetBrains initialization hooks missing")
    assert(vim.fn.exists(":IntellijAcceptEula") == 2, "EULA command missing")
    assert(vim.fn.exists(":IntellijOrganizeImports") == 2, "Organize imports command missing")

    local dap = require("dap")
    assert(dap.adapters.intellij, "IntelliJ DAP adapter missing")
    assert(not dap.adapters.java, "jdtls DAP adapter should not be registered")
    assert(#dap.configurations.java > 0, "IntelliJ Java debug configurations missing")
    for _, debug_config in ipairs(dap.configurations.java) do
      assert(debug_config.type == "intellij", "Java debug configuration uses another adapter")
    end

    local server = assert(require("intellij-lsp.server").find())
    assert(server:match("^/nix/store/"), "Server must come from Nix")
    local root = vim.fs.dirname(vim.fs.dirname(server))
    assert(vim.fn.filereadable(root .. "/EULA.txt") == 1, "Bundled EULA is missing")
    local help = vim.system({ server, "--help" }, { text = true }):wait(20000)
    assert(help.code == 0, "Native server failed to launch: " .. (help.stderr or ""))
    assert((help.stdout or ""):find("%-%-stdio"), "Server does not advertise stdio LSP")

    local opts = require("intellij-lsp").options()
    assert(not opts.accept_eula, "EULA must not be accepted automatically")
    assert(opts.inlay_hints == "manual", "LazyVim must own hint visibility")

    local fixture = vim.fn.tempname()
    vim.fn.mkdir(fixture .. "/module/src", "p")
    vim.fn.writefile({}, fixture .. "/settings.gradle")
    vim.fn.writefile({}, fixture .. "/module/build.gradle")
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, fixture .. "/module/src/Main.java")

    -- Exercise only root selection; do not launch or license the server.
    local eula = require("intellij-lsp.eula")
    assert(not eula.accepted(server), "Fresh data must require EULA acceptance")
    local accepted = eula.accepted
    local selected_root
    eula.accepted = function()
      return true
    end
    local resolved, resolve_err = pcall(config.root_dir, buf, function(dir)
      selected_root = dir
    end)
    eula.accepted = accepted
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.fn.delete(fixture, "rf")
    assert(resolved, resolve_err)
    assert(
      selected_root == fixture,
      "Gradle module must resolve to the workspace root: "
        .. vim.inspect({ expected = fixture, actual = selected_root })
    )
    assert(#vim.lsp.get_clients({ name = "jdtls" }) == 0, "jdtls client was started")
    print("Java: IntelliJ selection, capabilities, DAP, roots, and native startup passed")
  end, debug.traceback)

  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)

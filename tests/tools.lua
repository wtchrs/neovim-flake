-- Exercise the wrapper with a minimal PATH, then with external tool fixtures.
vim.schedule(function()
  local ok, err = xpcall(function()
    local external_bin = vim.env.TOOLS_EXTERNAL_BIN
    local commands = {
      "git",
      "gcc",
      "make",
      "cmake",
      "ctest",
      "ninja",
      "go",
      "rustc",
      "cargo",
      "clippy-driver",
      "rustfmt",
      "python3",
      "node",
      "javac",
      "tsx",
      "astro-ls",
      "awk-language-server",
      "clangd",
      "neocmakelsp",
      "docker-langserver",
      "docker-compose-langserver",
      "gopls",
      "nil",
      "lua-language-server",
      "pyright-langserver",
      "ruff",
      "rust-analyzer",
      "tailwindcss-language-server",
      "vtsls",
      "vscode-json-language-server",
      "tinymist",
      "yaml-language-server",
      "intellij-server",
      "stylua",
      "nixfmt",
      "shfmt",
      "fish",
      "fish_indent",
      "goimports",
      "gofumpt",
      "typstyle",
      "statix",
      "golangci-lint",
      "hadolint",
      "cmakelint",
      "dlv",
      "debugpy-adapter",
      "codelldb",
      "js-debug-adapter",
    }
    for _, command in ipairs(commands) do
      assert(vim.fn.executable(command) == 1, "Missing bundled command: " .. command)
    end

    local overridden = {
      "git",
      "gcc",
      "make",
      "cmake",
      "nil",
      "stylua",
      "statix",
      "pyright-langserver",
      "dlv",
      "codelldb",
      "js-debug-adapter",
      "intellij-server",
      "javac",
    }
    for _, command in ipairs(overridden) do
      local path = vim.fn.exepath(command)
      if external_bin then
        assert(path == external_bin .. "/" .. command, command .. " did not prefer the external tool: " .. path)
      else
        assert(path:match("^/nix/store/"), command .. " did not use the bundled fallback: " .. path)
      end
    end
    for _, command in ipairs({ "rg", "fd", "xxd", "tree-sitter" }) do
      local path = vim.fn.exepath(command)
      assert(path:match("^/nix/store/"), command .. " is not bundled")
      assert(not external_bin or path ~= external_bin .. "/" .. command, command .. " used the external fixture")
    end

    require("lazy").load({ plugins = { "conform.nvim", "nvim-lspconfig" } })
    local conform = require("conform")
    for _, name in ipairs({ "stylua", "nixfmt", "shfmt", "goimports", "gofumpt", "typstyle" }) do
      local info = conform.get_formatter_info(name)
      assert(info.available, name .. " is unavailable: " .. tostring(info.available_msg))
    end
    assert(vim.fn.exepath(conform.get_formatter_info("stylua").command) == vim.fn.exepath("stylua"))

    require("conform.health").show_window()
    local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    assert(report:find(vim.fn.exepath("stylua"), 1, true), "ConformInfo did not display the selected formatter path")
    vim.api.nvim_win_close(0, true)

    local plugins = require("lazy.core.config").plugins
    local lsp_opts = require("lazy.core.plugin").values(plugins["nvim-lspconfig"], "opts", false)
    for _, name in ipairs({ "astro", "jsonls" }) do
      assert(lsp_opts.servers[name].mason == false, name .. " must use the bundled server")
    end
    local astro_plugin
    for _, plugin in ipairs(lsp_opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins) do
      if plugin.name == "@astrojs/ts-plugin" then
        astro_plugin = plugin
      end
    end
    assert(astro_plugin and astro_plugin.location:match("^/nix/store/"), "Astro plugin must use the Nix path")
    assert(vim.fn.filereadable(astro_plugin.location .. "/package.json") == 1, "Astro TypeScript plugin is missing")
    assert(
      LazyVim.get_pkg_path("astro-language-server", "/node_modules/@astrojs/ts-plugin") == astro_plugin.location,
      "Astro package lookup still uses Mason"
    )

    local intellij_plugin = plugins["nvim-intellij-lsp"]
    local intellij = require("intellij-lsp")
    local server = require("intellij-lsp.server")
    local original_opts = vim.deepcopy(intellij.options())
    local cached_server = require("intellij-lsp.install").install_dir("999.0.0")
    vim.fn.mkdir(cached_server .. "/bin", "p")
    vim.fn.writefile({ "#!/bin/sh", "exit 0" }, cached_server .. "/bin/intellij-server")
    assert(vim.fn.setfperm(cached_server .. "/bin/intellij-server", "rwxr-xr-x") == 1)
    assert(server.find() == vim.fn.resolve(vim.fn.exepath("intellij-server")), "IntelliJ did not follow PATH selection")
    local javac_home = vim.fs.dirname(vim.fs.dirname(vim.fn.resolve(vim.fn.exepath("javac"))))
    assert(original_opts.jdk == javac_home, "IntelliJ did not select the PATH JDK")
    assert(vim.env.INTELLIJ_SERVER_DIR == nil, "Wrapper set INTELLIJ_SERVER_DIR")
    assert(vim.env.JAVA_HOME == nil, "Wrapper set JAVA_HOME")

    local fixture = vim.fn.tempname()
    for _, name in ipairs({ "env", "explicit", "project-jdk" }) do
      vim.fn.mkdir(fixture .. "/" .. name .. "/bin", "p")
      for _, command in ipairs({ "intellij-server", "javac" }) do
        local executable = fixture .. "/" .. name .. "/bin/" .. command
        vim.fn.writefile({ "#!/bin/sh", "exit 0" }, executable)
        assert(vim.fn.setfperm(executable, "rwxr-xr-x") == 1)
      end
    end
    vim.env.INTELLIJ_SERVER_DIR = fixture .. "/env"
    vim.env.JAVA_HOME = fixture .. "/project-jdk"
    local env_opts = vim.deepcopy(original_opts)
    env_opts.server_dir = nil
    env_opts.jdk = nil
    intellij_plugin.config(intellij_plugin, env_opts)
    assert(server.find() == fixture .. "/env/bin/intellij-server", "IntelliJ ignored INTELLIJ_SERVER_DIR")
    assert(intellij.options().jdk == vim.env.JAVA_HOME, "IntelliJ ignored JAVA_HOME")

    local explicit_opts = vim.deepcopy(env_opts)
    explicit_opts.server_dir = fixture .. "/explicit"
    explicit_opts.jdk = false
    intellij_plugin.config(intellij_plugin, explicit_opts)
    assert(server.find() == fixture .. "/explicit/bin/intellij-server", "Explicit server_dir did not take precedence")
    assert(intellij.options().jdk == false, "Explicit JDK configuration was overwritten")
    vim.env.INTELLIJ_SERVER_DIR = nil
    vim.env.JAVA_HOME = nil
    intellij_plugin.config(intellij_plugin, original_opts)
    vim.fn.delete(fixture, "rf")
    vim.fn.delete(cached_server, "rf")

    if not external_bin then
      -- Initialize Astro without a project TypeScript install to exercise the SDK fallback.
      local astro_fixture = vim.fn.tempname()
      vim.fn.mkdir(astro_fixture, "p")
      vim.fn.writefile({ '{ "name": "astro-check", "private": true }' }, astro_fixture .. "/package.json")
      local filename = astro_fixture .. "/index.astro"
      vim.fn.writefile({ "---", 'const name = "Astro";', "---", "<p>Hello {name}</p>" }, filename)
      vim.cmd.edit(vim.fn.fnameescape(filename))

      local client
      local initialized = vim.wait(15000, function()
        client = vim.lsp.get_clients({ name = "astro", bufnr = 0 })[1]
        return client and client.initialized
      end, 50)
      assert(initialized, "Astro failed to initialize: " .. vim.api.nvim_exec2("messages", { output = true }).output)
      assert(client.config.init_options.typescript.tsdk == vim.g.astro_tsdk, "Astro did not use the bundled SDK")
      assert(vim.fn.filereadable(vim.g.astro_tsdk .. "/typescript.js") == 1, "Bundled TypeScript SDK is missing")
      assert(client.server_capabilities.completionProvider, "Astro did not advertise completion support")

      local config = vim.deepcopy(vim.lsp.config.astro)
      config.root_dir = astro_fixture
      config.init_options.typescript.tsdk = nil
      local project_tsdk = astro_fixture .. "/node_modules/typescript/lib"
      vim.fn.mkdir(vim.fs.dirname(project_tsdk), "p")
      assert(vim.uv.fs_symlink(vim.g.astro_tsdk, project_tsdk, { dir = true }))
      config.before_init({}, config)
      assert(config.init_options.typescript.tsdk == project_tsdk, "Astro did not prefer the project SDK")

      config.init_options.typescript.tsdk = "/explicit/typescript/lib"
      config.before_init({}, config)
      assert(config.init_options.typescript.tsdk == "/explicit/typescript/lib", "Explicit SDK path was overwritten")

      client:stop(true)
      vim.api.nvim_buf_delete(0, { force = true })
      vim.fn.delete(astro_fixture, "rf")

      local smoke_commands = {
        { "clangd", "--version" },
        { "gopls", "version" },
        { "pyright", "--version" },
        { "ruff", "--version" },
        { "rust-analyzer", "--version" },
        { "javac", "-version" },
        { "dlv", "version" },
        { "debugpy-adapter", "--help" },
        { "codelldb", "--help" },
        { "js-debug-adapter", "--help" },
      }
      for _, command in ipairs(smoke_commands) do
        local result = vim.system(command, { text = true, timeout = 15000 }):wait()
        assert(result.code == 0, command[1] .. " failed to start: " .. (result.stderr or ""))
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".lua")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local answer=42" })
      conform.format({ bufnr = buf, formatters = { "stylua" }, async = false, lsp_format = "never" })
      assert(
        vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "local answer = 42",
        "Bundled StyLua did not format Lua"
      )
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    print(
      "Tools: "
        .. (external_bin and "external precedence" or "bundled fallback")
        .. ", Astro, ConformInfo, and IntelliJ overrides passed"
    )
  end, debug.traceback)

  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)

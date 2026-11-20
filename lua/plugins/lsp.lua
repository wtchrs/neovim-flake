return {
  -- Manage LSP as nix packages instead of mason
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },

  -- The Java extra only wires Lombok and the debug/test bundles from Mason, so supply the Nix paths.
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      table.insert(opts.cmd, "--jvm-arg=-javaagent:" .. vim.g.jdtls_lombok_jar)

      local bundles = vim.fn.glob(vim.g.java_debug_dir .. "/com.microsoft.java.debug.plugin-*.jar", false, true)
      for _, jar in ipairs(vim.fn.glob(vim.g.java_test_dir .. "/*.jar", false, true)) do
        local name = vim.fs.basename(jar)
        -- nvim-jdtls documents these two jars as breaking the bundle list.
        local excluded = name == "com.microsoft.java.test.runner-jar-with-dependencies.jar" or name == "jacocoagent.jar"
        if not excluded then
          table.insert(bundles, jar)
        end
      end
      opts.jdtls = { init_options = { bundles = bundles } }

      -- Mirror the extra's Mason-gated debug and test setup.
      opts.on_attach = function(args)
        require("jdtls").setup_dap(opts.dap)
        if opts.dap_main then
          require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)
        end

        local jdtls_dap = require("jdtls.dap")
        local test_opts = {}
        if type(opts.test) == "table" then
          test_opts.config_overrides = opts.test.config_overrides
        end
        require("which-key").add({
          {
            mode = "n",
            buffer = args.buf,
            { "<leader>t", group = "test" },
            {
              "<leader>tt",
              function()
                jdtls_dap.test_class(test_opts)
              end,
              desc = "Run All Test",
            },
            {
              "<leader>tr",
              function()
                jdtls_dap.test_nearest_method(test_opts)
              end,
              desc = "Run Nearest Test",
            },
            { "<leader>tT", jdtls_dap.pick_test, desc = "Run Test" },
          },
        })
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {},

    init = function()
      -- Resolve the Astro extra's package lookup before it can schedule a Mason warning.
      local get_pkg_path = LazyVim.get_pkg_path
      LazyVim.get_pkg_path = function(package_name, path, opts)
        if package_name == "astro-language-server" and path == "/node_modules/@astrojs/ts-plugin" then
          return vim.g.astro_ts_plugin
        end
        return get_pkg_path(package_name, path, opts)
      end
    end,

    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.astro.before_init = function(_, config)
        local typescript = config.init_options.typescript
        if typescript.tsdk and typescript.tsdk ~= "" then
          return
        end

        local tsdk = require("lspconfig.util").get_typescript_server_path(config.root_dir)
        if tsdk == "" then
          -- Use the server's bundled SDK when the project has no TypeScript install.
          tsdk = vim.g.astro_tsdk
        end
        typescript.tsdk = tsdk
      end

      -- tiny-code-action.nvim keymap config
      opts.servers["*"] = opts.servers["*"] or {}
      opts.servers["*"].keys = opts.servers["*"].keys or {}
      table.insert(opts.servers["*"].keys, {
        "<leader>ca",
        function()
          require("tiny-code-action").code_action({})
        end,
        mode = { "n", "x" },
        desc = "Code Action",
        has = "codeAction",
      })

      -- Enable awk_ls
      opts.servers.awk_ls = true

      -- Overwrite default lua_ls server settings
      opts.servers.lua_ls = vim.tbl_deep_extend("force", opts.servers.lua_ls or {}, {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
                vim.env.VIMRUNTIME .. "/lua",
              },
            },
          },
        },
      })

      opts.servers.tailwindcss = vim.tbl_deep_extend("force", opts.servers.tailwindcss or {}, {
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "clsx\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                -- (optional) shadcn/ui cn(...) wrapper
                { "cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
              },
            },
          },
        },
      })

      -- Set `mason = false` for all lsp servers
      for server, server_opts in pairs(opts.servers) do
        if server_opts == true then
          opts.servers[server] = { mason = false }
        elseif type(server_opts) == "table" then
          server_opts.mason = false
        end
      end

      -- Use `tiny-inline-diagnostic.nvim` instead
      opts.diagnostics.virtual_text = false
    end,
  },

  -- in order to remove mason dependency
  { "stevearc/conform.nvim", dependencies = {} },
  {
    "mfussenegger/nvim-lint",
    dependencies = {},
    opts = function(_, opts)
      local base = vim.deepcopy(require("lint.linters.golangcilint"))

      opts.linters = opts.linters or {}
      opts.linters.golangcilint = function()
        local linter = vim.deepcopy(base)
        local filename = vim.api.nvim_buf_get_name(0)
        local package_dir = vim.fs.dirname(filename)
        local module_root = vim.fs.root(filename, "go.mod")

        linter.cwd = module_root or package_dir
        linter.args[#linter.args] = module_root and package_dir or filename

        return linter
      end
    end,
  },

  {
    "rachartier/tiny-code-action.nvim",
    event = "LspAttach",
    dependencies = {
      "folke/snacks.nvim",
    },

    opts = {
      backend = "vim",
      picker = {
        "snacks",
        opts = {
          layout = {
            preset = function()
              return vim.o.columns >= 140 and "default" or "vertical"
            end,
          },
        },
      },

      notify = {
        enabled = true,
        on_empty = true,
      },

      format_title = function(action, _)
        if action.kind then
          return string.format("%s  [%s]", action.title, action.kind)
        end

        return action.title
      end,
    },
  },

  -- local plugin for custom commands that print linter information
  {
    name = "lintinfo.nvim",
    dir = vim.fn.stdpath("config") .. "/local/lintinfo.nvim",
    dependencies = { "mfussenegger/nvim-lint" },

    event = "VeryLazy",
    cmd = { "LintInfo", "LintInfoAll" },

    config = function()
      require("lintinfo").setup_commands()
    end,
  },
}

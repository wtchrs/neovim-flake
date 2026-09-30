return {
  -- Manage LSP as nix packages instead of mason
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },

  {
    "neovim/nvim-lspconfig",
    dependencies = {},

    opts = function(_, opts)
      opts.servers = opts.servers or {}

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

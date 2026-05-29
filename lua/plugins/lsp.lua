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

      -- Auto-detect LSP servers available in $PATH
      local configs = require("lspconfig.configs")
      for _, f in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
        local server = vim.fn.fnamemodify(f, ":t:r")
        if not opts.servers[server] then
          local ok, config = pcall(function()
            return configs[server]
          end)
          if ok and config and config.default_config and config.default_config.cmd then
            local cmd = config.default_config.cmd[1]
            if cmd and vim.fn.executable(cmd) == 1 then
              opts.servers[server] = { mason = false }
            end
          end
        end
      end

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
    end,
  },

  -- in order to remove mason dependency
  { "stevearc/conform.nvim", dependencies = {} },
  { "mfussenegger/nvim-lint", dependencies = {} },

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

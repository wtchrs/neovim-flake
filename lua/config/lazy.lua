return function(lazyPath)
  require("lazy").setup({
    defaults = {
      lazy = false,
    },

    dev = {
      -- reuse files from pkgs.vimPlugins.*
      path = lazyPath,
      patterns = { "" },
      -- disable fallback to download
      fallback = false,
    },

    -- disable automatic package installation
    install = { missing = false },

    -- disable plugin update checker
    checker = {
      enabled = false,
      notify = false,
    },

    -- lockfile as writable data
    lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",

    ui = {
      border = "rounded",
    },

    spec = {
      { "LazyVim/LazyVim", import = "lazyvim.plugins" },

      {
        "nvim-treesitter/nvim-treesitter",
        parser_install_dir = vim.fn.stdpath("data") .. "/nvim/parsers",
      },

      { import = "lazyvim.plugins.extras.editor.neo-tree" },
      { import = "lazyvim.plugins.extras.coding.mini-surround" },
      { import = "lazyvim.plugins.extras.dap.core" },
      { import = "lazyvim.plugins.extras.lang.clangd" },
      { import = "lazyvim.plugins.extras.lang.cmake" },
      { import = "lazyvim.plugins.extras.lang.docker" },
      { import = "lazyvim.plugins.extras.lang.java" },
      { import = "lazyvim.plugins.extras.lang.nix" },
      { import = "lazyvim.plugins.extras.lang.python" },
      { import = "lazyvim.plugins.extras.lang.rust" },
      { import = "lazyvim.plugins.extras.lang.tailwind" },
      { import = "lazyvim.plugins.extras.lang.typescript" },
      { import = "lazyvim.plugins.extras.lang.yaml" },

      { import = "plugins" },
    },
  })
end

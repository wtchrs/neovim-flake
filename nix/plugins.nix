{ pkgs, ... }:

let
  nvim-intellij-lsp = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-intellij-lsp";
    version = "2026-10-08";
    src = pkgs.fetchFromGitHub {
      owner = "gipo355";
      repo = "nvim-intellij-lsp";
      rev = "92adb1253846819b839f0ab8ccea781b7e2b46f2";
      hash = "sha256-sGlXZwBL/mmwi8zW0j4C3GLU2D8G/JkEpZhb3d+sbL4=";
    };
    dependencies = [ pkgs.vimPlugins.nvim-dap ];
  };
in
with pkgs.vimPlugins;
[
  lazy-nvim
  LazyVim
  bufferline-nvim
  blink-cmp
  clangd_extensions-nvim
  cmake-tools-nvim
  colorful-menu-nvim
  conform-nvim
  crates-nvim
  dropbar-nvim
  edgy-nvim
  flash-nvim
  friendly-snippets
  gitsigns-nvim
  grug-far-nvim
  hex-nvim
  im-select-nvim
  inc-rename-nvim
  lazydev-nvim
  lualine-nvim
  noice-nvim
  nord-nvim
  nui-nvim
  nvim-dap
  nvim-dap-go
  nvim-dap-python
  nvim-dap-ui
  nvim-dap-virtual-text
  nvim-intellij-lsp
  nvim-lint
  nvim-lspconfig
  nvim-nio
  nvim-treesitter.withAllGrammars
  nvim-treesitter-textobjects
  nvim-ts-autotag
  # nvim-ts-context-commentstring
  nvim-web-devicons
  persistence-nvim
  plenary-nvim
  rustaceanvim
  SchemaStore-nvim
  snacks-nvim
  telescope-fzf-native-nvim
  tiny-code-action-nvim
  tiny-inline-diagnostic-nvim
  todo-comments-nvim
  trouble-nvim
  ts-comments-nvim
  venv-selector-nvim
  vim-startuptime
  vim-tmux-navigator
  which-key-nvim

  {
    name = "mini.ai";
    path = mini-nvim;
  }
  # { name = "mini.bufremove"; path = mini-nvim; }
  # { name = "mini.comment"; path = mini-nvim; }
  {
    name = "mini.icons";
    path = mini-nvim;
  }
  # { name = "mini.indentscope"; path = mini-nvim; }
  {
    name = "mini.pairs";
    path = mini-nvim;
  }
  {
    name = "mini.surround";
    path = mini-nvim;
  }
  # { name = "mini.hipatterns"; path = mini-nvim; }
]

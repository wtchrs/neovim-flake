{ pkgs, lib }:

let
  appName = "nvim-store";
  intellijServer = import ./intellij-server.nix { inherit pkgs lib; };

  # LazyVim uses Mason's executable name for the JavaScript debug adapter.
  jsDebugAdapter = pkgs.runCommand "js-debug-adapter" { } ''
    mkdir -p "$out/bin"
    ln -s ${lib.getExe pkgs.vscode-js-debug} "$out/bin/js-debug-adapter"
  '';

  plugins = import ./plugins.nix { inherit pkgs lib; };

  mkLazyEntry =
    drv:
    if lib.isDerivation drv then
      {
        name = lib.getName drv;
        path = drv;
      }
    else
      drv;

  lazyPath = pkgs.linkFarm "lazy-plugins" (map mkLazyEntry plugins);

  # lazy.nvim loads the plugin itself, but not its Nix parser/query dependencies.
  # Expose them as one installation directory for Treesitter and LazyVim.
  treesitterRuntime = pkgs.symlinkJoin {
    name = "nvim-treesitter-runtime";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };

  configRoot = pkgs.runCommand "${appName}-config" { } ''
    mkdir -p "$out/${appName}"

    cp -r ${../after} "$out/${appName}/after"
    cp -r ${../lua}   "$out/${appName}/lua"
    cp -r ${../local} "$out/${appName}/local"

    cat >"$out/${appName}/init.lua" <<EOF
    vim.opt.rtp:prepend("${pkgs.vimPlugins.lazy-nvim}")
    local initLazy = require("config.lazy")
    initLazy("${lazyPath}", "${treesitterRuntime}")
    EOF
  '';

  internalTools = with pkgs; [
    ripgrep
    fd
    tree-sitter
    xxd
  ];

  # Project tools keep precedence; these also support editing outside a dev shell.
  developmentTools = with pkgs; [
    git
    gcc
    gnumake
    cmake
    ninja
    go
    rustc
    cargo
    clippy
    rustfmt
    python3
    nodejs
    jdk
    tsx

    # Language servers for the enabled LazyVim extras and local configuration.
    awk-language-server
    clang-tools
    neocmakelsp
    dockerfile-language-server
    docker-compose-language-service
    gopls
    nil
    lua-language-server
    pyright
    ruff
    rust-analyzer
    tailwindcss-language-server
    vtsls
    tinymist
    yaml-language-server
    intellijServer

    # Formatters and linters, including LazyVim's default shell support.
    stylua
    nixfmt
    shfmt
    fish
    gotools
    gofumpt
    typstyle
    statix
    golangci-lint
    hadolint
    cmake-lint

    # Debug adapters already configured by the enabled extras.
    delve
    python3Packages.debugpy
    vscode-extensions.vadimcn.vscode-lldb.adapter
    jsDebugAdapter
  ];
in
pkgs.symlinkJoin {
  name = "nvim-store";
  paths = [ pkgs.neovim-unwrapped ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    rm -f "$out/bin/nvim"

    makeWrapper ${pkgs.neovim-unwrapped}/bin/nvim "$out/bin/nvim" \
      --set NVIM_APPNAME ${appName} \
      --set XDG_CONFIG_HOME ${configRoot} \
      --set CODEDIFF_WATCHER_NO_AUTO_INSTALL 1 \
      --prefix PATH : ${lib.makeBinPath internalTools} \
      --suffix PATH : ${lib.makeBinPath developmentTools}
  '';
}

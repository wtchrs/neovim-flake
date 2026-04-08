{ pkgs, lib }:

let
  appName = "nvim-store";

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

  configRoot = pkgs.runCommand "${appName}-config" { } ''
    mkdir -p "$out/${appName}"

    cp -r ${../after} "$out/${appName}/after"
    cp -r ${../lua}   "$out/${appName}/lua"
    cp -r ${../local} "$out/${appName}/local"

    cat >"$out/${appName}/init.lua" <<EOF
    vim.opt.rtp:prepend("${pkgs.vimPlugins.lazy-nvim}")
    local initLazy = require("config.lazy")
    initLazy("${lazyPath}")
    EOF
  '';

  runtimeDeps = with pkgs; [
    git
    ripgrep
    fd
    gcc
    gnumake
    tree-sitter
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
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
  '';
}

{
  description = "Neovim configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "intellij-server";
        };

      mkNvim =
        system:
        let
          pkgs = pkgsFor system;
        in
        import ./nix/package.nix {
          inherit pkgs;
          inherit (pkgs) lib;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = mkNvim system;
          check-intellij-server = pkgs.writeShellApplication {
            name = "check-intellij-server";
            runtimeInputs = with pkgs; [
              curl
              libarchive
              jq
            ];
            text = builtins.readFile ./scripts/check-intellij-server.sh;
          };
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/nvim";
        };
      });

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          externalTools = pkgs.runCommand "neovim-external-tools" { } ''
            mkdir -p "$out/bin"
            for tool in git gcc make cmake nil stylua statix pyright-langserver \
              dlv codelldb js-debug-adapter intellij-server javac rg fd xxd tree-sitter; do
              cp ${pkgs.coreutils}/bin/true "$out/bin/$tool"
            done
          '';
        in
        {
          tools = pkgs.runCommand "neovim-tools-check" { } ''
            for mode in bundled external; do
              export HOME="$TMPDIR/$mode/home"
              export XDG_DATA_HOME="$TMPDIR/$mode/data"
              export XDG_CACHE_HOME="$TMPDIR/$mode/cache"
              export XDG_STATE_HOME="$TMPDIR/$mode/state"
              export PATH="${pkgs.coreutils}/bin"
              unset INTELLIJ_SERVER_DIR JAVA_HOME TOOLS_EXTERNAL_BIN
              mkdir -p "$HOME"

              if [ "$mode" = external ]; then
                export TOOLS_EXTERNAL_BIN="${externalTools}/bin"
                export PATH="$TOOLS_EXTERNAL_BIN:$PATH"
              fi

              timeout 90s ${self.packages.${system}.default}/bin/nvim --headless -i NONE \
                '+lua dofile("${./tests/tools.lua}")'
            done
            touch "$out"
          '';

          java = pkgs.runCommand "neovim-java-check" { } ''
            export HOME="$TMPDIR/home"
            export XDG_DATA_HOME="$TMPDIR/data"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            export XDG_STATE_HOME="$TMPDIR/state"
            mkdir -p "$HOME"

            timeout 60s ${self.packages.${system}.default}/bin/nvim --headless -i NONE \
              '+lua dofile("${./tests/java.lua}")'
            touch "$out"
          '';

          lintinfo = pkgs.runCommand "neovim-lintinfo-check" { } ''
            export XDG_DATA_HOME="$TMPDIR/data"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            export XDG_STATE_HOME="$TMPDIR/state"
            export NVIM_LOG_FILE="$TMPDIR/nvim.log"
            export LINTINFO_RUNTIME="${./local/lintinfo.nvim}"

            timeout 30s ${pkgs.neovim-unwrapped}/bin/nvim --headless -u NONE -i NONE \
              '+lua dofile("${./tests/lintinfo.lua}")'
            touch "$out"
          '';

          treesitter = pkgs.runCommand "neovim-treesitter-check" { } ''
            export HOME="$TMPDIR/home"
            export XDG_DATA_HOME="$TMPDIR/data"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            export XDG_STATE_HOME="$TMPDIR/state"
            mkdir -p "$HOME"

            timeout 30s ${self.packages.${system}.default}/bin/nvim --headless -i NONE \
              '+lua dofile("${./tests/treesitter.lua}")'
            touch "$out"
          '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # nix
              nil
              nixd
              statix

              # lua
              stylua
              lua-language-server
            ];

            shellHook = ''
              echo "Entered Neovim configuration flake dev shell"
            '';
          };
        }
      );
    };
}

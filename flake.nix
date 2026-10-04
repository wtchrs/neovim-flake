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

      pkgsFor = system: import nixpkgs { inherit system; };

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
      packages = forAllSystems (system: {
        default = mkNvim system;
      });

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
        in
        {
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

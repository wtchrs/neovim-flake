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

{
  description = "Neovim with configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      mkNvim =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
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
    };
}

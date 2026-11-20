# Neovim configuration flake

This flake provides a wrapped Neovim package whose configuration is bundled into the Nix store.

## Getting started

Run the following commands:

```sh
nix run github:wtchrs/neovim-flake

# or add this to your profile
nix profile add github:wtchrs/neovim-flake
nvim
```

> [!NOTE]
> If `nix-command` and `flakes` features are not enabled, add `--experimental-features 'nix-command flakes'`.

If you want to use this flake in your NixOS configuration, use the following setup:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    neovim-flake = {
      url = "github:wtchrs/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations."hostname" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [ ./configuration.nix ];
    };
  };
}
```

```nix
# configuration.nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.neovim-flake.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

## Development tools

Language servers, formatters, linters, debug adapters, and basic toolchains for
the enabled languages are bundled. Tools in the launching shell's `PATH` take
precedence. Internal utilities (`rg`, `fd`, `xxd`, and the Tree-sitter CLI) use
bundled versions first, including in Neovim terminals.

Use a project's development shell or direnv for its dependencies and tool
versions before launching Neovim. Inspect formatter and linter paths with
`:ConformInfo` and `:LintInfo`.

## Treesitter parsers

Treesitter parsers and queries are bundled by Nix and loaded from the Nix store.
Neovim does not download or compile parsers at startup. Update them by updating
the flake input and rebuilding the package, rather than running `:TSUpdate` or
`:TSInstall`.

## Checks

Run `nix flake check` to verify tool selection, Treesitter, LintInfo, Astro, and
Java integration.

## CodeDiff watcher

The wrapper disables watcher downloads with `CODEDIFF_WATCHER_NO_AUTO_INSTALL=1`.
Without a watcher, CodeDiff automatically refreshes by polling every 500 ms.

## Java: jdtls

Java uses LazyVim's `lang.java` extra with the bundled Eclipse JDT Language
Server (`jdtls`). Nix also provides Lombok and the Java debug and test bundles
that the extra would otherwise install with Mason.

- jdtls starts automatically for Java files in Maven, Gradle, or Git projects.
- The bundled jdtls always runs on its own Nix JDK (currently 25), regardless of
  the project's `JAVA_HOME`. A `jdtls` from the project's `PATH` takes
  precedence and selects Java from `JAVA_HOME` or `PATH` instead.
- The project's Java version comes from its build configuration. To analyze
  against a specific JDK, optionally register it in jdtls'
  `java.configuration.runtimes` setting.
- Debug with nvim-dap.

### Keybindings

| Key           | Mode           | Action                     |
| ------------- | -------------- | -------------------------- |
| `<leader>co`  | Normal         | Organize imports           |
| `<leader>cxv` | Normal, Visual | Extract variable           |
| `<leader>cxc` | Normal, Visual | Extract constant           |
| `<leader>cxm` | Visual         | Extract method             |
| `<leader>cgs` | Normal         | Go to super implementation |
| `<leader>cgS` | Normal         | Go to test subjects        |
| `<leader>tt`  | Normal         | Run all tests in the class |
| `<leader>tr`  | Normal         | Run the nearest test       |
| `<leader>tT`  | Normal         | Pick a test to run         |

## Dev shell

You can start the Nix development shell with LSPs and formatters for Nix and Lua.

```sh
nix develop
# or with your favorite shell
nix develop -c zsh
```

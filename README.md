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

## Treesitter parsers

Treesitter parsers and queries are bundled by Nix and loaded from the Nix store.
Neovim does not download or compile parsers at startup. Update them by updating
the flake input and rebuilding the package, rather than running `:TSUpdate` or
`:TSInstall`.

## Checks

Run `nix flake check` to verify:

- CodeDiff watcher discovery from the bundled PATH, native process startup, and
  worktree change notifications with empty Neovim data directories.
- Treesitter parser availability and automatic Lua/Nix highlighting with empty
  Neovim data directories.
- LintInfo command evaluation and preservation of global, tab-local, and
  window-local working directories, including when command evaluation fails.
- Java LSP selection, blink.cmp capabilities, IntelliJ DAP registration,
  multi-module root selection, and native server startup on Linux.

## CodeDiff watcher

Nix downloads `codediff-watcher` from a pinned GitHub Release for x86_64 and ARM64
Linux and adds it to Neovim's PATH. CodeDiff uses this binary without installing
it into the plugin's read-only Nix store directory. Keep the version in
`nix/codediff-watcher.nix` aligned with the plugin's watcher installer when updating
nixpkgs.

## Java: IntelliJ language server

Nix bundles JetBrains' `intellij-server`,
[nvim-intellij-lsp](https://github.com/gipo355/nvim-intellij-lsp).

After rebuilding, open a Java file in a Maven, Gradle, or Bazel project. Run
`:IntellijAcceptEula` and accept the agreement, then start the server:

```vim
:lsp enable intellij
:checkhealth intellij-lsp
```

- Provide a project JDK through your environment. Set `JAVA_HOME` before launching
  Neovim to select it explicitly; otherwise the client searches known JDK locations.
- Organize imports with `<leader>co`; run or debug with `:IntellijRun`,
  `:IntellijDebug`, or nvim-dap.
- The first import may take several minutes. Diagnose failures with
  `:IntellijStatus` and `:IntellijLog`. Use one Neovim instance per project root.
- Update the server pin in `nix/intellij-server.nix` and the client pin in
  `nix/plugins.nix`, then rebuild. Avoid `:IntellijInstall` and `:IntellijUpdate`
  on NixOS.

## Dev shell

You can start the Nix development shell with LSPs and formatters for Nix and Lua.

```sh
nix develop
# or with your favorite shell
nix develop -c zsh
```

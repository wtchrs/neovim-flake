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

- Treesitter parser availability and automatic Lua/Nix highlighting with empty
  Neovim data directories.
- LintInfo command evaluation and preservation of global, tab-local, and
  window-local working directories, including when command evaluation fails.
- Java LSP selection, blink.cmp capabilities, IntelliJ DAP registration,
  multi-module root selection, and native server startup on Linux.

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

## tmux integration

If you use tmux, add the [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) to your tmux config for seamless navigation between Neovim and tmux panes.

To extend horizontal navigation to tmux windows, apply these overrides after the
plugin loads (in `~/.tmux.conf`, or Home Manager's `programs.tmux.extraConfig`):

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
  | grep -iqE '^[^TXZ ]+ +([^[:space:]]+/)?g?[.]?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?$'"

bind -n C-h if-shell "$is_vim" {
  send-keys C-h
} {
  if-shell -F '#{pane_at_left}' 'previous-window' 'select-pane -L'
}

bind -n C-l if-shell "$is_vim" {
  send-keys C-l
} {
  if-shell -F '#{pane_at_right}' 'next-window' 'select-pane -R'
}

bind -T copy-mode-vi C-h if-shell -F '#{pane_at_left}' 'previous-window' 'select-pane -L'
bind -T copy-mode-vi C-l if-shell -F '#{pane_at_right}' 'next-window' 'select-pane -R'
```

`Ctrl+h/l` moves through Neovim splits, then tmux panes, then to the previous/next
tmux window at the left/right edge. The last two bindings provide the same window
navigation in vi copy mode. `Ctrl+j/k` keeps the plugin's vertical pane navigation.
Reload your tmux configuration after applying the changes.

## Dev shell

You can start the Nix development shell with LSPs and formatters for Nix and Lua.

```sh
nix develop
# or with your favorite shell
nix develop -c zsh
```

{
  description = "zeked's configs";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # nixos-22.11

    # Manages configs links things into your home directory
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Controls system level software and settings including fonts
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Tricked out nvim
    pwnvim.url = "github:zmre/pwnvim";

    # Devbox
    devbox.url = "github:jetify-com/devbox/latest";

    # Nix lsp
    nixd.url = "github:nix-community/nixd";
    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      pwnvim,
      devbox,
      alacritty-theme,
      ...
    }:
    {
      darwinConfigurations.zed-mini = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs { system = "aarch64-darwin"; overlays = [ alacritty-theme.overlays.default ]; };
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit pwnvim devbox; };
              users.zedang = import ./modules/home-manager;
            };
          }
        ];
      };
    };
}

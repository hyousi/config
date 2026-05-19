{
  description = "zeked's configs";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    # Pinned to the 25.05 stable channel; bump together with home-manager and darwin below.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";

    # Manages configs links things into your home directory
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Controls system level software and settings including fonts
    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Tricked out nvim
    pwnvim.url = "github:zmre/pwnvim";

    # Devbox
    devbox.url = "github:jetify-com/devbox/latest";

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
      darwinConfigurations."zedang-air" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          overlays = [ alacritty-theme.overlays.default ];
        };
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

{
  description = "zeked's configs";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    # Pinned to the 25.05 stable channel; bump together with home-manager and darwin below.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";

    # Pull selected fast-moving packages without moving the whole system off stable.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      darwin,
      pwnvim,
      devbox,
      ...
    }:
    {
      darwinConfigurations."zedang-air" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
        };
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit pwnvim devbox;
                unstablePkgs = import nixpkgs-unstable {
                  system = "aarch64-darwin";
                };
              };
              users.zedang = import ./modules/home-manager;
            };
          }
        ];
      };
    };
}

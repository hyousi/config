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
    let
      system = "aarch64-darwin";
      hostname = import ./host.nix;
    in
    {
      darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit hostname; };
        pkgs = import nixpkgs { inherit system; };
        modules = [
          ./modules/darwin
          { networking.hostName = hostname; }
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit pwnvim devbox hostname;
                unstablePkgs = import nixpkgs-unstable { inherit system; };
              };
              users.zedang = import ./modules/home-manager;
            };
          }
        ];
      };
    };
}

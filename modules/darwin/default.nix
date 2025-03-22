{ pkgs, ... }: {
  # nix-darwin manages system-level programs and configuration
  users.users.zedang.home = "/Users/zedang";
  programs.zsh.enable = true;
  ids.gids.nixbld = 350;
  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = [ 
      pkgs.coreutils
      pkgs.nixfmt-rfc-style
    ];
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.defaults = {
    finder.AppleShowAllExtensions = true;
    finder._FXShowPosixPathInTitle = true;
    dock.autohide = false;
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 14;
    NSGlobalDomain.KeyRepeat = 1;
  };
  # backwards compat; don't change
  system.stateVersion = 4;
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };
    caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = { };
    casks = [ 
      "betterdisplay"
      "cleanshot"
      "jordanbaird-ice"
      "raycast"
    ];
    taps = [ "fujiapple852/trippy" ];
    brews = [ "trippy" ];
  };
}

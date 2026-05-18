{ pkgs, ... }:
{
  # nix-darwin manages system-level programs and configuration
  users.users.zedang.home = "/Users/zeked";
  system.primaryUser = "zedang";
  programs.zsh.enable = true;
  ids.gids.nixbld = 350;
  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    systemPackages = [
      pkgs.coreutils
      pkgs.nixfmt
      pkgs.nixd
    ];
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    sandbox = false;
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWm3Jxg4apZq6KXZq7o6hZb6sTZ8="
    ];
  };
  fonts = {
    packages = with pkgs; [
      nerd-fonts.meslo-lg
    ];
  };
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.defaults = {
    finder.AppleShowAllExtensions = true;
    finder._FXShowPosixPathInTitle = true;
    dock.autohide = false;
    dock.expose-group-apps = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 14;
    NSGlobalDomain.KeyRepeat = 1;
  };
  # backwards compat; don't change
  system.stateVersion = 4;
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = { };
    casks = [
      "betterdisplay"
      "cleanshot"
      "pixelsnap"
      "cursor"
      "jordanbaird-ice"
      "raycast"
      "orbstack"
      "logi-options+"
      "yaak"
      "mono-mdk"
      "ghostty"
      "obsidian"
    ];
    brews = [
      "trippy"
      "cloudflared"
    ];
  };
}

{ pkgs, lib, ... }:
let
  username = "zedang";
  homebrewMirror = {
    HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
  };
in
{
  # nix-darwin manages system-level programs and configuration
  users.users.${username}.home = "/Users/${username}";
  system.primaryUser = username;
  programs.zsh.enable = true;
  ids.gids.nixbld = 350;
  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    systemPackages = [
      pkgs.coreutils
      pkgs.nixfmt-classic
      pkgs.nixd
    ];
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
    variables = homebrewMirror;
  };
  environment.etc."homebrew/brew.env".text =
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "${name}=\"${value}\"") homebrewMirror
    ) + "\n";
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    sandbox = false;
    substituters = lib.mkForce [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = lib.mkForce [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
  nix.optimise = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 4;
      Minute = 0;
    };
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
      autoUpdate = false;
      upgrade = false;
      # nix-darwin 25.05 emits deprecated `brew bundle --cleanup`; use
      # `--force-cleanup` directly until the darwin input is bumped.
      cleanup = "none";
      extraFlags = [ "--force-cleanup" ];
    };
    global.brewfile = true;
    masApps = { };
    casks = [
      "betterdisplay"
      "cleanshot"
      "pixelsnap"
      "claude-code"
      "cursor"
      "cursor-cli"
      "jordanbaird-ice"
      "raycast"
      "orbstack"
      "logi-options+"
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

{
  pkgs,
  lib,
  pwnvim,
  devbox,
  config,
  ...
}:
{
  # home-manager manages user-level programs and configuration
  home.homeDirectory = "/Users/zeked";
  # Don't change this when you change package input. Leave it alone.
  home.stateVersion = "24.11";
  # specify my home-manager configs
  home.packages = with pkgs; [
    ripgrep # for searching files
    fd # for finding files
    hyperfine
    curl # for downloading files
    less # for pager
    git-credential-manager # Git credential helper (needs sandbox disabled on macOS)
    pwnvim.packages."aarch64-darwin".default # for vim
    devbox.packages."aarch64-darwin".default # for devbox
    dotnet-sdk_8
  ];

  home.sessionVariables = {
    PAGER = "less";
    CLICLOLOR = 1;
    EDITOR = "nvim";
  };

  programs.aerospace = {
    enable = true;
    settings = lib.importTOML ./dotfiles/aerospace.toml;
  };

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  # A modern alternative to ls
  programs.eza.enable = true;
  programs.git = {
    enable = true;
    maintenance.enable = true;
  };
  programs.git-credential-oauth.enable = true;
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    initExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
    enableCompletion = true;
    # enable zsh-autosuggestions-plugin
    autosuggestion.enable = true;
    # enable zsh-syntax-highlighting-plugin
    syntaxHighlighting.enable = true;
    shellAliases = {
      cat = "bat";
      ls = "eza --oneline";
      lsa = "eza --all --oneline";
      lsl = "eza --long --header --total-size --time-style=long-iso";
      lsal = "eza --all --long --header --total-size --time-style=long-iso";
      lss = "eza --long --sort=size";
      lsd = "eza --only-dirs --oneline";
      lsf = "eza --only-files --oneline";
      lsab = "eza --absolute=on --oneline";
      nixswitch = "sudo darwin-rebuild switch --flake ~/config/.#";
      nixup = "pushd ~/config; nix flake update; nixswitch; popd";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "kubectl"
        "sudo"
      ];
      # Theme is controlled by starship
      # theme = "robbyrussell";
    };
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = lib.importTOML ./dotfiles/starship.toml;
  };
  programs.alacritty = {
    enable = true;
    settings = {
      font.normal.family = "MesloLGS Nerd Font Mono";
      font.size = 14;
      general.import = [ pkgs.alacritty-theme.catppuccin_mocha ];
    };
  };

  home.file = {
    ".inputrc".source = ./dotfiles/inputrc;
  };

  xdg = {
    enable = true;
    configFile."git/config".source = ./dotfiles/.gitconfig;
    configFile."ghostty/config".text = ''
      font-family = "MesloLGS Nerd Font Mono"
      font-size = 14
      theme = catppuccin-frappe
    '';
  };
}

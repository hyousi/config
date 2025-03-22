{ pkgs, pwnvim, devbox, ... }: {
  # home-manager manages user-level programs and configuration
  home.homeDirectory = "/Users/zedang";
  # Don't change this when you change package input. Leave it alone.
  home.stateVersion = "24.11";
  # specify my home-manager configs
  home.packages = with pkgs; [
    ripgrep # for searching files 
    fd # for finding files
    curl # for downloading files
    less # for pager
    pwnvim.packages."aarch64-darwin".default # for vim
    devbox.packages."aarch64-darwin".default # for devbox
  ];
  home.sessionVariables = {
    PAGER = "less";
    CLICLOLOR = 1;
    EDITOR = "nvim";
  };
  programs.bat.enable = true;
  programs.bat.config.theme = "TwoDark";
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  # A modern alternative to ls
  programs.eza.enable = true;
  programs.git.enable = true;
  programs.zsh.enable = true;
  programs.zsh.initExtra = ''
    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';
  programs.zsh.enableCompletion = true;
  programs.zsh.autosuggestion.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.shellAliases = {
    ls = "ls --color=auto -F";
    nixswitch = "darwin-rebuild switch --flake ~/config/.#";
    nixup = "pushd ~/config; nix flake update; nixswitch; popd";
  };
  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = [ "git" ];
    theme = "robbyrussell";
  };
  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.alacritty = {
    enable = true;
    settings.font.normal.family = "MesloLGS Nerd Font Mono";
    settings.font.size = 14;
  };
  home.file.".inputrc".source = ./dotfiles/inputrc;
}

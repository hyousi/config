{
  pkgs,
  lib,
  pwnvim,
  devbox,
  unstablePkgs,
  config,
  ...
}:
{
  # home-manager manages user-level programs and configuration
  # home.homeDirectory 由 nix-darwin 的 users.users.<name>.home 自动提供
  # Don't change this when you change package input. Leave it alone.
  home.stateVersion = "24.11";
  # specify my home-manager configs
  home.packages = with pkgs; [
    ripgrep # for searching files
    fd # for finding files
    hyperfine
    curl # for downloading files
    gh # GitHub CLI
    less # for pager
    pwnvim.packages."aarch64-darwin".default # for vim
    devbox.packages."aarch64-darwin".default # for devbox
    nodejs # current active LTS
  ];

  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "nvim";
  };

  programs.aerospace = {
    enable = true;
    package = unstablePkgs.aerospace;
    userSettings = lib.importTOML ./dotfiles/aerospace.toml;
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
    initContent = lib.concatStringsSep "\n" [
      (builtins.readFile ./dotfiles/zsh/env.zsh)
      (builtins.readFile ./dotfiles/zsh/sudo-widget.zsh)
      (builtins.readFile ./dotfiles/zsh/kubectl.zsh)
    ];
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
      # git
      gst = "git status";
      gco = "git checkout";
      gp = "git push";
      gl = "git pull";
      gpr = "git pull --rebase";
      gpf = "git push --force-with-lease";
      gcm = "git commit -m";
      gca = "git commit --amend";
      gd = "git diff";
      gb = "git branch";
      glog = "git log --oneline --decorate --graph";
      # kubectl
      k = "kubectl";
    };
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = lib.importTOML ./dotfiles/starship.toml;
  };

  home.file = {
    ".inputrc".source = ./dotfiles/inputrc;
    "Library/Application Support/Cursor/User/keybindings.json" = {
      source = ./dotfiles/cursor/keybindings.json;
      force = true;
    };
  };

  xdg = {
    enable = true;
    configFile."git/config".source = ./dotfiles/.gitconfig;
    configFile."ghostty/config".text = ''
      font-family = "MesloLGS Nerd Font Mono"
      font-size = 14
    '';
  };
}

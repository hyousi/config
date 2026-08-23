{
  pkgs,
  lib,
  pwnvim,
  devbox,
  unstablePkgs,
  hostname,
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
    less # for pager
    pwnvim.packages."aarch64-darwin".default # for vim
    devbox.packages."aarch64-darwin".default # for devbox
    nodejs # current active LTS
  ] ++ [
    # unstable: stable 25.05 ships gh 2.72.0 which queries deprecated projectCards
    unstablePkgs.gh
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
    includes = [
      {
        condition = "gitdir:~/Developer/work/";
        path = "~/Developer/work/.gitconfig";
      }
      {
        condition = "gitdir:~/Developer/hobby/";
        path = "~/Developer/hobby/.gitconfig";
      }
    ];
    userName = "hyousi";
    userEmail = "t0iiz@outlook.com";
    extraConfig = {
      column.ui = "auto";
      branch = {
        sort = "-committerdate";
        autoSetupMerge = "simple";
      };
      tag.sort = "version:refname";
      init.defaultBranch = "main";
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
      help.autocorrect = "prompt";
      commit.verbose = true;
      rerere = {
        enabled = true;
        autoUpdate = true;
      };
      core = {
        excludesFile = "~/.gitignore";
        fsmonitor = true;
      };
      grep = {
        lineNumber = true;
        heading = true;
        break = true;
        patternType = "perl";
      };
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      merge.conflictStyle = "zdiff3";
      pull.rebase = true;
    };
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
      nixswitch = "sudo darwin-rebuild switch --flake ~/config#${hostname}";
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

  # otty manages its own config.toml at runtime (theme/font changes made in
  # the GUI get written back to this file), so we only seed it once instead
  # of symlinking it read-only into the nix store.
  home.activation.seedOttyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ottyConfig="$HOME/.config/otty/config.toml"
    if [ ! -e "$ottyConfig" ]; then
      run mkdir -p "$HOME/.config/otty"
      run cp ${./dotfiles/otty/config.toml} "$ottyConfig"
      run chmod u+w "$ottyConfig"
    fi
  '';
}

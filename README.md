# zeked's nix-darwin config

Personal declarative configuration for macOS (Apple Silicon), built on
[Nix](https://nixos.org/), [nix-darwin](https://github.com/nix-darwin/nix-darwin),
and [home-manager](https://github.com/nix-community/home-manager).

System hostname: `zedang-air`.

## Layout

```
flake.nix                       # inputs + darwinConfigurations entry
modules/
  darwin/default.nix            # system-level: defaults, fonts, homebrew (casks/brews)
  home-manager/
    default.nix                 # user-level: packages, zsh, git, starship, alacritty, ...
    dotfiles/                   # config files imported via importTOML / readFile / source
      aerospace.toml
      starship.toml
      zsh/                      # split-out zsh init snippets (sourced into .zshrc)
      ...
```

Channels are pinned to the `25.05` stable release across `nixpkgs`,
`home-manager`, and `nix-darwin`. Bump all three together when upgrading.

## Bootstrap on a fresh machine

1. Install Nix (Determinate Systems installer recommended):

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Clone this repo to `~/config`:

   ```bash
   git clone <this-repo> ~/config
   ```

3. Build and activate the darwin configuration the first time:

   ```bash
   nix --extra-experimental-features 'nix-command flakes' \
     run nix-darwin -- switch --flake ~/config#zedang-air
   ```

4. Open a new shell. The `nixswitch` and `nixup` aliases are now available.

## Day-to-day

| Goal | Command |
| --- | --- |
| Apply config changes | `nixswitch` |
| Update inputs + apply | `nixup` |
| Format nix files | `nixfmt **/*.nix` |
| Free old generations | `nix-collect-garbage -d` |

`nixswitch` expands to `sudo darwin-rebuild switch --flake ~/config/.#`.

## Notes

- New files must be `git add`-ed before `nixswitch` — flakes only see
  git-tracked files, so untracked files cause "No such file" build errors.
- Homebrew is managed declaratively under `homebrew = { ... }` in
  `modules/darwin/default.nix`. Don't `brew install` ad-hoc; add to `casks`
  or `brews` and `nixswitch`.
- Per-project dev environments use `devbox` (`devbox.json` in the project).
  No `devbox global` state — global tools belong in `home.packages`.

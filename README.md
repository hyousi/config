# zeked's nix-darwin config

Personal declarative configuration for macOS (Apple Silicon), built on
[Nix](https://nixos.org/), [nix-darwin](https://github.com/nix-darwin/nix-darwin),
and [home-manager](https://github.com/nix-community/home-manager).

同一 repo 同步到多台设备，配置完全相同。每台设备 clone 后**只改 `host.nix` 一行**即可。

## Layout

```
host.nix                        # ★ 每台设备 clone 后改这里（唯一本地差异）
flake.nix                       # 读取 host.nix，设置 hostname 并 build 本机配置
modules/
  darwin/default.nix            # 系统配置
  home-manager/default.nix      # 用户配置
```

## 新设备上手（3 步）

1. 安装 Nix 并 clone 本 repo 到 `~/config`：

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   git clone <this-repo> ~/config
   ```

2. 编辑 `host.nix`，改成这台设备的名称（任意标识即可，如 `zed-mini`、`zedang-air`）：

   ```nix
   "zedang-air"
   ```

   建议执行一次，避免以后 `git push` 时覆盖其他设备：

   ```bash
   git update-index --skip-worktree host.nix
   ```

3. 首次激活（将 `zed-mini` 换成你在 `host.nix` 里写的名字；之后用 `nixswitch` 即可）：

   ```bash
   cd ~/config
   nix --extra-experimental-features 'nix-command flakes' \
     run nix-darwin -- switch --flake .#zed-mini
   ```

   打开新 shell，`nixswitch` / `nixup` 别名即可用。

## Day-to-day

| Goal | Command |
| --- | --- |
| Apply config changes | `nixswitch` |
| Update inputs + apply | `nixup` |
| Format nix files | `nixfmt **/*.nix` |
| Free old generations | `nix-collect-garbage -d` |

`nixswitch` 在构建时已绑定 `host.nix` 中的主机名，日常无需再指定 flake 属性。

## 新增一台设备

clone → 改 `host.nix` → 首次 `darwin-rebuild switch` → 完成。无需改 repo 其他文件。

## Notes

- New files must be `git add`-ed before `nixswitch` — flakes only see
  git-tracked files, so untracked files cause "No such file" build errors.
- `host.nix` 必须被 git 跟踪（flake 限制）；用 `skip-worktree` 保留各设备本地值。
- Homebrew casks/brews 在 `modules/darwin/default.nix`。
- Per-project dev environments use `devbox` (`devbox.json` in the project).
  No `devbox global` state — global tools belong in `home.packages`.

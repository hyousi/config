# Per-device identifier. After cloning, set the string below to this Mac's
# Local Hostname (System Settings → General → Sharing → Local Hostname).
# Check on the command line: scutil --get LocalHostName
# Used by flake.nix as darwinConfigurations.<name> and networking.hostName.
# Optional: git update-index --skip-worktree host.nix  (avoid pushing this change)
"zed-mini"

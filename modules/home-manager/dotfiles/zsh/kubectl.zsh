# kubectl completion + `k` alias completion (equivalent of oh-my-zsh's kubectl plugin)
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
  compdef k=kubectl
fi

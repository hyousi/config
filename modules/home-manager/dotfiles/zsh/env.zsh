eval "$(/opt/homebrew/bin/brew shellenv)"

# Case-insensitive Tab completion (e.g. `cd deve` → `Developer`)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

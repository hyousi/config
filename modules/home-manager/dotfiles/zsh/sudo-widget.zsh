# Equivalent of oh-my-zsh's `sudo` plugin:
# Press ESC twice to toggle `sudo ` at the start of the current (or previous) command.
sudo-command-line() {
  [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
  if [[ $BUFFER == sudo\ * ]]; then
    LBUFFER="${LBUFFER#sudo }"
  else
    LBUFFER="sudo $LBUFFER"
  fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

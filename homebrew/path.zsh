eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Google Cloud SDK (brew cask): puts gcloud, gke-gcloud-auth-plugin, etc. on PATH.
[[ -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]] && source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"

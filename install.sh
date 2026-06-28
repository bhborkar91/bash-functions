#!/usr/bin/env bash
set -euo pipefail

append_if_missing() {
  local file="$1"
  local line="$2"

  if [ ! -f "$file" ]; then
    touch "$file"
  fi

  if ! grep -Fqx "$line" "$file" 2>/dev/null; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

default_dir="$HOME/.local"
if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
  echo "Usage: $0 [install_dir]"
  echo "If install_dir is not provided, the default is $default_dir"
  exit 0
fi

if [ -n "${1:-}" ]; then
  install_dir="$1"
else
  read -r -p "Choose a parent folder for bash-functions [${default_dir}]: " install_dir
fi

install_dir="${install_dir:-$default_dir}"
install_dir="${install_dir/#\~/$HOME}"

repo_dir="$install_dir/bash-functions"
mkdir -p "$install_dir"

if [ -d "$repo_dir/.git" ]; then
  echo "bash-functions is already installed at $repo_dir"
else
  echo "Cloning bash-functions into $repo_dir"
  git clone https://github.com/bhborkar91/bash-functions.git "$repo_dir"
fi

bashrc_file="$HOME/.bashrc"
append_if_missing "$bashrc_file" "export BASH_FUNCTIONS_DIR=\"${repo_dir}\""
append_if_missing "$bashrc_file" "export PATH=\"\$PATH:\$BASH_FUNCTIONS_DIR/bin\""
append_if_missing "$bashrc_file" "source \"\$BASH_FUNCTIONS_DIR/functions-and-aliases.sh\""

# install the git-prompt script if not already present
mkdir -p "$HOME/.bash"
if [ ! -f "$HOME/.bash/git-prompt.sh" ]; then
  echo "Downloading git-prompt.sh to $HOME/.bash"
  wget -q -O "$HOME/.bash/git-prompt.sh" https://raw.githubusercontent.com/git/git/fbcdfab34852329929e6bfdd2bac8e49f2e3d8e3/contrib/completion/git-prompt.sh
fi

append_if_missing "$bashrc_file" "source \"\$HOME/.bash/git-prompt.sh\""

git config --global alias.in '!bash -c "git-ops in"'
git config --global alias.out '!bash -c "git-ops out"'
git config --global alias.hist '!bash -c "git-ops hist"'

echo "Installation complete. Restart your shell or run: source $bashrc_file"
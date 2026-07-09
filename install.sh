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

ensure_global_include_path() {
  local include_path="$1"

  if ! git config --global --get-all include.path 2>/dev/null | grep -Fxq -- "$include_path"; then
    git config --global --add include.path "$include_path"
  fi
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir" && git rev-parse --show-toplevel 2>/dev/null || true)"

default_dir="$HOME/.local"
if [ -n "$repo_root" ]; then
  default_dir="$(dirname "$repo_root")"
fi

if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
  echo "Usage: $0 [install_dir]"
  echo "If install_dir is not provided, the default is $default_dir"
  exit 0
fi

if [ -n "${1:-}" ]; then
  install_dir="$1"
else
  if [ -n "$repo_root" ]; then
    echo "Detected a full checkout at $repo_root; defaulting install_dir to its parent: $default_dir"
  fi

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
append_if_missing "$bashrc_file" "export PATH=\"\$PATH:${repo_dir}/bin\""
append_if_missing "$bashrc_file" "source \"${repo_dir}/functions-and-aliases.sh\""

# install the git-prompt script if not already present
mkdir -p "$HOME/.bash"
if [ ! -f "$HOME/.bash/git-prompt.sh" ]; then
  echo "Downloading git-prompt.sh to $HOME/.bash"
  wget -q -O "$HOME/.bash/git-prompt.sh" https://raw.githubusercontent.com/git/git/fbcdfab34852329929e6bfdd2bac8e49f2e3d8e3/contrib/completion/git-prompt.sh
fi

ensure_global_include_path "$repo_dir/config/gitconfig"

echo "Installation complete. Restart your shell or run: source $bashrc_file"

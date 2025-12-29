#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path to the bin directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="$script_dir/bin"

# Check if bin directory exists
if [ ! -d "$bin_dir" ]; then
  echo "Error: bin directory not found at $bin_dir" >&2
  exit 1
fi

# Export line to add
export_line="export PATH=\"$bin_dir:\$PATH\""

# Function to add to file if not already present
add_to_file() {
  local file="$1"
  if [ -f "$file" ]; then
    if grep -Fxq "$export_line" "$file"; then
      echo "✓ Already present in $file"
      return 0
    fi
  fi
  echo "$export_line" >> "$file"
  echo "✓ Added to $file"
}

echo "Installing bash-functions to PATH..."
echo "Binary directory: $bin_dir"
echo

# Add to shell rc files
for rc_file in ~/.bashrc ~/.zshrc; do
  if [ -f "$rc_file" ]; then
    add_to_file "$rc_file"
  fi
done

# Add to ~/.profile for GUI sessions (Alt+F2)
add_to_file ~/.profile

echo
echo "Installation complete!"
echo
echo "Next steps:"
echo "  • For terminal: restart your terminal or run: source ~/.bashrc"
echo "  • For GUI launchers (Alt+F2): log out and log back in"

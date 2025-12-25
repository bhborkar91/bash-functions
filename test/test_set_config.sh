#!/usr/bin/env bash
set -euo pipefail

# Tests for bin/set-config
script="$(pwd)/bin/set-config"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

# 1) Usage: no args -> non-zero exit
if "$script" >/dev/null 2>&1; then
  fail "expected non-zero exit when no args provided"
else
  ok "usage returns non-zero"
fi

# 2) jq missing -> script should exit non-zero with an error
jqpath="$(command -v jq || true)"
if [ -n "$jqpath" ]; then
  jqdir="$(dirname "$jqpath")"
  oldPATH="$PATH"
  # Build a PATH without the directory containing jq
  IFS=':' read -r -a parts <<< "$PATH"
  newPATH=""
  for p in "${parts[@]}"; do
    if [ "$p" != "$jqdir" ]; then
      newPATH="${newPATH:+$newPATH:}$p"
    fi
  done
  export PATH="$newPATH"
  if "$script" >/dev/null 2>&1; then
    PATH="$oldPATH"
    fail "expected non-zero exit when jq is not on PATH"
  fi
  PATH="$oldPATH"
  ok "jq missing behavior"
else
  if "$script" >/dev/null 2>&1; then
    fail "expected non-zero exit when jq is not installed"
  fi
  ok "jq missing behavior (jq not installed)"
fi

# 3) Basic write/update behavior
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq is required for write/update tests" >&2
  exit 0
fi

# create a repo-local tmp dir for tests (developer is responsible for cleanup)
tmp_home="$(mktemp -d -p "$(pwd)/test" tmp_home.XXXXXX)"
export HOME="$tmp_home"

# write a key
if ! "$script" theme dark; then
  fail "failed to write theme=dark"
fi
config="$HOME/.config/bash-function-config.json"
if ! jq -e '.theme=="dark"' "$config" >/dev/null; then
  fail "theme not set to dark"
fi
ok "wrote theme=dark"

# update existing key
if ! "$script" theme light; then
  fail "failed to update theme=light"
fi
if ! jq -e '.theme=="light"' "$config" >/dev/null; then
  fail "theme not updated to light"
fi
ok "updated theme to light"

# write key with spaces
if ! "$script" greeting "hello world"; then
  fail "failed to write greeting"
fi
if ! jq -e '.greeting=="hello world"' "$config" >/dev/null; then
  fail "greeting not set correctly"
fi
ok "wrote greeting with spaces"

# non-object file should be replaced with object containing the new key
printf "[]\n" > "$config"
if ! "$script" newkey value; then
  fail "failed to replace non-object file"
fi
if ! jq -e '.newkey=="value"' "$config" >/dev/null; then
  fail "non-object not replaced with object"
fi
ok "replaced non-object json with object"

# permissions: file should be at least mode 644 (owner writable)
mode=$(stat -c "%a" "$config")
if [ "$mode" -lt 644 ]; then
  fail "unexpected file mode $mode"
fi
ok "permissions ok (mode $mode)"

ok "all write/update tests passed"

# Note: tmp_home is left in the repo's test directory for manual cleanup if desired:
# $ rm -r "$tmp_home"

exit 0

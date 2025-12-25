#!/usr/bin/env bash
set -euo pipefail

# Tests for bin/get-config
script="$(pwd)/bin/get-config"
set_script="$(pwd)/bin/set-config"

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

# For the rest of the tests we require jq
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq is required for read/write tests" >&2
  exit 0
fi

# create a repo-local tmp dir for tests (developer will handle cleanup)
tmp_home="$(mktemp -d -p "$(pwd)/test" tmp_home.XXXXXX)"
export HOME="$tmp_home"

config="$HOME/.config/bash-function-config.json"

# 3) Missing config file -> non-zero exit
if [ -f "$config" ]; then
  fail "expected no config file at start"
fi
if "$script" somekey >/dev/null 2>&1; then
  fail "expected non-zero exit when config missing"
else
  ok "missing config behavior"
fi

# 4) write a key using set-config then read it
if ! "$set_script" taste sweet; then
  fail "set-config failed to write taste=sweet"
fi
val="$($script taste)"
if [ "$val" != "sweet" ]; then
  fail "expected 'sweet', got '$val'"
fi
ok "read value success"

# 5) key not found -> non-zero exit
if "$script" nonexist >/dev/null 2>&1; then
  fail "expected non-zero exit for missing key"
else
  ok "missing key returns non-zero"
fi

# 6) values with spaces
if ! "$set_script" greeting "hello world"; then
  fail "set-config greeting failed"
fi
val="$($script greeting)"
if [ "$val" != "hello world" ]; then
  fail "expected 'hello world', got '$val'"
fi
ok "read value with spaces"

# Note: tmp_home is intentionally left in the repo's test directory for manual inspection/cleanup:
# $ rm -r "$tmp_home"

echo "tmp_home=$tmp_home"
ok "all get-config tests passed"

exit 0

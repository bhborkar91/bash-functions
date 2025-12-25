#!/usr/bin/env bash
set -euo pipefail

# Tests for bin/prompt (terminal mode)
script="$(pwd)/bin/prompt"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

# 1) Single option should print immediately
out="$($script 'Title' $'only')"
if [ "$out" != "only" ]; then
  fail "single option expected 'only', got '$out'"
else
  ok "single-option output"
fi

# For PTY-based interactive tests we require the 'script' command
if ! command -v script >/dev/null 2>&1; then
  echo "SKIP: 'script' command required for pty tests" >&2
  exit 0
fi

# Helper: run command under a pseudo-tty via 'script' and feed it input.
# This constructs a safely quoted command string and uses `script -q -c` so the command runs
# non-interactively and exits after consuming provided stdin.
# Return the last non-empty line from the output (the selected option).
run_with_pty() {
  local input="$1"; shift
  # Build a shell-escaped command string from the args
  local cmd=""
  for a in "$@"; do
    cmd="$cmd $(printf '%q' "$a")"
  done
  if command -v timeout >/dev/null 2>&1; then
    # Use a small timeout to ensure tests don't hang indefinitely
    printf "%s" "$input" | timeout 5s script -q -c "$cmd" /dev/null 2>/dev/null | tr -d '\r' | awk 'NF{line=$0}END{print line}'
  else
    printf "%s" "$input" | script -q -c "$cmd" /dev/null 2>/dev/null | tr -d '\r' | awk 'NF{line=$0}END{print line}'
  fi
}

# Extra test: single option via PTY should print immediately (no input required)
out=$(run_with_pty "" "$script" "Solo" $'only')
if [ "$out" != "only" ]; then
  fail "expected 'only' for single-option PTY run, got '$out'"
else
  ok "single-option PTY output"
fi

# 3) Basic selection: choose option 2 -> expect 'two'
out=$(run_with_pty "2\n" "$script" "Pick" $'one\ntwo\nthree')
if [ "$out" != "two" ]; then
  fail "expected 'two', got '$out'"
else
  ok "selected second option"
fi

# 4) Invalid selection then valid: send '99' then '1' -> expect 'one'
out=$(run_with_pty "99\n1\n" "$script" "Pick" $'one\ntwo')
if [ "$out" != "one" ]; then
  fail "expected 'one' after invalid then valid, got '$out'"
else
  ok "invalid then valid selection"
fi

exit 0

#!/usr/bin/env bash
set -euo pipefail

script="$(pwd)/bin/git-ops"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

strip_ansi() {
  sed -E 's/\x1B\[[0-9;]*m//g'
}

# Build an isolated git environment in repo-local test tmp directory.
workdir="$(mktemp -d -p "$(pwd)/test" tmp_home.XXXXXX)"

origin="$workdir/origin.git"
upstream_work="$workdir/upstream-work"
local_repo="$workdir/local"

git init --bare "$origin" >/dev/null 2>&1

git clone "$origin" "$upstream_work" >/dev/null 2>&1
git -C "$upstream_work" config user.name "Test User"
git -C "$upstream_work" config user.email "test@example.com"

printf "base\n" > "$upstream_work/readme.txt"
git -C "$upstream_work" add readme.txt
git -C "$upstream_work" commit -m "Initial commit" >/dev/null 2>&1
git -C "$upstream_work" branch -M main >/dev/null 2>&1
git -C "$upstream_work" push -u origin main >/dev/null 2>&1
git --git-dir "$origin" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1

git clone "$origin" "$local_repo" >/dev/null 2>&1
if git -C "$local_repo" show-ref --verify --quiet refs/heads/main; then
  git -C "$local_repo" checkout main >/dev/null 2>&1
elif git -C "$local_repo" show-ref --verify --quiet refs/remotes/origin/main; then
  git -C "$local_repo" checkout -b main origin/main >/dev/null 2>&1
else
  fail "expected main branch to exist after clone"
fi
git -C "$local_repo" config user.name "Test User"
git -C "$local_repo" config user.email "test@example.com"

# Create upstream-only commits with one merge commit.
git -C "$upstream_work" checkout -b incoming-feature main >/dev/null 2>&1
printf "incoming feature\n" >> "$upstream_work/readme.txt"
git -C "$upstream_work" add readme.txt
git -C "$upstream_work" commit -m "Incoming feature commit" >/dev/null 2>&1
git -C "$upstream_work" checkout main >/dev/null 2>&1
git -C "$upstream_work" merge --no-ff incoming-feature -m "Merge incoming feature" >/dev/null 2>&1
git -C "$upstream_work" push origin main >/dev/null 2>&1

git -C "$local_repo" fetch origin >/dev/null 2>&1

incoming_default="$(cd "$local_repo" && "$script" in 2>/dev/null | strip_ansi)"
incoming_with_merges="$(cd "$local_repo" && "$script" in --include-merges 2>/dev/null | strip_ansi)"

if echo "$incoming_default" | grep -Fq "Merge incoming feature"; then
  fail "default git-ops in should exclude merge commits"
fi
if ! echo "$incoming_with_merges" | grep -Fq "Merge incoming feature"; then
  fail "git-ops in --include-merges should include merge commits"
fi
ok "incoming merge filtering works"

# Create local-only commits with one merge commit.
git -C "$local_repo" checkout -b outgoing-feature main >/dev/null 2>&1
printf "outgoing feature\n" >> "$local_repo/readme.txt"
git -C "$local_repo" add readme.txt
git -C "$local_repo" commit -m "Outgoing feature commit" >/dev/null 2>&1
git -C "$local_repo" checkout main >/dev/null 2>&1
git -C "$local_repo" merge --no-ff outgoing-feature -m "Merge outgoing feature" >/dev/null 2>&1

outgoing_default="$(cd "$local_repo" && "$script" out 2>/dev/null | strip_ansi)"
outgoing_with_merges="$(cd "$local_repo" && "$script" out --include-merges 2>/dev/null | strip_ansi)"

if echo "$outgoing_default" | grep -Fq "Merge outgoing feature"; then
  fail "default git-ops out should exclude merge commits"
fi
if ! echo "$outgoing_with_merges" | grep -Fq "Merge outgoing feature"; then
  fail "git-ops out --include-merges should include merge commits"
fi
ok "outgoing merge filtering works"

# Invalid arg should return non-zero.
if (cd "$local_repo" && $script in --bad-flag >/dev/null 2>&1); then
  fail "unexpected success for invalid flag"
fi
ok "invalid in/out args are rejected"

ok "all git-ops tests passed"

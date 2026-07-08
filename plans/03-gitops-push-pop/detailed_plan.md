# Detailed plan: git-ops branch-push / branch-pop

## 1) Objective

Extend `git-ops` with two subcommands that let users temporarily jump branches and then return to prior context safely.

Required outcomes:
- Add `branch-push <branch>` to save current git location, then switch to `<branch>`.
- Add `branch-pop` to restore the most recently saved location and remove it from saved state.
- Persist saved state using config keys scoped by repository folder path.
- If repository has uncommitted changes, both commands must no-op.

## 2) Scope constraints

Implementation constraints from the plan:
- `branch-push` must capture current location (branch / commit / tag) before attempting switch.
- If checkout of target branch fails, command must leave state unchanged.
- Saved state must be append-only stack semantics for push and LIFO removal for pop.
- Saved config must be repository-scoped so one repo cannot affect another.

Out of scope:
- Reworking unrelated `git-ops` subcommands.
- Introducing cross-repo global stack behavior.
- Adding or modifying automated tests for this change.

## 3) Current-state verification

Before edits, verify:
1. How `git-ops` currently parses subcommands.
2. How `set-config` and `get-config` are called from scripts in this repo.
3. Existing conventions for repository-scoped config keys (if any).
4. Existing error handling style and exit codes in `bin/git-ops`.
5. Existing tests in `test/test_git_ops.sh` and helper patterns.

## 4) Command behavior design

### 4.1 Shared precondition: clean workspace

For both `branch-push` and `branch-pop`:
1. Run a dirty check (for tracked/untracked changes as per current repo convention).
2. If dirty, print a clear message and exit without modifying config or branch state.

Rationale:
- Avoid accidental context switches with local work in progress.

### 4.2 Repository-scoped key design

Define a deterministic key using absolute repo path, for example:
- Prefix: `git_ops_branch_stack`
- Suffix: sanitized current repo root path
- Final key shape: `git_ops_branch_stack::<repo_root>` (or equivalent safe encoding)

Requirements:
1. Compute repo root via git (`git rev-parse --show-toplevel`).
2. Use that repo root to derive key every time.
3. Ensure no collisions across different paths.

### 4.3 Location capture format

Store one entry per push representing the current location in this priority:
1. Current branch name, if on a branch.
2. Exact tag name, if detached HEAD at a tag.
3. Fallback to commit SHA for detached HEAD without tag.

Persist stack as newline-delimited entries or another robust delimiter already used in repo config values.

### 4.4 `branch-push <branch>` flow

1. Validate argument count and target branch input.
2. Enforce clean-worktree precondition.
3. Resolve current location token (branch/tag/sha).
4. Verify target branch is checkout-able:
   - Attempt checkout in a way that fails fast if branch does not exist.
5. On checkout failure:
   - Print error and exit.
   - Do not write/append saved state.
6. On checkout success:
   - Append saved location token to repo-scoped stack using `set-config`.

Important ordering constraint:
- To satisfy "if cannot checkout, don't do anything", only persist after successful checkout.

### 4.5 `branch-pop` flow

1. Enforce clean-worktree precondition.
2. Read repo-scoped stack from config.
3. If stack is empty/missing, print no-op message and exit successfully.
4. Extract last entry (LIFO top).
5. Attempt checkout to extracted entry.
6. If checkout fails:
   - Keep stack unchanged (do not drop entry).
   - Exit with error.
7. If checkout succeeds:
   - Remove last entry from stack.
   - Persist updated stack with `set-config`.

### 4.6 Error handling and UX

1. Keep messages actionable:
   - Dirty workspace rejection
   - Missing argument
   - Unknown branch for push
   - Empty stack for pop
2. Follow existing output style in `git-ops` (stdout vs stderr) and exit code conventions.

## 5) File-level implementation plan

1. Update `bin/git-ops`:
   - Add subcommand dispatch for `branch-push` and `branch-pop`.
   - Add helper(s): dirty check, repo key generation, current-location resolver, stack append/pop utilities.
2. Reuse `get-config` / `set-config` for storage.
3. Ensure operations are atomic enough for expected shell usage (read-modify-write with immediate set).
4. Avoid changing behavior of existing subcommands.

## 6) Validation checklist

1. `git-ops branch-push main` switches to `main` and records previous location.
2. Repeated pushes create a recoverable stack.
3. `git-ops branch-pop` restores last saved location and removes it from stack.
4. Dirty worktree prevents both commands from making changes.
5. Failed checkout in push leaves stack unchanged.
6. Failed checkout in pop leaves stack unchanged.
7. State is isolated per repository path.
8. Existing `git-ops` behavior outside these subcommands remains unchanged.

## 7) Risks and mitigations

1. Risk: ambiguous saved token in detached HEAD states.
   Mitigation: explicit branch/tag/sha resolution with deterministic fallback.
2. Risk: delimiter issues in serialized stack.
   Mitigation: use newline-safe handling and avoid lossy splitting.
3. Risk: path-based key contains unsafe characters.
   Mitigation: sanitize/encode repo path consistently before key construction.
4. Risk: regressions in existing command parsing.
   Mitigation: keep subcommand additions minimal and manually verify existing command behavior.

## 8) Acceptance criteria

Task is complete when all are true:
1. `git-ops` exposes `branch-push <branch>` and `branch-pop`.
2. Both commands no-op on dirty workspace.
3. `branch-push` stores current location and checks out target branch on success.
4. `branch-push` does not mutate state when checkout fails.
5. `branch-pop` restores last saved location and pops it from stack.
6. `branch-pop` preserves stack when restore checkout fails.
7. Saved config is correctly scoped per repository path.
8. No automated tests are added or modified for this task.

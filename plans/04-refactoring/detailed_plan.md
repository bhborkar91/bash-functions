# Detailed plan: refactoring installation and git-ops top command

## 1) Objective

Turn the high-level refactoring plan into two concrete implementation tracks: packaging/install behavior and a new `git-ops` subcommand.

Required outcomes:
- The install script behaves differently when run from inside the fully checked out repo.
- Installation defaults to the repo parent directory in that case and tells the user what happened.
- `git config` setup is moved out of the install script and into a repo-local `config/gitconfig` file that is included during installation.
- `BASH_FUNCTIONS_DIR` is removed entirely.
- `git-ops` gains a new `top <n>` subcommand that behaves like `hist` but only prints the last `n` commits.
- `top` defaults to `1` when no count is provided.

## 2) Scope constraints

Implementation constraints from the plan:
- Keep installation logic compatible with existing repo layout.
- Avoid preserving the old `git config` commands in the installer once `config/gitconfig` is introduced.
- Remove all `BASH_FUNCTIONS_DIR` references rather than deprecating them.
- Keep `git-ops` changes narrowly focused on the new `top` command.
- Preserve existing `git-ops` subcommand behavior.
- Do not add or modify automated tests as part of this task unless a failure forces the issue.

## 3) Installation design

### 3.1 Detecting an in-repo install

The installer should detect when it is launched from inside the fully checked out repository.

Behavior:
1. Resolve the repository root from the installer location or current working context.
2. Compare the requested install location with the parent directory of the checked out repo.
3. If the installer is running from inside the repo checkout, emit a clear message telling the user that the parent directory will be used as the default install destination.

Reasoning:
- This keeps the installed layout consistent and avoids nesting the checkout inside itself.

### 3.2 `config/gitconfig` inclusion model

Move repository-level git settings into a tracked `config/gitconfig` file in this repo.

Expected flow:
1. Create or update `config/gitconfig` with the desired git config content.
2. During installation, use `git config` to include that file.
3. Remove inline `git config` commands from the install path once the include file is in place.

Design notes:
- The installer should only arrange the include relationship.
- The repo-owned config file should hold the actual git configuration content.
- The include path should be derived in a way that works after installation, not only in the source tree.

### 3.3 Removing `BASH_FUNCTIONS_DIR`

The environment variable should be removed entirely.

Expected behavior:
1. No new code should read or write `BASH_FUNCTIONS_DIR`.
2. Existing code paths should be updated to use the repo layout or derived paths instead.
3. Any install-time messaging or path resolution should not depend on that variable.

Compatibility note:
- This is a hard removal, not a shim or warning period.

## 4) `git-ops` top command design

### 4.1 Command contract

Add a new subcommand:
- `top <n>`: like `hist`, but only display the last `n` commits.

Required behavior:
1. If `n` is provided, use it as the commit count.
2. If `n` is omitted, default to `1`.
3. Preserve the existing style and output conventions used by `git-ops`.

### 4.2 Argument handling

`top` should accept a single optional numeric argument.

Behavior:
1. No argument means show the single most recent commit.
2. A positive integer means show that many commits.
3. Invalid input should follow the command’s existing validation style and error handling.

### 4.3 Relationship to `hist`

`top` should behave like a narrowed version of `hist`.

Implementation intent:
1. Reuse the same commit-history retrieval path where possible.
2. Apply a count limit at the top of the history display logic.
3. Avoid duplicating unrelated history formatting code.

## 5) File-level implementation plan

1. Update the installer:
   - Detect when it is run from inside the repo checkout.
   - Default the install location to the repo parent directory in that case.
   - Print a message explaining the chosen default.
   - Replace inline `git config` setup with an include of `config/gitconfig`.
   - Remove all `BASH_FUNCTIONS_DIR` handling.
2. Add or update `config/gitconfig`:
   - Move the installer-managed git config content into this file.
   - Ensure it is the single source of truth for the included git settings.
3. Update `git-ops`:
   - Add `top` to command parsing and dispatch.
   - Implement the default count of `1`.
   - Reuse existing history display behavior with a commit limit.
4. Review surrounding scripts for stale `BASH_FUNCTIONS_DIR` references and remove them.

## 6) Validation checklist

1. Run the installer from inside the checked out repo and confirm it defaults to the parent directory.
2. Confirm the installer prints the informational message about the chosen install location.
3. Confirm the installer no longer relies on `BASH_FUNCTIONS_DIR`.
4. Confirm the installer includes `config/gitconfig` through `git config` instead of embedding separate config commands.
5. Run `git-ops top` with no argument and confirm it shows only the most recent commit.
6. Run `git-ops top 5` and confirm it shows the last five commits.
7. Confirm existing `git-ops` subcommands still behave as before.

## 7) Risks and mitigations

1. Risk: install-path detection misidentifies nested or symlinked checkouts.
   Mitigation: resolve paths consistently before comparing the checkout location and parent directory.
2. Risk: moving git config into `config/gitconfig` changes include timing.
   Mitigation: keep the include setup in the installer and verify the resulting config is active immediately after install.
3. Risk: `top` duplicates `hist` logic and drifts over time.
   Mitigation: share the underlying history display code and only vary the limit.
4. Risk: removal of `BASH_FUNCTIONS_DIR` leaves stale references in scripts.
   Mitigation: search the repo for every reference and remove or replace them in the same change.

## 8) Acceptance criteria

Task is complete when all are true:
1. Running the install script from inside the fully checked out repo defaults the install directory to the repo parent.
2. The installer emits a message explaining that behavior.
3. `config/gitconfig` exists and is included via `git config` during installation.
4. `git config` setup is no longer hardcoded directly in the installer.
5. `BASH_FUNCTIONS_DIR` is fully removed from the codebase.
6. `git-ops` exposes `top <n>` and defaults to `1` when no argument is provided.
7. `top` displays only the requested number of recent commits.
8. Existing `git-ops` behavior remains unchanged outside the new subcommand.
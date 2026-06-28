# bash-functions

## Description

The purpose of this project is to build an easily-installable repository of common scripts and aliases that I might have use of.

## Installation

Run `./install.sh` to add the `bin/` folder to your PATH. The script:
- Adds the bin directory to `~/.bashrc`, `~/.zshrc` (if they exist), and `~/.profile`
- Is idempotent (won't add duplicates if run multiple times)
- Enables scripts to be called from both terminal and GUI launchers (Alt+F2)

After installation:
- **For terminal**: restart your terminal or run `source ~/.bashrc`
- **For GUI launchers**: log out and log back in

---

## Scripts

- **`bin/set-config`** 🔧
  - Usage: `set-config KEY VALUE`
  - Stores `KEY: VALUE` in `$HOME/.config/bash-function-config.json` (creates the directory/file if missing).
  - Uses `jq` to update JSON safely and writes atomically via a temporary file.

- **`bin/get-config`** 🔎
  - Usage: `get-config KEY [DEFAULT]`
  - Reads `KEY` from `$HOME/.config/bash-function-config.json` and prints the value.
  - If `KEY` is missing, prints `DEFAULT` when provided.
  - Exits non-zero with a clear error if `jq`, the config file, or the key is missing.

- **`bin/repo`** 📁
  - Usage: `repo [-s <search>] [-c] <org>/<repo>` (options can appear before or after the org/repo argument)
  - Checks for the repository at `$HOME/repositories/github.com/<org>/<repo>` and prints the full path if present.
  - If missing, verifies the remote exists and clones `https://github.com/<org>/<repo>.git` into that location, then prints the path. If the remote does not exist, it asks for confirmation before creating and initializing a new local repository in that path and seeds a default `.gitignore`.
  - **`-s <search>`**: Search for repositories in `$HOME/repositories` matching the search string (case-insensitive), present options via `prompt` (displaying `org/repo` without the `$HOME/repositories/github.com` prefix for cleaner output), and print the selected full path.
  - **`-c`**: Open VS Code in the target folder after determining or cloning the repository.

- **`bin/prompt`** 💬
  - Usage: `prompt "Dialog Title" $'option1\noption2\noption3'`
  - When run in a terminal, presents a numbered menu using bash `select` and uses the provided title as the prompt (PS3).
  - When not run from a terminal, uses `zenity --list --title="Dialog Title"` to present a GUI list dialog and prints the selected item.
  - Requires `zenity` for GUI mode.

- **`bin/confirm`** ✅
  - Usage: `confirm "Question?"`
  - When run in a terminal, prompts with `[y/N]` and outputs `y` for yes, `n` otherwise.
  - When not run from a terminal, uses `zenity --question` to ask the same question and outputs `y` or `n` accordingly.
  - Always exits 0; requires `zenity` for GUI mode.

- **`bin/git-ops`** 🌿
  - Usage: `git-ops <subcommand>`
  - Subcommands:
    - `in`: Prints incoming commits (commits in upstream that are not in `HEAD`).
    - `out`: Prints outgoing commits (commits in `HEAD` that are not in upstream).
  - Prints commits in a colorized format:
    `[date] [commit id] message [committer] (branch and tag info)`
  - Output is always newline-terminated.
  - Exits with a clear error when run outside a Git repository or when no upstream is configured for the current branch.

---

## Tests

- Test runner: `./test/run` — runs all `test/test_*.sh` scripts.
- Individual tests:
  - `./test/test_set_config.sh`
  - `./test/test_get_config.sh`
- Note: tests create repo-local temporary directories under `test/` (e.g. `test/tmp_home.XXXXXX`) which are ignored by `.gitignore` and left for manual cleanup.

---

## Development notes

- These scripts depend on `jq` and `git` for JSON handling and cloning respectively. Make sure they are installed.
- GUI flows (`prompt` in GUI mode and `confirm` when not in a terminal) require `zenity`.

---

## Audit / Logs

- Interaction history and prompts used during development are recorded in `prompts.md`. See `./prompts.md` for details.

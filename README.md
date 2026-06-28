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
  - UI mode is controlled by `bash-functions.ui-mode` in config (`set-config bash-functions.ui-mode <value>`).
  - Supported values:
    - `terminal`: always use terminal mode (`select`)
    - `zenity`: always attempt to use `zenity --list`
    - empty/unset: auto mode (if `zenity` is missing use terminal; otherwise choose terminal when interactive and `zenity` when non-interactive)

- **`bin/confirm`** ✅
  - Usage: `confirm "Question?"`
  - UI mode is controlled by `bash-functions.ui-mode` in config (`set-config bash-functions.ui-mode <value>`).
  - Supported values:
    - `terminal`: always prompt in terminal with `[y/N]`
    - `zenity`: always attempt `zenity --question`
    - empty/unset: auto mode (if `zenity` is missing use terminal; otherwise choose terminal when interactive and `zenity` when non-interactive)
  - Outputs `y` for yes and `n` for all other outcomes, and always exits 0.

- **`bin/git-ops`** 🌿
  - Usage: `git-ops <subcommand>`
  - Subcommands:
    - `in`: Prints incoming commits (commits in upstream that are not in `HEAD`).
    - `out`: Prints outgoing commits (commits in `HEAD` that are not in upstream).
    - `hist`: Works like `git log` but prints using the same git-ops format. Extra args are forwarded to `git log`.
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
- `zenity` is only required when a command actually runs in zenity mode (explicitly via `bash-functions.ui-mode=zenity` or auto mode in non-interactive contexts).

---

## Audit / Logs

- Interaction history and prompts used during development are recorded in `prompts.md`. See `./prompts.md` for details.

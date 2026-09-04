# bash-functions

## Description

The purpose of this project is to build an easily-installable repository of common scripts and aliases that I might have use of.

## Installation

Run `./install.sh` to install the project and wire it into your shell. The script:
- Clones this repository to `<install_dir>/bash-functions` (defaults to the parent of the current checkout when run from a full clone, otherwise `$HOME/.local`)
- Adds to `~/.bashrc`:
  - `export PATH="$PATH:<install_dir>/bash-functions/bin"`
  - `source "<install_dir>/bash-functions/functions-and-aliases.sh"`
  - `source "$HOME/.bash/git-prompt.sh"`
- Downloads `git-prompt.sh` to `~/.bash/git-prompt.sh` if it is missing
- Adds `config/gitconfig` from this repo to Git global includes (`git config --global --add include.path ...`), idempotently

After installation:
- **For terminal**: restart your terminal or run `source ~/.bashrc`

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
  - If the config file is missing, prints `DEFAULT` when provided.
  - Exits non-zero with a clear error if `jq` is missing or no value/default can be resolved.

- **`bin/get-credential`** 🔐
  - Usage: `get-credential <key> [--1p] [--1p-label LABEL]`
  - Default mode: prompts for a hidden credential in terminal and prints it.
  - `--1p`: retrieves the value from 1Password CLI (`op item get ...`).
  - `--1p-label LABEL`: selects a specific 1Password field label (default: `password`).

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
      - By default merge commits are excluded; pass `--include-merges` to include them.
    - `out`: Prints outgoing commits (commits in `HEAD` that are not in upstream).
      - By default merge commits are excluded; pass `--include-merges` to include them.
    - `hist`: Works like `git log` but prints using the same git-ops format. Extra args are forwarded to `git log`.
    - `top [n]`: Works like `hist` but only prints the last `n` commits. Defaults to `1`.
    - `branch-push <branch>`: Saves current location (branch/tag/commit) into a per-repo stack and checks out `<branch>`. Refuses to run when the workspace is dirty.
    - `branch-pop`: Checks out the most recently saved location from the per-repo stack. Refuses to run when the workspace is dirty.
  - Prints commits in a colorized format:
    `[date] [commit id] message [committer] (branch and tag info)`
  - Output is always newline-terminated.
  - Exits with a clear error when run outside a Git repository or when no upstream is configured for the current branch.

- **`bin/auto-refresh-config-upsert`** 🔁
  - Usage: `auto-refresh-config-upsert FILE_PATH PRIORITY`
  - Upserts `FILE_PATH` into `$HOME/.config/bash-function-source-config` with integer `PRIORITY`.
  - Keeps config sorted by ascending priority.

- **`bin/auto-refresh-config-list`** 📜
  - Usage: `auto-refresh-config-list`
  - Prints normalized entries from `$HOME/.config/bash-function-source-config` as tab-separated `priority<TAB>path`, sorted ascending.

- **`bin/bf-debug`** 🐞
  - Usage: `bf-debug <message...>`
  - Emits debug logs to stderr only when `BASH_FUNCTIONS_DEBUG=true`.

- **`bin/mp-convert`** 🎵
  - Usage: `mp-convert [-d DIR] [-f FROM_EXT] [-t TO_EXT] [-b BITRATE] [-c CODEC] [--dry-run]`
  - Converts media files from one extension to another using `ffmpeg`.
  - Defaults convert all `.mp4` files in the current directory to `.mp3` using `libmp3lame` at `160k`.
  - Uses `--dry-run` to list the conversions without executing them.
  - Example: `mp-convert -d ~/Videos -f mp4 -t mp3`

- **`bin/mp-trim`** ✂️
  - Usage: `mp-trim -i INPUT -e END [-s START] [-o OUTPUT]`
  - Trims a media file using `ffmpeg` with copy mode.
  - `START` defaults to `00:00:00`.
  - `OUTPUT` defaults to the input filename with `_output` appended; if that file exists, it adds `_1`, `_2`, etc.
  - Example: `mp-trim -i input.mp4 -e 00:03:48`

- **`bin/start-beep`** 🔔
  - Usage: `start-beep`
  - Plays a repeating 1000 Hz beep until interrupted.

---

## Development notes

- Core dependencies: `bash`, `git`, and `jq`.
- `wget` is required by `install.sh` (to fetch `git-prompt.sh`).
- `ffmpeg` is required by `bin/mp-convert` and `bin/mp-trim`.
- `play` is required by `bin/start-beep`.
- `zenity` is only required when a command actually runs in zenity mode (explicitly via `bash-functions.ui-mode=zenity` or auto mode in non-interactive contexts).
- `op` (1Password CLI) is only required when using `get-credential --1p`.

---

## Audit / Logs

- Planning and implementation notes are tracked under `plans/`.

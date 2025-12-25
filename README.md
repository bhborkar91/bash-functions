# bash-functions

## Description

This project serves 2 purposes:
- I want to build a repository of helper shell scripts that can ideally be installed easily whenever I move to a new system / re-install my operating system.
- I want to see what GenAI can do.

So the intent here is to create all the scripts, tests, and documentation solely through GenAI (and of course, read and review them for any unsafe behaviour before using them).

The above description is written by me; if things go well, everything else in this repo will be AI-generated. Ideally, I will also document the prompts used.

---

## Scripts

- **`bin/set-config`** 🔧
  - Usage: `set-config KEY VALUE`
  - Stores `KEY: VALUE` in `$HOME/.config/bash-function-config.json` (creates the directory/file if missing).
  - Uses `jq` to update JSON safely and writes atomically via a temporary file.

- **`bin/get-config`** 🔎
  - Usage: `get-config KEY`
  - Reads `KEY` from `$HOME/.config/bash-function-config.json` and prints the value.
  - Exits non-zero with a clear error if `jq`, the config file, or the key is missing.

- **`bin/repo`** 📁
  - Usage: `repo <org>/<repo>`
  - Checks for the repository at `$HOME/repositories/<org>/<repo>` and prints the full path if present.
  - If missing, verifies the remote exists and clones `https://github.com/<org>/<repo>.git` into that location, then prints the path.

- **`bin/prompt`** 💬
  - Usage: `prompt "Dialog Title" $'option1\noption2\noption3'`
  - When run in a terminal, presents a numbered menu using bash `select` and uses the provided title as the prompt (PS3).
  - When not run from a terminal, uses `zenity --list --title="Dialog Title"` to present a GUI list dialog and prints the selected item.
  - Requires `zenity` for GUI mode.

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

---

## Audit / Logs

- Interaction history and prompts used during development are recorded in `prompts.md`. See `./prompts.md` for details.

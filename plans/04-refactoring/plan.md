# main

create separate detailed_plan.md files for each section below

# installation

if the install script is called from inside the fully checked out repo, echo a message and have the repo's parent dir be the default installation dir
remove the existing `git config` commands and create a `config/gitconfig` file in this repo instead, and during the installation, use `git config` to include the gitconfig file
remove BASH_FUNCTIONS_DIR env var entirely

# commands

add the following subcommand to git-ops:
- top <n>: like hist, but only display the last n commits (default 1 if nothing is passed in)



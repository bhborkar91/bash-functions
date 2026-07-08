add the following subcommands to git-ops:
- branch-push <branch name>
    - save the currently checked out branch / commit / tag using set-config and a key containing the folder path
        - if already exists, then append to it
    - checkout the passed in branch
    - if the passed in branch cannot be checked out, don't do anything
- branch-pop
    - checkout the last appended branch and remove it from the saved config

ensure that saved config is scoped correctly
if the workspace is dirty then don't do anything
don't add tests for this script
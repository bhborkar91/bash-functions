# this section is for auto-reload of the file

require_cmd() {
	local cmd
	cmd="$1"

	command -v "$cmd" >/dev/null 2>&1
}

# this needs to be a function, not a script in bin
# because 
# 1. it sets a variable in the current shell
# 2. it needs to source the target so it must run as a function in the current shell
refresh_source_if_changed() {
	local hash_var="$1"
	local file_path="$2"
	local current_hash

	if ! require_cmd sha256sum; then
		return 1
	fi

	current_hash="$(sha256sum "${file_path}" | awk '{print $1}')"

	if [[ "${current_hash}" != "${!hash_var:-}" ]]; then
        echo "Detected changes in functions-and-aliases.sh. Refreshing functions and aliases..."
		# shellcheck disable=SC1090
		source "${file_path}"

		eval "$hash_var=\"${current_hash}\""
	fi
}

configure_auto_refresh() {
	local hash_var="$1"
	local file_path="$2"

	if ! require_cmd sha256sum; then
		return 1
	fi

	if [[ "$PROMPT_COMMAND" != *"refresh_source_if_changed ${hash_var} \"${file_path}\""* ]]; then
		PROMPT_COMMAND="refresh_source_if_changed ${hash_var} \"${file_path}\"; ${PROMPT_COMMAND:-:}"
	fi
}

configure_auto_refresh "_BASH_FUNCTIONS_HASH" "${BASH_SOURCE[0]}"

# section: vars
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)") \$ '
export GIT_PS1_SHOWUPSTREAM=verbose
export GIT_PS1_SHOWDIRTYSTATE=1

# Section: Aliases
alias fresh='. ~/.bashrc'

alias g='git'
alias ga='git add '
alias gb='git branch '
alias gc='git commit'
alias gcf='git commit --amend -m "$(git log -1 --pretty=%B)"'
alias gco='git checkout '
alias gcp='git cherry-pick '
alias gd='git diff'
alias ghi='git hist'
alias gpu='git push'
alias grb='git rebase '
alias grbi='git rebase -i '
alias gs='git status'
alias gst='git stash'
alias gsta='git stash apply'
alias gstp='git stash pop'


# section: Functions

function venv(){
    if ! [ -d venv ]; then
        python3 -m venv venv
    fi
    . venv/bin/activate
}


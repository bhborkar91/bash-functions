# this section is for auto-reload of the file

require_cmd() {
	local cmd
	cmd="$1"

	command -v "$cmd" >/dev/null 2>&1
}

refresh_functions_and_aliases_if_changed() {
	local file_path
	local current_hash

	if [[ -z "${BASH_FUNCTIONS_DIR:-}" ]]; then
		return 1
	fi

	file_path="${BASH_FUNCTIONS_DIR}/functions-and-aliases.sh"
	if [[ ! -f "${file_path}" ]]; then
		return 1
	fi

	if ! require_cmd sha256sum; then
		return 1
	fi

	current_hash="$(sha256sum "${file_path}" | awk '{print $1}')"

	if [[ "${current_hash}" != "${_BASH_FUNCTIONS_HASH:-}" ]]; then
        echo "Detected changes in functions-and-aliases.sh. Refreshing functions and aliases..."
		# shellcheck disable=SC1090
		source "${file_path}"

		_BASH_FUNCTIONS_HASH="$(sha256sum "${file_path}" | awk '{print $1}')"
	fi
}

if [[ "$PROMPT_COMMAND" != *"refresh_functions_and_aliases_if_changed"* ]]; then
    PROMPT_COMMAND="refresh_functions_and_aliases_if_changed; ${PROMPT_COMMAND:-:}"
fi

# section: vars

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)") \$ '

# Section: Aliases

alias g='git'
alias ga='git add '
alias gb='git branch '
alias gc='git commit'
alias gcf='git commit --amend -m "$(git log -1 --pretty=%B)"'
alias gco='git checkout '
alias gcp='git cherry-pick '
alias gd='git diff'
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


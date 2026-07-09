# this section is for auto-reload of the file

require_cmd() {
	local cmd
	cmd="$1"

	command -v "$cmd" >/dev/null 2>&1
}

_bf_debug() {
	if require_cmd bf-debug; then
		bf-debug "$@"
	fi
}

_auto_refresh_hash_var_for_path() {
	local file_path="$1"
	local digest

	digest="$(printf '%s' "$file_path" | sha256sum | awk '{print $1}')"
	printf '_AUTO_REFRESH_HASH_%s\n' "${digest:0:16}"
}

_auto_refresh_file_hash() {
	local file_path="$1"

	if [ ! -r "$file_path" ]; then
		return 1
	fi

	sha256sum "$file_path" | awk '{print $1}'
}

refresh_sources() {
	local -a entries
	local line path hash_var previous_hash current_hash
	local i first_changed=-1

	_bf_debug "refresh_sources: start"

	if ! require_cmd auto-refresh-config-list; then
		_bf_debug "refresh_sources: auto-refresh-config-list not found, skipping"
		return 0
	fi

	mapfile -t entries < <(auto-refresh-config-list)
	if [ "${#entries[@]}" -eq 0 ]; then
		_bf_debug "refresh_sources: no configured files, skipping"
		return 0
	fi
	_bf_debug "refresh_sources: loaded ${#entries[@]} configured file(s)"

	for i in "${!entries[@]}"; do
		line="${entries[$i]}"
		path="${line#*$'\t'}"
		if [[ "$path" != /* ]]; then
			echo "Warning: skipping non-absolute auto-refresh path: $path" >&2
			_bf_debug "refresh_sources: skipping non-absolute path during change detection $path"
			continue
		fi
		_bf_debug "refresh_sources: checking hash for $path"
		current_hash="$(_auto_refresh_file_hash "$path" 2>/dev/null || true)"
		if [ -z "$current_hash" ]; then
			_bf_debug "refresh_sources: unable to hash unreadable/missing file $path"
			continue
		fi

		hash_var="$(_auto_refresh_hash_var_for_path "$path")"
		previous_hash="${!hash_var:-}"

		if [ "$current_hash" != "$previous_hash" ]; then
			_bf_debug "refresh_sources: change detected at index $i for $path"
			first_changed="$i"
			break
		else
			_bf_debug "refresh_sources: no change for $path"
		fi
	done

	if [ "$first_changed" -lt 0 ]; then
		_bf_debug "refresh_sources: no changes detected across all configured files"
		return 0
	fi
	_bf_debug "refresh_sources: cascading re-source from index $first_changed"

	for (( i=first_changed; i<${#entries[@]}; i++ )); do
		line="${entries[$i]}"
		path="${line#*$'\t'}"

		if [[ "$path" != /* ]]; then
			echo "Warning: skipping non-absolute auto-refresh path: $path" >&2
			_bf_debug "refresh_sources: skipping non-absolute path during cascade $path"
			continue
		fi

		if [ ! -r "$path" ]; then
			echo "Warning: unable to read auto-refresh file: $path" >&2
			_bf_debug "refresh_sources: skipping unreadable file during cascade $path"
			continue
		fi

		echo "Auto-refresh sourcing: $path"
		_bf_debug "refresh_sources: sourcing $path"
		# shellcheck disable=SC1090
		if ! source "$path"; then
			_bf_debug "refresh_sources: source failed for $path"
			return 1
		fi

		current_hash="$(_auto_refresh_file_hash "$path")"
		hash_var="$(_auto_refresh_hash_var_for_path "$path")"
		printf -v "$hash_var" '%s' "$current_hash"
		_bf_debug "refresh_sources: updated hash var $hash_var for $path"
	done

	_bf_debug "refresh_sources: completed"
}

configure_auto_refresh() {
	echo "Warning: configure_auto_refresh is deprecated and has no effect." >&2
	return 0
}

if [[ "$PROMPT_COMMAND" != *"refresh_sources"* ]]; then
	PROMPT_COMMAND="refresh_sources; ${PROMPT_COMMAND:-:}"
fi

auto-refresh-config-upsert "${BASH_SOURCE[0]}" "10"

# section: vars
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)") \n\$ '
export GIT_PS1_SHOWUPSTREAM=verbose
export GIT_PS1_SHOWDIRTYSTATE=1

# Section: Aliases
alias fresh='. ~/.bashrc'

alias g='git'
alias ga='git add '
alias gb='git branch '
alias gbpu='git branch-push'
alias gbpo='git branch-pop'
alias gc='git commit'
alias gcf='git commit --amend -m "$(git log -1 --pretty=%B)"'
alias gco='git checkout '
alias gcp='git cherry-pick '
alias gd='git diff'
alias ghi='git hist'
alias gm='git merge '
alias gpl='git pull'
alias gpu='git push'
alias grb='git rebase '
alias grbi='git rebase -i '
alias gs='git status'
alias gst='git stash'
alias gsta='git stash apply'
alias gstp='git stash pop'
alias gto='git top'

# section: Functions

function venv(){
    if ! [ -d venv ]; then
        python3 -m venv venv
    fi
    . venv/bin/activate
}


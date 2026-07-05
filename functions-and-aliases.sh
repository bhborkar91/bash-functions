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

		printf -v "$hash_var" '%s' "${current_hash}"
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

		if [ ! -r "$path" ]; then
			echo "Warning: unable to read auto-refresh file: $path" >&2
			_bf_debug "refresh_sources: skipping unreadable file during cascade $path"
			continue
		fi

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
	local hash_var="$1"
	local file_path="$2"
	local priority="${3:-20}"

	if ! require_cmd sha256sum; then
		return 1
	fi

	if require_cmd auto-refresh-config-upsert && [[ "$priority" =~ ^-?[0-9]+$ ]]; then
		auto-refresh-config-upsert "$file_path" "$priority" >/dev/null 2>&1 || true
	fi

	if [[ "$PROMPT_COMMAND" != *"refresh_source_if_changed ${hash_var} \"${file_path}\""* ]]; then
		PROMPT_COMMAND="refresh_source_if_changed ${hash_var} \"${file_path}\"; ${PROMPT_COMMAND:-:}"
	fi

	if [[ "$PROMPT_COMMAND" != *"refresh_sources"* ]]; then
		PROMPT_COMMAND="refresh_sources; ${PROMPT_COMMAND:-:}"
	fi
}

configure_auto_refresh "_BASH_FUNCTIONS_HASH" "${BASH_SOURCE[0]}" 20

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


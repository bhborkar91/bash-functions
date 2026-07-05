use a function added to prompt command to do the following:
- iterate over the files in bash-function-source-config (can use auto-refresh-config-list for this)
- check each one for changes in hash value
- if any of them changes, re-source that file and the files after it in priority order, and re-calculate their hashes
- hashes can be stored as shell vars

additional details
- keep code in functions and aliases file to a minimum
- if any code used by the functions does not need to modify shell vars, a file can be created in the bin folder
- don't add test cases
- configure_auto_refresh should keep working as it is currently for backwards compatibility (thus so must its dependent function refresh_source_if_changed; create a new function refresh_sources for this new requirement)
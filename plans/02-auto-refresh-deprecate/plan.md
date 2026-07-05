the function configure_auto_refresh should only log a deprecation warning and not do anything. update calls to it
remove the refresh_sources_if_changed function
add an actual log (non debug) to refresh_sources when the file is actually being sourced. ensure to log full file path
ensure that only absolute paths are sourced. relative paths must not be sourced.
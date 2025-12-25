# Tests for set-config

Requirements:
- jq

Run all tests:

```
./test/run
```

Individual tests:

```
./test/test_set_config.sh
./test/test_get_config.sh
```

Note: tests create repo-local temporary directories under `test/` (e.g. `test/tmp_home.XXXXXX`). These are intentionally left for manual inspection and cleanup; they are ignored by `.gitignore`.
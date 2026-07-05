# Detailed plan: auto refresh based on config priority

## 1) Objective

Add a new prompt-time refresh function `refresh_sources` that works across all files registered in `bash-function-source-config` and refreshes in priority order, while keeping existing `refresh_source_if_changed` behavior intact for compatibility.

Required outcomes:
- New function `refresh_sources` iterates files from `auto-refresh-config-list`.
- It compares current hash with stored hash for each file.
- If a file changes, it re-sources that file and all lower-priority files after it.
- Hashes are kept in shell variables.
- `functions-and-aliases.sh` stays minimal.
- Helper logic that does not need shell variable mutation stays in `bin/` scripts.
- No new tests are added.
- `configure_auto_refresh` remains backward compatible.
- Existing `refresh_source_if_changed` remains backward compatible as a dependent function.

## 2) Scope constraints

Implementation constraints from the updated plan:
- Keep heavy logic out of `functions-and-aliases.sh`.
- Reuse `auto-refresh-config-list` for ordered file iteration.
- Use shell variables as the source of truth for previous hashes.
- Do not change behavior of existing `configure_auto_refresh` callers.
- Do not break existing callers of `refresh_source_if_changed`.
- Do not add or expand automated test cases in this task.

## 3) Execution design

### 3.1 Input source and ordering

`refresh_sources` must:
1. Call `auto-refresh-config-list` to retrieve configured files in priority order.
2. Iterate through that ordered list exactly once to detect first changed file.

Assumption:
- `auto-refresh-config-list` already emits stable priority order; if it does not, fix ordering there (in `bin/`, not shell function body).

### 3.2 Hash tracking model

For each configured path:
1. Calculate the current hash.
2. Read the previous hash from a path-derived shell variable.
3. Detect first change index where current hash differs from previous hash.

Hash variable rules:
- One deterministic variable name per file path.
- Valid shell identifier format.
- Reused across prompt evaluations in same shell session.

### 3.3 Cascade refresh behavior

Once first changed file is found at index `i`:
1. Source file `i`.
2. Continue sourcing all files `i+1 ... end` in priority order.
3. Recompute and store hashes for every re-sourced file.

If no changed file is found:
- Return without sourcing any file.

### 3.4 Backward compatibility for configure_auto_refresh

`configure_auto_refresh` should continue to work for existing usage patterns.

Compatibility expectations:
- Existing invocation patterns remain valid.
- Prompt hook behavior remains idempotent.
- Any new registration handling should not break earlier config assumptions.

### 3.5 Backward compatibility for refresh_source_if_changed

`refresh_source_if_changed` should continue to behave as it does today for existing consumers.

Compatibility expectations:
- Existing call signatures remain valid.
- Existing single-file hash/source flow remains available.
- New priority logic is introduced via a separate function rather than replacing current behavior.

## 4) Placement of logic

### Keep in functions-and-aliases.sh

- Prompt hook wiring.
- File `source` operations.
- Shell hash variable read/write and indirection.

### Keep in bin/

- Config listing/upsert and ordering logic.
- Hash helper logic if it does not need to mutate shell vars directly.
- Any text processing/parsing work that can be externalized.

## 5) Implementation steps

1. Confirm `auto-refresh-config-list` provides ordered entries suitable for prompt-time iteration.
2. Implement `refresh_sources` to:
   - load ordered entries,
   - detect first changed file,
   - cascade source from first changed file onward,
   - refresh shell hash vars for re-sourced files.
3. Keep/adjust helper(s) for deterministic hash variable naming.
4. Keep `refresh_source_if_changed` behavior unchanged and wire the new function from prompt logic without breaking compatibility.
5. Validate `configure_auto_refresh` still supports existing callers while integrating with multi-file config flow.
6. Keep shell file concise by moving non-shell-state operations to `bin/` where needed.

## 6) Manual validation checklist (no tests added)

1. Register multiple files with distinct priorities.
2. Verify `auto-refresh-config-list` returns them in expected order.
3. Change a middle-priority file and verify that file plus all subsequent files are re-sourced.
4. Change highest-priority file and verify full ordered re-source.
5. Confirm hash shell vars update after each refresh cycle.
6. Confirm existing `configure_auto_refresh` workflows still behave as before.
7. Confirm existing `refresh_source_if_changed` call paths continue to work unchanged.

## 7) Acceptance criteria

Task is complete when all are true:
1. `refresh_sources` iterates configured files from `auto-refresh-config-list`.
2. Change detection uses per-file shell hash variables.
3. On first detected change, refresh cascades from that file to the end in priority order.
4. Hashes are recalculated and stored for all re-sourced files.
5. `functions-and-aliases.sh` remains minimal, with non-shell-state logic in `bin/`.
6. `configure_auto_refresh` remains backward compatible.
7. `refresh_source_if_changed` remains backward compatible.
8. No new automated tests are introduced.

# Detailed plan: centralized debug logging with bf-debug

## 1) Objective

Add a reusable executable script `bf-debug` and use it to add debug logging across all branches of `refresh_sources` in `functions-and-aliases.sh`.

Required outcomes:
- A new executable script `bf-debug` exists.
- `bf-debug` writes to `stderr` only when `BASH_FUNCTIONS_DEBUG=true`.
- All meaningful decision branches in `refresh_sources` emit debug logs through `bf-debug`.
- Existing behavior stays unchanged when debug mode is off.

## 2) Scope constraints

Implementation constraints from the plan:
- Keep changes focused on debug instrumentation.
- Use the new `bf-debug` helper instead of inline `echo`/`printf` debug statements.
- Do not alter functional behavior of refresh logic.

## 3) Design decisions

### 3.1 `bf-debug` contract

Input:
- Accept debug message arguments as CLI args.

Behavior:
1. Check whether `BASH_FUNCTIONS_DEBUG` equals `true`.
2. If true, print a prefixed message to `stderr`.
3. If false/unset, do nothing and exit successfully.

Output:
- Logs are emitted to `stderr` only.
- Script is side-effect free besides optional output.

### 3.2 Logging strategy for `refresh_sources`

Add logs to cover each branch/state transition, including:
1. Start of `refresh_sources` execution.
2. No configured files found.
3. Per-file hash check path.
4. First changed file detected.
5. No change detected for a file.
6. Cascade re-source start.
7. Each file re-sourced in cascade.
8. Hash update completion.
9. No changes detected across all files.
10. Function completion.

Notes:
- Keep log lines concise and stable for troubleshooting.
- Include filename/path and branch reason when useful.

## 4) File-level implementation plan

1. Create `bin/bf-debug`:
   - Add shebang.
   - Implement env var gate on `BASH_FUNCTIONS_DEBUG`.
   - Emit message to `stderr` when enabled.
2. Make `bin/bf-debug` executable.
3. Update `functions-and-aliases.sh`:
   - Introduce `bf-debug` calls in all branches of `refresh_sources`.
   - Replace any ad-hoc debug output in that function (if present) with `bf-debug`.
4. Keep command usage consistent with existing `bin/` helper invocation patterns.

## 5) Branch coverage checklist for `refresh_sources`

Ensure at least one `bf-debug` message for each branch:
1. Entry branch.
2. Empty config/list branch.
3. Changed hash branch.
4. Unchanged hash branch.
5. Cascade refresh branch.
6. No refresh needed branch.
7. Exit branch.

## 6) Manual validation checklist

1. `chmod +x bin/bf-debug` applied and script runs.
2. With `BASH_FUNCTIONS_DEBUG` unset, run code path: no debug logs should appear.
3. With `BASH_FUNCTIONS_DEBUG=false`, no debug logs should appear.
4. With `BASH_FUNCTIONS_DEBUG=true`, debug logs should appear on `stderr`.
5. Trigger each `refresh_sources` branch and verify corresponding debug output is present.
6. Confirm non-debug behavior/output remains unchanged.

## 7) Acceptance criteria

Task is complete when all are true:
1. `bin/bf-debug` exists and is executable.
2. `bf-debug` logs only when `BASH_FUNCTIONS_DEBUG=true`.
3. `bf-debug` logs are sent to `stderr`.
4. All branches in `refresh_sources` have debug instrumentation via `bf-debug`.
5. Behavior of `refresh_sources` is unchanged when debug is disabled.

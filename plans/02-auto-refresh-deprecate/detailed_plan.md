# Detailed plan: deprecate configure_auto_refresh and simplify refresh flow

## 1) Objective

Align auto-refresh behavior with the deprecation direction by making `configure_auto_refresh` a no-op (with warning), removing redundant refresh API surface, and improving user-visible sourcing logs.

Required outcomes:
- `configure_auto_refresh` only emits a deprecation warning and performs no setup/action.
- All call sites that still rely on `configure_auto_refresh` are updated.
- `refresh_sources_if_changed` is removed.
- `refresh_sources` emits a normal (non-debug) log when it actually sources a file.
- The sourcing log includes the full file path.
- `refresh_sources` only sources absolute paths; relative paths are never sourced.

## 2) Scope constraints

Implementation constraints from the plan:
- Do not leave side effects in `configure_auto_refresh`.
- Keep logging intent clear: deprecation warning for deprecated function, operational info log for actual sourcing.
- Remove `refresh_sources_if_changed` cleanly (definition and references).
- Enforce absolute-path-only sourcing in `refresh_sources`.

Out of scope:
- New feature additions unrelated to deprecation and logging.
- Large refactors outside the auto-refresh path.

## 3) Current-state verification

Before edits, confirm:
1. Where `configure_auto_refresh` is defined.
2. Every internal invocation/caller of `configure_auto_refresh`.
3. Where `refresh_sources_if_changed` is defined and referenced.
4. Existing logging behavior inside `refresh_sources` and current log formatting.
5. How configured paths are validated before sourcing (absolute vs relative).

## 4) Design decisions

### 4.1 `configure_auto_refresh` behavior

New contract:
1. Print a deprecation warning message (once per invocation).
2. Return success (or existing expected code if current callers rely on it).
3. Perform no registration, no hook wiring, and no refresh action.

Rationale:
- Preserves compatibility for callers while preventing continued functional dependency.

### 4.2 Call-site migration

For each call site currently using `configure_auto_refresh`:
1. Remove the call if it is no longer needed.
2. Or replace it with the direct modern flow already used by the codebase.
3. Ensure startup/prompt behavior remains correct after removal.

### 4.3 Remove `refresh_sources_if_changed`

Removal scope:
1. Delete function definition.
2. Delete or migrate all references.
3. Ensure no broken calls remain.

Rationale:
- Consolidate behavior around `refresh_sources` and reduce duplicate pathways.

### 4.4 Operational logging in `refresh_sources`

Add a normal log (not gated by debug mode) exactly when a file is sourced.

Logging requirements:
1. Message should clearly indicate a source action occurred.
2. Include full file path (absolute or full resolved string as used in the source command).
3. Avoid emitting this log when no sourcing occurs.

### 4.5 Absolute-path-only sourcing

Path policy requirements:
1. `refresh_sources` must source only paths that are absolute (`/`-prefixed).
2. Relative paths must be skipped and never passed to `source`.
3. Skipped relative paths should produce a clear warning log (non-debug) so misconfiguration is visible.

Rationale:
- Prevent sourcing ambiguity and cwd-dependent behavior.

## 5) Implementation steps

1. Locate and update `configure_auto_refresh` implementation to deprecation-warning-only behavior.
2. Find and update all call sites of `configure_auto_refresh`.
3. Remove `refresh_sources_if_changed` definition.
4. Remove or migrate any remaining references to `refresh_sources_if_changed`.
5. Update `refresh_sources` to emit a non-debug log for each actual source action with full path.
6. Update `refresh_sources` to skip non-absolute configured paths and log a warning when skipped.
7. Run shell checks/tests used by this repository to confirm no regressions.

## 6) Validation checklist

1. Calling `configure_auto_refresh` prints deprecation warning and does nothing else.
2. No code path depends on side effects from `configure_auto_refresh`.
3. `refresh_sources_if_changed` no longer exists in the codebase.
4. Search shows no stale references to `refresh_sources_if_changed`.
5. When `refresh_sources` sources a file, a non-debug log is emitted.
6. The log line contains the full path for each sourced file.
7. When no files are sourced, no operational source log is emitted.
8. Relative configured paths are skipped with warning and are never sourced.
9. Existing relevant tests/scripts pass.

## 7) Risks and mitigations

1. Risk: hidden callers still expect `configure_auto_refresh` side effects.
   Mitigation: global search for callers and verify runtime startup flow manually.
2. Risk: removing `refresh_sources_if_changed` leaves broken references.
   Mitigation: full-text search and run repo tests after removal.
3. Risk: new operational logs become noisy.
   Mitigation: log only on actual source events and keep message concise.
4. Risk: existing configs include relative paths and stop auto-refreshing unexpectedly.
   Mitigation: emit a clear warning for each skipped relative path and document absolute path requirement.

## 8) Acceptance criteria

Task is complete when all are true:
1. `configure_auto_refresh` only emits a deprecation warning and otherwise no-ops.
2. All usages of `configure_auto_refresh` are updated to not rely on old behavior.
3. `refresh_sources_if_changed` is removed from implementation and references.
4. `refresh_sources` emits a non-debug log only when sourcing occurs.
5. Each source log includes the full file path.
6. `refresh_sources` never sources relative paths and logs warning when they are encountered.
7. Relevant checks/tests pass without introducing new failures.

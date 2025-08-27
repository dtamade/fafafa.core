# Next Round Unfreeze Scope · Symlink Robustness (Tests-First)

Status: Proposed (awaiting owner confirmation)
Date: 2025-08-14

## Scope (minimal)
- Focus only on symlink robustness in Walk/Path resolution
- No default behavior changes; no new public APIs
- Work starts with tests; code changes subject to approval after triage

## Objectives
- Validate behavior with:
  1) Deep symlink chains (A->B->C->...)
  2) Self-loop (A->A) and small cycles (A->B->A)
  3) Parent-loop (A->../A)
  4) Interaction with MaxDepth boundaries
- Ensure FollowSymlinks=False remains unaffected

## Deliverables
- Tests: new unit(s) in tests/fafafa.core.fs exercising the above cases
- Report: outcomes and whether fixes are necessary
- If needed: proposal for minimal fix (visited-set + depth guard when FollowSymlinks=True)

## Acceptance Criteria
- Tests compile and run; default environment skips only when lacking permission
- On Unix, tests pass with FollowSymlinks toggled and with varying MaxDepth
- No regressions in existing test suite
- Documentation updated only if behavior differences are discovered

## Out of Scope
- Performance optimizations (tracked separately)
- New public APIs; changing defaults
- Cross-module changes

## Notes
- Windows symlink tests are opt-in (FAFAFA_TEST_SYMLINK=1) due to policy/permissions
- Ensure robust cleanup of links and target files


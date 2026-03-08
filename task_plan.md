# Task Plan: SIMD Windows closeout to cross-platform ready

## Goal
Bring `fafafa.core.simd` to a truthful `Cross-platform ready` state by preserving Linux green status, obtaining real Windows B07 evidence, finalizing closeout docs, and verifying `freeze-status` returns `ready=True`.

## Current Phase
Phase 5

## Phases

### Phase 1: Baseline & Discovery
- [x] Confirm Linux mainline gate baseline
- [x] Confirm Windows evidence is the only real blocker
- [x] Record current state in planning files
- **Status:** complete

### Phase 2: Linux No-Regression
- [x] Re-run Linux evidence path
- [x] Re-run isolated Linux gate
- [x] Re-run backend bench
- **Status:** complete

### Phase 3: Windows Evidence Enablement
- [x] Diagnose Windows CI blockers
- [x] Fix workflow checkout / staging / toolchain path issues
- [x] Fix Windows batch collector / verifier / dispatch issues
- **Status:** complete

### Phase 4: Windows Evidence & Closeout
- [x] Produce real `windows_b07_gate.log`
- [x] Verify Windows evidence with strict verifier
- [x] Generate Windows closeout summary
- [x] Apply roadmap / RC / matrix closeout updates
- **Status:** complete

### Phase 5: Freeze & Handoff
- [x] Refresh `freeze-status` to `ready=True`
- [x] Update `docs/fafafa.core.simd.handoff.md`
- [x] Update `findings.md` and `progress.md`
- **Status:** complete

## Key Questions
1. Is Linux still green after closeout changes? → Yes.
2. Is Windows evidence real and verifier-clean? → Yes.
3. Is cross-platform freeze now ready? → Yes.

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Use file-based planning plus existing `findings.md` / `progress.md` | Keep long closeout work persistent and resumable |
| Use Linux staging artifact + Windows download in workflow | Avoid Windows checkout invalid-path blocker |
| Keep verifier strict and only add CRLF normalization | Preserve acceptance criteria while supporting Windows line endings |
| Use explicit Windows collector closeout steps | Remove fragile dependency on historical batch gate path |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| GitHub Actions billing blocked Windows run | 1 | Switched after account/public repo change; reran workflow |
| Windows checkout invalid path | 2 | Reworked workflow to Linux-stage source and Windows-download artifact |
| Windows batch self/root resolution failures | 3 | Added explicit root handling and simplified collector/verifier flow |
| Windows verifier failed on CRLF logs | 4 | Normalize `\r` in verifier before regex checks |
| Windows evidence workflow path/dispatch regressions | 5 | Inline dispatch and direct workflow invocation of collector+verifier |

## Notes
- Final batch id: `SIMD-20260309-152`
- Final platform claim: `Cross-platform ready`
- Evidence anchor: `tests/fafafa.core.simd/logs/windows_b07_gate.log`

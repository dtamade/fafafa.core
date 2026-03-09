# Task Plan: SIMD full-platform completion (RISCVV / QEMU)

## Goal
Bring `fafafa.core.simd` beyond current cross-platform ready status to a stronger full-platform completion state by closing non-x86 / QEMU evidence gaps and advancing RISCVV from opt-in experimental scaffolding toward a verifiable, documented implementation boundary.

## Current Phase
Phase 3

## Phases

### Phase 1: Scope Reset & Discovery
- [ ] Define what “全平台完整实现” means for this repo
- [ ] Identify RISCVV code, tests, and docs gaps
- [ ] Identify QEMU / non-x86 evidence gaps
- **Status:** complete

### Phase 2: Design & Acceptance Criteria
- [x] Decide target maturity boundary for RISCVV
- [x] Decide which QEMU scenarios must become required
- [x] Write decisions into findings / progress
- **Status:** complete

### Phase 3: Implementation
- [ ] Implement code / scripts / doc changes for RISCVV and QEMU
- [ ] Keep Linux mainline green
- [ ] Avoid weakening existing verifier / closeout guarantees
- **Status:** in_progress

### Phase 4: Verification
- [ ] Run Linux baseline checks
- [ ] Run QEMU / non-x86 evidence checks
- [ ] Re-evaluate freeze / completion outputs
- **Status:** pending

### Phase 5: Delivery
- [ ] Update handoff / findings / progress / docs
- [ ] State final platform claim precisely
- **Status:** pending

## Key Questions
1. Should RISCVV remain experimental but fully evidenced, or become part of stable/platform-complete support?
2. Which QEMU evidence paths must become required for “full-platform complete”?
3. What is the minimum truthful claim we can make after implementation?

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Start from the now-green Windows closeout baseline | Avoid mixing old blockers with new non-x86 scope |
| Treat QEMU / RISCVV as a new completion phase | Keeps planning files and verification boundaries clear |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |

## Notes
- Preserve current `freeze-status` success while extending the evidence/completeness bar.
- Do not relax Windows evidence or existing stable-path checks.
- Chosen scope: stable/public surface across x86/arm/riscv + evidenced RISCVV boundary; not “implement every experimental AVX2 intrinsic before any platform claim.”

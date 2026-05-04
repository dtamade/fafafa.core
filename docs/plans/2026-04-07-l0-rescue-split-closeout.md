# 2026-04-07 L0 Rescue Split Closeout

## Goal

Finish L0 control-plane cleanup after PR `#6` without dragging SIMD-side rescue material back through the L0 lane.

## Ground rules

- `main` is anchored at merge commit `7b5e9e7f`.
- L0 work continues in the follow-up branch `l0-main-followup-20260407`.
- The root worktree on branch `main` stays untouched because it is user-dirty and behind remote.
- `l0-main-rescue` is a source snapshot only. It is not a merge target.
- SIMD implementation, closeout scripts, and CI evidence remain owned outside L0.

## Phase map

### Phase 1: Merge and re-verify L0 on top of `main`

Status: complete

Completed work:

- merged PR `#6` with a merge commit
- fetched `origin/main`
- cut follow-up branch `l0-main-followup-20260407`
- re-ran the L0 verification set on top of merged main

Exit criteria:

- merged main is green for the L0 surface
- L0 follow-up work is no longer tied to the old promotion branch

### Phase 2: Remove mainline control-plane pollution

Status: complete

Completed work:

- archived the old root working set under `plans/archive/2026-04-07-mainline-working-set/`
- replaced root `task_plan.md`, `findings.md`, and `progress.md` with archive pointers
- refreshed `docs/INDEX.md`, `docs/README.md`, `plans/README.md`, `backlog.md`, and `workers/worker1.md`
- added a fresh audit and follow-up roadmap

Exit criteria:

- mainline points to stable docs instead of giant working logs
- L0 ownership and entry points are current again

### Phase 3: Split non-SIMD rescue candidates into reviewable batches

Status: pending

Planned batches:

1. repo tooling and verification helpers
2. base/atomic/option/result example script fixes
3. allocator and time-tick implementation deltas
4. documentation cleanup that is not SIMD-owned

Rules:

- each batch must be independently reviewable
- each batch must have a fresh verification command list
- no SIMD-only file comes through this lane

### Phase 4: Hand off SIMD-only rescue residue

Status: pending

Scope:

- `tests/fafafa.core.simd/**`
- `.github/workflows/simd-*`
- `docs/fafafa.core.simd*`
- other closeout and evidence helpers tied to SIMD ownership

Exit criteria:

- the SIMD owner gets a clean handoff list
- L0 follow-up stops carrying SIMD control-plane debt

### Phase 5: Run one more root-clutter sweep

Status: pending

Targets:

- root `*_REPORT.md`
- `WORKING*.md`
- one-off helper scripts that are no longer tied to a current module entry point

Exit criteria:

- remaining root files are either stable repo entry points or explicitly archived

## Verification run for Phase 1

Run:

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
```

Then:

```bash
bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts
bash examples/fafafa.core.contracts/BuildOrRun.sh run
bash examples/fafafa.core.platform/BuildOrRun.sh run
git diff --check
```

Result: all checks passed on `2026-04-07`.

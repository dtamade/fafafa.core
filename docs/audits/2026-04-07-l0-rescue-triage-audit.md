# 2026-04-07 L0 Rescue Triage Audit

## Read this first

This audit answers one question: what is still worth touching after L0 promotion PR `#6` merged, and what should stay out of the L0 lane.

Short version:

- `main` is now anchored by merge commit `7b5e9e7f`.
- `l0-main-rescue` is a mixed snapshot, not a merge target.
- Most of the rescue-only diff is SIMD and CI evidence work, which is outside L0 ownership.
- The first cleanup batch should focus on control-plane pollution on `main`, not on bulk-merging rescue.

## Scope and evidence

Compared snapshots:

- merged main anchor: `7b5e9e7f` (`Merge pull request #6 from dtamade/l0-main-promotion-20260407`)
- promotion anchor commit: `2ea1e94b` (`feat(core): curate strict l0 foundation wave`)
- rescue snapshot: `ecfc1c3f`

Primary diff reviewed:

```bash
git diff --name-status l0-main-promotion-20260407..l0-main-rescue
```

## What is clean already

- L0 promotion PR `#6` merged cleanly into `main`.
- A fresh L0 verification run still passes on top of merged main:
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`
  - `bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts`
  - `bash examples/fafafa.core.contracts/BuildOrRun.sh run`
  - `bash examples/fafafa.core.platform/BuildOrRun.sh run`
  - `git diff --check`

That means rescue triage can stay narrowly focused. There is no pressure to pull broad rescue changes just to make L0 green.

## Findings

### 1. Mainline control-plane pollution was the highest-priority cleanup

The biggest non-code problem on `main` was not missing L0 functionality. It was stale control-plane material:

- root `task_plan.md`
- root `findings.md`
- root `progress.md`
- stale `workers/worker1.md` pointers to the removed `l0-foundation` worktree
- stale `docs/INDEX.md` language that still treated root execution mirrors as current mainline state

These files had become a mix of historical execution logs and SIMD-heavy working notes. They made the repo look active in the wrong places and hid the actual L0 source of truth.

### 2. Rescue is dominated by SIMD-only or SIMD-adjacent material

These rescue paths stay out of the L0 lane unless the SIMD owner asks for help:

- `.github/workflows/simd-*`
- `docs/fafafa.core.simd*`
- `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- `tests/fafafa.core.simd/**`
- `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`
- `src/fafafa.core.simd.neon.register.inc`

Decision: do not bulk-merge any of these through L0 follow-up work.

### 3. A small rescue subset may still deserve later non-SIMD review

These files are not admitted yet, but they are reasonable candidates for a later file-by-file split:

- `docs/CI.md`
- `tests/run_all_tests.sh`
- `tests/test_repo_hygiene_guard.sh`
- `tools/lazbuild.sh`
- `examples/fafafa.core.atomic/BuildOrRun.sh`
- `examples/fafafa.core.base/BuildOrRun.sh`
- `examples/fafafa.core.option/BuildOrRun.sh`
- `examples/fafafa.core.result/BuildOrRun.sh`
- `examples/fafafa.core.base/example_base.lpr`
- `examples/fafafa.core.result/example_result_filters_and_try.lpr`
- `src/fafafa.core.mem.allocator.callbackAllocator.pas`
- `src/fafafa.core.time.tick.hardware.aarch64.pas`
- `src/fafafa.core.time.tick.hardware.armv7a.pas`
- `src/fafafa.core.time.tick.hardware.i386.pas`
- `src/fafafa.core.time.tick.hardware.riscv32.pas`
- `src/fafafa.core.time.tick.hardware.riscv64.pas`

Decision: review these in isolated batches with fresh tests. Do not treat rescue as a wholesale source of truth.

### 4. Some rescue deletions are explicitly rejected

The rescue snapshot deletes the `examples/fafafa.core.contracts/` runnable example set.

That is not acceptable for L0 mainline, because the current merged main was just reverified with:

```bash
bash examples/fafafa.core.contracts/BuildOrRun.sh run
```

Decision: reject that deletion set. It is noise, not cleanup.

### 5. Worker and documentation state must stay module-scoped

`workers/worker1.md` is part of L0 control-plane and should stay current.

`workers/worker0.md` is still SIMD-oriented and currently historical from the L0 point of view. It should be refreshed by the SIMD owner, not by L0 follow-up work.

Decision: keep the L0 worker current, and do not let L0 cleanup rewrite SIMD ownership.

## Batch decisions

| Batch | Scope | Owner | Decision |
| --- | --- | --- | --- |
| A | PR `#6` merge and merged-main verification | L0 | complete |
| B | Root execution-log cleanup, index refresh, worker refresh | L0 | complete |
| C | Non-SIMD rescue candidates | L0 | split later, file-by-file |
| D | SIMD scripts, CI, closeout docs, evidence helpers | SIMD owner | handoff only |
| E | Rescue deletions that break verified examples or current entry points | reject | do not carry |

## What changed in this batch

- Archived the heavy root working set under `plans/archive/2026-04-07-mainline-working-set/`.
- Replaced the root execution mirrors with short archive pointers.
- Refreshed L0 worker metadata to the current follow-up branch/worktree.
- Added a fresh rescue triage audit and a follow-up roadmap.
- Updated repo guidance so mainline no longer treats root scratch logs as stable documentation.

## What remains

- Review the non-SIMD rescue candidate files in small, verified batches.
- Hand the SIMD-only rescue residue to the SIMD owner.
- Run a second root-clutter pass against old `*_REPORT.md`, `WORKING*.md`, and one-off helper scripts that are not part of a stable module entry surface.

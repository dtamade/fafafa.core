# L0 Mem Callback And Closeout Doc Guard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 strict non-SIMD L0 worktree 中完成第十波小型高 ROI 收口：吸收 `mem allocator callback` 的低风险 rescue 语义修整，补齐对应测试，并为 `closeout` 的过时 test README residue 建立 no-downgrade 护栏。

**Architecture:** 这波不做 broad retained-ref merge，只做小范围 current-entry hardening。代码面只碰 `callbackAllocator` 的构造前置校验顺序和 `mem.allocator` 的 today wording；测试面扩展 `foundation` 入口对 nil callback policy 的覆盖；文档/控制面增加“closeout README 不能反向降级主线”的 contract，并把最新批次入口切到第十波审计。

**Tech Stack:** Free Pascal / Lazarus、FPCUnit、Bash、strict L0 docs/control-plane scripts

---

### Task 1: Freeze Tenth-Wave Scope

**Files:**
- Create: `docs/plans/2026-04-13-l0-retained-refs-tenth-mem-callback-doc-guard-plan.md`
- Create: `docs/audits/2026-04-13-l0-retained-refs-tenth-mem-callback-doc-guard-audit.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `workers/worker1.md`

**Step 1: Write the wave plan**

Write this file and pin the wave scope to:

- `src/fafafa.core.mem.allocator.callbackAllocator.pas`
- `src/fafafa.core.mem.allocator.pas`
- `tests/fafafa.core.mem.allocator.foundation/test_allocator_foundation_runtime.pas`
- closeout stale test README guard

**Step 2: Record the intended audit outcome**

Audit must say:

- no broad `closeout/rescue` absorb
- no SIMD touch
- `closeout` 6 test-doc candidates are stale downgrades, not absorption targets
- Windows exact native evidence remains CI-only

### Task 2: Harden Callback Allocator Construction

**Files:**
- Modify: `src/fafafa.core.mem.allocator.callbackAllocator.pas`
- Modify: `src/fafafa.core.mem.allocator.pas`
- Test: `tests/fafafa.core.mem.allocator.foundation/test_allocator_foundation_runtime.pas`

**Step 1: Tighten constructor ordering**

Move nil callback validation ahead of `inherited Create`, so constructor preconditions fail before object initialization when contracts are enabled.

**Step 2: Align facade wording**

Keep `fafafa.core.mem.allocator.pas` aligned with today L0 wording:

- strict L0 contract: `fafafa.core.mem.allocator.base`
- small concrete backend / low-level facade: `fafafa.core.mem.allocator.foundation`
- compatibility / optional backend aggregate: `fafafa.core.mem.allocator`

**Step 3: Extend foundation runtime coverage**

Cover all four nil callback positions in `test_allocator_foundation_runtime.pas` and keep the current policy explicit:

- contracts on: raise `EArgumentNil`
- `FAFAFA_CORE_NO_CONTRACTS`: object can still be constructed for smoke only

### Task 3: Add Closeout Test-Doc No-Downgrade Guard

**Files:**
- Create: `tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh`
- Modify: `docs/TESTING.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`

**Step 1: Encode the guard**

Add a shell contract that verifies these current README files are not downgraded by stale `closeout` diffs:

- `tests/fafafa.core.atomic/README.md`
- `tests/fafafa.core.endian/README.md`
- `tests/fafafa.core.layout/README.md`
- `tests/fafafa.core.mem.allocator.foundation/README.md`
- `tests/fafafa.core.platform/README.md`
- `tests/fafafa.core.span/README.md`

Guard conditions:

- `run_strict_l0_maintenance_loop.sh` remains documented where applicable
- exact Windows evidence remains documented as GitHub Actions / real Windows only
- `atomic` README keeps runtime outputs as local-only residue, not tracked support material

**Step 2: Surface the guard**

Add the new contract to the testing docs and docs-consistency required file set so the control plane knows about it.

### Task 4: Verification And Closeout

**Files:**
- Modify: `docs/TESTING.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `workers/worker1.md`

**Step 1: Run focused verification**

Run:

```bash
bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test
bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test-no-contracts
bash tests/fafafa.core.mem/BuildOrTest.sh test
bash tests/fafafa.core.mem/BuildOrTest.sh test-no-contracts
bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
git diff --check
```

Expected:

- focused mem allocator tests PASS
- no-downgrade contract PASS
- docs consistency PASS
- `git diff --check` clean

**Step 2: Run the Linux x64 strict L0 maintenance loop**

Run:

```bash
bash tests/run_strict_l0_maintenance_loop.sh
```

Expected:

- strict L0 docs consistency PASS
- aggregate gate PASS
- runtime matrix PASS
- native closeout stack PASS

**Step 3: Handle Windows exact evidence honestly**

If current `l0-mainline` HEAD is not available as a remote ref, do not spoof exact Windows evidence. Record that:

- Windows exact native evidence remains CI-only
- this local wave is verified on Linux x64
- exact Windows evidence must be collected after remote-visible ref publication / merge

**Step 4: Commit**

Stage only this tenth-wave set and commit with a dedicated L0 message.

# L0 Closeout/Rescue Final Source Review Clearout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `closeout/rescue` 剩余的 strict L0 source-review surface 一次性收口到 0：吸收唯一一条真正符合 today contract 的 collections/L0 去耦改动，并把其余 stale/no-op/rescue-regression 路径统一下沉到 `review_skip_paths=`。

**Architecture:** 这轮继续坚持 shortlist-first、non-destructive、review/skip 优先于 broad absorb。唯一允许吸收的是 `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas` 中移除 `SliceView` 对 strict L0 `span2` contract 的反向绑定；其余 27 条路径都按 fresh diff 判定为 stale/no-op/test-entry regression/style-only residue，统一转入 `review_skip_paths=`。随后刷新 latest audit、current-state docs、INDEX/README/TESTING 和 worker handoff，并用 collections vecdeque 测试 + strict L0 maintenance loop 完整验证。

**Tech Stack:** Bash shortlist script, Pascal tests, Lazarus/FPC test runners, Markdown docs, strict L0 audit/current-state scripts

---

### Task 1: 吸收唯一的 collections/L0 去耦改动

**Files:**
- Modify: `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas`
- Test: `tests/fafafa.core.collections/vecdeque/BuildOrTest.sh`

**Step 1: 移除不该由 collections 持有的 L0 parity 断言**

- 删除 `fafafa.core.span` 的直接依赖
- 删除 `TL0IntSpan` / `TL0IntSpan2` 别名
- 删除 `Test_SliceView_Matches_L0Span2_Contract`
- 保留 `SliceView` 自身的 container semantics 测试

**Step 2: 运行 vecdeque 模块测试**

Run:

```bash
bash tests/fafafa.core.collections/vecdeque/BuildOrTest.sh
```

Expected:

- 编译通过
- vecdeque span 相关测试继续通过

### Task 2: 把剩余 27 条 rescue candidate 全部下沉到 `review_skip_paths=`

**Files:**
- Modify: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`

**Skip cluster A: time hardware whitespace/no-boundary value**
- `src/fafafa.core.time.tick.hardware.aarch64.pas`
- `src/fafafa.core.time.tick.hardware.armv7a.pas`
- `src/fafafa.core.time.tick.hardware.i386.pas`
- `src/fafafa.core.time.tick.hardware.riscv32.pas`
- `src/fafafa.core.time.tick.hardware.riscv64.pas`

**Skip cluster B: stale test entry / settings / wrapper residue**
- `tests/fafafa.core.endian/fafafa.core.endian.test.lpr`
- `tests/fafafa.core.layout/fafafa.core.layout.test.lpr`
- `tests/fafafa.core.mem/tests_mem_allocator_only.lpi`
- `tests/fafafa.core.mem/tests_mem_allocator_only.lpr`
- `tests/fafafa.core.option/fafafa.core.option.test.lpr`
- `tests/fafafa.core.platform/fafafa.core.platform.test.lpr`
- `tests/fafafa.core.result/tests_result.lpr`
- `tests/fafafa.core.span/fafafa.core.span.test.lpr`
- `tests/fafafa.core.option/buildOrTest.bat`
- `tests/fafafa.core.result/buildOrTest.bat`
- `tests/fafafa.core.result/test_basic_result.pas`
- `tests/fafafa.core.result/test_option_basic.pas`
- `tests/fafafa.core.result/test_option_init_debug.pas`

**Skip cluster C: stale test-source regressions / style-only residue**
- `tests/fafafa.core.base/fafafa.core.base.testcase.pas`
- `tests/fafafa.core.bits/fafafa.core.bits.testcase.pas`
- `tests/fafafa.core.contracts/fafafa.core.contracts.testcase.pas`
- `tests/fafafa.core.endian/fafafa.core.endian.testcase.pas`
- `tests/fafafa.core.layout/fafafa.core.layout.testcase.pas`
- `tests/fafafa.core.mem/test_mem_allocator.pas`
- `tests/fafafa.core.option/fafafa.core.option.testcase.pas`
- `tests/fafafa.core.result/fafafa.core.result.testcase.pas`
- `tests/fafafa.core.span/fafafa.core.span.testcase.pas`

**Step 1: 只把已 fresh 复核的路径加入 skip**

- 不改变 retained refs
- 不 broad absorb `rescue`
- 不碰 SIMD

**Step 2: 目标输出**

- `closeout.review_candidate_paths=0`
- `rescue.review_candidate_paths=0`

### Task 3: 刷新 latest audit / current-state docs / worker handoff

**Files:**
- Create: `docs/audits/2026-04-15-l0-closeout-rescue-final-source-review-clearout-audit.md`
- Modify: `tests/update_strict_l0_current_state_docs.sh`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/TESTING.md`
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify via updater: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify via updater: `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md`
- Modify via updater: `workers/worker1.md`

**Step 1: 明确 latest state**

- `closeout/rescue` source-review shortlist 已清空
- `dangerous_delete_paths=` 仍然阻止 wholesale absorb
- `sidecar/tail` 继续是 retained-refs 下一跳
- collections `SliceView` 不再通过 vecdeque testcase 反向绑定 strict L0 `span2`

### Task 4: 更新 shortlist contract 与 fresh verification 记录

**Files:**
- Modify: `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh` only if stub output changes are needed
- Verify: `tests/test_update_strict_l0_current_state_docs_contract.sh`
- Verify: `tests/check_strict_l0_docs_consistency.sh`
- Verify: `tests/run_strict_l0_maintenance_loop.sh`

**Step 1: 只在必要时更新 contract**

- 如果 stub 场景不受这轮新 skip path 影响，则不改 contract
- 如果 docs consistency 新增 latest audit / plan 文件，则更新 required files / latest pointers

### Task 5: 完整收口验证

Run:

```bash
bash tests/fafafa.core.collections/vecdeque/BuildOrTest.sh
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

**Expected:**

- `closeout/rescue` source-review candidate 全部收敛到 0
- vecdeque 测试继续通过
- current-state docs / worker / latest audit 与 fresh shortlist 对齐
- strict L0 maintenance loop 继续 PASS

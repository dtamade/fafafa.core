# L0 Mainline Continuation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在已完成 L0 合并后的唯一 `l0-mainline` worktree 上，把 strict non-SIMD L0 维持在“边界稳定、文档可信、验证可重复、历史 refs 可治理”的长期维护态。

**Architecture:** 先把 current-entry 文档、worker 入口和 merged-main 现状重新对齐，确保所有人都从同一套 source-of-truth 进入。然后把日常维护闭环、retained refs 治理和 Windows exact evidence 规则固化下来，最后只在存在真实必要时再开小批次 non-SIMD follow-up 或 evaluation-only admission 设计。

**Tech Stack:** Markdown, bash test runners, git refs/worktrees, GitHub Actions Windows evidence.

---

### Task 1: 对齐 merged-main 的 current-entry 文档栈

**Files:**
- Review: `docs/fafafa.core.l0.roadmap.md`
- Review: `docs/fafafa.core.l0.foundation.md`
- Review: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Review: `docs/README.md`
- Review: `docs/INDEX.md`
- Review: `workers/worker1.md`
- Modify if drift exists: same files above
- Test: `tests/check_strict_l0_docs_consistency.sh`
- Test: `tests/test_strict_l0_docs_consistency_contract.sh`
- Test: `tests/test_update_strict_l0_current_state_docs_contract.sh`

**Step 1: 先确认 today contract 的入口是否一致**

检查这些文件是否都明确指向：

- `ARCHITECTURE_LAYERS`
- `foundation`
- `roadmap`
- latest current-state audit
- `l0-mainline` 作为唯一 L0 worktree

**Step 2: 如果文档仍带旧 merge-prep 语境，做最小改写**

只修正以下内容：

- 当前 L0 已经处于 post-merge maintenance 模式
- 当前主线重点是 source-of-truth hardening，不是继续扩 L0 面
- dated checklist / replay / closeout 文档只保留历史语境

**Step 3: 跑文档 contract**

Run:

```bash
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
```

Expected:

- 全部 PASS
- 没有 current-entry 入口漂移

### Task 2: 固化 strict L0 日常维护闭环

**Files:**
- Review: `tests/run_strict_l0_maintenance_loop.sh`
- Review: `tests/check_strict_l0_docs_consistency.sh`
- Review: `tests/test_strict_l0_maintenance_loop_contract.sh`
- Review: `.github/workflows/l0-linux-maintenance.yml`
- Modify only if actual contract drift is found

**Step 1: 以 maintenance loop 作为唯一 Linux x64 日常入口**

确认闭环仍固定为：

- docs consistency
- repo submodule hygiene
- active shell runners
- strict L0 aggregate gate
- `git diff --check`
- Windows batch runtime matrix contract
- Windows native closeout stack contract

**Step 2: 运行 maintenance loop**

Run:

```bash
bash tests/run_strict_l0_maintenance_loop.sh
```

Expected:

- `[PASS] strict L0 maintenance loop verified`

**Step 3: 若 loop 失败，只修 contract 漂移，不趁机扩 scope**

允许处理：

- 入口文档漂移
- runner contract 漂移
- include / hygiene 漂移

不允许处理：

- SIMD 实现
- broad rescue absorb
- 借失败顺手扩 L0 边界

### Task 3: 治理 retained refs，但不盲删

**Files:**
- Review: `tests/report_strict_l0_retained_refs_inventory.sh`
- Review: `tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
- Review: `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- Review: `tests/audit_strict_l0_retained_refs.sh`
- Modify only if scripts misclassify current state
- Optional audit output update: `docs/audits/2026-04-11-l0-current-state-audit.md`

**Step 1: 先看 inventory，不直接删 branch/ref**

Run:

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
```

Expected:

- 可以直接读出 `next_focus=`
- 可以区分 docs residue / test hygiene / source review

**Step 2: 再看 `sidecar/tail` pairwise cleanup readiness**

Run:

```bash
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/audit_strict_l0_retained_refs.sh
```

Expected:

- 明确哪些 refs 仍承载 unique history
- 只有 `safe_delete_now=yes` 且无独立 patch history 时才允许删除

**Step 3: 如仍是 `no-op`，保持保留而不是制造“假收口”**

输出结论只允许三类：

- `keep`
- `review in next narrow batch`
- `safe to delete`

禁止：

- broad absorb
- 因为“看起来很多”就清空 retained refs

### Task 4: 只在真实需要时推进 non-SIMD follow-up 小批次

**Files:**
- Possible batch A: `docs/CI.md`, `tests/run_all_tests.sh`, `tests/test_repo_hygiene_guard.sh`, `tools/lazbuild.sh`
- Possible batch B: `examples/fafafa.core.atomic/BuildOrRun.sh`, `examples/fafafa.core.base/BuildOrRun.sh`, `examples/fafafa.core.option/BuildOrRun.sh`, `examples/fafafa.core.result/BuildOrRun.sh`, `examples/fafafa.core.base/example_base.lpr`, `examples/fafafa.core.result/example_result_filters_and_try.lpr`
- Possible batch C: `src/fafafa.core.mem.allocator.callbackAllocator.pas`, `src/fafafa.core.time.tick.hardware.aarch64.pas`, `src/fafafa.core.time.tick.hardware.armv7a.pas`, `src/fafafa.core.time.tick.hardware.i386.pas`, `src/fafafa.core.time.tick.hardware.riscv32.pas`, `src/fafafa.core.time.tick.hardware.riscv64.pas`
- Possible batch D: non-SIMD-owned docs only

**Step 1: 每次只选一个 batch**

选择规则：

- 必须是 non-SIMD
- 必须能独立验证
- 必须不是 stale downgrade

**Step 2: 先写 batch-specific 验证清单**

至少包含：

- 相关模块 BuildOrTest / BuildOrRun
- `bash tests/run_strict_l0_maintenance_loop.sh`
- `git diff --check`

**Step 3: 只做最小吸收，不做 wholesale merge**

如果 fresh review 表明它只是：

- current-HEAD-ahead
- stale-no-downgrade
- already-absorbed

就直接标记 skip，不进入实现。

### Task 5: 保持 Windows evidence 规则硬边界

**Files:**
- Review: `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
- Review: `tests/verify_windows_strict_l0_native_evidence.sh`
- Review: `tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
- Review: `tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh`
- Review: `docs/CI.md`
- Review: `docs/fafafa.core.l0.roadmap.md`
- Modify only if wording or workflow contract drifts

**Step 1: 明确证据规则**

规则固定为：

- Windows exact evidence 只能来自 CI / GitHub Actions
- Linux x64 本地只负责 verifier，不伪装成 Windows exact native result

**Step 2: 只有这两类情况才重跑 Windows exact evidence**

- strict L0 非文档代码变化
- strict L0 测试入口变化

docs-only 变化默认不重跑。

**Step 3: 如需更新 evidence，走固定入口**

Run:

```bash
bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh <batch-id> <run-id>
```

Expected:

- artifact 下载成功
- shell-side verifier PASS
- docs 只记录真实 run id / sha

### Task 6: `segmented span` 只保持 evaluation-only

**Files:**
- Review: `docs/fafafa.core.l0.roadmap.md`
- Review: `docs/fafafa.core.l0.foundation.md`
- Review: `docs/fafafa.core.span.md`
- Review: `docs/plans/2026-04-14-l0-segmented-span-evaluation-plan.md`
- Create only if a new admission wave is approved: a new dated candidate/admission plan

**Step 1: 不把 evaluation topic 误写成 active admission**

当前结论必须保持：

- `segmented span` 值得评估
- 但不是当前默认开发主线
- 更不等于把 collections dual-segment semantics 整包搬进 strict L0

**Step 2: 只有满足 admission checklist 才能新开波次**

必须同时满足：

- RTL-only + existing L0 dependencies
- 非容器 policy
- 多上层自然复用
- 小而硬的 API
- 能补齐 code/tests/docs/foundation/roadmap/audit

**Step 3: 若条件不全，结论保持 `defer`**

不要为了推进感进入实现。

### Task 7: 收口标准

**Files:**
- Modify if needed: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify if needed: `workers/worker1.md`
- Modify if needed: a new dated closeout note under `docs/audits/` or `docs/plans/`

**Step 1: 记录这一轮结束时的 4 件事**

- 当前 L0 head / branch / worktree
- 当前 maintenance loop 结果
- 当前 retained refs decision
- 当前 Windows evidence posture

**Step 2: 把结论提升到稳定文档，不把 scratch 挂在根目录**

允许：

- `docs/audits/`
- `docs/plans/`
- `workers/`

不允许：

- 根目录长期 scratch
- 把 dated execution log 重新升成 current-entry

**Step 3: 最终验证**

Run:

```bash
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected:

- 全部 PASS
- 没有未解释的 control-plane drift

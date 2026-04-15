# L0 Maintenance Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 strict non-SIMD L0 的 post-merge 维护面固化成可重复执行的单入口闭环，并把历史 merge-prep 文档完全移出 current-entry。

**Architecture:** 先补两个 shell contract test，锁定“L0 docs consistency checker”和“L0 maintenance loop runner”的最小对外合同。然后实现两个脚本，把 `README`、`INDEX`、`CI`、`TESTING`、`worker1` 和 strict L0 模块文档统一改为同一套入口，再把 merge-prep 文档移到 `docs/legacy/l0/` 并更新所有引用。

**Tech Stack:** Bash, ripgrep, Markdown docs, existing `tests/run_all_tests.sh`, existing Windows strict L0 contract scripts.

---

### Task 1: 先写 failing shell contract tests

**Files:**
- Create: `tests/test_strict_l0_docs_consistency_contract.sh`
- Create: `tests/test_strict_l0_maintenance_loop_contract.sh`

**Step 1: 写 docs consistency contract test**

要求：

- 调用 `bash tests/check_strict_l0_docs_consistency.sh`
- 期待输出包含 `[PASS] strict L0 docs consistency verified`
- 期待输出包含 `docs/README.md`、`docs/INDEX.md`、`workers/worker1.md`

**Step 2: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_docs_consistency_contract.sh
```

Expected: 因目标脚本尚不存在或未满足 contract 而失败。

**Step 3: 写 maintenance loop contract test**

要求：

- 调用 `bash tests/run_strict_l0_maintenance_loop.sh --print-commands`
- 期待输出包含：
  - `check_strict_l0_docs_consistency.sh`
  - `git diff --check`
  - `tests/run_all_tests.sh`
  - `test_windows_strict_l0_batch_runtime_matrix.sh`
  - `test_windows_strict_l0_native_closeout_stack.sh`

**Step 4: 跑 test，确认先失败**

Run:

```bash
bash tests/test_strict_l0_maintenance_loop_contract.sh
```

Expected: 因目标脚本尚不存在或未满足 contract 而失败。

### Task 2: 实现 strict L0 docs consistency checker

**Files:**
- Create: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/CI.md`
- Modify: `docs/TESTING.md`
- Modify: `workers/worker1.md`

**Step 1: 写脚本**

脚本要求：

- 统一 `SCRIPT_DIR` / `REPO_ROOT` 检测
- 校验关键文件存在
- 校验 `README` / `INDEX` 不再把 merge-prep 文档指向 `docs/plans/`
- 校验 `README` / `INDEX` / `CI` / `worker1` 都指向同一套 current-entry
- 校验 Windows exact evidence 仍只接受 GitHub Actions
- 成功时输出 `[PASS] strict L0 docs consistency verified`

**Step 2: 更新 current-entry 文档**

要求：

- `README` / `INDEX` 的历史 merge-prep 文档入口切到 `docs/legacy/l0/`
- `CI` / `TESTING` 增加统一维护脚本入口
- `worker1` 把新脚本列入 fresh verification / source-of-truth

**Step 3: 跑 test，确认通过**

Run:

```bash
bash tests/test_strict_l0_docs_consistency_contract.sh
```

Expected: PASS

### Task 3: 实现 strict L0 maintenance loop runner

**Files:**
- Create: `tests/run_strict_l0_maintenance_loop.sh`
- Modify: `docs/CI.md`
- Modify: `docs/TESTING.md`

**Step 1: 写脚本**

脚本要求：

- 支持 `--print-commands`
- 默认顺序固定为：
  - `bash tests/check_strict_l0_docs_consistency.sh`
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh ...`
  - `git diff --check`
  - `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
  - `bash tests/test_windows_strict_l0_native_closeout_stack.sh`
- 成功时输出 `[PASS] strict L0 maintenance loop verified`

**Step 2: 更新文档入口**

要求：

- `CI` 把原本散落的 4 步闭环改成“默认运行这个脚本”
- `TESTING` 说明该脚本是 strict L0 的 Linux x64 维护入口

**Step 3: 跑 test，确认通过**

Run:

```bash
bash tests/test_strict_l0_maintenance_loop_contract.sh
```

Expected: PASS

### Task 4: 把 merge-prep 文档正式归档

**Files:**
- Create: `docs/legacy/l0/2026-04-11-l0-mainline-merge-checklist.md`
- Create: `docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md`
- Delete: `docs/plans/2026-04-11-l0-mainline-merge-checklist.md`
- Delete: `docs/plans/2026-04-11-l0-mainline-replay-execution-plan.md`
- Modify: `docs/legacy/l0/README.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/fafafa.core.l0.foundation.md`
- Modify: `docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md`

**Step 1: 移动文件并保留历史语境**

要求：

- 文件内容保留
- 顶部增加“已归档到 `docs/legacy/l0/`”说明

**Step 2: 更新所有 current-entry 引用**

要求：

- 当前入口不再指向 `docs/plans/2026-04-11-l0-mainline-*.md`
- 历史入口统一指向 `docs/legacy/l0/2026-04-11-l0-mainline-*.md`

### Task 5: 同步清扫 strict L0 模块文档与测试 README

**Files:**
- Modify: `docs/fafafa.core.platform.md`
- Modify: `docs/fafafa.core.layout.md`
- Modify: `docs/fafafa.core.endian.md`
- Modify: `docs/fafafa.core.span.md`
- Modify: `docs/fafafa.core.atomic.md`
- Modify: `docs/fafafa.core.mem.md`
- Modify: `tests/fafafa.core.platform/README.md`
- Modify: `tests/fafafa.core.layout/README.md`
- Modify: `tests/fafafa.core.endian/README.md`
- Modify: `tests/fafafa.core.span/README.md`
- Modify: `tests/fafafa.core.atomic/README.md`
- Modify: `tests/fafafa.core.mem.allocator.foundation/README.md`

**Step 1: 统一 today 口径**

要求：

- 明确 current-entry 是 `foundation + roadmap + latest audit`
- 明确 Linux x64 日常维护入口是 `bash tests/run_strict_l0_maintenance_loop.sh`
- 明确 Windows exact evidence 只来自 GitHub Actions
- 对 `compat` / facade / low-level facade 的边界保持一致，不再漂移

### Task 6: 跑完整闭环

**Files:**
- Modify: none

**Step 1: 跑两个 contract test**

Run:

```bash
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_maintenance_loop_contract.sh
```

Expected: PASS

**Step 2: 跑完整维护闭环**

Run:

```bash
bash tests/run_strict_l0_maintenance_loop.sh
```

Expected: PASS

**Step 3: 跑 diff hygiene**

Run:

```bash
git diff --check
```

Expected: PASS

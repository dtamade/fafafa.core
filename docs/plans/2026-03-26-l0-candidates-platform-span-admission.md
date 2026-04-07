# strict L0 Candidates: platform / span Admission Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

> **Status update (2026-03-26):**
> - `Task 1` 已完成审查，结论是 `platform` 继续 deferred；当前不进入 `Task 3`
> - `Task 2` 已完成审查，`span` 获批
> - `Task 4` / `Task 5` 中与 `span` 相关的实现和 L0 gate 纳入已完成
> - 因此本计划剩余未完成项，只剩“未来若要继续推进 `platform`，先收敛 API 壳面，再重新申请实现”

**Goal:** 在不盲目扩张 strict L0 的前提下，先完成 `platform` / `span` 的准入设计与最小原型边界定义；只有在审查结论通过后，才进入实现。

**Architecture:** 这轮不是直接把 `platform` / `span` 塞进 L0，而是先做 admission-driven implementation。也就是说，先证明“模块边界、依赖面、API 面、测试入口”都满足 L0 规则，再最小实现。`platform` 和 `span` 必须拆成两个独立候选，不允许在同一批里互相放大复杂度。

**Tech Stack:** Free Pascal / Lazarus, markdown docs, shell BuildOrTest scripts.

---

### Task 1: platform 候选准入设计

**Files:**
- Read: `docs/ARCHITECTURE_LAYERS.md`
- Read: `docs/fafafa.core.l0.foundation.md`
- Read: `docs/fafafa.core.l0.candidates.platform-span.review.md`（现已归档至 `docs/legacy/l0/fafafa.core.l0.candidates.platform-span.review.md`）
- Create: `docs/fafafa.core.platform.candidate.md`（现已归档至 `docs/legacy/l0/fafafa.core.platform.candidate.md`）

**Step 1: 列出 platform 候选 API**

- 只允许列出“纯表达层、无服务语义”的候选 API。
- 不允许把 env/time/fs/sync 的平台实现细节直接算进来。

**Step 2: 为每个 API 做准入判断**

- 是否只依赖 RTL + 已确认 L0
- 是否可被多个上层域自然复用
- 是否能稳定维持小 API 面

**Step 3: 形成结论**

- 若无法收敛到小 API，则明确写“不进入 strict L0”
- 若可以收敛，才进入 Task 3

### Task 2: span 候选准入设计

**Files:**
- Read: `docs/fafafa.core.l0.candidates.platform-span.review.md`（现已归档至 `docs/legacy/l0/fafafa.core.l0.candidates.platform-span.review.md`）
- Read: `tests/fafafa.core.collections/vec/Test_vec_span.pas`
- Read: `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas`
- Create: `docs/fafafa.core.span.candidate.md`（现已归档至 `docs/legacy/l0/fafafa.core.span.candidate.md`）

**Step 1: 区分 today semantics 与 L0 candidate**

- 现有 `collections.slice` / `SliceView` 只是 today semantics
- 不能直接等同于 `fafafa.core.span`

**Step 2: 列出最小候选 API**

- 优先只读
- 优先单段
- 先不带容器策略
- 先不带 allocator / ring-buffer 扩展

**Step 3: 形成结论**

- 若 span 仍依赖 collections 才成立，则继续留在 Layer 1
- 只有当它能脱离 collections 独立存在，才进入 Task 4

### Task 3: platform 最小原型（仅在 Task 1 结论允许时）

> 当前状态：**未获准进入本任务**

**Files:**
- Create: `src/fafafa.core.platform.pas`
- Create: `docs/fafafa.core.platform.md`
- Create: `tests/fafafa.core.platform/README.md`
- Create: `tests/fafafa.core.platform/BuildOrTest.sh`
- Create: `tests/fafafa.core.platform/BuildOrTest.bat`
- Create: `tests/fafafa.core.platform/fafafa.core.platform.test.lpi`
- Create: `tests/fafafa.core.platform/fafafa.core.platform.test.lpr`
- Create: `tests/fafafa.core.platform/fafafa.core.platform.testcase.pas`

**Step 1: 先写失败测试**

- 只覆盖批准后的最小 API
- 不预支更大平台抽象

**Step 2: 实现最小代码**

- 只依赖 RTL + L0
- 不牵出 env/fs/time/sync 的服务语义

**Step 3: 回归**

Run:
```bash
bash tests/fafafa.core.platform/BuildOrTest.sh test
```

### Task 4: span 最小原型（仅在 Task 2 结论允许时）

> 当前状态：**已完成**

**Files:**
- Create: `src/fafafa.core.span.pas`
- Create: `docs/fafafa.core.span.md`
- Create: `tests/fafafa.core.span/README.md`
- Create: `tests/fafafa.core.span/BuildOrTest.sh`
- Create: `tests/fafafa.core.span/BuildOrTest.bat`
- Create: `tests/fafafa.core.span/fafafa.core.span.test.lpi`
- Create: `tests/fafafa.core.span/fafafa.core.span.test.lpr`
- Create: `tests/fafafa.core.span/fafafa.core.span.testcase.pas`

**Step 1: 先写失败测试**

- 只覆盖批准后的“最小只读单段 span contract”
- 不把 collections 的 today behavior 整包搬过来

**Step 2: 实现最小代码**

- 只依赖 RTL + L0
- 不依赖 collections

**Step 3: 回归**

Run:
```bash
bash tests/fafafa.core.span/BuildOrTest.sh test
```

### Task 5: 若原型成立，再尝试纳入 strict L0 gate

> 当前状态：
> - `span` 相关部分已完成
> - `platform` 相关部分仍不进入本任务

**Files:**
- Modify: `docs/fafafa.core.l0.foundation.md`
- Modify: `docs/ARCHITECTURE_LAYERS.md`
- Modify: `docs/fafafa.core.l0.merge-closeout.md`（现已归档至 `docs/legacy/l0/fafafa.core.l0.merge-closeout.md`）

**Step 1: 更新边界文档**

- 只在 prototype 已通过且边界稳定时更新

**Step 2: 跑 gate**

Run:
```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation
```

**Step 3: 视情况扩 gate**

- 只有 `platform` / `span` 都形成独立入口后，才把它们加入 strict L0 gate 名单

## 当前执行限制

本计划最初写下时，只完成到“admission-ready”阶段。

原因是：

- `platform` / `span` 都属于新的 L0 准入动作
- 这属于架构扩张，不应未经批准直接实做
- 目前仓库证据显示它们都还没有现成的 strict L0 模块形态

但当前实际进展已经更新为：

- `span` 已不再停留在 admission-ready，而是已经完成最小 strict L0 落地
- `platform` 仍停留在 admission 结论阶段，且结论是继续 deferred

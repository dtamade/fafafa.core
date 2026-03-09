# Repo Gap Scan Priority Batch-21 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 继续清理 `sync.mutex.parkinglot` 压力测试占位项，本批完成 `Test_ExtremeContention_MixedOperations` 的 TDD 替换。

**Architecture:** 保持单方法最小改动：先确认占位基线，再构造 RED 失败，再实现“混合并发模式”最小可执行基线，最后模块回归并同步记录。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`。

---

## 本轮扫描结论（2026-02-11）

### P1（本批执行）
1. `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
   - `Test_ExtremeContention_MixedOperations` 仍为占位，执行时间 `00.000`。

### P1（下一批候选）
2. `Test_MemoryPressure_ManyMutexes`
3. `Test_MemoryPressure_FrequentCreation`

---

### Task 1: RED 基线

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 运行套件确认占位状态**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `MixedOperations` 为 `00.000`。

**Step 2: 改为最小失败断言并复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `MixedOperations` 失败（RED）。

---

### Task 2: GREEN 实现

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现“混合模式”基线**
- 三阶段混合负载（示例）：
  - 阶段1：8线程 × 120次；
  - 阶段2：16线程 × 60次；
  - 阶段3：4线程 × 240次。
- 每阶段断言错误计数=0、计数精确匹配。
- 最终断言总错误=0、总计数匹配预期。

**Step 2: 编译+套件复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，`MixedOperations` 有可见执行耗时。

---

### Task 3: 回归与记录

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `docs/plans/2026-02-10-repo-gap-scan-priority-execution.md`

**Step 1: 模块回归**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`

Expected:
- `N:62 E:0 F:0`。

**Step 2: 追加本批命令输出与下批建议**

---

## 执行记录（2026-02-11）

### Task 1（RED）
1) 基线（占位版）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ExtremeContention_MixedOperations`：`00.000`

2) 构造最小失败断言后复验
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_ExtremeContention_MixedOperations  Failed: 混合竞争测试应执行实际操作`

### Task 2（GREEN）
- 将 `MixedOperations` 实现为三阶段混合并发基线：
  - 阶段1：8线程×120次
  - 阶段2：16线程×60次
  - 阶段3：4线程×240次
- 每阶段断言计数与错误计数，最终断言总计数。
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ExtremeContention_MixedOperations`：`00.203`

### Task 3（回归）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-21 完成：`Test_ExtremeContention_MixedOperations` 已从占位断言替换为真实混合并发测试。
- 下一批建议：`Test_MemoryPressure_ManyMutexes`。

# Repo Gap Scan Priority Batch-22 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 继续清理 `sync.mutex.parkinglot` 压力测试占位项，本批完成 `Test_MemoryPressure_ManyMutexes` 的 TDD 替换。

**Architecture:** 保持单方法最小改动，先构造 RED 失败，再实现“批量创建互斥锁 + 基本操作”内存压力基线，最后模块回归与记录同步。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`。

---

## 本轮扫描结论（2026-02-11）

### P1（本批执行）
1. `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
   - `Test_MemoryPressure_ManyMutexes` 仍为占位断言（`00.000`）。

### P1（下一批候选）
2. `Test_MemoryPressure_FrequentCreation`
3. `Test_MemoryPressure_LowMemory`

---

### Task 1: RED 基线

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 套件基线确认**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `Test_MemoryPressure_ManyMutexes` 为 `00.000`。

**Step 2: 改为最小失败断言并复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `ManyMutexes` 失败（RED）。

---

### Task 2: GREEN 实现

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现内存压力基线**
- 批量创建固定数量互斥锁（例如 1024）；
- 对每个互斥锁执行一次 Acquire/Release；
- 断言：创建/操作错误计数为0、操作计数匹配创建数量。

**Step 2: 编译+套件复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，`ManyMutexes` 有可见执行耗时。

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

**Step 2: 追加本批执行日志与下批建议**

---

## 执行记录（2026-02-11）

### Task 1（RED）
1) 基线（占位版）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_MemoryPressure_ManyMutexes`：`00.000`

2) 构造最小失败断言后复验
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_MemoryPressure_ManyMutexes  Failed: 内存压力测试应执行实际操作`

### Task 2（GREEN）
- 将 `ManyMutexes` 实现为内存压力基线：创建 1024 个互斥锁并逐个 Acquire/Release。
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_MemoryPressure_ManyMutexes`：`00.001`

### Task 3（回归）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-22 完成：`Test_MemoryPressure_ManyMutexes` 已从占位断言替换为真实内存压力测试。
- 下一批建议：`Test_MemoryPressure_FrequentCreation`。

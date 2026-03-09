# Repo Gap Scan Priority Batch-20 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 延续全仓缺口清理，完成 `sync.mutex.parkinglot` 中 `Test_ExtremeContention_HighFrequency` 的占位替换。

**Architecture:** 继续采用单点替换策略，先构造 RED，再用最小高频短临界区并发基线达成 GREEN，最后做模块回归与记录同步。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`。

---

## 本轮缺口复核（2026-02-11）

### P1（本批执行）
1. `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
   - `Test_ExtremeContention_HighFrequency` 仍为占位断言，当前执行时间 `00.000`。

### P1（下一批候选）
2. `Test_ExtremeContention_MixedOperations`
3. `Test_MemoryPressure_ManyMutexes`

---

### Task 1: 建立 RED 基线

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 运行套件确认占位现状**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `Test_ExtremeContention_HighFrequency` 为 `00.000`。

**Step 2: 改为最小失败断言并复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `HighFrequency` 失败，确认 RED 生效。

---

### Task 2: 实现 GREEN（高频竞争基线）

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现高频短临界区场景**
- 采用多轮（例如 20 轮）短操作高频循环；
- 每轮固定线程数（例如 8）与迭代次数（例如 100）；
- 断言每轮与总计数、错误计数。

**Step 2: 编译+套件复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，`HighFrequency` 出现可见执行耗时。

---

### Task 3: 模块回归与记录

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

**Step 2: 追加执行日志与下批建议**

---

## 执行记录（2026-02-11）

### Task 1（RED）
1) 现状基线
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ExtremeContention_HighFrequency`：`00.000`

2) 构造最小失败断言后复验
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_ExtremeContention_HighFrequency  Failed: 高频竞争测试应执行实际操作`

### Task 2（GREEN）
- 将 `HighFrequency` 实现为高频短临界区并发基线：20 轮 × 每轮 8 线程 × 每线程 100 次。
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ExtremeContention_HighFrequency`：`02.011`

### Task 3（回归）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-20 完成：`Test_ExtremeContention_HighFrequency` 已从占位断言升级为真实高频并发测试。
- 下一批建议：`Test_ExtremeContention_MixedOperations`。

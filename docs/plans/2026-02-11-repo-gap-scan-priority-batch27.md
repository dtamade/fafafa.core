# Repo Gap Scan Priority Batch-27 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 完成 `sync.mutex.parkinglot` 剩余占位项，替换 `Test_ResourceExhaustion_Recovery`。

**Architecture:** 先 RED 构造失败，再实现“两阶段恢复基线”（先高压线程阶段，再恢复验证阶段），最后模块回归与记录同步。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`。

---

## 本轮扫描结论（2026-02-11）

### P1（本批执行）
1. `Test_ResourceExhaustion_Recovery` 仍为唯一占位断言。

---

### Task 1: RED 基线

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 套件基线确认**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `Recovery` 为 `00.000`。

**Step 2: 改为最小失败断言并复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `Recovery` 失败（RED）。

---

### Task 2: GREEN 实现

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现恢复场景基线**
- 阶段1：线程压力（如 8 线程 × 150 次），验证无错误；
- 阶段2：恢复验证（新建 mutex 连续 Acquire/Release），验证可继续稳定工作；
- 断言总错误与总计数。

**Step 2: 编译+套件复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，`Recovery` 有可见执行耗时。

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

**Step 2: 追加本批日志与结果总结**

---

## 执行记录（2026-02-11）

### Task 1（RED）
1) 基线（占位版）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ResourceExhaustion_Recovery`：`00.000`

2) 构造最小失败断言后复验
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_ResourceExhaustion_Recovery  Failed: 资源恢复测试应执行实际操作`

### Task 2（GREEN）
- 将 `Recovery` 实现为两阶段恢复基线：
  - 阶段1：8线程×150次压力负载；
  - 阶段2：新建锁执行1000次恢复验证。
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ResourceExhaustion_Recovery`：`00.101`

### Task 3（回归）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-27 完成：`Recovery` 已从占位断言替换为真实恢复场景测试。

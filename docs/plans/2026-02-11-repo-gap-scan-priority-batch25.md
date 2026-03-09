# Repo Gap Scan Priority Batch-25 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于本轮扫描，替换 `Test_ResourceExhaustion_ThreadLimit` 占位测试，形成可执行资源压力基线。

**Architecture:** 单测试方法最小改动；先 RED 构造失败，再实现“多轮高线程创建并回收”基线，最后模块回归与记录同步。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`。

---

## 本轮扫描结论（2026-02-11）

### P1（本批执行）
1. `Test_ResourceExhaustion_ThreadLimit` 仍为占位断言（`00.000`）。

### P1（下一批候选）
2. `Test_ResourceExhaustion_HandleLimit`
3. `Test_ResourceExhaustion_Recovery`

---

### Task 1: RED 基线

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 确认占位现状**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `ThreadLimit` 为 `00.000`。

**Step 2: 改为最小失败断言并复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `ThreadLimit` 失败（RED）。

---

### Task 2: GREEN 实现

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现线程资源压力基线**
- 固定轮次（例如 6 轮）和每轮线程数（例如 24）；
- 每线程运行固定迭代（例如 80）并共享同一互斥锁计数；
- 每轮断言错误计数=0、计数精确匹配；
- 结束断言总错误与总计数。

**Step 2: 编译+套件复验**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，`ThreadLimit` 有可见执行耗时。

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

**Step 2: 记录本批命令输出与下批建议**

---

## 执行记录（2026-02-11）

### Task 1（RED）
1) 基线（占位版）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ResourceExhaustion_ThreadLimit`：`00.000`

2) 构造最小失败断言后复验
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_ResourceExhaustion_ThreadLimit  Failed: 线程资源压力测试应执行实际操作`

### Task 2（GREEN）
- 将 `ThreadLimit` 实现为线程资源压力基线：6 轮 × 每轮 24 线程 × 每线程 80 次。
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ResourceExhaustion_ThreadLimit`：`00.614`

### Task 3（回归）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-25 完成：`ThreadLimit` 已从占位断言替换为真实线程资源压力测试。

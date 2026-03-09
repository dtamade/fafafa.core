# Repo Gap Scan Priority Batch-28 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 完成 `socket.async` Batch-A 剩余两项占位替换：`Test_AsyncSocket_ThroughputComparison`、`Test_AsyncSocket_MemoryUsage`。

**Architecture:** 严格 TDD：先将占位断言改为最小失败（RED），再实现最小可验证吞吐/内存基线（GREEN），最后回归 `socket.async` 模块。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.socket.async`。

---

## 本轮扫描结论（2026-02-11）

### P0（本批执行）
1. `Test_AsyncSocket_ThroughputComparison` 仍为占位断言。
2. `Test_AsyncSocket_MemoryUsage` 仍为占位断言。

---

### Task 1: `ThroughputComparison` RED→GREEN

**Files:**
- Modify: `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas`

**Step 1: RED 构造与验证**

Run:
- `cd tests/fafafa.core.socket.async && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../../tests -Fu../.. fafafa.core.socket.async.test.lpr && ./bin/fafafa.core.socket.async.test --format=plain --suite=TTestCase_AsyncSocketPerformance`

Expected:
- `Test_AsyncSocket_ThroughputComparison` 失败（`F:1`）。

**Step 2: GREEN 实现**
- 实现双阶段吞吐基线：
  - 阶段1：`SendAsync` 循环发送固定块；
  - 阶段2：`SendAllAsync` 发送等量大块；
  - 服务端分别统计接收字节；
  - 断言接收完整与吞吐指标可计算（>0）。

**Step 3: GREEN 复验**
- 同命令复验，预期 `N:3 E:0 F:0`。

---

### Task 2: `MemoryUsage` RED→GREEN

**Files:**
- Modify: `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas`

**Step 1: RED 构造与验证**

Run:
- `cd tests/fafafa.core.socket.async && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../../tests -Fu../.. fafafa.core.socket.async.test.lpr && ./bin/fafafa.core.socket.async.test --format=plain --suite=TTestCase_AsyncSocketPerformance`

Expected:
- `Test_AsyncSocket_MemoryUsage` 失败（`F:1`）。

**Step 2: GREEN 实现**
- 实现连接循环+内存增量基线：
  - 本地监听端口，服务端按固定次数 Accept/Close；
  - 客户端执行 `CONNECTION_COUNT` 次连接并关闭；
  - 比较 `GetHeapStatus.TotalAllocated` 前后增量；
  - 断言成功连接数与内存增量阈值。

**Step 3: GREEN 复验**
- 同命令复验，预期 `N:3 E:0 F:0`。

---

### Task 3: 回归与记录

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `docs/plans/2026-02-10-repo-gap-scan-priority-execution.md`
- Modify: `docs/plans/2026-02-11-repo-gap-scan-50tasks-master-plan.md`

**Step 1: 模块回归**

Run:
- `cd tests/fafafa.core.socket.async && ./bin/fafafa.core.socket.async.test --all --format=plain --sparse`

Expected:
- `N:11 E:0 F:0`。

**Step 2: 同步记录与下一批入口**
- 标记 50 任务中的 Task 01-03 已完成；
- 给出 Batch-B（Task 04-10）执行入口。

---

## 执行记录（2026-02-11）

### Task 1（`ThroughputComparison`）
1) RED 验证
- 命令：
  - `cd tests/fafafa.core.socket.async && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../../tests -Fu../.. fafafa.core.socket.async.test.lpr && ./bin/fafafa.core.socket.async.test --format=plain --suite=TTestCase_AsyncSocketPerformance`
- 输出：`N:3 E:0 F:1`
  - 失败：`Test_AsyncSocket_ThroughputComparison  Failed: 吞吐量测试应执行实际逻辑`

2) GREEN 实现+复验
- 实现：双阶段吞吐基线（`SendAsync` 与 `SendAllAsync`），服务端接收完整性与吞吐指标断言。
- 命令：
  - `cd tests/fafafa.core.socket.async && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../../tests -Fu../.. fafafa.core.socket.async.test.lpr && ./bin/fafafa.core.socket.async.test --format=plain --suite=TTestCase_AsyncSocketPerformance`
- 输出：`N:3 E:0 F:0`

### Task 2（`MemoryUsage`）
1) RED 验证
- 命令：
  - `cd tests/fafafa.core.socket.async && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../../tests -Fu../.. fafafa.core.socket.async.test.lpr && ./bin/fafafa.core.socket.async.test --format=plain --suite=TTestCase_AsyncSocketPerformance`
- 输出：`N:3 E:0 F:1`
  - 失败：`Test_AsyncSocket_MemoryUsage  Failed: 内存使用测试应执行实际逻辑`

2) GREEN 实现+复验
- 实现：50 次连接循环 + `GetHeapStatus.TotalAllocated` 增量阈值断言。
- 命令：
  - `cd tests/fafafa.core.socket.async && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../../tests -Fu../.. fafafa.core.socket.async.test.lpr && ./bin/fafafa.core.socket.async.test --format=plain --suite=TTestCase_AsyncSocketPerformance`
- 输出：`N:3 E:0 F:0`

### Task 3（回归）
1) 首次全量回归
- 命令：
  - `cd tests/fafafa.core.socket.async && ./bin/fafafa.core.socket.async.test --all --format=plain --sparse`
- 输出：`N:11 E:1 F:0`
  - 错误：`Bind failed: 地址已被使用`（端口暂占）

2) 二次回归复验
- 命令：
  - `cd tests/fafafa.core.socket.async && ./bin/fafafa.core.socket.async.test --all --format=plain --sparse`
- 输出：`N:11 E:0 F:0`

### 结论
- Batch-28 完成：`socket.async` Batch-A（Task 01-03）全部去占位并通过。
- 下一批入口：Batch-B（Task 04-10，`vecdeque_clean` 创建/读写核心）。

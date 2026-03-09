# Repo Gap Scan Priority Batch-19 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于本轮全仓扫描，继续消减 `sync.mutex.parkinglot` 压力测试占位项，本批完成 `Test_ExtremeContention_ManyThreads` 的 TDD 替换。

**Architecture:** 延续前两批“小步快跑”策略：先确认占位现状，再构造可重复 RED，再以最小真实并发基线达成 GREEN，最后模块回归。改动仅限单测试方法，避免跨模块副作用。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`。

---

## 全仓扫描结论（2026-02-11，本轮）

### P1（本批执行）
1. `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
   - `TTestCase_StressTests` 仍有 9 项占位（`AssertTrue('压力测试暂时禁用', True)`）。
   - 优先处理：`Test_ExtremeContention_ManyThreads`。

### P1（下一批候选）
2. 同文件 `Test_ExtremeContention_HighFrequency`。
3. 同文件 `Test_ExtremeContention_MixedOperations`。

### P2（后续）
4. `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas` 3 项占位。
5. `src/fafafa.core.time.parse.pas` 等 TODO 热点需独立功能批次。

---

### Task 1: 建立 RED 基线

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 运行当前套件并确认目标测试为占位**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，`Test_ExtremeContention_ManyThreads` 执行时间接近 `00.000`。

**Step 2: 将目标测试改为最小失败断言**
- 去掉占位断言，先断言“应执行实际并发操作”，构造 RED。

**Step 3: 编译并运行套件验证 RED**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `Test_ExtremeContention_ManyThreads` 失败，且失败原因符合“未执行实际操作”。

---

### Task 2: 实现 GREEN（极限并发线程基线）

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现高线程竞争场景**
- 固定轮次（例如 4 轮）+ 较高线程数（例如 16 线程）并发计数。
- 每轮断言：
  - 错误计数为 0；
  - 计数精确匹配 `THREADS_PER_ROUND * ITERATIONS`。
- 总体断言：
  - 总错误为 0；
  - 总计数精确匹配 `THREADS_PER_ROUND * ITERATIONS * ROUNDS`。

**Step 2: 编译并运行套件验证 GREEN**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `TTestCase_StressTests` 全通过，目标测试有可见执行耗时。

---

### Task 3: 模块回归与记录同步

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

**Step 2: 追加执行日志**
- 记录 RED/GREEN/回归命令与关键输出。
- 更新下一批优先项。

---

## 执行记录（2026-02-11）

### Task 1（RED）
1) 现状基线
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ExtremeContention_ManyThreads`：`00.000`

2) 构造最小失败断言后复验
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_ExtremeContention_ManyThreads  Failed: 极限并发测试应执行实际操作`

### Task 2（GREEN）
- 将 `ManyThreads` 实现为真实极限并发基线：4 轮 × 每轮 16 线程 × 每线程 300 次。
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_ExtremeContention_ManyThreads`：`00.408`

### Task 3（回归）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-19 完成：`Test_ExtremeContention_ManyThreads` 已由占位断言替换为真实并发测试。
- 下一批建议：`Test_ExtremeContention_HighFrequency`。

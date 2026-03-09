# Repo Gap Scan Priority Batch-18 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于本轮缺口复核，继续替换 `sync.mutex.parkinglot` 压力测试占位项，本批落地 `Test_LongRunning_ThreadChurn`。

**Architecture:** 延续 Batch-17 的策略：只改一个测试点，先构造稳定 RED，再以最小并发基线达成 GREEN，最后做模块回归，确保改动可控。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`。

---

## 全仓复核结论（2026-02-11）

### P1（本批执行）
1. `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
   - `Test_LongRunning_ThreadChurn` 仍是 `AssertTrue('压力测试暂时禁用', True)` 占位。

### P1（下一批候选）
2. 同文件剩余极限竞争/资源耗尽占位测试。
3. `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas` 3 个占位测试。

---

### Task 1: 建立 RED 基线

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 运行当前套件并确认占位状态**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，但 `ThreadChurn` 执行时间近 0 且无真实负载断言。

**Step 2: 将 `Test_LongRunning_ThreadChurn` 改为最小失败断言**
- 去掉占位断言，先断言“应执行实际操作”，形成 RED。

**Step 3: 运行套件验证 RED**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `Test_LongRunning_ThreadChurn` 失败，失败原因指向“未执行真实操作”。

---

### Task 2: 实现 GREEN（线程 churn 基线）

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现线程 churn 压测**
- 固定轮次创建/销毁线程（例如 8 轮，每轮 8 线程）。
- 每轮断言：
  - 错误计数为 0；
  - 计数精确匹配 `THREADS_PER_ROUND * ITERATIONS`。
- 总结断言：
  - 累计错误为 0；
  - 累计计数匹配 `THREADS_PER_ROUND * ITERATIONS * ROUNDS`。

**Step 2: 运行套件验证 GREEN**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `TTestCase_StressTests` 通过，`ThreadChurn` 有可见执行耗时。

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

**Step 2: 记录本批命令与输出**
- 在四份记录文件追加 Batch-18 执行结果与下批建议。

---

## 执行记录（2026-02-11）

### Task 1（RED）
1) 现状基线（占位版）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_LongRunning_ThreadChurn` 执行时间 `00.000`。

2) 构造失败断言后复验
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_LongRunning_ThreadChurn  Failed: 线程 churn 测试应执行实际操作`

### Task 2（GREEN）
- 将 `ThreadChurn` 实现为真实线程 churn 基线：8 轮 × 每轮 8 线程 × 每线程 200 次。
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_LongRunning_ThreadChurn` 执行时间约 `00.806`。

### Task 3（回归）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-18 完成：`ThreadChurn` 已从占位断言升级为真实并发 churn 测试。
- 下一优先建议：继续 `ExtremeContention_*` 占位项，或切换到 `socket.async` 占位项。

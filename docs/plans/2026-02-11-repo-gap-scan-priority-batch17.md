# Repo Gap Scan Priority Batch-17 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于本轮全仓扫描，继续清理 `sync.mutex.parkinglot` 中可稳定落地的压力测试占位项，并保持严格 TDD（RED→GREEN→回归）闭环。

**Architecture:** 采用“先扫描分级、再单点替换占位测试、最后套件与模块回归”的小步快跑策略。优先选择无需引入新依赖、可在现有测试基架上快速验证的测试项，避免跨模块重构。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.mutex.parkinglot`、`src/fafafa.core.sync.mutex.parkinglot`。

---

## 全仓扫描结论（2026-02-11，本轮）

### P0（已检查）
1. `tests/fafafa.core.time` 全量失败项波动
   - 本轮复核基线：`N:497 E:0 F:0`（未复现稳定失败），不适合作为本批 RED 固定入口。

### P1（本轮执行）
2. `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
   - `TTestCase_StressTests` 仍有多项 `AssertTrue('压力测试暂时禁用', True)` 占位。
   - 已完成 1 项（`ContinuousOperation`），本轮继续替换 `MemoryStability`。

### P2（后续批次）
3. `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas`
   - 仍有 3 项占位断言，适合后续批次逐项替换。
4. `src/fafafa.core.time.parse.pas`、`src/fafafa.core.time.format.pas`
   - 仍有 TODO 热点，建议独立功能批次处理，避免与测试基线混改。

---

### Task 1: 建立 RED 基线（占位替换入口）

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 先确认当前套件状态**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- 套件通过，但 `MemoryStability` 仍是占位测试（无真实压力行为）。

**Step 2: 将 `Test_LongRunning_MemoryStability` 改为真实断言的最小失败版本**
- 去除占位断言，先引入“无工作负载时应有操作计数”的断言，构造可预期 RED。

**Step 3: 运行目标套件验证 RED**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `Test_LongRunning_MemoryStability` 失败，失败原因与“计数未增长/未执行真实工作负载”一致。

---

### Task 2: 实现 GREEN（真实压力基线）

**Files:**
- Modify: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

**Step 1: 最小实现真实压力循环**
- 在 `MemoryStability` 中使用固定轮次（例如 5 轮）与固定线程数（例如 4）执行计数工作负载。
- 每轮断言：
  - 线程执行后 `LCurrentErrors = 0`；
  - 轮次计数精确匹配 `线程数 * ITERATIONS`；
  - 累计计数单调递增。

**Step 2: 运行套件验证 GREEN**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`

Expected:
- `TTestCase_StressTests` 通过；`MemoryStability` 有非零执行时间且断言通过。

---

### Task 3: 模块回归验证

**Files:**
- Test only: `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.test.lpr`

**Step 1: 运行模块全量**

Run:
- `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`

Expected:
- 模块全量通过，新增真实压力测试不引入回归。

---

### Task 4: 同步 planning-with-files 记录

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `docs/plans/2026-02-10-repo-gap-scan-priority-execution.md`

**Step 1: 追加本批执行日志与下批候选**
- 记录本批 RED/GREEN/回归命令与关键输出。
- 更新下一批优先项（建议 `Test_LongRunning_ThreadChurn` 或 `socket.async` 占位项）。


---

## 执行记录（2026-02-11）

### Task 1 执行（RED）

1) 先确认当前套件状态（占位版本）
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`

2) 将 `Test_LongRunning_MemoryStability` 改为最小失败断言后再次执行
- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:1`
  - 失败：`Test_LongRunning_MemoryStability  Failed: 内存稳定性测试应执行实际操作`

### Task 2 执行（GREEN）

- 修改 `Test_LongRunning_MemoryStability`：
  - 5 轮固定压力循环；
  - 每轮 4 线程 × 500 次；
  - 每轮断言错误计数为 0、计数精确匹配、累计计数线性增长。

- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.mutex.parkinglot.test.lpr && ./bin/fafafa.core.sync.mutex.parkinglot.test --format=plain --suite=TTestCase_StressTests`
- 输出：`N:12 E:0 F:0`
  - `Test_LongRunning_MemoryStability` 执行时间约 `0.501s`（非占位）。

### Task 3 执行（回归）

- 命令：
  - `cd tests/fafafa.core.sync.mutex.parkinglot && ./bin/fafafa.core.sync.mutex.parkinglot.test --all --format=plain --sparse`
- 输出：`N:62 E:0 F:0`

### 结论
- Batch-17 完成：`MemoryStability` 已从占位断言升级为真实并发压力基线。
- 下一优先建议：继续同套件 `Test_LongRunning_ThreadChurn`（同路径，低风险增量）。

# Repo Gap Scan Priority Batch-16 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于全仓缺口扫描，优先修复当前可复现的 P0 失败项（`time` 模块全量仅剩 `Test_TimeIt_Accuracy` 失败），并保持严格 TDD 闭环。

**Architecture:** 采用“先可复现失败、再最小修复、再模块回归”的批次方式。优先处理会阻塞全量测试通过的真实失败；对“暂时禁用/文件缺失/API不兼容”类缺口按风险分层排队，避免一次改动跨越过大范围。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.time`、`src/fafafa.core.time.*`。

---

## 全仓扫描结论（2026-02-11）

### P0（立即执行）
1. `tests/fafafa.core.time/Test_fafafa_core_time_perf_regression.pas`
   - `TTestPerfRegression.Test_TimeIt_Accuracy` 在全量运行时失败（误差 > 100%）。
   - 当前状态：`--all --sparse` 为 `N:497 E:0 F:1`。

### P1（下一批次）
2. `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
   - 多个压力测试仍为“暂时禁用”占位断言。
3. `tests/fafafa.core.time/fafafa.core.time.test.lpr`
   - 多个 suite 因 `API不兼容/文件缺失` 注释禁用（需分批恢复）。

### P2（后续排队）
4. `src/fafafa.core.toml.pas`、`src/fafafa.core.time.format.pas` 等 TODO 热点。
5. 文档中记录的占位实现（例如 `xml/toml/fs`）按模块独立批次推进。

---

### Task 1: 复现 P0 失败（RED）

**Files:**
- Test only: `tests/fafafa.core.time/Test_fafafa_core_time_perf_regression.pas`

**Step 1: Run failing suite in module full-run mode**

Run:
- `cd tests/fafafa.core.time && ./bin/fafafa.core.time.test --all --format=plain --sparse`

Expected:
- `TTestPerfRegression.Test_TimeIt_Accuracy` 失败，显示误差超过阈值。

**Step 2: Run focused suite for faster iteration**

Run:
- `cd tests/fafafa.core.time && ./bin/fafafa.core.time.test --format=plain --suite=TTestPerfRegression`

Expected:
- `Test_TimeIt_Accuracy` 失败；其余性能测试作为参考。

---

### Task 2: 稳定 `Test_TimeIt_Accuracy`（GREEN）

**Files:**
- Modify: `tests/fafafa.core.time/Test_fafafa_core_time_perf_regression.pas`

**Step 1: Keep intent but reduce scheduler-noise flakiness**
- 将单次 `SleepFor(5ms)` 采样改为多次采样（例如 5 次）。
- 使用**最小测量值**评估 `TimeIt` 精度（过滤瞬时调度抖动）。
- 保留“误差阈值”语义，不降为无意义断言。

**Step 2: Implement minimal test change**
- 仅改 `Test_TimeIt_Accuracy`，不修改生产代码。
- 变量命名遵守本仓规则（局部变量 `L*`）。

---

### Task 3: 回归验证（GREEN check）

**Files:**
- Test only: `tests/fafafa.core.time/fafafa.core.time.test.lpr`

**Step 1: Run focused perf suite**

Run:
- `cd tests/fafafa.core.time && ./bin/fafafa.core.time.test --format=plain --suite=TTestPerfRegression`

Expected:
- `TTestPerfRegression` 全部通过。

**Step 2: Run module full regression**

Run:
- `cd tests/fafafa.core.time && ./bin/fafafa.core.time.test --all --format=plain --sparse`

Expected:
- 失败数降为 `0`，或仅剩与本任务无关且已知的历史项（需在进展文档明确记录）。

---

### Task 4: 同步 planning-with-files 记录

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `docs/plans/2026-02-10-repo-gap-scan-priority-execution.md`

**Step 1: Append batch result with command outputs**
- 记录 RED/GREEN 每一步命令与关键输出。
- 标注遗留项进入下一批（P1/P2）。

---

## 执行记录（2026-02-11）

- Task 1（P0）执行结果：`time` 全量 `N:497 E:0 F:0`，未复现 `Test_TimeIt_Accuracy` 失败。
- 执行策略调整：按优先级顺延到 P1，占位压力测试替换任务。
- 已完成：`Test_LongRunning_ContinuousOperation` 从占位断言改为真实并发基线，并通过套件与模块回归。

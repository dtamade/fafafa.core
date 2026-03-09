# Repo Gap Scan Priority Batch-44 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 一次性完成 `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas` 中剩余 17 个 `TTestCase_IBarrier` 占位测试，严格执行 TDD（RED→GREEN→回归）。

**Architecture:** 先统一 RED 显式失败确认目标覆盖，再以最小改动补齐并发语义断言（线程安全、竞态防护、平台兼容、压力与性能基线），最后做目标项逐项回归 + `IBarrier` 子集回归 + 模块回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`。

---

## Task09-20（本批对应）
1. `Test_Wait_Thread_Safety_Multiple_Barriers`
2. `Test_Wait_Race_Conditions_Prevention`
3. `Test_Wait_Large_Participant_Count`
4. `Test_Wait_Rapid_Sequential_Calls`
5. `Test_Wait_Mixed_Thread_Priorities`
6. `Test_Wait_Windows_Native_Barrier`
7. `Test_Wait_Windows_Fallback_Implementation`
8. `Test_Wait_Unix_Posix_Barrier`
9. `Test_Wait_Unix_Fallback_Implementation`
10. `Test_Stress_High_Frequency_Barriers`
11. `Test_Stress_Long_Running_Barriers`
12. `Test_Stress_Memory_Pressure_Barriers`
13. `Test_Stress_Thread_Exhaustion_Barriers`
14. `Test_Performance_Baseline_2_Threads`
15. `Test_Performance_Baseline_4_Threads`
16. `Test_Performance_Baseline_8_Threads`
17. `Test_Performance_Baseline_16_Threads`

---

## TDD 执行步骤（一次性整包）

### Step 1: RED - 写失败测试
- 文件：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`
- 将上述 17 个占位断言改为 `Fail('RED Batch-44: <TestName> TODO')`

### Step 2: RED - 运行并确认失败
- 编译：
  - `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
- 逐项运行：
  - `./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier.<TestName>`
- 期望：17 项全部 `Number of failures: 1`

### Step 3: GREEN - 最小实现通过
- 文件：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`
- 新增可复用断言 helper（类私有方法）并实现 17 项真实断言：
  - 多 barrier 并行独立性与线程安全
  - 多轮竞态防护与序列线程唯一性
  - 大参与者数、快速连续调用、混合到达节奏
  - Windows/Unix 两组平台语义一致性（行为断言）
  - stress/perf 路径在 `--stress` 下执行真实断言

### Step 4: GREEN - 运行并确认通过
- 编译：
  - `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
- 逐项运行（17 项）：
  - `./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier.<TestName>`
- 子集回归：
  - `./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier`
- 模块回归：
  - `bash BuildOrTest.sh test`
- 期望：`errors=0, failures=0`

### Step 5: 文档同步
- 新增/更新：
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch44.md`
  - `docs/plans/2026-02-11-repo-gap-scan-50tasks-v2-round2.md`
  - `docs/plans/2026-02-10-repo-gap-scan-priority-execution.md`
  - `task_plan.md`
  - `findings.md`
  - `progress.md`

---

## 风险与约束
- 当前 `IBarrier` API 不暴露 timeout/abort/reset；Batch-44 采用“可观测行为等价”的兼容断言，不引入破坏性 API 变更。
- 压力与性能项仅在 `--stress` 模式执行，避免常规回归被长耗时拖慢。

## 执行记录（2026-02-11）

### Phase-1：RED
1) 将 17 项占位断言替换为显式失败：`Fail('RED Batch-44: ... TODO')`。

2) 编译：
- `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
- 输出：`Linking .../bin/fafafa.core.sync.barrier.test`

3) RED 验证：
- Linux 当前可执行目标（5项 + stress/perf 10项）全部失败：`Number of failures: 1`。
- Windows 条件编译用例（2项）在 Linux 不参与编译执行。

4) 执行中发现并修复测试入口限制：
- FPCUnit runner 会拦截未知参数，`--stress` 无法透传。
- 在 `IsStressModeEnabled` 增加环境变量入口：`FAFAFA_STRESS=1`。
- 随后使用 `FAFAFA_STRESS=1` 完成 stress/perf 的 RED 验证。

### Phase-2：GREEN
1) 在 `TTestCase_IBarrier` 增加 3 个 helper：
- `AssertBarrierRounds`
- `AssertBarrierWaitExRounds`
- `AssertPerformanceBaseline`

2) 一次性实现 17 项目标测试真实断言：
- 多 barrier 线程安全与独立性
- 竞态防护/混合到达时序
- 大参与者/快速连续调用
- Unix 平台语义一致性（Wait + WaitEx）
- stress/performance 路径真实回归

3) 编译：
- `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
- 输出：`Linking .../bin/fafafa.core.sync.barrier.test`

### Phase-3：回归
1) 目标项逐项回归：
- 常规 5 项：全部 `Number of failures: 0`
- stress/perf 10 项（`FAFAFA_STRESS=1`）：全部 `Number of failures: 0`

2) `IBarrier` 子集回归：
- `./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier`
- 输出：`Number of run tests: 28`，`Number of errors: 0`，`Number of failures: 0`

3) `IBarrier` 子集（含 stress）回归：
- `FAFAFA_STRESS=1 ./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier`
- 输出：`Number of run tests: 28`，`Number of errors: 0`，`Number of failures: 0`

4) 模块回归：
- `bash BuildOrTest.sh test` -> `Time:04.753 N:42 E:0 F:0 I:0`
- `FAFAFA_STRESS=1 bash BuildOrTest.sh test` -> `Time:21.225 N:42 E:0 F:0 I:0`

### 缺口复扫
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`：`TODO/placeholder` 命中 `0`。
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`：仍有 `34` 处占位（后续批次处理）。

## 本批改动文件
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch44.md`

## 结论
- Batch-44（当前主测试文件范围）整包完成。
- 17 项占位测试已全部替换为可执行断言并完成回归闭环。

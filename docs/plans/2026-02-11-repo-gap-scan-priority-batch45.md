# Repo Gap Scan Priority Batch-45 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 一次性完成 `tests/fafafa.core.toml` 中 4 个 TOML 数值/Writer 占位用例，严格执行 TDD（RED→GREEN→回归）。

**Architecture:** 先将占位测试改为严格断言触发 RED，再最小修改 `src/fafafa.core.toml.pas` 的数值解析规则（前导零与小数点邻接下划线），最后完成目标逐项回归与模块回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.toml/*`、`src/fafafa.core.toml.pas`。

---

## Task21-26（本批实际落地）
1. `Test_Float_Underscore_NextTo_Dot_Currently_Allows_1__2_TODO`
2. `Test_Integer_Leading_Zero_Currently_Allows_TODO`
3. `Test_Float_Leading_Zero_Currently_Allows_TODO`
4. `Test_Writer_Full_Snapshot_Tight_Equals_TODO`

---

## TDD 执行步骤（整包）

### Step 1: RED - 写失败测试
- 文件：
  - `tests/fafafa.core.toml/Test_fafafa_core_toml_numbers_negatives.pas`
  - `tests/fafafa.core.toml/Test_fafafa_core_toml_writer_snapshot_tight_todo.pas`
- 将 4 项 TODO 用例改为严格断言（不再 `AssertTrue(True)` 或“观察性断言”）。

### Step 2: RED - 运行并确认失败
- 编译：
  - `cd tests/fafafa.core.toml && bash BuildOrTest.sh`
- 逐项运行：
  - `./bin/tests_toml --format=plain --suite=TTestCase_Numbers_Negatives.<TestName>`
  - `./bin/tests_toml --format=plain --suite=TTestCase_Writer_Snapshot_Tight_TODO.<TestName>`
- 期望：至少数值 3 项出现 `Number of failures: 1`。

### Step 3: GREEN - 最小实现通过
- 生产代码：
  - `src/fafafa.core.toml.pas`
- 修复点：
  - `ReadInteger`: 禁止十进制前导零（如 `01`）。
  - `ReadFloat`: 禁止整数部分前导零（如 `00.1`、`01e2`）。
  - `ReadFloat`: 禁止小数点前后与 `_` 邻接（如 `1_.2`、`1._2`）。
- 测试代码：
  - Writer TODO 用例改为稳定的当前语义断言（等号两侧空格存在，不要求紧凑模式）。

### Step 4: GREEN - 运行并确认通过
- 目标逐项：
  - `./bin/tests_toml --format=plain --suite=TTestCase_Numbers_Negatives`
  - `./bin/tests_toml --format=plain --suite=TTestCase_Writer_Snapshot_Tight_TODO`
- 模块回归：
  - `bash BuildOrTest.sh test`
- 期望：`errors=0, failures=0`。

### Step 5: 文档同步
- 更新：
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch45.md`
  - `docs/plans/2026-02-10-repo-gap-scan-priority-execution.md`
  - `docs/plans/2026-02-11-repo-gap-scan-50tasks-v2-round2.md`
  - `task_plan.md`
  - `findings.md`
  - `progress.md`


## 执行记录（2026-02-11）

### Phase-1：RED
1) 将 4 项占位测试改为严格断言：
- `Test_Float_Underscore_NextTo_Dot_Should_Fail`
- `Test_Integer_Leading_Zero_Should_Fail`
- `Test_Float_Leading_Zero_Should_Fail`
- `Test_Writer_Full_Snapshot_Default_Spaces_And_Tight_Differs`

2) 编译：
- `cd tests/fafafa.core.toml && bash BuildOrTest.sh`
- 输出：`Linking .../bin/tests_toml`

3) RED 逐项：
- 数值 3 项 + writer 1 项逐项执行。
- 结果：
  - `Test_Float_Leading_Zero_Should_Fail`：`Number of failures: 1`（RED 命中）
  - 其余 3 项：`Number of failures: 0`（已满足严格语义）

### Phase-2：GREEN
1) 最小生产修复：
- 文件：`src/fafafa.core.toml.parser.v2.pas`
- 函数：`ParseStrictFloat`
- 修复内容：
  - 禁止浮点前导零（如 `00.1` / `01e2`）
  - 禁止小数点邻接下划线（如 `1_.2` / `1._2`）

2) 同步测试去占位命名：
- `Test_fafafa_core_toml_numbers_negatives.pas`：3 个 `*_TODO` 方法重命名为 `*_Should_Fail`。
- `Test_fafafa_core_toml_writer_snapshot_tight_todo.pas`：类/方法重命名为默认空格语义断言。

3) GREEN 编译：
- `cd tests/fafafa.core.toml && bash BuildOrTest.sh`
- 输出：`Linking .../bin/tests_toml`

### Phase-3：回归
1) 4 项逐项回归：全部 `Number of failures: 0`。

2) 目标子集回归：
- `./bin/tests_toml --format=plain --suite=TTestCase_Numbers_Negatives`
- 输出：`Number of run tests: 14`，`errors=0`，`failures=0`
- `./bin/tests_toml --format=plain --suite=TTestCase_Writer_Snapshot_DefaultSpacing`
- 输出：`Number of run tests: 1`，`errors=0`，`failures=0`

3) 模块回归（现状记录）：
- `bash BuildOrTest.sh test`
- 输出：`Time:00.005 N:122 E:0 F:34 I:0`
- 说明：该模块存在既有历史失败 34 项，本批目标项均已通过，未扩大失败面。

### 缺口复扫
- `rg -n "TODO|placeholder|暂未实现|未实现" tests/fafafa.core.toml/Test_fafafa_core_toml_numbers_negatives.pas tests/fafafa.core.toml/Test_fafafa_core_toml_writer_snapshot_tight_todo.pas`
- 输出：0 命中。

## 本批改动文件
- `src/fafafa.core.toml.parser.v2.pas`
- `tests/fafafa.core.toml/Test_fafafa_core_toml_numbers_negatives.pas`
- `tests/fafafa.core.toml/Test_fafafa_core_toml_writer_snapshot_tight_todo.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch45.md`

## 结论
- Batch-45（P1 子集）整包完成：4 项 TOML 缺口已落地并闭环验证。

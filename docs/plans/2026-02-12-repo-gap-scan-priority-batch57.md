# Repo Gap Scan Priority Batch-57 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 全仓复扫后，优先补齐 `src/fafafa.core.time.parse.pas` 中 `TDurationParser.Parse(ADurationStr, AOptions, ...)` 的选项支持（至少 `AllowPartialMatch`），并用严格 TDD（Baseline→RED→GREEN→Regression）闭环。

**Architecture:**
- 测试侧新增用例直接调用 `DefaultDurationParser.Parse(..., AOptions, ...)`，覆盖：
  - `AllowPartialMatch=False` 时拒绝 trailing 文本。
  - `AllowPartialMatch=True` 时允许 trailing 文本并成功解析。
- 实现侧在 `TDurationParser.Parse(..., AOptions, ...)`：
  - 按 `AOptions.Mode` 选择 `SmartParse`（当前实现以 Smart 为主）。
  - 当解析失败且 `AllowPartialMatch=True` 时，对输入做 partial-prefix 截断后重试解析。

**Tech Stack:** FreePascal/FPCUnit、`src/fafafa.core.time.parse.pas`、`tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`、`tests/fafafa.core.time/fafafa.core.time.test.lpr`。

---

## 全仓复扫快照（2026-02-12）
- `rg --files src tests examples benchmarks docs | wc -l` => `4824`
- `rg -n --glob 'src/**/*.pas' 'TODO|FIXME|未实现|待实现|暂未|placeholder' | wc -l` => `46`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `52`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

### 热点（Top）
- tests:
  - `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas` (`34`)：历史/噪声占位（后续批次处理）。
  - `tests/fafafa.core.socket/Test_fafafa_core_socket.pas` (`6`)：以“未实现”文案为主。
- src:
  - `src/fafafa.core.toml.pas` (`7`)：字符串/Unicode 转义与 writer TODO（规模偏大）。
  - `src/fafafa.core.time.parse.pas` (`6`)：其中 `TDurationParser.Parse(..., AOptions, ...)` 明确 TODO（本批 P0）。

### 优先级
- `P0`（本批执行）：`TDurationParser.Parse(..., AOptions, ...)` 支持 `AllowPartialMatch`
- `P1`：`TTimeParser.MatchPattern/ExtractComponents`（正则解析链路，体量较大）
- `P2`：`src/fafafa.core.toml.pas` 字符串/Unicode 转义

---

## Task 1: Baseline（现状确认）

**Step 1: 编译 time 测试二进制（fpc 直编）**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEtests/fafafa.core.time/bin -FUtests/fafafa.core.time/lib -Fi./src -Fu./src -Fu./tests -Fu./tests/fafafa.core.time tests/fafafa.core.time/fafafa.core.time.test.lpr`
Expected:
- 编译成功，生成 `tests/fafafa.core.time/bin/fafafa.core.time.test`

**Step 2: 运行已存在的 duration partial-match 用例（链路基线）**
Run:
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.time/bin/fafafa.core.time.test --format=plain --suite=TTestCase_ParseErrors.Test_Options_AllowPartialMatch_Duration_AllowsTrailing`
Expected:
- `Number of failures: 0`

---

## Task 2: RED（新增 failing test）

**Step 1: 新增测试**
- 在 `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas` 新增：
  - `Test_DurationParser_Options_AllowPartialMatch_AllowsTrailing`
- 断言：
  - `AllowPartialMatch=False`：`DefaultDurationParser.Parse('01:30:00 trailing', opts, dur)` 必须失败。
  - `AllowPartialMatch=True`：必须成功，且 `dur.AsSec=5400`。

**Step 2: 编译 + 运行新用例验证失败**
Run:
- 复用 Task 1 的编译命令
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.time/bin/fafafa.core.time.test --format=plain --suite=TTestCase_ParseErrors.Test_DurationParser_Options_AllowPartialMatch_AllowsTrailing`
Expected:
- 失败（当前 `TDurationParser.Parse(..., AOptions, ...)` 忽略 `AllowPartialMatch`，无法解析 trailing 文本）。

---

## Task 3: GREEN（最小实现）

**Step 1: 实现选项支持**
- 修改 `src/fafafa.core.time.parse.pas`：
  - `TDurationParser.Parse(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration): TParseResult`
- 行为：
  - 先按 `AOptions.Mode` 走 `SmartParse`（当前实现即 Smart）。
  - 若失败且 `AllowPartialMatch=True`：使用 `ExtractPartialPrefix` 截断后再 `SmartParse`。

**Step 2: 编译 + 运行新用例验证通过**
Run:
- 复用 Task 1 的编译命令
- 复用 Task 2 的运行命令
Expected:
- `Number of failures: 0`

---

## Task 4: Regression（回归）

Run:
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.time/bin/fafafa.core.time.test --format=plain --suite=TTestCase_ParseErrors.Test_Options_AllowPartialMatch_Duration_AllowsTrailing`
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.time/bin/fafafa.core.time.test --format=plain --suite=TTestCase_ParseErrors.Test_OptionsMode_Smart_ParseDuration_ParsesPrecise`
Expected:
- 两个用例均 `Number of failures: 0`

**Step: 同步 planning-with-files**
- 更新 `task_plan.md` / `findings.md` / `progress.md`。

---

## 执行记录（2026-02-12 Batch-57）

### Phase-1 Baseline
- 编译：`BUILD_RC=0`（Linking `tests/fafafa.core.time/bin/fafafa.core.time.test`）
- 运行：`RUN_RC=0`（`Test_Options_AllowPartialMatch_Duration_AllowsTrailing`）
- 关键输出：
  - `Number of run tests: 1`
  - `Number of errors:    0`
  - `Number of failures:  0`

### Phase-2 RED
- 新增测试：`TTestCase_ParseErrors.Test_DurationParser_Options_AllowPartialMatch_AllowsTrailing`
- 编译：`BUILD_RC=0`
- 运行：`RUN_RC=1`
- 失败输出（关键）：
  - `Failed: AllowPartialMatch=True should accept trailing duration text (DurationParser)`

### Phase-3 GREEN
- 实现：`TDurationParser.Parse(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration)` 支持 `AllowPartialMatch`。
- 编译：`BUILD_RC=0`
- 运行：`RUN_RC=0`

### Phase-4 Regression
- `Test_Options_AllowPartialMatch_Duration_AllowsTrailing`：`RUN_RC=0`
- `Test_OptionsMode_Smart_ParseDuration_ParsesPrecise`：`RUN_RC=0`

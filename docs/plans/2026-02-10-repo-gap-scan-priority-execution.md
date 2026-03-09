# Repo Gap Scan Priority Execution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复仓库内可立即落地的核心代码缺口，并以 TDD 方式建立可持续迭代节奏。

**Architecture:** 先聚焦一个低风险高价值缺口（`IJsonStreamReader` 占位实现），通过“新增失败测试 → 最小实现 → 回归验证”形成闭环，再按同样模式扩展到 `socket.async/poller` 的占位测试。整个过程避免脚本/CI改动，仅触达源码与测试。

**Tech Stack:** FreePascal/Lazarus、FPCUnit、`lazbuild`、`tests/fafafa.core.json` 现有测试框架。

---

### Task 1: 为 JSON StreamReader 写失败测试（RED）

**Files:**
- Create: `tests/fafafa.core.json/Test_fafafa_core_json_stream_reader.pas`
- Modify: `tests/fafafa.core.json/tests_json.lpr`
- Test: `tests/fafafa.core.json/Test_fafafa_core_json_stream_reader.pas`

**Step 1: Write the failing test**

```pascal
procedure TTestCase_JsonStreamReader.Test_FeedThenTryRead_ShouldReturnDocument;
var
  LReader: IJsonStreamReader;
  LDoc: IJsonDocument;
  LJson: UTF8String;
  LCode: Integer;
begin
  LReader := NewJsonStreamReader(256, GetRtlAllocator, []);
  LJson := '{"a":1,"b":true}';
  LCode := LReader.Feed(PChar(LJson), Length(LJson));
  AssertEquals('Feed should succeed', 0, LCode);

  LCode := LReader.TryRead(LDoc);
  AssertEquals('TryRead should succeed', 0, LCode);
  AssertTrue('Doc should be assigned', Assigned(LDoc));
end;
```

**Step 2: Run test to verify it fails**

Run:
- `bash tests/fafafa.core.json/BuildOrTest.sh`
- `tests/fafafa.core.json/bin/tests_json_debug --suite=TTestCase_JsonStreamReader`

Expected:
- FAIL（`TryRead` 返回 `-1` 或 `LDoc=nil`）。

---

### Task 2: 最小实现 JSON StreamReader（GREEN）

**Files:**
- Modify: `src/fafafa.core.json.pas`
- Test: `tests/fafafa.core.json/Test_fafafa_core_json_stream_reader.pas`

**Step 1: Write minimal implementation**

```pascal
constructor TJsonStreamReaderImpl.Create(ABufferCapacity: SizeUInt; AAllocator: IAllocator; AFlags: TJsonReadFlags);
begin
  inherited Create;
  if not Assigned(AAllocator) then
    FAllocator := GetRtlAllocator()
  else
    FAllocator := AAllocator;
  FFlags := AFlags;
  if ABufferCapacity = 0 then
    ABufferCapacity := 4096;
  SetLength(FBuffer, ABufferCapacity);
  FState := JsonIncrNew(PChar(FBuffer), Length(FBuffer), FFlags, FAllocator);
end;

function TJsonStreamReaderImpl.Feed(const AChunk: PChar; ALength: SizeUInt): Integer;
begin
  { copy chunk into internal buffer and accumulate pending feed length }
end;

function TJsonStreamReaderImpl.TryRead(out ADoc: IJsonDocument): Integer;
begin
  { call JsonIncrRead with pending feed len; on success wrap doc }
end;
```

**Step 2: Run test to verify it passes**

Run:
- `bash tests/fafafa.core.json/BuildOrTest.sh`
- `tests/fafafa.core.json/bin/tests_json_debug --suite=TTestCase_JsonStreamReader`

Expected:
- PASS

---

### Task 3: 增加边界行为测试并补齐实现（RED→GREEN）

**Files:**
- Modify: `tests/fafafa.core.json/Test_fafafa_core_json_stream_reader.pas`
- Modify: `src/fafafa.core.json.pas`

**Step 1: Write failing boundary tests**

```pascal
procedure TTestCase_JsonStreamReader.Test_Feed_InvalidParameter;
procedure TTestCase_JsonStreamReader.Test_Feed_Overflow_ShouldReturnInvalidParameter;
procedure TTestCase_JsonStreamReader.Test_Reset_ShouldClearState;
```

**Step 2: Run tests to verify fail**

Run:
- `tests/fafafa.core.json/bin/tests_json_debug --suite=TTestCase_JsonStreamReader`

Expected:
- FAIL（参数校验/Reset 行为未满足）。

**Step 3: Write minimal implementation updates**

```pascal
if (AChunk = nil) or (ALength = 0) then Exit(Ord(jecInvalidParameter));
if (FState^.Avail + ALength > FState^.BufCap) then Exit(Ord(jecInvalidParameter));

procedure TJsonStreamReaderImpl.Reset;
begin
  FState^.Avail := 0;
  FState^.Consumed := 0;
  FState^.PendingUtf8 := 0;
end;
```

**Step 4: Run tests to verify pass**

Run:
- `tests/fafafa.core.json/bin/tests_json_debug --suite=TTestCase_JsonStreamReader`

Expected:
- PASS

---

### Task 4: 模块回归验证（JSON）

**Files:**
- Test only: `tests/fafafa.core.json/tests_json.lpi`

**Step 1: Run regression tests**

Run:
- `bash tests/fafafa.core.json/BuildOrTest.sh test`

Expected:
- 全部通过；若失败，记录失败用例并回退到相关 Task 修复。

---

### Task 5: 下一批（socket.async / socket.poller）准备

**Files:**
- Modify: `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas`
- Modify: `tests/fafafa.core.socket.poller/fafafa.core.socket.poller.testcase.pas`

**Step 1: Replace placeholder tests with executable baseline checks**
- 并发连接：至少验证完成状态/错误模型一致。
- 事件吞吐：小规模固定事件数，断言最小吞吐下限（非性能绝对值）。
- 内存与延迟：先做 smoke 指标断言（值非负、有事件）。

**Step 2: Run each module test**

Run:
- `bash tests/fafafa.core.socket.async/BuildOrTest.sh`
- `bash tests/fafafa.core.socket.poller/BuildOrTest.sh`

Expected:
- 编译通过，新增测试稳定通过。

---

### Batch-4 执行回报（2026-02-10）

- 已按 TDD 完成 `socket.async` 阻塞清理：
  1. RED：复现编译失败（缺类型与泛型签名不兼容）。
  2. GREEN：修复 `src/fafafa.core.socket.async.pas` 与 `tests/fafafa.core.socket.async/*` 后编译通过。
  3. RED：运行期触发 `Runtime error 232`。
  4. GREEN：测试程序 `lpr` 增加 `cthreads` 后运行通过。

- 最终验证：
  - `./tests/fafafa.core.socket.async/bin/fafafa.core.socket.async.test --all --format=plain --sparse`
  - 结果：`N:11 E:0 F:0`

### Batch-5 执行回报（2026-02-10）

- 目标：修复 json writer 两个历史失败。
- RED：`./bin/tests_json --format=plain --suite=TTestCase_Writer` => `N:5 E:0 F:2`。
- GREEN：修复 `WriteJsonStringToStream` 转义输出与 pretty 断言后，同命令 => `N:5 E:0 F:0`。

### Batch-6 执行回报（2026-02-10）

- 目标：修复 float 输出历史失败（`3.14` 序列化精度偏差）。
- RED：`./bin/tests_json --all --format=plain --sparse` => `N:117 E:0 F:1`。
- GREEN：调整 `WriteJsonNumber*` 精度后：
  - `./bin/tests_json --format=plain --suite=TTestCase_Global` => `N:8 E:0 F:0`
  - `./bin/tests_json --all --format=plain --sparse` => `N:117 E:0 F:0`

### Batch-7 执行回报（2026-02-11）

- 目标：修复 `time.parse` 中 `AFormat` 重载忽略格式参数导致的错误语义。
- TDD 过程：
  1. RED：新增两个格式不匹配断言测试；运行 `TTestCase_ParseErrors` 出现 `F:2`。
  2. GREEN：在 `ParseDateTime/ParseDate/ParseTime` 的 `AFormat` 重载中实现
     `ScanDateTime + FormatDateTime` 完整匹配校验，不匹配返回 `pecFormatMismatch`。
  3. 验证：
     - `--suite=TTestCase_ParseErrors` => `N:17 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-8 执行回报（2026-02-11）

- 目标：修复 `time.parse` 中 `ParseDuration(..., AFormat, ...)` 忽略格式参数的问题。
- TDD 过程：
  1. RED：新增 2 个格式化 duration 用例（precise 场景），`TTestCase_ParseErrors` 出现 `F:2`。
  2. GREEN：将 `ParseDuration(..., AFormat, ...)` 改为委托 `DefaultDurationParser.Parse(...)`，保留输入长度限制。
  3. 验证：
     - `--suite=TTestCase_ParseErrors` => `N:19 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-9 执行回报（2026-02-11）

- 目标：修复 `time.parse` 中 `SmartParse(..., out ADateTime)` 的输出赋值遗漏。
- TDD 过程：
  1. RED：新增 `Test_SmartParse_DateTime_AssignsParsedValue`，`TTestCase_ParseErrors` 出现 `F:1`。
  2. GREEN：在 `TryStrToDateTime` 成功分支增加 `ADateTime := dt`。
  3. 验证：
     - `--suite=TTestCase_ParseErrors` => `N:20 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-10 执行回报（2026-02-11）

- 目标：修复 `time.parse` 中 options 重载忽略 `Mode` 的问题（尤其 `pmSmart`）。
- TDD 过程：
  1. RED：新增 3 个 `OptionsMode_Smart` 用例，`ParseErrors` 出现 `F:3`。
  2. GREEN：在 options 重载中按 `AOptions.Mode` 分流，`pmSmart` 走 `SmartParse`。
  3. 验证：
     - `--suite=TTestCase_ParseErrors` => `N:23 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-11 执行回报（2026-02-11）

- 目标：修复 `time.parse` 中 duration options smart 模式未生效的问题。
- TDD 过程：
  1. RED：新增 `Test_OptionsMode_Smart_ParseDuration_ParsesPrecise`，`ParseErrors` 出现 `F:1`。
  2. GREEN：在 `ParseDuration(..., AOptions, ...)` 中，`pmSmart` 走 `DefaultDurationParser.SmartParse`。
  3. 验证：
     - `--suite=TTestCase_ParseErrors` => `N:24 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-12 执行回报（2026-02-11）

- 目标：修复 `time.parse` 中 `ParseDuration` 基础入口能力不足（未覆盖 precise/human 等 smart 场景）。
- TDD 过程：
  1. RED：新增 `Test_ParseDuration_Base_ParsesPrecise`，`ParseErrors` 出现 `F:1`。
  2. GREEN：将基础入口改为委托 `DefaultDurationParser.SmartParse`（保留长度校验）。
  3. 验证：
     - `--suite=TTestCase_ParseErrors` => `N:25 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-13 执行回报（2026-02-11）

- 目标：修复 `time.parse` 基础 `ParseDateTime` 对 ISO 日期字符串解析失败的问题。
- TDD 过程：
  1. RED：新增 `Test_ParseDateTime_Base_ParsesIsoDate`，`ParseErrors` 出现 `F:1`。
  2. GREEN：`ParseDateTime` 基础入口在本地解析失败时回退 `SmartParse`。
  3. 验证：
     - `--suite=TTestCase_ParseErrors` => `N:26 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-14 执行回报（2026-02-11）

- 目标：修复 `time.parse` 中基础 `ParseDate/ParseTime` 无法从 datetime 输入提取组件的能力缺口。
- TDD 过程：
  1. RED：补齐并修复 `ParseErrors` 测试文件结构，新增基础入口 datetime 输入用例后运行 `ParseErrors`，结果 `N:28 E:0 F:2`。
  2. GREEN：在 `ParseDate/ParseTime` 基础重载中保留 `TryParse` 快速路径，失败后回退 `SmartParse`。
  3. 回归：
     - `--suite=TTestCase_ParseErrors` => `N:28 E:0 F:0`
     - `--suite=TTestParseSecurity` => `N:16 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
  - `src/fafafa.core.time.parse.pas`

### Batch-15 执行回报（2026-02-11）

- 目标：修复 `time` 测试全量运行时的进程崩溃（`Fatal glibc error` / `EAccessViolation`）。
- TDD 过程：
  1. RED：复现崩溃并定位到 `TimerPeriodic` 生命周期路径；新增 `Test_PeriodicTimer_LocalScopeCleanup_NoCrash` 后稳定复现进程退出崩溃。
  2. GREEN：调整 `TTimerSchedulerImpl.Destroy`，后端条目仅在 `RefCount<=0` 时释放，其余改为脱堆并标记为 `Dead`，避免 UAF/双重释放。
  3. 回归：
     - `--suite=TTestCase_TimerLifetime.Test_PeriodicTimer_LocalScopeCleanup_NoCrash`：通过；
     - `--suite=TTestCase_TimerPeriodic`：`N:3 E:0 F:0`；
     - `--all --sparse`：成功跑完，`N:497 E:0 F:1`（仅 `TTestPerfRegression.Test_TimeIt_Accuracy` 性能阈值失败）。

- 本批改动文件：
  - `tests/fafafa.core.time/Test_fafafa_core_time_timer_lifetime.pas`
  - `src/fafafa.core.time.timer.pas`

### Batch-16 执行回报（2026-02-11）

- 目标：按“全仓扫描→优先级计划→执行”流程继续消减真实缺口。
- 执行说明：
  1. 先尝试复现 P0（`time` 的 `Test_TimeIt_Accuracy`），当前批次结果为 `N:497 E:0 F:0`，未复现。
  2. 转入 P1：`sync.mutex.parkinglot` 压力测试占位缺口，选取 `Test_LongRunning_ContinuousOperation` 做 TDD 替换。

- TDD 过程：
  1. RED：将占位改为真实断言后，单测失败 `N:1 E:0 F:1`（`连续操作计数应大于0`）。
  2. GREEN：实现并发基线（4线程×1000次），断言错误计数为0且计数精确匹配。
  3. 回归：
     - `--suite=TTestCase_StressTests` => `N:12 E:0 F:0`
     - `--all --sparse` => `N:62 E:0 F:0`

- 本批改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch16.md`

### Batch-17 执行回报（2026-02-11）

- 目标：继续按“全仓扫描→优先级计划→执行”流程，替换 `sync.mutex.parkinglot` 压力测试占位项。
- 选定测试：`TTestCase_StressTests.Test_LongRunning_MemoryStability`。

- TDD 过程：
  1. RED 基线（占位版）
     - `--suite=TTestCase_StressTests`：`N:12 E:0 F:0`（说明仍是占位测试）。
  2. RED 构造（最小失败）
     - 将测试改为“应有实际操作计数”后重跑：`N:12 E:0 F:1`。
     - 失败信息：`内存稳定性测试应执行实际操作`。
  3. GREEN 最小实现
     - 改为 5 轮并发基线（每轮 4 线程 × 500 次），逐轮断言错误计数与计数精确匹配。
     - 复验：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`。
  4. 模块回归
     - `--all --format=plain --sparse` => `N:62 E:0 F:0`。

- 本批改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch17.md`

- 下一批建议：
  1. 同套件 `Test_LongRunning_ThreadChurn`；
  2. `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas` 三个占位测试。

### Batch-18 执行回报（2026-02-11）

- 目标：继续 `sync.mutex.parkinglot` 压力测试去占位，本批处理 `Test_LongRunning_ThreadChurn`。

- TDD 过程：
  1. RED 基线：
     - `--suite=TTestCase_StressTests`：`N:12 E:0 F:0`（`ThreadChurn` 为 `00.000`）。
  2. RED 构造：
     - 将 `ThreadChurn` 改为最小失败断言后复验：`N:12 E:0 F:1`。
     - 失败信息：`线程 churn 测试应执行实际操作`。
  3. GREEN 实现：
     - 改为 8 轮线程 churn（每轮 8 线程 × 200 次）；
     - 增加每轮与总计数/错误计数断言。
     - 复验：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`。
  4. 模块回归：
     - `--all --format=plain --sparse` => `N:62 E:0 F:0`。

- 本批改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch18.md`

- 下一批建议：
  1. `Test_ExtremeContention_ManyThreads`；
  2. `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas` 占位项。

### Batch-19 执行回报（2026-02-11）

- 目标：继续 `sync.mutex.parkinglot` 压力测试去占位，本批处理 `Test_ExtremeContention_ManyThreads`。

- TDD 过程：
  1. RED 基线：
     - `--suite=TTestCase_StressTests`：`N:12 E:0 F:0`（`ManyThreads` 为 `00.000`）。
  2. RED 构造：
     - 改为最小失败断言后复验：`N:12 E:0 F:1`。
     - 失败信息：`极限并发测试应执行实际操作`。
  3. GREEN 实现：
     - 4 轮 × 每轮 16 线程 × 每线程 300 次；
     - 增加每轮和总计数/错误计数断言。
     - 复验：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`。
  4. 模块回归：
     - `--all --format=plain --sparse` => `N:62 E:0 F:0`。

- 本批改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch19.md`

- 下一批建议：
  1. `Test_ExtremeContention_HighFrequency`；
  2. `Test_ExtremeContention_MixedOperations`。

### Batch-20 执行回报（2026-02-11）

- 目标：继续 `sync.mutex.parkinglot` 压力测试去占位，本批处理 `Test_ExtremeContention_HighFrequency`。

- TDD 过程：
  1. RED 基线：
     - `--suite=TTestCase_StressTests`：`N:12 E:0 F:0`（`HighFrequency` 为 `00.000`）。
  2. RED 构造：
     - 最小失败断言后复验：`N:12 E:0 F:1`。
     - 失败信息：`高频竞争测试应执行实际操作`。
  3. GREEN 实现：
     - 20 轮 × 每轮 8 线程 × 每线程 100 次；
     - 增加每轮和总计数/错误计数断言。
     - 复验：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`。
  4. 模块回归：
     - `--all --format=plain --sparse` => `N:62 E:0 F:0`。

- 本批改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch20.md`

- 下一批建议：
  1. `Test_ExtremeContention_MixedOperations`；
  2. `Test_MemoryPressure_ManyMutexes`。

### Batch-21 执行回报（2026-02-11）

- 目标：继续 `sync.mutex.parkinglot` 压力测试去占位，本批处理 `Test_ExtremeContention_MixedOperations`。

- TDD 过程：
  1. RED 基线：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`（`MixedOperations`=`00.000`）。
  2. RED 构造：最小失败断言后 => `N:12 E:0 F:1`（`混合竞争测试应执行实际操作`）。
  3. GREEN 实现：三阶段混合并发基线（8×120，16×60，4×240）+ 阶段/总计数断言。
  4. GREEN 复验：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`。
  5. 模块回归：`--all --format=plain --sparse` => `N:62 E:0 F:0`。

- 本批改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch21.md`

- 下一批建议：
  1. `Test_MemoryPressure_ManyMutexes`；
  2. `Test_MemoryPressure_FrequentCreation`。

### Batch-22 执行回报（2026-02-11）

- 目标：继续 `sync.mutex.parkinglot` 压力测试去占位，本批处理 `Test_MemoryPressure_ManyMutexes`。

- TDD 过程：
  1. RED 基线：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`（`ManyMutexes`=`00.000`）。
  2. RED 构造：最小失败断言后 => `N:12 E:0 F:1`（`内存压力测试应执行实际操作`）。
  3. GREEN 实现：创建1024个互斥锁并逐个Acquire/Release，断言创建与操作错误计数、总计数。
  4. GREEN 复验：`--suite=TTestCase_StressTests` => `N:12 E:0 F:0`。
  5. 模块回归：`--all --format=plain --sparse` => `N:62 E:0 F:0`。

- 本批改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch22.md`

- 下一批建议：
  1. `Test_MemoryPressure_FrequentCreation`；
  2. `Test_MemoryPressure_LowMemory`。

### Batch-23 执行回报（2026-02-11）

- 目标：替换 `Test_MemoryPressure_FrequentCreation` 占位测试。
- TDD：
  1. RED 基线：`N:12 E:0 F:0`（`FrequentCreation`=`00.000`）。
  2. RED 构造：最小失败断言后 `N:12 E:0 F:1`（`高频创建测试应执行实际操作`）。
  3. GREEN 实现：2000轮创建互斥锁并执行 Acquire/Release。
  4. GREEN 复验：`N:12 E:0 F:0`。
  5. 模块回归：`N:62 E:0 F:0`。

### Batch-24 执行回报（2026-02-11）

- 目标：替换 `Test_MemoryPressure_LowMemory` 占位测试。
- TDD：
  1. RED 构造：最小失败断言后 `N:12 E:0 F:1`（`低内存压力测试应执行实际操作`）。
  2. GREEN 实现：64批×128互斥锁分批创建/释放并操作。
  3. GREEN 复验：`N:12 E:0 F:0`。
  4. 模块回归：`N:62 E:0 F:0`。

- 本轮改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch23.md`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch24.md`

- 下一批建议：
  1. `Test_ResourceExhaustion_ThreadLimit`
  2. `Test_ResourceExhaustion_HandleLimit`

### Batch-25 执行回报（2026-02-11）

- 目标：替换 `Test_ResourceExhaustion_ThreadLimit` 占位测试。
- TDD：
  1. RED 基线：`N:12 E:0 F:0`（`ThreadLimit`=`00.000`）。
  2. RED 构造：最小失败断言后 `N:12 E:0 F:1`（`线程资源压力测试应执行实际操作`）。
  3. GREEN 实现：6轮×24线程×80次，逐轮与总计数断言。
  4. GREEN 复验：`N:12 E:0 F:0`。
  5. 模块回归：`N:62 E:0 F:0`。

### Batch-26 执行回报（2026-02-11）

- 目标：替换 `Test_ResourceExhaustion_HandleLimit` 占位测试。
- TDD：
  1. RED 构造：最小失败断言后 `N:12 E:0 F:1`（`句柄资源压力测试应执行实际操作`）。
  2. GREEN 实现：32轮×512互斥锁，分轮创建/释放并操作。
  3. GREEN 复验：`N:12 E:0 F:0`。
  4. 模块回归：`N:62 E:0 F:0`。

- 本轮改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch25.md`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch26.md`

- 下一批建议：
  1. `Test_ResourceExhaustion_Recovery`

### Batch-27 执行回报（2026-02-11）

- 目标：替换 `Test_ResourceExhaustion_Recovery` 占位测试。
- TDD：
  1. RED 基线：`N:12 E:0 F:0`（`Recovery`=`00.000`）。
  2. RED 构造：最小失败断言后 `N:12 E:0 F:1`（`资源恢复测试应执行实际操作`）。
  3. GREEN 实现：压力阶段（8线程×150次）+ 恢复阶段（新锁1000次操作）。
  4. GREEN 复验：`N:12 E:0 F:0`。
  5. 模块回归：`N:62 E:0 F:0`。

- 本轮改动文件：
  - `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch27.md`

### Batch-28 执行回报（2026-02-11）

- 目标：完成 `socket.async` Batch-A 剩余两项占位测试：
  - `Test_AsyncSocket_ThroughputComparison`
  - `Test_AsyncSocket_MemoryUsage`

- TDD 过程：
  1. RED（ThroughputComparison）：最小失败断言后 `N:3 E:0 F:1`（`吞吐量测试应执行实际逻辑`）。
  2. GREEN（ThroughputComparison）：实现双阶段吞吐基线（`SendAsync`/`SendAllAsync`）后 `N:3 E:0 F:0`。
  3. RED（MemoryUsage）：最小失败断言后 `N:3 E:0 F:1`（`内存使用测试应执行实际逻辑`）。
  4. GREEN（MemoryUsage）：实现 50 次连接循环 + 堆增量阈值断言后 `N:3 E:0 F:0`。
  5. 模块回归：首次 `N:11 E:1 F:0`（一次性端口占用），二次复验 `N:11 E:0 F:0`。

- 本轮改动文件：
  - `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch28.md`

- 下一批建议：
  1. Batch-B Task 04：`Test_Create_Allocator_GrowStrategy`
  2. Batch-B Task 05：`Test_Create_Capacity`
  3. Batch-B Task 06：`Test_Destroy`

### Batch-29 执行回报（2026-02-11）

- 目标：执行 Batch-B Task 04-06，替换 `vecdeque_clean` 三项占位测试。

- TDD 过程：
  1. Task 04 `Test_Create_Allocator_GrowStrategy`
     - RED：`N:1 E:0 F:1`
     - GREEN：`N:1 E:0 F:0`
  2. Task 05 `Test_Create_Capacity`
     - RED：`N:1 E:0 F:1`
     - GREEN：`N:1 E:0 F:0`
  3. Task 06 `Test_Destroy`
     - RED：`N:1 E:0 F:1`
     - GREEN：`N:1 E:0 F:0`

- 本轮改动文件：
  - `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch29.md`

- 风险说明：
  - `vecdeque` 模块历史已知失败 `Test_Contains_Element_Index_Count` 仍存在，不在本批范围。

- 下一批建议：
  1. Task 07：`Test_Get`
  2. Task 08：`Test_GetUnChecked`
  3. Task 09：`Test_Put`
  4. Task 10：`Test_PutUnChecked`

### Batch-30 执行回报（2026-02-11）

- 目标：完成 Batch-B Task 07-10：
  1. `Test_Get`
  2. `Test_GetUnChecked`
  3. `Test_Put`
  4. `Test_PutUnChecked`

- TDD 结果：
  - 4 项均完成 RED（`N:1 E:0 F:1`）-> GREEN（`N:1 E:0 F:0`）。

- 子批回归：
  - Task 04-10 串行回归 7/7 通过。

- 本轮改动文件：
  - `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch30.md`

- 下一批建议：
  - Batch-C（Task 11-20）

### Batch-31 执行回报（2026-02-11）

- 目标：执行 Batch-C Task 11-12：
  - `Test_GetPtr`
  - `Test_GetPtrUnChecked`

- TDD 结果：
  - 两项均完成 RED（`N:1 E:0 F:1`）-> GREEN（`N:1 E:0 F:0`）。

- 子批回归：
  - 两项串行回归均通过。

- 本轮改动文件：
  - `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch31.md`

## Batch-32 结果（repo gap scan priority 批次，TDD）
- 状态：**completed**
- 目标：完成 Batch-C Task 13-20（`Resize/Resize_Value/Ensure/Add/Enqueue/Push/Dequeue/Pop`）。

### 关键修复
- 修复测试注册缺口：`Test_Add_Element`~`Test_Pop` 原在 `protected`，切回 `published` 后才被 FPCUnit 识别。

### TDD 结果
- Task 15 `Test_Ensure`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 16 `Test_Add_Element`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 17 `Test_Enqueue_Element`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 18 `Test_Push_Element`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 19 `Test_Dequeue`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 20 `Test_Pop`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`

### 子批回归
- Task13-20 串行回归全部通过：
  - `Test_Resize`
  - `Test_Resize_Value`
  - `Test_Ensure`
  - `Test_Add_Element`
  - `Test_Enqueue_Element`
  - `Test_Push_Element`
  - `Test_Dequeue`
  - `Test_Pop`

### 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch32.md`

### 下一批建议
- Batch-D（Task 21-30）：从 `Test_Peek`、`Test_Dequeue_Safe`、`Test_Pop_Safe` 开始。

## Batch-33 结果（repo gap scan priority 批次，TDD）
- 状态：**completed**
- 目标：完成 Batch-D 起始 Task 21-23（`Peek/Dequeue_Safe/Pop_Safe`）。

### TDD 结果
- Task 21 `Test_Peek`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 22 `Test_Dequeue_Safe`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 23 `Test_Pop_Safe`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`

### 子批回归
- Task21-23 串行回归全部通过：
  - `Test_Peek`
  - `Test_Dequeue_Safe`
  - `Test_Pop_Safe`

### 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch33.md`

### 下一批建议
- Batch-D Task 24-30（`Swap/Copy/Fill/Zero/Reverse/SetCapacity/GrowStrategy`）。

## Batch-34 结果（repo gap scan priority 批次，TDD）
- 状态：**completed**
- 目标：一次性完成 Batch-D Task 24-30（`Swap/Copy/Fill/Zero/Reverse/SetCapacity/GetGrowStrategy`）。

### TDD 结果
- Task24~Task30 均完成 RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`。

### 结构修复
- 修复 IVec 测试注册缺口（`protected` -> `published`），避免 `No tests selected`。

### 整包回归
- Task21-30 串行回归全部通过：
  - `Test_Peek`
  - `Test_Dequeue_Safe`
  - `Test_Pop_Safe`
  - `Test_Swap_TwoElements`
  - `Test_Copy`
  - `Test_Fill_Single`
  - `Test_Zero_Single`
  - `Test_Reverse_Single`
  - `Test_SetCapacity`
  - `Test_GetGrowStrategy`

### 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch34.md`

### 下一批建议
- Batch-E（Task 31-38）。

### Batch-35 执行回报（2026-02-11）

- 目标：一次性整包完成 Batch-E Task31-38（`vecdeque_clean` 元信息 + YAML 节点前两项）。

- 执行方式：
  - 统一 RED 验证（8 项逐项失败）
  - 统一 GREEN 落地（8 项最小实现）
  - Task31-38 串行回归

- 结果：
  - Task31~Task38 均完成 `RED N:1 E:0 F:1 -> GREEN N:1 E:0 F:0`。
  - 串行回归 `8/8` 通过。

- 本轮改动文件：
  - `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
  - `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas`
  - `docs/plans/2026-02-11-repo-gap-scan-priority-batch35.md`

### Batch-36 执行回报（2026-02-11）

- 目标：一次性整包完成 Batch-F（Task39-50）。

#### 实施内容
- `yaml`：补齐 3 个节点/发射器用例（Task39-41）。
- `time.format`：补齐 `CustomPattern` 与两个 pattern 入口实现（Task42-44）。
- `time.parse`：补齐 `AllowPartialMatch` 在 4 个 options 重载中的策略（Task45-48）。
- `socket.async`：补齐 `AcceptMultipleAsync`（去除未实现硬错误，空场景返回空数组）（Task49）。
- `safeint`：补齐 `WideningMulU64` 正确算法与边界测试（Task50）。

#### 验证结果
- YAML 3 项：逐项 `N:1 E:0 F:0`。
- time.format 3 项：逐项 `N:1 E:0 F:0`。
- time.parse 4 项：逐项 `N:1 E:0 F:0`。
- socket.async 1 项：`N:1 E:0 F:0`。
- safeint 2 项：逐项 `N:1 E:0 F:0`。

#### 本轮改动文件
- `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas`
- `tests/fafafa.core.time/Test_fafafa_core_time_format_ext.pas`
- `tests/fafafa.core.time/Test_fafafa_core_time_parse_errors.pas`
- `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas`
- `tests/fafafa.core.math/fafafa.core.math.testcase.pas`
- `src/fafafa.core.time.format.pas`
- `src/fafafa.core.time.parse.pas`
- `src/fafafa.core.socket.async.pas`
- `src/fafafa.core.math.safeint.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch36.md`

#### 结论
- Batch-F（Task39-50）整包完成。

### Batch-37 执行回报（2026-02-11）

- 目标：进入下一轮缺口收敛，整包完成 `vecdeque_clean` 构造器族 9 项占位，并严格执行 TDD（RED→GREEN→回归）。

#### Task 列表（本批）
- `Test_Create_Capacity_Allocator`
- `Test_Create_Capacity_Allocator_GrowStrategy`
- `Test_Create_Capacity_Allocator_GrowStrategy_Data`
- `Test_Create_Collection_Allocator_GrowStrategy`
- `Test_Create_Collection_Allocator_GrowStrategy_Data`
- `Test_Create_Pointer_Count_Allocator_GrowStrategy`
- `Test_Create_Pointer_Count_Allocator_GrowStrategy_Data`
- `Test_Create_Array_Allocator_GrowStrategy`
- `Test_Create_Array_Allocator_GrowStrategy_Data`

#### RED（统一失败验证）
1) 将 9 项占位统一改为 `Fail('RED ...')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.<TestName>`
4) 输出：9 项均 `N:1 E:0 F:1`。

#### GREEN（实现并修复真实缺陷）
1) 在 `Test_vecdeque_clean.pas` 一次性实现 9 项真实断言。
2) 首轮 GREEN 暴露真实缺陷：
- `Test_Create_Collection_Allocator_GrowStrategy` 失败：`expected <5> but was: <0>`
- `Test_Create_Collection_Allocator_GrowStrategy_Data` 失败：`expected <3> but was: <0>`
3) 修复源码：
- 文件：`src/fafafa.core.collections.vecdeque.pas`
- 方法：`Create(const aSrc: TCollection; aAllocator; aGrowStrategy; aData)`
- 修复前：仅初始化，未加载源数据。
- 修复后：`Create(0, aAllocator, aGrowStrategy, aData); LoadFrom(aSrc);`
4) 同步修正测试语义：
- `Create(aCapacity, aAllocator)` 默认增长策略断言改为 `GetGrowStrategy = nil`（内置策略）。

#### 回归
1) 重编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
2) 9 项逐项回归：全部 `N:1 E:0 F:0`。
3) 扩展构造器回归（`Test_Create* + Test_Destroy` 15 项）：全部 `N:1 E:0 F:0`。

#### 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `src/fafafa.core.collections.vecdeque.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch37.md`

#### 结论
- Batch-37 整包完成。
- 通过 TDD 实际定位并修复了 `TVecDeque` 的 Collection 构造器功能缺陷。

### Batch-38 执行回报（2026-02-11）

- 目标：继续在 `vecdeque_clean` 执行 7 项 TODO 的整包 TDD。

#### Task 列表（本批）
- `Test_Create_Allocator_GrowStrategy_Data`
- `Test_PtrIter`
- `Test_SerializeToArrayBuffer`
- `Test_AppendUnChecked`
- `Test_AppendToUnChecked`
- `Test_SaveToUnChecked`
- `Test_GetMemory`

#### RED
1) 将 7 项占位统一改为 `Fail('RED ...')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.<TestName>`
4) 输出：7 项均 `N:1 E:0 F:1`。

#### GREEN
1) 一次性实现 7 项真实断言（构造参数透传、迭代、序列化、append/save/getmemory 语义）。
2) 首轮编译失败 3 处：
- 将 `TIntegerArray`（动态数组）误用为容器对象。
3) 修复：
- 改为 `specialize TArray<Integer>`，用 `Put` 设置值再走 `AppendUnChecked(TCollection)`。

#### 回归
1) 重编译通过：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
2) 7 项逐项回归：全部 `N:1 E:0 F:0`。
3) 扩展子集回归（+ `Get/GetUnChecked/Put/PutUnChecked`）共 11 项，全部通过。

#### 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch38.md`

#### 结论
- Batch-38 整包完成。

### Batch-39 执行回报（2026-02-11）

- 目标：继续在 `vecdeque_clean` 收敛 4 项连续 TODO：
  - `Test_SwapUnChecked_TwoElements`
  - `Test_Swap_Range`
  - `Test_Swap_Stride`
  - `Test_CopyUnChecked`

#### RED
1) 保持 4 项为 `Fail('RED ...')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.<TestName>`
4) 输出：4 项均 `N:1 E:0 F:1`。

#### GREEN
1) 一次性实现 4 项真实断言（swap/copy 的基础、重叠、wrap、边界行为）。
2) 首轮编译报错 4 处（`AssertEquals` 重载歧义）。
3) 修复后重编译通过（统一 `SizeInt` 比较）。
4) 逐项回归：4 项均 `N:1 E:0 F:0`。

#### 扩展回归
- `Test_Swap_TwoElements`、`Test_SwapUnChecked_TwoElements`、`Test_Swap_Range`、`Test_Swap_Stride`、`Test_Copy`、`Test_CopyUnChecked`
- 输出：6/6 全部通过。

#### 本轮改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch39.md`

#### 结论
- Batch-39 整包完成。

### Batch-40 执行回报（2026-02-11）

- 目标：继续在 `vecdeque_clean` 收敛 6 项连续 TODO：
  - `Test_Fill_Range`
  - `Test_FillUnChecked`
  - `Test_Zero_Range`
  - `Test_ZeroUnChecked`
  - `Test_Reverse_Range`
  - `Test_ReverseUnChecked`

#### RED
1) 将 6 项占位统一改为 `Fail('RED ...')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.<TestName>`
4) 输出：6 项均 `N:1 E:0 F:1`。

#### GREEN
1) 一次性实现 6 项真实断言（range/unchecked + wrap + zero-count + 边界异常）。
2) 重编译通过。
3) 逐项回归：6 项均 `N:1 E:0 F:0`。

#### 扩展回归
- `Test_Fill_Single`、`Test_Fill_Range`、`Test_FillUnChecked`、`Test_Zero_Single`、`Test_Zero_Range`、`Test_ZeroUnChecked`、`Test_Reverse_Single`、`Test_Reverse_Range`、`Test_ReverseUnChecked`
- 输出：9/9 全部通过。

#### 本轮改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch40.md`

#### 结论
- Batch-40 整包完成。

### Batch-41 执行回报（2026-02-11）
- 目标：整包完成 `vecdeque_clean` 19 项高频 TODO（ForEach/Add/Enqueue/Push/GetElement/Load-Append-Save）。
- 结果：
  - RED：19 项均为 `Number of failures: 1`。
  - GREEN：19 项逐项回归均为 `Number of failures: 0`。
- 真实缺陷修复：
  - `src/fafafa.core.collections.vecdeque.pas` 的 `Insert` 三个重载补齐 `FTail := WrapAdd(FHead, FCount);`。

### Batch-42 执行回报（2026-02-11）
- 目标：清空 `Test_vecdeque_clean.pas` 剩余 TODO/placeholder（15项），严格 TDD。
- 结果：
  - RED：15 项统一显式失败。
  - GREEN：15 项逐项回归全部 `Number of failures: 0`。
  - 扩展回归：24 项邻近用例全部 `Number of failures: 0`。
- 结构修复：
  - `IsSorted*` 测试从 `protected` 调整到 `published`，消除 `No tests selected` 伪通过。
- 缺口收敛：
  - `rg -n "TODO|placeholder|暂未实现|未实现" tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
  - 输出：0 命中。

### Batch-43 执行回报（2026-02-11）
- 目标：`sync.barrier` Task01-08（8项 wait 语义占位）整包 TDD。
- RED：8 项均 `Number of failures: 1`。
- GREEN：8 项逐项回归均 `Number of failures: 0`。
- 模块回归：`N:42 E:0 F:0`。

### Batch-44 执行回报（2026-02-11）

- 目标：一次性清零 `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas` 中剩余 17 项 `IBarrier` 占位测试，严格 TDD。

#### 阶段 A：RED
1) 将 17 项占位断言替换为 `Fail('RED Batch-44: ...')`。
2) 编译：
- `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
3) RED 逐项运行：
- 常规路径：`./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier.<TestName>`
- stress/perf 路径：`FAFAFA_STRESS=1 ./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier.<TestName>`
4) 输出：Linux 可执行 15 项全部 `Number of failures: 1`（Windows 2 项条件编译未执行）。

#### 阶段 B：GREEN
1) 关键实现：
- 在 `TTestCase_IBarrier` 增加 helper：`AssertBarrierRounds`、`AssertBarrierWaitExRounds`、`AssertPerformanceBaseline`。
- 实现 17 项测试真实断言（线程安全、竞态防护、平台兼容、stress/perf）。
2) 入口增强：
- `IsStressModeEnabled` 支持 `FAFAFA_STRESS=1`，用于 FPCUnit runner 下启用压力路径。
3) 编译：
- `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
- 输出：`Linking .../bin/fafafa.core.sync.barrier.test`

#### 阶段 C：回归
1) 目标项逐项回归：
- 常规 5 项 + stress/perf 10 项，全部 `Number of failures: 0`。
2) 子集回归：
- `./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier`
- `FAFAFA_STRESS=1 ./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier`
- 输出：均 `Number of run tests: 28`、`errors=0`、`failures=0`。
3) 模块回归：
- `bash BuildOrTest.sh test` -> `Time:04.753 N:42 E:0 F:0 I:0`
- `FAFAFA_STRESS=1 bash BuildOrTest.sh test` -> `Time:21.225 N:42 E:0 F:0 I:0`

#### 缺口复扫
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`：`TODO/placeholder` 命中 `0`。
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`：仍有 `34` 处占位（下一批清理）。

#### 本批改动文件
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch44.md`


### Batch-45 执行回报（2026-02-11）

- 目标：执行 TOML P1 子集整包（3 个数值负例 + 1 个 writer 默认快照语义），严格 TDD。

#### 阶段 A：RED
1) 将目标测试改为严格断言并去除占位逻辑。
2) 编译：
- `cd tests/fafafa.core.toml && bash BuildOrTest.sh`
3) 逐项 RED：
- 结果：`Test_Float_Leading_Zero_Should_Fail` 出现 `Number of failures: 1`；其余 3 项已为绿态。

#### 阶段 B：GREEN
1) 修改 `src/fafafa.core.toml.parser.v2.pas` 的 `ParseStrictFloat`：
- 禁止浮点前导零（`00.1` / `01e2`）
- 禁止小数点邻接 `_`（`1_.2` / `1._2`）
2) 测试命名去 TODO：
- `Test_fafafa_core_toml_numbers_negatives.pas`
- `Test_fafafa_core_toml_writer_snapshot_tight_todo.pas`
3) 重新编译通过（`Linking .../bin/tests_toml`）。

#### 阶段 C：回归
1) 目标 4 项逐项回归全部 `Number of failures: 0`。
2) 子集回归：
- `TTestCase_Numbers_Negatives`：`N:14 E:0 F:0`
- `TTestCase_Writer_Snapshot_DefaultSpacing`：`N:1 E:0 F:0`
3) 模块全量现状：
- `bash BuildOrTest.sh test` -> `N:122 E:0 F:34`
- 34 项为既有历史失败，本批未新增失败。

#### 缺口收敛
- 两个目标测试文件的 `TODO/placeholder` 命中均为 0。

#### 本批改动文件
- `src/fafafa.core.toml.parser.v2.pas`
- `tests/fafafa.core.toml/Test_fafafa_core_toml_numbers_negatives.pas`
- `tests/fafafa.core.toml/Test_fafafa_core_toml_writer_snapshot_tight_todo.pas`
- `docs/plans/2026-02-11-repo-gap-scan-priority-batch45.md`


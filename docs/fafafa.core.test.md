# fafafa.core.test — 自研单元测试框架（Runner/Listener/Context）

目标
- 无 fpcunit 依赖，自研可扩展测试框架，统一 Runner/Listener/Context 范式
- 现代能力：过滤、事件化子测试、表驱动、快照、XML（JUnit）报告，跨平台可用

架构概览
- Runner：命令行入口，解析 --filter 与 --junit；对每个（顶层或子）测试发出事件，统计失败并设定退出码
- Listener：订阅事件，输出到 Console/JUnit（可扩展 JSON 等）；Console 面向人读，JUnit 面向 CI
- Context（ITestContext）：测试用例的统一上下文入口，提供断言/日志/临时目录、子测试 Run、表驱动 ForEachStr

核心 API（摘要）
- 注册测试：Test('path', procedure(ctx: ITestContext) ... end)
- 断言：ctx.AssertTrue/AssertEquals/Fail/Log
- 资源：ctx.TempDir（自动隔离）
- 子测试：ctx.Run('name', procedure(sub: ITestContext) ... end)
- 表驱动：ctx.ForEachStr('prefix', ['a','bb'], procedure(c,v) begin ... end)
- 监听器：AddListener/NotifyStart/NotifyTestStart/NotifyTestSuccess/NotifyTestFailure/NotifyEnd

Runner 参数
- --filter=substr 按名称子串过滤要执行的测试（匹配层级路径）
- --junit=path 生成 JUnit XML 报告（tests 属性按实际用例条目数回写）
- --json=path  生成 JSON 报告（标准化 schema，支持 cleanup 数组（V2））
- --no-console/--no-junit/--no-json 可禁用对应监听器（便于只生成报告）


顶层 vs 子测试 语义
- 顶层 Test 注册的用例与 ctx.Run 子测试均由 Runner 统一调度，但在 Skip/Cleanup 语义上保持一致：
  - Skip/Assume：
    - 顶层与子测试均可调用 ctx.Skip/ctx.Assume；被跳过的用例不会计为失败，JSON/JUnit 中以 skipped 呈现
  - Cleanup：
    - 无论用例成功/失败/跳过，均会执行按 LIFO 顺序注册的清理过程
    - 成功用例若清理抛出异常：该用例整体标记为失败；失败信息中包含 [cleanup] 区块，列出所有清理异常
    - 失败用例：原始失败原因保留；清理异常聚合到 [cleanup] 区块，不覆盖原始异常
    - 跳过用例：执行清理；若清理异常，仅记录日志，不改变 skipped 结果
- 监听器输出计数
  - Console：在 [FAIL]/[SKIP] 汇总中分别统计
  - JUnit：单个 <testcase> 下含 <skipped/> 或 <failure/>；testsuite 的 failures、skipped 分别累加
  - JSON：testcase.status 为 "passed" | "failed" | "skipped"；testsuite 汇总字段包括 skipped


示例
- 顶层测试
```
Test('core.equals', procedure(const ctx: ITestContext)
begin
  ctx.AssertEquals('abc', 'a'+'bc');
end);
```
- 子测试
```
Test('core.sub', procedure(const ctx: ITestContext)
begin
  ctx.Run('a', procedure(const c: ITestContext) begin c.AssertTrue(True); end);
  ctx.Run('b', procedure(const c: ITestContext) begin c.AssertEquals('x','x'); end);
end);
```
- 表驱动
```
Test('core.foreach', procedure(const ctx: ITestContext)
var arr: array[0..2] of string;
begin
  arr[0]:='a'; arr[1]:='bb'; arr[2]:='ccc';
  ctx.ForEachStr('len', arr, procedure(const c: ITestContext; const v: string)
  begin c.AssertTrue(Length(v)>0); end);
end);
```

JUnit 报告
- testsuite tests 属性为监听器“实际见到”的 testcases 数量
- 每个子测试（parent/name）都会各自生成 <testcase>
- 后续将补充 classname/timestamp/hostname（可配置）


IClock 与时钟适配
- IClock: NowUTC / NowMonotonicMs；默认 TSystemClock
- TFixedClock: 可注入固定时间（确定性测试）
- TTickClock: 基于 fafafa.core.tick 的高精度适配器（CreateHighResClock）

示例（在测试里切换到高精度单调时钟）
```
uses fafafa.core.test.clock.tick;
...
ctx.SetClock(CreateHighResClock);
// 之后使用 ctx.Clock.NowMonotonicMs 做稳定耗时判断
```

快照（Snapshot）
- 文本：CompareTextSnapshot(Dir, Name, Text, Update)
  - 生成/比较文件：<Dir>/<Name>.snap.txt
  - 归一：换行统一为 LF，末尾空行裁剪
  - 更新策略：Update=True 或设置环境变量 TEST_SNAPSHOT_UPDATE/FAFAFA_TEST_SNAPSHOT_UPDATE=true/1/on/yes；在 CI 环境（CI=1/true/on/yes）下强制禁用更新
- JSON：CompareJsonSnapshot(Dir, Name, JsonText, Update)
  - 生成/比较文件：<Dir>/<Name>.snap.json
  - 归一：使用 fpjson 解析并“对象键排序”，数组顺序保持不变；FormatJSON([]) 稳定输出；换行统一为 LF
  - 更新策略：同上（支持 TEST_SNAPSHOT_UPDATE/FAFAFA_TEST_SNAPSHOT_UPDATE，CI 环境禁用）

- TOML：CompareTomlSnapshot(Dir, Name, TomlText, Update)
  - 生成/比较文件：<Dir>/<Name>.snap.toml
  - 归一：解析为 TOML 文档并以 ToToml([twfPretty, twfSortKeys]) 稳定输出（键排序、稳定格式）；解析失败则回退为纯文本 Normalize（LF/末尾空行裁剪）

快照差异修复说明
- BuildSimpleLineDiff 的上下文 diff 算法修复：
  - 修正了内层遍历变量覆盖问题，避免在多区块差异时上下文行丢失或错位
  - 修正了前后文截取范围，确保头尾边界正确处理
- 用户无感，但生成的 .snap.diff.txt 更加稳定、可读

  - 更新策略：同上（支持 TEST_SNAPSHOT_UPDATE/FAFAFA_TEST_SNAPSHOT_UPDATE，CI 环境禁用）

差异输出（Diff）
- 对比失败时生成 <Name>.snap.diff.txt，内容为逐行上下文 diff：
  - 头部：--- expected / +++ actual
  - 区块：@@ start,count @@
  - 行标记：空格=上下文，-=期望，+=实际
- 上下文行数可通过 TEST_SNAPSHOT_DIFF_CONTEXT 设置（默认 2）

Sink 选择与环境变量
- 目的：在不改动命令行参数的情况下，切换 Listener 实现为“Sink 适配器”，便于与统一报告内核（Console/JUnit/JSON）对齐
- 开关（任一设置为 '1' 时启用适配器版本）：
  - FAFAFA_TEST_USE_SINK_CONSOLE
  - FAFAFA_TEST_USE_SINK_JUNIT
  - FAFAFA_TEST_USE_SINK_JSON
- JSON/JUnit 输出路径解析顺序：
  1) 命令行 --json=path / --junit=path
  2) 环境变量 FAFAFA_TEST_JSON_FILE / FAFAFA_TEST_JUNIT_FILE（当未在命令行显式指定且未禁用对应 Listener 时）
  3) 显式存在裸 --json / --junit 时使用默认文件名：report.json / junit.xml
- 示例（本地调试）：
  - Windows PowerShell
    $env:FAFAFA_TEST_USE_SINK_JSON='1'; .\tests.exe --json
  - Bash
    FAFAFA_TEST_USE_SINK_JSON=1 ./tests --json

- 更新基线成功后自动删除对应 .snap.diff.txt

示例（JSON 快照）
```
var dir := GetTempDir(False)+'mysnaps';
ForceDirectories(dir);
AssertTrue(CompareJsonSnapshot(dir,'resp', '{"b":2,"a":1}', True)); // 建立基线
AssertTrue(CompareJsonSnapshot(dir,'resp', '{"a":1,"b":2}', False)); // 键排序后等价
```

CI 注意事项
- 禁止在 CI 默认分支启用快照更新（避免误覆盖），仅在本地或专用分支设置 TEST_SNAPSHOT_UPDATE
- 快照差异上下文：使用 TEST_SNAPSHOT_DIFF_CONTEXT 控制行数（默认 2）
- 若需要检查差异，可在失败时输出短 diff（已生成 .snap.diff.txt 文件）


Runner 环境变量与退出码策略
- 环境变量（默认路径兜底）
  - FAFAFA_TEST_JUNIT_FILE：当未显式传入 --junit=path，且未禁用 --no-junit 时，默认 JUnit 输出路径
  - FAFAFA_TEST_JSON_FILE：当未显式传入 --json=path，且未禁用 --no-json 时，默认 JSON 输出路径
- CI 预设
  - --ci 等价于 --quiet --summary，且如未指定 --junit 时默认写入 junit.xml
- 跳过视为失败
  - --fail-on-skip：若存在 skipped，用例结束返回码为 1（便于 CI 失败快速感知）
- 退出码
  - 0：全部通过（且在未启用 --fail-on-skip 时，即使有 skip 也为 0）
  - 1：存在失败，或启用 --fail-on-skip 且存在 skip
  - 2：Runner 自身错误（例如 --list-json 写文件失败）

--list-json 最佳实践
- 用途：输出匹配用例清单（JSON 数组），供外部编排器消费
- 开关
  - --list-json[=path]：输出到 stdout 或写入文件
  - --list-json-pretty：美化格式输出（默认紧凑）
  - --list-sort=alpha|none：是否按名称字母序排序（默认 alpha），none 保持注册顺序
  - --list-sort-case：排序大小写敏感（默认不敏感）
- 默认行为：alpha 排序 + 不区分大小写，确保输出稳定可重复

示例（CI 配置片段）
```
# 默认输出路径（可在 CI 环境里配置）
FAFAFA_TEST_JUNIT_FILE=out/junit.xml
FAFAFA_TEST_JSON_FILE=out/report.json

# 仅摘要与静默控制台，且默认输出 junit.xml
./tests.exe --ci

# 将跳过视为失败
./tests.exe --ci --fail-on-skip

# 输出最慢 5 条
./tests.exe --summary --top-slowest=5

# 输出用例清单（稳定排序）到 stdout / 文件
./tests.exe --list-json --filter=core --filter-ci
./tests.exe --list-json=tests.json --filter=core

# 美化 JSON、保持注册顺序、大小写敏感排序
./tests.exe --list-json --list-json-pretty --list-sort=none --list-sort-case
```



断言与跳过（Assertions & Skips）
- 新增断言：
  - ctx.Throws(EClass, Proc, Msg?) / ctx.NotThrows(Proc, Msg?)
  - ctx.AssertRaises(EClass, Proc, Msg?)
- 跳过与前置条件：
清理（Cleanup）
- 注册：ctx.AddCleanup(proc)
  - LIFO 顺序执行；适合关闭文件句柄/删除临时目录等
- 触发时机与异常策略：
  - 成功用例也会执行清理；若清理中抛出异常，则该用例被标记为失败，失败信息包含 [cleanup] 区块列出所有异常
  - 失败用例：先捕获原始失败，再执行清理；若清理也异常，聚合到失败信息的 [cleanup] 区块中（不吞并原始异常）
  - 跳过用例（Skip/Assume）：依然执行清理，但清理异常只记录日志，不改变“跳过”结果
- 示例
```
Test('demo.cleanup', procedure(const ctx: ITestContext)
begin
  ctx.AddCleanup(procedure begin // 资源释放
    // ...
  end);
  ctx.AssertTrue(True);
end);
```

  - ctx.Skip(Reason?)：标记该用例跳过
  - ctx.Assume(Cond, Reason?)：条件不满足则跳过，不计为失败
- 监听器输出（skipped）：
  - JSON：某 testcase 的 status="skipped"；testsuite 增加 "skipped" 计数
  - JUnit：单个 <testcase> 下包含 <skipped/>；testsuite 增加 skipped="N"

示例（Skip/Assume）
```
var ctx := NewTestContext;
ctx.Assume(FileExists('/data'), 'dataset not prepared');
ctx.Skip('not applicable on this platform');
Listeners 的清理异常展示示例
- Console
  [FAIL] suite/test2 (20 ms): boom
         cleanup (2):
           1) E1: c1
           2) E2: c2
- JUnit（片段）
  <testcase ...>
    <failure message="boom">
      <system-err><![CDATA[
cleanup (2):
  1) E1: c1
  2) E2: c2
      ]]></system-err>
    </failure>
  </testcase>
- JSON（message 字段拼接）
  "message": "boom\nE1: c1\nE2: c2"

```

迁移指引（从 fpcunit）
- 将 TTestCase/published 方法迁移为 Test('path', procedure(ctx) ... end)
- 断言替换为 ctx.AssertX；OneTime/SetUp 可封装为自定义注册序列或后续 Fixture
- Runner 切换为新可执行文件；CI 使用 --filter/--junit 组合

- 注册用例时请使用闭包（reference to procedure），避免使用 `is nested` 的过程类型：见 docs/partials/testing.best_practices.md

最佳实践
- 路径式命名：module.suite.case[/sub]
- 资源隔离：使用 ctx.TempDir；避免共享全局状态
- 快照测试：使用 fafafa.core.test.snapshot（文本/JSON，LF 归一）

计划路线
- v0：Runner/Listener（Console/JUnit）、子测试/表驱动、过滤
- v1：标签过滤 --tags、并行 --parallel=N、JUnit 字段增强、Fixture 接口
- v2：数据驱动扩展、Property-based/Fuzz（有限范围）



JSON V2（结构化 cleanup）
- 目的：在不破坏旧接口的前提下，为失败用例输出结构化的 cleanup 数组，便于下游程序解析
- 接口：IJsonReportWriterV2.AddTestFailureEx(...; ACleanupItems: TStrings; ...)
- 输出 schema（testcase 节点）示例：
  {
    "classname": "suite",
    "name": "test2",
    "time": 0.02,
    "status": "failed",
    "message": "boom",
    "cleanup": [
      { "text": "E1: c1" },
      { "text": "E2: c2" }
    ]
  }
- 启用方式：
  - 构造 JSON Listener 时传入 V2 工厂：TJsonTestListener.Create(@CreateRtlJsonWriterV2, 'report.json')
  - 若传入旧工厂 CreateRtlJsonWriter，则保持兼容（将 cleanup 以换行拼接到 message 文本中）
- 兼容策略：
  - Listener 运行时会优先探测 IJsonReportWriterV2 并使用 AddTestFailureEx；若不可用则回退到 AddTestFailure（拼接字符串）
  - 因此现有依赖无需修改即可获得最小兼容；需要结构化字段时再切换工厂即可

示例（启用 JSON V2 并生成失败用例的 cleanup 数组）
```
uses fafafa.core.test.listener.json, fafafa.core.test.json.rtl;
var L: ITestListener;
L := TJsonTestListener.Create(@CreateRtlJsonWriterV2, 'report.json');
L.OnStart(1);
L.OnTestFailure('suite/test2', 'boom'+LineEnding+'[cleanup]'+LineEnding+'E1: c1'+LineEnding+'E2: c2', 20);
L.OnEnd(1,1,20);
// report.json 中的 tests[0].cleanup 为结构化数组
```


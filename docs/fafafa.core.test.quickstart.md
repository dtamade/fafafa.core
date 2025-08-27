# fafafa.core.test — Quickstart (minimal kernel example)

目标
- 最小可用示例：注册用例 / 子测试 / 断言 / 控制台输出
- 不依赖 CI 或外部报告格式

## 1) 建立最小程序（tests_core_min.lpr）

将以下内容保存为 tests_core_min.lpr（示例）：

```pascal
program tests_core_min;

{$mode objfpc}{$H+}
{$I src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.test.core,
  fafafa.core.test.runner; // 提供 TestMain

begin
  // 顶层用例
  Test('math/add', procedure(const ctx: ITestContext)
  begin
    ctx.AssertTrue(1+1=2, '1+1 should equal 2');

    // 子测试
    ctx.Run('edge/zero', procedure(const sub: ITestContext)
    begin
      sub.AssertTrue(0+0=0, '0+0 should equal 0');
    end);

    // 清理示例
    ctx.AddCleanup(procedure
    begin
      // 清理资源（文件/目录/句柄等）
    end);
  end);

  // 另一个用例（字符串断言）
  Test('string/equals', procedure(const ctx: ITestContext)
  begin
    ctx.AssertEquals('hello', 'he'+'llo', 'string concat');
  end);

  // 运行入口（解析 --filter/--list/--version 等）
  TestMain;
end.
```

要点：
- Test(path, proc) 用于注册顶层用例；ctx.Run(name, proc) 组织层级子测试（名称以 "/" 连接）
- AssertTrue/AssertEquals/Fail/Skip/Assume 提供基础断言（MVP 以 True/Equals/Fail 为主）
- 注册测试时请使用闭包（reference to procedure），避免使用 is nested 的过程：
  - 原因：RegisterTests 返回后，nested proc 的静态链可能失效，延迟调用会 AV。
  - 详情：docs/partials/testing.best_practices.md

- AddCleanup 在用例结束后按 LIFO 顺序执行，确保资源释放

顶层 Skip / Cleanup 示例
```pascal
// Skip：在满足某条件时跳过（不计失败）
Test('control/skip', procedure(const ctx: ITestContext)
begin
  if GetEnvironmentVariable('DEMO_SKIP') <> '' then
    ctx.Skip('skipped by DEMO_SKIP');
  ctx.AssertTrue(True);
end);

// Cleanup：成功用例也会执行；若清理失败，则整体标记为失败并在消息中附带 [cleanup]
Test('control/cleanup', procedure(const ctx: ITestContext)
begin
  ctx.AddCleanup(procedure begin raise Exception.Create('c1'); end);
  ctx.AssertTrue(True);
end);
```

启用 JSON 报告（Sink 适配器版本）
- Windows PowerShell
```
$env:FAFAFA_TEST_USE_SINK_JSON='1'; .\tests_core_min.exe --json
```
- Bash
```
FAFAFA_TEST_USE_SINK_JSON=1 ./tests_core_min --json
```


## 2) 构建与运行

- 使用 lazbuild 建立一个最小工程（也可直接 fpc 编译）
- 运行示例：
  - `tests_core_min --all`（或无参数）
  - `tests_core_min --filter=string/` 仅运行匹配该子串的用例
  - `tests_core_min --list` 列出用例
  - 生成 JUnit 报告（CI 可用）：`tests_core_min --junit=bin/report.xml`

ConsoleListener 默认输出（示意）：
```
== Running tests ==
[ OK ] math/add (1 ms)
[ OK ] math/add/edge/zero (0 ms)
[ OK ] string/equals (0 ms)
== Done: seen=3, failed=0, elapsed=xx ms ==
```

## 3) 最佳实践
- 用例命名：package/feature/case；子测试用 ctx.Run 构造层级
- 断言消息：包含期望与实际，便于定位
- 可重复性：必要时使用 FixedClock 或确定性输入
- 过滤：利用 --filter 加快迭代

## 5) 本地最佳实践（脚本与环境变量）

- 统一报告路径（无需每次在命令行写路径）：
  - FAFAFA_TEST_JUNIT_FILE=out/junit.xml
  - FAFAFA_TEST_JSON_FILE=out/report.json

- 一键运行脚本：
  - Windows（PowerShell）：`scripts/run-tests-ci.ps1`
    - 参数：
      - -FailOnSkip（默认开启）
      - -TopSlowest=N（默认 5）
  - Linux/macOS（Bash）：`scripts/run-tests-ci.sh`
    - 环境变量：
      - FAIL_ON_SKIP=1/0（默认 1）
      - TOP_SLOWEST=N（默认 5）

- 用例清单（供外部编排器/选择性运行）：
  - Windows：`powershell -File scripts\list-tests.ps1 -Filter core -CI`
  - Linux/macOS：`./scripts/list-tests.sh core`
  - 美化与排序控制：
    - --list-json-pretty
    - --list-sort=alpha|none（默认 alpha）
    - --list-sort-case（大小写敏感）

说明：
- 默认排序为字母序、忽略大小写，确保输出可重复
- 文件写入失败时，stderr 会输出错误并以退出码 2 退出
- 调试：
  - Windows：`-DebugRaw`（打印主/回退路径状态与计数，保存原始 XML 到临时文件）
  - Linux/macOS：`DEBUG_RAW=1`（打印主/回退状态与 XML 长度）



## 4) 进阶（可选）
- 快照（snapshot）：文本/JSON 基线比对（默认关闭，后续里程碑）
- 诊断（diag）：详细二进制/十六进制流水（默认关闭，仅排障使用）

参考：
- 设计 ADR：docs/adr/ADR-0001-test-kernel-design.md
- ConsoleListener：docs/fafafa.core.test.console.md
- Adapters（外部格式，默认不加载）：docs/fafafa.core.test.adapters.md


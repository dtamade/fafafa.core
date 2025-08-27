program tests_core_min;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.test.core,
  fafafa.core.test.runner;

begin
  // 顶层用例：数学加法
  Test('math/add', procedure(const ctx: ITestContext)
  begin
    ctx.AssertTrue(1+1=2, '1+1 should equal 2');

    // 子测试：边界
    ctx.Run('edge/zero', procedure(const sub: ITestContext)
    begin
      sub.AssertTrue(0+0=0, '0+0 should equal 0');
    end);

    // 清理示例
    ctx.AddCleanup(procedure
    begin
      // TODO: 清理资源（文件/目录/句柄等）
    end);
  end);

  // 顶层用例：字符串相等
  Test('string/equals', procedure(const ctx: ITestContext)
  begin
    ctx.AssertEquals('hello', 'he'+'llo', 'string concat');
  end);

  // 顶层用例：演示 Fail/Skip/Assume
  Test('control/flow', procedure(const ctx: ITestContext)
  begin
    // Skip 示例（在某些条件下跳过）
    if GetEnvironmentVariable('DEMO_SKIP') <> '' then
      ctx.Skip('skipped by DEMO_SKIP env');

    // Assume 示例（不满足条件则跳过）
    ctx.Assume(Length('abc') = 3, 'assumption failed: length should be 3');

    // Fail 示例（显式失败）
    if GetEnvironmentVariable('DEMO_FAIL') <> '' then
      ctx.Fail('forced failure by DEMO_FAIL');

    // 正常断言
    ctx.AssertTrue(True, 'control/flow basic ok');
  end);


  // 顶层用例：演示 Skip（不计失败）
  Test('control/skip', procedure(const ctx: ITestContext)
  begin
    if GetEnvironmentVariable('DEMO_SKIP') <> '' then
      ctx.Skip('skipped by DEMO_SKIP');
    ctx.AssertTrue(True);
  end);

  // 顶层用例：Cleanup 失败会将成功用例标记为失败，并在消息中附带 [cleanup]
  Test('control/cleanup', procedure(const ctx: ITestContext)
  begin
    ctx.AddCleanup(procedure begin raise Exception.Create('c1'); end);
    ctx.AssertTrue(True);
  end);


  // 运行入口（解析 --filter/--list/--version 等）
  TestMain;
end.


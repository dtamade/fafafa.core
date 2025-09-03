program fafafa.core.sync.mutex.parkinglot.test;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.sync.mutex.parkinglot - 测试运行器
📖 概述：运行 Parking Lot Mutex 的所有单元测试
🧵 用法：直接运行此程序即可执行所有测试
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}

uses
  custapp, fpcunit, testregistry, consoletestrunner,
  fafafa.core.sync.mutex.parkinglot.testcase;

type
  { TTestRunner }
  TTestRunner = class(TTestRunner)
  protected
    // 可以在这里自定义测试运行器行为
  end;

var
  Application: TTestRunner;

begin
  WriteLn('=== fafafa.core.sync.mutex.parkinglot 单元测试 ===');
  WriteLn('测试开始...');
  WriteLn;
  
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'Parking Lot Mutex Tests';
  Application.Run;
  Application.Free;
  
  WriteLn;
  WriteLn('测试完成。');
end.

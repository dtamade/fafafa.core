program fafafa_core_socket_async_test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes, fpcunit, testregistry, consoletestrunner,
  fafafa.core.socket.async.testcase;

type
  TMyTestRunner = class(TTestRunner)
  protected
    procedure WriteCustomHelp; override;
  end;

procedure TMyTestRunner.WriteCustomHelp;
begin
  inherited WriteCustomHelp;
  WriteLn('');
  WriteLn('fafafa.core.socket.async 异步Socket模块测试');
  WriteLn('============================================');
  WriteLn('');
  WriteLn('测试覆盖：');
  WriteLn('- 异步Socket创建和基本操作');
  WriteLn('- 异步连接、发送、接收');
  WriteLn('- 高性能异步操作（缓冲区池、向量化I/O）');
  WriteLn('- 批量异步操作');
  WriteLn('- 错误处理和异常情况');
  WriteLn('- 事件回调机制');
  WriteLn('- 性能基准测试');
  WriteLn('');
end;

var
  Application: TMyTestRunner;

begin
  WriteLn('fafafa.core.socket.async 异步Socket测试套件');
  WriteLn('===========================================');
  WriteLn('');
  
  Application := TMyTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.socket.async Test Suite';
    Application.Run;
  finally
    Application.Free;
  end;
end.

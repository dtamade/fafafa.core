unit test_autodrain_two_sides_edge;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_AutoDrain_TwoSides = class(TTestCase)
  published
    procedure Test_AutoDrain_BothStdoutAndStderr;
  end;

implementation

procedure TTestCase_AutoDrain_TwoSides.Test_AutoDrain_BothStdoutAndStderr;
var
  B: IProcessBuilder;
  P: IProcess;
  Code: Integer;
begin
  {$IFDEF FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT}
  // 构造一个同时输出到 stdout/stderr 的命令
  {$IFDEF WINDOWS}
  B := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','(echo out & (>&2 echo err))'])
        .RedirectStdOut(True)
        .RedirectStdErr(True)
        .DrainOutput(True);
  {$ELSE}
  B := NewProcessBuilder
        .Exe('/bin/sh')
        .Args(['-c','(echo out; echo err 1>&2)'])
        .RedirectStdOut(True)
        .RedirectStdErr(True)
        .DrainOutput(True);
  {$ENDIF}

  P := B.Build;
  P.Start;
  // Wait 前会自动启动两路排水线程（实现需保证两路皆可收敛）
  if not P.WaitForExit(5000) then
    Fail('AutoDrain 两路排水下应在超时前完成');
  Code := P.ExitCode;
  AssertEquals('退出码应为 0', 0, Code);
  {$ELSE}
  AssertTrue('未启用 FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT，跳过', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_AutoDrain_TwoSides);

end.


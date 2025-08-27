{$CODEPAGE UTF8}
unit test_wait_fastpath;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_WaitFastPath = class(TTestCase)
  published
    procedure Test_WaitForExit_AlreadyExited_ReturnsTrue_AndExitCode;
    procedure Test_WaitForExit_StillRunning_ZeroTimeout_ReturnsFalse;
  end;

implementation

procedure TTestCase_WaitFastPath.Test_WaitForExit_AlreadyExited_ReturnsTrue_AndExitCode;
var
  B: IProcessBuilder;
  C: IChild;
  ok: Boolean;
  code: Integer;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','exit','7']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','exit 7']);
  {$ENDIF}
  C := B.Start;
  // 主动等待让其退出
  ok := C.WaitForExit(2000);
  AssertTrue('process should exit within 2s', ok);
  // fast path: 再以 0 超时调用，应该立即返回 true 并保留退出码
  ok := C.WaitForExit(0);
  AssertTrue('WaitForExit(0) should return True when already exited', ok);
  code := C.GetExitCode;
  AssertEquals('exit code should be 7', 7, code);
end;

procedure TTestCase_WaitFastPath.Test_WaitForExit_StillRunning_ZeroTimeout_ReturnsFalse;
var
  B: IProcessBuilder;
  C: IChild;
  ok: Boolean;
begin
  {$IFDEF WINDOWS}
  // 使用 ping 模拟短暂睡眠，避免依赖 powershell 启动耗时不确定
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','ping','-n','2','127.0.0.1','>','NUL']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','sleep 0.15']);
  {$ENDIF}
  C := B.Start;
  // 立刻非阻塞查询
  ok := C.WaitForExit(0);
  AssertFalse('WaitForExit(0) should return False when still running', ok);
  // 清理：等待完成避免僵尸
  ok := C.WaitForExit(1000);
  AssertTrue('process should finish eventually', ok);
end;

initialization
  RegisterTest(TTestCase_WaitFastPath);
end.


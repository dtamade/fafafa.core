unit test_kill_terminate_finalize;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_KillTerminateFinalize = class(TTestCase)
  published
    procedure Kill_NoDrain_NonMerged_Should_Not_Deadlock_And_Cleanup;
    procedure Terminate_Drain_Merged_Should_Not_Deadlock_And_Cleanup;
  end;

implementation

procedure TTestCase_KillTerminateFinalize.Kill_NoDrain_NonMerged_Should_Not_Deadlock_And_Cleanup;
var
  SI: IProcessStartInfo;
  P: IProcess;
  R: Boolean;
begin
  // Arrange: 制造有持续输出的命令
  SI := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  SI.FileName := 'cmd.exe';
  SI.Arguments := '/c for /L %i in (1,1,2000) do @echo K-%i & ping -n 2 127.0.0.1 >nul';
  {$ELSE}
  SI.FileName := '/bin/sh';
  SI.Arguments := '-c "for i in $(seq 1 2000); do echo K-$i; sleep 0.01; done"';
  {$ENDIF}
  SI.RedirectStandardOutput := True;
  SI.RedirectStandardError := True;
  SI.SetDrainOutput(False);    // 不启用 Drain
  SI.StdErrToStdOut := False;  // 非合流

  P := TProcess.Create(SI);
  P.Start;

  // Act: 立刻 Kill，然后短等待确认状态
  P.Kill;
  R := P.WaitForExit(3000);

  // Assert: 应退出且状态为 Terminated
  CheckTrue(R, 'Process should exit after Kill');
  CheckTrue(P.State = psTerminated, 'State should be psTerminated');

  // 读一把输出，验证不会死锁
  if Assigned(P.StandardOutput) then
  begin
    try
      P.StandardOutput.ReadAnsiString; // 消费一段（弱断言）
    except
      // 不抛出即可
    end;
  end;
end;

procedure TTestCase_KillTerminateFinalize.Terminate_Drain_Merged_Should_Not_Deadlock_And_Cleanup;
var
  SI: IProcessStartInfo;
  P: IProcess;
  R: Boolean;
begin
  // Arrange: 有输出且合流，启用 Drain
  SI := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  SI.FileName := 'cmd.exe';
  SI.Arguments := '/c for /L %i in (1,1,2000) do @echo T-%i & ping -n 2 127.0.0.1 >nul';
  {$ELSE}
  SI.FileName := '/bin/sh';
  SI.Arguments := '-c "for i in $(seq 1 2000); do echo T-$i; sleep 0.01; done"';
  {$ENDIF}
  SI.RedirectStandardOutput := True;
  SI.RedirectStandardError := True;
  SI.SetDrainOutput(True);     // 启用 Drain
  SI.StdErrToStdOut := True;   // 合流

  P := TProcess.Create(SI);
  P.Start;

  // Act: 优雅终止
  P.Terminate;
  R := P.WaitForExit(5000);

  // Assert: 应退出（可能被标记为 Terminated）
  CheckTrue(R, 'Process should exit after Terminate');
  CheckTrue(P.HasExited, 'Process should have exited');

  // 合流+Drain 情况下，收尾不应死锁
  if Assigned(P.StandardOutput) then
  begin
    try
      P.StandardOutput.ReadAnsiString;
    except
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_KillTerminateFinalize);

end.


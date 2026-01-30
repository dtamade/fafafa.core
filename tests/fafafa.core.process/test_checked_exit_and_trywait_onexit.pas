{$CODEPAGE UTF8}
unit test_checked_exit_and_trywait_onexit;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, Classes,
  fafafa.core.process;

type
  TTestCase_CheckedExit_And_TryWait_OnExit = class(TTestCase)
  published
    procedure StatusChecked_ShouldRaise_OnNonZero;
    procedure OutputChecked_ShouldRaise_OnNonZero;
    procedure TryWait_ShouldReturnFalse_WhenRunning;
    procedure OnExit_ShouldInvokeCallback;
  end;

implementation

procedure TTestCase_CheckedExit_And_TryWait_OnExit.StatusChecked_ShouldRaise_OnNonZero;
var
  B: IProcessBuilder;
  RaisedErr: Boolean = False;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','cmd','/c','exit','5']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','exit 5']);
  {$ENDIF}
  try
    B.StatusChecked;
  except
    on E: EProcessExitError do
      begin
        RaisedErr := True;
        AssertEquals('exit code should be 5', 5, E.ExitCode);
      end;
  end;
  AssertTrue('EProcessExitError expected on non-zero exit', RaisedErr);
end;

procedure TTestCase_CheckedExit_And_TryWait_OnExit.OutputChecked_ShouldRaise_OnNonZero;
var
  B: IProcessBuilder;
  RaisedErr: Boolean = False;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','cmd','/c','exit','3']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','exit 3']);
  {$ENDIF}
  try
    B.OutputChecked;
  except
    on E: EProcessExitError do
      begin
        RaisedErr := True;
        AssertEquals('exit code should be 3', 3, E.ExitCode);
      end;
  end;
  AssertTrue('EProcessExitError expected on non-zero exit', RaisedErr);
end;

procedure TTestCase_CheckedExit_And_TryWait_OnExit.TryWait_ShouldReturnFalse_WhenRunning;
var
  SI: IProcessStartInfo;
  P: IProcess;
  R: Boolean;
begin
  {$IFDEF WINDOWS}
  SI := TProcessStartInfo.Create('cmd.exe','/c powershell -NoProfile -Command Start-Sleep -Seconds 1');
  {$ELSE}
  SI := TProcessStartInfo.Create('/bin/sh','-c "sleep 1"');
  {$ENDIF}
  P := TProcess.Create(SI);
  P.Start;
  R := P.TryWait; // 非阻塞，短时间内应为 False
  AssertFalse('TryWait should return False while running', R);
  P.WaitForExit(2000);
end;

procedure TTestCase_CheckedExit_And_TryWait_OnExit.OnExit_ShouldInvokeCallback;
var
  SI: IProcessStartInfo;
  P: IProcess;
  Flag: Boolean = False;
begin
  {$IFDEF WINDOWS}
  SI := TProcessStartInfo.Create('cmd.exe','/c echo HELLO');
  {$ELSE}
  SI := TProcessStartInfo.Create('/bin/echo','HELLO');
  {$ENDIF}
  P := TProcess.Create(SI);
  P.Start;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  P.OnExit(
    procedure
    begin
      Flag := True;
    end
  );
  {$ENDIF}
  P.WaitForExit(2000);
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertTrue('OnExit should have been invoked', Flag);
  {$ELSE}
  AssertTrue('Skip OnExit check when anonymous not available', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_CheckedExit_And_TryWait_OnExit);
end.


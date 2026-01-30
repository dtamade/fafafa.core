unit Test_scheduler_precision;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_Scheduler_Precision = class(TTestCase)
  published
    procedure Test_Fires_Within_Tolerance;
  end;

implementation

procedure TTestCase_Scheduler_Precision.Test_Fires_Within_Tolerance;
var S: ITaskScheduler; F: IFuture; T0, T1: QWord; Delay, Tolerance: Cardinal;
begin
  Delay := 50;
  Tolerance := 30; // 容忍 30ms 抖动，事件驱动应更稳
  S := CreateTaskScheduler;
  T0 := GetTickCount64;
  F := S.Schedule(function(): Boolean begin Result := True; end, Delay);
  AssertTrue('schedule returns non-nil future', F <> nil);
  AssertTrue('wait completes', F.WaitFor(2000));
  T1 := GetTickCount64;
  AssertTrue('fired within tolerance', (T1 - T0) >= Delay - 1);
  AssertTrue('fired within tolerance high bound', (T1 - T0) <= Delay + Tolerance);
  S.Shutdown;
end;

initialization
  RegisterTest(TTestCase_Scheduler_Precision);
end.


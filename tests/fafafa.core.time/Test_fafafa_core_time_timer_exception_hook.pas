unit Test_fafafa_core_time_timer_exception_hook;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer,
  fafafa.core.time.testutils;

type
  TTestCase_TimerExceptionHook = class(TTestCase)
  published
    procedure Test_Exception_Handler_Called_And_Continue;
  end;

var
  GExcRaised: LongInt = 0;
  GHandlerCalled: LongInt = 0;
  GCountNext: LongInt = 0;





implementation

procedure OnTickRaise;
begin
  InterlockedIncrement(GExcRaised);
  raise Exception.Create('boom');
end;

procedure OnTickNext;
begin
  InterlockedIncrement(GCountNext);
end;

procedure OnExc(const E: Exception);
begin
  InterlockedIncrement(GHandlerCalled);
end;


procedure TTestCase_TimerExceptionHook.Test_Exception_Handler_Called_And_Continue;
var
  S: ITimerScheduler;
  t1, t2: ITimer;
  OldHandler: TTimerExceptionHandler;
begin
  S := CreateTimerScheduler;
  GExcRaised := 0;
  GHandlerCalled := 0;
  GCountNext := 0;

  OldHandler := PushTimerExceptionHandler(@OnExc);
  try
    t1 := S.ScheduleAtFixedRate(TDuration.FromMs(0), TDuration.FromMs(10), @OnTickRaise);
    t2 := S.ScheduleAtFixedRate(TDuration.FromMs(0), TDuration.FromMs(10), @OnTickNext);
    SleepFor(TDuration.FromMs(60));
    t1.Cancel; t2.Cancel;
    // 异常回调执行了多次（异常被捕获，线程继续）
    CheckTrue(GExcRaised >= 3);
    // 异常 hook 必须被调用（并且应与异常次数一致）
    CheckTrue(GHandlerCalled >= 3);
    CheckEquals(GExcRaised, GHandlerCalled);
    // 正常回调也继续执行
    CheckTrue(GCountNext >= 3);
  finally
    // Restore global hook to avoid cross-test interference.
    PopTimerExceptionHandler(OldHandler);
    S.Shutdown;
  end;
end;

initialization
  RegisterTest(TTestCase_TimerExceptionHook);
end.


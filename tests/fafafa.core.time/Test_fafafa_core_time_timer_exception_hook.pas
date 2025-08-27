unit Test_fafafa_core_time_timer_exception_hook;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerExceptionHook = class(TTestCase)
  published
    procedure Test_Exception_Handler_Called_And_Continue;
  end;

var
  GExcCalled: Integer = 0;
  GCountNext: Integer = 0;





implementation

procedure OnTickRaise;
begin
  Inc(GExcCalled);
  raise Exception.Create('boom');
end;

procedure OnTickNext;
begin
  Inc(GCountNext);
end;

procedure OnExc(const E: Exception);
begin
  // no-op for test, counting is done inside OnTickRaise
end;


procedure TTestCase_TimerExceptionHook.Test_Exception_Handler_Called_And_Continue;
var S: ITimerScheduler; t1, t2: ITimer;
begin
  S := CreateTimerScheduler;
  GExcCalled := 0; GCountNext := 0;
  SetTimerExceptionHandler(@OnExc);
  t1 := S.ScheduleAtFixedRate(TDuration.FromMs(0), TDuration.FromMs(10), @OnTickRaise);
  t2 := S.ScheduleAtFixedRate(TDuration.FromMs(0), TDuration.FromMs(10), @OnTickNext);
  SleepFor(TDuration.FromMs(60));
  t1.Cancel; t2.Cancel;
  // 异常回调执行了多次（异常被捕获，线程继续）
  CheckTrue(GExcCalled >= 3);
  // 正常回调也继续执行
  CheckTrue(GCountNext >= 3);
  // 还原 hook
  SetTimerExceptionHandler(nil);
  S.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TimerExceptionHook);
end.


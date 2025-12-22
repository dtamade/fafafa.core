unit Test_fafafa_core_time_timer_async_shutdown;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer,
  fafafa.core.sync,
  fafafa.core.thread;

type
  TTestCase_TimerAsyncShutdown = class(TTestCase)
  published
    procedure Test_AsyncCallback_SchedulerReleasedDuringCallback_NoCrash;
  end;

implementation

var
  GStarted: IEvent;
  GContinue: IEvent;
  GFinished: IEvent;
  GCallbackExecuted: Boolean = False;
  GExceptionCount: LongInt = 0;

procedure TestTimerExceptionHandler(const E: Exception);
begin
  // Any exception from timer callback machinery is a test failure signal.
  InterlockedIncrement(GExceptionCount);
end;

procedure BlockingCallback;
begin
  GCallbackExecuted := True;
  if Assigned(GStarted) then
    GStarted.SetEvent;

  // Block until the test allows us to finish (or timeout to avoid deadlock)
  if Assigned(GContinue) then
    GContinue.WaitFor(5000);

  if Assigned(GFinished) then
    GFinished.SetEvent;
end;

procedure TTestCase_TimerAsyncShutdown.Test_AsyncCallback_SchedulerReleasedDuringCallback_NoCrash;
var
  Pool: IThreadPool;
  S: ITimerScheduler;
  Tm: ITimer;
  wr: TWaitResult;
  OldHandler: TTimerExceptionHandler;
begin
  GCallbackExecuted := False;
  GExceptionCount := 0;
  GStarted := MakeEvent(True, False);
  GContinue := MakeEvent(True, False);
  GFinished := MakeEvent(True, False);

  OldHandler := GetTimerExceptionHandler;
  SetTimerExceptionHandler(@TestTimerExceptionHandler);
  try
    Pool := CreateThreadPool(1, 1, 60000, -1, TRejectPolicy.rpAbort);
    try
      S := CreateTimerScheduler(nil, Pool);

      // schedule 0ms so it fires ASAP
      Tm := S.ScheduleOnce(TDuration.FromMs(0), @BlockingCallback);
      CheckNotNull(Tm, 'schedule should succeed');

      // Ensure callback is running before releasing scheduler
      wr := GStarted.WaitFor(2000);
      CheckEquals(Ord(wrSignaled), Ord(wr), 'callback should start');

      // Shutdown + release scheduler while callback is still blocked.
      // If async callback does not keep scheduler alive, this may AV when the callback finishes.
      S.Shutdown;
      S := nil;

      // Allow callback to complete
      GContinue.SetEvent;

      wr := GFinished.WaitFor(2000);
      CheckEquals(Ord(wrSignaled), Ord(wr), 'callback should finish');

      // Release the timer reference too, so the entry can be freed if dead.
      Tm := nil;

      CheckTrue(GCallbackExecuted, 'callback should have executed');
    finally
      if Assigned(Pool) then
      begin
        Pool.Shutdown;
        Pool.AwaitTermination(2000);
      end;
    end;

    CheckEquals(0, GExceptionCount, 'timer callbacks should not raise exceptions');
  finally
    SetTimerExceptionHandler(OldHandler);
    GStarted := nil;
    GContinue := nil;
    GFinished := nil;
  end;
end;

initialization
  RegisterTest(TTestCase_TimerAsyncShutdown);
end.

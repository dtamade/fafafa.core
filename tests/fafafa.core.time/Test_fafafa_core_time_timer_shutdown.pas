unit Test_fafafa_core_time_timer_shutdown;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerShutdown = class(TTestCase)
  published
    procedure Test_Shutdown_Rejects_New_Scheduling;
    procedure Test_Shutdown_Is_Idempotent;
    procedure Test_Shutdown_Waits_For_Thread_Exit;
  end;

implementation

var
  GCallbackExecuted: Boolean = False;

procedure SimpleCallback;
begin
  GCallbackExecuted := True;
end;

procedure TTestCase_TimerShutdown.Test_Shutdown_Rejects_New_Scheduling;
var
  S: ITimerScheduler;
  t: ITimer;
begin
  S := CreateTimerScheduler;
  
  // 正常调度应该成功
  t := S.ScheduleOnce(TDuration.FromMs(100), @SimpleCallback);
  CheckNotNull(t, 'Schedule before shutdown should succeed');
  // ✅ 立即取消，避免资源泴漏
  t.Cancel;
  t := nil;
  
  // Shutdown
  S.Shutdown;
  
  // Shutdown 后的调度应该返回 nil
  t := S.ScheduleOnce(TDuration.FromMs(100), @SimpleCallback);
  CheckNull(t, 'Schedule after shutdown should return nil');
  
  t := S.ScheduleAtFixedRate(TDuration.FromMs(10), TDuration.FromMs(10), @SimpleCallback);
  CheckNull(t, 'ScheduleAtFixedRate after shutdown should return nil');
  
  t := S.ScheduleWithFixedDelay(TDuration.FromMs(10), TDuration.FromMs(10), @SimpleCallback);
  CheckNull(t, 'ScheduleWithFixedDelay after shutdown should return nil');
end;

procedure TTestCase_TimerShutdown.Test_Shutdown_Is_Idempotent;
var
  S: ITimerScheduler;
begin
  S := CreateTimerScheduler;
  
  // 多次调用 Shutdown 应该安全（幂等性）
  S.Shutdown;
  S.Shutdown; // 第二次调用应该立即返回，不会阻塞
  S.Shutdown; // 第三次也应该没问题
  
  CheckTrue(True, 'Multiple Shutdown calls should be safe');
end;

procedure TTestCase_TimerShutdown.Test_Shutdown_Waits_For_Thread_Exit;
var
  S: ITimerScheduler;
  t: ITimer;
  start, finish: TInstant;
begin
  S := CreateTimerScheduler;
  GCallbackExecuted := False;
  
  // 调度一个任务
  t := S.ScheduleOnce(TDuration.FromMs(10), @SimpleCallback);
  CheckNotNull(t);
  
  // 等待任务执行
  SleepFor(TDuration.FromMs(30));
  
  // Shutdown 应该等待线程退出
  start := NowInstant;
  S.Shutdown;
  finish := NowInstant;
  
  // Shutdown 应该很快完成（线程正常退出）
  CheckTrue(finish.Diff(start).AsMs < 1000, 'Shutdown should complete quickly');
  
  // 验证回调确实执行了
  CheckTrue(GCallbackExecuted, 'Callback should have executed before shutdown');
end;

initialization
  RegisterTest(TTestCase_TimerShutdown);
end.

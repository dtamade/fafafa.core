program example_timer_periodic;

{$MODE OBJFPC}{$H+}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.time, fafafa.core.time.timer;

var
  fired: Integer = 0;

procedure OnTick;
begin
  Inc(fired);
  Writeln('tick at ', NowInstant.AsNsSinceEpoch, ' ns, fired=', fired);
  if fired >= 5 then
  begin
    Writeln('done.');
  end;
end;

var
  S: ITimerScheduler;
  T: ITimer;
begin
  Writeln('Example: periodic timer (5 times)');
  S := CreateTimerScheduler;
  // 先延迟 200ms 启动，每 300ms 触发一次
  T := S.ScheduleAtFixedRate(TDuration.FromMs(200), TDuration.FromMs(300), @OnTick);
  // 主线程简单等待约 2 秒（实际生产中使用更合理的同步）
  SleepFor(TDuration.FromMs(2000));
  // 取消定时器并关闭调度器
  T.Cancel;
  S.Shutdown;
end.


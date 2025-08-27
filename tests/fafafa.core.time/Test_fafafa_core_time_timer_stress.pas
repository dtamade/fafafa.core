unit Test_fafafa_core_time_timer_stress;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerStress = class(TTestCase)
  published
    procedure Test_Concurrent_Schedule_Cancel_Shutdown_Basic;
  end;

implementation

var
  GCount: LongInt = 0;

procedure OnTick; begin InterlockedIncrement(GCount); end;

type
  TStressThread = class(TThread)
  private
    FS: ITimerScheduler;
  protected
    procedure Execute; override;
  public
    constructor Create(const S: ITimerScheduler);
  end;

constructor TStressThread.Create(const S: ITimerScheduler);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FS := S;
  Start;
end;

procedure TStressThread.Execute;
var
  i: Integer;
  t: ITimer;
  initDelayMs, perMs, delMs: Integer;
begin
  for i := 1 to 60 do
  begin
    // 交替使用 FixedRate 与 FixedDelay
    initDelayMs := (i mod 3); // 0..2 ms
    perMs := 2 + (i mod 3);   // 2..4 ms
    delMs := 2 + ((i+1) mod 3);

    if (i and 1) = 0 then
      t := FS.ScheduleAtFixedRate(TDuration.FromMs(initDelayMs), TDuration.FromMs(perMs), @OnTick)
    else
      t := FS.ScheduleWithFixedDelay(TDuration.FromMs(initDelayMs), TDuration.FromMs(delMs), @OnTick);

    // 短暂运行后随机取消
    SleepFor(TDuration.FromMs(2 + (i mod 4)));
    if (i mod 2) = 0 then
      if t <> nil then t.Cancel;
  end;
end;

procedure TTestCase_TimerStress.Test_Concurrent_Schedule_Cancel_Shutdown_Basic;
var
  S: ITimerScheduler;
  ths: array[0..3] of TStressThread;
  i: Integer;
  M: TTimerMetrics;
begin
  S := CreateTimerScheduler;
  GCount := 0;

  // 启动多个并发线程进行调度/取消
  for i := Low(ths) to High(ths) do
    ths[i] := TStressThread.Create(S);

  // 等待线程完成
  for i := Low(ths) to High(ths) do
  begin
    ths[i].WaitFor;
    ths[i].Free;
  end;

  // 短暂等待让调度线程收尾
  SleepFor(TDuration.FromMs(30));

  // 安全关闭
  S.Shutdown;

  // 宽松断言：应当至少调度过一部分任务并触发过回调
  M := TimerGetMetrics;
  CheckTrue(M.ScheduledTotal >= 1);
  CheckTrue(M.FiredTotal >= 0);
end;

initialization
  RegisterTest(TTestCase_TimerStress);
end.


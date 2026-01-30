program example_metrics_light;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.thread;

function BusyWork(Data: Pointer): Boolean;
var i, n: Integer;
begin
  n := NativeInt(Data);
  for i := 1 to n do
  begin
    if (i and 255) = 0 then SysUtils.Sleep(0);
  end;
  Result := True;
end;

var
  S: ITaskScheduler;
  P: IThreadPool;
  MS: ITaskSchedulerMetrics;
  MP: IThreadPoolMetrics;
  i: Integer;
  F: IFuture;
  T: Text;
  CSVPath: string;
  NeedHeader: Boolean;
  FS: TFormatSettings;
begin
  S := CreateTaskScheduler;
  P := CreateFixedThreadPool(2);
  try
    // 开启“轻量可观测性”（默认关闭）
    TTaskScheduler.SetObservedMetricsEnabled(True);
    TThreadPool.SetObservedMetricsEnabled(True);

    // 提交/调度一批任务
    for i := 1 to 10 do
    begin
      F := P.Submit(@BusyWork, nil, Pointer(5000 + i*50));
      S.Schedule(@BusyWork, 10*i, nil, Pointer(3500 + i*30));
    end;

    // 简单等待所有线程池任务完成
    P.Shutdown;
    P.AwaitTermination(5000);

    // 读取指标
    MS := S.GetMetrics; MP := P.GetMetrics;
    Writeln('sched.avg.observed.ms=', MS.GetObservedAverageDelayMs:0:2,
            ' pool.queue.avg.ms=', MP.QueueObservedAverageMs:0:2);

    // 追加到 CSV（默认 bin/metrics_light.csv；也可通过第1个命令行参数指定）
    // 格式：timestamp,sched_avg_ms,pool_queue_avg_ms
    if ParamCount>=1 then CSVPath := ParamStr(1)
    else CSVPath := 'bin' + PathDelim + 'metrics_light.csv';
    NeedHeader := not FileExists(CSVPath);
    AssignFile(T, CSVPath);
    if NeedHeader then Rewrite(T) else Append(T);
    try
      if NeedHeader then
        WriteLn(T, 'timestamp,sched_avg_ms,pool_queue_avg_ms');
      FS := DefaultFormatSettings; FS.DecimalSeparator := '.';
      WriteLn(T,
        FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now), ',',
        FloatToStrF(MS.GetObservedAverageDelayMs, ffFixed, 18, 2, FS), ',',
        FloatToStrF(MP.QueueObservedAverageMs, ffFixed, 18, 2, FS));
    finally
      CloseFile(T);
    end;
  finally
    S.Shutdown;
  end;
end.


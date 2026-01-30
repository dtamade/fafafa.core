program fafafa.core.sync.spin.benchmark;

{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads, BaseUnix, Unix,
  {$ENDIF}
  SysUtils, Classes,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.sync.spin;

type
  // 基准测试结果
  TBenchmarkResult = record
    TestName: string;
    ThreadCount: Integer;
    Operations: Int64;
    ElapsedNs: Int64;
    OpsPerSecond: Double;
    AvgLatencyNs: Double;
  end;

  // 高性能时间类型
  THighResTime = record
    {$IFDEF WINDOWS}
    Counter: Int64;
    {$ELSE}
    TimeSpec: TTimeSpec;
    {$ENDIF}
  end;

{$IFNDEF WINDOWS}
const
  CLOCK_MONOTONIC = 1;

type
  TTimeSpec = record
    tv_sec: Int64;
    tv_nsec: Int64;
  end;
  PTimeSpec = ^TTimeSpec;

function clock_gettime(clk_id: Integer; tp: PTimeSpec): Integer; cdecl; external 'c';
{$ENDIF}

// 高精度时间函数
function GetHighResTime: THighResTime;
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(Result.Counter);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @Result.TimeSpec);
  {$ENDIF}
end;

function CalcElapsedNs(const StartTime, EndTime: THighResTime): Int64;
{$IFDEF WINDOWS}
var
  Freq: Int64;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  QueryPerformanceFrequency(Freq);
  Result := ((EndTime.Counter - StartTime.Counter) * 1000000000) div Freq;
  {$ELSE}
  Result := (EndTime.TimeSpec.tv_sec - StartTime.TimeSpec.tv_sec) * 1000000000 +
            (EndTime.TimeSpec.tv_nsec - StartTime.TimeSpec.tv_nsec);
  {$ENDIF}
end;

// 工作线程
type
  TSpinWorkerThread = class(TThread)
  private
    FSpin: ISpin;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(ASpin: ISpin; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

constructor TSpinWorkerThread.Create(ASpin: ISpin; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FSpin := ASpin;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TSpinWorkerThread.Execute;
var
  LocalOps: Int64;
  CurrentTime: THighResTime;
begin
  LocalOps := 0;

  repeat
    // 对齐 Rust：先 lock+unlock，再计数
    FSpin.Acquire;
    FSpin.Release;
    Inc(LocalOps);

    if (LocalOps and $3FF) = 0 then
    begin
      CurrentTime := GetHighResTime;
      if CalcElapsedNs(FStartTime, CurrentTime) >= FDurationNs then
        Break;
    end;
  until Terminated;

  InterlockedExchangeAdd64(FOperations^, LocalOps);
end;

// 基准测试函数
function RunSpinBenchmark(const TestName: string; ThreadCount: Integer; DurationSec: Integer): TBenchmarkResult;
var
  StartTime, EndTime: THighResTime;
  Operations: Int64;
  ElapsedNs: Int64;
  DurationNs: Int64;
  Threads: array of TSpinWorkerThread;
  i: Integer;
  Spin: ISpin;
begin
  Result.TestName := TestName;
  Result.ThreadCount := ThreadCount;
  Operations := 0;
  DurationNs := Int64(DurationSec) * 1000000000;

  WriteLn(Format('测试: %s (%d线程, %d秒)', [TestName, ThreadCount, DurationSec]));

  Spin := MakeSpin;

  // 轻量预热
  for i := 1 to 1000 do
  begin
    Spin.Acquire;
    Spin.Release;
  end;

  Sleep(100);

  if ThreadCount = 1 then
  begin
    StartTime := GetHighResTime;
    repeat
      Spin.Acquire;
      Spin.Release;
      Inc(Operations);

      if (Operations and $3FF) = 0 then
      begin
        EndTime := GetHighResTime;
        ElapsedNs := CalcElapsedNs(StartTime, EndTime);
        if ElapsedNs >= DurationNs then
          Break;
      end;
    until False;

    EndTime := GetHighResTime;
  end
  else
  begin
    SetLength(Threads, ThreadCount);

    StartTime := GetHighResTime;
    for i := 0 to ThreadCount - 1 do
      Threads[i] := TSpinWorkerThread.Create(Spin, @Operations, DurationNs, StartTime);

    Sleep(DurationSec * 1000);
    EndTime := GetHighResTime;

    for i := 0 to ThreadCount - 1 do
      Threads[i].Terminate;

    for i := 0 to ThreadCount - 1 do
    begin
      Threads[i].WaitFor;
      Threads[i].Free;
    end;
  end;
  ElapsedNs := CalcElapsedNs(StartTime, EndTime);

  Result.Operations := Operations;
  Result.ElapsedNs := ElapsedNs;
  Result.OpsPerSecond := (Operations * 1000000000.0) / ElapsedNs;
  Result.AvgLatencyNs := ElapsedNs / Operations;

  WriteLn(Format('  操作数: %d', [Operations]));
  WriteLn(Format('  耗时: %.3f ms', [ElapsedNs / 1000000.0]));
  WriteLn(Format('  吞吐量: %.0f ops/sec', [Result.OpsPerSecond]));

  if ThreadCount = 1 then
    WriteLn(Format('  平均延迟: %.2f ns/op', [Result.AvgLatencyNs]))
  else
    WriteLn(Format('  平均延迟: %.2f ns/op (含竞争)', [Result.AvgLatencyNs]));

  WriteLn('');
end;

// 主程序
var
  Results: array of TBenchmarkResult;
  Result: TBenchmarkResult;
  ThreadCount: Integer;
  TestDuration: Integer;
  i: Integer;

begin
  WriteLn('fafafa.core.sync.spin 高性能基准测试');
  WriteLn('=====================================');
  WriteLn('');
  WriteLn('测试目标: 验证我们的 Spin 实现性能');
  WriteLn('测试平台: ', {$IFDEF WINDOWS}'Windows'{$ELSE}'Unix/Linux'{$ENDIF});
  WriteLn('测试算法: 智能自旋策略 (参考 parking_lot)');
  WriteLn('');

  TestDuration := 5;  // 每个测试5秒

  WriteLn('=== Spin 锁性能测试 ===');
  for ThreadCount := 1 to 8 do
  begin
    if ThreadCount in [1, 2, 4, 8] then
    begin
      Result := RunSpinBenchmark(Format('Spin Lock (%d线程)', [ThreadCount]), ThreadCount, TestDuration);
      SetLength(Results, Length(Results) + 1);
      Results[High(Results)] := Result;
      Sleep(1000);
    end;
  end;

  WriteLn('==================================================');
  WriteLn('完整基准测试结果汇总 (按吞吐量排序)');
  WriteLn('==================================================');

  // 按吞吐量排序
  for i := 0 to High(Results) - 1 do
  begin
    for ThreadCount := i + 1 to High(Results) do
    begin
      if Results[ThreadCount].OpsPerSecond > Results[i].OpsPerSecond then
      begin
        Result := Results[i];
        Results[i] := Results[ThreadCount];
        Results[ThreadCount] := Result;
      end;
    end;
  end;

  for i := 0 to High(Results) do
  begin
    WriteLn(Format('%-35s: %10.0f ops/sec (%6.2f ns/op)',
      [Results[i].TestName, Results[i].OpsPerSecond, Results[i].AvgLatencyNs]));
  end;

  WriteLn('');
  WriteLn('完整基准测试完成！');
end.

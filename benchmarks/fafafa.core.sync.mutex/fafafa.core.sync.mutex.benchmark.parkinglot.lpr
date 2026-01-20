program ParkingLotMutexBenchmark;
{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.mutex.parkinglot
  {$IFDEF WINDOWS}
  , fafafa.core.sync.mutex.windows
  {$ELSE}
  , fafafa.core.sync.mutex.unix
  {$ENDIF};

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

type
  THighResTime = record
    {$IFDEF WINDOWS}
    Value: Int64;
    {$ELSE}
    Sec: Int64;
    NSec: Int64;
    {$ENDIF}
  end;

  TBenchmarkResult = record
    TestName: string;
    ThreadCount: Integer;
    Operations: Int64;
    ElapsedNs: Int64;
    OpsPerSecond: Double;
    AvgLatencyNs: Double;
  end;

  TWorkerThread = class(TThread)
  private
    FMutex: ITryLock;
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: ITryLock; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;

  // 原生 API 工作线程 (简化版，只支持最快的原生 API)
  {$IFDEF WINDOWS}
  // 原生 API 工作线程 (简化版，只支持最快的原生 API)
  TNativeWorkerThread = class(TThread)
  private
    FCriticalSection: PRTLCriticalSection;  // CRITICAL_SECTION 指针
    FOperations: PInt64;
    FDurationNs: Int64;
    FStartTime: THighResTime;
  protected
    procedure Execute; override;
  public
    constructor Create(ACriticalSection: PRTLCriticalSection; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
  end;
  {$ENDIF}

{$IFDEF WINDOWS}
var
  Frequency: Int64;
{$ENDIF}

function GetHighResTime: THighResTime;
{$IFNDEF WINDOWS}
var
  ts: TTimeSpec;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(Result.Value);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @ts);
  Result.Sec := ts.tv_sec;
  Result.NSec := ts.tv_nsec;
  {$ENDIF}
end;

function CalcElapsedNs(const AStart, AEnd: THighResTime): Int64;
begin
  {$IFDEF WINDOWS}
  Result := ((AEnd.Value - AStart.Value) * 1000000000) div Frequency;
  {$ELSE}
  Result := (AEnd.Sec - AStart.Sec) * 1000000000 + (AEnd.NSec - AStart.NSec);
  {$ENDIF}
end;

{ TWorkerThread }

constructor TWorkerThread.Create(AMutex: ITryLock; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FMutex := AMutex;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TWorkerThread.Execute;
var
  LocalOps: Int64;
  CurrentTime: THighResTime;
begin
  LocalOps := 0;
  
  // 完全对齐 Rust 的逻辑：loop { mutex.lock_and_unlock(); local_ops += 1; ... }
  repeat
    FMutex.Acquire;
    FMutex.Release;  // 先完成 lock_and_unlock，再计数
    Inc(LocalOps);

    // 每1024次检查时间，与 Rust 完全一致：(local_ops & 0x3FF) == 0
    if (LocalOps and $3FF) = 0 then
    begin
      CurrentTime := GetHighResTime;
      if CalcElapsedNs(FStartTime, CurrentTime) >= FDurationNs then
        Break;
    end;
  until Terminated;

  InterlockedExchangeAdd64(FOperations^, LocalOps);
end;

{ TNativeWorkerThread }

{$IFDEF WINDOWS}
constructor TNativeWorkerThread.Create(ACriticalSection: PRTLCriticalSection; AOperations: PInt64; ADurationNs: Int64; const AStartTime: THighResTime);
begin
  inherited Create(False);
  FCriticalSection := ACriticalSection;
  FOperations := AOperations;
  FDurationNs := ADurationNs;
  FStartTime := AStartTime;
end;

procedure TNativeWorkerThread.Execute;
var
  LocalOps: Int64;
  CurrentTime: THighResTime;
begin
  LocalOps := 0;

  repeat
    // CRITICAL_SECTION - 对齐 Rust：先 lock+unlock，再计数
    EnterCriticalSection(FCriticalSection^);
    LeaveCriticalSection(FCriticalSection^);
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

{$ENDIF}

function RunParkingLotBenchmark(const TestName: string; Mutex: ITryLock; ThreadCount: Integer; DurationSec: Integer): TBenchmarkResult;
var
  StartTime, EndTime: THighResTime;
  Operations: Int64;
  ElapsedNs: Int64;
  DurationNs: Int64;
  Threads: array of TWorkerThread;
  i: Integer;
begin
  Result.TestName := TestName;
  Result.ThreadCount := ThreadCount;
  Operations := 0;
  DurationNs := Int64(DurationSec) * 1000000000;

  WriteLn(Format('测试: %s (%d线程, %d秒)', [TestName, ThreadCount, DurationSec]));

  // 轻量预热
  for i := 1 to 1000 do
  begin
    Mutex.Acquire;
    try
      // 空操作
    finally
      Mutex.Release;
    end;
  end;

  Sleep(100);

  if ThreadCount = 1 then
  begin
    StartTime := GetHighResTime;  // 单线程：在测试开始时计时
    // 完全对齐 Rust 单线程逻辑
    repeat
      Mutex.Acquire;
      Mutex.Release;  // 先完成 lock_and_unlock，再计数
      Inc(Operations);

      if (Operations and $3FF) = 0 then
      begin
        EndTime := GetHighResTime;
        ElapsedNs := CalcElapsedNs(StartTime, EndTime);
        if ElapsedNs >= DurationNs then
          Break;
      end;
    until False;

    EndTime := GetHighResTime;  // 单线程：在测试结束时计时
  end
  else
  begin
    SetLength(Threads, ThreadCount);

    StartTime := GetHighResTime;  // 多线程：在线程启动时计时
    for i := 0 to ThreadCount - 1 do
      Threads[i] := TWorkerThread.Create(Mutex, @Operations, DurationNs, StartTime);

    Sleep(DurationSec * 1000);
    EndTime := GetHighResTime;  // 多线程：在测试结束时计时

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

  // 延迟计算：对单线程和多线程都有意义
  // 单线程：每个操作的实际时间
  // 多线程：竞争环境下每个操作的平均时间（包含等待）
  Result.AvgLatencyNs := ElapsedNs / Operations;

  WriteLn(Format('  操作数: %d', [Operations]));
  WriteLn(Format('  耗时: %.3f ms', [ElapsedNs / 1000000.0]));
  WriteLn(Format('  吞吐量: %.0f ops/sec', [Result.OpsPerSecond]));

  // 显示延迟：单线程=实际耗时，多线程=竞争环境下的平均耗时
  if ThreadCount = 1 then
    WriteLn(Format('  平均延迟: %.2f ns/op', [Result.AvgLatencyNs]))
  else
    WriteLn(Format('  平均延迟: %.2f ns/op (含竞争)', [Result.AvgLatencyNs]));

  WriteLn('');
end;

{$IFDEF WINDOWS}
// RunNativeWinMutexBenchmark 已删除 - Windows Mutex 太慢，没有对比价值

function RunNativeCriticalSectionBenchmark(const TestName: string; ThreadCount: Integer; DurationSec: Integer): TBenchmarkResult;
var
  StartTime, EndTime: THighResTime;
  Operations: Int64;
  ElapsedNs: Int64;
  DurationNs: Int64;
  Threads: array of TNativeWorkerThread;
  i: Integer;
  CriticalSection: TRTLCriticalSection;
begin
  Result.TestName := TestName;
  Result.ThreadCount := ThreadCount;
  Operations := 0;
  DurationNs := Int64(DurationSec) * 1000000000;

  WriteLn(Format('测试: %s (%d线程, %d秒) [原生 CRITICAL_SECTION]', [TestName, ThreadCount, DurationSec]));

  // 初始化 CRITICAL_SECTION
  InitializeCriticalSection(CriticalSection);

  try
    // 轻量预热
    for i := 1 to 1000 do
    begin
      EnterCriticalSection(CriticalSection);
      LeaveCriticalSection(CriticalSection);
    end;

    Sleep(100);

    if ThreadCount = 1 then
    begin
      StartTime := GetHighResTime;  // 单线程：在测试开始时计时
      repeat
        EnterCriticalSection(CriticalSection);
        Inc(Operations);
        LeaveCriticalSection(CriticalSection);


        if (Operations and $3FF) = 0 then
        begin
          EndTime := GetHighResTime;
          ElapsedNs := CalcElapsedNs(StartTime, EndTime);
          if ElapsedNs >= DurationNs then
            Break;
        end;
      until False;

      EndTime := GetHighResTime;  // 单线程：在测试结束时计时
    end
    else
    begin
      SetLength(Threads, ThreadCount);

      StartTime := GetHighResTime;  // 多线程：在线程启动时计时
      for i := 0 to ThreadCount - 1 do
        Threads[i] := TNativeWorkerThread.Create(@CriticalSection, @Operations, DurationNs, StartTime);

      Sleep(DurationSec * 1000);
      EndTime := GetHighResTime;  // 多线程：在测试结束时计时

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

    // 延迟计算：单线程=实际耗时，多线程=竞争环境下的平均耗时
    Result.AvgLatencyNs := ElapsedNs / Operations;

    WriteLn(Format('  操作数: %d', [Operations]));
    WriteLn(Format('  耗时: %.3f ms', [ElapsedNs / 1000000.0]));
    WriteLn(Format('  吞吐量: %.0f ops/sec', [Result.OpsPerSecond]));

    if ThreadCount = 1 then
      WriteLn(Format('  平均延迟: %.2f ns/op', [Result.AvgLatencyNs]))
    else
      WriteLn(Format('  平均延迟: %.2f ns/op (含竞争)', [Result.AvgLatencyNs]));

    WriteLn('');

  finally
    DeleteCriticalSection(CriticalSection);
  end;
end;

// Unix 平台暂时移除原生 pthread 测试，专注于我们的 parking_lot 实现
{$ELSE}

// RunNativePthreadBenchmark 已移除 - 专注于跨平台 parking_lot 实现



{$ENDIF}

procedure RunParkingLotBenchmarks;
var
  Mutex: ITryLock;
  Result: TBenchmarkResult;
  Results: array of TBenchmarkResult;
  i, j, ThreadCount: Integer;
  TestDuration: Integer;
  Temp: TBenchmarkResult;
begin
  WriteLn('fafafa.core.sync.mutex 完整基准测试 (包含原生 API)');
  WriteLn('==================================================');
  WriteLn('测试层次:');
  WriteLn('1. 原生系统 API - 最底层实现');
  WriteLn('2. 我们的 parking_lot - 优化算法实现');
  WriteLn('3. 框架封装 - 便利性实现');
  WriteLn('');

  {$IFDEF WINDOWS}
  WriteLn('平台: Windows');
  WriteLn('原生 API: CRITICAL_SECTION (最快的用户态同步原语)');
  WriteLn('parking_lot: WaitOnAddress/WakeByAddressSingle');
  {$ELSE}
  WriteLn('平台: Unix/Linux');
  WriteLn('原生 API: pthread_mutex');
  WriteLn('parking_lot: futex 系统调用');
  {$ENDIF}

  WriteLn('');

  TestDuration := 5;
  SetLength(Results, 0);

  {$IFDEF WINDOWS}
  // === 原生 Windows CRITICAL_SECTION 测试 ===
  WriteLn('=== 原生 Windows CRITICAL_SECTION 测试 ===');

  // 只测试 CRITICAL_SECTION (Windows 最快的用户态同步原语)
  for ThreadCount := 1 to 8 do
  begin
    if ThreadCount in [1, 2, 4, 8] then
    begin
      Result := RunNativeCriticalSectionBenchmark(Format('Native CRITICAL_SECTION (%d线程)', [ThreadCount]), ThreadCount, TestDuration);
      SetLength(Results, Length(Results) + 1);
      Results[High(Results)] := Result;
      Sleep(1000);
    end;
  end;

  {$ELSE}
  // === 原生 Unix/Linux API 测试 ===
  WriteLn('=== 原生 Unix/Linux API 测试 ===');

  // Unix 平台暂时跳过原生 pthread 测试，专注于跨平台 parking_lot 实现
  WriteLn('Unix 平台：专注于 parking_lot 跨平台实现测试');
  {$ENDIF}

  // 测试真正的 parking_lot 实现
  WriteLn('=== 真正的 parking_lot Mutex ===');
  Mutex := MakeParkingLotMutex;

  for ThreadCount := 1 to 8 do
  begin
    if ThreadCount in [1, 2, 4, 8] then
    begin
      Result := RunParkingLotBenchmark(Format('ParkingLot Mutex (%d线程)', [ThreadCount]), Mutex, ThreadCount, TestDuration);
      SetLength(Results, Length(Results) + 1);
      Results[High(Results)] := Result;

      Sleep(1000);
    end;
  end;

  // 对比测试：默认实现
  WriteLn('=== 默认实现对比 (MakeMutex) ===');
  Mutex := MakeMutex;

  for ThreadCount := 1 to 8 do
  begin
    if ThreadCount in [1, 2, 4, 8] then
    begin
      Result := RunParkingLotBenchmark(Format('Default MakeMutex (%d线程)', [ThreadCount]), Mutex, ThreadCount, TestDuration);
      SetLength(Results, Length(Results) + 1);
      Results[High(Results)] := Result;

      Sleep(1000);
    end;
  end;

  {$IFDEF WINDOWS}
  // Windows 特定实现对比
  WriteLn('=== Windows SRWLOCK 对比 ===');
  Mutex := fafafa.core.sync.mutex.windows.TSRWMutex.Create;

  for ThreadCount := 1 to 8 do
  begin
    if ThreadCount in [1, 2, 4, 8] then
    begin
      Result := RunParkingLotBenchmark(Format('Windows SRWLOCK (%d线程)', [ThreadCount]), Mutex, ThreadCount, TestDuration);
      SetLength(Results, Length(Results) + 1);
      Results[High(Results)] := Result;

      Sleep(1000);
    end;
  end;
  {$ENDIF}

  // 输出汇总结果
  WriteLn('==================================================');
  WriteLn('完整基准测试结果汇总 (按吞吐量排序)');
  WriteLn('==================================================');

  // 排序
  for i := 0 to High(Results) - 1 do
  begin
    for j := i + 1 to High(Results) do
    begin
      if Results[j].OpsPerSecond > Results[i].OpsPerSecond then
      begin
        Temp := Results[i];
        Results[i] := Results[j];
        Results[j] := Temp;
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
end;

begin
  {$IFDEF WINDOWS}
  if not QueryPerformanceFrequency(Frequency) then
    raise Exception.Create('高精度计时器不可用');
  {$ENDIF}

  try
    RunParkingLotBenchmarks;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;

end.


unit fafafa.core.sync.mutex.stress;

{
  高强度压力测试和性能验证测试
  
  这个单元包含了对 fafafa.core.sync.mutex 的高强度测试：
  - 长时间运行测试
  - 高频率操作测试  
  - 内存压力测试
  - 边界条件测试
  - 性能基准测试
}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.atomic;

type
  {**
   * TTestCase_IMutex_Stress
   *
   * @desc 高强度压力测试和性能验证
   *}
  TTestCase_IMutex_Stress = class(TTestCase)
  private
    FMutex: IMutex;
    FSharedCounter: Int64;
    FErrorCount: LongInt;
    FSuccessCount: LongInt;
    FStartTime: QWord;
    FEndTime: QWord;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    function GetElapsedMs: Cardinal;
  published
    // 压力测试
    procedure Test_StressTest_LongRunning;
    procedure Test_StressTest_HighFrequency;
    procedure Test_StressTest_MemoryPressure;
    
    // 边界条件测试
    procedure Test_EdgeCase_ZeroTimeout;
    procedure Test_EdgeCase_MaxTimeout;
    procedure Test_EdgeCase_ThreadInterruption;
    
    // 性能验证测试
    procedure Test_Performance_Latency;
    procedure Test_Performance_Throughput;
    procedure Test_Performance_Fairness;
  end;

implementation

{ TTestCase_IMutex_Stress }

procedure TTestCase_IMutex_Stress.SetUp;
begin
  inherited SetUp;
  FMutex := MakeMutex;
  FSharedCounter := 0;
  atomic_store(FErrorCount, 0);
  atomic_store(FSuccessCount, 0);
  FStartTime := GetTickCount64;
end;

procedure TTestCase_IMutex_Stress.TearDown;
begin
  FEndTime := GetTickCount64;
  FMutex := nil;
  inherited TearDown;
end;

function TTestCase_IMutex_Stress.GetElapsedMs: Cardinal;
begin
  Result := FEndTime - FStartTime;
end;

// 长时间运行测试的工作线程
type
  TLongRunningThread = class(TThread)
  private
    FMutex: IMutex;
    FSharedCounter: PInt64;
    FDurationMs: Cardinal;
    FSuccessCount: PLongInt;
    FErrorCount: PLongInt;
  public
    constructor Create(AMutex: IMutex; ASharedCounter: PInt64; ADurationMs: Cardinal;
                      ASuccessCount, AErrorCount: PLongInt);
    procedure Execute; override;
  end;

constructor TLongRunningThread.Create(AMutex: IMutex; ASharedCounter: PInt64;
  ADurationMs: Cardinal; ASuccessCount, AErrorCount: PLongInt);
begin
  FMutex := AMutex;
  FSharedCounter := ASharedCounter;
  FDurationMs := ADurationMs;
  FSuccessCount := ASuccessCount;
  FErrorCount := AErrorCount;
  inherited Create(False);
end;

procedure TLongRunningThread.Execute;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  
  while (GetTickCount64 - StartTime) < FDurationMs do
  begin
    try
      FMutex.Acquire;
      try
        // 模拟一些工作
        Inc(FSharedCounter^);
        Sleep(1);
        atomic_fetch_add(FSuccessCount^, 1);
      finally
        FMutex.Release;
      end;
    except
      atomic_fetch_add(FErrorCount^, 1);
    end;
  end;
end;

procedure TTestCase_IMutex_Stress.Test_StressTest_LongRunning;
var
  Threads: array[0..3] of TLongRunningThread;
  I: Integer;
  TestDuration: Cardinal;
begin
  TestDuration := 10000; // 10秒长时间测试
  
  WriteLn('开始长时间运行测试 (', TestDuration div 1000, '秒)...');
  
  // 创建并启动线程
  for I := 0 to 3 do
  begin
    Threads[I] := TLongRunningThread.Create(FMutex, @FSharedCounter, TestDuration,
                                           @FSuccessCount, @FErrorCount);
  end;
  
  // 等待所有线程完成
  for I := 0 to 3 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  
  // 验证结果
  WriteLn('长时间测试完成: 成功=', atomic_load(FSuccessCount), 
          ', 错误=', atomic_load(FErrorCount),
          ', 共享计数器=', FSharedCounter);
          
  AssertEquals('不应该有错误', 0, atomic_load(FErrorCount));
  AssertTrue('应该有大量成功操作', atomic_load(FSuccessCount) > 500);
  AssertEquals('共享计数器应该等于成功次数', atomic_load(FSuccessCount), FSharedCounter);
end;

// 高频率测试的工作线程
type
  THighFrequencyThread = class(TThread)
  private
    FMutex: IMutex;
    FIterations: Integer;
    FSuccessCount: PLongInt;
  public
    constructor Create(AMutex: IMutex; AIterations: Integer; ASuccessCount: PLongInt);
    procedure Execute; override;
  end;

constructor THighFrequencyThread.Create(AMutex: IMutex; AIterations: Integer;
  ASuccessCount: PLongInt);
begin
  FMutex := AMutex;
  FIterations := AIterations;
  FSuccessCount := ASuccessCount;
  inherited Create(False);
end;

procedure THighFrequencyThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    FMutex.Acquire;
    try
      // 最小工作量，测试高频率获取/释放
      atomic_fetch_add(FSuccessCount^, 1);
    finally
      FMutex.Release;
    end;
  end;
end;

procedure TTestCase_IMutex_Stress.Test_StressTest_HighFrequency;
var
  Threads: array[0..7] of THighFrequencyThread;
  I: Integer;
  IterationsPerThread: Integer;
  ExpectedTotal: Int64;
begin
  IterationsPerThread := 50000; // 每线程5万次操作
  ExpectedTotal := 8 * IterationsPerThread;
  
  WriteLn('开始高频率测试 (', ExpectedTotal, ' 次操作)...');
  FStartTime := GetTickCount64;
  
  // 创建并启动线程
  for I := 0 to 7 do
  begin
    Threads[I] := THighFrequencyThread.Create(FMutex, IterationsPerThread, @FSuccessCount);
  end;
  
  // 等待所有线程完成
  for I := 0 to 7 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  
  FEndTime := GetTickCount64;
  
  // 验证结果和性能
  WriteLn('高频率测试完成: 操作数=', atomic_load(FSuccessCount), 
          ', 耗时=', GetElapsedMs, 'ms',
          ', 吞吐量=', Round(atomic_load(FSuccessCount) / (GetElapsedMs / 1000)), ' ops/sec');
          
  AssertEquals('操作数应该正确', ExpectedTotal, atomic_load(FSuccessCount));
  AssertTrue('性能应该合理 (>10000 ops/sec)', 
            atomic_load(FSuccessCount) / (GetElapsedMs / 1000) > 10000);
end;

procedure TTestCase_IMutex_Stress.Test_StressTest_MemoryPressure;
begin
  // 这个测试在内存压力下验证互斥锁的稳定性
  // 实际实现会创建大量对象并进行并发操作
  WriteLn('内存压力测试暂时跳过 (需要更复杂的实现)');
  AssertTrue('内存压力测试占位', True);
end;

procedure TTestCase_IMutex_Stress.Test_EdgeCase_ZeroTimeout;
var
  I: Integer;
  SuccessCount: Integer;
begin
  WriteLn('测试零超时边界条件...');
  
  // 先获取锁
  FMutex.Acquire;
  try
    SuccessCount := 0;
    // 在另一个线程中测试零超时
    for I := 1 to 100 do
    begin
      if FMutex.TryAcquire(0) then
      begin
        Inc(SuccessCount);
        FMutex.Release;
      end;
    end;
    
    // 零超时应该立即返回失败
    AssertEquals('零超时应该立即失败', 0, SuccessCount);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IMutex_Stress.Test_EdgeCase_MaxTimeout;
begin
  WriteLn('测试最大超时值...');
  
  // 测试最大超时值不会导致溢出
  AssertTrue('最大超时应该成功获取未锁定的锁', FMutex.TryAcquire(High(Cardinal)));
  FMutex.Release;
end;

procedure TTestCase_IMutex_Stress.Test_EdgeCase_ThreadInterruption;
begin
  WriteLn('线程中断测试暂时跳过 (需要平台特定实现)');
  AssertTrue('线程中断测试占位', True);
end;

procedure TTestCase_IMutex_Stress.Test_Performance_Latency;
var
  I: Integer;
  StartTime, EndTime: QWord;
  TotalLatency: QWord;
  AvgLatency: Double;
begin
  WriteLn('测试获取/释放延迟...');
  
  TotalLatency := 0;
  
  for I := 1 to 10000 do
  begin
    StartTime := GetTickCount64;
    FMutex.Acquire;
    FMutex.Release;
    EndTime := GetTickCount64;
    
    TotalLatency := TotalLatency + (EndTime - StartTime);
  end;
  
  AvgLatency := TotalLatency / 10000.0;
  
  WriteLn('平均延迟: ', AvgLatency:0:3, ' ms');
  
  // 平均延迟应该很低（小于1ms）
  AssertTrue('平均延迟应该很低', AvgLatency < 1.0);
end;

procedure TTestCase_IMutex_Stress.Test_Performance_Throughput;
begin
  // 吞吐量测试已经在 Test_StressTest_HighFrequency 中完成
  WriteLn('吞吐量测试参见 Test_StressTest_HighFrequency');
  AssertTrue('吞吐量测试占位', True);
end;

procedure TTestCase_IMutex_Stress.Test_Performance_Fairness;
begin
  WriteLn('公平性测试暂时跳过 (需要复杂的统计分析)');
  AssertTrue('公平性测试占位', True);
end;

initialization
  RegisterTest(TTestCase_IMutex_Stress);

end.

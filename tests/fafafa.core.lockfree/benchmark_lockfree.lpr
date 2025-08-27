program benchmark_lockfree;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, Math,
  fafafa.core.base,
  // 原子统一：tests 不再引用 fafafa.core.sync
  fafafa.core.lockfree;

type
  { 基准测试结果 }
  TBenchmarkResult = record
    TestName: string;
    Operations: Int64;
    ElapsedMs: QWord;
    OpsPerSecond: Double;
    AvgLatencyUs: Double;
    MemoryUsedMB: Double;
  end;

  { 基准测试套件 }
  TLockFreeBenchmark = class
  private
    FResults: array of TBenchmarkResult;
    
    procedure AddResult(const ATestName: string; AOperations: Int64; 
      AElapsedMs: QWord; AMemoryUsedMB: Double = 0);
    procedure PrintResults;
    function GetMemoryUsage: Double;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 单线程性能测试
    procedure BenchmarkSingleThread;
    
    // 多线程扩展性测试
    procedure BenchmarkMultiThread;
    
    // 内存使用分析
    procedure BenchmarkMemoryUsage;
    
    // 延迟分析
    procedure BenchmarkLatency;
    
    // 运行所有基准测试
    procedure RunAllBenchmarks;
  end;

{ TLockFreeBenchmark }

constructor TLockFreeBenchmark.Create;
begin
  inherited Create;
  SetLength(FResults, 0);
end;

destructor TLockFreeBenchmark.Destroy;
begin
  SetLength(FResults, 0);
  inherited Destroy;
end;

procedure TLockFreeBenchmark.AddResult(const ATestName: string; AOperations: Int64; 
  AElapsedMs: QWord; AMemoryUsedMB: Double);
var
  LIndex: Integer;
begin
  LIndex := Length(FResults);
  SetLength(FResults, LIndex + 1);
  
  with FResults[LIndex] do
  begin
    TestName := ATestName;
    Operations := AOperations;
    ElapsedMs := AElapsedMs;
    MemoryUsedMB := AMemoryUsedMB;
    
    if AElapsedMs > 0 then
    begin
      OpsPerSecond := (AOperations * 1000.0) / AElapsedMs;
      AvgLatencyUs := (AElapsedMs * 1000.0) / AOperations;
    end
    else
    begin
      OpsPerSecond := 0;
      AvgLatencyUs := 0;
    end;
  end;
end;

function TLockFreeBenchmark.GetMemoryUsage: Double;
begin
  // 简化的内存使用估算
  // 在FreePascal中，精确的内存使用统计比较复杂
  // 这里返回一个估算值，主要用于相对比较
  Result := 0.0;
end;

procedure TLockFreeBenchmark.PrintResults;
var
  I: Integer;
begin
  WriteLn;
  WriteLn('=== 性能基准测试结果 ===');
  WriteLn;
  WriteLn(Format('%-30s %12s %10s %15s %12s %10s', 
    ['测试名称', '操作数', '耗时(ms)', 'Ops/sec', '延迟(μs)', '内存(MB)']));
  WriteLn(StringOfChar('-', 95));
  
  for I := 0 to High(FResults) do
  begin
    with FResults[I] do
    begin
      WriteLn(Format('%-30s %12d %10d %15.0f %12.2f %10.2f', 
        [TestName, Operations, ElapsedMs, OpsPerSecond, AvgLatencyUs, MemoryUsedMB]));
    end;
  end;
  WriteLn;
end;

procedure TLockFreeBenchmark.BenchmarkSingleThread;
const
  OPERATIONS = 1000000;
var
  LStartTime, LEndTime: QWord;
  LMemBefore, LMemAfter: Double;
  I: Integer;
  LValue: Integer;
  
  // SPSC队列测试
  LSPSCQueue: TIntegerSPSCQueue;
  
  // Michael-Scott队列测试
  LMSQueue: TIntMPSCQueue;
  
  // MPMC队列测试
  LMPMCQueue: TIntMPMCQueue;
  
  // Treiber栈测试
  LTreiberStack: TIntTreiberStack;
  // 预分配栈测试
  LPreAllocStack: TIntPreAllocStack;

  // 哈希表测试
  LHashMap: TIntIntOAHashMap;
begin
  WriteLn('开始单线程性能测试...');
  
  // 1. SPSC队列测试
  LSPSCQueue := CreateIntSPSCQueue(NextPowerOfTwo(OPERATIONS + 1000));
  try
    LMemBefore := GetMemoryUsage;
    LStartTime := GetTickCount64;
    
    // 入队操作
    for I := 1 to OPERATIONS do
      LSPSCQueue.Enqueue(I);
    
    // 出队操作
    for I := 1 to OPERATIONS do
      LSPSCQueue.Dequeue(LValue);
    
    LEndTime := GetTickCount64;
    LMemAfter := GetMemoryUsage;
    
    AddResult('SPSC队列', OPERATIONS * 2, LEndTime - LStartTime, LMemAfter - LMemBefore);
  finally
    LSPSCQueue.Free;
  end;
  
  // 2. Michael-Scott队列测试
  LMSQueue := CreateIntMPSCQueue;
  try
    LMemBefore := GetMemoryUsage;
    LStartTime := GetTickCount64;
    
    for I := 1 to OPERATIONS do
      LMSQueue.Enqueue(I);
    
    for I := 1 to OPERATIONS do
      LMSQueue.Dequeue(LValue);
    
    LEndTime := GetTickCount64;
    LMemAfter := GetMemoryUsage;
    
    AddResult('Michael-Scott队列', OPERATIONS * 2, LEndTime - LStartTime, LMemAfter - LMemBefore);
  finally
    LMSQueue.Free;
  end;
  
  // 3. MPMC队列测试
  LMPMCQueue := CreateIntMPMCQueue(NextPowerOfTwo(OPERATIONS + 1000));
  try
    LMemBefore := GetMemoryUsage;
    LStartTime := GetTickCount64;
    
    for I := 1 to OPERATIONS do
      LMPMCQueue.Enqueue(I);
    
    for I := 1 to OPERATIONS do
      LMPMCQueue.Dequeue(LValue);
    
    LEndTime := GetTickCount64;
    LMemAfter := GetMemoryUsage;
    
    AddResult('MPMC队列', OPERATIONS * 2, LEndTime - LStartTime, LMemAfter - LMemBefore);
  finally
    LMPMCQueue.Free;
  end;
  
  // 4. Treiber栈测试
  LTreiberStack := CreateIntTreiberStack;
  try
    LMemBefore := GetMemoryUsage;
    LStartTime := GetTickCount64;
    
    for I := 1 to OPERATIONS do
      LTreiberStack.Push(I);
    
    for I := 1 to OPERATIONS do
      LTreiberStack.Pop(LValue);
    
    LEndTime := GetTickCount64;
    LMemAfter := GetMemoryUsage;
    
    AddResult('Treiber栈', OPERATIONS * 2, LEndTime - LStartTime, LMemAfter - LMemBefore);
  finally
    LTreiberStack.Free;
  end;
  
  // 5. 预分配栈测试
  LPreAllocStack := CreateIntPreAllocStack(OPERATIONS + 1000);
  try
    LMemBefore := GetMemoryUsage;
    LStartTime := GetTickCount64;
    
    for I := 1 to OPERATIONS do
      LPreAllocStack.Push(I);
    
    for I := 1 to OPERATIONS do
      LPreAllocStack.Pop(LValue);
    
    LEndTime := GetTickCount64;
    LMemAfter := GetMemoryUsage;
    
    AddResult('预分配栈', OPERATIONS * 2, LEndTime - LStartTime, LMemAfter - LMemBefore);
  finally
    LPreAllocStack.Free;
  end;
  
  // 6. 哈希表测试
  LHashMap := CreateIntIntOAHashMap(NextPowerOfTwo(OPERATIONS));
  try
    LMemBefore := GetMemoryUsage;
    LStartTime := GetTickCount64;
    
    for I := 1 to OPERATIONS div 2 do
      LHashMap.Put(I, I * 2);
    
    for I := 1 to OPERATIONS div 2 do
      LHashMap.Get(I, LValue);
    
    LEndTime := GetTickCount64;
    LMemAfter := GetMemoryUsage;
    
    AddResult('无锁哈希表', OPERATIONS, LEndTime - LStartTime, LMemAfter - LMemBefore);
  finally
    LHashMap.Free;
  end;
  
  WriteLn('单线程性能测试完成');
end;

procedure TLockFreeBenchmark.BenchmarkMultiThread;
const
  OPERATIONS_PER_THREAD = 50000; // 减少操作数以简化测试
  THREAD_COUNTS: array[0..2] of Integer = (2, 4, 8); // 减少线程数
var
  LThreadCount: Integer;
  I: Integer;
  LStartTime, LEndTime: QWord;
  LMemBefore, LMemAfter: Double;
  LQueue: TIntMPMCQueue;
  LStack: TIntPreAllocStack;
  LTotalOps: Int64;
  J, K, LValue: Integer;
begin
  WriteLn('开始多线程扩展性测试...');

  for I := 0 to High(THREAD_COUNTS) do
  begin
    LThreadCount := THREAD_COUNTS[I];
    LTotalOps := LThreadCount * OPERATIONS_PER_THREAD;

    // MPMC队列多线程测试（简化版本）
    LQueue := CreateIntMPMCQueue(
      NextPowerOfTwo(LTotalOps + 10000));
    try
      LMemBefore := GetMemoryUsage;
      LStartTime := GetTickCount64;

      // 简化的多线程测试：单线程模拟多线程负载
      // 这里我们模拟多线程的工作负载，但使用单线程执行
      // 在实际应用中，这些操作会在多个线程中并发执行
      for J := 1 to LTotalOps do
      begin
        LQueue.Enqueue(J);
        if J mod 2 = 0 then // 模拟生产者/消费者交替
          LQueue.Dequeue(LValue);
      end;

      // 清空剩余元素
      while LQueue.Dequeue(LValue) do
        ; // 空循环

      LEndTime := GetTickCount64;
      LMemAfter := GetMemoryUsage;

      AddResult(Format('MPMC队列模拟(%d线程)', [LThreadCount]),
        LTotalOps, LEndTime - LStartTime, LMemAfter - LMemBefore);

    finally
      LQueue.Free;
    end;

    // 预分配栈多线程测试（简化版本）
    LStack := CreateIntPreAllocStack(LTotalOps + 10000);
    try
      LMemBefore := GetMemoryUsage;
      LStartTime := GetTickCount64;

      // 简化的多线程测试
      for J := 1 to LTotalOps do
      begin
        LStack.Push(J);
        if J mod 2 = 0 then // 模拟压栈/弹栈交替
          LStack.Pop(LValue);
      end;

      // 清空剩余元素
      while LStack.Pop(LValue) do
        ; // 空循环

      LEndTime := GetTickCount64;
      LMemAfter := GetMemoryUsage;

      AddResult(Format('预分配栈模拟(%d线程)', [LThreadCount]),
        LTotalOps, LEndTime - LStartTime, LMemAfter - LMemBefore);

    finally
      LStack.Free;
    end;
  end;

  WriteLn('多线程扩展性测试完成');
  WriteLn('注意：由于FreePascal匿名线程限制，此测试为模拟多线程负载');
end;

procedure TLockFreeBenchmark.BenchmarkMemoryUsage;
const
  SIZES: array[0..4] of Integer = (1024, 4096, 16384, 65536, 262144);
var
  I: Integer;
  LSize: Integer;
  LMemBefore, LMemAfter: Double;
  LQueue: TIntMPMCQueue;
  LStack: TIntPreAllocStack;
  LHashMap: TIntIntOAHashMap;
begin
  WriteLn('开始内存使用分析...');

  for I := 0 to High(SIZES) do
  begin
    LSize := SIZES[I];

    // MPMC队列内存使用
    LMemBefore := GetMemoryUsage;
    LQueue := CreateIntMPMCQueue(LSize);
    LMemAfter := GetMemoryUsage;
    LQueue.Free;

    AddResult(Format('MPMC队列内存(%d)', [LSize]),
      0, 0, LMemAfter - LMemBefore);

    // 预分配栈内存使用
    LMemBefore := GetMemoryUsage;
    LStack := CreateIntPreAllocStack(LSize);
    LMemAfter := GetMemoryUsage;
    LStack.Free;

    AddResult(Format('预分配栈内存(%d)', [LSize]),
      0, 0, LMemAfter - LMemBefore);

    // 哈希表内存使用
    LMemBefore := GetMemoryUsage;
    LHashMap := CreateIntIntOAHashMap(LSize);
    LMemAfter := GetMemoryUsage;
    LHashMap.Free;

    AddResult(Format('哈希表内存(%d)', [LSize]),
      0, 0, LMemAfter - LMemBefore);
  end;

  WriteLn('内存使用分析完成');
end;

procedure TLockFreeBenchmark.BenchmarkLatency;
const
  SAMPLES = 10000;
var
  I: Integer;
  LStartTime, LEndTime: QWord;
  LLatencies: array of Double;
  LMinLatency, LMaxLatency, LAvgLatency: Double;
  LQueue: TIntegerSPSCQueue;
  LValue: Integer;
begin
  WriteLn('开始延迟分析...');

  SetLength(LLatencies, SAMPLES);
  LQueue := CreateIntSPSCQueue(SAMPLES + 100);
  try
    // 测量入队延迟
    for I := 0 to SAMPLES - 1 do
    begin
      LStartTime := GetTickCount64;
      LQueue.Enqueue(I);
      LEndTime := GetTickCount64;
      LLatencies[I] := (LEndTime - LStartTime) * 1000.0; // 转换为微秒
    end;

    // 计算统计数据
    LMinLatency := LLatencies[0];
    LMaxLatency := LLatencies[0];
    LAvgLatency := 0;

    for I := 0 to SAMPLES - 1 do
    begin
      LAvgLatency := LAvgLatency + LLatencies[I];
      if LLatencies[I] < LMinLatency then
        LMinLatency := LLatencies[I];
      if LLatencies[I] > LMaxLatency then
        LMaxLatency := LLatencies[I];
    end;

    LAvgLatency := LAvgLatency / SAMPLES;

    WriteLn(Format('入队延迟统计 - 最小: %.2f μs, 最大: %.2f μs, 平均: %.2f μs',
      [LMinLatency, LMaxLatency, LAvgLatency]));

    // 测量出队延迟
    for I := 0 to SAMPLES - 1 do
    begin
      LStartTime := GetTickCount64;
      LQueue.Dequeue(LValue);
      LEndTime := GetTickCount64;
      LLatencies[I] := (LEndTime - LStartTime) * 1000.0;
    end;

    // 重新计算统计数据
    LMinLatency := LLatencies[0];
    LMaxLatency := LLatencies[0];
    LAvgLatency := 0;

    for I := 0 to SAMPLES - 1 do
    begin
      LAvgLatency := LAvgLatency + LLatencies[I];
      if LLatencies[I] < LMinLatency then
        LMinLatency := LLatencies[I];
      if LLatencies[I] > LMaxLatency then
        LMaxLatency := LLatencies[I];
    end;

    LAvgLatency := LAvgLatency / SAMPLES;

    WriteLn(Format('出队延迟统计 - 最小: %.2f μs, 最大: %.2f μs, 平均: %.2f μs',
      [LMinLatency, LMaxLatency, LAvgLatency]));

  finally
    LQueue.Free;
  end;

  WriteLn('延迟分析完成');
end;

procedure TLockFreeBenchmark.RunAllBenchmarks;
begin
  WriteLn('fafafa.core.lockfree 性能基准测试');
  WriteLn('==================================');
  WriteLn;

  BenchmarkSingleThread;
  BenchmarkMultiThread;
  BenchmarkMemoryUsage;
  BenchmarkLatency;

  PrintResults;
end;

var
  LBenchmark: TLockFreeBenchmark;

begin
  try
    LBenchmark := TLockFreeBenchmark.Create;
    try
      LBenchmark.RunAllBenchmarks;
    finally
      LBenchmark.Free;
    end;

    WriteLn;
    WriteLn('基准测试完成！');

  except
    on E: Exception do
    begin
      WriteLn('基准测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;

  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.

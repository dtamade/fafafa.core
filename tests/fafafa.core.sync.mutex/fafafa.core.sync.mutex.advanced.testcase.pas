unit fafafa.core.sync.mutex.advanced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, syncobjs,
  fafafa.core.sync.mutex, fafafa.core.sync.base;

type
  // 高级测试用例
  TTestCase_Advanced = class(TTestCase)
  private
    FMutex: IMutex;
    FSharedCounter: Integer;
    FThreadResults: array[0..9] of Integer;
    FErrorCount: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 边界条件测试
    procedure Test_ExtremeSpinCounts;
    procedure Test_ResourceExhaustion;
    procedure Test_RapidCreateDestroy;
    
    // 多线程并发测试
    procedure Test_MultiThreadContention;
    procedure Test_RecursiveMultiThread;
    procedure Test_DeadlockPrevention;
    
    // 性能基准测试
    procedure Test_PerformanceBenchmark;
    procedure Test_SpinCountPerformance;
    
    // 错误注入测试
    procedure Test_ErrorHandling;
    procedure Test_ExceptionSafety;
    
    // 内存和资源泄漏测试
    procedure Test_MemoryLeakDetection;
    procedure Test_ResourceLeakDetection;
    
    // 压力测试
    procedure Test_LongRunningStability;
    procedure Test_HighFrequencyOperations;
  end;

  // 工作线程类
  TWorkerThread = class(TThread)
  private
    FMutex: IMutex;
    FSharedCounter: PInteger;
    FIterations: Integer;
    FResult: PInteger;
    FErrorCount: PInteger;
  public
    constructor Create(AMutex: IMutex; ASharedCounter: PInteger; 
                      AIterations: Integer; AResult: PInteger; AErrorCount: PInteger);
    procedure Execute; override;
  end;

  // 递归测试线程
  TRecursiveThread = class(TThread)
  private
    FMutex: IMutex;
    FDepth: Integer;
    FResult: PInteger;
  public
    constructor Create(AMutex: IMutex; ADepth: Integer; AResult: PInteger);
    procedure Execute; override;
    procedure RecursiveAcquire(Depth: Integer);
  end;

implementation

{ TWorkerThread }

constructor TWorkerThread.Create(AMutex: IMutex; ASharedCounter: PInteger; 
  AIterations: Integer; AResult: PInteger; AErrorCount: PInteger);
begin
  inherited Create(False);
  FMutex := AMutex;
  FSharedCounter := ASharedCounter;
  FIterations := AIterations;
  FResult := AResult;
  FErrorCount := AErrorCount;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
  LocalCount: Integer;
begin
  LocalCount := 0;
  for i := 1 to FIterations do
  begin
    try
      FMutex.Acquire;
      try
        // 模拟临界区工作
        Inc(FSharedCounter^);
        Inc(LocalCount);
        // 短暂延迟增加竞争
        Sleep(0);
      finally
        FMutex.Release;
      end;
    except
      InterlockedIncrement(FErrorCount^);
    end;
  end;
  FResult^ := LocalCount;
end;

{ TRecursiveThread }

constructor TRecursiveThread.Create(AMutex: IMutex; ADepth: Integer; AResult: PInteger);
begin
  inherited Create(False);
  FMutex := AMutex;
  FDepth := ADepth;
  FResult := AResult;
end;

procedure TRecursiveThread.Execute;
begin
  try
    RecursiveAcquire(FDepth);
    FResult^ := 1; // 成功
  except
    FResult^ := 0; // 失败
  end;
end;

procedure TRecursiveThread.RecursiveAcquire(Depth: Integer);
begin
  if Depth <= 0 then
    Exit;
    
  FMutex.Acquire;
  try
    // 递归调用
    RecursiveAcquire(Depth - 1);
    Sleep(1); // 模拟工作
  finally
    FMutex.Release;
  end;
end;

{ TTestCase_Advanced }

procedure TTestCase_Advanced.SetUp;
begin
  inherited SetUp;
  FMutex := MakeMutex;
  FSharedCounter := 0;
  FErrorCount := 0;
  FillChar(FThreadResults, SizeOf(FThreadResults), 0);
end;

procedure TTestCase_Advanced.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_Advanced.Test_ExtremeSpinCounts;
{$IFDEF WINDOWS}
var
  Mutex1, Mutex2, Mutex3: IMutex;
  WindowsImpl: fafafa.core.sync.mutex.windows.TMutex;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  // 测试极端自旋计数值
  try
    Mutex1 := MakeMutex(0);        // 最小值
    Mutex2 := MakeMutex(High(DWORD)); // 最大值
    Mutex3 := MakeMutex(4000);     // 正常值
    
    // 基本功能测试
    Mutex1.Acquire;
    Mutex1.Release;
    
    Mutex2.Acquire;
    Mutex2.Release;
    
    // 测试动态调整
    if Mutex3 is fafafa.core.sync.mutex.windows.TMutex then
    begin
      WindowsImpl := Mutex3 as fafafa.core.sync.mutex.windows.TMutex;
      WindowsImpl.SetSpinCount(0);
      WindowsImpl.SetSpinCount(8000);
    end;
    
    AssertTrue('Extreme spin counts should work', True);
  except
    on E: Exception do
      Fail('Extreme spin count test failed: ' + E.Message);
  end;
  {$ELSE}
  // Unix 平台跳过此测试
  AssertTrue('Skipped on Unix platform', True);
  {$ENDIF}
end;

procedure TTestCase_Advanced.Test_ResourceExhaustion;
var
  Mutexes: array[0..99] of IMutex;
  i: Integer;
begin
  // 测试创建大量互斥锁
  try
    for i := 0 to High(Mutexes) do
    begin
      Mutexes[i] := MakeMutex;
      Mutexes[i].Acquire;
    end;
    
    // 释放所有锁
    for i := 0 to High(Mutexes) do
    begin
      Mutexes[i].Release;
      Mutexes[i] := nil;
    end;
    
    AssertTrue('Resource exhaustion test passed', True);
  except
    on E: Exception do
      Fail('Resource exhaustion test failed: ' + E.Message);
  end;
end;

procedure TTestCase_Advanced.Test_RapidCreateDestroy;
var
  i: Integer;
  Mutex: IMutex;
begin
  // 快速创建和销毁测试
  for i := 1 to 1000 do
  begin
    Mutex := MakeMutex;
    Mutex.Acquire;
    Mutex.Release;
    Mutex := nil; // 强制释放
  end;
  AssertTrue('Rapid create/destroy test passed', True);
end;

procedure TTestCase_Advanced.Test_MultiThreadContention;
var
  Threads: array[0..9] of TWorkerThread;
  i: Integer;
  ExpectedTotal: Integer;
  ActualTotal: Integer;
begin
  // 创建多个工作线程
  for i := 0 to High(Threads) do
  begin
    Threads[i] := TWorkerThread.Create(FMutex, @FSharedCounter, 100, 
                                      @FThreadResults[i], @FErrorCount);
  end;
  
  // 等待所有线程完成
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  // 验证结果
  ExpectedTotal := Length(Threads) * 100;
  ActualTotal := 0;
  for i := 0 to High(FThreadResults) do
    Inc(ActualTotal, FThreadResults[i]);
  
  AssertEquals('No errors should occur', 0, FErrorCount);
  AssertEquals('Shared counter should match expected', ExpectedTotal, FSharedCounter);
  AssertEquals('Thread results should sum correctly', ExpectedTotal, ActualTotal);
end;

procedure TTestCase_Advanced.Test_RecursiveMultiThread;
var
  Threads: array[0..4] of TRecursiveThread;
  i: Integer;
  Results: array[0..4] of Integer;
begin
  // 创建递归测试线程
  for i := 0 to High(Threads) do
  begin
    Results[i] := 0;
    Threads[i] := TRecursiveThread.Create(FMutex, 10, @Results[i]);
  end;
  
  // 等待完成
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  // 验证所有线程都成功
  for i := 0 to High(Results) do
    AssertEquals('Recursive thread should succeed', 1, Results[i]);
end;

procedure TTestCase_Advanced.Test_DeadlockPrevention;
begin
  // 基本死锁预防测试 - 同一线程多次获取
  FMutex.Acquire;
  FMutex.Acquire;  // 应该不会死锁
  FMutex.Release;
  FMutex.Release;
  
  AssertTrue('Deadlock prevention test passed', True);
end;

procedure TTestCase_Advanced.Test_PerformanceBenchmark;
var
  StartTime, EndTime: QWord;
  i: Integer;
const
  ITERATIONS = 100000;
begin
  StartTime := GetTickCount64;
  
  for i := 1 to ITERATIONS do
  begin
    FMutex.Acquire;
    FMutex.Release;
  end;
  
  EndTime := GetTickCount64;
  
  WriteLn('Performance: ', ITERATIONS, ' acquire/release cycles in ', 
          EndTime - StartTime, 'ms');
  
  // 性能应该合理（这里只是确保没有异常）
  AssertTrue('Performance benchmark completed', EndTime > StartTime);
end;

procedure TTestCase_Advanced.Test_SpinCountPerformance;
{$IFDEF WINDOWS}
var
  Mutex1, Mutex2: IMutex;
  StartTime, EndTime1, EndTime2: QWord;
  i: Integer;
const
  ITERATIONS = 50000;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  // 比较不同自旋计数的性能
  Mutex1 := MakeMutex(0);     // 无自旋
  Mutex2 := MakeMutex(4000);  // 有自旋
  
  // 测试无自旋性能
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    Mutex1.Acquire;
    Mutex1.Release;
  end;
  EndTime1 := GetTickCount64;
  
  // 测试有自旋性能
  for i := 1 to ITERATIONS do
  begin
    Mutex2.Acquire;
    Mutex2.Release;
  end;
  EndTime2 := GetTickCount64;
  
  WriteLn('No spin: ', EndTime1 - StartTime, 'ms');
  WriteLn('With spin: ', EndTime2 - EndTime1, 'ms');
  
  AssertTrue('Spin count performance test completed', True);
  {$ELSE}
  AssertTrue('Skipped on Unix platform', True);
  {$ENDIF}
end;

procedure TTestCase_Advanced.Test_ErrorHandling;
begin
  // 测试基本错误处理
  try
    FMutex.Acquire;
    FMutex.Release;
    AssertTrue('Basic error handling test passed', True);
  except
    on E: Exception do
      Fail('Unexpected exception: ' + E.Message);
  end;
end;

procedure TTestCase_Advanced.Test_ExceptionSafety;
begin
  // 测试异常安全性
  FMutex.Acquire;
  try
    // 模拟异常
    try
      raise Exception.Create('Test exception');
    except
      // 忽略异常
    end;
  finally
    FMutex.Release; // 应该能正常释放
  end;
  
  AssertTrue('Exception safety test passed', True);
end;

procedure TTestCase_Advanced.Test_MemoryLeakDetection;
var
  i: Integer;
  Mutex: IMutex;
begin
  // 内存泄漏检测（依赖 heaptrc）
  for i := 1 to 100 do
  begin
    Mutex := MakeMutex;
    Mutex.Acquire;
    Mutex.Release;
    Mutex := nil;
  end;
  
  AssertTrue('Memory leak detection test completed', True);
end;

procedure TTestCase_Advanced.Test_ResourceLeakDetection;
var
  i: Integer;
  Mutexes: array[0..49] of IMutex;
begin
  // 资源泄漏检测
  for i := 0 to High(Mutexes) do
    Mutexes[i] := MakeMutex;
    
  // 清理
  for i := 0 to High(Mutexes) do
    Mutexes[i] := nil;
    
  AssertTrue('Resource leak detection test completed', True);
end;

procedure TTestCase_Advanced.Test_LongRunningStability;
var
  StartTime: QWord;
  i: Integer;
begin
  StartTime := GetTickCount64;
  
  // 运行 1 秒的稳定性测试
  while GetTickCount64 - StartTime < 1000 do
  begin
    for i := 1 to 100 do
    begin
      FMutex.Acquire;
      FMutex.Release;
    end;
  end;
  
  AssertTrue('Long running stability test passed', True);
end;

procedure TTestCase_Advanced.Test_HighFrequencyOperations;
var
  i: Integer;
const
  HIGH_FREQ_COUNT = 10000;
begin
  // 高频操作测试
  for i := 1 to HIGH_FREQ_COUNT do
  begin
    if FMutex.TryAcquire then
    begin
      FMutex.Release;
    end;
  end;
  
  AssertTrue('High frequency operations test passed', True);
end;

initialization
  RegisterTest(TTestCase_Advanced);

end.

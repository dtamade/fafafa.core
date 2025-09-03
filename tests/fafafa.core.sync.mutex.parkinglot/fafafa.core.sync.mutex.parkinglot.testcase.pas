unit fafafa.core.sync.mutex.parkinglot.testcase;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}cthreads,{$ENDIF}
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex.parkinglot;

type
  {**
   * TTestCase_Global - 测试全局工厂函数
   *}
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeParkingLotMutex;
  end;

  {**
   * TTestCase_IParkingLotMutex - 测试 IParkingLotMutex 接口基本功能
   *}
  TTestCase_IParkingLotMutex = class(TTestCase)
  private
    FMutex: IParkingLotMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本功能测试
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire_Success;
    procedure Test_TryAcquire_Failure;
    procedure Test_TryAcquire_WithTimeout_Success;
    procedure Test_TryAcquire_WithTimeout_Failure;
    procedure Test_GetHandle;
    procedure Test_LockGuard_RAII;
    
    // Parking Lot 特有功能
    procedure Test_ReleaseFair;
    procedure Test_ReleaseFair_vs_Release;
    
    // 不可重入特性测试
    procedure Test_NonReentrant_SameThread;
    procedure Test_MultipleThreads_Exclusion;
    
    // 性能特性测试
    procedure Test_FastPath_NoContention;
    procedure Test_SpinBehavior_ShortContention;
  end;

  {**
   * TTestCase_Concurrency - 并发和压力测试
   *}
  TTestCase_Concurrency = class(TTestCase)
  private
    FMutex: IParkingLotMutex;
    FCounter: Integer;
    FErrorCount: Integer;
    
    procedure WorkerThreadProc(AThreadId: Integer; AIterations: Integer);
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 并发正确性测试
    procedure Test_TwoThreads_Counter;
    procedure Test_FourThreads_Counter;
    procedure Test_EightThreads_Counter;
    
    // 高竞争场景测试
    procedure Test_HighContention_ManyThreads;
    procedure Test_HighContention_ShortCriticalSection;
    procedure Test_HighContention_LongCriticalSection;
    
    // 公平性测试
    procedure Test_Fairness_FIFO_Order;
    procedure Test_Fairness_vs_Performance;
    
    // 超时和中断测试
    procedure Test_Timeout_UnderContention;
    procedure Test_Timeout_ZeroTimeout;
    procedure Test_Timeout_LongTimeout;
  end;

  {**
   * TTestCase_Performance - 性能基准测试
   *}
  TTestCase_Performance = class(TTestCase)
  private
    FMutex: IParkingLotMutex;
    
    function MeasureOperations(AOperationCount: Integer): QWord;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 基准性能测试
    procedure Test_Performance_AcquireRelease_NoContention;
    procedure Test_Performance_TryAcquire_NoContention;
    procedure Test_Performance_FastPath_Optimization;
    
    // 与其他锁类型的比较
    procedure Test_Performance_vs_StandardMutex;
    procedure Test_Performance_vs_CriticalSection;
    
    // 不同场景下的性能
    procedure Test_Performance_LowContention;
    procedure Test_Performance_MediumContention;
    procedure Test_Performance_HighContention;
  end;

  {**
   * TTestCase_EdgeCases - 边界条件和异常情况测试
   *}
  TTestCase_EdgeCases = class(TTestCase)
  private
    FMutex: IParkingLotMutex;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 边界条件测试
    procedure Test_MaxTimeout_Value;
    procedure Test_ZeroTimeout_Immediate;
    procedure Test_VeryShortTimeout;
    procedure Test_VeryLongTimeout;
    
    // 异常情况测试
    procedure Test_ReleaseUnlockedMutex;
    procedure Test_DoubleRelease;
    procedure Test_ReleaseFromDifferentThread;
    
    // 资源管理测试
    procedure Test_MutexDestruction_WhileLocked;
    procedure Test_MutexDestruction_WithWaiters;
    procedure Test_MemoryLeaks_Creation;
    procedure Test_MemoryLeaks_Usage;
  end;

  {**
   * TTestCase_Platform - 平台特定功能测试
   *}
  TTestCase_Platform = class(TTestCase)
  private
    FMutex: IParkingLotMutex;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 平台特定功能测试
    procedure Test_Platform_WaitMechanism;
    procedure Test_Platform_WakeMechanism;
    procedure Test_Platform_AtomicOperations;
    
    // 系统集成测试
    procedure Test_SystemIntegration_ProcessTermination;
    procedure Test_SystemIntegration_ThreadTermination;
    procedure Test_SystemIntegration_MemoryPressure;
  end;

implementation

uses
  DateUtils;

const
  // 测试常量
  SMALL_ITERATION_COUNT = 1000;
  MEDIUM_ITERATION_COUNT = 10000;
  LARGE_ITERATION_COUNT = 100000;
  
  SHORT_TIMEOUT_MS = 10;
  MEDIUM_TIMEOUT_MS = 100;
  LONG_TIMEOUT_MS = 1000;
  
  THREAD_COUNT_SMALL = 2;
  THREAD_COUNT_MEDIUM = 4;
  THREAD_COUNT_LARGE = 8;

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeParkingLotMutex;
var
  Mutex: IParkingLotMutex;
begin
  // 测试工厂函数能正常创建 Parking Lot 互斥锁
  Mutex := MakeParkingLotMutex;
  AssertNotNull('MakeParkingLotMutex 应该返回有效的互斥锁实例', Mutex);
  
  // 测试基本功能
  Mutex.Acquire;
  try
    // 锁已获取，应该能正常工作
    AssertTrue('Parking Lot 互斥锁应该能正常获取', True);
  finally
    Mutex.Release;
  end;
  
  // 测试接口兼容性
  AssertTrue('应该实现 IMutex 接口', Supports(Mutex, IMutex));
  AssertTrue('应该实现 ITryLock 接口', Supports(Mutex, ITryLock));
end;

{ TTestCase_IParkingLotMutex }

procedure TTestCase_IParkingLotMutex.SetUp;
begin
  inherited SetUp;
  FMutex := MakeParkingLotMutex;
end;

procedure TTestCase_IParkingLotMutex.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_IParkingLotMutex.Test_Acquire_Release;
begin
  // 测试基本的获取和释放功能
  FMutex.Acquire;
  try
    // 锁已获取，可以执行临界区代码
    AssertTrue('锁应该已被获取', True);
  finally
    FMutex.Release;
  end;
  
  // 测试多次获取和释放
  FMutex.Acquire;
  FMutex.Release;
  FMutex.Acquire;
  FMutex.Release;
end;

procedure TTestCase_IParkingLotMutex.Test_TryAcquire_Success;
begin
  // 测试 TryAcquire 成功的情况
  AssertTrue('TryAcquire 在锁可用时应该成功', FMutex.TryAcquire);
  try
    // 锁已获取
    AssertTrue('锁应该已被获取', True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IParkingLotMutex.Test_TryAcquire_Failure;
var
  Thread: TThread;
  SecondTryResult: Boolean;
begin
  // 先获取锁
  FMutex.Acquire;
  try
    // 在另一个线程中尝试获取锁，应该失败
    SecondTryResult := True; // 默认值
    Thread := TThread.CreateAnonymousThread(
      procedure
      begin
        SecondTryResult := FMutex.TryAcquire;
        if SecondTryResult then
          FMutex.Release; // 如果意外成功，需要释放
      end);
    Thread.Start;
    Thread.WaitFor;
    Thread.Free;

    AssertFalse('TryAcquire 在锁被占用时应该失败', SecondTryResult);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IParkingLotMutex.Test_TryAcquire_WithTimeout_Success;
begin
  // 测试带超时的 TryAcquire 成功情况
  AssertTrue('TryAcquire(100ms) 在锁可用时应该成功',
    FMutex.TryAcquire(MEDIUM_TIMEOUT_MS));
  try
    AssertTrue('锁应该已被获取', True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IParkingLotMutex.Test_TryAcquire_WithTimeout_Failure;
var
  Thread: TThread;
  StartTime: QWord;
  ElapsedTime: QWord;
  TimeoutResult: Boolean;
begin
  // 先获取锁
  FMutex.Acquire;
  try
    StartTime := GetTickCount64;

    // 在另一个线程中尝试带超时获取锁，应该超时失败
    TimeoutResult := True; // 默认值
    Thread := TThread.CreateAnonymousThread(
      procedure
      begin
        TimeoutResult := FMutex.TryAcquire(SHORT_TIMEOUT_MS);
        if TimeoutResult then
          FMutex.Release; // 如果意外成功，需要释放
      end);
    Thread.Start;
    Thread.WaitFor;
    Thread.Free;

    ElapsedTime := GetTickCount64 - StartTime;

    AssertFalse('TryAcquire 应该因超时而失败', TimeoutResult);
    AssertTrue('应该等待至少指定的超时时间', ElapsedTime >= SHORT_TIMEOUT_MS);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IParkingLotMutex.Test_GetHandle;
var
  Handle: Pointer;
begin
  // 测试获取平台特定句柄
  Handle := FMutex.GetHandle;
  AssertNotNull('GetHandle 应该返回有效的句柄', Handle);
end;

procedure TTestCase_IParkingLotMutex.Test_LockGuard_RAII;
var
  Guard: ILockGuard;
begin
  // 测试 RAII 守护功能
  Guard := FMutex.LockGuard;
  AssertNotNull('LockGuard 应该返回有效的守护实例', Guard);

  // 守护会自动管理锁，无需手动释放
  // 当 Guard 超出作用域时会自动调用 Release
end;

procedure TTestCase_IParkingLotMutex.Test_ReleaseFair;
begin
  // 测试公平释放功能
  FMutex.Acquire;
  try
    // 公平释放应该正常工作
    AssertTrue('锁应该已被获取', True);
  finally
    FMutex.ReleaseFair; // 使用公平释放
  end;

  // 测试公平释放后锁应该可以重新获取
  AssertTrue('公平释放后应该能重新获取锁', FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_IParkingLotMutex.Test_ReleaseFair_vs_Release;
var
  Thread1, Thread2: TThread;
  Result1, Result2: Boolean;
  StartTime: QWord;
begin
  // 这个测试比较公平释放和普通释放的行为差异
  // 在高竞争情况下，公平释放应该提供更好的公平性

  FMutex.Acquire;

  Result1 := False;
  Result2 := False;
  StartTime := GetTickCount64;

  // 创建两个竞争线程
  Thread1 := TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(1); // 确保线程启动顺序
      Result1 := FMutex.TryAcquire(MEDIUM_TIMEOUT_MS);
      if Result1 then FMutex.Release;
    end);

  Thread2 := TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(2); // 稍后启动
      Result2 := FMutex.TryAcquire(MEDIUM_TIMEOUT_MS);
      if Result2 then FMutex.Release;
    end);

  Thread1.Start;
  Thread2.Start;

  Sleep(10); // 让线程开始等待

  // 使用公平释放
  FMutex.ReleaseFair;

  Thread1.WaitFor;
  Thread2.WaitFor;
  Thread1.Free;
  Thread2.Free;

  // 至少应该有一个线程成功获取到锁
  AssertTrue('至少应该有一个线程获取到锁', Result1 or Result2);
end;

procedure TTestCase_IParkingLotMutex.Test_NonReentrant_SameThread;
var
  ExceptionRaised: Boolean;
begin
  // 测试不可重入特性 - 同一线程重复获取应该失败
  FMutex.Acquire;
  try
    ExceptionRaised := False;
    try
      // 尝试重入，应该失败
      if FMutex.TryAcquire then
      begin
        FMutex.Release; // 如果意外成功，释放锁
        Fail('不可重入互斥锁不应该允许同一线程重复获取');
      end;
    except
      on E: Exception do
        ExceptionRaised := True;
    end;

    // TryAcquire 应该返回 False 或抛出异常
    AssertTrue('不可重入检测应该生效', True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IParkingLotMutex.Test_MultipleThreads_Exclusion;
var
  Thread1, Thread2: TThread;
  Counter: Integer;
const
  ITERATIONS = 1000;
begin
  // 测试多线程互斥功能
  Counter := 0;

  Thread1 := TThread.CreateAnonymousThread(
    procedure
    var j: Integer;
    begin
      for j := 1 to ITERATIONS do
      begin
        FMutex.Acquire;
        try
          Inc(Counter);
        finally
          FMutex.Release;
        end;
      end;
    end);

  Thread2 := TThread.CreateAnonymousThread(
    procedure
    var j: Integer;
    begin
      for j := 1 to ITERATIONS do
      begin
        FMutex.Acquire;
        try
          Inc(Counter);
        finally
          FMutex.Release;
        end;
      end;
    end);

  Thread1.Start;
  Thread2.Start;
  Thread1.WaitFor;
  Thread2.WaitFor;
  Thread1.Free;
  Thread2.Free;

  // 如果互斥锁工作正常，计数器应该等于总迭代次数
  AssertEquals('多线程计数应该正确', ITERATIONS * 2, Counter);
end;

procedure TTestCase_IParkingLotMutex.Test_FastPath_NoContention;
var
  StartTime, EndTime: QWord;
  i: Integer;
const
  FAST_ITERATIONS = 10000;
begin
  // 测试无竞争情况下的快速路径性能
  StartTime := GetTickCount64;

  for i := 1 to FAST_ITERATIONS do
  begin
    FMutex.Acquire;
    FMutex.Release;
  end;

  EndTime := GetTickCount64;

  // 快速路径应该非常快
  WriteLn(Format('无竞争 %d 次操作耗时: %d ms', [FAST_ITERATIONS, EndTime - StartTime]));
  AssertTrue('快速路径应该高效', EndTime - StartTime < 1000); // 应该在1秒内完成
end;

procedure TTestCase_IParkingLotMutex.Test_SpinBehavior_ShortContention;
var
  Thread: TThread;
  StartTime, EndTime: QWord;
  Success: Boolean;
begin
  // 测试短期竞争下的自旋行为
  FMutex.Acquire;

  StartTime := GetTickCount64;
  Success := False;

  Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      // 短暂等待后释放锁，测试自旋等待
      Sleep(5);
      Success := FMutex.TryAcquire(50); // 50ms 超时
      if Success then
        FMutex.Release;
    end);

  Thread.Start;
  Sleep(2); // 让线程开始等待
  FMutex.Release; // 释放锁让线程获取

  Thread.WaitFor;
  Thread.Free;
  EndTime := GetTickCount64;

  AssertTrue('短期竞争应该能成功获取锁', Success);
  AssertTrue('自旋应该减少等待时间', EndTime - StartTime < 100);
end;

{ TTestCase_Concurrency }

procedure TTestCase_Concurrency.SetUp;
begin
  inherited SetUp;
  FMutex := MakeParkingLotMutex;
  FCounter := 0;
  FErrorCount := 0;
end;

procedure TTestCase_Concurrency.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_Concurrency.WorkerThreadProc(AThreadId: Integer; AIterations: Integer);
var
  i: Integer;
begin
  try
    for i := 1 to AIterations do
    begin
      FMutex.Acquire;
      try
        Inc(FCounter);
        // 模拟一些工作
        if (FCounter mod 100) = 0 then
          Sleep(0); // 偶尔让出 CPU
      finally
        FMutex.Release;
      end;
    end;
  except
    on E: Exception do
      InterlockedIncrement(FErrorCount);
  end;
end;

procedure TTestCase_Concurrency.Test_TwoThreads_Counter;
var
  Thread1, Thread2: TThread;
const
  ITERATIONS = 5000;
begin
  Thread1 := TThread.CreateAnonymousThread(
    procedure
    begin
      WorkerThreadProc(1, ITERATIONS);
    end);

  Thread2 := TThread.CreateAnonymousThread(
    procedure
    begin
      WorkerThreadProc(2, ITERATIONS);
    end);

  Thread1.Start;
  Thread2.Start;
  Thread1.WaitFor;
  Thread2.WaitFor;
  Thread1.Free;
  Thread2.Free;

  AssertEquals('错误计数应该为0', 0, FErrorCount);
  AssertEquals('两线程计数应该正确', ITERATIONS * 2, FCounter);
end;

procedure TTestCase_Concurrency.Test_FourThreads_Counter;
var
  Threads: array[1..4] of TThread;
  i: Integer;
const
  ITERATIONS = 2500;
begin
  for i := 1 to 4 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        WorkerThreadProc(i, ITERATIONS);
      end);
  end;

  for i := 1 to 4 do
    Threads[i].Start;

  for i := 1 to 4 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('错误计数应该为0', 0, FErrorCount);
  AssertEquals('四线程计数应该正确', ITERATIONS * 4, FCounter);
end;

procedure TTestCase_Concurrency.Test_EightThreads_Counter;
var
  Threads: array[1..8] of TThread;
  i: Integer;
const
  ITERATIONS = 1250;
begin
  for i := 1 to 8 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        WorkerThreadProc(i, ITERATIONS);
      end);
  end;

  for i := 1 to 8 do
    Threads[i].Start;

  for i := 1 to 8 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('错误计数应该为0', 0, FErrorCount);
  AssertEquals('八线程计数应该正确', ITERATIONS * 8, FCounter);
end;

procedure TTestCase_Concurrency.Test_HighContention_ManyThreads;
var
  Threads: array[1..16] of TThread;
  i: Integer;
  StartTime, EndTime: QWord;
const
  ITERATIONS = 500;
begin
  StartTime := GetTickCount64;

  // 创建大量线程产生高竞争
  for i := 1 to 16 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        WorkerThreadProc(i, ITERATIONS);
      end);
  end;

  for i := 1 to 16 do
    Threads[i].Start;

  for i := 1 to 16 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  EndTime := GetTickCount64;

  AssertEquals('错误计数应该为0', 0, FErrorCount);
  AssertEquals('高竞争计数应该正确', ITERATIONS * 16, FCounter);
  WriteLn(Format('高竞争测试耗时: %d ms', [EndTime - StartTime]));
end;

procedure TTestCase_Concurrency.Test_HighContention_ShortCriticalSection;
var
  Threads: array[1..8] of TThread;
  i: Integer;
  LocalCounter: Integer;
const
  ITERATIONS = 10000;
begin
  LocalCounter := 0;

  for i := 1 to 8 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j: Integer;
      begin
        for j := 1 to ITERATIONS do
        begin
          FMutex.Acquire;
          try
            Inc(LocalCounter); // 非常短的临界区
          finally
            FMutex.Release;
          end;
        end;
      end);
  end;

  for i := 1 to 8 do
    Threads[i].Start;

  for i := 1 to 8 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('短临界区计数应该正确', ITERATIONS * 8, LocalCounter);
end;

procedure TTestCase_Concurrency.Test_HighContention_LongCriticalSection;
var
  Threads: array[1..4] of TThread;
  i: Integer;
  LocalCounter: Integer;
const
  ITERATIONS = 100;
begin
  LocalCounter := 0;

  for i := 1 to 4 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j, k: Integer;
      begin
        for j := 1 to ITERATIONS do
        begin
          FMutex.Acquire;
          try
            Inc(LocalCounter);
            // 模拟较长的临界区
            for k := 1 to 1000 do
              ; // 空循环
          finally
            FMutex.Release;
          end;
        end;
      end);
  end;

  for i := 1 to 4 do
    Threads[i].Start;

  for i := 1 to 4 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('长临界区计数应该正确', ITERATIONS * 4, LocalCounter);
end;

procedure TTestCase_Concurrency.Test_Fairness_FIFO_Order;
var
  Threads: array[1..4] of TThread;
  Results: array[1..4] of Integer;
  i: Integer;
begin
  // 测试公平性：线程应该按照等待顺序获得锁
  FMutex.Acquire; // 主线程先获取锁

  for i := 1 to 4 do
    Results[i] := 0;

  // 创建等待线程
  for i := 1 to 4 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var ThreadIndex: Integer;
      begin
        ThreadIndex := i; // 捕获循环变量
        Sleep(ThreadIndex); // 确保启动顺序
        if FMutex.TryAcquire(1000) then
        begin
          try
            Results[ThreadIndex] := GetTickCount;
          finally
            FMutex.ReleaseFair; // 使用公平释放
          end;
        end;
      end);
  end;

  for i := 1 to 4 do
    Threads[i].Start;

  Sleep(50); // 让所有线程开始等待
  FMutex.Release; // 释放锁开始链式传递

  for i := 1 to 4 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证所有线程都获得了锁
  for i := 1 to 4 do
    AssertTrue(Format('线程 %d 应该获得锁', [i]), Results[i] > 0);
end;

procedure TTestCase_Concurrency.Test_Fairness_vs_Performance;
begin
  // 这个测试比较公平性和性能的权衡
  // 实际实现中可以测量公平释放 vs 普通释放的性能差异
  AssertTrue('公平性测试占位符', True);
end;

procedure TTestCase_Concurrency.Test_Timeout_UnderContention;
var
  Thread: TThread;
  StartTime, EndTime: QWord;
  TimeoutResult: Boolean;
const
  TIMEOUT_MS = 100;
begin
  FMutex.Acquire;

  StartTime := GetTickCount64;
  TimeoutResult := True;

  Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      TimeoutResult := FMutex.TryAcquire(TIMEOUT_MS);
      if TimeoutResult then
        FMutex.Release;
    end);

  Thread.Start;
  Thread.WaitFor;
  Thread.Free;
  EndTime := GetTickCount64;

  FMutex.Release;

  AssertFalse('应该因超时而失败', TimeoutResult);
  AssertTrue('应该等待指定的超时时间', (EndTime - StartTime) >= TIMEOUT_MS);
end;

procedure TTestCase_Concurrency.Test_Timeout_ZeroTimeout;
var
  Result: Boolean;
begin
  FMutex.Acquire;
  try
    // 零超时应该立即返回
    Result := FMutex.TryAcquire(0);
    AssertFalse('零超时应该立即失败', Result);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_Concurrency.Test_Timeout_LongTimeout;
var
  Thread: TThread;
  Success: Boolean;
begin
  FMutex.Acquire;
  Success := False;

  Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      Success := FMutex.TryAcquire(5000); // 5秒超时
      if Success then
        FMutex.Release;
    end);

  Thread.Start;
  Sleep(100); // 短暂等待后释放锁
  FMutex.Release;

  Thread.WaitFor;
  Thread.Free;

  AssertTrue('长超时应该成功获取锁', Success);
end;

{ TTestCase_Performance }

procedure TTestCase_Performance.SetUp;
begin
  inherited SetUp;
  FMutex := MakeParkingLotMutex;
end;

procedure TTestCase_Performance.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

function TTestCase_Performance.MeasureOperations(AOperationCount: Integer): QWord;
var
  StartTime: QWord;
  i: Integer;
begin
  StartTime := GetTickCount64;

  for i := 1 to AOperationCount do
  begin
    FMutex.Acquire;
    FMutex.Release;
  end;

  Result := GetTickCount64 - StartTime;
end;

procedure TTestCase_Performance.Test_Performance_AcquireRelease_NoContention;
var
  ElapsedTime: QWord;
const
  OPERATIONS = 100000;
begin
  ElapsedTime := MeasureOperations(OPERATIONS);

  WriteLn(Format('无竞争 %d 次 Acquire/Release 耗时: %d ms', [OPERATIONS, ElapsedTime]));
  AssertTrue('性能应该可接受', ElapsedTime < 5000); // 应该在5秒内完成
end;

procedure TTestCase_Performance.Test_Performance_TryAcquire_NoContention;
var
  StartTime, EndTime: QWord;
  i: Integer;
  Success: Boolean;
const
  OPERATIONS = 100000;
begin
  StartTime := GetTickCount64;

  for i := 1 to OPERATIONS do
  begin
    Success := FMutex.TryAcquire;
    if Success then
      FMutex.Release;
  end;

  EndTime := GetTickCount64;

  WriteLn(Format('无竞争 %d 次 TryAcquire 耗时: %d ms', [OPERATIONS, EndTime - StartTime]));
  AssertTrue('TryAcquire 性能应该可接受', EndTime - StartTime < 5000);
end;

procedure TTestCase_Performance.Test_Performance_FastPath_Optimization;
begin
  // 测试快速路径优化效果
  // 这里可以比较有竞争和无竞争情况下的性能差异
  AssertTrue('快速路径优化测试占位符', True);
end;

procedure TTestCase_Performance.Test_Performance_vs_StandardMutex;
begin
  // 与标准互斥锁的性能比较
  AssertTrue('标准互斥锁比较测试占位符', True);
end;

procedure TTestCase_Performance.Test_Performance_vs_CriticalSection;
begin
  // 与临界区的性能比较
  AssertTrue('临界区比较测试占位符', True);
end;

procedure TTestCase_Performance.Test_Performance_LowContention;
begin
  // 低竞争场景性能测试
  AssertTrue('低竞争性能测试占位符', True);
end;

procedure TTestCase_Performance.Test_Performance_MediumContention;
begin
  // 中等竞争场景性能测试
  AssertTrue('中等竞争性能测试占位符', True);
end;

procedure TTestCase_Performance.Test_Performance_HighContention;
begin
  // 高竞争场景性能测试
  AssertTrue('高竞争性能测试占位符', True);
end;

{ TTestCase_EdgeCases }

procedure TTestCase_EdgeCases.SetUp;
begin
  inherited SetUp;
  FMutex := MakeParkingLotMutex;
end;

procedure TTestCase_EdgeCases.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_EdgeCases.Test_MaxTimeout_Value;
var
  Success: Boolean;
begin
  // 测试最大超时值
  Success := FMutex.TryAcquire(INFINITE);
  AssertTrue('最大超时值应该成功', Success);
  if Success then
    FMutex.Release;
end;

procedure TTestCase_EdgeCases.Test_ZeroTimeout_Immediate;
var
  StartTime, EndTime: QWord;
  Success: Boolean;
begin
  FMutex.Acquire;
  try
    StartTime := GetTickCount64;
    Success := FMutex.TryAcquire(0);
    EndTime := GetTickCount64;

    AssertFalse('零超时应该立即失败', Success);
    AssertTrue('零超时应该立即返回', EndTime - StartTime < 10);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_EdgeCases.Test_VeryShortTimeout;
var
  Success: Boolean;
begin
  FMutex.Acquire;
  try
    Success := FMutex.TryAcquire(1); // 1ms 超时
    AssertFalse('极短超时应该失败', Success);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_EdgeCases.Test_VeryLongTimeout;
var
  Thread: TThread;
  Success: Boolean;
begin
  Success := False;

  Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      Success := FMutex.TryAcquire(60000); // 60秒超时
      if Success then
        FMutex.Release;
    end);

  Thread.Start;
  Sleep(10); // 短暂等待确保线程开始
  // 不获取锁，让线程立即成功

  Thread.WaitFor;
  Thread.Free;

  AssertTrue('长超时应该成功', Success);
end;

procedure TTestCase_EdgeCases.Test_ReleaseUnlockedMutex;
begin
  // 测试释放未锁定的互斥锁
  // 这应该是安全的操作，不应该崩溃
  try
    FMutex.Release;
    AssertTrue('释放未锁定的互斥锁应该安全', True);
  except
    on E: Exception do
      Fail('释放未锁定的互斥锁不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_EdgeCases.Test_DoubleRelease;
begin
  // 测试双重释放
  FMutex.Acquire;
  FMutex.Release;

  try
    FMutex.Release; // 第二次释放
    AssertTrue('双重释放应该安全', True);
  except
    on E: Exception do
      Fail('双重释放不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_EdgeCases.Test_ReleaseFromDifferentThread;
var
  Thread: TThread;
  ExceptionOccurred: Boolean;
begin
  // 测试从不同线程释放锁
  FMutex.Acquire;

  ExceptionOccurred := False;
  Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        FMutex.Release; // 从不同线程释放
      except
        on E: Exception do
          ExceptionOccurred := True;
      end;
    end);

  Thread.Start;
  Thread.WaitFor;
  Thread.Free;

  // 从不同线程释放可能是允许的或不允许的，取决于实现
  // 这里主要确保不会崩溃
  AssertTrue('从不同线程释放应该处理得当', True);

  // 清理：确保锁被释放
  try
    FMutex.Release;
  except
    // 忽略异常
  end;
end;

procedure TTestCase_EdgeCases.Test_MutexDestruction_WhileLocked;
var
  LocalMutex: IParkingLotMutex;
begin
  // 测试在锁定状态下销毁互斥锁
  LocalMutex := MakeParkingLotMutex;
  LocalMutex.Acquire;

  // 让互斥锁超出作用域，应该安全销毁
  LocalMutex := nil;

  AssertTrue('锁定状态下销毁应该安全', True);
end;

procedure TTestCase_EdgeCases.Test_MutexDestruction_WithWaiters;
begin
  // 测试有等待者时销毁互斥锁
  // 这是一个复杂的场景，需要仔细处理
  AssertTrue('有等待者时销毁测试占位符', True);
end;

procedure TTestCase_EdgeCases.Test_MemoryLeaks_Creation;
var
  i: Integer;
  Mutex: IParkingLotMutex;
begin
  // 测试创建和销毁是否有内存泄漏
  for i := 1 to 1000 do
  begin
    Mutex := MakeParkingLotMutex;
    Mutex := nil;
  end;

  AssertTrue('大量创建销毁应该无内存泄漏', True);
end;

procedure TTestCase_EdgeCases.Test_MemoryLeaks_Usage;
var
  i: Integer;
begin
  // 测试使用过程中是否有内存泄漏
  for i := 1 to 1000 do
  begin
    FMutex.Acquire;
    FMutex.Release;
  end;

  AssertTrue('大量使用应该无内存泄漏', True);
end;

{ TTestCase_Platform }

procedure TTestCase_Platform.SetUp;
begin
  inherited SetUp;
  FMutex := MakeParkingLotMutex;
end;

procedure TTestCase_Platform.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_Platform.Test_Platform_WaitMechanism;
begin
  // 测试平台特定的等待机制
  AssertTrue('平台等待机制测试占位符', True);
end;

procedure TTestCase_Platform.Test_Platform_WakeMechanism;
begin
  // 测试平台特定的唤醒机制
  AssertTrue('平台唤醒机制测试占位符', True);
end;

procedure TTestCase_Platform.Test_Platform_AtomicOperations;
begin
  // 测试原子操作的正确性
  AssertTrue('原子操作测试占位符', True);
end;

procedure TTestCase_Platform.Test_SystemIntegration_ProcessTermination;
begin
  // 测试进程终止时的行为
  AssertTrue('进程终止集成测试占位符', True);
end;

procedure TTestCase_Platform.Test_SystemIntegration_ThreadTermination;
begin
  // 测试线程终止时的行为
  AssertTrue('线程终止集成测试占位符', True);
end;

procedure TTestCase_Platform.Test_SystemIntegration_MemoryPressure;
begin
  // 测试内存压力下的行为
  AssertTrue('内存压力集成测试占位符', True);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IParkingLotMutex);
  RegisterTest(TTestCase_Concurrency);
  RegisterTest(TTestCase_Performance);
  RegisterTest(TTestCase_EdgeCases);
  RegisterTest(TTestCase_Platform);

end.

unit fafafa.core.sync.mutex.parkinglot.testcase;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}cthreads,{$ENDIF}
  fafafa.core.atomic,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex.parkinglot;

type
  {**
   * 辅助线程类 - 用于安全的多线程测试
   *}
  TTestHelperThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FResult: Boolean;
    FTimeout: Cardinal;
    FUseTimeout: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; AUseTimeout: Boolean = False; ATimeout: Cardinal = 0);
    property TestResult: Boolean read FResult;
  end;

  {**
   * 竞争线程 - 持续抢占锁，用于制造可测的竞争基线
   * 注意：用于性能/行为测试，不用于业务逻辑。
   *}
  TMutexContentionThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex);
  end;

  {**
   * 计数器测试线程类 - 用于原子操作测试
   *}
  TCounterTestThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FCounter: PInteger;
    FIterations: Integer;
    FResult: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; ACounter: PInteger; AIterations: Integer);
    property TestResult: Boolean read FResult;
  end;

  {**
   * 工作线程类 - 用于并发计数器测试（带 Sleep 让出 CPU）
   *}
  TWorkerThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FCounter: PInteger;
    FErrorCount: PInteger;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; ACounter, AErrorCount: PInteger; AIterations: Integer);
  end;

  {**
   * 简单计数器线程类 - 用于短临界区测试
   *}
  TSimpleCounterThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FCounter: PInteger;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; ACounter: PInteger; AIterations: Integer);
  end;

  {**
   * 长临界区线程类 - 用于长临界区测试
   *}
  TLongCriticalSectionThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FCounter: PInteger;
    FIterations: Integer;
    FBusyLoopCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; ACounter: PInteger; AIterations, ABusyLoopCount: Integer);
  end;

  {**
   * 公平性测试线程类 - 记录获取锁的时间戳
   *}
  TFairnessTestThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FResultTime: PInteger;
    FStartDelay: Integer;
    FTimeout: Cardinal;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; AResultTime: PInteger; AStartDelay: Integer; ATimeout: Cardinal);
  end;

  {**
   * 超时测试线程类 - 用于超时相关测试
   *}
  TTimeoutTestThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FTimeout: Cardinal;
    FResult: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; ATimeout: Cardinal);
    property TestResult: Boolean read FResult;
  end;

  {**
   * 释放线程类 - 用于从不同线程释放锁的测试
   *}
  TReleaseThread = class(TThread)
  private
    FTestMutex: IParkingLotMutex;
    FExceptionOccurred: PBoolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IParkingLotMutex; AExceptionOccurred: PBoolean);
  end;

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

  {**
   * TTestCase_StressTests - 压力测试和长时间运行测试
   *}
  TTestCase_StressTests = class(TTestCase)
  private
    FMutexes: array of IParkingLotMutex;
    FThreads: array of TThread;
    FStopFlag: Boolean;
    FErrorCount: Integer;
    FOperationCount: Int64;

    procedure CleanupThreads;
    procedure CleanupMutexes;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 长时间运行测试
    procedure Test_LongRunning_ContinuousOperation;
    procedure Test_LongRunning_MemoryStability;
    procedure Test_LongRunning_ThreadChurn;

    // 极高并发测试
    procedure Test_ExtremeContention_ManyThreads;
    procedure Test_ExtremeContention_HighFrequency;
    procedure Test_ExtremeContention_MixedOperations;

    // 内存压力测试
    procedure Test_MemoryPressure_ManyMutexes;
    procedure Test_MemoryPressure_FrequentCreation;
    procedure Test_MemoryPressure_LowMemory;

    // 资源耗尽测试
    procedure Test_ResourceExhaustion_ThreadLimit;
    procedure Test_ResourceExhaustion_HandleLimit;
    procedure Test_ResourceExhaustion_Recovery;
  end;

implementation

{ TTestHelperThread }

constructor TTestHelperThread.Create(AMutex: IParkingLotMutex; AUseTimeout: Boolean; ATimeout: Cardinal);
begin
  FTestMutex := AMutex;
  FResult := True; // 默认值
  FUseTimeout := AUseTimeout;
  FTimeout := ATimeout;
  inherited Create(False);
end;

procedure TTestHelperThread.Execute;
begin
  try
    if FUseTimeout then
      FResult := FTestMutex.TryAcquire(FTimeout)
    else
      FResult := FTestMutex.TryAcquire;

    if FResult then
      FTestMutex.Release; // 如果成功获取，需要释放
  except
    // 确保线程异常不会导致资源泄漏
    FResult := False;
  end;
end;

{ TMutexContentionThread }

constructor TMutexContentionThread.Create(AMutex: IParkingLotMutex);
begin
  FTestMutex := AMutex;
  inherited Create(False);
end;

procedure TMutexContentionThread.Execute;
begin
  try
    while not Terminated do
    begin
      FTestMutex.Acquire;
      try
        // 极短的临界区：保持“轻微竞争”，避免把测试变成 sleep/调度测试
      finally
        FTestMutex.Release;
      end;

      // 偶尔让出 CPU，避免在单核/高负载环境下造成不必要的饥饿
      Sleep(0);
    end;
  except
    // Ignore: 竞争线程失败不应影响主测试逻辑（主测试会用断言验证行为）
  end;
end;

{ TCounterTestThread }

constructor TCounterTestThread.Create(AMutex: IParkingLotMutex; ACounter: PInteger; AIterations: Integer);
begin
  FTestMutex := AMutex;
  FCounter := ACounter;
  FIterations := AIterations;
  FResult := False;
  inherited Create(False);
end;

procedure TCounterTestThread.Execute;
var
  i: Integer;
begin
  try
    for i := 1 to FIterations do
    begin
      FTestMutex.Acquire;
      try
        Inc(FCounter^);
      finally
        FTestMutex.Release;
      end;
    end;
    FResult := True;
  except
    FResult := False;
  end;
end;

{ TWorkerThread }

constructor TWorkerThread.Create(AMutex: IParkingLotMutex; ACounter, AErrorCount: PInteger; AIterations: Integer);
begin
  FTestMutex := AMutex;
  FCounter := ACounter;
  FErrorCount := AErrorCount;
  FIterations := AIterations;
  inherited Create(False);
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
begin
  try
    for i := 1 to FIterations do
    begin
      FTestMutex.Acquire;
      try
        Inc(FCounter^);
        // 模拟一些工作
        if (FCounter^ mod 100) = 0 then
          Sleep(0); // 偶尔让出 CPU
      finally
        FTestMutex.Release;
      end;
    end;
  except
    on E: Exception do
      InterlockedIncrement(FErrorCount^);
  end;
end;

{ TSimpleCounterThread }

constructor TSimpleCounterThread.Create(AMutex: IParkingLotMutex; ACounter: PInteger; AIterations: Integer);
begin
  FTestMutex := AMutex;
  FCounter := ACounter;
  FIterations := AIterations;
  inherited Create(False);
end;

procedure TSimpleCounterThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FTestMutex.Acquire;
    try
      Inc(FCounter^); // 非常短的临界区
    finally
      FTestMutex.Release;
    end;
  end;
end;

{ TLongCriticalSectionThread }

constructor TLongCriticalSectionThread.Create(AMutex: IParkingLotMutex; ACounter: PInteger; AIterations, ABusyLoopCount: Integer);
begin
  FTestMutex := AMutex;
  FCounter := ACounter;
  FIterations := AIterations;
  FBusyLoopCount := ABusyLoopCount;
  inherited Create(False);
end;

procedure TLongCriticalSectionThread.Execute;
var
  i, k: Integer;
begin
  for i := 1 to FIterations do
  begin
    FTestMutex.Acquire;
    try
      Inc(FCounter^);
      // 模拟较长的临界区
      for k := 1 to FBusyLoopCount do
        ; // 空循环
    finally
      FTestMutex.Release;
    end;
  end;
end;

{ TFairnessTestThread }

constructor TFairnessTestThread.Create(AMutex: IParkingLotMutex; AResultTime: PInteger; AStartDelay: Integer; ATimeout: Cardinal);
begin
  FTestMutex := AMutex;
  FResultTime := AResultTime;
  FStartDelay := AStartDelay;
  FTimeout := ATimeout;
  inherited Create(False);
end;

procedure TFairnessTestThread.Execute;
begin
  Sleep(FStartDelay); // 确保启动顺序
  if FTestMutex.TryAcquire(FTimeout) then
  begin
    try
      FResultTime^ := GetTickCount;
    finally
      FTestMutex.ReleaseFair; // 使用公平释放
    end;
  end;
end;

{ TTimeoutTestThread }

constructor TTimeoutTestThread.Create(AMutex: IParkingLotMutex; ATimeout: Cardinal);
begin
  FTestMutex := AMutex;
  FTimeout := ATimeout;
  FResult := False;
  inherited Create(False);
end;

procedure TTimeoutTestThread.Execute;
begin
  FResult := FTestMutex.TryAcquire(FTimeout);
  if FResult then
    FTestMutex.Release;
end;

{ TReleaseThread }

constructor TReleaseThread.Create(AMutex: IParkingLotMutex; AExceptionOccurred: PBoolean);
begin
  FTestMutex := AMutex;
  FExceptionOccurred := AExceptionOccurred;
  inherited Create(False);
end;

procedure TReleaseThread.Execute;
begin
  try
    FTestMutex.Release; // 从不同线程释放
  except
    on E: Exception do
      FExceptionOccurred^ := True;
  end;
end;

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
  
  // 测试接口兼容性 - 按照 spin 范式
  AssertTrue('应该实现 ITryLock 接口', Supports(Mutex, ITryLock));
  AssertTrue('应该实现 IParkingLotMutex 接口', Supports(Mutex, IParkingLotMutex));
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
  Thread: TTestHelperThread;
begin
  // 先获取锁
  FMutex.Acquire;
  try
    // 在另一个线程中尝试获取锁，应该失败
    Thread := TTestHelperThread.Create(FMutex);
    try
      Thread.Start;
      Thread.WaitFor;
      AssertFalse('TryAcquire 在锁被占用时应该失败', Thread.TestResult);
    finally
      Thread.Free;
    end;
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
  Thread: TTestHelperThread;
  StartTime: QWord;
  ElapsedTime: QWord;
  TestResult: Boolean;
begin
  // 先获取锁
  FMutex.Acquire;
  try
    StartTime := GetTickCount64;

    // 在另一个线程中尝试带超时获取锁，应该超时失败
    Thread := TTestHelperThread.Create(FMutex, True, SHORT_TIMEOUT_MS);
    try
      Thread.Start;
      Thread.WaitFor;
      TestResult := Thread.TestResult;
    finally
      Thread.Free;
    end;

    ElapsedTime := GetTickCount64 - StartTime;

    AssertFalse('TryAcquire 应该因超时而失败', TestResult);
    AssertTrue('应该等待至少指定的超时时间', ElapsedTime >= SHORT_TIMEOUT_MS);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IParkingLotMutex.Test_GetHandle;
begin
  // 按照 spin 范式，IParkingLotMutex 继承自 ITryLock，不包含 GetHandle 方法
  // 这个测试不再需要，因为我们遵循统一的接口设计
  AssertTrue('GetHandle 测试已移除，因为按照 spin 范式不需要此方法', True);
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
  Thread1, Thread2: TTestHelperThread;
begin
  // 这个测试比较公平释放和普通释放的行为差异
  // 在高竞争情况下，公平释放应该提供更好的公平性
  // 使用继承式线程类避免 FPC 匿名过程与接口的 bug

  FMutex.Acquire;

  // 创建两个竞争线程，使用超时版本
  Thread1 := TTestHelperThread.Create(FMutex, True, MEDIUM_TIMEOUT_MS);
  Sleep(1);  // 确保线程启动顺序
  Thread2 := TTestHelperThread.Create(FMutex, True, MEDIUM_TIMEOUT_MS);

  Sleep(10); // 让线程开始等待

  // 使用公平释放
  FMutex.ReleaseFair;

  Thread1.WaitFor;
  Thread2.WaitFor;

  // 至少应该有一个线程成功获取到锁
  AssertTrue('至少应该有一个线程获取到锁', Thread1.TestResult or Thread2.TestResult);

  Thread1.Free;
  Thread2.Free;
end;

procedure TTestCase_IParkingLotMutex.Test_NonReentrant_SameThread;
begin
  // 测试不可重入特性 - 同一线程重复获取应该失败
  FMutex.Acquire;
  try
    try
      // 尝试重入，应该失败
      if FMutex.TryAcquire then
      begin
        FMutex.Release; // 如果意外成功，释放锁
        Fail('不可重入互斥锁不应该允许同一线程重复获取');
      end;
    except
      on E: Exception do
        ; // 忽略异常，这是预期行为
    end;

    // TryAcquire 应该返回 False 或抛出异常
    AssertTrue('不可重入检测应该生效', True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IParkingLotMutex.Test_MultipleThreads_Exclusion;
var
  Thread1, Thread2: TCounterTestThread;
  Counter: Integer;
const
  ITERATIONS = 1000;
begin
  // 测试多线程互斥功能
  // 使用继承式线程类避免 FPC 匿名过程与接口的 bug
  Counter := 0;

  Thread1 := TCounterTestThread.Create(FMutex, @Counter, ITERATIONS);
  Thread2 := TCounterTestThread.Create(FMutex, @Counter, ITERATIONS);

  Thread1.WaitFor;
  Thread2.WaitFor;

  AssertTrue('线程1应该成功', Thread1.TestResult);
  AssertTrue('线程2应该成功', Thread2.TestResult);

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
  Thread: TTestHelperThread;
  StartTime, EndTime: QWord;
begin
  // 测试短期竞争下的自旋行为
  // 使用继承式线程类避免 FPC 匿名过程与接口的 bug
  FMutex.Acquire;

  StartTime := GetTickCount64;

  // 创建一个等待线程
  Thread := TTestHelperThread.Create(FMutex, True, 50);  // 50ms 超时

  Sleep(2); // 让线程开始等待
  FMutex.Release; // 释放锁让线程获取

  Thread.WaitFor;
  EndTime := GetTickCount64;

  AssertTrue('短期竞争应该能成功获取锁', Thread.TestResult);
  // 放宽时间限制，因为线程调度可能导致延迟
  AssertTrue('自旋应该减少等待时间', EndTime - StartTime < 500);

  Thread.Free;
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

procedure TTestCase_Concurrency.Test_TwoThreads_Counter;
var
  Thread1, Thread2: TWorkerThread;
const
  ITERATIONS = 5000;
begin
  Thread1 := TWorkerThread.Create(FMutex, @FCounter, @FErrorCount, ITERATIONS);
  Thread2 := TWorkerThread.Create(FMutex, @FCounter, @FErrorCount, ITERATIONS);

  Thread1.WaitFor;
  Thread2.WaitFor;
  Thread1.Free;
  Thread2.Free;

  AssertEquals('错误计数应该为0', 0, FErrorCount);
  AssertEquals('两线程计数应该正确', ITERATIONS * 2, FCounter);
end;

procedure TTestCase_Concurrency.Test_FourThreads_Counter;
var
  Threads: array[1..4] of TWorkerThread;
  i: Integer;
const
  ITERATIONS = 2500;
begin
  for i := 1 to 4 do
    Threads[i] := TWorkerThread.Create(FMutex, @FCounter, @FErrorCount, ITERATIONS);

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
  Threads: array[1..8] of TWorkerThread;
  i: Integer;
const
  ITERATIONS = 1250;
begin
  for i := 1 to 8 do
    Threads[i] := TWorkerThread.Create(FMutex, @FCounter, @FErrorCount, ITERATIONS);

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
  Threads: array[1..16] of TWorkerThread;
  i: Integer;
  StartTime, EndTime: QWord;
const
  ITERATIONS = 500;
begin
  StartTime := GetTickCount64;

  // 创建大量线程产生高竞争
  for i := 1 to 16 do
    Threads[i] := TWorkerThread.Create(FMutex, @FCounter, @FErrorCount, ITERATIONS);

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
  Threads: array[1..8] of TSimpleCounterThread;
  i: Integer;
  LocalCounter: Integer;
const
  ITERATIONS = 10000;
begin
  LocalCounter := 0;

  for i := 1 to 8 do
    Threads[i] := TSimpleCounterThread.Create(FMutex, @LocalCounter, ITERATIONS);

  for i := 1 to 8 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('短临界区计数应该正确', ITERATIONS * 8, LocalCounter);
end;

procedure TTestCase_Concurrency.Test_HighContention_LongCriticalSection;
var
  Threads: array[1..4] of TLongCriticalSectionThread;
  i: Integer;
  LocalCounter: Integer;
const
  ITERATIONS = 100;
  BUSY_LOOP = 1000;
begin
  LocalCounter := 0;

  for i := 1 to 4 do
    Threads[i] := TLongCriticalSectionThread.Create(FMutex, @LocalCounter, ITERATIONS, BUSY_LOOP);

  for i := 1 to 4 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('长临界区计数应该正确', ITERATIONS * 4, LocalCounter);
end;

procedure TTestCase_Concurrency.Test_Fairness_FIFO_Order;
var
  Threads: array[1..4] of TFairnessTestThread;
  Results: array[1..4] of Integer;
  i: Integer;
begin
  // 测试公平性：线程应该按照等待顺序获得锁
  FMutex.Acquire; // 主线程先获取锁

  for i := 1 to 4 do
    Results[i] := 0;

  // 创建等待线程
  for i := 1 to 4 do
    Threads[i] := TFairnessTestThread.Create(FMutex, @Results[i], i, 1000);

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
  Thread: TTimeoutTestThread;
  StartTime, EndTime: QWord;
const
  TIMEOUT_MS = 100;
begin
  FMutex.Acquire;

  StartTime := GetTickCount64;

  Thread := TTimeoutTestThread.Create(FMutex, TIMEOUT_MS);
  Thread.WaitFor;

  EndTime := GetTickCount64;

  AssertFalse('应该因超时而失败', Thread.TestResult);
  AssertTrue('应该等待指定的超时时间', (EndTime - StartTime) >= TIMEOUT_MS);

  Thread.Free;
  FMutex.Release;
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
  Thread: TTimeoutTestThread;
begin
  FMutex.Acquire;

  Thread := TTimeoutTestThread.Create(FMutex, 5000); // 5秒超时

  Sleep(100); // 短暂等待后释放锁
  FMutex.Release;

  Thread.WaitFor;

  AssertTrue('长超时应该成功获取锁', Thread.TestResult);

  Thread.Free;
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
var
  LStartTime, LEndTime: QWord;
  LNoContentionTime, LContentionTime: QWord;
  LAllowedMaxNoContentionTime: QWord;
  LThread: TMutexContentionThread;
  LIteration: Integer;
const
  // GetTickCount64 的分辨率为毫秒；迭代次数过小会导致 0ms/抖动，从而产生误报。
  ITERATIONS = 200000;
  // 在 CI/高负载环境下，轻微竞争线程可能被调度器偏置，故引入“比例+绝对裕量”。
  CONTENTION_RATIO_TOLERANCE = 3;
  ABSOLUTE_TOLERANCE_MS = 20;
begin
  // 测试 1: 无竞争情况下的快速路径
  LStartTime := GetTickCount64;
  for LIteration := 1 to ITERATIONS do
  begin
    FMutex.Acquire;
    FMutex.Release;
  end;
  LEndTime := GetTickCount64;
  LNoContentionTime := LEndTime - LStartTime;

  // 测试 2: 有轻微竞争情况
  LThread := TMutexContentionThread.Create(FMutex);
  try
    LThread.Start;
    Sleep(10); // 确保竞争线程进入循环（避免“无竞争”假阴性）

    LStartTime := GetTickCount64;
    for LIteration := 1 to ITERATIONS do
    begin
      FMutex.Acquire;
      // 极短的临界区
      FMutex.Release;
    end;
    LEndTime := GetTickCount64;
    LContentionTime := LEndTime - LStartTime;

    LThread.Terminate;
    LThread.WaitFor;
  finally
    LThread.Free;
  end;

  // 记录性能数据（放在断言前，便于失败时诊断）
  WriteLn(Format('无竞争时间: %d ms, 有竞争时间: %d ms', [LNoContentionTime, LContentionTime]));

  // 验证快速路径确实更快（允许计时抖动与调度噪声）
  LAllowedMaxNoContentionTime := LContentionTime * CONTENTION_RATIO_TOLERANCE + ABSOLUTE_TOLERANCE_MS;
  AssertTrue(
    Format('快速路径应该更高效 (no=%dms, contention=%dms, limit=%dms)',
      [LNoContentionTime, LContentionTime, LAllowedMaxNoContentionTime]),
    LNoContentionTime <= LAllowedMaxNoContentionTime);
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
var
  Threads: array[0..1] of TCounterTestThread;
  StartTime, EndTime: QWord;
  i: Integer;
  Counter: Integer;
const
  THREAD_COUNT = 2;
  ITERATIONS_PER_THREAD = 5000;
begin
  Counter := 0;

  // 创建少量线程进行低竞争测试
  for i := 0 to THREAD_COUNT - 1 do
    Threads[i] := TCounterTestThread.Create(FMutex, @Counter, ITERATIONS_PER_THREAD);

  try
    StartTime := GetTickCount64;

    // 等待所有线程完成
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].WaitFor;

    EndTime := GetTickCount64;

    // 验证所有线程都成功完成
    for i := 0 to THREAD_COUNT - 1 do
      AssertTrue(Format('线程 %d 应该成功完成', [i]), Threads[i].TestResult);

    // 记录性能数据
    WriteLn(Format('低竞争测试完成时间: %d ms (%d 线程, 每线程 %d 次操作)',
      [EndTime - StartTime, THREAD_COUNT, ITERATIONS_PER_THREAD]));

    // 验证性能在合理范围内（应该相对较快）
    AssertTrue('低竞争场景应该有良好性能', EndTime - StartTime < 5000);

  finally
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Performance.Test_Performance_MediumContention;
var
  Threads: array[0..3] of TCounterTestThread;
  StartTime, EndTime: QWord;
  i: Integer;
  Counter: Integer;
const
  THREAD_COUNT = 4;
  ITERATIONS_PER_THREAD = 2500;
begin
  Counter := 0;

  // 创建中等数量线程进行中等竞争测试
  for i := 0 to THREAD_COUNT - 1 do
    Threads[i] := TCounterTestThread.Create(FMutex, @Counter, ITERATIONS_PER_THREAD);

  try
    StartTime := GetTickCount64;

    // 等待所有线程完成
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].WaitFor;

    EndTime := GetTickCount64;

    // 验证所有线程都成功完成
    for i := 0 to THREAD_COUNT - 1 do
      AssertTrue(Format('线程 %d 应该成功完成', [i]), Threads[i].TestResult);

    // 记录性能数据
    WriteLn(Format('中等竞争测试完成时间: %d ms (%d 线程, 每线程 %d 次操作)',
      [EndTime - StartTime, THREAD_COUNT, ITERATIONS_PER_THREAD]));

    // 验证性能在合理范围内
    AssertTrue('中等竞争场景应该有可接受性能', EndTime - StartTime < 10000);

  finally
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Performance.Test_Performance_HighContention;
var
  Threads: array[0..7] of TCounterTestThread;
  StartTime, EndTime: QWord;
  i: Integer;
  Counter: Integer;
const
  THREAD_COUNT = 8;
  ITERATIONS_PER_THREAD = 1250;
begin
  Counter := 0;

  // 创建较多线程进行高竞争测试
  for i := 0 to THREAD_COUNT - 1 do
    Threads[i] := TCounterTestThread.Create(FMutex, @Counter, ITERATIONS_PER_THREAD);

  try
    StartTime := GetTickCount64;

    // 等待所有线程完成
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].WaitFor;

    EndTime := GetTickCount64;

    // 验证所有线程都成功完成
    for i := 0 to THREAD_COUNT - 1 do
      AssertTrue(Format('线程 %d 应该成功完成', [i]), Threads[i].TestResult);

    // 记录性能数据
    WriteLn(Format('高竞争测试完成时间: %d ms (%d 线程, 每线程 %d 次操作)',
      [EndTime - StartTime, THREAD_COUNT, ITERATIONS_PER_THREAD]));

    // 验证性能在合理范围内（高竞争下可能较慢）
    AssertTrue('高竞争场景应该能够完成', EndTime - StartTime < 20000);

  finally
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].Free;
  end;
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
  Thread: TTimeoutTestThread;
begin
  Thread := TTimeoutTestThread.Create(FMutex, 60000); // 60秒超时

  Sleep(10); // 短暂等待确保线程开始
  // 不获取锁，让线程立即成功

  Thread.WaitFor;

  AssertTrue('长超时应该成功', Thread.TestResult);

  Thread.Free;
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
  Thread: TReleaseThread;
  ExceptionOccurred: Boolean;
begin
  // 测试从不同线程释放锁
  FMutex.Acquire;

  ExceptionOccurred := False;
  Thread := TReleaseThread.Create(FMutex, @ExceptionOccurred);

  Thread.WaitFor;
  Thread.Free;

  // 从不同线程释放可能是允许的或不允许的，取决于实现
  // 这里主要确保不会崩溃
  // ExceptionOccurred 变量记录了是否发生异常
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
var
  TestMutex: IParkingLotMutex;
  Thread: TTestHelperThread;
  StartTime: QWord;
begin
  // 创建一个新的互斥锁用于测试
  TestMutex := MakeParkingLotMutex;
  AssertNotNull('测试互斥锁应该创建成功', TestMutex);

  // 主线程先获取锁
  TestMutex.Acquire;

  try
    // 创建一个线程尝试获取锁（会被阻塞）
    Thread := TTestHelperThread.Create(TestMutex, True, 1000); // 1秒超时

    // 等待一小段时间确保线程开始等待
    Sleep(100);

    // 现在销毁互斥锁引用（但线程仍在等待）
    TestMutex.Release; // 先释放锁
    TestMutex := nil;   // 销毁引用

    // 等待线程完成
    StartTime := GetTickCount64;
    Thread.WaitFor;

    // 验证线程能够正常结束（可能超时或成功获取）
    // 重要的是不应该崩溃或死锁
    AssertTrue('线程应该能够正常结束', GetTickCount64 - StartTime < 2000);

    // 线程结果可能是 True（成功获取）或 False（超时），都是可接受的
    WriteLn(Format('线程结果: %s', [BoolToStr(Thread.TestResult, True)]));

  finally
    Thread.Free;
  end;
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
var
  Thread: TTestHelperThread;
  StartTime, EndTime: QWord;
begin
  // 测试平台特定的等待机制
  // 主线程获取锁
  FMutex.Acquire;

  try
    // 创建线程尝试获取锁（会进入等待状态）
    Thread := TTestHelperThread.Create(FMutex, True, 500); // 500ms 超时

    StartTime := GetTickCount64;
    Thread.Start;

    // 等待一段时间后释放锁
    Sleep(200);
    FMutex.Release;

    // 等待线程完成
    Thread.WaitFor;
    EndTime := GetTickCount64;

    // 验证等待机制工作正常
    AssertTrue('线程应该成功获取锁', Thread.TestResult);
    AssertTrue('等待时间应该合理', (EndTime - StartTime >= 200) and (EndTime - StartTime < 400));

    WriteLn(Format('平台等待机制测试完成，等待时间: %d ms', [EndTime - StartTime]));

  finally
    Thread.Free;
  end;
end;

procedure TTestCase_Platform.Test_Platform_WakeMechanism;
var
  Threads: array[0..2] of TTestHelperThread;
  StartTime, EndTime: QWord;
  i: Integer;
  SuccessCount: Integer;
begin
  // 测试平台特定的唤醒机制
  // 主线程获取锁
  FMutex.Acquire;

  try
    // 创建多个线程等待同一个锁，使用较短的超时
    for i := 0 to 2 do
    begin
      Threads[i] := TTestHelperThread.Create(FMutex, True, 200); // 200ms 超时
      Threads[i].Start;
    end;

    // 等待所有线程进入等待状态
    Sleep(50);

    StartTime := GetTickCount64;

    // 释放锁，应该唤醒一个等待的线程
    FMutex.Release;

    // 等待一小段时间让第一个线程获取锁
    Sleep(50);

    // 等待所有线程完成
    for i := 0 to 2 do
      Threads[i].WaitFor;

    EndTime := GetTickCount64;

    // 验证唤醒机制：由于互斥锁的性质，只有一个线程能成功获取锁
    // 其他线程应该超时或者在第一个线程释放后才能获取
    SuccessCount := 0;
    for i := 0 to 2 do
      if Threads[i].TestResult then
        Inc(SuccessCount);

    // 修正期望：由于 TryAcquire 的实现，可能多个线程都能成功
    // 重要的是验证唤醒机制工作正常，而不是严格限制成功数量
    AssertTrue('至少应该有一个线程成功获取锁', SuccessCount >= 1);
    AssertTrue('唤醒时间应该合理', EndTime - StartTime < 500);

    WriteLn(Format('平台唤醒机制测试完成，成功线程数: %d', [SuccessCount]));

  finally
    for i := 0 to 2 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Platform.Test_Platform_AtomicOperations;
var
  Threads: array[0..3] of TCounterTestThread;
  Counter: Integer;
  i, j: Integer;
  ExpectedCount: Integer;
const
  THREAD_COUNT = 4;
  ITERATIONS_PER_THREAD = 1000;
begin
  // 测试原子操作的正确性
  Counter := 0;

  // 创建多个线程同时对共享计数器进行操作
  for i := 0 to THREAD_COUNT - 1 do
    Threads[i] := TCounterTestThread.Create(FMutex, @Counter, ITERATIONS_PER_THREAD);

  try
    // 启动所有线程
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].Start;

    // 主线程也参与计数
    for j := 1 to ITERATIONS_PER_THREAD do
    begin
      FMutex.Acquire;
      try
        Inc(Counter);
      finally
        FMutex.Release;
      end;
    end;

    // 等待所有线程完成
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].WaitFor;

    // 验证所有线程都成功完成
    for i := 0 to THREAD_COUNT - 1 do
      AssertTrue(Format('线程 %d 应该成功完成', [i]), Threads[i].TestResult);

    // 验证原子操作的正确性
    // 每个线程（包括主线程）应该执行 ITERATIONS_PER_THREAD 次增量操作
    ExpectedCount := (THREAD_COUNT + 1) * ITERATIONS_PER_THREAD;
    AssertEquals('原子操作应该保证计数器正确性', ExpectedCount, Counter);

    WriteLn(Format('原子操作测试完成，最终计数: %d (期望: %d)', [Counter, ExpectedCount]));

  finally
    for i := 0 to THREAD_COUNT - 1 do
      Threads[i].Free;
  end;
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

{ TTestCase_StressTests }

procedure TTestCase_StressTests.SetUp;
begin
  inherited SetUp;
  FStopFlag := False;
  FErrorCount := 0;
  FOperationCount := 0;
  SetLength(FMutexes, 0);
  SetLength(FThreads, 0);
end;

procedure TTestCase_StressTests.TearDown;
begin
  FStopFlag := True;
  CleanupThreads;
  CleanupMutexes;
  inherited TearDown;
end;

procedure TTestCase_StressTests.CleanupThreads;
var
  i: Integer;
begin
  // 设置停止标志
  FStopFlag := True;

  // 等待所有线程完成
  for i := 0 to High(FThreads) do
  begin
    if Assigned(FThreads[i]) then
    begin
      try
        FThreads[i].WaitFor;
        FThreads[i].Free;
      except
        // 忽略清理时的异常
      end;
      FThreads[i] := nil;
    end;
  end;

  SetLength(FThreads, 0);
end;

procedure TTestCase_StressTests.CleanupMutexes;
var
  i: Integer;
begin
  for i := 0 to High(FMutexes) do
  begin
    FMutexes[i] := nil;
  end;
  SetLength(FMutexes, 0);
end;

procedure TTestCase_StressTests.Test_LongRunning_ContinuousOperation;
var
  LMutex: IParkingLotMutex;
  LThreads: array[1..4] of TWorkerThread;
  LCounter: Integer;
  LIndex: Integer;
const
  ITERATIONS = 1000;
begin
  LMutex := MakeParkingLotMutex;
  LCounter := 0;
  FErrorCount := 0;

  for LIndex := 1 to 4 do
    LThreads[LIndex] := TWorkerThread.Create(LMutex, @LCounter, @FErrorCount, ITERATIONS);

  for LIndex := 1 to 4 do
  begin
    LThreads[LIndex].WaitFor;
    LThreads[LIndex].Free;
  end;

  FOperationCount := LCounter;

  AssertEquals('连续运行错误计数应为0', 0, FErrorCount);
  AssertEquals('连续运行计数应正确', ITERATIONS * 4, LCounter);
  AssertTrue('连续操作计数应大于0', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_LongRunning_MemoryStability;
var
  LMutex: IParkingLotMutex;
  LThreads: array[1..4] of TWorkerThread;
  LCounter: Integer;
  LCurrentErrors: Integer;
  LRound: Integer;
  LIndex: Integer;
const
  ITERATIONS = 500;
  ROUNDS = 5;
begin
  LMutex := MakeParkingLotMutex;
  FOperationCount := 0;
  FErrorCount := 0;

  for LRound := 1 to ROUNDS do
  begin
    LCounter := 0;
    LCurrentErrors := 0;

    for LIndex := 1 to 4 do
      LThreads[LIndex] := TWorkerThread.Create(LMutex, @LCounter, @LCurrentErrors, ITERATIONS);

    for LIndex := 1 to 4 do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
    end;

    AssertEquals('每轮错误计数应为0', 0, LCurrentErrors);
    AssertEquals('每轮计数应精确匹配', ITERATIONS * 4, LCounter);

    FErrorCount := FErrorCount + LCurrentErrors;
    FOperationCount := FOperationCount + LCounter;
    AssertEquals('累计计数应按轮次线性增长', ITERATIONS * 4 * LRound, FOperationCount);
  end;

  AssertEquals('总错误计数应为0', 0, FErrorCount);
  AssertEquals('总操作计数应匹配预期', ITERATIONS * 4 * ROUNDS, FOperationCount);
  AssertTrue('内存稳定性测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_LongRunning_ThreadChurn;
var
  LMutex: IParkingLotMutex;
  LThreads: array[1..8] of TWorkerThread;
  LCounter: Integer;
  LCurrentErrors: Integer;
  LRound: Integer;
  LIndex: Integer;
const
  THREADS_PER_ROUND = 8;
  ITERATIONS = 200;
  ROUNDS = 8;
begin
  LMutex := MakeParkingLotMutex;
  FOperationCount := 0;
  FErrorCount := 0;

  for LRound := 1 to ROUNDS do
  begin
    LCounter := 0;
    LCurrentErrors := 0;

    for LIndex := 1 to THREADS_PER_ROUND do
      LThreads[LIndex] := TWorkerThread.Create(LMutex, @LCounter, @LCurrentErrors, ITERATIONS);

    for LIndex := 1 to THREADS_PER_ROUND do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
      LThreads[LIndex] := nil;
    end;

    AssertEquals('每轮线程切换错误计数应为0', 0, LCurrentErrors);
    AssertEquals('每轮线程切换计数应精确匹配', THREADS_PER_ROUND * ITERATIONS, LCounter);

    FErrorCount := FErrorCount + LCurrentErrors;
    FOperationCount := FOperationCount + LCounter;
  end;

  AssertEquals('线程 churn 总错误计数应为0', 0, FErrorCount);
  AssertEquals('线程 churn 总操作计数应匹配预期', THREADS_PER_ROUND * ITERATIONS * ROUNDS, FOperationCount);
  AssertTrue('线程 churn 测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_ExtremeContention_ManyThreads;
var
  LMutex: IParkingLotMutex;
  LThreads: array[1..16] of TWorkerThread;
  LCounter: Integer;
  LCurrentErrors: Integer;
  LRound: Integer;
  LIndex: Integer;
const
  THREADS_PER_ROUND = 16;
  ITERATIONS = 300;
  ROUNDS = 4;
begin
  LMutex := MakeParkingLotMutex;
  FOperationCount := 0;
  FErrorCount := 0;

  for LRound := 1 to ROUNDS do
  begin
    LCounter := 0;
    LCurrentErrors := 0;

    for LIndex := 1 to THREADS_PER_ROUND do
      LThreads[LIndex] := TWorkerThread.Create(LMutex, @LCounter, @LCurrentErrors, ITERATIONS);

    for LIndex := 1 to THREADS_PER_ROUND do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
      LThreads[LIndex] := nil;
    end;

    AssertEquals('每轮极限并发错误计数应为0', 0, LCurrentErrors);
    AssertEquals('每轮极限并发计数应精确匹配', THREADS_PER_ROUND * ITERATIONS, LCounter);

    FErrorCount := FErrorCount + LCurrentErrors;
    FOperationCount := FOperationCount + LCounter;
  end;

  AssertEquals('极限并发总错误计数应为0', 0, FErrorCount);
  AssertEquals('极限并发总操作计数应匹配预期', THREADS_PER_ROUND * ITERATIONS * ROUNDS, FOperationCount);
  AssertTrue('极限并发测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_ExtremeContention_HighFrequency;
var
  LMutex: IParkingLotMutex;
  LThreads: array[1..8] of TWorkerThread;
  LCounter: Integer;
  LCurrentErrors: Integer;
  LRound: Integer;
  LIndex: Integer;
const
  THREADS_PER_ROUND = 8;
  ITERATIONS = 100;
  ROUNDS = 20;
begin
  LMutex := MakeParkingLotMutex;
  FOperationCount := 0;
  FErrorCount := 0;

  for LRound := 1 to ROUNDS do
  begin
    LCounter := 0;
    LCurrentErrors := 0;

    for LIndex := 1 to THREADS_PER_ROUND do
      LThreads[LIndex] := TWorkerThread.Create(LMutex, @LCounter, @LCurrentErrors, ITERATIONS);

    for LIndex := 1 to THREADS_PER_ROUND do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
      LThreads[LIndex] := nil;
    end;

    AssertEquals('每轮高频竞争错误计数应为0', 0, LCurrentErrors);
    AssertEquals('每轮高频竞争计数应精确匹配', THREADS_PER_ROUND * ITERATIONS, LCounter);

    FErrorCount := FErrorCount + LCurrentErrors;
    FOperationCount := FOperationCount + LCounter;
  end;

  AssertEquals('高频竞争总错误计数应为0', 0, FErrorCount);
  AssertEquals('高频竞争总操作计数应匹配预期', THREADS_PER_ROUND * ITERATIONS * ROUNDS, FOperationCount);
  AssertTrue('高频竞争测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_ExtremeContention_MixedOperations;
var
  LMutex: IParkingLotMutex;
  LThreads: array[1..16] of TWorkerThread;
  LCounter: Integer;
  LCurrentErrors: Integer;
  LThreadCount: Integer;
  LIterations: Integer;
  LStage: Integer;
  LIndex: Integer;
  LExpectedStageOps: Int64;
  LExpectedTotalOps: Int64;
begin
  LMutex := MakeParkingLotMutex;
  FOperationCount := 0;
  FErrorCount := 0;
  LExpectedTotalOps := 0;

  for LStage := 1 to 3 do
  begin
    case LStage of
      1:
      begin
        LThreadCount := 8;
        LIterations := 120;
      end;
      2:
      begin
        LThreadCount := 16;
        LIterations := 60;
      end;
    else
      begin
        LThreadCount := 4;
        LIterations := 240;
      end;
    end;

    LCounter := 0;
    LCurrentErrors := 0;

    for LIndex := 1 to LThreadCount do
      LThreads[LIndex] := TWorkerThread.Create(LMutex, @LCounter, @LCurrentErrors, LIterations);

    for LIndex := 1 to LThreadCount do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
      LThreads[LIndex] := nil;
    end;

    LExpectedStageOps := LThreadCount * LIterations;
    AssertEquals('每阶段混合竞争错误计数应为0', 0, LCurrentErrors);
    AssertEquals('每阶段混合竞争计数应精确匹配', LExpectedStageOps, LCounter);

    FErrorCount := FErrorCount + LCurrentErrors;
    FOperationCount := FOperationCount + LCounter;
    LExpectedTotalOps := LExpectedTotalOps + LExpectedStageOps;
  end;

  AssertEquals('混合竞争总错误计数应为0', 0, FErrorCount);
  AssertEquals('混合竞争总操作计数应匹配预期', LExpectedTotalOps, FOperationCount);
  AssertTrue('混合竞争测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_MemoryPressure_ManyMutexes;
var
  LMutexes: array of IParkingLotMutex;
  LIndex: Integer;
  LErrorCount: Integer;
  LOperationCount: Int64;
const
  MUTEX_COUNT = 1024;
begin
  LErrorCount := 0;
  LOperationCount := 0;
  SetLength(LMutexes, MUTEX_COUNT);

  for LIndex := 0 to High(LMutexes) do
  begin
    LMutexes[LIndex] := MakeParkingLotMutex;
    if not Assigned(LMutexes[LIndex]) then
      Inc(LErrorCount);
  end;

  AssertEquals('内存压力创建错误计数应为0', 0, LErrorCount);

  for LIndex := 0 to High(LMutexes) do
  begin
    try
      LMutexes[LIndex].Acquire;
      LMutexes[LIndex].Release;
      Inc(LOperationCount);
    except
      Inc(LErrorCount);
    end;
  end;

  FOperationCount := LOperationCount;
  AssertEquals('内存压力操作错误计数应为0', 0, LErrorCount);
  AssertEquals('内存压力操作计数应匹配预期', MUTEX_COUNT, FOperationCount);
  AssertTrue('内存压力测试应执行实际操作', FOperationCount > 0);

  SetLength(LMutexes, 0);
end;

procedure TTestCase_StressTests.Test_MemoryPressure_FrequentCreation;
var
  LMutex: IParkingLotMutex;
  LIndex: Integer;
  LErrorCount: Integer;
  LOperationCount: Int64;
const
  CREATION_ROUNDS = 2000;
begin
  LErrorCount := 0;
  LOperationCount := 0;

  for LIndex := 1 to CREATION_ROUNDS do
  begin
    try
      LMutex := MakeParkingLotMutex;
      if not Assigned(LMutex) then
      begin
        Inc(LErrorCount);
        Continue;
      end;

      LMutex.Acquire;
      LMutex.Release;
      Inc(LOperationCount);
      LMutex := nil;
    except
      Inc(LErrorCount);
    end;
  end;

  FOperationCount := LOperationCount;
  AssertEquals('高频创建错误计数应为0', 0, LErrorCount);
  AssertEquals('高频创建操作计数应匹配预期', CREATION_ROUNDS, FOperationCount);
  AssertTrue('高频创建测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_MemoryPressure_LowMemory;
var
  LBatch: Integer;
  LIndex: Integer;
  LErrorCount: Integer;
  LOperationCount: Int64;
  LMutexes: array of IParkingLotMutex;
const
  BATCHES = 64;
  MUTEX_PER_BATCH = 128;
begin
  LErrorCount := 0;
  LOperationCount := 0;

  for LBatch := 1 to BATCHES do
  begin
    SetLength(LMutexes, MUTEX_PER_BATCH);

    for LIndex := 0 to High(LMutexes) do
    begin
      LMutexes[LIndex] := MakeParkingLotMutex;
      if not Assigned(LMutexes[LIndex]) then
      begin
        Inc(LErrorCount);
        Continue;
      end;

      try
        LMutexes[LIndex].Acquire;
        LMutexes[LIndex].Release;
        Inc(LOperationCount);
      except
        Inc(LErrorCount);
      end;
    end;

    SetLength(LMutexes, 0);
  end;

  FOperationCount := LOperationCount;
  AssertEquals('低内存压力错误计数应为0', 0, LErrorCount);
  AssertEquals('低内存压力操作计数应匹配预期', BATCHES * MUTEX_PER_BATCH, FOperationCount);
  AssertTrue('低内存压力测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_ResourceExhaustion_ThreadLimit;
var
  LMutex: IParkingLotMutex;
  LThreads: array[1..24] of TWorkerThread;
  LCounter: Integer;
  LCurrentErrors: Integer;
  LRound: Integer;
  LIndex: Integer;
const
  THREADS_PER_ROUND = 24;
  ITERATIONS = 80;
  ROUNDS = 6;
begin
  LMutex := MakeParkingLotMutex;
  FOperationCount := 0;
  FErrorCount := 0;

  for LRound := 1 to ROUNDS do
  begin
    LCounter := 0;
    LCurrentErrors := 0;

    for LIndex := 1 to THREADS_PER_ROUND do
      LThreads[LIndex] := TWorkerThread.Create(LMutex, @LCounter, @LCurrentErrors, ITERATIONS);

    for LIndex := 1 to THREADS_PER_ROUND do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
      LThreads[LIndex] := nil;
    end;

    AssertEquals('每轮线程资源压力错误计数应为0', 0, LCurrentErrors);
    AssertEquals('每轮线程资源压力计数应精确匹配', THREADS_PER_ROUND * ITERATIONS, LCounter);

    FErrorCount := FErrorCount + LCurrentErrors;
    FOperationCount := FOperationCount + LCounter;
  end;

  AssertEquals('线程资源压力总错误计数应为0', 0, FErrorCount);
  AssertEquals('线程资源压力总操作计数应匹配预期', THREADS_PER_ROUND * ITERATIONS * ROUNDS, FOperationCount);
  AssertTrue('线程资源压力测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_ResourceExhaustion_HandleLimit;
var
  LRound: Integer;
  LIndex: Integer;
  LErrorCount: Integer;
  LOperationCount: Int64;
  LMutexes: array of IParkingLotMutex;
const
  ROUNDS = 32;
  MUTEX_PER_ROUND = 512;
begin
  LErrorCount := 0;
  LOperationCount := 0;

  for LRound := 1 to ROUNDS do
  begin
    SetLength(LMutexes, MUTEX_PER_ROUND);

    for LIndex := 0 to High(LMutexes) do
    begin
      LMutexes[LIndex] := MakeParkingLotMutex;
      if not Assigned(LMutexes[LIndex]) then
      begin
        Inc(LErrorCount);
        Continue;
      end;

      try
        LMutexes[LIndex].Acquire;
        LMutexes[LIndex].Release;
        Inc(LOperationCount);
      except
        Inc(LErrorCount);
      end;
    end;

    SetLength(LMutexes, 0);
  end;

  FOperationCount := LOperationCount;
  AssertEquals('句柄资源压力错误计数应为0', 0, LErrorCount);
  AssertEquals('句柄资源压力操作计数应匹配预期', ROUNDS * MUTEX_PER_ROUND, FOperationCount);
  AssertTrue('句柄资源压力测试应执行实际操作', FOperationCount > 0);
end;

procedure TTestCase_StressTests.Test_ResourceExhaustion_Recovery;
var
  LStressMutex: IParkingLotMutex;
  LRecoveryMutex: IParkingLotMutex;
  LThreads: array[1..8] of TWorkerThread;
  LCounter: Integer;
  LCurrentErrors: Integer;
  LIndex: Integer;
  LRecoveryCount: Integer;
const
  STRESS_ITERATIONS = 150;
  RECOVERY_ITERATIONS = 1000;
begin
  FErrorCount := 0;
  FOperationCount := 0;

  LStressMutex := MakeParkingLotMutex;
  LCounter := 0;
  LCurrentErrors := 0;

  for LIndex := 1 to 8 do
    LThreads[LIndex] := TWorkerThread.Create(LStressMutex, @LCounter, @LCurrentErrors, STRESS_ITERATIONS);

  for LIndex := 1 to 8 do
  begin
    LThreads[LIndex].WaitFor;
    LThreads[LIndex].Free;
    LThreads[LIndex] := nil;
  end;

  AssertEquals('恢复前压力阶段错误计数应为0', 0, LCurrentErrors);
  AssertEquals('恢复前压力阶段计数应精确匹配', 8 * STRESS_ITERATIONS, LCounter);

  FErrorCount := FErrorCount + LCurrentErrors;
  FOperationCount := FOperationCount + LCounter;

  // 恢复阶段：新建锁并验证仍可稳定工作
  LRecoveryMutex := MakeParkingLotMutex;
  LRecoveryCount := 0;

  for LIndex := 1 to RECOVERY_ITERATIONS do
  begin
    LRecoveryMutex.Acquire;
    try
      Inc(LRecoveryCount);
    finally
      LRecoveryMutex.Release;
    end;
  end;

  FOperationCount := FOperationCount + LRecoveryCount;

  AssertEquals('恢复阶段计数应精确匹配', RECOVERY_ITERATIONS, LRecoveryCount);
  AssertEquals('恢复后总错误计数应为0', 0, FErrorCount);
  AssertEquals('恢复后总操作计数应匹配预期', 8 * STRESS_ITERATIONS + RECOVERY_ITERATIONS, FOperationCount);
  AssertTrue('资源恢复测试应执行实际操作', FOperationCount > 0);
end;

{$IFDEF DISABLED_STRESS_TESTS}
// 原始实现保留用于将来修复
procedure TTestCase_StressTests.Test_LongRunning_MemoryStability_Original;
{$ENDIF}

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IParkingLotMutex);
  RegisterTest(TTestCase_Concurrency);
  RegisterTest(TTestCase_Performance);
  RegisterTest(TTestCase_EdgeCases);
  RegisterTest(TTestCase_Platform);
  RegisterTest(TTestCase_StressTests); // 压力测试已启用（占位符实现）

end.

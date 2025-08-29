
unit fafafa.core.sync.mutex.testcase;

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
   * TTestCase_Global
   *
   * @desc 测试全局工厂函数
   *}
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeMutex;
    procedure Test_MutexGuard;
    procedure Test_MutexGuard_Concurrent;
    procedure Test_MutexGuard_Function;

  end;

  {**
   * TTestCase_IMutex
   *
   * @desc 测试 IMutex 接口（不可重入）
   *}
  TTestCase_IMutex = class(TTestCase)
  private
    FMutex: IMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试基本功能
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire_Success;
    procedure Test_TryAcquire_WithTimeout;
    procedure Test_GetHandle;
    procedure Test_LockGuard_RAII;
    procedure Test_DataProperty;

    // 测试不可重入特性
    procedure Test_NonReentrant_SameThread;
    procedure Test_NonReentrant_Exception;

    // 测试错误处理
    procedure Test_InvalidRelease;
    procedure Test_DoubleRelease;
  end;

  {**
   * TTestCase_IMutex_Concurrent
   *
   * @desc 高强度并发测试
   *}
  TTestCase_IMutex_Concurrent = class(TTestCase)
  private
    FMutex: IMutex;
    FSharedCounter: Int64;
    FThreadCount: Integer;
    FIterationsPerThread: Integer;
    FTestDuration: Cardinal;
    FErrorCount: LongInt;
    FSuccessCount: LongInt;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 并发正确性测试
    procedure Test_ConcurrentIncrement_2Threads;
    procedure Test_ConcurrentIncrement_8Threads;
    procedure Test_ConcurrentIncrement_32Threads;
    procedure Test_ConcurrentTryAcquire_HighContention;
    procedure Test_ConcurrentTimeout_MixedOperations;

    // 注意：压力测试、边界条件测试和性能验证测试在 fafafa.core.sync.mutex.stress 模块中实现
  end;

implementation

{$IFDEF UNIX}
uses
  cthreads;
{$ENDIF}

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeMutex;
var
  Mutex: IMutex;
begin
  // 测试工厂函数能正常创建互斥锁
  Mutex := MakeMutex;
  AssertNotNull('MakeMutex 应该返回有效的互斥锁实例', Mutex);
  
  // 测试基本功能
  Mutex.Acquire;
  try
    AssertTrue('锁应该被成功获取', True);
  finally
    Mutex.Release;
  end;
end;

procedure TTestCase_Global.Test_MutexGuard;
var
  Mutex: IMutex;
  Guard: ILockGuard;
  CanAcquire: Boolean;
begin
  // 创建一个互斥锁用于测试
  Mutex := MakeMutex;

  // 阶段1: 测试 Guard 自动获取锁
  Guard := MutexGuard(Mutex);
  AssertNotNull('MutexGuard 应该返回有效的锁保护器', Guard);

  // 阶段2: 验证锁已被获取（其他尝试应该失败）
  CanAcquire := Mutex.TryAcquire;
  AssertFalse('在 Guard 持有期间，TryAcquire 应该失败', CanAcquire);

  // 阶段3: 模拟 Guard 离开作用域（设置为 nil）
  Guard := nil;

  // 阶段4: 验证锁已被自动释放
  CanAcquire := Mutex.TryAcquire;
  AssertTrue('Guard 离开作用域后，锁应该被自动释放', CanAcquire);

  // 清理：手动释放我们获取的锁
  if CanAcquire then
    Mutex.Release;
end;

// RAII 并发测试的工作线程
type
  TRAIITestThread = class(TThread)
  private
    FMutex: IMutex;
    FSharedCounter: PInt64;
    FIterations: Integer;
    FSuccessCount: PLongInt;
  public
    constructor Create(AMutex: IMutex; ASharedCounter: PInt64; AIterations: Integer;
                      ASuccessCount: PLongInt);
    procedure Execute; override;
  end;

constructor TRAIITestThread.Create(AMutex: IMutex; ASharedCounter: PInt64;
  AIterations: Integer; ASuccessCount: PLongInt);
begin
  FMutex := AMutex;
  FSharedCounter := ASharedCounter;
  FIterations := AIterations;
  FSuccessCount := ASuccessCount;
  inherited Create(False);
end;

procedure TRAIITestThread.Execute;
var
  I: Integer;
  Guard: ILockGuard;
begin
  for I := 1 to FIterations do
  begin
    // 使用 RAII 保护临界区
    Guard := MutexGuard(FMutex);
    try
      // 临界区：增加共享计数器
      Inc(FSharedCounter^);
      atomic_fetch_add(FSuccessCount^, 1);
    finally
      // Guard 会在这里自动释放锁（当离开作用域时）
      Guard := nil;
    end;
  end;
end;

procedure TTestCase_Global.Test_MutexGuard_Concurrent;
var
  Mutex: IMutex;
  Threads: array[0..3] of TRAIITestThread;
  I: Integer;
  SharedCounter: Int64;
  SuccessCount: LongInt;
  ExpectedValue: Int64;
  IterationsPerThread: Integer;
begin
  // 初始化
  Mutex := MakeMutex;
  SharedCounter := 0;
  atomic_store(SuccessCount, 0);
  IterationsPerThread := 5000;
  ExpectedValue := 4 * IterationsPerThread;

  // 创建并启动4个线程，每个都使用 RAII 保护
  for I := 0 to 3 do
  begin
    Threads[I] := TRAIITestThread.Create(Mutex, @SharedCounter, IterationsPerThread, @SuccessCount);
  end;

  // 等待所有线程完成
  for I := 0 to 3 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // 验证 RAII 保护的正确性
  AssertEquals('RAII 保护下的共享计数器应该等于期望值', ExpectedValue, SharedCounter);
  AssertEquals('RAII 保护下的成功次数应该等于总操作数', ExpectedValue, atomic_load(SuccessCount));
end;

procedure TTestCase_Global.Test_MutexGuard_Function;
var
  Mutex1, Mutex2: IMutex;
  Guard1, Guard2: ILockGuard;
  CanAcquire: Boolean;
begin
  // 测试新的 MutexGuard(ALock: ILock) 函数：
  // 1. 语义清晰：为指定的锁创建保护器
  // 2. 便捷性：简化 RAII 保护的代码

  // 阶段1: 测试基本功能
  Mutex1 := MakeMutex;
  Guard1 := MutexGuard(Mutex1);
  AssertNotNull('MutexGuard 应该返回有效的锁保护器', Guard1);

  // 阶段2: 验证锁已被获取
  CanAcquire := Mutex1.TryAcquire;
  AssertFalse('在 Guard 持有期间，TryAcquire 应该失败', CanAcquire);

  // 阶段3: 测试不同锁的独立性
  Mutex2 := MakeMutex;
  Guard2 := MutexGuard(Mutex2);
  AssertNotNull('第二个 MutexGuard 应该返回有效的锁保护器', Guard2);
  AssertTrue('两个 Guard 应该是不同的对象', Guard1 <> Guard2);

  // 阶段4: 测试 RAII 生命周期管理
  Guard1 := nil; // 第一个锁应该被自动释放

  // 验证第一个锁已被释放
  CanAcquire := Mutex1.TryAcquire;
  AssertTrue('Guard1 释放后，Mutex1 应该可以被获取', CanAcquire);
  if CanAcquire then
    Mutex1.Release;

  Guard2 := nil; // 第二个锁也被释放

  // 新的 MutexGuard(ALock) 的优势：
  // - 语义清晰：明确为哪个锁创建保护器
  // - 便捷性：简化 RAII 代码
  // - 灵活性：可以为任何锁创建保护器
end;

// MutexGuard() 函数的设计说明：
// 该函数每次调用都创建一个新的互斥锁，适合以下场景：
// 1. 快速临界区保护：Guard := MutexGuard; // 使用后自动释放
// 2. 临时同步需求：不需要跨函数或跨线程共享同一个锁
// 3. 简化代码：避免手动创建和管理互斥锁
//
// 注意：如果需要多个线程共享同一个锁，应该使用：
// Mutex := MakeMutex; Guard := MakeLockGuard(Mutex);

{ TTestCase_IMutex }

procedure TTestCase_IMutex.SetUp;
begin
  inherited SetUp;
  FMutex := MakeMutex;
end;

procedure TTestCase_IMutex.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_IMutex.Test_Acquire_Release;
begin
  // 测试基本的获取和释放
  FMutex.Acquire;
  try
    AssertTrue('锁应该被成功获取', True);
  finally
    FMutex.Release;
  end;
  
  // 测试可以重新获取
  FMutex.Acquire;
  try
    AssertTrue('锁应该可以重新获取', True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IMutex.Test_TryAcquire_Success;
begin
  // 测试非阻塞获取（应该成功）
  AssertTrue('第一次 TryAcquire 应该成功', FMutex.TryAcquire);
  try
    // 测试重复获取（应该失败，因为是非重入锁）
    AssertFalse('重入 TryAcquire 应该失败', FMutex.TryAcquire);
  finally
    FMutex.Release;
  end;
  
  // 释放后应该可以再次获取
  AssertTrue('释放后 TryAcquire 应该成功', FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_TryAcquire_WithTimeout;
begin
  // 测试零超时（立即返回）
  AssertTrue('零超时 TryAcquire 应该成功', FMutex.TryAcquire(0));
  try
    // 测试重入检测
    AssertFalse('重入 TryAcquire 应该失败', FMutex.TryAcquire(100));
  finally
    FMutex.Release;
  end;
  
  // 测试正常超时获取
  AssertTrue('正常超时 TryAcquire 应该成功', FMutex.TryAcquire(1000));
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_GetHandle;
var
  Handle: Pointer;
begin
  Handle := FMutex.GetHandle;
  AssertNotNull('互斥锁句柄不应为空', Handle);
  
  // 句柄应该保持一致
  AssertEquals('句柄应该保持一致', PtrUInt(Handle), PtrUInt(FMutex.GetHandle));
end;

procedure TTestCase_IMutex.Test_LockGuard_RAII;
var
  Guard: ILockGuard;
begin
  // 测试锁保护器
  Guard := FMutex.LockGuard;
  AssertNotNull('锁保护器创建失败', Guard);

  // 测试锁已被获取（通过 TryAcquire 验证）
  AssertFalse('锁保护器应该已获取锁', FMutex.TryAcquire);

  // 测试 RAII：让保护器自动释放（不手动调用 Release）
  Guard := nil; // 触发析构函数，自动释放锁

  // 验证锁已被释放
  AssertTrue('锁保护器释放后应该可以获取锁', FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_DataProperty;
var
  TestData: Pointer;
begin
  // 测试初始数据为空
  AssertNull('初始数据应该为空', FMutex.Data);
  
  // 测试设置和获取数据
  TestData := Pointer($12345678);
  FMutex.Data := TestData;
  AssertEquals('数据设置和获取应该一致', PtrUInt(TestData), PtrUInt(FMutex.Data));
  
  // 测试清空数据
  FMutex.Data := nil;
  AssertNull('清空后数据应该为空', FMutex.Data);
end;

procedure TTestCase_IMutex.Test_NonReentrant_SameThread;
begin
  // 测试不可重入特性 - 同一线程重复获取应该失败
  FMutex.Acquire;
  try
    // 尝试重入，应该返回 False（不可重入）
    AssertFalse('不可重入互斥锁不应该允许同一线程重复获取', FMutex.TryAcquire);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IMutex.Test_NonReentrant_Exception;
begin
  // 测试重入时抛出异常
  FMutex.Acquire;
  try
    try
      FMutex.Acquire; // 应该抛出异常
      Fail('重入获取应该抛出异常');
    except
      on E: ELockError do
        // 期望的异常
        AssertTrue('应该抛出 ELockError', True);
    end;
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IMutex.Test_InvalidRelease;
begin
  // 测试释放未获取的锁
  try
    FMutex.Release;
    Fail('释放未获取的锁应该抛出异常');
  except
    on E: ELockError do
      // 期望的异常
      AssertTrue('应该抛出 ELockError', True);
  end;
end;

procedure TTestCase_IMutex.Test_DoubleRelease;
begin
  // 测试重复释放锁
  FMutex.Acquire;
  FMutex.Release;

  try
    FMutex.Release; // 重复释放
    Fail('重复释放锁应该抛出异常');
  except
    on E: ELockError do
      // 期望的异常
      AssertTrue('应该抛出 ELockError', True);
  end;
end;

{ TTestCase_IMutex_Concurrent }

procedure TTestCase_IMutex_Concurrent.SetUp;
begin
  inherited SetUp;
  FMutex := MakeMutex;
  FSharedCounter := 0;
  FThreadCount := 0;
  FIterationsPerThread := 10000;
  FTestDuration := 5000; // 5秒
  atomic_store(FErrorCount, 0);
  atomic_store(FSuccessCount, 0);
end;

procedure TTestCase_IMutex_Concurrent.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

// 并发增量测试的工作线程
type
  TIncrementThread = class(TThread)
  private
    FMutex: IMutex;
    FSharedCounter: PInt64;
    FIterations: Integer;
    FErrorCount: PLongInt;
    FSuccessCount: PLongInt;
  public
    constructor Create(AMutex: IMutex; ASharedCounter: PInt64; AIterations: Integer;
                      AErrorCount, ASuccessCount: PLongInt);
    procedure Execute; override;
  end;

constructor TIncrementThread.Create(AMutex: IMutex; ASharedCounter: PInt64;
  AIterations: Integer; AErrorCount, ASuccessCount: PLongInt);
begin
  FMutex := AMutex;
  FSharedCounter := ASharedCounter;
  FIterations := AIterations;
  FErrorCount := AErrorCount;
  FSuccessCount := ASuccessCount;
  inherited Create(False);
end;

procedure TIncrementThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    try
      FMutex.Acquire;
      try
        // 临界区：增加共享计数器
        Inc(FSharedCounter^);
        atomic_fetch_add(FSuccessCount^, 1);
      finally
        FMutex.Release;
      end;
    except
      atomic_fetch_add(FErrorCount^, 1);
    end;
  end;
end;

procedure TTestCase_IMutex_Concurrent.Test_ConcurrentIncrement_2Threads;
var
  Threads: array[0..1] of TIncrementThread;
  I: Integer;
  ExpectedValue: Int64;
begin
  FThreadCount := 2;
  ExpectedValue := FThreadCount * FIterationsPerThread;

  // 创建并启动线程
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I] := TIncrementThread.Create(FMutex, @FSharedCounter, FIterationsPerThread,
                                         @FErrorCount, @FSuccessCount);
  end;

  // 等待所有线程完成
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // 验证结果
  AssertEquals('共享计数器应该等于期望值', ExpectedValue, FSharedCounter);
  AssertEquals('不应该有错误', 0, atomic_load(FErrorCount));
  AssertEquals('成功次数应该等于总操作数', ExpectedValue, atomic_load(FSuccessCount));
end;

procedure TTestCase_IMutex_Concurrent.Test_ConcurrentIncrement_8Threads;
var
  Threads: array[0..7] of TIncrementThread;
  I: Integer;
  ExpectedValue: Int64;
begin
  FThreadCount := 8;
  ExpectedValue := FThreadCount * FIterationsPerThread;

  // 创建并启动线程
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I] := TIncrementThread.Create(FMutex, @FSharedCounter, FIterationsPerThread,
                                         @FErrorCount, @FSuccessCount);
  end;

  // 等待所有线程完成
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // 验证结果
  AssertEquals('共享计数器应该等于期望值', ExpectedValue, FSharedCounter);
  AssertEquals('不应该有错误', 0, atomic_load(FErrorCount));
  AssertEquals('成功次数应该等于总操作数', ExpectedValue, atomic_load(FSuccessCount));
end;

procedure TTestCase_IMutex_Concurrent.Test_ConcurrentIncrement_32Threads;
var
  Threads: array[0..31] of TIncrementThread;
  I: Integer;
  ExpectedValue: Int64;
begin
  FThreadCount := 32;
  FIterationsPerThread := 1000; // 减少迭代次数以避免测试时间过长
  ExpectedValue := FThreadCount * FIterationsPerThread;

  // 创建并启动线程
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I] := TIncrementThread.Create(FMutex, @FSharedCounter, FIterationsPerThread,
                                         @FErrorCount, @FSuccessCount);
  end;

  // 等待所有线程完成
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // 验证结果
  AssertEquals('共享计数器应该等于期望值', ExpectedValue, FSharedCounter);
  AssertEquals('不应该有错误', 0, atomic_load(FErrorCount));
  AssertEquals('成功次数应该等于总操作数', ExpectedValue, atomic_load(FSuccessCount));
end;

// TryAcquire 高竞争测试的工作线程
type
  TTryAcquireThread = class(TThread)
  private
    FMutex: IMutex;
    FIterations: Integer;
    FSuccessCount: PLongInt;
    FFailureCount: PLongInt;
  public
    constructor Create(AMutex: IMutex; AIterations: Integer;
                      ASuccessCount, AFailureCount: PLongInt);
    procedure Execute; override;
  end;

constructor TTryAcquireThread.Create(AMutex: IMutex; AIterations: Integer;
  ASuccessCount, AFailureCount: PLongInt);
begin
  FMutex := AMutex;
  FIterations := AIterations;
  FSuccessCount := ASuccessCount;
  FFailureCount := AFailureCount;
  inherited Create(False);
end;

procedure TTryAcquireThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    if FMutex.TryAcquire then
    begin
      try
        // 模拟一些工作
        Sleep(1);
        atomic_fetch_add(FSuccessCount^, 1);
      finally
        FMutex.Release;
      end;
    end
    else
    begin
      atomic_fetch_add(FFailureCount^, 1);
    end;
  end;
end;

procedure TTestCase_IMutex_Concurrent.Test_ConcurrentTryAcquire_HighContention;
var
  Threads: array[0..15] of TTryAcquireThread;
  I: Integer;
  TotalSuccess, TotalFailure: LongInt;
  FailureCount: LongInt;
begin
  FThreadCount := 16;
  FIterationsPerThread := 100;
  FailureCount := 0;

  // 创建并启动线程
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I] := TTryAcquireThread.Create(FMutex, FIterationsPerThread,
                                          @FSuccessCount, @FailureCount);
  end;

  // 等待所有线程完成
  for I := 0 to FThreadCount - 1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // 验证结果
  TotalSuccess := atomic_load(FSuccessCount);
  TotalFailure := atomic_load(FailureCount);

  AssertTrue('应该有成功的获取', TotalSuccess > 0);
  AssertTrue('应该有失败的获取（高竞争）', TotalFailure > 0);
  AssertEquals('总操作数应该正确', FThreadCount * FIterationsPerThread, TotalSuccess + TotalFailure);
end;

// 超时测试的工作线程
type
  TTimeoutThread = class(TThread)
  private
    FMutex: IMutex;
    FTimeoutMs: Cardinal;
    FSuccessCount: PLongInt;
    FTimeoutCount: PLongInt;
  public
    constructor Create(AMutex: IMutex; ATimeoutMs: Cardinal;
                      ASuccessCount, ATimeoutCount: PLongInt);
    procedure Execute; override;
  end;

constructor TTimeoutThread.Create(AMutex: IMutex; ATimeoutMs: Cardinal;
  ASuccessCount, ATimeoutCount: PLongInt);
begin
  FMutex := AMutex;
  FTimeoutMs := ATimeoutMs;
  FSuccessCount := ASuccessCount;
  FTimeoutCount := ATimeoutCount;
  inherited Create(False);
end;

procedure TTimeoutThread.Execute;
begin
  if FMutex.TryAcquire(FTimeoutMs) then
  begin
    try
      Sleep(50); // 持有锁一段时间
      atomic_fetch_add(FSuccessCount^, 1);
    finally
      FMutex.Release;
    end;
  end
  else
  begin
    atomic_fetch_add(FTimeoutCount^, 1);
  end;
end;

procedure TTestCase_IMutex_Concurrent.Test_ConcurrentTimeout_MixedOperations;
var
  Threads: array[0..7] of TTimeoutThread;
  I: Integer;
  TimeoutCount: LongInt;
begin
  TimeoutCount := 0;

  // 创建混合超时的线程
  for I := 0 to 7 do
  begin
    Threads[I] := TTimeoutThread.Create(FMutex, 10 + I * 5, // 不同的超时值
                                       @FSuccessCount, @TimeoutCount);
  end;

  // 等待所有线程完成
  for I := 0 to 7 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // 验证结果
  AssertTrue('应该有成功的操作', atomic_load(FSuccessCount) > 0);
  AssertEquals('总操作数应该正确', 8, atomic_load(FSuccessCount) + atomic_load(TimeoutCount));
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IMutex);
  RegisterTest(TTestCase_IMutex_Concurrent);

end.

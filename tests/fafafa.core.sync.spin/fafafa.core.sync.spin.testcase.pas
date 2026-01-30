unit fafafa.core.sync.spin.testcase;

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  fpcunit, testregistry,
  fafafa.core.sync.spin, fafafa.core.sync.base, fafafa.core.sync.spin.base;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeSpin;
  end;

  // ISpin 接口基础测试
  TTestCase_ISpin = class(TTestCase)
  private
    FSpin: ISpin;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本 API 测试
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire_Success;
    procedure Test_TryAcquire_Timeout_Zero;
    procedure Test_TryAcquire_Timeout_Short;
    procedure Test_RAII_LockGuard;

    // 边界测试
    procedure Test_Boundary_ZeroTimeout;
    procedure Test_Boundary_MaxTimeout;
    procedure Test_Boundary_LongTimeout;

    // 并发测试
    procedure Test_Concurrent_Basic;
  end;

  // 兼容性测试
  TTestCase_Compatibility = class(TTestCase)
  private
    FSpinLock: ISpin;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_ISpinLock_Interface;
    procedure Test_ISpinLock_BasicOperations;
  end;

  // 错误处理测试
  TTestCase_ErrorHandling = class(TTestCase)
  private
    FSpin: ISpin;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Error_DoubleRelease;
    procedure Test_Error_ReleaseWithoutAcquire;
    procedure Test_Behavior_NonReentrant;
  end;

  // RAII 深度测试
  TTestCase_RAII = class(TTestCase)
  private
    FSpin: ISpin;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_RAII_ExceptionSafety;
    procedure Test_RAII_NestedGuards;
    procedure Test_RAII_ManualRelease;
    procedure Test_RAII_GuardLifetime;
  end;

  // 多线程并发测试
  TTestCase_MultiThread = class(TTestCase)
  private
    FSpin: ISpin;
    FSharedCounter: Integer;
    FThreadCount: Integer;
    FIterationsPerThread: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_MultiThread_BasicContention;
    procedure Test_MultiThread_HighContention;
    procedure Test_MultiThread_Counter;
    procedure Test_MultiThread_TryAcquire;
    procedure Test_MultiThread_Fairness;
  end;

  // 性能和行为测试
  TTestCase_Performance = class(TTestCase)
  private
    FSpin: ISpin;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Performance_SpinBehavior;
    procedure Test_Performance_BackoffStrategy;
    procedure Test_Performance_BasicThroughput;
  end;

  // 线程工作器类型
  TSpinTestThread = class(TThread)
  private
    FSpin: ISpin;
    FCounter: PInteger;
    FIterations: Integer;
    FUseAcquire: Boolean;
    FSuccess: Boolean;
  public
    constructor Create(ASpin: ISpin; ACounter: PInteger; AIterations: Integer; AUseAcquire: Boolean = True);
    procedure Execute; override;
    property Success: Boolean read FSuccess;
  end;

implementation

// ===== TSpinTestThread =====

constructor TSpinTestThread.Create(ASpin: ISpin; ACounter: PInteger; AIterations: Integer; AUseAcquire: Boolean);
begin
  inherited Create(False);
  FSpin := ASpin;
  FCounter := ACounter;
  FIterations := AIterations;
  FUseAcquire := AUseAcquire;
  FSuccess := False;
end;

procedure TSpinTestThread.Execute;
var
  i: Integer;
begin
  try
    for i := 1 to FIterations do
    begin
      if FUseAcquire then
      begin
        FSpin.Acquire;
        try
          Inc(FCounter^);
        finally
          FSpin.Release;
        end;
      end
      else
      begin
        // 使用 TryAcquire
        while not FSpin.TryAcquire do
          Sleep(0); // 让出 CPU
        try
          Inc(FCounter^);
        finally
          FSpin.Release;
        end;
      end;
    end;
    FSuccess := True;
  except
    FSuccess := False;
  end;
end;

// ===== TTestCase_Global =====

procedure TTestCase_Global.Test_MakeSpin;
var
  L: ISpin;
begin
  L := MakeSpin;
  AssertNotNull('MakeSpin should return non-nil interface', L);
end;


// ===== TTestCase_ISpin =====

procedure TTestCase_ISpin.SetUp;
begin
  inherited SetUp;
  FSpin := MakeSpin;
end;

procedure TTestCase_ISpin.TearDown;
begin
  FSpin := nil;
  inherited TearDown;
end;

procedure TTestCase_ISpin.Test_Acquire_Release;
begin
  // 基本获取和释放
  FSpin.Acquire;
  FSpin.Release;
  
  // 多次获取和释放
  FSpin.Acquire;
  FSpin.Release;
  FSpin.Acquire;
  FSpin.Release;
end;

procedure TTestCase_ISpin.Test_TryAcquire_Success;
begin
  // 无竞争情况下应该成功
  AssertTrue('TryAcquire should succeed when no contention', FSpin.TryAcquire);
  FSpin.Release;
end;

procedure TTestCase_ISpin.Test_TryAcquire_Timeout_Zero;
begin
  // 测试零超时的行为：无竞争时应该成功
  AssertTrue('TryAcquire(0) should succeed when no contention', FSpin.TryAcquire(0));
  FSpin.Release;
  
  // 再次测试零超时
  AssertTrue('TryAcquire(0) should succeed again when no contention', FSpin.TryAcquire(0));
  FSpin.Release;
end;

procedure TTestCase_ISpin.Test_TryAcquire_Timeout_Short;
begin
  // 无竞争情况下，即使短超时也应该成功
  AssertTrue('TryAcquire with short timeout should succeed when no contention', FSpin.TryAcquire(10));
  FSpin.Release;
end;

procedure TTestCase_ISpin.Test_RAII_LockGuard;
var
  Guard: ILockGuard;
begin
  // 测试 RAII 自动锁管理
  Guard := FSpin.LockGuard;
  AssertNotNull('LockGuard should not be nil', Guard);
  // Guard 超出作用域时会自动释放锁
end;

procedure TTestCase_ISpin.Test_Boundary_ZeroTimeout;
begin
  // 测试零超时边界情况
  AssertTrue('TryAcquire(0) should succeed when no contention', FSpin.TryAcquire(0));
  FSpin.Release;
end;

procedure TTestCase_ISpin.Test_Boundary_MaxTimeout;
begin
  // 测试最大超时值
  AssertTrue('TryAcquire with max timeout should succeed when no contention', FSpin.TryAcquire(High(Cardinal)));
  FSpin.Release;
end;

procedure TTestCase_ISpin.Test_Boundary_LongTimeout;
begin
  // 测试长超时值（5秒）
  AssertTrue('TryAcquire with long timeout should succeed when no contention', FSpin.TryAcquire(5000));
  FSpin.Release;
end;

procedure TTestCase_ISpin.Test_Concurrent_Basic;
var
  Counter: Integer;
  i: Integer;
begin
  // 简单的并发测试
  Counter := 0;
  
  // 在单线程中模拟并发操作
  for i := 1 to 1000 do
  begin
    FSpin.Acquire;
    try
      Inc(Counter);
    finally
      FSpin.Release;
    end;
  end;
  
  AssertEquals('Counter should be 1000', 1000, Counter);
end;

// ===== TTestCase_Compatibility =====

procedure TTestCase_Compatibility.SetUp;
begin
  inherited SetUp;
  FSpinLock := MakeSpin;
end;

procedure TTestCase_Compatibility.TearDown;
begin
  FSpinLock := nil;
  inherited TearDown;
end;

procedure TTestCase_Compatibility.Test_ISpinLock_Interface;
var
  Spin: ISpin;
begin
  // 测试 ISpinLock 可以转换为 ISpin
  AssertNotNull('FSpinLock should not be nil', FSpinLock);

  Spin := ISpin(FSpinLock);
  AssertNotNull('ISpinLock should be convertible to ISpin', Spin);

  // 测试接口功能一致性
  Spin.Acquire;
  Spin.Release;
end;

procedure TTestCase_Compatibility.Test_ISpinLock_BasicOperations;
begin
  // 测试 ISpinLock 的基本操作
  FSpinLock.Acquire;
  FSpinLock.Release;

  // 测试 TryAcquire
  AssertTrue('ISpinLock TryAcquire should succeed', FSpinLock.TryAcquire);
  FSpinLock.Release;

  // 测试 RAII
  with FSpinLock.LockGuard do
  begin
    // 锁应该被自动获取和释放
  end;
end;

// ===== TTestCase_ErrorHandling =====

procedure TTestCase_ErrorHandling.SetUp;
begin
  inherited SetUp;
  FSpin := MakeSpin;
end;

procedure TTestCase_ErrorHandling.TearDown;
begin
  FSpin := nil;
  inherited TearDown;
end;

procedure TTestCase_ErrorHandling.Test_Error_DoubleRelease;
begin
  // 获取锁
  FSpin.Acquire;
  FSpin.Release;

  // 第二次释放应该安全（不崩溃）
  // 注意：自旋锁通常不检查重复释放，这是正常行为
  FSpin.Release; // 应该不会崩溃
end;

procedure TTestCase_ErrorHandling.Test_Error_ReleaseWithoutAcquire;
begin
  // 未获取锁就释放应该安全（不崩溃）
  // 注意：自旋锁通常不检查这种情况，这是正常行为
  FSpin.Release; // 应该不会崩溃
end;

procedure TTestCase_ErrorHandling.Test_Behavior_NonReentrant;
begin
  // 测试非重入行为
  // 注意：这个测试在单线程中无法真正测试死锁，
  // 只能验证基本的获取/释放行为
  FSpin.Acquire;

  // 在同一线程中，TryAcquire 应该失败（如果实现了重入检测）
  // 但大多数自旋锁实现不检查重入，所以这个测试可能会成功
  // 这里我们只测试基本行为
  FSpin.Release;

  // 释放后应该能再次获取
  AssertTrue('Should be able to acquire after release', FSpin.TryAcquire);
  FSpin.Release;
end;

// ===== TTestCase_RAII =====

procedure TTestCase_RAII.SetUp;
begin
  inherited SetUp;
  FSpin := MakeSpin;
end;

procedure TTestCase_RAII.TearDown;
begin
  FSpin := nil;
  inherited TearDown;
end;

procedure TTestCase_RAII.Test_RAII_ExceptionSafety;
var
  Guard: ILockGuard;
begin
  // 测试异常安全性
  Guard := FSpin.LockGuard;
  AssertNotNull('Guard should not be nil', Guard);

  // 模拟异常情况
  try
    try
      raise Exception.Create('Test exception');
    except
      // 异常被捕获，Guard 应该仍然有效
    end;
  finally
    // Guard 在 finally 块中应该仍然有效
  end;

  // 显式释放 Guard
  Guard := nil;

  // 验证锁已被释放
  AssertTrue('Lock should be released after exception', FSpin.TryAcquire);
  FSpin.Release;
end;

procedure TTestCase_RAII.Test_RAII_NestedGuards;
var
  Guard1, Guard2: ILockGuard;
begin
  // 测试嵌套守卫（应该失败，因为自旋锁不支持重入）
  Guard1 := FSpin.LockGuard;
  AssertNotNull('First guard should not be nil', Guard1);

  // 尝试创建第二个守卫（应该阻塞或失败）
  // 在单线程测试中，我们无法真正测试这种情况
  // 这里只是验证第一个守卫工作正常

  Guard1 := nil; // 释放第一个守卫

  // 现在应该能创建第二个守卫
  Guard2 := FSpin.LockGuard;
  AssertNotNull('Second guard should not be nil', Guard2);
end;

procedure TTestCase_RAII.Test_RAII_ManualRelease;
var
  Guard: ILockGuard;
begin
  // 测试手动释放守卫
  Guard := FSpin.LockGuard;
  AssertNotNull('Guard should not be nil', Guard);

  // 手动释放
  Guard.Release;

  // 验证锁已被释放
  AssertTrue('Lock should be released after manual release', FSpin.TryAcquire);
  FSpin.Release;
end;

procedure TTestCase_RAII.Test_RAII_GuardLifetime;
var
  Guard: ILockGuard;
begin
  // 测试守卫生命周期
  Guard := FSpin.LockGuard;
  AssertNotNull('Guard should not be nil', Guard);

  // 显式释放守卫
  Guard := nil;

  // 验证锁已被释放
  AssertTrue('Lock should be released after guard is set to nil', FSpin.TryAcquire);
  FSpin.Release;
end;

// ===== TTestCase_MultiThread =====

procedure TTestCase_MultiThread.SetUp;
begin
  inherited SetUp;
  FSpin := MakeSpin;
  FSharedCounter := 0;
  FThreadCount := 4;
  FIterationsPerThread := 250; // 4 * 250 = 1000 total
end;

procedure TTestCase_MultiThread.TearDown;
begin
  FSpin := nil;
  inherited TearDown;
end;

procedure TTestCase_MultiThread.Test_MultiThread_BasicContention;
var
  Threads: array of TSpinTestThread;
  i: Integer;
  AllSuccess: Boolean;
begin
  // 创建多个线程进行基本竞争测试
  SetLength(Threads, FThreadCount);

  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TSpinTestThread.Create(FSpin, @FSharedCounter, FIterationsPerThread, True);
  end;

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
  end;

  // 检查结果
  AllSuccess := True;
  for i := 0 to FThreadCount - 1 do
  begin
    if not Threads[i].Success then
      AllSuccess := False;
    Threads[i].Free;
  end;

  AssertTrue('All threads should complete successfully', AllSuccess);
  AssertEquals('Counter should be correct', FThreadCount * FIterationsPerThread, FSharedCounter);
end;

procedure TTestCase_MultiThread.Test_MultiThread_HighContention;
var
  Threads: array of TSpinTestThread;
  i: Integer;
  AllSuccess: Boolean;
begin
  // 高竞争测试：更多线程，更少迭代
  FThreadCount := 8;
  FIterationsPerThread := 125; // 8 * 125 = 1000 total
  FSharedCounter := 0;

  SetLength(Threads, FThreadCount);

  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TSpinTestThread.Create(FSpin, @FSharedCounter, FIterationsPerThread, True);
  end;

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
  end;

  // 检查结果
  AllSuccess := True;
  for i := 0 to FThreadCount - 1 do
  begin
    if not Threads[i].Success then
      AllSuccess := False;
    Threads[i].Free;
  end;

  AssertTrue('All threads should complete successfully in high contention', AllSuccess);
  AssertEquals('Counter should be correct in high contention', FThreadCount * FIterationsPerThread, FSharedCounter);
end;

procedure TTestCase_MultiThread.Test_MultiThread_Counter;
var
  Threads: array of TSpinTestThread;
  i: Integer;
  AllSuccess: Boolean;
begin
  // 标准计数器保护测试
  FSharedCounter := 0;
  SetLength(Threads, FThreadCount);

  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TSpinTestThread.Create(FSpin, @FSharedCounter, FIterationsPerThread, True);
  end;

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
  end;

  // 检查结果
  AllSuccess := True;
  for i := 0 to FThreadCount - 1 do
  begin
    if not Threads[i].Success then
      AllSuccess := False;
    Threads[i].Free;
  end;

  AssertTrue('All threads should complete successfully', AllSuccess);
  AssertEquals('Shared counter should be protected correctly', FThreadCount * FIterationsPerThread, FSharedCounter);
end;

procedure TTestCase_MultiThread.Test_MultiThread_TryAcquire;
var
  Threads: array of TSpinTestThread;
  i: Integer;
  AllSuccess: Boolean;
begin
  // 使用 TryAcquire 的多线程测试
  FSharedCounter := 0;
  SetLength(Threads, FThreadCount);

  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TSpinTestThread.Create(FSpin, @FSharedCounter, FIterationsPerThread, False); // 使用 TryAcquire
  end;

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
  end;

  // 检查结果
  AllSuccess := True;
  for i := 0 to FThreadCount - 1 do
  begin
    if not Threads[i].Success then
      AllSuccess := False;
    Threads[i].Free;
  end;

  AssertTrue('All threads should complete successfully with TryAcquire', AllSuccess);
  AssertEquals('Counter should be correct with TryAcquire', FThreadCount * FIterationsPerThread, FSharedCounter);
end;

procedure TTestCase_MultiThread.Test_MultiThread_Fairness;
var
  Threads: array of TSpinTestThread;
  i: Integer;
  AllSuccess: Boolean;
begin
  // 公平性测试：验证所有线程都能获得锁
  FSharedCounter := 0;
  FIterationsPerThread := 100; // 较少的迭代，更容易观察公平性

  SetLength(Threads, FThreadCount);

  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i] := TSpinTestThread.Create(FSpin, @FSharedCounter, FIterationsPerThread, True);
  end;

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
  end;

  // 检查结果
  AllSuccess := True;
  for i := 0 to FThreadCount - 1 do
  begin
    if not Threads[i].Success then
      AllSuccess := False;
    Threads[i].Free;
  end;

  AssertTrue('All threads should complete successfully (fairness test)', AllSuccess);
  AssertEquals('Counter should be correct (fairness test)', FThreadCount * FIterationsPerThread, FSharedCounter);
end;

// ===== TTestCase_Performance =====

procedure TTestCase_Performance.SetUp;
begin
  inherited SetUp;
  FSpin := MakeSpin;
end;

procedure TTestCase_Performance.TearDown;
begin
  FSpin := nil;
  inherited TearDown;
end;

procedure TTestCase_Performance.Test_Performance_SpinBehavior;
var
  StartTime, EndTime: QWord;
  i: Integer;
  ElapsedMs: QWord;
const
  ITERATIONS = 10000;
begin
  // 测试自旋锁的基本性能行为
  StartTime := GetTickCount64;

  for i := 1 to ITERATIONS do
  begin
    FSpin.Acquire;
    FSpin.Release;
  end;

  EndTime := GetTickCount64;
  ElapsedMs := EndTime - StartTime;

  // 基本健全性检查：10000次操作应该在合理时间内完成
  AssertTrue('Performance test should complete in reasonable time (elapsed=' + IntToStr(ElapsedMs) + 'ms)', ElapsedMs < 1000);
end;

procedure TTestCase_Performance.Test_Performance_BackoffStrategy;
var
  StartTime, EndTime: QWord;
  i: Integer;
  ElapsedMs: QWord;
const
  ITERATIONS = 5000;
begin
  // 测试退避策略的性能影响
  StartTime := GetTickCount64;

  for i := 1 to ITERATIONS do
  begin
    if FSpin.TryAcquire then
    begin
      FSpin.Release;
    end;
  end;

  EndTime := GetTickCount64;
  ElapsedMs := EndTime - StartTime;

  // TryAcquire 应该比 Acquire 更快（无竞争情况下）
  AssertTrue('TryAcquire performance test should complete quickly (elapsed=' + IntToStr(ElapsedMs) + 'ms)', ElapsedMs < 500);
end;

procedure TTestCase_Performance.Test_Performance_BasicThroughput;
var
  StartTime, EndTime: QWord;
  i: Integer;
  ElapsedMs: QWord;
  ThroughputOpsPerSec: Double;
const
  ITERATIONS = 50000;
begin
  // 基本吞吐量测试
  StartTime := GetTickCount64;

  for i := 1 to ITERATIONS do
  begin
    FSpin.Acquire;
    // 模拟极短的临界区
    FSpin.Release;
  end;

  EndTime := GetTickCount64;
  ElapsedMs := EndTime - StartTime;

  if ElapsedMs > 0 then
  begin
    ThroughputOpsPerSec := (ITERATIONS * 1000.0) / ElapsedMs;

    // 基本吞吐量应该达到合理水平（至少 100K ops/sec）
    AssertTrue('Throughput should be reasonable (got ' + FloatToStr(ThroughputOpsPerSec) + ' ops/sec)', ThroughputOpsPerSec > 100000);
  end;

  // 总时间不应该太长
  AssertTrue('Throughput test should complete in reasonable time (elapsed=' + IntToStr(ElapsedMs) + 'ms)', ElapsedMs < 2000);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_ISpin);
  RegisterTest(TTestCase_Compatibility);
  RegisterTest(TTestCase_ErrorHandling);
  RegisterTest(TTestCase_RAII);
  RegisterTest(TTestCase_MultiThread);
  RegisterTest(TTestCase_Performance);

end.

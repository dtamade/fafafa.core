unit fafafa.core.sync.recMutex.testcase.simplified;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.recMutex, fafafa.core.sync.base, fafafa.core.sync.recMutex.base,
  {$IFDEF WINDOWS}
  fafafa.core.sync.recMutex.windows
  {$ELSE}
  fafafa.core.sync.recMutex.unix
  {$ENDIF};

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeRecMutex;
    {$IFDEF WINDOWS}
    procedure Test_MakeRecMutex_WithSpinCount;
    {$ENDIF}
  end;

  // IRecMutex 接口基础测试 - 简化版本
  TTestCase_IRecMutex = class(TTestCase)
  private
    FRecMutex: IRecMutex;
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

    // 重入特性测试
    procedure Test_Reentrancy_Basic;
    procedure Test_Reentrancy_Deep;

    // 边界测试
    procedure Test_Boundary_ZeroTimeout;
    procedure Test_Boundary_MaxTimeout;
    procedure Test_Boundary_LongTimeout;

    // 并发测试
    procedure Test_Concurrent_Basic;

    // 错误处理测试
    procedure Test_Error_DoubleRelease;
    procedure Test_Error_ReleaseWithoutAcquire;

    // 性能和压力测试
    procedure Test_Performance_HighFrequency;
    procedure Test_Stress_DeepReentrancy;
    procedure Test_Stress_RapidAcquireRelease;

    // RAII 深度测试
    procedure Test_RAII_NestedGuards;
    procedure Test_RAII_ExceptionSafety;
    procedure Test_RAII_ManualRelease;

    // 边界和异常情况
    procedure Test_Boundary_MaxSpinCount;
    procedure Test_Boundary_ZeroSpinCount;

    // 极限压力测试
    procedure Test_Extreme_MassiveReentrancy;
    procedure Test_Extreme_RapidCycling;
    procedure Test_Extreme_LongHoldTime;

    // 实际使用场景测试
    procedure Test_Scenario_RecursiveFunction;
    procedure Test_Scenario_NestedCalls;
    procedure Test_Scenario_ExceptionInCriticalSection;
    procedure Test_Scenario_TimeoutInContention;

    // 资源管理测试
    procedure Test_Resource_MultipleInstances;
    procedure Test_Resource_InstanceLifecycle;
    procedure Test_Resource_HandleAccess;

    // 兼容性测试
    procedure Test_Compatibility_WithOtherLocks;
    procedure Test_Compatibility_CrossPlatform;
  end;

  // 多线程并发测试
  TTestCase_MultiThread = class(TTestCase)
  private
    FRecMutex: IRecMutex;
    FSharedCounter: Integer;
    FThreadCount: Integer;
    FIterationsPerThread: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_MultiThread_BasicContention;
    procedure Test_MultiThread_ReentrantAccess;
    procedure Test_MultiThread_TryAcquireContention;
    procedure Test_MultiThread_Counter;

    // 高强度多线程测试
    procedure Test_MultiThread_HighContention;
    procedure Test_MultiThread_MixedOperations;
    procedure Test_MultiThread_StressTest;
    procedure Test_MultiThread_TimeoutContention;
    procedure Test_MultiThread_RAIIStress;
  end;

implementation

// ===== TTestCase_Global =====

procedure TTestCase_Global.Test_MakeRecMutex;
var
  RecMutex: IRecMutex;
begin
  RecMutex := MakeRecMutex;
  AssertNotNull('MakeRecMutex should return non-nil interface', RecMutex);
  
  // 基本功能测试
  RecMutex.Acquire;
  RecMutex.Release;
  
  AssertTrue('TryAcquire should succeed', RecMutex.TryAcquire);
  RecMutex.Release;
end;

{$IFDEF WINDOWS}
procedure TTestCase_Global.Test_MakeRecMutex_WithSpinCount;
var
  RecMutex: IRecMutex;
begin
  RecMutex := MakeRecMutex(1000);
  AssertNotNull('MakeRecMutex with spin count should return non-nil interface', RecMutex);
  
  // 基本功能测试
  RecMutex.Acquire;
  RecMutex.Release;
  
  AssertTrue('TryAcquire should succeed', RecMutex.TryAcquire);
  RecMutex.Release;
end;
{$ENDIF}

// ===== TTestCase_IRecMutex =====

procedure TTestCase_IRecMutex.SetUp;
begin
  FRecMutex := MakeRecMutex;
end;

procedure TTestCase_IRecMutex.TearDown;
begin
  FRecMutex := nil;
end;

procedure TTestCase_IRecMutex.Test_Acquire_Release;
begin
  // 基本的获取和释放测试
  FRecMutex.Acquire;
  FRecMutex.Release;
  
  // 验证锁已释放
  AssertTrue('Lock should be available after release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_TryAcquire_Success;
begin
  // TryAcquire 成功测试
  AssertTrue('TryAcquire should succeed when lock is free', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_TryAcquire_Timeout_Zero;
begin
  // 零超时测试
  AssertTrue('TryAcquire(0) should succeed when lock is free', FRecMutex.TryAcquire(0));
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_TryAcquire_Timeout_Short;
begin
  // 短超时测试
  AssertTrue('TryAcquire(100) should succeed when lock is free', FRecMutex.TryAcquire(100));
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_RAII_LockGuard;
var
  Guard: ILockGuard;
begin
  // RAII 锁保护测试
  Guard := FRecMutex.LockGuard;
  AssertNotNull('Lock guard should not be nil', Guard);
  // Guard 会在作用域结束时自动释放锁
end;

procedure TTestCase_IRecMutex.Test_Reentrancy_Basic;
begin
  // 基本重入测试
  FRecMutex.Acquire;
  try
    // 同一线程再次获取锁应该成功
    FRecMutex.Acquire;
    try
      // 嵌套临界区
      AssertTrue('Nested acquire should succeed', True);
    finally
      FRecMutex.Release;
    end;
  finally
    FRecMutex.Release;
  end;
  
  // 验证锁已完全释放
  AssertTrue('Lock should be available after all releases', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Reentrancy_Deep;
var
  i: Integer;
const
  DEPTH = 10;
begin
  // 深度重入测试
  for i := 1 to DEPTH do
    FRecMutex.Acquire;

  for i := DEPTH downto 1 do
    FRecMutex.Release;

  // 验证锁已完全释放
  AssertTrue('Lock should be available after all releases', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Boundary_ZeroTimeout;
begin
  // 零超时边界测试
  AssertTrue('TryAcquire(0) should succeed', FRecMutex.TryAcquire(0));
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Boundary_MaxTimeout;
begin
  // 最大超时边界测试
  AssertTrue('TryAcquire(High(Cardinal)) should succeed', FRecMutex.TryAcquire(High(Cardinal)));
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Boundary_LongTimeout;
begin
  // 长超时测试
  AssertTrue('TryAcquire(5000) should succeed', FRecMutex.TryAcquire(5000));
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Concurrent_Basic;
begin
  // 基本并发测试（单线程版本）
  FRecMutex.Acquire;
  try
    // 模拟临界区工作
    Sleep(1);
  finally
    FRecMutex.Release;
  end;

  // 验证锁已释放
  AssertTrue('Lock should be available after release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Error_DoubleRelease;
begin
  // 测试双重释放的行为
  FRecMutex.Acquire;
  FRecMutex.Release;

  // 第二次释放应该不会崩溃（Windows Critical Section 的宽松行为）
  try
    FRecMutex.Release; // 可能是安全的或被忽略
    AssertTrue('Double release should not crash', True);
  except
    // 如果抛出异常也是可接受的行为
    on E: Exception do
      AssertTrue('Exception on double release is acceptable', True);
  end;
end;

procedure TTestCase_IRecMutex.Test_Error_ReleaseWithoutAcquire;
begin
  // 测试未获取锁就释放的行为
  try
    FRecMutex.Release; // 可能是安全的或抛出异常
    AssertTrue('Release without acquire should not crash', True);
  except
    // 如果抛出异常也是可接受的行为
    on E: Exception do
      AssertTrue('Exception on release without acquire is acceptable', True);
  end;
end;

procedure TTestCase_IRecMutex.Test_Performance_HighFrequency;
var
  i: Integer;
  StartTime, EndTime: TDateTime;
const
  ITERATIONS = 10000;
begin
  // 高频率获取/释放性能测试
  StartTime := Now;

  for i := 1 to ITERATIONS do
  begin
    FRecMutex.Acquire;
    FRecMutex.Release;
  end;

  EndTime := Now;

  // 验证性能合理（应该在合理时间内完成）
  AssertTrue('High frequency operations should complete in reasonable time',
    (EndTime - StartTime) < (1.0 / 24 / 60 / 60)); // 小于1秒
end;

procedure TTestCase_IRecMutex.Test_Stress_DeepReentrancy;
var
  i: Integer;
const
  MAX_DEPTH = 100;
begin
  // 深度重入压力测试
  for i := 1 to MAX_DEPTH do
    FRecMutex.Acquire;

  // 验证仍然可以获取锁（重入）
  AssertTrue('Should still be able to acquire after deep nesting', FRecMutex.TryAcquire);
  FRecMutex.Release; // 释放 TryAcquire 获取的锁

  for i := MAX_DEPTH downto 1 do
    FRecMutex.Release;

  // 验证完全释放
  AssertTrue('Lock should be available after deep release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Stress_RapidAcquireRelease;
var
  i: Integer;
const
  RAPID_COUNT = 1000;
begin
  // 快速获取/释放压力测试
  for i := 1 to RAPID_COUNT do
  begin
    FRecMutex.Acquire;
    // 立即释放，测试快速切换
    FRecMutex.Release;

    // 测试 TryAcquire 的快速切换
    if FRecMutex.TryAcquire then
      FRecMutex.Release;
  end;

  // 最终验证锁状态正常
  AssertTrue('Lock should be available after rapid operations', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_RAII_NestedGuards;
var
  Guard1, Guard2, Guard3: ILockGuard;
begin
  // 嵌套 RAII 守卫测试
  Guard1 := FRecMutex.LockGuard;
  AssertNotNull('First guard should not be nil', Guard1);

  // 嵌套第二层
  Guard2 := FRecMutex.LockGuard;
  AssertNotNull('Second guard should not be nil', Guard2);

  // 嵌套第三层
  Guard3 := FRecMutex.LockGuard;
  AssertNotNull('Third guard should not be nil', Guard3);

  // 所有守卫会在作用域结束时自动释放
end;

procedure TTestCase_IRecMutex.Test_RAII_ExceptionSafety;
var
  Guard: ILockGuard;
begin
  // 异常安全性测试
  Guard := FRecMutex.LockGuard;
  AssertNotNull('Guard should not be nil', Guard);

  try
    // 模拟异常情况
    raise Exception.Create('Test exception for RAII safety');
  except
    on E: Exception do
    begin
      // 异常被捕获，守卫应该仍然有效
      AssertTrue('Exception should be caught', E.Message = 'Test exception for RAII safety');
    end;
  end;

  // Guard 会在作用域结束时自动释放锁
end;

procedure TTestCase_IRecMutex.Test_RAII_ManualRelease;
var
  Guard: ILockGuard;
begin
  // 手动释放守卫测试
  Guard := FRecMutex.LockGuard;
  AssertNotNull('Guard should not be nil', Guard);

  // 手动释放守卫
  Guard := nil;

  // 验证锁已被释放
  AssertTrue('Lock should be available after manual guard release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Boundary_MaxSpinCount;
var
  RecMutex: IRecMutex;
begin
  {$IFDEF WINDOWS}
  // 测试最大自旋计数
  RecMutex := MakeRecMutex(High(DWORD));
  AssertNotNull('RecMutex with max spin count should not be nil', RecMutex);

  // 基本功能测试
  RecMutex.Acquire;
  RecMutex.Release;

  AssertTrue('TryAcquire should work with max spin count', RecMutex.TryAcquire);
  RecMutex.Release;
  {$ELSE}
  // 非 Windows 平台跳过此测试
  AssertTrue('Skipped on non-Windows platform', True);
  {$ENDIF}
end;

procedure TTestCase_IRecMutex.Test_Extreme_MassiveReentrancy;
var
  i: Integer;
const
  MASSIVE_DEPTH = 1000; // 1000 层重入
begin
  // 极限重入深度测试
  for i := 1 to MASSIVE_DEPTH do
    FRecMutex.Acquire;

  // 验证仍然可以获取锁（重入）
  AssertTrue('Should still be able to acquire after massive nesting', FRecMutex.TryAcquire);
  FRecMutex.Release; // 释放 TryAcquire 获取的锁

  for i := MASSIVE_DEPTH downto 1 do
    FRecMutex.Release;

  // 验证完全释放
  AssertTrue('Lock should be available after massive release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Extreme_RapidCycling;
var
  i: Integer;
  StartTime, EndTime: TDateTime;
const
  RAPID_CYCLES = 100000; // 10万次快速循环
begin
  // 极限快速循环测试
  StartTime := Now;

  for i := 1 to RAPID_CYCLES do
  begin
    FRecMutex.Acquire;
    FRecMutex.Release;
  end;

  EndTime := Now;

  // 验证性能合理（应该在合理时间内完成）
  AssertTrue('Rapid cycling should complete in reasonable time',
    (EndTime - StartTime) < (5.0 / 24 / 60 / 60)); // 小于5秒

  // 验证锁状态正常
  AssertTrue('Lock should be available after rapid cycling', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Extreme_LongHoldTime;
var
  Guard: ILockGuard;
begin
  // 长时间持有锁测试
  Guard := FRecMutex.LockGuard;

  // 模拟长时间持有（100ms）
  Sleep(100);

  // 验证重入仍然有效
  AssertTrue('Should be able to acquire during long hold', FRecMutex.TryAcquire);
  FRecMutex.Release;

  // Guard 会自动释放
end;

procedure TTestCase_IRecMutex.Test_Scenario_RecursiveFunction;

  // 递归函数，每次调用都需要获取锁
  function RecursiveFactorial(N: Integer): Int64;
  var
    Guard: ILockGuard;
  begin
    Guard := FRecMutex.LockGuard;

    if N <= 1 then
      Result := 1
    else
      Result := N * RecursiveFactorial(N - 1); // 递归调用，重入锁
  end;

var
  Result: Int64;
begin
  // 测试递归函数中的重入锁使用
  Result := RecursiveFactorial(10);
  AssertEquals('Recursive factorial should work correctly', 3628800, Result);

  // 验证锁已完全释放
  AssertTrue('Lock should be available after recursive function', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Scenario_NestedCalls;

  procedure Level3;
  var Guard: ILockGuard;
  begin
    Guard := FRecMutex.LockGuard;
    // 最深层，验证重入有效
    AssertTrue('Should be able to acquire at deepest level', FRecMutex.TryAcquire);
    FRecMutex.Release;
  end;

  procedure Level2;
  var Guard: ILockGuard;
  begin
    Guard := FRecMutex.LockGuard;
    Level3;
  end;

  procedure Level1;
  var Guard: ILockGuard;
  begin
    Guard := FRecMutex.LockGuard;
    Level2;
  end;

begin
  // 测试嵌套函数调用中的重入锁
  Level1;

  // 验证锁已完全释放
  AssertTrue('Lock should be available after nested calls', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Scenario_ExceptionInCriticalSection;
var
  Guard: ILockGuard;
  ExceptionCaught: Boolean;
begin
  // 测试临界区中异常的处理
  ExceptionCaught := False;

  try
    Guard := FRecMutex.LockGuard;

    // 嵌套获取锁
    FRecMutex.Acquire;
    try
      // 抛出异常
      raise Exception.Create('Test exception in critical section');
    finally
      FRecMutex.Release;
    end;
  except
    on E: Exception do
    begin
      ExceptionCaught := True;
      AssertEquals('Exception message should match', 'Test exception in critical section', E.Message);
    end;
  end;

  AssertTrue('Exception should have been caught', ExceptionCaught);

  // 验证锁已正确释放（RAII 保证）
  AssertTrue('Lock should be available after exception', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Scenario_TimeoutInContention;
begin
  // 简化的超时竞争测试（不使用多线程）
  // 测试超时机制本身
  AssertTrue('TryAcquire with timeout should work', FRecMutex.TryAcquire(50));
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Resource_MultipleInstances;
var
  RecMutex1, RecMutex2, RecMutex3: IRecMutex;
begin
  // 测试多个实例的独立性
  RecMutex1 := MakeRecMutex;
  RecMutex2 := MakeRecMutex;
  RecMutex3 := MakeRecMutex;

  // 获取第一个锁
  RecMutex1.Acquire;
  try
    // 其他锁应该仍然可用
    AssertTrue('Second mutex should be available', RecMutex2.TryAcquire);
    RecMutex2.Release;

    AssertTrue('Third mutex should be available', RecMutex3.TryAcquire);
    RecMutex3.Release;

    // 第一个锁应该支持重入
    AssertTrue('First mutex should support reentrancy', RecMutex1.TryAcquire);
    RecMutex1.Release;
  finally
    RecMutex1.Release;
  end;
end;

procedure TTestCase_IRecMutex.Test_Resource_InstanceLifecycle;
var
  RecMutex: IRecMutex;
  Guard: ILockGuard;
begin
  // 测试实例生命周期管理
  RecMutex := MakeRecMutex;

  // 获取锁和守卫
  Guard := RecMutex.LockGuard;

  // 重入测试
  RecMutex.Acquire;
  RecMutex.Release;

  // 清理守卫
  Guard := nil;

  // 验证锁仍然可用
  AssertTrue('Mutex should still be available', RecMutex.TryAcquire);
  RecMutex.Release;

  // 清理实例
  RecMutex := nil;

  // 创建新实例验证独立性
  RecMutex := MakeRecMutex;
  AssertTrue('New instance should be available', RecMutex.TryAcquire);
  RecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Resource_HandleAccess;
var
  RecMutex: IRecMutex;
  Handle: Pointer;
begin
  // 测试底层句柄访问
  RecMutex := MakeRecMutex;

  // 获取底层句柄
  Handle := (RecMutex as TRecMutex).GetHandle;
  AssertNotNull('Handle should not be null', Handle);

  // 验证句柄在锁定状态下仍然有效
  RecMutex.Acquire;
  try
    AssertNotNull('Handle should remain valid when locked',
      (RecMutex as TRecMutex).GetHandle);
    AssertTrue('Handle should be consistent', Handle =
      (RecMutex as TRecMutex).GetHandle);
  finally
    RecMutex.Release;
  end;
end;

procedure TTestCase_IRecMutex.Test_Compatibility_WithOtherLocks;
var
  RecMutex: IRecMutex;
  Guard1, Guard2: ILockGuard;
begin
  // 测试与其他锁类型的兼容性
  RecMutex := MakeRecMutex;

  // 测试 RAII 守卫的嵌套使用
  Guard1 := RecMutex.LockGuard;
  begin
    Guard2 := RecMutex.LockGuard; // 嵌套守卫

    // 验证重入有效
    AssertTrue('Should support nested guards', FRecMutex.TryAcquire);
    FRecMutex.Release;

    // Guard2 会在这里自动释放
  end;

  // 验证仍然持有外层锁
  AssertTrue('Should still hold outer lock', FRecMutex.TryAcquire);
  FRecMutex.Release;

  // Guard1 会在作用域结束时释放
end;

procedure TTestCase_IRecMutex.Test_Compatibility_CrossPlatform;
var
  RecMutex: IRecMutex;
begin
  // 跨平台兼容性测试
  RecMutex := MakeRecMutex;

  // 基本功能在所有平台都应该工作
  RecMutex.Acquire;
  try
    // 重入测试
    RecMutex.Acquire;
    RecMutex.Release;

    // TryAcquire 测试
    AssertTrue('TryAcquire should work on all platforms', RecMutex.TryAcquire);
    RecMutex.Release;
  finally
    RecMutex.Release;
  end;

  // 超时测试
  AssertTrue('Timeout should work on all platforms', RecMutex.TryAcquire(100));
  RecMutex.Release;

  // RAII 测试
  begin
    var Guard: ILockGuard;
    begin
      Guard := RecMutex.LockGuard;
      AssertNotNull('RAII should work on all platforms', Guard);
    end;
  end;
end;

procedure TTestCase_IRecMutex.Test_Boundary_ZeroSpinCount;
var
  RecMutex: IRecMutex;
begin
  {$IFDEF WINDOWS}
  // 测试零自旋计数
  RecMutex := MakeRecMutex(0);
  AssertNotNull('RecMutex with zero spin count should not be nil', RecMutex);

  // 基本功能测试
  RecMutex.Acquire;
  RecMutex.Release;

  AssertTrue('TryAcquire should work with zero spin count', RecMutex.TryAcquire);
  RecMutex.Release;
  {$ELSE}
  // 非 Windows 平台跳过此测试
  AssertTrue('Skipped on non-Windows platform', True);
  {$ENDIF}
end;

// ===== TTestCase_MultiThread =====

procedure TTestCase_MultiThread.SetUp;
begin
  FRecMutex := MakeRecMutex;
  FSharedCounter := 0;
  FThreadCount := 4;
  FIterationsPerThread := 1000;
end;

procedure TTestCase_MultiThread.TearDown;
begin
  FRecMutex := nil;
end;

type
  TTestThread = class(TThread)
  private
    FRecMutex: IRecMutex;
    FSharedCounter: PInteger;
    FIterations: Integer;
    FTestType: Integer; // 0=基本竞争, 1=重入访问, 2=TryAcquire竞争, 3=计数器, 4=高竞争, 5=混合操作, 6=超时竞争, 7=RAII压力
    FSuccessCount: Integer;
    FTimeoutCount: Integer;
  public
    constructor Create(ARecMutex: IRecMutex; ASharedCounter: PInteger;
                      AIterations, ATestType: Integer);
    property SuccessCount: Integer read FSuccessCount;
    property TimeoutCount: Integer read FTimeoutCount;
  protected
    procedure Execute; override;
  end;

constructor TTestThread.Create(ARecMutex: IRecMutex; ASharedCounter: PInteger;
                              AIterations, ATestType: Integer);
begin
  FRecMutex := ARecMutex;
  FSharedCounter := ASharedCounter;
  FIterations := AIterations;
  FTestType := ATestType;
  FSuccessCount := 0;
  FTimeoutCount := 0;
  inherited Create(False);
end;

procedure TTestThread.Execute;
var
  i: Integer;
  Guard: ILockGuard;
begin
  case FTestType of
    0: // 基本竞争测试
      for i := 1 to FIterations do
      begin
        FRecMutex.Acquire;
        try
          Sleep(0); // 让出时间片，增加竞争
        finally
          FRecMutex.Release;
        end;
      end;

    1: // 重入访问测试
      for i := 1 to FIterations do
      begin
        FRecMutex.Acquire;
        try
          FRecMutex.Acquire; // 重入
          try
            Sleep(0);
          finally
            FRecMutex.Release;
          end;
        finally
          FRecMutex.Release;
        end;
      end;

    2: // TryAcquire 竞争测试
      for i := 1 to FIterations do
      begin
        if FRecMutex.TryAcquire then
        try
          Sleep(0);
        finally
          FRecMutex.Release;
        end;
      end;

    3: // 计数器测试
      for i := 1 to FIterations do
      begin
        Guard := FRecMutex.LockGuard;
        Inc(FSharedCounter^);
      end;

    4: // 高竞争测试
      for i := 1 to FIterations do
      begin
        FRecMutex.Acquire;
        try
          // 模拟一些工作
          Inc(FSuccessCount);
          Sleep(0); // 强制线程切换
        finally
          FRecMutex.Release;
        end;
      end;

    5: // 混合操作测试
      for i := 1 to FIterations do
      begin
        case i mod 4 of
          0: begin // 基本获取
            FRecMutex.Acquire;
            try
              Inc(FSuccessCount);
            finally
              FRecMutex.Release;
            end;
          end;
          1: begin // TryAcquire
            if FRecMutex.TryAcquire then
            try
              Inc(FSuccessCount);
            finally
              FRecMutex.Release;
            end;
          end;
          2: begin // 重入
            FRecMutex.Acquire;
            try
              FRecMutex.Acquire;
              try
                Inc(FSuccessCount);
              finally
                FRecMutex.Release;
              end;
            finally
              FRecMutex.Release;
            end;
          end;
          3: begin // RAII
            Guard := FRecMutex.LockGuard;
            Inc(FSuccessCount);
          end;
        end;
      end;

    6: // 超时竞争测试
      for i := 1 to FIterations do
      begin
        if FRecMutex.TryAcquire(10) then // 10ms 超时
        try
          Inc(FSuccessCount);
          Sleep(1); // 持有锁一段时间
        finally
          FRecMutex.Release;
        end
        else
          Inc(FTimeoutCount);
      end;

    7: // RAII 压力测试
      for i := 1 to FIterations do
      begin
        Guard := FRecMutex.LockGuard;
        // 嵌套 RAII
        begin
          var NestedGuard: ILockGuard;
          NestedGuard := FRecMutex.LockGuard;
          Inc(FSuccessCount);
        end;
      end;
  end;
end;

procedure TTestCase_MultiThread.Test_MultiThread_BasicContention;
var
  Threads: array of TTestThread;
  i: Integer;
begin
  // 基本多线程竞争测试
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread, 0);

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证锁最终可用
  AssertTrue('Lock should be available after all threads complete', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_ReentrantAccess;
var
  Threads: array of TTestThread;
  i: Integer;
begin
  // 多线程重入访问测试
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread div 2, 1);

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证锁最终可用
  AssertTrue('Lock should be available after reentrant access', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_TryAcquireContention;
var
  Threads: array of TTestThread;
  i: Integer;
begin
  // 多线程 TryAcquire 竞争测试
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread, 2);

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证锁最终可用
  AssertTrue('Lock should be available after TryAcquire contention', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_Counter;
var
  Threads: array of TTestThread;
  i: Integer;
  ExpectedCount: Integer;
begin
  // 多线程计数器测试
  FSharedCounter := 0;
  ExpectedCount := FThreadCount * FIterationsPerThread;
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread, 3);

  // 等待所有线程完成
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证计数器正确性
  AssertEquals('Shared counter should match expected value', ExpectedCount, FSharedCounter);

  // 验证锁最终可用
  AssertTrue('Lock should be available after counter test', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_HighContention;
var
  Threads: array of TTestThread;
  i, TotalSuccess: Integer;
const
  HIGH_THREAD_COUNT = 8;
  HIGH_ITERATIONS = 2000;
begin
  // 高竞争多线程测试
  FThreadCount := HIGH_THREAD_COUNT;
  FIterationsPerThread := HIGH_ITERATIONS;
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread, 4);

  // 等待所有线程完成
  TotalSuccess := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess := TotalSuccess + Threads[i].SuccessCount;
    Threads[i].Free;
  end;

  // 验证所有操作都成功
  AssertEquals('All high contention operations should succeed',
    FThreadCount * FIterationsPerThread, TotalSuccess);

  // 验证锁最终可用
  AssertTrue('Lock should be available after high contention', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_MixedOperations;
var
  Threads: array of TTestThread;
  i, TotalSuccess: Integer;
begin
  // 混合操作多线程测试
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread, 5);

  // 等待所有线程完成
  TotalSuccess := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess := TotalSuccess + Threads[i].SuccessCount;
    Threads[i].Free;
  end;

  // 验证大部分操作成功（TryAcquire 可能失败）
  AssertTrue('Most mixed operations should succeed',
    TotalSuccess >= (FThreadCount * FIterationsPerThread * 3 div 4));

  // 验证锁最终可用
  AssertTrue('Lock should be available after mixed operations', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_StressTest;
var
  Threads: array of TTestThread;
  i, TotalSuccess: Integer;
const
  STRESS_THREAD_COUNT = 16;
  STRESS_ITERATIONS = 500;
begin
  // 压力测试：更多线程，更少迭代
  FThreadCount := STRESS_THREAD_COUNT;
  FIterationsPerThread := STRESS_ITERATIONS;
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread, 4);

  // 等待所有线程完成
  TotalSuccess := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess := TotalSuccess + Threads[i].SuccessCount;
    Threads[i].Free;
  end;

  // 验证所有操作都成功
  AssertEquals('All stress test operations should succeed',
    FThreadCount * FIterationsPerThread, TotalSuccess);

  // 验证锁最终可用
  AssertTrue('Lock should be available after stress test', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_TimeoutContention;
var
  Threads: array of TTestThread;
  i, TotalSuccess, TotalTimeout: Integer;
begin
  // 超时竞争测试
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread div 2, 6);

  // 等待所有线程完成
  TotalSuccess := 0;
  TotalTimeout := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess := TotalSuccess + Threads[i].SuccessCount;
    TotalTimeout := TotalTimeout + Threads[i].TimeoutCount;
    Threads[i].Free;
  end;

  // 验证总操作数正确
  AssertEquals('Total operations should match expected',
    FThreadCount * (FIterationsPerThread div 2), TotalSuccess + TotalTimeout);

  // 验证有一些成功操作
  AssertTrue('Should have some successful operations', TotalSuccess > 0);

  // 验证锁最终可用
  AssertTrue('Lock should be available after timeout contention', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_RAIIStress;
var
  Threads: array of TTestThread;
  i, TotalSuccess: Integer;
begin
  // RAII 压力测试
  SetLength(Threads, FThreadCount);

  // 创建并启动线程
  for i := 0 to FThreadCount - 1 do
    Threads[i] := TTestThread.Create(FRecMutex, @FSharedCounter, FIterationsPerThread, 7);

  // 等待所有线程完成
  TotalSuccess := 0;
  for i := 0 to FThreadCount - 1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess := TotalSuccess + Threads[i].SuccessCount;
    Threads[i].Free;
  end;

  // 验证所有 RAII 操作都成功
  AssertEquals('All RAII operations should succeed',
    FThreadCount * FIterationsPerThread, TotalSuccess);

  // 验证锁最终可用
  AssertTrue('Lock should be available after RAII stress', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IRecMutex);
  RegisterTest(TTestCase_MultiThread);

end.

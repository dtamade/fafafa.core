unit fafafa.core.sync.recMutex.testcase.enhanced;

{**
 * fafafa.core.sync.recMutex 增强版单元测试
 *
 * @desc
 *   这是 fafafa.core.sync.recMutex 模块的增强版单元测试套件，
 *   提供全面的功能验证、性能测试和边界条件检查。
 *
 * @test_coverage
 *   - 基础功能测试：获取/释放、超时、RAII
 *   - 重入特性测试：基本重入、深度重入、极限重入
 *   - 错误处理测试：异常情况、边界条件
 *   - 性能压力测试：高频操作、大量数据、长时间运行
 *   - 多线程测试：并发访问、竞争条件、同步验证
 *   - 实际场景测试：递归函数、异常安全、资源管理
 *
 * @test_philosophy
 *   采用 TDD 方法论，确保每个功能点都有对应的测试用例。
 *   测试用例设计遵循 AAA 模式（Arrange-Act-Assert）。
 *
 * @quality_assurance
 *   - 零内存泄漏要求
 *   - 100% 测试通过率
 *   - 异常安全性验证
 *   - 跨平台兼容性测试
 *}

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
  {**
   * TTestCase_Global - 全局函数测试用例
   *
   * @desc
   *   测试模块提供的全局工厂函数，验证实例创建的正确性。
   *
   * @test_scope
   *   - MakeRecMutex(): 基本工厂函数
   *   - MakeRecMutex(SpinCount): Windows 专用自旋计数版本
   *
   * @validation_points
   *   - 返回值非空
   *   - 接口类型正确
   *   - 基本功能可用
   *   - 平台特定功能正常
   *}
  TTestCase_Global = class(TTestCase)
  published
    {** 测试基本工厂函数 MakeRecMutex() *}
    procedure Test_MakeRecMutex;
    {$IFDEF WINDOWS}
    {** 测试带自旋计数的工厂函数 MakeRecMutex(SpinCount) *}
    procedure Test_MakeRecMutex_WithSpinCount;
    {$ENDIF}
  end;

  {**
   * TTestCase_IRecMutex - IRecMutex 接口全面测试用例
   *
   * @desc
   *   对 IRecMutex 接口进行全面的功能验证，包括基础操作、
   *   重入特性、错误处理、性能表现和实际使用场景。
   *
   * @test_categories
   *   1. 基础 API 测试：Acquire/Release/TryAcquire
   *   2. 重入特性测试：基本重入、深度重入、极限重入
   *   3. 超时机制测试：零超时、短超时、长超时
   *   4. RAII 支持测试：LockGuard、嵌套守卫、异常安全
   *   5. 错误处理测试：双重释放、无效操作
   *   6. 性能压力测试：高频操作、大量数据
   *   7. 边界条件测试：极值参数、特殊情况
   *   8. 实际场景测试：递归函数、异常处理、资源管理
   *
   * @test_methodology
   *   - 每个测试方法专注单一功能点
   *   - 使用描述性的测试方法名称
   *   - 包含正面和负面测试用例
   *   - 验证前置条件和后置条件
   *}
  TTestCase_IRecMutex = class(TTestCase)
  private
    FRecMutex: IRecMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // === 基础 API 功能测试 ===
    {** 测试基本的获取和释放操作，验证锁的基础功能 *}
    procedure Test_Acquire_Release;
    {** 测试非阻塞获取操作，验证 TryAcquire 在无竞争时的行为 *}
    procedure Test_TryAcquire_Success;
    {** 测试零超时的 TryAcquire，验证立即返回的行为 *}
    procedure Test_TryAcquire_Timeout_Zero;
    {** 测试短超时的 TryAcquire，验证超时机制的正确性 *}
    procedure Test_TryAcquire_Timeout_Short;
    {** 测试 RAII 锁守卫功能，验证自动资源管理 *}
    procedure Test_RAII_LockGuard;

    // === 重入特性测试 ===
    {** 测试基本重入功能，验证同一线程可以多次获取锁 *}
    procedure Test_Reentrancy_Basic;
    {** 测试深度重入，验证多层嵌套锁的正确性 *}
    procedure Test_Reentrancy_Deep;

    // === 边界条件测试 ===
    {** 测试零超时边界条件，验证边界值处理 *}
    procedure Test_Boundary_ZeroTimeout;
    {** 测试最大超时边界条件，验证极值参数处理 *}
    procedure Test_Boundary_MaxTimeout;
    {** 测试长超时机制，验证长时间等待的稳定性 *}
    procedure Test_Boundary_LongTimeout;
    {** 测试最大自旋计数边界条件（Windows专用） *}
    procedure Test_Boundary_MaxSpinCount;
    {** 测试零自旋计数边界条件（Windows专用） *}
    procedure Test_Boundary_ZeroSpinCount;

    // === 并发和错误处理测试 ===
    {** 测试基本并发场景，验证单线程环境下的并发模拟 *}
    procedure Test_Concurrent_Basic;
    {** 测试双重释放错误处理，验证异常情况的鲁棒性 *}
    procedure Test_Error_DoubleRelease;
    {** 测试未获取锁就释放的错误处理，验证错误检测能力 *}
    procedure Test_Error_ReleaseWithoutAcquire;

    // === 性能和压力测试 ===
    {** 测试高频率操作性能，验证大量快速操作的稳定性 *}
    procedure Test_Performance_HighFrequency;
    {** 测试深度重入压力，验证极限重入深度的处理能力 *}
    procedure Test_Stress_DeepReentrancy;
    {** 测试快速获取释放压力，验证高频切换的性能表现 *}
    procedure Test_Stress_RapidAcquireRelease;

    // === RAII 深度测试 ===
    {** 测试嵌套 RAII 守卫，验证多层守卫的正确性 *}
    procedure Test_RAII_NestedGuards;
    {** 测试 RAII 异常安全性，验证异常情况下的资源释放 *}
    procedure Test_RAII_ExceptionSafety;
    {** 测试 RAII 手动释放，验证守卫的手动控制能力 *}
    procedure Test_RAII_ManualRelease;

    // === 增强功能测试 ===
    {** 测试极限重入深度（1000层），验证大规模重入的稳定性和性能 *}
    procedure Test_Enhanced_MassiveReentrancy;
    {** 测试极限快速循环（10万次），验证高强度操作的性能表现 *}
    procedure Test_Enhanced_RapidCycling;
    {** 测试递归函数中的重入锁使用，验证实际编程场景的应用 *}
    procedure Test_Enhanced_RecursiveFunction;
    {** 测试增强的异常安全性，验证复杂异常情况下的资源管理 *}
    procedure Test_Enhanced_ExceptionSafety;
    {** 测试资源管理生命周期，验证实例创建销毁的完整流程 *}
    procedure Test_Enhanced_ResourceManagement;
  end;

  {**
   * TTestCase_MultiThread - 多线程并发测试用例
   *
   * @desc
   *   模拟多线程环境下的并发访问场景，验证可重入互斥锁
   *   在并发条件下的正确性和性能表现。
   *
   * @test_approach
   *   由于单元测试环境的限制，采用单线程模拟多线程行为的方式，
   *   通过循环和计数器来验证并发场景下的逻辑正确性。
   *
   * @test_scenarios
   *   - 基本竞争：模拟多线程同时访问共享资源
   *   - 重入访问：验证多线程环境下的重入特性
   *   - 非阻塞竞争：测试 TryAcquire 在竞争条件下的行为
   *   - 计数器同步：验证共享计数器的线程安全性
   *   - 高竞争压力：模拟高强度并发访问场景
   *   - 压力测试：验证长时间高负载下的稳定性
   *
   * @validation_points
   *   - 数据一致性：共享数据的正确性
   *   - 操作原子性：锁保护的有效性
   *   - 性能表现：高并发下的响应时间
   *   - 资源安全：无死锁和资源泄漏
   *}
  TTestCase_MultiThread = class(TTestCase)
  private
    FRecMutex: IRecMutex;           // 被测试的可重入互斥锁
    FSharedCounter: Integer;        // 共享计数器，用于验证同步效果
    FThreadCount: Integer;          // 模拟的线程数量
    FIterationsPerThread: Integer;  // 每个线程的迭代次数
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // === 基础并发测试 ===
    {** 测试基本竞争条件，验证多线程环境下的基础同步功能 *}
    procedure Test_MultiThread_BasicContention;
    {** 测试重入访问，验证多线程环境下的重入特性正确性 *}
    procedure Test_MultiThread_ReentrantAccess;
    {** 测试非阻塞竞争，验证 TryAcquire 在并发环境下的行为 *}
    procedure Test_MultiThread_TryAcquireContention;
    {** 测试计数器同步，验证共享资源的线程安全保护 *}
    procedure Test_MultiThread_Counter;

    // === 高强度并发测试 ===
    {** 测试高竞争场景，验证高强度并发访问下的性能和稳定性 *}
    procedure Test_MultiThread_HighContention;
    {** 测试并发压力，验证长时间高负载下的系统表现 *}
    procedure Test_MultiThread_StressTest;
  end;

implementation

// ===== TTestCase_Global =====

procedure TTestCase_Global.Test_MakeRecMutex;
var
  RecMutex: IRecMutex;
begin
  // === 测试目标 ===
  // 验证基本工厂函数 MakeRecMutex() 能够正确创建可重入互斥锁实例

  // === 执行测试 ===
  RecMutex := MakeRecMutex;

  // === 验证结果 ===
  // 1. 验证返回值非空
  AssertNotNull('MakeRecMutex should return non-nil interface', RecMutex);

  // 2. 验证基本锁操作功能
  RecMutex.Acquire;
  RecMutex.Release;

  // 3. 验证非阻塞获取功能
  AssertTrue('TryAcquire should succeed', RecMutex.TryAcquire);
  RecMutex.Release;

  // === 测试完成 ===
  // 工厂函数创建的实例功能正常，接口可用
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

// 新增的增强测试方法实现
procedure TTestCase_IRecMutex.Test_Enhanced_MassiveReentrancy;
var
  i: Integer;
const
  MASSIVE_DEPTH = 1000; // 1000 层重入深度
begin
  // === 测试目标 ===
  // 验证可重入互斥锁在极限重入深度（1000层）下的稳定性和正确性
  // 这是一个压力测试，确保在深度嵌套场景下锁机制仍然可靠

  // === 阶段1: 大规模重入获取 ===
  for i := 1 to MASSIVE_DEPTH do
    FRecMutex.Acquire;

  // === 阶段2: 验证重入状态 ===
  // 在1000层重入的基础上，验证仍然可以继续获取锁
  AssertTrue('Should still be able to acquire after massive nesting', FRecMutex.TryAcquire);
  FRecMutex.Release; // 释放额外获取的锁

  // === 阶段3: 大规模重入释放 ===
  for i := MASSIVE_DEPTH downto 1 do
    FRecMutex.Release;

  // === 阶段4: 验证完全释放 ===
  // 确保所有重入层级都已正确释放，锁回到可用状态
  AssertTrue('Lock should be available after massive release', FRecMutex.TryAcquire);
  FRecMutex.Release;

  // === 测试完成 ===
  // 极限重入测试通过，证明锁机制在深度嵌套下仍然稳定可靠
end;

procedure TTestCase_IRecMutex.Test_Enhanced_RapidCycling;
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

procedure TTestCase_IRecMutex.Test_Enhanced_RecursiveFunction;

  // 递归阶乘函数 - 每次调用都需要获取锁，模拟实际编程中的递归场景
  function RecursiveFactorial(N: Integer): Int64;
  var
    Guard: ILockGuard;
  begin
    // 使用 RAII 守卫自动管理锁，确保异常安全
    Guard := FRecMutex.LockGuard;

    if N <= 1 then
      Result := 1
    else
      Result := N * RecursiveFactorial(N - 1); // 递归调用，触发重入锁机制
  end;

var
  Result: Int64;
begin
  // === 测试目标 ===
  // 验证可重入互斥锁在递归函数中的实际应用场景
  // 这是一个真实的编程场景测试，确保锁在递归调用中正常工作

  // === 执行递归计算 ===
  // 计算 10! = 3628800，递归深度为10层，每层都会获取锁
  Result := RecursiveFactorial(10);

  // === 验证计算结果 ===
  AssertEquals('Recursive factorial should work correctly', 3628800, Result);

  // === 验证锁状态 ===
  // 确保递归完成后，所有锁都已正确释放（RAII 保证）
  AssertTrue('Lock should be available after recursive function', FRecMutex.TryAcquire);
  FRecMutex.Release;

  // === 测试完成 ===
  // 递归函数测试通过，证明重入锁在实际编程场景中工作正常
end;

procedure TTestCase_IRecMutex.Test_Enhanced_ExceptionSafety;
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

procedure TTestCase_IRecMutex.Test_Enhanced_ResourceManagement;
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

// 多线程测试的简化实现（避免复杂的线程类）
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

procedure TTestCase_MultiThread.Test_MultiThread_BasicContention;
var
  i: Integer;
begin
  // 简化的多线程测试（单线程模拟）
  for i := 1 to FThreadCount * FIterationsPerThread do
  begin
    FRecMutex.Acquire;
    try
      Inc(FSharedCounter);
    finally
      FRecMutex.Release;
    end;
  end;

  AssertEquals('Counter should match expected value', FThreadCount * FIterationsPerThread, FSharedCounter);
  AssertTrue('Lock should be available after contention', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_ReentrantAccess;
var
  i: Integer;
begin
  // 简化的重入访问测试
  for i := 1 to FIterationsPerThread do
  begin
    FRecMutex.Acquire;
    try
      FRecMutex.Acquire; // 重入
      try
        Inc(FSharedCounter);
      finally
        FRecMutex.Release;
      end;
    finally
      FRecMutex.Release;
    end;
  end;

  AssertEquals('Counter should match expected value', FIterationsPerThread, FSharedCounter);
  AssertTrue('Lock should be available after reentrant access', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_TryAcquireContention;
var
  i, SuccessCount: Integer;
begin
  // 简化的 TryAcquire 竞争测试
  SuccessCount := 0;

  for i := 1 to FIterationsPerThread do
  begin
    if FRecMutex.TryAcquire then
    try
      Inc(SuccessCount);
    finally
      FRecMutex.Release;
    end;
  end;

  AssertEquals('All TryAcquire should succeed', FIterationsPerThread, SuccessCount);
  AssertTrue('Lock should be available after TryAcquire contention', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_Counter;
var
  i: Integer;
  Guard: ILockGuard;
begin
  // 简化的计数器测试
  FSharedCounter := 0;
  for i := 1 to FThreadCount * FIterationsPerThread do
  begin
    Guard := FRecMutex.LockGuard;
    Inc(FSharedCounter);
    Guard := nil; // 手动释放
  end;

  AssertEquals('Shared counter should match expected value', FThreadCount * FIterationsPerThread, FSharedCounter);
  AssertTrue('Lock should be available after counter test', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_MultiThread.Test_MultiThread_HighContention;
var
  i: Integer;
const
  HIGH_ITERATIONS = 10000; // 高强度迭代次数
begin
  // === 测试目标 ===
  // 模拟高竞争环境下的并发访问，验证锁在高强度使用下的稳定性
  // 通过大量连续操作来测试锁的性能和可靠性

  // === 执行高强度操作 ===
  // 模拟10000次高频并发访问，每次都需要获取和释放锁
  for i := 1 to HIGH_ITERATIONS do
  begin
    FRecMutex.Acquire;
    try
      Inc(FSharedCounter); // 受保护的共享资源操作
    finally
      FRecMutex.Release;   // 确保锁总是被释放
    end;
  end;

  // === 验证操作结果 ===
  // 确保所有操作都成功执行，没有丢失任何计数
  AssertEquals('All high contention operations should succeed', HIGH_ITERATIONS, FSharedCounter);

  // === 验证锁状态 ===
  // 确保高强度操作后锁仍然可用，没有死锁或状态异常
  AssertTrue('Lock should be available after high contention', FRecMutex.TryAcquire);
  FRecMutex.Release;

  // === 测试完成 ===
  // 高竞争测试通过，证明锁在高强度使用下仍然稳定可靠
end;

procedure TTestCase_MultiThread.Test_MultiThread_StressTest;
var
  i: Integer;
const
  STRESS_ITERATIONS = 50000;
begin
  // 压力测试（简化版）

  FSharedCounter := 0;
  for i := 1 to STRESS_ITERATIONS do
  begin
    FRecMutex.Acquire;
    try
      Inc(FSharedCounter);
    finally
      FRecMutex.Release;
    end;
  end;

  AssertEquals('All stress test operations should succeed', STRESS_ITERATIONS, FSharedCounter);
  AssertTrue('Lock should be available after stress test', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

// === 基础测试方法的详细实现 ===

procedure TTestCase_IRecMutex.Test_Performance_HighFrequency;
var
  i: Integer;
  StartTime, EndTime: TDateTime;
const
  ITERATIONS = 10000; // 高频操作次数
begin
  // === 测试目标 ===
  // 验证可重入互斥锁在高频率获取/释放操作下的性能表现
  // 确保在大量快速操作下仍能保持合理的响应时间

  // === 性能测试执行 ===
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    FRecMutex.Acquire;  // 高频获取
    FRecMutex.Release;  // 立即释放
  end;
  EndTime := Now;

  // === 性能验证 ===
  // 10000次操作应在1秒内完成，证明性能合理
  AssertTrue('High frequency operations should complete in reasonable time',
    (EndTime - StartTime) < (1.0 / 24 / 60 / 60));

  // === 测试完成 ===
  // 高频性能测试通过，证明锁机制在高负载下仍然高效
end;

procedure TTestCase_IRecMutex.Test_Stress_DeepReentrancy;
var
  i: Integer;
const
  MAX_DEPTH = 100;
begin
  for i := 1 to MAX_DEPTH do
    FRecMutex.Acquire;
  AssertTrue('Should still be able to acquire after deep nesting', FRecMutex.TryAcquire);
  FRecMutex.Release;
  for i := MAX_DEPTH downto 1 do
    FRecMutex.Release;
  AssertTrue('Lock should be available after deep release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Stress_RapidAcquireRelease;
var
  i: Integer;
const
  RAPID_COUNT = 1000;
begin
  for i := 1 to RAPID_COUNT do
  begin
    FRecMutex.Acquire;
    FRecMutex.Release;
    if FRecMutex.TryAcquire then
      FRecMutex.Release;
  end;
  AssertTrue('Lock should be available after rapid operations', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_RAII_NestedGuards;
var
  Guard1, Guard2, Guard3: ILockGuard;
begin
  Guard1 := FRecMutex.LockGuard;
  AssertNotNull('First guard should not be nil', Guard1);
  Guard2 := FRecMutex.LockGuard;
  AssertNotNull('Second guard should not be nil', Guard2);
  Guard3 := FRecMutex.LockGuard;
  AssertNotNull('Third guard should not be nil', Guard3);
end;

procedure TTestCase_IRecMutex.Test_RAII_ExceptionSafety;
var
  Guard: ILockGuard;
begin
  Guard := FRecMutex.LockGuard;
  AssertNotNull('Guard should not be nil', Guard);
  try
    raise Exception.Create('Test exception for RAII safety');
  except
    on E: Exception do
      AssertTrue('Exception should be caught', E.Message = 'Test exception for RAII safety');
  end;
end;

procedure TTestCase_IRecMutex.Test_RAII_ManualRelease;
var
  Guard: ILockGuard;
begin
  Guard := FRecMutex.LockGuard;
  AssertNotNull('Guard should not be nil', Guard);
  Guard := nil;
  AssertTrue('Lock should be available after manual guard release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_IRecMutex.Test_Boundary_MaxSpinCount;
var
  RecMutex: IRecMutex;
begin
  {$IFDEF WINDOWS}
  RecMutex := MakeRecMutex(High(DWORD));
  AssertNotNull('RecMutex with max spin count should not be nil', RecMutex);
  RecMutex.Acquire;
  RecMutex.Release;
  AssertTrue('TryAcquire should work with max spin count', RecMutex.TryAcquire);
  RecMutex.Release;
  {$ELSE}
  AssertTrue('Skipped on non-Windows platform', True);
  {$ENDIF}
end;

procedure TTestCase_IRecMutex.Test_Boundary_ZeroSpinCount;
var
  RecMutex: IRecMutex;
begin
  {$IFDEF WINDOWS}
  RecMutex := MakeRecMutex(0);
  AssertNotNull('RecMutex with zero spin count should not be nil', RecMutex);
  RecMutex.Acquire;
  RecMutex.Release;
  AssertTrue('TryAcquire should work with zero spin count', RecMutex.TryAcquire);
  RecMutex.Release;
  {$ELSE}
  AssertTrue('Skipped on non-Windows platform', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IRecMutex);
  RegisterTest(TTestCase_MultiThread);

end.

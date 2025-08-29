unit fafafa.core.sync.spin.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fpcunit, testregistry,
  fafafa.core.sync.spin, fafafa.core.sync.base, fafafa.core.sync.spin.base;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeSpinLock;
  end;

  // TSpinLock 类测试
  TTestCase_TSpinLock = class(TTestCase)
  private
    FSpinLock: ISpinLock;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本 API 测试
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire_Success;
    procedure Test_TryAcquire_Timeout_Zero;
    procedure Test_TryAcquire_Timeout_Short;

    // 改进接口测试
    procedure Test_GetMaxSpins_SetMaxSpins;
    procedure Test_IsCurrentThreadOwner;
    procedure Test_GetLockState;
    procedure Test_ErrorHandling;
    procedure Test_GetOwnerThread;

    // 边界测试
    procedure Test_Boundary_MinMaxSpins;
    procedure Test_Boundary_ZeroTimeout;
    procedure Test_Boundary_MaxTimeout;

    // 退避策略测试
    procedure Test_BackoffStrategy_Linear;
    procedure Test_BackoffStrategy_Exponential;
    procedure Test_BackoffStrategy_Adaptive;

    // 简单性能测试
    procedure Test_Performance_Basic;

    // 调试功能测试
    procedure Test_Debug_HoldDuration;
    procedure Test_Debug_DeadlockDetection;

    // 统计接口测试
    procedure Test_Stats_Interface;
    procedure Test_Stats_BasicOperations;
    procedure Test_Stats_ContentionRate;
    procedure Test_Stats_Reset;

    // 调试接口测试
    procedure Test_Debug_Interface;
    procedure Test_Debug_Info;

    // RAII 守卫测试
    procedure Test_RAII_Lock;
    procedure Test_RAII_TryLock;
    procedure Test_RAII_TryLock_Timeout;
    procedure Test_RAII_AutoRelease;
    procedure Test_RAII_ManualRelease;
    procedure Test_RAII_InvalidGuard;

  end;

implementation

// ===== TTestCase_Global =====

procedure TTestCase_Global.Test_MakeSpinLock;
var
  L: ISpinLock;
begin
  L := MakeSpinLock;
  AssertNotNull(L);
end;

// ===== TTestCase_TSpinLock =====

procedure TTestCase_TSpinLock.SetUp;
begin
  inherited SetUp;
  FSpinLock := MakeSpinLock;
end;

procedure TTestCase_TSpinLock.TearDown;
begin
  FSpinLock := nil;
  inherited TearDown;
end;

procedure TTestCase_TSpinLock.Test_Acquire_Release;
begin
  // 基本获取和释放
  FSpinLock.Acquire;
  FSpinLock.Release;
  
  // 多次获取和释放
  FSpinLock.Acquire;
  FSpinLock.Release;
  FSpinLock.Acquire;
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_TryAcquire_Success;
begin
  // 无竞争情况下应该成功
  AssertTrue(FSpinLock.TryAcquire);
  FSpinLock.Release;
  
  // 再次尝试
  AssertTrue(FSpinLock.TryAcquire);
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_TryAcquire_Timeout_Zero;
var
  StartT, Elapsed: QWord;
  Result1, Result2: Boolean;
begin
  // 先测试无参版本
  Result1 := FSpinLock.TryAcquire;
  AssertTrue('TryAcquire() should succeed', Result1);
  if Result1 then
    FSpinLock.Release;

  // 再测试超时为0的版本
  StartT := GetTickCount64;
  Result2 := FSpinLock.TryAcquire(0);
  Elapsed := GetTickCount64 - StartT;

  AssertTrue('TryAcquire(0) should succeed like TryAcquire()', Result2);
  AssertTrue('elapsed='+IntToStr(Elapsed), Elapsed < 10);
  if Result2 then
    FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_TryAcquire_Timeout_Short;
var
  StartT, Elapsed: QWord;
begin
  // 短超时测试
  StartT := GetTickCount64;
  AssertTrue(FSpinLock.TryAcquire(50));
  Elapsed := GetTickCount64 - StartT;
  AssertTrue('elapsed='+IntToStr(Elapsed), Elapsed < 30);
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_Performance_Basic;
const
  N = 1000;
var
  L: ISpinLock;
  T: QWord;
  I: Integer;
begin
  L := MakeSpinLock;

  T := GetTickCount64;
  for I := 1 to N do
  begin
    L.Acquire;
    L.Release;
  end;
  T := GetTickCount64 - T;

  // 基本健全性检查：1000次操作应该在合理时间内完成
  AssertTrue('time='+IntToStr(T), T < 1000);
end;

// ===== 简化接口测试 =====

procedure TTestCase_TSpinLock.Test_GetMaxSpins_SetMaxSpins;
begin
  AssertEquals('Default max spins', 64, FSpinLock.GetMaxSpins);

  FSpinLock.SetMaxSpins(512);
  AssertEquals('Updated max spins', 512, FSpinLock.GetMaxSpins);
end;

procedure TTestCase_TSpinLock.Test_IsCurrentThreadOwner;
begin
  // 初始状态应该是当前线程不拥有锁
  AssertFalse('Initial state: current thread should not own lock', FSpinLock.IsCurrentThreadOwner);

  // 获取锁后当前线程应该拥有锁
  FSpinLock.Acquire;
  {$IFDEF DEBUG}
  AssertTrue('After acquire: current thread should own lock', FSpinLock.IsCurrentThreadOwner);
  {$ENDIF}

  // 释放锁后当前线程应该不拥有锁
  FSpinLock.Release;
  AssertFalse('After release: current thread should not own lock', FSpinLock.IsCurrentThreadOwner);
end;

procedure TTestCase_TSpinLock.Test_GetLockState;
begin
  // 初始状态应该是未锁定
  {$IFDEF DEBUG}
  AssertEquals('Initial state should be unlocked', 0, FSpinLock.GetLockState);
  {$ELSE}
  AssertEquals('Non-debug mode should return unknown state', -1, FSpinLock.GetLockState);
  {$ENDIF}

  // 获取锁后应该是锁定状态
  FSpinLock.Acquire;
  {$IFDEF DEBUG}
  AssertEquals('After acquire should be locked', 1, FSpinLock.GetLockState);
  {$ENDIF}

  // 释放锁后应该是未锁定状态
  FSpinLock.Release;
  {$IFDEF DEBUG}
  AssertEquals('After release should be unlocked', 0, FSpinLock.GetLockState);
  {$ENDIF}
end;

procedure TTestCase_TSpinLock.Test_ErrorHandling;
begin
  // 测试初始错误状态
  AssertEquals('Initial error should be none', Ord(weNone), Ord(FSpinLock.GetLastError));

  // 测试清除错误
  FSpinLock.ClearLastError;
  AssertEquals('After clear error should be none', Ord(weNone), Ord(FSpinLock.GetLastError));

  // 测试错误消息
  AssertTrue('Error message should not be empty', FSpinLock.GetErrorMessage(weTimeout) <> '');
  AssertTrue('Error message should not be empty', FSpinLock.GetErrorMessage(weReentrancy) <> '');
end;



procedure TTestCase_TSpinLock.Test_GetOwnerThread;
{$IFDEF DEBUG}
var
  CurrentThread: TThreadID;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  CurrentThread := GetCurrentThreadId;

  // 初始状态
  AssertEquals('Initial owner should be 0', 0, FSpinLock.GetOwnerThread);

  FSpinLock.Acquire;
  AssertEquals('Owner should be current thread', CurrentThread, FSpinLock.GetOwnerThread);
  FSpinLock.Release;
  {$ELSE}
  // 在 Release 模式下，GetOwnerThread 不可用，跳过测试
  {$ENDIF}
end;

// ===== 边界测试 =====

procedure TTestCase_TSpinLock.Test_Boundary_MinMaxSpins;
var
  Policy: TSpinLockPolicy;
  L: ISpinLock;
begin
  // 测试最小自旋次数
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 1;
  L := MakeSpinLock(Policy);
  L.Acquire;
  L.Release;
  AssertEquals('Min spins should work', 1, L.GetMaxSpins);

  // 测试最大自旋次数
  Policy.MaxSpins := 10000;
  L := MakeSpinLock(Policy);
  L.Acquire;
  L.Release;
  AssertEquals('Max spins should work', 10000, L.GetMaxSpins);
end;

procedure TTestCase_TSpinLock.Test_Boundary_ZeroTimeout;
begin
  // 零超时应该立即返回
  AssertTrue('Zero timeout should succeed if not contended', FSpinLock.TryAcquire(0));
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_Boundary_MaxTimeout;
begin
  // 最大超时应该正常工作
  AssertTrue('Max timeout should work', FSpinLock.TryAcquire(High(Cardinal)));
  FSpinLock.Release;
end;

// ===== 退避策略测试 =====

procedure TTestCase_TSpinLock.Test_BackoffStrategy_Linear;
var
  Policy: TSpinLockPolicy;
  L: ISpinLock;
begin
  Policy := DefaultSpinLockPolicy;
  Policy.BackoffStrategy := sbsLinear;
  Policy.MaxBackoffMs := 10;
  Policy.MaxSpins := 32;
  L := MakeSpinLock(Policy);

  L.Acquire;
  L.Release;

  // 策略测试：确保锁能正常工作即可
  AssertEquals('Linear backoff max spins should be set', 32, L.GetMaxSpins);
end;

procedure TTestCase_TSpinLock.Test_BackoffStrategy_Exponential;
var
  Policy: TSpinLockPolicy;
  L: ISpinLock;
begin
  Policy := DefaultSpinLockPolicy;
  Policy.BackoffStrategy := sbsExponential;
  Policy.MaxBackoffMs := 20;
  Policy.MaxSpins := 48;
  L := MakeSpinLock(Policy);

  L.Acquire;
  L.Release;

  AssertEquals('Exponential backoff max spins should be set', 48, L.GetMaxSpins);
end;

procedure TTestCase_TSpinLock.Test_BackoffStrategy_Adaptive;
var
  Policy: TSpinLockPolicy;
  L: ISpinLock;
begin
  Policy := DefaultSpinLockPolicy;
  Policy.BackoffStrategy := sbsAdaptive;
  Policy.MaxBackoffMs := 15;
  Policy.MaxSpins := 96;
  L := MakeSpinLock(Policy);

  L.Acquire;
  L.Release;

  AssertEquals('Adaptive backoff max spins should be set', 96, L.GetMaxSpins);
end;

// ===== 调试功能测试 =====

procedure TTestCase_TSpinLock.Test_Debug_HoldDuration;
{$IFDEF DEBUG}
var
  duration: Cardinal;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  // 初始状态下持锁时间应该为 0
  duration := FSpinLock.GetHoldDurationMs;
  AssertEquals('Initial hold duration should be 0', 0, duration);

  // 获取锁
  FSpinLock.Acquire;

  // 短暂等待
  Sleep(10);

  // 检查持锁时间
  duration := FSpinLock.GetHoldDurationMs;
  AssertTrue('Hold duration should be > 0 after acquire', duration > 0);
  AssertTrue('Hold duration should be reasonable', duration < 1000);

  // 释放锁
  FSpinLock.Release;

  // 释放后持锁时间应该为 0
  duration := FSpinLock.GetHoldDurationMs;
  AssertEquals('Hold duration should be 0 after release', 0, duration);
  {$ELSE}
  // 在 Release 模式下，跳过测试
  {$ENDIF}
end;

procedure TTestCase_TSpinLock.Test_Debug_DeadlockDetection;
var
  policy: TSpinLockPolicy;
  L: ISpinLock;
begin
  // 创建启用死锁检测的锁
  policy := DefaultSpinLockPolicy;
  policy.EnableDeadlockDetection := True;
  policy.DeadlockTimeoutMs := 100; // 100ms 超时
  L := MakeSpinLock(policy);

  {$IFDEF DEBUG}
  // 验证死锁检测已启用
  AssertTrue('Deadlock detection should be enabled', L.IsDeadlockDetectionEnabled);
  {$ENDIF}

  // 正常的获取和释放应该不会触发死锁检测
  L.Acquire;
  L.Release;

  // 测试默认策略（死锁检测关闭）
  AssertFalse('Default policy should have deadlock detection disabled',
              DefaultSpinLockPolicy.EnableDeadlockDetection);
end;

// ===== 统计接口测试 =====

procedure TTestCase_TSpinLock.Test_Stats_Interface;
var
  L: ISpinLock;
  LWithStats: ISpinLockWithStats;
  Policy: TSpinLockPolicy;
begin
  // 创建启用统计的自旋锁
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  L := MakeSpinLock(Policy);

  // 测试能否获取统计接口
  AssertEquals('Should support ISpinLockWithStats interface',
               S_OK, L.QueryInterface(ISpinLockWithStats, LWithStats));
  AssertNotNull('Stats interface should not be null', LWithStats);

  // 测试统计开关
  AssertTrue('Stats should be enabled', LWithStats.IsStatsEnabled);

  // 测试禁用统计
  LWithStats.EnableStats(False);
  AssertFalse('Stats should be disabled', LWithStats.IsStatsEnabled);

  // 重新启用
  LWithStats.EnableStats(True);
  AssertTrue('Stats should be enabled again', LWithStats.IsStatsEnabled);
end;

procedure TTestCase_TSpinLock.Test_Stats_BasicOperations;
var
  L: ISpinLock;
  LWithStats: ISpinLockWithStats;
  Policy: TSpinLockPolicy;
  Stats: TSpinLockStats;
  i: Integer;
begin
  // 创建启用统计的自旋锁
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  L := MakeSpinLock(Policy);
  AssertEquals('Should get stats interface', S_OK, L.QueryInterface(ISpinLockWithStats, LWithStats));

  // 测试初始统计
  Stats := LWithStats.GetStats;
  AssertEquals('Initial acquire count should be 0', 0, Stats.AcquireCount);
  AssertEquals('Initial contention count should be 0', 0, Stats.ContentionCount);
  AssertEquals('Initial total spin count should be 0', 0, Stats.TotalSpinCount);

  // 执行一些锁操作
  for i := 1 to 5 do
  begin
    L.Acquire;
    L.Release;
  end;

  // 检查统计更新
  Stats := LWithStats.GetStats;
  AssertEquals('Acquire count should be 5', 5, Stats.AcquireCount);

  // 测试 TryAcquire
  AssertTrue('TryAcquire should succeed', L.TryAcquire);
  L.Release;

  Stats := LWithStats.GetStats;
  AssertEquals('Acquire count should be 6', 6, Stats.AcquireCount);
end;

procedure TTestCase_TSpinLock.Test_Stats_ContentionRate;
var
  L: ISpinLock;
  LWithStats: ISpinLockWithStats;
  Policy: TSpinLockPolicy;
  Rate: Double;
begin
  // 创建启用统计的自旋锁
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  L := MakeSpinLock(Policy);
  AssertEquals('Should get stats interface', S_OK, L.QueryInterface(ISpinLockWithStats, LWithStats));

  // 初始竞争率应该是 0
  Rate := LWithStats.GetContentionRate;
  AssertEquals('Initial contention rate should be 0', 0.0, Rate, 0.01);

  // 执行一些无竞争的操作
  L.Acquire;
  L.Release;
  L.TryAcquire;
  L.Release;

  // 竞争率应该仍然很低或为 0（因为没有实际竞争）
  Rate := LWithStats.GetContentionRate;
  AssertTrue('Contention rate should be low', Rate <= 100.0);

  // 测试自旋效率
  AssertTrue('Spin efficiency should be reasonable', LWithStats.GetSpinEfficiency >= 0.0);
end;

procedure TTestCase_TSpinLock.Test_Stats_Reset;
var
  L: ISpinLock;
  LWithStats: ISpinLockWithStats;
  Policy: TSpinLockPolicy;
  Stats: TSpinLockStats;
begin
  // 创建启用统计的自旋锁
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  L := MakeSpinLock(Policy);
  AssertEquals('Should get stats interface', S_OK, L.QueryInterface(ISpinLockWithStats, LWithStats));

  // 执行一些操作
  L.Acquire;
  L.Release;
  L.TryAcquire;
  L.Release;

  // 确认有统计数据
  Stats := LWithStats.GetStats;
  AssertTrue('Should have some acquire count', Stats.AcquireCount > 0);

  // 重置统计
  LWithStats.ResetStats;

  // 检查重置后的状态
  Stats := LWithStats.GetStats;
  AssertEquals('Acquire count should be 0 after reset', 0, Stats.AcquireCount);
  AssertEquals('Contention count should be 0 after reset', 0, Stats.ContentionCount);
  AssertEquals('Total spin count should be 0 after reset', 0, Stats.TotalSpinCount);
end;

// ===== 调试接口测试 =====

procedure TTestCase_TSpinLock.Test_Debug_Interface;
var
  L: ISpinLock;
  LDebug: ISpinLockDebug;
begin
  L := MakeSpinLock;

  // 测试能否获取调试接口
  AssertEquals('Should support ISpinLockDebug interface',
               S_OK, L.QueryInterface(ISpinLockDebug, LDebug));
  AssertNotNull('Debug interface should not be null', LDebug);

  // 测试基本调试方法
  AssertTrue('Debug info should not be empty', Length(LDebug.GetDebugInfo) > 0);
  AssertEquals('Initial hold count should be 0', 0, LDebug.GetHoldCount);
  AssertEquals('Initial current spins should be 0', 0, LDebug.GetCurrentSpins);
end;

procedure TTestCase_TSpinLock.Test_Debug_Info;
var
  L: ISpinLock;
  LDebug: ISpinLockDebug;
  DebugInfo: string;
begin
  L := MakeSpinLock;
  AssertEquals('Should get debug interface', S_OK, L.QueryInterface(ISpinLockDebug, LDebug));

  // 测试调试信息
  DebugInfo := LDebug.GetDebugInfo;
  AssertTrue('Debug info should contain SpinLock', Pos('SpinLock', DebugInfo) > 0);

  // 测试死锁信息
  AssertTrue('Deadlock info should not be empty', Length(LDebug.GetDeadlockInfo) > 0);

  // 测试获取时间信息
  AssertEquals('Initial last acquire time should be 0', 0, LDebug.GetLastAcquireTimeUs);
  AssertEquals('Initial last acquire spins should be 0', 0, LDebug.GetLastAcquireSpins);

  // 执行一次锁操作
  L.Acquire;
  L.Release;

  // 检查是否有更新（可能为 0，因为没有竞争）
  AssertTrue('Last acquire time should be non-negative', LDebug.GetLastAcquireTimeUs >= 0);
  AssertTrue('Last acquire spins should be non-negative', LDebug.GetLastAcquireSpins >= 0);
end;

// ===== RAII 守卫测试 =====

procedure TTestCase_TSpinLock.Test_RAII_Lock;
var
  L: ISpinLock;
  Guard: ISpinLockGuard;
begin
  L := MakeSpinLock;

  // 测试 Lock 方法创建守卫
  Guard := L.Lock;
  AssertNotNull('Guard should not be null', Guard);
  AssertTrue('Guard should be valid', Guard.IsValid);
  AssertTrue('Guard should reference the same lock', Guard.GetSpinLock = L);

  // 测试锁已被获取
  AssertFalse('Lock should be held, TryAcquire should fail', L.TryAcquire);

  // 手动释放守卫
  Guard.Release;
  AssertFalse('Guard should be invalid after release', Guard.IsValid);

  // 测试锁已被释放
  AssertTrue('Lock should be released, TryAcquire should succeed', L.TryAcquire);
  L.Release;
end;

procedure TTestCase_TSpinLock.Test_RAII_TryLock;
var
  L: ISpinLock;
  Guard1, Guard2: ISpinLockGuard;
begin
  L := MakeSpinLock;

  // 测试成功的 TryLock
  Guard1 := L.TryLock;
  AssertNotNull('First guard should not be null', Guard1);
  AssertTrue('First guard should be valid', Guard1.IsValid);

  // 测试失败的 TryLock（锁已被持有）
  Guard2 := L.TryLock;
  AssertNotNull('Second guard should not be null', Guard2);
  AssertFalse('Second guard should be invalid', Guard2.IsValid);

  // 释放第一个守卫
  Guard1.Release;

  // 现在 TryLock 应该成功
  Guard2 := L.TryLock;
  AssertTrue('Third guard should be valid', Guard2.IsValid);

  Guard2.Release;
end;

procedure TTestCase_TSpinLock.Test_RAII_TryLock_Timeout;
var
  L: ISpinLock;
  Guard1, Guard2: ISpinLockGuard;
begin
  L := MakeSpinLock;

  // 测试成功的带超时 TryLock
  Guard1 := L.TryLock(1000);
  AssertNotNull('First guard should not be null', Guard1);
  AssertTrue('First guard should be valid', Guard1.IsValid);

  // 测试超时的 TryLock
  Guard2 := L.TryLock(10); // 很短的超时
  AssertNotNull('Second guard should not be null', Guard2);
  AssertFalse('Second guard should be invalid due to timeout', Guard2.IsValid);

  Guard1.Release;
end;

procedure TTestCase_TSpinLock.Test_RAII_AutoRelease;
var
  L: ISpinLock;
  Guard: ISpinLockGuard;
begin
  L := MakeSpinLock;

  // 创建守卫并测试
  Guard := L.Lock;
  AssertTrue('Guard should be valid', Guard.IsValid);
  AssertFalse('Lock should be held', L.TryAcquire);

  // 显式清除守卫引用，触发析构
  Guard := nil;

  // 锁应该已经被自动释放
  AssertTrue('Lock should be auto-released', L.TryAcquire);
  L.Release;
end;

procedure TTestCase_TSpinLock.Test_RAII_ManualRelease;
var
  L: ISpinLock;
  Guard: ISpinLockGuard;
begin
  L := MakeSpinLock;
  Guard := L.Lock;

  // 测试手动释放
  AssertTrue('Guard should be valid initially', Guard.IsValid);
  Guard.Release;
  AssertFalse('Guard should be invalid after manual release', Guard.IsValid);

  // 测试重复释放不会出错
  Guard.Release; // 应该安全地忽略
  AssertFalse('Guard should still be invalid', Guard.IsValid);

  // 锁应该已被释放
  AssertTrue('Lock should be released', L.TryAcquire);
  L.Release;
end;

procedure TTestCase_TSpinLock.Test_RAII_InvalidGuard;
var
  L: ISpinLock;
  Guard: ISpinLockGuard;
begin
  L := MakeSpinLock;

  // 先获取锁
  L.Acquire;

  // TryLock 应该失败，返回无效守卫
  Guard := L.TryLock;
  AssertNotNull('Guard should not be null', Guard);
  AssertFalse('Guard should be invalid', Guard.IsValid);
  AssertTrue('Guard should still reference the lock', Guard.GetSpinLock = L);

  // 对无效守卫调用 Release 应该安全
  Guard.Release;
  AssertFalse('Guard should still be invalid', Guard.IsValid);

  L.Release;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TSpinLock);

end.

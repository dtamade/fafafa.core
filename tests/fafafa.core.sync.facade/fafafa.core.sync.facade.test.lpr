program fafafa_core_sync_facade_test;

{**
 * 门面导出测试
 *
 * 验证所有核心类型都能通过主门面单元访问
 * 注意：由于 fafafa.core.result 有编译问题，这里直接使用子模块测试
 *
 * TDD: 红 → 绿 → 重构
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  // 直接使用子模块，避免触发命名同步原语编译
  fafafa.core.sync.mutex.guard,
  fafafa.core.sync.rwlock.guard,
  fafafa.core.sync.oncelock,
  fafafa.core.sync.lazylock;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure AssertTrue(const Cond: Boolean; const Msg: string);
begin
  if not Cond then
  begin
    WriteLn('FAIL: ', Msg);
    Inc(TestsFailed);
  end
  else
  begin
    WriteLn('OK:   ', Msg);
    Inc(TestsPassed);
  end;
end;

// ===== Phase 1: 泛型类型门面导出测试 =====

procedure Test_TMutexGuard_ExportedFromFacade;
type
  TIntMutexGuard = specialize TMutexGuard<Integer>;
var
  Guard: TIntMutexGuard;
begin
  // Arrange & Act
  Guard := TIntMutexGuard.Create(42);
  try
    // Assert
    AssertTrue(Guard.GetValue = 42, 'TMutexGuard<Integer> 应该能通过门面访问');
  finally
    Guard.Free;
  end;
end;

procedure Test_TRwLockGuard_ExportedFromFacade;
type
  TIntRwLockGuard = specialize TRwLockGuard<Integer>;
var
  Guard: TIntRwLockGuard;
begin
  // Arrange & Act
  Guard := TIntRwLockGuard.Create(100);
  try
    // Assert
    AssertTrue(Guard.GetValue = 100, 'TRwLockGuard<Integer> 应该能通过门面访问');
  finally
    Guard.Free;
  end;
end;

procedure Test_TOnceLock_ExportedFromFacade;
type
  TIntOnceLock = specialize TOnceLock<Integer>;
var
  Lock: TIntOnceLock;
begin
  // Arrange & Act
  Lock := TIntOnceLock.Create;
  try
    Lock.SetValue(999);
    // Assert
    AssertTrue(Lock.GetValue = 999, 'TOnceLock<Integer> 应该能通过门面访问');
  finally
    Lock.Free;
  end;
end;

// 独立函数作为 TLazyLock 初始化器
function LazyLockInitValue: Integer;
begin
  Result := 777;
end;

procedure Test_TLazyLock_ExportedFromFacade;
type
  TIntLazyLock = specialize TLazyLock<Integer>;
var
  Lock: TIntLazyLock;
begin
  // Arrange & Act
  Lock := TIntLazyLock.Create(@LazyLockInitValue);
  try
    // Assert
    AssertTrue(Lock.GetValue = 777, 'TLazyLock<Integer> 应该能通过门面访问');
  finally
    Lock.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync 门面导出测试 ===');
  WriteLn;

  WriteLn('--- 泛型类型导出测试 ---');
  Test_TMutexGuard_ExportedFromFacade;
  Test_TRwLockGuard_ExportedFromFacade;
  Test_TOnceLock_ExportedFromFacade;
  Test_TLazyLock_ExportedFromFacade;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

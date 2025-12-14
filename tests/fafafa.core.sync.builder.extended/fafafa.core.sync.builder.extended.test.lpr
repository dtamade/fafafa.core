program fafafa_core_sync_builder_extended_test;

{**
 * Builder 扩展测试
 *
 * 验证新增的 Builder 类型：
 *   - TSpinBuilder
 *   - TParkerBuilder
 *   - TRecMutexBuilder
 *
 * TDD: 红 → 绿 → 重构
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.spin,
  fafafa.core.sync.parker,
  fafafa.core.sync.recMutex,
  fafafa.core.sync.builder;

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

// ===== TSpinBuilder 测试 =====

procedure Test_SpinBuilder_Build_ReturnsValidSpin;
var
  Spin: ISpin;
begin
  // Act
  Spin := SpinBuilder.Build;

  // Assert
  AssertTrue(Assigned(Spin), 'SpinBuilder.Build 应该返回有效的 ISpin');
end;

procedure Test_SpinBuilder_CanAcquireAndRelease;
var
  Spin: ISpin;
begin
  // Arrange
  Spin := SpinBuilder.Build;

  // Act & Assert
  Spin.Acquire;
  AssertTrue(True, 'SpinBuilder 创建的 Spin 应该能够 Acquire');
  Spin.Release;
  AssertTrue(True, 'SpinBuilder 创建的 Spin 应该能够 Release');
end;

// ===== TParkerBuilder 测试 =====

procedure Test_ParkerBuilder_Build_ReturnsValidParker;
var
  Parker: IParker;
begin
  // Act
  Parker := ParkerBuilder.Build;

  // Assert
  AssertTrue(Assigned(Parker), 'ParkerBuilder.Build 应该返回有效的 IParker');
end;

// ===== TRecMutexBuilder 测试 =====

procedure Test_RecMutexBuilder_Build_ReturnsValidRecMutex;
var
  RecMutex: IRecMutex;
begin
  // Act
  RecMutex := RecMutexBuilder.Build;

  // Assert
  AssertTrue(Assigned(RecMutex), 'RecMutexBuilder.Build 应该返回有效的 IRecMutex');
end;

procedure Test_RecMutexBuilder_CanReenter;
var
  RecMutex: IRecMutex;
begin
  // Arrange
  RecMutex := RecMutexBuilder.Build;

  // Act: 可重入锁应该允许同一线程多次获取
  RecMutex.Acquire;
  RecMutex.Acquire;  // 第二次获取应该成功

  // Assert
  AssertTrue(True, 'RecMutexBuilder 创建的锁应该支持重入');

  // Cleanup
  RecMutex.Release;
  RecMutex.Release;
end;

{$IFDEF WINDOWS}
procedure Test_RecMutexBuilder_WithSpinCount;
var
  RecMutex: IRecMutex;
begin
  // Act
  RecMutex := RecMutexBuilder.WithSpinCount(4000).Build;

  // Assert
  AssertTrue(Assigned(RecMutex), 'RecMutexBuilder.WithSpinCount.Build 应该返回有效的 IRecMutex');
end;
{$ENDIF}

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync Builder 扩展测试 ===');
  WriteLn;

  WriteLn('--- TSpinBuilder 测试 ---');
  Test_SpinBuilder_Build_ReturnsValidSpin;
  Test_SpinBuilder_CanAcquireAndRelease;

  WriteLn;
  WriteLn('--- TParkerBuilder 测试 ---');
  Test_ParkerBuilder_Build_ReturnsValidParker;

  WriteLn;
  WriteLn('--- TRecMutexBuilder 测试 ---');
  Test_RecMutexBuilder_Build_ReturnsValidRecMutex;
  Test_RecMutexBuilder_CanReenter;

  {$IFDEF WINDOWS}
  Test_RecMutexBuilder_WithSpinCount;
  {$ENDIF}

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

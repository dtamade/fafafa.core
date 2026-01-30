program fafafa_core_sync_mutex_guard_test;

{**
 * TMutexGuard<T> 测试
 *
 * 测试 Rust 风格的带数据保护的互斥锁容器
 *
 * 遵循 TDD 规范：红 → 绿 → 重构
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.mutex.guard;

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

procedure AssertEquals(Expected, Actual: Integer; const Msg: string);
begin
  AssertTrue(Expected = Actual, Msg + ' (期望: ' + IntToStr(Expected) + ', 实际: ' + IntToStr(Actual) + ')');
end;

// ===== Tests for TMutexGuard =====

procedure Test_MutexGuard_Create_WithInitialValue;
var
  Guard: specialize TMutexGuard<Integer>;
begin
  // Arrange & Act
  Guard := specialize TMutexGuard<Integer>.Create(42);
  try
    // Assert
    AssertTrue(Assigned(Guard), 'TMutexGuard 应该被成功创建');
  finally
    Guard.Free;
  end;
end;

procedure Test_MutexGuard_Lock_ReturnsValue;
var
  Guard: specialize TMutexGuard<Integer>;
  Value: Integer;
begin
  // Arrange
  Guard := specialize TMutexGuard<Integer>.Create(123);
  try
    // Act
    Value := Guard.Lock^;
    Guard.Unlock;
    
    // Assert
    AssertEquals(123, Value, 'Lock 应该返回初始值');
  finally
    Guard.Free;
  end;
end;

procedure Test_MutexGuard_Lock_AllowsModification;
var
  Guard: specialize TMutexGuard<Integer>;
  ValuePtr: PInteger;
begin
  // Arrange
  Guard := specialize TMutexGuard<Integer>.Create(100);
  try
    // Act: 获取锁并修改值
    ValuePtr := Guard.Lock;
    ValuePtr^ := 200;
    Guard.Unlock;
    
    // 再次获取确认修改
    ValuePtr := Guard.Lock;
    AssertEquals(200, ValuePtr^, '修改后的值应该为 200');
    Guard.Unlock;
  finally
    Guard.Free;
  end;
end;

procedure Test_MutexGuard_TryLock_Success;
var
  Guard: specialize TMutexGuard<Integer>;
  ValuePtr: PInteger;
begin
  // Arrange
  Guard := specialize TMutexGuard<Integer>.Create(50);
  try
    // Act
    ValuePtr := Guard.TryLock;
    
    // Assert
    AssertTrue(ValuePtr <> nil, 'TryLock 应该返回非 nil');
    AssertEquals(50, ValuePtr^, 'TryLock 应该返回正确的值');
    Guard.Unlock;
  finally
    Guard.Free;
  end;
end;

procedure Test_MutexGuard_TryLockTimeout_Success;
var
  Guard: specialize TMutexGuard<Integer>;
  ValuePtr: PInteger;
begin
  // Arrange
  Guard := specialize TMutexGuard<Integer>.Create(60);
  try
    // Act
    ValuePtr := Guard.TryLockTimeout(10);

    // Assert: 在空闲互斥上应与 TryLock 行为类似
    AssertTrue(ValuePtr <> nil, 'TryLockTimeout 在空闲互斥上应该成功');
    AssertEquals(60, ValuePtr^, 'TryLockTimeout 应该返回正确的值');
    Guard.Unlock;
  finally
    Guard.Free;
  end;
end;

procedure Test_MutexGuard_GetValue_ReturnsCurrentValue;
var
  Guard: specialize TMutexGuard<Integer>;
begin
  // Arrange
  Guard := specialize TMutexGuard<Integer>.Create(999);
  try
    // Act & Assert: 直接获取值（内部会加锁/解锁）
    AssertEquals(999, Guard.GetValue, 'GetValue 应该返回当前值');
  finally
    Guard.Free;
  end;
end;

procedure Test_MutexGuard_SetValue_UpdatesValue;
var
  Guard: specialize TMutexGuard<Integer>;
begin
  // Arrange
  Guard := specialize TMutexGuard<Integer>.Create(0);
  try
    // Act
    Guard.SetValue(777);
    
    // Assert
    AssertEquals(777, Guard.GetValue, 'SetValue 应该更新值');
  finally
    Guard.Free;
  end;
end;

procedure Test_MutexGuard_WithString;
var
  Guard: specialize TMutexGuard<string>;
  ValuePtr: ^string;
begin
  // Arrange
  Guard := specialize TMutexGuard<string>.Create('Hello');
  try
    // Act
    ValuePtr := Guard.Lock;
    AssertTrue(ValuePtr^ = 'Hello', 'String 值应该为 "Hello"');
    ValuePtr^ := 'World';
    Guard.Unlock;
    
    // Verify
    AssertTrue(Guard.GetValue = 'World', 'String 值应该被修改为 "World"');
  finally
    Guard.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync.mutex.guard 测试 ===');
  WriteLn;
  
  WriteLn('--- TMutexGuard<Integer> 测试 ---');
  Test_MutexGuard_Create_WithInitialValue;
  Test_MutexGuard_Lock_ReturnsValue;
  Test_MutexGuard_Lock_AllowsModification;
  Test_MutexGuard_TryLock_Success;
  Test_MutexGuard_TryLockTimeout_Success;
  Test_MutexGuard_GetValue_ReturnsCurrentValue;
  Test_MutexGuard_SetValue_UpdatesValue;
  
  WriteLn;
  WriteLn('--- TMutexGuard<string> 测试 ---');
  Test_MutexGuard_WithString;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');
  
  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

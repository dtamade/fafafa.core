program fafafa_core_sync_rwlock_guard_test;

{**
 * TRwLockGuard<T> 测试
 *
 * 测试 Rust 风格的带数据保护的读写锁容器
 *
 * 遵循 TDD：先红再绿
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.rwlock.base,  // 需要这个单元来捕获 TRwLockGuard 抛出的 ELockError
  fafafa.core.sync.rwlock.guard;

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

procedure AssertStrEquals(const Expected, Actual: string; const Msg: string);
begin
  AssertTrue(Expected = Actual, Msg + ' (期望: ' + Expected + ', 实际: ' + Actual + ')');
end;

// ===== Tests for TRwLockGuard =====

procedure Test_RwLockGuard_Create_WithInitialValue;
var
  Guard: specialize TRwLockGuard<Integer>;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(42);
  try
    AssertTrue(Assigned(Guard), 'TRwLockGuard 应该被成功创建');
  finally
    Guard.Free;
  end;
end;

procedure Test_RwLockGuard_ReadLock_ReturnsValue;
var
  Guard: specialize TRwLockGuard<Integer>;
  Value: Integer;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(123);
  try
    Value := Guard.ReadLock^;
    Guard.ReadUnlock;
    AssertEquals(123, Value, 'ReadLock 应该返回初始值');
  finally
    Guard.Free;
  end;
end;

procedure Test_RwLockGuard_WriteLock_AllowsModification;
var
  Guard: specialize TRwLockGuard<Integer>;
  P: PInteger;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(100);
  try
    P := Guard.WriteLock;
    P^ := 200;
    Guard.WriteUnlock;

    // 读锁确认
    P := Guard.ReadLock;
    AssertEquals(200, P^, '写入后的值应为 200');
    Guard.ReadUnlock;
  finally
    Guard.Free;
  end;
end;

procedure Test_RwLockGuard_TryReadLock_Success;
var
  Guard: specialize TRwLockGuard<Integer>;
  P: PInteger;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(50);
  try
    P := Guard.TryReadLock;
    AssertTrue(P <> nil, 'TryReadLock 应该返回非 nil');
    if P <> nil then
    begin
      AssertEquals(50, P^, 'TryReadLock 应该返回正确的值');
      Guard.ReadUnlock;
    end;
  finally
    Guard.Free;
  end;
end;

procedure Test_RwLockGuard_TryWriteLock_Success;
var
  Guard: specialize TRwLockGuard<Integer>;
  P: PInteger;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(1);
  try
    P := Guard.TryWriteLock;
    AssertTrue(P <> nil, 'TryWriteLock 应该返回非 nil');
    if P <> nil then
    begin
      P^ := 7;
      Guard.WriteUnlock;
    end;
    // 验证
    AssertEquals(7, Guard.GetValue, 'TryWriteLock 修改后的值应为 7');
  finally
    Guard.Free;
  end;
end;

// Guard 重入防御：多次 TryReadLock / TryWriteLock 应明确失败

procedure Test_RwLockGuard_TryReadLock_Twice_RaisesError;
var
  Guard: specialize TRwLockGuard<Integer>;
  P: PInteger;
  Raised: Boolean;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(10);
  try
    P := Guard.TryReadLock;
    AssertTrue(P <> nil, '第一次 TryReadLock 应该成功');
    Raised := False;
    try
      P := Guard.TryReadLock;
    except
      on E: fafafa.core.sync.rwlock.base.ELockError do
        Raised := True;
    end;
    AssertTrue(Raised, '第二次 TryReadLock 应该抛出 ELockError');
    Guard.ReadUnlock;
  finally
    Guard.Free;
  end;
end;

procedure Test_RwLockGuard_TryWriteLock_Twice_RaisesError;
var
  Guard: specialize TRwLockGuard<Integer>;
  P: PInteger;
  Raised: Boolean;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(10);
  try
    P := Guard.TryWriteLock;
    AssertTrue(P <> nil, '第一次 TryWriteLock 应该成功');
    Raised := False;
    try
      P := Guard.TryWriteLock;
    except
      on E: fafafa.core.sync.rwlock.base.ELockError do
        Raised := True;
    end;
    AssertTrue(Raised, '第二次 TryWriteLock 应该抛出 ELockError');
    Guard.WriteUnlock;
  finally
    Guard.Free;
  end;
end;

procedure Test_RwLockGuard_GetValue_And_SetValue;
var
  Guard: specialize TRwLockGuard<Integer>;
begin
  Guard := specialize TRwLockGuard<Integer>.Create(0);
  try
    Guard.SetValue(777);
    AssertEquals(777, Guard.GetValue, 'SetValue 应该更新并能通过 GetValue 读取');
  finally
    Guard.Free;
  end;
end;

procedure Test_RwLockGuard_WithString;
var
  Guard: specialize TRwLockGuard<string>;
  PS: ^string;
begin
  Guard := specialize TRwLockGuard<string>.Create('Hello');
  try
    PS := Guard.ReadLock;
    AssertStrEquals('Hello', PS^, '字符串初始应为 "Hello"');
    Guard.ReadUnlock;

    PS := Guard.WriteLock;
    PS^ := 'World';
    Guard.WriteUnlock;

    AssertStrEquals('World', Guard.GetValue, '字符串应被修改为 "World"');
  finally
    Guard.Free;
  end;
end;

// ===== Main =====
begin
  WriteLn('=== fafafa.core.sync.rwlock.guard 测试 ===');
  WriteLn;

  WriteLn('--- TRwLockGuard<Integer> 测试 ---');
  Test_RwLockGuard_Create_WithInitialValue;
  Test_RwLockGuard_ReadLock_ReturnsValue;
  Test_RwLockGuard_WriteLock_AllowsModification;
  Test_RwLockGuard_TryReadLock_Success;
  Test_RwLockGuard_TryWriteLock_Success;
  Test_RwLockGuard_GetValue_And_SetValue;
  Test_RwLockGuard_TryReadLock_Twice_RaisesError;
  Test_RwLockGuard_TryWriteLock_Twice_RaisesError;

  WriteLn;  
  WriteLn('--- TRwLockGuard<string> 测试 ---');
  Test_RwLockGuard_WithString;

  WriteLn;  
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then Halt(1) else Halt(0);
end.

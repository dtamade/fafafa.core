program fafafa_core_sync_oncelock_test;

{**
 * OnceLock 测试
 *
 * 测试 Rust 风格的线程安全懒初始化容器
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
  fafafa.core.sync.oncelock;

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

// ===== Tests for TOnceLock =====

procedure Test_OnceLock_InitiallyEmpty;
var
  Lock: specialize TOnceLock<Integer>;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    // Assert: 初始状态应该为空
    AssertTrue(not Lock.IsSet, 'OnceLock 初始状态应该为空');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_Set_SetsValue;
var
  Lock: specialize TOnceLock<Integer>;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    // Act
    Lock.SetValue(42);
    
    // Assert
    AssertTrue(Lock.IsSet, 'Set 后 OnceLock 应该有值');
    AssertEquals(42, Lock.GetValue, 'OnceLock 值应该为 42');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_Set_OnlyOnce;
var
  Lock: specialize TOnceLock<Integer>;
  Success1, Success2: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    // Act: 第一次设置
    Success1 := Lock.TrySet(42);
    // Act: 第二次设置（应该失败）
    Success2 := Lock.TrySet(100);
    
    // Assert
    AssertTrue(Success1, '第一次 TrySet 应该成功');
    AssertTrue(not Success2, '第二次 TrySet 应该失败');
    AssertEquals(42, Lock.GetValue, '值应该保持为第一次设置的 42');
  finally
    Lock.Free;
  end;
end;

// 全局初始化器用于 GetOrInit 测试
var
  G_InitCount: Integer = 0;

function GlobalInitializer: Integer;
begin
  Inc(G_InitCount);
  Result := 123;
end;

procedure Test_OnceLock_GetOrInit_InitializesOnce;
var
  Lock: specialize TOnceLock<Integer>;
  Value: Integer;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  G_InitCount := 0;
  try
    // Act: 第一次调用
    Value := Lock.GetOrInit(@GlobalInitializer);
    AssertEquals(123, Value, 'GetOrInit 第一次应返回初始化值');
    AssertEquals(1, G_InitCount, '初始化器应该被调用一次');
    
    // Act: 第二次调用
    Value := Lock.GetOrInit(@GlobalInitializer);
    AssertEquals(123, Value, 'GetOrInit 第二次应返回相同值');
    AssertEquals(1, G_InitCount, '初始化器不应该被再次调用');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_GetValue_ThrowsWhenEmpty;
var
  Lock: specialize TOnceLock<Integer>;
  GotException: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  GotException := False;
  try
    try
      // Act: 尝试获取未设置的值
      Lock.GetValue;
    except
      on E: Exception do
        GotException := True;
    end;
    
    // Assert
    AssertTrue(GotException, 'GetValue 空时应该抛出异常');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_TryGet_ReturnsNilWhenEmpty;
var
  Lock: specialize TOnceLock<Integer>;
  Ptr: PInteger;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    // Act
    Ptr := Lock.TryGet;
    
    // Assert
    AssertTrue(Ptr = nil, 'TryGet 空时应该返回 nil');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_TryGet_ReturnsPointerWhenSet;
var
  Lock: specialize TOnceLock<Integer>;
  Ptr: PInteger;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    Lock.SetValue(999);
    
    // Act
    Ptr := Lock.TryGet;
    
    // Assert
    AssertTrue(Ptr <> nil, 'TryGet 有值时应该返回非 nil');
    AssertEquals(999, Ptr^, 'TryGet 返回的指针应该指向正确的值');
  finally
    Lock.Free;
  end;
end;

// ===== Tests for TOnceLockString =====

procedure Test_OnceLockString_SetAndGet;
var
  Lock: specialize TOnceLock<string>;
begin
  // Arrange
  Lock := specialize TOnceLock<string>.Create;
  try
    // Act
    Lock.SetValue('Hello, World!');
    
    // Assert
    AssertTrue(Lock.IsSet, 'OnceLock<string> 应该有值');
    AssertTrue(Lock.GetValue = 'Hello, World!', 'OnceLock<string> 值应该正确');
  finally
    Lock.Free;
  end;
end;

// ===== Tests for new Rust-style methods =====

type
  ETestInitError = class(Exception);

var
  G_TryInitCount: Integer = 0;
  G_TryInitShouldFail: Boolean = False;

function TryInitializer: Integer;
begin
  Inc(G_TryInitCount);
  if G_TryInitShouldFail then
    raise ETestInitError.Create('Intentional initialization failure');
  Result := 456;
end;

procedure Test_OnceLock_GetOrTryInit_Success;
var
  Lock: specialize TOnceLock<Integer>;
  Value: Integer;
  Err: Exception;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  G_TryInitCount := 0;
  G_TryInitShouldFail := False;
  Err := nil;
  try
    // Act
    Value := Lock.GetOrTryInit(@TryInitializer, Err);
    
    // Assert
    AssertTrue(Err = nil, 'GetOrTryInit 成功时不应有错误');
    AssertEquals(456, Value, 'GetOrTryInit 应返回初始化值');
    AssertEquals(1, G_TryInitCount, '初始化器应被调用一次');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_GetOrTryInit_Failure;
var
  Lock: specialize TOnceLock<Integer>;
  Value: Integer;
  Err: Exception;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  G_TryInitCount := 0;
  G_TryInitShouldFail := True;
  Err := nil;
  try
    // Act
    Value := Lock.GetOrTryInit(@TryInitializer, Err);
    
    // Assert
    AssertTrue(Err <> nil, 'GetOrTryInit 失败时应有错误');
    AssertTrue(Err is ETestInitError, 'GetOrTryInit 返回的错误类型应与初始化器抛出的异常类型一致');
    AssertTrue(not Lock.IsSet, '初始化失败后 OnceLock 应保持为空');
    if Err <> nil then Err.Free;
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_Take_ReturnsAndClears;
var
  Lock: specialize TOnceLock<Integer>;
  Value: Integer;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    Lock.SetValue(789);
    
    // Act
    Value := Lock.Take;
    
    // Assert
    AssertEquals(789, Value, 'Take 应返回存储的值');
    AssertTrue(not Lock.IsSet, 'Take 后 OnceLock 应变为空');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_Take_ThrowsWhenEmpty;
var
  Lock: specialize TOnceLock<Integer>;
  GotException: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  GotException := False;
  try
    try
      // Act
      Lock.Take;
    except
      on E: Exception do
        GotException := True;
    end;
    
    // Assert
    AssertTrue(GotException, 'Take 空时应抛出异常');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_IntoInner_ReturnsValue;
var
  Lock: specialize TOnceLock<Integer>;
  Value: Integer;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    Lock.SetValue(321);
    
    // Act
    Value := Lock.IntoInner;
    
    // Assert
    AssertEquals(321, Value, 'IntoInner 应返回存储的值');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_WaitTimeout_ReturnsTrueWhenSet;
var
  Lock: specialize TOnceLock<Integer>;
  Result: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    Lock.SetValue(111);
    
    // Act
    Result := Lock.WaitTimeout(100);
    
    // Assert
    AssertTrue(Result, 'WaitTimeout 已设置时应立即返回 True');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_WaitTimeout_ReturnsFalseOnTimeout;
var
  Lock: specialize TOnceLock<Integer>;
  Result: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    // Act: 等待一个未设置的 OnceLock
    Result := Lock.WaitTimeout(50);
    
    // Assert
    AssertTrue(not Result, 'WaitTimeout 超时应返回 False');
  finally
    Lock.Free;
  end;
end;

// ===== 并发压力测试 =====

type
  TTestOnceLockInt = specialize TOnceLock<Integer>;

var
  G_ConcurrentLock: TTestOnceLockInt;
  G_ConcurrentInitCount: Integer;
  G_ConcurrentAllSameValue: Boolean;
  G_ConcurrentExpectedValue: Integer;

function ConcurrentInitializer: Integer;
begin
  InterlockedIncrement(G_ConcurrentInitCount);
  Sleep(10);  // 模拟慢速初始化
  Result := 999;
end;

type
  TGetOrInitThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TGetOrInitThread.Execute;
var
  Value: Integer;
begin
  Value := G_ConcurrentLock.GetOrInit(@ConcurrentInitializer);
  if Value <> G_ConcurrentExpectedValue then
    G_ConcurrentAllSameValue := False;
end;

procedure Test_OnceLock_Concurrent_GetOrInit;
const
  THREAD_COUNT = 10;
var
  Threads: array[0..THREAD_COUNT-1] of TThread;
  I: Integer;
begin
  // Arrange
  G_ConcurrentLock := TTestOnceLockInt.Create;
  G_ConcurrentInitCount := 0;
  G_ConcurrentAllSameValue := True;
  G_ConcurrentExpectedValue := 999;
  
  try
    // Act: 启动多个线程同时调用 GetOrInit
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TGetOrInitThread.Create(True);
    
    // 同时启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;
    
    // 等待所有线程完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;
    
    // Assert
    AssertTrue(G_ConcurrentAllSameValue, '所有线程应该获取到相同的值 999');
    AssertEquals(1, G_ConcurrentInitCount, '初始化器在并发环境下只应该被调用一次');
  finally
    G_ConcurrentLock.Free;
  end;
end;

type
  TTrySetThread = class(TThread)
  private
    FValue: Integer;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    property Value: Integer read FValue write FValue;
    property Success: Boolean read FSuccess;
  end;

procedure TTrySetThread.Execute;
begin
  FSuccess := G_ConcurrentLock.TrySet(FValue);
end;

var
  G_TrySetSuccessCount: Integer;

procedure Test_OnceLock_Concurrent_TrySet;
const
  THREAD_COUNT = 10;
var
  Threads: array[0..THREAD_COUNT-1] of TTrySetThread;
  I: Integer;
begin
  // Arrange
  G_ConcurrentLock := TTestOnceLockInt.Create;
  G_TrySetSuccessCount := 0;
  
  try
    // Act: 启动多个线程同时调用 TrySet
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I] := TTrySetThread.Create(True);
      Threads[I].Value := I + 100;
    end;
    
    // 同时启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;
    
    // 等待所有线程完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      if Threads[I].Success then
        Inc(G_TrySetSuccessCount);
      Threads[I].Free;
    end;
    
    // Assert
    AssertEquals(1, G_TrySetSuccessCount, '并发 TrySet 只应该有一个成功');
    AssertTrue(G_ConcurrentLock.IsSet, 'OnceLock 应该被设置');
  finally
    G_ConcurrentLock.Free;
  end;
end;

procedure Test_OnceLock_MemoryModel_StressTest;
const
  ITERATIONS = 1000;
var
  I: Integer;
  Lock: TTestOnceLockInt;
  Value: Integer;
begin
  // 压力测试：多次创建/初始化/读取/销毁
  for I := 1 to ITERATIONS do
  begin
    Lock := TTestOnceLockInt.Create;
    try
      Lock.SetValue(I);
      Value := Lock.GetValue;
      if Value <> I then
      begin
        AssertTrue(False, '内存模型测试失败: 读取到不正确的值');
        Exit;
      end;
    finally
      Lock.Free;
    end;
  end;
  AssertTrue(True, '内存模型压力测试通过 (' + IntToStr(ITERATIONS) + ' 次迭代)');
end;

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync.oncelock 测试 ===');
  WriteLn;
  
  WriteLn('--- TOnceLock<Integer> 测试 ---');
  Test_OnceLock_InitiallyEmpty;
  Test_OnceLock_Set_SetsValue;
  Test_OnceLock_Set_OnlyOnce;
  Test_OnceLock_GetOrInit_InitializesOnce;
  Test_OnceLock_GetValue_ThrowsWhenEmpty;
  Test_OnceLock_TryGet_ReturnsNilWhenEmpty;
  Test_OnceLock_TryGet_ReturnsPointerWhenSet;
  
  WriteLn;
  WriteLn('--- TOnceLock<string> 测试 ---');
  Test_OnceLockString_SetAndGet;
  
  WriteLn;
  WriteLn('--- Rust-style 新方法测试 ---');
  Test_OnceLock_GetOrTryInit_Success;
  Test_OnceLock_GetOrTryInit_Failure;
  Test_OnceLock_Take_ReturnsAndClears;
  Test_OnceLock_Take_ThrowsWhenEmpty;
  Test_OnceLock_IntoInner_ReturnsValue;
  Test_OnceLock_WaitTimeout_ReturnsTrueWhenSet;
  Test_OnceLock_WaitTimeout_ReturnsFalseOnTimeout;
  
  WriteLn;
  WriteLn('--- 并发压力测试 ---');
  Test_OnceLock_Concurrent_GetOrInit;
  Test_OnceLock_Concurrent_TrySet;
  Test_OnceLock_MemoryModel_StressTest;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');
  
  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

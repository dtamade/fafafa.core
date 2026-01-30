program fafafa_core_sync_lazylock_test;

{**
 * LazyLock 测试
 *
 * 测试 Rust 风格的线程安全懒加载容器
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

procedure AssertEquals(Expected, Actual: Integer; const Msg: string);
begin
  AssertTrue(Expected = Actual, Msg + ' (期望: ' + IntToStr(Expected) + ', 实际: ' + IntToStr(Actual) + ')');
end;

// ===== 全局初始化器 =====

var
  G_InitCount: Integer = 0;

function GlobalInit42: Integer;
begin
  Inc(G_InitCount);
  Result := 42;
end;

function GlobalInit100: Integer;
begin
  Inc(G_InitCount);
  Result := 100;
end;

// ===== Tests for TLazyLock =====

procedure Test_LazyLock_NotInitializedBeforeAccess;
var
  Lock: specialize TLazyLock<Integer>;
begin
  // Arrange
  G_InitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Assert: 创建后不应该立即初始化
    AssertEquals(0, G_InitCount, 'LazyLock 创建后不应该立即调用初始化器');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_InitializesOnFirstAccess;
var
  Lock: specialize TLazyLock<Integer>;
  Value: Integer;
begin
  // Arrange
  G_InitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act: 第一次访问
    Value := Lock.GetValue;
    
    // Assert
    AssertEquals(42, Value, 'LazyLock 应该返回初始化值');
    AssertEquals(1, G_InitCount, '初始化器应该被调用一次');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_OnlyInitializesOnce;
var
  Lock: specialize TLazyLock<Integer>;
  Value1, Value2: Integer;
begin
  // Arrange
  G_InitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act: 多次访问
    Value1 := Lock.GetValue;
    Value2 := Lock.GetValue;
    Lock.GetValue;  // 第三次
    
    // Assert
    AssertEquals(42, Value1, '第一次访问应该返回 42');
    AssertEquals(42, Value2, '第二次访问应该返回 42');
    AssertEquals(1, G_InitCount, '初始化器只应该被调用一次');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_ForceInitialize;
var
  Lock: specialize TLazyLock<Integer>;
begin
  // Arrange
  G_InitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act: 强制初始化
    Lock.Force;
    
    // Assert
    AssertEquals(1, G_InitCount, 'Force 应该触发初始化');
    AssertTrue(Lock.IsInitialized, 'Force 后应该已初始化');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_TryGet_ReturnsNilBeforeInit;
var
  Lock: specialize TLazyLock<Integer>;
  Ptr: PInteger;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act
    Ptr := Lock.TryGet;
    
    // Assert
    AssertTrue(Ptr = nil, 'TryGet 未初始化时应该返回 nil');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_TryGet_ReturnsPointerAfterInit;
var
  Lock: specialize TLazyLock<Integer>;
  Ptr: PInteger;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    Lock.Force;  // 强制初始化
    
    // Act
    Ptr := Lock.TryGet;
    
    // Assert
    AssertTrue(Ptr <> nil, 'TryGet 初始化后应该返回非 nil');
    AssertEquals(42, Ptr^, 'TryGet 返回的指针应该指向正确的值');
  finally
    Lock.Free;
  end;
end;

// ===== Tests for TLazyLock with string =====

var
  G_StringInitCount: Integer = 0;

function GlobalInitString: string;
begin
  Inc(G_StringInitCount);
  Result := 'Hello, LazyLock!';
end;

procedure Test_LazyLock_String;
var
  Lock: specialize TLazyLock<string>;
  Value: string;
begin
  // Arrange
  G_StringInitCount := 0;
  Lock := specialize TLazyLock<string>.Create(@GlobalInitString);
  try
    // Act
    Value := Lock.GetValue;
    
    // Assert
    AssertTrue(Value = 'Hello, LazyLock!', 'LazyLock<string> 应该返回正确的字符串');
    AssertEquals(1, G_StringInitCount, '字符串初始化器只应该被调用一次');
  finally
    Lock.Free;
  end;
end;

// ===== Tests for concurrent access =====

var
  G_ConcurrentInitCount: Integer = 0;
  G_ConcurrentLock: specialize TLazyLock<Integer>;

function ConcurrentInitializer: Integer;
begin
  // 模拟耗时初始化
  Sleep(50);
  InterlockedIncrement(G_ConcurrentInitCount);
  Result := 999;
end;

type
  TAccessThread = class(TThread)
  public
    ResultValue: Integer;
  protected
    procedure Execute; override;
  end;

procedure TAccessThread.Execute;
begin
  // 等待所有线程就绪
  Sleep(10);
  ResultValue := G_ConcurrentLock.GetValue;
end;

procedure Test_LazyLock_ConcurrentAccess_OnlyInitializesOnce;
var
  Threads: array[1..8] of TAccessThread;
  I: Integer;
  AllCorrect: Boolean;
begin
  // Arrange
  G_ConcurrentInitCount := 0;
  G_ConcurrentLock := specialize TLazyLock<Integer>.Create(@ConcurrentInitializer);
  try
    // 创建多个线程
    for I := 1 to 8 do
    begin
      Threads[I] := TAccessThread.Create(True);
      Threads[I].FreeOnTerminate := False;
    end;

    // Act: 同时启动所有线程
    for I := 1 to 8 do
      Threads[I].Start;

    // 等待所有线程完成
    for I := 1 to 8 do
    begin
      Threads[I].WaitFor;
    end;

    // Assert: 检查所有线程获取到相同的值
    AllCorrect := True;
    for I := 1 to 8 do
    begin
      if Threads[I].ResultValue <> 999 then
        AllCorrect := False;
      Threads[I].Free;
    end;

    AssertTrue(AllCorrect, '所有线程应该获取到相同的值 999');
    AssertEquals(1, G_ConcurrentInitCount, '初始化器在并发环境下只应该被调用一次');
  finally
    G_ConcurrentLock.Free;
  end;
end;

// ===== Tests for new Rust-style methods =====

procedure Test_LazyLock_ForceInit_ReturnsTrueOnFirstCall;
var
  Lock: specialize TLazyLock<Integer>;
  WasFirst: Boolean;
begin
  // Arrange
  G_InitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act
    WasFirst := Lock.ForceInit;
    
    // Assert
    AssertTrue(WasFirst, 'ForceInit 首次调用应返回 True');
    AssertEquals(1, G_InitCount, '初始化器应被调用一次');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_ForceInit_ReturnsFalseOnSubsequentCalls;
var
  Lock: specialize TLazyLock<Integer>;
  WasFirst1, WasFirst2: Boolean;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act
    WasFirst1 := Lock.ForceInit;
    WasFirst2 := Lock.ForceInit;
    
    // Assert
    AssertTrue(WasFirst1, 'ForceInit 首次调用应返回 True');
    AssertTrue(not WasFirst2, 'ForceInit 再次调用应返回 False');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_TryGetValue_ReturnsFalseBeforeInit;
var
  Lock: specialize TLazyLock<Integer>;
  Value: Integer;
  Success: Boolean;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act
    Success := Lock.TryGetValue(Value);
    
    // Assert
    AssertTrue(not Success, 'TryGetValue 未初始化时应返回 False');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_TryGetValue_ReturnsTrueAfterInit;
var
  Lock: specialize TLazyLock<Integer>;
  Value: Integer;
  Success: Boolean;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    Lock.Force;  // 初始化
    
    // Act
    Success := Lock.TryGetValue(Value);
    
    // Assert
    AssertTrue(Success, 'TryGetValue 初始化后应返回 True');
    AssertEquals(42, Value, 'TryGetValue 应返回正确的值');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_GetOrElse_ReturnsDefaultBeforeInit;
var
  Lock: specialize TLazyLock<Integer>;
  Value: Integer;
begin
  // Arrange
  G_InitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    // Act: 不触发初始化，返回默认值
    Value := Lock.GetOrElse(999);
    
    // Assert
    AssertEquals(999, Value, 'GetOrElse 未初始化时应返回默认值');
    AssertEquals(0, G_InitCount, 'GetOrElse 不应触发初始化');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_GetOrElse_ReturnsValueAfterInit;
var
  Lock: specialize TLazyLock<Integer>;
  Value: Integer;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@GlobalInit42);
  try
    Lock.Force;  // 初始化
    
    // Act
    Value := Lock.GetOrElse(999);
    
    // Assert
    AssertEquals(42, Value, 'GetOrElse 初始化后应返回实际值');
  finally
    Lock.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync.lazylock 测试 ===');
  WriteLn;
  
  WriteLn('--- TLazyLock<Integer> 测试 ---');
  Test_LazyLock_NotInitializedBeforeAccess;
  Test_LazyLock_InitializesOnFirstAccess;
  Test_LazyLock_OnlyInitializesOnce;
  Test_LazyLock_ForceInitialize;
  Test_LazyLock_TryGet_ReturnsNilBeforeInit;
  Test_LazyLock_TryGet_ReturnsPointerAfterInit;
  
  WriteLn;
  WriteLn('--- TLazyLock<string> 测试 ---');
  Test_LazyLock_String;
  
  WriteLn;
  WriteLn('--- Rust-style 新方法测试 ---');
  Test_LazyLock_ForceInit_ReturnsTrueOnFirstCall;
  Test_LazyLock_ForceInit_ReturnsFalseOnSubsequentCalls;
  Test_LazyLock_TryGetValue_ReturnsFalseBeforeInit;
  Test_LazyLock_TryGetValue_ReturnsTrueAfterInit;
  Test_LazyLock_GetOrElse_ReturnsDefaultBeforeInit;
  Test_LazyLock_GetOrElse_ReturnsValueAfterInit;
  
  WriteLn;
  WriteLn('--- 并发测试 ---');
  Test_LazyLock_ConcurrentAccess_OnlyInitializesOnce;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');
  
  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

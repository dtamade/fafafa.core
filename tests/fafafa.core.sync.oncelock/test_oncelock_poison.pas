program test_oncelock_poison;

{**
 * OnceLock Poison 机制测试
 *
 * 测试 OnceLock 的毒化（Poisoned）状态处理
 * 当初始化器抛出异常时，OnceLock 应该进入毒化状态
 *
 * 测试覆盖：
 * 1. 初始化失败导致毒化
 * 2. 毒化状态检测
 * 3. 毒化后的访问行为
 * 4. 多线程竞争下的毒化传播
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

// ===== Poison 机制测试 =====

type
  ETestInitError = class(Exception);

var
  G_FailingInitCount: Integer = 0;

function FailingInitializer: Integer;
begin
  Inc(G_FailingInitCount);
  raise ETestInitError.Create('Intentional initialization failure');
end;

procedure Test_OnceLock_Poison_InitializerThrows;
var
  Lock: specialize TOnceLock<Integer>;
  GotException: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  G_FailingInitCount := 0;
  GotException := False;
  try
    try
      // Act: 尝试使用会抛出异常的初始化器
      Lock.GetOrInit(@FailingInitializer);
    except
      on E: ETestInitError do
        GotException := True;
    end;

    // Assert
    AssertTrue(GotException, '初始化器抛出异常应该被传播');
    AssertEquals(1, G_FailingInitCount, '初始化器应该被调用一次');
    AssertTrue(Lock.IsPoisoned, 'OnceLock 应该进入毒化状态');
    AssertTrue(not Lock.IsSet, '毒化的 OnceLock 不应该被标记为已设置');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_Poison_SubsequentAccessThrows;
var
  Lock: specialize TOnceLock<Integer>;
  GotPoisonException: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  GotPoisonException := False;
  try
    // 先让 OnceLock 进入毒化状态
    try
      Lock.GetOrInit(@FailingInitializer);
    except
      on E: ETestInitError do
        ; // 忽略初始化异常
    end;

    // Act: 尝试访问毒化的 OnceLock
    try
      Lock.GetValue;
    except
      on E: Exception do
        GotPoisonException := True;
    end;

    // Assert
    AssertTrue(GotPoisonException, '访问毒化的 OnceLock 应该抛出异常');
  finally
    Lock.Free;
  end;
end;

procedure Test_OnceLock_Poison_TrySetAfterPoison;
var
  Lock: specialize TOnceLock<Integer>;
  Success: Boolean;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  try
    // 先让 OnceLock 进入毒化状态
    try
      Lock.GetOrInit(@FailingInitializer);
    except
      on E: ETestInitError do
        ; // 忽略初始化异常
    end;

    // Act: 尝试在毒化后设置值
    Success := Lock.TrySet(42);

    // Assert
    AssertTrue(not Success, '毒化后的 TrySet 应该失败');
    AssertTrue(Lock.IsPoisoned, 'OnceLock 应该保持毒化状态');
  finally
    Lock.Free;
  end;
end;

function RecoveryInitializer: Integer;
begin
  Result := 100;
end;

procedure Test_OnceLock_Poison_GetOrTryInitAfterPoison;
var
  Lock: specialize TOnceLock<Integer>;
  Value: Integer;
  Err: Exception;
begin
  // Arrange
  Lock := specialize TOnceLock<Integer>.Create;
  Err := nil;
  try
    // 先让 OnceLock 进入毒化状态
    try
      Lock.GetOrInit(@FailingInitializer);
    except
      on E: ETestInitError do
        ; // 忽略初始化异常
    end;

    // Act: 尝试在毒化后使用 GetOrTryInit
    Value := Lock.GetOrTryInit(@RecoveryInitializer, Err);

    // Assert
    AssertTrue(Err <> nil, 'GetOrTryInit 应该返回错误');
    AssertTrue(Lock.IsPoisoned, 'OnceLock 应该保持毒化状态');
    if Err <> nil then Err.Free;
  finally
    Lock.Free;
  end;
end;

// ===== 多线程 Poison 传播测试 =====

type
  TTestOnceLockInt = specialize TOnceLock<Integer>;

var
  G_ConcurrentPoisonLock: TTestOnceLockInt;
  G_ConcurrentPoisonCount: Integer;

type
  TPoisonTestThread = class(TThread)
  private
    FGotException: Boolean;
  protected
    procedure Execute; override;
  public
    property GotException: Boolean read FGotException;
  end;

procedure TPoisonTestThread.Execute;
begin
  FGotException := False;
  try
    G_ConcurrentPoisonLock.GetOrInit(@FailingInitializer);
  except
    on E: Exception do
    begin
      FGotException := True;
      InterlockedIncrement(G_ConcurrentPoisonCount);
    end;
  end;
end;

procedure Test_OnceLock_Poison_ConcurrentAccess;
const
  THREAD_COUNT = 5;
var
  Threads: array[0..THREAD_COUNT-1] of TPoisonTestThread;
  I: Integer;
  AllGotException: Boolean;
begin
  // Arrange
  G_ConcurrentPoisonLock := TTestOnceLockInt.Create;
  G_ConcurrentPoisonCount := 0;
  AllGotException := True;

  try
    // Act: 启动多个线程同时访问会失败的初始化器
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TPoisonTestThread.Create(True);

    // 同时启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    // 等待所有线程完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      if not Threads[I].GotException then
        AllGotException := False;
      Threads[I].Free;
    end;

    // Assert
    AssertTrue(AllGotException, '所有线程都应该捕获到异常');
    AssertTrue(G_ConcurrentPoisonCount >= 1, '至少有一个线程应该捕获到异常');
    AssertTrue(G_ConcurrentPoisonLock.IsPoisoned, 'OnceLock 应该处于毒化状态');
  finally
    G_ConcurrentPoisonLock.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== OnceLock Poison 机制测试 ===');
  WriteLn;

  WriteLn('--- 基本 Poison 测试 ---');
  Test_OnceLock_Poison_InitializerThrows;
  Test_OnceLock_Poison_SubsequentAccessThrows;
  Test_OnceLock_Poison_TrySetAfterPoison;
  Test_OnceLock_Poison_GetOrTryInitAfterPoison;

  WriteLn;
  WriteLn('--- 并发 Poison 传播测试 ---');
  Test_OnceLock_Poison_ConcurrentAccess;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

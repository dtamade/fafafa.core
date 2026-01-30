program test_lazylock_poison;

{**
 * LazyLock Poison 机制测试
 *
 * 测试 LazyLock 的毒化（Poisoned）状态处理
 * 当初始化器抛出异常时，LazyLock 应该进入毒化状态
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

procedure Test_LazyLock_Poison_InitializerThrows;
var
  Lock: specialize TLazyLock<Integer>;
  GotException: Boolean;
begin
  // Arrange
  G_FailingInitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@FailingInitializer);
  GotException := False;
  try
    try
      // Act: 尝试使用会抛出异常的初始化器
      Lock.GetValue;
    except
      on E: ETestInitError do
        GotException := True;
    end;

    // Assert
    AssertTrue(GotException, '初始化器抛出异常应该被传播');
    AssertEquals(1, G_FailingInitCount, '初始化器应该被调用一次');
    AssertTrue(Lock.IsPoisoned, 'LazyLock 应该进入毒化状态');
    AssertTrue(not Lock.IsInitialized, '毒化的 LazyLock 不应该被标记为已初始化');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_Poison_SubsequentAccessThrows;
var
  Lock: specialize TLazyLock<Integer>;
  GotPoisonException: Boolean;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@FailingInitializer);
  GotPoisonException := False;
  try
    // 先让 LazyLock 进入毒化状态
    try
      Lock.GetValue;
    except
      on E: ETestInitError do
        ; // 忽略初始化异常
    end;

    // Act: 尝试访问毒化的 LazyLock
    try
      Lock.GetValue;
    except
      on E: Exception do
        GotPoisonException := True;
    end;

    // Assert
    AssertTrue(GotPoisonException, '访问毒化的 LazyLock 应该抛出异常');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_Poison_ForceAfterPoison;
var
  Lock: specialize TLazyLock<Integer>;
  GotException: Boolean;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@FailingInitializer);
  GotException := False;
  try
    // 先让 LazyLock 进入毒化状态
    try
      Lock.GetValue;
    except
      on E: ETestInitError do
        ; // 忽略初始化异常
    end;

    // Act: 尝试在毒化后强制初始化
    try
      Lock.Force;
    except
      on E: Exception do
        GotException := True;
    end;

    // Assert
    AssertTrue(GotException, '毒化后的 Force 应该抛出异常');
    AssertTrue(Lock.IsPoisoned, 'LazyLock 应该保持毒化状态');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_Poison_TryGetAfterPoison;
var
  Lock: specialize TLazyLock<Integer>;
  Ptr: PInteger;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@FailingInitializer);
  try
    // 先让 LazyLock 进入毒化状态
    try
      Lock.GetValue;
    except
      on E: ETestInitError do
        ; // 忽略初始化异常
    end;

    // Act: 尝试在毒化后使用 TryGet
    Ptr := Lock.TryGet;

    // Assert
    AssertTrue(Ptr = nil, '毒化后的 TryGet 应该返回 nil');
    AssertTrue(Lock.IsPoisoned, 'LazyLock 应该保持毒化状态');
  finally
    Lock.Free;
  end;
end;

procedure Test_LazyLock_Poison_GetOrElseAfterPoison;
var
  Lock: specialize TLazyLock<Integer>;
  Value: Integer;
begin
  // Arrange
  Lock := specialize TLazyLock<Integer>.Create(@FailingInitializer);
  try
    // 先让 LazyLock 进入毒化状态
    try
      Lock.GetValue;
    except
      on E: ETestInitError do
        ; // 忽略初始化异常
    end;

    // Act: 尝试在毒化后使用 GetOrElse
    Value := Lock.GetOrElse(999);

    // Assert
    AssertEquals(999, Value, '毒化后的 GetOrElse 应该返回默认值');
    AssertTrue(Lock.IsPoisoned, 'LazyLock 应该保持毒化状态');
  finally
    Lock.Free;
  end;
end;

// ===== 多线程 Poison 传播测试 =====

type
  TTestLazyLockInt = specialize TLazyLock<Integer>;

var
  G_ConcurrentPoisonLock: TTestLazyLockInt;
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
    G_ConcurrentPoisonLock.GetValue;
  except
    on E: Exception do
    begin
      FGotException := True;
      InterlockedIncrement(G_ConcurrentPoisonCount);
    end;
  end;
end;

procedure Test_LazyLock_Poison_ConcurrentAccess;
const
  THREAD_COUNT = 5;
var
  Threads: array[0..THREAD_COUNT-1] of TPoisonTestThread;
  I: Integer;
  AllGotException: Boolean;
begin
  // Arrange
  G_ConcurrentPoisonLock := TTestLazyLockInt.Create(@FailingInitializer);
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
    AssertTrue(G_ConcurrentPoisonLock.IsPoisoned, 'LazyLock 应该处于毒化状态');
  finally
    G_ConcurrentPoisonLock.Free;
  end;
end;

// ===== 边界条件测试 =====

procedure Test_LazyLock_Poison_MultipleFailedAttempts;
var
  Lock: specialize TLazyLock<Integer>;
  I: Integer;
  ExceptionCount: Integer;
begin
  // Arrange
  G_FailingInitCount := 0;
  Lock := specialize TLazyLock<Integer>.Create(@FailingInitializer);
  ExceptionCount := 0;
  try
    // Act: 多次尝试访问会失败的初始化器
    for I := 1 to 5 do
    begin
      try
        Lock.GetValue;
      except
        on E: Exception do
          Inc(ExceptionCount);
      end;
    end;

    // Assert
    AssertEquals(5, ExceptionCount, '应该捕获到 5 次异常');
    AssertEquals(1, G_FailingInitCount, '初始化器只应该被调用一次');
    AssertTrue(Lock.IsPoisoned, 'LazyLock 应该保持毒化状态');
  finally
    Lock.Free;
  end;
end;

// ===== Main =====

begin
  WriteLn('=== LazyLock Poison 机制测试 ===');
  WriteLn;

  WriteLn('--- 基本 Poison 测试 ---');
  Test_LazyLock_Poison_InitializerThrows;
  Test_LazyLock_Poison_SubsequentAccessThrows;
  Test_LazyLock_Poison_ForceAfterPoison;
  Test_LazyLock_Poison_TryGetAfterPoison;
  Test_LazyLock_Poison_GetOrElseAfterPoison;

  WriteLn;
  WriteLn('--- 并发 Poison 传播测试 ---');
  Test_LazyLock_Poison_ConcurrentAccess;

  WriteLn;
  WriteLn('--- 边界条件测试 ---');
  Test_LazyLock_Poison_MultipleFailedAttempts;

  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

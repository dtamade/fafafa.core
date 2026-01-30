program test_mutex_poison;

{**
 * Mutex Poison 机制测试
 *
 * 测试 Mutex 的毒化（Poisoned）状态处理
 * 当线程在持有锁时发生异常，Mutex 应该进入毒化状态
 *
 * 测试覆盖：
 * 1. 手动标记毒化状态
 * 2. 毒化状态检测
 * 3. 毒化后的访问行为
 * 4. 毒化状态清除
 * 5. 多线程竞争下的毒化传播
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.mutex.base;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Assert(Condition: Boolean; const Msg: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('  ✓ ', Msg);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  ✗ FAIL: ', Msg);
  end;
end;

// ============================================================================
// 测试 1: 手动标记毒化状态
// ============================================================================
procedure Test_Mutex_MarkPoisoned;
var
  M: IMutex;
begin
  WriteLn('Test: Mutex Mark Poisoned');

  M := MakeMutex;

  // 初始状态不应该是毒化的
  Assert(not M.IsPoisoned, 'Mutex should not be poisoned initially');

  // 手动标记为毒化
  M.MarkPoisoned('Test exception');

  // 验证毒化状态
  Assert(M.IsPoisoned, 'Mutex should be poisoned after MarkPoisoned');
end;

// ============================================================================
// 测试 2: 毒化状态清除
// ============================================================================
procedure Test_Mutex_ClearPoison;
var
  M: IMutex;
begin
  WriteLn('Test: Mutex Clear Poison');

  M := MakeMutex;

  // 先标记为毒化
  M.MarkPoisoned('Test exception');
  Assert(M.IsPoisoned, 'Mutex should be poisoned after MarkPoisoned');

  // 清除毒化状态
  M.ClearPoison;
  Assert(not M.IsPoisoned, 'Mutex should not be poisoned after ClearPoison');
end;

// ============================================================================
// 测试 3: 毒化后获取锁会抛出异常
// ============================================================================
procedure Test_Mutex_PoisonedThrowsOnLock;
var
  M: IMutex;
  Guard: ILockGuard;
  GotException: Boolean;
begin
  WriteLn('Test: Mutex Poisoned Throws On Lock');

  M := MakeMutex;

  // 标记为毒化
  M.MarkPoisoned('Test exception');
  Assert(M.IsPoisoned, 'Mutex should be poisoned');

  // 毒化后获取锁应该抛出异常
  GotException := False;
  try
    Guard := M.Lock;
    Guard := nil;
  except
    on E: EMutexPoisonError do
      GotException := True;
  end;

  Assert(GotException, 'Lock should throw EMutexPoisonError when mutex is poisoned');
end;

// ============================================================================
// 测试 4: 多次标记毒化
// ============================================================================
procedure Test_Mutex_MultiplePoisoning;
var
  M: IMutex;
begin
  WriteLn('Test: Mutex Multiple Poisoning');

  M := MakeMutex;

  // 第一次标记
  M.MarkPoisoned('First exception');
  Assert(M.IsPoisoned, 'Mutex should be poisoned after first MarkPoisoned');

  // 第二次标记（应该仍然是毒化状态）
  M.MarkPoisoned('Second exception');
  Assert(M.IsPoisoned, 'Mutex should still be poisoned after second MarkPoisoned');
end;

// ============================================================================
// 测试 5: 清除后重新标记
// ============================================================================
procedure Test_Mutex_ClearAndRemark;
var
  M: IMutex;
begin
  WriteLn('Test: Mutex Clear And Remark');

  M := MakeMutex;

  // 标记为毒化
  M.MarkPoisoned('First exception');
  Assert(M.IsPoisoned, 'Mutex should be poisoned');

  // 清除毒化状态
  M.ClearPoison;
  Assert(not M.IsPoisoned, 'Mutex should not be poisoned after clear');

  // 重新标记为毒化
  M.MarkPoisoned('Second exception');
  Assert(M.IsPoisoned, 'Mutex should be poisoned again');
end;

// ============================================================================
// 测试 6: 多线程毒化传播
// ============================================================================
type
  TPoisonPropagationThread = class(TThread)
  private
    FMutex: IMutex;
    FSeenPoisoned: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex);
    property SeenPoisoned: Boolean read FSeenPoisoned;
  end;

constructor TPoisonPropagationThread.Create(AMutex: IMutex);
begin
  inherited Create(True);
  FMutex := AMutex;
  FSeenPoisoned := False;
  FreeOnTerminate := False;
end;

procedure TPoisonPropagationThread.Execute;
var
  Guard: ILockGuard;
  GotException: Boolean;
begin
  // 等待主线程标记毒化
  Sleep(100);

  // 尝试获取锁（毒化后会抛出异常）
  GotException := False;
  try
    Guard := FMutex.Lock;
    Guard := nil;
  except
    on E: EMutexPoisonError do
      GotException := True;
  end;

  // 检查是否看到毒化状态
  FSeenPoisoned := FMutex.IsPoisoned and GotException;
end;

procedure Test_Mutex_PoisonPropagation;
var
  M: IMutex;
  T: TPoisonPropagationThread;
begin
  WriteLn('Test: Mutex Poison Propagation');

  M := MakeMutex;

  // 启动线程
  T := TPoisonPropagationThread.Create(M);
  T.Start;

  // 标记为毒化
  M.MarkPoisoned('Test exception');

  // 等待线程完成
  T.WaitFor;

  // 验证线程看到了毒化状态
  Assert(T.SeenPoisoned, 'Thread should see poisoned state');

  T.Free;
end;

// ============================================================================
// 测试 7: TryLock 在毒化状态下的行为
// ============================================================================
procedure Test_Mutex_TryLockWhenPoisoned;
var
  M: IMutex;
  Guard: ILockGuard;
  GotException: Boolean;
begin
  WriteLn('Test: Mutex TryLock When Poisoned');

  M := MakeMutex;

  // 标记为毒化
  M.MarkPoisoned('Test exception');
  Assert(M.IsPoisoned, 'Mutex should be poisoned');

  // TryLock 在毒化状态下也会抛出异常
  GotException := False;
  try
    Guard := M.TryLock;
    Guard := nil;
  except
    on E: EMutexPoisonError do
      GotException := True;
  end;

  Assert(GotException, 'TryLock should throw EMutexPoisonError when mutex is poisoned');
end;

// ============================================================================
// 测试 8: 毒化状态持久性
// ============================================================================
procedure Test_Mutex_PoisonPersistence;
var
  M: IMutex;
  Guard: ILockGuard;
  I: Integer;
  GotException: Boolean;
begin
  WriteLn('Test: Mutex Poison Persistence');

  M := MakeMutex;

  // 标记为毒化
  M.MarkPoisoned('Test exception');
  Assert(M.IsPoisoned, 'Mutex should be poisoned');

  // 多次尝试获取锁，每次都应该抛出异常，毒化状态应该持久
  for I := 1 to 5 do
  begin
    GotException := False;
    try
      Guard := M.Lock;
      Guard := nil;
    except
      on E: EMutexPoisonError do
        GotException := True;
    end;

    Assert(GotException, 'Lock should throw EMutexPoisonError on attempt ' + IntToStr(I));
    Assert(M.IsPoisoned, 'Mutex should remain poisoned after lock/unlock cycle ' + IntToStr(I));
  end;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Mutex Poison Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Mutex_MarkPoisoned;
    Test_Mutex_ClearPoison;
    Test_Mutex_PoisonedThrowsOnLock;
    Test_Mutex_MultiplePoisoning;
    Test_Mutex_ClearAndRemark;
    Test_Mutex_PoisonPropagation;
    Test_Mutex_TryLockWhenPoisoned;
    Test_Mutex_PoisonPersistence;
  except
    on E: Exception do
    begin
      WriteLn('FATAL: Unhandled exception: ', E.ClassName, ': ', E.Message);
      Inc(TestsFailed);
    end;
  end;

  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Results: ', TestsPassed, ' passed, ', TestsFailed, ' failed');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1);
end.

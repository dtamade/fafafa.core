program test_poison_recovery;

{**
 * Poison 恢复场景测试
 *
 * 测试 Mutex 和 RWLock 的 Poison 恢复机制
 *
 * 测试覆盖:
 * 1. Mutex Poison 后的 ClearPoison 恢复
 * 2. RWLock Poison 后的 ClearPoison 恢复
 * 3. Poison 状态下的访问行为
 * 4. 多次 Poison 和恢复循环
 * 5. 多线程环境下的 Poison 恢复
 *}

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.rwlock.base,
  fafafa.core.sync.rwlock;

var
  LTestsPassed: Integer = 0;
  LTestsFailed: Integer = 0;

procedure Assert(aCondition: Boolean; const aMsg: string);
begin
  if aCondition then
  begin
    Inc(LTestsPassed);
    WriteLn('  ✓ ', aMsg);
  end
  else
  begin
    Inc(LTestsFailed);
    WriteLn('  ✗ FAIL: ', aMsg);
  end;
end;

// ============================================================================
// 测试 1: Mutex 初始状态不是 Poison
// ============================================================================
procedure Test_Mutex_InitialState;
var
  LM: IMutex;
begin
  WriteLn('Test: Mutex Initial State');

  LM := MakeMutex;
  Assert(not LM.IsPoisoned, 'Mutex should not be poisoned initially');
end;

// ============================================================================
// 测试 2: Mutex MarkPoisoned 后的状态
// ============================================================================
procedure Test_Mutex_MarkPoisoned;
var
  LM: IMutex;
begin
  WriteLn('Test: Mutex MarkPoisoned');

  LM := MakeMutex;
  
  // 标记为 Poison
  LM.MarkPoisoned('Test poison');
  Assert(LM.IsPoisoned, 'Mutex should be poisoned after MarkPoisoned');
end;

// ============================================================================
// 测试 3: Mutex ClearPoison 恢复
// ============================================================================
procedure Test_Mutex_ClearPoison_Recovery;
var
  LM: IMutex;
  LGuard: ILockGuard;
begin
  WriteLn('Test: Mutex ClearPoison Recovery');

  LM := MakeMutex;
  
  // 标记为 Poison
  LM.MarkPoisoned('Test poison');
  Assert(LM.IsPoisoned, 'Mutex should be poisoned');
  
  // 清除 Poison
  LM.ClearPoison;
  Assert(not LM.IsPoisoned, 'Mutex should not be poisoned after ClearPoison');
  
  // 验证可以正常获取锁
  LGuard := LM.TryLock;
  Assert(Assigned(LGuard), 'Should be able to acquire lock after ClearPoison');
  LGuard := nil;
end;

// ============================================================================
// 测试 4: RWLock 初始状态不是 Poison
// ============================================================================
procedure Test_RWLock_InitialState;
var
  LRW: IRWLock;
begin
  WriteLn('Test: RWLock Initial State');

  LRW := MakeRWLock;
  Assert(not LRW.IsPoisoned, 'RWLock should not be poisoned initially');
end;

// ============================================================================
// 测试 5: RWLock ClearPoison 基本功能
// ============================================================================
procedure Test_RWLock_ClearPoison_Basic;
var
  LRW: IRWLock;
  LReadGuard: IRWLockReadGuard;
  LWriteGuard: IRWLockWriteGuard;
begin
  WriteLn('Test: RWLock ClearPoison Basic');

  LRW := MakeRWLock;
  
  // 初始状态不应该是 Poison
  Assert(not LRW.IsPoisoned, 'RWLock should not be poisoned initially');
  
  // 调用 ClearPoison（即使没有 Poison 也应该安全）
  LRW.ClearPoison;
  Assert(not LRW.IsPoisoned, 'RWLock should still not be poisoned after ClearPoison');
  
  // 验证可以正常获取读锁
  LReadGuard := LRW.TryRead;
  Assert(Assigned(LReadGuard), 'Should be able to acquire read lock');
  LReadGuard := nil;
  
  // 验证可以正常获取写锁
  LWriteGuard := LRW.TryWrite;
  Assert(Assigned(LWriteGuard), 'Should be able to acquire write lock');
  LWriteGuard := nil;
end;

// ============================================================================
// 测试 7: Mutex 多次 Poison 和恢复循环
// ============================================================================
procedure Test_Mutex_Multiple_Poison_Recovery_Cycles;
var
  LM: IMutex;
  LGuard: ILockGuard;
  I: Integer;
begin
  WriteLn('Test: Mutex Multiple Poison Recovery Cycles');

  LM := MakeMutex;
  
  for I := 1 to 3 do
  begin
    // 标记为 Poison
    LM.MarkPoisoned('Test poison ' + IntToStr(I));
    Assert(LM.IsPoisoned, 'Mutex should be poisoned in cycle ' + IntToStr(I));
    
    // 清除 Poison
    LM.ClearPoison;
    Assert(not LM.IsPoisoned, 'Mutex should not be poisoned after ClearPoison in cycle ' + IntToStr(I));
    
    // 验证可以正常获取锁
    LGuard := LM.TryLock;
    Assert(Assigned(LGuard), 'Should be able to acquire lock in cycle ' + IntToStr(I));
    LGuard := nil;
  end;
end;

// ============================================================================
// 测试 6: RWLock 多次 ClearPoison 调用
// ============================================================================
procedure Test_RWLock_Multiple_ClearPoison_Calls;
var
  LRW: IRWLock;
  LReadGuard: IRWLockReadGuard;
  LWriteGuard: IRWLockWriteGuard;
  I: Integer;
begin
  WriteLn('Test: RWLock Multiple ClearPoison Calls');

  LRW := MakeRWLock;
  
  for I := 1 to 3 do
  begin
    // 多次调用 ClearPoison（即使没有 Poison 也应该安全）
    LRW.ClearPoison;
    Assert(not LRW.IsPoisoned, 'RWLock should not be poisoned in cycle ' + IntToStr(I));
    
    // 验证可以正常获取读锁
    LReadGuard := LRW.TryRead;
    Assert(Assigned(LReadGuard), 'Should be able to acquire read lock in cycle ' + IntToStr(I));
    LReadGuard := nil;
    
    // 验证可以正常获取写锁
    LWriteGuard := LRW.TryWrite;
    Assert(Assigned(LWriteGuard), 'Should be able to acquire write lock in cycle ' + IntToStr(I));
    LWriteGuard := nil;
  end;
end;

// ============================================================================
// 测试 9: 多线程环境下的 Mutex Poison 恢复
// ============================================================================
type
  TMutexPoisonRecoveryThread = class(TThread)
  private
    FMutex: IMutex;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(aMutex: IMutex);
    property Success: Boolean read FSuccess;
  end;

constructor TMutexPoisonRecoveryThread.Create(aMutex: IMutex);
begin
  inherited Create(True);
  FMutex := aMutex;
  FSuccess := False;
  FreeOnTerminate := False;
end;

procedure TMutexPoisonRecoveryThread.Execute;
var
  LGuard: ILockGuard;
begin
  // 等待主线程标记 Poison 并清除
  Sleep(50);
  
  // 尝试获取锁
  LGuard := FMutex.TryLock;
  FSuccess := Assigned(LGuard);
  LGuard := nil;
end;

procedure Test_Mutex_MultiThread_Poison_Recovery;
var
  LM: IMutex;
  LThread: TMutexPoisonRecoveryThread;
begin
  WriteLn('Test: Mutex Multi-Thread Poison Recovery');

  LM := MakeMutex;
  
  // 标记为 Poison
  LM.MarkPoisoned('Test poison');
  Assert(LM.IsPoisoned, 'Mutex should be poisoned');
  
  // 创建线程
  LThread := TMutexPoisonRecoveryThread.Create(LM);
  LThread.Start;
  
  // 清除 Poison
  Sleep(10);
  LM.ClearPoison;
  Assert(not LM.IsPoisoned, 'Mutex should not be poisoned after ClearPoison');
  
  // 等待线程完成
  LThread.WaitFor;
  Assert(LThread.Success, 'Thread should be able to acquire lock after ClearPoison');
  
  LThread.Free;
end;

// ============================================================================
// 测试 7: 多线程环境下的 RWLock ClearPoison
// ============================================================================
type
  TRWLockClearPoisonThread = class(TThread)
  private
    FRWLock: IRWLock;
    FReadSuccess: Boolean;
    FWriteSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(aRWLock: IRWLock);
    property ReadSuccess: Boolean read FReadSuccess;
    property WriteSuccess: Boolean read FWriteSuccess;
  end;

constructor TRWLockClearPoisonThread.Create(aRWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := aRWLock;
  FReadSuccess := False;
  FWriteSuccess := False;
  FreeOnTerminate := False;
end;

procedure TRWLockClearPoisonThread.Execute;
var
  LReadGuard: IRWLockReadGuard;
  LWriteGuard: IRWLockWriteGuard;
begin
  // 等待主线程调用 ClearPoison
  Sleep(50);
  
  // 尝试获取读锁
  LReadGuard := FRWLock.TryRead;
  FReadSuccess := Assigned(LReadGuard);
  LReadGuard := nil;
  
  // 尝试获取写锁
  LWriteGuard := FRWLock.TryWrite;
  FWriteSuccess := Assigned(LWriteGuard);
  LWriteGuard := nil;
end;

procedure Test_RWLock_MultiThread_ClearPoison;
var
  LRW: IRWLock;
  LThread: TRWLockClearPoisonThread;
begin
  WriteLn('Test: RWLock Multi-Thread ClearPoison');

  LRW := MakeRWLock;
  
  // 创建线程
  LThread := TRWLockClearPoisonThread.Create(LRW);
  LThread.Start;
  
  // 调用 ClearPoison
  Sleep(10);
  LRW.ClearPoison;
  Assert(not LRW.IsPoisoned, 'RWLock should not be poisoned after ClearPoison');
  
  // 等待线程完成
  LThread.WaitFor;
  Assert(LThread.ReadSuccess, 'Thread should be able to acquire read lock');
  Assert(LThread.WriteSuccess, 'Thread should be able to acquire write lock');
  
  LThread.Free;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Poison Recovery Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Mutex_InitialState;
    Test_Mutex_MarkPoisoned;
    Test_Mutex_ClearPoison_Recovery;
    Test_RWLock_InitialState;
    Test_RWLock_ClearPoison_Basic;
    Test_RWLock_Multiple_ClearPoison_Calls;
    Test_Mutex_Multiple_Poison_Recovery_Cycles;
    Test_Mutex_MultiThread_Poison_Recovery;
    Test_RWLock_MultiThread_ClearPoison;

    WriteLn('');
    WriteLn('========================================');
    WriteLn('  Test Summary');
    WriteLn('========================================');
    WriteLn('  Passed: ', LTestsPassed);
    WriteLn('  Failed: ', LTestsFailed);
    WriteLn('  Total:  ', LTestsPassed + LTestsFailed);
    WriteLn('========================================');
    WriteLn('');

    if LTestsFailed > 0 then
    begin
      WriteLn('FAILED: Some tests did not pass');
      Halt(1);
    end
    else
    begin
      WriteLn('SUCCESS: All tests passed');
      Halt(0);
    end;
  except
    on E: Exception do
    begin
      WriteLn('');
      WriteLn('FATAL ERROR: ', E.Message);
      Halt(2);
    end;
  end;
end.

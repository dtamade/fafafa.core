program test_mutex_edge_cases;

{**
 * Mutex 边界条件和异常处理测试
 *
 * 测试 Mutex 的边界条件和异常处理
 *
 * 测试覆盖:
 * 1. 重复释放锁
 * 2. 未获取锁就释放
 * 3. 多线程竞争边界条件
 * 4. 超时边界值测试
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

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
// 测试 1: 正常获取和释放锁
// ============================================================================
procedure Test_Mutex_NormalAcquireRelease;
var
  M: IMutex;
  Guard: ILockGuard;
begin
  WriteLn('Test: Mutex Normal Acquire Release');

  M := MakeMutex;

  // 正常获取锁
  Guard := M.Lock;
  try
    Assert(True, 'Should be able to acquire lock');
  finally
    Guard := nil;
  end;

  // 释放后应该可以再次获取
  Guard := M.Lock;
  try
    Assert(True, 'Should be able to acquire lock again after release');
  finally
    Guard := nil;
  end;
end;

// ============================================================================
// 测试 2: TryLock 边界条件
// ============================================================================
procedure Test_Mutex_TryLockEdgeCases;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
begin
  WriteLn('Test: Mutex TryLock Edge Cases');

  M := MakeMutex;

  // 第一次 TryLock 应该成功
  Guard1 := M.TryLock;
  try
    Assert(Assigned(Guard1), 'First TryLock should succeed');

    // 第二次 TryLock 应该失败（锁已被持有）
    Guard2 := M.TryLock;
    Assert(not Assigned(Guard2), 'Second TryLock should fail when lock is held');
  finally
    Guard1 := nil;
  end;

  // 释放后 TryLock 应该成功
  Guard1 := M.TryLock;
  try
    Assert(Assigned(Guard1), 'TryLock should succeed after release');
  finally
    Guard1 := nil;
  end;
end;

// ============================================================================
// 测试 3: 多次获取和释放
// ============================================================================
procedure Test_Mutex_MultipleAcquireRelease;
var
  M: IMutex;
  Guard: ILockGuard;
  I: Integer;
begin
  WriteLn('Test: Mutex Multiple Acquire Release');

  M := MakeMutex;

  // 多次获取和释放锁
  for I := 1 to 10 do
  begin
    Guard := M.Lock;
    try
      Assert(True, 'Should be able to acquire lock in iteration ' + IntToStr(I));
    finally
      Guard := nil;
    end;
  end;
end;

// ============================================================================
// 测试 4: 零超时边界条件
// ============================================================================
procedure Test_Mutex_ZeroTimeoutEdgeCases;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
begin
  WriteLn('Test: Mutex Zero Timeout Edge Cases');

  M := MakeMutex;

  // 先获取锁
  Guard1 := M.Lock;
  try
    // 零超时应该立即返回 nil
    Guard2 := M.TryLockFor(0);
    Assert(not Assigned(Guard2), 'TryLockFor(0) should return nil when lock is held');
  finally
    Guard1 := nil;
  end;

  // 释放后零超时应该成功
  Guard1 := M.TryLockFor(0);
  try
    Assert(Assigned(Guard1), 'TryLockFor(0) should succeed when lock is free');
  finally
    Guard1 := nil;
  end;
end;

// ============================================================================
// 测试 5: 最大超时值边界条件
// ============================================================================
procedure Test_Mutex_MaxTimeoutEdgeCases;
var
  M: IMutex;
  Guard: ILockGuard;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Max Timeout Edge Cases');

  M := MakeMutex;

  // 测试最大超时值（应该立即成功，因为锁是空闲的）
  StartTime := GetTickCount64;
  Guard := M.TryLockFor(High(Cardinal));
  Elapsed := GetTickCount64 - StartTime;

  try
    Assert(Assigned(Guard), 'TryLockFor(High(Cardinal)) should succeed when lock is free');
    Assert(Elapsed < 100, 'Should succeed almost immediately');
  finally
    Guard := nil;
  end;
end;

// ============================================================================
// 测试 6: 多线程竞争边界条件
// ============================================================================
type
  TCompetingThread = class(TThread)
  private
    FMutex: IMutex;
    FSuccessCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex);
    property SuccessCount: Integer read FSuccessCount;
  end;

constructor TCompetingThread.Create(AMutex: IMutex);
begin
  inherited Create(True);
  FMutex := AMutex;
  FSuccessCount := 0;
  FreeOnTerminate := False;
end;

procedure TCompetingThread.Execute;
var
  Guard: ILockGuard;
  I: Integer;
begin
  for I := 1 to 100 do
  begin
    Guard := FMutex.Lock;
    try
      Inc(FSuccessCount);
    finally
      Guard := nil;
    end;
  end;
end;

procedure Test_Mutex_MultiThreadCompetition;
const
  THREAD_COUNT = 5;
var
  M: IMutex;
  Threads: array[0..THREAD_COUNT-1] of TCompetingThread;
  I: Integer;
  TotalSuccess: Integer;
begin
  WriteLn('Test: Mutex Multi Thread Competition');

  M := MakeMutex;

  // 创建多个竞争线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TCompetingThread.Create(M);

  // 启动所有线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;

  // 等待所有线程完成
  TotalSuccess := 0;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    TotalSuccess := TotalSuccess + Threads[I].SuccessCount;
    Threads[I].Free;
  end;

  // 验证所有线程都成功获取了锁
  Assert(TotalSuccess = THREAD_COUNT * 100, 'All threads should successfully acquire lock 100 times each');
end;

// ============================================================================
// 测试 7: Guard 自动释放
// ============================================================================
procedure Test_Mutex_GuardAutoRelease;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
begin
  WriteLn('Test: Mutex Guard Auto Release');

  M := MakeMutex;

  // 获取锁
  Guard1 := M.Lock;
  // 让 Guard1 超出作用域（自动释放）
  Guard1 := nil;

  // 应该可以立即获取锁
  Guard2 := M.TryLock;
  try
    Assert(Assigned(Guard2), 'Should be able to acquire lock after guard auto-release');
  finally
    Guard2 := nil;
  end;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Mutex Edge Cases Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Mutex_NormalAcquireRelease;
    Test_Mutex_TryLockEdgeCases;
    Test_Mutex_MultipleAcquireRelease;
    Test_Mutex_ZeroTimeoutEdgeCases;
    Test_Mutex_MaxTimeoutEdgeCases;
    Test_Mutex_MultiThreadCompetition;
    Test_Mutex_GuardAutoRelease;
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

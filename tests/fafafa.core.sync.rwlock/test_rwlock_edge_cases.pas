program test_rwlock_edge_cases;

{**
 * RWLock 边界条件和异常处理测试
 *
 * 测试 RWLock 的边界条件和异常处理
 *
 * 测试覆盖:
 * 1. 正常读锁和写锁获取/释放
 * 2. TryRead/TryWrite 边界条件
 * 3. 多次读锁和写锁获取/释放
 * 4. 零超时边界值测试
 * 5. 最大超时值测试
 * 6. 多线程竞争边界条件
 * 7. Guard 自动释放
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base;

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
// 测试 1: 正常读锁获取和释放
// ============================================================================
procedure Test_RWLock_NormalReadAcquireRelease;
var
  RW: IRWLock;
  Guard: IRWLockReadGuard;
begin
  WriteLn('Test: RWLock Normal Read Acquire Release');

  RW := MakeRWLock;

  // 正常获取读锁
  Guard := RW.Read;
  try
    Assert(True, 'Should be able to acquire read lock');
  finally
    Guard := nil;
  end;

  // 释放后应该可以再次获取
  Guard := RW.Read;
  try
    Assert(True, 'Should be able to acquire read lock again after release');
  finally
    Guard := nil;
  end;
end;

// ============================================================================
// 测试 2: 正常写锁获取和释放
// ============================================================================
procedure Test_RWLock_NormalWriteAcquireRelease;
var
  RW: IRWLock;
  Guard: IRWLockWriteGuard;
begin
  WriteLn('Test: RWLock Normal Write Acquire Release');

  RW := MakeRWLock;

  // 正常获取写锁
  Guard := RW.Write;
  try
    Assert(True, 'Should be able to acquire write lock');
  finally
    Guard := nil;
  end;

  // 释放后应该可以再次获取
  Guard := RW.Write;
  try
    Assert(True, 'Should be able to acquire write lock again after release');
  finally
    Guard := nil;
  end;
end;

// ============================================================================
// 测试 3: TryRead 边界条件
// ============================================================================
type
  TTryReadThread = class(TThread)
  private
    FRWLock: IRWLock;
    FTryReadResult: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property TryReadResult: Boolean read FTryReadResult;
  end;

constructor TTryReadThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FTryReadResult := False;
  FreeOnTerminate := False;
end;

procedure TTryReadThread.Execute;
var
  Guard: IRWLockReadGuard;
begin
  Guard := FRWLock.TryRead;
  FTryReadResult := Assigned(Guard);
  if Assigned(Guard) then
    Guard := nil;
end;

procedure Test_RWLock_TryReadEdgeCases;
var
  RW: IRWLock;
  ReadGuard1, ReadGuard2: IRWLockReadGuard;
  WriteGuard: IRWLockWriteGuard;
  T: TTryReadThread;
begin
  WriteLn('Test: RWLock TryRead Edge Cases');

  RW := MakeRWLock;

  // 第一次 TryRead 应该成功
  ReadGuard1 := RW.TryRead;
  try
    Assert(Assigned(ReadGuard1), 'First TryRead should succeed');

    // 第二次 TryRead 也应该成功（读锁可以共享）
    ReadGuard2 := RW.TryRead;
    try
      Assert(Assigned(ReadGuard2), 'Second TryRead should also succeed (read locks are shared)');
    finally
      ReadGuard2 := nil;
    end;
  finally
    ReadGuard1 := nil;
  end;

  // 获取写锁后，在另一个线程 TryRead 应该失败（避免可重入行为）
  WriteGuard := RW.Write;
  try
    T := TTryReadThread.Create(RW);
    T.Start;
    T.WaitFor;
    Assert(not T.TryReadResult, 'TryRead should fail when write lock is held');
    T.Free;
  finally
    WriteGuard := nil;
  end;
end;

// ============================================================================
// 测试 4: TryWrite 边界条件
// ============================================================================
type
  TTryWriteThread = class(TThread)
  private
    FRWLock: IRWLock;
    FTryWriteResult: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property TryWriteResult: Boolean read FTryWriteResult;
  end;

constructor TTryWriteThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FTryWriteResult := False;
  FreeOnTerminate := False;
end;

procedure TTryWriteThread.Execute;
var
  Guard: IRWLockWriteGuard;
begin
  Guard := FRWLock.TryWrite;
  FTryWriteResult := Assigned(Guard);
  if Assigned(Guard) then
    Guard := nil;
end;

procedure Test_RWLock_TryWriteEdgeCases;
var
  RW: IRWLock;
  WriteGuard1: IRWLockWriteGuard;
  ReadGuard: IRWLockReadGuard;
  T: TTryWriteThread;
begin
  WriteLn('Test: RWLock TryWrite Edge Cases');

  RW := MakeRWLock;

  // 第一次 TryWrite 应该成功
  WriteGuard1 := RW.TryWrite;
  try
    Assert(Assigned(WriteGuard1), 'First TryWrite should succeed');

    // 在另一个线程 TryWrite 应该失败（写锁是独占的）
    T := TTryWriteThread.Create(RW);
    T.Start;
    T.WaitFor;
    Assert(not T.TryWriteResult, 'Second TryWrite should fail when write lock is held');
    T.Free;
  finally
    WriteGuard1 := nil;
  end;

  // 获取读锁后，在另一个线程 TryWrite 应该失败
  ReadGuard := RW.Read;
  try
    T := TTryWriteThread.Create(RW);
    T.Start;
    T.WaitFor;
    Assert(not T.TryWriteResult, 'TryWrite should fail when read lock is held');
    T.Free;
  finally
    ReadGuard := nil;
  end;
end;

// ============================================================================
// 测试 5: 多次读锁获取和释放
// ============================================================================
procedure Test_RWLock_MultipleReadAcquireRelease;
var
  RW: IRWLock;
  Guard: IRWLockReadGuard;
  I: Integer;
begin
  WriteLn('Test: RWLock Multiple Read Acquire Release');

  RW := MakeRWLock;

  // 多次获取和释放读锁
  for I := 1 to 10 do
  begin
    Guard := RW.Read;
    try
      Assert(True, 'Should be able to acquire read lock in iteration ' + IntToStr(I));
    finally
      Guard := nil;
    end;
  end;
end;

// ============================================================================
// 测试 6: 多次写锁获取和释放
// ============================================================================
procedure Test_RWLock_MultipleWriteAcquireRelease;
var
  RW: IRWLock;
  Guard: IRWLockWriteGuard;
  I: Integer;
begin
  WriteLn('Test: RWLock Multiple Write Acquire Release');

  RW := MakeRWLock;

  // 多次获取和释放写锁
  for I := 1 to 10 do
  begin
    Guard := RW.Write;
    try
      Assert(True, 'Should be able to acquire write lock in iteration ' + IntToStr(I));
    finally
      Guard := nil;
    end;
  end;
end;

// ============================================================================
// 测试 7: 读锁零超时边界条件
// ============================================================================
type
  TReadZeroTimeoutEdgeThread = class(TThread)
  private
    FRWLock: IRWLock;
    FResult: TLockResult;
    FElapsed: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property Result: TLockResult read FResult;
    property Elapsed: QWord read FElapsed;
  end;

constructor TReadZeroTimeoutEdgeThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FResult := lrSuccess;
  FElapsed := 0;
  FreeOnTerminate := False;
end;

procedure TReadZeroTimeoutEdgeThread.Execute;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  FResult := FRWLock.TryAcquireReadEx(0);
  FElapsed := GetTickCount64 - StartTime;
  if FResult = lrSuccess then
    FRWLock.ReleaseRead;
end;

procedure Test_RWLock_ReadZeroTimeoutEdgeCases;
var
  RW: IRWLock;
  WriteGuard: IRWLockWriteGuard;
  T: TReadZeroTimeoutEdgeThread;
  LockResult: TLockResult;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Read Zero Timeout Edge Cases');

  RW := MakeRWLock;

  // 先获取写锁，在另一个线程测试零超时（避免可重入行为）
  WriteGuard := RW.Write;
  try
    T := TReadZeroTimeoutEdgeThread.Create(RW);
    T.Start;
    T.WaitFor;

    Assert(T.Result = lrWouldBlock, 'TryAcquireReadEx(0) should return lrWouldBlock when write lock is held');
    Assert(T.Elapsed < 50, 'Zero timeout should return almost immediately');
    T.Free;
  finally
    WriteGuard := nil;
  end;

  // 释放后零超时应该成功
  StartTime := GetTickCount64;
  LockResult := RW.TryAcquireReadEx(0);
  Elapsed := GetTickCount64 - StartTime;

  if LockResult = lrSuccess then
  begin
    RW.ReleaseRead;
    Assert(True, 'TryAcquireReadEx(0) should succeed when no write lock is held');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately even on success');
  end
  else
    Assert(False, 'TryAcquireReadEx(0) should succeed when no write lock is held');
end;

// ============================================================================
// 测试 8: 写锁零超时边界条件
// ============================================================================
procedure Test_RWLock_WriteZeroTimeoutEdgeCases;
var
  RW: IRWLock;
  ReadGuard: IRWLockReadGuard;
  LockResult: TLockResult;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Write Zero Timeout Edge Cases');

  RW := MakeRWLock;

  // 先获取读锁
  ReadGuard := RW.Read;
  try
    // 零超时应该立即返回 lrWouldBlock
    StartTime := GetTickCount64;
    LockResult := RW.TryAcquireWriteEx(0);
    Elapsed := GetTickCount64 - StartTime;

    Assert(LockResult = lrWouldBlock, 'TryAcquireWriteEx(0) should return lrWouldBlock when read lock is held');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately');
  finally
    ReadGuard := nil;
  end;

  // 释放后零超时应该成功
  StartTime := GetTickCount64;
  LockResult := RW.TryAcquireWriteEx(0);
  Elapsed := GetTickCount64 - StartTime;

  if LockResult = lrSuccess then
  begin
    RW.ReleaseWrite;
    Assert(True, 'TryAcquireWriteEx(0) should succeed when no lock is held');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately even on success');
  end
  else
    Assert(False, 'TryAcquireWriteEx(0) should succeed when no lock is held');
end;

// ============================================================================
// 测试 9: 最大超时值边界条件
// ============================================================================
procedure Test_RWLock_MaxTimeoutEdgeCases;
var
  RW: IRWLock;
  LockResult: TLockResult;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Max Timeout Edge Cases');

  RW := MakeRWLock;

  // 测试读锁最大超时值（应该立即成功，因为锁是空闲的）
  StartTime := GetTickCount64;
  LockResult := RW.TryAcquireReadEx(High(Cardinal));
  Elapsed := GetTickCount64 - StartTime;

  if LockResult = lrSuccess then
  begin
    RW.ReleaseRead;
    Assert(True, 'TryAcquireReadEx(High(Cardinal)) should succeed when lock is free');
    Assert(Elapsed < 100, 'Should succeed almost immediately');
  end
  else
    Assert(False, 'TryAcquireReadEx(High(Cardinal)) should succeed when lock is free');

  // 测试写锁最大超时值
  StartTime := GetTickCount64;
  LockResult := RW.TryAcquireWriteEx(High(Cardinal));
  Elapsed := GetTickCount64 - StartTime;

  if LockResult = lrSuccess then
  begin
    RW.ReleaseWrite;
    Assert(True, 'TryAcquireWriteEx(High(Cardinal)) should succeed when lock is free');
    Assert(Elapsed < 100, 'Should succeed almost immediately');
  end
  else
    Assert(False, 'TryAcquireWriteEx(High(Cardinal)) should succeed when lock is free');
end;

// ============================================================================
// 测试 10: 多线程读锁竞争边界条件
// ============================================================================
type
  TCompetingReadThread = class(TThread)
  private
    FRWLock: IRWLock;
    FSuccessCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property SuccessCount: Integer read FSuccessCount;
  end;

constructor TCompetingReadThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FSuccessCount := 0;
  FreeOnTerminate := False;
end;

procedure TCompetingReadThread.Execute;
var
  I: Integer;
begin
  for I := 1 to 100 do
  begin
    FRWLock.AcquireRead;
    try
      Inc(FSuccessCount);
    finally
      FRWLock.ReleaseRead;
    end;
  end;
end;

procedure Test_RWLock_MultiThreadReadCompetition;
const
  THREAD_COUNT = 5;
var
  RW: IRWLock;
  Threads: array[0..THREAD_COUNT-1] of TCompetingReadThread;
  I: Integer;
  TotalSuccess: Integer;
begin
  WriteLn('Test: RWLock Multi Thread Read Competition');

  RW := MakeRWLock;

  // 创建多个竞争读锁的线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TCompetingReadThread.Create(RW);

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

  // 验证所有线程都成功获取了读锁
  Assert(TotalSuccess = THREAD_COUNT * 100, 'All threads should successfully acquire read lock 100 times each');
end;

// ============================================================================
// 测试 11: 多线程写锁竞争边界条件
// ============================================================================
type
  TCompetingWriteThread = class(TThread)
  private
    FRWLock: IRWLock;
    FSuccessCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property SuccessCount: Integer read FSuccessCount;
  end;

constructor TCompetingWriteThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FSuccessCount := 0;
  FreeOnTerminate := False;
end;

procedure TCompetingWriteThread.Execute;
var
  I: Integer;
begin
  for I := 1 to 100 do
  begin
    FRWLock.AcquireWrite;
    try
      Inc(FSuccessCount);
    finally
      FRWLock.ReleaseWrite;
    end;
  end;
end;

procedure Test_RWLock_MultiThreadWriteCompetition;
const
  THREAD_COUNT = 5;
var
  RW: IRWLock;
  Threads: array[0..THREAD_COUNT-1] of TCompetingWriteThread;
  I: Integer;
  TotalSuccess: Integer;
begin
  WriteLn('Test: RWLock Multi Thread Write Competition');

  RW := MakeRWLock;

  // 创建多个竞争写锁的线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TCompetingWriteThread.Create(RW);

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

  // 验证所有线程都成功获取了写锁
  Assert(TotalSuccess = THREAD_COUNT * 100, 'All threads should successfully acquire write lock 100 times each');
end;

// ============================================================================
// 测试 12: Guard 自动释放
// ============================================================================
procedure Test_RWLock_GuardAutoRelease;
var
  RW: IRWLock;
  ReadGuard1, ReadGuard2: IRWLockReadGuard;
  WriteGuard1, WriteGuard2: IRWLockWriteGuard;
begin
  WriteLn('Test: RWLock Guard Auto Release');

  RW := MakeRWLock;

  // 测试读锁 Guard 自动释放
  ReadGuard1 := RW.Read;
  // 让 ReadGuard1 超出作用域（自动释放）
  ReadGuard1 := nil;

  // 应该可以立即获取写锁
  WriteGuard1 := RW.TryWrite;
  try
    Assert(Assigned(WriteGuard1), 'Should be able to acquire write lock after read guard auto-release');
  finally
    WriteGuard1 := nil;
  end;

  // 测试写锁 Guard 自动释放
  WriteGuard2 := RW.Write;
  // 让 WriteGuard2 超出作用域（自动释放）
  WriteGuard2 := nil;

  // 应该可以立即获取读锁
  ReadGuard2 := RW.TryRead;
  try
    Assert(Assigned(ReadGuard2), 'Should be able to acquire read lock after write guard auto-release');
  finally
    ReadGuard2 := nil;
  end;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  RWLock Edge Cases Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_RWLock_NormalReadAcquireRelease;
    Test_RWLock_NormalWriteAcquireRelease;
    Test_RWLock_TryReadEdgeCases;
    Test_RWLock_TryWriteEdgeCases;
    Test_RWLock_MultipleReadAcquireRelease;
    Test_RWLock_MultipleWriteAcquireRelease;
    Test_RWLock_ReadZeroTimeoutEdgeCases;
    Test_RWLock_WriteZeroTimeoutEdgeCases;
    Test_RWLock_MaxTimeoutEdgeCases;
    Test_RWLock_MultiThreadReadCompetition;
    Test_RWLock_MultiThreadWriteCompetition;
    Test_RWLock_GuardAutoRelease;
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

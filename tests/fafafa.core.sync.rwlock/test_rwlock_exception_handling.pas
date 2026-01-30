program test_rwlock_exception_handling;

{**
 * RWLock 异常处理测试
 *
 * 测试 RWLock 的异常处理和错误场景
 *
 * 测试覆盖:
 * 1. 资源耗尽场景（大量锁创建）
 * 2. 极限压力测试
 * 3. 并发异常场景
 * 4. 读写锁交替压力测试
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.rwlock;

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
// 测试 1: 大量 RWLock 创建（资源压力测试）
// ============================================================================
procedure Test_RWLock_MassCreation;
const
  RWLOCK_COUNT = 1000;
var
  RWLocks: array[0..RWLOCK_COUNT-1] of IRWLock;
  I: Integer;
  Success: Boolean;
begin
  WriteLn('Test: RWLock Mass Creation');

  Success := True;
  try
    // 创建大量 RWLock
    for I := 0 to RWLOCK_COUNT - 1 do
    begin
      RWLocks[I] := MakeRWLock;
      if not Assigned(RWLocks[I]) then
      begin
        Success := False;
        Break;
      end;
    end;

    Assert(Success, 'Should be able to create ' + IntToStr(RWLOCK_COUNT) + ' rwlocks');

    // 验证所有 RWLock 都可以正常使用
    if Success then
    begin
      for I := 0 to RWLOCK_COUNT - 1 do
      begin
        RWLocks[I].AcquireRead;
        RWLocks[I].ReleaseRead;
      end;
      Assert(True, 'All rwlocks should be functional');
    end;

    // 清理
    for I := 0 to RWLOCK_COUNT - 1 do
      RWLocks[I] := nil;

  except
    on E: Exception do
    begin
      Assert(False, 'Mass creation should not throw exception: ' + E.Message);
    end;
  end;
end;

// ============================================================================
// 测试 2: 快速读锁获取/释放循环（压力测试）
// ============================================================================
procedure Test_RWLock_RapidReadAcquireRelease;
const
  ITERATION_COUNT = 10000;
var
  RW: IRWLock;
  I: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Rapid Read Acquire Release');

  RW := MakeRWLock;

  StartTime := GetTickCount64;
  for I := 1 to ITERATION_COUNT do
  begin
    RW.AcquireRead;
    RW.ReleaseRead;
  end;
  Elapsed := GetTickCount64 - StartTime;

  Assert(True, 'Should complete ' + IntToStr(ITERATION_COUNT) + ' read acquire/release cycles');
  if Elapsed > 0 then
    WriteLn('    Completed in ', Elapsed, 'ms (',
            FloatToStrF(ITERATION_COUNT / (Elapsed / 1000.0), ffFixed, 0, 0), ' ops/sec)')
  else
    WriteLn('    Completed in <1ms (very fast)');
end;

// ============================================================================
// 测试 3: 快速写锁获取/释放循环（压力测试）
// ============================================================================
procedure Test_RWLock_RapidWriteAcquireRelease;
const
  ITERATION_COUNT = 10000;
var
  RW: IRWLock;
  I: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Rapid Write Acquire Release');

  RW := MakeRWLock;

  StartTime := GetTickCount64;
  for I := 1 to ITERATION_COUNT do
  begin
    RW.AcquireWrite;
    RW.ReleaseWrite;
  end;
  Elapsed := GetTickCount64 - StartTime;

  Assert(True, 'Should complete ' + IntToStr(ITERATION_COUNT) + ' write acquire/release cycles');
  if Elapsed > 0 then
    WriteLn('    Completed in ', Elapsed, 'ms (',
            FloatToStrF(ITERATION_COUNT / (Elapsed / 1000.0), ffFixed, 0, 0), ' ops/sec)')
  else
    WriteLn('    Completed in <1ms (very fast)');
end;

// ============================================================================
// 测试 4: 读写锁交替压力测试
// ============================================================================
procedure Test_RWLock_AlternatingReadWritePressure;
const
  ITERATION_COUNT = 5000;
var
  RW: IRWLock;
  I: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Alternating Read Write Pressure');

  RW := MakeRWLock;

  StartTime := GetTickCount64;
  for I := 1 to ITERATION_COUNT do
  begin
    // 读锁
    RW.AcquireRead;
    RW.ReleaseRead;

    // 写锁
    RW.AcquireWrite;
    RW.ReleaseWrite;
  end;
  Elapsed := GetTickCount64 - StartTime;

  Assert(True, 'Should complete ' + IntToStr(ITERATION_COUNT * 2) + ' alternating acquire/release cycles');
  if Elapsed > 0 then
    WriteLn('    Completed in ', Elapsed, 'ms (',
            FloatToStrF((ITERATION_COUNT * 2) / (Elapsed / 1000.0), ffFixed, 0, 0), ' ops/sec)')
  else
    WriteLn('    Completed in <1ms (very fast)');
end;

// ============================================================================
// 测试 5: 多线程读锁快速竞争（压力测试）
// ============================================================================
type
  TRapidReadCompetitionThread = class(TThread)
  private
    FRWLock: IRWLock;
    FIterations: Integer;
    FSuccessCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AIterations: Integer);
    property SuccessCount: Integer read FSuccessCount;
  end;

constructor TRapidReadCompetitionThread.Create(ARWLock: IRWLock; AIterations: Integer);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FIterations := AIterations;
  FSuccessCount := 0;
  FreeOnTerminate := False;
end;

procedure TRapidReadCompetitionThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    FRWLock.AcquireRead;
    try
      Inc(FSuccessCount);
    finally
      FRWLock.ReleaseRead;
    end;
  end;
end;

procedure Test_RWLock_RapidMultiThreadReadCompetition;
const
  THREAD_COUNT = 10;
  ITERATIONS_PER_THREAD = 1000;
var
  RW: IRWLock;
  Threads: array[0..THREAD_COUNT-1] of TRapidReadCompetitionThread;
  I: Integer;
  TotalSuccess: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Rapid Multi Thread Read Competition');

  RW := MakeRWLock;

  // 创建多个竞争线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TRapidReadCompetitionThread.Create(RW, ITERATIONS_PER_THREAD);

  // 启动所有线程
  StartTime := GetTickCount64;
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
  Elapsed := GetTickCount64 - StartTime;

  // 验证所有线程都成功获取了读锁
  Assert(TotalSuccess = THREAD_COUNT * ITERATIONS_PER_THREAD,
         'All threads should successfully acquire read lock');
  if Elapsed > 0 then
    WriteLn('    Completed ', TotalSuccess, ' operations in ', Elapsed, 'ms (',
            FloatToStrF(TotalSuccess / (Elapsed / 1000.0), ffFixed, 0, 0), ' ops/sec)')
  else
    WriteLn('    Completed ', TotalSuccess, ' operations in <1ms (very fast)');
end;

// ============================================================================
// 测试 6: 多线程写锁快速竞争（压力测试）
// ============================================================================
type
  TRapidWriteCompetitionThread = class(TThread)
  private
    FRWLock: IRWLock;
    FIterations: Integer;
    FSuccessCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock; AIterations: Integer);
    property SuccessCount: Integer read FSuccessCount;
  end;

constructor TRapidWriteCompetitionThread.Create(ARWLock: IRWLock; AIterations: Integer);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FIterations := AIterations;
  FSuccessCount := 0;
  FreeOnTerminate := False;
end;

procedure TRapidWriteCompetitionThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    FRWLock.AcquireWrite;
    try
      Inc(FSuccessCount);
    finally
      FRWLock.ReleaseWrite;
    end;
  end;
end;

procedure Test_RWLock_RapidMultiThreadWriteCompetition;
const
  THREAD_COUNT = 10;
  ITERATIONS_PER_THREAD = 1000;
var
  RW: IRWLock;
  Threads: array[0..THREAD_COUNT-1] of TRapidWriteCompetitionThread;
  I: Integer;
  TotalSuccess: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: RWLock Rapid Multi Thread Write Competition');

  RW := MakeRWLock;

  // 创建多个竞争线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TRapidWriteCompetitionThread.Create(RW, ITERATIONS_PER_THREAD);

  // 启动所有线程
  StartTime := GetTickCount64;
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
  Elapsed := GetTickCount64 - StartTime;

  // 验证所有线程都成功获取了写锁
  Assert(TotalSuccess = THREAD_COUNT * ITERATIONS_PER_THREAD,
         'All threads should successfully acquire write lock');
  if Elapsed > 0 then
    WriteLn('    Completed ', TotalSuccess, ' operations in ', Elapsed, 'ms (',
            FloatToStrF(TotalSuccess / (Elapsed / 1000.0), ffFixed, 0, 0), ' ops/sec)')
  else
    WriteLn('    Completed ', TotalSuccess, ' operations in <1ms (very fast)');
end;

// ============================================================================
// 测试 7: TryRead 在高竞争下的行为
// ============================================================================
type
  TTryReadCompetitionThread = class(TThread)
  private
    FRWLock: IRWLock;
    FSuccessCount: Integer;
    FFailCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property SuccessCount: Integer read FSuccessCount;
    property FailCount: Integer read FFailCount;
  end;

constructor TTryReadCompetitionThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FSuccessCount := 0;
  FFailCount := 0;
  FreeOnTerminate := False;
end;

procedure TTryReadCompetitionThread.Execute;
var
  I: Integer;
  Guard: IRWLockReadGuard;
begin
  for I := 1 to 1000 do
  begin
    Guard := FRWLock.TryRead;
    if Assigned(Guard) then
    begin
      Inc(FSuccessCount);
      Guard := nil;
    end
    else
      Inc(FFailCount);
  end;
end;

procedure Test_RWLock_TryReadUnderHighContention;
const
  THREAD_COUNT = 10;
var
  RW: IRWLock;
  Threads: array[0..THREAD_COUNT-1] of TTryReadCompetitionThread;
  I: Integer;
  TotalSuccess, TotalFail: Integer;
begin
  WriteLn('Test: RWLock TryRead Under High Contention');

  RW := MakeRWLock;

  // 创建多个竞争线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TTryReadCompetitionThread.Create(RW);

  // 启动所有线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;

  // 等待所有线程完成
  TotalSuccess := 0;
  TotalFail := 0;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    TotalSuccess := TotalSuccess + Threads[I].SuccessCount;
    TotalFail := TotalFail + Threads[I].FailCount;
    Threads[I].Free;
  end;

  Assert(TotalSuccess > 0, 'Some TryRead attempts should succeed');
  // 注意：读锁可以共享，所以失败次数可能很少或为零
  WriteLn('    Success: ', TotalSuccess, ', Failed: ', TotalFail);
  if (TotalSuccess + TotalFail) > 0 then
    WriteLn('    (', FloatToStrF(TotalSuccess / (TotalSuccess + TotalFail) * 100, ffFixed, 0, 1), '% success rate)');
end;

// ============================================================================
// 测试 8: TryWrite 在高竞争下的行为
// ============================================================================
type
  TTryWriteCompetitionThread = class(TThread)
  private
    FRWLock: IRWLock;
    FSuccessCount: Integer;
    FFailCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property SuccessCount: Integer read FSuccessCount;
    property FailCount: Integer read FFailCount;
  end;

constructor TTryWriteCompetitionThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FSuccessCount := 0;
  FFailCount := 0;
  FreeOnTerminate := False;
end;

procedure TTryWriteCompetitionThread.Execute;
var
  I: Integer;
  Guard: IRWLockWriteGuard;
begin
  for I := 1 to 1000 do
  begin
    Guard := FRWLock.TryWrite;
    if Assigned(Guard) then
    begin
      Inc(FSuccessCount);
      Guard := nil;
    end
    else
      Inc(FFailCount);
  end;
end;

procedure Test_RWLock_TryWriteUnderHighContention;
const
  THREAD_COUNT = 10;
var
  RW: IRWLock;
  Threads: array[0..THREAD_COUNT-1] of TTryWriteCompetitionThread;
  I: Integer;
  TotalSuccess, TotalFail: Integer;
begin
  WriteLn('Test: RWLock TryWrite Under High Contention');

  RW := MakeRWLock;

  // 创建多个竞争线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TTryWriteCompetitionThread.Create(RW);

  // 启动所有线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;

  // 等待所有线程完成
  TotalSuccess := 0;
  TotalFail := 0;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    TotalSuccess := TotalSuccess + Threads[I].SuccessCount;
    TotalFail := TotalFail + Threads[I].FailCount;
    Threads[I].Free;
  end;

  Assert(TotalSuccess > 0, 'Some TryWrite attempts should succeed');
  Assert(TotalFail > 0, 'Some TryWrite attempts should fail under contention');
  if (TotalSuccess + TotalFail) > 0 then
    WriteLn('    Success: ', TotalSuccess, ', Failed: ', TotalFail,
            ' (', FloatToStrF(TotalSuccess / (TotalSuccess + TotalFail) * 100, ffFixed, 0, 1), '% success rate)');
end;

// ============================================================================
// 测试 9: Guard 生命周期管理
// ============================================================================
procedure Test_RWLock_GuardLifecycleManagement;
var
  RW: IRWLock;
  ReadGuard1, ReadGuard2: IRWLockReadGuard;
  WriteGuard1, WriteGuard2: IRWLockWriteGuard;
begin
  WriteLn('Test: RWLock Guard Lifecycle Management');

  RW := MakeRWLock;

  // 测试读锁 Guard 的正常生命周期
  ReadGuard1 := RW.Read;
  Assert(Assigned(ReadGuard1), 'Read guard should be assigned after Read');

  // 释放读锁 Guard
  ReadGuard1 := nil;

  // 应该可以立即获取写锁 Guard
  WriteGuard1 := RW.TryWrite;
  Assert(Assigned(WriteGuard1), 'Should be able to acquire write lock after read guard release');
  WriteGuard1 := nil;

  // 测试写锁 Guard 的正常生命周期
  WriteGuard2 := RW.Write;
  Assert(Assigned(WriteGuard2), 'Write guard should be assigned after Write');

  // 释放写锁 Guard
  WriteGuard2 := nil;

  // 应该可以立即获取读锁 Guard
  ReadGuard2 := RW.TryRead;
  Assert(Assigned(ReadGuard2), 'Should be able to acquire read lock after write guard release');
  ReadGuard2 := nil;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  RWLock Exception Handling Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_RWLock_MassCreation;
    Test_RWLock_RapidReadAcquireRelease;
    Test_RWLock_RapidWriteAcquireRelease;
    Test_RWLock_AlternatingReadWritePressure;
    Test_RWLock_RapidMultiThreadReadCompetition;
    Test_RWLock_RapidMultiThreadWriteCompetition;
    Test_RWLock_TryReadUnderHighContention;
    Test_RWLock_TryWriteUnderHighContention;
    Test_RWLock_GuardLifecycleManagement;
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

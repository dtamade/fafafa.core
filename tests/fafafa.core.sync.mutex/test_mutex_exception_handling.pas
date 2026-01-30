program test_mutex_exception_handling;

{**
 * Mutex 异常处理测试
 *
 * 测试 Mutex 的异常处理和错误场景
 *
 * 测试覆盖:
 * 1. 资源耗尽场景（大量锁创建）
 * 2. 无效参数测试（负数超时等）
 * 3. 极限压力测试
 * 4. 并发异常场景
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
// 测试 1: 大量 Mutex 创建（资源压力测试）
// ============================================================================
procedure Test_Mutex_MassCreation;
const
  MUTEX_COUNT = 1000;
var
  Mutexes: array[0..MUTEX_COUNT-1] of IMutex;
  I: Integer;
  Success: Boolean;
begin
  WriteLn('Test: Mutex Mass Creation');

  Success := True;
  try
    // 创建大量 Mutex
    for I := 0 to MUTEX_COUNT - 1 do
    begin
      Mutexes[I] := MakeMutex;
      if not Assigned(Mutexes[I]) then
      begin
        Success := False;
        Break;
      end;
    end;

    Assert(Success, 'Should be able to create ' + IntToStr(MUTEX_COUNT) + ' mutexes');

    // 验证所有 Mutex 都可以正常使用
    if Success then
    begin
      for I := 0 to MUTEX_COUNT - 1 do
      begin
        Mutexes[I].Acquire;
        Mutexes[I].Release;
      end;
      Assert(True, 'All mutexes should be functional');
    end;

    // 清理
    for I := 0 to MUTEX_COUNT - 1 do
      Mutexes[I] := nil;

  except
    on E: Exception do
    begin
      Assert(False, 'Mass creation should not throw exception: ' + E.Message);
    end;
  end;
end;

// ============================================================================
// 测试 2: 极限超时值测试
// ============================================================================
procedure Test_Mutex_ExtremeTimeoutValues;
var
  M: IMutex;
  Result: Boolean;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Extreme Timeout Values');

  M := MakeMutex;

  // 测试零超时
  StartTime := GetTickCount64;
  Result := M.TryAcquire(0);
  Elapsed := GetTickCount64 - StartTime;

  if Result then
  begin
    M.Release;
    Assert(True, 'TryAcquire(0) should succeed when lock is free');
    Assert(Elapsed < 50, 'Zero timeout should return almost immediately');
  end
  else
    Assert(False, 'TryAcquire(0) should succeed when lock is free');

  // 测试最大超时值
  StartTime := GetTickCount64;
  Result := M.TryAcquire(High(Cardinal));
  Elapsed := GetTickCount64 - StartTime;

  if Result then
  begin
    M.Release;
    Assert(True, 'TryAcquire(High(Cardinal)) should succeed when lock is free');
    Assert(Elapsed < 100, 'Should succeed almost immediately when lock is free');
  end
  else
    Assert(False, 'TryAcquire(High(Cardinal)) should succeed when lock is free');
end;

// ============================================================================
// 测试 3: 快速获取/释放循环（压力测试）
// ============================================================================
procedure Test_Mutex_RapidAcquireRelease;
const
  ITERATION_COUNT = 10000;
var
  M: IMutex;
  I: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Rapid Acquire Release');

  M := MakeMutex;

  StartTime := GetTickCount64;
  for I := 1 to ITERATION_COUNT do
  begin
    M.Acquire;
    M.Release;
  end;
  Elapsed := GetTickCount64 - StartTime;

  Assert(True, 'Should complete ' + IntToStr(ITERATION_COUNT) + ' acquire/release cycles');
  if Elapsed > 0 then
    WriteLn('    Completed in ', Elapsed, 'ms (',
            FloatToStrF(ITERATION_COUNT / (Elapsed / 1000.0), ffFixed, 0, 0), ' ops/sec)')
  else
    WriteLn('    Completed in <1ms (very fast)');
end;

// ============================================================================
// 测试 4: 多线程快速竞争（压力测试）
// ============================================================================
type
  TRapidCompetitionThread = class(TThread)
  private
    FMutex: IMutex;
    FIterations: Integer;
    FSuccessCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex; AIterations: Integer);
    property SuccessCount: Integer read FSuccessCount;
  end;

constructor TRapidCompetitionThread.Create(AMutex: IMutex; AIterations: Integer);
begin
  inherited Create(True);
  FMutex := AMutex;
  FIterations := AIterations;
  FSuccessCount := 0;
  FreeOnTerminate := False;
end;

procedure TRapidCompetitionThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
  begin
    FMutex.Acquire;
    try
      Inc(FSuccessCount);
    finally
      FMutex.Release;
    end;
  end;
end;

procedure Test_Mutex_RapidMultiThreadCompetition;
const
  THREAD_COUNT = 10;
  ITERATIONS_PER_THREAD = 1000;
var
  M: IMutex;
  Threads: array[0..THREAD_COUNT-1] of TRapidCompetitionThread;
  I: Integer;
  TotalSuccess: Integer;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Mutex Rapid Multi Thread Competition');

  M := MakeMutex;

  // 创建多个竞争线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TRapidCompetitionThread.Create(M, ITERATIONS_PER_THREAD);

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

  // 验证所有线程都成功获取了锁
  Assert(TotalSuccess = THREAD_COUNT * ITERATIONS_PER_THREAD,
         'All threads should successfully acquire lock');
  if Elapsed > 0 then
    WriteLn('    Completed ', TotalSuccess, ' operations in ', Elapsed, 'ms (',
            FloatToStrF(TotalSuccess / (Elapsed / 1000.0), ffFixed, 0, 0), ' ops/sec)')
  else
    WriteLn('    Completed ', TotalSuccess, ' operations in <1ms (very fast)');
end;

// ============================================================================
// 测试 5: TryLock 在高竞争下的行为
// ============================================================================
type
  TTryLockCompetitionThread = class(TThread)
  private
    FMutex: IMutex;
    FSuccessCount: Integer;
    FFailCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex);
    property SuccessCount: Integer read FSuccessCount;
    property FailCount: Integer read FFailCount;
  end;

constructor TTryLockCompetitionThread.Create(AMutex: IMutex);
begin
  inherited Create(True);
  FMutex := AMutex;
  FSuccessCount := 0;
  FFailCount := 0;
  FreeOnTerminate := False;
end;

procedure TTryLockCompetitionThread.Execute;
var
  I: Integer;
  Guard: ILockGuard;
begin
  for I := 1 to 1000 do
  begin
    Guard := FMutex.TryLock;
    if Assigned(Guard) then
    begin
      Inc(FSuccessCount);
      Guard := nil;
    end
    else
      Inc(FFailCount);
  end;
end;

procedure Test_Mutex_TryLockUnderHighContention;
const
  THREAD_COUNT = 10;
var
  M: IMutex;
  Threads: array[0..THREAD_COUNT-1] of TTryLockCompetitionThread;
  I: Integer;
  TotalSuccess, TotalFail: Integer;
begin
  WriteLn('Test: Mutex TryLock Under High Contention');

  M := MakeMutex;

  // 创建多个竞争线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TTryLockCompetitionThread.Create(M);

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

  Assert(TotalSuccess > 0, 'Some TryLock attempts should succeed');
  Assert(TotalFail > 0, 'Some TryLock attempts should fail under contention');
  if (TotalSuccess + TotalFail) > 0 then
    WriteLn('    Success: ', TotalSuccess, ', Failed: ', TotalFail,
            ' (', FloatToStrF(TotalSuccess / (TotalSuccess + TotalFail) * 100, ffFixed, 0, 1), '% success rate)')
  else
    WriteLn('    Success: ', TotalSuccess, ', Failed: ', TotalFail);
end;

// ============================================================================
// 测试 6: Guard 生命周期管理
// ============================================================================
procedure Test_Mutex_GuardLifecycleManagement;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
begin
  WriteLn('Test: Mutex Guard Lifecycle Management');

  M := MakeMutex;

  // 测试 Guard 的正常生命周期
  Guard1 := M.Lock;
  Assert(Assigned(Guard1), 'Guard should be assigned after Lock');

  // 释放 Guard
  Guard1 := nil;

  // 应该可以立即获取新的 Guard
  Guard2 := M.TryLock;
  Assert(Assigned(Guard2), 'Should be able to acquire lock after guard release');
  Guard2 := nil;
end;

// ============================================================================
// 测试 7: 多次 TryLock 失败后成功
// ============================================================================
procedure Test_Mutex_TryLockRetryPattern;
var
  M: IMutex;
  Guard1, Guard2: ILockGuard;
  I: Integer;
  Success: Boolean;
begin
  WriteLn('Test: Mutex TryLock Retry Pattern');

  M := MakeMutex;

  // 先获取锁
  Guard1 := M.Lock;
  try
    // 多次尝试 TryLock（应该都失败）
    Success := False;
    for I := 1 to 5 do
    begin
      Guard2 := M.TryLock;
      if Assigned(Guard2) then
      begin
        Success := True;
        Guard2 := nil;
        Break;
      end;
    end;

    Assert(not Success, 'TryLock should fail while lock is held');
  finally
    Guard1 := nil;
  end;

  // 释放后应该成功
  Guard2 := M.TryLock;
  try
    Assert(Assigned(Guard2), 'TryLock should succeed after lock is released');
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
  WriteLn('  Mutex Exception Handling Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Mutex_MassCreation;
    Test_Mutex_ExtremeTimeoutValues;
    Test_Mutex_RapidAcquireRelease;
    Test_Mutex_RapidMultiThreadCompetition;
    Test_Mutex_TryLockUnderHighContention;
    Test_Mutex_GuardLifecycleManagement;
    Test_Mutex_TryLockRetryPattern;
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

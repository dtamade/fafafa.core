{$mode objfpc}{$H+}
program test_sync_leak;

{**
 * Memory Leak Detection Test for fafafa.core.sync
 *
 * Compile with HeapTrc enabled:
 *   fpc -gh -gl -B -Fu../../src -Fi../../src -o./test_sync_leak test_sync_leak.pas
 *
 * Run and check for "0 unfreed memory blocks" in output.
 *}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.sync.mutex,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.condvar,
  fafafa.core.sync.barrier,
  fafafa.core.sync.sem,
  fafafa.core.sync.event,
  fafafa.core.sync.spin,
  fafafa.core.sync.once,
  fafafa.core.sync.latch,
  fafafa.core.sync.waitgroup,
  fafafa.core.sync.parker;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Pass(const TestName: string);
begin
  WriteLn('  ✓ ', TestName);
  Inc(TestsPassed);
end;

procedure Fail(const TestName, Msg: string);
begin
  WriteLn('  ✗ ', TestName, ': ', Msg);
  Inc(TestsFailed);
end;

// ===== Test 1: Mutex Create/Destroy =====
procedure Test_Mutex_CreateDestroy;
var
  M: IMutex;
  I: Integer;
begin
  WriteLn('[Test 1] Mutex Create/Destroy');

  // Single create/destroy
  M := MakeMutex;
  M.Acquire;
  M.Release;
  M := nil;

  // Multiple create/destroy cycles
  for I := 1 to 100 do
  begin
    M := MakeMutex;
    M.Acquire;
    M.Release;
    M := nil;
  end;

  Pass('100 mutex create/destroy cycles');
end;

// ===== Test 2: RWLock Create/Destroy =====
procedure Test_RWLock_CreateDestroy;
var
  RW: IRWLock;
  I: Integer;
begin
  WriteLn('[Test 2] RWLock Create/Destroy');

  // Read lock cycle
  for I := 1 to 50 do
  begin
    RW := MakeRWLock;
    RW.AcquireRead;
    RW.ReleaseRead;
    RW := nil;
  end;

  // Write lock cycle
  for I := 1 to 50 do
  begin
    RW := MakeRWLock;
    RW.AcquireWrite;
    RW.ReleaseWrite;
    RW := nil;
  end;

  Pass('100 rwlock create/destroy cycles');
end;

// ===== Test 3: CondVar Create/Destroy =====
procedure Test_CondVar_CreateDestroy;
var
  CV: ICondVar;
  M: IMutex;
  I: Integer;
begin
  WriteLn('[Test 3] CondVar Create/Destroy');

  for I := 1 to 100 do
  begin
    CV := MakeCondVar;
    M := MakeMutex;

    // Signal/Broadcast without waiters (valid operation)
    CV.Signal;
    CV.Broadcast;

    // WaitFor with timeout
    M.Acquire;
    CV.WaitFor(M, 0);  // Immediate timeout
    M.Release;

    CV := nil;
    M := nil;
  end;

  Pass('100 condvar create/destroy cycles');
end;

// ===== Test 4: Barrier Create/Destroy =====
procedure Test_Barrier_CreateDestroy;
var
  B: IBarrier;
  I: Integer;
begin
  WriteLn('[Test 4] Barrier Create/Destroy');

  for I := 1 to 100 do
  begin
    // Single participant barrier - can wait immediately
    B := MakeBarrier(1);
    B.Wait;
    B := nil;
  end;

  Pass('100 barrier create/destroy cycles');
end;

// ===== Test 5: Semaphore Create/Destroy =====
procedure Test_Semaphore_CreateDestroy;
var
  S: ISem;
  I: Integer;
begin
  WriteLn('[Test 5] Semaphore Create/Destroy');

  for I := 1 to 100 do
  begin
    S := MakeSem(1, 10);
    S.Acquire;
    S.Release;
    S := nil;
  end;

  // Zero initial count
  for I := 1 to 50 do
  begin
    S := MakeSem(0, 10);
    S.Release;  // Increment to 1
    S.Acquire;  // Decrement back to 0
    S := nil;
  end;

  Pass('150 semaphore create/destroy cycles');
end;

// ===== Test 6: Event Create/Destroy =====
procedure Test_Event_CreateDestroy;
var
  E: IEvent;
  I: Integer;
begin
  WriteLn('[Test 6] Event Create/Destroy');

  // Auto-reset events
  for I := 1 to 50 do
  begin
    E := MakeEvent(False, True);  // Auto-reset, signaled
    E.WaitFor(0);
    E := nil;
  end;

  // Manual-reset events
  for I := 1 to 50 do
  begin
    E := MakeEvent(True, False);  // Manual-reset, not signaled
    E.SetEvent;
    E.WaitFor(0);
    E.ResetEvent;
    E := nil;
  end;

  Pass('100 event create/destroy cycles');
end;

// ===== Test 7: Spin Lock Create/Destroy =====
procedure Test_Spin_CreateDestroy;
var
  Sp: ISpin;
  I: Integer;
begin
  WriteLn('[Test 7] Spin Lock Create/Destroy');

  for I := 1 to 100 do
  begin
    Sp := MakeSpin;
    Sp.Acquire;
    Sp.Release;
    Sp := nil;
  end;

  Pass('100 spin lock create/destroy cycles');
end;

// ===== Test 8: Once Create/Destroy =====
procedure Test_Once_CreateDestroy;
var
  O: IOnce;
  CallCount: Integer;
  I: Integer;

  procedure OnceCallback;
  begin
    Inc(CallCount);
  end;

begin
  WriteLn('[Test 8] Once Create/Destroy');

  for I := 1 to 100 do
  begin
    CallCount := 0;
    O := MakeOnce;
    O.Execute(@OnceCallback);
    O.Execute(@OnceCallback);  // Should not call again
    O := nil;

    if CallCount <> 1 then
    begin
      Fail('Once', Format('Expected 1 call, got %d', [CallCount]));
      Exit;
    end;
  end;

  Pass('100 once create/destroy cycles');
end;

// ===== Test 9: Latch Create/Destroy =====
procedure Test_Latch_CreateDestroy;
var
  L: ILatch;
  I: Integer;
begin
  WriteLn('[Test 9] Latch Create/Destroy');

  for I := 1 to 100 do
  begin
    L := MakeLatch(1);
    L.CountDown;
    L.Await;  // Should return immediately
    L := nil;
  end;

  Pass('100 latch create/destroy cycles');
end;

// ===== Test 10: WaitGroup Create/Destroy =====
procedure Test_WaitGroup_CreateDestroy;
var
  WG: IWaitGroup;
  I: Integer;
begin
  WriteLn('[Test 10] WaitGroup Create/Destroy');

  for I := 1 to 100 do
  begin
    WG := MakeWaitGroup;
    WG.Add(1);
    WG.Done;
    WG.Wait;  // Should return immediately
    WG := nil;
  end;

  Pass('100 waitgroup create/destroy cycles');
end;

// ===== Test 11: Parker Create/Destroy =====
procedure Test_Parker_CreateDestroy;
var
  P: IParker;
  I: Integer;
begin
  WriteLn('[Test 11] Parker Create/Destroy');

  for I := 1 to 100 do
  begin
    P := MakeParker;
    P.Unpark;
    P.Park;  // Should return immediately after unpark
    P := nil;
  end;

  Pass('100 parker create/destroy cycles');
end;

// ===== Test 12: Guard Pattern (RAII) =====
procedure Test_Guard_Pattern;
var
  M: IMutex;
  RW: IRWLock;
  I: Integer;
begin
  WriteLn('[Test 12] Guard Pattern (RAII)');

  // Mutex guard pattern simulation
  for I := 1 to 100 do
  begin
    M := MakeMutex;
    M.Acquire;
    try
      // Critical section
    finally
      M.Release;
    end;
    M := nil;
  end;

  // RWLock guard pattern simulation
  for I := 1 to 50 do
  begin
    RW := MakeRWLock;
    RW.AcquireRead;
    try
      // Read section
    finally
      RW.ReleaseRead;
    end;
    RW := nil;
  end;

  for I := 1 to 50 do
  begin
    RW := MakeRWLock;
    RW.AcquireWrite;
    try
      // Write section
    finally
      RW.ReleaseWrite;
    end;
    RW := nil;
  end;

  Pass('200 guard pattern cycles');
end;

// ===== Test 13: Mixed Operations Stress Test =====
procedure Test_Mixed_Stress;
var
  M: IMutex;
  RW: IRWLock;
  S: ISem;
  E: IEvent;
  I, J: Integer;
begin
  WriteLn('[Test 13] Mixed Operations Stress Test');

  for I := 1 to 50 do
  begin
    M := MakeMutex;
    RW := MakeRWLock;
    S := MakeSem(5, 10);
    E := MakeEvent(False, True);

    for J := 1 to 10 do
    begin
      M.Acquire;
      M.Release;

      RW.AcquireRead;
      RW.ReleaseRead;

      if S.TryAcquire(1, 0) then
        S.Release;

      E.WaitFor(0);
      E.SetEvent;
    end;

    M := nil;
    RW := nil;
    S := nil;
    E := nil;
  end;

  Pass('50 mixed stress cycles (500 ops each)');
end;

// ===== Test 14: Rapid Create/Destroy (Allocation Stress) =====
procedure Test_Rapid_CreateDestroy;
var
  Arr: array[0..9] of IMutex;
  I, J: Integer;
begin
  WriteLn('[Test 14] Rapid Create/Destroy (Allocation Stress)');

  for I := 1 to 100 do
  begin
    // Create 10 mutexes
    for J := 0 to 9 do
      Arr[J] := MakeMutex;

    // Use them
    for J := 0 to 9 do
    begin
      Arr[J].Acquire;
      Arr[J].Release;
    end;

    // Destroy in different order
    for J := 9 downto 0 do
      Arr[J] := nil;
  end;

  Pass('1000 rapid mutex allocations');
end;

// ===== Main =====
begin
  WriteLn('==========================================');
  WriteLn('fafafa.core.sync Memory Leak Detection Test');
  WriteLn('==========================================');
  WriteLn;

  try
    Test_Mutex_CreateDestroy;
    WriteLn;

    Test_RWLock_CreateDestroy;
    WriteLn;

    Test_CondVar_CreateDestroy;
    WriteLn;

    Test_Barrier_CreateDestroy;
    WriteLn;

    Test_Semaphore_CreateDestroy;
    WriteLn;

    Test_Event_CreateDestroy;
    WriteLn;

    Test_Spin_CreateDestroy;
    WriteLn;

    Test_Once_CreateDestroy;
    WriteLn;

    Test_Latch_CreateDestroy;
    WriteLn;

    Test_WaitGroup_CreateDestroy;
    WriteLn;

    Test_Parker_CreateDestroy;
    WriteLn;

    Test_Guard_Pattern;
    WriteLn;

    Test_Mixed_Stress;
    WriteLn;

    Test_Rapid_CreateDestroy;
    WriteLn;

    WriteLn('==========================================');
    WriteLn(Format('Results: %d passed, %d failed', [TestsPassed, TestsFailed]));
    WriteLn('==========================================');
    WriteLn;
    WriteLn('Check below for memory leak report:');
    WriteLn('Look for "0 unfreed memory blocks"');
    WriteLn('==========================================');

    if TestsFailed > 0 then
      ExitCode := 1;

  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
end.

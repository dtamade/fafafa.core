program example_smoketest;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.sync;

function AssertTrue(const Cond: Boolean; const Msg: string): Boolean;
begin
  if not Cond then
    WriteLn('FAIL: ', Msg)
  else
    WriteLn('OK:   ', Msg);
  Result := Cond;
end;

// ---- Global state and thread procs (avoid nested procs for BeginThread) ----
var
  G_Mutex: TMutex;
  G_MutexHeldDone: TEvent;

function Mutex_HolderThread(Data: Pointer): PtrInt;
begin
  G_Mutex.Acquire;
  try
    Sleep(120);
  finally
    G_Mutex.Release;
  end;
  G_MutexHeldDone.SetEvent;
  Result := 0;
end;

var
  G_Lock: TMutex;
  G_Cond: TConditionVariable;
  G_Ready, G_Done: TEvent;
  G_WReady: TEvent;
  G_WDoneCount: Integer = 0;

function Cond_Worker(Data: Pointer): PtrInt;
begin
  G_Lock.Acquire;
  try
    G_Ready.SetEvent;
    G_Cond.Wait(G_Lock);
  finally
    G_Lock.Release;
  end;
  G_Done.SetEvent;
  Result := 0;
end;

function Cond_Waiter(Data: Pointer): PtrInt;
begin
  G_Lock.Acquire;
  try
    Inc(G_WDoneCount); // reuse as entered count before wait
    if G_WDoneCount = 2 then G_WReady.SetEvent;
    G_Cond.Wait(G_Lock);
  finally
    G_Lock.Release;
  end;
  G_Done.SetEvent;
  Result := 0;
end;

var
  G_RW: TReadWriteLock;

function RW_ReaderProc(Data: Pointer): PtrInt;
begin
  G_RW.AcquireRead;
  try
    Sleep(100);
  finally
    G_RW.ReleaseRead;
  end;
  Result := 0;
end;

// ---- Tests ----
function SmokeTestMutex: Boolean;
var
  Th: TThreadID;
  Step1, Step2, Step3: Boolean;
begin
  Result := True;
  G_Mutex := TMutex.Create;

  // Reentrant acquire
  G_Mutex.Acquire;
  Step1 := G_Mutex.TryAcquire; // reentrant
  G_Mutex.Release; G_Mutex.Release;
  Result := Result and AssertTrue(Step1, 'Mutex reentrant TryAcquire works');

  // Free acquire with timeout
  Step2 := G_Mutex.TryAcquire(10);
  if Step2 then G_Mutex.Release;
  Result := Result and AssertTrue(Step2, 'Mutex TryAcquire(timeout) when free works');

  // Compete with another thread
  G_MutexHeldDone := TEvent.Create(False, False);
  BeginThread(@Mutex_HolderThread, nil, Th);
  Sleep(10);
  Step3 := not G_Mutex.TryAcquire(50);
  Result := Result and AssertTrue(Step3, 'Mutex TryAcquire(timeout) times out when held by another thread');
  // wait release then ensure we can acquire
  G_MutexHeldDone.WaitFor(1000);
  Result := Result and AssertTrue(G_Mutex.TryAcquire(200), 'Mutex TryAcquire after holder releases');
  if G_Mutex.IsLocked then G_Mutex.Release;
end;

function SmokeTestCondVar: Boolean;
var Th, W1, W2: TThreadID; ok1, ok2: Boolean;
begin
  Result := True;
  G_Lock := TMutex.Create;
  G_Cond := TConditionVariable.Create;
  G_Ready := TEvent.Create(False, False);
  G_Done := TEvent.Create(False, False);
  G_WReady := TEvent.Create(False, False);
  G_WDoneCount := 0;

  BeginThread(@Cond_Worker, nil, Th);
  // wait until worker started and is waiting
  G_Ready.WaitFor(1000);
  Sleep(50);
  G_Cond.Signal;
  ok1 := (G_Done.WaitFor(1000) = wrSignaled);

  // Broadcast to multiple waiters
  G_Done.ResetEvent; G_WReady.ResetEvent; G_WDoneCount := 0;
  BeginThread(@Cond_Waiter, nil, W1);
  BeginThread(@Cond_Waiter, nil, W2);
  G_WReady.WaitFor(1000); // both entered (count reached 2)
  Sleep(50);
  G_Cond.Broadcast;
  ok2 := (G_Done.WaitFor(1000) = wrSignaled);

  Result := Result and AssertTrue(ok1, 'CondVar Signal wakes waiter');
  Result := Result and AssertTrue(ok2, 'CondVar Broadcast wakes waiters');
end;

function SmokeTestRWLock: Boolean;
var
  Reader1, Reader2: TThreadID;
  TryFailWhileReaders, TryOkAfter: Boolean;
begin
  Result := True;
  G_RW := TReadWriteLock.Create;

  BeginThread(@RW_ReaderProc, Pointer(1), Reader1);
  BeginThread(@RW_ReaderProc, Pointer(2), Reader2);
  Sleep(10);

  TryFailWhileReaders := not G_RW.TryAcquireWrite(50);
  Result := Result and AssertTrue(TryFailWhileReaders, 'RWLock TryAcquireWrite fails while readers active');

  Sleep(150);
  TryOkAfter := G_RW.TryAcquireWrite(200);
  Result := Result and AssertTrue(TryOkAfter, 'RWLock TryAcquireWrite succeeds after readers done');
  if TryOkAfter then G_RW.ReleaseWrite;
end;

var
  AllOk: Boolean;
begin
  AllOk := True;
  WriteLn('--- Smoke tests for fafafa.core.sync ---');
  AllOk := AllOk and SmokeTestMutex;
  AllOk := AllOk and SmokeTestCondVar;
  AllOk := AllOk and SmokeTestRWLock;
  if AllOk then begin
    WriteLn('ALL OK'); Halt(0);
  end else begin
    WriteLn('SOME TESTS FAILED'); Halt(1);
  end;
end.


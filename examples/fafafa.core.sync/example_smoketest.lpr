program example_smoketest;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync;

function AssertTrue(const aCond: Boolean; const aMsg: string): Boolean;
begin
  if not aCond then
    WriteLn('FAIL: ', aMsg)
  else
    WriteLn('OK:   ', aMsg);

  Result := aCond;
end;

var
  GMutex: IMutex;
  GMutexHeldDone: IEvent;

function MutexHolderThread(aData: Pointer): PtrInt;
begin
  if aData <> nil then
    WriteLn('Mutex holder tag=', PtrUInt(aData));

  GMutex.Acquire;
  try
    Sleep(120);
  finally
    GMutex.Release;
  end;

  GMutexHeldDone.SetEvent;
  Result := 0;
end;

var
  GLock: IMutex;
  GCondVar: ICondVar;
  GReady: IEvent;
  GDone: IEvent;
  GWReady: IEvent;
  GWDoneCount: Integer = 0;

function CondWorker(aData: Pointer): PtrInt;
var
  LOk: Boolean;
begin
  if aData <> nil then
    WriteLn('Cond worker tag=', PtrUInt(aData));

  GLock.Acquire;
  try
    GReady.SetEvent;
    LOk := GCondVar.Wait(GLock, 1000);
    if not LOk then
      WriteLn('Cond worker timed out');
  finally
    GLock.Release;
  end;

  GDone.SetEvent;
  Result := 0;
end;

function CondWaiter(aData: Pointer): PtrInt;
var
  LOk: Boolean;
begin
  if aData <> nil then
    WriteLn('Cond waiter tag=', PtrUInt(aData));

  GLock.Acquire;
  try
    Inc(GWDoneCount);
    if GWDoneCount = 2 then
      GWReady.SetEvent;

    LOk := GCondVar.Wait(GLock, 1000);
    if not LOk then
      WriteLn('Cond waiter timed out');
  finally
    GLock.Release;
  end;

  GDone.SetEvent;
  Result := 0;
end;

var
  GRWLock: IRWLock;

function RWReaderProc(aData: Pointer): PtrInt;
begin
  if aData <> nil then
    WriteLn('RW reader tag=', PtrUInt(aData));

  GRWLock.AcquireRead;
  try
    Sleep(100);
  finally
    GRWLock.ReleaseRead;
  end;

  Result := 0;
end;

function SmokeTestMutex: Boolean;
var
  LThreadId: TThreadID;
  LStep1: Boolean;
  LStep2: Boolean;
  LStep3: Boolean;
begin
  Result := True;

  GMutex := MakeMutex;

  LStep1 := GMutex.TryAcquire(10);
  if LStep1 then
    GMutex.Release;
  Result := Result and AssertTrue(LStep1, 'Mutex TryAcquire(timeout) when free works');

  GMutexHeldDone := MakeEvent(False, False);
  BeginThread(@MutexHolderThread, nil, LThreadId);
  Sleep(10);

  LStep2 := not GMutex.TryAcquire(50);
  Result := Result and AssertTrue(LStep2, 'Mutex TryAcquire(timeout) times out when held by another thread');

  GMutexHeldDone.WaitFor(1000);
  LStep3 := GMutex.TryAcquire(200);
  Result := Result and AssertTrue(LStep3, 'Mutex TryAcquire after holder releases');
  if LStep3 then
    GMutex.Release;
end;

function SmokeTestCondVar: Boolean;
var
  LWorkerThread: TThreadID;
  LWaiter1: TThreadID;
  LWaiter2: TThreadID;
  LOk1: Boolean;
  LOk2: Boolean;
begin
  Result := True;

  GLock := MakeMutex;
  GCondVar := MakeCondVar;
  GReady := MakeEvent(False, False);
  GDone := MakeEvent(False, False);
  GWReady := MakeEvent(False, False);
  GWDoneCount := 0;

  BeginThread(@CondWorker, nil, LWorkerThread);
  GReady.WaitFor(1000);
  Sleep(50);
  GCondVar.Signal;
  LOk1 := GDone.WaitFor(1000) = wrSignaled;

  GDone.ResetEvent;
  GWReady.ResetEvent;
  GWDoneCount := 0;

  BeginThread(@CondWaiter, Pointer(1), LWaiter1);
  BeginThread(@CondWaiter, Pointer(2), LWaiter2);
  GWReady.WaitFor(1000);
  Sleep(50);
  GCondVar.Broadcast;
  LOk2 := GDone.WaitFor(1000) = wrSignaled;

  Result := Result and AssertTrue(LOk1, 'CondVar Signal wakes waiter');
  Result := Result and AssertTrue(LOk2, 'CondVar Broadcast wakes waiters');
end;

function SmokeTestRWLock: Boolean;
var
  LReader1: TThreadID;
  LReader2: TThreadID;
  LTryFailWhileReaders: Boolean;
  LTryOkAfter: Boolean;
begin
  Result := True;

  GRWLock := MakeRWLock;

  BeginThread(@RWReaderProc, Pointer(1), LReader1);
  BeginThread(@RWReaderProc, Pointer(2), LReader2);
  Sleep(10);

  LTryFailWhileReaders := not GRWLock.TryAcquireWrite(50);
  Result := Result and AssertTrue(LTryFailWhileReaders, 'RWLock TryAcquireWrite fails while readers active');

  Sleep(150);
  LTryOkAfter := GRWLock.TryAcquireWrite(200);
  Result := Result and AssertTrue(LTryOkAfter, 'RWLock TryAcquireWrite succeeds after readers finish');
  if LTryOkAfter then
    GRWLock.ReleaseWrite;
end;

var
  LAllOk: Boolean;
begin
  LAllOk := True;
  WriteLn('--- Smoke tests for fafafa.core.sync ---');

  LAllOk := LAllOk and SmokeTestMutex;
  LAllOk := LAllOk and SmokeTestCondVar;
  LAllOk := LAllOk and SmokeTestRWLock;

  if LAllOk then
  begin
    WriteLn('ALL OK');
    Halt(0);
  end;

  WriteLn('SOME TESTS FAILED');
  Halt(1);
end.

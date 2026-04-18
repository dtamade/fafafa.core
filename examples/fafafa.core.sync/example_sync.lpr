program example_sync;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync;

function BoolLabel(aValue: Boolean): string;
begin
  if aValue then
    Result := 'yes'
  else
    Result := 'no';
end;

procedure PrintSection(const aTitle: string);
begin
  WriteLn;
  WriteLn('=== ', aTitle, ' ===');
end;

procedure DemoMutex;
var
  LMutex: IMutex;
  LGuard: ILockGuard;
  LTryGuard: ILockGuard;
begin
  PrintSection('Mutex');

  LMutex := MakeMutex;

  LGuard := LMutex.Lock;
  WriteLn('Lock() acquired guard: ', BoolLabel(Assigned(LGuard) and LGuard.IsLocked));

  LGuard.Release;
  WriteLn('Guard released explicitly: ', BoolLabel(Assigned(LGuard) and LGuard.IsLocked));

  LTryGuard := LMutex.TryLockFor(10);
  WriteLn('TryLockFor(10) succeeded: ', BoolLabel(Assigned(LTryGuard) and LTryGuard.IsLocked));
  if Assigned(LTryGuard) then
    LTryGuard.Release;
end;

procedure DemoSpin;
var
  LSpin: ISpin;
  LGuard: ILockGuard;
begin
  PrintSection('Spin');

  LSpin := MakeSpin;
  if LSpin.TryAcquire then
  begin
    try
      WriteLn('TryAcquire() succeeded: yes');
    finally
      LSpin.Release;
    end;
  end
  else
    WriteLn('TryAcquire() succeeded: no');

  LGuard := LSpin.Lock;
  WriteLn('Lock() returned guard: ', BoolLabel(Assigned(LGuard) and LGuard.IsLocked));
  LGuard.Release;
end;

procedure DemoRWLock;
var
  LRWLock: IRWLock;
begin
  PrintSection('RWLock');

  LRWLock := MakeRWLock;

  LRWLock.AcquireRead;
  try
    WriteLn('Reader count after AcquireRead: ', LRWLock.GetReaderCount);
    WriteLn('Write lock active during read: ', BoolLabel(LRWLock.IsWriteLocked));
  finally
    LRWLock.ReleaseRead;
  end;

  LRWLock.AcquireWrite;
  try
    WriteLn('Write lock active after AcquireWrite: ', BoolLabel(LRWLock.IsWriteLocked));
  finally
    LRWLock.ReleaseWrite;
  end;
end;

procedure DemoScopedLock;
var
  LLeft: IMutex;
  LRight: IMutex;
  LGuard: IMultiLockGuard;
begin
  PrintSection('ScopedLock2');

  LLeft := MakeMutex;
  LRight := MakeMutex;
  LGuard := ScopedLock2(LLeft, LRight);
  WriteLn('Scoped lock guard acquired: ', BoolLabel(Assigned(LGuard) and LGuard.IsLocked));
  LGuard.Release;
end;

procedure DemoErrorHandling;
var
  LMutex: IMutex;
begin
  PrintSection('Error Handling');

  LMutex := MakeMutex;
  try
    LMutex.Release;
    WriteLn('Unexpected success when releasing an unlocked mutex');
  except
    on LError: ELockError do
      WriteLn('Expected mutex release error: ', LError.Message);
  end;
end;

begin
  try
    WriteLn('fafafa.core.sync current API example');
    DemoMutex;
    DemoSpin;
    DemoRWLock;
    DemoScopedLock;
    DemoErrorHandling;
    WriteLn;
    WriteLn('example_sync completed.');
  except
    on LError: Exception do
    begin
      WriteLn('Unhandled exception: ', LError.ClassName, ' - ', LError.Message);
      Halt(1);
    end;
  end;
end.

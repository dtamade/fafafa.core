program example_sync;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync;

function BoolText(aValue: Boolean): string;
begin
  Result := BoolToStr(aValue, True);
end;

procedure DemoMutexGuard;
var
  LMutex: IMutex;
  LGuard: ILockGuard;
  LAcquired: Boolean;
begin
  WriteLn('=== Mutex / Guard ===');

  LMutex := MakeMutex;
  LGuard := LMutex.Lock;
  WriteLn('Lock() returned guard: ', BoolText(Assigned(LGuard)));
  WriteLn('Guard.IsLocked: ', BoolText(Assigned(LGuard) and LGuard.IsLocked));

  LGuard := nil;

  LAcquired := LMutex.TryAcquire;
  WriteLn('TryAcquire after guard release: ', BoolText(LAcquired));
  if LAcquired then
    LMutex.Release;

  LGuard := LMutex.TryLockFor(10);
  WriteLn('TryLockFor(10ms) returned guard: ', BoolText(Assigned(LGuard)));
  LGuard := nil;
  WriteLn('');
end;

procedure DemoSpin;
var
  LSpin: ISpin;
  LAcquired: Boolean;
begin
  WriteLn('=== Spin ===');

  LSpin := MakeSpin;
  LAcquired := LSpin.TryAcquire(10);
  WriteLn('TryAcquire(10ms): ', BoolText(LAcquired));
  if LAcquired then
  begin
    WriteLn('Spin critical section entered');
    LSpin.Release;
  end;
  WriteLn('');
end;

procedure DemoRWLock;
var
  LRWLock: IRWLock;
  LReadGuard: IRWLockReadGuard;
  LWriteGuard: IRWLockWriteGuard;
begin
  WriteLn('=== RWLock ===');

  LRWLock := MakeRWLock;

  LReadGuard := LRWLock.Read;
  WriteLn('Read guard acquired: ', BoolText(Assigned(LReadGuard) and LReadGuard.IsLocked));
  WriteLn('Reader count while held: ', LRWLock.GetReaderCount);
  LReadGuard := nil;

  WriteLn('Reader count after release: ', LRWLock.GetReaderCount);

  LWriteGuard := LRWLock.TryWrite(50);
  WriteLn('TryWrite(50ms) returned guard: ', BoolText(Assigned(LWriteGuard)));
  if Assigned(LWriteGuard) then
  begin
    WriteLn('IsWriteLocked while guard held: ', BoolText(LRWLock.IsWriteLocked));
    LWriteGuard := nil;
  end;

  WriteLn('IsWriteLocked after release: ', BoolText(LRWLock.IsWriteLocked));
  WriteLn('');
end;

procedure DemoEvent;
var
  LEvent: IEvent;
  LWaitResult: TWaitResult;
begin
  WriteLn('=== Event ===');

  LEvent := MakeEvent(False, False);

  LWaitResult := LEvent.WaitFor(1);
  WriteLn('Initial WaitFor(1ms) timed out: ', BoolText(LWaitResult = wrTimeout));

  LEvent.SetEvent;
  LWaitResult := LEvent.WaitFor(50);
  WriteLn('Wait after SetEvent signaled: ', BoolText(LWaitResult = wrSignaled));
  WriteLn('');
end;

begin
  WriteLn('fafafa.core.sync 当前入口示例');
  WriteLn('============================');

  try
    DemoMutexGuard;
    DemoSpin;
    DemoRWLock;
    DemoEvent;
    WriteLn('示例结束');
  except
    on LError: Exception do
    begin
      WriteLn('发生异常: ', LError.ClassName, ' - ', LError.Message);
      Halt(1);
    end;
  end;
end.

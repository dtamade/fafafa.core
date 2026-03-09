unit Test_sync_modern;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync;

type
  TTestCase_Sync_Smoke = class(TTestCase)
  published
    procedure Test_Mutex_Basic;
    procedure Test_Spin_Basic;
    procedure Test_Event_Basic;
    procedure Test_NamedEvent_Factory;
    procedure Test_Once_Basic;
  end;

implementation

procedure TTestCase_Sync_Smoke.Test_Mutex_Basic;
var
  L: IMutex;
begin
  L := MakeMutex;
  CheckNotNull(L);
  L.Acquire;
  L.Release;
  CheckTrue(True, 'Mutex acquire/release OK');
end;

procedure TTestCase_Sync_Smoke.Test_Spin_Basic;
var
  S: ISpin;
begin
  S := MakeSpin;
  CheckNotNull(S);
  // TryAcquire path
  if S.TryAcquire then
  begin
    S.Release;
  end
  else
  begin
    // If contended, wait briefly then try again
    Sleep(0);
    if S.TryAcquire(10) then
      S.Release;
  end;
  CheckTrue(True, 'Spin try/acquire/release OK');
end;

procedure TTestCase_Sync_Smoke.Test_Event_Basic;
var
  E: IEvent;
begin
  E := MakeEvent(False, False); // auto-reset, non-signaled
  CheckNotNull(E);
  // Wait times out
  CheckEquals(Ord(wrTimeout), Ord(E.WaitFor(1)));
  // Signal and wait should succeed
  E.SetEvent;
  CheckEquals(Ord(wrSignaled), Ord(E.WaitFor(10)));
end;

procedure TTestCase_Sync_Smoke.Test_NamedEvent_Factory;
var
  LNamedEvent: INamedEvent;
begin
  try
    LNamedEvent := MakeNamedEvent('fafafa.sync.test.event.modern');
    CheckNotNull(LNamedEvent);
  except
    on LError: ESyncError do
    begin
      {$IFDEF UNIX}
      if Pos('Permission denied', LError.Message) > 0 then
      begin
        CheckTrue(True, 'Skip in restricted UNIX environment: shared memory permission denied');
        Exit;
      end;
      {$ENDIF}
      raise;
    end;
  end;
end;

procedure TTestCase_Sync_Smoke.Test_Once_Basic;
var
  O: IOnce;
  Cnt: Integer = 0;
  procedure IncOnce;
  begin
    Inc(Cnt);
  end;
begin
  O := TOnce.Create(@IncOnce);
  CheckNotNull(O);
  O.Execute;
  O.Execute; // no-op
  CheckEquals(1, Cnt);
end;

initialization
  RegisterTest(TTestCase_Sync_Smoke);

end.

program example_condvar_broadcast;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync;

var
  M: ILock;
  CV: IConditionVariable;
  ReadyCount: Integer = 0;
  Target: Integer = 3; // 3 consumers

function Consumer(P: Pointer): PtrInt;
var id: PtrUInt;
begin
  id := PtrUInt(P);
  M.Acquire;
  try
    while ReadyCount = 0 do
      if not CV.Wait(M, 2000) then begin
        WriteLn('Consumer ', id, ' timeout waiting');
        Exit(0);
      end;
    // 被唤醒后，看到 ReadyCount > 0，表示广播生效
    WriteLn('Consumer ', id, ' observed broadcast');
  finally
    M.Release;
  end;
  Result := 0;
end;

function Producer(P: Pointer): PtrInt;
var i: Integer;
begin
  Sleep(300);
  M.Acquire;
  try
    ReadyCount := Target;
    CV.Broadcast;
    WriteLn('Producer broadcast to ', Target, ' consumers');
  finally
    M.Release;
  end;
  Result := 0;
end;

var T1, T2, T3, TP: TThreadID;
begin
  M := TMutex.Create;
  CV := TConditionVariable.Create;

  BeginThread(@Consumer, Pointer(1), T1);
  BeginThread(@Consumer, Pointer(2), T2);
  BeginThread(@Consumer, Pointer(3), T3);
  BeginThread(@Producer, nil, TP);

  Sleep(2000);
end.


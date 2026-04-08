program example_condvar_broadcast;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync;

var
  GMutex: ILock;
  GCondVar: ICondVar;
  GReadyCount: Integer = 0;
  GTargetCount: Integer = 3;

function Consumer(aData: Pointer): PtrInt;
var
  LId: PtrUInt;
  LOk: Boolean;
begin
  LId := PtrUInt(aData);

  GMutex.Acquire;
  try
    while GReadyCount = 0 do
    begin
      LOk := GCondVar.Wait(GMutex, 2000);
      if not LOk then
      begin
        WriteLn('Consumer ', LId, ' timeout waiting');
        Exit(0);
      end;
    end;

    WriteLn('Consumer ', LId, ' observed broadcast');
  finally
    GMutex.Release;
  end;

  Result := 0;
end;

function Producer(aData: Pointer): PtrInt;
begin
  Sleep(300);

  GMutex.Acquire;
  try
    GReadyCount := GTargetCount;
    GCondVar.Broadcast;
    WriteLn('Producer broadcast to ', GTargetCount, ' consumers');
  finally
    GMutex.Release;
  end;

  Result := 0;
end;

var
  LT1: TThreadID;
  LT2: TThreadID;
  LT3: TThreadID;
  LProducerThread: TThreadID;
begin
  GMutex := MakeMutex;
  GCondVar := MakeCondVar;

  BeginThread(@Consumer, Pointer(1), LT1);
  BeginThread(@Consumer, Pointer(2), LT2);
  BeginThread(@Consumer, Pointer(3), LT3);
  BeginThread(@Producer, nil, LProducerThread);

  Sleep(2000);
end.

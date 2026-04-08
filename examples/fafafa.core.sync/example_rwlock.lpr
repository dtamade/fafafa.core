program example_rwlock;

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
  GRWLock: IRWLock;
  GSharedValue: Integer = 0;

function ReaderThreadProc(aData: Pointer): PtrInt;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 5 do
  begin
    GRWLock.AcquireRead;
    try
      WriteLn('Reader ', PtrUInt(aData), ' read SharedValue=', GSharedValue);
    finally
      GRWLock.ReleaseRead;
    end;
    Sleep(50);
  end;
  Result := 0;
end;

function WriterThreadProc(aData: Pointer): PtrInt;
var
  LOk: Boolean;
  LIndex: Integer;
begin
  if aData <> nil then
    WriteLn('Writer thread tag=', PtrUInt(aData));

  for LIndex := 1 to 5 do
  begin
    LOk := GRWLock.TryAcquireWrite(50);
    if LOk then
    begin
      try
        Inc(GSharedValue);
        WriteLn('Writer updated SharedValue to ', GSharedValue);
      finally
        GRWLock.ReleaseWrite;
      end;
    end
    else
      WriteLn('Writer failed to acquire write within 50ms (as expected when readers active)');
    Sleep(80);
  end;
  Result := 0;
end;

var
  LT1: TThreadID;
  LT2: TThreadID;
  LTW: TThreadID;

begin
  GRWLock := MakeRWLock;
  BeginThread(@ReaderThreadProc, Pointer(1), LT1);
  BeginThread(@ReaderThreadProc, Pointer(2), LT2);
  BeginThread(@WriterThreadProc, nil, LTW);

  // 简单等待线程结束（示例化，真实项目应 Join）
  Sleep(1500);
  WriteLn('Final SharedValue=', GSharedValue);
end.

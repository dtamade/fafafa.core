program example_rwlock;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync;

var
  RW: IReadWriteLock;
  SharedValue: Integer = 0;

function ReaderThreadProc(Data: Pointer): PtrInt;
var
  i: Integer;
begin
  for i := 1 to 5 do
  begin
    RW.AcquireRead;
    try
      WriteLn('Reader ', PtrUInt(Data), ' read SharedValue=', SharedValue);
    finally
      RW.ReleaseRead;
    end;
    Sleep(50);
  end;
  Result := 0;
end;

function WriterThreadProc(Data: Pointer): PtrInt;
var
  ok: Boolean;
  i: Integer;
begin
  for i := 1 to 5 do
  begin
    ok := RW.TryAcquireWrite(50);
    if ok then
    begin
      try
        Inc(SharedValue);
        WriteLn('Writer updated SharedValue to ', SharedValue);
      finally
        RW.ReleaseWrite;
      end;
    end
    else
      WriteLn('Writer failed to acquire write within 50ms (as expected when readers active)');
    Sleep(80);
  end;
  Result := 0;
end;

var
  T1, T2, TW: TThreadID;

begin
  RW := TReadWriteLock.Create;
  BeginThread(@ReaderThreadProc, Pointer(1), T1);
  BeginThread(@ReaderThreadProc, Pointer(2), T2);
  BeginThread(@WriterThreadProc, nil, TW);

  // 简单等待线程结束（示例化，真实项目应 Join）
  Sleep(1500);
  WriteLn('Final SharedValue=', SharedValue);
end.


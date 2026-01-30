program concurrent_flags_no_leak_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}
{$I ../../src/fafafa.core.settings.inc}

uses
  Classes, SysUtils, fafafa.core.mem.allocator, fafafa.core.json.core;

var T,P,F: Integer;
procedure Ok(const Msg: string; Cond: Boolean);
begin Inc(T); if Cond then begin Inc(P); WriteLn('OK ', Msg); end else begin Inc(F); WriteLn('FAIL ', Msg); end; end;

function ReadDoc(const S: RawByteString; Flags: TJsonReadFlags; out V: PJsonValue; out D: TJsonDocument): Boolean;
var Alc: TAllocator; Err: TJsonError;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); if Result then V := JsonDocGetRoot(D) else V := nil; end;

procedure Test_Concurrent_No_Leak;
var V1,V2: PJsonValue; D1,D2: TJsonDocument;
  th1, th2: TThread;
  r1, r2: Boolean;
begin
  r1 := False; r2 := False;
  th1 := TThread.CreateAnonymousThread(procedure
    begin r1 := ReadDoc('"\uD800"', [], V1, D1) = False; end);
  th2 := TThread.CreateAnonymousThread(procedure
    begin r2 := ReadDoc('"\uD800"', [jrfAllowInvalidUnicode], V2, D2) = True; if Assigned(D2) then JsonDocFree(D2); end);
  th1.Start; th2.Start; th1.WaitFor; th2.WaitFor; th1.Free; th2.Free;
  Ok('thread1 strict still rejects', r1);
  Ok('thread2 relaxed still accepts', r2);
end;

begin
  try
    Test_Concurrent_No_Leak;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


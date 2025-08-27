program simple_json_stopwhendone_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

var T,P,F: Integer;

procedure Ok(const Msg: string; Cond: Boolean);
begin Inc(T); if Cond then begin Inc(P); WriteLn('OK ', Msg); end else begin Inc(F); WriteLn('FAIL ', Msg); end; end;

function ReadDoc(const S: RawByteString; Flags: TJsonReadFlags; out V: PJsonValue; out D: TJsonDocument): Boolean;
var Alc: TAllocator; Err: TJsonError;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); if not Assigned(D) then WriteLn('ERR code=', Ord(Err.Code), ' pos=', Err.Position, ' msg=', Err.Message);
  Result := Assigned(D); if Result then V := JsonDocGetRoot(D) else V := nil; end;

procedure Test_StopWhenDone;
var V: PJsonValue; D: TJsonDocument;
begin
  if not ReadDoc('123 456', [jrfStopWhenDone], V, D) then WriteLn('DBG single: not assigned') else WriteLn('DBG single: assigned'); if Assigned(D) then JsonDocFree(D);
  Ok('StopWhenDone accepts extra after single value', ReadDoc('123 456', [jrfStopWhenDone], V, D)); if Assigned(D) then JsonDocFree(D);
  if not ReadDoc('[1,2] 456', [jrfStopWhenDone], V, D) then WriteLn('DBG array: not assigned') else WriteLn('DBG array: assigned'); if Assigned(D) then JsonDocFree(D);
  Ok('StopWhenDone accepts extra after array', ReadDoc('[1,2] 456', [jrfStopWhenDone], V, D)); if Assigned(D) then JsonDocFree(D);
  if not ReadDoc('{"a":1} 456', [jrfStopWhenDone], V, D) then WriteLn('DBG object: not assigned') else WriteLn('DBG object: assigned'); if Assigned(D) then JsonDocFree(D);
  Ok('StopWhenDone accepts extra after object', ReadDoc('{"a":1} 456', [jrfStopWhenDone], V, D)); if Assigned(D) then JsonDocFree(D);
  Ok('Default rejects extra after value', not ReadDoc('123 456', [], V, D));
end;

begin
  try
    Test_StopWhenDone;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


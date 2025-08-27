program simple_json_bom_test;

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
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); if Result then V := JsonDocGetRoot(D) else V := nil; end;

procedure Test_BOM;
var V: PJsonValue; D: TJsonDocument; S: RawByteString;
begin
  S := AnsiString(#$EF#$BB#$BF'{"a":1}');
  Ok('BOM rejected by default', not ReadDoc(S, [], V, D));
  Ok('BOM accepted with flag', ReadDoc(S, [jrfAllowBOM], V, D)); if Assigned(D) then JsonDocFree(D);
end;

begin
  try
    Test_BOM;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


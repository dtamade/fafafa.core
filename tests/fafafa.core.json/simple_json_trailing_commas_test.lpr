program simple_json_trailing_commas_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

var T,P,F: Integer;

procedure Ok(const Msg: string; Cond: Boolean);
begin Inc(T); if Cond then begin Inc(P); WriteLn('✓ ', Msg); end else begin Inc(F); WriteLn('✗ ', Msg); end; end;

function ReadDoc(const S: string; Flags: TJsonReadFlags; out V: PJsonValue; out D: TJsonDocument): Boolean;
var Alc: TAllocator; Err: TJsonError;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); if Result then V := JsonDocGetRoot(D) else V := nil; end;

procedure Test_TrailingCommas;
var V: PJsonValue; D: TJsonDocument;
const O1 = '{"a":1,}';
      A1 = '[1,2,]';
begin
  Ok('object trailing comma rejected by default', not ReadDoc(O1, [], V, D));
  Ok('array trailing comma rejected by default', not ReadDoc(A1, [], V, D));
  Ok('object trailing comma accepted', ReadDoc(O1, [jrfAllowTrailingCommas], V, D)); if Assigned(D) then JsonDocFree(D);
  Ok('array trailing comma accepted', ReadDoc(A1, [jrfAllowTrailingCommas], V, D)); if Assigned(D) then JsonDocFree(D);
end;

begin
  try
    Test_TrailingCommas;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


program simple_json_nested_containers_test;

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

function ReadDoc(const S: RawByteString; Flags: TJsonReadFlags): Boolean;
var Alc: TAllocator; Err: TJsonError; D: TJsonDocument;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); if Assigned(D) then JsonDocFree(D); end;

procedure Test_Nested;
var S: RawByteString; i: Integer;
begin
  Ok('object with nested object', ReadDoc('{"a":{"b":1}}', []));
  Ok('array with nested array', ReadDoc('[1,[2]]', []));
  S := '['; for i := 1 to 100 do S := S + '1,'; S := S + '0]';
  Ok('large array', ReadDoc(S, []));
end;

begin
  try
    Test_Nested;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


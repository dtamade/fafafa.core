program simple_json_object_value_array_test;

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

function TryRead(const S: RawByteString; Flags: TJsonReadFlags; out E: TJsonError): Boolean;
var Alc: TAllocator; D: TJsonDocument;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, E); Result := Assigned(D); if Result then JsonDocFree(D); end;

procedure Test_ObjValArr;
var E: TJsonError; S: RawByteString;
begin
  S := '{"a":[1,2]}'; Ok('obj value array simple', TryRead(S, [], E));
  S := '{"a":[{"b":1}]}'; Ok('obj value array of object', TryRead(S, [], E));
  S := '{"a":[{"n":1,"arr":[1,2,3]}]}'; Ok('obj value nested array field', TryRead(S, [], E));
end;

begin
  try
    Test_ObjValArr;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


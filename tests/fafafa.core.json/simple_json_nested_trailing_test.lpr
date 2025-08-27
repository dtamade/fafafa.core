program simple_json_nested_trailing_test;

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
var Alc: IAllocator; Err: TJsonError; D: TJsonDocument;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); if Assigned(D) then JsonDocFree(D) else WriteLn('[ERR] code=', Ord(Err.Code), ' pos=', Err.Position, ' msg=', Err.Message); end;

procedure Test_Trailing;
var Flags: TJsonReadFlags;
begin
  Flags := [jrfAllowTrailingCommas];
  // Object trailing
  Ok('object trailing {"a":1,}', ReadDoc('{"a":1,}', Flags));
  Ok('object nested trailing {"a":{"b":2,},}', ReadDoc('{"a":{"b":2,},}', Flags));
  // Array trailing
  Ok('array trailing [1,2,]', ReadDoc('[1,2,]', Flags));
  Ok('array nested trailing [1,[2,3,],]', ReadDoc('[1,[2,3,],]', Flags));
  // Mixed
  Ok('mixed {"a":[1,2,],"b":3,}', ReadDoc('{"a":[1,2,],"b":3,}', Flags));
end;

begin
  try
    Test_Trailing;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


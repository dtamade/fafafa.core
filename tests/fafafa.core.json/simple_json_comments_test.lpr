program simple_json_comments_test;

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

procedure Test_Comments;
var V: PJsonValue; D: TJsonDocument;
const S1 = '{//c1\n"a":1/* mid */}';
      S2 = '/*head*/[1,//x\n2/*y*/]/*tail*/';
begin
  Ok('object with comments rejected by default', not ReadDoc(S1, [], V, D));
  Ok('array with comments rejected by default', not ReadDoc(S2, [], V, D));
  Ok('object with comments accepted', ReadDoc(S1, [jrfAllowComments], V, D)); if Assigned(D) then JsonDocFree(D);
  Ok('array with comments accepted', ReadDoc(S2, [jrfAllowComments], V, D)); if Assigned(D) then JsonDocFree(D);
end;

begin
  try
    Test_Comments;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


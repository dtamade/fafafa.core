program simple_json_infnan_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

var
  T, P, F: Integer;

procedure Ok(const Msg: string; Cond: Boolean);
begin
  Inc(T); if Cond then begin Inc(P); WriteLn('✓ ', Msg); end else begin Inc(F); WriteLn('✗ ', Msg); end;
end;

function ReadDoc(const S: string; Flags: TJsonReadFlags; out V: PJsonValue; out D: TJsonDocument): Boolean;
var Alc: TAllocator; Err: TJsonError;
begin
  Alc := GetRtlAllocator();
  D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err);
  Result := Assigned(D);
  if Result then V := JsonDocGetRoot(D) else V := nil;
end;

procedure Test_DisallowByDefault;
var V: PJsonValue; D: TJsonDocument;
begin
  Ok('default: inf rejected', not ReadDoc('inf', [], V, D)); if Assigned(D) then JsonDocFree(D);
  Ok('default: NaN rejected', not ReadDoc('NaN', [], V, D)); if Assigned(D) then JsonDocFree(D);
end;

procedure Test_AllowInfNan;
var V: PJsonValue; D: TJsonDocument;
begin
  Ok('allow: inf', ReadDoc('inf', [jrfAllowInfAndNan], V, D)); if Assigned(D) then try Ok('is num real', JsonIsNum(V) and (JsonGetType(V) = YYJSON_TYPE_NUM)); finally JsonDocFree(D); end;
  Ok('allow: -Infinity', ReadDoc('-Infinity', [jrfAllowInfAndNan], V, D)); if Assigned(D) then try Ok('is num', JsonIsNum(V)); finally JsonDocFree(D); end;
  Ok('allow: NaN', ReadDoc('NaN', [jrfAllowInfAndNan], V, D)); if Assigned(D) then try Ok('is num', JsonIsNum(V)); finally JsonDocFree(D); end;
end;

begin
  try
    Test_DisallowByDefault;
    Test_AllowInfNan;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


program simple_json_number_as_raw_test;

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

procedure Test_NumberAsRaw;
var V: PJsonValue; D: TJsonDocument;
begin
  Ok('raw: 123', ReadDoc('123', [jrfNumberAsRaw], V, D)); if Assigned(D) then try Ok('is raw', JsonIsRaw(V)); Ok('raw len=3', JsonGetLen(V)=3); Ok('raw str=123', StrLComp(JsonGetRaw(V),'123',3)=0); finally JsonDocFree(D); end;
  Ok('raw: -1.25e2', ReadDoc('-1.25e2', [jrfNumberAsRaw], V, D)); if Assigned(D) then try Ok('is raw', JsonIsRaw(V)); Ok('len=7', JsonGetLen(V)=7); finally JsonDocFree(D); end;
  Ok('raw: NaN (with allow)', ReadDoc('NaN', [jrfAllowInfAndNan, jrfNumberAsRaw], V, D)); if Assigned(D) then try Ok('is raw', JsonIsRaw(V)); finally JsonDocFree(D); end;
end;

begin
  try
    Test_NumberAsRaw;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


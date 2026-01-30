program simple_json_bignum_as_raw_test;

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

procedure Test_BignumAsRaw;
var V: PJsonValue; D: TJsonDocument;
begin
  // 超过 U64 上界
  Ok('bignum raw: 18446744073709551616', ReadDoc('18446744073709551616', [jrfBignumAsRaw], V, D)); if Assigned(D) then try Ok('is raw', JsonIsRaw(V)); Ok('len>=20', JsonGetLen(V)>=20); finally JsonDocFree(D); end;
  // 超过 S64 上界
  Ok('bignum raw: 9223372036854775808', ReadDoc('9223372036854775808', [jrfBignumAsRaw], V, D)); if Assigned(D) then try Ok('not raw (fits u64)', not JsonIsRaw(V)); finally JsonDocFree(D); end;
  // 超过有限 double（1e309）
  Ok('bignum raw: 1e309', ReadDoc('1e309', [jrfBignumAsRaw], V, D)); if Assigned(D) then try Ok('is raw', JsonIsRaw(V)); finally JsonDocFree(D); end;
  // number-as-raw 覆盖 bignum-as-raw
  Ok('number-as-raw overrides', ReadDoc('123', [jrfNumberAsRaw, jrfBignumAsRaw], V, D)); if Assigned(D) then try Ok('is raw', JsonIsRaw(V)); finally JsonDocFree(D); end;
end;

begin
  try
    Test_BignumAsRaw;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


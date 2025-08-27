program simple_json_invalid_unicode_test;

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

procedure Test_InvalidUnicode;
var V: PJsonValue; D: TJsonDocument;
begin
  // 非法 UTF-8（高位字节单独出现）：默认拒绝
  Ok('invalid UTF-8 rejected by default', not ReadDoc('"' + AnsiChar(#$C3) + '"', [], V, D));
  // 非法 UTF-8（同上）：放宽时接受
  Ok('invalid UTF-8 accepted with flag', ReadDoc('"' + AnsiChar(#$C3) + '"', [jrfAllowInvalidUnicode], V, D)); if Assigned(D) then JsonDocFree(D);
  // 高代理缺失低代理：默认拒绝
  Ok('missing low surrogate rejected by default', not ReadDoc('"\uD800"', [], V, D));
  // 放宽时接受
  Ok('missing low surrogate accepted with flag', ReadDoc('"\uD800"', [jrfAllowInvalidUnicode], V, D)); if Assigned(D) then JsonDocFree(D);
  // 控制字符：默认拒绝，放宽接受
  Ok('control char rejected by default', not ReadDoc('"'+AnsiChar(#1)+'"', [], V, D));
  Ok('control char accepted with flag', ReadDoc('"'+AnsiChar(#1)+'"', [jrfAllowInvalidUnicode], V, D)); if Assigned(D) then JsonDocFree(D);
end;

begin
  try
    Test_InvalidUnicode;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


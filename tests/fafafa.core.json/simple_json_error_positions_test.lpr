program simple_json_error_positions_test;

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

function TryRead(const S: RawByteString; Flags: TJsonReadFlags; out Err: TJsonError): Boolean;
var Alc: IAllocator; D: TJsonDocument;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); if Assigned(D) then JsonDocFree(D); end;

procedure Test_StringErrors;
var E: TJsonError; S: RawByteString;
begin
  // unterminated string
  S := '"abc'; Ok('unterminated string pos=end', (not TryRead(S, [], E)) and (E.Position = Length(S)));
  // missing low surrogate
  S := '"\uD800"'; Ok('missing low surrogate pos at quote', (not TryRead(S, [], E)) and (E.Position > 0) and (S[E.Position+1] = '"'));
  // invalid UTF-8 byte (strict)
  S := '"'+AnsiChar(#$C3)+'"'; Ok('invalid utf8 pos at offending byte', (not TryRead(S, [], E)) and (E.Position > 0));
end;

procedure Test_ObjectErrors;
var E: TJsonError; S: RawByteString;
begin
  // missing colon after key
  S := '{"a" 1}'; Ok('missing colon position at value', (not TryRead(S, [], E)) and (E.Position > 0) and (S[E.Position+1] = '1'));
end;

procedure Test_NumberErrors;
var E: TJsonError; S: RawByteString;
begin
  // bad exponent digits
  S := '1e'; Ok('bad exponent digits pos=end', (not TryRead(S, [], E)) and (E.Position = Length(S)));
  // trailing extra (StopWhenDone off)
  S := '123 456'; Ok('trailing data at 4', (not TryRead(S, [], E)) and (E.Position = 4));
end;

begin
  try
    Test_StringErrors; Test_ObjectErrors; Test_NumberErrors;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


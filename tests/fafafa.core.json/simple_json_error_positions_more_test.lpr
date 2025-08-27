program simple_json_error_positions_more_test;

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
var Alc: TAllocator; D: TJsonDocument;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); if Assigned(D) then JsonDocFree(D); end;

procedure Test_ArrayErrors;
var E: TJsonError; S: RawByteString;
begin
  // missing comma between elements
  S := '[1 2]'; Ok('array missing comma at value', (not TryRead(S, [], E)) and (E.Position > 0) and (S[E.Position+1] = '2'));
  // missing closing bracket
  S := '[1,2'; Ok('array missing closing bracket pos=end', (not TryRead(S, [], E)) and (E.Position = Length(S)));
  // unexpected comma at array start
  S := '[,1]'; Ok('array unexpected comma at start', (not TryRead(S, [], E)) and (E.Position > 0) and (S[E.Position+1] = ','));
end;

procedure Test_ObjectMissingBrace;
var E: TJsonError; S: RawByteString;
begin
  S := '{"a":1'; Ok('object missing closing brace pos=end', (not TryRead(S, [], E)) and (E.Position = Length(S)));
end;

procedure Test_NumberIllegalChar;
var E: TJsonError; S: RawByteString;
begin
  S := '12x'; Ok('illegal char after number at pos=2 (0-based)', (not TryRead(S, [], E)) and (E.Position = 2));
end;

begin
  try
    Test_ArrayErrors; Test_ObjectMissingBrace; Test_NumberIllegalChar;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


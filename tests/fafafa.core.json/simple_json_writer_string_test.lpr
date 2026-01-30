program simple_json_writer_string_test;

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

function ReadDoc(const S: RawByteString; Flags: TJsonReadFlags; out D: TJsonDocument): Boolean;
var Alc: TAllocator; Err: TJsonError;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err); Result := Assigned(D); end;

function WriteDoc(ADoc: TJsonDocument; Flags: TJsonWriteFlags): string;
var Len: SizeUInt; P: PChar;
begin P := JsonWrite(ADoc, Flags, Len); Result := Copy(P, 1, Len); GetRtlAllocator().FreeMem(P); end;

procedure Test_EscapeUnicode;
var D: TJsonDocument; S: string;
begin
  if not ReadDoc('"héllö"', [], D) then begin Ok('parse input', False); Exit; end;
  S := WriteDoc(D, [jwfEscapeUnicode]);
  Ok('escape unicode to \uXXXX', Pos('\u00', S) > 0);
  if Assigned(D) then JsonDocFree(D);
end;

procedure Test_Slashes;
var D: TJsonDocument; S: string;
begin
  if not ReadDoc('"a/b"', [], D) then begin Ok('parse input', False); Exit; end;
  S := WriteDoc(D, [jwfEscapeSlashes]);
  Ok('escape slash as \/', Pos('\/', S) > 0);
  if Assigned(D) then JsonDocFree(D);
end;

procedure Test_InvalidBytes_With_Escape;
var D: TJsonDocument; S: string;
begin
  if not ReadDoc('"'+AnsiChar(#$C3)+'"', [jrfAllowInvalidUnicode], D) then begin Ok('parse input', False); Exit; end;
  S := WriteDoc(D, [jwfEscapeUnicode, jwfAllowInvalidUnicode]);
  Ok('invalid byte escaped as \\u00XX', (Pos('\u00C3', S) > 0) or (Pos('?"', S) > 0));
  if Assigned(D) then JsonDocFree(D);
end;

begin
  try
    Test_EscapeUnicode; Test_Slashes; Test_InvalidBytes_With_Escape;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


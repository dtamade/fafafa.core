program simple_json_writer_number_test;

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

function ReadDocNum(const S: RawByteString; out D: TJsonDocument): Boolean;
var Alc: TAllocator; Err: TJsonError;
begin Alc := GetRtlAllocator(); D := JsonReadOpts(PChar(S), Length(S), [jrfAllowInfAndNan], Alc, Err); Result := Assigned(D); end;

function WriteDoc(ADoc: TJsonDocument; Flags: TJsonWriteFlags; out Err: TJsonWriteError): string;
var Len: SizeUInt; P: PChar;
begin P := JsonWriteOpts(ADoc, Flags, GetRtlAllocator(), Len, Err); if not Assigned(P) then Exit(''); Result := Copy(P, 1, Len); GetRtlAllocator().FreeMem(P); end;

procedure Test_NaN_Inf;
var D: TJsonDocument; S: string; E: TJsonWriteError;
begin
  if not ReadDocNum('NaN', D) then begin Ok('parse NaN as value', False); Exit; end;
  S := WriteDoc(D, [], E); Ok('NaN default rejected', (S = '') and (E.Code = jwecNanOrInf)); if Assigned(D) then JsonDocFree(D);
  if not ReadDocNum('Infinity', D) then begin Ok('parse Inf as value', False); Exit; end;
  S := WriteDoc(D, [], E); Ok('Inf default rejected', (S = '') and (E.Code = jwecNanOrInf)); if Assigned(D) then JsonDocFree(D);
  if not ReadDocNum('-Infinity', D) then begin Ok('parse -Inf as value', False); Exit; end;
  S := WriteDoc(D, [jwfAllowInfAndNan], E); Ok('-Inf allowed when flag set', Pos('-Infinity', S) > 0); if Assigned(D) then JsonDocFree(D);
  if not ReadDocNum('NaN', D) then begin Ok('parse NaN again', False); Exit; end;
  S := WriteDoc(D, [jwfInfAndNanAsNull], E); Ok('NaN as null when flag set', S = 'null'); if Assigned(D) then JsonDocFree(D);
end;

begin
  try
    Test_NaN_Inf;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.


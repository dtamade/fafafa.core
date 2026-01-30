unit fafafa.core.benchmark.format_utils;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

type
  TKeyValueHandler = procedure(const Key, Value: string);

function JsonEscape(const S: string): string;
function CsvEscape(const S: string): string;
function FmtFixed(const AValue: Double; const ADecimals: Integer): string;
function SafeTimePerIter(const ATotal: Double; const AIterations: Integer): Double;
procedure ForEachKeyValue(const AFormat: string; aHandler: TKeyValueHandler);
procedure WriteTextUTF8(const AFileName, AContent: string; const AAppend: Boolean);

implementation

var
  GFileCS: TCriticalSection;

function JsonEscape(const S: string): string;
var
  i: Integer;
  c: Char;
  code: Integer;
begin
  // Robust JSON escape: control chars, backslash, and quote
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    case c of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      code := Ord(c);
      if code < 32 then
        Result := Result + '\u00' + IntToHex(code, 2)
      else
        Result := Result + c;
    end;
  end;
end;

function CsvEscape(const S: string): string;
begin
  // enclose with quotes and double the quotes
  Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';
end;

function FmtFixed(const AValue: Double; const ADecimals: Integer): string;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  if ADecimals <= 0 then
    Result := FormatFloat('0', AValue, FS)
  else
    Result := FormatFloat('0.' + StringOfChar('0', ADecimals), AValue, FS);
end;

function SafeTimePerIter(const ATotal: Double; const AIterations: Integer): Double;
begin
  if AIterations > 0 then
    Result := ATotal / AIterations
  else
    Result := 0.0;
end;

procedure ForEachKeyValue(const AFormat: string; aHandler: TKeyValueHandler);
var
  I, P: Integer;
  L, Tok, K, V: string;
begin
  if not Assigned(aHandler) then Exit;
  L := LowerCase(AFormat);
  I := 1;
  while I <= Length(L) do
  begin
    P := Pos(';', Copy(L, I, MaxInt));
    if P = 0 then Tok := Trim(Copy(L, I, MaxInt)) else Tok := Trim(Copy(L, I, P-1));
    if Tok <> '' then
    begin
      K := Tok; V := '';
      P := Pos('=', Tok);
      if P > 0 then
      begin
        K := Trim(Copy(Tok, 1, P-1));
        V := Trim(Copy(Tok, P+1, MaxInt));
      end;
      aHandler(K, V);
    end;
    if P = 0 then Break else I := I + P;
  end;
end;

procedure WriteTextUTF8(const AFileName, AContent: string; const AAppend: Boolean);
var
  FS: TFileStream;
  Mode: LongInt;
  Bytes: RawByteString;
  NeedSeekEnd: Boolean;
begin
  // Write UTF-8 text without BOM; rely on Lazarus default UTF-8 strings
  GFileCS.Enter;
  try
    NeedSeekEnd := AAppend and FileExists(AFileName);
    if NeedSeekEnd then
      Mode := fmOpenReadWrite or fmShareDenyWrite
    else
      Mode := fmCreate or fmShareDenyWrite;

    FS := TFileStream.Create(AFileName, Mode);
    try
      if NeedSeekEnd then
        FS.Seek(0, soEnd);
      Bytes := AContent;
      if Length(Bytes) > 0 then
        FS.WriteBuffer(Pointer(Bytes)^, Length(Bytes));
    finally
      FS.Free;
    end;
  finally
    GFileCS.Leave;
  end;
end;

initialization
  GFileCS := TCriticalSection.Create;

finalization
  FreeAndNil(GFileCS);

end.


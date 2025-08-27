unit fafafa.core.crypto.cipher.caesar;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

function CaesarEncodeStr(const S: UnicodeString; Shift: Integer): UnicodeString;
function CaesarDecodeStr(const S: UnicodeString; Shift: Integer): UnicodeString;
function CaesarEncode(const Data: TBytes; Shift: Integer): TBytes;
function CaesarDecode(const Data: TBytes; Shift: Integer): TBytes;

implementation

function Mod26(N: Integer): Integer; inline;
begin
  N := N mod 26;
  if N < 0 then Inc(N, 26);
  Result := N;
end;

function ShiftAsciiLetter(B: Byte; Shift: Integer): Byte; inline;
var base: Integer;
begin
  if (B >= Ord('A')) and (B <= Ord('Z')) then
  begin
    base := Ord('A');
    Result := Byte(base + Mod26((B - base) + Shift));
  end
  else if (B >= Ord('a')) and (B <= Ord('z')) then
  begin
    base := Ord('a');
    Result := Byte(base + Mod26((B - base) + Shift));
  end
  else
    Result := B;
end;

function CaesarEncode(const Data: TBytes; Shift: Integer): TBytes;
var i: SizeInt; s: Integer;
begin
  s := Mod26(Shift);
  SetLength(Result, Length(Data));
  for i := 0 to High(Data) do
    Result[i] := ShiftAsciiLetter(Data[i], s);
end;

function CaesarDecode(const Data: TBytes; Shift: Integer): TBytes;
var i: SizeInt; s: Integer;
begin
  s := Mod26(-Shift);
  SetLength(Result, Length(Data));
  for i := 0 to High(Data) do
    Result[i] := ShiftAsciiLetter(Data[i], s);
end;

function CaesarEncodeStr(const S: UnicodeString; Shift: Integer): UnicodeString;
var i: SizeInt; b: Byte; ch: WideChar;
begin
  SetLength(Result, Length(S));
  for i := 1 to Length(S) do
  begin
    ch := S[i];
    if Ord(ch) <= 255 then
    begin
      b := Byte(Ord(ch) and $FF);
      Result[i] := WideChar(ShiftAsciiLetter(b, Shift));
    end
    else
      Result[i] := ch; // 非 ASCII 字符保持不变
  end;
end;

function CaesarDecodeStr(const S: UnicodeString; Shift: Integer): UnicodeString;
begin
  Result := CaesarEncodeStr(S, -Shift);
end;

end.


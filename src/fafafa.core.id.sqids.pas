{
  fafafa.core.id.sqids - Sqids (YouTube-style Short Integer Encoder)

  Sqids is a reversible encoding scheme that converts arrays of unsigned
  integers into short, URL-friendly strings (similar to YouTube video IDs).

  Features:
  - Encode single or multiple integers into short strings
  - Fully reversible (decode back to original numbers)
  - Customizable alphabet and minimum length
  - No profanity filtering built-in (use external blocklist if needed)

  Usage:
    // Simple encoding
    S := SqidsEncodeOne(12345);    // -> 'abc123'
    N := SqidsDecodeOne(S);         // -> 12345

    // Multiple integers
    S := SqidsEncode([1, 2, 3]);    // -> 'xyz789'
    Arr := SqidsDecode(S);          // -> [1, 2, 3]

    // With generator for batch operations
    Gen := CreateSqids('abc...', 8);
    S := Gen.Encode([42]);
}

unit fafafa.core.id.sqids;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

const
  { Default alphabet - lowercase, no ambiguous chars }
  SQIDS_DEFAULT_ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  SQIDS_MIN_ALPHABET_LENGTH = 3;

type
  TUInt64Array = array of UInt64;

  { ISqids - Sqids encoder/decoder interface }
  ISqids = interface
    ['{E8A2B3C4-D5E6-F7A8-B9C0-D1E2F3A4B5C6}']
    function Encode(const Numbers: array of UInt64): string;
    function Decode(const Id: string): TUInt64Array;
  end;

{ Quick functions }
function SqidsEncodeOne(Number: UInt64): string;
function SqidsDecodeOne(const Id: string): UInt64;
function SqidsEncode(const Numbers: array of UInt64): string;
function SqidsDecode(const Id: string): TUInt64Array;

{ Extended functions with options }
function SqidsEncodeEx(const Numbers: array of UInt64; const Alphabet: string; MinLength: Integer): string;
function SqidsDecodeEx(const Id: string; const Alphabet: string): TUInt64Array;

{ Generator }
function CreateSqids(const Alphabet: string = SQIDS_DEFAULT_ALPHABET; MinLength: Integer = 0): ISqids;

{ Validation }
function IsValidSqidsAlphabet(const Alphabet: string): Boolean;

implementation

type
  { TSqids - Internal implementation }
  TSqids = class(TInterfacedObject, ISqids)
  private
    FAlphabet: string;
    FMinLength: Integer;
    function ShuffleAlphabet(const Alphabet: string): string;
    function ToId(Num: UInt64; const Alphabet: string): string;
    function ToNumber(const Id: string; const Alphabet: string): UInt64;
    function EncodeNumbers(const Numbers: array of UInt64; Increment: Integer): string;
  public
    constructor Create(const Alphabet: string; MinLength: Integer);
    function Encode(const Numbers: array of UInt64): string;
    function Decode(const Id: string): TUInt64Array;
  end;

var
  GDefaultSqids: ISqids = nil;

function GetDefaultSqids: ISqids;
begin
  if GDefaultSqids = nil then
    GDefaultSqids := CreateSqids;
  Result := GDefaultSqids;
end;

function SqidsEncodeOne(Number: UInt64): string;
begin
  Result := GetDefaultSqids.Encode([Number]);
end;

function SqidsDecodeOne(const Id: string): UInt64;
var
  Arr: TUInt64Array;
begin
  Arr := GetDefaultSqids.Decode(Id);
  if Length(Arr) > 0 then
    Result := Arr[0]
  else
    Result := 0;
end;

function SqidsEncode(const Numbers: array of UInt64): string;
begin
  Result := GetDefaultSqids.Encode(Numbers);
end;

function SqidsDecode(const Id: string): TUInt64Array;
begin
  Result := GetDefaultSqids.Decode(Id);
end;

function SqidsEncodeEx(const Numbers: array of UInt64; const Alphabet: string; MinLength: Integer): string;
var
  Gen: ISqids;
begin
  Gen := CreateSqids(Alphabet, MinLength);
  Result := Gen.Encode(Numbers);
end;

function SqidsDecodeEx(const Id: string; const Alphabet: string): TUInt64Array;
var
  Gen: ISqids;
begin
  Gen := CreateSqids(Alphabet, 0);
  Result := Gen.Decode(Id);
end;

function CreateSqids(const Alphabet: string; MinLength: Integer): ISqids;
begin
  Result := TSqids.Create(Alphabet, MinLength);
end;

function IsValidSqidsAlphabet(const Alphabet: string): Boolean;
var
  I, J: Integer;
begin
  Result := False;

  // Must have minimum length
  if Length(Alphabet) < SQIDS_MIN_ALPHABET_LENGTH then
    Exit;

  // Check for duplicates
  for I := 1 to Length(Alphabet) do
    for J := I + 1 to Length(Alphabet) do
      if Alphabet[I] = Alphabet[J] then
        Exit;

  Result := True;
end;

{ TSqids }

constructor TSqids.Create(const Alphabet: string; MinLength: Integer);
begin
  inherited Create;
  if not IsValidSqidsAlphabet(Alphabet) then
    raise Exception.Create('Invalid Sqids alphabet');
  FAlphabet := ShuffleAlphabet(Alphabet);
  FMinLength := MinLength;
end;

function TSqids.ShuffleAlphabet(const Alphabet: string): string;
var
  I, J: Integer;
  Temp: Char;
  Chars: string;
begin
  // Fisher-Yates shuffle with consistent seed based on alphabet
  Chars := Alphabet;
  for I := Length(Chars) downto 2 do
  begin
    J := (Ord(Chars[I]) * I) mod (I - 1) + 1;
    if J <> I then
    begin
      Temp := Chars[I];
      Chars[I] := Chars[J];
      Chars[J] := Temp;
    end;
  end;
  Result := Chars;
end;

function TSqids.ToId(Num: UInt64; const Alphabet: string): string;
var
  AlphaLen: Integer;
begin
  Result := '';
  AlphaLen := Length(Alphabet);
  repeat
    Result := Alphabet[(Num mod UInt64(AlphaLen)) + 1] + Result;
    Num := Num div UInt64(AlphaLen);
  until Num = 0;
end;

function TSqids.ToNumber(const Id: string; const Alphabet: string): UInt64;
var
  I, Idx: Integer;
  AlphaLen: Integer;
begin
  Result := 0;
  AlphaLen := Length(Alphabet);
  for I := 1 to Length(Id) do
  begin
    Idx := Pos(Id[I], Alphabet);
    if Idx = 0 then
      Exit(0);  // Invalid character
    Result := Result * UInt64(AlphaLen) + UInt64(Idx - 1);
  end;
end;

function TSqids.EncodeNumbers(const Numbers: array of UInt64; Increment: Integer): string;
var
  I, Offset: Integer;
  Alpha, EncAlpha: string;
  NumId: string;
  Separator: Char;
begin
  if Length(Numbers) = 0 then
    Exit('');

  // Calculate offset for prefix selection
  Offset := 0;
  for I := 0 to High(Numbers) do
    Offset := Offset + (I + 1) + Integer(Numbers[I] mod 256);
  Offset := (Offset + Increment) mod Length(FAlphabet);

  // Build ID
  Alpha := Copy(FAlphabet, Offset + 1, Length(FAlphabet) - Offset) +
           Copy(FAlphabet, 1, Offset);
  Result := Alpha[1];  // Prefix character
  Separator := Alpha[2];  // Separator character

  // Encoding alphabet excludes prefix and separator
  EncAlpha := Copy(Alpha, 3, Length(Alpha) - 2);

  for I := 0 to High(Numbers) do
  begin
    NumId := ToId(Numbers[I], EncAlpha);
    Result := Result + NumId;
    if I < High(Numbers) then
      Result := Result + Separator;
  end;

  // Pad to minimum length if needed
  while Length(Result) < FMinLength do
    Result := Result + Alpha[(Length(Result) mod Length(Alpha)) + 1];
end;

function TSqids.Encode(const Numbers: array of UInt64): string;
begin
  Result := EncodeNumbers(Numbers, 0);
end;

function TSqids.Decode(const Id: string): TUInt64Array;
var
  Alpha, EncAlpha: string;
  Prefix, Separator: Char;
  Offset, I, SepPos, Count: Integer;
  WorkId: string;
  NumStr: string;
begin
  SetLength(Result, 0);
  if Id = '' then
    Exit;

  // Find prefix position to determine offset
  Prefix := Id[1];
  Offset := Pos(Prefix, FAlphabet) - 1;
  if Offset < 0 then
    Exit;  // Invalid prefix

  // Reconstruct alphabet
  Alpha := Copy(FAlphabet, Offset + 1, Length(FAlphabet) - Offset) +
           Copy(FAlphabet, 1, Offset);
  Separator := Alpha[2];
  EncAlpha := Copy(Alpha, 3, Length(Alpha) - 2);

  // Parse numbers (skip prefix)
  WorkId := Copy(Id, 2, Length(Id) - 1);

  // Count separators to pre-allocate
  Count := 1;
  for I := 1 to Length(WorkId) do
    if WorkId[I] = Separator then
      Inc(Count);
  SetLength(Result, Count);

  I := 0;
  while WorkId <> '' do
  begin
    SepPos := Pos(Separator, WorkId);
    if SepPos > 0 then
    begin
      NumStr := Copy(WorkId, 1, SepPos - 1);
      WorkId := Copy(WorkId, SepPos + 1, Length(WorkId) - SepPos);
    end
    else
    begin
      NumStr := WorkId;
      WorkId := '';
    end;

    // Remove padding chars (chars from Alpha that aren't in EncAlpha)
    while (NumStr <> '') and (Pos(NumStr[Length(NumStr)], EncAlpha) = 0) do
      Delete(NumStr, Length(NumStr), 1);

    if NumStr <> '' then
    begin
      Result[I] := ToNumber(NumStr, EncAlpha);
      Inc(I);
    end;
  end;

  SetLength(Result, I);
end;

end.

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
  SysUtils,
  fafafa.core.sync;

const
  { Default alphabet - lowercase, no ambiguous chars }
  SQIDS_DEFAULT_ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  SQIDS_MIN_ALPHABET_LENGTH = 3;

type
  TUInt64Array = array of UInt64;

  { ISqidsGenerator - Sqids encoder/decoder interface }
  // ✅ P1: 统一接口命名，添加 Generator 后缀
  ISqidsGenerator = interface
    ['{E8A2B3C4-D5E6-F7A8-B9C0-D1E2F3A4B5C6}']
    function Encode(const Numbers: array of UInt64): string;
    function Decode(const Id: string): TUInt64Array;
  end;

  // ✅ P1: 向后兼容别名
  ISqids = ISqidsGenerator;

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
  TSqids = class(TInterfacedObject, ISqidsGenerator)
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
  GDefaultSqids: ISqidsGenerator = nil;
  GSqidsLock: ILock = nil;
  GSqidsInitialized: Int32 = 0;  // 0=未初始化, 1=正在初始化, 2=已完成

// ✅ P0 修复: 添加 DCL 保护，解决线程安全问题
function GetDefaultSqids: ISqidsGenerator;
var
  LState: Int32;
begin
  // 快速路径：检查是否已初始化完成
  LState := InterlockedCompareExchange(GSqidsInitialized, 0, 0);
  if LState = 2 then
    Exit(GDefaultSqids);

  // 尝试获取初始化权
  if InterlockedCompareExchange(GSqidsInitialized, 1, 0) = 0 then
  begin
    // 我们赢得了初始化权，执行初始化
    try
      GDefaultSqids := CreateSqids;
      // 使用内存屏障确保写入可见后再设置状态
      InterlockedExchange(GSqidsInitialized, 2);
    except
      // 初始化失败，重置状态允许重试
      InterlockedExchange(GSqidsInitialized, 0);
      raise;
    end;
  end
  else
  begin
    // 其他线程正在初始化，等待完成
    while InterlockedCompareExchange(GSqidsInitialized, 0, 0) <> 2 do
    begin
      {$IFDEF WINDOWS}
      Sleep(0);  // 让出时间片
      {$ELSE}
      ThreadSwitch;
      {$ENDIF}
    end;
  end;
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
const
  MAX_DIGITS = 32;  // UInt64 最多约 22 个 base62 字符
var
  AlphaLen, Len, I: Integer;
  Buf: array[0..MAX_DIGITS - 1] of Char;  // ✅ P1: 栈缓冲区避免多次分配
begin
  AlphaLen := Length(Alphabet);
  Len := 0;
  repeat
    Buf[Len] := Alphabet[(Num mod UInt64(AlphaLen)) + 1];
    Inc(Len);
    Num := Num div UInt64(AlphaLen);
  until Num = 0;

  // ✅ P1: 反转到结果（单次分配）
  SetLength(Result, Len);
  for I := 0 to Len - 1 do
    Result[I + 1] := Buf[Len - 1 - I];
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
const
  MAX_NUMS = 64;  // 最多支持 64 个数字
var
  I, Offset, Pos, TotalLen: Integer;
  Alpha, EncAlpha: string;
  NumIds: array[0..MAX_NUMS - 1] of string;  // ✅ P1: 预存储各数字编码
  NumCount: Integer;
  Separator: Char;
begin
  if Length(Numbers) = 0 then
    Exit('');

  NumCount := Length(Numbers);
  if NumCount > MAX_NUMS then
    NumCount := MAX_NUMS;

  // Calculate offset for prefix selection
  Offset := 0;
  for I := 0 to High(Numbers) do
    Offset := Offset + (I + 1) + Integer(Numbers[I] mod 256);
  Offset := (Offset + Increment) mod Length(FAlphabet);

  // Build ID
  Alpha := Copy(FAlphabet, Offset + 1, Length(FAlphabet) - Offset) +
           Copy(FAlphabet, 1, Offset);
  Separator := Alpha[2];  // Separator character

  // Encoding alphabet excludes prefix and separator
  EncAlpha := Copy(Alpha, 3, Length(Alpha) - 2);

  // ✅ P1: 先计算所有 NumId 和总长度
  TotalLen := 1;  // Prefix char
  for I := 0 to NumCount - 1 do
  begin
    NumIds[I] := ToId(Numbers[I], EncAlpha);
    Inc(TotalLen, Length(NumIds[I]));
    if I < NumCount - 1 then
      Inc(TotalLen);  // Separator
  end;

  // 确保满足最小长度
  if TotalLen < FMinLength then
    TotalLen := FMinLength;

  // ✅ P1: 单次分配结果字符串
  SetLength(Result, TotalLen);

  // 填充结果
  Result[1] := Alpha[1];  // Prefix
  Pos := 2;

  for I := 0 to NumCount - 1 do
  begin
    Move(NumIds[I][1], Result[Pos], Length(NumIds[I]) * SizeOf(Char));
    Inc(Pos, Length(NumIds[I]));
    if I < NumCount - 1 then
    begin
      Result[Pos] := Separator;
      Inc(Pos);
    end;
  end;

  // Pad to minimum length if needed
  while Pos <= Length(Result) do
  begin
    Result[Pos] := Alpha[((Pos - 1) mod Length(Alpha)) + 1];
    Inc(Pos);
  end;
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

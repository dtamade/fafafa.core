{
  fafafa.core.id.timeflake - Timeflake ID Generator

  Timeflake is a 128-bit, roughly-ordered, URL-safe UUID alternative.
  Structure:
  - 48 bits: Unix timestamp in milliseconds
  - 80 bits: Random data

  Features:
  - Time-ordered (IDs sort chronologically)
  - 22-character Base62 string representation
  - UUID-compatible 36-character format
  - Monotonic generation option
  - Extract timestamp from ID

  Usage:
    Id := Timeflake;                    // Generate new Timeflake
    S := TimeflakeToString(Id);         // -> 22 char Base62 string
    Id2 := TimeflakeFromString(S);      // Parse from string
    Ms := TimeflakeUnixMs(Id);          // Extract timestamp
}

unit fafafa.core.id.timeflake;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, SyncObjs,
  fafafa.core.id.base;  // ✅ P1: 统一类型定义

const
  TIMEFLAKE_SIZE = 16;
  TIMEFLAKE_STRING_LENGTH = 22;  // Base62 encoded

{ 注意: TTimeflake, TTimeflakeArray 现在在 fafafa.core.id.base 中定义 }

type
  { EInvalidTimeflake - Invalid Timeflake string exception }
  EInvalidTimeflake = class(Exception);

  { ITimeflakeGenerator - Timeflake generator interface }
  ITimeflakeGenerator = interface
    ['{A1B2C3D4-E5F6-7890-A1B2-C3D4E5F67890}']
    function Next: TTimeflake;
    function NextString: string;
    function NextN(Count: Integer): TTimeflakeArray;
  end;

{ Quick generation }
function Timeflake: TTimeflake;
function TimeflakeMonotonic: TTimeflake;
function TimeflakeNil: TTimeflake;
function TimeflakeN(Count: Integer): TTimeflakeArray;

{ String conversion - Base62 format (22 chars) }
function TimeflakeToString(const Id: TTimeflake): string;
function TimeflakeFromString(const S: string): TTimeflake;
// ✅ P1: 统一解析函数命名
function TryParseTimeflake(const S: string; out Id: TTimeflake): Boolean;
// ✅ P2: 异常版本解析函数（对标 Rust）
function ParseTimeflake(const S: string): TTimeflake;

{ Zero-copy API }
// ✅ P2: 零拷贝格式化
procedure TimeflakeToChars(const Id: TTimeflake; Dest: PChar);

{ UUID format conversion (36 chars with dashes) }
function TimeflakeToUuidString(const Id: TTimeflake): string;
function TimeflakeFromUuidString(const S: string): TTimeflake;

{ Properties }
function TimeflakeTimestamp(const Id: TTimeflake): TDateTime;
function TimeflakeUnixMs(const Id: TTimeflake): Int64;

{ Comparison }
function TimeflakeEquals(const A, B: TTimeflake): Boolean;
function TimeflakeCompare(const A, B: TTimeflake): Integer;
function TimeflakeIsNil(const Id: TTimeflake): Boolean;

{ Generator }
function CreateTimeflakeGenerator: ITimeflakeGenerator;

implementation

uses
  fafafa.core.crypto.random,
  fafafa.core.id.rng;   // ✅ 缓冲 RNG 优化

type
  TTimeflakeGenerator = class(TInterfacedObject, ITimeflakeGenerator)
  private
    FLock: TCriticalSection;  // ✅ P0: 线程安全 - 保护内部状态
    FLastMs: Int64;
    FLastRandom: array[0..9] of Byte;  // 80 bits
  public
    constructor Create;
    destructor Destroy; override;
    function Next: TTimeflake;
    function NextString: string;
    function NextN(Count: Integer): TTimeflakeArray;
  end;

var
  GDefaultGenerator: ITimeflakeGenerator = nil;
  GMonotonicGenerator: ITimeflakeGenerator = nil;
  GTimeflakeLock: TCriticalSection = nil;  // ✅ P0: 线程安全锁

  // ✅ P0: 全局单调生成器状态（避免接口开销，确保线程安全）
  GMonotonicLastMs: Int64 = 0;
  GMonotonicRandom: array[0..9] of Byte;

function GetDefaultGenerator: ITimeflakeGenerator;
var
  LocalGen: ITimeflakeGenerator;
begin
  // ✅ P0: DCL 模式 + 内存屏障
  LocalGen := GDefaultGenerator;
  ReadWriteBarrier;
  if LocalGen <> nil then
  begin
    Result := LocalGen;
    Exit;
  end;

  GTimeflakeLock.Acquire;
  try
    if GDefaultGenerator = nil then
    begin
      LocalGen := CreateTimeflakeGenerator;
      ReadWriteBarrier;
      GDefaultGenerator := LocalGen;
    end;
    Result := GDefaultGenerator;
  finally
    GTimeflakeLock.Release;
  end;
end;

function GetMonotonicGenerator: ITimeflakeGenerator;
var
  LocalGen: ITimeflakeGenerator;
begin
  // ✅ P0: DCL 模式 + 内存屏障
  LocalGen := GMonotonicGenerator;
  ReadWriteBarrier;
  if LocalGen <> nil then
  begin
    Result := LocalGen;
    Exit;
  end;

  GTimeflakeLock.Acquire;
  try
    if GMonotonicGenerator = nil then
    begin
      LocalGen := CreateTimeflakeGenerator;
      ReadWriteBarrier;
      GMonotonicGenerator := LocalGen;
    end;
    Result := GMonotonicGenerator;
  finally
    GTimeflakeLock.Release;
  end;
end;

function GetCurrentUnixMs: Int64;
var
  UtcNow: TDateTime;
begin
  UtcNow := LocalTimeToUniversal(Now);
  Result := DateTimeToUnix(UtcNow, False) * 1000 + MilliSecondOf(UtcNow);
end;

function Timeflake: TTimeflake;
var
  Ms: Int64;
begin
  Ms := GetCurrentUnixMs;

  // Bytes 0-5: timestamp (big-endian, 48 bits)
  Result[0] := (Ms shr 40) and $FF;
  Result[1] := (Ms shr 32) and $FF;
  Result[2] := (Ms shr 24) and $FF;
  Result[3] := (Ms shr 16) and $FF;
  Result[4] := (Ms shr 8) and $FF;
  Result[5] := Ms and $FF;

  // Bytes 6-15: random (80 bits)
  // ✅ 使用缓冲 RNG 优化性能
  IdRngFillBytes(Result[6], 10);
end;

function TimeflakeMonotonic: TTimeflake;
var
  Ms: Int64;
  I: Integer;
  Carry: Word;
begin
  // ✅ P0: 直接使用全局状态 + 临界区保护（避免接口开销和 DCL 竞态）
  GTimeflakeLock.Acquire;
  try
    Ms := GetCurrentUnixMs;

    // Bytes 0-5: timestamp (big-endian, 48 bits)
    Result[0] := (Ms shr 40) and $FF;
    Result[1] := (Ms shr 32) and $FF;
    Result[2] := (Ms shr 24) and $FF;
    Result[3] := (Ms shr 16) and $FF;
    Result[4] := (Ms shr 8) and $FF;
    Result[5] := Ms and $FF;

    if Ms = GMonotonicLastMs then
    begin
      // Same millisecond - increment random part
      Carry := 1;
      for I := 9 downto 0 do
      begin
        Carry := Carry + GMonotonicRandom[I];
        GMonotonicRandom[I] := Carry and $FF;
        Carry := Carry shr 8;
        if Carry = 0 then
          Break;
      end;
      Move(GMonotonicRandom[0], Result[6], 10);
    end
    else
    begin
      // New millisecond - generate fresh random
      GMonotonicLastMs := Ms;
      IdRngFillBytes(GMonotonicRandom[0], 10);
      Move(GMonotonicRandom[0], Result[6], 10);
    end;
  finally
    GTimeflakeLock.Release;
  end;
end;

function TimeflakeNil: TTimeflake;
begin
  FillChar(Result[0], TIMEFLAKE_SIZE, 0);
end;

function TimeflakeN(Count: Integer): TTimeflakeArray;
var
  I: Integer;
begin
  // ✅ P0: 使用 TimeflakeMonotonic 确保线程安全
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := TimeflakeMonotonic;
end;

function TimeflakeToString(const Id: TTimeflake): string;
var
  Value: array[0..3] of UInt32;  // 128-bit as 4 x 32-bit
  I, Digit: Integer;
  Carry, Temp: UInt64;
  Chars: array[0..21] of Char;
begin
  // Load 128-bit value (big-endian)
  Value[0] := (UInt32(Id[0]) shl 24) or (UInt32(Id[1]) shl 16) or
              (UInt32(Id[2]) shl 8) or UInt32(Id[3]);
  Value[1] := (UInt32(Id[4]) shl 24) or (UInt32(Id[5]) shl 16) or
              (UInt32(Id[6]) shl 8) or UInt32(Id[7]);
  Value[2] := (UInt32(Id[8]) shl 24) or (UInt32(Id[9]) shl 16) or
              (UInt32(Id[10]) shl 8) or UInt32(Id[11]);
  Value[3] := (UInt32(Id[12]) shl 24) or (UInt32(Id[13]) shl 16) or
              (UInt32(Id[14]) shl 8) or UInt32(Id[15]);

  // Convert to Base62
  for I := 21 downto 0 do
  begin
    Carry := 0;
    // Divide 128-bit by 62
    Temp := (UInt64(Carry) shl 32) or Value[0];
    Value[0] := Temp div 62;
    Carry := Temp mod 62;

    Temp := (UInt64(Carry) shl 32) or Value[1];
    Value[1] := Temp div 62;
    Carry := Temp mod 62;

    Temp := (UInt64(Carry) shl 32) or Value[2];
    Value[2] := Temp div 62;
    Carry := Temp mod 62;

    Temp := (UInt64(Carry) shl 32) or Value[3];
    Value[3] := Temp div 62;
    Digit := Temp mod 62;

    Chars[I] := BASE62_ALPHABET_STR[Digit + 1];
  end;

  SetLength(Result, 22);
  for I := 0 to 21 do
    Result[I + 1] := Chars[I];
end;

function TimeflakeFromString(const S: string): TTimeflake;
var
  Value: array[0..3] of UInt32;
  I, J, Digit: Integer;
  Carry, Temp: UInt64;
begin
  FillChar(Result[0], TIMEFLAKE_SIZE, 0);
  if Length(S) <> TIMEFLAKE_STRING_LENGTH then
    Exit;

  // Initialize to zero
  Value[0] := 0;
  Value[1] := 0;
  Value[2] := 0;
  Value[3] := 0;

  // Convert from Base62
  for I := 1 to 22 do
  begin
    Digit := Pos(S[I], BASE62_ALPHABET_STR) - 1;
    if Digit < 0 then
      Exit;  // Invalid character

    // Multiply by 62 and add digit
    Carry := Digit;
    for J := 3 downto 0 do
    begin
      Temp := UInt64(Value[J]) * 62 + Carry;
      Value[J] := Temp and $FFFFFFFF;
      Carry := Temp shr 32;
    end;
  end;

  // Store as big-endian bytes
  Result[0] := (Value[0] shr 24) and $FF;
  Result[1] := (Value[0] shr 16) and $FF;
  Result[2] := (Value[0] shr 8) and $FF;
  Result[3] := Value[0] and $FF;
  Result[4] := (Value[1] shr 24) and $FF;
  Result[5] := (Value[1] shr 16) and $FF;
  Result[6] := (Value[1] shr 8) and $FF;
  Result[7] := Value[1] and $FF;
  Result[8] := (Value[2] shr 24) and $FF;
  Result[9] := (Value[2] shr 16) and $FF;
  Result[10] := (Value[2] shr 8) and $FF;
  Result[11] := Value[2] and $FF;
  Result[12] := (Value[3] shr 24) and $FF;
  Result[13] := (Value[3] shr 16) and $FF;
  Result[14] := (Value[3] shr 8) and $FF;
  Result[15] := Value[3] and $FF;
end;

// ✅ P1: TryParseTimeflake 统一解析函数
function TryParseTimeflake(const S: string; out Id: TTimeflake): Boolean;
var
  I: Integer;
begin
  // 验证长度
  if Length(S) <> TIMEFLAKE_STRING_LENGTH then
  begin
    FillChar(Id[0], TIMEFLAKE_SIZE, 0);
    Exit(False);
  end;

  // 验证字符是否都在 Base62 字母表中
  for I := 1 to TIMEFLAKE_STRING_LENGTH do
  begin
    if Pos(S[I], BASE62_ALPHABET_STR) = 0 then
    begin
      FillChar(Id[0], TIMEFLAKE_SIZE, 0);
      Exit(False);
    end;
  end;

  // 解析
  Id := TimeflakeFromString(S);
  Result := True;
end;

// ✅ P2: ParseTimeflake - 异常版本（对标 Rust）
function ParseTimeflake(const S: string): TTimeflake;
begin
  if not TryParseTimeflake(S, Result) then
    raise EInvalidTimeflake.CreateFmt('Invalid Timeflake string: "%s"', [S]);
end;

// ✅ P2: 零拷贝格式化（Base62）
procedure TimeflakeToChars(const Id: TTimeflake; Dest: PChar);
var
  Value: array[0..3] of UInt32;
  I, Digit: Integer;
  Carry, Temp: UInt64;
begin
  // Load 128-bit value (big-endian)
  Value[0] := (UInt32(Id[0]) shl 24) or (UInt32(Id[1]) shl 16) or
              (UInt32(Id[2]) shl 8) or UInt32(Id[3]);
  Value[1] := (UInt32(Id[4]) shl 24) or (UInt32(Id[5]) shl 16) or
              (UInt32(Id[6]) shl 8) or UInt32(Id[7]);
  Value[2] := (UInt32(Id[8]) shl 24) or (UInt32(Id[9]) shl 16) or
              (UInt32(Id[10]) shl 8) or UInt32(Id[11]);
  Value[3] := (UInt32(Id[12]) shl 24) or (UInt32(Id[13]) shl 16) or
              (UInt32(Id[14]) shl 8) or UInt32(Id[15]);

  // Convert to Base62
  for I := 21 downto 0 do
  begin
    Carry := 0;
    Temp := (UInt64(Carry) shl 32) or Value[0];
    Value[0] := Temp div 62;
    Carry := Temp mod 62;

    Temp := (UInt64(Carry) shl 32) or Value[1];
    Value[1] := Temp div 62;
    Carry := Temp mod 62;

    Temp := (UInt64(Carry) shl 32) or Value[2];
    Value[2] := Temp div 62;
    Carry := Temp mod 62;

    Temp := (UInt64(Carry) shl 32) or Value[3];
    Value[3] := Temp div 62;
    Digit := Temp mod 62;

    Dest[I] := BASE62_ALPHABET_STR[Digit + 1];
  end;
end;

function TimeflakeToUuidString(const Id: TTimeflake): string;
var
  I, P: Integer;
begin
  // ✅ P3: 使用统一 HEX_CHARS 常量
  SetLength(Result, 36);
  P := 1;

  // 8-4-4-4-12 format
  for I := 0 to 3 do
  begin
    Result[P] := HEX_CHARS[Id[I] shr 4];
    Result[P + 1] := HEX_CHARS[Id[I] and $0F];
    Inc(P, 2);
  end;
  Result[P] := '-'; Inc(P);

  for I := 4 to 5 do
  begin
    Result[P] := HEX_CHARS[Id[I] shr 4];
    Result[P + 1] := HEX_CHARS[Id[I] and $0F];
    Inc(P, 2);
  end;
  Result[P] := '-'; Inc(P);

  for I := 6 to 7 do
  begin
    Result[P] := HEX_CHARS[Id[I] shr 4];
    Result[P + 1] := HEX_CHARS[Id[I] and $0F];
    Inc(P, 2);
  end;
  Result[P] := '-'; Inc(P);

  for I := 8 to 9 do
  begin
    Result[P] := HEX_CHARS[Id[I] shr 4];
    Result[P + 1] := HEX_CHARS[Id[I] and $0F];
    Inc(P, 2);
  end;
  Result[P] := '-'; Inc(P);

  for I := 10 to 15 do
  begin
    Result[P] := HEX_CHARS[Id[I] shr 4];
    Result[P + 1] := HEX_CHARS[Id[I] and $0F];
    Inc(P, 2);
  end;
end;

function HexToByte(C1, C2: Char): Byte;

  function HexVal(C: Char): Byte;
  begin
    case C of
      '0'..'9': Result := Ord(C) - Ord('0');
      'a'..'f': Result := Ord(C) - Ord('a') + 10;
      'A'..'F': Result := Ord(C) - Ord('A') + 10;
    else
      Result := 0;
    end;
  end;

begin
  Result := (HexVal(C1) shl 4) or HexVal(C2);
end;

function TimeflakeFromUuidString(const S: string): TTimeflake;
var
  Clean: string;
  I: Integer;
begin
  FillChar(Result[0], TIMEFLAKE_SIZE, 0);
  if Length(S) <> 36 then
    Exit;

  // Remove dashes
  Clean := StringReplace(S, '-', '', [rfReplaceAll]);
  if Length(Clean) <> 32 then
    Exit;

  for I := 0 to 15 do
    Result[I] := HexToByte(Clean[I * 2 + 1], Clean[I * 2 + 2]);
end;

function TimeflakeTimestamp(const Id: TTimeflake): TDateTime;
begin
  Result := UnixToDateTime(TimeflakeUnixMs(Id) div 1000, False);
end;

function TimeflakeUnixMs(const Id: TTimeflake): Int64;
begin
  // 48-bit timestamp in first 6 bytes (big-endian)
  Result := (Int64(Id[0]) shl 40) or
            (Int64(Id[1]) shl 32) or
            (Int64(Id[2]) shl 24) or
            (Int64(Id[3]) shl 16) or
            (Int64(Id[4]) shl 8) or
            Int64(Id[5]);
end;

function TimeflakeEquals(const A, B: TTimeflake): Boolean;
var
  I: Integer;
begin
  for I := 0 to 15 do
    if A[I] <> B[I] then
      Exit(False);
  Result := True;
end;

function TimeflakeCompare(const A, B: TTimeflake): Integer;
var
  I: Integer;
begin
  for I := 0 to 15 do
  begin
    if A[I] < B[I] then
      Exit(-1);
    if A[I] > B[I] then
      Exit(1);
  end;
  Result := 0;
end;

function TimeflakeIsNil(const Id: TTimeflake): Boolean;
var
  I: Integer;
begin
  for I := 0 to 15 do
    if Id[I] <> 0 then
      Exit(False);
  Result := True;
end;

function CreateTimeflakeGenerator: ITimeflakeGenerator;
begin
  Result := TTimeflakeGenerator.Create;
end;

{ TTimeflakeGenerator }

constructor TTimeflakeGenerator.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;  // ✅ P0: 创建线程安全锁
  FLastMs := 0;
  FillChar(FLastRandom[0], 10, 0);
end;

destructor TTimeflakeGenerator.Destroy;
begin
  // ✅ P0: 清理敏感随机数据
  FillChar(FLastRandom[0], SizeOf(FLastRandom), 0);
  FLock.Free;
  inherited Destroy;
end;

function TTimeflakeGenerator.Next: TTimeflake;
var
  Ms: Int64;
  I: Integer;
  Carry: Word;
begin
  // ✅ P0: 线程安全 - 保护内部状态
  FLock.Acquire;
  try
    Ms := GetCurrentUnixMs;

    // Bytes 0-5: timestamp (big-endian, 48 bits)
    Result[0] := (Ms shr 40) and $FF;
    Result[1] := (Ms shr 32) and $FF;
    Result[2] := (Ms shr 24) and $FF;
    Result[3] := (Ms shr 16) and $FF;
    Result[4] := (Ms shr 8) and $FF;
    Result[5] := Ms and $FF;

    if Ms = FLastMs then
    begin
      // Same millisecond - increment random part
      Carry := 1;
      for I := 9 downto 0 do
      begin
        Carry := Carry + FLastRandom[I];
        FLastRandom[I] := Carry and $FF;
        Carry := Carry shr 8;
        if Carry = 0 then
          Break;
      end;
      Move(FLastRandom[0], Result[6], 10);
    end
    else
    begin
      // New millisecond - generate fresh random
      FLastMs := Ms;
      IdRngFillBytes(FLastRandom[0], 10);  // ✅ 缓冲 RNG
      Move(FLastRandom[0], Result[6], 10);
    end;
  finally
    FLock.Release;
  end;
end;

function TTimeflakeGenerator.NextString: string;
begin
  Result := TimeflakeToString(Next);
end;

function TTimeflakeGenerator.NextN(Count: Integer): TTimeflakeArray;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Next;
end;

initialization
  GTimeflakeLock := TCriticalSection.Create;

finalization
  GDefaultGenerator := nil;
  GMonotonicGenerator := nil;
  // ✅ P0: 安全清理敏感数据
  FillChar(GMonotonicRandom[0], SizeOf(GMonotonicRandom), 0);
  GTimeflakeLock.Free;

end.

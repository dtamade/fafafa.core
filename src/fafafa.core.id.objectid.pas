{
  fafafa.core.id.objectid - MongoDB-style ObjectId Generator

  ObjectId is a 12-byte unique identifier used by MongoDB:
  - 4 bytes: Unix timestamp (seconds since epoch)
  - 5 bytes: Random value (unique per process)
  - 3 bytes: Incrementing counter

  Features:
  - Time-ordered (older IDs sort before newer)
  - 24-character hex string representation
  - Thread-safe counter increment
  - Extract timestamp from ID

  Usage:
    Id := ObjectId;                    // Generate new ObjectId
    S := ObjectIdToString(Id);         // -> '507f1f77bcf86cd799439011'
    Id2 := ObjectIdFromString(S);      // Parse from string
    TS := ObjectIdTimestamp(Id);       // Extract timestamp
}

unit fafafa.core.id.objectid;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, SyncObjs,
  fafafa.core.id.base;  // ✅ P1: 统一类型定义

const
  OBJECTID_SIZE = 12;
  OBJECTID_STRING_LENGTH = 24;

{ 注意: TObjectId, TObjectIdArray 现在在 fafafa.core.id.base 中定义 }

type
  { EInvalidObjectId - Invalid ObjectId string exception }
  EInvalidObjectId = class(Exception);

  { IObjectIdGenerator - ObjectId generator interface }
  IObjectIdGenerator = interface
    ['{F1A2B3C4-D5E6-F7A8-B9C0-D1E2F3A4B5C7}']
    function Next: TObjectId;
    function NextString: string;
    function NextN(Count: Integer): TObjectIdArray;
  end;

{ Quick generation }
function ObjectId: TObjectId;
function ObjectIdNil: TObjectId;
function ObjectIdN(Count: Integer): TObjectIdArray;

{ String conversion }
function ObjectIdToString(const Id: TObjectId): string;
function ObjectIdFromString(const S: string): TObjectId;
function IsValidObjectIdString(const S: string): Boolean;
// ✅ P1: 统一解析函数命名
function TryParseObjectId(const S: string; out Id: TObjectId): Boolean;
// ✅ P2: 异常版本解析函数（对标 Rust）
function ParseObjectId(const S: string): TObjectId;

{ Zero-copy API }
// ✅ P2: 零拷贝格式化
procedure ObjectIdToChars(const Id: TObjectId; Dest: PChar); inline;

{ Properties }
function ObjectIdTimestamp(const Id: TObjectId): TDateTime;
function ObjectIdUnixTimestamp(const Id: TObjectId): UInt32;

{ Comparison }
function ObjectIdEquals(const A, B: TObjectId): Boolean;
function ObjectIdCompare(const A, B: TObjectId): Integer;
function ObjectIdIsNil(const Id: TObjectId): Boolean;

{ Generator }
function CreateObjectIdGenerator: IObjectIdGenerator;

implementation

uses
  fafafa.core.crypto.random,
  fafafa.core.id.rng;  // ✅ 缓冲 RNG 优化

type
  TObjectIdGenerator = class(TInterfacedObject, IObjectIdGenerator)
  private
    FRandom: array[0..4] of Byte;  // 5-byte random per instance
    FCounter: UInt32;              // 3-byte counter (lower 24 bits)
  public
    constructor Create;
    destructor Destroy; override;  // ✅ P0: 清理敏感数据
    function Next: TObjectId;
    function NextString: string;
    function NextN(Count: Integer): TObjectIdArray;
  end;

var
  GDefaultGenerator: IObjectIdGenerator = nil;
  GObjectIdLock: TCriticalSection = nil;  // ✅ P0: 线程安全锁

function GetDefaultGenerator: IObjectIdGenerator;
var
  LocalGen: IObjectIdGenerator;
begin
  // ✅ P0: DCL 模式 + 内存屏障
  LocalGen := GDefaultGenerator;
  ReadWriteBarrier;
  if LocalGen <> nil then
  begin
    Result := LocalGen;
    Exit;
  end;

  GObjectIdLock.Acquire;
  try
    if GDefaultGenerator = nil then
    begin
      LocalGen := CreateObjectIdGenerator;
      ReadWriteBarrier;
      GDefaultGenerator := LocalGen;
    end;
    Result := GDefaultGenerator;
  finally
    GObjectIdLock.Release;
  end;
end;

function ObjectId: TObjectId;
begin
  Result := GetDefaultGenerator.Next;
end;

function ObjectIdNil: TObjectId;
begin
  FillChar(Result[0], OBJECTID_SIZE, 0);
end;

function ObjectIdN(Count: Integer): TObjectIdArray;
begin
  Result := GetDefaultGenerator.NextN(Count);
end;

function ObjectIdToString(const Id: TObjectId): string;
var
  I: Integer;
begin
  // ✅ P3: 使用统一 HEX_CHARS 常量
  SetLength(Result, OBJECTID_STRING_LENGTH);
  for I := 0 to 11 do
  begin
    Result[I * 2 + 1] := HEX_CHARS[Id[I] shr 4];
    Result[I * 2 + 2] := HEX_CHARS[Id[I] and $0F];
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

function ObjectIdFromString(const S: string): TObjectId;
var
  I: Integer;
begin
  FillChar(Result[0], OBJECTID_SIZE, 0);
  if Length(S) <> OBJECTID_STRING_LENGTH then
    Exit;

  for I := 0 to 11 do
    Result[I] := HexToByte(S[I * 2 + 1], S[I * 2 + 2]);
end;

function IsValidObjectIdString(const S: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Length(S) <> OBJECTID_STRING_LENGTH then
    Exit;

  for I := 1 to OBJECTID_STRING_LENGTH do
    if not (S[I] in ['0'..'9', 'a'..'f', 'A'..'F']) then
      Exit;

  Result := True;
end;

// ✅ P1: TryParseObjectId 统一解析函数
function TryParseObjectId(const S: string; out Id: TObjectId): Boolean;
begin
  if not IsValidObjectIdString(S) then
  begin
    FillChar(Id[0], OBJECTID_SIZE, 0);
    Exit(False);
  end;
  Id := ObjectIdFromString(S);
  Result := True;
end;

// ✅ P2: ParseObjectId - 异常版本（对标 Rust）
function ParseObjectId(const S: string): TObjectId;
begin
  if not TryParseObjectId(S, Result) then
    raise EInvalidObjectId.CreateFmt('Invalid ObjectId string: "%s"', [S]);
end;

// ✅ P2: 零拷贝格式化
procedure ObjectIdToChars(const Id: TObjectId; Dest: PChar); inline;
var
  I: Integer;
begin
  for I := 0 to 11 do
  begin
    Dest[I * 2] := HEX_CHARS[Id[I] shr 4];
    Dest[I * 2 + 1] := HEX_CHARS[Id[I] and $0F];
  end;
end;

function ObjectIdTimestamp(const Id: TObjectId): TDateTime;
begin
  Result := UnixToDateTime(ObjectIdUnixTimestamp(Id), False);
end;

function ObjectIdUnixTimestamp(const Id: TObjectId): UInt32;
begin
  // Big-endian 4-byte timestamp
  Result := (UInt32(Id[0]) shl 24) or
            (UInt32(Id[1]) shl 16) or
            (UInt32(Id[2]) shl 8) or
            UInt32(Id[3]);
end;

function ObjectIdEquals(const A, B: TObjectId): Boolean;
var
  I: Integer;
begin
  for I := 0 to 11 do
    if A[I] <> B[I] then
      Exit(False);
  Result := True;
end;

function ObjectIdCompare(const A, B: TObjectId): Integer;
var
  I: Integer;
begin
  for I := 0 to 11 do
  begin
    if A[I] < B[I] then
      Exit(-1);
    if A[I] > B[I] then
      Exit(1);
  end;
  Result := 0;
end;

function ObjectIdIsNil(const Id: TObjectId): Boolean;
var
  I: Integer;
begin
  for I := 0 to 11 do
    if Id[I] <> 0 then
      Exit(False);
  Result := True;
end;

function CreateObjectIdGenerator: IObjectIdGenerator;
begin
  Result := TObjectIdGenerator.Create;
end;

{ TObjectIdGenerator }

constructor TObjectIdGenerator.Create;
begin
  inherited Create;
  // Generate random 5-byte machine/process identifier
  // ✅ 使用缓冲 RNG 优化
  IdRngFillBytes(FRandom[0], 5);
  // Random starting counter
  IdRngFillBytes(FCounter, 3);
  FCounter := FCounter and $00FFFFFF;  // Keep only 24 bits
end;

destructor TObjectIdGenerator.Destroy;
begin
  // ✅ P0: 清理敏感随机数据
  FillChar(FRandom[0], SizeOf(FRandom), 0);
  FCounter := 0;
  inherited Destroy;
end;

function TObjectIdGenerator.Next: TObjectId;
var
  Timestamp: UInt32;
  Counter: UInt32;
begin
  // Get current Unix timestamp
  Timestamp := DateTimeToUnix(LocalTimeToUniversal(Now), False);

  // Atomically increment counter
  Counter := InterlockedIncrement(FCounter) and $00FFFFFF;

  // Bytes 0-3: timestamp (big-endian)
  Result[0] := (Timestamp shr 24) and $FF;
  Result[1] := (Timestamp shr 16) and $FF;
  Result[2] := (Timestamp shr 8) and $FF;
  Result[3] := Timestamp and $FF;

  // Bytes 4-8: random (5 bytes)
  Move(FRandom[0], Result[4], 5);

  // Bytes 9-11: counter (big-endian, 3 bytes)
  Result[9] := (Counter shr 16) and $FF;
  Result[10] := (Counter shr 8) and $FF;
  Result[11] := Counter and $FF;
end;

function TObjectIdGenerator.NextString: string;
begin
  Result := ObjectIdToString(Next);
end;

function TObjectIdGenerator.NextN(Count: Integer): TObjectIdArray;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Next;
end;

initialization
  GObjectIdLock := TCriticalSection.Create;

finalization
  GDefaultGenerator := nil;
  GObjectIdLock.Free;

end.

{
  fafafa.core.id.snowflake.record — Strong typed Snowflake ID record API

  - Wraps TSnowflakeID (QWord) with typed methods for component extraction
  - Provides specialized exception types
  - 41-bit timestamp / 10-bit workerId / 12-bit sequence
}

unit fafafa.core.id.snowflake.record;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.base,  // ✅ SNOWFLAKE-002: 引入 ECore 基类
  fafafa.core.id.snowflake;

type
  // Specialized exceptions for Snowflake
  ESnowflakeError = class(ECore);  // ✅ SNOWFLAKE-002: 继承自 ECore
  ESnowflakeClockRollback = class(ESnowflakeError);
  ESnowflakeInvalidConfig = class(ESnowflakeError);
  ESnowflakeSequenceOverflow = class(ESnowflakeError);

  TSnowflakeIDRec = record
  private
    FValue: TSnowflakeID;
    FEpochMs: Int64;
  public
    // Construction
    class function FromRaw(AValue: TSnowflakeID; AEpochMs: Int64 = 1288834974657): TSnowflakeIDRec; static; inline;
    function ToRaw: TSnowflakeID; inline;

    // Component extraction
    function TimestampMs: Int64; inline;  // Unix epoch milliseconds
    function WorkerId: Word; inline;
    function Sequence: Word; inline;

    // Properties
    function IsNil: Boolean; inline;
    function Equals(const B: TSnowflakeIDRec): Boolean; inline;
    function Hash: UInt32; inline;

    // Ordering (natural 64-bit ordering = time ordering for same epoch)
    function CompareTo(const B: TSnowflakeIDRec): Integer; inline;
    function LessThan(const B: TSnowflakeIDRec): Boolean; inline;

    // Format
    function ToString: string; inline;       // Decimal string
    function ToHexString: string; inline;    // Hex string (16 chars)

    // Parse
    class function TryParse(const S: string; out R: TSnowflakeIDRec; AEpochMs: Int64 = 1288834974657): Boolean; static;
    class function TryParseHex(const S: string; out R: TSnowflakeIDRec; AEpochMs: Int64 = 1288834974657): Boolean; static;

    // Operator overloads
    class operator = (const A, B: TSnowflakeIDRec): Boolean; inline;
    class operator <> (const A, B: TSnowflakeIDRec): Boolean; inline;
    class operator < (const A, B: TSnowflakeIDRec): Boolean; inline;
    class operator <= (const A, B: TSnowflakeIDRec): Boolean; inline;
    class operator > (const A, B: TSnowflakeIDRec): Boolean; inline;
    class operator >= (const A, B: TSnowflakeIDRec): Boolean; inline;

    // Constants
    class function NilValue: TSnowflakeIDRec; static; inline;
  end;

implementation

{ TSnowflakeIDRec }

class function TSnowflakeIDRec.FromRaw(AValue: TSnowflakeID; AEpochMs: Int64): TSnowflakeIDRec;
begin
  Result.FValue := AValue;
  Result.FEpochMs := AEpochMs;
end;

function TSnowflakeIDRec.ToRaw: TSnowflakeID;
begin
  Result := FValue;
end;

function TSnowflakeIDRec.TimestampMs: Int64;
begin
  Result := fafafa.core.id.snowflake.Snowflake_TimestampMs(FValue, FEpochMs);
end;

function TSnowflakeIDRec.WorkerId: Word;
begin
  Result := fafafa.core.id.snowflake.Snowflake_WorkerId(FValue);
end;

function TSnowflakeIDRec.Sequence: Word;
begin
  Result := fafafa.core.id.snowflake.Snowflake_Sequence(FValue);
end;

function TSnowflakeIDRec.IsNil: Boolean;
begin
  Result := FValue = 0;
end;

function TSnowflakeIDRec.Equals(const B: TSnowflakeIDRec): Boolean;
begin
  Result := FValue = B.FValue;
end;

function TSnowflakeIDRec.Hash: UInt32;
const
  FNV_OFFSET_BASIS = $811C9DC5;
  FNV_PRIME = $01000193;
var
  i: Integer;
  bytes: array[0..7] of Byte absolute FValue;
begin
  // FNV-1a hash
  Result := FNV_OFFSET_BASIS;
  for i := 0 to 7 do
  begin
    Result := Result xor bytes[i];
    Result := Result * FNV_PRIME;
  end;
end;

function TSnowflakeIDRec.CompareTo(const B: TSnowflakeIDRec): Integer;
begin
  if FValue < B.FValue then Exit(-1);
  if FValue > B.FValue then Exit(1);
  Result := 0;
end;

function TSnowflakeIDRec.LessThan(const B: TSnowflakeIDRec): Boolean;
begin
  Result := FValue < B.FValue;
end;

function TSnowflakeIDRec.ToString: string;
begin
  Result := IntToStr(FValue);
end;

function TSnowflakeIDRec.ToHexString: string;
begin
  Result := IntToHex(FValue, 16);
end;

class function TSnowflakeIDRec.TryParse(const S: string; out R: TSnowflakeIDRec; AEpochMs: Int64): Boolean;
var
  V: QWord;
  Code: Integer;
begin
  Val(S, V, Code);
  if Code <> 0 then Exit(False);
  R.FValue := V;
  R.FEpochMs := AEpochMs;
  Result := True;
end;

class function TSnowflakeIDRec.TryParseHex(const S: string; out R: TSnowflakeIDRec; AEpochMs: Int64): Boolean;
var
  V: QWord;
  Code: Integer;
  HexStr: string;
begin
  if Length(S) = 0 then Exit(False);
  if (S[1] = '$') or ((Length(S) >= 2) and (S[1] = '0') and ((S[2] = 'x') or (S[2] = 'X'))) then
    HexStr := S
  else
    HexStr := '$' + S;
  Val(HexStr, V, Code);
  if Code <> 0 then Exit(False);
  R.FValue := V;
  R.FEpochMs := AEpochMs;
  Result := True;
end;

class function TSnowflakeIDRec.NilValue: TSnowflakeIDRec;
begin
  Result.FValue := 0;
  Result.FEpochMs := 1288834974657;
end;

{ Operator overloads }

class operator TSnowflakeIDRec.= (const A, B: TSnowflakeIDRec): Boolean;
begin
  Result := A.Equals(B);
end;

class operator TSnowflakeIDRec.<> (const A, B: TSnowflakeIDRec): Boolean;
begin
  Result := not A.Equals(B);
end;

class operator TSnowflakeIDRec.< (const A, B: TSnowflakeIDRec): Boolean;
begin
  Result := A.FValue < B.FValue;
end;

class operator TSnowflakeIDRec.<= (const A, B: TSnowflakeIDRec): Boolean;
begin
  Result := A.FValue <= B.FValue;
end;

class operator TSnowflakeIDRec.> (const A, B: TSnowflakeIDRec): Boolean;
begin
  Result := A.FValue > B.FValue;
end;

class operator TSnowflakeIDRec.>= (const A, B: TSnowflakeIDRec): Boolean;
begin
  Result := A.FValue >= B.FValue;
end;

end.

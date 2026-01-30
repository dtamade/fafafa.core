{
  fafafa.core.id.ulid.record — Strong typed ULID record API

  - Wraps TUlid128 with typed methods for parse/format/compare
  - Delegates to fafafa.core.id.ulid implementation to avoid duplication
  - Crockford Base32 encoding (26 chars)
  - Base58 encoding support via codec
}

unit fafafa.core.id.ulid.record;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.base,  // ✅ ULID-001: 引入 ECore 基类
  fafafa.core.id.ulid;

type
  EUlidParseError = class(ECore);  // ✅ ULID-001: 继承自 ECore

  TULID = record
  private
    F: TUlid128;
  public
    // Construction
    class function FromBytes(const A: TUlid128): TULID; static; inline;
    function ToBytes: TUlid128; inline;

    // Parse & Format (Crockford Base32)
    class function TryParse(const S: string; out R: TULID): Boolean; static;
    class function TryParseStrict(const S: string; out R: TULID): Boolean; static;
    class function Parse(const S: string): TULID; static; // raises on error
    function ToString: string; inline;

    // Base58 encoding
    function ToBase58: string; inline;
    class function TryFromBase58(const S: string; out R: TULID): Boolean; static;
    class function TryFromBase58Strict(const S: string; out R: TULID): Boolean; static;
    class function FromBase58(const S: string): TULID; static; // raises on error

    // Properties
    function TimestampMs: Int64; inline;
    function IsNil: Boolean; inline;
    function Equals(const B: TULID): Boolean; inline;
    function Hash: UInt32; inline;

    // Ordering (bytewise lex, suitable for DB ordering)
    function CompareLex(const B: TULID): Integer; inline;
    function LessThan(const B: TULID): Boolean; inline;

    // Operator overloads
    class operator = (const A, B: TULID): Boolean; inline;
    class operator <> (const A, B: TULID): Boolean; inline;
    class operator < (const A, B: TULID): Boolean; inline;
    class operator <= (const A, B: TULID): Boolean; inline;
    class operator > (const A, B: TULID): Boolean; inline;
    class operator >= (const A, B: TULID): Boolean; inline;

    // Generators
    class function New: TULID; static; inline;
    class function NewAt(const TimestampMs: Int64): TULID; static; inline;

    // Conversion to/from UUID (same 128 bits, different encoding)
    function ToUuidBytes: TUlid128; inline;

    // Constants
    class function NilValue: TULID; static; inline;
  end;

implementation

uses
  fafafa.core.id.codec;

{ TULID }

class function TULID.FromBytes(const A: TUlid128): TULID;
begin
  Result.F := A;
end;

function TULID.ToBytes: TUlid128;
begin
  Result := F;
end;

class function TULID.TryParse(const S: string; out R: TULID): Boolean;
var A: TUlid128;
begin
  Result := fafafa.core.id.ulid.TryParseUlid(S, A);
  if Result then R.F := A;
end;

class function TULID.TryParseStrict(const S: string; out R: TULID): Boolean;
var A: TUlid128;
begin
  Result := fafafa.core.id.ulid.TryParseUlidStrict(S, A);
  if Result then R.F := A;
end;

class function TULID.Parse(const S: string): TULID;
var A: TUlid128;
begin
  if not fafafa.core.id.ulid.TryParseUlid(S, A) then
    raise EUlidParseError.CreateFmt('invalid ULID: %s', [S]);
  Result.F := A;
end;

function TULID.ToString: string;
begin
  Result := fafafa.core.id.ulid.UlidToString(F);
end;

function TULID.ToBase58: string;
begin
  Result := fafafa.core.id.codec.UlidToBase58(F);
end;

class function TULID.TryFromBase58(const S: string; out R: TULID): Boolean;
var A: TUlid128;
begin
  Result := fafafa.core.id.codec.TryParseUlidBase58(S, A);
  if Result then R.F := A;
end;

class function TULID.TryFromBase58Strict(const S: string; out R: TULID): Boolean;
var A: TUlid128;
begin
  Result := fafafa.core.id.codec.TryParseUlidBase58Strict(S, A);
  if Result then R.F := A;
end;

class function TULID.FromBase58(const S: string): TULID;
var A: TUlid128;
begin
  if not fafafa.core.id.codec.TryParseUlidBase58(S, A) then
    raise EUlidParseError.CreateFmt('invalid ULID Base58: %s', [S]);
  Result.F := A;
end;

function TULID.TimestampMs: Int64;
begin
  // ✅ P0: 直接从原始字节提取时间戳，避免 ToString 绕行
  Result := fafafa.core.id.ulid.Ulid_TimestampMsRaw(F);
end;

function TULID.IsNil: Boolean;
const
  ZERO16: array[0..15] of Byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
begin
  // ✅ P0: 使用 CompareMem 避免未对齐访问（跨平台安全）
  Result := CompareMem(@F[0], @ZERO16[0], 16);
end;

function TULID.Equals(const B: TULID): Boolean;
begin
  Result := CompareMem(@F[0], @B.F[0], SizeOf(F));
end;

function TULID.Hash: UInt32;
const
  FNV_OFFSET_BASIS = $811C9DC5;
  FNV_PRIME = $01000193;
var
  i: Integer;
begin
  // FNV-1a hash for better distribution
  Result := FNV_OFFSET_BASIS;
  for i := 0 to 15 do
  begin
    Result := Result xor F[i];
    Result := Result * FNV_PRIME;
  end;
end;

function TULID.CompareLex(const B: TULID): Integer;
var i: Integer;
begin
  for i := 0 to 15 do
  begin
    if F[i] < B.F[i] then Exit(-1);
    if F[i] > B.F[i] then Exit(1);
  end;
  Result := 0;
end;

function TULID.LessThan(const B: TULID): Boolean;
begin
  Result := CompareLex(B) < 0;
end;

class function TULID.New: TULID;
begin
  Result.F := fafafa.core.id.ulid.UlidNow_Raw;
end;

class function TULID.NewAt(const TimestampMs: Int64): TULID;
begin
  Result.F := fafafa.core.id.ulid.Ulid_Raw(TimestampMs);
end;

function TULID.ToUuidBytes: TUlid128;
begin
  // ULID and UUID are both 128 bits, same byte layout
  Result := F;
end;

class function TULID.NilValue: TULID;
begin
  FillChar(Result.F[0], SizeOf(Result.F), 0);
end;

{ Operator overloads }

class operator TULID.= (const A, B: TULID): Boolean;
begin
  Result := A.Equals(B);
end;

class operator TULID.<> (const A, B: TULID): Boolean;
begin
  Result := not A.Equals(B);
end;

class operator TULID.< (const A, B: TULID): Boolean;
begin
  Result := A.CompareLex(B) < 0;
end;

class operator TULID.<= (const A, B: TULID): Boolean;
begin
  Result := A.CompareLex(B) <= 0;
end;

class operator TULID.> (const A, B: TULID): Boolean;
begin
  Result := A.CompareLex(B) > 0;
end;

class operator TULID.>= (const A, B: TULID): Boolean;
begin
  Result := A.CompareLex(B) >= 0;
end;

end.

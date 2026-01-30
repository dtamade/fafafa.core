{
  fafafa.core.id.ksuid.record — Strong typed KSUID record API

  - Wraps TKsuid160 with typed methods for parse/format/compare
  - Delegates to fafafa.core.id.ksuid implementation to avoid duplication
  - Base62 encoding (27 chars)
  - Base58 encoding support via codec
}

unit fafafa.core.id.ksuid.record;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.base,  // ✅ KSUID-001: 引入 ECore 基类
  fafafa.core.id.ksuid;

type
  EKsuidParseError = class(ECore);  // ✅ KSUID-001: 继承自 ECore

  TKSUID = record
  private
    F: TKsuid160;
  public
    // Construction
    class function FromBytes(const A: TKsuid160): TKSUID; static; inline;
    function ToBytes: TKsuid160; inline;

    // Parse & Format (Base62)
    class function TryParse(const S: string; out R: TKSUID): Boolean; static;
    class function TryParseStrict(const S: string; out R: TKSUID): Boolean; static;
    class function Parse(const S: string): TKSUID; static; // raises on error
    function ToString: string; inline;

    // Base58 encoding
    function ToBase58: string; inline;
    class function TryFromBase58(const S: string; out R: TKSUID): Boolean; static;
    class function TryFromBase58Strict(const S: string; out R: TKSUID): Boolean; static;
    class function FromBase58(const S: string): TKSUID; static; // raises on error

    // Properties
    function TimestampUnixSeconds: Int64; inline;
    function TimestampMs: Int64; inline; // Unix epoch milliseconds (seconds * 1000)
    function IsNil: Boolean; inline;
    function Equals(const B: TKSUID): Boolean; inline;
    function Hash: UInt32; inline;

    // Ordering (bytewise lex, suitable for DB ordering)
    function CompareLex(const B: TKSUID): Integer; inline;
    function LessThan(const B: TKSUID): Boolean; inline;

    // Generators
    class function New: TKSUID; static; inline;
    class function NewAt(const UnixSeconds: Int64): TKSUID; static; inline;

    // Operator overloads
    class operator = (const A, B: TKSUID): Boolean; inline;
    class operator <> (const A, B: TKSUID): Boolean; inline;
    class operator < (const A, B: TKSUID): Boolean; inline;
    class operator <= (const A, B: TKSUID): Boolean; inline;
    class operator > (const A, B: TKSUID): Boolean; inline;
    class operator >= (const A, B: TKSUID): Boolean; inline;

    // Constants
    class function NilValue: TKSUID; static; inline;
  end;

implementation

uses
  fafafa.core.id.codec;

{ TKSUID }

class function TKSUID.FromBytes(const A: TKsuid160): TKSUID;
begin
  Result.F := A;
end;

function TKSUID.ToBytes: TKsuid160;
begin
  Result := F;
end;

class function TKSUID.TryParse(const S: string; out R: TKSUID): Boolean;
var A: TKsuid160;
begin
  Result := fafafa.core.id.ksuid.TryParseKsuid(S, A);
  if Result then R.F := A;
end;

class function TKSUID.TryParseStrict(const S: string; out R: TKSUID): Boolean;
var A: TKsuid160;
begin
  Result := fafafa.core.id.ksuid.TryParseKsuidStrict(S, A);
  if Result then R.F := A;
end;

class function TKSUID.Parse(const S: string): TKSUID;
var A: TKsuid160;
begin
  if not fafafa.core.id.ksuid.TryParseKsuid(S, A) then
    raise EKsuidParseError.CreateFmt('invalid KSUID: %s', [S]);
  Result.F := A;
end;

function TKSUID.ToString: string;
begin
  Result := fafafa.core.id.ksuid.KsuidToString(F);
end;

function TKSUID.ToBase58: string;
begin
  Result := fafafa.core.id.codec.KsuidToBase58(F);
end;

class function TKSUID.TryFromBase58(const S: string; out R: TKSUID): Boolean;
var A: TKsuid160;
begin
  Result := fafafa.core.id.codec.TryParseKsuidBase58(S, A);
  if Result then R.F := A;
end;

class function TKSUID.TryFromBase58Strict(const S: string; out R: TKSUID): Boolean;
var A: TKsuid160;
begin
  Result := fafafa.core.id.codec.TryParseKsuidBase58Strict(S, A);
  if Result then R.F := A;
end;

class function TKSUID.FromBase58(const S: string): TKSUID;
var A: TKsuid160;
begin
  if not fafafa.core.id.codec.TryParseKsuidBase58(S, A) then
    raise EKsuidParseError.CreateFmt('invalid KSUID Base58: %s', [S]);
  Result.F := A;
end;

function TKSUID.TimestampUnixSeconds: Int64;
begin
  Result := fafafa.core.id.ksuid.Ksuid_TimestampUnixSeconds(ToString);
end;

function TKSUID.TimestampMs: Int64;
begin
  Result := TimestampUnixSeconds * 1000;
end;

function TKSUID.IsNil: Boolean;
var i: Integer;
begin
  for i := 0 to 19 do
    if F[i] <> 0 then Exit(False);
  Result := True;
end;

function TKSUID.Equals(const B: TKSUID): Boolean;
begin
  Result := CompareMem(@F[0], @B.F[0], SizeOf(F));
end;

function TKSUID.Hash: UInt32;
const
  FNV_OFFSET_BASIS = $811C9DC5;
  FNV_PRIME = $01000193;
var
  i: Integer;
begin
  // FNV-1a hash for better distribution
  Result := FNV_OFFSET_BASIS;
  for i := 0 to 19 do
  begin
    Result := Result xor F[i];
    Result := Result * FNV_PRIME;
  end;
end;

function TKSUID.CompareLex(const B: TKSUID): Integer;
var i: Integer;
begin
  for i := 0 to 19 do
  begin
    if F[i] < B.F[i] then Exit(-1);
    if F[i] > B.F[i] then Exit(1);
  end;
  Result := 0;
end;

function TKSUID.LessThan(const B: TKSUID): Boolean;
begin
  Result := CompareLex(B) < 0;
end;

class function TKSUID.New: TKSUID;
begin
  Result.F := fafafa.core.id.ksuid.KsuidNow_Raw;
end;

class function TKSUID.NewAt(const UnixSeconds: Int64): TKSUID;
begin
  Result.F := fafafa.core.id.ksuid.Ksuid_Raw(UnixSeconds);
end;

class function TKSUID.NilValue: TKSUID;
begin
  FillChar(Result.F[0], SizeOf(Result.F), 0);
end;

{ Operator overloads }

class operator TKSUID.= (const A, B: TKSUID): Boolean;
begin
  Result := A.Equals(B);
end;

class operator TKSUID.<> (const A, B: TKSUID): Boolean;
begin
  Result := not A.Equals(B);
end;

class operator TKSUID.< (const A, B: TKSUID): Boolean;
begin
  Result := A.CompareLex(B) < 0;
end;

class operator TKSUID.<= (const A, B: TKSUID): Boolean;
begin
  Result := A.CompareLex(B) <= 0;
end;

class operator TKSUID.> (const A, B: TKSUID): Boolean;
begin
  Result := A.CompareLex(B) > 0;
end;

class operator TKSUID.>= (const A, B: TKSUID): Boolean;
begin
  Result := A.CompareLex(B) >= 0;
end;

end.

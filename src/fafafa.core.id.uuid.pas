{
  fafafa.core.id.uuid — Strong typed UUID record API

  - Wraps TUuid128 with typed methods for parse/format/version/compare
  - Delegates to fafafa.core.id implementation to avoid duplication
}

unit fafafa.core.id.uuid;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.id;


type
  EUuidParseError = class(Exception);

  TUUID = record
  private
    F: TUuid128;
  public
    // Construction
    class function FromBytes(const A: TUuid128): TUUID; static; inline;
    function ToBytes: TUuid128; inline;

    // Parse & Format
    class function TryParse(const S: string; out R: TUUID): Boolean; static;
    class function TryParseRelaxed(const S: string; out R: TUUID): Boolean; static;
    class function Parse(const S: string): TUUID; static; // strict, raises on error
    function ToString: string; inline;
    function ToStringNoDash: string; inline;
    function ToBase64Url: string; inline;
    class function TryFromBase64Url(const S: string; out R: TUUID): Boolean; static; inline;
    class function FromBase64Url(const S: string): TUUID; static; // raises on error
    class function TryParseNoDash(const S: string; out R: TUUID): Boolean; static; inline;
    class function TryParseURN(const S: string; out R: TUUID): Boolean; static;

    // Properties
    function Version: Integer; inline;
    function IsRfc4122: Boolean; inline;
    function IsV4: Boolean; inline;
    function IsV7: Boolean; inline;
    function V7TimestampMs: Int64; inline; // -1 if not v7/invalid
    function IsNil: Boolean; inline;
    function Equals(const B: TUUID): Boolean; inline;
    function Hash: UInt32; inline;

    // Ordering (bytewise lex, suitable for DB ordering)
    function CompareLex(const B: TUUID): Integer; inline;
    function LessThan(const B: TUUID): Boolean; inline;

    // Generators
    class function NewV4: TUUID; static; inline;
    class function NewV7: TUUID; static; inline;
    class function NewV7At(const TimestampMs: Int64): TUUID; static; inline;

    // Interop with TGUID
    function ToGUID: TGUID; inline;
    class function FromGUID(const G: TGUID): TUUID; static; inline;

    // Constants
    class function NilValue: TUUID; static; inline;
  end;

implementation

uses
  fafafa.core.id.codec;

{ TUUID }

class function TUUID.FromBytes(const A: TUuid128): TUUID;
begin
  Result.F := A;
end;

function TUUID.ToBytes: TUuid128;
begin
  Result := F;
end;

class function TUUID.TryParse(const S: string; out R: TUUID): Boolean;
var A: TUuid128;
begin
  Result := fafafa.core.id.TryParseUuid(S, A);
  if Result then R.F := A;
end;

class function TUUID.TryParseRelaxed(const S: string; out R: TUUID): Boolean;
var A: TUuid128;
begin
  Result := fafafa.core.id.TryParseUuidRelaxed(S, A);
  if Result then R.F := A;
end;

class function TUUID.Parse(const S: string): TUUID;
var A: TUuid128;
begin
  if not fafafa.core.id.TryParseUuid(S, A) then
    raise EUuidParseError.CreateFmt('invalid UUID: %s', [S]);
  Result.F := A;
end;

function TUUID.ToString: string;
begin
  Result := fafafa.core.id.UuidToString(F);
end;

function TUUID.ToStringNoDash: string;
begin
  Result := fafafa.core.id.UuidToStringNoDash(F);
end;

function TUUID.ToBase64Url: string;
begin
  Result := UuidToBase64Url(F);
end;

class function TUUID.TryFromBase64Url(const S: string; out R: TUUID): Boolean;
var A: TUuid128;
begin
  Result := TryParseUuidBase64Url(S, A);
  if Result then R.F := A;
end;

class function TUUID.FromBase64Url(const S: string): TUUID;
var A: TUuid128;
begin
  if not TryParseUuidBase64Url(S, A) then
    raise EUuidParseError.CreateFmt('invalid UUID Base64URL: %s', [S]);
  Result.F := A;
end;

class function TUUID.TryParseNoDash(const S: string; out R: TUUID): Boolean;
var A: TUuid128;
begin
  Result := fafafa.core.id.TryParseUuidNoDash(S, A);
  if Result then R.F := A;
end;

class function TUUID.TryParseURN(const S: string; out R: TUUID): Boolean;
var L: Integer; Body: string;
begin
  // Accept urn:uuid:<36-chars> or urn:uuid:<32-hex>
  if (Length(S) >= 9) and (LowerCase(Copy(S,1,9)) = 'urn:uuid:') then
  begin
    Body := Copy(S, 10, MaxInt);
    if TUUID.TryParse(Body, R) then Exit(True);
    if TUUID.TryParseRelaxed(Body, R) then Exit(True);
  end;
  Exit(False);
end;

function TUUID.Version: Integer;
begin
  Result := fafafa.core.id.UuidVersion(F);
end;

function TUUID.IsRfc4122: Boolean;
begin
  Result := fafafa.core.id.UuidVariantRFC4122(F);
end;

function TUUID.IsV4: Boolean;
begin
  Result := (Version = 4) and IsRfc4122;
end;

function TUUID.IsV7: Boolean;
begin
  Result := (Version = 7) and IsRfc4122;
end;

function TUUID.V7TimestampMs: Int64;
begin
  // Extract directly from bytes if version=7 and variant is RFC4122
  if not IsV7 then Exit(-1);
  Result :=
    (Int64(F[0]) shl 40) or
    (Int64(F[1]) shl 32) or
    (Int64(F[2]) shl 24) or
    (Int64(F[3]) shl 16) or
    (Int64(F[4]) shl 8) or
     Int64(F[5]);
end;

function TUUID.CompareLex(const B: TUUID): Integer;
var i: Integer;
begin
  for i := 0 to 15 do begin
    if F[i] < B.F[i] then exit(-1);
    if F[i] > B.F[i] then exit(1);
  end;
  Result := 0;
end;

function TUUID.LessThan(const B: TUUID): Boolean;
begin
  Result := CompareLex(B) < 0;
end;

class function TUUID.NewV4: TUUID;
begin
  Result.F := fafafa.core.id.UuidV4_Raw;
end;

function TUUID.ToGUID: TGUID;
begin
  Move(F[0], Result, SizeOf(Result));
end;

function TUUID.IsNil: Boolean;
begin
  Result := (PUInt64(@F[0])^ = 0) and (PUInt64(@F[8])^ = 0);
end;

function TUUID.Equals(const B: TUUID): Boolean;
begin
  Result := CompareMem(@F[0], @B.F[0], SizeOf(F));
end;

function TUUID.Hash: UInt32;
var p: PCardinal;
begin
  // simple 32-bit mix over first and last 4 bytes
  p := @F[0];
  Result := p^;
  Inc(p, 1);
  Result := Result xor p^;
  Inc(p, 1);
  Result := Result xor p^;
  Inc(p, 1);
  Result := Result xor PCardinal(@F[12])^;
end;

class function TUUID.NilValue: TUUID;
begin
  FillChar(Result.F[0], SizeOf(Result.F), 0);
end;


class function TUUID.FromGUID(const G: TGUID): TUUID;
begin
  Move(G, Result.F[0], SizeOf(G));
end;

class function TUUID.NewV7: TUUID;
begin
  Result.F := fafafa.core.id.UuidV7_Raw;
end;

class function TUUID.NewV7At(const TimestampMs: Int64): TUUID;
begin
  Result.F := fafafa.core.id.UuidV7_Raw(TimestampMs);
end;

end.


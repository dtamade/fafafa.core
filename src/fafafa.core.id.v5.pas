{
  fafafa.core.id.v5 — UUID v3/v5 (MD5/SHA-1 namespace hash)

  - RFC 9562 compliant UUID version 3 (MD5) and 5 (SHA-1)
  - Deterministic: same namespace + name = same UUID
  - Pre-defined namespaces: DNS, URL, OID, X500
}

unit fafafa.core.id.v5;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.id;

type
  { Pre-defined namespace UUIDs (RFC 9562) }
  TUuidNamespace = (
    nsNil,    // Nil namespace (all zeros)
    nsDNS,    // 6ba7b810-9dad-11d1-80b4-00c04fd430c8
    nsURL,    // 6ba7b811-9dad-11d1-80b4-00c04fd430c8
    nsOID,    // 6ba7b812-9dad-11d1-80b4-00c04fd430c8
    nsX500    // 6ba7b814-9dad-11d1-80b4-00c04fd430c8
  );

{ UUID v5 generation (SHA-1) }
function UuidV5(const Namespace: TUuid128; const Name: string): TUuid128; overload;
function UuidV5(const Namespace: TUuid128; const Name: RawByteString): TUuid128; overload;
function UuidV5(Namespace: TUuidNamespace; const Name: string): TUuid128; overload;

{ Convenience functions with pre-defined namespaces }
function UuidV5_DNS(const Name: string): TUuid128;   // e.g., "example.com"
function UuidV5_URL(const Name: string): TUuid128;   // e.g., "https://example.com/path"
function UuidV5_OID(const Name: string): TUuid128;   // e.g., "1.2.3.4"
function UuidV5_X500(const Name: string): TUuid128;  // e.g., "cn=John Doe,o=Acme,c=US"

{ String versions }
function UuidV5Str(const Namespace: TUuid128; const Name: string): string; overload;
function UuidV5Str(Namespace: TUuidNamespace; const Name: string): string; overload;
function UuidV5Str_DNS(const Name: string): string;
function UuidV5Str_URL(const Name: string): string;

{ Namespace UUID constants }
function GetNamespaceUuid(Namespace: TUuidNamespace): TUuid128;

{ UUID v3 (MD5) for completeness }
function UuidV3(const Namespace: TUuid128; const Name: string): TUuid128; overload;
function UuidV3(Namespace: TUuidNamespace; const Name: string): TUuid128; overload;
function UuidV3_DNS(const Name: string): TUuid128;
function UuidV3_URL(const Name: string): TUuid128;
function UuidV3Str_DNS(const Name: string): string;
function UuidV3Str_URL(const Name: string): string;

implementation

uses
  fafafa.core.crypto.hash.sha1,
  fafafa.core.crypto.hash.md5;

const
  // Pre-defined namespace UUIDs (RFC 9562 / RFC 4122)
  NAMESPACE_DNS: TUuid128 = (
    $6b, $a7, $b8, $10, $9d, $ad, $11, $d1,
    $80, $b4, $00, $c0, $4f, $d4, $30, $c8
  );

  NAMESPACE_URL: TUuid128 = (
    $6b, $a7, $b8, $11, $9d, $ad, $11, $d1,
    $80, $b4, $00, $c0, $4f, $d4, $30, $c8
  );

  NAMESPACE_OID: TUuid128 = (
    $6b, $a7, $b8, $12, $9d, $ad, $11, $d1,
    $80, $b4, $00, $c0, $4f, $d4, $30, $c8
  );

  NAMESPACE_X500: TUuid128 = (
    $6b, $a7, $b8, $14, $9d, $ad, $11, $d1,
    $80, $b4, $00, $c0, $4f, $d4, $30, $c8
  );

  NAMESPACE_NIL: TUuid128 = (
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00
  );

function GetNamespaceUuid(Namespace: TUuidNamespace): TUuid128;
begin
  case Namespace of
    nsDNS:  Result := NAMESPACE_DNS;
    nsURL:  Result := NAMESPACE_URL;
    nsOID:  Result := NAMESPACE_OID;
    nsX500: Result := NAMESPACE_X500;
    else    Result := NAMESPACE_NIL;
  end;
end;

function UuidV5(const Namespace: TUuid128; const Name: RawByteString): TUuid128;
var
  Ctx: TSHA1Context;
  Hash: TBytes;
begin
  Ctx := TSHA1Context.Create;
  try
    // Hash: namespace UUID + name
    Ctx.Update(Namespace[0], 16);
    if Length(Name) > 0 then
      Ctx.Update(Name[1], Length(Name));
    Hash := Ctx.Finalize;

    // Take first 16 bytes of SHA-1 hash (20 bytes)
    Move(Hash[0], Result[0], 16);

    // Set version to 5 (0101 in high nibble of byte 6)
    Result[6] := (Result[6] and $0F) or $50;

    // Set variant to RFC 4122 (10 in high 2 bits of byte 8)
    Result[8] := (Result[8] and $3F) or $80;
  finally
    Ctx.Free;
  end;
end;

function UuidV5(const Namespace: TUuid128; const Name: string): TUuid128;
begin
  Result := UuidV5(Namespace, RawByteString(UTF8Encode(Name)));
end;

function UuidV5(Namespace: TUuidNamespace; const Name: string): TUuid128;
begin
  Result := UuidV5(GetNamespaceUuid(Namespace), Name);
end;

function UuidV5_DNS(const Name: string): TUuid128;
begin
  Result := UuidV5(NAMESPACE_DNS, Name);
end;

function UuidV5_URL(const Name: string): TUuid128;
begin
  Result := UuidV5(NAMESPACE_URL, Name);
end;

function UuidV5_OID(const Name: string): TUuid128;
begin
  Result := UuidV5(NAMESPACE_OID, Name);
end;

function UuidV5_X500(const Name: string): TUuid128;
begin
  Result := UuidV5(NAMESPACE_X500, Name);
end;

function UuidV5Str(const Namespace: TUuid128; const Name: string): string;
begin
  Result := UuidToString(UuidV5(Namespace, Name));
end;

function UuidV5Str(Namespace: TUuidNamespace; const Name: string): string;
begin
  Result := UuidToString(UuidV5(Namespace, Name));
end;

function UuidV5Str_DNS(const Name: string): string;
begin
  Result := UuidToString(UuidV5_DNS(Name));
end;

function UuidV5Str_URL(const Name: string): string;
begin
  Result := UuidToString(UuidV5_URL(Name));
end;

{ UUID v3 (MD5) implementation }

function UuidV3(const Namespace: TUuid128; const Name: string): TUuid128;
var
  Ctx: TMD5Context;
  Hash: TBytes;
  NameBytes: RawByteString;
begin
  NameBytes := RawByteString(UTF8Encode(Name));

  Ctx := TMD5Context.Create;
  try
    // Hash: namespace UUID + name
    Ctx.Update(Namespace[0], 16);
    if Length(NameBytes) > 0 then
      Ctx.Update(NameBytes[1], Length(NameBytes));
    Hash := Ctx.Finalize;

    // MD5 is exactly 16 bytes
    Move(Hash[0], Result[0], 16);

    // Set version to 3 (0011 in high nibble of byte 6)
    Result[6] := (Result[6] and $0F) or $30;

    // Set variant to RFC 4122 (10 in high 2 bits of byte 8)
    Result[8] := (Result[8] and $3F) or $80;
  finally
    Ctx.Free;
  end;
end;

function UuidV3(Namespace: TUuidNamespace; const Name: string): TUuid128;
begin
  Result := UuidV3(GetNamespaceUuid(Namespace), Name);
end;

function UuidV3_DNS(const Name: string): TUuid128;
begin
  Result := UuidV3(NAMESPACE_DNS, Name);
end;

function UuidV3_URL(const Name: string): TUuid128;
begin
  Result := UuidV3(NAMESPACE_URL, Name);
end;

function UuidV3Str_DNS(const Name: string): string;
begin
  Result := UuidToString(UuidV3_DNS(Name));
end;

function UuidV3Str_URL(const Name: string): string;
begin
  Result := UuidToString(UuidV3_URL(Name));
end;

end.

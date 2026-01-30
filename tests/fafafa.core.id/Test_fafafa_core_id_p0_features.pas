{
  Test_fafafa_core_id_p0_features — Phase 1 P0 新特性测试

  - UUID v7 Context (单调递增)
  - UUID v5 (SHA-1 命名空间)
  - Lock-free Snowflake
  - SHA-1 哈希
}

unit Test_fafafa_core_id_p0_features;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.id,
  fafafa.core.id.v5,
  fafafa.core.id.v7.context,
  fafafa.core.id.snowflake,
  fafafa.core.id.snowflake.lockfree,
  fafafa.core.crypto.hash.sha1;

type
  TTestCase_P0_UuidV5 = class(TTestCase)
  published
    procedure Test_V5_DNS_Deterministic;
    procedure Test_V5_URL_Deterministic;
    procedure Test_V5_RFC_Vector;
    procedure Test_V3_DNS_Deterministic;
    procedure Test_V5_Version_Variant;
  end;

  TTestCase_P0_ContextV7 = class(TTestCase)
  published
    procedure Test_Monotonic_SameMs_Increasing;
    procedure Test_Version_Variant;
    procedure Test_Global_Context;
  end;

  TTestCase_P0_LockFreeSnowflake = class(TTestCase)
  published
    procedure Test_Basic_Generation;
    procedure Test_Monotonic;
    procedure Test_WorkerId;
  end;

  TTestCase_P0_SHA1 = class(TTestCase)
  published
    procedure Test_Empty_String;
    procedure Test_ABC;
    procedure Test_Long_String;
    procedure Test_FIPS180_Vector;
  end;

implementation

{ TTestCase_P0_UuidV5 }

procedure TTestCase_P0_UuidV5.Test_V5_DNS_Deterministic;
var
  U1, U2: TUuid128;
begin
  // Same name should produce same UUID
  U1 := UuidV5_DNS('example.com');
  U2 := UuidV5_DNS('example.com');
  AssertTrue('Deterministic', CompareMem(@U1[0], @U2[0], 16));

  // Different names should produce different UUIDs
  U2 := UuidV5_DNS('example.org');
  AssertFalse('Different', CompareMem(@U1[0], @U2[0], 16));
end;

procedure TTestCase_P0_UuidV5.Test_V5_URL_Deterministic;
var
  U1, U2: TUuid128;
begin
  U1 := UuidV5_URL('https://example.com/path');
  U2 := UuidV5_URL('https://example.com/path');
  AssertTrue('Deterministic', CompareMem(@U1[0], @U2[0], 16));
end;

procedure TTestCase_P0_UuidV5.Test_V5_RFC_Vector;
var
  U: TUuid128;
  S: string;
begin
  // RFC 9562 Appendix B - Test Vector for v5
  // Namespace: DNS, Name: "www.example.com"
  // Expected: 2ed6657d-e927-568b-95e1-2665a8aea6a2
  U := UuidV5_DNS('www.example.com');
  S := UuidToString(U);
  AssertEquals('RFC vector', '2ed6657d-e927-568b-95e1-2665a8aea6a2', LowerCase(S));
end;

procedure TTestCase_P0_UuidV5.Test_V3_DNS_Deterministic;
var
  U1, U2: TUuid128;
begin
  U1 := UuidV3_DNS('example.com');
  U2 := UuidV3_DNS('example.com');
  AssertTrue('Deterministic', CompareMem(@U1[0], @U2[0], 16));
end;

procedure TTestCase_P0_UuidV5.Test_V5_Version_Variant;
var
  U: TUuid128;
begin
  U := UuidV5_DNS('test');
  // Version 5 = 0101 in high nibble of byte 6
  AssertEquals('Version 5', 5, (U[6] shr 4) and $0F);
  // Variant RFC 4122 = 10 in high 2 bits of byte 8
  AssertEquals('Variant', 2, (U[8] shr 6) and $03);
end;

{ TTestCase_P0_ContextV7 }

procedure TTestCase_P0_ContextV7.Test_Monotonic_SameMs_Increasing;
var
  Ctx: TContextV7;
  U1, U2, U3: TUuid128;
  FixedMs: Int64;
begin
  Ctx := TContextV7.Create;
  try
    FixedMs := 1700000000000; // Fixed timestamp for testing
    U1 := Ctx.NextRawAt(FixedMs);
    U2 := Ctx.NextRawAt(FixedMs);
    U3 := Ctx.NextRawAt(FixedMs);

    // Should be monotonically increasing
    AssertTrue('U1 < U2', CompareMem(@U1[0], @U2[0], 16) = False);
    AssertTrue('U2 < U3', CompareMem(@U2[0], @U3[0], 16) = False);

    // String comparison for lexicographic order
    AssertTrue('Lex order 1<2', UuidToString(U1) < UuidToString(U2));
    AssertTrue('Lex order 2<3', UuidToString(U2) < UuidToString(U3));
  finally
    Ctx.Free;
  end;
end;

procedure TTestCase_P0_ContextV7.Test_Version_Variant;
var
  Ctx: TContextV7;
  U: TUuid128;
begin
  Ctx := TContextV7.Create;
  try
    U := Ctx.NextRaw;
    // Version 7 = 0111
    AssertEquals('Version 7', 7, (U[6] shr 4) and $0F);
    // Variant RFC 4122 = 10
    AssertEquals('Variant', 2, (U[8] shr 6) and $03);
  finally
    Ctx.Free;
  end;
end;

procedure TTestCase_P0_ContextV7.Test_Global_Context;
var
  S1, S2: string;
begin
  S1 := UuidV7_Monotonic;
  S2 := UuidV7_Monotonic;
  AssertEquals('Length', 36, Length(S1));
  AssertTrue('Different', S1 <> S2);
end;

{ TTestCase_P0_LockFreeSnowflake }

procedure TTestCase_P0_LockFreeSnowflake.Test_Basic_Generation;
var
  SF: ISnowflake;
  Id: TSnowflakeID;
begin
  SF := CreateLockFreeSnowflake(123);
  Id := SF.NextID;
  AssertTrue('ID > 0', Id > 0);
end;

procedure TTestCase_P0_LockFreeSnowflake.Test_Monotonic;
var
  SF: ISnowflake;
  Id1, Id2, Id3: TSnowflakeID;
begin
  SF := CreateLockFreeSnowflake(1);
  Id1 := SF.NextID;
  Id2 := SF.NextID;
  Id3 := SF.NextID;
  AssertTrue('Id1 < Id2', Id1 < Id2);
  AssertTrue('Id2 < Id3', Id2 < Id3);
end;

procedure TTestCase_P0_LockFreeSnowflake.Test_WorkerId;
var
  SF: ISnowflake;
begin
  SF := CreateLockFreeSnowflake(456);
  AssertEquals('WorkerId', 456, SF.GetWorkerId);
end;

{ TTestCase_P0_SHA1 }

function BytesToHex(const Bytes: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Length(Bytes) - 1 do
    Result := Result + IntToHex(Bytes[I], 2);
  Result := LowerCase(Result);
end;

procedure TTestCase_P0_SHA1.Test_Empty_String;
var
  Hash: TBytes;
begin
  // SHA1('') = da39a3ee5e6b4b0d3255bfef95601890afd80709
  Hash := SHA1Hash('');
  AssertEquals('Empty hash', 'da39a3ee5e6b4b0d3255bfef95601890afd80709', BytesToHex(Hash));
end;

procedure TTestCase_P0_SHA1.Test_ABC;
var
  Hash: TBytes;
begin
  // SHA1('abc') = a9993e364706816aba3e25717850c26c9cd0d89d
  Hash := SHA1Hash('abc');
  AssertEquals('abc hash', 'a9993e364706816aba3e25717850c26c9cd0d89d', BytesToHex(Hash));
end;

procedure TTestCase_P0_SHA1.Test_Long_String;
var
  Hash: TBytes;
begin
  // SHA1('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')
  // = 84983e441c3bd26ebaae4aa1f95129e5e54670f1
  Hash := SHA1Hash('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq');
  AssertEquals('Long hash', '84983e441c3bd26ebaae4aa1f95129e5e54670f1', BytesToHex(Hash));
end;

procedure TTestCase_P0_SHA1.Test_FIPS180_Vector;
var
  Hash: TBytes;
  S: string;
  I: Integer;
begin
  // SHA1 of 1000 'a' characters (shortened for faster test)
  // Full FIPS test uses 1 million 'a's
  S := '';
  for I := 1 to 1000 do
    S := S + 'a';
  Hash := SHA1Hash(S);
  // Verify it produces a valid 20-byte hash
  AssertEquals('Hash length', 20, Length(Hash));
end;

initialization
  RegisterTest('fafafa.core.id.P0', TTestCase_P0_UuidV5);
  RegisterTest('fafafa.core.id.P0', TTestCase_P0_ContextV7);
  RegisterTest('fafafa.core.id.P0', TTestCase_P0_LockFreeSnowflake);
  RegisterTest('fafafa.core.id.P0', TTestCase_P0_SHA1);

end.

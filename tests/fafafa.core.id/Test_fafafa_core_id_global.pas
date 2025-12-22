{$CODEPAGE UTF8}
unit Test_fafafa_core_id_global;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, fpcunit, testutils, testregistry,
  fafafa.core.math,
  fafafa.core.id, fafafa.core.id.ulid, fafafa.core.id.ksuid, fafafa.core.id.snowflake, fafafa.core.id.ulid.monotonic, fafafa.core.id.codec;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_UuidV4_Format;
    procedure Test_UuidV7_Format;
    procedure Test_Uuid_Parse_Roundtrip;
    procedure Test_UuidV7_Timestamp_Roundtrip;
    procedure Test_Ulid_Format_26Chars;
    procedure Test_Ulid_Parse_Roundtrip;
    procedure Test_Ulid_Timestamp_Roundtrip;
    procedure Test_Ksuid_Format_27Chars;
    procedure Test_Ksuid_Parse_Roundtrip;
    procedure Test_Ksuid_Timestamp_Roundtrip;
    procedure Test_Snowflake_Bitfields;
    procedure Test_Snowflake_Monotonic_SameWorker;
    procedure Test_Ulid_Monotonic_SameMs;
    procedure Test_Uuid_TryParse_Relaxed_NoDashes;
    procedure Test_Uuid_Base64Url_Roundtrip;
    procedure Test_Ulid_Base58_Roundtrip;
    procedure Test_Ksuid_Base58_Roundtrip;
    procedure Test_Ksuid_Lex_Order_Cross_Seconds;
    procedure Test_Uuid_IsV4_IsV7;
  end;

implementation

function IsHexLower(const S: string): Boolean;
var I: Integer;
begin
  Result := Length(S) = 36;
  if not Result then Exit;
  for I := 1 to Length(S) do
  begin
    if (I in [9,14,19,24]) then begin if S[I] <> '-' then Exit(False); end
    else if not (S[I] in ['0'..'9','a'..'f']) then Exit(False);
  end;
end;

procedure TTestCase_Global.Test_UuidV4_Format;
var S: string; A: array[0..15] of Byte;
begin
  S := UuidV4;
  AssertTrue('format', IsHexLower(S));
  AssertTrue('parse', TryParseUuid(S, A));
  AssertEquals('version nibble', 4, (A[6] shr 4) and $0F);
  AssertEquals('variant bits', 2, (A[8] shr 6) and $03);
end;

procedure TTestCase_Global.Test_UuidV7_Format;
var S: string; A: array[0..15] of Byte;
begin
  S := UuidV7;
  AssertTrue('format', IsHexLower(S));
  AssertTrue('parse', TryParseUuid(S, A));
  AssertEquals('version nibble', 7, (A[6] shr 4) and $0F);
  AssertEquals('variant bits', 2, (A[8] shr 6) and $03);
end;

procedure TTestCase_Global.Test_Uuid_Parse_Roundtrip;
var S: string; A,B: array[0..15] of Byte;
begin
  S := UuidV4;
  AssertTrue('parse', TryParseUuid(S, A));
  S := UuidToString(A);
  AssertTrue('parse 2', TryParseUuid(S, B));
  AssertTrue('raw equal', CompareMem(@A[0], @B[0], 16));
end;

procedure TTestCase_Global.Test_UuidV7_Timestamp_Roundtrip;
var R: Int64; Raw: TUuid128; S: string; T: Int64; S2: string; T2: Int64;
begin
  R := 1730000000123; // fixed sample
  Raw := UuidV7_Raw(R);
  S := UuidToString(Raw);
  T := UuidV7_TimestampMs(S);
  AssertEquals('v7 ts roundtrip', R, T);
  // relaxed: 32-char no-dash
  S2 := StringReplace(S, '-', '', [rfReplaceAll]);
  T2 := UuidV7_TimestampMsRelaxed(S2);
  AssertEquals('v7 ts relaxed roundtrip', R, T2);
end;

procedure TTestCase_Global.Test_Ulid_Format_26Chars;
var S: string;
begin
  S := Ulid;
  AssertEquals('len=26', 26, Length(S));
end;

procedure TTestCase_Global.Test_Ulid_Parse_Roundtrip;
var S: string; A: TUlid128;
begin
  S := Ulid;
  AssertTrue('parse', TryParseUlid(S, A));
  AssertEquals('roundtrip len', 26, Length(UlidToString(A)));
end;

procedure TTestCase_Global.Test_Ulid_Timestamp_Roundtrip;
var TS, Back: Int64; A: TUlid128; S: string;
begin
  TS := 1730000000123;
  A := Ulid_Raw(TS);
  S := UlidToString(A);
  Back := Ulid_TimestampMs(S);
  AssertEquals('ulid ts roundtrip', TS, Back);
end;

procedure TTestCase_Global.Test_Ksuid_Format_27Chars;
var S: string;
begin
  S := Ksuid;
  AssertEquals('len=27', 27, Length(S));
end;

procedure TTestCase_Global.Test_Ksuid_Parse_Roundtrip;
var S: string; A: TKsuid160;
begin
  S := Ksuid;
  AssertTrue('parse', TryParseKsuid(S, A));
  AssertEquals('roundtrip len', 27, Length(KsuidToString(A)));
end;

procedure TTestCase_Global.Test_Ksuid_Timestamp_Roundtrip;
var T0: Int64; A,B: TKsuid160; S: string;
begin
  T0 := 1730000000;
  A := Ksuid_Raw(T0);
  S := KsuidToString(A);
  AssertTrue('ksuid parse', TryParseKsuid(S, B));
  AssertTrue('ksuid raw roundtrip', CompareMem(@A[0], @B[0], SizeOf(A)));
end;

procedure TTestCase_Global.Test_Snowflake_Bitfields;
var G: ISnowflake; id: TSnowflakeID; ts: Int64; NowUtcDT: TDateTime; NowUtcMs: Int64;
begin
  G := CreateSnowflake(42);
  id := G.NextID;
  AssertEquals('worker', 42, Snowflake_WorkerId(id));
  AssertTrue('seq <= 4095', Snowflake_Sequence(id) <= 4095);
  ts := Snowflake_TimestampMs(id, G.EpochMs);
  // Use UTC time since Snowflake now uses UTC via fafafa.core.id.time
  NowUtcDT := LocalTimeToUniversal(Now);
  NowUtcMs := Int64(DateTimeToUnix(NowUtcDT, False)) * 1000 + MilliSecondOf(NowUtcDT);
  AssertTrue('ts close to now', Abs(ts - NowUtcMs) < 2000);
end;

procedure TTestCase_Global.Test_Snowflake_Monotonic_SameWorker;
var G: ISnowflake; a,b: TSnowflakeID;
begin
  G := CreateSnowflake(7);
  a := G.NextID;
  b := G.NextID;
  AssertTrue('monotonic', b > a);
end;

procedure TTestCase_Global.Test_Ulid_Monotonic_SameMs;
var G: IUlidGenerator; a,b: string; ta,tb: Int64;
begin
  G := CreateUlidMonotonic;
  a := G.Next; b := G.Next;
  ta := Ulid_TimestampMs(a); tb := Ulid_TimestampMs(b);
  AssertEquals('same ms', ta, tb);
  AssertTrue('lex order', a < b);
end;

procedure TTestCase_Global.Test_Uuid_TryParse_Relaxed_NoDashes;
var A: TUuid128; s: string; s2: string;
begin
  s := UuidV4;
  s2 := UuidToStringNoDash(UuidV4_Raw);
  s := StringReplace(s, '-', '', [rfReplaceAll]);
  AssertEquals('len 32', 32, Length(s));
  AssertTrue('relaxed parse', TryParseUuidRelaxed(s, A));
  AssertTrue('no-dash parse', TryParseUuidNoDash(s2, A));
end;

procedure TTestCase_Global.Test_Uuid_Base64Url_Roundtrip;
var R, R2: TUuid128; S: string;
begin
  R := UuidV4_Raw;
  S := UuidToBase64Url(R);
  AssertTrue('decode', TryParseUuidBase64Url(S, R2));
  AssertTrue('raw equal', CompareMem(@R[0], @R2[0], SizeOf(R)));
end;

procedure TTestCase_Global.Test_Ulid_Base58_Roundtrip;
var A, B: TUlid128; S: string;
begin
  A := Ulid_Raw(1730000000123);
  S := UlidToBase58(A);
  AssertTrue('decode', TryParseUlidBase58(S, B));
  AssertTrue('raw equal', CompareMem(@A[0], @B[0], SizeOf(A)));
end;

procedure TTestCase_Global.Test_Ksuid_Base58_Roundtrip;
var A, B: TKsuid160; S: string;
begin
  A := Ksuid_Raw(1730000000);
  S := KsuidToBase58(A);
  AssertTrue('decode', TryParseKsuidBase58(S, B));
  AssertTrue('raw equal', CompareMem(@A[0], @B[0], SizeOf(A)));
end;

procedure TTestCase_Global.Test_Ksuid_Lex_Order_Cross_Seconds;
var A,B: TKsuid160; SA, SB: string;
begin
  A := Ksuid_Raw(1730000000);

  B := Ksuid_Raw(1730000001);
  SA := KsuidToString(A);
  SB := KsuidToString(B);
  AssertTrue('ksuid lex order across seconds', SA < SB);
end;

procedure TTestCase_Global.Test_Uuid_IsV4_IsV7;
var s4,s7: string; raw7: TUuid128;
begin
  s4 := UuidV4;
  AssertTrue('is v4', IsUuidV4(s4));
  AssertFalse('not v7', IsUuidV7(s4));
  raw7 := UuidV7_Raw(1730000000123);
  s7 := UuidToString(raw7);
  AssertTrue('is v7', IsUuidV7(s7));
  AssertFalse('not v4', IsUuidV4(s7));
  // relaxed: remove dashes
  s7 := StringReplace(s7, '-', '', [rfReplaceAll]);
  AssertTrue('is v7 relaxed', IsUuidV7(s7));
end;



initialization
  RegisterTest('fafafa.core.id.Global', TTestCase_Global);
end.

{
  Test_fafafa_core_id_p1_features — Phase 2 P1 新特性测试

  - UUID v6 (时间排序)
  - ULID 溢出策略
  - KSUID 毫秒精度
  - Builder API
  - 批量生成
}

unit Test_fafafa_core_id_p1_features;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.id,
  fafafa.core.id.v6,
  fafafa.core.id.ulid,
  fafafa.core.id.ulid.policy,
  fafafa.core.id.ksuid,
  fafafa.core.id.ksuid.ms,
  fafafa.core.id.builder,
  fafafa.core.id.batch,
  fafafa.core.id.snowflake,
  fafafa.core.id.snowflake.lockfree,
  fafafa.core.id.time;

type
  { UUID v6 tests }
  TTestCase_P1_UuidV6 = class(TTestCase)
  published
    procedure Test_V6_Format;
    procedure Test_V6_Version_Variant;
    procedure Test_V6_Timestamp_Roundtrip;
    procedure Test_V6_Lexicographic_Order;
  end;

  { ULID policy tests }
  TTestCase_P1_UlidPolicy = class(TTestCase)
  published
    procedure Test_Generator_Monotonic;
    procedure Test_Policy_WaitNextMs;
    procedure Test_Policy_Interface;
  end;

  { KSUID-Ms tests }
  TTestCase_P1_KsuidMs = class(TTestCase)
  published
    procedure Test_Format_27Chars;
    procedure Test_Timestamp_Roundtrip;
    procedure Test_Generator_Monotonic;
  end;

  { Builder API tests }
  TTestCase_P1_Builder = class(TTestCase)
  published
    procedure Test_UUID_V4_Builder;
    procedure Test_UUID_V7_Monotonic_Builder;
    procedure Test_ULID_Builder;
    procedure Test_KSUID_Builder;
    procedure Test_Snowflake_Builder;
  end;

  { Batch generation tests }
  TTestCase_P1_Batch = class(TTestCase)
  published
    procedure Test_UuidV7_BatchN;
    procedure Test_Ulid_BatchN;
    procedure Test_Ksuid_BatchN;
    procedure Test_Snowflake_BatchN;
    procedure Test_Batch_Monotonic_Order;
  end;

implementation

{ TTestCase_P1_UuidV6 }

procedure TTestCase_P1_UuidV6.Test_V6_Format;
var
  U: TUuid128;
  S: string;
begin
  U := UuidV6;
  S := UuidToString(U);
  AssertEquals('Format length', 36, Length(S));
  AssertEquals('Dash 1', '-', S[9]);
  AssertEquals('Dash 2', '-', S[14]);
  AssertEquals('Dash 3', '-', S[19]);
  AssertEquals('Dash 4', '-', S[24]);
end;

procedure TTestCase_P1_UuidV6.Test_V6_Version_Variant;
var
  U: TUuid128;
begin
  U := UuidV6;
  // Version 6 = 0110 in high nibble of byte 6
  AssertEquals('Version 6', 6, (U[6] shr 4) and $0F);
  // Variant RFC 4122 = 10 in high 2 bits of byte 8
  AssertEquals('Variant', 2, (U[8] shr 6) and $03);
  AssertTrue('IsUuidV6', IsUuidV6(U));
end;

procedure TTestCase_P1_UuidV6.Test_V6_Timestamp_Roundtrip;
var
  U: TUuid128;
  ExtractedDT: TDateTime;
  NowDT: TDateTime;
  DiffSec: Double;
begin
  NowDT := Now;
  U := UuidV6;
  ExtractedDT := UuidV6_Timestamp(U);

  // Should be within 2 seconds of now
  DiffSec := Abs(ExtractedDT - NowDT) * 86400;
  AssertTrue('Timestamp close to now', DiffSec < 2);
end;

procedure TTestCase_P1_UuidV6.Test_V6_Lexicographic_Order;
var
  U1, U2: TUuid128;
  S1, S2: string;
begin
  U1 := UuidV6;
  Sleep(2);  // Ensure different timestamp
  U2 := UuidV6;

  S1 := UuidToString(U1);
  S2 := UuidToString(U2);

  // v6 should be lexicographically ordered by time
  AssertTrue('Lex order', S1 < S2);
end;

{ TTestCase_P1_UlidPolicy }

procedure TTestCase_P1_UlidPolicy.Test_Generator_Monotonic;
var
  Gen: IUlidGenerator;
  U1, U2, U3: TUlid128;
begin
  Gen := CreateUlidGenerator(opWaitNextMs);
  U1 := Gen.NextRaw;
  U2 := Gen.NextRaw;
  U3 := Gen.NextRaw;

  // Should be monotonically increasing
  AssertTrue('U1 < U2', UlidToString(U1) < UlidToString(U2));
  AssertTrue('U2 < U3', UlidToString(U2) < UlidToString(U3));
end;

procedure TTestCase_P1_UlidPolicy.Test_Policy_WaitNextMs;
var
  Gen: IUlidGenerator;
begin
  Gen := CreateUlidGenerator(opWaitNextMs);
  AssertEquals('Policy', Ord(opWaitNextMs), Ord(Gen.OverflowPolicy));

  Gen.OverflowPolicy := opRaiseError;
  AssertEquals('Changed policy', Ord(opRaiseError), Ord(Gen.OverflowPolicy));
end;

procedure TTestCase_P1_UlidPolicy.Test_Policy_Interface;
var
  Gen: IUlidGenerator;
  S: string;
begin
  Gen := CreateUlidGenerator(opWaitNextMs);
  S := Gen.Next;
  AssertEquals('String length', 26, Length(S));
end;

{ TTestCase_P1_KsuidMs }

procedure TTestCase_P1_KsuidMs.Test_Format_27Chars;
var
  S: string;
begin
  S := KsuidMsNowStr;
  AssertEquals('KSUID-Ms length', 27, Length(S));
end;

procedure TTestCase_P1_KsuidMs.Test_Timestamp_Roundtrip;
var
  K: TKsuidMs160;
  ExtractedMs, NowMs: Int64;
  DiffMs: Int64;
begin
  // Use the same time source as KSUID-Ms implementation for accurate comparison
  NowMs := fafafa.core.id.time.NowUnixMs;
  K := KsuidMsNow;
  ExtractedMs := KsuidMs_TimestampMs(K);

  DiffMs := Abs(ExtractedMs - NowMs);
  // Should be within 1 second (accounting for execution time)
  AssertTrue('Timestamp close to now: diff=' + IntToStr(DiffMs), DiffMs < 1000);
end;

procedure TTestCase_P1_KsuidMs.Test_Generator_Monotonic;
var
  Gen: IKsuidMsGenerator;
  S1, S2, S3: string;
begin
  Gen := CreateKsuidMsGenerator;
  S1 := Gen.Next;
  S2 := Gen.Next;
  S3 := Gen.Next;

  // Should be monotonically increasing
  AssertTrue('S1 < S2', S1 < S2);
  AssertTrue('S2 < S3', S2 < S3);
end;

{ TTestCase_P1_Builder }

procedure TTestCase_P1_Builder.Test_UUID_V4_Builder;
var
  U: TUuid128;
begin
  U := TIdBuilder.UUID.V4.Build;
  AssertEquals('Version 4', 4, (U[6] shr 4) and $0F);
end;

procedure TTestCase_P1_Builder.Test_UUID_V7_Monotonic_Builder;
var
  S1, S2: string;
begin
  S1 := TIdBuilder.UUID.V7.Monotonic.BuildStr;
  S2 := TIdBuilder.UUID.V7.Monotonic.BuildStr;
  AssertEquals('Length', 36, Length(S1));
  AssertTrue('Different', S1 <> S2);
end;

procedure TTestCase_P1_Builder.Test_ULID_Builder;
var
  S: string;
begin
  S := TIdBuilder.ULID.Monotonic.WaitOnOverflow.BuildStr;
  AssertEquals('ULID length', 26, Length(S));
end;

procedure TTestCase_P1_Builder.Test_KSUID_Builder;
var
  S: string;
begin
  S := TIdBuilder.KSUID.Standard.BuildStr;
  AssertEquals('KSUID length', 27, Length(S));
end;

procedure TTestCase_P1_Builder.Test_Snowflake_Builder;
var
  Id: TSnowflakeID;
begin
  Id := TIdBuilder.Snowflake.WorkerId(123).TwitterEpoch.LockFree.Build;
  AssertTrue('ID > 0', Id > 0);
end;

{ TTestCase_P1_Batch }

procedure TTestCase_P1_Batch.Test_UuidV7_BatchN;
var
  Arr: TUuid128Array;
begin
  Arr := UuidV7_BatchN(10);
  AssertEquals('Count', 10, Length(Arr));
end;

procedure TTestCase_P1_Batch.Test_Ulid_BatchN;
var
  Arr: TUlid128Array;
begin
  Arr := Ulid_BatchN(10);
  AssertEquals('Count', 10, Length(Arr));
end;

procedure TTestCase_P1_Batch.Test_Ksuid_BatchN;
var
  Arr: TKsuid160Array;
begin
  Arr := Ksuid_BatchN(10);
  AssertEquals('Count', 10, Length(Arr));
end;

procedure TTestCase_P1_Batch.Test_Snowflake_BatchN;
var
  Arr: TSnowflakeIDArray;
begin
  Arr := Snowflake_BatchN(10, 1);
  AssertEquals('Count', 10, Length(Arr));
end;

procedure TTestCase_P1_Batch.Test_Batch_Monotonic_Order;
var
  Arr: TUlid128Array;
  I: Integer;
begin
  Arr := Ulid_BatchN(100);

  // All should be monotonically increasing
  for I := 1 to High(Arr) do
    AssertTrue('Order ' + IntToStr(I),
      UlidToString(Arr[I-1]) < UlidToString(Arr[I]));
end;

initialization
  RegisterTest('fafafa.core.id.P1', TTestCase_P1_UuidV6);
  RegisterTest('fafafa.core.id.P1', TTestCase_P1_UlidPolicy);
  RegisterTest('fafafa.core.id.P1', TTestCase_P1_KsuidMs);
  RegisterTest('fafafa.core.id.P1', TTestCase_P1_Builder);
  RegisterTest('fafafa.core.id.P1', TTestCase_P1_Batch);

end.

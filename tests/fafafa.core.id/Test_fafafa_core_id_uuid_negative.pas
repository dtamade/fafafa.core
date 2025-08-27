{$CODEPAGE UTF8}
unit Test_fafafa_core_id_uuid_negative;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.id, fafafa.core.id.uuid, fafafa.core.id.v7.monotonic;

type
  TTestCase_Uuid_Negative = class(TTestCase)
  published
    procedure Test_UuidV7_Timestamp_InvalidVersion;
    procedure Test_UuidV7_Timestamp_InvalidVariant;
    procedure Test_TUUID_Invalid_URN_NoDash_Base64Url;
    procedure Test_Batch_CountZero_And_OpenArray_Static;
  end;

implementation

procedure TTestCase_Uuid_Negative.Test_UuidV7_Timestamp_InvalidVersion;
var R: TUuid128; S: string; ts: Int64;
begin
  R := UuidV7_Raw;           // valid v7
  R[6] := (R[6] and $0F) or $40; // force version=4
  S := UuidToString(R);
  ts := UuidV7_TimestampMs(S);
  AssertEquals('invalid version -> -1', Int64(-1), ts);
end;

procedure TTestCase_Uuid_Negative.Test_UuidV7_Timestamp_InvalidVariant;
var R: TUuid128; S: string; ts: Int64;
begin
  R := UuidV7_Raw;           // valid v7
  R[8] := (R[8] and $3F) or $C0; // force variant=11b (non-RFC4122)
  S := UuidToString(R);
  ts := UuidV7_TimestampMs(S);
  AssertEquals('invalid variant -> -1', Int64(-1), ts);
end;

procedure TTestCase_Uuid_Negative.Test_TUUID_Invalid_URN_NoDash_Base64Url;
var ok: Boolean; u: TUUID; raised: Boolean;
begin
  ok := TUUID.TryParseURN('urn:uuid:bad', u);
  AssertFalse('invalid URN', ok);
  ok := TUUID.TryParseNoDash('1234567890ABCDEF', u); // 16 chars only
  AssertFalse('invalid no-dash length', ok);
  ok := TUUID.TryFromBase64Url('short_base64url', u);
  AssertFalse('invalid base64url', ok);
  // FromBase64Url should raise on invalid
  raised := False;
  try
    u := TUUID.FromBase64Url('invalid__________________');
  except
    on E: Exception do raised := True;
  end;
  AssertTrue('FromBase64Url raises', raised);
end;

procedure TTestCase_Uuid_Negative.Test_Batch_CountZero_And_OpenArray_Static;
var arrDyn: TUuid128Array; arrStat: array[0..3] of TUuid128; i: Integer; G: IUuidV7Generator;
begin
  // Count=0
  arrDyn := UuidV7_RawN(0);
  AssertEquals('len=0', 0, Length(arrDyn));
  SetLength(arrDyn, 0);
  UuidV7_FillRawN(arrDyn); // should not crash
  UuidV4_FillRawN(arrDyn); // should not crash
  // open array static
  for i := 0 to High(arrStat) do FillChar(arrStat[i], SizeOf(TUuid128), 0);
  UuidV7_FillRawN(arrStat);
  for i := 0 to High(arrStat) do begin
    AssertEquals('version 7', 7, (arrStat[i][6] shr 4) and $0F);
    AssertTrue('variant RFC4122', (arrStat[i][8] and $C0) = $80);
  end;
  // generator open array
  G := CreateUuidV7Monotonic;
  G.NextRawN(arrStat);
  for i := 0 to High(arrStat) do begin
    AssertEquals('version 7', 7, (arrStat[i][6] shr 4) and $0F);
    AssertTrue('variant RFC4122', (arrStat[i][8] and $C0) = $80);
  end;
end;

initialization
  RegisterTest('fafafa.core.id.UUID.Negative', TTestCase_Uuid_Negative);
end.


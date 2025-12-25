{
  Test_fafafa_core_id_p4_features - P4 扩展 ID 生成器测试
  测试: Sqids, ObjectId, Timeflake
}

unit Test_fafafa_core_id_p4_features;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fpcunit,
  testregistry,
  fafafa.core.math,
  fafafa.core.id.base,     // ✅ TTimeflake, TObjectId 类型定义
  fafafa.core.id.sqids,
  fafafa.core.id.objectid,
  fafafa.core.id.timeflake;

type
  { TTestSqids - Sqids 测试 }
  TTestSqids = class(TTestCase)
  published
    procedure Test_Sqids_EncodeOne;
    procedure Test_Sqids_EncodeMultiple;
    procedure Test_Sqids_DecodeRoundTrip;
    procedure Test_Sqids_CustomAlphabet;
    procedure Test_Sqids_MinLength;
    procedure Test_Sqids_Generator;
    procedure Test_Sqids_Validation;
    procedure Test_Sqids_EmptyArray;
  end;

  { TTestObjectId - ObjectId 测试 }
  TTestObjectId = class(TTestCase)
  published
    procedure Test_ObjectId_Generate;
    procedure Test_ObjectId_StringFormat;
    procedure Test_ObjectId_ParseRoundTrip;
    procedure Test_ObjectId_Timestamp;
    procedure Test_ObjectId_Compare;
    procedure Test_ObjectId_Batch;
    procedure Test_ObjectId_Generator;
    procedure Test_ObjectId_Nil;
  end;

  { TTestTimeflake - Timeflake 测试 }
  TTestTimeflake = class(TTestCase)
  published
    procedure Test_Timeflake_Generate;
    procedure Test_Timeflake_StringFormat;
    procedure Test_Timeflake_UuidFormat;
    procedure Test_Timeflake_UuidRoundTrip;
    procedure Test_Timeflake_Timestamp;
    procedure Test_Timeflake_Monotonic;
    procedure Test_Timeflake_Batch;
    procedure Test_Timeflake_Generator;
  end;

implementation

{ TTestSqids }

procedure TTestSqids.Test_Sqids_EncodeOne;
var
  Id: string;
begin
  Id := SqidsEncodeOne(127);
  AssertTrue('Single encode should produce non-empty string', Id <> '');
  AssertTrue('Single encode should be decodable', SqidsDecodeOne(Id) = 127);
end;

procedure TTestSqids.Test_Sqids_EncodeMultiple;
var
  Id: string;
  Nums: TUInt64Array;
begin
  Id := SqidsEncode([1, 2, 3]);
  AssertTrue('Multiple encode should produce non-empty string', Id <> '');

  Nums := SqidsDecode(Id);
  AssertEquals('Should decode to 3 numbers', 3, Length(Nums));
  AssertEquals('First number', 1, Nums[0]);
  AssertEquals('Second number', 2, Nums[1]);
  AssertEquals('Third number', 3, Nums[2]);
end;

procedure TTestSqids.Test_Sqids_DecodeRoundTrip;
var
  I: Integer;
  Id: string;
  Original, Decoded: UInt64;
begin
  for I := 0 to 100 do
  begin
    Original := UInt64(I) * 1000;
    Id := SqidsEncodeOne(Original);
    Decoded := SqidsDecodeOne(Id);
    AssertEquals('Roundtrip for ' + IntToStr(Original), Original, Decoded);
  end;
end;

procedure TTestSqids.Test_Sqids_CustomAlphabet;
var
  Id: string;
  Nums: TUInt64Array;
begin
  // 使用数字字母表
  Id := SqidsEncodeEx([42], '0123456789abcdef', 0);
  AssertTrue('Custom alphabet should work', Id <> '');

  Nums := SqidsDecodeEx(Id, '0123456789abcdef');
  AssertEquals('Should decode correctly', 1, Length(Nums));
  AssertEquals('Value should match', 42, Nums[0]);
end;

procedure TTestSqids.Test_Sqids_MinLength;
var
  Gen: ISqids;
  Id: string;
begin
  Gen := CreateSqids(SQIDS_DEFAULT_ALPHABET, 10);
  Id := Gen.Encode([1]);
  AssertTrue('Min length should be respected', Length(Id) >= 10);
end;

procedure TTestSqids.Test_Sqids_Generator;
var
  Gen: ISqids;
  Id1, Id2: string;
begin
  Gen := CreateSqids;
  Id1 := Gen.Encode([100]);
  Id2 := Gen.Encode([100]);

  // 相同输入应产生相同输出 (确定性)
  AssertEquals('Same input should produce same output', Id1, Id2);
end;

procedure TTestSqids.Test_Sqids_Validation;
begin
  AssertTrue('Default alphabet should be valid', IsValidSqidsAlphabet(SQIDS_DEFAULT_ALPHABET));
  AssertFalse('Short alphabet should be invalid', IsValidSqidsAlphabet('ab'));
  AssertFalse('Duplicate chars should be invalid', IsValidSqidsAlphabet('aab'));
end;

procedure TTestSqids.Test_Sqids_EmptyArray;
var
  Id: string;
  Nums: TUInt64Array;
begin
  Id := SqidsEncode([]);
  AssertEquals('Empty array should produce empty string', '', Id);

  Nums := SqidsDecode('');
  AssertEquals('Empty string should decode to empty array', 0, Length(Nums));
end;

{ TTestObjectId }

procedure TTestObjectId.Test_ObjectId_Generate;
var
  Id1, Id2: TObjectId;
begin
  Id1 := ObjectId;
  Id2 := ObjectId;

  AssertFalse('Two ObjectIds should be different', ObjectIdEquals(Id1, Id2));
  AssertFalse('ObjectId should not be nil', ObjectIdIsNil(Id1));
end;

procedure TTestObjectId.Test_ObjectId_StringFormat;
var
  Id: TObjectId;
  S: string;
begin
  Id := ObjectId;
  S := ObjectIdToString(Id);

  AssertEquals('ObjectId string should be 24 chars', OBJECTID_STRING_LENGTH, Length(S));

  // 验证全是十六进制字符
  AssertTrue('Should be valid hex string', IsValidObjectIdString(S));
end;

procedure TTestObjectId.Test_ObjectId_ParseRoundTrip;
var
  Id1, Id2: TObjectId;
  S: string;
begin
  Id1 := ObjectId;
  S := ObjectIdToString(Id1);
  Id2 := ObjectIdFromString(S);

  AssertTrue('Roundtrip should preserve ObjectId', ObjectIdEquals(Id1, Id2));
end;

procedure TTestObjectId.Test_ObjectId_Timestamp;
var
  Id: TObjectId;
  Unix: UInt32;
  NowUnix: Int64;
begin
  Id := ObjectId;
  Unix := ObjectIdUnixTimestamp(Id);

  NowUnix := DateTimeToUnix(LocalTimeToUniversal(Now), False);

  // 时间戳应该在当前时间附近 (±2秒)
  AssertTrue('Timestamp should be recent', Abs(Int64(Unix) - NowUnix) <= 2);
end;

procedure TTestObjectId.Test_ObjectId_Compare;
var
  Id1, Id2: TObjectId;
begin
  Id1 := ObjectId;
  Sleep(10);  // 确保时间不同
  Id2 := ObjectId;

  AssertTrue('Later ObjectId should be greater', ObjectIdCompare(Id2, Id1) > 0);
  AssertEquals('Same ObjectId should be equal', 0, ObjectIdCompare(Id1, Id1));
end;

procedure TTestObjectId.Test_ObjectId_Batch;
var
  Ids: TObjectIdArray;
  I: Integer;
begin
  Ids := ObjectIdN(100);
  AssertEquals('Batch should produce correct count', 100, Length(Ids));

  // 验证唯一性
  for I := 0 to High(Ids) - 1 do
    AssertFalse('Batch IDs should be unique', ObjectIdEquals(Ids[I], Ids[I + 1]));
end;

procedure TTestObjectId.Test_ObjectId_Generator;
var
  Gen: IObjectIdGenerator;
  Id1, Id2: TObjectId;
begin
  Gen := CreateObjectIdGenerator;
  Id1 := Gen.Next;
  Id2 := Gen.Next;

  AssertFalse('Generator should produce unique IDs', ObjectIdEquals(Id1, Id2));
end;

procedure TTestObjectId.Test_ObjectId_Nil;
var
  Id: TObjectId;
begin
  Id := ObjectIdNil;
  AssertTrue('Nil ObjectId should be nil', ObjectIdIsNil(Id));
  AssertEquals('Nil ObjectId string', '000000000000000000000000', ObjectIdToString(Id));
end;

{ TTestTimeflake }

procedure TTestTimeflake.Test_Timeflake_Generate;
var
  Id1, Id2: TTimeflake;
begin
  Id1 := Timeflake;
  Id2 := Timeflake;

  AssertFalse('Two Timeflakes should be different', TimeflakeEquals(Id1, Id2));
  AssertFalse('Timeflake should not be nil', TimeflakeIsNil(Id1));
end;

procedure TTestTimeflake.Test_Timeflake_StringFormat;
var
  Id: TTimeflake;
  S: string;
begin
  Id := Timeflake;
  S := TimeflakeToString(Id);

  AssertEquals('Timeflake string should be 22 chars', TIMEFLAKE_STRING_LENGTH, Length(S));
end;

procedure TTestTimeflake.Test_Timeflake_UuidFormat;
var
  Id: TTimeflake;
  S: string;
begin
  Id := Timeflake;
  S := TimeflakeToUuidString(Id);

  AssertEquals('UUID string should be 36 chars', 36, Length(S));
  AssertEquals('Dash at position 9', '-', S[9]);
  AssertEquals('Dash at position 14', '-', S[14]);
  AssertEquals('Dash at position 19', '-', S[19]);
  AssertEquals('Dash at position 24', '-', S[24]);
end;

procedure TTestTimeflake.Test_Timeflake_UuidRoundTrip;
var
  Id1, Id2: TTimeflake;
  S: string;
begin
  // 使用 UUID 格式进行 roundtrip 测试
  Id1 := Timeflake;
  S := TimeflakeToUuidString(Id1);
  Id2 := TimeflakeFromUuidString(S);

  AssertTrue('UUID roundtrip should preserve Timeflake', TimeflakeEquals(Id1, Id2));
end;

procedure TTestTimeflake.Test_Timeflake_Timestamp;
var
  Id: TTimeflake;
  Ms: Int64;
  NowMs: Int64;
begin
  Id := Timeflake;
  Ms := TimeflakeUnixMs(Id);

  NowMs := DateTimeToUnix(LocalTimeToUniversal(Now), False) * 1000 +
           MilliSecondOf(Now);

  // 时间戳应该在当前时间附近 (±200ms)
  AssertTrue('Timestamp should be recent', Abs(Ms - NowMs) <= 200);
end;

procedure TTestTimeflake.Test_Timeflake_Monotonic;
var
  Ids: array[0..99] of TTimeflake;
  I: Integer;
begin
  for I := 0 to 99 do
    Ids[I] := TimeflakeMonotonic;

  // 验证单调递增
  for I := 0 to 98 do
    AssertTrue('Monotonic Timeflakes should be ordered',
      TimeflakeCompare(Ids[I], Ids[I + 1]) < 0);
end;

procedure TTestTimeflake.Test_Timeflake_Batch;
var
  Ids: TTimeflakeArray;
  I: Integer;
begin
  Ids := TimeflakeN(100);
  AssertEquals('Batch should produce correct count', 100, Length(Ids));

  // 验证有序性 (批量使用单调生成器)
  for I := 0 to High(Ids) - 1 do
    AssertTrue('Batch IDs should be ordered', TimeflakeCompare(Ids[I], Ids[I + 1]) < 0);
end;

procedure TTestTimeflake.Test_Timeflake_Generator;
var
  Gen: ITimeflakeGenerator;
  Id1, Id2: TTimeflake;
begin
  Gen := CreateTimeflakeGenerator;
  Id1 := Gen.Next;
  Id2 := Gen.Next;

  AssertTrue('Generator should produce ordered IDs', TimeflakeCompare(Id1, Id2) < 0);
end;

initialization
  RegisterTest(TTestSqids);
  RegisterTest(TTestObjectId);
  RegisterTest(TTestTimeflake);

end.

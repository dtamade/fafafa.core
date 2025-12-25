{
  Test_fafafa_core_id_p2_features — Phase 3 P2 新特性测试

  - UUID v8 (自定义布局)
  - Sonyflake (10ms 精度变体)
  - JSON 序列化支持
}

unit Test_fafafa_core_id_p2_features;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.id,
  fafafa.core.id.v8,
  fafafa.core.id.ulid,
  fafafa.core.id.ksuid,
  fafafa.core.id.snowflake,
  fafafa.core.id.sonyflake,
  fafafa.core.id.json;

type
  { UUID v8 tests }
  TTestCase_P2_UuidV8 = class(TTestCase)
  published
    procedure Test_V8_FromBytes;
    procedure Test_V8_Version_Variant;
    procedure Test_V8_FromInt64_Roundtrip;
    procedure Test_V8_FromHash;
  end;

  { Sonyflake tests }
  TTestCase_P2_Sonyflake = class(TTestCase)
  published
    procedure Test_Basic_Generation;
    procedure Test_Monotonic;
    procedure Test_MachineID;
    procedure Test_Decompose;
    procedure Test_Timestamp_Extraction;
  end;

  { JSON serialization tests }
  TTestCase_P2_Json = class(TTestCase)
  published
    procedure Test_UUID_ToJson_String;
    procedure Test_UUID_ToJson_Object;
    procedure Test_UUID_FromJson;
    procedure Test_UUID_Array_Json;
    procedure Test_ULID_Json_Roundtrip;
    procedure Test_KSUID_Json_Roundtrip;
    procedure Test_Snowflake_Json_Roundtrip;
    procedure Test_Id_Detect;
  end;

implementation

{ TTestCase_P2_UuidV8 }

procedure TTestCase_P2_UuidV8.Test_V8_FromBytes;
var
  Data: array[0..15] of Byte;
  U: TUuid128;
  I: Integer;
begin
  // 填充测试数据
  for I := 0 to 15 do
    Data[I] := Byte(I * 17);

  U := UuidV8(Data);

  // 验证版本和变体
  AssertTrue('IsUuidV8', IsUuidV8(U));
  AssertEquals('Version 8', 8, (U[6] shr 4) and $0F);
  AssertEquals('Variant', 2, (U[8] shr 6) and $03);
end;

procedure TTestCase_P2_UuidV8.Test_V8_Version_Variant;
var
  U: TUuid128;
  Data: array[0..15] of Byte;
begin
  FillChar(Data[0], 16, $FF);  // 全 1
  U := UuidV8(Data);

  // 版本位应该是 8，即使原数据是 $FF
  AssertEquals('Version forced to 8', 8, (U[6] shr 4) and $0F);

  // 变体位应该是 10xx
  AssertEquals('Variant forced to RFC4122', 2, (U[8] shr 6) and $03);
end;

procedure TTestCase_P2_UuidV8.Test_V8_FromInt64_Roundtrip;
var
  U: TUuid128;
  HighIn, LowIn: Int64;
  HighOut, LowOut: Int64;
begin
  HighIn := $1234567890ABCDEF;
  LowIn := $FEDCBA0987654321;

  U := UuidV8_FromInt64(HighIn, LowIn);
  AssertTrue('IsUuidV8', IsUuidV8(U));

  UuidV8_ExtractInt64(U, HighOut, LowOut);

  // 注意：版本和变体位会被覆盖，所以不能完全还原
  // 但其他位应该保留
  AssertTrue('High preserved (except ver/var bits)',
    ((HighIn xor HighOut) and $FFFFFFFFFFFF0FFF) = 0);
end;

procedure TTestCase_P2_UuidV8.Test_V8_FromHash;
var
  Hash: array[0..31] of Byte;  // SHA-256 大小
  U: TUuid128;
  I: Integer;
begin
  // 模拟 SHA-256 哈希
  for I := 0 to 31 do
    Hash[I] := Byte(I);

  U := UuidV8_FromHash(Hash);

  AssertTrue('IsUuidV8', IsUuidV8(U));
  // 前 6 字节应该是哈希的前 6 字节
  AssertEquals('Byte 0', 0, U[0]);
  AssertEquals('Byte 1', 1, U[1]);
  AssertEquals('Byte 5', 5, U[5]);
end;

{ TTestCase_P2_Sonyflake }

procedure TTestCase_P2_Sonyflake.Test_Basic_Generation;
var
  Gen: ISonyflake;
  ID: TSonyflakeID;
begin
  Gen := CreateSonyflake(1234);
  ID := Gen.NextID;

  AssertTrue('ID > 0', ID > 0);
  AssertEquals('MachineID', 1234, SonyflakeMachineID(ID));
end;

procedure TTestCase_P2_Sonyflake.Test_Monotonic;
var
  Gen: ISonyflake;
  ID1, ID2, ID3: TSonyflakeID;
begin
  Gen := CreateSonyflake(100);
  ID1 := Gen.NextID;
  ID2 := Gen.NextID;
  ID3 := Gen.NextID;

  AssertTrue('ID1 < ID2', ID1 < ID2);
  AssertTrue('ID2 < ID3', ID2 < ID3);
end;

procedure TTestCase_P2_Sonyflake.Test_MachineID;
var
  Gen: ISonyflake;
  ID: TSonyflakeID;
begin
  Gen := CreateSonyflake($ABCD);
  ID := Gen.NextID;

  AssertEquals('MachineID from ID', $ABCD, SonyflakeMachineID(ID));
  AssertEquals('MachineID from Gen', $ABCD, Gen.MachineID);
end;

procedure TTestCase_P2_Sonyflake.Test_Decompose;
var
  Gen: ISonyflake;
  ID: TSonyflakeID;
  TimeUnits, Sequence: Int64;
  MachineID: Word;
begin
  Gen := CreateSonyflake(999);
  ID := Gen.NextID;

  AssertTrue('Decompose', Gen.Decompose(ID, TimeUnits, Sequence, MachineID));
  AssertEquals('MachineID', 999, MachineID);
  AssertTrue('TimeUnits > 0', TimeUnits > 0);
  AssertTrue('Sequence >= 0', Sequence >= 0);
end;

procedure TTestCase_P2_Sonyflake.Test_Timestamp_Extraction;
var
  Gen: ISonyflake;
  ID: TSonyflakeID;
  DT: TDateTime;
  NowDT: TDateTime;
  DiffSec: Double;
begin
  Gen := CreateSonyflake(1);
  ID := Gen.NextID;

  DT := SonyflakeTimestamp(ID);
  // SonyflakeTimestamp 返回 UTC 时间，需要用 UTC 时间比较
  NowDT := LocalTimeToUniversal(Now);

  // 应该在几秒内
  DiffSec := Abs(DT - NowDT) * 86400;
  AssertTrue('Timestamp close to now: diff=' + FloatToStr(DiffSec), DiffSec < 10);
end;

{ TTestCase_P2_Json }

procedure TTestCase_P2_Json.Test_UUID_ToJson_String;
var
  U: TUuid128;
  Json: string;
begin
  U := UuidV4_Raw;
  Json := TUuidJson.ToJson(U, ijfString);

  AssertTrue('Starts with quote', Json[1] = '"');
  AssertTrue('Contains dashes', Pos('-', Json) > 0);
  AssertEquals('Length', 38, Length(Json));  // 36 + 2 quotes
end;

procedure TTestCase_P2_Json.Test_UUID_ToJson_Object;
var
  U: TUuid128;
  Json: string;
begin
  U := UuidV4_Raw;
  Json := TUuidJson.ToJson(U, ijfObject);

  AssertTrue('Contains uuid field', Pos('"uuid"', Json) > 0);
  AssertTrue('Contains version field', Pos('"version"', Json) > 0);
end;

procedure TTestCase_P2_Json.Test_UUID_FromJson;
var
  U1, U2: TUuid128;
  Json: string;
begin
  U1 := UuidV4_Raw;
  Json := TUuidJson.ToJson(U1, ijfString);
  U2 := TUuidJson.FromJson(Json);

  AssertEquals('Roundtrip', UuidToString(U1), UuidToString(U2));
end;

procedure TTestCase_P2_Json.Test_UUID_Array_Json;
var
  Arr: TUuid128Array;
  Json: string;
  Arr2: TUuid128Array;
begin
  SetLength(Arr, 3);
  Arr[0] := UuidV4_Raw;
  Arr[1] := UuidV4_Raw;
  Arr[2] := UuidV4_Raw;

  Json := TUuidJson.ArrayToJson(Arr);
  AssertTrue('Is array', Json[1] = '[');

  Arr2 := TUuidJson.ArrayFromJson(Json);
  AssertEquals('Count', 3, Length(Arr2));
  AssertEquals('First', UuidToString(Arr[0]), UuidToString(Arr2[0]));
end;

procedure TTestCase_P2_Json.Test_ULID_Json_Roundtrip;
var
  U1, U2: TUlid128;
  Json: string;
begin
  U1 := UlidNow_Raw;
  Json := TUlidJson.ToJson(U1, ijfString);
  U2 := TUlidJson.FromJson(Json);

  AssertEquals('Roundtrip', UlidToString(U1), UlidToString(U2));
end;

procedure TTestCase_P2_Json.Test_KSUID_Json_Roundtrip;
var
  K1, K2: TKsuid160;
  Json: string;
begin
  K1 := KsuidNow_Raw;
  Json := TKsuidJson.ToJson(K1, ijfString);
  K2 := TKsuidJson.FromJson(Json);

  AssertEquals('Roundtrip', KsuidToString(K1), KsuidToString(K2));
end;

procedure TTestCase_P2_Json.Test_Snowflake_Json_Roundtrip;
var
  Gen: ISnowflake;
  ID1, ID2: TSnowflakeID;
  Json: string;
begin
  Gen := CreateSnowflake(1);
  ID1 := Gen.NextID;
  Json := TSnowflakeJson.ToJson(ID1, ijfString);
  ID2 := TSnowflakeJson.FromJson(Json);

  AssertEquals('Roundtrip', ID1, ID2);
end;

procedure TTestCase_P2_Json.Test_Id_Detect;
begin
  AssertEquals('UUID', 'UUID', TIdJson.Detect('550e8400-e29b-41d4-a716-446655440000'));
  AssertEquals('ULID', 'ULID', TIdJson.Detect('01ARZ3NDEKTSV4RRFFQ69G5FAV'));
  AssertEquals('KSUID', 'KSUID', TIdJson.Detect('0ujsswThIGTUYm2K8FjOOfXtY1K'));
  AssertEquals('Snowflake', 'Snowflake', TIdJson.Detect('1234567890123456789'));
end;

initialization
  RegisterTest('fafafa.core.id.P2', TTestCase_P2_UuidV8);
  RegisterTest('fafafa.core.id.P2', TTestCase_P2_Sonyflake);
  RegisterTest('fafafa.core.id.P2', TTestCase_P2_Json);

end.

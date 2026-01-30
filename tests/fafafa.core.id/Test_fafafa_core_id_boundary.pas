{
  Test_fafafa_core_id_boundary - 边界条件测试

  测试目标:
  - Snowflake Worker ID 边界
  - 字符串解析边界
  - 批量生成边界
}

unit Test_fafafa_core_id_boundary;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, DateUtils, fafafa.core.math;

type
  TBoundaryTest = class(TTestCase)
  published
    // Snowflake Worker ID 边界测试
    procedure Test_Snowflake_WorkerId_Zero;
    procedure Test_Snowflake_WorkerId_Max;
    procedure Test_Snowflake_WorkerId_Overflow;

    // 解析边界测试
    procedure Test_Uuid_Parse_Invalid_Length;
    procedure Test_Uuid_Parse_Valid;
    procedure Test_Ulid_Parse_Invalid_Length;
    procedure Test_Ulid_Parse_Valid;

    // 时间戳提取测试
    procedure Test_UuidV7_Timestamp_Recent;
    procedure Test_Ulid_Timestamp_Recent;
    procedure Test_Timeflake_Timestamp_Recent;

    // 批量生成边界
    procedure Test_Batch_Zero_Count;
    procedure Test_Batch_Large_Count;

    // ✅ P1: NanoID 边界测试
    procedure Test_NanoId_Default_Length;
    procedure Test_NanoId_Custom_Length;
    procedure Test_NanoId_Minimum_Length;
    procedure Test_NanoId_IsValid_Correct;
    procedure Test_NanoId_IsValid_Invalid_Chars;

    // ✅ P1: CUID2 边界测试
    procedure Test_Cuid2_Default_Length;
    procedure Test_Cuid2_Custom_Length;
    procedure Test_Cuid2_First_Char_IsLetter;
  end;

implementation

uses
  fafafa.core.id,
  fafafa.core.id.base,  // ✅ TTimeflake, TXid96 等类型定义
  fafafa.core.id.ulid,
  fafafa.core.id.ksuid,
  fafafa.core.id.snowflake,
  fafafa.core.id.timeflake,
  fafafa.core.id.nanoid,
  fafafa.core.id.cuid2;

{ TBoundaryTest }

procedure TBoundaryTest.Test_Snowflake_WorkerId_Zero;
var
  Gen: ISnowflake;
  Id: TSnowflakeID;
  WorkerId: Integer;
begin
  Gen := CreateSnowflake(0);  // Worker ID = 0 (最小值)
  Id := Gen.NextID;

  // 提取 Worker ID (bits 12-21)
  WorkerId := (Id shr 12) and $3FF;
  AssertEquals('Worker ID should be 0', 0, WorkerId);
  AssertTrue('ID should be positive', Id > 0);
end;

procedure TBoundaryTest.Test_Snowflake_WorkerId_Max;
var
  Gen: ISnowflake;
  Id: TSnowflakeID;
  WorkerId: Integer;
begin
  Gen := CreateSnowflake(1023);  // Worker ID = 1023 (最大值 10-bit)
  Id := Gen.NextID;

  WorkerId := (Id shr 12) and $3FF;
  AssertEquals('Worker ID should be 1023', 1023, WorkerId);
end;

procedure TBoundaryTest.Test_Snowflake_WorkerId_Overflow;
var
  Gen: ISnowflake;
  ExceptionRaised: Boolean;
begin
  // 1024 超过 10-bit 范围，应该抛出异常
  ExceptionRaised := False;
  try
    Gen := CreateSnowflake(1024);
  except
    on E: Exception do
      ExceptionRaised := True;
  end;
  AssertTrue('Worker ID 1024 should raise exception', ExceptionRaised);
end;

procedure TBoundaryTest.Test_Uuid_Parse_Invalid_Length;
var
  Id: TUuid128;
  Ok: Boolean;
begin
  // 太短
  Ok := TryParseUuid('12345', Id);
  AssertFalse('Should fail on too short string', Ok);

  // 太长
  Ok := TryParseUuid('12345678-1234-1234-1234-1234567890ab-extra', Id);
  AssertFalse('Should fail on too long string', Ok);
end;

procedure TBoundaryTest.Test_Uuid_Parse_Valid;
var
  Id: TUuid128;
  Ok: Boolean;
begin
  // 正确长度
  Ok := TryParseUuid('12345678-1234-1234-1234-1234567890ab', Id);
  AssertTrue('Should succeed on correct format', Ok);

  // 无破折号格式
  Ok := TryParseUuidNoDash('12345678123412341234567890abcdef', Id);
  AssertTrue('Should succeed on no-dash format', Ok);
end;

procedure TBoundaryTest.Test_Ulid_Parse_Invalid_Length;
var
  Id: TUlid128;
  Ok: Boolean;
begin
  // 太短
  Ok := TryParseUlid('01ARYZ', Id);
  AssertFalse('Too short ULID should fail', Ok);

  // 太长
  Ok := TryParseUlid('01ARYZ6S41TSV4RRFFQ69G5FAVEXTRA', Id);
  AssertFalse('Too long ULID should fail', Ok);
end;

procedure TBoundaryTest.Test_Ulid_Parse_Valid;
var
  Id: TUlid128;
  Ok: Boolean;
  S: string;
begin
  // 生成一个 ULID 并解析回去
  S := Ulid;
  Ok := TryParseUlid(S, Id);
  AssertTrue('Should parse generated ULID', Ok);
  AssertEquals('Roundtrip should match', S, UlidToString(Id));
end;

procedure TBoundaryTest.Test_UuidV7_Timestamp_Recent;
var
  S: string;
  Ms: Int64;
  NowMs: Int64;
  Diff: Int64;
begin
  S := UuidV7;
  Ms := UuidV7_TimestampMs(S);
  NowMs := DateTimeToUnix(LocalTimeToUniversal(Now), False) * 1000 +
           MilliSecondOf(Now);

  Diff := Abs(Ms - NowMs);
  AssertTrue('UUID v7 timestamp should be within 2 seconds of now', Diff < 2000);
end;

procedure TBoundaryTest.Test_Ulid_Timestamp_Recent;
var
  S: string;
  Ms: Int64;
  NowMs: Int64;
  Diff: Int64;
begin
  S := Ulid;
  Ms := Ulid_TimestampMs(S);
  NowMs := DateTimeToUnix(LocalTimeToUniversal(Now), False) * 1000 +
           MilliSecondOf(Now);

  Diff := Abs(Ms - NowMs);
  AssertTrue('ULID timestamp should be within 2 seconds of now', Diff < 2000);
end;

procedure TBoundaryTest.Test_Timeflake_Timestamp_Recent;
var
  Id: TTimeflake;
  Ms: Int64;
  NowMs: Int64;
  Diff: Int64;
begin
  Id := Timeflake;
  Ms := TimeflakeUnixMs(Id);
  NowMs := DateTimeToUnix(LocalTimeToUniversal(Now), False) * 1000 +
           MilliSecondOf(Now);

  Diff := Abs(Ms - NowMs);
  AssertTrue('Timeflake timestamp should be within 2 seconds of now', Diff < 2000);
end;

procedure TBoundaryTest.Test_Batch_Zero_Count;
var
  Arr: TUuid128Array;
begin
  Arr := UuidV7_RawN(0);
  AssertEquals('Batch of 0 should return empty array', 0, Length(Arr));
end;

procedure TBoundaryTest.Test_Batch_Large_Count;
var
  Arr: TUuid128Array;
  I: Integer;
  AllUnique: Boolean;
begin
  Arr := UuidV7_RawN(1000);
  AssertEquals('Batch should return correct count', 1000, Length(Arr));

  // 检查所有 ID 都不相同 (简单检查: 相邻元素不同)
  AllUnique := True;
  for I := 0 to Length(Arr) - 2 do
  begin
    if CompareMem(@Arr[I][0], @Arr[I + 1][0], 16) then
    begin
      AllUnique := False;
      Break;
    end;
  end;
  AssertTrue('All IDs in batch should be unique', AllUnique);
end;

// ✅ P1: NanoID 边界测试
procedure TBoundaryTest.Test_NanoId_Default_Length;
var
  Id: string;
begin
  Id := NanoId;
  AssertEquals('Default NanoID length should be 21', 21, Length(Id));
end;

procedure TBoundaryTest.Test_NanoId_Custom_Length;
var
  Id: string;
begin
  Id := NanoId(10);
  AssertEquals('Custom NanoID length should be 10', 10, Length(Id));

  Id := NanoId(50);
  AssertEquals('Custom NanoID length should be 50', 50, Length(Id));
end;

procedure TBoundaryTest.Test_NanoId_Minimum_Length;
var
  Id: string;
begin
  Id := NanoId(1);
  AssertEquals('Minimum NanoID length should be 1', 1, Length(Id));
end;

procedure TBoundaryTest.Test_NanoId_IsValid_Correct;
var
  Id: string;
begin
  Id := NanoId;
  AssertTrue('Generated NanoID should be valid', IsValidNanoId(Id));
end;

procedure TBoundaryTest.Test_NanoId_IsValid_Invalid_Chars;
begin
  // 包含无效字符 (空格、特殊符号等)
  AssertFalse('NanoID with space should be invalid', IsValidNanoId('V1StGXR8 Z5jdHi6B-myT'));
  AssertFalse('NanoID with @ should be invalid', IsValidNanoId('V1StGXR8@Z5jdHi6B-myT'));
end;

// ✅ P1: CUID2 边界测试
procedure TBoundaryTest.Test_Cuid2_Default_Length;
var
  Id: string;
begin
  Id := Cuid2;
  AssertEquals('Default CUID2 length should be 24', 24, Length(Id));
end;

procedure TBoundaryTest.Test_Cuid2_Custom_Length;
var
  Id: string;
begin
  Id := Cuid2(10);  // 最小长度
  AssertEquals('CUID2 min length should be 10', 10, Length(Id));

  Id := Cuid2(32);
  AssertEquals('CUID2 custom length should be 32', 32, Length(Id));
end;

procedure TBoundaryTest.Test_Cuid2_First_Char_IsLetter;
var
  Id: string;
  FirstChar: Char;
  I: Integer;
begin
  // CUID2 首字符必须是字母
  for I := 1 to 100 do
  begin
    Id := Cuid2;
    FirstChar := Id[1];
    AssertTrue('First char must be letter a-z',
      (FirstChar >= 'a') and (FirstChar <= 'z'));
  end;
end;

initialization
  RegisterTest(TBoundaryTest);

end.

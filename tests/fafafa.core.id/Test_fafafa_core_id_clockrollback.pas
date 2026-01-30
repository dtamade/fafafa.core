{
  Test_fafafa_core_id_clockrollback - 时钟回拨和单调性测试

  测试目标:
  - 验证 ID 生成器的单调性保证（快速连续生成时 ID 必须递增）
  - 验证序列号溢出时的等待逻辑
  - 验证 Snowflake sbThrow 策略的异常类型
  - 压力测试高并发下的单调性

  注意: 真正的时钟回拨测试需要可注入的时间源接口。
        当前测试验证现有的单调性逻辑正常工作。
}

unit Test_fafafa_core_id_clockrollback;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, SyncObjs;

type
  TClockRollbackTest = class(TTestCase)
  published
    // 单调性测试
    procedure Test_UuidV7_RapidGeneration_Monotonic;
    procedure Test_Ulid_RapidGeneration_Monotonic;
    procedure Test_Timeflake_RapidGeneration_Monotonic;
    procedure Test_Snowflake_RapidGeneration_Monotonic;

    // 序列号压力测试（验证溢出处理）
    procedure Test_UuidV7_SequenceExhaustion_Handling;
    procedure Test_Snowflake_SequenceExhaustion_Handling;

    // Snowflake 异常策略测试
    procedure Test_Snowflake_ExceptionType_Defined;
  end;

implementation

uses
  fafafa.core.id,
  fafafa.core.id.base,  // ✅ TTimeflake 类型定义
  fafafa.core.id.ulid,
  fafafa.core.id.v7.monotonic,
  fafafa.core.id.ulid.monotonic,
  fafafa.core.id.timeflake,
  fafafa.core.id.snowflake;

const
  RAPID_COUNT = 10000;  // 快速生成的 ID 数量
  STRESS_COUNT = 5000;  // 压力测试数量

{ 辅助函数：比较两个 128 位 ID }
function CompareBytes16(const A, B: array of Byte): Integer;
var
  I: Integer;
begin
  for I := 0 to 15 do
  begin
    if A[I] < B[I] then Exit(-1);
    if A[I] > B[I] then Exit(1);
  end;
  Result := 0;
end;

{ TClockRollbackTest }

procedure TClockRollbackTest.Test_UuidV7_RapidGeneration_Monotonic;
var
  Gen: IUuidV7Generator;
  Prev, Curr: TUuid128;
  I: Integer;
  Violations: Integer;
begin
  Gen := CreateUuidV7Monotonic;
  Prev := Gen.NextRaw;
  Violations := 0;

  for I := 2 to RAPID_COUNT do
  begin
    Curr := Gen.NextRaw;
    if CompareBytes16(Curr, Prev) <= 0 then
      Inc(Violations);
    Prev := Curr;
  end;

  AssertEquals('UUID v7 monotonicity violations', 0, Violations);
end;

procedure TClockRollbackTest.Test_Ulid_RapidGeneration_Monotonic;
var
  Gen: IUlidGenerator;
  Prev, Curr: TUlid128;
  I: Integer;
  Violations: Integer;
begin
  Gen := CreateUlidMonotonic;
  Prev := Gen.NextRaw;
  Violations := 0;

  for I := 2 to RAPID_COUNT do
  begin
    Curr := Gen.NextRaw;
    if CompareBytes16(Curr, Prev) <= 0 then
      Inc(Violations);
    Prev := Curr;
  end;

  AssertEquals('ULID monotonicity violations', 0, Violations);
end;

procedure TClockRollbackTest.Test_Timeflake_RapidGeneration_Monotonic;
var
  Prev, Curr: TTimeflake;
  I: Integer;
  Violations: Integer;
begin
  Prev := TimeflakeMonotonic;
  Violations := 0;

  for I := 2 to RAPID_COUNT do
  begin
    Curr := TimeflakeMonotonic;
    if TimeflakeCompare(Curr, Prev) <= 0 then
      Inc(Violations);
    Prev := Curr;
  end;

  AssertEquals('Timeflake monotonicity violations', 0, Violations);
end;

procedure TClockRollbackTest.Test_Snowflake_RapidGeneration_Monotonic;
var
  Gen: ISnowflake;
  Prev, Curr: TSnowflakeID;
  I: Integer;
  Violations: Integer;
begin
  Gen := CreateSnowflake(1);  // Worker ID = 1
  Prev := Gen.NextID;
  Violations := 0;

  for I := 2 to RAPID_COUNT do
  begin
    Curr := Gen.NextID;
    if Curr <= Prev then
      Inc(Violations);
    Prev := Curr;
  end;

  AssertEquals('Snowflake monotonicity violations', 0, Violations);
end;

procedure TClockRollbackTest.Test_UuidV7_SequenceExhaustion_Handling;
var
  Gen: IUuidV7Generator;
  Ids: array[0..STRESS_COUNT - 1] of TUuid128;
  I, J: Integer;
  Duplicates: Integer;
begin
  // 快速生成大量 ID，测试序列号溢出时的等待逻辑
  Gen := CreateUuidV7Monotonic;

  for I := 0 to STRESS_COUNT - 1 do
    Ids[I] := Gen.NextRaw;

  // 检查唯一性
  Duplicates := 0;
  for I := 0 to STRESS_COUNT - 2 do
  begin
    for J := I + 1 to STRESS_COUNT - 1 do
    begin
      if CompareBytes16(Ids[I], Ids[J]) = 0 then
      begin
        Inc(Duplicates);
        Break;
      end;
    end;
  end;

  AssertEquals('UUID v7 duplicates under stress', 0, Duplicates);
end;

procedure TClockRollbackTest.Test_Snowflake_SequenceExhaustion_Handling;
var
  Gen: ISnowflake;
  Ids: array[0..STRESS_COUNT - 1] of TSnowflakeID;
  I, J: Integer;
  Duplicates: Integer;
begin
  // 快速生成大量 ID，测试序列号溢出时的等待逻辑
  Gen := CreateSnowflake(1);

  for I := 0 to STRESS_COUNT - 1 do
    Ids[I] := Gen.NextID;

  // 检查唯一性
  Duplicates := 0;
  for I := 0 to STRESS_COUNT - 2 do
  begin
    for J := I + 1 to STRESS_COUNT - 1 do
    begin
      if Ids[I] = Ids[J] then
      begin
        Inc(Duplicates);
        Break;
      end;
    end;
  end;

  AssertEquals('Snowflake duplicates under stress', 0, Duplicates);
end;

procedure TClockRollbackTest.Test_Snowflake_ExceptionType_Defined;
var
  E: ESnowflakeClockRollback;
begin
  // 验证异常类型已定义并可以创建
  E := ESnowflakeClockRollback.Create('Test clock rollback exception');
  try
    AssertTrue('Exception message set', Pos('rollback', LowerCase(E.Message)) > 0);
  finally
    E.Free;
  end;
end;

initialization
  RegisterTest(TClockRollbackTest);

end.

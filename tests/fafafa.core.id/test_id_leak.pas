{
  test_id_leak - Memory leak test for fafafa.core.id module

  编译: fpc -gh -gl -B -Fi./src -Fu./src -o./bin/test_id_leak tests/test_id_leak.pas
  运行: ./bin/test_id_leak
  预期: "0 unfreed memory blocks"
}

program test_id_leak;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils,
  fafafa.core.id,
  fafafa.core.id.ulid,
  fafafa.core.id.ksuid,
  fafafa.core.id.snowflake,
  fafafa.core.id.v5,
  fafafa.core.id.v6,
  fafafa.core.id.v8,
  fafafa.core.id.sonyflake,
  fafafa.core.id.json,
  fafafa.core.id.batch,
  fafafa.core.id.builder;

const
  ITERATIONS = 1000;

procedure TestUuidV4Leak;
var
  I: Integer;
  U: TUuid128;
  S: string;
begin
  WriteLn('Testing UUID v4...');
  for I := 1 to ITERATIONS do
  begin
    U := UuidV4_Raw;
    S := UuidToString(U);
  end;
  WriteLn('  UUID v4: OK');
end;

procedure TestUuidV5Leak;
var
  I: Integer;
  U: TUuid128;
  S: string;
begin
  WriteLn('Testing UUID v5...');
  for I := 1 to ITERATIONS do
  begin
    U := UuidV5_DNS('example.com');
    S := UuidToString(U);
    U := UuidV5_URL('https://example.com');
    S := UuidToString(U);
  end;
  WriteLn('  UUID v5: OK');
end;

procedure TestUuidV6Leak;
var
  I: Integer;
  U: TUuid128;
  S: string;
begin
  WriteLn('Testing UUID v6...');
  for I := 1 to ITERATIONS do
  begin
    U := UuidV6;
    S := UuidToString(U);
  end;
  WriteLn('  UUID v6: OK');
end;

procedure TestUuidV7Leak;
var
  I: Integer;
  U: TUuid128;
  S: string;
begin
  WriteLn('Testing UUID v7...');
  for I := 1 to ITERATIONS do
  begin
    U := UuidV7_Raw;
    S := UuidToString(U);
  end;
  WriteLn('  UUID v7: OK');
end;

procedure TestUuidV8Leak;
var
  I: Integer;
  U: TUuid128;
  S: string;
  Data: array[0..15] of Byte;
begin
  WriteLn('Testing UUID v8...');
  for I := 1 to ITERATIONS do
  begin
    FillChar(Data[0], 16, Byte(I mod 256));
    U := UuidV8(Data);
    S := UuidToString(U);
  end;
  WriteLn('  UUID v8: OK');
end;

procedure TestUlidLeak;
var
  I: Integer;
  U: TUlid128;
  S: string;
begin
  WriteLn('Testing ULID...');
  for I := 1 to ITERATIONS do
  begin
    U := UlidNow_Raw;
    S := UlidToString(U);
  end;
  WriteLn('  ULID: OK');
end;

procedure TestKsuidLeak;
var
  I: Integer;
  K: TKsuid160;
  S: string;
begin
  WriteLn('Testing KSUID...');
  for I := 1 to ITERATIONS do
  begin
    K := KsuidNow_Raw;
    S := KsuidToString(K);
  end;
  WriteLn('  KSUID: OK');
end;

procedure TestSnowflakeLeak;
var
  I: Integer;
  Gen: ISnowflake;
  ID: TSnowflakeID;
begin
  WriteLn('Testing Snowflake...');
  Gen := CreateSnowflake(1);
  for I := 1 to ITERATIONS do
  begin
    ID := Gen.NextID;
  end;
  Gen := nil;  // Release interface
  WriteLn('  Snowflake: OK');
end;

procedure TestSonyflakeLeak;
var
  I: Integer;
  Gen: ISonyflake;
  ID: TSonyflakeID;
begin
  WriteLn('Testing Sonyflake...');
  Gen := CreateSonyflake(1234);
  for I := 1 to ITERATIONS do
  begin
    ID := Gen.NextID;
  end;
  Gen := nil;  // Release interface
  WriteLn('  Sonyflake: OK');
end;

procedure TestJsonSerializationLeak;
var
  I: Integer;
  U: TUuid128;
  UL: TUlid128;
  K: TKsuid160;
  Gen: ISnowflake;
  SF: TSnowflakeID;
  Json: string;
begin
  WriteLn('Testing JSON serialization...');
  Gen := CreateSnowflake(1);

  for I := 1 to ITERATIONS do
  begin
    // UUID JSON
    U := UuidV4_Raw;
    Json := TUuidJson.ToJson(U, ijfString);
    U := TUuidJson.FromJson(Json);

    // ULID JSON
    UL := UlidNow_Raw;
    Json := TUlidJson.ToJson(UL, ijfString);
    UL := TUlidJson.FromJson(Json);

    // KSUID JSON
    K := KsuidNow_Raw;
    Json := TKsuidJson.ToJson(K, ijfString);
    K := TKsuidJson.FromJson(Json);

    // Snowflake JSON
    SF := Gen.NextID;
    Json := TSnowflakeJson.ToJson(SF, ijfString);
    SF := TSnowflakeJson.FromJson(Json);
  end;

  Gen := nil;
  WriteLn('  JSON serialization: OK');
end;

procedure TestBatchLeak;
var
  I: Integer;
  UuidArr: TUuid128Array;
  UlidArr: TUlid128Array;
  KsuidArr: TKsuid160Array;
  SnowArr: TSnowflakeIDArray;
begin
  WriteLn('Testing Batch generation...');

  for I := 1 to ITERATIONS div 10 do
  begin
    UuidArr := UuidV7_BatchN(100);
    SetLength(UuidArr, 0);

    UlidArr := Ulid_BatchN(100);
    SetLength(UlidArr, 0);

    KsuidArr := Ksuid_BatchN(100);
    SetLength(KsuidArr, 0);

    SnowArr := Snowflake_BatchN(100, 1);
    SetLength(SnowArr, 0);
  end;

  WriteLn('  Batch generation: OK');
end;

procedure TestBuilderLeak;
var
  I: Integer;
begin
  WriteLn('Testing Builder API...');
  for I := 1 to ITERATIONS do
  begin
    // These builders return value types, no allocation
    // Just exercise the code paths
    TIdBuilder.UUID.V4.Build;
    TIdBuilder.UUID.V7.Build;
    TIdBuilder.ULID.Build;
    TIdBuilder.KSUID.Build;
  end;
  WriteLn('  Builder API: OK');
end;

begin
  WriteLn('=== fafafa.core.id Memory Leak Test ===');
  WriteLn('Iterations: ', ITERATIONS);
  WriteLn('');

  TestUuidV4Leak;
  TestUuidV5Leak;
  TestUuidV6Leak;
  TestUuidV7Leak;
  TestUuidV8Leak;
  TestUlidLeak;
  TestKsuidLeak;
  TestSnowflakeLeak;
  TestSonyflakeLeak;
  TestJsonSerializationLeak;
  TestBatchLeak;
  TestBuilderLeak;

  WriteLn('');
  WriteLn('=== All tests completed ===');
  WriteLn('Check HeapTrc output for memory leaks.');
end.

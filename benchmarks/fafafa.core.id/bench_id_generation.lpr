{$CODEPAGE UTF8}
program bench_id_generation;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads, BaseUnix, Unix,
  {$IFDEF LINUX}Linux,{$ENDIF}
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  SysUtils, DateUtils, Classes,
  fafafa.core.id,
  fafafa.core.id.ulid,
  fafafa.core.id.ulid.monotonic,
  fafafa.core.id.snowflake,
  fafafa.core.id.ksuid,
  fafafa.core.id.objectid,
  fafafa.core.id.timeflake,
  fafafa.core.id.nanoid,
  fafafa.core.id.xid,
  fafafa.core.id.sqids;

const
  WARMUP_ITERATIONS = 1000;
  BENCHMARK_ITERATIONS = 100000;
  BATCH_SIZE = 1000;

type
  TBenchmarkResult = record
    Name: string;
    Iterations: Int64;
    TotalMs: Double;
    OpsPerSec: Double;
    NsPerOp: Double;
  end;

var
  Results: array of TBenchmarkResult;

procedure AddResult(const AName: string; AIterations: Int64; ATotalMs: Double);
var
  Idx: Integer;
begin
  Idx := Length(Results);
  SetLength(Results, Idx + 1);
  Results[Idx].Name := AName;
  Results[Idx].Iterations := AIterations;
  Results[Idx].TotalMs := ATotalMs;
  if ATotalMs > 0 then
  begin
    Results[Idx].OpsPerSec := (AIterations / ATotalMs) * 1000;
    Results[Idx].NsPerOp := (ATotalMs * 1000000) / AIterations;
  end;
end;

{$IFDEF UNIX}
function GetHighResTimestamp: Int64;
var
  ts: TTimeSpec;
begin
  clock_gettime(CLOCK_MONOTONIC, @ts);
  Result := Int64(ts.tv_sec) * 1000000000 + ts.tv_nsec;
end;

function TimestampToMs(StartNs, EndNs: Int64): Double;
begin
  Result := (EndNs - StartNs) / 1000000.0;
end;
{$ELSE}
var
  QPCFreq: Int64;

function GetHighResTimestamp: Int64;
begin
  QueryPerformanceCounter(Result);
end;

function TimestampToMs(StartTick, EndTick: Int64): Double;
begin
  Result := ((EndTick - StartTick) * 1000.0) / QPCFreq;
end;
{$ENDIF}

procedure BenchmarkUuidV4;
var
  I: Integer;
  StartTs, EndTs: Int64;
  U: TUuid128;
begin
  // Warmup
  for I := 1 to WARMUP_ITERATIONS do
    U := UuidV4_Raw;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    U := UuidV4_Raw;
  EndTs := GetHighResTimestamp;

  AddResult('UUID v4 (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkUuidV4String;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := UuidV4;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := UuidV4;
  EndTs := GetHighResTimestamp;

  AddResult('UUID v4 (String)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkUuidV7;
var
  I: Integer;
  StartTs, EndTs: Int64;
  U: TUuid128;
begin
  for I := 1 to WARMUP_ITERATIONS do
    U := UuidV7_Raw;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    U := UuidV7_Raw;
  EndTs := GetHighResTimestamp;

  AddResult('UUID v7 (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkUuidV7String;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := UuidV7;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := UuidV7;
  EndTs := GetHighResTimestamp;

  AddResult('UUID v7 (String)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkUuidV7Batch;
var
  I: Integer;
  StartTs, EndTs: Int64;
  Arr: array of TUuid128;
  TotalOps: Int64;
begin
  SetLength(Arr, BATCH_SIZE);

  // Warmup
  UuidV7_FillRawN(Arr);

  TotalOps := 0;
  StartTs := GetHighResTimestamp;
  for I := 1 to (BENCHMARK_ITERATIONS div BATCH_SIZE) do
  begin
    UuidV7_FillRawN(Arr);
    Inc(TotalOps, BATCH_SIZE);
  end;
  EndTs := GetHighResTimestamp;

  AddResult('UUID v7 (Batch ' + IntToStr(BATCH_SIZE) + ')', TotalOps, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkUlid;
var
  I: Integer;
  StartTs, EndTs: Int64;
  U: TUlid128;
begin
  for I := 1 to WARMUP_ITERATIONS do
    U := UlidNow_Raw;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    U := UlidNow_Raw;
  EndTs := GetHighResTimestamp;

  AddResult('ULID (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkUlidString;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := Ulid;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := Ulid;
  EndTs := GetHighResTimestamp;

  AddResult('ULID (String)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkUlidMonotonic;
var
  I: Integer;
  StartTs, EndTs: Int64;
  Gen: IUlidGenerator;
  U: TUlid128;
begin
  Gen := CreateUlidMonotonic;

  for I := 1 to WARMUP_ITERATIONS do
    U := Gen.NextRaw;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    U := Gen.NextRaw;
  EndTs := GetHighResTimestamp;

  AddResult('ULID Monotonic (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkSnowflake;
var
  I: Integer;
  StartTs, EndTs: Int64;
  Gen: ISnowflake;
  Id: TSnowflakeID;
begin
  Gen := CreateSnowflake(1);

  for I := 1 to WARMUP_ITERATIONS do
    Id := Gen.NextID;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    Id := Gen.NextID;
  EndTs := GetHighResTimestamp;

  AddResult('Snowflake (Locked)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkKsuid;
var
  I: Integer;
  StartTs, EndTs: Int64;
  K: TKsuid160;
begin
  for I := 1 to WARMUP_ITERATIONS do
    K := KsuidNow_Raw;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    K := KsuidNow_Raw;
  EndTs := GetHighResTimestamp;

  AddResult('KSUID (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkKsuidString;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := Ksuid;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := Ksuid;
  EndTs := GetHighResTimestamp;

  AddResult('KSUID (String/Base62)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkObjectId;
var
  I: Integer;
  StartTs, EndTs: Int64;
  Id: TObjectId;
begin
  for I := 1 to WARMUP_ITERATIONS do
    Id := ObjectId;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    Id := ObjectId;
  EndTs := GetHighResTimestamp;

  AddResult('ObjectId (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkObjectIdString;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := ObjectIdToString(ObjectId);

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := ObjectIdToString(ObjectId);
  EndTs := GetHighResTimestamp;

  AddResult('ObjectId (String)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkTimeflake;
var
  I: Integer;
  StartTs, EndTs: Int64;
  T: TTimeflake;
begin
  for I := 1 to WARMUP_ITERATIONS do
    T := Timeflake;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    T := Timeflake;
  EndTs := GetHighResTimestamp;

  AddResult('Timeflake (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkTimeflakeString;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := TimeflakeToString(Timeflake);

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := TimeflakeToString(Timeflake);
  EndTs := GetHighResTimestamp;

  AddResult('Timeflake (String/Base62)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkNanoId;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := NanoId;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := NanoId;
  EndTs := GetHighResTimestamp;

  AddResult('NanoId (21 chars)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkXid;
var
  I: Integer;
  StartTs, EndTs: Int64;
  X: TXid96;
begin
  for I := 1 to WARMUP_ITERATIONS do
    X := Xid;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    X := Xid;
  EndTs := GetHighResTimestamp;

  AddResult('XID (Raw)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkXidString;
var
  I: Integer;
  StartTs, EndTs: Int64;
  S: string;
begin
  for I := 1 to WARMUP_ITERATIONS do
    S := XidString;

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := XidString;
  EndTs := GetHighResTimestamp;

  AddResult('XID (String)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure BenchmarkSqids;
var
  I: Integer;
  StartTs, EndTs: Int64;
  Gen: ISqids;
  S: string;
begin
  Gen := CreateSqids;

  for I := 1 to WARMUP_ITERATIONS do
    S := Gen.Encode([I]);

  StartTs := GetHighResTimestamp;
  for I := 1 to BENCHMARK_ITERATIONS do
    S := Gen.Encode([I]);
  EndTs := GetHighResTimestamp;

  AddResult('Sqids (Encode)', BENCHMARK_ITERATIONS, TimestampToMs(StartTs, EndTs));
end;

procedure PrintResults;
var
  I: Integer;
  R: TBenchmarkResult;
begin
  WriteLn;
  WriteLn(StringOfChar('=', 80));
  WriteLn('fafafa.core.id Benchmark Results');
  WriteLn(StringOfChar('=', 80));
  WriteLn(Format('%-30s %12s %12s %12s', ['Generator', 'ops/sec', 'ns/op', 'total ms']));
  WriteLn(StringOfChar('-', 80));

  for I := 0 to High(Results) do
  begin
    R := Results[I];
    WriteLn(Format('%-30s %12.0f %12.1f %12.1f', [R.Name, R.OpsPerSec, R.NsPerOp, R.TotalMs]));
  end;

  WriteLn(StringOfChar('=', 80));
  WriteLn(Format('Iterations per test: %d (warmup: %d)', [BENCHMARK_ITERATIONS, WARMUP_ITERATIONS]));
  WriteLn;
end;

procedure SaveResultsToFile;
var
  F: TextFile;
  I: Integer;
  FileName: string;
begin
  FileName := 'results/benchmark_' + FormatDateTime('yyyy-mm-dd_hh-nn-ss', Now) + '.csv';
  AssignFile(F, FileName);
  try
    Rewrite(F);
    WriteLn(F, 'Generator,Iterations,TotalMs,OpsPerSec,NsPerOp');
    for I := 0 to High(Results) do
      WriteLn(F, Format('%s,%d,%.2f,%.0f,%.1f', [
        Results[I].Name,
        Results[I].Iterations,
        Results[I].TotalMs,
        Results[I].OpsPerSec,
        Results[I].NsPerOp
      ]));
    CloseFile(F);
    WriteLn('Results saved to: ', FileName);
  except
    on E: Exception do
      WriteLn('Failed to save results: ', E.Message);
  end;
end;

begin
  WriteLn('fafafa.core.id Performance Benchmark');
  WriteLn('Running ', BENCHMARK_ITERATIONS, ' iterations per test...');
  WriteLn;

  // UUID benchmarks
  Write('Benchmarking UUID v4 (Raw)...'); BenchmarkUuidV4; WriteLn(' done');
  Write('Benchmarking UUID v4 (String)...'); BenchmarkUuidV4String; WriteLn(' done');
  Write('Benchmarking UUID v7 (Raw)...'); BenchmarkUuidV7; WriteLn(' done');
  Write('Benchmarking UUID v7 (String)...'); BenchmarkUuidV7String; WriteLn(' done');
  Write('Benchmarking UUID v7 (Batch)...'); BenchmarkUuidV7Batch; WriteLn(' done');

  // ULID benchmarks
  Write('Benchmarking ULID (Raw)...'); BenchmarkUlid; WriteLn(' done');
  Write('Benchmarking ULID (String)...'); BenchmarkUlidString; WriteLn(' done');
  Write('Benchmarking ULID Monotonic...'); BenchmarkUlidMonotonic; WriteLn(' done');

  // Snowflake benchmark
  Write('Benchmarking Snowflake...'); BenchmarkSnowflake; WriteLn(' done');

  // KSUID benchmarks
  Write('Benchmarking KSUID (Raw)...'); BenchmarkKsuid; WriteLn(' done');
  Write('Benchmarking KSUID (String)...'); BenchmarkKsuidString; WriteLn(' done');

  // ObjectId benchmarks
  Write('Benchmarking ObjectId (Raw)...'); BenchmarkObjectId; WriteLn(' done');
  Write('Benchmarking ObjectId (String)...'); BenchmarkObjectIdString; WriteLn(' done');

  // Timeflake benchmarks
  Write('Benchmarking Timeflake (Raw)...'); BenchmarkTimeflake; WriteLn(' done');
  Write('Benchmarking Timeflake (String)...'); BenchmarkTimeflakeString; WriteLn(' done');

  // NanoId benchmark
  Write('Benchmarking NanoId...'); BenchmarkNanoId; WriteLn(' done');

  // XID benchmarks
  Write('Benchmarking XID (Raw)...'); BenchmarkXid; WriteLn(' done');
  Write('Benchmarking XID (String)...'); BenchmarkXidString; WriteLn(' done');

  // Sqids benchmark
  Write('Benchmarking Sqids...'); BenchmarkSqids; WriteLn(' done');

  PrintResults;
  SaveResultsToFile;
end.

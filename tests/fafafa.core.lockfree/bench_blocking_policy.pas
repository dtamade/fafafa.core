unit bench_blocking_policy;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils, fafafa.core.math,
  fafafa.core.bench.util,
  fafafa.core.lockfree.factories,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.mapex.adapters;

procedure RunBlockingPolicyMicroBench;
procedure RunBlockingPolicyMicroBench_MultiModels;
procedure RunBlockingPolicyMicroBench_Aggressive;
procedure RunBlockingPolicyMicroBench_MultiModels_Aggressive;
procedure RunMapMicroBench;

// TBenchRow moved to fafafa.core.bench.util

// CSV writer unified via fafafa.core.bench.util.AppendCsv

implementation

uses
  fafafa.core.lockfree.backoff;

function CaseInsensitiveEqual(const L, R: string): Boolean;
begin
  Result := CompareText(L, R) = 0;
end;

function CaseInsensitiveHash32(const Key: string): Cardinal;
var
  i: SizeInt;
  h: Cardinal;
  c: Char;
begin
  // FNV-1a 32-bit (case-insensitive)
  h := Cardinal($811C9DC5);
  for i := 1 to Length(Key) do
  begin
    c := UpCase(Key[i]);
    h := h xor Cardinal(Ord(c));
    h := h * Cardinal($01000193);
  end;
  Result := h;
end;

function CaseInsensitiveHash64(const Key: string): QWord;
var
  i: SizeInt;
  h: QWord;
  c: Char;
begin
  // FNV-1a 64-bit (case-insensitive)
  h := QWord($CBF29CE484222325);
  for i := 1 to Length(Key) do
  begin
    c := UpCase(Key[i]);
    h := h xor QWord(Ord(c));
    h := h * QWord($100000001B3);
  end;
  Result := h;
end;

function MapComputeInc(const OldValue: Integer): Integer;
begin
  Result := OldValue + 1;
end;

var
  CurrentBackoffLabel: String = 'Default';

procedure BenchOne(const Name: string;
  const Q: specialize ILockFreeQueue<Integer>; N: Integer);
var
  i, v, repIdx, Repeats: Integer;
  t0, t1: TDateTime;
  durMs: Int64;
  opsPerMs, nsPerOp: Double;
  sumMs, sumNsPerOp, sumSqMs, sumSqNsPerOp: Double;
  avgMs, stdMs, avgNs, stdNs: Double;
  row: TBenchRow;
  repDur: array of Double;
  modelPart, policyPart: String;
  p: SizeInt;


  function PercentileOf(const arr: array of Double; p: Double): Double;
  var tmp: array of Double; i, j, n, idx: Integer; t: Double;
  begin
    n := Length(arr);
    if n = 0 then exit(0.0);
    SetLength(tmp, n);
    for i := 0 to n-1 do tmp[i] := arr[i];
    for i := 0 to n-2 do
      for j := i+1 to n-1 do
        if tmp[j] < tmp[i] then begin t := tmp[i]; tmp[i] := tmp[j]; tmp[j] := t; end;
    idx := Round((p/100.0) * (n-1));
    Result := tmp[idx];
  end;
begin
  Repeats := GetBenchRepeat;
  SetLength(repDur, Repeats);
  sumMs := 0; sumNsPerOp := 0; sumSqMs := 0; sumSqNsPerOp := 0;
  for repIdx := 1 to Repeats do
  begin
    t0 := Now;
    for i := 1 to N do begin
      Q.EnqueueBlocking(i, 10);
      Q.DequeueBlocking(v, 10);
    end;
    t1 := Now;
    durMs := MilliSecondsBetween(t1, t0);
    if durMs = 0 then durMs := 1; // avoid div by zero on very fast runs
    repDur[repIdx-1] := durMs;
    opsPerMs := N / durMs;
    nsPerOp := (durMs * 1000000.0) / N;
    sumMs += durMs; sumNsPerOp += nsPerOp;
    sumSqMs += durMs * durMs; sumSqNsPerOp += nsPerOp * nsPerOp;
  end;
  // averages
  avgMs := sumMs / Repeats;
  avgNs := sumNsPerOp / Repeats;
  // std dev (population)
  stdMs := Sqrt(Max(0.0, (sumSqMs / Repeats) - (avgMs * avgMs)));
  stdNs := Sqrt(Max(0.0, (sumSqNsPerOp / Repeats) - (avgNs * avgNs)));
  // console output (avg only for ops/ms)
  WriteLn(Format('%-18s %10d %8d %8.0f %10.2f %12.0f %12.0f',
    [Name, N, Round(avgMs), stdMs, N / Max(1.0, avgMs), avgNs, stdNs]));
  // CSV row for average (unified schema)
  p := Pos('/', Name);
  if p > 0 then begin
    modelPart := Copy(Name, 1, p-1);
    policyPart := Copy(Name, p+1, MaxInt);
  end else begin
    modelPart := '';
    policyPart := '';
  end;
  row.Name := Name; row.Model := modelPart; row.Backoff := CurrentBackoffLabel; row.WaitPolicy := policyPart;
  // Default capacity in this micro bench: SPSC/MPMC use 8 by builder, MPSC N/A
  if modelPart = 'SPSC' then row.Cap := 8
  else if modelPart = 'MPMC' then row.Cap := 8
  else row.Cap := 0;
  row.Batch := 1;
  row.Warmup := GetBenchWarmup; row.Repeats := Repeats; row.P50Ms := PercentileOf(repDur, 50); row.P90Ms := PercentileOf(repDur, 90); row.P95Ms := PercentileOf(repDur, 95); row.P99Ms := PercentileOf(repDur, 99);
  row.Host := GetBenchHost; row.RunId := GetBenchRunId; row.Commit := GetBenchCommit;
  row.N := N; row.Ms := Round(avgMs); row.MsStd := stdMs;
  row.OpsPerMs := N / Max(1.0, avgMs); row.NsPerOp := avgNs; row.NsPerOpStd := stdNs;
  AppendCsv(row);
end;

function GetBenchN: Integer;
var s: String;
begin
  s := GetEnvironmentVariable('FAFAFA_BENCH_N');
  if s <> '' then
    Result := StrToIntDef(s, 10000)
  else
    Result := 10000;
end;

function GetBenchRepeat: Integer;
var s: String;
begin
  s := GetEnvironmentVariable('FAFAFA_BENCH_REPEAT');
  if s <> '' then
    Result := StrToIntDef(s, 5)
  else
    Result := 5;
end;

function GetBenchOut: String;
begin
  Result := GetEnvironmentVariable('FAFAFA_BENCH_OUT');
  if Result = '' then Result := 'bench.csv';
end;

procedure PrintHeader(const Title: String; N, R: Integer);
begin
  WriteLn(Format('%s (N=%d, R=%d)', [Title, N, R]));
  WriteLn(Format('%-18s %10s %8s %10s %10s', ['name','ops','ms','ops/ms','ns/op']));
end;

procedure RunBlockingPolicyMicroBench;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  N: Integer;
begin
  N := GetBenchN;
  PrintHeader('--- MicroBench: BlockingPolicy SPSC ---', N, GetBenchRepeat);

  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelSPSC;
  Q := QB.BlockingPolicy(bpNone).Build;
  BenchOne('SPSC/bpNone', Q, N);

  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelSPSC;
  Q := QB.BlockingPolicy(bpSpin).Build;
  BenchOne('SPSC/bpSpin', Q, N);

  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelSPSC;
  Q := QB.BlockingPolicy(bpSleep).Build;
  BenchOne('SPSC/bpSleep', Q, N);
end;

procedure RunMapMicroBench;
var
  N, i: Integer;
  inserted, updated: Boolean;
  outV: Integer;
  t0, t1: TDateTime;
  durMs: Int64;
  M: specialize ILockFreeMapEx<string,Integer>;
  MB: specialize TMapBuilder<string,Integer>;
begin
  N := GetBenchN;
  WriteLn(Format('--- MicroBench: MapEx (N=%d, R=%d) ---', [N, GetBenchRepeat]));

  // OA: Case-insensitive comparer
  MB := specialize TMapBuilder<string,Integer>.New.Capacity(1024).ImplOA
    .WithComparer(@CaseInsensitiveHash32, @CaseInsensitiveEqual);
  M := MB.BuildEx;
  t0 := Now;
  for i := 1 to N do begin
    M.PutIfAbsent('Key'+IntToStr(i mod 128), i, inserted);
    M.Compute('KEY'+IntToStr(i mod 128), @MapComputeInc, updated);
    M.Get('key'+IntToStr(i mod 128), outV);
  end;
  t1 := Now;
  durMs := MilliSecondsBetween(t1, t0);
  if durMs = 0 then durMs := 1;
  WriteLn(Format('MapEx/OA: %d ops in %d ms (%.2f ops/ms)', [N*3, durMs, (N*3) / durMs]));

  // MM: 需要提供比较器
  MB := specialize TMapBuilder<string,Integer>.New.Capacity(1024).ImplMM
    .WithComparerMM(@CaseInsensitiveHash64, @CaseInsensitiveEqual);
  M := MB.BuildEx;
  t0 := Now;
  for i := 1 to N do begin
    M.PutIfAbsent('Key'+IntToStr(i mod 128), i, inserted);
    M.Compute('KEY'+IntToStr(i mod 128), @MapComputeInc, updated);
    M.Get('key'+IntToStr(i mod 128), outV);
  end;
  t1 := Now;
  durMs := MilliSecondsBetween(t1, t0);
  if durMs = 0 then durMs := 1;
  WriteLn(Format('MapEx/MM: %d ops in %d ms (%.2f ops/ms)', [N*3, durMs, (N*3) / durMs]));
end;

procedure RunBlockingPolicyMicroBench_MultiModels;
var
  QB: specialize TQueueBuilder<Integer>;
  Q: specialize ILockFreeQueue<Integer>;
  N: Integer;
begin
  N := GetBenchN;
  PrintHeader('--- MicroBench: BlockingPolicy MPSC/MPMC ---', N, GetBenchRepeat);

  // MPSC
  QB := specialize TQueueBuilder<Integer>.New.ModelMPSC;
  Q := QB.BlockingPolicy(bpNone).Build;
  BenchOne('MPSC/bpNone', Q, N);

  QB := specialize TQueueBuilder<Integer>.New.ModelMPSC;
  Q := QB.BlockingPolicy(bpSpin).Build;
  BenchOne('MPSC/bpSpin', Q, N);

  QB := specialize TQueueBuilder<Integer>.New.ModelMPSC;
  Q := QB.BlockingPolicy(bpSleep).Build;
  BenchOne('MPSC/bpSleep', Q, N);

  // MPMC
  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC;
  Q := QB.BlockingPolicy(bpNone).Build;
  BenchOne('MPMC/bpNone', Q, N);

  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC;
  Q := QB.BlockingPolicy(bpSpin).Build;
  BenchOne('MPMC/bpSpin', Q, N);

  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC;
  Q := QB.BlockingPolicy(bpSleep).Build;
  BenchOne('MPMC/bpSleep', Q, N);
end;

procedure RunBlockingPolicyMicroBench_Aggressive;
var
  oldP: IBackoffPolicy;
begin
  oldP := GetDefaultBackoff;
  try
    SetDefaultBackoff(GetAggressiveBackoff);
    CurrentBackoffLabel := 'Aggressive';
    RunBlockingPolicyMicroBench;
    RunBlockingPolicyMicroBench_MultiModels;
  finally
    SetDefaultBackoff(oldP);
    CurrentBackoffLabel := 'Default';
  end;
end;

procedure RunBlockingPolicyMicroBench_MultiModels_Aggressive;
begin
  RunBlockingPolicyMicroBench_Aggressive;
end;


end.


program example_mpmc_bench;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}
{$DEFINE FAFAFA_CORE_IFACE_FACTORIES}

uses
  SysUtils, DateUtils, Math,
  fafafa.core.bench.util,
  fafafa.core.lockfree.backoff,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.michaelScottQueue,
  fafafa.core.lockfree.mpmcQueue;

type
  TWaitProc = procedure(var fc: Integer);

procedure WaitBackoff(var fc: Integer); inline;
begin
  BackoffStep(fc);
end;

procedure WaitSpin(var fc: Integer); inline;
begin
  Inc(fc);
end;

procedure BenchOne_MPMC(const Name: string; Q: specialize TPreAllocMPMCQueue<Integer>;
  N, Batch: Integer; const Wait: TWaitProc; const Backoff, WaitPolicy: string; Cap: Integer);
var
  i, v, repIdx, repeats: Integer;
  t0, t1: TDateTime;
  durMs: Int64;
  sumMs, sumNsPerOp, sumSqMs, sumSqNsPerOp: Double;
  avgMs, stdMs, avgNs, stdNs: Double;
  row: TBenchRow;
  fc: Integer;
  inBuf, outBuf: array of Integer;
  step: Integer;
  repDur: array of Double;

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
  repeats := GetBenchRepeat;
  sumMs := 0; sumNsPerOp := 0; sumSqMs := 0; sumSqNsPerOp := 0;
  if Batch < 1 then Batch := 1;
  // warmup
  for repIdx := 1 to GetBenchWarmup do
  begin
    t0 := Now; t1 := Now; // no-op to keep codepath simple
  end;
  SetLength(inBuf, Batch);
  SetLength(outBuf, Batch);
  SetLength(repDur, repeats);
  for repIdx := 1 to repeats do
  begin
    t0 := Now;
    if Batch = 1 then
    begin
      for i := 1 to N do
      begin
        fc := 0; while not Q.Enqueue(i) do Wait(fc);
        fc := 0; while not Q.Dequeue(v) do Wait(fc);
      end;
    end
    else
    begin
      step := 1;
      i := 1;
      while i <= N do
      begin
        if i + Batch - 1 > N then step := N - i + 1 else step := Batch;
        // enqueue many
        while Q.EnqueueMany(inBuf) < step do begin fc := 0; Wait(fc); end;
        // dequeue many
        while Q.DequeueMany(outBuf) < step do begin fc := 0; Wait(fc); end;
        Inc(i, step);
      end;
    end;
    t1 := Now;
    durMs := MilliSecondsBetween(t1, t0);
    if durMs = 0 then durMs := 1;
    repDur[repIdx-1] := durMs;
    sumMs += durMs;
    sumNsPerOp += (durMs * 1000000.0) / N;
    sumSqMs += durMs * durMs; sumSqNsPerOp += ((durMs * 1000000.0) / N) * ((durMs * 1000000.0) / N);
  end;
  avgMs := sumMs / repeats;
  avgNs := sumNsPerOp / repeats;
  stdMs := Sqrt(Max(0.0, (sumSqMs / repeats) - (avgMs * avgMs)));
  stdNs := Sqrt(Max(0.0, (sumSqNsPerOp / repeats) - (avgNs * avgNs)));
  WriteLn(Format('%-18s %10d %8d %10.2f %10.0f', [Name, N, Round(avgMs), N / Max(1.0, avgMs), avgNs]));
  row.Name := Name; row.Model := 'MPMC';
  row.Warmup := GetBenchWarmup; row.Repeats := repeats; row.P50Ms := PercentileOf(repDur, 50); row.P90Ms := PercentileOf(repDur, 90); row.P95Ms := PercentileOf(repDur, 95); row.P99Ms := PercentileOf(repDur, 99);
  row.N := N; row.Ms := Round(avgMs); row.MsStd := stdMs;
  row.OpsPerMs := N / Max(1.0, avgMs); row.NsPerOp := avgNs; row.NsPerOpStd := stdNs;
  row.Backoff := Backoff; row.WaitPolicy := WaitPolicy; row.Host := GetBenchHost; row.RunId := GetBenchRunId; row.Commit := GetBenchCommit;
  row.Cap := Cap; row.Batch := Batch;
  AppendCsv(row);
end;

procedure BenchOne_SPSC(const Name: string; Q: specialize TSPSCQueue<Integer>;
  N: Integer; const Wait: TWaitProc; const Backoff, WaitPolicy: string; Cap: Integer);
var
  i, v, repIdx, repeats: Integer;
  t0, t1: TDateTime;
  durMs: Int64;
  sumMs, sumNsPerOp, sumSqMs, sumSqNsPerOp: Double;
  avgMs, stdMs, avgNs, stdNs: Double;
  row: TBenchRow;
  fc: Integer;
  repDur: array of Double;

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
  repeats := GetBenchRepeat;
  sumMs := 0; sumNsPerOp := 0; sumSqMs := 0; sumSqNsPerOp := 0;
  SetLength(repDur, repeats);
  for repIdx := 1 to repeats do
  begin
    t0 := Now;
    for i := 1 to N do
    begin
      fc := 0; while not Q.Enqueue(i) do Wait(fc);
      fc := 0; while not Q.Dequeue(v) do Wait(fc);
    end;
    t1 := Now;
    durMs := MilliSecondsBetween(t1, t0);
    if durMs = 0 then durMs := 1;
    repDur[repIdx-1] := durMs;
    sumMs += durMs;
    sumNsPerOp += (durMs * 1000000.0) / N;
    sumSqMs += durMs * durMs; sumSqNsPerOp += ((durMs * 1000000.0) / N) * ((durMs * 1000000.0) / N);
  end;
  avgMs := sumMs / repeats;
  avgNs := sumNsPerOp / repeats;
  stdMs := Sqrt(Max(0.0, (sumSqMs / repeats) - (avgMs * avgMs)));
  stdNs := Sqrt(Max(0.0, (sumSqNsPerOp / repeats) - (avgNs * avgNs)));
  WriteLn(Format('%-18s %10d %8d %10.2f %10.0f', [Name, N, Round(avgMs), N / Max(1.0, avgMs), avgNs]));
  row.Name := Name; row.Model := 'SPSC';
  row.Backoff := Backoff; row.WaitPolicy := WaitPolicy; row.Host := GetBenchHost; row.RunId := GetBenchRunId; row.Commit := GetBenchCommit; row.Cap := Cap; row.Batch := 1;
  row.Warmup := GetBenchWarmup; row.Repeats := repeats; row.P50Ms := PercentileOf(repDur, 50); row.P90Ms := PercentileOf(repDur, 90); row.P95Ms := PercentileOf(repDur, 95); row.P99Ms := PercentileOf(repDur, 99);
  row.N := N; row.Ms := Round(avgMs); row.MsStd := stdMs;
  row.OpsPerMs := N / Max(1.0, avgMs); row.NsPerOp := avgNs; row.NsPerOpStd := stdNs;
  AppendCsv(row);
end;

procedure BenchOne_MPSC(const Name: string; Q: specialize TMichaelScottQueue<Integer>;
  N: Integer; const Wait: TWaitProc; const Backoff, WaitPolicy: string);
var
  i, v, repIdx, repeats: Integer;
  t0, t1: TDateTime;
  durMs: Int64;
  sumMs, sumNsPerOp, sumSqMs, sumSqNsPerOp: Double;
  avgMs, stdMs, avgNs, stdNs: Double;
  row: TBenchRow;
  fc: Integer;
  repDur: array of Double;

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
  repeats := GetBenchRepeat;
  sumMs := 0; sumNsPerOp := 0; sumSqMs := 0; sumSqNsPerOp := 0;
  SetLength(repDur, repeats);
  for repIdx := 1 to repeats do
  begin
    t0 := Now;
    for i := 1 to N do
    begin
      Q.Enqueue(i);
      fc := 0; while not Q.Dequeue(v) do Wait(fc);
    end;
    t1 := Now;
    durMs := MilliSecondsBetween(t1, t0);
    if durMs = 0 then durMs := 1;
    repDur[repIdx-1] := durMs;
    sumMs += durMs;
    sumNsPerOp += (durMs * 1000000.0) / N;
    sumSqMs += durMs * durMs; sumSqNsPerOp += ((durMs * 1000000.0) / N) * ((durMs * 1000000.0) / N);
  end;
  avgMs := sumMs / repeats;
  avgNs := sumNsPerOp / repeats;
  stdMs := Sqrt(Max(0.0, (sumSqMs / repeats) - (avgMs * avgMs)));
  stdNs := Sqrt(Max(0.0, (sumSqNsPerOp / repeats) - (avgNs * avgNs)));
  WriteLn(Format('%-18s %10d %8d %10.2f %10.0f', [Name, N, Round(avgMs), N / Max(1.0, avgMs), avgNs]));
  row.Name := Name; row.Model := 'MPSC'; row.Backoff := Backoff; row.WaitPolicy := WaitPolicy; row.Host := GetBenchHost; row.RunId := GetBenchRunId; row.Commit := GetBenchCommit; row.Cap := 0; row.Batch := 1;
  row.Warmup := GetBenchWarmup; row.Repeats := repeats; row.P50Ms := PercentileOf(repDur, 50); row.P90Ms := PercentileOf(repDur, 90); row.P95Ms := PercentileOf(repDur, 95); row.P99Ms := PercentileOf(repDur, 99);
  row.N := N; row.Ms := Round(avgMs); row.MsStd := stdMs;
  row.OpsPerMs := N / Max(1.0, avgMs); row.NsPerOp := avgNs; row.NsPerOpStd := stdNs;
  AppendCsv(row);
end;

procedure Run;
var
  N: Integer;
  caps: array[0..2] of Integer;
  batches: array[0..2] of Integer;
  capIdx, batchIdx: Integer;
  cap, batch: Integer;
  policyName: String;
  MPMC: specialize TPreAllocMPMCQueue<Integer>;
  SPSC: specialize TSPSCQueue<Integer>;
  MPSC: specialize TMichaelScottQueue<Integer>;
begin
  N := GetBenchN;
  caps[0] := 256; caps[1] := 1024; caps[2] := 4096;
  batches[0] := 1; batches[1] := 4; batches[2] := 32;
  PrintHeader('--- Example: Backoff Default vs Aggressive (SPSC/MPSC/MPMC) + Capacity/Batch ---', N, GetBenchRepeat);

  // policy loop: 0 = Default, 1 = Aggressive
  // Default backoff + bpSleep
  SetDefaultBackoff(nil); policyName := 'Default/bpSleep';
  for capIdx := 0 to High(caps) do
  begin
    SPSC := specialize TSPSCQueue<Integer>.Create(caps[capIdx]);
    BenchOne_SPSC('SPSC/'+policyName+'/cap'+IntToStr(caps[capIdx]), SPSC, N, @WaitBackoff, 'Default', 'bpSleep', caps[capIdx]);
    SPSC.Free;
  end;
  MPSC := specialize TMichaelScottQueue<Integer>.Create;
  BenchOne_MPSC('MPSC/'+policyName, MPSC, N, @WaitBackoff, 'Default', 'bpSleep');
  MPSC.Free;
  for capIdx := 0 to High(caps) do
  begin
    for batchIdx := 0 to High(batches) do
    begin
      cap := caps[capIdx]; batch := batches[batchIdx];
      MPMC := specialize TPreAllocMPMCQueue<Integer>.Create(cap);
      BenchOne_MPMC('MPMC/'+policyName+'/cap'+IntToStr(cap)+'/batch'+IntToStr(batch),
        MPMC, N, batch, @WaitBackoff, 'Default', 'bpSleep', cap);
      MPMC.Free;
    end;
  end;

  // Aggressive backoff + bpSleep
  SetDefaultBackoff(GetAggressiveBackoff); policyName := 'Aggressive/bpSleep';
  for capIdx := 0 to High(caps) do
  begin
    SPSC := specialize TSPSCQueue<Integer>.Create(caps[capIdx]);
    BenchOne_SPSC('SPSC/'+policyName+'/cap'+IntToStr(caps[capIdx]), SPSC, N, @WaitBackoff, 'Aggressive', 'bpSleep', caps[capIdx]);
    SPSC.Free;
  end;
  MPSC := specialize TMichaelScottQueue<Integer>.Create;
  BenchOne_MPSC('MPSC/'+policyName, MPSC, N, @WaitBackoff, 'Aggressive', 'bpSleep');
  MPSC.Free;
  for capIdx := 0 to High(caps) do
  begin
    for batchIdx := 0 to High(batches) do
    begin
      cap := caps[capIdx]; batch := batches[batchIdx];
      MPMC := specialize TPreAllocMPMCQueue<Integer>.Create(cap);
      BenchOne_MPMC('MPMC/'+policyName+'/cap'+IntToStr(cap)+'/batch'+IntToStr(batch),
        MPMC, N, batch, @WaitBackoff, 'Aggressive', 'bpSleep', cap);
      MPMC.Free;
    end;
  end;

  // Default backoff + bpSpin（纯自旋对比）
  SetDefaultBackoff(nil); policyName := 'Default/bpSpin';
  for capIdx := 0 to High(caps) do
  begin
    SPSC := specialize TSPSCQueue<Integer>.Create(caps[capIdx]);
    BenchOne_SPSC('SPSC/'+policyName+'/cap'+IntToStr(caps[capIdx]), SPSC, N, @WaitSpin, 'Default', 'bpSpin', caps[capIdx]);
    SPSC.Free;
  end;
  MPSC := specialize TMichaelScottQueue<Integer>.Create;
  BenchOne_MPSC('MPSC/'+policyName, MPSC, N, @WaitSpin, 'Default', 'bpSpin');
  MPSC.Free;
  for capIdx := 0 to High(caps) do
  begin
    for batchIdx := 0 to High(batches) do
    begin
      cap := caps[capIdx]; batch := batches[batchIdx];
      MPMC := specialize TPreAllocMPMCQueue<Integer>.Create(cap);
      BenchOne_MPMC('MPMC/'+policyName+'/cap'+IntToStr(cap)+'/batch'+IntToStr(batch),
        MPMC, N, batch, @WaitSpin, 'Default', 'bpSpin', cap);
      MPMC.Free;
    end;
  end;

  // Aggressive backoff + bpSpin
  SetDefaultBackoff(GetAggressiveBackoff); policyName := 'Aggressive/bpSpin';
  for capIdx := 0 to High(caps) do
  begin
    SPSC := specialize TSPSCQueue<Integer>.Create(caps[capIdx]);
    BenchOne_SPSC('SPSC/'+policyName+'/cap'+IntToStr(caps[capIdx]), SPSC, N, @WaitSpin, 'Aggressive', 'bpSpin', caps[capIdx]);
    SPSC.Free;
  end;
  MPSC := specialize TMichaelScottQueue<Integer>.Create;
  BenchOne_MPSC('MPSC/'+policyName, MPSC, N, @WaitSpin, 'Aggressive', 'bpSpin');
  MPSC.Free;
  for capIdx := 0 to High(caps) do
  begin
    for batchIdx := 0 to High(batches) do
    begin
      cap := caps[capIdx]; batch := batches[batchIdx];
      MPMC := specialize TPreAllocMPMCQueue<Integer>.Create(cap);
      BenchOne_MPMC('MPMC/'+policyName+'/cap'+IntToStr(cap)+'/batch'+IntToStr(batch),
        MPMC, N, batch, @WaitSpin, 'Aggressive', 'bpSpin', cap);
      MPMC.Free;
    end;
  end;

  // Restore default (safety)
  SetDefaultBackoff(nil);
end;

begin
  Run;
end.


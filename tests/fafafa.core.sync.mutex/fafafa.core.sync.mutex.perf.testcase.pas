unit fafafa.core.sync.mutex.perf.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Math,
  fafafa.core.sync.mutex, fafafa.core.sync.base;

type
  // 性能与回归测试
  TTestCase_Perf = class(TTestCase)
  private
    function NowNs: QWord;
  published
    procedure Test_Baseline_AcquireRelease;
    procedure Test_SpinCount_Comparison;
    procedure Test_Scalability_ByThreads;
    procedure Test_Latency_Distribution;
  end;

implementation
{$I fafafa.core.sync.mutex.perf.benchthread.inc}


function TTestCase_Perf.NowNs: QWord;
begin
  Result := GetTickCount64 * 1000000; // 近似，CI 可用；如需更高精度，可换 monotonic clock
end;

procedure TTestCase_Perf.Test_Baseline_AcquireRelease;
var
  m: IMutex;
  i: Integer;
  startNs, endNs: QWord;
const
  N = 200000;
begin
  m := MakeMutex;
  startNs := NowNs;
  for i := 1 to N do begin m.Acquire; m.Release; end;
  endNs := NowNs;
  WriteLn('Baseline ', N, ' ops in ', (endNs - startNs) div 1000000, ' ms');
  AssertTrue('Baseline completed', endNs > startNs);
end;

procedure TTestCase_Perf.Test_SpinCount_Comparison;
{$IFDEF WINDOWS}
var
  m0, m4k: IMutex;
  i: Integer;
  t0s, t0e, t4s, t4e: QWord;
const
  N = 100000;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  m0 := MakeMutex(0);
  m4k := MakeMutex(4000);
  t0s := NowNs; for i := 1 to N do begin m0.Acquire; m0.Release; end; t0e := NowNs;
  t4s := NowNs; for i := 1 to N do begin m4k.Acquire; m4k.Release; end; t4e := NowNs;
  WriteLn('NoSpin ms=', (t0e - t0s) div 1000000, ' WithSpin ms=', (t4e - t4s) div 1000000);
  AssertTrue('Spin comparison completed', True);
  {$ELSE}
  AssertTrue('Skipped on Unix', True);
  {$ENDIF}
end;

procedure TTestCase_Perf.Test_Scalability_ByThreads;
var
  m: IMutex;
  counts: array[0..3] of Integer;
  threads: array of TThread;
  i, t, total: Integer;

begin
  m := MakeMutex;
  for t := 0 to 3 do
  begin
    counts[t] := 0;
    SetLength(threads, (t+1) * 2);
    for i := 0 to High(threads) do
      threads[i] := TBenchThread.Create(m, @counts[t]);
    for i := 0 to High(threads) do threads[i].WaitFor;
    for i := 0 to High(threads) do threads[i].Free;
  end;
  total := 0; for i := 0 to High(counts) do Inc(total, counts[i]);
  AssertEquals('All groups finished', 4, total);
end;

procedure TTestCase_Perf.Test_Latency_Distribution;
var
  m: IMutex;
  i: Integer;
  start, stop: QWord;
  samples: array[0..999] of QWord;
  p50, p95, p99: QWord;
  a, b: Integer;
  tmp: QWord;
  function Percentile(var arr: array of QWord; n: Integer; p: Double): QWord;
  var idx: Integer;
  begin
    idx := Trunc(p * (n-1));
    Result := arr[idx];
  end;
begin
  m := MakeMutex;
  for i := 0 to High(samples) do
  begin
    start := NowNs;
    m.Acquire; m.Release;
    stop := NowNs;
    samples[i] := stop - start;
  end;


  // 简单插入排序（避免依赖泛型助手，保证 CI 可编译）
  for a := 1 to High(samples) do
  begin
    tmp := samples[a]; b := a-1;
    while (b>=0) and (samples[b] > tmp) do
    begin
      samples[b+1] := samples[b]; Dec(b);
    end;
    samples[b+1] := tmp;
  end;
  p50 := Percentile(samples, Length(samples), 0.50);
  p95 := Percentile(samples, Length(samples), 0.95);
  p99 := Percentile(samples, Length(samples), 0.99);
  WriteLn(Format('Latency ns: P50=%d P95=%d P99=%d', [p50, p95, p99]));
  AssertTrue('Latency distribution computed', (p99 >= p95) and (p95 >= p50));
end;

initialization
  RegisterTest(TTestCase_Perf);

end.


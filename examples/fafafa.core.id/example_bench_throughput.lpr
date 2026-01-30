{$CODEPAGE UTF8}
program example_bench_throughput;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  SysUtils, DateUtils, Math,
  fafafa.core.id, fafafa.core.id.ulid, fafafa.core.id.ksuid, fafafa.core.id.snowflake,
  fafafa.core.time;

function NowMs: Int64; inline;
begin
  Result := Int64(DateTimeToUnix(Now)) * 1000 + MilliSecondOf(Now);
end;

function GetArgValue(const Key: string; const Default: Int64): Int64;
var i: Integer; S, Pfx: string;
begin
  Pfx := Key + '=';
  for i := 1 to ParamCount do
  begin
    S := ParamStr(i);
    if (Length(S) >= Length(Pfx)) and (Copy(S,1,Length(Pfx))=Pfx) then
    begin
      try Exit(StrToInt64(Copy(S, Length(Pfx)+1, MaxInt))); except Exit(Default); end;
    end;
  end;
  Result := Default;
end;

procedure ComputeStats(const A: array of Double; out Mean, Median, StdDev: Double);
var tmp: array of Double; i: Integer; sum, sum2: Double; n: Integer;
begin
  n := Length(A);
  if n=0 then begin Mean:=0; Median:=0; StdDev:=0; Exit; end;
  sum := 0; sum2 := 0;
  for i := 0 to n-1 do begin sum += A[i]; sum2 += A[i]*A[i]; end;
  Mean := sum / n;
  SetLength(tmp, n);
  for i := 0 to n-1 do tmp[i] := A[i];
  TArray.Sort<Double>(tmp);
  if (n and 1)=1 then Median := tmp[n div 2]
  else Median := 0.5*(tmp[n div 2 - 1] + tmp[n div 2]);
  if n>1 then StdDev := Sqrt(Max(0.0, (sum2/n) - Mean*Mean)) else StdDev := 0.0;
end;

function RunOnce(const DurationMs: Int64; const ProcGen: TProc): Double;
var t0, t1: Int64; n: QWord;
begin
  n := 0; t0 := NowMs; t1 := t0;
  while (t1 - t0) < DurationMs do
  begin
    ProcGen();
    Inc(n);
    if (n and 1023) = 0 then t1 := NowMs;
  end;
  if (t1 - t0) <= 0 then Exit(0);
  Result := (n * 1000.0) / (t1 - t0);
end;

procedure BenchMulti(const Name: string; const DurationMs: Int64; RepeatN: Integer; const ProcGen: TProc);
var i: Integer; samples: array of Double; mean, med, sd: Double;
begin
  if RepeatN < 1 then RepeatN := 1;
  SetLength(samples, RepeatN);
  for i := 0 to RepeatN-1 do
    samples[i] := RunOnce(DurationMs, ProcGen);
  ComputeStats(samples, mean, med, sd);
  WriteLn(Format('%-12s mean=%10.0f med=%10.0f sd=%8.0f (ops/sec)', [Name, mean, med, sd]));
end;

var
  g: ISnowflake;
  DummyStr: string;
  DummyId: TSnowflakeID;
  secs: Int64;
  repeatN: Int64;
  durMs: Int64;
begin
  secs := GetArgValue('--secs', 1);
  repeatN := GetArgValue('--repeat', 3);
  if secs < 1 then secs := 1;
  if repeatN < 1 then repeatN := 1;
  durMs := secs * 1000;

  WriteLn(Format('ID Generators Throughput: secs=%d repeat=%d', [secs, repeatN]));

  BenchMulti('UUID v4', durMs, repeatN,
    procedure
    begin
      DummyStr := UuidV4;
    end);

  BenchMulti('UUID v7', durMs, repeatN,
    procedure
    begin
      DummyStr := UuidV7;
    end);

  BenchMulti('ULID', durMs, repeatN,
    procedure
    begin
      DummyStr := Ulid;
    end);

  BenchMulti('KSUID', durMs, repeatN,
    procedure
    begin
      DummyStr := Ksuid;
    end);

  g := CreateSnowflake(1);
  BenchMulti('Snowflake', durMs, repeatN,
    procedure
    begin
      DummyId := g.NextID;
    end);
end.


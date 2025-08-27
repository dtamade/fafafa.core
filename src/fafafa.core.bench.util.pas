unit fafafa.core.bench.util;
{$mode objfpc}{$H+}

interface
uses SysUtils, DateUtils, fafafa.core.env;

type
  TBenchRow = record
    // Identification
    Name: String;      // human-friendly label
    Model: String;     // SPSC/MPSC/MPMC
    Backoff: String;   // Default/Aggressive
    WaitPolicy: String;// bpSleep/bpSpin
    Cap: Integer;      // capacity if applicable (0 for N/A)
    Batch: Integer;    // batch size if applicable (0/1 for single)
    // Metrics
    N: Integer;
    Ms: Int64;        // average ms
    MsStd: Double;    // std deviation of ms
    OpsPerMs: Double; // average
    NsPerOp: Double;  // average
    NsPerOpStd: Double; // std deviation
    // Meta
    Warmup: Integer;   // number of warmup repeats (not recorded in averages)
    Repeats: Integer;  // number of measured repeats
    // Distribution (optional)
    P50Ms: Double;     // 50th percentile of per-repeat ms
    P90Ms: Double;     // 90th percentile of per-repeat ms
    P95Ms: Double;     // 95th percentile of per-repeat ms
    P99Ms: Double;     // 99th percentile of per-repeat ms
    // Provenance (optional)
    Host: String;      // host machine identifier (FAFAFA_BENCH_HOST/COMPUTERNAME/HOSTNAME)
    RunId: String;     // caller-provided run identifier (FAFAFA_BENCH_RUNID)
    Commit: String;    // git commit (GIT_COMMIT)
  end;

function GetBenchN: Integer;
function GetBenchRepeat: Integer;
function GetBenchWarmup: Integer;
function GetBenchOut: String;
function GetBenchRunId: String;
function GetBenchCommit: String;
function GetBenchHost: String;
procedure PrintHeader(const Title: String; N, R: Integer);
procedure AppendCsv(const Row: TBenchRow);

implementation

function GetBenchN: Integer;
var s: String;
begin
  s := env_get('FAFAFA_BENCH_N');
  if s <> '' then Result := StrToIntDef(s, 100000)
  else Result := 100000;
end;

function GetBenchRepeat: Integer;
var s: String;
begin
  s := env_get('FAFAFA_BENCH_REPEAT');
  if s <> '' then Result := StrToIntDef(s, 5)
  else Result := 5;
end;

function GetBenchWarmup: Integer;
var s: String;
begin
  s := env_get('FAFAFA_BENCH_WARMUP');
  if s <> '' then Result := StrToIntDef(s, 1)
  else Result := 1;
end;

function GetBenchOut: String;
begin
  Result := env_get('FAFAFA_BENCH_OUT');
  if Result = '' then Result := 'bench_example.csv';
end;

function GetBenchRunId: String;
begin
  Result := env_get('FAFAFA_BENCH_RUNID');
end;

function GetBenchCommit: String;
begin
  Result := env_get('GIT_COMMIT');
end;

function GetBenchHost: String;
var h: String;
begin
  h := env_get('FAFAFA_BENCH_HOST');
  if h = '' then h := env_get('COMPUTERNAME');
  if h = '' then h := env_get('HOSTNAME');
  Result := h;
end;

procedure PrintHeader(const Title: String; N, R: Integer);
begin
  WriteLn(Format('%s (N=%d, R=%d)', [Title, N, R]));
  WriteLn(Format('%-18s %10s %8s %10s %10s', ['name','ops','ms','ops/ms','ns/op']));
end;

procedure AppendCsv(const Row: TBenchRow);
var
  fn: String;
  f: TextFile;
  newFile: Boolean;
  host, runId, commit: String;
begin
  fn := GetBenchOut;
  newFile := not FileExists(fn);
  AssignFile(f, fn);
  if newFile then Rewrite(f) else Append(f);
  if newFile then
    WriteLn(f, 'name,model,backoff,wait_policy,cap,batch,N,ms_avg,ms_std,ops_per_ms,ns_per_op_avg,ns_per_op_std,warmup,repeats,p50_ms,p90_ms,p95_ms,p99_ms,host,run_id,commit,timestamp');
  host := Row.Host; if host = '' then host := GetBenchHost;
  runId := Row.RunId; if runId = '' then runId := GetBenchRunId;
  commit := Row.Commit; if commit = '' then commit := GetBenchCommit;
  WriteLn(f, Format('"%s",%s,%s,%s,%d,%d,%d,%d,%.2f,%.2f,%.0f,%.0f,%d,%d,%.2f,%.2f,%.2f,%.2f,%s,%s,%s,%s',
    [Row.Name, Row.Model, Row.Backoff, Row.WaitPolicy, Row.Cap, Row.Batch,
     Row.N, Row.Ms, Row.MsStd, Row.OpsPerMs, Row.NsPerOp, Row.NsPerOpStd,
     Row.Warmup, Row.Repeats, Row.P50Ms, Row.P90Ms, Row.P95Ms, Row.P99Ms,
     host, runId, commit,
     FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now)]));
  CloseFile(f);
end;

end.


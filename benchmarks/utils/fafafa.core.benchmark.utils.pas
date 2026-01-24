unit fafafa.core.benchmark.utils;
{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils
  {$IFDEF WINDOWS}
  , Windows
  {$ENDIF};

type
  { 高精度时间类型 }
  THighResTime = record
    {$IFDEF WINDOWS}
    Value: Int64;
    {$ELSE}
    Sec: Int64;
    NSec: Int64;
    {$ENDIF}
  end;

  { 基准测试结果 }
  TBenchmarkResult = record
    TestName: string;
    ThreadCount: Integer;
    Operations: Int64;
    ElapsedNs: Int64;
    OpsPerSecond: Double;
    AvgLatencyNs: Double;
  end;

  { 基准测试结果数组 }
  TBenchmarkResults = array of TBenchmarkResult;

{ 高精度计时器函数 }
function GetHighResTime: THighResTime;
function CalcElapsedNs(const AStart, AEnd: THighResTime): Int64;

{ 结果格式化输出 }
procedure PrintHeader(const ATitle: string);
procedure PrintResult(const AResult: TBenchmarkResult);
procedure PrintFooter;

{ CSV 报告生成 }
procedure SaveResultsToCSV(const AResults: TBenchmarkResults; const AFileName: string);

{ JSON 报告生成 }
procedure SaveResultsToJSON(const AResults: TBenchmarkResults; const AFileName: string);

implementation

{$IFNDEF WINDOWS}
const
  CLOCK_MONOTONIC = 1;

type
  TTimeSpec = record
    tv_sec: Int64;
    tv_nsec: Int64;
  end;
  PTimeSpec = ^TTimeSpec;

function clock_gettime(clk_id: Integer; tp: PTimeSpec): Integer; cdecl; external 'c';
{$ENDIF}

{$IFDEF WINDOWS}
var
  Frequency: Int64;
{$ENDIF}

function GetHighResTime: THighResTime;
{$IFNDEF WINDOWS}
var
  LTimeSpec: TTimeSpec;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(Result.Value);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @LTimeSpec);
  Result.Sec := LTimeSpec.tv_sec;
  Result.NSec := LTimeSpec.tv_nsec;
  {$ENDIF}
end;

function CalcElapsedNs(const AStart, AEnd: THighResTime): Int64;
begin
  {$IFDEF WINDOWS}
  Result := ((AEnd.Value - AStart.Value) * 1000000000) div Frequency;
  {$ELSE}
  Result := (AEnd.Sec - AStart.Sec) * 1000000000 + (AEnd.NSec - AStart.NSec);
  {$ENDIF}
end;

procedure PrintHeader(const ATitle: string);
begin
  WriteLn('='.PadRight(120, '='));
  WriteLn(ATitle);
  WriteLn('='.PadRight(120, '='));
  WriteLn;
end;

procedure PrintResult(const AResult: TBenchmarkResult);
begin
  WriteLn(Format('%-40s %2d threads: %12d ops in %8.3f ms | %12.0f ops/sec | %8.2f ns/op',
    [AResult.TestName, AResult.ThreadCount, AResult.Operations,
     AResult.ElapsedNs / 1000000.0, AResult.OpsPerSecond, AResult.AvgLatencyNs]));
end;

procedure PrintFooter;
begin
  WriteLn;
  WriteLn('='.PadRight(120, '='));
  WriteLn('Benchmark Complete');
  WriteLn('='.PadRight(120, '='));
end;

procedure SaveResultsToCSV(const AResults: TBenchmarkResults; const AFileName: string);
var
  LFile: TextFile;
  i: Integer;
begin
  AssignFile(LFile, AFileName);
  try
    Rewrite(LFile);
    
    // Write header
    WriteLn(LFile, 'TestName,ThreadCount,Operations,ElapsedMs,OpsPerSecond,AvgLatencyNs');
    
    // Write data
    for i := 0 to High(AResults) do
    begin
      WriteLn(LFile, Format('%s,%d,%d,%.3f,%.0f,%.2f',
        [AResults[i].TestName,
         AResults[i].ThreadCount,
         AResults[i].Operations,
         AResults[i].ElapsedNs / 1000000.0,
         AResults[i].OpsPerSecond,
         AResults[i].AvgLatencyNs]));
    end;
    
    CloseFile(LFile);
  except
    on E: Exception do
      WriteLn('Error saving CSV: ', E.Message);
  end;
end;

procedure SaveResultsToJSON(const AResults: TBenchmarkResults; const AFileName: string);
var
  LFile: TextFile;
  i: Integer;
begin
  AssignFile(LFile, AFileName);
  try
    Rewrite(LFile);
    
    WriteLn(LFile, '{');
    WriteLn(LFile, '  "benchmarks": [');
    
    for i := 0 to High(AResults) do
    begin
      WriteLn(LFile, '    {');
      WriteLn(LFile, Format('      "name": "%s",', [AResults[i].TestName]));
      WriteLn(LFile, Format('      "thread_count": %d,', [AResults[i].ThreadCount]));
      WriteLn(LFile, Format('      "operations": %d,', [AResults[i].Operations]));
      WriteLn(LFile, Format('      "elapsed_ms": %.3f,', [AResults[i].ElapsedNs / 1000000.0]));
      WriteLn(LFile, Format('      "ops_per_second": %.0f,', [AResults[i].OpsPerSecond]));
      WriteLn(LFile, Format('      "avg_latency_ns": %.2f', [AResults[i].AvgLatencyNs]));
      
      if i < High(AResults) then
        WriteLn(LFile, '    },')
      else
        WriteLn(LFile, '    }');
    end;
    
    WriteLn(LFile, '  ]');
    WriteLn(LFile, '}');
    
    CloseFile(LFile);
  except
    on E: Exception do
      WriteLn('Error saving JSON: ', E.Message);
  end;
end;

{$IFDEF WINDOWS}
initialization
  QueryPerformanceFrequency(Frequency);
{$ENDIF}

end.

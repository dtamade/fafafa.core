program bench_riscvv_vs_scalar;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.scalar,
  fafafa.core.simd.riscvv,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.bench;

type
  TBackendBenchResult = record
    Name: string;
    Size: SizeUInt;
    ScalarOpsPerSec: Double;
    RISCVVOpsPerSec: Double;
    Speedup: Double;
  end;

  TBackendBenchResults = array of TBackendBenchResult;

function GetArchName: string;
begin
  {$IF defined(CPUX86_64)}
  Result := 'x86_64';
  {$ELSEIF defined(CPUI386)}
  Result := 'i386';
  {$ELSEIF defined(CPUAARCH64)}
  Result := 'arm64';
  {$ELSEIF defined(CPURISCV64)}
  Result := 'riscv64';
  {$ELSEIF defined(CPURISCV32)}
  Result := 'riscv32';
  {$ELSE}
  Result := 'unknown';
  {$ENDIF}
end;

function FormatOps(const aOps: Double): string;
begin
  if aOps >= 1e9 then
    Result := Format('%.2f G', [aOps / 1e9])
  else if aOps >= 1e6 then
    Result := Format('%.2f M', [aOps / 1e6])
  else if aOps >= 1e3 then
    Result := Format('%.2f K', [aOps / 1e3])
  else
    Result := Format('%.0f  ', [aOps]);
end;

function RunBackendComparison: TBackendBenchResults;
var
  LScalarResults, LRISCVVResults: TBenchResults;
  LIndex: Integer;
begin
  Result := nil;

  if not IsBackendAvailableOnCPU(sbRISCVV) then
  begin
    WriteLn('[SKIP] RISCVV backend is not available on this CPU');
    Exit;
  end;

  WriteLn('=== RISCVV vs Scalar Performance Benchmark ===');
  WriteLn;
  WriteLn('Running Scalar backend tests...');
  SetActiveBackend(sbScalar);
  LScalarResults := RunAllBenchmarks;

  WriteLn('Running RISCVV backend tests...');
  SetActiveBackend(sbRISCVV);
  LRISCVVResults := RunAllBenchmarks;

  SetLength(Result, Length(LScalarResults));
  for LIndex := 0 to High(LScalarResults) do
  begin
    Result[LIndex].Name := LScalarResults[LIndex].Name;
    Result[LIndex].Size := LScalarResults[LIndex].Size;
    Result[LIndex].ScalarOpsPerSec := LScalarResults[LIndex].ActiveOpsPerSec;
    Result[LIndex].RISCVVOpsPerSec := LRISCVVResults[LIndex].ActiveOpsPerSec;
    if Result[LIndex].ScalarOpsPerSec > 0 then
      Result[LIndex].Speedup := Result[LIndex].RISCVVOpsPerSec / Result[LIndex].ScalarOpsPerSec
    else
      Result[LIndex].Speedup := 0;
  end;

  ResetToAutomaticBackend;
end;

procedure PrintResults(const aResults: TBackendBenchResults);
var
  LIndex: Integer;
  LSizeStr: string;
begin
  WriteLn;
  WriteLn('=== RISCVV vs Scalar Performance Comparison ===');
  WriteLn;
  WriteLn('Operation        Size     Scalar ops/s   RISCVV ops/s   Speedup');
  WriteLn('------------------------------------------------------------------');

  for LIndex := 0 to High(aResults) do
  begin
    if aResults[LIndex].Size > 0 then
      LSizeStr := Format('%4d B', [aResults[LIndex].Size])
    else
      LSizeStr := '     -';

    WriteLn(Format('%-15s  %s  %12s  %12s  %6.2fx', [
      aResults[LIndex].Name,
      LSizeStr,
      FormatOps(aResults[LIndex].ScalarOpsPerSec),
      FormatOps(aResults[LIndex].RISCVVOpsPerSec),
      aResults[LIndex].Speedup
    ]));
  end;
  WriteLn('------------------------------------------------------------------');
end;

procedure GenerateMarkdownReport(const aResults: TBackendBenchResults; const aFileName: string);
var
  LFile: TextFile;
  LIndex: Integer;
  LSizeStr: string;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);
  try
    WriteLn(LFile, '# RISCVV vs Scalar Performance Benchmark Report');
    WriteLn(LFile);
    WriteLn(LFile, '**Generated**: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    WriteLn(LFile, '**Platform**: ', GetArchName);
    WriteLn(LFile);
    WriteLn(LFile, '| Operation | Size | Scalar ops/s | RISCVV ops/s | Speedup |');
    WriteLn(LFile, '|-----------|------|--------------|--------------|---------|');
    for LIndex := 0 to High(aResults) do
    begin
      if aResults[LIndex].Size > 0 then
        LSizeStr := Format('%d B', [aResults[LIndex].Size])
      else
        LSizeStr := '-';
      WriteLn(LFile, Format('| %s | %s | %s | %s | %.2fx |', [
        aResults[LIndex].Name,
        LSizeStr,
        FormatOps(aResults[LIndex].ScalarOpsPerSec),
        FormatOps(aResults[LIndex].RISCVVOpsPerSec),
        aResults[LIndex].Speedup
      ]));
    end;
  finally
    CloseFile(LFile);
  end;
  WriteLn('[BENCH] Markdown report generated: ', aFileName);
end;

var
  LResults: TBackendBenchResults;
begin
  WriteLn('RISCVV vs Scalar Performance Benchmark');
  WriteLn('======================================');
  WriteLn;

  LResults := RunBackendComparison;
  if Length(LResults) = 0 then
  begin
    WriteLn('[SKIP] No RISCVV benchmark results produced on this host.');
    Halt(0);
  end;

  PrintResults(LResults);
  GenerateMarkdownReport(LResults, 'RISCVV_vs_Scalar_Benchmark_Report.md');
  WriteLn('[BENCH] Benchmark completed successfully.');
end.


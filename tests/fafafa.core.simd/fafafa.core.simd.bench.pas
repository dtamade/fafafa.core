unit fafafa.core.simd.bench;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.scalar,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.memutils,
  fafafa.core.simd.api;

type
  TBenchResult = record
    Name: string;
    Size: SizeUInt;          // Data size in bytes (0 for vector ops)
    ScalarOpsPerSec: Double;
    ActiveOpsPerSec: Double;
    Speedup: Double;
  end;

  TBenchResults = array of TBenchResult;

// Run all benchmarks, returns results array
function RunAllBenchmarks: TBenchResults;

// Print benchmark results to console
procedure PrintBenchResults(const Results: TBenchResults);

// Individual benchmark categories
function BenchMemOps: TBenchResults;
function BenchVectorOps: TBenchResults;

implementation

const
  // Benchmark parameters
  WARMUP_ITERATIONS = 100;
  MIN_ITERATIONS = 1000;
  TARGET_TIME_MS = 500;  // Target at least 500ms per benchmark
  
  // Data sizes
  MEM_SIZE = 4096;  // 4KB for memory benchmarks

type
  TBenchFunc = function: Int64;

function MeasureOpsPerSec(Func: TBenchFunc; var TotalOps: Int64): Double;
const
  MAX_ITERATIONS = 100000000;
var
  LStartTick, LEndTick: UInt64;
  LIterations, LProbeIterations: Integer;
  LIndex: Integer;
  LElapsedMs: Double;
begin
  for LIndex := 1 to WARMUP_ITERATIONS do
    Func();

  LProbeIterations := MIN_ITERATIONS;
  repeat
    LStartTick := GetTickCount64;
    for LIndex := 1 to LProbeIterations do
      Func();
    LEndTick := GetTickCount64;
    LElapsedMs := LEndTick - LStartTick;
    if (LElapsedMs = 0) and (LProbeIterations < MAX_ITERATIONS) then
      LProbeIterations := LProbeIterations * 10;
  until (LElapsedMs > 0) or (LProbeIterations >= MAX_ITERATIONS);

  if LElapsedMs > 0 then
    LIterations := Trunc(LProbeIterations * TARGET_TIME_MS / LElapsedMs)
  else
    LIterations := LProbeIterations;

  if LIterations < MIN_ITERATIONS then
    LIterations := MIN_ITERATIONS;
  if LIterations > MAX_ITERATIONS then
    LIterations := MAX_ITERATIONS;

  repeat
    LStartTick := GetTickCount64;
    for LIndex := 1 to LIterations do
      Func();
    LEndTick := GetTickCount64;
    LElapsedMs := LEndTick - LStartTick;
    if (LElapsedMs = 0) and (LIterations < MAX_ITERATIONS) then
    begin
      if LIterations > (MAX_ITERATIONS div 10) then
        LIterations := MAX_ITERATIONS
      else
        LIterations := LIterations * 10;
    end;
  until (LElapsedMs > 0) or (LIterations >= MAX_ITERATIONS);

  TotalOps := Int64(LIterations);
  if LElapsedMs > 0 then
    Result := (LIterations * 1000.0) / LElapsedMs
  else
    Result := 0;
end;

// === Memory Operation Benchmarks ===

var
  g_MemBuf1, g_MemBuf2: array[0..MEM_SIZE-1] of Byte;
  g_MemDummy: LongBool;
  g_MemDummyIdx: PtrInt;
  g_MemDummySum: UInt64;
  g_MemDummyCount: SizeUInt;

procedure InitMemBufs;
var i: Integer;
begin
  for i := 0 to MEM_SIZE - 1 do
  begin
    g_MemBuf1[i] := Byte(i mod 256);
    g_MemBuf2[i] := Byte(i mod 256);
  end;
end;

function BenchMemEqual_Scalar: Int64;
begin
  g_MemDummy := MemEqual_Scalar(@g_MemBuf1[0], @g_MemBuf2[0], MEM_SIZE);
  Result := 1;
end;

function BenchMemEqual_Active: Int64;
begin
  g_MemDummy := MemEqual(@g_MemBuf1[0], @g_MemBuf2[0], MEM_SIZE);
  Result := 1;
end;

function BenchMemFindByte_Scalar: Int64;
begin
  g_MemDummyIdx := MemFindByte_Scalar(@g_MemBuf1[0], MEM_SIZE, 255);
  Result := 1;
end;

function BenchMemFindByte_Active: Int64;
begin
  g_MemDummyIdx := MemFindByte(@g_MemBuf1[0], MEM_SIZE, 255);
  Result := 1;
end;

function BenchSumBytes_Scalar: Int64;
begin
  g_MemDummySum := SumBytes_Scalar(@g_MemBuf1[0], MEM_SIZE);
  Result := 1;
end;

function BenchSumBytes_Active: Int64;
begin
  g_MemDummySum := SumBytes(@g_MemBuf1[0], MEM_SIZE);
  Result := 1;
end;

function BenchCountByte_Scalar: Int64;
begin
  g_MemDummyCount := CountByte_Scalar(@g_MemBuf1[0], MEM_SIZE, $AA);
  Result := 1;
end;

function BenchCountByte_Active: Int64;
begin
  g_MemDummyCount := CountByte(@g_MemBuf1[0], MEM_SIZE, $AA);
  Result := 1;
end;

function BenchBitsetPopCount_Scalar: Int64;
begin
  g_MemDummyCount := BitsetPopCount_Scalar(@g_MemBuf1[0], MEM_SIZE);
  Result := 1;
end;

function BenchBitsetPopCount_Active: Int64;
begin
  g_MemDummyCount := BitsetPopCount(@g_MemBuf1[0], MEM_SIZE);
  Result := 1;
end;

function BenchMemOps: TBenchResults;
var
  OpsScalar, OpsActive: Double;
  TotalOps: Int64;
begin
  InitMemBufs;
  SetLength(Result, 5);
  
  // MemEqual
  OpsScalar := MeasureOpsPerSec(@BenchMemEqual_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchMemEqual_Active, TotalOps);
  Result[0].Name := 'MemEqual';
  Result[0].Size := MEM_SIZE;
  Result[0].ScalarOpsPerSec := OpsScalar;
  Result[0].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[0].Speedup := OpsActive / OpsScalar else Result[0].Speedup := 0;
  
  // MemFindByte
  OpsScalar := MeasureOpsPerSec(@BenchMemFindByte_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchMemFindByte_Active, TotalOps);
  Result[1].Name := 'MemFindByte';
  Result[1].Size := MEM_SIZE;
  Result[1].ScalarOpsPerSec := OpsScalar;
  Result[1].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[1].Speedup := OpsActive / OpsScalar else Result[1].Speedup := 0;
  
  // SumBytes
  OpsScalar := MeasureOpsPerSec(@BenchSumBytes_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchSumBytes_Active, TotalOps);
  Result[2].Name := 'SumBytes';
  Result[2].Size := MEM_SIZE;
  Result[2].ScalarOpsPerSec := OpsScalar;
  Result[2].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[2].Speedup := OpsActive / OpsScalar else Result[2].Speedup := 0;
  
  // CountByte
  OpsScalar := MeasureOpsPerSec(@BenchCountByte_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchCountByte_Active, TotalOps);
  Result[3].Name := 'CountByte';
  Result[3].Size := MEM_SIZE;
  Result[3].ScalarOpsPerSec := OpsScalar;
  Result[3].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[3].Speedup := OpsActive / OpsScalar else Result[3].Speedup := 0;
  
  // BitsetPopCount
  OpsScalar := MeasureOpsPerSec(@BenchBitsetPopCount_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchBitsetPopCount_Active, TotalOps);
  Result[4].Name := 'BitsetPopCount';
  Result[4].Size := MEM_SIZE;
  Result[4].ScalarOpsPerSec := OpsScalar;
  Result[4].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[4].Speedup := OpsActive / OpsScalar else Result[4].Speedup := 0;
  
  // Suppress unused warnings
  if g_MemDummy then;
  if g_MemDummyIdx > 0 then;
  if g_MemDummySum > 0 then;
  if g_MemDummyCount > 0 then;
end;

// === Vector Operation Benchmarks ===

var
  g_VecA, g_VecB, g_VecR: TVecF32x4;
  g_VecIA, g_VecIB, g_VecIR: TVecI32x4;
  g_ScalarR: Single;

procedure InitVecData;
var
  i: Integer;
begin
  g_VecA := VecF32x4Splat(1.5);
  g_VecB := VecF32x4Splat(2.5);
  // No VecI32x4Splat available, initialize manually
  for i := 0 to 3 do
  begin
    g_VecIA.i[i] := 100;
    g_VecIB.i[i] := 200;
  end;
end;

function BenchVecF32x4Add_Scalar: Int64;
begin
  g_VecR := ScalarAddF32x4(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVecF32x4Add_Active: Int64;
begin
  g_VecR := VecF32x4Add(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVecF32x4Mul_Scalar: Int64;
begin
  g_VecR := ScalarMulF32x4(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVecF32x4Mul_Active: Int64;
begin
  g_VecR := VecF32x4Mul(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVecF32x4Div_Scalar: Int64;
begin
  g_VecR := ScalarDivF32x4(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVecF32x4Div_Active: Int64;
begin
  g_VecR := VecF32x4Div(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVecI32x4Add_Scalar: Int64;
begin
  g_VecIR := ScalarAddI32x4(g_VecIA, g_VecIB);
  Result := 1;
end;

function BenchVecI32x4Add_Active: Int64;
begin
  g_VecIR := VecI32x4Add(g_VecIA, g_VecIB);
  Result := 1;
end;

function BenchVecF32x4Dot_Scalar: Int64;
begin
  g_ScalarR := ScalarDotF32x4(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVecF32x4Dot_Active: Int64;
begin
  g_ScalarR := VecF32x4Dot(g_VecA, g_VecB);
  Result := 1;
end;

function BenchVectorOps: TBenchResults;
var
  OpsScalar, OpsActive: Double;
  TotalOps: Int64;
begin
  InitVecData;
  SetLength(Result, 5);
  
  // VecF32x4Add
  OpsScalar := MeasureOpsPerSec(@BenchVecF32x4Add_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchVecF32x4Add_Active, TotalOps);
  Result[0].Name := 'VecF32x4Add';
  Result[0].Size := 0;
  Result[0].ScalarOpsPerSec := OpsScalar;
  Result[0].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[0].Speedup := OpsActive / OpsScalar else Result[0].Speedup := 0;
  
  // VecF32x4Mul
  OpsScalar := MeasureOpsPerSec(@BenchVecF32x4Mul_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchVecF32x4Mul_Active, TotalOps);
  Result[1].Name := 'VecF32x4Mul';
  Result[1].Size := 0;
  Result[1].ScalarOpsPerSec := OpsScalar;
  Result[1].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[1].Speedup := OpsActive / OpsScalar else Result[1].Speedup := 0;
  
  // VecF32x4Div
  OpsScalar := MeasureOpsPerSec(@BenchVecF32x4Div_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchVecF32x4Div_Active, TotalOps);
  Result[2].Name := 'VecF32x4Div';
  Result[2].Size := 0;
  Result[2].ScalarOpsPerSec := OpsScalar;
  Result[2].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[2].Speedup := OpsActive / OpsScalar else Result[2].Speedup := 0;
  
  // VecI32x4Add
  OpsScalar := MeasureOpsPerSec(@BenchVecI32x4Add_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchVecI32x4Add_Active, TotalOps);
  Result[3].Name := 'VecI32x4Add';
  Result[3].Size := 0;
  Result[3].ScalarOpsPerSec := OpsScalar;
  Result[3].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[3].Speedup := OpsActive / OpsScalar else Result[3].Speedup := 0;
  
  // VecF32x4Dot
  OpsScalar := MeasureOpsPerSec(@BenchVecF32x4Dot_Scalar, TotalOps);
  OpsActive := MeasureOpsPerSec(@BenchVecF32x4Dot_Active, TotalOps);
  Result[4].Name := 'VecF32x4Dot';
  Result[4].Size := 0;
  Result[4].ScalarOpsPerSec := OpsScalar;
  Result[4].ActiveOpsPerSec := OpsActive;
  if OpsScalar > 0 then Result[4].Speedup := OpsActive / OpsScalar else Result[4].Speedup := 0;
  
  // Suppress unused warnings
  if g_VecR.f[0] > 0 then;
  if g_VecIR.i[0] > 0 then;
  if g_ScalarR > 0 then;
end;

// === Public API ===

function RunAllBenchmarks: TBenchResults;
var
  MemResults, VecResults: TBenchResults;
  i, Offset: Integer;
begin
  MemResults := BenchMemOps;
  VecResults := BenchVectorOps;
  
  SetLength(Result, Length(MemResults) + Length(VecResults));
  
  for i := 0 to High(MemResults) do
    Result[i] := MemResults[i];
  
  Offset := Length(MemResults);
  for i := 0 to High(VecResults) do
    Result[Offset + i] := VecResults[i];
end;

function FormatOps(Ops: Double): string;
begin
  if Ops >= 1e9 then
    Result := Format('%.2f G', [Ops / 1e9])
  else if Ops >= 1e6 then
    Result := Format('%.2f M', [Ops / 1e6])
  else if Ops >= 1e3 then
    Result := Format('%.2f K', [Ops / 1e3])
  else
    Result := Format('%.0f  ', [Ops]);
end;

function GetBackendName: string;
var
  Backend: TSimdBackend;
begin
  Backend := GetActiveBackend;
  case Backend of
    sbScalar: Result := 'Scalar';
    sbSSE2:   Result := 'SSE2';
    sbSSE3:   Result := 'SSE3';
    sbSSSE3:  Result := 'SSSE3';
    sbSSE41:  Result := 'SSE4.1';
    sbSSE42:  Result := 'SSE4.2';
    sbAVX2:   Result := 'AVX2';
    sbAVX512: Result := 'AVX-512';
    sbNEON:   Result := 'NEON';
    sbRISCVV: Result := 'RISC-V V';
  else
    Result := 'Unknown';
  end;
end;

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

procedure PrintBenchResults(const Results: TBenchResults);
var
  i: Integer;
  SizeStr: string;
begin
  WriteLn;
  WriteLn('=== SIMD Benchmark (', GetArchName, '/', GetBackendName, ') ===');
  WriteLn;
  WriteLn('Operation        Size     Scalar ops/s   Active ops/s   Speedup');
  WriteLn('----------------------------------------------------------------');
  
  for i := 0 to High(Results) do
  begin
    if Results[i].Size > 0 then
      SizeStr := Format('%4d B', [Results[i].Size])
    else
      SizeStr := '     -';
    
    WriteLn(Format('%-15s  %s  %12s  %12s  %6.2fx', [
      Results[i].Name,
      SizeStr,
      FormatOps(Results[i].ScalarOpsPerSec),
      FormatOps(Results[i].ActiveOpsPerSec),
      Results[i].Speedup
    ]));
  end;
  
  WriteLn;
end;

end.

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
program bench_math_operations;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils,
  fafafa.core.math,
  fafafa.core.math.base;  // TOptionalU32 type

function ParseIntArg(const aName: string; aDefault: Integer): Integer;
var
  LIdx: Integer;
  LS: string;
begin
  Result := aDefault;
  for LIdx := 1 to ParamCount do
  begin
    LS := ParamStr(LIdx);
    if Copy(LS, 1, Length(aName) + 1) = aName + '=' then
      Exit(StrToIntDef(Copy(LS, Length(aName) + 2, MaxInt), aDefault));
  end;
end;

function OpsPerSecond(aOps: QWord; aElapsedMs: QWord): Double;
begin
  if aElapsedMs = 0 then
    aElapsedMs := 1;
  Result := (Double(aOps) * 1000.0) / Double(aElapsedMs);
end;

{-----------------------------------------------------------------------------
  Checked Operations Benchmarks
-----------------------------------------------------------------------------}

procedure BenchCheckedAdd;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
  LOptResult: TOptionalU32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 100;
  LB := 200;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LOptResult := CheckedAddU32(LA, LB);
    if LOptResult.IsSome then
      LResult := LOptResult.Unwrap
    else
      LResult := 0;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['CheckedAddU32', LOps / 1e6]));
end;

procedure BenchCheckedSub;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
  LOptResult: TOptionalU32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 300;
  LB := 100;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LOptResult := CheckedSubU32(LA, LB);
    if LOptResult.IsSome then
      LResult := LOptResult.Unwrap
    else
      LResult := 0;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['CheckedSubU32', LOps / 1e6]));
end;

procedure BenchCheckedMul;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
  LOptResult: TOptionalU32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 1000;
  LB := 2000;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LOptResult := CheckedMulU32(LA, LB);
    if LOptResult.IsSome then
      LResult := LOptResult.Unwrap
    else
      LResult := 0;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['CheckedMulU32', LOps / 1e6]));
end;

procedure BenchCheckedDiv;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
  LOptResult: TOptionalU32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 1000000;
  LB := 100;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LOptResult := CheckedDivU32(LA, LB);
    if LOptResult.IsSome then
      LResult := LOptResult.Unwrap
    else
      LResult := 0;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['CheckedDivU32', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Saturating Operations Benchmarks
-----------------------------------------------------------------------------}

procedure BenchSaturatingAdd;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := High(UInt32) - 1000;
  LB := 2000;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := SaturatingAdd(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['SaturatingAdd', LOps / 1e6]));
end;

procedure BenchSaturatingSub;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 1000;
  LB := 2000;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := SaturatingSub(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['SaturatingSub', LOps / 1e6]));
end;

procedure BenchSaturatingMul;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := High(UInt32) div 2;
  LB := 3;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := SaturatingMul(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['SaturatingMul', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Wrapping Operations Benchmarks
-----------------------------------------------------------------------------}

procedure BenchWrappingAdd;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := High(UInt32) - 100;
  LB := 200;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := WrappingAddU32(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['WrappingAddU32', LOps / 1e6]));
end;

procedure BenchWrappingSub;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 100;
  LB := 200;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := WrappingSubU32(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['WrappingSubU32', LOps / 1e6]));
end;

procedure BenchWrappingMul;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := High(UInt32) div 2;
  LB := 3;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := WrappingMulU32(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['WrappingMulU32', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Euclidean Division Benchmarks
-----------------------------------------------------------------------------}

procedure BenchDivEuclid;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: Int32;
  LResult: Int32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := -1000;
  LB := 7;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := DivEuclidI32(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['DivEuclidI32', LOps / 1e6]));
end;

procedure BenchRemEuclid;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: Int32;
  LResult: Int32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := -1000;
  LB := 7;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := RemEuclidI32(LA, LB);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['RemEuclidI32', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Math Functions Benchmarks
-----------------------------------------------------------------------------}

procedure BenchPower;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LBase, LExp: Double;
  LResult: Double;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LBase := 2.5;
  LExp := 3.0;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := Power(LBase, LExp);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Power', LOps / 1e6]));
end;

procedure BenchSqrt;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LValue: Double;
  LResult: Double;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LValue := 2.5;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := Sqrt(LValue);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Sqrt', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Baseline Comparisons (Standard Pascal Operators)
-----------------------------------------------------------------------------}

procedure BenchStandardAdd;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 100;
  LB := 200;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LA + LB;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Standard Add (baseline)', LOps / 1e6]));
end;

procedure BenchStandardSub;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 300;
  LB := 100;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LA - LB;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Standard Sub (baseline)', LOps / 1e6]));
end;

procedure BenchStandardMul;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 1000;
  LB := 2000;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LA * LB;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Standard Mul (baseline)', LOps / 1e6]));
end;

procedure BenchStandardDiv;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LA, LB: UInt32;
  LResult: UInt32;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LA := 1000000;
  LB := 100;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LA div LB;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Standard Div (baseline)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Main
-----------------------------------------------------------------------------}

procedure Run;
var
  LIterations: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  Writeln('fafafa.core.math operations benchmark');
  Writeln(Format('  Iterations=%d', [LIterations]));
  Writeln;

  Writeln('Baseline (Standard Pascal Operators)');
  BenchStandardAdd;
  BenchStandardSub;
  BenchStandardMul;
  BenchStandardDiv;
  Writeln;

  Writeln('Checked Operations');
  BenchCheckedAdd;
  BenchCheckedSub;
  BenchCheckedMul;
  BenchCheckedDiv;
  Writeln;

  Writeln('Saturating Operations');
  BenchSaturatingAdd;
  BenchSaturatingSub;
  BenchSaturatingMul;
  Writeln;

  Writeln('Wrapping Operations');
  BenchWrappingAdd;
  BenchWrappingSub;
  BenchWrappingMul;
  Writeln;

  Writeln('Euclidean Division');
  BenchDivEuclid;
  BenchRemEuclid;
  Writeln;

  Writeln('Math Functions');
  BenchPower;
  BenchSqrt;
end;

begin
  Run;
end.

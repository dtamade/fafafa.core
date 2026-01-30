program bench_math_operations;

{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.math.safeint;

const
  ITERATIONS = 2000000;

var
  StartTime, EndTime: QWord;
  I: Integer;
  A, B: UInt32;
  ResultU32: TOptionalU32;
  ResultI32: Int32;
  Dummy: Int32;

function GetTickCount64: QWord;
begin
  Result := QWord(GetTickCount);
end;

procedure BenchmarkCheckedMulU32;
var
  Mops: Double;
begin
  A := 1000;
  B := 2000;

  StartTime := GetTickCount64;
  for I := 1 to ITERATIONS do
  begin
    ResultU32 := CheckedMulU32(A, B);
    if ResultU32.IsSome then
      Dummy := Integer(ResultU32.GetValue);
  end;
  EndTime := GetTickCount64;

  Mops := ITERATIONS / ((EndTime - StartTime) * 1000.0);
  WriteLn('CheckedMulU32: ', Mops:0:2, ' Mops/s');
end;

procedure BenchmarkDivEuclidI32;
var
  Mops: Double;
  A, B: Int32;
begin
  A := 17;
  B := 5;

  StartTime := GetTickCount64;
  for I := 1 to ITERATIONS do
  begin
    ResultI32 := DivEuclidI32(A, B);
    Dummy := ResultI32;
  end;
  EndTime := GetTickCount64;

  Mops := ITERATIONS / ((EndTime - StartTime) * 1000.0);
  WriteLn('DivEuclidI32: ', Mops:0:2, ' Mops/s');
end;

procedure BenchmarkRemEuclidI32;
var
  Mops: Double;
  A, B: Int32;
begin
  A := 17;
  B := 5;

  StartTime := GetTickCount64;
  for I := 1 to ITERATIONS do
  begin
    ResultI32 := RemEuclidI32(A, B);
    Dummy := ResultI32;
  end;
  EndTime := GetTickCount64;

  Mops := ITERATIONS / ((EndTime - StartTime) * 1000.0);
  WriteLn('RemEuclidI32: ', Mops:0:2, ' Mops/s');
end;

begin
  WriteLn('Math Module Performance Benchmark');
  WriteLn('Iterations: ', ITERATIONS);
  WriteLn('');

  BenchmarkCheckedMulU32;
  BenchmarkDivEuclidI32;
  BenchmarkRemEuclidI32;

  WriteLn('');
  WriteLn('Benchmark completed.');
end.

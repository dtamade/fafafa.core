program bench_option_combinators;

{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.option.base, fafafa.core.option, fafafa.core.base;

const
  ITERATIONS = 2000000;

var
  StartTime, EndTime: QWord;
  I: Integer;
  Dummy: Integer;

function GetTickCount64: QWord;
begin
  Result := QWord(GetTickCount);
end;

function DoubleIt(const N: Integer): Integer;
begin
  Result := N * 2;
end;

function IsEven(const N: Integer): Boolean;
begin
  Result := (N mod 2) = 0;
end;

function SafeDivide(const N: Integer): specialize TOption<Integer>;
begin
  if N = 0 then
    Exit(specialize TOption<Integer>.None);
  Result := specialize TOption<Integer>.Some(100 div N);
end;

procedure BenchmarkOptionMap;
var
  Mops: Double;
  Opt, Opt2: specialize TOption<Integer>;
begin
  Opt := specialize TOption<Integer>.Some(42);

  StartTime := GetTickCount64;
  for I := 1 to ITERATIONS do
  begin
    Opt2 := specialize OptionMap<Integer, Integer>(Opt, @DoubleIt);
    if Opt2.IsSome then
      Dummy := Opt2.GetValueUnchecked;
  end;
  EndTime := GetTickCount64;

  Mops := ITERATIONS / ((EndTime - StartTime) * 1000.0);
  WriteLn('OptionMap (Some): ', Mops:0:2, ' Mops/s');
end;

procedure BenchmarkOptionAndThen;
var
  Mops: Double;
  Opt, Opt2: specialize TOption<Integer>;
begin
  Opt := specialize TOption<Integer>.Some(5);

  StartTime := GetTickCount64;
  for I := 1 to ITERATIONS do
  begin
    Opt2 := specialize OptionAndThen<Integer, Integer>(Opt, @SafeDivide);
    if Opt2.IsSome then
      Dummy := Opt2.GetValueUnchecked;
  end;
  EndTime := GetTickCount64;

  Mops := ITERATIONS / ((EndTime - StartTime) * 1000.0);
  WriteLn('OptionAndThen (Some): ', Mops:0:2, ' Mops/s');
end;

procedure BenchmarkOptionFilter;
var
  Mops: Double;
  Opt, Opt2: specialize TOption<Integer>;
begin
  Opt := specialize TOption<Integer>.Some(42);

  StartTime := GetTickCount64;
  for I := 1 to ITERATIONS do
  begin
    Opt2 := specialize OptionFilter<Integer>(Opt, @IsEven);
    if Opt2.IsSome then
      Dummy := Opt2.GetValueUnchecked;
  end;
  EndTime := GetTickCount64;

  Mops := ITERATIONS / ((EndTime - StartTime) * 1000.0);
  WriteLn('OptionFilter (Some, pass): ', Mops:0:2, ' Mops/s');
end;

begin
  WriteLn('Option Module Performance Benchmark');
  WriteLn('Iterations: ', ITERATIONS);
  WriteLn('');

  BenchmarkOptionMap;
  BenchmarkOptionAndThen;
  BenchmarkOptionFilter;

  WriteLn('');
  WriteLn('Benchmark completed.');
end.

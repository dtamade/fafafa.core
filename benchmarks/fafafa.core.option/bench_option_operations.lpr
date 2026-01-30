{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
program bench_option_operations;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils,
  fafafa.core.option,
  fafafa.core.option.base;

type
  TOptInt = specialize TOption<Integer>;
  TOptStr = specialize TOption<string>;

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
  Callback Functions for Combinators
-----------------------------------------------------------------------------}

function DoubleIt(const N: Integer): Integer;
begin
  Result := N * 2;
end;

function IsEven(const N: Integer): Boolean;
begin
  Result := (N mod 2) = 0;
end;

function SafeDivide(const N: Integer): TOptInt;
begin
  if N = 0 then
    Exit(TOptInt.None);
  Result := TOptInt.Some(100 div N);
end;

function GetDefault: Integer;
begin
  Result := 42;
end;

{-----------------------------------------------------------------------------
  Baseline Operations Benchmarks
-----------------------------------------------------------------------------}

procedure BenchBaseline_DirectAccess;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LValue: Integer;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LValue := 42;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LValue;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Direct Access (baseline)', LOps / 1e6]));
end;

procedure BenchBaseline_FunctionCall;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LValue: Integer;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LValue := 42;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := DoubleIt(LValue);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Function Call (baseline)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Option Construction Benchmarks
-----------------------------------------------------------------------------}

procedure BenchConstruct_Some;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LOpt := TOptInt.Some(42);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['TOption.Some', LOps / 1e6]));
end;

procedure BenchConstruct_None;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LOpt := TOptInt.None;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['TOption.None', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Option Query Benchmarks
-----------------------------------------------------------------------------}

procedure BenchQuery_IsSome;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Boolean;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LOpt.IsSome;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['IsSome', LOps / 1e6]));
end;

procedure BenchQuery_IsNone;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Boolean;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.None;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LOpt.IsNone;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['IsNone', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Unwrap Operations Benchmarks
-----------------------------------------------------------------------------}

procedure BenchUnwrap_Unwrap;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LOpt.Unwrap;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Unwrap (Some)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOr;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LOpt.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOr (Some)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOrElse;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LOpt.UnwrapOrElse(@GetDefault);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOrElse (Some)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOr_None;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.None;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LOpt.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOr (None)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOrElse_None;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.None;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LOpt.UnwrapOrElse(@GetDefault);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOrElse (None)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Combinator Benchmarks
-----------------------------------------------------------------------------}

procedure BenchCombinator_Map_Some;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize OptionMap<Integer, Integer>(LOpt, @DoubleIt);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map (Some)', LOps / 1e6]));
end;

procedure BenchCombinator_Map_None;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.None;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize OptionMap<Integer, Integer>(LOpt, @DoubleIt);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map (None)', LOps / 1e6]));
end;

procedure BenchCombinator_Filter_Some_Pass;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize OptionFilter<Integer>(LOpt, @IsEven);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Filter (Some, pass)', LOps / 1e6]));
end;

procedure BenchCombinator_Filter_Some_Fail;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(43);  // Odd number, will fail IsEven

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize OptionFilter<Integer>(LOpt, @IsEven);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Filter (Some, fail)', LOps / 1e6]));
end;

procedure BenchCombinator_Filter_None;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.None;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize OptionFilter<Integer>(LOpt, @IsEven);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Filter (None)', LOps / 1e6]));
end;

procedure BenchCombinator_AndThen_Some;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(10);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize OptionAndThen<Integer, Integer>(LOpt, @SafeDivide);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['AndThen (Some)', LOps / 1e6]));
end;

procedure BenchCombinator_AndThen_None;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.None;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize OptionAndThen<Integer, Integer>(LOpt, @SafeDivide);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['AndThen (None)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Chained Operations Benchmarks
-----------------------------------------------------------------------------}

procedure BenchChained_MapFilterUnwrap_Some;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
  LMapped: TOptInt;
  LFiltered: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(21);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LMapped := specialize OptionMap<Integer, Integer>(LOpt, @DoubleIt);
    LFiltered := specialize OptionFilter<Integer>(LMapped, @IsEven);
    LResult := LFiltered.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map→Filter→UnwrapOr (Some)', LOps / 1e6]));
end;

procedure BenchChained_MapFilterUnwrap_None;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
  LMapped: TOptInt;
  LFiltered: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.None;

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LMapped := specialize OptionMap<Integer, Integer>(LOpt, @DoubleIt);
    LFiltered := specialize OptionFilter<Integer>(LMapped, @IsEven);
    LResult := LFiltered.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map→Filter→UnwrapOr (None)', LOps / 1e6]));
end;

procedure BenchChained_MapAndThenUnwrap_Some;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LOpt: TOptInt;
  LResult: Integer;
  LMapped: TOptInt;
  LAndThen: TOptInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LOpt := TOptInt.Some(5);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LMapped := specialize OptionMap<Integer, Integer>(LOpt, @DoubleIt);
    LAndThen := specialize OptionAndThen<Integer, Integer>(LMapped, @SafeDivide);
    LResult := LAndThen.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map→AndThen→UnwrapOr (Some)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Main
-----------------------------------------------------------------------------}

procedure Run;
var
  LIterations: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  Writeln('fafafa.core.option operations benchmark');
  Writeln(Format('  Iterations=%d', [LIterations]));
  Writeln;

  Writeln('Baseline (Direct Operations)');
  BenchBaseline_DirectAccess;
  BenchBaseline_FunctionCall;
  Writeln;

  Writeln('Option Construction');
  BenchConstruct_Some;
  BenchConstruct_None;
  Writeln;

  Writeln('Option Query');
  BenchQuery_IsSome;
  BenchQuery_IsNone;
  Writeln;

  Writeln('Unwrap Operations (Some)');
  BenchUnwrap_Unwrap;
  BenchUnwrap_UnwrapOr;
  BenchUnwrap_UnwrapOrElse;
  Writeln;

  Writeln('Unwrap Operations (None)');
  BenchUnwrap_UnwrapOr_None;
  BenchUnwrap_UnwrapOrElse_None;
  Writeln;

  Writeln('Combinators (Some)');
  BenchCombinator_Map_Some;
  BenchCombinator_Filter_Some_Pass;
  BenchCombinator_Filter_Some_Fail;
  BenchCombinator_AndThen_Some;
  Writeln;

  Writeln('Combinators (None)');
  BenchCombinator_Map_None;
  BenchCombinator_Filter_None;
  BenchCombinator_AndThen_None;
  Writeln;

  Writeln('Chained Operations');
  BenchChained_MapFilterUnwrap_Some;
  BenchChained_MapFilterUnwrap_None;
  BenchChained_MapAndThenUnwrap_Some;
end;

begin
  Run;
end.

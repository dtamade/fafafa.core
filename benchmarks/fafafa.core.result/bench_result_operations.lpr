{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
program bench_result_operations;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils,
  fafafa.core.result,
  fafafa.core.base;

type
  TIntResult = specialize TResult<Integer, string>;
  TStrResult = specialize TResult<string, string>;
  TErrorCtxInt = specialize TErrorCtx<Integer>;

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

function AddContext(const Err: string): string;
begin
  Result := 'Error: ' + Err;
end;

function SafeDivide(const N: Integer): TIntResult;
begin
  if N = 0 then
    Exit(TIntResult.Err('Division by zero'));
  Result := TIntResult.Ok(100 div N);
end;

function RecoverFromError(const Err: string): TIntResult;
begin
  Result := TIntResult.Ok(0);
end;

function GetDefaultValue: Integer;
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
  Result Construction Benchmarks
-----------------------------------------------------------------------------}

procedure BenchConstruct_Ok;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LRes := TIntResult.Ok(42);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['TResult.Ok', LOps / 1e6]));
end;

procedure BenchConstruct_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LRes := TIntResult.Err('Error message');
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['TResult.Err', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Result Query Benchmarks
-----------------------------------------------------------------------------}

procedure BenchQuery_IsOk;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Boolean;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LRes.IsOk;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['IsOk', LOps / 1e6]));
end;

procedure BenchQuery_IsErr;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Boolean;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LRes.IsErr;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['IsErr', LOps / 1e6]));
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
  LRes: TIntResult;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LRes.Unwrap;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Unwrap (Ok)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOr;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LRes.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOr (Ok)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOrElse;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LRes.UnwrapOrElse(@GetDefaultValue);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOrElse (Ok)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOr_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LRes.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOr (Err)', LOps / 1e6]));
end;

procedure BenchUnwrap_UnwrapOrElse_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := LRes.UnwrapOrElse(@GetDefaultValue);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['UnwrapOrElse (Err)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Combinator Benchmarks
-----------------------------------------------------------------------------}

procedure BenchCombinator_Map_Ok;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultMap<Integer, string, Integer>(LRes, @DoubleIt);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map (Ok)', LOps / 1e6]));
end;

procedure BenchCombinator_Map_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultMap<Integer, string, Integer>(LRes, @DoubleIt);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map (Err)', LOps / 1e6]));
end;

procedure BenchCombinator_MapErr_Ok;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultMapErr<Integer, string, string>(LRes, @AddContext);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['MapErr (Ok)', LOps / 1e6]));
end;

procedure BenchCombinator_MapErr_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultMapErr<Integer, string, string>(LRes, @AddContext);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['MapErr (Err)', LOps / 1e6]));
end;

procedure BenchCombinator_AndThen_Ok;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(10);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultAndThen<Integer, string, Integer>(LRes, @SafeDivide);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['AndThen (Ok)', LOps / 1e6]));
end;

procedure BenchCombinator_AndThen_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultAndThen<Integer, string, Integer>(LRes, @SafeDivide);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['AndThen (Err)', LOps / 1e6]));
end;

procedure BenchCombinator_OrElse_Ok;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(42);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultOrElse<Integer, string, string>(LRes, @RecoverFromError);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['OrElse (Ok)', LOps / 1e6]));
end;

procedure BenchCombinator_OrElse_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LResult := specialize ResultOrElse<Integer, string, string>(LRes, @RecoverFromError);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['OrElse (Err)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Chained Operations Benchmarks
-----------------------------------------------------------------------------}

procedure BenchChained_MapAndThenUnwrap_Ok;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Integer;
  LMapped: TIntResult;
  LAndThen: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(5);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LMapped := specialize ResultMap<Integer, string, Integer>(LRes, @DoubleIt);
    LAndThen := specialize ResultAndThen<Integer, string, Integer>(LMapped, @SafeDivide);
    LResult := LAndThen.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map→AndThen→UnwrapOr (Ok)', LOps / 1e6]));
end;

procedure BenchChained_MapAndThenUnwrap_Err;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Integer;
  LMapped: TIntResult;
  LAndThen: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Err('Error');

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LMapped := specialize ResultMap<Integer, string, Integer>(LRes, @DoubleIt);
    LAndThen := specialize ResultAndThen<Integer, string, Integer>(LMapped, @SafeDivide);
    LResult := LAndThen.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map→AndThen→UnwrapOr (Err)', LOps / 1e6]));
end;

procedure BenchChained_MapMapErrUnwrap_Ok;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LRes: TIntResult;
  LResult: Integer;
  LMapped: TIntResult;
  LMapErr: TIntResult;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LRes := TIntResult.Ok(21);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LMapped := specialize ResultMap<Integer, string, Integer>(LRes, @DoubleIt);
    LMapErr := specialize ResultMapErr<Integer, string, string>(LMapped, @AddContext);
    LResult := LMapErr.UnwrapOr(0);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['Map→MapErr→UnwrapOr (Ok)', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Error Context Benchmarks
-----------------------------------------------------------------------------}

procedure BenchErrorCtx_Create;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LCtx: TErrorCtxInt;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LCtx := TErrorCtxInt.Create('Error context', 404);
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['TErrorCtx.Create', LOps / 1e6]));
end;

procedure BenchErrorCtx_Access;
var
  LIdx: Integer;
  LIterations: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
  LOps: Double;
  LCtx: TErrorCtxInt;
  LMsg: string;
  LInner: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);
  LCtx := TErrorCtxInt.Create('Error context', 404);

  LStartMs := GetTickCount64;
  for LIdx := 1 to LIterations do
  begin
    LMsg := LCtx.Msg;
    LInner := LCtx.Inner;
  end;
  LElapsedMs := GetTickCount64 - LStartMs;

  LOps := OpsPerSecond(QWord(LIterations), LElapsedMs);
  Writeln(Format('%-40s %8.2f Mops/s', ['TErrorCtx.Access', LOps / 1e6]));
end;

{-----------------------------------------------------------------------------
  Main
-----------------------------------------------------------------------------}

procedure Run;
var
  LIterations: Integer;
begin
  LIterations := ParseIntArg('--iters', 2000000);

  Writeln('fafafa.core.result operations benchmark');
  Writeln(Format('  Iterations=%d', [LIterations]));
  Writeln;

  Writeln('Baseline (Direct Operations)');
  BenchBaseline_DirectAccess;
  BenchBaseline_FunctionCall;
  Writeln;

  Writeln('Result Construction');
  BenchConstruct_Ok;
  BenchConstruct_Err;
  Writeln;

  Writeln('Result Query');
  BenchQuery_IsOk;
  BenchQuery_IsErr;
  Writeln;

  Writeln('Unwrap Operations (Ok)');
  BenchUnwrap_Unwrap;
  BenchUnwrap_UnwrapOr;
  BenchUnwrap_UnwrapOrElse;
  Writeln;

  Writeln('Unwrap Operations (Err)');
  BenchUnwrap_UnwrapOr_Err;
  BenchUnwrap_UnwrapOrElse_Err;
  Writeln;

  Writeln('Combinators (Ok)');
  BenchCombinator_Map_Ok;
  BenchCombinator_MapErr_Ok;
  BenchCombinator_AndThen_Ok;
  BenchCombinator_OrElse_Ok;
  Writeln;

  Writeln('Combinators (Err)');
  BenchCombinator_Map_Err;
  BenchCombinator_MapErr_Err;
  BenchCombinator_AndThen_Err;
  BenchCombinator_OrElse_Err;
  Writeln;

  Writeln('Chained Operations');
  BenchChained_MapAndThenUnwrap_Ok;
  BenchChained_MapAndThenUnwrap_Err;
  BenchChained_MapMapErrUnwrap_Ok;
  Writeln;

  Writeln('Error Context');
  BenchErrorCtx_Create;
  BenchErrorCtx_Access;
end;

begin
  Run;
end.

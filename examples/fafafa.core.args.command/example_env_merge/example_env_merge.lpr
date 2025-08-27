program example_env_merge;

{$mode objfpc}{$H+}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.args.config;

function H_Run(const A: IArgs): Integer;
var v: string; c: Integer;
begin
  Writeln('run executed');
  if A<>nil then
  begin
    if A.TryGetValue('count', v) and TryStrToInt(v, c) then
      Writeln('  count = ', c)
    else if A.HasFlag('count') then
      Writeln('  count flag present');
    if A.HasFlag('debug') then
      Writeln('  debug = true');
  end;
  Exit(0);
end;

function ParamsToArray: TStringArray;
var i: Integer;
begin
  Result := nil;
  SetLength(Result, ParamCount);
  for i := 1 to ParamCount do
    Result[i-1] := ParamStr(i);
end;

function ConcatArrays(const A, B: TStringArray): TStringArray;
var i, n: Integer;
begin
  Result := nil;
  n := Length(A) + Length(B);
  SetLength(Result, n);
  for i := 0 to High(A) do Result[i] := A[i];
  for i := 0 to High(B) do Result[Length(A)+i] := B[i];
end;

var
  Root: IRootCommand;
  code: Integer;
  envArgv, cliArgv, merged: TStringArray;
  opts: TArgsOptions;
begin
  // define a simple command
  Root := NewRootCommand;
  Root.Register(NewCommandPath(['run'], @H_Run, 'Run with env-merged flags'));

  // example: take env with prefix APP_ and merge into argv
  envArgv := ArgvFromEnv('APP_');
  cliArgv := ParamsToArray;
  merged := ConcatArrays(envArgv, cliArgv);

  // normal dispatch using merged argv
  opts := ArgsOptionsDefault;
  code := Root.Run(merged, opts);
  Halt(code);
end.


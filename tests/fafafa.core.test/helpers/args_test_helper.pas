unit args_test_helper;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.args, fafafa.core.args.config;

type
  TStringArray = array of string;

// Create default options for tests; allow a mutator to tweak per-case
function MakeDefaultOpts: TArgsOptions;
procedure TweakOpts(var O: TArgsOptions; const CaseInsensitive, StopAtDDash,
  TreatNegAsPositional, EnableNoPrefix, AllowShortCombo, AllowShortKV: boolean);

// Build argv by merging ENV (with prefix) and CLI tokens; CONFIG intentionally omitted
function MakeMergedArgv(const Cli: array of string; const EnvPrefix: string = 'APP_'): TStringArray;

// Sanity helpers: CONFIG functions should return empty when macros not enabled
function IsJsonArgvSupported: boolean;
function IsTomlArgvSupported: boolean;

implementation

function MakeDefaultOpts: TArgsOptions;
begin
  Result := ArgsOptionsDefault;
  // enable no- prefix by default for tests
  Result.EnableNoPrefixNegation := True;
end;

procedure TweakOpts(var O: TArgsOptions; const CaseInsensitive, StopAtDDash,
  TreatNegAsPositional, EnableNoPrefix, AllowShortCombo, AllowShortKV: boolean);
begin
  O.CaseInsensitiveKeys := CaseInsensitive;
  O.StopAtDoubleDash := StopAtDDash;
  O.TreatNegativeNumbersAsPositionals := TreatNegAsPositional;
  O.EnableNoPrefixNegation := EnableNoPrefix;
  O.AllowShortFlagsCombo := AllowShortCombo;
  O.AllowShortKeyValue := AllowShortKV;
end;

function MakeMergedArgv(const Cli: array of string; const EnvPrefix: string): TStringArray;
var env: TStringArray; i, nCli, nEnv: Integer;
begin
  env := ArgsArgvFromEnv(EnvPrefix);
  nCli := Length(Cli);
  nEnv := Length(env);
  SetLength(Result, nEnv + nCli);
  for i := 0 to nEnv-1 do Result[i] := env[i];
  for i := 0 to nCli-1 do Result[nEnv + i] := Cli[i];
end;

function IsJsonArgvSupported: boolean;
begin
  {$IFDEF FAFAFA_ARGS_CONFIG_JSON}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function IsTomlArgvSupported: boolean;
begin
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

end.


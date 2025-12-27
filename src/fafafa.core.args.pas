unit fafafa.core.args;
{**
 * fafafa.core.args - 命令行参数解析门面
 *
 * 用户只需 uses fafafa.core.args 即可访问所有 args 相关 API
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.args.base,
  fafafa.core.args.errors,
  fafafa.core.args.config,
  fafafa.core.option.base,
  fafafa.core.option;

type
  // Re-export from args.base
  TStringArray = fafafa.core.args.base.TStringArray;
  TArgsOptions = fafafa.core.args.base.TArgsOptions;
  TArgKind = fafafa.core.args.base.TArgKind;
  TArgItem = fafafa.core.args.base.TArgItem;
  TArgsContext = fafafa.core.args.base.TArgsContext;
  IArgs = fafafa.core.args.base.IArgs;
  TArgs = fafafa.core.args.base.TArgs;
  TArgsEnumerator = fafafa.core.args.base.TArgsEnumerator;
  TArgsArgEnumerator = fafafa.core.args.base.TArgsArgEnumerator;
  TArgsOptionEnumerator = fafafa.core.args.base.TArgsOptionEnumerator;

  // Re-export from args.errors
  TArgsErrorKind = fafafa.core.args.errors.TArgsErrorKind;
  TArgsError = fafafa.core.args.errors.TArgsError;
  // ✅ P1-4: 补全 Result 类型导出
  TArgsResult = fafafa.core.args.errors.TArgsResult;
  TArgsResultInt = fafafa.core.args.errors.TArgsResultInt;
  TArgsResultDouble = fafafa.core.args.errors.TArgsResultDouble;
  TArgsResultBool = fafafa.core.args.errors.TArgsResultBool;

// Re-export functions from args.base
function ArgsOptionsDefault: TArgsOptions; inline;
procedure ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext); inline;

function ArgsHasFlag(const Flag: string): boolean; inline;
function ArgsTryGetValue(const Key: string; out Value: string): boolean; inline;
function ArgsGetAll(const Key: string): TStringArray; inline;
function ArgsPositionals: TStringArray; inline;
function ArgsIsHelpRequested: boolean; inline;

function ArgsGetOpt(const Key: string): specialize TOption<string>; inline;
function ArgsGetInt64Opt(const Key: string): specialize TOption<Int64>; inline;
function ArgsGetDoubleOpt(const Key: string): specialize TOption<Double>; inline;
function ArgsGetBoolOpt(const Key: string): specialize TOption<Boolean>; inline;

// Re-export functions from args.config (✅ P1-1: 使用新的 Args 前缀)
function ArgsArgvFromEnv(const Prefix: string): TStringArray; inline;
function ArgsValueFromEnvOpt(const Prefix, Key: string; const Flags: TEnvFlags = []): specialize TOption<string>; inline;

// ✅ P1-4: 补全 Result API 函数导出
function ArgsGetValueSafe(const Key: string): TArgsResult; inline;
function ArgsGetIntSafe(const Key: string): TArgsResultInt; inline;
function ArgsGetDoubleSafe(const Key: string): TArgsResultDouble; inline;
function ArgsGetBoolSafe(const Key: string): TArgsResultBool; inline;

implementation

function ArgsOptionsDefault: TArgsOptions; inline;
begin
  Result := fafafa.core.args.base.ArgsOptionsDefault;
end;

procedure ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext); inline;
begin
  fafafa.core.args.base.ParseArgs(Args, Opts, Ctx);
end;

function ArgsHasFlag(const Flag: string): boolean; inline;
begin
  Result := fafafa.core.args.base.ArgsHasFlag(Flag);
end;

function ArgsTryGetValue(const Key: string; out Value: string): boolean; inline;
begin
  Result := fafafa.core.args.base.ArgsTryGetValue(Key, Value);
end;

function ArgsGetAll(const Key: string): TStringArray; inline;
begin
  Result := fafafa.core.args.base.ArgsGetAll(Key);
end;

function ArgsPositionals: TStringArray; inline;
begin
  Result := fafafa.core.args.base.ArgsPositionals;
end;

function ArgsIsHelpRequested: boolean; inline;
begin
  Result := fafafa.core.args.base.ArgsIsHelpRequested;
end;

function ArgsGetOpt(const Key: string): specialize TOption<string>; inline;
begin
  Result := fafafa.core.args.base.ArgsGetOpt(Key);
end;

function ArgsGetInt64Opt(const Key: string): specialize TOption<Int64>; inline;
begin
  Result := fafafa.core.args.base.ArgsGetInt64Opt(Key);
end;

function ArgsGetDoubleOpt(const Key: string): specialize TOption<Double>; inline;
begin
  Result := fafafa.core.args.base.ArgsGetDoubleOpt(Key);
end;

function ArgsGetBoolOpt(const Key: string): specialize TOption<Boolean>; inline;
begin
  Result := fafafa.core.args.base.ArgsGetBoolOpt(Key);
end;

// ✅ P1-1: 使用新的 Args 前缀
function ArgsArgvFromEnv(const Prefix: string): TStringArray; inline;
begin
  Result := fafafa.core.args.config.ArgsArgvFromEnv(Prefix);
end;

function ArgsValueFromEnvOpt(const Prefix, Key: string; const Flags: TEnvFlags): specialize TOption<string>; inline;
begin
  Result := fafafa.core.args.config.ArgsValueFromEnvOpt(Prefix, Key, Flags);
end;

// ✅ P1-4: 补全 Result API 函数实现
function ArgsGetValueSafe(const Key: string): TArgsResult; inline;
begin
  Result := fafafa.core.args.errors.ArgsGetValueSafe(Key);
end;

function ArgsGetIntSafe(const Key: string): TArgsResultInt; inline;
begin
  Result := fafafa.core.args.errors.ArgsGetIntSafe(Key);
end;

function ArgsGetDoubleSafe(const Key: string): TArgsResultDouble; inline;
begin
  Result := fafafa.core.args.errors.ArgsGetDoubleSafe(Key);
end;

function ArgsGetBoolSafe(const Key: string): TArgsResultBool; inline;
begin
  Result := fafafa.core.args.errors.ArgsGetBoolSafe(Key);
end;

end.

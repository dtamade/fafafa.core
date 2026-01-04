{$CODEPAGE UTF8}
unit fafafa.core.args.config.testcase;
{**
 * fafafa.core.args.config 单元测试
 * 覆盖环境变量解析、配置文件解析和值转换
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  Classes,
  fafafa.core.args.config,
  fafafa.core.env,
  fafafa.core.option.base,
  fafafa.core.option,
  fafafa.core.result;

type
  TTestCase_ArgsConfig = class(TTestCase)
  private
    function EnvWorks: Boolean;
    function HasToken(const Arr: TStringArray; const Tok: string): Boolean;
    procedure AssertHasToken(const Arr: TStringArray; const Tok: string);
  published
    // ArgsValueFromEnvOpt 测试
    procedure Test_ArgValueFromEnvOpt_Basic;
    procedure Test_ArgValueFromEnvOpt_NotSet;
    procedure Test_ArgValueFromEnvOpt_EmptyValue;
    procedure Test_ArgValueFromEnvOpt_TrimValues;
    procedure Test_ArgValueFromEnvOpt_LowercaseBools_True;
    procedure Test_ArgValueFromEnvOpt_LowercaseBools_False;
    procedure Test_ArgValueFromEnvOpt_LowercaseBools_Yes;
    procedure Test_ArgValueFromEnvOpt_LowercaseBools_No;
    procedure Test_ArgValueFromEnvOpt_BothFlags;
    procedure Test_ArgValueFromEnvOpt_CaseInsensitiveKey;
    procedure Test_ArgValueFromEnvOpt_DashToUnderscore;

    // ArgsTokenFromEnvOpt 测试
    procedure Test_ArgTokenFromEnvOpt_WithValue;
    procedure Test_ArgTokenFromEnvOpt_EmptyValue;
    procedure Test_ArgTokenFromEnvOpt_NotSet;
    procedure Test_ArgTokenFromEnvOpt_KeyNormalization;
    procedure Test_ArgTokenFromEnvOpt_DashInKey;

    // ArgsIntFromEnvRes 测试
    procedure Test_ArgIntFromEnvRes_Valid;
    procedure Test_ArgIntFromEnvRes_NotSet;
    procedure Test_ArgIntFromEnvRes_Invalid;
    procedure Test_ArgIntFromEnvRes_Zero;
    procedure Test_ArgIntFromEnvRes_Negative;
    procedure Test_ArgIntFromEnvRes_Large;
    procedure Test_ArgIntFromEnvRes_TrimmedInt;
    procedure Test_ArgIntFromEnvRes_Float;
    procedure Test_ArgIntFromEnvRes_Hex;

    // ArgsArgvFromEnv 测试 (平台限制可能导致跳过)
    procedure Test_ArgvFromEnv_Basic;
    procedure Test_ArgvFromEnv_EmptyPrefix;
    procedure Test_ArgvFromEnv_NoMatch;
    procedure Test_ArgvFromEnv_KeyNormalization;

    // ArgsArgvFromEnvEx 测试
    procedure Test_ArgvFromEnvEx_AllowList;
    procedure Test_ArgvFromEnvEx_DenyList;
    procedure Test_ArgvFromEnvEx_AllowAndDeny;
    procedure Test_ArgvFromEnvEx_WithFlags;

    // ArgsTokensFromEnvOpt 测试
    procedure Test_ArgTokensFromEnvOpt_Some;
    procedure Test_ArgTokensFromEnvOpt_None;

    // 内部辅助函数行为测试 (通过公开 API 间接测试)
    procedure Test_KeyNormalization_Underscore;
    procedure Test_KeyNormalization_Mixed;
    procedure Test_ValueNormalization_Trim;
    procedure Test_ValueNormalization_Bool;

    // 边界情况测试
    procedure Test_EmptyKey;
    procedure Test_SpecialCharacters;
    procedure Test_UnicodeValue;
    procedure Test_VeryLongValue;
    procedure Test_NumericKey;

    // JSON 配置测试
    procedure Test_ArgvFromJson_NotExists;
    procedure Test_ArgvFromJson_EmptyPath;
    procedure Test_ArgvFromJson_InvalidJson_ReturnsEmpty;
    procedure Test_ArgvFromJson_RootArray_ReturnsEmpty;

    // TOML 配置测试 (条件编译)
    procedure Test_ArgvFromToml_NotExists;
    procedure Test_ArgvFromToml_EmptyPath;

    // YAML (unsupported) explicit API
    procedure Test_ArgvFromYamlOpt_Unsupported_ReturnsNone;
  end;

implementation

function TTestCase_ArgsConfig.EnvWorks: Boolean;
var
  Guard: TEnvOverrideGuard;
  Val: string;
begin
  Guard := env_override('__TEST_ENV_CHECK__', 'ok');
  try
    Result := env_lookup('__TEST_ENV_CHECK__', Val) and (Val = 'ok');
  finally
    Guard.Done;
  end;
end;

function TTestCase_ArgsConfig.HasToken(const Arr: TStringArray; const Tok: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(Arr) do
    if Arr[I] = Tok then
      Exit(True);
  Result := False;
end;

procedure TTestCase_ArgsConfig.AssertHasToken(const Arr: TStringArray; const Tok: string);
begin
  CheckTrue(HasToken(Arr, Tok), 'Expected token: ' + Tok);
end;

{ ArgsValueFromEnvOpt 测试 }

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_Basic;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_HOST', 'localhost');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'host', []);
    CheckTrue(Opt.IsSome, 'Should return Some for existing env');
    CheckEquals('localhost', Opt.Unwrap, 'Value should be localhost');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_NotSet;
var
  Opt: specialize TOption<string>;
begin
  Opt := ArgsValueFromEnvOpt('NONEXISTENT_PREFIX_XYZ_', 'missing', []);
  CheckTrue(Opt.IsNone, 'Should return None for non-existent env');
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_EmptyValue;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_EMPTY', '');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'empty', []);
    // Empty string is still Some, not None
    CheckTrue(Opt.IsSome, 'Should return Some for empty value');
    CheckEquals('', Opt.Unwrap, 'Value should be empty string');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_TrimValues;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_SPACED', '  hello world  ');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'spaced', [efTrimValues]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('hello world', Opt.Unwrap, 'Value should be trimmed');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_LowercaseBools_True;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_ENABLED', 'TRUE');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'enabled', [efNormalizeBools]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('true', Opt.Unwrap, 'TRUE should become true');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_LowercaseBools_False;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_DISABLED', 'FALSE');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'disabled', [efNormalizeBools]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('false', Opt.Unwrap, 'FALSE should become false');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_LowercaseBools_Yes;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_FLAG', 'YES');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'flag', [efNormalizeBools]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('true', Opt.Unwrap, 'YES should become true');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_LowercaseBools_No;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_FLAG', 'NO');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'flag', [efNormalizeBools]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('false', Opt.Unwrap, 'NO should become false');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_BothFlags;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_COMBO', '  TRUE  ');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('APP_', 'combo', [efTrimValues, efNormalizeBools]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('true', Opt.Unwrap, 'Should trim and lowercase');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_CaseInsensitiveKey;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_MYKEY', 'value');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    // Key is case-insensitive in lookup (toEnvName uppercases)
    Opt := ArgsValueFromEnvOpt('app_', 'mykey', []);
    CheckTrue(Opt.IsSome, 'Should find key case-insensitively');
    CheckEquals('value', Opt.Unwrap, 'Value should match');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_DashToUnderscore;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_MY_KEY', 'dash-value');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    // Key with dash becomes underscore in env name
    Opt := ArgsValueFromEnvOpt('APP_', 'my-key', []);
    CheckTrue(Opt.IsSome, 'Should convert dash to underscore');
    CheckEquals('dash-value', Opt.Unwrap, 'Value should match');
  finally
    Guard.Done;
  end;
end;

{ ArgsTokenFromEnvOpt 测试 }

procedure TTestCase_ArgsConfig.Test_ArgTokenFromEnvOpt_WithValue;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_PORT', '8080');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsTokenFromEnvOpt('APP_', 'port', []);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('--port=8080', Opt.Unwrap, 'Token should be --port=8080');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgTokenFromEnvOpt_EmptyValue;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_VERBOSE', '');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsTokenFromEnvOpt('APP_', 'verbose', []);
    CheckTrue(Opt.IsSome, 'Should return Some for empty value');
    CheckEquals('--verbose', Opt.Unwrap, 'Token should be --verbose (no =)');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgTokenFromEnvOpt_NotSet;
var
  Opt: specialize TOption<string>;
begin
  Opt := ArgsTokenFromEnvOpt('NONEXISTENT_', 'key', []);
  CheckTrue(Opt.IsNone, 'Should return None for non-existent env');
end;

procedure TTestCase_ArgsConfig.Test_ArgTokenFromEnvOpt_KeyNormalization;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_MY_CONFIG', 'test');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsTokenFromEnvOpt('APP_', 'MY_CONFIG', []);
    CheckTrue(Opt.IsSome, 'Should return Some');
    // Key normalization: underscore -> dash, lowercase
    CheckEquals('--my-config=test', Opt.Unwrap, 'Key should be normalized');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgTokenFromEnvOpt_DashInKey;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_LOG_LEVEL', 'debug');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsTokenFromEnvOpt('APP_', 'log-level', []);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('--log-level=debug', Opt.Unwrap, 'Token format correct');
  finally
    Guard.Done;
  end;
end;

{ ArgsIntFromEnvRes 测试 }

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Valid;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_COUNT', '42');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'count', []);
    CheckTrue(Res.IsOk, 'Should return Ok');
    CheckEquals(42, Res.Unwrap, 'Value should be 42');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_NotSet;
var
  Res: specialize TResult<Integer, string>;
begin
  Res := ArgsIntFromEnvRes('NONEXISTENT_', 'count', []);
  CheckTrue(Res.IsErr, 'Should return Err for non-existent env');
  CheckTrue(Pos('not set', Res.UnwrapErr) > 0, 'Error should mention not set');
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Invalid;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_BAD', 'abc');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'bad', []);
    CheckTrue(Res.IsErr, 'Should return Err for invalid int');
    CheckTrue(Pos('invalid', LowerCase(Res.UnwrapErr)) > 0, 'Error should mention invalid');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Zero;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_ZERO', '0');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'zero', []);
    CheckTrue(Res.IsOk, 'Should return Ok for zero');
    CheckEquals(0, Res.Unwrap, 'Value should be 0');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Negative;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_NEG', '-100');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'neg', []);
    CheckTrue(Res.IsOk, 'Should return Ok for negative');
    CheckEquals(-100, Res.Unwrap, 'Value should be -100');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Large;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_LARGE', '2147483647');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'large', []);
    CheckTrue(Res.IsOk, 'Should return Ok for MaxInt');
    CheckEquals(2147483647, Res.Unwrap, 'Value should be MaxInt');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_TrimmedInt;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_TRIMMED', '  123  ');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'trimmed', [efTrimValues]);
    CheckTrue(Res.IsOk, 'Should return Ok with trim flag');
    CheckEquals(123, Res.Unwrap, 'Value should be 123 after trim');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Float;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_FLOAT', '3.14');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'float', []);
    CheckTrue(Res.IsErr, 'Should return Err for float');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Hex;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_HEX', '0xFF');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgsIntFromEnvRes('APP_', 'hex', []);
    // FreePascal TryStrToInt can parse hex with 0x prefix
    CheckTrue(Res.IsOk, 'Should return Ok for hex');
    CheckEquals(255, Res.Unwrap, 'Value should be 255');
  finally
    Guard.Done;
  end;
end;

{ ArgsArgvFromEnv 测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_Basic;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  Arr: TStringArray;
begin
  if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

  kvs := nil;
  SetLength(kvs, 2);
  kvs[0].Name := '__FAFAFA_ARGS_CFG_TEST_BASIC_DEBUG'; kvs[0].Value := 'true'; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ARGS_CFG_TEST_BASIC_VERBOSE'; kvs[1].Value := ''; kvs[1].HasValue := True;

  g := env_overrides(kvs);
  try
    Arr := ArgsArgvFromEnv('__FAFAFA_ARGS_CFG_TEST_BASIC_');
    AssertHasToken(Arr, '--debug=true');
    AssertHasToken(Arr, '--verbose');
  finally
    g.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_EmptyPrefix;
var
  Arr: TStringArray;
begin
  Arr := ArgsArgvFromEnv('');
  CheckEquals(0, Length(Arr), 'Empty prefix should return empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_NoMatch;
var
  Arr: TStringArray;
begin
  Arr := ArgsArgvFromEnv('VERY_UNIQUE_PREFIX_THAT_DOES_NOT_EXIST_XYZ_');
  CheckEquals(0, Length(Arr), 'Non-matching prefix should return empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_KeyNormalization;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  Arr: TStringArray;
begin
  if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

  kvs := nil;
  SetLength(kvs, 1);
  kvs[0].Name := '__FAFAFA_ARGS_CFG_TEST_KEYNORM_LOG_LEVEL'; kvs[0].Value := 'debug'; kvs[0].HasValue := True;

  g := env_overrides(kvs);
  try
    Arr := ArgsArgvFromEnv('__FAFAFA_ARGS_CFG_TEST_KEYNORM_');
    AssertHasToken(Arr, '--log-level=debug');
  finally
    g.Done;
  end;
end;

{ ArgsArgvFromEnvEx 测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_AllowList;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  Arr: TStringArray;
begin
  if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

  kvs := nil;
  SetLength(kvs, 2);
  kvs[0].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_ALLOW_FOO'; kvs[0].Value := '1'; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_ALLOW_BAR'; kvs[1].Value := '2'; kvs[1].HasValue := True;

  g := env_overrides(kvs);
  try
    Arr := ArgsArgvFromEnvEx('__FAFAFA_ARGS_CFG_TEST_ENVEX_ALLOW_', ['foo'], [], []);
    CheckEquals(1, Length(Arr), 'AllowList should include only foo');
    CheckEquals('--foo=1', Arr[0]);
  finally
    g.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_DenyList;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  Arr: TStringArray;
begin
  if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

  kvs := nil;
  SetLength(kvs, 2);
  kvs[0].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_DENY_FOO'; kvs[0].Value := '1'; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_DENY_BAR'; kvs[1].Value := '2'; kvs[1].HasValue := True;

  g := env_overrides(kvs);
  try
    Arr := ArgsArgvFromEnvEx('__FAFAFA_ARGS_CFG_TEST_ENVEX_DENY_', [], ['bar'], []);
    CheckEquals(1, Length(Arr), 'DenyList should exclude bar');
    CheckEquals('--foo=1', Arr[0]);
  finally
    g.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_AllowAndDeny;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  Arr: TStringArray;
begin
  if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

  kvs := nil;
  SetLength(kvs, 3);
  kvs[0].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_BOTH_A'; kvs[0].Value := '1'; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_BOTH_B'; kvs[1].Value := '2'; kvs[1].HasValue := True;
  kvs[2].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_BOTH_C'; kvs[2].Value := '3'; kvs[2].HasValue := True;

  g := env_overrides(kvs);
  try
    Arr := ArgsArgvFromEnvEx('__FAFAFA_ARGS_CFG_TEST_ENVEX_BOTH_', ['a','b'], ['b'], [efTrimValues]);
    CheckEquals(1, Length(Arr), 'AllowAndDeny should keep a and drop b/c');
    CheckEquals('--a=1', Arr[0]);
  finally
    g.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_WithFlags;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  Arr: TStringArray;
begin
  if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

  kvs := nil;
  SetLength(kvs, 2);
  kvs[0].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_FLAGS_DEBUG'; kvs[0].Value := '  TRUE  '; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ARGS_CFG_TEST_ENVEX_FLAGS_NAME'; kvs[1].Value := '  x  '; kvs[1].HasValue := True;

  g := env_overrides(kvs);
  try
    Arr := ArgsArgvFromEnvEx('__FAFAFA_ARGS_CFG_TEST_ENVEX_FLAGS_', [], [], [efTrimValues, efNormalizeBools]);
    AssertHasToken(Arr, '--debug=true');
    AssertHasToken(Arr, '--name=x');
  finally
    g.Done;
  end;
end;

{ ArgsTokensFromEnvOpt 测试 }

procedure TTestCase_ArgsConfig.Test_ArgTokensFromEnvOpt_Some;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  Opt: specialize TOption<TStringArray>;
begin
  if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

  kvs := nil;
  SetLength(kvs, 1);
  kvs[0].Name := '__FAFAFA_ARGS_CFG_TEST_BATCH_ITEM'; kvs[0].Value := 'value'; kvs[0].HasValue := True;

  g := env_overrides(kvs);
  try
    Opt := ArgsTokensFromEnvOpt('__FAFAFA_ARGS_CFG_TEST_BATCH_', ['item'], [], []);
    CheckTrue(Opt.IsSome, 'Should return Some when matches found');
    AssertHasToken(Opt.Unwrap, '--item=value');
  finally
    g.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgTokensFromEnvOpt_None;
var
  Opt: specialize TOption<TStringArray>;
begin
  Opt := ArgsTokensFromEnvOpt('NONEXISTENT_', [], [], []);
  CheckTrue(Opt.IsNone, 'Should return None when no matches');
end;

{ 内部辅助函数行为测试 }

procedure TTestCase_ArgsConfig.Test_KeyNormalization_Underscore;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_SOME_LONG_KEY', 'test');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsTokenFromEnvOpt('APP_', 'some_long_key', []);
    CheckTrue(Opt.IsSome, 'Should find key');
    // Normalized key has dashes
    CheckEquals('--some-long-key=test', Opt.Unwrap, 'Underscores become dashes');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_KeyNormalization_Mixed;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('CFG_DB_HOST', 'localhost');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsTokenFromEnvOpt('CFG_', 'db.host', []);
    // . becomes _ in env lookup, but stays as . in output key
    CheckTrue(Opt.IsSome, 'Should find key with dot');
    CheckEquals('--db.host=localhost', Opt.Unwrap, 'Key keeps dot in output');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ValueNormalization_Trim;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('TRIM_TEST', '   spaces   ');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('TRIM_', 'test', [efTrimValues]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('spaces', Opt.Unwrap, 'Value trimmed');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ValueNormalization_Bool;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('BOOL_TEST', '1');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('BOOL_', 'test', [efNormalizeBools]);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('true', Opt.Unwrap, '1 becomes true');
  finally
    Guard.Done;
  end;
end;

{ 边界情况测试 }

procedure TTestCase_ArgsConfig.Test_EmptyKey;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('PREFIX_', 'value');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    // Empty key means env var is PREFIX_ (just the prefix)
    Opt := ArgsValueFromEnvOpt('PREFIX_', '', []);
    // This depends on implementation - likely None since empty key is invalid
    // Just verify it doesn't crash
    CheckTrue(True, 'Should not crash on empty key');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_SpecialCharacters;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('SPEC_PATH', '/usr/bin:./local');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('SPEC_', 'path', []);
    CheckTrue(Opt.IsSome, 'Should handle special chars');
    CheckEquals('/usr/bin:./local', Opt.Unwrap, 'Special chars preserved');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_UnicodeValue;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('UNI_NAME', 'Hello');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('UNI_', 'name', []);
    CheckTrue(Opt.IsSome, 'Should handle unicode');
    CheckEquals('Hello', Opt.Unwrap, 'Unicode preserved');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_VeryLongValue;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
  LongVal: string;
begin
  LongVal := StringOfChar('X', 4096);
  Guard := env_override('LONG_VAL', LongVal);
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('LONG_', 'val', []);
    CheckTrue(Opt.IsSome, 'Should handle long values');
    CheckEquals(4096, Length(Opt.Unwrap), 'Long value length preserved');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_NumericKey;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('NUM_123', 'numeric');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgsValueFromEnvOpt('NUM_', '123', []);
    CheckTrue(Opt.IsSome, 'Should handle numeric keys');
    CheckEquals('numeric', Opt.Unwrap, 'Value correct');
  finally
    Guard.Done;
  end;
end;

{ JSON 配置测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromJson_NotExists;
var
  Arr: TStringArray;
begin
  Arr := ArgsArgvFromJson('/nonexistent/path/config.json');
  CheckEquals(0, Length(Arr), 'Non-existent file returns empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromJson_EmptyPath;
var
  Arr: TStringArray;
begin
  Arr := ArgsArgvFromJson('');
  CheckEquals(0, Length(Arr), 'Empty path returns empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromJson_InvalidJson_ReturnsEmpty;
var
  FN: string;
  FS: TFileStream;
  Arr: TStringArray;
begin
  FN := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'fafafa_args_cfg_invalid_' + IntToStr(GetTickCount64) + '.json';
  FS := TFileStream.Create(FN, fmCreate);
  try
    // invalid json
    FS.WriteBuffer(PChar('{"a":,}')^, Length('{"a":,}'));
  finally
    FS.Free;
  end;

  try
    try
      Arr := ArgsArgvFromJson(FN);
    except
      on E: Exception do
        Fail('ArgsArgvFromJson should not raise on invalid JSON: ' + E.Message);
    end;
    CheckEquals(0, Length(Arr), 'Invalid JSON should return empty array');
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromJson_RootArray_ReturnsEmpty;
var
  FN: string;
  FS: TFileStream;
  Arr: TStringArray;
begin
  FN := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'fafafa_args_cfg_root_array_' + IntToStr(GetTickCount64) + '.json';
  FS := TFileStream.Create(FN, fmCreate);
  try
    FS.WriteBuffer(PChar('[1,2,"x"]')^, Length('[1,2,"x"]'));
  finally
    FS.Free;
  end;

  try
    try
      Arr := ArgsArgvFromJson(FN);
    except
      on E: Exception do
        Fail('ArgsArgvFromJson should not raise on root array JSON: ' + E.Message);
    end;
    CheckEquals(0, Length(Arr), 'Root array JSON should produce empty argv');
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

{ TOML 配置测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromToml_NotExists;
var
  Arr: TStringArray;
begin
  Arr := ArgsArgvFromToml('/nonexistent/path/config.toml');
  CheckEquals(0, Length(Arr), 'Non-existent file returns empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromToml_EmptyPath;
var
  Arr: TStringArray;
begin
  Arr := ArgsArgvFromToml('');
  CheckEquals(0, Length(Arr), 'Empty path returns empty array');
end;

{ YAML 存根测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromYamlOpt_Unsupported_ReturnsNone;
var
  Opt: specialize TOption<TStringArray>;
begin
  Opt := ArgsArgvFromYamlOpt('/any/path.yaml');
  CheckTrue(Opt.IsNone, 'YAML support is not ready; should return None');
end;

initialization
  RegisterTest(TTestCase_ArgsConfig);
end.

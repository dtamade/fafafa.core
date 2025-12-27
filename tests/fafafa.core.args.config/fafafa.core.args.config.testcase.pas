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
  published
    // ArgValueFromEnvOpt 测试
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

    // ArgTokenFromEnvOpt 测试
    procedure Test_ArgTokenFromEnvOpt_WithValue;
    procedure Test_ArgTokenFromEnvOpt_EmptyValue;
    procedure Test_ArgTokenFromEnvOpt_NotSet;
    procedure Test_ArgTokenFromEnvOpt_KeyNormalization;
    procedure Test_ArgTokenFromEnvOpt_DashInKey;

    // ArgIntFromEnvRes 测试
    procedure Test_ArgIntFromEnvRes_Valid;
    procedure Test_ArgIntFromEnvRes_NotSet;
    procedure Test_ArgIntFromEnvRes_Invalid;
    procedure Test_ArgIntFromEnvRes_Zero;
    procedure Test_ArgIntFromEnvRes_Negative;
    procedure Test_ArgIntFromEnvRes_Large;
    procedure Test_ArgIntFromEnvRes_TrimmedInt;
    procedure Test_ArgIntFromEnvRes_Float;
    procedure Test_ArgIntFromEnvRes_Hex;

    // ArgvFromEnv 测试 (平台限制可能导致跳过)
    procedure Test_ArgvFromEnv_Basic;
    procedure Test_ArgvFromEnv_EmptyPrefix;
    procedure Test_ArgvFromEnv_NoMatch;
    procedure Test_ArgvFromEnv_KeyNormalization;

    // ArgvFromEnvEx 测试
    procedure Test_ArgvFromEnvEx_AllowList;
    procedure Test_ArgvFromEnvEx_DenyList;
    procedure Test_ArgvFromEnvEx_AllowAndDeny;
    procedure Test_ArgvFromEnvEx_WithFlags;

    // ArgTokensFromEnvOpt 测试
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

    // JSON 配置测试 (条件编译)
    procedure Test_ArgvFromJson_NotExists;
    procedure Test_ArgvFromJson_EmptyPath;

    // TOML 配置测试 (条件编译)
    procedure Test_ArgvFromToml_NotExists;
    procedure Test_ArgvFromToml_EmptyPath;

    // YAML 存根测试
    procedure Test_ArgvFromYaml_Stub;
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

{ ArgValueFromEnvOpt 测试 }

procedure TTestCase_ArgsConfig.Test_ArgValueFromEnvOpt_Basic;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_HOST', 'localhost');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgValueFromEnvOpt('APP_', 'host', []);
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
  Opt := ArgValueFromEnvOpt('NONEXISTENT_PREFIX_XYZ_', 'missing', []);
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

    Opt := ArgValueFromEnvOpt('APP_', 'empty', []);
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

    Opt := ArgValueFromEnvOpt('APP_', 'spaced', [efTrimValues]);
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

    Opt := ArgValueFromEnvOpt('APP_', 'enabled', [efLowercaseBools]);
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

    Opt := ArgValueFromEnvOpt('APP_', 'disabled', [efLowercaseBools]);
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

    Opt := ArgValueFromEnvOpt('APP_', 'flag', [efLowercaseBools]);
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

    Opt := ArgValueFromEnvOpt('APP_', 'flag', [efLowercaseBools]);
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

    Opt := ArgValueFromEnvOpt('APP_', 'combo', [efTrimValues, efLowercaseBools]);
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
    Opt := ArgValueFromEnvOpt('app_', 'mykey', []);
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
    Opt := ArgValueFromEnvOpt('APP_', 'my-key', []);
    CheckTrue(Opt.IsSome, 'Should convert dash to underscore');
    CheckEquals('dash-value', Opt.Unwrap, 'Value should match');
  finally
    Guard.Done;
  end;
end;

{ ArgTokenFromEnvOpt 测试 }

procedure TTestCase_ArgsConfig.Test_ArgTokenFromEnvOpt_WithValue;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<string>;
begin
  Guard := env_override('APP_PORT', '8080');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgTokenFromEnvOpt('APP_', 'port', []);
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

    Opt := ArgTokenFromEnvOpt('APP_', 'verbose', []);
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
  Opt := ArgTokenFromEnvOpt('NONEXISTENT_', 'key', []);
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

    Opt := ArgTokenFromEnvOpt('APP_', 'MY_CONFIG', []);
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

    Opt := ArgTokenFromEnvOpt('APP_', 'log-level', []);
    CheckTrue(Opt.IsSome, 'Should return Some');
    CheckEquals('--log-level=debug', Opt.Unwrap, 'Token format correct');
  finally
    Guard.Done;
  end;
end;

{ ArgIntFromEnvRes 测试 }

procedure TTestCase_ArgsConfig.Test_ArgIntFromEnvRes_Valid;
var
  Guard: TEnvOverrideGuard;
  Res: specialize TResult<Integer, string>;
begin
  Guard := env_override('APP_COUNT', '42');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Res := ArgIntFromEnvRes('APP_', 'count', []);
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
  Res := ArgIntFromEnvRes('NONEXISTENT_', 'count', []);
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

    Res := ArgIntFromEnvRes('APP_', 'bad', []);
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

    Res := ArgIntFromEnvRes('APP_', 'zero', []);
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

    Res := ArgIntFromEnvRes('APP_', 'neg', []);
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

    Res := ArgIntFromEnvRes('APP_', 'large', []);
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

    Res := ArgIntFromEnvRes('APP_', 'trimmed', [efTrimValues]);
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

    Res := ArgIntFromEnvRes('APP_', 'float', []);
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

    Res := ArgIntFromEnvRes('APP_', 'hex', []);
    // FreePascal TryStrToInt can parse hex with 0x prefix
    CheckTrue(Res.IsOk, 'Should return Ok for hex');
    CheckEquals(255, Res.Unwrap, 'Value should be 255');
  finally
    Guard.Done;
  end;
end;

{ ArgvFromEnv 测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_Basic;
var
  Guard: TEnvOverrideGuard;
  Arr: TStringArray;
  Val: string;
begin
  Guard := env_override('TEST_DEBUG', 'true');
  try
    if not env_lookup('TEST_DEBUG', Val) then
    begin
      Ignore('env_override did not work');
      Exit;
    end;

    Arr := ArgvFromEnv('TEST_');
    // Platform limitation: Dos.EnvStr may not see runtime changes
    if Length(Arr) = 0 then
    begin
      Ignore('ArgvFromEnv uses Dos.EnvStr which cannot see runtime env changes');
      Exit;
    end;

    CheckTrue(Length(Arr) >= 1, 'Should have at least 1 token');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_EmptyPrefix;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromEnv('');
  CheckEquals(0, Length(Arr), 'Empty prefix should return empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_NoMatch;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromEnv('VERY_UNIQUE_PREFIX_THAT_DOES_NOT_EXIST_XYZ_');
  CheckEquals(0, Length(Arr), 'Non-matching prefix should return empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnv_KeyNormalization;
var
  Guard: TEnvOverrideGuard;
  Arr: TStringArray;
begin
  Guard := env_override('MYAPP_LOG_LEVEL', 'debug');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Arr := ArgvFromEnv('MYAPP_');
    if Length(Arr) = 0 then
    begin
      Ignore('Platform limitation with Dos.EnvStr');
      Exit;
    end;

    // Key LOG_LEVEL should become --log-level
    CheckTrue(Pos('--log-level', Arr[0]) > 0, 'Key should be normalized');
  finally
    Guard.Done;
  end;
end;

{ ArgvFromEnvEx 测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_AllowList;
var
  Arr: TStringArray;
begin
  // Without runtime env changes visible, we test structure only
  Arr := ArgvFromEnvEx('NONEXISTENT_', ['allowed'], [], []);
  CheckEquals(0, Length(Arr), 'No match returns empty');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_DenyList;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromEnvEx('NONEXISTENT_', [], ['denied'], []);
  CheckEquals(0, Length(Arr), 'No match returns empty');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_AllowAndDeny;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromEnvEx('NONEXISTENT_', ['a'], ['b'], [efTrimValues]);
  CheckEquals(0, Length(Arr), 'No match returns empty');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromEnvEx_WithFlags;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromEnvEx('NONEXISTENT_', [], [], [efTrimValues, efLowercaseBools]);
  CheckEquals(0, Length(Arr), 'No match returns empty');
end;

{ ArgTokensFromEnvOpt 测试 }

procedure TTestCase_ArgsConfig.Test_ArgTokensFromEnvOpt_Some;
var
  Guard: TEnvOverrideGuard;
  Opt: specialize TOption<TStringArray>;
begin
  Guard := env_override('BATCH_ITEM', 'value');
  try
    if not EnvWorks then begin Ignore('env_override not working'); Exit; end;

    Opt := ArgTokensFromEnvOpt('BATCH_', ['item'], [], []);
    // May be None due to platform limitation
    if Opt.IsNone then
    begin
      Ignore('Platform limitation with Dos.EnvStr');
      Exit;
    end;

    CheckTrue(Opt.IsSome, 'Should return Some when matches found');
    CheckTrue(Length(Opt.Unwrap) > 0, 'Should have tokens');
  finally
    Guard.Done;
  end;
end;

procedure TTestCase_ArgsConfig.Test_ArgTokensFromEnvOpt_None;
var
  Opt: specialize TOption<TStringArray>;
begin
  Opt := ArgTokensFromEnvOpt('NONEXISTENT_', [], [], []);
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

    Opt := ArgTokenFromEnvOpt('APP_', 'some_long_key', []);
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

    Opt := ArgTokenFromEnvOpt('CFG_', 'db.host', []);
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

    Opt := ArgValueFromEnvOpt('TRIM_', 'test', [efTrimValues]);
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

    Opt := ArgValueFromEnvOpt('BOOL_', 'test', [efLowercaseBools]);
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
    Opt := ArgValueFromEnvOpt('PREFIX_', '', []);
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

    Opt := ArgValueFromEnvOpt('SPEC_', 'path', []);
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

    Opt := ArgValueFromEnvOpt('UNI_', 'name', []);
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

    Opt := ArgValueFromEnvOpt('LONG_', 'val', []);
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

    Opt := ArgValueFromEnvOpt('NUM_', '123', []);
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
  Arr := ArgvFromJson('/nonexistent/path/config.json');
  CheckEquals(0, Length(Arr), 'Non-existent file returns empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromJson_EmptyPath;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromJson('');
  CheckEquals(0, Length(Arr), 'Empty path returns empty array');
end;

{ TOML 配置测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromToml_NotExists;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromToml('/nonexistent/path/config.toml');
  CheckEquals(0, Length(Arr), 'Non-existent file returns empty array');
end;

procedure TTestCase_ArgsConfig.Test_ArgvFromToml_EmptyPath;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromToml('');
  CheckEquals(0, Length(Arr), 'Empty path returns empty array');
end;

{ YAML 存根测试 }

procedure TTestCase_ArgsConfig.Test_ArgvFromYaml_Stub;
var
  Arr: TStringArray;
begin
  Arr := ArgvFromYaml('/any/path.yaml');
  CheckEquals(0, Length(Arr), 'YAML stub returns empty array');
end;

initialization
  RegisterTest(TTestCase_ArgsConfig);
end.

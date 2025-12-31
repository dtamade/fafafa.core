unit Test_core_env_filtering;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args.config,
  fafafa.core.env;

type
  TTestCase_Core_EnvFiltering = class(TTestCase)
  private
    function HasToken(const Tokens: array of string; const Tok: string): Boolean;
  published
    procedure Test_Allow_Filter_Includes_Only_Allowed;
    procedure Test_Deny_Filter_Excludes_Denied;
    procedure Test_Flags_Trim_And_BoolLowercase;
    procedure Test_EmptyValue_Becomes_SwitchToken;
  end;

procedure RegisterTests;

implementation

function TTestCase_Core_EnvFiltering.HasToken(const Tokens: array of string; const Tok: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(Tokens) do
    if Tokens[I] = Tok then
      Exit(True);
  Result := False;
end;

procedure RegisterTests;
begin
  testregistry.RegisterTest(TTestCase_Core_EnvFiltering);
end;

procedure TTestCase_Core_EnvFiltering.Test_Allow_Filter_Includes_Only_Allowed;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  tokens: array of string;
begin
  kvs := nil;
  SetLength(kvs, 2);
  kvs[0].Name := '__FAFAFA_ENV_FILTER_TEST_FOO'; kvs[0].Value := '1'; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ENV_FILTER_TEST_BAR'; kvs[1].Value := '2'; kvs[1].HasValue := True;

  g := env_overrides(kvs);
  try
    tokens := ArgsArgvFromEnvEx('__FAFAFA_ENV_FILTER_TEST_', ['foo'], [], []);
    // expect only --foo=1
    AssertEquals(1, Length(tokens));
    AssertEquals('--foo=1', tokens[0]);
  finally
    g.Done;
  end;
end;

procedure TTestCase_Core_EnvFiltering.Test_Deny_Filter_Excludes_Denied;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  tokens: array of string;
begin
  kvs := nil;
  SetLength(kvs, 2);
  kvs[0].Name := '__FAFAFA_ENV_FILTER_TEST_FOO'; kvs[0].Value := '1'; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ENV_FILTER_TEST_BAR'; kvs[1].Value := '2'; kvs[1].HasValue := True;

  g := env_overrides(kvs);
  try
    tokens := ArgsArgvFromEnvEx('__FAFAFA_ENV_FILTER_TEST_', [], ['bar'], []);
    // expect only --foo=1
    AssertEquals(1, Length(tokens));
    AssertEquals('--foo=1', tokens[0]);
  finally
    g.Done;
  end;
end;

procedure TTestCase_Core_EnvFiltering.Test_Flags_Trim_And_BoolLowercase;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  tokens: array of string;
begin
  kvs := nil;
  SetLength(kvs, 2);
  kvs[0].Name := '__FAFAFA_ENV_FILTER_TEST_DEBUG'; kvs[0].Value := '  TRUE  '; kvs[0].HasValue := True;
  kvs[1].Name := '__FAFAFA_ENV_FILTER_TEST_NAME'; kvs[1].Value := '  x  '; kvs[1].HasValue := True;

  g := env_overrides(kvs);
  try
    tokens := ArgsArgvFromEnvEx('__FAFAFA_ENV_FILTER_TEST_', [], [], [efTrimValues, efNormalizeBools]);
    AssertTrue(HasToken(tokens, '--debug=true'));
    AssertTrue(HasToken(tokens, '--name=x'));
  finally
    g.Done;
  end;
end;

procedure TTestCase_Core_EnvFiltering.Test_EmptyValue_Becomes_SwitchToken;
var
  g: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  tokens: array of string;
begin
  kvs := nil;
  SetLength(kvs, 1);
  kvs[0].Name := '__FAFAFA_ENV_FILTER_TEST_EMPTY'; kvs[0].Value := ''; kvs[0].HasValue := True;

  g := env_overrides(kvs);
  try
    tokens := ArgsArgvFromEnvEx('__FAFAFA_ENV_FILTER_TEST_', [], [], [efTrimValues]);
    AssertTrue(HasToken(tokens, '--empty'));
  finally
    g.Done;
  end;
end;

end.


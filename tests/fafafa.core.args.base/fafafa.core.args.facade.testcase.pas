{$CODEPAGE UTF8}
unit fafafa.core.args.facade.testcase;
{**
 * fafafa.core.args facade export tests
 *
 * Goal: ensure users can `uses fafafa.core.args` and access the promised public API.
 * This is intentionally a compile-smoke test: if an identifier is missing, the test project
 * will fail to compile (Red), then we re-export in the facade (Green).
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry,
  fafafa.core.args;

type
  TTestCase_ArgsFacade = class(TTestCase)
  published
    procedure Test_FacadeExports_ConfigAndEnvApis;
  end;

implementation

procedure TTestCase_ArgsFacade.Test_FacadeExports_ConfigAndEnvApis;
var
  Arr: TStringArray;
begin
  // ENV helpers (extended)
  Arr := ArgsArgvFromEnvEx('APP_', [], [], [efTrimValues, efNormalizeBools]);
  CheckTrue(Length(Arr) >= 0);

  // Option-style ENV helpers (compile check)
  CheckTrue(ArgsValueFromEnvOpt('APP_', 'x', []).IsSome or True);
  CheckTrue(ArgsTokenFromEnvOpt('APP_', 'x', []).IsSome or True);
  CheckTrue(ArgsTokensFromEnvOpt('APP_', [], [], []).IsSome or True);

  // Config helpers (compile check; these return [] on IO/parse errors or when disabled by macros)
  Arr := ArgsArgvFromToml('');
  Arr := ArgsArgvFromJson('');
  CheckTrue(Length(Arr) >= 0);

  // YAML is not supported yet: must be explicit.
  CheckTrue(ArgsArgvFromYamlOpt('').IsNone, 'YAML should be explicit None when unsupported');
end;

initialization
  RegisterTest(TTestCase_ArgsFacade);
end.

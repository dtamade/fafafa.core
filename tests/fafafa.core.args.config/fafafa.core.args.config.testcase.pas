{$CODEPAGE UTF8}
unit fafafa.core.args.config.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  Classes,
  fafafa.core.args.config,
  fafafa.core.env,
  fafafa.core.option,
  fafafa.core.result;

type
  TTestCase_ArgsConfig = class(TTestCase)
  published
    procedure Test_ArgValue_Token_Int_WithEnv;
  end;

implementation

procedure TTestCase_ArgsConfig.Test_ArgValue_Token_Int_WithEnv;
var
  Guard: TEnvOverrideGuard;
  OptV, OptTok: specialize TOption<string>;
  ResInt: specialize TResult<Integer,string>;
  Arr: array of string;
  OptArr: specialize TOption<TStringArray>;
begin
  // Prepare env: APP_PORT=42, APP_NAME=""
  Guard := env_override('APP_PORT', '42');
  try
    env_set('APP_NAME', '');

    OptV := ArgValueFromEnvOpt('APP_', 'port', [efTrimValues, efLowercaseBools]);
    CheckTrue(OptV.IsSome);
    CheckEquals('42', OptV.Unwrap);

    OptTok := ArgTokenFromEnvOpt('APP_', 'name', []);
    CheckTrue(OptTok.IsSome);
    CheckEquals('--name', OptTok.Unwrap);

    ResInt := ArgIntFromEnvRes('APP_', 'port', []);
    CheckTrue(ResInt.IsOk);
    CheckEquals(42, ResInt.Unwrap);

    Arr := ArgvFromEnv('APP_');
    OptArr := ArgTokensFromEnvOpt('APP_', [], [], []);
    CheckTrue(Length(Arr) >= 1);
    if OptArr.IsSome then CheckTrue(Length(OptArr.Unwrap) >= 1);
  finally
    Guard.Done;
    env_unset('APP_NAME');
  end;
end;

initialization
  RegisterTest(TTestCase_ArgsConfig);
end.


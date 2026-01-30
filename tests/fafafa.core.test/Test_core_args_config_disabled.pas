unit Test_core_args_config_disabled;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.args.config,
  args_test_helper;

procedure RegisterTests;

implementation

type
  TTestCase_Core_Args_Config_Disabled = class(TTestCase)
  published
    procedure Test_Json_Toml_Return_Empty_When_Macros_Disabled;
  end;

procedure TTestCase_Core_Args_Config_Disabled.Test_Json_Toml_Return_Empty_When_Macros_Disabled;
var arr: array of string; tmp: array of string;
begin
  if IsJsonArgvSupported or IsTomlArgvSupported then
  begin
    // If any is supported, skip this test in current build
    Exit;
  end;
  arr := ArgsArgvFromJson('nonexistent.json');
  AssertEquals('ArgsArgvFromJson should return empty when FAFAFA_ARGS_CONFIG_JSON is not defined', 0, Length(arr));
  tmp := ArgsArgvFromToml('nonexistent.toml');
  AssertEquals('ArgsArgvFromToml should return empty when FAFAFA_ARGS_CONFIG_TOML is not defined', 0, Length(tmp));
end;

procedure RegisterTests;
begin
  RegisterTest('TTestCase_Core_Args_Config_Disabled', TTestCase_Core_Args_Config_Disabled.Suite);
end;

end.


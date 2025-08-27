program min_forin_tests;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  SysUtils, consoletestrunner, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json,
  Test_fafafa_core_json_facade_forin;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Run;
  finally
    Application.Free;
  end;
end.


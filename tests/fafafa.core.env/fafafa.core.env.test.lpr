{$CODEPAGE UTF8}
program fafafa_core_env_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.env.testcase;

begin
  // FPCUnit 控制台运行器
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
  // Avoid heaptrc call traces in --list mode
  testregistry.GetTestRegistry.Free;
end.


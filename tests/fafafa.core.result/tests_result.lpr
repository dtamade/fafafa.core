{$CODEPAGE UTF8}
program tests_result;

{$mode objfpc}{$H+}

uses
  SysUtils, consoletestrunner,
  Test_fafafa_core_result;

var
  Application: TTestRunner;
begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Title := 'FPCUnit Console test runner for fafafa.core.result';
  Application.Initialize;
  Application.Run;
  Application.Free;
  // Avoid heaptrc call traces in --list mode
  testregistry.GetTestRegistry.Free;
end.


{$CODEPAGE UTF8}
program tests_result;

{$mode objfpc}{$H+}

uses
  SysUtils, consoletestrunner, testregistry,
  fafafa.core.result.testcase;

var
  Application: TTestRunner;
begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Title := 'FPCUnit Console test runner for fafafa.core.result';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.


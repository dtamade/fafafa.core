program fafafa.core.args.help.test;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  fafafa.core.args.help.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.args.help Test Suite';
  Application.Run;
  Application.Free;
end.

{$CODEPAGE UTF8}
program fafafa.core.time.isoweek.test;

{$mode objfpc}{$H+}

uses
  Classes,
  consoletestrunner,
  Test_TIsoWeek;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'TIsoWeek Test Runner';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

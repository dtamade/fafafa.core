{$CODEPAGE UTF8}
program fafafa.core.time.roundtrip.test;

{$mode objfpc}{$H+}

uses
  Classes,
  consoletestrunner,
  Test_Roundtrip;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'Roundtrip Consistency Test Runner (ISSUE-45)';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

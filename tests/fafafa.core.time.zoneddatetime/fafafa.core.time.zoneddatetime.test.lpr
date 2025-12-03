{$CODEPAGE UTF8}
program fafafa.core.time.zoneddatetime.test;

{$mode objfpc}{$H+}

uses
  Classes,
  consoletestrunner,
  Test_TZonedDateTime;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'TZonedDateTime Test Runner';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

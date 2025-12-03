{$CODEPAGE UTF8}
program fafafa.core.time.naivedatetime.test;

{$mode objfpc}{$H+}

uses
  Classes,
  consoletestrunner,
  Test_TNaiveDateTime;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'TNaiveDateTime Test Runner';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

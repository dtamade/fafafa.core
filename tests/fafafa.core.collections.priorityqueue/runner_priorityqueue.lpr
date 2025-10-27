program runner_priorityqueue;

{$mode objfpc}{$H+}{$J-}

uses
  consoletestrunner,
  tests_priorityqueue;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

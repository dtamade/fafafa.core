program tests_math;

{$MODE OBJFPC}{$H+}

uses
  Classes, consoletestrunner,
  fafafa.core.math.testcase,
  fafafa.core.math.float.contract.testcase,
  fafafa.core.math.intutil.testcase,
  fafafa.core.math.dispatch.testcase,
  fafafa.core.math.array_.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.math Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.

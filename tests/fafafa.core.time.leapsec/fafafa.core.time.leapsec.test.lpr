program fafafa.core.time.leapsec.test;

{$MODE OBJFPC}{$H+}

uses
  Classes, consoletestrunner,
  fafafa.core.time.leapsec.testcase;

type
  TMyTestRunner = class(TTestRunner)
  protected
  end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

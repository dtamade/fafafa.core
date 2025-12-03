program fafafa.core.time.offset.test;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  Test_TUtcOffset;

type
  TMyTestRunner = class(TTestRunner)
  protected
  end;

var
  Application: TMyTestRunner;
begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'TUtcOffset Test Runner';
  Application.Run;
  Application.Free;
end.

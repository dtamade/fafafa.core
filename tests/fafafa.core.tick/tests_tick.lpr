{$CODEPAGE UTF8}
program tests_tick;

{$mode objfpc}{$H+}

uses
  Classes,
  consoletestrunner,
  // 测试单元
  Test_tick;

var
  Application: TTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.tick Test Suite';
  Application.Run;
  Application.Free;
end.

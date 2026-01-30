program fafafa.core.time.tick.test;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  fafafa.core.time.tick.test.testcase,
  Test_hardware_tick_reliability;

var
  Application: TTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.time.tick Test Suite';
    Application.Run;
  finally
    Application.Free;
  end;
end.

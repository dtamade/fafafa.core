program fafafa.core.time.tick.test;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  test_tick_core, test_tick_strict;

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

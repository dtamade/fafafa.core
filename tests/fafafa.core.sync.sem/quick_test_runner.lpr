{$CODEPAGE UTF8}
program quick_test_runner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner, fpcunit, testregistry,
  quick_test;

{$IFDEF UNIX}
{$linklib pthread}
{$ENDIF}

var
  App: TTestRunner;

begin
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Run;
  finally
    App.Free;
  end;
end.

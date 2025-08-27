program fafafa.core.sync.semaphore.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner, fpcunit, testregistry,
  fafafa.core.sync.semaphore.testcase;

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


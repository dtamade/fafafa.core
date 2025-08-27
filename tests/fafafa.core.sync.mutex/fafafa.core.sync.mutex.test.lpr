program fafafa.core.sync.mutex.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner, fpcunit, testregistry,
  fafafa.core.sync.mutex.testcase,
  fafafa.core.sync.mutex.advanced.testcase,
  fafafa.core.sync.mutex.extreme.testcase,
  fafafa.core.sync.mutex.concurrency.testcase,
  fafafa.core.sync.mutex.perf.testcase;

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

program fafafa.core.sync.event.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner, fpcunit, testregistry,
  fafafa.core.sync.event.testcase,
  fafafa.core.sync.event.advanced.testcase,
  fafafa.core.sync.event.quick.stress.testcase,
  fafafa.core.sync.event.boundary.testcase,
  fafafa.core.sync.event.exception.enhanced.testcase,
  fafafa.core.sync.event.concurrency.enhanced.testcase;

var
  App: TTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Run;
  finally
    App.Free;
  end;
end.


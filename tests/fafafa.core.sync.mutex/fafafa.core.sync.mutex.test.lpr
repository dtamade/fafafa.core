program fafafa.core.sync.mutex.test;

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner, fpcunit, testregistry,
  fafafa.core.sync.mutex.testcase,
  fafafa.core.sync.mutex.stress;

{$IFDEF UNIX}
{$linklib pthread}
{$ENDIF}

var
  App: TTestRunner;

begin
  DefaultRunAllTests := true;
  DefaultFormat := fPlain;
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Run;
  finally
    App.Free;
  end;
end.

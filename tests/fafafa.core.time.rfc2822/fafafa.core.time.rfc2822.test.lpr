program fafafa.core.time.rfc2822.test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  fpcunit,
  testreport,
  testregistry,
  consoletestrunner,
  fafafa.core.time.rfc2822.testcase;

var
  App: TTestRunner;

begin
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'fafafa.core.time.rfc2822 测试';
    App.Run;
  finally
    App.Free;
  end;
end.

program fafafa.core.time.strftime.test;

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
  fafafa.core.time.strftime.testcase,
  fafafa.core.time.strptime.testcase;

var
  App: TTestRunner;

begin
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'fafafa.core.time.strftime 测试';
    App.Run;
  finally
    App.Free;
  end;
end.

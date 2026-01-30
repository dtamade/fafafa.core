program fafafa.core.time.dst.test;

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
  fafafa.core.time.dst.testcase;

var
  App: TTestRunner;

begin
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'fafafa.core.time.dst 测试';
    App.Run;
  finally
    App.Free;
  end;
end.

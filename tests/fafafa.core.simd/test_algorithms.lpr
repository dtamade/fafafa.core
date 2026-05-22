program test_algorithms;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.simd,
  fafafa.core.simd.algorithms.testcase;

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

program test_stress_pools_runner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, consoletestrunner,
  test_stress_pools;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'Stress Pools Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.

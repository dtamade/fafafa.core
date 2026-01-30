program test_concurrent_pools_runner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, consoletestrunner,
  test_concurrent_pools;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'Concurrent Pools Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.

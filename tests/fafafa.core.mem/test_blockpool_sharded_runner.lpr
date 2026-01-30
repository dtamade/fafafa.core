program test_blockpool_sharded_runner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, consoletestrunner,
  test_blockpool_sharded;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'BlockPool Sharded Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.

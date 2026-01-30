program test_slabpool_sharded_runner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, consoletestrunner,
  test_slabpool_sharded;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'SlabPool Sharded Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.

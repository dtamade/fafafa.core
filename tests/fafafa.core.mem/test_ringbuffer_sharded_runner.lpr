program test_ringbuffer_sharded_runner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, consoletestrunner,
  test_ringbuffer_sharded;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'RingBuffer Sharded Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.

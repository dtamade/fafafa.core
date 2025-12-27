{$CODEPAGE UTF8}
program test_sharded_ringbuffer_runner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils,
  test_sharded_ringbuffer,
  test_sharded_ringbuffer_extended;

begin
  try
    WriteLn('');
    WriteLn('=====================================');
    WriteLn('  Sharded RingBuffer Complete Tests');
    WriteLn('=====================================');

    // Run basic tests first
    test_sharded_ringbuffer.RunAllTests;

    // Run extended tests
    test_sharded_ringbuffer_extended.RunAllExtendedTests;

    WriteLn('');
    WriteLn('All sharded ringbuffer tests completed!');
  except
    on E: Exception do
    begin
      WriteLn('Exception: ', E.Message);
      Halt(1);
    end;
  end;
end.

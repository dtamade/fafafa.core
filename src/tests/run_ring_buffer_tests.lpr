program run_ring_buffer_tests;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  test_ring_buffer_basic,
  test_ring_buffer_try_ops;

begin
  // Register tests
  test_ring_buffer_basic.RegisterRingBufferTests;
  test_ring_buffer_try_ops.RegisterRingBufferTryOpsTests;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.


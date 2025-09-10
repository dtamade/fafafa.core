program run_tests;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  test_json_reader_basic,
  test_json_pointer_basic,
  test_incr_multidoc_basic,
  test_term_ui_surface_basic,
  test_crypto_aead_chacha20poly1305_basic,
  test_chacha20_block_minimal,
  test_atomic_basic,
  test_term_helpers_basic,
  {test_term_events_collect,} // removed: unit not present
  test_term_event_queue_basic,
  test_vec_growth_and_shrink,
  test_element_manager_overflow,
  test_vec_aligned_growth,
  test_vec_shrink_edges,
  test_vec_aligned_toggle,
  test_ring_buffer_basic,
  test_stopwatch_basic,
  test_stopwatch_edges,
  test_timer_scheduler_basic;



begin
  // Register tests from each unit
  test_json_reader_basic.RegisterTests;
  test_json_pointer_basic.RegisterJsonPointerTests;
  test_incr_multidoc_basic.RegisterJsonIncrMultiDocTests;
  test_term_ui_surface_basic.RegisterTermUiSurfaceTests;
  test_crypto_aead_chacha20poly1305_basic.RegisterTests_ChaCha20Poly1305_Basic;
  test_atomic_basic.RegisterAtomicTests;
  // test_term_events_collect.RegisterTermEventsCollectTests; // removed: unit not present
  test_term_event_queue_basic.RegisterTermEventQueueTests;
  test_vec_growth_and_shrink.RegisterVecGrowthAndShrinkTests;
  test_element_manager_overflow.RegisterElementManagerOverflowTests;
  test_vec_aligned_growth.RegisterVecAlignedGrowthTests;
  test_vec_shrink_edges.RegisterVecShrinkEdgeTests;
  test_vec_aligned_toggle.RegisterVecAlignedToggleTests;
  test_ring_buffer_basic.RegisterRingBufferTests;
  test_stopwatch_basic.RegisterStopwatchTests;
  test_stopwatch_edges.RegisterStopwatchEdgeTests;
  test_timer_scheduler_basic.RegisterTimerSchedulerBasicTests;
  {$IFDEF FAFAFA_ENABLE_TOML_TESTS}
  test_toml_basic.RegisterTomlBasicTests;
  {$ENDIF}
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.


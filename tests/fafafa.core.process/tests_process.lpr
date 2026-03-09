program tests_process;

{$mode objfpc}{$H+}
{$WARN 5023 OFF} // 仅关闭“Unit not used (5023)”提示，避免污染构建输出
{$HINTS OFF}
{$NOTES OFF}




uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes,
  consoletestrunner,
  // 测试单元
  test_process,
  test_resource_cleanup,
  test_path_search,
  test_useshellexecute,
  test_environment_block,
  test_builder_simple,
  test_utf8_builder,
  test_pipeline_basic,
  test_pipeline_enhanced,
  {$IFDEF RUN_STRESS}test_pipeline_stress,{$ENDIF}
  test_args_edgecases,
  test_args_edgecases_unix,
  test_args_edgecases_more,
  test_args_edgecases_final,
  test_combined_output,
  test_combined_output_convenience,
  test_capture_all_convenience,
  test_timeout_api,
  {$IFDEF WINDOWS}test_shell_shellexecute_minimal,{$ENDIF}
  test_path_pathext_edgecases,
  test_wait_fastpath,
  test_args_extremes,
  test_env_extremes,
  test_autodrain_postwait,
  test_autodrain_no_drain_read_after_wait,
  test_kill_terminate_finalize,
  test_pipeline_split_capture,
  {$IFDEF WINDOWS}test_process_group_windows,{$ENDIF}
  {$IFDEF WINDOWS}test_process_group_forceonly,{$ENDIF}
  {$IFDEF UNIX}test_process_group_unix_spawn,{$ENDIF}
  test_path_search_unix_ext,
  test_path_search_unix_edges,
  test_graceful_shutdown,
  {$IFDEF UNIX}test_graceful_shutdown_unix,{$ENDIF}
  test_external_stream_integration,
  test_pipeline_errortext_only_err,
  test_lookpath_basic,
  test_lookpath_edges,
  test_autodrain_two_sides_edge,
  test_pipeline_capture_threshold_bigout,
  test_noinherit_minimal,
  test_checked_exit_and_trywait_onexit,
  test_checked_exit_only,
  test_onexit_more,
  test_checked_exit_edges;
var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.process Tests';
  Application.Run;
  Application.Free;
end.

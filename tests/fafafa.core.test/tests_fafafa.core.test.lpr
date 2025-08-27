program tests_fafafa_core_test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  fpcunit, testregistry, args_test_helper,
  // sample test units
  Test_core_test_smoke,
  Test_core_test_listeners,
  Test_core_test_clock,
  Test_core_test_tickclock,
  Test_core_test_assert_cleanup,
  Test_core_test_snapshot_json,
  Test_core_test_assert_ext,
  Test_core_test_snapshot_toml,
  Test_core_test_tempfile,
  Test_core_args,
  Test_core_args_edges,
  Test_core_subcmds,
  Test_core_help_snapshots,
  Test_core_persistent_flags,
  Test_core_env_merge,
  Test_core_persistent_flags_advanced,
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML} Test_core_args_config, {$ENDIF}
  {$IFDEF FAFAFA_ARGS_CONFIG_JSON} Test_core_args_config_json, {$ENDIF}
  Test_core_diagnostics,
  Test_core_args_config_disabled,
  Test_core_env_filtering,
  fafafa.core.args,
  fafafa.core.args.command,
  Test_core_report_sinks_minimal,
  Test_core_report_sinks_junit_minimal;


var
  Application: TTestRunner;
  opts: TArgsOptions;
begin
  // Set global default args options for tests: enable --no-xxx negation
  opts := MakeDefaultOpts;
  ArgsOptionsSetDefault(opts);
  // register tests defined in units
  Test_core_test_smoke.RegisterTests;
  Test_core_test_listeners.RegisterTests;
  Test_core_test_clock.RegisterTests;
  Test_core_test_tickclock.RegisterTests;
  Test_core_test_assert_cleanup.RegisterTests;
  Test_core_test_snapshot_json.RegisterTests;
  Test_core_test_assert_ext.RegisterTests;
  Test_core_test_snapshot_toml.RegisterTests;
  Test_core_test_tempfile.RegisterTests;
  Test_core_report_sinks_minimal.RegisterTests;
  Test_core_report_sinks_junit_minimal.RegisterTests;
  Test_core_args.RegisterTests;
  Test_core_args_edges.RegisterTests;
  Test_core_subcmds.RegisterTests;
  Test_core_help_snapshots.RegisterTests;
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  Test_core_args_config.RegisterTests;
  {$ENDIF}
  {$IFDEF FAFAFA_ARGS_CONFIG_JSON}
  Test_core_args_config_json.RegisterTests;
  {$ENDIF}
  Test_core_diagnostics.RegisterTests;
  Test_core_env_filtering.RegisterTests;

  // Run with FPCUnit console runner for this suite
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.test FPCUnit Suite';
    Application.Run;
  finally
    Application.Free;
  end;
end.


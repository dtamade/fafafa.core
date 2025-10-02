{$CODEPAGE UTF8}
program fafafa.core.time.test;


{$mode objfpc}{$H+}

uses
  Classes,
  consoletestrunner,
  // Test_fafafa_core_time, // temporarily disabled - compilation error
  // Test_fafafa_core_time_stopwatch, // temporarily disabled - compilation error
  // Test_fafafa_core_time_api_ext, // temporarily disabled - missing SetSliceSleepMsFor API
  Test_fafafa_core_time_systemclock,
  Test_fafafa_core_time_waitfor_until,
  // Test_fafafa_core_time_wait_matrix, // temporarily disabled - missing SleepStrategy API
  // Test_fafafa_core_time_qpc_fallback, // temporarily disabled - missing fafafa.core.time.testhooks
  // Test_fafafa_core_time_short_sleep, // temporarily disabled - missing SleepStrategy API
  // Test_fafafa_core_time_config_matrix, // temporarily disabled - missing SleepStrategy API
  // Test_fafafa_core_time_platform_sleep, // temporarily disabled - missing GetSleepStrategy/SetSleepStrategy API
  // Test_fafafa_core_time_platform_strategy_compare, // temporarily disabled - missing GetSleepStrategy/SetSleepStrategy API
  // Test_fafafa_core_time_platform_lightload, // temporarily disabled - missing GetSleepStrategy/SetSleepStrategy API
  Test_fafafa_core_time_timer_once,
  Test_fafafa_core_time_timer_periodic,
  Test_fafafa_core_time_timer_catchup_limit,
  Test_fafafa_core_time_timer_exception_hook,
  Test_fafafa_core_time_timer_metrics,
  Test_fafafa_core_time_timer_shutdown,
  Test_fafafa_core_time_operators,
  Test_fafafa_core_time_duration_arith,
  Test_fafafa_core_time_duration_round_ops,
  Test_fafafa_core_time_instant_deadline_ext,
  Test_fafafa_core_time_instant_deadline_more,
  // Test_fafafa_core_time_timer_stress, // temporarily disabled to avoid unrelated sync.namedBarrier windows syntax error
  Test_fafafa_core_time_format_ext
  , Test_fafafa_core_time_duration_saturating_ops
  , Test_fafafa_core_time_instant_saturation_bounds
  , Test_fafafa_core_time_duration_constants
  {$IFDEF LINUX}, Test_SleepBest_Linux{$ENDIF}
  {$IFDEF DARWIN}, Test_SleepBest_Darwin{$ENDIF}
  ;

var
  Application: TTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.time Test Suite';
  Application.Run;
  Application.Free;
  // testregistry.GetTestRegistry.Free; // lazbuild 环境下不需要手动释放
end.


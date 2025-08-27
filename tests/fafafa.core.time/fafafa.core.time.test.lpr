{$CODEPAGE UTF8}
program fafafa.core.time.test;


{$mode objfpc}{$H+}

uses
  Classes,
  consoletestrunner,
  Test_fafafa_core_time,
  Test_fafafa_core_time_stopwatch,
  Test_fafafa_core_time_api_ext,
  Test_fafafa_core_time_systemclock,
  Test_fafafa_core_time_waitfor_until,
  Test_fafafa_core_time_wait_matrix,
  Test_fafafa_core_time_qpc_fallback,
  Test_fafafa_core_time_short_sleep,
  Test_fafafa_core_time_config_matrix,
  Test_fafafa_core_time_platform_sleep,
  Test_fafafa_core_time_platform_strategy_compare,
  Test_fafafa_core_time_platform_lightload,
  Test_fafafa_core_time_timer_once,
  Test_fafafa_core_time_timer_periodic,
  Test_fafafa_core_time_timer_catchup_limit,
  Test_fafafa_core_time_timer_exception_hook,
  Test_fafafa_core_time_timer_metrics,
  Test_fafafa_core_time_operators,
  Test_fafafa_core_time_duration_arith,
  Test_fafafa_core_time_duration_round_ops,
  Test_fafafa_core_time_instant_deadline_ext,
  Test_fafafa_core_time_instant_deadline_more,
  Test_fafafa_core_time_timer_stress,
  Test_fafafa_core_time_format_ext
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


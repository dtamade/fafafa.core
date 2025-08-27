program tests_thread;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  Test_thread,
  Test_future_generic,
  Test_threadpool_policy,
  Test_threadpool_policy_queue0,
  Test_threadpool_policy_more,
  Test_threadpool_keepalive,
  Test_future_oncomplete,
  Test_channel_unbuffered,
  Test_channel_fairness,
  Test_scheduler_basic,
  Test_scheduler_order,
  Test_scheduler_metrics,
  Test_scheduler_metrics_observed,
  Test_future_helpers,
  Test_future_map_then,
  Test_future_cancel,
  Test_threadpool_cancel,
  Test_select_race,
  Test_channel_sendtimeout,
  Test_scheduler_cancel,
  Test_threadpool_metrics_pool,
  Test_threadpool_effective_queue_boundary,
  Test_threadpool_effective_queue_abort_boundary,
  Test_threadpool_metrics_more,
  Test_threadpool_metrics_observed,
  Test_threadpool_env_taskitempoolmax,
  Test_example_cancel_io_batch,
  Test_select_edges,
  Test_cancel_token_postsubmit,
  Test_threadpool_caller_runs_race,
  Test_channel_close_drain,
  Test_threadpool_token_preexec_cancel,
  Test_threadpool_queue_perf_baseline,
  Test_threadpool_effective_queue_overflow_regression,
  Test_cancel_more_paths,
  Test_threadpool_cached_cap,
  Test_threadpool_reject_metrics,
  Test_token_precancel_semantics,
  Test_scheduler_precision,
  Test_thread_facade_smoke,
  Test_threadpool_policy_caller_runs,
  fafafa.core.thread;

type

  { TMyTestRunner }

  TMyTestRunner = class(TTestRunner)
  protected
    procedure DoRun; override;
  end;

procedure TMyTestRunner.DoRun;
var
  LDefault, LBlocking: IThreadPool;
begin
  try
    inherited DoRun;
  finally
    // 测试收尾：关闭默认与阻塞线程池，减少 heaptrc 残留
    LDefault := GetDefaultThreadPool;
    if Assigned(LDefault) and (not LDefault.IsShutdown) then
    begin
      LDefault.Shutdown;
      LDefault.AwaitTermination(3000);
    end;
    LBlocking := GetBlockingThreadPool;
    if Assigned(LBlocking) and (not LBlocking.IsShutdown) then
    begin
      LBlocking.Shutdown;
      LBlocking.AwaitTermination(3000);
    end;
  end;
end;


var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'FPCUnit Console test runner for fafafa.core.thread';
  Application.Run;
  Application.Free;
end.

{$CODEPAGE UTF8}
program fafafa_core_term_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  // 汇总纳入所有现有测试单元，避免丢失工作成果
  fafafa.core.term.testcase,
  Test_term,
  Test_term_event_queue,
  Test_term_color_degrade,
  Test_term_input_semantics,
  {$IFDEF UNIX}
  Test_term_unix_sequences,
  Test_term_unix_sigwinch,
  Test_term_unix_tty_read_params,
  {$ENDIF}
  Test_term_core_smoke,
  Test_term_events_collect,
  Test_term_events_collect_more,
  Test_term_events_collect_edgecases,
  Test_term_events_wheel_boundaries,
  Test_term_resize_storm_debounce_interrupt,
  Test_term_modeguard_nesting,
  Test_term_windows_modifiers,
  Test_term_windows_mouse,
  Test_term_paste_storage_bytes,
  Test_term_paste_storage_defaults,
  Test_term_paste_storage_bytes_total,
  Test_term_paste_benchmark_trim_div,
  Test_term_paste_profile,
  Test_term_protocol_toggles_smoke,
  Test_term_windows_unicode_input,
  Test_term_protocol_ansi_output,
  Test_term_windows_quickedit_guard,
  Test_term_paste_storage,
  Test_term_poll_timeout,
  Test_term_feature_toggles_getset,
  Test_term_last_error,
  Test_term_last_error_injection,
  Test_term_paste_ring_backend,
  Test_term_paste_ring_edgecases,
  Test_env_override,
  Test_ui_frame_loop_diff,
  Test_ui_viewport_clipping_nested,
  Test_ui_backbuffer_disabled_direct_write,
  Test_ui_diff_inline_style_segments,
  Test_ui_style_leak_guard,
  Test_ui_line_redraw_policy,
  Test_ui_cursor_policy_direct_write,
  Test_ui_clip_x_segments,
  Test_ui_diff_no_empty_segments,
  Test_ui_viewstack_restore_on_frame_end,
  Test_unix_feature_overrides,
  Test_terminal_facade_beta,
  Test_ui_clip_y_segments,
  Test_term_best_practices_smoke,
  Test_term_modeguard_nested_restore_smoke;

type
  TTestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TTestApp.DoRun;
var Runner: TTestRunner;
begin
  WriteLn('fafafa.core.term 单元测试');
  WriteLn('==========================');
  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    if HasOption('a', 'all') or (ParamCount=0) then
      Runner.Run
    else
      Runner.Run;
  finally
    Runner.Free;
  end;
  Terminate;
end;

var App: TTestApp;
begin
  App := TTestApp.Create(nil);
  App.Title := 'fafafa.core.term Tests';
  App.Run;
  App.Free;
end.


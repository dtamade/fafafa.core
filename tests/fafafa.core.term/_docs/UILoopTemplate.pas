unit UILoopTemplate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.term;

type
  TTest_UILoop_Min = class(TTestCase)
  published
    procedure Test_FrameLoop_With_Diff_Minimal;
  end;

implementation

uses tests.fafafa.core.term.TestHelpers_Env, tests.fafafa.core.term.TestHelpers_Skip;

procedure TTest_UILoop_Min.Test_FrameLoop_With_Diff_Minimal;
const FrameBudgetMs = 16;
var i: Integer;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    // 限制 10 帧演示：
    for i := 1 to 10 do
    begin
      // 注入少量事件（模拟用户交互）
      term_evnet_push(term_event_mouse(1+i, 1+i, tms_moved, tmb_none, False, False, False));
      term_evnet_push(term_event_mouse(0, 0, tms_press, tmb_wheel_up, False, False, False));
      // 0 预算：仅消费队列，不阻塞
      var E: array[0..31] of term_event_t; var N: SizeUInt;
      N := term_events_collect(E, Length(E), 0);
      // 简要断言：至少消费了注入事件
      AssertTrue('events consumed', N >= 1);
      // 帧预算控制
      Sleep(FrameBudgetMs);
    end;
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTest_UILoop_Min);

end.

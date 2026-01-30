unit EventCoalescingTemplate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.term;

type
  TTest_EventCoalescing = class(TTestCase)
  published
    procedure Test_MouseMove_Merges_Within_Sample;
    procedure Test_Wheel_Coalesces_Same_Direction;
    procedure Test_Wheel_SwitchDirection_Splits_Coalescing;
  end;

implementation

uses tests.fafafa.core.term.TestHelpers_Env, tests.fafafa.core.term.TestHelpers_Skip;

procedure TTest_EventCoalescing.Test_MouseMove_Merges_Within_Sample;
var
  E: array[0..31] of term_event_t;
  N, i: SizeUInt;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    // 先清空队列
    N := term_events_collect(E, Length(E), 0);
    // 注入 5 次连续移动（应被合并为最后一次坐标）
    for i := 0 to 4 do
      term_evnet_push(term_event_mouse(10 + i, 20 + i, tms_moved, tmb_none, False, False, False));
    // 收集：预算 0，仅消费队列
    N := term_events_collect(E, Length(E), 0);
    AssertEquals('merged move count', 1, Integer(N));
    AssertEquals('kind=mouse', Integer(tek_mouse), Integer(E[0].kind));
    AssertEquals('state=moved', Integer(Ord(tms_moved)), Integer(E[0].mouse.state));
    AssertEquals('x=last', 14, Integer(E[0].mouse.x));
    AssertEquals('y=last', 24, Integer(E[0].mouse.y));
  finally
    term_done;
  end;
end;

procedure TTest_EventCoalescing.Test_Wheel_Coalesces_Same_Direction;
var
  E: array[0..31] of term_event_t;
  N, i: SizeUInt;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    // 先清空队列
    N := term_events_collect(E, Length(E), 0);
    // 注入 4 次滚轮向上（同向合并后保留最后一条）
    for i := 0 to 3 do
      term_evnet_push(term_event_mouse(0, 0, tms_press, tmb_wheel_up, False, False, False));
    N := term_events_collect(E, Length(E), 0);
    AssertEquals('wheel events coalesced', 1, Integer(N));
    AssertEquals('kind=mouse', Integer(tek_mouse), Integer(E[0].kind));
    AssertEquals('button=wheel_up', Integer(Ord(tmb_wheel_up)), Integer(E[0].mouse.button));
  finally
    term_done;
  end;
end;

procedure TTest_EventCoalescing.Test_Wheel_SwitchDirection_Splits_Coalescing;
var
  E: array[0..31] of term_event_t;
  N, i: SizeUInt;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    // 清空
    N := term_events_collect(E, Length(E), 0);
    // up up down down → 预期合并为 1 up + 1 down（顺序保留）
    term_evnet_push(term_event_mouse(0,0,tms_press,tmb_wheel_up,False,False,False));
    term_evnet_push(term_event_mouse(0,0,tms_press,tmb_wheel_up,False,False,False));
    term_evnet_push(term_event_mouse(0,0,tms_press,tmb_wheel_down,False,False,False));
    term_evnet_push(term_event_mouse(0,0,tms_press,tmb_wheel_down,False,False,False));
    N := term_events_collect(E, Length(E), 0);
    AssertEquals('coalesced count 2', 2, Integer(N));
    AssertEquals('first=wheel_up', Integer(Ord(tmb_wheel_up)), Integer(E[0].mouse.button));
    AssertEquals('second=wheel_down', Integer(Ord(tmb_wheel_down)), Integer(E[1].mouse.button));
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTest_EventCoalescing);

end.

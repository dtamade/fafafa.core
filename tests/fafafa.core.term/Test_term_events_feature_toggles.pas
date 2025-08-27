{$CODEPAGE UTF8}
unit Test_term_events_feature_toggles;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermEvents_FeatureToggles = class(TTestCase)
  private
    FTerm: pterm_t;
    FQ: pterm_event_queue_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  private
    procedure CountMoveAndWheel(const Arr: array of term_event_t; aN: SizeUInt; out aMoveCount, aWheelCount: Integer);
  published
    procedure Test_Coalesce_Move_On_Off;
    procedure Test_Coalesce_Wheel_On_Off;
    procedure Test_Debounce_Resize_On_Off;
    procedure Test_Mixed_Move_Wheel_OnOff_Combo;
  end;

implementation

procedure TTestCase_TermEvents_FeatureToggles.CountMoveAndWheel(const Arr: array of term_event_t; aN: SizeUInt; out aMoveCount, aWheelCount: Integer);
var
  i: Integer;
begin
  aMoveCount := 0; aWheelCount := 0;
  for i := 0 to aN - 1 do
  begin
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.state = Ord(tms_moved)) then Inc(aMoveCount);
    if (Arr[i].kind = tek_mouse) and ((Arr[i].mouse.button = Ord(tmb_wheel_up)) or (Arr[i].mouse.button = Ord(tmb_wheel_down)) or
       (Arr[i].mouse.button = Ord(tmb_wheel_left)) or (Arr[i].mouse.button = Ord(tmb_wheel_right))) then Inc(aWheelCount);
  end;
end;

procedure TTestCase_TermEvents_FeatureToggles.SetUp;
begin
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  FQ := term_event_queue_create;
  FTerm^.event_queue := FQ;
end;

procedure TTestCase_TermEvents_FeatureToggles.TearDown;
begin
  if Assigned(FTerm) then
  begin
    if Assigned(FTerm^.event_queue) then
      term_event_queue_destroy(FTerm^.event_queue);
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermEvents_FeatureToggles.Test_Coalesce_Move_On_Off;
var
  Arr: array[0..7] of term_event_t;
  N: SizeUInt;
  i, moveCount: Integer;
begin
  term_event_queue_clear(FTerm^.event_queue);
  term_set_coalesce_move(True);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  moveCount := 0;
  for i := 0 to N - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.state = Ord(tms_moved)) then Inc(moveCount);
  CheckEquals(1, moveCount, 'with coalesce_move on, consecutive moves merged');

  // 关闭后应不过度合并
  term_event_queue_clear(FTerm^.event_queue);
  term_set_coalesce_move(False);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  moveCount := 0;
  for i := 0 to N - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.state = Ord(tms_moved)) then Inc(moveCount);
  CheckEquals(2, moveCount, 'with coalesce_move off, moves should not merge');
end;

procedure TTestCase_TermEvents_FeatureToggles.Test_Coalesce_Wheel_On_Off;
var
  Arr: array[0..7] of term_event_t;
  N: SizeUInt;
  i, wheelCount: Integer;
begin
  term_event_queue_clear(FTerm^.event_queue);
  term_set_coalesce_wheel(True);
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  wheelCount := 0;
  for i := 0 to N - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.button = Ord(tmb_wheel_up)) then Inc(wheelCount);
  CheckEquals(1, wheelCount, 'with coalesce_wheel on, same-direction wheels merged');

  // 关闭后应全部保留
  term_event_queue_clear(FTerm^.event_queue);
  term_set_coalesce_wheel(False);
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  wheelCount := 0;
  for i := 0 to N - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.button = Ord(tmb_wheel_up)) then Inc(wheelCount);
  CheckEquals(2, wheelCount, 'with coalesce_wheel off, wheels should not merge');
end;

procedure TTestCase_TermEvents_FeatureToggles.Test_Debounce_Resize_On_Off;
var
  Arr: array[0..7] of term_event_t;
  N: SizeUInt;
  i, resizeCount: Integer;
begin
  term_event_queue_clear(FTerm^.event_queue);
  term_set_debounce_resize(True);
  term_event_push(FTerm, term_event_size_change(80,24));
  term_event_push(FTerm, term_event_size_change(100,30));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  resizeCount := 0;
  for i := 0 to N - 1 do
    if Arr[i].kind = tek_sizeChange then Inc(resizeCount);
  CheckEquals(1, resizeCount, 'with debounce_resize on, consecutive resizes keep last');

  // 关闭后应全部保留
  term_event_queue_clear(FTerm^.event_queue);
  term_set_debounce_resize(False);
  term_event_push(FTerm, term_event_size_change(80,24));
  term_event_push(FTerm, term_event_size_change(100,30));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  resizeCount := 0;
  for i := 0 to N - 1 do
    if Arr[i].kind = tek_sizeChange then Inc(resizeCount);
  CheckEquals(2, resizeCount, 'with debounce_resize off, resizes should not debounce');
end;

procedure TTestCase_TermEvents_FeatureToggles.Test_Mixed_Move_Wheel_OnOff_Combo;
var
  Arr: array[0..15] of term_event_t;
  N: SizeUInt;
  moveCount, wheelCount: Integer;
begin
  // 组合1：move off + wheel on
  term_event_queue_clear(FTerm^.event_queue);
  term_set_coalesce_move(False);
  term_set_coalesce_wheel(True);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(3,3, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  CountMoveAndWheel(Arr, N, moveCount, wheelCount);
  CheckTrue(moveCount >= 2, 'combo1: move off should keep multiple moves');
  CheckEquals(1, wheelCount, 'combo1: wheel on should merge same-direction wheels');

  // 组合2：move on + wheel off
  term_event_queue_clear(FTerm^.event_queue);
  term_set_coalesce_move(True);
  term_set_coalesce_wheel(False);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(3,3, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  CountMoveAndWheel(Arr, N, moveCount, wheelCount);
  CheckTrue(moveCount >= 1, 'combo2: move on should merge consecutive moves');
  CheckEquals(2, wheelCount, 'combo2: wheel off should not merge');

  // 组合3：both off
  term_event_queue_clear(FTerm^.event_queue);
  term_set_coalesce_move(False);
  term_set_coalesce_wheel(False);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(3,3, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  CountMoveAndWheel(Arr, N, moveCount, wheelCount);
  CheckTrue(moveCount >= 2, 'combo3: move off should keep multiple moves');
  CheckEquals(2, wheelCount, 'combo3: wheel off should not merge');
end;

initialization
  RegisterTest(TTestCase_TermEvents_FeatureToggles);
end.

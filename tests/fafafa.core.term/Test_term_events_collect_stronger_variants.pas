{$CODEPAGE UTF8}
unit Test_term_events_collect_stronger_variants;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermEventsCollect_Stronger = class(TTestCase)
  private
    FTerm: pterm_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Move_Not_Merged_Across_Collect_With_Interleaving;
    procedure Test_Wheel_Alternating_Directions_Splits_Across_Collects;
    procedure Test_Resize_Debounce_With_Multiple_NonResize_And_Resume;
  end;

implementation

procedure TTestCase_TermEventsCollect_Stronger.SetUp;
begin
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  FTerm^.event_queue := term_event_queue_create;
end;

procedure TTestCase_TermEventsCollect_Stronger.TearDown;
begin
  if Assigned(FTerm) then
  begin
    if Assigned(FTerm^.event_queue) then
      term_event_queue_destroy(FTerm^.event_queue);
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermEventsCollect_Stronger.Test_Move_Not_Merged_Across_Collect_With_Interleaving;
var
  Arr: array[0..9] of term_event_t;
  N1, N2, i: SizeUInt;
  moveCount1, moveCount2, keyCount2, pressCount2: Integer;
begin
  // 第一轮：两个连续 move -> 合并为 1
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N1 := term_events_collect(FTerm, Arr, Length(Arr), 0);
  moveCount1 := 0;
  for i := 0 to N1 - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.state = Ord(tms_moved)) then Inc(moveCount1);
  CheckEquals(1, moveCount1, 'first collect merges consecutive moves');

  // 间插不同类型事件 + 新的 move -> 应作为新段计数
  term_event_push(FTerm, term_event_key(KEY_A, WideChar(#0), False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_left, False, False, False));
  term_event_push(FTerm, term_event_mouse(3,3, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N2 := term_events_collect(FTerm, Arr, Length(Arr), 0);
  moveCount2 := 0; keyCount2 := 0; pressCount2 := 0;
  for i := 0 to N2 - 1 do
    case Arr[i].kind of
      tek_mouse:
        if Arr[i].mouse.state = Ord(tms_moved) then Inc(moveCount2)
        else if Arr[i].mouse.state = Ord(tms_press) then Inc(pressCount2);
      tek_key: Inc(keyCount2);
    end;
  CheckEquals(1, moveCount2, 'new move after interleaving events should start a new segment');
  CheckEquals(1, keyCount2, 'interleaving key should be preserved');
  CheckEquals(1, pressCount2, 'interleaving press should be preserved');
end;

procedure TTestCase_TermEventsCollect_Stronger.Test_Wheel_Alternating_Directions_Splits_Across_Collects;
var
  Arr: array[0..15] of term_event_t;
  N1, N2, i: SizeUInt;
  wheelCount1, wheelCount2: Integer;
begin
  // 第一轮：up, up, down -> 应形成两个滚轮段（up的最后一条 + down 的最后一条）
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_down, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N1 := term_events_collect(FTerm, Arr, Length(Arr), 0);
  wheelCount1 := 0;
  for i := 0 to N1 - 1 do
    if (Arr[i].kind = tek_mouse) and
       ((Arr[i].mouse.button = Ord(tmb_wheel_up)) or (Arr[i].mouse.button = Ord(tmb_wheel_down))) then
      Inc(wheelCount1);
  CheckEquals(2, wheelCount1, 'wheel reversals split segments (first collect)');

  // 第二轮：up, down -> 再次形成两个滚轮段
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_down, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N2 := term_events_collect(FTerm, Arr, Length(Arr), 0);
  wheelCount2 := 0;
  for i := 0 to N2 - 1 do
    if (Arr[i].kind = tek_mouse) and
       ((Arr[i].mouse.button = Ord(tmb_wheel_up)) or (Arr[i].mouse.button = Ord(tmb_wheel_down))) then
      Inc(wheelCount2);
  CheckEquals(2, wheelCount2, 'wheel reversals split segments (second collect)');
end;

procedure TTestCase_TermEventsCollect_Stronger.Test_Resize_Debounce_With_Multiple_NonResize_And_Resume;
var
  Arr: array[0..15] of term_event_t;
  N, i: SizeUInt;
  resizeCount, keyCount, pressCount: Integer;
begin
  // 第一段连续 resize -> key -> press -> 第二段连续 resize -> key
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_size_change(80,24));
  term_event_push(FTerm, term_event_size_change(90,25));
  term_event_push(FTerm, term_event_key(KEY_D, WideChar(#0), False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_left, False, False, False));
  term_event_push(FTerm, term_event_size_change(100,30));
  term_event_push(FTerm, term_event_size_change(120,40));
  term_event_push(FTerm, term_event_key(KEY_E, WideChar(#0), False, False, False));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  resizeCount := 0; keyCount := 0; pressCount := 0;
  for i := 0 to N - 1 do
    case Arr[i].kind of
      tek_sizeChange: Inc(resizeCount);
      tek_key: Inc(keyCount);
      tek_mouse: if Arr[i].mouse.state = Ord(tms_press) then Inc(pressCount);
    end;

  // 期望：两段 resize（各自保留最后一条） + 两个非 resize 事件保留
  CheckEquals(2, resizeCount, 'two resize segments keep last of each');
  CheckEquals(2, keyCount, 'two keys preserved');
  CheckEquals(1, pressCount, 'one press preserved');
end;

initialization
  RegisterTest(TTestCase_TermEventsCollect_Stronger);

end.


{$CODEPAGE UTF8}
unit Test_term_events_collect_edgecases;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermEventsCollect_Edge = class(TTestCase)
  private
    FTerm: pterm_t;
    FQ: pterm_event_queue_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Move_Not_Merged_When_Separated_By_Key;
    procedure Test_Resize_Debounce_Stops_On_NonResize;
    procedure Test_Move_Resize_Segments_Independent;
    procedure Test_Move_Segments_Split_By_Wheel;
    procedure Test_Resize_Segments_Split_By_MousePress;
    procedure Test_Move_Not_Merged_Across_Collect_Calls;
  end;

implementation

procedure TTestCase_TermEventsCollect_Edge.SetUp;
begin
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  FQ := term_event_queue_create;
  FTerm^.event_queue := FQ;
  // 不设置 event_pull，聚焦于已有队列的行为
end;

procedure TTestCase_TermEventsCollect_Edge.TearDown;
begin
  if Assigned(FTerm) then
  begin
    if Assigned(FTerm^.event_queue) then
      term_event_queue_destroy(FTerm^.event_queue);
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermEventsCollect_Edge.Test_Move_Not_Merged_When_Separated_By_Key;
var
  Arr: array[0..7] of term_event_t;
  N, i, moveCount, keyCount: SizeUInt;
begin
  term_event_queue_clear(FTerm^.event_queue);
  // move -> key -> move：中间被 key 打断，不应合并为一个
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_key(KEY_X, WideChar(#0), False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  moveCount := 0; keyCount := 0;
  for i := 0 to N - 1 do
    case Arr[i].kind of
      tek_mouse: if Arr[i].mouse.state = Ord(tms_moved) then Inc(moveCount);
      tek_key: Inc(keyCount);
    end;
  CheckEquals(2, Integer(moveCount), 'moves separated by key should not be merged');
  CheckEquals(1, Integer(keyCount), 'key should be preserved');
end;

procedure TTestCase_TermEventsCollect_Edge.Test_Resize_Debounce_Stops_On_NonResize;
var
  Arr: array[0..7] of term_event_t;
  N, i, resizeCount: SizeUInt;
begin
  term_event_queue_clear(FTerm^.event_queue);
  // resize -> resize -> key -> resize：key 打断去抖；应保留前两者的后者 + 最后一条 resize
  term_event_push(FTerm, term_event_size_change(80, 24));
  term_event_push(FTerm, term_event_size_change(100, 30)); // 合并后保留这一条
  term_event_push(FTerm, term_event_key(KEY_B, WideChar(#0), False, False, False));
  term_event_push(FTerm, term_event_size_change(120, 40)); // 第二段应单独保留

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  resizeCount := 0;
  for i := 0 to N - 1 do
    if Arr[i].kind = tek_sizeChange then Inc(resizeCount);

  CheckTrue(resizeCount >= 2, 'debounce should stop at non-resize and keep last of each segment');
  end;

procedure TTestCase_TermEventsCollect_Edge.Test_Move_Resize_Segments_Independent;
var
  Arr: array[0..7] of term_event_t;
  N, i: SizeUInt;
  moveCount, resizeCount: Integer;
begin
  term_event_queue_clear(FTerm^.event_queue);
  // move -> move -> resize -> resize -> key -> move
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_size_change(80,24));
  term_event_push(FTerm, term_event_size_change(100,30));
  term_event_push(FTerm, term_event_key(KEY_C, WideChar(#0), False, False, False));
  term_event_push(FTerm, term_event_mouse(3,3, tms_moved, tmb_none, False, False, False));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  moveCount := 0; resizeCount := 0;
  for i := 0 to N - 1 do
    case Arr[i].kind of
      tek_mouse: if Arr[i].mouse.state = Ord(tms_moved) then Inc(moveCount);
      tek_sizeChange: Inc(resizeCount);
    end;
  // 期望：第一段 move 合并为 1；第一段 resize 去抖合并为 1；key 断段；最后的 move 另起一段，共 2 个 move
  CheckEquals(2, moveCount, 'two move segments, each keeps last');
  CheckEquals(1, resizeCount, 'one resize segment keeps last');
  end;
procedure TTestCase_TermEventsCollect_Edge.Test_Move_Segments_Split_By_Wheel;
var
  Arr: array[0..7] of term_event_t;
  N, i: SizeUInt;
  moveCount, wheelCount: Integer;
begin
  term_event_queue_clear(FTerm^.event_queue);
  // move -> wheel_up -> move：wheel 打断 move 段，应形成两段 move，且 wheel 保留
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  moveCount := 0; wheelCount := 0;
  for i := 0 to N - 1 do
    case Arr[i].kind of
      tek_mouse:
        if Arr[i].mouse.state = Ord(tms_moved) then Inc(moveCount)
        else if Arr[i].mouse.button = Ord(tmb_wheel_up) then Inc(wheelCount);
    end;
  CheckEquals(2, moveCount, 'wheel should split move segments');
  CheckEquals(1, wheelCount, 'wheel should be preserved');
end;

procedure TTestCase_TermEventsCollect_Edge.Test_Resize_Segments_Split_By_MousePress;
var
  Arr: array[0..7] of term_event_t;
  N, i: SizeUInt;
  resizeCount, pressCount: Integer;
begin
  term_event_queue_clear(FTerm^.event_queue);
  // resize -> mouse press -> resize：press 打断 resize 段，应形成两个 resize 段
  term_event_push(FTerm, term_event_size_change(80,24));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_left, False, False, False));
  term_event_push(FTerm, term_event_size_change(100,30));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  resizeCount := 0; pressCount := 0;
  for i := 0 to N - 1 do
    case Arr[i].kind of
      tek_sizeChange: Inc(resizeCount);
      tek_mouse: if Arr[i].mouse.state = Ord(tms_press) then Inc(pressCount);
    end;
  CheckEquals(2, resizeCount, 'mouse press should split resize segments');
  CheckEquals(1, pressCount, 'mouse press should be preserved');
end;

procedure TTestCase_TermEventsCollect_Edge.Test_Move_Not_Merged_Across_Collect_Calls;
var
  Arr: array[0..7] of term_event_t;
  N1, N2, i: SizeUInt;
  moveCount1, moveCount2: Integer;
begin
  // 第一次 collect：两次连续 move 应合并为 1
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_mouse(2,2, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N1 := term_events_collect(FTerm, Arr, Length(Arr), 0);
  moveCount1 := 0;
  for i := 0 to N1 - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.state = Ord(tms_moved)) then Inc(moveCount1);
  CheckEquals(1, moveCount1, 'consecutive moves merged in first collect');

  // 第二次 collect：在上一轮后注入新的 move；应作为新段计数
  term_event_push(FTerm, term_event_mouse(3,3, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N2 := term_events_collect(FTerm, Arr, Length(Arr), 0);
  moveCount2 := 0;
  for i := 0 to N2 - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.state = Ord(tms_moved)) then Inc(moveCount2);
  CheckEquals(1, moveCount2, 'new moves after previous collect start a new segment');
end;

initialization
  RegisterTest(TTestCase_TermEventsCollect_Edge);
end.


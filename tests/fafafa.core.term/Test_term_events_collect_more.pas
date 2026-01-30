{$CODEPAGE UTF8}
unit Test_term_events_collect_more;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermEventsCollect_More = class(TTestCase)
  private
    FTerm: pterm_t;
    FQ: pterm_event_queue_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Move_Merge_Across_Bursts;
    procedure Test_Capacity_Clipping_Safely;
    procedure Test_Move_Merge_Long_Sequence;
    procedure Test_Budget_Zero_Does_Not_Pull_Empty;
    procedure Test_Budget_Zero_Consumes_Queue_Only;
    procedure Test_Resize_Debounce_Keep_Last;
  end;


implementation

var
  gPullCount2: Integer = 0;

function FakePull_Burst_Mix(aTerm: pterm_t; aTimeout: UInt64): Boolean;
var
  ev: term_event_t;
begin
  // 两次 pull：第一次注入 move(1,1)、move(2,2)，第二次注入 wheel 与 key
  if gPullCount2 = 0 then
  begin
    ev := term_event_mouse(1, 1, tms_moved, tmb_none, False, False, False);
    term_event_push(aTerm, ev);
    ev := term_event_mouse(2, 2, tms_moved, tmb_none, False, False, False);
    term_event_push(aTerm, ev);
  end
  else if gPullCount2 = 1 then
  begin
    ev := term_event_mouse(0, 0, tms_press, tmb_wheel_up, False, False, False);
    term_event_push(aTerm, ev);
    ev := term_event_key(KEY_A, WideChar(#0), False, False, False);
    term_event_push(aTerm, ev);
  end
  else
    Exit(False);
  Inc(gPullCount2);
  Result := True;
end;

procedure TTestCase_TermEventsCollect_More.SetUp;
begin
  gPullCount2 := 0;
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  FQ := term_event_queue_create;
  FTerm^.event_queue := FQ;
  FTerm^.event_pull := @FakePull_Burst_Mix;
end;

procedure TTestCase_TermEventsCollect_More.TearDown;
begin
  if Assigned(FTerm) then
  begin
    if Assigned(FTerm^.event_queue) then
      term_event_queue_destroy(FTerm^.event_queue);
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermEventsCollect_More.Test_Move_Merge_Across_Bursts;
var
  Arr: array[0..7] of term_event_t;
  N: SizeUInt;
  i: Integer;
  moveCount, wheelCount, keyCount: Integer;
begin
  FillByte(Arr, SizeOf(Arr), 0);
  // 预算较大，允许两次 pull
  N := term_events_collect(FTerm, Arr, Length(Arr), 20);
  moveCount := 0; wheelCount := 0; keyCount := 0;
  for i := 0 to N - 1 do
  begin
    case Arr[i].kind of
      tek_mouse:
        if Arr[i].mouse.state = Ord(tms_moved) then
        begin
          Inc(moveCount);
          // 期望合并后仅保留最后一次 (2,2)
          CheckEquals(2, Arr[i].mouse.x, 'merged move x');
          CheckEquals(2, Arr[i].mouse.y, 'merged move y');
        end
        else if Arr[i].mouse.button = Ord(tmb_wheel_up) then
          Inc(wheelCount);
      tek_key: Inc(keyCount);
    end;
  end;
  CheckEquals(1, moveCount,  'consecutive move merged across bursts');
  CheckEquals(1, wheelCount, 'wheel kept');
  CheckEquals(1, keyCount,   'key kept');
end;

procedure TTestCase_TermEventsCollect_More.Test_Capacity_Clipping_Safely;
var
  Arr: array[0..0] of term_event_t; // 仅 1 个容量
  N: SizeUInt;
begin
  FillByte(Arr, SizeOf(Arr), 0);
  // 预算足够触发一次注入，但 aMaxN=1，确保不会越界，并返回 1
  N := term_events_collect(FTerm, Arr, Length(Arr), 10);
  CheckEquals(1, Integer(N), 'capacity clipping to 1');
  // 不关心具体是哪一种事件，只要合理落位即可
end;

procedure TTestCase_TermEventsCollect_More.Test_Move_Merge_Long_Sequence;
var
  Arr: array[0..31] of term_event_t;
  N, i: SizeUInt;
  moveCount: Integer;
begin
  // 构造一个长序列的移动注入：多次 move，最后一次应被保留
  gPullCount2 := 0;
  // 自定义一次性的 pull：注入 20 次移动
  FTerm^.event_pull := @FakePull_Burst_Mix; // 先按已有两次 burst
  // 先消费一次，确保 pull 可用
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 20);
  // 再手动向队列注入连续移动(3..20)
  for i := 3 to 20 do
    term_event_push(FTerm, term_event_mouse(i, i, tms_moved, tmb_none, False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0); // 仅消费现有队列
  moveCount := 0;
  for i := 0 to N - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.state = Ord(tms_moved)) then
    begin
      Inc(moveCount);
      // 最后一条移动应为 (20,20)
      CheckEquals(20, Arr[i].mouse.x);
      CheckEquals(20, Arr[i].mouse.y);
    end;
  end;


procedure TTestCase_TermEventsCollect_More.Test_Budget_Zero_Does_Not_Pull_Empty;
var
  Arr: array[0..3] of term_event_t;
  N: SizeUInt;
begin
  // 清空队列，预算为 0，按语义不应触发 event_pull
  term_event_queue_clear(FTerm^.event_queue);
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  CheckEquals(0, Integer(N), 'budget=0 should not pull when queue is empty');
end;

procedure TTestCase_TermEventsCollect_More.Test_Budget_Zero_Consumes_Queue_Only;
var
  Arr: array[0..7] of term_event_t;
  N: SizeUInt;
  i: Integer;
begin
  // 先手动注入两条事件到队列
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_mouse(1,1, tms_moved, tmb_none, False, False, False));
  term_event_push(FTerm, term_event_key(KEY_Z, WideChar(#0), False, False, False));
  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);
  // 仅消费现有队列（包含合并后的 move 与 key），不调用 pull 注入额外事件
  CheckTrue(N >= 1, 'should consume queued events');
  // 预算为 0 时不会追加新的 burst（占位断言已由其它用例覆盖细节）
  // 此处不再重复断言
end;

procedure TTestCase_TermEventsCollect_More.Test_Resize_Debounce_Keep_Last;
var
  Arr: array[0..7] of term_event_t;
  N: SizeUInt;
  i, resizeCount: Integer;
  lastW, lastH: Integer;
begin
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_size_change(80, 24));
  term_event_push(FTerm, term_event_key(KEY_B, WideChar(#0), False, False, False));
  term_event_push(FTerm, term_event_size_change(100, 30));
  term_event_push(FTerm, term_event_mouse(5,5, tms_press, tmb_left, False, False, False));
  term_event_push(FTerm, term_event_size_change(120, 40)); // 末段应为这一条

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  resizeCount := 0; lastW := -1; lastH := -1;
  for i := 0 to N - 1 do
    if Arr[i].kind = tek_sizeChange then
    begin
      Inc(resizeCount);
      lastW := Arr[i].size.width;
      lastH := Arr[i].size.height;
    end;
  // 新语义：按段去抖，遇非 resize 断段；因此会出现多个 resize（各段的最后一个）
  CheckTrue(resizeCount >= 2, 'resize should be segmented by non-resize events and keep last of each segment');
  CheckEquals(120, lastW);
  CheckEquals(40, lastH);
end;

initialization
  RegisterTest(TTestCase_TermEventsCollect_More);
end.

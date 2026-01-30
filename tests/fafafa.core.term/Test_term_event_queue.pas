{$CODEPAGE UTF8}
unit Test_term_event_queue;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermEventQueue = class(TTestCase)
  private
    FQ: pterm_event_queue_t;
    function MakeKeyEvent(const AKey: term_key_t): term_event_t;
    function MakeMouseEvent(const AX, AY: term_size_t): term_event_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Create_Init_Final_Destroy;
    procedure Test_Push_Pop_Order;
    procedure Test_Peek_NoRemove;
    procedure Test_Front_Back_Next_Prev_Remove;
    procedure Test_Clear_Empty_Behavior;
    procedure Test_Pop_Empty_ReturnsFalse;
    procedure Test_Overflow_Drops_Oldest;
  end;

implementation

function TTestCase_TermEventQueue.MakeKeyEvent(const AKey: term_key_t): term_event_t;
begin
  FillByte(Result, SizeOf(Result), 0);
  Result.kind := tek_key;
  Result.key.key := AKey;
end;

function TTestCase_TermEventQueue.MakeMouseEvent(const AX, AY: term_size_t): term_event_t;
begin
  FillByte(Result, SizeOf(Result), 0);
  Result.kind := tek_mouse;
  Result.mouse.x := AX;
  Result.mouse.y := AY;
end;

procedure TTestCase_TermEventQueue.SetUp;
begin
  FQ := term_event_queue_create;
  CheckTrue(FQ <> nil, 'queue should be created');
end;

procedure TTestCase_TermEventQueue.TearDown;
begin
  if FQ <> nil then
  begin
    term_event_queue_clear(FQ);
    term_event_queue_destroy(FQ);
    FQ := nil;
  end;
end;

procedure TTestCase_TermEventQueue.Test_Create_Init_Final_Destroy;
var
  C: SizeUInt;
begin
  // Newly created queue should be empty
  C := term_event_queue_count(FQ);
  CheckEquals(0, PtrInt(C), 'new queue count = 0');

  // Push one event and verify count
  term_event_queue_push(FQ, MakeKeyEvent(KEY_A));
  CheckEquals(1, PtrInt(term_event_queue_count(FQ)), 'count after push = 1');

  // Clear and verify empty
  term_event_queue_clear(FQ);
  CheckEquals(0, PtrInt(term_event_queue_count(FQ)), 'count after clear = 0');
end;

procedure TTestCase_TermEventQueue.Test_Push_Pop_Order;
var
  E: term_event_t;
begin
  term_event_queue_push(FQ, MakeKeyEvent(KEY_Q));
  term_event_queue_push(FQ, MakeMouseEvent(3, 5));
  CheckEquals(2, PtrInt(term_event_queue_count(FQ)), 'count=2');

  FillByte(E, SizeOf(E), 0);
  CheckTrue(term_event_queue_pop(FQ, E), 'pop first');
  CheckEquals(Ord(tek_key), Ord(E.kind), 'first.kind=key');
  CheckEquals(Ord(KEY_Q), Ord(E.key.key), 'first.key=Q');

  FillByte(E, SizeOf(E), 0);
  CheckTrue(term_event_queue_pop(FQ, E), 'pop second');
  CheckEquals(Ord(tek_mouse), Ord(E.kind), 'second.kind=mouse');
  CheckEquals(3, E.mouse.x, 'second.mouse.x=3');
  CheckEquals(5, E.mouse.y, 'second.mouse.y=5');

  CheckEquals(0, PtrInt(term_event_queue_count(FQ)), 'empty after two pops');
end;

procedure TTestCase_TermEventQueue.Test_Peek_NoRemove;
var
  E: term_event_t;
  C: SizeUInt;
begin
  term_event_queue_push(FQ, MakeKeyEvent(KEY_1));
  C := term_event_queue_count(FQ);
  FillByte(E, SizeOf(E), 0);
  CheckTrue(term_event_queue_peek(FQ, E), 'peek should return true');
  CheckEquals(Ord(tek_key), Ord(E.kind), 'peek.kind=key');
  CheckEquals(Ord(KEY_1), Ord(E.key.key), 'peek.key=1');
  CheckEquals(PtrInt(C), PtrInt(term_event_queue_count(FQ)), 'peek does not remove item');
end;

procedure TTestCase_TermEventQueue.Test_Front_Back_Next_Prev_Remove;
var
  E1, E2, E3: term_event_t;
  N1, N2, N3: pterm_event_queue_entry_t;
begin
  // Push 3 events
  E1 := MakeKeyEvent(KEY_A);
  E2 := MakeKeyEvent(KEY_B);
  E3 := MakeKeyEvent(KEY_C);
  term_event_queue_push(FQ, E1);
  term_event_queue_push(FQ, E2);
  term_event_queue_push(FQ, E3);
  CheckEquals(3, PtrInt(term_event_queue_count(FQ)), 'count=3');

  // Front -> second via next -> back
  N1 := term_event_queue_entry_front(FQ);
  CheckTrue(N1 <> nil, 'front exists');
  N2 := term_event_queue_entry_next(N1);
  CheckTrue(N2 <> nil, 'second exists');
  N3 := term_event_queue_entry_back(FQ);
  CheckTrue(N3 <> nil, 'back exists');

  // Remove the middle node
  term_event_queue_remove(FQ, N2);
  CheckEquals(2, PtrInt(term_event_queue_count(FQ)), 'count=2 after remove middle');

  // Pop order should now be A then C
  CheckTrue(term_event_queue_pop(FQ, E1), 'pop #1');
  CheckEquals(Ord(KEY_A), Ord(E1.key.key), 'first=A');
  CheckTrue(term_event_queue_pop(FQ, E3), 'pop #2');
  CheckEquals(Ord(KEY_C), Ord(E3.key.key), 'second=C');
end;

procedure TTestCase_TermEventQueue.Test_Clear_Empty_Behavior;
var
  E: term_event_t;
begin
  term_event_queue_clear(FQ);
  FillByte(E, SizeOf(E), 0);
  // peek/pop on empty
  CheckFalse(term_event_queue_peek(FQ, E), 'peek on empty -> false');
  CheckFalse(term_event_queue_pop(FQ, E), 'pop on empty -> false');
end;

procedure TTestCase_TermEventQueue.Test_Pop_Empty_ReturnsFalse;
var
  E: term_event_t;
begin
  FillByte(E, SizeOf(E), 0);
  CheckFalse(term_event_queue_pop(FQ, E));
end;

procedure TTestCase_TermEventQueue.Test_Overflow_Drops_Oldest;
var
  E: term_event_t;
  i: Integer;
  cap: Integer;
begin
  // 构造超过容量的入队，预期丢弃最旧的，保留最后 cap 个
  cap := 8192; // TERM_EVENT_QUEUE_MAX
  for i := 1 to cap + 10 do
    term_event_queue_push(FQ, MakeKeyEvent(KEY_A));
  // 此时 count 应该为 cap
  CheckEquals(cap, PtrInt(term_event_queue_count(FQ)), 'count should be capped at capacity');
  // 再推入一个特征事件
  term_event_queue_push(FQ, MakeMouseEvent(7, 9));
  // 弹出 cap-1 个（全部是 KEY_A），最后一个应为我们的特征事件
  for i := 1 to cap - 1 do
    CheckTrue(term_event_queue_pop(FQ, E), 'pop filler');
  CheckTrue(term_event_queue_pop(FQ, E), 'pop last');
  CheckEquals(Ord(tek_mouse), Ord(E.kind), 'last kept newest');
  CheckEquals(7, E.mouse.x);
  CheckEquals(9, E.mouse.y);
end;


initialization
  RegisterTest(TTestCase_TermEventQueue);
end.


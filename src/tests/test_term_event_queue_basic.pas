unit test_term_event_queue_basic;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTermEventQueueBasic = class(TTestCase)
  published
    procedure Test_Peek_Pop_Order;
    procedure Test_Clear_Empties_Queue;
    procedure Test_Capacity_Overwrite_Drops_Oldest;
  end;

procedure RegisterTermEventQueueTests;

implementation

procedure TTermEventQueueBasic.Test_Peek_Pop_Order;
var q: pterm_event_queue_t; e, outEv: term_event_t; ok: Boolean;
begin
  q := term_event_queue_create;
  try
    // push 3 events
    e := term_event_size_change(10, 1); term_event_queue_push(q, e);
    e := term_event_size_change(20, 2); term_event_queue_push(q, e);
    e := term_event_size_change(30, 3); term_event_queue_push(q, e);
    // peek should see first
    ok := term_event_queue_peek(q, outEv);
    fpcunit.TAssert.AssertTrue(ok);
    fpcunit.TAssert.AssertEquals(10, Integer(outEv.size.width));
    // pop in order
    ok := term_event_queue_pop(q, outEv);
    fpcunit.TAssert.AssertTrue(ok);
    fpcunit.TAssert.AssertEquals(20, Integer(q^.buffer[(q^.head_idx) mod q^.capacity].size.width)); // next head points to second
  finally
    term_event_queue_destroy(q);
  end;
end;

procedure TTermEventQueueBasic.Test_Clear_Empties_Queue;
var q: pterm_event_queue_t; e: term_event_t;
begin
  q := term_event_queue_create;
  try
    e := term_event_size_change(10, 1); term_event_queue_push(q, e);
    e := term_event_size_change(20, 2); term_event_queue_push(q, e);
    fpcunit.TAssert.AssertTrue(not term_event_queue_is_empty(q));
    term_event_queue_clear(q);
    fpcunit.TAssert.AssertTrue(term_event_queue_is_empty(q));
    fpcunit.TAssert.AssertEquals(0, Integer(term_event_queue_count(q)));
  finally
    term_event_queue_destroy(q);
  end;
end;

procedure TTermEventQueueBasic.Test_Capacity_Overwrite_Drops_Oldest;
var q: pterm_event_queue_t; e, outEv: term_event_t; i: SizeUInt; ok: Boolean;
begin
  q := term_event_queue_create;
  try
    // fill to capacity with width = 1..TERM_EVENT_QUEUE_MAX
    for i := 1 to TERM_EVENT_QUEUE_MAX do begin
      e := term_event_size_change(i, 0);
      term_event_queue_push(q, e);
    end;
    fpcunit.TAssert.AssertEquals(Integer(TERM_EVENT_QUEUE_MAX), Integer(term_event_queue_count(q)));
    // push one more, should drop the oldest (width=1)
    e := term_event_size_change(TERM_EVENT_QUEUE_MAX + 1, 0);
    term_event_queue_push(q, e);
    fpcunit.TAssert.AssertEquals(Integer(TERM_EVENT_QUEUE_MAX), Integer(term_event_queue_count(q)));
    // pop first, expect width=2
    ok := term_event_queue_pop(q, outEv);
    fpcunit.TAssert.AssertTrue(ok);
    fpcunit.TAssert.AssertEquals(2, Integer(outEv.size.width));
  finally
    term_event_queue_destroy(q);
  end;
end;

procedure RegisterTermEventQueueTests;
begin
  RegisterTest(TTermEventQueueBasic);
end;

end.


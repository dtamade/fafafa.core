{$CODEPAGE UTF8}
unit Test_term_events_collect;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermEventsCollect = class(TTestCase)
  private
    FTerm: pterm_t;
    FQ: pterm_event_queue_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_TermEventsCollect_Budget_And_Compose;
  end;

implementation

var
  gPullCount: Integer = 0;

function FakePullMoveBurst(aTerm: pterm_t; aTimeout: UInt64): Boolean;
var
  i: Integer;
  ev: term_event_t;
begin
  // 组合一组“可合并的 MouseMove + 后续 Key”的事件，模拟单帧输入洪峰
  // 仅在首次调用时注入；之后返回 False，避免预算内重复注入影响断言
  if gPullCount > 0 then Exit(False);
  for i := 1 to 2 do
  begin
    ev := term_event_mouse(i, i, tms_moved, tmb_none, False, False, False);
    term_event_push(aTerm, ev);
  end;
  // 紧接一个键盘事件，确保“尾合并 MouseMove，但保留后续 Key”
  ev := term_event_key(KEY_Q, WideChar(#0), False, False, False);
  term_event_push(aTerm, ev);
  Inc(gPullCount);
  Result := True;
end;

procedure TTestCase_TermEventsCollect.SetUp;
begin
  gPullCount := 0;
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  FQ := term_event_queue_create;
  FTerm^.event_queue := FQ;
  FTerm^.event_pull := @FakePullMoveBurst;
end;

procedure TTestCase_TermEventsCollect.TearDown;
begin
  if Assigned(FTerm) then
  begin
    if Assigned(FTerm^.event_queue) then
      term_event_queue_destroy(FTerm^.event_queue);
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermEventsCollect.Test_TermEventsCollect_Budget_And_Compose;
var
  Arr: array[0..7] of term_event_t;
  N: SizeUInt;
  i: Integer;
  moveCount, keyCount: Integer;
begin
  FillByte(Arr, SizeOf(Arr), 0);
  // 预算为 5ms，足以执行一次 FakePullMoveBurst；数组容量足够容纳单次注入
  N := term_events_collect(FTerm, Arr, Length(Arr), 5);
  CheckTrue((N >= 2) and (N <= 3), 'should have merged move + key, not more than injected once');
  moveCount := 0; keyCount := 0;
  for i := 0 to N - 1 do
  begin
    if Arr[i].kind = tek_mouse then
    begin
      Inc(moveCount);
      // 应为最后一次 move(2,2)
      CheckEquals(2, Arr[i].mouse.x);
      CheckEquals(2, Arr[i].mouse.y);
    end
    else if Arr[i].kind = tek_key then
      Inc(keyCount);
  end;
  CheckEquals(1, moveCount, 'merge consecutive moves into one');
  CheckEquals(1, keyCount,  'keep subsequent key event');
end;

initialization
  RegisterTest(TTestCase_TermEventsCollect);
end.


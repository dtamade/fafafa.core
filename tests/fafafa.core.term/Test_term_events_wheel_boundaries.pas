{$CODEPAGE UTF8}
unit Test_term_events_wheel_boundaries;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermEvents_WheelBoundaries = class(TTestCase)
  private
    FTerm: pterm_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Wheel_Aggregation_Split_By_Key;
    procedure Test_Wheel_Direction_Reverse_Splits;
  end;

implementation

procedure TTestCase_TermEvents_WheelBoundaries.SetUp;
begin
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  FTerm^.event_queue := term_event_queue_create;
  // 不设置 event_pull，针对已有队列直接注入测试数据
end;

procedure TTestCase_TermEvents_WheelBoundaries.TearDown;
begin
  if Assigned(FTerm) then
  begin
    if Assigned(FTerm^.event_queue) then
      term_event_queue_destroy(FTerm^.event_queue);
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermEvents_WheelBoundaries.Test_Wheel_Aggregation_Split_By_Key;
var
  Arr: array[0..15] of term_event_t;
  N, i: SizeUInt;
  wheelCount: Integer;
begin
  // Wheel(+1), Wheel(+1), Key, Wheel(+1) => 应形成两段 wheel：前段聚合、后段单独
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_key(KEY_X, WideChar(#0), False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  wheelCount := 0;
  for i := 0 to N - 1 do
    if (Arr[i].kind = tek_mouse) and (Arr[i].mouse.button = Ord(tmb_wheel_up)) then
      Inc(wheelCount);
  // 期望至少 2 个 wheel 段（前段聚合为一个，后段为一个）
  CheckTrue(wheelCount >= 2, 'wheel aggregation should split at key and preserve segments');
end;

procedure TTestCase_TermEvents_WheelBoundaries.Test_Wheel_Direction_Reverse_Splits;
var
  Arr: array[0..15] of term_event_t;
  N, i: SizeUInt;
  upCount, downCount: Integer;
begin
  // Wheel(+1), Wheel(+1), Wheel(-1) => 方向反转切段，应至少出现 up 段和 down 段各一次
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_up, False, False, False));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_wheel_down, False, False, False));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  upCount := 0; downCount := 0;
  for i := 0 to N - 1 do
    if (Arr[i].kind = tek_mouse) then
    begin
      if Arr[i].mouse.button = Ord(tmb_wheel_up) then Inc(upCount)
      else if Arr[i].mouse.button = Ord(tmb_wheel_down) then Inc(downCount);
    end;
  CheckTrue((upCount >= 1) and (downCount >= 1), 'wheel direction reversal should split segments');
end;

initialization
  RegisterTest(TTestCase_TermEvents_WheelBoundaries);

end.


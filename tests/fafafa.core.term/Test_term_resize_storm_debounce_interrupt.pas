{$CODEPAGE UTF8}
unit Test_term_resize_storm_debounce_interrupt;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermResize_Storm_Interrupt = class(TTestCase)
  private
    FTerm: pterm_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Resize_Storm_Interrupted_By_MousePress;
  end;

implementation

procedure TTestCase_TermResize_Storm_Interrupt.SetUp;
begin
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  FTerm^.event_queue := term_event_queue_create;
end;

procedure TTestCase_TermResize_Storm_Interrupt.TearDown;
begin
  if Assigned(FTerm) then
  begin
    if Assigned(FTerm^.event_queue) then
      term_event_queue_destroy(FTerm^.event_queue);
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermResize_Storm_Interrupt.Test_Resize_Storm_Interrupted_By_MousePress;
var
  Arr: array[0..15] of term_event_t;
  N, i: SizeUInt;
  resizeCount, pressCount: Integer;
begin
  // 多次 resize 后 mouse press，再继续 resize。期望形成两个 resize 段（各保留最后一个），press 保留
  term_event_queue_clear(FTerm^.event_queue);
  term_event_push(FTerm, term_event_size_change(80,24));
  term_event_push(FTerm, term_event_size_change(100,30));
  term_event_push(FTerm, term_event_mouse(0,0, tms_press, tmb_left, False, False, False));
  term_event_push(FTerm, term_event_size_change(120,40));

  FillByte(Arr, SizeOf(Arr), 0);
  N := term_events_collect(FTerm, Arr, Length(Arr), 0);

  resizeCount := 0; pressCount := 0;
  for i := 0 to N - 1 do
    case Arr[i].kind of
      tek_sizeChange: Inc(resizeCount);
      tek_mouse: if Arr[i].mouse.state = Ord(tms_press) then Inc(pressCount);
    end;
  CheckTrue(resizeCount >= 2, 'resize debounce should split at mouse press and keep last of each segment');
  CheckEquals(1, pressCount, 'mouse press should be preserved');
end;

initialization
  RegisterTest(TTestCase_TermResize_Storm_Interrupt);

end.


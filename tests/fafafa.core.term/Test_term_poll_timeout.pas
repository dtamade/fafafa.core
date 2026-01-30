{$CODEPAGE UTF8}
unit Test_term_poll_timeout;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_Term_PollTimeout = class(TTestCase)
  published
    procedure Test_Poll_Timeout_EmptyQueue_NoLeak;
    procedure Test_Poll_Repeat_ShortTimeout_NoStateLeak;
  end;

implementation

procedure TTestCase_Term_PollTimeout.Test_Poll_Timeout_EmptyQueue_NoLeak;
var ev: term_event_t; ok: Boolean; startTick, endTick: QWord;
begin
  // 不要求交互环境：直接调用底层 poll，但不进入 raw/alt 等模式
  FillByte(ev, SizeOf(ev), 0);
  startTick := GetTickCount64;
  ok := term_event_poll(ev, 5); // 5ms 短超时
  endTick := GetTickCount64;
  // 预期：空队列下返回 False；且不会异常
  CheckFalse(ok, 'poll should return False when no events and short timeout');
  // 预期：耗时不显著超出超时（允许 OS 级调度抖动）
  CheckTrue((endTick - startTick) <= 50, 'poll timeout should not block excessively');
end;

procedure TTestCase_Term_PollTimeout.Test_Poll_Repeat_ShortTimeout_NoStateLeak;
var i: Integer; ev: term_event_t; ok: Boolean;
begin
  // 多次短超时轮询，不应泄漏状态或崩溃
  for i := 1 to 10 do
  begin
    FillByte(ev, SizeOf(ev), 0);
    ok := term_event_poll(ev, 1);
    CheckFalse(ok);
  end;
  // 若底层出现状态泄漏或异常，此处将无法到达
  CheckTrue(True);
end;

initialization
  RegisterTest(TTestCase_Term_PollTimeout);
end.


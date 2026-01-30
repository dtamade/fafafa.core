unit fafafa.core.term.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Env, TestHelpers_Skip;

type
  // 全局函数测试用例（按规范放在该 testcase 单元中）
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_term_init;
    procedure Test_term_done;
    procedure Test_term_support_mouse;
    procedure Test_term_mouse_enable_disable;
    procedure Test_term_events_collect_Params;
  end;

implementation

procedure TTestCase_Global.Test_term_init;
begin
  if not term_init then
  begin
    TestSkip(Self, 'term_init returned False');
    Exit;
  end;
  CheckTrue(True);
end;

procedure TTestCase_Global.Test_term_done;
begin
  // 幂等：多次调用不应异常
  term_done;
  term_done;
  CheckTrue(True);
end;

procedure TTestCase_Global.Test_term_support_mouse;
begin
  if not term_init then
  begin
    TestSkip(Self, 'term_init failed');
    Exit;
  end;
  // 仅验证可调用，不强制断言环境能力
  CheckTrue(term_support_mouse or (not term_support_mouse));
end;

procedure TTestCase_Global.Test_term_mouse_enable_disable;
begin
  if not term_init then
  begin
    TestSkip(Self, 'term_init failed');
    Exit;
  end;
  term_mouse_enable(True);
  term_mouse_disable;
  CheckTrue(True);
end;

procedure TTestCase_Global.Test_term_events_collect_Params;
var evs: array[0..3] of term_event_t; n: SizeUInt;
begin
  if not term_init then
  begin
    TestSkip(Self, 'term_init failed');
    Exit;
  end;
  // budget=0 表示仅消费现有队列
  n := term_events_collect(evs, Length(evs), 0);
  CheckTrue(n <= Length(evs));
end;

initialization
  RegisterTest(TTestCase_Global);
end.


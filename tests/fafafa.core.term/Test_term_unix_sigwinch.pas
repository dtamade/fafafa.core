{$CODEPAGE UTF8}
unit Test_term_unix_sigwinch;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  fafafa.core.signal;

type
  TTestCase_UnixSigwinch = class(TTestCase)
  published
    procedure Test_Sigwinch_Pushes_SizeChange_On_Pull;
  end;

implementation

{$IFDEF UNIX}

procedure TTestCase_UnixSigwinch.Test_Sigwinch_Pushes_SizeChange_On_Pull;
var
  Ev: term_event_t;
begin
  term_init;
  try
    // 模拟 SIGWINCH 标志（不直接发信号，避免测试环境依赖）
    // 通过导出的 push API 无法设置标志，因此调用 sizeChange push 作为基线已在其他测试覆盖
    // 这里使用 term_event_poll 驱动 pull，依赖实现检查全局标志
    // 通过 signal center 注入 sgWinch 驱动事件派发（非真实信号）
    SignalCenter.Start;
    SignalCenter.InjectForTest(sgWinch);
    Sleep(10);
    CheckTrue(term_event_poll(Ev, 0));
    AssertEquals(Ord(tek_sizeChange), Ord(Ev.kind));
  finally
    term_done;
  end;
end;

{$ENDIF}

initialization
  RegisterTest(TTestCase_UnixSigwinch);

end.


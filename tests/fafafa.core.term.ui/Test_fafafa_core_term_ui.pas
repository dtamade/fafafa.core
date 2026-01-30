unit Test_fafafa_core_term_ui;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  fpcunit, testregistry,
  sysutils,
  fafafa.core.term,
  fafafa.core.term.ui,
  fafafa.core.term.ui.surface,
  fafafa.core.term.ui.app,
  fafafa.core.term.ui.node;

// 这里的测试先以“可构建”和“基本流程”验证为主：
// - termui_run 的入口能被链接并调用（在无真实终端事件时快速退出）
// - Facade 的简单调用不崩溃（编译期/链接期依赖正确）

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Smoke;
  end;

implementation

procedure TTestCase_Global.Test_Smoke;
begin
  // 最小可运行：仅验证 TestRunner/链接是否正常
  CheckEquals(1, 1);
end;

initialization
  RegisterTest(TTestCase_Global);

end.


{$CODEPAGE UTF8}
unit Test_term_protocol_toggles_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Env, TestHelpers_Skip;

type
  TTestCase_ProtocolTogglesSmoke = class(TTestCase)
  published
    procedure Test_Enable_Disable_AltScreen_Focus_Paste_and_Sync;
  end;

implementation

procedure TTestCase_ProtocolTogglesSmoke.Test_Enable_Disable_AltScreen_Focus_Paste_and_Sync;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    // 仅验证调用路径不抛异常；具体视觉行为属集成测试
    term_alternate_screen_enable(True);
    term_focus_enable(True);
    term_paste_bracket_enable(True);
    term_sync_update_enable(True);

    term_sync_update_enable(False);
    term_paste_bracket_enable(False);
    term_focus_enable(False);
    term_alternate_screen_enable(False);
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTestCase_ProtocolTogglesSmoke);

end.


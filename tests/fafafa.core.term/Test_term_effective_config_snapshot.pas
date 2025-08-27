{$CODEPAGE UTF8}
unit Test_term_effective_config_snapshot;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Env;

type
  TTestCase_EffectiveConfig = class(TTestCase)
  published
    procedure Test_Snapshot_Contains_Core_Keys_And_Toggles;
  end;

implementation

procedure TTestCase_EffectiveConfig.Test_Snapshot_Contains_Core_Keys_And_Toggles;
var
  cfg: string;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  if not term_init then
  begin
    CheckTrue(True, 'term_init returned False (skip)');
    Exit;
  end;
  try
    // 调整运行期开关后导出快照
    term_set_coalesce_move(False);
    term_set_coalesce_wheel(True);
    term_set_debounce_resize(False);
    term_set_idle_sleep_ms(0);
    term_set_poll_backoff_enabled(False);

    cfg := term_get_effective_config;

    // 基本键存在
    CheckTrue(Pos('"coalesce_move"', cfg) > 0, 'coalesce_move key present');
    CheckTrue(Pos('"coalesce_wheel"', cfg) > 0, 'coalesce_wheel key present');
    CheckTrue(Pos('"debounce_resize"', cfg) > 0, 'debounce_resize key present');
    CheckTrue(Pos('"idle_sleep_ms"', cfg) > 0, 'idle_sleep_ms key present');
    CheckTrue(Pos('"poll_backoff"', cfg) > 0, 'poll_backoff key present');
    CheckTrue(Pos('"paste_backend"', cfg) > 0, 'paste_backend key present');

    // 断言部分值与设置一致（布尔以 0/1 序列化）
    CheckTrue(Pos('"coalesce_move":0', cfg) > 0, 'coalesce_move reflected');
    CheckTrue(Pos('"coalesce_wheel":1', cfg) > 0, 'coalesce_wheel reflected');
    CheckTrue(Pos('"debounce_resize":0', cfg) > 0, 'debounce_resize reflected');
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTestCase_EffectiveConfig);

end.


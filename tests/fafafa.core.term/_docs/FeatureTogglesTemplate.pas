unit FeatureTogglesTemplate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.term;

type
  TTest_FeatureToggles = class(TTestCase)
  published
    procedure Test_AlternateScreen_Enable_Disable_Idempotent;
  end;

implementation

uses tests.fafafa.core.term.TestHelpers_Env, tests.fafafa.core.term.TestHelpers_Skip;

procedure TTest_FeatureToggles.Test_AlternateScreen_Enable_Disable_Idempotent;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    if term_support_alternate_screen then
    begin
      CheckTrue(term_alternate_screen_enable(True));
      CheckTrue(term_alternate_screen_disable);
      // 幂等：再次 disable 不应失败
      CheckTrue(term_alternate_screen_disable);
    end
    else
      TestSkip(Self, 'alternate screen not supported');
  finally
    // 避免遗留切换状态
    if term_support_alternate_screen then term_alternate_screen_disable;
    term_done;
  end;
end;

initialization
  RegisterTest(TTest_FeatureToggles);

end.

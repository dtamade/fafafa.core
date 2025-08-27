{$CODEPAGE UTF8}
unit Test_unix_feature_overrides;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.env,
  fafafa.core.term;

procedure RegisterTests;

implementation

procedure WithEnv(const Name, Value: string; const Proc: TProc);
var Snap: TEnvSnapshot;
begin
  Snap := env_snapshot([Name], []);
  try
    env_set(Name, Value);
    Proc();
  finally
    Snap.Restore;
  end;
end;

function NewTermOrNil: pterm_t;
begin
  // 允许返回 nil（例如在某些 CI 环境不具交互终端时），用例将以宽松断言处理
  Result := term_default_create_or_get;
end;

function CompatHas(const T: pterm_t; Cap: term_capability_t): Boolean;
begin
  if T = nil then Exit(False);
  Result := term_support_compatible(T, Cap);
end;

procedure Test_Focus_Override_On_Off;
var T: pterm_t;
begin
  WithEnv('FAFAFA_TERM_FEATURE_FOCUS', 'on', procedure
  begin
    T := NewTermOrNil;
    fpcunit.TAssert.AssertTrue('focus override ON ⇒ tc_focus_1004 or no-term', (T=nil) or CompatHas(T, tc_focus_1004));
  end);

  WithEnv('FAFAFA_TERM_FEATURE_FOCUS', 'off', procedure
  begin
    T := NewTermOrNil;
    fpcunit.TAssert.AssertTrue('focus override OFF ⇒ no tc_focus_1004 or no-term', (T=nil) or (not CompatHas(T, tc_focus_1004)));
  end);
end;

procedure Test_Paste_Override_On_Off;
var T: pterm_t;
begin
  WithEnv('FAFAFA_TERM_FEATURE_PASTE', 'on', procedure
  begin
    T := NewTermOrNil;
    fpcunit.TAssert.AssertTrue('paste override ON ⇒ tc_paste_2004 or no-term', (T=nil) or CompatHas(T, tc_paste_2004));
  end);

  WithEnv('FAFAFA_TERM_FEATURE_PASTE', 'off', procedure
  begin
    T := NewTermOrNil;
    fpcunit.TAssert.AssertTrue('paste override OFF ⇒ no tc_paste_2004 or no-term', (T=nil) or (not CompatHas(T, tc_paste_2004)));
  end);
end;


procedure RegisterTests;
begin
  RegisterTest('UnixFeatureOverrides',@Test_Focus_Override_On_Off);
  RegisterTest('UnixFeatureOverrides',@Test_Paste_Override_On_Off);
end;

initialization
  RegisterTests;
end.


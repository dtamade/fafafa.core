{$CODEPAGE UTF8}
unit Test_term_feature_toggles_getset;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermFeatureToggles_GetSet = class(TTestCase)
  published
    procedure Test_Defaults_And_GetSet;
  end;

implementation

procedure TTestCase_TermFeatureToggles_GetSet.Test_Defaults_And_GetSet;
var
  mv0, wh0, rz0: Boolean;
begin
  // 记录初始状态
  mv0 := term_get_coalesce_move;
  wh0 := term_get_coalesce_wheel;
  rz0 := term_get_debounce_resize;

  // 开关写入并读取验证
  term_set_coalesce_move(False);
  term_set_coalesce_wheel(False);
  term_set_debounce_resize(False);
  AssertFalse('coalesce_move off', term_get_coalesce_move);
  AssertFalse('coalesce_wheel off', term_get_coalesce_wheel);
  AssertFalse('debounce_resize off', term_get_debounce_resize);

  term_set_coalesce_move(True);
  term_set_coalesce_wheel(True);
  term_set_debounce_resize(True);
  AssertTrue('coalesce_move on', term_get_coalesce_move);
  AssertTrue('coalesce_wheel on', term_get_coalesce_wheel);
  AssertTrue('debounce_resize on', term_get_debounce_resize);

  // 复原
  term_set_coalesce_move(mv0);
  term_set_coalesce_wheel(wh0);
  term_set_debounce_resize(rz0);
end;

initialization
  RegisterTest(TTestCase_TermFeatureToggles_GetSet);

end.


unit fafafa.core.term.ui.style;

{$mode objfpc}{$H+}

interface

uses
  ui_style; // 暂用原实现

type
  TUiColor = ui_style.TUiColor;
  TUiStyle = ui_style.TUiStyle;
  TUiTheme = ui_style.TUiTheme;

procedure UiStyleApply(const S: TUiStyle);
procedure UiStyleReset;

procedure UiThemeUseDark;
procedure UiThemeUseLight;
function UiThemeGetListRowNormalStyle: TUiStyle;
function UiThemeGetListRowSelectedStyle: TUiStyle;
function UiThemeGetScrollTrackStyle: TUiStyle;
function UiThemeGetScrollThumbStyle: TUiStyle;
function UiThemeGetTabActiveStyle: TUiStyle;
function UiThemeGetTabInactiveStyle: TUiStyle;
function UiThemeGetStatusBarStyle: TUiStyle;

implementation

procedure UiStyleApply(const S: TUiStyle); begin ui_style.UiStyleApply(S); end;
procedure UiStyleReset; begin ui_style.UiStyleReset; end;

procedure UiThemeUseDark; begin ui_style.UiThemeUseDark; end;
procedure UiThemeUseLight; begin ui_style.UiThemeUseLight; end;
function UiThemeGetListRowNormalStyle: TUiStyle; begin Result := ui_style.UiThemeGetListRowNormalStyle; end;
function UiThemeGetListRowSelectedStyle: TUiStyle; begin Result := ui_style.UiThemeGetListRowSelectedStyle; end;
function UiThemeGetScrollTrackStyle: TUiStyle; begin Result := ui_style.UiThemeGetScrollTrackStyle; end;
function UiThemeGetScrollThumbStyle: TUiStyle; begin Result := ui_style.UiThemeGetScrollThumbStyle; end;
function UiThemeGetTabActiveStyle: TUiStyle; begin Result := ui_style.UiThemeGetTabActiveStyle; end;
function UiThemeGetTabInactiveStyle: TUiStyle; begin Result := ui_style.UiThemeGetTabInactiveStyle; end;
function UiThemeGetStatusBarStyle: TUiStyle; begin Result := ui_style.UiThemeGetStatusBarStyle; end;

end.


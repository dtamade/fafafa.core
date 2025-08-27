unit ui_style;

{$mode objfpc}{$H+}

interface

uses
  ui_surface;

// Minimal theming & style primitives for high customizability
// - Theme tokens for common roles
// - Per-component style overrides
// - Simple apply/reset helpers (currently fg/bg only)

 type
  TUiColor = record
    R, G, B: Integer;
  end;

  TUiStyle = record
    Fg, Bg: TUiColor;
    HasFg, HasBg: Boolean;
    // TODO: Bold/Underline/Reverse when term layer supports it
  end;

  TUiTheme = record
    // Base palette
    BgSurface: TUiColor;
    BgElevated: TUiColor;
    FgPrimary: TUiColor;
    FgMuted: TUiColor;
    Accent: TUiColor;
    // Components
    ListRowNormalFg: TUiColor;
    ListRowNormalBg: TUiColor;
    ListRowSelectedFg: TUiColor;
    ListRowSelectedBg: TUiColor;
    ScrollbarTrackFg: TUiColor; // single-column glyph color
    ScrollbarThumbFg: TUiColor;
    // Tabs
    TabActiveFg: TUiColor;
    TabActiveBg: TUiColor;
    TabInactiveFg: TUiColor;
    TabInactiveBg: TUiColor;
    // StatusBar
    StatusFg: TUiColor;
    StatusBg: TUiColor;
  end;

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

var
  GTheme: TUiTheme;

function Color(R,G,B: Integer): TUiColor;
begin
  Result.R := R; Result.G := G; Result.B := B;
end;

function MakeStyleFgBg(Fg, Bg: TUiColor): TUiStyle;
begin
  Result.Fg := Fg; Result.Bg := Bg; Result.HasFg := True; Result.HasBg := True;
end;

procedure UiStyleApply(const S: TUiStyle);
begin
  if S.HasBg then UiSetBg24(S.Bg.R, S.Bg.G, S.Bg.B);
  if S.HasFg then UiSetFg24(S.Fg.R, S.Fg.G, S.Fg.B);
end;

procedure UiStyleReset;
begin
  UiAttrReset;
end;

procedure UiThemeUseDark;
begin
  // Dark theme tokens (tweak later)
  GTheme.BgSurface := Color(24,24,24);
  GTheme.BgElevated := Color(34,34,34);
  GTheme.FgPrimary := Color(220,220,220);
  GTheme.FgMuted := Color(160,160,160);
  GTheme.Accent := Color(90,130,220);

  GTheme.ListRowNormalFg := GTheme.FgPrimary;
  GTheme.ListRowNormalBg := GTheme.BgSurface;
  GTheme.ListRowSelectedFg := Color(240,240,240);
  GTheme.ListRowSelectedBg := Color(70,90,140);

  GTheme.ScrollbarTrackFg := Color(110,110,110);
  GTheme.ScrollbarThumbFg := Color(200,200,200);

  // Tabs (dark): active uses Accent on elevated; inactive muted on surface
  GTheme.TabActiveFg := Color(250,250,250);
  GTheme.TabActiveBg := Color(50,50,70);
  GTheme.TabInactiveFg := GTheme.FgMuted;
  GTheme.TabInactiveBg := GTheme.BgSurface;

  // StatusBar
  GTheme.StatusFg := Color(220,220,220);
  GTheme.StatusBg := Color(40,40,40);
end;

procedure UiThemeUseLight;
begin
  GTheme.BgSurface := Color(245,245,245);
  GTheme.BgElevated := Color(255,255,255);
  GTheme.FgPrimary := Color(20,20,20);
  GTheme.FgMuted := Color(90,90,90);
  GTheme.Accent := Color(40,100,220);

  GTheme.ListRowNormalFg := GTheme.FgPrimary;
  GTheme.ListRowNormalBg := GTheme.BgSurface;
  GTheme.ListRowSelectedFg := Color(20,20,20);
  GTheme.ListRowSelectedBg := Color(200,210,245);

  GTheme.ScrollbarTrackFg := Color(170,170,170);
  GTheme.ScrollbarThumbFg := Color(80,80,80);

  // Tabs (light)
  GTheme.TabActiveFg := Color(20,20,20);
  GTheme.TabActiveBg := Color(210,220,255);
  GTheme.TabInactiveFg := GTheme.FgMuted;
  GTheme.TabInactiveBg := GTheme.BgSurface;

  // StatusBar
  GTheme.StatusFg := Color(20,20,20);
  GTheme.StatusBg := Color(230,230,230);
end;

function UiThemeGetListRowNormalStyle: TUiStyle;
begin
  Result := MakeStyleFgBg(GTheme.ListRowNormalFg, GTheme.ListRowNormalBg);
end;

function UiThemeGetListRowSelectedStyle: TUiStyle;
begin
  Result := MakeStyleFgBg(GTheme.ListRowSelectedFg, GTheme.ListRowSelectedBg);
end;

function UiThemeGetScrollTrackStyle: TUiStyle;
begin
  Result := MakeStyleFgBg(GTheme.ScrollbarTrackFg, Color(-1,-1,-1));
  Result.HasBg := False; // glyph only
end;

function UiThemeGetScrollThumbStyle: TUiStyle;
begin
  Result := MakeStyleFgBg(GTheme.ScrollbarThumbFg, Color(-1,-1,-1));
  Result.HasBg := False; // glyph only
end;

function UiThemeGetTabActiveStyle: TUiStyle;
begin
  Result := MakeStyleFgBg(GTheme.TabActiveFg, GTheme.TabActiveBg);
end;

function UiThemeGetTabInactiveStyle: TUiStyle;
begin
  Result := MakeStyleFgBg(GTheme.TabInactiveFg, GTheme.TabInactiveBg);
end;

function UiThemeGetStatusBarStyle: TUiStyle;
begin
  Result := MakeStyleFgBg(GTheme.StatusFg, GTheme.StatusBg);
end;

initialization
  UiThemeUseDark;

end.


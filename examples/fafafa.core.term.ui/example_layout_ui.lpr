program example_layout_ui;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  sysutils,
  fafafa.core.term, fafafa.core.term.ui,
  ui_node, ui_style;

var
  FrameCounter: QWord = 0;
  ShowOverlay: Boolean = False;
  FpsEma: Double = 0.0;
  LastStamp: TDateTime = 0;
  FpsAlpha: Double = 0.25;


procedure MidPanelOverlay(const R: TUiRect);
var msg: UnicodeString;
begin
  msg := Format('MidPanel Rect x=%d y=%d w=%d h=%d', [R.X, R.Y, R.W, R.H]);
  termui_set_attr(termui_attr_preset_info);
  termui_write_at_clipped(R.Y + R.H div 2, R.X + 1, R.W - 2, msg);
  termui_attr_reset;
end;

procedure OverlayProc;
var
  w,h: Word;
  msg, fpsStr: UnicodeString;
  nowStamp: TDateTime;
  dtSec, instFPS: Double;
begin
  Inc(FrameCounter);

  nowStamp := Now;
  if LastStamp <> 0 then
  begin
    dtSec := (nowStamp - LastStamp) * 86400.0; // seconds
    if dtSec > 0 then
    begin
      instFPS := 1.0 / dtSec;
      if FpsEma = 0 then FpsEma := instFPS
      else FpsEma := FpsAlpha * instFPS + (1.0 - FpsAlpha) * FpsEma;
    end;
  end;
  LastStamp := nowStamp;

  fpsStr := Format('%.1f', [FpsEma]);

  if term_size(w,h) then
    msg := Format('Overlay · %dx%d · 24bit:%s · fps:%s · frame:%d',
      [w, h, BoolToStr(term_support_color_24bit, True), fpsStr, FrameCounter])
  else
    msg := Format('Overlay · 24bit:%s · fps:%s · frame:%d',
      [BoolToStr(term_support_color_24bit, True), fpsStr, FrameCounter]);

  termui_set_attr(termui_attr_preset_info);
  termui_write_at_clipped(0, 2, 60, msg);
  termui_attr_reset;
end;



procedure UpdateStatus(S: TStatusBarNode; const DbgOn, OvOn: Boolean);
var
  dbgTxt, ovTxt: UnicodeString;
begin
  if S <> nil then
  begin
    if DbgOn then dbgTxt := 'Y' else dbgTxt := 'N';
    if OvOn then ovTxt := 'Y' else ovTxt := 'N';
    S.SetText(Format('ANSI:%s  24bit:%s  Depth:%d  |  D:%s  O:%s',
      [BoolToStr(SupportsColor, True), BoolToStr(term_support_color_24bit, True), TTerminalInfo.Create.GetColorDepth, dbgTxt, ovTxt]));
  end;
end;


var
  Root: IUiNode;
  RootObj: TStackRootNode;
  VBox: TVBoxNode;
  HBox: THBoxNode;
  Banner: TBannerNode;
  Status: TStatusBarNode;
  LeftPanel, MidPanel, RightPanel: TPanelNode;
  UseAltPreset: Boolean = False;
  FirstFrame: Boolean = True;

procedure RenderProc;
var w,h: Word;
begin
  // Always clear to avoid residual content
  termui_clear;
  // Debug via stdout to confirm RenderProc is called even if term drawing is broken
  System.Writeln('RenderProc: called');
  if Assigned(RootObj) then
    RootObj.Render;
  FirstFrame := False;
end;

function HandleEvent(const E: term_event_t): boolean;
begin
  // Toggle theme with T (Dark/Light)
  if (E.kind = tek_key) and (termui_key_is(E, ['t','T']) or (E.key.key = KEY_T)) then
  begin
    UseAltPreset := not UseAltPreset;
    if UseAltPreset then
    begin
      UiThemeUseLight;
      Banner.SetText('Layout Demo · Light Theme (T to toggle)');
      LeftPanel.SetBgColor(235,235,245);
      MidPanel.SetBgColor(250,250,250);
      RightPanel.SetBgColor(245,235,235);
    end
    else
    begin
      UiThemeUseDark;
      Banner.SetText('Layout Demo · Dark Theme (T to toggle)');
      LeftPanel.SetBgColor(32,32,64);
      MidPanel.SetBgColor(24,24,24);
      RightPanel.SetBgColor(64,32,32);
    end;
    UpdateStatus(Status, HBox.DebugDecorate, ShowOverlay);
    termui_invalidate;
    Exit(True);
  end;
  // Toggle debug decorate with D
  if (E.kind = tek_key) and (termui_key_is(E, ['d','D']) or (E.key.key = KEY_D)) then
  begin
    HBox.SetDebugDecorate(not HBox.DebugDecorate);
    VBox.SetDebugDecorate(HBox.DebugDecorate);
    UpdateStatus(Status, HBox.DebugDecorate, ShowOverlay);
    termui_invalidate;
    Exit(True);
  end;
  // Toggle overlay with O
  if (E.kind = tek_key) and (termui_key_is(E, ['o','O']) or (E.key.key = KEY_O)) then
  begin
    ShowOverlay := not ShowOverlay;
    if ShowOverlay then
    begin
      FrameCounter := 0;
      LastStamp := 0;
      FpsEma := 0.0;
      termui_set_overlay(@OverlayProc);
    end
    else
    begin
      termui_set_overlay(nil);
    end;
    UpdateStatus(Status, HBox.DebugDecorate, ShowOverlay);
    termui_invalidate;
    Exit(True);
  end;
  // Window size change
  if (E.kind = tek_sizeChange) then
  begin
    UpdateStatus(Status, HBox.DebugDecorate, ShowOverlay);
    termui_invalidate;
    Exit(True);
  end;
  // Q to quit
  if (E.kind = tek_key) and (termui_key_is(E, ['q','Q']) or (E.key.key = KEY_Q)) then exit(false);
  Result := true;
end;

function AppHandleEvent(const E: term_event_t): boolean;
begin
  // Debug: echo that we received an event
  termui_writeln('Got event');
  termui_invalidate;
  // 先由示例处理快捷键；若未退出，再把事件传给节点树（预留将来组件级交互）
  Result := HandleEvent(E);
  if Result and Assigned(Root) then
    Result := Root.HandleEvent(E);
end;

begin
  // Build a simple layout tree: Banner (top, 1 line) + HBox (center) + Status (bottom, 1 line)
  RootObj := TStackRootNode.Create;
  Root := RootObj; // keep interface for termui_run_node



  VBox := TVBoxNode.Create;
  VBox.SetPadding(0,0,0,0);
  VBox.SetGap(1);

  Banner := TBannerNode.Create('fafafa.core.term.ui · Layout Demo (Q to quit)');
  // Ensure banner text reflects theme toggle to给出视觉反馈
  if UseAltPreset then Banner.SetText('Layout Demo · Light Theme (T to toggle)') else Banner.SetText('Layout Demo · Dark Theme (T to toggle)');
  // Show runtime capabilities
  Status := TStatusBarNode.Create(
    Format('ANSI:%s  24bit:%s  Depth:%d',
      [BoolToStr(SupportsColor, True), BoolToStr(term_support_color_24bit, True), TTerminalInfo.Create.GetColorDepth]
    ), true);

  // Center area: HBox = Left fixed sidebar + Mid flex + Right fixed
  HBox := THBoxNode.Create;
  HBox.SetGap(2);

  LeftPanel := TPanelNode.Create(32,32,64, ' ');
  MidPanel  := TPanelNode.Create(24,24,24, ' ');
  RightPanel := TPanelNode.Create(64,32,32, ' ');

  HBox.AddFixed(LeftPanel, 24);
  HBox.AddFlex(MidPanel, 1);
  HBox.AddFixed(RightPanel, 24);

  // Assemble VBox: top banner (1 line), center flex (HBox), bottom status (1 line)
  VBox.AddFixed(Banner, 1);
  VBox.AddFlex(HBox, 1);
  VBox.AddFixed(Status, 1);
  // Show MidPanel rect & size overlay via OnRender callback
  MidPanel.OnRender := @MidPanelOverlay;


  RootObj.Add(VBox);

  // Initialize status bar to include debug/overlay flags
  UpdateStatus(Status, HBox.DebugDecorate, ShowOverlay);

  // Demo: disable backbuffer so attr (24bit color) changes take effect immediately on draw
  termui_set_backbuffer_enabled(False);
  // Ensure first frame draws even if no events
  termui_invalidate;
  // Use app loop with custom render+event to接入快捷键，并保持节点树渲染
  termui_run(@RenderProc, @AppHandleEvent);
end.


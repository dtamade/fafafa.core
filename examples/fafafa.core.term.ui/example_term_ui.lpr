program example_term_ui;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  sysutils, typinfo,
  fafafa.core.term, fafafa.core.term.ui, fafafa.core.term.ui.surface, ui_surface,
  fafafa.core.color;

function ReadAllText(const path: string): string;
var f: TextFile; s,line: string;
begin
  s := '';
  AssignFile(f, path);
  {$I-} Reset(f); {$I+}
  if IOResult<>0 then Exit('');
  while not Eof(f) do begin ReadLn(f, line); s := s + line; end;
  CloseFile(f);
  ReadAllText := s;
end;

var
  GSharedPS: IPaletteStrategy = nil;
  GStatusMsg: UnicodeString = '';


  // 读取并应用共享策略颜色（示意：状态栏使用）
  var barBg, barFg: term_color_24bit_t;
  procedure ApplySharedSample;
  var c: color_rgba_t;
  begin
    if GSharedPS<>nil then begin
      c := GSharedPS.Sample(0.2);
      barBg := term_color_24bit_rgb(0,0,0);
      barFg := term_color_24bit_rgb(c.r, c.g, c.b);
    end
    else begin
      barBg := term_color_24bit_rgb(0,0,0);
      barFg := term_color_24bit_rgb(200,200,200);
    end;
  end;

var
  GCursPolicy: TUiCursorAfterFramePolicy = ucpAuto;
procedure Render;
var
  w,h: term_size_t;
  info: TTerminalInfo;
  status: UnicodeString;
begin
  // Begin a frame to enable backbuffer + diff output
  termui_frame_begin;
  try
    // Determine terminal size (0-based UI coordinates)
    if not term_size(w,h) then begin w := 80; h := 24; end;

    // Clear and draw a banner line
    termui_clear;
    termui_set_attr(termui_attr_preset_info);
    termui_fill_line(0, ' ', -1);
    termui_write_at(0, 0, 'fafafa.term.ui demo - press Q to quit (press T to toggle color preset, press P to toggle cursor policy)');
    termui_attr_reset;

    // Fill content area (excluding banner/status)
    if h > 2 then
    begin
      termui_set_attr(termui_attr_preset_warn);
      termui_fill_rect(0, 1, w, h-2, ' ');
      termui_attr_reset;
    end;

    // Status bar at bottom with runtime capability info
    if h > 1 then
    begin
      // Build capability info and show cursor policy
      status := Format('Size: %d x %d  |  ColorDepth: %d  |  ANSI: %s  AltScreen: %s  |  CursorPolicy: %s  |  %s',
        [w, h,
         TTerminalInfo.Create.GetColorDepth,
         BoolToStr(SupportsColor, True),
         BoolToStr(term_support_alternate_screen, True),
         GetEnumName(TypeInfo(TUiCursorAfterFramePolicy), Ord(GCursPolicy)),
         GStatusMsg]);
      ApplySharedSample;
      termui_set_attr(term_attr_24bit(term_color_24bit_rgb(barFg.r,barFg.g,barFg.b), barBg, termui_attr_styles_empty));
      termui_fill_line(h-1, ' ', -1);
      termui_write_at(h-1, 0, status);
      termui_attr_reset;
    end;
  finally
    termui_frame_end;
  end;
end;

var
  useAltPreset: Boolean = False;

function HandleEvent(const E: term_event_t): boolean;
begin
  // Load shared palette strategy from color module demo
  var json: string;
  begin
    json := ReadAllText('examples'+PathDelim+'fafafa.core.color'+PathDelim+'palette_strategy.json');
    GSharedPS := palette_strategy_from_text(json);
    termui_run(@Render, @HandleEvent);
    // apply initial cursor policy before run
    termui_set_cursor_after_frame_policy(GCursPolicy);
  end;

  // 热重载共享策略：按 R 键
  if (E.kind = tek_key) and ((E.key.key = KEY_R) or (E.key.char.wchar in ['r','R'])) then
  begin
    var json: string := ReadAllText('examples'+PathDelim+'fafafa.core.color'+PathDelim+'palette_strategy.json');
    var obj: IPaletteStrategy; var err: string;
    if not palette_strategy_from_text_ex(json, obj, err) then
      GStatusMsg := 'Palette load error: '+err
    else begin
      GSharedPS := obj;
      GStatusMsg := 'Palette loaded OK';
    end;
    Exit(True);
  // 切换备用策略：按 S 键
  if (E.kind = tek_key) and ((E.key.key = KEY_S) or (E.key.char.wchar in ['s','S'])) then
  begin
    var json: string := ReadAllText('examples'+PathDelim+'fafafa.core.color'+PathDelim+'palette_strategy_alt.json');
    var obj: IPaletteStrategy; var err: string;
    if not palette_strategy_from_text_ex(json, obj, err) then
      GStatusMsg := 'Alt palette load error: '+err
    else begin
      GSharedPS := obj;
      GStatusMsg := 'Alt palette loaded OK';
    end;
    Exit(True);
  end;

  end;


  // Toggle theme/preset with T
  if (E.kind = tek_key) and ((E.key.key = KEY_T) or (E.key.char.wchar in ['t','T'])) then
  begin
    useAltPreset := not useAltPreset;
    if useAltPreset then termui_set_attr(termui_attr_preset_warn)
    else termui_set_attr(termui_attr_preset_info);
    Exit(True);
  end;

  // Toggle cursor policy with P
  if (E.kind = tek_key) and ((E.key.key = KEY_P) or (E.key.char.wchar in ['p','P'])) then
  begin
    // Cycle through policies
    if GCursPolicy = ucpAuto then GCursPolicy := ucpKeep
    else if GCursPolicy = ucpKeep then GCursPolicy := ucpToOrigin
    else if GCursPolicy = ucpToOrigin then GCursPolicy := ucpToBottomLeft
    else if GCursPolicy = ucpToBottomLeft then GCursPolicy := ucpToBottomRight
    else GCursPolicy := ucpAuto;
    case GCursPolicy of
      ucpAuto: GCursPolicy := ucpKeep;
      ucpKeep: GCursPolicy := ucpToOrigin;
      ucpToOrigin: GCursPolicy := ucpToBottomLeft;
      ucpToBottomLeft: GCursPolicy := ucpToBottomRight;
      ucpToBottomRight: GCursPolicy := ucpAuto;
    end;
    termui_set_cursor_after_frame_policy(GCursPolicy);
    Exit(True);
  end;
  // demo 级：Q 键退出
  if (E.kind = tek_key) and ((E.key.key = KEY_Q) or (E.key.char.wchar = 'q') or (E.key.char.wchar = 'Q')) then exit(false);
  Result := true;
end;

begin
  termui_run(@Render, @HandleEvent);
  // apply initial cursor policy before run
  termui_set_cursor_after_frame_policy(GCursPolicy);

end.


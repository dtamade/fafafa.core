unit fafafa.core.term.ui;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  fafafa.core.term.ui.types,
  fafafa.core.term.ui.surface,
  fafafa.core.term.ui.app,
  fafafa.core.term.ui.node,
  ui_backend;


  { NOTE / Best Practices:
    - Stable facade API for the UI layer. Internals live in ui_surface/ui_app/ui_node.
    - Rendering backends are abstracted via ui_backend.*; default is terminal; tests can switch to memory.
    - Coordinates are 0-based (line,col). Backend/terminal conversions (to 1-based) are handled inside ui_surface.
    - Prefer frame mode for rendering paths that involve viewport/origin/clipping:
        termui_frame_begin -> draw (write_at/fill_rect/...) -> termui_frame_end
    - Dirty region helpers (invalidate_all / invalidate_rect) are effective in frame mode to limit redraw.
    - When UiBackendGetCurrent = nil, all termui_* are safe no-ops to support headless/tests.
    - Debug hooks accept non-method procedure variables; in tests use global bridge procs if needed. }
    // Documentation: see docs/fafafa.core.term.ui.md (Quick Start / Frame Rendering / View & Clipping)
    // Testing hooks: see UiDebug_SetOutputHooks in ui_surface; prefer global bridge procs in tests.


{ Facade aliases to expose UI layer through fafafa.core.term.ui }

type
  // Re-export core UI types
  TUiRect = fafafa.core.term.ui.types.TUiRect;
  TUiPoint = fafafa.core.term.ui.types.TUiPoint;
  TUiSize  = fafafa.core.term.ui.types.TUiSize;
  TUiPadding = fafafa.core.term.ui.types.TUiPadding;

  // Re-export attr record for modern API
  TUiAttr = ui_backend.TUiAttr;

  // Re-export hook types and cursor policy via surface facade
  TUiHook_Write = fafafa.core.term.ui.surface.TUiHook_Write;
  TUiHook_Writeln = fafafa.core.term.ui.surface.TUiHook_Writeln;
  TUiHook_CursorLine = fafafa.core.term.ui.surface.TUiHook_CursorLine;
  TUiHook_CursorCol = fafafa.core.term.ui.surface.TUiHook_CursorCol;
  TUiHook_CursorVisibleSet = fafafa.core.term.ui.surface.TUiHook_CursorVisibleSet;
  TUiHook_Size = fafafa.core.term.ui.surface.TUiHook_Size;
  TUiCursorAfterFramePolicy = fafafa.core.term.ui.surface.TUiCursorAfterFramePolicy;

  // Re-export node interfaces/classes
  IUiNode = fafafa.core.term.ui.node.IUiNode;
  TStackRootNode = fafafa.core.term.ui.node.TStackRootNode;
  TBannerNode = fafafa.core.term.ui.node.TBannerNode;
  TStatusBarNode = fafafa.core.term.ui.node.TStatusBarNode;
  TPanelNode = fafafa.core.term.ui.node.TPanelNode;
  TVBoxNode = fafafa.core.term.ui.node.TVBoxNode;
  THBoxNode = fafafa.core.term.ui.node.THBoxNode;


// Application helpers
// - termui_invalidate: 标记全屏为脏区，触发下一帧重绘
// - termui_run: 运行主循环，提供渲染与事件处理回调
// - termui_run_node: 以根节点驱动 UI 渲染
procedure termui_invalidate; // mark whole screen dirty
procedure termui_run(const Render: TUiRenderProc; const HandleEvent: TUiEventProc);
procedure termui_run_node(const Root: IUiNode);
  // Cursor policy control facade
  procedure termui_set_cursor_after_frame_policy(const Policy: TUiCursorAfterFramePolicy);
// Backbuffer control (for demos using color attrs, disabling backbuffer lets attrs take effect immediately)
procedure termui_set_backbuffer_enabled(Enabled: Boolean);
// Optional: synchronized updates (?2026) behind-a-flag (default: disabled)
procedure termui_set_sync_update_enabled(Enabled: Boolean);

// Surface helpers (thin passthrough)
// - termui_clear: 清屏
// - termui_goto: 将光标定位到 (line, col)
// - termui_write/ln: 追加写入文本
// - termui_fg24/bg24: 设置 24 位前景/背景色
// - termui_attr_reset/set_attr: 重置/设置属性
// - termui_fill_line: 填充整行或 count 个字符
// - termui_write_at: 在指定位置写入
  // 参数顺序小贴士：write_at/writeln_at 接口统一采用 (line=Y, col=X)
  // 建议：涉及视口/裁剪/脏区时优先在 frame_begin/end 内调用写入与填充原语
  // 提示：优先使用 UnicodeString；如传 AnsiString，使用下面的重载避免隐式转换告警


// - termui_fill_rect: 区域填充
procedure termui_clear;
procedure termui_goto(line, col: term_size_t);
procedure termui_write(const S: UnicodeString);
procedure termui_writeln(const S: UnicodeString);
procedure termui_fg24(R,G,B: Integer);
procedure termui_bg24(R,G,B: Integer);
procedure termui_attr_reset;
procedure termui_set_attr(const Attr: TUiAttr);
procedure termui_fill_line(line: term_size_t; const ch: UnicodeChar; count: Integer = -1);
procedure termui_write_at(line, col: term_size_t; const S: UnicodeString);
procedure termui_fill_rect(x, y, w, h: term_size_t; const ch: UnicodeChar);
// View & Frame helpers
// - termui_push_view/pop_view: 设置/弹出视口与相对原点
// - termui_frame_begin/end: 开始/结束一帧
procedure termui_push_view(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t);
procedure termui_pop_view;
procedure termui_frame_begin;
procedure termui_frame_end;
// Dirty-region helpers
// - termui_invalidate_all: 标记全屏为脏
// - termui_invalidate_rect: 标记矩形区域为脏
procedure termui_invalidate_all;
procedure termui_invalidate_rect(x, y, w, h: term_size_t);

// Overloads to reduce implicit conversions in callers
// - 提供 AnsiString/AnsiChar 重载，减少隐式转换告警
procedure termui_write(const S: AnsiString); overload; inline;
procedure termui_writeln(const S: AnsiString); overload; inline;
procedure termui_write_at(line, col: term_size_t; const S: AnsiString); overload; inline;
procedure termui_fill_line(line: term_size_t; const ch: AnsiChar; count: Integer = -1); overload; inline;
procedure termui_fill_rect(x, y, w, h: term_size_t; const ch: AnsiChar); overload; inline;

// DX helpers (developer ergonomics)
// - writeln 单字符重载 / 在位置写入并换行
// - 作用域视口包装 (with_view)
//   坐标语义：ViewX/ViewY/ViewW/ViewH 使用绝对 UI 坐标；内部 Render 仍以全局(0基) UI 坐标解释 line/col
//   若希望在局部区域内以相对坐标编写，可通过 OriginX/OriginY 指定局部原点，或在 Render 中自行换算
//   Render 为“非方法过程变量”（TUiRenderProc），请使用全局过程，而非嵌套/匿名过程
// - 常用属性预设 (info/warn/error)
procedure termui_writeln(const Ch: UnicodeChar); overload;
procedure termui_writeln(const Ch: AnsiChar); overload;
procedure termui_writeln_at(line, col: term_size_t; const S: UnicodeString);
procedure termui_writeln_at(line, col: term_size_t; const S: AnsiString); overload;
// 以作用域方式开启子视口，内部自动 PushView/PopView，并进行裁剪与坐标转换
procedure termui_with_view(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t; const Render: TUiRenderProc);
function termui_attr_preset_info: TUiAttr;
function termui_attr_preset_warn: TUiAttr;
function termui_attr_preset_error: TUiAttr;

  // Convenience overload: default OriginX=0, OriginY=0
  procedure termui_with_view(ViewX, ViewY, ViewW, ViewH: term_size_t; const Render: TUiRenderProc); inline;

  // Scoped attribute application: set -> render -> reset
  procedure termui_with_attr(const Attr: TUiAttr; const Render: TUiRenderProc);

  // Text helpers
  procedure termui_write_center(line: term_size_t; const S: UnicodeString; TotalWidth: term_size_t);
  procedure termui_write_at_clipped(line, col, maxW: term_size_t; const S: UnicodeString);

  // Status line helper (clear line, apply attr, write text, reset)
  procedure termui_status_line(line: term_size_t; const S: UnicodeString; const Attr: TUiAttr);

  // Event helper: quick key matching (character keys)
  function termui_key_is(const E: term_event_t; const Keys: array of WideChar): boolean;


// Debug hooks & overlay passthrough
//
// Global frame overlay hook (optional)
// - 调用时机：每帧渲染之后、termui_frame_end 之前（渲染尾部帧内 Overlay 点）
// - 传入非方法过程变量（global proc）；传 nil 关闭 Overlay
// - 用于绘制 FPS、窗口尺寸、调试徽标等轻量级信息；建议尽量少量绘制
// - 可安全调用 termui_* 写入/属性 API；内部会在 UI 渲染线程上调用
// - 当后端不可用（UiBackendGetCurrent=nil）时为安全 no-op
//
// 使用示例：
//   procedure MyOverlay;
//   begin
//     termui_set_attr(termui_attr_preset_info);
//     termui_write_at_clipped(0, 2, 40, 'overlay: demo');
//     termui_attr_reset;
//   end;
//   // 启用：
//   //   termui_set_overlay(@MyOverlay);
//   // 关闭：
//   //   termui_set_overlay(nil);
procedure termui_set_overlay(const Overlay: TUiRenderProc);

// - Hooks 为非方法过程变量；在测试中建议传入全局桥接过程
procedure termui_debug_set_hooks(
  WriteHook: TUiHook_Write;
  WritelnHook: TUiHook_Writeln;
  CursorLineHook: TUiHook_CursorLine;
  CursorColHook: TUiHook_CursorCol;
  CursorVisibleSetHook: TUiHook_CursorVisibleSet;
  SizeHook: TUiHook_Size);
procedure termui_debug_reset_hooks;

implementation
var
  G_TERMUI_SYNC_UPDATE_ENABLED: Boolean = False;

procedure termui_set_sync_update_enabled(Enabled: Boolean);
begin
  G_TERMUI_SYNC_UPDATE_ENABLED := Enabled;
end;


procedure termui_invalidate;
begin
  fafafa.core.term.ui.app.UiAppInvalidate;
end;

procedure termui_run(const Render: TUiRenderProc; const HandleEvent: TUiEventProc);
begin
  fafafa.core.term.ui.app.UiAppRun(Render, HandleEvent);
end;

procedure termui_run_node(const Root: IUiNode);
begin
  fafafa.core.term.ui.app.UiAppRunNode(Root);
end;

procedure termui_set_backbuffer_enabled(Enabled: Boolean);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiSetBackBufferEnabled(Enabled);
end;

procedure termui_set_cursor_after_frame_policy(const Policy: TUiCursorAfterFramePolicy);
begin
  fafafa.core.term.ui.surface.UiSetCursorAfterFramePolicy(Policy);
end;

procedure termui_clear;
begin
  // Safe guard: ensure backend present (UiSurface internally depends on it)
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiClear;
end;

procedure termui_goto(line, col: term_size_t);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiGotoLineCol(line, col);
end;

procedure termui_write(const S: UnicodeString);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiWrite(S);
end;

procedure termui_writeln(const S: UnicodeString);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiWriteLn(S);
end;

procedure termui_writeln(const Ch: UnicodeChar); overload;
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiWriteLn(UnicodeString(Ch));
end;

procedure termui_writeln(const Ch: AnsiChar); overload;
begin
  termui_writeln(UnicodeChar(Ch));
end;

procedure termui_writeln_at(line, col: term_size_t; const S: UnicodeString);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiWriteAt(line, col, S + LineEnding);
end;

procedure termui_writeln_at(line, col: term_size_t; const S: AnsiString); overload;
begin
  termui_writeln_at(line, col, UnicodeString(S));
end;

procedure termui_fg24(R,G,B: Integer);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiSetFg24(R,G,B);
end;

procedure termui_bg24(R,G,B: Integer);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiSetBg24(R,G,B);
end;

procedure termui_push_view(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiPushView(ViewX, ViewY, ViewW, ViewH, OriginX, OriginY);
end;

procedure termui_pop_view;
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiPopView;
end;

procedure termui_frame_begin;
begin
  if UiBackendGetCurrent = nil then Exit;
  // Optional synchronized update: enable at frame start (behind-a-flag)
  if G_TERMUI_SYNC_UPDATE_ENABLED and term_support_sync_update then
    term_sync_update_enable(True);
  fafafa.core.term.ui.surface.UiFrameBegin;
end;

procedure termui_frame_end;
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiFrameEnd;
  // Optional synchronized update: disable at frame end
  if G_TERMUI_SYNC_UPDATE_ENABLED and term_support_sync_update then
    term_sync_update_enable(False);
end;

procedure termui_attr_reset;
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiAttrReset;
end;

procedure termui_set_attr(const Attr: TUiAttr);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiSetAttr(Attr);
end;

procedure termui_fill_line(line: term_size_t; const ch: UnicodeChar; count: Integer);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiFillLine(line, ch, count);
end;

procedure termui_write_at(line, col: term_size_t; const S: UnicodeString);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiWriteAt(line, col, S);
end;
procedure termui_with_view(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t; const Render: TUiRenderProc);
begin
  // 作用域视口：
  // - ViewX/Y/W/H 为绝对 UI 坐标与尺寸（0 基）
  // - OriginX/Y 为局部原点，内部 Render 使用的 line/col 将在输出前按原点平移并按视口裁剪
  // - Render 为非方法过程变量（非嵌套/匿名），建议传入全局过程
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiPushView(ViewX, ViewY, ViewW, ViewH, OriginX, OriginY);
  try
    if Assigned(Render) then Render;
  finally
    fafafa.core.term.ui.surface.UiPopView;
  end;
end;

function termui_attr_preset_info: TUiAttr;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.HasFg := True; Result.Fg.R := 64; Result.Fg.G := 160; Result.Fg.B := 255; // blue-ish
  Result.Styles := [];
end;

function termui_attr_preset_warn: TUiAttr;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.HasFg := True; Result.Fg.R := 255; Result.Fg.G := 192; Result.Fg.B := 64; // amber
  Result.Styles := [];
end;

function termui_attr_preset_error: TUiAttr;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.HasFg := True; Result.Fg.R := 255; Result.Fg.G := 64; Result.Fg.B := 64; // red-ish
  Result.Styles := [];
end;


// Overload implementations (global scope)
procedure termui_write(const S: AnsiString); overload;
begin
  termui_write(UnicodeString(S));
end;

procedure termui_writeln(const S: AnsiString); overload;
begin
  termui_writeln(UnicodeString(S));
end;

// Convenience overload implementation
procedure termui_with_view(ViewX, ViewY, ViewW, ViewH: term_size_t; const Render: TUiRenderProc); inline;
begin
  termui_with_view(ViewX, ViewY, ViewW, ViewH, 0, 0, Render);
end;

procedure termui_with_attr(const Attr: TUiAttr; const Render: TUiRenderProc);
begin
  if UiBackendGetCurrent = nil then Exit;
  termui_set_attr(Attr);
  try
    if Assigned(Render) then Render;
  finally
    termui_attr_reset;
  end;
end;

procedure termui_write_center(line: term_size_t; const S: UnicodeString; TotalWidth: term_size_t);
var col, slen: term_size_t;
begin
  if UiBackendGetCurrent = nil then Exit;
  slen := Length(S);
  if slen > TotalWidth then
  begin
    termui_write_at(line, 0, Copy(S, 1, TotalWidth));
    Exit;
  end;
  if TotalWidth = 0 then Exit;
  col := (TotalWidth - slen) div 2;
  termui_write_at(line, col, S);
end;

procedure termui_write_at_clipped(line, col, maxW: term_size_t; const S: UnicodeString);
var outS: UnicodeString;
begin
  if UiBackendGetCurrent = nil then Exit;
  if maxW <= 0 then Exit;
  if Length(S) > maxW then outS := Copy(S, 1, maxW) else outS := S;
  termui_write_at(line, col, outS);
end;

procedure termui_status_line(line: term_size_t; const S: UnicodeString; const Attr: TUiAttr);
begin
  if UiBackendGetCurrent = nil then Exit;
  termui_set_attr(Attr);
  try
    termui_fill_line(line, ' ', -1);
    termui_write_at(line, 0, S);
  finally
    termui_attr_reset;
  end;
end;

function termui_key_is(const E: term_event_t; const Keys: array of WideChar): boolean;
var i: Integer;
begin
  if E.kind <> tek_key then Exit(false);
  for i := 0 to High(Keys) do
    if E.key.char.wchar = Keys[i] then Exit(true);
  Result := false;
end;

procedure termui_write_at(line, col: term_size_t; const S: AnsiString); overload;
begin
  termui_write_at(line, col, UnicodeString(S));
end;

procedure termui_fill_line(line: term_size_t; const ch: AnsiChar; count: Integer); overload;
begin
  termui_fill_line(line, UnicodeChar(ch), count);
end;

procedure termui_fill_rect(x, y, w, h: term_size_t; const ch: AnsiChar); overload;
begin
  termui_fill_rect(x, y, w, h, UnicodeChar(ch));
end;

// Implementation of global frame overlay hook
procedure termui_set_overlay(const Overlay: TUiRenderProc);
begin
  fafafa.core.term.ui.app.UiAppSetOverlay(Overlay);
end;



procedure termui_debug_set_hooks(
  WriteHook: TUiHook_Write;
  WritelnHook: TUiHook_Writeln;
  CursorLineHook: TUiHook_CursorLine;
  CursorColHook: TUiHook_CursorCol;
  CursorVisibleSetHook: TUiHook_CursorVisibleSet;
  SizeHook: TUiHook_Size);
begin
  fafafa.core.term.ui.surface.UiDebug_SetOutputHooks(
    WriteHook, WritelnHook, CursorLineHook, CursorColHook, CursorVisibleSetHook, SizeHook);
end;

procedure termui_debug_reset_hooks;
begin
  fafafa.core.term.ui.surface.UiDebug_ResetOutputHooks;
end;



procedure termui_fill_rect(x, y, w, h: term_size_t; const ch: UnicodeChar);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiFillRect(x, y, w, h, ch);
end;

procedure termui_invalidate_all;
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiInvalidateAll;
end;


procedure termui_invalidate_rect(x, y, w, h: term_size_t);
begin
  if UiBackendGetCurrent = nil then Exit;
  fafafa.core.term.ui.surface.UiInvalidateRect(x, y, w, h);
end;

end.


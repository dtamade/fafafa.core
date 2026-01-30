unit fafafa.core.term.ui.surface;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_backend,
  ui_surface; // 暂时复用原实现

  // Backbuffer toggle passthrough
  procedure UiSetBackBufferEnabled(Enabled: Boolean);

type
  TUiHook_Write = ui_surface.TUiHook_Write;
  TUiHook_Writeln = ui_surface.TUiHook_Writeln;
  TUiHook_CursorLine = ui_surface.TUiHook_CursorLine;
  TUiHook_CursorCol = ui_surface.TUiHook_CursorCol;
  TUiHook_CursorVisibleSet = ui_surface.TUiHook_CursorVisibleSet;
  TUiHook_Size = ui_surface.TUiHook_Size;
  TUiCursorAfterFramePolicy = ui_surface.TUiCursorAfterFramePolicy;

// 视图与帧转发
procedure UiPushView(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t);
procedure UiPopView;
procedure UiFrameBegin;
procedure UiFrameEnd;

// 基础绘制
procedure UiClear;
procedure UiGotoLineCol(ALine, ACol: term_size_t);
procedure UiWrite(const S: UnicodeString);
procedure UiWriteLn(const S: UnicodeString);
procedure UiSetFg24(R,G,B: Integer);
procedure UiSetBg24(R,G,B: Integer);
procedure UiAttrReset;
procedure UiFillLine(ALine: term_size_t; const Ch: UnicodeChar; Count: Integer = -1);
procedure UiWriteAt(ALine, ACol: term_size_t; const S: UnicodeString);
procedure UiFillRect(AX, AY, AW, AH: term_size_t; const Ch: UnicodeChar);
procedure UiSetAttr(const Attr: TUiAttr);
// 脏区转发
procedure UiInvalidateAll;
procedure UiInvalidateRect(AX, AY, AW, AH: term_size_t);

// 调试 Hook 转发
procedure UiDebug_SetOutputHooks(
  WriteHook: TUiHook_Write;
  WritelnHook: TUiHook_Writeln;
  CursorLineHook: TUiHook_CursorLine;
  CursorColHook: TUiHook_CursorCol;
  CursorVisibleSetHook: TUiHook_CursorVisibleSet;
  SizeHook: TUiHook_Size);
procedure UiDebug_ResetOutputHooks;

// Cursor policy control passthrough (declared in interface, implement below)
procedure UiSetCursorAfterFramePolicy(const Policy: TUiCursorAfterFramePolicy);



implementation


procedure UiDebug_SetOutputHooks(
  WriteHook: TUiHook_Write;
  WritelnHook: TUiHook_Writeln;
  CursorLineHook: TUiHook_CursorLine;
  CursorColHook: TUiHook_CursorCol;
  CursorVisibleSetHook: TUiHook_CursorVisibleSet;
  SizeHook: TUiHook_Size);
begin
  ui_surface.UiDebug_SetOutputHooks(WriteHook, WritelnHook, CursorLineHook, CursorColHook, CursorVisibleSetHook, SizeHook);
end;

procedure UiSetCursorAfterFramePolicy(const Policy: TUiCursorAfterFramePolicy);
begin
  ui_surface.UiSetCursorAfterFramePolicy(Policy);
end;

procedure UiDebug_ResetOutputHooks;
begin
  ui_surface.UiDebug_ResetOutputHooks;
end;

procedure UiPushView(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t);
begin ui_surface.UiPushView(ViewX,ViewY,ViewW,ViewH,OriginX,OriginY); end;
procedure UiPopView; begin ui_surface.UiPopView; end;
procedure UiFrameBegin; begin ui_surface.UiFrameBegin; end;
procedure UiFrameEnd; begin ui_surface.UiFrameEnd; end;

procedure UiClear; begin ui_surface.UiClear; end;
procedure UiGotoLineCol(ALine, ACol: term_size_t); begin ui_surface.UiGotoLineCol(ALine,ACol); end;
procedure UiWrite(const S: UnicodeString); begin ui_surface.UiWrite(S); end;
procedure UiWriteLn(const S: UnicodeString); begin ui_surface.UiWriteLn(S); end;
procedure UiSetFg24(R,G,B: Integer); begin ui_surface.UiSetFg24(R,G,B); end;
procedure UiSetBg24(R,G,B: Integer); begin ui_surface.UiSetBg24(R,G,B); end;
procedure UiAttrReset; begin ui_surface.UiAttrReset; end;
procedure UiFillLine(ALine: term_size_t; const Ch: UnicodeChar; Count: Integer);
begin ui_surface.UiFillLine(ALine, Ch, Count); end;
procedure UiWriteAt(ALine, ACol: term_size_t; const S: UnicodeString);
begin ui_surface.UiWriteAt(ALine, ACol, S); end;
procedure UiInvalidateAll; begin ui_surface.UiInvalidateAll; end;
procedure UiInvalidateRect(AX, AY, AW, AH: term_size_t);
begin ui_surface.UiInvalidateRect(AX, AY, AW, AH); end;
procedure UiFillRect(AX, AY, AW, AH: term_size_t; const Ch: UnicodeChar);
begin ui_surface.UiFillRect(AX, AY, AW, AH, Ch); end;
procedure UiSetAttr(const Attr: TUiAttr);
begin ui_surface.UiSetAttr(Attr); end;

procedure UiSetBackBufferEnabled(Enabled: Boolean);
begin ui_surface.UiSetBackBufferEnabled(Enabled); end;

end.


procedure UiSetCursorAfterFramePolicy(const Policy: TUiCursorAfterFramePolicy);
begin
  ui_surface.UiSetCursorAfterFramePolicy(Policy);
end;


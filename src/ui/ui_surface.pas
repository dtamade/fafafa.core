unit ui_surface;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math,
  fafafa.core.term,
  ui_backend;

// Minimal hook type forward for interface declarations
Type
  TUiHook_Flush = procedure;

// Viewport & origin stack (for clipping/scrolling)
procedure UiPushView(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t);
procedure UiInvalidateAll;
procedure UiInvalidateRect(AX, AY, AW, AH: term_size_t);
procedure UiPopView;

// Frame brackets (double-buffer frame)
procedure UiFrameBegin;
procedure UiFrameEnd;
// Configure line diff threshold (0..1). Pass negative to restore default/env behavior.
procedure UiSetLineDiffThreshold(const Value: Double);

// Benchmark helpers (opt-in): enable term-level buffering per frame and count flushes
// Use UiDebug_SetFlushHook to observe flush events in tests/benchmarks.
procedure UiDebug_EnableFrameBufferingForBenchmark(Enabled: Boolean);
procedure UiDebug_SetFlushHook(const Hook: TUiHook_Flush);

// Backbuffer control
procedure UiSetBackBufferEnabled(Enabled: Boolean);



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

// Test/debug hooks: allow redirecting output for unit tests
// Hook types
Type
  TUiHook_Write = procedure(const S: UnicodeString);
  TUiHook_Writeln = procedure(const S: UnicodeString);
  TUiHook_CursorLine = procedure(Line: term_size_t);
  TUiHook_CursorCol = procedure(Col: term_size_t);
  TUiHook_CursorVisibleSet = function(Visible: Boolean): Boolean;
  TUiHook_Size = function(var W, H: term_size_t): Boolean;
  // Segment emission hook (tests only): called for each diff segment emit
  TUiHook_SegmentEmit = procedure(Line, Col, Len: term_size_t; const Attr: TUiAttr);
  // Cursor policy at end of frame
  TUiCursorAfterFramePolicy = (
    ucpAuto,          // default: backbuffer=keep, direct=to_origin
    ucpKeep,
    ucpToOrigin,
    ucpToBottomLeft,
    ucpToBottomRight
  );

// Set/reset hooks
procedure UiDebug_SetOutputHooks(
  WriteHook: TUiHook_Write;
  WritelnHook: TUiHook_Writeln;
  CursorLineHook: TUiHook_CursorLine;
  CursorColHook: TUiHook_CursorCol;
  CursorVisibleSetHook: TUiHook_CursorVisibleSet;
  SizeHook: TUiHook_Size);
  procedure UiDebug_SetSegmentEmitHook(const Hook: TUiHook_SegmentEmit);

procedure UiDebug_ResetOutputHooks;

// Cursor policy control
procedure UiSetCursorAfterFramePolicy(const Policy: TUiCursorAfterFramePolicy);

var
  GHook_Write: TUiHook_Write = nil;
  GHook_Writeln: TUiHook_Writeln = nil;
  GHook_CursorLine: TUiHook_CursorLine = nil;
  GHook_CursorCol: TUiHook_CursorCol = nil;
  GHook_CursorVisibleSet: TUiHook_CursorVisibleSet = nil;
  GHook_Size: TUiHook_Size = nil;
  GHook_Flush: TUiHook_Flush = nil;

var
  GCursorPolicy: TUiCursorAfterFramePolicy = ucpAuto;
implementation



function AttrSame(const A, B: TUiAttr): Boolean; inline;
begin
  Result := (A.HasFg = B.HasFg) and (A.HasBg = B.HasBg)
    and (A.Fg.R = B.Fg.R) and (A.Fg.G = B.Fg.G) and (A.Fg.B = B.Fg.B)
    and (A.Bg.R = B.Bg.R) and (A.Bg.G = B.Bg.G) and (A.Bg.B = B.Bg.B)
    and (A.Styles = B.Styles);
end;

type
  TUiView = record
    X, Y, W, H: term_size_t; // viewport in screen coords
    OX, OY: term_size_t;     // origin added to local coords (local -> screen)
  end;

var
  GCursorHidden: Boolean = False;
  GUseBackBuffer: Boolean = False;
  GBackBufferEnabled: Boolean = True; // allow toggling off for attr-aware direct draws
  GDirty: array of record X,Y,W,H: term_size_t; end;
  GBufW, GBufH: term_size_t;
  GFrontBuf: array of UnicodeString; // previous frame
  GBackBuf: array of UnicodeString;  // current frame being drawn
  GViewStack: array of TUiView;
  GViewTop: TUiView;
  // Global line diff threshold override; <0 means use env/default
  GLineDiffThreshold: Double = -1.0;
  GBackStyle: array of array of TUiAttr; // current frame styles per cell
  GFrontStyle: array of array of TUiAttr; // previous frame styles per cell
  GCurrentAttr: TUiAttr; // current drawing attribute used for backbuffer writes

  // Benchmark-only: per-frame term output buffering and flush hook
  GHook_SegmentEmit: TUiHook_SegmentEmit = nil;

  GBenchmarkFrameBuffering: Boolean = False;

var
  GBenchmarkBuffer: UnicodeString = '';

procedure BufEnsureSize(aW, aH: term_size_t);
var
  i: Integer;
begin
    SetLength(GBackStyle, aH);
    SetLength(GFrontStyle, aH);
    for i := 0 to aH - 1 do
    begin
      SetLength(GBackStyle[i], aW);
      SetLength(GFrontStyle[i], aW);
      FillChar(GBackStyle[i][0], SizeOf(TUiAttr) * aW, 0);
      FillChar(GFrontStyle[i][0], SizeOf(TUiAttr) * aW, 0);
    end;

  if (GBufW <> aW) or (GBufH <> aH) or (Length(GBackBuf) <> aH) then
  begin
    GBufW := aW; GBufH := aH;
    SetLength(GBackBuf, aH);
    SetLength(GFrontBuf, aH);
    // 清空脏区：让下一帧进行一次全量合成（UiFrameEnd 会在空脏区时 InvalidateAll）
    SetLength(GDirty, 0);
    for i := 0 to aH - 1 do
    begin
      GBackBuf[i] := StringOfChar(UnicodeChar(' '), aW);
      // 用一个不可能出现在输出中的字符初始化前帧缓冲，强制首帧与缩放后的全量重绘
      GFrontBuf[i] := StringOfChar(UnicodeChar(#0), aW);
    end;
  end;
  // reset view top to full screen
  GViewTop.X := 0; GViewTop.Y := 0; GViewTop.W := aW; GViewTop.H := aH; GViewTop.OX := 0; GViewTop.OY := 0;
end;

procedure UiPushView(ViewX, ViewY, ViewW, ViewH: term_size_t; OriginX, OriginY: term_size_t);
var v: TUiView;
begin
  v.X := ViewX; v.Y := ViewY; v.W := ViewW; v.H := ViewH; v.OX := OriginX; v.OY := OriginY;
  SetLength(GViewStack, Length(GViewStack)+1);
  GViewStack[High(GViewStack)] := GViewTop; // push current top
  GViewTop := v;
end;

procedure UiPopView;
begin
  if Length(GViewStack) > 0 then
  begin
    GViewTop := GViewStack[High(GViewStack)];
    SetLength(GViewStack, Length(GViewStack)-1);
  end
  else
  begin
    // reset to full screen as a guard
    GViewTop.X := 0; GViewTop.Y := 0; GViewTop.W := GBufW; GViewTop.H := GBufH; GViewTop.OX := 0; GViewTop.OY := 0;
  end;
end;

procedure UiDebug_SetOutputHooks(
  WriteHook: TUiHook_Write;
  WritelnHook: TUiHook_Writeln;
  CursorLineHook: TUiHook_CursorLine;
  CursorColHook: TUiHook_CursorCol;
  CursorVisibleSetHook: TUiHook_CursorVisibleSet;
  SizeHook: TUiHook_Size);
begin
  GHook_Write := WriteHook;
  GHook_Writeln := WritelnHook;
  GHook_CursorLine := CursorLineHook;
  GHook_CursorCol := CursorColHook;
  GHook_CursorVisibleSet := CursorVisibleSetHook;
  GHook_Size := SizeHook;
end;

procedure UiDebug_SetSegmentEmitHook(const Hook: TUiHook_SegmentEmit);
begin
  GHook_SegmentEmit := Hook;
end;

procedure UiDebug_ResetOutputHooks;
begin
  GHook_Write := nil;
  GHook_Writeln := nil;
  GHook_CursorLine := nil;
  GHook_CursorCol := nil;
  GHook_CursorVisibleSet := nil;
  GHook_Size := nil;
  GHook_Flush := nil;
end;


procedure UiSetCursorAfterFramePolicy(const Policy: TUiCursorAfterFramePolicy);
begin
  GCursorPolicy := Policy;
end;

procedure UiSetBackBufferEnabled(Enabled: Boolean);
begin
  GBackBufferEnabled := Enabled;
end;

procedure UiDebug_EnableFrameBufferingForBenchmark(Enabled: Boolean);
begin
  GBenchmarkFrameBuffering := Enabled;
end;

procedure UiDebug_SetFlushHook(const Hook: TUiHook_Flush);
begin
  GHook_Flush := Hook;
end;

procedure UiSetLineDiffThreshold(const Value: Double);
begin
  if Value < 0 then
    GLineDiffThreshold := -1.0
  else if Value > 1 then
    GLineDiffThreshold := 1.0
  else
    GLineDiffThreshold := Value;
end;

procedure InvalidateAll;
begin
  SetLength(GDirty, 1);
  GDirty[0].X := 0; GDirty[0].Y := 0; GDirty[0].W := GBufW; GDirty[0].H := GBufH;
end;

procedure InvalidateRect(AX, AY, AW, AH: term_size_t);
var N: Integer;
begin
  if (AW <= 0) or (AH <= 0) then Exit;
  N := Length(GDirty);
  SetLength(GDirty, N+1);
  GDirty[N].X := AX; GDirty[N].Y := AY; GDirty[N].W := AW; GDirty[N].H := AH;
end;



// Public invalidation wrappers
procedure UiInvalidateAll;
begin
  InvalidateAll;
end;

procedure UiInvalidateRect(AX, AY, AW, AH: term_size_t);
begin
  InvalidateRect(AX, AY, AW, AH);
end;

procedure BufClearCurrent;
var i: Integer;
begin
  for i := 0 to High(GBackBuf) do
    // Always reset to full-width spaces (Unicode)
    GBackBuf[i] := StringOfChar(UnicodeChar(' '), GBufW);
end;

procedure BufWriteSegment(aX, aY: term_size_t; const S: UnicodeString);
var
  pos1, maxLen, segLen: Integer;
  line: UnicodeString;
begin
  // aX/aY 为 0-based UI 坐标，允许 aX<0/aY<0 在后续被 clamp；仅提前剔除明显越界（行超出、列超出宽度）
  if (aY >= GBufH) or (aX >= GBufW) then Exit;
  // apply current view transform and clip to viewport
  if (GViewTop.W > 0) and (GViewTop.H > 0) then
  begin
    aX := aX + GViewTop.OX + GViewTop.X;
  // NOTE: current drawing attribute GCurrentAttr is applied per-cell after text write (see end of this proc)

    aY := aY + GViewTop.OY + GViewTop.Y;
    if (aY < GViewTop.Y) or (aY >= GViewTop.Y + GViewTop.H) then Exit;
    if (aX < GViewTop.X) then aX := GViewTop.X;
  end;

  // term_size_t 为无符号类型：不再比较 aX/aY < 0，避免恒假与不可达分支告警
  // compute max length constrained by viewport and buffer width
  if (GViewTop.W > 0) and (GViewTop.H > 0) then
    maxLen := (GViewTop.X + GViewTop.W) - aX
  else
    maxLen := GBufW - aX;
  if maxLen < 0 then Exit;
  segLen := Length(S);
  if segLen > maxLen then segLen := maxLen;
  if segLen <= 0 then Exit;
  // ensure line exists and has width
  if (aY > High(GBackBuf)) then Exit;
  line := GBackBuf[aY];
  if Length(line) <> GBufW then
    line := StringOfChar(UnicodeChar(' '), GBufW);
  pos1 := aX + 1; // UnicodeString is 1-based
  // replace [pos1, pos1+segLen-1]
  line := Copy(line, 1, pos1-1) + Copy(S, 1, segLen) + Copy(line, pos1+segLen, MaxInt);
  GBackBuf[aY] := line;
  // Apply current attr to style buffer for [aX, aX+segLen)
  if (aY <= High(GBackStyle)) and (Length(GBackStyle[aY]) >= (aX + segLen)) then
    Move(GCurrentAttr, GBackStyle[aY][aX], SizeOf(TUiAttr) * segLen);
  // 精确标记脏区
  InvalidateRect(aX, aY, segLen, 1);
end;

procedure UiFrameBegin;
var w,h: term_size_t; i: Integer; ok: Boolean;
begin
  // Default init to appease analyzer; will be overwritten by Size()
  w := 0; h := 0;
  if not GCursorHidden then
  begin
    if Assigned(GHook_CursorVisibleSet) then ok := GHook_CursorVisibleSet(False)
    else
    begin
      try
        ok := UiBackendGetCurrent.CursorVisibleSet(False);
      except
        ok := True; // tolerate non-tty
      end;
    end;
    GCursorHidden := True;
  end;
  // Optional: synchronized updates are controlled by term layer; ui_surface stays backend-agnostic here
  if Assigned(GHook_Size) then ok := GHook_Size(w,h) else ok := UiBackendGetCurrent.Size(w,h);
  if ok and (w>0) and (h>0) and GBackBufferEnabled then
  begin
    BufEnsureSize(w,h);
    BufClearCurrent;
    GUseBackBuffer := True;
  end
  else
    GUseBackBuffer := False;

  // Benchmark-only: when enabled and in a terminal, enable term output buffering
  if GBenchmarkFrameBuffering and IsTerminal then
  begin
    try
      with CreateTerminal do
        if (Output <> nil) then Output.EnableBuffering;
    except
      // swallow errors to keep UI robust
    end;
  end;
end;

procedure UiFrameEnd;
var
  w,h: term_size_t;
  y: Integer;
  line, prev: UnicodeString;
  i, j, segLen: Integer;
  rx, ry, rw, rh: Integer;
  c, cEnd: Integer;
  segStart, segEnd: Integer;
  v2: IUiBackendV2;
  // 行内阈值自适应（默认 35%），可通过环境变量 FAFAFA_TERM_DIFF_LINE_THRESHOLD 覆盖（0..1）
  threshold: Double;
  dlen: Integer;
  redrawWholeLine: Boolean;
  forceLineRedraw: Integer;
begin
  // Default initialize to appease analyzer; will be overwritten by Size()
  w := 0; h := 0;
  if ((Assigned(GHook_Size) and GHook_Size(w,h)) or (UiBackendGetCurrent.Size(w,h))) and (w>0) and (h>0) and GUseBackBuffer then
  begin
    // 若缓冲尺寸与当前窗口不一致（竞态窗口拖拽），强制全量重绘
    if (GBufW <> w) or (GBufH <> h) then InvalidateAll;

    // 阈值与强制整行重绘开关初始化（每帧读取一次，支持全局覆盖/环境变量）
    threshold := 0.35;
    if GLineDiffThreshold >= 0 then
      threshold := GLineDiffThreshold
    else
    begin
      try
        if GetEnvironmentVariable('FAFAFA_TERM_DIFF_LINE_THRESHOLD') <> '' then
          threshold := StrToFloatDef(GetEnvironmentVariable('FAFAFA_TERM_DIFF_LINE_THRESHOLD'), threshold);
      except
        // ignore malformed values
      end;
      if threshold < 0 then threshold := 0;
      if threshold > 1 then threshold := 1;
    end;

    forceLineRedraw := -1; // -1: 未显式设置；0/1: 显式设置
    try
      if GetEnvironmentVariable('FAFAFA_TERM_UI_FORCE_LINE_REDRAW') <> '' then
        forceLineRedraw := StrToIntDef(GetEnvironmentVariable('FAFAFA_TERM_UI_FORCE_LINE_REDRAW'), -1);
    except
      // ignore malformed values
    end;

    // 优先使用脏区，仅遍历脏行范围，减少全屏扫描
    if Length(GDirty) = 0 then InvalidateAll;
    for i := 0 to High(GDirty) do
    begin
      // clip rect
      rx := GDirty[i].X; ry := GDirty[i].Y;
      rw := GDirty[i].W; rh := GDirty[i].H;
      if rx < 0 then rx := 0; if ry < 0 then ry := 0;
      if rx + rw > w then rw := w - rx;
      if ry + rh > h then rh := h - ry;
      if (rw <= 0) or (rh <= 0) then Continue;
      for y := ry to ry + rh - 1 do
      begin
        if y > High(GBackBuf) then Break;
        line := GBackBuf[y];
        if Length(line) <> w then
          line := Copy(line + StringOfChar(UnicodeChar(' '), w), 1, w);

        if y <= High(GFrontBuf) then
          prev := GFrontBuf[y]
        else
          prev := '';
        if Length(prev) <> w then
          prev := Copy(prev + StringOfChar(UnicodeChar(' '), w), 1, w);

        // 计算行内差异总长度（限制在脏区）
        dlen := 0;
        c := rx + 1; cEnd := rx + rw; if cEnd > w then cEnd := w;
        while c <= cEnd do
        begin
          if prev[c] <> line[c] then
          begin
            j := c;
            while (j <= cEnd) and (prev[j] <> line[j]) do Inc(j);
            Inc(dlen, j - c);
            c := j;
          end
          else
            Inc(c);
        end;
        redrawWholeLine := (w > 0) and (dlen >= Ceil(w * threshold));
        // 强制整行重绘策略：环境变量优先；未设置时仅在 V2 后端默认启用
        if forceLineRedraw = 1 then
          redrawWholeLine := True
        else if forceLineRedraw = 0 then
          redrawWholeLine := False
        else if Supports(UiBackendGetCurrent, IUiBackendV2, v2) then
          redrawWholeLine := True;

        // 行内差异段输出（限制在脏区列范围）
        c := rx + 1; // 1-based index
        cEnd := rx + rw; if cEnd > w then cEnd := w;
        if redrawWholeLine then
        begin
          // 整行重绘：优先使用 V2 直接写，避免向内存后端写入 ANSI
          if Supports(UiBackendGetCurrent, IUiBackendV2, v2) then
          begin
            if (Length(GBackStyle) > y) and (Length(GBackStyle[y]) > 0) then
              UiSetAttr(GBackStyle[y][0]);
            v2.WriteAt(y, 0, line);
            UiAttrReset;
          end
          else
          begin
            // 终端后端：使用 ANSI 清行保证覆盖
            UiGotoLineCol(y, 0);
            if Assigned(GHook_Write) then GHook_Write(#27'[2K') else UiBackendGetCurrent.Write(#27'[2K');
            if (Length(GBackStyle) > y) and (Length(GBackStyle[y]) > 0) then
              UiSetAttr(GBackStyle[y][0]);
            if Assigned(GHook_Write) then GHook_Write(line) else UiBackendGetCurrent.Write(line);
            UiAttrReset;
          end;
        end
        else
        begin
          while c <= cEnd do
          begin
            if prev[c] <> line[c] then
            begin
              j := c;
              while (j <= cEnd) and (prev[j] <> line[j]) do Inc(j);
              segLen := j - c;
              // Attribute-aware segment emit: find contiguous segment with same attr in back buffer
              segStart := c;
              segEnd := j - 1;
              // expand to merge adjacent with same attr while content differs
              while (segEnd < cEnd) and (segEnd + 1 <= cEnd) and
                    AttrSame(GBackStyle[y][segEnd], GBackStyle[y][segEnd + 1]) and
                    (prev[segEnd + 1] <> line[segEnd + 1]) do
                Inc(segEnd);
              segLen := segEnd - segStart + 1;
              // Prefer V2 direct segment write when available to avoid cursor state issues
              if Supports(UiBackendGetCurrent, IUiBackendV2, v2) then
              begin
                UiSetAttr(GBackStyle[y][segStart]);
                v2.WriteAt(y, segStart - 1, Copy(line, segStart, segLen));
                UiAttrReset;
              end
              else
              begin
                UiGotoLineCol(y, segStart - 1);
                // Apply attr for this segment
                UiSetAttr(GBackStyle[y][segStart]);
                if Assigned(GHook_Write) then GHook_Write(Copy(line, segStart, segLen)) else UiBackendGetCurrent.Write(Copy(line, segStart, segLen));
                // Reset attr after segment to avoid leaking styles into subsequent segments
                UiAttrReset;
              end;
              // Test hook: notify a segment emission
              if Assigned(GHook_SegmentEmit) then GHook_SegmentEmit(y, segStart - 1, segLen, GBackStyle[y][segStart]);
              c := segEnd + 1;
            end
            else
              Inc(c);
          end;
        end;

        if y <= High(GFrontBuf) then
          GFrontBuf[y] := line;
        // sync style front/back for this line
        if (y <= High(GFrontStyle)) and (y <= High(GBackStyle)) then
        begin
          if (Length(GFrontStyle[y]) <> GBufW) then SetLength(GFrontStyle[y], GBufW);
          if (Length(GBackStyle[y]) <> GBufW) then SetLength(GBackStyle[y], GBufW);
          Move(GBackStyle[y][0], GFrontStyle[y][0], SizeOf(TUiAttr) * GBufW);
        end;
      end;
    end;
    // 清空脏区
    SetLength(GDirty, 0);
  end;

  if GCursorHidden then
  begin
    if Assigned(GHook_CursorVisibleSet) then GHook_CursorVisibleSet(True)
    else
    begin
      try
        UiBackendGetCurrent.CursorVisibleSet(True);
      except
        // ignore
      end;
    end;
    GCursorHidden := False;
  end;

  // Apply cursor policy at frame end
  case GCursorPolicy of
    ucpAuto:
      begin
        if not GUseBackBuffer then UiGotoLineCol(0,0);
      end;
    ucpKeep:
      ; // do nothing
    ucpToOrigin:
      UiGotoLineCol(0,0);
    ucpToBottomLeft:
      begin
        // Move to first column of last line
        if GBufH > 0 then UiGotoLineCol(GBufH-1, 0) else UiGotoLineCol(0,0);
      end;
    ucpToBottomRight:
      begin
        // Move to last column of last line (clamped in UiGotoLineCol)
        if (GBufH > 0) and (GBufW > 0) then UiGotoLineCol(GBufH-1, GBufW-1)
        else UiGotoLineCol(0,0);
      end;
  end;
  // 不再强制将光标移动到左上角；保持在最后一次绘制位置
  // 如需传统行为（将光标移出内容区域），仅在直写模式下执行
  if not GUseBackBuffer then
    UiGotoLineCol(0, 0);

  // 结束一帧后清空视口栈，避免在窗口频繁变化时遗留不一致的局部视口
  SetLength(GViewStack, 0);
  GViewTop.X := 0; GViewTop.Y := 0; GViewTop.W := GBufW; GViewTop.H := GBufH; GViewTop.OX := 0; GViewTop.OY := 0;

  // Benchmark-only: if enabled and in terminal, flush and disable buffering, then notify hook
  if GBenchmarkFrameBuffering and IsTerminal then
  begin
    try
      with CreateTerminal do
        if (Output <> nil) then
        begin
          Output.Flush;
          Output.DisableBuffering;
        end;
    except
      // swallow errors
    end;
  end;
  if GBenchmarkFrameBuffering and Assigned(GHook_Flush) then
    GHook_Flush;
end;

procedure UiClear;
begin
  if GUseBackBuffer then
  begin
    BufClearCurrent;
    // In frame/backbuffer mode we clear current back buffer and mark full dirty,
    // so next composite will emit a full redraw in a single flush.
    InvalidateAll; // ensure full redraw this frame
  end
  else
  begin
    UiBackendGetCurrent.Clear;
    UiGotoLineCol(0, 0); // move to top-left using UI 0-based -> terminal 1-based
  end;
end;

procedure UiGotoLineCol(ALine, ACol: term_size_t);
var
  w,h: term_size_t;
  ok: Boolean;
begin
  // Always try to get the real-time terminal size for safe clamping
  ok := (Assigned(GHook_Size) and GHook_Size(w,h)) or UiBackendGetCurrent.Size(w,h);
  if not ok then
  begin
    if GUseBackBuffer then begin w := GBufW; h := GBufH; end
    else begin w := 80; h := 24; end; // fallback for safety only
  end;
  if (h = 0) or (w = 0) then Exit;
  if ALine >= h then ALine := h - 1;
  if ACol >= w then ACol := w - 1;
  // Convert 0-based (UI) to 1-based (terminal) with robust retry on resize race
  try
    if Assigned(GHook_CursorLine) then GHook_CursorLine(ALine + 1) else UiBackendGetCurrent.CursorLine(ALine);
  except
    on E: Exception do
    begin
      // Re-fetch size and clamp again, then retry once
      if UiBackendGetCurrent.Size(w,h) and (h>0) and (w>0) then
      begin
        if ALine >= h then ALine := h - 1;
        if ACol >= w then ACol := w - 1;
      end;
      try
        if Assigned(GHook_CursorLine) then GHook_CursorLine(ALine + 1) else UiBackendGetCurrent.CursorLine(ALine);
      except
        // swallow to avoid hard crash during aggressive resize
      end;
    end;
  end;
  try
    if Assigned(GHook_CursorCol) then GHook_CursorCol(ACol + 1) else UiBackendGetCurrent.CursorCol(ACol);
  except
    on E: Exception do
    begin
      if UiBackendGetCurrent.Size(w,h) and (h>0) and (w>0) then
      begin
        if ALine >= h then ALine := h - 1;
        if ACol >= w then ACol := w - 1;
      end;
      try
        if Assigned(GHook_CursorCol) then GHook_CursorCol(ACol + 1) else UiBackendGetCurrent.CursorCol(ACol);
      except
        // swallow
      end;
    end;
  end;
end;

procedure UiWrite(const S: UnicodeString);
begin
  if Assigned(GHook_Write) then GHook_Write(S) else UiBackendGetCurrent.Write(S);
end;

procedure UiWriteLn(const S: UnicodeString);
begin
  if Assigned(GHook_Writeln) then GHook_Writeln(S) else UiBackendGetCurrent.Writeln(S);
end;

procedure UiSetFg24(R,G,B: Integer);
begin
  UiBackendGetCurrent.SetFg24(R,G,B);
end;

procedure UiSetBg24(R,G,B: Integer);
begin
  UiBackendGetCurrent.SetBg24(R,G,B);
end;

procedure UiAttrReset;
begin
  // Always reset current drawing attr for backbuffer tracking
  FillChar(GCurrentAttr, SizeOf(GCurrentAttr), 0);
  // When hooks are active (tests), avoid touching terminal backend attrs
  if Assigned(GHook_Write) or Assigned(GHook_Writeln) or Assigned(GHook_CursorLine) or
     Assigned(GHook_CursorCol) or Assigned(GHook_CursorVisibleSet) or Assigned(GHook_Size) then Exit;
  UiBackendGetCurrent.AttrReset;
end;

procedure UiSetAttr(const Attr: TUiAttr);
var v2: IUiBackendV2;
begin
  // Track current drawing attr for style-aware backbuffer writes
  GCurrentAttr := Attr;
  if Supports(UiBackendGetCurrent, IUiBackendV2, v2) then
    v2.SetAttr(Attr)
  else
  begin
    if Attr.HasBg then UiBackendGetCurrent.SetBg24(Attr.Bg.R, Attr.Bg.G, Attr.Bg.B);
    if Attr.HasFg then UiBackendGetCurrent.SetFg24(Attr.Fg.R, Attr.Fg.G, Attr.Fg.B);
  end;
end;

procedure UiWriteAt(ALine, ACol: term_size_t; const S: UnicodeString);
var
  w,h: term_size_t;
  v2: IUiBackendV2;
begin
  if GUseBackBuffer then begin w := GBufW; h := GBufH; end
  else if (Assigned(GHook_Size) and GHook_Size(w,h)) or UiBackendGetCurrent.Size(w,h) then begin end
  else begin w := 80; h := 24; end; // fallback for safety only
  if (h = 0) or (w = 0) then Exit;
  if ALine >= h then ALine := h - 1;
  if ACol >= w then ACol := w - 1;
  if GUseBackBuffer then
  begin
    BufWriteSegment(ACol, ALine, S);
  end
  else
  begin
    // Prefer V2 direct op if available
    if Supports(UiBackendGetCurrent, IUiBackendV2, v2) then
      v2.WriteAt(ALine, ACol, S)
    else
    begin
      // Fallback: move cursor then write (robust goto)
      UiGotoLineCol(ALine, ACol);
      if Assigned(GHook_Write) then GHook_Write(S) else UiBackendGetCurrent.Write(S);
    end;
  end;
end;

procedure UiFillRect(AX, AY, AW, AH: term_size_t; const Ch: UnicodeChar);
var
  y: term_size_t;
  line: UnicodeString;
  w,h: term_size_t;
  x0,y0,maxW,maxH: term_size_t;
  v2: IUiBackendV2;
begin
  if (AW <= 0) or (AH <= 0) then Exit;
  if GUseBackBuffer then begin w := GBufW; h := GBufH; end
  else if (Assigned(GHook_Size) and GHook_Size(w,h)) or UiBackendGetCurrent.Size(w,h) then begin end
  else begin w := 80; h := 24; end;
  if (w = 0) or (h = 0) then Exit;
  // Clip to visible window
  x0 := AX; y0 := AY;
  if x0 >= w then Exit;
  if y0 >= h then Exit;
  maxW := w - x0; if AW > maxW then AW := maxW;
  maxH := h - y0; if AH > maxH then AH := maxH;
  if (AW <= 0) or (AH <= 0) then Exit;
  // If backend supports V2 direct fill, use it (after clipping)
  if (not GUseBackBuffer) and Supports(UiBackendGetCurrent, IUiBackendV2, v2) then
  begin
    v2.FillRect(x0, y0, AW, AH, Ch);
    Exit;
  end;

  line := StringOfChar(Ch, AW);
  for y := 0 to AH-1 do
  begin
    if GUseBackBuffer then
      BufWriteSegment(x0, y0 + y, line)
    else
    begin
      // Robust goto to handle live resize safely
      UiGotoLineCol(y0 + y, x0);
      if Assigned(GHook_Write) then GHook_Write(line) else UiBackendGetCurrent.Write(line);
    end;
  end;
end;


procedure UiFillLine(ALine: term_size_t; const Ch: UnicodeChar; Count: Integer);
var
  w,h: term_size_t;
  n: Integer;
  v2: IUiBackendV2;
begin
  if GUseBackBuffer then begin w := GBufW; h := GBufH; end
  else if (Assigned(GHook_Size) and GHook_Size(w,h)) or UiBackendGetCurrent.Size(w,h) then begin end
  else begin w := 80; h := 24; end;
  if (h = 0) or (w = 0) then Exit;
  if ALine >= h then Exit;
  if Count < 0 then n := w else n := Count;
  if n < 0 then n := 0;
  if n > w then n := w;
  if GUseBackBuffer then
    BufWriteSegment(0, ALine, StringOfChar(Ch, n))
  else
  begin
    if Supports(UiBackendGetCurrent, IUiBackendV2, v2) then
      v2.FillRect(0, ALine, n, 1, Ch)
    else
    begin
      if Assigned(GHook_CursorLine) then GHook_CursorLine(ALine + 1) else UiBackendGetCurrent.CursorLine(ALine);
      if Assigned(GHook_CursorCol) then GHook_CursorCol(1) else UiBackendGetCurrent.CursorCol(0);
      if Assigned(GHook_Write) then GHook_Write(StringOfChar(Ch, n)) else UiBackendGetCurrent.Write(StringOfChar(Ch, n));
    end;
  end;
end;

end.

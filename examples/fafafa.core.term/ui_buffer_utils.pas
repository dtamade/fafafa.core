{$CODEPAGE UTF8}
unit ui_buffer_utils;

{$mode objfpc}{$H+}

interface

// 本单元仅用于示例层双缓冲与 diff 输出，方便在示例/plays 里复用。
// - 行级 diff：实现简单、稳定，适合行内容变化为主的 UI。
// - 块级 diff（全局脏矩形）：适合集中区域变化，能进一步减少输出量。

uses
  SysUtils, fafafa.core.signal;

type
  TStrLines = array of string;
  TFlushStats = record
    WrittenLines: Integer;
    WrittenChars: Integer;
    MinX, MinY, MaxX, MaxY: Integer; // 若无矩形则 MinX=MaxInt
  end;

  function GetLastFlushStats: TFlushStats;

  // 仅用于 demo 的轻量级估算：返回是否有变化；
  // ChangedLines: 变更行数；FullLineChars: 行级策略将写入的总字符数；
  // BlockChars: 块级（每行子区间）策略将写入的总字符数；
  // Min/Max: 全局脏矩形（若无变化则 MinX=MaxInt）。
  function EstimateDiffCosts(const PrevBuf, CurrBuf: TStrLines;
    out ChangedLines, FullLineChars, BlockChars, MinX, MinY, MaxX, MaxY: Integer): Boolean;


procedure EnsureBuffers(aW, aH: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines);
procedure ClearBuffer(var Buf: TStrLines; aW, aH: Integer);
procedure PutText(var Buf: TStrLines; X, Y: Integer; const S: string);
procedure FlushDiffAndSwap(const ModelWidth, ModelHeight: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines);
procedure FlushBlockDiffAndSwap(const ModelWidth, ModelHeight: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines);
  // SignalCenter · WINCH 辅助：在示例层统一订阅/去抖/释放
  procedure WinchAttach(out aToken: Int64; aQueueCapacity: Integer = 256);
  procedure WinchDetach(var aToken: Int64);
  function  WinchTickDebounced(var aPending: Boolean; var aLastTs: QWord; const aDebounceMs: Cardinal; out aNewSizeW, aNewSizeH: Integer): Boolean;

procedure FlushBlockDiffAndSwapRect(const ModelWidth, ModelHeight: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines; const aHighlight: Boolean; const aAsciiBorder: Boolean = False);

implementation
uses
  fafafa.core.term;

var
  GWinchTok: Int64 = 0;
  GWinchPending: Boolean = False;
  GWinchLastTs: QWord = 0;

procedure _OnWinch(const S: TSignal);
begin
  GWinchPending := True;
  GWinchLastTs := GetTickCount64;
end;

procedure WinchAttach(out aToken: Int64; aQueueCapacity: Integer);
var C: ISignalCenter;
begin
  C := SignalCenter; C.Start;
  if aQueueCapacity > 0 then
    C.ConfigureQueue(aQueueCapacity, qdpDropOldest);
  GWinchTok := C.Subscribe([sgWinch], @_OnWinch);
  aToken := GWinchTok;
end;

procedure WinchDetach(var aToken: Int64);
begin
  if (aToken <> 0) then
  begin
    SignalCenter.Unsubscribe(aToken);
    aToken := 0;
    if GWinchTok <> 0 then GWinchTok := 0;
    GWinchPending := False;
  end;
end;

function WinchTickDebounced(var aPending: Boolean; var aLastTs: QWord; const aDebounceMs: Cardinal; out aNewSizeW, aNewSizeH: Integer): Boolean;
var nowTs: QWord;
begin
  // 初始返回
  Result := False; aNewSizeW := 0; aNewSizeH := 0;
  // 与全局挂钩：将当前全局 pending/lastTs 赋给调用方的引用
  aPending := GWinchPending;
  aLastTs := GWinchLastTs;
  if not aPending then Exit(False);
  nowTs := GetTickCount64;
  if (nowTs - aLastTs) >= aDebounceMs then
  begin
    GWinchPending := False;
    aPending := False;
    if term_size(aNewSizeW, aNewSizeH) then
      Exit(True);
  end;
end;


  GLastStats: TFlushStats;

function EstimateDiffCosts(const PrevBuf, CurrBuf: TStrLines;
  out ChangedLines, FullLineChars, BlockChars, MinX, MinY, MaxX, MaxY: Integer): Boolean;
var
  y, W, L, R, RowChars: Integer;
  PrevLine, CurrLine: string;
begin
  ChangedLines := 0; FullLineChars := 0; BlockChars := 0;
  MinX := MaxInt; MinY := MaxInt; MaxX := -1; MaxY := -1;
  for y := 0 to High(CurrBuf) do
  begin
    CurrLine := CurrBuf[y];
    if y <= High(PrevBuf) then PrevLine := PrevBuf[y] else PrevLine := '';
    if (y > High(PrevBuf)) or (CurrLine <> PrevLine) then
    begin
      Inc(ChangedLines);
      W := Length(CurrLine);
      // 行级策略写全行
      Inc(FullLineChars, W);
      // 计算该行的最小子区间
      L := 1; while (L <= W) and (L <= Length(PrevLine)) and (CurrLine[L] = PrevLine[L]) do Inc(L);
      R := W; while (R >= 1) and (R <= Length(PrevLine)) and (CurrLine[R] = PrevLine[R]) do Dec(R);
      if (L <= W) and (R >= 1) and (R >= L) then
      begin
        RowChars := R - L + 1; Inc(BlockChars, RowChars);
        if L - 1 < MinX then MinX := L - 1; if R - 1 > MaxX then MaxX := R - 1;
        if y < MinY then MinY := y; if y > MaxY then MaxY := y;
      end;
    end;
  end;
  Result := ChangedLines > 0;
end;

function GetLastFlushStats: TFlushStats;
begin
  Result := GLastStats;
end;

procedure EnsureBuffers(aW, aH: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines);
var
  y: Integer;
  line: string;
begin
  if aW <= 0 then aW := 1;
  if aH <= 0 then aH := 1;
  if Length(PrevBuf) <> aH then SetLength(PrevBuf, aH);
  if Length(CurrBuf) <> aH then SetLength(CurrBuf, aH);
  line := StringOfChar(' ', aW);
  for y := 0 to aH - 1 do
  begin
    PrevBuf[y] := line;
    CurrBuf[y] := line;
  end;
end;

procedure ClearBuffer(var Buf: TStrLines; aW, aH: Integer);
var
  y: Integer;
  line: string;
begin
  if aW <= 0 then aW := 1;
  if aH <= 0 then aH := 1;
  line := StringOfChar(' ', aW);
  if Length(Buf) <> aH then SetLength(Buf, aH);
  for y := 0 to aH - 1 do Buf[y] := line;
end;

procedure PutText(var Buf: TStrLines; X, Y: Integer; const S: string);
var
  L: string;
  i, MaxCopy, W: Integer;
begin
  if (Y < 0) or (Y >= Length(Buf)) then Exit;
  if (X < 0) then X := 0;
  L := Buf[Y];
  W := Length(L);
  if (X >= W) then Exit;
  MaxCopy := Length(S);
  if X + MaxCopy > W then MaxCopy := W - X;
  if MaxCopy <= 0 then Exit;
  for i := 1 to MaxCopy do
    L[X + i] := S[i]; // Pascal 字符串从 1 开始索引
  Buf[Y] := L;
end;

procedure FlushDiffAndSwap(const ModelWidth, ModelHeight: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines);
var
  y: Integer;
  tmp: TStrLines;
  nLines, nChars: Integer;
begin
  // 统计初始化（行级 diff 不设置矩形，MinX=MaxInt 表示 N/A）
  GLastStats.WrittenLines := 0;
  GLastStats.WrittenChars := 0;
  GLastStats.MinX := MaxInt; GLastStats.MinY := MaxInt;
  GLastStats.MaxX := -1;     GLastStats.MaxY := -1;

  // 简易行级 diff：仅输出变更行
  nLines := 0; nChars := 0;
  for y := 0 to High(CurrBuf) do
  begin
    if (y <= High(PrevBuf)) and (CurrBuf[y] = PrevBuf[y]) then Continue;
    term_cursor_set(0, y);
    term_write(CurrBuf[y]);
    Inc(nLines);
    Inc(nChars, Length(CurrBuf[y]));
  end;
  GLastStats.WrittenLines := nLines;
  GLastStats.WrittenChars := nChars;

  // 交换缓冲，并清空当前缓冲
  tmp := PrevBuf; PrevBuf := CurrBuf; CurrBuf := tmp;
  ClearBuffer(CurrBuf, ModelWidth, ModelHeight);
end;

procedure FlushBlockDiffAndSwap(const ModelWidth, ModelHeight: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines);
var
  y, MinY, MaxY, MinX, MaxX, W, X: Integer;
  L, R: Integer;
  tmp: TStrLines;
  PrevLine, CurrLine: string;
  LRow, RRow: array of Integer; // 每行的变更左右边界，-1 表示该行未变更
  nLines, nChars: Integer;
begin
  // 统计初始化
  GLastStats.WrittenLines := 0;
  GLastStats.WrittenChars := 0;
  GLastStats.MinX := MaxInt; GLastStats.MinY := MaxInt;
  GLastStats.MaxX := -1;     GLastStats.MaxY := -1;
  // 预分配每行边界数组
  SetLength(LRow, Length(CurrBuf));
  SetLength(RRow, Length(CurrBuf));
  for y := 0 to High(CurrBuf) do begin LRow[y] := -1; RRow[y] := -1; end;

  // 计算全局脏矩形 + 每行变更区间（基于字符串比较）
  MinY := MaxInt; MaxY := -1; MinX := MaxInt; MaxX := -1;
  for y := 0 to High(CurrBuf) do
  begin
    CurrLine := CurrBuf[y];
    if y <= High(PrevBuf) then PrevLine := PrevBuf[y] else PrevLine := '';
    if (y > High(PrevBuf)) or (CurrLine <> PrevLine) then
    begin
      // 定位该行左右边界差异（保证 PrevLine 越界安全）
      W := Length(CurrLine);
      L := 1; while (L <= W) and (L <= Length(PrevLine)) and (CurrLine[L] = PrevLine[L]) do Inc(L);
      R := W; while (R >= 1) and (R <= Length(PrevLine)) and (CurrLine[R] = PrevLine[R]) do Dec(R);
      if (L <= W) and (R >= 1) and (R >= L) then
      begin
        // 行级变更边界（0-based）
        LRow[y] := L - 1; RRow[y] := R - 1;
        // 更新全局脏矩形上下/左右边界
        if LRow[y] < MinX then MinX := LRow[y];
        if RRow[y] > MaxX then MaxX := RRow[y];
        if y < MinY then MinY := y;
        if y > MaxY then MaxY := y;
      end;
    end;
  end;
  if (MinY <> MaxInt) and (MaxY >= 0) and (MinX <> MaxInt) and (MaxX >= 0) then
  begin
    // 输出：仅写入有变更的行的 [LRow[y]..RRow[y]] 区间，避免多写
    nLines := 0; nChars := 0;
    for y := MinY to MaxY do
    begin
      if (y <= High(LRow)) and (LRow[y] >= 0) then
      begin
        term_cursor_set(LRow[y], y);
        term_write(Copy(CurrBuf[y], LRow[y]+1, RRow[y]-LRow[y]+1));
        Inc(nLines);
        Inc(nChars, RRow[y]-LRow[y]+1);
      end;
    end;
    // 统计矩形范围（用于 UI 提示）
    GLastStats.WrittenLines := nLines;
    GLastStats.WrittenChars := nChars;
    GLastStats.MinX := MinX; GLastStats.MinY := MinY;
    GLastStats.MaxX := MaxX; GLastStats.MaxY := MaxY;
  end
  else
  begin
    // 没有变化
    GLastStats.WrittenLines := 0;
    GLastStats.WrittenChars := 0;
    GLastStats.MinX := MaxInt; GLastStats.MinY := MaxInt;
    GLastStats.MaxX := -1;     GLastStats.MaxY := -1;
  end;
  // 交换缓冲，并清空当前缓冲
  tmp := PrevBuf; PrevBuf := CurrBuf; CurrBuf := tmp;
  ClearBuffer(CurrBuf, ModelWidth, ModelHeight);
end;


procedure FlushBlockDiffAndSwapRect(const ModelWidth, ModelHeight: Integer; var PrevBuf: TStrLines; var CurrBuf: TStrLines; const aHighlight: Boolean; const aAsciiBorder: Boolean);
var
  y, MinY, MaxY, MinX, MaxX, W: Integer;
  L, R: Integer;
  tmp: TStrLines;
  rectLine: WideString; // 使用宽字符串承载 box-drawing，避免隐式窄化
  PrevLine, CurrLine: string;
  nLines, nChars: Integer;
begin
  // 初始化统计（矩形版）
  GLastStats.WrittenLines := 0;
  GLastStats.WrittenChars := 0;
  GLastStats.MinX := MaxInt; GLastStats.MinY := MaxInt;
  GLastStats.MaxX := -1;     GLastStats.MaxY := -1;

  MinY := MaxInt; MaxY := -1; MinX := MaxInt; MaxX := -1;
  for y := 0 to High(CurrBuf) do
  begin
    CurrLine := CurrBuf[y];
    if y <= High(PrevBuf) then PrevLine := PrevBuf[y] else PrevLine := '';
    if (y > High(PrevBuf)) or (CurrLine <> PrevLine) then
    begin
      W := Length(CurrLine);
      L := 1; while (L <= W) and (L <= Length(PrevLine)) and (CurrLine[L] = PrevLine[L]) do Inc(L);
      R := W; while (R >= 1) and (R <= Length(PrevLine)) and (CurrLine[R] = PrevLine[R]) do Dec(R);
      if L <= W then if L - 1 < MinX then MinX := L - 1;
      if R >= 1 then if R - 1 > MaxX then MaxX := R - 1;
      if y < MinY then MinY := y;
      if y > MaxY then MaxY := y;
    end;
  end;
  if (MinY <> MaxInt) and (MaxY >= 0) and (MinX <> MaxInt) and (MaxX >= 0) then
  begin
    // 边界裁剪，确保不越界
    if MinX < 0 then MinX := 0;
    if MinY < 0 then MinY := 0;
    if MaxX >= ModelWidth then MaxX := ModelWidth - 1;
    if MaxY >= ModelHeight then MaxY := ModelHeight - 1;

    // 先输出矩形内部内容，按行跳过未变更
    nLines := 0; nChars := 0;
    for y := MinY to MaxY do
    begin
      if (y <= High(PrevBuf)) and (CurrBuf[y] = PrevBuf[y]) then Continue;
      term_cursor_set(MinX, y);
      term_write(Copy(CurrBuf[y], MinX+1, MaxX-MinX+1));
      Inc(nLines);
      Inc(nChars, MaxX-MinX+1);
    end;

    // 统计矩形范围与写入量（用于 UI 显示）
    GLastStats.WrittenLines := nLines;
    GLastStats.WrittenChars := nChars;
    GLastStats.MinX := MinX; GLastStats.MinY := MinY;
    GLastStats.MaxX := MaxX; GLastStats.MaxY := MaxY;

    // 高亮矩形边框（box-drawing/ASCII + 亮黄色前景）
    if aHighlight then
    begin
      term_attr_push;
      term_attr_foreground_set(TERM_COLOR_PALETTE_YELLOW_BRIGHT);
      // 计算矩形尺寸
      W := MaxX - MinX + 1;
      // 选择字符集
      if aAsciiBorder then
      begin
        // ASCII 边框
        if W >= 2 then
        begin
          term_cursor_set(MinX, MinY);
          rectLine := WideString('+' + StringOfChar('-', W-2) + '+');
          term_write(rectLine);
          if MaxY > MinY then
          begin
            term_cursor_set(MinX, MaxY);
            rectLine := WideString('+' + StringOfChar('-', W-2) + '+');
            term_write(rectLine);
          end;
        end
        else if W = 1 then
        begin
          term_cursor_set(MinX, MinY);
          term_write('|');
          if MaxY > MinY then
          begin
            term_cursor_set(MinX, MaxY);
            term_write('|');
          end;
        end;
        if MaxY - MinY + 1 >= 3 then
        begin
          for y := MinY+1 to MaxY-1 do
          begin
            term_cursor_set(MinX, y);
            term_write('|');
            if W > 1 then
            begin
              term_cursor_set(MaxX, y);
              term_write('|');
            end;
          end;
        end;
      end
      else
      begin
        // Box-drawing 边框
        if W >= 2 then
        begin
          // 顶边
          term_cursor_set(MinX, MinY);
          rectLine := WideString('┌' + StringOfChar('─', W-2) + '┐');
          term_write(rectLine);
          // 底边（如果高度>1）
          if MaxY > MinY then
          begin
            term_cursor_set(MinX, MaxY);
            rectLine := WideString('└' + StringOfChar('─', W-2) + '┘');
            term_write(rectLine);
          end;
        end
        else if W = 1 then
        begin
          // 宽度为1：画单列竖线或短横线替代
          term_cursor_set(MinX, MinY);
          term_write('│');
          if MaxY > MinY then
          begin
            term_cursor_set(MinX, MaxY);
            term_write('│');
          end;
        end;
        // 竖边（高度>2 时画内层竖线）
        if MaxY - MinY + 1 >= 3 then
        begin
          for y := MinY+1 to MaxY-1 do
          begin
            // 左边
            term_cursor_set(MinX, y);
            term_write('│');
            // 右边（当宽度>1时）
            if W > 1 then
            begin
              term_cursor_set(MaxX, y);
              term_write('│');
            end;
          end;
        end;
      end;
      term_attr_pop;
    end;
  end
  else
  begin
    // 没有变化
    GLastStats.WrittenLines := 0;
    GLastStats.WrittenChars := 0;
    GLastStats.MinX := MaxInt; GLastStats.MinY := MaxInt;
    GLastStats.MaxX := -1;     GLastStats.MaxY := -1;
  end;
  // 交换缓冲，并清空当前缓冲
  tmp := PrevBuf; PrevBuf := CurrBuf; CurrBuf := tmp;
  ClearBuffer(CurrBuf, ModelWidth, ModelHeight);
end;

end.


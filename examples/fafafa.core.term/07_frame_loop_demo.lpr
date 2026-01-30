{$CODEPAGE UTF8}
program frame_loop_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, StrUtils, DateUtils,
  fafafa.core.term,
  fafafa.core.term.helpers,
  ui_buffer_utils, fafafa.core.signal;

const
  FRAME_BUDGET_MS = 16; // ~60 FPS 上限

type
  TModel = record
    Width, Height: Integer;
    MouseX, MouseY: Integer;
    Tick: QWord;
  end;

var
  Events: array[0..63] of term_event_t;
  N: SizeUInt;
  i: Integer;
  W, H: term_size_t;
  Running: Boolean = True;
  Guard: TTermModeGuard;
  Model: TModel;
  PrevBuf, CurrBuf: array of string; // 双缓冲（逐行）
  UseBlockDiff: Boolean = False;      // 用户选择：是否偏好 block 模式
  LastActualIsBlock: Boolean = False; // 实际使用：根据估算可能降级为 line
  HighlightRect: Boolean = False;
  // 边框模式：0=auto 1=ascii 2=box
  AsciiBorderMode: Integer = 0;
  // 终端能力探测
  AnyMouseSupportedState: Integer = 0; // 0=unknown, 1=yes(?1003), -1=no(only ?1002)
  DetectDeadlineTick: QWord = 300;    // 粗略检测窗口（基于 Tick）
  IsWindowsTerminal: Boolean = False;
  // 统计帧耗时(ms)
  FrameStartTS, FrameEndTS: QWord;
  FrameMs: Integer;
  // WINCH 处理（示例复用的 utils 封装）
  WinchTok: Int64 = 0;
  WinchPending: Boolean = False;
  WinchLastTs: QWord = 0;
  NewW, NewH: Integer;


procedure RenderToBuffer(const M: TModel; var Buf: TStrLines);
var
  BW, BH, HeaderLines, MaxXSpan, MaxYSpan, BX, BY, j: Integer;
  Row, BorderLabel: string;
begin
  if (M.Width <= 0) or (M.Height <= 0) then Exit;
  ClearBuffer(Buf, M.Width, M.Height);
  PutText(Buf, 0, 0, 'fafafa.core.term - frame loop demo');
  PutText(Buf, 0, 1, Format('size: %dx%d', [M.Width, M.Height]));
  PutText(Buf, 0, 2, 'press q to quit; move mouse / resize to see updates');
  PutText(Buf, 0, 3, Format('tick=%d mouse=(%d,%d)', [M.Tick, M.MouseX, M.MouseY]));
  if UseBlockDiff then PutText(Buf, 0, 4, '[diff=block] press d to toggle') else PutText(Buf, 0, 4, '[diff=line]  press d to toggle');
  // 边框模式提示：auto/ascii/box
  case AsciiBorderMode of
    0: BorderLabel := 'auto';
    1: BorderLabel := 'ascii';
  else BorderLabel := 'box';
  end;
  if UseBlockDiff then PutText(Buf, 0, 5, Format('[rect=%s] press r to toggle highlight; [border=%s] press b to cycle(auto/ascii/box)', [BoolToStr(HighlightRect, True), BorderLabel]) ) else PutText(Buf, 0, 5, '');
  // Mouse 能力提示：在 Windows Terminal 等不支持 ?1003h 的环境，会显示 requires button
  case AnyMouseSupportedState of
    1: PutText(Buf, 0, 6, 'tips: line-diff≈简单稳定；block-diff≈区域变化更优  | mouse: any-motion OK');
   -1: PutText(Buf, 0, 6, 'tips: line-diff≈简单稳定；block-diff≈区域变化更优  | mouse: move requires button');
    else PutText(Buf, 0, 6, 'tips: line-diff≈简单稳定；block-diff≈区域变化更优  | mouse: probing...');
  end;
  // 输出统计：每帧写入的行数/字符数与矩形范围（若适用），并显示“实际使用”的策略
  with GetLastFlushStats do
  begin
    if MinX = MaxInt then
      PutText(Buf, 0, 7, Format('written: lines=%d chars=%d | mode=%s(actual=%s) | frame=%dms', [
        WrittenLines, WrittenChars, IfThen(UseBlockDiff, 'block', 'line'), IfThen(LastActualIsBlock, 'block', 'line'), FrameMs]))
    else
      PutText(Buf, 0, 7, Format('written: lines=%d chars=%d rect=[%d,%d]-[%d,%d] | mode=%s(actual=%s) | frame=%dms', [
        WrittenLines, WrittenChars, MinX, MinY, MaxX, MaxY, IfThen(UseBlockDiff, 'block', 'line'), IfThen(LastActualIsBlock, 'block', 'line'), FrameMs]));
  end;

  // 演示用：一个随 tick 移动的小块，便于观察脏矩形
  HeaderLines := 7;
  BW := 8; BH := 3; // 方块宽高
  MaxXSpan := M.Width - BW - 1; if MaxXSpan < 0 then MaxXSpan := 0;
  MaxYSpan := M.Height - HeaderLines - BH; if MaxYSpan < 0 then MaxYSpan := 0;
  BX := (M.Tick div 3) mod (MaxXSpan+1);
  BY := HeaderLines + (M.Tick div 6) mod (MaxYSpan+1);
  // 画块（简化为 # 填充）
  Row := StringOfChar('#', BW);
  for j := 0 to BH-1 do
    PutText(Buf, BX, BY + j, Row);
end;

procedure FlushAndSwap;
var
  changedLines, fullLineChars, blockChars, minx, miny, maxx, maxy: Integer;
  chooseBlock: Boolean;
begin
  // 智能选择：估算 line 与 block 的写入成本，选择较小的一种（仅用于 demo，不改变 API）
  chooseBlock := UseBlockDiff;
  if EstimateDiffCosts(PrevBuf, CurrBuf, changedLines, fullLineChars, blockChars, minx, miny, maxx, maxy) then
  begin
    // 简单启发式：当 block 的写入字符数明显少于 line 时才用 block（阈值 0.8）
    if UseBlockDiff then // 仅在用户选择 block 时启用“聪明降级”
      if blockChars > 0 then
        chooseBlock := blockChars <= Trunc(0.8 * fullLineChars)
      else
        chooseBlock := False;
  end
  else
    chooseBlock := False;

  // 记录实际使用策略，供 UI 展示
  LastActualIsBlock := chooseBlock and (UseBlockDiff);

  if chooseBlock then
  begin
    if HighlightRect then
      ui_buffer_utils.FlushBlockDiffAndSwapRect(
        Model.Width, Model.Height, PrevBuf, CurrBuf, True,
        term_use_ascii_border(AsciiBorderMode, AnyMouseSupportedState, IsWindowsTerminal)
      )
    else
      ui_buffer_utils.FlushBlockDiffAndSwap(Model.Width, Model.Height, PrevBuf, CurrBuf);
  end
  else
    ui_buffer_utils.FlushDiffAndSwap(Model.Width, Model.Height, PrevBuf, CurrBuf);
end;

begin
  term_init;
  Guard := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_sgr_1006, tm_mouse_button_drag, tm_focus_1004, tm_paste_2004]);
    // 建议：开启同步输出以降低闪烁（终端支持时，不支持会优雅降级）
    term_sync_update_enable(True);
    // 进入备用屏，避免污染主屏幕缓冲；尝试开启“任意鼠标移动”
    term_alternate_screen_enable(True);
    // 优先开启按钮拖动（1002），再尝试 1003（兼容 WT）
    term_write(#27'[?1002h');
    term_write(#27'[?1003h');
    AnyMouseSupportedState := 0;
    DetectDeadlineTick := 300; // 约3~5秒探测窗口（视 Sleep/帧率而定）

	    // 附加：订阅 WINCH，并设置队列策略（抖动时丢最旧）
	    WinchAttach(WinchTok, 256);

    // 环境判断：尽可能识别 Windows Terminal（通过 WT_* 环境变量）
    IsWindowsTerminal := term_is_windows_terminal;
    // 自动边框模式初始化（auto->根据能力选择）
    if AsciiBorderMode = 0 then AsciiBorderMode := term_choose_border_mode(AnyMouseSupportedState, IsWindowsTerminal);

  try
    term_cursor_hide;
    if term_size(W, H) then begin Model.Width := W; Model.Height := H; end;
    EnsureBuffers(Model.Width, Model.Height, PrevBuf, CurrBuf);

    // 初次渲染
    RenderToBuffer(Model, CurrBuf);
    FlushAndSwap;

    while Running do
    begin
      FrameStartTS := GetTickCount64;
      // 每帧收集事件（带预算+合并/去抖）
      N := term_events_collect(Events, High(Events)+1, FRAME_BUDGET_MS);
      // 处理事件并更新状态（Model）
      if N > 0 then
      for i := 0 to Integer(N) - 1 do
      begin
        case Events[i].kind of
          tek_key:
            begin
              if (Events[i].key.key = KEY_Q) or (Events[i].key.key = KEY_q) then
                Running := False
              else if (Events[i].key.key = KEY_D) or (Events[i].key.key = KEY_d) then
                UseBlockDiff := not UseBlockDiff
              else if (Events[i].key.key = KEY_R) or (Events[i].key.key = KEY_r) then
                HighlightRect := not HighlightRect
              else if (Events[i].key.key = KEY_B) or (Events[i].key.key = KEY_b) then
                AsciiBorderMode := (AsciiBorderMode + 1) mod 3; // 0->1->2->0
            end;
          tek_mouse:
            begin
              Model.MouseX := Events[i].mouse.x;


              Model.MouseY := Events[i].mouse.y;
              // 自动边框：交由 helpers 统一策略
              if (AsciiBorderMode = 0) then
                AsciiBorderMode := term_choose_border_mode(AnyMouseSupportedState, IsWindowsTerminal);
              // 探测 any-motion 支持：若在未按键情况下收到移动，标记为支持
              if (AnyMouseSupportedState = 0) and (Events[i].mouse.state = Ord(tms_moved)) and (Events[i].mouse.button = Ord(tmb_none)) then
                AnyMouseSupportedState := 1;
            end;
          tek_sizeChange:
            begin
              W := Events[i].size.width; H := Events[i].size.height;
              Model.Width := W; Model.Height := H;
              EnsureBuffers(Model.Width, Model.Height, PrevBuf, CurrBuf);
              PrevBuf := nil; CurrBuf := nil; // 强制刷新矩形计算（避免旧尺寸残留）
              EnsureBuffers(Model.Width, Model.Height, PrevBuf, CurrBuf);

	      // 帧内：以 16ms 去抖合并 WINCH，并按需刷新缓冲
	      if WinchTickDebounced(WinchPending, WinchLastTs, 16, NewW, NewH) then
	      begin
	        Model.Width := NewW; Model.Height := NewH;
	        EnsureBuffers(Model.Width, Model.Height, PrevBuf, CurrBuf);
	        PrevBuf := nil; CurrBuf := nil;
	        EnsureBuffers(Model.Width, Model.Height, PrevBuf, CurrBuf);
	      end;

            end;
        else

          ; // ignore other event kinds to avoid incomplete-case warnings
        end;
      end;

      // 渲染到缓冲并行级 diff 输出
      Inc(Model.Tick);
      // 探测窗口过期：如果仍未知，就判定不支持 any-motion（Windows Terminal 常见）
      if (AnyMouseSupportedState = 0) and (Model.Tick > DetectDeadlineTick) then AnyMouseSupportedState := -1;

      RenderToBuffer(Model, CurrBuf);
      FlushAndSwap;

      // 帧耗时统计与自适应 Sleep
      FrameEndTS := GetTickCount64;
      FrameMs := Integer(FrameEndTS - FrameStartTS);
      if FrameMs < FRAME_BUDGET_MS then Sleep(FRAME_BUDGET_MS - FrameMs) else Sleep(0);
    end;
  finally
    term_cursor_show;
    term_sync_update_enable(False);
    term_write(#27'[?1003l'); // disable ANY-MOUSE (?1003l)
    term_write(#27'[?1002l'); // disable BUTTON-MOUSE (?1002l)
    term_alternate_screen_enable(False);
    // 释放 WINCH 订阅
    WinchDetach(WinchTok);
    term_mode_guard_done(Guard);
    term_done;
  end;
end.


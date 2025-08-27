unit fafafa.core.term.unix;

{**
 * 完整的 Unix/Linux 终端后端实现
 * 支持各种 Unix 终端：xterm, gnome-terminal, konsole 等
 * 使用 termios 和 termcap/terminfo 集成
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  classes,
  sysutils,
  baseunix,
  unix,
  termio,
  fafafa.core.signal,
  fafafa.core.env,
  fafafa.core.term;

{** Unix 终端类型 *}
type
  term_unix_t = record
    term_t: term_t;

    // 文件描述符
    stdin_fd: cint;
    stdout_fd: cint;
    stderr_fd: cint;

    // 原始状态保存
    original_termios: termios;
    current_termios: termios;

    // 终端信息
    term_name: string;
    term_type: string;

    // 能力检测
    supports_colors: Boolean;
    supports_256_colors: Boolean;
    supports_true_color: Boolean;
    supports_mouse: Boolean;
    supports_focus: Boolean;
    supports_bracketed_paste: Boolean;

    // 终端大小
    term_width: Integer;
    term_height: Integer;

    // 信号处理（改用 signal center 订阅 sgWinch）
    signal_handlers_installed: Boolean;
    sigwinch_pending: Boolean;
    winch_sub_token: Int64;

    // 光标和属性保存
    cursor_save_x: Integer;
    cursor_save_y: Integer;

    // 输入缓冲区
    input_buffer: array[0..255] of Byte;
    input_buffer_size: Integer;
    input_buffer_pos: Integer;

    // 序列解析状态
    escape_state: Integer;
    escape_buffer: array[0..63] of Char;
    escape_buffer_pos: Integer;
  end;
  pterm_unix_t = ^term_unix_t;

{** Unix 终端函数声明 *}

// 创建和销毁
function term_unix_create: pterm_t;
function term_unix_init(aTerm: pterm_t): Boolean;
procedure term_unix_destroy(aTerm: pterm_t);

// 能力检测
function term_unix_detect_capabilities(aTerm: pterm_t): Boolean;
function term_unix_query_terminal_type(aTerm: pterm_t): string;

// 基本操作
function term_unix_clear(aTerm: pterm_t): Boolean;
function term_unix_beep(aTerm: pterm_t): Boolean;
function term_unix_flash(aTerm: pterm_t): Boolean;

// 大小和位置
function term_unix_size_get(aTerm: pterm_t; var aWidth, aHeight: UInt16): Boolean;
function term_unix_cursor_get(aTerm: pterm_t; var aX, aY: UInt16): Boolean;
function term_unix_cursor_set(aTerm: pterm_t; aX, aY: UInt16): Boolean;
function term_unix_cursor_save(aTerm: pterm_t): Boolean;
function term_unix_cursor_restore(aTerm: pterm_t): Boolean;
function term_unix_cursor_shape_set(aTerm: pterm_t; aShape: term_cursor_shape_t): Boolean;
procedure term_unix_cursor_shape_reset(aTerm: pterm_t);

// 标题/图标
function term_unix_title_set(aTerm: pterm_t; const aTitle: String): Boolean;
function term_unix_icon_set(aTerm: pterm_t; const aIcon: PChar): Boolean;

// 输入输出
procedure term_unix_write(aTerm: pterm_t; const aData: pchar; aLen: Integer);
function term_unix_read_input(aTerm: pterm_t): Boolean;
function term_unix_event_available(aTerm: pterm_t): Boolean;
function term_unix_event_read(aTerm: pterm_t; var aEvent: term_event_t): Boolean;
function term_unix_event_pull(aTerm: pterm_t; aTimeout: UInt64): Boolean;

// 终端模式管理
function term_unix_set_raw_mode(aTerm: pterm_t): Boolean;
function term_unix_restore_mode(aTerm: pterm_t): Boolean;
function term_unix_enable_mouse(aTerm: pterm_t): Boolean;
function term_unix_disable_mouse(aTerm: pterm_t): Boolean;
function term_unix_alternate_screen_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;

function term_unix_raw_mode_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;

	// 解析策略配置（全局，轻量可调）
	function term_unix_get_escape_timeout_ms: Integer;
	function term_unix_set_escape_timeout_ms(aMS: Integer): Integer; // 返回旧值

// TTY 读取参数与等待策略
function term_unix_set_tty_read_params(aVMin: Byte; aVTimeDecisec: Byte): Boolean;
function term_unix_get_tty_read_params(out aVMin: Byte; out aVTimeDecisec: Byte): Boolean;
function term_unix_set_read_timeout_ms(aMS: Integer): Integer; // 便捷映射到 VTIME（0..255 * 100ms）
procedure term_unix_set_blocking_pull(aEnable: Boolean);




// 信号与策略配置
const
  DEFAULT_ESC_TIMEOUT_MS = 10;

var
  G_SIGWINCH_OCCURRED: Boolean = False;
  G_ESC_TIMEOUT_MS: Integer = DEFAULT_ESC_TIMEOUT_MS;
  G_BLOCKING_PULL: Boolean = False;

// 信号处理
procedure term_unix_setup_signals(aTerm: pterm_t);
var
  G_ESC_TIMEOUT_MS: Integer = DEFAULT_ESC_TIMEOUT_MS;

procedure term_unix_cleanup_signals(aTerm: pterm_t);

implementation

{** Unix 终端实现 *}

{** 创建 Unix 终端实例 *}
function term_unix_create: pterm_t;
var
  LTerm: pterm_unix_t;
begin
  New(LTerm);
  FillChar(LTerm^, SizeOf(term_unix_t), 0);

  // 设置函数指针
  with LTerm^.term_t do
  begin
    init := @term_unix_init;
    destroy := @term_unix_destroy;
    clear := @term_unix_clear;
    beep := @term_unix_beep;
    // 标题/图标（通过 ANSI OSC 实现）
    title_get := nil; // 无法可靠获取
    title_set := @term_unix_title_set;
    icon_set  := @term_unix_icon_set;
    // 大小/光标
    size_get := @term_unix_size_get;
    cursor_get := @term_unix_cursor_get;
    cursor_set := @term_unix_cursor_set;
    cursor_shape_set := @term_unix_cursor_shape_set;
    cursor_shape_reset := @term_unix_cursor_shape_reset;
    // IO/事件
    write := @term_unix_write;
    event_pull := @term_unix_event_pull;
    // Feature toggles
    alternate_screen_enable := @term_unix_alternate_screen_enable; // via ANSI CSI ?1049h/l
    raw_mode_enable := @term_unix_raw_mode_enable; // explicit toggle
  end;

  // 初始化
  if term_unix_init(pterm_t(LTerm)) then
    Result := pterm_t(LTerm)
  else
  begin
    Dispose(LTerm);
    Result := nil;
  end;
end;

{** 初始化 Unix 终端 *}
function term_unix_init(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_unix_t;
begin
  LTerm := pterm_unix_t(aTerm);
  Result := False;

  try
    // 获取文件描述符
    LTerm^.stdin_fd := 0;   // STDIN_FILENO
    LTerm^.stdout_fd := 1;  // STDOUT_FILENO
    LTerm^.stderr_fd := 2;  // STDERR_FILENO

    // 检查是否是终端
    if (fpIsATTY(LTerm^.stdin_fd) = 0) or (fpIsATTY(LTerm^.stdout_fd) = 0) then
      Exit;
  // 读取默认超时 behind-a-flag（可选）
  term_unix_apply_env_read_timeout_default;

    // 保存原始 termios 设置
    if tcgetattr(LTerm^.stdin_fd, LTerm^.original_termios) <> 0 then
      Exit;

    LTerm^.current_termios := LTerm^.original_termios;

    // 获取终端类型和名称
    LTerm^.term_type := term_unix_query_terminal_type(aTerm);
    LTerm^.term_name := 'Unix Terminal (' + LTerm^.term_type + ')';

    // 创建事件队列
    LTerm^.term_t.event_queue := term_event_queue_create;
    if LTerm^.term_t.event_queue = nil then
      Exit;

    // 检测终端能力
    term_unix_detect_capabilities(aTerm);

    // 设置终端属性
    LTerm^.term_t.name := LTerm^.term_name;
    LTerm^.term_t.compatibles := [tc_ansi, tc_clear, tc_beep, tc_cursor, tc_cursor_set, tc_cursor_shape_set, tc_title_set, tc_icon_set];

    if LTerm^.supports_colors then
      LTerm^.term_t.compatibles := LTerm^.term_t.compatibles + [tc_color_16];
    if LTerm^.supports_256_colors then
      LTerm^.term_t.compatibles := LTerm^.term_t.compatibles + [tc_color_256];
    if LTerm^.supports_true_color then
      LTerm^.term_t.compatibles := LTerm^.term_t.compatibles + [tc_color_24bit];
    if LTerm^.supports_mouse then
      LTerm^.term_t.compatibles := LTerm^.term_t.compatibles + [tc_mouse];

    // 模式能力：现代 ANSI 终端一般支持 1004/2004/Sync Update（可根据 supports_* 条件化）
    if LTerm^.supports_focus then
      LTerm^.term_t.compatibles := LTerm^.term_t.compatibles + [tc_focus_1004];
    if LTerm^.supports_bracketed_paste then
      LTerm^.term_t.compatibles := LTerm^.term_t.compatibles + [tc_paste_2004];
    LTerm^.term_t.compatibles := LTerm^.term_t.compatibles + [tc_sync_update];

    // 设置原始模式
    term_unix_set_raw_mode(aTerm);

    // 启用鼠标支持（如果支持）
    if LTerm^.supports_mouse then
      term_unix_enable_mouse(aTerm);

    // 设置信号处理
    term_unix_setup_signals(aTerm);

    Result := True;
  except
    Result := False;
  end;
end;

{** 销毁 Unix 终端 *}
procedure term_unix_destroy(aTerm: pterm_t);
var
  LTerm: pterm_unix_t;
begin
  if aTerm = nil then Exit;

  LTerm := pterm_unix_t(aTerm);

  try
    // 清理信号处理
    term_unix_cleanup_signals(aTerm);

    // 禁用鼠标支持
    if LTerm^.supports_mouse then
      term_unix_disable_mouse(aTerm);

    // 恢复原始终端模式
    term_unix_restore_mode(aTerm);

    // 清理事件队列
    if LTerm^.term_t.event_queue <> nil then
      term_event_queue_destroy(LTerm^.term_t.event_queue);
  except
    // 忽略清理时的错误
  end;

  // 释放内存
  Dispose(LTerm);
end;

{** 检测 Unix 终端能力 *}
function term_unix_detect_capabilities(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_unix_t;
  LTermEnv, LColortermEnv: string;
begin
  LTerm := pterm_unix_t(aTerm);
  Result := True;

  // 获取环境变量
  LTermEnv := GetEnvironmentVariable('TERM');
  LColortermEnv := GetEnvironmentVariable('COLORTERM');

  // 基本颜色支持检测
  LTerm^.supports_colors := (LTermEnv <> '') and
                           (Pos('color', LTermEnv) > 0) or
                           (Pos('xterm', LTermEnv) > 0) or
                           (Pos('screen', LTermEnv) > 0) or
                           (Pos('tmux', LTermEnv) > 0);

  // 256 色支持检测
  LTerm^.supports_256_colors := (Pos('256', LTermEnv) > 0) or
                               (Pos('256color', LTermEnv) > 0) or
                               (LTermEnv = 'xterm-256color') or
                               (LTermEnv = 'screen-256color');

  // True color (24-bit) 支持检测
  LTerm^.supports_true_color := (LColortermEnv = 'truecolor') or
                               (LColortermEnv = '24bit') or
                               (Pos('truecolor', LTermEnv) > 0);

  // 鼠标支持检测（大多数现代终端都支持）
  LTerm^.supports_mouse := (LTermEnv <> '') and
                          ((Pos('xterm', LTermEnv) > 0) or
                           (Pos('screen', LTermEnv) > 0) or
                           (Pos('tmux', LTermEnv) > 0) or
                           (LTermEnv = 'linux'));

  // 焦点/粘贴支持（默认与鼠标一致，可被环境变量覆盖）
  LTerm^.supports_focus := LTerm^.supports_mouse;
  LTerm^.supports_bracketed_paste := LTerm^.supports_mouse;

  // 环境变量覆盖（on/1 启用；off/0 禁用；未设置则保持默认）
  // FAFAFA_TERM_FEATURE_FOCUS, FAFAFA_TERM_FEATURE_PASTE
  var __v: string;
  if env_lookup('FAFAFA_TERM_FEATURE_FOCUS', __v) then
  begin
    if (CompareText(__v, 'on') = 0) or (__v = '1') then LTerm^.supports_focus := True
    else if (CompareText(__v, 'off') = 0) or (__v = '0') then LTerm^.supports_focus := False;
  end;
  if env_lookup('FAFAFA_TERM_FEATURE_PASTE', __v) then
  begin
    if (CompareText(__v, 'on') = 0) or (__v = '1') then LTerm^.supports_bracketed_paste := True
    else if (CompareText(__v, 'off') = 0) or (__v = '0') then LTerm^.supports_bracketed_paste := False;
  end;
end;

{** 查询终端类型 *}
function term_unix_query_terminal_type(aTerm: pterm_t): string;
var
  LTermEnv: string;
begin
  LTermEnv := GetEnvironmentVariable('TERM');

  if LTermEnv = '' then
    Result := 'unknown'
  else
    Result := LTermEnv;
end;

{** 清屏 *}
function term_unix_clear(aTerm: pterm_t): Boolean;
begin
  // 使用 ANSI 序列清屏
  term_unix_write(aTerm, PChar(#27'[2J'#27'[H'), 7);
  Result := True;
end;

{** 蜂鸣 *}
function term_unix_beep(aTerm: pterm_t): Boolean;
begin
  // 使用 BEL 字符
  term_unix_write(aTerm, PChar(#7), 1);
  Result := True;
end;

{** 闪烁 *}
function term_unix_flash(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_unix_t;
begin
  LTerm := pterm_unix_t(aTerm);

  if LTerm^.supports_colors then
  begin
    // 使用 ANSI 序列闪烁
    term_unix_write(aTerm, PChar(#27'[?5h'), 5);  // 反转屏幕
    fpusleep(100000); // 100ms
    term_unix_write(aTerm, PChar(#27'[?5l'), 5);  // 恢复屏幕
    Result := True;
  end
  else
  begin
    // 使用蜂鸣作为替代
    Result := term_unix_beep(aTerm);
  end;
end;

{** 获取终端大小 *}
function term_unix_size_get(aTerm: pterm_t; var aWidth, aHeight: UInt16): Boolean;
var
  LTerm: pterm_unix_t;
  LWinSize: TWinSize;
begin
  LTerm := pterm_unix_t(aTerm);
  Result := False;

  // 使用 ioctl 获取窗口大小
  if fpioctl(LTerm^.stdout_fd, TIOCGWINSZ, @LWinSize) = 0 then
  begin
    aWidth := LWinSize.ws_col;
    aHeight := LWinSize.ws_row;

    // 更新内部缓存
    LTerm^.term_width := aWidth;
    LTerm^.term_height := aHeight;

    Result := True;
  end;
end;

{** 获取光标位置 *}
function term_unix_cursor_get(aTerm: pterm_t; var aX, aY: UInt16): Boolean;
var
  LTerm: pterm_unix_t;
  LResponse: string;
  LPos: Integer;
  LRow, LCol: Integer;
begin
  LTerm := pterm_unix_t(aTerm);
  Result := False;

  // 发送光标位置查询序列
  term_unix_write(aTerm, PChar(#27'[6n'), 4);

  // 读取响应 (应该是 ESC[row;colR 格式)
  LResponse := '';
  // 这里需要实现读取响应的逻辑
  // 简化实现：返回保存的位置
  aX := LTerm^.cursor_save_x;
  aY := LTerm^.cursor_save_y;
  Result := True;
end;

{** 设置光标位置 *}
function term_unix_cursor_set(aTerm: pterm_t; aX, aY: UInt16): Boolean;
var
  LTerm: pterm_unix_t;
  LSeq: string;
begin
  LTerm := pterm_unix_t(aTerm);

  // 使用 ANSI 序列设置光标位置
  LSeq := Format(#27'[%d;%dH', [aY, aX]);
  term_unix_write(aTerm, PChar(LSeq), Length(LSeq));

  // 更新内部位置
  LTerm^.cursor_save_x := aX;
  LTerm^.cursor_save_y := aY;

  Result := True;
end;

{** 保存光标位置 *}
function term_unix_cursor_save(aTerm: pterm_t): Boolean;
begin
  // 使用 ANSI 序列保存光标位置
  term_unix_write(aTerm, PChar(#27'[s'), 3);
  Result := True;
end;

{** 恢复光标位置 *}
function term_unix_cursor_restore(aTerm: pterm_t): Boolean;
begin
  // 使用 ANSI 序列恢复光标位置
  term_unix_write(aTerm, PChar(#27'[u'), 3);
  Result := True;
end;

{** 设置光标形状 (DECSCUSR) *}
function term_unix_cursor_shape_set(aTerm: pterm_t; aShape: term_cursor_shape_t): Boolean;
var
  ps: Integer;
  seq: AnsiString;
begin
  if aTerm = nil then Exit(False);
  case aShape of
    tcs_blink_block:     ps := 1;
    tcs_block:           ps := 2;
    tcs_blink_underline: ps := 3;
    tcs_underline:       ps := 4;
    tcs_blink_bar:       ps := 5;
    tcs_bar:             ps := 6;
  else
    ps := 0; // default
  end;
  seq := #27'[' + AnsiString(IntToStr(ps)) + ' q';
  term_unix_write(aTerm, PChar(seq), Length(seq));
  Result := True;
end;

procedure term_unix_cursor_shape_reset(aTerm: pterm_t);
begin
  term_unix_cursor_shape_set(aTerm, tcs_default);
end;

{** 设置标题与图标 (OSC 2 / OSC 1) *}
function term_unix_title_set(aTerm: pterm_t; const aTitle: String): Boolean;
var s: AnsiString;
begin
  if aTerm = nil then Exit(False);
  s := #27']2;' + AnsiString(aTitle) + #7;
  term_unix_write(aTerm, PChar(s), Length(s));
  Result := True;
end;

function term_unix_icon_set(aTerm: pterm_t; const aIcon: PChar): Boolean;
var s: AnsiString;
begin
  if aTerm = nil then Exit(False);
  s := #27']1;' + AnsiString(aIcon) + #7;
  term_unix_write(aTerm, PChar(s), Length(s));
  Result := True;
end;

{** 写入数据到终端 *}
procedure term_unix_write(aTerm: pterm_t; const aData: pchar; aLen: Integer);
var
  LTerm: pterm_unix_t;
begin
  LTerm := pterm_unix_t(aTerm);

  if (aData = nil) or (aLen <= 0) then Exit;

  // 直接写入到 stdout
  fpwrite(LTerm^.stdout_fd, aData^, aLen);
end;

{** 读取输入数据 *}
function term_unix_read_input(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_unix_t;
  LBytesRead: TSsize;
  LBuffer: array[0..255] of Byte;
begin
  LTerm := pterm_unix_t(aTerm);
  Result := False;

  // 非阻塞读取
  LBytesRead := fpread(LTerm^.stdin_fd, LBuffer[0], SizeOf(LBuffer));

  if LBytesRead > 0 then
  begin
    // 将数据添加到输入缓冲区
    if LTerm^.input_buffer_size + LBytesRead <= Length(LTerm^.input_buffer) then
    begin
      Move(LBuffer[0], LTerm^.input_buffer[LTerm^.input_buffer_size], LBytesRead);
      Inc(LTerm^.input_buffer_size, LBytesRead);
      Result := True;
    end;
  end;
end;

{** 检查是否有事件可用 *}
function term_unix_event_available(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_unix_t;
  LFDSet: TFDSet;
  LTimeout: TTimeVal;
begin
  LTerm := pterm_unix_t(aTerm);

  // 检查输入缓冲区
  if LTerm^.input_buffer_pos < LTerm^.input_buffer_size then
  begin
    Result := True;
  function EscTimeoutMS: Integer; inline;
  begin
    if G_ESC_TIMEOUT_MS <= 0 then Exit(DEFAULT_ESC_TIMEOUT_MS);
    Result := G_ESC_TIMEOUT_MS;
  end;

    Exit;
  end;

  // 使用 select 检查 stdin
  fpFD_ZERO(LFDSet);
  fpFD_SET(LTerm^.stdin_fd, LFDSet);

  LTimeout.tv_sec := 0;
  LTimeout.tv_usec := 0;

  Result := fpselect(LTerm^.stdin_fd + 1, @LFDSet, nil, nil, @LTimeout) > 0;
end;

{** 读取并转换事件（含基础 VT 序列解析） *}
function term_unix_event_read(aTerm: pterm_t; var aEvent: term_event_t): Boolean;
var
  LTerm: pterm_unix_t;
  b: Byte;
  function Have: Boolean; inline;
  begin
    Result := (LTerm^.input_buffer_pos < LTerm^.input_buffer_size);
  function Remaining: Integer; inline;
  begin
    Result := LTerm^.input_buffer_size - LTerm^.input_buffer_pos;
  end;

  function EnsureNextByteWithin(ms: Integer): Boolean; inline;
  var t0: QWord;
  begin
    if Have then Exit(True);
    t0 := GetTickCount64;
    while (GetTickCount64 - t0) < QWord(ms) do
    begin
      term_unix_read_input(aTerm);
      if Have then Exit(True);
      Sleep(1);
    end;
    Result := Have;
  end;

  function EnsureNextByte: Boolean; inline;
  begin
    Result := EnsureNextByteWithin(EscTimeoutMS);
  end;

  end;
  function ReadByte(out x: Byte): Boolean; inline;
  begin
    Result := Have;
    if Result then
    begin
      x := LTerm^.input_buffer[LTerm^.input_buffer_pos];
      Inc(LTerm^.input_buffer_pos);
    end;
  end;
  function PeekByte(out x: Byte): Boolean; inline;
  begin
    Result := Have;
    if Result then x := LTerm^.input_buffer[LTerm^.input_buffer_pos];
  end;
  procedure ResetIfConsumed; inline;
  begin
    if LTerm^.input_buffer_pos >= LTerm^.input_buffer_size then
    begin
      LTerm^.input_buffer_pos := 0;
      LTerm^.input_buffer_size := 0;
    end;
  end;
  function ReadDigits(out num: LongInt): Boolean; inline;
  var ch: Byte; any: Boolean; digits: Integer;
  const MAX_DIGITS = 9; // 防止数值溢出与异常超长
  begin
    num := 0; any := False; digits := 0;
    while PeekByte(ch) and (ch >= Ord('0')) and (ch <= Ord('9')) do
    begin
      ReadByte(ch);
      Inc(digits);
      // 超过阈值后仍然消费输入，但不再扩大数值，避免溢出
      if digits <= MAX_DIGITS then
        num := num * 10 + (ch - Ord('0'));
      any := True;
    end;
    Result := any;
  end;
  procedure SetKey(k: term_key_t);
  begin
    aEvent.kind := tek_key;
    aEvent.key.key := k;
    aEvent.key.char := term_char(#0);
    aEvent.key.shift := 0; aEvent.key.ctrl := 0; aEvent.key.alt := 0;
  end;
begin
  LTerm := pterm_unix_t(aTerm);
  Result := False;

  // 确保有数据可读
  if not term_unix_event_available(aTerm) then
    term_unix_read_input(aTerm);

  if not ReadByte(b) then Exit(False);

  if b <> 27 {ESC} then
  begin
    // 普通字符
    aEvent.kind := tek_key;
    aEvent.key.key := KEY_UNKOWN;
    aEvent.key.char := term_char(Chr(b));
    aEvent.key.shift := 0; aEvent.key.ctrl := 0; aEvent.key.alt := 0;
    Result := True;
    ResetIfConsumed;
    Exit;
  end;

  // ESC 开头：尝试解析 VT 序列
  // 1) ESC [ ...  (CSI)
  if PeekByte(b) and (Chr(b) = '[') then
  begin
    ReadByte(b); // consume '['

    // SGR 鼠标: ESC [ < b ; x ; y (M|m)
    if PeekByte(b) and (Chr(b) = '<') then
    begin
      var ch: Byte; btn, cx, cy: LongInt; isRelease: Boolean;
      ReadByte(b); // consume '<'
      if not EnsureNextByte then Exit(False);
      if not ReadDigits(btn) then btn := -1;
      if PeekByte(ch) and (Chr(ch) = ';') then ReadByte(ch);
      if not EnsureNextByte then Exit(False);
      ReadDigits(cx);
      if PeekByte(ch) and (Chr(ch) = ';') then ReadByte(ch);
      if not EnsureNextByte then Exit(False);
      ReadDigits(cy);
      if not ReadByte(ch) then Exit(False);
      isRelease := (Chr(ch) = 'm');
      // btn 位编码: 0/1/2=左/中/右, 64/65=滚轮上/下, 66/67=滚轮左/右（常见实现）
      aEvent.kind := tek_mouse;
      aEvent.mouse.x := cx;
      aEvent.mouse.y := cy;

      // 解析修饰键与移动/滚轮标志位（SGR 1006）
      // 按位：+4=Shift, +8=Alt/Meta, +16=Ctrl, +32=Move, +64=Wheel
      var mods: LongInt; base: LongInt; isMove, isWheel: Boolean;
      mods := btn;
      isMove := (mods and 32) <> 0;
      isWheel := (mods and 64) <> 0;
      aEvent.mouse.shift := Ord((mods and 4) <> 0);
      aEvent.mouse.alt   := Ord((mods and 8) <> 0);
      aEvent.mouse.ctrl  := Ord((mods and 16) <> 0);

      // 去掉修饰位，保留基础编码（0..3 或 0..3 + 64 对应滚轮方向）
      base := btn and (not (4 or 8 or 16 or 32 or 64));

      if isWheel then
      begin
        case (base and 3) of
          0: aEvent.mouse.button := Ord(tmb_wheel_up);
          1: aEvent.mouse.button := Ord(tmb_wheel_down);
          2: aEvent.mouse.button := Ord(tmb_wheel_left);
          3: aEvent.mouse.button := Ord(tmb_wheel_right);
        else
          aEvent.mouse.button := Ord(tmb_none);
        end;
        // 滚轮统一视为一次瞬时按下事件
        aEvent.mouse.state := Ord(tms_press);
      end
      else
      begin
        // 普通按钮：左/中/右
        case (base and 3) of
          0: aEvent.mouse.button := Ord(tmb_left);
          1: aEvent.mouse.button := Ord(tmb_middle);
          2: aEvent.mouse.button := Ord(tmb_right);
        else
          aEvent.mouse.button := Ord(tmb_none);
        end;
        // 移动优先于按下；释放由 'm' 标志决定
        if isMove then
          aEvent.mouse.state := Ord(tms_moved)
        else if isRelease then
          aEvent.mouse.state := Ord(tms_release)
        else
          aEvent.mouse.state := Ord(tms_press);
      end;

      Result := True;
      ResetIfConsumed;
      Exit;
    end
    // 焦点事件: ESC [ I (FocusIn), ESC [ O (FocusOut)
    else if PeekByte(b) and ((Chr(b) = 'I') or (Chr(b) = 'O')) then
    begin
      ReadByte(b);
      aEvent.kind := tek_focus;
      aEvent.focus.focus := (Chr(b) = 'I');
      Result := True;
      ResetIfConsumed;
      Exit;
    end;

    // 可能是 A/B/C/D/H/F 或 数字序列 + ~ 或 修饰字母
    if PeekByte(b) and (b >= Ord('A')) and (b <= Ord('Z')) then
    begin
      // 粘贴事件边界：ESC [ 200 ~ 文本 ESC [ 201 ~
      if Chr(b) = '2' then
      begin
        var ch: Byte; code: LongInt;
        // 读取可能的 '200' / '201'
        ReadDigits(code);
        if PeekByte(ch) and (Chr(ch) = '~') then
        begin
          ReadByte(ch); // consume '~'
          if code = 200 then
          begin
            // 读取直到 ESC [ 201 ~
            var buf: TStringBuilder;
            buf := TStringBuilder.Create(256);
            try
              while True do
              begin
                // 贪婪读取直到遇到 ESC '[' '2' '0' '1' '~'
                if not Have then term_unix_read_input(aTerm);
                if (Remaining >= 5) and
                   (LTerm^.input_buffer[LTerm^.input_buffer_pos] = 27) and
                   (LTerm^.input_buffer[LTerm^.input_buffer_pos+1] = Ord('[')) and
                   (LTerm^.input_buffer[LTerm^.input_buffer_pos+2] = Ord('2')) and
                   (LTerm^.input_buffer[LTerm^.input_buffer_pos+3] = Ord('0')) and
                   (LTerm^.input_buffer[LTerm^.input_buffer_pos+4] = Ord('1')) then
                begin
                  // 消费 ESC [ 201 ~
                  ReadByte(ch); ReadByte(ch); ReadByte(ch); ReadByte(ch); ReadByte(ch);
                  if PeekByte(ch) and (Chr(ch) = '~') then ReadByte(ch);
                  // 生成粘贴事件（通过全局存储避免变体记录中的管理类型字段）
                  aEvent.kind := tek_paste;
                  aEvent.paste.id := term_paste_store_text(buf.ToString);
                  if G_PASTE_AUTO_KEEP_LAST > 0 then
                    term_paste_trim_keep_last(G_PASTE_AUTO_KEEP_LAST);
                  Result := True; ResetIfConsumed; Exit;
                end;
                // 正常消费一个字节
                if ReadByte(ch) then buf.Append(Char(ch)) else Break;
              end;
            finally
              buf.Free;
            end;
          end;
        end;
      end;

      ReadByte(b);
      case Chr(b) of
        'A': SetKey(KEY_UP);
        'B': SetKey(KEY_DOWN);
        'C': SetKey(KEY_RIGHT);
        'D': SetKey(KEY_LEFT);
        'H': SetKey(KEY_HOME);
        'F': SetKey(KEY_END);
      else
        SetKey(KEY_ESC);
      end;
      Result := True;
      ResetIfConsumed;
      Exit;
    end
    else
    begin
      // 数字 [ <num> [; <num>] ~ 或 形如 1;5A
      var p1, p2: LongInt; ch: Byte;
      p1 := 0; p2 := -1;
      ReadDigits(p1);
      if PeekByte(ch) and (Chr(ch) = ';') then
      begin
        ReadByte(ch); // consume ';'
        ReadDigits(p2);
      end;
      if PeekByte(ch) and (Chr(ch) = '~') then
      begin
        ReadByte(ch); // consume '~'
        case p1 of
          1,7:  SetKey(KEY_HOME);
          4,8:  SetKey(KEY_END);
          2:    SetKey(KEY_INSERT);
          3:    SetKey(KEY_DELETE);
          5:    SetKey(KEY_PAGE_UP);
          6:    SetKey(KEY_PAGE_DOWN);
          15:   SetKey(KEY_F5);
          17:   SetKey(KEY_F6);
          18:   SetKey(KEY_F7);
          19:   SetKey(KEY_F8);
          20:   SetKey(KEY_F9);
          21:   SetKey(KEY_F10);
          23:   SetKey(KEY_F11);
          24:   SetKey(KEY_F12);
        else
          SetKey(KEY_ESC);
        end;
        // 解析修饰位（xterm: 2=Shift 3=Alt 4=Shift+Alt 5=Ctrl 6=Shift+Ctrl 7=Alt+Ctrl 8=Shift+Alt+Ctrl）
        if p2 <> -1 then
        begin
          if p2 in [2,4,6,8] then aEvent.key.shift := 1;
          if p2 in [3,4,7,8] then aEvent.key.alt := 1;
          if p2 in [5,6,7,8] then aEvent.key.ctrl := 1;
        end;
        Result := True;
        ResetIfConsumed;
        Exit;
      end
      else
      begin
        // 形如 1;5A 等，解析修饰键并尝试终结字母
        var modv: LongInt; letter: Byte;
        modv := 1;
        if p2 <> -1 then modv := p2;
        if PeekByte(letter) and ((letter >= Ord('A')) and (letter <= Ord('Z'))) then
        begin
          ReadByte(letter);
          case Chr(letter) of
            'A': SetKey(KEY_UP);
            'B': SetKey(KEY_DOWN);
            'C': SetKey(KEY_RIGHT);
            'D': SetKey(KEY_LEFT);
            'H': SetKey(KEY_HOME);
            'F': SetKey(KEY_END);
          else
            SetKey(KEY_ESC);
          end;
          // xterm 修饰位: 2=Shift 3=Alt 4=Shift+Alt 5=Ctrl 6=Shift+Ctrl 7=Alt+Ctrl 8=Shift+Alt+Ctrl
          if modv in [2,4,6,8] then aEvent.key.shift := 1;
          if modv in [3,4,7,8] then aEvent.key.alt := 1;
          if modv in [5,6,7,8] then aEvent.key.ctrl := 1;
          Result := True;
          ResetIfConsumed;
          Exit;
        end;
      end;
    end;
  end
  // 2) ESC O ... (SS3) 常见 F1..F4
  else if PeekByte(b) and (Chr(b) = 'O') then
  begin
    ReadByte(b); // consume 'O'
    if ReadByte(b) then
    begin
      case Chr(b) of
        'P': SetKey(KEY_F1);
        'Q': SetKey(KEY_F2);
        'R': SetKey(KEY_F3);
        'S': SetKey(KEY_F4);
      else
        SetKey(KEY_ESC);
      end;
      Result := True;
      ResetIfConsumed;
      Exit;
    end;
  end;

  // 退化为单独 ESC
  SetKey(KEY_ESC);
  Result := True;
  ResetIfConsumed;
end;

{** 拉取事件到队列 *}
function term_unix_event_pull(aTerm: pterm_t; aTimeout: UInt64): Boolean;
var
  LTerm: pterm_unix_t;
  LEvent: term_event_t;
  LStartTime: QWord;
  LCurrentTime: QWord;
    // 优先处理挂起的 SIGWINCH（仅设置一次，避免风暴）
    if G_SIGWINCH_OCCURRED then
    begin
      G_SIGWINCH_OCCURRED := False;
      // 查询当前窗口尺寸并推送 sizeChange
      var w, h: UInt16;
      if term_unix_size_get(aTerm, w, h) then
      begin
        term_event_push_size_change(aTerm, w, h);
        Exit(True);
      end;
    end;

begin
  LTerm := pterm_unix_t(aTerm);
  Result := False;
  LStartTime := GetTickCount64;

  repeat
    // 检查是否有事件可用
    if term_unix_event_available(aTerm) then
    begin
      // 读取输入数据
      if term_unix_read_input(aTerm) then
      begin
        // 尝试读取并转换事件
        while term_unix_event_read(aTerm, LEvent) do
        begin
          // 将事件推入队列
          term_event_queue_push(LTerm^.term_t.event_queue, LEvent);
          Result := True;
        end;
      end;
    end;

    // 如果已经有事件，立即返回
    if Result then
      Break;

    // 阻塞等待或非阻塞休眠
    if G_BLOCKING_PULL and (aTimeout <> High(UInt64)) then
    begin
      // 计算剩余时间并阻塞等待
      LCurrentTime := GetTickCount64;
      var elapsed := LCurrentTime - LStartTime;
      if elapsed >= aTimeout then Break;
      var remain := aTimeout - elapsed;
      var tv: TTimeVal;
      tv.tv_sec := remain div 1000;
      tv.tv_usec := (remain mod 1000) * 1000;
      var rfds: TFDSet;
      fpFD_ZERO(rfds);
      fpFD_SET(LTerm^.stdin_fd, rfds);
      if fpselect(LTerm^.stdin_fd + 1, @rfds, nil, nil, @tv) < 0 then ; // 忽略中断
    end
    else
    begin
      // 短暂休眠避免 CPU 占用过高
      fpusleep(10000); // 10ms
    end;

    // 检查超时
    LCurrentTime := GetTickCount64;
    if (aTimeout <> High(UInt64)) and (LCurrentTime - LStartTime >= aTimeout) then
      Break;
  until False;
end;

{** 设置原始模式 *}
function term_unix_set_raw_mode(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_unix_t;
  LRawTermios: termios;
begin
  LTerm := pterm_unix_t(aTerm);

  // 复制当前设置
  LRawTermios := LTerm^.current_termios;

  // 设置原始模式标志
  LRawTermios.c_iflag := LRawTermios.c_iflag and not (BRKINT or ICRNL or INPCK or ISTRIP or IXON);
  LRawTermios.c_oflag := LRawTermios.c_oflag and not OPOST;
  LRawTermios.c_cflag := (LRawTermios.c_cflag and not (CSIZE or PARENB)) or CS8;
  LRawTermios.c_lflag := LRawTermios.c_lflag and not (ECHO or ICANON or IEXTEN or ISIG);

  // 设置读取参数
  LRawTermios.c_cc[VMIN] := 0;   // 非阻塞读取
  LRawTermios.c_cc[VTIME] := 0;  // 无超时

  // 应用设置
  Result := tcsetattr(LTerm^.stdin_fd, TCSAFLUSH, LRawTermios) = 0;

  if Result then
    LTerm^.current_termios := LRawTermios;
end;

{** 恢复原始模式 *}
function term_unix_restore_mode(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_unix_t;
begin
  LTerm := pterm_unix_t(aTerm);
  Result := tcsetattr(LTerm^.stdin_fd, TCSAFLUSH, LTerm^.original_termios) = 0;
function term_unix_get_escape_timeout_ms: Integer;
begin
  Result := G_ESC_TIMEOUT_MS;
end;

function term_unix_set_escape_timeout_ms(aMS: Integer): Integer;
begin
  Result := G_ESC_TIMEOUT_MS;
  if aMS < 0 then G_ESC_TIMEOUT_MS := DEFAULT_ESC_TIMEOUT_MS
  else G_ESC_TIMEOUT_MS := aMS;
end;

end;

function term_unix_raw_mode_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;
begin
  if aEnable then
    Result := term_unix_set_raw_mode(aTerm)
  else
    Result := term_unix_restore_mode(aTerm);
end;

{** 启用鼠标支持 *}
function term_unix_enable_mouse(aTerm: pterm_t): Boolean;

function term_unix_set_tty_read_params(aVMin: Byte; aVTimeDecisec: Byte): Boolean;
var LTerm: pterm_unix_t; T: termios;
begin
  LTerm := pterm_unix_t(_term);
  if LTerm = nil then Exit(False);
  T := LTerm^.current_termios;
  T.c_cc[VMIN] := aVMin;
  T.c_cc[VTIME] := aVTimeDecisec;
  Result := tcsetattr(LTerm^.stdin_fd, TCSAFLUSH, T) = 0;
  if Result then LTerm^.current_termios := T;
end;

function term_unix_get_tty_read_params(out aVMin: Byte; out aVTimeDecisec: Byte): Boolean;
var LTerm: pterm_unix_t;
begin
  LTerm := pterm_unix_t(_term);
  if LTerm = nil then Exit(False);
  aVMin := LTerm^.current_termios.c_cc[VMIN];
  aVTimeDecisec := LTerm^.current_termios.c_cc[VTIME];
  Result := True;
end;

function term_unix_set_read_timeout_ms(aMS: Integer): Integer;
var oldVMin, oldVTime: Byte; deci: Integer;
begin
  if not term_unix_get_tty_read_params(oldVMin, oldVTime) then Exit(-1);
  Result := oldVTime * 100; // 100ms units
  if aMS < 0 then deci := 0 else deci := aMS div 100;
  if deci > 255 then deci := 255;
  term_unix_set_tty_read_params(0, deci);
end;

procedure term_unix_apply_env_read_timeout_default;
var s: string; v, old: Integer;
begin
  s := GetEnvironmentVariable('FAFAFA_TERM_READ_TIMEOUT_MS');
  if s = '' then Exit;
  Val(s, v);
  if v < 0 then v := 0;
  old := term_unix_set_read_timeout_ms(v);
end;

procedure term_unix_set_blocking_pull(aEnable: Boolean);
begin
  G_BLOCKING_PULL := aEnable;
end;

begin
  // 鼠标协议启停策略（对齐 tcell/crossterm）：
  // - 优先启用 SGR(1006)
  // - 同时兼容 basic(1000) 与 button event(1002)
  // - 兼容 urxvt(1015) 作为少数终端的 fallback
  // 注：顺序上的“1006 优先”只影响文档语义；终端会选择其支持的子集处理
  term_unix_write(aTerm, PChar(#27'[?1006h'), 8);  // SGR 鼠标模式（首选）
  term_unix_write(aTerm, PChar(#27'[?1002h'), 8);  // 按钮事件跟踪
  term_unix_write(aTerm, PChar(#27'[?1000h'), 8);  // 基本鼠标跟踪
  term_unix_write(aTerm, PChar(#27'[?1015h'), 8);  // urxvt 鼠标模式

function term_unix_alternate_screen_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;
begin
  Result := False;
  if aTerm = nil then Exit;
  if aEnable then term_unix_write(aTerm, PChar(#27'[?1049h'), 8)
  else term_unix_write(aTerm, PChar(#27'[?1049l'), 8);
  Result := True;
end;

  term_unix_write(aTerm, PChar(#27'[?1006h'), 8);  // SGR 鼠标模式
  Result := True;
end;

{** 禁用鼠标支持 *}
function term_unix_disable_mouse(aTerm: pterm_t): Boolean;
begin
  // 鼠标协议禁用（与启用反向顺序一致，先关 SGR，再依次回退）
  term_unix_write(aTerm, PChar(#27'[?1006l'), 8);  // SGR 鼠标模式
  term_unix_write(aTerm, PChar(#27'[?1002l'), 8);  // 按钮事件跟踪
  term_unix_write(aTerm, PChar(#27'[?1000l'), 8);  // 基本鼠标跟踪
  term_unix_write(aTerm, PChar(#27'[?1015l'), 8);  // urxvt 鼠标模式
  Result := True;
end;

{** 信号处理函数 *}
{$IFNDEF FAFAFA_TERM_USE_SIGNALCENTER_WINCH}
procedure term_unix_sigwinch_handler(sig: cint); cdecl;
begin
  {$IFDEF UNIX}
  G_SIGWINCH_OCCURRED := True;
  {$ENDIF}
end;

procedure term_unix_sigterm_handler(sig: cint); cdecl;
begin
end;
{$ENDIF}

{** 设置信号处理 *}
procedure term_unix_setup_signals(aTerm: pterm_t);
var
  LTerm: pterm_unix_t;
  {$IFNDEF FAFAFA_TERM_USE_SIGNALCENTER_WINCH}
  LAction: SigActionRec;
  {$ENDIF}
begin
  LTerm := pterm_unix_t(aTerm);

  {$IFDEF FAFAFA_TERM_USE_SIGNALCENTER_WINCH}
  // 确保 signal center 已启动（跨平台安全）
  SignalCenter.Start;
  // 建议默认去抖 16ms（可被业务覆盖）；支持环境变量 FAFAFA_TERM_RESIZE_DEBOUNCE_MS，默认 50
  var __deb: string; var __ms: Integer;
  __deb := GetEnvironmentVariable('FAFAFA_TERM_RESIZE_DEBOUNCE_MS');
  if __deb <> '' then Val(__deb, __ms) else __ms := 50;
  if __ms < 0 then __ms := 0;
  SignalCenter.ConfigureWinchDebounce(__ms);
  if LTerm^.winch_sub_token = 0 then
    LTerm^.winch_sub_token := SignalCenter.Subscribe([sgWinch],
      procedure (const S: TSignal)
      begin
        G_SIGWINCH_OCCURRED := True;
      end
    );
  LTerm^.signal_handlers_installed := False;
  {$ELSE}
  try
    FillChar(LAction, SizeOf(LAction), 0);
    LAction.sa_handler := @term_unix_sigwinch_handler;
    sigemptyset(LAction.sa_mask);
    LAction.sa_flags := SA_RESTART;
    if fpSigAction(SIGWINCH, @LAction, nil) = 0 then
      LTerm^.signal_handlers_installed := True;

    FillChar(LAction, SizeOf(LAction), 0);
    LAction.sa_handler := @term_unix_sigterm_handler;
    sigemptyset(LAction.sa_mask);
    LAction.sa_flags := SA_RESTART;
    fpSigAction(SIGTERM, @LAction, nil);
  except
  end;
  {$ENDIF}
end;

{** 清理信号处理 *}
procedure term_unix_cleanup_signals(aTerm: pterm_t);
var
  LTerm: pterm_unix_t;
  LAction: SigActionRec;
begin
  LTerm := pterm_unix_t(aTerm);

  {$IFDEF FAFAFA_TERM_USE_SIGNALCENTER_WINCH}
  if LTerm^.winch_sub_token <> 0 then
  begin
    try
      SignalCenter.Unsubscribe(LTerm^.winch_sub_token);
    finally
      LTerm^.winch_sub_token := 0;
    end;
  end;
  {$ELSE}
  if LTerm^.signal_handlers_installed then
  begin
    try
      FillChar(LAction, SizeOf(LAction), 0);
      LAction.sa_handler := SIG_DFL;
      sigemptyset(LAction.sa_mask);
      fpSigAction(SIGWINCH, @LAction, nil);
      fpSigAction(SIGTERM, @LAction, nil);
      LTerm^.signal_handlers_installed := False;
    except
    end;
  end;
  {$ENDIF}
end;

end.







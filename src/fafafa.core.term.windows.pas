unit fafafa.core.term.windows;

{**
 * Windows 终端后端实现
 * 支持 Windows Console API 和 Virtual Terminal 序列
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.term, fafafa.core.env;

const
  // Console API 常量
  STD_INPUT_HANDLE = DWORD(-10);
  STD_OUTPUT_HANDLE = DWORD(-11);
  STD_ERROR_HANDLE = DWORD(-12);

  ENABLE_PROCESSED_INPUT = $0001;
  ENABLE_LINE_INPUT = $0002;
  ENABLE_ECHO_INPUT = $0004;
  ENABLE_WINDOW_INPUT = $0008;
  ENABLE_MOUSE_INPUT = $0010;
  ENABLE_INSERT_MODE = $0020;
  ENABLE_QUICK_EDIT_MODE = $0040;
  ENABLE_EXTENDED_FLAGS = $0080;
  ENABLE_VIRTUAL_TERMINAL_INPUT = $0200;

  ENABLE_PROCESSED_OUTPUT = $0001;
  ENABLE_WRAP_AT_EOL_OUTPUT = $0002;
  ENABLE_VIRTUAL_TERMINAL_PROCESSING = $0004;
  DISABLE_NEWLINE_AUTO_RETURN = $0008; // behind-a-flag: FAFAFA_TERM_WIN_NEWLINE_MODE

  CP_UTF8 = 65001;

  // 输入事件类型
  KEY_EVENT = $0001;
  MOUSE_EVENT = $0002;
  WINDOW_BUFFER_SIZE_EVENT = $0004;
  FOCUS_EVENT = $0010;

  // 鼠标按钮状态
  FROM_LEFT_1ST_BUTTON_PRESSED = $0001;
  FROM_LEFT_2ND_BUTTON_PRESSED = $0004;
  FROM_LEFT_3RD_BUTTON_PRESSED = $0008;
  FROM_LEFT_4TH_BUTTON_PRESSED = $0010;
  RIGHTMOST_BUTTON_PRESSED = $0002;

  // 鼠标事件标志
  MOUSE_MOVED = $0001;
  DOUBLE_CLICK = $0002;
  MOUSE_WHEELED = $0004;
  MOUSE_HWHEELED = $0008;

  // 控制键状态
  RIGHT_ALT_PRESSED = $0001;
  LEFT_ALT_PRESSED = $0002;
  RIGHT_CTRL_PRESSED = $0004;
  LEFT_CTRL_PRESSED = $0008;
  SHIFT_PRESSED = $0010;
  NUMLOCK_ON = $0020;
  SCROLLLOCK_ON = $0040;
  CAPSLOCK_ON = $0080;
  ENHANCED_KEY = $0100;

  // 等待常量
  INFINITE = $FFFFFFFF;
  WAIT_OBJECT_0 = $00000000;
  INVALID_HANDLE_VALUE = THandle(-1);

type
  WINBOOL   = longbool;
  BOOL      = WINBOOL;
  SHORT     = smallint;
  UINT      = cardinal;
  LPVOID    = pointer;
  LPCVOID   = pointer;
  LPWORD    = ^word;
  LPDWORD   = ^DWORD;
  LPCSTR    = PChar;
  LPWSTR    = pwidechar;

  ULONG     = cardinal;
  USHORT    = word;

  COLORREF  = cardinal;
  TCOLORREF = cardinal;
  WCHAR     = WideChar;

  // 基本类型定义
  COORD = record
    X: SHORT;
    Y: SHORT;
  end;
  TCOORD = COORD;
  PCOORD = ^COORD;

  SMALL_RECT = record
    Left: SHORT;
    Top: SHORT;
    Right: SHORT;
    Bottom: SHORT;
  end;

  // 输入记录类型
  KEY_EVENT_RECORD = record
    bKeyDown: BOOL;
    wRepeatCount: Word;
    wVirtualKeyCode: Word;
    wVirtualScanCode: Word;
    case Integer of
      0: (UnicodeChar: WCHAR; dwControlKeyState: DWORD);
      1: (AsciiChar: AnsiChar; dwControlKeyState2: DWORD);
  end;

  MOUSE_EVENT_RECORD = record
    dwMousePosition: COORD;
    dwButtonState: DWORD;
    dwControlKeyState: DWORD;
    dwEventFlags: DWORD;
  end;

  WINDOW_BUFFER_SIZE_RECORD = record
    dwSize: COORD;
  end;

  FOCUS_EVENT_RECORD = record
    bSetFocus: BOOL;
  end;

  INPUT_RECORD = record
    EventType: Word;
    case Integer of
      0: (KeyEvent: KEY_EVENT_RECORD);
      1: (MouseEvent: MOUSE_EVENT_RECORD);
      2: (WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD);
      3: (FocusEvent: FOCUS_EVENT_RECORD);
  end;
  PINPUT_RECORD = ^INPUT_RECORD;

  CONSOLE_SCREEN_BUFFER_INFO = record
    dwSize: COORD;
    dwCursorPosition: COORD;
    wAttributes: Word;
    srWindow: SMALL_RECT;
    dwMaximumWindowSize: COORD;
  end;

  term_windows_t = record
    term_t: term_t;

    // 文件句柄
    std_in: THandle;
    std_out: THandle;
    std_err: THandle;

    // 原始状态保存
    original_input_mode: DWORD;
    original_output_mode: DWORD;
    current_input_mode: DWORD;
    current_output_mode: DWORD;

    // 代码页保存
    original_cp: UINT;
    original_output_cp: UINT;

    // 能力检测
    supports_vt: Boolean;
    supports_mouse: Boolean;
    supports_focus: Boolean;
    // 可选：使用 VT 输入（behind-a-flag，默认 False）
    use_vt_input: Boolean;

    // 记忆上次鼠标按钮状态，用于判定按下/释放
    last_button_state: DWORD;

    // No-Scrollbar mode state
    original_buffer_size: COORD;
    original_window_rect: SMALL_RECT;
    no_scrollbar_locked: Boolean;
  end;
  pterm_windows_t = ^term_windows_t;

// Windows API 函数声明
function GetStdHandle(nStdHandle: DWORD): THandle; stdcall; external 'kernel32.dll';
function GetConsoleMode(hConsoleHandle: THandle; var lpMode: DWORD): BOOL; stdcall; external 'kernel32.dll';
function SetConsoleMode(hConsoleHandle: THandle; dwMode: DWORD): BOOL; stdcall; external 'kernel32.dll';
function GetConsoleCP: UINT; stdcall; external 'kernel32.dll';
function GetConsoleOutputCP: UINT; stdcall; external 'kernel32.dll';
function SetConsoleCP(wCodePageID: UINT): BOOL; stdcall; external 'kernel32.dll';
function SetConsoleOutputCP(wCodePageID: UINT): BOOL; stdcall; external 'kernel32.dll';
function GetConsoleScreenBufferInfo(hConsoleOutput: THandle; var lpConsoleScreenBufferInfo: CONSOLE_SCREEN_BUFFER_INFO): BOOL; stdcall; external 'kernel32.dll';
function SetConsoleCursorPosition(hConsoleOutput: THandle; dwCursorPosition: COORD): BOOL; stdcall; external 'kernel32.dll';
function FillConsoleOutputCharacterA(hConsoleOutput: THandle; cCharacter: AnsiChar; nLength: DWORD; dwWriteCoord: COORD; var lpNumberOfCharsWritten: DWORD): BOOL; stdcall; external 'kernel32.dll';
function WriteConsoleA(hConsoleOutput: THandle; lpBuffer: Pointer; nNumberOfCharsToWrite: DWORD; var lpNumberOfCharsWritten: DWORD; lpReserved: Pointer): BOOL; stdcall; external 'kernel32.dll';
function ReadConsoleInputA(hConsoleInput: THandle; var lpBuffer: INPUT_RECORD; nLength: DWORD; var lpNumberOfEventsRead: DWORD): BOOL; stdcall; external 'kernel32.dll';
function ReadConsoleInputW(hConsoleInput: THandle; var lpBuffer: INPUT_RECORD; nLength: DWORD; var lpNumberOfEventsRead: DWORD): BOOL; stdcall; external 'kernel32.dll';
function GetNumberOfConsoleInputEvents(hConsoleInput: THandle; var lpNumberOfEvents: DWORD): BOOL; stdcall; external 'kernel32.dll';
function SetConsoleScreenBufferSize(hConsoleOutput: THandle; dwSize: COORD): BOOL; stdcall; external 'kernel32.dll';
function SetConsoleWindowInfo(hConsoleOutput: THandle; bAbsolute: BOOL; const lpConsoleWindow: SMALL_RECT): BOOL; stdcall; external 'kernel32.dll';
function GetLargestConsoleWindowSize(hConsoleOutput: THandle): COORD; stdcall; external 'kernel32.dll';

function WaitForSingleObject(hHandle: THandle; dwMilliseconds: DWORD): DWORD; stdcall; external 'kernel32.dll';
function MessageBeep(uType: UINT): BOOL; stdcall; external 'user32.dll';
function WriteConsoleW(hConsoleOutput: THandle; lpBuffer: Pointer; nNumberOfCharsToWrite: DWORD; var lpNumberOfCharsWritten: DWORD; lpReserved: Pointer): BOOL; stdcall; external 'kernel32.dll';
function WriteFile(hFile: THandle; lpBuffer: Pointer; nNumberOfBytesToWrite: DWORD; var lpNumberOfBytesWritten: DWORD; lpOverlapped: Pointer): BOOL; stdcall; external 'kernel32.dll';


// 内部函数声明
function term_windows_init(aTerm: pterm_t): Boolean;
procedure term_windows_destroy(aTerm: pterm_t);
function term_windows_clear(aTerm: pterm_t): Boolean;
function term_windows_beep(aTerm: pterm_t): Boolean;
function term_windows_size_get(aTerm: pterm_t; var aWidth, aHeight: UInt16): Boolean;
function term_windows_cursor_get(aTerm: pterm_t; var aX, aY: UInt16): Boolean;
function term_windows_cursor_set(aTerm: pterm_t; aX, aY: UInt16): Boolean;
procedure term_windows_write(aTerm: pterm_t; const aData: pchar; aLen: Integer);
procedure term_windows_write_wide(aTerm: pterm_t; const aData: pwidechar; aLen: Integer);

// Enable/disable mouse event production via console mode
function term_windows_mouse_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;

function term_windows_event_pull(aTerm: pterm_t; aTimeout: UInt64): Boolean;

// Title/Icon forward declarations
function term_windows_title_get(aTerm: pterm_t): string;
function term_windows_title_set(aTerm: pterm_t; const aTitle: String): Boolean;
function term_windows_icon_set(aTerm: pterm_t; const aIcon: PChar): Boolean;

// Alternate screen forward declaration
function term_windows_alternate_screen_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;
// Raw mode forward declaration
function term_windows_raw_mode_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;

// Cursor shape (DECSCUSR) forward declarations
function term_windows_cursor_shape_set(aTerm: pterm_t; aShape: term_cursor_shape_t): Boolean;
procedure term_windows_cursor_shape_reset(aTerm: pterm_t);

// Attribute emitters forward declarations
procedure term_windows_attr_reset(aTerm: pterm_t);
procedure term_windows_attr_foreground_24bit_set(aTerm: pterm_t; const aColor: term_color_24bit_t);
procedure term_windows_attr_background_24bit_set(aTerm: pterm_t; const aColor: term_color_24bit_t);
procedure term_windows_attr_color_24bit_set(aTerm: pterm_t; const aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t);


// 事件转换函数
function term_windows_convert_key_event(const aKeyEvent: KEY_EVENT_RECORD): term_event_t;
function term_windows_convert_mouse_event(aTerm: pterm_windows_t; const aMouseEvent: MOUSE_EVENT_RECORD): term_event_t;
function term_windows_convert_size_event(const aSizeEvent: WINDOW_BUFFER_SIZE_RECORD): term_event_t;
function term_windows_convert_focus_event(const aFocusEvent: FOCUS_EVENT_RECORD): term_event_t;

// 导出函数
function term_windows_create: pterm_t;

implementation

uses SysUtils;

var
  G_WIN_FORCE_WRITEFILE: Boolean = False; // 调试/回退：强制使用 WriteFile 输出

function StrToBoolLoose(const S: string; const Default: Boolean): Boolean;
begin
  case LowerCase(Trim(S)) of
    '1','true','yes','on','y','t': Exit(True);
    '0','false','no','off','n','f','': Exit(False);
  end;
  Result := Default;
end;


function term_windows_create: pterm_t;
var
  LTerm: pterm_windows_t;
begin
  New(LTerm);
  FillChar(LTerm^, SizeOf(term_windows_t), 0);

  // 设置函数指针
  with LTerm^.term_t do
  begin
    init := @term_windows_init;
    destroy := @term_windows_destroy;
    clear := @term_windows_clear;
    beep := @term_windows_beep;
    // 标题/图标
    title_get := @term_windows_title_get;
    title_set := @term_windows_title_set;
    icon_set  := @term_windows_icon_set;
    // 大小/光标
    size_get := @term_windows_size_get;
    cursor_get := @term_windows_cursor_get;
    cursor_set := @term_windows_cursor_set;
    // 写入/事件
    write := @term_windows_write;
    event_pull := @term_windows_event_pull;
    // 输入：鼠标启用/禁用（使用 Console 模式）
    mouse_enable := @term_windows_mouse_enable;
    // Attribute support: emit VT SGR when supported
    attr_reset := @term_windows_attr_reset;
    attr_foreground_24bit_set := @term_windows_attr_foreground_24bit_set;
    attr_background_24bit_set := @term_windows_attr_background_24bit_set;
    attr_color_24bit_set := @term_windows_attr_color_24bit_set;
    // Cursor shape
    cursor_shape_set := @term_windows_cursor_shape_set;
    cursor_shape_reset := @term_windows_cursor_shape_reset;
    // Alternate screen
    alternate_screen_enable := @term_windows_alternate_screen_enable;
    // Raw mode toggle
    raw_mode_enable := @term_windows_raw_mode_enable;
  end;

  // 初始化
  if term_windows_init(pterm_t(LTerm)) then
    Result := pterm_t(LTerm)
  else
  begin
    Dispose(LTerm);
    Result := nil;
  end;
end;


function term_windows_title_get(aTerm: pterm_t): string;
begin
  // Windows 控制台不支持读取标题，返回空串
  Result := '';
end;

function term_windows_title_set(aTerm: pterm_t; const aTitle: String): Boolean;
var s: AnsiString;
begin
  // 通过 OSC 2 设置标题（VT 支持下有效）
  s := #27']2;' + AnsiString(aTitle) + #7;
  term_windows_write(aTerm, PChar(s), Length(s));
  Result := True;
end;

function term_windows_icon_set(aTerm: pterm_t; const aIcon: PChar): Boolean;
var s: AnsiString;
begin
  // 通过 OSC 1 设置图标标题（VT 支持下有效）
  s := #27']1;' + AnsiString(aIcon) + #7;
  term_windows_write(aTerm, PChar(s), Length(s));
  Result := True;
end;

function term_windows_alternate_screen_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;
begin
  if aTerm = nil then Exit(False);
  // Use VT: CSI ? 1049 h/l to swap to alternate screen buffer
  if aEnable then
    term_windows_write(aTerm, PChar(#27'[?1049h'), 8)
  else
    term_windows_write(aTerm, PChar(#27'[?1049l'), 8);
  Result := True;
end;

function term_windows_raw_mode_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;
var
  LTerm: pterm_windows_t;
  InMode, OutMode: DWORD;
begin
  Result := False;
  if aTerm = nil then Exit;
  LTerm := pterm_windows_t(aTerm);
  // Start from saved originals to avoid accumulative toggles
  InMode := LTerm^.original_input_mode;
  OutMode := LTerm^.original_output_mode;
  if aEnable then
    // 语义说明：
    // - 启用 raw 模式时，我们显式清除 QUICK_EDIT_MODE（以及 LINE_INPUT/ECHO_INPUT），
    //   以避免在控制台选择文本导致输入冻结；退出 raw 模式时恢复 original 模式位；
    // - 该逻辑基于 ReadConsoleInput 事件流工作，不启用 VIRTUAL_TERMINAL_INPUT，
    //   在 Windows Terminal/ConHost 下均能稳定；

  begin
    // raw-ish: no line input, no echo; keep processed to still get events via ReadConsoleInput
    InMode := (InMode or ENABLE_EXTENDED_FLAGS or ENABLE_WINDOW_INPUT or ENABLE_PROCESSED_INPUT)
              and not (ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_QUICK_EDIT_MODE);
  end
  else
  begin
    // restore originals
    InMode := LTerm^.original_input_mode;
    OutMode := LTerm^.original_output_mode;

  end;
  if not SetConsoleMode(LTerm^.std_in, InMode) then Exit(False);
  if not SetConsoleMode(LTerm^.std_out, OutMode) then Exit(False);
  LTerm^.current_input_mode := InMode;
  LTerm^.current_output_mode := OutMode;
  Result := True;
end;

function term_windows_mouse_enable(aTerm: pterm_t; aEnable: Boolean): Boolean;
var
  LTerm: pterm_windows_t;
  Mode: DWORD;
begin
  Result := False;
  if aTerm = nil then Exit;
  LTerm := pterm_windows_t(aTerm);
  // 基于 current_input_mode 开关 ENABLE_MOUSE_INPUT
  Mode := LTerm^.current_input_mode;
  if aEnable then
    Mode := Mode or ENABLE_MOUSE_INPUT
  else
    Mode := Mode and not ENABLE_MOUSE_INPUT;
  if SetConsoleMode(LTerm^.std_in, Mode) then
  begin
    LTerm^.current_input_mode := Mode;
    Result := True;
  end;
end;

function term_windows_cursor_shape_set(aTerm: pterm_t; aShape: term_cursor_shape_t): Boolean;
var ps: Integer;
begin
  if aTerm = nil then Exit(False);
  // Map to DECSCUSR Ps values
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
  // ESC [ Ps SP q
  term_windows_write(aTerm, PChar(#27'[' + AnsiString(IntToStr(ps)) + ' q'), 0);
  Result := True;
end;

procedure term_windows_cursor_shape_reset(aTerm: pterm_t);
begin
  // Reset to default
  term_windows_cursor_shape_set(aTerm, tcs_default);
end;

// ----------------------------------------------------------------------------
// Attribute emitters (VT SGR)
procedure term_windows_attr_reset(aTerm: pterm_t);
var LTerm: pterm_windows_t;
begin
  LTerm := pterm_windows_t(aTerm);
  if LTerm^.supports_vt then
    term_windows_write(aTerm, PChar(#27'[0m'), 4)
  else
    ; // TODO: optional SetConsoleTextAttribute fallback
end;

procedure term_windows_attr_foreground_24bit_set(aTerm: pterm_t; const aColor: term_color_24bit_t);
var s: AnsiString;
begin
  // ESC [ 38 ; 2 ; R ; G ; B m
  s := #27'[38;2;' + AnsiString(IntToStr(aColor.R)) + ';' + AnsiString(IntToStr(aColor.G)) + ';' + AnsiString(IntToStr(aColor.B)) + 'm';
  term_windows_write(aTerm, PChar(s), Length(s));
end;

procedure term_windows_attr_background_24bit_set(aTerm: pterm_t; const aColor: term_color_24bit_t);
var s: AnsiString;
begin
  // ESC [ 48 ; 2 ; R ; G ; B m
  s := #27'[48;2;' + AnsiString(IntToStr(aColor.R)) + ';' + AnsiString(IntToStr(aColor.G)) + ';' + AnsiString(IntToStr(aColor.B)) + 'm';
  term_windows_write(aTerm, PChar(s), Length(s));
end;

procedure term_windows_attr_color_24bit_set(aTerm: pterm_t; const aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t);
begin
  // Only set colors; style SGR mapping can be added later
  term_windows_attr_foreground_24bit_set(aTerm, aForeground);
  term_windows_attr_background_24bit_set(aTerm, aBackground);
end;


function term_windows_init(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_windows_t;
  LMode: DWORD;
  LBufferInfo: CONSOLE_SCREEN_BUFFER_INFO;
  targetSize: COORD;
  __vtIn: string;
  __nl: string;
begin
  // 初始化潜在未赋值变量，避免编译器告警
  {$PUSH}
  {$WARN 5057 OFF} // quiet: local var may appear uninitialized to analyzer; guarded by API returns

  {$IFDEF MSWINDOWS}
  FillChar(LBufferInfo, SizeOf(LBufferInfo), 0);
  {$ENDIF}
  LMode := 0;
  LTerm := pterm_windows_t(aTerm);
  Result := False;

  try
    // 获取标准句柄
    LTerm^.std_in := GetStdHandle(STD_INPUT_HANDLE);
    LTerm^.std_out := GetStdHandle(STD_OUTPUT_HANDLE);
    LTerm^.std_err := GetStdHandle(STD_ERROR_HANDLE);

    if (LTerm^.std_in = THandle(INVALID_HANDLE_VALUE)) or
       (LTerm^.std_out = THandle(INVALID_HANDLE_VALUE)) then
      Exit;

    // 保存原始模式
    if not GetConsoleMode(LTerm^.std_in, LTerm^.original_input_mode) then Exit;
    if not GetConsoleMode(LTerm^.std_out, LTerm^.original_output_mode) then Exit;
    LTerm^.use_vt_input := False;

    // 保存原始代码页
    LTerm^.original_cp := GetConsoleCP;
    LTerm^.original_output_cp := GetConsoleOutputCP;

    // 检测 VT 支持（失败不致命，降级）
    if GetConsoleMode(LTerm^.std_out, LMode) then
    begin
      LTerm^.supports_vt := SetConsoleMode(LTerm^.std_out, LMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING);
      // 如果设置失败，保持原模式并声明不支持 VT
      if not LTerm^.supports_vt then
        SetConsoleMode(LTerm^.std_out, LMode);
    end
    else
      LTerm^.supports_vt := False;

    // 创建事件队列（失败则初始化失败）
    LTerm^.term_t.event_queue := term_event_queue_create;
    if LTerm^.term_t.event_queue = nil then Exit;

    // 设置终端属性与能力集合（基于是否支持 VT 做能力映射）
    LTerm^.term_t.name := 'Windows Console Terminal';
    LTerm^.term_t.compatibles := [tc_clear, tc_beep];
    // 通用：声明尺寸获取与鼠标事件能力（通过 ReadConsoleInput 支持）
    Include(LTerm^.term_t.compatibles, tc_size);
    Include(LTerm^.term_t.compatibles, tc_mouse);
    if LTerm^.supports_vt then
    begin
      Include(LTerm^.term_t.compatibles, tc_ansi);
      Include(LTerm^.term_t.compatibles, tc_color_16);
      Include(LTerm^.term_t.compatibles, tc_color_256);
      Include(LTerm^.term_t.compatibles, tc_color_24bit);
      Include(LTerm^.term_t.compatibles, tc_cursor);
      Include(LTerm^.term_t.compatibles, tc_cursor_set);
      Include(LTerm^.term_t.compatibles, tc_cursor_shape_set);
      // 这些模式依赖 ANSI，Windows Terminal/VT 模式下可宣称支持
      Include(LTerm^.term_t.compatibles, tc_focus_1004);
      Include(LTerm^.term_t.compatibles, tc_paste_2004);
      Include(LTerm^.term_t.compatibles, tc_sync_update);
      // Do not claim alternate screen support while disabled
      // Include(LTerm^.term_t.compatibles, tc_alternate_screen);
    end
    else
    begin
      // 非 VT 模式，保守声明基本能力（颜色能力交由后续探测/保守为16色）
      Include(LTerm^.term_t.compatibles, tc_color_16);
      Include(LTerm^.term_t.compatibles, tc_cursor);
      Include(LTerm^.term_t.compatibles, tc_cursor_set);
    end;

    // 设置 UTF-8 代码页（失败则忽略，不影响功能）
    if not SetConsoleCP(CP_UTF8) then ;
    if not SetConsoleOutputCP(CP_UTF8) then ;

    // 配置输入模式 - 启用键盘/窗口/鼠标事件；保留 PROCESSED_INPUT 以确保 Ctrl+C 等被处理并产生事件
    // 先设置扩展标志位，再进行实际模式设置（这是官方建议的步骤，用于正确控制 QUICK_EDIT_MODE）
    SetConsoleMode(LTerm^.std_in, ENABLE_EXTENDED_FLAGS);
    // Disable mouse input temporarily to isolate keyboard events
    LTerm^.current_input_mode := ENABLE_WINDOW_INPUT or ENABLE_PROCESSED_INPUT or ENABLE_EXTENDED_FLAGS;
    // 显式关闭行缓冲和回显，并确保关闭 QUICK_EDIT_MODE，避免选择冻结输入
    LTerm^.current_input_mode := LTerm^.current_input_mode and not (ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_QUICK_EDIT_MODE);

    // behind-a-flag: 可选启用 VT 输入（默认关闭）。仅在 supports_vt=True 且环境开关允许时启用；
    // 注意：启用后 ReadConsoleInputW 的键盘事件语义会变化，故默认保持关闭以维持现有事件流。
    if LTerm^.supports_vt and env_lookup('FAFAFA_TERM_WIN_VT_INPUT', __vtIn) then
    begin
      if (CompareText(__vtIn, 'on') = 0) or (__vtIn = '1') then
      begin
        LTerm^.use_vt_input := True;
        LTerm^.current_input_mode := LTerm^.current_input_mode or ENABLE_VIRTUAL_TERMINAL_INPUT;
      end;
    end;

    if not SetConsoleMode(LTerm^.std_in, LTerm^.current_input_mode) then
      SetConsoleMode(LTerm^.std_in, LTerm^.original_input_mode);

    // 配置输出模式（失败降级为原模式）
    // 关闭自动换行（WRAP_AT_EOL_OUTPUT）以避免写满行尾时触发隐式换行导致滚动
    LTerm^.current_output_mode := ENABLE_PROCESSED_OUTPUT; // no WRAP_AT_EOL_OUTPUT
    if LTerm^.supports_vt then
      LTerm^.current_output_mode := LTerm^.current_output_mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;

    // behind-a-flag: 可选启用 DISABLE_NEWLINE_AUTO_RETURN（默认关闭）
    if LTerm^.supports_vt and env_lookup('FAFAFA_TERM_WIN_NEWLINE_MODE', __nl) then
    begin
      if (CompareText(__nl, 'on') = 0) or (__nl = '1') then
        LTerm^.current_output_mode := LTerm^.current_output_mode or DISABLE_NEWLINE_AUTO_RETURN;
    end;

    if not SetConsoleMode(LTerm^.std_out, LTerm^.current_output_mode) then
      SetConsoleMode(LTerm^.std_out, LTerm^.original_output_mode);

    // 解析调试回退开关（仅在 init 阶段解析一次）
    G_WIN_FORCE_WRITEFILE := StrToBoolLoose(GetEnvironmentVariable('FAFAFA_TERM_WIN_FORCE_WRITEFILE'), False);

    // No-Scrollbar 模式：将缓冲区大小锁定为当前窗口大小（进入时保存，退出时还原）
    LTerm^.no_scrollbar_locked := False;
    if GetConsoleScreenBufferInfo(LTerm^.std_out, LBufferInfo) then
    begin
      LTerm^.original_buffer_size := LBufferInfo.dwSize;
      LTerm^.original_window_rect := LBufferInfo.srWindow;
      // 以当前窗口宽高为准设置缓冲区大小
      targetSize.X := LBufferInfo.srWindow.Right - LBufferInfo.srWindow.Left + 1;
      targetSize.Y := LBufferInfo.srWindow.Bottom - LBufferInfo.srWindow.Top + 1;
      if (targetSize.X > 0) and (targetSize.Y > 0) then
      begin
        if SetConsoleScreenBufferSize(LTerm^.std_out, targetSize) then
          LTerm^.no_scrollbar_locked := True;
      end;
    end;

    Result := True;
  {$POP}

  except
    Result := False;
  end;
end;

procedure term_windows_destroy(aTerm: pterm_t);
var
  LTerm: pterm_windows_t;
begin
  if aTerm = nil then Exit;
  LTerm := pterm_windows_t(aTerm);

  try
    // 还原缓冲区/窗口（No-Scrollbar）
    if LTerm^.no_scrollbar_locked then
    begin
      // 先收缩窗口，再恢复缓冲区，避免 WinAPI 限制导致失败
      SetConsoleWindowInfo(LTerm^.std_out, TRUE, LTerm^.original_window_rect);
      SetConsoleScreenBufferSize(LTerm^.std_out, LTerm^.original_buffer_size);
    end;

    // 恢复原始模式
    SetConsoleMode(LTerm^.std_in, LTerm^.original_input_mode);
    SetConsoleMode(LTerm^.std_out, LTerm^.original_output_mode);

    // 恢复代码页
    SetConsoleCP(LTerm^.original_cp);
    SetConsoleOutputCP(LTerm^.original_output_cp);

    // 清理事件队列
    if LTerm^.term_t.event_queue <> nil then
      term_event_queue_destroy(LTerm^.term_t.event_queue);
  except
    // 忽略清理时的错误
  end;

  Dispose(LTerm);
end;

function term_windows_clear(aTerm: pterm_t): Boolean;
var
  LTerm: pterm_windows_t;
  LBufferInfo: CONSOLE_SCREEN_BUFFER_INFO;
  LWritten: DWORD;
  LSize: DWORD;
  LCoord: COORD;
  y: SmallInt;
{$PUSH}
  {$WARN 5057 OFF}
  begin
  {$IFDEF MSWINDOWS}
  FillChar(LBufferInfo, SizeOf(LBufferInfo), 0);
  {$ENDIF}
  LWritten := 0;
  LSize := 0;
  LCoord.X := 0; LCoord.Y := 0;
  y := 0;
  LTerm := pterm_windows_t(aTerm);

  if LTerm^.supports_vt then
  begin
    // 使用 ANSI 序列清屏
    term_windows_write(aTerm, PChar(#27'[2J'#27'[H'), 7);
    Result := True;
  end
  else
  begin
    // 使用 Windows API 清屏
    if GetConsoleScreenBufferInfo(LTerm^.std_out, LBufferInfo) then
    begin
      // Clear only the visible window region to avoid scroll-buffer artifacts
      for y := LBufferInfo.srWindow.Top to LBufferInfo.srWindow.Bottom do
      begin
        LCoord.X := LBufferInfo.srWindow.Left;
        LCoord.Y := y;
        LSize := LBufferInfo.srWindow.Right - LBufferInfo.srWindow.Left + 1;
        FillConsoleOutputCharacterA(LTerm^.std_out, ' ', LSize, LCoord, LWritten);
      end;
      // Reset cursor to top-left of the window
      LCoord.X := LBufferInfo.srWindow.Left;
      LCoord.Y := LBufferInfo.srWindow.Top;
      SetConsoleCursorPosition(LTerm^.std_out, LCoord);
      Result := True;
    end
    else
      Result := False;
  end;
{$POP}
end;

function term_windows_beep(aTerm: pterm_t): Boolean;
begin
  Result := MessageBeep(0);
end;

function term_windows_size_get(aTerm: pterm_t; var aWidth, aHeight: UInt16): Boolean;
var
  LTerm: pterm_windows_t;
  LBufferInfo: CONSOLE_SCREEN_BUFFER_INFO;
begin
  {$PUSH}
  {$WARN 5057 OFF}
  {$IFDEF MSWINDOWS}
  FillChar(LBufferInfo, SizeOf(LBufferInfo), 0);
  {$ENDIF}
  aWidth := 0; aHeight := 0; // default when API fails
  LTerm := pterm_windows_t(aTerm);

  if GetConsoleScreenBufferInfo(LTerm^.std_out, LBufferInfo) then
  begin
    aWidth := LBufferInfo.srWindow.Right - LBufferInfo.srWindow.Left + 1;
    aHeight := LBufferInfo.srWindow.Bottom - LBufferInfo.srWindow.Top + 1;
    Result := True;
  end
  else
    Result := False;
  {$POP}
end;

function term_windows_cursor_get(aTerm: pterm_t; var aX, aY: UInt16): Boolean;
var
  LTerm: pterm_windows_t;
  LBufferInfo: CONSOLE_SCREEN_BUFFER_INFO;
begin
  {$PUSH}
  {$WARN 5057 OFF}
  {$IFDEF MSWINDOWS}
  FillChar(LBufferInfo, SizeOf(LBufferInfo), 0);
  {$ENDIF}
  aX := 0; aY := 0;
  LTerm := pterm_windows_t(aTerm);

  if GetConsoleScreenBufferInfo(LTerm^.std_out, LBufferInfo) then
  begin
    aX := LBufferInfo.dwCursorPosition.X + 1;
    aY := LBufferInfo.dwCursorPosition.Y + 1;
    Result := True;
  end
  else
    Result := False;
  {$POP}
end;

function term_windows_cursor_set(aTerm: pterm_t; aX, aY: UInt16): Boolean;
var
  LTerm: pterm_windows_t;
  LCoord: COORD;
  LInfo: CONSOLE_SCREEN_BUFFER_INFO;
  TargetX, TargetY: Integer;
begin
  {$PUSH}
  {$WARN 5057 OFF}
  LCoord.X := 0; LCoord.Y := 0;
  {$IFDEF MSWINDOWS}
  FillChar(LInfo, SizeOf(LInfo), 0);
  {$ENDIF}
  TargetX := 0; TargetY := 0; // defaults; clamped after querying buffer info

  LTerm := pterm_windows_t(aTerm);

  // Position relative to current window to keep layout stable when user scrolls
  if GetConsoleScreenBufferInfo(LTerm^.std_out, LInfo) then
  begin
    TargetX := LInfo.srWindow.Left + Integer(aX) - 1;
    TargetY := LInfo.srWindow.Top + Integer(aY) - 1;
    // Clamp to window bounds
    if TargetX < LInfo.srWindow.Left then TargetX := LInfo.srWindow.Left;
    if TargetY < LInfo.srWindow.Top then TargetY := LInfo.srWindow.Top;
    if TargetX > LInfo.srWindow.Right then TargetX := LInfo.srWindow.Right;
    if TargetY > LInfo.srWindow.Bottom then TargetY := LInfo.srWindow.Bottom;
    LCoord.X := SmallInt(TargetX);
    LCoord.Y := SmallInt(TargetY);
  end
  else
  begin
    LCoord.X := aX - 1;
    LCoord.Y := aY - 1;
  end;

  Result := SetConsoleCursorPosition(LTerm^.std_out, LCoord);
  {$POP}
end;

procedure term_windows_write(aTerm: pterm_t; const aData: pchar; aLen: Integer);
var
  LTerm: pterm_windows_t;
  LWritten: DWORD;
  tmpAnsi: AnsiString;
  tmpWide: UnicodeString;
begin
  LWritten := 0;

  LTerm := pterm_windows_t(aTerm);
  if (aData = nil) then Exit;
  if aLen <= 0 then aLen := StrLen(aData);

  // 默认路径：假定传入 UTF-8，转换为 UTF-16 并用 WriteConsoleW 输出；
  // 若启用调试回退（G_WIN_FORCE_WRITEFILE），则直接以字节写出（适用于极端环境排障）。
  SetString(tmpAnsi, aData, aLen);

  if G_WIN_FORCE_WRITEFILE then
  begin
    if Length(tmpAnsi) > 0 then
      WriteFile(LTerm^.std_out, PAnsiChar(tmpAnsi), Length(tmpAnsi), LWritten, nil);
  end
  else
  begin
    {$IFDEF FPC}
    tmpWide := UTF8Decode(tmpAnsi);
    {$ELSE}
    tmpWide := UTF8Decode(tmpAnsi);
    {$ENDIF}
    if Length(tmpWide) > 0 then
      WriteConsoleW(LTerm^.std_out, PWideChar(tmpWide), Length(tmpWide), LWritten, nil);
  end;
end;

procedure term_windows_write_wide(aTerm: pterm_t; const aData: pwidechar; aLen: Integer);
var
  LTerm: pterm_windows_t;
  LWritten: DWORD;
begin
  LWritten := 0;

  LTerm := pterm_windows_t(aTerm);
  if (aData = nil) or (aLen <= 0) then Exit;
  // 直接使用宽字符输出，VT 模式下同样可写入 ESC 等控制字符
  WriteConsoleW(LTerm^.std_out, aData, aLen, LWritten, nil);
end;

function term_windows_event_pull(aTerm: pterm_t; aTimeout: UInt64): Boolean;
var
  LTerm: pterm_windows_t;
  LInputRecord: INPUT_RECORD;
  LEventsRead: DWORD;
  LEventsAvailable: DWORD;
  LEvent: term_event_t;
  LWaitResult: DWORD;
  LTimeoutMs: DWORD;

begin
  {$PUSH}
  {$WARN 5057 OFF}
  {$IFDEF MSWINDOWS}
  FillChar(LInputRecord, SizeOf(LInputRecord), 0);
  {$ENDIF}
  LEventsRead := 0;
  LEventsAvailable := 0;
  FillByte(LEvent, SizeOf(LEvent), 0); // ensure clean record before conversion
  LWaitResult := 0;
  LTimeoutMs := 0;
  LTerm := pterm_windows_t(aTerm);
  Result := False;

  // 转换超时时间
  if aTimeout = High(UInt64) then
    LTimeoutMs := INFINITE
  else
    LTimeoutMs := aTimeout;

  // 等待输入事件
  LWaitResult := WaitForSingleObject(LTerm^.std_in, LTimeoutMs);

  if LWaitResult = WAIT_OBJECT_0 then
  begin
    // 检查是否有事件可用
    if GetNumberOfConsoleInputEvents(LTerm^.std_in, LEventsAvailable) and (LEventsAvailable > 0) then
    begin
      // 读取输入事件
      if ReadConsoleInputW(LTerm^.std_in, LInputRecord, 1, LEventsRead) and (LEventsRead > 0) then
      begin
        // 转换事件类型
        case LInputRecord.EventType of
          KEY_EVENT:
            if LInputRecord.KeyEvent.bKeyDown then // 只处理按键按下事件
            begin
              LEvent := term_windows_convert_key_event(LInputRecord.KeyEvent);
              term_event_queue_push(LTerm^.term_t.event_queue, LEvent);
              Result := True;
            end;

          MOUSE_EVENT:
            begin
              LEvent := term_windows_convert_mouse_event(LTerm, LInputRecord.MouseEvent);
              term_event_queue_push(LTerm^.term_t.event_queue, LEvent);
              Result := True;
            end;

          WINDOW_BUFFER_SIZE_EVENT:
            begin
              LEvent := term_windows_convert_size_event(LInputRecord.WindowBufferSizeEvent);
              term_event_queue_push(LTerm^.term_t.event_queue, LEvent);
              Result := True;
            end;

          FOCUS_EVENT:
            begin
              LEvent := term_windows_convert_focus_event(LInputRecord.FocusEvent);
              term_event_queue_push(LTerm^.term_t.event_queue, LEvent);
              Result := True;
            end;
        end;
      end;
    end;
  end;
  {$POP}
end;

{** Windows 事件转换函数 *}

function vk_to_term_key(vk: Word): term_key_t;
begin
  // 默认未知键
  Result := KEY_UNKOWN;
  case vk of
    $1B: Result := KEY_ESC; // VK_ESCAPE

    $70..$7B: // VK_F1..VK_F12
      Result := term_key_t(KEY_F1 + (vk - $70));

    $C0: Result := KEY_BACKTICK;  // VK_OEM_3 `~

    $30: Result := KEY_0;         // '0'
    $31: Result := KEY_1; $32: Result := KEY_2; $33: Result := KEY_3; $34: Result := KEY_4;
    $35: Result := KEY_5; $36: Result := KEY_6; $37: Result := KEY_7; $38: Result := KEY_8; $39: Result := KEY_9;

    $BD: Result := KEY_MINUS;     // VK_OEM_MINUS -_
    $BB: Result := KEY_EQUAL;     // VK_OEM_PLUS  =+
    $08: Result := KEY_BACKSPACE; // VK_BACK
    $09: Result := KEY_TAB;       // VK_TAB

    $51: Result := KEY_Q; $57: Result := KEY_W; $45: Result := KEY_E; $52: Result := KEY_R; $54: Result := KEY_T;
    $59: Result := KEY_Y; $55: Result := KEY_U; $49: Result := KEY_I; $4F: Result := KEY_O; $50: Result := KEY_P;
    $DB: Result := KEY_LEFT_BRACKET;   // VK_OEM_4 [
    $DD: Result := KEY_RIGHT_BRACKET;  // VK_OEM_6 ]
    $DC: Result := KEY_BACKSLASH;      // VK_OEM_5 \

    $14: Result := KEY_CAPS_LOCK; // VK_CAPITAL

    $41: Result := KEY_A; $53: Result := KEY_S; $44: Result := KEY_D; $46: Result := KEY_F; $47: Result := KEY_G;
    $48: Result := KEY_H; $4A: Result := KEY_J; $4B: Result := KEY_K; $4C: Result := KEY_L;
    $BA: Result := KEY_SEMICOLON; // VK_OEM_1 ;:
    $DE: Result := KEY_APOSTROPHE; // VK_OEM_7 '"
    $0D: Result := KEY_ENTER;     // VK_RETURN

    $A0: Result := KEY_LSHIFT;    // VK_LSHIFT
    $A1: Result := KEY_RSHIFT;    // VK_RSHIFT
    $5A: Result := KEY_Z; $58: Result := KEY_X; $43: Result := KEY_C; $56: Result := KEY_V; $42: Result := KEY_B;
    $4E: Result := KEY_N; $4D: Result := KEY_M;
    $BC: Result := KEY_COMMA;     // VK_OEM_COMMA ,<
    $BE: Result := KEY_PERIOD;    // VK_OEM_PERIOD .>
    $BF: Result := KEY_SLASH;     // VK_OEM_2 /?

    $A2: Result := KEY_LCtrl;     // VK_LCONTROL
    $A3: Result := KEY_RCtrl;     // VK_RCONTROL
    $5B: Result := KEY_LWin;      // VK_LWIN
    $5C: Result := KEY_RWin;      // VK_RWIN
    $A4: Result := KEY_LAlt;      // VK_LMENU
    $A5: Result := KEY_RAlt;      // VK_RMENU
    $20: Result := KEY_SPACE;     // VK_SPACE
    $5D: Result := KEY_Menu;      // VK_APPS

    $2C: Result := KEY_PRINT_SCREEN; // VK_SNAPSHOT
    $91: Result := KEY_SCROLL_LOCK;  // VK_SCROLL
    $13: Result := KEY_PAUSE;        // VK_PAUSE

    $2D: Result := KEY_INSERT;    // VK_INSERT
    $24: Result := KEY_HOME;      // VK_HOME
    $21: Result := KEY_PAGE_UP;   // VK_PRIOR
    $2E: Result := KEY_DELETE;    // VK_DELETE
    $23: Result := KEY_END;       // VK_END
    $22: Result := KEY_PAGE_DOWN; // VK_NEXT

    $26: Result := KEY_UP;    // VK_UP
    $25: Result := KEY_LEFT;  // VK_LEFT
    $28: Result := KEY_DOWN;  // VK_DOWN
    $27: Result := KEY_RIGHT; // VK_RIGHT

    $90: Result := KEY_NUM_LOCK;     // VK_NUMLOCK
    $6F: Result := KEY_NUM_DIVIDE;   // VK_DIVIDE
    $6A: Result := KEY_NUM_MULTIPLY; // VK_MULTIPLY
    $6D: Result := KEY_NUM_SUBTRACT; // VK_SUBTRACT
    $6B: Result := KEY_NUM_PLUS;     // VK_ADD
    $6E: Result := KEY_NUM_DECIMAL;  // VK_DECIMAL

    $67: Result := KEY_NUM_7; $68: Result := KEY_NUM_8; $69: Result := KEY_NUM_9;
    $64: Result := KEY_NUM_4; $65: Result := KEY_NUM_5; $66: Result := KEY_NUM_6;
    $61: Result := KEY_NUM_1; $62: Result := KEY_NUM_2; $63: Result := KEY_NUM_3;
    $60: Result := KEY_NUM_0;
  end;
end;

function term_windows_convert_key_event(const aKeyEvent: KEY_EVENT_RECORD): term_event_t;
begin
  // 明确初始化整个结构，避免编译器关于未初始化 Result 的提示
  FillChar(Result, SizeOf(Result), 0);
  Result.kind := tek_key;
  Result.key.key := vk_to_term_key(aKeyEvent.wVirtualKeyCode);

  // 设置字符: 先取 UnicodeChar, 若为 0 再回退到 AsciiChar（因为我们使用 ReadConsoleInputA）
  if aKeyEvent.UnicodeChar <> #0 then
    Result.key.char := term_char(aKeyEvent.UnicodeChar)
  else if aKeyEvent.AsciiChar <> #0 then
    Result.key.char := term_char(aKeyEvent.AsciiChar)
  else
    Result.key.char := term_char(#0);

  // 设置修饰键
  Result.key.shift := Byte((aKeyEvent.dwControlKeyState and SHIFT_PRESSED) <> 0);
  Result.key.ctrl := Byte((aKeyEvent.dwControlKeyState and (LEFT_CTRL_PRESSED or RIGHT_CTRL_PRESSED)) <> 0);
  Result.key.alt := Byte((aKeyEvent.dwControlKeyState and (LEFT_ALT_PRESSED or RIGHT_ALT_PRESSED)) <> 0);
end;

function term_windows_convert_mouse_event(aTerm: pterm_windows_t; const aMouseEvent: MOUSE_EVENT_RECORD): term_event_t;
var
  wheelDelta: SmallInt;
  pressed, released: DWORD;
  btn: term_mouse_button_t;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.kind := tek_mouse;
  Result.mouse.x := aMouseEvent.dwMousePosition.X + 1; // 转换为 1 基索引
  Result.mouse.y := aMouseEvent.dwMousePosition.Y + 1;

  // 鼠标滚轮事件优先处理（Console: delta 位于 dwButtonState 高字）
  if (aMouseEvent.dwEventFlags and MOUSE_WHEELED) <> 0 then
  begin
    wheelDelta := SmallInt((aMouseEvent.dwButtonState shr 16) and $FFFF);
    if wheelDelta > 0 then
      Result.mouse.button := Ord(tmb_wheel_up)
    else
      Result.mouse.button := Ord(tmb_wheel_down);
    Result.mouse.state := Ord(tms_press);
  end
  else if (aMouseEvent.dwEventFlags and MOUSE_HWHEELED) <> 0 then
  begin
    wheelDelta := SmallInt((aMouseEvent.dwButtonState shr 16) and $FFFF);
    if wheelDelta > 0 then
      Result.mouse.button := Ord(tmb_wheel_right)
    else
      Result.mouse.button := Ord(tmb_wheel_left);
    Result.mouse.state := Ord(tms_press);
  end
  else
  begin
    // 基于前一状态，识别按下/释放/移动
    pressed := aMouseEvent.dwButtonState and not aTerm^.last_button_state;
    released := aTerm^.last_button_state and not aMouseEvent.dwButtonState;

    // 默认无按钮；先按当前状态推断基础按钮
    btn := tmb_none;
    if (aMouseEvent.dwButtonState and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then btn := tmb_left
    else if (aMouseEvent.dwButtonState and RIGHTMOST_BUTTON_PRESSED) <> 0 then btn := tmb_right
    else if (aMouseEvent.dwButtonState and FROM_LEFT_2ND_BUTTON_PRESSED) <> 0 then btn := tmb_middle
    else if (aMouseEvent.dwButtonState and FROM_LEFT_3RD_BUTTON_PRESSED) <> 0 then btn := tmb_backward
    else if (aMouseEvent.dwButtonState and FROM_LEFT_4TH_BUTTON_PRESSED) <> 0 then btn := tmb_forward;

    if (aMouseEvent.dwEventFlags and MOUSE_MOVED) <> 0 then
    begin
      Result.mouse.button := Ord(btn);
      Result.mouse.state := Ord(tms_moved);
    end
    else if (pressed <> 0) then
    begin
      // 新增按下：从 pressed 边沿判定具体按钮
      if (pressed and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then btn := tmb_left
      else if (pressed and RIGHTMOST_BUTTON_PRESSED) <> 0 then btn := tmb_right
      else if (pressed and FROM_LEFT_2ND_BUTTON_PRESSED) <> 0 then btn := tmb_middle
      else if (pressed and FROM_LEFT_3RD_BUTTON_PRESSED) <> 0 then btn := tmb_backward
      else if (pressed and FROM_LEFT_4TH_BUTTON_PRESSED) <> 0 then btn := tmb_forward;
      Result.mouse.button := Ord(btn);
      Result.mouse.state := Ord(tms_press);
    end
    else if (released <> 0) then
    begin
      // 新增释放：从 released 边沿判定具体按钮
      if (released and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then btn := tmb_left
      else if (released and RIGHTMOST_BUTTON_PRESSED) <> 0 then btn := tmb_right
      else if (released and FROM_LEFT_2ND_BUTTON_PRESSED) <> 0 then btn := tmb_middle
      else if (released and FROM_LEFT_3RD_BUTTON_PRESSED) <> 0 then btn := tmb_backward
      else if (released and FROM_LEFT_4TH_BUTTON_PRESSED) <> 0 then btn := tmb_forward;
      Result.mouse.button := Ord(btn);
      Result.mouse.state := Ord(tms_release);
    end
    else
    begin
      // 无移动且无边沿，视为按压保持（兼容旧行为）
      Result.mouse.button := Ord(btn);
      Result.mouse.state := Ord(tms_press);
    end;

    // 记忆状态
    aTerm^.last_button_state := aMouseEvent.dwButtonState;
  end;

  // 设置修饰键
  Result.mouse.shift := Byte((aMouseEvent.dwControlKeyState and SHIFT_PRESSED) <> 0);
  Result.mouse.ctrl := Byte((aMouseEvent.dwControlKeyState and (LEFT_CTRL_PRESSED or RIGHT_CTRL_PRESSED)) <> 0);
  Result.mouse.alt := Byte((aMouseEvent.dwControlKeyState and (LEFT_ALT_PRESSED or RIGHT_ALT_PRESSED)) <> 0);
end;

function term_windows_convert_size_event(const aSizeEvent: WINDOW_BUFFER_SIZE_RECORD): term_event_t;
begin
  Result.kind := tek_sizeChange;
  Result.size.width := aSizeEvent.dwSize.X;
  Result.size.height := aSizeEvent.dwSize.Y;
end;

function term_windows_convert_focus_event(const aFocusEvent: FOCUS_EVENT_RECORD): term_event_t;
begin
  Result.kind := tek_focus;
  Result.focus.focus := aFocusEvent.bSetFocus;
end;

end.

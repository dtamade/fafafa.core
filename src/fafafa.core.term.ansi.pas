unit fafafa.core.term.ansi;

{**
 * ANSI 转义序列处理单元
 * 专门处理所有 ANSI 转义序列的定义、构建、解析和验证
 * 为终端模块提供统一的 ANSI 序列支持
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

{** ANSI 转义序列常量定义 *}

const
  // 基础控制字符
  ESC = #27;                    // 转义字符
  CSI = ESC + '[';              // 控制序列引导符
  OSC = ESC + ']';              // 操作系统命令序列
  BEL = #7;                     // 响铃
  BS = #8;                      // 退格
  HT = #9;                      // 水平制表符
  LF = #10;                     // 换行
  CR = #13;                     // 回车

  // 光标控制序列
  ANSI_CURSOR_UP = CSI + 'A';                    // 光标上移
  ANSI_CURSOR_DOWN = CSI + 'B';                  // 光标下移
  ANSI_CURSOR_FORWARD = CSI + 'C';               // 光标右移
  ANSI_CURSOR_BACKWARD = CSI + 'D';              // 光标左移
  ANSI_CURSOR_NEXT_LINE = CSI + 'E';             // 光标移到下一行开头
  ANSI_CURSOR_PREV_LINE = CSI + 'F';             // 光标移到上一行开头
  ANSI_CURSOR_COLUMN = CSI + 'G';                // 光标移到指定列
  ANSI_CURSOR_POSITION = CSI + 'H';              // 光标移到指定位置
  ANSI_CURSOR_SAVE = CSI + 's';                  // 保存光标位置
  ANSI_CURSOR_RESTORE = CSI + 'u';               // 恢复光标位置
  ANSI_CURSOR_SAVE_DEC = ESC + '7';              // DEC 保存光标
  ANSI_CURSOR_RESTORE_DEC = ESC + '8';           // DEC 恢复光标
  ANSI_CURSOR_HIDE = CSI + '?25l';               // 隐藏光标
  ANSI_CURSOR_SHOW = CSI + '?25h';               // 显示光标

  // 屏幕控制序列
  ANSI_CLEAR_SCREEN = CSI + '2J';                // 清除整个屏幕
  ANSI_CLEAR_SCREEN_TO_END = CSI + '0J';         // 清除从光标到屏幕末尾
  ANSI_CLEAR_SCREEN_TO_BEGIN = CSI + '1J';       // 清除从屏幕开头到光标
  ANSI_CLEAR_LINE = CSI + '2K';                  // 清除整行
  ANSI_CLEAR_LINE_TO_END = CSI + '0K';           // 清除从光标到行末
  ANSI_CLEAR_LINE_TO_BEGIN = CSI + '1K';         // 清除从行首到光标
  ANSI_SCROLL_UP_ONE = CSI + 'S';               // 向上滚动一行
  ANSI_SCROLL_DOWN_ONE = CSI + 'T';             // 向下滚动一行

  // 文本样式序列
  ANSI_RESET = CSI + '0m';                       // 重置所有样式
  ANSI_BOLD = CSI + '1m';                        // 粗体
  ANSI_DIM = CSI + '2m';                         // 暗淡
  ANSI_ITALIC = CSI + '3m';                      // 斜体
  ANSI_UNDERLINE = CSI + '4m';                   // 下划线
  ANSI_BLINK = CSI + '5m';                       // 闪烁
  ANSI_REVERSE = CSI + '7m';                     // 反转
  ANSI_STRIKETHROUGH = CSI + '9m';               // 删除线
  ANSI_BOLD_OFF = CSI + '22m';                   // 关闭粗体
  ANSI_ITALIC_OFF = CSI + '23m';                 // 关闭斜体
  ANSI_UNDERLINE_OFF = CSI + '24m';              // 关闭下划线
  ANSI_BLINK_OFF = CSI + '25m';                  // 关闭闪烁
  ANSI_REVERSE_OFF = CSI + '27m';                // 关闭反转
  ANSI_STRIKETHROUGH_OFF = CSI + '29m';          // 关闭删除线

  // 16 色前景色序列
  ANSI_FG_BLACK = CSI + '30m';
  ANSI_FG_RED = CSI + '31m';
  ANSI_FG_GREEN = CSI + '32m';
  ANSI_FG_YELLOW = CSI + '33m';
  ANSI_FG_BLUE = CSI + '34m';
  ANSI_FG_MAGENTA = CSI + '35m';
  ANSI_FG_CYAN = CSI + '36m';
  ANSI_FG_WHITE = CSI + '37m';
  ANSI_FG_DEFAULT = CSI + '39m';

  // 16 色高亮前景色序列
  ANSI_FG_BRIGHT_BLACK = CSI + '90m';
  ANSI_FG_BRIGHT_RED = CSI + '91m';
  ANSI_FG_BRIGHT_GREEN = CSI + '92m';
  ANSI_FG_BRIGHT_YELLOW = CSI + '93m';
  ANSI_FG_BRIGHT_BLUE = CSI + '94m';
  ANSI_FG_BRIGHT_MAGENTA = CSI + '95m';
  ANSI_FG_BRIGHT_CYAN = CSI + '96m';
  ANSI_FG_BRIGHT_WHITE = CSI + '97m';

  // 16 色背景色序列
  ANSI_BG_BLACK = CSI + '40m';
  ANSI_BG_RED = CSI + '41m';
  ANSI_BG_GREEN = CSI + '42m';
  ANSI_BG_YELLOW = CSI + '43m';
  ANSI_BG_BLUE = CSI + '44m';
  ANSI_BG_MAGENTA = CSI + '45m';
  ANSI_BG_CYAN = CSI + '46m';
  ANSI_BG_WHITE = CSI + '47m';
  ANSI_BG_DEFAULT = CSI + '49m';

  // 16 色高亮背景色序列
  ANSI_BG_BRIGHT_BLACK = CSI + '100m';
  ANSI_BG_BRIGHT_RED = CSI + '101m';
  ANSI_BG_BRIGHT_GREEN = CSI + '102m';
  ANSI_BG_BRIGHT_YELLOW = CSI + '103m';
  ANSI_BG_BRIGHT_BLUE = CSI + '104m';
  ANSI_BG_BRIGHT_MAGENTA = CSI + '105m';
  ANSI_BG_BRIGHT_CYAN = CSI + '106m';
  ANSI_BG_BRIGHT_WHITE = CSI + '107m';

  // 鼠标和焦点事件序列
  ANSI_MOUSE_ENABLE = CSI + '?1000h';            // 启用鼠标跟踪
  ANSI_MOUSE_DISABLE = CSI + '?1000l';           // 禁用鼠标跟踪
  ANSI_MOUSE_BUTTON_ENABLE = CSI + '?1002h';     // 启用鼠标按钮事件
  ANSI_MOUSE_BUTTON_DISABLE = CSI + '?1002l';    // 禁用鼠标按钮事件
  ANSI_MOUSE_ANY_ENABLE = CSI + '?1003h';        // 启用任意鼠标事件
  ANSI_MOUSE_ANY_DISABLE = CSI + '?1003l';       // 禁用任意鼠标事件
  ANSI_MOUSE_SGR_ENABLE = CSI + '?1006h';        // 启用 SGR 鼠标模式
  ANSI_MOUSE_SGR_DISABLE = CSI + '?1006l';       // 禁用 SGR 鼠标模式
  ANSI_FOCUS_ENABLE = CSI + '?1004h';            // 启用焦点事件
  ANSI_FOCUS_DISABLE = CSI + '?1004l';           // 禁用焦点事件

  // 括号粘贴模式
  ANSI_BRACKETED_PASTE_ENABLE = CSI + '?2004h';  // 启用括号粘贴
  ANSI_BRACKETED_PASTE_DISABLE = CSI + '?2004l'; // 禁用括号粘贴


  // 同步输出（Synchronized Updates）— 减少闪烁（终端支持时）
  ANSI_SYNC_UPDATE_ENABLE  = CSI + '?2026h';
  ANSI_SYNC_UPDATE_DISABLE = CSI + '?2026l';

  // 查询序列
  ANSI_QUERY_CURSOR_POSITION = CSI + '6n';       // 查询光标位置
  ANSI_QUERY_DEVICE_ATTRIBUTES = CSI + '0c';     // 查询设备属性

{** ANSI 序列构建函数 *}

// 光标控制序列构建
function ansi_cursor_move_up(aLines: Integer): string;
function ansi_cursor_move_down(aLines: Integer): string;
function ansi_cursor_move_forward(aCols: Integer): string;
function ansi_cursor_move_backward(aCols: Integer): string;
function ansi_cursor_move_to_column(aCol: Integer): string;
function ansi_cursor_move_to_position(aRow, aCol: Integer): string;

// 屏幕控制序列构建
function ansi_scroll_up(aLines: Integer): string;
function ansi_scroll_down(aLines: Integer): string;

// 颜色序列构建
function ansi_fg_color_256(aColor: Byte): string;
function ansi_bg_color_256(aColor: Byte): string;
function ansi_fg_color_rgb(aRed, aGreen, aBlue: Byte): string;
function ansi_bg_color_rgb(aRed, aGreen, aBlue: Byte): string;
function ansi_color_reset: string;

// 文本样式序列构建
function ansi_style_bold(aEnable: Boolean): string;
function ansi_style_italic(aEnable: Boolean): string;
function ansi_style_underline(aEnable: Boolean): string;
function ansi_style_blink(aEnable: Boolean): string;
function ansi_style_reverse(aEnable: Boolean): string;
function ansi_style_strikethrough(aEnable: Boolean): string;

{** ANSI 序列解析和验证函数 *}

// 序列解析类型
type
  ansi_sequence_type_t = (
    ast_unknown,
    ast_cursor_control,
    ast_screen_control,
    ast_color,
    ast_style,
    ast_mouse,
    ast_query
  );

  ansi_sequence_info_t = record
    sequence_type: ansi_sequence_type_t;
    command: Char;
    parameters: array[0..15] of Integer;
    parameter_count: Integer;
    is_valid: Boolean;
  end;

// 序列解析函数
function ansi_parse_sequence(const aSequence: string): ansi_sequence_info_t;
function ansi_is_valid_sequence(const aSequence: string): Boolean;
type
  TIntegerArray = array of Integer;

function ansi_extract_parameters(const aSequence: string): TIntegerArray;

// 序列检测函数
function ansi_is_escape_sequence(const aText: string; aPos: Integer): Boolean;
function ansi_find_sequence_end(const aText: string; aStartPos: Integer): Integer;
function ansi_strip_sequences(const aText: string): string;

implementation

{** 光标控制序列构建函数 *}

function ansi_cursor_move_up(aLines: Integer): string;
begin
  if aLines <= 0 then
    Result := ''
  else if aLines = 1 then
    Result := ANSI_CURSOR_UP
  else
    Result := CSI + IntToStr(aLines) + 'A';
end;

function ansi_cursor_move_down(aLines: Integer): string;
begin
  if aLines <= 0 then
    Result := ''
  else if aLines = 1 then
    Result := ANSI_CURSOR_DOWN
  else
    Result := CSI + IntToStr(aLines) + 'B';
end;

function ansi_cursor_move_forward(aCols: Integer): string;
begin
  if aCols <= 0 then
    Result := ''
  else if aCols = 1 then
    Result := ANSI_CURSOR_FORWARD
  else
    Result := CSI + IntToStr(aCols) + 'C';
end;

function ansi_cursor_move_backward(aCols: Integer): string;
begin
  if aCols <= 0 then
    Result := ''
  else if aCols = 1 then
    Result := ANSI_CURSOR_BACKWARD
  else
    Result := CSI + IntToStr(aCols) + 'D';
end;

function ansi_cursor_move_to_column(aCol: Integer): string;
begin
  if aCol <= 0 then
    Result := ''
  else
    Result := CSI + IntToStr(aCol) + 'G';
end;

function ansi_cursor_move_to_position(aRow, aCol: Integer): string;
begin
  if (aRow <= 0) or (aCol <= 0) then
    Result := ''
  else
    Result := CSI + IntToStr(aRow) + ';' + IntToStr(aCol) + 'H';
end;

{** 屏幕控制序列构建函数 *}

function ansi_scroll_up(aLines: Integer): string;
begin
  if aLines <= 0 then
    Result := ''
  else if aLines = 1 then
    Result := CSI + 'S'
  else
    Result := CSI + IntToStr(aLines) + 'S';
end;

function ansi_scroll_down(aLines: Integer): string;
begin
  if aLines <= 0 then
    Result := ''
  else if aLines = 1 then
    Result := CSI + 'T'
  else
    Result := CSI + IntToStr(aLines) + 'T';
end;

{** 颜色序列构建函数 *}

function ansi_fg_color_256(aColor: Byte): string;
begin
  Result := CSI + '38;5;' + IntToStr(aColor) + 'm';
end;

function ansi_bg_color_256(aColor: Byte): string;
begin
  Result := CSI + '48;5;' + IntToStr(aColor) + 'm';
end;

function ansi_fg_color_rgb(aRed, aGreen, aBlue: Byte): string;
begin
  Result := CSI + '38;2;' + IntToStr(aRed) + ';' + IntToStr(aGreen) + ';' + IntToStr(aBlue) + 'm';
end;

function ansi_bg_color_rgb(aRed, aGreen, aBlue: Byte): string;
begin
  Result := CSI + '48;2;' + IntToStr(aRed) + ';' + IntToStr(aGreen) + ';' + IntToStr(aBlue) + 'm';
end;

function ansi_color_reset: string;
begin
  Result := ANSI_RESET;
end;

{** 文本样式序列构建函数 *}

function ansi_style_bold(aEnable: Boolean): string;
begin
  if aEnable then
    Result := ANSI_BOLD
  else
    Result := ANSI_BOLD_OFF;
end;

function ansi_style_italic(aEnable: Boolean): string;
begin
  if aEnable then
    Result := ANSI_ITALIC
  else
    Result := ANSI_ITALIC_OFF;
end;

function ansi_style_underline(aEnable: Boolean): string;
begin
  if aEnable then
    Result := ANSI_UNDERLINE
  else
    Result := ANSI_UNDERLINE_OFF;
end;

function ansi_style_blink(aEnable: Boolean): string;
begin
  if aEnable then
    Result := ANSI_BLINK
  else
    Result := ANSI_BLINK_OFF;
end;

function ansi_style_reverse(aEnable: Boolean): string;
begin
  if aEnable then
    Result := ANSI_REVERSE
  else
    Result := ANSI_REVERSE_OFF;
end;

function ansi_style_strikethrough(aEnable: Boolean): string;
begin
  if aEnable then
    Result := ANSI_STRIKETHROUGH
  else
    Result := ANSI_STRIKETHROUGH_OFF;
end;

{** ANSI 序列解析和验证函数 *}

function ansi_parse_sequence(const aSequence: string): ansi_sequence_info_t;
var
  i, ParamStart, ParamValue: Integer;
  InParam: Boolean;
begin
  // 初始化结果（确保 Result 总是有定义，避免编译器 Hint）
  FillChar(Result, SizeOf(ansi_sequence_info_t), 0);
  Result.sequence_type := ast_unknown;
  Result.is_valid := False;

  // 检查最小长度
  if Length(aSequence) < 2 then
  begin
    Exit;
  end;

  // 检查是否以 ESC[ 开头
  if not ((aSequence[1] = ESC) and (Length(aSequence) > 2) and (aSequence[2] = '[')) then
    Exit;

  // 解析参数
  i := 3;
  InParam := False;
  ParamStart := i;

  while i <= Length(aSequence) do
  begin
    case aSequence[i] of
      '0'..'9':
        begin
          if not InParam then
          begin
            InParam := True;
            ParamStart := i;
          end;
        end;
      ';':
        begin
          if InParam then
          begin
            ParamValue := StrToIntDef(Copy(aSequence, ParamStart, i - ParamStart), 0);
            if Result.parameter_count < Length(Result.parameters) then
            begin
              Result.parameters[Result.parameter_count] := ParamValue;
              Inc(Result.parameter_count);
            end;
            InParam := False;
          end;
        end;
      'A'..'Z', 'a'..'z':
        begin
          // 找到命令字符
          if InParam then
          begin
            ParamValue := StrToIntDef(Copy(aSequence, ParamStart, i - ParamStart), 0);
            if Result.parameter_count < Length(Result.parameters) then
            begin
              Result.parameters[Result.parameter_count] := ParamValue;
              Inc(Result.parameter_count);
            end;
          end;

          Result.command := aSequence[i];
          Result.is_valid := True;

          // 确定序列类型
          case aSequence[i] of
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 's', 'u':
              Result.sequence_type := ast_cursor_control;
            'J', 'K', 'S', 'T':
              Result.sequence_type := ast_screen_control;
            'm':
              Result.sequence_type := ast_color;
            'n':
              Result.sequence_type := ast_query;
          end;

          Break;
        end;
    end;
    Inc(i);
  end;
end;

function ansi_is_valid_sequence(const aSequence: string): Boolean;
var
  Info: ansi_sequence_info_t;
begin
  Info := ansi_parse_sequence(aSequence);
  Result := Info.is_valid;
end;

function ansi_extract_parameters(const aSequence: string): TIntegerArray;
var
  Info: ansi_sequence_info_t;
  i: Integer;
begin
  Info := ansi_parse_sequence(aSequence);

  // 初始化结果数组
  Result := nil;
  SetLength(Result, 0);

  if Info.parameter_count > 0 then
  begin
    SetLength(Result, Info.parameter_count);
    for i := 0 to Info.parameter_count - 1 do
      Result[i] := Info.parameters[i];
  end;
end;

{** 序列检测和处理函数 *}

function ansi_is_escape_sequence(const aText: string; aPos: Integer): Boolean;
begin
  Result := (aPos <= Length(aText)) and (aText[aPos] = ESC);
end;

function ansi_find_sequence_end(const aText: string; aStartPos: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;

  // 检查是否以 ESC 开头
  if (aStartPos > Length(aText)) or (aText[aStartPos] <> ESC) then
    Exit;

  // 简单的 ESC 序列（如 ESC 7, ESC 8）
  if (aStartPos + 1 <= Length(aText)) and (aText[aStartPos + 1] in ['7', '8']) then
  begin
    Result := aStartPos + 1;
    Exit;
  end;

  // CSI 序列（ESC [）
  if (aStartPos + 1 <= Length(aText)) and (aText[aStartPos + 1] = '[') then
  begin
    i := aStartPos + 2;
    while i <= Length(aText) do
    begin
      case aText[i] of
        '0'..'9', ';', '?':
          Inc(i);
        'A'..'Z', 'a'..'z':
          begin
            Result := i;
            Exit;
          end;
        else
          Exit; // 无效序列
      end;
    end;
  end

  // OSC 序列（ESC ]）
  else if (aStartPos + 1 <= Length(aText)) and (aText[aStartPos + 1] = ']') then
  begin
    i := aStartPos + 2;
    while i <= Length(aText) do
    begin
      if aText[i] = BEL then
      begin
        Result := i;
        Exit;
      end
      else if (i + 1 <= Length(aText)) and (aText[i] = ESC) and (aText[i + 1] = '\') then
      begin
        Result := i + 1;
        Exit;
      end;
      Inc(i);
    end;
  end;
end;

function ansi_strip_sequences(const aText: string): string;
var
  i, SeqEnd: Integer;
begin
  Result := '';
  i := 1;

  while i <= Length(aText) do
  begin
    if ansi_is_escape_sequence(aText, i) then
    begin
      SeqEnd := ansi_find_sequence_end(aText, i);
      if SeqEnd > 0 then
      begin
        // 跳过整个序列
        i := SeqEnd + 1;
        Continue;
      end;
    end;

    // 添加普通字符
    Result := Result + aText[i];
    Inc(i);
  end;
end;

end.

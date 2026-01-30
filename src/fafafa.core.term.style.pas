unit fafafa.core.term.style;

{**
 * Terminal Text Style Management Unit
 * 终端文本样式管理单元
 * 
 * 提供高级的文本格式化功能，基于 ANSI 转义序列
 * 支持样式组合、颜色管理和便捷的文本格式化
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.term.ansi;

{** 辅助函数声明 *}

function IntToStr(aValue: Integer): string;

{** 文本样式类型定义 *}

type
  // 基本样式枚举
  term_style_t = (
    ts_normal,        // 正常
    ts_bold,          // 粗体
    ts_dim,           // 暗淡
    ts_italic,        // 斜体
    ts_underline,     // 下划线
    ts_blink,         // 闪烁
    ts_reverse,       // 反转
    ts_strikethrough  // 删除线
  );

  // 样式集合
  term_style_set_t = set of term_style_t;

  // 颜色类型
  term_color_type_t = (
    tct_default,      // 默认色
    tct_16_color,     // 16 色
    tct_256_color,    // 256 色
    tct_rgb_color     // RGB 真彩色
  );

  // 颜色定义
  term_color_def_t = record
    color_type: term_color_type_t;
    case term_color_type_t of
      tct_default: ();
      tct_16_color: (color_16: Byte);
      tct_256_color: (color_256: Byte);
      tct_rgb_color: (red, green, blue: Byte);
  end;

  // 完整的文本样式定义
  term_text_style_t = record
    styles: term_style_set_t;
    fg_color: term_color_def_t;
    bg_color: term_color_def_t;
  end;

{** 样式管理函数 *}

// 样式创建函数
function term_style_create: term_text_style_t;
function term_style_create_simple(aStyle: term_style_t): term_text_style_t;
function term_style_create_colored(aFgColor: Byte): term_text_style_t;
function term_style_create_full(aStyles: term_style_set_t; aFgColor, aBgColor: Byte): term_text_style_t;

// 样式修改函数
function term_style_add(var aStyle: term_text_style_t; aNewStyle: term_style_t): term_text_style_t;
function term_style_remove(var aStyle: term_text_style_t; aRemoveStyle: term_style_t): term_text_style_t;
function term_style_set_fg_16(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
function term_style_set_bg_16(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
function term_style_set_fg_256(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
function term_style_set_bg_256(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
function term_style_set_fg_rgb(var aStyle: term_text_style_t; aRed, aGreen, aBlue: Byte): term_text_style_t;
function term_style_set_bg_rgb(var aStyle: term_text_style_t; aRed, aGreen, aBlue: Byte): term_text_style_t;

// 样式应用函数
function term_style_apply(const aStyle: term_text_style_t): string;
function term_style_reset: string;

// 便捷的文本格式化函数
function term_text_bold(const aText: string): string;
function term_text_italic(const aText: string): string;
function term_text_underline(const aText: string): string;
function term_text_strikethrough(const aText: string): string;
function term_text_blink(const aText: string): string;
function term_text_reverse(const aText: string): string;

// 颜色文本函数
function term_text_red(const aText: string): string;
function term_text_green(const aText: string): string;
function term_text_blue(const aText: string): string;
function term_text_yellow(const aText: string): string;
function term_text_magenta(const aText: string): string;
function term_text_cyan(const aText: string): string;
function term_text_white(const aText: string): string;
function term_text_black(const aText: string): string;

// 高级格式化函数
function term_text_colored(const aText: string; aColor: Byte): string;
function term_text_rgb(const aText: string; aRed, aGreen, aBlue: Byte): string;
function term_text_styled(const aText: string; const aStyle: term_text_style_t): string;

// 组合样式函数
function term_text_error(const aText: string): string;    // 红色粗体
function term_text_warning(const aText: string): string;  // 黄色粗体
function term_text_success(const aText: string): string;  // 绿色粗体
function term_text_info(const aText: string): string;     // 蓝色
function term_text_highlight(const aText: string): string; // 反转显示

{** 预定义样式常量 *}

const
  // 基本样式
  STYLE_NORMAL: term_text_style_t = (
    styles: [];
    fg_color: (color_type: tct_default);
    bg_color: (color_type: tct_default)
  );

  STYLE_BOLD: term_text_style_t = (
    styles: [ts_bold];
    fg_color: (color_type: tct_default);
    bg_color: (color_type: tct_default)
  );

  STYLE_ITALIC: term_text_style_t = (
    styles: [ts_italic];
    fg_color: (color_type: tct_default);
    bg_color: (color_type: tct_default)
  );

  STYLE_UNDERLINE: term_text_style_t = (
    styles: [ts_underline];
    fg_color: (color_type: tct_default);
    bg_color: (color_type: tct_default)
  );

implementation

{** 辅助函数实现 *}

function IntToStr(aValue: Integer): string;
var
  LNegative: Boolean;
  LTemp: Integer;
begin
  if aValue = 0 then
  begin
    Result := '0';
    Exit;
  end;

  Result := '';
  LNegative := aValue < 0;
  if LNegative then
    aValue := -aValue;

  while aValue > 0 do
  begin
    LTemp := aValue mod 10;
    Result := Chr(Ord('0') + LTemp) + Result;
    aValue := aValue div 10;
  end;

  if LNegative then
    Result := '-' + Result;
end;

{** 样式创建函数实现 *}

function term_style_create: term_text_style_t;
begin
  Result.styles := [];
  Result.fg_color.color_type := tct_default;
  Result.bg_color.color_type := tct_default;
end;

function term_style_create_simple(aStyle: term_style_t): term_text_style_t;
begin
  Result := term_style_create;
  Result.styles := [aStyle];
end;

function term_style_create_colored(aFgColor: Byte): term_text_style_t;
begin
  Result := term_style_create;
  Result.fg_color.color_type := tct_16_color;
  Result.fg_color.color_16 := aFgColor;
end;

function term_style_create_full(aStyles: term_style_set_t; aFgColor, aBgColor: Byte): term_text_style_t;
begin
  Result := term_style_create;
  Result.styles := aStyles;
  Result.fg_color.color_type := tct_16_color;
  Result.fg_color.color_16 := aFgColor;
  Result.bg_color.color_type := tct_16_color;
  Result.bg_color.color_16 := aBgColor;
end;

{** 样式修改函数实现 *}

function term_style_add(var aStyle: term_text_style_t; aNewStyle: term_style_t): term_text_style_t;
begin
  aStyle.styles := aStyle.styles + [aNewStyle];
  Result := aStyle;
end;

function term_style_remove(var aStyle: term_text_style_t; aRemoveStyle: term_style_t): term_text_style_t;
begin
  aStyle.styles := aStyle.styles - [aRemoveStyle];
  Result := aStyle;
end;

function term_style_set_fg_16(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
begin
  aStyle.fg_color.color_type := tct_16_color;
  aStyle.fg_color.color_16 := aColor;
  Result := aStyle;
end;

function term_style_set_bg_16(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
begin
  aStyle.bg_color.color_type := tct_16_color;
  aStyle.bg_color.color_16 := aColor;
  Result := aStyle;
end;

function term_style_set_fg_256(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
begin
  aStyle.fg_color.color_type := tct_256_color;
  aStyle.fg_color.color_256 := aColor;
  Result := aStyle;
end;

function term_style_set_bg_256(var aStyle: term_text_style_t; aColor: Byte): term_text_style_t;
begin
  aStyle.bg_color.color_type := tct_256_color;
  aStyle.bg_color.color_256 := aColor;
  Result := aStyle;
end;

function term_style_set_fg_rgb(var aStyle: term_text_style_t; aRed, aGreen, aBlue: Byte): term_text_style_t;
begin
  aStyle.fg_color.color_type := tct_rgb_color;
  aStyle.fg_color.red := aRed;
  aStyle.fg_color.green := aGreen;
  aStyle.fg_color.blue := aBlue;
  Result := aStyle;
end;

function term_style_set_bg_rgb(var aStyle: term_text_style_t; aRed, aGreen, aBlue: Byte): term_text_style_t;
begin
  aStyle.bg_color.color_type := tct_rgb_color;
  aStyle.bg_color.red := aRed;
  aStyle.bg_color.green := aGreen;
  aStyle.bg_color.blue := aBlue;
  Result := aStyle;
end;

{** 样式应用函数实现 *}

function term_style_apply(const aStyle: term_text_style_t): string;
begin
  Result := '';

  // 应用文本样式
  if ts_bold in aStyle.styles then
    Result := Result + ANSI_BOLD;
  if ts_dim in aStyle.styles then
    Result := Result + ANSI_DIM;
  if ts_italic in aStyle.styles then
    Result := Result + ANSI_ITALIC;
  if ts_underline in aStyle.styles then
    Result := Result + ANSI_UNDERLINE;
  if ts_blink in aStyle.styles then
    Result := Result + ANSI_BLINK;
  if ts_reverse in aStyle.styles then
    Result := Result + ANSI_REVERSE;
  if ts_strikethrough in aStyle.styles then
    Result := Result + ANSI_STRIKETHROUGH;

  // 应用前景色
  case aStyle.fg_color.color_type of
    tct_16_color:
      if aStyle.fg_color.color_16 <= 7 then
        Result := Result + CSI + IntToStr(30 + aStyle.fg_color.color_16) + 'm'
      else if aStyle.fg_color.color_16 <= 15 then
        Result := Result + CSI + IntToStr(90 + (aStyle.fg_color.color_16 - 8)) + 'm';
    tct_256_color:
      Result := Result + ansi_fg_color_256(aStyle.fg_color.color_256);
    tct_rgb_color:
      Result := Result + ansi_fg_color_rgb(aStyle.fg_color.red, aStyle.fg_color.green, aStyle.fg_color.blue);
  end;

  // 应用背景色
  case aStyle.bg_color.color_type of
    tct_16_color:
      if aStyle.bg_color.color_16 <= 7 then
        Result := Result + CSI + IntToStr(40 + aStyle.bg_color.color_16) + 'm'
      else if aStyle.bg_color.color_16 <= 15 then
        Result := Result + CSI + IntToStr(100 + (aStyle.bg_color.color_16 - 8)) + 'm';
    tct_256_color:
      Result := Result + ansi_bg_color_256(aStyle.bg_color.color_256);
    tct_rgb_color:
      Result := Result + ansi_bg_color_rgb(aStyle.bg_color.red, aStyle.bg_color.green, aStyle.bg_color.blue);
  end;
end;

function term_style_reset: string;
begin
  Result := ANSI_RESET;
end;

{** 便捷的文本格式化函数实现 *}

function term_text_bold(const aText: string): string;
begin
  Result := ANSI_BOLD + aText + ANSI_RESET;
end;

function term_text_italic(const aText: string): string;
begin
  Result := ANSI_ITALIC + aText + ANSI_RESET;
end;

function term_text_underline(const aText: string): string;
begin
  Result := ANSI_UNDERLINE + aText + ANSI_RESET;
end;

function term_text_strikethrough(const aText: string): string;
begin
  Result := ANSI_STRIKETHROUGH + aText + ANSI_RESET;
end;

function term_text_blink(const aText: string): string;
begin
  Result := ANSI_BLINK + aText + ANSI_RESET;
end;

function term_text_reverse(const aText: string): string;
begin
  Result := ANSI_REVERSE + aText + ANSI_RESET;
end;

{** 颜色文本函数实现 *}

function term_text_red(const aText: string): string;
begin
  Result := ANSI_FG_RED + aText + ANSI_RESET;
end;

function term_text_green(const aText: string): string;
begin
  Result := ANSI_FG_GREEN + aText + ANSI_RESET;
end;

function term_text_blue(const aText: string): string;
begin
  Result := ANSI_FG_BLUE + aText + ANSI_RESET;
end;

function term_text_yellow(const aText: string): string;
begin
  Result := ANSI_FG_YELLOW + aText + ANSI_RESET;
end;

function term_text_magenta(const aText: string): string;
begin
  Result := ANSI_FG_MAGENTA + aText + ANSI_RESET;
end;

function term_text_cyan(const aText: string): string;
begin
  Result := ANSI_FG_CYAN + aText + ANSI_RESET;
end;

function term_text_white(const aText: string): string;
begin
  Result := ANSI_FG_WHITE + aText + ANSI_RESET;
end;

function term_text_black(const aText: string): string;
begin
  Result := ANSI_FG_BLACK + aText + ANSI_RESET;
end;

{** 高级格式化函数实现 *}

function term_text_colored(const aText: string; aColor: Byte): string;
begin
  Result := ansi_fg_color_256(aColor) + aText + ANSI_RESET;
end;

function term_text_rgb(const aText: string; aRed, aGreen, aBlue: Byte): string;
begin
  Result := ansi_fg_color_rgb(aRed, aGreen, aBlue) + aText + ANSI_RESET;
end;

function term_text_styled(const aText: string; const aStyle: term_text_style_t): string;
begin
  Result := term_style_apply(aStyle) + aText + ANSI_RESET;
end;

{** 组合样式函数实现 *}

function term_text_error(const aText: string): string;
begin
  Result := ANSI_FG_RED + ANSI_BOLD + aText + ANSI_RESET;
end;

function term_text_warning(const aText: string): string;
begin
  Result := ANSI_FG_YELLOW + ANSI_BOLD + aText + ANSI_RESET;
end;

function term_text_success(const aText: string): string;
begin
  Result := ANSI_FG_GREEN + ANSI_BOLD + aText + ANSI_RESET;
end;

function term_text_info(const aText: string): string;
begin
  Result := ANSI_FG_BLUE + aText + ANSI_RESET;
end;

function term_text_highlight(const aText: string): string;
begin
  Result := ANSI_REVERSE + aText + ANSI_RESET;
end;

end.

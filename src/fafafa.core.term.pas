unit fafafa.core.term;

{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.term

## 概述

fafafa.term 是一个跨平台(Windows/Unix)的终端库。它提供了统一的终端接口，支持标准的输入/输出操作。
作为 fafafa.tui 的基础框架，它为上层应用提供了稳定可靠的终端交互能力。

## 讨论和建议

关于回调实现:
- 部分回调功能并非强依赖，在后端不支持时会自动降级或省略
- 建议后端尽可能实现更多高质量的功能回调，以提供最佳性能和用户体验

字符编码支持:
- Windows Console(wincon)默认使用 utf16(widestring)，因其对 utf8 支持有限
- Windows Terminal 完善了 utf8 支持，默认使用 utf8 编码
- Linux/Unix 系统普遍采用 utf8 环境，默认使用 utf8 编码
- 对于 emoji 等特殊码点，推荐使用 utf32 版本的 term_write 接口，以确保安全和便利

使用建议:
程序应当在初始化阶段探测并适应终端环境的特性。毕竟，适应终端环境是程序的责任，而不是期待终端环境来适应程序。

示例:
term_init;
...
term_writeln('bye');


## 声明

转发或者用于自己项目请保留本项目的版权声明,谢谢.

fafafaStudio
Email:dtamade@gmail.com
QQ群:685403987  QQ:179033731

}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$MACRO OFF}





interface

uses
  classes,
  sysutils,Variants, fafafa.core.env;

const

  { 类库版本号 }

  FAFAFA_TERM_VER_MAJOR = 1; // 主版本号
  FAFAFA_TERM_VER_MINOR = 0; // 次版本号
  FAFAFA_TERM_VER_PATCH = 0; // 补丁版本号

{**
 * term_version
 *
 * @desc 获取类库版本字符串
 *
 * @return 返回类库版本字符串
 *}
function term_version: string; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


type

  term_bit1_t = 0..1;
  term_bit2_t = 0..3;
  term_bit3_t = 0..7;
  term_bit4_t = 0..15;
  term_bit5_t = 0..31;
  term_bit6_t = 0..63;
  term_bit7_t = 0..127;
  term_bit8_t = 0..255;

const

  INFINITE      = $FFFFFFFF;
  WAIT_OBJECT_0 = 0;
  WAIT_TIMEOUT  = $00000102;


type

  { term_size_t 终端大小类型 }
  term_size_t = UInt16;

  term_cursor_shape_t = (
    tcs_default         = 0, // 默认
    tcs_blink_block     = 1, // 闪烁块状
    tcs_block           = 2, // 块状
    tcs_blink_underline = 3, // 闪烁下划线
    tcs_underline       = 4, // 下划线
    tcs_blink_bar       = 5, // 闪烁条状
    tcs_bar             = 6  // 条状
  );

type

  term_point_t = record
    x: term_size_t;
    y: term_size_t;
  end;
  pterm_point_t = ^term_point_t;


type

  { term_char_t 字符类型 }
  term_char_t = record
    case integer of
      0: (char:  AnsiChar);
      1: (wchar: WideChar);
  end;
  pterm_char_t = ^term_char_t;

  function term_char(aChar: AnsiChar): term_char_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_char(aChar: WideChar): term_char_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


type

  { term_compatible_t 终端兼容性类型 }
  term_compatible_t =(
    tc_clear               = 0,  // 支持屏幕清除
    tc_beep                = 1,  // 支持蜂鸣
    tc_flash               = 2,  // 支持闪烁
    tc_ansi                = 3,  // 支持ANSI序列
    tc_mouse               = 4,  // 支持鼠标

    tc_title               = 5,  // 支持标题获取
    tc_title_set           = 6,  // 支持标题设置
    tc_icon_set            = 7,  // 支持图标设置

    tc_size                = 8,  // 支持大小获取
    tc_size_set            = 9,  // 支持大小设置

    tc_alternate_screen    = 10, // 支持交替屏幕

    tc_color_16            = 11, // 支持16色
    tc_color_256           = 12, // 支持256色
    tc_color_24bit         = 13, // 支持24位色
    tc_color_16_palette    = 14, // 支持16色调色板
    tc_color_256_palette   = 15, // 支持256色调色板
    tc_color_palette_stack = 16, // 支持调色板栈

    tc_cursor              = 17, // 支持光标获取
    tc_cursor_set          = 18, // 支持光标设置
    tc_cursor_visible_set  = 19, // 支持光标可见设置
    tc_cursor_shape_set    = 20, // 支持光标形状设置
    tc_cursor_size_set     = 21, // 支持光标大小设置
    tc_cursor_blink_set    = 22, // 支持光标闪烁设置
    tc_cursor_color_set    = 23, // 支持光标颜色设置

    // 终端模式能力（ANSI扩展）
    tc_focus_1004          = 24, // 支持 FocusIn/Out (?1004)
    tc_paste_2004          = 25, // 支持 Bracketed Paste (?2004)
    tc_sync_update         = 26  // 支持 Synchronized Updates

  );

  { term_compatibles_t 终端兼容性集合 }
  term_compatibles_t = set of term_compatible_t;


type

  { term_color_16_t 16色索引 }
  term_color_16_t  = 0..15;

  { term_color_256_t 256色索引 }
  term_color_256_t = 0..255;


{ 调色板索引定义 }

const

  { 16位调色板 }

  { 标准色 0..7 }

  TERM_COLOR_PALETTE_BLACK          = 0; // 黑色
  TERM_COLOR_PALETTE_RED            = 1; // 红色
  TERM_COLOR_PALETTE_GREEN          = 2; // 绿色
  TERM_COLOR_PALETTE_YELLOW         = 3; // 黄色
  TERM_COLOR_PALETTE_BLUE           = 4; // 蓝色
  TERM_COLOR_PALETTE_MAGENTA        = 5; // 品红色
  TERM_COLOR_PALETTE_CYAN           = 6; // 青色
  TERM_COLOR_PALETTE_WHITE          = 7; // 白色

  { 高强度标准色 8..15 }

  TERM_COLOR_PALETTE_BLACK_BRIGHT   = 8;  // 灰色
  TERM_COLOR_PALETTE_RED_BRIGHT     = 9;  // 亮红色
  TERM_COLOR_PALETTE_GREEN_BRIGHT   = 10; // 亮绿色
  TERM_COLOR_PALETTE_YELLOW_BRIGHT  = 11; // 亮黄色
  TERM_COLOR_PALETTE_BLUE_BRIGHT    = 12; // 亮蓝色
  TERM_COLOR_PALETTE_MAGENTA_BRIGHT = 13; // 亮品红色
  TERM_COLOR_PALETTE_CYAN_BRIGHT    = 14; // 亮青色
  TERM_COLOR_PALETTE_WHITE_BRIGHT   = 15; // 亮白色

const

  TERM_COLOR_PALETTE_NAMES: array[0..15] of String = (
    'black',
    'red',
    'green',
    'yellow',
    'blue',
    'magenta',
    'cyan',
    'white',
    'gray',
    'red_bright',
    'green_bright',
    'yellow_bright',
    'blue_bright',
    'magenta_bright',
    'cyan_bright',
    'white_bright'
  );


  { 256位调色板 }

  { 216色 16..231 }



  { 灰度色 232..255 (从暗到亮) }

  TERM_COLOR_PALETTE_GRAY_0         = 232; // 灰色0
  TERM_COLOR_PALETTE_GRAY_1         = 233; // 灰色1
  TERM_COLOR_PALETTE_GRAY_2         = 234; // 灰色2
  TERM_COLOR_PALETTE_GRAY_3         = 235; // 灰色3
  TERM_COLOR_PALETTE_GRAY_4         = 236; // 灰色4
  TERM_COLOR_PALETTE_GRAY_5         = 237; // 灰色5
  TERM_COLOR_PALETTE_GRAY_6         = 238; // 灰色6
  TERM_COLOR_PALETTE_GRAY_7         = 239; // 灰色7
  TERM_COLOR_PALETTE_GRAY_8         = 240; // 灰色8
  TERM_COLOR_PALETTE_GRAY_9         = 241; // 灰色9
  TERM_COLOR_PALETTE_GRAY_10        = 242; // 灰色10
  TERM_COLOR_PALETTE_GRAY_11        = 243; // 灰色11
  TERM_COLOR_PALETTE_GRAY_12        = 244; // 灰色12
  TERM_COLOR_PALETTE_GRAY_13        = 245; // 灰色13
  TERM_COLOR_PALETTE_GRAY_14        = 246; // 灰色14
  TERM_COLOR_PALETTE_GRAY_15        = 247; // 灰色15
  TERM_COLOR_PALETTE_GRAY_16        = 248; // 灰色16
  TERM_COLOR_PALETTE_GRAY_17        = 249; // 灰色17
  TERM_COLOR_PALETTE_GRAY_18        = 250; // 灰色18
  TERM_COLOR_PALETTE_GRAY_19        = 251; // 灰色19
  TERM_COLOR_PALETTE_GRAY_20        = 252; // 灰色20
  TERM_COLOR_PALETTE_GRAY_21        = 253; // 灰色21
  TERM_COLOR_PALETTE_GRAY_22        = 254; // 灰色22
  TERM_COLOR_PALETTE_GRAY_23        = 255; // 灰色23
  TERM_COLOR_PALETTE_GRAY_MAX       = 255; // 最大灰色


type

  { term_color_24bit_t 24位真彩色 }
  term_color_24bit_t  = record
  case Integer of
    0: (b, g, r, reserved: UInt8);
    1: (color:             UInt32);
  end;
  pterm_color_24bit_t = ^term_color_24bit_t;

  term_hue_t                       = 0..359; // 色相
  term_saturation_t                = 0..100; // 饱和度
  term_value_t                     = 0..100; // 明度
  term_lightness_t                 = 0..100; // 亮度
  term_brightness_t                = 0..100; // 亮度
  term_cmyk_t                      = 0..100; // 青色
  term_color_palette_index_t       = UInt8;  // 调色板索引
  term_color_palette_stack_index_t = 0..10;  // 调色板栈索引

///
/// 事件
///


const

  { TERM_ASCII_MAP ASCII码映射表 }
  TERM_ASCII_MAP: array[0..127] of string = (
    'NUL',   'SOH', 'STX', 'ETX', 'EOT', 'ENQ', 'ACK', 'BEL',
    'BS',    'HT',  'LF',  'VT',  'FF',  'CR',  'SO',  'SI',
    'DLE',   'DC1', 'DC2', 'DC3', 'DC4', 'NAK', 'SYN', 'ETB',
    'CAN',   'EM',  'SUB', 'ESC', 'FS',  'GS',  'RS',  'US',
    'SPACE', '!',   '"',   '#',   '$',   '%',   '&',   '''',
    '(',     ')',   '*',   '+',   ',',   '-',   '.',   '/',
    '0',     '1',   '2',   '3',   '4',   '5',   '6',   '7',
    '8',     '9',   ':',   ';',   '<',   '=',   '>',   '?',
    '@',     'A',   'B',   'C',   'D',   'E',   'F',   'G',
    'H',     'I',   'J',   'K',   'L',   'M',   'N',   'O',
    'P',     'Q',   'R',   'S',   'T',   'U',   'V',   'W',
    'X',     'Y',   'Z',   '[',   '\',   ']',   '^',   '_',
    '`',     'a',   'b',   'c',   'd',   'e',   'f',   'g',
    'h',     'i',   'j',   'k',   'l',   'm',   'n',   'o',
    'p',     'q',   'r',   's',   't',   'u',   'v',   'w',
    'x',     'y',   'z',   '{',   '|',   '}',   '~',   'DEL'
  );



// 粘贴文本存储 API（可选治理）
function term_paste_store_text(const aText: string): SizeUInt;
function term_paste_get_text(aId: SizeUInt): string;
procedure term_paste_clear_all;
procedure term_paste_trim_keep_last(aKeepLast: SizeUInt);
procedure term_paste_set_auto_keep_last(aKeepLast: SizeUInt);
procedure term_paste_set_max_bytes(aMaxBytes: SizeUInt);
procedure term_paste_set_trim_fastpath_div(aDivisor: SizeUInt);
function term_paste_get_count: SizeUInt;
function term_paste_get_total_bytes: SizeUInt;
procedure term_paste_defaults(aKeepLast, aMaxBytes: SizeUInt);
function term_paste_get_auto_keep_last: SizeUInt;
procedure term_paste_defaults_ex(aKeepLast, aMaxBytes: SizeUInt; const aProfile: string = '');
// Programmatic backend toggle for tests/dev (legacy|ring); returns True if accepted
function term_paste_use_backend(const aName: string): Boolean;

function term_paste_get_max_bytes: SizeUInt;
function term_paste_get_trim_fastpath_div: SizeUInt;
procedure term_paste_apply_profile(const aProfile: string);


(*

按键标志

┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐              ┌──────┬──────┬──────┐
│ Esc │ F1  │ F2  │ F3  │ F4  │ F5  │ F6  │ F7  │ F8  │ F9  │ F10 │ F11 │ F12 │              │PrintS│Scroll│Pause │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘              └──────┴──────┴──────┘
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬────────────┐ ┌──────┬──────┬──────┐ ┌─────┬─────┬─────┬─────┐
│ `~  │ 1!  │ 2@  │ 3#  │ 4$  │ 5%  │ 6^  │ 7&  │ 8*  │ 9(  │ 0)  │ -_  │ =+  │ Back Space │ │ INS  │ HOME │ PGUP │ │ NUM │  /  │  *  │  -  │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼────────────┤ ├──────┼──────┼──────┤ ├─────┼─────┼─────┼─────┤
│ Tab │  Q  │  W  │  E  │  R  │  T  │  Y  │  U  │  I  │  O  │  P  │ {[  │ }]  │     \|     │ │ DEL  │ END  │ PGDN │ │  7  │  8  │  9  │     │
├─────┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴────────────┤ └──────┴──────┴──────┘ ├─────┼─────┼─────┤  +  │
│ Caps  │  A  │  S  │  D  │  F  │  G  │  H  │  J  │  K  │  L  │ ;:  │ '"  │      Enter     │                        │  4  │  5  │  6  │     │

function term_paste_store_text(const aText: string): SizeUInt;
function term_paste_get_text(aId: SizeUInt): string;
procedure term_paste_clear_all;
procedure term_paste_trim_keep_last(aKeepLast: SizeUInt);
procedure term_paste_set_auto_keep_last(aKeepLast: SizeUInt);

├───────┴──┬──┴──┬──┴──┬──┴──┬──┴──┬──┴──┬──┴──┬──┴──┬──┴──┬──┴──┬──┴──┬──┴────────────────┤        ┌──────┐        ├─────┼─────┼─────┼─────┤
│ LShift   │  Z  │  X  │  C  │  V  │  B  │  N  │  M  │ ,<  │ .>  │ /?  │      RShift       │        │  UP  │        │  1  │  2  │  3  │     │
├───────┬──┴────┬┴─────┴┬────┴─────┴─────┴─────┴─────┴─────┼─────┴─┬───┴───┬───────┬───────┤ ┌──────┼──────┼──────┐ ├─────┴─────┼─────┤Enter│
│ LCtrl │ LWin  │ LAlt  │               Space              │ RAlt  │ RWin  │ Menu  │ RCtrl │ │ Left │ Down │Right │ │     0     │  .  │     │
└───────┴───────┴───────┴──────────────────────────────────┴───────┴───────┴───────┴───────┘ └──────┴──────┴──────┘ └───────────┴─────┴─────┘

*)


type

  term_key_t = UInt8;

{ 按键定义 }

const

  KEY_UNKOWN              = 0;          // 未知键

  KEY_ESC                 = 1;          // Esc
  KEY_F1                  = 2;          // F1
  KEY_F2                  = 3;          // F2
  KEY_F3                  = 4;          // F3
  KEY_F4                  = 5;          // F4
  KEY_F5                  = 6;          // F5
  KEY_F6                  = 7;          // F6
  KEY_F7                  = 8;          // F7
  KEY_F8                  = 9;          // F8
  KEY_F9                  = 10;         // F9
  KEY_F10                 = 11;         // F10
  KEY_F11                 = 12;         // F11
  KEY_F12                 = 13;         // F12

  KEY_BACKTICK            = 14;         // ` ~
  KEY_1                   = 15;         // 1 !
  KEY_2                   = 16;         // 2 @
  KEY_3                   = 17;         // 3 #
  KEY_4                   = 18;         // 4 $
  KEY_5                   = 19;         // 5 %
  KEY_6                   = 20;         // 6 ^
  KEY_7                   = 21;         // 7 &
  KEY_8                   = 22;         // 8 *
  KEY_9                   = 23;         // 9 (
  KEY_0                   = 24;         // 0 )
  KEY_MINUS               = 25;         // - _
  KEY_EQUAL               = 26;         // = +
  KEY_BACKSPACE           = 27;         // Back Space

  KEY_TAB                 = 28;         // Tab
  KEY_Q                   = 29;         // Q
  KEY_W                   = 30;         // W
  KEY_E                   = 31;         // E
  KEY_R                   = 32;         // R
  KEY_T                   = 33;         // T
  KEY_Y                   = 34;         // Y
  KEY_U                   = 35;         // U
  KEY_I                   = 36;         // I
  KEY_O                   = 37;         // O
  KEY_P                   = 38;         // P
  KEY_LEFT_BRACKET        = 39;         // [ {
  KEY_RIGHT_BRACKET       = 40;         // ] }
  KEY_BACKSLASH           = 41;         // \ |

  KEY_CAPS_LOCK           = 42;         // Caps Lock
  KEY_A                   = 43;         // A
  KEY_S                   = 44;         // S
  KEY_D                   = 45;         // D
  KEY_F                   = 46;         // F
  KEY_G                   = 47;         // G
  KEY_H                   = 48;         // H
  KEY_J                   = 49;         // J
  KEY_K                   = 50;         // K
  KEY_L                   = 51;         // L
  KEY_SEMICOLON           = 52;         // ; :
  KEY_APOSTROPHE          = 53;         // ' "
  KEY_ENTER               = 54;         // Enter

  KEY_LSHIFT              = 55;         // LShift
  KEY_SHIFT               = KEY_LSHIFT; // Shift
  KEY_Z                   = 56;         // Z
  KEY_X                   = 57;         // X
  KEY_C                   = 58;         // C
  KEY_V                   = 59;         // V
  KEY_B                   = 60;         // B
  KEY_N                   = 61;         // N
  KEY_M                   = 62;         // M
  KEY_COMMA               = 63;         // , <
  KEY_PERIOD              = 64;         // . >
  KEY_SLASH               = 65;         // / ?
  KEY_RSHIFT              = 66;         // RShift

  KEY_LCtrl               = 67;         // LCtrl
  KEY_CTRL                = KEY_LCtrl;  // Ctrl
  KEY_LWin                = 68;         // LWin
  KEY_WIN                 = KEY_LWin;   // Win
  KEY_LAlt                = 69;         // LAlt
  KEY_ALT                 = KEY_LAlt;   // Alt
  KEY_SPACE               = 70;         // Space
  KEY_RAlt                = 71;         // RAlt
  KEY_RWin                = 72;         // RWin
  KEY_Menu                = 73;         // Menu
  KEY_RCtrl               = 74;         // RCtrl

  KEY_PRINT_SCREEN        = 75;         // Print Screen
  KEY_SCROLL_LOCK         = 76;         // Scroll Lock
  KEY_PAUSE               = 77;         // Pause

  KEY_INSERT              = 78;         // Insert
  KEY_HOME                = 79;         // Home
  KEY_PAGE_UP             = 80;         // Page Up

  KEY_DELETE              = 81;         // Delete
  KEY_END                 = 82;         // End
  KEY_PAGE_DOWN           = 83;         // Page Down

  KEY_UP                  = 84;         // Up
  KEY_LEFT                = 85;         // Left
  KEY_DOWN                = 86;         // Down
  KEY_RIGHT               = 87;         // Right

  KEY_NUM_LOCK            = 88;         // Num Lock
  KEY_NUM_DIVIDE          = 89;         // / ?
  KEY_NUM_MULTIPLY        = 90;         // *
  KEY_NUM_SUBTRACT        = 91;         // -

  KEY_NUM_7               = 92;         // 7
  KEY_NUM_8               = 93;         // 8
  KEY_NUM_9               = 94;         // 9

  KEY_NUM_4               = 95;         // 4
  KEY_NUM_5               = 96;         // 5
  KEY_NUM_6               = 97;         // 6

  KEY_NUM_1               = 98;         // 1
  KEY_NUM_2               = 99;         // 2
  KEY_NUM_3               = 100;        // 3

  KEY_NUM_0               = 101;        // 0
  KEY_NUM_DECIMAL         = 102;        // .

  KEY_NUM_PLUS            = 103;        // +
  KEY_NUM_ENTER           = 104;        // Enter

  { 其他      }

  KEY_MEDIA_NEXT_TRACK    = 105;        // 媒体键 下一曲
  KEY_MEDIA_PREV_TRACK    = 106;        // 媒体键 上一曲
  KEY_MEDIA_STOP          = 107;        // 媒体键 停止
  KEY_MEDIA_PLAY_PAUSE    = 108;        // 媒体键 播放/暂停
  KEY_VOLUME_MUTE         = 109;        // 音量静音键
  KEY_VOLUME_UP           = 110;        // 音量增大键
  KEY_VOLUME_DOWN         = 111;        // 音量减小键
  KEY_APPS                = 112;        // 应用程序键
  KEY_BROWSER_BACK        = 113;        // 浏览器后退键
  KEY_BROWSER_FORWARD     = 114;        // 浏览器前进键
  KEY_BROWSER_REFRESH     = 115;        // 浏览器刷新键
  KEY_BROWSER_STOP        = 116;        // 浏览器停止键
  KEY_BROWSER_SEARCH      = 117;        // 浏览器搜索键
  KEY_BROWSER_FAVORITES   = 118;        // 浏览器收藏键
  KEY_BROWSER_HOME        = 119;        // 浏览器主页键
  KEY_LAUNCH_MAIL         = 120;        // 启动邮件键
  KEY_LAUNCH_MEDIA_SELECT = 121;        // 启动媒体选择键
  KEY_LAUNCH_APP1         = 122;        // 启动应用程序1键
  KEY_LAUNCH_APP2         = 123;        // 启动应用程序2键

const

  { TERM_KEY_NAME_MAP 按键的文本映射数组 }
  TERM_KEY_NAME_MAP: array[0..123] of string = (
    'unknown',
    'esc',
    'f1',
    'f2',
    'f3',
    'f4',
    'f5',
    'f6',
    'f7',
    'f8',
    'f9',
    'f10',
    'f11',
    'f12',
    'backtick',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    'minus',
    'equal',
    'backspace',
    'tab',
    'q',
    'w',
    'e',
    'r',
    't',
    'y',
    'u',
    'i',
    'o',
    'p',
    'left bracket',
    'right bracket',
    'backslash',
    'caps lock',
    'a',
    's',
    'd',
    'f',
    'g',
    'h',
    'j',
    'k',
    'l',
    'semicolon',
    'apostrophe',
    'enter',
    'shift',
    'z',
    'x',
    'c',
    'v',
    'b',
    'n',
    'm',
    'comma',
    'period',
    'slash',
    'right shift',
    'ctrl',
    'win',
    'alt',
    'space',
    'right alt',
    'right win',
    'menu',
    'right ctrl',
    'print screen',
    'scroll lock',
    'pause',
    'insert',
    'home',
    'page up',
    'delete',
    'end',
    'page down',
    'up',
    'left',
    'down',
    'right',
    'num lock',
    'num divide',
    'num multiply',
    'num subtract',
    'num 7',
    'num 8',
    'num 9',
    'num 4',
    'num 5',
    'num 6',
    'num 1',
    'num 2',
    'num 3',
    'num 0',
    'num decimal',
    'num plus',
    'num enter',
    'media next track',
    'media prev track',
    'media stop',
    'media play pause',
    'volume mute',
    'volume up',
    'volume down',
    'apps',
    'browser back',
    'browser forward',
    'browser refresh',
    'browser stop',
    'browser search',
    'browser favorites',
    'browser home',
    'launch mail',
    'launch media select',
    'launch app1',
    'launch app2'
  );





type

  { term_event_key_t 按键事件 }
  term_event_key_t = bitpacked record
    key:   term_key_t;  // 按键代码,见 KEY_XXX 常量,当我们处理按键事件应该关注这个值
    char:  term_char_t; // 按键产生的字符

    { 修饰键 0:未按下 1:按下 }

    shift: term_bit1_t;
    ctrl:  term_bit1_t;
    alt:   term_bit1_t;
  end;
  pterm_event_key_t = ^term_event_key_t;

type

  { term_mouse_button_t 鼠标按键 }
  term_mouse_button_t = (
    tmb_none         = 0,  // 无按钮
    tmb_left         = 1,  // 左键
    tmb_middle       = 2,  // 中键
    tmb_right        = 3,  // 右键
    tmb_wheel_up     = 4,  // 滚轮向上
    tmb_wheel_down   = 5,  // 滚轮向下
    tmb_wheel_left   = 6,  // 滚轮向左
    tmb_wheel_right  = 7,  // 滚轮向右
    tmb_backward     = 8,  // 后退键
    tmb_forward      = 9,  // 前进键
    tmb_10           = 10, // 按钮10
    tmb_11           = 11  // 按钮11
  );

const

  { TERM_MOUSE_BUTTON_MAP 鼠标按键的文本映射数组 }
  TERM_MOUSE_BUTTON_MAP: array[term_mouse_button_t] of string = (
    'none',
    'left',
    'middle',
    'right',
    'wheel up',
    'wheel down',
    'wheel left',
    'wheel right',
    'backward',
    'forward',
    'button 10',
    'button 11'
  );

type

  { term_mouse_state_t 鼠标状态 }
  term_mouse_state_t = (
    tms_release = 0, // 鼠标释放
    tms_press   = 1, // 鼠标按下
    tms_moved   = 2  // 鼠标移动
  );

type

  { term_event_mouse_t 鼠标事件 }
  term_event_mouse_t = bitpacked record
    x:      term_size_t; // 位置x
    y:      term_size_t; // 位置y
    state:  term_bit2_t; // 状态
    button: term_bit4_t; // 按键
    shift:  term_bit1_t; // Shift 键
    ctrl:   term_bit1_t; // Ctrl 键
    alt:    term_bit1_t; // Alt 键
  end;
  pterm_event_mouse_t = ^term_event_mouse_t;

type

  { term_event_size_change_t 窗口大小变更事件 }
  term_event_size_change_t = record
    width:  term_size_t; // 新宽度
    height: term_size_t; // 新高度
  end;
  pterm_event_size_change_t = ^term_event_size_change_t;

type

  { term_event_focus_t 焦点事件 }
  term_event_focus_t = record
    focus: Boolean; // 焦点
  end;
  pterm_event_focus_t = ^term_event_focus_t;

  { term_event_paste_t 粘贴事件（Bracketed Paste） }
  term_event_paste_t = record
    id: SizeUInt; // 粘贴内容存储ID（通过辅助函数取回文本）
  end;
  pterm_event_paste_t = ^term_event_paste_t;


type

  { term_event_kind_t 事件类型 }
  term_event_kind_t = (
    tek_unknown    = 0, // 未知事件
    tek_key        = 1, // 按键事件
    tek_mouse      = 2, // 鼠标事件
    tek_sizeChange = 3, // 窗口大小变更事件
    tek_focus      = 4, // 焦点事件
    tek_paste      = 5  // 粘贴事件（Bracketed Paste）
  );

const

  { TERM_EVENT_KIND_NAME 事件类型名称 }
  TERM_EVENT_KIND_NAME: array[term_event_kind_t] of string = ('unknown', 'key', 'mouse', 'sizeChange', 'focus', 'paste');

type

  { term_event_t 事件 }
  term_event_t = bitpacked record
    kind:  term_event_kind_t; // 事件类型
    case integer of
      0:(key:     term_event_key_t);         // 按键事件数据
      1:(mouse:   term_event_mouse_t);       // 鼠标事件数据
      2:(size:    term_event_size_change_t); // 窗口大小变更事件数据
      3:(focus:   term_event_focus_t);       // 焦点事件数据
      4:(paste:   term_event_paste_t);       // 粘贴事件数据
  end;
  pterm_event_t  = ^term_event_t;
  ppterm_event_t = ^pterm_event_t;


type
  { 事件队列项 }
  pterm_event_queue_entry_t = ^term_event_queue_entry_t;
  term_event_queue_entry_t = record
    event: term_event_t;
    next:  pterm_event_queue_entry_t;
    prev:  pterm_event_queue_entry_t;
  end;

  { 事件队列 }
  term_event_queue_t = record
    // legacy linked-list fields (unused when capacity>0)
    head:  pterm_event_queue_entry_t;
    tail:  pterm_event_queue_entry_t;
    // ring buffer fields
    buffer: array of term_event_t;
    capacity: SizeUInt;
    head_idx: SizeUInt; // read position
    tail_idx: SizeUInt; // write position
    count: SizeUInt;
  end;
  pterm_event_queue_t = ^term_event_queue_t;

const
  // 事件队列硬上限/环形容量，避免极端输入风暴导致内存膨胀
  TERM_EVENT_QUEUE_MAX = 8192;


  {**
  * term_event_queue_create
  *
  * @desc 创建事件队列
  *
  * @return 返回事件队列
  *}
  function term_event_queue_create: pterm_event_queue_t;

  {**
  * term_event_queue_init
  *
  * @desc 初始化事件队列
  *
  * @params
  *  - aQueue 事件队列
  *}
  procedure term_event_queue_init(aQueue: pterm_event_queue_t);

  {**
  * term_event_queue_final
  *
  * @desc 清理事件队列
  *
  * @params
  *  - aQueue 事件队列
  *}
  procedure term_event_queue_final(aQueue: pterm_event_queue_t);

  {**
  * term_event_queue_destroy
  *
  * @desc 销毁事件队列
  *
  * @params
  *  - aQueue 事件队列
  *}
  procedure term_event_queue_destroy(aQueue: pterm_event_queue_t);

  {**
  * term_event_queue_count
  *
  * @desc 获取事件队列中的事件数量
  *
  * @params
  *  - aQueue 事件队列
  *}
  function term_event_queue_count(aQueue: pterm_event_queue_t): SizeUInt; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * term_event_queue_is_empty
  *
  * @desc 判断事件队列是否为空
  *
  * @params
  *  - aQueue 事件队列
  *}
  function term_event_queue_is_empty(aQueue: pterm_event_queue_t): Boolean; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * term_event_queue_clear
  *
  * @desc 清空事件队列
  *
  * @params
  *  - aQueue 事件队列
  *}
  procedure term_event_queue_clear(aQueue: pterm_event_queue_t);

  {**
  * term_event_queue_peek
  *
  * @desc 查看事件队列中的事件
  *
  * @params
  *  - aQueue 事件队列
  *  - aEvent 事件数据
  *}
  function term_event_queue_peek(aQueue: pterm_event_queue_t; var aEvent: term_event_t): Boolean; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * term_event_queue_pop
  *
  * @desc 从事件队列中弹出一个事件
  *
  * @params
  *  - aQueue 事件队列
  *  - aEvent 事件数据
  *}
  function term_event_queue_pop(aQueue: pterm_event_queue_t; var aEvent: term_event_t): Boolean;

  {**
  * term_event_queue_push
  *
  * @desc 将事件推入事件队列
  *
  * @params
  *  - aQueue 事件队列
  *  - aEvent 事件数据
  *}
  procedure term_event_queue_push(aQueue: pterm_event_queue_t; const aEvent: term_event_t);

  {**
  * term_event_queue_entry_front
  *
  * @desc 获取事件队列的第一个元素
  *
  * @params
  *  - aQueue 事件队列
  *}
  function term_event_queue_entry_front(aQueue: pterm_event_queue_t): pterm_event_queue_entry_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * term_event_queue_entry_back
  *
  * @desc 获取事件队列的最后一个元素
  *
  * @params
  *  - aQueue 事件队列
  *}
  function term_event_queue_entry_back(aQueue: pterm_event_queue_t): pterm_event_queue_entry_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * term_event_queue_entry_next
  *
  * @desc 获取下一个元素
  *
  * @params
  *  - aEntry 事件队列项
  *}
  function term_event_queue_entry_next(aEntry: pterm_event_queue_entry_t): pterm_event_queue_entry_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * term_event_queue_entry_prev
  *
  * @desc 获取上一个元素
  *
  * @params
  *  - aEntry 事件队列项
  *}
  function term_event_queue_entry_prev(aEntry: pterm_event_queue_entry_t): pterm_event_queue_entry_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * term_event_queue_entry_remove
  *
  * @desc 移除事件队列项
  *
  * @params
  *  - aEntry 事件队列项
  *}
  procedure term_event_queue_remove(aQueue: pterm_event_queue_t; aEntry: pterm_event_queue_entry_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}




  {**
   * term_color_24bit
   *
   * @desc 通过 rgb 分量构造24位真彩色
   *
   * @params
   *  - aR R 分量
   *  - aG G 分量
   *  - aB B 分量
   *
   * @return 返回24位真彩色
   *}
  function term_color_24bit_rgb(aR, aG, aB: UInt8): term_color_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_24bit_hsv
   *
   * @desc 通过 hsv 分量构造24位真彩色
   *
   * @params
   *  - aHue        色相
   *  - aSaturation 饱和度
   *  - aValue      明度
   *
   * @return 返回24位真彩色
   *}
  function term_color_24bit_hsv(aHue: term_hue_t; aSaturation: term_saturation_t; aValue: term_value_t): term_color_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_24bit_hsb
   *
   * @desc 通过 hsb 分量构造24位真彩色(hsv 别名)
   *
   * @params
   *  - aHue        色相
   *  - aSaturation 饱和度
   *  - aBrightness 亮度
   *
   * @return 返回24位真彩色
   *}
  function term_color_24bit_hsb(aHue: term_hue_t; aSaturation: term_saturation_t; aBrightness: term_brightness_t): term_color_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_24bit_hsl
   *
   * @desc 通过 hsl 分量构造24位真彩色
   *
   * @params
   *  - aHue        色相
   *  - aSaturation 饱和度
   *  - aLightness  亮度
   *
   * @return 返回24位真彩色
   *}
  function term_color_24bit_hsl(aHue: term_hue_t; aSaturation: term_saturation_t; aLightness: term_lightness_t): term_color_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_24bit_cmyk
   *
   * @desc 通过 cmyk 分量构造24位真彩色
   *
   * @params
   *  - aCyan     青色
   *  - aMagenta  品红色
   *  - aYellow   黄色
   *  - aBlack    黑色
   *
   * @return 返回24位真彩色
   *}
  function term_color_24bit_cmyk(aCyan, aMagenta, aYellow, aBlack: term_cmyk_t): term_color_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_24bit_hex
   *
   * @desc 通过十六进制字符串构造24位真彩色
   *
   * @params
   *  - aHex 十六进制
   *
   * @return 返回24位真彩色
   *}
  function term_color_24bit_hex(const aHex: String): term_color_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_24bit_gray
   *
   * @desc 通过255级灰度构造24位真彩色
   *
   * @params
   *  - aGray 灰度
   *
   * @return 返回24位真彩色
   *}
  function term_color_24bit_gray(aGray: UInt8): term_color_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {** 颜色降级辅助（24bit -> 256/16）**}
  function term_color_approx_256(const aColor: term_color_24bit_t): term_color_256_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_rgb_to_256(aR, aG, aB: UInt8): term_color_256_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_color_approx_16(const aColor: term_color_24bit_t): term_color_16_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_rgb_to_16(aR, aG, aB: UInt8): term_color_16_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_to_hex
   *
   * @desc 将24位真彩色转换为十六进制字符串
   *
   * @params
   *  - aColor 24位真彩色
   *
   * @return 返回十六进制字符串
   *}
  function term_color_to_hex(aColor: term_color_24bit_t): String;


type

  { 文本样式 }
  term_attr_styles_t = bitpacked record
    bold:          term_bit1_t; // 粗体
    dim:           term_bit1_t; // 暗色
    italic:        term_bit1_t; // 斜体
    underline:     term_bit1_t; // 下划线
    blink:         term_bit1_t; // 闪烁
    reverse:       term_bit1_t; // 反色
    hidden:        term_bit1_t; // 隐藏
    strikethrough: term_bit1_t; // 删除线
  end;

  { 16 色调色板索引 }
  term_attr_color_palette_16_index_t  =  term_bit4_t;

  { 16 色调色板属性 }
  term_attr_16_t = bitpacked record
    foreground: term_attr_color_palette_16_index_t; // 前景色
    background: term_attr_color_palette_16_index_t; // 背景色
    styles:     term_attr_styles_t;                 // 文本样式
  end;
  pterm_attr_16_t = ^term_attr_16_t;

  function term_attr_16(const aForeground, aBackground: term_color_16_t; const aStyles: term_attr_styles_t): term_attr_16_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

type

  { 256 色调色板索引 }
  term_attr_color_palette_256_index_t =  term_bit8_t;

  { 256 色调色板属性 }
  term_attr_256_t = bitpacked record
    foreground: term_attr_color_palette_256_index_t; // 前景色
    background: term_attr_color_palette_256_index_t; // 背景色
    styles:     term_attr_styles_t;                  // 文本样式
  end;
  pterm_attr_256_t = ^term_attr_256_t;

  function term_attr_256(const aForeground, aBackground: term_color_256_t; const aStyles: term_attr_styles_t): term_attr_256_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


type

  { 24 位真彩色属性 }
  term_attr_24bit_t = bitpacked record
    foreground: term_color_24bit_t; // 前景色
    background: term_color_24bit_t; // 背景色
    styles:     term_attr_styles_t;      // 文本样式
  end;
  pterm_attr_24bit_t = ^term_attr_24bit_t;

  function term_attr_24bit(const aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t): term_attr_24bit_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}



{ term_t 终端抽象层 }

type

  pterm_t = ^term_t;

  term_t = record

    { 终端名称 utf8 编码 }
    name: string;

    { 额外数据 }
    data: pointer;

    { 终端兼容性集合 }
    compatibles: term_compatibles_t;

    { 初始化 }
    init: function (aTerm: pterm_t) :Boolean;

    { 销毁 }
    destroy: procedure (aTerm: pterm_t);

    { 重置 }
    reset: procedure (aTerm: pterm_t);

    { 清除屏幕 }
    clear: function (aTerm: pterm_t): boolean;

    { 蜂鸣 }
    beep: function (aTerm: pterm_t): boolean;

    { 闪烁 }
    flash: function (aTerm: pterm_t): boolean;

    { 获取标题 }
    title_get: function (aTerm: pterm_t): string;

    { 设置标题 }
    title_set: function (aTerm: pterm_t; const aTitle: String): boolean;

    { 获取大小 }
    size_get: function (aTerm: pterm_t; var aWidth, aHeight: term_size_t): boolean;

    { 设置大小 }
    size_set: function (aTerm: pterm_t; aWidth, aHeight: term_size_t): boolean;

    { 设置图标 }
    icon_set: function (aTerm: pterm_t; const aIcon: pchar): boolean;

    { 启用鼠标 }
    mouse_enable: function (aTerm: pterm_t; aEnabled: Boolean): Boolean;


    { 光标 }

    { 保存光标位置 }
    cursor_save: procedure (aTerm: pterm_t);

    { 恢复光标位置 }
    cursor_restore: procedure (aTerm: pterm_t);

    { 入栈保存光标位置 }
    cursor_push: procedure (aTerm: pterm_t);

    { 出栈恢复光标位置 }
    cursor_pop: procedure (aTerm: pterm_t);

    { 获取光标位置 }
    cursor_get: function  (aTerm: pterm_t; var aX, aY: term_size_t): Boolean;

    { 设置光标位置 }
    cursor_set: function  (aTerm: pterm_t; aX, aY: term_size_t): Boolean;

    { 获取光标x位置 }
    cursor_x: function (aTerm: pterm_t): term_size_t;

    { 获取光标y位置 }
    cursor_y: function  (aTerm: pterm_t): term_size_t;

    { 设置光标x位置 }
    cursor_x_set: function (aTerm: pterm_t; aX: term_size_t): Boolean;

    { 设置光标y位置 }
    cursor_y_set: function (aTerm: pterm_t; aY: term_size_t): Boolean;

    { 移动光标到终端原点 }
    cursor_home: procedure (aTerm: pterm_t);

    { 向上移动光标 }
    cursor_up: procedure (aTerm: pterm_t; aCount: term_size_t);

    { 光标向左移动 }
    cursor_left: procedure (aTerm: pterm_t; aCount: term_size_t);

    { 向下移动光标 }
    cursor_down: procedure (aTerm: pterm_t; aCount: term_size_t);

    { 光标向右移动 }
    cursor_right: procedure (aTerm: pterm_t; aCount: term_size_t);

    { 移动光标到指定行 }
    cursor_line: procedure (aTerm: pterm_t; aLine: term_size_t);

    { 向上移动光标 }
    cursor_line_prev: procedure (aTerm: pterm_t; aCount: term_size_t);

    { 向下移动光标 }
    cursor_line_next: procedure (aTerm: pterm_t; aCount: term_size_t);

    { 移动光标到当前行指定列 }
    cursor_col: procedure (aTerm: pterm_t; aColumn: term_size_t);


    { 设置光标可见 }
    cursor_visible_set: function (aTerm: pterm_t; aVisible: Boolean): Boolean;

    { 设置光标形状 }
    cursor_shape_set: function (aTerm: pterm_t; aShape: term_cursor_shape_t): Boolean;

    { 重置光标形状 }
    cursor_shape_reset: procedure (aTerm: pterm_t);

    { 设置光标大小(厚度) }
    cursor_size_set: function (aTerm: pterm_t; aSize: UInt8): Boolean;

    { 设置光标闪烁 }
    cursor_blink_set: function (aTerm: pterm_t; aBlink: Boolean): Boolean;

    { 设置光标调色板索引 }
    cursor_color_palette_set: function (aTerm: pterm_t; aIndex: term_color_palette_index_t): Boolean;

    { 设置光标24bit真彩色 }
    cursor_color_set: function (aTerm: pterm_t; const aColor: term_color_24bit_t): Boolean;

    { 切换备用屏 }
    alternate_screen_enable: function (aTerm: pterm_t; aEnable: Boolean): Boolean;

    { 原始模式 Raw Mode 切换 }
    raw_mode_enable: function (aTerm: pterm_t; aEnable: Boolean): Boolean;

    { 调色板 }

    { 修改调色板 }
    color_palette_set:  function (aTerm: pterm_t; aIndex: term_color_palette_index_t; const aColor: term_color_24bit_t): Boolean;

    { 调色板入栈保存 }
    color_palette_push: procedure (aTerm: pterm_t; aStackIndex: term_color_palette_stack_index_t);

    { 调色板出栈恢复 }
    color_palette_pop:  procedure (aTerm: pterm_t; aStackIndex: term_color_palette_stack_index_t);


    { attr 属性 }


    { 属性入栈保存 }
    attr_push: procedure (aTerm: pterm_t);

    { 属性出栈恢复 }
    attr_pop:  procedure (aTerm: pterm_t);

    { 设置属性(调色板) }
    attr_color_palette_set: procedure (aTerm: pterm_t; aForeground, aBackground: term_color_palette_index_t; const aStyles: term_attr_styles_t);

    { 设置属性(24位真彩色) }
    attr_color_24bit_set:   procedure (aTerm: pterm_t; const aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t);

    { 设置终端前景(调色板索引) }
    attr_foreground_palette_set: procedure (aTerm: pterm_t; aColor: term_color_palette_index_t);

    { 设置终端前景(24位真彩色) }
    attr_foreground_24bit_set:   procedure (aTerm: pterm_t; const aColor: term_color_24bit_t);

    { 设置终端背景(调色板索引) }
    attr_background_palette_set: procedure (aTerm: pterm_t; aColor: term_color_palette_index_t);

    { 设置终端背景(24位真彩色) }
    attr_background_24bit_set:   procedure (aTerm: pterm_t; const aColor: term_color_24bit_t);

    { 重置属性文本样式 }
    attr_styles_reset:     procedure (aTerm: pterm_t);

    { 重置属性背景色 }
    attr_background_reset: procedure (aTerm: pterm_t);

    { 重置属性前景色 }
    attr_foreground_reset: procedure (aTerm: pterm_t);

    { 重置所有属性 }
    attr_reset: procedure (aTerm: pterm_t);


    { 输出 }

    write:      procedure (aTerm: pterm_t; const aData: pchar; aLen: Integer);
    write_wide: procedure (aTerm: pterm_t; const aData: pwidechar; aLen: Integer);
    write_ucs4: procedure (aTerm: pterm_t; const aData: pucs4char; aLen: Integer);


    { 事件队列 }
    event_queue: pterm_event_queue_t;

    { 拉取事件 }
    event_pull: function (aTerm: pterm_t; aTimeout: UInt64) :Boolean;


    { 输入 }

    readchar:  function (aTerm: pterm_t): char;
    readln:    procedure (aTerm: pterm_t; var aLine: String);

  end;


  {**
   * term_point_create
   *
   * @desc 创建point
   *
   * @params
   * - aX 位置x
   * - aY 位置y
   *
   * @return 返回创建的位置指针
   *}
  function term_point_create(aX, aY: term_size_t): pterm_point_t; overload;

  {**
   * term_point_create
   *
   * @desc 创建point 0,0
   *
   * @return 返回创建的位置指针
   *}
  function term_point_create: pterm_point_t; overload;

  {**
   * term_point_init
   *
   * @desc 初始化point
   *
   * @params
   * - aPoint 位置指针
   * - aX     位置x
   * - aY     位置y
   *}
  procedure term_point_init(aPoint: pterm_point_t; aX, aY: term_size_t);

  {**
   * term_point_destroy
   *
   * @desc 销毁point
   *
   * @params
   * - aPoint 位置指针
   *}
  procedure term_point_destroy(aPoint: pterm_point_t);

  {**
   * term_point_x
   *
   * @desc 获取point x
   *
   * @params
   * - aPoint 位置指针
   *
   * @return 返回位置x
   *}
  function  term_point_x(aPoint: pterm_point_t): term_size_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_y
   *
   * @desc 获取point y
   *
   * @params
   * - aPoint 位置指针
   *
   * @return 返回位置y
   *}
  function  term_point_y(aPoint: pterm_point_t): term_size_t; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_set_x
   *
   * @desc 设置point x
   *
   * @params
   * - aPoint 位置指针
   * - aX     位置x
   *}
  procedure term_point_set_x(aPoint: pterm_point_t; aX: term_size_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_set_y
   *
   * @desc 设置point y
   *
   * @params
   * - aPoint 位置指针
   * - aY     位置y
   *}
  procedure term_point_set_y(aPoint: pterm_point_t; aY: term_size_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_equal
   *
   * @desc 比较两个point是否相等
   *
   * @params
   * - aPoint1 位置1
   * - aPoint2 位置2
   *
   * @return 返回比较结果
   *}
  function  term_point_equal(aPoint1, aPoint2: pterm_point_t): boolean; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_set
   *
   * @desc 设置
   *
   * @params
   * - aPoint 位置指针
   * - aX     位置x
   * - aY     位置y
   *}
  procedure term_point_set(aPoint: pterm_point_t; aX, aY: term_size_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_offset
   *
   * @desc 偏移
   *
   * @params
   * - aPoint 位置指针
   * - aX     位置x 偏移量
   * - aY     位置y 偏移量
   *}
  procedure term_point_offset(aPoint: pterm_point_t; aX, aY: term_size_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_up
   *
   * @desc 向上移动
   *
   * @params
   * - aPoint 位置指针
   * - aY     位置y 偏移量
   *}
  procedure term_point_up(aPoint: pterm_point_t; aY: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_up
   *
   * @desc 向上移动(1)
   *
   * @params
   * - aPoint 位置指针
   *}
  procedure term_point_up(aPoint: pterm_point_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_down
   *
   * @desc 向下移动point(1)
   *}
  procedure term_point_down(aPoint: pterm_point_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_left
   *
   * @desc 向左移动
   *
   * @params
   * - aPoint 位置指针
   * - aX     位置x 偏移量
   *}
  procedure term_point_left(aPoint: pterm_point_t; aX: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_left
   *
   * @desc 向左移动位置(1)
   *}
  procedure term_point_left(aPoint: pterm_point_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_right
   *
   * @desc 向右移动位置
   *
   * @params
   * - aPoint 位置指针
   * - aX     位置x 偏移量
   *}
  procedure term_point_right(aPoint: pterm_point_t; aX: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_point_right
   *
   * @desc 向右移动位置(1)
   *}
  procedure term_point_right(aPoint: pterm_point_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


///
/// 基础接口
///


  {**
   * term_init
   *
   * @desc 初始化平台默认终端实例
   *
   * @return 返回是否初始化成功
   *
   * @remark 使用类库前必须初始化平台默认终端实例
   *         平台默认终端实例会在程序结束时自动清理,无需手动销毁
   *}
  function term_init: Boolean; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_done
   *
   * @desc 释放默认终端实例并恢复控制台状态（幂等）
   *}
  procedure term_done;


  {**
   * term_last_error
   *
   * @desc 返回最近一次初始化或操作错误的简要诊断信息；空字符串表示无错误
   *}
  function term_last_error: string; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_name
   *
   * @desc 获取指定终端的名称
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回终端名称
   *}
  function term_name(aTerm: pterm_t): string; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_name
   *
   * @desc 获取终端名称
   *
   * @return 返回终端名称
   *}
  function term_name: string; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_data
   *
   * @desc 获取指定终端的额外数据
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回终端的额外数据指针
   *}
  function term_data(aTerm: pterm_t): pointer; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_data
   *
   * @desc 获取额外数据
   *
   * @return 返回额外数据指针
   *}
  function term_data: pointer; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_compatibles
   *
   * @desc 获取指定终端的兼容性集合
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回兼容性集合
   *}
  function term_compatibles(aTerm: pterm_t): term_compatibles_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_compatibles
   *
   * @desc 获取兼容性集合
   *
   * @return 返回兼容性集合
   *}
  function term_compatibles: term_compatibles_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_compatibles
   *
   * @desc 检查指定终端是否支持指定兼容性集合
   *
   * @params
   *  - aTerm        终端实例指针
   *  - aCompatibles 兼容性集合
   *
   * @return 返回是否支持
   *}
  function term_support_compatibles(aTerm: pterm_t; const aCompatibles: term_compatibles_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_compatibles
   *
   * @desc 检查是否支持指定兼容性集合
   *
   * @params
   *  - aCompatibles 兼容性集合
   *
   * @return 返回是否支持
   *}
  function term_support_compatibles(const aCompatibles: term_compatibles_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_compatible
   *
   * @desc 检查指定终端是否支持指定兼容性
   *
   * @params
   *  - aTerm       终端实例指针
   *  - aCompatible 兼容性
   *
   * @return 返回是否支持
   *}
  function term_support_compatible(aTerm: pterm_t; aCompatible: term_compatible_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_compatible
   *
   * @desc 检查是否支持指定兼容性
   *
   * @params
   *  - aCompatible 兼容性
   *
   * @return 返回是否支持
   *}
  function term_support_compatible(aCompatible: term_compatible_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_reset
   *
   * @desc 重置指定终端到初始化状态
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_reset(aTerm: pterm_t); overload;

  {**
   * term_reset
   *
   * @desc 重置终端到初始化状态
   *}
  procedure term_reset; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_clear
   *
   * @desc 检查指定终端是否支持屏幕清除
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_clear(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_clear
   *
   * @desc 检查是否支持屏幕清除
   *
   * @return 返回是否支持
   *}
  function term_support_clear: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_clear
   *
   * @desc 清除指定终端
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否清除成功
   *}
  function term_clear(aTerm: pterm_t): boolean; overload;

  {**
   * term_clear
   *
   * @desc 清除终端
   *
   * @return 返回是否清除成功
   *}
  function term_clear: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_beep
   *
   * @desc 检查指定终端是否支持蜂鸣
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_beep(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_beep
   *
   * @desc 检查是否支持蜂鸣
   *
   * @return 返回是否支持
   *}
  function term_support_beep: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_beep
   *
   * @desc 蜂鸣指定终端
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否蜂鸣成功
   *}
  function term_beep(aTerm: pterm_t): boolean; overload;

  {**
   * term_beep
   *
   * @desc 蜂鸣终端
   *
   * @return 返回是否蜂鸣成功
   *}
  function term_beep: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_flash
   *
   * @desc 检查指定终端是否支持闪烁
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_flash(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_flash
   *
   * @desc 检查是否支持闪烁
   *
   * @return 返回是否支持
   *}
  function term_support_flash: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_flash
   *
   * @desc 闪烁指定终端
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否闪烁成功
   *}
  function term_flash(aTerm: pterm_t): boolean; overload;

  {**
   * term_flash
   *
   * @desc 闪烁终端
   *
   * @return 返回是否闪烁成功
   *}
  function term_flash: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_ansi
   *
   * @desc 检查指定终端是否支持ANSI序列
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_ansi(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_ansi
   *
   * @desc 检查是否支持ANSI序列
   *
   * @return 返回是否支持
   *}
  function term_support_ansi: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  ///
  /// mouse 鼠标
  ///

  {
    大部分的终端都支持鼠标, 但是也有一些终端不支持鼠标.
    保险起见,你需要在程序初始化时检查环境是否支持鼠标(term_support_mouse 或者 term_support_compatible(tc_mouse)).
    鼠标默认是不开启的,你还需要手动开启(term_mouse_enable),并且自行处理鼠标事件(term_event_poll).
  }

  {**
   * term_support_mouse
   *
   * @desc 检查指定终端是否支持鼠标
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_focus_1004(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_support_focus_1004: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_support_paste_2004(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_support_paste_2004: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_support_sync_update(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_support_sync_update: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_support_mouse(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_mouse
   *
   * @desc 检查是否支持鼠标
   *
   * @return 返回是否支持
   *}
  function term_support_mouse: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

    {**
   * term_mouse_enable
   *
   * @desc 启用指定终端鼠标
   *
   * @params
   *  - aTerm    终端实例指针
   *  - aEnabled 是否启用
   *
   * @return 返回是否启用成功
   *}
  function term_mouse_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean; overload;

  {**
   * term_mouse_enable
   *
   * @desc 启用鼠标
   *
   * @params
   *  - aEnabled 是否启用
   *
   * @return 返回是否启用成功
   *}
  function term_mouse_enable(aEnabled: Boolean): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_mouse_enable
   *
   * @desc 启用指定终端鼠标
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否启用成功
   *}
  function term_mouse_enable(aTerm: pterm_t):Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_mouse_enable
   *
   * @desc 启用鼠标
   *
   * @return 返回是否启用成功
   *}
  function term_mouse_enable: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_mouse_disable
   *
   * @desc 禁用指定终端鼠标
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否禁用成功
   *}
  function term_mouse_disable(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_mouse_disable
   *
   * @desc 禁用鼠标
   *
   * @return 返回是否禁用成功
   *}
  function term_mouse_disable: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  { 便捷启用/关闭 SGR 鼠标与拖动跟踪 }
  function term_mouse_sgr_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean; overload;
  function term_mouse_sgr_enable(aEnabled: Boolean): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_mouse_drag_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean; overload;
  function term_mouse_drag_enable(aEnabled: Boolean): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  { 便捷启用/关闭 焦点事件 }
  function term_focus_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean; overload;
  function term_focus_enable(aEnabled: Boolean): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  { 便捷启用/关闭 括号粘贴（Bracketed Paste） }
  function term_paste_bracket_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean; overload;
  function term_paste_bracket_enable(aEnabled: Boolean): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  { 同步输出（Synchronized Updates）：终端支持时可减少闪烁 }
  function term_sync_update_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean; overload;
  function term_sync_update_enable(aEnabled: Boolean): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  { 模式守卫：创建时启用一组模式，销毁时自动还原 }
  type
    term_mode_flag_t = (
      tm_mouse_enable_base,   // 启用基础鼠标（Windows: ENABLE_MOUSE_INPUT；Unix: backend 鼠标开关）
      tm_mouse_button_drag,   // ?1002h / ?1002l
      tm_mouse_sgr_1006,      // ?1006h / ?1006l
      tm_focus_1004,          // ?1004h / ?1004l
      tm_paste_2004           // ?2004h / ?2004l
    );
    term_mode_flags_t = set of term_mode_flag_t;

    TTermModeGuard = record
      FTerm: pterm_t;
      FFlags: term_mode_flags_t;
      // 记录 acquire 前的原始状态，用于 LIFO 恢复
      PrevMouseBase: Boolean;
      PrevMouseDrag: Boolean;
      PrevMouseSGR:  Boolean;
      PrevFocus:     Boolean;
      PrevPaste:     Boolean;
    end;

  function term_mode_guard_acquire(aTerm: pterm_t; const aFlags: term_mode_flags_t): TTermModeGuard;
  function term_mode_guard_acquire_current(const aFlags: term_mode_flags_t): TTermModeGuard; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  procedure term_mode_guard_done(var aGuard: TTermModeGuard); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}



  ///
  /// title 标题
  ///

  {
    大部分的终端都支持标题, 但是也有一些终端不支持标题,还有一些终端甚至支持设置图标.
    你需要在程序初始化时检查环境是否支持标题(term_support_title 或者 term_support_compatible(tc_title)).
  }


  {**
   * term_support_title
   *
   * @desc 检查指定终端是否支持标题
   *
   * @return 返回是否支持
   *}
  function term_support_title(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_title
   *
   * @desc 检查是否支持标题
   *
   * @return 返回是否支持
   *}
  function term_support_title: boolean; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_title
   *
   * @desc 获取指定终端标题
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回终端标题
   *}
  function term_title(aTerm: pterm_t): string; overload;

  {**
   * term_title
   *
   * @desc 获取终端标题
   *
   * @return 返回终端标题
   *}
  function term_title: string; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_title_set
   *
   * @desc 检查指定终端是否支持标题设置
   *
   * @return 返回是否支持
   *}
  function term_support_title_set(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_title_set
   *
   * @desc 检查是否支持标题设置
   *
   * @return 返回是否支持
   *}
  function term_support_title_set: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_title_set
   *
   * @desc 设置指定终端标题
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aTitle 标题
   *
   * @return 返回是否设置成功
   *}
  function term_title_set(aTerm: pterm_t; const aTitle: string): boolean; overload;

  {**
   * term_title_set
   *
   * @desc 设置终端标题
   *
   * @params
   *  - aTitle 标题
   *
   * @return 返回是否设置成功
   *}
  function term_title_set(const aTitle: string): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_icon_set
   *
   * @desc 检查指定终端是否支持图标设置
   *
   * @return 返回是否支持
   *}
  function term_support_icon_set(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_icon_set
   *
   * @desc 检查是否支持图标设置
   *
   * @return 返回是否支持
   *}
  function term_support_icon_set: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_icon_set
   *
   * @desc 设置指定终端图标
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aIcon  图标
   *
   * @return 返回是否设置成功
   *}
  function term_icon_set(aTerm: pterm_t; const aIcon: string): boolean; overload;

  {**
   * term_icon_set
   *
   * @desc 设置图标
   *
   * @params
   *  - aIcon 图标
   *
   * @return 返回是否设置成功
   *}
  function term_icon_set(const aIcon: string): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  ///
  /// scroll region 滚动区域
  ///

  {**
   * term_scroll_region_set
   *
   * @desc 设置滚动区域（0-based 输入，内部按 DECSTBM 输出 1-based）
   * @return 是否成功（要求 ANSI 能力）
   *}
  function term_scroll_region_set(aTerm: pterm_t; aTop, aBottom: term_size_t): boolean; overload;
  function term_scroll_region_set(aTop, aBottom: term_size_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  ///
  /// scroll region rollback
  ///
  function term_scroll_region_reset(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_scroll_region_reset: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  ///
  /// size 大小
  ///

  {
    windows 下还没有发现设置终端大小的方法,谁能告诉我?
  }


  {**
   * term_support_size
   *
   * @desc 检查指定终端是否支持大小获取
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_size(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_size
   *
   * @desc 检查是否支持大小获取
   *
   * @return 返回是否支持
   *}
  function term_support_size: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_size
   *
   * @desc 获取指定终端大小
   *
   * @params
   *  - aTerm   终端实例指针
   *  - aWidth  宽度
   *  - aHeight 高度
   *
   * @return 返回终端大小
   *}
  function term_size(aTerm: pterm_t; var aWidth, aHeight: term_size_t): boolean; overload;

  {**
   * term_size
   *
   * @desc 获取终端大小
   *
   * @params
   *  - aWidth  宽度
   *  - aHeight 高度
   *
   * @return 返回终端大小
   *}
  function term_size(var aWidth, aHeight: term_size_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_size_width
   *
   * @desc 获取指定终端宽度
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回终端宽度
   *}
  function term_size_width(aTerm: pterm_t): term_size_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_size_width
   *
   * @desc 获取宽度
   *
   * @return 返回宽度
   *}
  function term_size_width: term_size_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_size_height
   *
   * @desc 获取指定终端高度
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回终端高度
   *}
  function term_size_height(aTerm: pterm_t): term_size_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_size_height
   *
   * @desc 获取高度
   *
   * @return 返回高度
   *}
  function term_size_height: term_size_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_size_set
   *
   * @desc 检查指定终端是否支持大小设置
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_size_set(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_size_set
   *
   * @desc 检查是否支持大小设置
   *
   * @return 返回是否支持
   *}
  function term_support_size_set: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_size_set
   *
   * @desc 设置指定终端大小
   *
   * @params
   *  - aTerm   终端实例指针
   *  - aWidth  宽度
   *  - aHeight 高度
   *
   * @return 返回是否设置成功
   *}
  function term_size_set(aTerm: pterm_t; aWidth, aHeight: term_size_t): boolean; overload;

  {**
   * term_size_set
   *
   * @desc 设置终端大小
   *
   * @params
   *  - aWidth  宽度
   *  - aHeight 高度
   *
   * @return 返回是否设置成功
   *}
  function term_size_set(aWidth, aHeight: term_size_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  ///
  /// cursor 光标
  ///


  {**
   * term_cursor_save
   *
   * @desc 保存指定终端光标位置
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_save(aTerm: pterm_t); overload;

  {**
   * term_cursor_save
   *
   * @desc 保存光标位置
   *}
  procedure term_cursor_save; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_restore
   *
   * @desc 恢复指定终端光标位置
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_restore(aTerm: pterm_t); overload;

  {**
   * term_cursor_restore
   *
   * @desc 恢复光标位置
   *}
  procedure term_cursor_restore; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_push
   *
   * @desc 压栈保存指定终端光标位置
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_push(aTerm: pterm_t); overload;

  {**
   * term_cursor_push
   *
   * @desc 压栈保存光标位置
   *}
  procedure term_cursor_push; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_pop
   *
   * @desc 出栈恢复指定终端光标位置
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_pop(aTerm: pterm_t); overload;

  {**
   * term_cursor_pop
   *
   * @desc 出栈恢复光标位置
   *}
  procedure term_cursor_pop; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor
   *
   * @desc 获取指定终端光标位置
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aX    位置x
   *  - aY    位置y
   *
   * @return 返回是否获取成功
   *}
  function term_cursor(aTerm: pterm_t; var aX, aY: term_size_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor
   *
   * @desc 获取光标位置
   *
   * @params
   *  - aX 位置x
   *  - aY 位置y
   *
   * @return 返回是否获取成功
   *}
  function term_cursor(var aX, aY: term_size_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor
   *
   * @desc 获取光标位置
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aPoint 光标位置
   *
   * @return 返回是否获取成功
   *}
  function term_cursor(aTerm: pterm_t; var aPoint: term_point_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor
   *
   * @desc 获取光标位置
   *
   * @params
   *  - aPoint 光标位置
   *
   * @return 返回是否获取成功
   *}
  function term_cursor(var aPoint: term_point_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_x
   *
   * @desc 获取指定终端光标x位置
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回光标x位置,如果失败,返回0
   *}
  function term_cursor_x(aTerm: pterm_t): term_size_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_x
   *
   * @desc 获取光标x位置
   *
   * @return 返回光标x位置,如果失败,返回0
   *}
  function term_cursor_x: term_size_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_y
   *
   * @desc 获取指定终端光标y位置
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回光标y位置,如果失败,返回0
   *}
  function term_cursor_y(aTerm: pterm_t): term_size_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_y
   *
   * @desc 获取光标y位置
   *
   * @return 返回光标y位置,如果失败,返回0
   *}
  function term_cursor_y: term_size_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_set
   *
   * @desc 设置指定终端光标位置
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aX    位置x
   *  - aY    位置y
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_set(aTerm: pterm_t; aX, aY: term_size_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_set
   *
   * @desc 设置光标位置
   *
   * @params
   *  - aX 位置x
   *  - aY 位置y
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_set(aX, aY: term_size_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_set
   *
   * @desc 设置指定终端光标位置
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aPoint 光标位置
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_set(aTerm: pterm_t; const aPoint: term_point_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_set
   *
   * @desc 设置光标位置
   *
   * @params
   *  - aPoint 光标位置
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_set(const aPoint: term_point_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_x_set
   *
   * @desc 设置指定终端光标x位置
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aX    位置x
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_x_set(aTerm: pterm_t; aX: term_size_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_x_set
   *
   * @desc 设置光标x位置
   *
   * @params
   *  - aX 位置x
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_x_set(aX: term_size_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_y_set
   *
   * @desc 设置指定终端光标y位置
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aY    位置y
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_y_set(aTerm: pterm_t; aY: term_size_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_y_set
   *
   * @desc 设置光标y位置
   *
   * @params
   *  - aY 位置y
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_y_set(aY: term_size_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_home
   *
   * @desc 指定终端移动光标到终端原点 (x=0, y=0)
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_home(aTerm: pterm_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_home
   *
   * @desc 移动光标到终端原点 (x=0, y=0)
   *}
  procedure term_cursor_home; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_up
   *
   * @desc 指定终端向上移动光标
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aCount 移动次数
   *}
  procedure term_cursor_up(aTerm: pterm_t; aCount: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_up
   *
   * @desc 向上移动光标
   *
   * @params
   *  - aCount 移动次数
   *}
  procedure term_cursor_up(aCount: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_up
   *
   * @desc 指定终端向上移动光标1次
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_up(aTerm: pterm_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_up
   *
   * @desc 向上移动光标1次
   *}
  procedure term_cursor_up; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_left
   *
   * @desc 指定终端向左移动光标
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aCount 移动次数
   *}
  procedure term_cursor_left(aTerm: pterm_t; aCount: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_left
   *
   * @desc 向左移动光标
   *
   * @params
   *  - aCount 移动次数
   *}
  procedure term_cursor_left(aCount: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_left
   *
   * @desc 指定终端向左移动光标1次
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_left(aTerm: pterm_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_left
   *
   * @desc 向左移动光标1次
   *}
  procedure term_cursor_left; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_down
   *
   * @desc 指定终端向下移动光标
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aCount 移动次数
   *}
  procedure term_cursor_down(aTerm: pterm_t; aCount: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_down
   *
   * @desc 向下移动光标
   *
   * @params
   *  - aCount 移动次数
   *}
  procedure term_cursor_down(aCount: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_down
   *
   * @desc 指定终端向下移动光标1次
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_down(aTerm: pterm_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_down
   *
   * @desc 向下移动光标1次
   *}
  procedure term_cursor_down; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_right
   *
   * @desc 指定终端向右移动光标
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aCount 移动次数
   *}
  procedure term_cursor_right(aTerm: pterm_t; aCount: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_right
   *
   * @desc 向右移动光标
   *
   * @params
   *  - aCount 移动次数
   *}
  procedure term_cursor_right(aCount: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_right
   *
   * @desc 指定终端向右移动光标1次
   *}
  procedure term_cursor_right(aTerm: pterm_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_right
   *
   * @desc 向右移动光标1次
   *}
  procedure term_cursor_right; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line
   *
   * @desc 指定终端移动光标到指定行
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aLine 行位置
   *}
  procedure term_cursor_line(aTerm: pterm_t; aLine: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line
   *
   * @desc 移动光标到指定行
   *}
  procedure term_cursor_line(aLine: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_next
   *
   * @desc 指定终端向下移动光标
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aCount 移动次数
   *}
  procedure term_cursor_line_next(aTerm: pterm_t; aCount: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_next
   *
   * @desc 向下移动光标
   *
   * @params
   *  - aCount 移动次数
   *}
  procedure term_cursor_line_next(aCount: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_next
   *
   * @desc 指定终端向下移动光标1次
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_line_next(aTerm: pterm_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_next
   *
   * @desc 向下移动光标1次
   *}
  procedure term_cursor_line_next; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_prev
   *
   * @desc 指定终端向上移动光标
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aCount 移动次数
   *}
  procedure term_cursor_line_prev(aTerm: pterm_t; aCount: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_prev
   *
   * @desc 向上移动光标
   *
   * @params
   *  - aCount 移动次数
   *}
  procedure term_cursor_line_prev(aCount: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_prev
   *
   * @desc 指定终端向上移动光标1次
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_line_prev(aTerm: pterm_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_line_prev
   *
   * @desc 向上移动光标1次
   *}
  procedure term_cursor_line_prev; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_col
   *
   * @desc 指定终端移动光标到当前行指定列
   *
   * @params
   *  - aTerm    终端实例指针
   *  - aColumn  列
   *}
  procedure term_cursor_col(aTerm: pterm_t; aColumn: term_size_t); overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_col
   *
   * @desc 移动光标到当前行指定列
   *}
  procedure term_cursor_col(aColumn: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  {**
   * term_cursor_visible_set
   *
   * @desc 设置指定终端光标可见
   *
   * @params
   *  - aTerm    终端实例指针
   *  - aVisible 是否可见
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_visible_set(aTerm: pterm_t; aVisible: Boolean): Boolean; overload;

  {**
   * term_cursor_visible_set
   *
   * @desc 设置光标可见
   *
   * @params
   *  - aVisible 是否可见
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_visible_set(aVisible: Boolean): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_show
   *
   * @desc 启用指定终端光标可见
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否启用成功
   *}
  function term_cursor_show(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_show
   *
   * @desc 启用光标可见
   *
   * @return 返回是否启用成功
   *}
  function term_cursor_show: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_hide
   *
   * @desc 禁用指定终端光标可见
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否禁用成功
   *}
  function term_cursor_hide(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_hide
   *
   * @desc 禁用光标可见
   *
   * @return 返回是否禁用成功
   *}
  function term_cursor_hide: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
   * term_cursor_shape_set
   *
   * @desc 设置指定终端光标形状
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aShape 形状
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_shape_set(aTerm: pterm_t; aShape: term_cursor_shape_t): Boolean; overload;

  {**
   * term_cursor_shape_set
   *
   * @desc 设置光标形状
   *
   * @params
   *  - aShape 形状
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_shape_set(aShape: term_cursor_shape_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_shape_reset
   *
   * @desc 重置指定终端光标形状
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_cursor_shape_reset(aTerm: pterm_t);

  {**
   * term_cursor_shape_reset
   *
   * @desc 重置终端光标形状
   *}
  procedure term_cursor_shape_reset;

  {**
  * term_cursor_size_set
  *
  * @desc 设置指定终端光标大小(厚度)
  *
  * @params
  *  - aTerm 终端实例指针
  *  - aSize 大小
  *
  * @return 返回是否设置成功
  *
  * @remark 鉴于winapi老旧控制台实在没有修改光标的接口,预留一个唯一接口
  *         不建议使用
  *}
  function term_cursor_size_set(aTerm: pterm_t; aSize: UInt8): Boolean; overload;

  {**
  * term_cursor_size_set
  *
  * @desc 设置光标大小
  *
  * @params
  *  - aSize 大小
  *
  * @return 返回是否设置成功
  *
  * @remark 鉴于winapi老旧控制台实在没有修改光标的接口,预留一个唯一接口
  *         不建议使用
  *}
  function term_cursor_size_set(aSize: UInt8): Boolean; overload;

  {**
   * term_cursor_blink_set
   *
   * @desc 设置指定终端光标闪烁
   *
   * @params
   *  - aTerm    终端实例指针
   *  - aBlink   是否闪烁
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_blink_set(aTerm: pterm_t; aBlink: Boolean): Boolean; overload;

  {**
   * term_cursor_blink_set
   *
   * @desc 设置光标闪烁
   *
   * @params
   *  - aBlink 是否闪烁
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_blink_set(aBlink: Boolean):Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_blink_enable
   *
   * @desc 启用光标闪烁
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否启用成功
   *}
  function term_cursor_blink_enable(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_blink_enable
   *
   * @desc 启用光标闪烁
   *
   * @return 返回是否启用成功
   *}
  function term_cursor_blink_enable: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_blink_disable
   *
   * @desc 禁用光标闪烁
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否禁用成功
   *}
  function term_cursor_blink_disable(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_blink_disable
   *
   * @desc 禁用光标闪烁
   *
   * @return 返回是否禁用成功
   *}
  function term_cursor_blink_disable: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {
    注意：Windows 终端不支持设置终端光标颜色
    此功能在某些终端（如 Linux/unix 的的某些终端）中可用
  }

  {**
   * term_cursor_color_palette_set
   *
   * @desc 设置指定终端光标调色板索引
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aIndex 调色板索引
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_color_palette_set(aTerm: pterm_t; aIndex: term_color_palette_index_t): Boolean; overload;

  {**
   * term_cursor_color_palette_set
   *
   * @desc 设置终端光标颜色
   *
   * @params
   *  - aIndex 调色板索引
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_color_palette_set(aIndex: term_color_palette_index_t): Boolean; overload;  {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_cursor_color_set
   *
   * @desc 设置指定终端光标24bit真彩色
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aColor 24bit真彩色
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_color_set(aTerm: pterm_t; const aColor: term_color_24bit_t): Boolean; overload;

  {**
   * term_cursor_color_set
   *
   * @desc 设置指定终端光标24bit真彩色
   *
   * @params
   *  - aColor 24bit真彩色
   *
   * @return 返回是否设置成功
   *}
  function term_cursor_color_set(const aColor: term_color_24bit_t): Boolean; overload;  {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  ///
  /// alternate_screen 备用屏幕
  ///


  {**
   * term_support_alternate_screen
   *
   * @desc 检查指定终端是否支持交替屏幕
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_alternate_screen(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_alternate_screen
   *
   * @desc 检查是否支持交替屏幕
   *
   * @return 返回是否支持
   *}
  function term_support_alternate_screen: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_alternate_screen_enable
   *
   * @desc 启用交替屏幕
   *}
  function term_alternate_screen_enable(aTerm: pterm_t; aEnable: boolean): boolean; overload;
  function term_alternate_screen_enable(aEnable: boolean): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_alternate_screen_enable(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_alternate_screen_enable: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_alternate_screen_disable
   *
   * @desc 禁用交替屏幕
   *}
  function term_alternate_screen_disable(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_alternate_screen_disable: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {** Raw Mode 切换 **}
  function term_raw_mode_enable(aTerm: pterm_t; aEnable: boolean): boolean; overload;
  function term_raw_mode_enable(aEnable: boolean): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_raw_mode_enable(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_raw_mode_disable(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
  function term_raw_mode_disable: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  ///
  /// color 颜色
  ///


  {**
   * term_support_color
   *
   * @desc 检查指定终端是否支持颜色
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_color(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color
   *
   * @desc 检查是否支持颜色
   *
   * @return 返回是否支持
   *}
  function term_support_color: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_16
   *
   * @desc 检查指定终端是否支持16色
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_color_16(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_16
   *
   * @desc 检查是否支持16色
   *
   * @return 返回是否支持
   *}
  function term_support_color_16: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_256
   *
   * @desc 检查指定终端是否支持256色
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_color_256(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_256
   *
   * @desc 检查是否支持256色
   *
   * @return 返回是否支持
   *}
  function term_support_color_256: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_24bit
   *
   * @desc 检查指定终端是否支持真彩色
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_color_24bit(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_24bit
   *
   * @desc 检查是否支持真彩色
   *
   * @return 返回是否支持
   *}
  function term_support_color_24bit: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}



  ///
  /// palette 调色板
  ///


  {**
   * term_support_color_16_palette
   *
   * @desc 检查指定终端是否支持16色调色板
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_color_16_palette(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_16_palette
   *
   * @desc 检查是否支持16色调色板
   *
   * @return 返回是否支持
   *}
  function term_support_color_16_palette: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_256_palette
   *
   * @desc 检查指定终端是否支持256色调色板
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_color_256_palette(aTerm: pterm_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_256_palette
   *
   * @desc 检查是否支持256色调色板
   *
   * @return 返回是否支持
   *}
  function term_support_color_256_palette: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_palette_stack
   *
   * @desc 检查指定终端是否支持调色板栈
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @return 返回是否支持
   *}
  function term_support_color_palette_stack(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_support_color_palette_stack
   *
   * @desc 检查是否支持调色板栈
   *
   * @return 返回是否支持
   *}
  function term_support_color_palette_stack: boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_push
   *
   * @desc 指定终端调色板入栈保存
   *
   * @params
   *  - aTerm       终端实例指针
   *  - aStackIndex 栈索引
   *
   * @remark 如果后端不支持调色板栈,将不会入栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制),超过容量将丢弃栈尾
   *         如果栈索引为0,将执行入栈操作,非0则直接写入到栈索引位置
   *}
  procedure term_color_palette_push(aTerm: pterm_t; aStackIndex: term_color_palette_stack_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_push
   *
   * @desc 调色板入栈保存
   *
   * @params
   *  - aStackIndex 栈索引
   *
   * @remark 如果后端不支持调色板栈,将不会入栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制),超过容量将丢弃栈尾
   *         如果栈索引为0,将执行入栈操作,非0则直接写入到栈索引位置
   *}
  procedure term_color_palette_push(aStackIndex: term_color_palette_stack_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_push
   *
   * @desc 调色板入栈保存
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @remark 如果后端不支持调色板栈,将不会入栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制),超过容量将丢弃栈尾
   *}
  procedure term_color_palette_push(aTerm: pterm_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_push
   *
   * @desc 调色板入栈保存
   *
   * @remark 如果后端不支持调色板栈,将不会入栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制),超过容量将丢弃栈尾
   *}
  procedure term_color_palette_push; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_pop
   *
   * @desc 指定终端调色板出栈恢复
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aStackIndex 栈索引
   *
   * @remark 如果后端不支持调色板栈,将不会出栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制)
   *         如果栈索引为0,将执行出栈操作,非0则直接从栈索引位置读取恢复
   *}
  procedure term_color_palette_pop(aTerm: pterm_t; aStackIndex: term_color_palette_stack_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_pop
   *
   * @desc 调色板出栈恢复
   *
   * @params
   *  - aStackIndex 栈索引
   *
   * @remark 如果后端不支持调色板栈,将不会出栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制)
   *         如果栈索引为0,将执行出栈操作,非0则直接从栈索引位置读取恢复
   *}
  procedure term_color_palette_pop(aStackIndex: term_color_palette_stack_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_pop
   *
   * @desc 指定终端调色板出栈恢复
   *
   * @params
   *  - aTerm 终端实例指针
   *
   * @remark 如果后端不支持调色板栈,将不会出栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制)
   *         如果栈索引为0,将执行出栈操作,非0则直接从栈索引位置读取恢复
   *}
  procedure term_color_palette_pop(aTerm: pterm_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_pop
   *
   * @desc 调色板出栈恢复
   *
   * @remark 如果后端不支持调色板栈,将不会出栈
   *         调色板栈最大容量为10(xterm默认值,其他后端如果实现,应模拟这个行为和限制)
   *         如果栈索引为0,将执行出栈操作,非0则直接从栈索引位置读取恢复
   *}
  procedure term_color_palette_pop; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_set
   *
   * @desc 设置指定终端调色板
   *
   * @params
   *  - aTerm   终端实例指针
   *  - aIndex  颜色索引
   *  - aColor  颜色
   *
   * @return 返回是否设置成功
   *}
  function term_color_palette_set(aTerm: pterm_t; aIndex: term_color_palette_index_t; const aColor: term_color_24bit_t): boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_palette_set
   *
   * @desc 设置调色版
   *
   * @params
   *  - aIndex  颜色索引
   *  - aColor  颜色
   *
   * @return 返回是否设置成功
   *}
  function term_color_palette_set(aIndex: term_color_palette_index_t; const aColor: term_color_24bit_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  ///
  /// ANSI Color System Integration ANSI 颜色系统集成
  ///

  {**
   * term_color_fg_16 设置 16 色前景色
   *
   * @params
   *  - aTerm  终端实例
   *  - aColor 颜色索引 (0-15)
   *
   * @return 返回是否设置成功
   *}
  function term_color_fg_16(aTerm: pterm_t; aColor: Byte): Boolean; overload;

  {**
   * term_color_fg_16 设置 16 色前景色
   *
   * @params
   *  - aColor 颜色索引 (0-15)
   *
   * @return 返回是否设置成功
   *}
  function term_color_fg_16(aColor: Byte): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_bg_16 设置 16 色背景色
   *
   * @params
   *  - aTerm  终端实例
   *  - aColor 颜色索引 (0-15)
   *
   * @return 返回是否设置成功
   *}
  function term_color_bg_16(aTerm: pterm_t; aColor: Byte): Boolean; overload;

  {**
   * term_color_bg_16 设置 16 色背景色
   *
   * @params
   *  - aColor 颜色索引 (0-15)
   *
   * @return 返回是否设置成功
   *}
  function term_color_bg_16(aColor: Byte): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_fg_256 设置 256 色前景色
   *
   * @params
   *  - aTerm  终端实例
   *  - aColor 颜色索引 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_fg_256(aTerm: pterm_t; aColor: Byte): Boolean; overload;

  {**
   * term_color_fg_256 设置 256 色前景色
   *
   * @params
   *  - aColor 颜色索引 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_fg_256(aColor: Byte): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_bg_256 设置 256 色背景色
   *
   * @params
   *  - aTerm  终端实例
   *  - aColor 颜色索引 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_bg_256(aTerm: pterm_t; aColor: Byte): Boolean; overload;

  {**
   * term_color_bg_256 设置 256 色背景色
   *
   * @params
   *  - aColor 颜色索引 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_bg_256(aColor: Byte): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_fg_rgb 设置 24 位真彩色前景色
   *
   * @params
   *  - aTerm  终端实例
   *  - aRed   红色分量 (0-255)
   *  - aGreen 绿色分量 (0-255)
   *  - aBlue  蓝色分量 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_fg_rgb(aTerm: pterm_t; aRed, aGreen, aBlue: Byte): Boolean; overload;

  {**
   * term_color_fg_rgb 设置 24 位真彩色前景色
   *
   * @params
   *  - aRed   红色分量 (0-255)
   *  - aGreen 绿色分量 (0-255)
   *  - aBlue  蓝色分量 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_fg_rgb(aRed, aGreen, aBlue: Byte): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_bg_rgb 设置 24 位真彩色背景色
   *
   * @params
   *  - aTerm  终端实例
   *  - aRed   红色分量 (0-255)
   *  - aGreen 绿色分量 (0-255)
   *  - aBlue  蓝色分量 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_bg_rgb(aTerm: pterm_t; aRed, aGreen, aBlue: Byte): Boolean; overload;

  {**
   * term_color_bg_rgb 设置 24 位真彩色背景色
   *
   * @params
   *  - aRed   红色分量 (0-255)
   *  - aGreen 绿色分量 (0-255)
   *  - aBlue  蓝色分量 (0-255)
   *
   * @return 返回是否设置成功
   *}
  function term_color_bg_rgb(aRed, aGreen, aBlue: Byte): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_reset 重置颜色到默认值
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否重置成功
   *}
  function term_color_reset(aTerm: pterm_t): Boolean; overload;

  {**
   * term_color_reset 重置颜色到默认值
   *
   * @return 返回是否重置成功
   *}
  function term_color_reset: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  // 预定义颜色便捷函数 Predefined Color Convenience Functions

  {**
   * term_color_black 设置前景色为黑色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_black(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_black 设置前景色为黑色
   *
   * @return 返回是否设置成功
   *}
  function term_color_black: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_red 设置前景色为红色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_red(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_red 设置前景色为红色
   *
   * @return 返回是否设置成功
   *}
  function term_color_red: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_green 设置前景色为绿色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_green(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_green 设置前景色为绿色
   *
   * @return 返回是否设置成功
   *}
  function term_color_green: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_yellow 设置前景色为黄色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_yellow(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_yellow 设置前景色为黄色
   *
   * @return 返回是否设置成功
   *}
  function term_color_yellow: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_blue 设置前景色为蓝色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_blue(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_blue 设置前景色为蓝色
   *
   * @return 返回是否设置成功
   *}
  function term_color_blue: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_magenta 设置前景色为洋红色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_magenta(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_magenta 设置前景色为洋红色
   *
   * @return 返回是否设置成功
   *}
  function term_color_magenta: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_cyan 设置前景色为青色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_cyan(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_cyan 设置前景色为青色
   *
   * @return 返回是否设置成功
   *}
  function term_color_cyan: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_white 设置前景色为白色
   *
   * @params
   *  - aTerm 终端实例
   *
   * @return 返回是否设置成功
   *}
  function term_color_white(aTerm: pterm_t): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_color_white 设置前景色为白色
   *
   * @return 返回是否设置成功
   *}
  function term_color_white: Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  ///
  /// attr 属性
  ///

  {
    attr 是一个状态机输出属性, 包括 [前景颜色,背景颜色,样式].
    attr 接口被设计支持 [16色,256色,24位真彩色] 的色彩能力, 并提供兼容策略, 当色彩能力不足时会降级处理.
    当你调用24位真彩色接口的时候,尽管后端环境不支持24位真彩色,依然会降级处理到色彩能力能处理的近似色.
  }

  {**
   * term_attr_push
   *
   * @desc 指定终端属性入栈保存
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_attr_push(aTerm: pterm_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_push
   *
   * @desc 属性入栈保存
   *
   *}
  procedure term_attr_push; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_pop
   *
   * @desc 指定终端属性弹出恢复
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_attr_pop(aTerm: pterm_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_pop
   *
   * @desc 属性弹出恢复
   *
   *}
  procedure term_attr_pop; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置指定终端属性(16色调色板)
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aAttr 属性
   *
   * @remark 如果后端没有色彩能力,将不会设置颜色
   *         如果后端没有文本样式能力,将不会设置文本样式
   *}
  procedure term_attr_set(aTerm: pterm_t; const aAttr: term_attr_16_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置属性(16色调色板)
   *
   * @params
   *  - aAttr 属性
   *
   * @remark 如果后端没有色彩能力,将不会设置颜色
   *         如果后端没有文本样式能力,将不会设置文本样式
   *}
  procedure term_attr_set(const aAttr: term_attr_16_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置指定终端属性(256色调色板)
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aAttr 属性
   *
   * @remark 如果后端不支持256色,会降级处理,转为16调色板近似索引
   *         如果后端没有文本样式能力,将不会设置文本样式
   *}
  procedure term_attr_set(aTerm: pterm_t; const aAttr: term_attr_256_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置属性(256色调色板)
   *
   * @params
   *  - aAttr 属性
   *
   * @remark 如果后端不支持256色,会降级处理,转为16调色板近似索引
   *         如果后端没有文本样式能力,将不会设置文本样式
   *}
  procedure term_attr_set(const aAttr: term_attr_256_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置指定终端属性(24位真彩色)
   *
   * @params
   *  - aTerm 终端实例指针
   *  - aAttr 属性
   *
   * @remark 如果后端不支持24位真彩色,会降级处理,转为256调色板近似索引
   *         如果后端没有文本样式能力,将不会设置文本样式
   *}
  procedure term_attr_set(aTerm: pterm_t; const aAttr: term_attr_24bit_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置属性(24位真彩色)
   *
   * @params
   *  - aAttr 属性
   *
   * @remark 如果后端不支持24位真彩色,会降级处理,转为256调色板近似索引
   *         如果后端没有文本样式能力,将不会设置文本样式
   *}
  procedure term_attr_set(const aAttr: term_attr_24bit_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置指定终端属性(调色板)
   *
   * @params
   *  - aTerm       终端实例指针
   *  - aForeground 前景颜色
   *  - aBackground 背景颜色
   *  - aStyles     文本样式
   *}
  procedure term_attr_set(aTerm: pterm_t; aForeground, aBackground: term_color_palette_index_t; const aStyles: term_attr_styles_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置属性(调色板)
   *
   * @params
   *  - aForeground 前景颜色
   *  - aBackground 背景颜色
   *  - aStyles     文本样式
   *}
  procedure term_attr_set(aForeground, aBackground: term_color_palette_index_t; const aStyles: term_attr_styles_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置指定终端属性(24位真彩色)
   *
   * @params
   *  - aTerm       终端实例指针
   *  - aForeground 前景颜色
   *  - aBackground 背景颜色
   *  - aStyles     文本样式
   *}
  procedure term_attr_set(aTerm: pterm_t; aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_set
   *
   * @desc 设置属性(24位真彩色)
   *
   * @params
   *  - aForeground 前景颜色
   *  - aBackground 背景颜色
   *  - aStyles     文本样式
   *}
  procedure term_attr_set(const aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {
    设置attr
    单独设置 前景色/背景色/文本样式 并不会清除当前状态的其他属性,只会替换前景色/背景色/文本样式,其他属性保持不变.
    调用 term_attr_reset/term_attr_foreground_reset/term_attr_background_reset/term_attr_styles_reset 来重置其他属性.
    调用 term_attr_set 来设置所有属性.
  }

  {**
   * term_attr_foreground_set
   *
   * @desc 设置指定终端前景(调色板索引)
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aColor 调色板索引
   *}
  procedure term_attr_foreground_set(aTerm: pterm_t; aColor: term_color_palette_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_foreground_set
   *
   * @desc 设置前景(调色板索引)
   *
   * @params
   *  - aColor 调色板索引
   *}
  procedure term_attr_foreground_set(aColor: term_color_palette_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_foreground_set
   *
   * @desc 设置指定终端前景(24bit真彩色)
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aColor 24bit真彩色
   *}
  procedure term_attr_foreground_set(aTerm: pterm_t; const aColor: term_color_24bit_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_foreground_set
   *
   * @desc 设置前景(24bit真彩色)
   *
   * @params
   *  - aColor 24bit真彩色
   *}
  procedure term_attr_foreground_set(const aColor: term_color_24bit_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_background_set
   *
   * @desc 设置指定终端背景(调色板索引)
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aColor 调色板索引
   *}
  procedure term_attr_background_set(aTerm: pterm_t; aColor: term_color_palette_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_background_set
   *
   * @desc 设置背景(调色板索引)
   *
   * @params
   *  - aColor 调色板索引
   *}
  procedure term_attr_background_set(aColor: term_color_palette_index_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_background_set
   *
   * @desc 设置指定终端背景(24bit真彩色)
   *
   * @params
   *  - aTerm  终端实例指针
   *  - aColor 24bit真彩色
   *}
  procedure term_attr_background_set(aTerm: pterm_t; const aColor: term_color_24bit_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_background_set
   *
   * @desc 设置背景(24bit真彩色)
   *
   * @params
   *  - aColor 24bit真彩色
   *}
  procedure term_attr_background_set(const aColor: term_color_24bit_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  {**
   * term_attr_reset
   *
   * @desc 重置指定终端属性
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_attr_reset(aTerm: pterm_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_reset
   *
   * @desc 重置属性
   *}
  procedure term_attr_reset; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_foreground_reset
   *
   * @desc 重置指定终端前景色
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_attr_foreground_reset(aTerm: pterm_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_foreground_reset
   *
   * @desc 重置前景色
   *}
  procedure term_attr_foreground_reset; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_background_reset
   *
   * @desc 重置指定终端背景色
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_attr_background_reset(aTerm: pterm_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_background_reset
   *
   * @desc 重置背景色
   *}
  procedure term_attr_background_reset; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_styles_reset
   *
   * @desc 重置指定终端文本样式
   *
   * @params
   *  - aTerm 终端实例指针
   *}
  procedure term_attr_styles_reset(aTerm: pterm_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
   * term_attr_styles_reset
   *
   * @desc 重置文本样式
   *}
  procedure term_attr_styles_reset; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  { UCS4 转换 }

  {**
   * ucs4Char_to_utf8
   *
   * @desc 将UCS4字符转换为UTF8字符串
   *
   * @params
   *  - aUCS4     UCS4字符
   *  - aUtf8     UTF8字符串
   *  - aUtf8Size UTF8字符串大小
   *
   * @return 返回UTF8字符串长度
   *
   * @remark 如果aUtf8Size小于实际需要的UTF8字符串长度,将不会转换,并返回-1
   *}
  function ucs4Char_to_utf8(aUCS4: UCS4Char; aUtf8: PAnsiChar; aUtf8Size: SizeUInt): SizeInt; overload;

  {**
  * ucs4Char_to_utf8
  *
  * @desc 将UCS4字符转换为UTF8字符串
  *
  * @params
  *  - ucs4 UCS4字符
  *}
  function ucs4Char_to_utf8(aUCS4: UCS4Char): ansistring; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

  {**
  * ucs4String_to_utf8
  *
  * @desc 将UCS4字符串转换为UTF8字符串
  *
  * @params
  *  - ucs4 UCS4字符串
  *}
  function ucs4String_to_utf8(const aUCS4: UCS4String): ansistring;


///
/// 写入
///


{**
 * term_write
 *
 * @desc 指定终端写入数据(ANSI字符串)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aLength 数据长度
 *}
procedure term_write(aTerm: pterm_t; const aData: PAnsiChar; aLength: SizeUInt); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_write
 *
 * @desc 写入数据(ANSI字符串)
 *
 * @params
 *  - aData   数据
 *  - aLength 数据长度
 *}
procedure term_write(const aData: PAnsiChar; aLength: SizeUInt); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_write
 *
 * @desc 指定终端写入数据(宽字符串)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aLength 数据长度
 *}
procedure term_write(aTerm: pterm_t; const aData: PWideChar; aLength: SizeUInt); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_write
 *
 * @desc 写入数据(宽字符串)
 *
 * @params
 *  - aData   数据
 *  - aLength 数据长度
 *}
procedure term_write(const aData: PWideChar; aLength: SizeUInt); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符串)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aLength 数据长度
 *}
procedure term_write(aTerm: pterm_t; const aData: PUCS4Char; aLength: SizeUInt); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符串)
 *
 * @params
 *  - aData   数据
 *  - aLength 数据长度
 *}
procedure term_write(const aData: PUCS4Char; aLength: SizeUInt); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(字符串)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *}
procedure term_write(aTerm: pterm_t; const aText: string); overload;

{**
 * term_write
 *
 * @desc 写入数据(字符串)
 *
 * @params
 *  - aText 数据
 *}
procedure term_write(const aText: string); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(宽字符串)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *}
procedure term_write(aTerm: pterm_t; const aText: widestring); overload;

{**
 * term_write
 *
 * @desc 写入数据(宽字符串)
 *
 * @params
 *  - aText 数据
 *}
procedure term_write(const aText: widestring); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aChar   数据
 *}
procedure term_write(aTerm: pterm_t; aChar: UCS4Char); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符)
 *
 * @params
 *  - aChar 数据
 *}
procedure term_write(aChar: UCS4Char); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符串)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *}
procedure term_write(aTerm: pterm_t; const aText: ucs4string); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符串)
 *
 * @params
 *  - aText 数据
 *}
procedure term_write(const aText: ucs4string); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(开放数组)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 开放数组
 *}
procedure term_write(aTerm: pterm_t; const aArrays: array of const); overload;

{**
 * term_write
 *
 * @desc 写入数据(开放数组)
 *
 * @params
 *  - aArrays 开放数组
 *}
procedure term_write(const aArrays: array of const); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(Variant)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *}
procedure term_write(aTerm: pterm_t; const aData: Variant); overload;

{**
 * term_write
 *
 * @desc 写入数据(Variant)
 *
 * @params
 *  - aData 数据
 *}
procedure term_write(const aData: Variant); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(ANSI字符串)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: String; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(ANSI字符串,附加16色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: String; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(ANSI字符串,附加256色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: String; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(ANSI字符串,附加256色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: String; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(ANSI字符串,附加24位真彩色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: String; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(ANSI字符串,附加24位真彩色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: String; const aAttr: term_attr_24bit_t); overload;


{**
 * term_write
 *
 * @desc 指定终端写入数据(宽字符串,附加16色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(宽字符串,附加16色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: WideString; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(宽字符串,附加256色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(宽字符串,附加256色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: WideString; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(宽字符串,附加24位真彩色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(宽字符串,附加24位真彩色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: WideString; const aAttr: term_attr_24bit_t); overload;


{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符串,附加16色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符串,附加16色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: UCS4String; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符串,附加256色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符串,附加256色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: UCS4String; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符串,附加24位真彩色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符串,附加24位真彩色属性)
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_write(const aText: UCS4String; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符,附加16色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符,附加16色属性)
 *
 * @params
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_write(aChar: UCS4Char; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(UCS4字符,附加256色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符,附加256色属性)
 *
 * @params
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_write(aChar: UCS4Char; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符,附加256色属性)
 *
 * @params
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(UCS4字符,附加24位真彩色属性)
 *
 * @params
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_write(aChar: UCS4Char; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(数组,附加16色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(数组,附加16色属性)
 *
 * @params
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_write(const aArrays: array of const; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(数组,附加256色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(数组,附加256色属性)
 *
 * @params
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_write(const aArrays: array of const; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(数组,附加24位真彩色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(数组,附加24位真彩色属性)
 *
 * @params
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_write(const aArrays: array of const; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(Variant,附加16色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(Variant,附加16色属性)
 *
 * @params
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_write(const aData: Variant; const aAttr: term_attr_16_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(Variant,附加256色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(Variant,附加256色属性)
 *
 * @params
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_write(const aData: Variant; const aAttr: term_attr_256_t); overload;

{**
 * term_write
 *
 * @desc 指定终端写入数据(Variant,附加24位真彩色属性)
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_write(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_24bit_t); overload;

{**
 * term_write
 *
 * @desc 写入数据(Variant,附加24位真彩色属性)
 *
 * @params
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_write(const aData: Variant; const aAttr: term_attr_24bit_t); overload;


{**
 * term_writeln
 *
 * @desc 指定终端写入换行
 *
 * @params
 *  - aTerm   终端实例指针
 *}
procedure term_writeln(aTerm: pterm_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 写入换行
 *}
procedure term_writeln; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(字符串)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *}
procedure term_writeln(aTerm: pterm_t; const aText: string); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 写入数据(字符串)并换行
 *
 * @params
 *  - aText 数据
 *}
procedure term_writeln(const aText: string); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(宽字符串)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *}
procedure term_writeln(aTerm: pterm_t; const aText: widestring); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 写入数据(宽字符串)并换行
 *
 * @params
 *  - aText 数据
 *}
procedure term_writeln(const aText: widestring); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符串)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *}
procedure term_writeln(aTerm: pterm_t; const aText: ucs4string); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符串)并换行
 *
 * @params
 *  - aText 数据
 *}
procedure term_writeln(const aText: ucs4string); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aChar   数据
 *}
procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符)并换行
 *
 * @params
 *  - aChar   数据
 *}
procedure term_writeln(aChar: UCS4Char); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(数组)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 数据
 *}
procedure term_writeln(aTerm: pterm_t; const aArrays: array of const); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(数组)并换行
 *
 * @params
 *  - aArrays 数据
 *}
procedure term_writeln(const aArrays: array of const); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(Variant)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *}
procedure term_writeln(aTerm: pterm_t; const aData: Variant); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(Variant)并换行
 *
 * @params
 *  - aData   数据
 *}
procedure term_writeln(const aData: Variant); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(字符串,16色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: String; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(字符串,16色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: String; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(字符串,256色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: String; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(字符串,256色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: String; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(字符串,24位色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: String; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(字符串,24位色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: String; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(宽字符串,16色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(宽字符串,16色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: WideString; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(宽字符串,256色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(宽字符串,256色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: WideString; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(宽字符串,24位色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(宽字符串,24位色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: WideString; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符串,16色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符串,16色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: UCS4String; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符串,256色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符串,256色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: UCS4String; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符串,24位色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符串,24位色属性)并换行
 *
 * @params
 *  - aText   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aText: UCS4String; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符,16色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符,16色属性)并换行
 *
 * @params
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aChar: UCS4Char; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符,256色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符,256色属性)并换行
 *
 * @params
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aChar: UCS4Char; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(UCS4字符,24位色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(UCS4字符,24位色属性)并换行
 *
 * @params
 *  - aChar   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aChar: UCS4Char; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(数组,16色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(数组,16色属性)并换行
 *
 * @params
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aArrays: array of const; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(数组,256色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(数组,256色属性)并换行
 *
 * @params
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aArrays: array of const; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(数组,24位色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(数组,24位色属性)并换行
 *
 * @params
 *  - aArrays 数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aArrays: array of const; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(Variant,16色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(Variant,16色属性)并换行
 *
 * @params
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aData: Variant; const aAttr: term_attr_16_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(Variant,256色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(Variant,256色属性)并换行
 *
 * @params
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aData: Variant; const aAttr: term_attr_256_t); overload;

{**
 * term_writeln
 *
 * @desc 指定终端写入数据(Variant,24位色属性)并换行
 *
 * @params
 *  - aTerm   终端实例指针
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_writeln(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_24bit_t); overload;

{**
 * term_writeln
 *
 * @desc 写入数据(Variant,24位色属性)并换行
 *
 * @params
 *  - aData   数据
 *  - aAttr   属性
 *}
procedure term_writeln(const aData: Variant; const aAttr: term_attr_24bit_t); overload;





{ 构造事件数据 }

{**
 * term_event_key
 *
 * @desc 构造按键事件数据
 *
 * @params
 *  - aKey 按键数据
 *
 * @return term_event_t 按键事件数据
 *}
function term_event_key(const aKey: term_event_key_t): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_key
 *
 * @desc 构造按键事件数据
 *
 * @params
 *  - aKey   按键数据
 *  - aChar  按键产生的字符
 *  - aShift 是否按下Shift键
 *  - aCtrl  是否按下Ctrl键
 *  - aAlt   是否按下Alt键
 *
 * @return term_event_t 按键事件数据
 *}
function term_event_key(aKey: term_key_t; aChar: term_char_t; aShift, aCtrl, aAlt: Boolean): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_key
 *
 * @desc 构造按键事件数据
 *
 * @params
 *  - aKey   按键数据
 *  - aChar  按键产生的字符
 *  - aShift 是否按下Shift键
 *  - aCtrl  是否按下Ctrl键
 *  - aAlt   是否按下Alt键
 *
 * @return term_event_t 按键事件数据
 *}
function term_event_key(aKey: term_key_t; aChar: Char;        aShift, aCtrl, aAlt: Boolean): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_key
 *
 * @desc 构造按键事件数据
 *
 * @params
 *  - aKey   按键数据
 *  - aChar  按键产生的字符
 *  - aShift 是否按下Shift键
 *  - aCtrl  是否按下Ctrl键
 *  - aAlt   是否按下Alt键
 *
 * @return term_event_t 按键事件数据
 *}
function term_event_key(aKey: term_key_t; aChar: WideChar;    aShift, aCtrl, aAlt: Boolean): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_mouse
 *
 * @desc 构造鼠标事件数据
 *
 * @params
 *  - aMouse 鼠标事件数据
 *
 * @return term_event_t 鼠标事件数据
 *}
function term_event_mouse(aMouse: term_event_mouse_t): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_mouse
 *
 * @desc 构造鼠标事件数据
 *
 * @params
 *  - aX     鼠标位置x
 *  - aY     鼠标位置y
 *  - aState 鼠标状态
 *  - aButton 鼠标按键
 *  - aShift 是否按下Shift键
 *  - aCtrl  是否按下Ctrl键
 *  - aAlt   是否按下Alt键
 *
 * @return term_event_t 鼠标事件数据
 *}
function term_event_mouse(aX, aY: term_size_t; aState: term_mouse_state_t; aButton: term_mouse_button_t; aShift, aCtrl, aAlt: Boolean): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_size_change
 *
 * @desc 构造窗口大小变更事件数据
 *
 * @params
 *  - aWidth  新宽度
 *  - aHeight 新高度
 *
 * @return term_event_t 窗口大小变更事件数据
 *}
function term_event_size_change(aWidth, aHeight: term_size_t): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_focus
 *
 * @desc 构造焦点事件数据
 *
 * @params
 *  - aFocus 是否聚焦
 *
 * @return term_event_t 焦点事件数据
 *}
function term_event_focus(const aFocus: boolean): term_event_t; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{ 事件队列 }

{**
 * term_event_push
 *
 * @desc 指定终端向事件队列推送一个事件
 *
 * @params
 *  - aTerm   终端实例
 *  - aEvent  事件数据
 *}
procedure term_event_push(aTerm: pterm_t; const aEvent: term_event_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_evnet_push
 *
 * @desc 向事件队列推送一个事件
 *
 * @params
 *  - aEvent  事件数据
 *}
procedure term_evnet_push(const aEvent: term_event_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF} deprecated 'use term_event_push instead';

{**
 * term_event_push_key
 *
 * @desc 向事件队列推送一个按键事件
 *
 * @params
 *  - aTerm 终端实例
 *  - aKey  按键事件数据
 *}
procedure term_event_push_key(const aTerm: pterm_t; const aKey: term_event_key_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_push_key
 *
 * @desc 向事件队列推送一个按键事件
 *
 * @params
 *  - aKey  按键事件数据
 *}
procedure term_event_push_key(const aKey: term_event_key_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_push_mouse
 *
 * @desc 指定终端向事件队列推送一个鼠标事件
 *
 * @params
 *  - aTerm  终端实例
 *  - aMouse 鼠标事件数据
 *}
procedure term_event_push_mouse(const aTerm: pterm_t; const aMouse: term_event_mouse_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_push_mouse
 *
 * @desc 向事件队列推送一个鼠标事件
 *
 * @params
 *  - aMouse 鼠标事件数据
 *}
procedure term_event_push_mouse(const aMouse: term_event_mouse_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_push_size_change
 *
 * @desc 指定终端向事件队列推送一个窗口大小变更事件
 *
 * @params
 *  - aTerm  终端实例
 *  - aWidth  新宽度
 *  - aHeight 新高度
 *}
procedure term_event_push_size_change(const aTerm: pterm_t; aWidth, aHeight: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_push_size_change
 *
 * @desc 向事件队列推送一个窗口大小变更事件
 *
 * @params
 *  - aWidth  新宽度
 *  - aHeight 新高度
 *}
procedure term_event_push_size_change(aWidth, aHeight: term_size_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_push_focus
 *
 * @desc 指定终端向事件队列推送一个焦点事件
 *
 * @params
 *  - aTerm  终端实例
 *  - aFocus 焦点事件数据
 *}
procedure term_event_push_focus(const aTerm: pterm_t; const aFocus: boolean); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_push_focus
 *
 * @desc 向事件队列推送一个焦点事件
 *
 * @params
 *  - aFocus 焦点事件数据
 *}
procedure term_event_push_focus(const aFocus: boolean); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_poll
 *
 * @desc 指定终端从事件队列中轮询并获取一个事件。
 *       此函数会在指定的超时时间内尝试从后端拉取事件，并将其放入事件队列中。
 *
 * @params
 *  - aTerm    终端实例
 *  - aEvent   事件数据
 *  - aTimeout 超时时间
 *
 * @return Boolean 是否成功
 *
 * @remark 如果轮询超时后事件队列为空, 则返回False
 *         与pop操作不同，pop仅从已有的事件队列中弹出一个事件，而不会主动拉取新事件。
 *         poll操作会尝试从后端拉取事件并放入事件队列中，然后返回。
 *}

{**
 * term_events_collect
 *
 * @desc 单线程同步批处理收集事件：在预算时间内批量拉取，
 *       自动合并 MouseMove（末帧最新）与 Resize 去抖（最后一条）。
 *
 * @params
 *  - aTerm    终端实例（可传 _term）
 *  - aEvents  输出事件数组（开放数组）
 *  - aMaxN    最大收集数量（不超过数组长度）
 *  - aBudgetMs 时间预算（毫秒），0 表示仅拉取队列已有事件
 *
 * @return 实际收集数量
 *}
function term_events_collect(aTerm: pterm_t; var aEvents: array of term_event_t;
                             aMaxN: SizeUInt; aBudgetMs: UInt32): SizeUInt; overload;
function term_events_collect(var aEvents: array of term_event_t;
                             aMaxN: SizeUInt; aBudgetMs: UInt32): SizeUInt; overload;

function term_event_poll(aTerm: pterm_t; var aEvent: term_event_t; aTimeout: UInt64): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_poll
 *
 * @desc 从事件队列中轮询并获取一个事件。
 *       此函数会在指定的超时时间内尝试从后端拉取事件，并将其放入事件队列中。
 *
 * @params
 *  - aEvent   事件数据
 *  - aTimeout 超时时间
 *
 * @return Boolean 是否成功
 *
 * @remark 如果轮询超时后事件队列为空, 则返回False
 *         与pop操作不同，pop仅从已有的事件队列中弹出一个事件，而不会主动拉取新事件。
 *         poll操作会尝试从后端拉取事件并放入事件队列中，然后返回。
 *}
function term_event_poll(var aEvent: term_event_t; aTimeout: UInt64): Boolean; overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


  {**
   * 运行期开关（事件合并/去抖）：环境变量在 term_init 时设置默认值；
   * 运行期间可通过以下 Setter/Getter 显式覆盖。
   *}
  procedure term_set_coalesce_move(aEnable: Boolean);
  procedure term_set_coalesce_wheel(aEnable: Boolean);
  procedure term_set_debounce_resize(aEnable: Boolean);
  function  term_get_coalesce_move: Boolean;
  function  term_get_coalesce_wheel: Boolean;
  function  term_get_debounce_resize: Boolean;

  { 诊断：导出当前生效配置的 JSON 快照（编译期默认+环境变量+运行时设置之后） }
  function term_get_effective_config: string;


  // 可选：空转轻睡与指数退避（默认关闭/0，不改变现状）
  procedure term_set_idle_sleep_ms(aMs: UInt32);
  function  term_get_idle_sleep_ms: UInt32;
  procedure term_set_poll_backoff_enabled(aEnable: Boolean);
  function  term_get_poll_backoff_enabled: Boolean;



  { 最小输出队列化原型（全局，默认 _term）：先 queue 多次，最后 flush 一次写出 }
  procedure term_queue(const aText: string); overload;
  procedure term_queue(const aArrays: array of const); overload;
  procedure term_flush; overload;

{**
 * term_event_read
 *
 * @desc 指定终端从事件队列中读取(消费)一个事件
 *
 * @params
 *  - aTerm  终端实例
 *  - aEvent 事件数据
 *
 * @remark 如果事件队列为空, 则阻塞等待直到有新事件到达
 *         事件一旦被读取, 将从事件队列中移除
 *}
procedure term_event_read(aTerm: pterm_t; var aEvent: term_event_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}

{**
 * term_event_read
 *
 * @desc 从事件队列中读取(消费)一个事件
 *
 * @params
 *  - aEvent 事件数据
 *}
procedure term_event_read(var aEvent: term_event_t); overload; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}


///
/// 输入
///

{**
 * term_readchar
 *
 * @desc 从指定终端读取一个字符
 *
 * @params
 *  - aTerm 终端实例
 *}
function term_readchar(aTerm: pterm_t): term_char_t; overload;

{**
 * term_readchar
 *
 * @desc 从终端读取一个字符
 *}
function term_readchar: term_char_t; overload;

{**
 * term_readln
 *
 * @desc 从指定终端读取一行字符串
 *
 * @params
 *  - aTerm   终端实例
 *  - aBuffer 读取到的字符串
 *}
procedure term_readln(aTerm: pterm_t; var aBuffer: string); overload;

{**
 * term_readln
 *
 * @desc 从终端读取一行字符串
 *
 * @params
 *  - aBuffer 读取到的字符串
 *}
procedure term_readln(var aBuffer: string); overload;

{**
 * term_readln
 *
 * @desc 从指定终端读取一行字符串
 *
 * @params
 *  - aTerm 终端实例
 *}
function term_readln(aTerm: pterm_t): string; overload;

{**
 * term_readln
 *
 * @desc 从终端读取一行字符串
 *}
function term_readln: string; overload;






  { ===== Modern interfaces and helpers (facade) ===== }

  type
    // 终端颜色（16色）
    TTerminalColor = (
      tcBlack, tcRed, tcGreen, tcYellow, tcBlue, tcMagenta, tcCyan, tcWhite,
      tcBrightBlack, tcBrightRed, tcBrightGreen, tcBrightYellow, tcBrightBlue, tcBrightMagenta, tcBrightCyan, tcBrightWhite
    );

    // 文本属性
    TTerminalAttribute = (
      taBold, taDim, taItalic, taUnderline, taBlink, taReverse, taStrikethrough
    );

    // 清理目标
    TClearTarget = (tctAll, tctCurrentLine);

    // RGB 颜色
    TRGBColor = record
      R, G, B, A: Byte;
    end;

  function MakeRGBColor(aR, aG, aB: Byte): TRGBColor; overload;

  // 键盘事件/枚举（精简版，满足测试需要）
  type
    TKeyType = (
      ktUnknown, ktChar, ktEnter, ktBackspace, ktTab, ktEscape,
      // 导航键
      ktArrowUp, ktArrowDown, ktArrowLeft, ktArrowRight,
      ktHome, ktEnd, ktPageUp, ktPageDown, ktInsert, ktDelete,
      // 功能键
      ktF1, ktF2, ktF3, ktF4, ktF5, ktF6, ktF7, ktF8, ktF9, ktF10, ktF11, ktF12
    );

    TKeyModifier = (kmCtrl, kmShift, kmAlt);
    TKeyModifiers = set of TKeyModifier;

    TKeyEvent = record
      KeyType: TKeyType;
      KeyChar: Char;
      Modifiers: TKeyModifiers;
      UnicodeChar: string;
    end;

  function MakeKeyEvent(aType: TKeyType; aKeyChar: Char = #0; aModifiers: TKeyModifiers = []; const aUnicodeChar: string = ''): TKeyEvent;
  function KeyEventToString(const aEvent: TKeyEvent): string;

  // 颜色辅助
  function ColorToRGB(aColor: TTerminalColor): TRGBColor;


  // 终端尺寸与能力（精简）
  type
    TTerminalSize = record
      Width: Integer;
      Height: Integer;
    end;

    TTerminalCapability = (
      tcapANSI,
      tcapColor16,
      tcapColor256,
      tcapTrueColor,
      // 细粒度鼠标与扩展能力位（对齐现代终端库）
      tcapMouse,               // 总开关（兼容位）
      tcapMouseBasic,          // ?1000
      tcapMouseDrag,           // ?1002
      tcapMouseSGR,            // ?1006（首选）
      tcapMouseUrxvt,          // ?1015
      tcapFocus,               // ?1004
      tcapBracketedPaste       // ?2004
    );
    TTerminalCapabilities = set of TTerminalCapability;

  // 接口定义
  type
    // 前置声明，避免在 ITerminalOutput 中引用次序问题
    ITerminalCommand = interface;
    ITerminalInfo = interface(IInterface)
      ['{A5A8D8B1-4BB6-4C18-8E5A-C5B8F3F2B3D7}']
      // 尺寸与能力
      function GetSize: TTerminalSize;
      function GetCapabilities: TTerminalCapabilities;
      function GetTerminalType: string;
      function IsATTY: Boolean;
      function SupportsColor: Boolean;
      function SupportsTrueColor: Boolean;
      function GetColorDepth: Integer;
      // 环境与上下文
      function GetEnvironmentVariable(const aName: string): string;
      function IsInsideTerminalMultiplexer: Boolean;
      // 接口层属性便捷（通过方法读）
      property Size: TTerminalSize read GetSize;
      property Capabilities: TTerminalCapabilities read GetCapabilities;
      property TerminalType: string read GetTerminalType;
    end;

    ITerminalOutput = interface(IInterface)
      ['{B0C0F1F3-0E7A-44A5-9C8A-5B7BE1A7B6F2}']
      // 基本输出
      procedure Write(const aText: string);
      procedure WriteLn(const aText: string = '');
      procedure Flush;

      // 颜色/属性
      procedure SetForegroundColor(aColor: TTerminalColor);
      procedure SetBackgroundColor(aColor: TTerminalColor);
      procedure SetForegroundColorRGB(const aColor: TRGBColor);
      procedure SetBackgroundColorRGB(const aColor: TRGBColor);
      procedure ResetColors;

      procedure SetAttribute(aAttr: TTerminalAttribute);
      procedure ResetAttributes;

      // 光标/屏幕
      procedure MoveCursor(aX, aY: Integer);
      procedure MoveCursorUp(aCount: Integer);
      procedure MoveCursorDown(aCount: Integer);
      procedure MoveCursorLeft(aCount: Integer);
      procedure MoveCursorRight(aCount: Integer);
      procedure SaveCursorPosition;
      procedure RestoreCursorPosition;
      procedure ShowCursor;
      procedure HideCursor;

      procedure ClearScreen(aTarget: TClearTarget);
      procedure ScrollUp(aLines: Integer);
      procedure ScrollDown(aLines: Integer);
      procedure EnterAlternateScreen;
      procedure LeaveAlternateScreen;
      // 滚动区域
      procedure SetScrollRegion(aTop, aBottom: Integer);
      procedure ResetScrollRegion;

      // 命令
      procedure EnableBuffering;
      procedure DisableBuffering;
      function IsBufferingEnabled: Boolean;

      // 命令执行
      procedure ExecuteCommand(const aCommand: IInterface);
      procedure ExecuteCommands(const aCommands: array of IInterface); overload;
      procedure ExecuteCommands(const aCommands: array of ITerminalCommand); overload;
    end;

    ITerminalInput = interface(IInterface)
      ['{6D1A9A2B-0E6B-4D0F-9B0E-7F1B5D2C1E90}']
      function ReadKey: TKeyEvent;
      function TryReadKey(out aKeyEvent: TKeyEvent): Boolean;
      function ReadLine: string;
      function HasInput: Boolean;
      // 新增：窥视下一个按键但不消费；清空输入缓冲
      function PeekKey(out aKeyEvent: TKeyEvent): Boolean;
      procedure FlushInput;
    end;

    ITerminal = interface(IInterface)
      ['{E8D1C2B3-5F7A-4D9C-8A1B-9C0D2E3F4A5B}']
      function GetInfo: ITerminalInfo;
      function GetOutput: ITerminalOutput;
      function GetInput: ITerminalInput;
      procedure Initialize;
      procedure Finalize;
      procedure EnterRawMode;
      procedure LeaveRawMode;
      procedure Reset;
      property Info: ITerminalInfo read GetInfo;
      property Output: ITerminalOutput read GetOutput;
      property Input: ITerminalInput read GetInput;
    end;

    ITerminalCommand = interface(IInterface)
      ['{F1A2B3C4-D5E6-47F8-9012-34A5B6C7D8E9}']
      function GetCommandString: string;
      function GetDescription: string;
      procedure Execute(const aOutput: ITerminalOutput);
      function IsValid: Boolean;
      function Clone: ITerminalCommand;
      property CommandString: string read GetCommandString;
      property Description: string read GetDescription;
    end;

  // 工厂/便捷函数
  function CreateTerminal: ITerminal;
  function CreateTerminalCommand(const aCommandString: string; const aDescription: string = ''): ITerminalCommand;
  function GetTerminalSize: TTerminalSize;
  function IsTerminal: Boolean;
  function SupportsColor: Boolean;

  // ANSI 生成器（静态）
  type
    TANSIGenerator = class sealed
    public
      class function SetForegroundColor(aColor: TTerminalColor): string; static;
      class function SetBackgroundColor(aColor: TTerminalColor): string; static;
      class function SetForegroundColorRGB(const aColor: TRGBColor): string; static;
      class function SetBackgroundColorRGB(const aColor: TRGBColor): string; static;
      class function ResetColors: string; static;

      class function SetAttribute(aAttr: TTerminalAttribute): string; static;
      class function ResetAttributes: string; static;

      class function MoveCursor(aX, aY: Integer): string; static;
      class function MoveCursorUp(aCount: Integer): string; static;
      class function MoveCursorDown(aCount: Integer): string; static;
      class function MoveCursorLeft(aCount: Integer): string; static;
      class function MoveCursorRight(aCount: Integer): string; static;
      class function SaveCursorPosition: string; static;
      class function RestoreCursorPosition: string; static;
      class function ShowCursor: string; static;
      class function HideCursor: string; static;

      class function ClearScreen(aTarget: TClearTarget): string; static;
      class function ScrollUp(aLines: Integer): string; static;
      class function ScrollDown(aLines: Integer): string; static;
      // DECSTBM: set scroll region (top/bottom inclusive, 0-based input; mapped to 1-based CSI t;b r)
      class function SetScrollRegion(aTop, aBottom: Integer): string; static;
      // DECSCUSR: set cursor shape via CSI Ps SP q; map from term_cursor_shape_t
      class function SetCursorShape(aShape: term_cursor_shape_t): string; static;
      class function EnterAlternateScreen: string; static;
      class function LeaveAlternateScreen: string; static;
      // OSC sequences
      class function SetWindowTitle(const aTitle: string): string; static; // OSC 2
      class function SetIconTitle(const aTitle: string): string; static;   // OSC 1

      class function ColorToANSICode(aColor: TTerminalColor; aBackground: Boolean): Integer; static;
      class function AttributeToANSICode(aAttr: TTerminalAttribute): Integer; static;
    end;

  { 面向对象实现类声明（对外可见） }
  type

    TTerminalInfo = class(TInterfacedObject, ITerminalInfo)
    public
      function GetSize: TTerminalSize;
      function GetCapabilities: TTerminalCapabilities;
      function GetTerminalType: string;
      function IsATTY: Boolean;
      function SupportsColor: Boolean;
      function SupportsTrueColor: Boolean;
      function GetColorDepth: Integer;
      // 环境与上下文
      function GetEnvironmentVariable(const aName: string): string;
      function IsInsideTerminalMultiplexer: Boolean;

      // 属性便捷
      property Size: TTerminalSize read GetSize;
      property Capabilities: TTerminalCapabilities read GetCapabilities;
      property TerminalType: string read GetTerminalType;
    end;

    TTerminalOutput = class(TInterfacedObject, ITerminalOutput)
    private
      FStream: TStream;
      FOwnsStream: Boolean;
      FBuffering: Boolean;
      FBuffer: string;
      // 输出状态：用于最小化重复的颜色/属性序列
      FColorStateValid: Boolean;
      FFGColor: TTerminalColor;
      FBGColor: TTerminalColor;
      FLastAttrValid: Boolean;
      FLastAttr: TTerminalAttribute;
      // 光标可见性状态：避免重复发出显示/隐藏序列
      FCursorVisibleKnown: Boolean;
      FCursorVisible: Boolean;
      // 滚动区域与光标保存/恢复的重复抑制
      FScrollRegionSet: Boolean;
      FScrollRegionTop: Integer;
      FScrollRegionBottom: Integer;
      FCursorSaved: Boolean;
      procedure InternalWrite(const S: string);
    public
      constructor Create(AStream: TStream; AOwnsStream: Boolean);
      destructor Destroy; override;
      // 基本输出
      procedure Write(const aText: string);
      procedure WriteLn(const aText: string = '');
      procedure Flush;
      // 颜色/属性
      procedure SetForegroundColor(aColor: TTerminalColor);
      procedure SetBackgroundColor(aColor: TTerminalColor);
      procedure SetForegroundColorRGB(const aColor: TRGBColor);
      procedure SetBackgroundColorRGB(const aColor: TRGBColor);
      procedure ResetColors;
      procedure SetAttribute(aAttr: TTerminalAttribute);
      procedure ResetAttributes;
      // 光标/屏幕
      procedure MoveCursor(aX, aY: Integer);
      procedure MoveCursorUp(aCount: Integer);
      procedure MoveCursorDown(aCount: Integer);
      procedure MoveCursorLeft(aCount: Integer);
      procedure MoveCursorRight(aCount: Integer);
      procedure SaveCursorPosition;
      procedure RestoreCursorPosition;
      procedure ShowCursor;
      procedure HideCursor;
      procedure ClearScreen(aTarget: TClearTarget);
      procedure ScrollUp(aLines: Integer);
      procedure ScrollDown(aLines: Integer);
      procedure EnterAlternateScreen;
      procedure LeaveAlternateScreen;
      // 滚动区域
      procedure SetScrollRegion(aTop, aBottom: Integer);
      procedure ResetScrollRegion;
      // 缓冲
      procedure EnableBuffering;
      procedure DisableBuffering;
      function IsBufferingEnabled: Boolean;
      // 命令
      procedure ExecuteCommand(const aCommand: IInterface);
      procedure ExecuteCommands(const aCommands: array of IInterface); overload;
      procedure ExecuteCommands(const aCommands: array of ITerminalCommand); overload;
    end;

    TTerminalInput = class(TInterfacedObject, ITerminalInput)
    private
      FPending: Boolean;
      FPendingKey: TKeyEvent;
      function MapEventToKeyEvent(const E: term_event_t; out K: TKeyEvent): Boolean;
      function FetchNextKey(aTimeout: UInt64; out K: TKeyEvent): Boolean;
    public
      function ReadKey: TKeyEvent;
      function TryReadKey(out aKeyEvent: TKeyEvent): Boolean;
      function ReadLine: string;
      function HasInput: Boolean;
      // 新增 API
      function PeekKey(out aKeyEvent: TKeyEvent): Boolean;
      procedure FlushInput;
    end;


    TTerminalCommand = class(TInterfacedObject, ITerminalCommand)
    private
      FCmd: string;
      FDesc: string;
    public
      constructor Create(const aCommandString: string; const aDescription: string = '');
      function GetCommandString: string;
      function GetDescription: string;
      procedure Execute(const aOutput: ITerminalOutput);
      function IsValid: Boolean;
      function Clone: ITerminalCommand;
    end;

    TTerminal = class(TInterfacedObject, ITerminal)
    private
      FInfo: ITerminalInfo;
      FOutput: ITerminalOutput;
      FInput: ITerminalInput;

    public
      constructor Create;
      destructor Destroy; override;
      function GetInfo: ITerminalInfo;
      function GetOutput: ITerminalOutput;
      function GetInput: ITerminalInput;
      procedure Initialize;
      procedure Finalize;
      procedure EnterRawMode;
      procedure LeaveRawMode;
      procedure Reset;
    end;


  // Behind-a-flag 选择：新环形存储后端（默认关闭）。
  // FAFAFA_TERM_PASTE_BACKEND=ring 切换到环形后端；其他值或空为旧后端
  var
    G_PASTE_BACKEND_RING: Boolean = False;

  var
    G_PASTE_MAX_BYTES: SizeUInt = 0; // 0 表示不限制累计字节数（若启用 DEFAULTS，将在 term_init 中设为更保守的上限）
  var
  G_PASTE_AUTO_KEEP_LAST: SizeUInt; // 0 表示不自动修剪；>0 表示仅保留最近 N 条
  G_PASTE_TOTAL_BYTES: SizeUInt;

  G_PASTE_TRIM_FASTPATH_DIV: SizeUInt = 8; // StartIdx > L div Div 时触发快速路径（>=1）

  G_PASTE_STORE: array of string;

implementation

uses


{$IFDEF MSWINDOWS}
  fafafa.core.term.windows,
{$ELSE}
  fafafa.core.term.unix,
{$ENDIF}
  fafafa.core.term.ansi,
  fafafa.core.color,
  fafafa.core.math,
  fafafa.core.term.paste.ring;

function ParseSizeWithSuffix(const S: string; out V: SizeUInt): Boolean;
var
  X: QWord;
  Tail: string;
  Code: Integer;
  Shift: Integer;
  Suffix: Char;
begin
  Result := False;
  V := 0;
  // 空或全空白均视为失败
  Tail := LowerCase(Trim(S));
  if Tail = '' then Exit(False);

  // 允许 k/m/g 后缀（二进制 1024 进制），并做溢出与边界防护
  Suffix := Tail[Length(Tail)];
  if (Suffix in ['k','m','g']) and (Length(Tail) > 1) then
  begin
    Val(Copy(Tail, 1, Length(Tail)-1), X, Code);
    if Code <> 0 then Exit(False);
    case Suffix of
      'k': Shift := 10;
      'm': Shift := 20;
      'g': Shift := 30;
    else
      Shift := 0;
    end;
    // 先检查 QWord 级别移位是否会溢出
    if (Shift > 0) then
    begin
      if X > (High(QWord) shr Shift) then
        X := High(QWord)
      else
        X := X shl Shift;
    end;
  end
  else
  begin
    Val(Tail, X, Code);
    if Code <> 0 then Exit(False);
  end;

  // 最终落到 SizeUInt，做一次上限钳位
  if X > High(SizeUInt) then
    V := High(SizeUInt)
  else
    V := SizeUInt(X);

  Result := True;
end;


{** 平台特定的终端创建函数 *}

{$IFDEF MSWINDOWS}
function term_create_platform: pterm_t;
begin
  Result := term_windows_create;
end;

{$ELSE}
function term_create_platform: pterm_t;
begin
  Result := term_unix_create;
end;
{$ENDIF}

var
  G_TERM_OUT_QUEUE: string = '';

  _term:        pterm_t;         // 默认平台终端实例
  _term_initialized: boolean = False;
  // 合并策略调试/开关（默认开启，可用环境变量覆盖）
  G_TERM_COALESCE_MOVE: Boolean = True;
  G_TERM_COALESCE_WHEEL: Boolean = True;
  G_TERM_DEBOUNCE_RESIZE: Boolean = True;
  // 最近一次初始化/操作错误的诊断消息（非空表示最近一次错误简述）
  G_TERM_LAST_ERROR: string = '';
  // 空转轻睡/退避（默认关闭）
  G_TERM_IDLE_SLEEP_MS: UInt32 = 0; // 0 表示不 sleep
  G_TERM_POLL_BACKOFF_ENABLED: Boolean = False;
  // 运行时模式状态（针对默认 _term，最佳努力）：用于守卫恢复
  G_TERM_STATE_MOUSE_BASE: Boolean = False;
  G_TERM_STATE_MOUSE_DRAG: Boolean = False;
  G_TERM_STATE_MOUSE_SGR:  Boolean = False;
  G_TERM_STATE_FOCUS:      Boolean = False;
  G_TERM_STATE_PASTE:      Boolean = False;



// 前置声明，避免实现顺序影响编译
function vars_str(const aArray: array of const): string; forward;

// 简易输出缓冲与一次性写出
procedure term_queue(const aText: string);
begin
  if aText = '' then Exit;
  G_TERM_OUT_QUEUE := G_TERM_OUT_QUEUE + aText;
end;

procedure term_queue(const aArrays: array of const);
begin
  term_queue(vars_str(aArrays));
end;

procedure term_flush;
var
  S: string;
begin
  if Length(G_TERM_OUT_QUEUE) = 0 then Exit;
  S := G_TERM_OUT_QUEUE;
  G_TERM_OUT_QUEUE := '';
  term_write(S);
end;



function Max(A, B: Integer): Integer; inline;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;
procedure term_set_idle_sleep_ms(aMs: UInt32);
begin
  G_TERM_IDLE_SLEEP_MS := aMs;
end;

function term_get_idle_sleep_ms: UInt32;
begin
  Result := G_TERM_IDLE_SLEEP_MS;
end;

procedure term_set_poll_backoff_enabled(aEnable: Boolean);
begin
  G_TERM_POLL_BACKOFF_ENABLED := aEnable;
end;

function term_get_poll_backoff_enabled: Boolean;
begin
  Result := G_TERM_POLL_BACKOFF_ENABLED;
end;


// Runtime toggles (coalesce/debounce) setters/getters implementation
procedure term_set_coalesce_move(aEnable: Boolean);
begin
  G_TERM_COALESCE_MOVE := aEnable;
end;

procedure term_set_coalesce_wheel(aEnable: Boolean);
begin
  G_TERM_COALESCE_WHEEL := aEnable;
end;

procedure term_set_debounce_resize(aEnable: Boolean);
begin
  G_TERM_DEBOUNCE_RESIZE := aEnable;
end;

function term_get_coalesce_move: Boolean;
begin
  Result := G_TERM_COALESCE_MOVE;
end;

function term_get_coalesce_wheel: Boolean;
begin
  Result := G_TERM_COALESCE_WHEEL;
end;

function term_get_debounce_resize: Boolean;
begin
  Result := G_TERM_DEBOUNCE_RESIZE;
end;

function term_get_effective_config: string;
var
  s, backend: string;
begin
  // 简单 JSON 序列化（不引入依赖），导出关键运行时开关与 Paste 存储策略
  if G_PASTE_BACKEND_RING then backend := 'ring' else backend := 'legacy';
  s := '{'
     + '"coalesce_move":'   + IntToStr(ord(G_TERM_COALESCE_MOVE))
     + ',"coalesce_wheel":' + IntToStr(ord(G_TERM_COALESCE_WHEEL))
     + ',"debounce_resize":'+ IntToStr(ord(G_TERM_DEBOUNCE_RESIZE))
     + ',"idle_sleep_ms":'  + IntToStr(G_TERM_IDLE_SLEEP_MS)
     + ',"poll_backoff":'   + IntToStr(ord(G_TERM_POLL_BACKOFF_ENABLED))
     + ',"paste_backend":"' + backend + '"'
     + ',"paste_max_bytes":'+ IntToStr(G_PASTE_MAX_BYTES)
     + ',"paste_auto_keep_last":'+ IntToStr(G_PASTE_AUTO_KEEP_LAST)
     + ',"paste_trim_fastpath_div":'+ IntToStr(G_PASTE_TRIM_FASTPATH_DIV)
     + '}';
  Result := s;
end;


function Min(A, B: Integer): Integer; inline;
begin
  if A < B then
    Result := A
  else
    Result := B;
end;

function term_version: string;
begin
  Result := concat(IntToStr(FAFAFA_TERM_VER_MAJOR), '.', IntToStr(FAFAFA_TERM_VER_MINOR), '.', IntToStr(FAFAFA_TERM_VER_PATCH));
end;

function term_char(aChar: AnsiChar): term_char_t;
begin
  Result.char:= aChar;
end;

function term_char(aChar: WideChar): term_char_t;
begin
  Result.wchar := aChar;
end;

function term_event_queue_create: pterm_event_queue_t;
begin
  New(Result);
  if Result <> nil then
    term_event_queue_init(Result);
end;

procedure term_event_queue_init(aQueue: pterm_event_queue_t);
begin
  // 初始化环形缓冲区
  SetLength(aQueue^.buffer, TERM_EVENT_QUEUE_MAX);
  aQueue^.capacity := TERM_EVENT_QUEUE_MAX;
  aQueue^.head_idx := 0;
  aQueue^.tail_idx := 0;
  aQueue^.count    := 0;
  // 兼容字段清空
  aQueue^.head := nil;
  aQueue^.tail := nil;
end;

procedure term_event_queue_build_compat_list(aQueue: pterm_event_queue_t);
var
  i: SizeUInt;
  prev, node: pterm_event_queue_entry_t;
  cur, nxt: pterm_event_queue_entry_t;
begin
  if (aQueue = nil) or (aQueue^.count = 0) then Exit;
  // 若已有，先清理
  if aQueue^.head <> nil then
  begin
    cur := aQueue^.head;
    while cur <> nil do
    begin
      nxt := cur^.next;
      Dispose(cur);
      cur := nxt;
    end;
    aQueue^.head := nil; aQueue^.tail := nil;
  end;
  prev := nil;
  for i := 0 to aQueue^.count - 1 do
  begin
    New(node);
    node^.event := aQueue^.buffer[(aQueue^.head_idx + i) mod aQueue^.capacity];
    node^.prev := prev; node^.next := nil;
    if prev <> nil then prev^.next := node else aQueue^.head := node;
    prev := node;
  end;
  aQueue^.tail := prev;
end;

procedure term_event_queue_final(aQueue: pterm_event_queue_t);
begin
  term_event_queue_clear(aQueue);
end;

procedure term_event_queue_destroy(aQueue: pterm_event_queue_t);
begin
  term_event_queue_final(aQueue);
  Dispose(aQueue);
end;

function term_event_queue_count(aQueue: pterm_event_queue_t): SizeUInt;
begin
  Result := aQueue^.count;
end;

function term_event_queue_is_empty(aQueue: pterm_event_queue_t): Boolean;
begin
  Result := (term_event_queue_count(aQueue) = 0);
end;

procedure term_event_queue_clear(aQueue: pterm_event_queue_t);
var
  cur, nxt: pterm_event_queue_entry_t;
begin
  if aQueue = nil then Exit;
  // 清空环形缓冲
  aQueue^.head_idx := 0;
  aQueue^.tail_idx := 0;
  aQueue^.count    := 0;
  // 释放兼容链表视图
  if aQueue^.head <> nil then
  begin
    cur := aQueue^.head;
    while cur <> nil do
    begin
      nxt := cur^.next;
      Dispose(cur);
      cur := nxt;
    end;
    aQueue^.head := nil; aQueue^.tail := nil;
  end;
end;

function term_event_queue_peek(aQueue: pterm_event_queue_t; var aEvent: term_event_t): Boolean;
begin
  if aQueue = nil then Exit(False);
  Result := (aQueue^.count > 0);
  if Result then
    aEvent := aQueue^.buffer[aQueue^.head_idx];
end;

function term_event_queue_pop(aQueue: pterm_event_queue_t; var aEvent: term_event_t): Boolean;
begin
  if aQueue = nil then Exit(False);
  Result := (aQueue^.count > 0);
  if Result then
  begin
    aEvent := aQueue^.buffer[aQueue^.head_idx];
    aQueue^.head_idx := (aQueue^.head_idx + 1) mod aQueue^.capacity;
    Dec(aQueue^.count);
  end;
end;

procedure term_event_queue_push(aQueue: pterm_event_queue_t; const aEvent: term_event_t);
var
  nextTail: SizeUInt;
  tailIdx: SizeUInt;
  prevIdx: SizeUInt;
  prevEv: ^term_event_t;
begin
  if aQueue = nil then Exit;

  // 合并高频鼠标移动事件：如果尾部是同类移动事件，只更新位置与修饰键，不追加新节点
  if (aQueue^.count > 0) and (aEvent.kind = tek_mouse) and (aEvent.mouse.state = Ord(tms_moved)) then
  begin
    if aQueue^.tail_idx = 0 then prevIdx := aQueue^.capacity - 1 else prevIdx := aQueue^.tail_idx - 1;
    prevEv := @aQueue^.buffer[prevIdx];
    if (prevEv^.kind = tek_mouse) and (prevEv^.mouse.state = Ord(tms_moved)) then
    begin
      prevEv^.mouse.x     := aEvent.mouse.x;
      prevEv^.mouse.y     := aEvent.mouse.y;
      prevEv^.mouse.shift := aEvent.mouse.shift;
      prevEv^.mouse.ctrl  := aEvent.mouse.ctrl;
      prevEv^.mouse.alt   := aEvent.mouse.alt;
      Exit;
    end;
  end;

  // 写入环形缓冲：满时覆盖最旧元素（无异常退出），并前移 head
  nextTail := (aQueue^.tail_idx + 1) mod aQueue^.capacity;
  if aQueue^.count = aQueue^.capacity then
  begin
    // 覆盖策略：直接前移 head，丢弃最老事件
    aQueue^.head_idx := (aQueue^.head_idx + 1) mod aQueue^.capacity;
    aQueue^.buffer[aQueue^.tail_idx] := aEvent;
    aQueue^.tail_idx := nextTail;
    Exit;
  end;

  // 正常入队
  tailIdx := aQueue^.tail_idx;
  aQueue^.buffer[tailIdx] := aEvent;
  aQueue^.tail_idx := nextTail;
  Inc(aQueue^.count);
end;

function term_event_queue_entry_front(aQueue: pterm_event_queue_t): pterm_event_queue_entry_t;
begin
  if aQueue = nil then
    raise Exception.Create('term_event_queue_entry_front: aQueue is nil');
  // 若尚未构建兼容链表视图，则基于当前环形内容构建
  if (aQueue^.head = nil) and (aQueue^.count > 0) then
    term_event_queue_build_compat_list(aQueue);
  if aQueue^.count = 0 then Exit(nil);
  Result := aQueue^.head;
end;

function term_event_queue_entry_back(aQueue: pterm_event_queue_t): pterm_event_queue_entry_t;
begin
  if aQueue = nil then
    raise Exception.Create('term_event_queue_entry_back: aQueue is nil');
  if (aQueue^.tail = nil) and (aQueue^.count > 0) then
    Result := term_event_queue_entry_front(aQueue) // 构建后 head/tail 就绪
  else
    Result := aQueue^.tail;
end;

function term_event_queue_entry_next(aEntry: pterm_event_queue_entry_t): pterm_event_queue_entry_t;
begin
  if aEntry = nil then
    raise Exception.Create('term_event_queue_entry_next: aEntry is nil');

  Result := aEntry^.next;
end;

function term_event_queue_entry_prev(aEntry: pterm_event_queue_entry_t): pterm_event_queue_entry_t;
begin
  if aEntry = nil then
    raise Exception.Create('term_event_queue_entry_prev: aEntry is nil');

  Result := aEntry^.prev;
end;

procedure term_event_queue_remove(aQueue: pterm_event_queue_t; aEntry: pterm_event_queue_entry_t);
var
  idx, i, j: SizeUInt;
  removeRingIdx: SizeUInt;
  tmp: array of term_event_t;
  cur, nxt: pterm_event_queue_entry_t;
  pos: SizeUInt;
begin
  if (aQueue = nil) then
    raise Exception.Create('term_event_queue_entry_remove: aQueue is nil');
  if aEntry = nil then
    raise Exception.Create('term_event_queue_entry_remove: aEntry is nil');

  // 计算 aEntry 在当前链表视图中的序号（基于 front 构建的顺序）
  idx := 0; cur := aQueue^.head;
  while (cur <> nil) and (cur <> aEntry) do
  begin
    Inc(idx);
    cur := cur^.next;
  end;
  if cur = nil then Exit; // 未找到：视为无操作

  // 将链表视图释放，避免悬挂指针
  //（注意：测试不会在 remove 之后继续使用这些节点）
  cur := aQueue^.head;
  while cur <> nil do
  begin
    nxt := cur^.next;
    Dispose(cur);
    cur := nxt;
  end;
  aQueue^.head := nil; aQueue^.tail := nil;

  // 从环形缓冲中删除对应元素
  if aQueue^.count = 0 then Exit;
  removeRingIdx := (aQueue^.head_idx + idx) mod aQueue^.capacity;
  if aQueue^.count > 0 then
  begin
    SetLength(tmp, aQueue^.count - 1);
    if Length(tmp) > 0 then FillByte(tmp[0], Length(tmp) * SizeOf(term_event_t), 0);
    j := 0;
    for i := 0 to aQueue^.count - 1 do
    begin
      pos := (aQueue^.head_idx + i) mod aQueue^.capacity;
      if pos = removeRingIdx then Continue;
      tmp[j] := aQueue^.buffer[pos];
      Inc(j);
    end;
    // 重新打包到 0..j-1
    aQueue^.head_idx := 0;
    aQueue^.count := j;
    if j > 0 then
    begin
      for i := 0 to j - 1 do aQueue^.buffer[i] := tmp[i];
      aQueue^.tail_idx := j mod aQueue^.capacity;
    end
    else
    begin
      aQueue^.tail_idx := 0;
    end;
  end;
end;

function term_color_24bit_rgb(aR, aG, aB: UInt8): term_color_24bit_t;
begin
  Result.r        := aR;
  Result.g        := aG;
  Result.b        := aB;
  Result.reserved := 0;
end;

function term_color_24bit_hsv(aHue: term_hue_t; aSaturation: term_saturation_t; aValue: term_value_t): term_color_24bit_t;
var
  c: color_rgba_t;
begin
  c := color_from_hsv(aHue, aSaturation, aValue);
  Result := term_color_24bit_rgb(c.r, c.g, c.b);
end;




function term_rgb_to_256(aR, aG, aB: UInt8): term_color_256_t;
begin
  // Delegate to fafafa.core.color to ensure unified behavior
  Result := term_color_256_t(color_rgb_to_xterm256(aR, aG, aB));
end;

function term_color_approx_256(const aColor: term_color_24bit_t): term_color_256_t;
begin
  Result := term_rgb_to_256(aColor.r, aColor.g, aColor.b);
end;

function term_rgb_to_16(aR, aG, aB: UInt8): term_color_16_t;
begin
  // Delegate to fafafa.core.color to ensure unified behavior
  Result := term_color_16_t(color_rgb_to_ansi16(aR, aG, aB));
end;


function term_color_approx_16(const aColor: term_color_24bit_t): term_color_16_t;
begin
  Result := term_rgb_to_16(aColor.r, aColor.g, aColor.b);
end;








function term_color_24bit_hsb(aHue: term_hue_t; aSaturation: term_saturation_t; aBrightness: term_brightness_t): term_color_24bit_t;
begin
  Result := term_color_24bit_hsv(aHue, aSaturation, aBrightness);
end;

function term_color_24bit_hsl(aHue: term_hue_t; aSaturation: term_saturation_t; aLightness: term_lightness_t): term_color_24bit_t;
var
  c: color_rgba_t;
begin
  c := color_from_hsl(aHue, aSaturation, aLightness);
  Result := term_color_24bit_rgb(c.r, c.g, c.b);
end;

function term_color_24bit_cmyk(aCyan, aMagenta, aYellow, aBlack: term_cmyk_t): term_color_24bit_t; inline;
var
  R, G, B: Integer;
begin
  R := (255 * (100 - aCyan) * (100 - aBlack) + 5000) div 10000;
  G := (255 * (100 - aMagenta) * (100 - aBlack) + 5000) div 10000;
  B := (255 * (100 - aYellow) * (100 - aBlack) + 5000) div 10000;

  Result.r := UInt8(Max(0, Min(R, 255)));
  Result.g := UInt8(Max(0, Min(G, 255)));
  Result.b := UInt8(Max(0, Min(B, 255)));
end;

function term_point_create(aX, aY: term_size_t): pterm_point_t;
begin
  new(Result);

  if Result = nil then
    raise Exception.Create('term_point_create: Result is nil');

  term_point_init(Result, aX, aY);
end;

function term_point_create: pterm_point_t;
begin
  Result := term_point_create(0, 0);
end;

procedure term_point_init(aPoint: pterm_point_t; aX, aY: term_size_t);
begin
  if aPoint = nil then
    raise Exception.Create('term_point_init: aPoint is nil');

  aPoint^.x := aX;
  aPoint^.y := aY;
end;

procedure term_point_destroy(aPoint: pterm_point_t);
begin
  if aPoint = nil then
    raise Exception.Create('term_point_destroy: aPoint is nil');

  dispose(aPoint);
end;

function term_point_x(aPoint: pterm_point_t): term_size_t;
begin
  Result := aPoint^.x;
end;

function term_point_y(aPoint: pterm_point_t): term_size_t;
begin
  Result := aPoint^.y;
end;

procedure term_point_set_x(aPoint: pterm_point_t; aX: term_size_t);
begin
  aPoint^.x := aX;
end;

procedure term_point_set_y(aPoint: pterm_point_t; aY: term_size_t);
begin
  aPoint^.y := aY;
end;

function term_point_equal(aPoint1, aPoint2: pterm_point_t): boolean;
begin
  Result := (aPoint1^.x = aPoint2^.x) and (aPoint1^.y = aPoint2^.y);
end;

procedure term_point_set(aPoint: pterm_point_t; aX, aY: term_size_t);
begin
  aPoint^.x := aX;
  aPoint^.y := aY;
end;

procedure term_point_offset(aPoint: pterm_point_t; aX, aY: term_size_t);
begin
  aPoint^.x := aPoint^.x + aX;
  aPoint^.y := aPoint^.y + aY;
end;

procedure term_point_up(aPoint: pterm_point_t; aY: term_size_t);
begin
  aPoint^.y := aPoint^.y - aY;
end;

procedure term_point_up(aPoint: pterm_point_t);
begin
  term_point_up(aPoint, 1);
end;

procedure term_point_down(aPoint: pterm_point_t; aY: term_size_t);
begin
  aPoint^.y := aPoint^.y + aY;
end;

procedure term_point_down(aPoint: pterm_point_t);
begin
  aPoint^.y := aPoint^.y + 1;
end;

procedure term_point_left(aPoint: pterm_point_t; aX: term_size_t);
begin
  aPoint^.x := aPoint^.x - aX;
end;

procedure term_point_left(aPoint: pterm_point_t);
begin
  term_point_left(aPoint, 1);
end;

procedure term_point_right(aPoint: pterm_point_t; aX: term_size_t);
begin
  aPoint^.x := aPoint^.x + aX;
end;

procedure term_point_right(aPoint: pterm_point_t);
begin
  term_point_right(aPoint, 1);
end;


procedure term_check_nil(aTerm: pterm_t); {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
begin
  if aTerm = nil then
    raise Exception.Create('term_check_nil: aTerm is nil');
end;

function term_default_create_or_get: pterm_t;
var
  S: string;
begin
  if _term = nil then
  begin
    try
      // 测试/调试失败注入：设置环境变量可强制平台创建失败
      S := LowerCase(Trim(env_get('FAFAFA_TERM_FORCE_PLATFORM_FAIL')));
      if (S='1') or (S='true') or (S='on') or (S='yes') then
      begin
        _term := nil;
        G_TERM_LAST_ERROR := 'forced platform creation failure';
      end
      else
        // 平台创建函数自身会调用其 init 并在失败时返回 nil
        _term := term_create_platform;
      _term_initialized := (_term <> nil);
    except
      on E: Exception do
      begin
        _term := nil;
        _term_initialized := False;
        G_TERM_LAST_ERROR := E.ClassName + ': ' + E.Message;
      end;
      else
      begin
        _term := nil;
        _term_initialized := False;
        G_TERM_LAST_ERROR := 'unknown error during term_default_create_or_get';
      end;
    end;
  end;
  Result := _term;
end;

function term_init: Boolean;
var
  S: string;
  V: SizeUInt;
begin
  try
    G_TERM_LAST_ERROR := '';
    if not _term_initialized then
      _term := term_default_create_or_get;

    // 选择 Paste 存储后端（behind-a-flag）
    S := env_get('FAFAFA_TERM_PASTE_BACKEND');
    G_PASTE_BACKEND_RING := (LowerCase(Trim(S)) = 'ring');

    // 环境变量驱动的默认治理（仅在未显式设置时）
    if (G_PASTE_AUTO_KEEP_LAST = 0) and (LowerCase(env_get('FAFAFA_TERM_PASTE_DEFAULTS')) <> 'off') then
    begin
      S := env_get('FAFAFA_TERM_PASTE_KEEP_LAST');
      if ParseSizeWithSuffix(S, V) and (V > 0) then
        term_paste_set_auto_keep_last(V);
    end;

    // 事件合并/去抖策略开关（默认开启；faFaFa_term_coalesce_* 环境变量可覆盖）
    S := env_get('FAFAFA_TERM_COALESCE_MOVE');
    if S <> '' then G_TERM_COALESCE_MOVE := not (LowerCase(S) = '0') and not (LowerCase(S) = 'false');
    S := env_get('FAFAFA_TERM_COALESCE_WHEEL');
    if S <> '' then G_TERM_COALESCE_WHEEL := not (LowerCase(S) = '0') and not (LowerCase(S) = 'false');
    S := env_get('FAFAFA_TERM_DEBOUNCE_RESIZE');


    if S <> '' then G_TERM_DEBOUNCE_RESIZE := not (LowerCase(S) = '0') and not (LowerCase(S) = 'false');
    if (G_PASTE_MAX_BYTES = 0) and (LowerCase(env_get('FAFAFA_TERM_PASTE_DEFAULTS')) <> 'off') then
    begin
      S := env_get('FAFAFA_TERM_PASTE_MAX_BYTES');
      if ParseSizeWithSuffix(S, V) and (V > 0) then
        term_paste_set_max_bytes(V);
    end;
    // 快速路径阈值（>=1），默认 8
    S := env_get('FAFAFA_TERM_PASTE_TRIM_FASTPATH_DIV');
    if ParseSizeWithSuffix(S, V) and (V > 0) then
      term_paste_set_trim_fastpath_div(V);
    // 档位配置（仅当 DEFAULTS 不为 off 时）
    S := env_get('FAFAFA_TERM_PASTE_PROFILE');
    if (S <> '') and (LowerCase(env_get('FAFAFA_TERM_PASTE_DEFAULTS')) <> 'off') then
      term_paste_apply_profile(S);

    Result := (_term <> nil);
  except
    Result := False;
  end;

    // Debug behind-a-flag：FAFAFA_TERM_DEBUG=on|1 输出关键节点诊断（默认关闭）
    S := env_get('FAFAFA_TERM_DEBUG');
    if (CompareText(S, 'on') = 0) or (S = '1') then
    begin
      term_writeln('[DEBUG] term_init: default term created=', _term_initialized);
      term_writeln('[DEBUG] term_init: term_type=', TTerminalInfo.Create.GetTerminalType);
      term_writeln('[DEBUG] term_init: supports_ansi=', term_support_ansi);
    end;

end;

function term_name(aTerm: pterm_t): string;
begin
  term_check_nil(aTerm);
  Result := aTerm^.name;
end;

function term_last_error: string;
begin
  Result := G_TERM_LAST_ERROR;
end;


procedure term_done;
begin
  if (_term <> nil) then
  begin
    try
      if Assigned(_term^.reset) then _term^.reset(_term);
      if Assigned(_term^.destroy) then _term^.destroy(_term);
    finally
      _term := nil;
      _term_initialized := False;
    end;
  end;
end;

function term_name: string;
begin
  Result := term_name(_term);
end;

function term_data(aTerm: pterm_t): pointer;
begin
  term_check_nil(aTerm);
  Result := aTerm^.data;
end;

function term_data: pointer;
begin
  Result := term_data(_term);
end;

function term_compatibles(aTerm: pterm_t): term_compatibles_t;
begin
  term_check_nil(aTerm);
  Result := aTerm^.compatibles;
end;

function term_compatibles: term_compatibles_t;
begin
  Result := term_compatibles(_term);
end;

function term_support_compatibles(aTerm: pterm_t; const aCompatibles: term_compatibles_t): boolean;
var
  LCompatibles: term_compatibles_t;
  LCompatible:  term_compatible_t;
begin
  if aCompatibles = [] then
    exit(True);

  LCompatibles := term_compatibles(aTerm);

  for LCompatible in aCompatibles do
    if not (LCompatible in LCompatibles) then
      exit(False);

  Result := True;
end;

function term_support_compatibles(const aCompatibles: term_compatibles_t): boolean;
begin
  Result := term_support_compatibles(_term, aCompatibles);
end;

function term_support_compatible(aTerm: pterm_t; aCompatible: term_compatible_t): boolean;
begin
  Result := aCompatible in term_compatibles(aTerm);
end;

function term_support_compatible(aCompatible: term_compatible_t): boolean;
begin
  Result := term_support_compatible(_term, aCompatible);
end;

procedure term_reset(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.reset <> nil then
    aTerm^.reset(aTerm);
end;

procedure term_reset;
begin
  term_reset(_term);
end;

function term_support_clear(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_clear);
end;

function term_support_clear: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_clear(_term);
end;

function term_clear(aTerm: pterm_t): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.clear <> nil) and aTerm^.clear(aTerm);
end;

function term_clear: boolean;
begin
  Result := term_clear(_term);
end;

function term_support_beep(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_beep);
end;

function term_support_beep: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_beep(_term);
end;

function term_beep(aTerm: pterm_t): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.beep <> nil) and aTerm^.beep(aTerm);
end;

function term_beep: boolean;
begin
  Result := term_beep(_term);
end;

function term_support_flash(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_flash);
end;

function term_support_flash: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_flash(_term);
end;

function term_flash(aTerm: pterm_t): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.flash <> nil) and aTerm^.flash(aTerm);
end;

function term_flash: boolean;
begin
  Result := term_flash(_term);
end;

function term_support_ansi(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_ansi);
end;

function term_support_ansi: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_ansi(_term);
end;

function term_support_mouse(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_mouse);
end;

function term_support_mouse: boolean;
begin
  Result := term_support_mouse(_term);
end;

function term_mouse_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.mouse_enable <> nil) and aTerm^.mouse_enable(aTerm, aEnabled);
  if Result and (aTerm = _term) then
    G_TERM_STATE_MOUSE_BASE := aEnabled;
end;

function term_mouse_enable(aEnabled: Boolean): Boolean;
begin
  Result := term_mouse_enable(_term, aEnabled);
end;

function term_mouse_enable(aTerm: pterm_t): Boolean;
begin
  Result := term_mouse_enable(aTerm, True);
end;

function term_mouse_enable: Boolean;
begin
  Result := term_mouse_enable(_term, True);
end;

function term_mouse_disable(aTerm: pterm_t): Boolean;
begin
  Result := term_mouse_enable(aTerm, False);
end;
function term_mouse_sgr_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  if not term_support_compatible(aTerm, tc_ansi) then Exit(False);
  if aEnabled then term_write(aTerm, ANSI_MOUSE_SGR_ENABLE)
  else term_write(aTerm, ANSI_MOUSE_SGR_DISABLE);
  if (aTerm = _term) then G_TERM_STATE_MOUSE_SGR := aEnabled;
  Result := True;
end;

function term_mouse_sgr_enable(aEnabled: Boolean): Boolean;
begin
  Result := term_mouse_sgr_enable(_term, aEnabled);
end;

function term_mouse_drag_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  if not term_support_compatible(aTerm, tc_ansi) then Exit(False);
  if aEnabled then term_write(aTerm, ANSI_MOUSE_BUTTON_ENABLE)
  else term_write(aTerm, ANSI_MOUSE_BUTTON_DISABLE);
  if (aTerm = _term) then G_TERM_STATE_MOUSE_DRAG := aEnabled;
  Result := True;
end;


function term_paste_bracket_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  if not term_support_compatible(aTerm, tc_ansi) then
  begin
    G_TERM_LAST_ERROR := 'term_paste_bracket_enable: ANSI not supported';
    Exit(False);
  end;
  if aEnabled then term_write(aTerm, ANSI_BRACKETED_PASTE_ENABLE)
  else term_write(aTerm, ANSI_BRACKETED_PASTE_DISABLE);
  if (aTerm = _term) then G_TERM_STATE_PASTE := aEnabled;
  Result := True;
end;

function term_paste_bracket_enable(aEnabled: Boolean): Boolean;
begin
  Result := term_paste_bracket_enable(_term, aEnabled);
end;

function term_mode_guard_acquire(aTerm: pterm_t; const aFlags: term_mode_flags_t): TTermModeGuard;
begin
  Result.FTerm := aTerm;
  Result.FFlags := aFlags;
  // 记录 acquire 前的状态（仅针对默认 _term）
  Result.PrevMouseBase := G_TERM_STATE_MOUSE_BASE;
  Result.PrevMouseDrag := G_TERM_STATE_MOUSE_DRAG;
  Result.PrevMouseSGR  := G_TERM_STATE_MOUSE_SGR;
  Result.PrevFocus     := G_TERM_STATE_FOCUS;
  Result.PrevPaste     := G_TERM_STATE_PASTE;
  // 启用请求的模式（若已开启则幂等）
  if tm_mouse_enable_base in aFlags then if not G_TERM_STATE_MOUSE_BASE then term_mouse_enable(aTerm, True);
  if tm_mouse_button_drag in aFlags then if not G_TERM_STATE_MOUSE_DRAG then term_mouse_drag_enable(aTerm, True);
  if tm_mouse_sgr_1006 in aFlags then if not G_TERM_STATE_MOUSE_SGR then term_mouse_sgr_enable(aTerm, True);
  if tm_focus_1004 in aFlags then if not G_TERM_STATE_FOCUS then term_focus_enable(aTerm, True);
  if tm_paste_2004 in aFlags then if not G_TERM_STATE_PASTE then term_paste_bracket_enable(aTerm, True);
end;

function term_mode_guard_acquire_current(const aFlags: term_mode_flags_t): TTermModeGuard;
begin
  Result := term_mode_guard_acquire(_term, aFlags);
end;

procedure term_mode_guard_done(var aGuard: TTermModeGuard);
begin
  if aGuard.FTerm = nil then Exit;
  // 恢复到 acquire 前的状态（仅对参与的标志位）
  if tm_paste_2004 in aGuard.FFlags then term_paste_bracket_enable(aGuard.FTerm, aGuard.PrevPaste);
  if tm_focus_1004 in aGuard.FFlags then term_focus_enable(aGuard.FTerm, aGuard.PrevFocus);
  if tm_mouse_sgr_1006 in aGuard.FFlags then term_mouse_sgr_enable(aGuard.FTerm, aGuard.PrevMouseSGR);
  if tm_mouse_button_drag in aGuard.FFlags then term_mouse_drag_enable(aGuard.FTerm, aGuard.PrevMouseDrag);
  if tm_mouse_enable_base in aGuard.FFlags then term_mouse_enable(aGuard.FTerm, aGuard.PrevMouseBase);
  aGuard.FTerm := nil;
  aGuard.FFlags := [];
end;

function term_focus_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  if not term_support_compatible(aTerm, tc_ansi) then
  begin
    G_TERM_LAST_ERROR := 'term_focus_enable: ANSI not supported';
    Exit(False);
  end;
  if aEnabled then term_write(aTerm, ANSI_FOCUS_ENABLE)
  else term_write(aTerm, ANSI_FOCUS_DISABLE);
  if (aTerm = _term) then G_TERM_STATE_FOCUS := aEnabled;
  Result := True;
end;

function term_focus_enable(aEnabled: Boolean): Boolean;
begin
  Result := term_focus_enable(_term, aEnabled);
end;

function term_mouse_drag_enable(aEnabled: Boolean): Boolean;
begin
  Result := term_mouse_drag_enable(_term, aEnabled);

end;


function term_sync_update_enable(aTerm: pterm_t; aEnabled: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  if not term_support_compatible(aTerm, tc_ansi) then Exit(False);
  if aEnabled then term_write(aTerm, ANSI_SYNC_UPDATE_ENABLE)
  else term_write(aTerm, ANSI_SYNC_UPDATE_DISABLE);
  Result := True;
end;

function term_sync_update_enable(aEnabled: Boolean): Boolean;
begin
  Result := term_sync_update_enable(_term, aEnabled);
end;

function term_mouse_disable: Boolean;
begin
  Result := term_mouse_disable(_term);
end;


function term_scroll_region_set(aTerm: pterm_t; aTop, aBottom: term_size_t): boolean;
var s: string;
begin
  term_check_nil(aTerm);
  if not term_support_compatible(aTerm, tc_ansi) then Exit(False);
  s := TANSIGenerator.SetScrollRegion(aTop, aBottom);
  term_write(aTerm, s);
  Result := True;
end;

function term_scroll_region_set(aTop, aBottom: term_size_t): boolean;
begin
  Result := term_scroll_region_set(_term, aTop, aBottom);
end;

function term_support_title(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_title);
end;

function term_support_focus_1004(aTerm: pterm_t): boolean;
begin
  // 收敛判定：仅在后端明确宣称支持时返回 True；避免因 ANSI 即乐观宣称
  Result := term_support_compatible(aTerm, tc_focus_1004);
end;

function term_support_focus_1004: boolean;
begin
  Result := term_support_focus_1004(_term);
end;

function term_support_paste_2004(aTerm: pterm_t): boolean;
begin
  // 收敛判定：仅在后端明确宣称支持时返回 True；避免因 ANSI 即乐观宣称
  Result := term_support_compatible(aTerm, tc_paste_2004);
end;

function term_support_paste_2004: boolean;
begin
  Result := term_support_paste_2004(_term);
end;

function term_support_sync_update(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_sync_update) or term_support_compatible(aTerm, tc_ansi);
end;

function term_support_sync_update: boolean;
begin
  Result := term_support_sync_update(_term);
end;

function term_scroll_region_reset(aTerm: pterm_t): boolean;
begin
  term_check_nil(aTerm);
  if not term_support_compatible(aTerm, tc_ansi) then Exit(False);
  // CSI r 恢复整屏为滚动区域
  term_write(aTerm, #27'[r');
  Result := True;
end;

function term_scroll_region_reset: boolean;
begin
  Result := term_scroll_region_reset(_term);
end;

function term_support_title: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_title(_term);
end;

function term_title(aTerm: pterm_t): string;
begin
  term_check_nil(aTerm);

  if aTerm^.title_get <> nil then
    Result := aTerm^.title_get(aTerm)
  else
    Result := '';
end;

function term_title: string;
begin
  Result := term_title(_term);
end;

function term_support_title_set(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_title_set);
end;

function term_support_title_set: boolean;
begin
  Result := term_support_title_set(_term);
end;

function term_title_set(aTerm: pterm_t; const aTitle: string): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.title_set <> nil) and aTerm^.title_set(aTerm, PChar(@aTitle[1]));
end;

function term_title_set(const aTitle: string): boolean;
begin
  Result := term_title_set(_term, aTitle);
end;


function term_support_icon_set(aTerm: pterm_t): Boolean;
begin
  Result := term_support_compatible(aTerm, tc_icon_set);
end;

function term_support_icon_set: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_icon_set(_term);
end;

function term_icon_set(aTerm: pterm_t; const aIcon: string): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.icon_set <> nil) and aTerm^.icon_set(aTerm, PChar(@aIcon[1]));
end;

function term_icon_set(const aIcon: string): Boolean;
begin
  Result := term_icon_set(_term, aIcon);
end;

function term_color_to_hex(aColor: term_color_24bit_t): String;
var
  c: color_rgba_t;
begin
  c.r := aColor.r; c.g := aColor.g; c.b := aColor.b; c.a := 255;
  Result := color_to_hex(c);
end;

function term_support_color(aTerm: pterm_t): Boolean;
var
  LCompatibles: term_compatibles_t;
begin
  LCompatibles := term_compatibles(aTerm);
  Result := (tc_color_16    in LCompatibles) or
            (tc_color_256   in LCompatibles) or
            (tc_color_24bit in LCompatibles);
end;

function term_support_color: boolean;
begin
  Result := term_support_color(_term);
end;

function term_support_color_16(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_color_16);
end;

function term_support_color_16: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_color_16(_term);
end;

function term_support_color_256(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_color_256);
end;

function term_support_color_256: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_color_256(_term);
end;

function term_support_color_24bit(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_color_24bit);
end;

function term_support_color_24bit: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_color_24bit(_term);
end;

function term_support_color_16_palette(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_color_16_palette);
end;

function term_support_color_16_palette: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_color_16_palette(_term);
end;

function term_support_color_256_palette(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_color_256_palette);
end;

function term_support_color_256_palette: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_color_256_palette(_term);
end;

function term_support_color_palette_stack(aTerm: pterm_t): Boolean;
begin
  Result := term_support_compatible(aTerm, tc_color_palette_stack);
end;

function term_support_color_palette_stack: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_color_palette_stack(_term);
end;

procedure term_color_palette_push(aTerm: pterm_t;
  aStackIndex: term_color_palette_stack_index_t);
begin
  term_check_nil(aTerm);

  if aTerm^.color_palette_push <> nil then
    aTerm^.color_palette_push(aTerm, aStackIndex);
end;

procedure term_color_palette_push(aStackIndex: term_color_palette_stack_index_t);
begin
  term_color_palette_push(_term, aStackIndex);
end;

procedure term_color_palette_push(aTerm: pterm_t);
begin
  term_color_palette_push(aTerm, 0);
end;

procedure term_color_palette_push;
begin
  term_color_palette_push(_term);
end;

procedure term_color_palette_pop(aTerm: pterm_t; aStackIndex: term_color_palette_stack_index_t);
begin
  term_check_nil(aTerm);

  if aTerm^.color_palette_pop <> nil then
    aTerm^.color_palette_pop(aTerm, aStackIndex);
end;

procedure term_color_palette_pop(aStackIndex: term_color_palette_stack_index_t);
begin
  term_color_palette_pop(_term, aStackIndex);
end;

procedure term_color_palette_pop(aTerm: pterm_t);
begin
  term_color_palette_pop(aTerm, 0);
end;

procedure term_color_palette_pop;
begin
  term_color_palette_pop(_term);
end;

function term_color_palette_set(aTerm: pterm_t; aIndex: term_color_palette_index_t; const aColor: term_color_24bit_t): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.color_palette_set <> nil) and (aTerm^.color_palette_set(aTerm,aIndex,aColor));
end;

function term_color_palette_set(aIndex: term_color_palette_index_t; const aColor: term_color_24bit_t): Boolean;
begin
  Result := term_color_palette_set(_term, aIndex, aColor);
end;

{** ANSI Color System Integration Implementations *}

function term_color_fg_16(aTerm: pterm_t; aColor: Byte): Boolean;
var
  LSequence: string;
begin
  term_check_nil(aTerm);

  // 使用 ANSI 16 色前景色序列
  if aColor <= 7 then
    LSequence := CSI + IntToStr(30 + aColor) + 'm'
  else if aColor <= 15 then
    LSequence := CSI + IntToStr(90 + (aColor - 8)) + 'm'
  else
    LSequence := ANSI_FG_DEFAULT; // 超出范围使用默认色

  aTerm^.write(aTerm, PChar(LSequence), Length(LSequence));
  Result := True;
end;

function term_color_fg_16(aColor: Byte): Boolean;
begin
  Result := term_color_fg_16(_term, aColor);
end;

function term_color_bg_16(aTerm: pterm_t; aColor: Byte): Boolean;
var
  LSequence: string;
begin
  term_check_nil(aTerm);

  // 使用 ANSI 16 色背景色序列
  if aColor <= 7 then
    LSequence := CSI + IntToStr(40 + aColor) + 'm'
  else if aColor <= 15 then
    LSequence := CSI + IntToStr(100 + (aColor - 8)) + 'm'
  else
    LSequence := ANSI_BG_DEFAULT; // 超出范围使用默认色

  aTerm^.write(aTerm, PChar(LSequence), Length(LSequence));
  Result := True;
end;

function term_color_bg_16(aColor: Byte): Boolean;
begin
  Result := term_color_bg_16(_term, aColor);
end;

function term_color_fg_256(aTerm: pterm_t; aColor: Byte): Boolean;
var
  LSequence: string;
begin
  term_check_nil(aTerm);

  // 使用 ANSI 256 色前景色序列
  LSequence := ansi_fg_color_256(aColor);
  aTerm^.write(aTerm, PChar(LSequence), Length(LSequence));
  Result := True;
end;

function term_color_fg_256(aColor: Byte): Boolean;
begin
  Result := term_color_fg_256(_term, aColor);
end;

function term_color_bg_256(aTerm: pterm_t; aColor: Byte): Boolean;
var
  LSequence: string;
begin
  term_check_nil(aTerm);

  // 使用 ANSI 256 色背景色序列
  LSequence := ansi_bg_color_256(aColor);
  aTerm^.write(aTerm, PChar(LSequence), Length(LSequence));
  Result := True;
end;

function term_color_bg_256(aColor: Byte): Boolean;
begin
  Result := term_color_bg_256(_term, aColor);
end;

function term_color_fg_rgb(aTerm: pterm_t; aRed, aGreen, aBlue: Byte): Boolean;
var
  LSequence: string;
begin
  term_check_nil(aTerm);

  // 使用 ANSI 24 位真彩色前景色序列
  LSequence := ansi_fg_color_rgb(aRed, aGreen, aBlue);
  aTerm^.write(aTerm, PChar(LSequence), Length(LSequence));
  Result := True;
end;

function term_color_fg_rgb(aRed, aGreen, aBlue: Byte): Boolean;
begin
  Result := term_color_fg_rgb(_term, aRed, aGreen, aBlue);
end;

function term_color_bg_rgb(aTerm: pterm_t; aRed, aGreen, aBlue: Byte): Boolean;
var
  LSequence: string;
begin
  term_check_nil(aTerm);

  // 使用 ANSI 24 位真彩色背景色序列
  LSequence := ansi_bg_color_rgb(aRed, aGreen, aBlue);
  aTerm^.write(aTerm, PChar(LSequence), Length(LSequence));
  Result := True;
end;

function term_color_bg_rgb(aRed, aGreen, aBlue: Byte): Boolean;
begin
  Result := term_color_bg_rgb(_term, aRed, aGreen, aBlue);
end;

function term_color_reset(aTerm: pterm_t): Boolean;
var
  LSequence: string;
begin
  term_check_nil(aTerm);

  // 使用 ANSI 重置序列
  LSequence := ansi_color_reset;
  aTerm^.write(aTerm, PChar(LSequence), Length(LSequence));
  Result := True;
end;

function term_color_reset: Boolean;
begin
  Result := term_color_reset(_term);
end;

{** Predefined Color Convenience Functions *}

function term_color_black(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 0);
end;

function term_color_black: Boolean;
begin
  Result := term_color_black(_term);
end;

function term_color_red(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 1);
end;

function term_color_red: Boolean;
begin
  Result := term_color_red(_term);
end;

function term_color_green(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 2);
end;

function term_color_green: Boolean;
begin
  Result := term_color_green(_term);
end;

function term_color_yellow(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 3);
end;

function term_color_yellow: Boolean;
begin
  Result := term_color_yellow(_term);
end;

function term_color_blue(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 4);
end;

function term_color_blue: Boolean;
begin
  Result := term_color_blue(_term);
end;

function term_color_magenta(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 5);
end;

function term_color_magenta: Boolean;
begin
  Result := term_color_magenta(_term);
end;

function term_color_cyan(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 6);
end;

function term_color_cyan: Boolean;
begin
  Result := term_color_cyan(_term);
end;

function term_color_white(aTerm: pterm_t): Boolean;
begin
  Result := term_color_fg_16(aTerm, 7);
end;

function term_color_white: Boolean;
begin
  Result := term_color_white(_term);
end;

function term_support_size(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_size);
end;

function term_support_size: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_size(_term);
end;

function term_size(aTerm: pterm_t; var aWidth, aHeight: term_size_t): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.size_get <> nil) and aTerm^.size_get(aTerm, aWidth, aHeight);
end;

function term_size(var aWidth, aHeight: term_size_t): boolean;
begin
  if (_term = nil) then begin aWidth := 0; aHeight := 0; Exit(False); end;
  Result := term_size(_term, aWidth, aHeight);
end;

function term_size_width(aTerm: pterm_t): term_size_t;
var
  LHeight: term_size_t;
begin
  LHeight := 0; // avoid uninitialized var hint
  Result := 0;
  if term_size(aTerm, Result, LHeight) then Exit;
  // fallback Result already 0
end;

function term_size_width: term_size_t;
begin
  Result := term_size_width(_term);
end;

function term_size_height(aTerm: pterm_t): term_size_t;
var
  LWidth: term_size_t;
begin
  LWidth := 0; // avoid uninitialized var hint
  Result := 0;
  if term_size(aTerm, LWidth, Result) then Exit;
  // fallback Result already 0
end;

function term_size_height: term_size_t;
begin
  Result := term_size_height(_term);
end;

function term_support_size_set(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_size_set);
end;

function term_support_size_set: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_size_set(_term);
end;

function term_size_set(aTerm: pterm_t; aWidth, aHeight: term_size_t): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.size_set <> nil) and aTerm^.size_set(aTerm, aWidth, aHeight);
end;

function term_size_set(aWidth, aHeight: term_size_t): boolean;
begin
  Result := term_size_set(_term, aWidth, aHeight);
end;


procedure term_cursor_save(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_save <> nil then
    aTerm^.cursor_save(aTerm);
end;

procedure term_cursor_save;
begin
  term_cursor_save(_term);
end;

procedure term_cursor_restore(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_restore <> nil then
    aTerm^.cursor_restore(aTerm);
end;

procedure term_cursor_restore;
begin
  term_cursor_restore(_term);
end;

procedure term_cursor_push(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_push = nil then
    raise Exception.Create('term_cursor_push: cursor_push is nil');

  aTerm^.cursor_push(aTerm);
end;

procedure term_cursor_push;
begin
  term_cursor_push(_term);
end;

procedure term_cursor_pop(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_pop = nil then
    raise Exception.Create('term_cursor_pop: cursor_pop is nil');

  aTerm^.cursor_pop(aTerm);
end;

procedure term_cursor_pop;
begin
  term_cursor_pop(_term);
end;

function term_cursor(aTerm: pterm_t; var aX, aY: term_size_t): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_get <> nil) and aTerm^.cursor_get(aTerm, aX, aY);
end;

function term_cursor(var aX, aY: term_size_t): Boolean;
begin
  Result := term_cursor(_term, aX, aY);
end;

function term_cursor(aTerm: pterm_t; var aPoint: term_point_t): Boolean;
begin
  Result := term_cursor(aTerm, aPoint.x, aPoint.y);
end;

function term_cursor(var aPoint: term_point_t): Boolean;
begin
  Result := term_cursor(_term, aPoint);
end;

function term_cursor_x(aTerm: pterm_t): term_size_t;
var
  LY: term_size_t;
begin
  term_check_nil(aTerm);
  LY := 0; // avoid uninitialized var hint
  Result := 0;
  if aTerm^.cursor_x <> nil then
    Exit(aTerm^.cursor_x(aTerm));
  if term_cursor(aTerm, Result, LY) then Exit;
  // fallback Result already 0
end;

function term_cursor_x: term_size_t;
begin
  Result := term_cursor_x(_term);
end;

function term_cursor_y(aTerm: pterm_t): term_size_t;
var
  LX: term_size_t;
begin
  term_check_nil(aTerm);
  LX := 0; // avoid uninitialized var hint
  Result := 0;
  if aTerm^.cursor_y <> nil then
    Exit(aTerm^.cursor_y(aTerm));
  if term_cursor(aTerm, LX, Result) then Exit;
  // fallback Result already 0
end;

function term_cursor_y: term_size_t;
begin
  Result := term_cursor_y(_term);
end;

function term_cursor_set(aTerm: pterm_t; aX, aY: term_size_t): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_set <> nil) and aTerm^.cursor_set(aTerm, aX, aY);
end;

function term_cursor_set(aX, aY: term_size_t): Boolean;
begin
  Result := term_cursor_set(_term, aX, aY);
end;

function term_cursor_set(aTerm: pterm_t; const aPoint: term_point_t): Boolean;
begin
  Result := term_cursor_set(aTerm, aPoint.x, aPoint.y);
end;

function term_cursor_set(const aPoint: term_point_t): Boolean;
begin
  Result := term_cursor_set(_term, aPoint);
end;

function term_cursor_x_set(aTerm: pterm_t; aX: term_size_t): Boolean;
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_x_set <> nil then
    Result := aTerm^.cursor_x_set(aTerm, aX)
  else
    Result := term_cursor_set(aTerm, aX, term_cursor_y(aTerm));
end;

function term_cursor_x_set(aX: term_size_t): Boolean;
begin
  Result := term_cursor_x_set(_term, aX);
end;

function term_cursor_y_set(aTerm: pterm_t; aY: term_size_t): Boolean;
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_y_set <> nil then
    Result := aTerm^.cursor_y_set(aTerm, aY)
  else
    Result := term_cursor_set(aTerm, term_cursor_x(aTerm), aY);
end;

function term_cursor_y_set(aY: term_size_t): Boolean;
begin
  Result := term_cursor_y_set(_term, aY);
end;

procedure term_cursor_home(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_home <> nil then
    aTerm^.cursor_home(aTerm)
  else
    if not term_cursor_set(aTerm, 0, 0) then
      raise Exception.Create('term_cursor_home: term_cursor_set failed');
end;

procedure term_cursor_home;
begin
  term_cursor_home(_term);
end;

procedure term_cursor_up(aTerm: pterm_t; aCount: term_size_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_up <> nil then
    aTerm^.cursor_up(aTerm, aCount)
  else
    if not term_cursor_y_set(aTerm, Max(0, term_cursor_y(aTerm) - aCount)) then
      raise Exception.CreateFmt('term_cursor_up: term_cursor_y_set failed, aCount: %d, term_cursor_y: %d', [aCount, term_cursor_y(aTerm)]);
end;

procedure term_cursor_up(aCount: term_size_t);
begin
  term_cursor_up(_term, aCount);
end;

procedure term_cursor_up(aTerm: pterm_t);
begin
  term_cursor_up(aTerm, 1);
end;

procedure term_cursor_up;
begin
  term_cursor_up(_term);
end;

procedure term_cursor_left(aTerm: pterm_t; aCount: term_size_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_left <> nil then
    aTerm^.cursor_left(aTerm, aCount)
  else
    if not term_cursor_x_set(aTerm, Max(0, term_cursor_x(aTerm) - aCount)) then
      raise Exception.CreateFmt('term_cursor_left: term_cursor_x_set failed, aCount: %d, term_cursor_x: %d', [aCount, term_cursor_x(aTerm)]);
end;

procedure term_cursor_left(aCount: term_size_t);
begin
  term_cursor_left(_term, aCount);
end;

procedure term_cursor_left(aTerm: pterm_t);
begin
  term_cursor_left(aTerm, 1);
end;

procedure term_cursor_left;
begin
  term_cursor_left(_term);
end;

procedure term_cursor_down(aTerm: pterm_t; aCount: term_size_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_down <> nil then
    aTerm^.cursor_down(aTerm, aCount)
  else
    if not term_cursor_y_set(aTerm, term_cursor_y(aTerm) + aCount) then
      raise Exception.CreateFmt('term_cursor_down: term_cursor_y_set failed, aCount: %d, term_cursor_y: %d', [aCount, term_cursor_y(aTerm)]);
end;

procedure term_cursor_down(aCount: term_size_t);
begin
  term_cursor_down(_term, aCount);
end;

procedure term_cursor_down(aTerm: pterm_t);
begin
  term_cursor_down(aTerm, 1);
end;

procedure term_cursor_down;
begin
  term_cursor_down(_term);
end;

procedure term_cursor_right(aTerm: pterm_t; aCount: term_size_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_right <> nil then
    aTerm^.cursor_right(aTerm, aCount)
  else
    if not term_cursor_x_set(aTerm, term_cursor_x(aTerm) + aCount) then
      raise Exception.CreateFmt('term_cursor_right: term_cursor_x_set failed, aCount: %d, term_cursor_x: %d', [aCount, term_cursor_x(aTerm)]);
end;

procedure term_cursor_right(aCount: term_size_t);
begin
  term_cursor_right(_term, aCount);
end;

procedure term_cursor_right(aTerm: pterm_t);
begin
  term_cursor_right(aTerm, 1);
end;

procedure term_cursor_right;
begin
  term_cursor_right(_term);
end;

procedure term_cursor_line(aTerm: pterm_t; aLine: term_size_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_line <> nil then
    aTerm^.cursor_line(aTerm, aLine)
  else
    if not term_cursor_y_set(aTerm, aLine) then
      raise Exception.CreateFmt('term_cursor_line: term_cursor_y_set failed, aLine: %d', [aLine]);
end;

procedure term_cursor_line(aLine: term_size_t);
begin
  term_cursor_line(_term, aLine);
end;

procedure term_cursor_line_next(aTerm: pterm_t; aCount: term_size_t);
var
  LWidth, LHeight, LX, LY: term_size_t;
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_line_next <> nil then
  begin
    aTerm^.cursor_line_next(aTerm, aCount);
    Exit;
  end;

  // Initialize locals to avoid hints; values will be overwritten by calls below
  LWidth := 0; LHeight := 0; LX := 0; LY := 0;

  if not term_size(aTerm, LWidth, LHeight) then
    raise Exception.Create('term_cursor_line_next: term_size failed');

  if not term_cursor(aTerm, LX, LY) then
    raise Exception.Create('term_cursor_line_next: term_cursor failed');

  if not term_cursor_set(aTerm, LX, Min(LHeight - 1, LY + aCount)) then
    raise Exception.CreateFmt('term_cursor_line_next: term_cursor_set failed, aCount: %d, LX: %d, LY: %d', [aCount, LX, LY]);
end;

procedure term_cursor_line_next(aCount: term_size_t);
begin
  term_cursor_line_next(_term, aCount);
end;

procedure term_cursor_line_next(aTerm: pterm_t);
begin
  term_cursor_line_next(aTerm, 1);
end;

procedure term_cursor_line_next;
begin
  term_cursor_line_next(_term);
end;

procedure term_cursor_line_prev(aTerm: pterm_t; aCount: term_size_t);
var
  LX, LY: term_size_t;
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_line_prev <> nil then
  begin
    aTerm^.cursor_line_prev(aTerm, aCount);
    Exit;
  end;

  // Initialize locals to avoid hints; values will be overwritten by calls below
  LX := 0; LY := 0;

  if not term_cursor(aTerm, LX, LY) then
    raise Exception.Create('term_cursor_line_prev: term_cursor failed');

  if not term_cursor_set(aTerm, LX, Max(0, LY - aCount)) then
    raise Exception.CreateFmt('term_cursor_line_prev: term_cursor_set failed, aCount: %d, LX: %d, LY: %d', [aCount, LX, LY]);
end;

procedure term_cursor_line_prev(aCount: term_size_t);
begin
  term_cursor_line_prev(_term, aCount);
end;

procedure term_cursor_line_prev(aTerm: pterm_t);
begin
  term_cursor_line_prev(aTerm, 1);
end;

procedure term_cursor_line_prev;
begin
  term_cursor_line_prev(_term);
end;

procedure term_cursor_col(aTerm: pterm_t; aColumn: term_size_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_col <> nil then
    aTerm^.cursor_col(aTerm, aColumn)
  else
    if not term_cursor_x_set(aTerm, aColumn) then
      raise Exception.CreateFmt('term_cursor_col: term_cursor_x_set failed, aColumn: %d', [aColumn]);
end;

procedure term_cursor_col(aColumn: term_size_t);
begin
  term_cursor_col(_term, aColumn);
end;


function term_cursor_visible_set(aTerm: pterm_t; aVisible: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_visible_set <> nil) and aTerm^.cursor_visible_set(aTerm, aVisible);
end;

function term_cursor_visible_set(aVisible: Boolean): Boolean;
begin
  Result := term_cursor_visible_set(_term, aVisible);
end;

function term_cursor_show(aTerm: pterm_t): Boolean;
begin
  Result := term_cursor_visible_set(aTerm, True);
end;

function term_cursor_show: Boolean;
begin
  Result := term_cursor_show(_term);
end;

function term_cursor_hide(aTerm: pterm_t): Boolean;
begin
  Result := term_cursor_visible_set(aTerm, False);
end;

function term_cursor_hide: Boolean;
begin
  Result := term_cursor_hide(_term);
end;

function term_cursor_shape_set(aTerm: pterm_t; aShape: term_cursor_shape_t): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_shape_set <> nil) and aTerm^.cursor_shape_set(aTerm, aShape);
end;

function term_cursor_shape_set(aShape: term_cursor_shape_t): Boolean;
begin
  Result := term_cursor_shape_set(_term, aShape);
end;

procedure term_cursor_shape_reset(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.cursor_shape_reset <> nil then
    aTerm^.cursor_shape_reset(aTerm);
end;

procedure term_cursor_shape_reset;
begin
  term_cursor_shape_reset(_term);
end;

function term_cursor_size_set(aTerm: pterm_t; aSize: UInt8): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_size_set <> nil) and aTerm^.cursor_size_set(aTerm, aSize);
end;

function term_cursor_size_set(aSize: UInt8): Boolean;
begin
  Result := term_cursor_size_set(_term, aSize);
end;

function term_cursor_blink_set(aTerm: pterm_t; aBlink: Boolean): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_blink_set <> nil) and aTerm^.cursor_blink_set(aTerm, aBlink);
end;

function term_cursor_blink_set(aBlink: Boolean): Boolean;
begin
  Result := term_cursor_blink_set(_term, aBlink);
end;

function term_cursor_blink_enable(aTerm: pterm_t): Boolean;
begin
  Result := term_cursor_blink_set(aTerm, True);
end;

function term_cursor_blink_enable: Boolean;
begin
  Result := term_cursor_blink_enable(_term);
end;

function term_cursor_blink_disable(aTerm: pterm_t): Boolean;
begin
  Result := term_cursor_blink_set(aTerm, False);
end;

function term_cursor_blink_disable: Boolean;
begin
  Result := term_cursor_blink_disable(_term);
end;

function term_cursor_color_palette_set(aTerm: pterm_t; aIndex: term_color_palette_index_t): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_color_palette_set <> nil) and aTerm^.cursor_color_palette_set(aTerm, aIndex);
end;

function term_cursor_color_palette_set(aIndex: term_color_palette_index_t): Boolean;
begin
  Result := term_cursor_color_palette_set(_term, aIndex);
end;

function term_cursor_color_set(aTerm: pterm_t; const aColor: term_color_24bit_t): Boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.cursor_color_set <> nil) and aTerm^.cursor_color_set(aTerm, aColor);
end;

function term_cursor_color_set(const aColor: term_color_24bit_t): Boolean;
begin
  Result := term_cursor_color_set(_term, aColor);
end;



function term_support_alternate_screen(aTerm: pterm_t): boolean;
begin
  Result := term_support_compatible(aTerm, tc_alternate_screen);
end;

function term_support_alternate_screen: boolean;
begin
  if (_term = nil) then Exit(False);
  Result := term_support_alternate_screen(_term);
end;

function term_alternate_screen_enable(aTerm: pterm_t; aEnable: boolean): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.alternate_screen_enable <> nil) and aTerm^.alternate_screen_enable(aTerm, aEnable);
end;

function term_alternate_screen_enable(aEnable: boolean): boolean;
begin
  Result := term_alternate_screen_enable(_term, aEnable);
end;

function term_alternate_screen_enable(aTerm: pterm_t): boolean;
begin
  Result := term_alternate_screen_enable(aTerm, True);
end;

function term_alternate_screen_enable: boolean;
begin
  Result := term_alternate_screen_enable(_term);
end;

function term_alternate_screen_disable(aTerm: pterm_t): boolean;
begin
  Result := term_alternate_screen_enable(aTerm, False);
end;

function term_alternate_screen_disable: boolean;
begin
  Result := term_alternate_screen_disable(_term);
end;

function term_raw_mode_enable(aTerm: pterm_t; aEnable: boolean): boolean;
begin
  term_check_nil(aTerm);
  Result := (aTerm^.raw_mode_enable <> nil) and aTerm^.raw_mode_enable(aTerm, aEnable);
end;

function term_raw_mode_enable(aEnable: boolean): boolean;
begin
  Result := term_raw_mode_enable(_term, aEnable);
end;

function term_raw_mode_enable(aTerm: pterm_t): boolean;
begin
  Result := term_raw_mode_enable(aTerm, True);
end;

function term_raw_mode_disable(aTerm: pterm_t): boolean;
begin
  Result := term_raw_mode_enable(aTerm, False);
end;

function term_raw_mode_disable: boolean;
begin
  Result := term_raw_mode_disable(_term);
end;



function HexToInt(c: Char): Integer; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
begin
  case c of
    '0'..'9': Result := Ord(c) - Ord('0');
    'A'..'F': Result := Ord(c) - Ord('A') + 10;
    'a'..'f': Result := Ord(c) - Ord('a') + 10;
  else
    Result := 0;
  end;
end;

function term_color_24bit_hex(const aHex: String): term_color_24bit_t;
var
  c: color_rgba_t;
begin
  c := color_from_hex(aHex);
  Result := term_color_24bit_rgb(c.r, c.g, c.b);
end;

function term_color_24bit_gray(aGray: UInt8): term_color_24bit_t;
begin
  Result.r        := aGray;
  Result.g        := aGray;
  Result.b        := aGray;
  Result.reserved := 0;
end;

function term_attr_16(const aForeground, aBackground: term_color_16_t; const aStyles: term_attr_styles_t): term_attr_16_t;
begin
  Result.foreground := aForeground;
  Result.background := aBackground;
  Result.styles     := aStyles;
end;

function term_attr_256(const aForeground, aBackground: term_color_256_t; const aStyles: term_attr_styles_t): term_attr_256_t;
begin
  Result.foreground := aForeground;
  Result.background := aBackground;
  Result.styles     := aStyles;
end;

function term_attr_24bit(const aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t): term_attr_24bit_t;
begin
  Result.foreground := aForeground;
  Result.background := aBackground;
  Result.styles     := aStyles;
end;

procedure term_attr_push(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_push <> nil then
    aTerm^.attr_push(aTerm);
end;

procedure term_attr_push;
begin
  term_attr_push(_term);
end;

procedure term_attr_pop(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_pop <> nil then
    aTerm^.attr_pop(aTerm);
end;

procedure term_attr_pop;
begin
  term_attr_pop(_term);
end;

procedure term_attr_set(aTerm: pterm_t; const aAttr: term_attr_16_t);
begin
  term_attr_set(aTerm, aAttr.foreground, aAttr.background, aAttr.styles);
end;

procedure term_attr_set(const aAttr: term_attr_16_t);
begin
  term_attr_set(_term, aAttr);
end;

procedure term_attr_set(aTerm: pterm_t; const aAttr: term_attr_256_t);
begin
  term_attr_set(aTerm, aAttr.foreground, aAttr.background, aAttr.styles);
end;

procedure term_attr_set(const aAttr: term_attr_256_t);
begin
  term_attr_set(_term, aAttr);
end;

procedure term_attr_set(aTerm: pterm_t; const aAttr: term_attr_24bit_t);
begin
  term_attr_set(aTerm, aAttr.foreground, aAttr.background, aAttr.styles);
end;

procedure term_attr_set(const aAttr: term_attr_24bit_t);
begin
  term_attr_set(_term, aAttr);
end;

procedure term_attr_set(aTerm: pterm_t; aForeground, aBackground: term_color_palette_index_t; const aStyles: term_attr_styles_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
    aTerm^.attr_color_palette_set(aTerm, aForeground, aBackground, aStyles);
end;

procedure term_attr_set(aForeground, aBackground: term_color_palette_index_t; const aStyles: term_attr_styles_t);
begin
  term_attr_set(_term, aForeground, aBackground, aStyles);
end;

procedure term_attr_set(aTerm: pterm_t; aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t);
begin
  term_check_nil(aTerm);

  // Prefer truecolor when supported by both backend and terminal
  if (aTerm^.attr_color_24bit_set <> nil) and term_support_color_24bit(aTerm) then
  begin
    aTerm^.attr_color_24bit_set(aTerm, aForeground, aBackground, aStyles);
    Exit;
  end;

  // Fallback to 256-color palette if supported
  if (aTerm^.attr_color_palette_set <> nil) and term_support_color_256(aTerm) then
  begin
    aTerm^.attr_color_palette_set(aTerm,
      term_color_approx_256(aForeground),
      term_color_approx_256(aBackground),
      aStyles);
    Exit;
  end;

  // Fallback to 16-color palette if supported
  if (aTerm^.attr_color_palette_set <> nil) and term_support_color_16(aTerm) then
  begin
    aTerm^.attr_color_palette_set(aTerm,
      term_color_approx_16(aForeground),
      term_color_approx_16(aBackground),
      aStyles);
    Exit;
  end;
  // Else: no color support; keep silent no-op
end;

procedure term_attr_set(const aForeground, aBackground: term_color_24bit_t; const aStyles: term_attr_styles_t);
begin
  term_attr_set(_term, aForeground, aBackground, aStyles);
end;

procedure term_attr_foreground_set(aTerm: pterm_t; aColor: term_color_palette_index_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_foreground_palette_set <> nil then
    aTerm^.attr_foreground_palette_set(aTerm, aColor);
end;

procedure term_attr_foreground_set(aColor: term_color_palette_index_t);
begin
  term_attr_foreground_set(_term, aColor);
end;

procedure term_attr_foreground_set(aTerm: pterm_t; const aColor: term_color_24bit_t);
begin
  term_check_nil(aTerm);

  if (aTerm^.attr_foreground_24bit_set <> nil) and term_support_color_24bit(aTerm) then
  begin
    aTerm^.attr_foreground_24bit_set(aTerm, aColor);
    Exit;
  end
  else if (aTerm^.attr_foreground_palette_set <> nil) and term_support_color_256(aTerm) then
  begin
    aTerm^.attr_foreground_palette_set(aTerm, term_color_approx_256(aColor));
    Exit;
  end
  else if (aTerm^.attr_foreground_palette_set <> nil) and term_support_color_16(aTerm) then
  begin
    aTerm^.attr_foreground_palette_set(aTerm, term_color_approx_16(aColor));
    Exit;
  end;
end;

procedure term_attr_foreground_set(const aColor: term_color_24bit_t);
begin
  term_attr_foreground_set(_term, aColor);
end;

procedure term_attr_background_set(aTerm: pterm_t; aColor: term_color_palette_index_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_background_palette_set <> nil then
    aTerm^.attr_background_palette_set(aTerm, aColor);
end;

procedure term_attr_background_set(aColor: term_color_palette_index_t);
begin
  term_attr_background_set(_term, aColor);
end;

procedure term_attr_background_set(aTerm: pterm_t; const aColor: term_color_24bit_t);
begin
  term_check_nil(aTerm);

  if (aTerm^.attr_background_24bit_set <> nil) and term_support_color_24bit(aTerm) then
  begin
    aTerm^.attr_background_24bit_set(aTerm, aColor);
    Exit;
  end
  else if (aTerm^.attr_background_palette_set <> nil) and term_support_color_256(aTerm) then
  begin
    aTerm^.attr_background_palette_set(aTerm, term_color_approx_256(aColor));
    Exit;
  end
  else if (aTerm^.attr_background_palette_set <> nil) and term_support_color_16(aTerm) then
  begin
    aTerm^.attr_background_palette_set(aTerm, term_color_approx_16(aColor));
    Exit;
  end;
end;

procedure term_attr_background_set(const aColor: term_color_24bit_t);
begin
  term_attr_background_set(_term, aColor);
end;

procedure term_attr_reset(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_reset <> nil then
    aTerm^.attr_reset(aTerm);
end;

procedure term_attr_reset;
begin
  term_attr_reset(_term);
end;

procedure term_attr_foreground_reset(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_foreground_reset <> nil then
    aTerm^.attr_foreground_reset(aTerm);
end;

procedure term_attr_foreground_reset;
begin
  term_attr_foreground_reset(_term);
end;

procedure term_attr_background_reset(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_background_reset <> nil then
    aTerm^.attr_background_reset(aTerm);
end;

procedure term_attr_background_reset;
begin
  term_attr_background_reset(_term);
end;

procedure term_attr_styles_reset(aTerm: pterm_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_styles_reset <> nil then
    aTerm^.attr_styles_reset(aTerm);
end;

procedure term_attr_styles_reset;
begin
  term_attr_styles_reset(_term);
end;

function ucs4Char_to_utf8(aUCS4: UCS4Char; aUtf8: PAnsiChar; aUtf8Size: SizeUInt): SizeInt;
begin
  if aUCS4 <= $7F then
  begin
    if aUtf8Size < 1 then
      Exit(-1);

    aUtf8[0] := AnsiChar(aUCS4);
    Result   := 1;
  end
  else if aUCS4 <= $7FF then
  begin
    if aUtf8Size < 2 then
      Exit(-1);

    aUtf8[0] := AnsiChar($C0 or (aUCS4 shr 6));
    aUtf8[1] := AnsiChar($80 or (aUCS4 and $3F));
    Result   := 2;
  end
  else if aUCS4 <= $FFFF then
  begin
    if aUtf8Size < 3 then
      Exit(-1);

    aUtf8[0] := AnsiChar($E0 or ( aUCS4 shr 12));
    aUtf8[1] := AnsiChar($80 or ((aUCS4 shr 6) and $3F));
    aUtf8[2] := AnsiChar($80 or ( aUCS4 and $3F));
    Result   := 3;
  end
  else
  begin
    if aUtf8Size < 4 then
      Exit(-1);

    aUtf8[0] := AnsiChar($F0 or ( aUCS4 shr 18));
    aUtf8[1] := AnsiChar($80 or ((aUCS4 shr 12) and $3F));
    aUtf8[2] := AnsiChar($80 or ((aUCS4 shr 6) and $3F));
    aUtf8[3] := AnsiChar($80 or ( aUCS4 and $3F));
    Result := 4;
  end;
end;

function ucs4Char_to_utf8(aUCS4: UCS4Char): ansistring;
var
  LLen : SizeInt;
begin
  Result := '';
  SetLength(Result, 4);
  LLen := ucs4Char_to_utf8(aUCS4, @Result[1], 4);

  if LLen < 4 then
    SetLength(Result, LLen);
end;

function ucs4String_to_utf8(const aUCS4: UCS4String): ansistring;
var
  i, LInLen, LOutLen, LLenTmp: SizeInt;
  LP: PAnsiChar;
begin
  LInLen := Length(aUCS4);

  if LInLen = 0 then
    Exit('');

  SetLength(Result, LInLen * 4);
  LP := PAnsiChar(@Result[1]);
  LOutLen := 0;

  for i := 0 to pred(LInLen) do
  begin
    LLenTmp := ucs4Char_to_utf8(aUCS4[i], LP, 4);
    inc(LP, LLenTmp);
    inc(LOutLen, LLenTmp);
  end;

  if LOutLen < Length(Result) then
    SetLength(Result, LOutLen);
end;

function vars_str(const aArray : array of const): string;

  function var_str(const arg : TVarRec): string;
  begin
    case arg.VType of
      vtInteger:  Result := IntToStr(arg.VInteger);
      vtBoolean:  Result := BoolToStr(arg.VBoolean, True);
      vtChar:     Result := arg.VChar;
      {$IFNDEF FPUNONE}
      vtExtended: Result := FloatToStr(arg.VExtended^);
      {$ENDIF}
      vtString:
      begin
        if arg.VString <> nil then
          Result := arg.VString^
        else
          Result := '';
      end;
      vtPChar:
      begin
        if arg.VPChar <> nil then
          Result := string(arg.VPChar)
        else
          Result := '';
      end;
      vtAnsiString: Result := ansistring(arg.VAnsiString);
      vtWideChar:   Result := UTF8Encode(WideString(arg.VWideChar));
      vtPWideChar:
      begin
        if arg.VPWideChar <> nil then
          Result := UTF8Encode(WideString(arg.VPWideChar))
        else
          Result := '';
      end;
      vtWideString:    Result := UTF8Encode(WideString(arg.VWideString));
      vtUnicodeString: Result := UTF8Encode(unicodestring(arg.VUnicodeString));
      vtInt64:         Result := IntToStr(arg.VInt64^);
      vtCurrency:      Result := CurrToStr(arg.VCurrency^);
      {$IFDEF FPC_HAS_FEATURE_VARIANTS}
      vtVariant:       Result := VarToStr(variant(arg.VVariant^));
      {$ENDIF}
      {$IFDEF FPC_HAS_FEATURE_CLASSES}
      vtObject:
      begin
        if arg.VObject <> nil then
          Result := '(Object: ' + arg.VObject.ClassName + ')'
        else
          Result := '(Object: nil)';
      end;
      vtClass:     Result := '(Class: ' + arg.VClass.ClassName + ')';
      {$ENDIF}
      vtInterface: Result := '(Interface)';
      else
                   Result := '(Unknown type: ' + IntToStr(arg.VType) + ')';
    end;
  end;

const
  SB_INITIAL = 8;
var
  LLen: SizeInt;
  i:    integer;
  LSB:  TStringBuilder;
begin
  Result := '';
  LLen := Length(aArray);

  if LLen > 0 then
  begin
    if LLen > SB_INITIAL then
    begin
      LSB := TStringBuilder.Create(LLen * 16); // 预估长度,每个元素预留16个字符
      try
        for i := 0 to Pred(LLen) do
          LSB.Append(var_str(TVarRec(aArray[i])));

        Result := LSB.ToString;
      finally
        LSB.Free;
      end;
    end
    else // 数组长度小于等于 SB_INITIAL(默认8) 时,直接拼接
      for i := 0 to Pred(LLen) do
        Result := Result + var_str(TVarRec(aArray[i]));
  end;
end;



procedure term_write(aTerm: pterm_t; const aData: PAnsiChar; aLength: SizeUInt);
begin
  term_check_nil(aTerm);

  if aTerm^.write <> nil then
    aTerm^.write(aTerm, aData, aLength);
end;

procedure term_write(const aData: PAnsiChar; aLength: SizeUInt);
begin
  term_write(_term, aData, aLength);
end;

procedure term_write(aTerm: pterm_t; const aData: PWideChar; aLength: SizeUInt);
begin
  term_check_nil(aTerm);

  if aTerm^.write_wide <> nil then
    aTerm^.write_wide(aTerm, aData, aLength);
end;

procedure term_write(const aData: PWideChar; aLength: SizeUInt);
begin
  term_write(_term, aData, aLength);
end;

procedure term_write(aTerm: pterm_t; const aData: PUCS4Char; aLength: SizeUInt);
begin
  term_check_nil(aTerm);

  if aTerm^.write_ucs4 <> nil then
    aTerm^.write_ucs4(aTerm, aData, aLength);
end;

procedure term_write(const aData: PUCS4Char; aLength: SizeUInt);
begin
  term_write(_term, aData, aLength);
end;

procedure term_write(aTerm: pterm_t; const aText: string);
begin
  if Length(aText) = 0 then Exit;
  term_write(aTerm, PAnsiChar(@aText[1]), Length(aText));
end;

procedure term_write(const aText: string);
begin
  term_write(_term, aText);
end;

procedure term_write(aTerm: pterm_t; const aText: widestring);
begin
  if Length(aText) = 0 then Exit;
  term_write(aTerm, PWideChar(@aText[1]), Length(aText));
end;

procedure term_write(const aText: widestring);
begin
  term_write(_term, aText);
end;

procedure term_write(aTerm: pterm_t; aChar: UCS4Char);
begin
  term_write(aTerm, PUCS4Char(@aChar), 1);
end;

procedure term_write(aChar: UCS4Char);
begin
  term_write(_term, aChar);
end;

procedure term_write(aTerm: pterm_t; const aText: ucs4string);
begin
  if Length(aText) = 0 then Exit;
  term_write(aTerm, PUCS4Char(@aText[0]), Length(aText));
end;

procedure term_write(const aText: ucs4string);
begin
  term_write(_term, aText);
end;

procedure term_write(aTerm: pterm_t; const aArrays: array of const);
begin
  term_write(aTerm, vars_str(aArrays));
end;

procedure term_write(const aArrays: array of const);
begin
  term_write(_term, aArrays);
end;

procedure term_write(aTerm: pterm_t; const aData: Variant);
begin
  if VarIsType(aData,[varUString,varOleStr]) then
    term_write(aTerm, WideString(aData))
  else
    term_write(aTerm, vartostr(aData));
end;

procedure term_write(const aData: Variant);
begin
  term_write(_term, aData);
end;

procedure term_write(aTerm: pterm_t; const aText: String; const aAttr: term_attr_16_t);
begin
  term_check_nil(aTerm);
  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: String; const aAttr: term_attr_16_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: String; const aAttr: term_attr_256_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: String; const aAttr: term_attr_256_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: String; const aAttr: term_attr_24bit_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_24bit_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: String; const aAttr: term_attr_24bit_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_16_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: WideString; const aAttr: term_attr_16_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_256_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: WideString; const aAttr: term_attr_256_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_24bit_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_24bit_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: WideString; const aAttr: term_attr_24bit_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_16_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: UCS4String; const aAttr: term_attr_16_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_256_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: UCS4String; const aAttr: term_attr_256_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_24bit_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_24bit_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aText);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aText);
end;

procedure term_write(const aText: UCS4String; const aAttr: term_attr_24bit_t);
begin
  term_write(_term, aText, aAttr);
end;

procedure term_write(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_16_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aChar);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aChar);
end;

procedure term_write(aChar: UCS4Char; const aAttr: term_attr_16_t);
begin
  term_write(_term, aChar, aAttr);
end;

procedure term_write(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_256_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aChar);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aChar);
end;

procedure term_write(aChar: UCS4Char; const aAttr: term_attr_256_t);
begin
  term_write(_term, aChar, aAttr);
end;

procedure term_write(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_24bit_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_24bit_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aChar);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aChar);
end;

procedure term_write(aChar: UCS4Char; const aAttr: term_attr_24bit_t);
begin
  term_write(_term, aChar, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_16_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aArrays);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aArrays);
end;

procedure term_write(const aArrays: array of const; const aAttr: term_attr_16_t);
begin
  term_write(_term, aArrays, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_256_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aArrays);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aArrays);
end;

procedure term_write(const aArrays: array of const; const aAttr: term_attr_256_t);
begin
  term_write(_term, aArrays, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_24bit_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_24bit_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aArrays);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aArrays);
end;

procedure term_write(const aArrays: array of const; const aAttr: term_attr_24bit_t);
begin
  term_write(_term, aArrays, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_16_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aData);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aData);
end;

procedure term_write(const aData: Variant; const aAttr: term_attr_16_t);
begin
  term_write(_term, aData, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_256_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_palette_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aData);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aData);
end;

procedure term_write(const aData: Variant; const aAttr: term_attr_256_t);
begin
  term_write(_term, aData, aAttr);
end;

procedure term_write(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_24bit_t);
begin
  term_check_nil(aTerm);

  if aTerm^.attr_color_24bit_set <> nil then
  begin
    term_attr_push(aTerm);
    term_attr_set(aTerm, aAttr);
    term_write(aTerm, aData);
    term_attr_pop(aTerm);
  end
  else
    term_write(aTerm, aData);
end;

procedure term_write(const aData: Variant; const aAttr: term_attr_24bit_t);
begin
  term_write(_term, aData, aAttr);
end;

procedure term_writeln(aTerm: pterm_t);
begin
  term_write(aTerm, sLineBreak);
end;

procedure term_writeln;
begin
  term_writeln(_term);
end;

procedure term_writeln(aTerm: pterm_t; const aText: string);
begin
  term_write(aTerm, aText);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: string);
begin
  term_writeln(_term, aText);
end;

procedure term_writeln(aTerm: pterm_t; const aText: widestring);
begin
  term_write(aTerm, aText);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: widestring);
begin
  term_writeln(_term, aText);
end;

procedure term_writeln(aTerm: pterm_t; const aText: ucs4string);
begin
  term_write(aTerm, aText);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: ucs4string);
begin
  term_writeln(_term, aText);
end;

procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char);
begin
  term_write(aTerm, aChar);
  term_writeln(aTerm);
end;

procedure term_writeln(aChar: UCS4Char);
begin
  term_writeln(_term, aChar);
end;

procedure term_writeln(aTerm: pterm_t; const aArrays: array of const);
begin
  term_write(aTerm, vars_str(aArrays));
  term_writeln(aTerm);
end;

procedure term_writeln(const aArrays: array of const);
begin
  term_writeln(_term, aArrays);
end;

procedure term_writeln(aTerm: pterm_t; const aData: Variant);
begin
  term_write(aTerm, aData);
  term_writeln(aTerm);
end;

procedure term_writeln(const aData: Variant);
begin
  term_writeln(_term, aData);
end;

procedure term_writeln(aTerm: pterm_t; const aText: String; const aAttr: term_attr_16_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: String; const aAttr: term_attr_16_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: String; const aAttr: term_attr_256_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: String; const aAttr: term_attr_256_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: String; const aAttr: term_attr_24bit_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: String; const aAttr: term_attr_24bit_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_16_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: WideString; const aAttr: term_attr_16_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_256_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: WideString; const aAttr: term_attr_256_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: WideString; const aAttr: term_attr_24bit_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: WideString; const aAttr: term_attr_24bit_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_16_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: UCS4String; const aAttr: term_attr_16_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_256_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: UCS4String; const aAttr: term_attr_256_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aText: UCS4String; const aAttr: term_attr_24bit_t);
begin
  term_write(aTerm, aText, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aText: UCS4String; const aAttr: term_attr_24bit_t);
begin
  term_writeln(_term, aText, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_16_t);
begin
  term_write(aTerm, aChar, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(aChar: UCS4Char; const aAttr: term_attr_16_t);
begin
  term_writeln(_term, aChar, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_256_t);
begin
  term_write(aTerm, aChar, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(aChar: UCS4Char; const aAttr: term_attr_256_t);
begin
  term_writeln(_term, aChar, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; aChar: UCS4Char; const aAttr: term_attr_24bit_t);
begin
  term_write(aTerm, aChar, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(aChar: UCS4Char; const aAttr: term_attr_24bit_t);
begin
  term_writeln(_term, aChar, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_16_t);
begin
  term_write(aTerm, aArrays, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aArrays: array of const; const aAttr: term_attr_16_t);
begin
  term_writeln(_term, aArrays, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_256_t);
begin
  term_write(aTerm, aArrays, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aArrays: array of const; const aAttr: term_attr_256_t);
begin
  term_writeln(_term, aArrays, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aArrays: array of const; const aAttr: term_attr_24bit_t);
begin
  term_write(aTerm, aArrays, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aArrays: array of const; const aAttr: term_attr_24bit_t);
begin
  term_writeln(_term, aArrays, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_16_t);
begin
  term_write(aTerm, aData, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aData: Variant; const aAttr: term_attr_16_t);
begin
  term_writeln(_term, aData, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_256_t);
begin
  term_write(aTerm, aData, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aData: Variant; const aAttr: term_attr_256_t);
begin
  term_writeln(_term, aData, aAttr);
end;

procedure term_writeln(aTerm: pterm_t; const aData: Variant; const aAttr: term_attr_24bit_t);
begin
  term_write(aTerm, aData, aAttr);
  term_writeln(aTerm);
end;

procedure term_writeln(const aData: Variant; const aAttr: term_attr_24bit_t);
begin
  term_writeln(_term, aData, aAttr);
end;

function term_event_key(const aKey: term_event_key_t): term_event_t;
begin
  Result.kind := tek_key;
  Result.key  := aKey;
end;

function term_event_key(aKey: term_key_t; aChar: term_char_t; aShift, aCtrl, aAlt: Boolean): term_event_t;
begin
  Result.kind      := tek_key;
  Result.key.key   := aKey;
  Result.key.char  := aChar;
  Result.key.shift := term_bit1_t(aShift);
  Result.key.ctrl  := term_bit1_t(aCtrl);
  Result.key.alt   := term_bit1_t(aAlt);
end;

function term_event_key(aKey: term_key_t; aChar: Char; aShift, aCtrl, aAlt: Boolean): term_event_t;
begin
  Result := term_event_key(aKey, term_char(aChar), aShift, aCtrl, aAlt);
end;

function term_event_key(aKey: term_key_t; aChar: WideChar; aShift, aCtrl, aAlt: Boolean): term_event_t;
begin
  Result := term_event_key(aKey, term_char(aChar), aShift, aCtrl, aAlt);
end;

function term_event_mouse(aMouse: term_event_mouse_t): term_event_t;
begin
  Result.kind  := tek_mouse;
  Result.mouse := aMouse;
end;

function term_event_mouse(aX, aY: term_size_t; aState: term_mouse_state_t; aButton: term_mouse_button_t; aShift, aCtrl, aAlt: Boolean): term_event_t;
begin
  Result.kind         := tek_mouse;
  Result.mouse.x      := aX;
  Result.mouse.y      := aY;
  Result.mouse.state  := term_bit2_t(aState);
  Result.mouse.button := term_bit4_t(aButton);
  Result.mouse.shift  := term_bit1_t(aShift);
  Result.mouse.ctrl   := term_bit1_t(aCtrl);
  Result.mouse.alt    := term_bit1_t(aAlt);
end;

function term_event_size_change(aWidth, aHeight: term_size_t): term_event_t;
begin
  Result.kind              := tek_sizeChange;
  Result.size.width  := aWidth;
  Result.size.height := aHeight;
end;

function term_event_focus(const aFocus: boolean): term_event_t;
begin
  Result.kind        := tek_focus;
  Result.focus.focus := aFocus;
end;

procedure term_event_push(aTerm: pterm_t; const aEvent: term_event_t);
begin
  term_check_nil(aTerm);
  term_event_queue_push(aTerm^.event_queue, aEvent);
end;

procedure term_evnet_push(const aEvent: term_event_t);
begin
  term_event_push(_term, aEvent);
end;

procedure term_event_push_key(const aTerm: pterm_t; const aKey: term_event_key_t);
begin
  term_event_push(aTerm, term_event_key(aKey));
end;

procedure term_event_push_key(const aKey: term_event_key_t);
begin
  term_event_push(_term, term_event_key(aKey));
end;

procedure term_event_push_mouse(const aTerm: pterm_t; const aMouse: term_event_mouse_t);
begin
  term_event_push(aTerm, term_event_mouse(aMouse));
end;

procedure term_event_push_mouse(const aMouse: term_event_mouse_t);
begin
  term_event_push(_term, term_event_mouse(aMouse));
end;





{ ===== Modern facade implementations (clean) ===== }

function MakeRGBColor(aR, aG, aB: Byte): TRGBColor;
begin
  Result.R := aR;
  Result.G := aG;
  Result.B := aB;
  Result.A := 255;
end;

function ColorToRGB(aColor: TTerminalColor): TRGBColor;
const
  BASE: array[0..15, 0..2] of Byte = (
    (0,0,0),       (128,0,0),   (0,128,0),   (128,128,0),
    (0,0,128),     (128,0,128), (0,128,128), (192,192,192),
    (128,128,128), (255,0,0),   (0,255,0),   (255,255,0),
    (0,0,255),     (255,0,255), (0,255,255), (255,255,255)
  );
var LIdx: Integer;
begin
  LIdx := Ord(aColor);
  if (LIdx < 0) or (LIdx > 15) then LIdx := 0;
  Result.R := BASE[LIdx,0];
  Result.G := BASE[LIdx,1];
  Result.B := BASE[LIdx,2];
  Result.A := 255;
end;

function MakeKeyEvent(aType: TKeyType; aKeyChar: Char; aModifiers: TKeyModifiers; const aUnicodeChar: string): TKeyEvent;
begin
  Result.KeyType := aType;
  Result.KeyChar := aKeyChar;
  Result.Modifiers := aModifiers;
  Result.UnicodeChar := aUnicodeChar;
end;

function KeyEventToString(const aEvent: TKeyEvent): string;
  function ModPrefix: string;
  begin
    Result := '';
    if kmCtrl in aEvent.Modifiers then Result := Result + 'Ctrl+';
    if kmShift in aEvent.Modifiers then Result := Result + 'Shift+';
    if kmAlt in aEvent.Modifiers then Result := Result + 'Alt+';
  end;
begin
  case aEvent.KeyType of
    ktChar:       Result := ModPrefix + aEvent.KeyChar;
    ktEnter:      Result := ModPrefix + 'Enter';
    ktBackspace:  Result := ModPrefix + 'Backspace';
    ktTab:        Result := ModPrefix + 'Tab';
    ktEscape:     Result := ModPrefix + 'Escape';
    // 导航
    ktArrowUp:    Result := ModPrefix + 'Up';
    ktArrowDown:  Result := ModPrefix + 'Down';
    ktArrowLeft:  Result := ModPrefix + 'Left';
    ktArrowRight: Result := ModPrefix + 'Right';
    ktHome:       Result := ModPrefix + 'Home';
    ktEnd:        Result := ModPrefix + 'End';
    ktPageUp:     Result := ModPrefix + 'PageUp';
    ktPageDown:   Result := ModPrefix + 'PageDown';
    ktInsert:     Result := ModPrefix + 'Insert';
    ktDelete:     Result := ModPrefix + 'Delete';
    // 功能键
    ktF1:  Result := ModPrefix + 'F1';
    ktF2:  Result := ModPrefix + 'F2';
    ktF3:  Result := ModPrefix + 'F3';
    ktF4:  Result := ModPrefix + 'F4';
    ktF5:  Result := ModPrefix + 'F5';
    ktF6:  Result := ModPrefix + 'F6';
    ktF7:  Result := ModPrefix + 'F7';
    ktF8:  Result := ModPrefix + 'F8';
    ktF9:  Result := ModPrefix + 'F9';
    ktF10: Result := ModPrefix + 'F10';
    ktF11: Result := ModPrefix + 'F11';
    ktF12: Result := ModPrefix + 'F12';
  else
    Result := ModPrefix + 'Unknown';
  end;
end;

class function TANSIGenerator.ColorToANSICode(aColor: TTerminalColor; aBackground: Boolean): Integer;
var idx: Integer;
begin
  idx := Ord(aColor);
  if not aBackground then
  begin
    if idx <= 7 then Result := 30 + idx else Result := 90 + (idx - 8);
  end
  else
  begin
    if idx <= 7 then Result := 40 + idx else Result := 100 + (idx - 8);
  end;
end;

class function TANSIGenerator.AttributeToANSICode(aAttr: TTerminalAttribute): Integer;
begin
  // Default to 0; overridden by specific attributes below.
  Result := 0;
  case aAttr of
    taBold:          Exit(1);
    taDim:           Exit(2);
    taItalic:        Exit(3);
    taUnderline:     Exit(4);
    taBlink:         Exit(5);
    taReverse:       Exit(7);
    taStrikethrough: Exit(9);
  end;
end;

class function TANSIGenerator.SetForegroundColor(aColor: TTerminalColor): string;
begin
  Result := CSI + IntToStr(ColorToANSICode(aColor, False)) + 'm';
end;

class function TANSIGenerator.SetBackgroundColor(aColor: TTerminalColor): string;
begin
  Result := CSI + IntToStr(ColorToANSICode(aColor, True)) + 'm';
end;

class function TANSIGenerator.SetForegroundColorRGB(const aColor: TRGBColor): string;
begin
  Result := CSI + '38;2;' + IntToStr(aColor.R) + ';' + IntToStr(aColor.G) + ';' + IntToStr(aColor.B) + 'm';
end;

class function TANSIGenerator.SetBackgroundColorRGB(const aColor: TRGBColor): string;
begin
  Result := CSI + '48;2;' + IntToStr(aColor.R) + ';' + IntToStr(aColor.G) + ';' + IntToStr(aColor.B) + 'm';
end;

class function TANSIGenerator.ResetColors: string;
begin
  Result := CSI + '39;49m';
end;

class function TANSIGenerator.SetAttribute(aAttr: TTerminalAttribute): string;
begin
  Result := CSI + IntToStr(AttributeToANSICode(aAttr)) + 'm';
end;

class function TANSIGenerator.ResetAttributes: string;
begin
  Result := ANSI_RESET;
end;

class function TANSIGenerator.MoveCursor(aX, aY: Integer): string;
begin
  Result := CSI + IntToStr(aY + 1) + ';' + IntToStr(aX + 1) + 'H';
end;

class function TANSIGenerator.MoveCursorUp(aCount: Integer): string;
begin
  if aCount <= 0 then Exit('');
  if aCount = 1 then Result := ANSI_CURSOR_UP else Result := CSI + IntToStr(aCount) + 'A';
end;

class function TANSIGenerator.MoveCursorDown(aCount: Integer): string;
begin
  if aCount <= 0 then Exit('');
  if aCount = 1 then Result := ANSI_CURSOR_DOWN else Result := CSI + IntToStr(aCount) + 'B';
end;

class function TANSIGenerator.MoveCursorLeft(aCount: Integer): string;
begin
  if aCount <= 0 then Exit('');
  if aCount = 1 then Result := ANSI_CURSOR_BACKWARD else Result := CSI + IntToStr(aCount) + 'D';
end;

class function TANSIGenerator.MoveCursorRight(aCount: Integer): string;
begin
  if aCount <= 0 then Exit('');
  if aCount = 1 then Result := ANSI_CURSOR_FORWARD else Result := CSI + IntToStr(aCount) + 'C';
end;

class function TANSIGenerator.SaveCursorPosition: string;
begin
  Result := ANSI_CURSOR_SAVE;
end;

class function TANSIGenerator.RestoreCursorPosition: string;
begin
  Result := ANSI_CURSOR_RESTORE;
end;

class function TANSIGenerator.ShowCursor: string;
begin
  Result := ANSI_CURSOR_SHOW;
end;

class function TANSIGenerator.HideCursor: string;
begin
  Result := ANSI_CURSOR_HIDE;
end;

class function TANSIGenerator.ClearScreen(aTarget: TClearTarget): string;
begin
  // Default empty response when target not recognized
  Result := '';
  case aTarget of
    tctAll:         Exit(ANSI_CLEAR_SCREEN);
    tctCurrentLine: Exit(ANSI_CLEAR_LINE);
  end;
end;

class function TANSIGenerator.ScrollUp(aLines: Integer): string;
begin
  Result := ansi_scroll_up(aLines);
end;

class function TANSIGenerator.ScrollDown(aLines: Integer): string;
begin
  Result := ansi_scroll_down(aLines);
end;

class function TANSIGenerator.SetScrollRegion(aTop, aBottom: Integer): string;
begin
  // map 0-based input to 1-based CSI: CSI t ; b r
  Result := CSI + IntToStr(aTop + 1) + ';' + IntToStr(aBottom + 1) + 'r';
end;

class function TANSIGenerator.SetCursorShape(aShape: term_cursor_shape_t): string;
var ps: Integer;
begin
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
  Result := CSI + IntToStr(ps) + ' q'; // note: space before q per spec "SP q"
end;

class function TANSIGenerator.EnterAlternateScreen: string;
begin
  Result := CSI + '?1049h';
end;

class function TANSIGenerator.LeaveAlternateScreen: string;
begin
  Result := CSI + '?1049l';
end;

class function TANSIGenerator.SetWindowTitle(const aTitle: string): string;
begin
  Result := OSC + '2;' + aTitle + BEL;
end;

class function TANSIGenerator.SetIconTitle(const aTitle: string): string;
begin
  Result := OSC + '1;' + aTitle + BEL;
end;


{ TTerminalOutput }
constructor TTerminalOutput.Create(AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  FStream := AStream;
  FOwnsStream := AOwnsStream;
  FBuffering := False;
  FBuffer := '';
  // 初始化状态机
  FColorStateValid := False;
  FLastAttrValid := False;
  FCursorVisibleKnown := False;
  FCursorVisible := True; // 绝大多数终端默认显示光标
  FScrollRegionSet := False;
  FScrollRegionTop := 0;
  FScrollRegionBottom := 0;
  FCursorSaved := False;
end;

destructor TTerminalOutput.Destroy;
begin
  if FOwnsStream and (FStream <> nil) then FStream.Free;
  inherited Destroy;
end;

procedure TTerminalOutput.InternalWrite(const S: string);
var bytes: RawByteString;
begin
  if S = '' then Exit;
  if FStream = nil then Exit;
  if FBuffering then
  begin
    FBuffer := FBuffer + S;
    // 阈值触发分块 flush，减少巨大帧内缓冲的峰值
    if Length(FBuffer) >= (64*1024) then
    begin
      bytes := UTF8Encode(FBuffer);
      if Length(bytes) > 0 then
        FStream.WriteBuffer(bytes[1], Length(bytes));
      FBuffer := '';
  // 可选写入合并阈值（behind-a-flag）：FAFAFA_TERM_WRITE_COALESCE_BYTES
  // 默认关闭（0 或未设置），设置为 >0 时在非缓冲模式下聚合到阈值再写
  var __coalesce_bytes_s: string; var __coalesce_bytes: Integer;
  __coalesce_bytes_s := env_get('FAFAFA_TERM_WRITE_COALESCE_BYTES');
  if (__coalesce_bytes_s <> '') and TryStrToInt(__coalesce_bytes_s, __coalesce_bytes) and (__coalesce_bytes > 0) then
  begin
    FBuffer := FBuffer + S;
    if (Length(FBuffer) >= __coalesce_bytes) then
    begin
      bytes := UTF8Encode(FBuffer);
      if Length(bytes) > 0 then FStream.WriteBuffer(bytes[1], Length(bytes));
      FBuffer := '';
    end;
    Exit;
  end;

    end;
    Exit;
  end;
  // write as UTF-8
  bytes := UTF8Encode(S);
  if Length(bytes) > 0 then
    FStream.WriteBuffer(bytes[1], Length(bytes));
end;

procedure TTerminalOutput.Write(const aText: string);
begin
  InternalWrite(aText);
end;

procedure TTerminalOutput.WriteLn(const aText: string);
begin
  InternalWrite(aText + LineEnding);
end;

procedure TTerminalOutput.Flush;
var bytes: RawByteString;
begin
  if not FBuffering then Exit;
  if Length(FBuffer) = 0 then Exit;
  bytes := UTF8Encode(FBuffer);
  if (FStream <> nil) and (Length(bytes) > 0) then
    FStream.WriteBuffer(bytes[1], Length(bytes));
  FBuffer := '';
end;

procedure TTerminalOutput.SetForegroundColor(aColor: TTerminalColor);
begin
  // 避免重复设置相同颜色
  if FColorStateValid and (FFGColor = aColor) then Exit;
  InternalWrite(TANSIGenerator.SetForegroundColor(aColor));
  FFGColor := aColor;
  FColorStateValid := True;
end;

procedure TTerminalOutput.SetBackgroundColor(aColor: TTerminalColor);
begin
  // 避免重复设置相同颜色
  if FColorStateValid and (FBGColor = aColor) then Exit;
  InternalWrite(TANSIGenerator.SetBackgroundColor(aColor));
  FBGColor := aColor;
  FColorStateValid := True;
end;

procedure TTerminalOutput.SetForegroundColorRGB(const aColor: TRGBColor);
begin
  InternalWrite(TANSIGenerator.SetForegroundColorRGB(aColor));
end;

procedure TTerminalOutput.SetBackgroundColorRGB(const aColor: TRGBColor);
begin
  InternalWrite(TANSIGenerator.SetBackgroundColorRGB(aColor));
end;

procedure TTerminalOutput.ResetColors;
begin
  // 始终输出重置序列，符合测试与直觉期望
  InternalWrite(TANSIGenerator.ResetColors);
  FColorStateValid := False;
end;

procedure TTerminalOutput.SetAttribute(aAttr: TTerminalAttribute);
begin
  // 避免重复设置同一属性
  if FLastAttrValid and (FLastAttr = aAttr) then Exit;
  InternalWrite(TANSIGenerator.SetAttribute(aAttr));
  FLastAttr := aAttr;
  FLastAttrValid := True;
end;

procedure TTerminalOutput.ResetAttributes;
begin
  // 始终输出重置序列，符合测试与直觉期望
  InternalWrite(TANSIGenerator.ResetAttributes);
  FLastAttrValid := False;
end;

procedure TTerminalOutput.MoveCursor(aX, aY: Integer);
begin
  InternalWrite(TANSIGenerator.MoveCursor(aX, aY));
end;

procedure TTerminalOutput.MoveCursorUp(aCount: Integer);
begin
  InternalWrite(TANSIGenerator.MoveCursorUp(aCount));
end;

procedure TTerminalOutput.MoveCursorDown(aCount: Integer);
begin
  InternalWrite(TANSIGenerator.MoveCursorDown(aCount));
end;

procedure TTerminalOutput.MoveCursorLeft(aCount: Integer);
begin
  InternalWrite(TANSIGenerator.MoveCursorLeft(aCount));
end;

procedure TTerminalOutput.MoveCursorRight(aCount: Integer);
begin
  InternalWrite(TANSIGenerator.MoveCursorRight(aCount));
end;

procedure TTerminalOutput.SaveCursorPosition;
begin
  if FCursorSaved then Exit;
  InternalWrite(TANSIGenerator.SaveCursorPosition);
  FCursorSaved := True;
end;

procedure TTerminalOutput.RestoreCursorPosition;
begin
  if not FCursorSaved then Exit;
  InternalWrite(TANSIGenerator.RestoreCursorPosition);
  FCursorSaved := False;
end;

procedure TTerminalOutput.ShowCursor;
begin
  // 避免重复发出相同的显示光标序列
  if FCursorVisibleKnown and FCursorVisible then Exit;
  InternalWrite(TANSIGenerator.ShowCursor);
  FCursorVisibleKnown := True;
  FCursorVisible := True;
end;

procedure TTerminalOutput.HideCursor;
begin
  // 避免重复发出相同的隐藏光标序列
  if FCursorVisibleKnown and (not FCursorVisible) then Exit;
  InternalWrite(TANSIGenerator.HideCursor);
  FCursorVisibleKnown := True;
  FCursorVisible := False;
end;

procedure TTerminalOutput.ClearScreen(aTarget: TClearTarget);
begin
  InternalWrite(TANSIGenerator.ClearScreen(aTarget));
end;

procedure TTerminalOutput.ScrollUp(aLines: Integer);
begin
  InternalWrite(TANSIGenerator.ScrollUp(aLines));
end;

procedure TTerminalOutput.ScrollDown(aLines: Integer);
begin
  InternalWrite(TANSIGenerator.ScrollDown(aLines));
end;

procedure TTerminalOutput.EnterAlternateScreen;
begin
  InternalWrite(TANSIGenerator.EnterAlternateScreen);
end;

procedure TTerminalOutput.LeaveAlternateScreen;
begin
  InternalWrite(TANSIGenerator.LeaveAlternateScreen);
end;



procedure TTerminalOutput.SetScrollRegion(aTop, aBottom: Integer);
begin
  // 0-based 输入，内部生成器已转换为 1-based DECSTBM
  if FScrollRegionSet and (FScrollRegionTop = aTop) and (FScrollRegionBottom = aBottom) then Exit;
  InternalWrite(TANSIGenerator.SetScrollRegion(aTop, aBottom));
  FScrollRegionSet := True;
  FScrollRegionTop := aTop;
  FScrollRegionBottom := aBottom;
end;

procedure TTerminalOutput.ResetScrollRegion;
begin
  if not FScrollRegionSet then Exit;
  // CSI r 恢复整屏为滚动区域
  InternalWrite(#27'[r');
  FScrollRegionSet := False;
end;

procedure TTerminalOutput.EnableBuffering;
begin
  FBuffering := True;
end;

procedure TTerminalOutput.DisableBuffering;
begin
  Flush;
  FBuffering := False;
end;

function TTerminalOutput.IsBufferingEnabled: Boolean;
begin
  Result := FBuffering;
end;

procedure TTerminalOutput.ExecuteCommand(const aCommand: IInterface);
var C: ITerminalCommand;
begin
  if (aCommand <> nil) and Supports(aCommand, ITerminalCommand, C) then
    C.Execute(Self);
end;

procedure TTerminalOutput.ExecuteCommands(const aCommands: array of IInterface);
var
  LIndex: Integer;
  prevBuffered: Boolean;
begin
  // 将命令批处理在一次缓冲中，减少多次 Write 带来的分段写
  prevBuffered := IsBufferingEnabled;
  if not prevBuffered then EnableBuffering;
  try
    for LIndex := Low(aCommands) to High(aCommands) do
      ExecuteCommand(aCommands[LIndex]);
  finally
    Flush;
    if not prevBuffered then DisableBuffering; // 恢复调用前状态
  end;
end;

procedure TTerminalOutput.ExecuteCommands(const aCommands: array of ITerminalCommand);
var
  LIndex: Integer;
  prevBuffered: Boolean;
begin
  // 将命令批处理在一次缓冲中，减少多次 Write 带来的分段写
  prevBuffered := IsBufferingEnabled;
  if not prevBuffered then EnableBuffering;
  try
    for LIndex := Low(aCommands) to High(aCommands) do
      ExecuteCommand(aCommands[LIndex]);
  finally
    Flush;
    if not prevBuffered then DisableBuffering; // 恢复调用前状态
  end;
end;

{ TTerminalCommand }
constructor TTerminalCommand.Create(const aCommandString: string; const aDescription: string);
begin
  inherited Create;
  FCmd := aCommandString;
  FDesc := aDescription;
end;

function TTerminalCommand.GetCommandString: string;
begin
  Result := FCmd;
end;

function TTerminalCommand.GetDescription: string;
begin
  Result := FDesc;
end;

procedure TTerminalCommand.Execute(const aOutput: ITerminalOutput);
begin
  if aOutput <> nil then aOutput.Write(FCmd);
end;

function TTerminalCommand.IsValid: Boolean;
begin
  Result := FCmd <> '';
end;

function TTerminalCommand.Clone: ITerminalCommand;
begin
  Result := TTerminalCommand.Create(FCmd, FDesc);
end;

{ TTerminal }
constructor TTerminal.Create;
begin
  inherited Create;
  FInfo := TTerminalInfo.Create;
  // 默认输出绑定至标准输出（可通过自定义流重载/工厂替换）；
  // 兼容测试：测试用例直接构造 TTerminalOutput(FMemoryStream) 不受影响
  try
    {$ifdef FPC}
    FOutput := TTerminalOutput.Create(THandleStream.Create(TTextRec(Output).Handle), True);
    {$else}
    FOutput := TTerminalOutput.Create(TMemoryStream.Create, True);
    {$endif}
  except
    // 回退：极端情况下仍回退到内存流，避免构造失败影响使用
    FOutput := TTerminalOutput.Create(TMemoryStream.Create, True);
  end;
  FInput := TTerminalInput.Create;
end;

destructor TTerminal.Destroy;
begin
  FInfo := nil;
  FOutput := nil;
  FInput := nil;
  inherited Destroy;
end;

function TTerminal.GetInfo: ITerminalInfo;
begin
  Result := FInfo;
end;

function TTerminal.GetOutput: ITerminalOutput;
begin
  Result := FOutput;
end;

function TTerminal.GetInput: ITerminalInput;
begin
  Result := FInput;
end;

procedure TTerminal.Initialize;
begin
  term_init;
end;

procedure TTerminal.Finalize;
begin
  term_done;
end;

{ TTerminalInput }

function TTerminalInput.MapEventToKeyEvent(const E: term_event_t; out K: TKeyEvent): Boolean;
begin
  Result := False;
  if E.kind <> tek_key then Exit;
  // 基于 KEY_* 常量粗略映射到简化 TKeyType
  K.Modifiers := [];
  if E.key.shift <> 0 then Include(K.Modifiers, kmShift);
  if E.key.ctrl  <> 0 then Include(K.Modifiers, kmCtrl);
  if E.key.alt   <> 0 then Include(K.Modifiers, kmAlt);

  case E.key.key of
    KEY_ESC:       begin K.KeyType := ktEscape; Result := True; end;
    KEY_ENTER:     begin K.KeyType := ktEnter;  Result := True; end;
    KEY_BACKSPACE: begin K.KeyType := ktBackspace; Result := True; end;
    KEY_TAB:       begin K.KeyType := ktTab; Result := True; end;

    KEY_UP:        begin K.KeyType := ktArrowUp; Result := True; end;
    KEY_DOWN:      begin K.KeyType := ktArrowDown; Result := True; end;
    KEY_LEFT:      begin K.KeyType := ktArrowLeft; Result := True; end;
    KEY_RIGHT:     begin K.KeyType := ktArrowRight; Result := True; end;

    KEY_HOME:      begin K.KeyType := ktHome; Result := True; end;
    KEY_END:       begin K.KeyType := ktEnd; Result := True; end;
    KEY_PAGE_UP:   begin K.KeyType := ktPageUp; Result := True; end;
    KEY_PAGE_DOWN: begin K.KeyType := ktPageDown; Result := True; end;
    KEY_INSERT:    begin K.KeyType := ktInsert; Result := True; end;
    KEY_DELETE:    begin K.KeyType := ktDelete; Result := True; end;

    KEY_F1..KEY_F12:
      begin
        case E.key.key of
          KEY_F1:  K.KeyType := ktF1;
          KEY_F2:  K.KeyType := ktF2;
          KEY_F3:  K.KeyType := ktF3;
          KEY_F4:  K.KeyType := ktF4;
          KEY_F5:  K.KeyType := ktF5;
          KEY_F6:  K.KeyType := ktF6;
          KEY_F7:  K.KeyType := ktF7;
          KEY_F8:  K.KeyType := ktF8;
          KEY_F9:  K.KeyType := ktF9;
          KEY_F10: K.KeyType := ktF10;
          KEY_F11: K.KeyType := ktF11;
          KEY_F12: K.KeyType := ktF12;
        end;
        Result := True;
      end;
  else
    // 退化为字符键（若有 Unicode 字符）
    if E.key.char.wchar <> #0 then
    begin
      K.KeyType := ktChar;
      K.KeyChar := AnsiChar(E.key.char.wchar);
      Result := True;
    end
    else if E.key.char.char <> #0 then
    begin
      K.KeyType := ktChar;
      K.KeyChar := E.key.char.char;
      Result := True;
    end
    else
    begin
      K.KeyType := ktUnknown;
      Result := True;
    end;
  end;
end;

function TTerminalInput.FetchNextKey(aTimeout: UInt64; out K: TKeyEvent): Boolean;
var E: term_event_t;
begin
  // 先用 pending 缓存，避免多次 poll
  if FPending then
  begin
    K := FPendingKey;
    FPending := False;
    Exit(True);
  end;

  FillByte(E, SizeOf(E), 0);
  Result := term_event_poll(E, aTimeout);
  if Result then
    Result := MapEventToKeyEvent(E, K);
end;

function TTerminalInput.ReadKey: TKeyEvent;
begin
  if not TryReadKey(Result) then
  begin
    // 阻塞直到有键
    while not TryReadKey(Result) do ;
  end;
end;

function TTerminalInput.TryReadKey(out aKeyEvent: TKeyEvent): Boolean;
begin
  Result := FetchNextKey(INFINITE, aKeyEvent);
end;

function TTerminalInput.ReadLine: string;
var K: TKeyEvent;
begin
  Result := '';
  while True do
  begin
    K := ReadKey;
    case K.KeyType of
      ktEnter: Break;
      ktBackspace: if Result <> '' then Delete(Result, Length(Result), 1);
      ktChar: Result := Result + K.KeyChar;
    else
      // 其他键型：忽略（方向键/F1-F12/Escape/Tab等不改变行缓冲）
    end;
  end;
end;

function TTerminalInput.HasInput: Boolean;
var E: term_event_t;
begin
  // 非阻塞探测：零超时 poll
  if FPending then Exit(True);
  FillByte(E, SizeOf(E), 0);
  Result := term_event_poll(E, 0);
  if Result then
  begin
    Result := MapEventToKeyEvent(E, FPendingKey);
    FPending := Result;
  end;
end;

function TTerminalInput.PeekKey(out aKeyEvent: TKeyEvent): Boolean;
var E: term_event_t;
begin
  if FPending then
  begin
    aKeyEvent := FPendingKey;
    Exit(True);
  end;
  FillByte(E, SizeOf(E), 0);
  Result := term_event_poll(E, 0);
  if Result then
  begin
    Result := MapEventToKeyEvent(E, FPendingKey);
    FPending := Result;
    if Result then aKeyEvent := FPendingKey;
  end;
end;

procedure TTerminalInput.FlushInput;
var E: term_event_t;
begin
  FPending := False;
  while term_event_poll(E, 0) do ;
end;


procedure TTerminal.EnterRawMode;
begin
  term_raw_mode_enable(True);
end;

procedure TTerminal.LeaveRawMode;
begin
  term_raw_mode_disable;
end;

procedure TTerminal.Reset;
begin
  term_reset;
end;

{ 工厂与便捷函数 }
function CreateTerminal: ITerminal;
begin
  Result := TTerminal.Create;
end;

function CreateTerminalCommand(const aCommandString: string; const aDescription: string): ITerminalCommand;
begin
  Result := TTerminalCommand.Create(aCommandString, aDescription);
end;

function GetTerminalSize: TTerminalSize;
var W,H: term_size_t;
begin
  W := 0; H := 0; // avoid uninitialized hints
  Result.Width := 0; Result.Height := 0;
  if not _term_initialized then term_init;
  if term_size(W, H) then
  begin
    Result.Width := W;
    Result.Height := H;
  end;
end;

function SupportsColor: Boolean;
begin
  if not _term_initialized then term_init;
  Result := term_support_ansi;
end;

function TTerminalInfo.GetSize: TTerminalSize;
begin
  Result := GetTerminalSize;
end;

function TTerminalInfo.GetColorDepth: Integer;
var
  t, ct: string;
begin
  // 环境优先：尊重 NO_COLOR/COLORTERM/TERM/CLICOLOR 的约定；否则回退到能力探测
  if env_get('NO_COLOR') <> '' then Exit(0);
  if env_get('CLICOLOR') = '0' then Exit(0);
  if env_get('CLICOLOR_FORCE') = '1' then
  begin
    // 强制彩色但不强制位深，仍让 COLORTERM/TERM 决定位深
  end;
  ct := LowerCase(env_get('COLORTERM'));
  if (Pos('truecolor', ct) > 0) or (Pos('24bit', ct) > 0) then Exit(24);
  t := LowerCase(env_get('TERM'));
  if Pos('256color', t) > 0 then Exit(8);
  // 能力探测（保持惰性策略）
  if not _term_initialized then term_init;
  if term_support_color_24bit then Exit(24);
  if term_support_color_256 then Exit(8);
  if term_support_color_16 then Exit(4);
  Result := 0;
end;

function TTerminalInfo.SupportsColor: Boolean;
var
  t: string;
begin
  // NO_COLOR 或 dumb 终端：关闭彩色
  if env_get('NO_COLOR') <> '' then Exit(False);
  t := LowerCase(env_get('TERM'));
  if (t = 'dumb') then Exit(False);
  // CLICOLOR/CLICOLOR_FORCE
  if env_get('CLICOLOR_FORCE') = '1' then Exit(True);
  if env_get('CLICOLOR') = '0' then Exit(False);
  // 其余遵循能力探测
  Result := term_support_ansi;
end;

function TTerminalInfo.SupportsTrueColor: Boolean;
begin
  if env_get('NO_COLOR') <> '' then Exit(False);
  if (Pos('truecolor', LowerCase(env_get('COLORTERM'))) > 0) or
     (Pos('24bit', LowerCase(env_get('COLORTERM'))) > 0) then
    Exit(True);
  Result := term_support_color_24bit;
end;

function IsTerminal: Boolean;
begin
  Result := term_init;
  if Result then term_done;
end;

// Removed duplicate legacy implementations (consolidated above)
function TTerminalInfo.GetCapabilities: TTerminalCapabilities;
begin
  Result := [];
  if term_support_ansi then Include(Result, tcapANSI);
  if term_support_color_16 then Include(Result, tcapColor16);
  if term_support_color_256 then Include(Result, tcapColor256);
  if term_support_color_24bit then Include(Result, tcapTrueColor);
  if term_support_mouse then
  begin
    Include(Result, tcapMouse);
    // 细粒度鼠标协议能力（依据平台/探测/环境，按保守方式纳入）
    if term_support_compatible(_term, tc_mouse_basic_1000) then Include(Result, tcapMouseBasic);
    if term_support_compatible(_term, tc_mouse_drag_1002) then Include(Result, tcapMouseDrag);
    if term_support_compatible(_term, tc_mouse_sgr_1006) then Include(Result, tcapMouseSGR);
    if term_support_compatible(_term, tc_mouse_urxvt_1015) then Include(Result, tcapMouseUrxvt);
  end;
  // 扩展能力：焦点/括号粘贴（如不支持将自然缺席）
  if term_support_compatible(_term, tc_focus_1004) then Include(Result, tcapFocus);
  if term_support_compatible(_term, tc_paste_2004) then Include(Result, tcapBracketedPaste);
end;

function TTerminalInfo.GetTerminalType: string;
var
  termVar, prog, vte, kz, wz, alacritty: string;
begin
  {$IFDEF MSWINDOWS}
  // Windows 终端识别（启发式）：
  if env_get('WT_SESSION') <> '' then Exit('Windows Terminal');
  if env_get('ConEmuPID') <> '' then Exit('ConEmu');
  if env_get('ANSICON') <> '' then Exit('ANSICON');
  if env_get('KOMOREBI') <> '' then Exit('Komorebi');
  // MSYS/MinTTY
  if env_get('MSYSTEM') <> '' then
  begin
    termVar := LowerCase(env_get('TERM'));
    if (Pos('mintty', termVar) > 0) or (Pos('xterm', termVar) > 0) then
      Exit('MSYS MinTTY');
  end;
  // 回退：传统控制台
  Result := 'Windows Console';
  {$ELSE}
  // Unix 终端识别（启发式）：
  termVar := LowerCase(env_get('TERM'));
  prog := LowerCase(env_get('TERM_PROGRAM'));
  vte := env_get('VTE_VERSION');
  kz := env_get('KONSOLE_VERSION');
  wz := env_get('WEZTERM_EXECUTABLE');
  alacritty := env_get('ALACRITTY_LOG');

  if prog <> '' then
  begin
    if Pos('wezterm', prog) > 0 then Exit('WezTerm');
    if Pos('apple_terminal', prog) > 0 then Exit('Apple Terminal');
    if Pos('iTerm', env_get('TERM_PROGRAM')) > 0 then Exit('iTerm2');
  end;
  if wz <> '' then Exit('WezTerm');
  if (alacritty <> '') or (Pos('alacritty', termVar) > 0) then Exit('Alacritty');
  if (kz <> '') then Exit('Konsole');
  if (vte <> '') then Exit('VTE-based');
  if Pos('xterm-kitty', termVar) > 0 then Exit('kitty');
  if Pos('xterm', termVar) > 0 then Exit('xterm');
  if termVar <> '' then Exit(termVar);
  Result := 'unknown';
  {$ENDIF}
end;

function TTerminalInfo.IsATTY: Boolean;
var
  t: string;
begin
  {$IFDEF MSWINDOWS}
  // 常见终端标识：若存在则近似认为是 TTY 环境
  if (env_get('WT_SESSION') <> '') or (env_get('ConEmuPID') <> '') or (env_get('ANSICON') <> '') then
    Exit(True);
  {$ENDIF}
  // Unix/通用：TERM 存在且非 dumb 近似视为交互终端
  t := LowerCase(env_get('TERM'));
  if (t = '') or (t = 'dumb') then Exit(False);
  // 避免在这里调用 term_init 产生副作用；如需更强保证，可显式调用 IsTerminal
  Result := True;
end;


procedure term_event_push_size_change(const aTerm: pterm_t; aWidth, aHeight: term_size_t);
begin
  term_event_push(aTerm, term_event_size_change(aWidth, aHeight));
end;

procedure term_event_push_size_change(aWidth, aHeight: term_size_t);
begin
  term_event_push(_term, term_event_size_change(aWidth, aHeight));
end;

procedure term_event_push_focus(const aTerm: pterm_t; const aFocus: boolean);
begin
  term_event_push(aTerm, term_event_focus(aFocus));
end;

procedure term_event_push_focus(const aFocus: boolean);
begin
  term_event_push(_term, term_event_focus(aFocus));
end;

function TTerminalInfo.GetEnvironmentVariable(const aName: string): string;
begin
  // 读取环境变量（跨平台：Windows/Unix）
  Result := env_get(aName);
end;

function TTerminalInfo.IsInsideTerminalMultiplexer: Boolean;
var LTermProg: string;
begin
  // 常见多路复用器：tmux/screen
  LTermProg := env_get('TERM_PROGRAM');
  if LTermProg = '' then
    LTermProg := env_get('TMUX');
  Result := (LTermProg <> '') or
            (Pos('tmux', LowerCase(env_get('TERM'))) > 0) or
            (Pos('screen', LowerCase(env_get('TERM'))) > 0);
end;

function term_event_pop(aTerm: pterm_t; var aEvent: term_event_t): Boolean; {$IFDEF FAFAFA_TERM_INLINE}inline;{$ENDIF}
begin
  term_check_nil(aTerm);
  Result := term_event_queue_pop(aTerm^.event_queue, aEvent);
end;

function term_event_poll(aTerm: pterm_t; var aEvent: term_event_t; aTimeout: UInt64): Boolean;
var
  idleStart: QWord;
  slept: Boolean;
begin
  try
    if term_event_pop(aTerm, aEvent) then
      Exit(True);

    Result := (aTerm^.event_pull <> nil) and aTerm^.event_pull(aTerm, aTimeout) and term_event_pop(aTerm, aEvent);

    // 空转轻睡/退避（默认关闭；仅在未取到事件且超时为 0 或很小且启用了轻睡时）
    if (not Result) and (G_TERM_IDLE_SLEEP_MS > 0) and (aTimeout = 0) then
    begin
      slept := False;
      // 若启用退避，可在后续回合指数增加睡眠时间（此处最小落点，保守仅 sleep 固定时长）
      Sleep(G_TERM_IDLE_SLEEP_MS);
      slept := True;
      // 不改变返回语义；轻睡仅作为 CPU 友好优化
    end;
  except
    // 防御性：任何异常视为无事件，避免进程崩溃
    Result := False;
  end;
end;

function term_events_collect(aTerm: pterm_t; var aEvents: array of term_event_t;
                             aMaxN: SizeUInt; aBudgetMs: UInt32): SizeUInt;
var
  startTick: QWord;
  ev: term_event_t;
  n, cap: SizeUInt;
  lastResizeIdx: Integer;
  resizeRunLen: Integer;
  prevWasResize: Boolean;
  hasMove: Boolean;
  lastMoveIdx: Integer;
  // 滚轮合并（同向压缩为最后一条）
  hasWheelRun: Boolean;
  lastWheelIdx: Integer;
  lastWheelButton: term_mouse_button_t;
begin
  Result := 0;
  if aTerm = nil then Exit(0);
  if aMaxN = 0 then Exit(0);
  cap := SizeUInt(High(aEvents) - Low(aEvents) + 1);
  if aMaxN > cap then aMaxN := cap;

  {**
   * term_events_collect 语义说明（就近注释）：
   * - 预算 aBudgetMs = 0：不进行 pull，仅消费事件队列（pop），即刻返回已消费结果；
   * - 分段合并：
   *   - 尺寸变化（tek_sizeChange）：仅对“连续 resize”进行去抖，保留该段的最后一条；
   *     一旦遇到非 resize 事件，则终止当前 resize 段，后续新出现的 resize 重新起段；
   *   - 鼠标移动（tek_mouse/tms_moved）：仅对“连续移动”进行合并，保留该段最后一条；
   *     一旦遇到非移动事件（包括其他鼠标事件、键盘、粘贴等），终止当前 move 段；
   * - 以上策略仅影响本次 collect 调用中的合并行为，不改变队列内部顺序。
   *}


  // 初始化本地变量，避免 Hint，且不改变逻辑
  FillByte(ev, SizeOf(ev), 0);

  startTick := GetTickCount64;
  lastResizeIdx := -1;
  resizeRunLen := 0;
  prevWasResize := False;
  hasMove := False;
  lastMoveIdx := -1;
  hasWheelRun := False;
  lastWheelIdx := -1;
  lastWheelButton := tmb_none;

  // 先尽可能消费已有事件（可配置去抖/合并）
  while (Result < aMaxN) and term_event_pop(aTerm, ev) do
  begin
    // 合并策略
    if ev.kind = tek_mouse then
    begin
      // 滚轮同向合并：保留最后一条
      if G_TERM_COALESCE_WHEEL and ((ev.mouse.button = Ord(tmb_wheel_up)) or (ev.mouse.button = Ord(tmb_wheel_down)) or
         (ev.mouse.button = Ord(tmb_wheel_left)) or (ev.mouse.button = Ord(tmb_wheel_right))) then
      begin
        if hasWheelRun and (lastWheelIdx >= 0) and (Ord(lastWheelButton) = ev.mouse.button) then
        begin
          aEvents[lastWheelIdx] := ev;
          Continue;
        end
        else
        begin
          hasWheelRun := True;
          lastWheelIdx := Result;
          lastWheelButton := term_mouse_button_t(ev.mouse.button);
        end;
      end
      // 鼠标移动合并：保留最后一条
      else if G_TERM_COALESCE_MOVE and (ev.mouse.state = Ord(tms_moved)) then
      begin
        if hasMove and (lastMoveIdx >= 0) then
        begin
          aEvents[lastMoveIdx] := ev;
          Continue;
        end
        else
        begin
          hasMove := True;
          lastMoveIdx := Result;
        end;
      end;
    end
    else if ev.kind = tek_sizeChange then
    begin
      // 去抖：连续 resize 仅保留最后一条；遇到非 resize 则开启新段（可关闭）
      if G_TERM_DEBOUNCE_RESIZE and (prevWasResize) and (lastResizeIdx >= 0) then
      begin
        aEvents[lastResizeIdx] := ev;
        Inc(resizeRunLen);
        Continue;
      end
      else
      begin
        lastResizeIdx := Result;
        resizeRunLen := 1;
        prevWasResize := True;
      end;
    end
    else
    begin
      // 非 resize：终止当前 resize 段
      prevWasResize := False;
      resizeRunLen := 0;
      lastResizeIdx := -1;
    end;


    // 分段策略：遇到非尺寸变化事件（包括鼠标非移动/键盘/粘贴等），终止 resize 段（可关闭）
    if (ev.kind <> tek_sizeChange) or (not G_TERM_DEBOUNCE_RESIZE) then
    begin
      prevWasResize := False;
      resizeRunLen := 0;
      lastResizeIdx := -1;
    end;

    // 分段策略：任何“非移动事件”都会终止 move 段
    if not ((ev.kind = tek_mouse) and (ev.mouse.state = Ord(tms_moved))) then
    begin
      hasMove := False;
      lastMoveIdx := -1;
    end;

    // 分段策略：任何“非滚轮事件”或“不同方向滚轮”都会终止当前滚轮段
    if not ((ev.kind = tek_mouse) and ((ev.mouse.button = Ord(tmb_wheel_up)) or (ev.mouse.button = Ord(tmb_wheel_down)) or (ev.mouse.button = Ord(tmb_wheel_left)) or (ev.mouse.button = Ord(tmb_wheel_right)))) or (not G_TERM_COALESCE_WHEEL) then
    begin
      hasWheelRun := False;
      lastWheelIdx := -1;
      lastWheelButton := tmb_none;
    end;

    aEvents[Result] := ev;
    Inc(Result);
  end;

  // 若预算为 0：不进行任何拉取，仅消费现有队列
  if aBudgetMs = 0 then Exit(Result);

  // 预算时间内，从后端拉取新事件
  while (Result < aMaxN) do
  begin
    // 超预算则停止
    if (aBudgetMs > 0) and (GetTickCount64 - startTick >= aBudgetMs) then Break;

    if not ((aTerm^.event_pull <> nil) and aTerm^.event_pull(aTerm, 0)) then Break;

    // 拉取后再消费一次
    while (Result < aMaxN) and term_event_pop(aTerm, ev) do
    begin
      if ev.kind = tek_mouse then
      begin
        // 滚轮同向合并：保留最后一条
        if G_TERM_COALESCE_WHEEL and ((ev.mouse.button = Ord(tmb_wheel_up)) or (ev.mouse.button = Ord(tmb_wheel_down)) or
           (ev.mouse.button = Ord(tmb_wheel_left)) or (ev.mouse.button = Ord(tmb_wheel_right))) then
        begin
          if hasWheelRun and (lastWheelIdx >= 0) and (Ord(lastWheelButton) = ev.mouse.button) then
          begin
            aEvents[lastWheelIdx] := ev;
            Continue;
          end
          else
          begin
            hasWheelRun := True;
            lastWheelIdx := Result;
            lastWheelButton := term_mouse_button_t(ev.mouse.button);
          end;
        end
        // 鼠标移动合并：保留最后一条
        else if G_TERM_COALESCE_MOVE and (ev.mouse.state = Ord(tms_moved)) then
        begin
          if hasMove and (lastMoveIdx >= 0) then
          begin
            aEvents[lastMoveIdx] := ev;
            Continue;
          end
          else
          begin
            hasMove := True;
            lastMoveIdx := Result;
          end;
        end;
      end
      else if ev.kind = tek_sizeChange then
      begin
        if (prevWasResize) and (lastResizeIdx >= 0) then
        begin
          aEvents[lastResizeIdx] := ev;
          Inc(resizeRunLen);
          Continue;
        end
        else
        begin
          lastResizeIdx := Result;
          resizeRunLen := 1;
          prevWasResize := True;
        end;
      end
      else
      begin
        // 非 resize：终止当前 resize 段
        prevWasResize := False;
        resizeRunLen := 0;
        lastResizeIdx := -1;
      end;


      // 分段策略：遇到非尺寸变化事件，终止 resize 段（可关闭）
      if (ev.kind <> tek_sizeChange) or (not G_TERM_DEBOUNCE_RESIZE) then
      begin
        prevWasResize := False;
        resizeRunLen := 0;
        lastResizeIdx := -1;
      end;

      // 分段策略：遇到非移动事件，终止 move 段
      if not ((ev.kind = tek_mouse) and (ev.mouse.state = Ord(tms_moved))) then
      begin
        hasMove := False;
        lastMoveIdx := -1;
      end;

      // 分段策略：任何“非滚轮事件”或“不同方向滚轮”都会终止当前滚轮段
      if not ((ev.kind = tek_mouse) and ((ev.mouse.button = Ord(tmb_wheel_up)) or (ev.mouse.button = Ord(tmb_wheel_down)) or (ev.mouse.button = Ord(tmb_wheel_left)) or (ev.mouse.button = Ord(tmb_wheel_right)))) or (not G_TERM_COALESCE_WHEEL) then
      begin
        hasWheelRun := False;
        lastWheelIdx := -1;
        lastWheelButton := tmb_none;
      end;




      aEvents[Result] := ev;
      Inc(Result);
    end;
  end;
end;

function term_events_collect(var aEvents: array of term_event_t;
                             aMaxN: SizeUInt; aBudgetMs: UInt32): SizeUInt;
begin
  Result := term_events_collect(_term, aEvents, aMaxN, aBudgetMs);
end;


function term_event_poll(var aEvent: term_event_t; aTimeout: UInt64): Boolean;
begin
  Result := term_event_poll(_term, aEvent, aTimeout);
end;

procedure term_event_read(aTerm: pterm_t; var aEvent: term_event_t);
begin
  if (not term_event_poll(aTerm, aEvent, INFINITE) ) then
    raise Exception.Create('term_event_read: event poll failed');
end;

procedure term_event_read(var aEvent: term_event_t);
begin
  term_event_read(_term, aEvent);
end;

function term_readchar(aTerm: pterm_t): term_char_t;
begin



  // working...
  term_check_nil(aTerm);

  // 暂时返回空字符，等待完整实现
  Result := term_char(#0);

// if aTerm^.readchar <> nil then
//Result := aTerm^.readchar(aTerm);
end;

function term_readchar: term_char_t;
begin
  Result := term_readchar(_term);
end;

procedure term_readln(aTerm: pterm_t; var aBuffer: string);
begin
  // 暂时返回空字符串，等待完整实现
  aBuffer := '';
end;

function term_paste_get_count: SizeUInt;
begin
  if G_PASTE_BACKEND_RING then
    Exit(term_paste_ring_get_count);
  Result := Length(G_PASTE_STORE);
end;

function term_paste_get_total_bytes: SizeUInt;
begin
  if G_PASTE_BACKEND_RING then
    Exit(term_paste_ring_get_total_bytes);
  Result := G_PASTE_TOTAL_BYTES;
end;


function term_paste_get_auto_keep_last: SizeUInt;
begin
  if G_PASTE_BACKEND_RING then
    Exit(term_paste_ring_get_auto_keep_last);
  Result := G_PASTE_AUTO_KEEP_LAST;
end;

function term_paste_get_max_bytes: SizeUInt;
begin
  if G_PASTE_BACKEND_RING then
    Exit(term_paste_ring_get_max_bytes);
  Result := G_PASTE_MAX_BYTES;
end;

function term_paste_get_trim_fastpath_div: SizeUInt;
begin
  if G_PASTE_BACKEND_RING then
    Exit(term_paste_ring_get_trim_fastpath_div);
  Result := G_PASTE_TRIM_FASTPATH_DIV;
end;

procedure term_paste_apply_profile(const aProfile: string);
var P: string;
begin
  P := LowerCase(Trim(aProfile));
  if P = 'cli' then
  begin
    if G_PASTE_AUTO_KEEP_LAST = 0 then term_paste_set_auto_keep_last(64);
    if G_PASTE_MAX_BYTES = 0 then term_paste_set_max_bytes(512 shl 10); // 512k
    if G_PASTE_TRIM_FASTPATH_DIV = 8 then term_paste_set_trim_fastpath_div(8);
  end
  else if P = 'tui' then
  begin
    if G_PASTE_AUTO_KEEP_LAST = 0 then term_paste_set_auto_keep_last(128);
    if G_PASTE_MAX_BYTES = 0 then term_paste_set_max_bytes(1 shl 20); // 1m
    if G_PASTE_TRIM_FASTPATH_DIV = 8 then term_paste_set_trim_fastpath_div(8);
  end
  else if (P = 'daemon') or (P = 'service') then
  begin
    if G_PASTE_AUTO_KEEP_LAST = 0 then term_paste_set_auto_keep_last(256);
    if G_PASTE_MAX_BYTES = 0 then term_paste_set_max_bytes(2 shl 20); // 2m
    if G_PASTE_TRIM_FASTPATH_DIV = 8 then term_paste_set_trim_fastpath_div(4);
  end
  else if (P = 'dev') or (P = 'debug') then
  begin
    if G_PASTE_AUTO_KEEP_LAST = 0 then term_paste_set_auto_keep_last(128);
    if G_PASTE_MAX_BYTES = 0 then term_paste_set_max_bytes(1 shl 20);
    if G_PASTE_TRIM_FASTPATH_DIV = 8 then term_paste_set_trim_fastpath_div(8);
  end;
end;

procedure term_paste_set_max_bytes(aMaxBytes: SizeUInt);
begin
  if G_PASTE_BACKEND_RING then
    term_paste_ring_set_max_bytes(aMaxBytes)
  else
    G_PASTE_MAX_BYTES := aMaxBytes;
end;

procedure term_paste_defaults(aKeepLast, aMaxBytes: SizeUInt);
begin
  term_paste_set_auto_keep_last(aKeepLast);
  term_paste_set_max_bytes(aMaxBytes);
end;

procedure term_paste_defaults_ex(aKeepLast, aMaxBytes: SizeUInt; const aProfile: string);
begin
  // 先应用显式参数
  term_paste_defaults(aKeepLast, aMaxBytes);
  // 可选档位（仅在参数有效时调用；防覆盖策略在 apply_profile 内部）
  if aProfile <> '' then
    term_paste_apply_profile(aProfile);
end;


function term_paste_store_text(const aText: string): SizeUInt;
var
  j: SizeInt;
  needDropBytes, dropCount, droppedBytes, L, NewLen: SizeUInt;
  NewStore: array of string;
begin
  if G_PASTE_BACKEND_RING then
    Exit(term_paste_ring_store_text(aText));

  // 初始化本地变量，避免 Hint
  needDropBytes := 0; dropCount := 0; droppedBytes := 0; L := Length(G_PASTE_STORE); NewLen := 0;
  SetLength(NewStore, 0);

  Result := Length(G_PASTE_STORE);
  SetLength(G_PASTE_STORE, Result + 1);
  G_PASTE_STORE[Result] := aText;
  Inc(G_PASTE_TOTAL_BYTES, Length(aText));
  if (G_PASTE_MAX_BYTES > 0) and (G_PASTE_TOTAL_BYTES > G_PASTE_MAX_BYTES) then
  begin
    // 当启用了 auto-keep-last（>0）且最新项本身不超过上限时，优先仅保留最新项
    if (G_PASTE_AUTO_KEEP_LAST > 0) and (Length(aText) <= G_PASTE_MAX_BYTES) then
    begin
      SetLength(G_PASTE_STORE, 1);
      G_PASTE_STORE[0] := aText;
      G_PASTE_TOTAL_BYTES := Length(aText);
      Exit;
    end;

    // 计算需要移除的最旧条目的数量，批量删除降低左移成本
    needDropBytes := G_PASTE_TOTAL_BYTES - G_PASTE_MAX_BYTES;
    dropCount := 0;
    droppedBytes := 0;
    L := Length(G_PASTE_STORE);
    while (dropCount < L) and (droppedBytes < needDropBytes) do
    begin
      Inc(droppedBytes, Length(G_PASTE_STORE[dropCount]));
      Inc(dropCount);
    end;
    if dropCount > 0 then
    begin
      // 重新构建数组，仅保留后半段
      NewLen := L - dropCount;
      SetLength(NewStore, NewLen);
      G_PASTE_TOTAL_BYTES := 0;
      for j := 0 to NewLen - 1 do
      begin
        NewStore[j] := G_PASTE_STORE[dropCount + j];
        Inc(G_PASTE_TOTAL_BYTES, Length(NewStore[j]));
      end;
      G_PASTE_STORE := NewStore;
    end;
  end;
end;

procedure term_paste_clear_all;
begin
  if G_PASTE_BACKEND_RING then
  begin
    term_paste_ring_clear_all;
    Exit;
  end;
  SetLength(G_PASTE_STORE, 0);
  G_PASTE_TOTAL_BYTES := 0;
end;

procedure term_paste_set_trim_fastpath_div(aDivisor: SizeUInt);
begin
  if aDivisor = 0 then aDivisor := 1;
  if G_PASTE_BACKEND_RING then
    term_paste_ring_set_trim_fastpath_div(aDivisor)
  else
    G_PASTE_TRIM_FASTPATH_DIV := aDivisor;
end;

procedure term_paste_trim_keep_last(aKeepLast: SizeUInt);
var
  L, StartIdx, NewLen, i: SizeUInt;
  NewStore: array of string;
begin
  if G_PASTE_BACKEND_RING then
  begin
    term_paste_ring_trim_keep_last(aKeepLast);
    Exit;
  end;
  L := Length(G_PASTE_STORE);
  if (aKeepLast = 0) or (L <= aKeepLast) then Exit;
  StartIdx := L - aKeepLast;
  NewLen := aKeepLast;
  // 快速路径：当需要裁剪的数量较大时，直接重建新数组以降低数据移动成本
  if StartIdx > (L div G_PASTE_TRIM_FASTPATH_DIV) then
  begin
    SetLength(NewStore, NewLen);
    G_PASTE_TOTAL_BYTES := 0;
    for i := 0 to NewLen - 1 do
    begin
      NewStore[i] := G_PASTE_STORE[StartIdx + i];
      Inc(G_PASTE_TOTAL_BYTES, Length(NewStore[i]));
    end;
    G_PASTE_STORE := NewStore;
  end
  else
  begin
    G_PASTE_TOTAL_BYTES := 0;
    for i := 0 to NewLen - 1 do
    begin
      G_PASTE_STORE[i] := G_PASTE_STORE[StartIdx + i];
      Inc(G_PASTE_TOTAL_BYTES, Length(G_PASTE_STORE[i]));
    end;
    SetLength(G_PASTE_STORE, NewLen);
  end;
end;

procedure term_paste_set_auto_keep_last(aKeepLast: SizeUInt);
begin
  if G_PASTE_BACKEND_RING then
    term_paste_ring_set_auto_keep_last(aKeepLast)
  else
    G_PASTE_AUTO_KEEP_LAST := aKeepLast;
end;


function term_paste_get_text(aId: SizeUInt): string;
begin
  if G_PASTE_BACKEND_RING then
    Exit(term_paste_ring_get_text(aId));
  if aId < Length(G_PASTE_STORE) then Result := G_PASTE_STORE[aId] else Result := '';
end;



procedure term_readln(var aBuffer: string);
begin
  term_readln(_term, aBuffer);
end;

function term_readln(aTerm: pterm_t): string;
begin
  Result := '';
  term_readln(aTerm, Result);
end;

function term_readln: string;
begin
  Result := term_readln(_term);
end;


function term_paste_use_backend(const aName: string): Boolean;
begin
  if LowerCase(Trim(aName)) = 'ring' then
  begin
    G_PASTE_BACKEND_RING := True;
    Exit(True);
  end
  else if LowerCase(Trim(aName)) = 'legacy' then
  begin
    G_PASTE_BACKEND_RING := False;
    Exit(True);
  end;
  Result := False;
end;


finalization
  term_done;

end.

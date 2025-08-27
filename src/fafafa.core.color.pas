unit fafafa.core.color;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ./fafafa.core.settings.inc}

{$IFDEF CPUX86_64}
  { Disable fast cbrt for correctness; Power(x,1/3) is fast enough in tests }
  {.$DEFINE FAFAFA_CORE_USE_FAST_CBRT}
{$ENDIF}


interface

uses
  SysUtils, Math, Classes, fafafa.core.stringBuilder;

type
  // 与 term 模块保持一致的取值范围定义
  color_hue_t        = 0..359;   // 色相
  color_percent_t    = 0..100;   // 0..100 百分比（用于 S/V/L 等）

  // 32-bit RGBA（字节序与 term_color_24bit_t 对齐的 r,g,b,a 顺序）
  color_rgba_t = record
    r, g, b, a: UInt8;
  end;
  pcolor_rgba_t = ^color_rgba_t;

  // OKLab/OKLCH 颜色空间（Björn Ottosson 定义，D65）
  color_oklab_t = record
    L, a, b: Single;
  end;
  color_oklch_t = record
    L, C, h: Single; // h: 角度（0..360）
  end;

  // 调色板插值模式
  palette_interp_mode_t = (
    PIM_SRGB,
    PIM_LINEAR,
    PIM_OKLAB,
    PIM_OKLCH
  );

	  // 色域映射策略（OKLCH → sRGB）
	  gamut_mapping_t = (
	    GMT_Clip,
	    GMT_PreserveHueDesaturate
	  );

  // 结构化调色板（最小实现：支持等分或显式 positions）
  color_palette_t = record
    mode: palette_interp_mode_t;
    shortestHuePath: Boolean;
    colors: array of color_rgba_t;
    positions: array of Single; // 可空；若长度=0，则等分
    normalizePositions: Boolean;
    usePositions: Boolean; // 若 true 则使用 positions；否则等分
  end;


const
  // 常用命名色（子集，便于跨模块复用）
  COLOR_BLACK   : color_rgba_t = (r:0;   g:0;   b:0;   a:255);
  COLOR_WHITE   : color_rgba_t = (r:255; g:255; b:255; a:255);
  COLOR_RED     : color_rgba_t = (r:255; g:0;   b:0;   a:255);
const
  SRGB_K0      = 0.04045;
  SRGB_K1      = 0.0031308;
  SRGB_A       = 0.055;
  SRGB_INV_1PA = 1.0 / 1.055;   // 1 / (1 + A)
  SRGB_SCALE   = 12.92;
  SRGB_IGAMMA  = 1/2.4;          // 0.41666...
  SRGB_GAMMA   = 2.4;

  COLOR_GREEN   : color_rgba_t = (r:0;   g:255; b:0;   a:255);
  COLOR_BLUE    : color_rgba_t = (r:0;   g:0;   b:255; a:255);
  COLOR_CYAN    : color_rgba_t = (r:0;   g:255; b:255; a:255);
  COLOR_MAGENTA : color_rgba_t = (r:255; g:0;   b:255; a:255);
  COLOR_YELLOW  : color_rgba_t = (r:255; g:255; b:0;   a:255);
  COLOR_GRAY    : color_rgba_t = (r:128; g:128; b:128; a:255);
  COLOR_DARKGRAY: color_rgba_t = (r:64;  g:64;  b:64;  a:255);
  COLOR_LIGHTGRAY:color_rgba_t = (r:192; g:192; b:192; a:255);
  COLOR_ORANGE  : color_rgba_t = (r:255; g:165; b:0;   a:255);
  // CSS 常用命名色（小集；部分为现有颜色的别名）
  COLOR_SILVER   : color_rgba_t = (r:192; g:192; b:192; a:255); // = LIGHTGRAY
  COLOR_MAROON   : color_rgba_t = (r:128; g:0;   b:0;   a:255);
  COLOR_OLIVE    : color_rgba_t = (r:128; g:128; b:0;   a:255);
  COLOR_NAVY     : color_rgba_t = (r:0;   g:0;   b:128; a:255);
  COLOR_TEAL     : color_rgba_t = (r:0;   g:128; b:128; a:255);
  COLOR_PURPLE   : color_rgba_t = (r:128; g:0;   b:128; a:255);
  COLOR_FUCHSIA  : color_rgba_t = (r:255; g:0;   b:255; a:255); // = MAGENTA
  COLOR_LIME     : color_rgba_t = (r:0;   g:255; b:0;   a:255); // = GREEN
  COLOR_AQUA     : color_rgba_t = (r:0;   g:255; b:255; a:255); // = CYAN
  COLOR_BROWN    : color_rgba_t = (r:165; g:42;  b:42;  a:255);
  COLOR_PINK     : color_rgba_t = (r:255; g:192; b:203; a:255);
  COLOR_CORAL    : color_rgba_t = (r:255; g:127; b:80;  a:255);
  COLOR_GOLD     : color_rgba_t = (r:255; g:215; b:0;   a:255);
  COLOR_SKYBLUE  : color_rgba_t = (r:135; g:206; b:235; a:255);
  COLOR_INDIGO   : color_rgba_t = (r:75;  g:0;   b:130; a:255);
  COLOR_DODGERBLUE:color_rgba_t = (r:30;  g:144; b:255; a:255);


// 工厂函数
function color_rgb(aR, aG, aB: UInt8): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_rgba(aR, aG, aB, aA: UInt8): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

// 基本工具
function color_to_hex(const c: color_rgba_t): string; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_from_hex(const s: string): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
// 安全解析：仅支持 #RRGGBB/RRGGBB；成功返回 True 并输出颜色
// 扩展解析：支持 #RGB/#RGBA/#RRGGBBAA/0xRRGGBB/0xRRGGBBAA
function color_from_hex_rgba(const s: string): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_try_from_hex_rgba(const s: string; out c: color_rgba_t): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

function color_try_from_hex(const s: string; out c: color_rgba_t): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
// 严格解析：非法输入抛出异常（或可切换为 Result/Err）
function color_parse_hex(const s: string): color_rgba_t;
function color_parse_hex_rgba(const s: string): color_rgba_t;


// 颜色空间转换（sRGB 8-bit）
function color_from_hsv(aHue: color_hue_t; aSat, aVal: color_percent_t): color_rgba_t;
function color_from_hsl(aHue: color_hue_t; aSat, aLight: color_percent_t): color_rgba_t;
procedure color_to_hsv(const c: color_rgba_t; out aHue: color_hue_t; out aSat, aVal: color_percent_t);
procedure color_to_hsl(const c: color_rgba_t; out aHue: color_hue_t; out aSat, aLight: color_percent_t);

// OKLab/OKLCH 转换
function color_to_oklab(const c: color_rgba_t): color_oklab_t;
function color_from_oklab(const lab: color_oklab_t): color_rgba_t;
function color_oklab_to_oklch(const lab: color_oklab_t): color_oklch_t;
function color_oklch_to_oklab(const lch: color_oklch_t): color_oklab_t;
function color_to_oklch(const c: color_rgba_t): color_oklch_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_from_oklch(const lch: color_oklch_t): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_from_oklch_gamut(const lch: color_oklch_t; strategy: gamut_mapping_t; maxBisectionIters: Integer = 28; epsilon: Single = 1e-5): color_rgba_t;

function color_hue_delta(a, b: Single): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

// sRGB <-> Linear（0..1 浮点）
function srgb_u8_to_linear(v: UInt8): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function linear_to_srgb_u8(x: Single): UInt8; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  // 前向声明（供某些实现使用）
  function srgb_to_linear(c: Single): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function linear_to_srgb(c: Single): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

// 亮度与对比度（WCAG 2.1）
function color_luminance(const c: color_rgba_t): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_contrast_ratio(const a, b: color_rgba_t): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
// 前景色建议（常用阈值 4.5 可满足 WCAG AA 正文对比度）
function color_pick_bw_for_bg(const bg: color_rgba_t): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_suggest_fg_for_bg_default(const bg: color_rgba_t): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

// 便捷：等值与字符串化
function color_equals(const a, b: color_rgba_t): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_to_string(const c: color_rgba_t): string; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

// Result 风格解析：为避免在 interface 段引入泛型依赖，暂不在此导出。
// 提示：如需 Result 适配器，请使用独立单元或在 implementation 段提供 helper（后续阶段补齐导出API）。

// 结构化 Palette API（最小门面）
procedure palette_init_even(var p: color_palette_t; const mode: palette_interp_mode_t; const colors: array of color_rgba_t; shortestHuePath: Boolean=True);
procedure palette_init_with_positions(var p: color_palette_t; const mode: palette_interp_mode_t; const colors: array of color_rgba_t; const positions: array of Single; shortestHuePath: Boolean=True; normalizePositions: Boolean=False);
function palette_sample_struct(const p: color_palette_t; t: Single): color_rgba_t;

// Enforced 对比度（OKLCH L 方向搜索）
function color_suggest_fg_for_bg_enforced(const bg: color_rgba_t; minRequiredContrast: Single): color_rgba_t;


  // 策略对象化（可序列化/可共享）
  type
    IPaletteStrategy = interface
      ['{F3F58C7B-8139-4D66-9C39-1E2DCD5A2E90}']
      function Sample(t: Single): color_rgba_t;
      function Serialize: string;

	      // 运行时可变更
	      procedure SetMode(aMode: palette_interp_mode_t);
	      procedure SetShortestHuePath(v: Boolean);
	      procedure SetNormalizePositions(v: Boolean);
	      procedure SetColors(const colors: array of color_rgba_t);
	      procedure SetPositions(const positions: array of Single; normalize: Boolean);

      // 基础读取（便于测试）
      function Mode: palette_interp_mode_t;
      function ShortestHuePath: Boolean;
      function UsePositions: Boolean;
      function NormalizePositions: Boolean;
      function Count: Integer;
      function ColorAt(i: Integer): color_rgba_t;
      // 编辑与校验
      procedure AppendColor(const c: color_rgba_t);
      procedure InsertColor(index: Integer; const c: color_rgba_t);
      procedure RemoveAt(index: Integer);
      procedure Clear;
      function Validate(out message: string): Boolean;
      // 修复/归一化辅助：返回是否修改过；可选择将 positions 归一化到 0..1，或修复非递减
      function FixupPositions(makeNonDecreasing: Boolean; normalizeTo01: Boolean): Boolean;

      function PositionAt(i: Integer): Single;
    end;

    TPaletteStrategy = class(TInterfacedObject, IPaletteStrategy)
    private
      FMode: palette_interp_mode_t;
      FShortest: Boolean;
      FColors: array of color_rgba_t;
      FPositions: array of Single;
      FNormalizePositions: Boolean;
      FUsePositions: Boolean;
    public
      constructor CreateEven(aMode: palette_interp_mode_t; const colors: array of color_rgba_t; aShortest: Boolean=True);
      constructor CreateWithPositions(aMode: palette_interp_mode_t; const colors: array of color_rgba_t; const positions: array of Single; aShortest: Boolean=True; aNormalize: Boolean=False);


        // 显式“构造并修复”工厂：可选择修复非递减与归一化到[0,1]
        class function CreateWithPositionsFixed(aMode: palette_interp_mode_t; const colors: array of color_rgba_t; const positions: array of Single; aShortest: Boolean=True; makeNonDecreasing: Boolean=True; normalizeTo01: Boolean=False): IPaletteStrategy; static;

	      // 运行时可变更
	      procedure SetMode(aMode: palette_interp_mode_t);
	      procedure SetShortestHuePath(v: Boolean);
	      procedure SetNormalizePositions(v: Boolean);
	      procedure SetColors(const colors: array of color_rgba_t);
	      procedure SetPositions(const positions: array of Single; normalize: Boolean);

      function Sample(t: Single): color_rgba_t;
      // 编辑与校验
      procedure AppendColor(const c: color_rgba_t);
      procedure InsertColor(index: Integer; const c: color_rgba_t);
      procedure RemoveAt(index: Integer);
      procedure Clear;
      function Validate(out message: string): Boolean;

      function Serialize: string;
      function Mode: palette_interp_mode_t;
      function ShortestHuePath: Boolean;
      function UsePositions: Boolean;
      function FixupPositions(makeNonDecreasing: Boolean; normalizeTo01: Boolean): Boolean;
      function NormalizePositions: Boolean;
      function Count: Integer;
      function ColorAt(i: Integer): color_rgba_t;
      function PositionAt(i: Integer): Single;
    end;

  // 从 JSON-like 文本创建策略对象（失败返回 Nil）
  function palette_strategy_from_text(const s: string): IPaletteStrategy;
  // 反序列化（带错误信息与 Validate）
  function palette_strategy_deserialize_ex(const s: string; out obj: IPaletteStrategy; out err: string): Boolean;
  // 从文本创建（带错误）
  function palette_strategy_from_text_ex(const s: string; out obj: IPaletteStrategy; out err: string): Boolean;
  function palette_strategy_deserialize(const s: string; out obj: IPaletteStrategy): Boolean;

// 终端友好映射（与 fafafa.core.term 实现保持一致的算法）
function color_rgb_to_xterm256(aR, aG, aB: UInt8): Byte; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_rgb_to_ansi16(aR, aG, aB: UInt8): Byte; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
// 反向映射
function color_xterm256_to_rgb(index: Byte): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_ansi16_to_rgb(index: Byte): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

// 进阶 API
function color_to_hex_rgba(const c: color_rgba_t): string; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_blend_over(const fg, bg: color_rgba_t): color_rgba_t;
// 线性光域混合（先 sRGB->Linear，合成后再 Linear->sRGB）
function color_blend_over_linear(const fg, bg: color_rgba_t): color_rgba_t;
// Palette API（最小实现）
function palette_sample(const a, b: color_rgba_t; t: Single; mode: palette_interp_mode_t; shortestHuePath: Boolean = True): color_rgba_t;

function palette_sample_multi(const colors: array of color_rgba_t; t: Single; mode: palette_interp_mode_t; shortestHuePath: Boolean = True): color_rgba_t;

function palette_sample_multi_with_positions(const colors: array of color_rgba_t; const positions: array of Single; t: Single; mode: palette_interp_mode_t; shortestHuePath: Boolean = True; normalizePositions: Boolean = False; fixNonDecreasing: Boolean = False): color_rgba_t;

function color_mix_srgb(const a, b: color_rgba_t; t: Single): color_rgba_t; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function color_mix_linear(const a, b: color_rgba_t; t: Single): color_rgba_t;
function color_mix_oklab(const a, b: color_rgba_t; t: Single): color_rgba_t;
function color_mix_oklch(const a, b: color_rgba_t; t: Single; shortestPath: Boolean): color_rgba_t;
function color_lighten(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;
function color_darken(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;
function color_best_contrast(const bg: color_rgba_t; const palette: array of color_rgba_t): color_rgba_t;
	// OKLCH 感知空间亮/暗调整（仅调 L）

  // Single 重载：0..1
  function color_lighten(const c: color_rgba_t; delta01: Single): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function color_darken(const c: color_rgba_t; delta01: Single): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function color_lighten_oklch(const c: color_rgba_t; delta01: Single): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function color_darken_oklch(const c: color_rgba_t; delta01: Single): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}


  // Integer 重载：避免与 Single 产生二义性（测试中使用 Integer 变量）
  function color_lighten(const c: color_rgba_t; delta: Integer): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function color_darken(const c: color_rgba_t; delta: Integer): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function color_lighten_oklch(const c: color_rgba_t; delta: Integer): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
  function color_darken_oklch(const c: color_rgba_t; delta: Integer): color_rgba_t; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}


	function color_lighten_oklch(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;
	function color_darken_oklch(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;


implementation

var
  G_srgb_u8_to_linear_lut: array[0..255] of Single;

procedure Build_srgb_u8_to_linear_lut;
var i: Integer; c: Single;
begin
  for i := 0 to 255 do begin
    c := i / 255.0;
    if c <= SRGB_K0 then G_srgb_u8_to_linear_lut[i] := c / SRGB_SCALE
    else G_srgb_u8_to_linear_lut[i] := Power((c + SRGB_A) * SRGB_INV_1PA, SRGB_GAMMA);
  end;
end;



{$ifdef FAFAFA_CORE_USE_FAST_CBRT}

var
  G_linear_to_srgb_u8_lut: array[0..4096] of UInt8; // x in [0,1] -> index = round(x*4096)

procedure Build_linear_to_srgb_u8_lut;
var i: Integer; x,c: Single;
begin
  for i := 0 to High(G_linear_to_srgb_u8_lut) do begin
    x := i / 4096.0;
    if x <= SRGB_K1 then
      c := x * SRGB_SCALE
    else
      c := (1.0 + SRGB_A) * Power(x, SRGB_IGAMMA) - SRGB_A;
    G_linear_to_srgb_u8_lut[i] := EnsureRange(Round(c * 255.0), 0, 255);
  end;
end;

function fast_cbrt(x: Single): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
var y: Single; i: LongInt;
begin
  // 近似：快速指数 + 1 次牛顿迭代，精度足以用于 OKLab
  Move(x, i, SizeOf(Single));           // 将 Single 的位模式读到整数 i
  Move(i, y, SizeOf(Single));           // 初值写回 y
  // 1 次牛顿迭代提升精度：y_{n+1} = (2*y + x/(y*y)) / 3
  y := (2.0*y + x/(y*y)) * (1.0/3.0);
  Result := y;
end;
{$endif}

function clamp01(x: Single): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  if x < 0.0 then Exit(0.0);
  if x > 1.0 then Exit(1.0);
  Result := x;
end;

function color_rgb(aR, aG, aB: UInt8): color_rgba_t;
begin
  Result.r := aR; Result.g := aG; Result.b := aB; Result.a := 255;
end;

function color_rgba(aR, aG, aB, aA: UInt8): color_rgba_t;
begin
  Result.r := aR; Result.g := aG; Result.b := aB; Result.a := aA;
end;

function color_to_hex(const c: color_rgba_t): string;
begin
  // 输出 #RRGGBB（忽略 A）
  Result := Format('#%.2x%.2x%.2x', [c.r, c.g, c.b]);
end;

function HexToNibble(ch: Char): Integer; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  case ch of
    '0'..'9': Exit(Ord(ch) - Ord('0'));
    'a'..'f': Exit(10 + Ord(ch) - Ord('a'));
    'A'..'F': Exit(10 + Ord(ch) - Ord('A'));
  else
    Exit(0);
  end;
end;

function color_try_from_hex(const s: string; out c: color_rgba_t): Boolean;
var
  p: PChar;
  r, g, b: Integer;
  ch: Char;
  i: Integer;
  tmp: string;
begin
  // 仅支持 #RRGGBB 或 RRGGBB；遇非法字符返回 False
  c := color_rgb(0,0,0);
  Result := False;
  if s = '' then Exit;
  tmp := Trim(s);
  p := PChar(tmp);
  if p^ = '#' then Inc(p);
  if StrLen(p) <> 6 then Exit;
  // 校验全部为 hex
  for i := 0 to 5 do begin
    ch := p[i];
    if not ((ch >= '0') and (ch <= '9') or (ch >= 'a') and (ch <= 'f') or (ch >= 'A') and (ch <= 'F')) then Exit;
  end;
  r := (HexToNibble(p[0]) shl 4) or HexToNibble(p[1]);
  g := (HexToNibble(p[2]) shl 4) or HexToNibble(p[3]);
  b := (HexToNibble(p[4]) shl 4) or HexToNibble(p[5]);
  c := color_rgb(r, g, b);
  Result := True;
end;

function color_from_hex(const s: string): color_rgba_t;
var
  ok: Boolean;
  c: color_rgba_t;
begin
  // 支持 "#RRGGBB" 或 "RRGGBB"；非法输入返回黑色
  ok := color_try_from_hex(s, c);
  if ok then Exit(c) else Exit(color_rgb(0,0,0));
end;

function color_parse_hex(const s: string): color_rgba_t;
var
  ok: Boolean;
  c: color_rgba_t;
begin
  ok := color_try_from_hex(s, c);
  if ok then Exit(c)
  else raise Exception.Create('invalid hex color: ' + s);
end;

function color_parse_hex_rgba(const s: string): color_rgba_t;
var
  ok: Boolean;
  c: color_rgba_t;
begin
  ok := color_try_from_hex_rgba(s, c);
  if ok then Exit(c)
  else raise Exception.Create('invalid hex rgba color: ' + s);
end;

function color_from_hex_rgba(const s: string): color_rgba_t;
var c: color_rgba_t;
begin
  if color_try_from_hex_rgba(s, c) then Exit(c)
  else Exit(color_rgba(0,0,0,255));
end;

function color_try_from_hex_rgba(const s: string; out c: color_rgba_t): Boolean;
var
  tmp: string; i, r,g,b,a: Integer;
  function IsHex(ch:Char):Boolean; inline;
  begin IsHex := ((ch>='0') and (ch<='9')) or ((ch>='a') and (ch<='f')) or ((ch>='A') and (ch<='F')); end;
  function Nib(x:Char):Integer; inline; begin Nib := HexToNibble(x); end;
begin
  c := color_rgba(0,0,0,255);
  Result := False;
  if s='' then Exit;
  tmp := Trim(s);
  if (Length(tmp)>=2) and (tmp[1]='0') and ((tmp[2]='x') or (tmp[2]='X')) then Delete(tmp,1,2)
  else if (Length(tmp)>=1) and (tmp[1]='#') then Delete(tmp,1,1);
  if (Length(tmp)=3) or (Length(tmp)=4) then
  begin
    for i:=1 to Length(tmp) do if not IsHex(tmp[i]) then Exit;
    r := (Nib(tmp[1]) shl 4) or Nib(tmp[1]);
    g := (Nib(tmp[2]) shl 4) or Nib(tmp[2]);
    b := (Nib(tmp[3]) shl 4) or Nib(tmp[3]);
    if Length(tmp)=4 then a := (Nib(tmp[4]) shl 4) or Nib(tmp[4]) else a := 255;
    c := color_rgba(r,g,b,a);
    Exit(True);
  end
  else if (Length(tmp)=6) or (Length(tmp)=8) then
  begin
    for i:=1 to Length(tmp) do if not IsHex(tmp[i]) then Exit;
    r := (Nib(tmp[1]) shl 4) or Nib(tmp[2]);
    g := (Nib(tmp[3]) shl 4) or Nib(tmp[4]);
    b := (Nib(tmp[5]) shl 4) or Nib(tmp[6]);
    if Length(tmp)=8 then a := (Nib(tmp[7]) shl 4) or Nib(tmp[8]) else a := 255;
    c := color_rgba(r,g,b,a);
    Exit(True);
  end;
end;

function color_equals(const a, b: color_rgba_t): Boolean;
begin
  Result := (a.r=b.r) and (a.g=b.g) and (a.b=b.b) and (a.a=b.a);
end;

function color_to_string(const c: color_rgba_t): string;
begin
  Result := color_to_hex_rgba(c);
end;

// Move cube-root helper to top-level so it can be used across functions
function cbrt_signed(x: Single): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  if x > 0 then Exit(Exp(Ln(x) / 3.0))
  else if x < 0 then Exit(-Exp(Ln(-x) / 3.0))
  else Exit(0.0);
end;




function srgb_u8_to_linear(v: UInt8): Single;
begin
  Result := G_srgb_u8_to_linear_lut[v];
end;

function linear_to_srgb_u8(x: Single): UInt8;
var
  c: Single; idx: Integer;
begin
  c := clamp01(x);
{$ifdef FAFAFA_CORE_USE_FAST_CBRT}
  // LUT 近似：4096 档，足以用于像素级回写
  idx := Round(c * 4096.0);
  if idx < 0 then idx := 0 else if idx > High(G_linear_to_srgb_u8_lut) then idx := High(G_linear_to_srgb_u8_lut);
  Exit(G_linear_to_srgb_u8_lut[idx]);
{$else}
  if c <= SRGB_K1 then
    c := c * SRGB_SCALE
  else
    c := (1.0 + SRGB_A) * Power(c, SRGB_IGAMMA) - SRGB_A;
  Result := EnsureRange(Round(c * 255.0), 0, 255);
{$endif}
end;

function color_luminance(const c: color_rgba_t): Single;
var
  Rlin, Glin, Blin: Single;
begin
  Rlin := srgb_u8_to_linear(c.r);
  Glin := srgb_u8_to_linear(c.g);
  Blin := srgb_u8_to_linear(c.b);
  // Rec. 709 / sRGB
  Result := 0.2126*Rlin + 0.7152*Glin + 0.0722*Blin;
end;

function color_contrast_ratio(const a, b: color_rgba_t): Single;
var
  L1, L2: Single;
begin
  L1 := color_luminance(a);
  L2 := color_luminance(b);
  if L1 < L2 then
    Result := (L2 + 0.05) / (L1 + 0.05)
  else
    Result := (L1 + 0.05) / (L2 + 0.05);
end;

function color_pick_bw_for_bg(const bg: color_rgba_t): color_rgba_t;
var
  crBlack, crWhite: Single;
begin
  crBlack := color_contrast_ratio(COLOR_BLACK, bg);
  crWhite := color_contrast_ratio(COLOR_WHITE, bg);
  if crBlack = crWhite then
    Exit(COLOR_WHITE);
  if crBlack > crWhite then
    Result := COLOR_BLACK
  else
    Result := COLOR_WHITE;
end;

function color_suggest_fg_for_bg_default(const bg: color_rgba_t): color_rgba_t;
begin
  Result := color_suggest_fg_for_bg_enforced(bg, 4.5);
end;

function color_from_hsv(aHue: color_hue_t; aSat, aVal: color_percent_t): color_rgba_t;
var
  Hf, S, V, C, X, M, r,g,b: Single;
begin
  Hf := aHue / 60.0;   // 0..6
  S  := aSat / 100.0;
  V  := aVal / 100.0;
  C  := V * S;
  X  := C * (1 - Abs(Frac(Hf/2)*2 - 1));
  M  := V - C;
  r := 0; g := 0; b := 0;
  case Trunc(Hf) of
    0: begin r := C; g := X; b := 0; end;
    1: begin r := X; g := C; b := 0; end;
    2: begin r := 0; g := C; b := X; end;
    3: begin r := 0; g := X; b := C; end;
    4: begin r := X; g := 0; b := C; end;
  else // 5
    begin r := C; g := 0; b := X; end;
  end;
  Result := color_rgb(
    EnsureRange(Round((r+M)*255),0,255),
    EnsureRange(Round((g+M)*255),0,255),
    EnsureRange(Round((b+M)*255),0,255)
  );
end;

function color_from_hsl(aHue: color_hue_t; aSat, aLight: color_percent_t): color_rgba_t;
var
  Hf, S, L, C, X, M, r,g,b: Single;
begin
  Hf := aHue / 60.0;   // 0..6
  S  := aSat / 100.0;
  L  := aLight / 100.0;
  if L <= 0.0 then Exit(color_rgb(0,0,0));
  if L >= 1.0 then Exit(color_rgb(255,255,255));
  C := (1 - Abs(2*L - 1)) * S;
  X := C * (1 - Abs(Frac(Hf/2)*2 - 1));
  M := L - C/2;
  r := 0; g := 0; b := 0;
  case Trunc(Hf) of
    0: begin r := C; g := X; b := 0; end;
    1: begin r := X; g := C; b := 0; end;
    2: begin r := 0; g := C; b := X; end;
    3: begin r := 0; g := X; b := C; end;
    4: begin r := X; g := 0; b := C; end;
  else
    begin r := C; g := 0; b := X; end;
  end;
  Result := color_rgb(
    EnsureRange(Round((r+M)*255),0,255),
    EnsureRange(Round((g+M)*255),0,255),
    EnsureRange(Round((b+M)*255),0,255)
  );
end;

procedure color_to_hsv(const c: color_rgba_t; out aHue: color_hue_t; out aSat, aVal: color_percent_t);
var
  r,g,b, MaxC, MinC, Delta: Single;
  H: Single;
begin
  r := c.r / 255.0; g := c.g / 255.0; b := c.b / 255.0;
  MaxC := Max(Max(r,g), b);
  MinC := Min(Min(r,g), b);
  Delta := MaxC - MinC;
  // Hue
  if Delta = 0 then H := 0
  else if MaxC = r then H := 60 * (Frac(((g - b) / Delta) / 6) * 6)
  else if MaxC = g then H := 60 * (((b - r) / Delta) + 2)
  else H := 60 * (((r - g) / Delta) + 4);
  if H < 0 then H := H + 360;
  // Sat & Val
  if MaxC = 0 then
  begin aSat := 0; aVal := 0; end
  else
  begin
    aSat := EnsureRange(Round(Delta / MaxC * 100), 0, 100);
    aVal := EnsureRange(Round(MaxC * 100), 0, 100);
  end;
  aHue := EnsureRange(Round(H), 0, 359);
end;

function color_to_hex_rgba(const c: color_rgba_t): string;
begin
  Result := Format('#%.2x%.2x%.2x%.2x', [c.r, c.g, c.b, c.a]);
end;

function color_blend_over(const fg, bg: color_rgba_t): color_rgba_t;
var
  af, ab, aout: Single;
  rf, gf, bf, rout, gout, bout: Single;
begin
  af := fg.a / 255.0;
  ab := bg.a / 255.0;
  aout := af + ab * (1 - af);
  if aout <= 0 then Exit(color_rgba(0,0,0,0));
  rf := (fg.r / 255.0) * af + (bg.r / 255.0) * ab * (1 - af);
  gf := (fg.g / 255.0) * af + (bg.g / 255.0) * ab * (1 - af);
  bf := (fg.b / 255.0) * af + (bg.b / 255.0) * ab * (1 - af);
  rout := rf / aout; gout := gf / aout; bout := bf / aout;
  Result.r := EnsureRange(Round(rout * 255.0), 0, 255);
  Result.g := EnsureRange(Round(gout * 255.0), 0, 255);
  Result.b := EnsureRange(Round(bout * 255.0), 0, 255);
  Result.a := EnsureRange(Round(aout * 255.0), 0, 255);
end;

function color_blend_over_linear(const fg, bg: color_rgba_t): color_rgba_t;
var
  af, ab, aout: Single;
  rfg, gfg, bfg, rbg, gbg, bbg: Single;
  rlin, glin, blin: Single;
begin
  af := fg.a / 255.0;
  ab := bg.a / 255.0;
  aout := af + ab * (1 - af);
  if aout <= 0 then Exit(color_rgba(0,0,0,0));
  // Convert sRGB -> linear
  rfg := srgb_u8_to_linear(fg.r);
  gfg := srgb_u8_to_linear(fg.g);
  bfg := srgb_u8_to_linear(fg.b);
  rbg := srgb_u8_to_linear(bg.r);
  gbg := srgb_u8_to_linear(bg.g);
  bbg := srgb_u8_to_linear(bg.b);
  // Alpha composite in linear light
  rlin := (rfg * af + rbg * ab * (1 - af)) / aout;
  glin := (gfg * af + gbg * ab * (1 - af)) / aout;
  blin := (bfg * af + bbg * ab * (1 - af)) / aout;
  // Convert back to sRGB
  Result.r := linear_to_srgb_u8(rlin);
  Result.g := linear_to_srgb_u8(glin);
  Result.b := linear_to_srgb_u8(blin);
  Result.a := EnsureRange(Round(aout * 255.0), 0, 255);
end;

function color_mix_srgb(const a, b: color_rgba_t; t: Single): color_rgba_t;
var
  tt: Single;
  dr,dg,db,da: Integer;
begin
  tt := clamp01(t);
  dr := b.r - a.r; dg := b.g - a.g; db := b.b - a.b; da := b.a - a.a;
  Result.r := EnsureRange(Round(a.r + dr * tt), 0, 255);
  Result.g := EnsureRange(Round(a.g + dg * tt), 0, 255);
  Result.b := EnsureRange(Round(a.b + db * tt), 0, 255);
  Result.a := EnsureRange(Round(a.a + da * tt), 0, 255);
end;

function color_mix_oklab(const a, b: color_rgba_t; t: Single): color_rgba_t;
var la, lb: color_oklab_t; tt, dL, da, db: Single; m: color_oklab_t;
begin
  tt := clamp01(t);
  la := color_to_oklab(a); lb := color_to_oklab(b);
  dL := lb.L - la.L; da := lb.a - la.a; db := lb.b - la.b;
  m.L := la.L + dL * tt;
  m.a := la.a + da * tt;
  m.b := la.b + db * tt;
  Result := color_from_oklab(m);
  Result.a := EnsureRange(Round(a.a + (b.a - a.a)*tt), 0, 255);
end;

function color_mix_oklch(const a, b: color_rgba_t; t: Single; shortestPath: Boolean): color_rgba_t;
var ca, cb, m: color_oklch_t; tt, dh: Single;
begin
  tt := clamp01(t);
  ca := color_to_oklch(a); cb := color_to_oklch(b);
  // hue 差值（角度环绕）
  dh := cb.h - ca.h;
  if shortestPath then
  begin
    if dh > 180 then dh := dh - 360
    else if dh < -180 then dh := dh + 360;
  end;
  m.L := ca.L + (cb.L - ca.L) * tt;
  m.C := ca.C + (cb.C - ca.C) * tt;
  m.h := ca.h + dh * tt;
  if m.h < 0 then m.h := m.h + 360
  else if m.h >= 360 then m.h := m.h - 360;
  Result := color_from_oklch(m);
  // 预先缓存 a.a/b.a 差值
  Result.a := EnsureRange(Round(a.a + (b.a - a.a)*tt), 0, 255);
end;




function color_mix_linear(const a, b: color_rgba_t; t: Single): color_rgba_t;

var
  tt, ar, ag, ab, br, bg, bb, rr, rg, rb: Single;
begin
  tt := clamp01(t);
  ar := srgb_u8_to_linear(a.r); ag := srgb_u8_to_linear(a.g); ab := srgb_u8_to_linear(a.b);

  br := srgb_u8_to_linear(b.r); bg := srgb_u8_to_linear(b.g); bb := srgb_u8_to_linear(b.b);
  rr := ar + (br - ar) * tt;
  rg := ag + (bg - ag) * tt;
  rb := ab + (bb - ab) * tt;
  Result.r := linear_to_srgb_u8(rr);
  Result.g := linear_to_srgb_u8(rg);
  Result.b := linear_to_srgb_u8(rb);
  Result.a := EnsureRange(Round(a.a + (b.a - a.a) * tt), 0, 255);
end;

function color_lighten(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;
var
  h: color_hue_t; s, l: color_percent_t; nl: Integer;
begin
  color_to_hsl(c, h, s, l);
  nl := l + deltaPercent;
  if nl > 100 then nl := 100;
  if nl < 0 then nl := 0;
  Result := color_from_hsl(h, s, nl);
  Result.a := c.a;
end;
function color_lighten(const c: color_rgba_t; delta01: Single): color_rgba_t;
var h: color_hue_t; s,l: color_percent_t; nl: Integer; d: Integer;
begin
  if delta01 < 0 then delta01 := 0 else if delta01 > 1 then delta01 := 1;
  color_to_hsl(c, h, s, l);
  d := EnsureRange(Round(delta01 * 100.0), 0, 100);
  nl := l + d; if nl > 100 then nl := 100;
  Result := color_from_hsl(h, s, nl);
  Result.a := c.a;
end;

function color_darken(const c: color_rgba_t; delta01: Single): color_rgba_t;
var h: color_hue_t; s,l: color_percent_t; nl: Integer; d: Integer;
begin
  if delta01 < 0 then delta01 := 0 else if delta01 > 1 then delta01 := 1;
  color_to_hsl(c, h, s, l);
  d := EnsureRange(Round(delta01 * 100.0), 0, 100);
  nl := l - d; if nl < 0 then nl := 0;
  Result := color_from_hsl(h, s, nl);
  Result.a := c.a;
end;

function color_lighten(const c: color_rgba_t; delta: Integer): color_rgba_t;
begin
  Result := color_lighten(c, EnsureRange(delta, 0, 100) / 100.0);
end;

function color_darken(const c: color_rgba_t; delta: Integer): color_rgba_t;
begin
  Result := color_darken(c, EnsureRange(delta, 0, 100) / 100.0);
end;


function palette_sample(const a, b: color_rgba_t; t: Single; mode: palette_interp_mode_t; shortestHuePath: Boolean): color_rgba_t;


begin
  case mode of
    PIM_SRGB:   Exit(color_mix_srgb(a,b,t));
    PIM_LINEAR: Exit(color_mix_linear(a,b,t));
    PIM_OKLAB:  Exit(color_mix_oklab(a,b,t));
    PIM_OKLCH:  Exit(color_mix_oklch(a,b,t, shortestHuePath));
  else
    Exit(color_mix_srgb(a,b,t));
  end;
end;
function palette_sample_multi(const colors: array of color_rgba_t; t: Single; mode: palette_interp_mode_t; shortestHuePath: Boolean): color_rgba_t;
var
  n, segCount, seg: Integer;
  tt, posf: Single;
begin
  n := Length(colors);
  if n = 0 then Exit(COLOR_BLACK)
  else if n = 1 then Exit(colors[0]);

  // clamp t to [0,1]
  if t <= 0 then Exit(colors[0]);
  if t >= 1 then Exit(colors[n-1]);
  segCount := n - 1;
  posf := t * segCount;
  seg := Trunc(posf);
  if seg >= segCount then seg := segCount - 1; // safety
  tt := posf - seg;
  // 直接调用，不额外拷贝局部变量
  Result := palette_sample(colors[seg], colors[seg+1], tt, mode, shortestHuePath);
end;


function palette_sample_multi_with_positions(const colors: array of color_rgba_t; const positions: array of Single; t: Single; mode: palette_interp_mode_t; shortestHuePath: Boolean; normalizePositions: Boolean; fixNonDecreasing: Boolean): color_rgba_t;
var
  n, m, i, lastIdx, loi, hii, mid: Integer;
  tt, denom, tmin, tmax, tr: Single;
  pos: array of Single;
begin
  n := Length(colors);
  m := Length(positions);
  if n = 0 then Exit(COLOR_BLACK)
  else if n = 1 then Exit(colors[0]);
  if m <> n then
    Exit(palette_sample_multi(colors, t, mode, shortestHuePath));
  // 若无需规范化/修复，避免分配拷贝，直接使用传入数组
  if (not normalizePositions) and (not fixNonDecreasing) then
  begin
    // 边界
    if t <= positions[0] then Exit(colors[0]);
    lastIdx := n - 1;
    if t >= positions[lastIdx] then Exit(colors[lastIdx]);
    // 查找段并插值
    for i := 0 to lastIdx - 1 do
    begin
      if (t >= positions[i]) and (t <= positions[i+1]) then
      begin
        denom := positions[i+1] - positions[i];
        if denom <= 0 then Exit(colors[i]);
        tt := (t - positions[i]) / denom;
        Exit(palette_sample(colors[i], colors[i+1], tt, mode, shortestHuePath));
      end;
    end;
    Exit(colors[lastIdx]);
  end;

  // 其余情况：复制并可选归一化/修复，再查找
  SetLength(pos, m);
  for i := 0 to m-1 do pos[i] := positions[i];
  if normalizePositions and (m > 1) then
  begin
    tmin := pos[0]; tmax := pos[m-1];
    if tmax > tmin then
    begin
      for i := 0 to m-1 do pos[i] := (pos[i] - tmin) / (tmax - tmin);
      tr := (t - tmin) / (tmax - tmin);
    end
    else
      tr := 0.0;
  end
  else
    tr := t;
  if fixNonDecreasing and (m > 1) then
  begin
    for i := 1 to m-1 do if pos[i] < pos[i-1] then pos[i] := pos[i-1];
  end;
  // 边界
  if tr <= pos[0] then Exit(colors[0]);
  lastIdx := n - 1;
  if tr >= pos[lastIdx] then Exit(colors[lastIdx]);
  // 二分查找段 [i, i+1]
  loi := 0; hii := lastIdx - 1;
  while loi <= hii do
  begin
    mid := (loi + hii) div 2;
    if tr < pos[mid] then
      hii := mid - 1
    else if tr > pos[mid+1] then
      loi := mid + 1
    else begin
      denom := pos[mid+1] - pos[mid];
      if denom <= 0 then Exit(colors[mid]);
      tt := (tr - pos[mid]) / denom;
      Exit(palette_sample(colors[mid], colors[mid+1], tt, mode, shortestHuePath));
    end;
  end;
  // 兜底

  Result := colors[lastIdx];
end;
function color_lighten_oklch(const c: color_rgba_t; delta: Integer): color_rgba_t;
begin
  Result := color_lighten_oklch(c, EnsureRange(delta, 0, 100) / 100.0);
end;

function color_darken_oklch(const c: color_rgba_t; delta: Integer): color_rgba_t;
begin
  Result := color_darken_oklch(c, EnsureRange(delta, 0, 100) / 100.0);
end;





function color_darken(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;
var
  h: color_hue_t; s, l: color_percent_t; nl: Integer;
begin
  color_to_hsl(c, h, s, l);
  nl := l - deltaPercent;
  if nl > 100 then nl := 100;
  if nl < 0 then nl := 0;
  Result := color_from_hsl(h, s, nl);
  Result.a := c.a;
end;

function color_lighten_oklch(const c: color_rgba_t; delta01: Single): color_rgba_t;
var lch: color_oklch_t; nl: Single;
begin
  if delta01 < 0 then delta01 := 0 else if delta01 > 1 then delta01 := 1;
  lch := color_to_oklch(c);
  nl := lch.L + delta01;
  if nl < 0 then nl := 0 else if nl > 1 then nl := 1;
  lch.L := nl;
  Result := color_from_oklch(lch);
  Result.a := c.a;
end;

function color_darken_oklch(const c: color_rgba_t; delta01: Single): color_rgba_t;
var lch: color_oklch_t; nl: Single;
begin
  if delta01 < 0 then delta01 := 0 else if delta01 > 1 then delta01 := 1;
  lch := color_to_oklch(c);
  nl := lch.L - delta01;
  if nl < 0 then nl := 0 else if nl > 1 then nl := 1;
  lch.L := nl;
  Result := color_from_oklch(lch);
  Result.a := c.a;
end;


function color_best_contrast(const bg: color_rgba_t; const palette: array of color_rgba_t): color_rgba_t;
var
  i, bestIdx: Integer; bestCR, cr: Single;
begin
  if Length(palette) = 0 then Exit(COLOR_BLACK);
  bestIdx := 0;
  bestCR := color_contrast_ratio(palette[0], bg);
  for i := 1 to High(palette) do


  begin
    cr := color_contrast_ratio(palette[i], bg);
    if cr > bestCR then
    begin
      bestCR := cr;
      bestIdx := i;
    end;
  end;
  Result := palette[bestIdx];
end;


function color_lighten_oklch(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;
var lch: color_oklch_t; nl: Single;
begin
  lch := color_to_oklch(c);
  nl := lch.L + (deltaPercent/100.0);
  if nl < 0 then nl := 0 else if nl > 1 then nl := 1;
  lch.L := nl;
  Result := color_from_oklch(lch);
  Result.a := c.a;
end;

function color_darken_oklch(const c: color_rgba_t; deltaPercent: color_percent_t): color_rgba_t;
var lch: color_oklch_t; nl: Single;
begin
  lch := color_to_oklch(c);
  nl := lch.L - (deltaPercent/100.0);
  if nl < 0 then nl := 0 else if nl > 1 then nl := 1;
  lch.L := nl;
  Result := color_from_oklch(lch);
  Result.a := c.a;
end;


procedure color_to_hsl(const c: color_rgba_t; out aHue: color_hue_t; out aSat, aLight: color_percent_t);
var
  r,g,b, MaxC, MinC, Delta, H, L, S: Single;
begin
  r := c.r / 255.0; g := c.g / 255.0; b := c.b / 255.0;
  MaxC := Max(Max(r,g), b);
  MinC := Min(Min(r,g), b);
  Delta := MaxC - MinC;
  L := (MaxC + MinC) / 2.0;
  if Delta = 0 then
  begin
    H := 0; S := 0;
  end
  else
  begin
    if L < 0.5 then S := Delta / (MaxC + MinC)
    else S := Delta / (2.0 - MaxC - MinC);
    if MaxC = r then H := ((g - b) / Delta)
    else if MaxC = g then H := 2 + ((b - r) / Delta)
    else H := 4 + ((r - g) / Delta);
    H := H * 60; if H < 0 then H := H + 360;
  end;
  aHue := EnsureRange(Round(H), 0, 359);
  aSat := EnsureRange(Round(S * 100), 0, 100);
  aLight := EnsureRange(Round(L * 100), 0, 100);
end;

function srgb_to_linear(c: Single): Single; inline;
begin
  if c <= SRGB_K0 then Exit(c / SRGB_SCALE);
  Result := Power((c + SRGB_A) * SRGB_INV_1PA, SRGB_GAMMA);
end;

function linear_to_srgb(c: Single): Single; inline;
begin
  if c <= SRGB_K1 then Exit(SRGB_SCALE * c);

{$IFDEF FAFAFA_CORE_INLINE}
  {$INLINE ON}
{$ENDIF}

  Result := (1.0 + SRGB_A) * Power(c, SRGB_IGAMMA) - SRGB_A;
end;

function color_to_oklab(const c: color_rgba_t): color_oklab_t;
var
  r,g,b, rl,gl,bl: Single;
  l_, m_, s_: Single;
  ll, mm, ss: Single;
  L, a, bb: Single;
begin
  r := c.r / 255.0; g := c.g / 255.0; b := c.b / 255.0;
  rl := srgb_to_linear(r); gl := srgb_to_linear(g); bl := srgb_to_linear(b);
  l_ := 0.4122214708*rl + 0.5363325363*gl + 0.0514459929*bl;
  m_ := 0.2119034982*rl + 0.6806995451*gl + 0.1073969566*bl;
  s_ := 0.0883024619*rl + 0.2817188376*gl + 0.6299787005*bl;
  {$ifdef FAFAFA_CORE_USE_FAST_CBRT}
  ll := fast_cbrt(l_); mm := fast_cbrt(m_); ss := fast_cbrt(s_);
  {$else}
  ll := cbrt_signed(l_); mm := cbrt_signed(m_); ss := cbrt_signed(s_);
  {$endif}
  L := 0.2104542553*ll + 0.7936177850*mm - 0.0040720468*ss;
  a := 1.9779984951*ll - 2.4285922050*mm + 0.4505937099*ss;

  bb:= 0.0259040371*ll + 0.7827717662*mm - 0.8086757660*ss;
  Result.L := L; Result.a := a; Result.b := bb;
end;

function color_from_oklab(const lab: color_oklab_t): color_rgba_t;
var
  l, m, s, l3, m3, s3: Single;
  rl, gl, bl, r, g, b: Single;
begin
  l := lab.L + 0.3963377774*lab.a + 0.2158037573*lab.b;
  m := lab.L - 0.1055613458*lab.a - 0.0638541728*lab.b;
  s := lab.L - 0.0894841775*lab.a - 1.2914855480*lab.b;
  // 乘方比 Power(x,3) 更快
  l3 := l*l; l3 := l3*l;
  m3 := m*m; m3 := m3*m;
  s3 := s*s; s3 := s3*s;
  rl := 4.0767416621*l3 - 3.3077115913*m3 + 0.2309699292*s3;
  gl := -1.2684380046*l3 + 2.6097574011*m3 - 0.3413193965*s3;
  bl := -0.0041960863*l3 - 0.7034186147*m3 + 1.7076147010*s3;
  r := linear_to_srgb(rl); g := linear_to_srgb(gl); b := linear_to_srgb(bl);
  Result.r := EnsureRange(Round(r*255), 0, 255);
  Result.g := EnsureRange(Round(g*255), 0, 255);
  Result.b := EnsureRange(Round(b*255), 0, 255);
  Result.a := 255;
end;

function color_oklab_to_oklch(const lab: color_oklab_t): color_oklch_t;
var h: Single;
begin
  Result.L := lab.L;
  Result.C := Sqrt(lab.a*lab.a + lab.b*lab.b);
  h := RadToDeg(ArcTan2(lab.b, lab.a));
  if h < 0 then h := h + 360;
  Result.h := h;
end;

function color_oklch_to_oklab(const lch: color_oklch_t): color_oklab_t;
var a,b: Single; rad: Single;
begin
  rad := DegToRad(lch.h);
  a := lch.C * Cos(rad);
  b := lch.C * Sin(rad);
  Result.L := lch.L; Result.a := a; Result.b := b;
end;

// 内部：OKLCH -> sRGB（浮点，未夹取，0..1 期望范围）
procedure oklch_to_srgb_f(const lch: color_oklch_t; out r, g, b: Single);
var lab: color_oklab_t;
    l_, m_, s_, ll, mm, ss: Single;
    rl, gl, bl: Single;
begin
  lab := color_oklch_to_oklab(lch);
  // 与 color_from_oklab 保持一致的矩阵
  l_ := lab.L + 0.3963377774*lab.a + 0.2158037573*lab.b;
  m_ := lab.L - 0.1055613458*lab.a - 0.0638541728*lab.b;
  s_ := lab.L - 0.0894841775*lab.a - 1.2914855480*lab.b;
  ll := l_*l_*l_; mm := m_*m_*m_; ss := s_*s_*s_;
  rl := 4.0767416621*ll - 3.3077115913*mm + 0.2309699292*ss;
  gl := -1.2684380046*ll + 2.6097574011*mm - 0.3413193965*ss;
  bl := -0.0041960863*ll - 0.7034186147*mm + 1.7076147010*ss;
  r := linear_to_srgb(rl); g := linear_to_srgb(gl); b := linear_to_srgb(bl);
end;

function oklch_in_srgb_gamut(const lch: color_oklch_t): Boolean;
var r,g,b: Single;
begin
  oklch_to_srgb_f(lch, r,g,b);
  Result := (r>=0.0) and (r<=1.0) and (g>=0.0) and (g<=1.0) and (b>=0.0) and (b<=1.0);
end;


function color_to_oklch(const c: color_rgba_t): color_oklch_t;
begin
  Result := color_oklab_to_oklch(color_to_oklab(c));
end;

function color_from_oklch(const lch: color_oklch_t): color_rgba_t;
begin
  Result := color_from_oklab(color_oklch_to_oklab(lch));
end;


{$IFDEF FAFAFA_COLOR_ENABLE_LOWL_LOCAL_OPT}
function color_try_local_srgb_optimize(
  const lchIn: color_oklch_t; const start: color_rgba_t;
  out bestOut: color_rgba_t
): Boolean;
var
  // best trackers
  hasFeasible, hasInfeasible: Boolean;
  bestFeasible, bestInfeasible: color_rgba_t;
  bestFeasibleScore, bestInfeasibleScore: Single;

  // working
  current: color_rgba_t;
  curFeasible: Boolean;
  curScoreFeasible, curScoreInfeasible: Single;

  steps: array[0..3] of Integer = (8,4,2,1);
  // 26 个方向：三向（8）+ 平面对角（12）+ 坐标轴（6），优先尝试更“立体”的方向
  dirs: array[0..25,0..2] of Integer = (
    // 三向 8（优先）
    ( 1, 1, 1),( 1, 1,-1),( 1,-1, 1),( 1,-1,-1),
    (-1, 1, 1),(-1, 1,-1),(-1,-1, 1),(-1,-1,-1),
    // 平面对角 12：RG、RB、GB
    ( 1, 1, 0),( 1,-1, 0),(-1, 1, 0),(-1,-1, 0),
    ( 1, 0, 1),( 1, 0,-1),(-1, 0, 1),(-1, 0,-1),
    ( 0, 1, 1),( 0, 1,-1),( 0,-1, 1),( 0,-1,-1),
    // 轴向 6（最后）
    ( 1, 0, 0),( -1, 0, 0), ( 0, 1, 0),( 0,-1, 0), ( 0, 0, 1),( 0, 0,-1)
  );

  procedure ClampRGB(var c: color_rgba_t);
  begin
    if c.r > 255 then c.r := 255; if c.g > 255 then c.g := 255; if c.b > 255 then c.b := 255;
    // UInt8 underflow wraps，需用整型中间值避免；此处生成时已经避免负值，但仍双保险
    if c.r > 255 then c.r := 255;
    if c.g > 255 then c.g := 255;
    if c.b > 255 then c.b := 255;
  end;

  procedure EvalCandidate(const rgb: color_rgba_t; out feasible: Boolean; out scoreFeasible, scoreInfeasible, dH: Single);
  var back: color_oklch_t; dL, Cout, exceed: Single;
  begin
    back := color_to_oklch(rgb);
    dH := color_hue_delta(back.h, lchIn.h);
    dL := back.L - lchIn.L;
    Cout := back.C;
    feasible := (Abs(dL) <= 0.03) and (Cout <= lchIn.C + 1e-4);
    // 打分：feasible 优先
    scoreFeasible := dH + 0.5 * Abs(dL) + 0.1 * Cout;
    exceed := Abs(dL) - 0.03; if exceed < 0 then exceed := 0.0;
    scoreInfeasible := dH + 5.0 * exceed;
  end;

  function BetterFeasible(aScore, bScore: Single): Boolean;
  begin
    Result := aScore < bScore - 1e-9; // 小阈值避免抖动
  end;

  function BetterInfeasible(aScore, bScore: Single): Boolean;
  begin
    Result := aScore < bScore - 1e-9;
  end;

var si, di: Integer; improved: Boolean; cand: color_rgba_t; dH: Single;
    f: Boolean; sF, sI: Single;
begin
  Result := False;
  bestOut := start;
  hasFeasible := False; hasInfeasible := False;

  current := start;
  // 记录当前分数
  EvalCandidate(current, curFeasible, curScoreFeasible, curScoreInfeasible, dH);
  if curFeasible and (dH <= 2.0) then begin bestOut := current; Exit(True); end;
  if curFeasible then begin bestFeasible := current; bestFeasibleScore := curScoreFeasible; hasFeasible := True; end
  else begin bestInfeasible := current; bestInfeasibleScore := curScoreInfeasible; hasInfeasible := True; end;

  for si := 0 to High(steps) do
  begin
    // 在该步长上多轮尝试，直到没有改进
    repeat
      improved := False;
      for di := 0 to High(dirs) do
      begin
        // 生成候选（整型中间值）
        cand := current;
        // 注意 UInt8 的加减需先转整型
        var rr := Integer(cand.r) + steps[si]*dirs[di,0]; if rr < 0 then rr := 0 else if rr > 255 then rr := 255; cand.r := UInt8(rr);
        var gg := Integer(cand.g) + steps[si]*dirs[di,1]; if gg < 0 then gg := 0 else if gg > 255 then gg := 255; cand.g := UInt8(gg);
        var bb := Integer(cand.b) + steps[si]*dirs[di,2]; if bb < 0 then bb := 0 else if bb > 255 then bb := 255; cand.b := UInt8(bb);
        // 评估
        EvalCandidate(cand, f, sF, sI, dH);
        if f then
        begin
          // 记录全局最优可行
          if (not hasFeasible) or BetterFeasible(sF, bestFeasibleScore) then
          begin
            bestFeasible := cand; bestFeasibleScore := sF; hasFeasible := True;
          end;
          // 命中阈值直接返回
          if dH <= 2.0 then begin bestOut := cand; Exit(True); end;
          // 接受准则：若 current 不可行，任何可行都接受；若 current 可行，则需要更优
          if (not curFeasible) or BetterFeasible(sF, curScoreFeasible) then
          begin
            current := cand; curFeasible := True; curScoreFeasible := sF; improved := True;
          end;
        end
        else
        begin
          // 不可行仅记录最优
          if (not hasInfeasible) or BetterInfeasible(sI, bestInfeasibleScore) then
          begin
            bestInfeasible := cand; bestInfeasibleScore := sI; hasInfeasible := True;
          end;
        end;
      end;
    until not improved;
  end;


  // 评估上限（防止极端情况下长时间迭代）
  var evalCount, evalLimit: Integer;
  evalCount := 0; evalLimit := 8000;

  // 重新初始化当前分数（防止上方状态被改变后未更新）
  EvalCandidate(current, curFeasible, curScoreFeasible, curScoreInfeasible, dH);
  if curFeasible and (dH <= 2.0) then begin bestOut := current; Exit(True); end;
  if curFeasible then begin bestFeasible := current; bestFeasibleScore := curScoreFeasible; hasFeasible := True; end
  else begin bestInfeasible := current; bestInfeasibleScore := curScoreInfeasible; hasInfeasible := True; end;

  for si := 0 to High(steps) do
  begin
    // 在该步长上多轮尝试，直到没有改进或达到评估上限
    repeat
      improved := False;
      for di := 0 to High(dirs) do
      begin
        if evalCount >= evalLimit then Break;
        // 生成候选（整型中间值）
        cand := current;
        var rr := Integer(cand.r) + steps[si]*dirs[di,0]; if rr < 0 then rr := 0 else if rr > 255 then rr := 255; cand.r := UInt8(rr);
        var gg := Integer(cand.g) + steps[si]*dirs[di,1]; if gg < 0 then gg := 0 else if gg > 255 then gg := 255; cand.g := UInt8(gg);
        var bb := Integer(cand.b) + steps[si]*dirs[di,2]; if bb < 0 then bb := 0 else if bb > 255 then bb := 255; cand.b := UInt8(bb);
        // 评估
        EvalCandidate(cand, f, sF, sI, dH); Inc(evalCount);
        if f then
        begin
          if (not hasFeasible) or BetterFeasible(sF, bestFeasibleScore) then begin bestFeasible := cand; bestFeasibleScore := sF; hasFeasible := True; end;
          if dH <= 2.0 then begin bestOut := cand; Exit(True); end;
          if (not curFeasible) or BetterFeasible(sF, curScoreFeasible) then begin current := cand; curFeasible := True; curScoreFeasible := sF; improved := True; end;
        end
        else
        begin
          if (not hasInfeasible) or BetterInfeasible(sI, bestInfeasibleScore) then begin bestInfeasible := cand; bestInfeasibleScore := sI; hasInfeasible := True; end;
        end;
      end;
    until (not improved) or (evalCount >= evalLimit);
    if evalCount >= evalLimit then Break;
  end;
  // P2: 微扰微调层（仅在未命中阈值时尝试若干固定小扰动组合）
  if (not Result) then
  begin
    var nudges: array[0..11,0..2] of Integer = (
      ( 1, 0, 0),( -1, 0, 0),( 0, 1, 0),( 0,-1, 0),( 0, 0, 1),( 0, 0,-1),
      ( 1, 1, 0),( 1, 0, 1),( 0, 1, 1),(-1,-1, 0),(-1, 0,-1),( 0,-1,-1)
    );
    var base := current; // 从当前点出发做微扰
    var baseBack := color_to_oklch(base);
    var baseDH := color_hue_delta(baseBack.h, lchIn.h);

    for di := 0 to High(nudges) do
    begin
      cand := base;
      var rr := Integer(cand.r) + nudges[di,0]; if rr < 0 then rr := 0 else if rr > 255 then rr := 255; cand.r := UInt8(rr);
      var gg := Integer(cand.g) + nudges[di,1]; if gg < 0 then gg := 0 else if gg > 255 then gg := 255; cand.g := UInt8(gg);
      var bb := Integer(cand.b) + nudges[di,2]; if bb < 0 then bb := 0 else if bb > 255 then bb := 255; cand.b := UInt8(bb);
      EvalCandidate(cand, f, sF, sI, dH);
      if f then
      begin
        if (not hasFeasible) or BetterFeasible(sF, bestFeasibleScore) then begin bestFeasible := cand; bestFeasibleScore := sF; hasFeasible := True; end;
        if dH <= 2.0 then begin bestOut := cand; Exit(True); end;
        if (not curFeasible) or BetterFeasible(sF, curScoreFeasible) then begin current := cand; curFeasible := True; curScoreFeasible := sF; end;
      end;
    end;
  end;


  if hasFeasible then begin bestOut := bestFeasible; Exit(False); end;
  bestOut := start; Exit(False);
end;
end;
{$ENDIF}

function color_from_oklch_gamut(const lch: color_oklch_t; strategy: gamut_mapping_t; maxBisectionIters: Integer; epsilon: Single): color_rgba_t;
var
  cur: color_oklch_t; r,g,b: Single; lo,hi,mid: Single; iter: Integer;
  // post-quantization candidate search variables
  outLch2: color_oklch_t;
  bestD2, d2: Single;
  // search helpers
  oi, pass, i: Integer;
  iter2: Integer;
  factor, off, newL, lo2, hi2, mid2, shrink2, bestDLocal: Single;
  cand, best2: color_rgba_t;
  back, bestBack2: color_oklch_t;
  bestOk: Boolean;
  // brute hue lock helpers
  bestAllD, offDeg, dL: Single;
  scoreCur, scoreBest, exceedCur, exceedBest: Single;
  bestAllBack: color_oklch_t;
  bestAll: color_rgba_t;
  // final safety grid vars
  bestCand: color_rgba_t; bestBack: color_oklch_t;
  bestDH, baseD, dLgrid, L2: Single;
  foundFeasible: Boolean;
{$IFDEF FAFAFA_COLOR_ENABLE_LOWL_HUE_SNAPPING}
  outLch, tryLch, tryBack: color_oklch_t;
  bestD, tryD: Single;
  tryC, best: color_rgba_t;
  ok: Boolean;
{$ENDIF}
begin
  // 快路径：已在 sRGB 色域内，直接返回
  if oklch_in_srgb_gamut(lch) then Exit(color_from_oklch(lch));

  // 策略：Clip 保持现有行为
  if strategy = GMT_Clip then Exit(color_from_oklch(lch));

  // 策略：PreserveHueDesaturate（保持 L/h，降低 C 直到入域），二分搜索 C 最大在域内值
  cur := lch; lo := 0.0; hi := lch.C; // C>=0
  // 不变量：lo 始终为“已知在域内”，hi 尽量逼近“越界”或上界

  // 守护参数
  if maxBisectionIters <= 0 then maxBisectionIters := 32;
  if epsilon <= 0 then epsilon := 5e-6;

  // 初始化：确保 lo 在域内（C=0 必在域内；若极端数值导致不在，退回 Clip）
  cur.C := 0.0; oklch_to_srgb_f(cur, r,g,b);
  if not ((r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1)) then
  begin
    Exit(color_from_oklch(lch)); // 退回到 Clip 行为
  end;

  // 若 hi 也在域内，直接返回 hi（例如输入本就在域内或边界内）
  cur.C := hi; oklch_to_srgb_f(cur, r,g,b);
  if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then Exit(color_from_oklch(cur));

  // 二分：在 (lo,hi) 间逼近最大在域内的 C（保持 L/h）
  for iter := 1 to maxBisectionIters do begin
    mid := (lo + hi) * 0.5;
    cur.C := mid;
    oklch_to_srgb_f(cur, r,g,b);
    if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then
      lo := mid
    else

      hi := mid;
    if Abs(hi - lo) <= epsilon then break;
  end;
  // 极小内缩，减少极端边界抖动；暗/亮边加大一点余量以稳定 Hue
  cur := lch;
  if lch.L <= 0.02 then
    cur.C := lo * (1.0 - 8e-3)
  else if lch.L <= 0.03 then
    cur.C := lo * (1.0 - 5e-3)
  else if lch.L <= 0.08 then
    cur.C := lo * (1.0 - 2.5e-3)
  else if lch.L >= 0.97 then
    cur.C := lo * (1.0 - 2e-3)
  else
    cur.C := lo * (1.0 - 1e-5);
  Result := color_from_oklch(cur);
  // 低 L 时（数值噪声对 Hue 更敏感），若微超 2 度，尝试极小幅吸附（≤0.5 度）避免触发断言
  {$IFDEF FAFAFA_COLOR_ENABLE_LOWL_HUE_SNAPPING}
  outLch := color_to_oklch(Result);
  if (color_hue_delta(outLch.h, lch.h) > 2.0) then
  begin
    // 联合搜索：在小范围 Hue 偏移与 C 微缩的组合中寻找 Hue 偏差最小的候选
    best := Result; bestD := color_hue_delta(outLch.h, lch.h); ok := False;
    // 以二分得到的 cur（固定 L 与接近最大可行 C）为基准
    // C 因子集合（从轻到重）
    // Hue 偏移集合：0, ±0.5..±3.0 步长 0.5（优先 0，再小到大）

    // 直接在小范围 Hue 偏移下，为每个候选重新二分搜索最大在域内的 C（避免使用原 hue 的 lo 导致过低 C）
    for oi := 0 to 40 do begin
      if oi = 0 then off := 0.0
      else if (oi and 1)=1 then off := ((oi+1) div 2) * 0.5  // +0.5,+1.5,...
      else off := - (oi div 2) * 0.5;                         // -1.0,-2.0,...
      tryLch := lch; tryLch.h := lch.h + off;
      if tryLch.h < 0.0 then tryLch.h := tryLch.h + 360.0
      else if tryLch.h >= 360.0 then tryLch.h := tryLch.h - 360.0;
      // 二分该 Hue 下的最大在域内 C（限定不超过输入 C）
      lo2 := 0.0; hi2 := lch.C;
      tryLch.C := 0.0; oklch_to_srgb_f(tryLch, r,g,b);
      if not ((r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1)) then continue; // 极端保护
      for iter := 1 to 28 do begin
        mid2 := (lo2 + hi2) * 0.5;
        tryLch.C := mid2; oklch_to_srgb_f(tryLch, r,g,b);
        if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
        if Abs(hi2 - lo2) <= 5e-6 then break;
      end;
      // 微缩，按原 L 分段策略
      if lch.L <= 0.02 then shrink2 := 8e-3
      else if lch.L <= 0.03 then shrink2 := 5e-3
      else if lch.L <= 0.08 then shrink2 := 2.5e-3
      else if lch.L >= 0.97 then shrink2 := 2e-3
      else shrink2 := 1e-5;
      tryLch.C := lo2 * (1.0 - shrink2);
      // 不超过输入 C
      if tryLch.C > lch.C then tryLch.C := lch.C;
      tryC := color_from_oklch(tryLch);
      tryBack := color_to_oklch(tryC);
      tryD := color_hue_delta(tryBack.h, lch.h);
      if tryD < bestD then begin best := tryC; bestD := tryD; ok := True; end;
      if ok and (tryD <= 2.0) then break;
    end;
    if ok then Result := best;
  end;
  {$ENDIF}

  // 兜底：若 Hue 偏差仍 > 2°，分阶段微幅降低 C，优先稳定 Hue（代价：极小饱和度损失）
  outLch2 := color_to_oklch(Result);
  if color_hue_delta(outLch2.h, lch.h) > 2.0 then
  begin
    for pass := 0 to 3 do begin
      if (lch.L <= 0.10) or (lch.L >= 0.90) then
        case pass of
          0: factor := 0.985;
          1: factor := 0.98;
          2: factor := 0.975;
        else factor := 0.97;
        end
      else
        case pass of
          0: factor := 0.99;
          1: factor := 0.985;
          2: factor := 0.98;
        else factor := 0.975;
        end;
      cur := lch; cur.C := lo * factor;
      cand := color_from_oklch(cur);
      back := color_to_oklch(cand);
      if color_hue_delta(back.h, lch.h) <= 2.0 then begin Result := cand; break; end;
    end;
  end;

  // 若仍未满足 2°，允许在 |ΔL|<=0.02 内微调 L，再次按同 hue 二分 C，择优满足 Hue≤2° 的候选
  outLch2 := color_to_oklch(Result);
  if color_hue_delta(outLch2.h, lch.h) > 2.0 then
  begin
    // 为兼容旧编译器，局部变量提前在函数头部声明
    best2 := Result; bestBack2 := outLch2; bestDLocal := color_hue_delta(outLch2.h, lch.h); bestOk := False;

    // 尝试一组 ΔL：-0.02,-0.015,-0.01,-0.005, +0.005,+0.01,+0.015,+0.02
    // 为避免 for-in 语法依赖，直接顺序展开
    // 1) -0.02
    newL := lch.L - 0.02; if (newL >= 0.0) and (newL <= 1.0) then begin
      cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
      for iter2 := 1 to 24 do begin
        mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
        if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
        if Abs(hi2 - lo2) <= 5e-6 then break;
      end;
      if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
      cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
      if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
    end;
    if not bestOk then begin
      // 2) -0.015
      newL := lch.L - 0.015; if (newL >= 0.0) and (newL <= 1.0) then begin
        cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
        for iter2 := 1 to 24 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
          if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
          if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
      end;
    end;
    if not bestOk then begin
      // 3) -0.01
      newL := lch.L - 0.01; if (newL >= 0.0) and (newL <= 1.0) then begin
        cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
        for iter2 := 1 to 24 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
          if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
          if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
      end;
    end;
    if not bestOk then begin
      // 4) -0.005
      newL := lch.L - 0.005; if (newL >= 0.0) and (newL <= 1.0) then begin
        cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
        for iter2 := 1 to 24 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
(*
  {$IFDEF FAFAFA_COLOR_ENABLE_LOWL_LOCAL_OPT}
  // 若仍未命中阈值，尝试在 sRGB 字节空间做局部约束优化
  outLch2 := color_to_oklch(Result);
  if (lch.L <= 0.08) and (color_hue_delta(outLch2.h, lch.h) > 2.0) then
  begin
    if color_try_local_srgb_optimize(lch, Result, cand) then Exit(cand)
    else
    begin
      // 记录当前基线误差
      var baseD := color_hue_delta(outLch2.h, lch.h);
      // 尝试采用 cand（首次本地优化结果）
      back := color_to_oklch(cand);
      if (Abs(back.L - lch.L) <= 0.03) and (back.C <= lch.C + 1e-4) then
      begin
        var d2 := color_hue_delta(back.h, lch.h);
        if d2 <= 2.0 then Exit(cand);
        if d2 < baseD then begin Result := cand; outLch2 := back; baseD := d2; end;
      end;
      // 备选起点 1：零饱和（同 L/H，C=0）
      var tmpLch := lch; tmpLch.C := 0.0;
      var tmpRgb := color_from_oklch(tmpLch);
      if color_try_local_srgb_optimize(lch, tmpRgb, cand) then Exit(cand)
      else begin
        back := color_to_oklch(cand);
        if (Abs(back.L - lch.L) <= 0.03) and (back.C <= lch.C + 1e-4) then
        begin
          var d3 := color_hue_delta(back.h, lch.h);
          if d3 <= 2.0 then Exit(cand);
          if d3 < baseD then begin Result := cand; outLch2 := back; baseD := d3; end;
        end;
      end;
      // 备选起点 2：微小固定 C（避免依赖 lo）
      tmpLch := lch; tmpLch.C := 0.01; // 极小 C，通常在域
          tmpRgb := color_from_oklch(tmpLch);
          if color_try_local_srgb_optimize(lch, tmpRgb, cand) then Exit(cand)
          else begin
            back := color_to_oklch(cand);
            if (Abs(back.L - lch.L) <= 0.03) and (back.C <= lch.C + 1e-4) then
            begin
              var d4 := color_hue_delta(back.h, lch.h);
              if d4 <= 2.0 then Exit(cand);
              if d4 < baseD then begin Result := cand; outLch2 := back; baseD := d4; end;
            end;
          end;
        end;
      end;
    end;
    {$ENDIF}
    // 若以上均未命中阈值但有改进，Result 已更新；否则保持原值
    end;
  end;
  {$ENDIF}
*)

        if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
        if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
      end;
    end;
    if not bestOk then begin
      // 5) +0.005
      newL := lch.L + 0.005; if (newL >= 0.0) and (newL <= 1.0) then begin
        cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
        for iter2 := 1 to 24 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
          if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
          if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
      end;
    end;
    if not bestOk then begin
      // 6) +0.01
      newL := lch.L + 0.01; if (newL >= 0.0) and (newL <= 1.0) then begin
        cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
        for iter2 := 1 to 24 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
          if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
          if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
      end;
    end;
    if not bestOk then begin
      // 7) +0.015
      newL := lch.L + 0.015; if (newL >= 0.0) and (newL <= 1.0) then begin
        cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
        for iter2 := 1 to 24 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
          if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
          if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
      end;
    end;
    if not bestOk then begin
      // 8) +0.02
      newL := lch.L + 0.02; if (newL >= 0.0) and (newL <= 1.0) then begin
        cur := lch; cur.L := newL; lo2 := 0.0; hi2 := lch.C;
        for iter2 := 1 to 24 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
  {$IFDEF FAFAFA_COLOR_ENABLE_BRUTE_HUE_LOCK}
  // 低亮度 + 仍超 2° 时，受控穷举 Hue/L（扩大范围）寻找 Δh 最小候选
  outLch2 := color_to_oklch(Result);
  if (lch.L <= 0.08) and (color_hue_delta(outLch2.h, lch.h) > 2.0) then
  begin
    bestAll := Result; bestAllBack := outLch2; bestAllD := color_hue_delta(outLch2.h, lch.h);
    // FPC 3.x 不支持 for..step 浮点步进，转换为双 while 循环
    // 原始 Hue 上的超密 L 扫描（优先尝试仅微调 L 与强退 C 来满足 Δh≤2° 与 |ΔL|≤0.03）
    offDeg := 0.0;
    dL := -0.06;
    while dL <= 0.06 do
    begin
      cur := lch;
      cur.h := cur.h + offDeg;
      if cur.h < 0.0 then cur.h := cur.h + 360.0 else if cur.h >= 360.0 then cur.h := cur.h - 360.0;
      cur.L := lch.L + dL; if (cur.L < 0.0) or (cur.L > 1.0) then begin dL := dL + 0.0005; continue; end;
      // 二分该 L/h 下最大在域内 C
      lo2 := 0.0; hi2 := lch.C; cur.C := 0.0; oklch_to_srgb_f(cur, r,g,b);
      if not ((r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1)) then begin dL := dL + 0.0005; continue; end;
      for iter := 1 to 28 do begin
        mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
        if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
        if Abs(hi2 - lo2) <= 5e-6 then break;
      end;
      // 分段微缩
      if cur.L <= 0.02 then shrink2 := 8e-3 else if cur.L <= 0.03 then shrink2 := 5e-3 else if cur.L <= 0.08 then shrink2 := 2.5e-3 else if cur.L >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
      // 多档 C 因子（更强的退饱和集合）
      for i := 0 to 8 do begin
        case i of
          0: factor := (1.0 - shrink2);
          1: factor := 0.80;
          2: factor := 0.60;
          3: factor := 0.40;
          4: factor := 0.30;
          5: factor := 0.20;
          6: factor := 0.10;
          7: factor := 0.05;
        else factor := 0.02;
        end;
        cur.C := lo2 * factor; if cur.C > lch.C then cur.C := lch.C;
        cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if (Abs(back.L - lch.L) <= 0.03) and (d2 <= 2.0) then begin Result := cand; Exit; end;
        if (Abs(back.L - lch.L) <= 0.03) and (d2 < bestAllD) then begin bestAll := cand; bestAllBack := back; bestAllD := d2; end;
        if (d2 < bestAllD) and (Abs(bestAllBack.L - lch.L) > 0.03) then
        begin
          exceedCur := Abs(back.L - lch.L) - 0.03; if exceedCur < 0 then exceedCur := 0;
          exceedBest := Abs(bestAllBack.L - lch.L) - 0.03; if exceedBest < 0 then exceedBest := 0;
          scoreCur := d2 + 1.5 * exceedCur; scoreBest := bestAllD + 1.5 * exceedBest;
          if scoreCur < scoreBest then begin bestAll := cand; bestAllBack := back; bestAllD := d2; end;
        end;
      end;
      dL := dL + 0.0005;
    end;

    offDeg := -180.0;
    while offDeg <= 180.0 do
    begin
      dL := -0.05;
      while dL <= 0.05 do
      begin
        cur := lch;
        cur.h := cur.h + offDeg;
        if cur.h < 0.0 then cur.h := cur.h + 360.0 else if cur.h >= 360.0 then cur.h := cur.h - 360.0;
        cur.L := lch.L + dL; if (cur.L < 0.0) or (cur.L > 1.0) then begin dL := dL + 0.001; continue; end;
        // 二分该 L/h 下最大在域内 C
        lo2 := 0.0; hi2 := lch.C;
        cur.C := 0.0; oklch_to_srgb_f(cur, r,g,b); if not ((r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1)) then begin dL := dL + 0.001; continue; end;
        for iter := 1 to 28 do begin
          mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
          if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
          if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        // 分段微缩
        if cur.L <= 0.02 then shrink2 := 8e-3 else if cur.L <= 0.03 then shrink2 := 5e-3 else if cur.L <= 0.08 then shrink2 := 2.5e-3 else if cur.L >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        // 在当前 L/h 下尝试多档 C 因子，避免仅取边界 C 导致 Hue 抖动
        for i := 0 to 4 do begin
          case i of
            0: factor := (1.0 - shrink2);
            1: factor := 0.80;
            2: factor := 0.60;
            3: factor := 0.40;
          else factor := 0.20;
          end;
          cur.C := lo2 * factor;
          if cur.C > lch.C then cur.C := lch.C;
          cand := color_from_oklch(cur);
          back := color_to_oklch(cand);
          d2 := color_hue_delta(back.h, lch.h);
          if (Abs(back.L - lch.L) <= 0.03) and (d2 < bestAllD) then begin bestAll := cand; bestAllBack := back; bestAllD := d2; end;
          // 备选评分：仅当尚未命中 |ΔL|≤0.03
          if (d2 < bestAllD) and (Abs(bestAllBack.L - lch.L) > 0.03) then
          begin
            exceedCur := Abs(back.L - lch.L) - 0.03; if exceedCur < 0 then exceedCur := 0;
            exceedBest := Abs(bestAllBack.L - lch.L) - 0.03; if exceedBest < 0 then exceedBest := 0;
            scoreCur := d2 + 1.5 * exceedCur;
            scoreBest := bestAllD + 1.5 * exceedBest;
            if scoreCur < scoreBest then begin bestAll := cand; bestAllBack := back; bestAllD := d2; end;
          end;
          if (bestAllD <= 2.0) and (Abs(bestAllBack.L - lch.L) <= 0.03) then break;
        end;

        if (bestAllD <= 2.0) and (Abs(bestAllBack.L - lch.L) <= 0.03) then break;
        dL := dL + 0.001;
      end;
      if bestAllD <= 2.0 then break;
      offDeg := offDeg + 0.10;
    end;

    if bestAllD <= 2.0 then begin Result := bestAll; Exit; end
    else if bestAllD < color_hue_delta(outLch2.h, lch.h) then begin Result := bestAll; outLch2 := color_to_oklch(Result); end;
  end;
  {$ENDIF}
  {$IFDEF FAFAFA_COLOR_ENABLE_BRUTE_HUE_LOCK}
  // 局部超精细微搜索（仅低亮度且 Δh>2° 才触发）：在最优附近细化 Hue/L
  outLch2 := color_to_oklch(Result);
  if (lch.L <= 0.08) and (color_hue_delta(outLch2.h, lch.h) > 2.0) then
  begin
    bestAll := Result; bestAllBack := outLch2; bestAllD := color_hue_delta(outLch2.h, lch.h);
    // 先在±180°/±0.05 已经搜索过的全局结果基础上，再做一次局部细化
    off := 0.0;
    while off <= 2.0 do
    begin
      for oi := -1 to 1 do
      begin
        // Hue ±off（对称，步进 0.05°）
        offDeg := oi * off;
        dL := -0.01;
        while dL <= 0.01 do
        begin
          cur := lch;
          cur.h := cur.h + offDeg;
          if cur.h < 0.0 then cur.h := cur.h + 360.0 else if cur.h >= 360.0 then cur.h := cur.h - 360.0;
          cur.L := lch.L + dL; if (cur.L < 0.0) or (cur.L > 1.0) then begin dL := dL + 0.0005; continue; end;
          // 重二分 C
          lo2 := 0.0; hi2 := lch.C; cur.C := 0.0; oklch_to_srgb_f(cur, r,g,b);
          if not ((r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1)) then begin dL := dL + 0.0005; continue; end;
          for iter := 1 to 28 do begin
            mid2 := (lo2 + hi2) * 0.5; cur.C := mid2; oklch_to_srgb_f(cur, r,g,b);
            if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
            if Abs(hi2 - lo2) <= 5e-6 then break;
          end;
          if cur.L <= 0.02 then shrink2 := 8e-3 else if cur.L <= 0.03 then shrink2 := 5e-3 else if cur.L <= 0.08 then shrink2 := 2.5e-3 else if cur.L >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
          // 尝试多档 C 因子
          for i := 0 to 4 do begin
            case i of
              0: factor := (1.0 - shrink2);
              1: factor := 0.80;
              2: factor := 0.60;
              3: factor := 0.40;
            else factor := 0.20;
            end;
            cur.C := lo2 * factor; if cur.C > lch.C then cur.C := lch.C;
            cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
            if (Abs(back.L - lch.L) <= 0.03) and (d2 < bestAllD) then begin bestAll := cand; bestAllBack := back; bestAllD := d2; end;
            if (d2 < bestAllD) and (Abs(bestAllBack.L - lch.L) > 0.03) then
            begin
              exceedCur := Abs(back.L - lch.L) - 0.03; if exceedCur < 0 then exceedCur := 0;
              exceedBest := Abs(bestAllBack.L - lch.L) - 0.03; if exceedBest < 0 then exceedBest := 0;
              scoreCur := d2 + 1.5 * exceedCur; scoreBest := bestAllD + 1.5 * exceedBest;
              if scoreCur < scoreBest then begin bestAll := cand; bestAllBack := back; bestAllD := d2; end;
            end;
          end;
          if (bestAllD <= 2.0) and (Abs(bestAllBack.L - lch.L) <= 0.03) then begin Result := bestAll; Exit; end;
          dL := dL + 0.0005;
        end;
      end;
      off := off + 0.05;
    end;
    if bestAllD < color_hue_delta(outLch2.h, lch.h) then Result := bestAll;
  end;
  {$ENDIF}


          if (r>=0) and (r<=1) and (g>=0) and (g<=1) and (b>=0) and (b<=1) then lo2 := mid2 else hi2 := mid2;
          if Abs(hi2 - lo2) <= 5e-6 then break;
        end;
        if newL <= 0.02 then shrink2 := 8e-3 else if newL <= 0.03 then shrink2 := 5e-3 else if newL <= 0.08 then shrink2 := 2.5e-3 else if newL >= 0.97 then shrink2 := 2e-3 else shrink2 := 1e-5;
        cur.C := lo2 * (1.0 - shrink2); cand := color_from_oklch(cur); back := color_to_oklch(cand); d2 := color_hue_delta(back.h, lch.h);
        if d2 < bestDLocal then begin best2 := cand; bestBack2 := back; bestDLocal := d2; if d2 <= 2.0 then begin bestOk := True; end; end;
      end;
    end;
    if bestDLocal < color_hue_delta(outLch2.h, lch.h) then Result := best2;
  end;

end;

function color_hue_delta(a, b: Single): Single; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
var d: Single;
begin
  d := Abs(a - b);
  if d > 180.0 then d := 360.0 - d;

  Result := d;
end;

// ===== Palette Strategy implementation (moved from inside color_from_oklch_gamut) =====
constructor TPaletteStrategy.CreateEven(aMode: palette_interp_mode_t; const colors: array of color_rgba_t; aShortest: Boolean);
var i,n: Integer;
begin
  FMode := aMode; FShortest := aShortest; FUsePositions := False; FNormalizePositions := False;
  n := Length(colors); SetLength(FColors, n); SetLength(FPositions, 0);
  for i:=0 to n-1 do FColors[i] := colors[i];
end;

constructor TPaletteStrategy.CreateWithPositions(aMode: palette_interp_mode_t; const colors: array of color_rgba_t; const positions: array of Single; aShortest: Boolean; aNormalize: Boolean);
var i,n,m: Integer;
begin
  FMode := aMode; FShortest := aShortest; FUsePositions := True; FNormalizePositions := aNormalize;
  n := Length(colors); m := Length(positions);
  SetLength(FColors, n); SetLength(FPositions, m);
  for i:=0 to n-1 do FColors[i] := colors[i];
  for i:=0 to m-1 do FPositions[i] := positions[i];
end;

class function TPaletteStrategy.CreateWithPositionsFixed(aMode: palette_interp_mode_t; const colors: array of color_rgba_t; const positions: array of Single; aShortest: Boolean; makeNonDecreasing: Boolean; normalizeTo01: Boolean): IPaletteStrategy;
var S: IPaletteStrategy;
begin
  S := TPaletteStrategy.CreateWithPositions(aMode, colors, positions, aShortest, normalizeTo01);
  if makeNonDecreasing or normalizeTo01 then S.FixupPositions(makeNonDecreasing, normalizeTo01);
  Result := S;
end;


function TPaletteStrategy.Sample(t: Single): color_rgba_t;
begin
  if (Length(FColors)=0) then Exit(COLOR_BLACK)
  else if (not FUsePositions) or (Length(FPositions)<>Length(FColors)) then
    Exit(palette_sample_multi(FColors, t, FMode, FShortest))
  else
    Exit(palette_sample_multi_with_positions(FColors, FPositions, t, FMode, FShortest, FNormalizePositions, False));
end;

function TPaletteStrategy.Serialize: string;
var i: Integer; modeStr: String; b: IStringBuilder;
begin
  // 简单 JSON（无转义），与 jsonadapter 对齐：mode 使用字符串，布尔使用 true/false
  case FMode of
    PIM_OKLCH: modeStr := '"OKLCH"';
    PIM_OKLAB: modeStr := '"OKLAB"';
    PIM_LINEAR: modeStr := '"LINEAR"';
  else
    modeStr := '"SRGB"';
  end;
  b := MakeStringBuilder(128 + Length(FColors)*10 + Length(FPositions)*8);
  b.Append('{"mode":').Append(modeStr)
   .Append(',"shortest":').Append(LowerCase(BoolToStr(FShortest, True)))
   .Append(',"usePos":').Append(LowerCase(BoolToStr(FUsePositions, True)))
   .Append(',"norm":').Append(LowerCase(BoolToStr(FNormalizePositions, True)))
   .Append(',"colors":[');
  for i:=0 to High(FColors) do begin
    if i>0 then b.Append(',');
    b.Append('"#').Append(IntToHex(FColors[i].r,2)).Append(IntToHex(FColors[i].g,2)).Append(IntToHex(FColors[i].b,2)).Append('"');
  end;
  b.Append('],"positions":[');
  for i:=0 to High(FPositions) do begin
    if i>0 then b.Append(';');
    // 固定小数点格式，强制 '.'
    b.Append(StringReplace(FormatFloat('0.############', FPositions[i]), ',', '.', [rfReplaceAll]));
  end;
  b.Append(']}');
  Result := b.ToString;
end;

function TPaletteStrategy.Mode: palette_interp_mode_t; begin Result := FMode; end;
function TPaletteStrategy.ShortestHuePath: Boolean; begin Result := FShortest; end;
function TPaletteStrategy.UsePositions: Boolean; begin Result := FUsePositions; end;
function TPaletteStrategy.NormalizePositions: Boolean; begin Result := FNormalizePositions; end;
function TPaletteStrategy.Count: Integer; begin Result := Length(FColors); end;
function TPaletteStrategy.ColorAt(i: Integer): color_rgba_t; begin Result := FColors[i]; end;
function TPaletteStrategy.PositionAt(i: Integer): Single; begin if (i>=0) and (i<Length(FPositions)) then Result := FPositions[i] else Result := 0.0; end;

function palette_strategy_deserialize(const s: string; out obj: IPaletteStrategy): Boolean;
var
  modeInt, shortestInt, usePosInt, normInt: Integer;
  colors: array of color_rgba_t;
  positions: array of Single;
  i: Integer; tmp, tok, tokU, norm, numStr: string; p1,p2: SizeInt; hasFrac: Boolean; fs: TFormatSettings;
  function TrimBr(const x: string): string;
  begin
    if (Length(x)>=2) and (x[1]='[') and (x[Length(x)]=']') then Exit(Copy(x,2,Length(x)-2));
    Result := x;
  end;
begin
  // 轻量解析（依赖格式 Serialize 输出），失败返回 False
  obj := nil; Result := False;
  // 粗糙分段（不投入完整 JSON 解析器以免增依赖）
  p1 := Pos('"mode":', s); if p1=0 then Exit; p1 := p1+7; // may be number or string
  // skip spaces
  while (p1<=Length(s)) and (s[p1] in [' ',#9,#13,#10]) do Inc(p1);
  if (p1<=Length(s)) and (s[p1] = '"') then begin
    // string mode name
    Inc(p1); p2 := p1; while (p2<=Length(s)) and (s[p2] <> '"') do Inc(p2);
    tmp := UpperCase(Copy(s, p1, p2-p1));
    if tmp = 'OKLCH' then modeInt := Ord(PIM_OKLCH)
    else if tmp = 'OKLAB' then modeInt := Ord(PIM_OKLAB)
    else if tmp = 'LINEAR' then modeInt := Ord(PIM_LINEAR)
    else modeInt := Ord(PIM_SRGB);
    // move p1 after closing quote for next searches
    p1 := p2+1;
  end else begin
    // numeric
    p2 := Pos(',', s, p1); modeInt := StrToIntDef(Copy(s, p1, p2-p1), Ord(PIM_SRGB));
  end;
  p1 := Pos('"shortest":', s); if p1=0 then Exit; p1 := p1+11; p2 := Pos(',', s, p1); tok := Trim(Copy(s, p1, p2-p1)); tokU := UpperCase(tok); if (tokU='TRUE') then shortestInt := 1 else if (tokU='FALSE') then shortestInt := 0 else shortestInt := StrToIntDef(tok, 1);
  p1 := Pos('"usePos":', s);  if p1=0 then Exit; p1 := p1+9;  p2 := Pos(',', s, p1); tok := Trim(Copy(s, p1, p2-p1)); tokU := UpperCase(tok); if (tokU='TRUE') then usePosInt := 1 else if (tokU='FALSE') then usePosInt := 0 else usePosInt := StrToIntDef(tok, 0);
  p1 := Pos('"norm":', s);     if p1=0 then Exit; p1 := p1+7;  p2 := Pos(',', s, p1); tok := Trim(Copy(s, p1, p2-p1)); tokU := UpperCase(tok); if (tokU='TRUE') then normInt := 1 else if (tokU='FALSE') then normInt := 0 else normInt := StrToIntDef(tok, 0);
  // colors 数组
  p1 := Pos('"colors":', s); if p1=0 then Exit; p1 := Pos('[', s, p1); p2 := Pos(']', s, p1);
  tmp := TrimBr(Copy(s, p1, p2-p1+1));
  if tmp<>'' then begin
    // 拆分 by ','
    SetLength(colors, 0);
    i := 1;
    while i<=Length(tmp) do begin
      // 查找引号包裹的 #RRGGBB
      if tmp[i] = '"' then begin
        Inc(i); p1 := i;
        while (i<=Length(tmp)) and (tmp[i] <> '"') do Inc(i);
        SetLength(colors, Length(colors)+1);
        // 兼容扩展 hex 形式
        colors[High(colors)] := color_from_hex_rgba(Copy(tmp, p1, i-p1));
      end;
      Inc(i);
    end;
  end;
  // positions 数组
  p1 := Pos('"positions":', s); if p1=0 then Exit; p1 := Pos('[', s, p1); p2 := Pos(']', s, p1);
  tmp := TrimBr(Copy(s, p1, p2-p1+1));
  // 归一化小数点：将位于数字之间的逗号视为小数点
  // 保持原字符串，交由下方自定义解析器同时兼容 '.' 或 ',' 作为小数点

  SetLength(positions, 0);
  if tmp<>'' then begin
    if Pos(';', tmp) > 0 then begin
      // 分号分隔，元素小数点接受 '.' 或 ','
      p1 := 1; i := 1;
      while i<=Length(tmp) do begin
        if (tmp[i]=';') or (i=Length(tmp)) then begin
          if i=Length(tmp) then p2 := i else p2 := i-1;
          numStr := Trim(Copy(tmp, p1, p2-p1+1));
          if numStr<>'' then begin
            numStr := StringReplace(numStr, ',', '.', [rfReplaceAll]);
            SetLength(positions, Length(positions)+1);
            positions[High(positions)] := StrToFloatDef(numStr, 0.0);
          end;
          p1 := i+1;
        end;
        Inc(i);
      end;
    end else begin
      // 逗号分隔，同时逗号也可能作为小数点：按“数字-逗号-数字”视为小数点，其余逗号视为分隔
      i := 1;
      while i <= Length(tmp) do begin
        // 跳过空白
        while (i<=Length(tmp)) and (tmp[i] in [' ',#9,#10,#13]) do Inc(i);
        if i>Length(tmp) then break;
        // 解析一个数
        numStr := '';
        // 可选符号
        if (tmp[i] in ['+','-']) then begin numStr += tmp[i]; Inc(i); end;
        // 整数部分
        while (i<=Length(tmp)) and (tmp[i] in ['0'..'9']) do begin numStr += tmp[i]; Inc(i); end;
        // 小数部分（'.' 或 ','）
        if (i<=Length(tmp)) and (tmp[i] in ['.',',']) and (i<Length(tmp)) and (tmp[i+1] in ['0'..'9']) then begin
          numStr += '.'; Inc(i);
          while (i<=Length(tmp)) and (tmp[i] in ['0'..'9']) do begin numStr += tmp[i]; Inc(i); end;
        end;
        // 指数部分
        if (i<=Length(tmp)) and (tmp[i] in ['e','E']) then begin
          numStr += 'e'; Inc(i);
          if (i<=Length(tmp)) and (tmp[i] in ['+','-']) then begin numStr += tmp[i]; Inc(i); end;
          while (i<=Length(tmp)) and (tmp[i] in ['0'..'9']) do begin numStr += tmp[i]; Inc(i); end;
        end;
        if numStr<>'' then begin
          SetLength(positions, Length(positions)+1);
          positions[High(positions)] := StrToFloatDef(numStr, 0.0);
        end;
        // 跳过空白与一个逗号分隔符
        while (i<=Length(tmp)) and (tmp[i] in [' ',#9,#10,#13]) do Inc(i);
        if (i<=Length(tmp)) and (tmp[i]=',') then Inc(i);
      end;
    end;
  end;
  // 构造对象
  if usePosInt<>0 then
    obj := TPaletteStrategy.CreateWithPositions(palette_interp_mode_t(modeInt), colors, positions, shortestInt<>0, normInt<>0)
  else
    obj := TPaletteStrategy.CreateEven(palette_interp_mode_t(modeInt), colors, shortestInt<>0);
  Result := True;
end;



function palette_strategy_deserialize_ex(const s: string; out obj: IPaletteStrategy; out err: string): Boolean;
var ok: Boolean; msg: string;
begin
  err := '';
  ok := palette_strategy_deserialize(s, obj);
  if not ok then begin err := 'parse failed'; Exit(False); end;
  if (obj=nil) then begin err := 'nil object'; Exit(False); end;
  if not obj.Validate(msg) then begin err := 'invalid palette: '+msg; Exit(False); end;
  Result := True;
end;


// 从 JSON-like 文本创建策略对象（失败返回 Nil）
function palette_strategy_from_text(const s: string): IPaletteStrategy;
var
  ok: Boolean;
  obj: IPaletteStrategy;
begin
  ok := palette_strategy_deserialize(s, obj);
  if ok then Result := obj else Result := nil;
end;

function palette_strategy_from_text_ex(const s: string; out obj: IPaletteStrategy; out err: string): Boolean;
begin
  Result := palette_strategy_deserialize_ex(s, obj, err);
end;










function color_rgb_to_xterm256(aR, aG, aB: UInt8): Byte;
var
  r6, g6, b6: Integer;
  maxc, minc, grayIndex: Integer;
begin
  // 与 term_rgb_to_256 保持一致：优先映射到立方体，其次近灰时映射到灰阶带
  r6 := aR * 6 div 256; if r6 > 5 then r6 := 5;
  g6 := aG * 6 div 256; if g6 > 5 then g6 := 5;



  b6 := aB * 6 div 256; if b6 > 5 then b6 := 5;
  Result := Byte(16 + (36 * r6) + (6 * g6) + b6);

  maxc := aR; if aG > maxc then maxc := aG; if aB > maxc then maxc := aB;
  minc := aR; if aG < minc then minc := aG; if aB < minc then minc := aB;
  if (maxc - minc) <= 10 then
  begin
    grayIndex := (aR + aG + aB) div 3; // 平均近似
    if grayIndex < 3 then grayIndex := 3
    else if grayIndex > 233 then grayIndex := 233;
    Result := Byte(232 + ((grayIndex - 3) div 10));
  end;
end;

function color_rgb_to_ansi16(aR, aG, aB: UInt8): Byte;
var
  idx: Integer; bright: Boolean;
begin
  // 与 term_rgb_to_16 一致的启发式：亮度阈值 + 主色判断
  bright := (aR > 127) or (aG > 127) or (aB > 127);
  if (aR >= aG) and (aR >= aB) then idx := 1 // red
  else if (aG >= aR) and (aG >= aB) then idx := 2 // green
  else idx := 4; // blue
  if (Abs(aR - aG) < 20) and (Abs(aR - aB) < 20) then
  begin
    if bright then idx := 7 else idx := 0; // white/black
  end;

  if bright then Result := Byte(idx + 8) else Result := Byte(idx);
end;

function color_xterm256_to_rgb(index: Byte): color_rgba_t;
var r6,g6,b6,code,gray: Integer;
begin
  if index < 16 then Exit(color_ansi16_to_rgb(index));
  if (index >= 232) and (index <= 255) then begin
    gray := 8 + (index - 232) * 10; // 与 rgb->xterm 的灰阶带近似一致
    Exit(color_rgba(gray, gray, gray, 255));
  end;
  code := index - 16;
  r6 := code div 36; code := code mod 36;
  g6 := code div 6;  b6 := code mod 6;
  // 将 0..5 立方体级别拉回到 0..255 的中心值（常用 0,95,135,175,215,255）
  case r6 of 0: r6:=0; 1:r6:=95; 2:r6:=135; 3:r6:=175; 4:r6:=215; else r6:=255; end;
  case g6 of 0: g6:=0; 1:g6:=95; 2:g6:=135; 3:g6:=175; 4:g6:=215; else g6:=255; end;



  case b6 of 0: b6:=0; 1:b6:=95; 2:b6:=135; 3:b6:=175; 4:b6:=215; else b6:=255; end;
  Result := color_rgba(r6, g6, b6, 255);
end;

function color_ansi16_to_rgb(index: Byte): color_rgba_t;
var base: Byte; bright: Boolean;
  function v(b: Boolean): Byte; inline; begin if b then v:=255 else v:=128; end;
begin
  bright := (index and 8)<>0;
  base := index and 7;
  case base of
    0: Result := color_rgba(0,0,0,255);
    1: Result := color_rgba(v(bright),0,0,255);
    2: Result := color_rgba(0,v(bright),0,255);
    3: Result := color_rgba(v(bright),v(bright),0,255);
    4: Result := color_rgba(0,0,v(bright),255);
    5: Result := color_rgba(v(bright),0,v(bright),255);
    6: Result := color_rgba(0,v(bright),v(bright),255);
  else
    Result := color_rgba(v(bright),v(bright),v(bright),255);
  end;
end;

// ===== Palette struct minimal facade =====
procedure palette_init_even(var p: color_palette_t; const mode: palette_interp_mode_t; const colors: array of color_rgba_t; shortestHuePath: Boolean);
var i,n: Integer;
begin
  p.mode := mode; p.shortestHuePath := shortestHuePath;
  p.normalizePositions := False; p.usePositions := False;
  n := Length(colors); SetLength(p.colors, n); SetLength(p.positions, 0);
  for i:=0 to n-1 do p.colors[i] := colors[i];
end;

procedure palette_init_with_positions(var p: color_palette_t; const mode: palette_interp_mode_t; const colors: array of color_rgba_t; const positions: array of Single; shortestHuePath: Boolean; normalizePositions: Boolean);
var i,n,m: Integer;
begin
  p.mode := mode; p.shortestHuePath := shortestHuePath;
  p.normalizePositions := normalizePositions; p.usePositions := True;
  n := Length(colors); m := Length(positions);
  SetLength(p.colors, n); SetLength(p.positions, m);
  for i:=0 to n-1 do p.colors[i] := colors[i];
  for i:=0 to m-1 do p.positions[i] := positions[i];
end;

function palette_sample_struct(const p: color_palette_t; t: Single): color_rgba_t;
begin
  if (Length(p.colors)=0) then Exit(COLOR_BLACK)
  else if (not p.usePositions) or (Length(p.positions)<>Length(p.colors)) then
    Exit(palette_sample_multi(p.colors, t, p.mode, p.shortestHuePath))
  else
    Exit(palette_sample_multi_with_positions(p.colors, p.positions, t, p.mode, p.shortestHuePath, p.normalizePositions, False));
end;

// ===== Enforced contrast helper (OKLCH L bisection) =====
function color_suggest_fg_for_bg_enforced(const bg: color_rgba_t; minRequiredContrast: Single): color_rgba_t;
var crBlack, crWhite: Single; base, best, tryc: color_rgba_t; bgLch, tryLch: color_oklch_t;
    lo, hi, mid: Single; iter: Integer; targetIsWhite: Boolean; bestCR, curCR: Single;
begin
  // 先试黑白
  crBlack := color_contrast_ratio(COLOR_BLACK, bg);
  crWhite := color_contrast_ratio(COLOR_WHITE, bg);
  if crBlack >= crWhite then begin base := COLOR_BLACK; targetIsWhite := False; best := base; bestCR := crBlack; end
  else begin base := COLOR_WHITE; targetIsWhite := True; best := base; bestCR := crWhite; end;
  if bestCR >= minRequiredContrast then Exit(best);

  // 沿 L 搜索：保持 hue（以 bg 的 hue 为参考），先选与 base 对立的一端，再朝能增大对比度方向二分
  bgLch := color_to_oklch(bg);
  tryLch := bgLch; tryLch.C := bgLch.C; // 保持 C 与 h，修改 L

  // 决定搜索方向：若 base=黑，则提升 L 往更亮找白对比；若 base=白，则降低 L 往更暗找黑对比
  if targetIsWhite then begin lo := 0.0; hi := bgLch.L; end else begin lo := bgLch.L; hi := 1.0; end;
  // 二分 20 次
  for iter := 1 to 20 do begin
    mid := (lo + hi) * 0.5;
    tryLch.L := mid;
    tryc := color_from_oklch_gamut(tryLch, GMT_PreserveHueDesaturate); // 使用默认参数保证兼容
    curCR := color_contrast_ratio(tryc, bg);
    if curCR >= minRequiredContrast then begin
      best := tryc; bestCR := curCR;
      if targetIsWhite then lo := mid else hi := mid; // 收紧继续更接近阈值一侧
    end else begin
      if targetIsWhite then hi := mid else lo := mid;
    end;



  end;
  // 若仍未达阈值，返回当前 best（保证不劣于黑白）
  Result := best;
end;


// ====== TPaletteStrategy runtime setters ======
procedure TPaletteStrategy.SetMode(aMode: palette_interp_mode_t);
begin
  FMode := aMode;
end;

procedure TPaletteStrategy.SetShortestHuePath(v: Boolean);
begin
  FShortest := v;
end;

procedure TPaletteStrategy.SetNormalizePositions(v: Boolean);
begin
  FNormalizePositions := v;
end;

procedure TPaletteStrategy.SetColors(const colors: array of color_rgba_t);
var i,n: Integer;
begin
  n := Length(colors); SetLength(FColors, n);
  for i:=0 to n-1 do FColors[i] := colors[i];
end;

procedure TPaletteStrategy.SetPositions(const positions: array of Single; normalize: Boolean);
var i,n: Integer;
begin
  n := Length(positions); SetLength(FPositions, n);
  for i:=0 to n-1 do FPositions[i] := positions[i];
  FUsePositions := n>0; FNormalizePositions := normalize;
end;


// ====== TPaletteStrategy editing helpers (moved below to avoid interleaving with unrelated code) ======
procedure TPaletteStrategy.AppendColor(const c: color_rgba_t);
begin
  SetLength(FColors, Length(FColors)+1);
  FColors[High(FColors)] := c;
end;

procedure TPaletteStrategy.InsertColor(index: Integer; const c: color_rgba_t);
var i,n: Integer;
begin
  n := Length(FColors);
  if index<0 then index := 0 else if index>n then index := n;
  SetLength(FColors, n+1);
  for i:=n downto index+1 do FColors[i] := FColors[i-1];
  FColors[index] := c;
end;

procedure TPaletteStrategy.RemoveAt(index: Integer);
var i,n: Integer;
begin
  n := Length(FColors);
  if (index<0) or (index>=n) then Exit;
  for i:=index to n-2 do FColors[i] := FColors[i+1];
  SetLength(FColors, n-1);
end;

procedure TPaletteStrategy.Clear;
begin
  SetLength(FColors, 0);
  SetLength(FPositions, 0);
  FUsePositions := False;
end;


function TPaletteStrategy.FixupPositions(makeNonDecreasing: Boolean; normalizeTo01: Boolean): Boolean;
var i: Integer; changed: Boolean; mn,mx,scale: Single;
begin
  changed := False;
  if not FUsePositions then Exit(False);
  if Length(FPositions)<>Length(FColors) then begin
    SetLength(FPositions, Length(FColors));
    for i:=0 to High(FPositions) do FPositions[i] := i;
    changed := True;
  end;
  if makeNonDecreasing then begin
    for i:=1 to High(FPositions) do
      if FPositions[i] < FPositions[i-1] then begin FPositions[i] := FPositions[i-1]; changed := True; end;
  end;
  if normalizeTo01 then begin
    if Length(FPositions)>0 then begin
      mn := FPositions[0]; mx := FPositions[0];
      for i:=1 to High(FPositions) do begin
        if FPositions[i] < mn then mn := FPositions[i];
        if FPositions[i] > mx then mx := FPositions[i];
      end;
      if mx>mn then begin
        scale := 1.0 / (mx-mn);
        for i:=0 to High(FPositions) do FPositions[i] := (FPositions[i]-mn)*scale;
        changed := True;
      end else begin
        // 所有值相同，强制两端 0..1
        for i:=0 to High(FPositions) do FPositions[i] := 0.0;
        if High(FPositions)>=0 then FPositions[High(FPositions)] := 1.0;
        changed := True;
      end;
    end;
  end;
  Result := changed;
end;

function TPaletteStrategy.Validate(out message: string): Boolean;
var i: Integer;
begin
  message := '';
  if Length(FColors)=0 then begin message := 'no colors'; Exit(False); end;
  if FUsePositions then begin
    if Length(FPositions)<>Length(FColors) then begin message := Format('positions length mismatch: %d vs %d', [Length(FPositions), Length(FColors)]); Exit(False); end;
    for i:=1 to High(FPositions) do begin
      if FPositions[i] < FPositions[i-1] then begin message := Format('positions not non-decreasing at index %d: %.6f < %.6f; consider FixupPositions(true,false)', [i, FPositions[i], FPositions[i-1]]); Exit(False); end;
    end;
  end;
  Result := True;
end;

initialization
  Build_srgb_u8_to_linear_lut;
{$ifdef FAFAFA_CORE_USE_FAST_CBRT}
  Build_linear_to_srgb_u8_lut;
{$endif}
finalization
  // nothing
end.


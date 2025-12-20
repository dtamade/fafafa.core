{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math

## Abstract 摘要

Provides a set of basic, cross-platform mathematical routines without external dependencies.
提供一组不依赖外部单元的、跨平台的基础数学函数。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

{$WARN 5023 OFF} // facade: interface uses re-exported units
uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.math.float,
  fafafa.core.math.safeint,
  fafafa.core.math.intutil,
  fafafa.core.math.dispatch,
  fafafa.core.math.array_;

const
  // Keep PI available via facade (avoid direct RTL/qualified PI usage).
  PI: Double = 3.1415926535897932384626433832795;

{**
 * IsAddOverflow
 *
 * @desc
 *   Checks whether the addition of SizeUInt values would overflow.
 *   检查 SizeUInt 加法是否会溢出.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   True if overflow would occur / 如果会溢出返回 True
 *}
function IsAddOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsAddOverflow
 *
 * @desc
 *   Checks whether the addition of UInt32 values would overflow.
 *   检查 UInt32 加法是否会溢出.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   True if overflow would occur / 如果会溢出返回 True
 *}
function IsAddOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Abs
 *
 * @desc
 *   Scalar absolute value (Double).
 *   标量绝对值（Double）。
 *   Semantics follow RTL Math.
 *}
function Abs(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Min
 *
 * @desc
 *   Returns the smaller of two Double values.
 *   返回两个 Double 中较小者（语义对齐 RTL Math）。
 *}
function Min(aA, aB: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Max
 *
 * @desc
 *   Returns the larger of two Double values.
 *   返回两个 Double 中较大者（语义对齐 RTL Math）。
 *}
function Max(aA, aB: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Clamp
 *
 * @desc
 *   Clamps x into [aMin, aMax].
 *   将 x 夹紧到 [aMin, aMax]。
 *}
function Clamp(x, aMin, aMax: Double): Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Floor
 *
 * @desc
 *   Floor(x) as Int64, semantics follow RTL Math.Floor.
 *   向下取整并返回 Int64（语义对齐 RTL Math）。
 *}
function Floor(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Ceil
 *
 * @desc
 *   Ceil(x) as Int64, semantics follow RTL Math.Ceil.
 *   向上取整并返回 Int64（语义对齐 RTL Math）。
 *}
function Ceil(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Trunc
 *
 * @desc
 *   Trunc(x) as Int64, semantics follow RTL Math.Trunc.
 *   截断取整并返回 Int64（语义对齐 RTL Math）。
 *}
function Trunc(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Round
 *
 * @desc
 *   Round(x) as Int64, semantics follow RTL Math.Round.
 *   四舍五入并返回 Int64（语义对齐 RTL Math）。
 *}
function Round(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Sqrt
 *
 * @desc
 *   Square root (Double), semantics follow RTL Math.Sqrt.
 *   平方根（语义对齐 RTL Math）。
 *}
function Sqrt(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Sqr
 *
 * @desc
 *   Square (Double).
 *   平方。
 *}
function Sqr(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Int
 *
 * @desc
 *   Integer part of x (as Double), semantics follow RTL Int.
 *   返回 x 的整数部分（Double），语义对齐 RTL Int。
 *}
function Int(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Frac
 *
 * @desc
 *   Fractional part of x (as Double), semantics follow RTL Frac.
 *   返回 x 的小数部分（Double），语义对齐 RTL Frac。
 *}
function Frac(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Sign
 *
 * @desc
 *   Returns -1, 0, or 1 depending on sign of x. NaN yields 0.
 *   返回 -1/0/1 表示符号；NaN 返回 0。
 *}
function Sign(x: Double): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IntPower
 *
 * @desc
 *   Integer exponentiation.
 *   整数指数幂。
 *}
function IntPower(aBase: Double; aExponent: Integer): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * NaN
 *
 * @desc
 *   Returns a quiet NaN value (Double).
 *   返回 quiet NaN（Double）。
 *}
function NaN: Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Infinity
 *
 * @desc
 *   Returns positive infinity (Double).
 *   返回正无穷（Double）。
 *}
function Infinity: Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * GetExceptionMask
 *
 * @desc
 *   Get current FPU exception mask.
 *   获取当前 FPU 异常屏蔽掩码。
 *}
function GetExceptionMask: TFPUExceptionMask; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SetExceptionMask
 *
 * @desc
 *   Set current FPU exception mask.
 *   设置当前 FPU 异常屏蔽掩码。
 *}
procedure SetExceptionMask(const aMask: TFPUExceptionMask); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsNaN
 *
 * @desc
 *   Check if value is Not-a-Number.
 *   检查值是否为 NaN。
 *}
function IsNaN(x: Double): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsInfinite
 *
 * @desc
 *   Check if value is positive or negative infinity.
 *   检查值是否为正无穷或负无穷。
 *}
function IsInfinite(x: Double): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Power
 *
 * @desc
 *   Raise base to the power of exponent.
 *   计算 base 的 exponent 次幂。
 *}
function Power(aBase, aExponent: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * EnsureRange
 *
 * @desc
 *   Clamp value to [aMin, aMax].
 *   将值夹紧到 [aMin, aMax] 范围。
 *}
function EnsureRange(aValue, aMin, aMax: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function EnsureRange(aValue, aMin, aMax: Int64): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function EnsureRange(aValue, aMin, aMax: Integer): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * RadToDeg
 *
 * @desc
 *   Convert radians to degrees.
 *   将弧度转换为角度。
 *}
function RadToDeg(aRadians: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * DegToRad
 *
 * @desc
 *   Convert degrees to radians.
 *   将角度转换为弧度。
 *}
function DegToRad(aDegrees: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * ArcTan2
 *
 * @desc
 *   Two-argument arctangent.
 *   双参数反正切函数。
 *}
function ArcTan2(aY, aX: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// === Trigonometric Functions ===

function Sin(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Cos(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Tan(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function ArcSin(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function ArcCos(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function ArcTan(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// === Exponential and Logarithmic Functions ===

function Exp(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Ln(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Log10(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Log2(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsSubUnderflow
 *
 * @desc
 *   Checks whether the subtraction of SizeUInt values would underflow.
 *   检查 SizeUInt 减法是否会下溢.
 *
 * @params
 *   aA - Minuend / 被减数
 *   aB - Subtrahend / 减数
 *
 * @returns
 *   True if underflow would occur (aA < aB) / 如果会下溢返回 True
 *}
function IsSubUnderflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsSubUnderflow
 *
 * @desc
 *   Checks whether the subtraction of UInt32 values would underflow.
 *   检查 UInt32 减法是否会下溢.
 *
 * @params
 *   aA - Minuend / 被减数
 *   aB - Subtrahend / 减数
 *
 * @returns
 *   True if underflow would occur (aA < aB) / 如果会下溢返回 True
 *}
function IsSubUnderflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsMulOverflow
 *
 * @desc
 *   Checks whether the multiplication of SizeUInt values would overflow.
 *   检查 SizeUInt 乘法是否会溢出.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   True if overflow would occur / 如果会溢出返回 True
 *}
function IsMulOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsMulOverflow
 *
 * @desc
 *   Checks whether the multiplication of UInt32 values would overflow.
 *   检查 UInt32 乘法是否会溢出.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   True if overflow would occur / 如果会溢出返回 True
 *}
function IsMulOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SaturatingAdd
 *
 * @desc
 *   Performs saturating addition on SizeUInt values.
 *   Returns MAX_SIZE_UINT if overflow would occur.
 *   执行 SizeUInt 饱和加法，溢出时返回 MAX_SIZE_UINT.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   Sum or MAX_SIZE_UINT if overflow / 和或溢出时返回最大值
 *}
function SaturatingAdd(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SaturatingAdd
 *
 * @desc
 *   Performs saturating addition on UInt32 values.
 *   Returns MAX_UINT32 if overflow would occur.
 *   执行 UInt32 饱和加法，溢出时返回 MAX_UINT32.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   Sum or MAX_UINT32 if overflow / 和或溢出时返回最大值
 *}
function SaturatingAdd(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SaturatingSub
 *
 * @desc
 *   Performs saturating subtraction on SizeUInt values.
 *   Returns 0 if underflow would occur.
 *   执行 SizeUInt 饱和减法，下溢时返回 0.
 *
 * @params
 *   aA - Minuend / 被减数
 *   aB - Subtrahend / 减数
 *
 * @returns
 *   Difference or 0 if underflow / 差或下溢时返回 0
 *}
function SaturatingSub(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SaturatingSub
 *
 * @desc
 *   Performs saturating subtraction on UInt32 values.
 *   Returns 0 if underflow would occur.
 *   执行 UInt32 饱和减法，下溢时返回 0.
 *
 * @params
 *   aA - Minuend / 被减数
 *   aB - Subtrahend / 减数
 *
 * @returns
 *   Difference or 0 if underflow / 差或下溢时返回 0
 *}
function SaturatingSub(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SaturatingMul
 *
 * @desc
 *   Performs saturating multiplication on SizeUInt values.
 *   Returns MAX_SIZE_UINT if overflow would occur.
 *   执行 SizeUInt 饱和乘法，溢出时返回 MAX_SIZE_UINT.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   Product or MAX_SIZE_UINT if overflow / 积或溢出时返回最大值
 *}
function SaturatingMul(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SaturatingMul
 *
 * @desc
 *   Performs saturating multiplication on UInt32 values.
 *   Returns MAX_UINT32 if overflow would occur.
 *   执行 UInt32 饱和乘法，溢出时返回 MAX_UINT32.
 *
 * @params
 *   aA - First operand / 第一个操作数
 *   aB - Second operand / 第二个操作数
 *
 * @returns
 *   Product or MAX_UINT32 if overflow / 积或溢出时返回最大值
 *}
function SaturatingMul(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// === Integer Utilities ===

{**
 * DivRoundUp
 *
 * @desc
 *   Ceiling division: (aValue + aDivisor - 1) div aDivisor.
 *   向上整除：计算 ceil(aValue / aDivisor)。
 *}
function DivRoundUp(aValue, aDivisor: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsPowerOfTwo
 *
 * @desc
 *   Check if value is a power of two (1,2,4,8,...).
 *   检查值是否为 2 的幂次（1,2,4,8,...）。
 *}
function IsPowerOfTwo(aValue: SizeUInt): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * NextPowerOfTwo
 *
 * @desc
 *   Returns the smallest power of two >= aValue.
 *   返回 >= aValue 的最小 2 的幂次。
 *}
function NextPowerOfTwo(aValue: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * AlignUp
 *
 * @desc
 *   Round up to alignment boundary (alignment must be power of 2).
 *   向上对齐到边界（对齐值必须为 2 的幂次）。
 *}
function AlignUp(aValue, aAlignment: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * AlignDown
 *
 * @desc
 *   Round down to alignment boundary (alignment must be power of 2).
 *   向下对齐到边界（对齐值必须为 2 的幂次）。
 *}
function AlignDown(aValue, aAlignment: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsAligned
 *
 * @desc
 *   Check if value is aligned to boundary (alignment must be power of 2).
 *   检查值是否对齐到边界（对齐值必须为 2 的幂次）。
 *}
function IsAligned(aValue, aAlignment: SizeUInt): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Min / Max
 *
 * @desc
 *   Basic Min/Max helpers for integer types used across fafafa.core.
 *}
function Min(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Max(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Min(aA, aB: Int64): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Max(aA, aB: Int64): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$if SizeOf(SizeInt) <> SizeOf(Int64)}
function Min(aA, aB: SizeInt): SizeInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Max(aA, aB: SizeInt): SizeInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$endif}

implementation

uses
  Math;

// === Facade Implementation ===

function IsAddOverflow(aA, aB: SizeUInt): Boolean;
begin
  Result := fafafa.core.math.safeint.IsAddOverflow(aA, aB);
end;

function IsAddOverflow(aA, aB: UInt32): Boolean;
begin
  Result := fafafa.core.math.safeint.IsAddOverflow(aA, aB);
end;

function IsSubUnderflow(aA, aB: SizeUInt): Boolean;
begin
  Result := fafafa.core.math.safeint.IsSubUnderflow(aA, aB);
end;

function IsSubUnderflow(aA, aB: UInt32): Boolean;
begin
  Result := fafafa.core.math.safeint.IsSubUnderflow(aA, aB);
end;

function IsMulOverflow(aA, aB: SizeUInt): Boolean;
begin
  Result := fafafa.core.math.safeint.IsMulOverflow(aA, aB);
end;

function IsMulOverflow(aA, aB: UInt32): Boolean;
begin
  Result := fafafa.core.math.safeint.IsMulOverflow(aA, aB);
end;

function SaturatingAdd(aA, aB: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.safeint.SaturatingAdd(aA, aB);
end;

function SaturatingAdd(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.SaturatingAdd(aA, aB);
end;

function SaturatingSub(aA, aB: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.safeint.SaturatingSub(aA, aB);
end;

function SaturatingSub(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.SaturatingSub(aA, aB);
end;

function SaturatingMul(aA, aB: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.safeint.SaturatingMul(aA, aB);
end;

function SaturatingMul(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.SaturatingMul(aA, aB);
end;

function Abs(x: Double): Double;
begin
  Result := fafafa.core.math.float.Abs(x);
end;

function Min(aA, aB: Double): Double;
begin
  Result := fafafa.core.math.float.Min(aA, aB);
end;

function Max(aA, aB: Double): Double;
begin
  Result := fafafa.core.math.float.Max(aA, aB);
end;

function Clamp(x, aMin, aMax: Double): Double;
begin
  Result := fafafa.core.math.float.Clamp(x, aMin, aMax);
end;

function Floor(x: Double): Int64;
begin
  Result := fafafa.core.math.float.Floor(x);
end;

function Ceil(x: Double): Int64;
begin
  Result := fafafa.core.math.float.Ceil(x);
end;

function Trunc(x: Double): Int64;
begin
  Result := fafafa.core.math.float.Trunc(x);
end;

function Round(x: Double): Int64;
begin
  Result := fafafa.core.math.float.Round(x);
end;

function Sqrt(x: Double): Double;
begin
  Result := fafafa.core.math.float.Sqrt(x);
end;

function Sqr(x: Double): Double;
begin
  Result := x * x;
end;

function Int(x: Double): Double;
begin
  Result := System.Int(x);
end;

function Frac(x: Double): Double;
begin
  Result := System.Frac(x);
end;

function Sign(x: Double): Integer;
begin
  if x > 0 then
    Result := 1
  else if x < 0 then
    Result := -1
  else
    Result := 0;
end;

function IntPower(aBase: Double; aExponent: Integer): Double;
var
  base: Double;
  exp: Int64;
begin
  if aExponent = 0 then
    Exit(1.0);

  if aExponent < 0 then
  begin
    base := 1.0 / aBase;
    exp := -Int64(aExponent); // handles Low(Integer) safely
  end
  else
  begin
    base := aBase;
    exp := aExponent;
  end;

  Result := 1.0;
  while exp > 0 do
  begin
    if (exp and 1) <> 0 then
      Result := Result * base;
    base := base * base;
    exp := exp shr 1;
  end;
end;

function NaN: Double;
begin
  Result := Math.NaN;
end;

function Infinity: Double;
begin
  Result := Math.Infinity;
end;

function GetExceptionMask: TFPUExceptionMask;
begin
  Result := Math.GetExceptionMask;
end;

procedure SetExceptionMask(const aMask: TFPUExceptionMask);
begin
  Math.SetExceptionMask(aMask);
end;

function IsNaN(x: Double): Boolean;
begin
  Result := fafafa.core.math.float.IsNaN(x);
end;

function IsInfinite(x: Double): Boolean;
begin
  Result := fafafa.core.math.float.IsInfinite(x);
end;

function Power(aBase, aExponent: Double): Double;
begin
  Result := fafafa.core.math.float.Power(aBase, aExponent);
end;

function EnsureRange(aValue, aMin, aMax: Double): Double;
begin
  Result := fafafa.core.math.float.EnsureRange(aValue, aMin, aMax);
end;

function EnsureRange(aValue, aMin, aMax: Int64): Int64;
begin
  Result := fafafa.core.math.float.EnsureRange(aValue, aMin, aMax);
end;

function EnsureRange(aValue, aMin, aMax: Integer): Integer;
begin
  Result := fafafa.core.math.float.EnsureRange(aValue, aMin, aMax);
end;

function RadToDeg(aRadians: Double): Double;
begin
  Result := fafafa.core.math.float.RadToDeg(aRadians);
end;

function DegToRad(aDegrees: Double): Double;
begin
  Result := fafafa.core.math.float.DegToRad(aDegrees);
end;

function ArcTan2(aY, aX: Double): Double;
begin
  Result := fafafa.core.math.float.ArcTan2(aY, aX);
end;

// === Trigonometric Functions ===

function Sin(x: Double): Double;
begin
  Result := fafafa.core.math.float.Sin(x);
end;

function Cos(x: Double): Double;
begin
  Result := fafafa.core.math.float.Cos(x);
end;

function Tan(x: Double): Double;
begin
  Result := fafafa.core.math.float.Tan(x);
end;

function ArcSin(x: Double): Double;
begin
  Result := fafafa.core.math.float.ArcSin(x);
end;

function ArcCos(x: Double): Double;
begin
  Result := fafafa.core.math.float.ArcCos(x);
end;

function ArcTan(x: Double): Double;
begin
  Result := fafafa.core.math.float.ArcTan(x);
end;

// === Exponential and Logarithmic Functions ===

function Exp(x: Double): Double;
begin
  Result := fafafa.core.math.float.Exp(x);
end;

function Ln(x: Double): Double;
begin
  Result := fafafa.core.math.float.Ln(x);
end;

function Log10(x: Double): Double;
begin
  Result := fafafa.core.math.float.Log10(x);
end;

function Log2(x: Double): Double;
begin
  Result := fafafa.core.math.float.Log2(x);
end;

// === Integer Utilities ===

function DivRoundUp(aValue, aDivisor: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.intutil.DivRoundUp(aValue, aDivisor);
end;

function IsPowerOfTwo(aValue: SizeUInt): Boolean;
begin
  Result := fafafa.core.math.intutil.IsPowerOfTwo(aValue);
end;

function NextPowerOfTwo(aValue: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.intutil.NextPowerOfTwo(aValue);
end;

function AlignUp(aValue, aAlignment: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.intutil.AlignUp(aValue, aAlignment);
end;

function AlignDown(aValue, aAlignment: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.intutil.AlignDown(aValue, aAlignment);
end;

function IsAligned(aValue, aAlignment: SizeUInt): Boolean;
begin
  Result := fafafa.core.math.intutil.IsAligned(aValue, aAlignment);
end;

// === Min / Max ===

function Min(aA, aB: SizeUInt): SizeUInt;
begin
  if aA < aB then
    Result := aA
  else
    Result := aB;
end;

function Max(aA, aB: SizeUInt): SizeUInt;
begin
  if aA > aB then
    Result := aA
  else
    Result := aB;
end;

function Min(aA, aB: Int64): Int64;
begin
  if aA < aB then
    Result := aA
  else
    Result := aB;
end;

function Max(aA, aB: Int64): Int64;
begin
  if aA > aB then
    Result := aA
  else
    Result := aB;
end;

{$if SizeOf(SizeInt) <> SizeOf(Int64)}
function Min(aA, aB: SizeInt): SizeInt;
begin
  if aA < aB then
    Result := aA
  else
    Result := aB;
end;

function Max(aA, aB: SizeInt): SizeInt;
begin
  if aA > aB then
    Result := aA
  else
    Result := aB;
end;
{$endif}

end.

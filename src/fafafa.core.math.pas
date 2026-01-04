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
  fafafa.core.math.base,  // TOptional<T>, TOverflowResult<T> types
  fafafa.core.math.float,
  fafafa.core.math.safeint,
  fafafa.core.math.intutil,
  fafafa.core.math.dispatch,
  fafafa.core.math.arrays;

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

{$IFDEF CPU64}
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
{$ENDIF}

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

{$IFDEF CPU64}
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
{$ENDIF}

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

{$IFDEF CPU64}
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
{$ENDIF}

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

{$IFDEF CPU64}
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
{$ENDIF}

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

{$IFDEF CPU64}
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
{$ENDIF}

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

{$IFDEF CPU64}
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
{$ENDIF}

// ============================================================================
// Checked Operations (Return TOptional - None on overflow)
// Rust-style checked arithmetic: returns Option<T>.
// ============================================================================

{**
 * CheckedAddU32
 *
 * @desc
 *   Checked addition that returns None on overflow.
 *   检查加法，溢出时返回 None。
 *
 * @example
 *   var result: TOptionalU32;
 *   result := CheckedAddU32(100, 50);
 *   if result.Valid then
 *     WriteLn('Sum: ', result.Value)  // 输出: Sum: 150
 *
 * @safety
 *   永不引发异常，溢出时返回 None。
 *}
function CheckedAddU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function CheckedAddU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function CheckedAddI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedNegI32(aA: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function CheckedAddI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedNegI64(aA: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Overflowing Operations (Return value + overflow flag)
// Rust-style overflowing arithmetic: returns (T, bool).
// ============================================================================

{**
 * OverflowingAddU32
 *
 * @desc
 *   Overflowing addition that returns wrapped value + overflow flag.
 *   溢出加法，返回环绕值和溢出标志。
 *
 * @example
 *   var result: TOverflowU32;
 *   result := OverflowingAddU32(High(UInt32), 1);
 *   WriteLn('Value: ', result.Value);       // 0 (环绕)
 *   WriteLn('Overflowed: ', result.Overflowed);  // True
 *}
function OverflowingAddU32(aA, aB: UInt32): TOverflowU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubU32(aA, aB: UInt32): TOverflowU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulU32(aA, aB: UInt32): TOverflowU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function OverflowingAddU64(aA, aB: UInt64): TOverflowU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubU64(aA, aB: UInt64): TOverflowU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulU64(aA, aB: UInt64): TOverflowU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function OverflowingAddI32(aA, aB: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubI32(aA, aB: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulI32(aA, aB: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingNegI32(aA: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function OverflowingAddI64(aA, aB: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubI64(aA, aB: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulI64(aA, aB: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingNegI64(aA: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Wrapping Operations (2's complement wrap, no overflow detection)
// Rust-style wrapping arithmetic: always wraps on overflow.
// ============================================================================

{**
 * WrappingAddU32
 *
 * @desc
 *   Wrapping addition using 2's complement semantics.
 *   2 补码环绕加法。
 *
 * @note
 *   这些函数禁用范围/溢出检查，总是返回环绕结果。
 *}
function WrappingAddU32(aA, aB: UInt32): UInt32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubU32(aA, aB: UInt32): UInt32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulU32(aA, aB: UInt32): UInt32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function WrappingAddU64(aA, aB: UInt64): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubU64(aA, aB: UInt64): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulU64(aA, aB: UInt64): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function WrappingAddI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingNegI32(aA: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function WrappingAddI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingNegI64(aA: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Carrying/Borrowing Operations (for multi-word arithmetic)
// Rust-style carrying arithmetic: returns (value, carry) or (value, borrow).
// ============================================================================

{**
 * CarryingAddU32
 *
 * @desc
 *   Addition with carry input and output for multi-word arithmetic.
 *   带进位输入输出的加法，用于多字算术。
 *
 * @example
 *   var low, high: TCarryResultU32;
 *   low := CarryingAddU32(a_lo, b_lo, False);
 *   high := CarryingAddU32(a_hi, b_hi, low.Carry);  // propagate carry
 *}
function CarryingAddU32(aA, aB: UInt32; aCarryIn: Boolean): TCarryResultU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function BorrowingSubU32(aA, aB: UInt32; aBorrowIn: Boolean): TCarryResultU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function CarryingAddU64(aA, aB: UInt64; aCarryIn: Boolean): TCarryResultU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function BorrowingSubU64(aA, aB: UInt64; aBorrowIn: Boolean): TCarryResultU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Widening Multiplication (no overflow possible)
// Rust-style widening multiplication: result type is 2x input width.
// ============================================================================

{**
 * WideningMulU32
 *
 * @desc
 *   Widening multiplication: UInt32 * UInt32 -> UInt64.
 *   扩展乘法：UInt32 * UInt32 -> UInt64，永不溢出。
 *
 * @example
 *   var product: UInt64;
 *   product := WideningMulU32(High(UInt32), High(UInt32));
 *   // product = 18446744065119617025 (no overflow!)
 *}
function WideningMulU32(aA, aB: UInt32): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * WideningMulU64
 *
 * @desc
 *   Widening multiplication: UInt64 * UInt64 -> TUInt128.
 *   扩展乘法：UInt64 * UInt64 -> TUInt128，永不溢出。
 *}
function WideningMulU64(aA, aB: UInt64): TUInt128; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Euclidean Division/Remainder (differs from truncated division for negatives)
// Rust-style div_euclid/rem_euclid: remainder is always non-negative.
// ============================================================================

{**
 * DivEuclidI32 / RemEuclidI32
 *
 * @desc
 *   Euclidean division where the remainder is always non-negative.
 *   For positive numbers, same as regular division.
 *   For negative dividends, differs from Pascal's truncated division.
 *   欧几里得除法，余数始终为非负数。
 *
 * @example
 *   // Regular Pascal division vs Euclidean:
 *   // -7 div 4 = -1, -7 mod 4 = -3 (Pascal truncated)
 *   // DivEuclid(-7, 4) = -2, RemEuclid(-7, 4) = 1 (Euclidean)
 *   // Invariant: a = DivEuclid(a,b) * b + RemEuclid(a,b)
 *   // And: 0 <= RemEuclid(a,b) < |b|
 *}
function DivEuclidI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function RemEuclidI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivEuclidI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedRemEuclidI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function DivEuclidI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function RemEuclidI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivEuclidI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedRemEuclidI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

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

{$IFDEF CPU64}
function IsAddOverflow(aA, aB: UInt32): Boolean;
begin
  Result := fafafa.core.math.safeint.IsAddOverflow(aA, aB);
end;
{$ENDIF}

function IsSubUnderflow(aA, aB: SizeUInt): Boolean;
begin
  Result := fafafa.core.math.safeint.IsSubUnderflow(aA, aB);
end;

{$IFDEF CPU64}
function IsSubUnderflow(aA, aB: UInt32): Boolean;
begin
  Result := fafafa.core.math.safeint.IsSubUnderflow(aA, aB);
end;
{$ENDIF}

function IsMulOverflow(aA, aB: SizeUInt): Boolean;
begin
  Result := fafafa.core.math.safeint.IsMulOverflow(aA, aB);
end;

{$IFDEF CPU64}
function IsMulOverflow(aA, aB: UInt32): Boolean;
begin
  Result := fafafa.core.math.safeint.IsMulOverflow(aA, aB);
end;
{$ENDIF}

function SaturatingAdd(aA, aB: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.safeint.SaturatingAdd(aA, aB);
end;

{$IFDEF CPU64}
function SaturatingAdd(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.SaturatingAdd(aA, aB);
end;
{$ENDIF}

function SaturatingSub(aA, aB: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.safeint.SaturatingSub(aA, aB);
end;

{$IFDEF CPU64}
function SaturatingSub(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.SaturatingSub(aA, aB);
end;
{$ENDIF}

function SaturatingMul(aA, aB: SizeUInt): SizeUInt;
begin
  Result := fafafa.core.math.safeint.SaturatingMul(aA, aB);
end;

{$IFDEF CPU64}
function SaturatingMul(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.SaturatingMul(aA, aB);
end;
{$ENDIF}

// ============================================================================
// Checked Operations
// ============================================================================

function CheckedAddU32(aA, aB: UInt32): TOptionalU32;
begin
  Result := fafafa.core.math.safeint.CheckedAddU32(aA, aB);
end;

function CheckedSubU32(aA, aB: UInt32): TOptionalU32;
begin
  Result := fafafa.core.math.safeint.CheckedSubU32(aA, aB);
end;

function CheckedMulU32(aA, aB: UInt32): TOptionalU32;
begin
  Result := fafafa.core.math.safeint.CheckedMulU32(aA, aB);
end;

function CheckedDivU32(aA, aB: UInt32): TOptionalU32;
begin
  Result := fafafa.core.math.safeint.CheckedDivU32(aA, aB);
end;

function CheckedAddU64(aA, aB: UInt64): TOptionalU64;
begin
  Result := fafafa.core.math.safeint.CheckedAddU64(aA, aB);
end;

function CheckedSubU64(aA, aB: UInt64): TOptionalU64;
begin
  Result := fafafa.core.math.safeint.CheckedSubU64(aA, aB);
end;

function CheckedMulU64(aA, aB: UInt64): TOptionalU64;
begin
  Result := fafafa.core.math.safeint.CheckedMulU64(aA, aB);
end;

function CheckedDivU64(aA, aB: UInt64): TOptionalU64;
begin
  Result := fafafa.core.math.safeint.CheckedDivU64(aA, aB);
end;

function CheckedAddI32(aA, aB: Int32): TOptionalI32;
begin
  Result := fafafa.core.math.safeint.CheckedAddI32(aA, aB);
end;

function CheckedSubI32(aA, aB: Int32): TOptionalI32;
begin
  Result := fafafa.core.math.safeint.CheckedSubI32(aA, aB);
end;

function CheckedMulI32(aA, aB: Int32): TOptionalI32;
begin
  Result := fafafa.core.math.safeint.CheckedMulI32(aA, aB);
end;

function CheckedDivI32(aA, aB: Int32): TOptionalI32;
begin
  Result := fafafa.core.math.safeint.CheckedDivI32(aA, aB);
end;

function CheckedNegI32(aA: Int32): TOptionalI32;
begin
  Result := fafafa.core.math.safeint.CheckedNegI32(aA);
end;

function CheckedAddI64(aA, aB: Int64): TOptionalI64;
begin
  Result := fafafa.core.math.safeint.CheckedAddI64(aA, aB);
end;

function CheckedSubI64(aA, aB: Int64): TOptionalI64;
begin
  Result := fafafa.core.math.safeint.CheckedSubI64(aA, aB);
end;

function CheckedMulI64(aA, aB: Int64): TOptionalI64;
begin
  Result := fafafa.core.math.safeint.CheckedMulI64(aA, aB);
end;

function CheckedDivI64(aA, aB: Int64): TOptionalI64;
begin
  Result := fafafa.core.math.safeint.CheckedDivI64(aA, aB);
end;

function CheckedNegI64(aA: Int64): TOptionalI64;
begin
  Result := fafafa.core.math.safeint.CheckedNegI64(aA);
end;

// ============================================================================
// Overflowing Operations
// ============================================================================

function OverflowingAddU32(aA, aB: UInt32): TOverflowU32;
begin
  Result := fafafa.core.math.safeint.OverflowingAddU32(aA, aB);
end;

function OverflowingSubU32(aA, aB: UInt32): TOverflowU32;
begin
  Result := fafafa.core.math.safeint.OverflowingSubU32(aA, aB);
end;

function OverflowingMulU32(aA, aB: UInt32): TOverflowU32;
begin
  Result := fafafa.core.math.safeint.OverflowingMulU32(aA, aB);
end;

function OverflowingAddU64(aA, aB: UInt64): TOverflowU64;
begin
  Result := fafafa.core.math.safeint.OverflowingAddU64(aA, aB);
end;

function OverflowingSubU64(aA, aB: UInt64): TOverflowU64;
begin
  Result := fafafa.core.math.safeint.OverflowingSubU64(aA, aB);
end;

function OverflowingMulU64(aA, aB: UInt64): TOverflowU64;
begin
  Result := fafafa.core.math.safeint.OverflowingMulU64(aA, aB);
end;

function OverflowingAddI32(aA, aB: Int32): TOverflowI32;
begin
  Result := fafafa.core.math.safeint.OverflowingAddI32(aA, aB);
end;

function OverflowingSubI32(aA, aB: Int32): TOverflowI32;
begin
  Result := fafafa.core.math.safeint.OverflowingSubI32(aA, aB);
end;

function OverflowingMulI32(aA, aB: Int32): TOverflowI32;
begin
  Result := fafafa.core.math.safeint.OverflowingMulI32(aA, aB);
end;

function OverflowingNegI32(aA: Int32): TOverflowI32;
begin
  Result := fafafa.core.math.safeint.OverflowingNegI32(aA);
end;

function OverflowingAddI64(aA, aB: Int64): TOverflowI64;
begin
  Result := fafafa.core.math.safeint.OverflowingAddI64(aA, aB);
end;

function OverflowingSubI64(aA, aB: Int64): TOverflowI64;
begin
  Result := fafafa.core.math.safeint.OverflowingSubI64(aA, aB);
end;

function OverflowingMulI64(aA, aB: Int64): TOverflowI64;
begin
  Result := fafafa.core.math.safeint.OverflowingMulI64(aA, aB);
end;

function OverflowingNegI64(aA: Int64): TOverflowI64;
begin
  Result := fafafa.core.math.safeint.OverflowingNegI64(aA);
end;

// ============================================================================
// Wrapping Operations
// ============================================================================

function WrappingAddU32(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.WrappingAddU32(aA, aB);
end;

function WrappingSubU32(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.WrappingSubU32(aA, aB);
end;

function WrappingMulU32(aA, aB: UInt32): UInt32;
begin
  Result := fafafa.core.math.safeint.WrappingMulU32(aA, aB);
end;

function WrappingAddU64(aA, aB: UInt64): UInt64;
begin
  Result := fafafa.core.math.safeint.WrappingAddU64(aA, aB);
end;

function WrappingSubU64(aA, aB: UInt64): UInt64;
begin
  Result := fafafa.core.math.safeint.WrappingSubU64(aA, aB);
end;

function WrappingMulU64(aA, aB: UInt64): UInt64;
begin
  Result := fafafa.core.math.safeint.WrappingMulU64(aA, aB);
end;

function WrappingAddI32(aA, aB: Int32): Int32;
begin
  Result := fafafa.core.math.safeint.WrappingAddI32(aA, aB);
end;

function WrappingSubI32(aA, aB: Int32): Int32;
begin
  Result := fafafa.core.math.safeint.WrappingSubI32(aA, aB);
end;

function WrappingMulI32(aA, aB: Int32): Int32;
begin
  Result := fafafa.core.math.safeint.WrappingMulI32(aA, aB);
end;

function WrappingNegI32(aA: Int32): Int32;
begin
  Result := fafafa.core.math.safeint.WrappingNegI32(aA);
end;

function WrappingAddI64(aA, aB: Int64): Int64;
begin
  Result := fafafa.core.math.safeint.WrappingAddI64(aA, aB);
end;

function WrappingSubI64(aA, aB: Int64): Int64;
begin
  Result := fafafa.core.math.safeint.WrappingSubI64(aA, aB);
end;

function WrappingMulI64(aA, aB: Int64): Int64;
begin
  Result := fafafa.core.math.safeint.WrappingMulI64(aA, aB);
end;

function WrappingNegI64(aA: Int64): Int64;
begin
  Result := fafafa.core.math.safeint.WrappingNegI64(aA);
end;

// ============================================================================
// Carrying/Borrowing Operations
// ============================================================================

function CarryingAddU32(aA, aB: UInt32; aCarryIn: Boolean): TCarryResultU32;
begin
  Result := fafafa.core.math.safeint.CarryingAddU32(aA, aB, aCarryIn);
end;

function BorrowingSubU32(aA, aB: UInt32; aBorrowIn: Boolean): TCarryResultU32;
begin
  Result := fafafa.core.math.safeint.BorrowingSubU32(aA, aB, aBorrowIn);
end;

function CarryingAddU64(aA, aB: UInt64; aCarryIn: Boolean): TCarryResultU64;
begin
  Result := fafafa.core.math.safeint.CarryingAddU64(aA, aB, aCarryIn);
end;

function BorrowingSubU64(aA, aB: UInt64; aBorrowIn: Boolean): TCarryResultU64;
begin
  Result := fafafa.core.math.safeint.BorrowingSubU64(aA, aB, aBorrowIn);
end;

// ============================================================================
// Widening Multiplication
// ============================================================================

function WideningMulU32(aA, aB: UInt32): UInt64;
begin
  Result := fafafa.core.math.safeint.WideningMulU32(aA, aB);
end;

function WideningMulU64(aA, aB: UInt64): TUInt128;
begin
  Result := fafafa.core.math.safeint.WideningMulU64(aA, aB);
end;

// ============================================================================
// Euclidean Division/Remainder
// ============================================================================

function DivEuclidI32(aA, aB: Int32): Int32;
begin
  Result := fafafa.core.math.safeint.DivEuclidI32(aA, aB);
end;

function RemEuclidI32(aA, aB: Int32): Int32;
begin
  Result := fafafa.core.math.safeint.RemEuclidI32(aA, aB);
end;

function CheckedDivEuclidI32(aA, aB: Int32): TOptionalI32;
begin
  Result := fafafa.core.math.safeint.CheckedDivEuclidI32(aA, aB);
end;

function CheckedRemEuclidI32(aA, aB: Int32): TOptionalI32;
begin
  Result := fafafa.core.math.safeint.CheckedRemEuclidI32(aA, aB);
end;

function DivEuclidI64(aA, aB: Int64): Int64;
begin
  Result := fafafa.core.math.safeint.DivEuclidI64(aA, aB);
end;

function RemEuclidI64(aA, aB: Int64): Int64;
begin
  Result := fafafa.core.math.safeint.RemEuclidI64(aA, aB);
end;

function CheckedDivEuclidI64(aA, aB: Int64): TOptionalI64;
begin
  Result := fafafa.core.math.safeint.CheckedDivEuclidI64(aA, aB);
end;

function CheckedRemEuclidI64(aA, aB: Int64): TOptionalI64;
begin
  Result := fafafa.core.math.safeint.CheckedRemEuclidI64(aA, aB);
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

{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.safeint

## Abstract 摘要

Safe integer arithmetic operations inspired by Rust std::num.
Provides overflow detection, saturating, checked, overflowing, and wrapping operations.
安全整数算术运算，灵感来自 Rust std::num。
提供溢出检测、饱和、检查、溢出和环绕操作。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.safeint;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

// Disable range/overflow checks for intentional wrapping operations
{$PUSH}
{$R-}
{$Q-}

interface

uses
  fafafa.core.base,
  fafafa.core.math.base;

// ============================================================================
// Overflow/Underflow Detection
// 溢出/下溢检测
// ============================================================================
{**
 * IsAddOverflow / IsSubUnderflow / IsMulOverflow
 *
 * @desc
 *   Predicate functions that check if an arithmetic operation would overflow.
 *   谓词函数，检查算术运算是否会溢出。
 *
 * @example
 *   // Check before performing operation
 *   // 在执行操作前检查
 *   if not IsAddOverflow(a, b) then
 *     result := a + b
 *   else
 *     HandleOverflow;
 *
 *   // Guard allocation size calculation
 *   // 保护分配大小计算
 *   if IsMulOverflow(count, SizeOf(TElement)) then
 *     raise EOutOfMemory.Create('Allocation size overflow');
 *
 * @safety
 *   - 永不引发异常 / Never raises exceptions
 *   - 纯函数，无副作用 / Pure function, no side effects
 *   - 无符号类型使用 IsSubUnderflow，有符号类型使用 IsSubOverflow
 *     Unsigned types use IsSubUnderflow, signed types use IsSubOverflow
 *
 * @perf
 *   O(1)，1-3 条指令 / 1-3 instructions
 *}

// --- UInt8 ---
function IsAddOverflow(aA, aB: UInt8): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubUnderflow(aA, aB: UInt8): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: UInt8): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt16 ---
function IsAddOverflow(aA, aB: UInt16): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubUnderflow(aA, aB: UInt16): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: UInt16): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt32 ---
function IsAddOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubUnderflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt64 ---
function IsAddOverflow(aA, aB: UInt64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubUnderflow(aA, aB: UInt64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: UInt64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeUInt --- (only on 32-bit where SizeUInt != UInt64)
{$IFNDEF CPU64}
function IsAddOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubUnderflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

// --- Int8 ---
function IsAddOverflow(aA, aB: Int8): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubOverflow(aA, aB: Int8): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: Int8): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int16 ---
function IsAddOverflow(aA, aB: Int16): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubOverflow(aA, aB: Int16): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: Int16): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int32 ---
function IsAddOverflow(aA, aB: Int32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubOverflow(aA, aB: Int32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: Int32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int64 ---
function IsAddOverflow(aA, aB: Int64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubOverflow(aA, aB: Int64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: Int64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeInt --- (only on 32-bit where SizeInt != Int64)
{$IFNDEF CPU64}
function IsAddOverflow(aA, aB: SizeInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubOverflow(aA, aB: SizeInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: SizeInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

// ============================================================================
// Saturating Operations (Clamp at Min/Max on overflow)
// 饱和运算（溢出时钳位到最小/最大值）
// ============================================================================
{**
 * SaturatingAdd / SaturatingSub / SaturatingMul
 *
 * @desc
 *   Saturating arithmetic: clamps result to type bounds instead of wrapping.
 *   On overflow → returns MAX; on underflow → returns MIN (or 0 for unsigned).
 *   饱和算术：溢出时钳位到类型边界而非环绕。
 *   溢出时返回 MAX；下溢时返回 MIN（无符号类型返回 0）。
 *
 * @example
 *   // Safe pixel arithmetic (no wrap-around artifacts)
 *   // 安全像素运算（无环绕伪影）
 *   var brightness: UInt8 := SaturatingAdd(pixel, UInt8(50));
 *   // 200 + 50 = 250 ✓
 *   // 220 + 50 = 255 (saturated, not 14)
 *
 *   // Safe audio sample mixing
 *   // 安全音频采样混合
 *   var mixed: Int16 := SaturatingAdd(sample1, sample2);
 *   // Prevents clipping artifacts from wrap-around
 *
 *   // Safe counter increment
 *   // 安全计数器递增
 *   retryCount := SaturatingAdd(retryCount, UInt32(1));
 *   // Stays at MAX_UINT32 instead of wrapping to 0
 *
 * @safety
 *   - 永不引发异常 / Never raises exceptions
 *   - 永不产生未定义行为 / Never causes undefined behavior
 *   - 结果始终在类型有效范围内 / Result always within valid type range
 *   - 适用于需要有界结果的场景 / Use when bounded results are required
 *
 * @perf
 *   O(1)，3-5 条指令（含条件分支）
 *   O(1), 3-5 instructions (with conditional branch)
 *
 * @rust_equiv
 *   u32::saturating_add, i32::saturating_sub, etc.
 *}

// --- UInt8 ---
function SaturatingAdd(aA, aB: UInt8): UInt8; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: UInt8): UInt8; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: UInt8): UInt8; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt16 ---
function SaturatingAdd(aA, aB: UInt16): UInt16; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: UInt16): UInt16; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: UInt16): UInt16; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt32 ---
function SaturatingAdd(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt64 ---
function SaturatingAdd(aA, aB: UInt64): UInt64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: UInt64): UInt64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: UInt64): UInt64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeUInt --- (only on 32-bit where SizeUInt != UInt64)
{$IFNDEF CPU64}
function SaturatingAdd(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

// --- Int8 ---
function SaturatingAdd(aA, aB: Int8): Int8; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: Int8): Int8; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: Int8): Int8; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int16 ---
function SaturatingAdd(aA, aB: Int16): Int16; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: Int16): Int16; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: Int16): Int16; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int32 ---
function SaturatingAdd(aA, aB: Int32): Int32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: Int32): Int32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: Int32): Int32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int64 ---
function SaturatingAdd(aA, aB: Int64): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: Int64): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: Int64): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeInt --- (only on 32-bit where SizeInt != Int64)
{$IFNDEF CPU64}
function SaturatingAdd(aA, aB: SizeInt): SizeInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: SizeInt): SizeInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: SizeInt): SizeInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

// ============================================================================
// Checked Operations (Return TOptional - None on overflow)
// 检查运算（返回 TOptional - 溢出时返回 None）
// ============================================================================
{**
 * CheckedAddXX / CheckedSubXX / CheckedMulXX / CheckedDivXX / CheckedNegXX
 *
 * @desc
 *   Checked arithmetic: returns TOptional with Valid=False on overflow/error.
 *   Equivalent to Rust's checked_add(), checked_sub(), etc.
 *   检查算术：溢出或错误时返回 Valid=False 的 TOptional。
 *   等价于 Rust 的 checked_add()、checked_sub() 等。
 *
 * @example
 *   // Safe addition with explicit error handling
 *   // 带显式错误处理的安全加法
 *   var result: TOptionalU32 := CheckedAddU32(a, b);
 *   if result.Valid then
 *     WriteLn('Sum: ', result.Value)
 *   else
 *     WriteLn('Overflow detected!');
 *
 *   // Using UnwrapOr for default value on overflow
 *   // 溢出时使用 UnwrapOr 提供默认值
 *   var sum: UInt32 := CheckedAddU32(a, b).UnwrapOr(0);
 *
 *   // Chain operations with early exit
 *   // 链式操作提前退出
 *   result := CheckedMulU32(width, height);
 *   if not result.Valid then Exit(False);
 *   result := CheckedMulU32(result.Value, depth);
 *   if not result.Valid then Exit(False);
 *
 *   // Division by zero returns None (not exception)
 *   // 除零返回 None（非异常）
 *   var quotient: TOptionalU32 := CheckedDivU32(10, 0);
 *   // quotient.Valid = False
 *
 *   // Negation of MIN_INT returns None (no positive representation)
 *   // 对 MIN_INT 取反返回 None（无正数表示）
 *   var negated: TOptionalI32 := CheckedNegI32(MIN_INT32);
 *   // negated.Valid = False
 *
 * @safety
 *   - 永不引发异常 / Never raises exceptions
 *   - 除零返回 None 而非 EDivByZero / Division by zero returns None, not EDivByZero
 *   - CheckedNegI32(MIN_INT32) 返回 None / CheckedNegI32(MIN_INT32) returns None
 *   - CheckedDivI32(MIN_INT32, -1) 返回 None / CheckedDivI32(MIN_INT32, -1) returns None
 *   - 推荐用于需要精确溢出处理的场景 / Recommended when precise overflow handling needed
 *
 * @perf
 *   O(1)，2-4 条指令（含溢出检测）
 *   O(1), 2-4 instructions (with overflow detection)
 *
 * @rust_equiv
 *   u32::checked_add, i32::checked_neg, etc.
 *}

// --- UInt8 ---
function CheckedAddU8(aA, aB: UInt8): TOptionalU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubU8(aA, aB: UInt8): TOptionalU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulU8(aA, aB: UInt8): TOptionalU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivU8(aA, aB: UInt8): TOptionalU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt16 ---
function CheckedAddU16(aA, aB: UInt16): TOptionalU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubU16(aA, aB: UInt16): TOptionalU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulU16(aA, aB: UInt16): TOptionalU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivU16(aA, aB: UInt16): TOptionalU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt32 ---
function CheckedAddU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivU32(aA, aB: UInt32): TOptionalU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt64 ---
function CheckedAddU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivU64(aA, aB: UInt64): TOptionalU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeUInt ---
function CheckedAddSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int8 ---
function CheckedAddI8(aA, aB: Int8): TOptionalI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubI8(aA, aB: Int8): TOptionalI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulI8(aA, aB: Int8): TOptionalI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivI8(aA, aB: Int8): TOptionalI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedNegI8(aA: Int8): TOptionalI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int16 ---
function CheckedAddI16(aA, aB: Int16): TOptionalI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubI16(aA, aB: Int16): TOptionalI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulI16(aA, aB: Int16): TOptionalI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivI16(aA, aB: Int16): TOptionalI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedNegI16(aA: Int16): TOptionalI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int32 ---
function CheckedAddI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedNegI32(aA: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int64 ---
function CheckedAddI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedNegI64(aA: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeInt ---
function CheckedAddSizeInt(aA, aB: SizeInt): TOptionalSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedSubSizeInt(aA, aB: SizeInt): TOptionalSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedMulSizeInt(aA, aB: SizeInt): TOptionalSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivSizeInt(aA, aB: SizeInt): TOptionalSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedNegSizeInt(aA: SizeInt): TOptionalSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Overflowing Operations (Return value + overflow flag)
// 溢出运算（返回值 + 溢出标志）
// ============================================================================
{**
 * OverflowingAddXX / OverflowingSubXX / OverflowingMulXX / OverflowingNegXX
 *
 * @desc
 *   Returns both the wrapped result AND an overflow flag.
 *   Use when you need the wrapped value even on overflow.
 *   Equivalent to Rust's overflowing_add(), etc.
 *   返回环绕结果和溢出标志。
 *   用于即使溢出也需要环绕值的场景。
 *   等价于 Rust 的 overflowing_add() 等。
 *
 * @example
 *   // Get wrapped result + know if overflow occurred
 *   // 获取环绕结果 + 知道是否发生溢出
 *   var res: TOverflowU32 := OverflowingAddU32(MAX_UINT32, 1);
 *   // res.Value = 0, res.Overflowed = True
 *
 *   // Implement multi-word arithmetic
 *   // 实现多字算术
 *   var low: TOverflowU64 := OverflowingAddU64(a.Lo, b.Lo);
 *   var high: UInt64 := a.Hi + b.Hi;
 *   if low.Overflowed then
 *     Inc(high);  // Propagate carry
 *
 *   // Timing-safe comparison (constant-time)
 *   // 时序安全比较（常量时间）
 *   var diff: TOverflowU32 := OverflowingSubU32(a, b);
 *   // Use diff.Overflowed in constant-time logic
 *
 * @safety
 *   - 永不引发异常 / Never raises exceptions
 *   - 溢出时 Value 为二补码环绕值 / Value is 2's complement wrap on overflow
 *   - Overflowed 标志精确指示溢出 / Overflowed flag precisely indicates overflow
 *   - 适用于密码学等需要溢出信息的场景 / Use in crypto where overflow info needed
 *
 * @perf
 *   O(1)，2-3 条指令
 *   O(1), 2-3 instructions
 *
 * @rust_equiv
 *   u32::overflowing_add, i32::overflowing_neg, etc.
 *}

// --- UInt8 ---
function OverflowingAddU8(aA, aB: UInt8): TOverflowU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubU8(aA, aB: UInt8): TOverflowU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulU8(aA, aB: UInt8): TOverflowU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt16 ---
function OverflowingAddU16(aA, aB: UInt16): TOverflowU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubU16(aA, aB: UInt16): TOverflowU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulU16(aA, aB: UInt16): TOverflowU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt32 ---
function OverflowingAddU32(aA, aB: UInt32): TOverflowU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubU32(aA, aB: UInt32): TOverflowU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulU32(aA, aB: UInt32): TOverflowU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt64 ---
function OverflowingAddU64(aA, aB: UInt64): TOverflowU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubU64(aA, aB: UInt64): TOverflowU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulU64(aA, aB: UInt64): TOverflowU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeUInt ---
function OverflowingAddSizeUInt(aA, aB: SizeUInt): TOverflowSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubSizeUInt(aA, aB: SizeUInt): TOverflowSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulSizeUInt(aA, aB: SizeUInt): TOverflowSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int8 ---
function OverflowingAddI8(aA, aB: Int8): TOverflowI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubI8(aA, aB: Int8): TOverflowI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulI8(aA, aB: Int8): TOverflowI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingNegI8(aA: Int8): TOverflowI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int16 ---
function OverflowingAddI16(aA, aB: Int16): TOverflowI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubI16(aA, aB: Int16): TOverflowI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulI16(aA, aB: Int16): TOverflowI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingNegI16(aA: Int16): TOverflowI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int32 ---
function OverflowingAddI32(aA, aB: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubI32(aA, aB: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulI32(aA, aB: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingNegI32(aA: Int32): TOverflowI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int64 ---
function OverflowingAddI64(aA, aB: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubI64(aA, aB: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulI64(aA, aB: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingNegI64(aA: Int64): TOverflowI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeInt ---
function OverflowingAddSizeInt(aA, aB: SizeInt): TOverflowSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingSubSizeInt(aA, aB: SizeInt): TOverflowSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingMulSizeInt(aA, aB: SizeInt): TOverflowSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function OverflowingNegSizeInt(aA: SizeInt): TOverflowSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Wrapping Operations (2's complement wrap, no overflow detection)
// 环绕运算（二补码环绕，无溢出检测）
// ============================================================================
{**
 * WrappingAddXX / WrappingSubXX / WrappingMulXX / WrappingNegXX
 *
 * @desc
 *   Intentional 2's complement wrapping without overflow detection.
 *   Use when wrapping behavior is desired (e.g., hash functions, checksums).
 *   Equivalent to Rust's wrapping_add(), etc.
 *   有意的二补码环绕，无溢出检测。
 *   用于需要环绕行为的场景（如哈希函数、校验和）。
 *   等价于 Rust 的 wrapping_add() 等。
 *
 * @example
 *   // Hash function with intentional wrapping
 *   // 有意环绕的哈希函数
 *   function SimpleHash(const s: string): UInt32;
 *   var i: Integer;
 *   begin
 *     Result := 0;
 *     for i := 1 to Length(s) do
 *       Result := WrappingAddU32(WrappingMulU32(Result, 31), Ord(s[i]));
 *   end;
 *
 *   // Checksum calculation
 *   // 校验和计算
 *   var checksum: UInt16 := 0;
 *   for i := 0 to Length(data) - 1 do
 *     checksum := WrappingAddU16(checksum, data[i]);
 *
 *   // Timer difference (handles wrap-around)
 *   // 计时器差值（处理环绕）
 *   var elapsed: UInt32 := WrappingSubU32(nowTicks, startTicks);
 *   // Works correctly even when nowTicks < startTicks due to wrap
 *
 * @safety
 *   - 永不引发异常 / Never raises exceptions
 *   - 行为与 C/C++ 无符号算术相同 / Same behavior as C/C++ unsigned arithmetic
 *   - 对有符号类型：行为与 $Q- 编译指令下的 Pascal 相同
 *     For signed types: same as Pascal with $Q- directive
 *   - 仅在需要环绕语义时使用 / Only use when wrapping semantics needed
 *
 * @perf
 *   O(1)，1 条指令（最快的安全整数操作）
 *   O(1), 1 instruction (fastest safe integer operation)
 *
 * @rust_equiv
 *   u32::wrapping_add, i32::wrapping_neg, etc.
 *}

// --- UInt8 ---
function WrappingAddU8(aA, aB: UInt8): UInt8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubU8(aA, aB: UInt8): UInt8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulU8(aA, aB: UInt8): UInt8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt16 ---
function WrappingAddU16(aA, aB: UInt16): UInt16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubU16(aA, aB: UInt16): UInt16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulU16(aA, aB: UInt16): UInt16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt32 ---
function WrappingAddU32(aA, aB: UInt32): UInt32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubU32(aA, aB: UInt32): UInt32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulU32(aA, aB: UInt32): UInt32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt64 ---
function WrappingAddU64(aA, aB: UInt64): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubU64(aA, aB: UInt64): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulU64(aA, aB: UInt64): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeUInt ---
function WrappingAddSizeUInt(aA, aB: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubSizeUInt(aA, aB: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulSizeUInt(aA, aB: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int8 ---
function WrappingAddI8(aA, aB: Int8): Int8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubI8(aA, aB: Int8): Int8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulI8(aA, aB: Int8): Int8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingNegI8(aA: Int8): Int8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int16 ---
function WrappingAddI16(aA, aB: Int16): Int16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubI16(aA, aB: Int16): Int16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulI16(aA, aB: Int16): Int16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingNegI16(aA: Int16): Int16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int32 ---
function WrappingAddI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingNegI32(aA: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int64 ---
function WrappingAddI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingNegI64(aA: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeInt ---
function WrappingAddSizeInt(aA, aB: SizeInt): SizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingSubSizeInt(aA, aB: SizeInt): SizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingMulSizeInt(aA, aB: SizeInt): SizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WrappingNegSizeInt(aA: SizeInt): SizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Carrying/Borrowing Operations (for multi-word arithmetic)
// 进位/借位运算（用于多字算术）
// ============================================================================
{**
 * CarryingAddXX / BorrowingSubXX
 *
 * @desc
 *   Arithmetic with carry/borrow propagation for implementing multi-word integers.
 *   Returns both the result and the carry/borrow flag for chaining operations.
 *   带进位/借位传播的算术运算，用于实现多字整数。
 *   返回结果和进位/借位标志，便于链式操作。
 *
 * @example
 *   // Multi-word addition: low + low with carry propagation
 *   // 多字加法：低位 + 低位 带进位传播
 *   var low: TCarryResultU64 := CarryingAddU64(a.Lo, b.Lo, False);
 *   var high: UInt64 := a.Hi + b.Hi;
 *   if low.Carry then Inc(high);
 *
 *   // Chained carry: a + b + c with full carry chain
 *   // 链式进位：a + b + c 完整进位链
 *   var r1: TCarryResultU32 := CarryingAddU32(a, b, False);
 *   var r2: TCarryResultU32 := CarryingAddU32(r1.Value, c, r1.Carry);
 *   // r2.Carry indicates overall overflow
 *
 * @safety
 *   - 永不引发异常 / Never raises exceptions
 *   - Carry 标志精确指示是否产生进位 / Carry flag precisely indicates carry
 *   - 适用于大整数实现 / Use for big integer implementations
 *
 * @perf
 *   O(1)，2-3 条指令
 *   O(1), 2-3 instructions
 *
 * @rust_equiv
 *   u32::carrying_add, u64::borrowing_sub
 *}

// --- UInt8 ---
function CarryingAddU8(aA, aB: UInt8; aCarryIn: Boolean): TCarryResultU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function BorrowingSubU8(aA, aB: UInt8; aBorrowIn: Boolean): TCarryResultU8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt16 ---
function CarryingAddU16(aA, aB: UInt16; aCarryIn: Boolean): TCarryResultU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function BorrowingSubU16(aA, aB: UInt16; aBorrowIn: Boolean): TCarryResultU16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt32 ---
function CarryingAddU32(aA, aB: UInt32; aCarryIn: Boolean): TCarryResultU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function BorrowingSubU32(aA, aB: UInt32; aBorrowIn: Boolean): TCarryResultU32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- UInt64 ---
function CarryingAddU64(aA, aB: UInt64; aCarryIn: Boolean): TCarryResultU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function BorrowingSubU64(aA, aB: UInt64; aBorrowIn: Boolean): TCarryResultU64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeUInt ---
function CarryingAddSizeUInt(aA, aB: SizeUInt; aCarryIn: Boolean): TCarryResultSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function BorrowingSubSizeUInt(aA, aB: SizeUInt; aBorrowIn: Boolean): TCarryResultSizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Widening Multiplication (no overflow possible)
// 扩展宽度乘法（不可能溢出）
// ============================================================================
{**
 * WideningMulXX
 *
 * @desc
 *   Widening multiplication: multiply two N-bit integers to produce a 2N-bit result.
 *   This operation can never overflow since the result type is large enough.
 *   扩展乘法：将两个 N 位整数相乘产生 2N 位结果。
 *   此操作永不溢出，因为结果类型足够大。
 *
 * @example
 *   // Multiply two 32-bit values to get 64-bit result
 *   // 将两个 32 位值相乘得到 64 位结果
 *   var product: UInt64 := WideningMulU32(High(UInt32), High(UInt32));
 *   // product = 18446744065119617025 (no overflow!)
 *
 *   // Multiply two 64-bit values to get 128-bit result
 *   // 将两个 64 位值相乘得到 128 位结果
 *   var big: TUInt128 := WideningMulU64(High(UInt64), 2);
 *   // big.Hi = 1, big.Lo = High(UInt64) - 1
 *
 * @safety
 *   - 永不引发异常 / Never raises exceptions
 *   - 永不溢出 / Never overflows
 *   - 结果类型保证容纳所有可能值 / Result type guaranteed to hold all possible values
 *
 * @perf
 *   O(1)，1-2 条指令（利用硬件乘法）
 *   O(1), 1-2 instructions (uses hardware multiply)
 *
 * @rust_equiv
 *   u32::widening_mul, u64::widening_mul
 *}

function WideningMulU8(aA, aB: UInt8): UInt16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WideningMulU16(aA, aB: UInt16): UInt32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WideningMulU32(aA, aB: UInt32): UInt64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function WideningMulU64(aA, aB: UInt64): TUInt128; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Euclidean Division/Remainder (differs from truncated division for negatives)
// 欧几里得除法/余数（对负数与截断除法不同）
// ============================================================================
{**
 * DivEuclidXX / RemEuclidXX / CheckedDivEuclidXX / CheckedRemEuclidXX
 *
 * @desc
 *   Euclidean division where the remainder is always non-negative.
 *   For positive numbers, same as regular division.
 *   For negative dividends, differs from Pascal's truncated division.
 *   欧几里得除法，余数始终为非负数。
 *   对于正数，与常规除法相同。
 *   对于负被除数，与 Pascal 的截断除法不同。
 *
 * @example
 *   // Regular Pascal division vs Euclidean:
 *   // 常规 Pascal 除法 vs 欧几里得除法：
 *   // -7 div 4 = -1, -7 mod 4 = -3 (Pascal truncated)
 *   // DivEuclid(-7, 4) = -2, RemEuclid(-7, 4) = 1 (Euclidean)
 *
 *   // Invariant: a = DivEuclid(a,b) * b + RemEuclid(a,b)
 *   // 不变式：a = DivEuclid(a,b) * b + RemEuclid(a,b)
 *   // And: 0 <= RemEuclid(a,b) < |b|
 *   // 且：0 <= RemEuclid(a,b) < |b|
 *
 * @safety
 *   - DivEuclid/RemEuclid: 除零引发异常 / Division by zero raises exception
 *   - CheckedDivEuclid/CheckedRemEuclid: 除零返回 None / Division by zero returns None
 *   - MIN_INT / -1 溢出由 Checked 版本处理 / MIN_INT / -1 overflow handled by Checked versions
 *
 * @perf
 *   O(1)，3-5 条指令
 *   O(1), 3-5 instructions
 *
 * @rust_equiv
 *   i32::div_euclid, i32::rem_euclid, i32::checked_div_euclid
 *}

// --- Int8 ---
function DivEuclidI8(aA, aB: Int8): Int8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function RemEuclidI8(aA, aB: Int8): Int8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivEuclidI8(aA, aB: Int8): TOptionalI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedRemEuclidI8(aA, aB: Int8): TOptionalI8; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int16 ---
function DivEuclidI16(aA, aB: Int16): Int16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function RemEuclidI16(aA, aB: Int16): Int16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivEuclidI16(aA, aB: Int16): TOptionalI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedRemEuclidI16(aA, aB: Int16): TOptionalI16; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int32 ---
function DivEuclidI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function RemEuclidI32(aA, aB: Int32): Int32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivEuclidI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedRemEuclidI32(aA, aB: Int32): TOptionalI32; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- Int64 ---
function DivEuclidI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function RemEuclidI64(aA, aB: Int64): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivEuclidI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedRemEuclidI64(aA, aB: Int64): TOptionalI64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// --- SizeInt ---
function DivEuclidSizeInt(aA, aB: SizeInt): SizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function RemEuclidSizeInt(aA, aB: SizeInt): SizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedDivEuclidSizeInt(aA, aB: SizeInt): TOptionalSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function CheckedRemEuclidSizeInt(aA, aB: SizeInt): TOptionalSizeInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

// ============================================================================
// Overflow/Underflow Detection - Unsigned Types
// ============================================================================

// --- UInt8 ---
function IsAddOverflow(aA, aB: UInt8): Boolean;
begin
  Result := aA > (MAX_UINT8 - aB);
end;

function IsSubUnderflow(aA, aB: UInt8): Boolean;
begin
  Result := aA < aB;
end;

function IsMulOverflow(aA, aB: UInt8): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_UINT8 div aB);
end;

// --- UInt16 ---
function IsAddOverflow(aA, aB: UInt16): Boolean;
begin
  Result := aA > (MAX_UINT16 - aB);
end;

function IsSubUnderflow(aA, aB: UInt16): Boolean;
begin
  Result := aA < aB;
end;

function IsMulOverflow(aA, aB: UInt16): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_UINT16 div aB);
end;

// --- UInt32 ---
function IsAddOverflow(aA, aB: UInt32): Boolean;
begin
  Result := aA > (MAX_UINT32 - aB);
end;

function IsSubUnderflow(aA, aB: UInt32): Boolean;
begin
  Result := aA < aB;
end;

function IsMulOverflow(aA, aB: UInt32): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_UINT32 div aB);
end;

// --- UInt64 ---
function IsAddOverflow(aA, aB: UInt64): Boolean;
begin
  Result := aA > (MAX_UINT64 - aB);
end;

function IsSubUnderflow(aA, aB: UInt64): Boolean;
begin
  Result := aA < aB;
end;

function IsMulOverflow(aA, aB: UInt64): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_UINT64 div aB);
end;

// --- SizeUInt --- (only on 32-bit where SizeUInt != UInt64)
{$IFNDEF CPU64}
function IsAddOverflow(aA, aB: SizeUInt): Boolean;
begin
  Result := aA > (MAX_SIZE_UINT - aB);
end;

function IsSubUnderflow(aA, aB: SizeUInt): Boolean;
begin
  Result := aA < aB;
end;

function IsMulOverflow(aA, aB: SizeUInt): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_SIZE_UINT div aB);
end;
{$ENDIF}

// ============================================================================
// Overflow Detection - Signed Types
// ============================================================================

// --- Int8 ---
function IsAddOverflow(aA, aB: Int8): Boolean;
var
  LResult: Int16;
begin
  LResult := Int16(aA) + Int16(aB);
  Result := (LResult > MAX_INT8) or (LResult < MIN_INT8);
end;

function IsSubOverflow(aA, aB: Int8): Boolean;
var
  LResult: Int16;
begin
  LResult := Int16(aA) - Int16(aB);
  Result := (LResult > MAX_INT8) or (LResult < MIN_INT8);
end;

function IsMulOverflow(aA, aB: Int8): Boolean;
var
  LResult: Int16;
begin
  LResult := Int16(aA) * Int16(aB);
  Result := (LResult > MAX_INT8) or (LResult < MIN_INT8);
end;

// --- Int16 ---
function IsAddOverflow(aA, aB: Int16): Boolean;
var
  LResult: Int32;
begin
  LResult := Int32(aA) + Int32(aB);
  Result := (LResult > MAX_INT16) or (LResult < MIN_INT16);
end;

function IsSubOverflow(aA, aB: Int16): Boolean;
var
  LResult: Int32;
begin
  LResult := Int32(aA) - Int32(aB);
  Result := (LResult > MAX_INT16) or (LResult < MIN_INT16);
end;

function IsMulOverflow(aA, aB: Int16): Boolean;
var
  LResult: Int32;
begin
  LResult := Int32(aA) * Int32(aB);
  Result := (LResult > MAX_INT16) or (LResult < MIN_INT16);
end;

// --- Int32 ---
function IsAddOverflow(aA, aB: Int32): Boolean;
var
  LResult: Int64;
begin
  LResult := Int64(aA) + Int64(aB);
  Result := (LResult > MAX_INT32) or (LResult < MIN_INT32);
end;

function IsSubOverflow(aA, aB: Int32): Boolean;
var
  LResult: Int64;
begin
  LResult := Int64(aA) - Int64(aB);
  Result := (LResult > MAX_INT32) or (LResult < MIN_INT32);
end;

function IsMulOverflow(aA, aB: Int32): Boolean;
var
  LResult: Int64;
begin
  LResult := Int64(aA) * Int64(aB);
  Result := (LResult > MAX_INT32) or (LResult < MIN_INT32);
end;

// --- Int64 ---
function IsAddOverflow(aA, aB: Int64): Boolean;
begin
  // For Int64, we cannot use a wider type, so we use sign-based detection
  if aB > 0 then
    Result := aA > (MAX_INT64 - aB)
  else if aB < 0 then
    Result := aA < (MIN_INT64 - aB)
  else
    Result := False;
end;

function IsSubOverflow(aA, aB: Int64): Boolean;
begin
  if aB > 0 then
    Result := aA < (MIN_INT64 + aB)
  else if aB < 0 then
    Result := aA > (MAX_INT64 + aB)
  else
    Result := False;
end;

function IsMulOverflow(aA, aB: Int64): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else if (aA = -1) then
    Result := aB = MIN_INT64
  else if (aB = -1) then
    Result := aA = MIN_INT64
  else if (aA > 0) and (aB > 0) then
    Result := aA > (MAX_INT64 div aB)
  else if (aA < 0) and (aB < 0) then
    Result := aA < (MAX_INT64 div aB)
  else if (aA > 0) and (aB < 0) then
    Result := aB < (MIN_INT64 div aA)
  else // (aA < 0) and (aB > 0)
    Result := aA < (MIN_INT64 div aB);
end;

// --- SizeInt --- (only on 32-bit where SizeInt != Int64)
{$IFNDEF CPU64}
function IsAddOverflow(aA, aB: SizeInt): Boolean;
begin
  Result := IsAddOverflow(Int32(aA), Int32(aB));
end;

function IsSubOverflow(aA, aB: SizeInt): Boolean;
begin
  Result := IsSubOverflow(Int32(aA), Int32(aB));
end;

function IsMulOverflow(aA, aB: SizeInt): Boolean;
begin
  Result := IsMulOverflow(Int32(aA), Int32(aB));
end;
{$ENDIF}

// ============================================================================
// Saturating Operations - Unsigned Types
// ============================================================================

// --- UInt8 ---
function SaturatingAdd(aA, aB: UInt8): UInt8;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_UINT8
  else
    Result := aA + aB;
end;

function SaturatingSub(aA, aB: UInt8): UInt8;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

function SaturatingMul(aA, aB: UInt8): UInt8;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_UINT8
  else
    Result := aA * aB;
end;

// --- UInt16 ---
function SaturatingAdd(aA, aB: UInt16): UInt16;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_UINT16
  else
    Result := aA + aB;
end;

function SaturatingSub(aA, aB: UInt16): UInt16;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

function SaturatingMul(aA, aB: UInt16): UInt16;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_UINT16
  else
    Result := aA * aB;
end;

// --- UInt32 ---
function SaturatingAdd(aA, aB: UInt32): UInt32;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_UINT32
  else
    Result := aA + aB;
end;

function SaturatingSub(aA, aB: UInt32): UInt32;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

function SaturatingMul(aA, aB: UInt32): UInt32;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_UINT32
  else
    Result := aA * aB;
end;

// --- UInt64 ---
function SaturatingAdd(aA, aB: UInt64): UInt64;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_UINT64
  else
    Result := aA + aB;
end;

function SaturatingSub(aA, aB: UInt64): UInt64;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

function SaturatingMul(aA, aB: UInt64): UInt64;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_UINT64
  else
    Result := aA * aB;
end;

// --- SizeUInt --- (only on 32-bit where SizeUInt != UInt64)
{$IFNDEF CPU64}
function SaturatingAdd(aA, aB: SizeUInt): SizeUInt;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_SIZE_UINT
  else
    Result := aA + aB;
end;

function SaturatingSub(aA, aB: SizeUInt): SizeUInt;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

function SaturatingMul(aA, aB: SizeUInt): SizeUInt;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_SIZE_UINT
  else
    Result := aA * aB;
end;
{$ENDIF}

// ============================================================================
// Saturating Operations - Signed Types
// ============================================================================

// --- Int8 ---
function SaturatingAdd(aA, aB: Int8): Int8;
var
  LResult: Int16;
begin
  LResult := Int16(aA) + Int16(aB);
  if LResult > MAX_INT8 then
    Result := MAX_INT8
  else if LResult < MIN_INT8 then
    Result := MIN_INT8
  else
    Result := Int8(LResult);
end;

function SaturatingSub(aA, aB: Int8): Int8;
var
  LResult: Int16;
begin
  LResult := Int16(aA) - Int16(aB);
  if LResult > MAX_INT8 then
    Result := MAX_INT8
  else if LResult < MIN_INT8 then
    Result := MIN_INT8
  else
    Result := Int8(LResult);
end;

function SaturatingMul(aA, aB: Int8): Int8;
var
  LResult: Int16;
begin
  LResult := Int16(aA) * Int16(aB);
  if LResult > MAX_INT8 then
    Result := MAX_INT8
  else if LResult < MIN_INT8 then
    Result := MIN_INT8
  else
    Result := Int8(LResult);
end;

// --- Int16 ---
function SaturatingAdd(aA, aB: Int16): Int16;
var
  LResult: Int32;
begin
  LResult := Int32(aA) + Int32(aB);
  if LResult > MAX_INT16 then
    Result := MAX_INT16
  else if LResult < MIN_INT16 then
    Result := MIN_INT16
  else
    Result := Int16(LResult);
end;

function SaturatingSub(aA, aB: Int16): Int16;
var
  LResult: Int32;
begin
  LResult := Int32(aA) - Int32(aB);
  if LResult > MAX_INT16 then
    Result := MAX_INT16
  else if LResult < MIN_INT16 then
    Result := MIN_INT16
  else
    Result := Int16(LResult);
end;

function SaturatingMul(aA, aB: Int16): Int16;
var
  LResult: Int32;
begin
  LResult := Int32(aA) * Int32(aB);
  if LResult > MAX_INT16 then
    Result := MAX_INT16
  else if LResult < MIN_INT16 then
    Result := MIN_INT16
  else
    Result := Int16(LResult);
end;

// --- Int32 ---
function SaturatingAdd(aA, aB: Int32): Int32;
var
  LResult: Int64;
begin
  LResult := Int64(aA) + Int64(aB);
  if LResult > MAX_INT32 then
    Result := MAX_INT32
  else if LResult < MIN_INT32 then
    Result := MIN_INT32
  else
    Result := Int32(LResult);
end;

function SaturatingSub(aA, aB: Int32): Int32;
var
  LResult: Int64;
begin
  LResult := Int64(aA) - Int64(aB);
  if LResult > MAX_INT32 then
    Result := MAX_INT32
  else if LResult < MIN_INT32 then
    Result := MIN_INT32
  else
    Result := Int32(LResult);
end;

function SaturatingMul(aA, aB: Int32): Int32;
var
  LResult: Int64;
begin
  LResult := Int64(aA) * Int64(aB);
  if LResult > MAX_INT32 then
    Result := MAX_INT32
  else if LResult < MIN_INT32 then
    Result := MIN_INT32
  else
    Result := Int32(LResult);
end;

// --- Int64 ---
function SaturatingAdd(aA, aB: Int64): Int64;
begin
  if IsAddOverflow(aA, aB) then
  begin
    if aB > 0 then
      Result := MAX_INT64
    else
      Result := MIN_INT64;
  end
  else
    Result := aA + aB;
end;

function SaturatingSub(aA, aB: Int64): Int64;
begin
  if IsSubOverflow(aA, aB) then
  begin
    if aB > 0 then
      Result := MIN_INT64
    else
      Result := MAX_INT64;
  end
  else
    Result := aA - aB;
end;

function SaturatingMul(aA, aB: Int64): Int64;
begin
  if IsMulOverflow(aA, aB) then
  begin
    // Determine sign of result
    if ((aA > 0) and (aB > 0)) or ((aA < 0) and (aB < 0)) then
      Result := MAX_INT64
    else
      Result := MIN_INT64;
  end
  else
    Result := aA * aB;
end;

// --- SizeInt --- (only on 32-bit where SizeInt != Int64)
{$IFNDEF CPU64}
function SaturatingAdd(aA, aB: SizeInt): SizeInt;
begin
  Result := SizeInt(SaturatingAdd(Int32(aA), Int32(aB)));
end;

function SaturatingSub(aA, aB: SizeInt): SizeInt;
begin
  Result := SizeInt(SaturatingSub(Int32(aA), Int32(aB)));
end;

function SaturatingMul(aA, aB: SizeInt): SizeInt;
begin
  Result := SizeInt(SaturatingMul(Int32(aA), Int32(aB)));
end;
{$ENDIF}

// ============================================================================
// Checked Operations - Unsigned Types
// ============================================================================

// --- UInt8 ---
function CheckedAddU8(aA, aB: UInt8): TOptionalU8;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalU8.None
  else
    Result := TOptionalU8.Some(aA + aB);
end;

function CheckedSubU8(aA, aB: UInt8): TOptionalU8;
begin
  if IsSubUnderflow(aA, aB) then
    Result := TOptionalU8.None
  else
    Result := TOptionalU8.Some(aA - aB);
end;

function CheckedMulU8(aA, aB: UInt8): TOptionalU8;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalU8.None
  else
    Result := TOptionalU8.Some(aA * aB);
end;

function CheckedDivU8(aA, aB: UInt8): TOptionalU8;
begin
  if aB = 0 then
    Result := TOptionalU8.None
  else
    Result := TOptionalU8.Some(aA div aB);
end;

// --- UInt16 ---
function CheckedAddU16(aA, aB: UInt16): TOptionalU16;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalU16.None
  else
    Result := TOptionalU16.Some(aA + aB);
end;

function CheckedSubU16(aA, aB: UInt16): TOptionalU16;
begin
  if IsSubUnderflow(aA, aB) then
    Result := TOptionalU16.None
  else
    Result := TOptionalU16.Some(aA - aB);
end;

function CheckedMulU16(aA, aB: UInt16): TOptionalU16;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalU16.None
  else
    Result := TOptionalU16.Some(aA * aB);
end;

function CheckedDivU16(aA, aB: UInt16): TOptionalU16;
begin
  if aB = 0 then
    Result := TOptionalU16.None
  else
    Result := TOptionalU16.Some(aA div aB);
end;

// --- UInt32 ---
function CheckedAddU32(aA, aB: UInt32): TOptionalU32;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalU32.None
  else
    Result := TOptionalU32.Some(aA + aB);
end;

function CheckedSubU32(aA, aB: UInt32): TOptionalU32;
begin
  if IsSubUnderflow(aA, aB) then
    Result := TOptionalU32.None
  else
    Result := TOptionalU32.Some(aA - aB);
end;

function CheckedMulU32(aA, aB: UInt32): TOptionalU32;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalU32.None
  else
    Result := TOptionalU32.Some(aA * aB);
end;

function CheckedDivU32(aA, aB: UInt32): TOptionalU32;
begin
  if aB = 0 then
    Result := TOptionalU32.None
  else
    Result := TOptionalU32.Some(aA div aB);
end;

// --- UInt64 ---
function CheckedAddU64(aA, aB: UInt64): TOptionalU64;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalU64.None
  else
    Result := TOptionalU64.Some(aA + aB);
end;

function CheckedSubU64(aA, aB: UInt64): TOptionalU64;
begin
  if IsSubUnderflow(aA, aB) then
    Result := TOptionalU64.None
  else
    Result := TOptionalU64.Some(aA - aB);
end;

function CheckedMulU64(aA, aB: UInt64): TOptionalU64;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalU64.None
  else
    Result := TOptionalU64.Some(aA * aB);
end;

function CheckedDivU64(aA, aB: UInt64): TOptionalU64;
begin
  if aB = 0 then
    Result := TOptionalU64.None
  else
    Result := TOptionalU64.Some(aA div aB);
end;

// --- SizeUInt ---
function CheckedAddSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalSizeUInt.None
  else
    Result := TOptionalSizeUInt.Some(aA + aB);
end;

function CheckedSubSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt;
begin
  if IsSubUnderflow(aA, aB) then
    Result := TOptionalSizeUInt.None
  else
    Result := TOptionalSizeUInt.Some(aA - aB);
end;

function CheckedMulSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalSizeUInt.None
  else
    Result := TOptionalSizeUInt.Some(aA * aB);
end;

function CheckedDivSizeUInt(aA, aB: SizeUInt): TOptionalSizeUInt;
begin
  if aB = 0 then
    Result := TOptionalSizeUInt.None
  else
    Result := TOptionalSizeUInt.Some(aA div aB);
end;

// ============================================================================
// Checked Operations - Signed Types
// ============================================================================

// --- Int8 ---
function CheckedAddI8(aA, aB: Int8): TOptionalI8;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalI8.None
  else
    Result := TOptionalI8.Some(aA + aB);
end;

function CheckedSubI8(aA, aB: Int8): TOptionalI8;
begin
  if IsSubOverflow(aA, aB) then
    Result := TOptionalI8.None
  else
    Result := TOptionalI8.Some(aA - aB);
end;

function CheckedMulI8(aA, aB: Int8): TOptionalI8;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalI8.None
  else
    Result := TOptionalI8.Some(aA * aB);
end;

function CheckedDivI8(aA, aB: Int8): TOptionalI8;
begin
  if (aB = 0) or ((aA = MIN_INT8) and (aB = -1)) then
    Result := TOptionalI8.None
  else
    Result := TOptionalI8.Some(aA div aB);
end;

function CheckedNegI8(aA: Int8): TOptionalI8;
begin
  if aA = MIN_INT8 then
    Result := TOptionalI8.None
  else
    Result := TOptionalI8.Some(-aA);
end;

// --- Int16 ---
function CheckedAddI16(aA, aB: Int16): TOptionalI16;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalI16.None
  else
    Result := TOptionalI16.Some(aA + aB);
end;

function CheckedSubI16(aA, aB: Int16): TOptionalI16;
begin
  if IsSubOverflow(aA, aB) then
    Result := TOptionalI16.None
  else
    Result := TOptionalI16.Some(aA - aB);
end;

function CheckedMulI16(aA, aB: Int16): TOptionalI16;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalI16.None
  else
    Result := TOptionalI16.Some(aA * aB);
end;

function CheckedDivI16(aA, aB: Int16): TOptionalI16;
begin
  if (aB = 0) or ((aA = MIN_INT16) and (aB = -1)) then
    Result := TOptionalI16.None
  else
    Result := TOptionalI16.Some(aA div aB);
end;

function CheckedNegI16(aA: Int16): TOptionalI16;
begin
  if aA = MIN_INT16 then
    Result := TOptionalI16.None
  else
    Result := TOptionalI16.Some(-aA);
end;

// --- Int32 ---
function CheckedAddI32(aA, aB: Int32): TOptionalI32;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(aA + aB);
end;

function CheckedSubI32(aA, aB: Int32): TOptionalI32;
begin
  if IsSubOverflow(aA, aB) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(aA - aB);
end;

function CheckedMulI32(aA, aB: Int32): TOptionalI32;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(aA * aB);
end;

function CheckedDivI32(aA, aB: Int32): TOptionalI32;
begin
  if (aB = 0) or ((aA = MIN_INT32) and (aB = -1)) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(aA div aB);
end;

function CheckedNegI32(aA: Int32): TOptionalI32;
begin
  if aA = MIN_INT32 then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(-aA);
end;

// --- Int64 ---
function CheckedAddI64(aA, aB: Int64): TOptionalI64;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(aA + aB);
end;

function CheckedSubI64(aA, aB: Int64): TOptionalI64;
begin
  if IsSubOverflow(aA, aB) then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(aA - aB);
end;

function CheckedMulI64(aA, aB: Int64): TOptionalI64;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(aA * aB);
end;

function CheckedDivI64(aA, aB: Int64): TOptionalI64;
begin
  if (aB = 0) or ((aA = MIN_INT64) and (aB = -1)) then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(aA div aB);
end;

function CheckedNegI64(aA: Int64): TOptionalI64;
begin
  if aA = MIN_INT64 then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(-aA);
end;

// --- SizeInt ---
function CheckedAddSizeInt(aA, aB: SizeInt): TOptionalSizeInt;
begin
  if IsAddOverflow(aA, aB) then
    Result := TOptionalSizeInt.None
  else
    Result := TOptionalSizeInt.Some(aA + aB);
end;

function CheckedSubSizeInt(aA, aB: SizeInt): TOptionalSizeInt;
begin
  if IsSubOverflow(aA, aB) then
    Result := TOptionalSizeInt.None
  else
    Result := TOptionalSizeInt.Some(aA - aB);
end;

function CheckedMulSizeInt(aA, aB: SizeInt): TOptionalSizeInt;
begin
  if IsMulOverflow(aA, aB) then
    Result := TOptionalSizeInt.None
  else
    Result := TOptionalSizeInt.Some(aA * aB);
end;

function CheckedDivSizeInt(aA, aB: SizeInt): TOptionalSizeInt;
begin
  if (aB = 0) or ((aA = MIN_SIZE_INT) and (aB = -1)) then
    Result := TOptionalSizeInt.None
  else
    Result := TOptionalSizeInt.Some(aA div aB);
end;

function CheckedNegSizeInt(aA: SizeInt): TOptionalSizeInt;
begin
  if aA = MIN_SIZE_INT then
    Result := TOptionalSizeInt.None
  else
    Result := TOptionalSizeInt.Some(-aA);
end;

// ============================================================================
// Overflowing Operations - Unsigned Types
// ============================================================================

// --- UInt8 ---
function OverflowingAddU8(aA, aB: UInt8): TOverflowU8;
begin
  Result := TOverflowU8.Create(UInt8(aA + aB), IsAddOverflow(aA, aB));
end;

function OverflowingSubU8(aA, aB: UInt8): TOverflowU8;
begin
  Result := TOverflowU8.Create(UInt8(aA - aB), IsSubUnderflow(aA, aB));
end;

function OverflowingMulU8(aA, aB: UInt8): TOverflowU8;
begin
  Result := TOverflowU8.Create(UInt8(UInt16(aA) * UInt16(aB)), IsMulOverflow(aA, aB));
end;

// --- UInt16 ---
function OverflowingAddU16(aA, aB: UInt16): TOverflowU16;
begin
  Result := TOverflowU16.Create(UInt16(aA + aB), IsAddOverflow(aA, aB));
end;

function OverflowingSubU16(aA, aB: UInt16): TOverflowU16;
begin
  Result := TOverflowU16.Create(UInt16(aA - aB), IsSubUnderflow(aA, aB));
end;

function OverflowingMulU16(aA, aB: UInt16): TOverflowU16;
begin
  Result := TOverflowU16.Create(UInt16(UInt32(aA) * UInt32(aB)), IsMulOverflow(aA, aB));
end;

// --- UInt32 ---
function OverflowingAddU32(aA, aB: UInt32): TOverflowU32;
begin
  Result := TOverflowU32.Create(UInt32(aA + aB), IsAddOverflow(aA, aB));
end;

function OverflowingSubU32(aA, aB: UInt32): TOverflowU32;
begin
  Result := TOverflowU32.Create(UInt32(aA - aB), IsSubUnderflow(aA, aB));
end;

function OverflowingMulU32(aA, aB: UInt32): TOverflowU32;
begin
  Result := TOverflowU32.Create(UInt32(UInt64(aA) * UInt64(aB)), IsMulOverflow(aA, aB));
end;

// --- UInt64 ---
function OverflowingAddU64(aA, aB: UInt64): TOverflowU64;
begin
  Result := TOverflowU64.Create(aA + aB, IsAddOverflow(aA, aB));
end;

function OverflowingSubU64(aA, aB: UInt64): TOverflowU64;
begin
  Result := TOverflowU64.Create(aA - aB, IsSubUnderflow(aA, aB));
end;

function OverflowingMulU64(aA, aB: UInt64): TOverflowU64;
begin
  Result := TOverflowU64.Create(aA * aB, IsMulOverflow(aA, aB));
end;

// --- SizeUInt ---
function OverflowingAddSizeUInt(aA, aB: SizeUInt): TOverflowSizeUInt;
begin
  Result := TOverflowSizeUInt.Create(aA + aB, IsAddOverflow(aA, aB));
end;

function OverflowingSubSizeUInt(aA, aB: SizeUInt): TOverflowSizeUInt;
begin
  Result := TOverflowSizeUInt.Create(aA - aB, IsSubUnderflow(aA, aB));
end;

function OverflowingMulSizeUInt(aA, aB: SizeUInt): TOverflowSizeUInt;
begin
  Result := TOverflowSizeUInt.Create(aA * aB, IsMulOverflow(aA, aB));
end;

// ============================================================================
// Overflowing Operations - Signed Types
// ============================================================================

// --- Int8 ---
function OverflowingAddI8(aA, aB: Int8): TOverflowI8;
begin
  Result := TOverflowI8.Create(Int8(aA + aB), IsAddOverflow(aA, aB));
end;

function OverflowingSubI8(aA, aB: Int8): TOverflowI8;
begin
  Result := TOverflowI8.Create(Int8(aA - aB), IsSubOverflow(aA, aB));
end;

function OverflowingMulI8(aA, aB: Int8): TOverflowI8;
begin
  Result := TOverflowI8.Create(Int8(Int16(aA) * Int16(aB)), IsMulOverflow(aA, aB));
end;

function OverflowingNegI8(aA: Int8): TOverflowI8;
begin
  if aA = MIN_INT8 then
    Result := TOverflowI8.Create(MIN_INT8, True)
  else
    Result := TOverflowI8.Create(-aA, False);
end;

// --- Int16 ---
function OverflowingAddI16(aA, aB: Int16): TOverflowI16;
begin
  Result := TOverflowI16.Create(Int16(aA + aB), IsAddOverflow(aA, aB));
end;

function OverflowingSubI16(aA, aB: Int16): TOverflowI16;
begin
  Result := TOverflowI16.Create(Int16(aA - aB), IsSubOverflow(aA, aB));
end;

function OverflowingMulI16(aA, aB: Int16): TOverflowI16;
begin
  Result := TOverflowI16.Create(Int16(Int32(aA) * Int32(aB)), IsMulOverflow(aA, aB));
end;

function OverflowingNegI16(aA: Int16): TOverflowI16;
begin
  if aA = MIN_INT16 then
    Result := TOverflowI16.Create(MIN_INT16, True)
  else
    Result := TOverflowI16.Create(-aA, False);
end;

// --- Int32 ---
function OverflowingAddI32(aA, aB: Int32): TOverflowI32;
begin
  Result := TOverflowI32.Create(Int32(aA + aB), IsAddOverflow(aA, aB));
end;

function OverflowingSubI32(aA, aB: Int32): TOverflowI32;
begin
  Result := TOverflowI32.Create(Int32(aA - aB), IsSubOverflow(aA, aB));
end;

function OverflowingMulI32(aA, aB: Int32): TOverflowI32;
begin
  Result := TOverflowI32.Create(Int32(Int64(aA) * Int64(aB)), IsMulOverflow(aA, aB));
end;

function OverflowingNegI32(aA: Int32): TOverflowI32;
begin
  if aA = MIN_INT32 then
    Result := TOverflowI32.Create(MIN_INT32, True)
  else
    Result := TOverflowI32.Create(-aA, False);
end;

// --- Int64 ---
function OverflowingAddI64(aA, aB: Int64): TOverflowI64;
begin
  Result := TOverflowI64.Create(aA + aB, IsAddOverflow(aA, aB));
end;

function OverflowingSubI64(aA, aB: Int64): TOverflowI64;
begin
  Result := TOverflowI64.Create(aA - aB, IsSubOverflow(aA, aB));
end;

function OverflowingMulI64(aA, aB: Int64): TOverflowI64;
begin
  Result := TOverflowI64.Create(aA * aB, IsMulOverflow(aA, aB));
end;

function OverflowingNegI64(aA: Int64): TOverflowI64;
begin
  if aA = MIN_INT64 then
    Result := TOverflowI64.Create(MIN_INT64, True)
  else
    Result := TOverflowI64.Create(-aA, False);
end;

// --- SizeInt ---
function OverflowingAddSizeInt(aA, aB: SizeInt): TOverflowSizeInt;
begin
  Result := TOverflowSizeInt.Create(aA + aB, IsAddOverflow(aA, aB));
end;

function OverflowingSubSizeInt(aA, aB: SizeInt): TOverflowSizeInt;
begin
  Result := TOverflowSizeInt.Create(aA - aB, IsSubOverflow(aA, aB));
end;

function OverflowingMulSizeInt(aA, aB: SizeInt): TOverflowSizeInt;
begin
  Result := TOverflowSizeInt.Create(aA * aB, IsMulOverflow(aA, aB));
end;

function OverflowingNegSizeInt(aA: SizeInt): TOverflowSizeInt;
begin
  if aA = MIN_SIZE_INT then
    Result := TOverflowSizeInt.Create(MIN_SIZE_INT, True)
  else
    Result := TOverflowSizeInt.Create(-aA, False);
end;

// ============================================================================
// Wrapping Operations - Unsigned Types
// ============================================================================

// --- UInt8 ---
function WrappingAddU8(aA, aB: UInt8): UInt8;
begin
  Result := aA + aB;
end;

function WrappingSubU8(aA, aB: UInt8): UInt8;
begin
  Result := aA - aB;
end;

function WrappingMulU8(aA, aB: UInt8): UInt8;
begin
  Result := aA * aB;
end;

// --- UInt16 ---
function WrappingAddU16(aA, aB: UInt16): UInt16;
begin
  Result := aA + aB;
end;

function WrappingSubU16(aA, aB: UInt16): UInt16;
begin
  Result := aA - aB;
end;

function WrappingMulU16(aA, aB: UInt16): UInt16;
begin
  Result := aA * aB;
end;

// --- UInt32 ---
function WrappingAddU32(aA, aB: UInt32): UInt32;
begin
  Result := aA + aB;
end;

function WrappingSubU32(aA, aB: UInt32): UInt32;
begin
  Result := aA - aB;
end;

function WrappingMulU32(aA, aB: UInt32): UInt32;
begin
  Result := aA * aB;
end;

// --- UInt64 ---
function WrappingAddU64(aA, aB: UInt64): UInt64;
begin
  Result := aA + aB;
end;

function WrappingSubU64(aA, aB: UInt64): UInt64;
begin
  Result := aA - aB;
end;

function WrappingMulU64(aA, aB: UInt64): UInt64;
begin
  Result := aA * aB;
end;

// --- SizeUInt ---
function WrappingAddSizeUInt(aA, aB: SizeUInt): SizeUInt;
begin
  Result := aA + aB;
end;

function WrappingSubSizeUInt(aA, aB: SizeUInt): SizeUInt;
begin
  Result := aA - aB;
end;

function WrappingMulSizeUInt(aA, aB: SizeUInt): SizeUInt;
begin
  Result := aA * aB;
end;

// ============================================================================
// Wrapping Operations - Signed Types
// ============================================================================

// --- Int8 ---
function WrappingAddI8(aA, aB: Int8): Int8;
begin
  Result := aA + aB;
end;

function WrappingSubI8(aA, aB: Int8): Int8;
begin
  Result := aA - aB;
end;

function WrappingMulI8(aA, aB: Int8): Int8;
begin
  Result := aA * aB;
end;

function WrappingNegI8(aA: Int8): Int8;
begin
  Result := -aA;
end;

// --- Int16 ---
function WrappingAddI16(aA, aB: Int16): Int16;
begin
  Result := aA + aB;
end;

function WrappingSubI16(aA, aB: Int16): Int16;
begin
  Result := aA - aB;
end;

function WrappingMulI16(aA, aB: Int16): Int16;
begin
  Result := aA * aB;
end;

function WrappingNegI16(aA: Int16): Int16;
begin
  Result := -aA;
end;

// --- Int32 ---
function WrappingAddI32(aA, aB: Int32): Int32;
begin
  Result := aA + aB;
end;

function WrappingSubI32(aA, aB: Int32): Int32;
begin
  Result := aA - aB;
end;

function WrappingMulI32(aA, aB: Int32): Int32;
begin
  Result := aA * aB;
end;

function WrappingNegI32(aA: Int32): Int32;
begin
  Result := -aA;
end;

// --- Int64 ---
function WrappingAddI64(aA, aB: Int64): Int64;
begin
  Result := aA + aB;
end;

function WrappingSubI64(aA, aB: Int64): Int64;
begin
  Result := aA - aB;
end;

function WrappingMulI64(aA, aB: Int64): Int64;
begin
  Result := aA * aB;
end;

function WrappingNegI64(aA: Int64): Int64;
begin
  Result := -aA;
end;

// --- SizeInt ---
function WrappingAddSizeInt(aA, aB: SizeInt): SizeInt;
begin
  Result := aA + aB;
end;

function WrappingSubSizeInt(aA, aB: SizeInt): SizeInt;
begin
  Result := aA - aB;
end;

function WrappingMulSizeInt(aA, aB: SizeInt): SizeInt;
begin
  Result := aA * aB;
end;

function WrappingNegSizeInt(aA: SizeInt): SizeInt;
begin
  Result := -aA;
end;

// ============================================================================
// Carrying/Borrowing Operations - Implementation
// ============================================================================

// --- UInt8 ---
function CarryingAddU8(aA, aB: UInt8; aCarryIn: Boolean): TCarryResultU8;
var
  LSum: UInt16;
begin
  LSum := UInt16(aA) + UInt16(aB);
  if aCarryIn then
    Inc(LSum);
  Result := TCarryResultU8.Create(UInt8(LSum), LSum > MAX_UINT8);
end;

function BorrowingSubU8(aA, aB: UInt8; aBorrowIn: Boolean): TCarryResultU8;
var
  LDiff: Int16;
begin
  LDiff := Int16(aA) - Int16(aB);
  if aBorrowIn then
    Dec(LDiff);
  // Borrow occurred if result is negative
  Result := TCarryResultU8.Create(UInt8(LDiff and $FF), LDiff < 0);
end;

// --- UInt16 ---
function CarryingAddU16(aA, aB: UInt16; aCarryIn: Boolean): TCarryResultU16;
var
  LSum: UInt32;
begin
  LSum := UInt32(aA) + UInt32(aB);
  if aCarryIn then
    Inc(LSum);
  Result := TCarryResultU16.Create(UInt16(LSum), LSum > MAX_UINT16);
end;

function BorrowingSubU16(aA, aB: UInt16; aBorrowIn: Boolean): TCarryResultU16;
var
  LDiff: Int32;
begin
  LDiff := Int32(aA) - Int32(aB);
  if aBorrowIn then
    Dec(LDiff);
  Result := TCarryResultU16.Create(UInt16(LDiff and $FFFF), LDiff < 0);
end;

// --- UInt32 ---
function CarryingAddU32(aA, aB: UInt32; aCarryIn: Boolean): TCarryResultU32;
var
  LSum: UInt64;
begin
  LSum := UInt64(aA) + UInt64(aB);
  if aCarryIn then
    Inc(LSum);
  Result := TCarryResultU32.Create(UInt32(LSum), LSum > MAX_UINT32);
end;

function BorrowingSubU32(aA, aB: UInt32; aBorrowIn: Boolean): TCarryResultU32;
var
  LDiff: Int64;
begin
  LDiff := Int64(aA) - Int64(aB);
  if aBorrowIn then
    Dec(LDiff);
  Result := TCarryResultU32.Create(UInt32(LDiff and $FFFFFFFF), LDiff < 0);
end;

// --- UInt64 ---
function CarryingAddU64(aA, aB: UInt64; aCarryIn: Boolean): TCarryResultU64;
var
  LSum: UInt64;
  LCarry: Boolean;
begin
  // For UInt64, we can't use a wider type, so we detect carry differently
  LSum := aA + aB;
  LCarry := LSum < aA; // Carry occurred if result wrapped around
  if aCarryIn then
  begin
    Inc(LSum);
    // Additional carry if incrementing caused wrap
    if LSum = 0 then
      LCarry := True;
  end;
  Result := TCarryResultU64.Create(LSum, LCarry);
end;

function BorrowingSubU64(aA, aB: UInt64; aBorrowIn: Boolean): TCarryResultU64;
var
  LDiff: UInt64;
  LBorrow: Boolean;
begin
  // Borrow detection: if b > a, we need to borrow
  LBorrow := aB > aA;
  LDiff := aA - aB;
  if aBorrowIn then
  begin
    // Additional borrow if we're subtracting from 0
    if LDiff = 0 then
      LBorrow := True;
    Dec(LDiff);
  end;
  Result := TCarryResultU64.Create(LDiff, LBorrow);
end;

// --- SizeUInt ---
function CarryingAddSizeUInt(aA, aB: SizeUInt; aCarryIn: Boolean): TCarryResultSizeUInt;
begin
  {$IFDEF CPU64}
  Result := TCarryResultSizeUInt(CarryingAddU64(UInt64(aA), UInt64(aB), aCarryIn));
  {$ELSE}
  Result := TCarryResultSizeUInt(CarryingAddU32(UInt32(aA), UInt32(aB), aCarryIn));
  {$ENDIF}
end;

function BorrowingSubSizeUInt(aA, aB: SizeUInt; aBorrowIn: Boolean): TCarryResultSizeUInt;
begin
  {$IFDEF CPU64}
  Result := TCarryResultSizeUInt(BorrowingSubU64(UInt64(aA), UInt64(aB), aBorrowIn));
  {$ELSE}
  Result := TCarryResultSizeUInt(BorrowingSubU32(UInt32(aA), UInt32(aB), aBorrowIn));
  {$ENDIF}
end;

// ============================================================================
// Widening Multiplication - Implementation
// ============================================================================

function WideningMulU8(aA, aB: UInt8): UInt16;
begin
  Result := UInt16(aA) * UInt16(aB);
end;

function WideningMulU16(aA, aB: UInt16): UInt32;
begin
  Result := UInt32(aA) * UInt32(aB);
end;

function WideningMulU32(aA, aB: UInt32): UInt64;
begin
  Result := UInt64(aA) * UInt64(aB);
end;

function WideningMulU64(aA, aB: UInt64): TUInt128;
var
  LA_Lo, LA_Hi, LB_Lo, LB_Hi: UInt64;
  LLo_Lo, LLo_Hi, LHi_Lo, LHi_Hi: UInt64;
  LMid1, LMid2: UInt64;
  LCarry: UInt64;
begin
  // Split each 64-bit value into two 32-bit halves
  // 将每个 64 位值拆分为两个 32 位半部
  LA_Lo := aA and $FFFFFFFF;
  LA_Hi := aA shr 32;
  LB_Lo := aB and $FFFFFFFF;
  LB_Hi := aB shr 32;

  // Compute partial products (each fits in 64 bits)
  // 计算部分积（每个都适合 64 位）
  LLo_Lo := LA_Lo * LB_Lo;  // Low * Low
  LLo_Hi := LA_Lo * LB_Hi;  // Low * High
  LHi_Lo := LA_Hi * LB_Lo;  // High * Low
  LHi_Hi := LA_Hi * LB_Hi;  // High * High

  // Combine: Result = LLo_Lo + (LLo_Hi + LHi_Lo) << 32 + LHi_Hi << 64
  // 组合：结果 = LLo_Lo + (LLo_Hi + LHi_Lo) << 32 + LHi_Hi << 64
  Result.Lo := LLo_Lo;
  Result.Hi := LHi_Hi;

  // Add middle terms
  // 添加中间项
  LMid1 := LLo_Hi + LHi_Lo;
  LCarry := 0;
  if LMid1 < LLo_Hi then // overflow in addition
    LCarry := UInt64(1) shl 32;

  // Add lower 32 bits of middle sum to Result.Lo
  // 将中间和的低 32 位加到 Result.Lo
  LMid2 := Result.Lo + (LMid1 shl 32);
  if LMid2 < Result.Lo then
    Inc(Result.Hi); // carry to Hi
  Result.Lo := LMid2;

  // Add upper 32 bits of middle sum to Result.Hi
  // 将中间和的高 32 位加到 Result.Hi
  Result.Hi := Result.Hi + (LMid1 shr 32) + LCarry;
end;

// ============================================================================
// Euclidean Division/Remainder - Implementation
// ============================================================================

// Internal helper: compute rem_euclid from div_euclid and truncated mod
// 内部辅助：从 div_euclid 和截断 mod 计算 rem_euclid
// Note: Euclidean remainder is always non-negative: 0 <= r < |b|
// 注意：欧几里得余数始终为非负数：0 <= r < |b|

// --- Int8 ---
function DivEuclidI8(aA, aB: Int8): Int8;
var
  LDiv, LRem: Int8;
begin
  // Euclidean division: quotient such that remainder is non-negative
  // 欧几里得除法：商使得余数为非负
  LDiv := aA div aB;
  LRem := aA mod aB;
  // If remainder is negative, adjust quotient
  // 如果余数为负，调整商
  if LRem < 0 then
  begin
    if aB > 0 then
      Dec(LDiv)
    else
      Inc(LDiv);
  end;
  Result := LDiv;
end;

function RemEuclidI8(aA, aB: Int8): Int8;
var
  LRem: Int8;
begin
  LRem := aA mod aB;
  // Euclidean remainder is always non-negative
  // 欧几里得余数始终为非负
  if LRem < 0 then
  begin
    if aB > 0 then
      LRem := LRem + aB
    else
      LRem := LRem - aB;
  end;
  Result := LRem;
end;

function CheckedDivEuclidI8(aA, aB: Int8): TOptionalI8;
begin
  // Division by zero or MIN_INT / -1 overflow
  // 除零或 MIN_INT / -1 溢出
  if (aB = 0) or ((aA = MIN_INT8) and (aB = -1)) then
    Result := TOptionalI8.None
  else
    Result := TOptionalI8.Some(DivEuclidI8(aA, aB));
end;

function CheckedRemEuclidI8(aA, aB: Int8): TOptionalI8;
begin
  // Division by zero
  // 除零
  if aB = 0 then
    Result := TOptionalI8.None
  else
    Result := TOptionalI8.Some(RemEuclidI8(aA, aB));
end;

// --- Int16 ---
function DivEuclidI16(aA, aB: Int16): Int16;
var
  LDiv, LRem: Int16;
begin
  LDiv := aA div aB;
  LRem := aA mod aB;
  if LRem < 0 then
  begin
    if aB > 0 then
      Dec(LDiv)
    else
      Inc(LDiv);
  end;
  Result := LDiv;
end;

function RemEuclidI16(aA, aB: Int16): Int16;
var
  LRem: Int16;
begin
  LRem := aA mod aB;
  if LRem < 0 then
  begin
    if aB > 0 then
      LRem := LRem + aB
    else
      LRem := LRem - aB;
  end;
  Result := LRem;
end;

function CheckedDivEuclidI16(aA, aB: Int16): TOptionalI16;
begin
  if (aB = 0) or ((aA = MIN_INT16) and (aB = -1)) then
    Result := TOptionalI16.None
  else
    Result := TOptionalI16.Some(DivEuclidI16(aA, aB));
end;

function CheckedRemEuclidI16(aA, aB: Int16): TOptionalI16;
begin
  if aB = 0 then
    Result := TOptionalI16.None
  else
    Result := TOptionalI16.Some(RemEuclidI16(aA, aB));
end;

// --- Int32 ---
function DivEuclidI32(aA, aB: Int32): Int32;
var
  LDiv, LRem: Int32;
begin
  LDiv := aA div aB;
  LRem := aA mod aB;
  if LRem < 0 then
  begin
    if aB > 0 then
      Dec(LDiv)
    else
      Inc(LDiv);
  end;
  Result := LDiv;
end;

function RemEuclidI32(aA, aB: Int32): Int32;
var
  LRem: Int32;
begin
  LRem := aA mod aB;
  if LRem < 0 then
  begin
    if aB > 0 then
      LRem := LRem + aB
    else
      LRem := LRem - aB;
  end;
  Result := LRem;
end;

function CheckedDivEuclidI32(aA, aB: Int32): TOptionalI32;
begin
  if (aB = 0) or ((aA = MIN_INT32) and (aB = -1)) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(DivEuclidI32(aA, aB));
end;

function CheckedRemEuclidI32(aA, aB: Int32): TOptionalI32;
begin
  if aB = 0 then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(RemEuclidI32(aA, aB));
end;

// --- Int64 ---
function DivEuclidI64(aA, aB: Int64): Int64;
var
  LDiv, LRem: Int64;
begin
  LDiv := aA div aB;
  LRem := aA mod aB;
  if LRem < 0 then
  begin
    if aB > 0 then
      Dec(LDiv)
    else
      Inc(LDiv);
  end;
  Result := LDiv;
end;

function RemEuclidI64(aA, aB: Int64): Int64;
var
  LRem: Int64;
begin
  LRem := aA mod aB;
  if LRem < 0 then
  begin
    if aB > 0 then
      LRem := LRem + aB
    else
      LRem := LRem - aB;
  end;
  Result := LRem;
end;

function CheckedDivEuclidI64(aA, aB: Int64): TOptionalI64;
begin
  if (aB = 0) or ((aA = MIN_INT64) and (aB = -1)) then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(DivEuclidI64(aA, aB));
end;

function CheckedRemEuclidI64(aA, aB: Int64): TOptionalI64;
begin
  if aB = 0 then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(RemEuclidI64(aA, aB));
end;

// --- SizeInt ---
function DivEuclidSizeInt(aA, aB: SizeInt): SizeInt;
begin
  {$IFDEF CPU64}
  Result := SizeInt(DivEuclidI64(Int64(aA), Int64(aB)));
  {$ELSE}
  Result := SizeInt(DivEuclidI32(Int32(aA), Int32(aB)));
  {$ENDIF}
end;

function RemEuclidSizeInt(aA, aB: SizeInt): SizeInt;
begin
  {$IFDEF CPU64}
  Result := SizeInt(RemEuclidI64(Int64(aA), Int64(aB)));
  {$ELSE}
  Result := SizeInt(RemEuclidI32(Int32(aA), Int32(aB)));
  {$ENDIF}
end;

function CheckedDivEuclidSizeInt(aA, aB: SizeInt): TOptionalSizeInt;
begin
  if (aB = 0) or ((aA = MIN_SIZE_INT) and (aB = -1)) then
    Result := TOptionalSizeInt.None
  else
    Result := TOptionalSizeInt.Some(DivEuclidSizeInt(aA, aB));
end;

function CheckedRemEuclidSizeInt(aA, aB: SizeInt): TOptionalSizeInt;
begin
  if aB = 0 then
    Result := TOptionalSizeInt.None
  else
    Result := TOptionalSizeInt.Some(RemEuclidSizeInt(aA, aB));
end;

{$POP}

end.

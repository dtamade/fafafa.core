{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.base

## Abstract 摘要

Core type definitions for safe arithmetic operations, inspired by Rust std::num.
Provides TOptional<T> (Rust Option equivalent) and TOverflowResult<T> for
checked and overflowing arithmetic operations.

安全算术运算的核心类型定义，设计灵感来自 Rust std::num。
提供 TOptional<T>（Rust Option 等价物）和 TOverflowResult<T>，
用于检查和溢出算术运算。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.base;

{$MODE OBJFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}

interface

type
  // ============================================================================
  // TOptional<T> - Rust Option<T> Equivalent
  // ============================================================================

  {**
   * TOptional<T>
   *
   * @desc
   *   A generic optional type that represents either a valid value (Some)
   *   or no value (None). Equivalent to Rust's Option<T>.
   *
   *   泛型可选类型，表示有效值（Some）或无值（None）。
   *   等价于 Rust 的 Option<T>。
   *
   * @example
   *   var opt: specialize TOptional<Integer>;
   *   opt := specialize TOptional<Integer>.Some(42);
   *   if opt.Valid then
   *     WriteLn('Value: ', opt.Value);
   *
   *   opt := specialize TOptional<Integer>.None;
   *   WriteLn('Default: ', opt.UnwrapOr(0));  // 输出: Default: 0
   *
   * @safety
   *   - 访问 None 状态的 Value 字段是未定义行为
   *   - 建议始终使用 Valid 检查或 UnwrapOr 方法
   *}
  generic TOptional<T> = record
  public
    Valid: Boolean;
    Value: T;

    {**
     * None
     *
     * @desc
     *   Creates an empty Optional (no value).
     *   创建空的 Optional（无值）。
     *
     * @returns
     *   An Optional with Valid = False.
     *}
    class function None: TOptional; static; inline;

    {**
     * Some
     *
     * @desc
     *   Creates an Optional containing the given value.
     *   创建包含给定值的 Optional。
     *
     * @param aValue
     *   The value to wrap.
     *
     * @returns
     *   An Optional with Valid = True and Value = aValue.
     *}
    class function Some(const aValue: T): TOptional; static; inline;

    {**
     * UnwrapOr
     *
     * @desc
     *   Returns the contained value if Valid, otherwise returns aDefault.
     *   如果 Valid 则返回包含的值，否则返回 aDefault。
     *
     * @param aDefault
     *   The default value to return if this Optional is None.
     *
     * @returns
     *   Value if Valid = True, otherwise aDefault.
     *
     * @safety
     *   - 永不引发异常
     *   - 永不访问无效的 Value 字段
     *}
    function UnwrapOr(const aDefault: T): T; inline;

    {**
     * IsSome
     *
     * @desc
     *   Returns True if this Optional contains a value.
     *   如果此 Optional 包含值则返回 True。
     *}
    function IsSome: Boolean; inline;

    {**
     * IsNone
     *
     * @desc
     *   Returns True if this Optional is empty.
     *   如果此 Optional 为空则返回 True。
     *}
    function IsNone: Boolean; inline;

    {**
     * Unwrap
     *
     * @desc
     *   Returns the contained value. Caller must ensure Valid = True.
     *   返回包含的值。调用者必须确保 Valid = True。
     *
     * @safety
     *   - 前置条件: Valid = True
     *   - 违反前置条件将导致未定义行为（返回垃圾值）
     *}
    function Unwrap: T; inline;
  end;

  // ============================================================================
  // TOverflowResult<T> - Rust (T, bool) Tuple Equivalent
  // ============================================================================

  {**
   * TOverflowResult<T>
   *
   * @desc
   *   A generic result type for overflowing arithmetic operations.
   *   Contains both the wrapped result value and an overflow flag.
   *   Equivalent to Rust's overflowing_* return type (T, bool).
   *
   *   溢出算术运算的泛型结果类型。
   *   包含环绕结果值和溢出标志。
   *   等价于 Rust 的 overflowing_* 返回类型 (T, bool)。
   *
   * @example
   *   var result: specialize TOverflowResult<UInt32>;
   *   result := OverflowingAddU32(High(UInt32), 1);
   *   WriteLn('Value: ', result.Value);       // 输出: Value: 0 (环绕)
   *   WriteLn('Overflowed: ', result.Overflowed);  // 输出: Overflowed: True
   *
   * @note
   *   Value 字段始终包含有效的环绕结果（2 补码语义）。
   *   Overflowed 标志指示是否发生了算术溢出。
   *}
  generic TOverflowResult<T> = record
  public
    Value: T;
    Overflowed: Boolean;

    {**
     * Create
     *
     * @desc
     *   Creates an overflow result with the given value and flag.
     *   创建具有给定值和标志的溢出结果。
     *}
    class function Create(const aValue: T; aOverflowed: Boolean): TOverflowResult; static; inline;
  end;

  // ============================================================================
  // Unsigned Integer Optional Types
  // ============================================================================

  TOptionalU8 = specialize TOptional<UInt8>;
  TOptionalU16 = specialize TOptional<UInt16>;
  TOptionalU32 = specialize TOptional<UInt32>;
  TOptionalU64 = specialize TOptional<UInt64>;
  TOptionalSizeUInt = specialize TOptional<SizeUInt>;

  // ============================================================================
  // Signed Integer Optional Types
  // ============================================================================

  TOptionalI8 = specialize TOptional<Int8>;
  TOptionalI16 = specialize TOptional<Int16>;
  TOptionalI32 = specialize TOptional<Int32>;
  TOptionalI64 = specialize TOptional<Int64>;
  TOptionalSizeInt = specialize TOptional<SizeInt>;

  // ============================================================================
  // Unsigned Integer Overflow Result Types
  // ============================================================================

  TOverflowU8 = specialize TOverflowResult<UInt8>;
  TOverflowU16 = specialize TOverflowResult<UInt16>;
  TOverflowU32 = specialize TOverflowResult<UInt32>;
  TOverflowU64 = specialize TOverflowResult<UInt64>;
  TOverflowSizeUInt = specialize TOverflowResult<SizeUInt>;

  // ============================================================================
  // Signed Integer Overflow Result Types
  // ============================================================================

  TOverflowI8 = specialize TOverflowResult<Int8>;
  TOverflowI16 = specialize TOverflowResult<Int16>;
  TOverflowI32 = specialize TOverflowResult<Int32>;
  TOverflowI64 = specialize TOverflowResult<Int64>;
  TOverflowSizeInt = specialize TOverflowResult<SizeInt>;

  // ============================================================================
  // Floating Point Optional Types
  // ============================================================================

  TOptionalF32 = specialize TOptional<Single>;
  TOptionalF64 = specialize TOptional<Double>;

  // ============================================================================
  // TCarryResult<T> - Carrying/Borrowing Arithmetic Result
  // ============================================================================

  {**
   * TCarryResult<T>
   *
   * @desc
   *   A generic result type for arithmetic operations with carry/borrow.
   *   Used for implementing multi-word arithmetic (big integers).
   *   Equivalent to Rust's carrying_add/borrowing_sub return type.
   *
   *   带进位/借位的算术运算泛型结果类型。
   *   用于实现多字算术（大整数）。
   *   等价于 Rust 的 carrying_add/borrowing_sub 返回类型。
   *
   * @example
   *   var result: TCarryResultU64;
   *   // Multi-word addition: a + b with carry propagation
   *   // 多字加法：a + b 带进位传播
   *   result := CarryingAddU64(low1, low2, False);
   *   high := high1 + high2;
   *   if result.Carry then
   *     Inc(high);  // Propagate carry to high word
   *
   * @safety
   *   - 永不引发异常 / Never raises exceptions
   *   - Carry 标志精确指示是否需要向高位传播
   *}
  generic TCarryResult<T> = record
  public
    Value: T;
    Carry: Boolean;

    {**
     * Create
     *
     * @desc
     *   Creates a carry result with the given value and carry flag.
     *   创建具有给定值和进位标志的进位结果。
     *}
    class function Create(const aValue: T; aCarry: Boolean): TCarryResult; static; inline;
  end;

  // ============================================================================
  // Carry Result Type Aliases
  // ============================================================================

  TCarryResultU8 = specialize TCarryResult<UInt8>;
  TCarryResultU16 = specialize TCarryResult<UInt16>;
  TCarryResultU32 = specialize TCarryResult<UInt32>;
  TCarryResultU64 = specialize TCarryResult<UInt64>;
  TCarryResultSizeUInt = specialize TCarryResult<SizeUInt>;

  // ============================================================================
  // TUInt128 - 128-bit Unsigned Integer (for Widening Multiplication)
  // ============================================================================

  {**
   * TUInt128
   *
   * @desc
   *   A 128-bit unsigned integer represented as two 64-bit parts.
   *   Used as the result type for widening multiplication of UInt64.
   *
   *   128 位无符号整数，由两个 64 位部分表示。
   *   用作 UInt64 扩展乘法的结果类型。
   *
   * @example
   *   var result: TUInt128;
   *   result := WideningMulU64(High(UInt64), 2);
   *   // result.Lo = low 64 bits
   *   // result.Hi = high 64 bits
   *
   * @note
   *   Value = Hi * 2^64 + Lo
   *}
  TUInt128 = record
    Lo: UInt64;  // Low 64 bits
    Hi: UInt64;  // High 64 bits
  end;

implementation

// ============================================================================
// TOptional<T> Implementation
// ============================================================================

class function TOptional.None: TOptional;
begin
  Result.Valid := False;
  // Value is left uninitialized (undefined when Valid = False)
end;

class function TOptional.Some(const aValue: T): TOptional;
begin
  Result.Valid := True;
  Result.Value := aValue;
end;

function TOptional.UnwrapOr(const aDefault: T): T;
begin
  if Valid then
    Result := Value
  else
    Result := aDefault;
end;

function TOptional.IsSome: Boolean;
begin
  Result := Valid;
end;

function TOptional.IsNone: Boolean;
begin
  Result := not Valid;
end;

function TOptional.Unwrap: T;
begin
  // Precondition: Valid = True
  // No runtime check for performance - caller is responsible
  Result := Value;
end;

// ============================================================================
// TOverflowResult<T> Implementation
// ============================================================================

class function TOverflowResult.Create(const aValue: T; aOverflowed: Boolean): TOverflowResult;
begin
  Result.Value := aValue;
  Result.Overflowed := aOverflowed;
end;

// ============================================================================
// TCarryResult<T> Implementation
// ============================================================================

class function TCarryResult.Create(const aValue: T; aCarry: Boolean): TCarryResult;
begin
  Result.Value := aValue;
  Result.Carry := aCarry;
end;

end.

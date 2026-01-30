unit fafafa.core.math.safeint;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.math.base;

{**
 * fafafa.core.math.safeint - 安全整数算术
 *
 * @desc
 *   提供多种安全整数运算策略，防止溢出/下溢导致的未定义行为和安全漏洞。
 *   Provides multiple safe integer arithmetic strategies to prevent undefined behavior and security vulnerabilities from overflow/underflow.
 *
 * @strategies
 *   1. **Saturating（饱和）**: 溢出时返回类型的最大/最小值
 *      - 适用场景：图形处理、音频处理、物理模拟
 *      - 示例：255 + 10 = 255 (UInt8)
 *
 *   2. **Checked（检查）**: 返回 Optional，溢出时返回 None
 *      - 适用场景：金融计算、关键业务逻辑
 *      - 示例：CheckedAddU32(MAX_UINT32, 1) = None
 *
 *   3. **Overflowing（溢出标记）**: 返回结果和溢出标志
 *      - 适用场景：需要知道是否溢出但仍需结果
 *      - 示例：OverflowingAddU32(MAX_UINT32, 1) = (0, True)
 *
 *   4. **Wrapping（环绕）**: 使用模运算，允许溢出环绕
 *      - 适用场景：哈希计算、循环计数器
 *      - 示例：WrappingAddU32(MAX_UINT32, 1) = 0
 *
 * @usage
 *   // 饱和运算 - 图形处理
 *   var Color: UInt8;
 *   Color := SaturatingAdd(200, 100);  // 返回 255，不会溢出
 *
 *   // 检查运算 - 金融计算
 *   var Result: TOptionalU32;
 *   Result := CheckedAddU32(Balance, Amount);
 *   if Result.IsSome then
 *     Balance := Result.Value
 *   else
 *     raise EOverflow.Create('Balance overflow');
 *
 *   // 溢出标记 - 需要知道是否溢出
 *   var Overflow: TOverflowU32;
 *   Overflow := OverflowingAddU32(A, B);
 *   if Overflow.Overflowed then
 *     WriteLn('Overflow detected, wrapped result: ', Overflow.Value);
 *
 *   // 环绕运算 - 哈希计算
 *   Hash := WrappingMulU32(Hash, 31);
 *   Hash := WrappingAddU32(Hash, Ord(Ch));
 *
 * @performance
 *   - Saturating: 1-2 条件分支
 *   - Checked: 1 条件分支 + Optional 构造
 *   - Overflowing: 1 条件检查
 *   - Wrapping: 0 额外开销（编译器优化）
 *
 * @thread_safety
 *   所有函数都是纯函数，线程安全。
 *   All functions are pure and thread-safe.
 *
 * @see fafafa.core.math, fafafa.core.math.base, TOptional, TOverflowResult
 *}

function IsAddOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$IFDEF CPU64}
function IsAddOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

function IsSubUnderflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$IFDEF CPU64}
function IsSubUnderflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

function IsMulOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$IFDEF CPU64}
function IsMulOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

function SaturatingAdd(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$IFDEF CPU64}
function SaturatingAdd(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

function SaturatingSub(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$IFDEF CPU64}
function SaturatingSub(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

function SaturatingMul(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$IFDEF CPU64}
function SaturatingMul(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

// Int32 Saturating operations
function SaturatingAdd(aA, aB: Int32): Int32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: Int32): Int32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: Int32): Int32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// Stub declarations for Windows compilation
function CheckedAddU32(aA, aB: UInt32): TOptionalU32;
function CheckedSubU32(aA, aB: UInt32): TOptionalU32;
function CheckedMulU32(aA, aB: UInt32): TOptionalU32;
function CheckedDivU32(aA, aB: UInt32): TOptionalU32;
function CheckedAddU64(aA, aB: UInt64): TOptionalU64;
function CheckedSubU64(aA, aB: UInt64): TOptionalU64;
function CheckedMulU64(aA, aB: UInt64): TOptionalU64;
function CheckedDivU64(aA, aB: UInt64): TOptionalU64;
function CheckedAddI32(aA, aB: Int32): TOptionalI32;
function CheckedSubI32(aA, aB: Int32): TOptionalI32;
function CheckedMulI32(aA, aB: Int32): TOptionalI32;
function CheckedDivI32(aA, aB: Int32): TOptionalI32;
function CheckedNegI32(aA: Int32): TOptionalI32;
function CheckedAddI64(aA, aB: Int64): TOptionalI64;
function CheckedSubI64(aA, aB: Int64): TOptionalI64;
function CheckedMulI64(aA, aB: Int64): TOptionalI64;
function CheckedDivI64(aA, aB: Int64): TOptionalI64;
function CheckedNegI64(aA: Int64): TOptionalI64;
function OverflowingAddU32(aA, aB: UInt32): TOverflowU32;
function OverflowingSubU32(aA, aB: UInt32): TOverflowU32;
function OverflowingMulU32(aA, aB: UInt32): TOverflowU32;
function OverflowingAddU64(aA, aB: UInt64): TOverflowU64;
function OverflowingSubU64(aA, aB: UInt64): TOverflowU64;
function OverflowingMulU64(aA, aB: UInt64): TOverflowU64;
function OverflowingAddI32(aA, aB: Int32): TOverflowI32;
function OverflowingSubI32(aA, aB: Int32): TOverflowI32;
function OverflowingMulI32(aA, aB: Int32): TOverflowI32;
function OverflowingNegI32(aA: Int32): TOverflowI32;
function OverflowingAddI64(aA, aB: Int64): TOverflowI64;
function OverflowingSubI64(aA, aB: Int64): TOverflowI64;
function OverflowingMulI64(aA, aB: Int64): TOverflowI64;
function OverflowingNegI64(aA: Int64): TOverflowI64;
function WrappingAddU32(aA, aB: UInt32): UInt32;
function WrappingSubU32(aA, aB: UInt32): UInt32;
function WrappingMulU32(aA, aB: UInt32): UInt32;
function WrappingAddU64(aA, aB: UInt64): UInt64;
function WrappingSubU64(aA, aB: UInt64): UInt64;
function WrappingMulU64(aA, aB: UInt64): UInt64;
function WrappingAddI32(aA, aB: Int32): Int32;
function WrappingSubI32(aA, aB: Int32): Int32;
function WrappingMulI32(aA, aB: Int32): Int32;
function WrappingNegI32(aA: Int32): Int32;
function WrappingAddI64(aA, aB: Int64): Int64;
function WrappingSubI64(aA, aB: Int64): Int64;
function WrappingMulI64(aA, aB: Int64): Int64;
function WrappingNegI64(aA: Int64): Int64;
function CarryingAddU32(aA, aB: UInt32; aCarryIn: Boolean): TCarryResultU32;
function BorrowingSubU32(aA, aB: UInt32; aBorrowIn: Boolean): TCarryResultU32;
function CarryingAddU64(aA, aB: UInt64; aCarryIn: Boolean): TCarryResultU64;
function BorrowingSubU64(aA, aB: UInt64; aBorrowIn: Boolean): TCarryResultU64;
function WideningMulU32(aA, aB: UInt32): UInt64;
function WideningMulI32(aA, aB: Int32): Int64;
function WideningMulU64(aA, aB: UInt64): TUInt128;
function DivEuclidI32(aA, aB: Int32): Int32;
function RemEuclidI32(aA, aB: Int32): Int32;
function CheckedDivEuclidI32(aA, aB: Int32): TOptionalI32;
function CheckedRemEuclidI32(aA, aB: Int32): TOptionalI32;
function DivEuclidI64(aA, aB: Int64): Int64;
function RemEuclidI64(aA, aB: Int64): Int64;
function CheckedDivEuclidI64(aA, aB: Int64): TOptionalI64;
function CheckedRemEuclidI64(aA, aB: Int64): TOptionalI64;

implementation

function IsAddOverflow(aA, aB: SizeUInt): Boolean;
begin
  Result := aA > (MAX_SIZE_UINT - aB);
end;

{$IFDEF CPU64}
function IsAddOverflow(aA, aB: UInt32): Boolean;
begin
  Result := aA > (MAX_UINT32 - aB);
end;
{$ENDIF}

function IsSubUnderflow(aA, aB: SizeUInt): Boolean;
begin
  Result := aA < aB;
end;

{$IFDEF CPU64}
function IsSubUnderflow(aA, aB: UInt32): Boolean;
begin
  Result := aA < aB;
end;
{$ENDIF}

function IsMulOverflow(aA, aB: SizeUInt): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_SIZE_UINT div aB);
end;

{$IFDEF CPU64}
function IsMulOverflow(aA, aB: UInt32): Boolean;
  {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
var
  Hi: UInt32;
begin
  // ✅ Phase 4.3 优化：使用 64 位乘法检测溢出
  // 将两个 32 位数相乘得到 64 位结果，如果高 32 位非零则发生溢出
  // 这比使用除法检测溢出快得多（消除除法操作 + 减少分支）
  Hi := UInt32((UInt64(aA) * UInt64(aB)) shr 32);
  Result := Hi <> 0;
end;
{$ENDIF}

function SaturatingAdd(aA, aB: SizeUInt): SizeUInt;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_SIZE_UINT
  else
    Result := aA + aB;
end;

{$IFDEF CPU64}
function SaturatingAdd(aA, aB: UInt32): UInt32;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_UINT32
  else
    Result := aA + aB;
end;
{$ENDIF}

function SaturatingSub(aA, aB: SizeUInt): SizeUInt;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

{$IFDEF CPU64}
function SaturatingSub(aA, aB: UInt32): UInt32;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;
{$ENDIF}

function SaturatingMul(aA, aB: SizeUInt): SizeUInt;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_SIZE_UINT
  else
    Result := aA * aB;
end;

{$IFDEF CPU64}
function SaturatingMul(aA, aB: UInt32): UInt32;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_UINT32
  else
    Result := aA * aB;
end;
{$ENDIF}

// Int32 Saturating operations - handle signed overflow/underflow
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

// ============================================================================
// Stub implementations for compilation
// These are temporary implementations to allow compilation on Windows
// TODO: Implement proper checked/overflowing/wrapping operations
// ============================================================================

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

// Signed 32-bit operations - use Int64 to detect overflow
function CheckedAddI32(aA, aB: Int32): TOptionalI32;
var
  LResult: Int64;
begin
  LResult := Int64(aA) + Int64(aB);
  if (LResult > MAX_INT32) or (LResult < MIN_INT32) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(Int32(LResult));
end;

function CheckedSubI32(aA, aB: Int32): TOptionalI32;
var
  LResult: Int64;
begin
  LResult := Int64(aA) - Int64(aB);
  if (LResult > MAX_INT32) or (LResult < MIN_INT32) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(Int32(LResult));
end;

function CheckedMulI32(aA, aB: Int32): TOptionalI32;
var
  LResult: Int64;
begin
  LResult := Int64(aA) * Int64(aB);
  if (LResult > MAX_INT32) or (LResult < MIN_INT32) then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(Int32(LResult));
end;

function CheckedDivI32(aA, aB: Int32): TOptionalI32;
begin
  if aB = 0 then
    Result := TOptionalI32.None
  else if (aA = MIN_INT32) and (aB = -1) then
    Result := TOptionalI32.None  // MIN_INT32 / -1 overflows
  else
    Result := TOptionalI32.Some(aA div aB);
end;

function CheckedNegI32(aA: Int32): TOptionalI32;
begin
  if aA = MIN_INT32 then
    Result := TOptionalI32.None  // -MIN_INT32 overflows
  else
    Result := TOptionalI32.Some(-aA);
end;

// Signed 64-bit operations - use overflow detection logic
function CheckedAddI64(aA, aB: Int64): TOptionalI64;
begin
  // Overflow if: (aA > 0 and aB > MAX - aA) or (aA < 0 and aB < MIN - aA)
  if (aB > 0) and (aA > MAX_INT64 - aB) then
    Result := TOptionalI64.None
  else if (aB < 0) and (aA < MIN_INT64 - aB) then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(aA + aB);
end;

function CheckedSubI64(aA, aB: Int64): TOptionalI64;
begin
  // Overflow if: (aB < 0 and aA > MAX + aB) or (aB > 0 and aA < MIN + aB)
  if (aB < 0) and (aA > MAX_INT64 + aB) then
    Result := TOptionalI64.None
  else if (aB > 0) and (aA < MIN_INT64 + aB) then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(aA - aB);
end;

function CheckedMulI64(aA, aB: Int64): TOptionalI64;
begin
  // Special cases for multiplication overflow detection
  if (aA = 0) or (aB = 0) then
    Result := TOptionalI64.Some(0)
  else if (aA = MIN_INT64) then
  begin
    if aB <> 1 then
      Result := TOptionalI64.None
    else
      Result := TOptionalI64.Some(aA);
  end
  else if (aB = MIN_INT64) then
  begin
    if aA <> 1 then
      Result := TOptionalI64.None
    else
      Result := TOptionalI64.Some(aB);
  end
  else if (aA > 0) and (aB > 0) then
  begin
    if aA > MAX_INT64 div aB then
      Result := TOptionalI64.None
    else
      Result := TOptionalI64.Some(aA * aB);
  end
  else if (aA < 0) and (aB < 0) then
  begin
    if aA < MAX_INT64 div aB then
      Result := TOptionalI64.None
    else
      Result := TOptionalI64.Some(aA * aB);
  end
  else if (aA > 0) and (aB < 0) then
  begin
    if aB < MIN_INT64 div aA then
      Result := TOptionalI64.None
    else
      Result := TOptionalI64.Some(aA * aB);
  end
  else // aA < 0 and aB > 0
  begin
    if aA < MIN_INT64 div aB then
      Result := TOptionalI64.None
    else
      Result := TOptionalI64.Some(aA * aB);
  end;
end;

function CheckedDivI64(aA, aB: Int64): TOptionalI64;
begin
  if aB = 0 then
    Result := TOptionalI64.None
  else if (aA = MIN_INT64) and (aB = -1) then
    Result := TOptionalI64.None  // MIN_INT64 / -1 overflows
  else
    Result := TOptionalI64.Some(aA div aB);
end;

function CheckedNegI64(aA: Int64): TOptionalI64;
begin
  if aA = MIN_INT64 then
    Result := TOptionalI64.None  // -MIN_INT64 overflows
  else
    Result := TOptionalI64.Some(-aA);
end;

// Overflowing operations (return value + overflow flag)
// Use {$R-} to disable range checking for these operations
function OverflowingAddU32(aA, aB: UInt32): TOverflowU32;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := IsAddOverflow(aA, aB);
  Result.Value := aA + aB;
end;
{$POP}

function OverflowingSubU32(aA, aB: UInt32): TOverflowU32;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := IsSubUnderflow(aA, aB);
  Result.Value := aA - aB;
end;
{$POP}

function OverflowingMulU32(aA, aB: UInt32): TOverflowU32;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := IsMulOverflow(aA, aB);
  Result.Value := aA * aB;
end;
{$POP}

function OverflowingAddU64(aA, aB: UInt64): TOverflowU64;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := IsAddOverflow(aA, aB);
  Result.Value := aA + aB;
end;
{$POP}

function OverflowingSubU64(aA, aB: UInt64): TOverflowU64;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := IsSubUnderflow(aA, aB);
  Result.Value := aA - aB;
end;
{$POP}

function OverflowingMulU64(aA, aB: UInt64): TOverflowU64;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := IsMulOverflow(aA, aB);
  Result.Value := aA * aB;
end;
{$POP}

function OverflowingAddI32(aA, aB: Int32): TOverflowI32;
var
  LResult: Int64;
{$PUSH}{$R-}{$Q-}
begin
  LResult := Int64(aA) + Int64(aB);
  Result.Overflowed := (LResult > MAX_INT32) or (LResult < MIN_INT32);
  Result.Value := Int32(LResult);  // Truncate to Int32
end;
{$POP}

function OverflowingSubI32(aA, aB: Int32): TOverflowI32;
var
  LResult: Int64;
{$PUSH}{$R-}{$Q-}
begin
  LResult := Int64(aA) - Int64(aB);
  Result.Overflowed := (LResult > MAX_INT32) or (LResult < MIN_INT32);
  Result.Value := Int32(LResult);  // Truncate to Int32
end;
{$POP}

function OverflowingMulI32(aA, aB: Int32): TOverflowI32;
var
  LResult: Int64;
{$PUSH}{$R-}{$Q-}
begin
  LResult := Int64(aA) * Int64(aB);
  Result.Overflowed := (LResult > MAX_INT32) or (LResult < MIN_INT32);
  Result.Value := Int32(LResult);  // Truncate to Int32
end;
{$POP}

function OverflowingNegI32(aA: Int32): TOverflowI32;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := (aA = MIN_INT32);
  if aA = MIN_INT32 then
    Result.Value := MIN_INT32  // -MIN_INT32 wraps to MIN_INT32
  else
    Result.Value := -aA;
end;
{$POP}

function OverflowingAddI64(aA, aB: Int64): TOverflowI64;
{$PUSH}{$R-}{$Q-}
begin
  // Detect overflow before operation
  if (aB > 0) and (aA > MAX_INT64 - aB) then
    Result.Overflowed := True
  else if (aB < 0) and (aA < MIN_INT64 - aB) then
    Result.Overflowed := True
  else
    Result.Overflowed := False;
  Result.Value := aA + aB;
end;
{$POP}

function OverflowingSubI64(aA, aB: Int64): TOverflowI64;
{$PUSH}{$R-}{$Q-}
begin
  // Detect overflow before operation
  if (aB < 0) and (aA > MAX_INT64 + aB) then
    Result.Overflowed := True
  else if (aB > 0) and (aA < MIN_INT64 + aB) then
    Result.Overflowed := True
  else
    Result.Overflowed := False;
  Result.Value := aA - aB;
end;
{$POP}

function OverflowingMulI64(aA, aB: Int64): TOverflowI64;
{$PUSH}{$R-}{$Q-}
begin
  // Detect overflow before operation
  if (aA = 0) or (aB = 0) then
    Result.Overflowed := False
  else if (aA = MIN_INT64) then
    Result.Overflowed := (aB <> 1)
  else if (aB = MIN_INT64) then
    Result.Overflowed := (aA <> 1)
  else if (aA > 0) and (aB > 0) then
    Result.Overflowed := (aA > MAX_INT64 div aB)
  else if (aA < 0) and (aB < 0) then
    Result.Overflowed := (aA < MAX_INT64 div aB)
  else if (aA > 0) and (aB < 0) then
    Result.Overflowed := (aB < MIN_INT64 div aA)
  else // aA < 0 and aB > 0
    Result.Overflowed := (aA < MIN_INT64 div aB);
  Result.Value := aA * aB;
end;
{$POP}

function OverflowingNegI64(aA: Int64): TOverflowI64;
{$PUSH}{$R-}{$Q-}
begin
  Result.Overflowed := (aA = MIN_INT64);
  if aA = MIN_INT64 then
    Result.Value := MIN_INT64  // -MIN_INT64 wraps to MIN_INT64
  else
    Result.Value := -aA;
end;
{$POP}

// Wrapping operations (just do the operation, overflow wraps)
// Use {$R-}{$Q-} to disable range and overflow checking
function WrappingAddU32(aA, aB: UInt32): UInt32;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA + aB;
end;
{$POP}

function WrappingSubU32(aA, aB: UInt32): UInt32;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA - aB;
end;
{$POP}

function WrappingMulU32(aA, aB: UInt32): UInt32;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA * aB;
end;
{$POP}

function WrappingAddU64(aA, aB: UInt64): UInt64;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA + aB;
end;
{$POP}

function WrappingSubU64(aA, aB: UInt64): UInt64;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA - aB;
end;
{$POP}

function WrappingMulU64(aA, aB: UInt64): UInt64;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA * aB;
end;
{$POP}

function WrappingAddI32(aA, aB: Int32): Int32;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA + aB;
end;
{$POP}

function WrappingSubI32(aA, aB: Int32): Int32;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA - aB;
end;
{$POP}

function WrappingMulI32(aA, aB: Int32): Int32;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA * aB;
end;
{$POP}

function WrappingNegI32(aA: Int32): Int32;
{$PUSH}{$R-}{$Q-}
begin
  Result := -aA;
end;
{$POP}

function WrappingAddI64(aA, aB: Int64): Int64;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA + aB;
end;
{$POP}

function WrappingSubI64(aA, aB: Int64): Int64;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA - aB;
end;
{$POP}

function WrappingMulI64(aA, aB: Int64): Int64;
{$PUSH}{$R-}{$Q-}
begin
  Result := aA * aB;
end;
{$POP}

function WrappingNegI64(aA: Int64): Int64;
{$PUSH}{$R-}{$Q-}
begin
  Result := -aA;
end;
{$POP}

// Carrying/borrowing operations
function CarryingAddU32(aA, aB: UInt32; aCarryIn: Boolean): TCarryResultU32;
var
  C: UInt32;
begin
  C := Ord(aCarryIn);
  Result.Value := aA + aB + C;
  Result.Carry := (aA > High(UInt32) - aB) or ((aA + aB) > High(UInt32) - C);
end;

function BorrowingSubU32(aA, aB: UInt32; aBorrowIn: Boolean): TCarryResultU32;
var
  B: UInt32;
begin
  B := Ord(aBorrowIn);
  Result.Value := aA - aB - B;
  Result.Carry := (aA < aB) or ((aA - aB) < B);
end;

function CarryingAddU64(aA, aB: UInt64; aCarryIn: Boolean): TCarryResultU64;
var
  C: UInt64;
begin
  C := Ord(aCarryIn);
  Result.Value := aA + aB + C;
  Result.Carry := (aA > High(UInt64) - aB) or ((aA + aB) > High(UInt64) - C);
end;

function BorrowingSubU64(aA, aB: UInt64; aBorrowIn: Boolean): TCarryResultU64;
var
  B: UInt64;
begin
  B := Ord(aBorrowIn);
  Result.Value := aA - aB - B;
  Result.Carry := (aA < aB) or ((aA - aB) < B);
end;

// Widening multiplication
function WideningMulU32(aA, aB: UInt32): UInt64;
begin
  Result := UInt64(aA) * UInt64(aB);
end;

function WideningMulI32(aA, aB: Int32): Int64;
begin
  Result := Int64(aA) * Int64(aB);
end;

function WideningMulU64(aA, aB: UInt64): TUInt128;
begin
  // Simple implementation: returns low 64 bits, high bits set to 0
  // Full 128-bit multiply would require extended precision arithmetic
  Result.Lo := aA * aB;
  Result.Hi := 0;  // Stub: proper implementation needs multi-precision math
end;

// Euclidean division for signed integers
function DivEuclidI32(aA, aB: Int32): Int32;
  {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
var
  R: Int32;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.3 优化：仅在 Debug 模式保留除零检查
  if aB = 0 then
    raise EDivByZero.Create('Division by zero');
  {$ENDIF}

  // ✅ Phase 4.3 优化：计算商和余数
  Result := aA div aB;
  R := aA mod aB;

  // ✅ Phase 4.3 优化：使用 XOR 位运算简化符号检查
  // (aA xor aB) < 0 等价于 (aA < 0) <> (aB < 0)，但更高效
  // 如果余数非零且 aA 和 aB 符号不同，则商减 1
  if (R <> 0) and ((aA xor aB) < 0) then
    Result := Result - 1;
end;

function RemEuclidI32(aA, aB: Int32): Int32;
  {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
var
  R: Int32;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.3 优化：仅在 Debug 模式保留除零检查
  if aB = 0 then
    raise EDivByZero.Create('Division by zero');
  {$ENDIF}

  R := aA mod aB;

  // ✅ Phase 4.3 优化：简化嵌套分支逻辑
  // Euclidean remainder is always non-negative
  if R < 0 then
  begin
    // 如果 aB > 0，则 R + aB；否则 R - aB
    if aB > 0 then
      Result := R + aB
    else
      Result := R - aB;
  end
  else
    Result := R;
end;

function CheckedDivEuclidI32(aA, aB: Int32): TOptionalI32;
begin
  if aB = 0 then
    Exit(TOptionalI32.None);
  Result := TOptionalI32.Some(DivEuclidI32(aA, aB));
end;

function CheckedRemEuclidI32(aA, aB: Int32): TOptionalI32;
begin
  if aB = 0 then
    Exit(TOptionalI32.None);
  Result := TOptionalI32.Some(RemEuclidI32(aA, aB));
end;

function DivEuclidI64(aA, aB: Int64): Int64;
begin
  if aB = 0 then
    raise EDivByZero.Create('Division by zero');
  Result := aA div aB;
  if ((aA mod aB) <> 0) and ((aA < 0) <> (aB < 0)) then
    Result := Result - 1;
end;

function RemEuclidI64(aA, aB: Int64): Int64;
var
  R: Int64;
begin
  if aB = 0 then
    raise EDivByZero.Create('Division by zero');
  R := aA mod aB;
  if R < 0 then
  begin
    if aB > 0 then
      Result := R + aB
    else
      Result := R - aB;
  end
  else
    Result := R;
end;

function CheckedDivEuclidI64(aA, aB: Int64): TOptionalI64;
begin
  if aB = 0 then
    Exit(TOptionalI64.None);
  Result := TOptionalI64.Some(DivEuclidI64(aA, aB));
end;

function CheckedRemEuclidI64(aA, aB: Int64): TOptionalI64;
begin
  if aB = 0 then
    Exit(TOptionalI64.None);
  Result := TOptionalI64.Some(RemEuclidI64(aA, aB));
end;

end.

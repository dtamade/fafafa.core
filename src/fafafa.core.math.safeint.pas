unit fafafa.core.math.safeint;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.math.base;

{**
 * 安全整数算术（基线实现）
 *
 * 说明：
 * - 本单元提供 overflow/underflow 检测与 saturating 运算。
 * - `fafafa.core.math` 作为统一入口会 re-export/转发这些 API。
 * - 后续若引入 SIMD/平台优化，应保持语义不变，并以测试为准。
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
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_UINT32 div aB);
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

// Signed 32-bit operations
function CheckedAddI32(aA, aB: Int32): TOptionalI32;
begin
  Result := TOptionalI32.Some(aA + aB); // Stub
end;

function CheckedSubI32(aA, aB: Int32): TOptionalI32;
begin
  Result := TOptionalI32.Some(aA - aB); // Stub
end;

function CheckedMulI32(aA, aB: Int32): TOptionalI32;
begin
  Result := TOptionalI32.Some(aA * aB); // Stub
end;

function CheckedDivI32(aA, aB: Int32): TOptionalI32;
begin
  if aB = 0 then
    Result := TOptionalI32.None
  else
    Result := TOptionalI32.Some(aA div aB);
end;

function CheckedNegI32(aA: Int32): TOptionalI32;
begin
  Result := TOptionalI32.Some(-aA); // Stub
end;

// Signed 64-bit operations
function CheckedAddI64(aA, aB: Int64): TOptionalI64;
begin
  Result := TOptionalI64.Some(aA + aB); // Stub
end;

function CheckedSubI64(aA, aB: Int64): TOptionalI64;
begin
  Result := TOptionalI64.Some(aA - aB); // Stub
end;

function CheckedMulI64(aA, aB: Int64): TOptionalI64;
begin
  Result := TOptionalI64.Some(aA * aB); // Stub
end;

function CheckedDivI64(aA, aB: Int64): TOptionalI64;
begin
  if aB = 0 then
    Result := TOptionalI64.None
  else
    Result := TOptionalI64.Some(aA div aB);
end;

function CheckedNegI64(aA: Int64): TOptionalI64;
begin
  Result := TOptionalI64.Some(-aA); // Stub
end;

// Overflowing operations (return value + overflow flag)
function OverflowingAddU32(aA, aB: UInt32): TOverflowU32;
begin
  Result.Overflowed := IsAddOverflow(aA, aB);
  Result.Value := aA + aB;
end;

function OverflowingSubU32(aA, aB: UInt32): TOverflowU32;
begin
  Result.Overflowed := IsSubUnderflow(aA, aB);
  Result.Value := aA - aB;
end;

function OverflowingMulU32(aA, aB: UInt32): TOverflowU32;
begin
  Result.Overflowed := IsMulOverflow(aA, aB);
  Result.Value := aA * aB;
end;

function OverflowingAddU64(aA, aB: UInt64): TOverflowU64;
begin
  Result.Overflowed := IsAddOverflow(aA, aB);
  Result.Value := aA + aB;
end;

function OverflowingSubU64(aA, aB: UInt64): TOverflowU64;
begin
  Result.Overflowed := IsSubUnderflow(aA, aB);
  Result.Value := aA - aB;
end;

function OverflowingMulU64(aA, aB: UInt64): TOverflowU64;
begin
  Result.Overflowed := IsMulOverflow(aA, aB);
  Result.Value := aA * aB;
end;

function OverflowingAddI32(aA, aB: Int32): TOverflowI32;
begin
  Result.Overflowed := False; // Stub
  Result.Value := aA + aB;
end;

function OverflowingSubI32(aA, aB: Int32): TOverflowI32;
begin
  Result.Overflowed := False; // Stub
  Result.Value := aA - aB;
end;

function OverflowingMulI32(aA, aB: Int32): TOverflowI32;
begin
  Result.Overflowed := False; // Stub
  Result.Value := aA * aB;
end;

function OverflowingNegI32(aA: Int32): TOverflowI32;
begin
  Result.Overflowed := False; // Stub
  Result.Value := -aA;
end;

function OverflowingAddI64(aA, aB: Int64): TOverflowI64;
begin
  Result.Overflowed := False; // Stub
  Result.Value := aA + aB;
end;

function OverflowingSubI64(aA, aB: Int64): TOverflowI64;
begin
  Result.Overflowed := False; // Stub
  Result.Value := aA - aB;
end;

function OverflowingMulI64(aA, aB: Int64): TOverflowI64;
begin
  Result.Overflowed := False; // Stub
  Result.Value := aA * aB;
end;

function OverflowingNegI64(aA: Int64): TOverflowI64;
begin
  Result.Overflowed := False; // Stub
  Result.Value := -aA;
end;

// Wrapping operations (just do the operation, overflow wraps)
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
begin
  if aB = 0 then
    raise EDivByZero.Create('Division by zero');
  Result := aA div aB;
  // Adjust for negative divisor to ensure remainder is always non-negative
  if ((aA mod aB) <> 0) and ((aA < 0) <> (aB < 0)) then
    Result := Result - 1;
end;

function RemEuclidI32(aA, aB: Int32): Int32;
var
  R: Int32;
begin
  if aB = 0 then
    raise EDivByZero.Create('Division by zero');
  R := aA mod aB;
  // Euclidean remainder is always non-negative
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

// === Scalar Fallback ===
// Used when:
// - not CPUAARCH64, or
// - CPUAARCH64 but FAFAFA_SIMD_NEON_ASM is not enabled, or
// - SIMD_VECTOR_ASM_DISABLED is defined.

function NEONAddF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function NEONSubF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function NEONMulF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function NEONDivF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] / b.f[i];
end;

function NEONAddF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONAddF32x4(a.lo, b.lo);
  Result.hi := NEONAddF32x4(a.hi, b.hi);
end;

function NEONSubF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONSubF32x4(a.lo, b.lo);
  Result.hi := NEONSubF32x4(a.hi, b.hi);
end;

function NEONMulF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONMulF32x4(a.lo, b.lo);
  Result.hi := NEONMulF32x4(a.hi, b.hi);
end;

function NEONDivF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONDivF32x4(a.lo, b.lo);
  Result.hi := NEONDivF32x4(a.hi, b.hi);
end;

function NEONAddF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function NEONSubF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function NEONMulF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function NEONDivF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// Integer SIMD operations must wrap on overflow (hardware semantics).
{$PUSH}{$R-}{$Q-}
function NEONAddI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function NEONSubI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function NEONMulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] * b.i[i];
end;
{$POP}

{$I fafafa.core.simd.neon.scalar.compare.inc}

{$I fafafa.core.simd.neon.scalar.math.inc}

{$I fafafa.core.simd.neon.scalar.ext_math.inc}

{$I fafafa.core.simd.neon.scalar.vector_math.inc}

{$I fafafa.core.simd.neon.scalar.reduction.inc}

{$I fafafa.core.simd.neon.scalar.memory.inc}

{$I fafafa.core.simd.neon.scalar.utility.inc}

{$I fafafa.core.simd.neon.scalar.autowrap.inc}

{$I fafafa.core.simd.neon.scalar.wide_reduce.inc}

{$I fafafa.core.simd.neon.scalar.wide_memory.inc}

{$ENDIF} // FAFAFA_SIMD_NEON_ASM_ENABLED (256/512-bit ASM implementations)

{$ENDIF} // FAFAFA_SIMD_NEON_ASM_ENABLED


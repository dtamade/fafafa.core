unit fafafa.core.simd.sse3;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// === SSE3 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 SSE3 instructions.
// SSE3 (Prescott New Instructions) adds horizontal operations for faster reductions.
//
// Key SSE3 instructions:
// - HADDPS/HSUBPS: Horizontal add/sub for F32 (faster reductions)
// - HADDPD/HSUBPD: Horizontal add/sub for F64
// - MOVDDUP: Duplicate low F64 to both lanes
// - MOVSLDUP/MOVSHDUP: Duplicate even/odd F32 elements
// - LDDQU: Optimized unaligned load for cache-line crossing
// - ADDSUBPS/ADDSUBPD: Alternating add/sub (useful for complex arithmetic)

procedure RegisterSSE3Backend;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.scalar,
  fafafa.core.simd.sse2;

// === SSE3 Horizontal Arithmetic ===
// These operations are the main benefit of SSE3 over SSE2

// Horizontal add: [a0+a1, a2+a3, b0+b1, b2+b3]
function SSE3HAddF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    haddps xmm0, xmm1
    movups [result], xmm0
  end;
end;

// Horizontal sub: [a0-a1, a2-a3, b0-b1, b2-b3]
function SSE3HSubF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    hsubps xmm0, xmm1
    movups [result], xmm0
  end;
end;

// Horizontal add for F64: [a0+a1, b0+b1]
function SSE3HAddF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    haddpd xmm0, xmm1
    movupd [result], xmm0
  end;
end;

// Horizontal sub for F64: [a0-a1, b0-b1]
function SSE3HSubF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    hsubpd xmm0, xmm1
    movupd [result], xmm0
  end;
end;

// === SSE3 Optimized Reductions ===
// SSE3's HADD makes horizontal reductions more efficient

// Sum all 4 floats using SSE3 horizontal add (faster than SSE2 shuffle method)
function SSE3ReduceAddF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    haddps  xmm0, xmm0     // [a0+a1, a2+a3, a0+a1, a2+a3]
    haddps  xmm0, xmm0     // [sum, sum, sum, sum]
    movss   [result], xmm0
  end;
end;

// Sum both doubles using SSE3 horizontal add
function SSE3ReduceAddF64x2(const a: TVecF64x2): Double;
begin
  asm
    lea     rax, a
    movupd  xmm0, [rax]
    haddpd  xmm0, xmm0     // [a0+a1, a0+a1]
    movsd   [result], xmm0
  end;
end;

// === SSE3 Alternating Operations ===
// Useful for complex number arithmetic

// Alternating add/sub: [a0-b0, a1+b1, a2-b2, a3+b3]
function SSE3AddSubF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    addsubps xmm0, xmm1
    movups [result], xmm0
  end;
end;

// Alternating add/sub for F64: [a0-b0, a1+b1]
function SSE3AddSubF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    addsubpd xmm0, xmm1
    movupd [result], xmm0
  end;
end;

// === SSE3 Data Movement ===

// Duplicate low double to both lanes: [a0, a0]
function SSE3MovDupF64x2(const a: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    movddup xmm0, [rax]
    movupd [result], xmm0
  end;
end;

// Duplicate even elements: [a0, a0, a2, a2]
function SSE3MovSLDupF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movsldup xmm0, [rax]
    movups [result], xmm0
  end;
end;

// Duplicate odd elements: [a1, a1, a3, a3]
function SSE3MovSHDupF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movshdup xmm0, [rax]
    movups [result], xmm0
  end;
end;

// === SSE3 Optimized Dot Product ===
// Using HADD for final reduction

function SSE3DotF32x4(const a, b: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    lea     rdx, b
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1      // Element-wise multiply
    haddps  xmm0, xmm0      // [a0*b0+a1*b1, a2*b2+a3*b3, ...]
    haddps  xmm0, xmm0      // [sum, sum, sum, sum]
    movss   [result], xmm0
  end;
end;

function SSE3DotF32x3(const a, b: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    lea     rdx, b
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    // Zero the w component
    xorps   xmm2, xmm2
    insertps xmm0, xmm2, $30  // Zero element 3 (SSE4.1 would be better, fallback)
  end;
  // Fallback: use mask to zero w
  asm
    lea     rax, a
    lea     rdx, b
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1
    // Zero w by clearing high bits
    pcmpeqd xmm2, xmm2
    psrldq  xmm2, 4           // Mask: [FF, FF, FF, 00]
    andps   xmm0, xmm2
    haddps  xmm0, xmm0
    haddps  xmm0, xmm0
    movss   [result], xmm0
  end;
end;

// === SSE3 Optimized Length ===

function SSE3LengthF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    mulps   xmm0, xmm0      // Square each element
    haddps  xmm0, xmm0      // Sum pairs
    haddps  xmm0, xmm0      // Sum all
    sqrtss  xmm0, xmm0      // Square root
    movss   [result], xmm0
  end;
end;

// === Backend Registration ===

procedure RegisterSSE3Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSE3 is available
  if not HasSSE3 then
    Exit;

  // Start with SSE2 as base (SSE3 is a superset)
  // We copy the registered SSE2 table and enhance it
  FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbSSE3;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSE3;
    Name := 'SSE3';
    Description := 'x86-64 SSE3 SIMD implementation (horizontal ops)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction, scLoadStore];
    Available := True;
    Priority := 15; // Higher than SSE2 (10)
  end;

  // SSE3 improvements: faster reductions via HADD
  if IsVectorAsmEnabled then
  begin
    // Override reduction operations with SSE3 HADD versions (faster)
    dispatchTable.ReduceAddF32x4 := @SSE3ReduceAddF32x4;
    // TODO: Add ReduceAddF64x2 to dispatch table when F64x2 support is added
    // dispatchTable.ReduceAddF64x2 := @SSE3ReduceAddF64x2;

    // Override dot product with SSE3 version (uses HADD)
    dispatchTable.DotF32x4 := @SSE3DotF32x4;

    // Override length with SSE3 version
    dispatchTable.LengthF32x4 := @SSE3LengthF32x4;
  end;

  // Note: SSE3 also enables:
  // - dispatchTable.HAddF32x4 := @SSE3HAddF32x4;
  // - dispatchTable.HSubF32x4 := @SSE3HSubF32x4;
  // - dispatchTable.AddSubF32x4 := @SSE3AddSubF32x4;
  // These would need to be added to TSimdDispatchTable if horizontal ops are exposed

  // Register the backend
  RegisterBackend(sbSSE3, dispatchTable);
end;

initialization
  RegisterSSE3Backend;
  RegisterBackendRebuilder(sbSSE3, @RegisterSSE3Backend);

end.

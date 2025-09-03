unit fafafa.core.simd.intrinsics.x86.sse3;

{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_SSE3_AVAILABLE}

// === SSE3 Intrinsics 实现 ===
// SSE3 主要添加了水平操作和一些特殊的加载指令
// 对于字节级操作用处不大，主要用于浮点运算

uses
  fafafa.core.simd.intrinsics.x86;

// === 水平操作 (主要用于浮点，这里占位) ===
// function sse3_mm_hadd_ps(a, b: __m128): __m128; inline;
// function sse3_mm_hsub_ps(a, b: __m128): __m128; inline;

// === 特殊加载 ===
// function sse3_mm_lddqu_si128(p: Pointer): __m128i; inline;

implementation

// SSE3 对于我们的字节级操作用处不大
// 主要功能在 SSE2 中已经足够
// 这里作为占位，将来如果需要可以添加

{$ENDIF} // SIMD_SSE3_AVAILABLE

end.

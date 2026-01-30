unit fafafa.core.simd.intrinsics.sse3;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.sse3 ===
  SSE3 (Streaming SIMD Extensions 3) 指令集支�?  
  SSE3 �?Intel �?2004 年引入的 SIMD 指令集扩�?  主要增加了水平运算、复数运算和一些特殊的加载指令
  
  特性：
  - 水平加法/减法 (HADDPS, HSUBPS, HADDPD, HSUBPD)
  - 复数运算支持 (ADDSUBPS, ADDSUBPD)
  - 特殊加载指令 (LDDQU, MOVSHDUP, MOVSLDUP, MOVDDUP)
  - 线程同步指令 (MONITOR, MWAIT)
  
  兼容性：大部分现�?x86/x64 处理器都支持
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === SSE3 水平运算 ===
// Horizontal Add/Sub (单精�?
function sse3_hadd_ps(const a, b: TM128): TM128;
function sse3_hsub_ps(const a, b: TM128): TM128;

// Horizontal Add/Sub (双精�?
function sse3_hadd_pd(const a, b: TM128): TM128;
function sse3_hsub_pd(const a, b: TM128): TM128;

// === SSE3 复数运算 ===
// Add/Sub (交替加减)
function sse3_addsub_ps(const a, b: TM128): TM128;
function sse3_addsub_pd(const a, b: TM128): TM128;

// === SSE3 特殊加载指令 ===
// Load Unaligned Integer (更快的未对齐加载)
function sse3_lddqu_si128(const Ptr: Pointer): TM128;

// Move and Duplicate
function sse3_movehdup_ps(const a: TM128): TM128;  // 复制高位元素
function sse3_moveldup_ps(const a: TM128): TM128;  // 复制低位元素
function sse3_movddup_pd(const a: TM128): TM128;   // 复制双精度元�?
// Load and Duplicate
function sse3_loaddup_pd(const Ptr: Pointer): TM128;

// === SSE3 线程同步 (占位�? ===
procedure sse3_monitor(const Ptr: Pointer; extensions, hints: Cardinal);
procedure sse3_mwait(extensions, hints: Cardinal);

implementation

// === 水平运算实现 ===
function sse3_hadd_ps(const a, b: TM128): TM128;
begin
  // 水平加法：[a1+a0, a3+a2, b1+b0, b3+b2]
  Result.m128_f32[0] := a.m128_f32[0] + a.m128_f32[1];
  Result.m128_f32[1] := a.m128_f32[2] + a.m128_f32[3];
  Result.m128_f32[2] := b.m128_f32[0] + b.m128_f32[1];
  Result.m128_f32[3] := b.m128_f32[2] + b.m128_f32[3];
end;

function sse3_hsub_ps(const a, b: TM128): TM128;
begin
  // 水平减法：[a1-a0, a3-a2, b1-b0, b3-b2]
  Result.m128_f32[0] := a.m128_f32[1] - a.m128_f32[0];
  Result.m128_f32[1] := a.m128_f32[3] - a.m128_f32[2];
  Result.m128_f32[2] := b.m128_f32[1] - b.m128_f32[0];
  Result.m128_f32[3] := b.m128_f32[3] - b.m128_f32[2];
end;

function sse3_hadd_pd(const a, b: TM128): TM128;
begin
  // 双精度水平加法：[a1+a0, b1+b0]
  Result.m128d_f64[0] := a.m128d_f64[0] + a.m128d_f64[1];
  Result.m128d_f64[1] := b.m128d_f64[0] + b.m128d_f64[1];
end;

function sse3_hsub_pd(const a, b: TM128): TM128;
begin
  // 双精度水平减法：[a1-a0, b1-b0]
  Result.m128d_f64[0] := a.m128d_f64[1] - a.m128d_f64[0];
  Result.m128d_f64[1] := b.m128d_f64[1] - b.m128d_f64[0];
end;

// === 复数运算实现 ===
function sse3_addsub_ps(const a, b: TM128): TM128;
begin
  // 交替加减：[a0-b0, a1+b1, a2-b2, a3+b3]
  Result.m128_f32[0] := a.m128_f32[0] - b.m128_f32[0];
  Result.m128_f32[1] := a.m128_f32[1] + b.m128_f32[1];
  Result.m128_f32[2] := a.m128_f32[2] - b.m128_f32[2];
  Result.m128_f32[3] := a.m128_f32[3] + b.m128_f32[3];
end;

function sse3_addsub_pd(const a, b: TM128): TM128;
begin
  // 双精度交替加减：[a0-b0, a1+b1]
  Result.m128d_f64[0] := a.m128d_f64[0] - b.m128d_f64[0];
  Result.m128d_f64[1] := a.m128d_f64[1] + b.m128d_f64[1];
end;

// === 特殊加载指令实现 ===
function sse3_lddqu_si128(const Ptr: Pointer): TM128;
begin
  // 未对齐整数加载（在这个实现中与普通加载相同）
  Result := PTM128(Ptr)^;
end;

function sse3_movehdup_ps(const a: TM128): TM128;
begin
  // 复制高位元素：[a1, a1, a3, a3]
  Result.m128_f32[0] := a.m128_f32[1];
  Result.m128_f32[1] := a.m128_f32[1];
  Result.m128_f32[2] := a.m128_f32[3];
  Result.m128_f32[3] := a.m128_f32[3];
end;

function sse3_moveldup_ps(const a: TM128): TM128;
begin
  // 复制低位元素：[a0, a0, a2, a2]
  Result.m128_f32[0] := a.m128_f32[0];
  Result.m128_f32[1] := a.m128_f32[0];
  Result.m128_f32[2] := a.m128_f32[2];
  Result.m128_f32[3] := a.m128_f32[2];
end;

function sse3_movddup_pd(const a: TM128): TM128;
begin
  // 复制双精度元素：[a0, a0]
  Result.m128d_f64[0] := a.m128d_f64[0];
  Result.m128d_f64[1] := a.m128d_f64[0];
end;

function sse3_loaddup_pd(const Ptr: Pointer): TM128;
var
  value: Double;
begin
  // 加载并复制双精度�?  value := PDouble(Ptr)^;
  Result.m128d_f64[0] := value;
  Result.m128d_f64[1] := value;
end;

// === 线程同步指令 (占位�? ===
procedure sse3_monitor(const Ptr: Pointer; extensions, hints: Cardinal);
begin
  // MONITOR 指令的占位符实现
  // 在实际实现中，这里应该执�?MONITOR 指令
end;

procedure sse3_mwait(extensions, hints: Cardinal);
begin
  // MWAIT 指令的占位符实现
  // 在实际实现中，这里应该执�?MWAIT 指令
end;

end.



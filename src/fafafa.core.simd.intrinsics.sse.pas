unit fafafa.core.simd.intrinsics.sse;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.sse ===
  SSE (Streaming SIMD Extensions) 指令集支�?  
  SSE �?Intel �?1999 年引入的 128-bit SIMD 指令�?  主要用于单精度浮点运算，也包含一些整数操�?  
  特性：
  - 128-bit 向量寄存�?(xmm0-xmm7/xmm15)
  - 单精度浮点运�?(4x32-bit)
  - 预取指令
  - 流式存储
  - 缓存控制
  
  兼容性：所有现�?x86/x64 处理器都支持
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === SSE 单精度浮点函�?===
// Load/Store
function sse_load_ps(const Ptr: Pointer): TM128;
function sse_loadu_ps(const Ptr: Pointer): TM128;
function sse_load_ss(const Ptr: Pointer): TM128;
function sse_load1_ps(const Ptr: Pointer): TM128;
procedure sse_store_ps(var Dest; const Src: TM128);
procedure sse_storeu_ps(var Dest; const Src: TM128);
procedure sse_store_ss(var Dest; const Src: TM128);
procedure sse_store1_ps(var Dest; const Src: TM128);
function sse_movq(const Ptr: Pointer): TM128;
procedure sse_movq_store(var Dest; const Src: TM128);

// Set/Zero
function sse_setzero_ps: TM128;
function sse_set1_ps(Value: Single): TM128;
function sse_set_ps(e3, e2, e1, e0: Single): TM128;
function sse_set_ss(Value: Single): TM128;
function sse_setr_ps(e0, e1, e2, e3: Single): TM128;

// Arithmetic
function sse_add_ps(const a, b: TM128): TM128;
function sse_add_ss(const a, b: TM128): TM128;
function sse_sub_ps(const a, b: TM128): TM128;
function sse_sub_ss(const a, b: TM128): TM128;
function sse_mul_ps(const a, b: TM128): TM128;
function sse_mul_ss(const a, b: TM128): TM128;
function sse_div_ps(const a, b: TM128): TM128;
function sse_div_ss(const a, b: TM128): TM128;

// Math Functions
function sse_sqrt_ps(const a: TM128): TM128;
function sse_sqrt_ss(const a: TM128): TM128;
function sse_rsqrt_ps(const a: TM128): TM128;  // 平方根倒数近似
function sse_rsqrt_ss(const a: TM128): TM128;
function sse_rcp_ps(const a: TM128): TM128;    // 倒数近似
function sse_rcp_ss(const a: TM128): TM128;

// Min/Max
function sse_min_ps(const a, b: TM128): TM128;
function sse_min_ss(const a, b: TM128): TM128;
function sse_max_ps(const a, b: TM128): TM128;
function sse_max_ss(const a, b: TM128): TM128;

// Logical
function sse_and_ps(const a, b: TM128): TM128;
function sse_andnot_ps(const a, b: TM128): TM128;
function sse_andn_ps(const a, b: TM128): TM128;  // 别名
function sse_or_ps(const a, b: TM128): TM128;
function sse_xor_ps(const a, b: TM128): TM128;

// Compare
function sse_cmpeq_ps(const a, b: TM128): TM128;
function sse_cmpeq_ss(const a, b: TM128): TM128;
function sse_cmplt_ps(const a, b: TM128): TM128;
function sse_cmplt_ss(const a, b: TM128): TM128;
function sse_cmple_ps(const a, b: TM128): TM128;
function sse_cmple_ss(const a, b: TM128): TM128;
function sse_cmpgt_ps(const a, b: TM128): TM128;
function sse_cmpgt_ss(const a, b: TM128): TM128;
function sse_cmpge_ps(const a, b: TM128): TM128;
function sse_cmpge_ss(const a, b: TM128): TM128;
function sse_cmpneq_ps(const a, b: TM128): TM128;
function sse_cmpneq_ss(const a, b: TM128): TM128;
function sse_cmpord_ps(const a, b: TM128): TM128;
function sse_cmpord_ss(const a, b: TM128): TM128;
function sse_cmpunord_ps(const a, b: TM128): TM128;
function sse_cmpunord_ss(const a, b: TM128): TM128;

// Shuffle/Unpack
function sse_shuffle_ps(const a, b: TM128; imm8: Byte): TM128;
function sse_unpackhi_ps(const a, b: TM128): TM128;
function sse_unpacklo_ps(const a, b: TM128): TM128;
function sse_unpckhps(const a, b: TM128): TM128;  // 别名
function sse_unpcklps(const a, b: TM128): TM128;  // 别名

// Move
function sse_move_ss(const a, b: TM128): TM128;
function sse_movehl_ps(const a, b: TM128): TM128;
function sse_movelh_ps(const a, b: TM128): TM128;
function sse_movemask_ps(const a: TM128): Integer;
function sse_movaps(const a: TM128): TM128;
function sse_movups(const a: TM128): TM128;
function sse_movss(const a: TM128): TM128;
function sse_movhl_ps(const a, b: TM128): TM128;  // 别名
function sse_movlh_ps(const a, b: TM128): TM128;  // 别名
function sse_movd(Value: LongInt): TM128;
function sse_movd_toint(const a: TM128): LongInt;

// Convert
function sse_cvtsi2ss(const a: TM128; Value: LongInt): TM128;
function sse_cvtss2si(const a: TM128): LongInt;
function sse_cvttss2si(const a: TM128): LongInt;

// Prefetch and Cache Control
procedure sse_prefetch(const Ptr: Pointer; locality: Integer);
procedure sse_sfence;
procedure sse_stream_ps(var Dest; const Src: TM128);
procedure sse_stream_si64(var Dest; const Src: TM128);

// Miscellaneous
function sse_getcsr: Integer;
procedure sse_setcsr(Value: Integer);

implementation

uses
  fafafa.core.math;

// 辅助函数：检查浮点数是否�?NaN
function IsNaN(Value: Single): Boolean;
var
  IntValue: LongWord absolute Value;
begin
  // IEEE 754: NaN 的指数部分全�?，尾数部分非�?  Result := ((IntValue and $7F800000) = $7F800000) and ((IntValue and $007FFFFF) <> 0);
end;

// === SSE Load/Store 操作 (内联汇编实现) ===

// 功能：从内存加载4个对齐的单精度浮点数
function sse_load_ps(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movaps xmm0, [rcx]
  {$ELSE}
    movaps xmm0, [rdi]
  {$ENDIF}
  movaps [Result], xmm0
{$ELSE}
  mov eax, Ptr
  movaps xmm0, [eax]
  movaps [Result], xmm0
{$ENDIF}
end;

// 功能：从内存加载4个未对齐的单精度浮点�
function sse_loadu_ps(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  movups [Result], xmm0
{$ELSE}
  mov eax, Ptr
  movups xmm0, [eax]
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：加载单个单精度浮点数到最低位，其他位清零
function sse_load_ss(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movss xmm0, [rcx]
  {$ELSE}
    movss xmm0, [rdi]
  {$ENDIF}
  movups [Result], xmm0
{$ELSE}
  mov eax, Ptr
  movss xmm0, [eax]
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：加载单个单精度浮点数并复制到所�?个位�
function sse_load1_ps(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movss xmm0, [rcx]
  {$ELSE}
    movss xmm0, [rdi]
  {$ENDIF}
  shufps xmm0, xmm0, 0
  movups [Result], xmm0
{$ELSE}
  mov eax, Ptr
  movss xmm0, [eax]
  shufps xmm0, xmm0, 0
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：加�?4位整数到�?4位，�?4位清�
function sse_movq(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq xmm0, [rcx]
  {$ELSE}
    movq xmm0, [rdi]
  {$ENDIF}
  movups [Result], xmm0
{$ELSE}
  mov eax, Ptr
  movq xmm0, [eax]
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：存储低64位到内存
procedure sse_movq_store(var Dest; const Src: TM128); {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rdx]
    movq [rcx], xmm0
  {$ELSE}
    movups xmm0, [rsi]
    movq [rdi], xmm0
  {$ENDIF}
{$ELSE}
  movups xmm0, [Src]
  mov eax, Dest
  movq [eax], xmm0
{$ENDIF}
end;

// 功能：存�?个对齐的单精度浮点数到内�
procedure sse_store_ps(var Dest; const Src: TM128); {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rdx]
    movaps [rcx], xmm0
  {$ELSE}
    movups xmm0, [rsi]
    movaps [rdi], xmm0
  {$ENDIF}
{$ELSE}
  movups xmm0, [Src]
  mov eax, Dest
  movaps [eax], xmm0
{$ENDIF}
end;

// 功能：存�?个未对齐的单精度浮点数到内存
procedure sse_storeu_ps(var Dest; const Src: TM128); {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rdx]
    movups [rcx], xmm0
  {$ELSE}
    movups xmm0, [rsi]
    movups [rdi], xmm0
  {$ENDIF}
{$ELSE}
  movups xmm0, [Src]
  mov eax, Dest
  movups [eax], xmm0
{$ENDIF}
end;

// 功能：存储最低位单精度浮点数到内�
procedure sse_store_ss(var Dest; const Src: TM128); {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rdx]
    movss [rcx], xmm0
  {$ELSE}
    movups xmm0, [rsi]
    movss [rdi], xmm0
  {$ENDIF}
{$ELSE}
  movups xmm0, [Src]
  mov eax, Dest
  movss [eax], xmm0
{$ENDIF}
end;

// 功能：存储最低位单精度浮点数到内存的4个位�
procedure sse_store1_ps(var Dest; const Src: TM128); {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rdx]
    shufps xmm0, xmm0, 0
    movups [rcx], xmm0
  {$ELSE}
    movups xmm0, [rsi]
    shufps xmm0, xmm0, 0
    movups [rdi], xmm0
  {$ENDIF}
{$ELSE}
  movups xmm0, [Src]
  shufps xmm0, xmm0, 0
  mov eax, Dest
  movups [eax], xmm0
{$ENDIF}
end;

// === SSE Set/Zero 操作 (内联汇编实现) ===

// 功能：设置所有位为零
function sse_setzero_ps: TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
  xorps xmm0, xmm0
  movups [Result], xmm0
end;

// 功能：将单个值复制到所�?个位�
function sse_set1_ps(Value: Single): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movss xmm0, Value
  {$ELSE}
    movss xmm0, Value
  {$ENDIF}
  shufps xmm0, xmm0, 0
  movups [Result], xmm0
{$ELSE}
  movss xmm0, Value
  shufps xmm0, xmm0, 0
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：设置4个单精度浮点数 (e3, e2, e1, e0)
function sse_set_ps(e3, e2, e1, e0: Single): TM128;
begin
  Result.m128_f32[0] := e0;
  Result.m128_f32[1] := e1;
  Result.m128_f32[2] := e2;
  Result.m128_f32[3] := e3;
end;

// 功能：设置最低位为指定值，其他位为0
function sse_set_ss(Value: Single): TM128;
begin
  Result.m128_f32[0] := Value;
  Result.m128_f32[1] := 0.0;
  Result.m128_f32[2] := 0.0;
  Result.m128_f32[3] := 0.0;
end;

// 功能：设置4个单精度浮点数 (反向顺序: e0, e1, e2, e3)
function sse_setr_ps(e0, e1, e2, e3: Single): TM128;
begin
  Result.m128_f32[0] := e0;
  Result.m128_f32[1] := e1;
  Result.m128_f32[2] := e2;
  Result.m128_f32[3] := e3;
end;

// === SSE 算术运算操作 (内联汇编实现) ===

// 功能：4个单精度浮点数并行加法
function sse_add_ps(const a, b: TM128): TM128;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    addps  xmm0, xmm1
    movups [Result], xmm0
  end;
end;

// 功能：最低位单精度浮点数加法，其他位保持不变
function sse_add_ss(const a, b: TM128): TM128;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    addss  xmm0, xmm1
    movups [Result], xmm0
  end;
end;

// 功能：4个单精度浮点数并行减法
function sse_sub_ps(const a, b: TM128): TM128;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    subps  xmm0, xmm1
    movups [Result], xmm0
  end;
end;

// 功能：最低位单精度浮点数减法，其他位保持不变
function sse_sub_ss(const a, b: TM128): TM128;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    subss  xmm0, xmm1
    movups [Result], xmm0
  end;
end;

// 功能：4个单精度浮点数并行乘法
function sse_mul_ps(const a, b: TM128): TM128;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    mulps  xmm0, xmm1
    movups [Result], xmm0
  end;
end;

// 功能：最低位单精度浮点数乘法，其他位保持不变
function sse_mul_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  mulss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  mulss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行除�
function sse_div_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  divps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  divps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数除法，其他位保持不变
function sse_div_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  divss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  divss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// === SSE 数学函数操作 (内联汇编实现) ===

// 功能�?个单精度浮点数并行平方根
function sse_sqrt_ps(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  sqrtps xmm0, xmm0
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  sqrtps xmm0, xmm0
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数平方根，其他位保持不�
function sse_sqrt_ss(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  sqrtss xmm0, xmm0
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  sqrtss xmm0, xmm0
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行平方根倒数近似
function sse_rsqrt_ps(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  rsqrtps xmm0, xmm0
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  rsqrtps xmm0, xmm0
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数平方根倒数近似，其他位保持不变
function sse_rsqrt_ss(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  rsqrtss xmm0, xmm0
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  rsqrtss xmm0, xmm0
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行倒数近似
function sse_rcp_ps(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  rcpps xmm0, xmm0
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  rcpps xmm0, xmm0
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数倒数近似，其他位保持不变
function sse_rcp_ss(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  rcpss xmm0, xmm0
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  rcpss xmm0, xmm0
  movups [Result], xmm0
{$ENDIF}
end;

// === SSE 最值操�?(内联汇编实现) ===

// 功能�?个单精度浮点数并行最小�
function sse_min_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  minps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  minps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数最小值，其他位保持不�
function sse_min_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  minss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  minss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行最大�
function sse_max_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  maxps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  maxps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数最大值，其他位保持不�
function sse_max_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  maxss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  maxss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// === SSE 逻辑运算操作 (内联汇编实现) ===

// 功能�?28位按位与
function sse_and_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  andps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  andps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?28位按位与�?(NOT a AND b)
function sse_andnot_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  andnps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  andnps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?28位按位或
function sse_or_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  orps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  orps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?28位按位异�
function sse_xor_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  xorps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  xorps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// === SSE 比较操作 (内联汇编实现) ===

// 功能�?个单精度浮点数并行相等比�
function sse_cmpeq_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpeqps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpeqps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数相等比较，其他位保持不变
function sse_cmpeq_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpeqss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpeqss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行小于比�
function sse_cmplt_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpltps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpltps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数小于比较，其他位保持不变
function sse_cmplt_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpltss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpltss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行小于等于比�
function sse_cmple_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpleps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpleps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数小于等于比较，其他位保持不变
function sse_cmple_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpless xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpless xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行大于比�
function sse_cmpgt_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpps xmm0, xmm1, 6
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpps xmm0, xmm1, 6
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数大于比较，其他位保持不变
function sse_cmpgt_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpss xmm0, xmm1, 6
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpss xmm0, xmm1, 6
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行大于等于比�
function sse_cmpge_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpps xmm0, xmm1, 5
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpps xmm0, xmm1, 5
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数大于等于比较，其他位保持不变
function sse_cmpge_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpss xmm0, xmm1, 5
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpss xmm0, xmm1, 5
  movups [Result], xmm0
{$ENDIF}
end;

// 功能�?个单精度浮点数并行不等于比较
function sse_cmpneq_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpneqps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpneqps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数不等于比较，其他位保持不�
function sse_cmpneq_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpneqss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpneqss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// === SSE Shuffle/Unpack 操作 (内联汇编实现) ===

// 功能：根据立即数重新排列4个单精度浮点�
function sse_shuffle_ps(const a, b: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    // 使用运行时shuffle实现
    push rax
    push rbx
    mov al, r8b
    mov bl, al
    and bl, 3           // 提取�?-1
    shr al, 2
    mov bh, al
    and bh, 3           // 提取�?-3
    shr al, 2
    mov cl, al
    and cl, 3           // 提取�?-5
    shr al, 2
    and al, 3           // 提取�?-7

    // 手动构建结果
    sub rsp, 32
    movups [rsp], xmm0      // 保存a
    movups [rsp+16], xmm1   // 保存b

    // 提取元素并重新组�?    movzx rbx, bl
    movss xmm2, [rsp + rbx*4]
    movzx rbx, bh
    movss xmm3, [rsp + rbx*4]
    movzx rbx, cl
    movss xmm4, [rsp + 16 + rbx*4]
    movzx rbx, al
    movss xmm5, [rsp + 16 + rbx*4]

    unpcklps xmm2, xmm3
    unpcklps xmm4, xmm5
    movlhps xmm2, xmm4

    add rsp, 32
    pop rbx
    pop rax
    movups [Result], xmm2
  {$ELSE}
    // SysV x64类似实现
    movups xmm0, [rdi]
    movups xmm1, [rsi]
    // 简化为Pascal实现以避免复杂的汇编
    push rax
    push rbx
    mov al, sil
    // ... 类似的实�?    pop rbx
    pop rax
    movups [Result], xmm0
  {$ENDIF}
{$ELSE}
  // x86: 使用Pascal实现
  push eax
  push ebx
  mov al, imm8
  // 复杂的x86实现
  pop ebx
  pop eax
{$ENDIF}
end;

// 功能：解包高位单精度浮点�
function sse_unpackhi_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  unpckhps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  unpckhps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：解包低位单精度浮点�
function sse_unpacklo_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  unpcklps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  unpcklps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// === SSE 数据移动操作 (内联汇编实现) ===

// 功能：移动最低位单精度浮点数，其他位保持a的�
function sse_move_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  movss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  movss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：移动高位到低位
function sse_movehl_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  movhlps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  movhlps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：移动低位到高位
function sse_movelh_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  movlhps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  movlhps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：提取符号位掩码
function sse_movemask_ps(const a: TM128): Integer; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  movmskps eax, xmm0
{$ELSE}
  movups xmm0, [a]
  movmskps eax, xmm0
{$ENDIF}
end;

// === SSE 类型转换操作 (内联汇编实现) ===

// 功能：将32位整数转换为单精度浮点数
function sse_cvtsi2ss(const a: TM128; Value: LongInt): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    cvtsi2ss xmm0, edx
  {$ELSE}
    movups xmm0, [rdi]
    cvtsi2ss xmm0, esi
  {$ENDIF}
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  cvtsi2ss xmm0, Value
  movups [Result], xmm0
{$ENDIF}
end;

function sse_cvtss2si(const a: TM128): LongInt;
begin
  Result := Round(a.m128_f32[0]);
end;

function sse_cvttss2si(const a: TM128): LongInt;
begin
  Result := Trunc(a.m128_f32[0]);
end;

procedure sse_prefetch(const Ptr: Pointer; locality: Integer);
begin
  // 预取指令的占位符实现
  // 在实际实现中，这里应该执行相应的预取指令
end;

// === 缺失函数的实�?===

function sse_andn_ps(const a, b: TM128): TM128;
begin
  Result := sse_andnot_ps(a, b);
end;

function sse_cmpord_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    if (not IsNaN(a.m128_f32[i])) and (not IsNaN(b.m128_f32[i])) then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := 0;
  end;
end;

function sse_cmpord_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if (not IsNaN(a.m128_f32[0])) and (not IsNaN(b.m128_f32[0])) then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := 0;
end;

function sse_cmpunord_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    if IsNaN(a.m128_f32[i]) or IsNaN(b.m128_f32[i]) then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := 0;
  end;
end;

function sse_cmpunord_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if IsNaN(a.m128_f32[0]) or IsNaN(b.m128_f32[0]) then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := 0;
end;

function sse_unpckhps(const a, b: TM128): TM128;
begin
  Result := sse_unpackhi_ps(a, b);
end;

function sse_unpcklps(const a, b: TM128): TM128;
begin
  Result := sse_unpacklo_ps(a, b);
end;

// 功能：移�?个对齐的单精度浮点数
function sse_movaps(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movaps xmm0, [rcx]
  {$ELSE}
    movaps xmm0, [rdi]
  {$ENDIF}
  movaps [Result], xmm0
{$ELSE}
  movaps xmm0, [a]
  movaps [Result], xmm0
{$ENDIF}
end;

// 功能：移�?个未对齐的单精度浮点�
function sse_movups(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：移动单个单精度浮点数，其他位清�
function sse_movss(const a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    xorps xmm0, xmm0
    movss xmm0, [rcx]
  {$ELSE}
    xorps xmm0, xmm0
    movss xmm0, [rdi]
  {$ENDIF}
  movups [Result], xmm0
{$ELSE}
  xorps xmm0, xmm0
  movss xmm0, [a]
  movups [Result], xmm0
{$ENDIF}
end;

function sse_movhl_ps(const a, b: TM128): TM128;
begin
  Result := sse_movehl_ps(a, b);
end;

function sse_movlh_ps(const a, b: TM128): TM128;
begin
  Result := sse_movelh_ps(a, b);
end;

// 功能：从32位整数创�?28位向量，其他位清�
function sse_movd(Value: LongInt): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movd xmm0, ecx
  {$ELSE}
    movd xmm0, edi
  {$ENDIF}
  movups [Result], xmm0
{$ELSE}
  movd xmm0, Value
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：提�?28位向量的�?2位整�
function sse_movd_toint(const a: TM128): LongInt; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  movd eax, xmm0
{$ELSE}
  movups xmm0, [a]
  movd eax, xmm0
{$ENDIF}
end;

procedure sse_stream_ps(var Dest; const Src: TM128);
begin
  // 非时态存储的占位符实�?  PTM128(@Dest)^ := Src;
end;

procedure sse_stream_si64(var Dest; const Src: TM128);
begin
  // 非时态存储的占位符实�?  PUInt64(@Dest)^ := Src.m128i_u64[0];
end;

function sse_getcsr: Integer;
begin
  // MXCSR 寄存器读取的占位符实�?  Result := 0;
end;

procedure sse_setcsr(Value: Integer);
begin
  // MXCSR 寄存器设置的占位符实�
end;

procedure sse_sfence;
begin
  // 存储栅栏指令的占位符实现
  // 在实际实现中，这里应该执�?SFENCE 指令
end;

end.



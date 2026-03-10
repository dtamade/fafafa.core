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
procedure sse_store_ps(var Dest; constref Src: TM128);
procedure sse_storeu_ps(var Dest; constref Src: TM128);
procedure sse_store_ss(var Dest; constref Src: TM128);
procedure sse_store1_ps(var Dest; constref Src: TM128);
function sse_movq(const Ptr: Pointer): TM128;
procedure sse_movq_store(var Dest; constref Src: TM128);

// Set/Zero
function sse_setzero_ps: TM128;
function sse_set1_ps(Value: Single): TM128;
function sse_set_ps(e3, e2, e1, e0: Single): TM128;
function sse_set_ss(Value: Single): TM128;
function sse_setr_ps(e0, e1, e2, e3: Single): TM128;

// Arithmetic
function sse_add_ps(constref a, b: TM128): TM128;
function sse_add_ss(constref a, b: TM128): TM128;
function sse_sub_ps(constref a, b: TM128): TM128;
function sse_sub_ss(constref a, b: TM128): TM128;
function sse_mul_ps(constref a, b: TM128): TM128;
function sse_mul_ss(constref a, b: TM128): TM128;
function sse_div_ps(constref a, b: TM128): TM128;
function sse_div_ss(constref a, b: TM128): TM128;

// Math Functions
function sse_sqrt_ps(constref a: TM128): TM128;
function sse_sqrt_ss(constref a: TM128): TM128;
function sse_rsqrt_ps(constref a: TM128): TM128;  // 平方根倒数近似
function sse_rsqrt_ss(constref a: TM128): TM128;
function sse_rcp_ps(constref a: TM128): TM128;    // 倒数近似
function sse_rcp_ss(constref a: TM128): TM128;

// Min/Max
function sse_min_ps(constref a, b: TM128): TM128;
function sse_min_ss(constref a, b: TM128): TM128;
function sse_max_ps(constref a, b: TM128): TM128;
function sse_max_ss(constref a, b: TM128): TM128;

// Logical
function sse_and_ps(constref a, b: TM128): TM128;
function sse_andnot_ps(constref a, b: TM128): TM128;
function sse_andn_ps(constref a, b: TM128): TM128;  // 别名：sse_andnot_ps
function sse_or_ps(constref a, b: TM128): TM128;
function sse_xor_ps(constref a, b: TM128): TM128;

// Compare
function sse_cmpeq_ps(constref a, b: TM128): TM128;
function sse_cmpeq_ss(constref a, b: TM128): TM128;
function sse_cmplt_ps(constref a, b: TM128): TM128;
function sse_cmplt_ss(constref a, b: TM128): TM128;
function sse_cmple_ps(constref a, b: TM128): TM128;
function sse_cmple_ss(constref a, b: TM128): TM128;
function sse_cmpgt_ps(constref a, b: TM128): TM128;
function sse_cmpgt_ss(constref a, b: TM128): TM128;
function sse_cmpge_ps(constref a, b: TM128): TM128;
function sse_cmpge_ss(constref a, b: TM128): TM128;
function sse_cmpneq_ps(constref a, b: TM128): TM128;
function sse_cmpneq_ss(constref a, b: TM128): TM128;
function sse_cmpord_ps(constref a, b: TM128): TM128;
function sse_cmpord_ss(constref a, b: TM128): TM128;
function sse_cmpunord_ps(constref a, b: TM128): TM128;
function sse_cmpunord_ss(constref a, b: TM128): TM128;

// Shuffle/Unpack
function sse_shuffle_ps(constref a, b: TM128; imm8: Byte): TM128;
function sse_unpackhi_ps(constref a, b: TM128): TM128;
function sse_unpacklo_ps(constref a, b: TM128): TM128;
function sse_unpckhps(constref a, b: TM128): TM128;  // 别名：sse_unpackhi_ps
function sse_unpcklps(constref a, b: TM128): TM128;  // 别名：sse_unpacklo_ps

// Move
function sse_move_ss(constref a, b: TM128): TM128;
function sse_movehl_ps(constref a, b: TM128): TM128;
function sse_movelh_ps(constref a, b: TM128): TM128;
function sse_movemask_ps(constref a: TM128): Integer;
function sse_movaps(constref a: TM128): TM128;
function sse_movups(constref a: TM128): TM128;
function sse_movss(constref a: TM128): TM128;
function sse_movhl_ps(constref a, b: TM128): TM128;  // 别名：sse_movehl_ps
function sse_movlh_ps(constref a, b: TM128): TM128;  // 别名：sse_movelh_ps
function sse_movd(Value: LongInt): TM128;
function sse_movd_toint(constref a: TM128): LongInt;

// Convert
function sse_cvtsi2ss(constref a: TM128; Value: LongInt): TM128;
function sse_cvtss2si(constref a: TM128): LongInt;
function sse_cvttss2si(constref a: TM128): LongInt;

// Prefetch and Cache Control
procedure sse_prefetch(const Ptr: Pointer; locality: Integer);
procedure sse_sfence;
procedure sse_stream_ps(var Dest; constref Src: TM128);
procedure sse_stream_si64(var Dest; constref Src: TM128);

// Miscellaneous
function sse_getcsr: Integer;
procedure sse_setcsr(Value: Integer);

implementation

uses
  SysUtils;

// 辅助函数：检查浮点数是否�?NaN
function IsNaN(Value: Single): Boolean;
var
  IntValue: LongWord absolute Value;
begin
  // IEEE 754: NaN 的指数部分全1，尾数部分非0
  Result := ((IntValue and $7F800000) = $7F800000) and ((IntValue and $007FFFFF) <> 0);
end;

// === SSE Load/Store 操作 (内联汇编实现) ===

// 功能：从内存加载4个对齐的单精度浮点数
function sse_load_ps(const Ptr: Pointer): TM128;
var
  LPtr: Pointer;
begin
  Result := sse_setzero_ps;
  if Ptr = nil then
    Exit;

  LPtr := Ptr;
{$IFDEF CPUX86_64}
  asm
    mov rax, LPtr
    movups xmm0, [rax]
    movups [Result], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LPtr
    movups xmm0, [eax]
    movups [Result], xmm0
  end;
  {$ELSE}
  Move(PByte(LPtr)^, Result, SizeOf(Result));
  {$ENDIF}
{$ENDIF}
end;

// 功能：从内存加载4个未对齐的单精度浮点�
function sse_loadu_ps(const Ptr: Pointer): TM128;
var
  LPtr: Pointer;
begin
  Result := sse_setzero_ps;
  if Ptr = nil then
    Exit;

  LPtr := Ptr;
{$IFDEF CPUX86_64}
  asm
    mov rax, LPtr
    movups xmm0, [rax]
    movups [Result], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LPtr
    movups xmm0, [eax]
    movups [Result], xmm0
  end;
  {$ELSE}
  Move(PByte(LPtr)^, Result, SizeOf(Result));
  {$ENDIF}
{$ENDIF}
end;

// 功能：加载单个单精度浮点数到最低位，其他位清零
function sse_load_ss(const Ptr: Pointer): TM128;
var
  LPtr: Pointer;
begin
  Result := sse_setzero_ps;
  if Ptr = nil then
    Exit;

  LPtr := Ptr;
{$IFDEF CPUX86_64}
  asm
    mov rax, LPtr
    xorps xmm0, xmm0
    movss xmm0, [rax]
    movups [Result], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LPtr
    xorps xmm0, xmm0
    movss xmm0, [eax]
    movups [Result], xmm0
  end;
  {$ELSE}
  Result.m128_f32[0] := PSingle(LPtr)^;
  {$ENDIF}
{$ENDIF}
end;

// 功能：加载单个单精度浮点数并复制到所�?个位�
function sse_load1_ps(const Ptr: Pointer): TM128;
var
  LPtr: Pointer;
  LValue: Single;
begin
  Result := sse_setzero_ps;
  if Ptr = nil then
    Exit;

  LPtr := Ptr;

{$IFDEF CPUX86_64}
  asm
    mov rax, LPtr
    movss xmm0, [rax]
    shufps xmm0, xmm0, 0
    movups [Result], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LPtr
    movss xmm0, [eax]
    shufps xmm0, xmm0, 0
    movups [Result], xmm0
  end;
  {$ELSE}
  LValue := PSingle(LPtr)^;
  Result.m128_f32[0] := LValue;
  Result.m128_f32[1] := LValue;
  Result.m128_f32[2] := LValue;
  Result.m128_f32[3] := LValue;
  {$ENDIF}
{$ENDIF}
end;

// 功能：加�?4位整数到�?4位，�?4位清�
function sse_movq(const Ptr: Pointer): TM128;
var
  LPtr: Pointer;
begin
  Result := sse_setzero_ps;
  if Ptr = nil then
    Exit;

  LPtr := Ptr;
{$IFDEF CPUX86_64}
  asm
    mov rax, LPtr
    xorps xmm0, xmm0
    movq xmm0, [rax]
    movups [Result], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LPtr
    xorps xmm0, xmm0
    movq xmm0, [eax]
    movups [Result], xmm0
  end;
  {$ELSE}
  Result.m128i_u64[0] := PUInt64(LPtr)^;
  {$ENDIF}
{$ENDIF}
end;

// 功能：存储低64位到内存
procedure sse_movq_store(var Dest; constref Src: TM128);
var
  LDest: Pointer;
  LSrc: Pointer;
begin
  LDest := @Dest;
  LSrc := @Src;
{$IFDEF CPUX86_64}
  asm
    mov rax, LDest
    mov rdx, LSrc
    movq xmm0, [rdx]
    movq [rax], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LDest
    mov edx, LSrc
    movq xmm0, [edx]
    movq [eax], xmm0
  end;
  {$ELSE}
  PUInt64(LDest)^ := PUInt64(LSrc)^;
  {$ENDIF}
{$ENDIF}
end;

// 功能：存�?个对齐的单精度浮点数到内�
procedure sse_store_ps(var Dest; constref Src: TM128);
var
  LDest: Pointer;
  LSrc: Pointer;
begin
  LDest := @Dest;
  LSrc := @Src;
{$IFDEF CPUX86_64}
  asm
    mov rax, LDest
    mov rdx, LSrc
    movups xmm0, [rdx]
    movups [rax], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LDest
    mov edx, LSrc
    movups xmm0, [edx]
    movups [eax], xmm0
  end;
  {$ELSE}
  Move(PByte(LSrc)^, Dest, SizeOf(TM128));
  {$ENDIF}
{$ENDIF}
end;

// 功能：存�?个未对齐的单精度浮点数到内存
procedure sse_storeu_ps(var Dest; constref Src: TM128);
var
  LDest: Pointer;
  LSrc: Pointer;
begin
  LDest := @Dest;
  LSrc := @Src;
{$IFDEF CPUX86_64}
  asm
    mov rax, LDest
    mov rdx, LSrc
    movups xmm0, [rdx]
    movups [rax], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LDest
    mov edx, LSrc
    movups xmm0, [edx]
    movups [eax], xmm0
  end;
  {$ELSE}
  Move(PByte(LSrc)^, Dest, SizeOf(TM128));
  {$ENDIF}
{$ENDIF}
end;

// 功能：存储最低位单精度浮点数到内�
procedure sse_store_ss(var Dest; constref Src: TM128);
var
  LDest: Pointer;
  LSrc: Pointer;
begin
  LDest := @Dest;
  LSrc := @Src;
{$IFDEF CPUX86_64}
  asm
    mov rax, LDest
    mov rdx, LSrc
    movss xmm0, [rdx]
    movss [rax], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LDest
    mov edx, LSrc
    movss xmm0, [edx]
    movss [eax], xmm0
  end;
  {$ELSE}
  PSingle(LDest)^ := PSingle(LSrc)^;
  {$ENDIF}
{$ENDIF}
end;

// 功能：存储最低位单精度浮点数到内存的4个位�
procedure sse_store1_ps(var Dest; constref Src: TM128);
var
  LDestPtr: Pointer;
  LSrc: Pointer;
  LDest: PSingle;
  LValue: Single;
begin
  LDestPtr := @Dest;
  LSrc := @Src;
{$IFDEF CPUX86_64}
  asm
    mov rax, LDestPtr
    mov rdx, LSrc
    movss xmm0, [rdx]
    shufps xmm0, xmm0, 0
    movups [rax], xmm0
  end;
{$ELSE}
  {$IFDEF CPU386}
  asm
    mov eax, LDestPtr
    mov edx, LSrc
    movss xmm0, [edx]
    shufps xmm0, xmm0, 0
    movups [eax], xmm0
  end;
  {$ELSE}
  LDest := PSingle(LDestPtr);
  LValue := PSingle(LSrc)^;
  LDest[0] := LValue;
  LDest[1] := LValue;
  LDest[2] := LValue;
  LDest[3] := LValue;
  {$ENDIF}
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
function sse_add_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  addps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  addps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数加法，其他位保持不变
function sse_add_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  addss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  addss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：4个单精度浮点数并行减法
function sse_sub_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  subps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  subps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数减法，其他位保持不变
function sse_sub_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  subss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  subss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：4个单精度浮点数并行乘法
function sse_mul_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  mulps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  mulps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 功能：最低位单精度浮点数乘法，其他位保持不变
function sse_mul_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_div_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_div_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_sqrt_ps(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_sqrt_ss(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_rsqrt_ps(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_rsqrt_ss(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_rcp_ps(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_rcp_ss(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_min_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_min_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_max_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_max_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_and_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_andnot_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_or_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_xor_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpeq_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpeq_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmplt_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmplt_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmple_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmple_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpgt_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpgt_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpge_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpge_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpneq_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cmpneq_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_shuffle_ps(constref a, b: TM128; imm8: Byte): TM128;
begin
  Result.m128_f32[0] := a.m128_f32[imm8 and $03];
  Result.m128_f32[1] := a.m128_f32[(imm8 shr 2) and $03];
  Result.m128_f32[2] := b.m128_f32[(imm8 shr 4) and $03];
  Result.m128_f32[3] := b.m128_f32[(imm8 shr 6) and $03];
end;

// 功能：解包高位单精度浮点�
function sse_unpackhi_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_unpacklo_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_move_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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

// 功能：移动高位到低位（结果 lanes: b2,b3,a2,a3）
function sse_movehl_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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

// 功能：移动低位到高位（结果 lanes: a0,a1,b0,b1）
function sse_movelh_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_movemask_ps(constref a: TM128): Integer; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_cvtsi2ss(constref a: TM128; Value: LongInt): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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

{$IF Defined(CPUX86_64) or Defined(CPU386)}
function sse_cvtss2si(constref a: TM128): LongInt; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  cvtss2si eax, xmm0
{$ELSE}
  movups xmm0, [a]
  cvtss2si eax, xmm0
{$ENDIF}
end;

function sse_cvttss2si(constref a: TM128): LongInt; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
  cvttss2si eax, xmm0
{$ELSE}
  movups xmm0, [a]
  cvttss2si eax, xmm0
{$ENDIF}
end;
{$ELSE}
function sse_cvtss2si(constref a: TM128): LongInt;
begin
  Result := Round(a.m128_f32[0]);
end;

function sse_cvttss2si(constref a: TM128): LongInt;
begin
  Result := Trunc(a.m128_f32[0]);
end;
{$ENDIF}

procedure sse_prefetch(const Ptr: Pointer; locality: Integer);
var
  LPtr: Pointer;
begin
  if Ptr = nil then
    Exit;

  LPtr := Ptr;

  {$IF Defined(CPUX86) or Defined(CPUX86_64)}
  {$IFDEF FPC}
  case locality of
    0:
      asm
        {$IFDEF CPUX86_64}
        mov rax, LPtr
        {$ELSE}
        mov eax, LPtr
        {$ENDIF}
        prefetchnta [rax]
      end;
    1:
      asm
        {$IFDEF CPUX86_64}
        mov rax, LPtr
        {$ELSE}
        mov eax, LPtr
        {$ENDIF}
        prefetcht2 [rax]
      end;
    2:
      asm
        {$IFDEF CPUX86_64}
        mov rax, LPtr
        {$ELSE}
        mov eax, LPtr
        {$ENDIF}
        prefetcht1 [rax]
      end;
  else
    asm
      {$IFDEF CPUX86_64}
      mov rax, LPtr
      {$ELSE}
      mov eax, LPtr
      {$ENDIF}
      prefetcht0 [rax]
    end;
  end;
  {$ENDIF}
  {$ENDIF}
end;

// === 补充函数与别名实现 ===

// 别名：等价于 sse_andnot_ps
function sse_andn_ps(constref a, b: TM128): TM128;
begin
  Result := sse_andnot_ps(a, b);
end;

function sse_cmpord_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpordps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpordps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

function sse_cmpord_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpordss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpordss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

function sse_cmpunord_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpunordps xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpunordps xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

function sse_cmpunord_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
  {$ENDIF}
  cmpunordss xmm0, xmm1
  movups [Result], xmm0
{$ELSE}
  movups xmm0, [a]
  movups xmm1, [b]
  cmpunordss xmm0, xmm1
  movups [Result], xmm0
{$ENDIF}
end;

// 别名：等价于 sse_unpackhi_ps
function sse_unpckhps(constref a, b: TM128): TM128;
begin
  Result := sse_unpackhi_ps(a, b);
end;

// 别名：等价于 sse_unpacklo_ps
function sse_unpcklps(constref a, b: TM128): TM128;
begin
  Result := sse_unpacklo_ps(a, b);
end;

// 功能：移�?个对齐的单精度浮点数
function sse_movaps(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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

// 功能：移�?个未对齐的单精度浮点�
function sse_movups(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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
function sse_movss(constref a: TM128): TM128; {$IFDEF FPC}assembler;{$ENDIF}
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

// 别名：等价于 sse_movehl_ps
function sse_movhl_ps(constref a, b: TM128): TM128;
begin
  Result := sse_movehl_ps(a, b);
end;

// 别名：等价于 sse_movelh_ps
function sse_movlh_ps(constref a, b: TM128): TM128;
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
function sse_movd_toint(constref a: TM128): LongInt; {$IFDEF FPC}assembler;{$ENDIF}
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

procedure sse_stream_ps(var Dest; constref Src: TM128);
var
  LDestPtr: PByte;
  LDestAddr: PtrUInt;
begin
  LDestPtr := @Dest;
  {$push}
  {$warn 4055 off}
  LDestAddr := PtrUInt(LDestPtr);
  {$pop}

  {$IF Defined(CPUX86_64) and Defined(FPC)}
  if (LDestAddr and $0F) = 0 then
  begin
    asm
      mov rax, LDestPtr
      movups xmm0, [Src]
      movntps [rax], xmm0
    end;
    sse_sfence;
    Exit;
  end;
  {$ENDIF}

  Move(Src, Dest, SizeOf(TM128));
end;

procedure sse_stream_si64(var Dest; constref Src: TM128);
var
  LDestPtr: PByte;
  LDestAddr: PtrUInt;
  LValue: QWord;
begin
  LDestPtr := @Dest;
  {$push}
  {$warn 4055 off}
  LDestAddr := PtrUInt(LDestPtr);
  {$pop}
  LValue := Src.m128i_u64[0];

  {$IF Defined(CPUX86_64) and Defined(FPC)}
  if (LDestAddr and $07) = 0 then
  begin
    asm
      mov rax, LDestPtr
      mov rdx, LValue
      movnti [rax], rdx
    end;
    sse_sfence;
    Exit;
  end;
  {$ENDIF}

  PUInt64(LDestPtr)^ := LValue;
end;

function sse_getcsr: Integer;
var
  LMxcsr: LongWord;
begin
  LMxcsr := 0;
  {$IF Defined(CPUX86) or Defined(CPUX86_64)}
  {$IFDEF FPC}
  asm
    stmxcsr [LMxcsr]
  end;
  {$ENDIF}
  {$ENDIF}
  Result := LongInt(LMxcsr);
end;

procedure sse_setcsr(Value: Integer);
var
  LMxcsr: LongWord;
begin
  LMxcsr := LongWord(Value);
  {$IF Defined(CPUX86) or Defined(CPUX86_64)}
  {$IFDEF FPC}
  asm
    ldmxcsr [LMxcsr]
  end;
  {$ENDIF}
  {$ENDIF}
end;

procedure sse_sfence;
begin
  {$IF Defined(CPUX86) or Defined(CPUX86_64)}
  {$IFDEF FPC}
  asm
    sfence
  end;
  {$ENDIF}
  {$ENDIF}
end;

end.

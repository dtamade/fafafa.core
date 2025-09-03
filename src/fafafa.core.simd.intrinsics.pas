unit fafafa.core.simd.intrinsics;

{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics ===
  SIMD 内联函数统一门面模块
  
  这个模块作为所有 SIMD 指令集的统一入口，提供：
  1. 统一的类型定义和接口
  2. 自动的指令集检测和选择
  3. 跨平台的兼容性抽象
  4. 性能优化的函数选择
  
  支持的指令集：
  - x86/x64: MMX, SSE, SSE2, SSE3, SSE4.1, SSE4.2, AVX, AVX2, AVX-512, AES, SHA, FMA3
  - ARM: NEON, SVE, SVE2
  - RISC-V: RVV (Vector Extension)
  - LoongArch: LASX
  
  使用方式：
    uses fafafa.core.simd.intrinsics;
    
    var
      a, b, result: TM128;
    begin
      a := simd_set1_epi32(42);
      b := simd_set1_epi32(24);
      result := simd_add_epi32(a, b);
    end;
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === 重新导出基础类型 ===
type
  // 128-bit 向量类型
  TM128 = fafafa.core.simd.intrinsics.base.TM128;
  PTM128 = ^TM128;

  // 256-bit 向量类型 (AVX)
  TM256 = fafafa.core.simd.intrinsics.base.TSimd256;
  PTM256 = ^TM256;

  // 512-bit 向量类型 (AVX-512)
  TM512 = fafafa.core.simd.intrinsics.base.TSimd512;
  PTM512 = ^TM512;

// === 指令集检测 ===
function simd_has_mmx: Boolean;
function simd_has_sse: Boolean;
function simd_has_sse2: Boolean;
function simd_has_sse3: Boolean;
function simd_has_sse41: Boolean;
function simd_has_sse42: Boolean;
function simd_has_avx: Boolean;
function simd_has_avx2: Boolean;
function simd_has_avx512f: Boolean;
function simd_has_aes: Boolean;
function simd_has_sha: Boolean;
function simd_has_fma3: Boolean;

// === 基础 SSE2 函数 (最常用，所有 x64 都支持) ===
// Load/Store
function simd_load_si128(const Ptr: Pointer): TM128;
function simd_loadu_si128(const Ptr: Pointer): TM128;
procedure simd_store_si128(var Dest; const Src: TM128);
procedure simd_storeu_si128(var Dest; const Src: TM128);

// Set/Zero
function simd_setzero_si128: TM128;
function simd_set1_epi32(Value: LongInt): TM128;
function simd_set1_epi16(Value: SmallInt): TM128;
function simd_set1_epi8(Value: ShortInt): TM128;

// Arithmetic
function simd_add_epi32(const a, b: TM128): TM128;
function simd_add_epi16(const a, b: TM128): TM128;
function simd_add_epi8(const a, b: TM128): TM128;
function simd_sub_epi32(const a, b: TM128): TM128;
function simd_sub_epi16(const a, b: TM128): TM128;
function simd_sub_epi8(const a, b: TM128): TM128;

// Logical
function simd_and_si128(const a, b: TM128): TM128;
function simd_or_si128(const a, b: TM128): TM128;
function simd_xor_si128(const a, b: TM128): TM128;
function simd_andnot_si128(const a, b: TM128): TM128;

// Compare
function simd_cmpeq_epi32(const a, b: TM128): TM128;
function simd_cmpeq_epi16(const a, b: TM128): TM128;
function simd_cmpeq_epi8(const a, b: TM128): TM128;
function simd_cmpgt_epi32(const a, b: TM128): TM128;
function simd_cmpgt_epi16(const a, b: TM128): TM128;
function simd_cmpgt_epi8(const a, b: TM128): TM128;

// Shift
function simd_slli_epi32(const a: TM128; imm8: Byte): TM128;
function simd_srli_epi32(const a: TM128; imm8: Byte): TM128;
function simd_srai_epi32(const a: TM128; imm8: Byte): TM128;

// === 高级函数 (根据可用指令集自动选择最优实现) ===
function simd_max_epi8(const a, b: TM128): TM128;   // SSE4.1 优化，SSE2 兼容
function simd_min_epi8(const a, b: TM128): TM128;   // SSE4.1 优化，SSE2 兼容
function simd_max_epi32(const a, b: TM128): TM128;  // SSE4.1 优化，SSE2 兼容
function simd_min_epi32(const a, b: TM128): TM128;  // SSE4.1 优化，SSE2 兼容

// === 浮点运算 ===
function simd_add_ps(const a, b: TM128): TM128;     // 单精度浮点
function simd_add_pd(const a, b: TM128): TM128;     // 双精度浮点
function simd_mul_ps(const a, b: TM128): TM128;
function simd_mul_pd(const a, b: TM128): TM128;

implementation

// 暂时只提供基础的 Pascal 实现，后续会添加具体指令集模块的调用

// === 指令集检测实现 ===
var
  g_cpu_features: record
    mmx, sse, sse2, sse3, sse41, sse42: Boolean;
    avx, avx2, avx512f: Boolean;
    aes, sha, fma3: Boolean;
    initialized: Boolean;
  end;

procedure detect_cpu_features;
{$IFDEF CPUX86_64}
var
  eax, ebx, ecx, edx: Cardinal;
{$ENDIF}
begin
  if g_cpu_features.initialized then Exit;

{$IFDEF CPUX86_64}
  try
    // 使用 CPUID 检测 x86/x64 特性
    asm
      push rbx
      mov eax, 1
      cpuid
      mov eax, edx
      mov ebx, ecx
      pop rbx
      mov edx, eax
      mov ecx, ebx
    end;

    g_cpu_features.mmx := (edx and (1 shl 23)) <> 0;
    g_cpu_features.sse := (edx and (1 shl 25)) <> 0;
    g_cpu_features.sse2 := (edx and (1 shl 26)) <> 0;
    g_cpu_features.sse3 := (ecx and (1 shl 0)) <> 0;
    g_cpu_features.sse41 := (ecx and (1 shl 19)) <> 0;
    g_cpu_features.sse42 := (ecx and (1 shl 20)) <> 0;
    g_cpu_features.avx := (ecx and (1 shl 28)) <> 0;
    g_cpu_features.aes := (ecx and (1 shl 25)) <> 0;
    g_cpu_features.fma3 := (ecx and (1 shl 12)) <> 0;

    // 检测 AVX2 和 AVX-512
    asm
      push rbx
      mov eax, 7
      xor ecx, ecx
      cpuid
      mov eax, ebx
      pop rbx
      mov ebx, eax
    end;

    g_cpu_features.avx2 := (ebx and (1 shl 5)) <> 0;
    g_cpu_features.avx512f := (ebx and (1 shl 16)) <> 0;
    g_cpu_features.sha := False; // 需要额外检测
  except
    // 如果 CPUID 失败，假设不支持任何特性
    g_cpu_features.mmx := False;
    g_cpu_features.sse := False;
    g_cpu_features.sse2 := False;
    g_cpu_features.sse3 := False;
    g_cpu_features.sse41 := False;
    g_cpu_features.sse42 := False;
    g_cpu_features.avx := False;
    g_cpu_features.avx2 := False;
    g_cpu_features.avx512f := False;
    g_cpu_features.aes := False;
    g_cpu_features.sha := False;
    g_cpu_features.fma3 := False;
  end;
{$ELSE}
  // 其他架构默认不支持 x86 特性
  g_cpu_features.mmx := False;
  g_cpu_features.sse := False;
  g_cpu_features.sse2 := False;
  g_cpu_features.sse3 := False;
  g_cpu_features.sse41 := False;
  g_cpu_features.sse42 := False;
  g_cpu_features.avx := False;
  g_cpu_features.avx2 := False;
  g_cpu_features.avx512f := False;
  g_cpu_features.aes := False;
  g_cpu_features.sha := False;
  g_cpu_features.fma3 := False;
{$ENDIF}

  g_cpu_features.initialized := True;
end;

function simd_has_mmx: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.mmx;
end;

function simd_has_sse: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.sse;
end;

function simd_has_sse2: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.sse2;
end;

function simd_has_sse3: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.sse3;
end;

function simd_has_sse41: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.sse41;
end;

function simd_has_sse42: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.sse42;
end;

function simd_has_avx: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.avx;
end;

function simd_has_avx2: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.avx2;
end;

function simd_has_avx512f: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.avx512f;
end;

function simd_has_aes: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.aes;
end;

function simd_has_sha: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.sha;
end;

function simd_has_fma3: Boolean;
begin
  detect_cpu_features;
  Result := g_cpu_features.fma3;
end;

// === 基础函数实现 (Pascal 版本，后续会优化为汇编) ===
function simd_load_si128(const Ptr: Pointer): TM128;
begin
  Result := PTM128(Ptr)^;
end;

function simd_loadu_si128(const Ptr: Pointer): TM128;
begin
  Result := PTM128(Ptr)^;
end;

procedure simd_store_si128(var Dest; const Src: TM128);
begin
  PTM128(@Dest)^ := Src;
end;

procedure simd_storeu_si128(var Dest; const Src: TM128);
begin
  PTM128(@Dest)^ := Src;
end;

function simd_setzero_si128: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function simd_set1_epi32(Value: LongInt): TM128;
begin
  Result.m128i_i32[0] := Value;
  Result.m128i_i32[1] := Value;
  Result.m128i_i32[2] := Value;
  Result.m128i_i32[3] := Value;
end;

function simd_set1_epi16(Value: SmallInt): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := Value;
end;

function simd_set1_epi8(Value: ShortInt): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m128i_i8[i] := Value;
end;

function simd_add_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_i32[i] := a.m128i_i32[i] + b.m128i_i32[i];
end;

function simd_add_epi16(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := a.m128i_i16[i] + b.m128i_i16[i];
end;

function simd_add_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m128i_i8[i] := a.m128i_i8[i] + b.m128i_i8[i];
end;

function simd_sub_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_i32[i] := a.m128i_i32[i] - b.m128i_i32[i];
end;

function simd_sub_epi16(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := a.m128i_i16[i] - b.m128i_i16[i];
end;

function simd_sub_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m128i_i8[i] := a.m128i_i8[i] - b.m128i_i8[i];
end;

function simd_and_si128(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] and b.m128i_u32[i];
end;

function simd_or_si128(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] or b.m128i_u32[i];
end;

function simd_xor_si128(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] xor b.m128i_u32[i];
end;

function simd_andnot_si128(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := (not a.m128i_u32[i]) and b.m128i_u32[i];
end;

function simd_cmpeq_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] = b.m128i_i32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function simd_cmpeq_epi16(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_i16[i] = b.m128i_i16[i] then
      Result.m128i_u16[i] := $FFFF
    else
      Result.m128i_u16[i] := $0000;
end;

function simd_cmpeq_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] = b.m128i_i8[i] then
      Result.m128i_u8[i] := $FF
    else
      Result.m128i_u8[i] := $00;
end;

function simd_cmpgt_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] > b.m128i_i32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function simd_cmpgt_epi16(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_i16[i] > b.m128i_i16[i] then
      Result.m128i_u16[i] := $FFFF
    else
      Result.m128i_u16[i] := $0000;
end;

function simd_cmpgt_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] > b.m128i_i8[i] then
      Result.m128i_u8[i] := $FF
    else
      Result.m128i_u8[i] := $00;
end;

function simd_slli_epi32(const a: TM128; imm8: Byte): TM128;
var
  i: Integer;
begin
  if imm8 >= 32 then
  begin
    FillChar(Result, SizeOf(Result), 0);
  end
  else
  begin
    for i := 0 to 3 do
      Result.m128i_u32[i] := a.m128i_u32[i] shl imm8;
  end;
end;

function simd_srli_epi32(const a: TM128; imm8: Byte): TM128;
var
  i: Integer;
begin
  if imm8 >= 32 then
  begin
    FillChar(Result, SizeOf(Result), 0);
  end
  else
  begin
    for i := 0 to 3 do
      Result.m128i_u32[i] := a.m128i_u32[i] shr imm8;
  end;
end;

function simd_srai_epi32(const a: TM128; imm8: Byte): TM128;
var
  i: Integer;
  shift_count: Byte;
  value: LongInt;
begin
  shift_count := imm8;
  if shift_count >= 32 then
    shift_count := 31; // 算术右移最多31位

  for i := 0 to 3 do
  begin
    value := a.m128i_i32[i];
    // 手动实现算术右移
    if shift_count = 0 then
      Result.m128i_i32[i] := value
    else if value >= 0 then
      Result.m128i_i32[i] := value shr shift_count
    else
      Result.m128i_i32[i] := (value shr shift_count) or ((-1) shl (32 - shift_count));
  end;
end;

function simd_max_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] > b.m128i_i8[i] then
      Result.m128i_i8[i] := a.m128i_i8[i]
    else
      Result.m128i_i8[i] := b.m128i_i8[i];
end;

function simd_min_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] < b.m128i_i8[i] then
      Result.m128i_i8[i] := a.m128i_i8[i]
    else
      Result.m128i_i8[i] := b.m128i_i8[i];
end;

function simd_max_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] > b.m128i_i32[i] then
      Result.m128i_i32[i] := a.m128i_i32[i]
    else
      Result.m128i_i32[i] := b.m128i_i32[i];
end;

function simd_min_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] < b.m128i_i32[i] then
      Result.m128i_i32[i] := a.m128i_i32[i]
    else
      Result.m128i_i32[i] := b.m128i_i32[i];
end;

function simd_add_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] + b.m128_f32[i];
end;

function simd_add_pd(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] + b.m128d_f64[i];
end;

function simd_mul_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i];
end;

function simd_mul_pd(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i];
end;

end.

unit fafafa.core.simd.intrinsics.mmx;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.mmx ===
  MMX (MultiMedia eXtensions) 指令集支持

  MMX 是 Intel 在 1997 年引入的第一个 SIMD 指令集扩展
  提供 64-bit 向量操作，主要用于多媒体处理

  特性：
  - 64-bit 向量寄存器 (mm0-mm7)
  - 整数运算 (8/16/32-bit)
  - 饱和运算支持
  - 与 x87 FPU 寄存器共享

  注意：现代代码建议使用 SSE2 替代 MMX

  历史意义：
  - 第一个 x86 SIMD 指令集
  - 为后续 SSE/AVX 奠定基础
  - 多媒体处理的里程碑
}

interface

type
  // MMX 64-bit 向量类型
  TM64 = record
    case Integer of
      0: (mm_u64: UInt64);
      1: (mm_i64: Int64);
      2: (mm_u32: array[0..1] of UInt32);
      3: (mm_i32: array[0..1] of LongInt);
      4: (mm_u16: array[0..3] of UInt16);
      5: (mm_i16: array[0..3] of SmallInt);
      6: (mm_u8: array[0..7] of UInt8);
      7: (mm_i8: array[0..7] of ShortInt);
  end;
  PM64 = ^TM64;

// === 1️⃣ Load / Store ===
// 加载和存储指令，用于在内存和 MMX 寄存器之间传输数据

function mmx_movd_mm(const Ptr: Pointer): TM64;
procedure mmx_movd_mm_store(var Dest: LongInt; const Src: TM64);
function mmx_movq_mm(const Ptr: Pointer): TM64;
procedure mmx_movq_mm_store(var Dest; const Src: TM64);

// === 2️⃣ Set / Zero ===
// 设置和清零指令，用于初始化 MMX 寄存器

function mmx_setzero_si64: TM64;
function mmx_set1_pi8(Value: ShortInt): TM64;
function mmx_set1_pi16(Value: SmallInt): TM64;
function mmx_set1_pi32(Value: LongInt): TM64;
function mmx_set_pi8(a7, a6, a5, a4, a3, a2, a1, a0: ShortInt): TM64;
function mmx_set_pi16(a3, a2, a1, a0: SmallInt): TM64;
function mmx_set_pi32(a1, a0: LongInt): TM64;

// === 3️⃣ Integer Arithmetic ===
// 整数运算指令，支持加法、减法、乘法和饱和运算

function mmx_paddb(a, b: TM64): TM64;
function mmx_paddw(a, b: TM64): TM64;
function mmx_paddd(a, b: TM64): TM64;
function mmx_paddq(a, b: TM64): TM64;
function mmx_paddsb(a, b: TM64): TM64;
function mmx_paddsw(a, b: TM64): TM64;
function mmx_paddusb(a, b: TM64): TM64;
function mmx_paddusw(a, b: TM64): TM64;
function mmx_psubb(a, b: TM64): TM64;
function mmx_psubw(a, b: TM64): TM64;
function mmx_psubd(a, b: TM64): TM64;
function mmx_psubq(a, b: TM64): TM64;
function mmx_psubsb(a, b: TM64): TM64;
function mmx_psubsw(a, b: TM64): TM64;
function mmx_psubusb(a, b: TM64): TM64;
function mmx_psubusw(a, b: TM64): TM64;
function mmx_pmullw(a, b: TM64): TM64;
function mmx_pmulhw(a, b: TM64): TM64;
function mmx_pmaddwd(a, b: TM64): TM64;

// === 5️⃣ Logical Operations ===
// 逻辑运算指令，支持位操作

function mmx_pand(a, b: TM64): TM64;
function mmx_pandn(a, b: TM64): TM64;
function mmx_por(a, b: TM64): TM64;
function mmx_pxor(a, b: TM64): TM64;

// === 6️⃣ Compare ===
// 比较指令，生成掩码用于条件处理

function mmx_pcmpeqb(a, b: TM64): TM64;
function mmx_pcmpeqw(a, b: TM64): TM64;
function mmx_pcmpeqd(a, b: TM64): TM64;
function mmx_pcmpgtb(a, b: TM64): TM64;
function mmx_pcmpgtw(a, b: TM64): TM64;
function mmx_pcmpgtd(a, b: TM64): TM64;

// === 7️⃣ Shift ===
// 移位指令，支持逻辑和算术移位

function mmx_psllw(a: TM64; count: TM64): TM64;
function mmx_pslld(a: TM64; count: TM64): TM64;
function mmx_psllq(a: TM64; count: TM64): TM64;
function mmx_psllw_imm(a: TM64; imm8: Byte): TM64;
function mmx_pslld_imm(a: TM64; imm8: Byte): TM64;
function mmx_psllq_imm(a: TM64; imm8: Byte): TM64;
function mmx_psrlw(a: TM64; count: TM64): TM64;
function mmx_psrld(a: TM64; count: TM64): TM64;
function mmx_psrlq(a: TM64; count: TM64): TM64;
function mmx_psrlw_imm(a: TM64; imm8: Byte): TM64;
function mmx_psrld_imm(a: TM64; imm8: Byte): TM64;
function mmx_psrlq_imm(a: TM64; imm8: Byte): TM64;
function mmx_psraw(a: TM64; count: TM64): TM64;
function mmx_psrad(a: TM64; count: TM64): TM64;
function mmx_psraw_imm(a: TM64; imm8: Byte): TM64;
function mmx_psrad_imm(a: TM64; imm8: Byte): TM64;

// === 10️⃣ Pack / Unpack ===
// 打包和解包指令，用于数据格式转换

function mmx_packsswb(a, b: TM64): TM64;
function mmx_packssdw(a, b: TM64): TM64;
function mmx_packuswb(a, b: TM64): TM64;
function mmx_punpckhbw(a, b: TM64): TM64;
function mmx_punpckhwd(a, b: TM64): TM64;
function mmx_punpckhdq(a, b: TM64): TM64;
function mmx_punpcklbw(a, b: TM64): TM64;
function mmx_punpcklwd(a, b: TM64): TM64;
function mmx_punpckldq(a, b: TM64): TM64;

// === 11️⃣ Miscellaneous ===
// 杂项指令，用于状态管理

procedure mmx_emms;

implementation

// === 1️⃣ Load / Store 实现 ===

function mmx_movd_mm(const Ptr: Pointer): TM64;
begin
  // 从内存加载 32 位整数到 MMX 寄存器（低 32 位），高 32 位清零
  mmx_movd_mm.mm_u64 := 0;  // 清零整个寄存器
  mmx_movd_mm.mm_u32[0] := PLongInt(Ptr)^;  // 加载低 32 位
end;

procedure mmx_movd_mm_store(var Dest: LongInt; const Src: TM64);
begin
  // 将 MMX 寄存器的低 32 位整数存储到内存
  Dest := Src.mm_i32[0];
end;

function mmx_movq_mm(const Ptr: Pointer): TM64;
begin
  // 从内存加载 64 位数据到 MMX 寄存器
  Result.mm_u64 := PUInt64(Ptr)^;
end;

procedure mmx_movq_mm_store(var Dest; const Src: TM64);
begin
  // 将 MMX 寄存器的 64 位数据存储到内存
  PUInt64(@Dest)^ := Src.mm_u64;
end;

// === 2️⃣ Set / Zero 实现 ===

function mmx_setzero_si64: TM64;
begin
  // 将 MMX 寄存器清零
  mmx_setzero_si64.mm_u64 := 0;
end;

function mmx_set1_pi8(Value: ShortInt): TM64;
var
  i: Integer;
begin
  // 将所有 8 位整数设置为指定值
  for i := 0 to 7 do
    Result.mm_i8[i] := Value;
end;

function mmx_set1_pi16(Value: SmallInt): TM64;
var
  i: Integer;
begin
  // 将所有 16 位整数设置为指定值
  for i := 0 to 3 do
    Result.mm_i16[i] := Value;
end;

function mmx_set1_pi32(Value: LongInt): TM64;
begin
  // 将所有 32 位整数设置为指定值
  Result.mm_i32[0] := Value;
  Result.mm_i32[1] := Value;
end;

function mmx_set_pi8(a7, a6, a5, a4, a3, a2, a1, a0: ShortInt): TM64;
begin
  // 设置 8 个 8 位整数到 MMX 寄存器（从高到低）
  Result.mm_i8[0] := a0;
  Result.mm_i8[1] := a1;
  Result.mm_i8[2] := a2;
  Result.mm_i8[3] := a3;
  Result.mm_i8[4] := a4;
  Result.mm_i8[5] := a5;
  Result.mm_i8[6] := a6;
  Result.mm_i8[7] := a7;
end;

function mmx_set_pi16(a3, a2, a1, a0: SmallInt): TM64;
begin
  // 设置 4 个 16 位整数到 MMX 寄存器（从高到低）
  Result.mm_i16[0] := a0;
  Result.mm_i16[1] := a1;
  Result.mm_i16[2] := a2;
  Result.mm_i16[3] := a3;
end;

function mmx_set_pi32(a1, a0: LongInt): TM64;
begin
  // 设置 2 个 32 位整数到 MMX 寄存器（从高到低）
  Result.mm_i32[0] := a0;
  Result.mm_i32[1] := a1;
end;

// === 3️⃣ Integer Arithmetic 实现 ===

function mmx_paddb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 8 个 8 位整数执行加法（无饱和）
  for i := 0 to 7 do
    Result.mm_i8[i] := a.mm_i8[i] + b.mm_i8[i];
end;

function mmx_paddw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位整数执行加法（无饱和）
  for i := 0 to 3 do
    Result.mm_i16[i] := a.mm_i16[i] + b.mm_i16[i];
end;

function mmx_paddd(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 2 个 32 位整数执行加法（无饱和）
  for i := 0 to 1 do
    Result.mm_i32[i] := a.mm_i32[i] + b.mm_i32[i];
end;

function mmx_paddq(a, b: TM64): TM64;
begin
  // 对 1 个 64 位整数执行加法（无饱和）
  Result.mm_i64 := a.mm_i64 + b.mm_i64;
end;

// 饱和算术运算辅助函数
function SaturateSignedByte(Value: LongInt): ShortInt;
begin
  if Value > 127 then
    Result := 127
  else if Value < -128 then
    Result := -128
  else
    Result := ShortInt(Value);
end;

function SaturateUnsignedByte(Value: LongInt): UInt8;
begin
  if Value > 255 then
    Result := 255
  else if Value < 0 then
    Result := 0
  else
    Result := UInt8(Value);
end;

function SaturateSignedWord(Value: LongInt): SmallInt;
begin
  if Value > 32767 then
    Result := 32767
  else if Value < -32768 then
    Result := -32768
  else
    Result := SmallInt(Value);
end;

function SaturateUnsignedWord(Value: LongInt): UInt16;
begin
  if Value > 65535 then
    Result := 65535
  else if Value < 0 then
    Result := 0
  else
    Result := UInt16(Value);
end;

function mmx_paddsb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 8 个 8 位有符号整数执行饱和加法
  for i := 0 to 7 do
    Result.mm_i8[i] := SaturateSignedByte(LongInt(a.mm_i8[i]) + LongInt(b.mm_i8[i]));
end;

function mmx_paddsw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位有符号整数执行饱和加法
  for i := 0 to 3 do
    Result.mm_i16[i] := SaturateSignedWord(LongInt(a.mm_i16[i]) + LongInt(b.mm_i16[i]));
end;

function mmx_paddusb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 8 个 8 位无符号整数执行饱和加法
  for i := 0 to 7 do
    Result.mm_u8[i] := SaturateUnsignedByte(LongInt(a.mm_u8[i]) + LongInt(b.mm_u8[i]));
end;

function mmx_paddusw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位无符号整数执行饱和加法
  for i := 0 to 3 do
    Result.mm_u16[i] := SaturateUnsignedWord(LongInt(a.mm_u16[i]) + LongInt(b.mm_u16[i]));
end;

// 减法运算
function mmx_psubb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 8 个 8 位整数执行减法（无饱和）
  for i := 0 to 7 do
    Result.mm_i8[i] := a.mm_i8[i] - b.mm_i8[i];
end;

function mmx_psubw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位整数执行减法（无饱和）
  for i := 0 to 3 do
    Result.mm_i16[i] := a.mm_i16[i] - b.mm_i16[i];
end;

function mmx_psubd(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 2 个 32 位整数执行减法（无饱和）
  for i := 0 to 1 do
    Result.mm_i32[i] := a.mm_i32[i] - b.mm_i32[i];
end;

function mmx_psubq(a, b: TM64): TM64;
begin
  // 对 1 个 64 位整数执行减法（无饱和）
  Result.mm_i64 := a.mm_i64 - b.mm_i64;
end;

function mmx_psubsb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 8 个 8 位有符号整数执行饱和减法
  for i := 0 to 7 do
    Result.mm_i8[i] := SaturateSignedByte(LongInt(a.mm_i8[i]) - LongInt(b.mm_i8[i]));
end;

function mmx_psubsw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位有符号整数执行饱和减法
  for i := 0 to 3 do
    Result.mm_i16[i] := SaturateSignedWord(LongInt(a.mm_i16[i]) - LongInt(b.mm_i16[i]));
end;

function mmx_psubusb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 8 个 8 位无符号整数执行饱和减法
  for i := 0 to 7 do
    Result.mm_u8[i] := SaturateUnsignedByte(LongInt(a.mm_u8[i]) - LongInt(b.mm_u8[i]));
end;

function mmx_psubusw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位无符号整数执行饱和减法
  for i := 0 to 3 do
    Result.mm_u16[i] := SaturateUnsignedWord(LongInt(a.mm_u16[i]) - LongInt(b.mm_u16[i]));
end;

// 乘法运算
function mmx_pmullw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位整数执行乘法，保留低 16 位结果
  for i := 0 to 3 do
    Result.mm_i16[i] := SmallInt((LongInt(a.mm_i16[i]) * LongInt(b.mm_i16[i])) and $FFFF);
end;

function mmx_pmulhw(a, b: TM64): TM64;
var
  i: Integer;
  temp: LongInt;
begin
  // 对 4 个 16 位整数执行乘法，保留高 16 位结果
  for i := 0 to 3 do
  begin
    temp := LongInt(a.mm_i16[i]) * LongInt(b.mm_i16[i]);
    Result.mm_i16[i] := SmallInt((temp shr 16) and $FFFF);
  end;
end;

function mmx_pmaddwd(a, b: TM64): TM64;
var
  temp0, temp1: LongInt;
begin
  // 对 4 个 16 位整数执行乘法，成对相加得到 2 个 32 位结果
  temp0 := LongInt(a.mm_i16[0]) * LongInt(b.mm_i16[0]) + LongInt(a.mm_i16[1]) * LongInt(b.mm_i16[1]);
  temp1 := LongInt(a.mm_i16[2]) * LongInt(b.mm_i16[2]) + LongInt(a.mm_i16[3]) * LongInt(b.mm_i16[3]);
  Result.mm_i32[0] := temp0;
  Result.mm_i32[1] := temp1;
end;

// === 5️⃣ Logical Operations 实现 ===

function mmx_pand(a, b: TM64): TM64;
begin
  // 对 64 位寄存器执行按位 AND 操作
  Result.mm_u64 := a.mm_u64 and b.mm_u64;
end;

function mmx_pandn(a, b: TM64): TM64;
begin
  // 对 64 位寄存器执行按位 AND NOT 操作（~a & b）
  Result.mm_u64 := (not a.mm_u64) and b.mm_u64;
end;

function mmx_por(a, b: TM64): TM64;
begin
  // 对 64 位寄存器执行按位 OR 操作
  Result.mm_u64 := a.mm_u64 or b.mm_u64;
end;

function mmx_pxor(a, b: TM64): TM64;
begin
  // 对 64 位寄存器执行按位 XOR 操作
  Result.mm_u64 := a.mm_u64 xor b.mm_u64;
end;

// === 6️⃣ Compare 实现 ===

function mmx_pcmpeqb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 比较 8 个 8 位整数，等于则置 1（0xFF），否则置 0
  for i := 0 to 7 do
    if a.mm_i8[i] = b.mm_i8[i] then
      Result.mm_u8[i] := $FF
    else
      Result.mm_u8[i] := $00;
end;

function mmx_pcmpeqw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 比较 4 个 16 位整数，等于则置 1（0xFFFF），否则置 0
  for i := 0 to 3 do
    if a.mm_i16[i] = b.mm_i16[i] then
      Result.mm_u16[i] := $FFFF
    else
      Result.mm_u16[i] := $0000;
end;

function mmx_pcmpeqd(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 比较 2 个 32 位整数，等于则置 1（0xFFFFFFFF），否则置 0
  for i := 0 to 1 do
    if a.mm_i32[i] = b.mm_i32[i] then
      Result.mm_u32[i] := $FFFFFFFF
    else
      Result.mm_u32[i] := $00000000;
end;

function mmx_pcmpgtb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 比较 8 个 8 位有符号整数，大于则置 1（0xFF），否则置 0
  for i := 0 to 7 do
    if a.mm_i8[i] > b.mm_i8[i] then
      Result.mm_u8[i] := $FF
    else
      Result.mm_u8[i] := $00;
end;

function mmx_pcmpgtw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 比较 4 个 16 位有符号整数，大于则置 1（0xFFFF），否则置 0
  for i := 0 to 3 do
    if a.mm_i16[i] > b.mm_i16[i] then
      Result.mm_u16[i] := $FFFF
    else
      Result.mm_u16[i] := $0000;
end;

function mmx_pcmpgtd(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 比较 2 个 32 位有符号整数，大于则置 1（0xFFFFFFFF），否则置 0
  for i := 0 to 1 do
    if a.mm_i32[i] > b.mm_i32[i] then
      Result.mm_u32[i] := $FFFFFFFF
    else
      Result.mm_u32[i] := $00000000;
end;

// === 7️⃣ Shift 实现 ===

function mmx_psllw(a: TM64; count: TM64): TM64;
var
  i: Integer;
  shift_count: Byte;
begin
  // 对 4 个 16 位整数执行左移（逻辑移位）
  shift_count := count.mm_u8[0];  // 使用 count 的低 8 位
  if shift_count >= 16 then
  begin
    // 移位超过位宽，结果为 0
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 3 do
      Result.mm_u16[i] := a.mm_u16[i] shl shift_count;
  end;
end;

function mmx_pslld(a: TM64; count: TM64): TM64;
var
  i: Integer;
  shift_count: Byte;
begin
  // 对 2 个 32 位整数执行左移（逻辑移位）
  shift_count := count.mm_u8[0];
  if shift_count >= 32 then
  begin
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 1 do
      Result.mm_u32[i] := a.mm_u32[i] shl shift_count;
  end;
end;

function mmx_psllq(a: TM64; count: TM64): TM64;
var
  shift_count: Byte;
begin
  // 对 1 个 64 位整数执行左移（逻辑移位）
  shift_count := count.mm_u8[0];
  if shift_count >= 64 then
    Result.mm_u64 := 0
  else
    Result.mm_u64 := a.mm_u64 shl shift_count;
end;

function mmx_psllw_imm(a: TM64; imm8: Byte): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位整数执行左移（逻辑移位，使用立即数）
  if imm8 >= 16 then
  begin
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 3 do
      Result.mm_u16[i] := a.mm_u16[i] shl imm8;
  end;
end;

function mmx_pslld_imm(a: TM64; imm8: Byte): TM64;
var
  i: Integer;
begin
  // 对 2 个 32 位整数执行左移（逻辑移位，使用立即数）
  if imm8 >= 32 then
  begin
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 1 do
      Result.mm_u32[i] := a.mm_u32[i] shl imm8;
  end;
end;

function mmx_psllq_imm(a: TM64; imm8: Byte): TM64;
begin
  // 对 1 个 64 位整数执行左移（逻辑移位，使用立即数）
  if imm8 >= 64 then
    Result.mm_u64 := 0
  else
    Result.mm_u64 := a.mm_u64 shl imm8;
end;

// 逻辑右移
function mmx_psrlw(a: TM64; count: TM64): TM64;
var
  i: Integer;
  shift_count: Byte;
begin
  // 对 4 个 16 位整数执行逻辑右移
  shift_count := count.mm_u8[0];
  if shift_count >= 16 then
  begin
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 3 do
      Result.mm_u16[i] := a.mm_u16[i] shr shift_count;
  end;
end;

function mmx_psrld(a: TM64; count: TM64): TM64;
var
  i: Integer;
  shift_count: Byte;
begin
  // 对 2 个 32 位整数执行逻辑右移
  shift_count := count.mm_u8[0];
  if shift_count >= 32 then
  begin
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 1 do
      Result.mm_u32[i] := a.mm_u32[i] shr shift_count;
  end;
end;

function mmx_psrlq(a: TM64; count: TM64): TM64;
var
  shift_count: Byte;
begin
  // 对 1 个 64 位整数执行逻辑右移
  shift_count := count.mm_u8[0];
  if shift_count >= 64 then
    Result.mm_u64 := 0
  else
    Result.mm_u64 := a.mm_u64 shr shift_count;
end;

function mmx_psrlw_imm(a: TM64; imm8: Byte): TM64;
var
  i: Integer;
begin
  // 对 4 个 16 位整数执行逻辑右移（使用立即数）
  if imm8 >= 16 then
  begin
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 3 do
      Result.mm_u16[i] := a.mm_u16[i] shr imm8;
  end;
end;

function mmx_psrld_imm(a: TM64; imm8: Byte): TM64;
var
  i: Integer;
begin
  // 对 2 个 32 位整数执行逻辑右移（使用立即数）
  if imm8 >= 32 then
  begin
    Result.mm_u64 := 0;
  end
  else
  begin
    for i := 0 to 1 do
      Result.mm_u32[i] := a.mm_u32[i] shr imm8;
  end;
end;

function mmx_psrlq_imm(a: TM64; imm8: Byte): TM64;
begin
  // 对 1 个 64 位整数执行逻辑右移（使用立即数）
  if imm8 >= 64 then
    Result.mm_u64 := 0
  else
    Result.mm_u64 := a.mm_u64 shr imm8;
end;

// 算术右移（保留符号位）
function mmx_psraw(a: TM64; count: TM64): TM64;
var
  i: Integer;
  shift_count: Byte;
  value: SmallInt;
begin
  // 对 4 个 16 位有符号整数执行算术右移
  shift_count := count.mm_u8[0];
  if shift_count >= 16 then
    shift_count := 15;  // 最多移位 15 位，保留符号位

  for i := 0 to 3 do
  begin
    value := a.mm_i16[i];
    if shift_count = 0 then
      Result.mm_i16[i] := value
    else if value >= 0 then
      Result.mm_i16[i] := value shr shift_count
    else
      Result.mm_i16[i] := SmallInt((value shr shift_count) or ((-1) shl (16 - shift_count)));
  end;
end;

function mmx_psrad(a: TM64; count: TM64): TM64;
var
  i: Integer;
  shift_count: Byte;
  value: LongInt;
begin
  // 对 2 个 32 位有符号整数执行算术右移
  shift_count := count.mm_u8[0];
  if shift_count >= 32 then
    shift_count := 31;  // 最多移位 31 位，保留符号位

  for i := 0 to 1 do
  begin
    value := a.mm_i32[i];
    if shift_count = 0 then
      Result.mm_i32[i] := value
    else if value >= 0 then
      Result.mm_i32[i] := value shr shift_count
    else
      Result.mm_i32[i] := (value shr shift_count) or ((-1) shl (32 - shift_count));
  end;
end;

function mmx_psraw_imm(a: TM64; imm8: Byte): TM64;
var
  i: Integer;
  shift_count: Byte;
  value: SmallInt;
begin
  // 对 4 个 16 位有符号整数执行算术右移（使用立即数）
  shift_count := imm8;
  if shift_count >= 16 then
    shift_count := 15;

  for i := 0 to 3 do
  begin
    value := a.mm_i16[i];
    if shift_count = 0 then
      Result.mm_i16[i] := value
    else if value >= 0 then
      Result.mm_i16[i] := value shr shift_count
    else
      Result.mm_i16[i] := SmallInt((value shr shift_count) or ((-1) shl (16 - shift_count)));
  end;
end;

function mmx_psrad_imm(a: TM64; imm8: Byte): TM64;
var
  i: Integer;
  shift_count: Byte;
  value: LongInt;
begin
  // 对 2 个 32 位有符号整数执行算术右移（使用立即数）
  shift_count := imm8;
  if shift_count >= 32 then
    shift_count := 31;

  for i := 0 to 1 do
  begin
    value := a.mm_i32[i];
    if shift_count = 0 then
      Result.mm_i32[i] := value
    else if value >= 0 then
      Result.mm_i32[i] := value shr shift_count
    else
      Result.mm_i32[i] := (value shr shift_count) or ((-1) shl (32 - shift_count));
  end;
end;

// === 10️⃣ Pack / Unpack 实现 ===

function mmx_packsswb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 将 8 个 16 位有符号整数（两个寄存器）打包为 8 个 8 位有符号整数（带饱和）
  for i := 0 to 3 do
  begin
    Result.mm_i8[i] := SaturateSignedByte(a.mm_i16[i]);
    Result.mm_i8[i + 4] := SaturateSignedByte(b.mm_i16[i]);
  end;
end;

function mmx_packssdw(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 将 4 个 32 位有符号整数（两个寄存器）打包为 4 个 16 位有符号整数（带饱和）
  for i := 0 to 1 do
  begin
    Result.mm_i16[i] := SaturateSignedWord(a.mm_i32[i]);
    Result.mm_i16[i + 2] := SaturateSignedWord(b.mm_i32[i]);
  end;
end;

function mmx_packuswb(a, b: TM64): TM64;
var
  i: Integer;
begin
  // 将 8 个 16 位有符号整数（两个寄存器）打包为 8 个 8 位无符号整数（带饱和）
  for i := 0 to 3 do
  begin
    Result.mm_u8[i] := SaturateUnsignedByte(a.mm_i16[i]);
    Result.mm_u8[i + 4] := SaturateUnsignedByte(b.mm_i16[i]);
  end;
end;

function mmx_punpckhbw(a, b: TM64): TM64;
begin
  // 解包高位 8 位整数（从两个寄存器交织）
  Result.mm_u8[0] := a.mm_u8[4];
  Result.mm_u8[1] := b.mm_u8[4];
  Result.mm_u8[2] := a.mm_u8[5];
  Result.mm_u8[3] := b.mm_u8[5];
  Result.mm_u8[4] := a.mm_u8[6];
  Result.mm_u8[5] := b.mm_u8[6];
  Result.mm_u8[6] := a.mm_u8[7];
  Result.mm_u8[7] := b.mm_u8[7];
end;

function mmx_punpckhwd(a, b: TM64): TM64;
begin
  // 解包高位 16 位整数（从两个寄存器交织）
  Result.mm_u16[0] := a.mm_u16[2];
  Result.mm_u16[1] := b.mm_u16[2];
  Result.mm_u16[2] := a.mm_u16[3];
  Result.mm_u16[3] := b.mm_u16[3];
end;

function mmx_punpckhdq(a, b: TM64): TM64;
begin
  // 解包高位 32 位整数（从两个寄存器交织）
  Result.mm_u32[0] := a.mm_u32[1];
  Result.mm_u32[1] := b.mm_u32[1];
end;

function mmx_punpcklbw(a, b: TM64): TM64;
begin
  // 解包低位 8 位整数（从两个寄存器交织）
  Result.mm_u8[0] := a.mm_u8[0];
  Result.mm_u8[1] := b.mm_u8[0];
  Result.mm_u8[2] := a.mm_u8[1];
  Result.mm_u8[3] := b.mm_u8[1];
  Result.mm_u8[4] := a.mm_u8[2];
  Result.mm_u8[5] := b.mm_u8[2];
  Result.mm_u8[6] := a.mm_u8[3];
  Result.mm_u8[7] := b.mm_u8[3];
end;

function mmx_punpcklwd(a, b: TM64): TM64;
begin
  // 解包低位 16 位整数（从两个寄存器交织）
  Result.mm_u16[0] := a.mm_u16[0];
  Result.mm_u16[1] := b.mm_u16[0];
  Result.mm_u16[2] := a.mm_u16[1];
  Result.mm_u16[3] := b.mm_u16[1];
end;

function mmx_punpckldq(a, b: TM64): TM64;
begin
  // 解包低位 32 位整数（从两个寄存器交织）
  Result.mm_u32[0] := a.mm_u32[0];
  Result.mm_u32[1] := b.mm_u32[0];
end;

// === 11️⃣ Miscellaneous 实现 ===

procedure mmx_emms;
begin
  // 清空 MMX 状态，恢复 FPU 寄存器可用性
  // 在实际实现中，这里应该执行 EMMS 指令
  // Pascal 版本中这是一个空操作，因为我们没有真正使用 MMX 寄存器
  // 但在真实的汇编实现中，这个指令非常重要
end;

end.

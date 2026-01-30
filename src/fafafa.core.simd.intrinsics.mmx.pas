unit fafafa.core.simd.intrinsics.mmx;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.mmx ===
  MMX (MultiMedia eXtensions) 指令集支�?
  MMX �?Intel �?1997 年引入的第一�?SIMD 指令集扩�?  提供 64-bit 向量操作，主要用于多媒体处理

  特性：
  - 64-bit 向量寄存�?(mm0-mm7)
  - 整数运算 (8/16/32-bit)

  编译选项�?  - 默认使用 Pascal 模拟实现，兼容性好
  - 定义 USE_INLINE_ASM 可启用内联汇编实现（需�?x86/x64 平台�?  - 饱和运算支持
  - �?x87 FPU 寄存器共�?
  注意：现代代码建议使�?SSE2 替代 MMX

  历史意义�?  - 第一�?x86 SIMD 指令�?  - 为后�?SSE/AVX 奠定基础
  - 多媒体处理的里程�?}

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

// === Load / Store ===
// 加载和存储指令，用于在内存和 MMX 寄存器之间传输数�?
function mmx_movd_mm(const Ptr: Pointer): TM64;
procedure mmx_movd_mm_store(var Dest: LongInt; const Src: TM64);
function mmx_movq_mm(const Ptr: Pointer): TM64;
procedure mmx_movq_mm_store(var Dest; const Src: TM64);

// === Set / Zero ===
// 设置和清零指令，用于初始�?MMX 寄存�?
function mmx_setzero_si64: TM64;
function mmx_set1_pi8(Value: ShortInt): TM64;
function mmx_set1_pi16(Value: SmallInt): TM64;
function mmx_set1_pi32(Value: LongInt): TM64;
function mmx_set_pi8(a7, a6, a5, a4, a3, a2, a1, a0: ShortInt): TM64;
function mmx_set_pi16(a3, a2, a1, a0: SmallInt): TM64;
function mmx_set_pi32(a1, a0: LongInt): TM64;

// === Integer Arithmetic ===
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
// 比较指令，生成掩码用于条件处�?
function mmx_pcmpeqb(a, b: TM64): TM64;
function mmx_pcmpeqw(a, b: TM64): TM64;
function mmx_pcmpeqd(a, b: TM64): TM64;
function mmx_pcmpgtb(a, b: TM64): TM64;
function mmx_pcmpgtw(a, b: TM64): TM64;
function mmx_pcmpgtd(a, b: TM64): TM64;

// === 7️⃣ Shift ===
// 移位指令，支持逻辑和算术移�?
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
// 杂项指令，用于状态管�?
procedure mmx_emms;

// === 🆕 补充的真正MMX指令 ===

// 额外的数据传输指�
function mmx_movd_r32(mm: TM64): LongWord;        // 从MMX�?2位寄存器
function mmx_movd_r32_to_mm(r32: LongWord): TM64; // �?2位寄存器到MMX

// 额外的移位指令变�
function mmx_psllw_mm(a, count: TM64): TM64;      // 16位左�?MMX寄存器计�?
function mmx_psrlw_mm(a, count: TM64): TM64;      // 16位右�?MMX寄存器计�?
function mmx_psraw_mm(a, count: TM64): TM64;      // 16位算术右�?MMX寄存器计�?

// 额外的打包指�
function mmx_packusdw(a, b: TM64): TM64;          // 32位到16位无符号打包

// 额外的解包指令变�
function mmx_punpcklbw_mem(a: TM64; mem: Pointer): TM64; // 从内存解包低位字�
function mmx_punpcklwd_mem(a: TM64; mem: Pointer): TM64; // 从内存解包低位字
function mmx_punpckldq_mem(a: TM64; mem: Pointer): TM64; // 从内存解包低位双�?
implementation

// === 1️⃣ Load / Store 实现 ===

// 功能：从内存加载32位整数到MMX寄存器低位，高位清零
// 输入：Ptr - 指向32位整数的内存地址
// 输出：TM64 - �?2位为加载的整数，�?2位为0
function mmx_movd_mm(const Ptr: Pointer): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: RCX = Ptr
    movd mm0, dword ptr [rcx]
  {$ELSE}
    // SysV x64: RDI = Ptr
    movd mm0, dword ptr [rdi]
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  // x86: 参数通过栈传�?  mov eax, Ptr
  movd mm0, dword ptr [eax]
  movd eax, mm0
  xor edx, edx
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：将MMX寄存器的�?2位整数存储到内存
// 输入：Dest - 目标内存地址；Src - MMX寄存�
procedure mmx_movd_mm_store(var Dest: LongInt; const Src: TM64); {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: RCX = @Dest, RDX = Src
    movq mm0, rdx
    movd dword ptr [rcx], mm0
  {$ELSE}
    // SysV x64: RDI = @Dest, RSI = Src
    movq mm0, rsi
    movd dword ptr [rdi], mm0
  {$ENDIF}
{$ELSE}
  // x86: 参数通过栈传�?  movq mm0, qword ptr [Src]
  mov eax, Dest
  movd dword ptr [eax], mm0
{$ENDIF}
end;

// 功能：从内存加载64位数据到MMX寄存�?// 输入：Ptr - 指向64位数据的内存地址
// 输出：TM64 - 包含加载�?4位数�
function mmx_movq_mm(const Ptr: Pointer): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: RCX = Ptr
    movq mm0, qword ptr [rcx]
  {$ELSE}
    // SysV x64: RDI = Ptr
    movq mm0, qword ptr [rdi]
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  // x86: 参数通过栈传�?  mov eax, Ptr
  movq mm0, qword ptr [eax]
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [Ptr]
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：将MMX寄存器的64位数据存储到内存
// 输入：Dest - 目标内存地址；Src - MMX寄存�
procedure mmx_movq_mm_store(var Dest; const Src: TM64); {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: RCX = @Dest, RDX = Src
    movq mm0, rdx
    movq qword ptr [rcx], mm0
  {$ELSE}
    // SysV x64: RDI = @Dest, RSI = Src
    movq mm0, rsi
    movq qword ptr [rdi], mm0
  {$ENDIF}
{$ELSE}
  // x86: 参数通过栈传�?  movq mm0, qword ptr [Src]
  mov eax, Dest
  movq qword ptr [eax], mm0
{$ENDIF}
end;

// === 2️⃣ Set / Zero 实现 ===

// 功能：将MMX寄存器清�?// 输出：TM64 - 全零�?4位寄存器
function mmx_setzero_si64: TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  pxor mm0, mm0
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  pxor mm0, mm0
  movd eax, mm0
  xor edx, edx
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：将所�?�?位整数设置为指定值（广播�?// 输入：Value - 8位有符号整数
// 输出：TM64 - 包含8个相同Value�?位整�
function mmx_set1_pi8(Value: ShortInt): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: ECX = Value (�?�?
    movd mm0, ecx
  {$ELSE}
    // SysV x64: EDI = Value (�?�?
    movd mm0, edi
  {$ENDIF}
  punpcklbw mm0, mm0  // 复制�?6�?  punpcklwd mm0, mm0  // 复制�?2�?  punpckldq mm0, mm0  // 复制�?4�?  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movd mm0, Value
  punpcklbw mm0, mm0
  punpcklwd mm0, mm0
  punpckldq mm0, mm0
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [Value]
  punpcklbw mm0, mm0
  punpcklwd mm0, mm0
  punpckldq mm0, mm0
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：将所�?�?6位整数设置为指定值（广播�?// 输入：Value - 16位有符号整数
// 输出：TM64 - 包含4个相同Value�?6位整�
function mmx_set1_pi16(Value: SmallInt): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movd mm0, ecx
  {$ELSE}
    movd mm0, edi
  {$ENDIF}
  punpcklwd mm0, mm0  // 复制�?2�?  punpckldq mm0, mm0  // 复制�?4�?  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movd mm0, Value
  punpcklwd mm0, mm0
  punpckldq mm0, mm0
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [Value]
  punpcklwd mm0, mm0
  punpckldq mm0, mm0
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：将所�?�?2位整数设置为指定值（广播�?// 输入：Value - 32位有符号整数
// 输出：TM64 - 包含2个相同Value�?2位整�
function mmx_set1_pi32(Value: LongInt): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movd mm0, ecx
  {$ELSE}
    movd mm0, edi
  {$ENDIF}
  punpckldq mm0, mm0  // 复制�?4�?  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movd mm0, Value
  punpckldq mm0, mm0
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [Value]
  punpckldq mm0, mm0
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：设�?�?位整数到MMX寄存器（从高到低�?// 输入：a7-a0 - 8�?位有符号整数
// 输出：TM64 - 包含指定�?�?位整�
function mmx_set_pi8(a7, a6, a5, a4, a3, a2, a1, a0: ShortInt): TM64;
begin
  Result.mm_i8[0] := a0;
  Result.mm_i8[1] := a1;
  Result.mm_i8[2] := a2;
  Result.mm_i8[3] := a3;
  Result.mm_i8[4] := a4;
  Result.mm_i8[5] := a5;
  Result.mm_i8[6] := a6;
  Result.mm_i8[7] := a7;
end;

// 功能：设�?�?6位整数到MMX寄存器（从高到低�?// 输入：a3-a0 - 4�?6位有符号整数
// 输出：TM64 - 包含指定�?�?6位整�
function mmx_set_pi16(a3, a2, a1, a0: SmallInt): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: RCX=a3, RDX=a2, R8=a1, R9=a0
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov word ptr [rsp], cx     // a3
    mov word ptr [rsp+2], dx   // a2
    mov word ptr [rsp+4], r8w  // a1
    mov word ptr [rsp+6], r9w  // a0
    movq mm0, qword ptr [rsp]
    add rsp, 8
    pop rbp
  {$ELSE}
    // SysV x64: RDI=a3, RSI=a2, RDX=a1, RCX=a0
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov word ptr [rsp], di
    mov word ptr [rsp+2], si
    mov word ptr [rsp+4], dx
    mov word ptr [rsp+6], cx
    movq mm0, qword ptr [rsp]
    add rsp, 8
    pop rbp
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  // x86: 参数通过栈传�?  push ebp
  mov ebp, esp
  sub esp, 8
  mov ax, word ptr [ebp+8]   // a0
  mov word ptr [esp+6], ax
  mov ax, word ptr [ebp+12]  // a1
  mov word ptr [esp+4], ax
  mov ax, word ptr [ebp+16]  // a2
  mov word ptr [esp+2], ax
  mov ax, word ptr [ebp+20]  // a3
  mov word ptr [esp], ax
  movq mm0, qword ptr [esp]
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [esp]
  movq qword ptr [Result], mm0
  add esp, 8
  pop ebp
{$ENDIF}
end;

// 功能：设�?�?2位整数到MMX寄存器（从高到低�?// 输入：a1, a0 - 2�?2位有符号整数
// 输出：TM64 - 包含指定�?�?2位整�
function mmx_set_pi32(a1, a0: LongInt): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: RCX=a1, RDX=a0
    movd mm0, edx  // a0 到低32�?    movd mm1, ecx  // a1 到临时寄存器
    psllq mm1, 32  // a1 移到�?2�?    por mm0, mm1   // 合并
  {$ELSE}
    // SysV x64: RDI=a1, RSI=a0
    movd mm0, esi  // a0 到低32�?    movd mm1, edi  // a1 到临时寄存器
    psllq mm1, 32  // a1 移到�?2�?    por mm0, mm1   // 合并
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  // x86: 参数通过栈传�?  movd mm0, a0   // a0 到低32�?  movd mm1, a1   // a1 到临时寄存器
  psllq mm1, 32  // a1 移到�?2�?  por mm0, mm1   // 合并
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movd mm0, a0
  movd mm1, a1
  psllq mm1, 32
  por mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// === 3️⃣ Integer Arithmetic 实现 ===

// 功能：对8�?位整数执行加法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?位整�?// 输出：TM64 - 包含8个加法结�
function mmx_paddb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: RCX=a, RDX=b
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    // SysV x64: RDI=a, RSI=b
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  // x86: 参数通过栈传�?  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位整数执行加法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?6位整�?// 输出：TM64 - 包含4个加法结�
function mmx_paddw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位整数执行加法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?2位整�?// 输出：TM64 - 包含2个加法结�
function mmx_paddd(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddd mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddd mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddd mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对1�?4位整数执行加法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?4位整�?// 输出：TM64 - 包含1个加法结�
function mmx_paddq(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddq mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对8�?位有符号整数执行饱和加法
// 输入：a, b - 两个TM64寄存器，各包�?�?位有符号整数
// 输出：TM64 - 包含8个饱和加法结�
function mmx_paddsb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddsb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddsb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddsb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位有符号整数执行饱和加法
// 输入：a, b - 两个TM64寄存器，各包�?�?6位有符号整数
// 输出：TM64 - 包含4个饱和加法结�
function mmx_paddsw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddsw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddsw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddsw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对8�?位无符号整数执行饱和加法
// 输入：a, b - 两个TM64寄存器，各包�?�?位无符号整数
// 输出：TM64 - 包含8个饱和加法结�
function mmx_paddusb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddusb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddusb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddusb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位无符号整数执行饱和加法
// 输入：a, b - 两个TM64寄存器，各包�?�?6位无符号整数
// 输出：TM64 - 包含4个饱和加法结�
function mmx_paddusw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  paddusw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddusw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  paddusw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对8�?位整数执行减法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?位整�?// 输出：TM64 - 包含8个减法结�
function mmx_psubb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位整数执行减法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?6位整�?// 输出：TM64 - 包含4个减法结�
function mmx_psubw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位整数执行减法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?2位整�?// 输出：TM64 - 包含2个减法结�
function mmx_psubd(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubd mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubd mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubd mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对1�?4位整数执行减法（无饱和）
// 输入：a, b - 两个TM64寄存器，各包�?�?4位整�?// 输出：TM64 - 包含1个减法结�
function mmx_psubq(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubq mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对8�?位有符号整数执行饱和减法
function mmx_psubsb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubsb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubsb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubsb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位有符号整数执行饱和减法
function mmx_psubsw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubsw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubsw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubsw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对8�?位无符号整数执行饱和减法
function mmx_psubusb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubusb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubusb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubusb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位无符号整数执行饱和减法
function mmx_psubusw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psubusw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubusw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  psubusw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位整数执行乘法，保留�?6位结�
function mmx_pmullw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pmullw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pmullw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pmullw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位整数执行乘法，保留�?6位结�
function mmx_pmulhw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pmulhw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pmulhw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pmulhw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位整数执行乘法，成对相加得到2�?2位结�
function mmx_pmaddwd(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pmaddwd mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pmaddwd mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pmaddwd mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// === 5️⃣ Logical Operations 实现 ===

// 功能：对64位寄存器执行按位AND操作
function mmx_pand(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pand mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pand mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pand mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对64位寄存器执行按位AND NOT操作（~a & b�
function mmx_pandn(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pandn mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pandn mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pandn mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对64位寄存器执行按位OR操作
function mmx_por(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  por mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  por mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  por mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对64位寄存器执行按位XOR操作
function mmx_pxor(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pxor mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pxor mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pxor mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// === 6️⃣ Compare 实现 ===

// 功能：比�?�?位整数，等于则置1�?xFF），否则�?
function mmx_pcmpeqb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pcmpeqb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpeqb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpeqb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：比�?�?6位整数，等于则置1�?xFFFF），否则�?
function mmx_pcmpeqw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pcmpeqw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpeqw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpeqw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：比�?�?2位整数，等于则置1�?xFFFFFFFF），否则�?
function mmx_pcmpeqd(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pcmpeqd mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpeqd mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpeqd mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：比�?�?位有符号整数，大于则�?�?xFF），否则�?
function mmx_pcmpgtb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pcmpgtb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpgtb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpgtb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：比�?�?6位有符号整数，大于则�?�?xFFFF），否则�?
function mmx_pcmpgtw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pcmpgtw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpgtw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpgtw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：比�?�?2位有符号整数，大于则�?�?xFFFFFFFF），否则�?
function mmx_pcmpgtd(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pcmpgtd mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpgtd mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  pcmpgtd mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// === 7️⃣ Shift 实现 ===

// 功能：对4�?6位整数执行左移（逻辑移位�
function mmx_psllw(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psllw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psllw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psllw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位整数执行左移（逻辑移位�
function mmx_pslld(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  pslld mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  pslld mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  pslld mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对1�?4位整数执行左移（逻辑移位�
function mmx_psllq(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psllq mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psllq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psllq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位整数执行左移（逻辑移位，使用立即数�
function mmx_psllw_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    psllw mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    psllw mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psllw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psllw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位整数执行左移（逻辑移位，使用立即数�
function mmx_pslld_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    pslld mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    pslld mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  pslld mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  pslld mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对1�?4位整数执行左移（逻辑移位，使用立即数�
function mmx_psllq_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    psllq mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    psllq mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psllq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psllq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 逻辑右移
// 功能：对4�?6位整数执行逻辑右移
function mmx_psrlw(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psrlw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrlw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrlw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位整数执行逻辑右移
function mmx_psrld(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psrld mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrld mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrld mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对1�?4位整数执行逻辑右移
function mmx_psrlq(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psrlq mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrlq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrlq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位整数执行逻辑右移（使用立即数�
function mmx_psrlw_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    psrlw mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    psrlw mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrlw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrlw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位整数执行逻辑右移（使用立即数�
function mmx_psrld_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    psrld mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    psrld mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrld mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrld mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对1�?4位整数执行逻辑右移（使用立即数�
function mmx_psrlq_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    psrlq mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    psrlq mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrlq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrlq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位有符号整数执行算术右移
function mmx_psraw(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psraw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psraw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psraw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位有符号整数执行算术右移
function mmx_psrad(a: TM64; count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psrad mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrad mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrad mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对4�?6位有符号整数执行算术右移（使用立即数�
function mmx_psraw_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    psraw mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    psraw mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psraw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psraw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：对2�?2位有符号整数执行算术右移（使用立即数�
function mmx_psrad_imm(a: TM64; imm8: Byte): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movd mm1, edx
    psrad mm0, mm1
  {$ELSE}
    movq mm0, rdi
    movd mm1, esi
    psrad mm0, mm1
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrad mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movd mm1, imm8
  psrad mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// === 10️⃣ Pack / Unpack 实现 ===

// 功能：将8�?6位有符号整数打包�?�?位有符号整数（带饱和�
function mmx_packsswb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  packsswb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  packsswb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  packsswb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：将4�?2位有符号整数打包�?�?6位有符号整数（带饱和�
function mmx_packssdw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  packssdw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  packssdw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  packssdw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：将8�?6位有符号整数打包�?�?位无符号整数（带饱和�
function mmx_packuswb(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  packuswb mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  packuswb mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  packuswb mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：解包高�?位整数（从两个寄存器交织�
function mmx_punpckhbw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  punpckhbw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckhbw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckhbw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：解包高�?6位整数（从两个寄存器交织�
function mmx_punpckhwd(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  punpckhwd mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckhwd mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckhwd mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：解包高�?2位整数（从两个寄存器交织�
function mmx_punpckhdq(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  punpckhdq mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckhdq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckhdq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：解包低�?位整数（从两个寄存器交织�
function mmx_punpcklbw(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  punpcklbw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpcklbw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpcklbw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：解包低�?6位整数（从两个寄存器交织�
function mmx_punpcklwd(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  punpcklwd mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpcklwd mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpcklwd mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：解包低�?2位整数（从两个寄存器交织�
function mmx_punpckldq(a, b: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  punpckldq mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckldq mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [b]
  punpckldq mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// === 11️⃣ Miscellaneous 实现 ===

// 功能：清空MMX状态，恢复FPU寄存器可用�?// 重要：在MMX代码和FPU代码之间必须调用此函�
procedure mmx_emms; {$IFDEF FPC}assembler;{$ENDIF}
asm
  emms
end;

// === 🆕 补充的真正MMX指令实现 ===

// 功能：从MMX寄存器到32位通用寄存�
function mmx_movd_r32(mm: TM64): LongWord; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
  {$ELSE}
    movq mm0, rdi
  {$ENDIF}
  movd eax, mm0
{$ELSE}
  movq mm0, qword ptr [mm]
  movd eax, mm0
{$ENDIF}
end;

// 功能：从32位通用寄存器到MMX寄存�
function mmx_movd_r32_to_mm(r32: LongWord): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movd mm0, ecx
  {$ELSE}
    movd mm0, edi
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movd mm0, r32
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movd mm0, r32
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能�?6位左�?MMX寄存器计�? - 这实际上就是我们已有的psllw
function mmx_psllw_mm(a, count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psllw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psllw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psllw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能�?6位右�?MMX寄存器计�? - 这实际上就是我们已有的psrlw
function mmx_psrlw_mm(a, count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psrlw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrlw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psrlw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能�?6位算术右�?MMX寄存器计�? - 这实际上就是我们已有的psraw
function mmx_psraw_mm(a, count: TM64): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    movq mm1, rdx
  {$ELSE}
    movq mm0, rdi
    movq mm1, rsi
  {$ENDIF}
  psraw mm0, mm1
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psraw mm0, mm1
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  movq mm1, qword ptr [count]
  psraw mm0, mm1
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能�?2位到16位无符号打包（模拟实现，MMX没有此指令）
function mmx_packusdw(a, b: TM64): TM64;
var
  i: Integer;
  temp: TM64;
begin
  // 这是一个模拟实现，因为原始MMX没有此指�?  for i := 0 to 1 do
  begin
    if a.mm_u32[i] > 65535 then
      temp.mm_u16[i] := 65535
    else
      temp.mm_u16[i] := a.mm_u32[i];

    if b.mm_u32[i] > 65535 then
      temp.mm_u16[i + 2] := 65535
    else
      temp.mm_u16[i + 2] := b.mm_u32[i];
  end;
  Result := temp;
end;

// 功能：从内存解包低位字节
function mmx_punpcklbw_mem(a: TM64; mem: Pointer): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    punpcklbw mm0, qword ptr [rdx]
  {$ELSE}
    movq mm0, rdi
    punpcklbw mm0, qword ptr [rsi]
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  punpcklbw mm0, qword ptr [mem]
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  punpcklbw mm0, qword ptr [mem]
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：从内存解包低位�
function mmx_punpcklwd_mem(a: TM64; mem: Pointer): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    punpcklwd mm0, qword ptr [rdx]
  {$ELSE}
    movq mm0, rdi
    punpcklwd mm0, qword ptr [rsi]
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  punpcklwd mm0, qword ptr [mem]
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  punpcklwd mm0, qword ptr [mem]
  movq qword ptr [Result], mm0
{$ENDIF}
end;

// 功能：从内存解包低位双字
function mmx_punpckldq_mem(a: TM64; mem: Pointer): TM64; {$IFDEF FPC}assembler;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq mm0, rcx
    punpckldq mm0, qword ptr [rdx]
  {$ELSE}
    movq mm0, rdi
    punpckldq mm0, qword ptr [rsi]
  {$ENDIF}
  movq rax, mm0
  movq qword ptr [Result], mm0
{$ELSE}
  movq mm0, qword ptr [a]
  punpckldq mm0, qword ptr [mem]
  movd eax, mm0
  psrlq mm0, 32
  movd edx, mm0
  movq mm0, qword ptr [a]
  punpckldq mm0, qword ptr [mem]
  movq qword ptr [Result], mm0
{$ENDIF}
end;

end.



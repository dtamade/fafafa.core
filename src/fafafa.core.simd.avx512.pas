unit fafafa.core.simd.avx512;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.cpuinfo.base;

// === AVX-512 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 AVX-512 instructions.
// This backend requires AVX-512F support (Intel Skylake-X 2017+, AMD Zen 4 2022+).
// Uses 512-bit ZMM registers, processing 64 bytes per iteration.

// Register the AVX-512 backend
procedure RegisterAVX512Backend;

// Pure logical predicate: returns True iff the CPU has all sub-features required by this backend.
// NOTE: This does NOT include OS enabling checks (XCR0), which are handled separately via HasAVX512.
function X86HasAVX512BackendRequiredFeatures(const X86: TX86Features): Boolean; inline;

// === AVX-512 门面函数声明 ===

// 内存操作函数
function MemEqual_AVX512(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_AVX512(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
function MemDiffRange_AVX512(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemCopy_AVX512(src, dst: Pointer; len: SizeUInt);
procedure MemSet_AVX512(dst: Pointer; len: SizeUInt; value: Byte);
procedure MemReverse_AVX512(p: Pointer; len: SizeUInt);

// 统计函数
function SumBytes_AVX512(p: Pointer; len: SizeUInt): UInt64;
procedure MinMaxBytes_AVX512(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
function CountByte_AVX512(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
function BitsetPopCount_AVX512(p: Pointer; len: SizeUInt): SizeUInt;

// 文本处理函数
function Utf8Validate_AVX512(p: Pointer; len: SizeUInt): Boolean;
function AsciiIEqual_AVX512(a, b: Pointer; len: SizeUInt): Boolean;
procedure ToLowerAscii_AVX512(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_AVX512(p: Pointer; len: SizeUInt);

// 搜索函数
function BytesIndexOf_AVX512(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.avx2; // Fallback for some operations

// === AVX-512 Memory Functions (512-bit) ===

// MemEqual_AVX512 - 使用 AVX-512 比较两个内存区域
// 一次处理 64 字节，使用 ZMM 寄存器
function MemEqual_AVX512(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
// RDI = a, RSI = b, RDX = len
asm
  xor eax, eax           // Default result = false
  test rdx, rdx
  jz @equal              // Empty = equal
  test rdi, rdi
  jz @check_both_nil
  test rsi, rsi
  jz @done
  cmp rdi, rsi
  je @equal              // Same pointer = equal

  xor rcx, rcx           // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rdx
  ja @loop32
  // 使用 AVX-512 加载和比较 64 字节
  vmovdqu64 zmm0, [rdi + rcx]
  vpcmpeqb k1, zmm0, [rsi + rcx]
  kortestq k1, k1
  jnc @not_equal_cleanup     // 如果有任何不等字节
  add rcx, 64
  jmp @loop64

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rdx
  ja @loop16
  vmovdqu ymm0, [rdi + rcx]
  vpcmpeqb ymm0, ymm0, [rsi + rcx]
  vpmovmskb eax, ymm0
  cmp eax, $FFFFFFFF
  jne @not_equal_cleanup
  add rcx, 32
  jmp @loop32

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rdx
  ja @remainder
  vmovdqu xmm0, [rdi + rcx]
  vpcmpeqb xmm0, xmm0, [rsi + rcx]
  vpmovmskb eax, xmm0
  cmp eax, $FFFF
  jne @not_equal_cleanup
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rdx
  jae @equal_cleanup
  movzx r8d, byte ptr [rdi + rcx]
  movzx r9d, byte ptr [rsi + rcx]
  cmp r8d, r9d
  jne @not_equal_cleanup
  inc rcx
  jmp @remainder

@check_both_nil:
  test rsi, rsi
  jz @equal
  jmp @done

@not_equal_cleanup:
  vzeroupper
  xor eax, eax
  ret

@equal_cleanup:
  vzeroupper
@equal:
  mov eax, 1
@done:
end;

// MemFindByte_AVX512 - 使用 AVX-512 查找字节
// 一次搜索 64 字节
function MemFindByte_AVX512(p: Pointer; len: SizeUInt; value: Byte): PtrInt; assembler; nostackframe;
// RDI = p, RSI = len, RDX = value
asm
  mov rax, -1            // Default result = -1 (not found)
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 64 bytes in zmm1
  vpbroadcastb zmm1, edx

  xor rcx, rcx           // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rsi
  ja @loop32
  vmovdqu64 zmm0, [rdi + rcx]
  vpcmpeqb k1, zmm0, zmm1
  kmovq r8, k1
  test r8, r8
  jnz @found64
  add rcx, 64
  jmp @loop64

@found64:
  bsf r8, r8
  lea rax, [rcx + r8]
  vzeroupper
  ret

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rsi
  ja @loop16
  vmovdqu ymm0, [rdi + rcx]
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb r8d, ymm0
  test r8d, r8d
  jnz @found32
  add rcx, 32
  jmp @loop32

@found32:
  bsf r8d, r8d
  lea rax, [rcx + r8]
  vzeroupper
  ret

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  vmovdqu xmm0, [rdi + rcx]
  vpcmpeqb xmm0, xmm0, xmm1
  vpmovmskb r8d, xmm0
  test r8d, r8d
  jnz @found16
  add rcx, 16
  jmp @loop16

@found16:
  bsf r8d, r8d
  lea rax, [rcx + r8]
  vzeroupper
  ret

@remainder:
  cmp rcx, rsi
  jae @cleanup
  movzx r8d, byte ptr [rdi + rcx]
  cmp r8d, edx
  je @found_remainder
  inc rcx
  jmp @remainder

@found_remainder:
  mov rax, rcx
  vzeroupper
  ret

@cleanup:
  vzeroupper
  mov rax, -1
@done:
end;

// SumBytes_AVX512 - 使用 AVX-512 求和字节数组
// 使用 vpsadbw 快速累加
function SumBytes_AVX512(p: Pointer; len: SizeUInt): UInt64; assembler; nostackframe;
// RDI = p, RSI = len
asm
  xor rax, rax           // sum = 0
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  vpxorq zmm2, zmm2, zmm2  // accumulator
  vpxorq zmm3, zmm3, zmm3  // zero for psadbw
  xor rcx, rcx             // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rsi
  ja @loop32
  vmovdqu64 zmm0, [rdi + rcx]
  vpsadbw zmm0, zmm0, zmm3
  vpaddq zmm2, zmm2, zmm0
  add rcx, 64
  jmp @loop64

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rsi
  ja @loop16
  vmovdqu ymm0, [rdi + rcx]
  vpsadbw ymm0, ymm0, ymm3
  vpaddq ymm2, ymm2, ymm0
  add rcx, 32
  jmp @loop32

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  vmovdqu xmm0, [rdi + rcx]
  vpsadbw xmm0, xmm0, xmm3
  vpaddq xmm2, xmm2, xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  // Reduce zmm2 to scalar
  // Extract 256-bit halves and add
  vextracti64x4 ymm0, zmm2, 1
  vpaddq ymm0, ymm0, ymm2
  // Extract 128-bit halves and add
  vextracti128 xmm1, ymm0, 1
  vpaddq xmm0, xmm0, xmm1
  // Extract 64-bit halves and add
  vpshufd xmm1, xmm0, $4E
  vpaddq xmm0, xmm0, xmm1
  vmovq rax, xmm0
  vzeroupper

  // Handle remaining bytes
@remainder_loop:
  cmp rcx, rsi
  jae @done
  movzx r8d, byte ptr [rdi + rcx]
  add rax, r8
  inc rcx
  jmp @remainder_loop

@done:
end;

// CountByte_AVX512 - 使用 AVX-512 计数指定字节
function CountByte_AVX512(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; assembler; nostackframe;
// RDI = p, RSI = len, RDX = value
asm
  xor rax, rax           // count = 0
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 64 bytes in zmm1
  vpbroadcastb zmm1, edx

  xor rcx, rcx           // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rsi
  ja @loop32
  vmovdqu64 zmm0, [rdi + rcx]
  vpcmpeqb k1, zmm0, zmm1
  kmovq r8, k1
  popcnt r8, r8
  add rax, r8
  add rcx, 64
  jmp @loop64

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rsi
  ja @loop16
  vmovdqu ymm0, [rdi + rcx]
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb r8d, ymm0
  popcnt r8d, r8d
  add rax, r8
  add rcx, 32
  jmp @loop32

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  vmovdqu xmm0, [rdi + rcx]
  vpcmpeqb xmm0, xmm0, xmm1
  vpmovmskb r8d, xmm0
  popcnt r8d, r8d
  add rax, r8
  add rcx, 16
  jmp @loop16

@remainder:
  vzeroupper
@remainder_loop:
  cmp rcx, rsi
  jae @done
  movzx r8d, byte ptr [rdi + rcx]
  cmp r8d, edx
  jne @skip
  inc rax
@skip:
  inc rcx
  jmp @remainder_loop

@done:
end;

// MinMaxBytes_AVX512 - 使用 AVX-512 查找最小和最大字节
procedure MinMaxBytes_AVX512(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte); assembler; nostackframe;
asm
  // RDI = p, RSI = len, RDX = &minVal, RCX = &maxVal
  push rbx
  mov r8, rdx       // r8 = &minVal
  mov r9, rcx       // r9 = &maxVal
  
  // 边界检查
  test rsi, rsi
  jz @empty
  
  // 初始化 min = 255, max = 0
  mov al, 255
  mov bl, 0
  
  // 如果长度 < 64，跳到 AVX2 或标量处理
  cmp rsi, 64
  jb @avx2_path
  
  // 初始化 ZMM 寄存器
  // zmm0 = min (全 255)
  // zmm1 = max (全 0)
  vpternlogd zmm0, zmm0, zmm0, $FF   // zmm0 = all 1s (255)
  vpxorq zmm1, zmm1, zmm1             // zmm1 = all 0s
  
  // 计算向量循环次数
  mov rcx, rsi
  shr rcx, 6            // rcx = len / 64
  
  // 向量主循环
@vector_loop:
  vmovdqu64 zmm2, [rdi]   // 加载 64 字节
  vpminub zmm0, zmm0, zmm2    // min = min(min, data)
  vpmaxub zmm1, zmm1, zmm2    // max = max(max, data)
  add rdi, 64
  dec rcx
  jnz @vector_loop
  
  // 水平归约 512 位到 256 位
  vextracti64x4 ymm2, zmm0, 1
  vextracti64x4 ymm3, zmm1, 1
  vpminub ymm0, ymm0, ymm2
  vpmaxub ymm1, ymm1, ymm3
  
  // 256 位归约到 128 位
  vextracti128 xmm2, ymm0, 1
  vextracti128 xmm3, ymm1, 1
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  // 128 位归约到 64 位
  vpsrldq xmm2, xmm0, 8
  vpsrldq xmm3, xmm1, 8
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  // 64 位归约到 32 位
  vpsrldq xmm2, xmm0, 4
  vpsrldq xmm3, xmm1, 4
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  // 32 位归约到 16 位
  vpsrldq xmm2, xmm0, 2
  vpsrldq xmm3, xmm1, 2
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  // 16 位归约到 8 位
  vpsrldq xmm2, xmm0, 1
  vpsrldq xmm3, xmm1, 1
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  // 提取结果
  vpextrb eax, xmm0, 0          // al = min
  vpextrb ebx, xmm1, 0          // bl = max
  
  // 计算剩余字节
  and rsi, 63           // len % 64
  jz @store_result
  jmp @scalar_loop
  
@avx2_path:
  // 如果长度 < 32，跳到标量处理
  cmp rsi, 32
  jb @scalar_loop
  
  // AVX2 路径
  vpcmpeqb ymm0, ymm0, ymm0   // ymm0 = all 1s (255)
  vpxor ymm1, ymm1, ymm1       // ymm1 = all 0s
  
  mov rcx, rsi
  shr rcx, 5            // rcx = len / 32
  
@avx2_loop:
  vmovdqu ymm2, [rdi]
  vpminub ymm0, ymm0, ymm2
  vpmaxub ymm1, ymm1, ymm2
  add rdi, 32
  dec rcx
  jnz @avx2_loop
  
  // 256 位归约
  vextracti128 xmm2, ymm0, 1
  vextracti128 xmm3, ymm1, 1
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  vpsrldq xmm2, xmm0, 8
  vpsrldq xmm3, xmm1, 8
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  vpsrldq xmm2, xmm0, 4
  vpsrldq xmm3, xmm1, 4
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  vpsrldq xmm2, xmm0, 2
  vpsrldq xmm3, xmm1, 2
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  vpsrldq xmm2, xmm0, 1
  vpsrldq xmm3, xmm1, 1
  vpminub xmm0, xmm0, xmm2
  vpmaxub xmm1, xmm1, xmm3
  
  vpextrb eax, xmm0, 0
  vpextrb ebx, xmm1, 0
  
  and rsi, 31
  jz @store_result
  
  // 处理剩余字节
@scalar_loop:
  test rsi, rsi
  jz @store_result
  movzx ecx, byte ptr [rdi]
  cmp cl, al
  cmovb eax, ecx       // if (data < min) min = data
  cmp cl, bl
  cmova ebx, ecx       // if (data > max) max = data
  inc rdi
  dec rsi
  jnz @scalar_loop
  
@store_result:
  mov [r8], al         // *minVal = al
  mov [r9], bl         // *maxVal = bl
  vzeroupper
  pop rbx
  jmp @return
  
@empty:
  mov byte ptr [r8], 0
  mov byte ptr [r9], 0
  pop rbx
  
@return:
end;

// BitsetPopCount_AVX512 - 使用 POPCNT 指令计算位集中置 1 的位数
function BitsetPopCount_AVX512(p: Pointer; len: SizeUInt): SizeUInt; assembler; nostackframe;
asm
  // 参数: RDI = p, RSI = len
  // 返回: RAX = 置 1 的位数
  
  xor rax, rax          // result = 0
  
  // 边界检查
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done
  
  // 主循环：一次处理 8 字节
  mov rcx, rsi
  shr rcx, 3            // rcx = len / 8
  jz @remainder
  
@main_loop:
  popcnt rdx, qword ptr [rdi]
  add rax, rdx
  add rdi, 8
  dec rcx
  jnz @main_loop
  
@remainder:
  // 处理剩余字节 (0-7)
  and rsi, 7            // len % 8
  jz @done
  
@scalar_loop:
  movzx edx, byte ptr [rdi]
  popcnt edx, edx
  add rax, rdx
  inc rdi
  dec rsi
  jnz @scalar_loop
  
@done:
end;

// === 以下函数使用 AVX2 实现或回退到 Scalar ===

function Utf8Validate_AVX512(p: Pointer; len: SizeUInt): Boolean;
begin
  // UTF-8 验证逻辑复杂，暂时使用 AVX2 实现
  Result := Utf8Validate_AVX2(p, len);
end;

procedure MemReverse_AVX512(p: Pointer; len: SizeUInt);
begin
  // 内存反转使用 AVX2 实现
  MemReverse_AVX2(p, len);
end;

// AsciiIEqual_AVX512 - 使用 AVX-512 进行大小写不敏感的 ASCII 比较
// 算法：将两个字符串都转换为小写后比较
function AsciiIEqual_AVX512(a, b: Pointer; len: SizeUInt): Boolean; assembler; nostackframe;
// RDI = a, RSI = b, RDX = len
asm
  xor eax, eax           // Default result = false
  test rdx, rdx
  jz @equal              // Empty = equal
  test rdi, rdi
  jz @check_both_nil
  test rsi, rsi
  jz @done
  cmp rdi, rsi
  je @equal              // Same pointer = equal

  // 广播常量
  mov r8d, 'A'           // 65
  vpbroadcastb zmm4, r8d   // zmm4 = all 'A'
  mov r8d, 'Z'           // 90
  vpbroadcastb zmm5, r8d   // zmm5 = all 'Z'
  mov r8d, 32
  vpbroadcastb zmm6, r8d   // zmm6 = all 32 (大小写差)

  xor rcx, rcx           // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rdx
  ja @loop32
  
  // 加载两个字符串
  vmovdqu64 zmm0, [rdi + rcx]  // a
  vmovdqu64 zmm1, [rsi + rcx]  // b
  
  // 将 a 转换为小写
  vpcmpub k1, zmm0, zmm4, 5    // k1 = (a >= 'A')
  vpcmpub k2, zmm0, zmm5, 2    // k2 = (a <= 'Z')
  kandq k1, k1, k2             // k1 = ('A' <= a <= 'Z')
  vpaddb zmm0 {k1}, zmm0, zmm6 // a = tolower(a)
  
  // 将 b 转换为小写
  vpcmpub k1, zmm1, zmm4, 5    // k1 = (b >= 'A')
  vpcmpub k2, zmm1, zmm5, 2    // k2 = (b <= 'Z')
  kandq k1, k1, k2             // k1 = ('A' <= b <= 'Z')
  vpaddb zmm1 {k1}, zmm1, zmm6 // b = tolower(b)
  
  // 比较
  vpcmpeqb k1, zmm0, zmm1
  kortestq k1, k1
  jnc @not_equal_cleanup       // 如果有任何不等字节
  
  add rcx, 64
  jmp @loop64

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rdx
  ja @loop16
  
  vmovdqu ymm0, [rdi + rcx]
  vmovdqu ymm1, [rsi + rcx]
  
  // 将 a 转换为小写 (AVX2 方式)
  mov r8d, 'A' - 1
  vpbroadcastb ymm7, r8d
  vpcmpgtb ymm2, ymm0, ymm7    // ymm2 = (a >= 'A')
  mov r8d, 'Z' + 1
  vpbroadcastb ymm7, r8d
  vpcmpgtb ymm7, ymm7, ymm0    // ymm7 = (a <= 'Z')
  vpand ymm2, ymm2, ymm7       // ymm2 = mask for a
  vpand ymm2, ymm2, ymm6       // ymm2 = 32 if in range, else 0
  vpaddb ymm0, ymm0, ymm2      // a = tolower(a)
  
  // 将 b 转换为小写
  mov r8d, 'A' - 1
  vpbroadcastb ymm7, r8d
  vpcmpgtb ymm2, ymm1, ymm7
  mov r8d, 'Z' + 1
  vpbroadcastb ymm7, r8d
  vpcmpgtb ymm7, ymm7, ymm1
  vpand ymm2, ymm2, ymm7
  vpand ymm2, ymm2, ymm6
  vpaddb ymm1, ymm1, ymm2
  
  // 比较
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb r8d, ymm0
  cmp r8d, $FFFFFFFF
  jne @not_equal_cleanup
  
  add rcx, 32
  jmp @loop32

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rdx
  ja @remainder
  
  vmovdqu xmm0, [rdi + rcx]
  vmovdqu xmm1, [rsi + rcx]
  
  // 将 a 转换为小写
  mov r8d, 'A' - 1
  vpbroadcastb xmm7, r8d
  vpcmpgtb xmm2, xmm0, xmm7
  mov r8d, 'Z' + 1
  vpbroadcastb xmm7, r8d
  vpcmpgtb xmm7, xmm7, xmm0
  vpand xmm2, xmm2, xmm7
  vpand xmm2, xmm2, xmm6
  vpaddb xmm0, xmm0, xmm2
  
  // 将 b 转换为小写
  mov r8d, 'A' - 1
  vpbroadcastb xmm7, r8d
  vpcmpgtb xmm2, xmm1, xmm7
  mov r8d, 'Z' + 1
  vpbroadcastb xmm7, r8d
  vpcmpgtb xmm7, xmm7, xmm1
  vpand xmm2, xmm2, xmm7
  vpand xmm2, xmm2, xmm6
  vpaddb xmm1, xmm1, xmm2
  
  // 比较
  vpcmpeqb xmm0, xmm0, xmm1
  vpmovmskb r8d, xmm0
  cmp r8d, $FFFF
  jne @not_equal_cleanup
  
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rdx
  jae @equal_cleanup
  
  movzx r8d, byte ptr [rdi + rcx]
  movzx r9d, byte ptr [rsi + rcx]
  
  // tolower(a)
  cmp r8d, 'A'
  jb @skip_lower_a
  cmp r8d, 'Z'
  ja @skip_lower_a
  add r8d, 32
@skip_lower_a:
  
  // tolower(b)
  cmp r9d, 'A'
  jb @skip_lower_b
  cmp r9d, 'Z'
  ja @skip_lower_b
  add r9d, 32
@skip_lower_b:
  
  cmp r8d, r9d
  jne @not_equal_cleanup
  inc rcx
  jmp @remainder

@check_both_nil:
  test rsi, rsi
  jz @equal
  jmp @done

@not_equal_cleanup:
  vzeroupper
  xor eax, eax
  ret

@equal_cleanup:
  vzeroupper
@equal:
  mov eax, 1
@done:
end;

// MemCopy_AVX512 - 使用 AVX-512 复制内存
// 一次复制 64 字节以获得最大吸吐
// 注意：应对重叠情况需要处理
procedure MemCopy_AVX512(src, dst: Pointer; len: SizeUInt); assembler; nostackframe;
// RDI = src, RSI = dst, RDX = len
asm
  test rdx, rdx
  jz @done
  test rdi, rdi
  jz @done
  test rsi, rsi
  jz @done
  cmp rdi, rsi
  je @done              // src == dst, nothing to do

  // 检查重叠：如果 dst > src && dst < src + len，需要从后向前复制
  mov rcx, rdi
  add rcx, rdx          // rcx = src + len
  cmp rsi, rdi
  jbe @forward_copy     // dst <= src, forward copy
  cmp rsi, rcx
  jae @forward_copy     // dst >= src + len, forward copy
  
  // 重叠情况，从后向前复制
  lea rdi, [rdi + rdx]  // src = src + len
  lea rsi, [rsi + rdx]  // dst = dst + len
  mov rcx, rdx          // rcx = remaining len

@backward_loop64:
  cmp rcx, 64
  jb @backward_loop32
  sub rdi, 64
  sub rsi, 64
  vmovdqu64 zmm0, [rdi]
  vmovdqu64 [rsi], zmm0
  sub rcx, 64
  jmp @backward_loop64

@backward_loop32:
  cmp rcx, 32
  jb @backward_loop16
  sub rdi, 32
  sub rsi, 32
  vmovdqu ymm0, [rdi]
  vmovdqu [rsi], ymm0
  sub rcx, 32
  jmp @backward_loop32

@backward_loop16:
  cmp rcx, 16
  jb @backward_loop8
  sub rdi, 16
  sub rsi, 16
  vmovdqu xmm0, [rdi]
  vmovdqu [rsi], xmm0
  sub rcx, 16
  jmp @backward_loop16

@backward_loop8:
  test rcx, rcx
  jz @cleanup
  dec rdi
  dec rsi
  movzx eax, byte ptr [rdi]
  mov [rsi], al
  dec rcx
  jmp @backward_loop8

@forward_copy:
  xor rcx, rcx          // i = 0

@forward_loop64:
  lea r8, [rcx + 64]
  cmp r8, rdx
  ja @forward_loop32
  vmovdqu64 zmm0, [rdi + rcx]
  vmovdqu64 [rsi + rcx], zmm0
  add rcx, 64
  jmp @forward_loop64

@forward_loop32:
  lea r8, [rcx + 32]
  cmp r8, rdx
  ja @forward_loop16
  vmovdqu ymm0, [rdi + rcx]
  vmovdqu [rsi + rcx], ymm0
  add rcx, 32
  jmp @forward_loop32

@forward_loop16:
  lea r8, [rcx + 16]
  cmp r8, rdx
  ja @forward_remainder
  vmovdqu xmm0, [rdi + rcx]
  vmovdqu [rsi + rcx], xmm0
  add rcx, 16
  jmp @forward_loop16

@forward_remainder:
  cmp rcx, rdx
  jae @cleanup
  movzx eax, byte ptr [rdi + rcx]
  mov [rsi + rcx], al
  inc rcx
  jmp @forward_remainder

@cleanup:
  vzeroupper
@done:
end;

// MemSet_AVX512 - 使用 AVX-512 填充内存
// 一次填充 64 字节
procedure MemSet_AVX512(dst: Pointer; len: SizeUInt; value: Byte); assembler; nostackframe;
// RDI = dst, RSI = len, RDX = value
asm
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // 广播 value 到 zmm0 的所有 64 字节
  vpbroadcastb zmm0, edx

  xor rcx, rcx          // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rsi
  ja @loop32
  vmovdqu64 [rdi + rcx], zmm0
  add rcx, 64
  jmp @loop64

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rsi
  ja @loop16
  vmovdqu [rdi + rcx], ymm0
  add rcx, 32
  jmp @loop32

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  vmovdqu [rdi + rcx], xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @cleanup
  mov [rdi + rcx], dl
  inc rcx
  jmp @remainder

@cleanup:
  vzeroupper
@done:
end;

// ToLowerAscii_AVX512 - 使用 AVX-512 将 ASCII 转换为小写
// 算法：如果字符在 'A'-'Z' 范围，加 32
procedure ToLowerAscii_AVX512(p: Pointer; len: SizeUInt); assembler; nostackframe;
// RDI = p, RSI = len
asm
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // 广播常量
  mov eax, 'A'          // 65
  vpbroadcastb zmm1, eax  // zmm1 = all 'A'
  mov eax, 'Z'          // 90
  vpbroadcastb zmm2, eax  // zmm2 = all 'Z'
  mov eax, 32
  vpbroadcastb zmm3, eax  // zmm3 = all 32 (大小写差)

  xor rcx, rcx          // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rsi
  ja @loop32
  
  vmovdqu64 zmm0, [rdi + rcx]
  // 检查 >= 'A'
  vpcmpub k1, zmm0, zmm1, 5  // k1 = (zmm0 >= zmm1) = (ch >= 'A')
  // 检查 <= 'Z'
  vpcmpub k2, zmm0, zmm2, 2  // k2 = (zmm0 <= zmm2) = (ch <= 'Z')
  // 取交集
  kandq k1, k1, k2           // k1 = ('A' <= ch <= 'Z')
  // 条件加法：如果在范围内，加 32
  vpaddb zmm0 {k1}, zmm0, zmm3
  vmovdqu64 [rdi + rcx], zmm0
  
  add rcx, 64
  jmp @loop64

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rsi
  ja @loop16
  
  vmovdqu ymm0, [rdi + rcx]
  // AVX2 方式：使用比较和混合
  vpcmpgtb ymm4, ymm0, ymm1  // ymm4 = (ch > 'A'-1)
  mov eax, 'A' - 1
  vpbroadcastb ymm5, eax
  vpcmpgtb ymm4, ymm0, ymm5  // ymm4 = (ch > 'A'-1) = (ch >= 'A')
  mov eax, 'Z' + 1
  vpbroadcastb ymm5, eax
  vpcmpgtb ymm5, ymm5, ymm0  // ymm5 = ('Z'+1 > ch) = (ch <= 'Z')
  vpand ymm4, ymm4, ymm5     // ymm4 = ('A' <= ch <= 'Z')
  vpand ymm4, ymm4, ymm3     // ymm4 = 32 if in range, else 0
  vpaddb ymm0, ymm0, ymm4
  vmovdqu [rdi + rcx], ymm0
  
  add rcx, 32
  jmp @loop32

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  
  vmovdqu xmm0, [rdi + rcx]
  mov eax, 'A' - 1
  vpbroadcastb xmm5, eax
  vpcmpgtb xmm4, xmm0, xmm5  // xmm4 = (ch >= 'A')
  mov eax, 'Z' + 1
  vpbroadcastb xmm5, eax
  vpcmpgtb xmm5, xmm5, xmm0  // xmm5 = (ch <= 'Z')
  vpand xmm4, xmm4, xmm5     // xmm4 = ('A' <= ch <= 'Z')
  vpand xmm4, xmm4, xmm3     // xmm4 = 32 if in range, else 0
  vpaddb xmm0, xmm0, xmm4
  vmovdqu [rdi + rcx], xmm0
  
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @cleanup
  movzx eax, byte ptr [rdi + rcx]
  cmp al, 'A'
  jb @next
  cmp al, 'Z'
  ja @next
  add al, 32
  mov [rdi + rcx], al
@next:
  inc rcx
  jmp @remainder

@cleanup:
  vzeroupper
@done:
end;

// ToUpperAscii_AVX512 - 使用 AVX-512 将 ASCII 转换为大写
// 算法：如果字符在 'a'-'z' 范围，减 32
procedure ToUpperAscii_AVX512(p: Pointer; len: SizeUInt); assembler; nostackframe;
// RDI = p, RSI = len
asm
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // 广播常量
  mov eax, 'a'          // 97
  vpbroadcastb zmm1, eax  // zmm1 = all 'a'
  mov eax, 'z'          // 122
  vpbroadcastb zmm2, eax  // zmm2 = all 'z'
  mov eax, 32
  vpbroadcastb zmm3, eax  // zmm3 = all 32 (大小写差)

  xor rcx, rcx          // i = 0

@loop64:
  lea r8, [rcx + 64]
  cmp r8, rsi
  ja @loop32
  
  vmovdqu64 zmm0, [rdi + rcx]
  // 检查 >= 'a'
  vpcmpub k1, zmm0, zmm1, 5  // k1 = (zmm0 >= zmm1) = (ch >= 'a')
  // 检查 <= 'z'
  vpcmpub k2, zmm0, zmm2, 2  // k2 = (zmm0 <= zmm2) = (ch <= 'z')
  // 取交集
  kandq k1, k1, k2           // k1 = ('a' <= ch <= 'z')
  // 条件减法：如果在范围内，减 32
  vpsubb zmm0 {k1}, zmm0, zmm3
  vmovdqu64 [rdi + rcx], zmm0
  
  add rcx, 64
  jmp @loop64

@loop32:
  lea r8, [rcx + 32]
  cmp r8, rsi
  ja @loop16
  
  vmovdqu ymm0, [rdi + rcx]
  // AVX2 方式
  mov eax, 'a' - 1
  vpbroadcastb ymm5, eax
  vpcmpgtb ymm4, ymm0, ymm5  // ymm4 = (ch >= 'a')
  mov eax, 'z' + 1
  vpbroadcastb ymm5, eax
  vpcmpgtb ymm5, ymm5, ymm0  // ymm5 = (ch <= 'z')
  vpand ymm4, ymm4, ymm5     // ymm4 = ('a' <= ch <= 'z')
  vpand ymm4, ymm4, ymm3     // ymm4 = 32 if in range, else 0
  vpsubb ymm0, ymm0, ymm4
  vmovdqu [rdi + rcx], ymm0
  
  add rcx, 32
  jmp @loop32

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  
  vmovdqu xmm0, [rdi + rcx]
  mov eax, 'a' - 1
  vpbroadcastb xmm5, eax
  vpcmpgtb xmm4, xmm0, xmm5  // xmm4 = (ch >= 'a')
  mov eax, 'z' + 1
  vpbroadcastb xmm5, eax
  vpcmpgtb xmm5, xmm5, xmm0  // xmm5 = (ch <= 'z')
  vpand xmm4, xmm4, xmm5     // xmm4 = ('a' <= ch <= 'z')
  vpand xmm4, xmm4, xmm3     // xmm4 = 32 if in range, else 0
  vpsubb xmm0, xmm0, xmm4
  vmovdqu [rdi + rcx], xmm0
  
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @cleanup
  movzx eax, byte ptr [rdi + rcx]
  cmp al, 'a'
  jb @next
  cmp al, 'z'
  ja @next
  sub al, 32
  mov [rdi + rcx], al
@next:
  inc rcx
  jmp @remainder

@cleanup:
  vzeroupper
@done:
end;

// === AVX-512 Vector Type Operations ===

// === F32x16 Arithmetic Operations (512-bit) ===

function AVX512AddF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vaddps  zmm0, zmm0, [rcx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SubF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vsubps  zmm0, zmm0, [rcx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MulF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vmulps  zmm0, zmm0, [rcx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512DivF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vdivps  zmm0, zmm0, [rcx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

// === F64x8 Arithmetic Operations (512-bit) ===

function AVX512AddF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vaddpd  zmm0, zmm0, [rcx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SubF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vsubpd  zmm0, zmm0, [rcx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MulF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vmulpd  zmm0, zmm0, [rcx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512DivF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vdivpd  zmm0, zmm0, [rcx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

// === 512-bit Load/Store/Splat/Zero/Select ===

// F32x16
function AVX512LoadF32x16(p: PSingle): TVecF32x16;
var
  pp, pr: Pointer;
begin
  pr := @Result;
  pp := p;

  asm
    mov     rax, pr
    mov     rdx, pp
    vmovups zmm0, [rdx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

procedure AVX512StoreF32x16(p: PSingle; const a: TVecF32x16);
var
  pp, pa: Pointer;
begin
  pp := p;
  pa := @a;

  asm
    mov     rax, pp
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SplatF32x16(value: Single): TVecF32x16;
var
  pr: Pointer;
  v: Single;
begin
  pr := @Result;
  v := value;

  asm
    mov     rax, pr
    vbroadcastss zmm0, v
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512ZeroF32x16: TVecF32x16;
var
  pr: Pointer;
begin
  pr := @Result;

  asm
    mov     rax, pr
    vxorps  zmm0, zmm0, zmm0
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
  m: Word;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  m := Word(mask);

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    kmovw   k1, m
    vmovups zmm0, [rcx]
    vmovups zmm0 {k1}, [rdx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

// F64x8
function AVX512LoadF64x8(p: PDouble): TVecF64x8;
var
  pp, pr: Pointer;
begin
  pr := @Result;
  pp := p;

  asm
    mov     rax, pr
    mov     rdx, pp
    vmovupd zmm0, [rdx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

procedure AVX512StoreF64x8(p: PDouble; const a: TVecF64x8);
var
  pp, pa: Pointer;
begin
  pp := p;
  pa := @a;

  asm
    mov     rax, pp
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SplatF64x8(value: Double): TVecF64x8;
var
  pr: Pointer;
  v: Double;
begin
  pr := @Result;
  v := value;

  asm
    mov     rax, pr
    vbroadcastsd zmm0, v
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512ZeroF64x8: TVecF64x8;
var
  pr: Pointer;
begin
  pr := @Result;

  asm
    mov     rax, pr
    vxorpd  zmm0, zmm0, zmm0
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
  m: Byte;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  m := Byte(mask);

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    kmovb   k1, m
    vmovupd zmm0, [rcx]
    vmovupd zmm0 {k1}, [rdx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

// === I32x16 Arithmetic Operations (512-bit) ===

function AVX512AddI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpaddd  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SubI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpsubd  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MulI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpmulld zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

// === I32x16 Bitwise Operations ===

function AVX512AndI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpandd  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512OrI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpord   zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512XorI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpxord  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512NotI32x16(const a: TVecI32x16): TVecI32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu64 zmm0, [rdx]
    // vpternlogd zmm0, zmm0, zmm0, 0x0F = NOT (imm8=0x0F means ~A)
    // Actually imm8=0xFF means all 1s, then XOR gives NOT
    // Better: vpternlogd with imm=0x55 gives NOT A
    vpternlogd zmm0, zmm0, zmm0, $55   // NOT A = ~A
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512AndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpandnd zmm0, zmm0, [rcx]   // (NOT a) AND b
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

// === I32x16 Shift Operations ===

function AVX512ShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  if (count < 0) or (count >= 32) then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu64 zmm0, [rdx]
    vmovd   xmm1, count
    vpslld  zmm0, zmm0, xmm1
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512ShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  if (count < 0) or (count >= 32) then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu64 zmm0, [rdx]
    vmovd   xmm1, count
    vpsrld  zmm0, zmm0, xmm1    // Logical right shift
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512ShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var
  pa, pr: Pointer;
  i: Integer;
begin
  pr := @Result;
  pa := @a;

  if count < 0 then
  begin
    Result := a;
    Exit;
  end;

  if count >= 32 then
  begin
    // Arithmetic shift >= 32: result is all 0s or all 1s depending on sign
    for i := 0 to 15 do
      if a.i[i] < 0 then
        Result.i[i] := -1
      else
        Result.i[i] := 0;
    Exit;
  end;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu64 zmm0, [rdx]
    vmovd   xmm1, count
    vpsrad  zmm0, zmm0, xmm1    // Arithmetic right shift
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

// === I32x16 Comparison Operations ===

function AVX512CmpEqI32x16(const a, b: TVecI32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpeqd k1, zmm0, [rcx]
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpLtI32x16(const a, b: TVecI32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // a < b is equivalent to b > a
  asm
    mov     rdx, pb
    mov     rcx, pa
    vmovdqu64 zmm0, [rdx]
    vpcmpgtd k1, zmm0, [rcx]    // b > a
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpGtI32x16(const a, b: TVecI32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpgtd k1, zmm0, [rcx]
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

// ✅ P0-1: 补充缺失的比较函数
function AVX512CmpLeI32x16(const a, b: TVecI32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vpcmpd with imm8=2 means LE (less than or equal)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpd  k1, zmm0, [rcx], 2    // imm8=2: LE
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpGeI32x16(const a, b: TVecI32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vpcmpd with imm8=5 means NLT (not less than) = GE
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpd  k1, zmm0, [rcx], 5    // imm8=5: GE (NLT)
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpNeI32x16(const a, b: TVecI32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vpcmpd with imm8=4 means NE (not equal)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpd  k1, zmm0, [rcx], 4    // imm8=4: NE
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

// === I32x16 Min/Max Operations ===

function AVX512MinI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpminsd zmm0, zmm0, [rcx]   // Signed min
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MaxI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpmaxsd zmm0, zmm0, [rcx]   // Signed max
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

// === I32x16 Load/Store/Splat/Zero/Select Operations ===

function AVX512LoadI32x16(p: PInt32): TVecI32x16;
var
  pp, pr: Pointer;
begin
  pr := @Result;
  pp := p;

  asm
    mov     rax, pr
    mov     rdx, pp
    vmovdqu64 zmm0, [rdx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

procedure AVX512StoreI32x16(p: PInt32; const a: TVecI32x16);
var
  pp, pa: Pointer;
begin
  pp := p;
  pa := @a;

  asm
    mov     rax, pp
    mov     rdx, pa
    vmovdqu64 zmm0, [rdx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SplatI32x16(value: Int32): TVecI32x16;
var
  pr: Pointer;
begin
  pr := @Result;

  asm
    mov     rax, pr
    vpbroadcastd zmm0, value
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512ZeroI32x16: TVecI32x16;
var
  pr: Pointer;
begin
  pr := @Result;

  asm
    mov     rax, pr
    vpxord  zmm0, zmm0, zmm0
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SelectI32x16(const mask: TMask16; const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
  m: Word;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  m := Word(mask);

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    kmovw   k1, m
    vmovdqu64 zmm0, [rcx]
    vmovdqu64 zmm0 {k1}, [rdx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

// === I64x8 Arithmetic Operations (512-bit) ===

function AVX512AddI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpaddq  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SubI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpsubq  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

// === I64x8 Bitwise Operations ===

function AVX512AndI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpandq  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512OrI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vporq   zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512XorI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpxorq  zmm0, zmm0, [rcx]
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

function AVX512NotI64x8(const a: TVecI64x8): TVecI64x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu64 zmm0, [rdx]
    vpternlogq zmm0, zmm0, zmm0, $55   // NOT A
    vmovdqu64 [rax], zmm0
    vzeroupper
  end;
end;

// === I64x8 Comparison Operations ===

function AVX512CmpEqI64x8(const a, b: TVecI64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpeqq k1, zmm0, [rcx]
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpLtI64x8(const a, b: TVecI64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  // a < b is equivalent to b > a
  asm
    mov     rdx, pb
    mov     rcx, pa
    vmovdqu64 zmm0, [rdx]
    vpcmpgtq k1, zmm0, [rcx]    // b > a
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpGtI64x8(const a, b: TVecI64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpgtq k1, zmm0, [rcx]
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpLeI64x8(const a, b: TVecI64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  // vpcmpq with imm8=2 means LE
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpq  k1, zmm0, [rcx], 2    // imm8=2: LE
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpGeI64x8(const a, b: TVecI64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  // vpcmpq with imm8=5 means GE (NLT)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpq  k1, zmm0, [rcx], 5    // imm8=5: GE
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpNeI64x8(const a, b: TVecI64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  // vpcmpq with imm8=4 means NE
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu64 zmm0, [rdx]
    vpcmpq  k1, zmm0, [rcx], 4    // imm8=4: NE
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

// === F32x16 Comparison Operations ===

function AVX512CmpEqF32x16(const a, b: TVecF32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vcmpps with imm8=0 means EQ
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vcmpps  k1, zmm0, [rcx], 0    // imm8=0: EQ
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpLtF32x16(const a, b: TVecF32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vcmpps with imm8=1 means LT
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vcmpps  k1, zmm0, [rcx], 1    // imm8=1: LT
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpLeF32x16(const a, b: TVecF32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vcmpps with imm8=2 means LE
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vcmpps  k1, zmm0, [rcx], 2    // imm8=2: LE
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpGtF32x16(const a, b: TVecF32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vcmpps with imm8=14 means GT (NLE)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vcmpps  k1, zmm0, [rcx], 14   // imm8=14: GT (NLE)
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpGeF32x16(const a, b: TVecF32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vcmpps with imm8=13 means GE (NLT)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vcmpps  k1, zmm0, [rcx], 13   // imm8=13: GE (NLT)
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

function AVX512CmpNeF32x16(const a, b: TVecF32x16): TMask16;
var
  pa, pb: Pointer;
  mask: Word;
begin
  pa := @a;
  pb := @b;

  // vcmpps with imm8=4 means NE (unordered)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vcmpps  k1, zmm0, [rcx], 4    // imm8=4: NEQ
    kmovw   mask, k1
    vzeroupper
  end;

  Result := TMask16(mask);
end;

// === F64x8 Comparison Operations ===

function AVX512CmpEqF64x8(const a, b: TVecF64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vcmppd  k1, zmm0, [rcx], 0    // imm8=0: EQ
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpLtF64x8(const a, b: TVecF64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vcmppd  k1, zmm0, [rcx], 1    // imm8=1: LT
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpLeF64x8(const a, b: TVecF64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vcmppd  k1, zmm0, [rcx], 2    // imm8=2: LE
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpGtF64x8(const a, b: TVecF64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vcmppd  k1, zmm0, [rcx], 14   // imm8=14: GT (NLE)
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpGeF64x8(const a, b: TVecF64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vcmppd  k1, zmm0, [rcx], 13   // imm8=13: GE (NLT)
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX512CmpNeF64x8(const a, b: TVecF64x8): TMask8;
var
  pa, pb: Pointer;
  mask: Byte;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vcmppd  k1, zmm0, [rcx], 4    // imm8=4: NEQ
    kmovb   mask, k1
    vzeroupper
  end;

  Result := TMask8(mask);
end;

// === F32x16 Math Functions ===

function AVX512AbsF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  // Abs by clearing sign bit: AND with 0x7FFFFFFF
  asm
    mov     rax, pr
    mov     rdx, pa
    mov     ecx, $7FFFFFFF
    vpbroadcastd zmm1, ecx
    vmovups zmm0, [rdx]
    vpandd  zmm0, zmm0, zmm1
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SqrtF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vsqrtps zmm0, zmm0
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MinF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vminps  zmm0, zmm0, [rcx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MaxF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovups zmm0, [rdx]
    vmaxps  zmm0, zmm0, [rcx]
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512ClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
var
  pa, pmin, pmax, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pmin := @minVal;
  pmax := @maxVal;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pmin
    mov     r8, pmax
    vmovups zmm0, [rdx]
    vmaxps  zmm0, zmm0, [rcx]    // max(a, minVal)
    vminps  zmm0, zmm0, [r8]     // min(result, maxVal)
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

// === F64x8 Math Functions ===

function AVX512AbsF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  // Abs by clearing sign bit: AND with 0x7FFFFFFFFFFFFFFF
  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, $7FFFFFFFFFFFFFFF
    vpbroadcastq zmm1, rcx
    vmovupd zmm0, [rdx]
    vpandq  zmm0, zmm0, zmm1
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512SqrtF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vsqrtpd zmm0, zmm0
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MinF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vminpd  zmm0, zmm0, [rcx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512MaxF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovupd zmm0, [rdx]
    vmaxpd  zmm0, zmm0, [rcx]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512ClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
var
  pa, pmin, pmax, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pmin := @minVal;
  pmax := @maxVal;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pmin
    mov     r8, pmax
    vmovupd zmm0, [rdx]
    vmaxpd  zmm0, zmm0, [rcx]
    vminpd  zmm0, zmm0, [r8]
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

// === F32x16 FMA and Rounding Operations ===

function AVX512FmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
var
  pa, pb, pc, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  pc := @c;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    mov     r8, pc
    vmovups zmm0, [rdx]
    vmovups zmm1, [rcx]
    vmovups zmm2, [r8]
    vfmadd213ps zmm0, zmm1, zmm2   // a*b+c
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512FloorF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vrndscaleps zmm0, zmm0, 1    // imm8=1: floor (round toward -inf)
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512CeilF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vrndscaleps zmm0, zmm0, 2    // imm8=2: ceil (round toward +inf)
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512RoundF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vrndscaleps zmm0, zmm0, 0    // imm8=0: round to nearest even
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

function AVX512TruncF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vrndscaleps zmm0, zmm0, 3    // imm8=3: truncate (round toward zero)
    vmovups [rax], zmm0
    vzeroupper
  end;
end;

// === F64x8 FMA and Rounding Operations ===

function AVX512FmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
var
  pa, pb, pc, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  pc := @c;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    mov     r8, pc
    vmovupd zmm0, [rdx]
    vmovupd zmm1, [rcx]
    vmovupd zmm2, [r8]
    vfmadd213pd zmm0, zmm1, zmm2
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512FloorF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vrndscalepd zmm0, zmm0, 1
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512CeilF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vrndscalepd zmm0, zmm0, 2
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512RoundF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vrndscalepd zmm0, zmm0, 0
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

function AVX512TruncF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vrndscalepd zmm0, zmm0, 3
    vmovupd [rax], zmm0
    vzeroupper
  end;
end;

// === F32x16 Reduction Operations ===

function AVX512ReduceAddF32x16(const a: TVecF32x16): Single;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovups zmm0, [rdx]
    // Extract upper 256 bits and add to lower
    vextractf64x4 ymm1, zmm0, 1
    vaddps  ymm0, ymm0, ymm1
    // Extract upper 128 bits and add to lower
    vextractf128 xmm1, ymm0, 1
    vaddps  xmm0, xmm0, xmm1
    // Horizontal add within 128 bits
    vhaddps xmm0, xmm0, xmm0
    vhaddps xmm0, xmm0, xmm0
    vmovss  Result, xmm0
    vzeroupper
  end;
end;

function AVX512ReduceMinF32x16(const a: TVecF32x16): Single;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vextractf64x4 ymm1, zmm0, 1
    vminps  ymm0, ymm0, ymm1
    vextractf128 xmm1, ymm0, 1
    vminps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $4E  // Swap high/low 64 bits
    vminps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $B1  // Swap adjacent pairs
    vminps  xmm0, xmm0, xmm1
    vmovss  Result, xmm0
    vzeroupper
  end;
end;

function AVX512ReduceMaxF32x16(const a: TVecF32x16): Single;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vextractf64x4 ymm1, zmm0, 1
    vmaxps  ymm0, ymm0, ymm1
    vextractf128 xmm1, ymm0, 1
    vmaxps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $4E
    vmaxps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $B1
    vmaxps  xmm0, xmm0, xmm1
    vmovss  Result, xmm0
    vzeroupper
  end;
end;

function AVX512ReduceMulF32x16(const a: TVecF32x16): Single;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovups zmm0, [rdx]
    vextractf64x4 ymm1, zmm0, 1
    vmulps  ymm0, ymm0, ymm1
    vextractf128 xmm1, ymm0, 1
    vmulps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $4E
    vmulps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $B1
    vmulps  xmm0, xmm0, xmm1
    vmovss  Result, xmm0
    vzeroupper
  end;
end;

// === F64x8 Reduction Operations ===

function AVX512ReduceAddF64x8(const a: TVecF64x8): Double;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vextractf64x4 ymm1, zmm0, 1
    vaddpd  ymm0, ymm0, ymm1
    vextractf128 xmm1, ymm0, 1
    vaddpd  xmm0, xmm0, xmm1
    vhaddpd xmm0, xmm0, xmm0
    vmovsd  Result, xmm0
    vzeroupper
  end;
end;

function AVX512ReduceMinF64x8(const a: TVecF64x8): Double;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vextractf64x4 ymm1, zmm0, 1
    vminpd  ymm0, ymm0, ymm1
    vextractf128 xmm1, ymm0, 1
    vminpd  xmm0, xmm0, xmm1
    vshufpd xmm1, xmm0, xmm0, 1
    vminpd  xmm0, xmm0, xmm1
    vmovsd  Result, xmm0
    vzeroupper
  end;
end;

function AVX512ReduceMaxF64x8(const a: TVecF64x8): Double;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vextractf64x4 ymm1, zmm0, 1
    vmaxpd  ymm0, ymm0, ymm1
    vextractf128 xmm1, ymm0, 1
    vmaxpd  xmm0, xmm0, xmm1
    vshufpd xmm1, xmm0, xmm0, 1
    vmaxpd  xmm0, xmm0, xmm1
    vmovsd  Result, xmm0
    vzeroupper
  end;
end;

function AVX512ReduceMulF64x8(const a: TVecF64x8): Double;
var
  pa: Pointer;
begin
  pa := @a;

  asm
    mov     rdx, pa
    vmovupd zmm0, [rdx]
    vextractf64x4 ymm1, zmm0, 1
    vmulpd  ymm0, ymm0, ymm1
    vextractf128 xmm1, ymm0, 1
    vmulpd  xmm0, xmm0, xmm1
    vshufpd xmm1, xmm0, xmm0, 1
    vmulpd  xmm0, xmm0, xmm1
    vmovsd  Result, xmm0
    vzeroupper
  end;
end;

// === TMask16 Operations (AVX-512 Optimized) ===

function AVX512Mask16All(mask: TMask16): Boolean; assembler; nostackframe;
// RDI = mask (16-bit)
asm
  cmp     di, $FFFF
  sete    al
end;

function AVX512Mask16Any(mask: TMask16): Boolean; assembler; nostackframe;
asm
  test    di, di
  setne   al
end;

function AVX512Mask16None(mask: TMask16): Boolean; assembler; nostackframe;
asm
  test    di, di
  sete    al
end;

function AVX512Mask16PopCount(mask: TMask16): Integer; assembler; nostackframe;
asm
  movzx   eax, di
  popcnt  eax, eax
end;

function AVX512Mask16FirstSet(mask: TMask16): Integer; assembler; nostackframe;
asm
  movzx   eax, di
  test    eax, eax
  jz      @none
  bsf     eax, eax
  ret
@none:
  mov     eax, -1
end;

// === ✅ P2: Saturating Arithmetic (EVEX-encoded 128-bit) ===
// 使用 EVEX 编码的 128-bit 指令，保持 API 一致性

// I8x16 有符号饱和加法 (VPADDSB)
function AVX512I8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // SysV ABI: a -> RDI, b -> RSI, Result -> RAX
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpaddsb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  // Win64 ABI: a -> RCX, b -> RDX, Result -> RAX
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpaddsb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// I8x16 有符号饱和减法 (VPSUBSB)
function AVX512I8x16SatSub(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpsubsb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpsubsb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// I16x8 有符号饱和加法 (VPADDSW)
function AVX512I16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpaddsw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpaddsw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// I16x8 有符号饱和减法 (VPSUBSW)
function AVX512I16x8SatSub(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpsubsw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpsubsw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// U8x16 无符号饱和加法 (VPADDUSB)
function AVX512U8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpaddusb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpaddusb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// U8x16 无符号饱和减法 (VPSUBUSB)
function AVX512U8x16SatSub(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpsubusb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpsubusb xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// U16x8 无符号饱和加法 (VPADDUSW)
function AVX512U16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpaddusw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpaddusw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// U16x8 无符号饱和减法 (VPSUBUSW)
function AVX512U16x8SatSub(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpsubusw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpsubusw xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  vzeroupper
  {$ENDIF}
end;

// === Fallback Functions ===

function MemDiffRange_AVX512(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  // 使用 AVX2 实现
  Result := MemDiffRange_AVX2(a, b, len, firstDiff, lastDiff);
end;

function BytesIndexOf_AVX512(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  // 使用 AVX2 实现
  Result := BytesIndexOf_AVX2(haystack, haystackLen, needle, needleLen);
end;

// === Backend Registration ===

function X86HasAVX512BackendRequiredFeatures(const X86: TX86Features): Boolean; inline;
begin
  // This backend uses:
  //   - AVX-512F + AVX-512BW (byte/word ops like vpcmpeqb/vpcmpub/vpminub/...)
  //   - AVX2 256-bit integer ops in fallback paths
  //   - POPCNT for bit counting (mask popcount)
  Result := X86.HasAVX2 and X86.HasAVX512F and X86.HasAVX512BW and X86.HasPOPCNT;
end;

procedure RegisterAVX512Backend;
var
  dispatchTable: TSimdDispatchTable;
  isAvailable: Boolean;
begin
  // Always register so the dispatch table can be inspected (e.g. on non-AVX-512 machines).
  // Runtime dispatch/forcing still prevents executing AVX-512 on unsupported CPUs.
  isAvailable := HasAVX512 and X86HasAVX512BackendRequiredFeatures(GetX86CPUInfo);

  // ✅ AVX-512 inherits all 128-bit and 256-bit operations from AVX2
  // This provides full coverage for F32x4, F64x2, I32x4, I64x2, F32x8, F64x4, etc.
  // AVX-512 only needs to override 512-bit operations and AVX-512-specific optimizations.
  dispatchTable := Default(TSimdDispatchTable);
  if not CloneDispatchTable(sbAVX2, dispatchTable) then
    FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbAVX512;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbAVX512;
    Name := 'AVX-512';
    Description := 'x86-64 AVX-512 SIMD implementation (512-bit)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scLoadStore, scMaskedOps, sc512BitOps];
    Available := isAvailable;
    Priority := 30; // Higher than AVX2 (20)
  end;

  // Override facade functions with AVX-512 accelerated versions
  dispatchTable.MemEqual := @MemEqual_AVX512;
  dispatchTable.MemFindByte := @MemFindByte_AVX512;
  dispatchTable.SumBytes := @SumBytes_AVX512;
  dispatchTable.CountByte := @CountByte_AVX512;
  dispatchTable.MinMaxBytes := @MinMaxBytes_AVX512;
  dispatchTable.BitsetPopCount := @BitsetPopCount_AVX512;
  dispatchTable.MemCopy := @MemCopy_AVX512;
  dispatchTable.MemSet := @MemSet_AVX512;
  dispatchTable.ToLowerAscii := @ToLowerAscii_AVX512;
  dispatchTable.ToUpperAscii := @ToUpperAscii_AVX512;
  dispatchTable.AsciiIEqual := @AsciiIEqual_AVX512;

  // Functions using AVX2 fallback (complex algorithms)
  dispatchTable.Utf8Validate := @Utf8Validate_AVX512;
  dispatchTable.MemReverse := @MemReverse_AVX512;
  dispatchTable.MemDiffRange := @MemDiffRange_AVX512;
  dispatchTable.BytesIndexOf := @BytesIndexOf_AVX512;

  // === 512-bit Vector Type Operations ===

  // F32x16 (512-bit float)
  dispatchTable.AddF32x16 := @AVX512AddF32x16;
  dispatchTable.SubF32x16 := @AVX512SubF32x16;
  dispatchTable.MulF32x16 := @AVX512MulF32x16;
  dispatchTable.DivF32x16 := @AVX512DivF32x16;

  dispatchTable.LoadF32x16 := @AVX512LoadF32x16;
  dispatchTable.StoreF32x16 := @AVX512StoreF32x16;
  dispatchTable.SplatF32x16 := @AVX512SplatF32x16;
  dispatchTable.ZeroF32x16 := @AVX512ZeroF32x16;
  dispatchTable.SelectF32x16 := @AVX512SelectF32x16;

  // F64x8 (512-bit double)
  dispatchTable.AddF64x8 := @AVX512AddF64x8;
  dispatchTable.SubF64x8 := @AVX512SubF64x8;
  dispatchTable.MulF64x8 := @AVX512MulF64x8;
  dispatchTable.DivF64x8 := @AVX512DivF64x8;

  dispatchTable.LoadF64x8 := @AVX512LoadF64x8;
  dispatchTable.StoreF64x8 := @AVX512StoreF64x8;
  dispatchTable.SplatF64x8 := @AVX512SplatF64x8;
  dispatchTable.ZeroF64x8 := @AVX512ZeroF64x8;
  dispatchTable.SelectF64x8 := @AVX512SelectF64x8;

  // I32x16 (512-bit integer) - Arithmetic
  dispatchTable.AddI32x16 := @AVX512AddI32x16;
  dispatchTable.SubI32x16 := @AVX512SubI32x16;
  dispatchTable.MulI32x16 := @AVX512MulI32x16;

  // I32x16 (512-bit integer) - Bitwise
  dispatchTable.AndI32x16 := @AVX512AndI32x16;
  dispatchTable.OrI32x16 := @AVX512OrI32x16;
  dispatchTable.XorI32x16 := @AVX512XorI32x16;
  dispatchTable.NotI32x16 := @AVX512NotI32x16;
  dispatchTable.AndNotI32x16 := @AVX512AndNotI32x16;

  // I32x16 (512-bit integer) - Shift
  dispatchTable.ShiftLeftI32x16 := @AVX512ShiftLeftI32x16;
  dispatchTable.ShiftRightI32x16 := @AVX512ShiftRightI32x16;
  dispatchTable.ShiftRightArithI32x16 := @AVX512ShiftRightArithI32x16;

  // I32x16 (512-bit integer) - Comparison
  dispatchTable.CmpEqI32x16 := @AVX512CmpEqI32x16;
  dispatchTable.CmpLtI32x16 := @AVX512CmpLtI32x16;
  dispatchTable.CmpGtI32x16 := @AVX512CmpGtI32x16;
  dispatchTable.CmpLeI32x16 := @AVX512CmpLeI32x16;  // ✅ P0-1: 补充缺失
  dispatchTable.CmpGeI32x16 := @AVX512CmpGeI32x16;  // ✅ P0-1: 补充缺失
  dispatchTable.CmpNeI32x16 := @AVX512CmpNeI32x16;  // ✅ P0-1: 补充缺失

  // I32x16 (512-bit integer) - Min/Max
  dispatchTable.MinI32x16 := @AVX512MinI32x16;
  dispatchTable.MaxI32x16 := @AVX512MaxI32x16;

  // === I64x8 (512-bit 64-bit integer) ===
  dispatchTable.AddI64x8 := @AVX512AddI64x8;
  dispatchTable.SubI64x8 := @AVX512SubI64x8;
  dispatchTable.AndI64x8 := @AVX512AndI64x8;
  dispatchTable.OrI64x8 := @AVX512OrI64x8;
  dispatchTable.XorI64x8 := @AVX512XorI64x8;
  dispatchTable.NotI64x8 := @AVX512NotI64x8;
  dispatchTable.CmpEqI64x8 := @AVX512CmpEqI64x8;
  dispatchTable.CmpLtI64x8 := @AVX512CmpLtI64x8;
  dispatchTable.CmpGtI64x8 := @AVX512CmpGtI64x8;
  dispatchTable.CmpLeI64x8 := @AVX512CmpLeI64x8;
  dispatchTable.CmpGeI64x8 := @AVX512CmpGeI64x8;
  dispatchTable.CmpNeI64x8 := @AVX512CmpNeI64x8;

  // === F32x16 Comparison Operations ===
  dispatchTable.CmpEqF32x16 := @AVX512CmpEqF32x16;
  dispatchTable.CmpLtF32x16 := @AVX512CmpLtF32x16;
  dispatchTable.CmpLeF32x16 := @AVX512CmpLeF32x16;
  dispatchTable.CmpGtF32x16 := @AVX512CmpGtF32x16;
  dispatchTable.CmpGeF32x16 := @AVX512CmpGeF32x16;
  dispatchTable.CmpNeF32x16 := @AVX512CmpNeF32x16;

  // === F64x8 Comparison Operations ===
  dispatchTable.CmpEqF64x8 := @AVX512CmpEqF64x8;
  dispatchTable.CmpLtF64x8 := @AVX512CmpLtF64x8;
  dispatchTable.CmpLeF64x8 := @AVX512CmpLeF64x8;
  dispatchTable.CmpGtF64x8 := @AVX512CmpGtF64x8;
  dispatchTable.CmpGeF64x8 := @AVX512CmpGeF64x8;
  dispatchTable.CmpNeF64x8 := @AVX512CmpNeF64x8;

  // === F32x16 Math Functions ===
  dispatchTable.AbsF32x16 := @AVX512AbsF32x16;
  dispatchTable.SqrtF32x16 := @AVX512SqrtF32x16;
  dispatchTable.MinF32x16 := @AVX512MinF32x16;
  dispatchTable.MaxF32x16 := @AVX512MaxF32x16;
  dispatchTable.ClampF32x16 := @AVX512ClampF32x16;
  dispatchTable.FmaF32x16 := @AVX512FmaF32x16;
  dispatchTable.FloorF32x16 := @AVX512FloorF32x16;
  dispatchTable.CeilF32x16 := @AVX512CeilF32x16;
  dispatchTable.RoundF32x16 := @AVX512RoundF32x16;
  dispatchTable.TruncF32x16 := @AVX512TruncF32x16;

  // === F64x8 Math Functions ===
  dispatchTable.AbsF64x8 := @AVX512AbsF64x8;
  dispatchTable.SqrtF64x8 := @AVX512SqrtF64x8;
  dispatchTable.MinF64x8 := @AVX512MinF64x8;
  dispatchTable.MaxF64x8 := @AVX512MaxF64x8;
  dispatchTable.ClampF64x8 := @AVX512ClampF64x8;
  dispatchTable.FmaF64x8 := @AVX512FmaF64x8;
  dispatchTable.FloorF64x8 := @AVX512FloorF64x8;
  dispatchTable.CeilF64x8 := @AVX512CeilF64x8;
  dispatchTable.RoundF64x8 := @AVX512RoundF64x8;
  dispatchTable.TruncF64x8 := @AVX512TruncF64x8;

  // === F32x16 Reduction Operations ===
  dispatchTable.ReduceAddF32x16 := @AVX512ReduceAddF32x16;
  dispatchTable.ReduceMinF32x16 := @AVX512ReduceMinF32x16;
  dispatchTable.ReduceMaxF32x16 := @AVX512ReduceMaxF32x16;
  dispatchTable.ReduceMulF32x16 := @AVX512ReduceMulF32x16;

  // === F64x8 Reduction Operations ===
  dispatchTable.ReduceAddF64x8 := @AVX512ReduceAddF64x8;
  dispatchTable.ReduceMinF64x8 := @AVX512ReduceMinF64x8;
  dispatchTable.ReduceMaxF64x8 := @AVX512ReduceMaxF64x8;
  dispatchTable.ReduceMulF64x8 := @AVX512ReduceMulF64x8;

  // === Mask16 Operations (AVX-512 Optimized) ===
  dispatchTable.Mask16All := @AVX512Mask16All;
  dispatchTable.Mask16Any := @AVX512Mask16Any;
  dispatchTable.Mask16None := @AVX512Mask16None;
  dispatchTable.Mask16PopCount := @AVX512Mask16PopCount;
  dispatchTable.Mask16FirstSet := @AVX512Mask16FirstSet;

  // ✅ P2: Saturating Arithmetic (EVEX-encoded, always enabled)
  dispatchTable.I8x16SatAdd := @AVX512I8x16SatAdd;
  dispatchTable.I8x16SatSub := @AVX512I8x16SatSub;
  dispatchTable.I16x8SatAdd := @AVX512I16x8SatAdd;
  dispatchTable.I16x8SatSub := @AVX512I16x8SatSub;
  dispatchTable.U8x16SatAdd := @AVX512U8x16SatAdd;
  dispatchTable.U8x16SatSub := @AVX512U8x16SatSub;
  dispatchTable.U16x8SatAdd := @AVX512U16x8SatAdd;
  dispatchTable.U16x8SatSub := @AVX512U16x8SatSub;

  // Register the backend
  RegisterBackend(sbAVX512, dispatchTable);
end;

initialization
  RegisterAVX512Backend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbAVX512, @RegisterAVX512Backend);

end.

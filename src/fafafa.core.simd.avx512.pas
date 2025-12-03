unit fafafa.core.simd.avx512;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.types,
  fafafa.core.simd.dispatch;

// === AVX-512 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 AVX-512 instructions.
// This backend requires AVX-512F support (Intel Skylake-X 2017+, AMD Zen 4 2022+).
// Uses 512-bit ZMM registers, processing 64 bytes per iteration.

// Register the AVX-512 backend
procedure RegisterAVX512Backend;

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
  fafafa.core.simd.scalar,
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

function AsciiIEqual_AVX512(a, b: Pointer; len: SizeUInt): Boolean;
begin
  // ASCII 比较使用 AVX2 实现
  Result := AsciiIEqual_AVX2(a, b, len);
end;

procedure ToLowerAscii_AVX512(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_AVX2(p, len);
end;

procedure ToUpperAscii_AVX512(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_AVX2(p, len);
end;

procedure MemCopy_AVX512(src, dst: Pointer; len: SizeUInt);
begin
  if (len = 0) or (src = nil) or (dst = nil) then
    Exit;
  Move(src^, dst^, len);
end;

procedure MemSet_AVX512(dst: Pointer; len: SizeUInt; value: Byte);
begin
  if (len = 0) or (dst = nil) then
    Exit;
  FillChar(dst^, len, value);
end;

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

procedure RegisterAVX512Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if AVX-512 is available
  if not HasAVX512 then
    Exit;

  // Initialize dispatch table
  FillChar(dispatchTable, SizeOf(dispatchTable), 0);

  // Set backend info
  dispatchTable.Backend := sbAVX512;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbAVX512;
    Name := 'AVX-512';
    Description := 'x86-64 AVX-512 SIMD implementation (512-bit)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction, scLoadStore, scMaskedOps];
    Available := True;
    Priority := 30; // Higher than AVX2 (20)
  end;

  // Register facade functions (AVX-512 accelerated)
  dispatchTable.MemEqual := @MemEqual_AVX512;
  dispatchTable.MemFindByte := @MemFindByte_AVX512;
  dispatchTable.SumBytes := @SumBytes_AVX512;
  dispatchTable.CountByte := @CountByte_AVX512;
  dispatchTable.MinMaxBytes := @MinMaxBytes_AVX512;
  dispatchTable.BitsetPopCount := @BitsetPopCount_AVX512;
  
  // Functions that use AVX2 fallback
  dispatchTable.Utf8Validate := @Utf8Validate_AVX512;
  dispatchTable.MemReverse := @MemReverse_AVX512;
  dispatchTable.AsciiIEqual := @AsciiIEqual_AVX512;
  dispatchTable.ToLowerAscii := @ToLowerAscii_AVX512;
  dispatchTable.ToUpperAscii := @ToUpperAscii_AVX512;
  dispatchTable.MemCopy := @MemCopy_AVX512;
  dispatchTable.MemSet := @MemSet_AVX512;
  dispatchTable.MemDiffRange := @MemDiffRange_AVX512;
  dispatchTable.BytesIndexOf := @BytesIndexOf_AVX512;

  // Register the backend
  RegisterBackend(sbAVX512, dispatchTable);
end;

initialization
  RegisterAVX512Backend;

end.

unit fafafa.core.simd.sse2;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// === SSE2 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 SSE2 instructions.
// This backend is available on all x86-64 processors.

// Register the SSE2 backend
procedure RegisterSSE2Backend;

// === SSE2 门面函数声明 ===

// 内存操作函数
function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
procedure MemCopy_SSE2(src, dst: Pointer; len: SizeUInt);
procedure MemSet_SSE2(dst: Pointer; len: SizeUInt; value: Byte);

// 统计函数
function SumBytes_SSE2(p: Pointer; len: SizeUInt): UInt64;
function CountByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;

// ✅ P2-1: 饱和算术（SSE2 PADDS/PSUBS 指令加速）
function SSE2I8x16SatAdd(const a, b: TVecI8x16): TVecI8x16;
function SSE2I8x16SatSub(const a, b: TVecI8x16): TVecI8x16;
function SSE2I16x8SatAdd(const a, b: TVecI16x8): TVecI16x8;
function SSE2I16x8SatSub(const a, b: TVecI16x8): TVecI16x8;
function SSE2U8x16SatAdd(const a, b: TVecU8x16): TVecU8x16;
function SSE2U8x16SatSub(const a, b: TVecU8x16): TVecU8x16;
function SSE2U16x8SatAdd(const a, b: TVecU16x8): TVecU16x8;
function SSE2U16x8SatSub(const a, b: TVecU16x8): TVecU16x8;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.scalar, // For fallback functions
  fafafa.core.simd.sync,   // For atomic operations
  fafafa.core.math;

// === SSE2 Arithmetic Operations ===
// Note: FPC x86-64 calling convention:
//   - First 6 integer/pointer args: RDI, RSI, RDX, RCX, R8, R9
//   - Float args: XMM0-XMM7
//   - Result pointer for large structs: hidden first arg in RDI
//   - For const record params, pointer is passed

function SSE2AddF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    addps  xmm0, xmm1
    movups [result], xmm0
  end;
end;

function SSE2SubF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    subps  xmm0, xmm1
    movups [result], xmm0
  end;
end;

function SSE2MulF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    mulps  xmm0, xmm1
    movups [result], xmm0
  end;
end;

function SSE2DivF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    divps  xmm0, xmm1
    movups [result], xmm0
  end;
end;

function SSE2AddF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    addpd  xmm0, xmm1
    movupd [result], xmm0
  end;
end;

function SSE2SubF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    subpd  xmm0, xmm1
    movupd [result], xmm0
  end;
end;

function SSE2MulF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    mulpd  xmm0, xmm1
    movupd [result], xmm0
  end;
end;

function SSE2DivF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    divpd  xmm0, xmm1
    movupd [result], xmm0
  end;
end;

function SSE2AddI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddd  xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

function SSE2SubI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubd  xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// Note: SSE2 has no direct SIMD multiply for 32-bit integers
// We need to use SSE4.1's pmulld or simulate with pmuludq
// For now, use scalar fallback
function SSE2MulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] * b.i[i];
end;

// === SSE2 Comparison Operations ===

function SSE2CmpEqF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpeqps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLeF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  // GT: swap operands and use LT
  asm
    lea      rax, b
    lea      rdx, a
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGeF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  // GE: swap operands and use LE
  asm
    lea      rax, b
    lea      rdx, a
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpNeF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpneqps xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

// === SSE2 Math Functions ===

function SSE2AbsF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    pcmpeqd xmm1, xmm1       // all 1s
    psrld   xmm1, 1          // shift right to get 0x7FFFFFFF
    andps   xmm0, xmm1
    movups  [result], xmm0
  end;
end;

function SSE2SqrtF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    sqrtps xmm0, xmm0
    movups [result], xmm0
  end;
end;

function SSE2MinF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    minps  xmm0, xmm1
    movups [result], xmm0
  end;
end;

function SSE2MaxF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    maxps  xmm0, xmm1
    movups [result], xmm0
  end;
end;

// === SSE2 Reduction Operations ===

function SSE2ReduceAddF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

function SSE2ReduceMinF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    minps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    minss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

function SSE2ReduceMaxF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    maxps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    maxss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

function SSE2ReduceMulF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    mulps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    mulss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

// === SSE2 Memory Operations ===

function SSE2LoadF32x4(p: PSingle): TVecF32x4;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2LoadF32x4: pointer is nil');
  asm
    mov    rax, p
    movups xmm0, [rax]
    movups [result], xmm0
  end;
end;

function SSE2LoadF32x4Aligned(p: PSingle): TVecF32x4;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2LoadF32x4Aligned: pointer is nil');
  Assert((PtrUInt(p) and $F) = 0, 'SSE2LoadF32x4Aligned: Pointer must be 16-byte aligned');
  asm
    mov    rax, p
    movaps xmm0, [rax]
    movups [result], xmm0
  end;
end;

procedure SSE2StoreF32x4(p: PSingle; const a: TVecF32x4);
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2StoreF32x4: pointer is nil');
  asm
    mov    rax, p
    lea    rdx, a
    movups xmm0, [rdx]
    movups [rax], xmm0
  end;
end;

procedure SSE2StoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2StoreF32x4Aligned: pointer is nil');
  Assert((PtrUInt(p) and $F) = 0, 'SSE2StoreF32x4Aligned: Pointer must be 16-byte aligned');
  asm
    mov    rax, p
    lea    rdx, a
    movups xmm0, [rdx]
    movaps [rax], xmm0
  end;
end;

// === SSE2 Utility Operations ===

function SSE2SplatF32x4(value: Single): TVecF32x4;
begin
  asm
    movss  xmm0, value
    shufps xmm0, xmm0, 0
    movups [result], xmm0
  end;
end;

function SSE2ZeroF32x4: TVecF32x4;
begin
  asm
    xorps  xmm0, xmm0
    movups [result], xmm0
  end;
end;

function SSE2SelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function SSE2ExtractF32x4(const a: TVecF32x4; index: Integer): Single;
var
  safeIndex: Integer;
begin
  // ✅ Safety check: use saturation strategy for index bounds (per project spec)
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  Result := a.f[safeIndex];
end;

function SSE2InsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var
  safeIndex: Integer;
begin
  // ✅ Safety check: use saturation strategy for index bounds (per project spec)
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  Result := a;
  Result.f[safeIndex] := value;
end;

// === F32x8 Operations (simulate with 2x F32x4) ===

function SSE2AddF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := SSE2AddF32x4(a.lo, b.lo);
  Result.hi := SSE2AddF32x4(a.hi, b.hi);
end;

function SSE2SubF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := SSE2SubF32x4(a.lo, b.lo);
  Result.hi := SSE2SubF32x4(a.hi, b.hi);
end;

function SSE2MulF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := SSE2MulF32x4(a.lo, b.lo);
  Result.hi := SSE2MulF32x4(a.hi, b.hi);
end;

function SSE2DivF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := SSE2DivF32x4(a.lo, b.lo);
  Result.hi := SSE2DivF32x4(a.hi, b.hi);
end;

// === SSE2 Memory Functions ===

function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool;
var
  pa, pb: PByte;
  i: SizeUInt;
  maskA, maskB: Integer;
begin
  {$PUSH}{$Q-}{$R-}  // Disable overflow/range checks for SIMD loop
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);
  i := 0;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      mov   rax, pa
      mov   rdx, pb
      add   rax, i
      add   rdx, i
      movdqu xmm0, [rax]
      movdqu xmm1, [rdx]
      pcmpeqb xmm0, xmm1
      pmovmskb eax, xmm0
      mov   maskA, eax
    end;

    if maskA <> $FFFF then
    begin
      Result := False;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pa[i] <> pb[i] then
    begin
      Result := False;
      Exit;
    end;
    Inc(i);
  end;

  Result := True;
  {$POP}
end;

function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  pb: PByte;
  i: SizeUInt;
  mask: Integer;
  bitPos: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := -1;
    Exit;
  end;

  pb := PByte(p);
  i := 0;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      mov      rax, pb
      add      rax, i
      movzx    edx, value
      movd     xmm1, edx
      punpcklbw xmm1, xmm1
      pshuflw  xmm1, xmm1, 0
      punpcklqdq xmm1, xmm1  // Broadcast value to all 16 bytes
      movdqu   xmm0, [rax]
      pcmpeqb  xmm0, xmm1
      pmovmskb eax, xmm0
      mov      mask, eax
    end;

    if mask <> 0 then
    begin
      // Find first set bit
      asm
        bsf eax, mask
        mov bitPos, eax
      end;
      Result := PtrInt(i) + bitPos;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] = value then
    begin
      Result := PtrInt(i);
      Exit;
    end;
    Inc(i);
  end;

  Result := -1;
end;

procedure MemCopy_SSE2(src, dst: Pointer; len: SizeUInt); assembler; nostackframe;
// RDI = src, RSI = dst, RDX = len
asm
  test rdx, rdx
  jz @done
  test rdi, rdi
  jz @done
  test rsi, rsi
  jz @done
  cmp rdi, rsi
  je @done

  xor rcx, rcx           // i = 0

@loop16:
  lea rax, [rcx + 16]
  cmp rax, rdx
  ja @remainder
  movdqu xmm0, [rdi + rcx]
  movdqu [rsi + rcx], xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rdx
  jae @done
  mov al, [rdi + rcx]
  mov [rsi + rcx], al
  inc rcx
  jmp @remainder

@done:
end;

procedure MemSet_SSE2(dst: Pointer; len: SizeUInt; value: Byte); assembler; nostackframe;
// RDI = dst, RSI = len, RDX = value
asm
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 16 bytes
  movd xmm0, edx
  punpcklbw xmm0, xmm0
  pshuflw xmm0, xmm0, 0
  punpcklqdq xmm0, xmm0

  xor rcx, rcx           // i = 0

@loop16:
  lea rax, [rcx + 16]
  cmp rax, rsi
  ja @remainder
  movdqu [rdi + rcx], xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @done
  mov [rdi + rcx], dl
  inc rcx
  jmp @remainder

@done:
end;

function SumBytes_SSE2(p: Pointer; len: SizeUInt): UInt64;
var
  pb: PByte;
  i: SizeUInt;
  sum0, sum1, sum2, sum3: UInt32;
begin
  {$PUSH}{$Q-}{$R-}  // Disable overflow/range checks for SIMD loop
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  sum0 := 0;
  sum1 := 0;
  sum2 := 0;
  sum3 := 0;

  // Process 16 bytes at a time using SSE2
  // Use psadbw (sum of absolute differences) with zero to sum bytes
  while i + 16 <= len do
  begin
    asm
      mov      rax, pb
      add      rax, i
      movdqu   xmm0, [rax]
      pxor     xmm1, xmm1      // Zero register
      psadbw   xmm0, xmm1      // Sum bytes: result in low 16 bits of each 64-bit lane
      movd     eax, xmm0       // Get lower 64-bit sum
      add      sum0, eax
      psrldq   xmm0, 8         // Shift right 8 bytes
      movd     eax, xmm0       // Get upper 64-bit sum
      add      sum1, eax
    end;
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    Inc(sum2, pb[i]);
    Inc(i);
  end;

  Result := UInt64(sum0) + UInt64(sum1) + UInt64(sum2) + UInt64(sum3);
  {$POP}
end;

function CountByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; assembler; nostackframe;
// RDI = p, RSI = len, RDX = value
// Use SWAR popcount for 16-bit mask
asm
  xor rax, rax           // count = 0
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 16 bytes in xmm1
  movd xmm1, edx
  punpcklbw xmm1, xmm1
  pshuflw xmm1, xmm1, 0
  punpcklqdq xmm1, xmm1

  xor rcx, rcx           // i = 0

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  movdqu xmm0, [rdi + rcx]
  pcmpeqb xmm0, xmm1
  pmovmskb r8d, xmm0
  // Popcount using SWAR
  mov r9d, r8d
  shr r9d, 1
  and r9d, $5555
  sub r8d, r9d
  mov r9d, r8d
  shr r9d, 2
  and r8d, $3333
  and r9d, $3333
  add r8d, r9d
  mov r9d, r8d
  shr r9d, 4
  add r8d, r9d
  and r8d, $0F0F
  mov r9d, r8d
  shr r9d, 8
  add r8d, r9d
  and r8d, $FF
  add rax, r8
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @done
  movzx r8d, byte ptr [rdi + rcx]
  cmp r8d, edx
  jne @skip
  inc rax
@skip:
  inc rcx
  jmp @remainder

@done:
end;

// === Extended Math Functions ===

// FMA emulation: a*b + c (SSE2 has no native FMA)
function SSE2FmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    lea    rcx, c
    movups xmm0, [rax]
    movups xmm1, [rdx]
    movups xmm2, [rcx]
    mulps  xmm0, xmm1
    addps  xmm0, xmm2
    movups [result], xmm0
  end;
end;

// Reciprocal approximation (1/x)
function SSE2RcpF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    rcpps  xmm0, xmm0     // Approximate reciprocal (12-bit precision)
    movups [result], xmm0
  end;
end;

// Reciprocal square root approximation (1/sqrt(x))
function SSE2RsqrtF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    rsqrtps xmm0, xmm0    // Approximate rsqrt (12-bit precision)
    movups [result], xmm0
  end;
end;

// Floor/Ceil/Round/Trunc: Use SSE4.1 roundps if available, otherwise scalar fallback
// SSE4.1 roundps immediate values:
//   0 = Round to nearest (even)
//   1 = Round toward negative infinity (floor)
//   2 = Round toward positive infinity (ceil) 
//   3 = Round toward zero (truncate)

var
  g_HasSSE41: Boolean = False;
  g_SSE41CheckState: LongInt = 0; // 0=未检查, 1=检查中, 2=已完成

// ✅ Thread-safe SSE4.1 detection using atomic operations
procedure CheckSSE41;
var
  oldState: LongInt;
begin
  // 快速路径: 已完成检查
  if g_SSE41CheckState = 2 then Exit;

  oldState := InterlockedCompareExchange(g_SSE41CheckState, 1, 0);
  if oldState = 0 then
  begin
    // 我们是第一个检查者
    g_HasSSE41 := HasSSE41;
    WriteBarrier;
    InterlockedExchange(g_SSE41CheckState, 2);
  end
  else if oldState = 1 then
  begin
    // 另一个线程正在检查，自旋等待
    while g_SSE41CheckState <> 2 do
    begin
      ReadBarrier;
      ThreadSwitch;
    end;
  end;
  // oldState = 2: 已完成，直接返回
end;

function SSE2FloorF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    asm
      lea    rax, a
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 1  (floor)
      db $66, $0F, $3A, $08, $C0, $01
      movups [result], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Int(a.f[i]);
    // Adjust for negative numbers
    for i := 0 to 3 do
      if (a.f[i] < 0) and (Result.f[i] <> a.f[i]) then
        Result.f[i] := Result.f[i] - 1.0;
  end;
end;

function SSE2CeilF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    asm
      lea    rax, a
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 2  (ceil)
      db $66, $0F, $3A, $08, $C0, $02
      movups [result], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Int(a.f[i]);
    // Adjust for positive numbers
    for i := 0 to 3 do
      if (a.f[i] > 0) and (Result.f[i] <> a.f[i]) then
        Result.f[i] := Result.f[i] + 1.0;
  end;
end;

function SSE2RoundF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    asm
      lea    rax, a
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 0  (round to nearest even)
      db $66, $0F, $3A, $08, $C0, $00
      movups [result], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Round(a.f[i]);
  end;
end;

function SSE2TruncF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    asm
      lea    rax, a
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 3  (truncate)
      db $66, $0F, $3A, $08, $C0, $03
      movups [result], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Int(a.f[i]);
  end;
end;

// Clamp using SSE2 min/max
function SSE2ClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, minVal
    lea    rcx, maxVal
    movups xmm0, [rax]
    movups xmm1, [rdx]
    movups xmm2, [rcx]
    maxps  xmm0, xmm1     // max(a, minVal)
    minps  xmm0, xmm2     // min(result, maxVal)
    movups [result], xmm0
  end;
end;

// === Vector Math Functions ===

// Dot product (4 elements)
function SSE2DotF32x4(const a, b: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    lea     rdx, b
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1     // Element-wise multiply
    // Horizontal add: [a*b, c*d, e*f, g*h] -> sum
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E // Swap high/low pairs
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1 // Swap adjacent
    addss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

// Dot product (3 elements, ignore w)
function SSE2DotF32x3(const a, b: TVecF32x4): Single;
var t: TVecF32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1
    // Zero the w component before summing
    xorps   xmm1, xmm1
    movss   xmm1, xmm0     // xmm1 = [x, 0, 0, 0]
    shufps  xmm0, xmm0, $E9 // xmm0 = [y, z, z, w]
    addss   xmm1, xmm0     // x + y
    shufps  xmm0, xmm0, $E9
    addss   xmm1, xmm0     // x + y + z
    movss   [result], xmm1
  end;
end;

// Cross product (3D)
function SSE2CrossF32x3(const a, b: TVecF32x4): TVecF32x4;
begin
  // Cross = (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  asm
    lea     rax, a
    lea     rdx, b
    movups  xmm0, [rax]        // a = [x, y, z, w]
    movups  xmm1, [rdx]        // b = [x, y, z, w]
    
    // Shuffle a: [y, z, x, w]
    movaps  xmm2, xmm0
    shufps  xmm2, xmm2, $C9    // 11 00 10 01 -> y,z,x,w
    
    // Shuffle b: [z, x, y, w]
    movaps  xmm3, xmm1
    shufps  xmm3, xmm3, $D2    // 11 01 00 10 -> z,x,y,w
    
    mulps   xmm2, xmm3         // [a.y*b.z, a.z*b.x, a.x*b.y, ...]
    
    // Shuffle a: [z, x, y, w]
    movaps  xmm4, xmm0
    shufps  xmm4, xmm4, $D2
    
    // Shuffle b: [y, z, x, w]
    movaps  xmm5, xmm1
    shufps  xmm5, xmm5, $C9
    
    mulps   xmm4, xmm5         // [a.z*b.y, a.x*b.z, a.y*b.x, ...]
    
    subps   xmm2, xmm4         // Subtract to get [x', y', z', w']
    
    movups  [result], xmm2
  end;
  Result.f[3] := 0.0; // Ensure w=0
end;

// Vector length (4 elements)
function SSE2LengthF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    mulps   xmm0, xmm0      // Square each element
    // Horizontal add
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    sqrtss  xmm0, xmm0      // Square root
    movss   [result], xmm0
  end;
end;

// Vector length (3 elements)
function SSE2LengthF32x3(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    movups  xmm0, [rax]
    // Zero w before squaring
    pcmpeqd xmm1, xmm1
    psrldq  xmm1, 4          // Shift right to create mask [FF,FF,FF,00]
    andps   xmm0, xmm1       // Zero w
    mulps   xmm0, xmm0
    // Horizontal add
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    sqrtss  xmm0, xmm0
    movss   [result], xmm0
  end;
end;

// Normalize vector (4 elements)
function SSE2NormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var len: Single;
begin
  len := SSE2LengthF32x4(a);
  if len > 0 then
  begin
    asm
      lea     rax, a
      movups  xmm0, [rax]
      movss   xmm1, len
      shufps  xmm1, xmm1, 0   // Broadcast length
      divps   xmm0, xmm1      // Divide each element by length
      movups  [result], xmm0
    end;
  end
  else
    Result := a;
end;

// Normalize vector (3 elements, w=0)
function SSE2NormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var len: Single;
begin
  len := SSE2LengthF32x3(a);
  if len > 0 then
  begin
    asm
      lea     rax, a
      movups  xmm0, [rax]
      movss   xmm1, len
      shufps  xmm1, xmm1, 0
      divps   xmm0, xmm1
      movups  [result], xmm0
    end;
    Result.f[3] := 0.0;
  end
  else
  begin
    Result := a;
    Result.f[3] := 0.0;
  end;
end;

// === Additional Facade Functions with SSE2 ===

// MinMax with SSE2
procedure MinMaxBytes_SSE2(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
var
  pb: PByte;
  i: SizeUInt;
  minAcc, maxAcc: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    minVal := 0;
    maxVal := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  minAcc := 255;
  maxAcc := 0;

  // Process 16 bytes at a time
  while i + 16 <= len do
  begin
    asm
      mov     rax, pb
      add     rax, i
      movdqu  xmm0, [rax]
      
      // Get min
      movdqa  xmm1, xmm0
      psrlw   xmm1, 8
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrld   xmm1, 16
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrlq   xmm1, 32
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrldq  xmm1, 8
      pminub  xmm0, xmm1
      movd    eax, xmm0
      and     eax, $FF
      cmp     eax, minAcc
      jge     @skipmin
      mov     minAcc, eax
    @skipmin:
      
      // Get max
      mov     rax, pb
      add     rax, i
      movdqu  xmm0, [rax]
      movdqa  xmm1, xmm0
      psrlw   xmm1, 8
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrld   xmm1, 16
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrlq   xmm1, 32
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrldq  xmm1, 8
      pmaxub  xmm0, xmm1
      movd    eax, xmm0
      and     eax, $FF
      cmp     eax, maxAcc
      jle     @skipmax
      mov     maxAcc, eax
    @skipmax:
    end;
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] < minAcc then
      minAcc := pb[i];
    if pb[i] > maxAcc then
      maxAcc := pb[i];
    Inc(i);
  end;

  minVal := Byte(minAcc);
  maxVal := Byte(maxAcc);
end;

// Popcount with SSE2 (using lookup table)
function BitsetPopCount_SSE2(p: Pointer; len: SizeUInt): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
  count: SizeUInt;
  b: Byte;
const
  PopCountTable: array[0..15] of Byte = (
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
  );
begin
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  count := 0;
  i := 0;

  // Use SWAR technique for bulk processing
  while i + 8 <= len do
  begin
    asm
      mov     rax, pb
      add     rax, i
      mov     rdx, [rax]      // Load 8 bytes
      
      // SWAR popcount
      mov     rcx, rdx
      shr     rcx, 1
      mov     r8, $5555555555555555
      and     rcx, r8
      sub     rdx, rcx
      
      mov     rcx, rdx
      shr     rcx, 2
      mov     r8, $3333333333333333
      and     rdx, r8
      and     rcx, r8
      add     rdx, rcx
      
      mov     rcx, rdx
      shr     rcx, 4
      add     rdx, rcx
      mov     r8, $0F0F0F0F0F0F0F0F
      and     rdx, r8
      
      mov     r8, $0101010101010101
      imul    rdx, r8
      shr     rdx, 56
      
      add     count, rdx
    end;
    Inc(i, 8);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    b := pb[i];
    Inc(count, PopCountTable[b and $0F] + PopCountTable[b shr 4]);
    Inc(i);
  end;

  Result := count;
end;

// === ✅ P2-1: Saturating Arithmetic (SSE2 硬件加速) ===
// SSE2 提供专门的饱和算术指令，比标量实现快 8-16x

// I8x16 有符号饱和加法 (PADDSB)
function SSE2I8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // x86-64 SysV ABI: a -> RDI, b -> RSI, Result -> RAX
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  // Windows x64: a -> RCX, b -> RDX, Result -> RAX
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I8x16 有符号饱和减法 (PSUBSB)
function SSE2I8x16SatSub(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I16x8 有符号饱和加法 (PADDSW)
function SSE2I16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I16x8 有符号饱和减法 (PSUBSW)
function SSE2I16x8SatSub(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U8x16 无符号饱和加法 (PADDUSB)
function SSE2U8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U8x16 无符号饱和减法 (PSUBUSB)
function SSE2U8x16SatSub(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U16x8 无符号饱和加法 (PADDUSW)
function SSE2U16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U16x8 无符号饱和减法 (PSUBUSW)
function SSE2U16x8SatSub(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// === Backend Registration ===

procedure RegisterSSE2Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSE2 is available
  if not HasSSE2 then
    Exit;

  // Fill with base scalar implementations (provides fallback for all operations)
  FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbSSE2;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSE2;
    Name := 'SSE2';
    Description := 'x86-64 SSE2 SIMD implementation';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction, scLoadStore];
    Available := True;
    Priority := 10; // Higher than scalar
  end;

  // Vector-related operations default to Scalar reference implementations.
  // You can enable SSE2 vector ops for experimentation via SetVectorAsmEnabled(True)
  // (note: SSE2 asm path is not yet fully validated under FPC's calling conventions).

  if IsVectorAsmEnabled then
  begin
    // Override with SSE2 arithmetic operations
    dispatchTable.AddF32x4 := @SSE2AddF32x4;
    dispatchTable.SubF32x4 := @SSE2SubF32x4;
    dispatchTable.MulF32x4 := @SSE2MulF32x4;
    dispatchTable.DivF32x4 := @SSE2DivF32x4;

    dispatchTable.AddF32x8 := @SSE2AddF32x8;
    dispatchTable.SubF32x8 := @SSE2SubF32x8;
    dispatchTable.MulF32x8 := @SSE2MulF32x8;
    dispatchTable.DivF32x8 := @SSE2DivF32x8;

    dispatchTable.AddF64x2 := @SSE2AddF64x2;
    dispatchTable.SubF64x2 := @SSE2SubF64x2;
    dispatchTable.MulF64x2 := @SSE2MulF64x2;
    dispatchTable.DivF64x2 := @SSE2DivF64x2;

    dispatchTable.AddI32x4 := @SSE2AddI32x4;
    dispatchTable.SubI32x4 := @SSE2SubI32x4;
    dispatchTable.MulI32x4 := @SSE2MulI32x4;

    // Override with SSE2 comparison operations
    dispatchTable.CmpEqF32x4 := @SSE2CmpEqF32x4;
    dispatchTable.CmpLtF32x4 := @SSE2CmpLtF32x4;
    dispatchTable.CmpLeF32x4 := @SSE2CmpLeF32x4;
    dispatchTable.CmpGtF32x4 := @SSE2CmpGtF32x4;
    dispatchTable.CmpGeF32x4 := @SSE2CmpGeF32x4;
    dispatchTable.CmpNeF32x4 := @SSE2CmpNeF32x4;

    // Override with SSE2 math functions
    dispatchTable.AbsF32x4 := @SSE2AbsF32x4;
    dispatchTable.SqrtF32x4 := @SSE2SqrtF32x4;
    dispatchTable.MinF32x4 := @SSE2MinF32x4;
    dispatchTable.MaxF32x4 := @SSE2MaxF32x4;

    // Override with SSE2 extended math functions
    dispatchTable.FmaF32x4 := @SSE2FmaF32x4;
    dispatchTable.RcpF32x4 := @SSE2RcpF32x4;
    dispatchTable.RsqrtF32x4 := @SSE2RsqrtF32x4;
    dispatchTable.FloorF32x4 := @SSE2FloorF32x4;
    dispatchTable.CeilF32x4 := @SSE2CeilF32x4;
    dispatchTable.RoundF32x4 := @SSE2RoundF32x4;
    dispatchTable.TruncF32x4 := @SSE2TruncF32x4;
    dispatchTable.ClampF32x4 := @SSE2ClampF32x4;

    // Override with SSE2 vector math functions
    dispatchTable.DotF32x4 := @SSE2DotF32x4;
    dispatchTable.DotF32x3 := @SSE2DotF32x3;
    dispatchTable.CrossF32x3 := @SSE2CrossF32x3;
    dispatchTable.LengthF32x4 := @SSE2LengthF32x4;
    dispatchTable.LengthF32x3 := @SSE2LengthF32x3;
    dispatchTable.NormalizeF32x4 := @SSE2NormalizeF32x4;
    dispatchTable.NormalizeF32x3 := @SSE2NormalizeF32x3;

    // Override with SSE2 reduction operations
    dispatchTable.ReduceAddF32x4 := @SSE2ReduceAddF32x4;
    dispatchTable.ReduceMinF32x4 := @SSE2ReduceMinF32x4;
    dispatchTable.ReduceMaxF32x4 := @SSE2ReduceMaxF32x4;
    dispatchTable.ReduceMulF32x4 := @SSE2ReduceMulF32x4;

    // Override with SSE2 memory operations
    dispatchTable.LoadF32x4 := @SSE2LoadF32x4;
    dispatchTable.LoadF32x4Aligned := @SSE2LoadF32x4Aligned;
    dispatchTable.StoreF32x4 := @SSE2StoreF32x4;
    dispatchTable.StoreF32x4Aligned := @SSE2StoreF32x4Aligned;

    // Override with SSE2 utility operations
    dispatchTable.SplatF32x4 := @SSE2SplatF32x4;
    dispatchTable.ZeroF32x4 := @SSE2ZeroF32x4;
    dispatchTable.SelectF32x4 := @SSE2SelectF32x4;
    dispatchTable.ExtractF32x4 := @SSE2ExtractF32x4;
    dispatchTable.InsertF32x4 := @SSE2InsertF32x4;
  end;
  // else: keep scalar implementations from FillBaseDispatchTable

  // Override facade functions with SSE2-accelerated versions
  dispatchTable.MemEqual := @MemEqual_SSE2;
  dispatchTable.MemFindByte := @MemFindByte_SSE2;
  dispatchTable.SumBytes := @SumBytes_SSE2;
  dispatchTable.CountByte := @CountByte_SSE2;
  dispatchTable.MinMaxBytes := @MinMaxBytes_SSE2;
  dispatchTable.BitsetPopCount := @BitsetPopCount_SSE2;
  // Note: MemCopy, MemSet, MemDiffRange, MemReverse, Utf8Validate, etc.
  // keep scalar implementations (FPC's Move/FillChar are already optimized)

  // ✅ P2-1: Override with SSE2 saturating arithmetic (always enabled, stable ops)
  dispatchTable.I8x16SatAdd := @SSE2I8x16SatAdd;
  dispatchTable.I8x16SatSub := @SSE2I8x16SatSub;
  dispatchTable.I16x8SatAdd := @SSE2I16x8SatAdd;
  dispatchTable.I16x8SatSub := @SSE2I16x8SatSub;
  dispatchTable.U8x16SatAdd := @SSE2U8x16SatAdd;
  dispatchTable.U8x16SatSub := @SSE2U8x16SatSub;
  dispatchTable.U16x8SatAdd := @SSE2U16x8SatAdd;
  dispatchTable.U16x8SatSub := @SSE2U16x8SatSub;

  // Register the backend
  RegisterBackend(sbSSE2, dispatchTable);
end;

initialization
  RegisterSSE2Backend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbSSE2, @RegisterSSE2Backend);

end.

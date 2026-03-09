// ============================================================================
// ✅ 512-bit 向量的 SSE2 渐进降级实现 (2026-02-05)
// 策略: 使用 2×256-bit 操作 (利用已有的 F32x8/F64x4/I32x8)
// ============================================================================

// === F32x16 操作 (16×Float32) ===
function SSE2AddF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2SubF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2MulF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2DivF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2AbsF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2SqrtF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2MinF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2MaxF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2FmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
function SSE2FloorF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2CeilF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2RoundF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2TruncF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2ClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
function SSE2ReduceAddF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMinF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMaxF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMulF32x16(const a: TVecF32x16): Single;
function SSE2LoadF32x16(p: PSingle): TVecF32x16;
procedure SSE2StoreF32x16(p: PSingle; const a: TVecF32x16);
function SSE2SplatF32x16(value: Single): TVecF32x16;
function SSE2ZeroF32x16: TVecF32x16;
function SSE2CmpEqF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpLtF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpLeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpGtF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpGeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpNeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2SelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;

// === F64x8 操作 (8×Float64) ===
function SSE2AddF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2SubF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2MulF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2DivF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2AbsF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2SqrtF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2MinF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2MaxF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2FmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
function SSE2FloorF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2CeilF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2RoundF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2TruncF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2ClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
function SSE2ReduceAddF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMinF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMaxF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMulF64x8(const a: TVecF64x8): Double;
function SSE2LoadF64x8(p: PDouble): TVecF64x8;
procedure SSE2StoreF64x8(p: PDouble; const a: TVecF64x8);
function SSE2SplatF64x8(value: Double): TVecF64x8;
function SSE2ZeroF64x8: TVecF64x8;
function SSE2CmpEqF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpLtF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpLeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpGtF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpGeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpNeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2SelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;

// ✅ NEW: 缺失的 Select 操作 (条件选择: mask[i] != 0 ? a[i] : b[i])
function SSE2SelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
function SSE2SelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
function SSE2SelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;

// === I32x16 操作 (16×Int32) ===
function SSE2AddI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2SubI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2MulI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2AndI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2OrI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2XorI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2NotI32x16(const a: TVecI32x16): TVecI32x16;
function SSE2AndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2ShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2ShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2ShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2CmpEqI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpLtI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpGtI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpLeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpGeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpNeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2MinI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2MaxI32x16(const a, b: TVecI32x16): TVecI32x16;

// ============================================================================
// ✅ NEW: I64x4 操作 (256-bit AVX2 仿真，使用 2×I64x2)
// ============================================================================
function SSE2AddI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2SubI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2AndI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2OrI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2XorI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2NotI64x4(const a: TVecI64x4): TVecI64x4;
function SSE2AndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2ShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
function SSE2ShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
function SSE2CmpEqI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpLtI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpGtI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpLeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpGeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpNeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2LoadI64x4(p: PInt64): TVecI64x4;
procedure SSE2StoreI64x4(p: PInt64; const a: TVecI64x4);
function SSE2SplatI64x4(value: Int64): TVecI64x4;
function SSE2ZeroI64x4: TVecI64x4;

// ============================================================================
// ✅ NEW: U32x8 操作 (256-bit AVX2 仿真，使用 2×U32x4)
// ============================================================================
function SSE2AddU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2SubU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2MulU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2AndU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2OrU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2XorU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2NotU32x8(const a: TVecU32x8): TVecU32x8;
function SSE2AndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2ShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
function SSE2ShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
function SSE2CmpEqU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpLtU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpGtU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpLeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpGeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpNeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2MinU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2MaxU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2SplatU32x8(value: UInt32): TVecU32x8;

// ============================================================================
// ✅ NEW: U64x4 操作 (256-bit AVX2 仿真，使用 2×U64x2)
// ============================================================================
function SSE2AddU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2SubU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2AndU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2OrU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2XorU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2NotU64x4(const a: TVecU64x4): TVecU64x4;
function SSE2ShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
function SSE2ShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
function SSE2CmpEqU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpLtU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpGtU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpLeU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpGeU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpNeU64x4(const a, b: TVecU64x4): TMask4;

// ============================================================================
// ✅ NEW: I64x8 操作 (512-bit AVX-512 仿真，使用 4×I64x2 或 2×I64x4)
// ============================================================================
function SSE2AddI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2SubI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2AndI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2OrI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2XorI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2NotI64x8(const a: TVecI64x8): TVecI64x8;
function SSE2ShiftLeftI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
function SSE2ShiftRightI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
function SSE2CmpEqI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpLtI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpGtI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpLeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpGeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpNeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2LoadI64x8(p: PInt64): TVecI64x8;
procedure SSE2StoreI64x8(p: PInt64; const a: TVecI64x8);
function SSE2SplatI64x8(value: Int64): TVecI64x8;
function SSE2ZeroI64x8: TVecI64x8;

// ============================================================================
// ✅ NEW: Extract/Insert 操作 (通过数组索引实现)
// ============================================================================
// F64x2
function SSE2ExtractF64x2(const a: TVecF64x2; index: Integer): Double;
function SSE2InsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
// I32x4
function SSE2ExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
function SSE2InsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
// I64x2
function SSE2ExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
function SSE2InsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
// F32x8
function SSE2ExtractF32x8(const a: TVecF32x8; index: Integer): Single;
function SSE2InsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
// F64x4
function SSE2ExtractF64x4(const a: TVecF64x4; index: Integer): Double;
function SSE2InsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
// I32x8
function SSE2ExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
function SSE2InsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
// I64x4
function SSE2ExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
function SSE2InsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
// F32x16
function SSE2ExtractF32x16(const a: TVecF32x16; index: Integer): Single;
function SSE2InsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
// I32x16
function SSE2ExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
function SSE2InsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;

// ============================================================================
// ✅ NEW: Facade 函数 (高级内存和文本操作)
// ============================================================================
function MemDiffRange_SSE2(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemReverse_SSE2(p: Pointer; len: SizeUInt);
procedure ToLowerAscii_SSE2(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_SSE2(p: Pointer; len: SizeUInt);
function AsciiIEqual_SSE2(a, b: Pointer; len: SizeUInt): Boolean;
function BytesIndexOf_SSE2(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
function Utf8Validate_SSE2(p: Pointer; len: SizeUInt): Boolean;

implementation

uses
  SysUtils,
  Math,  // RTL Math 单元
  fafafa.core.simd.cpuinfo;

// === SSE2 Arithmetic Operations ===
// Note: FPC x86-64 calling convention:
//   - First 6 integer/pointer args: RDI, RSI, RDX, RCX, R8, R9
//   - Float args: XMM0-XMM7
//   - Result pointer for large structs: hidden first arg in RDI
//   - For const record params, pointer is passed

function SSE2AddF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    addps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2SubF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    subps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2MulF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    mulps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2DivF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    divps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2AddF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    addpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2SubF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    subpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2MulF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    mulpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2DivF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    divpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// F64x2 Math Operations (SSE2)
// ============================================================================

function SSE2SqrtF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    sqrtpd xmm0, xmm0
    movupd [rcx], xmm0
  end;
end;

function SSE2MinF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    minpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2MaxF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    maxpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2AbsF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
const
  SignMask: array[0..1] of UInt64 = ($7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rip + SignMask]
    andpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// F64x2 Comparison Operations (SSE2)
// ============================================================================

function SSE2CmpEqF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpeqpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpLtF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpltpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpLeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmplepd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpGtF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GT: a > b is same as b < a
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rdx]  // load b
    movupd xmm1, [rax]  // load a
    cmpltpd xmm0, xmm1  // b < a
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpGeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as b <= a
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rdx]  // load b
    movupd xmm1, [rax]  // load a
    cmplepd xmm0, xmm1  // b <= a
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpNeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpneqpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// ============================================================================
// F64x2 Utility Operations (SSE2)
// ============================================================================

function SSE2LoadF64x2(p: PDouble): TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, p
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd [rcx], xmm0
  end;
end;

function SSE2SplatF64x2(value: Double): TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    movlpd xmm0, value
    unpcklpd xmm0, xmm0  // duplicate to both lanes
    mov    rcx, pr
    movupd [rcx], xmm0
  end;
end;

function SSE2ZeroF64x2: TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rcx, pr
    xorpd  xmm0, xmm0
    movupd [rcx], xmm0
  end;
end;

procedure SSE2StoreF64x2(p: PDouble; const v: TVecF64x2);
var
  pv: Pointer;
begin
  pv := @v;
  asm
    mov    rax, pv
    mov    rcx, p
    movupd xmm0, [rax]
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Bitwise Operations (SSE2)
// ============================================================================

function SSE2AndI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI32x4(const a: TVecI32x4): TVecI32x4;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..3] of UInt32 = ($FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // PANDN: dest = (NOT a) AND b
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Shift Operations (SSE2)
// ============================================================================

function SSE2ShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    pslld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Logical right shift (unsigned)
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Arithmetic right shift (signed, preserves sign bit)
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrad  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Comparison Operations (SSE2)
// ============================================================================

function SSE2CmpEqI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpgtd xmm0, xmm1
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LT: a < b is same as b > a
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rdx]  // load b
    movdqu xmm1, [rax]  // load a
    pcmpgtd xmm0, xmm1  // b > a
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

// SSE2 does not have LE/GE/NE directly, but we can derive them
function SSE2CmpLeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpgtd xmm0, xmm1      // a > b
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(a > b)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rdx]      // load b
    movdqu xmm1, [rax]      // load a
    pcmpgtd xmm0, xmm1      // b > a
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(b > a)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpNeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: NOT(a == b)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1      // a == b
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(a == b)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

// ============================================================================
// I32x4 Min/Max Operations (SSE2 emulation - no native instruction)
// Note: SSE4.1 has PMINSD/PMAXSD, but SSE2 needs emulation
// ============================================================================

function SSE2MinI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // min(a,b) = (a < b) ? a : b = blend(b, a, a < b)
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm1       // copy b
    pcmpgtd xmm2, xmm0      // b > a (i.e., a < b)
    // mask in xmm2: all 1s where a < b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2MaxI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // max(a,b) = (a > b) ? a : b = blend(b, a, a > b)
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm0       // copy a
    pcmpgtd xmm2, xmm1      // a > b
    // mask in xmm2: all 1s where a > b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2AddI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubd  xmm0, xmm1
    movdqu [rcx], xmm0
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

// ============================================================================
// I16x8 Operations (SSE2)
// ============================================================================

function SSE2AddI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddw  xmm0, xmm1    // 16-bit integer add
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubw  xmm0, xmm1    // 16-bit integer sub
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmullw xmm0, xmm1    // 16-bit integer multiply (low part)
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI16x8(const a: TVecI16x8): TVecI16x8;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..7] of UInt16 = ($FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1    // (NOT a) AND b
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psllw  xmm0, xmm1    // 16-bit logical shift left
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrlw  xmm0, xmm1    // 16-bit logical shift right
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psraw  xmm0, xmm1    // 16-bit arithmetic shift right
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // 16-bit compare equal
    pmovmskb eax, xmm0     // extract mask
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpLtI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm1, xmm0    // b > a (i.e., a < b)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGtI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm0, xmm1    // a > b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for I16x8 using NOT + base comparison
function SSE2CmpLeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm0, xmm1    // a > b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm1, xmm0    // b > a (i.e., a < b)
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm1, xmm2    // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpNeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // a == b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2MinI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminsw xmm0, xmm1    // SSE2 has PMINSW for signed 16-bit
    movdqu [rcx], xmm0
  end;
end;

function SSE2MaxI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxsw xmm0, xmm1    // SSE2 has PMAXSW for signed 16-bit
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I8x16 Operations (SSE2)
// ============================================================================

function SSE2AddI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddb  xmm0, xmm1    // 8-bit integer add
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubb  xmm0, xmm1    // 8-bit integer sub
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI8x16(const a: TVecI8x16): TVecI8x16;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..15] of Byte = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
                                    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1    // (NOT a) AND b
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // 8-bit compare equal
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpLtI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm1, xmm0    // b > a (i.e., a < b)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGtI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm0, xmm1    // a > b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for I8x16 using NOT + base comparison
function SSE2CmpLeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm0, xmm1    // a > b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm1, xmm0    // b > a (i.e., a < b)
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm1, xmm2    // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpNeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // a == b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2MinI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // SSE2 doesn't have PMINSB (SSE4.1), so we emulate with compare+blend
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm1       // copy b
    pcmpgtb xmm2, xmm0      // b > a (i.e., a < b)
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2MaxI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // SSE2 doesn't have PMAXSB (SSE4.1), so we emulate with compare+blend
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm0       // copy a
    pcmpgtb xmm2, xmm1      // a > b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

// ============================================================================
// U32x4 Operations (SSE2)
// ============================================================================

function SSE2AddU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // ✅ SSE2 32位乘法模拟 (无 PMULLD)
  // 使用 pmuludq + psrldq + pshufd + punpckldq 标准方法
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr

    movdqu xmm0, [rax]       // a
    movdqu xmm1, [rdx]       // b
    movdqa xmm2, xmm0        // 备份 a
    movdqa xmm3, xmm1        // 备份 b

    // 第1步: 计算 a0*b0, a2*b2
    pmuludq xmm0, xmm1       // xmm0 = [a2*b2(64bit), a0*b0(64bit)]

    // 第2步: 计算 a1*b1, a3*b3 (右移4字节取奇数元素)
    psrldq  xmm2, 4          // xmm2 = [0, a3, a2, a1]
    psrldq  xmm3, 4          // xmm3 = [0, b3, b2, b1]
    pmuludq xmm2, xmm3       // xmm2 = [a3*b3(64bit), a1*b1(64bit)]

    // 第3步: Shuffle 提取低32位乘积
    pshufd xmm0, xmm0, $08   // xmm0 = [a0*b0_L, a0*b0_L, a2*b2_L, a0*b0_L]
    pshufd xmm2, xmm2, $08   // xmm2 = [a1*b1_L, a1*b1_L, a3*b3_L, a1*b1_L]

    // 第4步: Unpack 交织结果
    punpckldq xmm0, xmm2     // xmm0 = [a1*b1_L, a0*b0_L, a3*b3_L, a2*b2_L]? 顺序检查!

    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU32x4(const a: TVecU32x4): TVecU32x4;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..3] of UInt32 = ($FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    pslld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqd  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  // Unsigned compare: flip sign bit to use signed comparison
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtd  xmm1, xmm0       // signed(b) > signed(a)
    movmskps eax, xmm1
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  // Unsigned compare: flip sign bit to use signed comparison
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtd  xmm0, xmm1       // signed(a) > signed(b)
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

// CmpLeU32x4: a <= b = NOT(a > b)
function SSE2CmpLeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpGtU32x4(a, b))) and $F);
end;

// CmpGeU32x4: a >= b = NOT(a < b)
function SSE2CmpGeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpLtU32x4(a, b))) and $F);
end;

// CmpNeU32x4: a != b = NOT(a == b)
function SSE2CmpNeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpEqU32x4(a, b))) and $F);
end;

function SSE2MinU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned min: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtd xmm3, xmm2      // signed(b) > signed(a)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm3       // a & mask
    pandn  xmm3, xmm1       // b & ~mask
    por    xmm5, xmm3       // combine
    movdqu [rcx], xmm5
  end;
end;

function SSE2MaxU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned max: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtd xmm2, xmm3      // signed(a) > signed(b)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm5, xmm2       // combine
    movdqu [rcx], xmm5
  end;
end;

// ============================================================================
// U16x8 Operations (SSE2)
// ============================================================================

function SSE2AddU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmullw xmm0, xmm1    // Works for unsigned too (low 16 bits)
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU16x8(const a: TVecU16x8): TVecU16x8;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..7] of UInt16 = ($FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1       // xmm0 = (~a) & b
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psllw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrlw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpLtU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm1, xmm0       // signed(b) > signed(a)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGtU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm0, xmm1       // signed(a) > signed(b)
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for U16x8 using NOT + base comparison
function SSE2CmpLeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm0, xmm1       // signed(a) > signed(b) = unsigned(a) > unsigned(b)
    pcmpeqw  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm1, xmm0       // signed(b) > signed(a) = unsigned(a) < unsigned(b)
    pcmpeqw  xmm2, xmm2       // all ones
    pxor     xmm1, xmm2       // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpNeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // a == b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2MinU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned min: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtw xmm3, xmm2      // signed(b) > signed(a)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm3       // a & mask
    pandn  xmm3, xmm1       // b & ~mask
    por    xmm5, xmm3       // combine
    movdqu [rcx], xmm5
  end;
end;

function SSE2MaxU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned max: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtw xmm2, xmm3      // signed(a) > signed(b)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm5, xmm2       // combine
    movdqu [rcx], xmm5
  end;
end;

// ============================================================================
// U8x16 Operations (SSE2)
// ============================================================================

function SSE2AddU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddb  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubb  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU8x16(const a: TVecU8x16): TVecU8x16;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..15] of Byte = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
                                    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1       // xmm0 = (~a) & b
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpLtU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm1, xmm0       // signed(b) > signed(a)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGtU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm0, xmm1       // signed(a) > signed(b)
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for U8x16 using NOT + base comparison
function SSE2CmpLeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm0, xmm1       // signed(a) > signed(b) = unsigned(a) > unsigned(b)
    pcmpeqb  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm1, xmm0       // signed(b) > signed(a) = unsigned(a) < unsigned(b)
    pcmpeqb  xmm2, xmm2       // all ones
    pxor     xmm1, xmm2       // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpNeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // a == b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2MinU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminub xmm0, xmm1    // SSE2 has PMINUB for unsigned 8-bit
    movdqu [rcx], xmm0
  end;
end;

function SSE2MaxU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxub xmm0, xmm1    // SSE2 has PMAXUB for unsigned 8-bit
    movdqu [rcx], xmm0
  end;
end;

// === SSE2 Comparison Operations ===

function SSE2CmpEqF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpeqps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  // GT: swap operands and use LT
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  // GE: swap operands and use LE
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpNeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
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
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov     rax, pa
    mov     rdx, pr
    movups  xmm0, [rax]
    pcmpeqd xmm1, xmm1       // all 1s
    psrld   xmm1, 1          // shift right to get 0x7FFFFFFF
    andps   xmm0, xmm1
    movups  [rdx], xmm0
  end;
end;

function SSE2SqrtF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov    rax, pa
    mov    rdx, pr
    movups xmm0, [rax]
    sqrtps xmm0, xmm0
    movups [rdx], xmm0
  end;
end;

function SSE2MinF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    minps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2MaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    maxps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

// === SSE2 Reduction Operations ===

function SSE2ReduceAddF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pr: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2LoadF32x4: pointer is nil');
  pr := @Result;
  asm
    mov    rax, p
    mov    rdx, pr
    movups xmm0, [rax]
    movups [rdx], xmm0
  end;
end;

function SSE2LoadF32x4Aligned(p: PSingle): TVecF32x4;
var
  pr: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2LoadF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'SSE2LoadF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  pr := @Result;
  asm
    mov    rax, p
    mov    rdx, pr
    movaps xmm0, [rax]
    movups [rdx], xmm0
  end;
end;

procedure SSE2StoreF32x4(p: PSingle; const a: TVecF32x4);
var
  pa: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2StoreF32x4: pointer is nil');
  pa := @a;
  asm
    mov    rax, p
    mov    rdx, pa
    movups xmm0, [rdx]
    movups [rax], xmm0
  end;
end;

procedure SSE2StoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
var
  pa: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2StoreF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'SSE2StoreF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  pa := @a;
  asm
    mov    rax, p
    mov    rdx, pa
    movups xmm0, [rdx]
    movaps [rax], xmm0
  end;
end;

// === SSE2 Utility Operations ===

function SSE2SplatF32x4(value: Single): TVecF32x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, pr
    movss  xmm0, value
    shufps xmm0, xmm0, 0
    movups [rax], xmm0
  end;
end;

function SSE2ZeroF32x4: TVecF32x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, pr
    xorps  xmm0, xmm0
    movups [rax], xmm0
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

{$I fafafa.core.simd.sse2.f32x8_arith.inc}

{$I fafafa.core.simd.sse2.f32x8_compare.inc}

{$I fafafa.core.simd.sse2.memory.inc}

{$I fafafa.core.simd.sse2.ext_math.inc}

{$I fafafa.core.simd.sse2.vector_math.inc}

{$I fafafa.core.simd.sse2.facade_extra.inc}

{$I fafafa.core.simd.sse2.saturating.inc}

{$I fafafa.core.simd.sse2.i64x2_arith.inc}

{$I fafafa.core.simd.sse2.i64x2_compare.inc}

{$I fafafa.core.simd.sse2.mask.inc}

{$I fafafa.core.simd.sse2.select.inc}

// ============================================================================
// ✅ 512-bit 向量的 SSE2 渐进降级实现 (2026-02-05)
// 策略: 使用 2×256-bit 操作 (利用已有的 F32x8/F64x4/I32x8)
// ============================================================================

// === F32x16 操作 (16×Float32) ===
function SSE2AddF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2SubF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2MulF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2DivF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2AbsF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2SqrtF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2MinF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2MaxF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2FmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
function SSE2FloorF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2CeilF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2RoundF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2TruncF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2ClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
function SSE2ReduceAddF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMinF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMaxF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMulF32x16(const a: TVecF32x16): Single;
function SSE2LoadF32x16(p: PSingle): TVecF32x16;
procedure SSE2StoreF32x16(p: PSingle; const a: TVecF32x16);
function SSE2SplatF32x16(value: Single): TVecF32x16;
function SSE2ZeroF32x16: TVecF32x16;
function SSE2CmpEqF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpLtF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpLeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpGtF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpGeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpNeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2SelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;

// === F64x8 操作 (8×Float64) ===
function SSE2AddF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2SubF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2MulF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2DivF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2AbsF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2SqrtF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2MinF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2MaxF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2FmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
function SSE2FloorF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2CeilF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2RoundF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2TruncF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2ClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
function SSE2ReduceAddF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMinF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMaxF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMulF64x8(const a: TVecF64x8): Double;
function SSE2LoadF64x8(p: PDouble): TVecF64x8;
procedure SSE2StoreF64x8(p: PDouble; const a: TVecF64x8);
function SSE2SplatF64x8(value: Double): TVecF64x8;
function SSE2ZeroF64x8: TVecF64x8;
function SSE2CmpEqF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpLtF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpLeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpGtF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpGeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpNeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2SelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;

// ✅ NEW: 缺失的 Select 操作 (条件选择: mask[i] != 0 ? a[i] : b[i])
function SSE2SelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
function SSE2SelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
function SSE2SelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;

// === I32x16 操作 (16×Int32) ===
function SSE2AddI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2SubI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2MulI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2AndI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2OrI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2XorI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2NotI32x16(const a: TVecI32x16): TVecI32x16;
function SSE2AndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2ShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2ShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2ShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2CmpEqI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpLtI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpGtI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpLeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpGeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpNeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2MinI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2MaxI32x16(const a, b: TVecI32x16): TVecI32x16;

// ============================================================================
// ✅ NEW: I64x4 操作 (256-bit AVX2 仿真，使用 2×I64x2)
// ============================================================================
function SSE2AddI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2SubI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2AndI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2OrI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2XorI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2NotI64x4(const a: TVecI64x4): TVecI64x4;
function SSE2AndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2ShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
function SSE2ShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
function SSE2CmpEqI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpLtI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpGtI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpLeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpGeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpNeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2LoadI64x4(p: PInt64): TVecI64x4;
procedure SSE2StoreI64x4(p: PInt64; const a: TVecI64x4);
function SSE2SplatI64x4(value: Int64): TVecI64x4;
function SSE2ZeroI64x4: TVecI64x4;

// ============================================================================
// ✅ NEW: U32x8 操作 (256-bit AVX2 仿真，使用 2×U32x4)
// ============================================================================
function SSE2AddU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2SubU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2MulU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2AndU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2OrU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2XorU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2NotU32x8(const a: TVecU32x8): TVecU32x8;
function SSE2AndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2ShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
function SSE2ShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
function SSE2CmpEqU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpLtU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpGtU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpLeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpGeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpNeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2MinU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2MaxU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2SplatU32x8(value: UInt32): TVecU32x8;

// ============================================================================
// ✅ NEW: U64x4 操作 (256-bit AVX2 仿真，使用 2×U64x2)
// ============================================================================
function SSE2AddU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2SubU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2AndU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2OrU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2XorU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2NotU64x4(const a: TVecU64x4): TVecU64x4;
function SSE2ShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
function SSE2ShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
function SSE2CmpEqU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpLtU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpGtU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpLeU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpGeU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpNeU64x4(const a, b: TVecU64x4): TMask4;

// ============================================================================
// ✅ NEW: I64x8 操作 (512-bit AVX-512 仿真，使用 4×I64x2 或 2×I64x4)
// ============================================================================
function SSE2AddI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2SubI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2AndI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2OrI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2XorI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2NotI64x8(const a: TVecI64x8): TVecI64x8;
function SSE2ShiftLeftI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
function SSE2ShiftRightI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
function SSE2CmpEqI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpLtI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpGtI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpLeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpGeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpNeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2LoadI64x8(p: PInt64): TVecI64x8;
procedure SSE2StoreI64x8(p: PInt64; const a: TVecI64x8);
function SSE2SplatI64x8(value: Int64): TVecI64x8;
function SSE2ZeroI64x8: TVecI64x8;

// ============================================================================
// ✅ NEW: Extract/Insert 操作 (通过数组索引实现)
// ============================================================================
// F64x2
function SSE2ExtractF64x2(const a: TVecF64x2; index: Integer): Double;
function SSE2InsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
// I32x4
function SSE2ExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
function SSE2InsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
// I64x2
function SSE2ExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
function SSE2InsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
// F32x8
function SSE2ExtractF32x8(const a: TVecF32x8; index: Integer): Single;
function SSE2InsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
// F64x4
function SSE2ExtractF64x4(const a: TVecF64x4; index: Integer): Double;
function SSE2InsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
// I32x8
function SSE2ExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
function SSE2InsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
// I64x4
function SSE2ExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
function SSE2InsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
// F32x16
function SSE2ExtractF32x16(const a: TVecF32x16; index: Integer): Single;
function SSE2InsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
// I32x16
function SSE2ExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
function SSE2InsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;

// ============================================================================
// ✅ NEW: Facade 函数 (高级内存和文本操作)
// ============================================================================
function MemDiffRange_SSE2(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemReverse_SSE2(p: Pointer; len: SizeUInt);
procedure ToLowerAscii_SSE2(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_SSE2(p: Pointer; len: SizeUInt);
function AsciiIEqual_SSE2(a, b: Pointer; len: SizeUInt): Boolean;
function BytesIndexOf_SSE2(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
function Utf8Validate_SSE2(p: Pointer; len: SizeUInt): Boolean;

implementation

uses
  SysUtils,
  Math,  // RTL Math 单元
  fafafa.core.simd.cpuinfo;

// === SSE2 Arithmetic Operations ===
// Note: FPC x86-64 calling convention:
//   - First 6 integer/pointer args: RDI, RSI, RDX, RCX, R8, R9
//   - Float args: XMM0-XMM7
//   - Result pointer for large structs: hidden first arg in RDI
//   - For const record params, pointer is passed

function SSE2AddF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    addps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2SubF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    subps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2MulF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    mulps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2DivF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    divps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2AddF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    addpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2SubF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    subpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2MulF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    mulpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2DivF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    divpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// F64x2 Math Operations (SSE2)
// ============================================================================

function SSE2SqrtF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    sqrtpd xmm0, xmm0
    movupd [rcx], xmm0
  end;
end;

function SSE2MinF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    minpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2MaxF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    maxpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2AbsF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
const
  SignMask: array[0..1] of UInt64 = ($7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rip + SignMask]
    andpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// F64x2 Comparison Operations (SSE2)
// ============================================================================

function SSE2CmpEqF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpeqpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpLtF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpltpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpLeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmplepd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpGtF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GT: a > b is same as b < a
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rdx]  // load b
    movupd xmm1, [rax]  // load a
    cmpltpd xmm0, xmm1  // b < a
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpGeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as b <= a
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rdx]  // load b
    movupd xmm1, [rax]  // load a
    cmplepd xmm0, xmm1  // b <= a
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpNeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpneqpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// ============================================================================
// F64x2 Utility Operations (SSE2)
// ============================================================================

function SSE2LoadF64x2(p: PDouble): TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, p
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd [rcx], xmm0
  end;
end;

function SSE2SplatF64x2(value: Double): TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    movlpd xmm0, value
    unpcklpd xmm0, xmm0  // duplicate to both lanes
    mov    rcx, pr
    movupd [rcx], xmm0
  end;
end;

function SSE2ZeroF64x2: TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rcx, pr
    xorpd  xmm0, xmm0
    movupd [rcx], xmm0
  end;
end;

procedure SSE2StoreF64x2(p: PDouble; const v: TVecF64x2);
var
  pv: Pointer;
begin
  pv := @v;
  asm
    mov    rax, pv
    mov    rcx, p
    movupd xmm0, [rax]
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Bitwise Operations (SSE2)
// ============================================================================

function SSE2AndI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI32x4(const a: TVecI32x4): TVecI32x4;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..3] of UInt32 = ($FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // PANDN: dest = (NOT a) AND b
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Shift Operations (SSE2)
// ============================================================================

function SSE2ShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    pslld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Logical right shift (unsigned)
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Arithmetic right shift (signed, preserves sign bit)
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrad  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Comparison Operations (SSE2)
// ============================================================================

function SSE2CmpEqI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpgtd xmm0, xmm1
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LT: a < b is same as b > a
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rdx]  // load b
    movdqu xmm1, [rax]  // load a
    pcmpgtd xmm0, xmm1  // b > a
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

// SSE2 does not have LE/GE/NE directly, but we can derive them
function SSE2CmpLeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpgtd xmm0, xmm1      // a > b
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(a > b)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rdx]      // load b
    movdqu xmm1, [rax]      // load a
    pcmpgtd xmm0, xmm1      // b > a
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(b > a)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpNeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: NOT(a == b)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1      // a == b
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(a == b)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

// ============================================================================
// I32x4 Min/Max Operations (SSE2 emulation - no native instruction)
// Note: SSE4.1 has PMINSD/PMAXSD, but SSE2 needs emulation
// ============================================================================

function SSE2MinI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // min(a,b) = (a < b) ? a : b = blend(b, a, a < b)
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm1       // copy b
    pcmpgtd xmm2, xmm0      // b > a (i.e., a < b)
    // mask in xmm2: all 1s where a < b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2MaxI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // max(a,b) = (a > b) ? a : b = blend(b, a, a > b)
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm0       // copy a
    pcmpgtd xmm2, xmm1      // a > b
    // mask in xmm2: all 1s where a > b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2AddI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubd  xmm0, xmm1
    movdqu [rcx], xmm0
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

// ============================================================================
// I16x8 Operations (SSE2)
// ============================================================================

function SSE2AddI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddw  xmm0, xmm1    // 16-bit integer add
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubw  xmm0, xmm1    // 16-bit integer sub
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmullw xmm0, xmm1    // 16-bit integer multiply (low part)
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI16x8(const a: TVecI16x8): TVecI16x8;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..7] of UInt16 = ($FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1    // (NOT a) AND b
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psllw  xmm0, xmm1    // 16-bit logical shift left
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrlw  xmm0, xmm1    // 16-bit logical shift right
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psraw  xmm0, xmm1    // 16-bit arithmetic shift right
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // 16-bit compare equal
    pmovmskb eax, xmm0     // extract mask
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpLtI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm1, xmm0    // b > a (i.e., a < b)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGtI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm0, xmm1    // a > b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for I16x8 using NOT + base comparison
function SSE2CmpLeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm0, xmm1    // a > b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm1, xmm0    // b > a (i.e., a < b)
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm1, xmm2    // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpNeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // a == b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2MinI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminsw xmm0, xmm1    // SSE2 has PMINSW for signed 16-bit
    movdqu [rcx], xmm0
  end;
end;

function SSE2MaxI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxsw xmm0, xmm1    // SSE2 has PMAXSW for signed 16-bit
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I8x16 Operations (SSE2)
// ============================================================================

function SSE2AddI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddb  xmm0, xmm1    // 8-bit integer add
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubb  xmm0, xmm1    // 8-bit integer sub
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI8x16(const a: TVecI8x16): TVecI8x16;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..15] of Byte = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
                                    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1    // (NOT a) AND b
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // 8-bit compare equal
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpLtI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm1, xmm0    // b > a (i.e., a < b)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGtI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm0, xmm1    // a > b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for I8x16 using NOT + base comparison
function SSE2CmpLeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm0, xmm1    // a > b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm1, xmm0    // b > a (i.e., a < b)
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm1, xmm2    // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpNeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // a == b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2MinI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // SSE2 doesn't have PMINSB (SSE4.1), so we emulate with compare+blend
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm1       // copy b
    pcmpgtb xmm2, xmm0      // b > a (i.e., a < b)
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2MaxI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // SSE2 doesn't have PMAXSB (SSE4.1), so we emulate with compare+blend
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm0       // copy a
    pcmpgtb xmm2, xmm1      // a > b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

// ============================================================================
// U32x4 Operations (SSE2)
// ============================================================================

function SSE2AddU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // ✅ SSE2 32位乘法模拟 (无 PMULLD)
  // 使用 pmuludq + psrldq + pshufd + punpckldq 标准方法
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr

    movdqu xmm0, [rax]       // a
    movdqu xmm1, [rdx]       // b
    movdqa xmm2, xmm0        // 备份 a
    movdqa xmm3, xmm1        // 备份 b

    // 第1步: 计算 a0*b0, a2*b2
    pmuludq xmm0, xmm1       // xmm0 = [a2*b2(64bit), a0*b0(64bit)]

    // 第2步: 计算 a1*b1, a3*b3 (右移4字节取奇数元素)
    psrldq  xmm2, 4          // xmm2 = [0, a3, a2, a1]
    psrldq  xmm3, 4          // xmm3 = [0, b3, b2, b1]
    pmuludq xmm2, xmm3       // xmm2 = [a3*b3(64bit), a1*b1(64bit)]

    // 第3步: Shuffle 提取低32位乘积
    pshufd xmm0, xmm0, $08   // xmm0 = [a0*b0_L, a0*b0_L, a2*b2_L, a0*b0_L]
    pshufd xmm2, xmm2, $08   // xmm2 = [a1*b1_L, a1*b1_L, a3*b3_L, a1*b1_L]

    // 第4步: Unpack 交织结果
    punpckldq xmm0, xmm2     // xmm0 = [a1*b1_L, a0*b0_L, a3*b3_L, a2*b2_L]? 顺序检查!

    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU32x4(const a: TVecU32x4): TVecU32x4;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..3] of UInt32 = ($FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    pslld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqd  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  // Unsigned compare: flip sign bit to use signed comparison
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtd  xmm1, xmm0       // signed(b) > signed(a)
    movmskps eax, xmm1
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  // Unsigned compare: flip sign bit to use signed comparison
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtd  xmm0, xmm1       // signed(a) > signed(b)
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

// CmpLeU32x4: a <= b = NOT(a > b)
function SSE2CmpLeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpGtU32x4(a, b))) and $F);
end;

// CmpGeU32x4: a >= b = NOT(a < b)
function SSE2CmpGeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpLtU32x4(a, b))) and $F);
end;

// CmpNeU32x4: a != b = NOT(a == b)
function SSE2CmpNeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpEqU32x4(a, b))) and $F);
end;

function SSE2MinU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned min: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtd xmm3, xmm2      // signed(b) > signed(a)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm3       // a & mask
    pandn  xmm3, xmm1       // b & ~mask
    por    xmm5, xmm3       // combine
    movdqu [rcx], xmm5
  end;
end;

function SSE2MaxU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned max: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtd xmm2, xmm3      // signed(a) > signed(b)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm5, xmm2       // combine
    movdqu [rcx], xmm5
  end;
end;

// ============================================================================
// U16x8 Operations (SSE2)
// ============================================================================

function SSE2AddU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmullw xmm0, xmm1    // Works for unsigned too (low 16 bits)
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU16x8(const a: TVecU16x8): TVecU16x8;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..7] of UInt16 = ($FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1       // xmm0 = (~a) & b
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psllw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrlw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpLtU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm1, xmm0       // signed(b) > signed(a)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGtU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm0, xmm1       // signed(a) > signed(b)
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for U16x8 using NOT + base comparison
function SSE2CmpLeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm0, xmm1       // signed(a) > signed(b) = unsigned(a) > unsigned(b)
    pcmpeqw  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm1, xmm0       // signed(b) > signed(a) = unsigned(a) < unsigned(b)
    pcmpeqw  xmm2, xmm2       // all ones
    pxor     xmm1, xmm2       // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpNeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // a == b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2MinU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned min: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtw xmm3, xmm2      // signed(b) > signed(a)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm3       // a & mask
    pandn  xmm3, xmm1       // b & ~mask
    por    xmm5, xmm3       // combine
    movdqu [rcx], xmm5
  end;
end;

function SSE2MaxU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned max: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtw xmm2, xmm3      // signed(a) > signed(b)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm5, xmm2       // combine
    movdqu [rcx], xmm5
  end;
end;

// ============================================================================
// U8x16 Operations (SSE2)
// ============================================================================

function SSE2AddU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddb  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubb  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU8x16(const a: TVecU8x16): TVecU8x16;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..15] of Byte = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
                                    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1       // xmm0 = (~a) & b
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpLtU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm1, xmm0       // signed(b) > signed(a)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGtU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm0, xmm1       // signed(a) > signed(b)
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for U8x16 using NOT + base comparison
function SSE2CmpLeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm0, xmm1       // signed(a) > signed(b) = unsigned(a) > unsigned(b)
    pcmpeqb  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm1, xmm0       // signed(b) > signed(a) = unsigned(a) < unsigned(b)
    pcmpeqb  xmm2, xmm2       // all ones
    pxor     xmm1, xmm2       // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpNeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // a == b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2MinU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminub xmm0, xmm1    // SSE2 has PMINUB for unsigned 8-bit
    movdqu [rcx], xmm0
  end;
end;

function SSE2MaxU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxub xmm0, xmm1    // SSE2 has PMAXUB for unsigned 8-bit
    movdqu [rcx], xmm0
  end;
end;

// === SSE2 Comparison Operations ===

function SSE2CmpEqF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpeqps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  // GT: swap operands and use LT
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  // GE: swap operands and use LE
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpNeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
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
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov     rax, pa
    mov     rdx, pr
    movups  xmm0, [rax]
    pcmpeqd xmm1, xmm1       // all 1s
    psrld   xmm1, 1          // shift right to get 0x7FFFFFFF
    andps   xmm0, xmm1
    movups  [rdx], xmm0
  end;
end;

function SSE2SqrtF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov    rax, pa
    mov    rdx, pr
    movups xmm0, [rax]
    sqrtps xmm0, xmm0
    movups [rdx], xmm0
  end;
end;

function SSE2MinF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    minps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2MaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    maxps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

// === SSE2 Reduction Operations ===

function SSE2ReduceAddF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
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
var
  pr: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2LoadF32x4: pointer is nil');
  pr := @Result;
  asm
    mov    rax, p
    mov    rdx, pr
    movups xmm0, [rax]
    movups [rdx], xmm0
  end;
end;

function SSE2LoadF32x4Aligned(p: PSingle): TVecF32x4;
var
  pr: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2LoadF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'SSE2LoadF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  pr := @Result;
  asm
    mov    rax, p
    mov    rdx, pr
    movaps xmm0, [rax]
    movups [rdx], xmm0
  end;
end;

procedure SSE2StoreF32x4(p: PSingle; const a: TVecF32x4);
var
  pa: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2StoreF32x4: pointer is nil');
  pa := @a;
  asm
    mov    rax, p
    mov    rdx, pa
    movups xmm0, [rdx]
    movups [rax], xmm0
  end;
end;

procedure SSE2StoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
var
  pa: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2StoreF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'SSE2StoreF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  pa := @a;
  asm
    mov    rax, p
    mov    rdx, pa
    movups xmm0, [rdx]
    movaps [rax], xmm0
  end;
end;

// === SSE2 Utility Operations ===

function SSE2SplatF32x4(value: Single): TVecF32x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, pr
    movss  xmm0, value
    shufps xmm0, xmm0, 0
    movups [rax], xmm0
  end;
end;

function SSE2ZeroF32x4: TVecF32x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, pr
    xorps  xmm0, xmm0
    movups [rax], xmm0
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

{$I fafafa.core.simd.sse2.f32x8_arith.inc}

{$I fafafa.core.simd.sse2.f32x8_compare.inc}

{$I fafafa.core.simd.sse2.memory.inc}

{$I fafafa.core.simd.sse2.ext_math.inc}

{$I fafafa.core.simd.sse2.vector_math.inc}

{$I fafafa.core.simd.sse2.facade_extra.inc}

{$I fafafa.core.simd.sse2.saturating.inc}

{$I fafafa.core.simd.sse2.i64x2_arith.inc}

{$I fafafa.core.simd.sse2.i64x2_compare.inc}

{$I fafafa.core.simd.sse2.mask.inc}

// === ✅ P4: SelectF64x2 SIMD Implementation ===
// 使用 andpd/andnpd/orpd 实现手动混合 (blendvpd 需要 SSE4.1)
// mask 位 0 控制元素 0，位 1 控制元素 1
// 位为 1 时选择 a，位为 0 时选择 b
function SSE2SelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pm, pr: Pointer;
  expandedMask: TVecI64x2;
begin
  // 将 mask 扩展为 64-bit 掉码
  if (mask and 1) <> 0 then expandedMask.i[0] := Int64(-1) else expandedMask.i[0] := 0;
  if (mask and 2) <> 0 then expandedMask.i[1] := Int64(-1) else expandedMask.i[1] := 0;

  pa := @a;
  pb := @b;
  pm := @expandedMask;
  pr := @Result;

  // result = (a AND mask) OR (b AND NOT mask)
  asm
    mov   rax, pa
    mov   rdx, pb
    mov   rcx, pm
    mov   r8, pr

    movupd xmm0, [rax]     // a
    movupd xmm1, [rdx]     // b
    movdqu xmm2, [rcx]     // mask (expanded to 128-bit)

    andpd  xmm0, xmm2      // a AND mask
    andnpd xmm2, xmm1      // b AND (NOT mask)  (andnpd: ~src1 AND src2)
    orpd   xmm0, xmm2      // combine

    movupd [r8], xmm0
  end;
end;

// ✅ F64x2 扩展函数 (2026-02-05) - 用于构建 F64x4 分解实现

function SSE2FloorF64x2(const a: TVecF64x2): TVecF64x2;
begin
  // SSE2 没有 ROUNDPD，使用标量 Floor
  Result.d[0] := Floor(a.d[0]);
  Result.d[1] := Floor(a.d[1]);
end;

function SSE2CeilF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Ceil(a.d[0]);
  Result.d[1] := Ceil(a.d[1]);
end;

function SSE2RoundF64x2(const a: TVecF64x2): TVecF64x2;
var
  LBits: QWord;
begin
  LBits := 0;
  if IsNan(a.d[0]) or IsInfinite(a.d[0]) then
    Result.d[0] := a.d[0]
  else
  begin
    Result.d[0] := Round(a.d[0]);
    if Result.d[0] = 0.0 then
    begin
      Move(a.d[0], LBits, SizeOf(LBits));
      if (LBits and QWord($8000000000000000)) <> 0 then
        Result.d[0] := -0.0;
    end;
  end;

  if IsNan(a.d[1]) or IsInfinite(a.d[1]) then
    Result.d[1] := a.d[1]
  else
  begin
    Result.d[1] := Round(a.d[1]);
    if Result.d[1] = 0.0 then
    begin
      Move(a.d[1], LBits, SizeOf(LBits));
      if (LBits and QWord($8000000000000000)) <> 0 then
        Result.d[1] := -0.0;
    end;
  end;
end;

function SSE2TruncF64x2(const a: TVecF64x2): TVecF64x2;
var
  LBits: QWord;
begin
  LBits := 0;
  if IsNan(a.d[0]) or IsInfinite(a.d[0]) then
    Result.d[0] := a.d[0]
  else
  begin
    Result.d[0] := Trunc(a.d[0]);
    if Result.d[0] = 0.0 then
    begin
      Move(a.d[0], LBits, SizeOf(LBits));
      if (LBits and QWord($8000000000000000)) <> 0 then
        Result.d[0] := -0.0;
    end;
  end;

  if IsNan(a.d[1]) or IsInfinite(a.d[1]) then
    Result.d[1] := a.d[1]
  else
  begin
    Result.d[1] := Trunc(a.d[1]);
    if Result.d[1] = 0.0 then
    begin
      Move(a.d[1], LBits, SizeOf(LBits));
      if (LBits and QWord($8000000000000000)) <> 0 then
        Result.d[1] := -0.0;
    end;
  end;
end;

function SSE2FmaF64x2(const a, b, c: TVecF64x2): TVecF64x2;
begin
  // FMA: a * b + c，SSE2 没有 FMA 指令，用乘加分离
  Result.d[0] := a.d[0] * b.d[0] + c.d[0];
  Result.d[1] := a.d[1] * b.d[1] + c.d[1];
end;

function SSE2ClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2;
begin
  Result := SSE2MaxF64x2(SSE2MinF64x2(a, maxVal), minVal);
end;

function SSE2ReduceAddF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] + a.d[1];
end;

function SSE2ReduceMinF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] < a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function SSE2ReduceMaxF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] > a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function SSE2ReduceMulF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] * a.d[1];
end;

// ✅ F64x4 分解实现 (2026-02-05) - 使用 2x F64x2

// ✅ SIMD Quality Iteration 4.4: F64x4 2×128-bit SSE2 ASM 实现
function SSE2AddF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    addpd  xmm0, xmm2
    addpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AddF64x2(a.lo, b.lo);
  Result.hi := SSE2AddF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2SubF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    subpd  xmm0, xmm2
    subpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SubF64x2(a.lo, b.lo);
  Result.hi := SSE2SubF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MulF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    mulpd  xmm0, xmm2
    mulpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MulF64x2(a.lo, b.lo);
  Result.hi := SSE2MulF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2DivF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    divpd  xmm0, xmm2
    divpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2DivF64x2(a.lo, b.lo);
  Result.hi := SSE2DivF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2FmaF64x4(const a, b, c: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pc, pr: Pointer;
begin
  pa := @a; pb := @b; pc := @c; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    r8,  pc
    mov    rcx, pr
    // Load a
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Load b
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    // Multiply a * b
    mulpd  xmm0, xmm2
    mulpd  xmm1, xmm3
    // Load c
    movupd xmm4, [r8]
    movupd xmm5, [r8+16]
    // Add c
    addpd  xmm0, xmm4
    addpd  xmm1, xmm5
    // Store
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2FmaF64x2(a.lo, b.lo, c.lo);
  Result.hi := SSE2FmaF64x2(a.hi, b.hi, c.hi);
{$ENDIF}
end;

// Reciprocal: 1.0 / a
function SSE2RcpF64x4(const a: TVecF64x4): TVecF64x4;
var
  one: TVecF64x2;
begin
  one := SSE2SplatF64x2(1.0);
  Result.lo := SSE2DivF64x2(one, a.lo);
  Result.hi := SSE2DivF64x2(one, a.hi);
end;

// ✅ SIMD Quality Iteration 6.3: F64x4 舍入操作 SSE2 ASM 实现
function SSE2FloorF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
  LIndex: Integer;
const
  OneDouble: array[0..1] of Double = (1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 2 个 double
    movupd xmm0, [rax]
    // 加载高 2 个 double
    movupd xmm4, [rax+16]

    // === 处理低 2 个元素 (xmm0) ===
    // 保存原值
    movapd xmm1, xmm0
    // 截断转整数 (SSE2 cvttpd2dq 转换 2 个 double 到 2 个 int32)
    cvttpd2dq xmm0, xmm0
    // 转回浮点 (cvtdq2pd 将 2 个 int32 转为 2 个 double)
    cvtdq2pd xmm0, xmm0
    // 比较: 原值 < 截断值？
    movapd xmm2, xmm1
    cmpltpd xmm2, xmm0
    // 加载 1.0
    movupd xmm3, [rip + OneDouble]
    // 掩码 & 1.0
    andpd  xmm2, xmm3
    // 减去修正值
    subpd  xmm0, xmm2

    // === 处理高 2 个元素 (xmm4) ===
    // 保存原值
    movapd xmm5, xmm4
    // 截断转整数
    cvttpd2dq xmm4, xmm4
    // 转回浮点
    cvtdq2pd xmm4, xmm4
    // 比较: 原值 < 截断值？
    movapd xmm6, xmm5
    cmpltpd xmm6, xmm4
    // 掩码 & 1.0
    andpd  xmm6, xmm3
    // 减去修正值
    subpd  xmm4, xmm6

    // 保存结果
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
  end;
{$ELSE}
var
  LIndex: Integer;
begin
  Result.lo := SSE2FloorF64x2(a.lo);
  Result.hi := SSE2FloorF64x2(a.hi);
{$ENDIF}
  for LIndex := 0 to 3 do
    if IsNan(a.d[LIndex]) or IsInfinite(a.d[LIndex]) then
      Result.d[LIndex] := a.d[LIndex];
end;

function SSE2CeilF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
  LIndex: Integer;
const
  OneDouble: array[0..1] of Double = (1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 2 个 double
    movupd xmm0, [rax]
    // 加载高 2 个 double
    movupd xmm4, [rax+16]

    // === 处理低 2 个元素 (xmm0) ===
    // 保存原值
    movapd xmm1, xmm0
    // 截断转整数
    cvttpd2dq xmm0, xmm0
    // 转回浮点
    cvtdq2pd xmm0, xmm0
    // 比较: 截断值 < 原值？
    cmpltpd xmm0, xmm1
    // 加载 1.0
    movupd xmm3, [rip + OneDouble]
    // 掩码 & 1.0
    andpd  xmm0, xmm3
    // 重新加载截断值
    movapd xmm2, xmm1
    cvttpd2dq xmm2, xmm2
    cvtdq2pd xmm2, xmm2
    // 加上修正值
    addpd  xmm0, xmm2

    // === 处理高 2 个元素 (xmm4) ===
    // 保存原值
    movapd xmm5, xmm4
    // 截断转整数
    cvttpd2dq xmm4, xmm4
    // 转回浮点
    cvtdq2pd xmm4, xmm4
    // 比较: 截断值 < 原值？
    cmpltpd xmm4, xmm5
    // 掩码 & 1.0
    andpd  xmm4, xmm3
    // 重新加载截断值
    movapd xmm6, xmm5
    cvttpd2dq xmm6, xmm6
    cvtdq2pd xmm6, xmm6
    // 加上修正值
    addpd  xmm4, xmm6

    // 保存结果
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
  end;
{$ELSE}
var
  LIndex: Integer;
begin
  Result.lo := SSE2CeilF64x2(a.lo);
  Result.hi := SSE2CeilF64x2(a.hi);
{$ENDIF}
  for LIndex := 0 to 3 do
    if IsNan(a.d[LIndex]) or IsInfinite(a.d[LIndex]) then
      Result.d[LIndex] := a.d[LIndex];
end;

function SSE2RoundF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result.lo := SSE2RoundF64x2(a.lo);
  Result.hi := SSE2RoundF64x2(a.hi);
end;

function SSE2TruncF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result.lo := SSE2TruncF64x2(a.lo);
  Result.hi := SSE2TruncF64x2(a.hi);
end;

function SSE2AbsF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Create sign mask for double (0x7FFFFFFFFFFFFFFF)
    pcmpeqd xmm2, xmm2       // all 1s
    psrlq   xmm2, 1          // clear sign bit (64-bit)
    movapd  xmm3, xmm2
    // Clear sign bits
    andpd   xmm0, xmm2
    andpd   xmm1, xmm3
    movupd  [rcx], xmm0
    movupd  [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AbsF64x2(a.lo);
  Result.hi := SSE2AbsF64x2(a.hi);
{$ENDIF}
end;

function SSE2SqrtF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    sqrtpd xmm0, xmm0
    sqrtpd xmm1, xmm1
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SqrtF64x2(a.lo);
  Result.hi := SSE2SqrtF64x2(a.hi);
{$ENDIF}
end;

function SSE2MinF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    minpd  xmm0, xmm2
    minpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MinF64x2(a.lo, b.lo);
  Result.hi := SSE2MinF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MaxF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    maxpd  xmm0, xmm2
    maxpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MaxF64x2(a.lo, b.lo);
  Result.hi := SSE2MaxF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2ClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pmin, pmax, pr: Pointer;
begin
  pa := @a; pmin := @minVal; pmax := @maxVal; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pmin
    mov    r8,  pmax
    mov    rcx, pr
    // Load a
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Load minVal
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    // Max with minVal
    maxpd  xmm0, xmm2
    maxpd  xmm1, xmm3
    // Load maxVal
    movupd xmm4, [r8]
    movupd xmm5, [r8+16]
    // Min with maxVal
    minpd  xmm0, xmm4
    minpd  xmm1, xmm5
    // Store
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ClampF64x2(a.lo, minVal.lo, maxVal.lo);
  Result.hi := SSE2ClampF64x2(a.hi, minVal.hi, maxVal.hi);
{$ENDIF}
end;

function SSE2ReduceAddF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge lo + hi
    addpd  xmm0, xmm1
    // Horizontal add for 2 doubles
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1      // swap high/low double
    addpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceAddF64x2(a.lo) + SSE2ReduceAddF64x2(a.hi);
{$ENDIF}
end;

function SSE2ReduceMinF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge with min
    minpd  xmm0, xmm1
    // Horizontal min
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1
    minpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Double;
begin
  lo := SSE2ReduceMinF64x2(a.lo);
  hi := SSE2ReduceMinF64x2(a.hi);
  if lo < hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMaxF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge with max
    maxpd  xmm0, xmm1
    // Horizontal max
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1
    maxpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Double;
begin
  lo := SSE2ReduceMaxF64x2(a.lo);
  hi := SSE2ReduceMaxF64x2(a.hi);
  if lo > hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMulF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge with mul
    mulpd  xmm0, xmm1
    // Horizontal mul
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1
    mulpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceMulF64x2(a.lo) * SSE2ReduceMulF64x2(a.hi);
{$ENDIF}
end;

function SSE2LoadF64x4(p: PDouble): TVecF64x4;
begin
  Result.lo := SSE2LoadF64x2(p);
  Result.hi := SSE2LoadF64x2(p + 2);
end;

procedure SSE2StoreF64x4(p: PDouble; const a: TVecF64x4);
begin
  SSE2StoreF64x2(p, a.lo);
  SSE2StoreF64x2(p + 2, a.hi);
end;

function SSE2SplatF64x4(value: Double): TVecF64x4;
begin
  Result.lo := SSE2SplatF64x2(value);
  Result.hi := SSE2SplatF64x2(value);
end;

function SSE2ZeroF64x4: TVecF64x4;
begin
  Result.lo := SSE2ZeroF64x2;
  Result.hi := SSE2ZeroF64x2;
end;

// ✅ F64x4 Comparison Operations (2×128-bit SSE2 ASM) - 2026-02-05

function SSE2CmpEqF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmpeqpd  xmm0, xmm1      // 比较 a.lo == b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmpeqpd  xmm0, xmm1      // 比较 a.hi == b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpEqF64x2(a.lo, b.lo)) or (Byte(SSE2CmpEqF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpLtF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmpltpd  xmm0, xmm1      // 比较 a.lo < b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmpltpd  xmm0, xmm1      // 比较 a.hi < b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpLtF64x2(a.lo, b.lo)) or (Byte(SSE2CmpLtF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpLeF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmplepd  xmm0, xmm1      // 比较 a.lo <= b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmplepd  xmm0, xmm1      // 比较 a.hi <= b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpLeF64x2(a.lo, b.lo)) or (Byte(SSE2CmpLeF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpGtF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // GT: a > b is same as b < a
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rdx]     // load b.lo
    movupd   xmm1, [rax]     // load a.lo
    cmpltpd  xmm0, xmm1      // 比较 b.lo < a.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rdx+16]  // load b.hi
    movupd   xmm1, [rax+16]  // load a.hi
    cmpltpd  xmm0, xmm1      // 比较 b.hi < a.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpGtF64x2(a.lo, b.lo)) or (Byte(SSE2CmpGtF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpGeF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as b <= a
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rdx]     // load b.lo
    movupd   xmm1, [rax]     // load a.lo
    cmplepd  xmm0, xmm1      // 比较 b.lo <= a.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rdx+16]  // load b.hi
    movupd   xmm1, [rax+16]  // load a.hi
    cmplepd  xmm0, xmm1      // 比较 b.hi <= a.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpGeF64x2(a.lo, b.lo)) or (Byte(SSE2CmpGeF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpNeF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmpneqpd xmm0, xmm1      // 比较 a.lo != b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmpneqpd xmm0, xmm1      // 比较 a.hi != b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpNeF64x2(a.lo, b.lo)) or (Byte(SSE2CmpNeF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

// ✅ I32x8 分解实现 (2026-02-05) - 使用 2x I32x4

// ✅ SIMD Quality Iteration 4.4: I32x8 2×128-bit SSE2 ASM 实现
function SSE2AddI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    paddd  xmm0, xmm2
    paddd  xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AddI32x4(a.lo, b.lo);
  Result.hi := SSE2AddI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2SubI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    psubd  xmm0, xmm2
    psubd  xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SubI32x4(a.lo, b.lo);
  Result.hi := SSE2SubI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MulI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result.lo := SSE2MulI32x4(a.lo, b.lo);
  Result.hi := SSE2MulI32x4(a.hi, b.hi);
end;

function SSE2AndI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    pand   xmm0, xmm2
    pand   xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AndI32x4(a.lo, b.lo);
  Result.hi := SSE2AndI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2OrI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    por    xmm0, xmm2
    por    xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2OrI32x4(a.lo, b.lo);
  Result.hi := SSE2OrI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2XorI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    pxor   xmm0, xmm2
    pxor   xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2XorI32x4(a.lo, b.lo);
  Result.hi := SSE2XorI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2NotI32x8(const a: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    // Create all 1s
    pcmpeqd xmm2, xmm2
    movdqa  xmm3, xmm2
    // XOR with all 1s = NOT
    pxor    xmm0, xmm2
    pxor    xmm1, xmm3
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2NotI32x4(a.lo);
  Result.hi := SSE2NotI32x4(a.hi);
{$ENDIF}
end;

function SSE2AndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    pandn  xmm0, xmm2
    pandn  xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AndNotI32x4(a.lo, b.lo);
  Result.hi := SSE2AndNotI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2ShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    pslld  xmm0, xmm2
    pslld  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ShiftLeftI32x4(a.lo, count);
  Result.hi := SSE2ShiftLeftI32x4(a.hi, count);
{$ENDIF}
end;

function SSE2ShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    psrld  xmm0, xmm2
    psrld  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ShiftRightI32x4(a.lo, count);
  Result.hi := SSE2ShiftRightI32x4(a.hi, count);
{$ENDIF}
end;

function SSE2ShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    psrad  xmm0, xmm2      // 算术右移（保留符号位）
    psrad  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ShiftRightArithI32x4(a.lo, count);
  Result.hi := SSE2ShiftRightArithI32x4(a.hi, count);
{$ENDIF}
end;

function SSE2CmpEqI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqd  xmm0, xmm1     // a.lo == b.lo
    movmskps eax, xmm0      // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpeqd  xmm0, xmm1     // a.hi == b.hi
    movmskps eax, xmm0      // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // LT: a < b is same as b > a
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rdx]      // load b.lo
    movdqu   xmm1, [rax]      // load a.lo
    pcmpgtd  xmm0, xmm1       // b.lo > a.lo
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rdx+16]   // load b.hi
    movdqu   xmm1, [rax+16]   // load a.hi
    pcmpgtd  xmm0, xmm1       // b.hi > a.hi
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtd  xmm0, xmm1       // a.lo > b.lo
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpgtd  xmm0, xmm1       // a.hi > b.hi
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtd  xmm0, xmm1       // a.lo > b.lo
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.lo > b.lo)
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpgtd  xmm0, xmm1       // a.hi > b.hi
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.hi > b.hi)
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rdx]      // load b.lo
    movdqu   xmm1, [rax]      // load a.lo
    pcmpgtd  xmm0, xmm1       // b.lo > a.lo
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(b.lo > a.lo)
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rdx+16]   // load b.hi
    movdqu   xmm1, [rax+16]   // load a.hi
    pcmpgtd  xmm0, xmm1       // b.hi > a.hi
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(b.hi > a.hi)
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpNeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // NE: NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqd  xmm0, xmm1       // a.lo == b.lo
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.lo == b.lo)
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpeqd  xmm0, xmm1       // a.hi == b.hi
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.hi == b.hi)
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2MinI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  // min(a,b) = (a < b) ? a : b = blend(b, a, a < b)
  // Process 2×128-bit using pcmpgtd + pand/pandn/por
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // First 128-bit (lo)
    movdqu xmm0, [rax]      // a.lo
    movdqu xmm1, [rdx]      // b.lo
    movdqa xmm2, xmm1       // copy b.lo
    pcmpgtd xmm2, xmm0      // b.lo > a.lo (i.e., a.lo < b.lo)
    movdqa xmm3, xmm0       // copy a.lo
    pand   xmm3, xmm2       // a.lo & mask
    pandn  xmm2, xmm1       // b.lo & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
    // Second 128-bit (hi)
    movdqu xmm0, [rax+16]   // a.hi
    movdqu xmm1, [rdx+16]   // b.hi
    movdqa xmm2, xmm1       // copy b.hi
    pcmpgtd xmm2, xmm0      // b.hi > a.hi
    movdqa xmm3, xmm0       // copy a.hi
    pand   xmm3, xmm2       // a.hi & mask
    pandn  xmm2, xmm1       // b.hi & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx+16], xmm3
  end;
{$ELSE}
begin
  Result.lo := SSE2MinI32x4(a.lo, b.lo);
  Result.hi := SSE2MinI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MaxI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  // max(a,b) = (a > b) ? a : b = blend(b, a, a > b)
  // Process 2×128-bit using pcmpgtd + pand/pandn/por
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // First 128-bit (lo)
    movdqu xmm0, [rax]      // a.lo
    movdqu xmm1, [rdx]      // b.lo
    movdqa xmm2, xmm0       // copy a.lo
    pcmpgtd xmm2, xmm1      // a.lo > b.lo
    movdqa xmm3, xmm0       // copy a.lo
    pand   xmm3, xmm2       // a.lo & mask
    pandn  xmm2, xmm1       // b.lo & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
    // Second 128-bit (hi)
    movdqu xmm0, [rax+16]   // a.hi
    movdqu xmm1, [rdx+16]   // b.hi
    movdqa xmm2, xmm0       // copy a.hi
    pcmpgtd xmm2, xmm1      // a.hi > b.hi
    movdqa xmm3, xmm0       // copy a.hi
    pand   xmm3, xmm2       // a.hi & mask
    pandn  xmm2, xmm1       // b.hi & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx+16], xmm3
  end;
{$ELSE}
begin
  Result.lo := SSE2MaxI32x4(a.lo, b.lo);
  Result.hi := SSE2MaxI32x4(a.hi, b.hi);
{$ENDIF}
end;

{$I fafafa.core.simd.sse2.wide_emulation.inc}


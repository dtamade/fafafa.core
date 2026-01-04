unit fafafa.core.simd.avx2;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// === AVX2 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 AVX2 instructions.
// This backend requires AVX2 support (Intel Haswell 2013+, AMD Excavator 2015+).
//
// ✅ P1-E: vzeroupper 策略
// ============================================================
// 所有使用 YMM 寄存器的 AVX2 函数必须在返回前调用 vzeroupper。
// 这可以避免从 AVX 代码调用 SSE 代码时的 SSE/AVX 状态转换惩罚。
//
// 惩罚原因:
//   - 当 YMM 寄存器的上半部分不干净时，后续 SSE 指令会触发部分寄存器暂存
//   - 在某些 CPU 上可能导致 70+ 周期的延迟
//
// 正确模式:
//   function AVX2Foo(...): ...;
//   asm
//     vmovups ymm0, [...]
//     ... AVX2 操作 ...
//     vmovups [...], ymm0
//     vzeroupper          // <-- 必须在返回前调用
//   end;
//
// 何时需要 vzeroupper:
//   - 任何使用 256-bit YMM 寄存器的汇编函数
//   - 即使函数返回标量值（因为调用者可能使用 SSE）
//
// 何时不需要:
//   - 仅使用 128-bit XMM 寄存器的函数
//   - 纯 Pascal 函数（无内联汇编）
// ============================================================

// Register the AVX2 backend
procedure RegisterAVX2Backend;

// === AVX2 门面函数声明 ===

// 内存操作函数
function MemEqual_AVX2(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_AVX2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;

// 统计函数
function SumBytes_AVX2(p: Pointer; len: SizeUInt): UInt64;
function CountByte_AVX2(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
procedure MinMaxBytes_AVX2(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
function BitsetPopCount_AVX2(p: Pointer; len: SizeUInt): SizeUInt;
function Utf8Validate_AVX2(p: Pointer; len: SizeUInt): Boolean;
procedure MemReverse_AVX2(p: Pointer; len: SizeUInt);
function AsciiIEqual_AVX2(a, b: Pointer; len: SizeUInt): Boolean;
procedure ToLowerAscii_AVX2(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_AVX2(p: Pointer; len: SizeUInt);
function MemDiffRange_AVX2(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
function BytesIndexOf_AVX2(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;

// 内存操作函数 (使用 FPC 内置函数，已足够快)
procedure MemCopy_AVX2(src, dst: Pointer; len: SizeUInt);
procedure MemSet_AVX2(dst: Pointer; len: SizeUInt; value: Byte);

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.scalar; // For fallback functions

// === AVX2 Arithmetic Operations ===
// Note: FPC x86-64 calling convention:
//   - First 6 integer/pointer args: RDI, RSI, RDX, RCX, R8, R9
//   - Float args: XMM0-XMM7
//   - Result pointer for large structs: hidden first arg in RDI
//   - For const record params, pointer is passed

function AVX2AddF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovups xmm0, [rax]
    vaddps xmm0, xmm0, [rdx]
    vmovups [result], xmm0
  end;
end;

function AVX2SubF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovups xmm0, [rax]
    vsubps xmm0, xmm0, [rdx]
    vmovups [result], xmm0
  end;
end;

function AVX2MulF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovups xmm0, [rax]
    vmulps xmm0, xmm0, [rdx]
    vmovups [result], xmm0
  end;
end;

function AVX2DivF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovups xmm0, [rax]
    vdivps xmm0, xmm0, [rdx]
    vmovups [result], xmm0
  end;
end;

function AVX2FmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
begin
  // 仅当 CPU + OS 均支持 FMA(AVX state) 时，才执行 vfmadd* 指令
  if HasFeature(gfFMA) then
  begin
    asm
      lea      rax, a
      lea      rdx, b
      lea      rcx, c
      vmovups  xmm0, [rcx]          // xmm0 = c
      vmovups  xmm1, [rax]          // xmm1 = a
      vfmadd231ps xmm0, xmm1, [rdx] // xmm0 = a*b + c (fused)
      vmovups  [result], xmm0
    end;
  end
  else
    Result := ScalarFmaF32x4(a, b, c);
end;

function AVX2RcpF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    vmovups xmm0, [rax]
    vrcpps xmm0, xmm0
    vmovups [result], xmm0
  end;
end;

function AVX2RsqrtF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea     rax, a
    vmovups xmm0, [rax]
    vrsqrtps xmm0, xmm0
    vmovups [result], xmm0
  end;
end;

function AVX2FloorF32x4(const a: TVecF32x4): TVecF32x4;
begin
  if HasSSE41 then
  begin
    asm
      lea    rax, a
      vmovups xmm0, [rax]
      // roundps xmm0, xmm0, 1  (floor)
      db $66, $0F, $3A, $08, $C0, $01
      vmovups [result], xmm0
    end;
  end
  else
    Result := ScalarFloorF32x4(a);
end;

function AVX2CeilF32x4(const a: TVecF32x4): TVecF32x4;
begin
  if HasSSE41 then
  begin
    asm
      lea    rax, a
      vmovups xmm0, [rax]
      // roundps xmm0, xmm0, 2  (ceil)
      db $66, $0F, $3A, $08, $C0, $02
      vmovups [result], xmm0
    end;
  end
  else
    Result := ScalarCeilF32x4(a);
end;

function AVX2RoundF32x4(const a: TVecF32x4): TVecF32x4;
begin
  if HasSSE41 then
  begin
    asm
      lea    rax, a
      vmovups xmm0, [rax]
      // roundps xmm0, xmm0, 0  (round to nearest even)
      db $66, $0F, $3A, $08, $C0, $00
      vmovups [result], xmm0
    end;
  end
  else
    Result := ScalarRoundF32x4(a);
end;

function AVX2TruncF32x4(const a: TVecF32x4): TVecF32x4;
begin
  if HasSSE41 then
  begin
    asm
      lea    rax, a
      vmovups xmm0, [rax]
      // roundps xmm0, xmm0, 3  (truncate)
      db $66, $0F, $3A, $08, $C0, $03
      vmovups [result], xmm0
    end;
  end
  else
    Result := ScalarTruncF32x4(a);
end;

function AVX2ClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
begin
  // 语义对齐：与 ScalarClampF32x4 相同的计算顺序：
  //   Max(minVal, Min(a, maxVal))
  // 注意：vmin/vmax 在 NaN 场景下是“返回第二操作数”，因此 operand 顺序必须匹配标量实现。
  asm
    lea     rax, a
    lea     rdx, minVal
    lea     rcx, maxVal

    vmovups xmm0, [rax]
    vminps  xmm0, xmm0, [rcx]   // temp = Min(a, maxVal)  (maxVal as 2nd operand)

    vmovups xmm1, [rdx]
    vmaxps  xmm0, xmm1, xmm0    // result = Max(minVal, temp) (temp as 2nd operand)

    vmovups [result], xmm0
  end;
end;

// === Vector Math Functions ===

function AVX2DotF32x4(const a, b: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovups xmm0, [rax]
    vmovups xmm1, [rdx]
    vmulps  xmm0, xmm0, xmm1

    // Horizontal add: sum all 4 lanes
    vshufps xmm1, xmm0, xmm0, $4E // Swap high/low pairs
    vaddps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $B1 // Swap adjacent
    vaddss  xmm0, xmm0, xmm1

    vmovss  [result], xmm0
  end;
end;

function AVX2DotF32x3(const a, b: TVecF32x4): Single;
begin
  asm
    lea      rax, a
    lea      rdx, b
    vmovups  xmm0, [rax]
    vmovups  xmm1, [rdx]
    vmulps   xmm0, xmm0, xmm1

    // Zero w before summing (mask = [FFFFFFFF,FFFFFFFF,FFFFFFFF,00000000])
    vpcmpeqd xmm1, xmm1, xmm1
    vpsrldq  xmm1, xmm1, 4
    vandps   xmm0, xmm0, xmm1

    // Horizontal add
    vshufps  xmm1, xmm0, xmm0, $4E
    vaddps   xmm0, xmm0, xmm1
    vshufps  xmm1, xmm0, xmm0, $B1
    vaddss   xmm0, xmm0, xmm1

    vmovss   [result], xmm0
  end;
end;

function AVX2CrossF32x3(const a, b: TVecF32x4): TVecF32x4;
begin
  // Cross = (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  asm
    lea     rax, a
    lea     rdx, b
    vmovups xmm0, [rax]        // a = [x, y, z, w]
    vmovups xmm1, [rdx]        // b = [x, y, z, w]

    // Shuffle a: [y, z, x, w]
    vshufps xmm2, xmm0, xmm0, $C9
    // Shuffle b: [z, x, y, w]
    vshufps xmm3, xmm1, xmm1, $D2
    vmulps  xmm2, xmm2, xmm3

    // Shuffle a: [z, x, y, w]
    vshufps xmm4, xmm0, xmm0, $D2
    // Shuffle b: [y, z, x, w]
    vshufps xmm5, xmm1, xmm1, $C9
    vmulps  xmm4, xmm4, xmm5

    vsubps  xmm2, xmm2, xmm4
    vmovups [result], xmm2
  end;
  Result.f[3] := 0.0; // Ensure w=0
end;

function AVX2LengthF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea     rax, a
    vmovups xmm0, [rax]
    vmulps  xmm0, xmm0, xmm0

    // Horizontal add
    vshufps xmm1, xmm0, xmm0, $4E
    vaddps  xmm0, xmm0, xmm1
    vshufps xmm1, xmm0, xmm0, $B1
    vaddss  xmm0, xmm0, xmm1

    vsqrtss xmm0, xmm0, xmm0
    vmovss  [result], xmm0
  end;
end;

function AVX2LengthF32x3(const a: TVecF32x4): Single;
begin
  asm
    lea      rax, a
    vmovups  xmm0, [rax]

    // Zero w (mask = [FFFFFFFF,FFFFFFFF,FFFFFFFF,00000000])
    vpcmpeqd xmm1, xmm1, xmm1
    vpsrldq  xmm1, xmm1, 4
    vandps   xmm0, xmm0, xmm1

    vmulps   xmm0, xmm0, xmm0

    // Horizontal add
    vshufps  xmm1, xmm0, xmm0, $4E
    vaddps   xmm0, xmm0, xmm1
    vshufps  xmm1, xmm0, xmm0, $B1
    vaddss   xmm0, xmm0, xmm1

    vsqrtss  xmm0, xmm0, xmm0
    vmovss   [result], xmm0
  end;
end;

function AVX2NormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var
  len: Single;
begin
  len := AVX2LengthF32x4(a);
  if len > 0.0 then
  begin
    asm
      lea     rax, a
      vmovups xmm0, [rax]
      vmovss  xmm1, len
      vshufps xmm1, xmm1, xmm1, 0   // Broadcast length
      vdivps  xmm0, xmm0, xmm1      // Divide each element by length
      vmovups [result], xmm0
    end;
  end
  else
    Result := a;
end;

function AVX2NormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var
  len: Single;
begin
  len := AVX2LengthF32x3(a);
  if len > 0.0 then
  begin
    asm
      lea     rax, a
      vmovups xmm0, [rax]
      vmovss  xmm1, len
      vshufps xmm1, xmm1, xmm1, 0
      vdivps  xmm0, xmm0, xmm1
      vmovups [result], xmm0
    end;
    Result.f[3] := 0.0;
  end
  else
  begin
    Result := a;
    Result.f[3] := 0.0;
  end;
end;

function AVX2AddF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovupd xmm0, [rax]
    vaddpd xmm0, xmm0, [rdx]
    vmovupd [result], xmm0
  end;
end;

function AVX2SubF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovupd xmm0, [rax]
    vsubpd xmm0, xmm0, [rdx]
    vmovupd [result], xmm0
  end;
end;

function AVX2MulF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovupd xmm0, [rax]
    vmulpd xmm0, xmm0, [rdx]
    vmovupd [result], xmm0
  end;
end;

function AVX2DivF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovupd xmm0, [rax]
    vdivpd xmm0, xmm0, [rdx]
    vmovupd [result], xmm0
  end;
end;

// === F64x2 Math Operations (128-bit) ===

function AVX2AbsF64x2(const a: TVecF64x2): TVecF64x2;
begin
  // Generate AbsMask dynamically (PIC-safe): 0x7FFFFFFFFFFFFFFF
  asm
    lea      rax, a
    vmovupd  xmm0, [rax]
    vpcmpeqd xmm1, xmm1, xmm1  // all 1s
    vpsrlq   xmm1, xmm1, 1     // shift right 1 = 0x7FFFFFFFFFFFFFFF
    vandpd   xmm0, xmm0, xmm1
    vmovupd  [result], xmm0
  end;
end;

function AVX2SqrtF64x2(const a: TVecF64x2): TVecF64x2;
begin
  asm
    lea     rax, a
    vmovupd xmm0, [rax]
    vsqrtpd xmm0, xmm0
    vmovupd [result], xmm0
  end;
end;

function AVX2MinF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovupd xmm0, [rax]
    vminpd  xmm0, xmm0, [rdx]
    vmovupd [result], xmm0
  end;
end;

function AVX2MaxF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovupd xmm0, [rax]
    vmaxpd  xmm0, xmm0, [rdx]
    vmovupd [result], xmm0
  end;
end;

function AVX2ClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2;
begin
  asm
    lea     rax, a
    lea     rdx, minVal
    lea     rcx, maxVal
    vmovupd xmm0, [rax]
    vmaxpd  xmm0, xmm0, [rdx]   // clamp to min
    vminpd  xmm0, xmm0, [rcx]   // clamp to max
    vmovupd [result], xmm0
  end;
end;

// === F64x2 Reduction Operations (128-bit) ===

function AVX2ReduceAddF64x2(const a: TVecF64x2): Double;
begin
  asm
    lea      rax, a
    vmovupd  xmm0, [rax]
    vhaddpd  xmm0, xmm0, xmm0   // horizontal add
    vmovsd   [result], xmm0
  end;
end;

function AVX2ReduceMinF64x2(const a: TVecF64x2): Double;
begin
  asm
    lea      rax, a
    vmovupd  xmm0, [rax]
    vshufpd  xmm1, xmm0, xmm0, 1  // swap elements
    vminpd   xmm0, xmm0, xmm1
    vmovsd   [result], xmm0
  end;
end;

function AVX2ReduceMaxF64x2(const a: TVecF64x2): Double;
begin
  asm
    lea      rax, a
    vmovupd  xmm0, [rax]
    vshufpd  xmm1, xmm0, xmm0, 1  // swap elements
    vmaxpd   xmm0, xmm0, xmm1
    vmovsd   [result], xmm0
  end;
end;

function AVX2ReduceMulF64x2(const a: TVecF64x2): Double;
begin
  asm
    lea      rax, a
    vmovupd  xmm0, [rax]
    vshufpd  xmm1, xmm0, xmm0, 1  // swap elements
    vmulpd   xmm0, xmm0, xmm1
    vmovsd   [result], xmm0
  end;
end;

// === F64x2 Comparison Operations (128-bit) ===

function AVX2CmpEqF64x2(const a, b: TVecF64x2): TMask2;
var mask: Integer;
begin
  asm
    lea       rax, a
    lea       rdx, b
    vmovupd   xmm0, [rax]
    vcmpeqpd  xmm0, xmm0, [rdx]
    vmovmskpd eax, xmm0
    mov       mask, eax
  end;
  Result := TMask2(mask);
end;

function AVX2CmpLtF64x2(const a, b: TVecF64x2): TMask2;
var mask: Integer;
begin
  asm
    lea       rax, a
    lea       rdx, b
    vmovupd   xmm0, [rax]
    vcmpltpd  xmm0, xmm0, [rdx]
    vmovmskpd eax, xmm0
    mov       mask, eax
  end;
  Result := TMask2(mask);
end;

function AVX2CmpLeF64x2(const a, b: TVecF64x2): TMask2;
var mask: Integer;
begin
  asm
    lea       rax, a
    lea       rdx, b
    vmovupd   xmm0, [rax]
    vcmplepd  xmm0, xmm0, [rdx]
    vmovmskpd eax, xmm0
    mov       mask, eax
  end;
  Result := TMask2(mask);
end;

function AVX2CmpGtF64x2(const a, b: TVecF64x2): TMask2;
var mask: Integer;
begin
  // GT: swap operands and use LT (a > b = b < a)
  asm
    lea       rax, b
    lea       rdx, a
    vmovupd   xmm0, [rax]
    vcmpltpd  xmm0, xmm0, [rdx]
    vmovmskpd eax, xmm0
    mov       mask, eax
  end;
  Result := TMask2(mask);
end;

function AVX2CmpGeF64x2(const a, b: TVecF64x2): TMask2;
var mask: Integer;
begin
  // GE: swap operands and use LE (a >= b = b <= a)
  asm
    lea       rax, b
    lea       rdx, a
    vmovupd   xmm0, [rax]
    vcmplepd  xmm0, xmm0, [rdx]
    vmovmskpd eax, xmm0
    mov       mask, eax
  end;
  Result := TMask2(mask);
end;

function AVX2CmpNeF64x2(const a, b: TVecF64x2): TMask2;
var mask: Integer;
begin
  asm
    lea        rax, a
    lea        rdx, b
    vmovupd    xmm0, [rax]
    vcmpneqpd  xmm0, xmm0, [rdx]
    vmovmskpd  eax, xmm0
    mov        mask, eax
  end;
  Result := TMask2(mask);
end;

// === F64x2 Extended Math Operations (128-bit) ===

function AVX2FmaF64x2(const a, b, c: TVecF64x2): TVecF64x2;
begin
  if HasFeature(gfFMA) then
  begin
    asm
      lea       rax, a
      lea       rdx, b
      lea       rcx, c
      vmovupd   xmm0, [rcx]           // xmm0 = c
      vmovupd   xmm1, [rax]           // xmm1 = a
      vfmadd231pd xmm0, xmm1, [rdx]   // xmm0 = a*b + c (fused)
      vmovupd   [result], xmm0
    end;
  end
  else
    Result := ScalarFmaF64x2(a, b, c);
end;

function AVX2FloorF64x2(const a: TVecF64x2): TVecF64x2;
begin
  if HasSSE41 then
  begin
    asm
      lea      rax, a
      vmovupd  xmm0, [rax]
      vroundpd xmm0, xmm0, 1   // floor = round toward -inf
      vmovupd  [result], xmm0
    end;
  end
  else
    Result := ScalarFloorF64x2(a);
end;

function AVX2CeilF64x2(const a: TVecF64x2): TVecF64x2;
begin
  if HasSSE41 then
  begin
    asm
      lea      rax, a
      vmovupd  xmm0, [rax]
      vroundpd xmm0, xmm0, 2   // ceil = round toward +inf
      vmovupd  [result], xmm0
    end;
  end
  else
    Result := ScalarCeilF64x2(a);
end;

function AVX2RoundF64x2(const a: TVecF64x2): TVecF64x2;
begin
  if HasSSE41 then
  begin
    asm
      lea      rax, a
      vmovupd  xmm0, [rax]
      vroundpd xmm0, xmm0, 0   // round to nearest even
      vmovupd  [result], xmm0
    end;
  end
  else
    Result := ScalarRoundF64x2(a);
end;

function AVX2TruncF64x2(const a: TVecF64x2): TVecF64x2;
begin
  if HasSSE41 then
  begin
    asm
      lea      rax, a
      vmovupd  xmm0, [rax]
      vroundpd xmm0, xmm0, 3   // truncate = round toward zero
      vmovupd  [result], xmm0
    end;
  end
  else
    Result := ScalarTruncF64x2(a);
end;

// === F64x2 Load/Store/Splat/Zero Operations (128-bit) ===

function AVX2LoadF64x2(p: PDouble): TVecF64x2;
begin
  Assert(p <> nil, 'AVX2LoadF64x2: pointer is nil');
  asm
    mov      rax, p
    vmovupd  xmm0, [rax]
    vmovupd  [result], xmm0
  end;
end;

procedure AVX2StoreF64x2(p: PDouble; const a: TVecF64x2);
begin
  Assert(p <> nil, 'AVX2StoreF64x2: pointer is nil');
  asm
    mov      rax, p
    lea      rdx, a
    vmovupd  xmm0, [rdx]
    vmovupd  [rax], xmm0
  end;
end;

function AVX2SplatF64x2(value: Double): TVecF64x2;
begin
  asm
    movsd       xmm0, value
    vmovddup    xmm0, xmm0     // duplicate to both lanes
    vmovupd     [result], xmm0
  end;
end;

function AVX2ZeroF64x2: TVecF64x2;
begin
  asm
    vxorpd   xmm0, xmm0, xmm0
    vmovupd  [result], xmm0
  end;
end;

function AVX2AddI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovdqu xmm0, [rax]
    vpaddd xmm0, xmm0, [rdx]
    vmovdqu [result], xmm0
  end;
end;

function AVX2SubI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovdqu xmm0, [rax]
    vpsubd xmm0, xmm0, [rdx]
    vmovdqu [result], xmm0
  end;
end;

// AVX2 has pmulld for 32-bit integer multiply
function AVX2MulI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    vmovdqu xmm0, [rax]
    vpmulld xmm0, xmm0, [rdx]
    vmovdqu [result], xmm0
  end;
end;

// === I32x4 Bitwise Operations (128-bit) ===

function AVX2AndI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovdqu xmm0, [rax]
    vpand   xmm0, xmm0, [rdx]
    vmovdqu [result], xmm0
  end;
end;

function AVX2OrI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovdqu xmm0, [rax]
    vpor    xmm0, xmm0, [rdx]
    vmovdqu [result], xmm0
  end;
end;

function AVX2XorI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovdqu xmm0, [rax]
    vpxor   xmm0, xmm0, [rdx]
    vmovdqu [result], xmm0
  end;
end;

function AVX2NotI32x4(const a: TVecI32x4): TVecI32x4;
begin
  asm
    lea      rax, a
    vpcmpeqd xmm1, xmm1, xmm1   // all 1s
    vmovdqu  xmm0, [rax]
    vpxor    xmm0, xmm0, xmm1   // NOT = XOR with all 1s
    vmovdqu  [result], xmm0
  end;
end;

function AVX2AndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovdqu xmm0, [rax]
    vpandn  xmm0, xmm0, [rdx]  // (NOT a) AND b
    vmovdqu [result], xmm0
  end;
end;

// === I32x4 Shift Operations (128-bit) ===

function AVX2ShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  if (count < 0) or (count >= 32) then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;
  asm
    lea     rax, a
    vmovdqu xmm0, [rax]
    vmovd   xmm1, count
    vpslld  xmm0, xmm0, xmm1
    vmovdqu [result], xmm0
  end;
end;

function AVX2ShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  if (count < 0) or (count >= 32) then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;
  asm
    lea     rax, a
    vmovdqu xmm0, [rax]
    vmovd   xmm1, count
    vpsrld  xmm0, xmm0, xmm1   // Logical right shift
    vmovdqu [result], xmm0
  end;
end;

function AVX2ShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  i: Integer;
begin
  if count < 0 then
  begin
    Result := a;
    Exit;
  end;
  if count >= 32 then
  begin
    // Arithmetic shift >= 32: result is all 0s or all 1s depending on sign
    for i := 0 to 3 do
      if a.i[i] < 0 then
        Result.i[i] := -1
      else
        Result.i[i] := 0;
    Exit;
  end;
  asm
    lea     rax, a
    vmovdqu xmm0, [rax]
    vmovd   xmm1, count
    vpsrad  xmm0, xmm0, xmm1   // Arithmetic right shift
    vmovdqu [result], xmm0
  end;
end;

// === I32x4 Comparison Operations (128-bit) ===

function AVX2CmpEqI32x4(const a, b: TVecI32x4): TMask4;
var mask: Integer;
begin
  asm
    lea       rax, a
    lea       rdx, b
    vmovdqu   xmm0, [rax]
    vpcmpeqd  xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov       mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpLtI32x4(const a, b: TVecI32x4): TMask4;
var mask: Integer;
begin
  // a < b is equivalent to b > a
  asm
    lea       rax, b
    lea       rdx, a
    vmovdqu   xmm0, [rax]
    vpcmpgtd  xmm0, xmm0, [rdx]  // b > a
    vmovmskps eax, xmm0
    mov       mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpGtI32x4(const a, b: TVecI32x4): TMask4;
var mask: Integer;
begin
  asm
    lea       rax, a
    lea       rdx, b
    vmovdqu   xmm0, [rax]
    vpcmpgtd  xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov       mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpLeI32x4(const a, b: TVecI32x4): TMask4;
var mask: Integer;
begin
  // a <= b is equivalent to NOT(a > b)
  asm
    lea       rax, a
    lea       rdx, b
    vmovdqu   xmm0, [rax]
    vpcmpgtd  xmm0, xmm0, [rdx]  // a > b
    vmovmskps eax, xmm0
    xor       eax, $F            // NOT (4 bits for 4 elements)
    mov       mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpGeI32x4(const a, b: TVecI32x4): TMask4;
var mask: Integer;
begin
  // a >= b is equivalent to NOT(a < b) = NOT(b > a)
  asm
    lea       rax, b
    lea       rdx, a
    vmovdqu   xmm0, [rax]
    vpcmpgtd  xmm0, xmm0, [rdx]  // b > a = a < b
    vmovmskps eax, xmm0
    xor       eax, $F            // NOT (4 bits)
    mov       mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpNeI32x4(const a, b: TVecI32x4): TMask4;
var mask: Integer;
begin
  // a != b is equivalent to NOT(a == b)
  asm
    lea       rax, a
    lea       rdx, b
    vmovdqu   xmm0, [rax]
    vpcmpeqd  xmm0, xmm0, [rdx]  // a == b
    vmovmskps eax, xmm0
    xor       eax, $F            // NOT (4 bits)
    mov       mask, eax
  end;
  Result := TMask4(mask);
end;

// === I32x4 Min/Max Operations (128-bit) ===

function AVX2MinI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovdqu xmm0, [rax]
    vpminsd xmm0, xmm0, [rdx]   // Signed min
    vmovdqu [result], xmm0
  end;
end;

function AVX2MaxI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovdqu xmm0, [rax]
    vpmaxsd xmm0, xmm0, [rdx]   // Signed max
    vmovdqu [result], xmm0
  end;
end;

// === AVX2 Comparison Operations ===

function AVX2CmpEqF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    vmovups  xmm0, [rax]
    vcmpeqps xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpLtF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    vmovups  xmm0, [rax]
    vcmpltps xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpLeF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    vmovups  xmm0, [rax]
    vcmpleps xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpGtF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  // GT: swap operands and use LT
  asm
    lea      rax, b
    lea      rdx, a
    vmovups  xmm0, [rax]
    vcmpltps xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpGeF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  // GE: swap operands and use LE
  asm
    lea      rax, b
    lea      rdx, a
    vmovups  xmm0, [rax]
    vcmpleps xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function AVX2CmpNeF32x4(const a, b: TVecF32x4): TMask4;
var mask: Integer;
begin
  asm
    lea       rax, a
    lea       rdx, b
    vmovups   xmm0, [rax]
    vcmpneqps xmm0, xmm0, [rdx]
    vmovmskps eax, xmm0
    mov       mask, eax
  end;
  Result := TMask4(mask);
end;

// === AVX2 Math Functions ===

function AVX2AbsF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea      rax, a
    vmovups  xmm0, [rax]
    vpcmpeqd xmm1, xmm1, xmm1     // all 1s
    vpsrld   xmm1, xmm1, 1        // shift right to get 0x7FFFFFFF
    vandps   xmm0, xmm0, xmm1
    vmovups  [result], xmm0
  end;
end;

function AVX2SqrtF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea     rax, a
    vmovups xmm0, [rax]
    vsqrtps xmm0, xmm0
    vmovups [result], xmm0
  end;
end;

function AVX2MinF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovups xmm0, [rax]
    vminps  xmm0, xmm0, [rdx]
    vmovups [result], xmm0
  end;
end;

function AVX2MaxF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea     rax, a
    lea     rdx, b
    vmovups xmm0, [rax]
    vmaxps  xmm0, xmm0, [rdx]
    vmovups [result], xmm0
  end;
end;

// === AVX2 Reduction Operations ===

function AVX2ReduceAddF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea      rax, a
    vmovups  xmm0, [rax]
    vhaddps  xmm0, xmm0, xmm0     // horizontal add
    vhaddps  xmm0, xmm0, xmm0
    vmovss   [result], xmm0
  end;
end;

function AVX2ReduceMinF32x4(const a: TVecF32x4): Single;
begin
  // 语义对齐：与 ScalarReduceMinF32x4 相同的顺序 fold。
  // 说明：vmin* 在 NaN/相等值/±0 上是“选择第二操作数”的语义，
  // 这会让 reduction 的结果依赖于归约顺序；因此这里按 a0->a1->a2->a3 顺序归约。
  asm
    lea      rax, a
    vmovups  xmm2, [rax]

    // acc := a0
    vmovaps  xmm0, xmm2

    // acc := min(acc, a1)
    vshufps  xmm1, xmm2, xmm2, $55
    vminss   xmm0, xmm0, xmm1

    // acc := min(acc, a2)
    vshufps  xmm1, xmm2, xmm2, $AA
    vminss   xmm0, xmm0, xmm1

    // acc := min(acc, a3)
    vshufps  xmm1, xmm2, xmm2, $FF
    vminss   xmm0, xmm0, xmm1

    vmovss   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMaxF32x4(const a: TVecF32x4): Single;
begin
  // 语义对齐：与 ScalarReduceMaxF32x4 相同的顺序 fold。
  // 说明：vmax* 在 NaN/相等值/±0 上是“选择第二操作数”的语义，
  // 这会让 reduction 的结果依赖于归约顺序；因此这里按 a0->a1->a2->a3 顺序归约。
  asm
    lea      rax, a
    vmovups  xmm2, [rax]

    // acc := a0
    vmovaps  xmm0, xmm2

    // acc := max(acc, a1)
    vshufps  xmm1, xmm2, xmm2, $55
    vmaxss   xmm0, xmm0, xmm1

    // acc := max(acc, a2)
    vshufps  xmm1, xmm2, xmm2, $AA
    vmaxss   xmm0, xmm0, xmm1

    // acc := max(acc, a3)
    vshufps  xmm1, xmm2, xmm2, $FF
    vmaxss   xmm0, xmm0, xmm1

    vmovss   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMulF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea      rax, a
    vmovups  xmm0, [rax]
    vshufps  xmm1, xmm0, xmm0, $4E
    vmulps   xmm0, xmm0, xmm1
    vshufps  xmm1, xmm0, xmm0, $B1
    vmulss   xmm0, xmm0, xmm1
    vmovss   [result], xmm0
  end;
end;

// === AVX2 Memory Operations ===

function AVX2LoadF32x4(p: PSingle): TVecF32x4;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'AVX2LoadF32x4: pointer is nil');
  asm
    mov     rax, p
    vmovups xmm0, [rax]
    vmovups [result], xmm0
  end;
end;

function AVX2LoadF32x4Aligned(p: PSingle): TVecF32x4;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'AVX2LoadF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'AVX2LoadF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  asm
    mov     rax, p
    vmovaps xmm0, [rax]
    vmovups [result], xmm0
  end;
end;

procedure AVX2StoreF32x4(p: PSingle; const a: TVecF32x4);
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'AVX2StoreF32x4: pointer is nil');
  asm
    mov     rax, p
    lea     rdx, a
    vmovups xmm0, [rdx]
    vmovups [rax], xmm0
  end;
end;

procedure AVX2StoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'AVX2StoreF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'AVX2StoreF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  asm
    mov     rax, p
    lea     rdx, a
    vmovups xmm0, [rdx]
    vmovaps [rax], xmm0
  end;
end;

// === AVX2 Utility Operations ===

function AVX2SplatF32x4(value: Single): TVecF32x4;
begin
  asm
    movss       xmm0, value
    vbroadcastss xmm0, xmm0
    vmovups     [result], xmm0
  end;
end;

function AVX2ZeroF32x4: TVecF32x4;
begin
  asm
    vxorps  xmm0, xmm0, xmm0
    vmovups [result], xmm0
  end;
end;

function AVX2SelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function AVX2ExtractF32x4(const a: TVecF32x4; index: Integer): Single;
var
  safeIndex: Integer;
begin
  // ✅ Safety check: use saturation strategy for index bounds (per project spec)
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  Result := a.f[safeIndex];
end;

function AVX2InsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
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

// === F32x8 Operations (native 256-bit AVX) ===

function AVX2AddF32x8(const a, b: TVecF32x8): TVecF32x8;
var
  pa, pb, pr: Pointer;
begin
  // 注意：FPC 对 32-byte record 的传参与返回值可能走 hidden pointer 约定。
  // 直接在 asm 中用 [a]/[result] 容易把指针槽当作数据块，导致栈/堆被写坏。
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovups ymm0, [rdx]
    vaddps  ymm0, ymm0, [rcx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SubF32x8(const a, b: TVecF32x8): TVecF32x8;
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
    vmovups ymm0, [rdx]
    vsubps  ymm0, ymm0, [rcx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MulF32x8(const a, b: TVecF32x8): TVecF32x8;
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
    vmovups ymm0, [rdx]
    vmulps  ymm0, ymm0, [rcx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

function AVX2DivF32x8(const a, b: TVecF32x8): TVecF32x8;
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
    vmovups ymm0, [rdx]
    vdivps  ymm0, ymm0, [rcx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

// === F32x8 Math Operations (256-bit AVX) ===

function AVX2AbsF32x8(const a: TVecF32x8): TVecF32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  // Generate AbsMask dynamically (PIC-safe): 0x7FFFFFFF for each lane
  asm
    mov      rax, pr
    mov      rdx, pa
    vmovups  ymm0, [rdx]
    vpcmpeqd ymm1, ymm1, ymm1  // all 1s
    vpsrld   ymm1, ymm1, 1     // shift right 1 = 0x7FFFFFFF
    vandps   ymm0, ymm0, ymm1
    vmovups  [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SqrtF32x8(const a: TVecF32x8): TVecF32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov     rax, pr
    mov     rdx, pa
    vmovups ymm0, [rdx]
    vsqrtps ymm0, ymm0
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MinF32x8(const a, b: TVecF32x8): TVecF32x8;
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
    vmovups ymm0, [rdx]
    vminps  ymm0, ymm0, [rcx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MaxF32x8(const a, b: TVecF32x8): TVecF32x8;
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
    vmovups ymm0, [rdx]
    vmaxps  ymm0, ymm0, [rcx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8;
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
    vmovups ymm0, [rdx]
    vmaxps  ymm0, ymm0, [rcx]   // clamp to min
    vminps  ymm0, ymm0, [r8]    // clamp to max
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

// === F32x8 Reduction Operations (256-bit AVX) ===

function AVX2ReduceAddF32x8(const a: TVecF32x8): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovups  ymm0, [rdx]
    // 256->128: extract high 128 and add to low 128
    vextractf128 xmm1, ymm0, 1
    vaddps   xmm0, xmm0, xmm1
    // 128->64: horizontal add
    vhaddps  xmm0, xmm0, xmm0
    // 64->32: horizontal add again
    vhaddps  xmm0, xmm0, xmm0
    vmovss   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMinF32x8(const a: TVecF32x8): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovups  ymm0, [rdx]
    // 256->128: extract high 128 and min with low 128
    vextractf128 xmm1, ymm0, 1
    vminps   xmm0, xmm0, xmm1
    // 128->64: shuffle and min
    vshufps  xmm1, xmm0, xmm0, $4E  // swap high/low 64-bit pairs
    vminps   xmm0, xmm0, xmm1
    // 64->32: shuffle and min
    vshufps  xmm1, xmm0, xmm0, $B1  // swap adjacent 32-bit elements
    vminss   xmm0, xmm0, xmm1
    vmovss   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMaxF32x8(const a: TVecF32x8): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovups  ymm0, [rdx]
    // 256->128: extract high 128 and max with low 128
    vextractf128 xmm1, ymm0, 1
    vmaxps   xmm0, xmm0, xmm1
    // 128->64: shuffle and max
    vshufps  xmm1, xmm0, xmm0, $4E
    vmaxps   xmm0, xmm0, xmm1
    // 64->32: shuffle and max
    vshufps  xmm1, xmm0, xmm0, $B1
    vmaxss   xmm0, xmm0, xmm1
    vmovss   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMulF32x8(const a: TVecF32x8): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovups  ymm0, [rdx]
    // 256->128: extract high 128 and mul with low 128
    vextractf128 xmm1, ymm0, 1
    vmulps   xmm0, xmm0, xmm1
    // 128->64: shuffle and mul
    vshufps  xmm1, xmm0, xmm0, $4E
    vmulps   xmm0, xmm0, xmm1
    // 64->32: shuffle and mul
    vshufps  xmm1, xmm0, xmm0, $B1
    vmulss   xmm0, xmm0, xmm1
    vmovss   [result], xmm0
    vzeroupper
  end;
end;

// === F32x8 Extended Math Operations (256-bit AVX) ===

function AVX2FmaF32x8(const a, b, c: TVecF32x8): TVecF32x8;
var
  pa, pb, pc, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  pc := @c;
  if HasFeature(gfFMA) then
  begin
    asm
      mov     rax, pr
      mov     rdx, pa
      mov     rcx, pb
      mov     r8, pc
      vmovups ymm0, [r8]            // ymm0 = c
      vmovups ymm1, [rdx]           // ymm1 = a
      vfmadd231ps ymm0, ymm1, [rcx] // ymm0 = a*b + c (fused)
      vmovups [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarFmaF32x8(a, b, c);
end;

function AVX2FloorF32x8(const a: TVecF32x8): TVecF32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovups  ymm0, [rdx]
      vroundps ymm0, ymm0, 1   // floor = round toward -inf
      vmovups  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarFloorF32x8(a);
end;

function AVX2CeilF32x8(const a: TVecF32x8): TVecF32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovups  ymm0, [rdx]
      vroundps ymm0, ymm0, 2   // ceil = round toward +inf
      vmovups  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarCeilF32x8(a);
end;

function AVX2RoundF32x8(const a: TVecF32x8): TVecF32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovups  ymm0, [rdx]
      vroundps ymm0, ymm0, 0   // round to nearest even
      vmovups  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarRoundF32x8(a);
end;

function AVX2TruncF32x8(const a: TVecF32x8): TVecF32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovups  ymm0, [rdx]
      vroundps ymm0, ymm0, 3   // truncate = round toward zero
      vmovups  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarTruncF32x8(a);
end;

// === F32x8 Load/Store/Splat/Zero Operations (256-bit AVX) ===

function AVX2LoadF32x8(p: PSingle): TVecF32x8;
var
  pr: Pointer;
begin
  Assert(p <> nil, 'AVX2LoadF32x8: pointer is nil');
  pr := @Result;
  asm
    mov     rax, pr
    mov     rdx, p
    vmovups ymm0, [rdx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

procedure AVX2StoreF32x8(p: PSingle; const a: TVecF32x8);
var
  pa: Pointer;
begin
  Assert(p <> nil, 'AVX2StoreF32x8: pointer is nil');
  pa := @a;
  asm
    mov     rax, p
    mov     rdx, pa
    vmovups ymm0, [rdx]
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SplatF32x8(value: Single): TVecF32x8;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov          rax, pr
    movss        xmm0, value
    vbroadcastss ymm0, xmm0     // broadcast to all 8 lanes
    vmovups      [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ZeroF32x8: TVecF32x8;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov     rax, pr
    vxorps  ymm0, ymm0, ymm0
    vmovups [rax], ymm0
    vzeroupper
  end;
end;

// === F64x4 Operations (native 256-bit AVX) ===

function AVX2AddF64x4(const a, b: TVecF64x4): TVecF64x4;
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
    vmovupd ymm0, [rdx]
    vaddpd  ymm0, ymm0, [rcx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SubF64x4(const a, b: TVecF64x4): TVecF64x4;
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
    vmovupd ymm0, [rdx]
    vsubpd  ymm0, ymm0, [rcx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MulF64x4(const a, b: TVecF64x4): TVecF64x4;
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
    vmovupd ymm0, [rdx]
    vmulpd  ymm0, ymm0, [rcx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

function AVX2DivF64x4(const a, b: TVecF64x4): TVecF64x4;
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
    vmovupd ymm0, [rdx]
    vdivpd  ymm0, ymm0, [rcx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

// === F64x4 Math Operations (256-bit AVX) ===

function AVX2AbsF64x4(const a: TVecF64x4): TVecF64x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  // Generate AbsMask dynamically (PIC-safe): 0x7FFFFFFFFFFFFFFF for each lane
  asm
    mov      rax, pr
    mov      rdx, pa
    vmovupd  ymm0, [rdx]
    vpcmpeqd ymm1, ymm1, ymm1  // all 1s
    vpsrlq   ymm1, ymm1, 1     // shift right 1 = 0x7FFFFFFFFFFFFFFF
    vandpd   ymm0, ymm0, ymm1
    vmovupd  [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SqrtF64x4(const a: TVecF64x4): TVecF64x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov     rax, pr
    mov     rdx, pa
    vmovupd ymm0, [rdx]
    vsqrtpd ymm0, ymm0
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MinF64x4(const a, b: TVecF64x4): TVecF64x4;
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
    vmovupd ymm0, [rdx]
    vminpd  ymm0, ymm0, [rcx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MaxF64x4(const a, b: TVecF64x4): TVecF64x4;
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
    vmovupd ymm0, [rdx]
    vmaxpd  ymm0, ymm0, [rcx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4;
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
    vmovupd ymm0, [rdx]
    vmaxpd  ymm0, ymm0, [rcx]   // clamp to min
    vminpd  ymm0, ymm0, [r8]    // clamp to max
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

// === F64x4 Reduction Operations (256-bit AVX) ===

function AVX2ReduceAddF64x4(const a: TVecF64x4): Double;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovupd  ymm0, [rdx]
    // 256->128: extract high 128 and add to low 128
    vextractf128 xmm1, ymm0, 1
    vaddpd   xmm0, xmm0, xmm1
    // 128->64: horizontal add
    vhaddpd  xmm0, xmm0, xmm0
    vmovsd   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMinF64x4(const a: TVecF64x4): Double;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovupd  ymm0, [rdx]
    // 256->128: extract high 128 and min with low 128
    vextractf128 xmm1, ymm0, 1
    vminpd   xmm0, xmm0, xmm1
    // 128->64: shuffle and min
    vshufpd  xmm1, xmm0, xmm0, 1  // swap elements
    vminsd   xmm0, xmm0, xmm1
    vmovsd   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMaxF64x4(const a: TVecF64x4): Double;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovupd  ymm0, [rdx]
    // 256->128: extract high 128 and max with low 128
    vextractf128 xmm1, ymm0, 1
    vmaxpd   xmm0, xmm0, xmm1
    // 128->64: shuffle and max
    vshufpd  xmm1, xmm0, xmm0, 1
    vmaxsd   xmm0, xmm0, xmm1
    vmovsd   [result], xmm0
    vzeroupper
  end;
end;

function AVX2ReduceMulF64x4(const a: TVecF64x4): Double;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov      rdx, pa
    vmovupd  ymm0, [rdx]
    // 256->128: extract high 128 and mul with low 128
    vextractf128 xmm1, ymm0, 1
    vmulpd   xmm0, xmm0, xmm1
    // 128->64: shuffle and mul
    vshufpd  xmm1, xmm0, xmm0, 1
    vmulsd   xmm0, xmm0, xmm1
    vmovsd   [result], xmm0
    vzeroupper
  end;
end;

// === F64x4 Extended Math Operations (256-bit AVX) ===

function AVX2FmaF64x4(const a, b, c: TVecF64x4): TVecF64x4;
var
  pa, pb, pc, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  pc := @c;
  if HasFeature(gfFMA) then
  begin
    asm
      mov     rax, pr
      mov     rdx, pa
      mov     rcx, pb
      mov     r8, pc
      vmovupd ymm0, [r8]            // ymm0 = c
      vmovupd ymm1, [rdx]           // ymm1 = a
      vfmadd231pd ymm0, ymm1, [rcx] // ymm0 = a*b + c (fused)
      vmovupd [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarFmaF64x4(a, b, c);
end;

function AVX2FloorF64x4(const a: TVecF64x4): TVecF64x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovupd  ymm0, [rdx]
      vroundpd ymm0, ymm0, 1   // floor = round toward -inf
      vmovupd  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarFloorF64x4(a);
end;

function AVX2CeilF64x4(const a: TVecF64x4): TVecF64x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovupd  ymm0, [rdx]
      vroundpd ymm0, ymm0, 2   // ceil = round toward +inf
      vmovupd  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarCeilF64x4(a);
end;

function AVX2RoundF64x4(const a: TVecF64x4): TVecF64x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovupd  ymm0, [rdx]
      vroundpd ymm0, ymm0, 0   // round to nearest even
      vmovupd  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarRoundF64x4(a);
end;

function AVX2TruncF64x4(const a: TVecF64x4): TVecF64x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  if HasSSE41 then
  begin
    asm
      mov      rax, pr
      mov      rdx, pa
      vmovupd  ymm0, [rdx]
      vroundpd ymm0, ymm0, 3   // truncate = round toward zero
      vmovupd  [rax], ymm0
      vzeroupper
    end;
  end
  else
    Result := ScalarTruncF64x4(a);
end;

// === F64x4 Load/Store/Splat/Zero Operations (256-bit AVX) ===

function AVX2LoadF64x4(p: PDouble): TVecF64x4;
var
  pr: Pointer;
begin
  Assert(p <> nil, 'AVX2LoadF64x4: pointer is nil');
  pr := @Result;
  asm
    mov     rax, pr
    mov     rdx, p
    vmovupd ymm0, [rdx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

procedure AVX2StoreF64x4(p: PDouble; const a: TVecF64x4);
var
  pa: Pointer;
begin
  Assert(p <> nil, 'AVX2StoreF64x4: pointer is nil');
  pa := @a;
  asm
    mov     rax, p
    mov     rdx, pa
    vmovupd ymm0, [rdx]
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SplatF64x4(value: Double): TVecF64x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov          rax, pr
    movsd        xmm0, value
    vbroadcastsd ymm0, xmm0     // broadcast to all 4 lanes
    vmovupd      [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ZeroF64x4: TVecF64x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov     rax, pr
    vxorpd  ymm0, ymm0, ymm0
    vmovupd [rax], ymm0
    vzeroupper
  end;
end;

// === I32x8 Operations (native 256-bit AVX2) ===

function AVX2AddI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpaddd  ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SubI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpsubd  ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MulI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpmulld ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

// I32x8 Bitwise Operations

function AVX2AndI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpand   ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2OrI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpor    ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2XorI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpxor   ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2NotI32x8(const a: TVecI32x8): TVecI32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vpcmpeqd ymm1, ymm1, ymm1   // all 1s
    vmovdqu ymm0, [rdx]
    vpxor   ymm0, ymm0, ymm1    // NOT = XOR with all 1s
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2AndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpandn  ymm0, ymm0, [rcx]   // (NOT a) AND b
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

// I32x8 Shift Operations

function AVX2ShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vmovd   xmm1, count
    vpslld  ymm0, ymm0, xmm1
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vmovd   xmm1, count
    vpsrld  ymm0, ymm0, xmm1    // Logical right shift
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
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
    for i := 0 to 7 do
      if a.i[i] < 0 then
        Result.i[i] := -1
      else
        Result.i[i] := 0;
    Exit;
  end;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu ymm0, [rdx]
    vmovd   xmm1, count
    vpsrad  ymm0, ymm0, xmm1    // Arithmetic right shift
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

// I32x8 Comparison Operations

function AVX2CmpEqI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpeqd ymm0, ymm0, [rcx]
    vmovmskps eax, ymm0         // Extract sign bits (1 bit per 32-bit element)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpLtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a < b is equivalent to b > a
  asm
    mov     rdx, pb
    mov     rcx, pa
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]  // b > a
    vmovmskps eax, ymm0
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpGtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]
    vmovmskps eax, ymm0
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

// ✅ P0-2: 补充缺失的比较函数
function AVX2CmpLeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a <= b is equivalent to NOT(a > b)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]   // a > b
    vmovmskps eax, ymm0
    xor     eax, $FF              // NOT (8 bits for 8 elements)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpGeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a >= b is equivalent to NOT(a < b) = NOT(b > a)
  asm
    mov     rdx, pb
    mov     rcx, pa
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]   // b > a = a < b
    vmovmskps eax, ymm0
    xor     eax, $FF              // NOT (8 bits for 8 elements)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpNeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a != b is equivalent to NOT(a == b)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpeqd ymm0, ymm0, [rcx]   // a == b
    vmovmskps eax, ymm0
    xor     eax, $FF              // NOT (8 bits for 8 elements)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

// I32x8 Min/Max Operations

function AVX2MinI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpminsd ymm0, ymm0, [rcx]   // Signed min
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MaxI32x8(const a, b: TVecI32x8): TVecI32x8;
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
    vmovdqu ymm0, [rdx]
    vpmaxsd ymm0, ymm0, [rcx]   // Signed max
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

// === AVX2 Memory Functions (256-bit) ===

function MemEqual_AVX2(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
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

function MemFindByte_AVX2(p: Pointer; len: SizeUInt; value: Byte): PtrInt; assembler; nostackframe;
// RDI = p, RSI = len, RDX = value
asm
  mov rax, -1            // Default result = -1 (not found)
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 32 bytes in ymm1
  vmovd xmm1, edx
  vpbroadcastb ymm1, xmm1

  xor rcx, rcx           // i = 0

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

function SumBytes_AVX2(p: Pointer; len: SizeUInt): UInt64; assembler; nostackframe;
// RDI = p, RSI = len
// Use vpsadbw for fast byte summation
asm
  xor rax, rax           // sum = 0
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  vpxor ymm2, ymm2, ymm2 // accumulator
  vpxor ymm3, ymm3, ymm3 // zero for psadbw
  xor rcx, rcx           // i = 0

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
  // Before 128-bit loop, reduce 256-bit accumulator to avoid losing high bits
  vextracti128 xmm4, ymm2, 1    // xmm4 = high 128 bits of ymm2
  vpaddq xmm2, xmm2, xmm4        // xmm2 = sum of high and low (now only 128-bit)

@loop16_inner:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  vmovdqu xmm0, [rdi + rcx]
  vpsadbw xmm0, xmm0, xmm3
  vpaddq xmm2, xmm2, xmm0
  add rcx, 16
  jmp @loop16_inner

@remainder:
  // Sum the 128-bit accumulator (2 x 64-bit values in xmm2)
  vpshufd xmm1, xmm2, $4E      // swap high/low 64-bit
  vpaddq xmm0, xmm2, xmm1
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

function CountByte_AVX2(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; assembler; nostackframe;
// RDI = p, RSI = len, RDX = value
// Use popcnt instruction (available on all AVX2 CPUs)
asm
  xor rax, rax           // count = 0
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 32 bytes in ymm1
  vmovd xmm1, edx
  vpbroadcastb ymm1, xmm1

  xor rcx, rcx           // i = 0

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

// MinMaxBytes_AVX2 - 使用 AVX2 vpminub/vpmaxub 指令查找字节数组的最小和最大值
// 使用 256 位宽向量一次处理 32 字节
procedure MinMaxBytes_AVX2(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte); assembler; nostackframe;
asm
  // 参数: RDI = p, RSI = len, RDX = &minVal, RCX = &maxVal
  // 保存 minVal 和 maxVal 指针
  push rbx
  mov r8, rdx       // r8 = &minVal
  mov r9, rcx       // r9 = &maxVal
  
  // 边界检查
  test rsi, rsi
  jz @empty
  
  // 初始化 min = 255, max = 0
  mov al, 255
  mov bl, 0
  
  // 如果长度 < 32，跳到标量处理
  cmp rsi, 32
  jb @scalar_loop
  
  // 初始化 YMM 寄存器
  // ymm0 = min (全 255)
  // ymm1 = max (全 0)
  vpcmpeqb ymm0, ymm0, ymm0   // ymm0 = all 1s (255)
  vpxor ymm1, ymm1, ymm1       // ymm1 = all 0s
  
  // 计算向量循环次数
  mov rcx, rsi
  shr rcx, 5            // rcx = len / 32
  
  // 向量主循环
@vector_loop:
  vmovdqu ymm2, [rdi]   // 加载 32 字节
  vpminub ymm0, ymm0, ymm2    // min = min(min, data)
  vpmaxub ymm1, ymm1, ymm2    // max = max(max, data)
  add rdi, 32
  dec rcx
  jnz @vector_loop
  
  // 水平归约 256 位到标量
  // 提取高低 128 位并比较
  vextracti128 xmm2, ymm0, 1    // xmm2 = high 128 of ymm0
  vextracti128 xmm3, ymm1, 1    // xmm3 = high 128 of ymm1
  vpminub xmm0, xmm0, xmm2      // xmm0 = min of high and low
  vpmaxub xmm1, xmm1, xmm3      // xmm1 = max of high and low
  
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
  and rsi, 31           // len % 32
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

// BitsetPopCount_AVX2 - 使用 POPCNT 指令计算位集中置 1 的位数
// 一次处理 8 字节（64位）使用硬件 POPCNT 指令
function BitsetPopCount_AVX2(p: Pointer; len: SizeUInt): SizeUInt; assembler; nostackframe;
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

// Utf8Validate_AVX2 - UTF-8 验证的混合实现
// 策略：使用 AVX2 快速检测纯 ASCII 路径，包含非 ASCII 字符时回退到标量验证
// 这是一种实用优化，因为大量实际文本数据是纯 ASCII
function Utf8Validate_AVX2(p: Pointer; len: SizeUInt): Boolean;
type
  TByteArray = array[0..MaxInt-1] of Byte;
  PByteArray = ^TByteArray;
var
  pData: PByteArray;
  remaining: SizeUInt;
  hasNonASCII: Boolean;
  i: SizeUInt;
  mask: UInt32;
  pCurrent: Pointer;
  usedYMM: Boolean;
begin
  // 边界检查
  if (len = 0) then Exit(True);
  if (p = nil) then Exit(False);

  pData := PByteArray(p);
  pCurrent := p;
  remaining := len;
  hasNonASCII := False;
  usedYMM := False;

  // 阶段 1：使用 AVX2 快速检查是否全为 ASCII
  // 一次处理 32 字节，检查最高位是否为 0
  while remaining >= 32 do
  begin
    usedYMM := True;
    asm
      mov rax, pCurrent
      vmovdqu ymm0, [rax]         // 加载 32 字节
      vpmovmskb eax, ymm0         // 提取每个字节的最高位
      mov mask, eax
    end;

    if mask <> 0 then
    begin
      // 发现非 ASCII 字节
      hasNonASCII := True;
      Break;
    end;

    Inc(pCurrent, 32);
    Dec(remaining, 32);
  end;

  // 如果全部是 ASCII，继续检查剩余字节
  if not hasNonASCII then
  begin
    // 检查剩余字节 (0-31)
    if remaining > 0 then
    begin
      pData := PByteArray(pCurrent);
      for i := 0 to remaining - 1 do
      begin
        if pData^[i] >= $80 then
        begin
          hasNonASCII := True;
          // 从这个位置开始使用标量验证
          Break;
        end;
      end;
    end;

    if not hasNonASCII then
    begin
      // 全部是 ASCII，有效 - 确保在退出前调用 vzeroupper
      if usedYMM then
        asm
          vzeroupper
        end;
      Exit(True);
    end;

    // 调整位置
    Inc(pCurrent, i);
    Dec(remaining, i);
  end;

  // 阶段 2：包含非 ASCII，回退到完整的标量 UTF-8 验证
  // 确保在退出前调用 vzeroupper
  if usedYMM then
    asm
      vzeroupper
    end;

  Result := Utf8Validate_Scalar(pCurrent, remaining);
end;

// MemReverse_AVX2 - 使用标量字节反转（优化版本）
// 策略: 从两端向中间交换，利用 bswap 一次处理 8 字节
procedure MemReverse_AVX2(p: Pointer; len: SizeUInt); assembler; nostackframe;
asm
  // RDI = p, RSI = len
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done
  cmp rsi, 1
  je @done
  
  // pLeft = p, pRight = p + len - 1
  mov rax, rdi               // rax = pLeft
  lea rdx, [rdi + rsi - 1]   // rdx = pRight
  
  // 主循环: 一次交换 8 字节 (64-bit)
@loop8:
  lea rcx, [rax + 8]
  cmp rcx, rdx
  ja @loop1
  
  // 加载左右各 8 字节
  mov r8, qword ptr [rax]      // left 8 bytes
  mov r9, qword ptr [rdx - 7]  // right 8 bytes (rdx 指向最后一个字节)
  
  // 使用 bswap 反转字节序
  bswap r8
  bswap r9
  
  // 交换写回
  mov qword ptr [rax], r9
  mov qword ptr [rdx - 7], r8
  
  add rax, 8
  sub rdx, 8
  jmp @loop8
  
  // 处理剩余字节: 一次交换 1 字节
@loop1:
  cmp rax, rdx
  jae @done
  
  movzx ecx, byte ptr [rax]
  movzx r8d, byte ptr [rdx]
  mov byte ptr [rax], r8b
  mov byte ptr [rdx], cl
  
  inc rax
  dec rdx
  jmp @loop1
  
@done:
end;

// AsciiIEqual_AVX2 - 向量化 ASCII 大小写不敏感比较
// 策略: 将两边都转为小写后比较
function AsciiIEqual_AVX2(a, b: Pointer; len: SizeUInt): Boolean; assembler; nostackframe;
asm
  // RDI = a, RSI = b, RDX = len
  mov rax, 1             // 默认 true
  
  test rdx, rdx
  jz @done
  test rdi, rdi
  jz @check_both_nil
  test rsi, rsi
  jz @false
  cmp rdi, rsi
  je @done               // 同一指针
  
  // 准备常量:
  // 'A' = 65, 'Z' = 90, 差值 = 32
  mov r8d, 64            // 'A' - 1
  vmovd xmm2, r8d
  vpbroadcastb ymm2, xmm2  // ymm2 = all 64 ('A'-1)
  
  mov r8d, 91            // 'Z' + 1  
  vmovd xmm3, r8d
  vpbroadcastb ymm3, xmm3  // ymm3 = all 91 ('Z'+1)
  
  mov r8d, 32
  vmovd xmm4, r8d
  vpbroadcastb ymm4, xmm4  // ymm4 = all 32 (大小写差)
  
  xor rcx, rcx           // i = 0
  
@loop32:
  lea r8, [rcx + 32]
  cmp r8, rdx
  ja @loop_remainder
  
  // 加载 32 字节
  vmovdqu ymm0, [rdi + rcx]  // a
  vmovdqu ymm1, [rsi + rcx]  // b
  
  // 将 a 转为小写: 如果在 A-Z 范围，加 32
  vpcmpgtb ymm5, ymm0, ymm2      // a > 'A'-1
  vpcmpgtb ymm6, ymm3, ymm0      // 'Z'+1 > a
  vpand ymm5, ymm5, ymm6          // 在 A-Z 范围内
  vpand ymm5, ymm5, ymm4          // 掩码 & 32
  vpaddb ymm0, ymm0, ymm5         // a += 32 (if A-Z)
  
  // 将 b 转为小写
  vpcmpgtb ymm5, ymm1, ymm2
  vpcmpgtb ymm6, ymm3, ymm1
  vpand ymm5, ymm5, ymm6
  vpand ymm5, ymm5, ymm4
  vpaddb ymm1, ymm1, ymm5
  
  // 比较
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb r8d, ymm0
  cmp r8d, $FFFFFFFF
  jne @false_cleanup
  
  add rcx, 32
  jmp @loop32
  
@loop_remainder:
  vzeroupper
  cmp rcx, rdx
  jae @done
  
  // 标量处理剩余字节
@scalar_loop:
  movzx r8d, byte ptr [rdi + rcx]
  movzx r9d, byte ptr [rsi + rcx]
  
  // 转小写
  cmp r8d, 65
  jb @skip_lower1
  cmp r8d, 90
  ja @skip_lower1
  add r8d, 32
@skip_lower1:
  cmp r9d, 65
  jb @skip_lower2
  cmp r9d, 90
  ja @skip_lower2
  add r9d, 32
@skip_lower2:
  
  cmp r8d, r9d
  jne @false
  
  inc rcx
  cmp rcx, rdx
  jb @scalar_loop
  jmp @done
  
@check_both_nil:
  test rsi, rsi
  jnz @false
  jmp @done
  
@false_cleanup:
  vzeroupper
@false:
  xor eax, eax
@done:
end;

// ToLowerAscii_AVX2 - 向量化 ASCII 大写转小写
procedure ToLowerAscii_AVX2(p: Pointer; len: SizeUInt); assembler; nostackframe;
asm
  // RDI = p, RSI = len
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done
  
  // 准备常量
  mov eax, 64            // 'A' - 1
  vmovd xmm2, eax
  vpbroadcastb ymm2, xmm2
  
  mov eax, 91            // 'Z' + 1
  vmovd xmm3, eax
  vpbroadcastb ymm3, xmm3
  
  mov eax, 32
  vmovd xmm4, eax
  vpbroadcastb ymm4, xmm4
  
  xor rcx, rcx
  
@loop32:
  lea rax, [rcx + 32]
  cmp rax, rsi
  ja @remainder
  
  vmovdqu ymm0, [rdi + rcx]
  vpcmpgtb ymm5, ymm0, ymm2      // > 'A'-1
  vpcmpgtb ymm6, ymm3, ymm0      // < 'Z'+1
  vpand ymm5, ymm5, ymm6          // in A-Z
  vpand ymm5, ymm5, ymm4          // mask & 32
  vpaddb ymm0, ymm0, ymm5         // += 32
  vmovdqu [rdi + rcx], ymm0
  
  add rcx, 32
  jmp @loop32
  
@remainder:
  vzeroupper
  cmp rcx, rsi
  jae @done
  
@scalar_loop:
  movzx eax, byte ptr [rdi + rcx]
  cmp eax, 65
  jb @skip
  cmp eax, 90
  ja @skip
  add eax, 32
  mov byte ptr [rdi + rcx], al
@skip:
  inc rcx
  cmp rcx, rsi
  jb @scalar_loop
  
@done:
end;

// ToUpperAscii_AVX2 - 向量化 ASCII 小写转大写
procedure ToUpperAscii_AVX2(p: Pointer; len: SizeUInt); assembler; nostackframe;
asm
  // RDI = p, RSI = len
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done
  
  // 准备常量: 'a' = 97, 'z' = 122
  mov eax, 96            // 'a' - 1
  vmovd xmm2, eax
  vpbroadcastb ymm2, xmm2
  
  mov eax, 123           // 'z' + 1
  vmovd xmm3, eax
  vpbroadcastb ymm3, xmm3
  
  mov eax, 32
  vmovd xmm4, eax
  vpbroadcastb ymm4, xmm4
  
  xor rcx, rcx
  
@loop32:
  lea rax, [rcx + 32]
  cmp rax, rsi
  ja @remainder
  
  vmovdqu ymm0, [rdi + rcx]
  vpcmpgtb ymm5, ymm0, ymm2      // > 'a'-1
  vpcmpgtb ymm6, ymm3, ymm0      // < 'z'+1
  vpand ymm5, ymm5, ymm6          // in a-z
  vpand ymm5, ymm5, ymm4          // mask & 32
  vpsubb ymm0, ymm0, ymm5         // -= 32
  vmovdqu [rdi + rcx], ymm0
  
  add rcx, 32
  jmp @loop32
  
@remainder:
  vzeroupper
  cmp rcx, rsi
  jae @done
  
@scalar_loop:
  movzx eax, byte ptr [rdi + rcx]
  cmp eax, 97
  jb @skip
  cmp eax, 122
  ja @skip
  sub eax, 32
  mov byte ptr [rdi + rcx], al
@skip:
  inc rcx
  cmp rcx, rsi
  jb @scalar_loop
  
@done:
end;

// MemCopy_AVX2 - 使用 FPC 内置 Move 函数（已足够优化）
// 提供此接口保持 API 一致性，实际调用 FPC 运行时库
procedure MemCopy_AVX2(src, dst: Pointer; len: SizeUInt);
begin
  if (len = 0) or (src = nil) or (dst = nil) then
    Exit;
  Move(src^, dst^, len);
end;

// MemSet_AVX2 - 使用 FPC 内置 FillChar 函数（已足够优化）
// 提供此接口保持 API 一致性，实际调用 FPC 运行时库
procedure MemSet_AVX2(dst: Pointer; len: SizeUInt; value: Byte);
begin
  if (len = 0) or (dst = nil) then
    Exit;
  FillChar(dst^, len, value);
end;

// MemDiffRange_AVX2 - 向量化查找两个缓冲区第一个和最后一个不同字节的位置
// 策略: 使用 AVX2 vpcmpeqb 比较 32 字节，找到不等的位置
function MemDiffRange_AVX2(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
var
  pa, pb: PByte;
  i, blockStart: SizeUInt;
  mask: UInt32;
  foundFirst: Boolean;
  firstPos, lastPos: SizeUInt;
begin
  firstDiff := 0;
  lastDiff := 0;
  Result := False;
  
  if len = 0 then Exit;
  
  if (a = nil) or (b = nil) then
  begin
    if a <> b then
    begin
      firstDiff := 0;
      lastDiff := len - 1;
      Result := True;
    end;
    Exit;
  end;
  
  pa := PByte(a);
  pb := PByte(b);
  foundFirst := False;
  firstPos := 0;
  lastPos := 0;
  i := 0;
  
  // 向量循环: 一次处理 32 字节
  while i + 32 <= len do
  begin
    asm
      mov rax, pa
      add rax, i
      mov rdx, pb
      add rdx, i
      vmovdqu ymm0, [rax]
      vpcmpeqb ymm0, ymm0, [rdx]
      vpmovmskb eax, ymm0
      not eax               // 反转: 1 表示不等
      mov mask, eax
    end;
    
    if mask <> 0 then
    begin
      // 找到不等字节
      blockStart := i;
      
      // 找第一个不等位置
      if not foundFirst then
      begin
        asm
          mov eax, mask
          bsf eax, eax       // 找第一个置位
          mov firstPos, rax
        end;
        firstPos := blockStart + firstPos;
        foundFirst := True;
      end;
      
      // 更新最后一个不等位置
      asm
        mov eax, mask
        bsr eax, eax         // 找最后一个置位
        mov lastPos, rax
      end;
      lastPos := blockStart + lastPos;
    end;
    
    Inc(i, 32);
  end;
  
  asm
    vzeroupper
  end;
  
  // 处理剩余字节
  while i < len do
  begin
    if pa[i] <> pb[i] then
    begin
      if not foundFirst then
      begin
        firstPos := i;
        foundFirst := True;
      end;
      lastPos := i;
    end;
    Inc(i);
  end;
  
  if foundFirst then
  begin
    firstDiff := firstPos;
    lastDiff := lastPos;
    Result := True;
  end;
end;

// BytesIndexOf_AVX2 - 向量化字节序列搜索
// 策略: 使用 AVX2 搜索 needle 的第一个字节，找到后验证完整匹配
function BytesIndexOf_AVX2(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
var
  ph, pn: PByte;
  i, j: SizeUInt;
  firstByte: Byte;
  mask: UInt32;
  bitPos: Integer;
  found: Boolean;
begin
  Result := -1;
  
  if (haystackLen = 0) or (needleLen = 0) or (haystack = nil) or (needle = nil) then
    Exit;
  
  if needleLen > haystackLen then
    Exit;
  
  ph := PByte(haystack);
  pn := PByte(needle);
  firstByte := pn[0];
  
  // 如果 needle 只有 1 字节，使用 MemFindByte
  if needleLen = 1 then
  begin
    Result := MemFindByte_AVX2(haystack, haystackLen, firstByte);
    Exit;
  end;
  
  i := 0;
  
  // 向量化搜索第一个字节
  while i + 32 <= haystackLen - needleLen + 1 do
  begin
    asm
      // 广播第一个字节
      movzx eax, firstByte
      vmovd xmm1, eax
      vpbroadcastb ymm1, xmm1
      
      // 加载 32 字节并比较
      mov rax, ph
      add rax, i
      vmovdqu ymm0, [rax]
      vpcmpeqb ymm0, ymm0, ymm1
      vpmovmskb eax, ymm0
      mov mask, eax
    end;
    
    // 检查每个匹配位置
    while mask <> 0 do
    begin
      asm
        mov eax, mask
        bsf eax, eax
        mov bitPos, eax
      end;
      
      // 验证完整匹配
      if i + SizeUInt(bitPos) + needleLen <= haystackLen then
      begin
        found := True;
        for j := 1 to needleLen - 1 do
        begin
          if ph[i + SizeUInt(bitPos) + j] <> pn[j] then
          begin
            found := False;
            Break;
          end;
        end;
        
        if found then
        begin
          asm
            vzeroupper
          end;
          Result := PtrInt(i + SizeUInt(bitPos));
          Exit;
        end;
      end;
      
      // 清除已检查的位
      mask := mask and not (1 shl bitPos);
    end;
    
    Inc(i, 32);
  end;
  
  asm
    vzeroupper
  end;
  
  // 标量处理剩余部分
  while i <= haystackLen - needleLen do
  begin
    if ph[i] = firstByte then
    begin
      found := True;
      for j := 1 to needleLen - 1 do
      begin
        if ph[i + j] <> pn[j] then
        begin
          found := False;
          Break;
        end;
      end;
      
      if found then
      begin
        Result := PtrInt(i);
        Exit;
      end;
    end;
    Inc(i);
  end;
end;

// === ✅ P2: Saturating Arithmetic (AVX2 VEX-encoded) ===
// 使用 VEX 编码避免 SSE-AVX 转换惩罚

// I8x16 有符号饱和加法 (VPADDSB)
function AVX2I8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  // NOTE:
  //   TVec* (16-byte variant record) 在 x86_64 上按 INTEGER 类传参/返回：
  //   - SysV:  a.lowQ=RDI, a.highQ=RSI, b.lowQ=RDX, b.highQ=RCX; return RAX/RDX
  //   - Win64: a.lowQ=RCX, a.highQ=RDX, b.lowQ=R8,  b.highQ=R9;  return RAX/RDX
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpaddsb xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// I8x16 有符号饱和减法 (VPSUBSB)
function AVX2I8x16SatSub(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpsubsb xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// I16x8 有符号饱和加法 (VPADDSW)
function AVX2I16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpaddsw xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// I16x8 有符号饱和减法 (VPSUBSW)
function AVX2I16x8SatSub(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpsubsw xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// U8x16 无符号饱和加法 (VPADDUSB)
function AVX2U8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpaddusb xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// U8x16 无符号饱和减法 (VPSUBUSB)
function AVX2U8x16SatSub(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpsubusb xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// U16x8 无符号饱和加法 (VPADDUSW)
function AVX2U16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpaddusw xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// U16x8 无符号饱和减法 (VPSUBUSW)
function AVX2U16x8SatSub(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  sub rsp, 32
  {$IFDEF UNIX}
  mov qword ptr [rsp], rdi
  mov qword ptr [rsp + 8], rsi
  mov qword ptr [rsp + 16], rdx
  mov qword ptr [rsp + 24], rcx
  {$ELSE}
  mov qword ptr [rsp], rcx
  mov qword ptr [rsp + 8], rdx
  mov qword ptr [rsp + 16], r8
  mov qword ptr [rsp + 24], r9
  {$ENDIF}
  vmovdqu xmm0, [rsp]
  vmovdqu xmm1, [rsp + 16]
  vpsubusw xmm0, xmm0, xmm1
  vmovdqu [rsp], xmm0
  mov rax, qword ptr [rsp]
  mov rdx, qword ptr [rsp + 8]
  add rsp, 32
end;

// === ✅ P3: I64x2 Arithmetic and Bitwise Operations (AVX2 VEX-encoded) ===
// 使用 VEX 编码避免 SSE-AVX 转换惩罚

// I64x2 加法 (VPADDQ)
function AVX2AddI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpaddq  xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpaddq  xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 减法 (VPSUBQ)
function AVX2SubI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpsubq  xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpsubq  xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位与 (VPAND)
function AVX2AndI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpand   xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpand   xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位或 (VPOR)
function AVX2OrI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpor    xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpor    xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位异或 (VPXOR)
function AVX2XorI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu xmm0, [rdi]
  vmovdqu xmm1, [rsi]
  vpxor   xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ELSE}
  vmovdqu xmm0, [rcx]
  vmovdqu xmm1, [rdx]
  vpxor   xmm0, xmm0, xmm1
  vmovdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位非 (VPXOR with all 1s)
function AVX2NotI64x2(const a: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  vmovdqu  xmm0, [rdi]
  vpcmpeqd xmm1, xmm1, xmm1    // all 1s
  vpxor    xmm0, xmm0, xmm1    // NOT = XOR with all 1s
  vmovdqu  [rax], xmm0
  {$ELSE}
  vmovdqu  xmm0, [rcx]
  vpcmpeqd xmm1, xmm1, xmm1
  vpxor    xmm0, xmm0, xmm1
  vmovdqu  [rax], xmm0
  {$ENDIF}
end;

// I64x2 相等比较 (VPCMPEQQ - requires AVX2)
function AVX2CmpEqI64x2(const a, b: TVecI64x2): TMask2;
var maskVal: Integer;
begin
  asm
    lea rax, a
    lea rdx, b
    vmovdqu  xmm0, [rax]
    vmovdqu  xmm1, [rdx]
    vpcmpeqq xmm0, xmm0, xmm1
    vmovmskpd eax, xmm0
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// I64x2 大于比较 (VPCMPGTQ - requires AVX2)
function AVX2CmpGtI64x2(const a, b: TVecI64x2): TMask2;
var maskVal: Integer;
begin
  asm
    lea rax, a
    lea rdx, b
    vmovdqu  xmm0, [rax]
    vmovdqu  xmm1, [rdx]
    vpcmpgtq xmm0, xmm0, xmm1
    vmovmskpd eax, xmm0
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// I64x2 小于比较 (a < b = b > a)
function AVX2CmpLtI64x2(const a, b: TVecI64x2): TMask2;
var maskVal: Integer;
begin
  asm
    lea rax, b     // swap: load b first
    lea rdx, a
    vmovdqu  xmm0, [rax]
    vmovdqu  xmm1, [rdx]
    vpcmpgtq xmm0, xmm0, xmm1  // b > a
    vmovmskpd eax, xmm0
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// I64x2 小于等于 (a <= b = NOT(a > b))
function AVX2CmpLeI64x2(const a, b: TVecI64x2): TMask2;
var maskVal: Integer;
begin
  asm
    lea rax, a
    lea rdx, b
    vmovdqu  xmm0, [rax]
    vmovdqu  xmm1, [rdx]
    vpcmpgtq xmm0, xmm0, xmm1  // a > b
    vmovmskpd eax, xmm0
    xor      eax, 3           // NOT (2 bits)
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// I64x2 大于等于 (a >= b = NOT(a < b) = NOT(b > a))
function AVX2CmpGeI64x2(const a, b: TVecI64x2): TMask2;
var maskVal: Integer;
begin
  asm
    lea rax, b     // swap: load b first
    lea rdx, a
    vmovdqu  xmm0, [rax]
    vmovdqu  xmm1, [rdx]
    vpcmpgtq xmm0, xmm0, xmm1  // b > a = a < b
    vmovmskpd eax, xmm0
    xor      eax, 3           // NOT
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// I64x2 不等比较 (a != b = NOT(a == b))
function AVX2CmpNeI64x2(const a, b: TVecI64x2): TMask2;
var maskVal: Integer;
begin
  asm
    lea rax, a
    lea rdx, b
    vmovdqu  xmm0, [rax]
    vmovdqu  xmm1, [rdx]
    vpcmpeqq xmm0, xmm0, xmm1
    vmovmskpd eax, xmm0
    xor      eax, 3           // NOT
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// === ✅ P1: Mask Operations SIMD Implementation (AVX2) ===
// AVX2 CPU 都支持 popcnt 指令（SSE4.2），可以使用原生指令
// 使用 bsf (bit scan forward) 和 popcnt 指令

// --- TMask2 Operations (2 bits) ---
function AVX2Mask2All(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3
  cmp   edi, 3
  sete  al
  {$ELSE}
  and   ecx, 3
  cmp   ecx, 3
  sete  al
  {$ENDIF}
end;

function AVX2Mask2Any(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 3
  setne al
  {$ELSE}
  test  ecx, 3
  setne al
  {$ENDIF}
end;

function AVX2Mask2None(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 3
  sete  al
  {$ELSE}
  test  ecx, 3
  sete  al
  {$ENDIF}
end;

function AVX2Mask2PopCount(mask: TMask2): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3
  popcnt eax, edi    // 原生 popcnt 指令
  {$ELSE}
  and   ecx, 3
  popcnt eax, ecx
  {$ENDIF}
end;

function AVX2Mask2FirstSet(mask: TMask2): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  and   ecx, 3
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask4 Operations (4 bits) ---
function AVX2Mask4All(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 15
  cmp   edi, 15
  sete  al
  {$ELSE}
  and   ecx, 15
  cmp   ecx, 15
  sete  al
  {$ENDIF}
end;

function AVX2Mask4Any(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 15
  setne al
  {$ELSE}
  test  ecx, 15
  setne al
  {$ENDIF}
end;

function AVX2Mask4None(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 15
  sete  al
  {$ELSE}
  test  ecx, 15
  sete  al
  {$ENDIF}
end;

function AVX2Mask4PopCount(mask: TMask4): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 15
  popcnt eax, edi
  {$ELSE}
  and   ecx, 15
  popcnt eax, ecx
  {$ENDIF}
end;

function AVX2Mask4FirstSet(mask: TMask4): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 15
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  and   ecx, 15
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask8 Operations (8 bits) ---
function AVX2Mask8All(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  cmp   dil, $FF
  sete  al
  {$ELSE}
  cmp   cl, $FF
  sete  al
  {$ENDIF}
end;

function AVX2Mask8Any(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  dil, dil
  setne al
  {$ELSE}
  test  cl, cl
  setne al
  {$ENDIF}
end;

function AVX2Mask8None(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  dil, dil
  sete  al
  {$ELSE}
  test  cl, cl
  sete  al
  {$ENDIF}
end;

function AVX2Mask8PopCount(mask: TMask8): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, dil
  popcnt eax, edi
  {$ELSE}
  movzx ecx, cl
  popcnt eax, ecx
  {$ENDIF}
end;

function AVX2Mask8FirstSet(mask: TMask8): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, dil
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  movzx ecx, cl
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask16 Operations (16 bits) ---
function AVX2Mask16All(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  cmp   di, $FFFF
  sete  al
  {$ELSE}
  cmp   cx, $FFFF
  sete  al
  {$ENDIF}
end;

function AVX2Mask16Any(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  di, di
  setne al
  {$ELSE}
  test  cx, cx
  setne al
  {$ENDIF}
end;

function AVX2Mask16None(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  di, di
  sete  al
  {$ELSE}
  test  cx, cx
  sete  al
  {$ENDIF}
end;

function AVX2Mask16PopCount(mask: TMask16): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, di
  popcnt eax, edi
  {$ELSE}
  movzx ecx, cx
  popcnt eax, ecx
  {$ENDIF}
end;

function AVX2Mask16FirstSet(mask: TMask16): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, di
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  movzx ecx, cx
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// === ✅ P4: SelectF64x2 SIMD Implementation ===
// 使用 vblendvpd 进行掩码混合 (AVX 指令集)
// mask 位 0 控制元素 0，位 1 控制元素 1
// 位为 1 时选择 a，位为 0 时选择 b
function AVX2SelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var
  expandedMask: TVecI64x2;
begin
  // 将 mask 扩展为 64-bit 掩码 (最高位需要为 1 表示选择第一个源)
  if (mask and 1) <> 0 then expandedMask.i[0] := Int64($8000000000000000) else expandedMask.i[0] := 0;
  if (mask and 2) <> 0 then expandedMask.i[1] := Int64($8000000000000000) else expandedMask.i[1] := 0;

  // vblendvpd: if mask bit set, select from first source (a), else from second (b)
  asm
    lea rax, a
    lea rdx, b
    lea rcx, expandedMask

    vmovupd xmm0, [rax]      // a (first source)
    vmovupd xmm1, [rdx]      // b (second source)  
    vmovdqu xmm2, [rcx]      // expanded mask

    // vblendvpd xmm0, xmm1, xmm0, xmm2
    // Result = mask[i] ? xmm0[i] : xmm1[i]
    vblendvpd xmm0, xmm1, xmm0, xmm2

    vmovupd [result], xmm0
    vzeroupper
  end;
end;

// === Backend Registration ===

procedure RegisterAVX2Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if AVX2 is available
  if not HasAVX2 then
    Exit;

  // Fill with base scalar implementations (provides fallback for all operations)
  dispatchTable := Default(TSimdDispatchTable);
  FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbAVX2;
  dispatchTable.BackendInfo.Backend := sbAVX2;
  dispatchTable.BackendInfo.Name := 'AVX2';
  dispatchTable.BackendInfo.Description := 'x86-64 AVX2 SIMD implementation (256-bit)';
  dispatchTable.BackendInfo.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction, scLoadStore];
  dispatchTable.BackendInfo.Available := True;
  dispatchTable.BackendInfo.Priority := 20; // Higher than SSE2

  // Vector-related operations default to Scalar reference implementations.
  // You can enable AVX2 vector ops for experimentation via SetVectorAsmEnabled(True)
  // (note: AVX2 asm path is not yet fully validated under FPC's calling conventions).

  if IsVectorAsmEnabled then
  begin
    // Override with AVX2 arithmetic operations
    dispatchTable.AddF32x4 := @AVX2AddF32x4;
    dispatchTable.SubF32x4 := @AVX2SubF32x4;
    dispatchTable.MulF32x4 := @AVX2MulF32x4;
    dispatchTable.DivF32x4 := @AVX2DivF32x4;

    dispatchTable.AddF32x8 := @AVX2AddF32x8;
    dispatchTable.SubF32x8 := @AVX2SubF32x8;
    dispatchTable.MulF32x8 := @AVX2MulF32x8;
    dispatchTable.DivF32x8 := @AVX2DivF32x8;

    dispatchTable.AddF64x2 := @AVX2AddF64x2;
    dispatchTable.SubF64x2 := @AVX2SubF64x2;
    dispatchTable.MulF64x2 := @AVX2MulF64x2;
    dispatchTable.DivF64x2 := @AVX2DivF64x2;

    dispatchTable.AddI32x4 := @AVX2AddI32x4;
    dispatchTable.SubI32x4 := @AVX2SubI32x4;
    dispatchTable.MulI32x4 := @AVX2MulI32x4;
    // I32x4 Bitwise operations
    dispatchTable.AndI32x4 := @AVX2AndI32x4;
    dispatchTable.OrI32x4 := @AVX2OrI32x4;
    dispatchTable.XorI32x4 := @AVX2XorI32x4;
    dispatchTable.NotI32x4 := @AVX2NotI32x4;
    dispatchTable.AndNotI32x4 := @AVX2AndNotI32x4;
    // I32x4 Shift operations
    dispatchTable.ShiftLeftI32x4 := @AVX2ShiftLeftI32x4;
    dispatchTable.ShiftRightI32x4 := @AVX2ShiftRightI32x4;
    dispatchTable.ShiftRightArithI32x4 := @AVX2ShiftRightArithI32x4;
    // I32x4 Comparison operations
    dispatchTable.CmpEqI32x4 := @AVX2CmpEqI32x4;
    dispatchTable.CmpLtI32x4 := @AVX2CmpLtI32x4;
    dispatchTable.CmpGtI32x4 := @AVX2CmpGtI32x4;
    dispatchTable.CmpLeI32x4 := @AVX2CmpLeI32x4;
    dispatchTable.CmpGeI32x4 := @AVX2CmpGeI32x4;
    dispatchTable.CmpNeI32x4 := @AVX2CmpNeI32x4;
    // I32x4 Min/Max operations
    dispatchTable.MinI32x4 := @AVX2MinI32x4;
    dispatchTable.MaxI32x4 := @AVX2MaxI32x4;

    // ✅ P3: I64x2 arithmetic, bitwise, and comparison
    dispatchTable.AddI64x2 := @AVX2AddI64x2;
    dispatchTable.SubI64x2 := @AVX2SubI64x2;
    dispatchTable.AndI64x2 := @AVX2AndI64x2;
    dispatchTable.OrI64x2 := @AVX2OrI64x2;
    dispatchTable.XorI64x2 := @AVX2XorI64x2;
    dispatchTable.NotI64x2 := @AVX2NotI64x2;
    dispatchTable.CmpEqI64x2 := @AVX2CmpEqI64x2;
    dispatchTable.CmpLtI64x2 := @AVX2CmpLtI64x2;
    dispatchTable.CmpGtI64x2 := @AVX2CmpGtI64x2;
    dispatchTable.CmpLeI64x2 := @AVX2CmpLeI64x2;
    dispatchTable.CmpGeI64x2 := @AVX2CmpGeI64x2;
    dispatchTable.CmpNeI64x2 := @AVX2CmpNeI64x2;

    // F64x4 (256-bit AVX)
    dispatchTable.AddF64x4 := @AVX2AddF64x4;
    dispatchTable.SubF64x4 := @AVX2SubF64x4;
    dispatchTable.MulF64x4 := @AVX2MulF64x4;
    dispatchTable.DivF64x4 := @AVX2DivF64x4;

    // I32x8 (256-bit AVX2)
    dispatchTable.AddI32x8 := @AVX2AddI32x8;
    dispatchTable.SubI32x8 := @AVX2SubI32x8;
    dispatchTable.MulI32x8 := @AVX2MulI32x8;
    dispatchTable.AndI32x8 := @AVX2AndI32x8;
    dispatchTable.OrI32x8 := @AVX2OrI32x8;
    dispatchTable.XorI32x8 := @AVX2XorI32x8;
    dispatchTable.NotI32x8 := @AVX2NotI32x8;
    dispatchTable.AndNotI32x8 := @AVX2AndNotI32x8;
    dispatchTable.ShiftLeftI32x8 := @AVX2ShiftLeftI32x8;
    dispatchTable.ShiftRightI32x8 := @AVX2ShiftRightI32x8;
    dispatchTable.ShiftRightArithI32x8 := @AVX2ShiftRightArithI32x8;
    dispatchTable.CmpEqI32x8 := @AVX2CmpEqI32x8;
    dispatchTable.CmpLtI32x8 := @AVX2CmpLtI32x8;
    dispatchTable.CmpGtI32x8 := @AVX2CmpGtI32x8;
    dispatchTable.CmpLeI32x8 := @AVX2CmpLeI32x8;  // ✅ P0-2: 补充缺失
    dispatchTable.CmpGeI32x8 := @AVX2CmpGeI32x8;  // ✅ P0-2: 补充缺失
    dispatchTable.CmpNeI32x8 := @AVX2CmpNeI32x8;  // ✅ P0-2: 补充缺失
    dispatchTable.MinI32x8 := @AVX2MinI32x8;
    dispatchTable.MaxI32x8 := @AVX2MaxI32x8;

    // Override with AVX2 comparison operations
    dispatchTable.CmpEqF32x4 := @AVX2CmpEqF32x4;
    dispatchTable.CmpLtF32x4 := @AVX2CmpLtF32x4;
    dispatchTable.CmpLeF32x4 := @AVX2CmpLeF32x4;
    dispatchTable.CmpGtF32x4 := @AVX2CmpGtF32x4;
    dispatchTable.CmpGeF32x4 := @AVX2CmpGeF32x4;
    dispatchTable.CmpNeF32x4 := @AVX2CmpNeF32x4;

    // Override with AVX2 math functions
    dispatchTable.AbsF32x4 := @AVX2AbsF32x4;
    dispatchTable.SqrtF32x4 := @AVX2SqrtF32x4;
    dispatchTable.MinF32x4 := @AVX2MinF32x4;
    dispatchTable.MaxF32x4 := @AVX2MaxF32x4;

    // Override with AVX2 extended math functions
    dispatchTable.FmaF32x4 := @AVX2FmaF32x4;
    dispatchTable.RcpF32x4 := @AVX2RcpF32x4;
    dispatchTable.RsqrtF32x4 := @AVX2RsqrtF32x4;
    dispatchTable.FloorF32x4 := @AVX2FloorF32x4;
    dispatchTable.CeilF32x4 := @AVX2CeilF32x4;
    dispatchTable.RoundF32x4 := @AVX2RoundF32x4;
    dispatchTable.TruncF32x4 := @AVX2TruncF32x4;
    dispatchTable.ClampF32x4 := @AVX2ClampF32x4;

    // Override with AVX2 vector math functions
    dispatchTable.DotF32x4 := @AVX2DotF32x4;
    dispatchTable.DotF32x3 := @AVX2DotF32x3;
    dispatchTable.CrossF32x3 := @AVX2CrossF32x3;
    dispatchTable.LengthF32x4 := @AVX2LengthF32x4;
    dispatchTable.LengthF32x3 := @AVX2LengthF32x3;
    dispatchTable.NormalizeF32x4 := @AVX2NormalizeF32x4;
    dispatchTable.NormalizeF32x3 := @AVX2NormalizeF32x3;

    // Override with AVX2 reduction operations
    dispatchTable.ReduceAddF32x4 := @AVX2ReduceAddF32x4;
    dispatchTable.ReduceMinF32x4 := @AVX2ReduceMinF32x4;
    dispatchTable.ReduceMaxF32x4 := @AVX2ReduceMaxF32x4;
    dispatchTable.ReduceMulF32x4 := @AVX2ReduceMulF32x4;

    // F64x2 Math (128-bit)
    dispatchTable.AbsF64x2 := @AVX2AbsF64x2;
    dispatchTable.SqrtF64x2 := @AVX2SqrtF64x2;
    dispatchTable.MinF64x2 := @AVX2MinF64x2;
    dispatchTable.MaxF64x2 := @AVX2MaxF64x2;
    dispatchTable.ClampF64x2 := @AVX2ClampF64x2;

    // F64x2 Reduction (128-bit)
    dispatchTable.ReduceAddF64x2 := @AVX2ReduceAddF64x2;
    dispatchTable.ReduceMinF64x2 := @AVX2ReduceMinF64x2;
    dispatchTable.ReduceMaxF64x2 := @AVX2ReduceMaxF64x2;
    dispatchTable.ReduceMulF64x2 := @AVX2ReduceMulF64x2;

    // F64x2 Comparison (128-bit)
    dispatchTable.CmpEqF64x2 := @AVX2CmpEqF64x2;
    dispatchTable.CmpLtF64x2 := @AVX2CmpLtF64x2;
    dispatchTable.CmpLeF64x2 := @AVX2CmpLeF64x2;
    dispatchTable.CmpGtF64x2 := @AVX2CmpGtF64x2;
    dispatchTable.CmpGeF64x2 := @AVX2CmpGeF64x2;
    dispatchTable.CmpNeF64x2 := @AVX2CmpNeF64x2;

    // F64x2 Extended Math (128-bit)
    dispatchTable.FmaF64x2 := @AVX2FmaF64x2;
    dispatchTable.FloorF64x2 := @AVX2FloorF64x2;
    dispatchTable.CeilF64x2 := @AVX2CeilF64x2;
    dispatchTable.RoundF64x2 := @AVX2RoundF64x2;
    dispatchTable.TruncF64x2 := @AVX2TruncF64x2;

    // F64x2 Load/Store/Splat/Zero (128-bit)
    dispatchTable.LoadF64x2 := @AVX2LoadF64x2;
    dispatchTable.StoreF64x2 := @AVX2StoreF64x2;
    dispatchTable.SplatF64x2 := @AVX2SplatF64x2;
    dispatchTable.ZeroF64x2 := @AVX2ZeroF64x2;

    // F32x8 Math (256-bit AVX)
    dispatchTable.AbsF32x8 := @AVX2AbsF32x8;
    dispatchTable.SqrtF32x8 := @AVX2SqrtF32x8;
    dispatchTable.MinF32x8 := @AVX2MinF32x8;
    dispatchTable.MaxF32x8 := @AVX2MaxF32x8;
    dispatchTable.ClampF32x8 := @AVX2ClampF32x8;

    // F32x8 Reduction (256-bit AVX)
    dispatchTable.ReduceAddF32x8 := @AVX2ReduceAddF32x8;
    dispatchTable.ReduceMinF32x8 := @AVX2ReduceMinF32x8;
    dispatchTable.ReduceMaxF32x8 := @AVX2ReduceMaxF32x8;
    dispatchTable.ReduceMulF32x8 := @AVX2ReduceMulF32x8;

    // F32x8 Extended Math (256-bit AVX)
    dispatchTable.FmaF32x8 := @AVX2FmaF32x8;
    dispatchTable.FloorF32x8 := @AVX2FloorF32x8;
    dispatchTable.CeilF32x8 := @AVX2CeilF32x8;
    dispatchTable.RoundF32x8 := @AVX2RoundF32x8;
    dispatchTable.TruncF32x8 := @AVX2TruncF32x8;

    // F32x8 Load/Store/Splat/Zero (256-bit AVX)
    dispatchTable.LoadF32x8 := @AVX2LoadF32x8;
    dispatchTable.StoreF32x8 := @AVX2StoreF32x8;
    dispatchTable.SplatF32x8 := @AVX2SplatF32x8;
    dispatchTable.ZeroF32x8 := @AVX2ZeroF32x8;

    // F64x4 Math (256-bit AVX)
    dispatchTable.AbsF64x4 := @AVX2AbsF64x4;
    dispatchTable.SqrtF64x4 := @AVX2SqrtF64x4;
    dispatchTable.MinF64x4 := @AVX2MinF64x4;
    dispatchTable.MaxF64x4 := @AVX2MaxF64x4;
    dispatchTable.ClampF64x4 := @AVX2ClampF64x4;

    // F64x4 Reduction (256-bit AVX)
    dispatchTable.ReduceAddF64x4 := @AVX2ReduceAddF64x4;
    dispatchTable.ReduceMinF64x4 := @AVX2ReduceMinF64x4;
    dispatchTable.ReduceMaxF64x4 := @AVX2ReduceMaxF64x4;
    dispatchTable.ReduceMulF64x4 := @AVX2ReduceMulF64x4;

    // F64x4 Extended Math (256-bit AVX)
    dispatchTable.FmaF64x4 := @AVX2FmaF64x4;
    dispatchTable.FloorF64x4 := @AVX2FloorF64x4;
    dispatchTable.CeilF64x4 := @AVX2CeilF64x4;
    dispatchTable.RoundF64x4 := @AVX2RoundF64x4;
    dispatchTable.TruncF64x4 := @AVX2TruncF64x4;

    // F64x4 Load/Store/Splat/Zero (256-bit AVX)
    dispatchTable.LoadF64x4 := @AVX2LoadF64x4;
    dispatchTable.StoreF64x4 := @AVX2StoreF64x4;
    dispatchTable.SplatF64x4 := @AVX2SplatF64x4;
    dispatchTable.ZeroF64x4 := @AVX2ZeroF64x4;

    // Override with AVX2 memory operations
    dispatchTable.LoadF32x4 := @AVX2LoadF32x4;
    dispatchTable.LoadF32x4Aligned := @AVX2LoadF32x4Aligned;
    dispatchTable.StoreF32x4 := @AVX2StoreF32x4;
    dispatchTable.StoreF32x4Aligned := @AVX2StoreF32x4Aligned;

    // Override with AVX2 utility operations
    dispatchTable.SplatF32x4 := @AVX2SplatF32x4;
    dispatchTable.ZeroF32x4 := @AVX2ZeroF32x4;
    dispatchTable.SelectF32x4 := @AVX2SelectF32x4;
    dispatchTable.ExtractF32x4 := @AVX2ExtractF32x4;
    dispatchTable.InsertF32x4 := @AVX2InsertF32x4;

    // ✅ P4: SelectF64x2
    dispatchTable.SelectF64x2 := @AVX2SelectF64x2;
  end;
  // else: keep scalar implementations from FillBaseDispatchTable

  // Override facade functions with AVX2-accelerated versions
  dispatchTable.MemEqual := @MemEqual_AVX2;
  dispatchTable.MemFindByte := @MemFindByte_AVX2;
  dispatchTable.SumBytes := @SumBytes_AVX2;
  dispatchTable.CountByte := @CountByte_AVX2;
  dispatchTable.MemDiffRange := @MemDiffRange_AVX2;
  dispatchTable.MemReverse := @MemReverse_AVX2;
  dispatchTable.MinMaxBytes := @MinMaxBytes_AVX2;
  dispatchTable.Utf8Validate := @Utf8Validate_AVX2;
  dispatchTable.AsciiIEqual := @AsciiIEqual_AVX2;
  dispatchTable.ToLowerAscii := @ToLowerAscii_AVX2;
  dispatchTable.ToUpperAscii := @ToUpperAscii_AVX2;
  dispatchTable.BytesIndexOf := @BytesIndexOf_AVX2;
  dispatchTable.BitsetPopCount := @BitsetPopCount_AVX2;
  // Note: MemCopy, MemSet keep scalar implementations (FPC's Move/FillChar are already optimized)

  // ✅ P2: Override with AVX2 saturating arithmetic (VEX-encoded, always enabled)
  dispatchTable.I8x16SatAdd := @AVX2I8x16SatAdd;
  dispatchTable.I8x16SatSub := @AVX2I8x16SatSub;
  dispatchTable.I16x8SatAdd := @AVX2I16x8SatAdd;
  dispatchTable.I16x8SatSub := @AVX2I16x8SatSub;
  dispatchTable.U8x16SatAdd := @AVX2U8x16SatAdd;
  dispatchTable.U8x16SatSub := @AVX2U8x16SatSub;
  dispatchTable.U16x8SatAdd := @AVX2U16x8SatAdd;
  dispatchTable.U16x8SatSub := @AVX2U16x8SatSub;

  // ✅ P1: Mask operations (native popcnt + bsf, always enabled)
  dispatchTable.Mask2All := @AVX2Mask2All;
  dispatchTable.Mask2Any := @AVX2Mask2Any;
  dispatchTable.Mask2None := @AVX2Mask2None;
  dispatchTable.Mask2PopCount := @AVX2Mask2PopCount;
  dispatchTable.Mask2FirstSet := @AVX2Mask2FirstSet;
  dispatchTable.Mask4All := @AVX2Mask4All;
  dispatchTable.Mask4Any := @AVX2Mask4Any;
  dispatchTable.Mask4None := @AVX2Mask4None;
  dispatchTable.Mask4PopCount := @AVX2Mask4PopCount;
  dispatchTable.Mask4FirstSet := @AVX2Mask4FirstSet;
  dispatchTable.Mask8All := @AVX2Mask8All;
  dispatchTable.Mask8Any := @AVX2Mask8Any;
  dispatchTable.Mask8None := @AVX2Mask8None;
  dispatchTable.Mask8PopCount := @AVX2Mask8PopCount;
  dispatchTable.Mask8FirstSet := @AVX2Mask8FirstSet;
  dispatchTable.Mask16All := @AVX2Mask16All;
  dispatchTable.Mask16Any := @AVX2Mask16Any;
  dispatchTable.Mask16None := @AVX2Mask16None;
  dispatchTable.Mask16PopCount := @AVX2Mask16PopCount;
  dispatchTable.Mask16FirstSet := @AVX2Mask16FirstSet;

  // Register the backend
  RegisterBackend(sbAVX2, dispatchTable);
end;

initialization
  RegisterAVX2Backend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbAVX2, @RegisterAVX2Backend);

end.

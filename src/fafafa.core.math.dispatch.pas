{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.dispatch

## Abstract 摘要

Backend dispatch mechanism for fafafa.core.math.
Allows switching between scalar (RTL-backed) and SIMD implementations.
fafafa.core.math 的后端派发机制，支持在标量/RTL 实现与 SIMD 实现间切换。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.dispatch;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

type
  {**
   * TMathBackend
   *
   * @desc
   *   Available math backend implementations.
   *   可用的数学后端实现。
   *}
  TMathBackend = (
    mbScalar,     // Pure Pascal / RTL-backed (always available)
    mbSSE2,       // SSE2 SIMD (x86_64)
    mbAVX2,       // AVX2 SIMD (x86_64)
    mbNEON        // NEON SIMD (ARM64)
  );

  {**
   * TMathBackendInfo
   *
   * @desc
   *   Information about a math backend.
   *   数学后端的信息。
   *}
  TMathBackendInfo = record
    Name: string;
    Description: string;
    Available: Boolean;
  end;

  // ============================================================================
  // Function Pointer Types for Array Operations
  // ============================================================================

  // F64 Reduction operations (返回单一值)
  TArraySumF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArraySumKahanF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayMinF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayMaxF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayMinMaxF64Proc = procedure(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);
  TArrayMeanF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayVarianceF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayPopulationVarianceF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayStdDevF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayPopulationStdDevF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;
  TArrayDotProductF64Proc = function(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;
  TArrayL2NormF64Proc = function(aSrc: PDouble; aCount: SizeUInt): Double;

  // F64 Element-wise operations (逐元素操作)
  TArrayScaleF64Proc = procedure(aSrc, aDst: PDouble; aCount: SizeUInt; aFactor: Double);
  TArrayAbsF64Proc = procedure(aSrc, aDst: PDouble; aCount: SizeUInt);
  TArrayAddF64Proc = procedure(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);
  TArrayAddArrayF64Proc = procedure(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);

  // F32 Reduction operations
  TArraySumF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArraySumKahanF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayMinF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayMaxF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayMinMaxF32Proc = procedure(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
  TArrayMeanF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayVarianceF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayPopulationVarianceF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayStdDevF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayPopulationStdDevF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;
  TArrayDotProductF32Proc = function(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
  TArrayL2NormF32Proc = function(aSrc: PSingle; aCount: SizeUInt): Single;

  // F32 Element-wise operations
  TArrayScaleF32Proc = procedure(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
  TArrayAbsF32Proc = procedure(aSrc, aDst: PSingle; aCount: SizeUInt);
  TArrayAddF32Proc = procedure(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
  TArrayAddArrayF32Proc = procedure(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);

  {**
   * TMathDispatchTable
   *
   * @desc
   *   Function pointer table for dispatching math operations.
   *   派发数学运算的函数指针表。
   *}
  TMathDispatchTable = record
    Backend: TMathBackend;
    BackendInfo: TMathBackendInfo;

    // === F64 Reduction Operations ===
    ArraySumF64: TArraySumF64Proc;
    ArraySumKahanF64: TArraySumKahanF64Proc;
    ArrayMinF64: TArrayMinF64Proc;
    ArrayMaxF64: TArrayMaxF64Proc;
    ArrayMinMaxF64: TArrayMinMaxF64Proc;
    ArrayMeanF64: TArrayMeanF64Proc;
    ArrayVarianceF64: TArrayVarianceF64Proc;
    ArrayPopulationVarianceF64: TArrayPopulationVarianceF64Proc;
    ArrayStdDevF64: TArrayStdDevF64Proc;
    ArrayPopulationStdDevF64: TArrayPopulationStdDevF64Proc;
    ArrayDotProductF64: TArrayDotProductF64Proc;
    ArrayL2NormF64: TArrayL2NormF64Proc;

    // === F64 Element-wise Operations ===
    ArrayScaleF64: TArrayScaleF64Proc;
    ArrayAbsF64: TArrayAbsF64Proc;
    ArrayAddF64: TArrayAddF64Proc;
    ArrayAddArrayF64: TArrayAddArrayF64Proc;

    // === F32 Reduction Operations ===
    ArraySumF32: TArraySumF32Proc;
    ArraySumKahanF32: TArraySumKahanF32Proc;
    ArrayMinF32: TArrayMinF32Proc;
    ArrayMaxF32: TArrayMaxF32Proc;
    ArrayMinMaxF32: TArrayMinMaxF32Proc;
    ArrayMeanF32: TArrayMeanF32Proc;
    ArrayVarianceF32: TArrayVarianceF32Proc;
    ArrayPopulationVarianceF32: TArrayPopulationVarianceF32Proc;
    ArrayStdDevF32: TArrayStdDevF32Proc;
    ArrayPopulationStdDevF32: TArrayPopulationStdDevF32Proc;
    ArrayDotProductF32: TArrayDotProductF32Proc;
    ArrayL2NormF32: TArrayL2NormF32Proc;

    // === F32 Element-wise Operations ===
    ArrayScaleF32: TArrayScaleF32Proc;
    ArrayAbsF32: TArrayAbsF32Proc;
    ArrayAddF32: TArrayAddF32Proc;
    ArrayAddArrayF32: TArrayAddArrayF32Proc;
  end;

  PMathDispatchTable = ^TMathDispatchTable;

{$IFDEF DEBUG}
  // Debug/Test only: trace counters used to verify facade routes array ops through dispatch.
  TMathDispatchTrace = record
    ArraySumF64Calls: SizeUInt;
    ArraySumKahanF64Calls: SizeUInt;
    ArrayMinF64Calls: SizeUInt;
    ArrayMaxF64Calls: SizeUInt;
    ArrayMinMaxF64Calls: SizeUInt;
    ArrayMeanF64Calls: SizeUInt;
    ArrayVarianceF64Calls: SizeUInt;
    ArrayPopulationVarianceF64Calls: SizeUInt;
    ArrayStdDevF64Calls: SizeUInt;
    ArrayPopulationStdDevF64Calls: SizeUInt;
    ArrayDotProductF64Calls: SizeUInt;
    ArrayL2NormF64Calls: SizeUInt;
    ArrayScaleF64Calls: SizeUInt;
    ArrayAbsF64Calls: SizeUInt;
    ArrayAddF64Calls: SizeUInt;
    ArrayAddArrayF64Calls: SizeUInt;

    ArraySumF32Calls: SizeUInt;
    ArraySumKahanF32Calls: SizeUInt;
    ArrayMinF32Calls: SizeUInt;
    ArrayMaxF32Calls: SizeUInt;
    ArrayMinMaxF32Calls: SizeUInt;
    ArrayMeanF32Calls: SizeUInt;
    ArrayVarianceF32Calls: SizeUInt;
    ArrayPopulationVarianceF32Calls: SizeUInt;
    ArrayStdDevF32Calls: SizeUInt;
    ArrayPopulationStdDevF32Calls: SizeUInt;
    ArrayDotProductF32Calls: SizeUInt;
    ArrayL2NormF32Calls: SizeUInt;
    ArrayScaleF32Calls: SizeUInt;
    ArrayAbsF32Calls: SizeUInt;
    ArrayAddF32Calls: SizeUInt;
    ArrayAddArrayF32Calls: SizeUInt;
  end;
{$ENDIF}

{**
 * GetActiveBackend
 *
 * @desc
 *   Returns the currently active math backend.
 *   返回当前活动的数学后端。
 *}
function GetActiveBackend: TMathBackend;

{**
 * GetRequestedBackend
 *
 * @desc
 *   Returns the backend that was requested (via SetActiveBackend or auto-selection).
 *   For automatic selection, it matches GetActiveBackend.
 *   返回用户请求的后端(通过 SetActiveBackend 或自动选择)。
 *   对于自动选择模式,它与 GetActiveBackend 相同。
 *}
function GetRequestedBackend: TMathBackend;

{**
 * IsBackendForced
 *
 * @desc
 *   Returns true if the backend was explicitly set via SetActiveBackend.
 *   返回 true 如果后端是通过 SetActiveBackend 显式设置的。
 *}
function IsBackendForced: Boolean;

{**
 * GetBackendInfo
 *
 * @desc
 *   Returns information about a specific backend.
 *   返回指定后端的信息。
 *}
function GetBackendInfo(aBackend: TMathBackend): TMathBackendInfo;

{**
 * SetActiveBackend
 *
 * @desc
 *   Force a specific backend (for testing or manual override).
 *   强制使用指定后端(用于测试或手动覆盖).
 *}
procedure SetActiveBackend(aBackend: TMathBackend);

{**
 * ResetToAutomaticBackend
 *
 * @desc
 *   Reset to automatic backend selection.
 *   重置为自动后端选择.
 *}
procedure ResetToAutomaticBackend;

{**
 * IsBackendAvailable
 *
 * @desc
 *   Check if a backend is available on this platform.
 *   检查后端在当前平台是否可用.
 *}
function IsBackendAvailable(aBackend: TMathBackend): Boolean;

{**
 * GetDispatchTable
 *
 * @desc
 *   Get the current dispatch table.
 *   获取当前派发表.
 *}
function GetDispatchTable: PMathDispatchTable;

{$IFDEF DEBUG}
// Debug/Test only: dispatch trace helpers.
procedure Debug_ResetDispatchTrace;
function Debug_GetDispatchTrace: TMathDispatchTrace;
{$ENDIF}

implementation

uses
  fafafa.core.math.array_;

var
  g_ActiveBackend: TMathBackend = mbScalar;
  g_RequestedBackend: TMathBackend = mbScalar;
  g_BackendForced: Boolean = False;
  g_DispatchTable: TMathDispatchTable;
  g_Initialized: Boolean = False;
  g_BackendInfos: array[TMathBackend] of TMathBackendInfo;

{$IFDEF DEBUG}
  g_DispatchTrace: TMathDispatchTrace;
{$ENDIF}

{$IFDEF DEBUG}
procedure Debug_ResetDispatchTrace;
begin
  FillChar(g_DispatchTrace, SizeOf(g_DispatchTrace), 0);
end;

function Debug_GetDispatchTrace: TMathDispatchTrace;
begin
  Result := g_DispatchTrace;
end;
{$ENDIF}

// ============================================================================
// Scalar Wrapper Functions (delegate to array_ module)
// ============================================================================

function ScalarArraySumF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumF64Calls);
{$ENDIF}
  // Match facade semantics: ArraySumF64 is the naive sum (Kahan has its own API).
  Result := fafafa.core.math.array_.ArraySumF64(aSrc, aCount);
end;

function ScalarArraySumKahanF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumKahanF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArraySumKahanF64(aSrc, aCount);
end;

function ScalarArrayMinF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayMinF64(aSrc, aCount);
end;

function ScalarArrayMaxF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMaxF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayMaxF64(aSrc, aCount);
end;

procedure ScalarArrayMinMaxF64(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinMaxF64Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayMinMaxF64(aSrc, aCount, aMin, aMax);
end;

function ScalarArrayMeanF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMeanF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayMeanF64(aSrc, aCount);
end;

function ScalarArrayDotProductF64(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayDotProductF64Calls);
{$ENDIF}
  // Match facade semantics: use the array_ implementation (Kahan summation).
  Result := fafafa.core.math.array_.ArrayDotProductF64(aSrc1, aSrc2, aCount);
end;

function ScalarArrayVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayVarianceF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayVarianceF64(aSrc, aCount);
end;

function ScalarArrayPopulationVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationVarianceF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayPopulationVarianceF64(aSrc, aCount);
end;

function ScalarArrayStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayStdDevF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayStdDevF64(aSrc, aCount);
end;

function ScalarArrayPopulationStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationStdDevF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayPopulationStdDevF64(aSrc, aCount);
end;

function ScalarArrayL2NormF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayL2NormF64Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayL2NormF64(aSrc, aCount);
end;

procedure ScalarArrayScaleF64(aSrc, aDst: PDouble; aCount: SizeUInt; aFactor: Double);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayScaleF64Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayScaleF64(aSrc, aDst, aCount, aFactor);
end;

procedure ScalarArrayAbsF64(aSrc, aDst: PDouble; aCount: SizeUInt);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAbsF64Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayAbsF64(aSrc, aDst, aCount);
end;

procedure ScalarArrayAddF64(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddF64Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayAddF64(aSrc, aDst, aCount, aValue);
end;

procedure ScalarArrayAddArrayF64(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddArrayF64Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayAddArrayF64(aSrc1, aSrc2, aDst, aCount);
end;

function ScalarArraySumF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumF32Calls);
{$ENDIF}
  // Match facade semantics: ArraySumF32 is the naive sum (Kahan has its own API).
  Result := fafafa.core.math.array_.ArraySumF32(aSrc, aCount);
end;

function ScalarArraySumKahanF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumKahanF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArraySumKahanF32(aSrc, aCount);
end;

function ScalarArrayMinF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayMinF32(aSrc, aCount);
end;

function ScalarArrayMaxF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMaxF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayMaxF32(aSrc, aCount);
end;

procedure ScalarArrayMinMaxF32(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinMaxF32Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayMinMaxF32(aSrc, aCount, aMin, aMax);
end;

function ScalarArrayMeanF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMeanF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayMeanF32(aSrc, aCount);
end;

function ScalarArrayVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayVarianceF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayVarianceF32(aSrc, aCount);
end;

function ScalarArrayPopulationVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationVarianceF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayPopulationVarianceF32(aSrc, aCount);
end;

function ScalarArrayStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayStdDevF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayStdDevF32(aSrc, aCount);
end;

function ScalarArrayPopulationStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationStdDevF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayPopulationStdDevF32(aSrc, aCount);
end;

function ScalarArrayDotProductF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayDotProductF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayDotProductF32(aSrc1, aSrc2, aCount);
end;

function ScalarArrayL2NormF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayL2NormF32Calls);
{$ENDIF}
  Result := fafafa.core.math.array_.ArrayL2NormF32(aSrc, aCount);
end;

procedure ScalarArrayScaleF32(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayScaleF32Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayScaleF32(aSrc, aDst, aCount, aFactor);
end;

procedure ScalarArrayAbsF32(aSrc, aDst: PSingle; aCount: SizeUInt);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAbsF32Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayAbsF32(aSrc, aDst, aCount);
end;

procedure ScalarArrayAddF32(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddF32Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayAddF32(aSrc, aDst, aCount, aValue);
end;

procedure ScalarArrayAddArrayF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddArrayF32Calls);
{$ENDIF}
  fafafa.core.math.array_.ArrayAddArrayF32(aSrc1, aSrc2, aDst, aCount);
end;

// ============================================================================
// AVX2 Backend (x86_64)
// ============================================================================

{$IFDEF CPUX86_64}
function AVX2ArraySumF64(aSrc: PDouble; aCount: SizeUInt): Double;
type
  TAcc4 = array[0..3] of Double;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  LAcc: TAcc4;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumF64Calls);
{$ENDIF}
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  // Sum 4 doubles at a time using YMM, then finish the tail scalar.
  LVecCount := aCount and (not SizeUInt(3));
  LAcc := Default(TAcc4);

  asm
    mov     rax, aSrc
    mov     rcx, LVecCount
    xor     rdx, rdx
    vxorpd  ymm0, ymm0, ymm0
  @loop4:
    cmp     rdx, rcx
    jae     @done4
    vmovupd ymm1, [rax + rdx*8]
    vaddpd  ymm0, ymm0, ymm1
    add     rdx, 4
    jmp     @loop4
  @done4:
    lea     r8, LAcc
    vmovupd [r8], ymm0
    vzeroupper
  end;

  Result := LAcc[0] + LAcc[1] + LAcc[2] + LAcc[3];

  i := LVecCount;
  while i < aCount do
  begin
    Result := Result + aSrc[i];
    Inc(i);
  end;
end;

function AVX2ArraySumF32(aSrc: PSingle; aCount: SizeUInt): Single;
type
  TAcc8 = array[0..7] of Single;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  LAcc: TAcc8;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumF32Calls);
{$ENDIF}
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  // Sum 8 singles at a time using YMM, then finish the tail scalar.
  LVecCount := aCount and (not SizeUInt(7));
  LAcc := Default(TAcc8);

  asm
    mov     rax, aSrc
    mov     rcx, LVecCount
    xor     rdx, rdx
    vxorps  ymm0, ymm0, ymm0
  @loop8:
    cmp     rdx, rcx
    jae     @done8
    vmovups ymm1, [rax + rdx*4]
    vaddps  ymm0, ymm0, ymm1
    add     rdx, 8
    jmp     @loop8
  @done8:
    lea     r8, LAcc
    vmovups [r8], ymm0
    vzeroupper
  end;

  Result := LAcc[0] + LAcc[1] + LAcc[2] + LAcc[3] +
            LAcc[4] + LAcc[5] + LAcc[6] + LAcc[7];

  i := LVecCount;
  while i < aCount do
  begin
    Result := Result + aSrc[i];
    Inc(i);
  end;
end;

type
  TF64Bits = record
    case Integer of
      0: (u: QWord);
      1: (d: Double);
  end;

  TF32Bits = record
    case Integer of
      0: (u: UInt32);
      1: (f: Single);
  end;

const
  kF64_PosInfBits: QWord = QWord($7FF0000000000000);
  kF64_NegInfBits: QWord = QWord($FFF0000000000000);
  kF64_QNaNBits: QWord = QWord($7FF8000000000000);

  kF32_PosInfBits: UInt32 = UInt32($7F800000);
  kF32_NegInfBits: UInt32 = UInt32($FF800000);
  kF32_QNaNBits: UInt32 = UInt32($7FC00000);

function F64FromBits(const aBits: QWord): Double; inline;
var
  t: TF64Bits;
begin
  t.u := aBits;
  Result := t.d;
end;

function F32FromBits(const aBits: UInt32): Single; inline;
var
  t: TF32Bits;
begin
  t.u := aBits;
  Result := t.f;
end;

procedure AVX2MinMaxF64Core(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);
type
  TAcc4 = array[0..3] of Double;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LMin0, LMax0: Double;
  LMinAcc, LMaxAcc: TAcc4;
  LNaNMask: UInt32;
  v: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := F64FromBits(kF64_PosInfBits);
    aMax := F64FromBits(kF64_NegInfBits);
    Exit;
  end;

  aMin := aSrc[0];
  aMax := aSrc[0];

  // NaN propagation: if any element is NaN, return NaN.
  if aMin <> aMin then
  begin
    aMin := F64FromBits(kF64_QNaNBits);
    aMax := aMin;
    Exit;
  end;

  if aCount = 1 then
    Exit;

  LMin0 := aMin;
  LMax0 := aMax;

  // Process elements [1..] in 4-wide vectors.
  LVecCount := (aCount - 1) and (not SizeUInt(3));
  LMinAcc := Default(TAcc4);
  LMaxAcc := Default(TAcc4);
  LNaNMask := 0;

  asm
    mov         rax, aSrc
    add         rax, 8
    mov         rcx, LVecCount
    xor         rdx, rdx

    lea         r8, LMin0
    vbroadcastsd ymm4, [r8]
    lea         r9, LMax0
    vbroadcastsd ymm5, [r9]

    vxorpd      ymm6, ymm6, ymm6
    xor         r10d, r10d

  @loop4:
    cmp         rdx, rcx
    jae         @done4

    vmovupd     ymm0, [rax + rdx*8]

    // NaN mask: unordered compare (x ? x). True for NaNs.
    vcmppd      ymm1, ymm0, ymm0, 3
    vmovmskpd   eax, ymm1
    or          r10d, eax

    // Min update: if x < curMin
    vcmppd      ymm2, ymm0, ymm4, 1
    vblendvpd   ymm4, ymm4, ymm0, ymm2

    // Max update: if curMax < x
    vcmppd      ymm2, ymm5, ymm0, 1
    vblendvpd   ymm5, ymm5, ymm0, ymm2

    add         rdx, 4
    jmp         @loop4

  @done4:
    mov         LNaNMask, r10d

    lea         r8, LMinAcc
    vmovupd     [r8], ymm4
    lea         r9, LMaxAcc
    vmovupd     [r9], ymm5

    vzeroupper
  end;

  if LNaNMask <> 0 then
  begin
    aMin := F64FromBits(kF64_QNaNBits);
    aMax := aMin;
    Exit;
  end;

  aMin := LMin0;
  aMax := LMax0;

  for j := 0 to High(LMinAcc) do
  begin
    if LMinAcc[j] < aMin then
      aMin := LMinAcc[j];
    if LMaxAcc[j] > aMax then
      aMax := LMaxAcc[j];
  end;

  i := 1 + LVecCount;
  while i < aCount do
  begin
    v := aSrc[i];
    if v <> v then
    begin
      aMin := F64FromBits(kF64_QNaNBits);
      aMax := aMin;
      Exit;
    end;
    if v < aMin then
      aMin := v;
    if v > aMax then
      aMax := v;
    Inc(i);
  end;
end;

procedure AVX2MinMaxF32Core(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
type
  TAcc8 = array[0..7] of Single;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LMin0, LMax0: Single;
  LMinAcc, LMaxAcc: TAcc8;
  LNaNMask: UInt32;
  v: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := F32FromBits(kF32_PosInfBits);
    aMax := F32FromBits(kF32_NegInfBits);
    Exit;
  end;

  aMin := aSrc[0];
  aMax := aSrc[0];

  if aMin <> aMin then
  begin
    aMin := F32FromBits(kF32_QNaNBits);
    aMax := aMin;
    Exit;
  end;

  if aCount = 1 then
    Exit;

  LMin0 := aMin;
  LMax0 := aMax;

  // Process elements [1..] in 8-wide vectors.
  LVecCount := (aCount - 1) and (not SizeUInt(7));
  LMinAcc := Default(TAcc8);
  LMaxAcc := Default(TAcc8);
  LNaNMask := 0;

  asm
    mov         rax, aSrc
    add         rax, 4
    mov         rcx, LVecCount
    xor         rdx, rdx

    lea         r8, LMin0
    vbroadcastss ymm4, [r8]
    lea         r9, LMax0
    vbroadcastss ymm5, [r9]

    vxorps      ymm6, ymm6, ymm6
    xor         r10d, r10d

  @loop8:
    cmp         rdx, rcx
    jae         @done8

    vmovups     ymm0, [rax + rdx*4]

    vcmpps      ymm1, ymm0, ymm0, 3
    vmovmskps   eax, ymm1
    or          r10d, eax

    vcmpps      ymm2, ymm0, ymm4, 1
    vblendvps   ymm4, ymm4, ymm0, ymm2

    vcmpps      ymm2, ymm5, ymm0, 1
    vblendvps   ymm5, ymm5, ymm0, ymm2

    add         rdx, 8
    jmp         @loop8

  @done8:
    mov         LNaNMask, r10d

    lea         r8, LMinAcc
    vmovups     [r8], ymm4
    lea         r9, LMaxAcc
    vmovups     [r9], ymm5

    vzeroupper
  end;

  if LNaNMask <> 0 then
  begin
    aMin := F32FromBits(kF32_QNaNBits);
    aMax := aMin;
    Exit;
  end;

  aMin := LMin0;
  aMax := LMax0;

  for j := 0 to High(LMinAcc) do
  begin
    if LMinAcc[j] < aMin then
      aMin := LMinAcc[j];
    if LMaxAcc[j] > aMax then
      aMax := LMaxAcc[j];
  end;

  i := 1 + LVecCount;
  while i < aCount do
  begin
    v := aSrc[i];
    if v <> v then
    begin
      aMin := F32FromBits(kF32_QNaNBits);
      aMax := aMin;
      Exit;
    end;
    if v < aMin then
      aMin := v;
    if v > aMax then
      aMax := v;
    Inc(i);
  end;
end;

function AVX2SumKahanF64Core(aSrc: PDouble; aCount: SizeUInt): Double;
type
  TAcc4 = array[0..3] of Double;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LAcc: TAcc4;
  c, y, t: Double;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(3));
  LAcc := Default(TAcc4);

  asm
    mov         rax, aSrc
    mov         rcx, LVecCount
    xor         rdx, rdx

    // ymm0 = sum, ymm1 = c
    vxorpd      ymm0, ymm0, ymm0
    vxorpd      ymm1, ymm1, ymm1

  @loop4:
    cmp         rdx, rcx
    jae         @done4

    vmovupd     ymm2, [rax + rdx*8]

    // Kahan update per lane:
    // y = x - c
    // t = sum + y
    // c = (t - sum) - y
    // sum = t
    vsubpd      ymm3, ymm2, ymm1
    vaddpd      ymm4, ymm0, ymm3
    vsubpd      ymm5, ymm4, ymm0
    vsubpd      ymm1, ymm5, ymm3
    vmovapd     ymm0, ymm4

    add         rdx, 4
    jmp         @loop4

  @done4:
    lea         r8, LAcc
    vmovupd     [r8], ymm0
    vzeroupper
  end;

  // Reduce vector lanes with scalar Kahan.
  c := 0.0;
  for j := 0 to High(LAcc) do
  begin
    y := LAcc[j] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;

  // Tail.
  i := LVecCount;
  while i < aCount do
  begin
    y := aSrc[i] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
    Inc(i);
  end;
end;

function AVX2ArraySumKahanF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumKahanF64Calls);
{$ENDIF}
  Result := AVX2SumKahanF64Core(aSrc, aCount);
end;

function AVX2ArrayMinF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LMin, LMax: Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinF64Calls);
{$ENDIF}
  AVX2MinMaxF64Core(aSrc, aCount, LMin, LMax);
  Result := LMin;
end;

function AVX2ArrayMaxF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LMin, LMax: Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMaxF64Calls);
{$ENDIF}
  AVX2MinMaxF64Core(aSrc, aCount, LMin, LMax);
  Result := LMax;
end;

procedure AVX2ArrayMinMaxF64(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinMaxF64Calls);
{$ENDIF}
  AVX2MinMaxF64Core(aSrc, aCount, aMin, aMax);
end;

function AVX2ArrayMeanF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMeanF64Calls);
{$ENDIF}
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  Result := AVX2SumKahanF64Core(aSrc, aCount) / aCount;
end;

function AVX2SumSqDiffF64Core(aSrc: PDouble; aCount: SizeUInt; aMean: Double): Double;
type
  TAcc4 = array[0..3] of Double;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LAcc: TAcc4;
  LMean: Double;
  c, y, t: Double;
  d, s: Double;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(3));
  LAcc := Default(TAcc4);
  LMean := aMean;

  asm
    mov         rax, aSrc
    mov         rcx, LVecCount
    xor         rdx, rdx

    lea         r8, LMean
    vbroadcastsd ymm2, [r8]      // mean

    // ymm0 = sumsq, ymm1 = c
    vxorpd      ymm0, ymm0, ymm0
    vxorpd      ymm1, ymm1, ymm1

  @loop4:
    cmp         rdx, rcx
    jae         @done4

    vmovupd     ymm3, [rax + rdx*8]
    vsubpd      ymm3, ymm3, ymm2
    vmulpd      ymm3, ymm3, ymm3

    vsubpd      ymm4, ymm3, ymm1
    vaddpd      ymm5, ymm0, ymm4
    vsubpd      ymm6, ymm5, ymm0
    vsubpd      ymm1, ymm6, ymm4
    vmovapd     ymm0, ymm5

    add         rdx, 4
    jmp         @loop4

  @done4:
    lea         r9, LAcc
    vmovupd     [r9], ymm0
    vzeroupper
  end;

  // Reduce lanes with scalar Kahan.
  c := 0.0;
  for j := 0 to High(LAcc) do
  begin
    y := LAcc[j] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;

  // Tail.
  i := LVecCount;
  while i < aCount do
  begin
    d := aSrc[i] - aMean;
    s := d * d;

    y := s - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;

    Inc(i);
  end;
end;

function AVX2VarianceF64Core(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LMean: Double;
  LSumSq: Double;
begin
  if (aSrc = nil) or (aCount < 2) then
    Exit(0.0);

  LMean := AVX2SumKahanF64Core(aSrc, aCount) / aCount;
  LSumSq := AVX2SumSqDiffF64Core(aSrc, aCount, LMean);
  Result := LSumSq / (aCount - 1);
end;

function AVX2PopulationVarianceF64Core(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LMean: Double;
  LSumSq: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LMean := AVX2SumKahanF64Core(aSrc, aCount) / aCount;
  LSumSq := AVX2SumSqDiffF64Core(aSrc, aCount, LMean);
  Result := LSumSq / aCount;
end;

function AVX2ArrayVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayVarianceF64Calls);
{$ENDIF}
  Result := AVX2VarianceF64Core(aSrc, aCount);
end;

function AVX2ArrayPopulationVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationVarianceF64Calls);
{$ENDIF}
  Result := AVX2PopulationVarianceF64Core(aSrc, aCount);
end;

function AVX2ArrayStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  v: Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayStdDevF64Calls);
{$ENDIF}
  v := AVX2VarianceF64Core(aSrc, aCount);
  Result := System.Sqrt(v);
end;

function AVX2ArrayPopulationStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  v: Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationStdDevF64Calls);
{$ENDIF}
  v := AVX2PopulationVarianceF64Core(aSrc, aCount);
  Result := System.Sqrt(v);
end;

function AVX2DotProductF64Core(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;
type
  TAcc4 = array[0..3] of Double;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LAcc: TAcc4;
  c, y, t: Double;
  p: Double;
begin
  Result := 0.0;
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(3));
  LAcc := Default(TAcc4);

  asm
    mov         rax, aSrc1
    mov         r8, aSrc2
    mov         rcx, LVecCount
    xor         rdx, rdx

    // ymm0 = sum, ymm1 = c
    vxorpd      ymm0, ymm0, ymm0
    vxorpd      ymm1, ymm1, ymm1

  @loop4:
    cmp         rdx, rcx
    jae         @done4

    vmovupd     ymm2, [rax + rdx*8]
    vmovupd     ymm3, [r8 + rdx*8]
    vmulpd      ymm2, ymm2, ymm3

    vsubpd      ymm4, ymm2, ymm1
    vaddpd      ymm5, ymm0, ymm4
    vsubpd      ymm6, ymm5, ymm0
    vsubpd      ymm1, ymm6, ymm4
    vmovapd     ymm0, ymm5

    add         rdx, 4
    jmp         @loop4

  @done4:
    lea         r9, LAcc
    vmovupd     [r9], ymm0
    vzeroupper
  end;

  c := 0.0;
  for j := 0 to High(LAcc) do
  begin
    y := LAcc[j] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;

  i := LVecCount;
  while i < aCount do
  begin
    p := aSrc1[i] * aSrc2[i];
    y := p - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
    Inc(i);
  end;
end;

function AVX2ArrayDotProductF64(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayDotProductF64Calls);
{$ENDIF}
  Result := AVX2DotProductF64Core(aSrc1, aSrc2, aCount);
end;

function AVX2ArrayL2NormF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LSumSq: Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayL2NormF64Calls);
{$ENDIF}
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LSumSq := AVX2DotProductF64Core(aSrc, aSrc, aCount);
  Result := System.Sqrt(LSumSq);
end;

procedure AVX2ArrayScaleF64(aSrc, aDst: PDouble; aCount: SizeUInt; aFactor: Double);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  LFactor: Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayScaleF64Calls);
{$ENDIF}
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(3));
  LFactor := aFactor;

  asm
    mov         rax, aSrc
    mov         r8, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
    lea         r9, LFactor
    vbroadcastsd ymm2, [r9]
  @loop4:
    cmp         rdx, rcx
    jae         @done4
    vmovupd     ymm0, [rax + rdx*8]
    vmulpd      ymm0, ymm0, ymm2
    vmovupd     [r8 + rdx*8], ymm0
    add         rdx, 4
    jmp         @loop4
  @done4:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    aDst[i] := aSrc[i] * aFactor;
    Inc(i);
  end;
end;

procedure AVX2ArrayAbsF64(aSrc, aDst: PDouble; aCount: SizeUInt);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAbsF64Calls);
{$ENDIF}
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(3));

  asm
    mov         rax, aSrc
    mov         r8, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
    vxorpd      ymm4, ymm4, ymm4
  @loop4:
    cmp         rdx, rcx
    jae         @done4
    vmovupd     ymm0, [rax + rdx*8]

    // neg := -x
    vsubpd      ymm1, ymm4, ymm0

    // mask := x < 0.0 (strict), which preserves -0.0 and NaN semantics
    vcmppd      ymm2, ymm0, ymm4, 1

    // result := mask ? neg : x
    vblendvpd   ymm0, ymm0, ymm1, ymm2

    vmovupd     [r8 + rdx*8], ymm0
    add         rdx, 4
    jmp         @loop4
  @done4:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    if aSrc[i] < 0 then
      aDst[i] := -aSrc[i]
    else
      aDst[i] := aSrc[i];
    Inc(i);
  end;
end;

procedure AVX2ArrayAddF64(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  LValue: Double;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddF64Calls);
{$ENDIF}
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(3));
  LValue := aValue;

  asm
    mov         rax, aSrc
    mov         r8, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
    lea         r9, LValue
    vbroadcastsd ymm2, [r9]
  @loop4:
    cmp         rdx, rcx
    jae         @done4
    vmovupd     ymm0, [rax + rdx*8]
    vaddpd      ymm0, ymm0, ymm2
    vmovupd     [r8 + rdx*8], ymm0
    add         rdx, 4
    jmp         @loop4
  @done4:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    aDst[i] := aSrc[i] + aValue;
    Inc(i);
  end;
end;

procedure AVX2ArrayAddArrayF64(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddArrayF64Calls);
{$ENDIF}
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(3));

  asm
    mov         rax, aSrc1
    mov         r8, aSrc2
    mov         r9, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
  @loop4:
    cmp         rdx, rcx
    jae         @done4
    vmovupd     ymm0, [rax + rdx*8]
    vmovupd     ymm1, [r8 + rdx*8]
    vaddpd      ymm0, ymm0, ymm1
    vmovupd     [r9 + rdx*8], ymm0
    add         rdx, 4
    jmp         @loop4
  @done4:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    aDst[i] := aSrc1[i] + aSrc2[i];
    Inc(i);
  end;
end;

function AVX2SumKahanF32Core(aSrc: PSingle; aCount: SizeUInt): Single;
type
  TAcc8 = array[0..7] of Single;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LAcc: TAcc8;
  c, y, t: Single;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(7));
  LAcc := Default(TAcc8);

  asm
    mov         rax, aSrc
    mov         rcx, LVecCount
    xor         rdx, rdx

    // ymm0 = sum, ymm1 = c
    vxorps      ymm0, ymm0, ymm0
    vxorps      ymm1, ymm1, ymm1

  @loop8:
    cmp         rdx, rcx
    jae         @done8

    vmovups     ymm2, [rax + rdx*4]

    vsubps      ymm3, ymm2, ymm1
    vaddps      ymm4, ymm0, ymm3
    vsubps      ymm5, ymm4, ymm0
    vsubps      ymm1, ymm5, ymm3
    vmovaps     ymm0, ymm4

    add         rdx, 8
    jmp         @loop8

  @done8:
    lea         r8, LAcc
    vmovups     [r8], ymm0
    vzeroupper
  end;

  c := 0.0;
  for j := 0 to High(LAcc) do
  begin
    y := LAcc[j] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;

  i := LVecCount;
  while i < aCount do
  begin
    y := aSrc[i] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
    Inc(i);
  end;
end;

function AVX2ArraySumKahanF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArraySumKahanF32Calls);
{$ENDIF}
  Result := AVX2SumKahanF32Core(aSrc, aCount);
end;

function AVX2ArrayMinF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LMin, LMax: Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinF32Calls);
{$ENDIF}
  AVX2MinMaxF32Core(aSrc, aCount, LMin, LMax);
  Result := LMin;
end;

function AVX2ArrayMaxF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LMin, LMax: Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMaxF32Calls);
{$ENDIF}
  AVX2MinMaxF32Core(aSrc, aCount, LMin, LMax);
  Result := LMax;
end;

procedure AVX2ArrayMinMaxF32(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMinMaxF32Calls);
{$ENDIF}
  AVX2MinMaxF32Core(aSrc, aCount, aMin, aMax);
end;

function AVX2ArrayMeanF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayMeanF32Calls);
{$ENDIF}
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  Result := AVX2SumKahanF32Core(aSrc, aCount) / aCount;
end;

function AVX2SumSqDiffF32Core(aSrc: PSingle; aCount: SizeUInt; aMean: Single): Single;
type
  TAcc8 = array[0..7] of Single;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LAcc: TAcc8;
  LMean: Single;
  c, y, t: Single;
  d, s: Single;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(7));
  LAcc := Default(TAcc8);
  LMean := aMean;

  asm
    mov         rax, aSrc
    mov         rcx, LVecCount
    xor         rdx, rdx

    lea         r8, LMean
    vbroadcastss ymm2, [r8]      // mean

    // ymm0 = sumsq, ymm1 = c
    vxorps      ymm0, ymm0, ymm0
    vxorps      ymm1, ymm1, ymm1

  @loop8:
    cmp         rdx, rcx
    jae         @done8

    vmovups     ymm3, [rax + rdx*4]
    vsubps      ymm3, ymm3, ymm2
    vmulps      ymm3, ymm3, ymm3

    vsubps      ymm4, ymm3, ymm1
    vaddps      ymm5, ymm0, ymm4
    vsubps      ymm6, ymm5, ymm0
    vsubps      ymm1, ymm6, ymm4
    vmovaps     ymm0, ymm5

    add         rdx, 8
    jmp         @loop8

  @done8:
    lea         r9, LAcc
    vmovups     [r9], ymm0
    vzeroupper
  end;

  // Reduce lanes with scalar Kahan.
  c := 0.0;
  for j := 0 to High(LAcc) do
  begin
    y := LAcc[j] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;

  // Tail.
  i := LVecCount;
  while i < aCount do
  begin
    d := aSrc[i] - aMean;
    s := d * d;

    y := s - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;

    Inc(i);
  end;
end;

function AVX2VarianceF32Core(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LMean: Single;
  LSumSq: Single;
begin
  if (aSrc = nil) or (aCount < 2) then
    Exit(0.0);

  LMean := AVX2SumKahanF32Core(aSrc, aCount) / aCount;
  LSumSq := AVX2SumSqDiffF32Core(aSrc, aCount, LMean);
  Result := LSumSq / (aCount - 1);
end;

function AVX2PopulationVarianceF32Core(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LMean: Single;
  LSumSq: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LMean := AVX2SumKahanF32Core(aSrc, aCount) / aCount;
  LSumSq := AVX2SumSqDiffF32Core(aSrc, aCount, LMean);
  Result := LSumSq / aCount;
end;

function AVX2ArrayVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayVarianceF32Calls);
{$ENDIF}
  Result := AVX2VarianceF32Core(aSrc, aCount);
end;

function AVX2ArrayPopulationVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationVarianceF32Calls);
{$ENDIF}
  Result := AVX2PopulationVarianceF32Core(aSrc, aCount);
end;

function AVX2ArrayStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  v: Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayStdDevF32Calls);
{$ENDIF}
  v := AVX2VarianceF32Core(aSrc, aCount);
  Result := System.Sqrt(v);
end;

function AVX2ArrayPopulationStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  v: Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayPopulationStdDevF32Calls);
{$ENDIF}
  v := AVX2PopulationVarianceF32Core(aSrc, aCount);
  Result := System.Sqrt(v);
end;

function AVX2DotProductF32Core(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
type
  TAcc8 = array[0..7] of Single;
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  j: Integer;
  LAcc: TAcc8;
  c, y, t: Single;
  p: Single;
begin
  Result := 0.0;
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(7));
  LAcc := Default(TAcc8);

  asm
    mov         rax, aSrc1
    mov         r8, aSrc2
    mov         rcx, LVecCount
    xor         rdx, rdx

    // ymm0 = sum, ymm1 = c
    vxorps      ymm0, ymm0, ymm0
    vxorps      ymm1, ymm1, ymm1

  @loop8:
    cmp         rdx, rcx
    jae         @done8

    vmovups     ymm2, [rax + rdx*4]
    vmovups     ymm3, [r8 + rdx*4]
    vmulps      ymm2, ymm2, ymm3

    vsubps      ymm4, ymm2, ymm1
    vaddps      ymm5, ymm0, ymm4
    vsubps      ymm6, ymm5, ymm0
    vsubps      ymm1, ymm6, ymm4
    vmovaps     ymm0, ymm5

    add         rdx, 8
    jmp         @loop8

  @done8:
    lea         r9, LAcc
    vmovups     [r9], ymm0
    vzeroupper
  end;

  c := 0.0;
  for j := 0 to High(LAcc) do
  begin
    y := LAcc[j] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;

  i := LVecCount;
  while i < aCount do
  begin
    p := aSrc1[i] * aSrc2[i];
    y := p - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
    Inc(i);
  end;
end;

function AVX2ArrayDotProductF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayDotProductF32Calls);
{$ENDIF}
  Result := AVX2DotProductF32Core(aSrc1, aSrc2, aCount);
end;

function AVX2ArrayL2NormF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LSumSq: Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayL2NormF32Calls);
{$ENDIF}
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LSumSq := AVX2DotProductF32Core(aSrc, aSrc, aCount);
  Result := System.Sqrt(LSumSq);
end;

procedure AVX2ArrayScaleF32(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  LFactor: Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayScaleF32Calls);
{$ENDIF}
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(7));
  LFactor := aFactor;

  asm
    mov         rax, aSrc
    mov         r8, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
    lea         r9, LFactor
    vbroadcastss ymm2, [r9]
  @loop8:
    cmp         rdx, rcx
    jae         @done8
    vmovups     ymm0, [rax + rdx*4]
    vmulps      ymm0, ymm0, ymm2
    vmovups     [r8 + rdx*4], ymm0
    add         rdx, 8
    jmp         @loop8
  @done8:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    aDst[i] := aSrc[i] * aFactor;
    Inc(i);
  end;
end;

procedure AVX2ArrayAbsF32(aSrc, aDst: PSingle; aCount: SizeUInt);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAbsF32Calls);
{$ENDIF}
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(7));

  asm
    mov         rax, aSrc
    mov         r8, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
    vxorps      ymm4, ymm4, ymm4
  @loop8:
    cmp         rdx, rcx
    jae         @done8
    vmovups     ymm0, [rax + rdx*4]

    // neg := -x
    vsubps      ymm1, ymm4, ymm0

    // mask := x < 0.0 (strict), which preserves -0.0 and NaN semantics
    vcmpps      ymm2, ymm0, ymm4, 1

    // result := mask ? neg : x
    vblendvps   ymm0, ymm0, ymm1, ymm2

    vmovups     [r8 + rdx*4], ymm0
    add         rdx, 8
    jmp         @loop8
  @done8:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    if aSrc[i] < 0 then
      aDst[i] := -aSrc[i]
    else
      aDst[i] := aSrc[i];
    Inc(i);
  end;
end;

procedure AVX2ArrayAddF32(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
  LValue: Single;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddF32Calls);
{$ENDIF}
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(7));
  LValue := aValue;

  asm
    mov         rax, aSrc
    mov         r8, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
    lea         r9, LValue
    vbroadcastss ymm2, [r9]
  @loop8:
    cmp         rdx, rcx
    jae         @done8
    vmovups     ymm0, [rax + rdx*4]
    vaddps      ymm0, ymm0, ymm2
    vmovups     [r8 + rdx*4], ymm0
    add         rdx, 8
    jmp         @loop8
  @done8:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    aDst[i] := aSrc[i] + aValue;
    Inc(i);
  end;
end;

procedure AVX2ArrayAddArrayF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  LVecCount: SizeUInt;
  i: SizeUInt;
begin
{$IFDEF DEBUG}
  Inc(g_DispatchTrace.ArrayAddArrayF32Calls);
{$ENDIF}
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LVecCount := aCount and (not SizeUInt(7));

  asm
    mov         rax, aSrc1
    mov         r8, aSrc2
    mov         r9, aDst
    mov         rcx, LVecCount
    xor         rdx, rdx
  @loop8:
    cmp         rdx, rcx
    jae         @done8
    vmovups     ymm0, [rax + rdx*4]
    vmovups     ymm1, [r8 + rdx*4]
    vaddps      ymm0, ymm0, ymm1
    vmovups     [r9 + rdx*4], ymm0
    add         rdx, 8
    jmp         @loop8
  @done8:
    vzeroupper
  end;

  i := LVecCount;
  while i < aCount do
  begin
    aDst[i] := aSrc1[i] + aSrc2[i];
    Inc(i);
  end;
end;
{$ENDIF}

// ============================================================================
// CPU Feature Detection (simplified)
// ============================================================================

{$IFDEF CPUX86_64}
function DetectSSE2Available: Boolean;
begin
  // SSE2 is mandatory for x86_64
  Result := True;
end;

function DetectAVX2Available: Boolean;
var
  LCpuid1Ecx: UInt32;
  LCpuid7Ebx: UInt32;
  LXcr0Eax: UInt32;
  LXcr0Edx: UInt32;
begin
  Result := False;

  // 1) CPUID leaf 1: check OSXSAVE + AVX
  //    ECX bit 27: OSXSAVE, bit 28: AVX
  asm
    PUSH RBX
    MOV EAX, 1
    XOR ECX, ECX
    CPUID
    MOV LCpuid1Ecx, ECX
    POP RBX
  end;

  if (LCpuid1Ecx and (1 shl 27)) = 0 then
    Exit;
  if (LCpuid1Ecx and (1 shl 28)) = 0 then
    Exit;

  // 2) XGETBV: ensure XMM (bit 1) and YMM (bit 2) state are enabled by OS
  asm
    XOR ECX, ECX
    XGETBV
    MOV LXcr0Eax, EAX
    MOV LXcr0Edx, EDX
  end;

  if (LXcr0Eax and $6) <> $6 then
    Exit;

  // 3) CPUID leaf 7 subleaf 0: check AVX2 (EBX bit 5)
  asm
    PUSH RBX
    MOV EAX, 7
    XOR ECX, ECX
    CPUID
    MOV LCpuid7Ebx, EBX
    POP RBX
  end;

  Result := (LCpuid7Ebx and (1 shl 5)) <> 0;
end;
{$ELSE}
function DetectSSE2Available: Boolean;
begin
  Result := False;
end;

function DetectAVX2Available: Boolean;
begin
  Result := False;
end;
{$ENDIF}

{$IFDEF CPUAARCH64}
function DetectNEONAvailable: Boolean;
begin
  // NEON is mandatory for AArch64
  Result := True;
end;
{$ELSE}
function DetectNEONAvailable: Boolean;
begin
  Result := False;
end;
{$ENDIF}

// ============================================================================
// Dispatch Table Initialization
// ============================================================================

procedure SetupScalarBackend;
begin
  g_DispatchTable.Backend := mbScalar;
  g_DispatchTable.BackendInfo := g_BackendInfos[mbScalar];

  // F64 operations
  g_DispatchTable.ArraySumF64 := @ScalarArraySumF64;
  g_DispatchTable.ArraySumKahanF64 := @ScalarArraySumKahanF64;
  g_DispatchTable.ArrayMinF64 := @ScalarArrayMinF64;
  g_DispatchTable.ArrayMaxF64 := @ScalarArrayMaxF64;
  g_DispatchTable.ArrayMinMaxF64 := @ScalarArrayMinMaxF64;
  g_DispatchTable.ArrayMeanF64 := @ScalarArrayMeanF64;
  g_DispatchTable.ArrayVarianceF64 := @ScalarArrayVarianceF64;
  g_DispatchTable.ArrayPopulationVarianceF64 := @ScalarArrayPopulationVarianceF64;
  g_DispatchTable.ArrayStdDevF64 := @ScalarArrayStdDevF64;
  g_DispatchTable.ArrayPopulationStdDevF64 := @ScalarArrayPopulationStdDevF64;
  g_DispatchTable.ArrayDotProductF64 := @ScalarArrayDotProductF64;
  g_DispatchTable.ArrayL2NormF64 := @ScalarArrayL2NormF64;

  g_DispatchTable.ArrayScaleF64 := @ScalarArrayScaleF64;
  g_DispatchTable.ArrayAbsF64 := @ScalarArrayAbsF64;
  g_DispatchTable.ArrayAddF64 := @ScalarArrayAddF64;
  g_DispatchTable.ArrayAddArrayF64 := @ScalarArrayAddArrayF64;

  // F32 operations
  g_DispatchTable.ArraySumF32 := @ScalarArraySumF32;
  g_DispatchTable.ArraySumKahanF32 := @ScalarArraySumKahanF32;
  g_DispatchTable.ArrayMinF32 := @ScalarArrayMinF32;
  g_DispatchTable.ArrayMaxF32 := @ScalarArrayMaxF32;
  g_DispatchTable.ArrayMinMaxF32 := @ScalarArrayMinMaxF32;
  g_DispatchTable.ArrayMeanF32 := @ScalarArrayMeanF32;
  g_DispatchTable.ArrayVarianceF32 := @ScalarArrayVarianceF32;
  g_DispatchTable.ArrayPopulationVarianceF32 := @ScalarArrayPopulationVarianceF32;
  g_DispatchTable.ArrayStdDevF32 := @ScalarArrayStdDevF32;
  g_DispatchTable.ArrayPopulationStdDevF32 := @ScalarArrayPopulationStdDevF32;
  g_DispatchTable.ArrayDotProductF32 := @ScalarArrayDotProductF32;
  g_DispatchTable.ArrayL2NormF32 := @ScalarArrayL2NormF32;

  g_DispatchTable.ArrayScaleF32 := @ScalarArrayScaleF32;
  g_DispatchTable.ArrayAbsF32 := @ScalarArrayAbsF32;
  g_DispatchTable.ArrayAddF32 := @ScalarArrayAddF32;
  g_DispatchTable.ArrayAddArrayF32 := @ScalarArrayAddArrayF32;
end;

{$IFDEF CPUX86_64}
procedure SetupAVX2Backend;
begin
  // Fill everything with scalar fallbacks first, then override AVX2 ops.
  SetupScalarBackend;

  g_DispatchTable.Backend := mbAVX2;
  g_DispatchTable.BackendInfo := g_BackendInfos[mbAVX2];

  // F64 operations
  g_DispatchTable.ArraySumF64 := @AVX2ArraySumF64;
  g_DispatchTable.ArraySumKahanF64 := @AVX2ArraySumKahanF64;
  g_DispatchTable.ArrayMinF64 := @AVX2ArrayMinF64;
  g_DispatchTable.ArrayMaxF64 := @AVX2ArrayMaxF64;
  g_DispatchTable.ArrayMinMaxF64 := @AVX2ArrayMinMaxF64;
  g_DispatchTable.ArrayMeanF64 := @AVX2ArrayMeanF64;
  g_DispatchTable.ArrayVarianceF64 := @AVX2ArrayVarianceF64;
  g_DispatchTable.ArrayPopulationVarianceF64 := @AVX2ArrayPopulationVarianceF64;
  g_DispatchTable.ArrayStdDevF64 := @AVX2ArrayStdDevF64;
  g_DispatchTable.ArrayPopulationStdDevF64 := @AVX2ArrayPopulationStdDevF64;
  g_DispatchTable.ArrayDotProductF64 := @AVX2ArrayDotProductF64;
  g_DispatchTable.ArrayL2NormF64 := @AVX2ArrayL2NormF64;

  g_DispatchTable.ArrayScaleF64 := @AVX2ArrayScaleF64;
  g_DispatchTable.ArrayAbsF64 := @AVX2ArrayAbsF64;
  g_DispatchTable.ArrayAddF64 := @AVX2ArrayAddF64;
  g_DispatchTable.ArrayAddArrayF64 := @AVX2ArrayAddArrayF64;

  // F32 operations
  g_DispatchTable.ArraySumF32 := @AVX2ArraySumF32;
  g_DispatchTable.ArraySumKahanF32 := @AVX2ArraySumKahanF32;
  g_DispatchTable.ArrayMinF32 := @AVX2ArrayMinF32;
  g_DispatchTable.ArrayMaxF32 := @AVX2ArrayMaxF32;
  g_DispatchTable.ArrayMinMaxF32 := @AVX2ArrayMinMaxF32;
  g_DispatchTable.ArrayMeanF32 := @AVX2ArrayMeanF32;
  g_DispatchTable.ArrayVarianceF32 := @AVX2ArrayVarianceF32;
  g_DispatchTable.ArrayPopulationVarianceF32 := @AVX2ArrayPopulationVarianceF32;
  g_DispatchTable.ArrayStdDevF32 := @AVX2ArrayStdDevF32;
  g_DispatchTable.ArrayPopulationStdDevF32 := @AVX2ArrayPopulationStdDevF32;
  g_DispatchTable.ArrayDotProductF32 := @AVX2ArrayDotProductF32;
  g_DispatchTable.ArrayL2NormF32 := @AVX2ArrayL2NormF32;

  g_DispatchTable.ArrayScaleF32 := @AVX2ArrayScaleF32;
  g_DispatchTable.ArrayAbsF32 := @AVX2ArrayAbsF32;
  g_DispatchTable.ArrayAddF32 := @AVX2ArrayAddF32;
  g_DispatchTable.ArrayAddArrayF32 := @AVX2ArrayAddArrayF32;
end;
{$ENDIF}

procedure InitializeBackendInfos;
begin
  // Scalar - always available
  g_BackendInfos[mbScalar].Name := 'Scalar';
  g_BackendInfos[mbScalar].Description := 'Pure Pascal / RTL-backed implementation';
  g_BackendInfos[mbScalar].Available := True;

  // SSE2
  g_BackendInfos[mbSSE2].Name := 'SSE2';
  g_BackendInfos[mbSSE2].Description := 'SSE2 SIMD implementation (x86_64)';
  g_BackendInfos[mbSSE2].Available := DetectSSE2Available;

  // AVX2
  g_BackendInfos[mbAVX2].Name := 'AVX2';
  g_BackendInfos[mbAVX2].Description := 'AVX2 SIMD implementation (x86_64)';
  g_BackendInfos[mbAVX2].Available := DetectAVX2Available;

  // NEON
  g_BackendInfos[mbNEON].Name := 'NEON';
  g_BackendInfos[mbNEON].Description := 'NEON SIMD implementation (ARM64)';
  g_BackendInfos[mbNEON].Available := DetectNEONAvailable;
end;

procedure InitializeDispatch;
begin
  if g_Initialized then
    Exit;

  // Initialize backend availability info
  InitializeBackendInfos;

  // Start with scalar backend (always available)
  SetupScalarBackend;
  g_ActiveBackend := mbScalar;

  // Auto-select best available backend
  // Note: SIMD implementations can be added here when available
  // For now, we use scalar which delegates to array_ module
  {$IFDEF CPUX86_64}
  if g_BackendInfos[mbAVX2].Available then
  begin
    // Future: Setup AVX2 backend when SIMD implementations are ready
    // SetupAVX2Backend;
    // g_ActiveBackend := mbAVX2;
  end
  else if g_BackendInfos[mbSSE2].Available then
  begin
    // Future: Setup SSE2 backend when SIMD implementations are ready
    // SetupSSE2Backend;
    // g_ActiveBackend := mbSSE2;
  end;
  {$ENDIF}

  {$IFDEF CPUAARCH64}
  if g_BackendInfos[mbNEON].Available then
  begin
    // Future: Setup NEON backend when SIMD implementations are ready
    // SetupNEONBackend;
    // g_ActiveBackend := mbNEON;
  end;
  {$ENDIF}

  // Keep GetActiveBackend consistent with the dispatch table.
  g_ActiveBackend := g_DispatchTable.Backend;
  if not g_BackendForced then
    g_RequestedBackend := g_ActiveBackend;

  g_Initialized := True;
end;

// ============================================================================
// Public API
// ============================================================================

function GetActiveBackend: TMathBackend;
begin
  InitializeDispatch;
  Result := g_ActiveBackend;
end;

function GetRequestedBackend: TMathBackend;
begin
  InitializeDispatch;
  Result := g_RequestedBackend;
end;

function IsBackendForced: Boolean;
begin
  InitializeDispatch;
  Result := g_BackendForced;
end;

function GetBackendInfo(aBackend: TMathBackend): TMathBackendInfo;
begin
  InitializeDispatch;
  Result := g_BackendInfos[aBackend];
end;

procedure SetActiveBackend(aBackend: TMathBackend);
begin
  InitializeDispatch;
  if not IsBackendAvailable(aBackend) then
    Exit;

  g_RequestedBackend := aBackend;
  g_BackendForced := True;

  // Update dispatch table based on selected backend.
  case aBackend of
    mbScalar:
      SetupScalarBackend;

    mbAVX2:
      begin
        {$IFDEF CPUX86_64}
        SetupAVX2Backend;
        {$ELSE}
        SetupScalarBackend;
        {$ENDIF}
      end;

    // Future: add SIMD backend setup here
    mbSSE2, mbNEON:
      begin
        // For now, fall back to scalar until SIMD implementations are ready.
        SetupScalarBackend;
      end;
  end;

  // Keep GetActiveBackend consistent with the dispatch table.
  g_ActiveBackend := g_DispatchTable.Backend;
end;

procedure ResetToAutomaticBackend;
begin
  g_BackendForced := False;
  g_Initialized := False;
  InitializeDispatch;
end;

function IsBackendAvailable(aBackend: TMathBackend): Boolean;
begin
  InitializeDispatch;
  Result := g_BackendInfos[aBackend].Available;
end;

function GetDispatchTable: PMathDispatchTable;
begin
  InitializeDispatch;
  Result := @g_DispatchTable;
end;

end.

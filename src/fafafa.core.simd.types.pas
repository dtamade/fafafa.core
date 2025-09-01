unit fafafa.core.simd.types;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

// === Vector Type Definitions ===
type
  // 128-bit vector types
  TVecF32x4 = record
    case Integer of
      0: (f: array[0..3] of Single);
      1: (raw: array[0..15] of Byte);
  end;

  TVecF64x2 = record
    case Integer of
      0: (d: array[0..1] of Double);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI32x4 = record
    case Integer of
      0: (i: array[0..3] of Int32);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI64x2 = record
    case Integer of
      0: (i: array[0..1] of Int64);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI16x8 = record
    case Integer of
      0: (i: array[0..7] of Int16);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI8x16 = record
    case Integer of
      0: (i: array[0..15] of Int8);
      1: (raw: array[0..15] of Byte);
  end;

  // 256-bit vector types (AVX)
  TVecF32x8 = record
    case Integer of
      0: (f: array[0..7] of Single);
      1: (lo, hi: TVecF32x4);  // 两个 128-bit 部分
      2: (raw: array[0..31] of Byte);
  end;

  TVecF64x4 = record
    case Integer of
      0: (d: array[0..3] of Double);
      1: (lo, hi: TVecF64x2);  // 两个 128-bit 部分
      2: (raw: array[0..31] of Byte);
  end;

  TVecI32x8 = record
    case Integer of
      0: (i: array[0..7] of Int32);
      1: (lo, hi: TVecI32x4);  // 两个 128-bit 部分
      2: (raw: array[0..31] of Byte);
  end;

  TVecI16x16 = record
    case Integer of
      0: (i: array[0..15] of Int16);
      1: (lo, hi: TVecI16x8);  // 两个 128-bit 部分
      2: (raw: array[0..31] of Byte);
  end;

  TVecI8x32 = record
    case Integer of
      0: (i: array[0..31] of Int8);
      1: (lo, hi: TVecI8x16);  // 两个 128-bit 部分
      2: (raw: array[0..31] of Byte);
  end;

// === Mask Types (Bit Masks) ===
type
  // 简化为基础整数类型，便于常量定义与互操作
  TMask2 = type Byte;    // 使用低 2 位
  TMask4 = type Byte;    // 使用低 4 位
  TMask8 = type Byte;    // 使用低 8 位
  TMask16 = type Word;   // 使用低 16 位
  TMask32 = type DWord;  // 使用低 32 位

// === Element Types ===
type
  // SIMD element types
  TSimdElementType = (
    setFloat32,   // 32-bit floating point
    setFloat64,   // 64-bit floating point
    setInt8,      // 8-bit signed integer
    setInt16,     // 16-bit signed integer
    setInt32,     // 32-bit signed integer
    setInt64,     // 64-bit signed integer
    setUInt8,     // 8-bit unsigned integer
    setUInt16,    // 16-bit unsigned integer
    setUInt32,    // 32-bit unsigned integer
    setUInt64     // 64-bit unsigned integer
  );

// === Backend Types ===
  // Available SIMD backends
  TSimdBackend = (
    sbScalar,    // Pure scalar implementation (always available)
    sbSSE2,      // x86 SSE2 (128-bit)
    sbAVX2,      // x86 AVX2 (256-bit)
    sbAVX512,    // x86 AVX-512 (512-bit)
    sbNEON,      // ARM NEON (128-bit)
    sbRISCVV     // RISC-V Vector Extension
  );

  // Backend capability flags
  TSimdCapability = (
    scBasicArithmetic,    // +, -, *, /
    scComparison,         // =, <, <=, >, >=
    scMathFunctions,      // abs, sqrt, min, max
    scReduction,          // horizontal add, min, max
    scShuffle,            // permute, blend, zip
    scFMA,                // fused multiply-add
    scFastMath,           // reciprocal, rsqrt approximations
    scIntegerOps,         // integer arithmetic and bitwise
    scLoadStore,          // aligned/unaligned memory access
    scGather,             // gather/scatter operations
    scMaskedOps           // masked operations
  );
  TSimdCapabilities = set of TSimdCapability;
  TSimdCapabilitySet = TSimdCapabilities; // 别名，用于接口

// === Function Pointer Types for Dispatch ===
type
  // Arithmetic operations
  TSimdAddF32x4Func = function(const a, b: TVecF32x4): TVecF32x4;
  TSimdAddF32x8Func = function(const a, b: TVecF32x8): TVecF32x8;
  TSimdAddF64x2Func = function(const a, b: TVecF64x2): TVecF64x2;
  TSimdAddI32x4Func = function(const a, b: TVecI32x4): TVecI32x4;

  // Comparison operations
  TSimdCmpEqF32x4Func = function(const a, b: TVecF32x4): TMask4;
  TSimdCmpLtF32x4Func = function(const a, b: TVecF32x4): TMask4;

  // Math functions
  TSimdAbsF32x4Func = function(const a: TVecF32x4): TVecF32x4;
  TSimdSqrtF32x4Func = function(const a: TVecF32x4): TVecF32x4;

  // Reduction operations
  TSimdReduceAddF32x4Func = function(const a: TVecF32x4): Single;
  TSimdReduceMinF32x4Func = function(const a: TVecF32x4): Single;

  // Memory operations
  TSimdLoadF32x4Func = function(p: PSingle): TVecF32x4;
  TSimdStoreF32x4Proc = procedure(p: PSingle; const a: TVecF32x4);

  // Utility operations
  TSimdSplatF32x4Func = function(value: Single): TVecF32x4;
  TSimdSelectF32x4Func = function(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;

// === Backend Information ===
type
  TSimdBackendInfo = record
    Backend: TSimdBackend;
    Name: string;
    Description: string;
    Capabilities: TSimdCapabilities;
    Available: Boolean;
    Priority: Integer;  // Higher priority = preferred backend
  end;

// === CPU Feature Detection ===
type
  // x86 CPU features
  TX86Features = record
    // Basic SIMD features
    HasMMX: Boolean;
    HasSSE: Boolean;
    HasSSE2: Boolean;
    HasSSE3: Boolean;
    HasSSSE3: Boolean;
    HasSSE41: Boolean;
    HasSSE42: Boolean;

    // Advanced Vector Extensions
    HasAVX: Boolean;
    HasAVX2: Boolean;
    HasAVX512F: Boolean;      // Foundation
    HasAVX512DQ: Boolean;     // Doubleword and Quadword
    HasAVX512BW: Boolean;     // Byte and Word
    HasAVX512VL: Boolean;     // Vector Length Extensions
    HasAVX512VBMI: Boolean;   // Vector Bit Manipulation Instructions

    // Arithmetic and Math
    HasFMA: Boolean;          // Fused Multiply-Add
    HasFMA4: Boolean;         // 4-operand FMA (AMD)

    // Bit Manipulation
    HasBMI1: Boolean;         // Bit Manipulation Instructions 1
    HasBMI2: Boolean;         // Bit Manipulation Instructions 2

    // Cryptography
    HasAES: Boolean;          // AES instructions
    HasPCLMULQDQ: Boolean;    // Carry-less multiplication
    HasSHA: Boolean;          // SHA extensions

    // Other features
    HasRDRAND: Boolean;       // Hardware random number generator
    HasRDSEED: Boolean;       // Hardware random seed generator
    HasF16C: Boolean;         // Half-precision floating-point conversion
  end;

  // ARM CPU features
  TARMFeatures = record
    HasNEON: Boolean;
    HasFP: Boolean;
    HasAdvSIMD: Boolean;
    HasSVE: Boolean;
    HasCrypto: Boolean;
  end;

  // RISC-V CPU features
  TRISCVFeatures = record
    HasRV32I: Boolean;    // RV32I base integer instruction set
    HasRV64I: Boolean;    // RV64I base integer instruction set
    HasM: Boolean;        // Integer multiplication and division
    HasA: Boolean;        // Atomic instructions
    HasF: Boolean;        // Single-precision floating-point
    HasD: Boolean;        // Double-precision floating-point
    HasC: Boolean;        // Compressed instructions
    HasV: Boolean;        // Vector extension
  end;

  // x86 Cache information
  TX86CacheInfo = record
    L1DataCache: Integer;        // KB
    L1InstructionCache: Integer; // KB
    L2Cache: Integer;            // KB
    L3Cache: Integer;            // KB
    CacheLineSize: Integer;      // Cache line size in bytes
  end;

  // ARM Processor information
  TARMProcessorInfo = record
    Architecture: string;        // AArch32, AArch64
    InstructionSet: string;      // ARMv7-A, ARMv8-A, etc.
    CoreType: string;            // Cortex-A, Cortex-R, etc.
  end;

  // RISC-V Processor information
  TRISCVProcessorInfo = record
    Architecture: string;        // RV32, RV64
    ISA: string;                 // Full ISA string
    XLEN: Integer;               // Register width (32 or 64)
  end;

  // Combined CPU information
  TCPUInfo = record
    Vendor: string;
    Model: string;
    {$IFDEF SIMD_X86_AVAILABLE}
    X86: TX86Features;
    {$ENDIF}
    {$IFDEF SIMD_ARM_AVAILABLE}
    ARM: TARMFeatures;
    {$ENDIF}
    {$IFDEF SIMD_RISCV_AVAILABLE}
    RISCV: TRISCVFeatures;
    {$ENDIF}
  end;

// === Constants ===
const
  // Mask bit manipulation helpers
  MASK2_ALL_SET: TMask2 = $03;      // 11b
  MASK4_ALL_SET: TMask4 = $0F;      // 1111b
  MASK8_ALL_SET: TMask8 = $FF;      // 11111111b
  MASK16_ALL_SET: TMask16 = $FFFF;  // 16 ones
  MASK32_ALL_SET: TMask32 = $FFFFFFFF; // 32 ones

  MASK2_NONE_SET: TMask2 = $00;
  MASK4_NONE_SET: TMask4 = $00;
  MASK8_NONE_SET: TMask8 = $00;
  MASK16_NONE_SET: TMask16 = $0000;
  MASK32_NONE_SET: TMask32 = $00000000;

// === Utility Functions ===

// Mask manipulation
function MaskGetBit(mask: TMask4; index: Integer): Boolean; inline;
function MaskSetBit(mask: TMask4; index: Integer; value: Boolean): TMask4; inline;
function MaskAny(mask: TMask4): Boolean; inline;
function MaskAll(mask: TMask4): Boolean; inline;
function MaskNone(mask: TMask4): Boolean; inline;
function MaskCount(mask: TMask4): Integer; inline;

// Mask conversion (for debugging/testing)
type
  TBoolArray4 = array[0..3] of Boolean;

function MaskToBoolArray4(mask: TMask4): TBoolArray4;
function BoolArrayToMask4(const arr: TBoolArray4): TMask4;

// Backend information
function GetBackendName(backend: TSimdBackend): string;
function GetBackendDescription(backend: TSimdBackend): string;

implementation

// === Mask Utility Functions ===

function MaskGetBit(mask: TMask4; index: Integer): Boolean;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Mask index %d out of range [0..3]', [index]);
  {$ENDIF}
  Result := (mask and (1 shl index)) <> 0;
end;

function MaskSetBit(mask: TMask4; index: Integer; value: Boolean): TMask4;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Mask index %d out of range [0..3]', [index]);
  {$ENDIF}
  if value then
    Result := mask or (1 shl index)
  else
    Result := mask and not (1 shl index);
end;

function MaskAny(mask: TMask4): Boolean;
begin
  Result := mask <> 0;
end;

function MaskAll(mask: TMask4): Boolean;
begin
  Result := (mask and MASK4_ALL_SET) = MASK4_ALL_SET;
end;

function MaskNone(mask: TMask4): Boolean;
begin
  Result := mask = 0;
end;

function MaskCount(mask: TMask4): Integer;
begin
  Result := 0;
  if (mask and $01) <> 0 then Inc(Result);
  if (mask and $02) <> 0 then Inc(Result);
  if (mask and $04) <> 0 then Inc(Result);
  if (mask and $08) <> 0 then Inc(Result);
end;

// === Mask Conversion Functions ===

function MaskToBoolArray4(mask: TMask4): TBoolArray4;
begin
  Result[0] := (mask and $01) <> 0;
  Result[1] := (mask and $02) <> 0;
  Result[2] := (mask and $04) <> 0;
  Result[3] := (mask and $08) <> 0;
end;

function BoolArrayToMask4(const arr: TBoolArray4): TMask4;
begin
  Result := 0;
  if arr[0] then Result := Result or $01;
  if arr[1] then Result := Result or $02;
  if arr[2] then Result := Result or $04;
  if arr[3] then Result := Result or $08;
end;

// === Backend Information Functions ===

function GetBackendName(backend: TSimdBackend): string;
begin
  case backend of
    sbScalar: Result := 'Scalar';
    sbSSE2: Result := 'SSE2';
    sbAVX2: Result := 'AVX2';
    sbAVX512: Result := 'AVX-512';
    sbNEON: Result := 'NEON';
    sbRISCVV: Result := 'RISC-V Vector';
  else
    Result := 'Unknown';
  end;
end;

function GetBackendDescription(backend: TSimdBackend): string;
begin
  case backend of
    sbScalar: Result := 'Pure scalar implementation (portable fallback)';
    sbSSE2: Result := 'x86 SSE2 128-bit SIMD';
    sbAVX2: Result := 'x86 AVX2 256-bit SIMD';
    sbAVX512: Result := 'x86 AVX-512 512-bit SIMD';
    sbNEON: Result := 'ARM NEON 128-bit SIMD';
    sbRISCVV: Result := 'RISC-V Vector Extension variable-width SIMD';
  else
    Result := 'Unknown backend';
  end;
end;

end.

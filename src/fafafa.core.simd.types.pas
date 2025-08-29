unit fafafa.core.simd.types;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

// === Forward Declarations ===
type
  // Vector types
  TVecF32x4 = record end;
  TVecF32x8 = record end;
  TVecF64x2 = record end;
  TVecF64x4 = record end;
  TVecI32x4 = record end;
  TVecI32x8 = record end;
  TVecI16x8 = record end;
  TVecI16x16 = record end;
  TVecI8x16 = record end;
  TVecI8x32 = record end;

// === Mask Types (Bit Masks) ===
type
  // Bit masks for conditional operations
  TMask2 = type Byte;    // 2 bits: bit0, bit1
  TMask4 = type Byte;    // 4 bits: bit0..bit3
  TMask8 = type Byte;    // 8 bits: bit0..bit7
  TMask16 = type Word;   // 16 bits: bit0..bit15
  TMask32 = type DWord;  // 32 bits: bit0..bit31

// === Backend Types ===
type
  // Available SIMD backends
  TSimdBackend = (
    sbScalar,    // Pure scalar implementation (always available)
    sbSSE2,      // x86 SSE2 (128-bit)
    sbAVX2,      // x86 AVX2 (256-bit)
    sbAVX512,    // x86 AVX-512 (512-bit)
    sbNEON       // ARM NEON (128-bit)
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
    HasSSE: Boolean;
    HasSSE2: Boolean;
    HasSSE3: Boolean;
    HasSSSE3: Boolean;
    HasSSE41: Boolean;
    HasSSE42: Boolean;
    HasAVX: Boolean;
    HasAVX2: Boolean;
    HasAVX512F: Boolean;
    HasAVX512DQ: Boolean;
    HasAVX512BW: Boolean;
    HasFMA: Boolean;
  end;

  // ARM CPU features
  TARMFeatures = record
    HasNEON: Boolean;
    HasFP: Boolean;
    HasAdvSIMD: Boolean;
    HasSVE: Boolean;
    HasCrypto: Boolean;
  end;

  // x86 Cache information
  TX86CacheInfo = record
    L1DataCache: Integer;        // KB
    L1InstructionCache: Integer; // KB
    L2Cache: Integer;            // KB
    L3Cache: Integer;            // KB
  end;

  // ARM Processor information
  TARMProcessorInfo = record
    Architecture: string;        // AArch32, AArch64
    InstructionSet: string;      // ARMv7-A, ARMv8-A, etc.
    CoreType: string;            // Cortex-A, Cortex-R, etc.
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
  else
    Result := 'Unknown backend';
  end;
end;

end.

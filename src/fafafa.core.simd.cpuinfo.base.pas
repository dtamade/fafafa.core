unit fafafa.core.simd.cpuinfo.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

type
  TCPUArch = (caUnknown, caX86, caARM, caRISCV);
  // Generic, cross-arch features for upper layers
  TGenericFeature = (
    gfSimd128,   // 128-bit SIMD available
    gfSimd256,   // 256-bit SIMD available
    gfSimd512,   // 512-bit SIMD available
    gfAES,       // AES instructions
    gfSHA,       // SHA instructions
    gfFMA        // Fused multiply-add
  );
  TGenericFeatureSet = set of TGenericFeature;

  // x86 CPU features
  TX86Features = record
    HasMMX: Boolean;
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
    HasAVX512VL: Boolean;
    HasAVX512VBMI: Boolean;

    HasFMA: Boolean;
    HasFMA4: Boolean;

    HasBMI1: Boolean;
    HasBMI2: Boolean;

    HasAES: Boolean;
    HasPCLMULQDQ: Boolean;
    HasSHA: Boolean;

    HasRDRAND: Boolean;
    HasRDSEED: Boolean;
    HasF16C: Boolean;
  end;

  // Arch-specific ISA enums for strong-typed queries
  TX86ISA = (
    xMMX, xSSE, xSSE2, xSSE3, xSSSE3, xSSE41, xSSE42,
    xAVX, xAVX2, xAVX512F, xAVX512DQ, xAVX512BW, xAVX512VL, xAVX512VBMI,
    xAES, xSHA, xPCLMULQDQ, xFMA, xFMA4, xBMI1, xBMI2, xF16C, xRDRAND, xRDSEED
  );

  // ARM CPU features
  TARMFeatures = record
    HasNEON: Boolean;
    HasFP: Boolean;
    HasAdvSIMD: Boolean;
    HasSVE: Boolean;
    HasCrypto: Boolean;
  end;

  TARMISA = (aNEON, aAdvSIMD, aSVE, aCrypto);

  // RISC-V CPU features
  TRISCVFeatures = record
    HasRV32I: Boolean;
    HasRV64I: Boolean;
    HasM: Boolean;
    HasA: Boolean;
    HasF: Boolean;
    HasD: Boolean;
    HasC: Boolean;
    HasV: Boolean;
  end;

  TRISCVISA = (rvV, rvF, rvD, rvA, rvC);

  // x86 Cache information
  TX86CacheInfo = record
    L1DataCache: Integer;        // KB
    L1InstructionCache: Integer; // KB
    L2Cache: Integer;            // KB
    L3Cache: Integer;            // KB
    CacheLineSize: Integer;      // bytes
  end;

  // Generic Cache information
  TCacheInfo = record
    L1DataKB: Integer;
    L1InstrKB: Integer;
    L2KB: Integer;
    L3KB: Integer;
    LineSize: Integer; // bytes
  end;

  // Combined CPU information (cross-arch container)
  TCPUInfo = record
    Arch: TCPUArch;
    Vendor: string;
    Model: string;
    LogicalCores: Integer;
    PhysicalCores: Integer;
    Cache: TCacheInfo;
    OSXSAVE: Boolean;
    XCR0: UInt64;
    GenericRaw: TGenericFeatureSet;
    GenericUsable: TGenericFeatureSet;
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

implementation

end.





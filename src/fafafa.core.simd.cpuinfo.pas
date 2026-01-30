unit fafafa.core.simd.cpuinfo;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.simd.base,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.atomic
  {$IFDEF WINDOWS}
  , fafafa.core.simd.cpuinfo.windows
  {$ELSE}
    {$IFDEF DARWIN}
    , fafafa.core.simd.cpuinfo.darwin
    {$ELSE}
      {$IFDEF UNIX}
      , fafafa.core.simd.cpuinfo.unix
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
  ;

// === CPU Feature Detection Facade ===
// 纯门面模式：委托给平台特定的实现模块

type
  // Array type for backend list
  TSimdBackendArray = array of TSimdBackend;

// === 公共门面 API ===

// Get comprehensive CPU information (thread-safe)
function GetCPUInfo: TCPUInfo;

// Architecture detection helpers
function DetectCPUArchitecture: TCPUArch;

// Feature query helpers (quick checks)
function HasFeature(feature: TGenericFeature): Boolean;
function GetSupportedBackends: TSimdBackendArray;
function GetAvailableBackends: TSimdBackendArray; // alias for backward compatibility

// ✅ P2: 添加 GetBestBackend 别名函数（向后兼容）
// 注意：此函数委托给 dispatch 模块的 GetActiveBackend
function GetBestBackend: TSimdBackend;

// Cache and lifecycle helpers
procedure ResetCPUInfo; // safe reset for re-initialization

// Quick feature detection (commonly used)
function HasSSE2: Boolean;
function HasSSE3: Boolean;
function HasSSSE3: Boolean;
function HasSSE41: Boolean;
function HasSSE42: Boolean;
function HasAVX2: Boolean;
function HasAVX512: Boolean;
function HasNEON: Boolean;
function HasRISCVV: Boolean;

{$IFDEF SIMD_X86_AVAILABLE}
function GetX86CPUInfo: TX86Features;
{$ENDIF}

{$IFDEF SIMD_ARM_AVAILABLE}
function GetARMCPUInfo: TARMFeatures;
{$ENDIF}

{$IFDEF SIMD_RISCV_AVAILABLE}
function GetRISCVCPUInfo: TRISCVFeatures;
{$ENDIF}

implementation

// Platform-specific imports
{$IF DEFINED(SIMD_X86_AVAILABLE) OR DEFINED(SIMD_ARM_AVAILABLE) OR DEFINED(SIMD_RISCV_AVAILABLE)}
uses
  {$IFDEF SIMD_X86_AVAILABLE}
  fafafa.core.simd.cpuinfo.x86
    {$IF DEFINED(SIMD_ARM_AVAILABLE) OR DEFINED(SIMD_RISCV_AVAILABLE)}
    ,
    {$ENDIF}
  {$ENDIF}
  {$IFDEF SIMD_ARM_AVAILABLE}
  fafafa.core.simd.cpuinfo.arm
    {$IFDEF SIMD_RISCV_AVAILABLE}
    ,
    {$ENDIF}
  {$ENDIF}
  {$IFDEF SIMD_RISCV_AVAILABLE}
  fafafa.core.simd.cpuinfo.riscv
  {$ENDIF}
  ;
{$ENDIF}

var
  // Global CPU info cache
  G_CPUInfo: TCPUInfo;
  // Initialization state: 0=uninitialized, 1=initializing, 2=initialized
  G_InitState: Int32 = 0;

function X86_XCR0_EnablesAVX: Boolean; inline;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := ((G_CPUInfo.XCR0 and (UInt64(1) shl 1)) <> 0) {XMM}
            and ((G_CPUInfo.XCR0 and (UInt64(1) shl 2)) <> 0); {YMM}
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

{$IFDEF SIMD_X86_AVAILABLE}
function DetectX86Architecture: TCPUArch;
begin
  // All x86 variants map to caX86 in this simplified enum
  Result := caX86;
end;
{$ENDIF}

// Detect CPU architecture dynamically
function DetectCPUArchitecture: TCPUArch;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := DetectX86Architecture;
  {$ELSE}
    {$IFDEF SIMD_ARM_AVAILABLE}
    Result := caARM;
    {$ELSE}
      {$IFDEF SIMD_RISCV_AVAILABLE}
      Result := caRISCV;
      {$ELSE}
      Result := caUnknown;
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
end;

// Cross-platform core count detection dispatcher via platform-specific units
function DetectCoreCountsPortable(out Physical, Logical: LongInt): Boolean;
begin
  Physical := 0;
  Logical := 0;
  {$IFDEF WINDOWS}
  Result := fafafa.core.simd.cpuinfo.windows.DetectCoreCounts(Physical, Logical);
  {$ELSE}
    {$IFDEF DARWIN}
    Result := fafafa.core.simd.cpuinfo.darwin.DetectCoreCounts(Physical, Logical);
    {$ELSE}
      {$IFDEF UNIX}
      Result := fafafa.core.simd.cpuinfo.unix.DetectCoreCounts(Physical, Logical);
      {$ELSE}
      Result := False;
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
  if Physical < 1 then Physical := 1;
  if Logical < 1 then Logical := 1;
end;

// Internal initialization worker (no concurrency guards)
procedure InitializeCPUInfoInternal;
{$IFDEF SIMD_X86_AVAILABLE}
var
  CacheInfo: TX86CacheInfo;
  eax, ebx, ecx, edx: DWord;
{$ENDIF}
var
  PhysC, LogC: LongInt;
begin
  // 设定架构
  G_CPUInfo.Arch := DetectCPUArchitecture;
  
  // 委托给平台特定的检测模块
  {$IFDEF SIMD_X86_AVAILABLE}
  if G_CPUInfo.Arch = caX86 then
  begin
    fafafa.core.simd.cpuinfo.x86.DetectX86VendorAndModel(G_CPUInfo);
    G_CPUInfo.X86 := fafafa.core.simd.cpuinfo.x86.DetectX86Features;

    // OSXSAVE / XCR0 (precise detection)
    // Initialize locals to keep the compiler happy (CPUID is implemented in asm).
    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUID($00000001, eax, ebx, ecx, edx);
    G_CPUInfo.OSXSAVE := ((ecx and (1 shl 27)) <> 0);
    if G_CPUInfo.OSXSAVE then
      G_CPUInfo.XCR0 := fafafa.core.simd.cpuinfo.x86.ReadXCR0
    else
      G_CPUInfo.XCR0 := 0;
    
    // Convert x86 cache info to generic format
    CacheInfo := fafafa.core.simd.cpuinfo.x86.GetX86CacheInfo;
    G_CPUInfo.Cache.L1DataKB := CacheInfo.L1DataCache;
    G_CPUInfo.Cache.L1InstrKB := CacheInfo.L1InstructionCache;
    G_CPUInfo.Cache.L2KB := CacheInfo.L2Cache;
    G_CPUInfo.Cache.L3KB := CacheInfo.L3Cache;
    G_CPUInfo.Cache.LineSize := CacheInfo.CacheLineSize;
  end;
  {$ENDIF}
  
  {$IFDEF SIMD_ARM_AVAILABLE}
  if G_CPUInfo.Arch = caARM then
  begin
    fafafa.core.simd.cpuinfo.arm.DetectARMVendorAndModel(G_CPUInfo);
    G_CPUInfo.ARM := fafafa.core.simd.cpuinfo.arm.DetectARMFeatures;
    
    // ARM cache detection would go here
    G_CPUInfo.Cache.LineSize := 64; // Common ARM cache line size
  end;
  {$ENDIF}
  
  {$IFDEF SIMD_RISCV_AVAILABLE}
  if G_CPUInfo.Arch = caRISCV then
  begin
    fafafa.core.simd.cpuinfo.riscv.DetectRISCVVendorAndModel(G_CPUInfo);
    G_CPUInfo.RISCV := fafafa.core.simd.cpuinfo.riscv.DetectRISCVFeatures;
    
    // RISC-V cache detection would go here
    G_CPUInfo.Cache.LineSize := 64; // Common RISC-V cache line size
  end;
  {$ENDIF}
  
  // Fallback for unknown architectures
  if G_CPUInfo.Arch = caUnknown then
  begin
    G_CPUInfo.Vendor := 'Unknown';
    G_CPUInfo.Model := 'Unknown CPU';
    G_CPUInfo.PhysicalCores := 1;
    G_CPUInfo.LogicalCores := 1;
    G_CPUInfo.Cache.LineSize := 64;
  end;
  
  // Core count detection (cross-platform best effort)
  if DetectCoreCountsPortable(PhysC, LogC) then
  begin
    G_CPUInfo.PhysicalCores := PhysC;
    G_CPUInfo.LogicalCores := LogC;
  end
  else
  begin
    if G_CPUInfo.LogicalCores = 0 then
    begin
      G_CPUInfo.PhysicalCores := 1;
      G_CPUInfo.LogicalCores := 1;
    end;
  end;

  // Populate GenericRaw / GenericUsable
  G_CPUInfo.GenericRaw := [];
  G_CPUInfo.GenericUsable := [];
  case G_CPUInfo.Arch of
    {$IFDEF SIMD_X86_AVAILABLE}
    caX86:
      begin
        if G_CPUInfo.X86.HasSSE2 then Include(G_CPUInfo.GenericRaw, gfSimd128);
        if G_CPUInfo.X86.HasAVX or G_CPUInfo.X86.HasAVX2 then Include(G_CPUInfo.GenericRaw, gfSimd256);
        if G_CPUInfo.X86.HasAVX512F then Include(G_CPUInfo.GenericRaw, gfSimd512);
        if G_CPUInfo.X86.HasAES then Include(G_CPUInfo.GenericRaw, gfAES);
        if G_CPUInfo.X86.HasFMA then Include(G_CPUInfo.GenericRaw, gfFMA);
        if G_CPUInfo.X86.HasSHA then Include(G_CPUInfo.GenericRaw, gfSHA);
        // OS usable checks
        if G_CPUInfo.X86.HasSSE2 then Include(G_CPUInfo.GenericUsable, gfSimd128);
        if (G_CPUInfo.X86.HasAVX or G_CPUInfo.X86.HasAVX2) and (fafafa.core.simd.cpuinfo.x86.IsAVXSupportedByOS) and X86_XCR0_EnablesAVX then Include(G_CPUInfo.GenericUsable, gfSimd256);
        if G_CPUInfo.X86.HasAVX512F and (fafafa.core.simd.cpuinfo.x86.IsAVXSupportedByOS) and X86_XCR0_EnablesAVX then Include(G_CPUInfo.GenericUsable, gfSimd512);
        if G_CPUInfo.X86.HasAES then Include(G_CPUInfo.GenericUsable, gfAES);
        if G_CPUInfo.X86.HasFMA and (fafafa.core.simd.cpuinfo.x86.IsAVXSupportedByOS) and X86_XCR0_EnablesAVX then Include(G_CPUInfo.GenericUsable, gfFMA);
        if G_CPUInfo.X86.HasSHA then Include(G_CPUInfo.GenericUsable, gfSHA);
      end;
    {$ENDIF}
    {$IFDEF SIMD_ARM_AVAILABLE}
    caARM:
      begin
        if G_CPUInfo.ARM.HasNEON then Include(G_CPUInfo.GenericRaw, gfSimd128);
        if G_CPUInfo.ARM.HasSVE then
        begin
          Include(G_CPUInfo.GenericRaw, gfSimd256);
          Include(G_CPUInfo.GenericRaw, gfSimd512);
        end;
        if G_CPUInfo.ARM.HasCrypto then Include(G_CPUInfo.GenericRaw, gfAES);
        // ARM: assume OS usability aligns with hardware availability for NEON/SVE in user space
        G_CPUInfo.GenericUsable := G_CPUInfo.GenericRaw;
      end;
    {$ENDIF}
    {$IFDEF SIMD_RISCV_AVAILABLE}
    caRISCV:
      begin
        if G_CPUInfo.RISCV.HasV then
        begin
          Include(G_CPUInfo.GenericRaw, gfSimd128);
          Include(G_CPUInfo.GenericRaw, gfSimd256);
          Include(G_CPUInfo.GenericRaw, gfSimd512);
        end;
        G_CPUInfo.GenericUsable := G_CPUInfo.GenericRaw;
      end;
    {$ENDIF}
  else
    ;
  end;
end;

// Single-time initialization with atomic state machine
function AtomicCAS(var Target: Int32; Expected, Desired: Int32): Boolean; inline;
var
  Exp: Int32;
begin
  Exp := Expected;
  Result := atomic_compare_exchange(Target, Exp, Desired);
end;

procedure EnsureCPUInfoInitialized;
begin
  if G_InitState = 2 then Exit;
  // Try to acquire initialization
  if AtomicCAS(G_InitState, 0, 1) then
  begin
    try
      InitializeCPUInfoInternal;
      atomic_thread_fence(mo_seq_cst); // Ensure visibility of G_CPUInfo writes
      G_InitState := 2;
    except
      G_InitState := 0; // rollback on failure
      raise;
    end;
  end
  else
  begin
    // Wait for the concurrent initializer to finish
    while G_InitState <> 2 do
    begin
      atomic_thread_fence(mo_seq_cst);
      // Yield to scheduler to avoid busy spin on all platforms
      SysUtils.Sleep(0);
    end;
  end;
end;

// Main CPU info getter (thread-safe)
function GetCPUInfo: TCPUInfo;
begin
  if G_InitState <> 2 then
    EnsureCPUInfoInitialized;
  Result := G_CPUInfo;
end;

// Quick feature checker（基于“可用”能力，而非仅硬件）
function HasFeature(feature: TGenericFeature): Boolean;
var
  C: TCPUInfo;
begin
  C := GetCPUInfo;
  Result := feature in C.GenericUsable;
end;

// Get list of supported SIMD backends（仅暴露 OS 已使能的能力）
function GetSupportedBackends: TSimdBackendArray;
var
  C: TCPUInfo;
  L: TSimdBackendArray;
  procedure Add(const B: TSimdBackend);
  var n: Integer;
  begin
    n := Length(L);
    SetLength(L, n+1);
    L[n] := B;
  end;
begin
  C := GetCPUInfo;
  // Always include scalar
  Add(sbScalar);

  {$IFDEF SIMD_X86_AVAILABLE}
  if C.Arch = caX86 then
  begin
    // SSE family: 按演进顺序添加，每个后端要求对应的 CPU 特性
    if (gfSimd128 in C.GenericUsable) then Add(sbSSE2);
    if (gfSimd128 in C.GenericUsable) and C.X86.HasSSE3 then Add(sbSSE3);
    if (gfSimd128 in C.GenericUsable) and C.X86.HasSSSE3 then Add(sbSSSE3);
    if (gfSimd128 in C.GenericUsable) and C.X86.HasSSE41 then Add(sbSSE41);
    if (gfSimd128 in C.GenericUsable) and C.X86.HasSSE42 then Add(sbSSE42);
    // AVX family: 需要 OS 支持 (XCR0)
    if (gfSimd256 in C.GenericUsable) and C.X86.HasAVX2 then Add(sbAVX2);
    if (gfSimd512 in C.GenericUsable) and C.X86.HasAVX512F then Add(sbAVX512);
  end;
  {$ENDIF}

  {$IFDEF SIMD_ARM_AVAILABLE}
  if C.Arch = caARM then
  begin
    if (gfSimd128 in C.GenericUsable) then Add(sbNEON);
  end;
  {$ENDIF}

  {$IFDEF SIMD_RISCV_AVAILABLE}
  if C.Arch = caRISCV then
  begin
    if (gfSimd128 in C.GenericUsable) or (gfSimd256 in C.GenericUsable) or (gfSimd512 in C.GenericUsable) then Add(sbRISCVV);
  end;
  {$ENDIF}

  Result := L;
end;

{$IFDEF SIMD_X86_AVAILABLE}
function GetX86CPUInfo: TX86Features;
var
  cpuInfo: TCPUInfo;
begin
  cpuInfo := GetCPUInfo;
  if cpuInfo.Arch = caX86 then
    Result := cpuInfo.X86
  else
    FillChar(Result, SizeOf(Result), 0);
end;
{$ENDIF}

{$IFDEF SIMD_ARM_AVAILABLE}
function GetARMCPUInfo: TARMFeatures;
var
  cpuInfo: TCPUInfo;
begin
  cpuInfo := GetCPUInfo;
  if cpuInfo.Arch = caARM then
    Result := cpuInfo.ARM
  else
    FillChar(Result, SizeOf(Result), 0);
end;
{$ENDIF}

{$IFDEF SIMD_RISCV_AVAILABLE}
function GetRISCVCPUInfo: TRISCVFeatures;
var
  cpuInfo: TCPUInfo;
begin
  cpuInfo := GetCPUInfo;
  if cpuInfo.Arch = caRISCV then
    Result := cpuInfo.RISCV
  else
    FillChar(Result, SizeOf(Result), 0);
end;
{$ENDIF}

// Backward-compatible alias
function GetAvailableBackends: TSimdBackendArray;
begin
  Result := GetSupportedBackends;
end;

// ✅ P2: GetBestBackend 实现 - 返回当前 CPU 支持的最佳后端
// 优先级: AVX512 > AVX2 > SSE4.2 > SSE4.1 > SSSE3 > SSE3 > SSE2 > NEON > RISCVV > Scalar
function GetBestBackend: TSimdBackend;
const
  BACKEND_PRIORITY: array[0..9] of TSimdBackend = (
    sbAVX512, sbAVX2, sbSSE42, sbSSE41, sbSSSE3, sbSSE3, sbSSE2, sbNEON, sbRISCVV, sbScalar
  );
var
  backends: TSimdBackendArray;
  i, j: Integer;
begin
  backends := GetSupportedBackends;

  // 按优先级顺序查找第一个可用的后端
  for i := Low(BACKEND_PRIORITY) to High(BACKEND_PRIORITY) do
    for j := 0 to High(backends) do
      if backends[j] = BACKEND_PRIORITY[i] then
        Exit(BACKEND_PRIORITY[i]);

  // 默认回退到 Scalar
  Result := sbScalar;
end;

// Safe reset to force re-detection on next query
procedure ResetCPUInfo;
begin
  // Clear structure
  FillChar(G_CPUInfo, SizeOf(G_CPUInfo), 0);
  atomic_thread_fence(mo_seq_cst);
  // Reset init state
  G_InitState := 0;
end;

// === Quick feature detection ===

function HasSSE2: Boolean;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caX86) and cpuInfo.X86.HasSSE2;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasSSE3: Boolean;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caX86) and cpuInfo.X86.HasSSE3;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasSSSE3: Boolean;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caX86) and cpuInfo.X86.HasSSSE3;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasSSE41: Boolean;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caX86) and cpuInfo.X86.HasSSE41;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasSSE42: Boolean;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caX86) and cpuInfo.X86.HasSSE42;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasAVX2: Boolean;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caX86) and cpuInfo.X86.HasAVX2 and (gfSimd256 in cpuInfo.GenericUsable);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasAVX512: Boolean;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  cpuInfo := GetCPUInfo;
  // AVX-512 requires: AVX512F + OS support (XCR0 bits 5,6,7 for opmask, ZMM_Hi256, Hi16_ZMM)
  Result := (cpuInfo.Arch = caX86) and cpuInfo.X86.HasAVX512F and (gfSimd512 in cpuInfo.GenericUsable);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasNEON: Boolean;
{$IFDEF SIMD_ARM_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_ARM_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caARM) and cpuInfo.ARM.HasNEON;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HasRISCVV: Boolean;
{$IFDEF SIMD_RISCV_AVAILABLE}
var
  cpuInfo: TCPUInfo;
{$ENDIF}
begin
  {$IFDEF SIMD_RISCV_AVAILABLE}
  cpuInfo := GetCPUInfo;
  Result := (cpuInfo.Arch = caRISCV) and cpuInfo.RISCV.HasV;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

end.

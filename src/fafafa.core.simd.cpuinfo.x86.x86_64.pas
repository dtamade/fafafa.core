unit fafafa.core.simd.cpuinfo.x86.x86_64;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$ASMMODE INTEL}

interface

uses
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.cpuinfo.x86.base;

// 架构实现（x86_64）：导出�?x86 门面一致的 API

function HasCPUID: Boolean;
procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
function ReadXCR0: UInt64;

function DetectX86Features: TX86Features;
procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
function GetX86CacheInfo: TX86CacheInfo;
function IsAVXSupportedByOS: Boolean;

implementation

type
  TCPUIDResult = array[0..3] of DWord;

function HasCPUID: Boolean;
begin
  // CPUID is always available on x86-64
  Result := True;
end;

function ActualCPUID(leaf: DWord): TCPUIDResult;
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    push rbx
    mov eax, leaf
    cpuid
    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx
    pop rbx
  end;
  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;

procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
var
  r: TCPUIDResult;
begin
  r := ActualCPUID(EAX);
  EAX_Out := r[0];
  EBX_Out := r[1];
  ECX_Out := r[2];
  EDX_Out := r[3];
end;

function ActualCPUIDEX(leaf, ecx_in: DWord): TCPUIDResult;
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    push rbx
    mov eax, leaf
    mov ecx, ecx_in
    cpuid
    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx
    pop rbx
  end;
  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
var
  r: TCPUIDResult;
begin
  r := ActualCPUIDEX(EAX, ECX_In);
  EAX_Out := r[0];
  EBX_Out := r[1];
  ECX_Out := r[2];
  EDX_Out := r[3];
end;

function ReadXCR0: UInt64;
var
  result_eax, result_edx: DWord;
begin
  try
    asm
      mov ecx, 0
      xgetbv
      mov result_eax, eax
      mov result_edx, edx
    end;
    Result := (UInt64(result_edx) shl 32) or result_eax;
  except
    Result := 0;
  end;
end;

function IsAVXSupportedByOS: Boolean;
var
  eax, ebx, ecx, edx: DWord;
  xcr0: UInt64;
begin
  Result := False;
  CPUID(1, eax, ebx, ecx, edx);
  if (ecx and (1 shl 27)) = 0 then Exit; // OSXSAVE
  xcr0 := ReadXCR0;
  Result := XCR0HasAVX(xcr0);
end;

function DetectX86Features: TX86Features;
var
  eax, ebx, ecx, edx: DWord;
  maxLeaf, maxExtLeaf: DWord;
  xcr0: UInt64;
  osxsave: Boolean;
begin
  FillChar(Result, SizeOf(Result), 0);
  CPUID(0, maxLeaf, ebx, ecx, edx);
  if maxLeaf < 1 then Exit;
  CPUID(1, eax, ebx, ecx, edx);
  Result.HasMMX := (edx and (1 shl 23)) <> 0;
  Result.HasSSE := (edx and (1 shl 25)) <> 0;
  Result.HasSSE2 := (edx and (1 shl 26)) <> 0;
  Result.HasSSE3 := (ecx and (1 shl 0)) <> 0;
  Result.HasPCLMULQDQ := (ecx and (1 shl 1)) <> 0;
  Result.HasSSSE3 := (ecx and (1 shl 9)) <> 0;
  Result.HasFMA := (ecx and (1 shl 12)) <> 0;
  Result.HasSSE41 := (ecx and (1 shl 19)) <> 0;
  Result.HasSSE42 := (ecx and (1 shl 20)) <> 0;
  Result.HasAES := (ecx and (1 shl 25)) <> 0;
  Result.HasAVX := (ecx and (1 shl 28)) <> 0;
  Result.HasF16C := (ecx and (1 shl 29)) <> 0;
  Result.HasRDRAND := (ecx and (1 shl 30)) <> 0;
  osxsave := (ecx and (1 shl 27)) <> 0;
  if osxsave then xcr0 := ReadXCR0 else xcr0 := 0;
  if Result.HasAVX then Result.HasAVX := XCR0HasAVX(xcr0);
  if maxLeaf >= 7 then
  begin
    CPUIDEX(7, 0, eax, ebx, ecx, edx);
    Result.HasBMI1 := (ebx and (1 shl 3)) <> 0;
    Result.HasAVX2 := (ebx and (1 shl 5)) <> 0;
    Result.HasBMI2 := (ebx and (1 shl 8)) <> 0;
    Result.HasAVX512F := (ebx and (1 shl 16)) <> 0;
    Result.HasAVX512DQ := (ebx and (1 shl 17)) <> 0;
    Result.HasAVX512BW := (ebx and (1 shl 30)) <> 0;
    Result.HasAVX512VL := (ebx and (1 shl 31)) <> 0;
    Result.HasAVX512VBMI := (ecx and (1 shl 1)) <> 0;
    Result.HasSHA := (ebx and (1 shl 29)) <> 0;
    Result.HasRDSEED := (ecx and (1 shl 18)) <> 0;
    if not Result.HasAVX then
    begin
      Result.HasAVX2 := False;
      Result.HasFMA := False;
    end;
    if not Result.HasAVX2 then
    begin
      Result.HasAVX512F := False;
      Result.HasAVX512DQ := False;
      Result.HasAVX512BW := False;
      Result.HasAVX512VL := False;
      Result.HasAVX512VBMI := False;
    end;
    if not XCR0HasAVX512(xcr0) then
    begin
      Result.HasAVX512F := False;
      Result.HasAVX512DQ := False;
      Result.HasAVX512BW := False;
      Result.HasAVX512VL := False;
      Result.HasAVX512VBMI := False;
    end;
  end;
  CPUID($80000000, maxExtLeaf, ebx, ecx, edx);
  if maxExtLeaf >= $80000001 then
  begin
    CPUID($80000001, eax, ebx, ecx, edx);
    Result.HasFMA4 := (ecx and (1 shl 16)) <> 0;
  end;
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
var
  eax, ebx, ecx, edx: DWord;
  vendorString: array[0..12] of AnsiChar;
  brandString: array[0..48] of AnsiChar;
begin
  CPUID(0, eax, ebx, ecx, edx);
  Move(ebx, vendorString[0], 4);
  Move(edx, vendorString[4], 4);
  Move(ecx, vendorString[8], 4);
  vendorString[12] := #0;
  cpuInfo.Vendor := string(vendorString);
  
  // 检测OSXSAVE和XCR0
  CPUID(1, eax, ebx, ecx, edx);
  cpuInfo.OSXSAVE := (ecx and (1 shl 27)) <> 0;
  if cpuInfo.OSXSAVE then
    cpuInfo.XCR0 := ReadXCR0
  else
    cpuInfo.XCR0 := 0;
  FillChar(brandString, SizeOf(brandString), 0);
  CPUID($80000000, eax, ebx, ecx, edx);
  if eax >= $80000004 then
  begin
    CPUID($80000002, eax, ebx, ecx, edx);
    Move(eax, brandString[0], 4);
    Move(ebx, brandString[4], 4);
    Move(ecx, brandString[8], 4);
    Move(edx, brandString[12], 4);
    CPUID($80000003, eax, ebx, ecx, edx);
    Move(eax, brandString[16], 4);
    Move(ebx, brandString[20], 4);
    Move(ecx, brandString[24], 4);
    Move(edx, brandString[28], 4);
    CPUID($80000004, eax, ebx, ecx, edx);
    Move(eax, brandString[32], 4);
    Move(ebx, brandString[36], 4);
    Move(ecx, brandString[40], 4);
    Move(edx, brandString[44], 4);
    cpuInfo.Model := string(brandString);
  end
  else
  begin
    cpuInfo.Model := cpuInfo.Vendor + ' Processor';
  end;
  if cpuInfo.Model = '' then
    cpuInfo.Model := cpuInfo.Vendor + ' Processor';
end;

function GetX86CacheInfo: TX86CacheInfo;
var
  eax, ebx, ecx, edx: DWord;
  maxLeaf: DWord;
  i, subleaf: Integer;
  cacheType, cacheLevel, cacheSets: DWord;
  cacheLineSize, cachePartitions, cacheWays: DWord;
  cacheSize: DWord;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  // First, try to get cache info from leaf 4 (Deterministic Cache Parameters)
  CPUID(0, maxLeaf, ebx, ecx, edx);
  if maxLeaf >= 4 then
  begin
    subleaf := 0;
    repeat
      CPUIDEX(4, subleaf, eax, ebx, ecx, edx);
      cacheType := eax and $1F;
      
      if cacheType <> 0 then  // 0 = No more caches
      begin
        cacheLevel := (eax shr 5) and $07;
        cacheLineSize := (ebx and $FFF) + 1;
        cachePartitions := ((ebx shr 12) and $3FF) + 1;
        cacheWays := ((ebx shr 22) and $3FF) + 1;
        cacheSets := ecx + 1;
        
        // Calculate cache size in KB
        cacheSize := (cacheWays * cachePartitions * cacheLineSize * cacheSets) div 1024;
        
        case cacheLevel of
          1: // L1 cache
            begin
              if cacheType = 1 then  // Data cache
                Result.L1DataCache := cacheSize
              else if cacheType = 2 then  // Instruction cache
                Result.L1InstructionCache := cacheSize;
            end;
          2: // L2 cache
            Result.L2Cache := cacheSize;
          3: // L3 cache
            Result.L3Cache := cacheSize;
        end;
      end;
      
      Inc(subleaf);
    until (cacheType = 0) or (subleaf > 10);  // Safety limit
    
    // Get cache line size from the first valid cache
    if Result.CacheLineSize = 0 then
    begin
      CPUIDEX(4, 0, eax, ebx, ecx, edx);
      if (eax and $1F) <> 0 then
        Result.CacheLineSize := (ebx and $FFF) + 1;
    end;
  end;
  
  // Fallback to extended CPUID leaves if leaf 4 didn't work or as supplement
  CPUID($80000000, maxLeaf, ebx, ecx, edx);
  
  // Get L1 cache info from leaf $80000005 if available and not already set
  if (maxLeaf >= $80000005) and (Result.L1DataCache = 0) then
  begin
    CPUID($80000005, eax, ebx, ecx, edx);
    if Result.L1DataCache = 0 then
      Result.L1DataCache := (ecx shr 24) and $FF;  // L1 D-cache size in KB
    if Result.L1InstructionCache = 0 then  
      Result.L1InstructionCache := (edx shr 24) and $FF;  // L1 I-cache size in KB
    if Result.CacheLineSize = 0 then
      Result.CacheLineSize := ecx and $FF;  // L1 D-cache line size
  end;
  
  // Get L2/L3 cache info from leaf $80000006
  if maxLeaf >= $80000006 then
  begin
    CPUID($80000006, eax, ebx, ecx, edx);
    if Result.L2Cache = 0 then
      Result.L2Cache := (ecx shr 16) and $FFFF;  // L2 cache size in KB
    if Result.L3Cache = 0 then
    begin
      // L3 cache size: bits 31-18 contain the size in 512KB units
      Result.L3Cache := ((edx shr 18) and $3FFF) * 512;  // Convert to KB
    end;
    if Result.CacheLineSize = 0 then
      Result.CacheLineSize := ecx and $FF;  // L2 cache line size
  end;
  
  // Default values if detection failed
  if Result.CacheLineSize = 0 then
    Result.CacheLineSize := 64;  // Common default
end;

end.





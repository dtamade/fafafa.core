unit fafafa.core.simd.cpuinfo.x86;

{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_X86_AVAILABLE}

uses
  SysUtils,
  fafafa.core.simd.types;

// === x86/x64 CPU Detection Interface ===

// Check if CPUID instruction is available
function HasCPUID: Boolean;

// Execute CPUID instruction
procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);

// Execute CPUID with ECX input (for extended leaves)
procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);

// Detect all x86 features
function DetectX86Features: TX86Features;

// Detect x86 vendor and model information
procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);

// Check if OS supports AVX (requires XGETBV)
function IsAVXSupportedByOS: Boolean;

// Get x86 cache information
function GetX86CacheInfo: TX86CacheInfo;

implementation

// === CPUID Instruction Implementation ===

function HasCPUID: Boolean;
{$IFDEF CPUX86_64}
begin
  // CPUID is always available on x86-64
  Result := True;
end;
{$ELSE}
asm
  // Try to flip ID bit (bit 21) in EFLAGS
  pushfd
  pop eax
  mov ecx, eax
  xor eax, $200000
  push eax
  popfd
  pushfd
  pop eax
  xor eax, ecx
  shr eax, 21
  and eax, 1
  push ecx
  popfd
end;
{$ENDIF}

procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  if not HasCPUID then
  begin
    EAX_Out := 0;
    EBX_Out := 0;
    ECX_Out := 0;
    EDX_Out := 0;
    Exit;
  end;

  try
    {$IFDEF CPUX86_64}
    // Use external assembly or simplified approach for FreePascal
    // FreePascal's inline assembly syntax is different
    // For now, use a fallback implementation
    EAX_Out := 0;
    EBX_Out := 0;
    ECX_Out := 0;
    EDX_Out := 0;

    // TODO: Implement proper CPUID for FreePascal x64
    {$ELSE}
    asm
      push ebx
      push edi
      push esi
      
      // Execute CPUID
      cpuid
      
      // Store results using parameter addresses
      mov esi, EAX_Out
      mov [esi], eax
      
      mov esi, EBX_Out
      mov [esi], ebx
      
      mov esi, ECX_Out
      mov [esi], ecx
      
      mov esi, EDX_Out
      mov [esi], edx
      
      pop esi
      pop edi
      pop ebx
    end;
    {$ENDIF}
  except
    // If CPUID fails, return zeros
    EAX_Out := 0;
    EBX_Out := 0;
    ECX_Out := 0;
    EDX_Out := 0;
  end;
end;

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  if not HasCPUID then
  begin
    EAX_Out := 0;
    EBX_Out := 0;
    ECX_Out := 0;
    EDX_Out := 0;
    Exit;
  end;

  try
    {$IFDEF CPUX86_64}
    // Use fallback implementation for FreePascal x64
    EAX_Out := 0;
    EBX_Out := 0;
    ECX_Out := 0;
    EDX_Out := 0;

    // TODO: Implement proper CPUIDEX for FreePascal x64
    {$ELSE}
    asm
      push ebx
      push edi
      push esi
      
      // Set inputs
      mov esi, eax      // Save EAX input
      mov edi, ECX_In   // Get ECX input
      
      mov eax, esi
      mov ecx, edi
      
      // Execute CPUID
      cpuid
      
      // Store results
      mov esi, EAX_Out
      mov [esi], eax
      
      mov esi, EBX_Out
      mov [esi], ebx
      
      mov esi, ECX_Out
      mov [esi], ecx
      
      mov esi, EDX_Out
      mov [esi], edx
      
      pop esi
      pop edi
      pop ebx
    end;
    {$ENDIF}
  except
    // If CPUIDEX fails, return zeros
    EAX_Out := 0;
    EBX_Out := 0;
    ECX_Out := 0;
    EDX_Out := 0;
  end;
end;

// === XGETBV Implementation for AVX OS Support ===

function XGETBV(ECX: DWord): UInt64;
begin
  // Fallback implementation - assume AVX is supported by OS
  // TODO: Implement proper XGETBV for FreePascal
  Result := $06; // XCR0 with AVX state saving enabled
end;

function IsAVXSupportedByOS: Boolean;
var
  eax, ebx, ecx, edx: DWord;
  xcr0: UInt64;
begin
  Result := False;
  
  try
    // Check if OSXSAVE is supported
    CPUID(1, eax, ebx, ecx, edx);
    if (ecx and (1 shl 27)) = 0 then
      Exit; // OSXSAVE not supported
    
    // Check XCR0 register for AVX state saving
    xcr0 := XGETBV(0);
    
    // Check if OS saves AVX state (bits 1 and 2 must be set)
    Result := (xcr0 and $06) = $06;
  except
    // If XGETBV fails, assume no AVX support
    Result := False;
  end;
end;

// === x86 Feature Detection ===

function DetectX86Features: TX86Features;
var
  eax, ebx, ecx, edx: DWord;
  maxLeaf, maxExtLeaf: DWord;
begin
  FillChar(Result, SizeOf(Result), 0);

  if not HasCPUID then
    Exit;

  try
    // Get maximum supported leaf
    CPUID(0, maxLeaf, ebx, ecx, edx);
    if maxLeaf < 1 then
      Exit;

    // Get basic feature information (Leaf 1)
    CPUID(1, eax, ebx, ecx, edx);

    // Check SSE features (EDX register)
    Result.HasSSE := (edx and (1 shl 25)) <> 0;
    Result.HasSSE2 := (edx and (1 shl 26)) <> 0;

    // Check SSE3+ features (ECX register)
    Result.HasSSE3 := (ecx and (1 shl 0)) <> 0;
    Result.HasSSSE3 := (ecx and (1 shl 9)) <> 0;
    Result.HasSSE41 := (ecx and (1 shl 19)) <> 0;
    Result.HasSSE42 := (ecx and (1 shl 20)) <> 0;

    // Check AVX features
    Result.HasAVX := (ecx and (1 shl 28)) <> 0;
    Result.HasFMA := (ecx and (1 shl 12)) <> 0;

    // Verify OS support for AVX
    if Result.HasAVX then
      Result.HasAVX := IsAVXSupportedByOS;

    // Check extended features (Leaf 7, Sub-leaf 0)
    if maxLeaf >= 7 then
    begin
      CPUIDEX(7, 0, eax, ebx, ecx, edx);

      // EBX register features
      Result.HasAVX2 := (ebx and (1 shl 5)) <> 0;
      Result.HasAVX512F := (ebx and (1 shl 16)) <> 0;
      Result.HasAVX512DQ := (ebx and (1 shl 17)) <> 0;
      Result.HasAVX512BW := (ebx and (1 shl 30)) <> 0;

      // Validate feature hierarchy
      if not Result.HasAVX then
        Result.HasAVX2 := False;

      if not Result.HasAVX2 then
      begin
        Result.HasAVX512F := False;
        Result.HasAVX512DQ := False;
        Result.HasAVX512BW := False;
      end;
    end;

    // Check extended function availability
    CPUID($80000000, maxExtLeaf, ebx, ecx, edx);

  except
    // If any CPUID call fails, return conservative defaults
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

// === Vendor and Model Detection ===

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
var
  eax, ebx, ecx, edx: DWord;
  vendorString: array[0..12] of AnsiChar;
  brandString: array[0..48] of AnsiChar;
begin
  if not HasCPUID then
  begin
    cpuInfo.Vendor := 'Unknown x86';
    cpuInfo.Model := 'Unknown x86 Processor';
    Exit;
  end;

  try
    // Get vendor string (Leaf 0)
    CPUID(0, eax, ebx, ecx, edx);

    // Vendor string is stored in EBX, EDX, ECX (in that order)
    Move(ebx, vendorString[0], 4);
    Move(edx, vendorString[4], 4);
    Move(ecx, vendorString[8], 4);
    vendorString[12] := #0;

    cpuInfo.Vendor := string(vendorString);

    // Get processor brand string (Leaves 80000002h-80000004h)
    FillChar(brandString, SizeOf(brandString), 0);

    // Check if extended functions are available
    CPUID($80000000, eax, ebx, ecx, edx);
    if eax >= $80000004 then
    begin
      // Get brand string part 1
      CPUID($80000002, eax, ebx, ecx, edx);
      Move(eax, brandString[0], 4);
      Move(ebx, brandString[4], 4);
      Move(ecx, brandString[8], 4);
      Move(edx, brandString[12], 4);

      // Get brand string part 2
      CPUID($80000003, eax, ebx, ecx, edx);
      Move(eax, brandString[16], 4);
      Move(ebx, brandString[20], 4);
      Move(ecx, brandString[24], 4);
      Move(edx, brandString[28], 4);

      // Get brand string part 3
      CPUID($80000004, eax, ebx, ecx, edx);
      Move(eax, brandString[32], 4);
      Move(ebx, brandString[36], 4);
      Move(ecx, brandString[40], 4);
      Move(edx, brandString[44], 4);

      // Trim leading/trailing spaces
      cpuInfo.Model := Trim(string(brandString));
    end
    else
    begin
      // Fallback: construct model from vendor and family/model info
      CPUID(1, eax, ebx, ecx, edx);
      cpuInfo.Model := Format('%s Family %d Model %d', [
        cpuInfo.Vendor,
        (eax shr 8) and $F,   // Family
        (eax shr 4) and $F    // Model
      ]);
    end;

    // If model is empty or just spaces, use vendor as fallback
    if Trim(cpuInfo.Model) = '' then
      cpuInfo.Model := cpuInfo.Vendor + ' Processor';

  except
    // If detection fails, use safe defaults
    cpuInfo.Vendor := 'Unknown x86';
    cpuInfo.Model := 'Unknown x86 Processor';
  end;
end;

// === Cache Information Detection ===

function GetX86CacheInfo: TX86CacheInfo;
var
  eax, ebx, ecx, edx: DWord;
begin
  FillChar(Result, SizeOf(Result), 0);

  if not HasCPUID then
    Exit;

  try
    // Get cache information from CPUID leaf 2 (Intel) or leaf 80000005h/80000006h (AMD)
    CPUID(0, eax, ebx, ecx, edx);

    // Check if we have enough leaves
    if eax >= 2 then
    begin
      // Intel cache descriptors (leaf 2)
      CPUID(2, eax, ebx, ecx, edx);
      // Parse cache descriptors (simplified implementation)
      Result.L1DataCache := 32;  // Default values
      Result.L1InstructionCache := 32;
      Result.L2Cache := 256;
      Result.L3Cache := 0;
    end;

    // Check AMD extended cache information
    CPUID($80000000, eax, ebx, ecx, edx);
    if eax >= $80000006 then
    begin
      // AMD L2/L3 cache information
      CPUID($80000006, eax, ebx, ecx, edx);
      Result.L2Cache := (ecx shr 16) and $FFFF;  // L2 cache size in KB
      Result.L3Cache := ((edx shr 18) and $3FFF) * 512;  // L3 cache size in KB
    end;

  except
    // If cache detection fails, use defaults
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

{$ELSE}

// === Stub implementations for non-x86 platforms ===

implementation

function HasCPUID: Boolean;
begin
  Result := False;
end;

procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  EAX_Out := 0;
  EBX_Out := 0;
  ECX_Out := 0;
  EDX_Out := 0;
end;

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  EAX_Out := 0;
  EBX_Out := 0;
  ECX_Out := 0;
  EDX_Out := 0;
end;

function DetectX86Features: TX86Features;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
begin
  cpuInfo.Vendor := 'Non-x86';
  cpuInfo.Model := 'Non-x86 Processor';
end;

function IsAVXSupportedByOS: Boolean;
begin
  Result := False;
end;

function GetX86CacheInfo: TX86CacheInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{$ENDIF} // SIMD_X86_AVAILABLE

end.

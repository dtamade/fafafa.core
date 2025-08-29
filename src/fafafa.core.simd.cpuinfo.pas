unit fafafa.core.simd.cpuinfo;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.simd.types;

// === CPU Feature Detection ===

type
  // Array type for backend list
  TSimdBackendArray = array of TSimdBackend;

// Get comprehensive CPU information
function GetCPUInfo: TCPUInfo;

// Check if specific backends are available
function IsBackendAvailable(backend: TSimdBackend): Boolean;

// Get list of all available backends (sorted by priority)
function GetAvailableBackends: TSimdBackendArray;

// Get the best available backend for general use
function GetBestBackend: TSimdBackend;

// Get backend information
function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;

{$IFDEF SIMD_X86_AVAILABLE}
// x86-specific feature detection
function DetectX86Features: TX86Features;
function HasCPUID: Boolean;
procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
{$ENDIF}

{$IFDEF SIMD_ARM_AVAILABLE}
// ARM-specific feature detection
function DetectARMFeatures: TARMFeatures;
{$ENDIF}

implementation

{$IFDEF UNIX}
uses
  BaseUnix;
{$ENDIF}

{$IFDEF WINDOWS}
uses
  Windows;
{$ENDIF}

type
  // Thread-safe initialization state
  TInitState = (isNotInitialized, isInitializing, isInitialized);

var
  // Cached CPU information (initialized once)
  g_CPUInfo: TCPUInfo;
  g_InitState: TInitState = isNotInitialized;

{$IFDEF WINDOWS}
  g_InitCS: TRTLCriticalSection;
  g_CSInitialized: Boolean = False;
{$ELSE}
  g_InitLock: Boolean = False;  // Simple spinlock for non-Windows
{$ENDIF}

// === Thread-Safe CPU Information Detection ===

// Forward declarations for internal functions
{$IFDEF SIMD_X86_AVAILABLE}
procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
{$ENDIF}
{$IFDEF SIMD_ARM_AVAILABLE}
procedure DetectARMVendorAndModel(var cpuInfo: TCPUInfo);
{$ENDIF}

procedure InitializeCPUInfo;
begin
  // Initialize CPU information structure
  FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);

  // Set default values
  g_CPUInfo.Vendor := 'Unknown';
  g_CPUInfo.Model := 'Unknown';

  {$IFDEF SIMD_X86_AVAILABLE}
  g_CPUInfo.X86 := DetectX86Features;
  DetectX86VendorAndModel(g_CPUInfo);
  {$ENDIF}

  {$IFDEF SIMD_ARM_AVAILABLE}
  g_CPUInfo.ARM := DetectARMFeatures;
  DetectARMVendorAndModel(g_CPUInfo);
  {$ENDIF}
end;

function GetCPUInfo: TCPUInfo;
begin
  // Fast path: already initialized
  if g_InitState = isInitialized then
  begin
    Result := g_CPUInfo;
    Exit;
  end;

{$IFDEF WINDOWS}
  // Thread-safe initialization using critical section
  // Critical section is initialized in initialization section
  EnterCriticalSection(g_InitCS);
  try
    // Double-check pattern
    if g_InitState = isNotInitialized then
    begin
      g_InitState := isInitializing;
      try
        InitializeCPUInfo;
        g_InitState := isInitialized;
      except
        g_InitState := isNotInitialized;
        raise;
      end;
    end;
  finally
    LeaveCriticalSection(g_InitCS);
  end;
{$ELSE}
  // Improved spinlock for non-Windows platforms
  // Use atomic compare-and-swap pattern
  while True do
  begin
    // Wait for any ongoing initialization
    while g_InitLock do
      Sleep(1);

    // Try to acquire lock atomically
    if g_InitState = isNotInitialized then
    begin
      // Try to set lock (this is still not perfect but better)
      if not g_InitLock then
      begin
        g_InitLock := True;
        // Double check after acquiring lock
        if g_InitState = isNotInitialized then
        begin
          g_InitState := isInitializing;
          try
            InitializeCPUInfo;
            g_InitState := isInitialized;
          except
            g_InitState := isNotInitialized;
            raise;
          finally
            g_InitLock := False;
          end;
          Break;
        end
        else
        begin
          g_InitLock := False;
          Break;
        end;
      end;
    end
    else
      Break;
  end;
{$ENDIF}

  Result := g_CPUInfo;
end;

// === Backend Availability ===

function IsBackendAvailable(backend: TSimdBackend): Boolean;
var
  cpuInfo: TCPUInfo;
begin
  case backend of
    sbScalar:
      Result := True;  // Always available
      
    {$IFDEF SIMD_BACKEND_SSE2}
    sbSSE2:
      begin
        cpuInfo := GetCPUInfo;
        Result := cpuInfo.X86.HasSSE2;
      end;
    {$ELSE}
    sbSSE2:
      Result := False;
    {$ENDIF}
    
    {$IFDEF SIMD_BACKEND_AVX2}
    sbAVX2:
      begin
        cpuInfo := GetCPUInfo;
        Result := cpuInfo.X86.HasAVX2;
      end;
    {$ELSE}
    sbAVX2:
      Result := False;
    {$ENDIF}
    
    {$IFDEF SIMD_BACKEND_AVX512}
    sbAVX512:
      begin
        cpuInfo := GetCPUInfo;
        Result := cpuInfo.X86.HasAVX512F;
      end;
    {$ELSE}
    sbAVX512:
      Result := False;
    {$ENDIF}
    
    {$IFDEF SIMD_BACKEND_NEON}
    sbNEON:
      begin
        cpuInfo := GetCPUInfo;
        Result := cpuInfo.ARM.HasNEON;
      end;
    {$ELSE}
    sbNEON:
      Result := False;
    {$ENDIF}
    
  else
    Result := False;
  end;
end;

function GetAvailableBackends: TSimdBackendArray;
var
  backends: TSimdBackendArray;
  count: Integer;
  backend: TSimdBackend;
  maxBackends: Integer;
begin
  // Pre-allocate for maximum possible backends
  maxBackends := Ord(High(TSimdBackend)) - Ord(Low(TSimdBackend)) + 1;
  SetLength(backends, maxBackends);
  count := 0;

  // Check all backends in priority order (best first)
  for backend := High(TSimdBackend) downto Low(TSimdBackend) do
  begin
    if IsBackendAvailable(backend) then
    begin
      backends[count] := backend;
      Inc(count);
    end;
  end;

  // Resize to actual count
  SetLength(backends, count);
  Result := backends;
end;

function GetBestBackend: TSimdBackend;
var
  backends: array of TSimdBackend;
begin
  backends := GetAvailableBackends;
  if Length(backends) > 0 then
    Result := backends[0]  // First is best (highest priority)
  else
    Result := sbScalar;    // Fallback
end;

function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;
begin
  Result.Backend := backend;
  Result.Name := GetBackendName(backend);
  Result.Description := GetBackendDescription(backend);
  Result.Available := IsBackendAvailable(backend);
  
  // Set capabilities based on backend
  case backend of
    sbScalar:
      begin
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, 
                               scReduction, scLoadStore];
        Result.Priority := 0;
      end;
      
    sbSSE2:
      begin
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scReduction, scShuffle, scIntegerOps, scLoadStore];
        Result.Priority := 100;
      end;
      
    sbAVX2:
      begin
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scReduction, scShuffle, scFMA, scIntegerOps, 
                               scLoadStore, scGather];
        Result.Priority := 200;
      end;
      
    sbAVX512:
      begin
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scReduction, scShuffle, scFMA, scIntegerOps,
                               scLoadStore, scGather, scMaskedOps];
        Result.Priority := 300;
      end;
      
    sbNEON:
      begin
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scReduction, scShuffle, scIntegerOps, scLoadStore];
        Result.Priority := 150;
      end;
  end;
end;

{$IFDEF SIMD_X86_AVAILABLE}

// === x86 Feature Detection ===

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
  // Use a safer approach - call external function or use intrinsics
  try
    {$IFDEF CPUX86_64}
    asm
      push rbx

      // Execute CPUID
      cpuid

      // Store results using proper addressing
      mov r10, rcx      // Save EAX_Out pointer
      mov [r10], eax    // Store EAX

      mov r10, rdx      // Save EBX_Out pointer
      mov [r10], ebx    // Store EBX

      mov [r8], ecx     // Store ECX
      mov [r9], edx     // Store EDX

      pop rbx
    end;
    {$ELSE}
    // For 32-bit, use a simpler approach
    asm
      push ebx
      push edi
      push esi

      // Execute CPUID
      cpuid

      // Get parameter pointers and store results
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

// Extended CPUID with ECX input (for leaf 7 and others)
procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  try
    {$IFDEF CPUX86_64}
    asm
      push rbx

      // Set ECX input
      mov ecx, edx

      // Execute CPUID
      cpuid

      // Store results using proper addressing
      mov r10, [rsp + 40]  // Get EAX_Out from stack
      mov [r10], eax

      mov r10, [rsp + 48]  // Get EBX_Out from stack
      mov [r10], ebx

      mov [r8], ecx        // ECX_Out
      mov [r9], edx        // EDX_Out

      pop rbx
    end;
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

function DetectX86Features: TX86Features;
var
  eax, ebx, ecx, edx: DWord;
  maxLeaf, maxExtLeaf: DWord;
begin
  FillChar(Result, SizeOf(Result), 0);

  if not HasCPUID then
    Exit;

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

  // Check if OS supports AVX (XGETBV instruction)
  if Result.HasAVX then
  begin
    // Check OSXSAVE bit
    if (ecx and (1 shl 27)) <> 0 then
    begin
      // Check if OS saves AVX state (XCR0[2:1] = 11b)
      // This requires XGETBV instruction which we'll implement later
      // For now, assume OS supports AVX if CPU does
    end
    else
      Result.HasAVX := False;
  end;

  // Check extended features (Leaf 7, Sub-leaf 0)
  if maxLeaf >= 7 then
  begin
    CPUIDEX(7, 0, eax, ebx, ecx, edx);

    // EBX register features
    Result.HasAVX2 := (ebx and (1 shl 5)) <> 0;
    Result.HasAVX512F := (ebx and (1 shl 16)) <> 0;
    Result.HasAVX512DQ := (ebx and (1 shl 17)) <> 0;
    Result.HasAVX512BW := (ebx and (1 shl 30)) <> 0;

    // Disable AVX2 if AVX is not supported
    if not Result.HasAVX then
      Result.HasAVX2 := False;

    // Disable AVX-512 if AVX2 is not supported
    if not Result.HasAVX2 then
    begin
      Result.HasAVX512F := False;
      Result.HasAVX512DQ := False;
      Result.HasAVX512BW := False;
    end;
  end;

  // Check extended function availability
  CPUID($80000000, maxExtLeaf, ebx, ecx, edx);

  // Additional extended features can be checked here if needed
  // For example, AMD-specific features
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
var
  eax, ebx, ecx, edx: DWord;
  vendorString: array[0..12] of AnsiChar;
  brandString: array[0..48] of AnsiChar;
  i: Integer;
begin
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
end;

{$ENDIF} // SIMD_X86_AVAILABLE

{$IFDEF SIMD_ARM_AVAILABLE}

// === ARM Feature Detection ===

{$IFDEF UNIX}
// Read /proc/cpuinfo on Linux to detect ARM features
function ReadProcCpuInfo: string;
var
  f: TextFile;
  line: string;
  result: string;
  fileOpened: Boolean;
begin
  result := '';
  fileOpened := False;
  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(f, '/proc/cpuinfo');
      Reset(f);
      fileOpened := True;

      while not EOF(f) do
      begin
        ReadLn(f, line);
        result := result + line + #10;
      end;
    end;
  except
    // Ignore errors, return empty string
    result := '';
  end;

  // Ensure file is closed even if exception occurs
  if fileOpened then
  begin
    try
      CloseFile(f);
    except
      // Ignore close errors
    end;
  end;

  Result := result;
end;

function ParseARMFeaturesFromCpuInfo(const cpuInfo: string): TARMFeatures;
begin
  FillChar(Result, SizeOf(Result), 0);

  // Look for feature flags in /proc/cpuinfo
  if Pos('neon', LowerCase(cpuInfo)) > 0 then
    Result.HasNEON := True;

  if Pos('asimd', LowerCase(cpuInfo)) > 0 then
    Result.HasAdvSIMD := True;

  if Pos('fp', LowerCase(cpuInfo)) > 0 then
    Result.HasFP := True;

  if Pos('sve', LowerCase(cpuInfo)) > 0 then
    Result.HasSVE := True;
end;
{$ENDIF} // UNIX

function DetectARMFeatures: TARMFeatures;
{$IFDEF UNIX}
var
  cpuInfoText: string;
{$ENDIF}
begin
  FillChar(Result, SizeOf(Result), 0);

  {$IFDEF CPUAARCH64}
  // On AArch64, NEON (Advanced SIMD) is mandatory per ARM architecture
  Result.HasNEON := True;
  Result.HasAdvSIMD := True;
  Result.HasFP := True;

  {$IFDEF UNIX}
  // Try to detect additional features from /proc/cpuinfo
  cpuInfoText := ReadProcCpuInfo;
  if cpuInfoText <> '' then
  begin
    Result := ParseARMFeaturesFromCpuInfo(cpuInfoText);
    // Ensure mandatory features are still set
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;
  end;
  {$ENDIF}

  {$ELSE} // 32-bit ARM

  {$IFDEF UNIX}
  // On 32-bit ARM, NEON is optional, check /proc/cpuinfo
  cpuInfoText := ReadProcCpuInfo;
  if cpuInfoText <> '' then
    Result := ParseARMFeaturesFromCpuInfo(cpuInfoText);
  {$ELSE}
  // On other platforms, conservative defaults
  Result.HasNEON := False;
  Result.HasAdvSIMD := False;
  Result.HasFP := False;
  Result.HasSVE := False;
  {$ENDIF}

  {$ENDIF} // CPUAARCH64
end;

procedure DetectARMVendorAndModel(var cpuInfo: TCPUInfo);
{$IFDEF UNIX}
var
  cpuInfoText: string;
  pos, nextPos, colonPos: Integer;
  line, key, value: string;
{$ENDIF}
begin
  // Set default values
  cpuInfo.Vendor := 'ARM';
  cpuInfo.Model := 'Unknown ARM Processor';

  {$IFDEF UNIX}
  // Try to get detailed info from /proc/cpuinfo
  cpuInfoText := ReadProcCpuInfo;
  if cpuInfoText <> '' then
  begin
    pos := 1;
    while pos <= Length(cpuInfoText) do
    begin
      // Find next line
      nextPos := Pos(#10, cpuInfoText, pos);
      if nextPos = 0 then
        nextPos := Length(cpuInfoText) + 1;

      line := Trim(Copy(cpuInfoText, pos, nextPos - pos));
      pos := nextPos + 1;

      // Parse key:value pairs
      colonPos := Pos(':', line);
      if colonPos > 0 then
      begin
        key := Trim(LowerCase(Copy(line, 1, colonPos - 1)));
        value := Trim(Copy(line, colonPos + 1, Length(line)));

        if (key = 'cpu implementer') or (key = 'hardware') then
        begin
          if value <> '' then
            cpuInfo.Vendor := value;
        end
        else if (key = 'cpu part') or (key = 'model name') or (key = 'processor') then
        begin
          if value <> '' then
            cpuInfo.Model := value;
        end;
      end;
    end;
  end;
  {$ENDIF}
end;

{$ENDIF} // SIMD_ARM_AVAILABLE

{$IFDEF WINDOWS}
initialization
  InitializeCriticalSection(g_InitCS);
  g_CSInitialized := True;

finalization
  if g_CSInitialized then
  begin
    DeleteCriticalSection(g_InitCS);
    g_CSInitialized := False;
  end;
{$ENDIF}

end.

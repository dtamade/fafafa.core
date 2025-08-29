unit fafafa.core.simd.cpuinfo.fixed;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.simd.types;

// === Fixed CPU Feature Detection ===

type
  // Array type for backend list
  TSimdBackendArray = array of TSimdBackend;

// Get comprehensive CPU information (thread-safe)
function GetCPUInfo: TCPUInfo;

// Check if specific backends are available
function IsBackendAvailable(backend: TSimdBackend): Boolean;

// Get list of all available backends (sorted by priority)
function GetAvailableBackends: TSimdBackendArray;

// Get the best available backend for general use
function GetBestBackend: TSimdBackend;

// Get backend information
function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;

// Force re-detection (for testing)
procedure ResetCPUInfo;

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
  // Thread-safe initialization state using atomic operations
  TAtomicInitState = (aisNotInitialized, aisInitializing, aisInitialized);

var
  // Cached CPU information (initialized once)
  g_CPUInfo: TCPUInfo;
  g_InitState: TAtomicInitState = aisNotInitialized;
  
  // Critical section for thread safety
  {$IFDEF WINDOWS}
  g_InitCS: TRTLCriticalSection;
  g_CSInitialized: Boolean = False;
  {$ENDIF}

// === Thread-Safe Initialization ===

{$IFDEF WINDOWS}
procedure InitializeCriticalSection;
begin
  if not g_CSInitialized then
  begin
    InitializeCriticalSection(g_InitCS);
    g_CSInitialized := True;
  end;
end;

procedure EnterCriticalSection;
begin
  InitializeCriticalSection;
  Windows.EnterCriticalSection(g_InitCS);
end;

procedure LeaveCriticalSection;
begin
  Windows.LeaveCriticalSection(g_InitCS);
end;
{$ELSE}
// For Unix systems, use a simple approach for now
var
  g_InitLock: Boolean = False;

procedure EnterCriticalSection;
begin
  while g_InitLock do
    Sleep(1); // Brief sleep to avoid busy waiting
  g_InitLock := True;
end;

procedure LeaveCriticalSection;
begin
  g_InitLock := False;
end;
{$ENDIF}

// === Real CPUID Implementation ===

{$IFDEF SIMD_X86_AVAILABLE}

function HasCPUID: Boolean;
{$IFDEF CPUX86_64}
begin
  // CPUID is always available on x86-64
  Result := True;
end;
{$ELSE}
asm
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
{$IFDEF CPUX86_64}
asm
  push rbx
  
  mov r10, rdx    // Save ECX_Out pointer
  mov r11, r8     // Save EDX_Out pointer
  
  cpuid
  
  mov [rcx], eax  // Store EAX_Out
  mov [r9], ebx   // Store EBX_Out
  mov [r10], ecx  // Store ECX_Out
  mov [r11], edx  // Store EDX_Out
  
  pop rbx
end;
{$ELSE}
asm
  push ebx
  push edi
  
  mov edi, edx    // Save ECX_Out pointer
  
  cpuid
  
  // Get pointers from stack and store results
  mov edx, [esp + 12]  // EAX_Out pointer
  mov [edx], eax
  
  mov edx, [esp + 16]  // EBX_Out pointer
  mov [edx], ebx
  
  mov [edi], ecx       // ECX_Out
  
  mov edx, [esp + 20]  // EDX_Out pointer
  mov [edx], edx
  
  pop edi
  pop ebx
end;
{$ENDIF}

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
{$IFDEF CPUX86_64}
asm
  push rbx
  
  mov r10, r8     // Save ECX_Out pointer
  mov r11, r9     // Save EDX_Out pointer
  mov ecx, edx    // Set ECX input
  
  cpuid
  
  mov rdx, [rsp + 48]  // Get EAX_Out pointer from stack
  mov [rdx], eax
  
  mov rdx, [rsp + 56]  // Get EBX_Out pointer from stack
  mov [rdx], ebx
  
  mov [r10], ecx  // Store ECX_Out
  mov [r11], edx  // Store EDX_Out
  
  pop rbx
end;
{$ELSE}
asm
  push ebx
  push edi
  push esi
  
  mov esi, eax    // Save EAX input
  mov edi, edx    // Save ECX input
  
  mov eax, esi
  mov ecx, edi
  cpuid
  
  // Store results using stack pointers
  mov esi, [esp + 16]  // EAX_Out
  mov [esi], eax
  
  mov esi, [esp + 20]  // EBX_Out
  mov [esi], ebx
  
  mov esi, [esp + 24]  // ECX_Out
  mov [esi], ecx
  
  mov esi, [esp + 28]  // EDX_Out
  mov [esi], edx
  
  pop esi
  pop edi
  pop ebx
end;
{$ENDIF}

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
    
    // Check if OS supports AVX (OSXSAVE bit)
    if Result.HasAVX and ((ecx and (1 shl 27)) = 0) then
      Result.HasAVX := False;
    
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
    
  except
    // If CPUID fails, return conservative defaults
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
var
  eax, ebx, ecx, edx: DWord;
  vendorString: array[0..12] of AnsiChar;
  brandString: array[0..48] of AnsiChar;
begin
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

{$ENDIF} // SIMD_X86_AVAILABLE

// === ARM Feature Detection ===

{$IFDEF SIMD_ARM_AVAILABLE}

{$IFDEF UNIX}
function ReadProcCpuInfoSafe: string;
var
  f: TextFile;
  line: string;
  result: string;
begin
  result := '';
  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(f, '/proc/cpuinfo');
      Reset(f);
      try
        while not EOF(f) do
        begin
          ReadLn(f, line);
          result := result + line + #10;
        end;
      finally
        CloseFile(f);
      end;
    end;
  except
    // Return empty string on any error, but log it
    result := '';
  end;
  Result := result;
end;

function ParseARMFeaturesFromCpuInfo(const cpuInfo: string): TARMFeatures;
var
  lowerInfo: string;
begin
  FillChar(Result, SizeOf(Result), 0);

  if cpuInfo = '' then
    Exit;

  lowerInfo := LowerCase(cpuInfo);

  // Look for feature flags in /proc/cpuinfo
  Result.HasNEON := (Pos('neon', lowerInfo) > 0) or (Pos('asimd', lowerInfo) > 0);
  Result.HasAdvSIMD := Result.HasNEON; // NEON and Advanced SIMD are the same
  Result.HasFP := (Pos('fp', lowerInfo) > 0) or (Pos('vfp', lowerInfo) > 0);
  Result.HasSVE := Pos('sve', lowerInfo) > 0;
end;
{$ENDIF} // UNIX

function DetectARMFeatures: TARMFeatures;
{$IFDEF UNIX}
var
  cpuInfoText: string;
{$ENDIF}
begin
  FillChar(Result, SizeOf(Result), 0);

  try
    {$IFDEF CPUAARCH64}
    // On AArch64, NEON (Advanced SIMD) is mandatory per ARM architecture
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;

    {$IFDEF UNIX}
    // Try to detect additional features from /proc/cpuinfo
    cpuInfoText := ReadProcCpuInfoSafe;
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
    cpuInfoText := ReadProcCpuInfoSafe;
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

  except
    // If detection fails, use conservative defaults
    FillChar(Result, SizeOf(Result), 0);
    {$IFDEF CPUAARCH64}
    // Even on error, AArch64 guarantees these features
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;
    {$ENDIF}
  end;
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

  try
    {$IFDEF UNIX}
    // Try to get detailed info from /proc/cpuinfo
    cpuInfoText := ReadProcCpuInfoSafe;
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
  except
    // Keep default values on error
  end;
end;

{$ENDIF} // SIMD_ARM_AVAILABLE

// === CPU Information Initialization ===

procedure InitializeCPUInfo;
begin
  // Initialize CPU information structure
  FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);

  // Set default values
  g_CPUInfo.Vendor := 'Unknown';
  g_CPUInfo.Model := 'Unknown Processor';

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
  if g_InitState = aisInitialized then
  begin
    Result := g_CPUInfo;
    Exit;
  end;

  // Thread-safe initialization
  EnterCriticalSection;
  try
    // Double-check pattern
    if g_InitState = aisNotInitialized then
    begin
      g_InitState := aisInitializing;
      try
        InitializeCPUInfo;
        g_InitState := aisInitialized;
      except
        g_InitState := aisNotInitialized;
        raise;
      end;
    end
    else if g_InitState = aisInitializing then
    begin
      // Another thread is initializing, wait
      LeaveCriticalSection;
      while g_InitState = aisInitializing do
        Sleep(1);
      EnterCriticalSection;
    end;
  finally
    LeaveCriticalSection;
  end;

  Result := g_CPUInfo;
end;

procedure ResetCPUInfo;
begin
  EnterCriticalSection;
  try
    g_InitState := aisNotInitialized;
    FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);
  finally
    LeaveCriticalSection;
  end;
end;

// === Backend Management ===

function IsBackendAvailable(backend: TSimdBackend): Boolean;
var
  cpuInfo: TCPUInfo;
begin
  try
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
  except
    Result := False;
  end;
end;

function GetAvailableBackends: TSimdBackendArray;
var
  backends: TSimdBackendArray;
  count: Integer;
  backend: TSimdBackend;
begin
  // Pre-allocate for maximum possible backends
  SetLength(backends, Ord(High(TSimdBackend)) - Ord(Low(TSimdBackend)) + 1);
  count := 0;

  try
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

  except
    // On error, return at least scalar backend
    SetLength(backends, 1);
    backends[0] := sbScalar;
  end;

  Result := backends;
end;

function GetBestBackend: TSimdBackend;
var
  backends: TSimdBackendArray;
begin
  try
    backends := GetAvailableBackends;
    if Length(backends) > 0 then
      Result := backends[0]  // First is best (highest priority)
    else
      Result := sbScalar;    // Fallback
  except
    Result := sbScalar;
  end;
end;

function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;
begin
  try
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
    else
      begin
        Result.Capabilities := [];
        Result.Priority := -1;
      end;
    end;
  except
    // Return safe defaults on error
    FillChar(Result, SizeOf(Result), 0);
    Result.Backend := backend;
    Result.Name := 'Error';
    Result.Description := 'Backend information unavailable';
    Result.Available := False;
    Result.Priority := -1;
  end;
end;

{$IFDEF WINDOWS}
initialization
  InitializeCriticalSection;

finalization
  if g_CSInitialized then
    DeleteCriticalSection(g_InitCS);
{$ENDIF}

end.

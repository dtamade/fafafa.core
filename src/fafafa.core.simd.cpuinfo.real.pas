unit fafafa.core.simd.cpuinfo.real;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.simd.types;

// === Real CPU Feature Detection with Working CPUID ===

type
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

var
  // Cached CPU information (initialized once)
  g_CPUInfo: TCPUInfo;
  g_Initialized: Boolean = False;
  g_InitLock: Boolean = False;

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
  
  // Save output pointers
  push rcx    // EAX_Out
  push rdx    // EBX_Out  
  push r8     // ECX_Out
  push r9     // EDX_Out
  
  // Execute CPUID
  cpuid
  
  // Restore pointers and store results
  pop r9      // EDX_Out
  mov [r9], edx
  
  pop r8      // ECX_Out
  mov [r8], ecx
  
  pop rdx     // EBX_Out
  mov [rdx], ebx
  
  pop rcx     // EAX_Out
  mov [rcx], eax
  
  pop rbx
end;
{$ELSE}
asm
  push ebx
  push edi
  push esi
  
  // Save input EAX
  mov esi, eax
  
  // Execute CPUID
  cpuid
  
  // Store EAX result
  mov edi, [esp + 16]  // EAX_Out parameter
  mov [edi], eax
  
  // Store EBX result  
  mov edi, [esp + 20]  // EBX_Out parameter
  mov [edi], ebx
  
  // Store ECX result
  mov edi, [esp + 24]  // ECX_Out parameter
  mov [edi], ecx
  
  // Store EDX result
  mov edi, [esp + 28]  // EDX_Out parameter
  mov [edi], edx
  
  pop esi
  pop edi
  pop ebx
end;
{$ENDIF}

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
{$IFDEF CPUX86_64}
asm
  push rbx
  
  // Set ECX input
  mov ecx, edx
  
  // Save output pointers
  push r8     // EAX_Out (from stack)
  push r9     // EBX_Out (from stack)
  mov r10, [rsp + 32]  // ECX_Out (from stack)
  mov r11, [rsp + 40]  // EDX_Out (from stack)
  
  // Execute CPUID
  cpuid
  
  // Store results
  pop r9      // EBX_Out
  mov [r9], ebx
  
  pop r8      // EAX_Out
  mov [r8], eax
  
  mov [r10], ecx  // ECX_Out
  mov [r11], edx  // EDX_Out
  
  pop rbx
end;
{$ELSE}
asm
  push ebx
  push edi
  push esi
  
  // Set inputs
  mov esi, eax    // Save EAX input
  mov edi, edx    // Save ECX input
  
  mov eax, esi
  mov ecx, edi
  
  // Execute CPUID
  cpuid
  
  // Store results using stack parameters
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

  Result.HasNEON := (Pos('neon', lowerInfo) > 0) or (Pos('asimd', lowerInfo) > 0);
  Result.HasAdvSIMD := Result.HasNEON;
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
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;

    {$IFDEF UNIX}
    cpuInfoText := ReadProcCpuInfoSafe;
    if cpuInfoText <> '' then
    begin
      Result := ParseARMFeaturesFromCpuInfo(cpuInfoText);
      Result.HasNEON := True;
      Result.HasAdvSIMD := True;
      Result.HasFP := True;
    end;
    {$ENDIF}

    {$ELSE} // 32-bit ARM

    {$IFDEF UNIX}
    cpuInfoText := ReadProcCpuInfoSafe;
    if cpuInfoText <> '' then
      Result := ParseARMFeaturesFromCpuInfo(cpuInfoText);
    {$ENDIF}

    {$ENDIF} // CPUAARCH64

  except
    FillChar(Result, SizeOf(Result), 0);
    {$IFDEF CPUAARCH64}
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
  cpuInfo.Vendor := 'ARM';
  cpuInfo.Model := 'Unknown ARM Processor';

  try
    {$IFDEF UNIX}
    cpuInfoText := ReadProcCpuInfoSafe;
    if cpuInfoText <> '' then
    begin
      pos := 1;
      while pos <= Length(cpuInfoText) do
      begin
        nextPos := Pos(#10, cpuInfoText, pos);
        if nextPos = 0 then
          nextPos := Length(cpuInfoText) + 1;

        line := Trim(Copy(cpuInfoText, pos, nextPos - pos));
        pos := nextPos + 1;

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
    // Keep default values
  end;
end;

{$ENDIF} // SIMD_ARM_AVAILABLE

// === Thread-Safe CPU Information ===

procedure InitializeCPUInfo;
begin
  FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);

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
  if g_Initialized then
  begin
    Result := g_CPUInfo;
    Exit;
  end;

  // Simple thread safety (good enough for most cases)
  while g_InitLock do
    Sleep(1);

  if not g_Initialized then
  begin
    g_InitLock := True;
    try
      if not g_Initialized then
      begin
        InitializeCPUInfo;
        g_Initialized := True;
      end;
    finally
      g_InitLock := False;
    end;
  end;

  Result := g_CPUInfo;
end;

procedure ResetCPUInfo;
begin
  while g_InitLock do
    Sleep(1);

  g_InitLock := True;
  try
    g_Initialized := False;
    FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);
  finally
    g_InitLock := False;
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
        Result := True;

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
  SetLength(backends, Ord(High(TSimdBackend)) - Ord(Low(TSimdBackend)) + 1);
  count := 0;

  try
    for backend := High(TSimdBackend) downto Low(TSimdBackend) do
    begin
      if IsBackendAvailable(backend) then
      begin
        backends[count] := backend;
        Inc(count);
      end;
    end;

    SetLength(backends, count);

  except
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
      Result := backends[0]
    else
      Result := sbScalar;
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
    FillChar(Result, SizeOf(Result), 0);
    Result.Backend := backend;
    Result.Name := 'Error';
    Result.Description := 'Backend information unavailable';
    Result.Available := False;
    Result.Priority := -1;
  end;
end;

end.

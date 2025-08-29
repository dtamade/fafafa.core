unit fafafa.core.simd.cpuinfo.refactored;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.simd.types;

// === Public API - Maintains backward compatibility ===

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

// Force re-detection (for testing purposes)
procedure ResetCPUInfo;

implementation

uses
  {$IFDEF SIMD_X86_AVAILABLE}
  fafafa.core.simd.cpuinfo.x86,
  {$ENDIF}
  {$IFDEF SIMD_ARM_AVAILABLE}
  fafafa.core.simd.cpuinfo.arm,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows
  {$ENDIF}
  {$IFDEF UNIX}
  BaseUnix
  {$ENDIF};

// === Thread-Safe Initialization ===

type
  TInitState = (isNotInitialized, isInitializing, isInitialized);

var
  // Cached CPU information (initialized once)
  g_CPUInfo: TCPUInfo;
  g_InitState: TInitState = isNotInitialized;

{$IFDEF WINDOWS}
  g_InitCS: TRTLCriticalSection;
  g_CSInitialized: Boolean = False;
{$ELSE}
  g_InitLock: Boolean = False;
{$ENDIF}

// === CPU Information Detection ===

procedure InitializeCPUInfo;
begin
  // Initialize CPU information structure
  FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);

  // Set default values
  g_CPUInfo.Vendor := 'Unknown';
  g_CPUInfo.Model := 'Unknown Processor';

  try
    {$IFDEF SIMD_X86_AVAILABLE}
    // Delegate x86 detection to specialized module
    g_CPUInfo.X86 := fafafa.core.simd.cpuinfo.x86.DetectX86Features;
    fafafa.core.simd.cpuinfo.x86.DetectX86VendorAndModel(g_CPUInfo);
    {$ENDIF}

    {$IFDEF SIMD_ARM_AVAILABLE}
    // Delegate ARM detection to specialized module
    g_CPUInfo.ARM := fafafa.core.simd.cpuinfo.arm.DetectARMFeatures;
    fafafa.core.simd.cpuinfo.arm.DetectARMVendorAndModel(g_CPUInfo);
    {$ENDIF}

  except
    // If detection fails, keep default values
    g_CPUInfo.Vendor := 'Detection Failed';
    g_CPUInfo.Model := 'Unknown Processor';
  end;
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
  while True do
  begin
    // Wait for any ongoing initialization
    while g_InitLock do
      Sleep(1);
      
    // Try to acquire lock
    if g_InitState = isNotInitialized then
    begin
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

procedure ResetCPUInfo;
begin
{$IFDEF WINDOWS}
  EnterCriticalSection(g_InitCS);
  try
    g_InitState := isNotInitialized;
    FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);
  finally
    LeaveCriticalSection(g_InitCS);
  end;
{$ELSE}
  while g_InitLock do
    Sleep(1);
    
  g_InitLock := True;
  try
    g_InitState := isNotInitialized;
    FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);
  finally
    g_InitLock := False;
  end;
{$ENDIF}
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
  maxBackends: Integer;
begin
  // Pre-allocate for maximum possible backends
  maxBackends := Ord(High(TSimdBackend)) - Ord(Low(TSimdBackend)) + 1;
  SetLength(backends, maxBackends);
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

// === Initialization and Cleanup ===

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

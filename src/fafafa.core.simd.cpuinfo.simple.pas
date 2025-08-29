unit fafafa.core.simd.cpuinfo.simple;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.simd.types;

// === Simplified CPU Feature Detection ===

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

implementation

var
  // Cached CPU information (initialized once)
  g_CPUInfo: TCPUInfo;
  g_CPUInfoInitialized: Boolean = False;

// === Simplified CPU Information Detection ===

procedure InitializeCPUInfo;
begin
  // Initialize CPU information structure
  FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);
  
  // Set default values
  g_CPUInfo.Vendor := 'Generic';
  g_CPUInfo.Model := 'Unknown Processor';
  
  {$IFDEF SIMD_X86_AVAILABLE}
  // Simulate x86 features for testing
  g_CPUInfo.X86.HasSSE := True;
  g_CPUInfo.X86.HasSSE2 := True;
  g_CPUInfo.X86.HasSSE3 := True;
  g_CPUInfo.X86.HasSSSE3 := True;
  g_CPUInfo.X86.HasSSE41 := True;
  g_CPUInfo.X86.HasSSE42 := True;
  g_CPUInfo.X86.HasAVX := True;
  g_CPUInfo.X86.HasAVX2 := True;
  g_CPUInfo.X86.HasFMA := True;
  g_CPUInfo.X86.HasAVX512F := False;  // Conservative default
  g_CPUInfo.X86.HasAVX512DQ := False;
  g_CPUInfo.X86.HasAVX512BW := False;
  
  g_CPUInfo.Vendor := 'Intel/AMD';
  g_CPUInfo.Model := 'x86-64 Processor with AVX2';
  {$ENDIF}
  
  {$IFDEF SIMD_ARM_AVAILABLE}
  // Simulate ARM features for testing
  g_CPUInfo.ARM.HasNEON := True;
  g_CPUInfo.ARM.HasAdvSIMD := True;
  g_CPUInfo.ARM.HasFP := True;
  g_CPUInfo.ARM.HasSVE := False;  // Conservative default
  
  g_CPUInfo.Vendor := 'ARM';
  g_CPUInfo.Model := 'ARM Processor with NEON';
  {$ENDIF}
end;

function GetCPUInfo: TCPUInfo;
begin
  if not g_CPUInfoInitialized then
  begin
    InitializeCPUInfo;
    g_CPUInfoInitialized := True;
  end;
  
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
begin
  SetLength(backends, 0);
  count := 0;
  
  // Check all backends in priority order (best first)
  for backend := High(TSimdBackend) downto Low(TSimdBackend) do
  begin
    if IsBackendAvailable(backend) then
    begin
      SetLength(backends, count + 1);
      backends[count] := backend;
      Inc(count);
    end;
  end;
  
  Result := backends;
end;

function GetBestBackend: TSimdBackend;
var
  backends: TSimdBackendArray;
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

end.

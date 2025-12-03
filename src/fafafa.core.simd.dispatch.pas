unit fafafa.core.simd.dispatch;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

// === Dispatch System ===

// Initialize the dispatch system (called automatically)
procedure InitializeDispatch;

// Get current active backend
function GetActiveBackend: TSimdBackend;

// Force a specific backend (for testing)
procedure SetActiveBackend(backend: TSimdBackend);

// Reset to automatic backend selection
procedure ResetToAutomaticBackend;

// === Function Dispatch Tables ===
type
  // Dispatch table for all SIMD operations
  TSimdDispatchTable = record
    // Backend information
    Backend: TSimdBackend;
    BackendInfo: TSimdBackendInfo;
    
    // Arithmetic operations - F32x4
    AddF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    SubF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    MulF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    DivF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    
    // Arithmetic operations - F32x8
    AddF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    SubF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    MulF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    DivF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    
    // Arithmetic operations - F64x2
    AddF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    SubF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    MulF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    DivF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    
    // Arithmetic operations - I32x4
    AddI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    SubI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    MulI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    
    // Comparison operations
    CmpEqF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpLtF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpLeF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpGtF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpGeF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpNeF32x4: function(const a, b: TVecF32x4): TMask4;
    
    // Math functions
    AbsF32x4: function(const a: TVecF32x4): TVecF32x4;
    SqrtF32x4: function(const a: TVecF32x4): TVecF32x4;
    MinF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    MaxF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    
    // Extended math functions
    FmaF32x4: function(const a, b, c: TVecF32x4): TVecF32x4;   // a*b+c
    RcpF32x4: function(const a: TVecF32x4): TVecF32x4;          // 1/x (approximate)
    RsqrtF32x4: function(const a: TVecF32x4): TVecF32x4;        // 1/sqrt(x) (approximate)
    FloorF32x4: function(const a: TVecF32x4): TVecF32x4;
    CeilF32x4: function(const a: TVecF32x4): TVecF32x4;
    RoundF32x4: function(const a: TVecF32x4): TVecF32x4;
    TruncF32x4: function(const a: TVecF32x4): TVecF32x4;
    ClampF32x4: function(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
    
    // 3D/4D Vector math
    DotF32x4: function(const a, b: TVecF32x4): Single;          // Dot product (4 elements)
    DotF32x3: function(const a, b: TVecF32x4): Single;          // Dot product (3 elements)
    CrossF32x3: function(const a, b: TVecF32x4): TVecF32x4;     // Cross product (uses x,y,z)
    LengthF32x4: function(const a: TVecF32x4): Single;          // Length (4 elements)
    LengthF32x3: function(const a: TVecF32x4): Single;          // Length (3 elements)
    NormalizeF32x4: function(const a: TVecF32x4): TVecF32x4;    // Normalize (4 elements)
    NormalizeF32x3: function(const a: TVecF32x4): TVecF32x4;    // Normalize (3 elements, w=0)
    
    // Reduction operations
    ReduceAddF32x4: function(const a: TVecF32x4): Single;
    ReduceMinF32x4: function(const a: TVecF32x4): Single;
    ReduceMaxF32x4: function(const a: TVecF32x4): Single;
    ReduceMulF32x4: function(const a: TVecF32x4): Single;
    
    // Memory operations
    LoadF32x4: function(p: PSingle): TVecF32x4;
    LoadF32x4Aligned: function(p: PSingle): TVecF32x4;
    StoreF32x4: procedure(p: PSingle; const a: TVecF32x4);
    StoreF32x4Aligned: procedure(p: PSingle; const a: TVecF32x4);
    
    // Utility operations
    SplatF32x4: function(value: Single): TVecF32x4;
    ZeroF32x4: function: TVecF32x4;
    SelectF32x4: function(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
    ExtractF32x4: function(const a: TVecF32x4; index: Integer): Single;
    InsertF32x4: function(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
    
    // === Facade Functions (High-Level API) ===
    // Memory operations
    MemEqual: function(a, b: Pointer; len: SizeUInt): LongBool;
    MemFindByte: function(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
    MemDiffRange: function(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
    MemCopy: procedure(src, dst: Pointer; len: SizeUInt);
    MemSet: procedure(dst: Pointer; len: SizeUInt; value: Byte);
    MemReverse: procedure(p: Pointer; len: SizeUInt);
    
    // Statistics functions
    SumBytes: function(p: Pointer; len: SizeUInt): UInt64;
    MinMaxBytes: procedure(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
    CountByte: function(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
    
    // Text processing functions
    Utf8Validate: function(p: Pointer; len: SizeUInt): Boolean;
    AsciiIEqual: function(a, b: Pointer; len: SizeUInt): Boolean;
    ToLowerAscii: procedure(p: Pointer; len: SizeUInt);
    ToUpperAscii: procedure(p: Pointer; len: SizeUInt);
    
    // Search functions
    BytesIndexOf: function(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
    
    // Bitset functions
    BitsetPopCount: function(p: Pointer; byteLen: SizeUInt): SizeUInt;
  end;

// Pointer to dispatch table
type
  PSimdDispatchTable = ^TSimdDispatchTable;

// Get current dispatch table
function GetDispatchTable: PSimdDispatchTable;

// === Backend Registration ===

// Register a backend implementation
procedure RegisterBackend(backend: TSimdBackend; const dispatchTable: TSimdDispatchTable);

// Check if backend is registered
function IsBackendRegistered(backend: TSimdBackend): Boolean;

// Get backend info
function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;

implementation

uses
  SysUtils;

var
  // Current active dispatch table
  g_CurrentDispatch: PSimdDispatchTable;
  
  // Registered backend dispatch tables
  g_BackendTables: array[TSimdBackend] of TSimdDispatchTable;
  g_BackendRegistered: array[TSimdBackend] of Boolean;
  
  // Initialization state
  g_DispatchInitialized: Boolean = False;
  g_ForcedBackend: TSimdBackend;
  g_BackendForced: Boolean = False;

// === Initialization ===

const
  BACKEND_PRIORITY: array[0..5] of TSimdBackend = (
    sbAVX512, sbAVX2, sbSSE2, sbNEON, sbRISCVV, sbScalar
  );

function IsBackendAvailable(b: TSimdBackend; const backends: array of TSimdBackend): Boolean;
var
  j: Integer;
begin
  Result := False;
  for j := 0 to High(backends) do
    if backends[j] = b then
      Exit(True);
end;

procedure DoInitializeDispatch;
var
  bestBackend: TSimdBackend;
  backends: array of TSimdBackend;
  i: Integer;
begin
  if g_DispatchInitialized then
    Exit;
    
  // Note: Do NOT reset g_BackendRegistered here!
  // Backends register themselves during unit initialization,
  // and we don't want to lose that registration.
    
  // Find best available backend
  if g_BackendForced then
  begin
    bestBackend := g_ForcedBackend;
    if not IsBackendRegistered(bestBackend) then
      bestBackend := sbScalar;
  end
  else
  begin
    backends := GetAvailableBackends;
    bestBackend := sbScalar;

    for i := Low(BACKEND_PRIORITY) to High(BACKEND_PRIORITY) do
    begin
      if IsBackendRegistered(BACKEND_PRIORITY[i]) and 
         IsBackendAvailable(BACKEND_PRIORITY[i], backends) then
      begin
        bestBackend := BACKEND_PRIORITY[i];
        Break;
      end;
    end;
  end;
  
  // Set active dispatch table
  if IsBackendRegistered(bestBackend) then
    g_CurrentDispatch := @g_BackendTables[bestBackend]
  else
    g_CurrentDispatch := nil;
    
  g_DispatchInitialized := True;
end;

procedure InitializeDispatch;
begin
  // Always call DoInitializeDispatch - it has its own guard
  DoInitializeDispatch;
end;

// === Public Interface ===

function GetActiveBackend: TSimdBackend;
begin
  InitializeDispatch;
  if g_CurrentDispatch <> nil then
    Result := g_CurrentDispatch^.Backend
  else
    Result := sbScalar;
end;

procedure SetActiveBackend(backend: TSimdBackend);
begin
  g_ForcedBackend := backend;
  g_BackendForced := True;
  g_DispatchInitialized := False; // Force re-initialization
  InitializeDispatch;
end;

procedure ResetToAutomaticBackend;
begin
  g_BackendForced := False;
  g_DispatchInitialized := False; // Force re-initialization
  InitializeDispatch;
end;

function GetDispatchTable: PSimdDispatchTable;
begin
  InitializeDispatch;
  Result := g_CurrentDispatch;
end;

// === Backend Registration ===

procedure RegisterBackend(backend: TSimdBackend; const dispatchTable: TSimdDispatchTable);
begin
  g_BackendTables[backend] := dispatchTable;
  g_BackendRegistered[backend] := True;
  
  // Always re-select best backend when a new one is registered
  g_DispatchInitialized := False;
  InitializeDispatch;
end;

function IsBackendRegistered(backend: TSimdBackend): Boolean;
begin
  Result := g_BackendRegistered[backend];
end;

function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;
begin
  if g_BackendRegistered[backend] then
    Result := g_BackendTables[backend].BackendInfo
  else
  begin
    // Return empty info for unregistered backend
    FillChar(Result, SizeOf(Result), 0);
    Result.Backend := backend;
    Result.Available := False;
  end;
end;

// === Initialization ===

initialization
  // Initialize dispatch system on unit load
  InitializeDispatch;

end.



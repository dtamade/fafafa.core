unit fafafa.core.simd.dispatch;

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
    AddF32x4: TSimdAddF32x4Func;
    SubF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    MulF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    DivF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    
    // Arithmetic operations - F32x8
    AddF32x8: TSimdAddF32x8Func;
    SubF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    MulF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    DivF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    
    // Arithmetic operations - F64x2
    AddF64x2: TSimdAddF64x2Func;
    SubF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    MulF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    DivF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    
    // Arithmetic operations - I32x4
    AddI32x4: TSimdAddI32x4Func;
    SubI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    MulI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    
    // Comparison operations
    CmpEqF32x4: TSimdCmpEqF32x4Func;
    CmpLtF32x4: TSimdCmpLtF32x4Func;
    CmpLeF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpGtF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpGeF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpNeF32x4: function(const a, b: TVecF32x4): TMask4;
    
    // Math functions
    AbsF32x4: TSimdAbsF32x4Func;
    SqrtF32x4: TSimdSqrtF32x4Func;
    MinF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    MaxF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    
    // Reduction operations
    ReduceAddF32x4: TSimdReduceAddF32x4Func;
    ReduceMinF32x4: TSimdReduceMinF32x4Func;
    ReduceMaxF32x4: function(const a: TVecF32x4): Single;
    ReduceMulF32x4: function(const a: TVecF32x4): Single;
    
    // Memory operations
    LoadF32x4: TSimdLoadF32x4Func;
    LoadF32x4Aligned: function(p: PSingle): TVecF32x4;
    StoreF32x4: TSimdStoreF32x4Proc;
    StoreF32x4Aligned: procedure(p: PSingle; const a: TVecF32x4);
    
    // Utility operations
    SplatF32x4: TSimdSplatF32x4Func;
    ZeroF32x4: function: TVecF32x4;
    SelectF32x4: TSimdSelectF32x4Func;
    ExtractF32x4: function(const a: TVecF32x4; index: Integer): Single;
    InsertF32x4: function(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
  end;

// Get current dispatch table
function GetDispatchTable: PSimdDispatchTable;

// === Backend Registration ===

// Register a backend implementation
procedure RegisterBackend(backend: TSimdBackend; const dispatchTable: TSimdDispatchTable);

// Check if backend is registered
function IsBackendRegistered(backend: TSimdBackend): Boolean;

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
  
  // Thread-safe initialization (simple flag for now)
  g_InitLock: Boolean = False;

// === Initialization ===

procedure DoInitializeDispatch;
var
  bestBackend: TSimdBackend;
  backends: array of TSimdBackend;
  i: Integer;
begin
  if g_DispatchInitialized then
    Exit;
    
  // Initialize backend registration array
  for bestBackend := Low(TSimdBackend) to High(TSimdBackend) do
    g_BackendRegistered[bestBackend] := False;
    
  // Register scalar backend (always available)
  // This will be done by the scalar backend unit
  
  // Find best available backend
  if g_BackendForced then
  begin
    bestBackend := g_ForcedBackend;
    if not IsBackendRegistered(bestBackend) then
    begin
      // Fallback to scalar if forced backend not available
      bestBackend := sbScalar;
    end;
  end
  else
  begin
    backends := GetAvailableBackends;
    bestBackend := sbScalar; // Default fallback
    
    // Find best registered backend
    for i := 0 to Length(backends) - 1 do
    begin
      if IsBackendRegistered(backends[i]) then
      begin
        bestBackend := backends[i];
        Break; // First one is best (sorted by priority)
      end;
    end;
  end;
  
  // Set active dispatch table
  if IsBackendRegistered(bestBackend) then
    g_CurrentDispatch := @g_BackendTables[bestBackend]
  else
    g_CurrentDispatch := nil; // Will cause runtime error if used
    
  g_DispatchInitialized := True;
end;

procedure InitializeDispatch;
begin
  if not g_InitLock then
  begin
    g_InitLock := True;
    DoInitializeDispatch;
  end;
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
  
  // If this is the first registration or a better backend, re-initialize
  if g_DispatchInitialized then
  begin
    g_DispatchInitialized := False;
    InitializeDispatch;
  end;
end;

function IsBackendRegistered(backend: TSimdBackend): Boolean;
begin
  Result := g_BackendRegistered[backend];
end;

// === Initialization ===

initialization
  // Initialize dispatch system on unit load
  InitializeDispatch;

end.

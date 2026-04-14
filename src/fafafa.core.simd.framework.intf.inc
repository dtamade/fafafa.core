// Canonical façade convenience wrapper for fafafa.core.simd.cpuinfo.GetCPUInfo.
function GetCPUInfo: TCPUInfo;

// Canonical runtime/control-plane façade.
function GetCurrentRuntimeSnapshot: TSimdRuntimeSnapshot;
function GetCurrentBackend: TSimdBackend;
function GetCurrentBackendInfo: TSimdBackendInfo;

// Compatibility façade alias for GetCPUInfo.
function GetCPUInformation: TCPUInfo;

// Canonical CPU capability view.
function GetSupportedBackendList: TSimdBackendArray;
function GetBestSupportedBackend: TSimdBackend;

// Canonical runtime registration / dispatchability view.
function IsBackendRegisteredInBinary(aBackend: TSimdBackend): Boolean;
function GetRegisteredBackendList: TSimdBackendArray;
function GetDispatchableBackendList: TSimdBackendArray;
function GetBestDispatchableBackend: TSimdBackend;

// Compatibility alias for the dispatchable view.
function GetAvailableBackendList: TSimdBackendArray;

// Canonical runtime control-plane mutators.
function TrySetCurrentBackend(aBackend: TSimdBackend): Boolean;
procedure SetCurrentBackend(aBackend: TSimdBackend);
procedure ResetCurrentBackendSelection;

// Legacy façade aliases kept for compatibility.
function TryForceBackend(aBackend: TSimdBackend): Boolean;
procedure ForceBackend(aBackend: TSimdBackend);
procedure ResetBackendSelection;

// Memory helpers.
function AllocateAligned(size: NativeUInt; alignment: NativeUInt = 32): Pointer;
procedure FreeAligned(ptr: Pointer);
function IsPointerAligned(ptr: Pointer; alignment: NativeUInt = 32): Boolean;

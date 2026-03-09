function GetCurrentBackend: TSimdBackend;
begin
  Result := GetActiveBackend;
end;

function GetCurrentBackendInfo: TSimdBackendInfo;
begin
  Result := GetBackendInfo(GetActiveBackend);
end;

function GetCPUInformation: TCPUInfo;
begin
  Result := GetCPUInfo;
end;

function GetAvailableBackendList: TSimdBackendArray;
begin
  Result := GetAvailableBackends;
end;

function TryForceBackend(aBackend: TSimdBackend): Boolean;
begin
  Result := TrySetActiveBackend(aBackend);
end;

procedure ForceBackend(backend: TSimdBackend);
begin
  SetActiveBackend(backend);
end;

procedure ResetBackendSelection;
begin
  ResetToAutomaticBackend;
end;

function AllocateAligned(size: NativeUInt; alignment: NativeUInt): Pointer;
begin
  Result := AlignedAlloc(size, alignment);
end;

procedure FreeAligned(ptr: Pointer);
begin
  AlignedFree(ptr);
end;

function IsPointerAligned(ptr: Pointer; alignment: NativeUInt): Boolean;
begin
  Result := fafafa.core.simd.memutils.IsAligned(ptr, alignment);
end;

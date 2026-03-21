function GetCurrentBackend: TSimdBackend;
begin
  Result := GetActiveBackend;
end;

function GetCurrentBackendInfo: TSimdBackendInfo;
var
  LDispatch: PSimdDispatchTable;
begin
  LDispatch := GetDispatchTable;
  if LDispatch <> nil then
    Result := LDispatch^.BackendInfo
  else
    Result := GetBackendInfo(GetActiveBackend);
end;

function GetCPUInformation: TCPUInfo;
begin
  Result := GetCPUInfo;
end;

function GetSupportedBackendList: TSimdBackendArray;
begin
  Result := GetSupportedBackends;
end;

function GetBestSupportedBackend: TSimdBackend;
begin
  Result := GetBestBackendOnCPU;
end;

function IsBackendRegisteredInBinary(aBackend: TSimdBackend): Boolean;
begin
  Result := IsBackendRegistered(aBackend);
end;

function GetRegisteredBackendList: TSimdBackendArray;
var
  LBackend: TSimdBackend;
  LCount: Integer;
begin
  LCount := 0;
  for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    if IsBackendRegisteredInBinary(LBackend) then
      Inc(LCount);

  SetLength(Result, LCount);
  LCount := 0;
  for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    if IsBackendRegisteredInBinary(LBackend) then
    begin
      Result[LCount] := LBackend;
      Inc(LCount);
    end;
end;

function GetDispatchableBackendList: TSimdBackendArray;
begin
  Result := GetDispatchableBackends;
end;

function GetBestDispatchableBackend: TSimdBackend;
begin
  Result := fafafa.core.simd.dispatch.GetBestDispatchableBackend;
end;

function GetAvailableBackendList: TSimdBackendArray;
begin
  Result := GetDispatchableBackendList;
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

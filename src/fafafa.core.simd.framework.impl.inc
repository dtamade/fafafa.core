function GetCPUInformation: TCPUInfo;
begin
  Result := GetCPUInfo;
end;

function GetCurrentBackend: TSimdBackend;
begin
  Result := GetActiveBackend;
end;

function GetCurrentBackendInfo: TSimdBackendInfo;
begin
  Result := GetBackendInfo(GetCurrentBackend);
end;

function GetBackendName(aBackend: TSimdBackend): string;
var
  LInfo: TSimdBackendInfo;
begin
  LInfo := GetBackendInfo(aBackend);
  if LInfo.Name <> '' then
    Exit(LInfo.Name);

  Result := 'Unknown';
  case aBackend of
    sbScalar: Result := 'Scalar';
    sbSSE2: Result := 'SSE2';
    sbSSE3: Result := 'SSE3';
    sbSSSE3: Result := 'SSSE3';
    sbSSE41: Result := 'SSE4.1';
    sbSSE42: Result := 'SSE4.2';
    sbAVX2: Result := 'AVX2';
    sbAVX512: Result := 'AVX-512';
    sbNEON: Result := 'NEON';
    sbRISCVV: Result := 'RISCVV';
  end;
end;

procedure ForceBackend(aBackend: TSimdBackend);
begin
  SetActiveBackend(aBackend);
end;

procedure ResetBackendSelection;
begin
  ResetToAutomaticBackend;
end;

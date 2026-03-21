const
  FAFAFA_SIMD_PUBLIC_ABI_VERSION_MAJOR: UInt16 = 1;
  FAFAFA_SIMD_PUBLIC_ABI_VERSION_MINOR: UInt16 = 3;
  FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_HI: UInt64 = QWord($73696D645055424C);
  FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_LO: UInt64 = QWord($4142495441424C45);

type
  PSimdPublicApiBindingState = ^TSimdPublicApiBindingState;
  TSimdPublicApiBindingState = record
    NextOwned: PSimdPublicApiBindingState;
    Api: TFafafaSimdPublicApi;
    MemEqualBound: function(aA, aB: Pointer; aLen: SizeUInt): LongBool;
    MemFindByteBound: function(aP: Pointer; aLen: SizeUInt; aValue: Byte): PtrInt;
    MemDiffRangeBound: function(aA, aB: Pointer; aLen: SizeUInt;
      out aFirstDiff, aLastDiff: SizeUInt): Boolean;
    SumBytesBound: function(aP: Pointer; aLen: SizeUInt): UInt64;
    CountByteBound: function(aP: Pointer; aLen: SizeUInt; aValue: Byte): SizeUInt;
    BitsetPopCountBound: function(aP: Pointer; aByteLen: SizeUInt): SizeUInt;
    Utf8ValidateBound: function(aP: Pointer; aLen: SizeUInt): Boolean;
    AsciiIEqualBound: function(aA, aB: Pointer; aLen: SizeUInt): Boolean;
    BytesIndexOfBound: function(aHaystack: Pointer; aHaystackLen: SizeUInt;
      aNeedle: Pointer; aNeedleLen: SizeUInt): PtrInt;
    MemCopyBound: procedure(aSrc, aDst: Pointer; aLen: SizeUInt);
    MemSetBound: procedure(aDst: Pointer; aLen: SizeUInt; aValue: Byte);
    ToLowerAsciiBound: procedure(aP: Pointer; aLen: SizeUInt);
    ToUpperAsciiBound: procedure(aP: Pointer; aLen: SizeUInt);
    MemReverseBound: procedure(aP: Pointer; aLen: SizeUInt);
    MinMaxBytesBound: procedure(aP: Pointer; aLen: SizeUInt; out aMinVal, aMaxVal: Byte);
  end;

var
  g_SimdBackendNameCache: array[TSimdBackend] of AnsiString;
  g_SimdBackendDescriptionCache: array[TSimdBackend] of AnsiString;
  g_SimdPublicApiStatePtr: Pointer = nil;
  g_SimdPublicApiOwnedHead: PSimdPublicApiBindingState = nil;
  g_SimdPublicApiRebindLock: TRTLCriticalSection;

function DefaultBackendName(const aBackend: TSimdBackend): AnsiString; inline;
begin
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
    sbRISCVV: Result := 'RISC-V V';
  end;
end;

function DefaultBackendDescription(const aBackend: TSimdBackend): AnsiString; inline;
begin
  case aBackend of
    sbScalar: Result := 'Pure scalar reference implementation';
    sbSSE2: Result := 'x86-64 SSE2 SIMD implementation';
    sbSSE3: Result := 'x86-64 SSE3 SIMD implementation';
    sbSSSE3: Result := 'x86-64 SSSE3 SIMD implementation';
    sbSSE41: Result := 'x86-64 SSE4.1 SIMD implementation';
    sbSSE42: Result := 'x86-64 SSE4.2 SIMD implementation';
    sbAVX2: Result := 'x86-64 AVX2 SIMD implementation';
    sbAVX512: Result := 'x86-64 AVX-512 SIMD implementation';
    sbNEON: Result := 'ARM NEON 128-bit SIMD';
    sbRISCVV: Result := 'RISC-V Vector Extension (RVV)';
  end;
end;

function SimdCapabilitiesToAbiBits(const aCaps: TSimdCapabilities): UInt64;
var
  LCap: TSimdCapability;
begin
  Result := 0;
  for LCap := Low(TSimdCapability) to High(TSimdCapability) do
    if LCap in aCaps then
      Result := Result or (UInt64(1) shl Ord(LCap));
end;

function SimdBackendToAbiFlags(aBackend: TSimdBackend): TFafafaSimdAbiFlags;
begin
  Result := 0;
  if IsBackendAvailableOnCPU(aBackend) then
    Result := Result or FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU;
  if IsBackendRegisteredInBinary(aBackend) then
    Result := Result or FAF_SIMD_ABI_FLAG_REGISTERED;
  if IsBackendDispatchable(aBackend) then
    Result := Result or FAF_SIMD_ABI_FLAG_DISPATCHABLE;
  if GetCurrentBackend = aBackend then
    Result := Result or FAF_SIMD_ABI_FLAG_ACTIVE;
  if aBackend = sbRISCVV then
    Result := Result or FAF_SIMD_ABI_FLAG_EXPERIMENTAL;
end;

function BuildSimdBackendAbiFlagsFromSnapshot(const aBackend: TSimdBackend;
  const aRegistered, aDispatchable, aActive: Boolean): TFafafaSimdAbiFlags;
begin
  Result := 0;
  if IsBackendAvailableOnCPU(aBackend) then
    Result := Result or FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU;
  if aRegistered then
    Result := Result or FAF_SIMD_ABI_FLAG_REGISTERED;
  if aDispatchable then
    Result := Result or FAF_SIMD_ABI_FLAG_DISPATCHABLE;
  if aActive then
    Result := Result or FAF_SIMD_ABI_FLAG_ACTIVE;
  if aBackend = sbRISCVV then
    Result := Result or FAF_SIMD_ABI_FLAG_EXPERIMENTAL;
end;

function TryAbiBackendId(aBackendId: UInt32; out aBackend: TSimdBackend): Boolean; inline;
begin
  Result := aBackendId <= UInt32(Ord(High(TSimdBackend)));
  if Result then
    aBackend := TSimdBackend(aBackendId)
  else
    aBackend := sbScalar;
end;

function GetCurrentSimdPublicApiBindingState: PSimdPublicApiBindingState; inline;
begin
  Result := PSimdPublicApiBindingState(atomic_load_ptr(g_SimdPublicApiStatePtr, mo_acquire));
end;

function CreateSimdPublicApiBindingState: PSimdPublicApiBindingState;
begin
  New(Result);
  FillChar(Result^, SizeOf(Result^), 0);
  Result^.NextOwned := g_SimdPublicApiOwnedHead;
  g_SimdPublicApiOwnedHead := Result;
end;

procedure InitializeSimdPublicApiBinding;
begin
  InitCriticalSection(g_SimdPublicApiRebindLock);
end;

procedure FinalizeSimdPublicApiBinding;
var
  LState: PSimdPublicApiBindingState;
  LNext: PSimdPublicApiBindingState;
begin
  EnterCriticalSection(g_SimdPublicApiRebindLock);
  try
    atomic_store_ptr(g_SimdPublicApiStatePtr, nil, mo_release);
    LState := g_SimdPublicApiOwnedHead;
    g_SimdPublicApiOwnedHead := nil;
  finally
    LeaveCriticalSection(g_SimdPublicApiRebindLock);
  end;

  while LState <> nil do
  begin
    LNext := LState^.NextOwned;
    Dispose(LState);
    LState := LNext;
  end;

  DoneCriticalSection(g_SimdPublicApiRebindLock);
end;

function PublicAbiMemEqual(aA, aB: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.MemEqualBound) then
    Result := LState^.MemEqualBound(aA, aB, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemEqual(aA, aB, aLen);
  end;
end;

function PublicAbiMemFindByte(aP: Pointer; aLen: SizeUInt; aValue: Byte): PtrInt; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.MemFindByteBound) then
    Result := LState^.MemFindByteBound(aP, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemFindByte(aP, aLen, aValue);
  end;
end;

function PublicAbiMemDiffRange(aA, aB: Pointer; aLen: SizeUInt;
  out aFirstDiff, aLastDiff: SizeUInt): LongBool; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.MemDiffRangeBound) then
    Result := LState^.MemDiffRangeBound(aA, aB, aLen, aFirstDiff, aLastDiff)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemDiffRange(aA, aB, aLen, aFirstDiff, aLastDiff);
  end;
end;

function PublicAbiSumBytes(aP: Pointer; aLen: SizeUInt): UInt64; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.SumBytesBound) then
    Result := LState^.SumBytesBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.SumBytes(aP, aLen);
  end;
end;

function PublicAbiCountByte(aP: Pointer; aLen: SizeUInt; aValue: Byte): SizeUInt; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.CountByteBound) then
    Result := LState^.CountByteBound(aP, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.CountByte(aP, aLen, aValue);
  end;
end;

function PublicAbiBitsetPopCount(aP: Pointer; aByteLen: SizeUInt): SizeUInt; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.BitsetPopCountBound) then
    Result := LState^.BitsetPopCountBound(aP, aByteLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.BitsetPopCount(aP, aByteLen);
  end;
end;

function PublicAbiUtf8Validate(aP: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.Utf8ValidateBound) then
    Result := LState^.Utf8ValidateBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.Utf8Validate(aP, aLen);
  end;
end;

function PublicAbiAsciiIEqual(aA, aB: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.AsciiIEqualBound) then
    Result := LState^.AsciiIEqualBound(aA, aB, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.AsciiIEqual(aA, aB, aLen);
  end;
end;

function PublicAbiBytesIndexOf(aHaystack: Pointer; aHaystackLen: SizeUInt;
  aNeedle: Pointer; aNeedleLen: SizeUInt): PtrInt; cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.BytesIndexOfBound) then
    Result := LState^.BytesIndexOfBound(aHaystack, aHaystackLen, aNeedle, aNeedleLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.BytesIndexOf(aHaystack, aHaystackLen, aNeedle, aNeedleLen);
  end;
end;

procedure PublicAbiMemCopy(aSrc, aDst: Pointer; aLen: SizeUInt); cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.MemCopyBound) then
    LState^.MemCopyBound(aSrc, aDst, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemCopy(aSrc, aDst, aLen);
  end;
end;

procedure PublicAbiMemSet(aDst: Pointer; aLen: SizeUInt; aValue: Byte); cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.MemSetBound) then
    LState^.MemSetBound(aDst, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemSet(aDst, aLen, aValue);
  end;
end;

procedure PublicAbiToLowerAscii(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.ToLowerAsciiBound) then
    LState^.ToLowerAsciiBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.ToLowerAscii(aP, aLen);
  end;
end;

procedure PublicAbiToUpperAscii(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.ToUpperAsciiBound) then
    LState^.ToUpperAsciiBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.ToUpperAscii(aP, aLen);
  end;
end;

procedure PublicAbiMemReverse(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.MemReverseBound) then
    LState^.MemReverseBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemReverse(aP, aLen);
  end;
end;

procedure PublicAbiMinMaxBytes(aP: Pointer; aLen: SizeUInt; out aMinVal, aMaxVal: Byte); cdecl;
var
  LState: PSimdPublicApiBindingState;
  LDispatch: PSimdDispatchTable;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if (LState <> nil) and Assigned(LState^.MinMaxBytesBound) then
    LState^.MinMaxBytesBound(aP, aLen, aMinVal, aMaxVal)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MinMaxBytes(aP, aLen, aMinVal, aMaxVal);
  end;
end;

procedure EnsureBackendTextCache(const aBackend: TSimdBackend);
var
  LInfo: TSimdBackendInfo;
begin
  // Backends can be re-registered at runtime, so refresh the cached text view
  // from the latest backend metadata instead of pinning the first observed value.
  LInfo := GetBackendInfo(aBackend);
  if LInfo.Name <> '' then
    g_SimdBackendNameCache[aBackend] := AnsiString(LInfo.Name)
  else
    g_SimdBackendNameCache[aBackend] := DefaultBackendName(aBackend);

  if LInfo.Description <> '' then
    g_SimdBackendDescriptionCache[aBackend] := AnsiString(LInfo.Description)
  else
    g_SimdBackendDescriptionCache[aBackend] := DefaultBackendDescription(aBackend);
end;

procedure RebindSimdPublicApi;
var
  LDispatch: PSimdDispatchTable;
  LState: PSimdPublicApiBindingState;
begin
  EnterCriticalSection(g_SimdPublicApiRebindLock);
  try
  LDispatch := GetDispatchTable;
  if LDispatch = nil then
    Exit;

    LState := CreateSimdPublicApiBindingState;
    LState^.Api.StructSize := SizeOf(LState^.Api);
    LState^.Api.AbiVersionMajor := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MAJOR;
    LState^.Api.AbiVersionMinor := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MINOR;
    LState^.Api.AbiSignatureHi := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_HI;
    LState^.Api.AbiSignatureLo := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_LO;
    LState^.Api.ActiveBackendId := UInt32(Ord(LDispatch^.Backend));
    LState^.Api.ActiveFlags := SimdBackendToAbiFlags(LDispatch^.Backend);
    LState^.MemEqualBound := LDispatch^.MemEqual;
    LState^.MemFindByteBound := LDispatch^.MemFindByte;
    LState^.MemDiffRangeBound := LDispatch^.MemDiffRange;
    LState^.SumBytesBound := LDispatch^.SumBytes;
    LState^.CountByteBound := LDispatch^.CountByte;
    LState^.BitsetPopCountBound := LDispatch^.BitsetPopCount;
    LState^.Utf8ValidateBound := LDispatch^.Utf8Validate;
    LState^.AsciiIEqualBound := LDispatch^.AsciiIEqual;
    LState^.BytesIndexOfBound := LDispatch^.BytesIndexOf;
    LState^.MemCopyBound := LDispatch^.MemCopy;
    LState^.MemSetBound := LDispatch^.MemSet;
    LState^.ToLowerAsciiBound := LDispatch^.ToLowerAscii;
    LState^.ToUpperAsciiBound := LDispatch^.ToUpperAscii;
    LState^.MemReverseBound := LDispatch^.MemReverse;
    LState^.MinMaxBytesBound := LDispatch^.MinMaxBytes;
    LState^.Api.MemEqual := @PublicAbiMemEqual;
    LState^.Api.MemFindByte := @PublicAbiMemFindByte;
    LState^.Api.MemDiffRange := @PublicAbiMemDiffRange;
    LState^.Api.SumBytes := @PublicAbiSumBytes;
    LState^.Api.CountByte := @PublicAbiCountByte;
    LState^.Api.BitsetPopCount := @PublicAbiBitsetPopCount;
    LState^.Api.Utf8Validate := @PublicAbiUtf8Validate;
    LState^.Api.AsciiIEqual := @PublicAbiAsciiIEqual;
    LState^.Api.BytesIndexOf := @PublicAbiBytesIndexOf;
    LState^.Api.MemCopy := @PublicAbiMemCopy;
    LState^.Api.MemSet := @PublicAbiMemSet;
    LState^.Api.ToLowerAscii := @PublicAbiToLowerAscii;
    LState^.Api.ToUpperAscii := @PublicAbiToUpperAscii;
    LState^.Api.MemReverse := @PublicAbiMemReverse;
    LState^.Api.MinMaxBytes := @PublicAbiMinMaxBytes;

    atomic_store_ptr(g_SimdPublicApiStatePtr, Pointer(LState), mo_release);
  finally
    LeaveCriticalSection(g_SimdPublicApiRebindLock);
  end;
end;

function GetSimdAbiVersionMajor: UInt16; cdecl;
begin
  Result := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MAJOR;
end;

function GetSimdAbiVersionMinor: UInt16; cdecl;
begin
  Result := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MINOR;
end;

procedure GetSimdAbiSignature(out aHi, aLo: UInt64); cdecl;
begin
  aHi := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_HI;
  aLo := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_LO;
end;

function TryGetSimdBackendPodInfo(aBackend: TSimdBackend; out aInfo: TFafafaSimdBackendPodInfo): Boolean; cdecl;
var
  LDispatchTable: TSimdDispatchTable;
  LCurrentDispatch: PSimdDispatchTable;
  LRegistered: Boolean;
  LDispatchable: Boolean;
  LActive: Boolean;
begin
  aInfo := Default(TFafafaSimdBackendPodInfo);
  aInfo.StructSize := SizeOf(aInfo);
  aInfo.BackendId := UInt32(Ord(aBackend));

  LRegistered := TryGetRegisteredBackendDispatchTable(aBackend, LDispatchTable);
  if LRegistered then
  begin
    aInfo.CapabilityBits := SimdCapabilitiesToAbiBits(LDispatchTable.BackendInfo.Capabilities);
    LDispatchable := LDispatchTable.BackendInfo.Available and IsBackendAvailableOnCPU(aBackend);
    aInfo.Priority := LDispatchTable.BackendInfo.Priority;
  end
  else
  begin
    aInfo.CapabilityBits := 0;
    LDispatchable := False;
    aInfo.Priority := GetBackendInfo(aBackend).Priority;
  end;

  LCurrentDispatch := GetDispatchTable;
  LActive := (LCurrentDispatch <> nil) and (LCurrentDispatch^.Backend = aBackend);
  aInfo.Flags := BuildSimdBackendAbiFlagsFromSnapshot(aBackend, LRegistered, LDispatchable, LActive);
  Result := True;
end;

function GetSimdBackendNamePtr(aBackend: TSimdBackend): PAnsiChar; cdecl;
begin
  EnsureBackendTextCache(aBackend);
  Result := PAnsiChar(g_SimdBackendNameCache[aBackend]);
end;

function GetSimdBackendDescriptionPtr(aBackend: TSimdBackend): PAnsiChar; cdecl;
begin
  EnsureBackendTextCache(aBackend);
  Result := PAnsiChar(g_SimdBackendDescriptionCache[aBackend]);
end;

function GetSimdPublicApi: PFafafaSimdPublicApi; cdecl;
var
  LState: PSimdPublicApiBindingState;
begin
  LState := GetCurrentSimdPublicApiBindingState;
  if LState = nil then
  begin
    RebindSimdPublicApi;
    LState := GetCurrentSimdPublicApiBindingState;
  end;

  if LState = nil then
    Exit(nil);

  Result := @LState^.Api;
end;

function fafafa_simd_abi_version_major: UInt16; cdecl;
begin
  Result := GetSimdAbiVersionMajor;
end;

function fafafa_simd_abi_version_minor: UInt16; cdecl;
begin
  Result := GetSimdAbiVersionMinor;
end;

procedure fafafa_simd_abi_signature(out aHi, aLo: UInt64); cdecl;
begin
  GetSimdAbiSignature(aHi, aLo);
end;

function fafafa_simd_get_backend_pod_info(aBackendId: UInt32; out aInfo: TFafafaSimdBackendPodInfo): LongBool; cdecl;
var
  LBackend: TSimdBackend;
begin
  if not TryAbiBackendId(aBackendId, LBackend) then
  begin
    aInfo := Default(TFafafaSimdBackendPodInfo);
    Exit(False);
  end;
  Result := TryGetSimdBackendPodInfo(LBackend, aInfo);
end;

function fafafa_simd_backend_name(aBackendId: UInt32): PAnsiChar; cdecl;
var
  LBackend: TSimdBackend;
begin
  if not TryAbiBackendId(aBackendId, LBackend) then
    Exit(nil);
  Result := GetSimdBackendNamePtr(LBackend);
end;

function fafafa_simd_backend_description(aBackendId: UInt32): PAnsiChar; cdecl;
var
  LBackend: TSimdBackend;
begin
  if not TryAbiBackendId(aBackendId, LBackend) then
    Exit(nil);
  Result := GetSimdBackendDescriptionPtr(LBackend);
end;

function fafafa_simd_get_public_api: PFafafaSimdPublicApi; cdecl;
begin
  Result := GetSimdPublicApi;
end;

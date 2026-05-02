const
  FAFAFA_SIMD_PUBLIC_ABI_VERSION_MAJOR: UInt16 = 1;
  FAFAFA_SIMD_PUBLIC_ABI_VERSION_MINOR: UInt16 = 3;
  FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_HI: UInt64 = QWord($73696D645055424C);
  FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_LO: UInt64 = QWord($4142495441424C45);

type
  TSimdPublicMemEqualFunc = function(aA, aB: Pointer; aLen: SizeUInt): LongBool;
  TSimdPublicMemFindByteFunc = function(aP: Pointer; aLen: SizeUInt; aValue: Byte): PtrInt;
  TSimdPublicMemDiffRangeFunc = function(aA, aB: Pointer; aLen: SizeUInt;
    out aFirstDiff, aLastDiff: SizeUInt): Boolean;
  TSimdPublicSumBytesFunc = function(aP: Pointer; aLen: SizeUInt): UInt64;
  TSimdPublicCountByteFunc = function(aP: Pointer; aLen: SizeUInt; aValue: Byte): SizeUInt;
  TSimdPublicBitsetPopCountFunc = function(aP: Pointer; aByteLen: SizeUInt): SizeUInt;
  TSimdPublicUtf8ValidateFunc = function(aP: Pointer; aLen: SizeUInt): Boolean;
  TSimdPublicAsciiIEqualFunc = function(aA, aB: Pointer; aLen: SizeUInt): Boolean;
  TSimdPublicBytesIndexOfFunc = function(aHaystack: Pointer; aHaystackLen: SizeUInt;
    aNeedle: Pointer; aNeedleLen: SizeUInt): PtrInt;
  TSimdPublicMemCopyFunc = procedure(aSrc, aDst: Pointer; aLen: SizeUInt);
  TSimdPublicMemSetFunc = procedure(aDst: Pointer; aLen: SizeUInt; aValue: Byte);
  TSimdPublicAsciiCaseFunc = procedure(aP: Pointer; aLen: SizeUInt);
  TSimdPublicMemReverseFunc = procedure(aP: Pointer; aLen: SizeUInt);
  TSimdPublicMinMaxBytesFunc = procedure(aP: Pointer; aLen: SizeUInt; out aMinVal, aMaxVal: Byte);

  PSimdPublicApiBindingState = ^TSimdPublicApiBindingState;
  TSimdPublicApiBindingState = record
    NextOwned: PSimdPublicApiBindingState;
    // Metadata stays frozen with the published table pointer, while the ABI
    // entry points remain stable cdecl shims that lazily hop through the
    // latest published bound fast-paths.
    Api: TFafafaSimdPublicApi;
    Dispatch: PSimdDispatchTable;
    MemEqualBound: TSimdPublicMemEqualFunc;
    MemFindByteBound: TSimdPublicMemFindByteFunc;
    MemDiffRangeBound: TSimdPublicMemDiffRangeFunc;
    SumBytesBound: TSimdPublicSumBytesFunc;
    CountByteBound: TSimdPublicCountByteFunc;
    BitsetPopCountBound: TSimdPublicBitsetPopCountFunc;
    Utf8ValidateBound: TSimdPublicUtf8ValidateFunc;
    AsciiIEqualBound: TSimdPublicAsciiIEqualFunc;
    BytesIndexOfBound: TSimdPublicBytesIndexOfFunc;
    MemCopyBound: TSimdPublicMemCopyFunc;
    MemSetBound: TSimdPublicMemSetFunc;
    ToLowerAsciiBound: TSimdPublicAsciiCaseFunc;
    ToUpperAsciiBound: TSimdPublicAsciiCaseFunc;
    MemReverseBound: TSimdPublicMemReverseFunc;
    MinMaxBytesBound: TSimdPublicMinMaxBytesFunc;
  end;

  PSimdBackendTextState = ^TSimdBackendTextState;
  TSimdBackendTextState = record
    NextOwned: PSimdBackendTextState;
    NameText: AnsiString;
    DescriptionText: AnsiString;
  end;

var
  g_SimdPublicApiStatePtr: Pointer = nil;
  g_SimdPublicApiTargetDispatchPtr: Pointer = nil;
  g_SimdPublicApiMemEqualPtr: Pointer = nil;
  g_SimdPublicApiMemFindBytePtr: Pointer = nil;
  g_SimdPublicApiMemDiffRangePtr: Pointer = nil;
  g_SimdPublicApiSumBytesPtr: Pointer = nil;
  g_SimdPublicApiCountBytePtr: Pointer = nil;
  g_SimdPublicApiBitsetPopCountPtr: Pointer = nil;
  g_SimdPublicApiUtf8ValidatePtr: Pointer = nil;
  g_SimdPublicApiAsciiIEqualPtr: Pointer = nil;
  g_SimdPublicApiBytesIndexOfPtr: Pointer = nil;
  g_SimdPublicApiMemCopyPtr: Pointer = nil;
  g_SimdPublicApiMemSetPtr: Pointer = nil;
  g_SimdPublicApiToLowerAsciiPtr: Pointer = nil;
  g_SimdPublicApiToUpperAsciiPtr: Pointer = nil;
  g_SimdPublicApiMemReversePtr: Pointer = nil;
  g_SimdPublicApiMinMaxBytesPtr: Pointer = nil;
  // Public API tables may be cached by consumers after later control-plane
  // mutations, so published states stay process-owned until finalization.
  g_SimdPublicApiOwnedHead: PSimdPublicApiBindingState = nil;
  g_SimdPublicApiRebindLock: TRTLCriticalSection;
  g_SimdBackendTextStatePtrs: array[TSimdBackend] of Pointer;
  g_SimdBackendTextOwnedHead: PSimdBackendTextState = nil;
  g_SimdBackendTextLock: TRTLCriticalSection;

function DefaultBackendName(const aBackend: TSimdBackend): AnsiString; inline;
begin
  Result := '';
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
  Result := '';
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
  Result := PSimdPublicApiBindingState(atomic_load(g_SimdPublicApiStatePtr, mo_acquire));
end;

function GetCurrentSimdPublicApiTargetDispatch: PSimdDispatchTable; inline;
begin
  Result := PSimdDispatchTable(atomic_load(g_SimdPublicApiTargetDispatchPtr, mo_acquire));
end;

procedure RebindSimdPublicApi; forward;

function LoadSimdPublicApiBoundPtr(var aFuncPtr: Pointer): Pointer; inline;
begin
  // Hot-path loads stay relaxed on x86/x86_64 and acquire on weaker targets
  // through fafafa.core.atomic defaults, mirroring the façade fast-path model.
  Result := atomic_load(aFuncPtr);
end;

function GetLiveSimdPublicApiBindingState: PSimdPublicApiBindingState; inline;
var
  LCurrent: PSimdPublicApiBindingState;
  LTargetDispatch: PSimdDispatchTable;
begin
  LCurrent := GetCurrentSimdPublicApiBindingState;
  LTargetDispatch := GetCurrentSimdPublicApiTargetDispatch;
  if LTargetDispatch = nil then
    LTargetDispatch := GetDispatchTable;

  if (LCurrent = nil) or
     ((LTargetDispatch <> nil) and (LCurrent^.Dispatch <> LTargetDispatch)) then
  begin
    RebindSimdPublicApi;
    Result := GetCurrentSimdPublicApiBindingState;
    if (Result = nil) and (LCurrent <> nil) then
      Result := LCurrent;
    Exit;
  end;
  Result := LCurrent;
end;

function CreateSimdPublicApiBindingState: PSimdPublicApiBindingState;
begin
  New(Result);
  FillChar(Result^, SizeOf(Result^), 0);
  Result^.NextOwned := g_SimdPublicApiOwnedHead;
  g_SimdPublicApiOwnedHead := Result;
end;

function FindOwnedSimdPublicApiBindingState(
  aDispatch: PSimdDispatchTable): PSimdPublicApiBindingState;
begin
  Result := g_SimdPublicApiOwnedHead;
  while Result <> nil do
  begin
    if Result^.Dispatch = aDispatch then
      Exit;
    Result := Result^.NextOwned;
  end;
end;

function GetCurrentSimdBackendTextState(
  const aBackend: TSimdBackend): PSimdBackendTextState; inline;
begin
  Result := PSimdBackendTextState(atomic_load(g_SimdBackendTextStatePtrs[aBackend], mo_acquire));
end;

function CreateSimdBackendTextState: PSimdBackendTextState;
begin
  New(Result);
  FillChar(Result^, SizeOf(Result^), 0);
  Result^.NextOwned := g_SimdBackendTextOwnedHead;
  g_SimdBackendTextOwnedHead := Result;
end;

procedure BuildCanonicalBackendText(const aBackend: TSimdBackend;
  out aNameText, aDescriptionText: AnsiString);
var
  LInfo: TSimdBackendInfo;
begin
  LInfo := GetBackendInfo(aBackend);
  aNameText := AnsiString(LInfo.Name);
  aDescriptionText := AnsiString(LInfo.Description);
end;

function BackendTextStateMatches(const aState: PSimdBackendTextState;
  const aNameText, aDescriptionText: AnsiString): Boolean; inline;
begin
  Result := (aState <> nil) and
    (aState^.NameText = aNameText) and
    (aState^.DescriptionText = aDescriptionText);
end;

function GetLiveSimdBackendTextState(
  const aBackend: TSimdBackend): PSimdBackendTextState;
var
  LCurrent: PSimdBackendTextState;
  LState: PSimdBackendTextState;
  LNameText: AnsiString;
  LDescriptionText: AnsiString;
begin
  BuildCanonicalBackendText(aBackend, LNameText, LDescriptionText);
  LCurrent := GetCurrentSimdBackendTextState(aBackend);
  if BackendTextStateMatches(LCurrent, LNameText, LDescriptionText) then
    Exit(LCurrent);

  EnterCriticalSection(g_SimdBackendTextLock);
  try
    LCurrent := GetCurrentSimdBackendTextState(aBackend);
    if BackendTextStateMatches(LCurrent, LNameText, LDescriptionText) then
      Exit(LCurrent);

    LState := CreateSimdBackendTextState;
    LState^.NameText := LNameText;
    LState^.DescriptionText := LDescriptionText;
    atomic_store(g_SimdBackendTextStatePtrs[aBackend], Pointer(LState), mo_release);
    Result := LState;
  finally
    LeaveCriticalSection(g_SimdBackendTextLock);
  end;
end;

procedure InitializeSimdPublicApiBinding;
begin
  InitCriticalSection(g_SimdPublicApiRebindLock);
  InitCriticalSection(g_SimdBackendTextLock);
end;

procedure PublishSimdPublicApiBoundFastPaths(const aDataPlane: PSimdDataPlane); inline;
begin
  atomic_store(g_SimdPublicApiMemEqualPtr, aDataPlane^.MemEqualPtr, mo_release);
  atomic_store(g_SimdPublicApiMemFindBytePtr, aDataPlane^.MemFindBytePtr, mo_release);
  atomic_store(g_SimdPublicApiMemDiffRangePtr, aDataPlane^.MemDiffRangePtr, mo_release);
  atomic_store(g_SimdPublicApiSumBytesPtr, aDataPlane^.SumBytesPtr, mo_release);
  atomic_store(g_SimdPublicApiCountBytePtr, aDataPlane^.CountBytePtr, mo_release);
  atomic_store(g_SimdPublicApiBitsetPopCountPtr, aDataPlane^.BitsetPopCountPtr, mo_release);
  atomic_store(g_SimdPublicApiUtf8ValidatePtr, aDataPlane^.Utf8ValidatePtr, mo_release);
  atomic_store(g_SimdPublicApiAsciiIEqualPtr, aDataPlane^.AsciiIEqualPtr, mo_release);
  atomic_store(g_SimdPublicApiBytesIndexOfPtr, aDataPlane^.BytesIndexOfPtr, mo_release);
  atomic_store(g_SimdPublicApiMemCopyPtr, aDataPlane^.MemCopyPtr, mo_release);
  atomic_store(g_SimdPublicApiMemSetPtr, aDataPlane^.MemSetPtr, mo_release);
  atomic_store(g_SimdPublicApiToLowerAsciiPtr, aDataPlane^.ToLowerAsciiPtr, mo_release);
  atomic_store(g_SimdPublicApiToUpperAsciiPtr, aDataPlane^.ToUpperAsciiPtr, mo_release);
  atomic_store(g_SimdPublicApiMemReversePtr, aDataPlane^.MemReversePtr, mo_release);
  atomic_store(g_SimdPublicApiMinMaxBytesPtr, aDataPlane^.MinMaxBytesPtr, mo_release);
end;

procedure ClearSimdPublicApiBoundFastPaths; inline;
begin
  atomic_store(g_SimdPublicApiMemEqualPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiMemFindBytePtr, nil, mo_release);
  atomic_store(g_SimdPublicApiMemDiffRangePtr, nil, mo_release);
  atomic_store(g_SimdPublicApiSumBytesPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiCountBytePtr, nil, mo_release);
  atomic_store(g_SimdPublicApiBitsetPopCountPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiUtf8ValidatePtr, nil, mo_release);
  atomic_store(g_SimdPublicApiAsciiIEqualPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiBytesIndexOfPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiMemCopyPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiMemSetPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiToLowerAsciiPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiToUpperAsciiPtr, nil, mo_release);
  atomic_store(g_SimdPublicApiMemReversePtr, nil, mo_release);
  atomic_store(g_SimdPublicApiMinMaxBytesPtr, nil, mo_release);
end;

procedure FinalizeSimdPublicApiBinding;
var
  LBackend: TSimdBackend;
  LState: PSimdPublicApiBindingState;
  LNext: PSimdPublicApiBindingState;
  LTextState: PSimdBackendTextState;
  LTextNext: PSimdBackendTextState;
begin
  EnterCriticalSection(g_SimdPublicApiRebindLock);
  try
    atomic_store(g_SimdPublicApiStatePtr, nil, mo_release);
    atomic_store(g_SimdPublicApiTargetDispatchPtr, nil, mo_release);
    ClearSimdPublicApiBoundFastPaths;
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

  EnterCriticalSection(g_SimdBackendTextLock);
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
      atomic_store(g_SimdBackendTextStatePtrs[LBackend], nil, mo_release);
    LTextState := g_SimdBackendTextOwnedHead;
    g_SimdBackendTextOwnedHead := nil;
  finally
    LeaveCriticalSection(g_SimdBackendTextLock);
  end;

  while LTextState <> nil do
  begin
    LTextNext := LTextState^.NextOwned;
    Dispose(LTextState);
    LTextState := LTextNext;
  end;

  DoneCriticalSection(g_SimdBackendTextLock);
  DoneCriticalSection(g_SimdPublicApiRebindLock);
end;

function PublicAbiMemEqual(aA, aB: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LFunc: TSimdPublicMemEqualFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicMemEqualFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemEqualPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicMemEqualFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemEqualPtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aA, aB, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemEqual(aA, aB, aLen);
  end;
end;

function PublicAbiMemFindByte(aP: Pointer; aLen: SizeUInt; aValue: Byte): PtrInt; cdecl;
var
  LFunc: TSimdPublicMemFindByteFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicMemFindByteFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemFindBytePtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicMemFindByteFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemFindBytePtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aP, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemFindByte(aP, aLen, aValue);
  end;
end;

function PublicAbiMemDiffRange(aA, aB: Pointer; aLen: SizeUInt;
  out aFirstDiff, aLastDiff: SizeUInt): LongBool; cdecl;
var
  LFunc: TSimdPublicMemDiffRangeFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicMemDiffRangeFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemDiffRangePtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicMemDiffRangeFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemDiffRangePtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aA, aB, aLen, aFirstDiff, aLastDiff)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemDiffRange(aA, aB, aLen, aFirstDiff, aLastDiff);
  end;
end;

function PublicAbiSumBytes(aP: Pointer; aLen: SizeUInt): UInt64; cdecl;
var
  LFunc: TSimdPublicSumBytesFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicSumBytesFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiSumBytesPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicSumBytesFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiSumBytesPtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.SumBytes(aP, aLen);
  end;
end;

function PublicAbiCountByte(aP: Pointer; aLen: SizeUInt; aValue: Byte): SizeUInt; cdecl;
var
  LFunc: TSimdPublicCountByteFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicCountByteFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiCountBytePtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicCountByteFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiCountBytePtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aP, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.CountByte(aP, aLen, aValue);
  end;
end;

function PublicAbiBitsetPopCount(aP: Pointer; aByteLen: SizeUInt): SizeUInt; cdecl;
var
  LFunc: TSimdPublicBitsetPopCountFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicBitsetPopCountFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiBitsetPopCountPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicBitsetPopCountFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiBitsetPopCountPtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aP, aByteLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.BitsetPopCount(aP, aByteLen);
  end;
end;

function PublicAbiUtf8Validate(aP: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LFunc: TSimdPublicUtf8ValidateFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicUtf8ValidateFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiUtf8ValidatePtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicUtf8ValidateFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiUtf8ValidatePtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.Utf8Validate(aP, aLen);
  end;
end;

function PublicAbiAsciiIEqual(aA, aB: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LFunc: TSimdPublicAsciiIEqualFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicAsciiIEqualFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiAsciiIEqualPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicAsciiIEqualFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiAsciiIEqualPtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aA, aB, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.AsciiIEqual(aA, aB, aLen);
  end;
end;

function PublicAbiBytesIndexOf(aHaystack: Pointer; aHaystackLen: SizeUInt;
  aNeedle: Pointer; aNeedleLen: SizeUInt): PtrInt; cdecl;
var
  LFunc: TSimdPublicBytesIndexOfFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicBytesIndexOfFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiBytesIndexOfPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicBytesIndexOfFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiBytesIndexOfPtr));
  end;
  if Assigned(LFunc) then
    Result := LFunc(aHaystack, aHaystackLen, aNeedle, aNeedleLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.BytesIndexOf(aHaystack, aHaystackLen, aNeedle, aNeedleLen);
  end;
end;

procedure PublicAbiMemCopy(aSrc, aDst: Pointer; aLen: SizeUInt); cdecl;
var
  LFunc: TSimdPublicMemCopyFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicMemCopyFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemCopyPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicMemCopyFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemCopyPtr));
  end;
  if Assigned(LFunc) then
    LFunc(aSrc, aDst, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemCopy(aSrc, aDst, aLen);
  end;
end;

procedure PublicAbiMemSet(aDst: Pointer; aLen: SizeUInt; aValue: Byte); cdecl;
var
  LFunc: TSimdPublicMemSetFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicMemSetFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemSetPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicMemSetFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemSetPtr));
  end;
  if Assigned(LFunc) then
    LFunc(aDst, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemSet(aDst, aLen, aValue);
  end;
end;

procedure PublicAbiToLowerAscii(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LFunc: TSimdPublicAsciiCaseFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicAsciiCaseFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiToLowerAsciiPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicAsciiCaseFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiToLowerAsciiPtr));
  end;
  if Assigned(LFunc) then
    LFunc(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.ToLowerAscii(aP, aLen);
  end;
end;

procedure PublicAbiToUpperAscii(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LFunc: TSimdPublicAsciiCaseFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicAsciiCaseFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiToUpperAsciiPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicAsciiCaseFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiToUpperAsciiPtr));
  end;
  if Assigned(LFunc) then
    LFunc(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.ToUpperAscii(aP, aLen);
  end;
end;

procedure PublicAbiMemReverse(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LFunc: TSimdPublicMemReverseFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicMemReverseFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemReversePtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicMemReverseFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMemReversePtr));
  end;
  if Assigned(LFunc) then
    LFunc(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemReverse(aP, aLen);
  end;
end;

procedure PublicAbiMinMaxBytes(aP: Pointer; aLen: SizeUInt; out aMinVal, aMaxVal: Byte); cdecl;
var
  LFunc: TSimdPublicMinMaxBytesFunc;
  LDispatch: PSimdDispatchTable;
begin
  LFunc := TSimdPublicMinMaxBytesFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMinMaxBytesPtr));
  if not Assigned(LFunc) then
  begin
    RebindSimdPublicApi;
    LFunc := TSimdPublicMinMaxBytesFunc(LoadSimdPublicApiBoundPtr(g_SimdPublicApiMinMaxBytesPtr));
  end;
  if Assigned(LFunc) then
    LFunc(aP, aLen, aMinVal, aMaxVal)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MinMaxBytes(aP, aLen, aMinVal, aMaxVal);
  end;
end;

procedure RebindSimdPublicApi;
var
  LDataPlane: PSimdDataPlane;
  LDispatch: PSimdDispatchTable;
  LCurrent: PSimdPublicApiBindingState;
  LState: PSimdPublicApiBindingState;
begin
  EnterCriticalSection(g_SimdPublicApiRebindLock);
  try
    LDataPlane := GetCurrentSimdDataPlane;
    if LDataPlane = nil then
      Exit;
    LDispatch := LDataPlane^.Dispatch;
    if LDispatch = nil then
      Exit;

    LCurrent := GetCurrentSimdPublicApiBindingState;
    if (LCurrent <> nil) and (LCurrent^.Dispatch = LDispatch) then
    begin
      PublishSimdPublicApiBoundFastPaths(LDataPlane);
      atomic_store(g_SimdPublicApiTargetDispatchPtr, Pointer(LDispatch), mo_release);
      atomic_store(g_SimdPublicApiStatePtr, Pointer(LCurrent), mo_release);
      Exit;
    end;

    LState := FindOwnedSimdPublicApiBindingState(LDispatch);
    if LState = nil then
      LState := CreateSimdPublicApiBindingState;

    LState^.Api.StructSize := SizeOf(LState^.Api);
    LState^.Dispatch := LDispatch;
    LState^.Api.AbiVersionMajor := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MAJOR;
    LState^.Api.AbiVersionMinor := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MINOR;
    LState^.Api.AbiSignatureHi := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_HI;
    LState^.Api.AbiSignatureLo := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_LO;
    LState^.Api.ActiveBackendId := UInt32(Ord(LDataPlane^.ActiveBackend));
    LState^.Api.ActiveFlags := BuildSimdBackendAbiFlagsFromSnapshot(
      LDataPlane^.ActiveBackend, True, LDataPlane^.ActiveDispatchable, True);
    LState^.MemEqualBound := TSimdPublicMemEqualFunc(LDataPlane^.MemEqualPtr);
    LState^.MemFindByteBound := TSimdPublicMemFindByteFunc(LDataPlane^.MemFindBytePtr);
    LState^.MemDiffRangeBound := TSimdPublicMemDiffRangeFunc(LDataPlane^.MemDiffRangePtr);
    LState^.SumBytesBound := TSimdPublicSumBytesFunc(LDataPlane^.SumBytesPtr);
    LState^.CountByteBound := TSimdPublicCountByteFunc(LDataPlane^.CountBytePtr);
    LState^.BitsetPopCountBound := TSimdPublicBitsetPopCountFunc(LDataPlane^.BitsetPopCountPtr);
    LState^.Utf8ValidateBound := TSimdPublicUtf8ValidateFunc(LDataPlane^.Utf8ValidatePtr);
    LState^.AsciiIEqualBound := TSimdPublicAsciiIEqualFunc(LDataPlane^.AsciiIEqualPtr);
    LState^.BytesIndexOfBound := TSimdPublicBytesIndexOfFunc(LDataPlane^.BytesIndexOfPtr);
    LState^.MemCopyBound := TSimdPublicMemCopyFunc(LDataPlane^.MemCopyPtr);
    LState^.MemSetBound := TSimdPublicMemSetFunc(LDataPlane^.MemSetPtr);
    LState^.ToLowerAsciiBound := TSimdPublicAsciiCaseFunc(LDataPlane^.ToLowerAsciiPtr);
    LState^.ToUpperAsciiBound := TSimdPublicAsciiCaseFunc(LDataPlane^.ToUpperAsciiPtr);
    LState^.MemReverseBound := TSimdPublicMemReverseFunc(LDataPlane^.MemReversePtr);
    LState^.MinMaxBytesBound := TSimdPublicMinMaxBytesFunc(LDataPlane^.MinMaxBytesPtr);
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

    PublishSimdPublicApiBoundFastPaths(LDataPlane);
    atomic_store(g_SimdPublicApiTargetDispatchPtr, Pointer(LDispatch), mo_release);
    atomic_store(g_SimdPublicApiStatePtr, Pointer(LState), mo_release);
  finally
    LeaveCriticalSection(g_SimdPublicApiRebindLock);
  end;
end;

procedure InvalidateSimdPublicApiBinding;
begin
  // Mirror dataplane publication semantics: cached readers may keep using the
  // last published metadata snapshot, while fresh getters compare its Dispatch
  // pointer against the latest target dispatch and refresh on demand.
  atomic_store(g_SimdPublicApiTargetDispatchPtr, Pointer(GetDispatchTable), mo_release);
  ClearSimdPublicApiBoundFastPaths;
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

  LCurrentDispatch := GetDispatchTable;
  LActive := (LCurrentDispatch <> nil) and (LCurrentDispatch^.Backend = aBackend);

  if LActive then
  begin
    aInfo.CapabilityBits := SimdCapabilitiesToAbiBits(LCurrentDispatch^.BackendInfo.Capabilities);
    LDispatchable := LCurrentDispatch^.BackendInfo.Available and IsBackendAvailableOnCPU(aBackend);
    aInfo.Priority := LCurrentDispatch^.BackendInfo.Priority;
    LRegistered := True;
  end
  else
  begin
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
  end;

  aInfo.Flags := BuildSimdBackendAbiFlagsFromSnapshot(aBackend, LRegistered, LDispatchable, LActive);
  Result := True;
end;

function GetSimdBackendNamePtr(aBackend: TSimdBackend): PAnsiChar; cdecl;
var
  LState: PSimdBackendTextState;
begin
  LState := GetLiveSimdBackendTextState(aBackend);
  if LState = nil then
    Exit(nil);
  Result := PAnsiChar(LState^.NameText);
end;

function GetSimdBackendDescriptionPtr(aBackend: TSimdBackend): PAnsiChar; cdecl;
var
  LState: PSimdBackendTextState;
begin
  LState := GetLiveSimdBackendTextState(aBackend);
  if LState = nil then
    Exit(nil);
  Result := PAnsiChar(LState^.DescriptionText);
end;

function GetSimdPublicApi: PFafafaSimdPublicApi; cdecl;
var
  LState: PSimdPublicApiBindingState;
begin
  LState := GetLiveSimdPublicApiBindingState;

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

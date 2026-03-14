const
  FAFAFA_SIMD_PUBLIC_ABI_VERSION_MAJOR: UInt16 = 1;
  FAFAFA_SIMD_PUBLIC_ABI_VERSION_MINOR: UInt16 = 3;
  FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_HI: UInt64 = QWord($73696D645055424C);
  FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_LO: UInt64 = QWord($4142495441424C45);

var
  g_SimdPublicApi: TFafafaSimdPublicApi;
  g_SimdBackendNameCache: array[TSimdBackend] of AnsiString;
  g_SimdBackendDescriptionCache: array[TSimdBackend] of AnsiString;
  g_SimdPublicMemEqualBound: function(aA, aB: Pointer; aLen: SizeUInt): LongBool = nil;
  g_SimdPublicMemFindByteBound: function(aP: Pointer; aLen: SizeUInt; aValue: Byte): PtrInt = nil;
  g_SimdPublicMemDiffRangeBound: function(aA, aB: Pointer; aLen: SizeUInt;
    out aFirstDiff, aLastDiff: SizeUInt): Boolean = nil;
  g_SimdPublicSumBytesBound: function(aP: Pointer; aLen: SizeUInt): UInt64 = nil;
  g_SimdPublicCountByteBound: function(aP: Pointer; aLen: SizeUInt; aValue: Byte): SizeUInt = nil;
  g_SimdPublicBitsetPopCountBound: function(aP: Pointer; aByteLen: SizeUInt): SizeUInt = nil;
  g_SimdPublicUtf8ValidateBound: function(aP: Pointer; aLen: SizeUInt): Boolean = nil;
  g_SimdPublicAsciiIEqualBound: function(aA, aB: Pointer; aLen: SizeUInt): Boolean = nil;
  g_SimdPublicBytesIndexOfBound: function(aHaystack: Pointer; aHaystackLen: SizeUInt;
    aNeedle: Pointer; aNeedleLen: SizeUInt): PtrInt = nil;
  g_SimdPublicMemCopyBound: procedure(aSrc, aDst: Pointer; aLen: SizeUInt) = nil;
  g_SimdPublicMemSetBound: procedure(aDst: Pointer; aLen: SizeUInt; aValue: Byte) = nil;
  g_SimdPublicToLowerAsciiBound: procedure(aP: Pointer; aLen: SizeUInt) = nil;
  g_SimdPublicToUpperAsciiBound: procedure(aP: Pointer; aLen: SizeUInt) = nil;
  g_SimdPublicMemReverseBound: procedure(aP: Pointer; aLen: SizeUInt) = nil;
  g_SimdPublicMinMaxBytesBound: procedure(aP: Pointer; aLen: SizeUInt; out aMinVal, aMaxVal: Byte) = nil;

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

function TryAbiBackendId(aBackendId: UInt32; out aBackend: TSimdBackend): Boolean; inline;
begin
  Result := aBackendId <= UInt32(Ord(High(TSimdBackend)));
  if Result then
    aBackend := TSimdBackend(aBackendId)
  else
    aBackend := sbScalar;
end;

function PublicAbiMemEqual(aA, aB: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicMemEqualBound) then
    Result := g_SimdPublicMemEqualBound(aA, aB, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemEqual(aA, aB, aLen);
  end;
end;

function PublicAbiMemFindByte(aP: Pointer; aLen: SizeUInt; aValue: Byte): PtrInt; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicMemFindByteBound) then
    Result := g_SimdPublicMemFindByteBound(aP, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemFindByte(aP, aLen, aValue);
  end;
end;

function PublicAbiMemDiffRange(aA, aB: Pointer; aLen: SizeUInt;
  out aFirstDiff, aLastDiff: SizeUInt): LongBool; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicMemDiffRangeBound) then
    Result := g_SimdPublicMemDiffRangeBound(aA, aB, aLen, aFirstDiff, aLastDiff)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.MemDiffRange(aA, aB, aLen, aFirstDiff, aLastDiff);
  end;
end;

function PublicAbiSumBytes(aP: Pointer; aLen: SizeUInt): UInt64; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicSumBytesBound) then
    Result := g_SimdPublicSumBytesBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.SumBytes(aP, aLen);
  end;
end;

function PublicAbiCountByte(aP: Pointer; aLen: SizeUInt; aValue: Byte): SizeUInt; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicCountByteBound) then
    Result := g_SimdPublicCountByteBound(aP, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.CountByte(aP, aLen, aValue);
  end;
end;

function PublicAbiBitsetPopCount(aP: Pointer; aByteLen: SizeUInt): SizeUInt; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicBitsetPopCountBound) then
    Result := g_SimdPublicBitsetPopCountBound(aP, aByteLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.BitsetPopCount(aP, aByteLen);
  end;
end;

function PublicAbiUtf8Validate(aP: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicUtf8ValidateBound) then
    Result := g_SimdPublicUtf8ValidateBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.Utf8Validate(aP, aLen);
  end;
end;

function PublicAbiAsciiIEqual(aA, aB: Pointer; aLen: SizeUInt): LongBool; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicAsciiIEqualBound) then
    Result := g_SimdPublicAsciiIEqualBound(aA, aB, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.AsciiIEqual(aA, aB, aLen);
  end;
end;

function PublicAbiBytesIndexOf(aHaystack: Pointer; aHaystackLen: SizeUInt;
  aNeedle: Pointer; aNeedleLen: SizeUInt): PtrInt; cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicBytesIndexOfBound) then
    Result := g_SimdPublicBytesIndexOfBound(aHaystack, aHaystackLen, aNeedle, aNeedleLen)
  else
  begin
    LDispatch := GetDispatchTable;
    Result := LDispatch^.BytesIndexOf(aHaystack, aHaystackLen, aNeedle, aNeedleLen);
  end;
end;

procedure PublicAbiMemCopy(aSrc, aDst: Pointer; aLen: SizeUInt); cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicMemCopyBound) then
    g_SimdPublicMemCopyBound(aSrc, aDst, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemCopy(aSrc, aDst, aLen);
  end;
end;

procedure PublicAbiMemSet(aDst: Pointer; aLen: SizeUInt; aValue: Byte); cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicMemSetBound) then
    g_SimdPublicMemSetBound(aDst, aLen, aValue)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemSet(aDst, aLen, aValue);
  end;
end;

procedure PublicAbiToLowerAscii(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicToLowerAsciiBound) then
    g_SimdPublicToLowerAsciiBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.ToLowerAscii(aP, aLen);
  end;
end;

procedure PublicAbiToUpperAscii(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicToUpperAsciiBound) then
    g_SimdPublicToUpperAsciiBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.ToUpperAscii(aP, aLen);
  end;
end;

procedure PublicAbiMemReverse(aP: Pointer; aLen: SizeUInt); cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicMemReverseBound) then
    g_SimdPublicMemReverseBound(aP, aLen)
  else
  begin
    LDispatch := GetDispatchTable;
    LDispatch^.MemReverse(aP, aLen);
  end;
end;

procedure PublicAbiMinMaxBytes(aP: Pointer; aLen: SizeUInt; out aMinVal, aMaxVal: Byte); cdecl;
var
  LDispatch: PSimdDispatchTable;
begin
  if Assigned(g_SimdPublicMinMaxBytesBound) then
    g_SimdPublicMinMaxBytesBound(aP, aLen, aMinVal, aMaxVal)
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
  if (g_SimdBackendNameCache[aBackend] <> '') and (g_SimdBackendDescriptionCache[aBackend] <> '') then
    Exit;

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
begin
  LDispatch := GetDispatchTable;
  if LDispatch = nil then
    Exit;

  FillChar(g_SimdPublicApi, SizeOf(g_SimdPublicApi), 0);
  g_SimdPublicApi.StructSize := SizeOf(g_SimdPublicApi);
  g_SimdPublicApi.AbiVersionMajor := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MAJOR;
  g_SimdPublicApi.AbiVersionMinor := FAFAFA_SIMD_PUBLIC_ABI_VERSION_MINOR;
  g_SimdPublicApi.AbiSignatureHi := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_HI;
  g_SimdPublicApi.AbiSignatureLo := FAFAFA_SIMD_PUBLIC_ABI_SIGNATURE_LO;
  g_SimdPublicApi.ActiveBackendId := UInt32(Ord(LDispatch^.Backend));
  g_SimdPublicApi.ActiveFlags := SimdBackendToAbiFlags(LDispatch^.Backend);
  g_SimdPublicMemEqualBound := LDispatch^.MemEqual;
  g_SimdPublicMemFindByteBound := LDispatch^.MemFindByte;
  g_SimdPublicMemDiffRangeBound := LDispatch^.MemDiffRange;
  g_SimdPublicSumBytesBound := LDispatch^.SumBytes;
  g_SimdPublicCountByteBound := LDispatch^.CountByte;
  g_SimdPublicBitsetPopCountBound := LDispatch^.BitsetPopCount;
  g_SimdPublicUtf8ValidateBound := LDispatch^.Utf8Validate;
  g_SimdPublicAsciiIEqualBound := LDispatch^.AsciiIEqual;
  g_SimdPublicBytesIndexOfBound := LDispatch^.BytesIndexOf;
  g_SimdPublicMemCopyBound := LDispatch^.MemCopy;
  g_SimdPublicMemSetBound := LDispatch^.MemSet;
  g_SimdPublicToLowerAsciiBound := LDispatch^.ToLowerAscii;
  g_SimdPublicToUpperAsciiBound := LDispatch^.ToUpperAscii;
  g_SimdPublicMemReverseBound := LDispatch^.MemReverse;
  g_SimdPublicMinMaxBytesBound := LDispatch^.MinMaxBytes;
  g_SimdPublicApi.MemEqual := @PublicAbiMemEqual;
  g_SimdPublicApi.MemFindByte := @PublicAbiMemFindByte;
  g_SimdPublicApi.MemDiffRange := @PublicAbiMemDiffRange;
  g_SimdPublicApi.SumBytes := @PublicAbiSumBytes;
  g_SimdPublicApi.CountByte := @PublicAbiCountByte;
  g_SimdPublicApi.BitsetPopCount := @PublicAbiBitsetPopCount;
  g_SimdPublicApi.Utf8Validate := @PublicAbiUtf8Validate;
  g_SimdPublicApi.AsciiIEqual := @PublicAbiAsciiIEqual;
  g_SimdPublicApi.BytesIndexOf := @PublicAbiBytesIndexOf;
  g_SimdPublicApi.MemCopy := @PublicAbiMemCopy;
  g_SimdPublicApi.MemSet := @PublicAbiMemSet;
  g_SimdPublicApi.ToLowerAscii := @PublicAbiToLowerAscii;
  g_SimdPublicApi.ToUpperAscii := @PublicAbiToUpperAscii;
  g_SimdPublicApi.MemReverse := @PublicAbiMemReverse;
  g_SimdPublicApi.MinMaxBytes := @PublicAbiMinMaxBytes;
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
  LInfo: TSimdBackendInfo;
begin
  LInfo := GetBackendInfo(aBackend);
  aInfo := Default(TFafafaSimdBackendPodInfo);
  aInfo.StructSize := SizeOf(aInfo);
  aInfo.BackendId := UInt32(Ord(aBackend));
  aInfo.CapabilityBits := SimdCapabilitiesToAbiBits(LInfo.Capabilities);
  aInfo.Flags := SimdBackendToAbiFlags(aBackend);
  aInfo.Priority := LInfo.Priority;
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
begin
  Result := @g_SimdPublicApi;
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

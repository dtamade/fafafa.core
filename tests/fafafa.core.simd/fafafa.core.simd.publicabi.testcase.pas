unit fafafa.core.simd.publicabi.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.api;

type
  TTestCase_PublicAbi = class(TTestCase)
  published
    procedure Test_PublicApi_Table_IsBound_And_Metadata_IsPresent;
    procedure Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind;
    procedure Test_PublicApi_Table_Refreshes_AfterBackendSwitch;
    procedure Test_PublicApi_BackendPodInfo_Flags_AreSelfConsistent;
    procedure Test_PublicAbi_BackendText_Getters_Refresh_After_RegisterBackend;
    procedure Test_PublicAbi_BackendText_Getters_PreviousPointers_RemainValid_After_Refresh;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_DoNotUnderclaim_Shuffle;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_X86Shuffle_WhenVectorAsmDisabled;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX512FMA_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX512Shuffle_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_AVX512VectorAsmGatedBits_WhenVectorAsmDisabled;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_NEONShuffle_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_NEONIntegerOps_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_NEONFMA_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_NEONVectorAsmGatedBits_WhenVectorAsmDisabled;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVIntegerOps_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVFMA_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVShuffle_WhenNativeSlotsPresent;
    procedure Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_RISCVVVectorAsmGatedBits_WhenVectorAsmDisabled;
    procedure Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable;
    procedure Test_PublicApi_ActiveBackendId_Tracks_RegisterSlot_After_ReRegister;
    procedure Test_PublicApi_ActiveBackendId_Tracks_FinalState_When_HookReRegister_Overrides_ForcedSelection;
    procedure Test_PublicApi_Refreshes_WhenVectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend;
    procedure Test_PublicApi_DataPlane_Parity;
  end;

implementation

var
  GPublicAbiHookDisableBackendEnabled: Boolean = False;
  GPublicAbiHookDisableBackendArmed: Boolean = False;
  GPublicAbiHookDisableBackendDone: Boolean = False;
  GPublicAbiHookDisableBackendTarget: TSimdBackend = sbScalar;
  GPublicAbiHookDisableBackendOriginalTable: TSimdDispatchTable;

procedure PublicAbiHookDisableBackendOnce;
var
  LModifiedTable: TSimdDispatchTable;
begin
  if not GPublicAbiHookDisableBackendEnabled then
    Exit;

  if not GPublicAbiHookDisableBackendArmed then
  begin
    GPublicAbiHookDisableBackendArmed := True;
    Exit;
  end;

  if GPublicAbiHookDisableBackendDone then
    Exit;

  GPublicAbiHookDisableBackendDone := True;
  LModifiedTable := GPublicAbiHookDisableBackendOriginalTable;
  LModifiedTable.BackendInfo.Available := False;
  RegisterBackend(GPublicAbiHookDisableBackendTarget, LModifiedTable);
end;

function RestoreOriginalActiveBackend(aOriginalBackend: TSimdBackend): Boolean;
begin
  ResetToAutomaticBackend;
  if GetCurrentBackend = aOriginalBackend then
    Exit(True);

  Result := TrySetActiveBackend(aOriginalBackend);
end;

procedure TTestCase_PublicAbi.Test_PublicApi_Table_IsBound_And_Metadata_IsPresent;
var
  LApi: PFafafaSimdPublicApi;
begin
  LApi := GetSimdPublicApi;
  AssertNotNull('Public API table should not be nil', LApi);
  AssertEquals('StructSize should match record size',
    SizeOf(TFafafaSimdPublicApi), LApi^.StructSize);
  AssertEquals('ABI major should match getter',
    GetSimdAbiVersionMajor, LApi^.AbiVersionMajor);
  AssertEquals('ABI minor should match getter',
    GetSimdAbiVersionMinor, LApi^.AbiVersionMinor);
  AssertTrue('ABI signature hi should be non-zero', LApi^.AbiSignatureHi <> 0);
  AssertTrue('ABI signature lo should be non-zero', LApi^.AbiSignatureLo <> 0);
  AssertEquals('Active backend id should match current backend',
    Ord(GetCurrentBackend), Integer(LApi^.ActiveBackendId));
  AssertTrue('MemEqual function pointer should be bound', Assigned(LApi^.MemEqual));
  AssertTrue('MemFindByte function pointer should be bound', Assigned(LApi^.MemFindByte));
  AssertTrue('MemDiffRange function pointer should be bound', Assigned(LApi^.MemDiffRange));
  AssertTrue('SumBytes function pointer should be bound', Assigned(LApi^.SumBytes));
  AssertTrue('CountByte function pointer should be bound', Assigned(LApi^.CountByte));
  AssertTrue('BitsetPopCount function pointer should be bound', Assigned(LApi^.BitsetPopCount));
  AssertTrue('Utf8Validate function pointer should be bound', Assigned(LApi^.Utf8Validate));
  AssertTrue('AsciiIEqual function pointer should be bound', Assigned(LApi^.AsciiIEqual));
  AssertTrue('BytesIndexOf function pointer should be bound', Assigned(LApi^.BytesIndexOf));
  AssertTrue('MemCopy function pointer should be bound', Assigned(LApi^.MemCopy));
  AssertTrue('MemSet function pointer should be bound', Assigned(LApi^.MemSet));
  AssertTrue('ToLowerAscii function pointer should be bound', Assigned(LApi^.ToLowerAscii));
  AssertTrue('ToUpperAscii function pointer should be bound', Assigned(LApi^.ToUpperAscii));
  AssertTrue('MemReverse function pointer should be bound', Assigned(LApi^.MemReverse));
  AssertTrue('MinMaxBytes function pointer should be bound', Assigned(LApi^.MinMaxBytes));
end;

procedure TTestCase_PublicAbi.Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind;
var
  LApiBefore: PFafafaSimdPublicApi;
  LApiAfter: PFafafaSimdPublicApi;
  LOriginalBackend: TSimdBackend;
  LBufferA: array[0..31] of Byte;
  LBufferB: array[0..31] of Byte;
begin
  LApiBefore := GetSimdPublicApi;
  AssertNotNull('Public API table should not be nil before rebind', LApiBefore);
  LOriginalBackend := GetCurrentBackend;
  FillChar(LBufferA, SizeOf(LBufferA), $42);
  FillChar(LBufferB, SizeOf(LBufferB), $42);

  try
    AssertTrue('TrySetActiveBackend(sbScalar) should succeed', TrySetActiveBackend(sbScalar));
    LApiAfter := GetSimdPublicApi;
    AssertNotNull('Public API table should not be nil after rebind', LApiAfter);
    AssertEquals('Fresh getter should expose refreshed active backend metadata after rebind',
      Ord(sbScalar), Integer(LApiAfter^.ActiveBackendId));
    AssertTrue('Cached pre-rebind MemEqual pointer should remain callable after rebind',
      Assigned(LApiBefore^.MemEqual) and
      LApiBefore^.MemEqual(@LBufferA[0], @LBufferB[0], SizeUInt(Length(LBufferA))));
  finally
    if GetCurrentBackend <> LOriginalBackend then
      AssertTrue('Restoring original active backend should succeed',
        RestoreOriginalActiveBackend(LOriginalBackend));
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_Table_Refreshes_AfterBackendSwitch;
var
  LApi: PFafafaSimdPublicApi;
  LOriginalBackend: TSimdBackend;
  LOriginalDispatchable: TSimdBackend;
  LDispatchable: TSimdBackendArray;
  LTargetBackend: TSimdBackend;
  LFoundDifferent: Boolean;
  LIndex: Integer;
begin
  LApi := GetSimdPublicApi;
  AssertNotNull('Public API table should not be nil', LApi);
  LOriginalBackend := GetCurrentBackend;
  LOriginalDispatchable := GetBestDispatchableBackend;

  LDispatchable := GetDispatchableBackendList;
  LTargetBackend := LOriginalBackend;
  LFoundDifferent := False;
  for LIndex := 0 to High(LDispatchable) do
    if LDispatchable[LIndex] <> LOriginalBackend then
    begin
      LTargetBackend := LDispatchable[LIndex];
      LFoundDifferent := True;
      Break;
    end;

  try
    AssertTrue('TrySetActiveBackend(sbScalar) should succeed', TrySetActiveBackend(sbScalar));
    AssertEquals('Public API active backend should refresh to Scalar',
      Ord(sbScalar), Integer(GetSimdPublicApi^.ActiveBackendId));

    if LFoundDifferent then
    begin
      AssertTrue('TrySetActiveBackend(target) should succeed', TrySetActiveBackend(LTargetBackend));
      AssertEquals('Public API active backend should refresh to target backend',
        Ord(LTargetBackend), Integer(GetSimdPublicApi^.ActiveBackendId));
    end;

    ResetToAutomaticBackend;
    AssertEquals('Public API active backend should refresh after reset-to-auto',
      Ord(GetCurrentBackend), Integer(GetSimdPublicApi^.ActiveBackendId));
    AssertEquals('ResetToAutomaticBackend should restore best dispatchable backend',
      Ord(LOriginalDispatchable), Ord(GetCurrentBackend));
  finally
    if GetCurrentBackend <> LOriginalBackend then
      AssertTrue('Restoring original active backend should succeed',
        RestoreOriginalActiveBackend(LOriginalBackend));
  end;

  AssertEquals('Public API active backend should track the restored backend',
    Ord(GetCurrentBackend), Integer(GetSimdPublicApi^.ActiveBackendId));
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_Flags_AreSelfConsistent;
var
  LBackend: TSimdBackend;
  LInfo: TFafafaSimdBackendPodInfo;
  LNamePtr: PAnsiChar;
begin
  for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
  begin
    AssertTrue('TryGetSimdBackendPodInfo should succeed for backend=' + IntToStr(Ord(LBackend)),
      TryGetSimdBackendPodInfo(LBackend, LInfo));
    AssertEquals('StructSize mismatch for backend=' + IntToStr(Ord(LBackend)),
      SizeOf(TFafafaSimdBackendPodInfo), LInfo.StructSize);
    AssertEquals('BackendId mismatch for backend=' + IntToStr(Ord(LBackend)),
      Ord(LBackend), Integer(LInfo.BackendId));

    if IsBackendAvailableOnCPU(LBackend) then
      AssertTrue('supported_on_cpu flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) <> 0)
    else
      AssertTrue('supported_on_cpu flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) = 0);

    if IsBackendRegisteredInBinary(LBackend) then
      AssertTrue('registered flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_REGISTERED) <> 0)
    else
      AssertTrue('registered flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_REGISTERED) = 0);

    if IsBackendDispatchable(LBackend) then
      AssertTrue('dispatchable flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) <> 0)
    else
      AssertTrue('dispatchable flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) = 0);

    if GetCurrentBackend = LBackend then
      AssertTrue('active flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_ACTIVE) <> 0)
    else
      AssertTrue('active flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_ACTIVE) = 0);

    if LBackend = sbRISCVV then
      AssertTrue('experimental flag missing for RISCVV',
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_EXPERIMENTAL) <> 0);

    LNamePtr := GetSimdBackendNamePtr(LBackend);
    AssertNotNull('Backend name pointer should not be nil for backend=' + IntToStr(Ord(LBackend)), Pointer(LNamePtr));
    AssertTrue('Backend name should not be empty for backend=' + IntToStr(Ord(LBackend)), LNamePtr^ <> #0);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicAbi_BackendText_Getters_Refresh_After_RegisterBackend;
var
  LBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LModifiedTable: TSimdDispatchTable;
  LBackendInfo: TSimdBackendInfo;
  LNamePtr: PAnsiChar;
  LDescriptionPtr: PAnsiChar;
begin
  LBackend := GetCurrentBackend;
  AssertTrue('Backend should be registered before dynamic text refresh test',
    TryGetRegisteredBackendDispatchTable(LBackend, LOriginalTable));

  // Prime the consumer-facing text cache before mutating the backend table.
  LNamePtr := GetSimdBackendNamePtr(LBackend);
  LDescriptionPtr := GetSimdBackendDescriptionPtr(LBackend);
  AssertNotNull('Original backend name pointer should not be nil', Pointer(LNamePtr));
  AssertNotNull('Original backend description pointer should not be nil', Pointer(LDescriptionPtr));

  LModifiedTable := LOriginalTable;
  LModifiedTable.BackendInfo.Name := 'MutatedBackendName';
  LModifiedTable.BackendInfo.Description := 'Mutated backend description for public ABI refresh';
  RegisterBackend(LBackend, LModifiedTable);
  try
    LBackendInfo := GetBackendInfo(LBackend);
    AssertEquals('Dispatch metadata should reflect the updated backend name',
      'MutatedBackendName', LBackendInfo.Name);
    AssertEquals('Dispatch metadata should reflect the updated backend description',
      'Mutated backend description for public ABI refresh', LBackendInfo.Description);

    LNamePtr := GetSimdBackendNamePtr(LBackend);
    LDescriptionPtr := GetSimdBackendDescriptionPtr(LBackend);
    AssertNotNull('Updated backend name pointer should not be nil', Pointer(LNamePtr));
    AssertNotNull('Updated backend description pointer should not be nil', Pointer(LDescriptionPtr));
    AssertEquals('Public ABI backend name getter should refresh after RegisterBackend',
      'MutatedBackendName', string(StrPas(LNamePtr)));
    AssertEquals('Public ABI backend description getter should refresh after RegisterBackend',
      'Mutated backend description for public ABI refresh', string(StrPas(LDescriptionPtr)));
  finally
    RegisterBackend(LBackend, LOriginalTable);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicAbi_BackendText_Getters_PreviousPointers_RemainValid_After_Refresh;
const
  TEXT_LEN = 1024;
  CHURN_COUNT = 2048;
var
  LBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LFirstTable: TSimdDispatchTable;
  LSecondTable: TSimdDispatchTable;
  LNameBefore: AnsiString;
  LDescriptionBefore: AnsiString;
  LNameAfter: AnsiString;
  LDescriptionAfter: AnsiString;
  LNamePtrBefore: PAnsiChar;
  LDescriptionPtrBefore: PAnsiChar;
  LNamePtrAfter: PAnsiChar;
  LDescriptionPtrAfter: PAnsiChar;
  LChurn: array of AnsiString;
  LIndex: Integer;
begin
  LBackend := GetCurrentBackend;
  AssertTrue('Backend should be registered before backend text pointer lifetime test',
    TryGetRegisteredBackendDispatchTable(LBackend, LOriginalTable));

  LNameBefore := 'PointerLifetimeNameA_' + StringOfChar('A', TEXT_LEN);
  LDescriptionBefore := 'PointerLifetimeDescriptionA_' + StringOfChar('a', TEXT_LEN);
  LNameAfter := 'PointerLifetimeNameB_' + StringOfChar('B', TEXT_LEN);
  LDescriptionAfter := 'PointerLifetimeDescriptionB_' + StringOfChar('b', TEXT_LEN);
  try
    LFirstTable := LOriginalTable;
    LFirstTable.BackendInfo.Name := string(LNameBefore);
    LFirstTable.BackendInfo.Description := string(LDescriptionBefore);
    RegisterBackend(LBackend, LFirstTable);

    LNamePtrBefore := GetSimdBackendNamePtr(LBackend);
    LDescriptionPtrBefore := GetSimdBackendDescriptionPtr(LBackend);
    AssertNotNull('Original backend name pointer should not be nil in pointer lifetime test',
      Pointer(LNamePtrBefore));
    AssertNotNull('Original backend description pointer should not be nil in pointer lifetime test',
      Pointer(LDescriptionPtrBefore));
    AssertEquals('Original backend name should match seeded text in pointer lifetime test',
      string(LNameBefore), string(StrPas(LNamePtrBefore)));
    AssertEquals('Original backend description should match seeded text in pointer lifetime test',
      string(LDescriptionBefore), string(StrPas(LDescriptionPtrBefore)));

    LSecondTable := LOriginalTable;
    LSecondTable.BackendInfo.Name := string(LNameAfter);
    LSecondTable.BackendInfo.Description := string(LDescriptionAfter);
    RegisterBackend(LBackend, LSecondTable);

    LNamePtrAfter := GetSimdBackendNamePtr(LBackend);
    LDescriptionPtrAfter := GetSimdBackendDescriptionPtr(LBackend);
    AssertNotNull('Refreshed backend name pointer should not be nil in pointer lifetime test',
      Pointer(LNamePtrAfter));
    AssertNotNull('Refreshed backend description pointer should not be nil in pointer lifetime test',
      Pointer(LDescriptionPtrAfter));
    AssertEquals('Refreshed backend name should match updated text in pointer lifetime test',
      string(LNameAfter), string(StrPas(LNamePtrAfter)));
    AssertEquals('Refreshed backend description should match updated text in pointer lifetime test',
      string(LDescriptionAfter), string(StrPas(LDescriptionPtrAfter)));

    SetLength(LChurn, CHURN_COUNT);
    for LIndex := 0 to High(LChurn) do
      LChurn[LIndex] := IntToStr(LIndex) + StringOfChar(Chr(Ord('C') + (LIndex mod 3)), TEXT_LEN);

    AssertEquals('Previously returned backend name pointer should remain process-lifetime valid after refresh',
      string(LNameBefore), string(StrPas(LNamePtrBefore)));
    AssertEquals('Previously returned backend description pointer should remain process-lifetime valid after refresh',
      string(LDescriptionBefore), string(StrPas(LDescriptionPtrBefore)));
  finally
    RegisterBackend(LBackend, LOriginalTable);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_DoNotUnderclaim_Shuffle;
var
  LBackend: TSimdBackend;
  LScalarTable: TSimdDispatchTable;
  LBackendTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LHasNonScalarShuffleSlots: Boolean;
  LOldVectorAsm: Boolean;

  procedure ObserveRepresentativeSlot(aScalarSlot, aBackendSlot: Pointer);
  begin
    if aBackendSlot <> aScalarSlot then
      LHasNonScalarShuffleSlots := True;
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    if not IsVectorAsmEnabled then
      Exit;

    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if LBackend = sbScalar then
        Continue;
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TryGetSimdBackendPodInfo(LBackend, LInfo) then
        Continue;

      LHasNonScalarShuffleSlots := False;
      ObserveRepresentativeSlot(Pointer(LScalarTable.SelectF32x4), Pointer(LBackendTable.SelectF32x4));
      ObserveRepresentativeSlot(Pointer(LScalarTable.InsertF32x4), Pointer(LBackendTable.InsertF32x4));
      ObserveRepresentativeSlot(Pointer(LScalarTable.ExtractF32x4), Pointer(LBackendTable.ExtractF32x4));
      ObserveRepresentativeSlot(Pointer(LScalarTable.SelectF32x8), Pointer(LBackendTable.SelectF32x8));
      ObserveRepresentativeSlot(Pointer(LScalarTable.SelectF64x4), Pointer(LBackendTable.SelectF64x4));

      if not LHasNonScalarShuffleSlots then
        Continue;

      AssertTrue('Public ABI CapabilityBits missing scShuffle while representative shuffle slots are non-scalar for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) <> 0);
    end;
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_WhenNativeSlotsPresent;
var
  LScalarTable: TSimdDispatchTable;
  LAVX2Table: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    if not IsVectorAsmEnabled then
      Exit;
    if not TryGetRegisteredBackendDispatchTable(sbAVX2, LAVX2Table) then
      Exit;
    if not TryGetSimdBackendPodInfo(sbAVX2, LInfo) then
      Exit;

    if (Pointer(LAVX2Table.SelectF32x4) = Pointer(LScalarTable.SelectF32x4)) and
       (Pointer(LAVX2Table.InsertF32x4) = Pointer(LScalarTable.InsertF32x4)) and
       (Pointer(LAVX2Table.ExtractF32x4) = Pointer(LScalarTable.ExtractF32x4)) and
       (Pointer(LAVX2Table.SelectF32x8) = Pointer(LScalarTable.SelectF32x8)) and
       (Pointer(LAVX2Table.SelectF64x4) = Pointer(LScalarTable.SelectF64x4)) then
      Exit;

    AssertTrue('Public ABI CapabilityBits should expose AVX2 scShuffle when representative shuffle slots are non-scalar',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) <> 0);
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_X86Shuffle_WhenVectorAsmDisabled;
var
  LBackend: TSimdBackend;
  LScalarTable: TSimdDispatchTable;
  LBackendTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;

  function IsShuffleCapabilityGatedBackend(const aBackend: TSimdBackend): Boolean;
  begin
    case aBackend of
      sbSSE41, sbSSE42, sbAVX2:
        Exit(True);
      else
        Exit(False);
    end;
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    SetVectorAsmEnabled(False);
    AssertFalse('Vector asm should be disabled for x86 shuffle public ABI rebuild test', IsVectorAsmEnabled);

    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsShuffleCapabilityGatedBackend(LBackend) then
        Continue;
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TryGetSimdBackendPodInfo(LBackend, LInfo) then
        Continue;

      AssertEquals('Representative SelectF32x4 slot should be scalar when vector asm is disabled for backend=' + IntToStr(Ord(LBackend)),
        PtrUInt(LScalarTable.SelectF32x4), PtrUInt(LBackendTable.SelectF32x4));
      AssertEquals('Representative InsertF32x4 slot should be scalar when vector asm is disabled for backend=' + IntToStr(Ord(LBackend)),
        PtrUInt(LScalarTable.InsertF32x4), PtrUInt(LBackendTable.InsertF32x4));
      AssertEquals('Representative ExtractF32x4 slot should be scalar when vector asm is disabled for backend=' + IntToStr(Ord(LBackend)),
        PtrUInt(LScalarTable.ExtractF32x4), PtrUInt(LBackendTable.ExtractF32x4));

      AssertTrue('Public ABI CapabilityBits should clear scShuffle when representative shuffle slots are scalar for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) = 0);
    end;
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX512FMA_WhenNativeSlotsPresent;
var
  LScalarTable: TSimdDispatchTable;
  LAVX512Table: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    if not IsVectorAsmEnabled then
      Exit;
    if not TryGetRegisteredBackendDispatchTable(sbAVX512, LAVX512Table) then
      Exit;
    if not TryGetSimdBackendPodInfo(sbAVX512, LInfo) then
      Exit;

    AssertTrue('AVX512 FmaF32x16 should be assigned', Assigned(LAVX512Table.FmaF32x16));
    AssertTrue('AVX512 FmaF64x8 should be assigned', Assigned(LAVX512Table.FmaF64x8));

    if (Pointer(LAVX512Table.FmaF32x16) = Pointer(LScalarTable.FmaF32x16)) and
       (Pointer(LAVX512Table.FmaF64x8) = Pointer(LScalarTable.FmaF64x8)) then
      Exit;

    AssertTrue('Public ABI CapabilityBits should expose AVX512 scFMA when wide FMA slots are non-scalar',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) <> 0);
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX512Shuffle_WhenNativeSlotsPresent;
var
  LScalarTable: TSimdDispatchTable;
  LAVX512Table: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    if not IsVectorAsmEnabled then
      Exit;
    if not TryGetRegisteredBackendDispatchTable(sbAVX512, LAVX512Table) then
      Exit;
    if not TryGetSimdBackendPodInfo(sbAVX512, LInfo) then
      Exit;

    if (Pointer(LAVX512Table.SelectF32x16) = Pointer(LScalarTable.SelectF32x16)) and
       (Pointer(LAVX512Table.SelectF64x8) = Pointer(LScalarTable.SelectF64x8)) then
      Exit;

    AssertTrue('Public ABI CapabilityBits should expose AVX512 scShuffle when wide select slots are non-scalar',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) <> 0);
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_AVX512VectorAsmGatedBits_WhenVectorAsmDisabled;
var
  LAVX512Table: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;
begin
  if not TryGetRegisteredBackendDispatchTable(sbAVX512, LAVX512Table) then
    Exit;

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    if not IsVectorAsmEnabled then
      Exit;
    SetVectorAsmEnabled(False);
    AssertFalse('Vector asm should be disabled for AVX512 public ABI rebuild test', IsVectorAsmEnabled);
    AssertTrue('AVX512 backend should remain registered after runtime rebuild',
      TryGetRegisteredBackendDispatchTable(sbAVX512, LAVX512Table));
    AssertTrue('AVX512 backend pod info should remain queryable after runtime rebuild',
      TryGetSimdBackendPodInfo(sbAVX512, LInfo));

    AssertTrue('Public ABI CapabilityBits should clear AVX512 scFMA when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear AVX512 scShuffle when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear AVX512 scIntegerOps when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scIntegerOps))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear AVX512 scMaskedOps when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scMaskedOps))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear AVX512 sc512BitOps when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(sc512BitOps))) = 0);
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_NEONShuffle_WhenNativeSlotsPresent;
var
  LScalarTable: TSimdDispatchTable;
  LNEONTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND}
  AssertTrue('NEON opt-in test registration should be present',
    TryGetRegisteredBackendDispatchTable(sbNEON, LNEONTable));
  AssertTrue('NEON opt-in public ABI pod info should be present',
    TryGetSimdBackendPodInfo(sbNEON, LInfo));
  {$ELSE}
  if not TryGetRegisteredBackendDispatchTable(sbNEON, LNEONTable) then
    Exit;
  if not TryGetSimdBackendPodInfo(sbNEON, LInfo) then
    Exit;
  {$ENDIF}

  if (Pointer(LNEONTable.SelectF32x4) = Pointer(LScalarTable.SelectF32x4)) and
     (Pointer(LNEONTable.InsertF32x4) = Pointer(LScalarTable.InsertF32x4)) and
     (Pointer(LNEONTable.ExtractF32x4) = Pointer(LScalarTable.ExtractF32x4)) and
     (Pointer(LNEONTable.SelectF32x8) = Pointer(LScalarTable.SelectF32x8)) and
     (Pointer(LNEONTable.SelectF64x4) = Pointer(LScalarTable.SelectF64x4)) then
    Exit;

  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  AssertTrue('Public ABI CapabilityBits should expose NEON scShuffle when NEON asm-backed representative shuffle slots are non-scalar',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) <> 0);
  {$ELSE}
  AssertTrue('Public ABI CapabilityBits should clear NEON scShuffle when only scalar fallback shuffle slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) = 0);
  {$ENDIF}
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_NEONFMA_WhenNativeSlotsPresent;
var
  LNEONTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
begin
  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND}
  AssertTrue('NEON opt-in test registration should be present',
    TryGetRegisteredBackendDispatchTable(sbNEON, LNEONTable));
  AssertTrue('NEON opt-in public ABI pod info should be present',
    TryGetSimdBackendPodInfo(sbNEON, LInfo));
  {$ELSE}
  if not TryGetRegisteredBackendDispatchTable(sbNEON, LNEONTable) then
    Exit;
  if not TryGetSimdBackendPodInfo(sbNEON, LInfo) then
    Exit;
  {$ENDIF}

  AssertTrue('NEON FmaF32x4 should be assigned', Assigned(LNEONTable.FmaF32x4));
  AssertTrue('NEON FmaF32x8 should be assigned', Assigned(LNEONTable.FmaF32x8));
  AssertTrue('NEON FmaF64x2 should be assigned', Assigned(LNEONTable.FmaF64x2));
  AssertTrue('NEON FmaF64x4 should be assigned', Assigned(LNEONTable.FmaF64x4));

  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  AssertTrue('Public ABI CapabilityBits should expose NEON scFMA when NEON asm-backed FMA slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) <> 0);
  {$ELSE}
  AssertTrue('Public ABI CapabilityBits should clear NEON scFMA when only scalar/common fallback FMA slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) = 0);
  {$ENDIF}
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_NEONIntegerOps_WhenNativeSlotsPresent;
var
  LNEONTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
begin
  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND}
  AssertTrue('NEON opt-in test registration should be present',
    TryGetRegisteredBackendDispatchTable(sbNEON, LNEONTable));
  AssertTrue('NEON opt-in public ABI pod info should be present',
    TryGetSimdBackendPodInfo(sbNEON, LInfo));
  {$ELSE}
  if not TryGetRegisteredBackendDispatchTable(sbNEON, LNEONTable) then
    Exit;
  if not TryGetSimdBackendPodInfo(sbNEON, LInfo) then
    Exit;
  {$ENDIF}

  AssertTrue('NEON AddI32x4 should be assigned', Assigned(LNEONTable.AddI32x4));
  AssertTrue('NEON AndI32x4 should be assigned', Assigned(LNEONTable.AndI32x4));
  AssertTrue('NEON AddI16x8 should be assigned', Assigned(LNEONTable.AddI16x8));

  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  AssertTrue('Public ABI CapabilityBits should expose NEON scIntegerOps when NEON asm-backed integer slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scIntegerOps))) <> 0);
  {$ELSE}
  AssertTrue('Public ABI CapabilityBits should clear NEON scIntegerOps when only scalar/common fallback integer slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scIntegerOps))) = 0);
  {$ENDIF}
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_NEONVectorAsmGatedBits_WhenVectorAsmDisabled;
var
  LNEONTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;
begin
  {$IFNDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Exit;
  {$ENDIF}

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    SetVectorAsmEnabled(False);
    AssertFalse('Vector asm should be disabled for NEON public ABI rebuild test', IsVectorAsmEnabled);
    AssertTrue('NEON backend should remain registered after runtime rebuild',
      TryGetRegisteredBackendDispatchTable(sbNEON, LNEONTable));
    AssertTrue('NEON backend pod info should remain queryable after runtime rebuild',
      TryGetSimdBackendPodInfo(sbNEON, LInfo));

    AssertTrue('Public ABI CapabilityBits should clear NEON scFMA when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear NEON scIntegerOps when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scIntegerOps))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear NEON scShuffle when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) = 0);
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVIntegerOps_WhenNativeSlotsPresent;
var
  LRISCVVTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
begin
  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND}
  AssertTrue('RISCVV opt-in test registration should be present',
    TryGetRegisteredBackendDispatchTable(sbRISCVV, LRISCVVTable));
  AssertTrue('RISCVV opt-in public ABI pod info should be present',
    TryGetSimdBackendPodInfo(sbRISCVV, LInfo));
  {$ELSE}
  if not TryGetRegisteredBackendDispatchTable(sbRISCVV, LRISCVVTable) then
    Exit;
  if not TryGetSimdBackendPodInfo(sbRISCVV, LInfo) then
    Exit;
  {$ENDIF}

  AssertTrue('RISCVV AddI32x4 should be assigned', Assigned(LRISCVVTable.AddI32x4));
  AssertTrue('RISCVV AndI32x4 should be assigned', Assigned(LRISCVVTable.AndI32x4));
  AssertTrue('RISCVV AddI64x2 should be assigned', Assigned(LRISCVVTable.AddI64x2));

  {$IFDEF RISCVV_ASSEMBLY}
  AssertTrue('Public ABI CapabilityBits should expose RISCVV scIntegerOps when RVV asm-backed integer slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scIntegerOps))) <> 0);
  {$ELSE}
  AssertTrue('Public ABI CapabilityBits should clear RISCVV scIntegerOps when only scalar/common fallback integer slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scIntegerOps))) = 0);
  {$ENDIF}
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVFMA_WhenNativeSlotsPresent;
var
  LScalarTable: TSimdDispatchTable;
  LRISCVVTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND}
  AssertTrue('RISCVV opt-in test registration should be present',
    TryGetRegisteredBackendDispatchTable(sbRISCVV, LRISCVVTable));
  AssertTrue('RISCVV opt-in public ABI pod info should be present',
    TryGetSimdBackendPodInfo(sbRISCVV, LInfo));
  {$ELSE}
  if not TryGetRegisteredBackendDispatchTable(sbRISCVV, LRISCVVTable) then
    Exit;
  if not TryGetSimdBackendPodInfo(sbRISCVV, LInfo) then
    Exit;
  {$ENDIF}

  if (Pointer(LRISCVVTable.FmaF32x4) = Pointer(LScalarTable.FmaF32x4)) and
     (Pointer(LRISCVVTable.FmaF32x8) = Pointer(LScalarTable.FmaF32x8)) and
     (Pointer(LRISCVVTable.FmaF64x2) = Pointer(LScalarTable.FmaF64x2)) and
     (Pointer(LRISCVVTable.FmaF64x4) = Pointer(LScalarTable.FmaF64x4)) and
     (Pointer(LRISCVVTable.FmaF32x16) = Pointer(LScalarTable.FmaF32x16)) and
     (Pointer(LRISCVVTable.FmaF64x8) = Pointer(LScalarTable.FmaF64x8)) then
    Exit;

  {$IFDEF RISCVV_ASSEMBLY}
  AssertTrue('Public ABI CapabilityBits should expose RISCVV scFMA when RVV asm-backed representative FMA slots are non-scalar',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) <> 0);
  {$ELSE}
  AssertTrue('Public ABI CapabilityBits should clear RISCVV scFMA when only scalar fallback FMA slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) = 0);
  {$ENDIF}
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVShuffle_WhenNativeSlotsPresent;
var
  LRISCVVTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
begin
  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND}
  AssertTrue('RISCVV opt-in test registration should be present',
    TryGetRegisteredBackendDispatchTable(sbRISCVV, LRISCVVTable));
  AssertTrue('RISCVV opt-in public ABI pod info should be present',
    TryGetSimdBackendPodInfo(sbRISCVV, LInfo));
  {$ELSE}
  if not TryGetRegisteredBackendDispatchTable(sbRISCVV, LRISCVVTable) then
    Exit;
  if not TryGetSimdBackendPodInfo(sbRISCVV, LInfo) then
    Exit;
  {$ENDIF}

  AssertTrue('RISCVV SelectF32x4 should be assigned', Assigned(LRISCVVTable.SelectF32x4));
  AssertTrue('RISCVV InsertF32x4 should be assigned', Assigned(LRISCVVTable.InsertF32x4));
  AssertTrue('RISCVV ExtractF32x4 should be assigned', Assigned(LRISCVVTable.ExtractF32x4));

  {$IFDEF RISCVV_ASSEMBLY}
  AssertTrue('Public ABI CapabilityBits should expose RISCVV scShuffle when RVV asm-backed representative shuffle slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) <> 0);
  {$ELSE}
  AssertTrue('Public ABI CapabilityBits should clear RISCVV scShuffle when only scalar/common fallback shuffle slots are compiled',
    (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) = 0);
  {$ENDIF}
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_RISCVVVectorAsmGatedBits_WhenVectorAsmDisabled;
var
  LRISCVVTable: TSimdDispatchTable;
  LInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;
begin
  {$IFNDEF RISCVV_ASSEMBLY}
  Exit;
  {$ENDIF}

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    SetVectorAsmEnabled(False);
    AssertFalse('Vector asm should be disabled for RISCVV public ABI rebuild test', IsVectorAsmEnabled);
    AssertTrue('RISCVV backend should remain registered after runtime rebuild',
      TryGetRegisteredBackendDispatchTable(sbRISCVV, LRISCVVTable));
    AssertTrue('RISCVV backend pod info should remain queryable after runtime rebuild',
      TryGetSimdBackendPodInfo(sbRISCVV, LInfo));

    AssertTrue('Public ABI CapabilityBits should clear RISCVV scFMA when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scFMA))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear RISCVV scIntegerOps when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scIntegerOps))) = 0);
    AssertTrue('Public ABI CapabilityBits should clear RISCVV scShuffle when vector asm is disabled',
      (LInfo.CapabilityBits and (UInt64(1) shl Ord(scShuffle))) = 0);
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable;
var
  LApi: PFafafaSimdPublicApi;
  LOriginalBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LModifiedTable: TSimdDispatchTable;
  LOriginalInfo: TFafafaSimdBackendPodInfo;
  LUpdatedInfo: TFafafaSimdBackendPodInfo;
  LActiveInfo: TFafafaSimdBackendPodInfo;
begin
  LOriginalBackend := GetCurrentBackend;

  // If the platform only has the scalar backend dispatchable, this dynamic split
  // cannot be exercised meaningfully.
  if LOriginalBackend = sbScalar then
    Exit;

  AssertTrue('Original active backend should be registered',
    TryGetRegisteredBackendDispatchTable(LOriginalBackend, LOriginalTable));
  AssertTrue('Original active backend pod info should be queryable',
    TryGetSimdBackendPodInfo(LOriginalBackend, LOriginalInfo));
  AssertTrue('Original active backend should start as dispatchable',
    (LOriginalInfo.Flags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) <> 0);
  AssertTrue('Original active backend should start as active',
    (LOriginalInfo.Flags and FAF_SIMD_ABI_FLAG_ACTIVE) <> 0);

  LModifiedTable := LOriginalTable;
  LModifiedTable.BackendInfo.Available := False;
  RegisterBackend(LOriginalBackend, LModifiedTable);
  try
    LApi := GetSimdPublicApi;
    AssertNotNull('Public API table should not be nil after backend re-registration', LApi);
    AssertEquals('Public API active backend should track current backend after re-registration',
      Ord(GetCurrentBackend), Integer(LApi^.ActiveBackendId));
    AssertTrue('Re-selection should move away from backend marked unavailable',
      GetCurrentBackend <> LOriginalBackend);
    AssertTrue('Public API active flags should keep active bit after re-selection',
      (LApi^.ActiveFlags and FAF_SIMD_ABI_FLAG_ACTIVE) <> 0);
    AssertTrue('Public API active flags should keep dispatchable bit after re-selection',
      (LApi^.ActiveFlags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) <> 0);

    AssertTrue('Original backend pod info should remain queryable after re-registration',
      TryGetSimdBackendPodInfo(LOriginalBackend, LUpdatedInfo));
    AssertTrue('Original backend should remain CPU-supported after re-registration',
      (LUpdatedInfo.Flags and FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) <> 0);
    AssertTrue('Original backend should remain registered after re-registration',
      (LUpdatedInfo.Flags and FAF_SIMD_ABI_FLAG_REGISTERED) <> 0);
    AssertTrue('Original backend should lose dispatchable bit after re-registration',
      (LUpdatedInfo.Flags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) = 0);
    AssertTrue('Original backend should lose active bit after re-selection',
      (LUpdatedInfo.Flags and FAF_SIMD_ABI_FLAG_ACTIVE) = 0);

    AssertTrue('New active backend pod info should be queryable',
      TryGetSimdBackendPodInfo(GetCurrentBackend, LActiveInfo));
    AssertEquals('Active backend pod flags should match public api active flags after re-selection',
      LActiveInfo.Flags, LApi^.ActiveFlags);
  finally
    RegisterBackend(LOriginalBackend, LOriginalTable);
    if GetCurrentBackend <> LOriginalBackend then
      AssertTrue('Restoring original active backend should succeed',
        RestoreOriginalActiveBackend(LOriginalBackend));
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_ActiveBackendId_Tracks_RegisterSlot_After_ReRegister;
var
  LApi: PFafafaSimdPublicApi;
  LOriginalBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LModifiedTable: TSimdDispatchTable;
  LActiveInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;
begin
  try
    GetSimdPublicApi;
    LOldVectorAsm := IsVectorAsmEnabled;
    SetVectorAsmEnabled(True);
    ResetToAutomaticBackend;
    LOriginalBackend := GetCurrentBackend;
    if LOriginalBackend = sbScalar then
      Exit;

    AssertTrue('Original active backend should be registered for public ABI identity test',
      TryGetRegisteredBackendDispatchTable(LOriginalBackend, LOriginalTable));

    LModifiedTable := LOriginalTable;
    LModifiedTable.Backend := sbScalar;
    LModifiedTable.BackendInfo.Backend := sbScalar;
    RegisterBackend(LOriginalBackend, LModifiedTable);
    try
      AssertTrue('TrySetActiveBackend should succeed for the requested backend slot after re-register',
        TrySetActiveBackend(LOriginalBackend));

      LApi := GetSimdPublicApi;
      AssertNotNull('Public API table should remain available after identity-mismatch re-register', LApi);
      AssertEquals('Public API active backend id should track the registered backend slot, not the stale table Backend field',
        Ord(LOriginalBackend), Integer(LApi^.ActiveBackendId));
      AssertTrue('Backend pod info should remain queryable for the requested backend slot',
        TryGetSimdBackendPodInfo(LOriginalBackend, LActiveInfo));
      AssertEquals('Public API active flags should match the requested backend pod flags after re-register',
        LActiveInfo.Flags, LApi^.ActiveFlags);
    finally
      RegisterBackend(LOriginalBackend, LOriginalTable);
      if GetCurrentBackend <> LOriginalBackend then
        AssertTrue('Restoring original active backend should succeed',
          RestoreOriginalActiveBackend(LOriginalBackend));
    end;
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_ActiveBackendId_Tracks_FinalState_When_HookReRegister_Overrides_ForcedSelection;
var
  LApi: PFafafaSimdPublicApi;
  LRequestedBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LOldVectorAsm: Boolean;
begin
  try
    LOldVectorAsm := IsVectorAsmEnabled;
    SetVectorAsmEnabled(True);
    ResetToAutomaticBackend;
    LRequestedBackend := GetCurrentBackend;
    if LRequestedBackend = sbScalar then
      Exit;

    AssertTrue('Requested backend should be registered for public ABI hook-driven reselection test',
      TryGetRegisteredBackendDispatchTable(LRequestedBackend, LOriginalTable));
    AssertTrue('Requested backend should start dispatchable before hook-driven mutation',
      IsBackendDispatchable(LRequestedBackend));

    GPublicAbiHookDisableBackendOriginalTable := LOriginalTable;
    GPublicAbiHookDisableBackendTarget := LRequestedBackend;
    GPublicAbiHookDisableBackendEnabled := True;
    GPublicAbiHookDisableBackendArmed := False;
    GPublicAbiHookDisableBackendDone := False;
    AddDispatchChangedHook(@PublicAbiHookDisableBackendOnce);
    try
      AssertFalse('TrySetActiveBackend should fail when hook-driven re-register makes the requested backend non-dispatchable before the call completes',
        TrySetActiveBackend(LRequestedBackend));

      LApi := GetSimdPublicApi;
      AssertNotNull('Public API table should remain available after hook-driven re-selection', LApi);
      AssertEquals('Public API active backend id should track the final active backend after hook-driven re-selection',
        Ord(GetCurrentBackend), Integer(LApi^.ActiveBackendId));
      AssertTrue('Hook-driven re-selection should move public API active backend away from the requested backend',
        Integer(LApi^.ActiveBackendId) <> Ord(LRequestedBackend));
    finally
      RemoveDispatchChangedHook(@PublicAbiHookDisableBackendOnce);
      GPublicAbiHookDisableBackendEnabled := False;
      GPublicAbiHookDisableBackendArmed := False;
      GPublicAbiHookDisableBackendDone := False;
      RegisterBackend(LRequestedBackend, LOriginalTable);
      if GetCurrentBackend <> LRequestedBackend then
        AssertTrue('Restoring original active backend should succeed',
          RestoreOriginalActiveBackend(LRequestedBackend));
    end;
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_Refreshes_WhenVectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend;
var
  LApi: PFafafaSimdPublicApi;
  LOriginalBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LOriginalInfo: TFafafaSimdBackendPodInfo;
  LActiveInfo: TFafafaSimdBackendPodInfo;
  LOldVectorAsm: Boolean;

  function IsScalarBackedForRepresentativeSlots(const aBackendTable, aScalarTable: TSimdDispatchTable): Boolean;
  begin
    Result :=
      (Pointer(aBackendTable.AddF32x4) = Pointer(aScalarTable.AddF32x4)) and
      (Pointer(aBackendTable.MulF32x4) = Pointer(aScalarTable.MulF32x4)) and
      (Pointer(aBackendTable.AddI32x4) = Pointer(aScalarTable.AddI32x4)) and
      (Pointer(aBackendTable.SelectF32x4) = Pointer(aScalarTable.SelectF32x4));
  end;
begin
  ResetToAutomaticBackend;
  LOriginalBackend := GetCurrentBackend;
  if LOriginalBackend = sbScalar then
    Exit;

  AssertTrue('Original active backend should be registered',
    TryGetRegisteredBackendDispatchTable(LOriginalBackend, LOriginalTable));
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  GetDispatchTable;
  LOldVectorAsm := IsVectorAsmEnabled;
  try
    SetVectorAsmEnabled(True);
    SetVectorAsmEnabled(False);
    AssertFalse('Vector asm should be disabled for public ABI reselection test', IsVectorAsmEnabled);

    AssertTrue('Original active backend should remain registered after runtime rebuild',
      TryGetRegisteredBackendDispatchTable(LOriginalBackend, LOriginalTable));

    if not IsScalarBackedForRepresentativeSlots(LOriginalTable, LScalarTable) then
      Exit;

    LApi := GetSimdPublicApi;
    AssertNotNull('Public API table should not be nil after vector asm disable', LApi);
    AssertEquals('Public API active backend should track current backend after vector asm disable',
      Ord(GetCurrentBackend), Integer(LApi^.ActiveBackendId));
    AssertTrue('Vector-asm-disabled reselection should move away from scalar-backed original backend',
      GetCurrentBackend <> LOriginalBackend);

    AssertTrue('Original backend pod info should remain queryable after vector asm disable',
      TryGetSimdBackendPodInfo(LOriginalBackend, LOriginalInfo));
    AssertTrue('Original backend should remain CPU-supported after vector asm disable',
      (LOriginalInfo.Flags and FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) <> 0);
    AssertTrue('Original backend should remain registered after vector asm disable',
      (LOriginalInfo.Flags and FAF_SIMD_ABI_FLAG_REGISTERED) <> 0);
    AssertTrue('Original backend should lose dispatchable bit after becoming scalar-backed',
      (LOriginalInfo.Flags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) = 0);
    AssertTrue('Original backend should lose active bit after reselection',
      (LOriginalInfo.Flags and FAF_SIMD_ABI_FLAG_ACTIVE) = 0);

    AssertTrue('New active backend pod info should be queryable after vector asm disable',
      TryGetSimdBackendPodInfo(GetCurrentBackend, LActiveInfo));
    AssertEquals('Public API active flags should match the new active backend pod flags',
      LActiveInfo.Flags, LApi^.ActiveFlags);
    AssertTrue('Public API active flags should keep active bit after reselection',
      (LApi^.ActiveFlags and FAF_SIMD_ABI_FLAG_ACTIVE) <> 0);
    AssertTrue('Public API active flags should keep dispatchable bit after reselection',
      (LApi^.ActiveFlags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) <> 0);
  finally
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_DataPlane_Parity;
var
  LApi: PFafafaSimdPublicApi;
  LA, LB: array[0..31] of Byte;
  LIdx: Integer;
  LSumApi, LSumFacade: UInt64;
  LCountApi, LCountFacade: SizeUInt;
  LPopApi, LPopFacade: SizeUInt;
  LEqApi, LEqFacade: LongBool;
  LFindApi, LFindFacade: PtrInt;
  LDiffApi, LDiffFacade: Boolean;
  LFirstApi, LLastApi: SizeUInt;
  LFirstFacade, LLastFacade: SizeUInt;
  LUtfApi, LUtfFacade: Boolean;
  LAsciiApi, LAsciiFacade: Boolean;
  LBytesApi, LBytesFacade: PtrInt;
  LNeedle: array[0..2] of Byte;
  LUtf8Text: RawByteString;
  LAsciiA, LAsciiB: RawByteString;
  LCopyApi, LCopyFacade: array[0..31] of Byte;
  LFillApi, LFillFacade: array[0..31] of Byte;
  LRevApi, LRevFacade: array[0..7] of Byte;
  LLowerApi, LLowerFacade: RawByteString;
  LUpperApi, LUpperFacade: RawByteString;
  LMinApi, LMaxApi: Byte;
  LMinFacade, LMaxFacade: Byte;
begin
  LApi := GetSimdPublicApi;
  AssertNotNull('Public API table should not be nil', LApi);

  for LIdx := 0 to High(LA) do
  begin
    LA[LIdx] := Byte((LIdx * 7) and $FF);
    LB[LIdx] := LA[LIdx];
  end;
  LB[17] := $AA;

  LEqApi := LApi^.MemEqual(@LA[0], @LA[0], Length(LA));
  LEqFacade := MemEqual(@LA[0], @LA[0], Length(LA));
  AssertEquals('MemEqual parity', LEqFacade, LEqApi);

  LFindApi := LApi^.MemFindByte(@LB[0], Length(LB), $AA);
  LFindFacade := MemFindByte(@LB[0], Length(LB), $AA);
  AssertEquals('MemFindByte parity', LFindFacade, LFindApi);

  LFirstApi := 0;
  LLastApi := 0;
  LFirstFacade := 0;
  LLastFacade := 0;
  LDiffApi := LApi^.MemDiffRange(@LA[0], @LB[0], Length(LA), LFirstApi, LLastApi);
  LDiffFacade := MemDiffRange(@LA[0], @LB[0], Length(LA), LFirstFacade, LLastFacade);
  AssertEquals('MemDiffRange parity(hasDiff)', LDiffFacade, LDiffApi);
  AssertEquals('MemDiffRange parity(firstDiff)', LFirstFacade, LFirstApi);
  AssertEquals('MemDiffRange parity(lastDiff)', LLastFacade, LLastApi);

  LSumApi := LApi^.SumBytes(@LA[0], Length(LA));
  LSumFacade := SumBytes(@LA[0], Length(LA));
  AssertEquals('SumBytes parity', LSumFacade, LSumApi);

  LCountApi := LApi^.CountByte(@LB[0], Length(LB), $AA);
  LCountFacade := CountByte(@LB[0], Length(LB), $AA);
  AssertEquals('CountByte parity', LCountFacade, LCountApi);

  LPopApi := LApi^.BitsetPopCount(@LA[0], Length(LA));
  LPopFacade := BitsetPopCount(@LA[0], Length(LA));
  AssertEquals('BitsetPopCount parity', LPopFacade, LPopApi);

  LUtf8Text := UTF8Encode('simd-测试-123');
  LUtfApi := LApi^.Utf8Validate(@LUtf8Text[1], Length(LUtf8Text));
  LUtfFacade := Utf8Validate(@LUtf8Text[1], Length(LUtf8Text));
  AssertEquals('Utf8Validate parity', LUtfFacade, LUtfApi);

  LAsciiA := 'AbCdEf012';
  LAsciiB := 'aBcDeF012';
  LAsciiApi := LApi^.AsciiIEqual(@LAsciiA[1], @LAsciiB[1], Length(LAsciiA));
  LAsciiFacade := AsciiIEqual(@LAsciiA[1], @LAsciiB[1], Length(LAsciiA));
  AssertEquals('AsciiIEqual parity', LAsciiFacade, LAsciiApi);

  LNeedle[0] := LA[7];
  LNeedle[1] := LA[8];
  LNeedle[2] := LA[9];
  LBytesApi := LApi^.BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  LBytesFacade := BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  AssertEquals('BytesIndexOf parity(hit)', LBytesFacade, LBytesApi);

  LNeedle[0] := $FE;
  LNeedle[1] := $ED;
  LNeedle[2] := $DC;
  LBytesApi := LApi^.BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  LBytesFacade := BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  AssertEquals('BytesIndexOf parity(miss)', LBytesFacade, LBytesApi);

  FillChar(LCopyApi[0], SizeOf(LCopyApi), 0);
  FillChar(LCopyFacade[0], SizeOf(LCopyFacade), 0);
  LApi^.MemCopy(@LA[0], @LCopyApi[0], Length(LA));
  MemCopy(@LA[0], @LCopyFacade[0], Length(LA));
  AssertTrue('MemCopy parity', MemEqual(@LCopyApi[0], @LCopyFacade[0], Length(LA)));

  FillChar(LFillApi[0], SizeOf(LFillApi), 0);
  FillChar(LFillFacade[0], SizeOf(LFillFacade), 0);
  LApi^.MemSet(@LFillApi[0], Length(LFillApi), $5A);
  MemSet(@LFillFacade[0], Length(LFillFacade), $5A);
  AssertTrue('MemSet parity', MemEqual(@LFillApi[0], @LFillFacade[0], Length(LFillApi)));

  LLowerApi := 'AbCdEf012';
  LLowerFacade := LLowerApi;
  UniqueString(LLowerApi);
  UniqueString(LLowerFacade);
  LApi^.ToLowerAscii(PAnsiChar(LLowerApi), Length(LLowerApi));
  ToLowerAscii(PAnsiChar(LLowerFacade), Length(LLowerFacade));
  AssertEquals('ToLowerAscii parity', LLowerFacade, LLowerApi);
  AssertEquals('ToLowerAscii expected', 'abcdef012', LLowerApi);

  LUpperApi := 'AbCdEf012';
  LUpperFacade := LUpperApi;
  UniqueString(LUpperApi);
  UniqueString(LUpperFacade);
  LApi^.ToUpperAscii(PAnsiChar(LUpperApi), Length(LUpperApi));
  ToUpperAscii(PAnsiChar(LUpperFacade), Length(LUpperFacade));
  AssertEquals('ToUpperAscii parity', LUpperFacade, LUpperApi);
  AssertEquals('ToUpperAscii expected', 'ABCDEF012', LUpperApi);

  LRevApi[0] := 1;
  LRevApi[1] := 2;
  LRevApi[2] := 3;
  LRevApi[3] := 4;
  LRevApi[4] := 5;
  LRevApi[5] := 6;
  LRevApi[6] := 7;
  LRevApi[7] := 8;
  LRevFacade := LRevApi;
  LApi^.MemReverse(@LRevApi[0], Length(LRevApi));
  MemReverse(@LRevFacade[0], Length(LRevFacade));
  AssertTrue('MemReverse parity', MemEqual(@LRevApi[0], @LRevFacade[0], Length(LRevApi)));

  LMinApi := 0;
  LMaxApi := 0;
  LMinFacade := 0;
  LMaxFacade := 0;
  LApi^.MinMaxBytes(@LA[0], Length(LA), LMinApi, LMaxApi);
  MinMaxBytes(@LA[0], Length(LA), LMinFacade, LMaxFacade);
  AssertEquals('MinMaxBytes parity(min)', LMinFacade, LMinApi);
  AssertEquals('MinMaxBytes parity(max)', LMaxFacade, LMaxApi);
end;

initialization
  RegisterTest(TTestCase_PublicAbi);

end.

unit fafafa.core.simd.dispatchapi.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

// Keep parity with the original testcase compilation behavior.
{$R-}{$Q-}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.utils,
  fafafa.core.simd.ops,
  fafafa.core.simd.api,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.scalar;

type


  // Dispatch public API contract tests
  TTestCase_DispatchAPI = class(TTestCase)
  published
    procedure Test_TryForceBackend_Scalar_ReturnsTrue;
    procedure Test_TryForceBackend_Unavailable_NoChange;
    procedure Test_TrySetActiveBackend_Scalar_ReturnsTrue;
    procedure Test_TrySetActiveBackend_Unavailable_NoChange;
    procedure Test_SetActiveBackend_Unavailable_FallsBackToScalar;
    procedure Test_DispatchChangedHooks_MultiSubscriber_Dedup_And_Remove;
    procedure Test_BackendInfoAvailableFalse_IsNotSelectable;
    procedure Test_BackendConceptViews_AreSelfConsistent;
    procedure Test_GetAvailableBackendList_AliasesDispatchableView;
    procedure Test_VecI64x2_DispatchAssigned_And_Parity;
    procedure Test_VecU64x2_DispatchAssigned_And_Parity;
    procedure Test_VecU32x8_DispatchAssigned_And_Parity;
    procedure Test_VecF64x4_DispatchAssigned_And_Parity;
    procedure Test_VecI64x4_DispatchAssigned_And_Parity;
    procedure Test_VecU64x4_DispatchAssigned_And_Parity;
    procedure Test_VecI64x8_DispatchAssigned_And_Parity;
    procedure Test_VecF32x16_DispatchAssigned_And_Parity;
    procedure Test_VecF64x8_DispatchAssigned_And_Parity;
    procedure Test_VecU32x16_DispatchAssigned_And_Parity;
    procedure Test_VecU64x8_DispatchAssigned_And_Parity;
    procedure Test_VecI16x32_DispatchAssigned_And_Parity;
    procedure Test_VecI8x64_DispatchAssigned_And_Parity;
    procedure Test_VecU8x64_DispatchAssigned_And_Parity;
    procedure Test_WideFamilies_FacadeScalar_Parity_Completeness;
    procedure Test_CoreFamilies_FacadeScalar_Parity_Completeness_Batch2;
    procedure Test_BacklogParityAndSmoke_Batch3;
    procedure Test_AllRegisteredBackends_Wide512IntegerSlots_Assigned;
    procedure Test_AVX512_U32x16_U64x8_MappingAndParity;
    procedure Test_AVX512_I16x32_I8x64_U8x64_MappingAndParity;
    procedure Test_AVX512_F32x16_F64x8_IEEE754_MappingAndParity;
    procedure Test_BackendCapabilities_DoNotOverclaim_512BitOps;
    procedure Test_AVX2_BenchmarkWideOps_NotScalar;
    procedure Test_NonX86_DispatchTable_WiringChecklist_Grouped;
    procedure Test_NonX86_DispatchTable_WiringChecklist;
    procedure Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable;
    procedure Test_X86_DispatchTable_WiringChecklist_Grouped;
  end;

  // Non-x86 backend semantic parity smoke (NEON/RISCVV if available).
  TTestCase_NonX86BackendParity = class(TTestCase)
  published
    procedure Test_NativeWideFloorCeilSlots_NotScalar_IfAvailable;
    procedure Test_MinimalDispatchParity_IfAvailable;
    procedure Test_ExtendedFloatParity_IfAvailable;
    procedure Test_NarrowAndNotParity_IfAvailable;
    procedure Test_DotParity_IfAvailable;
    procedure Test_I16x32_CoreParity_IfAvailable;
    procedure Test_I8x64_CoreParity_IfAvailable;
    procedure Test_U32x16_U64x8_CoreParity_IfAvailable;
    procedure Test_WideInteger_FuzzSeed_Parity_IfAvailable;
    procedure Test_I32x4_BitwiseShiftParity_IfAvailable;
  end;

implementation

var
  GDispatchHookCountA: Integer = 0;
  GDispatchHookCountB: Integer = 0;

procedure DispatchHookProbeA;
begin
  Inc(GDispatchHookCountA);
end;

procedure DispatchHookProbeB;
begin
  Inc(GDispatchHookCountB);
end;

{ TTestCase_DispatchAPI }

procedure TTestCase_DispatchAPI.Test_TryForceBackend_Scalar_ReturnsTrue;
begin
  try
    AssertTrue('TryForceBackend(sbScalar) should succeed', TryForceBackend(sbScalar));
    AssertEquals('Active backend should be Scalar after TryForceBackend', Ord(sbScalar), Ord(GetActiveBackend));
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_TryForceBackend_Unavailable_NoChange;
var
  LOriginal: TSimdBackend;
begin
  LOriginal := GetActiveBackend;
  try
    {$IFDEF CPUX86_64}
    AssertFalse('TryForceBackend(sbNEON) should fail on x86_64', TryForceBackend(sbNEON));
    {$ELSE}
    {$IFDEF CPUAARCH64}
    AssertFalse('TryForceBackend(sbSSE2) should fail on AArch64', TryForceBackend(sbSSE2));
    {$ELSE}
    AssertFalse('TryForceBackend(sbAVX512) should fail when backend is unavailable', TryForceBackend(sbAVX512));
    {$ENDIF}
    {$ENDIF}

    AssertEquals('Active backend should remain unchanged after failed TryForceBackend', Ord(LOriginal), Ord(GetActiveBackend));
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_TrySetActiveBackend_Scalar_ReturnsTrue;
begin
  try
    AssertTrue('TrySetActiveBackend(sbScalar) should succeed', TrySetActiveBackend(sbScalar));
    AssertEquals('Active backend should be Scalar after TrySetActiveBackend', Ord(sbScalar), Ord(GetActiveBackend));
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_TrySetActiveBackend_Unavailable_NoChange;
var
  original: TSimdBackend;
begin
  original := GetActiveBackend;
  try
    {$IFDEF CPUX86_64}
    AssertFalse('TrySetActiveBackend(sbNEON) should fail on x86_64', TrySetActiveBackend(sbNEON));
    {$ELSE}
    {$IFDEF CPUAARCH64}
    AssertFalse('TrySetActiveBackend(sbSSE2) should fail on AArch64', TrySetActiveBackend(sbSSE2));
    {$ELSE}
    AssertFalse('TrySetActiveBackend(sbAVX512) should fail when backend is unavailable', TrySetActiveBackend(sbAVX512));
    {$ENDIF}
    {$ENDIF}

    AssertEquals('Active backend should remain unchanged after failed TrySetActiveBackend', Ord(original), Ord(GetActiveBackend));
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_SetActiveBackend_Unavailable_FallsBackToScalar;
begin
  try
    {$IFDEF CPUX86_64}
    SetActiveBackend(sbNEON);
    {$ELSE}
    {$IFDEF CPUAARCH64}
    SetActiveBackend(sbSSE2);
    {$ELSE}
    SetActiveBackend(sbAVX512);
    {$ENDIF}
    {$ENDIF}

    AssertEquals('SetActiveBackend(unavailable) should fall back to Scalar', Ord(sbScalar), Ord(GetActiveBackend));
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_BackendInfoAvailableFalse_IsNotSelectable;
var
  originalBackend: TSimdBackend;
  beforeTry: TSimdBackend;
  afterAuto: TSimdBackend;
  dtOrig, dtMod: TSimdDispatchTable;
begin
  ResetToAutomaticBackend;
  originalBackend := GetActiveBackend;

  // If we ended up on Scalar, there's nothing meaningful to test.
  if originalBackend = sbScalar then
    Exit;

  AssertTrue('Active backend should be registered',
             TryGetRegisteredBackendDispatchTable(originalBackend, dtOrig));

  dtMod := dtOrig;
  dtMod.BackendInfo.Available := False;

  // Re-register same backend but mark it unavailable.
  RegisterBackend(originalBackend, dtMod);
  try
    // Forced selection must now fail.
    beforeTry := GetActiveBackend;
    AssertFalse('TrySetActiveBackend should fail when BackendInfo.Available=False',
                TrySetActiveBackend(originalBackend));
    AssertEquals('Active backend should remain unchanged after failed TrySetActiveBackend',
                 Ord(beforeTry), Ord(GetActiveBackend));

    // Automatic selection must not pick this backend anymore.
    ResetToAutomaticBackend;
    afterAuto := GetActiveBackend;
    AssertTrue('Automatic selection should skip backend marked unavailable', afterAuto <> originalBackend);
  finally
    // Restore original table.
    RegisterBackend(originalBackend, dtOrig);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_BackendConceptViews_AreSelfConsistent;
var
  LSupported: TSimdBackendArray;
  LRegistered: TSimdBackendArray;
  LDispatchable: TSimdBackendArray;
  LBackend: TSimdBackend;
  LIndex: Integer;

  function BackendInArray(const aItems: TSimdBackendArray; aBackend: TSimdBackend): Boolean;
  var
    LItemIndex: Integer;
  begin
    for LItemIndex := 0 to High(aItems) do
      if aItems[LItemIndex] = aBackend then
        Exit(True);
    Result := False;
  end;
begin
  LSupported := fafafa.core.simd.GetSupportedBackendList;
  LRegistered := fafafa.core.simd.GetRegisteredBackendList;
  LDispatchable := fafafa.core.simd.GetDispatchableBackendList;

  AssertTrue('Supported backend list should contain Scalar', BackendInArray(LSupported, sbScalar));
  AssertTrue('Registered backend list should contain Scalar', BackendInArray(LRegistered, sbScalar));
  AssertTrue('Dispatchable backend list should contain Scalar', BackendInArray(LDispatchable, sbScalar));

  for LIndex := 0 to High(LSupported) do
  begin
    LBackend := LSupported[LIndex];
    AssertTrue('Supported view must satisfy cpu-support predicate for backend=' + IntToStr(Ord(LBackend)),
      IsBackendAvailableOnCPU(LBackend));
  end;

  for LIndex := 0 to High(LRegistered) do
  begin
    LBackend := LRegistered[LIndex];
    AssertTrue('Registered view must satisfy registered predicate for backend=' + IntToStr(Ord(LBackend)),
      fafafa.core.simd.IsBackendRegisteredInBinary(LBackend));
  end;

  for LIndex := 0 to High(LDispatchable) do
  begin
    LBackend := LDispatchable[LIndex];
    AssertTrue('Dispatchable view must satisfy dispatchable predicate for backend=' + IntToStr(Ord(LBackend)),
      IsBackendDispatchable(LBackend));
    AssertTrue('Dispatchable view must be subset of registered view for backend=' + IntToStr(Ord(LBackend)),
      BackendInArray(LRegistered, LBackend));
    AssertTrue('Dispatchable view must be subset of supported view for backend=' + IntToStr(Ord(LBackend)),
      BackendInArray(LSupported, LBackend));
  end;

  AssertTrue('Current active backend must be dispatchable',
    IsBackendDispatchable(fafafa.core.simd.GetCurrentBackend));
  AssertTrue('Best dispatchable backend must be dispatchable',
    IsBackendDispatchable(fafafa.core.simd.GetBestDispatchableBackend));
  AssertTrue('Best supported backend must be cpu-supported',
    IsBackendAvailableOnCPU(fafafa.core.simd.GetBestSupportedBackend));
end;

procedure TTestCase_DispatchAPI.Test_GetAvailableBackendList_AliasesDispatchableView;
var
  LAvailable: TSimdBackendArray;
  LDispatchable: TSimdBackendArray;
  LIndex: Integer;
begin
  LAvailable := fafafa.core.simd.GetAvailableBackendList;
  LDispatchable := fafafa.core.simd.GetDispatchableBackendList;

  AssertEquals('Available backend list length should match dispatchable view',
    Length(LDispatchable), Length(LAvailable));

  for LIndex := 0 to High(LAvailable) do
    AssertEquals('Available backend list should alias dispatchable ordering at index ' + IntToStr(LIndex),
      Ord(LDispatchable[LIndex]), Ord(LAvailable[LIndex]));
end;

procedure TTestCase_DispatchAPI.Test_VecI64x2_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecI64x2;
  LVecByDispatch, LVecByFacade: TVecI64x2;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AndNotI64x2 should be assigned', Assigned(LDispatch^.AndNotI64x2));
  AssertTrue('Dispatch.ShiftLeftI64x2 should be assigned', Assigned(LDispatch^.ShiftLeftI64x2));
  AssertTrue('Dispatch.ShiftRightI64x2 should be assigned', Assigned(LDispatch^.ShiftRightI64x2));
  AssertTrue('Dispatch.ShiftRightArithI64x2 should be assigned', Assigned(LDispatch^.ShiftRightArithI64x2));
  AssertTrue('Dispatch.MinI64x2 should be assigned', Assigned(LDispatch^.MinI64x2));
  AssertTrue('Dispatch.MaxI64x2 should be assigned', Assigned(LDispatch^.MaxI64x2));

  LA.i[0] := $0F0F0F0F0F0F0F0F;
  LA.i[1] := -16;
  LB.i[0] := $00FF00FF00FF00FF;
  LB.i[1] := 7;

  LVecByDispatch := LDispatch^.AndNotI64x2(LA, LB);
  LVecByFacade := VecI64x2AndNot(LA, LB);
  AssertEquals('Dispatch/Facade AndNotI64x2 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade AndNotI64x2 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);

  LVecByDispatch := LDispatch^.ShiftLeftI64x2(LA, 3);
  LVecByFacade := VecI64x2ShiftLeft(LA, 3);
  AssertEquals('Dispatch/Facade ShiftLeftI64x2 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade ShiftLeftI64x2 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);

  LVecByDispatch := LDispatch^.ShiftRightI64x2(LA, 4);
  LVecByFacade := VecI64x2ShiftRight(LA, 4);
  AssertEquals('Dispatch/Facade ShiftRightI64x2 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade ShiftRightI64x2 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);

  LVecByDispatch := LDispatch^.ShiftRightArithI64x2(LA, 2);
  LVecByFacade := VecI64x2ShiftRightArith(LA, 2);
  AssertEquals('Dispatch/Facade ShiftRightArithI64x2 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade ShiftRightArithI64x2 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);

  LVecByDispatch := LDispatch^.MinI64x2(LA, LB);
  LVecByFacade := VecI64x2Min(LA, LB);
  AssertEquals('Dispatch/Facade MinI64x2 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade MinI64x2 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);

  LVecByDispatch := LDispatch^.MaxI64x2(LA, LB);
  LVecByFacade := VecI64x2Max(LA, LB);
  AssertEquals('Dispatch/Facade MaxI64x2 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade MaxI64x2 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);
end;

procedure TTestCase_DispatchAPI.Test_VecU64x2_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecU64x2;
  LMaskByDispatch: TMask2;
  LVecByDispatch, LVecByFacade: TVecU64x2;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddU64x2 should be assigned', Assigned(LDispatch^.AddU64x2));
  AssertTrue('Dispatch.SubU64x2 should be assigned', Assigned(LDispatch^.SubU64x2));
  AssertTrue('Dispatch.AndU64x2 should be assigned', Assigned(LDispatch^.AndU64x2));
  AssertTrue('Dispatch.OrU64x2 should be assigned', Assigned(LDispatch^.OrU64x2));
  AssertTrue('Dispatch.XorU64x2 should be assigned', Assigned(LDispatch^.XorU64x2));
  AssertTrue('Dispatch.NotU64x2 should be assigned', Assigned(LDispatch^.NotU64x2));
  AssertTrue('Dispatch.AndNotU64x2 should be assigned', Assigned(LDispatch^.AndNotU64x2));
  AssertTrue('Dispatch.CmpEqU64x2 should be assigned', Assigned(LDispatch^.CmpEqU64x2));
  AssertTrue('Dispatch.CmpLtU64x2 should be assigned', Assigned(LDispatch^.CmpLtU64x2));
  AssertTrue('Dispatch.CmpGtU64x2 should be assigned', Assigned(LDispatch^.CmpGtU64x2));
  AssertTrue('Dispatch.MinU64x2 should be assigned', Assigned(LDispatch^.MinU64x2));
  AssertTrue('Dispatch.MaxU64x2 should be assigned', Assigned(LDispatch^.MaxU64x2));

  LA.u[0] := $F0F0F0F0F0F0F0F0;
  LA.u[1] := 20;
  LB.u[0] := $00FF00FF00FF00FF;
  LB.u[1] := 30;

  LVecByDispatch := LDispatch^.AddU64x2(LA, LB);
  LVecByFacade := VecU64x2Add(LA, LB);
  AssertEquals('Dispatch/Facade AddU64x2 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade AddU64x2 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);

  LVecByDispatch := LDispatch^.AndNotU64x2(LA, LB);
  LVecByFacade := VecU64x2AndNot(LA, LB);
  AssertEquals('Dispatch/Facade AndNotU64x2 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade AndNotU64x2 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);

  AssertEquals('Dispatch/Facade CmpEqU64x2 parity',
    Integer(VecU64x2CmpEq(LA, LB)), Integer(LDispatch^.CmpEqU64x2(LA, LB)));
  AssertEquals('Dispatch/Facade CmpLtU64x2 parity',
    Integer(VecU64x2CmpLt(LA, LB)), Integer(LDispatch^.CmpLtU64x2(LA, LB)));
  AssertEquals('Dispatch/Facade CmpGtU64x2 parity',
    Integer(VecU64x2CmpGt(LA, LB)), Integer(LDispatch^.CmpGtU64x2(LA, LB)));

  LVecByDispatch := LDispatch^.MinU64x2(LA, LB);
  LVecByFacade := VecU64x2Min(LA, LB);
  AssertEquals('Dispatch/Facade MinU64x2 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade MinU64x2 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);

  LVecByDispatch := LDispatch^.MaxU64x2(LA, LB);
  LVecByFacade := VecU64x2Max(LA, LB);
  AssertEquals('Dispatch/Facade MaxU64x2 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade MaxU64x2 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);

  // 预期值断言：覆盖无符号比较高位边界（防止符号比较误用）
  LA.u[0] := QWord($FFFFFFFFFFFFFFFF);
  LA.u[1] := 1;
  LB.u[0] := 0;
  LB.u[1] := 2;

  LMaskByDispatch := LDispatch^.CmpLtU64x2(LA, LB);
  AssertEquals('Dispatch CmpLtU64x2 expected mask', Integer(TMask2(2)), Integer(LMaskByDispatch));
  LMaskByDispatch := LDispatch^.CmpGtU64x2(LA, LB);
  AssertEquals('Dispatch CmpGtU64x2 expected mask', Integer(TMask2(1)), Integer(LMaskByDispatch));

  AssertEquals('Facade CmpLtU64x2 expected mask', Integer(TMask2(2)), Integer(VecU64x2CmpLt(LA, LB)));
  AssertEquals('Facade CmpGtU64x2 expected mask', Integer(TMask2(1)), Integer(VecU64x2CmpGt(LA, LB)));

  LVecByDispatch := LDispatch^.MinU64x2(LA, LB);
  AssertEquals('Dispatch MinU64x2 expected lane0', QWord(0), LVecByDispatch.u[0]);
  AssertEquals('Dispatch MinU64x2 expected lane1', QWord(1), LVecByDispatch.u[1]);

  LVecByDispatch := LDispatch^.MaxU64x2(LA, LB);
  AssertEquals('Dispatch MaxU64x2 expected lane0', QWord($FFFFFFFFFFFFFFFF), LVecByDispatch.u[0]);
  AssertEquals('Dispatch MaxU64x2 expected lane1', QWord(2), LVecByDispatch.u[1]);
end;

procedure TTestCase_DispatchAPI.Test_VecU32x8_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecU32x8;
  LMaskByDispatch: TMask8;
  LVecByDispatch, LVecByFacade: TVecU32x8;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddU32x8 should be assigned', Assigned(LDispatch^.AddU32x8));
  AssertTrue('Dispatch.SubU32x8 should be assigned', Assigned(LDispatch^.SubU32x8));
  AssertTrue('Dispatch.MulU32x8 should be assigned', Assigned(LDispatch^.MulU32x8));
  AssertTrue('Dispatch.AndU32x8 should be assigned', Assigned(LDispatch^.AndU32x8));
  AssertTrue('Dispatch.OrU32x8 should be assigned', Assigned(LDispatch^.OrU32x8));
  AssertTrue('Dispatch.XorU32x8 should be assigned', Assigned(LDispatch^.XorU32x8));
  AssertTrue('Dispatch.NotU32x8 should be assigned', Assigned(LDispatch^.NotU32x8));
  AssertTrue('Dispatch.AndNotU32x8 should be assigned', Assigned(LDispatch^.AndNotU32x8));
  AssertTrue('Dispatch.ShiftLeftU32x8 should be assigned', Assigned(LDispatch^.ShiftLeftU32x8));
  AssertTrue('Dispatch.ShiftRightU32x8 should be assigned', Assigned(LDispatch^.ShiftRightU32x8));
  AssertTrue('Dispatch.CmpEqU32x8 should be assigned', Assigned(LDispatch^.CmpEqU32x8));
  AssertTrue('Dispatch.CmpLtU32x8 should be assigned', Assigned(LDispatch^.CmpLtU32x8));
  AssertTrue('Dispatch.CmpGtU32x8 should be assigned', Assigned(LDispatch^.CmpGtU32x8));
  AssertTrue('Dispatch.CmpLeU32x8 should be assigned', Assigned(LDispatch^.CmpLeU32x8));
  AssertTrue('Dispatch.CmpGeU32x8 should be assigned', Assigned(LDispatch^.CmpGeU32x8));
  AssertTrue('Dispatch.CmpNeU32x8 should be assigned', Assigned(LDispatch^.CmpNeU32x8));
  AssertTrue('Dispatch.MinU32x8 should be assigned', Assigned(LDispatch^.MinU32x8));
  AssertTrue('Dispatch.MaxU32x8 should be assigned', Assigned(LDispatch^.MaxU32x8));

  LA.u[0] := 1;          LB.u[0] := 2;
  LA.u[1] := 3;          LB.u[1] := 4;
  LA.u[2] := $FFFFFFFF;  LB.u[2] := 1;
  LA.u[3] := 9;          LB.u[3] := 9;
  LA.u[4] := 0;          LB.u[4] := 7;
  LA.u[5] := 12;         LB.u[5] := 6;
  LA.u[6] := $80000000;  LB.u[6] := $7FFFFFFF;
  LA.u[7] := 42;         LB.u[7] := 43;

  LVecByDispatch := LDispatch^.AddU32x8(LA, LB);
  LVecByFacade := VecU32x8Add(LA, LB);
  AssertEquals('Dispatch/Facade AddU32x8 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade AddU32x8 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);
  AssertEquals('Dispatch/Facade AddU32x8 lane2 parity', LVecByFacade.u[2], LVecByDispatch.u[2]);
  AssertEquals('Dispatch/Facade AddU32x8 lane3 parity', LVecByFacade.u[3], LVecByDispatch.u[3]);

  LVecByDispatch := LDispatch^.AndNotU32x8(LA, LB);
  LVecByFacade := VecU32x8AndNot(LA, LB);
  AssertEquals('Dispatch/Facade AndNotU32x8 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade AndNotU32x8 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);
  AssertEquals('Dispatch/Facade AndNotU32x8 lane2 parity', LVecByFacade.u[2], LVecByDispatch.u[2]);
  AssertEquals('Dispatch/Facade AndNotU32x8 lane3 parity', LVecByFacade.u[3], LVecByDispatch.u[3]);

  LMaskByDispatch := LDispatch^.CmpNeU32x8(LA, LB);
  AssertEquals('Dispatch/Facade CmpNeU32x8 parity', Integer(VecU32x8CmpNe(LA, LB)), Integer(LMaskByDispatch));

  LVecByDispatch := LDispatch^.MinU32x8(LA, LB);
  LVecByFacade := VecU32x8Min(LA, LB);
  AssertEquals('Dispatch/Facade MinU32x8 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade MinU32x8 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);

  LVecByDispatch := LDispatch^.MaxU32x8(LA, LB);
  LVecByFacade := VecU32x8Max(LA, LB);
  AssertEquals('Dispatch/Facade MaxU32x8 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade MaxU32x8 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);
end;

procedure TTestCase_DispatchAPI.Test_VecF64x4_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecF64x4;
  LVecByDispatch, LVecByFacade: TVecF64x4;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddF64x4 should be assigned', Assigned(LDispatch^.AddF64x4));
  AssertTrue('Dispatch.SubF64x4 should be assigned', Assigned(LDispatch^.SubF64x4));
  AssertTrue('Dispatch.MulF64x4 should be assigned', Assigned(LDispatch^.MulF64x4));
  AssertTrue('Dispatch.DivF64x4 should be assigned', Assigned(LDispatch^.DivF64x4));
  AssertTrue('Dispatch.RcpF64x4 should be assigned', Assigned(LDispatch^.RcpF64x4));
  AssertTrue('Dispatch.AbsF64x4 should be assigned', Assigned(LDispatch^.AbsF64x4));
  AssertTrue('Dispatch.SqrtF64x4 should be assigned', Assigned(LDispatch^.SqrtF64x4));
  AssertTrue('Dispatch.MinF64x4 should be assigned', Assigned(LDispatch^.MinF64x4));
  AssertTrue('Dispatch.MaxF64x4 should be assigned', Assigned(LDispatch^.MaxF64x4));

  LA.d[0] := 2.0;   LB.d[0] := 1.0;
  LA.d[1] := -4.0;  LB.d[1] := 2.0;
  LA.d[2] := 0.5;   LB.d[2] := 8.0;
  LA.d[3] := 16.0;  LB.d[3] := 4.0;

  LVecByDispatch := LDispatch^.AddF64x4(LA, LB);
  LVecByFacade := VecF64x4Add(LA, LB);
  for LIndex := 0 to 3 do
    AssertEquals('Dispatch/Facade AddF64x4 lane parity', LVecByFacade.d[LIndex], LVecByDispatch.d[LIndex], 1e-12);

  LVecByDispatch := LDispatch^.RcpF64x4(LB);
  LVecByFacade := VecF64x4Rcp(LB);
  for LIndex := 0 to 3 do
    AssertEquals('Dispatch/Facade RcpF64x4 lane parity', LVecByFacade.d[LIndex], LVecByDispatch.d[LIndex], 1e-12);

  LVecByDispatch := LDispatch^.MinF64x4(LA, LB);
  LVecByFacade := VecF64x4Min(LA, LB);
  for LIndex := 0 to 3 do
    AssertEquals('Dispatch/Facade MinF64x4 lane parity', LVecByFacade.d[LIndex], LVecByDispatch.d[LIndex], 1e-12);
end;


procedure TTestCase_DispatchAPI.Test_VecI64x4_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecI64x4;
  LMaskByDispatch: TMask4;
  LVecByDispatch, LVecByFacade: TVecI64x4;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddI64x4 should be assigned', Assigned(LDispatch^.AddI64x4));
  AssertTrue('Dispatch.SubI64x4 should be assigned', Assigned(LDispatch^.SubI64x4));
  AssertTrue('Dispatch.AndI64x4 should be assigned', Assigned(LDispatch^.AndI64x4));
  AssertTrue('Dispatch.OrI64x4 should be assigned', Assigned(LDispatch^.OrI64x4));
  AssertTrue('Dispatch.XorI64x4 should be assigned', Assigned(LDispatch^.XorI64x4));
  AssertTrue('Dispatch.NotI64x4 should be assigned', Assigned(LDispatch^.NotI64x4));
  AssertTrue('Dispatch.AndNotI64x4 should be assigned', Assigned(LDispatch^.AndNotI64x4));
  AssertTrue('Dispatch.ShiftLeftI64x4 should be assigned', Assigned(LDispatch^.ShiftLeftI64x4));
  AssertTrue('Dispatch.ShiftRightI64x4 should be assigned', Assigned(LDispatch^.ShiftRightI64x4));
  AssertTrue('Dispatch.ShiftRightArithI64x4 should be assigned', Assigned(LDispatch^.ShiftRightArithI64x4));
  AssertTrue('Dispatch.CmpEqI64x4 should be assigned', Assigned(LDispatch^.CmpEqI64x4));
  AssertTrue('Dispatch.CmpLtI64x4 should be assigned', Assigned(LDispatch^.CmpLtI64x4));
  AssertTrue('Dispatch.CmpGtI64x4 should be assigned', Assigned(LDispatch^.CmpGtI64x4));
  AssertTrue('Dispatch.CmpLeI64x4 should be assigned', Assigned(LDispatch^.CmpLeI64x4));
  AssertTrue('Dispatch.CmpGeI64x4 should be assigned', Assigned(LDispatch^.CmpGeI64x4));
  AssertTrue('Dispatch.CmpNeI64x4 should be assigned', Assigned(LDispatch^.CmpNeI64x4));

  LA.i[0] := -1;
  LA.i[1] := 5;
  LA.i[2] := 7;
  LA.i[3] := -8;
  LB.i[0] := 0;
  LB.i[1] := 1;
  LB.i[2] := 7;
  LB.i[3] := 9;

  LVecByDispatch := LDispatch^.AndNotI64x4(LA, LB);
  LVecByFacade := VecI64x4AndNot(LA, LB);
  AssertEquals('Dispatch/Facade AndNotI64x4 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade AndNotI64x4 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);
  AssertEquals('Dispatch/Facade AndNotI64x4 lane2 parity', LVecByFacade.i[2], LVecByDispatch.i[2]);
  AssertEquals('Dispatch/Facade AndNotI64x4 lane3 parity', LVecByFacade.i[3], LVecByDispatch.i[3]);

  LVecByDispatch := LDispatch^.ShiftLeftI64x4(LA, 2);
  LVecByFacade := VecI64x4ShiftLeft(LA, 2);
  AssertEquals('Dispatch/Facade ShiftLeftI64x4 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade ShiftLeftI64x4 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);
  AssertEquals('Dispatch/Facade ShiftLeftI64x4 lane2 parity', LVecByFacade.i[2], LVecByDispatch.i[2]);
  AssertEquals('Dispatch/Facade ShiftLeftI64x4 lane3 parity', LVecByFacade.i[3], LVecByDispatch.i[3]);

  LVecByDispatch := LDispatch^.ShiftRightArithI64x4(LA, 2);
  LVecByFacade := VecI64x4ShiftRightArith(LA, 2);
  AssertEquals('Dispatch/Facade ShiftRightArithI64x4 lane0 parity', LVecByFacade.i[0], LVecByDispatch.i[0]);
  AssertEquals('Dispatch/Facade ShiftRightArithI64x4 lane1 parity', LVecByFacade.i[1], LVecByDispatch.i[1]);
  AssertEquals('Dispatch/Facade ShiftRightArithI64x4 lane2 parity', LVecByFacade.i[2], LVecByDispatch.i[2]);
  AssertEquals('Dispatch/Facade ShiftRightArithI64x4 lane3 parity', LVecByFacade.i[3], LVecByDispatch.i[3]);

  LMaskByDispatch := LDispatch^.CmpLtI64x4(LA, LB);
  AssertEquals('Dispatch CmpLtI64x4 expected mask', Integer(TMask4(9)), Integer(LMaskByDispatch));
  AssertEquals('Facade CmpLtI64x4 expected mask', Integer(TMask4(9)), Integer(VecI64x4CmpLt(LA, LB)));

  LMaskByDispatch := LDispatch^.CmpGtI64x4(LA, LB);
  AssertEquals('Dispatch CmpGtI64x4 expected mask', Integer(TMask4(2)), Integer(LMaskByDispatch));
  AssertEquals('Facade CmpGtI64x4 expected mask', Integer(TMask4(2)), Integer(VecI64x4CmpGt(LA, LB)));

  LMaskByDispatch := LDispatch^.CmpEqI64x4(LA, LB);
  AssertEquals('Dispatch CmpEqI64x4 expected mask', Integer(TMask4(4)), Integer(LMaskByDispatch));
  AssertEquals('Facade CmpEqI64x4 expected mask', Integer(TMask4(4)), Integer(VecI64x4CmpEq(LA, LB)));
end;

procedure TTestCase_DispatchAPI.Test_VecU64x4_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecU64x4;
  LMaskByDispatch: TMask4;
  LVecByDispatch, LVecByFacade: TVecU64x4;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddU64x4 should be assigned', Assigned(LDispatch^.AddU64x4));
  AssertTrue('Dispatch.SubU64x4 should be assigned', Assigned(LDispatch^.SubU64x4));
  AssertTrue('Dispatch.AndU64x4 should be assigned', Assigned(LDispatch^.AndU64x4));
  AssertTrue('Dispatch.OrU64x4 should be assigned', Assigned(LDispatch^.OrU64x4));
  AssertTrue('Dispatch.XorU64x4 should be assigned', Assigned(LDispatch^.XorU64x4));
  AssertTrue('Dispatch.NotU64x4 should be assigned', Assigned(LDispatch^.NotU64x4));
  AssertTrue('Dispatch.ShiftLeftU64x4 should be assigned', Assigned(LDispatch^.ShiftLeftU64x4));
  AssertTrue('Dispatch.ShiftRightU64x4 should be assigned', Assigned(LDispatch^.ShiftRightU64x4));
  AssertTrue('Dispatch.CmpEqU64x4 should be assigned', Assigned(LDispatch^.CmpEqU64x4));
  AssertTrue('Dispatch.CmpLtU64x4 should be assigned', Assigned(LDispatch^.CmpLtU64x4));
  AssertTrue('Dispatch.CmpGtU64x4 should be assigned', Assigned(LDispatch^.CmpGtU64x4));
  AssertTrue('Dispatch.CmpLeU64x4 should be assigned', Assigned(LDispatch^.CmpLeU64x4));
  AssertTrue('Dispatch.CmpGeU64x4 should be assigned', Assigned(LDispatch^.CmpGeU64x4));
  AssertTrue('Dispatch.CmpNeU64x4 should be assigned', Assigned(LDispatch^.CmpNeU64x4));

  LA.u[0] := QWord($FFFFFFFFFFFFFFFF);
  LA.u[1] := 0;
  LA.u[2] := 5;
  LA.u[3] := 9;
  LB.u[0] := 0;
  LB.u[1] := 1;
  LB.u[2] := 5;
  LB.u[3] := 8;

  LVecByDispatch := LDispatch^.AddU64x4(LA, LB);
  LVecByFacade := VecU64x4Add(LA, LB);
  AssertEquals('Dispatch/Facade AddU64x4 lane0 parity', LVecByFacade.u[0], LVecByDispatch.u[0]);
  AssertEquals('Dispatch/Facade AddU64x4 lane1 parity', LVecByFacade.u[1], LVecByDispatch.u[1]);
  AssertEquals('Dispatch/Facade AddU64x4 lane2 parity', LVecByFacade.u[2], LVecByDispatch.u[2]);
  AssertEquals('Dispatch/Facade AddU64x4 lane3 parity', LVecByFacade.u[3], LVecByDispatch.u[3]);

  LMaskByDispatch := LDispatch^.CmpLtU64x4(LA, LB);
  AssertEquals('Dispatch CmpLtU64x4 expected mask', Integer(TMask4(2)), Integer(LMaskByDispatch));
  AssertEquals('Facade CmpLtU64x4 expected mask', Integer(TMask4(2)), Integer(VecU64x4CmpLt(LA, LB)));

  LMaskByDispatch := LDispatch^.CmpGtU64x4(LA, LB);
  AssertEquals('Dispatch CmpGtU64x4 expected mask', Integer(TMask4(9)), Integer(LMaskByDispatch));
  AssertEquals('Facade CmpGtU64x4 expected mask', Integer(TMask4(9)), Integer(VecU64x4CmpGt(LA, LB)));

  LMaskByDispatch := LDispatch^.CmpEqU64x4(LA, LB);
  AssertEquals('Dispatch CmpEqU64x4 expected mask', Integer(TMask4(4)), Integer(LMaskByDispatch));
  AssertEquals('Facade CmpEqU64x4 expected mask', Integer(TMask4(4)), Integer(VecU64x4CmpEq(LA, LB)));
end;


procedure TTestCase_DispatchAPI.Test_VecI64x8_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecI64x8;
  LVecByDispatch, LVecByScalar: TVecI64x8;
  LMaskByDispatch, LMaskByScalar: TMask8;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddI64x8 should be assigned', Assigned(LDispatch^.AddI64x8));
  AssertTrue('Dispatch.SubI64x8 should be assigned', Assigned(LDispatch^.SubI64x8));
  AssertTrue('Dispatch.AndI64x8 should be assigned', Assigned(LDispatch^.AndI64x8));
  AssertTrue('Dispatch.OrI64x8 should be assigned', Assigned(LDispatch^.OrI64x8));
  AssertTrue('Dispatch.XorI64x8 should be assigned', Assigned(LDispatch^.XorI64x8));
  AssertTrue('Dispatch.NotI64x8 should be assigned', Assigned(LDispatch^.NotI64x8));
  AssertTrue('Dispatch.CmpEqI64x8 should be assigned', Assigned(LDispatch^.CmpEqI64x8));
  AssertTrue('Dispatch.CmpLtI64x8 should be assigned', Assigned(LDispatch^.CmpLtI64x8));
  AssertTrue('Dispatch.CmpGtI64x8 should be assigned', Assigned(LDispatch^.CmpGtI64x8));
  AssertTrue('Dispatch.CmpLeI64x8 should be assigned', Assigned(LDispatch^.CmpLeI64x8));
  AssertTrue('Dispatch.CmpGeI64x8 should be assigned', Assigned(LDispatch^.CmpGeI64x8));
  AssertTrue('Dispatch.CmpNeI64x8 should be assigned', Assigned(LDispatch^.CmpNeI64x8));

  LA.i[0] := -1;   LB.i[0] := 0;
  LA.i[1] := 5;    LB.i[1] := 1;
  LA.i[2] := 7;    LB.i[2] := 7;
  LA.i[3] := -8;   LB.i[3] := 9;
  LA.i[4] := 12;   LB.i[4] := -3;
  LA.i[5] := 0;    LB.i[5] := 0;
  LA.i[6] := 100;  LB.i[6] := 200;
  LA.i[7] := -50;  LB.i[7] := -60;

  LVecByDispatch := LDispatch^.AddI64x8(LA, LB);
  LVecByScalar := ScalarAddI64x8(LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Scalar AddI64x8 lane' + IntToStr(LIndex), LVecByScalar.i[LIndex], LVecByDispatch.i[LIndex]);

  LVecByDispatch := LDispatch^.SubI64x8(LA, LB);
  LVecByScalar := ScalarSubI64x8(LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Scalar SubI64x8 lane' + IntToStr(LIndex), LVecByScalar.i[LIndex], LVecByDispatch.i[LIndex]);

  LVecByDispatch := LDispatch^.AndI64x8(LA, LB);
  LVecByScalar := ScalarAndI64x8(LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Scalar AndI64x8 lane' + IntToStr(LIndex), LVecByScalar.i[LIndex], LVecByDispatch.i[LIndex]);

  LVecByDispatch := LDispatch^.OrI64x8(LA, LB);
  LVecByScalar := ScalarOrI64x8(LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Scalar OrI64x8 lane' + IntToStr(LIndex), LVecByScalar.i[LIndex], LVecByDispatch.i[LIndex]);

  LVecByDispatch := LDispatch^.XorI64x8(LA, LB);
  LVecByScalar := ScalarXorI64x8(LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Scalar XorI64x8 lane' + IntToStr(LIndex), LVecByScalar.i[LIndex], LVecByDispatch.i[LIndex]);

  LVecByDispatch := LDispatch^.NotI64x8(LA);
  LVecByScalar := ScalarNotI64x8(LA);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Scalar NotI64x8 lane' + IntToStr(LIndex), LVecByScalar.i[LIndex], LVecByDispatch.i[LIndex]);

  LMaskByDispatch := LDispatch^.CmpEqI64x8(LA, LB);
  LMaskByScalar := ScalarCmpEqI64x8(LA, LB);
  AssertEquals('Dispatch/Scalar CmpEqI64x8 parity', Integer(LMaskByScalar), Integer(LMaskByDispatch));

  LMaskByDispatch := LDispatch^.CmpLtI64x8(LA, LB);
  LMaskByScalar := ScalarCmpLtI64x8(LA, LB);
  AssertEquals('Dispatch/Scalar CmpLtI64x8 parity', Integer(LMaskByScalar), Integer(LMaskByDispatch));

  LMaskByDispatch := LDispatch^.CmpGtI64x8(LA, LB);
  LMaskByScalar := ScalarCmpGtI64x8(LA, LB);
  AssertEquals('Dispatch/Scalar CmpGtI64x8 parity', Integer(LMaskByScalar), Integer(LMaskByDispatch));

  LMaskByDispatch := LDispatch^.CmpLeI64x8(LA, LB);
  LMaskByScalar := ScalarCmpLeI64x8(LA, LB);
  AssertEquals('Dispatch/Scalar CmpLeI64x8 parity', Integer(LMaskByScalar), Integer(LMaskByDispatch));

  LMaskByDispatch := LDispatch^.CmpGeI64x8(LA, LB);
  LMaskByScalar := ScalarCmpGeI64x8(LA, LB);
  AssertEquals('Dispatch/Scalar CmpGeI64x8 parity', Integer(LMaskByScalar), Integer(LMaskByDispatch));

  LMaskByDispatch := LDispatch^.CmpNeI64x8(LA, LB);
  LMaskByScalar := ScalarCmpNeI64x8(LA, LB);
  AssertEquals('Dispatch/Scalar CmpNeI64x8 parity', Integer(LMaskByScalar), Integer(LMaskByDispatch));
end;


procedure TTestCase_DispatchAPI.Test_VecF32x16_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB, LC: TVecF32x16;
  LMask: TMask16;
  LByDispatch, LByFacade: TVecF32x16;
  LSource, LStoredDispatch, LStoredFacade: array[0..15] of Single;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.LoadF32x16 should be assigned', Assigned(LDispatch^.LoadF32x16));
  AssertTrue('Dispatch.StoreF32x16 should be assigned', Assigned(LDispatch^.StoreF32x16));
  AssertTrue('Dispatch.SplatF32x16 should be assigned', Assigned(LDispatch^.SplatF32x16));
  AssertTrue('Dispatch.ZeroF32x16 should be assigned', Assigned(LDispatch^.ZeroF32x16));
  AssertTrue('Dispatch.SelectF32x16 should be assigned', Assigned(LDispatch^.SelectF32x16));
  AssertTrue('Dispatch.ClampF32x16 should be assigned', Assigned(LDispatch^.ClampF32x16));
  AssertTrue('Dispatch.FmaF32x16 should be assigned', Assigned(LDispatch^.FmaF32x16));
  AssertTrue('Dispatch.FloorF32x16 should be assigned', Assigned(LDispatch^.FloorF32x16));
  AssertTrue('Dispatch.CeilF32x16 should be assigned', Assigned(LDispatch^.CeilF32x16));
  AssertTrue('Dispatch.RoundF32x16 should be assigned', Assigned(LDispatch^.RoundF32x16));
  AssertTrue('Dispatch.TruncF32x16 should be assigned', Assigned(LDispatch^.TruncF32x16));

  for LIndex := 0 to 15 do
  begin
    LA.f[LIndex] := LIndex + 0.25;
    LB.f[LIndex] := 2.0;
    LC.f[LIndex] := 1.0;
    LSource[LIndex] := LIndex + 0.5;
  end;

  LByDispatch := LDispatch^.FmaF32x16(LA, LB, LC);
  LByFacade := VecF32x16Fma(LA, LB, LC);
  for LIndex := 0 to 15 do
    AssertEquals('Dispatch/Facade FmaF32x16 lane ' + IntToStr(LIndex),
      LByDispatch.f[LIndex], LByFacade.f[LIndex], 0.0001);

  LByDispatch := LDispatch^.ClampF32x16(LByDispatch, LDispatch^.SplatF32x16(3.0), LDispatch^.SplatF32x16(20.0));
  LByFacade := VecF32x16Clamp(LByFacade, VecF32x16Splat(3.0), VecF32x16Splat(20.0));
  for LIndex := 0 to 15 do
    AssertEquals('Dispatch/Facade ClampF32x16 lane ' + IntToStr(LIndex),
      LByDispatch.f[LIndex], LByFacade.f[LIndex], 0.0001);

  LMask := TMask16($5555);
  LByDispatch := LDispatch^.SelectF32x16(LMask, LA, LB);
  LByFacade := VecF32x16Select(LMask, LA, LB);
  for LIndex := 0 to 15 do
    AssertEquals('Dispatch/Facade SelectF32x16 lane ' + IntToStr(LIndex),
      LByDispatch.f[LIndex], LByFacade.f[LIndex], 0.0001);

  LByDispatch := LDispatch^.LoadF32x16(@LSource[0]);
  LByFacade := VecF32x16Load(@LSource[0]);
  for LIndex := 0 to 15 do
    AssertEquals('Dispatch/Facade LoadF32x16 lane ' + IntToStr(LIndex),
      LByDispatch.f[LIndex], LByFacade.f[LIndex], 0.0001);

  LDispatch^.StoreF32x16(@LStoredDispatch[0], LByDispatch);
  VecF32x16Store(@LStoredFacade[0], LByFacade);
  for LIndex := 0 to 15 do
    AssertEquals('Dispatch/Facade StoreF32x16 lane ' + IntToStr(LIndex),
      LStoredDispatch[LIndex], LStoredFacade[LIndex], 0.0001);
end;

procedure TTestCase_DispatchAPI.Test_VecF64x8_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB, LC: TVecF64x8;
  LMask: TMask8;
  LByDispatch, LByFacade: TVecF64x8;
  LSource, LStoredDispatch, LStoredFacade: array[0..7] of Double;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.LoadF64x8 should be assigned', Assigned(LDispatch^.LoadF64x8));
  AssertTrue('Dispatch.StoreF64x8 should be assigned', Assigned(LDispatch^.StoreF64x8));
  AssertTrue('Dispatch.SplatF64x8 should be assigned', Assigned(LDispatch^.SplatF64x8));
  AssertTrue('Dispatch.ZeroF64x8 should be assigned', Assigned(LDispatch^.ZeroF64x8));
  AssertTrue('Dispatch.SelectF64x8 should be assigned', Assigned(LDispatch^.SelectF64x8));
  AssertTrue('Dispatch.ClampF64x8 should be assigned', Assigned(LDispatch^.ClampF64x8));
  AssertTrue('Dispatch.FmaF64x8 should be assigned', Assigned(LDispatch^.FmaF64x8));
  AssertTrue('Dispatch.FloorF64x8 should be assigned', Assigned(LDispatch^.FloorF64x8));
  AssertTrue('Dispatch.CeilF64x8 should be assigned', Assigned(LDispatch^.CeilF64x8));
  AssertTrue('Dispatch.RoundF64x8 should be assigned', Assigned(LDispatch^.RoundF64x8));
  AssertTrue('Dispatch.TruncF64x8 should be assigned', Assigned(LDispatch^.TruncF64x8));

  for LIndex := 0 to 7 do
  begin
    LA.d[LIndex] := LIndex + 0.5;
    LB.d[LIndex] := 3.0;
    LC.d[LIndex] := 2.0;
    LSource[LIndex] := LIndex + 0.125;
  end;

  LByDispatch := LDispatch^.FmaF64x8(LA, LB, LC);
  LByFacade := VecF64x8Fma(LA, LB, LC);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Facade FmaF64x8 lane ' + IntToStr(LIndex),
      LByDispatch.d[LIndex], LByFacade.d[LIndex], 0.000001);

  LByDispatch := LDispatch^.ClampF64x8(LByDispatch, LDispatch^.SplatF64x8(4.0), LDispatch^.SplatF64x8(20.0));
  LByFacade := VecF64x8Clamp(LByFacade, VecF64x8Splat(4.0), VecF64x8Splat(20.0));
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Facade ClampF64x8 lane ' + IntToStr(LIndex),
      LByDispatch.d[LIndex], LByFacade.d[LIndex], 0.000001);

  LMask := TMask8($55);
  LByDispatch := LDispatch^.SelectF64x8(LMask, LA, LB);
  LByFacade := VecF64x8Select(LMask, LA, LB);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Facade SelectF64x8 lane ' + IntToStr(LIndex),
      LByDispatch.d[LIndex], LByFacade.d[LIndex], 0.000001);

  LByDispatch := LDispatch^.LoadF64x8(@LSource[0]);
  LByFacade := VecF64x8Load(@LSource[0]);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Facade LoadF64x8 lane ' + IntToStr(LIndex),
      LByDispatch.d[LIndex], LByFacade.d[LIndex], 0.000001);

  LDispatch^.StoreF64x8(@LStoredDispatch[0], LByDispatch);
  VecF64x8Store(@LStoredFacade[0], LByFacade);
  for LIndex := 0 to 7 do
    AssertEquals('Dispatch/Facade StoreF64x8 lane ' + IntToStr(LIndex),
      LStoredDispatch[LIndex], LStoredFacade[LIndex], 0.000001);
end;


procedure TTestCase_DispatchAPI.Test_VecU32x16_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecU32x16;
  LVecDispatch, LVecFacade, LVecScalar: TVecU32x16;
  LMaskDispatch, LMaskScalar: TMask16;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddU32x16 should be assigned', Assigned(LDispatch^.AddU32x16));
  AssertTrue('Dispatch.SubU32x16 should be assigned', Assigned(LDispatch^.SubU32x16));
  AssertTrue('Dispatch.MulU32x16 should be assigned', Assigned(LDispatch^.MulU32x16));
  AssertTrue('Dispatch.AndU32x16 should be assigned', Assigned(LDispatch^.AndU32x16));
  AssertTrue('Dispatch.OrU32x16 should be assigned', Assigned(LDispatch^.OrU32x16));
  AssertTrue('Dispatch.XorU32x16 should be assigned', Assigned(LDispatch^.XorU32x16));
  AssertTrue('Dispatch.NotU32x16 should be assigned', Assigned(LDispatch^.NotU32x16));
  AssertTrue('Dispatch.AndNotU32x16 should be assigned', Assigned(LDispatch^.AndNotU32x16));
  AssertTrue('Dispatch.ShiftLeftU32x16 should be assigned', Assigned(LDispatch^.ShiftLeftU32x16));
  AssertTrue('Dispatch.ShiftRightU32x16 should be assigned', Assigned(LDispatch^.ShiftRightU32x16));
  AssertTrue('Dispatch.CmpEqU32x16 should be assigned', Assigned(LDispatch^.CmpEqU32x16));
  AssertTrue('Dispatch.CmpLtU32x16 should be assigned', Assigned(LDispatch^.CmpLtU32x16));
  AssertTrue('Dispatch.CmpGtU32x16 should be assigned', Assigned(LDispatch^.CmpGtU32x16));
  AssertTrue('Dispatch.CmpLeU32x16 should be assigned', Assigned(LDispatch^.CmpLeU32x16));
  AssertTrue('Dispatch.CmpGeU32x16 should be assigned', Assigned(LDispatch^.CmpGeU32x16));
  AssertTrue('Dispatch.CmpNeU32x16 should be assigned', Assigned(LDispatch^.CmpNeU32x16));
  AssertTrue('Dispatch.MinU32x16 should be assigned', Assigned(LDispatch^.MinU32x16));
  AssertTrue('Dispatch.MaxU32x16 should be assigned', Assigned(LDispatch^.MaxU32x16));

  for LIndex := 0 to 15 do
  begin
    LA.u[LIndex] := DWord(LIndex) * 17 + 1;
    LB.u[LIndex] := DWord(300 - LIndex * 7);
  end;

  LVecDispatch := LDispatch^.AddU32x16(LA, LB);
  LVecFacade := VecU32x16Add(LA, LB);
  LVecScalar := ScalarAddU32x16(LA, LB);
  for LIndex := 0 to 15 do
  begin
    AssertEquals('Dispatch/Facade AddU32x16 lane ' + IntToStr(LIndex), LVecDispatch.u[LIndex], LVecFacade.u[LIndex]);
    AssertEquals('Dispatch/Scalar AddU32x16 lane ' + IntToStr(LIndex), LVecDispatch.u[LIndex], LVecScalar.u[LIndex]);
  end;

  LVecDispatch := LDispatch^.ShiftRightU32x16(LA, 3);
  LVecFacade := VecU32x16ShiftRight(LA, 3);
  for LIndex := 0 to 15 do
    AssertEquals('Dispatch/Facade ShiftRightU32x16 lane ' + IntToStr(LIndex), LVecDispatch.u[LIndex], LVecFacade.u[LIndex]);

  LMaskDispatch := LDispatch^.CmpLeU32x16(LA, LB);
  LMaskScalar := ScalarCmpLeU32x16(LA, LB);
  AssertEquals('Dispatch/Scalar CmpLeU32x16 parity', Integer(LMaskScalar), Integer(LMaskDispatch));
end;

procedure TTestCase_DispatchAPI.Test_VecU64x8_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecU64x8;
  LVecDispatch, LVecFacade, LVecScalar: TVecU64x8;
  LMaskDispatch, LMaskScalar: TMask8;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddU64x8 should be assigned', Assigned(LDispatch^.AddU64x8));
  AssertTrue('Dispatch.SubU64x8 should be assigned', Assigned(LDispatch^.SubU64x8));
  AssertTrue('Dispatch.AndU64x8 should be assigned', Assigned(LDispatch^.AndU64x8));
  AssertTrue('Dispatch.OrU64x8 should be assigned', Assigned(LDispatch^.OrU64x8));
  AssertTrue('Dispatch.XorU64x8 should be assigned', Assigned(LDispatch^.XorU64x8));
  AssertTrue('Dispatch.NotU64x8 should be assigned', Assigned(LDispatch^.NotU64x8));
  AssertTrue('Dispatch.ShiftLeftU64x8 should be assigned', Assigned(LDispatch^.ShiftLeftU64x8));
  AssertTrue('Dispatch.ShiftRightU64x8 should be assigned', Assigned(LDispatch^.ShiftRightU64x8));
  AssertTrue('Dispatch.CmpEqU64x8 should be assigned', Assigned(LDispatch^.CmpEqU64x8));
  AssertTrue('Dispatch.CmpLtU64x8 should be assigned', Assigned(LDispatch^.CmpLtU64x8));
  AssertTrue('Dispatch.CmpGtU64x8 should be assigned', Assigned(LDispatch^.CmpGtU64x8));
  AssertTrue('Dispatch.CmpLeU64x8 should be assigned', Assigned(LDispatch^.CmpLeU64x8));
  AssertTrue('Dispatch.CmpGeU64x8 should be assigned', Assigned(LDispatch^.CmpGeU64x8));
  AssertTrue('Dispatch.CmpNeU64x8 should be assigned', Assigned(LDispatch^.CmpNeU64x8));

  for LIndex := 0 to 7 do
  begin
    LA.u[LIndex] := QWord($FFFFFFFF00000000) + QWord(LIndex);
    LB.u[LIndex] := QWord(LIndex) * 33;
  end;

  LVecDispatch := LDispatch^.XorU64x8(LA, LB);
  LVecFacade := VecU64x8Xor(LA, LB);
  LVecScalar := ScalarXorU64x8(LA, LB);
  for LIndex := 0 to 7 do
  begin
    AssertEquals('Dispatch/Facade XorU64x8 lane ' + IntToStr(LIndex), LVecDispatch.u[LIndex], LVecFacade.u[LIndex]);
    AssertEquals('Dispatch/Scalar XorU64x8 lane ' + IntToStr(LIndex), LVecDispatch.u[LIndex], LVecScalar.u[LIndex]);
  end;

  LMaskDispatch := LDispatch^.CmpGtU64x8(LA, LB);
  LMaskScalar := ScalarCmpGtU64x8(LA, LB);
  AssertEquals('Dispatch/Scalar CmpGtU64x8 parity', Integer(LMaskScalar), Integer(LMaskDispatch));
end;

procedure TTestCase_DispatchAPI.Test_VecI16x32_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecI16x32;
  LVecDispatch, LVecFacade, LVecScalar: TVecI16x32;
  LMaskDispatch, LMaskScalar: TMask32;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddI16x32 should be assigned', Assigned(LDispatch^.AddI16x32));
  AssertTrue('Dispatch.SubI16x32 should be assigned', Assigned(LDispatch^.SubI16x32));
  AssertTrue('Dispatch.AndI16x32 should be assigned', Assigned(LDispatch^.AndI16x32));
  AssertTrue('Dispatch.OrI16x32 should be assigned', Assigned(LDispatch^.OrI16x32));
  AssertTrue('Dispatch.XorI16x32 should be assigned', Assigned(LDispatch^.XorI16x32));
  AssertTrue('Dispatch.NotI16x32 should be assigned', Assigned(LDispatch^.NotI16x32));
  AssertTrue('Dispatch.AndNotI16x32 should be assigned', Assigned(LDispatch^.AndNotI16x32));
  AssertTrue('Dispatch.ShiftLeftI16x32 should be assigned', Assigned(LDispatch^.ShiftLeftI16x32));
  AssertTrue('Dispatch.ShiftRightI16x32 should be assigned', Assigned(LDispatch^.ShiftRightI16x32));
  AssertTrue('Dispatch.ShiftRightArithI16x32 should be assigned', Assigned(LDispatch^.ShiftRightArithI16x32));
  AssertTrue('Dispatch.CmpEqI16x32 should be assigned', Assigned(LDispatch^.CmpEqI16x32));
  AssertTrue('Dispatch.CmpLtI16x32 should be assigned', Assigned(LDispatch^.CmpLtI16x32));
  AssertTrue('Dispatch.CmpGtI16x32 should be assigned', Assigned(LDispatch^.CmpGtI16x32));
  AssertTrue('Dispatch.MinI16x32 should be assigned', Assigned(LDispatch^.MinI16x32));
  AssertTrue('Dispatch.MaxI16x32 should be assigned', Assigned(LDispatch^.MaxI16x32));

  for LIndex := 0 to 31 do
  begin
    LA.i[LIndex] := SmallInt(LIndex - 16);
    LB.i[LIndex] := SmallInt(8 - LIndex);
  end;

  LVecDispatch := LDispatch^.SubI16x32(LA, LB);
  LVecFacade := VecI16x32Sub(LA, LB);
  LVecScalar := ScalarSubI16x32(LA, LB);
  for LIndex := 0 to 31 do
  begin
    AssertEquals('Dispatch/Facade SubI16x32 lane ' + IntToStr(LIndex), LVecDispatch.i[LIndex], LVecFacade.i[LIndex]);
    AssertEquals('Dispatch/Scalar SubI16x32 lane ' + IntToStr(LIndex), LVecDispatch.i[LIndex], LVecScalar.i[LIndex]);
  end;

  LMaskDispatch := LDispatch^.CmpLtI16x32(LA, LB);
  LMaskScalar := ScalarCmpLtI16x32(LA, LB);
  AssertEquals('Dispatch/Scalar CmpLtI16x32 parity', LongInt(LMaskScalar), LongInt(LMaskDispatch));
end;

procedure TTestCase_DispatchAPI.Test_VecI8x64_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecI8x64;
  LVecDispatch, LVecFacade, LVecScalar: TVecI8x64;
  LMaskDispatch, LMaskScalar: TMask64;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddI8x64 should be assigned', Assigned(LDispatch^.AddI8x64));
  AssertTrue('Dispatch.SubI8x64 should be assigned', Assigned(LDispatch^.SubI8x64));
  AssertTrue('Dispatch.AndI8x64 should be assigned', Assigned(LDispatch^.AndI8x64));
  AssertTrue('Dispatch.OrI8x64 should be assigned', Assigned(LDispatch^.OrI8x64));
  AssertTrue('Dispatch.XorI8x64 should be assigned', Assigned(LDispatch^.XorI8x64));
  AssertTrue('Dispatch.NotI8x64 should be assigned', Assigned(LDispatch^.NotI8x64));
  AssertTrue('Dispatch.AndNotI8x64 should be assigned', Assigned(LDispatch^.AndNotI8x64));
  AssertTrue('Dispatch.CmpEqI8x64 should be assigned', Assigned(LDispatch^.CmpEqI8x64));
  AssertTrue('Dispatch.CmpLtI8x64 should be assigned', Assigned(LDispatch^.CmpLtI8x64));
  AssertTrue('Dispatch.CmpGtI8x64 should be assigned', Assigned(LDispatch^.CmpGtI8x64));
  AssertTrue('Dispatch.MinI8x64 should be assigned', Assigned(LDispatch^.MinI8x64));
  AssertTrue('Dispatch.MaxI8x64 should be assigned', Assigned(LDispatch^.MaxI8x64));

  for LIndex := 0 to 63 do
  begin
    LA.i[LIndex] := ShortInt((LIndex mod 40) - 20);
    LB.i[LIndex] := ShortInt((20 - LIndex) mod 37);
  end;

  LVecDispatch := LDispatch^.AndNotI8x64(LA, LB);
  LVecFacade := VecI8x64AndNot(LA, LB);
  LVecScalar := ScalarAndNotI8x64(LA, LB);
  for LIndex := 0 to 63 do
  begin
    AssertEquals('Dispatch/Facade AndNotI8x64 lane ' + IntToStr(LIndex), LVecDispatch.i[LIndex], LVecFacade.i[LIndex]);
    AssertEquals('Dispatch/Scalar AndNotI8x64 lane ' + IntToStr(LIndex), LVecDispatch.i[LIndex], LVecScalar.i[LIndex]);
  end;

  LMaskDispatch := LDispatch^.CmpEqI8x64(LA, LB);
  LMaskScalar := ScalarCmpEqI8x64(LA, LB);
  AssertEquals('Dispatch/Scalar CmpEqI8x64 parity', QWord(LMaskScalar), QWord(LMaskDispatch));
end;

procedure TTestCase_DispatchAPI.Test_VecU8x64_DispatchAssigned_And_Parity;
var
  LDispatch: PSimdDispatchTable;
  LA, LB: TVecU8x64;
  LVecDispatch, LVecFacade, LVecScalar: TVecU8x64;
  LMaskDispatch, LMaskScalar: TMask64;
  LIndex: Integer;
begin
  LDispatch := GetDispatchTable;
  AssertNotNull('Dispatch table should be available', LDispatch);

  AssertTrue('Dispatch.AddU8x64 should be assigned', Assigned(LDispatch^.AddU8x64));
  AssertTrue('Dispatch.SubU8x64 should be assigned', Assigned(LDispatch^.SubU8x64));
  AssertTrue('Dispatch.AndU8x64 should be assigned', Assigned(LDispatch^.AndU8x64));
  AssertTrue('Dispatch.OrU8x64 should be assigned', Assigned(LDispatch^.OrU8x64));
  AssertTrue('Dispatch.XorU8x64 should be assigned', Assigned(LDispatch^.XorU8x64));
  AssertTrue('Dispatch.NotU8x64 should be assigned', Assigned(LDispatch^.NotU8x64));
  AssertTrue('Dispatch.CmpEqU8x64 should be assigned', Assigned(LDispatch^.CmpEqU8x64));
  AssertTrue('Dispatch.CmpLtU8x64 should be assigned', Assigned(LDispatch^.CmpLtU8x64));
  AssertTrue('Dispatch.CmpGtU8x64 should be assigned', Assigned(LDispatch^.CmpGtU8x64));
  AssertTrue('Dispatch.MinU8x64 should be assigned', Assigned(LDispatch^.MinU8x64));
  AssertTrue('Dispatch.MaxU8x64 should be assigned', Assigned(LDispatch^.MaxU8x64));

  for LIndex := 0 to 63 do
  begin
    LA.u[LIndex] := Byte((LIndex * 3) and $FF);
    LB.u[LIndex] := Byte((255 - LIndex * 2) and $FF);
  end;

  LVecDispatch := LDispatch^.MaxU8x64(LA, LB);
  LVecFacade := VecU8x64Max(LA, LB);
  LVecScalar := ScalarMaxU8x64(LA, LB);
  for LIndex := 0 to 63 do
  begin
    AssertEquals('Dispatch/Facade MaxU8x64 lane ' + IntToStr(LIndex), LVecDispatch.u[LIndex], LVecFacade.u[LIndex]);
    AssertEquals('Dispatch/Scalar MaxU8x64 lane ' + IntToStr(LIndex), LVecDispatch.u[LIndex], LVecScalar.u[LIndex]);
  end;

  LMaskDispatch := LDispatch^.CmpGtU8x64(LA, LB);
  LMaskScalar := ScalarCmpGtU8x64(LA, LB);
  AssertEquals('Dispatch/Scalar CmpGtU8x64 parity', QWord(LMaskScalar), QWord(LMaskDispatch));
end;

procedure TTestCase_DispatchAPI.Test_WideFamilies_FacadeScalar_Parity_Completeness;
var
  LIndex: Integer;

  LU32A, LU32B: TVecU32x16;
  LU32ByFacade, LU32ByScalar: TVecU32x16;
  LMask16Facade, LMask16Scalar: TMask16;

  LU64A, LU64B: TVecU64x8;
  LU64ByFacade, LU64ByScalar: TVecU64x8;
  LMask8Facade, LMask8Scalar: TMask8;

  LI16A, LI16B: TVecI16x32;
  LI16ByFacade, LI16ByScalar: TVecI16x32;
  LMask32Facade, LMask32Scalar: TMask32;

  LI8A, LI8B: TVecI8x64;
  LI8ByFacade, LI8ByScalar: TVecI8x64;
  LMask64Facade, LMask64Scalar: TMask64;

  LU8A, LU8B: TVecU8x64;
  LU8ByFacade, LU8ByScalar: TVecU8x64;

  procedure AssertVecU32x16Equal(const aOp: string; const aExpected, aActual: TVecU32x16);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 15 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.u[LLane], aActual.u[LLane]);
  end;

  procedure AssertVecU64x8Equal(const aOp: string; const aExpected, aActual: TVecU64x8);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.u[LLane], aActual.u[LLane]);
  end;

  procedure AssertVecI16x32Equal(const aOp: string; const aExpected, aActual: TVecI16x32);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 31 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecI8x64Equal(const aOp: string; const aExpected, aActual: TVecI8x64);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 63 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecU8x64Equal(const aOp: string; const aExpected, aActual: TVecU8x64);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 63 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.u[LLane], aActual.u[LLane]);
  end;
begin
  for LIndex := 0 to 15 do
  begin
    LU32A.u[LIndex] := DWord($10000000 + LIndex * 12345);
    LU32B.u[LIndex] := DWord((15 - LIndex) * 54321 + 7);
  end;

  LU32ByFacade := VecU32x16Add(LU32A, LU32B);
  LU32ByScalar := ScalarAddU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16Add', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16Sub(LU32A, LU32B);
  LU32ByScalar := ScalarSubU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16Sub', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16Mul(LU32A, LU32B);
  LU32ByScalar := ScalarMulU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16Mul', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16And(LU32A, LU32B);
  LU32ByScalar := ScalarAndU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16And', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16Or(LU32A, LU32B);
  LU32ByScalar := ScalarOrU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16Or', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16Xor(LU32A, LU32B);
  LU32ByScalar := ScalarXorU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16Xor', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16Not(LU32A);
  LU32ByScalar := ScalarNotU32x16(LU32A);
  AssertVecU32x16Equal('VecU32x16Not', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16AndNot(LU32A, LU32B);
  LU32ByScalar := ScalarAndNotU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16AndNot', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16ShiftLeft(LU32A, 5);
  LU32ByScalar := ScalarShiftLeftU32x16(LU32A, 5);
  AssertVecU32x16Equal('VecU32x16ShiftLeft', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16ShiftRight(LU32A, 3);
  LU32ByScalar := ScalarShiftRightU32x16(LU32A, 3);
  AssertVecU32x16Equal('VecU32x16ShiftRight', LU32ByScalar, LU32ByFacade);

  LMask16Facade := VecU32x16CmpEq(LU32A, LU32B);
  LMask16Scalar := ScalarCmpEqU32x16(LU32A, LU32B);
  AssertEquals('VecU32x16CmpEq', Integer(LMask16Scalar), Integer(LMask16Facade));

  LMask16Facade := VecU32x16CmpLt(LU32A, LU32B);
  LMask16Scalar := ScalarCmpLtU32x16(LU32A, LU32B);
  AssertEquals('VecU32x16CmpLt', Integer(LMask16Scalar), Integer(LMask16Facade));

  LMask16Facade := VecU32x16CmpGt(LU32A, LU32B);
  LMask16Scalar := ScalarCmpGtU32x16(LU32A, LU32B);
  AssertEquals('VecU32x16CmpGt', Integer(LMask16Scalar), Integer(LMask16Facade));

  LMask16Facade := VecU32x16CmpLe(LU32A, LU32B);
  LMask16Scalar := ScalarCmpLeU32x16(LU32A, LU32B);
  AssertEquals('VecU32x16CmpLe', Integer(LMask16Scalar), Integer(LMask16Facade));

  LMask16Facade := VecU32x16CmpGe(LU32A, LU32B);
  LMask16Scalar := ScalarCmpGeU32x16(LU32A, LU32B);
  AssertEquals('VecU32x16CmpGe', Integer(LMask16Scalar), Integer(LMask16Facade));

  LMask16Facade := VecU32x16CmpNe(LU32A, LU32B);
  LMask16Scalar := ScalarCmpNeU32x16(LU32A, LU32B);
  AssertEquals('VecU32x16CmpNe', Integer(LMask16Scalar), Integer(LMask16Facade));

  LU32ByFacade := VecU32x16Min(LU32A, LU32B);
  LU32ByScalar := ScalarMinU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16Min', LU32ByScalar, LU32ByFacade);

  LU32ByFacade := VecU32x16Max(LU32A, LU32B);
  LU32ByScalar := ScalarMaxU32x16(LU32A, LU32B);
  AssertVecU32x16Equal('VecU32x16Max', LU32ByScalar, LU32ByFacade);

  for LIndex := 0 to 7 do
  begin
    LU64A.u[LIndex] := QWord($F000000000000000) or (QWord(LIndex + 1) * QWord($0102030405060708));
    LU64B.u[LIndex] := QWord(17 + LIndex * 1234567);
  end;

  LU64ByFacade := VecU64x8Add(LU64A, LU64B);
  LU64ByScalar := ScalarAddU64x8(LU64A, LU64B);
  AssertVecU64x8Equal('VecU64x8Add', LU64ByScalar, LU64ByFacade);

  LU64ByFacade := VecU64x8Sub(LU64A, LU64B);
  LU64ByScalar := ScalarSubU64x8(LU64A, LU64B);
  AssertVecU64x8Equal('VecU64x8Sub', LU64ByScalar, LU64ByFacade);

  LU64ByFacade := VecU64x8And(LU64A, LU64B);
  LU64ByScalar := ScalarAndU64x8(LU64A, LU64B);
  AssertVecU64x8Equal('VecU64x8And', LU64ByScalar, LU64ByFacade);

  LU64ByFacade := VecU64x8Or(LU64A, LU64B);
  LU64ByScalar := ScalarOrU64x8(LU64A, LU64B);
  AssertVecU64x8Equal('VecU64x8Or', LU64ByScalar, LU64ByFacade);

  LU64ByFacade := VecU64x8Xor(LU64A, LU64B);
  LU64ByScalar := ScalarXorU64x8(LU64A, LU64B);
  AssertVecU64x8Equal('VecU64x8Xor', LU64ByScalar, LU64ByFacade);

  LU64ByFacade := VecU64x8Not(LU64A);
  LU64ByScalar := ScalarNotU64x8(LU64A);
  AssertVecU64x8Equal('VecU64x8Not', LU64ByScalar, LU64ByFacade);

  LU64ByFacade := VecU64x8ShiftLeft(LU64A, 7);
  LU64ByScalar := ScalarShiftLeftU64x8(LU64A, 7);
  AssertVecU64x8Equal('VecU64x8ShiftLeft', LU64ByScalar, LU64ByFacade);

  LU64ByFacade := VecU64x8ShiftRight(LU64A, 9);
  LU64ByScalar := ScalarShiftRightU64x8(LU64A, 9);
  AssertVecU64x8Equal('VecU64x8ShiftRight', LU64ByScalar, LU64ByFacade);

  LMask8Facade := VecU64x8CmpEq(LU64A, LU64B);
  LMask8Scalar := ScalarCmpEqU64x8(LU64A, LU64B);
  AssertEquals('VecU64x8CmpEq', Integer(LMask8Scalar), Integer(LMask8Facade));

  LMask8Facade := VecU64x8CmpLt(LU64A, LU64B);
  LMask8Scalar := ScalarCmpLtU64x8(LU64A, LU64B);
  AssertEquals('VecU64x8CmpLt', Integer(LMask8Scalar), Integer(LMask8Facade));

  LMask8Facade := VecU64x8CmpGt(LU64A, LU64B);
  LMask8Scalar := ScalarCmpGtU64x8(LU64A, LU64B);
  AssertEquals('VecU64x8CmpGt', Integer(LMask8Scalar), Integer(LMask8Facade));

  LMask8Facade := VecU64x8CmpLe(LU64A, LU64B);
  LMask8Scalar := ScalarCmpLeU64x8(LU64A, LU64B);
  AssertEquals('VecU64x8CmpLe', Integer(LMask8Scalar), Integer(LMask8Facade));

  LMask8Facade := VecU64x8CmpGe(LU64A, LU64B);
  LMask8Scalar := ScalarCmpGeU64x8(LU64A, LU64B);
  AssertEquals('VecU64x8CmpGe', Integer(LMask8Scalar), Integer(LMask8Facade));

  LMask8Facade := VecU64x8CmpNe(LU64A, LU64B);
  LMask8Scalar := ScalarCmpNeU64x8(LU64A, LU64B);
  AssertEquals('VecU64x8CmpNe', Integer(LMask8Scalar), Integer(LMask8Facade));

  for LIndex := 0 to 31 do
  begin
    LI16A.i[LIndex] := SmallInt(LIndex * 5 - 70);
    LI16B.i[LIndex] := SmallInt(90 - LIndex * 3);
  end;

  LI16ByFacade := VecI16x32Add(LI16A, LI16B);
  LI16ByScalar := ScalarAddI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32Add', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32Sub(LI16A, LI16B);
  LI16ByScalar := ScalarSubI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32Sub', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32And(LI16A, LI16B);
  LI16ByScalar := ScalarAndI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32And', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32Or(LI16A, LI16B);
  LI16ByScalar := ScalarOrI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32Or', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32Xor(LI16A, LI16B);
  LI16ByScalar := ScalarXorI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32Xor', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32Not(LI16A);
  LI16ByScalar := ScalarNotI16x32(LI16A);
  AssertVecI16x32Equal('VecI16x32Not', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32AndNot(LI16A, LI16B);
  LI16ByScalar := ScalarAndNotI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32AndNot', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32ShiftLeft(LI16A, 3);
  LI16ByScalar := ScalarShiftLeftI16x32(LI16A, 3);
  AssertVecI16x32Equal('VecI16x32ShiftLeft', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32ShiftRight(LI16A, 2);
  LI16ByScalar := ScalarShiftRightI16x32(LI16A, 2);
  AssertVecI16x32Equal('VecI16x32ShiftRight', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32ShiftRightArith(LI16A, 2);
  LI16ByScalar := ScalarShiftRightArithI16x32(LI16A, 2);
  AssertVecI16x32Equal('VecI16x32ShiftRightArith', LI16ByScalar, LI16ByFacade);

  LMask32Facade := VecI16x32CmpEq(LI16A, LI16B);
  LMask32Scalar := ScalarCmpEqI16x32(LI16A, LI16B);
  AssertEquals('VecI16x32CmpEq', LongInt(LMask32Scalar), LongInt(LMask32Facade));

  LMask32Facade := VecI16x32CmpLt(LI16A, LI16B);
  LMask32Scalar := ScalarCmpLtI16x32(LI16A, LI16B);
  AssertEquals('VecI16x32CmpLt', LongInt(LMask32Scalar), LongInt(LMask32Facade));

  LMask32Facade := VecI16x32CmpGt(LI16A, LI16B);
  LMask32Scalar := ScalarCmpGtI16x32(LI16A, LI16B);
  AssertEquals('VecI16x32CmpGt', LongInt(LMask32Scalar), LongInt(LMask32Facade));

  LI16ByFacade := VecI16x32Min(LI16A, LI16B);
  LI16ByScalar := ScalarMinI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32Min', LI16ByScalar, LI16ByFacade);

  LI16ByFacade := VecI16x32Max(LI16A, LI16B);
  LI16ByScalar := ScalarMaxI16x32(LI16A, LI16B);
  AssertVecI16x32Equal('VecI16x32Max', LI16ByScalar, LI16ByFacade);

  for LIndex := 0 to 63 do
  begin
    LI8A.i[LIndex] := ShortInt((LIndex mod 41) - 20);
    LI8B.i[LIndex] := ShortInt(15 - (LIndex mod 31));
    LU8A.u[LIndex] := Byte((LIndex * 11 + 3) and $FF);
    LU8B.u[LIndex] := Byte((255 - LIndex * 7) and $FF);
  end;

  LI8ByFacade := VecI8x64Add(LI8A, LI8B);
  LI8ByScalar := ScalarAddI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64Add', LI8ByScalar, LI8ByFacade);

  LI8ByFacade := VecI8x64Sub(LI8A, LI8B);
  LI8ByScalar := ScalarSubI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64Sub', LI8ByScalar, LI8ByFacade);

  LI8ByFacade := VecI8x64And(LI8A, LI8B);
  LI8ByScalar := ScalarAndI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64And', LI8ByScalar, LI8ByFacade);

  LI8ByFacade := VecI8x64Or(LI8A, LI8B);
  LI8ByScalar := ScalarOrI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64Or', LI8ByScalar, LI8ByFacade);

  LI8ByFacade := VecI8x64Xor(LI8A, LI8B);
  LI8ByScalar := ScalarXorI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64Xor', LI8ByScalar, LI8ByFacade);

  LI8ByFacade := VecI8x64Not(LI8A);
  LI8ByScalar := ScalarNotI8x64(LI8A);
  AssertVecI8x64Equal('VecI8x64Not', LI8ByScalar, LI8ByFacade);

  LI8ByFacade := VecI8x64AndNot(LI8A, LI8B);
  LI8ByScalar := ScalarAndNotI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64AndNot', LI8ByScalar, LI8ByFacade);

  LMask64Facade := VecI8x64CmpEq(LI8A, LI8B);
  LMask64Scalar := ScalarCmpEqI8x64(LI8A, LI8B);
  AssertEquals('VecI8x64CmpEq', QWord(LMask64Scalar), QWord(LMask64Facade));

  LMask64Facade := VecI8x64CmpLt(LI8A, LI8B);
  LMask64Scalar := ScalarCmpLtI8x64(LI8A, LI8B);
  AssertEquals('VecI8x64CmpLt', QWord(LMask64Scalar), QWord(LMask64Facade));

  LMask64Facade := VecI8x64CmpGt(LI8A, LI8B);
  LMask64Scalar := ScalarCmpGtI8x64(LI8A, LI8B);
  AssertEquals('VecI8x64CmpGt', QWord(LMask64Scalar), QWord(LMask64Facade));

  LI8ByFacade := VecI8x64Min(LI8A, LI8B);
  LI8ByScalar := ScalarMinI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64Min', LI8ByScalar, LI8ByFacade);

  LI8ByFacade := VecI8x64Max(LI8A, LI8B);
  LI8ByScalar := ScalarMaxI8x64(LI8A, LI8B);
  AssertVecI8x64Equal('VecI8x64Max', LI8ByScalar, LI8ByFacade);

  LU8ByFacade := VecU8x64Add(LU8A, LU8B);
  LU8ByScalar := ScalarAddU8x64(LU8A, LU8B);
  AssertVecU8x64Equal('VecU8x64Add', LU8ByScalar, LU8ByFacade);

  LU8ByFacade := VecU8x64Sub(LU8A, LU8B);
  LU8ByScalar := ScalarSubU8x64(LU8A, LU8B);
  AssertVecU8x64Equal('VecU8x64Sub', LU8ByScalar, LU8ByFacade);

  LU8ByFacade := VecU8x64And(LU8A, LU8B);
  LU8ByScalar := ScalarAndU8x64(LU8A, LU8B);
  AssertVecU8x64Equal('VecU8x64And', LU8ByScalar, LU8ByFacade);

  LU8ByFacade := VecU8x64Or(LU8A, LU8B);
  LU8ByScalar := ScalarOrU8x64(LU8A, LU8B);
  AssertVecU8x64Equal('VecU8x64Or', LU8ByScalar, LU8ByFacade);

  LU8ByFacade := VecU8x64Xor(LU8A, LU8B);
  LU8ByScalar := ScalarXorU8x64(LU8A, LU8B);
  AssertVecU8x64Equal('VecU8x64Xor', LU8ByScalar, LU8ByFacade);

  LU8ByFacade := VecU8x64Not(LU8A);
  LU8ByScalar := ScalarNotU8x64(LU8A);
  AssertVecU8x64Equal('VecU8x64Not', LU8ByScalar, LU8ByFacade);

  LMask64Facade := VecU8x64CmpEq(LU8A, LU8B);
  LMask64Scalar := ScalarCmpEqU8x64(LU8A, LU8B);
  AssertEquals('VecU8x64CmpEq', QWord(LMask64Scalar), QWord(LMask64Facade));

  LMask64Facade := VecU8x64CmpLt(LU8A, LU8B);
  LMask64Scalar := ScalarCmpLtU8x64(LU8A, LU8B);
  AssertEquals('VecU8x64CmpLt', QWord(LMask64Scalar), QWord(LMask64Facade));

  LMask64Facade := VecU8x64CmpGt(LU8A, LU8B);
  LMask64Scalar := ScalarCmpGtU8x64(LU8A, LU8B);
  AssertEquals('VecU8x64CmpGt', QWord(LMask64Scalar), QWord(LMask64Facade));

  LU8ByFacade := VecU8x64Min(LU8A, LU8B);
  LU8ByScalar := ScalarMinU8x64(LU8A, LU8B);
  AssertVecU8x64Equal('VecU8x64Min', LU8ByScalar, LU8ByFacade);

  LU8ByFacade := VecU8x64Max(LU8A, LU8B);
  LU8ByScalar := ScalarMaxU8x64(LU8A, LU8B);
  AssertVecU8x64Equal('VecU8x64Max', LU8ByScalar, LU8ByFacade);
end;

procedure TTestCase_DispatchAPI.Test_CoreFamilies_FacadeScalar_Parity_Completeness_Batch2;
var
  LIndex: Integer;

  LI32x16A, LI32x16B, LI32x16Facade, LI32x16Scalar, LI32x16Inserted: TVecI32x16;
  LI32x4A, LI32x4B, LI32x4Facade, LI32x4Scalar, LI32x4Mask: TVecI32x4;
  LI64x4A, LI64x4B, LI64x4Facade, LI64x4Scalar, LI64x4Inserted: TVecI64x4;
  LI64x2A, LI64x2B, LI64x2Facade, LI64x2Scalar, LI64x2Inserted: TVecI64x2;
  LF64x2A, LF64x2B, LF64x2Facade, LF64x2Scalar, LF64x2Inserted: TVecF64x2;

  LMask16Facade, LMask16Scalar: TMask16;
  LMask4Facade, LMask4Scalar: TMask4;
  LMask2Facade, LMask2Scalar: TMask2;

  LF64ReduceFacade, LF64ReduceScalar: Double;
  LF64DotFacade, LF64DotScalar: Double;

  LLoadF64: array[0..1] of Double;
  LStoreF64Facade: array[0..1] of Double;
  LStoreF64Scalar: array[0..1] of Double;
  LLoadI64x4: array[0..3] of Int64;
  LStoreI64x4Facade: array[0..3] of Int64;
  LStoreI64x4Scalar: array[0..3] of Int64;

  procedure AssertVecI32x16Equal(const aOp: string; const aExpected, aActual: TVecI32x16);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 15 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecI32x4Equal(const aOp: string; const aExpected, aActual: TVecI32x4);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 3 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecI64x4Equal(const aOp: string; const aExpected, aActual: TVecI64x4);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 3 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecI64x2Equal(const aOp: string; const aExpected, aActual: TVecI64x2);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 1 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecF64x2Equal(const aOp: string; const aExpected, aActual: TVecF64x2);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 1 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.d[LLane], aActual.d[LLane], 1.0e-12);
  end;
begin
  for LIndex := 0 to 15 do
  begin
    LI32x16A.i[LIndex] := LIndex * 23 - 100;
    LI32x16B.i[LIndex] := 700 - LIndex * 19;
  end;

  AssertEquals('VecI32x16Extract lane5', LI32x16A.i[5], VecI32x16Extract(LI32x16A, 5));
  LI32x16Inserted := VecI32x16Insert(LI32x16A, 123456, 6);
  AssertEquals('VecI32x16Insert lane6', 123456, LI32x16Inserted.i[6]);
  AssertEquals('VecI32x16Insert keep lane5', LI32x16A.i[5], LI32x16Inserted.i[5]);

  LI32x16Facade := VecI32x16Add(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarAddI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16Add', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16Sub(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarSubI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16Sub', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16Mul(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarMulI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16Mul', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16And(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarAndI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16And', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16Or(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarOrI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16Or', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16Xor(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarXorI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16Xor', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16Not(LI32x16A);
  LI32x16Scalar := ScalarNotI32x16(LI32x16A);
  AssertVecI32x16Equal('VecI32x16Not', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16AndNot(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarAndNotI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16AndNot', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16ShiftLeft(LI32x16A, 4);
  LI32x16Scalar := ScalarShiftLeftI32x16(LI32x16A, 4);
  AssertVecI32x16Equal('VecI32x16ShiftLeft', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16ShiftRight(LI32x16A, 3);
  LI32x16Scalar := ScalarShiftRightI32x16(LI32x16A, 3);
  AssertVecI32x16Equal('VecI32x16ShiftRight', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16ShiftRightArith(LI32x16A, 3);
  LI32x16Scalar := ScalarShiftRightArithI32x16(LI32x16A, 3);
  AssertVecI32x16Equal('VecI32x16ShiftRightArith', LI32x16Scalar, LI32x16Facade);

  LMask16Facade := fafafa.core.simd.VecI32x16CmpEq(LI32x16A, LI32x16B);
  LMask16Scalar := ScalarCmpEqI32x16(LI32x16A, LI32x16B);
  AssertEquals('VecI32x16CmpEq', LongInt(LMask16Scalar), LongInt(LMask16Facade));

  LMask16Facade := fafafa.core.simd.VecI32x16CmpLt(LI32x16A, LI32x16B);
  LMask16Scalar := ScalarCmpLtI32x16(LI32x16A, LI32x16B);
  AssertEquals('VecI32x16CmpLt', LongInt(LMask16Scalar), LongInt(LMask16Facade));

  LMask16Facade := fafafa.core.simd.VecI32x16CmpGt(LI32x16A, LI32x16B);
  LMask16Scalar := ScalarCmpGtI32x16(LI32x16A, LI32x16B);
  AssertEquals('VecI32x16CmpGt', LongInt(LMask16Scalar), LongInt(LMask16Facade));

  LMask16Facade := fafafa.core.simd.VecI32x16CmpLe(LI32x16A, LI32x16B);
  LMask16Scalar := ScalarCmpLeI32x16(LI32x16A, LI32x16B);
  AssertEquals('VecI32x16CmpLe', LongInt(LMask16Scalar), LongInt(LMask16Facade));

  LMask16Facade := fafafa.core.simd.VecI32x16CmpGe(LI32x16A, LI32x16B);
  LMask16Scalar := ScalarCmpGeI32x16(LI32x16A, LI32x16B);
  AssertEquals('VecI32x16CmpGe', LongInt(LMask16Scalar), LongInt(LMask16Facade));

  LMask16Facade := fafafa.core.simd.VecI32x16CmpNe(LI32x16A, LI32x16B);
  LMask16Scalar := ScalarCmpNeI32x16(LI32x16A, LI32x16B);
  AssertEquals('VecI32x16CmpNe', LongInt(LMask16Scalar), LongInt(LMask16Facade));

  LI32x16Facade := VecI32x16Min(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarMinI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16Min', LI32x16Scalar, LI32x16Facade);

  LI32x16Facade := VecI32x16Max(LI32x16A, LI32x16B);
  LI32x16Scalar := ScalarMaxI32x16(LI32x16A, LI32x16B);
  AssertVecI32x16Equal('VecI32x16Max', LI32x16Scalar, LI32x16Facade);

  LF64x2A.d[0] := -3.25;
  LF64x2A.d[1] := 8.5;
  LF64x2B.d[0] := 2.75;
  LF64x2B.d[1] := -4.0;

  AssertEquals('VecF64x2Extract lane0', LF64x2A.d[0], VecF64x2Extract(LF64x2A, 0), 1.0e-12);
  LF64x2Inserted := VecF64x2Insert(LF64x2A, 42.125, 1);
  AssertEquals('VecF64x2Insert lane1', 42.125, LF64x2Inserted.d[1], 1.0e-12);
  AssertEquals('VecF64x2Insert keep lane0', LF64x2A.d[0], LF64x2Inserted.d[0], 1.0e-12);

  LF64x2Facade := VecF64x2Add(LF64x2A, LF64x2B);
  LF64x2Scalar := ScalarAddF64x2(LF64x2A, LF64x2B);
  AssertVecF64x2Equal('VecF64x2Add', LF64x2Scalar, LF64x2Facade);

  LF64x2Facade := VecF64x2Sub(LF64x2A, LF64x2B);
  LF64x2Scalar := ScalarSubF64x2(LF64x2A, LF64x2B);
  AssertVecF64x2Equal('VecF64x2Sub', LF64x2Scalar, LF64x2Facade);

  LF64x2Facade := VecF64x2Div(LF64x2A, LF64x2B);
  LF64x2Scalar := ScalarDivF64x2(LF64x2A, LF64x2B);
  AssertVecF64x2Equal('VecF64x2Div', LF64x2Scalar, LF64x2Facade);

  LF64x2Facade := VecF64x2Abs(LF64x2A);
  LF64x2Scalar := ScalarAbsF64x2(LF64x2A);
  AssertVecF64x2Equal('VecF64x2Abs', LF64x2Scalar, LF64x2Facade);

  LF64x2Facade := VecF64x2Sqrt(VecF64x2Splat(9.0));
  LF64x2Scalar := ScalarSqrtF64x2(ScalarSplatF64x2(9.0));
  AssertVecF64x2Equal('VecF64x2Sqrt', LF64x2Scalar, LF64x2Facade);

  LF64x2Facade := VecF64x2Min(LF64x2A, LF64x2B);
  LF64x2Scalar := ScalarMinF64x2(LF64x2A, LF64x2B);
  AssertVecF64x2Equal('VecF64x2Min', LF64x2Scalar, LF64x2Facade);

  LF64x2Facade := VecF64x2Max(LF64x2A, LF64x2B);
  LF64x2Scalar := ScalarMaxF64x2(LF64x2A, LF64x2B);
  AssertVecF64x2Equal('VecF64x2Max', LF64x2Scalar, LF64x2Facade);

  LF64ReduceFacade := VecF64x2ReduceAdd(LF64x2A);
  LF64ReduceScalar := ScalarReduceAddF64x2(LF64x2A);
  AssertEquals('VecF64x2ReduceAdd', LF64ReduceScalar, LF64ReduceFacade, 1.0e-12);

  LF64ReduceFacade := VecF64x2ReduceMin(LF64x2A);
  LF64ReduceScalar := ScalarReduceMinF64x2(LF64x2A);
  AssertEquals('VecF64x2ReduceMin', LF64ReduceScalar, LF64ReduceFacade, 1.0e-12);

  LF64ReduceFacade := VecF64x2ReduceMax(LF64x2A);
  LF64ReduceScalar := ScalarReduceMaxF64x2(LF64x2A);
  AssertEquals('VecF64x2ReduceMax', LF64ReduceScalar, LF64ReduceFacade, 1.0e-12);

  LF64ReduceFacade := VecF64x2ReduceMul(LF64x2A);
  LF64ReduceScalar := ScalarReduceMulF64x2(LF64x2A);
  AssertEquals('VecF64x2ReduceMul', LF64ReduceScalar, LF64ReduceFacade, 1.0e-12);

  LLoadF64[0] := 1.25;
  LLoadF64[1] := -9.5;
  LF64x2Facade := VecF64x2Load(@LLoadF64[0]);
  LF64x2Scalar := ScalarLoadF64x2(@LLoadF64[0]);
  AssertVecF64x2Equal('VecF64x2Load', LF64x2Scalar, LF64x2Facade);

  VecF64x2Store(@LStoreF64Facade[0], LF64x2Facade);
  ScalarStoreF64x2(@LStoreF64Scalar[0], LF64x2Scalar);
  AssertEquals('VecF64x2Store lane0', LStoreF64Scalar[0], LStoreF64Facade[0], 1.0e-12);
  AssertEquals('VecF64x2Store lane1', LStoreF64Scalar[1], LStoreF64Facade[1], 1.0e-12);

  LF64x2Facade := VecF64x2Zero;
  LF64x2Scalar := ScalarZeroF64x2;
  AssertVecF64x2Equal('VecF64x2Zero', LF64x2Scalar, LF64x2Facade);

  LMask2Facade := TMask2(1);
  LF64x2Facade := VecF64x2Select(LMask2Facade, LF64x2A, LF64x2B);
  LF64x2Scalar := ScalarSelectF64x2(LMask2Facade, LF64x2A, LF64x2B);
  AssertVecF64x2Equal('VecF64x2Select', LF64x2Scalar, LF64x2Facade);

  LF64DotFacade := VecF64x2Dot(LF64x2A, LF64x2B);
  LF64DotScalar := ScalarDotF64x2(LF64x2A, LF64x2B);
  AssertEquals('VecF64x2Dot', LF64DotScalar, LF64DotFacade, 1.0e-12);

  for LIndex := 0 to 3 do
  begin
    LI32x4A.i[LIndex] := 50 - LIndex * 17;
    LI32x4B.i[LIndex] := LIndex * 11 - 30;
  end;
  LI32x4Mask.i[0] := -1;
  LI32x4Mask.i[1] := 0;
  LI32x4Mask.i[2] := -1;
  LI32x4Mask.i[3] := 0;

  LI32x4Facade := VecI32x4Select(LI32x4Mask, LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarSelectI32x4(LI32x4Mask, LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4Select', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4Sub(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarSubI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4Sub', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4Mul(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarMulI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4Mul', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4And(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarAndI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4And', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4Or(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarOrI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4Or', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4Xor(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarXorI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4Xor', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4Not(LI32x4A);
  LI32x4Scalar := ScalarNotI32x4(LI32x4A);
  AssertVecI32x4Equal('VecI32x4Not', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4AndNot(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarAndNotI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4AndNot', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4ShiftLeft(LI32x4A, 2);
  LI32x4Scalar := ScalarShiftLeftI32x4(LI32x4A, 2);
  AssertVecI32x4Equal('VecI32x4ShiftLeft', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4ShiftRight(LI32x4A, 2);
  LI32x4Scalar := ScalarShiftRightI32x4(LI32x4A, 2);
  AssertVecI32x4Equal('VecI32x4ShiftRight', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4ShiftRightArith(LI32x4A, 2);
  LI32x4Scalar := ScalarShiftRightArithI32x4(LI32x4A, 2);
  AssertVecI32x4Equal('VecI32x4ShiftRightArith', LI32x4Scalar, LI32x4Facade);

  LMask4Facade := VecI32x4CmpLt(LI32x4A, LI32x4B);
  LMask4Scalar := ScalarCmpLtI32x4(LI32x4A, LI32x4B);
  AssertEquals('VecI32x4CmpLt', Integer(LMask4Scalar), Integer(LMask4Facade));

  LMask4Facade := VecI32x4CmpGt(LI32x4A, LI32x4B);
  LMask4Scalar := ScalarCmpGtI32x4(LI32x4A, LI32x4B);
  AssertEquals('VecI32x4CmpGt', Integer(LMask4Scalar), Integer(LMask4Facade));

  LMask4Facade := VecI32x4CmpLe(LI32x4A, LI32x4B);
  LMask4Scalar := ScalarCmpLeI32x4(LI32x4A, LI32x4B);
  AssertEquals('VecI32x4CmpLe', Integer(LMask4Scalar), Integer(LMask4Facade));

  LMask4Facade := VecI32x4CmpGe(LI32x4A, LI32x4B);
  LMask4Scalar := ScalarCmpGeI32x4(LI32x4A, LI32x4B);
  AssertEquals('VecI32x4CmpGe', Integer(LMask4Scalar), Integer(LMask4Facade));

  LMask4Facade := VecI32x4CmpNe(LI32x4A, LI32x4B);
  LMask4Scalar := ScalarCmpNeI32x4(LI32x4A, LI32x4B);
  AssertEquals('VecI32x4CmpNe', Integer(LMask4Scalar), Integer(LMask4Facade));

  LI32x4Facade := VecI32x4Min(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarMinI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4Min', LI32x4Scalar, LI32x4Facade);

  LI32x4Facade := VecI32x4Max(LI32x4A, LI32x4B);
  LI32x4Scalar := ScalarMaxI32x4(LI32x4A, LI32x4B);
  AssertVecI32x4Equal('VecI32x4Max', LI32x4Scalar, LI32x4Facade);

  LI64x4A.i[0] := Int64(-1000);
  LI64x4A.i[1] := Int64(7777777);
  LI64x4A.i[2] := Int64(-1234567890123);
  LI64x4A.i[3] := Int64(42);
  LI64x4B.i[0] := Int64(13);
  LI64x4B.i[1] := Int64(-9);
  LI64x4B.i[2] := Int64(3000);
  LI64x4B.i[3] := Int64(-500);

  AssertEquals('VecI64x4Extract lane2', LI64x4A.i[2], VecI64x4Extract(LI64x4A, 2));
  LI64x4Inserted := VecI64x4Insert(LI64x4A, Int64(88888888), 1);
  AssertEquals('VecI64x4Insert lane1', Int64(88888888), LI64x4Inserted.i[1]);
  AssertEquals('VecI64x4Insert keep lane2', LI64x4A.i[2], LI64x4Inserted.i[2]);

  LI64x4Facade := VecI64x4Add(LI64x4A, LI64x4B);
  LI64x4Scalar := ScalarAddI64x4(LI64x4A, LI64x4B);
  AssertVecI64x4Equal('VecI64x4Add', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4Sub(LI64x4A, LI64x4B);
  LI64x4Scalar := ScalarSubI64x4(LI64x4A, LI64x4B);
  AssertVecI64x4Equal('VecI64x4Sub', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4And(LI64x4A, LI64x4B);
  LI64x4Scalar := ScalarAndI64x4(LI64x4A, LI64x4B);
  AssertVecI64x4Equal('VecI64x4And', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4Or(LI64x4A, LI64x4B);
  LI64x4Scalar := ScalarOrI64x4(LI64x4A, LI64x4B);
  AssertVecI64x4Equal('VecI64x4Or', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4Xor(LI64x4A, LI64x4B);
  LI64x4Scalar := ScalarXorI64x4(LI64x4A, LI64x4B);
  AssertVecI64x4Equal('VecI64x4Xor', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4Not(LI64x4A);
  LI64x4Scalar := ScalarNotI64x4(LI64x4A);
  AssertVecI64x4Equal('VecI64x4Not', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4ShiftRight(LI64x4A, 3);
  LI64x4Scalar := ScalarShiftRightI64x4(LI64x4A, 3);
  AssertVecI64x4Equal('VecI64x4ShiftRight', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4ShiftRightArith(LI64x4A, 3);
  LI64x4Scalar := ScalarShiftRightArithI64x4(LI64x4A, 3);
  AssertVecI64x4Equal('VecI64x4ShiftRightArith', LI64x4Scalar, LI64x4Facade);

  LMask4Facade := VecI64x4CmpLe(LI64x4A, LI64x4B);
  LMask4Scalar := ScalarCmpLeI64x4(LI64x4A, LI64x4B);
  AssertEquals('VecI64x4CmpLe', Integer(LMask4Scalar), Integer(LMask4Facade));

  LMask4Facade := VecI64x4CmpGe(LI64x4A, LI64x4B);
  LMask4Scalar := ScalarCmpGeI64x4(LI64x4A, LI64x4B);
  AssertEquals('VecI64x4CmpGe', Integer(LMask4Scalar), Integer(LMask4Facade));

  LMask4Facade := VecI64x4CmpNe(LI64x4A, LI64x4B);
  LMask4Scalar := ScalarCmpNeI64x4(LI64x4A, LI64x4B);
  AssertEquals('VecI64x4CmpNe', Integer(LMask4Scalar), Integer(LMask4Facade));

  LLoadI64x4[0] := Int64(11);
  LLoadI64x4[1] := Int64(-22);
  LLoadI64x4[2] := Int64(33);
  LLoadI64x4[3] := Int64(-44);
  LI64x4Facade := VecI64x4Load(@LLoadI64x4[0]);
  LI64x4Scalar := ScalarLoadI64x4(@LLoadI64x4[0]);
  AssertVecI64x4Equal('VecI64x4Load', LI64x4Scalar, LI64x4Facade);

  VecI64x4Store(@LStoreI64x4Facade[0], LI64x4Facade);
  ScalarStoreI64x4(@LStoreI64x4Scalar[0], LI64x4Scalar);
  for LIndex := 0 to 3 do
    AssertEquals('VecI64x4Store lane ' + IntToStr(LIndex), LStoreI64x4Scalar[LIndex], LStoreI64x4Facade[LIndex]);

  LI64x4Facade := VecI64x4Splat(Int64(-12345));
  LI64x4Scalar := ScalarSplatI64x4(Int64(-12345));
  AssertVecI64x4Equal('VecI64x4Splat', LI64x4Scalar, LI64x4Facade);

  LI64x4Facade := VecI64x4Zero;
  LI64x4Scalar := ScalarZeroI64x4;
  AssertVecI64x4Equal('VecI64x4Zero', LI64x4Scalar, LI64x4Facade);

  LI64x2A.i[0] := Int64(-4567890);
  LI64x2A.i[1] := Int64(1234567);
  LI64x2B.i[0] := Int64(9999);
  LI64x2B.i[1] := Int64(-8888);

  AssertEquals('VecI64x2Extract lane1', LI64x2A.i[1], VecI64x2Extract(LI64x2A, 1));
  LI64x2Inserted := VecI64x2Insert(LI64x2A, Int64(55555), 0);
  AssertEquals('VecI64x2Insert lane0', Int64(55555), LI64x2Inserted.i[0]);
  AssertEquals('VecI64x2Insert keep lane1', LI64x2A.i[1], LI64x2Inserted.i[1]);

  LI64x2Facade := VecI64x2Add(LI64x2A, LI64x2B);
  LI64x2Scalar := ScalarAddI64x2(LI64x2A, LI64x2B);
  AssertVecI64x2Equal('VecI64x2Add', LI64x2Scalar, LI64x2Facade);

  LI64x2Facade := VecI64x2Sub(LI64x2A, LI64x2B);
  LI64x2Scalar := ScalarSubI64x2(LI64x2A, LI64x2B);
  AssertVecI64x2Equal('VecI64x2Sub', LI64x2Scalar, LI64x2Facade);

  LI64x2Facade := VecI64x2And(LI64x2A, LI64x2B);
  LI64x2Scalar := ScalarAndI64x2(LI64x2A, LI64x2B);
  AssertVecI64x2Equal('VecI64x2And', LI64x2Scalar, LI64x2Facade);

  LI64x2Facade := VecI64x2Or(LI64x2A, LI64x2B);
  LI64x2Scalar := ScalarOrI64x2(LI64x2A, LI64x2B);
  AssertVecI64x2Equal('VecI64x2Or', LI64x2Scalar, LI64x2Facade);

  LI64x2Facade := VecI64x2Xor(LI64x2A, LI64x2B);
  LI64x2Scalar := ScalarXorI64x2(LI64x2A, LI64x2B);
  AssertVecI64x2Equal('VecI64x2Xor', LI64x2Scalar, LI64x2Facade);

  LI64x2Facade := VecI64x2Not(LI64x2A);
  LI64x2Scalar := ScalarNotI64x2(LI64x2A);
  AssertVecI64x2Equal('VecI64x2Not', LI64x2Scalar, LI64x2Facade);

  LMask2Facade := VecI64x2CmpEq(LI64x2A, LI64x2B);
  LMask2Scalar := ScalarCmpEqI64x2(LI64x2A, LI64x2B);
  AssertEquals('VecI64x2CmpEq', Integer(LMask2Scalar), Integer(LMask2Facade));

  LMask2Facade := VecI64x2CmpLt(LI64x2A, LI64x2B);
  LMask2Scalar := ScalarCmpLtI64x2(LI64x2A, LI64x2B);
  AssertEquals('VecI64x2CmpLt', Integer(LMask2Scalar), Integer(LMask2Facade));

  LMask2Facade := VecI64x2CmpGt(LI64x2A, LI64x2B);
  LMask2Scalar := ScalarCmpGtI64x2(LI64x2A, LI64x2B);
  AssertEquals('VecI64x2CmpGt', Integer(LMask2Scalar), Integer(LMask2Facade));

  LMask2Facade := VecI64x2CmpLe(LI64x2A, LI64x2B);
  LMask2Scalar := ScalarCmpLeI64x2(LI64x2A, LI64x2B);
  AssertEquals('VecI64x2CmpLe', Integer(LMask2Scalar), Integer(LMask2Facade));

  LMask2Facade := VecI64x2CmpGe(LI64x2A, LI64x2B);
  LMask2Scalar := ScalarCmpGeI64x2(LI64x2A, LI64x2B);
  AssertEquals('VecI64x2CmpGe', Integer(LMask2Scalar), Integer(LMask2Facade));

  LMask2Facade := VecI64x2CmpNe(LI64x2A, LI64x2B);
  LMask2Scalar := ScalarCmpNeI64x2(LI64x2A, LI64x2B);
  AssertEquals('VecI64x2CmpNe', Integer(LMask2Scalar), Integer(LMask2Facade));
end;

procedure TTestCase_DispatchAPI.Test_BacklogParityAndSmoke_Batch3;
var
  LIndex: Integer;
  LDotF32x8Facade, LDotF32x8Scalar: Single;
  LDotF64x4Facade, LDotF64x4Scalar: Double;

  LF32x4A, LF32x4B, LF32x4Loaded, LF32x4Selected: TVecF32x4;
  LF32x8A, LF32x8B, LF32x8Facade, LF32x8Scalar, LF32x8Inserted: TVecF32x8;
  LF64x4A, LF64x4B, LF64x4Facade, LF64x4Scalar, LF64x4Inserted: TVecF64x4;
  LI32x8A, LI32x8Inserted: TVecI32x8;
  LF32x16A, LF32x16B, LF32x16Facade, LF32x16Scalar, LF32x16Inserted: TVecF32x16;

  LU64x2A, LU64x2B, LU64x2Facade, LU64x2Scalar: TVecU64x2;
  LU32x4A, LU32x4B, LU32x4Facade, LU32x4Scalar: TVecU32x4;
  LU64x4A, LU64x4B, LU64x4Facade, LU64x4Scalar: TVecU64x4;
  LU16x8A, LU16x8B, LU16x8Facade, LU16x8Scalar: TVecU16x8;
  LF64x8A, LF64x8B, LF64x8Facade, LF64x8Scalar: TVecF64x8;
  LI64x8A, LI64x8B, LI64x8Facade, LI64x8Scalar: TVecI64x8;

  LMask4: TMask4;
  LMask4Facade, LMask4Scalar: TMask4;
  LMaskF32x8: TVecU32x8;
  LMaskF64x4: TVecU64x4;

  LAligned: Pointer;
  LMisaligned: Pointer;
  LAlignedF32: PSingle;

  LBackendInfo: TSimdBackendInfo;
  LAvailableBackends: TSimdBackendArray;

  procedure AssertVecF32x8Equal(const aOp: string; const aExpected, aActual: TVecF32x8);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.f[LLane], aActual.f[LLane], 1.0e-6);
  end;

  procedure AssertVecF64x4Equal(const aOp: string; const aExpected, aActual: TVecF64x4);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 3 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.d[LLane], aActual.d[LLane], 1.0e-12);
  end;

  procedure AssertVecF32x16Equal(const aOp: string; const aExpected, aActual: TVecF32x16);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 15 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.f[LLane], aActual.f[LLane], 1.0e-5);
  end;

  procedure AssertVecU64x2Equal(const aOp: string; const aExpected, aActual: TVecU64x2);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 1 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.u[LLane], aActual.u[LLane]);
  end;

  procedure AssertVecU64x4Equal(const aOp: string; const aExpected, aActual: TVecU64x4);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 3 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.u[LLane], aActual.u[LLane]);
  end;

  procedure AssertVecU16x8Equal(const aOp: string; const aExpected, aActual: TVecU16x8);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.u[LLane], aActual.u[LLane]);
  end;

  procedure AssertVecF64x8Equal(const aOp: string; const aExpected, aActual: TVecF64x8);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.d[LLane], aActual.d[LLane], 1.0e-12);
  end;

  procedure AssertVecI64x8Equal(const aOp: string; const aExpected, aActual: TVecI64x8);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;
begin
  for LIndex := 0 to 7 do
  begin
    LF32x8A.f[LIndex] := (LIndex + 1) * 1.25;
    LF32x8B.f[LIndex] := (8 - LIndex) * 0.75;
    LMaskF32x8.u[LIndex] := DWord((LIndex mod 2) * $FFFFFFFF);
  end;

  LDotF32x8Facade := fafafa.core.simd.VecF32x8Dot(LF32x8A, LF32x8B);
  LDotF32x8Scalar := ScalarDotF32x8(LF32x8A, LF32x8B);
  AssertEquals('VecF32x8Dot', LDotF32x8Scalar, LDotF32x8Facade, 1.0e-6);

  AssertEquals('VecF32x8Extract lane3', LF32x8A.f[3], fafafa.core.simd.VecF32x8Extract(LF32x8A, 3), 1.0e-6);
  LF32x8Inserted := fafafa.core.simd.VecF32x8Insert(LF32x8A, 123.5, 4);
  AssertEquals('VecF32x8Insert lane4', 123.5, LF32x8Inserted.f[4], 1.0e-6);
  AssertEquals('VecF32x8Insert keep lane3', LF32x8A.f[3], LF32x8Inserted.f[3], 1.0e-6);

  LF32x8Facade := fafafa.core.simd.VecF32x8Select(LMaskF32x8, LF32x8A, LF32x8B);
  LF32x8Scalar := ScalarSelectF32x8(LMaskF32x8, LF32x8A, LF32x8B);
  AssertVecF32x8Equal('VecF32x8Select', LF32x8Scalar, LF32x8Facade);

  for LIndex := 0 to 3 do
  begin
    LF64x4A.d[LIndex] := (LIndex + 1) * 2.0;
    LF64x4B.d[LIndex] := (LIndex - 2) * 3.5;
    if (LIndex and 1) <> 0 then
      LMaskF64x4.u[LIndex] := High(QWord)
    else
      LMaskF64x4.u[LIndex] := 0;
  end;

  LDotF64x4Facade := fafafa.core.simd.VecF64x4Dot(LF64x4A, LF64x4B);
  LDotF64x4Scalar := ScalarDotF64x4(LF64x4A, LF64x4B);
  AssertEquals('VecF64x4Dot', LDotF64x4Scalar, LDotF64x4Facade, 1.0e-12);

  AssertEquals('VecF64x4Extract lane2', LF64x4A.d[2], fafafa.core.simd.VecF64x4Extract(LF64x4A, 2), 1.0e-12);
  LF64x4Inserted := fafafa.core.simd.VecF64x4Insert(LF64x4A, 777.25, 1);
  AssertEquals('VecF64x4Insert lane1', 777.25, LF64x4Inserted.d[1], 1.0e-12);
  AssertEquals('VecF64x4Insert keep lane2', LF64x4A.d[2], LF64x4Inserted.d[2], 1.0e-12);

  LF64x4Facade := fafafa.core.simd.VecF64x4Select(LMaskF64x4, LF64x4A, LF64x4B);
  LF64x4Scalar := ScalarSelectF64x4(LMaskF64x4, LF64x4A, LF64x4B);
  AssertVecF64x4Equal('VecF64x4Select', LF64x4Scalar, LF64x4Facade);

  for LIndex := 0 to 7 do
    LI32x8A.i[LIndex] := LIndex * 10 - 30;
  AssertEquals('VecI32x8Extract lane6', LI32x8A.i[6], fafafa.core.simd.VecI32x8Extract(LI32x8A, 6));
  LI32x8Inserted := fafafa.core.simd.VecI32x8Insert(LI32x8A, 2026, 5);
  AssertEquals('VecI32x8Insert lane5', 2026, LI32x8Inserted.i[5]);
  AssertEquals('VecI32x8Insert keep lane4', LI32x8A.i[4], LI32x8Inserted.i[4]);

  for LIndex := 0 to 15 do
  begin
    LF32x16A.f[LIndex] := (LIndex - 8) * 1.25;
    LF32x16B.f[LIndex] := (LIndex + 1) * 0.75 + 1.0;
  end;

  AssertEquals('VecF32x16Extract lane10', LF32x16A.f[10], fafafa.core.simd.VecF32x16Extract(LF32x16A, 10), 1.0e-5);
  LF32x16Inserted := fafafa.core.simd.VecF32x16Insert(LF32x16A, 9.75, 11);
  AssertEquals('VecF32x16Insert lane11', 9.75, LF32x16Inserted.f[11], 1.0e-5);
  AssertEquals('VecF32x16Insert keep lane10', LF32x16A.f[10], LF32x16Inserted.f[10], 1.0e-5);

  LF32x16Facade := fafafa.core.simd.VecF32x16Abs(LF32x16A);
  LF32x16Scalar := ScalarAbsF32x16(LF32x16A);
  AssertVecF32x16Equal('VecF32x16Abs', LF32x16Scalar, LF32x16Facade);

  LF32x16Facade := fafafa.core.simd.VecF32x16Sqrt(LF32x16B);
  LF32x16Scalar := ScalarSqrtF32x16(LF32x16B);
  AssertVecF32x16Equal('VecF32x16Sqrt', LF32x16Scalar, LF32x16Facade);

  LF32x16Facade := fafafa.core.simd.VecF32x16Min(LF32x16A, LF32x16B);
  LF32x16Scalar := ScalarMinF32x16(LF32x16A, LF32x16B);
  AssertVecF32x16Equal('VecF32x16Min', LF32x16Scalar, LF32x16Facade);

  LF32x16Facade := fafafa.core.simd.VecF32x16Max(LF32x16A, LF32x16B);
  LF32x16Scalar := ScalarMaxF32x16(LF32x16A, LF32x16B);
  AssertVecF32x16Equal('VecF32x16Max', LF32x16Scalar, LF32x16Facade);

  LU64x2A.u[0] := QWord($0102030405060708);
  LU64x2A.u[1] := QWord($F0F1F2F3F4F5F6F7);
  LU64x2B.u[0] := QWord($0001000100010001);
  LU64x2B.u[1] := QWord($00FF00FF00FF00FF);

  LU64x2Facade := fafafa.core.simd.VecU64x2Sub(LU64x2A, LU64x2B);
  LU64x2Scalar := ScalarSubU64x2(LU64x2A, LU64x2B);
  AssertVecU64x2Equal('VecU64x2Sub', LU64x2Scalar, LU64x2Facade);

  LU64x2Facade := fafafa.core.simd.VecU64x2And(LU64x2A, LU64x2B);
  LU64x2Scalar := ScalarAndU64x2(LU64x2A, LU64x2B);
  AssertVecU64x2Equal('VecU64x2And', LU64x2Scalar, LU64x2Facade);

  LU64x2Facade := fafafa.core.simd.VecU64x2Or(LU64x2A, LU64x2B);
  LU64x2Scalar := ScalarOrU64x2(LU64x2A, LU64x2B);
  AssertVecU64x2Equal('VecU64x2Or', LU64x2Scalar, LU64x2Facade);

  LU64x2Facade := fafafa.core.simd.VecU64x2Xor(LU64x2A, LU64x2B);
  LU64x2Scalar := ScalarXorU64x2(LU64x2A, LU64x2B);
  AssertVecU64x2Equal('VecU64x2Xor', LU64x2Scalar, LU64x2Facade);

  LU64x2Facade := fafafa.core.simd.VecU64x2Not(LU64x2A);
  LU64x2Scalar := ScalarNotU64x2(LU64x2A);
  AssertVecU64x2Equal('VecU64x2Not', LU64x2Scalar, LU64x2Facade);

  for LIndex := 0 to 3 do
  begin
    LU32x4A.u[LIndex] := DWord($FFFFFFFF - LIndex * 1000);
    LU32x4B.u[LIndex] := DWord(LIndex * 900 + 123);
  end;

  LU32x4Facade := fafafa.core.simd.VecU32x4AndNot(LU32x4A, LU32x4B);
  LU32x4Scalar := ScalarAndNotU32x4(LU32x4A, LU32x4B);
  for LIndex := 0 to 3 do
    AssertEquals('VecU32x4AndNot lane ' + IntToStr(LIndex), LU32x4Scalar.u[LIndex], LU32x4Facade.u[LIndex]);

  LMask4Facade := fafafa.core.simd.VecU32x4CmpLe(LU32x4A, LU32x4B);
  LMask4Scalar := ScalarCmpLeU32x4(LU32x4A, LU32x4B);
  AssertEquals('VecU32x4CmpLe', Integer(LMask4Scalar), Integer(LMask4Facade));

  LMask4Facade := fafafa.core.simd.VecU32x4CmpGe(LU32x4A, LU32x4B);
  LMask4Scalar := ScalarCmpGeU32x4(LU32x4A, LU32x4B);
  AssertEquals('VecU32x4CmpGe', Integer(LMask4Scalar), Integer(LMask4Facade));

  for LIndex := 0 to 3 do
  begin
    LU64x4A.u[LIndex] := QWord($1000000000000000) + QWord(LIndex) * QWord($0101010101010101);
    LU64x4B.u[LIndex] := QWord(LIndex + 1) * QWord($1111111111111111);
  end;

  LU64x4Facade := fafafa.core.simd.VecU64x4Sub(LU64x4A, LU64x4B);
  LU64x4Scalar := ScalarSubU64x4(LU64x4A, LU64x4B);
  AssertVecU64x4Equal('VecU64x4Sub', LU64x4Scalar, LU64x4Facade);

  LU64x4Facade := fafafa.core.simd.VecU64x4And(LU64x4A, LU64x4B);
  LU64x4Scalar := ScalarAndU64x4(LU64x4A, LU64x4B);
  AssertVecU64x4Equal('VecU64x4And', LU64x4Scalar, LU64x4Facade);

  LU64x4Facade := fafafa.core.simd.VecU64x4Or(LU64x4A, LU64x4B);
  LU64x4Scalar := ScalarOrU64x4(LU64x4A, LU64x4B);
  AssertVecU64x4Equal('VecU64x4Or', LU64x4Scalar, LU64x4Facade);

  LU64x4Facade := fafafa.core.simd.VecU64x4Xor(LU64x4A, LU64x4B);
  LU64x4Scalar := ScalarXorU64x4(LU64x4A, LU64x4B);
  AssertVecU64x4Equal('VecU64x4Xor', LU64x4Scalar, LU64x4Facade);

  LU64x4Facade := fafafa.core.simd.VecU64x4Not(LU64x4A);
  LU64x4Scalar := ScalarNotU64x4(LU64x4A);
  AssertVecU64x4Equal('VecU64x4Not', LU64x4Scalar, LU64x4Facade);

  LU64x4Facade := fafafa.core.simd.VecU64x4ShiftLeft(LU64x4A, 5);
  LU64x4Scalar := ScalarShiftLeftU64x4(LU64x4A, 5);
  AssertVecU64x4Equal('VecU64x4ShiftLeft', LU64x4Scalar, LU64x4Facade);

  LU64x4Facade := fafafa.core.simd.VecU64x4ShiftRight(LU64x4A, 7);
  LU64x4Scalar := ScalarShiftRightU64x4(LU64x4A, 7);
  AssertVecU64x4Equal('VecU64x4ShiftRight', LU64x4Scalar, LU64x4Facade);

  LU64x4Facade := fafafa.core.simd.VecU64x4Splat(QWord($ABCDEF0123456789));
  for LIndex := 0 to 3 do
    AssertEquals('VecU64x4Splat lane ' + IntToStr(LIndex), QWord($ABCDEF0123456789), LU64x4Facade.u[LIndex]);

  LU64x4Facade := fafafa.core.simd.VecU64x4Zero;
  for LIndex := 0 to 3 do
    AssertEquals('VecU64x4Zero lane ' + IntToStr(LIndex), QWord(0), LU64x4Facade.u[LIndex]);

  for LIndex := 0 to 7 do
  begin
    LU16x8A.u[LIndex] := Word(LIndex * 37 + 1);
    LU16x8B.u[LIndex] := Word(LIndex * 11 + 3);
  end;
  LU16x8Facade := fafafa.core.simd.VecU16x8Mul(LU16x8A, LU16x8B);
  LU16x8Scalar := ScalarMulU16x8(LU16x8A, LU16x8B);
  AssertVecU16x8Equal('VecU16x8Mul', LU16x8Scalar, LU16x8Facade);

  for LIndex := 0 to 7 do
  begin
    LF64x8A.d[LIndex] := (LIndex - 4) * 2.5;
    LF64x8B.d[LIndex] := (LIndex + 1) * 1.75 + 1.0;
    LI64x8A.i[LIndex] := Int64(LIndex * 1000 - 3000);
    LI64x8B.i[LIndex] := Int64(500 - LIndex * 77);
  end;

  LF64x8Facade := fafafa.core.simd.VecF64x8Abs(LF64x8A);
  LF64x8Scalar := ScalarAbsF64x8(LF64x8A);
  AssertVecF64x8Equal('VecF64x8Abs', LF64x8Scalar, LF64x8Facade);

  LF64x8Facade := fafafa.core.simd.VecF64x8Sqrt(LF64x8B);
  LF64x8Scalar := ScalarSqrtF64x8(LF64x8B);
  AssertVecF64x8Equal('VecF64x8Sqrt', LF64x8Scalar, LF64x8Facade);

  LF64x8Facade := fafafa.core.simd.VecF64x8Min(LF64x8A, LF64x8B);
  LF64x8Scalar := ScalarMinF64x8(LF64x8A, LF64x8B);
  AssertVecF64x8Equal('VecF64x8Min', LF64x8Scalar, LF64x8Facade);

  LF64x8Facade := fafafa.core.simd.VecF64x8Max(LF64x8A, LF64x8B);
  LF64x8Scalar := ScalarMaxF64x8(LF64x8A, LF64x8B);
  AssertVecF64x8Equal('VecF64x8Max', LF64x8Scalar, LF64x8Facade);

  LI64x8Facade := fafafa.core.simd.VecI64x8Sub(LI64x8A, LI64x8B);
  LI64x8Scalar := ScalarSubI64x8(LI64x8A, LI64x8B);
  AssertVecI64x8Equal('VecI64x8Sub', LI64x8Scalar, LI64x8Facade);

  LI64x8Facade := fafafa.core.simd.VecI64x8And(LI64x8A, LI64x8B);
  LI64x8Scalar := ScalarAndI64x8(LI64x8A, LI64x8B);
  AssertVecI64x8Equal('VecI64x8And', LI64x8Scalar, LI64x8Facade);

  LI64x8Facade := fafafa.core.simd.VecI64x8Or(LI64x8A, LI64x8B);
  LI64x8Scalar := ScalarOrI64x8(LI64x8A, LI64x8B);
  AssertVecI64x8Equal('VecI64x8Or', LI64x8Scalar, LI64x8Facade);

  LI64x8Facade := fafafa.core.simd.VecI64x8Xor(LI64x8A, LI64x8B);
  LI64x8Scalar := ScalarXorI64x8(LI64x8A, LI64x8B);
  AssertVecI64x8Equal('VecI64x8Xor', LI64x8Scalar, LI64x8Facade);

  LI64x8Facade := fafafa.core.simd.VecI64x8Not(LI64x8A);
  LI64x8Scalar := ScalarNotI64x8(LI64x8A);
  AssertVecI64x8Equal('VecI64x8Not', LI64x8Scalar, LI64x8Facade);

  LAligned := fafafa.core.simd.AllocateAligned(SizeOf(Single) * 8, 32);
  AssertTrue('AllocateAligned should return non-nil', LAligned <> nil);
  try
    AssertTrue('IsPointerAligned(32) should be true for AllocateAligned',
      fafafa.core.simd.IsPointerAligned(LAligned, 32));
    LMisaligned := Pointer(PByte(LAligned) + 1);
    AssertFalse('IsPointerAligned should be false for +1 offset',
      fafafa.core.simd.IsPointerAligned(LMisaligned, 32));

    LAlignedF32 := PSingle(LAligned);
    LAlignedF32[0] := 10.0;
    LAlignedF32[1] := 20.0;
    LAlignedF32[2] := 30.0;
    LAlignedF32[3] := 40.0;

    LF32x4Loaded := fafafa.core.simd.VecF32x4LoadAligned(LAlignedF32);
    AssertEquals('VecF32x4LoadAligned lane0', 10.0, LF32x4Loaded.f[0], 1.0e-6);
    AssertEquals('VecF32x4LoadAligned lane3', 40.0, LF32x4Loaded.f[3], 1.0e-6);

    LF32x4A := fafafa.core.simd.VecF32x4Splat(1.0);
    LF32x4B := fafafa.core.simd.VecF32x4Splat(9.0);
    LMask4 := TMask4($5); // lane0/2 -> a, lane1/3 -> b
    LF32x4Selected := fafafa.core.simd.VecF32x4Select(LMask4, LF32x4A, LF32x4B);
    AssertEquals('VecF32x4Select lane0', 1.0, LF32x4Selected.f[0], 1.0e-6);
    AssertEquals('VecF32x4Select lane1', 9.0, LF32x4Selected.f[1], 1.0e-6);
    AssertEquals('VecF32x4Select lane2', 1.0, LF32x4Selected.f[2], 1.0e-6);
    AssertEquals('VecF32x4Select lane3', 9.0, LF32x4Selected.f[3], 1.0e-6);

    fafafa.core.simd.VecF32x4StoreAligned(LAlignedF32, LF32x4Selected);
    AssertEquals('VecF32x4StoreAligned lane0', 1.0, LAlignedF32[0], 1.0e-6);
    AssertEquals('VecF32x4StoreAligned lane1', 9.0, LAlignedF32[1], 1.0e-6);
    AssertEquals('VecF32x4StoreAligned lane2', 1.0, LAlignedF32[2], 1.0e-6);
    AssertEquals('VecF32x4StoreAligned lane3', 9.0, LAlignedF32[3], 1.0e-6);
  finally
    fafafa.core.simd.FreeAligned(LAligned);
  end;

  LBackendInfo := fafafa.core.simd.GetCurrentBackendInfo;
  AssertEquals('GetCurrentBackendInfo.Backend should match GetCurrentBackend',
    Ord(fafafa.core.simd.GetCurrentBackend), Ord(LBackendInfo.Backend));
  LAvailableBackends := fafafa.core.simd.GetAvailableBackendList;
  AssertTrue('GetAvailableBackendList should return at least one backend', Length(LAvailableBackends) > 0);
end;

procedure TTestCase_DispatchAPI.Test_AllRegisteredBackends_Wide512IntegerSlots_Assigned;
var
  LBackends: array[0..4] of TSimdBackend;
  LBackend: TSimdBackend;
  LTable: TSimdDispatchTable;
  LRegisteredCount: Integer;

  function BackendName(const aBackend: TSimdBackend): string;
  begin
    case aBackend of
      sbSSE2: Result := 'SSE2';
      sbAVX2: Result := 'AVX2';
      sbAVX512: Result := 'AVX512';
      sbNEON: Result := 'NEON';
      sbRISCVV: Result := 'RISCVV';
      else Result := IntToStr(Ord(aBackend));
    end;
  end;

  procedure AssertAssigned(const aBackendName, aSlotName: string; aSlot: Pointer);
  begin
    AssertTrue(aSlotName + ' missing: ' + aBackendName, aSlot <> nil);
  end;
begin
  LBackends[0] := sbSSE2;
  LBackends[1] := sbAVX2;
  LBackends[2] := sbAVX512;
  LBackends[3] := sbNEON;
  LBackends[4] := sbRISCVV;
  LRegisteredCount := 0;

  for LBackend in LBackends do
  begin
    if not TryGetRegisteredBackendDispatchTable(LBackend, LTable) then
      Continue;

    Inc(LRegisteredCount);

    AssertAssigned(BackendName(LBackend), 'AddU32x16', Pointer(LTable.AddU32x16));
    AssertAssigned(BackendName(LBackend), 'CmpEqU32x16', Pointer(LTable.CmpEqU32x16));
    AssertAssigned(BackendName(LBackend), 'MinU32x16', Pointer(LTable.MinU32x16));

    AssertAssigned(BackendName(LBackend), 'AddU64x8', Pointer(LTable.AddU64x8));
    AssertAssigned(BackendName(LBackend), 'CmpEqU64x8', Pointer(LTable.CmpEqU64x8));
    AssertAssigned(BackendName(LBackend), 'ShiftRightU64x8', Pointer(LTable.ShiftRightU64x8));

    AssertAssigned(BackendName(LBackend), 'AddI16x32', Pointer(LTable.AddI16x32));
    AssertAssigned(BackendName(LBackend), 'CmpEqI16x32', Pointer(LTable.CmpEqI16x32));
    AssertAssigned(BackendName(LBackend), 'ShiftRightArithI16x32', Pointer(LTable.ShiftRightArithI16x32));

    AssertAssigned(BackendName(LBackend), 'AddI8x64', Pointer(LTable.AddI8x64));
    AssertAssigned(BackendName(LBackend), 'CmpEqI8x64', Pointer(LTable.CmpEqI8x64));
    AssertAssigned(BackendName(LBackend), 'MaxI8x64', Pointer(LTable.MaxI8x64));

    AssertAssigned(BackendName(LBackend), 'AddU8x64', Pointer(LTable.AddU8x64));
    AssertAssigned(BackendName(LBackend), 'CmpEqU8x64', Pointer(LTable.CmpEqU8x64));
    AssertAssigned(BackendName(LBackend), 'MaxU8x64', Pointer(LTable.MaxU8x64));
  end;

  if LRegisteredCount = 0 then
    AssertTrue('No SIMD backend registered on this host (allowed)', True);
end;

procedure TTestCase_DispatchAPI.Test_AVX512_U32x16_U64x8_MappingAndParity;
var
  LScalar: TSimdDispatchTable;
  LAVX512: TSimdDispatchTable;
  LCanRunAVX512: Boolean;
  LIndex: Integer;
  LU32A, LU32B, LU32Result, LU32Expected: TVecU32x16;
  LU64A, LU64B, LU64Result, LU64Expected: TVecU64x8;
  LMask16Result, LMask16Expected: TMask16;
  LMask8Result, LMask8Expected: TMask8;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalar));

  if not TryGetRegisteredBackendDispatchTable(sbAVX512, LAVX512) then
    Exit;

  // Mapping check: these slots must no longer point to scalar fallback.
  AssertTrue('AVX512 AddU32x16 should not be scalar slot',
    Pointer(LAVX512.AddU32x16) <> Pointer(LScalar.AddU32x16));
  AssertTrue('AVX512 CmpEqU32x16 should not be scalar slot',
    Pointer(LAVX512.CmpEqU32x16) <> Pointer(LScalar.CmpEqU32x16));
  AssertTrue('AVX512 ShiftRightU32x16 should not be scalar slot',
    Pointer(LAVX512.ShiftRightU32x16) <> Pointer(LScalar.ShiftRightU32x16));
  AssertTrue('AVX512 AddU64x8 should not be scalar slot',
    Pointer(LAVX512.AddU64x8) <> Pointer(LScalar.AddU64x8));
  AssertTrue('AVX512 CmpEqU64x8 should not be scalar slot',
    Pointer(LAVX512.CmpEqU64x8) <> Pointer(LScalar.CmpEqU64x8));
  AssertTrue('AVX512 ShiftRightU64x8 should not be scalar slot',
    Pointer(LAVX512.ShiftRightU64x8) <> Pointer(LScalar.ShiftRightU64x8));

  // Parity check only on hosts where AVX512 backend is dispatch-available.
  LCanRunAVX512 := LAVX512.BackendInfo.Available and TrySetActiveBackend(sbAVX512);
  if not LCanRunAVX512 then
    Exit;

  try
    for LIndex := 0 to 15 do
    begin
      LU32A.u[LIndex] := DWord($F0000000 + DWord(LIndex) * DWord($1111111));
      LU32B.u[LIndex] := DWord($0F0F0F0F + DWord(LIndex) * DWord(97));
    end;

    for LIndex := 0 to 7 do
    begin
      LU64A.u[LIndex] := QWord($F000000000000000) + QWord(LIndex) * QWord($0102030405060708);
      LU64B.u[LIndex] := QWord($00FF00FF00FF00FF) + QWord(LIndex) * QWord($0001000100010001);
    end;

    LU32Result := LAVX512.AddU32x16(LU32A, LU32B);
    LU32Expected := ScalarAddU32x16(LU32A, LU32B);
    for LIndex := 0 to 15 do
      AssertEquals('AVX512 AddU32x16 lane ' + IntToStr(LIndex), LU32Expected.u[LIndex], LU32Result.u[LIndex]);

    LU32Result := LAVX512.AndU32x16(LU32A, LU32B);
    LU32Expected := ScalarAndU32x16(LU32A, LU32B);
    for LIndex := 0 to 15 do
      AssertEquals('AVX512 AndU32x16 lane ' + IntToStr(LIndex), LU32Expected.u[LIndex], LU32Result.u[LIndex]);

    LU32Result := LAVX512.ShiftRightU32x16(LU32A, 5);
    LU32Expected := ScalarShiftRightU32x16(LU32A, 5);
    for LIndex := 0 to 15 do
      AssertEquals('AVX512 ShiftRightU32x16 lane ' + IntToStr(LIndex), LU32Expected.u[LIndex], LU32Result.u[LIndex]);

    LMask16Result := LAVX512.CmpEqU32x16(LU32A, LU32B);
    LMask16Expected := ScalarCmpEqU32x16(LU32A, LU32B);
    AssertEquals('AVX512 CmpEqU32x16 mask parity', Integer(LMask16Expected), Integer(LMask16Result));

    LMask16Result := LAVX512.CmpGtU32x16(LU32A, LU32B);
    LMask16Expected := ScalarCmpGtU32x16(LU32A, LU32B);
    AssertEquals('AVX512 CmpGtU32x16 mask parity', Integer(LMask16Expected), Integer(LMask16Result));

    LU64Result := LAVX512.AddU64x8(LU64A, LU64B);
    LU64Expected := ScalarAddU64x8(LU64A, LU64B);
    for LIndex := 0 to 7 do
      AssertEquals('AVX512 AddU64x8 lane ' + IntToStr(LIndex), LU64Expected.u[LIndex], LU64Result.u[LIndex]);

    LU64Result := LAVX512.XorU64x8(LU64A, LU64B);
    LU64Expected := ScalarXorU64x8(LU64A, LU64B);
    for LIndex := 0 to 7 do
      AssertEquals('AVX512 XorU64x8 lane ' + IntToStr(LIndex), LU64Expected.u[LIndex], LU64Result.u[LIndex]);

    LU64Result := LAVX512.ShiftRightU64x8(LU64A, 11);
    LU64Expected := ScalarShiftRightU64x8(LU64A, 11);
    for LIndex := 0 to 7 do
      AssertEquals('AVX512 ShiftRightU64x8 lane ' + IntToStr(LIndex), LU64Expected.u[LIndex], LU64Result.u[LIndex]);

    LMask8Result := LAVX512.CmpEqU64x8(LU64A, LU64B);
    LMask8Expected := ScalarCmpEqU64x8(LU64A, LU64B);
    AssertEquals('AVX512 CmpEqU64x8 mask parity', Integer(LMask8Expected), Integer(LMask8Result));

    LMask8Result := LAVX512.CmpLtU64x8(LU64A, LU64B);
    LMask8Expected := ScalarCmpLtU64x8(LU64A, LU64B);
    AssertEquals('AVX512 CmpLtU64x8 mask parity', Integer(LMask8Expected), Integer(LMask8Result));
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_DispatchChangedHooks_MultiSubscriber_Dedup_And_Remove;
var
  LBeforeA: Integer;
  LBeforeB: Integer;
begin
  GDispatchHookCountA := 0;
  GDispatchHookCountB := 0;

  AddDispatchChangedHook(@DispatchHookProbeA);
  AddDispatchChangedHook(@DispatchHookProbeA);
  AddDispatchChangedHook(@DispatchHookProbeB);
  try
    AssertEquals('Duplicate hook should be ignored for hook A', 1, GDispatchHookCountA);
    AssertEquals('Second subscriber should be invoked immediately once', 1, GDispatchHookCountB);

    LBeforeA := GDispatchHookCountA;
    LBeforeB := GDispatchHookCountB;

    SetActiveBackend(sbScalar);

    AssertEquals('Hook A should fire exactly once per dispatch change', LBeforeA + 1, GDispatchHookCountA);
    AssertEquals('Hook B should fire exactly once per dispatch change', LBeforeB + 1, GDispatchHookCountB);

    RemoveDispatchChangedHook(@DispatchHookProbeA);
    LBeforeA := GDispatchHookCountA;
    LBeforeB := GDispatchHookCountB;

    ResetToAutomaticBackend;

    AssertEquals('Removed hook should not receive further notifications', LBeforeA, GDispatchHookCountA);
    AssertEquals('Remaining hook should keep receiving notifications', LBeforeB + 1, GDispatchHookCountB);
  finally
    RemoveDispatchChangedHook(@DispatchHookProbeA);
    RemoveDispatchChangedHook(@DispatchHookProbeB);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_AVX512_I16x32_I8x64_U8x64_MappingAndParity;
var
  LScalar: TSimdDispatchTable;
  LAVX512: TSimdDispatchTable;
  LCanRunAVX512: Boolean;
  LIndex: Integer;
  LI16A, LI16B, LI16Result, LI16Expected: TVecI16x32;
  LI8A, LI8B, LI8Result, LI8Expected: TVecI8x64;
  LU8A, LU8B, LU8Result, LU8Expected: TVecU8x64;
  LMask32Result, LMask32Expected: TMask32;
  LMask64Result, LMask64Expected: TMask64;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalar));

  if not TryGetRegisteredBackendDispatchTable(sbAVX512, LAVX512) then
    Exit;

  AssertTrue('AVX512 AddI16x32 should not be scalar slot',
    Pointer(LAVX512.AddI16x32) <> Pointer(LScalar.AddI16x32));
  AssertTrue('AVX512 CmpEqI16x32 should not be scalar slot',
    Pointer(LAVX512.CmpEqI16x32) <> Pointer(LScalar.CmpEqI16x32));
  AssertTrue('AVX512 ShiftRightArithI16x32 should not be scalar slot',
    Pointer(LAVX512.ShiftRightArithI16x32) <> Pointer(LScalar.ShiftRightArithI16x32));
  AssertTrue('AVX512 AddI8x64 should not be scalar slot',
    Pointer(LAVX512.AddI8x64) <> Pointer(LScalar.AddI8x64));
  AssertTrue('AVX512 CmpEqI8x64 should not be scalar slot',
    Pointer(LAVX512.CmpEqI8x64) <> Pointer(LScalar.CmpEqI8x64));
  AssertTrue('AVX512 MaxI8x64 should not be scalar slot',
    Pointer(LAVX512.MaxI8x64) <> Pointer(LScalar.MaxI8x64));
  AssertTrue('AVX512 AddU8x64 should not be scalar slot',
    Pointer(LAVX512.AddU8x64) <> Pointer(LScalar.AddU8x64));
  AssertTrue('AVX512 CmpEqU8x64 should not be scalar slot',
    Pointer(LAVX512.CmpEqU8x64) <> Pointer(LScalar.CmpEqU8x64));
  AssertTrue('AVX512 MaxU8x64 should not be scalar slot',
    Pointer(LAVX512.MaxU8x64) <> Pointer(LScalar.MaxU8x64));

  LCanRunAVX512 := LAVX512.BackendInfo.Available and TrySetActiveBackend(sbAVX512);
  if not LCanRunAVX512 then
    Exit;

  try
    for LIndex := 0 to 31 do
    begin
      LI16A.i[LIndex] := Int16(LIndex * 97 - 1400);
      LI16B.i[LIndex] := Int16(700 - LIndex * 41);
    end;

    for LIndex := 0 to 63 do
    begin
      LI8A.i[LIndex] := Int8((LIndex mod 31) - 15);
      LI8B.i[LIndex] := Int8(20 - (LIndex mod 29));
      LU8A.u[LIndex] := Byte((LIndex * 13) and $FF);
      LU8B.u[LIndex] := Byte((255 - LIndex * 9) and $FF);
    end;

    LI16Result := LAVX512.AddI16x32(LI16A, LI16B);
    LI16Expected := ScalarAddI16x32(LI16A, LI16B);
    for LIndex := 0 to 31 do
      AssertEquals('AVX512 AddI16x32 lane ' + IntToStr(LIndex), LI16Expected.i[LIndex], LI16Result.i[LIndex]);

    LI16Result := LAVX512.ShiftRightArithI16x32(LI16A, 3);
    LI16Expected := ScalarShiftRightArithI16x32(LI16A, 3);
    for LIndex := 0 to 31 do
      AssertEquals('AVX512 ShiftRightArithI16x32 lane ' + IntToStr(LIndex), LI16Expected.i[LIndex], LI16Result.i[LIndex]);

    LMask32Result := LAVX512.CmpLtI16x32(LI16A, LI16B);
    LMask32Expected := ScalarCmpLtI16x32(LI16A, LI16B);
    AssertEquals('AVX512 CmpLtI16x32 mask parity', Integer(LMask32Expected), Integer(LMask32Result));

    LI8Result := LAVX512.AndNotI8x64(LI8A, LI8B);
    LI8Expected := ScalarAndNotI8x64(LI8A, LI8B);
    for LIndex := 0 to 63 do
      AssertEquals('AVX512 AndNotI8x64 lane ' + IntToStr(LIndex), LI8Expected.i[LIndex], LI8Result.i[LIndex]);

    LMask64Result := LAVX512.CmpGtI8x64(LI8A, LI8B);
    LMask64Expected := ScalarCmpGtI8x64(LI8A, LI8B);
    AssertEquals('AVX512 CmpGtI8x64 mask parity', Int64(LMask64Expected), Int64(LMask64Result));

    LU8Result := LAVX512.AddU8x64(LU8A, LU8B);
    LU8Expected := ScalarAddU8x64(LU8A, LU8B);
    for LIndex := 0 to 63 do
      AssertEquals('AVX512 AddU8x64 lane ' + IntToStr(LIndex), LU8Expected.u[LIndex], LU8Result.u[LIndex]);

    LU8Result := LAVX512.XorU8x64(LU8A, LU8B);
    LU8Expected := ScalarXorU8x64(LU8A, LU8B);
    for LIndex := 0 to 63 do
      AssertEquals('AVX512 XorU8x64 lane ' + IntToStr(LIndex), LU8Expected.u[LIndex], LU8Result.u[LIndex]);

    LMask64Result := LAVX512.CmpLtU8x64(LU8A, LU8B);
    LMask64Expected := ScalarCmpLtU8x64(LU8A, LU8B);
    AssertEquals('AVX512 CmpLtU8x64 mask parity', Int64(LMask64Expected), Int64(LMask64Result));
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_AVX512_F32x16_F64x8_IEEE754_MappingAndParity;
var
  LScalar: TSimdDispatchTable;
  LAVX2: TSimdDispatchTable;
  LAVX512: TSimdDispatchTable;
  LHasAVX2: Boolean;
  LCanRunAVX512: Boolean;
  LIndex: Integer;

  LInF32x16, LRoundF32x16, LTruncF32x16, LFloorF32x16, LCeilF32x16: TVecF32x16;
  LInF64x8, LRoundF64x8, LTruncF64x8, LFloorF64x8, LCeilF64x8: TVecF64x8;
  LExpectedRoundF32x16, LExpectedTruncF32x16, LExpectedFloorF32x16, LExpectedCeilF32x16: TVecF32x16;
  LExpectedRoundF64x8, LExpectedTruncF64x8, LExpectedFloorF64x8, LExpectedCeilF64x8: TVecF64x8;

  LReduceInF32x16: TVecF32x16;
  LReduceInF64x8: TVecF64x8;
  LExpectedReduceAddF32x16, LExpectedReduceMulF32x16, LExpectedReduceMinF32x16, LExpectedReduceMaxF32x16: Single;
  LActualReduceAddF32x16, LActualReduceMulF32x16, LActualReduceMinF32x16, LActualReduceMaxF32x16: Single;
  LExpectedReduceAddF64x8, LExpectedReduceMulF64x8, LExpectedReduceMinF64x8, LExpectedReduceMaxF64x8: Double;
  LActualReduceAddF64x8, LActualReduceMulF64x8, LActualReduceMinF64x8, LActualReduceMaxF64x8: Double;

  procedure AssertSingleSemantics(const aName: string; const aExpected, aActual: Single);
  begin
    if IsNaN(aExpected) then
      AssertTrue(aName + ' expected NaN', IsNaN(aActual))
    else if IsInfinite(aExpected) then
      AssertTrue(aName + ' expected Inf sign',
        IsInfinite(aActual) and ((aActual > 0) = (aExpected > 0)))
    else
      AssertEquals(aName, aExpected, aActual, 1e-6);
  end;

  procedure AssertDoubleSemantics(const aName: string; const aExpected, aActual: Double);
  begin
    if IsNaN(aExpected) then
      AssertTrue(aName + ' expected NaN', IsNaN(aActual))
    else if IsInfinite(aExpected) then
      AssertTrue(aName + ' expected Inf sign',
        IsInfinite(aActual) and ((aActual > 0) = (aExpected > 0)))
    else
      AssertEquals(aName, aExpected, aActual, 1e-12);
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalar));

  if not TryGetRegisteredBackendDispatchTable(sbAVX512, LAVX512) then
    Exit;

  LHasAVX2 := TryGetRegisteredBackendDispatchTable(sbAVX2, LAVX2);

  AssertTrue('AVX512 RoundF32x16 should not be scalar slot',
    Pointer(LAVX512.RoundF32x16) <> Pointer(LScalar.RoundF32x16));
  AssertTrue('AVX512 TruncF32x16 should not be scalar slot',
    Pointer(LAVX512.TruncF32x16) <> Pointer(LScalar.TruncF32x16));
  AssertTrue('AVX512 FloorF32x16 should not be scalar slot',
    Pointer(LAVX512.FloorF32x16) <> Pointer(LScalar.FloorF32x16));
  AssertTrue('AVX512 CeilF32x16 should not be scalar slot',
    Pointer(LAVX512.CeilF32x16) <> Pointer(LScalar.CeilF32x16));

  AssertTrue('AVX512 RoundF64x8 should not be scalar slot',
    Pointer(LAVX512.RoundF64x8) <> Pointer(LScalar.RoundF64x8));
  AssertTrue('AVX512 TruncF64x8 should not be scalar slot',
    Pointer(LAVX512.TruncF64x8) <> Pointer(LScalar.TruncF64x8));
  AssertTrue('AVX512 FloorF64x8 should not be scalar slot',
    Pointer(LAVX512.FloorF64x8) <> Pointer(LScalar.FloorF64x8));
  AssertTrue('AVX512 CeilF64x8 should not be scalar slot',
    Pointer(LAVX512.CeilF64x8) <> Pointer(LScalar.CeilF64x8));

  if LHasAVX2 then
  begin
    AssertTrue('AVX512 RoundF32x16 should not reuse AVX2 slot',
      Pointer(LAVX512.RoundF32x16) <> Pointer(LAVX2.RoundF32x16));
    AssertTrue('AVX512 TruncF32x16 should not reuse AVX2 slot',
      Pointer(LAVX512.TruncF32x16) <> Pointer(LAVX2.TruncF32x16));
    AssertTrue('AVX512 FloorF32x16 should not reuse AVX2 slot',
      Pointer(LAVX512.FloorF32x16) <> Pointer(LAVX2.FloorF32x16));
    AssertTrue('AVX512 CeilF32x16 should not reuse AVX2 slot',
      Pointer(LAVX512.CeilF32x16) <> Pointer(LAVX2.CeilF32x16));

    AssertTrue('AVX512 RoundF64x8 should not reuse AVX2 slot',
      Pointer(LAVX512.RoundF64x8) <> Pointer(LAVX2.RoundF64x8));
    AssertTrue('AVX512 TruncF64x8 should not reuse AVX2 slot',
      Pointer(LAVX512.TruncF64x8) <> Pointer(LAVX2.TruncF64x8));
    AssertTrue('AVX512 FloorF64x8 should not reuse AVX2 slot',
      Pointer(LAVX512.FloorF64x8) <> Pointer(LAVX2.FloorF64x8));
    AssertTrue('AVX512 CeilF64x8 should not reuse AVX2 slot',
      Pointer(LAVX512.CeilF64x8) <> Pointer(LAVX2.CeilF64x8));
  end;

  LCanRunAVX512 := LAVX512.BackendInfo.Available and TrySetActiveBackend(sbAVX512);
  if not LCanRunAVX512 then
    Exit;

  try
    for LIndex := 0 to 15 do
    begin
      case (LIndex mod 5) of
        0: LInF32x16.f[LIndex] := 0.0 / 0.0;   // NaN
        1: LInF32x16.f[LIndex] := 1.0 / 0.0;   // +Inf
        2: LInF32x16.f[LIndex] := -1.0 / 0.0;  // -Inf
        3: LInF32x16.f[LIndex] := -3.75 + LIndex * 0.5;
      else
        LInF32x16.f[LIndex] := 2.5 - LIndex * 0.25;
      end;
      LReduceInF32x16.f[LIndex] := (LIndex - 7.5) * 0.375;
    end;

    for LIndex := 0 to 7 do
    begin
      case (LIndex mod 5) of
        0: LInF64x8.d[LIndex] := 0.0 / 0.0;    // NaN
        1: LInF64x8.d[LIndex] := 1.0 / 0.0;    // +Inf
        2: LInF64x8.d[LIndex] := -1.0 / 0.0;   // -Inf
        3: LInF64x8.d[LIndex] := -1234.875 + LIndex * 7.25;
      else
        LInF64x8.d[LIndex] := 42.5 - LIndex * 1.125;
      end;
      LReduceInF64x8.d[LIndex] := (LIndex - 3.0) * 1.5;
    end;

    LRoundF32x16 := LAVX512.RoundF32x16(LInF32x16);
    LTruncF32x16 := LAVX512.TruncF32x16(LInF32x16);
    LFloorF32x16 := LAVX512.FloorF32x16(LInF32x16);
    LCeilF32x16 := LAVX512.CeilF32x16(LInF32x16);
    LRoundF64x8 := LAVX512.RoundF64x8(LInF64x8);
    LTruncF64x8 := LAVX512.TruncF64x8(LInF64x8);
    LFloorF64x8 := LAVX512.FloorF64x8(LInF64x8);
    LCeilF64x8 := LAVX512.CeilF64x8(LInF64x8);

    LExpectedRoundF32x16 := ScalarRoundF32x16(LInF32x16);
    LExpectedTruncF32x16 := ScalarTruncF32x16(LInF32x16);
    LExpectedFloorF32x16 := ScalarFloorF32x16(LInF32x16);
    LExpectedCeilF32x16 := ScalarCeilF32x16(LInF32x16);
    LExpectedRoundF64x8 := ScalarRoundF64x8(LInF64x8);
    LExpectedTruncF64x8 := ScalarTruncF64x8(LInF64x8);
    LExpectedFloorF64x8 := ScalarFloorF64x8(LInF64x8);
    LExpectedCeilF64x8 := ScalarCeilF64x8(LInF64x8);

    for LIndex := 0 to 15 do
    begin
      AssertSingleSemantics('AVX512 RoundF32x16[' + IntToStr(LIndex) + ']',
        LExpectedRoundF32x16.f[LIndex], LRoundF32x16.f[LIndex]);
      AssertSingleSemantics('AVX512 TruncF32x16[' + IntToStr(LIndex) + ']',
        LExpectedTruncF32x16.f[LIndex], LTruncF32x16.f[LIndex]);
      AssertSingleSemantics('AVX512 FloorF32x16[' + IntToStr(LIndex) + ']',
        LExpectedFloorF32x16.f[LIndex], LFloorF32x16.f[LIndex]);
      AssertSingleSemantics('AVX512 CeilF32x16[' + IntToStr(LIndex) + ']',
        LExpectedCeilF32x16.f[LIndex], LCeilF32x16.f[LIndex]);
    end;

    for LIndex := 0 to 7 do
    begin
      AssertDoubleSemantics('AVX512 RoundF64x8[' + IntToStr(LIndex) + ']',
        LExpectedRoundF64x8.d[LIndex], LRoundF64x8.d[LIndex]);
      AssertDoubleSemantics('AVX512 TruncF64x8[' + IntToStr(LIndex) + ']',
        LExpectedTruncF64x8.d[LIndex], LTruncF64x8.d[LIndex]);
      AssertDoubleSemantics('AVX512 FloorF64x8[' + IntToStr(LIndex) + ']',
        LExpectedFloorF64x8.d[LIndex], LFloorF64x8.d[LIndex]);
      AssertDoubleSemantics('AVX512 CeilF64x8[' + IntToStr(LIndex) + ']',
        LExpectedCeilF64x8.d[LIndex], LCeilF64x8.d[LIndex]);
    end;

    LExpectedReduceAddF32x16 := ScalarReduceAddF32x16(LReduceInF32x16);
    LExpectedReduceMulF32x16 := ScalarReduceMulF32x16(LReduceInF32x16);
    LExpectedReduceMinF32x16 := ScalarReduceMinF32x16(LReduceInF32x16);
    LExpectedReduceMaxF32x16 := ScalarReduceMaxF32x16(LReduceInF32x16);
    LExpectedReduceAddF64x8 := ScalarReduceAddF64x8(LReduceInF64x8);
    LExpectedReduceMulF64x8 := ScalarReduceMulF64x8(LReduceInF64x8);
    LExpectedReduceMinF64x8 := ScalarReduceMinF64x8(LReduceInF64x8);
    LExpectedReduceMaxF64x8 := ScalarReduceMaxF64x8(LReduceInF64x8);

    LActualReduceAddF32x16 := LAVX512.ReduceAddF32x16(LReduceInF32x16);
    LActualReduceMulF32x16 := LAVX512.ReduceMulF32x16(LReduceInF32x16);
    LActualReduceMinF32x16 := LAVX512.ReduceMinF32x16(LReduceInF32x16);
    LActualReduceMaxF32x16 := LAVX512.ReduceMaxF32x16(LReduceInF32x16);
    LActualReduceAddF64x8 := LAVX512.ReduceAddF64x8(LReduceInF64x8);
    LActualReduceMulF64x8 := LAVX512.ReduceMulF64x8(LReduceInF64x8);
    LActualReduceMinF64x8 := LAVX512.ReduceMinF64x8(LReduceInF64x8);
    LActualReduceMaxF64x8 := LAVX512.ReduceMaxF64x8(LReduceInF64x8);

    AssertEquals('AVX512 ReduceAddF32x16 parity', LExpectedReduceAddF32x16, LActualReduceAddF32x16, 1e-5);
    AssertEquals('AVX512 ReduceMulF32x16 parity', LExpectedReduceMulF32x16, LActualReduceMulF32x16, 1e-4);
    AssertEquals('AVX512 ReduceMinF32x16 parity', LExpectedReduceMinF32x16, LActualReduceMinF32x16, 1e-6);
    AssertEquals('AVX512 ReduceMaxF32x16 parity', LExpectedReduceMaxF32x16, LActualReduceMaxF32x16, 1e-6);

    AssertEquals('AVX512 ReduceAddF64x8 parity', LExpectedReduceAddF64x8, LActualReduceAddF64x8, 1e-12);
    AssertEquals('AVX512 ReduceMulF64x8 parity', LExpectedReduceMulF64x8, LActualReduceMulF64x8, 1e-10);
    AssertEquals('AVX512 ReduceMinF64x8 parity', LExpectedReduceMinF64x8, LActualReduceMinF64x8, 1e-12);
    AssertEquals('AVX512 ReduceMaxF64x8 parity', LExpectedReduceMaxF64x8, LActualReduceMaxF64x8, 1e-12);
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_DispatchAPI.Test_BackendCapabilities_DoNotOverclaim_512BitOps;
var
  LBackend: TSimdBackend;
  LTable: TSimdDispatchTable;
  LScalar: TSimdDispatchTable;
  LClaims512: Boolean;

  function BackendName(const aBackend: TSimdBackend): string;
  begin
    case aBackend of
      sbScalar: Result := 'Scalar';
      sbSSE2: Result := 'SSE2';
      sbSSE3: Result := 'SSE3';
      sbSSSE3: Result := 'SSSE3';
      sbSSE41: Result := 'SSE41';
      sbSSE42: Result := 'SSE42';
      sbAVX2: Result := 'AVX2';
      sbAVX512: Result := 'AVX512';
      sbNEON: Result := 'NEON';
      sbRISCVV: Result := 'RISCVV';
      else Result := IntToStr(Ord(aBackend));
    end;
  end;

  procedure AssertNonScalarSlot(const aBackendName, aSlotName: string; aScalarSlot, aBackendSlot: Pointer);
  begin
    AssertTrue(aSlotName + ' missing: ' + aBackendName, aBackendSlot <> nil);
    AssertTrue(aSlotName + ' still scalar fallback while sc512BitOps is advertised: ' + aBackendName,
      aBackendSlot <> aScalarSlot);
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalar));

  for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
  begin
    if not TryGetRegisteredBackendDispatchTable(LBackend, LTable) then
      Continue;

    LClaims512 := sc512BitOps in LTable.BackendInfo.Capabilities;
    if not LClaims512 then
      Continue;

    AssertNonScalarSlot(BackendName(LBackend), 'AddU32x16', Pointer(LScalar.AddU32x16), Pointer(LTable.AddU32x16));
    AssertNonScalarSlot(BackendName(LBackend), 'CmpEqU32x16', Pointer(LScalar.CmpEqU32x16), Pointer(LTable.CmpEqU32x16));
    AssertNonScalarSlot(BackendName(LBackend), 'ShiftRightU32x16', Pointer(LScalar.ShiftRightU32x16), Pointer(LTable.ShiftRightU32x16));

    AssertNonScalarSlot(BackendName(LBackend), 'AddU64x8', Pointer(LScalar.AddU64x8), Pointer(LTable.AddU64x8));
    AssertNonScalarSlot(BackendName(LBackend), 'CmpEqU64x8', Pointer(LScalar.CmpEqU64x8), Pointer(LTable.CmpEqU64x8));
    AssertNonScalarSlot(BackendName(LBackend), 'ShiftRightU64x8', Pointer(LScalar.ShiftRightU64x8), Pointer(LTable.ShiftRightU64x8));

    AssertNonScalarSlot(BackendName(LBackend), 'AddI16x32', Pointer(LScalar.AddI16x32), Pointer(LTable.AddI16x32));
    AssertNonScalarSlot(BackendName(LBackend), 'CmpEqI16x32', Pointer(LScalar.CmpEqI16x32), Pointer(LTable.CmpEqI16x32));
    AssertNonScalarSlot(BackendName(LBackend), 'ShiftRightArithI16x32', Pointer(LScalar.ShiftRightArithI16x32), Pointer(LTable.ShiftRightArithI16x32));

    AssertNonScalarSlot(BackendName(LBackend), 'AddI8x64', Pointer(LScalar.AddI8x64), Pointer(LTable.AddI8x64));
    AssertNonScalarSlot(BackendName(LBackend), 'CmpEqI8x64', Pointer(LScalar.CmpEqI8x64), Pointer(LTable.CmpEqI8x64));
    AssertNonScalarSlot(BackendName(LBackend), 'MaxI8x64', Pointer(LScalar.MaxI8x64), Pointer(LTable.MaxI8x64));

    AssertNonScalarSlot(BackendName(LBackend), 'AddU8x64', Pointer(LScalar.AddU8x64), Pointer(LTable.AddU8x64));
    AssertNonScalarSlot(BackendName(LBackend), 'CmpEqU8x64', Pointer(LScalar.CmpEqU8x64), Pointer(LTable.CmpEqU8x64));
    AssertNonScalarSlot(BackendName(LBackend), 'MaxU8x64', Pointer(LScalar.MaxU8x64), Pointer(LTable.MaxU8x64));
  end;

  if TryGetRegisteredBackendDispatchTable(sbAVX512, LTable) then
    AssertTrue('AVX512 should advertise sc512BitOps once wide integer matrix is non-scalar',
      sc512BitOps in LTable.BackendInfo.Capabilities);
end;

procedure TTestCase_DispatchAPI.Test_AVX2_BenchmarkWideOps_NotScalar;
var
  LScalar: TSimdDispatchTable;
  LAVX2: TSimdDispatchTable;

  procedure AssertNonScalarSlot(const aSlotName: string; aScalarSlot, aAVX2Slot: Pointer);
  begin
    AssertTrue(aSlotName + ' missing: AVX2', aAVX2Slot <> nil);
    AssertTrue(aSlotName + ' still scalar fallback on AVX2 benchmark path', aAVX2Slot <> aScalarSlot);
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalar));

  if not IsVectorAsmEnabled then
    Exit;

  if not TryGetRegisteredBackendDispatchTable(sbAVX2, LAVX2) then
    Exit;

  AssertNonScalarSlot('AddI16x32', Pointer(LScalar.AddI16x32), Pointer(LAVX2.AddI16x32));
  AssertNonScalarSlot('MulU32x16', Pointer(LScalar.MulU32x16), Pointer(LAVX2.MulU32x16));
  AssertNonScalarSlot('AddU64x8', Pointer(LScalar.AddU64x8), Pointer(LAVX2.AddU64x8));
  AssertNonScalarSlot('MaxU8x64', Pointer(LScalar.MaxU8x64), Pointer(LAVX2.MaxU8x64));
end;

procedure TTestCase_DispatchAPI.Test_NonX86_DispatchTable_WiringChecklist_Grouped;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LTable: TSimdDispatchTable;
  LRegisteredCount: Integer;

  function BackendName(const aBackend: TSimdBackend): string;
  begin
    case aBackend of
      sbNEON: Result := 'NEON';
      sbRISCVV: Result := 'RISCVV';
      else Result := IntToStr(Ord(aBackend));
    end;
  end;

  procedure AssertSlotGroup(const aBackendName, aGroupName: string;
    const aNames: array of string; const aSlots: array of Pointer);
  var
    LIndex: Integer;
  begin
    AssertEquals(aGroupName + '.slot-count', Length(aNames), Length(aSlots));
    for LIndex := 0 to High(aNames) do
      AssertTrue(aGroupName + '.' + aNames[LIndex] + ' missing: ' + aBackendName,
        aSlots[LIndex] <> nil);
  end;
begin
  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LRegisteredCount := 0;

  for LBackend in LBackends do
  begin
    if not TryGetRegisteredBackendDispatchTable(LBackend, LTable) then
      Continue;

    Inc(LRegisteredCount);

    AssertSlotGroup(
      BackendName(LBackend),
      'WideI64AndU64',
      ['AndNotI64x2', 'ShiftLeftI64x2', 'ShiftRightI64x2', 'ShiftRightArithI64x2', 'MinI64x2', 'MaxI64x2',
       'AddU64x2', 'SubU64x2', 'AndU64x2', 'OrU64x2', 'XorU64x2', 'NotU64x2',
       'AndNotU64x2', 'CmpEqU64x2', 'CmpLtU64x2', 'CmpGtU64x2', 'MinU64x2', 'MaxU64x2'],
      [Pointer(LTable.AndNotI64x2), Pointer(LTable.ShiftLeftI64x2), Pointer(LTable.ShiftRightI64x2), Pointer(LTable.ShiftRightArithI64x2),
       Pointer(LTable.MinI64x2), Pointer(LTable.MaxI64x2), Pointer(LTable.AddU64x2), Pointer(LTable.SubU64x2),
       Pointer(LTable.AndU64x2), Pointer(LTable.OrU64x2), Pointer(LTable.XorU64x2), Pointer(LTable.NotU64x2),
       Pointer(LTable.AndNotU64x2), Pointer(LTable.CmpEqU64x2), Pointer(LTable.CmpLtU64x2), Pointer(LTable.CmpGtU64x2),
       Pointer(LTable.MinU64x2), Pointer(LTable.MaxU64x2)]
    );

    AssertSlotGroup(
      BackendName(LBackend),
      'Wide256I64x4U64x4',
      ['AddI64x4', 'SubI64x4', 'AndI64x4', 'OrI64x4', 'XorI64x4', 'NotI64x4', 'AndNotI64x4',
       'ShiftLeftI64x4', 'ShiftRightI64x4', 'ShiftRightArithI64x4', 'CmpEqI64x4', 'CmpLtI64x4', 'CmpGtI64x4', 'CmpLeI64x4', 'CmpGeI64x4', 'CmpNeI64x4',
       'AddU64x4', 'SubU64x4', 'AndU64x4', 'OrU64x4', 'XorU64x4', 'NotU64x4',
       'ShiftLeftU64x4', 'ShiftRightU64x4', 'CmpEqU64x4', 'CmpLtU64x4', 'CmpGtU64x4', 'CmpLeU64x4', 'CmpGeU64x4', 'CmpNeU64x4'],
      [Pointer(LTable.AddI64x4), Pointer(LTable.SubI64x4), Pointer(LTable.AndI64x4), Pointer(LTable.OrI64x4), Pointer(LTable.XorI64x4),
       Pointer(LTable.NotI64x4), Pointer(LTable.AndNotI64x4), Pointer(LTable.ShiftLeftI64x4), Pointer(LTable.ShiftRightI64x4), Pointer(LTable.ShiftRightArithI64x4),
       Pointer(LTable.CmpEqI64x4), Pointer(LTable.CmpLtI64x4), Pointer(LTable.CmpGtI64x4), Pointer(LTable.CmpLeI64x4), Pointer(LTable.CmpGeI64x4), Pointer(LTable.CmpNeI64x4),
       Pointer(LTable.AddU64x4), Pointer(LTable.SubU64x4), Pointer(LTable.AndU64x4), Pointer(LTable.OrU64x4), Pointer(LTable.XorU64x4), Pointer(LTable.NotU64x4),
       Pointer(LTable.ShiftLeftU64x4), Pointer(LTable.ShiftRightU64x4), Pointer(LTable.CmpEqU64x4), Pointer(LTable.CmpLtU64x4), Pointer(LTable.CmpGtU64x4),
       Pointer(LTable.CmpLeU64x4), Pointer(LTable.CmpGeU64x4), Pointer(LTable.CmpNeU64x4)]
    );

    AssertSlotGroup(
      BackendName(LBackend),
      'Wide512I64x8',
      ['AddI64x8', 'SubI64x8', 'AndI64x8', 'OrI64x8', 'XorI64x8', 'NotI64x8',
       'CmpEqI64x8', 'CmpLtI64x8', 'CmpGtI64x8', 'CmpLeI64x8', 'CmpGeI64x8', 'CmpNeI64x8'],
      [Pointer(LTable.AddI64x8), Pointer(LTable.SubI64x8), Pointer(LTable.AndI64x8), Pointer(LTable.OrI64x8),
       Pointer(LTable.XorI64x8), Pointer(LTable.NotI64x8), Pointer(LTable.CmpEqI64x8), Pointer(LTable.CmpLtI64x8),
       Pointer(LTable.CmpGtI64x8), Pointer(LTable.CmpLeI64x8), Pointer(LTable.CmpGeI64x8), Pointer(LTable.CmpNeI64x8)]
    );
  end;

  if LRegisteredCount = 0 then
    AssertTrue('No non-x86 backend registered on this host (allowed)', True);
end;

procedure TTestCase_DispatchAPI.Test_X86_DispatchTable_WiringChecklist_Grouped;
var
  LBackends: array[0..2] of TSimdBackend;
  LBackend: TSimdBackend;
  LTable: TSimdDispatchTable;
  LRegisteredCount: Integer;

  function BackendName(const aBackend: TSimdBackend): string;
  begin
    case aBackend of
      sbSSE2: Result := 'SSE2';
      sbAVX2: Result := 'AVX2';
      sbAVX512: Result := 'AVX512';
      else Result := IntToStr(Ord(aBackend));
    end;
  end;

  procedure AssertAssigned(const aBackendName, aSlotName: string; aSlot: Pointer);
  begin
    AssertTrue(aSlotName + ' missing: ' + aBackendName, aSlot <> nil);
  end;
begin
  LBackends[0] := sbSSE2;
  LBackends[1] := sbAVX2;
  LBackends[2] := sbAVX512;
  LRegisteredCount := 0;

  for LBackend in LBackends do
  begin
    if not TryGetRegisteredBackendDispatchTable(LBackend, LTable) then
      Continue;

    Inc(LRegisteredCount);

    AssertAssigned(BackendName(LBackend), 'AndNotI64x2', Pointer(LTable.AndNotI64x2));
    AssertAssigned(BackendName(LBackend), 'ShiftLeftI64x2', Pointer(LTable.ShiftLeftI64x2));
    AssertAssigned(BackendName(LBackend), 'ShiftRightI64x2', Pointer(LTable.ShiftRightI64x2));
    AssertAssigned(BackendName(LBackend), 'ShiftRightArithI64x2', Pointer(LTable.ShiftRightArithI64x2));
    AssertAssigned(BackendName(LBackend), 'MinI64x2', Pointer(LTable.MinI64x2));
    AssertAssigned(BackendName(LBackend), 'MaxI64x2', Pointer(LTable.MaxI64x2));

    AssertAssigned(BackendName(LBackend), 'AddU64x2', Pointer(LTable.AddU64x2));
    AssertAssigned(BackendName(LBackend), 'SubU64x2', Pointer(LTable.SubU64x2));
    AssertAssigned(BackendName(LBackend), 'AndU64x2', Pointer(LTable.AndU64x2));
    AssertAssigned(BackendName(LBackend), 'OrU64x2', Pointer(LTable.OrU64x2));
    AssertAssigned(BackendName(LBackend), 'XorU64x2', Pointer(LTable.XorU64x2));
    AssertAssigned(BackendName(LBackend), 'NotU64x2', Pointer(LTable.NotU64x2));
    AssertAssigned(BackendName(LBackend), 'AndNotU64x2', Pointer(LTable.AndNotU64x2));
    AssertAssigned(BackendName(LBackend), 'CmpEqU64x2', Pointer(LTable.CmpEqU64x2));
    AssertAssigned(BackendName(LBackend), 'CmpLtU64x2', Pointer(LTable.CmpLtU64x2));
    AssertAssigned(BackendName(LBackend), 'CmpGtU64x2', Pointer(LTable.CmpGtU64x2));
    AssertAssigned(BackendName(LBackend), 'MinU64x2', Pointer(LTable.MinU64x2));
    AssertAssigned(BackendName(LBackend), 'MaxU64x2', Pointer(LTable.MaxU64x2));

    AssertAssigned(BackendName(LBackend), 'AddI64x4', Pointer(LTable.AddI64x4));
    AssertAssigned(BackendName(LBackend), 'SubI64x4', Pointer(LTable.SubI64x4));
    AssertAssigned(BackendName(LBackend), 'AndI64x4', Pointer(LTable.AndI64x4));
    AssertAssigned(BackendName(LBackend), 'OrI64x4', Pointer(LTable.OrI64x4));
    AssertAssigned(BackendName(LBackend), 'XorI64x4', Pointer(LTable.XorI64x4));
    AssertAssigned(BackendName(LBackend), 'NotI64x4', Pointer(LTable.NotI64x4));
    AssertAssigned(BackendName(LBackend), 'AndNotI64x4', Pointer(LTable.AndNotI64x4));
    AssertAssigned(BackendName(LBackend), 'ShiftLeftI64x4', Pointer(LTable.ShiftLeftI64x4));
    AssertAssigned(BackendName(LBackend), 'ShiftRightI64x4', Pointer(LTable.ShiftRightI64x4));
    AssertAssigned(BackendName(LBackend), 'ShiftRightArithI64x4', Pointer(LTable.ShiftRightArithI64x4));
    AssertAssigned(BackendName(LBackend), 'CmpEqI64x4', Pointer(LTable.CmpEqI64x4));
    AssertAssigned(BackendName(LBackend), 'CmpLtI64x4', Pointer(LTable.CmpLtI64x4));
    AssertAssigned(BackendName(LBackend), 'CmpGtI64x4', Pointer(LTable.CmpGtI64x4));
    AssertAssigned(BackendName(LBackend), 'CmpLeI64x4', Pointer(LTable.CmpLeI64x4));
    AssertAssigned(BackendName(LBackend), 'CmpGeI64x4', Pointer(LTable.CmpGeI64x4));
    AssertAssigned(BackendName(LBackend), 'CmpNeI64x4', Pointer(LTable.CmpNeI64x4));

    AssertAssigned(BackendName(LBackend), 'AddU64x4', Pointer(LTable.AddU64x4));
    AssertAssigned(BackendName(LBackend), 'SubU64x4', Pointer(LTable.SubU64x4));
    AssertAssigned(BackendName(LBackend), 'AndU64x4', Pointer(LTable.AndU64x4));
    AssertAssigned(BackendName(LBackend), 'OrU64x4', Pointer(LTable.OrU64x4));
    AssertAssigned(BackendName(LBackend), 'XorU64x4', Pointer(LTable.XorU64x4));
    AssertAssigned(BackendName(LBackend), 'NotU64x4', Pointer(LTable.NotU64x4));
    AssertAssigned(BackendName(LBackend), 'ShiftLeftU64x4', Pointer(LTable.ShiftLeftU64x4));
    AssertAssigned(BackendName(LBackend), 'ShiftRightU64x4', Pointer(LTable.ShiftRightU64x4));
    AssertAssigned(BackendName(LBackend), 'CmpEqU64x4', Pointer(LTable.CmpEqU64x4));
    AssertAssigned(BackendName(LBackend), 'CmpLtU64x4', Pointer(LTable.CmpLtU64x4));
    AssertAssigned(BackendName(LBackend), 'CmpGtU64x4', Pointer(LTable.CmpGtU64x4));
    AssertAssigned(BackendName(LBackend), 'CmpLeU64x4', Pointer(LTable.CmpLeU64x4));
    AssertAssigned(BackendName(LBackend), 'CmpGeU64x4', Pointer(LTable.CmpGeU64x4));
    AssertAssigned(BackendName(LBackend), 'CmpNeU64x4', Pointer(LTable.CmpNeU64x4));

    AssertAssigned(BackendName(LBackend), 'AddI64x8', Pointer(LTable.AddI64x8));
    AssertAssigned(BackendName(LBackend), 'SubI64x8', Pointer(LTable.SubI64x8));
    AssertAssigned(BackendName(LBackend), 'AndI64x8', Pointer(LTable.AndI64x8));
    AssertAssigned(BackendName(LBackend), 'OrI64x8', Pointer(LTable.OrI64x8));
    AssertAssigned(BackendName(LBackend), 'XorI64x8', Pointer(LTable.XorI64x8));
    AssertAssigned(BackendName(LBackend), 'NotI64x8', Pointer(LTable.NotI64x8));
    AssertAssigned(BackendName(LBackend), 'CmpEqI64x8', Pointer(LTable.CmpEqI64x8));
    AssertAssigned(BackendName(LBackend), 'CmpLtI64x8', Pointer(LTable.CmpLtI64x8));
    AssertAssigned(BackendName(LBackend), 'CmpGtI64x8', Pointer(LTable.CmpGtI64x8));
    AssertAssigned(BackendName(LBackend), 'CmpLeI64x8', Pointer(LTable.CmpLeI64x8));
    AssertAssigned(BackendName(LBackend), 'CmpGeI64x8', Pointer(LTable.CmpGeI64x8));
    AssertAssigned(BackendName(LBackend), 'CmpNeI64x8', Pointer(LTable.CmpNeI64x8));
  end;

  if LRegisteredCount = 0 then
    AssertTrue('No x86 backend registered on this host (allowed)', True);
end;

procedure TTestCase_DispatchAPI.Test_NonX86_DispatchTable_WiringChecklist;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LTable: TSimdDispatchTable;
  LRegisteredCount: Integer;

  function BackendName(const aBackend: TSimdBackend): string;
  begin
    case aBackend of
      sbNEON: Result := 'NEON';
      sbRISCVV: Result := 'RISCVV';
      else Result := IntToStr(Ord(aBackend));
    end;
  end;
begin
  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LRegisteredCount := 0;

  for LBackend in LBackends do
  begin
    if not IsBackendRegistered(LBackend) then
      Continue;

    Inc(LRegisteredCount);
    AssertTrue('TryGetRegisteredBackendDispatchTable failed: ' + BackendName(LBackend),
      TryGetRegisteredBackendDispatchTable(LBackend, LTable));

    AssertTrue('AndNotI64x2 missing: ' + BackendName(LBackend), Assigned(LTable.AndNotI64x2));
    AssertTrue('ShiftLeftI64x2 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftLeftI64x2));
    AssertTrue('ShiftRightI64x2 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftRightI64x2));
    AssertTrue('ShiftRightArithI64x2 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftRightArithI64x2));
    AssertTrue('MinI64x2 missing: ' + BackendName(LBackend), Assigned(LTable.MinI64x2));
    AssertTrue('MaxI64x2 missing: ' + BackendName(LBackend), Assigned(LTable.MaxI64x2));

    AssertTrue('AddU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.AddU64x2));
    AssertTrue('SubU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.SubU64x2));
    AssertTrue('AndU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.AndU64x2));
    AssertTrue('OrU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.OrU64x2));
    AssertTrue('XorU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.XorU64x2));
    AssertTrue('NotU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.NotU64x2));
    AssertTrue('AndNotU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.AndNotU64x2));
    AssertTrue('CmpEqU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.CmpEqU64x2));
    AssertTrue('CmpLtU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.CmpLtU64x2));
    AssertTrue('CmpGtU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.CmpGtU64x2));
    AssertTrue('MinU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.MinU64x2));
    AssertTrue('MaxU64x2 missing: ' + BackendName(LBackend), Assigned(LTable.MaxU64x2));

    AssertTrue('AddI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.AddI64x4));
    AssertTrue('SubI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.SubI64x4));
    AssertTrue('AndI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.AndI64x4));
    AssertTrue('OrI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.OrI64x4));
    AssertTrue('XorI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.XorI64x4));
    AssertTrue('NotI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.NotI64x4));
    AssertTrue('AndNotI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.AndNotI64x4));
    AssertTrue('ShiftLeftI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftLeftI64x4));
    AssertTrue('ShiftRightI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftRightI64x4));
    AssertTrue('ShiftRightArithI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftRightArithI64x4));
    AssertTrue('CmpEqI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpEqI64x4));
    AssertTrue('CmpLtI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpLtI64x4));
    AssertTrue('CmpGtI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpGtI64x4));
    AssertTrue('CmpLeI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpLeI64x4));
    AssertTrue('CmpGeI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpGeI64x4));
    AssertTrue('CmpNeI64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpNeI64x4));

    AssertTrue('AddU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.AddU64x4));
    AssertTrue('SubU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.SubU64x4));
    AssertTrue('AndU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.AndU64x4));
    AssertTrue('OrU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.OrU64x4));
    AssertTrue('XorU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.XorU64x4));
    AssertTrue('NotU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.NotU64x4));
    AssertTrue('ShiftLeftU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftLeftU64x4));
    AssertTrue('ShiftRightU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.ShiftRightU64x4));
    AssertTrue('CmpEqU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpEqU64x4));
    AssertTrue('CmpLtU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpLtU64x4));
    AssertTrue('CmpGtU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpGtU64x4));
    AssertTrue('CmpLeU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpLeU64x4));
    AssertTrue('CmpGeU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpGeU64x4));
    AssertTrue('CmpNeU64x4 missing: ' + BackendName(LBackend), Assigned(LTable.CmpNeU64x4));

    AssertTrue('AddI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.AddI64x8));
    AssertTrue('SubI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.SubI64x8));
    AssertTrue('AndI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.AndI64x8));
    AssertTrue('OrI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.OrI64x8));
    AssertTrue('XorI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.XorI64x8));
    AssertTrue('NotI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.NotI64x8));
    AssertTrue('CmpEqI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.CmpEqI64x8));
    AssertTrue('CmpLtI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.CmpLtI64x8));
    AssertTrue('CmpGtI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.CmpGtI64x8));
    AssertTrue('CmpLeI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.CmpLeI64x8));
    AssertTrue('CmpGeI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.CmpGeI64x8));
    AssertTrue('CmpNeI64x8 missing: ' + BackendName(LBackend), Assigned(LTable.CmpNeI64x8));
  end;

  if LRegisteredCount = 0 then
    AssertTrue('No non-x86 backend registered on this host (allowed)', True);
end;

procedure TTestCase_DispatchAPI.Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LScalarTable: TSimdDispatchTable;
  LBackendTable: TSimdDispatchTable;
  LCheckedBackends: Integer;

  function BackendName(const aBackend: TSimdBackend): string;
  begin
    case aBackend of
      sbNEON: Result := 'NEON';
      sbRISCVV: Result := 'RISCVV';
      else Result := IntToStr(Ord(aBackend));
    end;
  end;

  procedure AssertNativeSlotNotScalar(const aBackendName, aSlotName: string; const aScalarSlot, aBackendSlot: Pointer);
  begin
    AssertTrue(aSlotName + ' missing: ' + aBackendName, aBackendSlot <> nil);
    AssertTrue(aSlotName + ' unexpectedly falls back to scalar slot: ' + aBackendName,
      aBackendSlot <> aScalarSlot);
  end;
begin
  AssertTrue('Scalar dispatch table should be available',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LCheckedBackends := 0;

  for LBackend in LBackends do
  begin
    if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
      Continue;

    Inc(LCheckedBackends);

    // Native-slot contract (only for explicitly marked non-x86 wide Floor/Ceil targets).
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FloorF32x8',
      Pointer(LScalarTable.FloorF32x8), Pointer(LBackendTable.FloorF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'CeilF32x8',
      Pointer(LScalarTable.CeilF32x8), Pointer(LBackendTable.CeilF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'RoundF32x8',
      Pointer(LScalarTable.RoundF32x8), Pointer(LBackendTable.RoundF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'TruncF32x8',
      Pointer(LScalarTable.TruncF32x8), Pointer(LBackendTable.TruncF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FloorF64x4',
      Pointer(LScalarTable.FloorF64x4), Pointer(LBackendTable.FloorF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'CeilF64x4',
      Pointer(LScalarTable.CeilF64x4), Pointer(LBackendTable.CeilF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'RoundF64x4',
      Pointer(LScalarTable.RoundF64x4), Pointer(LBackendTable.RoundF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'TruncF64x4',
      Pointer(LScalarTable.TruncF64x4), Pointer(LBackendTable.TruncF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FloorF32x16',
      Pointer(LScalarTable.FloorF32x16), Pointer(LBackendTable.FloorF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'CeilF32x16',
      Pointer(LScalarTable.CeilF32x16), Pointer(LBackendTable.CeilF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'RoundF32x16',
      Pointer(LScalarTable.RoundF32x16), Pointer(LBackendTable.RoundF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'TruncF32x16',
      Pointer(LScalarTable.TruncF32x16), Pointer(LBackendTable.TruncF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FloorF64x8',
      Pointer(LScalarTable.FloorF64x8), Pointer(LBackendTable.FloorF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'CeilF64x8',
      Pointer(LScalarTable.CeilF64x8), Pointer(LBackendTable.CeilF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'RoundF64x8',
      Pointer(LScalarTable.RoundF64x8), Pointer(LBackendTable.RoundF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'TruncF64x8',
      Pointer(LScalarTable.TruncF64x8), Pointer(LBackendTable.TruncF64x8));

    AssertNativeSlotNotScalar(BackendName(LBackend), 'AddF32x8',
      Pointer(LScalarTable.AddF32x8), Pointer(LBackendTable.AddF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SubF32x8',
      Pointer(LScalarTable.SubF32x8), Pointer(LBackendTable.SubF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MulF32x8',
      Pointer(LScalarTable.MulF32x8), Pointer(LBackendTable.MulF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'DivF32x8',
      Pointer(LScalarTable.DivF32x8), Pointer(LBackendTable.DivF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MinF32x8',
      Pointer(LScalarTable.MinF32x8), Pointer(LBackendTable.MinF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MaxF32x8',
      Pointer(LScalarTable.MaxF32x8), Pointer(LBackendTable.MaxF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'AbsF32x8',
      Pointer(LScalarTable.AbsF32x8), Pointer(LBackendTable.AbsF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SqrtF32x8',
      Pointer(LScalarTable.SqrtF32x8), Pointer(LBackendTable.SqrtF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FmaF32x8',
      Pointer(LScalarTable.FmaF32x8), Pointer(LBackendTable.FmaF32x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'ClampF32x8',
      Pointer(LScalarTable.ClampF32x8), Pointer(LBackendTable.ClampF32x8));

    AssertNativeSlotNotScalar(BackendName(LBackend), 'AddF64x4',
      Pointer(LScalarTable.AddF64x4), Pointer(LBackendTable.AddF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SubF64x4',
      Pointer(LScalarTable.SubF64x4), Pointer(LBackendTable.SubF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MulF64x4',
      Pointer(LScalarTable.MulF64x4), Pointer(LBackendTable.MulF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'DivF64x4',
      Pointer(LScalarTable.DivF64x4), Pointer(LBackendTable.DivF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MinF64x4',
      Pointer(LScalarTable.MinF64x4), Pointer(LBackendTable.MinF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MaxF64x4',
      Pointer(LScalarTable.MaxF64x4), Pointer(LBackendTable.MaxF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'AbsF64x4',
      Pointer(LScalarTable.AbsF64x4), Pointer(LBackendTable.AbsF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SqrtF64x4',
      Pointer(LScalarTable.SqrtF64x4), Pointer(LBackendTable.SqrtF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FmaF64x4',
      Pointer(LScalarTable.FmaF64x4), Pointer(LBackendTable.FmaF64x4));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'ClampF64x4',
      Pointer(LScalarTable.ClampF64x4), Pointer(LBackendTable.ClampF64x4));

    AssertNativeSlotNotScalar(BackendName(LBackend), 'AddF32x16',
      Pointer(LScalarTable.AddF32x16), Pointer(LBackendTable.AddF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SubF32x16',
      Pointer(LScalarTable.SubF32x16), Pointer(LBackendTable.SubF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MulF32x16',
      Pointer(LScalarTable.MulF32x16), Pointer(LBackendTable.MulF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'DivF32x16',
      Pointer(LScalarTable.DivF32x16), Pointer(LBackendTable.DivF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MinF32x16',
      Pointer(LScalarTable.MinF32x16), Pointer(LBackendTable.MinF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MaxF32x16',
      Pointer(LScalarTable.MaxF32x16), Pointer(LBackendTable.MaxF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'AbsF32x16',
      Pointer(LScalarTable.AbsF32x16), Pointer(LBackendTable.AbsF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SqrtF32x16',
      Pointer(LScalarTable.SqrtF32x16), Pointer(LBackendTable.SqrtF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FmaF32x16',
      Pointer(LScalarTable.FmaF32x16), Pointer(LBackendTable.FmaF32x16));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'ClampF32x16',
      Pointer(LScalarTable.ClampF32x16), Pointer(LBackendTable.ClampF32x16));

    AssertNativeSlotNotScalar(BackendName(LBackend), 'AddF64x8',
      Pointer(LScalarTable.AddF64x8), Pointer(LBackendTable.AddF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SubF64x8',
      Pointer(LScalarTable.SubF64x8), Pointer(LBackendTable.SubF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MulF64x8',
      Pointer(LScalarTable.MulF64x8), Pointer(LBackendTable.MulF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'DivF64x8',
      Pointer(LScalarTable.DivF64x8), Pointer(LBackendTable.DivF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MinF64x8',
      Pointer(LScalarTable.MinF64x8), Pointer(LBackendTable.MinF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'MaxF64x8',
      Pointer(LScalarTable.MaxF64x8), Pointer(LBackendTable.MaxF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'AbsF64x8',
      Pointer(LScalarTable.AbsF64x8), Pointer(LBackendTable.AbsF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'SqrtF64x8',
      Pointer(LScalarTable.SqrtF64x8), Pointer(LBackendTable.SqrtF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'FmaF64x8',
      Pointer(LScalarTable.FmaF64x8), Pointer(LBackendTable.FmaF64x8));
    AssertNativeSlotNotScalar(BackendName(LBackend), 'ClampF64x8',
      Pointer(LScalarTable.ClampF64x8), Pointer(LBackendTable.ClampF64x8));
  end;

  if LCheckedBackends = 0 then
    AssertTrue('No non-x86 backend registered on this host (allowed)', True);
end;

function NonX86BackendName(const aBackend: TSimdBackend): string;
begin
  case aBackend of
    sbNEON: Result := 'NEON';
    sbRISCVV: Result := 'RISCVV';
    else Result := IntToStr(Ord(aBackend));
  end;
end;

procedure TTestCase_NonX86BackendParity.Test_NativeWideFloorCeilSlots_NotScalar_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LScalarTable: TSimdDispatchTable;
  LBackendTable: TSimdDispatchTable;
  LCheckedBackends: Integer;

  procedure AssertNativeSlotNotScalar(const aBackendName, aSlotName: string; const aScalarSlot, aBackendSlot: Pointer);
  begin
    AssertTrue(aSlotName + ' missing: ' + aBackendName, aBackendSlot <> nil);
    AssertTrue(aSlotName + ' unexpectedly falls back to scalar slot: ' + aBackendName,
      aBackendSlot <> aScalarSlot);
  end;
begin
  AssertTrue('Scalar dispatch table should be available',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LCheckedBackends := 0;

  for LBackend in LBackends do
  begin
    if not IsBackendRegistered(LBackend) then
      Continue;
    if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
      Continue;

    Inc(LCheckedBackends);

    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FloorF32x8',
      Pointer(LScalarTable.FloorF32x8), Pointer(LBackendTable.FloorF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'CeilF32x8',
      Pointer(LScalarTable.CeilF32x8), Pointer(LBackendTable.CeilF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'RoundF32x8',
      Pointer(LScalarTable.RoundF32x8), Pointer(LBackendTable.RoundF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'TruncF32x8',
      Pointer(LScalarTable.TruncF32x8), Pointer(LBackendTable.TruncF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FloorF64x4',
      Pointer(LScalarTable.FloorF64x4), Pointer(LBackendTable.FloorF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'CeilF64x4',
      Pointer(LScalarTable.CeilF64x4), Pointer(LBackendTable.CeilF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'RoundF64x4',
      Pointer(LScalarTable.RoundF64x4), Pointer(LBackendTable.RoundF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'TruncF64x4',
      Pointer(LScalarTable.TruncF64x4), Pointer(LBackendTable.TruncF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FloorF32x16',
      Pointer(LScalarTable.FloorF32x16), Pointer(LBackendTable.FloorF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'CeilF32x16',
      Pointer(LScalarTable.CeilF32x16), Pointer(LBackendTable.CeilF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'RoundF32x16',
      Pointer(LScalarTable.RoundF32x16), Pointer(LBackendTable.RoundF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'TruncF32x16',
      Pointer(LScalarTable.TruncF32x16), Pointer(LBackendTable.TruncF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FloorF64x8',
      Pointer(LScalarTable.FloorF64x8), Pointer(LBackendTable.FloorF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'CeilF64x8',
      Pointer(LScalarTable.CeilF64x8), Pointer(LBackendTable.CeilF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'RoundF64x8',
      Pointer(LScalarTable.RoundF64x8), Pointer(LBackendTable.RoundF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'TruncF64x8',
      Pointer(LScalarTable.TruncF64x8), Pointer(LBackendTable.TruncF64x8));

    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AddF32x8',
      Pointer(LScalarTable.AddF32x8), Pointer(LBackendTable.AddF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SubF32x8',
      Pointer(LScalarTable.SubF32x8), Pointer(LBackendTable.SubF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MulF32x8',
      Pointer(LScalarTable.MulF32x8), Pointer(LBackendTable.MulF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'DivF32x8',
      Pointer(LScalarTable.DivF32x8), Pointer(LBackendTable.DivF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MinF32x8',
      Pointer(LScalarTable.MinF32x8), Pointer(LBackendTable.MinF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MaxF32x8',
      Pointer(LScalarTable.MaxF32x8), Pointer(LBackendTable.MaxF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AbsF32x8',
      Pointer(LScalarTable.AbsF32x8), Pointer(LBackendTable.AbsF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SqrtF32x8',
      Pointer(LScalarTable.SqrtF32x8), Pointer(LBackendTable.SqrtF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FmaF32x8',
      Pointer(LScalarTable.FmaF32x8), Pointer(LBackendTable.FmaF32x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'ClampF32x8',
      Pointer(LScalarTable.ClampF32x8), Pointer(LBackendTable.ClampF32x8));

    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AddF64x4',
      Pointer(LScalarTable.AddF64x4), Pointer(LBackendTable.AddF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SubF64x4',
      Pointer(LScalarTable.SubF64x4), Pointer(LBackendTable.SubF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MulF64x4',
      Pointer(LScalarTable.MulF64x4), Pointer(LBackendTable.MulF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'DivF64x4',
      Pointer(LScalarTable.DivF64x4), Pointer(LBackendTable.DivF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MinF64x4',
      Pointer(LScalarTable.MinF64x4), Pointer(LBackendTable.MinF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MaxF64x4',
      Pointer(LScalarTable.MaxF64x4), Pointer(LBackendTable.MaxF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AbsF64x4',
      Pointer(LScalarTable.AbsF64x4), Pointer(LBackendTable.AbsF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SqrtF64x4',
      Pointer(LScalarTable.SqrtF64x4), Pointer(LBackendTable.SqrtF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FmaF64x4',
      Pointer(LScalarTable.FmaF64x4), Pointer(LBackendTable.FmaF64x4));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'ClampF64x4',
      Pointer(LScalarTable.ClampF64x4), Pointer(LBackendTable.ClampF64x4));

    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AddF32x16',
      Pointer(LScalarTable.AddF32x16), Pointer(LBackendTable.AddF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SubF32x16',
      Pointer(LScalarTable.SubF32x16), Pointer(LBackendTable.SubF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MulF32x16',
      Pointer(LScalarTable.MulF32x16), Pointer(LBackendTable.MulF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'DivF32x16',
      Pointer(LScalarTable.DivF32x16), Pointer(LBackendTable.DivF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MinF32x16',
      Pointer(LScalarTable.MinF32x16), Pointer(LBackendTable.MinF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MaxF32x16',
      Pointer(LScalarTable.MaxF32x16), Pointer(LBackendTable.MaxF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AbsF32x16',
      Pointer(LScalarTable.AbsF32x16), Pointer(LBackendTable.AbsF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SqrtF32x16',
      Pointer(LScalarTable.SqrtF32x16), Pointer(LBackendTable.SqrtF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FmaF32x16',
      Pointer(LScalarTable.FmaF32x16), Pointer(LBackendTable.FmaF32x16));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'ClampF32x16',
      Pointer(LScalarTable.ClampF32x16), Pointer(LBackendTable.ClampF32x16));

    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AddF64x8',
      Pointer(LScalarTable.AddF64x8), Pointer(LBackendTable.AddF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SubF64x8',
      Pointer(LScalarTable.SubF64x8), Pointer(LBackendTable.SubF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MulF64x8',
      Pointer(LScalarTable.MulF64x8), Pointer(LBackendTable.MulF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'DivF64x8',
      Pointer(LScalarTable.DivF64x8), Pointer(LBackendTable.DivF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MinF64x8',
      Pointer(LScalarTable.MinF64x8), Pointer(LBackendTable.MinF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'MaxF64x8',
      Pointer(LScalarTable.MaxF64x8), Pointer(LBackendTable.MaxF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'AbsF64x8',
      Pointer(LScalarTable.AbsF64x8), Pointer(LBackendTable.AbsF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'SqrtF64x8',
      Pointer(LScalarTable.SqrtF64x8), Pointer(LBackendTable.SqrtF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'FmaF64x8',
      Pointer(LScalarTable.FmaF64x8), Pointer(LBackendTable.FmaF64x8));
    AssertNativeSlotNotScalar(NonX86BackendName(LBackend), 'ClampF64x8',
      Pointer(LScalarTable.ClampF64x8), Pointer(LBackendTable.ClampF64x8));
  end;

  if LCheckedBackends = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_MinimalDispatchParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LA, LB: TVecF32x4;
  LVecByBackend, LVecByScalar: TVecF32x4;
  LMaskByBackend, LMaskByScalar: TMask4;
  LReduceByBackend, LReduceByScalar: Single;
  LIndex: Integer;
  LChecked: Integer;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  LA.f[0] := 1.25;  LB.f[0] := 2.0;
  LA.f[1] := -4.0;  LB.f[1] := 3.5;
  LA.f[2] := 0.0;   LB.f[2] := -1.0;
  LA.f[3] := 7.75;  LB.f[3] := 7.75;

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('AddF32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddF32x4));
      AssertTrue('CmpLtF32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtF32x4));
      AssertTrue('ReduceAddF32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ReduceAddF32x4));

      LVecByBackend := LBackendTable.AddF32x4(LA, LB);
      LVecByScalar := LScalarTable.AddF32x4(LA, LB);
      for LIndex := 0 to 3 do
        AssertEquals('AddF32x4 parity lane ' + IntToStr(LIndex) + ': ' + NonX86BackendName(LBackend),
          LVecByScalar.f[LIndex], LVecByBackend.f[LIndex], 1e-6);

      LMaskByBackend := LBackendTable.CmpLtF32x4(LA, LB);
      LMaskByScalar := LScalarTable.CmpLtF32x4(LA, LB);
      AssertEquals('CmpLtF32x4 parity: ' + NonX86BackendName(LBackend),
        Integer(LMaskByScalar), Integer(LMaskByBackend));

      LReduceByBackend := LBackendTable.ReduceAddF32x4(LA);
      LReduceByScalar := LScalarTable.ReduceAddF32x4(LA);
      AssertEquals('ReduceAddF32x4 parity: ' + NonX86BackendName(LBackend),
        LReduceByScalar, LReduceByBackend, 1e-6);

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_ExtendedFloatParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LF64A, LF64B: TVecF64x2;
  LF64ByBackend, LF64ByScalar: TVecF64x2;
  LF32A, LF32B: TVecF32x8;
  LF32ByBackend, LF32ByScalar: TVecF32x8;
  LF32x16A, LF32x16B, LF32x16C: TVecF32x16;
  LF32x16Min, LF32x16Max: TVecF32x16;
  LF32x16ByBackend, LF32x16ByScalar: TVecF32x16;
  LF64x8A, LF64x8B, LF64x8C: TVecF64x8;
  LF64x8Min, LF64x8Max: TVecF64x8;
  LF64x8ByBackend, LF64x8ByScalar: TVecF64x8;
  LMask2ByBackend, LMask2ByScalar: TMask2;
  LMask8ByBackend, LMask8ByScalar: TMask8;
  LReduceF64ByBackend, LReduceF64ByScalar: Double;
  LReduceF32ByBackend, LReduceF32ByScalar: Single;
  LIndex: Integer;
  LChecked: Integer;

  procedure AssertVecF32x16Equal(const aOp, aBackendName: string; const aExpected, aActual: TVecF32x16; const aEps: Single);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 15 do
      AssertEquals(aOp + ' parity lane ' + IntToStr(LLane) + ': ' + aBackendName,
        aExpected.f[LLane], aActual.f[LLane], aEps);
  end;

  procedure AssertVecF64x8Equal(const aOp, aBackendName: string; const aExpected, aActual: TVecF64x8; const aEps: Double);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' parity lane ' + IntToStr(LLane) + ': ' + aBackendName,
        aExpected.d[LLane], aActual.d[LLane], aEps);
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  LF64A.d[0] := 1.5;    LF64B.d[0] := -2.25;
  LF64A.d[1] := -8.75;  LF64B.d[1] := 10.0;

  LF32A.f[0] := 1.0;    LF32B.f[0] := 2.5;
  LF32A.f[1] := -3.5;   LF32B.f[1] := 4.0;
  LF32A.f[2] := 0.0;    LF32B.f[2] := -1.0;
  LF32A.f[3] := 7.25;   LF32B.f[3] := 7.25;
  LF32A.f[4] := -9.0;   LF32B.f[4] := 1.0;
  LF32A.f[5] := 5.5;    LF32B.f[5] := -2.0;
  LF32A.f[6] := 100.0;  LF32B.f[6] := -99.5;
  LF32A.f[7] := -0.25;  LF32B.f[7] := 0.5;

  for LIndex := 0 to 15 do
  begin
    LF32x16A.f[LIndex] := (LIndex - 8) * 1.25;
    LF32x16B.f[LIndex] := (LIndex + 1) * 0.5 + 1.0;
    LF32x16C.f[LIndex] := (LIndex mod 5) - 2.0;
    LF32x16Min.f[LIndex] := -6.0 + LIndex * 0.1;
    LF32x16Max.f[LIndex] := 6.0 + LIndex * 0.1;
  end;

  for LIndex := 0 to 7 do
  begin
    LF64x8A.d[LIndex] := (LIndex - 3) * 2.75;
    LF64x8B.d[LIndex] := (LIndex + 1) * 0.75 + 1.0;
    LF64x8C.d[LIndex] := (LIndex mod 4) - 1.5;
    LF64x8Min.d[LIndex] := -12.0 + LIndex;
    LF64x8Max.d[LIndex] := 12.0 + LIndex;
  end;

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('AddF64x2 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddF64x2));
      AssertTrue('CmpLtF64x2 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtF64x2));
      AssertTrue('ReduceAddF64x2 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ReduceAddF64x2));
      AssertTrue('AddF32x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddF32x8));
      AssertTrue('CmpLtF32x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtF32x8));
      AssertTrue('ReduceAddF32x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ReduceAddF32x8));
      AssertTrue('Wide float math slots missing: ' + NonX86BackendName(LBackend),
        Assigned(LBackendTable.AddF32x16) and Assigned(LBackendTable.SubF32x16) and
        Assigned(LBackendTable.MulF32x16) and Assigned(LBackendTable.DivF32x16) and
        Assigned(LBackendTable.MinF32x16) and Assigned(LBackendTable.MaxF32x16) and
        Assigned(LBackendTable.AbsF32x16) and Assigned(LBackendTable.SqrtF32x16) and
        Assigned(LBackendTable.FmaF32x16) and Assigned(LBackendTable.ClampF32x16) and
        Assigned(LBackendTable.AddF64x8) and Assigned(LBackendTable.SubF64x8) and
        Assigned(LBackendTable.MulF64x8) and Assigned(LBackendTable.DivF64x8) and
        Assigned(LBackendTable.MinF64x8) and Assigned(LBackendTable.MaxF64x8) and
        Assigned(LBackendTable.AbsF64x8) and Assigned(LBackendTable.SqrtF64x8) and
        Assigned(LBackendTable.FmaF64x8) and Assigned(LBackendTable.ClampF64x8));

      LF64ByBackend := LBackendTable.AddF64x2(LF64A, LF64B);
      LF64ByScalar := LScalarTable.AddF64x2(LF64A, LF64B);
      for LIndex := 0 to 1 do
        AssertEquals('AddF64x2 parity lane ' + IntToStr(LIndex) + ': ' + NonX86BackendName(LBackend),
          LF64ByScalar.d[LIndex], LF64ByBackend.d[LIndex], 1e-12);

      LMask2ByBackend := LBackendTable.CmpLtF64x2(LF64A, LF64B);
      LMask2ByScalar := LScalarTable.CmpLtF64x2(LF64A, LF64B);
      AssertEquals('CmpLtF64x2 parity: ' + NonX86BackendName(LBackend),
        Integer(LMask2ByScalar), Integer(LMask2ByBackend));

      LReduceF64ByBackend := LBackendTable.ReduceAddF64x2(LF64A);
      LReduceF64ByScalar := LScalarTable.ReduceAddF64x2(LF64A);
      AssertEquals('ReduceAddF64x2 parity: ' + NonX86BackendName(LBackend),
        LReduceF64ByScalar, LReduceF64ByBackend, 1e-12);

      LF32ByBackend := LBackendTable.AddF32x8(LF32A, LF32B);
      LF32ByScalar := LScalarTable.AddF32x8(LF32A, LF32B);
      for LIndex := 0 to 7 do
        AssertEquals('AddF32x8 parity lane ' + IntToStr(LIndex) + ': ' + NonX86BackendName(LBackend),
          LF32ByScalar.f[LIndex], LF32ByBackend.f[LIndex], 1e-6);

      LMask8ByBackend := LBackendTable.CmpLtF32x8(LF32A, LF32B);
      LMask8ByScalar := LScalarTable.CmpLtF32x8(LF32A, LF32B);
      AssertEquals('CmpLtF32x8 parity: ' + NonX86BackendName(LBackend),
        Integer(LMask8ByScalar), Integer(LMask8ByBackend));

      LReduceF32ByBackend := LBackendTable.ReduceAddF32x8(LF32A);
      LReduceF32ByScalar := LScalarTable.ReduceAddF32x8(LF32A);
      AssertEquals('ReduceAddF32x8 parity: ' + NonX86BackendName(LBackend),
        LReduceF32ByScalar, LReduceF32ByBackend, 1e-6);

      LF32x16ByBackend := LBackendTable.AddF32x16(LF32x16A, LF32x16B);
      LF32x16ByScalar := LScalarTable.AddF32x16(LF32x16A, LF32x16B);
      AssertVecF32x16Equal('AddF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 1e-6);

      LF32x16ByBackend := LBackendTable.SubF32x16(LF32x16A, LF32x16B);
      LF32x16ByScalar := LScalarTable.SubF32x16(LF32x16A, LF32x16B);
      AssertVecF32x16Equal('SubF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 1e-6);

      LF32x16ByBackend := LBackendTable.MulF32x16(LF32x16A, LF32x16B);
      LF32x16ByScalar := LScalarTable.MulF32x16(LF32x16A, LF32x16B);
      AssertVecF32x16Equal('MulF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 1e-5);

      LF32x16ByBackend := LBackendTable.DivF32x16(LF32x16A, LF32x16B);
      LF32x16ByScalar := LScalarTable.DivF32x16(LF32x16A, LF32x16B);
      AssertVecF32x16Equal('DivF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 1e-6);

      LF32x16ByBackend := LBackendTable.MinF32x16(LF32x16A, LF32x16B);
      LF32x16ByScalar := LScalarTable.MinF32x16(LF32x16A, LF32x16B);
      AssertVecF32x16Equal('MinF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 0.0);

      LF32x16ByBackend := LBackendTable.MaxF32x16(LF32x16A, LF32x16B);
      LF32x16ByScalar := LScalarTable.MaxF32x16(LF32x16A, LF32x16B);
      AssertVecF32x16Equal('MaxF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 0.0);

      LF32x16ByBackend := LBackendTable.AbsF32x16(LF32x16A);
      LF32x16ByScalar := LScalarTable.AbsF32x16(LF32x16A);
      AssertVecF32x16Equal('AbsF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 0.0);

      LF32x16ByBackend := LBackendTable.SqrtF32x16(LF32x16B);
      LF32x16ByScalar := LScalarTable.SqrtF32x16(LF32x16B);
      AssertVecF32x16Equal('SqrtF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 1e-6);

      LF32x16ByBackend := LBackendTable.FmaF32x16(LF32x16A, LF32x16B, LF32x16C);
      LF32x16ByScalar := LScalarTable.FmaF32x16(LF32x16A, LF32x16B, LF32x16C);
      AssertVecF32x16Equal('FmaF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 1e-5);

      LF32x16ByBackend := LBackendTable.ClampF32x16(LF32x16A, LF32x16Min, LF32x16Max);
      LF32x16ByScalar := LScalarTable.ClampF32x16(LF32x16A, LF32x16Min, LF32x16Max);
      AssertVecF32x16Equal('ClampF32x16', NonX86BackendName(LBackend), LF32x16ByScalar, LF32x16ByBackend, 0.0);

      LF64x8ByBackend := LBackendTable.AddF64x8(LF64x8A, LF64x8B);
      LF64x8ByScalar := LScalarTable.AddF64x8(LF64x8A, LF64x8B);
      AssertVecF64x8Equal('AddF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 1e-12);

      LF64x8ByBackend := LBackendTable.SubF64x8(LF64x8A, LF64x8B);
      LF64x8ByScalar := LScalarTable.SubF64x8(LF64x8A, LF64x8B);
      AssertVecF64x8Equal('SubF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 1e-12);

      LF64x8ByBackend := LBackendTable.MulF64x8(LF64x8A, LF64x8B);
      LF64x8ByScalar := LScalarTable.MulF64x8(LF64x8A, LF64x8B);
      AssertVecF64x8Equal('MulF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 1e-11);

      LF64x8ByBackend := LBackendTable.DivF64x8(LF64x8A, LF64x8B);
      LF64x8ByScalar := LScalarTable.DivF64x8(LF64x8A, LF64x8B);
      AssertVecF64x8Equal('DivF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 1e-12);

      LF64x8ByBackend := LBackendTable.MinF64x8(LF64x8A, LF64x8B);
      LF64x8ByScalar := LScalarTable.MinF64x8(LF64x8A, LF64x8B);
      AssertVecF64x8Equal('MinF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 0.0);

      LF64x8ByBackend := LBackendTable.MaxF64x8(LF64x8A, LF64x8B);
      LF64x8ByScalar := LScalarTable.MaxF64x8(LF64x8A, LF64x8B);
      AssertVecF64x8Equal('MaxF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 0.0);

      LF64x8ByBackend := LBackendTable.AbsF64x8(LF64x8A);
      LF64x8ByScalar := LScalarTable.AbsF64x8(LF64x8A);
      AssertVecF64x8Equal('AbsF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 0.0);

      LF64x8ByBackend := LBackendTable.SqrtF64x8(LF64x8B);
      LF64x8ByScalar := LScalarTable.SqrtF64x8(LF64x8B);
      AssertVecF64x8Equal('SqrtF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 1e-12);

      LF64x8ByBackend := LBackendTable.FmaF64x8(LF64x8A, LF64x8B, LF64x8C);
      LF64x8ByScalar := LScalarTable.FmaF64x8(LF64x8A, LF64x8B, LF64x8C);
      AssertVecF64x8Equal('FmaF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 1e-11);

      LF64x8ByBackend := LBackendTable.ClampF64x8(LF64x8A, LF64x8Min, LF64x8Max);
      LF64x8ByScalar := LScalarTable.ClampF64x8(LF64x8A, LF64x8Min, LF64x8Max);
      AssertVecF64x8Equal('ClampF64x8', NonX86BackendName(LBackend), LF64x8ByScalar, LF64x8ByBackend, 0.0);

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_NarrowAndNotParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LI8A, LI8B: TVecI8x16;
  LU16A, LU16B: TVecU16x8;
  LU8A, LU8B: TVecU8x16;
  LI8ByBackend, LI8ByScalar: TVecI8x16;
  LU16ByBackend, LU16ByScalar: TVecU16x8;
  LU8ByBackend, LU8ByScalar: TVecU8x16;
  LIndex: Integer;
  LChecked: Integer;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  LI8A.i[0] := -1;    LI8B.i[0] := 0;
  LI8A.i[1] := 0;     LI8B.i[1] := -1;
  LI8A.i[2] := 127;   LI8B.i[2] := 85;
  LI8A.i[3] := -128;  LI8B.i[3] := 51;
  LI8A.i[4] := 18;    LI8B.i[4] := -52;
  LI8A.i[5] := -85;   LI8B.i[5] := 15;
  LI8A.i[6] := 64;    LI8B.i[6] := -64;
  LI8A.i[7] := -7;    LI8B.i[7] := 7;
  LI8A.i[8] := 1;     LI8B.i[8] := -2;
  LI8A.i[9] := 2;     LI8B.i[9] := 3;
  LI8A.i[10] := 4;    LI8B.i[10] := 5;
  LI8A.i[11] := 6;    LI8B.i[11] := 7;
  LI8A.i[12] := 8;    LI8B.i[12] := 9;
  LI8A.i[13] := 10;   LI8B.i[13] := 11;
  LI8A.i[14] := 12;   LI8B.i[14] := 13;
  LI8A.i[15] := 14;   LI8B.i[15] := 15;

  LU16A.u[0] := $0000; LU16B.u[0] := $FFFF;
  LU16A.u[1] := $FFFF; LU16B.u[1] := $0000;
  LU16A.u[2] := $1234; LU16B.u[2] := $F0F0;
  LU16A.u[3] := $AAAA; LU16B.u[3] := $5555;
  LU16A.u[4] := $00FF; LU16B.u[4] := $0F0F;
  LU16A.u[5] := $FF00; LU16B.u[5] := $3333;
  LU16A.u[6] := $1357; LU16B.u[6] := $2468;
  LU16A.u[7] := $8001; LU16B.u[7] := $7FFE;

  LU8A.u[0] := $00; LU8B.u[0] := $FF;
  LU8A.u[1] := $FF; LU8B.u[1] := $00;
  LU8A.u[2] := $12; LU8B.u[2] := $34;
  LU8A.u[3] := $56; LU8B.u[3] := $78;
  LU8A.u[4] := $9A; LU8B.u[4] := $BC;
  LU8A.u[5] := $DE; LU8B.u[5] := $F0;
  LU8A.u[6] := $0F; LU8B.u[6] := $F0;
  LU8A.u[7] := $F0; LU8B.u[7] := $0F;
  LU8A.u[8] := $55; LU8B.u[8] := $AA;
  LU8A.u[9] := $AA; LU8B.u[9] := $55;
  LU8A.u[10] := $11; LU8B.u[10] := $22;
  LU8A.u[11] := $33; LU8B.u[11] := $44;
  LU8A.u[12] := $66; LU8B.u[12] := $77;
  LU8A.u[13] := $88; LU8B.u[13] := $99;
  LU8A.u[14] := $CC; LU8B.u[14] := $DD;
  LU8A.u[15] := $EE; LU8B.u[15] := $FF;

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('AndNotI8x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndNotI8x16));
      AssertTrue('AndNotU16x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndNotU16x8));
      AssertTrue('AndNotU8x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndNotU8x16));

      LI8ByBackend := LBackendTable.AndNotI8x16(LI8A, LI8B);
      LI8ByScalar := LScalarTable.AndNotI8x16(LI8A, LI8B);
      for LIndex := 0 to 15 do
        AssertEquals('AndNotI8x16 lane ' + IntToStr(LIndex) + ': ' + NonX86BackendName(LBackend),
          LI8ByScalar.i[LIndex], LI8ByBackend.i[LIndex]);

      LU16ByBackend := LBackendTable.AndNotU16x8(LU16A, LU16B);
      LU16ByScalar := LScalarTable.AndNotU16x8(LU16A, LU16B);
      for LIndex := 0 to 7 do
        AssertEquals('AndNotU16x8 lane ' + IntToStr(LIndex) + ': ' + NonX86BackendName(LBackend),
          QWord(LU16ByScalar.u[LIndex]), QWord(LU16ByBackend.u[LIndex]));

      LU8ByBackend := LBackendTable.AndNotU8x16(LU8A, LU8B);
      LU8ByScalar := LScalarTable.AndNotU8x16(LU8A, LU8B);
      for LIndex := 0 to 15 do
        AssertEquals('AndNotU8x16 lane ' + IntToStr(LIndex) + ': ' + NonX86BackendName(LBackend),
          QWord(LU8ByScalar.u[LIndex]), QWord(LU8ByBackend.u[LIndex]));

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_DotParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LF32x8A, LF32x8B: TVecF32x8;
  LF64x2A, LF64x2B: TVecF64x2;
  LF64x4A, LF64x4B: TVecF64x4;
  LDotF32x8ByBackend, LDotF32x8ByScalar: Single;
  LDotF64x2ByBackend, LDotF64x2ByScalar: Double;
  LDotF64x4ByBackend, LDotF64x4ByScalar: Double;
  LIndex: Integer;
  LChecked: Integer;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  for LIndex := 0 to 7 do
  begin
    LF32x8A.f[LIndex] := (LIndex + 1) * 1.125;
    LF32x8B.f[LIndex] := (7 - LIndex) * -0.875;
  end;

  LF64x2A.d[0] := 1.25;
  LF64x2A.d[1] := -3.5;
  LF64x2B.d[0] := 2.0;
  LF64x2B.d[1] := 4.25;

  for LIndex := 0 to 3 do
  begin
    LF64x4A.d[LIndex] := (LIndex + 1) * 2.5;
    LF64x4B.d[LIndex] := (LIndex - 1) * -1.75;
  end;

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('DotF32x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.DotF32x8));
      AssertTrue('DotF64x2 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.DotF64x2));
      AssertTrue('DotF64x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.DotF64x4));

      LDotF32x8ByBackend := LBackendTable.DotF32x8(LF32x8A, LF32x8B);
      LDotF32x8ByScalar := LScalarTable.DotF32x8(LF32x8A, LF32x8B);
      AssertEquals('DotF32x8 parity: ' + NonX86BackendName(LBackend),
        LDotF32x8ByScalar, LDotF32x8ByBackend, 1e-6);

      LDotF64x2ByBackend := LBackendTable.DotF64x2(LF64x2A, LF64x2B);
      LDotF64x2ByScalar := LScalarTable.DotF64x2(LF64x2A, LF64x2B);
      AssertEquals('DotF64x2 parity: ' + NonX86BackendName(LBackend),
        LDotF64x2ByScalar, LDotF64x2ByBackend, 1e-12);

      LDotF64x4ByBackend := LBackendTable.DotF64x4(LF64x4A, LF64x4B);
      LDotF64x4ByScalar := LScalarTable.DotF64x4(LF64x4A, LF64x4B);
      AssertEquals('DotF64x4 parity: ' + NonX86BackendName(LBackend),
        LDotF64x4ByScalar, LDotF64x4ByBackend, 1e-12);

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_I16x32_CoreParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LA, LB: TVecI16x32;
  LVecByBackend, LVecByScalar: TVecI16x32;
  LMaskByBackend, LMaskByScalar: TMask32;
  LShiftCounts: array[0..4] of Integer;
  LShiftCount: Integer;
  LIndex: Integer;
  LChecked: Integer;

  procedure AssertVecI16x32Equal(const aOp: string; const aExpected, aActual: TVecI16x32);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 31 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  for LIndex := 0 to 31 do
  begin
    LA.i[LIndex] := Int16((LIndex * 37) - 400);
    LB.i[LIndex] := Int16(450 - (LIndex * 29));
    if (LIndex mod 5) = 0 then
      LB.i[LIndex] := LA.i[LIndex];
  end;

  LShiftCounts[0] := -1;
  LShiftCounts[1] := 0;
  LShiftCounts[2] := 5;
  LShiftCounts[3] := 15;
  LShiftCounts[4] := 16;

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('AddI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddI16x32));
      AssertTrue('SubI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.SubI16x32));
      AssertTrue('AndI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndI16x32));
      AssertTrue('OrI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.OrI16x32));
      AssertTrue('XorI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.XorI16x32));
      AssertTrue('NotI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.NotI16x32));
      AssertTrue('AndNotI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndNotI16x32));
      AssertTrue('ShiftLeftI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftLeftI16x32));
      AssertTrue('ShiftRightI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightI16x32));
      AssertTrue('ShiftRightArithI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightArithI16x32));
      AssertTrue('CmpEqI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpEqI16x32));
      AssertTrue('CmpLtI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtI16x32));
      AssertTrue('CmpGtI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpGtI16x32));
      AssertTrue('MinI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MinI16x32));
      AssertTrue('MaxI16x32 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MaxI16x32));

      LVecByBackend := LBackendTable.AddI16x32(LA, LB);
      LVecByScalar := LScalarTable.AddI16x32(LA, LB);
      AssertVecI16x32Equal('AddI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.SubI16x32(LA, LB);
      LVecByScalar := LScalarTable.SubI16x32(LA, LB);
      AssertVecI16x32Equal('SubI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.AndI16x32(LA, LB);
      LVecByScalar := LScalarTable.AndI16x32(LA, LB);
      AssertVecI16x32Equal('AndI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.OrI16x32(LA, LB);
      LVecByScalar := LScalarTable.OrI16x32(LA, LB);
      AssertVecI16x32Equal('OrI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.XorI16x32(LA, LB);
      LVecByScalar := LScalarTable.XorI16x32(LA, LB);
      AssertVecI16x32Equal('XorI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.NotI16x32(LA);
      LVecByScalar := LScalarTable.NotI16x32(LA);
      AssertVecI16x32Equal('NotI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.AndNotI16x32(LA, LB);
      LVecByScalar := LScalarTable.AndNotI16x32(LA, LB);
      AssertVecI16x32Equal('AndNotI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      for LIndex := 0 to High(LShiftCounts) do
      begin
        LShiftCount := LShiftCounts[LIndex];

        LVecByBackend := LBackendTable.ShiftLeftI16x32(LA, LShiftCount);
        LVecByScalar := LScalarTable.ShiftLeftI16x32(LA, LShiftCount);
        AssertVecI16x32Equal('ShiftLeftI16x32 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LVecByScalar, LVecByBackend);

        LVecByBackend := LBackendTable.ShiftRightI16x32(LA, LShiftCount);
        LVecByScalar := LScalarTable.ShiftRightI16x32(LA, LShiftCount);
        AssertVecI16x32Equal('ShiftRightI16x32 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LVecByScalar, LVecByBackend);

        LVecByBackend := LBackendTable.ShiftRightArithI16x32(LA, LShiftCount);
        LVecByScalar := LScalarTable.ShiftRightArithI16x32(LA, LShiftCount);
        AssertVecI16x32Equal('ShiftRightArithI16x32 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LVecByScalar, LVecByBackend);
      end;

      LMaskByBackend := LBackendTable.CmpEqI16x32(LA, LB);
      LMaskByScalar := LScalarTable.CmpEqI16x32(LA, LB);
      AssertEquals('CmpEqI16x32 parity: ' + NonX86BackendName(LBackend),
        QWord(LMaskByScalar), QWord(LMaskByBackend));

      LMaskByBackend := LBackendTable.CmpLtI16x32(LA, LB);
      LMaskByScalar := LScalarTable.CmpLtI16x32(LA, LB);
      AssertEquals('CmpLtI16x32 parity: ' + NonX86BackendName(LBackend),
        QWord(LMaskByScalar), QWord(LMaskByBackend));

      LMaskByBackend := LBackendTable.CmpGtI16x32(LA, LB);
      LMaskByScalar := LScalarTable.CmpGtI16x32(LA, LB);
      AssertEquals('CmpGtI16x32 parity: ' + NonX86BackendName(LBackend),
        QWord(LMaskByScalar), QWord(LMaskByBackend));

      LVecByBackend := LBackendTable.MinI16x32(LA, LB);
      LVecByScalar := LScalarTable.MinI16x32(LA, LB);
      AssertVecI16x32Equal('MinI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.MaxI16x32(LA, LB);
      LVecByScalar := LScalarTable.MaxI16x32(LA, LB);
      AssertVecI16x32Equal('MaxI16x32 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_I8x64_CoreParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LA, LB: TVecI8x64;
  LVecByBackend, LVecByScalar: TVecI8x64;
  LMaskByBackend, LMaskByScalar: TMask64;
  LIndex: Integer;
  LChecked: Integer;

  procedure AssertVecI8x64Equal(const aOp: string; const aExpected, aActual: TVecI8x64);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 63 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  for LIndex := 0 to 63 do
  begin
    LA.i[LIndex] := Int8((LIndex mod 17) - 8);
    LB.i[LIndex] := Int8(7 - (LIndex mod 19));
    if (LIndex mod 7) = 0 then
      LB.i[LIndex] := LA.i[LIndex];
  end;

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('AddI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddI8x64));
      AssertTrue('SubI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.SubI8x64));
      AssertTrue('AndI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndI8x64));
      AssertTrue('OrI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.OrI8x64));
      AssertTrue('XorI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.XorI8x64));
      AssertTrue('NotI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.NotI8x64));
      AssertTrue('AndNotI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndNotI8x64));
      AssertTrue('CmpEqI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpEqI8x64));
      AssertTrue('CmpLtI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtI8x64));
      AssertTrue('CmpGtI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpGtI8x64));
      AssertTrue('MinI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MinI8x64));
      AssertTrue('MaxI8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MaxI8x64));

      LVecByBackend := LBackendTable.AddI8x64(LA, LB);
      LVecByScalar := LScalarTable.AddI8x64(LA, LB);
      AssertVecI8x64Equal('AddI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.SubI8x64(LA, LB);
      LVecByScalar := LScalarTable.SubI8x64(LA, LB);
      AssertVecI8x64Equal('SubI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.AndI8x64(LA, LB);
      LVecByScalar := LScalarTable.AndI8x64(LA, LB);
      AssertVecI8x64Equal('AndI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.OrI8x64(LA, LB);
      LVecByScalar := LScalarTable.OrI8x64(LA, LB);
      AssertVecI8x64Equal('OrI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.XorI8x64(LA, LB);
      LVecByScalar := LScalarTable.XorI8x64(LA, LB);
      AssertVecI8x64Equal('XorI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.NotI8x64(LA);
      LVecByScalar := LScalarTable.NotI8x64(LA);
      AssertVecI8x64Equal('NotI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.AndNotI8x64(LA, LB);
      LVecByScalar := LScalarTable.AndNotI8x64(LA, LB);
      AssertVecI8x64Equal('AndNotI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LMaskByBackend := LBackendTable.CmpEqI8x64(LA, LB);
      LMaskByScalar := LScalarTable.CmpEqI8x64(LA, LB);
      AssertEquals('CmpEqI8x64 parity: ' + NonX86BackendName(LBackend),
        QWord(LMaskByScalar), QWord(LMaskByBackend));

      LMaskByBackend := LBackendTable.CmpLtI8x64(LA, LB);
      LMaskByScalar := LScalarTable.CmpLtI8x64(LA, LB);
      AssertEquals('CmpLtI8x64 parity: ' + NonX86BackendName(LBackend),
        QWord(LMaskByScalar), QWord(LMaskByBackend));

      LMaskByBackend := LBackendTable.CmpGtI8x64(LA, LB);
      LMaskByScalar := LScalarTable.CmpGtI8x64(LA, LB);
      AssertEquals('CmpGtI8x64 parity: ' + NonX86BackendName(LBackend),
        QWord(LMaskByScalar), QWord(LMaskByBackend));

      LVecByBackend := LBackendTable.MinI8x64(LA, LB);
      LVecByScalar := LScalarTable.MinI8x64(LA, LB);
      AssertVecI8x64Equal('MinI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.MaxI8x64(LA, LB);
      LVecByScalar := LScalarTable.MaxI8x64(LA, LB);
      AssertVecI8x64Equal('MaxI8x64 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_U32x16_U64x8_CoreParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LU32A, LU32B: TVecU32x16;
  LU64A, LU64B: TVecU64x8;
  LU8A, LU8B: TVecU8x64;
  LU32ByBackend, LU32ByScalar: TVecU32x16;
  LU64ByBackend, LU64ByScalar: TVecU64x8;
  LU8ByBackend, LU8ByScalar: TVecU8x64;
  LMask16ByBackend, LMask16ByScalar: TMask16;
  LMask8ByBackend, LMask8ByScalar: TMask8;
  LMask64ByBackend, LMask64ByScalar: TMask64;
  LU32ShiftCounts: array[0..4] of Integer;
  LU64ShiftCounts: array[0..4] of Integer;
  LShiftCount: Integer;
  LIndex: Integer;
  LChecked: Integer;

  procedure AssertVecU32x16Equal(const aOp: string; const aExpected, aActual: TVecU32x16);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 15 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), QWord(aExpected.u[LLane]), QWord(aActual.u[LLane]));
  end;

  procedure AssertVecU64x8Equal(const aOp: string; const aExpected, aActual: TVecU64x8);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), QWord(aExpected.u[LLane]), QWord(aActual.u[LLane]));
  end;

  procedure AssertVecU8x64Equal(const aOp: string; const aExpected, aActual: TVecU8x64);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 63 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), QWord(aExpected.u[LLane]), QWord(aActual.u[LLane]));
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  for LIndex := 0 to 15 do
  begin
    LU32A.u[LIndex] := DWord((LIndex + 1) * 1234567);
    LU32B.u[LIndex] := DWord((17 - LIndex) * 76543);
    if (LIndex mod 4) = 0 then
      LU32B.u[LIndex] := LU32A.u[LIndex];
  end;

  for LIndex := 0 to 7 do
  begin
    LU64A.u[LIndex] := QWord((LIndex + 1) * 1000003) shl (LIndex mod 13);
    LU64B.u[LIndex] := QWord((9 - LIndex) * 700001) shl ((LIndex + 3) mod 11);
    if (LIndex mod 3) = 0 then
      LU64B.u[LIndex] := LU64A.u[LIndex];
  end;

  for LIndex := 0 to 63 do
  begin
    LU8A.u[LIndex] := Byte((LIndex * 19) and $FF);
    LU8B.u[LIndex] := Byte((255 - (LIndex * 7)) and $FF);
    if (LIndex mod 6) = 0 then
      LU8B.u[LIndex] := LU8A.u[LIndex];
  end;

  LU32ShiftCounts[0] := 0;
  LU32ShiftCounts[1] := 3;
  LU32ShiftCounts[2] := 15;
  LU32ShiftCounts[3] := 31;
  LU32ShiftCounts[4] := 32;

  LU64ShiftCounts[0] := 0;
  LU64ShiftCounts[1] := 7;
  LU64ShiftCounts[2] := 19;
  LU64ShiftCounts[3] := 63;
  LU64ShiftCounts[4] := 64;

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('AddU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddU32x16));
      AssertTrue('SubU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.SubU32x16));
      AssertTrue('MulU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MulU32x16));
      AssertTrue('AndU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndU32x16));
      AssertTrue('OrU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.OrU32x16));
      AssertTrue('XorU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.XorU32x16));
      AssertTrue('NotU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.NotU32x16));
      AssertTrue('AndNotU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndNotU32x16));
      AssertTrue('ShiftLeftU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftLeftU32x16));
      AssertTrue('ShiftRightU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightU32x16));
      AssertTrue('CmpEqU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpEqU32x16));
      AssertTrue('CmpLtU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtU32x16));
      AssertTrue('CmpGtU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpGtU32x16));
      AssertTrue('CmpLeU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLeU32x16));
      AssertTrue('CmpGeU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpGeU32x16));
      AssertTrue('CmpNeU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpNeU32x16));
      AssertTrue('MinU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MinU32x16));
      AssertTrue('MaxU32x16 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MaxU32x16));
      AssertTrue('AddU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddU64x8));
      AssertTrue('SubU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.SubU64x8));
      AssertTrue('AndU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndU64x8));
      AssertTrue('OrU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.OrU64x8));
      AssertTrue('XorU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.XorU64x8));
      AssertTrue('NotU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.NotU64x8));
      AssertTrue('ShiftLeftU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftLeftU64x8));
      AssertTrue('ShiftRightU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightU64x8));
      AssertTrue('CmpEqU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpEqU64x8));
      AssertTrue('CmpLtU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtU64x8));
      AssertTrue('CmpGtU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpGtU64x8));
      AssertTrue('CmpLeU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLeU64x8));
      AssertTrue('CmpGeU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpGeU64x8));
      AssertTrue('CmpNeU64x8 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpNeU64x8));
      AssertTrue('AddU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AddU8x64));
      AssertTrue('SubU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.SubU8x64));
      AssertTrue('AndU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndU8x64));
      AssertTrue('OrU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.OrU8x64));
      AssertTrue('XorU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.XorU8x64));
      AssertTrue('NotU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.NotU8x64));
      AssertTrue('CmpEqU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpEqU8x64));
      AssertTrue('CmpLtU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpLtU8x64));
      AssertTrue('CmpGtU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.CmpGtU8x64));
      AssertTrue('MinU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MinU8x64));
      AssertTrue('MaxU8x64 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.MaxU8x64));

      LU32ByBackend := LBackendTable.AddU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.AddU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('AddU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.SubU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.SubU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('SubU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.MulU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.MulU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('MulU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.AndU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.AndU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('AndU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.OrU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.OrU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('OrU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.XorU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.XorU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('XorU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.NotU32x16(LU32A);
      LU32ByScalar := LScalarTable.NotU32x16(LU32A);
      AssertVecU32x16Equal('NotU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.AndNotU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.AndNotU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('AndNotU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      for LIndex := 0 to High(LU32ShiftCounts) do
      begin
        LShiftCount := LU32ShiftCounts[LIndex];
        LU32ByBackend := LBackendTable.ShiftLeftU32x16(LU32A, LShiftCount);
        LU32ByScalar := LScalarTable.ShiftLeftU32x16(LU32A, LShiftCount);
        AssertVecU32x16Equal('ShiftLeftU32x16 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

        LU32ByBackend := LBackendTable.ShiftRightU32x16(LU32A, LShiftCount);
        LU32ByScalar := LScalarTable.ShiftRightU32x16(LU32A, LShiftCount);
        AssertVecU32x16Equal('ShiftRightU32x16 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);
      end;

      LMask16ByBackend := LBackendTable.CmpEqU32x16(LU32A, LU32B);
      LMask16ByScalar := LScalarTable.CmpEqU32x16(LU32A, LU32B);
      AssertEquals('CmpEqU32x16 parity: ' + NonX86BackendName(LBackend), QWord(LMask16ByScalar), QWord(LMask16ByBackend));

      LMask16ByBackend := LBackendTable.CmpLtU32x16(LU32A, LU32B);
      LMask16ByScalar := LScalarTable.CmpLtU32x16(LU32A, LU32B);
      AssertEquals('CmpLtU32x16 parity: ' + NonX86BackendName(LBackend), QWord(LMask16ByScalar), QWord(LMask16ByBackend));

      LMask16ByBackend := LBackendTable.CmpGtU32x16(LU32A, LU32B);
      LMask16ByScalar := LScalarTable.CmpGtU32x16(LU32A, LU32B);
      AssertEquals('CmpGtU32x16 parity: ' + NonX86BackendName(LBackend), QWord(LMask16ByScalar), QWord(LMask16ByBackend));

      LMask16ByBackend := LBackendTable.CmpLeU32x16(LU32A, LU32B);
      LMask16ByScalar := LScalarTable.CmpLeU32x16(LU32A, LU32B);
      AssertEquals('CmpLeU32x16 parity: ' + NonX86BackendName(LBackend), QWord(LMask16ByScalar), QWord(LMask16ByBackend));

      LMask16ByBackend := LBackendTable.CmpGeU32x16(LU32A, LU32B);
      LMask16ByScalar := LScalarTable.CmpGeU32x16(LU32A, LU32B);
      AssertEquals('CmpGeU32x16 parity: ' + NonX86BackendName(LBackend), QWord(LMask16ByScalar), QWord(LMask16ByBackend));

      LMask16ByBackend := LBackendTable.CmpNeU32x16(LU32A, LU32B);
      LMask16ByScalar := LScalarTable.CmpNeU32x16(LU32A, LU32B);
      AssertEquals('CmpNeU32x16 parity: ' + NonX86BackendName(LBackend), QWord(LMask16ByScalar), QWord(LMask16ByBackend));

      LU32ByBackend := LBackendTable.MinU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.MinU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('MinU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU32ByBackend := LBackendTable.MaxU32x16(LU32A, LU32B);
      LU32ByScalar := LScalarTable.MaxU32x16(LU32A, LU32B);
      AssertVecU32x16Equal('MaxU32x16 parity: ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

      LU64ByBackend := LBackendTable.AddU64x8(LU64A, LU64B);
      LU64ByScalar := LScalarTable.AddU64x8(LU64A, LU64B);
      AssertVecU64x8Equal('AddU64x8 parity: ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

      LU64ByBackend := LBackendTable.SubU64x8(LU64A, LU64B);
      LU64ByScalar := LScalarTable.SubU64x8(LU64A, LU64B);
      AssertVecU64x8Equal('SubU64x8 parity: ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

      LU64ByBackend := LBackendTable.AndU64x8(LU64A, LU64B);
      LU64ByScalar := LScalarTable.AndU64x8(LU64A, LU64B);
      AssertVecU64x8Equal('AndU64x8 parity: ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

      LU64ByBackend := LBackendTable.OrU64x8(LU64A, LU64B);
      LU64ByScalar := LScalarTable.OrU64x8(LU64A, LU64B);
      AssertVecU64x8Equal('OrU64x8 parity: ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

      LU64ByBackend := LBackendTable.XorU64x8(LU64A, LU64B);
      LU64ByScalar := LScalarTable.XorU64x8(LU64A, LU64B);
      AssertVecU64x8Equal('XorU64x8 parity: ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

      LU64ByBackend := LBackendTable.NotU64x8(LU64A);
      LU64ByScalar := LScalarTable.NotU64x8(LU64A);
      AssertVecU64x8Equal('NotU64x8 parity: ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

      for LIndex := 0 to High(LU64ShiftCounts) do
      begin
        LShiftCount := LU64ShiftCounts[LIndex];
        LU64ByBackend := LBackendTable.ShiftLeftU64x8(LU64A, LShiftCount);
        LU64ByScalar := LScalarTable.ShiftLeftU64x8(LU64A, LShiftCount);
        AssertVecU64x8Equal('ShiftLeftU64x8 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

        LU64ByBackend := LBackendTable.ShiftRightU64x8(LU64A, LShiftCount);
        LU64ByScalar := LScalarTable.ShiftRightU64x8(LU64A, LShiftCount);
        AssertVecU64x8Equal('ShiftRightU64x8 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);
      end;

      LMask8ByBackend := LBackendTable.CmpEqU64x8(LU64A, LU64B);
      LMask8ByScalar := LScalarTable.CmpEqU64x8(LU64A, LU64B);
      AssertEquals('CmpEqU64x8 parity: ' + NonX86BackendName(LBackend), QWord(LMask8ByScalar), QWord(LMask8ByBackend));

      LMask8ByBackend := LBackendTable.CmpLtU64x8(LU64A, LU64B);
      LMask8ByScalar := LScalarTable.CmpLtU64x8(LU64A, LU64B);
      AssertEquals('CmpLtU64x8 parity: ' + NonX86BackendName(LBackend), QWord(LMask8ByScalar), QWord(LMask8ByBackend));

      LMask8ByBackend := LBackendTable.CmpGtU64x8(LU64A, LU64B);
      LMask8ByScalar := LScalarTable.CmpGtU64x8(LU64A, LU64B);
      AssertEquals('CmpGtU64x8 parity: ' + NonX86BackendName(LBackend), QWord(LMask8ByScalar), QWord(LMask8ByBackend));

      LMask8ByBackend := LBackendTable.CmpLeU64x8(LU64A, LU64B);
      LMask8ByScalar := LScalarTable.CmpLeU64x8(LU64A, LU64B);
      AssertEquals('CmpLeU64x8 parity: ' + NonX86BackendName(LBackend), QWord(LMask8ByScalar), QWord(LMask8ByBackend));

      LMask8ByBackend := LBackendTable.CmpGeU64x8(LU64A, LU64B);
      LMask8ByScalar := LScalarTable.CmpGeU64x8(LU64A, LU64B);
      AssertEquals('CmpGeU64x8 parity: ' + NonX86BackendName(LBackend), QWord(LMask8ByScalar), QWord(LMask8ByBackend));

      LMask8ByBackend := LBackendTable.CmpNeU64x8(LU64A, LU64B);
      LMask8ByScalar := LScalarTable.CmpNeU64x8(LU64A, LU64B);
      AssertEquals('CmpNeU64x8 parity: ' + NonX86BackendName(LBackend), QWord(LMask8ByScalar), QWord(LMask8ByBackend));

      LU8ByBackend := LBackendTable.AddU8x64(LU8A, LU8B);
      LU8ByScalar := LScalarTable.AddU8x64(LU8A, LU8B);
      AssertVecU8x64Equal('AddU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      LU8ByBackend := LBackendTable.SubU8x64(LU8A, LU8B);
      LU8ByScalar := LScalarTable.SubU8x64(LU8A, LU8B);
      AssertVecU8x64Equal('SubU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      LU8ByBackend := LBackendTable.AndU8x64(LU8A, LU8B);
      LU8ByScalar := LScalarTable.AndU8x64(LU8A, LU8B);
      AssertVecU8x64Equal('AndU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      LU8ByBackend := LBackendTable.OrU8x64(LU8A, LU8B);
      LU8ByScalar := LScalarTable.OrU8x64(LU8A, LU8B);
      AssertVecU8x64Equal('OrU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      LU8ByBackend := LBackendTable.XorU8x64(LU8A, LU8B);
      LU8ByScalar := LScalarTable.XorU8x64(LU8A, LU8B);
      AssertVecU8x64Equal('XorU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      LU8ByBackend := LBackendTable.NotU8x64(LU8A);
      LU8ByScalar := LScalarTable.NotU8x64(LU8A);
      AssertVecU8x64Equal('NotU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      LMask64ByBackend := LBackendTable.CmpEqU8x64(LU8A, LU8B);
      LMask64ByScalar := LScalarTable.CmpEqU8x64(LU8A, LU8B);
      AssertEquals('CmpEqU8x64 parity: ' + NonX86BackendName(LBackend), QWord(LMask64ByScalar), QWord(LMask64ByBackend));

      LMask64ByBackend := LBackendTable.CmpLtU8x64(LU8A, LU8B);
      LMask64ByScalar := LScalarTable.CmpLtU8x64(LU8A, LU8B);
      AssertEquals('CmpLtU8x64 parity: ' + NonX86BackendName(LBackend), QWord(LMask64ByScalar), QWord(LMask64ByBackend));

      LMask64ByBackend := LBackendTable.CmpGtU8x64(LU8A, LU8B);
      LMask64ByScalar := LScalarTable.CmpGtU8x64(LU8A, LU8B);
      AssertEquals('CmpGtU8x64 parity: ' + NonX86BackendName(LBackend), QWord(LMask64ByScalar), QWord(LMask64ByBackend));

      LU8ByBackend := LBackendTable.MinU8x64(LU8A, LU8B);
      LU8ByScalar := LScalarTable.MinU8x64(LU8A, LU8B);
      AssertVecU8x64Equal('MinU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      LU8ByBackend := LBackendTable.MaxU8x64(LU8A, LU8B);
      LU8ByScalar := LScalarTable.MaxU8x64(LU8A, LU8B);
      AssertVecU8x64Equal('MaxU8x64 parity: ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_WideInteger_FuzzSeed_Parity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LI16A, LI16B: TVecI16x32;
  LI8A, LI8B: TVecI8x64;
  LU32A, LU32B: TVecU32x16;
  LU64A, LU64B: TVecU64x8;
  LU8A, LU8B: TVecU8x64;
  LI16ByBackend, LI16ByScalar: TVecI16x32;
  LI8ByBackend, LI8ByScalar: TVecI8x64;
  LU32ByBackend, LU32ByScalar: TVecU32x16;
  LU64ByBackend, LU64ByScalar: TVecU64x8;
  LU8ByBackend, LU8ByScalar: TVecU8x64;
  LMask32ByBackend, LMask32ByScalar: TMask32;
  LMask64ByBackend, LMask64ByScalar: TMask64;
  LMask16ByBackend, LMask16ByScalar: TMask16;
  LMask8ByBackend, LMask8ByScalar: TMask8;
  LI16ShiftChoices: array[0..4] of Integer;
  LU32ShiftChoices: array[0..4] of Integer;
  LU64ShiftChoices: array[0..4] of Integer;
  LIter: Integer;
  LIndex: Integer;
  LChecked: Integer;
  LOriginalSeed: Integer;
  LShiftCount: Integer;

  procedure AssertVecI16x32Equal(const aOp: string; const aExpected, aActual: TVecI16x32);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 31 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecI8x64Equal(const aOp: string; const aExpected, aActual: TVecI8x64);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 63 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecU32x16Equal(const aOp: string; const aExpected, aActual: TVecU32x16);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 15 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), QWord(aExpected.u[LLane]), QWord(aActual.u[LLane]));
  end;

  procedure AssertVecU64x8Equal(const aOp: string; const aExpected, aActual: TVecU64x8);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 7 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), QWord(aExpected.u[LLane]), QWord(aActual.u[LLane]));
  end;

  procedure AssertVecU8x64Equal(const aOp: string; const aExpected, aActual: TVecU8x64);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 63 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), QWord(aExpected.u[LLane]), QWord(aActual.u[LLane]));
  end;

  function NextU32: DWord;
  begin
    Result := DWord(Random($10000)) or (DWord(Random($10000)) shl 16);
  end;

  function NextU64: QWord;
  begin
    Result := QWord(NextU32) or (QWord(NextU32) shl 32);
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  LI16ShiftChoices[0] := -1;
  LI16ShiftChoices[1] := 0;
  LI16ShiftChoices[2] := 3;
  LI16ShiftChoices[3] := 15;
  LI16ShiftChoices[4] := 16;

  LU32ShiftChoices[0] := 0;
  LU32ShiftChoices[1] := 5;
  LU32ShiftChoices[2] := 13;
  LU32ShiftChoices[3] := 31;
  LU32ShiftChoices[4] := 32;

  LU64ShiftChoices[0] := 0;
  LU64ShiftChoices[1] := 7;
  LU64ShiftChoices[2] := 21;
  LU64ShiftChoices[3] := 63;
  LU64ShiftChoices[4] := 64;

  LOriginalSeed := RandSeed;
  RandSeed := 20260311;
  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      for LIter := 1 to 24 do
      begin
        for LIndex := 0 to 31 do
        begin
          LI16A.i[LIndex] := Int16(Random(65536) - 32768);
          LI16B.i[LIndex] := Int16(Random(65536) - 32768);
        end;

        for LIndex := 0 to 63 do
        begin
          LI8A.i[LIndex] := Int8(Random(256) - 128);
          LI8B.i[LIndex] := Int8(Random(256) - 128);
          LU8A.u[LIndex] := Byte(Random(256));
          LU8B.u[LIndex] := Byte(Random(256));
        end;

        for LIndex := 0 to 15 do
        begin
          LU32A.u[LIndex] := NextU32;
          LU32B.u[LIndex] := NextU32;
        end;

        for LIndex := 0 to 7 do
        begin
          LU64A.u[LIndex] := NextU64;
          LU64B.u[LIndex] := NextU64;
        end;

        LI16ByBackend := LBackendTable.AddI16x32(LI16A, LI16B);
        LI16ByScalar := LScalarTable.AddI16x32(LI16A, LI16B);
        AssertVecI16x32Equal('Fuzz AddI16x32 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend), LI16ByScalar, LI16ByBackend);

        LShiftCount := LI16ShiftChoices[Random(Length(LI16ShiftChoices))];
        LI16ByBackend := LBackendTable.ShiftRightArithI16x32(LI16A, LShiftCount);
        LI16ByScalar := LScalarTable.ShiftRightArithI16x32(LI16A, LShiftCount);
        AssertVecI16x32Equal('Fuzz ShiftRightArithI16x32 iter ' + IntToStr(LIter) + ' c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LI16ByScalar, LI16ByBackend);

        LMask32ByBackend := LBackendTable.CmpLtI16x32(LI16A, LI16B);
        LMask32ByScalar := LScalarTable.CmpLtI16x32(LI16A, LI16B);
        AssertEquals('Fuzz CmpLtI16x32 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend),
          QWord(LMask32ByScalar), QWord(LMask32ByBackend));

        LI8ByBackend := LBackendTable.AndNotI8x64(LI8A, LI8B);
        LI8ByScalar := LScalarTable.AndNotI8x64(LI8A, LI8B);
        AssertVecI8x64Equal('Fuzz AndNotI8x64 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend), LI8ByScalar, LI8ByBackend);

        LMask64ByBackend := LBackendTable.CmpEqI8x64(LI8A, LI8B);
        LMask64ByScalar := LScalarTable.CmpEqI8x64(LI8A, LI8B);
        AssertEquals('Fuzz CmpEqI8x64 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend),
          QWord(LMask64ByScalar), QWord(LMask64ByBackend));

        LU32ByBackend := LBackendTable.MulU32x16(LU32A, LU32B);
        LU32ByScalar := LScalarTable.MulU32x16(LU32A, LU32B);
        AssertVecU32x16Equal('Fuzz MulU32x16 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend), LU32ByScalar, LU32ByBackend);

        LShiftCount := LU32ShiftChoices[Random(Length(LU32ShiftChoices))];
        LU32ByBackend := LBackendTable.ShiftRightU32x16(LU32A, LShiftCount);
        LU32ByScalar := LScalarTable.ShiftRightU32x16(LU32A, LShiftCount);
        AssertVecU32x16Equal('Fuzz ShiftRightU32x16 iter ' + IntToStr(LIter) + ' c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LU32ByScalar, LU32ByBackend);

        LMask16ByBackend := LBackendTable.CmpLeU32x16(LU32A, LU32B);
        LMask16ByScalar := LScalarTable.CmpLeU32x16(LU32A, LU32B);
        AssertEquals('Fuzz CmpLeU32x16 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend),
          QWord(LMask16ByScalar), QWord(LMask16ByBackend));

        LU64ByBackend := LBackendTable.AddU64x8(LU64A, LU64B);
        LU64ByScalar := LScalarTable.AddU64x8(LU64A, LU64B);
        AssertVecU64x8Equal('Fuzz AddU64x8 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend), LU64ByScalar, LU64ByBackend);

        LShiftCount := LU64ShiftChoices[Random(Length(LU64ShiftChoices))];
        LU64ByBackend := LBackendTable.ShiftLeftU64x8(LU64A, LShiftCount);
        LU64ByScalar := LScalarTable.ShiftLeftU64x8(LU64A, LShiftCount);
        AssertVecU64x8Equal('Fuzz ShiftLeftU64x8 iter ' + IntToStr(LIter) + ' c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LU64ByScalar, LU64ByBackend);

        LMask8ByBackend := LBackendTable.CmpNeU64x8(LU64A, LU64B);
        LMask8ByScalar := LScalarTable.CmpNeU64x8(LU64A, LU64B);
        AssertEquals('Fuzz CmpNeU64x8 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend),
          QWord(LMask8ByScalar), QWord(LMask8ByBackend));

        LU8ByBackend := LBackendTable.XorU8x64(LU8A, LU8B);
        LU8ByScalar := LScalarTable.XorU8x64(LU8A, LU8B);
        AssertVecU8x64Equal('Fuzz XorU8x64 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend), LU8ByScalar, LU8ByBackend);

        LMask64ByBackend := LBackendTable.CmpGtU8x64(LU8A, LU8B);
        LMask64ByScalar := LScalarTable.CmpGtU8x64(LU8A, LU8B);
        AssertEquals('Fuzz CmpGtU8x64 iter ' + IntToStr(LIter) + ': ' + NonX86BackendName(LBackend),
          QWord(LMask64ByScalar), QWord(LMask64ByBackend));
      end;

      Inc(LChecked);
    end;
  finally
    RandSeed := LOriginalSeed;
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

procedure TTestCase_NonX86BackendParity.Test_I32x4_BitwiseShiftParity_IfAvailable;
var
  LBackends: array[0..1] of TSimdBackend;
  LBackend: TSimdBackend;
  LBackendTable: TSimdDispatchTable;
  LScalarTable: TSimdDispatchTable;
  LA, LB: TVecI32x4;
  LVecByBackend, LVecByScalar: TVecI32x4;
  LI64A: TVecI64x2;
  LI64ByBackend, LI64ByScalar: TVecI64x2;
  LI64x4A: TVecI64x4;
  LI64x4ByBackend, LI64x4ByScalar: TVecI64x4;
  LU64x4A: TVecU64x4;
  LU64x4ByBackend, LU64x4ByScalar: TVecU64x4;
  LShiftCounts: array[0..4] of Integer;
  LShiftCounts64: array[0..4] of Integer;
  LShiftCount: Integer;
  LIndex: Integer;
  LChecked: Integer;

  procedure AssertVecI32x4Equal(const aOp: string; const aExpected, aActual: TVecI32x4);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 3 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecI64x4Equal(const aOp: string; const aExpected, aActual: TVecI64x4);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 3 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), aExpected.i[LLane], aActual.i[LLane]);
  end;

  procedure AssertVecU64x4Equal(const aOp: string; const aExpected, aActual: TVecU64x4);
  var
    LLane: Integer;
  begin
    for LLane := 0 to 3 do
      AssertEquals(aOp + ' lane ' + IntToStr(LLane), QWord(aExpected.u[LLane]), QWord(aActual.u[LLane]));
  end;
begin
  AssertTrue('Scalar dispatch table should be registered',
    TryGetRegisteredBackendDispatchTable(sbScalar, LScalarTable));

  LBackends[0] := sbNEON;
  LBackends[1] := sbRISCVV;
  LChecked := 0;

  LA.i[0] := $7FFFFFFF;
  LA.i[1] := $40000001;
  LA.i[2] := -1;
  LA.i[3] := -16;
  LB.i[0] := $0F0F0F0F;
  LB.i[1] := $F0F0F0F0;
  LB.i[2] := $AAAAAAAA;
  LB.i[3] := $55555555;

  LShiftCounts[0] := -1;
  LShiftCounts[1] := 0;
  LShiftCounts[2] := 7;
  LShiftCounts[3] := 31;
  LShiftCounts[4] := 32;
  LShiftCounts64[0] := -1;
  LShiftCounts64[1] := 0;
  LShiftCounts64[2] := 13;
  LShiftCounts64[3] := 63;
  LShiftCounts64[4] := 64;

  LI64A.i[0] := $7FFFFFFFFFFFFFFF;
  LI64A.i[1] := -1;
  LI64x4A.i[0] := $7FFFFFFFFFFFFFFF;
  LI64x4A.i[1] := -1;
  LI64x4A.i[2] := Int64($4000000000000001);
  LI64x4A.i[3] := -16;
  LU64x4A.u[0] := QWord($FFFFFFFFFFFFFFFF);
  LU64x4A.u[1] := QWord($8000000000000000);
  LU64x4A.u[2] := 1;
  LU64x4A.u[3] := QWord($0123456789ABCDEF);

  try
    for LBackend in LBackends do
    begin
      if not TryGetRegisteredBackendDispatchTable(LBackend, LBackendTable) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      AssertTrue('AndI32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.AndI32x4));
      AssertTrue('OrI32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.OrI32x4));
      AssertTrue('XorI32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.XorI32x4));
      AssertTrue('ShiftLeftI32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftLeftI32x4));
      AssertTrue('ShiftRightI32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightI32x4));
      AssertTrue('ShiftRightArithI32x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightArithI32x4));
      AssertTrue('ShiftLeftI64x2 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftLeftI64x2));
      AssertTrue('ShiftRightI64x2 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightI64x2));
      AssertTrue('ShiftRightArithI64x2 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightArithI64x2));
      AssertTrue('ShiftLeftI64x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftLeftI64x4));
      AssertTrue('ShiftRightI64x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightI64x4));
      AssertTrue('ShiftRightArithI64x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightArithI64x4));
      AssertTrue('ShiftLeftU64x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftLeftU64x4));
      AssertTrue('ShiftRightU64x4 missing: ' + NonX86BackendName(LBackend), Assigned(LBackendTable.ShiftRightU64x4));

      LVecByBackend := LBackendTable.AndI32x4(LA, LB);
      LVecByScalar := LScalarTable.AndI32x4(LA, LB);
      AssertVecI32x4Equal('AndI32x4 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.OrI32x4(LA, LB);
      LVecByScalar := LScalarTable.OrI32x4(LA, LB);
      AssertVecI32x4Equal('OrI32x4 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      LVecByBackend := LBackendTable.XorI32x4(LA, LB);
      LVecByScalar := LScalarTable.XorI32x4(LA, LB);
      AssertVecI32x4Equal('XorI32x4 parity: ' + NonX86BackendName(LBackend), LVecByScalar, LVecByBackend);

      for LIndex := 0 to High(LShiftCounts) do
      begin
        LShiftCount := LShiftCounts[LIndex];

        LVecByBackend := LBackendTable.ShiftLeftI32x4(LA, LShiftCount);
        LVecByScalar := LScalarTable.ShiftLeftI32x4(LA, LShiftCount);
        AssertVecI32x4Equal('ShiftLeftI32x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LVecByScalar, LVecByBackend);

        LVecByBackend := LBackendTable.ShiftRightI32x4(LA, LShiftCount);
        LVecByScalar := LScalarTable.ShiftRightI32x4(LA, LShiftCount);
        AssertVecI32x4Equal('ShiftRightI32x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LVecByScalar, LVecByBackend);

        LVecByBackend := LBackendTable.ShiftRightArithI32x4(LA, LShiftCount);
        LVecByScalar := LScalarTable.ShiftRightArithI32x4(LA, LShiftCount);
        AssertVecI32x4Equal('ShiftRightArithI32x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LVecByScalar, LVecByBackend);
      end;

      for LIndex := 0 to High(LShiftCounts64) do
      begin
        LShiftCount := LShiftCounts64[LIndex];

        LI64ByBackend := LBackendTable.ShiftLeftI64x2(LI64A, LShiftCount);
        LI64ByScalar := LScalarTable.ShiftLeftI64x2(LI64A, LShiftCount);
        AssertEquals('ShiftLeftI64x2 parity c=' + IntToStr(LShiftCount) + ' lane 0: ' + NonX86BackendName(LBackend),
          LI64ByScalar.i[0], LI64ByBackend.i[0]);
        AssertEquals('ShiftLeftI64x2 parity c=' + IntToStr(LShiftCount) + ' lane 1: ' + NonX86BackendName(LBackend),
          LI64ByScalar.i[1], LI64ByBackend.i[1]);

        LI64ByBackend := LBackendTable.ShiftRightI64x2(LI64A, LShiftCount);
        LI64ByScalar := LScalarTable.ShiftRightI64x2(LI64A, LShiftCount);
        AssertEquals('ShiftRightI64x2 parity c=' + IntToStr(LShiftCount) + ' lane 0: ' + NonX86BackendName(LBackend),
          LI64ByScalar.i[0], LI64ByBackend.i[0]);
        AssertEquals('ShiftRightI64x2 parity c=' + IntToStr(LShiftCount) + ' lane 1: ' + NonX86BackendName(LBackend),
          LI64ByScalar.i[1], LI64ByBackend.i[1]);

        LI64ByBackend := LBackendTable.ShiftRightArithI64x2(LI64A, LShiftCount);
        LI64ByScalar := LScalarTable.ShiftRightArithI64x2(LI64A, LShiftCount);
        AssertEquals('ShiftRightArithI64x2 parity c=' + IntToStr(LShiftCount) + ' lane 0: ' + NonX86BackendName(LBackend),
          LI64ByScalar.i[0], LI64ByBackend.i[0]);
        AssertEquals('ShiftRightArithI64x2 parity c=' + IntToStr(LShiftCount) + ' lane 1: ' + NonX86BackendName(LBackend),
          LI64ByScalar.i[1], LI64ByBackend.i[1]);

        LI64x4ByBackend := LBackendTable.ShiftLeftI64x4(LI64x4A, LShiftCount);
        LI64x4ByScalar := LScalarTable.ShiftLeftI64x4(LI64x4A, LShiftCount);
        AssertVecI64x4Equal('ShiftLeftI64x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LI64x4ByScalar, LI64x4ByBackend);

        LI64x4ByBackend := LBackendTable.ShiftRightI64x4(LI64x4A, LShiftCount);
        LI64x4ByScalar := LScalarTable.ShiftRightI64x4(LI64x4A, LShiftCount);
        AssertVecI64x4Equal('ShiftRightI64x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LI64x4ByScalar, LI64x4ByBackend);

        LI64x4ByBackend := LBackendTable.ShiftRightArithI64x4(LI64x4A, LShiftCount);
        LI64x4ByScalar := ScalarShiftRightArithI64x4(LI64x4A, LShiftCount);
        AssertVecI64x4Equal('ShiftRightArithI64x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LI64x4ByScalar, LI64x4ByBackend);

        LU64x4ByBackend := LBackendTable.ShiftLeftU64x4(LU64x4A, LShiftCount);
        LU64x4ByScalar := LScalarTable.ShiftLeftU64x4(LU64x4A, LShiftCount);
        AssertVecU64x4Equal('ShiftLeftU64x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LU64x4ByScalar, LU64x4ByBackend);

        LU64x4ByBackend := LBackendTable.ShiftRightU64x4(LU64x4A, LShiftCount);
        LU64x4ByScalar := LScalarTable.ShiftRightU64x4(LU64x4A, LShiftCount);
        AssertVecU64x4Equal('ShiftRightU64x4 parity c=' + IntToStr(LShiftCount) + ': ' + NonX86BackendName(LBackend),
          LU64x4ByScalar, LU64x4ByBackend);
      end;

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  if LChecked = 0 then
    AssertTrue('No non-x86 backend registered/active on this host (allowed)', True);
end;

initialization
  RegisterTest(TTestCase_DispatchAPI);
  RegisterTest(TTestCase_NonX86BackendParity);

end.

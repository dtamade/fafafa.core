unit fafafa.core.simd.direct.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.direct;

type
  TTestCase_DirectDispatch = class(TTestCase)
  published
    procedure Test_DirectDispatchTable_Assigned;
    procedure Test_DirectDispatchTable_MatchesGetDispatchTable;
    procedure Test_DirectDispatchTable_Rebind_AfterForceBackend;
    procedure Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend;
  end;

implementation

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_Assigned;
begin
  AssertTrue('Direct dispatch table should be assigned', GetDirectDispatchTable <> nil);
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MatchesGetDispatchTable;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;

  AssertTrue('GetDispatchTable should be assigned', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned', directDt <> nil);

  // Spot-check a few representative entries across categories.
  AssertEquals('AddF32x4 pointer should match', PtrUInt(Pointer(dt^.AddF32x4)), PtrUInt(Pointer(directDt^.AddF32x4)));
  AssertEquals('SplatF32x4 pointer should match', PtrUInt(Pointer(dt^.SplatF32x4)), PtrUInt(Pointer(directDt^.SplatF32x4)));
  AssertEquals('MemEqual pointer should match', PtrUInt(Pointer(dt^.MemEqual)), PtrUInt(Pointer(directDt^.MemEqual)));
  AssertEquals('MemCopy pointer should match', PtrUInt(Pointer(dt^.MemCopy)), PtrUInt(Pointer(directDt^.MemCopy)));
  AssertEquals('SumBytes pointer should match', PtrUInt(Pointer(dt^.SumBytes)), PtrUInt(Pointer(directDt^.SumBytes)));
  AssertEquals('Mask4All pointer should match', PtrUInt(Pointer(dt^.Mask4All)), PtrUInt(Pointer(directDt^.Mask4All)));
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_Rebind_AfterForceBackend;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
begin
  // Force backend (for testing) and ensure direct table can be re-bound.
  ForceBackend(sbScalar);
  RebindDirectDispatch;

  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;

  AssertTrue('GetDispatchTable should be assigned after ForceBackend', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned after RebindDirectDispatch', directDt <> nil);

  AssertEquals('Backend enum should match', Ord(dt^.Backend), Ord(directDt^.Backend));
  AssertEquals('AddF32x4 pointer should match after rebind', PtrUInt(Pointer(dt^.AddF32x4)), PtrUInt(Pointer(directDt^.AddF32x4)));

  // Restore automatic backend selection for other tests.
  ResetBackendSelection;
  RebindDirectDispatch;
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
  originalBackend: TSimdBackend;
begin
  // Baseline
  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertTrue('Baseline GetDispatchTable should be assigned', dt <> nil);
  AssertTrue('Baseline GetDirectDispatchTable should be assigned', directDt <> nil);

  originalBackend := dt^.Backend;

  // Switch backend via dispatch directly (bypassing fafafa.core.simd facade)
  SetActiveBackend(sbScalar);

  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertTrue('GetDispatchTable should be assigned after SetActiveBackend', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned after SetActiveBackend', directDt <> nil);

  AssertEquals('Dispatch backend should be Scalar after SetActiveBackend', Ord(sbScalar), Ord(dt^.Backend));
  AssertEquals('Direct dispatch backend should track dispatch after SetActiveBackend', Ord(dt^.Backend), Ord(directDt^.Backend));
  AssertEquals('AddF32x4 pointer should match after dispatch SetActiveBackend', PtrUInt(Pointer(dt^.AddF32x4)), PtrUInt(Pointer(directDt^.AddF32x4)));

  // Restore automatic selection (also via dispatch)
  ResetToAutomaticBackend;

  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertTrue('GetDispatchTable should be assigned after ResetToAutomaticBackend', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned after ResetToAutomaticBackend', directDt <> nil);

  // If original backend wasn't scalar, we expect it can change back. Either way, direct must match dispatch.
  AssertEquals('Direct dispatch backend should track dispatch after ResetToAutomaticBackend', Ord(dt^.Backend), Ord(directDt^.Backend));

  // Keep the test stable: if automatic selection returns to original backend, fine; otherwise also fine.
  // But we at least assert the backend is a valid enum.
  AssertTrue('Backend enum should be within range', (Ord(dt^.Backend) >= Ord(Low(TSimdBackend))) and (Ord(dt^.Backend) <= Ord(High(TSimdBackend))));

  // Prevent unused var warning in some configs
  if originalBackend = sbScalar then
    AssertTrue(True);
end;

initialization
  RegisterTest(TTestCase_DirectDispatch);

end.

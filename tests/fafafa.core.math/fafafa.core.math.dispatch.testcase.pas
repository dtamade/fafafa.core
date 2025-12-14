unit fafafa.core.math.dispatch.testcase;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math.dispatch;

type
  TTestMathDispatch = class(TTestCase)
  published
    // === Backend Query ===
    procedure Test_GetActiveBackend_ReturnsScalarByDefault;
    procedure Test_GetBackendInfo_ScalarHasCorrectName;
    procedure Test_IsBackendAvailable_ScalarAlwaysTrue;
    procedure Test_IsBackendAvailable_SIMDCurrentlyFalse;

    // === Backend Selection ===
    procedure Test_SetActiveBackend_ChangesBackend;
    procedure Test_SetActiveBackend_UnavailableBackend_NoChange;
    procedure Test_ResetToAutomaticBackend_RestoresDefault;

    // === Dispatch Table ===
    procedure Test_GetDispatchTable_NotNil;
    procedure Test_GetDispatchTable_BackendMatchesActive;
  end;

implementation

// === Backend Query ===

procedure TTestMathDispatch.Test_GetActiveBackend_ReturnsScalarByDefault;
begin
  ResetToAutomaticBackend;
  AssertEquals('Default backend should be Scalar',
               Ord(mbScalar), Ord(GetActiveBackend));
end;

procedure TTestMathDispatch.Test_GetBackendInfo_ScalarHasCorrectName;
var
  LInfo: TMathBackendInfo;
begin
  LInfo := GetBackendInfo(mbScalar);
  AssertEquals('Scalar', LInfo.Name);
  AssertTrue(LInfo.Available);
end;

procedure TTestMathDispatch.Test_IsBackendAvailable_ScalarAlwaysTrue;
begin
  AssertTrue('Scalar backend should always be available',
             IsBackendAvailable(mbScalar));
end;

procedure TTestMathDispatch.Test_IsBackendAvailable_SIMDCurrentlyFalse;
begin
  // SIMD backend is not yet implemented
  AssertFalse('SIMD backend should not be available yet',
              IsBackendAvailable(mbSIMD));
end;

// === Backend Selection ===

procedure TTestMathDispatch.Test_SetActiveBackend_ChangesBackend;
begin
  ResetToAutomaticBackend;
  // Scalar is available, so this should work
  SetActiveBackend(mbScalar);
  AssertEquals(Ord(mbScalar), Ord(GetActiveBackend));
end;

procedure TTestMathDispatch.Test_SetActiveBackend_UnavailableBackend_NoChange;
begin
  ResetToAutomaticBackend;
  // Try to set unavailable SIMD backend
  SetActiveBackend(mbSIMD);
  // Should remain Scalar since SIMD is unavailable
  AssertEquals('Should remain Scalar when SIMD unavailable',
               Ord(mbScalar), Ord(GetActiveBackend));
end;

procedure TTestMathDispatch.Test_ResetToAutomaticBackend_RestoresDefault;
begin
  SetActiveBackend(mbScalar);
  ResetToAutomaticBackend;
  AssertEquals(Ord(mbScalar), Ord(GetActiveBackend));
end;

// === Dispatch Table ===

procedure TTestMathDispatch.Test_GetDispatchTable_NotNil;
begin
  AssertNotNull('Dispatch table should not be nil', GetDispatchTable);
end;

procedure TTestMathDispatch.Test_GetDispatchTable_BackendMatchesActive;
var
  LTable: PMathDispatchTable;
begin
  ResetToAutomaticBackend;
  LTable := GetDispatchTable;
  AssertEquals(Ord(GetActiveBackend), Ord(LTable^.Backend));
end;

initialization
  RegisterTest(TTestMathDispatch);

end.

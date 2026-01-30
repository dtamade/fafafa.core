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
  // Test that a platform-incompatible SIMD backend is not available:
  // - On x86_64: NEON (ARM) is unavailable
  // - On ARM64: SSE2/AVX2 (x86) are unavailable
  {$IFDEF CPUX86_64}
  AssertFalse('NEON backend should not be available on x86_64',
              IsBackendAvailable(mbNEON));
  {$ENDIF}
  {$IFDEF CPUAARCH64}
  AssertFalse('SSE2 backend should not be available on ARM64',
              IsBackendAvailable(mbSSE2));
  {$ENDIF}
  {$IF NOT DEFINED(CPUX86_64) AND NOT DEFINED(CPUAARCH64)}
  // On other platforms, scalar is the only available backend
  AssertTrue('At least scalar should be available', IsBackendAvailable(mbScalar));
  {$ENDIF}
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
var
  LOriginalBackend: TMathBackend;
begin
  ResetToAutomaticBackend;
  LOriginalBackend := GetActiveBackend;

  // Try to set a platform-incompatible backend:
  // - On x86_64: try to set NEON (ARM-only)
  // - On ARM64: try to set SSE2 (x86-only)
  {$IFDEF CPUX86_64}
  SetActiveBackend(mbNEON);
  AssertEquals('Should remain unchanged when NEON unavailable on x86_64',
               Ord(LOriginalBackend), Ord(GetActiveBackend));
  {$ENDIF}
  {$IFDEF CPUAARCH64}
  SetActiveBackend(mbSSE2);
  AssertEquals('Should remain unchanged when SSE2 unavailable on ARM64',
               Ord(LOriginalBackend), Ord(GetActiveBackend));
  {$ENDIF}
  {$IF NOT DEFINED(CPUX86_64) AND NOT DEFINED(CPUAARCH64)}
  // On other platforms, just verify scalar is active
  AssertEquals('Scalar should be active on unsupported platforms',
               Ord(mbScalar), Ord(GetActiveBackend));
  {$ENDIF}
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

procedure RegisterSSSE3Backend;
var
  dispatchTable: TSimdDispatchTable;
  LUseVectorAsm: Boolean;
  LAdvertiseAvailability: Boolean;
begin
  // Only register if SSSE3 is available
  if not HasSSSE3 then
    Exit;

  LUseVectorAsm := IsVectorAsmEnabled;
  LAdvertiseAvailability := LUseVectorAsm;
  {$IFDEF WINDOWS}
  // Win64 lane: keep the clone/override shape registered for table-audit tests,
  // but do not publish SSSE3 as dispatchable until representative semantics are validated.
  LAdvertiseAvailability := False;
  {$ENDIF}

  // ✅ 使用 CloneDispatchTable 从 SSE3 继承实现
  dispatchTable := Default(TSimdDispatchTable);
  if not CloneDispatchTable(sbSSE3, dispatchTable) then
    if not CloneDispatchTable(sbSSE2, dispatchTable) then
      FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbSSSE3;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSSE3;
    Name := 'SSSE3';
    Description := 'x86-64 SSSE3 SIMD implementation (PSHUFB, PABS, PALIGNR)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scLoadStore];
    Include(Capabilities, scMaskedOps);
    Include(Capabilities, scIntegerOps);
    if LUseVectorAsm then
      Include(Capabilities, scShuffle);
    Available := LAdvertiseAvailability;
    Priority := GetSimdBackendPriorityValue(sbSSSE3);
  end;

  // SSSE3 improvements
  if LUseVectorAsm then
  begin
    // ✅ PABS instructions for integer absolute value
    // Note: These operations are not yet in the dispatch table
    // When AbsI8x16/AbsI16x8/AbsI32x4 are added to TSimdDispatchTable:
    // dispatchTable.AbsI8x16 := @SSSE3AbsI8x16;
    // dispatchTable.AbsI16x8 := @SSSE3AbsI16x8;
    // dispatchTable.AbsI32x4 := @SSSE3AbsI32x4;

    // ✅ Improved Min/Max for I8x16
    dispatchTable.MinI8x16 := @SSSE3MinI8x16;
    dispatchTable.MaxI8x16 := @SSSE3MaxI8x16;
  end;

  // Register the backend
  RegisterBackend(sbSSSE3, dispatchTable);
end;

initialization
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.ssse3:init:before-register');
  Flush(StdErr);
  {$ENDIF}
  RegisterSSSE3Backend;
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.ssse3:init:after-register');
  Flush(StdErr);
  {$ENDIF}
  RegisterBackendRebuilder(sbSSSE3, @RegisterSSSE3Backend);
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.ssse3:init:after-rebuilder');
  Flush(StdErr);
  {$ENDIF}

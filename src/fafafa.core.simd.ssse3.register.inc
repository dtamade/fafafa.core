procedure RegisterSSSE3Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSSE3 is available
  if not HasSSSE3 then
    Exit;

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
                     scShuffle, scIntegerOps, scLoadStore];
    Available := True;
    Priority := GetSimdBackendPriorityValue(sbSSSE3);
  end;

  // SSSE3 improvements
  if IsVectorAsmEnabled then
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
  RegisterSSSE3Backend;

procedure RegisterSSE42Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSE4.2 is available
  if not HasSSE42 then
    Exit;

  dispatchTable := Default(TSimdDispatchTable);

  // Start with base scalar implementations
  FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbSSE42;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSE42;
    Name := 'SSE4.2';
    Description := 'x86-64 SSE4.2 SIMD implementation (CRC32, string ops)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scShuffle, scIntegerOps, scLoadStore];
    Available := True;
    Priority := GetSimdBackendPriorityValue(sbSSE42);
  end;

  // SSE4.2 provides string operations and CRC32
  if IsVectorAsmEnabled then
  begin
    // Override 64-bit comparison with PCMPGTQ
    dispatchTable.CmpGtI64x2 := @SSE42CmpGtI64x2;

    // CRC32 functions are exposed directly, not through dispatch table
    // (They're not vector operations, but specialized instructions)
  end;

  // Register the backend
  RegisterBackend(sbSSE42, dispatchTable);
end;

initialization
  RegisterSSE42Backend;
  RegisterBackendRebuilder(sbSSE42, @RegisterSSE42Backend);

// === Dot Product Functions (needed by RegisterNEONBackend) ===

// ✅ Iteration 6.4: Dot Product fallback implementations
// Keep these as scalar wrappers to avoid toolchain-dependent AArch64 asm syntax drift.
function NEONDotF32x8(const a, b: TVecF32x8): Single;
begin
  Result := ScalarDotF32x8(a, b);
end;

function NEONDotF64x2(const a, b: TVecF64x2): Double;
begin
  Result := ScalarDotF64x2(a, b);
end;

function NEONDotF64x4(const a, b: TVecF64x4): Double;
begin
  Result := ScalarDotF64x4(a, b);
end;


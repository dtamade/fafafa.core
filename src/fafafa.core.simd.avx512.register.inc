procedure RegisterAVX512Backend;
var
  dispatchTable: TSimdDispatchTable;
  isAvailable: Boolean;
begin
  // Always register so the dispatch table can be inspected (e.g. on non-AVX-512 machines).
  // Runtime dispatch/forcing still prevents executing AVX-512 on unsupported CPUs.
  isAvailable := HasAVX512 and X86HasAVX512BackendRequiredFeatures(GetX86CPUInfo);

  // ✅ AVX-512 inherits all 128-bit and 256-bit operations from AVX2
  // This provides full coverage for F32x4, F64x2, I32x4, I64x2, F32x8, F64x4, etc.
  // AVX-512 only needs to override 512-bit operations and AVX-512-specific optimizations.
  dispatchTable := Default(TSimdDispatchTable);
  if not CloneDispatchTable(sbAVX2, dispatchTable) then
    FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbAVX512;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbAVX512;
    Name := 'AVX-512';
    Description := 'x86-64 AVX-512 SIMD implementation (512-bit)';
    // sc512BitOps is now advertised: wide 512-bit integer families
    // (I16x32/I8x64/U32x16/U64x8/U8x64) are mapped to AVX-512 slots.
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scLoadStore, scMaskedOps, sc512BitOps];
    Available := isAvailable;
    Priority := GetSimdBackendPriorityValue(sbAVX512);
  end;

  // Override facade functions with AVX-512 accelerated versions
  dispatchTable.MemEqual := @MemEqual_AVX512;
  dispatchTable.MemFindByte := @MemFindByte_AVX512;
  dispatchTable.SumBytes := @SumBytes_AVX512;
  dispatchTable.CountByte := @CountByte_AVX512;
  dispatchTable.MinMaxBytes := @MinMaxBytes_AVX512;
  dispatchTable.BitsetPopCount := @BitsetPopCount_AVX512;
  dispatchTable.MemCopy := @MemCopy_AVX512;
  dispatchTable.MemSet := @MemSet_AVX512;
  dispatchTable.ToLowerAscii := @ToLowerAscii_AVX512;
  dispatchTable.ToUpperAscii := @ToUpperAscii_AVX512;
  dispatchTable.AsciiIEqual := @AsciiIEqual_AVX512;

  // Functions using AVX2 fallback (complex algorithms)
  dispatchTable.Utf8Validate := @Utf8Validate_AVX512;
  dispatchTable.MemReverse := @MemReverse_AVX512;
  dispatchTable.MemDiffRange := @MemDiffRange_AVX512;
  dispatchTable.BytesIndexOf := @BytesIndexOf_AVX512;

  // === 512-bit Vector Type Operations ===

  // F32x16 (512-bit float)
  dispatchTable.AddF32x16 := @AVX512AddF32x16;
  dispatchTable.SubF32x16 := @AVX512SubF32x16;
  dispatchTable.MulF32x16 := @AVX512MulF32x16;
  dispatchTable.DivF32x16 := @AVX512DivF32x16;

  dispatchTable.LoadF32x16 := @AVX512LoadF32x16;
  dispatchTable.StoreF32x16 := @AVX512StoreF32x16;
  dispatchTable.SplatF32x16 := @AVX512SplatF32x16;
  dispatchTable.ZeroF32x16 := @AVX512ZeroF32x16;
  dispatchTable.SelectF32x16 := @AVX512SelectF32x16;

  // F64x8 (512-bit double)
  dispatchTable.AddF64x8 := @AVX512AddF64x8;
  dispatchTable.SubF64x8 := @AVX512SubF64x8;
  dispatchTable.MulF64x8 := @AVX512MulF64x8;
  dispatchTable.DivF64x8 := @AVX512DivF64x8;

  dispatchTable.LoadF64x8 := @AVX512LoadF64x8;
  dispatchTable.StoreF64x8 := @AVX512StoreF64x8;
  dispatchTable.SplatF64x8 := @AVX512SplatF64x8;
  dispatchTable.ZeroF64x8 := @AVX512ZeroF64x8;
  dispatchTable.SelectF64x8 := @AVX512SelectF64x8;

  // I32x16 (512-bit integer) - Arithmetic
  dispatchTable.AddI32x16 := @AVX512AddI32x16;
  dispatchTable.SubI32x16 := @AVX512SubI32x16;
  dispatchTable.MulI32x16 := @AVX512MulI32x16;

  // I32x16 (512-bit integer) - Bitwise
  dispatchTable.AndI32x16 := @AVX512AndI32x16;
  dispatchTable.OrI32x16 := @AVX512OrI32x16;
  dispatchTable.XorI32x16 := @AVX512XorI32x16;
  dispatchTable.NotI32x16 := @AVX512NotI32x16;
  dispatchTable.AndNotI32x16 := @AVX512AndNotI32x16;

  // I32x16 (512-bit integer) - Shift
  dispatchTable.ShiftLeftI32x16 := @AVX512ShiftLeftI32x16;
  dispatchTable.ShiftRightI32x16 := @AVX512ShiftRightI32x16;
  dispatchTable.ShiftRightArithI32x16 := @AVX512ShiftRightArithI32x16;

  // I32x16 (512-bit integer) - Comparison
  dispatchTable.CmpEqI32x16 := @AVX512CmpEqI32x16;
  dispatchTable.CmpLtI32x16 := @AVX512CmpLtI32x16;
  dispatchTable.CmpGtI32x16 := @AVX512CmpGtI32x16;
  dispatchTable.CmpLeI32x16 := @AVX512CmpLeI32x16;  // ✅ P0-1: 补充缺失
  dispatchTable.CmpGeI32x16 := @AVX512CmpGeI32x16;  // ✅ P0-1: 补充缺失
  dispatchTable.CmpNeI32x16 := @AVX512CmpNeI32x16;  // ✅ P0-1: 补充缺失

  // I32x16 (512-bit integer) - Min/Max
  dispatchTable.MinI32x16 := @AVX512MinI32x16;
  dispatchTable.MaxI32x16 := @AVX512MaxI32x16;

  // === I64x8 (512-bit 64-bit integer) ===
  dispatchTable.AddI64x8 := @AVX512AddI64x8;
  dispatchTable.SubI64x8 := @AVX512SubI64x8;
  dispatchTable.AndI64x8 := @AVX512AndI64x8;
  dispatchTable.OrI64x8 := @AVX512OrI64x8;
  dispatchTable.XorI64x8 := @AVX512XorI64x8;
  dispatchTable.NotI64x8 := @AVX512NotI64x8;
  dispatchTable.CmpEqI64x8 := @AVX512CmpEqI64x8;
  dispatchTable.CmpLtI64x8 := @AVX512CmpLtI64x8;
  dispatchTable.CmpGtI64x8 := @AVX512CmpGtI64x8;
  dispatchTable.CmpLeI64x8 := @AVX512CmpLeI64x8;
  dispatchTable.CmpGeI64x8 := @AVX512CmpGeI64x8;
  dispatchTable.CmpNeI64x8 := @AVX512CmpNeI64x8;

  // === U32x16 (512-bit unsigned integer) ===
  dispatchTable.AddU32x16 := @AVX512AddU32x16;
  dispatchTable.SubU32x16 := @AVX512SubU32x16;
  dispatchTable.MulU32x16 := @AVX512MulU32x16;
  dispatchTable.AndU32x16 := @AVX512AndU32x16;
  dispatchTable.OrU32x16 := @AVX512OrU32x16;
  dispatchTable.XorU32x16 := @AVX512XorU32x16;
  dispatchTable.NotU32x16 := @AVX512NotU32x16;
  dispatchTable.AndNotU32x16 := @AVX512AndNotU32x16;
  dispatchTable.ShiftLeftU32x16 := @AVX512ShiftLeftU32x16;
  dispatchTable.ShiftRightU32x16 := @AVX512ShiftRightU32x16;
  dispatchTable.CmpEqU32x16 := @AVX512CmpEqU32x16;
  dispatchTable.CmpLtU32x16 := @AVX512CmpLtU32x16;
  dispatchTable.CmpGtU32x16 := @AVX512CmpGtU32x16;
  dispatchTable.CmpLeU32x16 := @AVX512CmpLeU32x16;
  dispatchTable.CmpGeU32x16 := @AVX512CmpGeU32x16;
  dispatchTable.CmpNeU32x16 := @AVX512CmpNeU32x16;
  dispatchTable.MinU32x16 := @AVX512MinU32x16;
  dispatchTable.MaxU32x16 := @AVX512MaxU32x16;

  // === U64x8 (512-bit unsigned integer) ===
  dispatchTable.AddU64x8 := @AVX512AddU64x8;
  dispatchTable.SubU64x8 := @AVX512SubU64x8;
  dispatchTable.AndU64x8 := @AVX512AndU64x8;
  dispatchTable.OrU64x8 := @AVX512OrU64x8;
  dispatchTable.XorU64x8 := @AVX512XorU64x8;
  dispatchTable.NotU64x8 := @AVX512NotU64x8;
  dispatchTable.ShiftLeftU64x8 := @AVX512ShiftLeftU64x8;
  dispatchTable.ShiftRightU64x8 := @AVX512ShiftRightU64x8;
  dispatchTable.CmpEqU64x8 := @AVX512CmpEqU64x8;
  dispatchTable.CmpLtU64x8 := @AVX512CmpLtU64x8;
  dispatchTable.CmpGtU64x8 := @AVX512CmpGtU64x8;
  dispatchTable.CmpLeU64x8 := @AVX512CmpLeU64x8;
  dispatchTable.CmpGeU64x8 := @AVX512CmpGeU64x8;
  dispatchTable.CmpNeU64x8 := @AVX512CmpNeU64x8;

  // === I16x32 (512-bit signed integer) ===
  dispatchTable.AddI16x32 := @AVX512AddI16x32;
  dispatchTable.SubI16x32 := @AVX512SubI16x32;
  dispatchTable.AndI16x32 := @AVX512AndI16x32;
  dispatchTable.OrI16x32 := @AVX512OrI16x32;
  dispatchTable.XorI16x32 := @AVX512XorI16x32;
  dispatchTable.NotI16x32 := @AVX512NotI16x32;
  dispatchTable.AndNotI16x32 := @AVX512AndNotI16x32;
  dispatchTable.ShiftLeftI16x32 := @AVX512ShiftLeftI16x32;
  dispatchTable.ShiftRightI16x32 := @AVX512ShiftRightI16x32;
  dispatchTable.ShiftRightArithI16x32 := @AVX512ShiftRightArithI16x32;
  dispatchTable.CmpEqI16x32 := @AVX512CmpEqI16x32;
  dispatchTable.CmpLtI16x32 := @AVX512CmpLtI16x32;
  dispatchTable.CmpGtI16x32 := @AVX512CmpGtI16x32;
  dispatchTable.MinI16x32 := @AVX512MinI16x32;
  dispatchTable.MaxI16x32 := @AVX512MaxI16x32;

  // === I8x64 (512-bit signed integer) ===
  dispatchTable.AddI8x64 := @AVX512AddI8x64;
  dispatchTable.SubI8x64 := @AVX512SubI8x64;
  dispatchTable.AndI8x64 := @AVX512AndI8x64;
  dispatchTable.OrI8x64 := @AVX512OrI8x64;
  dispatchTable.XorI8x64 := @AVX512XorI8x64;
  dispatchTable.NotI8x64 := @AVX512NotI8x64;
  dispatchTable.AndNotI8x64 := @AVX512AndNotI8x64;
  dispatchTable.CmpEqI8x64 := @AVX512CmpEqI8x64;
  dispatchTable.CmpLtI8x64 := @AVX512CmpLtI8x64;
  dispatchTable.CmpGtI8x64 := @AVX512CmpGtI8x64;
  dispatchTable.MinI8x64 := @AVX512MinI8x64;
  dispatchTable.MaxI8x64 := @AVX512MaxI8x64;

  // === U8x64 (512-bit unsigned integer) ===
  dispatchTable.AddU8x64 := @AVX512AddU8x64;
  dispatchTable.SubU8x64 := @AVX512SubU8x64;
  dispatchTable.AndU8x64 := @AVX512AndU8x64;
  dispatchTable.OrU8x64 := @AVX512OrU8x64;
  dispatchTable.XorU8x64 := @AVX512XorU8x64;
  dispatchTable.NotU8x64 := @AVX512NotU8x64;
  dispatchTable.CmpEqU8x64 := @AVX512CmpEqU8x64;
  dispatchTable.CmpLtU8x64 := @AVX512CmpLtU8x64;
  dispatchTable.CmpGtU8x64 := @AVX512CmpGtU8x64;
  dispatchTable.MinU8x64 := @AVX512MinU8x64;
  dispatchTable.MaxU8x64 := @AVX512MaxU8x64;

  // === F32x16 Comparison Operations ===
  dispatchTable.CmpEqF32x16 := @AVX512CmpEqF32x16;
  dispatchTable.CmpLtF32x16 := @AVX512CmpLtF32x16;
  dispatchTable.CmpLeF32x16 := @AVX512CmpLeF32x16;
  dispatchTable.CmpGtF32x16 := @AVX512CmpGtF32x16;
  dispatchTable.CmpGeF32x16 := @AVX512CmpGeF32x16;
  dispatchTable.CmpNeF32x16 := @AVX512CmpNeF32x16;

  // === F64x8 Comparison Operations ===
  dispatchTable.CmpEqF64x8 := @AVX512CmpEqF64x8;
  dispatchTable.CmpLtF64x8 := @AVX512CmpLtF64x8;
  dispatchTable.CmpLeF64x8 := @AVX512CmpLeF64x8;
  dispatchTable.CmpGtF64x8 := @AVX512CmpGtF64x8;
  dispatchTable.CmpGeF64x8 := @AVX512CmpGeF64x8;
  dispatchTable.CmpNeF64x8 := @AVX512CmpNeF64x8;

  // === F32x16 Math Functions ===
  dispatchTable.AbsF32x16 := @AVX512AbsF32x16;
  dispatchTable.SqrtF32x16 := @AVX512SqrtF32x16;
  dispatchTable.MinF32x16 := @AVX512MinF32x16;
  dispatchTable.MaxF32x16 := @AVX512MaxF32x16;
  dispatchTable.ClampF32x16 := @AVX512ClampF32x16;
  dispatchTable.FmaF32x16 := @AVX512FmaF32x16;
  dispatchTable.FloorF32x16 := @AVX512FloorF32x16;
  dispatchTable.CeilF32x16 := @AVX512CeilF32x16;
  dispatchTable.RoundF32x16 := @AVX512RoundF32x16;
  dispatchTable.TruncF32x16 := @AVX512TruncF32x16;

  // === F64x8 Math Functions ===
  dispatchTable.AbsF64x8 := @AVX512AbsF64x8;
  dispatchTable.SqrtF64x8 := @AVX512SqrtF64x8;
  dispatchTable.MinF64x8 := @AVX512MinF64x8;
  dispatchTable.MaxF64x8 := @AVX512MaxF64x8;
  dispatchTable.ClampF64x8 := @AVX512ClampF64x8;
  dispatchTable.FmaF64x8 := @AVX512FmaF64x8;
  dispatchTable.FloorF64x8 := @AVX512FloorF64x8;
  dispatchTable.CeilF64x8 := @AVX512CeilF64x8;
  dispatchTable.RoundF64x8 := @AVX512RoundF64x8;
  dispatchTable.TruncF64x8 := @AVX512TruncF64x8;

  // === F32x16 Reduction Operations ===
  dispatchTable.ReduceAddF32x16 := @AVX512ReduceAddF32x16;
  dispatchTable.ReduceMinF32x16 := @AVX512ReduceMinF32x16;
  dispatchTable.ReduceMaxF32x16 := @AVX512ReduceMaxF32x16;
  dispatchTable.ReduceMulF32x16 := @AVX512ReduceMulF32x16;

  // === F64x8 Reduction Operations ===
  dispatchTable.ReduceAddF64x8 := @AVX512ReduceAddF64x8;
  dispatchTable.ReduceMinF64x8 := @AVX512ReduceMinF64x8;
  dispatchTable.ReduceMaxF64x8 := @AVX512ReduceMaxF64x8;
  dispatchTable.ReduceMulF64x8 := @AVX512ReduceMulF64x8;

  // === Mask16 Operations (AVX-512 Optimized) ===
  dispatchTable.Mask16All := @AVX512Mask16All;
  dispatchTable.Mask16Any := @AVX512Mask16Any;
  dispatchTable.Mask16None := @AVX512Mask16None;
  dispatchTable.Mask16PopCount := @AVX512Mask16PopCount;
  dispatchTable.Mask16FirstSet := @AVX512Mask16FirstSet;

  // ✅ P2: Saturating Arithmetic (EVEX-encoded, always enabled)
  dispatchTable.I8x16SatAdd := @AVX512I8x16SatAdd;
  dispatchTable.I8x16SatSub := @AVX512I8x16SatSub;
  dispatchTable.I16x8SatAdd := @AVX512I16x8SatAdd;
  dispatchTable.I16x8SatSub := @AVX512I16x8SatSub;
  dispatchTable.U8x16SatAdd := @AVX512U8x16SatAdd;
  dispatchTable.U8x16SatSub := @AVX512U8x16SatSub;
  dispatchTable.U16x8SatAdd := @AVX512U16x8SatAdd;
  dispatchTable.U16x8SatSub := @AVX512U16x8SatSub;

  // Register the backend
  RegisterBackend(sbAVX512, dispatchTable);
end;

initialization
  RegisterAVX512Backend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbAVX512, @RegisterAVX512Backend);

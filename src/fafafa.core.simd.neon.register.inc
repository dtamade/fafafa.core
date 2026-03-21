procedure RegisterNEONBackend;
var
  table: TSimdDispatchTable;
  LCapabilities: TSimdCapabilities;
  LAsmCapable: Boolean;
  LUseVectorAsm: Boolean;
begin
  // Fill with base scalar implementations (provides fallback for unimplemented operations)
  FillBaseDispatchTable(table);

  LAsmCapable := False;
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  LAsmCapable := True;
  {$ENDIF}
  LUseVectorAsm := False;
  if LAsmCapable then
    LUseVectorAsm := IsVectorAsmEnabled;

  // Backend info
  table.Backend := sbNEON;
  table.BackendInfo.Backend := sbNEON;
  table.BackendInfo.Available := (not LAsmCapable) or LUseVectorAsm;
  table.BackendInfo.Name := 'NEON';
  table.BackendInfo.Description := 'ARM NEON 128-bit SIMD';
  LCapabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                    scReduction, scLoadStore];
  if LUseVectorAsm then
    Include(LCapabilities, scIntegerOps);
  if LUseVectorAsm then
    Include(LCapabilities, scFMA);
  if LUseVectorAsm then
    Include(LCapabilities, scShuffle);
  table.BackendInfo.Capabilities := LCapabilities;
  table.BackendInfo.Priority := GetSimdBackendPriorityValue(sbNEON);

  if LAsmCapable and (not LUseVectorAsm) then
  begin
    RegisterBackend(sbNEON, table);
    Exit;
  end;

  // Override with NEON-accelerated operations
  // Arithmetic operations - F32x4
  table.AddF32x4 := @NEONAddF32x4;
  table.SubF32x4 := @NEONSubF32x4;
  table.MulF32x4 := @NEONMulF32x4;
  table.DivF32x4 := @NEONDivF32x4;

  // Arithmetic operations - F32x8 (emulated via 2x F32x4)
  table.AddF32x8 := @NEONAddF32x8;
  table.SubF32x8 := @NEONSubF32x8;
  table.MulF32x8 := @NEONMulF32x8;
  table.DivF32x8 := @NEONDivF32x8;

  // Arithmetic operations - F64x2
  table.AddF64x2 := @NEONAddF64x2;
  table.SubF64x2 := @NEONSubF64x2;
  table.MulF64x2 := @NEONMulF64x2;
  table.DivF64x2 := @NEONDivF64x2;

  // Arithmetic operations - I32x4
  table.AddI32x4 := @NEONAddI32x4;
  table.SubI32x4 := @NEONSubI32x4;
  table.MulI32x4 := @NEONMulI32x4;

  // Comparison operations
  table.CmpEqF32x4 := @NEONCmpEqF32x4;
  table.CmpLtF32x4 := @NEONCmpLtF32x4;
  table.CmpLeF32x4 := @NEONCmpLeF32x4;
  table.CmpGtF32x4 := @NEONCmpGtF32x4;
  table.CmpGeF32x4 := @NEONCmpGeF32x4;
  table.CmpNeF32x4 := @NEONCmpNeF32x4;

  // Math functions
  table.AbsF32x4 := @NEONAbsF32x4;
  table.SqrtF32x4 := @NEONSqrtF32x4;
  table.MinF32x4 := @NEONMinF32x4;
  table.MaxF32x4 := @NEONMaxF32x4;

  // Extended math functions
  table.FmaF32x4 := @NEONFmaF32x4;
  table.RcpF32x4 := @NEONRcpF32x4;
  table.RsqrtF32x4 := @NEONRsqrtF32x4;
  table.FloorF32x4 := @NEONFloorF32x4;
  table.CeilF32x4 := @NEONCeilF32x4;
  table.RoundF32x4 := @NEONRoundF32x4;
  table.TruncF32x4 := @NEONTruncF32x4;
  table.ClampF32x4 := @NEONClampF32x4;

  // 3D/4D Vector math
  table.DotF32x4 := @NEONDotF32x4;
  table.DotF32x3 := @NEONDotF32x3;
  table.CrossF32x3 := @NEONCrossF32x3;
  table.LengthF32x4 := @NEONLengthF32x4;
  table.LengthF32x3 := @NEONLengthF32x3;
  table.NormalizeF32x4 := @NEONNormalizeF32x4;

  // ✅ Iteration 6.4: FMA-optimized Dot Product
  table.DotF32x8 := @NEONDotF32x8;
  table.DotF64x2 := @NEONDotF64x2;
  table.DotF64x4 := @NEONDotF64x4;
  table.NormalizeF32x3 := @NEONNormalizeF32x3;

  // Reduction operations
  table.ReduceAddF32x4 := @NEONReduceAddF32x4;
  table.ReduceMinF32x4 := @NEONReduceMinF32x4;
  table.ReduceMaxF32x4 := @NEONReduceMaxF32x4;
  table.ReduceMulF32x4 := @NEONReduceMulF32x4;

  // Memory operations
  table.LoadF32x4 := @NEONLoadF32x4;
  table.LoadF32x4Aligned := @NEONLoadF32x4Aligned;
  table.StoreF32x4 := @NEONStoreF32x4;
  table.StoreF32x4Aligned := @NEONStoreF32x4Aligned;

  // Utility operations
  table.SplatF32x4 := @NEONSplatF32x4;
  table.ZeroF32x4 := @NEONZeroF32x4;
  table.SelectF32x4 := @NEONSelectF32x4;
  table.ExtractF32x4 := @NEONExtractF32x4;
  table.InsertF32x4 := @NEONInsertF32x4;

  // Facade functions
  table.MemEqual := @MemEqual_NEON;
  table.MemFindByte := @MemFindByte_NEON;
  table.MemDiffRange := @MemDiffRange_NEON;
  table.MemCopy := @MemCopy_NEON;
  table.MemSet := @MemSet_NEON;
  table.MemReverse := @MemReverse_NEON;
  table.SumBytes := @SumBytes_NEON;
  table.MinMaxBytes := @MinMaxBytes_NEON;
  table.CountByte := @CountByte_NEON;
  table.Utf8Validate := @Utf8Validate_NEON;
  table.AsciiIEqual := @AsciiIEqual_NEON;
  table.ToLowerAscii := @ToLowerAscii_NEON;
  table.ToUpperAscii := @ToUpperAscii_NEON;
  table.BytesIndexOf := @BytesIndexOf_NEON;
  table.BitsetPopCount := @BitsetPopCount_NEON;

  // ✅ P2: Saturating Arithmetic
  table.I8x16SatAdd := @NEONI8x16SatAdd;
  table.I8x16SatSub := @NEONI8x16SatSub;
  table.I16x8SatAdd := @NEONI16x8SatAdd;
  table.I16x8SatSub := @NEONI16x8SatSub;
  table.U8x16SatAdd := @NEONU8x16SatAdd;
  table.U8x16SatSub := @NEONU8x16SatSub;
  table.U16x8SatAdd := @NEONU16x8SatAdd;
  table.U16x8SatSub := @NEONU16x8SatSub;

  {$IFNDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  // ✅ P3: I64x2 Arithmetic, Bitwise, and Comparison
  table.AddI64x2 := @NEONAddI64x2;
  table.SubI64x2 := @NEONSubI64x2;
  table.AndI64x2 := @NEONAndI64x2;
  table.OrI64x2 := @NEONOrI64x2;
  table.XorI64x2 := @NEONXorI64x2;
  table.NotI64x2 := @NEONNotI64x2;
  table.AndNotI64x2 := @NEONAndNotI64x2;
  table.ShiftLeftI64x2 := @NEONShiftLeftI64x2;
  table.ShiftRightI64x2 := @NEONShiftRightI64x2;
  table.ShiftRightArithI64x2 := @NEONShiftRightArithI64x2;
  table.CmpEqI64x2 := @NEONCmpEqI64x2;
  table.CmpLtI64x2 := @NEONCmpLtI64x2;
  table.CmpGtI64x2 := @NEONCmpGtI64x2;
  table.CmpLeI64x2 := @NEONCmpLeI64x2;
  table.CmpGeI64x2 := @NEONCmpGeI64x2;
  table.CmpNeI64x2 := @NEONCmpNeI64x2;
  table.MinI64x2 := @NEONMinI64x2;
  table.MaxI64x2 := @NEONMaxI64x2;

  // ✅ P3.3: U64x2 Arithmetic, Bitwise, and Comparison (优先复用 I64x2 路径)
  table.AddU64x2 := @NEONAddU64x2;
  table.SubU64x2 := @NEONSubU64x2;
  table.AndU64x2 := @NEONAndU64x2;
  table.OrU64x2 := @NEONOrU64x2;
  table.XorU64x2 := @NEONXorU64x2;
  table.NotU64x2 := @NEONNotU64x2;
  table.AndNotU64x2 := @NEONAndNotU64x2;
  table.CmpEqU64x2 := @NEONCmpEqU64x2;
  table.CmpLtU64x2 := @NEONCmpLtU64x2;
  table.CmpGtU64x2 := @NEONCmpGtU64x2;
  table.MinU64x2 := @NEONMinU64x2;
  table.MaxU64x2 := @NEONMaxU64x2;

  // ✅ I16x8 整数操作 (8×Int16)
  table.AddI16x8 := @NEONAddI16x8;
  table.SubI16x8 := @NEONSubI16x8;
  table.MulI16x8 := @NEONMulI16x8;
  table.AndI16x8 := @NEONAndI16x8;
  table.OrI16x8 := @NEONOrI16x8;
  table.XorI16x8 := @NEONXorI16x8;
  table.NotI16x8 := @NEONNotI16x8;
  table.AndNotI16x8 := @NEONAndNotI16x8;
  table.MinI16x8 := @NEONMinI16x8;
  table.MaxI16x8 := @NEONMaxI16x8;

  // ✅ I8x16 整数操作 (16×Int8)
  table.AddI8x16 := @NEONAddI8x16;
  table.SubI8x16 := @NEONSubI8x16;
  table.AndI8x16 := @NEONAndI8x16;
  table.OrI8x16 := @NEONOrI8x16;
  table.XorI8x16 := @NEONXorI8x16;
  table.NotI8x16 := @NEONNotI8x16;
  table.MinI8x16 := @NEONMinI8x16;
  table.MaxI8x16 := @NEONMaxI8x16;

  // ✅ U16x8 无符号整数操作 (8×UInt16)
  table.AddU16x8 := @NEONAddU16x8;
  table.SubU16x8 := @NEONSubU16x8;
  table.MulU16x8 := @NEONMulU16x8;
  table.AndU16x8 := @NEONAndU16x8;
  table.OrU16x8 := @NEONOrU16x8;
  table.XorU16x8 := @NEONXorU16x8;
  table.NotU16x8 := @NEONNotU16x8;
  table.MinU16x8 := @NEONMinU16x8;
  table.MaxU16x8 := @NEONMaxU16x8;

  // ✅ U8x16 无符号整数操作 (16×UInt8)
  table.AddU8x16 := @NEONAddU8x16;
  table.SubU8x16 := @NEONSubU8x16;
  table.AndU8x16 := @NEONAndU8x16;
  table.OrU8x16 := @NEONOrU8x16;
  table.XorU8x16 := @NEONXorU8x16;
  table.NotU8x16 := @NEONNotU8x16;
  table.MinU8x16 := @NEONMinU8x16;
  table.MaxU8x16 := @NEONMaxU8x16;

  // ✅ P4: SelectF64x2
  table.SelectF64x2 := @NEONSelectF64x2;

  // ✅ P1: Mask Operations
  table.Mask2All := @NEONMask2All;
  table.Mask2Any := @NEONMask2Any;
  table.Mask2None := @NEONMask2None;
  table.Mask2PopCount := @NEONMask2PopCount;
  table.Mask2FirstSet := @NEONMask2FirstSet;
  table.Mask4All := @NEONMask4All;
  table.Mask4Any := @NEONMask4Any;
  table.Mask4None := @NEONMask4None;
  table.Mask4PopCount := @NEONMask4PopCount;
  table.Mask4FirstSet := @NEONMask4FirstSet;
  table.Mask8All := @NEONMask8All;
  table.Mask8Any := @NEONMask8Any;
  table.Mask8None := @NEONMask8None;
  table.Mask8PopCount := @NEONMask8PopCount;
  table.Mask8FirstSet := @NEONMask8FirstSet;
  table.Mask16All := @NEONMask16All;
  table.Mask16Any := @NEONMask16Any;
  table.Mask16None := @NEONMask16None;
  table.Mask16PopCount := @NEONMask16PopCount;
  table.Mask16FirstSet := @NEONMask16FirstSet;

  // === Auto-generated Registration for 100% Coverage ===
  table.AbsF32x16 := @NEONAbsF32x16;
  table.AbsF32x8 := @NEONAbsF32x8;
  table.AbsF64x2 := @NEONAbsF64x2;
  table.AbsF64x4 := @NEONAbsF64x4;
  table.AbsF64x8 := @NEONAbsF64x8;
  table.AddF32x16 := @NEONAddF32x16;
  table.AddF64x4 := @NEONAddF64x4;
  table.AddF64x8 := @NEONAddF64x8;
  table.AddI32x16 := @NEONAddI32x16;
  table.AddI32x8 := @NEONAddI32x8;
  table.AddI64x4 := @NEONAddI64x4;
  table.AddI64x8 := @NEONAddI64x8;
  table.AddI16x32 := @NEONAddI16x32;
  table.AddI8x64 := @NEONAddI8x64;
  table.SubI16x32 := @NEONSubI16x32;
  table.SubI8x64 := @NEONSubI8x64;
  table.AndI16x32 := @NEONAndI16x32;
  table.AndI8x64 := @NEONAndI8x64;
  table.OrI16x32 := @NEONOrI16x32;
  table.OrI8x64 := @NEONOrI8x64;
  table.XorI16x32 := @NEONXorI16x32;
  table.XorI8x64 := @NEONXorI8x64;
  table.NotI16x32 := @NEONNotI16x32;
  table.NotI8x64 := @NEONNotI8x64;
  table.AndNotI16x32 := @NEONAndNotI16x32;
  table.AndNotI8x64 := @NEONAndNotI8x64;
  table.CmpEqI16x32 := @NEONCmpEqI16x32;
  table.CmpEqI8x64 := @NEONCmpEqI8x64;
  table.CmpLtI16x32 := @NEONCmpLtI16x32;
  table.CmpLtI8x64 := @NEONCmpLtI8x64;
  table.CmpGtI16x32 := @NEONCmpGtI16x32;
  table.CmpGtI8x64 := @NEONCmpGtI8x64;
  table.MinI16x32 := @NEONMinI16x32;
  table.MinI8x64 := @NEONMinI8x64;
  table.MaxI16x32 := @NEONMaxI16x32;
  table.MaxI8x64 := @NEONMaxI8x64;
  table.ShiftLeftI16x32 := @NEONShiftLeftI16x32;
  table.ShiftRightI16x32 := @NEONShiftRightI16x32;
  table.ShiftRightArithI16x32 := @NEONShiftRightArithI16x32;
  table.AddU8x64 := @NEONAddU8x64;
  table.SubU8x64 := @NEONSubU8x64;
  table.AndU8x64 := @NEONAndU8x64;
  table.OrU8x64 := @NEONOrU8x64;
  table.XorU8x64 := @NEONXorU8x64;
  table.NotU8x64 := @NEONNotU8x64;
  table.CmpEqU8x64 := @NEONCmpEqU8x64;
  table.CmpLtU8x64 := @NEONCmpLtU8x64;
  table.CmpGtU8x64 := @NEONCmpGtU8x64;
  table.MinU8x64 := @NEONMinU8x64;
  table.MaxU8x64 := @NEONMaxU8x64;
  table.AddU32x16 := @NEONAddU32x16;
  table.SubU32x16 := @NEONSubU32x16;
  table.MulU32x16 := @NEONMulU32x16;
  table.AndU32x16 := @NEONAndU32x16;
  table.OrU32x16 := @NEONOrU32x16;
  table.XorU32x16 := @NEONXorU32x16;
  table.NotU32x16 := @NEONNotU32x16;
  table.AndNotU32x16 := @NEONAndNotU32x16;
  table.ShiftLeftU32x16 := @NEONShiftLeftU32x16;
  table.ShiftRightU32x16 := @NEONShiftRightU32x16;
  table.CmpEqU32x16 := @NEONCmpEqU32x16;
  table.CmpLtU32x16 := @NEONCmpLtU32x16;
  table.CmpGtU32x16 := @NEONCmpGtU32x16;
  table.CmpLeU32x16 := @NEONCmpLeU32x16;
  table.CmpGeU32x16 := @NEONCmpGeU32x16;
  table.CmpNeU32x16 := @NEONCmpNeU32x16;
  table.MinU32x16 := @NEONMinU32x16;
  table.MaxU32x16 := @NEONMaxU32x16;
  table.AddU64x8 := @NEONAddU64x8;
  table.SubU64x8 := @NEONSubU64x8;
  table.AndU64x8 := @NEONAndU64x8;
  table.OrU64x8 := @NEONOrU64x8;
  table.XorU64x8 := @NEONXorU64x8;
  table.NotU64x8 := @NEONNotU64x8;
  table.ShiftLeftU64x8 := @NEONShiftLeftU64x8;
  table.ShiftRightU64x8 := @NEONShiftRightU64x8;
  table.CmpEqU64x8 := @NEONCmpEqU64x8;
  table.CmpLtU64x8 := @NEONCmpLtU64x8;
  table.CmpGtU64x8 := @NEONCmpGtU64x8;
  table.CmpLeU64x8 := @NEONCmpLeU64x8;
  table.CmpGeU64x8 := @NEONCmpGeU64x8;
  table.CmpNeU64x8 := @NEONCmpNeU64x8;
  table.AddU32x4 := @NEONAddU32x4;
  table.AddU32x8 := @NEONAddU32x8;
  table.AddU64x4 := @NEONAddU64x4;
  table.AndI32x16 := @NEONAndI32x16;
  table.AndI32x4 := @NEONAndI32x4;
  table.AndI32x8 := @NEONAndI32x8;
  table.AndI64x4 := @NEONAndI64x4;
  table.AndI64x8 := @NEONAndI64x8;
  table.AndNotI32x16 := @NEONAndNotI32x16;
  table.AndNotI32x4 := @NEONAndNotI32x4;
  table.AndNotI32x8 := @NEONAndNotI32x8;
  table.AndNotI64x4 := @NEONAndNotI64x4;
  table.AndNotU32x4 := @NEONAndNotU32x4;
  table.AndNotU32x8 := @NEONAndNotU32x8;
  table.AndU32x4 := @NEONAndU32x4;
  table.AndU32x8 := @NEONAndU32x8;
  table.AndU64x4 := @NEONAndU64x4;
  table.CeilF32x16 := @NEONCeilF32x16;
  table.CeilF32x8 := @NEONCeilF32x8;
  table.CeilF64x2 := @NEONCeilF64x2;
  table.CeilF64x4 := @NEONCeilF64x4;
  table.CeilF64x8 := @NEONCeilF64x8;
  table.ClampF32x16 := @NEONClampF32x16;
  table.ClampF32x8 := @NEONClampF32x8;
  table.ClampF64x2 := @NEONClampF64x2;
  table.ClampF64x4 := @NEONClampF64x4;
  table.ClampF64x8 := @NEONClampF64x8;
  table.CmpEqF32x16 := @NEONCmpEqF32x16;
  table.CmpEqF32x8 := @NEONCmpEqF32x8;
  table.CmpEqF64x2 := @NEONCmpEqF64x2;
  table.CmpEqF64x4 := @NEONCmpEqF64x4;
  table.CmpEqF64x8 := @NEONCmpEqF64x8;
  table.CmpEqI16x8 := @NEONCmpEqI16x8;
  table.CmpEqI32x16 := @NEONCmpEqI32x16;
  table.CmpEqI32x4 := @NEONCmpEqI32x4;
  table.CmpEqI32x8 := @NEONCmpEqI32x8;
  table.CmpEqI64x4 := @NEONCmpEqI64x4;
  table.CmpEqI64x8 := @NEONCmpEqI64x8;
  table.CmpEqI8x16 := @NEONCmpEqI8x16;
  table.CmpEqU16x8 := @NEONCmpEqU16x8;
  table.CmpEqU32x4 := @NEONCmpEqU32x4;
  table.CmpEqU32x8 := @NEONCmpEqU32x8;
  table.CmpEqU64x4 := @NEONCmpEqU64x4;
  table.CmpEqU8x16 := @NEONCmpEqU8x16;
  table.CmpGeF32x16 := @NEONCmpGeF32x16;
  table.CmpGeF32x8 := @NEONCmpGeF32x8;
  table.CmpGeF64x2 := @NEONCmpGeF64x2;
  table.CmpGeF64x4 := @NEONCmpGeF64x4;
  table.CmpGeF64x8 := @NEONCmpGeF64x8;
  table.CmpGeI16x8 := @NEONCmpGeI16x8;
  table.CmpGeI32x16 := @NEONCmpGeI32x16;
  table.CmpGeI32x4 := @NEONCmpGeI32x4;
  table.CmpGeI32x8 := @NEONCmpGeI32x8;
  table.CmpGeI64x4 := @NEONCmpGeI64x4;
  table.CmpGeI64x8 := @NEONCmpGeI64x8;
  table.CmpGeI8x16 := @NEONCmpGeI8x16;
  table.CmpGeU16x8 := @NEONCmpGeU16x8;
  table.CmpGeU32x4 := @NEONCmpGeU32x4;
  table.CmpGeU32x8 := @NEONCmpGeU32x8;
  table.CmpGeU64x4 := @NEONCmpGeU64x4;
  table.CmpGeU8x16 := @NEONCmpGeU8x16;
  table.CmpGtF32x16 := @NEONCmpGtF32x16;
  table.CmpGtF32x8 := @NEONCmpGtF32x8;
  table.CmpGtF64x2 := @NEONCmpGtF64x2;
  table.CmpGtF64x4 := @NEONCmpGtF64x4;
  table.CmpGtF64x8 := @NEONCmpGtF64x8;
  table.CmpGtI16x8 := @NEONCmpGtI16x8;
  table.CmpGtI32x16 := @NEONCmpGtI32x16;
  table.CmpGtI32x4 := @NEONCmpGtI32x4;
  table.CmpGtI32x8 := @NEONCmpGtI32x8;
  table.CmpGtI64x4 := @NEONCmpGtI64x4;
  table.CmpGtI64x8 := @NEONCmpGtI64x8;
  table.CmpGtI8x16 := @NEONCmpGtI8x16;
  table.CmpGtU16x8 := @NEONCmpGtU16x8;
  table.CmpGtU32x4 := @NEONCmpGtU32x4;
  table.CmpGtU32x8 := @NEONCmpGtU32x8;
  table.CmpGtU64x4 := @NEONCmpGtU64x4;
  table.CmpGtU8x16 := @NEONCmpGtU8x16;
  table.CmpLeF32x16 := @NEONCmpLeF32x16;
  table.CmpLeF32x8 := @NEONCmpLeF32x8;
  table.CmpLeF64x2 := @NEONCmpLeF64x2;
  table.CmpLeF64x4 := @NEONCmpLeF64x4;
  table.CmpLeF64x8 := @NEONCmpLeF64x8;
  table.CmpLeI16x8 := @NEONCmpLeI16x8;
  table.CmpLeI32x16 := @NEONCmpLeI32x16;
  table.CmpLeI32x4 := @NEONCmpLeI32x4;
  table.CmpLeI32x8 := @NEONCmpLeI32x8;
  table.CmpLeI64x4 := @NEONCmpLeI64x4;
  table.CmpLeI64x8 := @NEONCmpLeI64x8;
  table.CmpLeI8x16 := @NEONCmpLeI8x16;
  table.CmpLeU16x8 := @NEONCmpLeU16x8;
  table.CmpLeU32x4 := @NEONCmpLeU32x4;
  table.CmpLeU32x8 := @NEONCmpLeU32x8;
  table.CmpLeU64x4 := @NEONCmpLeU64x4;
  table.CmpLeU8x16 := @NEONCmpLeU8x16;
  table.CmpLtF32x16 := @NEONCmpLtF32x16;
  table.CmpLtF32x8 := @NEONCmpLtF32x8;
  table.CmpLtF64x2 := @NEONCmpLtF64x2;
  table.CmpLtF64x4 := @NEONCmpLtF64x4;
  table.CmpLtF64x8 := @NEONCmpLtF64x8;
  table.CmpLtI16x8 := @NEONCmpLtI16x8;
  table.CmpLtI32x16 := @NEONCmpLtI32x16;
  table.CmpLtI32x4 := @NEONCmpLtI32x4;
  table.CmpLtI32x8 := @NEONCmpLtI32x8;
  table.CmpLtI64x4 := @NEONCmpLtI64x4;
  table.CmpLtI64x8 := @NEONCmpLtI64x8;
  table.CmpLtI8x16 := @NEONCmpLtI8x16;
  table.CmpLtU16x8 := @NEONCmpLtU16x8;
  table.CmpLtU32x4 := @NEONCmpLtU32x4;
  table.CmpLtU32x8 := @NEONCmpLtU32x8;
  table.CmpLtU64x4 := @NEONCmpLtU64x4;
  table.CmpLtU8x16 := @NEONCmpLtU8x16;
  table.CmpNeF32x16 := @NEONCmpNeF32x16;
  table.CmpNeF32x8 := @NEONCmpNeF32x8;
  table.CmpNeF64x2 := @NEONCmpNeF64x2;
  table.CmpNeF64x4 := @NEONCmpNeF64x4;
  table.CmpNeF64x8 := @NEONCmpNeF64x8;
  table.CmpNeI16x8 := @NEONCmpNeI16x8;
  table.CmpNeI32x16 := @NEONCmpNeI32x16;
  table.CmpNeI32x4 := @NEONCmpNeI32x4;
  table.CmpNeI32x8 := @NEONCmpNeI32x8;
  table.CmpNeI64x4 := @NEONCmpNeI64x4;
  table.CmpNeI64x8 := @NEONCmpNeI64x8;
  table.CmpNeI8x16 := @NEONCmpNeI8x16;
  table.CmpNeU16x8 := @NEONCmpNeU16x8;
  table.CmpNeU32x8 := @NEONCmpNeU32x8;
  table.CmpNeU64x4 := @NEONCmpNeU64x4;
  table.CmpNeU8x16 := @NEONCmpNeU8x16;
  table.DivF32x16 := @NEONDivF32x16;
  table.DivF64x4 := @NEONDivF64x4;
  table.DivF64x8 := @NEONDivF64x8;
  table.ExtractF32x16 := @NEONExtractF32x16;
  table.ExtractF32x8 := @NEONExtractF32x8;
  table.ExtractF64x2 := @NEONExtractF64x2;
  table.ExtractF64x4 := @NEONExtractF64x4;
  table.ExtractI32x16 := @NEONExtractI32x16;
  table.ExtractI32x4 := @NEONExtractI32x4;
  table.ExtractI32x8 := @NEONExtractI32x8;
  table.ExtractI64x2 := @NEONExtractI64x2;
  table.ExtractI64x4 := @NEONExtractI64x4;
  table.FloorF32x16 := @NEONFloorF32x16;
  table.FloorF32x8 := @NEONFloorF32x8;
  table.FloorF64x2 := @NEONFloorF64x2;
  table.FloorF64x4 := @NEONFloorF64x4;
  table.FloorF64x8 := @NEONFloorF64x8;
  table.FmaF32x16 := @NEONFmaF32x16;
  table.FmaF32x8 := @NEONFmaF32x8;
  table.FmaF64x2 := @NEONFmaF64x2;
  table.FmaF64x4 := @NEONFmaF64x4;
  table.FmaF64x8 := @NEONFmaF64x8;
  table.InsertF32x16 := @NEONInsertF32x16;
  table.InsertF32x8 := @NEONInsertF32x8;
  table.InsertF64x2 := @NEONInsertF64x2;
  table.InsertF64x4 := @NEONInsertF64x4;
  table.InsertI32x16 := @NEONInsertI32x16;
  table.InsertI32x4 := @NEONInsertI32x4;
  table.InsertI32x8 := @NEONInsertI32x8;
  table.InsertI64x2 := @NEONInsertI64x2;
  table.InsertI64x4 := @NEONInsertI64x4;
  table.LoadF32x16 := @NEONLoadF32x16;
  table.LoadF32x8 := @NEONLoadF32x8;
  table.LoadF64x2 := @NEONLoadF64x2;
  table.LoadF64x4 := @NEONLoadF64x4;
  table.LoadF64x8 := @NEONLoadF64x8;
  table.LoadI64x4 := @NEONLoadI64x4;
  table.MaxF32x16 := @NEONMaxF32x16;
  table.MaxF32x8 := @NEONMaxF32x8;
  table.MaxF64x2 := @NEONMaxF64x2;
  table.MaxF64x4 := @NEONMaxF64x4;
  table.MaxF64x8 := @NEONMaxF64x8;
  table.MaxI32x16 := @NEONMaxI32x16;
  table.MaxI32x4 := @NEONMaxI32x4;
  table.MaxI32x8 := @NEONMaxI32x8;
  table.MaxU32x4 := @NEONMaxU32x4;
  table.MaxU32x8 := @NEONMaxU32x8;
  table.MinF32x16 := @NEONMinF32x16;
  table.MinF32x8 := @NEONMinF32x8;
  table.MinF64x2 := @NEONMinF64x2;
  table.MinF64x4 := @NEONMinF64x4;
  table.MinF64x8 := @NEONMinF64x8;
  table.MinI32x16 := @NEONMinI32x16;
  table.MinI32x4 := @NEONMinI32x4;
  table.MinI32x8 := @NEONMinI32x8;
  table.MinU32x4 := @NEONMinU32x4;
  table.MinU32x8 := @NEONMinU32x8;
  table.MulF32x16 := @NEONMulF32x16;
  table.MulF64x4 := @NEONMulF64x4;
  table.MulF64x8 := @NEONMulF64x8;
  table.MulI32x16 := @NEONMulI32x16;
  table.MulI32x8 := @NEONMulI32x8;
  table.MulU32x4 := @NEONMulU32x4;
  table.MulU32x8 := @NEONMulU32x8;
  table.NotI32x16 := @NEONNotI32x16;
  table.NotI32x4 := @NEONNotI32x4;
  table.NotI32x8 := @NEONNotI32x8;
  table.NotI64x4 := @NEONNotI64x4;
  table.NotI64x8 := @NEONNotI64x8;
  table.NotU32x4 := @NEONNotU32x4;
  table.NotU32x8 := @NEONNotU32x8;
  table.NotU64x4 := @NEONNotU64x4;
  table.OrI32x16 := @NEONOrI32x16;
  table.OrI32x4 := @NEONOrI32x4;
  table.OrI32x8 := @NEONOrI32x8;
  table.OrI64x4 := @NEONOrI64x4;
  table.OrI64x8 := @NEONOrI64x8;
  table.OrU32x4 := @NEONOrU32x4;
  table.OrU32x8 := @NEONOrU32x8;
  table.OrU64x4 := @NEONOrU64x4;
  table.RcpF64x4 := @NEONRcpF64x4;
  table.ReduceAddF32x16 := @NEONReduceAddF32x16;
  table.ReduceAddF32x8 := @NEONReduceAddF32x8;
  table.ReduceAddF64x2 := @NEONReduceAddF64x2;
  table.ReduceAddF64x4 := @NEONReduceAddF64x4;
  table.ReduceAddF64x8 := @NEONReduceAddF64x8;
  table.ReduceMaxF32x16 := @NEONReduceMaxF32x16;
  table.ReduceMaxF32x8 := @NEONReduceMaxF32x8;
  table.ReduceMaxF64x2 := @NEONReduceMaxF64x2;
  table.ReduceMaxF64x4 := @NEONReduceMaxF64x4;
  table.ReduceMaxF64x8 := @NEONReduceMaxF64x8;
  table.ReduceMinF32x16 := @NEONReduceMinF32x16;
  table.ReduceMinF32x8 := @NEONReduceMinF32x8;
  table.ReduceMinF64x2 := @NEONReduceMinF64x2;
  table.ReduceMinF64x4 := @NEONReduceMinF64x4;
  table.ReduceMinF64x8 := @NEONReduceMinF64x8;
  table.ReduceMulF32x16 := @NEONReduceMulF32x16;
  table.ReduceMulF32x8 := @NEONReduceMulF32x8;
  table.ReduceMulF64x2 := @NEONReduceMulF64x2;
  table.ReduceMulF64x4 := @NEONReduceMulF64x4;
  table.ReduceMulF64x8 := @NEONReduceMulF64x8;
  table.RoundF32x16 := @NEONRoundF32x16;
  table.RoundF32x8 := @NEONRoundF32x8;
  table.RoundF64x2 := @NEONRoundF64x2;
  table.RoundF64x4 := @NEONRoundF64x4;
  table.RoundF64x8 := @NEONRoundF64x8;
  table.SelectF32x16 := @NEONSelectF32x16;
  table.SelectF32x8 := @NEONSelectF32x8;
  table.SelectF64x4 := @NEONSelectF64x4;
  table.SelectF64x8 := @NEONSelectF64x8;
  table.SelectI32x4 := @NEONSelectI32x4;
  table.ShiftLeftI16x8 := @NEONShiftLeftI16x8;
  table.ShiftLeftI32x16 := @NEONShiftLeftI32x16;
  table.ShiftLeftI32x4 := @NEONShiftLeftI32x4;
  table.ShiftLeftI32x8 := @NEONShiftLeftI32x8;
  table.ShiftLeftI64x4 := @NEONShiftLeftI64x4;
  table.ShiftLeftU16x8 := @NEONShiftLeftU16x8;
  table.ShiftLeftU32x4 := @NEONShiftLeftU32x4;
  table.ShiftLeftU32x8 := @NEONShiftLeftU32x8;
  table.ShiftLeftU64x4 := @NEONShiftLeftU64x4;
  table.ShiftRightArithI16x8 := @NEONShiftRightArithI16x8;
  table.ShiftRightArithI32x16 := @NEONShiftRightArithI32x16;
  table.ShiftRightArithI32x4 := @NEONShiftRightArithI32x4;
  table.ShiftRightArithI32x8 := @NEONShiftRightArithI32x8;
  table.ShiftRightI16x8 := @NEONShiftRightI16x8;
  table.ShiftRightI32x16 := @NEONShiftRightI32x16;
  table.ShiftRightI32x4 := @NEONShiftRightI32x4;
  table.ShiftRightI32x8 := @NEONShiftRightI32x8;
  table.ShiftRightI64x4 := @NEONShiftRightI64x4;
  table.ShiftRightArithI64x4 := @NEONShiftRightArithI64x4;
  table.ShiftRightU16x8 := @NEONShiftRightU16x8;
  table.ShiftRightU32x4 := @NEONShiftRightU32x4;
  table.ShiftRightU32x8 := @NEONShiftRightU32x8;
  table.ShiftRightU64x4 := @NEONShiftRightU64x4;
  table.SplatF32x16 := @NEONSplatF32x16;
  table.SplatF32x8 := @NEONSplatF32x8;
  table.SplatF64x2 := @NEONSplatF64x2;
  table.SplatF64x4 := @NEONSplatF64x4;
  table.SplatF64x8 := @NEONSplatF64x8;
  table.SplatI64x4 := @NEONSplatI64x4;
  table.SqrtF32x16 := @NEONSqrtF32x16;
  table.SqrtF32x8 := @NEONSqrtF32x8;
  table.SqrtF64x2 := @NEONSqrtF64x2;
  table.SqrtF64x4 := @NEONSqrtF64x4;
  table.SqrtF64x8 := @NEONSqrtF64x8;
  table.StoreF32x16 := @NEONStoreF32x16;
  table.StoreF32x8 := @NEONStoreF32x8;
  table.StoreF64x2 := @NEONStoreF64x2;
  table.StoreF64x4 := @NEONStoreF64x4;
  table.StoreF64x8 := @NEONStoreF64x8;
  table.StoreI64x4 := @NEONStoreI64x4;
  table.SubF32x16 := @NEONSubF32x16;
  table.SubF64x4 := @NEONSubF64x4;
  table.SubF64x8 := @NEONSubF64x8;
  table.SubI32x16 := @NEONSubI32x16;
  table.SubI32x8 := @NEONSubI32x8;
  table.SubI64x4 := @NEONSubI64x4;
  table.SubI64x8 := @NEONSubI64x8;
  table.SubU32x4 := @NEONSubU32x4;
  table.SubU32x8 := @NEONSubU32x8;
  table.SubU64x4 := @NEONSubU64x4;
  table.TruncF32x16 := @NEONTruncF32x16;
  table.TruncF32x8 := @NEONTruncF32x8;
  table.TruncF64x2 := @NEONTruncF64x2;
  table.TruncF64x4 := @NEONTruncF64x4;
  table.TruncF64x8 := @NEONTruncF64x8;
  table.XorI32x16 := @NEONXorI32x16;
  table.XorI32x4 := @NEONXorI32x4;
  table.XorI32x8 := @NEONXorI32x8;
  table.XorI64x4 := @NEONXorI64x4;
  table.XorI64x8 := @NEONXorI64x8;
  table.XorU32x4 := @NEONXorU32x4;
  table.XorU32x8 := @NEONXorU32x8;
  table.XorU64x4 := @NEONXorU64x4;
  table.ZeroF32x16 := @NEONZeroF32x16;
  table.ZeroF32x8 := @NEONZeroF32x8;
  table.ZeroF64x2 := @NEONZeroF64x2;
  table.ZeroF64x4 := @NEONZeroF64x4;
  table.ZeroF64x8 := @NEONZeroF64x8;
  table.ZeroI64x4 := @NEONZeroI64x4;
  {$ENDIF}
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  table.AndNotI8x16 := @NEONAndNotI8x16;
  table.AndNotU16x8 := @NEONAndNotU16x8;
  table.AndNotU8x16 := @NEONAndNotU8x16;
  {$ENDIF}

  // Register the backend
  RegisterBackend(sbNEON, table);
end;

initialization
  // Test-only opt-in path: allow non-native hosts to register NEON scalar-fallback
  // implementations so DispatchAPI/PublicAbi suites can verify metadata contracts.
  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND}
    RegisterNEONBackend;
    RegisterBackendRebuilder(sbNEON, @RegisterNEONBackend);
  {$ELSE}
  // Only register NEON backend when ASM is available.
  // FPC 3.2.2 does NOT support AArch64 NEON inline assembly (causes ICE).
  // Without ASM, the scalar fallback + dispatch overhead makes performance WORSE.
  // Users with FPC 3.2.2 should use the scalar backend directly.
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
    {$IFDEF CPUAARCH64}
    RegisterNEONBackend;
    RegisterBackendRebuilder(sbNEON, @RegisterNEONBackend);
    {$ENDIF}
    {$IFDEF CPUARM}
    RegisterNEONBackend;
    RegisterBackendRebuilder(sbNEON, @RegisterNEONBackend);
    {$ENDIF}
  {$ENDIF}
  {$ENDIF}

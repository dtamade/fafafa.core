procedure RegisterRISCVVBackend;
var
  table: TSimdDispatchTable;
  LCapabilities: TSimdCapabilities;
  LAsmCapable: Boolean;
  LUseVectorAsm: Boolean;
begin
  // ✅ 使用 FillBaseDispatchTable 填充标量后备实现，而不是 FillChar
  // 这确保所有未注册的函数都有有效的后备实现，避免空指针异常
  table := Default(TSimdDispatchTable);
  FillBaseDispatchTable(table);

  LAsmCapable := False;
  {$IFDEF RISCVV_ASSEMBLY}
  LAsmCapable := True;
  {$ENDIF}
  LUseVectorAsm := False;
  if LAsmCapable then
    LUseVectorAsm := IsVectorAsmEnabled;

  // Backend info
  table.Backend := sbRISCVV;
  table.BackendInfo.Backend := sbRISCVV;
  table.BackendInfo.Name := 'RISC-V V';
  table.BackendInfo.Description := 'RISC-V Vector Extension (RVV)';
  table.BackendInfo.Available := (not LAsmCapable) or LUseVectorAsm;
  table.BackendInfo.Priority := GetSimdBackendPriorityValue(sbRISCVV);
  LCapabilities := [
    scBasicArithmetic,
    scComparison,
    scMathFunctions,
    scReduction,
    scLoadStore
  ];
  if LUseVectorAsm then
    Include(LCapabilities, scIntegerOps);
  if LUseVectorAsm then
  Include(LCapabilities, scShuffle);
  if LUseVectorAsm then
  Include(LCapabilities, scFMA);
  table.BackendInfo.Capabilities := LCapabilities;

  if LAsmCapable and (not LUseVectorAsm) then
  begin
    RegisterBackend(sbRISCVV, table);
    Exit;
  end;

  // === F32x4 Operations ===
  table.AddF32x4 := @RISCVVAddF32x4;
  table.SubF32x4 := @RISCVVSubF32x4;
  table.MulF32x4 := @RISCVVMulF32x4;
  table.DivF32x4 := @RISCVVDivF32x4;

  // F32x4 Math
  table.AbsF32x4 := @RISCVVAbsF32x4;
  table.SqrtF32x4 := @RISCVVSqrtF32x4;
  table.MinF32x4 := @RISCVVMinF32x4;
  table.MaxF32x4 := @RISCVVMaxF32x4;
  table.FmaF32x4 := @RISCVVFmaF32x4;
  table.RcpF32x4 := @RISCVVRcpF32x4;
  table.RsqrtF32x4 := @RISCVVRsqrtF32x4;
  // Keep IEEE754 semantics stable in RVV asm mode until dedicated
  // floor/ceil/round/trunc asm paths are fully validated.
  {$IFDEF RISCVV_ASSEMBLY}
  table.FloorF32x4 := @ScalarFloorF32x4;
  table.CeilF32x4 := @ScalarCeilF32x4;
  table.RoundF32x4 := @ScalarRoundF32x4;
  table.TruncF32x4 := @ScalarTruncF32x4;
  {$ELSE}
  table.FloorF32x4 := @RISCVVFloorF32x4;
  table.CeilF32x4 := @RISCVVCeilF32x4;
  table.RoundF32x4 := @RISCVVRoundF32x4;
  table.TruncF32x4 := @RISCVVTruncF32x4;
  {$ENDIF}
  table.ClampF32x4 := @RISCVVClampF32x4;

  // F32x4 Vector Math
  table.DotF32x4 := @RISCVVDotF32x4;
  table.DotF32x3 := @RISCVVDotF32x3;
  table.DotF32x8 := @RISCVVDotF32x8;
  table.DotF64x2 := @RISCVVDotF64x2;
  table.DotF64x4 := @RISCVVDotF64x4;
  table.CrossF32x3 := @RISCVVCrossF32x3;
  table.LengthF32x4 := @RISCVVLengthF32x4;
  table.LengthF32x3 := @RISCVVLengthF32x3;
  table.NormalizeF32x4 := @RISCVVNormalizeF32x4;
  table.NormalizeF32x3 := @RISCVVNormalizeF32x3;

  // F32x4 Reduction
  table.ReduceAddF32x4 := @RISCVVReduceAddF32x4;
  table.ReduceMinF32x4 := @RISCVVReduceMinF32x4;
  table.ReduceMaxF32x4 := @RISCVVReduceMaxF32x4;
  table.ReduceMulF32x4 := @RISCVVReduceMulF32x4;

  // F32x4 Comparison
  table.CmpEqF32x4 := @RISCVVCmpEqF32x4;
  table.CmpLtF32x4 := @RISCVVCmpLtF32x4;
  table.CmpLeF32x4 := @RISCVVCmpLeF32x4;
  table.CmpGtF32x4 := @RISCVVCmpGtF32x4;
  table.CmpGeF32x4 := @RISCVVCmpGeF32x4;
  table.CmpNeF32x4 := @RISCVVCmpNeF32x4;

  // F32x4 Memory
  table.LoadF32x4 := @RISCVVLoadF32x4;
  table.LoadF32x4Aligned := @RISCVVLoadF32x4Aligned;
  table.StoreF32x4 := @RISCVVStoreF32x4;
  table.StoreF32x4Aligned := @RISCVVStoreF32x4Aligned;

  // F32x4 Utility
  table.SplatF32x4 := @RISCVVSplatF32x4;
  table.ZeroF32x4 := @RISCVVZeroF32x4;
  table.SelectF32x4 := @RISCVVSelectF32x4;
  table.ExtractF32x4 := @RISCVVExtractF32x4;
  table.InsertF32x4 := @RISCVVInsertF32x4;

  // === F64x2 Operations ===
  table.AddF64x2 := @RISCVVAddF64x2;
  table.SubF64x2 := @RISCVVSubF64x2;
  table.MulF64x2 := @RISCVVMulF64x2;
  table.DivF64x2 := @RISCVVDivF64x2;

  // === I32x4 Operations ===
  table.AddI32x4 := @RISCVVAddI32x4;
  table.SubI32x4 := @RISCVVSubI32x4;
  table.MulI32x4 := @RISCVVMulI32x4;

  // I32x4 Bitwise
  table.AndI32x4 := @RISCVVAndI32x4;
  table.OrI32x4 := @RISCVVOrI32x4;
  table.XorI32x4 := @RISCVVXorI32x4;
  table.NotI32x4 := @RISCVVNotI32x4;
  table.AndNotI32x4 := @RISCVVAndNotI32x4;

  // I32x4 Shift
  table.ShiftLeftI32x4 := @RISCVVShiftLeftI32x4;
  table.ShiftRightI32x4 := @RISCVVShiftRightI32x4;
  table.ShiftRightArithI32x4 := @RISCVVShiftRightArithI32x4;

  // I32x4 Comparison
  table.CmpEqI32x4 := @RISCVVCmpEqI32x4;
  table.CmpLtI32x4 := @RISCVVCmpLtI32x4;
  table.CmpGtI32x4 := @RISCVVCmpGtI32x4;
  table.CmpLeI32x4 := @RISCVVCmpLeI32x4;  // ✅ Task 6.4: Added
  table.CmpGeI32x4 := @RISCVVCmpGeI32x4;  // ✅ Task 6.4: Added
  table.CmpNeI32x4 := @RISCVVCmpNeI32x4;  // ✅ Task 6.4: Added

  // I32x4 Min/Max
  table.MinI32x4 := @RISCVVMinI32x4;
  table.MaxI32x4 := @RISCVVMaxI32x4;

  // === I64x2 Operations ===
  table.AddI64x2 := @RISCVVAddI64x2;
  table.SubI64x2 := @RISCVVSubI64x2;
  table.AndI64x2 := @RISCVVAndI64x2;
  table.OrI64x2 := @RISCVVOrI64x2;
  table.XorI64x2 := @RISCVVXorI64x2;
  table.NotI64x2 := @RISCVVNotI64x2;
  table.AndNotI64x2 := @RISCVVAndNotI64x2;
  table.ShiftLeftI64x2 := @RISCVVShiftLeftI64x2;
  table.ShiftRightI64x2 := @RISCVVShiftRightI64x2;
  table.ShiftRightArithI64x2 := @RISCVVShiftRightArithI64x2;
  table.MinI64x2 := @RISCVVMinI64x2;
  table.MaxI64x2 := @RISCVVMaxI64x2;

  // === U64x2 Operations ===
  table.AddU64x2 := @RISCVVAddU64x2;
  table.SubU64x2 := @RISCVVSubU64x2;
  table.AndU64x2 := @RISCVVAndU64x2;
  table.OrU64x2 := @RISCVVOrU64x2;
  table.XorU64x2 := @RISCVVXorU64x2;
  table.NotU64x2 := @RISCVVNotU64x2;
  table.AndNotU64x2 := @RISCVVAndNotU64x2;
  table.CmpEqU64x2 := @RISCVVCmpEqU64x2;
  table.CmpLtU64x2 := @RISCVVCmpLtU64x2;
  table.CmpGtU64x2 := @RISCVVCmpGtU64x2;
  table.MinU64x2 := @RISCVVMinU64x2;
  table.MaxU64x2 := @RISCVVMaxU64x2;

  // === F32x8 Operations ===
  table.AddF32x8 := @RISCVVAddF32x8;
  table.SubF32x8 := @RISCVVSubF32x8;
  table.MulF32x8 := @RISCVVMulF32x8;
  table.DivF32x8 := @RISCVVDivF32x8;

  // F32x8 Comparison - ✅ Task 6.4: Added
  table.CmpEqF32x8 := @RISCVVCmpEqF32x8;
  table.CmpLtF32x8 := @RISCVVCmpLtF32x8;
  table.CmpLeF32x8 := @RISCVVCmpLeF32x8;
  table.CmpGtF32x8 := @RISCVVCmpGtF32x8;
  table.CmpGeF32x8 := @RISCVVCmpGeF32x8;
  table.CmpNeF32x8 := @RISCVVCmpNeF32x8;

  // === F64x4 Operations ===
  table.AddF64x4 := @RISCVVAddF64x4;
  table.SubF64x4 := @RISCVVSubF64x4;
  table.MulF64x4 := @RISCVVMulF64x4;
  table.DivF64x4 := @RISCVVDivF64x4;

  // F64x4 Comparison - ✅ Task 6.4: Added
  table.CmpEqF64x4 := @RISCVVCmpEqF64x4;
  table.CmpLtF64x4 := @RISCVVCmpLtF64x4;
  table.CmpLeF64x4 := @RISCVVCmpLeF64x4;
  table.CmpGtF64x4 := @RISCVVCmpGtF64x4;
  table.CmpGeF64x4 := @RISCVVCmpGeF64x4;
  table.CmpNeF64x4 := @RISCVVCmpNeF64x4;

  // === I32x8 Operations ===
  table.AddI32x8 := @RISCVVAddI32x8;
  table.SubI32x8 := @RISCVVSubI32x8;
  table.MulI32x8 := @RISCVVMulI32x8;
  table.AndI32x8 := @RISCVVAndI32x8;
  table.OrI32x8 := @RISCVVOrI32x8;
  table.XorI32x8 := @RISCVVXorI32x8;
  table.NotI32x8 := @RISCVVNotI32x8;
  table.AndNotI32x8 := @RISCVVAndNotI32x8;
  table.ShiftLeftI32x8 := @RISCVVShiftLeftI32x8;
  table.ShiftRightI32x8 := @RISCVVShiftRightI32x8;
  table.ShiftRightArithI32x8 := @RISCVVShiftRightArithI32x8;
  table.CmpEqI32x8 := @RISCVVCmpEqI32x8;
  table.CmpLtI32x8 := @RISCVVCmpLtI32x8;
  table.CmpGtI32x8 := @RISCVVCmpGtI32x8;
  table.CmpLeI32x8 := @RISCVVCmpLeI32x8;  // ✅ Task 6.4: Added
  table.CmpGeI32x8 := @RISCVVCmpGeI32x8;  // ✅ Task 6.4: Added
  table.CmpNeI32x8 := @RISCVVCmpNeI32x8;  // ✅ Task 6.4: Added
  table.MinI32x8 := @RISCVVMinI32x8;
  table.MaxI32x8 := @RISCVVMaxI32x8;

  // === I32x16 Operations ===
  table.AddI32x16 := @RISCVVAddI32x16;
  table.SubI32x16 := @RISCVVSubI32x16;
  table.MulI32x16 := @RISCVVMulI32x16;
  table.AndI32x16 := @RISCVVAndI32x16;
  table.OrI32x16 := @RISCVVOrI32x16;
  table.XorI32x16 := @RISCVVXorI32x16;
  table.NotI32x16 := @RISCVVNotI32x16;
  table.AndNotI32x16 := @RISCVVAndNotI32x16;
  table.ShiftLeftI32x16 := @RISCVVShiftLeftI32x16;
  table.ShiftRightI32x16 := @RISCVVShiftRightI32x16;
  table.ShiftRightArithI32x16 := @RISCVVShiftRightArithI32x16;
  table.CmpEqI32x16 := @RISCVVCmpEqI32x16;
  table.CmpLtI32x16 := @RISCVVCmpLtI32x16;
  table.CmpGtI32x16 := @RISCVVCmpGtI32x16;
  table.CmpLeI32x16 := @RISCVVCmpLeI32x16;  // ✅ Task 6.4: Added
  table.CmpGeI32x16 := @RISCVVCmpGeI32x16;  // ✅ Task 6.4: Added
  table.CmpNeI32x16 := @RISCVVCmpNeI32x16;  // ✅ Task 6.4: Added
  table.MinI32x16 := @RISCVVMinI32x16;
  table.MaxI32x16 := @RISCVVMaxI32x16;

  // === F32x16 Operations (512-bit, 16x Single) ===
  table.AddF32x16 := @RISCVVAddF32x16;
  table.SubF32x16 := @RISCVVSubF32x16;
  table.MulF32x16 := @RISCVVMulF32x16;
  table.DivF32x16 := @RISCVVDivF32x16;

  // F32x16 Comparison - ✅ Task 6.4: Added
  table.CmpEqF32x16 := @RISCVVCmpEqF32x16;
  table.CmpLtF32x16 := @RISCVVCmpLtF32x16;
  table.CmpLeF32x16 := @RISCVVCmpLeF32x16;
  table.CmpGtF32x16 := @RISCVVCmpGtF32x16;
  table.CmpGeF32x16 := @RISCVVCmpGeF32x16;
  table.CmpNeF32x16 := @RISCVVCmpNeF32x16;
  table.SelectF32x16 := @RISCVVSelectF32x16;

  // === F64x8 Operations (512-bit, 8x Double) ===
  table.AddF64x8 := @RISCVVAddF64x8;
  table.SubF64x8 := @RISCVVSubF64x8;
  table.MulF64x8 := @RISCVVMulF64x8;
  table.DivF64x8 := @RISCVVDivF64x8;

  // F64x8 Comparison - ✅ Task 6.4: Added
  table.CmpEqF64x8 := @RISCVVCmpEqF64x8;
  table.CmpLtF64x8 := @RISCVVCmpLtF64x8;
  table.CmpLeF64x8 := @RISCVVCmpLeF64x8;
  table.CmpGtF64x8 := @RISCVVCmpGtF64x8;
  table.CmpGeF64x8 := @RISCVVCmpGeF64x8;
  table.CmpNeF64x8 := @RISCVVCmpNeF64x8;
  table.SelectF64x8 := @RISCVVSelectF64x8;

  // === Mask Operations - ✅ Task 6.4: Added ===
  // TMask4 Operations
  table.Mask4All := @RISCVVMask4All;
  table.Mask4Any := @RISCVVMask4Any;
  table.Mask4None := @RISCVVMask4None;
  table.Mask4PopCount := @RISCVVMask4PopCount;
  table.Mask4FirstSet := @RISCVVMask4FirstSet;

  // TMask8 Operations
  table.Mask8All := @RISCVVMask8All;
  table.Mask8Any := @RISCVVMask8Any;
  table.Mask8None := @RISCVVMask8None;
  table.Mask8PopCount := @RISCVVMask8PopCount;
  table.Mask8FirstSet := @RISCVVMask8FirstSet;

  // TMask16 Operations
  table.Mask16All := @RISCVVMask16All;
  table.Mask16Any := @RISCVVMask16Any;
  table.Mask16None := @RISCVVMask16None;
  table.Mask16PopCount := @RISCVVMask16PopCount;
  table.Mask16FirstSet := @RISCVVMask16FirstSet;

  // =============================================================
  // Additional Operations Registration (100% Coverage)
  // =============================================================

  // TMask2 Operations
  table.Mask2All := @RISCVVMask2All;
  table.Mask2Any := @RISCVVMask2Any;
  table.Mask2None := @RISCVVMask2None;
  table.Mask2PopCount := @RISCVVMask2PopCount;
  table.Mask2FirstSet := @RISCVVMask2FirstSet;

  // Wide Float Operations (Abs, Sqrt, Min, Max, Clamp)
  table.AbsF32x16 := @RISCVVAbsF32x16;
  table.AbsF32x8 := @RISCVVAbsF32x8;
  table.AbsF64x2 := @RISCVVAbsF64x2;
  table.AbsF64x4 := @RISCVVAbsF64x4;
  table.AbsF64x8 := @RISCVVAbsF64x8;
  table.SqrtF32x16 := @RISCVVSqrtF32x16;
  table.SqrtF32x8 := @RISCVVSqrtF32x8;
  table.SqrtF64x2 := @RISCVVSqrtF64x2;
  table.SqrtF64x4 := @RISCVVSqrtF64x4;
  table.SqrtF64x8 := @RISCVVSqrtF64x8;
  table.MinF32x16 := @RISCVVMinF32x16;
  table.MinF32x8 := @RISCVVMinF32x8;
  table.MinF64x2 := @RISCVVMinF64x2;
  table.MinF64x4 := @RISCVVMinF64x4;
  table.MinF64x8 := @RISCVVMinF64x8;
  table.MaxF32x16 := @RISCVVMaxF32x16;
  table.MaxF32x8 := @RISCVVMaxF32x8;
  table.MaxF64x2 := @RISCVVMaxF64x2;
  table.MaxF64x4 := @RISCVVMaxF64x4;
  table.MaxF64x8 := @RISCVVMaxF64x8;
  table.ClampF32x16 := @RISCVVClampF32x16;
  table.ClampF32x8 := @RISCVVClampF32x8;
  table.ClampF64x2 := @RISCVVClampF64x2;
  table.ClampF64x4 := @RISCVVClampF64x4;
  table.ClampF64x8 := @RISCVVClampF64x8;

  // Wide Float Extended Math (Ceil, Floor, Round, Trunc, Fma)
  {$IFDEF RISCVV_ASSEMBLY}
  table.CeilF32x16 := @ScalarCeilF32x16;
  table.CeilF32x8 := @ScalarCeilF32x8;
  table.CeilF64x2 := @ScalarCeilF64x2;
  table.CeilF64x4 := @ScalarCeilF64x4;
  table.CeilF64x8 := @ScalarCeilF64x8;
  table.FloorF32x16 := @ScalarFloorF32x16;
  table.FloorF32x8 := @ScalarFloorF32x8;
  table.FloorF64x2 := @ScalarFloorF64x2;
  table.FloorF64x4 := @ScalarFloorF64x4;
  table.FloorF64x8 := @ScalarFloorF64x8;
  table.RoundF32x16 := @ScalarRoundF32x16;
  table.RoundF32x8 := @ScalarRoundF32x8;
  table.RoundF64x2 := @ScalarRoundF64x2;
  table.RoundF64x4 := @ScalarRoundF64x4;
  table.RoundF64x8 := @ScalarRoundF64x8;
  table.TruncF32x16 := @ScalarTruncF32x16;
  table.TruncF32x8 := @ScalarTruncF32x8;
  table.TruncF64x2 := @ScalarTruncF64x2;
  table.TruncF64x4 := @ScalarTruncF64x4;
  table.TruncF64x8 := @ScalarTruncF64x8;
  {$ELSE}
  table.CeilF32x16 := @RISCVVCeilF32x16;
  table.CeilF32x8 := @RISCVVCeilF32x8;
  table.CeilF64x2 := @RISCVVCeilF64x2;
  table.CeilF64x4 := @RISCVVCeilF64x4;
  table.CeilF64x8 := @RISCVVCeilF64x8;
  table.FloorF32x16 := @RISCVVFloorF32x16;
  table.FloorF32x8 := @RISCVVFloorF32x8;
  table.FloorF64x2 := @RISCVVFloorF64x2;
  table.FloorF64x4 := @RISCVVFloorF64x4;
  table.FloorF64x8 := @RISCVVFloorF64x8;
  table.RoundF32x16 := @RISCVVRoundF32x16;
  table.RoundF32x8 := @RISCVVRoundF32x8;
  table.RoundF64x2 := @RISCVVRoundF64x2;
  table.RoundF64x4 := @RISCVVRoundF64x4;
  table.RoundF64x8 := @RISCVVRoundF64x8;
  table.TruncF32x16 := @RISCVVTruncF32x16;
  table.TruncF32x8 := @RISCVVTruncF32x8;
  table.TruncF64x2 := @RISCVVTruncF64x2;
  table.TruncF64x4 := @RISCVVTruncF64x4;
  table.TruncF64x8 := @RISCVVTruncF64x8;
  {$ENDIF}
  table.FmaF32x16 := @RISCVVFmaF32x16;
  table.FmaF32x8 := @RISCVVFmaF32x8;
  table.FmaF64x2 := @RISCVVFmaF64x2;
  table.FmaF64x4 := @RISCVVFmaF64x4;
  table.FmaF64x8 := @RISCVVFmaF64x8;

  // Wide Float Reduction
  table.ReduceAddF32x16 := @RISCVVReduceAddF32x16;
  table.ReduceAddF32x8 := @RISCVVReduceAddF32x8;
  table.ReduceAddF64x2 := @RISCVVReduceAddF64x2;
  table.ReduceAddF64x4 := @RISCVVReduceAddF64x4;
  table.ReduceAddF64x8 := @RISCVVReduceAddF64x8;
  table.ReduceMaxF32x16 := @RISCVVReduceMaxF32x16;
  table.ReduceMaxF32x8 := @RISCVVReduceMaxF32x8;
  table.ReduceMaxF64x2 := @RISCVVReduceMaxF64x2;
  table.ReduceMaxF64x4 := @RISCVVReduceMaxF64x4;
  table.ReduceMaxF64x8 := @RISCVVReduceMaxF64x8;
  table.ReduceMinF32x16 := @RISCVVReduceMinF32x16;
  table.ReduceMinF32x8 := @RISCVVReduceMinF32x8;
  table.ReduceMinF64x2 := @RISCVVReduceMinF64x2;
  table.ReduceMinF64x4 := @RISCVVReduceMinF64x4;
  table.ReduceMinF64x8 := @RISCVVReduceMinF64x8;
  table.ReduceMulF32x16 := @RISCVVReduceMulF32x16;
  table.ReduceMulF32x8 := @RISCVVReduceMulF32x8;
  table.ReduceMulF64x2 := @RISCVVReduceMulF64x2;
  table.ReduceMulF64x4 := @RISCVVReduceMulF64x4;
  table.ReduceMulF64x8 := @RISCVVReduceMulF64x8;

  // F64x2 Comparison
  table.CmpEqF64x2 := @RISCVVCmpEqF64x2;
  table.CmpLtF64x2 := @RISCVVCmpLtF64x2;
  table.CmpLeF64x2 := @RISCVVCmpLeF64x2;
  table.CmpGtF64x2 := @RISCVVCmpGtF64x2;
  table.CmpGeF64x2 := @RISCVVCmpGeF64x2;
  table.CmpNeF64x2 := @RISCVVCmpNeF64x2;

  // Wide Float Memory/Utility
  table.LoadF32x16 := @RISCVVLoadF32x16;
  table.LoadF32x8 := @RISCVVLoadF32x8;
  table.LoadF64x2 := @RISCVVLoadF64x2;
  table.LoadF64x4 := @RISCVVLoadF64x4;
  table.LoadF64x8 := @RISCVVLoadF64x8;
  table.StoreF32x16 := @RISCVVStoreF32x16;
  table.StoreF32x8 := @RISCVVStoreF32x8;
  table.StoreF64x2 := @RISCVVStoreF64x2;
  table.StoreF64x4 := @RISCVVStoreF64x4;
  table.StoreF64x8 := @RISCVVStoreF64x8;
  table.SplatF32x16 := @RISCVVSplatF32x16;
  table.SplatF32x8 := @RISCVVSplatF32x8;
  table.SplatF64x2 := @RISCVVSplatF64x2;
  table.SplatF64x4 := @RISCVVSplatF64x4;
  table.SplatF64x8 := @RISCVVSplatF64x8;
  table.ZeroF32x16 := @RISCVVZeroF32x16;
  table.ZeroF32x8 := @RISCVVZeroF32x8;
  table.ZeroF64x2 := @RISCVVZeroF64x2;
  table.ZeroF64x4 := @RISCVVZeroF64x4;
  table.ZeroF64x8 := @RISCVVZeroF64x8;

  // Wide Float Extract/Insert
  table.ExtractF32x16 := @RISCVVExtractF32x16;
  table.ExtractF32x8 := @RISCVVExtractF32x8;
  table.ExtractF64x2 := @RISCVVExtractF64x2;
  table.ExtractF64x4 := @RISCVVExtractF64x4;
  table.InsertF32x16 := @RISCVVInsertF32x16;
  table.InsertF32x8 := @RISCVVInsertF32x8;
  table.InsertF64x2 := @RISCVVInsertF64x2;
  table.InsertF64x4 := @RISCVVInsertF64x4;

  // Wide Float Select
  table.SelectF32x8 := @RISCVVSelectF32x8;
  table.SelectF64x2 := @RISCVVSelectF64x2;
  table.SelectF64x4 := @RISCVVSelectF64x4;
  table.SelectI32x4 := @RISCVVSelectI32x4;

  // I64x2 Comparison
  table.CmpEqI64x2 := @RISCVVCmpEqI64x2;
  table.CmpLtI64x2 := @RISCVVCmpLtI64x2;
  table.CmpLeI64x2 := @RISCVVCmpLeI64x2;
  table.CmpGtI64x2 := @RISCVVCmpGtI64x2;
  table.CmpGeI64x2 := @RISCVVCmpGeI64x2;
  table.CmpNeI64x2 := @RISCVVCmpNeI64x2;

  // I64x4 Operations
  table.AddI64x4 := @RISCVVAddI64x4;
  table.SubI64x4 := @RISCVVSubI64x4;
  table.AndI64x4 := @RISCVVAndI64x4;
  table.OrI64x4 := @RISCVVOrI64x4;
  table.XorI64x4 := @RISCVVXorI64x4;
  table.NotI64x4 := @RISCVVNotI64x4;
  table.AndNotI64x4 := @RISCVVAndNotI64x4;
  table.ShiftLeftI64x4 := @RISCVVShiftLeftI64x4;
  table.ShiftRightI64x4 := @RISCVVShiftRightI64x4;
  table.ShiftRightArithI64x4 := @RISCVVShiftRightArithI64x4;
  table.CmpEqI64x4 := @RISCVVCmpEqI64x4;
  table.CmpLtI64x4 := @RISCVVCmpLtI64x4;
  table.CmpLeI64x4 := @RISCVVCmpLeI64x4;
  table.CmpGtI64x4 := @RISCVVCmpGtI64x4;
  table.CmpGeI64x4 := @RISCVVCmpGeI64x4;
  table.CmpNeI64x4 := @RISCVVCmpNeI64x4;
  table.LoadI64x4 := @RISCVVLoadI64x4;
  table.StoreI64x4 := @RISCVVStoreI64x4;
  table.SplatI64x4 := @RISCVVSplatI64x4;
  table.ZeroI64x4 := @RISCVVZeroI64x4;
  table.ExtractI64x4 := @RISCVVExtractI64x4;
  table.InsertI64x4 := @RISCVVInsertI64x4;

  // I64x8 Operations
  table.AddI64x8 := @RISCVVAddI64x8;
  table.SubI64x8 := @RISCVVSubI64x8;
  table.AndI64x8 := @RISCVVAndI64x8;
  table.OrI64x8 := @RISCVVOrI64x8;
  table.XorI64x8 := @RISCVVXorI64x8;
  table.NotI64x8 := @RISCVVNotI64x8;
  table.CmpEqI64x8 := @RISCVVCmpEqI64x8;
  table.CmpLtI64x8 := @RISCVVCmpLtI64x8;
  table.CmpLeI64x8 := @RISCVVCmpLeI64x8;
  table.CmpGtI64x8 := @RISCVVCmpGtI64x8;
  table.CmpGeI64x8 := @RISCVVCmpGeI64x8;
  table.CmpNeI64x8 := @RISCVVCmpNeI64x8;

  // I16x32 Operations
  table.AddI16x32 := @RISCVVAddI16x32;
  table.AddI8x64 := @RISCVVAddI8x64;
  table.SubI16x32 := @RISCVVSubI16x32;
  table.SubI8x64 := @RISCVVSubI8x64;
  table.AndI16x32 := @RISCVVAndI16x32;
  table.AndI8x64 := @RISCVVAndI8x64;
  table.OrI16x32 := @RISCVVOrI16x32;
  table.OrI8x64 := @RISCVVOrI8x64;
  table.XorI16x32 := @RISCVVXorI16x32;
  table.XorI8x64 := @RISCVVXorI8x64;
  table.NotI16x32 := @RISCVVNotI16x32;
  table.NotI8x64 := @RISCVVNotI8x64;
  table.AndNotI16x32 := @RISCVVAndNotI16x32;
  table.AndNotI8x64 := @RISCVVAndNotI8x64;
  table.CmpEqI16x32 := @RISCVVCmpEqI16x32;
  table.CmpEqI8x64 := @RISCVVCmpEqI8x64;
  table.CmpLtI16x32 := @RISCVVCmpLtI16x32;
  table.CmpLtI8x64 := @RISCVVCmpLtI8x64;
  table.CmpGtI16x32 := @RISCVVCmpGtI16x32;
  table.CmpGtI8x64 := @RISCVVCmpGtI8x64;
  table.MinI16x32 := @RISCVVMinI16x32;
  table.MinI8x64 := @RISCVVMinI8x64;
  table.MaxI16x32 := @RISCVVMaxI16x32;
  table.MaxI8x64 := @RISCVVMaxI8x64;
  table.ShiftLeftI16x32 := @RISCVVShiftLeftI16x32;
  table.ShiftRightI16x32 := @RISCVVShiftRightI16x32;
  table.ShiftRightArithI16x32 := @RISCVVShiftRightArithI16x32;
  table.AddU8x64 := @RISCVVAddU8x64;
  table.SubU8x64 := @RISCVVSubU8x64;
  table.AndU8x64 := @RISCVVAndU8x64;
  table.OrU8x64 := @RISCVVOrU8x64;
  table.XorU8x64 := @RISCVVXorU8x64;
  table.NotU8x64 := @RISCVVNotU8x64;
  table.CmpEqU8x64 := @RISCVVCmpEqU8x64;
  table.CmpLtU8x64 := @RISCVVCmpLtU8x64;
  table.CmpGtU8x64 := @RISCVVCmpGtU8x64;
  table.MinU8x64 := @RISCVVMinU8x64;
  table.MaxU8x64 := @RISCVVMaxU8x64;
  table.AddU32x16 := @RISCVVAddU32x16;
  table.SubU32x16 := @RISCVVSubU32x16;
  table.MulU32x16 := @RISCVVMulU32x16;
  table.AndU32x16 := @RISCVVAndU32x16;
  table.OrU32x16 := @RISCVVOrU32x16;
  table.XorU32x16 := @RISCVVXorU32x16;
  table.NotU32x16 := @RISCVVNotU32x16;
  table.AndNotU32x16 := @RISCVVAndNotU32x16;
  table.ShiftLeftU32x16 := @RISCVVShiftLeftU32x16;
  table.ShiftRightU32x16 := @RISCVVShiftRightU32x16;
  table.CmpEqU32x16 := @RISCVVCmpEqU32x16;
  table.CmpLtU32x16 := @RISCVVCmpLtU32x16;
  table.CmpGtU32x16 := @RISCVVCmpGtU32x16;
  table.CmpLeU32x16 := @RISCVVCmpLeU32x16;
  table.CmpGeU32x16 := @RISCVVCmpGeU32x16;
  table.CmpNeU32x16 := @RISCVVCmpNeU32x16;
  table.MinU32x16 := @RISCVVMinU32x16;
  table.MaxU32x16 := @RISCVVMaxU32x16;
  table.AddU64x8 := @RISCVVAddU64x8;
  table.SubU64x8 := @RISCVVSubU64x8;
  table.AndU64x8 := @RISCVVAndU64x8;
  table.OrU64x8 := @RISCVVOrU64x8;
  table.XorU64x8 := @RISCVVXorU64x8;
  table.NotU64x8 := @RISCVVNotU64x8;
  table.ShiftLeftU64x8 := @RISCVVShiftLeftU64x8;
  table.ShiftRightU64x8 := @RISCVVShiftRightU64x8;
  table.CmpEqU64x8 := @RISCVVCmpEqU64x8;
  table.CmpLtU64x8 := @RISCVVCmpLtU64x8;
  table.CmpGtU64x8 := @RISCVVCmpGtU64x8;
  table.CmpLeU64x8 := @RISCVVCmpLeU64x8;
  table.CmpGeU64x8 := @RISCVVCmpGeU64x8;
  table.CmpNeU64x8 := @RISCVVCmpNeU64x8;

  // I32x4/I32x8/I32x16 Extract/Insert
  table.ExtractI32x4 := @RISCVVExtractI32x4;
  table.InsertI32x4 := @RISCVVInsertI32x4;
  table.ExtractI32x8 := @RISCVVExtractI32x8;
  table.InsertI32x8 := @RISCVVInsertI32x8;
  table.ExtractI32x16 := @RISCVVExtractI32x16;
  table.InsertI32x16 := @RISCVVInsertI32x16;
  table.ExtractI64x2 := @RISCVVExtractI64x2;
  table.InsertI64x2 := @RISCVVInsertI64x2;

  // Narrow Integer Types: I16x8
  table.AddI16x8 := @RISCVVAddI16x8;
  table.SubI16x8 := @RISCVVSubI16x8;
  table.MulI16x8 := @RISCVVMulI16x8;
  table.AndI16x8 := @RISCVVAndI16x8;
  table.OrI16x8 := @RISCVVOrI16x8;
  table.XorI16x8 := @RISCVVXorI16x8;
  table.NotI16x8 := @RISCVVNotI16x8;
  table.AndNotI16x8 := @RISCVVAndNotI16x8;
  table.ShiftLeftI16x8 := @RISCVVShiftLeftI16x8;
  table.ShiftRightI16x8 := @RISCVVShiftRightI16x8;
  table.ShiftRightArithI16x8 := @RISCVVShiftRightArithI16x8;
  table.CmpEqI16x8 := @RISCVVCmpEqI16x8;
  table.CmpLtI16x8 := @RISCVVCmpLtI16x8;
  table.CmpLeI16x8 := @RISCVVCmpLeI16x8;
  table.CmpGtI16x8 := @RISCVVCmpGtI16x8;
  table.CmpGeI16x8 := @RISCVVCmpGeI16x8;
  table.CmpNeI16x8 := @RISCVVCmpNeI16x8;
  table.MinI16x8 := @RISCVVMinI16x8;
  table.MaxI16x8 := @RISCVVMaxI16x8;

  // Narrow Integer Types: I8x16
  table.AddI8x16 := @RISCVVAddI8x16;
  table.SubI8x16 := @RISCVVSubI8x16;
  table.AndI8x16 := @RISCVVAndI8x16;
  table.OrI8x16 := @RISCVVOrI8x16;
  table.XorI8x16 := @RISCVVXorI8x16;
  table.NotI8x16 := @RISCVVNotI8x16;
  table.AndNotI8x16 := @RISCVVAndNotI8x16;
  table.CmpEqI8x16 := @RISCVVCmpEqI8x16;
  table.CmpLtI8x16 := @RISCVVCmpLtI8x16;
  table.CmpLeI8x16 := @RISCVVCmpLeI8x16;
  table.CmpGtI8x16 := @RISCVVCmpGtI8x16;
  table.CmpGeI8x16 := @RISCVVCmpGeI8x16;
  table.CmpNeI8x16 := @RISCVVCmpNeI8x16;
  table.MinI8x16 := @RISCVVMinI8x16;
  table.MaxI8x16 := @RISCVVMaxI8x16;

  // Unsigned Integer Types: U32x4
  table.AddU32x4 := @RISCVVAddU32x4;
  table.SubU32x4 := @RISCVVSubU32x4;
  table.MulU32x4 := @RISCVVMulU32x4;
  table.AndU32x4 := @RISCVVAndU32x4;
  table.OrU32x4 := @RISCVVOrU32x4;
  table.XorU32x4 := @RISCVVXorU32x4;
  table.NotU32x4 := @RISCVVNotU32x4;
  table.AndNotU32x4 := @RISCVVAndNotU32x4;
  table.ShiftLeftU32x4 := @RISCVVShiftLeftU32x4;
  table.ShiftRightU32x4 := @RISCVVShiftRightU32x4;
  table.CmpEqU32x4 := @RISCVVCmpEqU32x4;
  table.CmpLtU32x4 := @RISCVVCmpLtU32x4;
  table.CmpLeU32x4 := @RISCVVCmpLeU32x4;
  table.CmpGtU32x4 := @RISCVVCmpGtU32x4;
  table.CmpGeU32x4 := @RISCVVCmpGeU32x4;
  table.MinU32x4 := @RISCVVMinU32x4;
  table.MaxU32x4 := @RISCVVMaxU32x4;

  // Unsigned Integer Types: U64x4
  table.AddU64x4 := @RISCVVAddU64x4;
  table.SubU64x4 := @RISCVVSubU64x4;
  table.AndU64x4 := @RISCVVAndU64x4;
  table.OrU64x4 := @RISCVVOrU64x4;
  table.XorU64x4 := @RISCVVXorU64x4;
  table.NotU64x4 := @RISCVVNotU64x4;
  table.ShiftLeftU64x4 := @RISCVVShiftLeftU64x4;
  table.ShiftRightU64x4 := @RISCVVShiftRightU64x4;
  table.CmpEqU64x4 := @RISCVVCmpEqU64x4;
  table.CmpLtU64x4 := @RISCVVCmpLtU64x4;
  table.CmpLeU64x4 := @RISCVVCmpLeU64x4;
  table.CmpGtU64x4 := @RISCVVCmpGtU64x4;
  table.CmpGeU64x4 := @RISCVVCmpGeU64x4;
  table.CmpNeU64x4 := @RISCVVCmpNeU64x4;

  // ✅ Unsigned Integer Types: U32x8 (256-bit)
  table.AddU32x8 := @RISCVVAddU32x8;
  table.SubU32x8 := @RISCVVSubU32x8;
  table.MulU32x8 := @RISCVVMulU32x8;
  table.AndU32x8 := @RISCVVAndU32x8;
  table.OrU32x8 := @RISCVVOrU32x8;
  table.XorU32x8 := @RISCVVXorU32x8;
  table.NotU32x8 := @RISCVVNotU32x8;
  table.AndNotU32x8 := @RISCVVAndNotU32x8;
  table.ShiftLeftU32x8 := @RISCVVShiftLeftU32x8;
  table.ShiftRightU32x8 := @RISCVVShiftRightU32x8;
  table.CmpEqU32x8 := @RISCVVCmpEqU32x8;
  table.CmpLtU32x8 := @RISCVVCmpLtU32x8;
  table.CmpLeU32x8 := @RISCVVCmpLeU32x8;
  table.CmpGtU32x8 := @RISCVVCmpGtU32x8;
  table.CmpGeU32x8 := @RISCVVCmpGeU32x8;
  table.CmpNeU32x8 := @RISCVVCmpNeU32x8;
  table.MinU32x8 := @RISCVVMinU32x8;
  table.MaxU32x8 := @RISCVVMaxU32x8;

  // ✅ RcpF64x4 (Reciprocal)
  table.RcpF64x4 := @RISCVVRcpF64x4;

  // Unsigned Integer Types: U16x8
  table.AddU16x8 := @RISCVVAddU16x8;
  table.SubU16x8 := @RISCVVSubU16x8;
  table.MulU16x8 := @RISCVVMulU16x8;
  table.AndU16x8 := @RISCVVAndU16x8;
  table.OrU16x8 := @RISCVVOrU16x8;
  table.XorU16x8 := @RISCVVXorU16x8;
  table.NotU16x8 := @RISCVVNotU16x8;
  table.AndNotU16x8 := @RISCVVAndNotU16x8;
  table.ShiftLeftU16x8 := @RISCVVShiftLeftU16x8;
  table.ShiftRightU16x8 := @RISCVVShiftRightU16x8;
  table.CmpEqU16x8 := @RISCVVCmpEqU16x8;
  table.CmpLtU16x8 := @RISCVVCmpLtU16x8;
  table.CmpLeU16x8 := @RISCVVCmpLeU16x8;
  table.CmpGtU16x8 := @RISCVVCmpGtU16x8;
  table.CmpGeU16x8 := @RISCVVCmpGeU16x8;
  table.CmpNeU16x8 := @RISCVVCmpNeU16x8;
  table.MinU16x8 := @RISCVVMinU16x8;
  table.MaxU16x8 := @RISCVVMaxU16x8;

  // Unsigned Integer Types: U8x16
  table.AddU8x16 := @RISCVVAddU8x16;
  table.SubU8x16 := @RISCVVSubU8x16;
  table.AndU8x16 := @RISCVVAndU8x16;
  table.OrU8x16 := @RISCVVOrU8x16;
  table.XorU8x16 := @RISCVVXorU8x16;
  table.NotU8x16 := @RISCVVNotU8x16;
  table.AndNotU8x16 := @RISCVVAndNotU8x16;
  table.CmpEqU8x16 := @RISCVVCmpEqU8x16;
  table.CmpLtU8x16 := @RISCVVCmpLtU8x16;
  table.CmpLeU8x16 := @RISCVVCmpLeU8x16;
  table.CmpGtU8x16 := @RISCVVCmpGtU8x16;
  table.CmpGeU8x16 := @RISCVVCmpGeU8x16;
  table.CmpNeU8x16 := @RISCVVCmpNeU8x16;
  table.MinU8x16 := @RISCVVMinU8x16;
  table.MaxU8x16 := @RISCVVMaxU8x16;

  // Saturating Arithmetic
  table.I8x16SatAdd := @RISCVVSatAddI8x16;
  table.I8x16SatSub := @RISCVVSatSubI8x16;
  table.I16x8SatAdd := @RISCVVSatAddI16x8;
  table.I16x8SatSub := @RISCVVSatSubI16x8;
  table.U8x16SatAdd := @RISCVVSatAddU8x16;
  table.U8x16SatSub := @RISCVVSatSubU8x16;
  table.U16x8SatAdd := @RISCVVSatAddU16x8;
  table.U16x8SatSub := @RISCVVSatSubU16x8;

  // === Facade Functions ===
  table.MemEqual := @MemEqual_RISCVV;
  table.MemFindByte := @MemFindByte_RISCVV;
  table.MemDiffRange := @MemDiffRange_RISCVV;
  table.MemCopy := @MemCopy_RISCVV;
  table.MemSet := @MemSet_RISCVV;
  table.MemReverse := @MemReverse_RISCVV;
  table.SumBytes := @SumBytes_RISCVV;
  table.MinMaxBytes := @MinMaxBytes_RISCVV;
  table.CountByte := @CountByte_RISCVV;
  table.Utf8Validate := @Utf8Validate_RISCVV;
  table.AsciiIEqual := @AsciiIEqual_RISCVV;
  table.ToLowerAscii := @ToLowerAscii_RISCVV;
  table.ToUpperAscii := @ToUpperAscii_RISCVV;
  table.BytesIndexOf := @BytesIndexOf_RISCVV;
  table.BitsetPopCount := @BitsetPopCount_RISCVV;

  // Register the backend
  RegisterBackend(sbRISCVV, table);
end;

// =============================================================
// Initialization
// =============================================================
// Auto-register on RISC-V platforms with V extension

initialization
  {$IFDEF FAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND}
  // Test-only opt-in path: allow non-native hosts to register RVV scalar/common
  // implementations so DispatchAPI/PublicAbi suites can verify metadata contracts.
  RegisterRISCVVBackend;
  RegisterBackendRebuilder(sbRISCVV, @RegisterRISCVVBackend);
  {$ELSE}
  {$IFDEF CPURISCV64}
  // On RISC-V 64-bit, attempt to register
  // In practice, runtime detection of V extension would be needed
  RegisterRISCVVBackend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbRISCVV, @RegisterRISCVVBackend);
  {$ENDIF}
  {$IFDEF CPURISCV32}
  RegisterRISCVVBackend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbRISCVV, @RegisterRISCVVBackend);
  {$ENDIF}
  {$ENDIF}

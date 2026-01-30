unit fafafa.core.simd.backend.adapter;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.backend.iface,
  fafafa.core.simd.dispatch;

// =============================================================================
// SIMD Backend Adapter
// =============================================================================
//
// Purpose:
//   Provides bidirectional conversion between:
//   - Legacy TSimdDispatchTable (flat, 100+ fields)
//   - New TSimdBackendOps (hierarchical, grouped)
//
// Migration Strategy:
//   1. Existing backends continue using TSimdDispatchTable (no changes needed)
//   2. New backends can implement TSimdBackendOps (cleaner)
//   3. Adapter converts between them transparently
//   4. Gradual migration: convert one backend at a time
//
// This allows parallel development without breaking existing code!
//
// =============================================================================

// Convert new TSimdBackendOps to legacy TSimdDispatchTable
// Use this when registering a backend implemented with new interface
procedure BackendOpsToDispatchTable(const ops: TSimdBackendOps; out table: TSimdDispatchTable);

// Convert legacy TSimdDispatchTable to new TSimdBackendOps
// Use this to access legacy backends via new interface
procedure DispatchTableToBackendOps(const table: TSimdDispatchTable; out ops: TSimdBackendOps);

// Register a backend using the new TSimdBackendOps interface
// Internally converts to TSimdDispatchTable for compatibility
procedure RegisterBackendOps(backend: TSimdBackend; const ops: TSimdBackendOps);

// Get backend operations in new format (converts from internal dispatch table)
function GetBackendOps(backend: TSimdBackend): TSimdBackendOps;

// Check if a backend is registered (wrapper for compatibility)
function IsBackendOpsRegistered(backend: TSimdBackend): Boolean;

// Fill TSimdBackendOps with scalar implementations (complete version)
// This is the authoritative source for scalar function assignments
procedure FillScalarOps(var ops: TSimdBackendOps);

implementation

uses
  fafafa.core.simd.scalar;

procedure BackendOpsToDispatchTable(const ops: TSimdBackendOps; out table: TSimdDispatchTable);
begin
  // Initialize to zeros
  FillChar(table, SizeOf(TSimdDispatchTable), 0);

  // Copy backend info
  table.Backend := ops.Backend;
  table.BackendInfo := ops.BackendInfo;

  // === F32x4 Arithmetic ===
  table.AddF32x4 := ops.ArithmeticF32x4.Add;
  table.SubF32x4 := ops.ArithmeticF32x4.Sub;
  table.MulF32x4 := ops.ArithmeticF32x4.Mul;
  table.DivF32x4 := ops.ArithmeticF32x4.OpDiv;

  // === F32x8 Arithmetic ===
  table.AddF32x8 := ops.ArithmeticF32x8.Add;
  table.SubF32x8 := ops.ArithmeticF32x8.Sub;
  table.MulF32x8 := ops.ArithmeticF32x8.Mul;
  table.DivF32x8 := ops.ArithmeticF32x8.OpDiv;

  // === F64x2 Arithmetic ===
  table.AddF64x2 := ops.ArithmeticF64x2.Add;
  table.SubF64x2 := ops.ArithmeticF64x2.Sub;
  table.MulF64x2 := ops.ArithmeticF64x2.Mul;
  table.DivF64x2 := ops.ArithmeticF64x2.OpDiv;

  // === F64x4 Arithmetic ===
  table.AddF64x4 := ops.ArithmeticF64x4.Add;
  table.SubF64x4 := ops.ArithmeticF64x4.Sub;
  table.MulF64x4 := ops.ArithmeticF64x4.Mul;
  table.DivF64x4 := ops.ArithmeticF64x4.OpDiv;

  // === I32x4 Arithmetic ===
  table.AddI32x4 := ops.ArithmeticI32x4.Add;
  table.SubI32x4 := ops.ArithmeticI32x4.Sub;
  table.MulI32x4 := ops.ArithmeticI32x4.Mul;

  // === I32x4 Bitwise ===
  table.AndI32x4 := ops.BitwiseI32x4.OpAnd;
  table.OrI32x4 := ops.BitwiseI32x4.OpOr;
  table.XorI32x4 := ops.BitwiseI32x4.OpXor;
  table.NotI32x4 := ops.BitwiseI32x4.OpNot;
  table.AndNotI32x4 := ops.BitwiseI32x4.AndNot;

  // === I32x4 Shift ===
  table.ShiftLeftI32x4 := ops.ShiftI32x4.ShiftLeft;
  table.ShiftRightI32x4 := ops.ShiftI32x4.ShiftRight;
  table.ShiftRightArithI32x4 := ops.ShiftI32x4.ShiftRightArith;

  // === I32x4 Comparison ===
  table.CmpEqI32x4 := ops.ComparisonI32x4.CmpEq;
  table.CmpLtI32x4 := ops.ComparisonI32x4.CmpLt;
  table.CmpGtI32x4 := ops.ComparisonI32x4.CmpGt;

  // === I32x4 MinMax ===
  table.MinI32x4 := ops.MinMaxI32x4.Min;
  table.MaxI32x4 := ops.MinMaxI32x4.Max;

  // === I64x2 Arithmetic ===
  table.AddI64x2 := ops.ArithmeticI64x2.Add;
  table.SubI64x2 := ops.ArithmeticI64x2.Sub;

  // === I64x2 Bitwise ===
  table.AndI64x2 := ops.BitwiseI64x2.OpAnd;
  table.OrI64x2 := ops.BitwiseI64x2.OpOr;
  table.XorI64x2 := ops.BitwiseI64x2.OpXor;
  table.NotI64x2 := ops.BitwiseI64x2.OpNot;

  // === I32x8 Arithmetic ===
  table.AddI32x8 := ops.ArithmeticI32x8.Add;
  table.SubI32x8 := ops.ArithmeticI32x8.Sub;
  table.MulI32x8 := ops.ArithmeticI32x8.Mul;

  // === I32x8 Bitwise ===
  table.AndI32x8 := ops.BitwiseI32x8.OpAnd;
  table.OrI32x8 := ops.BitwiseI32x8.OpOr;
  table.XorI32x8 := ops.BitwiseI32x8.OpXor;
  table.NotI32x8 := ops.BitwiseI32x8.OpNot;
  table.AndNotI32x8 := ops.BitwiseI32x8.AndNot;

  // === I32x8 Shift ===
  table.ShiftLeftI32x8 := ops.ShiftI32x8.ShiftLeft;
  table.ShiftRightI32x8 := ops.ShiftI32x8.ShiftRight;
  table.ShiftRightArithI32x8 := ops.ShiftI32x8.ShiftRightArith;

  // === I32x8 Comparison ===
  table.CmpEqI32x8 := ops.ComparisonI32x8.CmpEq;
  table.CmpLtI32x8 := ops.ComparisonI32x8.CmpLt;
  table.CmpGtI32x8 := ops.ComparisonI32x8.CmpGt;

  // === I32x8 MinMax ===
  table.MinI32x8 := ops.MinMaxI32x8.Min;
  table.MaxI32x8 := ops.MinMaxI32x8.Max;

  // === 512-bit F32x16 ===
  table.AddF32x16 := ops.ArithmeticF32x16.Add;
  table.SubF32x16 := ops.ArithmeticF32x16.Sub;
  table.MulF32x16 := ops.ArithmeticF32x16.Mul;
  table.DivF32x16 := ops.ArithmeticF32x16.OpDiv;

  // === 512-bit F64x8 ===
  table.AddF64x8 := ops.ArithmeticF64x8.Add;
  table.SubF64x8 := ops.ArithmeticF64x8.Sub;
  table.MulF64x8 := ops.ArithmeticF64x8.Mul;
  table.DivF64x8 := ops.ArithmeticF64x8.OpDiv;

  // === 512-bit I32x16 Arithmetic ===
  table.AddI32x16 := ops.ArithmeticI32x16.Add;
  table.SubI32x16 := ops.ArithmeticI32x16.Sub;
  table.MulI32x16 := ops.ArithmeticI32x16.Mul;

  // === 512-bit I32x16 Bitwise ===
  table.AndI32x16 := ops.BitwiseI32x16.OpAnd;
  table.OrI32x16 := ops.BitwiseI32x16.OpOr;
  table.XorI32x16 := ops.BitwiseI32x16.OpXor;
  table.NotI32x16 := ops.BitwiseI32x16.OpNot;
  table.AndNotI32x16 := ops.BitwiseI32x16.AndNot;

  // === 512-bit I32x16 Shift ===
  table.ShiftLeftI32x16 := ops.ShiftI32x16.ShiftLeft;
  table.ShiftRightI32x16 := ops.ShiftI32x16.ShiftRight;
  table.ShiftRightArithI32x16 := ops.ShiftI32x16.ShiftRightArith;

  // === 512-bit I32x16 Comparison ===
  table.CmpEqI32x16 := ops.ComparisonI32x16.CmpEq;
  table.CmpLtI32x16 := ops.ComparisonI32x16.CmpLt;
  table.CmpGtI32x16 := ops.ComparisonI32x16.CmpGt;

  // === 512-bit I32x16 MinMax ===
  table.MinI32x16 := ops.MinMaxI32x16.Min;
  table.MaxI32x16 := ops.MinMaxI32x16.Max;

  // === F32x4 Comparison ===
  table.CmpEqF32x4 := ops.ComparisonF32x4.CmpEq;
  table.CmpLtF32x4 := ops.ComparisonF32x4.CmpLt;
  table.CmpLeF32x4 := ops.ComparisonF32x4.CmpLe;
  table.CmpGtF32x4 := ops.ComparisonF32x4.CmpGt;
  table.CmpGeF32x4 := ops.ComparisonF32x4.CmpGe;
  table.CmpNeF32x4 := ops.ComparisonF32x4.CmpNe;

  // === F32x4 Math ===
  table.AbsF32x4 := ops.MathF32x4.Abs;
  table.SqrtF32x4 := ops.MathF32x4.Sqrt;
  table.MinF32x4 := ops.MathF32x4.Min;
  table.MaxF32x4 := ops.MathF32x4.Max;
  table.FmaF32x4 := ops.MathF32x4.Fma;
  table.RcpF32x4 := ops.MathF32x4.Rcp;
  table.RsqrtF32x4 := ops.MathF32x4.Rsqrt;
  table.FloorF32x4 := ops.MathF32x4.Floor;
  table.CeilF32x4 := ops.MathF32x4.Ceil;
  table.RoundF32x4 := ops.MathF32x4.Round;
  table.TruncF32x4 := ops.MathF32x4.Trunc;
  table.ClampF32x4 := ops.MathF32x4.Clamp;

  // === F32x4 Vector Math ===
  table.DotF32x4 := ops.VectorMathF32x4.Dot4;
  table.DotF32x3 := ops.VectorMathF32x4.Dot3;
  table.CrossF32x3 := ops.VectorMathF32x4.Cross3;
  table.LengthF32x4 := ops.VectorMathF32x4.Length4;
  table.LengthF32x3 := ops.VectorMathF32x4.Length3;
  table.NormalizeF32x4 := ops.VectorMathF32x4.Normalize4;
  table.NormalizeF32x3 := ops.VectorMathF32x4.Normalize3;

  // === F32x4 Reduction ===
  table.ReduceAddF32x4 := ops.ReductionF32x4.ReduceAdd;
  table.ReduceMinF32x4 := ops.ReductionF32x4.ReduceMin;
  table.ReduceMaxF32x4 := ops.ReductionF32x4.ReduceMax;
  table.ReduceMulF32x4 := ops.ReductionF32x4.ReduceMul;

  // === F32x4 Memory ===
  table.LoadF32x4 := ops.MemoryF32x4.Load;
  table.LoadF32x4Aligned := ops.MemoryF32x4.LoadAligned;
  table.StoreF32x4 := ops.MemoryF32x4.Store;
  table.StoreF32x4Aligned := ops.MemoryF32x4.StoreAligned;
  table.SplatF32x4 := ops.MemoryF32x4.Splat;
  table.ZeroF32x4 := ops.MemoryF32x4.Zero;
  table.SelectF32x4 := ops.MemoryF32x4.Select;
  table.ExtractF32x4 := ops.MemoryF32x4.Extract;
  table.InsertF32x4 := ops.MemoryF32x4.Insert;

  // === Facade Operations ===
  table.MemEqual := ops.Facade.MemEqual;
  table.MemFindByte := ops.Facade.MemFindByte;
  table.MemDiffRange := ops.Facade.MemDiffRange;
  table.MemCopy := ops.Facade.MemCopy;
  table.MemSet := ops.Facade.MemSet;
  table.MemReverse := ops.Facade.MemReverse;
  table.SumBytes := ops.Facade.SumBytes;
  table.MinMaxBytes := ops.Facade.MinMaxBytes;
  table.CountByte := ops.Facade.CountByte;
  table.Utf8Validate := ops.Facade.Utf8Validate;
  table.AsciiIEqual := ops.Facade.AsciiIEqual;
  table.ToLowerAscii := ops.Facade.ToLowerAscii;
  table.ToUpperAscii := ops.Facade.ToUpperAscii;
  table.BytesIndexOf := ops.Facade.BytesIndexOf;
  table.BitsetPopCount := ops.Facade.BitsetPopCount;
end;

procedure DispatchTableToBackendOps(const table: TSimdDispatchTable; out ops: TSimdBackendOps);
begin
  // Initialize to zeros
  FillChar(ops, SizeOf(TSimdBackendOps), 0);

  // Copy backend info
  ops.Backend := table.Backend;
  ops.BackendInfo := table.BackendInfo;

  // === F32x4 Arithmetic ===
  ops.ArithmeticF32x4.Add := table.AddF32x4;
  ops.ArithmeticF32x4.Sub := table.SubF32x4;
  ops.ArithmeticF32x4.Mul := table.MulF32x4;
  ops.ArithmeticF32x4.OpDiv := table.DivF32x4;

  // === F32x8 Arithmetic ===
  ops.ArithmeticF32x8.Add := table.AddF32x8;
  ops.ArithmeticF32x8.Sub := table.SubF32x8;
  ops.ArithmeticF32x8.Mul := table.MulF32x8;
  ops.ArithmeticF32x8.OpDiv := table.DivF32x8;

  // === F64x2 Arithmetic ===
  ops.ArithmeticF64x2.Add := table.AddF64x2;
  ops.ArithmeticF64x2.Sub := table.SubF64x2;
  ops.ArithmeticF64x2.Mul := table.MulF64x2;
  ops.ArithmeticF64x2.OpDiv := table.DivF64x2;

  // === F64x4 Arithmetic ===
  ops.ArithmeticF64x4.Add := table.AddF64x4;
  ops.ArithmeticF64x4.Sub := table.SubF64x4;
  ops.ArithmeticF64x4.Mul := table.MulF64x4;
  ops.ArithmeticF64x4.OpDiv := table.DivF64x4;

  // === I32x4 Arithmetic ===
  ops.ArithmeticI32x4.Add := table.AddI32x4;
  ops.ArithmeticI32x4.Sub := table.SubI32x4;
  ops.ArithmeticI32x4.Mul := table.MulI32x4;

  // === I32x4 Bitwise ===
  ops.BitwiseI32x4.OpAnd := table.AndI32x4;
  ops.BitwiseI32x4.OpOr := table.OrI32x4;
  ops.BitwiseI32x4.OpXor := table.XorI32x4;
  ops.BitwiseI32x4.OpNot := table.NotI32x4;
  ops.BitwiseI32x4.AndNot := table.AndNotI32x4;

  // === I32x4 Shift ===
  ops.ShiftI32x4.ShiftLeft := table.ShiftLeftI32x4;
  ops.ShiftI32x4.ShiftRight := table.ShiftRightI32x4;
  ops.ShiftI32x4.ShiftRightArith := table.ShiftRightArithI32x4;

  // === I32x4 Comparison ===
  ops.ComparisonI32x4.CmpEq := table.CmpEqI32x4;
  ops.ComparisonI32x4.CmpLt := table.CmpLtI32x4;
  ops.ComparisonI32x4.CmpGt := table.CmpGtI32x4;

  // === I32x4 MinMax ===
  ops.MinMaxI32x4.Min := table.MinI32x4;
  ops.MinMaxI32x4.Max := table.MaxI32x4;

  // === I64x2 Arithmetic ===
  ops.ArithmeticI64x2.Add := table.AddI64x2;
  ops.ArithmeticI64x2.Sub := table.SubI64x2;

  // === I64x2 Bitwise ===
  ops.BitwiseI64x2.OpAnd := table.AndI64x2;
  ops.BitwiseI64x2.OpOr := table.OrI64x2;
  ops.BitwiseI64x2.OpXor := table.XorI64x2;
  ops.BitwiseI64x2.OpNot := table.NotI64x2;

  // === I32x8 Arithmetic ===
  ops.ArithmeticI32x8.Add := table.AddI32x8;
  ops.ArithmeticI32x8.Sub := table.SubI32x8;
  ops.ArithmeticI32x8.Mul := table.MulI32x8;

  // === I32x8 Bitwise ===
  ops.BitwiseI32x8.OpAnd := table.AndI32x8;
  ops.BitwiseI32x8.OpOr := table.OrI32x8;
  ops.BitwiseI32x8.OpXor := table.XorI32x8;
  ops.BitwiseI32x8.OpNot := table.NotI32x8;
  ops.BitwiseI32x8.AndNot := table.AndNotI32x8;

  // === I32x8 Shift ===
  ops.ShiftI32x8.ShiftLeft := table.ShiftLeftI32x8;
  ops.ShiftI32x8.ShiftRight := table.ShiftRightI32x8;
  ops.ShiftI32x8.ShiftRightArith := table.ShiftRightArithI32x8;

  // === I32x8 Comparison ===
  ops.ComparisonI32x8.CmpEq := table.CmpEqI32x8;
  ops.ComparisonI32x8.CmpLt := table.CmpLtI32x8;
  ops.ComparisonI32x8.CmpGt := table.CmpGtI32x8;

  // === I32x8 MinMax ===
  ops.MinMaxI32x8.Min := table.MinI32x8;
  ops.MinMaxI32x8.Max := table.MaxI32x8;

  // === 512-bit F32x16 ===
  ops.ArithmeticF32x16.Add := table.AddF32x16;
  ops.ArithmeticF32x16.Sub := table.SubF32x16;
  ops.ArithmeticF32x16.Mul := table.MulF32x16;
  ops.ArithmeticF32x16.OpDiv := table.DivF32x16;

  // === 512-bit F64x8 ===
  ops.ArithmeticF64x8.Add := table.AddF64x8;
  ops.ArithmeticF64x8.Sub := table.SubF64x8;
  ops.ArithmeticF64x8.Mul := table.MulF64x8;
  ops.ArithmeticF64x8.OpDiv := table.DivF64x8;

  // === 512-bit I32x16 Arithmetic ===
  ops.ArithmeticI32x16.Add := table.AddI32x16;
  ops.ArithmeticI32x16.Sub := table.SubI32x16;
  ops.ArithmeticI32x16.Mul := table.MulI32x16;

  // === 512-bit I32x16 Bitwise ===
  ops.BitwiseI32x16.OpAnd := table.AndI32x16;
  ops.BitwiseI32x16.OpOr := table.OrI32x16;
  ops.BitwiseI32x16.OpXor := table.XorI32x16;
  ops.BitwiseI32x16.OpNot := table.NotI32x16;
  ops.BitwiseI32x16.AndNot := table.AndNotI32x16;

  // === 512-bit I32x16 Shift ===
  ops.ShiftI32x16.ShiftLeft := table.ShiftLeftI32x16;
  ops.ShiftI32x16.ShiftRight := table.ShiftRightI32x16;
  ops.ShiftI32x16.ShiftRightArith := table.ShiftRightArithI32x16;

  // === 512-bit I32x16 Comparison ===
  ops.ComparisonI32x16.CmpEq := table.CmpEqI32x16;
  ops.ComparisonI32x16.CmpLt := table.CmpLtI32x16;
  ops.ComparisonI32x16.CmpGt := table.CmpGtI32x16;

  // === 512-bit I32x16 MinMax ===
  ops.MinMaxI32x16.Min := table.MinI32x16;
  ops.MinMaxI32x16.Max := table.MaxI32x16;

  // === F32x4 Comparison ===
  ops.ComparisonF32x4.CmpEq := table.CmpEqF32x4;
  ops.ComparisonF32x4.CmpLt := table.CmpLtF32x4;
  ops.ComparisonF32x4.CmpLe := table.CmpLeF32x4;
  ops.ComparisonF32x4.CmpGt := table.CmpGtF32x4;
  ops.ComparisonF32x4.CmpGe := table.CmpGeF32x4;
  ops.ComparisonF32x4.CmpNe := table.CmpNeF32x4;

  // === F32x4 Math ===
  ops.MathF32x4.Abs := table.AbsF32x4;
  ops.MathF32x4.Sqrt := table.SqrtF32x4;
  ops.MathF32x4.Min := table.MinF32x4;
  ops.MathF32x4.Max := table.MaxF32x4;
  ops.MathF32x4.Fma := table.FmaF32x4;
  ops.MathF32x4.Rcp := table.RcpF32x4;
  ops.MathF32x4.Rsqrt := table.RsqrtF32x4;
  ops.MathF32x4.Floor := table.FloorF32x4;
  ops.MathF32x4.Ceil := table.CeilF32x4;
  ops.MathF32x4.Round := table.RoundF32x4;
  ops.MathF32x4.Trunc := table.TruncF32x4;
  ops.MathF32x4.Clamp := table.ClampF32x4;

  // === F32x4 Vector Math ===
  ops.VectorMathF32x4.Dot4 := table.DotF32x4;
  ops.VectorMathF32x4.Dot3 := table.DotF32x3;
  ops.VectorMathF32x4.Cross3 := table.CrossF32x3;
  ops.VectorMathF32x4.Length4 := table.LengthF32x4;
  ops.VectorMathF32x4.Length3 := table.LengthF32x3;
  ops.VectorMathF32x4.Normalize4 := table.NormalizeF32x4;
  ops.VectorMathF32x4.Normalize3 := table.NormalizeF32x3;

  // === F32x4 Reduction ===
  ops.ReductionF32x4.ReduceAdd := table.ReduceAddF32x4;
  ops.ReductionF32x4.ReduceMin := table.ReduceMinF32x4;
  ops.ReductionF32x4.ReduceMax := table.ReduceMaxF32x4;
  ops.ReductionF32x4.ReduceMul := table.ReduceMulF32x4;

  // === F32x4 Memory ===
  ops.MemoryF32x4.Load := table.LoadF32x4;
  ops.MemoryF32x4.LoadAligned := table.LoadF32x4Aligned;
  ops.MemoryF32x4.Store := table.StoreF32x4;
  ops.MemoryF32x4.StoreAligned := table.StoreF32x4Aligned;
  ops.MemoryF32x4.Splat := table.SplatF32x4;
  ops.MemoryF32x4.Zero := table.ZeroF32x4;
  ops.MemoryF32x4.Select := table.SelectF32x4;
  ops.MemoryF32x4.Extract := table.ExtractF32x4;
  ops.MemoryF32x4.Insert := table.InsertF32x4;

  // === Facade Operations ===
  ops.Facade.MemEqual := table.MemEqual;
  ops.Facade.MemFindByte := table.MemFindByte;
  ops.Facade.MemDiffRange := table.MemDiffRange;
  ops.Facade.MemCopy := table.MemCopy;
  ops.Facade.MemSet := table.MemSet;
  ops.Facade.MemReverse := table.MemReverse;
  ops.Facade.SumBytes := table.SumBytes;
  ops.Facade.MinMaxBytes := table.MinMaxBytes;
  ops.Facade.CountByte := table.CountByte;
  ops.Facade.Utf8Validate := table.Utf8Validate;
  ops.Facade.AsciiIEqual := table.AsciiIEqual;
  ops.Facade.ToLowerAscii := table.ToLowerAscii;
  ops.Facade.ToUpperAscii := table.ToUpperAscii;
  ops.Facade.BytesIndexOf := table.BytesIndexOf;
  ops.Facade.BitsetPopCount := table.BitsetPopCount;
end;

procedure RegisterBackendOps(backend: TSimdBackend; const ops: TSimdBackendOps);
var
  table: TSimdDispatchTable;
begin
  // Convert new format to legacy format
  BackendOpsToDispatchTable(ops, table);
  // Register using existing system
  RegisterBackend(backend, table);
end;

function GetBackendOps(backend: TSimdBackend): TSimdBackendOps;
var
  info: TSimdBackendInfo;
begin
  // Get backend info to check if registered
  info := GetBackendInfo(backend);
  if info.Available then
  begin
    // For now, return empty ops - future: cache converted ops
    ClearBackendOps(Result);
    Result.Backend := backend;
    Result.BackendInfo := info;
  end
  else
  begin
    ClearBackendOps(Result);
    Result.Backend := sbScalar;
  end;
end;

function IsBackendOpsRegistered(backend: TSimdBackend): Boolean;
begin
  Result := IsBackendRegistered(backend);
end;

procedure FillScalarOps(var ops: TSimdBackendOps);
begin
  // Initialize to zeros first
  ClearBackendOps(ops);

  // Set backend info
  ops.Backend := sbScalar;
  ops.BackendInfo.Backend := sbScalar;
  ops.BackendInfo.Name := 'Scalar';
  ops.BackendInfo.Description := 'Pure scalar reference implementation';
  ops.BackendInfo.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction, scLoadStore];
  ops.BackendInfo.Available := True;
  ops.BackendInfo.Priority := 0;

  // === F32x4 Arithmetic ===
  ops.ArithmeticF32x4.Add := @ScalarAddF32x4;
  ops.ArithmeticF32x4.Sub := @ScalarSubF32x4;
  ops.ArithmeticF32x4.Mul := @ScalarMulF32x4;
  ops.ArithmeticF32x4.OpDiv := @ScalarDivF32x4;

  // === F32x8 Arithmetic ===
  ops.ArithmeticF32x8.Add := @ScalarAddF32x8;
  ops.ArithmeticF32x8.Sub := @ScalarSubF32x8;
  ops.ArithmeticF32x8.Mul := @ScalarMulF32x8;
  ops.ArithmeticF32x8.OpDiv := @ScalarDivF32x8;

  // === F64x2 Arithmetic ===
  ops.ArithmeticF64x2.Add := @ScalarAddF64x2;
  ops.ArithmeticF64x2.Sub := @ScalarSubF64x2;
  ops.ArithmeticF64x2.Mul := @ScalarMulF64x2;
  ops.ArithmeticF64x2.OpDiv := @ScalarDivF64x2;

  // === F64x4 Arithmetic ===
  ops.ArithmeticF64x4.Add := @ScalarAddF64x4;
  ops.ArithmeticF64x4.Sub := @ScalarSubF64x4;
  ops.ArithmeticF64x4.Mul := @ScalarMulF64x4;
  ops.ArithmeticF64x4.OpDiv := @ScalarDivF64x4;

  // === I32x4 Arithmetic ===
  ops.ArithmeticI32x4.Add := @ScalarAddI32x4;
  ops.ArithmeticI32x4.Sub := @ScalarSubI32x4;
  ops.ArithmeticI32x4.Mul := @ScalarMulI32x4;

  // === I32x4 Bitwise ===
  ops.BitwiseI32x4.OpAnd := @ScalarAndI32x4;
  ops.BitwiseI32x4.OpOr := @ScalarOrI32x4;
  ops.BitwiseI32x4.OpXor := @ScalarXorI32x4;
  ops.BitwiseI32x4.OpNot := @ScalarNotI32x4;
  ops.BitwiseI32x4.AndNot := @ScalarAndNotI32x4;

  // === I32x4 Shift ===
  ops.ShiftI32x4.ShiftLeft := @ScalarShiftLeftI32x4;
  ops.ShiftI32x4.ShiftRight := @ScalarShiftRightI32x4;
  ops.ShiftI32x4.ShiftRightArith := @ScalarShiftRightArithI32x4;

  // === I32x4 Comparison ===
  ops.ComparisonI32x4.CmpEq := @ScalarCmpEqI32x4;
  ops.ComparisonI32x4.CmpLt := @ScalarCmpLtI32x4;
  ops.ComparisonI32x4.CmpGt := @ScalarCmpGtI32x4;

  // === I32x4 MinMax ===
  ops.MinMaxI32x4.Min := @ScalarMinI32x4;
  ops.MinMaxI32x4.Max := @ScalarMaxI32x4;

  // === I64x2 Arithmetic ===
  ops.ArithmeticI64x2.Add := @ScalarAddI64x2;
  ops.ArithmeticI64x2.Sub := @ScalarSubI64x2;

  // === I64x2 Bitwise ===
  ops.BitwiseI64x2.OpAnd := @ScalarAndI64x2;
  ops.BitwiseI64x2.OpOr := @ScalarOrI64x2;
  ops.BitwiseI64x2.OpXor := @ScalarXorI64x2;
  ops.BitwiseI64x2.OpNot := @ScalarNotI64x2;

  // === I32x8 Arithmetic ===
  ops.ArithmeticI32x8.Add := @ScalarAddI32x8;
  ops.ArithmeticI32x8.Sub := @ScalarSubI32x8;
  ops.ArithmeticI32x8.Mul := @ScalarMulI32x8;

  // === I32x8 Bitwise ===
  ops.BitwiseI32x8.OpAnd := @ScalarAndI32x8;
  ops.BitwiseI32x8.OpOr := @ScalarOrI32x8;
  ops.BitwiseI32x8.OpXor := @ScalarXorI32x8;
  ops.BitwiseI32x8.OpNot := @ScalarNotI32x8;
  ops.BitwiseI32x8.AndNot := @ScalarAndNotI32x8;

  // === I32x8 Shift ===
  ops.ShiftI32x8.ShiftLeft := @ScalarShiftLeftI32x8;
  ops.ShiftI32x8.ShiftRight := @ScalarShiftRightI32x8;
  ops.ShiftI32x8.ShiftRightArith := @ScalarShiftRightArithI32x8;

  // === I32x8 Comparison ===
  ops.ComparisonI32x8.CmpEq := @ScalarCmpEqI32x8;
  ops.ComparisonI32x8.CmpLt := @ScalarCmpLtI32x8;
  ops.ComparisonI32x8.CmpGt := @ScalarCmpGtI32x8;

  // === I32x8 MinMax ===
  ops.MinMaxI32x8.Min := @ScalarMinI32x8;
  ops.MinMaxI32x8.Max := @ScalarMaxI32x8;

  // === F32x16 Arithmetic (512-bit) ===
  ops.ArithmeticF32x16.Add := @ScalarAddF32x16;
  ops.ArithmeticF32x16.Sub := @ScalarSubF32x16;
  ops.ArithmeticF32x16.Mul := @ScalarMulF32x16;
  ops.ArithmeticF32x16.OpDiv := @ScalarDivF32x16;

  // === F64x8 Arithmetic (512-bit) ===
  ops.ArithmeticF64x8.Add := @ScalarAddF64x8;
  ops.ArithmeticF64x8.Sub := @ScalarSubF64x8;
  ops.ArithmeticF64x8.Mul := @ScalarMulF64x8;
  ops.ArithmeticF64x8.OpDiv := @ScalarDivF64x8;

  // === I32x16 Arithmetic (512-bit) ===
  ops.ArithmeticI32x16.Add := @ScalarAddI32x16;
  ops.ArithmeticI32x16.Sub := @ScalarSubI32x16;
  ops.ArithmeticI32x16.Mul := @ScalarMulI32x16;

  // === I32x16 Bitwise ===
  ops.BitwiseI32x16.OpAnd := @ScalarAndI32x16;
  ops.BitwiseI32x16.OpOr := @ScalarOrI32x16;
  ops.BitwiseI32x16.OpXor := @ScalarXorI32x16;
  ops.BitwiseI32x16.OpNot := @ScalarNotI32x16;
  ops.BitwiseI32x16.AndNot := @ScalarAndNotI32x16;

  // === I32x16 Shift ===
  ops.ShiftI32x16.ShiftLeft := @ScalarShiftLeftI32x16;
  ops.ShiftI32x16.ShiftRight := @ScalarShiftRightI32x16;
  ops.ShiftI32x16.ShiftRightArith := @ScalarShiftRightArithI32x16;

  // === I32x16 Comparison ===
  ops.ComparisonI32x16.CmpEq := @ScalarCmpEqI32x16;
  ops.ComparisonI32x16.CmpLt := @ScalarCmpLtI32x16;
  ops.ComparisonI32x16.CmpGt := @ScalarCmpGtI32x16;

  // === I32x16 MinMax ===
  ops.MinMaxI32x16.Min := @ScalarMinI32x16;
  ops.MinMaxI32x16.Max := @ScalarMaxI32x16;

  // === F32x4 Comparison ===
  ops.ComparisonF32x4.CmpEq := @ScalarCmpEqF32x4;
  ops.ComparisonF32x4.CmpLt := @ScalarCmpLtF32x4;
  ops.ComparisonF32x4.CmpLe := @ScalarCmpLeF32x4;
  ops.ComparisonF32x4.CmpGt := @ScalarCmpGtF32x4;
  ops.ComparisonF32x4.CmpGe := @ScalarCmpGeF32x4;
  ops.ComparisonF32x4.CmpNe := @ScalarCmpNeF32x4;

  // === F32x4 Math ===
  ops.MathF32x4.Abs := @ScalarAbsF32x4;
  ops.MathF32x4.Sqrt := @ScalarSqrtF32x4;
  ops.MathF32x4.Min := @ScalarMinF32x4;
  ops.MathF32x4.Max := @ScalarMaxF32x4;
  ops.MathF32x4.Fma := @ScalarFmaF32x4;
  ops.MathF32x4.Rcp := @ScalarRcpF32x4;
  ops.MathF32x4.Rsqrt := @ScalarRsqrtF32x4;
  ops.MathF32x4.Floor := @ScalarFloorF32x4;
  ops.MathF32x4.Ceil := @ScalarCeilF32x4;
  ops.MathF32x4.Round := @ScalarRoundF32x4;
  ops.MathF32x4.Trunc := @ScalarTruncF32x4;
  ops.MathF32x4.Clamp := @ScalarClampF32x4;

  // === F32x4 Vector Math ===
  ops.VectorMathF32x4.Dot4 := @ScalarDotF32x4;
  ops.VectorMathF32x4.Dot3 := @ScalarDotF32x3;
  ops.VectorMathF32x4.Cross3 := @ScalarCrossF32x3;
  ops.VectorMathF32x4.Length4 := @ScalarLengthF32x4;
  ops.VectorMathF32x4.Length3 := @ScalarLengthF32x3;
  ops.VectorMathF32x4.Normalize4 := @ScalarNormalizeF32x4;
  ops.VectorMathF32x4.Normalize3 := @ScalarNormalizeF32x3;

  // === F32x4 Reduction ===
  ops.ReductionF32x4.ReduceAdd := @ScalarReduceAddF32x4;
  ops.ReductionF32x4.ReduceMin := @ScalarReduceMinF32x4;
  ops.ReductionF32x4.ReduceMax := @ScalarReduceMaxF32x4;
  ops.ReductionF32x4.ReduceMul := @ScalarReduceMulF32x4;

  // === F32x4 Memory Operations ===
  ops.MemoryF32x4.Load := @ScalarLoadF32x4;
  ops.MemoryF32x4.LoadAligned := @ScalarLoadF32x4Aligned;
  ops.MemoryF32x4.Store := @ScalarStoreF32x4;
  ops.MemoryF32x4.StoreAligned := @ScalarStoreF32x4Aligned;
  ops.MemoryF32x4.Splat := @ScalarSplatF32x4;
  ops.MemoryF32x4.Zero := @ScalarZeroF32x4;
  ops.MemoryF32x4.Select := @ScalarSelectF32x4;
  ops.MemoryF32x4.Extract := @ScalarExtractF32x4;
  ops.MemoryF32x4.Insert := @ScalarInsertF32x4;

  // === Facade Operations ===
  ops.Facade.MemEqual := @MemEqual_Scalar;
  ops.Facade.MemFindByte := @MemFindByte_Scalar;
  ops.Facade.MemDiffRange := @MemDiffRange_Scalar;
  ops.Facade.MemCopy := @MemCopy_Scalar;
  ops.Facade.MemSet := @MemSet_Scalar;
  ops.Facade.MemReverse := @MemReverse_Scalar;
  ops.Facade.SumBytes := @SumBytes_Scalar;
  ops.Facade.MinMaxBytes := @MinMaxBytes_Scalar;
  ops.Facade.CountByte := @CountByte_Scalar;
  ops.Facade.Utf8Validate := @Utf8Validate_Scalar;
  ops.Facade.AsciiIEqual := @AsciiIEqual_Scalar;
  ops.Facade.ToLowerAscii := @ToLowerAscii_Scalar;
  ops.Facade.ToUpperAscii := @ToUpperAscii_Scalar;
  ops.Facade.BytesIndexOf := @BytesIndexOf_Scalar;
  ops.Facade.BitsetPopCount := @BitsetPopCount_Scalar;
end;

end.

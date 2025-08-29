unit fafafa.core.simd.scalar;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types,
  fafafa.core.simd.dispatch;

// === Scalar Backend Implementation ===
// This provides the reference implementation for all SIMD operations
// using pure scalar code. It serves as:
// 1. Fallback when no SIMD hardware is available
// 2. Reference for correctness testing
// 3. Performance baseline

// Register the scalar backend
procedure RegisterScalarBackend;

implementation

uses
  Math,
  SysUtils;

// === Vector Type Implementations ===
// These are the actual data structures for vectors

type
  // 32-bit float vectors
  TVecF32x4Data = array[0..3] of Single;
  TVecF32x8Data = array[0..7] of Single;

  // 64-bit float vectors
  TVecF64x2Data = array[0..1] of Double;
  TVecF64x4Data = array[0..3] of Double;

  // 32-bit integer vectors
  TVecI32x4Data = array[0..3] of Int32;
  TVecI32x8Data = array[0..7] of Int32;

// Redefine the vector types with actual data
{$PUSH}
{$WARNINGS OFF} // Suppress redefinition warnings
type
  TVecF32x4 = record
    Data: TVecF32x4Data;
  end;

  TVecF32x8 = record
    Data: TVecF32x8Data;
  end;

  TVecF64x2 = record
    Data: TVecF64x2Data;
  end;

  TVecF64x4 = record
    Data: TVecF64x4Data;
  end;

  TVecI32x4 = record
    Data: TVecI32x4Data;
  end;

  TVecI32x8 = record
    Data: TVecI32x8Data;
  end;
{$POP}

// === Arithmetic Operations ===

function ScalarAddF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

function ScalarDivF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] / b.Data[i];
end;

function ScalarAddF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

function ScalarDivF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] / b.Data[i];
end;

function ScalarAddF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

function ScalarDivF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] / b.Data[i];
end;

function ScalarAddI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

// === Comparison Operations ===

function ScalarCmpEqF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] = b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpLtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] < b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpLeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] <= b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpGtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] > b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpGeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] >= b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpNeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] <> b.Data[i] then
      Result := Result or (1 shl i);
end;

// === Math Functions ===

function ScalarAbsF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Abs(a.Data[i]);
end;

function ScalarSqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Sqrt(a.Data[i]);
end;

function ScalarMinF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Min(a.Data[i], b.Data[i]);
end;

function ScalarMaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Max(a.Data[i], b.Data[i]);
end;

// === Reduction Operations ===

function ScalarReduceAddF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 3 do
    Result := Result + a.Data[i];
end;

function ScalarReduceMinF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.Data[0];
  for i := 1 to 3 do
    Result := Min(Result, a.Data[i]);
end;

function ScalarReduceMaxF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.Data[0];
  for i := 1 to 3 do
    Result := Max(Result, a.Data[i]);
end;

function ScalarReduceMulF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := 1.0;
  for i := 0 to 3 do
    Result := Result * a.Data[i];
end;

// === Memory Operations ===

function ScalarLoadF32x4(p: PSingle): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := p[i];
end;

function ScalarLoadF32x4Aligned(p: PSingle): TVecF32x4;
begin
  // For scalar implementation, aligned and unaligned are the same
  Result := ScalarLoadF32x4(p);
end;

procedure ScalarStoreF32x4(p: PSingle; const a: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.Data[i];
end;

procedure ScalarStoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
begin
  // For scalar implementation, aligned and unaligned are the same
  ScalarStoreF32x4(p, a);
end;

// === Utility Operations ===

function ScalarSplatF32x4(value: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := value;
end;

function ScalarZeroF32x4: TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := 0.0;
end;

function ScalarSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.Data[i] := a.Data[i]
    else
      Result.Data[i] := b.Data[i];
end;

function ScalarExtractF32x4(const a: TVecF32x4; index: Integer): Single;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..3]', [index]);
  {$ENDIF}
  Result := a.Data[index];
end;

function ScalarInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..3]', [index]);
  {$ENDIF}
  Result := a;
  Result.Data[index] := value;
end;

// === Backend Registration ===

procedure RegisterScalarBackend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Initialize dispatch table
  FillChar(dispatchTable, SizeOf(dispatchTable), 0);

  // Set backend info
  dispatchTable.Backend := sbScalar;
  dispatchTable.BackendInfo := GetBackendInfo(sbScalar);

  // Register arithmetic operations
  dispatchTable.AddF32x4 := @ScalarAddF32x4;
  dispatchTable.SubF32x4 := @ScalarSubF32x4;
  dispatchTable.MulF32x4 := @ScalarMulF32x4;
  dispatchTable.DivF32x4 := @ScalarDivF32x4;

  dispatchTable.AddF32x8 := @ScalarAddF32x8;
  dispatchTable.SubF32x8 := @ScalarSubF32x8;
  dispatchTable.MulF32x8 := @ScalarMulF32x8;
  dispatchTable.DivF32x8 := @ScalarDivF32x8;

  dispatchTable.AddF64x2 := @ScalarAddF64x2;
  dispatchTable.SubF64x2 := @ScalarSubF64x2;
  dispatchTable.MulF64x2 := @ScalarMulF64x2;
  dispatchTable.DivF64x2 := @ScalarDivF64x2;

  dispatchTable.AddI32x4 := @ScalarAddI32x4;
  dispatchTable.SubI32x4 := @ScalarSubI32x4;
  dispatchTable.MulI32x4 := @ScalarMulI32x4;

  // Register comparison operations
  dispatchTable.CmpEqF32x4 := @ScalarCmpEqF32x4;
  dispatchTable.CmpLtF32x4 := @ScalarCmpLtF32x4;
  dispatchTable.CmpLeF32x4 := @ScalarCmpLeF32x4;
  dispatchTable.CmpGtF32x4 := @ScalarCmpGtF32x4;
  dispatchTable.CmpGeF32x4 := @ScalarCmpGeF32x4;
  dispatchTable.CmpNeF32x4 := @ScalarCmpNeF32x4;

  // Register math functions
  dispatchTable.AbsF32x4 := @ScalarAbsF32x4;
  dispatchTable.SqrtF32x4 := @ScalarSqrtF32x4;
  dispatchTable.MinF32x4 := @ScalarMinF32x4;
  dispatchTable.MaxF32x4 := @ScalarMaxF32x4;

  // Register reduction operations
  dispatchTable.ReduceAddF32x4 := @ScalarReduceAddF32x4;
  dispatchTable.ReduceMinF32x4 := @ScalarReduceMinF32x4;
  dispatchTable.ReduceMaxF32x4 := @ScalarReduceMaxF32x4;
  dispatchTable.ReduceMulF32x4 := @ScalarReduceMulF32x4;

  // Register memory operations
  dispatchTable.LoadF32x4 := @ScalarLoadF32x4;
  dispatchTable.LoadF32x4Aligned := @ScalarLoadF32x4Aligned;
  dispatchTable.StoreF32x4 := @ScalarStoreF32x4;
  dispatchTable.StoreF32x4Aligned := @ScalarStoreF32x4Aligned;

  // Register utility operations
  dispatchTable.SplatF32x4 := @ScalarSplatF32x4;
  dispatchTable.ZeroF32x4 := @ScalarZeroF32x4;
  dispatchTable.SelectF32x4 := @ScalarSelectF32x4;
  dispatchTable.ExtractF32x4 := @ScalarExtractF32x4;
  dispatchTable.InsertF32x4 := @ScalarInsertF32x4;

  // Register the backend
  RegisterBackend(sbScalar, dispatchTable);
end;

initialization
  // Register scalar backend on unit initialization
  RegisterScalarBackend;

end.
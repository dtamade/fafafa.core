unit fafafa.core.simd.scalar;

{$mode objfpc}
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

// === 标量门面函数声明 ===

// 内存操作函数
function MemEqual_Scalar(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
function MemDiffRange_Scalar(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemCopy_Scalar(src, dst: Pointer; len: SizeUInt);
procedure MemSet_Scalar(dst: Pointer; len: SizeUInt; value: Byte);
procedure MemReverse_Scalar(p: Pointer; len: SizeUInt);

// 统计函数
function SumBytes_Scalar(p: Pointer; len: SizeUInt): UInt64;
procedure MinMaxBytes_Scalar(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
function CountByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;

// 文本处理函数
function Utf8Validate_Scalar(p: Pointer; len: SizeUInt): Boolean;
function AsciiIEqual_Scalar(a, b: Pointer; len: SizeUInt): Boolean;
procedure ToLowerAscii_Scalar(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_Scalar(p: Pointer; len: SizeUInt);

// 搜索函数
function BytesIndexOf_Scalar(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;

// 位集函数
function BitsetPopCount_Scalar(p: Pointer; byteLen: SizeUInt): SizeUInt;

// 扩展数学函数
function ScalarFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
function ScalarRcpF32x4(const a: TVecF32x4): TVecF32x4;
function ScalarRsqrtF32x4(const a: TVecF32x4): TVecF32x4;
function ScalarFloorF32x4(const a: TVecF32x4): TVecF32x4;
function ScalarCeilF32x4(const a: TVecF32x4): TVecF32x4;
function ScalarRoundF32x4(const a: TVecF32x4): TVecF32x4;
function ScalarTruncF32x4(const a: TVecF32x4): TVecF32x4;
function ScalarClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;

// 3D/4D 向量数学函数
function ScalarDotF32x4(const a, b: TVecF32x4): Single;
function ScalarDotF32x3(const a, b: TVecF32x4): Single;
function ScalarCrossF32x3(const a, b: TVecF32x4): TVecF32x4;
function ScalarLengthF32x4(const a: TVecF32x4): Single;
function ScalarLengthF32x3(const a: TVecF32x4): Single;
function ScalarNormalizeF32x4(const a: TVecF32x4): TVecF32x4;
function ScalarNormalizeF32x3(const a: TVecF32x4): TVecF32x4;

implementation

uses
  Math,
  SysUtils;

// === Arithmetic Operations ===
// Using types from fafafa.core.simd.types:
//   TVecF32x4.f[0..3], TVecF64x2.d[0..1], TVecI32x4.i[0..3], etc.

function ScalarAddF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function ScalarSubF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function ScalarMulF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function ScalarDivF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] / b.f[i];
end;

function ScalarAddF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function ScalarSubF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function ScalarMulF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function ScalarDivF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] / b.f[i];
end;

function ScalarAddF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function ScalarSubF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function ScalarMulF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function ScalarDivF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] / b.d[i];
end;

function ScalarAddI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function ScalarSubI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function ScalarMulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] * b.i[i];
end;

// === Comparison Operations ===

function ScalarCmpEqF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpLtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpLeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpGtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpGeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpNeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// === Math Functions ===

function ScalarAbsF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Abs(a.f[i]);
end;

function ScalarSqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function ScalarMinF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Min(a.f[i], b.f[i]);
end;

function ScalarMaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Max(a.f[i], b.f[i]);
end;

// === Extended Math Functions ===

function ScalarFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function ScalarRcpF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / a.f[i];
end;

function ScalarRsqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / Sqrt(a.f[i]);
end;

function ScalarFloorF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Floor(a.f[i]);
end;

function ScalarCeilF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Ceil(a.f[i]);
end;

function ScalarRoundF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Round(a.f[i]);
end;

function ScalarTruncF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Trunc(a.f[i]);
end;

function ScalarClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Max(minVal.f[i], Min(a.f[i], maxVal.f[i]));
end;

// === 3D/4D Vector Math ===

function ScalarDotF32x4(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2] + a.f[3] * b.f[3];
end;

function ScalarDotF32x3(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2];
end;

function ScalarCrossF32x3(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[1] * b.f[2] - a.f[2] * b.f[1];
  Result.f[1] := a.f[2] * b.f[0] - a.f[0] * b.f[2];
  Result.f[2] := a.f[0] * b.f[1] - a.f[1] * b.f[0];
  Result.f[3] := 0.0;
end;

function ScalarLengthF32x4(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2] + a.f[3] * a.f[3]);
end;

function ScalarLengthF32x3(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2]);
end;

function ScalarNormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var
  len: Single;
  invLen: Single;
  i: Integer;
begin
  len := ScalarLengthF32x4(a);
  if len > 0.0 then
  begin
    invLen := 1.0 / len;
    for i := 0 to 3 do
      Result.f[i] := a.f[i] * invLen;
  end
  else
    Result := a;
end;

function ScalarNormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var
  len: Single;
  invLen: Single;
begin
  len := ScalarLengthF32x3(a);
  if len > 0.0 then
  begin
    invLen := 1.0 / len;
    Result.f[0] := a.f[0] * invLen;
    Result.f[1] := a.f[1] * invLen;
    Result.f[2] := a.f[2] * invLen;
    Result.f[3] := 0.0;
  end
  else
  begin
    Result := a;
    Result.f[3] := 0.0;
  end;
end;

// === Reduction Operations ===

function ScalarReduceAddF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 3 do
    Result := Result + a.f[i];
end;

function ScalarReduceMinF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    Result := Min(Result, a.f[i]);
end;

function ScalarReduceMaxF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    Result := Max(Result, a.f[i]);
end;

function ScalarReduceMulF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := 1.0;
  for i := 0 to 3 do
    Result := Result * a.f[i];
end;

// === Memory Operations ===

function ScalarLoadF32x4(p: PSingle): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := p[i];
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
    p[i] := a.f[i];
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
    Result.f[i] := value;
end;

function ScalarZeroF32x4: TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 0.0;
end;

function ScalarSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function ScalarExtractF32x4(const a: TVecF32x4; index: Integer): Single;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..3]', [index]);
  {$ENDIF}
  Result := a.f[index];
end;

function ScalarInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..3]', [index]);
  {$ENDIF}
  Result := a;
  Result.f[index] := value;
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
  with dispatchTable.BackendInfo do
  begin
    Backend := sbScalar;
    Name := 'Scalar';
    Description := 'Pure scalar reference implementation';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction, scLoadStore];
    Available := True;
    Priority := 0; // Lowest priority
  end;

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

  // Register extended math functions
  dispatchTable.FmaF32x4 := @ScalarFmaF32x4;
  dispatchTable.RcpF32x4 := @ScalarRcpF32x4;
  dispatchTable.RsqrtF32x4 := @ScalarRsqrtF32x4;
  dispatchTable.FloorF32x4 := @ScalarFloorF32x4;
  dispatchTable.CeilF32x4 := @ScalarCeilF32x4;
  dispatchTable.RoundF32x4 := @ScalarRoundF32x4;
  dispatchTable.TruncF32x4 := @ScalarTruncF32x4;
  dispatchTable.ClampF32x4 := @ScalarClampF32x4;

  // Register 3D/4D vector math
  dispatchTable.DotF32x4 := @ScalarDotF32x4;
  dispatchTable.DotF32x3 := @ScalarDotF32x3;
  dispatchTable.CrossF32x3 := @ScalarCrossF32x3;
  dispatchTable.LengthF32x4 := @ScalarLengthF32x4;
  dispatchTable.LengthF32x3 := @ScalarLengthF32x3;
  dispatchTable.NormalizeF32x4 := @ScalarNormalizeF32x4;
  dispatchTable.NormalizeF32x3 := @ScalarNormalizeF32x3;

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

  // Register facade functions
  dispatchTable.MemEqual := @MemEqual_Scalar;
  dispatchTable.MemFindByte := @MemFindByte_Scalar;
  dispatchTable.MemDiffRange := @MemDiffRange_Scalar;
  dispatchTable.MemCopy := @MemCopy_Scalar;
  dispatchTable.MemSet := @MemSet_Scalar;
  dispatchTable.MemReverse := @MemReverse_Scalar;
  dispatchTable.SumBytes := @SumBytes_Scalar;
  dispatchTable.MinMaxBytes := @MinMaxBytes_Scalar;
  dispatchTable.CountByte := @CountByte_Scalar;
  dispatchTable.Utf8Validate := @Utf8Validate_Scalar;
  dispatchTable.AsciiIEqual := @AsciiIEqual_Scalar;
  dispatchTable.ToLowerAscii := @ToLowerAscii_Scalar;
  dispatchTable.ToUpperAscii := @ToUpperAscii_Scalar;
  dispatchTable.BytesIndexOf := @BytesIndexOf_Scalar;
  dispatchTable.BitsetPopCount := @BitsetPopCount_Scalar;

  // Register the backend
  RegisterBackend(sbScalar, dispatchTable);
end;

// === 标量门面函数实现 ===

// 内存操作函数
function MemEqual_Scalar(a, b: Pointer; len: SizeUInt): LongBool;
var
  pa, pb: PByte;
  i: SizeUInt;
begin
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);

  for i := 0 to len - 1 do
  begin
    if pa[i] <> pb[i] then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True;
end;

function MemFindByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  pb: PByte;
  i: SizeUInt;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := -1;
    Exit;
  end;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if pb[i] = value then
    begin
      Result := PtrInt(i);
      Exit;
    end;
  end;

  Result := -1;
end;

function MemDiffRange_Scalar(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
var
  pa, pb: PByte;
  i: SizeUInt;
  foundFirst: Boolean;
begin
  firstDiff := 0;
  lastDiff := 0;

  if len = 0 then
  begin
    Result := False;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    if a <> b then
    begin
      firstDiff := 0;
      lastDiff := len - 1;
      Result := True;
    end
    else
      Result := False;
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);
  foundFirst := False;

  for i := 0 to len - 1 do
  begin
    if pa[i] <> pb[i] then
    begin
      if not foundFirst then
      begin
        firstDiff := i;
        foundFirst := True;
      end;
      lastDiff := i;
    end;
  end;

  Result := foundFirst;
end;

procedure MemCopy_Scalar(src, dst: Pointer; len: SizeUInt);
begin
  if (len = 0) or (src = nil) or (dst = nil) then
    Exit;

  Move(src^, dst^, len);
end;

procedure MemSet_Scalar(dst: Pointer; len: SizeUInt; value: Byte);
begin
  if (len = 0) or (dst = nil) then
    Exit;

  FillChar(dst^, len, value);
end;

procedure MemReverse_Scalar(p: Pointer; len: SizeUInt);
var
  pb: PByte;
  i: SizeUInt;
  temp: Byte;
begin
  if (len <= 1) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to (len div 2) - 1 do
  begin
    temp := pb[i];
    pb[i] := pb[len - 1 - i];
    pb[len - 1 - i] := temp;
  end;
end;

// 统计函数
function SumBytes_Scalar(p: Pointer; len: SizeUInt): UInt64;
var
  pb: PByte;
  i: SizeUInt;
begin
  Result := 0;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
    Result := Result + pb[i];
end;

procedure MinMaxBytes_Scalar(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
var
  pb: PByte;
  i: SizeUInt;
begin
  minVal := 255;
  maxVal := 0;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);
  minVal := pb[0];
  maxVal := pb[0];

  for i := 1 to len - 1 do
  begin
    if pb[i] < minVal then
      minVal := pb[i];
    if pb[i] > maxVal then
      maxVal := pb[i];
  end;
end;

function CountByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
begin
  Result := 0;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if pb[i] = value then
      Inc(Result);
  end;
end;

// 文本处理函数
function Utf8Validate_Scalar(p: Pointer; len: SizeUInt): Boolean;
var
  pb: PByte;
  i: SizeUInt;
  b, b2: Byte;
  seqLen: Integer;
  j: Integer;
begin
  Result := True;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);
  i := 0;

  while i < len do
  begin
    b := pb[i];

    // ASCII (0xxxxxxx)
    if (b and $80) = 0 then
    begin
      Inc(i);
      Continue;
    end;

    // Multi-byte sequence
    // 2-byte sequences: $C2-$DF (NOT $C0-$C1 which are overlong)
    if (b >= $C2) and (b <= $DF) then
      seqLen := 2
    // 3-byte sequences: $E0-$EF
    else if (b and $F0) = $E0 then
      seqLen := 3
    // 4-byte sequences: $F0-$F4
    else if (b >= $F0) and (b <= $F4) then
      seqLen := 4
    else
    begin
      // Invalid leading byte ($C0, $C1, $F5-$FF, or continuation byte)
      Result := False;
      Exit;
    end;

    // Check if we have enough bytes
    if i + SizeUInt(seqLen) > len then
    begin
      Result := False;
      Exit;
    end;

    // Check continuation bytes
    for j := 1 to seqLen - 1 do
    begin
      if (pb[i + SizeUInt(j)] and $C0) <> $80 then
      begin
        Result := False;
        Exit;
      end;
    end;

    // Additional checks for overlong sequences
    if seqLen = 3 then
    begin
      b2 := pb[i + 1];
      // E0 followed by 80-9F is overlong
      if (b = $E0) and (b2 < $A0) then
      begin
        Result := False;
        Exit;
      end;
      // ED followed by A0-BF is surrogate (invalid in UTF-8)
      if (b = $ED) and (b2 >= $A0) then
      begin
        Result := False;
        Exit;
      end;
    end
    else if seqLen = 4 then
    begin
      b2 := pb[i + 1];
      // F0 followed by 80-8F is overlong
      if (b = $F0) and (b2 < $90) then
      begin
        Result := False;
        Exit;
      end;
      // F4 followed by 90-BF is beyond Unicode range
      if (b = $F4) and (b2 >= $90) then
      begin
        Result := False;
        Exit;
      end;
    end;

    Inc(i, seqLen);
  end;
end;

function AsciiIEqual_Scalar(a, b: Pointer; len: SizeUInt): Boolean;
var
  pa, pb: PByte;
  i: SizeUInt;
  ca, cb: Byte;
begin
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);

  for i := 0 to len - 1 do
  begin
    ca := pa[i];
    cb := pb[i];

    // Convert to lowercase for comparison
    if (ca >= Ord('A')) and (ca <= Ord('Z')) then
      ca := ca + 32;
    if (cb >= Ord('A')) and (cb <= Ord('Z')) then
      cb := cb + 32;

    if ca <> cb then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True;
end;

procedure ToLowerAscii_Scalar(p: Pointer; len: SizeUInt);
var
  pb: PByte;
  i: SizeUInt;
begin
  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if (pb[i] >= Ord('A')) and (pb[i] <= Ord('Z')) then
      pb[i] := pb[i] + 32;
  end;
end;

procedure ToUpperAscii_Scalar(p: Pointer; len: SizeUInt);
var
  pb: PByte;
  i: SizeUInt;
begin
  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if (pb[i] >= Ord('a')) and (pb[i] <= Ord('z')) then
      pb[i] := pb[i] - 32;
  end;
end;

// 搜索函数
function BytesIndexOf_Scalar(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
var
  ph, pn: PByte;
  i, j: SizeUInt;
  found: Boolean;
begin
  Result := -1;

  if (haystackLen = 0) or (needleLen = 0) or (haystack = nil) or (needle = nil) then
    Exit;

  if needleLen > haystackLen then
    Exit;

  ph := PByte(haystack);
  pn := PByte(needle);

  for i := 0 to haystackLen - needleLen do
  begin
    found := True;
    for j := 0 to needleLen - 1 do
    begin
      if ph[i + j] <> pn[j] then
      begin
        found := False;
        Break;
      end;
    end;

    if found then
    begin
      Result := PtrInt(i);
      Exit;
    end;
  end;
end;

// 位集函数
function BitsetPopCount_Scalar(p: Pointer; byteLen: SizeUInt): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
  b: Byte;
  count: Integer;
begin
  Result := 0;

  if (byteLen = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to byteLen - 1 do
  begin
    b := pb[i];
    count := 0;

    // Count bits in byte
    while b <> 0 do
    begin
      if (b and 1) <> 0 then
        Inc(count);
      b := b shr 1;
    end;

    Result := Result + SizeUInt(count);
  end;
end;

initialization
  // Register scalar backend on unit initialization
  RegisterScalarBackend;

end.


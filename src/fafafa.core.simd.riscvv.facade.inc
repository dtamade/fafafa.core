// =============================================================
// Facade Function Implementations
// =============================================================
// Keep facade APIs available in asm branch by delegating to scalar helpers.

function MemEqual_RISCVV(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := MemEqual_Scalar(a, b, len);
end;

function MemFindByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  Result := MemFindByte_Scalar(p, len, value);
end;

function MemDiffRange_RISCVV(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  Result := MemDiffRange_Scalar(a, b, len, firstDiff, lastDiff);
end;

procedure MemCopy_RISCVV(src, dst: Pointer; len: SizeUInt);
begin
  MemCopy_Scalar(src, dst, len);
end;

procedure MemSet_RISCVV(dst: Pointer; len: SizeUInt; value: Byte);
begin
  MemSet_Scalar(dst, len, value);
end;

procedure MemReverse_RISCVV(p: Pointer; len: SizeUInt);
begin
  MemReverse_Scalar(p, len);
end;

function SumBytes_RISCVV(p: Pointer; len: SizeUInt): UInt64;
begin
  Result := SumBytes_Scalar(p, len);
end;

procedure MinMaxBytes_RISCVV(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
begin
  MinMaxBytes_Scalar(p, len, minVal, maxVal);
end;

function CountByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := CountByte_Scalar(p, len, value);
end;

function Utf8Validate_RISCVV(p: Pointer; len: SizeUInt): Boolean;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function AsciiIEqual_RISCVV(a, b: Pointer; len: SizeUInt): Boolean;
begin
  Result := AsciiIEqual_Scalar(a, b, len);
end;

procedure ToLowerAscii_RISCVV(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_Scalar(p, len);
end;

procedure ToUpperAscii_RISCVV(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_Scalar(p, len);
end;

function BytesIndexOf_RISCVV(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(haystack, haystackLen, needle, needleLen);
end;

function BitsetPopCount_RISCVV(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := BitsetPopCount_Scalar(p, byteLen);
end;

{$ELSE}

// =============================================================
// Scalar Fallback Implementations
// =============================================================
// Used when RISC-V V extension is not available

// =============================================================
// F32x4 Operations (128-bit, 4x Single)
// =============================================================

function RISCVVAddF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function RISCVVSubF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function RISCVVMulF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function RISCVVDivF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] / b.f[i];
end;

function RISCVVAbsF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Abs(a.f[i]);
end;

function RISCVVSqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function RISCVVMinF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// =============================================================
// F64x2 Operations (128-bit, 2x Double)
// =============================================================

function RISCVVAddF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function RISCVVSubF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function RISCVVMulF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function RISCVVDivF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// =============================================================
// I32x4 Operations (128-bit, 4x Int32)
// =============================================================

function RISCVVAddI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVMulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVAndI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI32x4(const a: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := not a.i[i];
end;

// =============================================================
// Common Implementations (both assembly and scalar paths)
// =============================================================

// =============================================================
// F32x4 Extended Math Operations
// =============================================================

function RISCVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  // a * b + c
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function RISCVVRcpF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / a.f[i];
end;

function RISCVVRsqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / Sqrt(a.f[i]);
end;

function RISCVVFloorF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Floor(a.f[i]);
end;

function RISCVVCeilF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Ceil(a.f[i]);
end;

function RISCVVRoundF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Round(a.f[i]);
end;

function RISCVVTruncF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Trunc(a.f[i]);
end;

function RISCVVClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
  begin
    if a.f[i] < minVal.f[i] then
      Result.f[i] := minVal.f[i]
    else if a.f[i] > maxVal.f[i] then
      Result.f[i] := maxVal.f[i]
    else
      Result.f[i] := a.f[i];
  end;
end;

// =============================================================
// F32x4 Comparison Operations
// =============================================================

function RISCVVCmpEqF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// I32x4 Comparison Operations
// =============================================================

function RISCVVCmpEqI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// I32x4 Extended Operations
// =============================================================

function RISCVVAndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  // (~a) and b
  for i := 0 to 3 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var i: Integer;
begin
  if (count < 0) or (count >= 32) then
  begin
    for i := 0 to 3 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var i: Integer;
begin
  if (count < 0) or (count >= 32) then
  begin
    for i := 0 to 3 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.i[i] := Int32(UInt32(a.i[i]) shr count);
end;

function RISCVVShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var i: Integer;
begin
  if count < 0 then
  begin
    for i := 0 to 3 do
      Result.i[i] := a.i[i];
    Exit;
  end;

  if count >= 32 then
  begin
    for i := 0 to 3 do
      if a.i[i] < 0 then
        Result.i[i] := -1
      else
        Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.i[i] := SarLongint(a.i[i], count);
end;

function RISCVVMinI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

// =============================================================
// I64x2 Operations (128-bit, 2x Int64)
// =============================================================

function RISCVVAddI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVAndI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI64x2(const a: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := not a.i[i];
end;

// =============================================================
// F32x4 Vector Math Operations
// =============================================================

function RISCVVDotF32x4(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2] + a.f[3] * b.f[3];
end;

function RISCVVDotF32x3(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2];
end;

function RISCVVDotF32x8(const a, b: TVecF32x8): Single;
begin
  Result := ScalarDotF32x8(a, b);
end;

function RISCVVDotF64x2(const a, b: TVecF64x2): Double;
begin
  Result := ScalarDotF64x2(a, b);
end;

function RISCVVDotF64x4(const a, b: TVecF64x4): Double;
begin
  Result := ScalarDotF64x4(a, b);
end;

function RISCVVCrossF32x3(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[1] * b.f[2] - a.f[2] * b.f[1];
  Result.f[1] := a.f[2] * b.f[0] - a.f[0] * b.f[2];
  Result.f[2] := a.f[0] * b.f[1] - a.f[1] * b.f[0];
  Result.f[3] := 0.0;
end;

function RISCVVLengthF32x4(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2] + a.f[3] * a.f[3]);
end;

function RISCVVLengthF32x3(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2]);
end;

function RISCVVNormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var len, invLen: Single;
    i: Integer;
begin
  len := RISCVVLengthF32x4(a);
  if len > 1e-10 then
  begin
    invLen := 1.0 / len;
    for i := 0 to 3 do
      Result.f[i] := a.f[i] * invLen;
  end
  else
    Result := a;
end;

function RISCVVNormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var len, invLen: Single;
begin
  len := RISCVVLengthF32x3(a);
  if len > 1e-10 then
  begin
    invLen := 1.0 / len;
    Result.f[0] := a.f[0] * invLen;
    Result.f[1] := a.f[1] * invLen;
    Result.f[2] := a.f[2] * invLen;
    Result.f[3] := 0.0;
  end
  else
    Result := a;
end;

// =============================================================
// F32x4 Reduction Operations
// =============================================================

function RISCVVReduceAddF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] + a.f[1] + a.f[2] + a.f[3];
end;

function RISCVVReduceMinF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function RISCVVReduceMaxF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function RISCVVReduceMulF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] * a.f[1] * a.f[2] * a.f[3];
end;

// =============================================================
// F32x4 Memory Operations
// =============================================================

function RISCVVLoadF32x4(p: PSingle): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := p[i];
end;

function RISCVVLoadF32x4Aligned(p: PSingle): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := p[i];
end;

procedure RISCVVStoreF32x4(p: PSingle; const a: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.f[i];
end;

procedure RISCVVStoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.f[i];
end;

// =============================================================
// F32x4 Utility Operations
// =============================================================

function RISCVVSplatF32x4(value: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := value;
end;

function RISCVVZeroF32x4: TVecF32x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVExtractF32x4(const a: TVecF32x4; index: Integer): Single;
var
  idx: Integer;
begin
  if index < 0 then
    idx := 0
  else if index > 3 then
    idx := 3
  else
    idx := index;

  Result := a.f[idx];
end;

function RISCVVInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var
  idx: Integer;
begin
  if index < 0 then
    idx := 0
  else if index > 3 then
    idx := 3
  else
    idx := index;

  Result := a;
  Result.f[idx] := value;
end;

// =============================================================
// F32x8 Operations (256-bit, 8x Single)
// =============================================================

function RISCVVAddF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function RISCVVSubF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function RISCVVMulF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function RISCVVDivF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] / b.f[i];
end;

// =============================================================
// F64x4 Operations (256-bit, 4x Double)
// =============================================================

function RISCVVAddF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function RISCVVSubF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function RISCVVMulF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function RISCVVDivF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// =============================================================
// I32x8 Operations (256-bit, 8x Int32)
// =============================================================

function RISCVVAddI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVMulI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVAndI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI32x8(const a: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := not a.i[i];
end;

function RISCVVAndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := Int32(UInt32(a.i[i]) shr count);
end;

function RISCVVShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := SarLongint(a.i[i], count);
end;

function RISCVVCmpEqI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVMinI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

// =============================================================
// I32x16 Operations (512-bit, 16x Int32)
// =============================================================

function RISCVVAddI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVMulI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVAndI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI32x16(const a: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := not a.i[i];
end;

function RISCVVAndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := Int32(UInt32(a.i[i]) shr count);
end;

function RISCVVShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := SarLongint(a.i[i], count);
end;

function RISCVVCmpEqI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVMinI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

// =============================================================
// F32x16 Operations (512-bit, 16x Single)
// =============================================================

function RISCVVAddF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function RISCVVSubF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function RISCVVMulF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function RISCVVDivF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] / b.f[i];
end;

// =============================================================
// F64x8 Operations (512-bit, 8x Double)
// =============================================================

function RISCVVAddF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function RISCVVSubF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function RISCVVMulF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function RISCVVDivF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// =============================================================
// F32x8 Comparison Operations (256-bit, 8x Single)
// =============================================================

function RISCVVCmpEqF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// F64x4 Comparison Operations (256-bit, 4x Double)
// =============================================================

function RISCVVCmpEqF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] = b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] < b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] <= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] > b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] >= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] <> b.d[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// F64x8 Comparison Operations (512-bit, 8x Double)
// =============================================================

function RISCVVCmpEqF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] = b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] < b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] <= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] > b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] >= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] <> b.d[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// F32x16 Comparison Operations (512-bit, 16x Single)
// =============================================================

function RISCVVCmpEqF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// TMask4 Operations (4 有效位)
// =============================================================

function RISCVVMask4All(mask: TMask4): Boolean;
begin
  Result := (mask and $0F) = $0F;
end;

function RISCVVMask4Any(mask: TMask4): Boolean;
begin
  Result := (mask and $0F) <> 0;
end;

function RISCVVMask4None(mask: TMask4): Boolean;
begin
  Result := (mask and $0F) = 0;
end;

function RISCVVMask4PopCount(mask: TMask4): Integer;
var
  m: Byte;
begin
  m := mask and $0F;
  Result := 0;
  while m <> 0 do
  begin
    Inc(Result, m and 1);
    m := m shr 1;
  end;
end;

function RISCVVMask4FirstSet(mask: TMask4): Integer;
var
  m: Byte;
  i: Integer;
begin
  m := mask and $0F;
  if m = 0 then
  begin
    Result := -1;
    Exit;
  end;
  for i := 0 to 3 do
  begin
    if (m and (1 shl i)) <> 0 then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

// =============================================================
// TMask8 Operations (8 有效位)
// =============================================================

function RISCVVMask8All(mask: TMask8): Boolean;
begin
  Result := mask = $FF;
end;

function RISCVVMask8Any(mask: TMask8): Boolean;
begin
  Result := mask <> 0;
end;

function RISCVVMask8None(mask: TMask8): Boolean;
begin
  Result := mask = 0;
end;

function RISCVVMask8PopCount(mask: TMask8): Integer;
var
  m: Byte;
begin
  m := mask;
  Result := 0;
  while m <> 0 do
  begin
    Inc(Result, m and 1);
    m := m shr 1;
  end;
end;

function RISCVVMask8FirstSet(mask: TMask8): Integer;
var
  m: Byte;
  i: Integer;
begin
  m := mask;
  if m = 0 then
  begin
    Result := -1;
    Exit;
  end;
  for i := 0 to 7 do
  begin
    if (m and (1 shl i)) <> 0 then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

// =============================================================
// TMask16 Operations (16 有效位)
// =============================================================

function RISCVVMask16All(mask: TMask16): Boolean;
begin
  Result := mask = $FFFF;
end;

function RISCVVMask16Any(mask: TMask16): Boolean;
begin
  Result := mask <> 0;
end;

function RISCVVMask16None(mask: TMask16): Boolean;
begin
  Result := mask = 0;
end;

function RISCVVMask16PopCount(mask: TMask16): Integer;
var
  m: Word;
begin
  m := mask;
  Result := 0;
  while m <> 0 do
  begin
    Inc(Result, m and 1);
    m := m shr 1;
  end;
end;

function RISCVVMask16FirstSet(mask: TMask16): Integer;
var
  m: Word;
  i: Integer;
begin
  m := mask;
  if m = 0 then
  begin
    Result := -1;
    Exit;
  end;
  for i := 0 to 15 do
  begin
    if (m and (1 shl i)) <> 0 then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

// =============================================================
// Mask Logical Operations (TMask4)
// =============================================================

function RISCVVMask4And(a, b: TMask4): TMask4;
begin
  Result := (a and b) and $0F;
end;

function RISCVVMask4Or(a, b: TMask4): TMask4;
begin
  Result := (a or b) and $0F;
end;

function RISCVVMask4Xor(a, b: TMask4): TMask4;
begin
  Result := (a xor b) and $0F;
end;

function RISCVVMask4Not(a: TMask4): TMask4;
begin
  Result := (not a) and $0F;
end;

// =============================================================
// Mask Logical Operations (TMask8)
// =============================================================

function RISCVVMask8And(a, b: TMask8): TMask8;
begin
  Result := a and b;
end;

function RISCVVMask8Or(a, b: TMask8): TMask8;
begin
  Result := a or b;
end;

function RISCVVMask8Xor(a, b: TMask8): TMask8;
begin
  Result := a xor b;
end;

function RISCVVMask8Not(a: TMask8): TMask8;
begin
  Result := not a;
end;

// =============================================================
// Mask Logical Operations (TMask16)
// =============================================================

function RISCVVMask16And(a, b: TMask16): TMask16;
begin
  Result := a and b;
end;

function RISCVVMask16Or(a, b: TMask16): TMask16;
begin
  Result := a or b;
end;

function RISCVVMask16Xor(a, b: TMask16): TMask16;
begin
  Result := a xor b;
end;

function RISCVVMask16Not(a: TMask16): TMask16;
begin
  Result := not a;
end;

// =============================================================
// F32x8 Select Operation
// =============================================================

function RISCVVSelectF32x8(const mask: TMask8; const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// =============================================================
// F64x4 Select Operation
// =============================================================

function RISCVVSelectF64x4(const mask: TMask4; const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

// =============================================================
// F32x16 Select Operation
// =============================================================

function RISCVVSelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// =============================================================
// F64x8 Select Operation
// =============================================================

function RISCVVSelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

// =============================================================
// Additional Operations for 100% Coverage
// =============================================================
// Generated implementations for missing operations
// =============================================================

function RISCVVMask2All(mask: TMask2): Boolean;
begin
  Result := (mask and $03) = $03;
end;

function RISCVVMask2Any(mask: TMask2): Boolean;
begin
  Result := (mask and $03) <> 0;
end;

function RISCVVMask2None(mask: TMask2): Boolean;
begin
  Result := (mask and $03) = 0;
end;

function RISCVVMask2PopCount(mask: TMask2): Integer;
var m: Byte;
begin
  m := mask and $03;
  Result := (m and 1) + ((m shr 1) and 1);
end;

function RISCVVMask2FirstSet(mask: TMask2): Integer;
var m: Byte;
begin
  m := mask and $03;
  if m = 0 then Result := -1
  else if (m and 1) <> 0 then Result := 0
  else Result := 1;
end;

function RISCVVAbsF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Abs(a.f[i]);
end;

function RISCVVAbsF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Abs(a.f[i]);
end;

function RISCVVAbsF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Abs(a.d[i]);
end;

function RISCVVAbsF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Abs(a.d[i]);
end;

function RISCVVAbsF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Abs(a.d[i]);
end;

function RISCVVAddI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarAddI16x32(a, b);
end;

function RISCVVSubI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarSubI16x32(a, b);
end;

function RISCVVAndI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarAndI16x32(a, b);
end;

function RISCVVOrI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarOrI16x32(a, b);
end;

function RISCVVXorI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarXorI16x32(a, b);
end;

function RISCVVNotI16x32(const a: TVecI16x32): TVecI16x32;
begin
  Result := ScalarNotI16x32(a);
end;

function RISCVVAndNotI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarAndNotI16x32(a, b);
end;

function RISCVVCmpEqI16x32(const a, b: TVecI16x32): TMask32;
begin
  Result := ScalarCmpEqI16x32(a, b);
end;

function RISCVVCmpLtI16x32(const a, b: TVecI16x32): TMask32;
begin
  Result := ScalarCmpLtI16x32(a, b);
end;

function RISCVVCmpGtI16x32(const a, b: TVecI16x32): TMask32;
begin
  Result := ScalarCmpGtI16x32(a, b);
end;

function RISCVVMinI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarMinI16x32(a, b);
end;

function RISCVVMaxI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarMaxI16x32(a, b);
end;

function RISCVVShiftLeftI16x32(const a: TVecI16x32; count: Integer): TVecI16x32;
begin
  Result := ScalarShiftLeftI16x32(a, count);
end;

function RISCVVShiftRightI16x32(const a: TVecI16x32; count: Integer): TVecI16x32;
begin
  Result := ScalarShiftRightI16x32(a, count);
end;

function RISCVVShiftRightArithI16x32(const a: TVecI16x32; count: Integer): TVecI16x32;
begin
  Result := ScalarShiftRightArithI16x32(a, count);
end;

function RISCVVAddI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarAddI8x64(a, b);
end;

function RISCVVSubI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarSubI8x64(a, b);
end;

function RISCVVAndI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarAndI8x64(a, b);
end;

function RISCVVOrI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarOrI8x64(a, b);
end;

function RISCVVXorI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarXorI8x64(a, b);
end;

function RISCVVNotI8x64(const a: TVecI8x64): TVecI8x64;
begin
  Result := ScalarNotI8x64(a);
end;

function RISCVVAndNotI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarAndNotI8x64(a, b);
end;

function RISCVVCmpEqI8x64(const a, b: TVecI8x64): TMask64;
begin
  Result := ScalarCmpEqI8x64(a, b);
end;

function RISCVVCmpLtI8x64(const a, b: TVecI8x64): TMask64;
begin
  Result := ScalarCmpLtI8x64(a, b);
end;

function RISCVVCmpGtI8x64(const a, b: TVecI8x64): TMask64;
begin
  Result := ScalarCmpGtI8x64(a, b);
end;

function RISCVVMinI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarMinI8x64(a, b);
end;

function RISCVVMaxI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarMaxI8x64(a, b);
end;

function RISCVVAddU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarAddU8x64(a, b);
end;

function RISCVVSubU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarSubU8x64(a, b);
end;

function RISCVVAndU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarAndU8x64(a, b);
end;

function RISCVVOrU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarOrU8x64(a, b);
end;

function RISCVVXorU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarXorU8x64(a, b);
end;

function RISCVVNotU8x64(const a: TVecU8x64): TVecU8x64;
begin
  Result := ScalarNotU8x64(a);
end;

function RISCVVCmpEqU8x64(const a, b: TVecU8x64): TMask64;
begin
  Result := ScalarCmpEqU8x64(a, b);
end;

function RISCVVCmpLtU8x64(const a, b: TVecU8x64): TMask64;
begin
  Result := ScalarCmpLtU8x64(a, b);
end;

function RISCVVCmpGtU8x64(const a, b: TVecU8x64): TMask64;
begin
  Result := ScalarCmpGtU8x64(a, b);
end;

function RISCVVMinU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarMinU8x64(a, b);
end;

function RISCVVMaxU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarMaxU8x64(a, b);
end;

function RISCVVAddU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarAddU32x16(a, b);
end;

function RISCVVSubU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarSubU32x16(a, b);
end;

function RISCVVMulU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarMulU32x16(a, b);
end;

function RISCVVAndU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarAndU32x16(a, b);
end;

function RISCVVOrU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarOrU32x16(a, b);
end;

function RISCVVXorU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarXorU32x16(a, b);
end;

function RISCVVNotU32x16(const a: TVecU32x16): TVecU32x16;
begin
  Result := ScalarNotU32x16(a);
end;

function RISCVVAndNotU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarAndNotU32x16(a, b);
end;

function RISCVVShiftLeftU32x16(const a: TVecU32x16; count: Integer): TVecU32x16;
begin
  Result := ScalarShiftLeftU32x16(a, count);
end;

function RISCVVShiftRightU32x16(const a: TVecU32x16; count: Integer): TVecU32x16;
begin
  Result := ScalarShiftRightU32x16(a, count);
end;

function RISCVVCmpEqU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpEqU32x16(a, b);
end;

function RISCVVCmpLtU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpLtU32x16(a, b);
end;

function RISCVVCmpGtU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpGtU32x16(a, b);
end;

function RISCVVCmpLeU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpLeU32x16(a, b);
end;

function RISCVVCmpGeU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpGeU32x16(a, b);
end;

function RISCVVCmpNeU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpNeU32x16(a, b);
end;

function RISCVVMinU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarMinU32x16(a, b);
end;

function RISCVVMaxU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarMaxU32x16(a, b);
end;

function RISCVVAddU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarAddU64x8(a, b);
end;

function RISCVVSubU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarSubU64x8(a, b);
end;

function RISCVVAndU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarAndU64x8(a, b);
end;

function RISCVVOrU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarOrU64x8(a, b);
end;

function RISCVVXorU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarXorU64x8(a, b);
end;

function RISCVVNotU64x8(const a: TVecU64x8): TVecU64x8;
begin
  Result := ScalarNotU64x8(a);
end;

function RISCVVShiftLeftU64x8(const a: TVecU64x8; count: Integer): TVecU64x8;
begin
  Result := ScalarShiftLeftU64x8(a, count);
end;

function RISCVVShiftRightU64x8(const a: TVecU64x8; count: Integer): TVecU64x8;
begin
  Result := ScalarShiftRightU64x8(a, count);
end;

function RISCVVCmpEqU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpEqU64x8(a, b);
end;

function RISCVVCmpLtU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpLtU64x8(a, b);
end;

function RISCVVCmpGtU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpGtU64x8(a, b);
end;

function RISCVVCmpLeU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpLeU64x8(a, b);
end;

function RISCVVCmpGeU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpGeU64x8(a, b);
end;

function RISCVVCmpNeU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpNeU64x8(a, b);
end;

function RISCVVAddI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVAddU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVAddU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] + b.u[i];
end;

// ✅ U32x8 Operations (256-bit)
function RISCVVAddU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVSubU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVMulU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] * b.u[i];
end;

function RISCVVAndU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVOrU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVXorU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVNotU32x8(const a: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := not a.u[i];
end;

function RISCVVAndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function RISCVVShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVCmpEqU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVMinU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMaxU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

// ✅ RcpF64x4 (Reciprocal)
function RISCVVRcpF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] <> 0.0 then
      Result.d[i] := 1.0 / a.d[i]
    else
      Result.d[i] := 0.0;
end;

function RISCVVAddU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVAndI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVAndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVAndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function RISCVVAndU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVAndU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVAndU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVAndU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVCeilF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Ceil(a.f[i]);
end;

function RISCVVCeilF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Ceil(a.f[i]);
end;

function RISCVVCeilF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Ceil(a.d[i]);
end;

function RISCVVCeilF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Ceil(a.d[i]);
end;

function RISCVVCeilF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Ceil(a.d[i]);
end;

function RISCVVClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
  begin
    if a.f[i] < minVal.f[i] then
      Result.f[i] := minVal.f[i]
    else if a.f[i] > maxVal.f[i] then
      Result.f[i] := maxVal.f[i]
    else
      Result.f[i] := a.f[i];
  end;
end;

function RISCVVClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
  begin
    if a.f[i] < minVal.f[i] then
      Result.f[i] := minVal.f[i]
    else if a.f[i] > maxVal.f[i] then
      Result.f[i] := maxVal.f[i]
    else
      Result.f[i] := a.f[i];
  end;
end;

function RISCVVClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
  begin
    if a.d[i] < minVal.d[i] then
      Result.d[i] := minVal.d[i]
    else if a.d[i] > maxVal.d[i] then
      Result.d[i] := maxVal.d[i]
    else
      Result.d[i] := a.d[i];
  end;
end;

function RISCVVClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
  begin
    if a.d[i] < minVal.d[i] then
      Result.d[i] := minVal.d[i]
    else if a.d[i] > maxVal.d[i] then
      Result.d[i] := maxVal.d[i]
    else
      Result.d[i] := a.d[i];
  end;
end;

function RISCVVClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
  begin
    if a.d[i] < minVal.d[i] then
      Result.d[i] := minVal.d[i]
    else if a.d[i] > maxVal.d[i] then
      Result.d[i] := maxVal.d[i]
    else
      Result.d[i] := a.d[i];
  end;
end;

function RISCVVCmpEqF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] = b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] >= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] > b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] <= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] < b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] <> b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVExtractF32x16(const a: TVecF32x16; index: Integer): Single;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a.f[index];
end;

function RISCVVExtractF32x8(const a: TVecF32x8; index: Integer): Single;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a.f[index];
end;

function RISCVVExtractF64x2(const a: TVecF64x2; index: Integer): Double;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a.d[index];
end;

function RISCVVExtractF64x4(const a: TVecF64x4; index: Integer): Double;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a.d[index];
end;

function RISCVVExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a.i[index];
end;

function RISCVVExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a.i[index];
end;

function RISCVVExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a.i[index];
end;

function RISCVVExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a.i[index];
end;

function RISCVVExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a.i[index];
end;

function RISCVVFloorF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Floor(a.f[i]);
end;

function RISCVVFloorF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Floor(a.f[i]);
end;

function RISCVVFloorF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Floor(a.d[i]);
end;

function RISCVVFloorF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Floor(a.d[i]);
end;

function RISCVVFloorF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Floor(a.d[i]);
end;

function RISCVVFmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function RISCVVFmaF32x8(const a, b, c: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function RISCVVFmaF64x2(const a, b, c: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i] + c.d[i];
end;

function RISCVVFmaF64x4(const a, b, c: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] * b.d[i] + c.d[i];
end;

function RISCVVFmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] * b.d[i] + c.d[i];
end;

function RISCVVSatAddI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
    sum: Int16;
begin
  for i := 0 to 15 do
  begin
    sum := Int16(a.i[i]) + Int16(b.i[i]);
    if sum > 127 then
      Result.i[i] := 127
    else if sum < -128 then
      Result.i[i] := -128
    else
      Result.i[i] := Int8(sum);
  end;
end;

function RISCVVSatSubI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
    diff: Int16;
begin
  for i := 0 to 15 do
  begin
    diff := Int16(a.i[i]) - Int16(b.i[i]);
    if diff > 127 then
      Result.i[i] := 127
    else if diff < -128 then
      Result.i[i] := -128
    else
      Result.i[i] := Int8(diff);
  end;
end;

function RISCVVSatAddI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
    sum: Int32;
begin
  for i := 0 to 7 do
  begin
    sum := Int32(a.i[i]) + Int32(b.i[i]);
    if sum > 32767 then
      Result.i[i] := 32767
    else if sum < -32768 then
      Result.i[i] := -32768
    else
      Result.i[i] := Int16(sum);
  end;
end;

function RISCVVSatSubI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
    diff: Int32;
begin
  for i := 0 to 7 do
  begin
    diff := Int32(a.i[i]) - Int32(b.i[i]);
    if diff > 32767 then
      Result.i[i] := 32767
    else if diff < -32768 then
      Result.i[i] := -32768
    else
      Result.i[i] := Int16(diff);
  end;
end;

function RISCVVSatAddU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
    sum: Word;
begin
  for i := 0 to 15 do
  begin
    sum := Word(a.u[i]) + Word(b.u[i]);
    if sum > 255 then
      Result.u[i] := 255
    else
      Result.u[i] := Byte(sum);
  end;
end;

function RISCVVSatSubU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
  begin
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i] - b.u[i]
    else
      Result.u[i] := 0;
  end;
end;

function RISCVVSatAddU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
    sum: UInt32;
begin
  for i := 0 to 7 do
  begin
    sum := UInt32(a.u[i]) + UInt32(b.u[i]);
    if sum > 65535 then
      Result.u[i] := 65535
    else
      Result.u[i] := Word(sum);
  end;
end;

function RISCVVSatSubU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
  begin
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i] - b.u[i]
    else
      Result.u[i] := 0;
  end;
end;

function RISCVVInsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a;
  Result.f[index] := value;
end;

function RISCVVInsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a;
  Result.f[index] := value;
end;

function RISCVVInsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a;
  Result.d[index] := value;
end;

function RISCVVInsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a;
  Result.d[index] := value;
end;

function RISCVVInsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVLoadF32x16(p: PSingle): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := p[i];
end;

function RISCVVLoadF32x8(p: PSingle): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := p[i];
end;

function RISCVVLoadF64x2(p: PDouble): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := p[i];
end;

function RISCVVLoadF64x4(p: PDouble): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := p[i];
end;

function RISCVVLoadF64x8(p: PDouble): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := p[i];
end;

function RISCVVLoadI64x4(p: PInt64): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := p[i];
end;

function RISCVVMaxF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMaxF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMaxF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMaxF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMaxF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMaxI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMaxU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMaxU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMinF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMinF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMinF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMinF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMinF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMinI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMinI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMinU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMinU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMinU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMulI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVMulU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] * b.u[i];
end;

function RISCVVMulU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] * b.u[i];
end;

function RISCVVNotI16x8(const a: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotI64x4(const a: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotI64x8(const a: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotI8x16(const a: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotU16x8(const a: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := not a.u[i];
end;

function RISCVVNotU32x4(const a: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := not a.u[i];
end;

function RISCVVNotU64x4(const a: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := not a.u[i];
end;

function RISCVVNotU8x16(const a: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := not a.u[i];
end;

function RISCVVOrI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVOrU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVOrU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVOrU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVReduceAddF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    Result := Result + a.f[i];
end;

function RISCVVReduceAddF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    Result := Result + a.f[i];
end;

function RISCVVReduceAddF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    Result := Result + a.d[i];
end;

function RISCVVReduceAddF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    Result := Result + a.d[i];
end;

function RISCVVReduceAddF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    Result := Result + a.d[i];
end;

function RISCVVReduceMaxF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function RISCVVReduceMaxF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function RISCVVReduceMaxF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    if a.d[i] > Result then
      Result := a.d[i];
end;

function RISCVVReduceMaxF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    if a.d[i] > Result then
      Result := a.d[i];
end;

function RISCVVReduceMaxF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    if a.d[i] > Result then
      Result := a.d[i];
end;

function RISCVVReduceMinF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function RISCVVReduceMinF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function RISCVVReduceMinF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    if a.d[i] < Result then
      Result := a.d[i];
end;

function RISCVVReduceMinF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    if a.d[i] < Result then
      Result := a.d[i];
end;

function RISCVVReduceMinF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    if a.d[i] < Result then
      Result := a.d[i];
end;

function RISCVVReduceMulF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    Result := Result * a.f[i];
end;

function RISCVVReduceMulF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    Result := Result * a.f[i];
end;

function RISCVVReduceMulF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    Result := Result * a.d[i];
end;

function RISCVVReduceMulF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    Result := Result * a.d[i];
end;

function RISCVVReduceMulF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    Result := Result * a.d[i];
end;

function RISCVVRoundF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Round(a.f[i]);
end;

function RISCVVRoundF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Round(a.f[i]);
end;

function RISCVVRoundF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Round(a.d[i]);
end;

function RISCVVRoundF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Round(a.d[i]);
end;

function RISCVVRoundF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Round(a.d[i]);
end;

function RISCVVSelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if mask.u[i] <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVSelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if mask.u[i] <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVSelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if mask.i[i] <> 0 then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
var i: Integer;
begin
  if (count < 0) or (count >= 64) then
  begin
    for i := 0 to 3 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
var i: Integer;
begin
  if (count < 0) or (count >= 64) then
  begin
    for i := 0 to 3 do
      Result.u[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := SarSmallint(a.i[i], count);
end;

function RISCVVShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] shr count;
end;

function RISCVVShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
var i: Integer;
begin
  if (count < 0) or (count >= 64) then
  begin
    for i := 0 to 3 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.i[i] := Int64(UInt64(a.i[i]) shr count);
end;

function RISCVVShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
var i: Integer;
begin
  if (count < 0) or (count >= 64) then
  begin
    for i := 0 to 3 do
      Result.u[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVSplatF32x16(value: Single): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := value;
end;

function RISCVVSplatF32x8(value: Single): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := value;
end;

function RISCVVSplatF64x2(value: Double): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := value;
end;

function RISCVVSplatF64x4(value: Double): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := value;
end;

function RISCVVSplatF64x8(value: Double): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := value;
end;

function RISCVVSplatI64x4(value: Int64): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := value;
end;

function RISCVVSqrtF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function RISCVVSqrtF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function RISCVVSqrtF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Sqrt(a.d[i]);
end;

function RISCVVSqrtF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Sqrt(a.d[i]);
end;

function RISCVVSqrtF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Sqrt(a.d[i]);
end;

procedure RISCVVStoreF32x16(p: PSingle; const a: TVecF32x16);
var i: Integer;
begin
  for i := 0 to 15 do
    p[i] := a.f[i];
end;

procedure RISCVVStoreF32x8(p: PSingle; const a: TVecF32x8);
var i: Integer;
begin
  for i := 0 to 7 do
    p[i] := a.f[i];
end;

procedure RISCVVStoreF64x2(p: PDouble; const a: TVecF64x2);
var i: Integer;
begin
  for i := 0 to 1 do
    p[i] := a.d[i];
end;

procedure RISCVVStoreF64x4(p: PDouble; const a: TVecF64x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.d[i];
end;

procedure RISCVVStoreF64x8(p: PDouble; const a: TVecF64x8);
var i: Integer;
begin
  for i := 0 to 7 do
    p[i] := a.d[i];
end;

procedure RISCVVStoreI64x4(p: PInt64; const a: TVecI64x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.i[i];
end;

function RISCVVSubI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVSubU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVSubU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVSubU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVTruncF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Trunc(a.f[i]);
end;

function RISCVVTruncF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Trunc(a.f[i]);
end;

function RISCVVTruncF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Trunc(a.d[i]);
end;

function RISCVVTruncF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Trunc(a.d[i]);
end;

function RISCVVTruncF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Trunc(a.d[i]);
end;

function RISCVVXorI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVXorU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVXorU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVXorU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVZeroF32x16: TVecF32x16;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF32x8: TVecF32x8;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF64x2: TVecF64x2;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF64x4: TVecF64x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF64x8: TVecF64x8;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroI64x4: TVecI64x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

// =============================================================
// Facade Function Implementations
// =============================================================
// These delegate to the scalar backend's implementations

function MemEqual_RISCVV(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := MemEqual_Scalar(a, b, len);
end;

function MemFindByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  Result := MemFindByte_Scalar(p, len, value);
end;

function MemDiffRange_RISCVV(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  Result := MemDiffRange_Scalar(a, b, len, firstDiff, lastDiff);
end;

procedure MemCopy_RISCVV(src, dst: Pointer; len: SizeUInt);
begin
  MemCopy_Scalar(src, dst, len);
end;

procedure MemSet_RISCVV(dst: Pointer; len: SizeUInt; value: Byte);
begin
  MemSet_Scalar(dst, len, value);
end;

procedure MemReverse_RISCVV(p: Pointer; len: SizeUInt);
begin
  MemReverse_Scalar(p, len);
end;

function SumBytes_RISCVV(p: Pointer; len: SizeUInt): UInt64;
begin
  Result := SumBytes_Scalar(p, len);
end;

procedure MinMaxBytes_RISCVV(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
begin
  MinMaxBytes_Scalar(p, len, minVal, maxVal);
end;

function CountByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := CountByte_Scalar(p, len, value);
end;

function Utf8Validate_RISCVV(p: Pointer; len: SizeUInt): Boolean;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function AsciiIEqual_RISCVV(a, b: Pointer; len: SizeUInt): Boolean;
begin
  Result := AsciiIEqual_Scalar(a, b, len);
end;

procedure ToLowerAscii_RISCVV(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_Scalar(p, len);
end;

procedure ToUpperAscii_RISCVV(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_Scalar(p, len);
end;

function BytesIndexOf_RISCVV(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(haystack, haystackLen, needle, needleLen);
end;

function BitsetPopCount_RISCVV(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := BitsetPopCount_Scalar(p, byteLen);
end;

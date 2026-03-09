// === Utility Operations ===

function NEONSplatF32x4(value: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := value;
end;

function NEONZeroF32x4: TVecF32x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function NEONSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function NEONExtractF32x4(const a: TVecF32x4; index: Integer): Single;
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

function NEONInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
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

{$I fafafa.core.simd.neon.facade_scalar.inc}

// ✅ P2: Saturating Arithmetic Scalar Fallback
// 用于 FPC < 3.3.1 或非 ARM 平台

function NEONI8x16SatAdd(const a, b: TVecI8x16): TVecI8x16;
begin
  Result := ScalarI8x16SatAdd(a, b);
end;

function NEONI8x16SatSub(const a, b: TVecI8x16): TVecI8x16;
begin
  Result := ScalarI8x16SatSub(a, b);
end;

function NEONI16x8SatAdd(const a, b: TVecI16x8): TVecI16x8;
begin
  Result := ScalarI16x8SatAdd(a, b);
end;

function NEONI16x8SatSub(const a, b: TVecI16x8): TVecI16x8;
begin
  Result := ScalarI16x8SatSub(a, b);
end;

function NEONU8x16SatAdd(const a, b: TVecU8x16): TVecU8x16;
begin
  Result := ScalarU8x16SatAdd(a, b);
end;

function NEONU8x16SatSub(const a, b: TVecU8x16): TVecU8x16;
begin
  Result := ScalarU8x16SatSub(a, b);
end;

function NEONU16x8SatAdd(const a, b: TVecU16x8): TVecU16x8;
begin
  Result := ScalarU16x8SatAdd(a, b);
end;

function NEONU16x8SatSub(const a, b: TVecU16x8): TVecU16x8;
begin
  Result := ScalarU16x8SatSub(a, b);
end;

// ✅ Task 6.2: Narrow Integer Types Scalar Fallback
// 用于 FPC < 3.3.1 或非 ARM 平台

// --- I16x8 Scalar Fallback ---
function NEONAddI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarAddI16x8(a, b); end;

function NEONSubI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarSubI16x8(a, b); end;

function NEONMulI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarMulI16x8(a, b); end;

function NEONAndI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarAndI16x8(a, b); end;

function NEONOrI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarOrI16x8(a, b); end;

function NEONXorI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarXorI16x8(a, b); end;

function NEONNotI16x8(const a: TVecI16x8): TVecI16x8;
begin Result := ScalarNotI16x8(a); end;

function NEONAndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarAndNotI16x8(a, b); end;

function NEONMinI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarMinI16x8(a, b); end;

function NEONMaxI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarMaxI16x8(a, b); end;

// --- I8x16 Scalar Fallback ---
function NEONAddI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarAddI8x16(a, b); end;

function NEONSubI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarSubI8x16(a, b); end;

function NEONAndI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarAndI8x16(a, b); end;

function NEONOrI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarOrI8x16(a, b); end;

function NEONXorI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarXorI8x16(a, b); end;

function NEONNotI8x16(const a: TVecI8x16): TVecI8x16;
begin Result := ScalarNotI8x16(a); end;

function NEONMinI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarMinI8x16(a, b); end;

function NEONMaxI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarMaxI8x16(a, b); end;

// --- U16x8 Scalar Fallback ---
function NEONAddU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarAddU16x8(a, b); end;

function NEONSubU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarSubU16x8(a, b); end;

function NEONMulU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarMulU16x8(a, b); end;

function NEONAndU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarAndU16x8(a, b); end;

function NEONOrU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarOrU16x8(a, b); end;

function NEONXorU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarXorU16x8(a, b); end;

function NEONNotU16x8(const a: TVecU16x8): TVecU16x8;
begin Result := ScalarNotU16x8(a); end;

function NEONMinU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarMinU16x8(a, b); end;

function NEONMaxU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarMaxU16x8(a, b); end;

// --- U8x16 Scalar Fallback ---
function NEONAddU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarAddU8x16(a, b); end;

function NEONSubU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarSubU8x16(a, b); end;

function NEONAndU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarAndU8x16(a, b); end;

function NEONOrU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarOrU8x16(a, b); end;

function NEONXorU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarXorU8x16(a, b); end;

function NEONNotU8x16(const a: TVecU8x16): TVecU8x16;
begin Result := ScalarNotU8x16(a); end;

function NEONMinU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarMinU8x16(a, b); end;

function NEONMaxU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarMaxU8x16(a, b); end;

// ✅ P3: I64x2 Scalar Fallback (用于 FPC < 3.3.1 或非 ARM 平台)
function NEONAddI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarAddI64x2(a, b);
end;

function NEONSubI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarSubI64x2(a, b);
end;

function NEONAndI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarAndI64x2(a, b);
end;

function NEONOrI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarOrI64x2(a, b);
end;

function NEONXorI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarXorI64x2(a, b);
end;

function NEONNotI64x2(const a: TVecI64x2): TVecI64x2;
begin
  Result := ScalarNotI64x2(a);
end;

function NEONAndNotI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := NEONAndI64x2(NEONNotI64x2(a), b);
end;

function NEONShiftLeftI64x2(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  Result := ScalarShiftLeftI64x2(a, count);
end;

function NEONShiftRightI64x2(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  Result := ScalarShiftRightI64x2(a, count);
end;

function NEONShiftRightArithI64x2(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  Result := ScalarShiftRightArithI64x2(a, count);
end;

function NEONMinI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarMinI64x2(a, b);
end;

function NEONMaxI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarMaxI64x2(a, b);
end;

function NEONAddU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  ai, bi, ri: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  Move(b, bi, SizeOf(bi));
  ri := NEONAddI64x2(ai, bi);
  Move(ri, Result, SizeOf(Result));
end;

function NEONSubU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  ai, bi, ri: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  Move(b, bi, SizeOf(bi));
  ri := NEONSubI64x2(ai, bi);
  Move(ri, Result, SizeOf(Result));
end;

function NEONAndU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  ai, bi, ri: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  Move(b, bi, SizeOf(bi));
  ri := NEONAndI64x2(ai, bi);
  Move(ri, Result, SizeOf(Result));
end;

function NEONOrU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  ai, bi, ri: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  Move(b, bi, SizeOf(bi));
  ri := NEONOrI64x2(ai, bi);
  Move(ri, Result, SizeOf(Result));
end;

function NEONXorU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  ai, bi, ri: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  Move(b, bi, SizeOf(bi));
  ri := NEONXorI64x2(ai, bi);
  Move(ri, Result, SizeOf(Result));
end;

function NEONNotU64x2(const a: TVecU64x2): TVecU64x2;
var
  ai, ri: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  ri := NEONNotI64x2(ai);
  Move(ri, Result, SizeOf(Result));
end;

function NEONAndNotU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  ai, bi, ri: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  Move(b, bi, SizeOf(bi));
  ri := NEONAndNotI64x2(ai, bi);
  Move(ri, Result, SizeOf(Result));
end;

function NEONCmpEqI64x2(const a, b: TVecI64x2): TMask2; forward;
function NEONCmpLtI64x2(const a, b: TVecI64x2): TMask2; forward;
function NEONCmpGtI64x2(const a, b: TVecI64x2): TMask2; forward;

function NEONCmpEqU64x2(const a, b: TVecU64x2): TMask2;
var
  ai, bi: TVecI64x2;
begin
  Move(a, ai, SizeOf(ai));
  Move(b, bi, SizeOf(bi));
  Result := NEONCmpEqI64x2(ai, bi);
end;

function NEONCmpLtU64x2(const a, b: TVecU64x2): TMask2;
const
  SIGN_MASK: QWord = QWord($8000000000000000);
var
  LAdjustedA, LAdjustedB: TVecI64x2;
begin
  // 将无符号顺序映射到有符号顺序，再复用 I64x2 比较路径
  LAdjustedA.i[0] := Int64(a.u[0] xor SIGN_MASK);
  LAdjustedA.i[1] := Int64(a.u[1] xor SIGN_MASK);
  LAdjustedB.i[0] := Int64(b.u[0] xor SIGN_MASK);
  LAdjustedB.i[1] := Int64(b.u[1] xor SIGN_MASK);
  Result := NEONCmpLtI64x2(LAdjustedA, LAdjustedB);
end;

function NEONCmpGtU64x2(const a, b: TVecU64x2): TMask2;
const
  SIGN_MASK: QWord = QWord($8000000000000000);
var
  LAdjustedA, LAdjustedB: TVecI64x2;
begin
  LAdjustedA.i[0] := Int64(a.u[0] xor SIGN_MASK);
  LAdjustedA.i[1] := Int64(a.u[1] xor SIGN_MASK);
  LAdjustedB.i[0] := Int64(b.u[0] xor SIGN_MASK);
  LAdjustedB.i[1] := Int64(b.u[1] xor SIGN_MASK);
  Result := NEONCmpGtI64x2(LAdjustedA, LAdjustedB);
end;

function NEONMinU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LMask: TMask2;
begin
  LMask := NEONCmpLtU64x2(a, b);
  if (LMask and 1) <> 0 then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if (LMask and 2) <> 0 then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

function NEONMaxU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LMask: TMask2;
begin
  LMask := NEONCmpGtU64x2(a, b);
  if (LMask and 1) <> 0 then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if (LMask and 2) <> 0 then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

function NEONCmpEqI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpEqI64x2(a, b);
end;

function NEONCmpLtI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpLtI64x2(a, b);
end;

function NEONCmpGtI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpGtI64x2(a, b);
end;

function NEONCmpLeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpLeI64x2(a, b);
end;

function NEONCmpGeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpGeI64x2(a, b);
end;

function NEONCmpNeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpNeI64x2(a, b);
end;

// ✅ P4: SelectF64x2 (Pascal Implementation)
function NEONSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

// ✅ P1: Mask Operations (Scalar Fallback)
// NEON 没有直接的 popcount/bsf 指令，使用标量回退
function NEONMask2All(mask: TMask2): Boolean;
begin Result := ScalarMask2All(mask); end;

function NEONMask2Any(mask: TMask2): Boolean;
begin Result := ScalarMask2Any(mask); end;

function NEONMask2None(mask: TMask2): Boolean;
begin Result := ScalarMask2None(mask); end;

function NEONMask2PopCount(mask: TMask2): Integer;
begin Result := ScalarMask2PopCount(mask); end;

function NEONMask2FirstSet(mask: TMask2): Integer;
begin Result := ScalarMask2FirstSet(mask); end;

function NEONMask4All(mask: TMask4): Boolean;
begin Result := ScalarMask4All(mask); end;

function NEONMask4Any(mask: TMask4): Boolean;
begin Result := ScalarMask4Any(mask); end;

function NEONMask4None(mask: TMask4): Boolean;
begin Result := ScalarMask4None(mask); end;

function NEONMask4PopCount(mask: TMask4): Integer;
begin Result := ScalarMask4PopCount(mask); end;

function NEONMask4FirstSet(mask: TMask4): Integer;
begin Result := ScalarMask4FirstSet(mask); end;

function NEONMask8All(mask: TMask8): Boolean;
begin Result := ScalarMask8All(mask); end;

function NEONMask8Any(mask: TMask8): Boolean;
begin Result := ScalarMask8Any(mask); end;

function NEONMask8None(mask: TMask8): Boolean;
begin Result := ScalarMask8None(mask); end;

function NEONMask8PopCount(mask: TMask8): Integer;
begin Result := ScalarMask8PopCount(mask); end;

function NEONMask8FirstSet(mask: TMask8): Integer;
begin Result := ScalarMask8FirstSet(mask); end;

function NEONMask16All(mask: TMask16): Boolean;
begin Result := ScalarMask16All(mask); end;

function NEONMask16Any(mask: TMask16): Boolean;
begin Result := ScalarMask16Any(mask); end;

function NEONMask16None(mask: TMask16): Boolean;
begin Result := ScalarMask16None(mask); end;

function NEONMask16PopCount(mask: TMask16): Integer;
begin Result := ScalarMask16PopCount(mask); end;

function NEONMask16FirstSet(mask: TMask16): Integer;
begin Result := ScalarMask16FirstSet(mask); end;


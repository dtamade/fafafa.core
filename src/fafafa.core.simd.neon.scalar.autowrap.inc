// === Auto-generated NEON Wrapper Functions (Scalar Fallback) ===
// These wrappers delegate to scalar implementations for 100% coverage

function NEONAbsF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONAbsF32x4(a.lo.lo);
  Result.lo.hi := NEONAbsF32x4(a.lo.hi);
  Result.hi.lo := NEONAbsF32x4(a.hi.lo);
  Result.hi.hi := NEONAbsF32x4(a.hi.hi);
end;

function NEONAbsF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONAbsF32x4(a.lo);
  Result.hi := NEONAbsF32x4(a.hi);
end;

function NEONAbsF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Abs(a.d[0]);
  Result.d[1] := Abs(a.d[1]);
end;

function NEONAbsF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONAbsF64x2(a.lo);
  Result.hi := NEONAbsF64x2(a.hi);
end;

function NEONAbsF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONAbsF64x4(a.lo);
  Result.hi := NEONAbsF64x4(a.hi);
end;

function NEONAddF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONAddF32x4(a.lo.lo, b.lo.lo);
  Result.lo.hi := NEONAddF32x4(a.lo.hi, b.lo.hi);
  Result.hi.lo := NEONAddF32x4(a.hi.lo, b.hi.lo);
  Result.hi.hi := NEONAddF32x4(a.hi.hi, b.hi.hi);
end;

function NEONAddF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONAddF64x2(a.lo, b.lo);
  Result.hi := NEONAddF64x2(a.hi, b.hi);
end;

function NEONAddF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONAddF64x4(a.lo, b.lo);
  Result.hi := NEONAddF64x4(a.hi, b.hi);
end;

function NEONAddI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarAddI32x16(a, b);
end;

function NEONAddI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarAddI32x8(a, b);
end;

function NEONAddI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarAddI64x4(a, b);
end;

function NEONAddI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarAddI64x8(a, b);
end;

function NEONAddI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarAddI16x32(a, b);
end;

function NEONSubI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarSubI16x32(a, b);
end;

function NEONAndI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarAndI16x32(a, b);
end;

function NEONOrI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarOrI16x32(a, b);
end;

function NEONXorI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarXorI16x32(a, b);
end;

function NEONNotI16x32(const a: TVecI16x32): TVecI16x32;
begin
  Result := ScalarNotI16x32(a);
end;

function NEONAndNotI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarAndNotI16x32(a, b);
end;

function NEONCmpEqI16x32(const a, b: TVecI16x32): TMask32;
begin
  Result := ScalarCmpEqI16x32(a, b);
end;

function NEONCmpLtI16x32(const a, b: TVecI16x32): TMask32;
begin
  Result := ScalarCmpLtI16x32(a, b);
end;

function NEONCmpGtI16x32(const a, b: TVecI16x32): TMask32;
begin
  Result := ScalarCmpGtI16x32(a, b);
end;

function NEONMinI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarMinI16x32(a, b);
end;

function NEONMaxI16x32(const a, b: TVecI16x32): TVecI16x32;
begin
  Result := ScalarMaxI16x32(a, b);
end;

function NEONShiftLeftI16x32(const a: TVecI16x32; count: Integer): TVecI16x32;
begin
  Result := ScalarShiftLeftI16x32(a, count);
end;

function NEONShiftRightI16x32(const a: TVecI16x32; count: Integer): TVecI16x32;
begin
  Result := ScalarShiftRightI16x32(a, count);
end;

function NEONShiftRightArithI16x32(const a: TVecI16x32; count: Integer): TVecI16x32;
begin
  Result := ScalarShiftRightArithI16x32(a, count);
end;

function NEONAddI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarAddI8x64(a, b);
end;

function NEONSubI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarSubI8x64(a, b);
end;

function NEONAndI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarAndI8x64(a, b);
end;

function NEONOrI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarOrI8x64(a, b);
end;

function NEONXorI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarXorI8x64(a, b);
end;

function NEONNotI8x64(const a: TVecI8x64): TVecI8x64;
begin
  Result := ScalarNotI8x64(a);
end;

function NEONAndNotI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarAndNotI8x64(a, b);
end;

function NEONCmpEqI8x64(const a, b: TVecI8x64): TMask64;
begin
  Result := ScalarCmpEqI8x64(a, b);
end;

function NEONCmpLtI8x64(const a, b: TVecI8x64): TMask64;
begin
  Result := ScalarCmpLtI8x64(a, b);
end;

function NEONCmpGtI8x64(const a, b: TVecI8x64): TMask64;
begin
  Result := ScalarCmpGtI8x64(a, b);
end;

function NEONMinI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarMinI8x64(a, b);
end;

function NEONMaxI8x64(const a, b: TVecI8x64): TVecI8x64;
begin
  Result := ScalarMaxI8x64(a, b);
end;

function NEONAddU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarAddU8x64(a, b);
end;

function NEONSubU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarSubU8x64(a, b);
end;

function NEONAndU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarAndU8x64(a, b);
end;

function NEONOrU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarOrU8x64(a, b);
end;

function NEONXorU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarXorU8x64(a, b);
end;

function NEONNotU8x64(const a: TVecU8x64): TVecU8x64;
begin
  Result := ScalarNotU8x64(a);
end;

function NEONCmpEqU8x64(const a, b: TVecU8x64): TMask64;
begin
  Result := ScalarCmpEqU8x64(a, b);
end;

function NEONCmpLtU8x64(const a, b: TVecU8x64): TMask64;
begin
  Result := ScalarCmpLtU8x64(a, b);
end;

function NEONCmpGtU8x64(const a, b: TVecU8x64): TMask64;
begin
  Result := ScalarCmpGtU8x64(a, b);
end;

function NEONMinU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarMinU8x64(a, b);
end;

function NEONMaxU8x64(const a, b: TVecU8x64): TVecU8x64;
begin
  Result := ScalarMaxU8x64(a, b);
end;

function NEONAddU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarAddU32x16(a, b);
end;

function NEONSubU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarSubU32x16(a, b);
end;

function NEONMulU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarMulU32x16(a, b);
end;

function NEONAndU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarAndU32x16(a, b);
end;

function NEONOrU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarOrU32x16(a, b);
end;

function NEONXorU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarXorU32x16(a, b);
end;

function NEONNotU32x16(const a: TVecU32x16): TVecU32x16;
begin
  Result := ScalarNotU32x16(a);
end;

function NEONAndNotU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarAndNotU32x16(a, b);
end;

function NEONShiftLeftU32x16(const a: TVecU32x16; count: Integer): TVecU32x16;
begin
  Result := ScalarShiftLeftU32x16(a, count);
end;

function NEONShiftRightU32x16(const a: TVecU32x16; count: Integer): TVecU32x16;
begin
  Result := ScalarShiftRightU32x16(a, count);
end;

function NEONCmpEqU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpEqU32x16(a, b);
end;

function NEONCmpLtU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpLtU32x16(a, b);
end;

function NEONCmpGtU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpGtU32x16(a, b);
end;

function NEONCmpLeU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpLeU32x16(a, b);
end;

function NEONCmpGeU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpGeU32x16(a, b);
end;

function NEONCmpNeU32x16(const a, b: TVecU32x16): TMask16;
begin
  Result := ScalarCmpNeU32x16(a, b);
end;

function NEONMinU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarMinU32x16(a, b);
end;

function NEONMaxU32x16(const a, b: TVecU32x16): TVecU32x16;
begin
  Result := ScalarMaxU32x16(a, b);
end;

function NEONAddU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarAddU64x8(a, b);
end;

function NEONSubU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarSubU64x8(a, b);
end;

function NEONAndU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarAndU64x8(a, b);
end;

function NEONOrU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarOrU64x8(a, b);
end;

function NEONXorU64x8(const a, b: TVecU64x8): TVecU64x8;
begin
  Result := ScalarXorU64x8(a, b);
end;

function NEONNotU64x8(const a: TVecU64x8): TVecU64x8;
begin
  Result := ScalarNotU64x8(a);
end;

function NEONShiftLeftU64x8(const a: TVecU64x8; count: Integer): TVecU64x8;
begin
  Result := ScalarShiftLeftU64x8(a, count);
end;

function NEONShiftRightU64x8(const a: TVecU64x8; count: Integer): TVecU64x8;
begin
  Result := ScalarShiftRightU64x8(a, count);
end;

function NEONCmpEqU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpEqU64x8(a, b);
end;

function NEONCmpLtU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpLtU64x8(a, b);
end;

function NEONCmpGtU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpGtU64x8(a, b);
end;

function NEONCmpLeU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpLeU64x8(a, b);
end;

function NEONCmpGeU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpGeU64x8(a, b);
end;

function NEONCmpNeU64x8(const a, b: TVecU64x8): TMask8;
begin
  Result := ScalarCmpNeU64x8(a, b);
end;

function NEONAddU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarAddU32x4(a, b);
end;

function NEONAddU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarAddU32x8(a, b);
end;

function NEONAddU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarAddU64x4(a, b);
end;

function NEONAndI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarAndI32x16(a, b);
end;

function NEONAndI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarAndI32x4(a, b);
end;

function NEONAndI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarAndI32x8(a, b);
end;

function NEONAndI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarAndI64x4(a, b);
end;

function NEONAndI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarAndI64x8(a, b);
end;

function NEONAndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarAndNotI32x16(a, b);
end;

function NEONAndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarAndNotI32x4(a, b);
end;

function NEONAndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarAndNotI32x8(a, b);
end;

function NEONAndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarAndNotI64x4(a, b);
end;

function NEONAndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarAndNotU32x4(a, b);
end;

function NEONAndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarAndNotU32x8(a, b);
end;

function NEONAndU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarAndU32x4(a, b);
end;

function NEONAndU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarAndU32x8(a, b);
end;

function NEONAndU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarAndU64x4(a, b);
end;

function NEONCeilF32x16(const a: TVecF32x16): TVecF32x16;
var
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := Ceil(a.f[i]);
  end;
end;

function NEONCeilF32x8(const a: TVecF32x8): TVecF32x8;
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := Ceil(a.f[i]);
  end;
end;

function NEONCeilF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Ceil(a.d[0]);
  Result.d[1] := Ceil(a.d[1]);
end;

function NEONCeilF64x4(const a: TVecF64x4): TVecF64x4;
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    if IsNan(a.d[i]) or IsInfinite(a.d[i]) then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := Ceil(a.d[i]);
  end;
end;

function NEONCeilF64x8(const a: TVecF64x8): TVecF64x8;
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    if IsNan(a.d[i]) or IsInfinite(a.d[i]) then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := Ceil(a.d[i]);
  end;
end;

function NEONClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONClampF32x4(a.lo.lo, minVal.lo.lo, maxVal.lo.lo);
  Result.lo.hi := NEONClampF32x4(a.lo.hi, minVal.lo.hi, maxVal.lo.hi);
  Result.hi.lo := NEONClampF32x4(a.hi.lo, minVal.hi.lo, maxVal.hi.lo);
  Result.hi.hi := NEONClampF32x4(a.hi.hi, minVal.hi.hi, maxVal.hi.hi);
end;

function NEONClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONClampF32x4(a.lo, minVal.lo, maxVal.lo);
  Result.hi := NEONClampF32x4(a.hi, minVal.hi, maxVal.hi);
end;

function NEONClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2;
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

function NEONClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONClampF64x2(a.lo, minVal.lo, maxVal.lo);
  Result.hi := NEONClampF64x2(a.hi, minVal.hi, maxVal.hi);
end;

function NEONClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONClampF64x4(a.lo, minVal.lo, maxVal.lo);
  Result.hi := NEONClampF64x4(a.hi, minVal.hi, maxVal.hi);
end;

function NEONCmpEqF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpEqF32x16(a, b);
end;

function NEONCmpEqF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpEqF32x8(a, b);
end;

function NEONCmpEqF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] = b.d[0] then Result := Result or 1;
  if a.d[1] = b.d[1] then Result := Result or 2;
end;

function NEONCmpEqF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpEqF64x4(a, b);
end;

function NEONCmpEqF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpEqF64x8(a, b);
end;

function NEONCmpEqI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpEqI16x8(a, b);
end;

function NEONCmpEqI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpEqI32x16(a, b);
end;

function NEONCmpEqI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpEqI32x4(a, b);
end;

function NEONCmpEqI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpEqI32x8(a, b);
end;

function NEONCmpEqI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpEqI64x4(a, b);
end;

function NEONCmpEqI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpEqI64x8(a, b);
end;

function NEONCmpEqI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpEqI8x16(a, b);
end;

function NEONCmpEqU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpEqU16x8(a, b);
end;

function NEONCmpEqU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpEqU32x4(a, b);
end;

function NEONCmpEqU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpEqU32x8(a, b);
end;

function NEONCmpEqU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpEqU64x4(a, b);
end;

function NEONCmpEqU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpEqU8x16(a, b);
end;

function NEONCmpGeF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpGeF32x16(a, b);
end;

function NEONCmpGeF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpGeF32x8(a, b);
end;

function NEONCmpGeF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] >= b.d[0] then Result := Result or 1;
  if a.d[1] >= b.d[1] then Result := Result or 2;
end;

function NEONCmpGeF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpGeF64x4(a, b);
end;

function NEONCmpGeF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpGeF64x8(a, b);
end;

function NEONCmpGeI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpGeI16x8(a, b);
end;

function NEONCmpGeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpGeI32x16(a, b);
end;

function NEONCmpGeI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpGeI32x4(a, b);
end;

function NEONCmpGeI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpGeI32x8(a, b);
end;

function NEONCmpGeI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpGeI64x4(a, b);
end;

function NEONCmpGeI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpGeI64x8(a, b);
end;

function NEONCmpGeI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpGeI8x16(a, b);
end;

function NEONCmpGeU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpGeU16x8(a, b);
end;

function NEONCmpGeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpGeU32x4(a, b);
end;

function NEONCmpGeU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpGeU32x8(a, b);
end;

function NEONCmpGeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpGeU64x4(a, b);
end;

function NEONCmpGeU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpGeU8x16(a, b);
end;

function NEONCmpGtF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpGtF32x16(a, b);
end;

function NEONCmpGtF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpGtF32x8(a, b);
end;

function NEONCmpGtF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] > b.d[0] then Result := Result or 1;
  if a.d[1] > b.d[1] then Result := Result or 2;
end;

function NEONCmpGtF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpGtF64x4(a, b);
end;

function NEONCmpGtF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpGtF64x8(a, b);
end;

function NEONCmpGtI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpGtI16x8(a, b);
end;

function NEONCmpGtI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpGtI32x16(a, b);
end;

function NEONCmpGtI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpGtI32x4(a, b);
end;

function NEONCmpGtI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpGtI32x8(a, b);
end;

function NEONCmpGtI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpGtI64x4(a, b);
end;

function NEONCmpGtI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpGtI64x8(a, b);
end;

function NEONCmpGtI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpGtI8x16(a, b);
end;

function NEONCmpGtU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpGtU16x8(a, b);
end;

function NEONCmpGtU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpGtU32x4(a, b);
end;

function NEONCmpGtU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpGtU32x8(a, b);
end;

function NEONCmpGtU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpGtU64x4(a, b);
end;

function NEONCmpGtU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpGtU8x16(a, b);
end;

function NEONCmpLeF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpLeF32x16(a, b);
end;

function NEONCmpLeF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpLeF32x8(a, b);
end;

function NEONCmpLeF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] <= b.d[0] then Result := Result or 1;
  if a.d[1] <= b.d[1] then Result := Result or 2;
end;

function NEONCmpLeF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpLeF64x4(a, b);
end;

function NEONCmpLeF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpLeF64x8(a, b);
end;

function NEONCmpLeI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpLeI16x8(a, b);
end;

function NEONCmpLeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpLeI32x16(a, b);
end;

function NEONCmpLeI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpLeI32x4(a, b);
end;

function NEONCmpLeI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpLeI32x8(a, b);
end;

function NEONCmpLeI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpLeI64x4(a, b);
end;

function NEONCmpLeI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpLeI64x8(a, b);
end;

function NEONCmpLeI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpLeI8x16(a, b);
end;

function NEONCmpLeU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpLeU16x8(a, b);
end;

function NEONCmpLeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpLeU32x4(a, b);
end;

function NEONCmpLeU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpLeU32x8(a, b);
end;

function NEONCmpLeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpLeU64x4(a, b);
end;

function NEONCmpLeU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpLeU8x16(a, b);
end;

function NEONCmpLtF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpLtF32x16(a, b);
end;

function NEONCmpLtF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpLtF32x8(a, b);
end;

function NEONCmpLtF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] < b.d[0] then Result := Result or 1;
  if a.d[1] < b.d[1] then Result := Result or 2;
end;

function NEONCmpLtF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpLtF64x4(a, b);
end;

function NEONCmpLtF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpLtF64x8(a, b);
end;

function NEONCmpLtI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpLtI16x8(a, b);
end;

function NEONCmpLtI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpLtI32x16(a, b);
end;

function NEONCmpLtI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpLtI32x4(a, b);
end;

function NEONCmpLtI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpLtI32x8(a, b);
end;

function NEONCmpLtI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpLtI64x4(a, b);
end;

function NEONCmpLtI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpLtI64x8(a, b);
end;

function NEONCmpLtI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpLtI8x16(a, b);
end;

function NEONCmpLtU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpLtU16x8(a, b);
end;

function NEONCmpLtU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpLtU32x4(a, b);
end;

function NEONCmpLtU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpLtU32x8(a, b);
end;

function NEONCmpLtU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpLtU64x4(a, b);
end;

function NEONCmpLtU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpLtU8x16(a, b);
end;

function NEONCmpNeF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpNeF32x16(a, b);
end;

function NEONCmpNeF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpNeF32x8(a, b);
end;

function NEONCmpNeF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] <> b.d[0] then Result := Result or 1;
  if a.d[1] <> b.d[1] then Result := Result or 2;
end;

function NEONCmpNeF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpNeF64x4(a, b);
end;

function NEONCmpNeF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpNeF64x8(a, b);
end;

function NEONCmpNeI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpNeI16x8(a, b);
end;

function NEONCmpNeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpNeI32x16(a, b);
end;

function NEONCmpNeI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpNeI32x4(a, b);
end;

function NEONCmpNeI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpNeI32x8(a, b);
end;

function NEONCmpNeI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpNeI64x4(a, b);
end;

function NEONCmpNeI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpNeI64x8(a, b);
end;

function NEONCmpNeI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpNeI8x16(a, b);
end;

function NEONCmpNeU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpNeU16x8(a, b);
end;

function NEONCmpNeU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpNeU32x8(a, b);
end;

function NEONCmpNeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpNeU64x4(a, b);
end;

function NEONCmpNeU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpNeU8x16(a, b);
end;

function NEONDivF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONDivF32x4(a.lo.lo, b.lo.lo);
  Result.lo.hi := NEONDivF32x4(a.lo.hi, b.lo.hi);
  Result.hi.lo := NEONDivF32x4(a.hi.lo, b.hi.lo);
  Result.hi.hi := NEONDivF32x4(a.hi.hi, b.hi.hi);
end;

function NEONDivF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONDivF64x2(a.lo, b.lo);
  Result.hi := NEONDivF64x2(a.hi, b.hi);
end;

function NEONDivF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONDivF64x4(a.lo, b.lo);
  Result.hi := NEONDivF64x4(a.hi, b.hi);
end;

function NEONExtractF32x16(const a: TVecF32x16; index: Integer): Single;
begin
  Result := ScalarExtractF32x16(a, index);
end;

function NEONExtractF32x8(const a: TVecF32x8; index: Integer): Single;
begin
  Result := ScalarExtractF32x8(a, index);
end;

function NEONExtractF64x2(const a: TVecF64x2; index: Integer): Double;
var idx: Integer;
begin
  if index < 0 then idx := 0
  else if index > 1 then idx := 1
  else idx := index;
  Result := a.d[idx];
end;

function NEONExtractF64x4(const a: TVecF64x4; index: Integer): Double;
begin
  Result := ScalarExtractF64x4(a, index);
end;

function NEONExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
begin
  Result := ScalarExtractI32x16(a, index);
end;

function NEONExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
begin
  Result := ScalarExtractI32x4(a, index);
end;

function NEONExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
begin
  Result := ScalarExtractI32x8(a, index);
end;

function NEONExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
begin
  Result := ScalarExtractI64x2(a, index);
end;

function NEONExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
begin
  Result := ScalarExtractI64x4(a, index);
end;

function NEONFloorF32x16(const a: TVecF32x16): TVecF32x16;
var
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := Floor(a.f[i]);
  end;
end;

function NEONFloorF32x8(const a: TVecF32x8): TVecF32x8;
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := Floor(a.f[i]);
  end;
end;

function NEONFloorF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Floor(a.d[0]);
  Result.d[1] := Floor(a.d[1]);
end;

function NEONFloorF64x4(const a: TVecF64x4): TVecF64x4;
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    if IsNan(a.d[i]) or IsInfinite(a.d[i]) then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := Floor(a.d[i]);
  end;
end;

function NEONFloorF64x8(const a: TVecF64x8): TVecF64x8;
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    if IsNan(a.d[i]) or IsInfinite(a.d[i]) then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := Floor(a.d[i]);
  end;
end;

function NEONFmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONFmaF32x4(a.lo.lo, b.lo.lo, c.lo.lo);
  Result.lo.hi := NEONFmaF32x4(a.lo.hi, b.lo.hi, c.lo.hi);
  Result.hi.lo := NEONFmaF32x4(a.hi.lo, b.hi.lo, c.hi.lo);
  Result.hi.hi := NEONFmaF32x4(a.hi.hi, b.hi.hi, c.hi.hi);
end;

function NEONFmaF32x8(const a, b, c: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONFmaF32x4(a.lo, b.lo, c.lo);
  Result.hi := NEONFmaF32x4(a.hi, b.hi, c.hi);
end;

function NEONFmaF64x2(const a, b, c: TVecF64x2): TVecF64x2;
begin
  // Result = a * b + c
  Result.d[0] := a.d[0] * b.d[0] + c.d[0];
  Result.d[1] := a.d[1] * b.d[1] + c.d[1];
end;

function NEONFmaF64x4(const a, b, c: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONFmaF64x2(a.lo, b.lo, c.lo);
  Result.hi := NEONFmaF64x2(a.hi, b.hi, c.hi);
end;

function NEONFmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONFmaF64x4(a.lo, b.lo, c.lo);
  Result.hi := NEONFmaF64x4(a.hi, b.hi, c.hi);
end;

function NEONInsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
begin
  Result := ScalarInsertF32x16(a, value, index);
end;

function NEONInsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
begin
  Result := ScalarInsertF32x8(a, value, index);
end;

function NEONInsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
var idx: Integer;
begin
  if index < 0 then idx := 0
  else if index > 1 then idx := 1
  else idx := index;
  Result := a;
  Result.d[idx] := value;
end;

function NEONInsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
begin
  Result := ScalarInsertF64x4(a, value, index);
end;

function NEONInsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;
begin
  Result := ScalarInsertI32x16(a, value, index);
end;

function NEONInsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
begin
  Result := ScalarInsertI32x4(a, value, index);
end;

function NEONInsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
begin
  Result := ScalarInsertI32x8(a, value, index);
end;

function NEONInsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
begin
  Result := ScalarInsertI64x2(a, value, index);
end;

function NEONInsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
begin
  Result := ScalarInsertI64x4(a, value, index);
end;

function NEONLoadF32x16(p: PSingle): TVecF32x16;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF32x16_ASM(p);
  {$ELSE}
  Result := ScalarLoadF32x16(p);
  {$ENDIF}
end;

function NEONLoadF32x8(p: PSingle): TVecF32x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF32x8_ASM(p);
  {$ELSE}
  Result := ScalarLoadF32x8(p);
  {$ENDIF}
end;

function NEONLoadF64x2(p: PDouble): TVecF64x2;
begin
  Move(p^, Result.d[0], 16);
end;

function NEONLoadF64x4(p: PDouble): TVecF64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF64x4_ASM(p);
  {$ELSE}
  Result := ScalarLoadF64x4(p);
  {$ENDIF}
end;

function NEONLoadF64x8(p: PDouble): TVecF64x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF64x8_ASM(p);
  {$ELSE}
  Result := ScalarLoadF64x8(p);
  {$ENDIF}
end;

function NEONLoadI64x4(p: PInt64): TVecI64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadI64x4_ASM(p);
  {$ELSE}
  Result := ScalarLoadI64x4(p);
  {$ENDIF}
end;

function NEONMaxF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONMaxF32x4(a.lo.lo, b.lo.lo);
  Result.lo.hi := NEONMaxF32x4(a.lo.hi, b.lo.hi);
  Result.hi.lo := NEONMaxF32x4(a.hi.lo, b.hi.lo);
  Result.hi.hi := NEONMaxF32x4(a.hi.hi, b.hi.hi);
end;

function NEONMaxF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONMaxF32x4(a.lo, b.lo);
  Result.hi := NEONMaxF32x4(a.hi, b.hi);
end;

function NEONMaxF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  if a.d[0] > b.d[0] then Result.d[0] := a.d[0] else Result.d[0] := b.d[0];
  if a.d[1] > b.d[1] then Result.d[1] := a.d[1] else Result.d[1] := b.d[1];
end;

function NEONMaxF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONMaxF64x2(a.lo, b.lo);
  Result.hi := NEONMaxF64x2(a.hi, b.hi);
end;

function NEONMaxF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONMaxF64x4(a.lo, b.lo);
  Result.hi := NEONMaxF64x4(a.hi, b.hi);
end;

function NEONMaxI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarMaxI32x16(a, b);
end;

function NEONMaxI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarMaxI32x4(a, b);
end;

function NEONMaxI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarMaxI32x8(a, b);
end;

function NEONMaxU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarMaxU32x4(a, b);
end;

function NEONMaxU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarMaxU32x8(a, b);
end;

function NEONMinF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONMinF32x4(a.lo.lo, b.lo.lo);
  Result.lo.hi := NEONMinF32x4(a.lo.hi, b.lo.hi);
  Result.hi.lo := NEONMinF32x4(a.hi.lo, b.hi.lo);
  Result.hi.hi := NEONMinF32x4(a.hi.hi, b.hi.hi);
end;

function NEONMinF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONMinF32x4(a.lo, b.lo);
  Result.hi := NEONMinF32x4(a.hi, b.hi);
end;

function NEONMinF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  if a.d[0] < b.d[0] then Result.d[0] := a.d[0] else Result.d[0] := b.d[0];
  if a.d[1] < b.d[1] then Result.d[1] := a.d[1] else Result.d[1] := b.d[1];
end;

function NEONMinF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONMinF64x2(a.lo, b.lo);
  Result.hi := NEONMinF64x2(a.hi, b.hi);
end;

function NEONMinF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONMinF64x4(a.lo, b.lo);
  Result.hi := NEONMinF64x4(a.hi, b.hi);
end;

function NEONMinI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarMinI32x16(a, b);
end;

function NEONMinI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarMinI32x4(a, b);
end;

function NEONMinI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarMinI32x8(a, b);
end;

function NEONMinU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarMinU32x4(a, b);
end;

function NEONMinU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarMinU32x8(a, b);
end;

function NEONMulF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONMulF32x4(a.lo.lo, b.lo.lo);
  Result.lo.hi := NEONMulF32x4(a.lo.hi, b.lo.hi);
  Result.hi.lo := NEONMulF32x4(a.hi.lo, b.hi.lo);
  Result.hi.hi := NEONMulF32x4(a.hi.hi, b.hi.hi);
end;

function NEONMulF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONMulF64x2(a.lo, b.lo);
  Result.hi := NEONMulF64x2(a.hi, b.hi);
end;

function NEONMulF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONMulF64x4(a.lo, b.lo);
  Result.hi := NEONMulF64x4(a.hi, b.hi);
end;

function NEONMulI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarMulI32x16(a, b);
end;

function NEONMulI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarMulI32x8(a, b);
end;

function NEONMulU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarMulU32x4(a, b);
end;

function NEONMulU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarMulU32x8(a, b);
end;

function NEONNotI32x16(const a: TVecI32x16): TVecI32x16;
begin
  Result := ScalarNotI32x16(a);
end;

function NEONNotI32x4(const a: TVecI32x4): TVecI32x4;
begin
  Result := ScalarNotI32x4(a);
end;

function NEONNotI32x8(const a: TVecI32x8): TVecI32x8;
begin
  Result := ScalarNotI32x8(a);
end;

function NEONNotI64x4(const a: TVecI64x4): TVecI64x4;
begin
  Result := ScalarNotI64x4(a);
end;

function NEONNotI64x8(const a: TVecI64x8): TVecI64x8;
begin
  Result := ScalarNotI64x8(a);
end;

function NEONNotU32x4(const a: TVecU32x4): TVecU32x4;
begin
  Result := ScalarNotU32x4(a);
end;

function NEONNotU32x8(const a: TVecU32x8): TVecU32x8;
begin
  Result := ScalarNotU32x8(a);
end;

function NEONNotU64x4(const a: TVecU64x4): TVecU64x4;
begin
  Result := ScalarNotU64x4(a);
end;

function NEONOrI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarOrI32x16(a, b);
end;

function NEONOrI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarOrI32x4(a, b);
end;

function NEONOrI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarOrI32x8(a, b);
end;

function NEONOrI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarOrI64x4(a, b);
end;

function NEONOrI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarOrI64x8(a, b);
end;

function NEONOrU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarOrU32x4(a, b);
end;

function NEONOrU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarOrU32x8(a, b);
end;

function NEONOrU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarOrU64x4(a, b);
end;

function NEONRcpF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarRcpF64x4(a);
end;

function NEONReduceAddF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF32x16(a);
  {$ENDIF}
end;

function NEONReduceAddF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF32x8(a);
  {$ENDIF}
end;

function NEONReduceAddF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] + a.d[1];
end;

function NEONReduceAddF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF64x4(a);
  {$ENDIF}
end;

function NEONReduceAddF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF64x8(a);
  {$ENDIF}
end;

function NEONReduceMaxF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF32x16(a);
  {$ENDIF}
end;

function NEONReduceMaxF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF32x8(a);
  {$ENDIF}
end;

function NEONReduceMaxF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] > a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function NEONReduceMaxF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF64x4(a);
  {$ENDIF}
end;

function NEONReduceMaxF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF64x8(a);
  {$ENDIF}
end;

function NEONReduceMinF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF32x16(a);
  {$ENDIF}
end;

function NEONReduceMinF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF32x8(a);
  {$ENDIF}
end;

function NEONReduceMinF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] < a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function NEONReduceMinF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF64x4(a);
  {$ENDIF}
end;

function NEONReduceMinF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF64x8(a);
  {$ENDIF}
end;

function NEONReduceMulF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF32x16(a);
  {$ENDIF}
end;

function NEONReduceMulF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF32x8(a);
  {$ENDIF}
end;

function NEONReduceMulF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] * a.d[1];
end;

function NEONReduceMulF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF64x4(a);
  {$ENDIF}
end;

function NEONReduceMulF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF64x8(a);
  {$ENDIF}
end;

function NEONRoundF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONRoundF32x4(a.lo.lo);
  Result.lo.hi := NEONRoundF32x4(a.lo.hi);
  Result.hi.lo := NEONRoundF32x4(a.hi.lo);
  Result.hi.hi := NEONRoundF32x4(a.hi.hi);
end;

function NEONRoundF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONRoundF32x4(a.lo);
  Result.hi := NEONRoundF32x4(a.hi);
end;

function NEONRoundF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Round(a.d[0]);
  Result.d[1] := Round(a.d[1]);
end;

function NEONRoundF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONRoundF64x2(a.lo);
  Result.hi := NEONRoundF64x2(a.hi);
end;

function NEONRoundF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONRoundF64x4(a.lo);
  Result.hi := NEONRoundF64x4(a.hi);
end;

function NEONSelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarSelectF32x16(mask, a, b);
end;

function NEONSelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarSelectF32x8(mask, a, b);
end;

function NEONSelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarSelectF64x4(mask, a, b);
end;

function NEONSelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarSelectF64x8(mask, a, b);
end;

function NEONSelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarSelectI32x4(mask, a, b);
end;

function NEONShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
begin
  Result := ScalarShiftLeftI16x8(a, count);
end;

function NEONShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
begin
  Result := ScalarShiftLeftI32x16(a, count);
end;

function NEONShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  Result := ScalarShiftLeftI32x4(a, count);
end;

function NEONShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
begin
  Result := ScalarShiftLeftI32x8(a, count);
end;

function NEONShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
begin
  Result := ScalarShiftLeftI64x4(a, count);
end;

function NEONShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
begin
  Result := ScalarShiftLeftU16x8(a, count);
end;

function NEONShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
begin
  Result := ScalarShiftLeftU32x4(a, count);
end;

function NEONShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
begin
  Result := ScalarShiftLeftU32x8(a, count);
end;

function NEONShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
begin
  Result := ScalarShiftLeftU64x4(a, count);
end;

function NEONShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
begin
  Result := ScalarShiftRightArithI16x8(a, count);
end;

function NEONShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
begin
  Result := ScalarShiftRightArithI32x16(a, count);
end;

function NEONShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  Result := ScalarShiftRightArithI32x4(a, count);
end;

function NEONShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
begin
  Result := ScalarShiftRightArithI32x8(a, count);
end;

function NEONShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
begin
  Result := ScalarShiftRightI16x8(a, count);
end;

function NEONShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
begin
  Result := ScalarShiftRightI32x16(a, count);
end;

function NEONShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  Result := ScalarShiftRightI32x4(a, count);
end;

function NEONShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
begin
  Result := ScalarShiftRightI32x8(a, count);
end;

function NEONShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
begin
  Result := ScalarShiftRightI64x4(a, count);
end;

function NEONShiftRightArithI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
begin
  Result := ScalarShiftRightArithI64x4(a, count);
end;

function NEONShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
begin
  Result := ScalarShiftRightU16x8(a, count);
end;

function NEONShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
begin
  Result := ScalarShiftRightU32x4(a, count);
end;

function NEONShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
begin
  Result := ScalarShiftRightU32x8(a, count);
end;

function NEONShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
begin
  Result := ScalarShiftRightU64x4(a, count);
end;

function NEONSplatF32x16(value: Single): TVecF32x16;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF32x16_ASM(value);
  {$ELSE}
  Result := ScalarSplatF32x16(value);
  {$ENDIF}
end;

function NEONSplatF32x8(value: Single): TVecF32x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF32x8_ASM(value);
  {$ELSE}
  Result := ScalarSplatF32x8(value);
  {$ENDIF}
end;

function NEONSplatF64x2(value: Double): TVecF64x2;
begin
  Result.d[0] := value;
  Result.d[1] := value;
end;

function NEONSplatF64x4(value: Double): TVecF64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF64x4_ASM(value);
  {$ELSE}
  Result := ScalarSplatF64x4(value);
  {$ENDIF}
end;

function NEONSplatF64x8(value: Double): TVecF64x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF64x8_ASM(value);
  {$ELSE}
  Result := ScalarSplatF64x8(value);
  {$ENDIF}
end;

function NEONSplatI64x4(value: Int64): TVecI64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatI64x4_ASM(value);
  {$ELSE}
  Result := ScalarSplatI64x4(value);
  {$ENDIF}
end;

function NEONSqrtF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONSqrtF32x4(a.lo.lo);
  Result.lo.hi := NEONSqrtF32x4(a.lo.hi);
  Result.hi.lo := NEONSqrtF32x4(a.hi.lo);
  Result.hi.hi := NEONSqrtF32x4(a.hi.hi);
end;

function NEONSqrtF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONSqrtF32x4(a.lo);
  Result.hi := NEONSqrtF32x4(a.hi);
end;

function NEONSqrtF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Sqrt(a.d[0]);
  Result.d[1] := Sqrt(a.d[1]);
end;

function NEONSqrtF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONSqrtF64x2(a.lo);
  Result.hi := NEONSqrtF64x2(a.hi);
end;

function NEONSqrtF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONSqrtF64x4(a.lo);
  Result.hi := NEONSqrtF64x4(a.hi);
end;

procedure NEONStoreF32x16(p: PSingle; const a: TVecF32x16);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF32x16_ASM(p, a);
  {$ELSE}
  ScalarStoreF32x16(p, a);
  {$ENDIF}
end;

procedure NEONStoreF32x8(p: PSingle; const a: TVecF32x8);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF32x8_ASM(p, a);
  {$ELSE}
  ScalarStoreF32x8(p, a);
  {$ENDIF}
end;

procedure NEONStoreF64x2(p: PDouble; const a: TVecF64x2);
begin
  Move(a.d[0], p^, 16);
end;

procedure NEONStoreF64x4(p: PDouble; const a: TVecF64x4);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF64x4_ASM(p, a);
  {$ELSE}
  ScalarStoreF64x4(p, a);
  {$ENDIF}
end;

procedure NEONStoreF64x8(p: PDouble; const a: TVecF64x8);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF64x8_ASM(p, a);
  {$ELSE}
  ScalarStoreF64x8(p, a);
  {$ENDIF}
end;

procedure NEONStoreI64x4(p: PInt64; const a: TVecI64x4);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreI64x4_ASM(p, a);
  {$ELSE}
  ScalarStoreI64x4(p, a);
  {$ENDIF}
end;

function NEONSubF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONSubF32x4(a.lo.lo, b.lo.lo);
  Result.lo.hi := NEONSubF32x4(a.lo.hi, b.lo.hi);
  Result.hi.lo := NEONSubF32x4(a.hi.lo, b.hi.lo);
  Result.hi.hi := NEONSubF32x4(a.hi.hi, b.hi.hi);
end;

function NEONSubF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONSubF64x2(a.lo, b.lo);
  Result.hi := NEONSubF64x2(a.hi, b.hi);
end;

function NEONSubF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONSubF64x4(a.lo, b.lo);
  Result.hi := NEONSubF64x4(a.hi, b.hi);
end;

function NEONSubI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarSubI32x16(a, b);
end;

function NEONSubI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarSubI32x8(a, b);
end;

function NEONSubI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarSubI64x4(a, b);
end;

function NEONSubI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarSubI64x8(a, b);
end;

function NEONSubU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarSubU32x4(a, b);
end;

function NEONSubU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarSubU32x8(a, b);
end;

function NEONSubU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarSubU64x4(a, b);
end;

function NEONTruncF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result.lo.lo := NEONTruncF32x4(a.lo.lo);
  Result.lo.hi := NEONTruncF32x4(a.lo.hi);
  Result.hi.lo := NEONTruncF32x4(a.hi.lo);
  Result.hi.hi := NEONTruncF32x4(a.hi.hi);
end;

function NEONTruncF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result.lo := NEONTruncF32x4(a.lo);
  Result.hi := NEONTruncF32x4(a.hi);
end;

function NEONTruncF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Trunc(a.d[0]);
  Result.d[1] := Trunc(a.d[1]);
end;

function NEONTruncF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result.lo := NEONTruncF64x2(a.lo);
  Result.hi := NEONTruncF64x2(a.hi);
end;

function NEONTruncF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result.lo := NEONTruncF64x4(a.lo);
  Result.hi := NEONTruncF64x4(a.hi);
end;

function NEONXorI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarXorI32x16(a, b);
end;

function NEONXorI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarXorI32x4(a, b);
end;

function NEONXorI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarXorI32x8(a, b);
end;

function NEONXorI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarXorI64x4(a, b);
end;

function NEONXorI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarXorI64x8(a, b);
end;

function NEONXorU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarXorU32x4(a, b);
end;

function NEONXorU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarXorU32x8(a, b);
end;

function NEONXorU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarXorU64x4(a, b);
end;

function NEONZeroF32x16: TVecF32x16;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF32x16_ASM;
  {$ELSE}
  Result := ScalarZeroF32x16;
  {$ENDIF}
end;

function NEONZeroF32x8: TVecF32x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF32x8_ASM;
  {$ELSE}
  Result := ScalarZeroF32x8;
  {$ENDIF}
end;

function NEONZeroF64x2: TVecF64x2;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function NEONZeroF64x4: TVecF64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF64x4_ASM;
  {$ELSE}
  Result := ScalarZeroF64x4;
  {$ENDIF}
end;

function NEONZeroF64x8: TVecF64x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF64x8_ASM;
  {$ELSE}
  Result := ScalarZeroF64x8;
  {$ENDIF}
end;

function NEONZeroI64x4: TVecI64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroI64x4_ASM;
  {$ELSE}
  Result := ScalarZeroI64x4;
  {$ENDIF}
end;

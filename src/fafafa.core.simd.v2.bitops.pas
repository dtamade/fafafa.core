unit fafafa.core.simd.v2.bitops;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.v2.types;

// === 位操作和逻辑运算（SIMD版本）===
// 设计原则：
// 1. 高效位操作：直接操作位模式，零开销
// 2. 类型安全：编译时检查，避免位操作错误
// 3. 向量化：并行处理多个元素的位操作
// 4. 标准兼容：与标准位操作语义一致

// === 基础位操作 ===
function simd_and_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_or_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_xor_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_not_i32x4(const A: TI32x4): TI32x4; inline;
function simd_andnot_i32x4(const A, B: TI32x4): TI32x4; inline; // A AND (NOT B)

// === 位移操作 ===
function simd_shl_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline;
function simd_shr_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline;
function simd_sar_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline; // 算术右移
function simd_rol_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline; // 循环左移
function simd_ror_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline; // 循环右移

// === 变量位移（每个元素不同的位移量）===
function simd_shlv_i32x4(const A, Shift: TI32x4): TI32x4; inline;
function simd_shrv_i32x4(const A, Shift: TI32x4): TI32x4; inline;
function simd_sarv_i32x4(const A, Shift: TI32x4): TI32x4; inline;

// === 位计数操作 ===
function simd_popcnt_i32x4(const A: TI32x4): TI32x4; inline; // 计算1的个数
function simd_lzcnt_i32x4(const A: TI32x4): TI32x4; inline;  // 前导零计数
function simd_tzcnt_i32x4(const A: TI32x4): TI32x4; inline;  // 尾随零计数

// === 位测试操作 ===
function simd_test_i32x4(const A, B: TI32x4): TMaskF32x4; inline; // 测试位是否设置
function simd_testz_i32x4(const A, B: TI32x4): Boolean; inline;   // 测试是否全零
function simd_testc_i32x4(const A, B: TI32x4): Boolean; inline;   // 测试是否全一

// === 位选择和混合 ===
function simd_select_i32x4(const Mask: TMaskF32x4; const A, B: TI32x4): TI32x4; inline;
function simd_blend_i32x4(const A, B: TI32x4; const Mask: Integer): TI32x4; inline;

// === 字节向量位操作 ===
function simd_and_i8x16(const A, B: TI8x16): TI8x16; inline;
function simd_or_i8x16(const A, B: TI8x16): TI8x16; inline;
function simd_xor_i8x16(const A, B: TI8x16): TI8x16; inline;
function simd_not_i8x16(const A: TI8x16): TI8x16; inline;

// === 短整数向量位操作 ===
function simd_and_i16x8(const A, B: TI16x8): TI16x8; inline;
function simd_or_i16x8(const A, B: TI16x8): TI16x8; inline;
function simd_xor_i16x8(const A, B: TI16x8): TI16x8; inline;
function simd_not_i16x8(const A: TI16x8): TI16x8; inline;

// === 无符号整数向量位操作 ===
function simd_and_u32x4(const A, B: TU32x4): TU32x4; inline;
function simd_or_u32x4(const A, B: TU32x4): TU32x4; inline;
function simd_xor_u32x4(const A, B: TU32x4): TU32x4; inline;
function simd_not_u32x4(const A: TU32x4): TU32x4; inline;

// === 浮点数位操作（通过类型转换）===
function simd_and_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_or_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_xor_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_andnot_f32x4(const A, B: TF32x4): TF32x4; inline;

// === 位操作实用函数 ===
function simd_reverse_bits_i32x4(const A: TI32x4): TI32x4; inline; // 反转位顺序
function simd_byteswap_i32x4(const A: TI32x4): TI32x4; inline;     // 字节序交换
function simd_parity_i32x4(const A: TI32x4): TI32x4; inline;       // 奇偶校验

implementation

// === 基础位操作实现 ===

function simd_and_i32x4(const A, B: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) and B.Extract(I));
end;

function simd_or_i32x4(const A, B: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) or B.Extract(I));
end;

function simd_xor_i32x4(const A, B: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) xor B.Extract(I));
end;

function simd_not_i32x4(const A: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, not A.Extract(I));
end;

function simd_andnot_i32x4(const A, B: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) and (not B.Extract(I)));
end;

// === 位移操作实现 ===

function simd_shl_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) shl Shift);
end;

function simd_shr_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) shr Shift);
end;

function simd_sar_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
var
  I: Integer;
  Val: Int32;
begin
  for I := 0 to 3 do
  begin
    Val := A.Extract(I);
    // 算术右移：保持符号位
    if Val < 0 then
      Result.Insert(I, (Val shr Shift) or ((-1) shl (32 - Shift)))
    else
      Result.Insert(I, Val shr Shift);
  end;
end;

function simd_rol_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
var
  I: Integer;
  Val: UInt32;
  S: Integer;
begin
  S := Shift and 31; // 限制在0-31范围内
  for I := 0 to 3 do
  begin
    Val := UInt32(A.Extract(I));
    Result.Insert(I, Int32((Val shl S) or (Val shr (32 - S))));
  end;
end;

function simd_ror_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
var
  I: Integer;
  Val: UInt32;
  S: Integer;
begin
  S := Shift and 31; // 限制在0-31范围内
  for I := 0 to 3 do
  begin
    Val := UInt32(A.Extract(I));
    Result.Insert(I, Int32((Val shr S) or (Val shl (32 - S))));
  end;
end;

// === 变量位移实现 ===

function simd_shlv_i32x4(const A, Shift: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) shl (Shift.Extract(I) and 31));
end;

function simd_shrv_i32x4(const A, Shift: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) shr (Shift.Extract(I) and 31));
end;

function simd_sarv_i32x4(const A, Shift: TI32x4): TI32x4;
var
  I: Integer;
  Val: Int32;
  S: Integer;
begin
  for I := 0 to 3 do
  begin
    Val := A.Extract(I);
    S := Shift.Extract(I) and 31;
    // 算术右移
    if Val < 0 then
      Result.Insert(I, (Val shr S) or ((-1) shl (32 - S)))
    else
      Result.Insert(I, Val shr S);
  end;
end;

// === 位计数操作实现 ===

function PopCount32(Value: UInt32): Integer; inline;
var
  Count: Integer;
begin
  Count := 0;
  while Value <> 0 do
  begin
    Inc(Count);
    Value := Value and (Value - 1); // 清除最低位的1
  end;
  Result := Count;
end;

function LeadingZeroCount32(Value: UInt32): Integer; inline;
var
  Count: Integer;
begin
  if Value = 0 then
    Exit(32);
  
  Count := 0;
  if (Value and $FFFF0000) = 0 then begin Count := Count + 16; Value := Value shl 16; end;
  if (Value and $FF000000) = 0 then begin Count := Count + 8;  Value := Value shl 8;  end;
  if (Value and $F0000000) = 0 then begin Count := Count + 4;  Value := Value shl 4;  end;
  if (Value and $C0000000) = 0 then begin Count := Count + 2;  Value := Value shl 2;  end;
  if (Value and $80000000) = 0 then begin Count := Count + 1;  end;
  
  Result := Count;
end;

function TrailingZeroCount32(Value: UInt32): Integer; inline;
var
  Count: Integer;
begin
  if Value = 0 then
    Exit(32);
  
  Count := 0;
  if (Value and $0000FFFF) = 0 then begin Count := Count + 16; Value := Value shr 16; end;
  if (Value and $000000FF) = 0 then begin Count := Count + 8;  Value := Value shr 8;  end;
  if (Value and $0000000F) = 0 then begin Count := Count + 4;  Value := Value shr 4;  end;
  if (Value and $00000003) = 0 then begin Count := Count + 2;  Value := Value shr 2;  end;
  if (Value and $00000001) = 0 then begin Count := Count + 1;  end;
  
  Result := Count;
end;

function simd_popcnt_i32x4(const A: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, PopCount32(UInt32(A.Extract(I))));
end;

function simd_lzcnt_i32x4(const A: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, LeadingZeroCount32(UInt32(A.Extract(I))));
end;

function simd_tzcnt_i32x4(const A: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, TrailingZeroCount32(UInt32(A.Extract(I))));
end;

// === 位测试操作实现 ===

function simd_test_i32x4(const A, B: TI32x4): TMaskF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Data[I] := (A.Extract(I) and B.Extract(I)) <> 0;
end;

function simd_testz_i32x4(const A, B: TI32x4): Boolean;
var
  I: Integer;
begin
  for I := 0 to 3 do
    if (A.Extract(I) and B.Extract(I)) <> 0 then
      Exit(False);
  Result := True;
end;

function simd_testc_i32x4(const A, B: TI32x4): Boolean;
var
  I: Integer;
begin
  for I := 0 to 3 do
    if (A.Extract(I) and B.Extract(I)) <> B.Extract(I) then
      Exit(False);
  Result := True;
end;

// === 位选择和混合实现 ===

function simd_select_i32x4(const Mask: TMaskF32x4; const A, B: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    if Mask.Data[I] then
      Result.Insert(I, A.Extract(I))
    else
      Result.Insert(I, B.Extract(I));
end;

function simd_blend_i32x4(const A, B: TI32x4; const Mask: Integer): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    if (Mask and (1 shl I)) <> 0 then
      Result.Insert(I, B.Extract(I))
    else
      Result.Insert(I, A.Extract(I));
end;

// === 字节向量位操作实现 ===

function simd_and_i8x16(const A, B: TI8x16): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.Insert(I, A.Extract(I) and B.Extract(I));
end;

function simd_or_i8x16(const A, B: TI8x16): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.Insert(I, A.Extract(I) or B.Extract(I));
end;

function simd_xor_i8x16(const A, B: TI8x16): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.Insert(I, A.Extract(I) xor B.Extract(I));
end;

function simd_not_i8x16(const A: TI8x16): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.Insert(I, not A.Extract(I));
end;

// === 短整数向量位操作实现 ===

function simd_and_i16x8(const A, B: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Insert(I, A.Extract(I) and B.Extract(I));
end;

function simd_or_i16x8(const A, B: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Insert(I, A.Extract(I) or B.Extract(I));
end;

function simd_xor_i16x8(const A, B: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Insert(I, A.Extract(I) xor B.Extract(I));
end;

function simd_not_i16x8(const A: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Insert(I, not A.Extract(I));
end;

// === 无符号整数向量位操作实现 ===

function simd_and_u32x4(const A, B: TU32x4): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) and B.Extract(I));
end;

function simd_or_u32x4(const A, B: TU32x4): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) or B.Extract(I));
end;

function simd_xor_u32x4(const A, B: TU32x4): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, A.Extract(I) xor B.Extract(I));
end;

function simd_not_u32x4(const A: TU32x4): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, not A.Extract(I));
end;

// === 浮点数位操作实现 ===

function simd_and_f32x4(const A, B: TF32x4): TF32x4;
var
  I: Integer;
  ValA, ValB: UInt32;
  ResultVal: UInt32;
  FloatA, FloatB: Single;
begin
  for I := 0 to 3 do
  begin
    // 通过指针转换进行位操作
    FloatA := A.Extract(I);
    FloatB := B.Extract(I);
    ValA := PUInt32(@FloatA)^;
    ValB := PUInt32(@FloatB)^;
    ResultVal := ValA and ValB;
    Result.Insert(I, PSingle(@ResultVal)^);
  end;
end;

function simd_or_f32x4(const A, B: TF32x4): TF32x4;
var
  I: Integer;
  ValA, ValB: UInt32;
  ResultVal: UInt32;
  FloatA, FloatB: Single;
begin
  for I := 0 to 3 do
  begin
    FloatA := A.Extract(I);
    FloatB := B.Extract(I);
    ValA := PUInt32(@FloatA)^;
    ValB := PUInt32(@FloatB)^;
    ResultVal := ValA or ValB;
    Result.Insert(I, PSingle(@ResultVal)^);
  end;
end;

function simd_xor_f32x4(const A, B: TF32x4): TF32x4;
var
  I: Integer;
  ValA, ValB: UInt32;
  ResultVal: UInt32;
  FloatA, FloatB: Single;
begin
  for I := 0 to 3 do
  begin
    FloatA := A.Extract(I);
    FloatB := B.Extract(I);
    ValA := PUInt32(@FloatA)^;
    ValB := PUInt32(@FloatB)^;
    ResultVal := ValA xor ValB;
    Result.Insert(I, PSingle(@ResultVal)^);
  end;
end;

function simd_andnot_f32x4(const A, B: TF32x4): TF32x4;
var
  I: Integer;
  ValA, ValB: UInt32;
  ResultVal: UInt32;
  FloatA, FloatB: Single;
begin
  for I := 0 to 3 do
  begin
    FloatA := A.Extract(I);
    FloatB := B.Extract(I);
    ValA := PUInt32(@FloatA)^;
    ValB := PUInt32(@FloatB)^;
    ResultVal := ValA and (not ValB);
    Result.Insert(I, PSingle(@ResultVal)^);
  end;
end;

// === 位操作实用函数实现 ===

function ReverseBits32(Value: UInt32): UInt32; inline;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 31 do
  begin
    Result := (Result shl 1) or (Value and 1);
    Value := Value shr 1;
  end;
end;

function ByteSwap32(Value: UInt32): UInt32; inline;
begin
  Result := ((Value and $000000FF) shl 24) or
            ((Value and $0000FF00) shl 8) or
            ((Value and $00FF0000) shr 8) or
            ((Value and $FF000000) shr 24);
end;

function simd_reverse_bits_i32x4(const A: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, Int32(ReverseBits32(UInt32(A.Extract(I)))));
end;

function simd_byteswap_i32x4(const A: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, Int32(ByteSwap32(UInt32(A.Extract(I)))));
end;

function simd_parity_i32x4(const A: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, PopCount32(UInt32(A.Extract(I))) and 1);
end;

end.

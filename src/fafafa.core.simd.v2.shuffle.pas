unit fafafa.core.simd.v2.shuffle;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.v2.types;

// === 向量重排和混洗（SIMD版本）===
// 设计原则：
// 1. 灵活重排：支持任意元素位置重新排列
// 2. 高效实现：针对常见模式优化
// 3. 类型安全：编译时检查索引范围
// 4. 向量化：并行处理多个重排操作

// === 基础混洗操作 ===
function simd_shuffle_f32x4(const A: TF32x4; const Mask: array of Integer): TF32x4; inline;
function simd_shuffle_i32x4(const A: TI32x4; const Mask: array of Integer): TI32x4; inline;

// === 双向量混洗 ===
function simd_shuffle2_f32x4(const A, B: TF32x4; const Mask: array of Integer): TF32x4; inline;
function simd_shuffle2_i32x4(const A, B: TI32x4; const Mask: array of Integer): TI32x4; inline;

// === 排列操作 ===
function simd_permute_f32x4(const A: TF32x4; const Indices: TI32x4): TF32x4; inline;
function simd_permute_i32x4(const A: TI32x4; const Indices: TI32x4): TI32x4; inline;

// === 广播操作 ===
function simd_broadcast_f32x4(const A: TF32x4; const Index: Integer): TF32x4; inline;
function simd_broadcast_i32x4(const A: TI32x4; const Index: Integer): TI32x4; inline;

// === 复制操作 ===
function simd_duplicate_low_f32x4(const A: TF32x4): TF32x4; inline;  // [a,b,c,d] -> [a,a,c,c]
function simd_duplicate_high_f32x4(const A: TF32x4): TF32x4; inline; // [a,b,c,d] -> [b,b,d,d]
function simd_duplicate_even_f32x4(const A: TF32x4): TF32x4; inline; // [a,b,c,d] -> [a,c,a,c]
function simd_duplicate_odd_f32x4(const A: TF32x4): TF32x4; inline;  // [a,b,c,d] -> [b,d,b,d]

// === 交换操作 ===
function simd_swap_pairs_f32x4(const A: TF32x4): TF32x4; inline;     // [a,b,c,d] -> [b,a,d,c]
function simd_swap_halves_f32x4(const A: TF32x4): TF32x4; inline;    // [a,b,c,d] -> [c,d,a,b]

// === 反转操作 ===
function simd_reverse_f32x4(const A: TF32x4): TF32x4; inline;        // [a,b,c,d] -> [d,c,b,a]
function simd_reverse_i32x4(const A: TI32x4): TI32x4; inline;

// === 旋转操作 ===
function simd_rotate_left_f32x4(const A: TF32x4; const Count: Integer): TF32x4; inline;
function simd_rotate_right_f32x4(const A: TF32x4; const Count: Integer): TF32x4; inline;

// === 交错操作 ===
function simd_interleave_low_f32x4(const A, B: TF32x4): TF32x4; inline;  // [a0,a1,a2,a3],[b0,b1,b2,b3] -> [a0,b0,a1,b1]
function simd_interleave_high_f32x4(const A, B: TF32x4): TF32x4; inline; // [a0,a1,a2,a3],[b0,b1,b2,b3] -> [a2,b2,a3,b3]

// 定义返回类型
type
  TDeinterleaveResult = record
    Low, High: TF32x4;
  end;

function simd_deinterleave_f32x4(const A: TF32x4): TDeinterleaveResult; inline;

// === 压缩和展开 ===
function simd_pack_f32x4(const A, B: TF32x4): TF32x4; inline;        // 将两个向量压缩为一个
function simd_unpack_low_f32x4(const A: TF32x4): TF32x4; inline;     // 展开低位元素
function simd_unpack_high_f32x4(const A: TF32x4): TF32x4; inline;    // 展开高位元素

// === 字节向量混洗 ===
function simd_shuffle_i8x16(const A: TI8x16; const Mask: array of Integer): TI8x16; inline;
function simd_reverse_i8x16(const A: TI8x16): TI8x16; inline;

// === 短整数向量混洗 ===
function simd_shuffle_i16x8(const A: TI16x8; const Mask: array of Integer): TI16x8; inline;
function simd_reverse_i16x8(const A: TI16x8): TI16x8; inline;

// === 特殊混洗模式 ===
function simd_movemask_f32x4(const A: TF32x4): Integer; inline;       // 提取符号位掩码
function simd_blend_f32x4(const A, B: TF32x4; const Mask: Integer): TF32x4; inline;
function simd_blendv_f32x4(const A, B, Mask: TF32x4): TF32x4; inline; // 变量混合

// === 条件选择 ===
function simd_select_f32x4(const Condition: TMaskF32x4; const A, B: TF32x4): TF32x4; inline;

// === 向量合并和分离 ===
type
  TZipResult = record
    First, Second: TF32x4;
  end;

function simd_zip_f32x4(const A, B: TF32x4): TZipResult; inline;
function simd_unzip_f32x4(const A, B: TF32x4): TZipResult; inline;

implementation

// === 基础混洗操作实现 ===

function simd_shuffle_f32x4(const A: TF32x4; const Mask: array of Integer): TF32x4;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 3 do
  begin
    if I <= High(Mask) then
    begin
      Index := Mask[I] and 3; // 限制在0-3范围内
      Result.Insert(I, A.Extract(Index));
    end
    else
      Result.Insert(I, 0.0);
  end;
end;

function simd_shuffle_i32x4(const A: TI32x4; const Mask: array of Integer): TI32x4;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 3 do
  begin
    if I <= High(Mask) then
    begin
      Index := Mask[I] and 3; // 限制在0-3范围内
      Result.Insert(I, A.Extract(Index));
    end
    else
      Result.Insert(I, 0);
  end;
end;

// === 双向量混洗实现 ===

function simd_shuffle2_f32x4(const A, B: TF32x4; const Mask: array of Integer): TF32x4;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 3 do
  begin
    if I <= High(Mask) then
    begin
      Index := Mask[I];
      if Index < 4 then
        Result.Insert(I, A.Extract(Index))
      else
        Result.Insert(I, B.Extract(Index - 4));
    end
    else
      Result.Insert(I, 0.0);
  end;
end;

function simd_shuffle2_i32x4(const A, B: TI32x4; const Mask: array of Integer): TI32x4;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 3 do
  begin
    if I <= High(Mask) then
    begin
      Index := Mask[I];
      if Index < 4 then
        Result.Insert(I, A.Extract(Index))
      else
        Result.Insert(I, B.Extract(Index - 4));
    end
    else
      Result.Insert(I, 0);
  end;
end;

// === 排列操作实现 ===

function simd_permute_f32x4(const A: TF32x4; const Indices: TI32x4): TF32x4;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 3 do
  begin
    Index := Indices.Extract(I) and 3; // 限制在0-3范围内
    Result.Insert(I, A.Extract(Index));
  end;
end;

function simd_permute_i32x4(const A: TI32x4; const Indices: TI32x4): TI32x4;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 3 do
  begin
    Index := Indices.Extract(I) and 3; // 限制在0-3范围内
    Result.Insert(I, A.Extract(Index));
  end;
end;

// === 广播操作实现 ===

function simd_broadcast_f32x4(const A: TF32x4; const Index: Integer): TF32x4;
var
  I: Integer;
  Value: Single;
begin
  Value := A.Extract(Index and 3); // 限制在0-3范围内
  for I := 0 to 3 do
    Result.Insert(I, Value);
end;

function simd_broadcast_i32x4(const A: TI32x4; const Index: Integer): TI32x4;
var
  I: Integer;
  Value: Int32;
begin
  Value := A.Extract(Index and 3); // 限制在0-3范围内
  for I := 0 to 3 do
    Result.Insert(I, Value);
end;

// === 复制操作实现 ===

function simd_duplicate_low_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(0));
  Result.Insert(1, A.Extract(0));
  Result.Insert(2, A.Extract(2));
  Result.Insert(3, A.Extract(2));
end;

function simd_duplicate_high_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(1));
  Result.Insert(1, A.Extract(1));
  Result.Insert(2, A.Extract(3));
  Result.Insert(3, A.Extract(3));
end;

function simd_duplicate_even_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(0));
  Result.Insert(1, A.Extract(2));
  Result.Insert(2, A.Extract(0));
  Result.Insert(3, A.Extract(2));
end;

function simd_duplicate_odd_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(1));
  Result.Insert(1, A.Extract(3));
  Result.Insert(2, A.Extract(1));
  Result.Insert(3, A.Extract(3));
end;

// === 交换操作实现 ===

function simd_swap_pairs_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(1));
  Result.Insert(1, A.Extract(0));
  Result.Insert(2, A.Extract(3));
  Result.Insert(3, A.Extract(2));
end;

function simd_swap_halves_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(2));
  Result.Insert(1, A.Extract(3));
  Result.Insert(2, A.Extract(0));
  Result.Insert(3, A.Extract(1));
end;

// === 反转操作实现 ===

function simd_reverse_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(3));
  Result.Insert(1, A.Extract(2));
  Result.Insert(2, A.Extract(1));
  Result.Insert(3, A.Extract(0));
end;

function simd_reverse_i32x4(const A: TI32x4): TI32x4;
begin
  Result.Insert(0, A.Extract(3));
  Result.Insert(1, A.Extract(2));
  Result.Insert(2, A.Extract(1));
  Result.Insert(3, A.Extract(0));
end;

// === 旋转操作实现 ===

function simd_rotate_left_f32x4(const A: TF32x4; const Count: Integer): TF32x4;
var
  I: Integer;
  Shift: Integer;
begin
  Shift := Count and 3; // 限制在0-3范围内
  for I := 0 to 3 do
    Result.Insert(I, A.Extract((I + Shift) and 3));
end;

function simd_rotate_right_f32x4(const A: TF32x4; const Count: Integer): TF32x4;
var
  I: Integer;
  Shift: Integer;
begin
  Shift := Count and 3; // 限制在0-3范围内
  for I := 0 to 3 do
    Result.Insert(I, A.Extract((I - Shift + 4) and 3));
end;

// === 交错操作实现 ===

function simd_interleave_low_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(0));
  Result.Insert(1, B.Extract(0));
  Result.Insert(2, A.Extract(1));
  Result.Insert(3, B.Extract(1));
end;

function simd_interleave_high_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(2));
  Result.Insert(1, B.Extract(2));
  Result.Insert(2, A.Extract(3));
  Result.Insert(3, B.Extract(3));
end;

function simd_deinterleave_f32x4(const A: TF32x4): TDeinterleaveResult;
begin
  Result.Low.Insert(0, A.Extract(0));
  Result.Low.Insert(1, A.Extract(2));
  Result.Low.Insert(2, 0.0);
  Result.Low.Insert(3, 0.0);
  
  Result.High.Insert(0, A.Extract(1));
  Result.High.Insert(1, A.Extract(3));
  Result.High.Insert(2, 0.0);
  Result.High.Insert(3, 0.0);
end;

// === 压缩和展开实现 ===

function simd_pack_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(0));
  Result.Insert(1, A.Extract(2));
  Result.Insert(2, B.Extract(0));
  Result.Insert(3, B.Extract(2));
end;

function simd_unpack_low_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(0));
  Result.Insert(1, 0.0);
  Result.Insert(2, A.Extract(1));
  Result.Insert(3, 0.0);
end;

function simd_unpack_high_f32x4(const A: TF32x4): TF32x4;
begin
  Result.Insert(0, A.Extract(2));
  Result.Insert(1, 0.0);
  Result.Insert(2, A.Extract(3));
  Result.Insert(3, 0.0);
end;

// === 字节向量混洗实现 ===

function simd_shuffle_i8x16(const A: TI8x16; const Mask: array of Integer): TI8x16;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 15 do
  begin
    if I <= High(Mask) then
    begin
      Index := Mask[I] and 15; // 限制在0-15范围内
      Result.Insert(I, A.Extract(Index));
    end
    else
      Result.Insert(I, 0);
  end;
end;

function simd_reverse_i8x16(const A: TI8x16): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.Insert(I, A.Extract(15 - I));
end;

// === 短整数向量混洗实现 ===

function simd_shuffle_i16x8(const A: TI16x8; const Mask: array of Integer): TI16x8;
var
  I: Integer;
  Index: Integer;
begin
  for I := 0 to 7 do
  begin
    if I <= High(Mask) then
    begin
      Index := Mask[I] and 7; // 限制在0-7范围内
      Result.Insert(I, A.Extract(Index));
    end
    else
      Result.Insert(I, 0);
  end;
end;

function simd_reverse_i16x8(const A: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Insert(I, A.Extract(7 - I));
end;

// === 特殊混洗模式实现 ===

function simd_movemask_f32x4(const A: TF32x4): Integer;
var
  I: Integer;
  Value: UInt32;
  FloatVal: Single;
begin
  Result := 0;
  for I := 0 to 3 do
  begin
    FloatVal := A.Extract(I);
    Value := PUInt32(@FloatVal)^;
    if (Value and $80000000) <> 0 then // 检查符号位
      Result := Result or (1 shl I);
  end;
end;

function simd_blend_f32x4(const A, B: TF32x4; const Mask: Integer): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
  begin
    if (Mask and (1 shl I)) <> 0 then
      Result.Insert(I, B.Extract(I))
    else
      Result.Insert(I, A.Extract(I));
  end;
end;

function simd_blendv_f32x4(const A, B, Mask: TF32x4): TF32x4;
var
  I: Integer;
  MaskValue: UInt32;
  FloatVal: Single;
begin
  for I := 0 to 3 do
  begin
    FloatVal := Mask.Extract(I);
    MaskValue := PUInt32(@FloatVal)^;
    if (MaskValue and $80000000) <> 0 then // 检查符号位
      Result.Insert(I, B.Extract(I))
    else
      Result.Insert(I, A.Extract(I));
  end;
end;

// === 条件选择实现 ===

function simd_select_f32x4(const Condition: TMaskF32x4; const A, B: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
  begin
    if Condition.Data[I] then
      Result.Insert(I, A.Extract(I))
    else
      Result.Insert(I, B.Extract(I));
  end;
end;

// === 向量合并和分离实现 ===

function simd_zip_f32x4(const A, B: TF32x4): TZipResult;
begin
  // 交错合并：[a0,a1,a2,a3],[b0,b1,b2,b3] -> [a0,b0,a1,b1],[a2,b2,a3,b3]
  Result.First.Insert(0, A.Extract(0));
  Result.First.Insert(1, B.Extract(0));
  Result.First.Insert(2, A.Extract(1));
  Result.First.Insert(3, B.Extract(1));

  Result.Second.Insert(0, A.Extract(2));
  Result.Second.Insert(1, B.Extract(2));
  Result.Second.Insert(2, A.Extract(3));
  Result.Second.Insert(3, B.Extract(3));
end;

function simd_unzip_f32x4(const A, B: TF32x4): TZipResult;
begin
  // 分离交错：[a0,b0,a1,b1],[a2,b2,a3,b3] -> [a0,a1,a2,a3],[b0,b1,b2,b3]
  Result.First.Insert(0, A.Extract(0));
  Result.First.Insert(1, A.Extract(2));
  Result.First.Insert(2, B.Extract(0));
  Result.First.Insert(3, B.Extract(2));

  Result.Second.Insert(0, A.Extract(1));
  Result.Second.Insert(1, A.Extract(3));
  Result.Second.Insert(2, B.Extract(1));
  Result.Second.Insert(3, B.Extract(3));
end;

end.

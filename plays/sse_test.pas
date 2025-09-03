program sse_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.base in '../src/fafafa.core.simd.intrinsics.base.pas',
  fafafa.core.simd.intrinsics.sse in '../src/fafafa.core.simd.intrinsics.sse.pas';

procedure TestSSEBasics;
var
  a, b, result: TM128;
  i: Integer;
begin
  WriteLn('=== SSE 基础测试 ===');
  
  // 测试 Set 函数
  WriteLn('测试 Set 函数...');
  a := sse_set1_ps(3.14);
  Write('sse_set1_ps(3.14): [');
  for i := 0 to 3 do
  begin
    Write(a.m128_f32[i]:0:2);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  b := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  Write('sse_set_ps(4.0, 3.0, 2.0, 1.0): [');
  for i := 0 to 3 do
  begin
    Write(b.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  // 测试加法
  WriteLn('');
  WriteLn('测试浮点加法...');
  result := sse_add_ps(a, b);
  Write('add_ps 结果: [');
  for i := 0 to 3 do
  begin
    Write(result.m128_f32[i]:0:2);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  // 测试减法
  WriteLn('');
  WriteLn('测试浮点减法...');
  result := sse_sub_ps(b, a);
  Write('sub_ps 结果: [');
  for i := 0 to 3 do
  begin
    Write(result.m128_f32[i]:0:2);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  // 测试乘法
  WriteLn('');
  WriteLn('测试浮点乘法...');
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(2.0, 2.0, 2.0, 2.0);
  result := sse_mul_ps(a, b);
  Write('mul_ps 结果: [');
  for i := 0 to 3 do
  begin
    Write(result.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  WriteLn('预期: [2.0, 4.0, 6.0, 8.0]');
end;

procedure TestSSEMath;
var
  a, result: TM128;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== SSE 数学函数测试 ===');
  
  // 测试平方根
  WriteLn('测试平方根...');
  a := sse_set_ps(16.0, 9.0, 4.0, 1.0);
  Write('原始值: [');
  for i := 0 to 3 do
  begin
    Write(a.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  result := sse_sqrt_ps(a);
  Write('sqrt_ps 结果: [');
  for i := 0 to 3 do
  begin
    Write(result.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  WriteLn('预期: [1.0, 2.0, 3.0, 4.0]');
  
  // 测试 Min/Max
  WriteLn('');
  WriteLn('测试 Min/Max...');
  a := sse_set_ps(10.0, 2.0, 8.0, 3.0);
  b := sse_set_ps(5.0, 7.0, 1.0, 9.0);
  
  Write('a: [');
  for i := 0 to 3 do
  begin
    Write(a.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b: [');
  for i := 0 to 3 do
  begin
    Write(b.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  result := sse_min_ps(a, b);
  Write('min_ps 结果: [');
  for i := 0 to 3 do
  begin
    Write(result.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  result := sse_max_ps(a, b);
  Write('max_ps 结果: [');
  for i := 0 to 3 do
  begin
    Write(result.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
end;

procedure TestSSELogical;
var
  a, b, result: TM128;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== SSE 逻辑运算测试 ===');
  
  // 使用整数视图来设置位模式
  a.m128i_u32[0] := $F0F0F0F0;
  a.m128i_u32[1] := $F0F0F0F0;
  a.m128i_u32[2] := $F0F0F0F0;
  a.m128i_u32[3] := $F0F0F0F0;
  
  b.m128i_u32[0] := $AAAAAAAA;
  b.m128i_u32[1] := $AAAAAAAA;
  b.m128i_u32[2] := $AAAAAAAA;
  b.m128i_u32[3] := $AAAAAAAA;
  
  WriteLn('a: $F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0');
  WriteLn('b: $AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
  
  result := sse_and_ps(a, b);
  Write('AND: $');
  for i := 3 downto 0 do
    Write(IntToHex(result.m128i_u32[i], 8));
  WriteLn('');
  
  result := sse_or_ps(a, b);
  Write('OR:  $');
  for i := 3 downto 0 do
    Write(IntToHex(result.m128i_u32[i], 8));
  WriteLn('');
  
  result := sse_xor_ps(a, b);
  Write('XOR: $');
  for i := 3 downto 0 do
    Write(IntToHex(result.m128i_u32[i], 8));
  WriteLn('');
end;

procedure TestSSECompare;
var
  a, b, result: TM128;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== SSE 比较运算测试 ===');
  
  a := sse_set_ps(4.0, 2.0, 6.0, 1.0);
  b := sse_set_ps(3.0, 2.0, 8.0, 2.0);
  
  Write('a: [');
  for i := 0 to 3 do
  begin
    Write(a.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b: [');
  for i := 0 to 3 do
  begin
    Write(b.m128_f32[i]:0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  result := sse_cmpeq_ps(a, b);
  Write('相等比较: [');
  for i := 0 to 3 do
  begin
    Write('$', IntToHex(result.m128i_u32[i], 8));
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  result := sse_cmplt_ps(a, b);
  Write('小于比较: [');
  for i := 0 to 3 do
  begin
    Write('$', IntToHex(result.m128i_u32[i], 8));
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
end;

procedure TestSSEScalar;
var
  a, b, result: TM128;
begin
  WriteLn('');
  WriteLn('=== SSE 标量运算测试 ===');
  
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  
  WriteLn('a: [1.0, 2.0, 3.0, 4.0]');
  WriteLn('b: [5.0, 6.0, 7.0, 8.0]');
  
  result := sse_add_ss(a, b);
  WriteLn('add_ss 结果: [', result.m128_f32[0]:0:1, ', ', result.m128_f32[1]:0:1, ', ', 
          result.m128_f32[2]:0:1, ', ', result.m128_f32[3]:0:1, ']');
  WriteLn('预期: [6.0, 2.0, 3.0, 4.0] (只有第一个元素相加)');
  
  result := sse_mul_ss(a, b);
  WriteLn('mul_ss 结果: [', result.m128_f32[0]:0:1, ', ', result.m128_f32[1]:0:1, ', ', 
          result.m128_f32[2]:0:1, ', ', result.m128_f32[3]:0:1, ']');
  WriteLn('预期: [5.0, 2.0, 3.0, 4.0] (只有第一个元素相乘)');
end;

begin
  WriteLn('SSE 指令集测试程序');
  WriteLn('==================');
  
  TestSSEBasics;
  TestSSEMath;
  TestSSELogical;
  TestSSECompare;
  TestSSEScalar;
  
  WriteLn('');
  WriteLn('测试完成！');
  WriteLn('注意：这是 Pascal 模拟实现，实际 SSE 指令会更快。');
  
  ReadLn;
end.

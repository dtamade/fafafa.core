program simple_sse_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils;

// 简化的 SSE 类型定义
type
  TM128 = record
    case Integer of
      0: (m128_f32: array[0..3] of Single);
      1: (m128i_u32: array[0..3] of UInt32);
      2: (m128i_i32: array[0..3] of LongInt);
      3: (m128d_f64: array[0..1] of Double);
  end;

// 简化的 SSE 函数实现
function sse_setzero_ps: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function sse_set1_ps(Value: Single): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := Value;
end;

function sse_set_ps(e3, e2, e1, e0: Single): TM128;
begin
  Result.m128_f32[0] := e0;
  Result.m128_f32[1] := e1;
  Result.m128_f32[2] := e2;
  Result.m128_f32[3] := e3;
end;

function sse_add_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] + b.m128_f32[i];
end;

function sse_sub_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] - b.m128_f32[i];
end;

function sse_mul_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i];
end;

function sse_div_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] / b.m128_f32[i];
end;

function sse_sqrt_ps(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := Sqrt(a.m128_f32[i]);
end;

function sse_min_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] < b.m128_f32[i] then
      Result.m128_f32[i] := a.m128_f32[i]
    else
      Result.m128_f32[i] := b.m128_f32[i];
end;

function sse_max_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] > b.m128_f32[i] then
      Result.m128_f32[i] := a.m128_f32[i]
    else
      Result.m128_f32[i] := b.m128_f32[i];
end;

function sse_add_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] + b.m128_f32[0];
end;

function sse_mul_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] * b.m128_f32[0];
end;

// 测试程序
procedure PrintVector(const name: string; const v: TM128);
var
  i: Integer;
begin
  Write(name, ': [');
  for i := 0 to 3 do
  begin
    Write(v.m128_f32[i]:0:2);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
end;

var
  a, b, result: TM128;

begin
  WriteLn('简化 SSE 测试程序');
  WriteLn('==================');
  
  // 测试基本的 set 函数
  WriteLn('测试 Set 函数...');
  a := sse_set1_ps(3.14);
  PrintVector('sse_set1_ps(3.14)', a);
  
  b := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  PrintVector('sse_set_ps(4.0, 3.0, 2.0, 1.0)', b);
  
  // 测试算术运算
  WriteLn('');
  WriteLn('测试算术运算...');
  result := sse_add_ps(a, b);
  PrintVector('add_ps 结果', result);
  
  result := sse_sub_ps(b, a);
  PrintVector('sub_ps 结果', result);
  
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(2.0, 2.0, 2.0, 2.0);
  result := sse_mul_ps(a, b);
  PrintVector('mul_ps 结果', result);
  WriteLn('预期: [2.00, 4.00, 6.00, 8.00]');
  
  result := sse_div_ps(a, b);
  PrintVector('div_ps 结果', result);
  WriteLn('预期: [0.50, 1.00, 1.50, 2.00]');
  
  // 测试数学函数
  WriteLn('');
  WriteLn('测试数学函数...');
  a := sse_set_ps(16.0, 9.0, 4.0, 1.0);
  PrintVector('原始值', a);
  
  result := sse_sqrt_ps(a);
  PrintVector('sqrt_ps 结果', result);
  WriteLn('预期: [1.00, 2.00, 3.00, 4.00]');
  
  // 测试 Min/Max
  WriteLn('');
  WriteLn('测试 Min/Max...');
  a := sse_set_ps(10.0, 2.0, 8.0, 3.0);
  b := sse_set_ps(5.0, 7.0, 1.0, 9.0);
  PrintVector('a', a);
  PrintVector('b', b);
  
  result := sse_min_ps(a, b);
  PrintVector('min_ps 结果', result);
  WriteLn('预期: [3.00, 1.00, 2.00, 5.00]');
  
  result := sse_max_ps(a, b);
  PrintVector('max_ps 结果', result);
  WriteLn('预期: [9.00, 8.00, 7.00, 10.00]');
  
  // 测试标量运算
  WriteLn('');
  WriteLn('测试标量运算...');
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  PrintVector('a', a);
  PrintVector('b', b);
  
  result := sse_add_ss(a, b);
  PrintVector('add_ss 结果', result);
  WriteLn('预期: [6.00, 2.00, 3.00, 4.00] (只有第一个元素相加)');
  
  result := sse_mul_ss(a, b);
  PrintVector('mul_ss 结果', result);
  WriteLn('预期: [5.00, 2.00, 3.00, 4.00] (只有第一个元素相乘)');
  
  WriteLn('');
  WriteLn('测试完成！');
  WriteLn('注意：这是 Pascal 模拟实现，实际 SSE 指令会更快。');
  
  ReadLn;
end.

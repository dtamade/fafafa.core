program test_simd_ops;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.ops;

procedure TestVectorOperations;
var
  a, b, result: TVecF32x4;
  sum: Single;
begin
  WriteLn('=== SIMD 向量操作测试 ===');
  
  try
    // 创建测试向量
    a := VecF32x4_Set(1.0, 2.0, 3.0, 4.0);
    b := VecF32x4_Set(5.0, 6.0, 7.0, 8.0);
    
    WriteLn('向量 A: [', a.f[0]:0:1, ', ', a.f[1]:0:1, ', ', a.f[2]:0:1, ', ', a.f[3]:0:1, ']');
    WriteLn('向量 B: [', b.f[0]:0:1, ', ', b.f[1]:0:1, ', ', b.f[2]:0:1, ', ', b.f[3]:0:1, ']');
    
    // 测试加法
    result := VecF32x4_Add(a, b);
    WriteLn('');
    WriteLn('加法 A + B:');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [6.0, 8.0, 10.0, 12.0]');
    
    // 测试减法
    result := VecF32x4_Sub(a, b);
    WriteLn('');
    WriteLn('减法 A - B:');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [-4.0, -4.0, -4.0, -4.0]');
    
    // 测试乘法
    result := VecF32x4_Mul(a, b);
    WriteLn('');
    WriteLn('乘法 A * B:');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [5.0, 12.0, 21.0, 32.0]');
    
    // 测试除法
    result := VecF32x4_Div(b, a);
    WriteLn('');
    WriteLn('除法 B / A:');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [5.0, 3.0, 2.3, 2.0]');
    
    // 测试向量创建函数
    result := VecF32x4_SetAll(42.0);
    WriteLn('');
    WriteLn('SetAll(42.0):');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [42.0, 42.0, 42.0, 42.0]');
    
    // 测试零向量
    result := VecF32x4_Zero;
    WriteLn('');
    WriteLn('Zero():');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [0.0, 0.0, 0.0, 0.0]');
    
    // 测试数学函数
    a := VecF32x4_Set(4.0, 9.0, 16.0, 25.0);
    result := VecF32x4_Sqrt(a);
    WriteLn('');
    WriteLn('Sqrt([4.0, 9.0, 16.0, 25.0]):');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [2.0, 3.0, 4.0, 5.0]');
    
    // 测试 Min/Max
    a := VecF32x4_Set(1.0, 8.0, 3.0, 6.0);
    b := VecF32x4_Set(5.0, 2.0, 7.0, 4.0);
    
    result := VecF32x4_Min(a, b);
    WriteLn('');
    WriteLn('Min([1.0, 8.0, 3.0, 6.0], [5.0, 2.0, 7.0, 4.0]):');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [1.0, 2.0, 3.0, 4.0]');
    
    result := VecF32x4_Max(a, b);
    WriteLn('');
    WriteLn('Max([1.0, 8.0, 3.0, 6.0], [5.0, 2.0, 7.0, 4.0]):');
    WriteLn('  结果: [', result.f[0]:0:1, ', ', result.f[1]:0:1, ', ', result.f[2]:0:1, ', ', result.f[3]:0:1, ']');
    WriteLn('  期望: [5.0, 8.0, 7.0, 6.0]');
    
    // 测试水平操作
    a := VecF32x4_Set(1.0, 2.0, 3.0, 4.0);
    sum := VecF32x4_HorizontalAdd(a);
    WriteLn('');
    WriteLn('HorizontalAdd([1.0, 2.0, 3.0, 4.0]):');
    WriteLn('  结果: ', sum:0:1);
    WriteLn('  期望: 10.0');
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('=== 测试完成 ===');
end;

procedure TestMemoryOperations;
var
  data: array[0..3] of Single;
  vec, loaded: TVecF32x4;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== 内存操作测试 ===');
  
  try
    // 准备测试数据
    data[0] := 10.0;
    data[1] := 20.0;
    data[2] := 30.0;
    data[3] := 40.0;
    
    WriteLn('原始数据: [', data[0]:0:1, ', ', data[1]:0:1, ', ', data[2]:0:1, ', ', data[3]:0:1, ']');
    
    // 测试加载
    loaded := VecF32x4_LoadUnaligned(@data[0]);
    WriteLn('');
    WriteLn('LoadUnaligned:');
    WriteLn('  结果: [', loaded.f[0]:0:1, ', ', loaded.f[1]:0:1, ', ', loaded.f[2]:0:1, ', ', loaded.f[3]:0:1, ']');
    
    // 测试操作
    vec := VecF32x4_Mul(loaded, VecF32x4_SetAll(2.0));
    WriteLn('');
    WriteLn('乘以 2.0:');
    WriteLn('  结果: [', vec.f[0]:0:1, ', ', vec.f[1]:0:1, ', ', vec.f[2]:0:1, ', ', vec.f[3]:0:1, ']');
    
    // 测试存储
    VecF32x4_StoreUnaligned(vec, @data[0]);
    WriteLn('');
    WriteLn('StoreUnaligned 后的数据:');
    Write('  结果: [');
    for i := 0 to 3 do
    begin
      Write(data[i]:0:1);
      if i < 3 then Write(', ');
    end;
    WriteLn(']');
    WriteLn('  期望: [20.0, 40.0, 60.0, 80.0]');
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('=== 内存操作测试完成 ===');
end;

begin
  try
    TestVectorOperations;
    TestMemoryOperations;
  except
    on E: Exception do
      WriteLn('致命错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('按任意键退出...');
  ReadLn;
end.

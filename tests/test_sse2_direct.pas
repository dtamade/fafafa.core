program test_sse2_direct;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd.v2.types,
  fafafa.core.simd.v2.sse2;

var
  A, B, C: TF32x4;
  Value: Single;

begin
  WriteLn('=== 直接测试 SSE2 汇编实现 ===');
  
  try
    // 测试 splat
    WriteLn('测试 SSE2 splat...');
    A := sse2_f32x4_splat(2.0);
    WriteLn('A = [', A.Extract(0):0:1, ', ', A.Extract(1):0:1, ', ', A.Extract(2):0:1, ', ', A.Extract(3):0:1, ']');
    
    // 测试 add
    WriteLn('测试 SSE2 add...');
    B := sse2_f32x4_splat(3.0);
    C := sse2_f32x4_add(A, B);
    WriteLn('B = [', B.Extract(0):0:1, ', ', B.Extract(1):0:1, ', ', B.Extract(2):0:1, ', ', B.Extract(3):0:1, ']');
    WriteLn('C = A + B = [', C.Extract(0):0:1, ', ', C.Extract(1):0:1, ', ', C.Extract(2):0:1, ', ', C.Extract(3):0:1, ']');
    
    // 验证结果
    Value := C.Extract(0);
    if Abs(Value - 5.0) < 0.001 then
      WriteLn('✅ SSE2 测试通过！')
    else
      WriteLn('❌ SSE2 测试失败！期望 5.0，实际 ', Value:0:3);
      
  except
    on E: Exception do
    begin
      WriteLn('❌ SSE2 测试异常：', E.Message);
    end;
  end;
  
  WriteLn('测试完成。');
end.

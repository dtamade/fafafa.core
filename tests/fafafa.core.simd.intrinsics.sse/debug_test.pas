program debug_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse;

var
  a, b, result: TM128;
  nan_val: Single;

begin
  WriteLn('Debug SSE Test');
  WriteLn('==============');
  
  // 测试可能有问题的 NaN 操作
  WriteLn('Testing NaN operations...');
  try
    nan_val := 0.0 / 0.0;  // 创建 NaN
    WriteLn('NaN created: ', nan_val);
    
    a := sse_set_ps(4.0, nan_val, 2.0, 1.0);
    b := sse_set_ps(3.0, 5.0, nan_val, 3.0);
    
    WriteLn('Testing cmpord_ps...');
    result := sse_cmpord_ps(a, b);
    WriteLn('cmpord_ps completed');
    
    WriteLn('Testing cmpunord_ps...');
    result := sse_cmpunord_ps(a, b);
    WriteLn('cmpunord_ps completed');
    
  except
    on E: Exception do
      WriteLn('Exception: ', E.Message);
  end;
  
  // 测试 shuffle 操作
  WriteLn('Testing shuffle operations...');
  try
    a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
    b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
    
    WriteLn('Testing shuffle_ps...');
    result := sse_shuffle_ps(a, b, $E4);
    WriteLn('shuffle_ps completed');
    
  except
    on E: Exception do
      WriteLn('Exception: ', E.Message);
  end;
  
  WriteLn('Debug test completed.');
end.

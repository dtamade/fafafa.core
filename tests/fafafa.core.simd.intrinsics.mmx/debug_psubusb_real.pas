program debug_psubusb_real;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;
  i: Integer;

begin
  WriteLn('Debug Real psubusb Test');
  WriteLn('=======================');
  
  // 测试正常情况
  WriteLn('Testing normal case...');
  a := mmx_set_pi8(100, 80, 60, 40, 20, 10, 5, 2);
  b := mmx_set_pi8(50, 40, 30, 20, 10, 5, 2, 1);
  result := mmx_psubusb(a, b);
  
  Write('a.mm_u8 = [');
  for i := 0 to 7 do
  begin
    Write(a.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b.mm_u8 = [');
  for i := 0 to 7 do
  begin
    Write(b.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('result.mm_u8 = [');
  for i := 0 to 7 do
  begin
    Write(result.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('Expected: [1, 3, 5, 10, 20, 30, 40, 50]');
  
  // 检查是否匹配
  if (result.mm_u8[0] = 1) and (result.mm_u8[1] = 3) and (result.mm_u8[2] = 5) and 
     (result.mm_u8[3] = 10) and (result.mm_u8[4] = 20) and (result.mm_u8[5] = 30) and
     (result.mm_u8[6] = 40) and (result.mm_u8[7] = 50) then
    WriteLn('✓ Normal test PASSED')
  else
    WriteLn('✗ Normal test FAILED');
  
  WriteLn('');
  
  // 测试饱和到0
  WriteLn('Testing saturation to 0...');
  a := mmx_set1_pi8(10);
  b := mmx_set1_pi8(50);
  result := mmx_psubusb(a, b);
  
  Write('a.mm_u8 = [');
  for i := 0 to 7 do
  begin
    Write(a.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b.mm_u8 = [');
  for i := 0 to 7 do
  begin
    Write(b.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('result.mm_u8 = [');
  for i := 0 to 7 do
  begin
    Write(result.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('Expected: [0, 0, 0, 0, 0, 0, 0, 0]');
  
  // 检查是否全为0
  if (result.mm_u64 = 0) then
    WriteLn('✓ Saturation test PASSED')
  else
    WriteLn('✗ Saturation test FAILED');
  
  WriteLn('');
  WriteLn('Debug completed.');
end.

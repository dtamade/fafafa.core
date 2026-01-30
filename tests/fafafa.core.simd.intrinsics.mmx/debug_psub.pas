program debug_psub;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;
  i: Integer;

begin
  WriteLn('Debug psubsb and psubsw Test');
  WriteLn('============================');
  
  // 测试 psubsb
  WriteLn('Testing mmx_psubsb...');
  a := mmx_set_pi8(50, 40, 30, 20, 10, 0, -10, -20);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  result := mmx_psubsb(a, b);
  
  Write('a.mm_i8 = [');
  for i := 0 to 7 do
  begin
    Write(a.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b.mm_i8 = [');
  for i := 0 to 7 do
  begin
    Write(b.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('result.mm_i8 = [');
  for i := 0 to 7 do
  begin
    Write(result.mm_i8[i]);
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
  
  WriteLn('Expected (signed): [40, 20, 0, -20, -40, -60, -80, -100]');
  WriteLn('Expected (unsigned): [40, 20, 0, 236, 216, 196, 176, 156]');
  WriteLn('');
  
  // 测试 psubsw
  WriteLn('Testing mmx_psubsw...');
  a := mmx_set_pi16(1000, 0, -1000, -30000);
  b := mmx_set_pi16(2000, 1000, 2000, 5000);
  result := mmx_psubsw(a, b);
  
  Write('a.mm_i16 = [');
  for i := 0 to 3 do
  begin
    Write(a.mm_i16[i]);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b.mm_i16 = [');
  for i := 0 to 3 do
  begin
    Write(b.mm_i16[i]);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  Write('result.mm_i16 = [');
  for i := 0 to 3 do
  begin
    Write(result.mm_i16[i]);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('Expected: [-1000, -1000, -3000, -32768] (with saturation)');
  WriteLn('');
  WriteLn('Debug completed.');
end.

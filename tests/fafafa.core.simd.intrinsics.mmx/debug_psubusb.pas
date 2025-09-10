program debug_psubusb;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;
  i: Integer;

begin
  WriteLn('Debug psubusb Test');
  WriteLn('==================');
  
  // 测试饱和情况
  a := mmx_set_pi8(100, 50, 25, 10, 200, 150, 75, 5);
  b := mmx_set_pi8(150, 75, 50, 25, 100, 200, 100, 50);
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
  
  WriteLn('');
  WriteLn('Manual calculation (unsigned saturation):');
  for i := 0 to 7 do
  begin
    WriteLn('  [', i, '] ', a.mm_u8[i], ' - ', b.mm_u8[i], ' = ', 
            LongInt(a.mm_u8[i]) - LongInt(b.mm_u8[i]), 
            ' -> ', result.mm_u8[i]);
  end;
  
  WriteLn('');
  WriteLn('Expected: [0, 0, 0, 0, 100, 0, 0, 0]');
  WriteLn('');
  WriteLn('Debug completed.');
end.

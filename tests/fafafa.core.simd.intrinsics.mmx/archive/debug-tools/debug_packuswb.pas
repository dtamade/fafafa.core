program debug_packuswb;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;
  i: Integer;

begin
  WriteLn('Debug packuswb Test');
  WriteLn('===================');
  
  // 测试饱和情况
  a := mmx_set_pi16(300, -100, 255, 0);
  b := mmx_set_pi16(1000, -50, 128, 64);
  result := mmx_packuswb(a, b);
  
  WriteLn('a = mmx_set_pi16(300, -100, 255, 0)');
  Write('a.mm_i16 = [');
  for i := 0 to 3 do
  begin
    Write(a.mm_i16[i]);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('b = mmx_set_pi16(1000, -50, 128, 64)');
  Write('b.mm_i16 = [');
  for i := 0 to 3 do
  begin
    Write(b.mm_i16[i]);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('result = mmx_packuswb(a, b)');
  Write('result.mm_u8 = [');
  for i := 0 to 7 do
  begin
    Write(result.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('Expected: [0, 255, 0, 255, 64, 128, 0, 255]');
  
  WriteLn('');
  WriteLn('Debug completed.');
end.

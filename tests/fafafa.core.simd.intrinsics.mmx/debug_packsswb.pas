program debug_packsswb;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;
  i: Integer;

begin
  WriteLn('Debug packsswb Test');
  WriteLn('===================');
  
  // 测试正常情况
  a := mmx_set_pi16(100, 50, 25, 10);
  b := mmx_set_pi16(200, 150, 75, 5);
  result := mmx_packsswb(a, b);
  
  WriteLn('a = mmx_set_pi16(100, 50, 25, 10)');
  Write('a.mm_i16 = [');
  for i := 0 to 3 do
  begin
    Write(a.mm_i16[i]);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('b = mmx_set_pi16(200, 150, 75, 5)');
  Write('b.mm_i16 = [');
  for i := 0 to 3 do
  begin
    Write(b.mm_i16[i]);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn('result = mmx_packsswb(a, b)');
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
  
  WriteLn('Expected: [10, 25, 50, 100, 5, 75, 127, 127]');
  
  WriteLn('');
  WriteLn('Debug completed.');
end.

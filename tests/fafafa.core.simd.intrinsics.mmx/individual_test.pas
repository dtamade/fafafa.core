program individual_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

// 简化的断言函数
procedure AssertTM64ByteArray(const Expected: array of Byte; const Actual: TM64; const Msg: string);
var
  i: Integer;
  Failed: Boolean;
begin
  Failed := False;
  if Length(Expected) <> 8 then
  begin
    WriteLn('FAIL: ', Msg, ' - Expected array length 8, got ', Length(Expected));
    Failed := True;
  end;
  
  for i := 0 to 7 do
  begin
    if Expected[i] <> Actual.mm_u8[i] then
    begin
      WriteLn('FAIL: ', Msg, ' - byte[', i, '] expected ', Expected[i], ', got ', Actual.mm_u8[i]);
      Failed := True;
    end;
  end;
  
  if not Failed then
    WriteLn('PASS: ', Msg);
end;

var
  a, b, result: TM64;

begin
  WriteLn('Individual MMX Tests');
  WriteLn('===================');
  WriteLn('');
  
  // 测试 packsswb 正常情况
  WriteLn('Testing mmx_packsswb normal case...');
  a := mmx_set_pi16(100, 50, 25, 10);
  b := mmx_set_pi16(200, 150, 75, 5);
  result := mmx_packsswb(a, b);
  AssertTM64ByteArray([10, 25, 50, 100, 5, 75, 127, 127], result, 'packsswb normal');
  
  // 测试 packsswb 饱和情况
  WriteLn('Testing mmx_packsswb saturation case...');
  a := mmx_set_pi16(300, -300, 127, -128);
  b := mmx_set_pi16(1000, -1000, 50, -50);
  result := mmx_packsswb(a, b);
  AssertTM64ByteArray([128, 127, 128, 127, 206, 50, 128, 127], result, 'packsswb saturation');
  
  // 测试 set1_pi8 负数
  WriteLn('Testing mmx_set1_pi8 negative...');
  result := mmx_set1_pi8(-10);
  AssertTM64ByteArray([246, 246, 246, 246, 246, 246, 246, 246], result, 'set1_pi8(-10)');
  
  // 测试 paddsb 负向饱和
  WriteLn('Testing mmx_paddsb negative saturation...');
  a := mmx_set1_pi8(-100);
  b := mmx_set1_pi8(-50);
  result := mmx_paddsb(a, b);
  AssertTM64ByteArray([128, 128, 128, 128, 128, 128, 128, 128], result, 'paddsb negative saturation');
  
  WriteLn('');
  WriteLn('Individual tests completed.');
end.

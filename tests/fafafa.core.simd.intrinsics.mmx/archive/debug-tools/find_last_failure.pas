program find_last_failure;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

// 简化的断言函数
procedure AssertTM64ByteArray(const Expected: array of Byte; const Actual: TM64; const TestName: string);
var
  i: Integer;
  Failed: Boolean;
begin
  Failed := False;
  for i := 0 to 7 do
  begin
    if Expected[i] <> Actual.mm_u8[i] then
    begin
      WriteLn('FAIL: ', TestName, ' - byte[', i, '] expected ', Expected[i], ', got ', Actual.mm_u8[i]);
      Failed := True;
    end;
  end;
  
  if not Failed then
    WriteLn('PASS: ', TestName);
end;

procedure AssertTM64WordArray(const Expected: array of SmallInt; const Actual: TM64; const TestName: string);
var
  i: Integer;
  Failed: Boolean;
begin
  Failed := False;
  for i := 0 to 3 do
  begin
    if Expected[i] <> Actual.mm_i16[i] then
    begin
      WriteLn('FAIL: ', TestName, ' - word[', i, '] expected ', Expected[i], ', got ', Actual.mm_i16[i]);
      Failed := True;
    end;
  end;
  
  if not Failed then
    WriteLn('PASS: ', TestName);
end;

procedure AssertEquals(const Expected, Actual: UInt64; const TestName: string);
begin
  if Expected <> Actual then
    WriteLn('FAIL: ', TestName, ' - expected ', Expected, ', got ', Actual)
  else
    WriteLn('PASS: ', TestName);
end;

// 测试可能失败的函数
procedure TestSuspiciousFunctions;
var
  a, b, result: TM64;
begin
  WriteLn('Testing suspicious functions...');
  WriteLn('');
  
  // 测试 packuswb 饱和情况
  WriteLn('Testing mmx_packuswb saturation...');
  a := mmx_set_pi16(300, -100, 255, 0);
  b := mmx_set_pi16(1000, -50, 128, 64);
  result := mmx_packuswb(a, b);
  AssertTM64ByteArray([0, 255, 0, 255, 64, 128, 0, 255], result, 'packuswb saturation');
  
  // 测试 psubusb 饱和情况
  WriteLn('Testing mmx_psubusb saturation...');
  a := mmx_set_pi8(100, 50, 25, 10, 200, 150, 75, 5);
  b := mmx_set_pi8(150, 75, 50, 25, 100, 200, 100, 50);
  result := mmx_psubusb(a, b);
  AssertTM64ByteArray([0, 0, 0, 0, 0, 100, 0, 0], result, 'psubusb saturation');
  
  // 测试 psubusw 饱和情况
  WriteLn('Testing mmx_psubusw saturation...');
  a := mmx_set_pi16(1000, 500, 2000, 100);
  b := mmx_set_pi16(1500, 300, 3000, 200);
  result := mmx_psubusw(a, b);
  AssertTM64WordArray([0, 0, 200, 0], result, 'psubusw saturation');
  
  WriteLn('');
end;

begin
  WriteLn('Finding Last Failure');
  WriteLn('====================');
  WriteLn('');
  
  TestSuspiciousFunctions;
  
  WriteLn('Test completed.');
end.

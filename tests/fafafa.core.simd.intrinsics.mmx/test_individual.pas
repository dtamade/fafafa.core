program test_individual;

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
  if Length(Expected) <> 8 then
  begin
    WriteLn('FAIL: ', TestName, ' - Expected array length 8, got ', Length(Expected));
    Failed := True;
  end;
  
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
  if Length(Expected) <> 4 then
  begin
    WriteLn('FAIL: ', TestName, ' - Expected array length 4, got ', Length(Expected));
    Failed := True;
  end;
  
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
procedure TestPossibleFailures;
var
  a, b, result: TM64;
begin
  WriteLn('Testing possible failure cases...');
  WriteLn('');
  
  // 测试 por 函数
  WriteLn('Testing mmx_por...');
  a.mm_u64 := UInt64(17361641481138401520);  // $F0F0F0F0F0F0F0F0
  b.mm_u64 := UInt64(12297829382473034410); // $AAAAAAAAAAAAAAAA
  result := mmx_por(a, b);
  AssertEquals(UInt64(18077129492005502970), result.mm_u64, 'mmx_por'); // $FAFAFAFAFAFAFAFAFA
  
  // 测试 psubsb 函数
  WriteLn('Testing mmx_psubsb...');
  a := mmx_set_pi8(50, 40, 30, 20, 10, 0, -10, -20);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  result := mmx_psubsb(a, b);
  AssertTM64ByteArray([156, 176, 196, 216, 236, 0, 20, 40], result, 'mmx_psubsb with saturation');
  
  // 测试 psubsw 函数
  WriteLn('Testing mmx_psubsw...');
  a := mmx_set_pi16(1000, 0, -1000, -30000);
  b := mmx_set_pi16(2000, 1000, 2000, 5000);
  result := mmx_psubsw(a, b);
  AssertTM64WordArray([-32768, -3000, -1000, -1000], result, 'mmx_psubsw with saturation');
  
  WriteLn('');
end;

begin
  WriteLn('Individual MMX Test - Finding Failures');
  WriteLn('======================================');
  WriteLn('');
  
  TestPossibleFailures;
  
  WriteLn('Individual test completed.');
end.

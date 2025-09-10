program manual_test_runner;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.mmx.testcase;

procedure RunSingleTest(TestClass: TTestCaseClass; TestMethod: string);
var
  TestCase: TTestCase;
  TestResult: TTestResult;
begin
  TestCase := TestClass.CreateWithName(TestMethod);
  TestResult := TTestResult.Create;
  try
    TestCase.Run(TestResult);
    if TestResult.NumberOfFailures > 0 then
      WriteLn('FAIL: ', TestMethod)
    else if TestResult.NumberOfErrors > 0 then
      WriteLn('ERROR: ', TestMethod)
    else
      WriteLn('PASS: ', TestMethod);
  finally
    TestResult.Free;
    TestCase.Free;
  end;
end;

begin
  WriteLn('Manual Test Runner');
  WriteLn('==================');
  WriteLn('');
  
  // 测试一些可能有问题的测试
  WriteLn('Testing potentially problematic tests...');
  
  RunSingleTest(TTestCase_TM64, 'Test_mmx_por');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_pxor');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_psubsb');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_psubsw');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_psubusb');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_packuswb');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_packsswb');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_set1_pi8');
  RunSingleTest(TTestCase_TM64, 'Test_mmx_paddsb');
  
  WriteLn('');
  WriteLn('Manual test completed.');
end.

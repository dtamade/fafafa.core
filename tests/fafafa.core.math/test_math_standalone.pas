program test_math_standalone;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.math;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Assert(Condition: Boolean; const TestName: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  ✗ ', TestName, ' FAILED');
  end;
end;

procedure AssertEquals(Expected, Actual: Integer; const TestName: string);
begin
  Assert(Expected = Actual, TestName + Format(' (expected %d, got %d)', [Expected, Actual]));
end;

procedure AssertEquals64(Expected, Actual: Int64; const TestName: string);
begin
  Assert(Expected = Actual, TestName + Format(' (expected %d, got %d)', [Expected, Actual]));
end;

// === Min 函数测试 ===
procedure Test_Min;
begin
  WriteLn('Testing Min function:');
  AssertEquals(3, Min(3, 5), 'Min(3, 5)');
  AssertEquals(1, Min(10, 1), 'Min(10, 1)');
  AssertEquals(-5, Min(-3, -5), 'Min(-3, -5)');
  AssertEquals(-10, Min(-10, -1), 'Min(-10, -1)');
  AssertEquals(-3, Min(-3, 5), 'Min(-3, 5)');
  AssertEquals(5, Min(5, 5), 'Min(5, 5)');
  AssertEquals(0, Min(High(Integer), 0), 'Min(MaxInt, 0)');
  AssertEquals(Low(Integer), Min(Low(Integer), 0), 'Min(MinInt, 0)');
end;

// === Max 函数测试 ===
procedure Test_Max;
begin
  WriteLn('Testing Max function:');
  AssertEquals(5, Max(3, 5), 'Max(3, 5)');
  AssertEquals(10, Max(10, 1), 'Max(10, 1)');
  AssertEquals(-3, Max(-3, -5), 'Max(-3, -5)');
  AssertEquals(-1, Max(-10, -1), 'Max(-10, -1)');
  AssertEquals(5, Max(-3, 5), 'Max(-3, 5)');
  AssertEquals(5, Max(5, 5), 'Max(5, 5)');
  AssertEquals(High(Integer), Max(High(Integer), 0), 'Max(MaxInt, 0)');
  AssertEquals(0, Max(Low(Integer), 0), 'Max(MinInt, 0)');
end;

// === Ceil 函数测试 ===
procedure Test_Ceil;
begin
  WriteLn('Testing Ceil function:');
  AssertEquals(3, Ceil(2.1), 'Ceil(2.1)');
  AssertEquals(3, Ceil(2.5), 'Ceil(2.5)');
  AssertEquals(3, Ceil(2.9), 'Ceil(2.9)');
  AssertEquals(5, Ceil(5.0), 'Ceil(5.0)');
  AssertEquals(-2, Ceil(-2.1), 'Ceil(-2.1)');
  AssertEquals(-2, Ceil(-2.9), 'Ceil(-2.9)');
  AssertEquals(0, Ceil(0.0), 'Ceil(0.0)');
  AssertEquals(1, Ceil(0.0001), 'Ceil(0.0001)');
  AssertEquals(1, Ceil(0.9999), 'Ceil(0.9999)');
end;

// === Ceil64 函数测试 ===
procedure Test_Ceil64;
begin
  WriteLn('Testing Ceil64 function:');
  AssertEquals64(3, Ceil64(2.1), 'Ceil64(2.1)');
  AssertEquals64(3, Ceil64(2.9), 'Ceil64(2.9)');
  AssertEquals64(5, Ceil64(5.0), 'Ceil64(5.0)');
  AssertEquals64(-2, Ceil64(-2.1), 'Ceil64(-2.1)');
  AssertEquals64(3000000000, Ceil64(2999999999.1), 'Ceil64(2999999999.1)');
  AssertEquals64(3000000000, Ceil64(3000000000.0), 'Ceil64(3000000000.0)');
end;

// === IsAddOverflow SizeUInt 测试 ===
procedure Test_IsAddOverflow_SizeUInt;
begin
  WriteLn('Testing IsAddOverflow (SizeUInt):');
  Assert(not IsAddOverflow(SizeUInt(10), SizeUInt(20)), 'NoOverflow: 10 + 20');
  Assert(not IsAddOverflow(SizeUInt(0), SizeUInt(0)), 'NoOverflow: 0 + 0');
  Assert(not IsAddOverflow(MAX_SIZE_UINT, SizeUInt(0)), 'NoOverflow: MAX + 0');
  Assert(not IsAddOverflow(MAX_SIZE_UINT - 1, SizeUInt(1)), 'NoOverflow: MAX-1 + 1');
  Assert(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(1)), 'Overflow: MAX + 1');
  Assert(IsAddOverflow(MAX_SIZE_UINT, MAX_SIZE_UINT), 'Overflow: MAX + MAX');
  Assert(IsAddOverflow(MAX_SIZE_UINT - 10, SizeUInt(20)), 'Overflow: MAX-10 + 20');
  Assert(IsAddOverflow(MAX_SIZE_UINT div 2 + 1, MAX_SIZE_UINT div 2 + 1), 'Overflow: MAX/2+1 + MAX/2+1');
end;

// === IsAddOverflow UInt32 测试 ===
procedure Test_IsAddOverflow_UInt32;
begin
  WriteLn('Testing IsAddOverflow (UInt32):');
  Assert(not IsAddOverflow(UInt32(10), UInt32(20)), 'NoOverflow: 10 + 20');
  Assert(not IsAddOverflow(UInt32(0), UInt32(0)), 'NoOverflow: 0 + 0');
  Assert(not IsAddOverflow(MAX_UINT32, UInt32(0)), 'NoOverflow: MAX + 0');
  Assert(not IsAddOverflow(MAX_UINT32 - 1, UInt32(1)), 'NoOverflow: MAX-1 + 1');
  Assert(IsAddOverflow(MAX_UINT32, UInt32(1)), 'Overflow: MAX + 1');
  Assert(IsAddOverflow(MAX_UINT32, MAX_UINT32), 'Overflow: MAX + MAX');
  Assert(IsAddOverflow(MAX_UINT32 - 10, UInt32(20)), 'Overflow: MAX-10 + 20');
  Assert(IsAddOverflow(MAX_UINT32 div 2 + 1, MAX_UINT32 div 2 + 1), 'Overflow: MAX/2+1 + MAX/2+1');
end;

begin
  WriteLn('=== fafafa.core.math Unit Tests ===');
  WriteLn;

  Test_Min;
  WriteLn;
  Test_Max;
  WriteLn;
  Test_Ceil;
  WriteLn;
  Test_Ceil64;
  WriteLn;
  Test_IsAddOverflow_SizeUInt;
  WriteLn;
  Test_IsAddOverflow_UInt32;
  WriteLn;

  WriteLn('=================================');
  WriteLn(Format('Results: %d passed, %d failed', [TestsPassed, TestsFailed]));

  if TestsFailed > 0 then
    Halt(1);

  WriteLn('All tests passed!');
end.

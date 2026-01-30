program example_math;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.math.base,
  fafafa.core.math;

procedure DemoOverflowDetection;
begin
  WriteLn('=== 溢出检测 ===');
  WriteLn('IsAddOverflow(100, 50): ', IsAddOverflow(SizeUInt(100), SizeUInt(50)));
  WriteLn('IsSubUnderflow(10, 20): ', IsSubUnderflow(SizeUInt(10), SizeUInt(20)));
  WriteLn;
end;

procedure DemoSaturating;
begin
  WriteLn('=== 饱和运算 ===');
  WriteLn('SaturatingSub(10, 100): ', SaturatingSub(SizeUInt(10), SizeUInt(100)));
  WriteLn;
end;

procedure DemoChecked;
var
  R: TOptionalU32;
begin
  WriteLn('=== Checked 运算 ===');
  
  R := CheckedAddU32(100, 50);
  if R.Valid then
    WriteLn('CheckedAddU32(100, 50) = ', R.Value)
  else
    WriteLn('CheckedAddU32(100, 50) = None (溢出)');
  
  R := CheckedDivU32(100, 0);
  if R.Valid then
    WriteLn('CheckedDivU32(100, 0) = ', R.Value)
  else
    WriteLn('CheckedDivU32(100, 0) = None (除零)');
  WriteLn;
end;

procedure DemoOverflowing;
var
  R: TOverflowU32;
begin
  WriteLn('=== Overflowing 运算 ===');
  
  R := OverflowingAddU32(100, 50);
  WriteLn('OverflowingAddU32(100, 50):');
  WriteLn('  Value: ', R.Value);
  WriteLn('  Overflowed: ', R.Overflowed);
  WriteLn;
end;

procedure DemoWrapping;
begin
  WriteLn('=== Wrapping 运算 ===');
  WriteLn('WrappingSubU32(0, 1): ', WrappingSubU32(0, 1));
  WriteLn;
end;

procedure DemoFloatFunctions;
begin
  WriteLn('=== 浮点数运算 ===');
  WriteLn('Abs(-3.14): ', Abs(-3.14):0:2);
  WriteLn('Min(10.5, 3.2): ', Min(10.5, 3.2):0:2);
  WriteLn('Max(10.5, 3.2): ', Max(10.5, 3.2):0:2);
  WriteLn('Clamp(15.0, 0.0, 10.0): ', Clamp(15.0, 0.0, 10.0):0:2);
  WriteLn('Floor(3.7): ', Floor(3.7));
  WriteLn('Ceil(3.2): ', Ceil(3.2));
  WriteLn('Round(3.5): ', Round(3.5));
  WriteLn('Sqrt(16.0): ', Sqrt(16.0):0:2);
  WriteLn;
end;

procedure DemoIntegerUtils;
begin
  WriteLn('=== 整数工具 ===');
  WriteLn('IsPowerOfTwo(8): ', IsPowerOfTwo(8));
  WriteLn('IsPowerOfTwo(10): ', IsPowerOfTwo(10));
  WriteLn('NextPowerOfTwo(10): ', NextPowerOfTwo(10));
  WriteLn('AlignUp(17, 8): ', AlignUp(17, 8));
  WriteLn('AlignDown(17, 8): ', AlignDown(17, 8));
  WriteLn('DivRoundUp(10, 3): ', DivRoundUp(10, 3));
  WriteLn;
end;

procedure DemoTrigFunctions;
begin
  WriteLn('=== 三角函数 ===');
  WriteLn('Sin(PI/2): ', Sin(PI/2):0:4);
  WriteLn('Cos(0): ', Cos(0.0):0:4);
  WriteLn('RadToDeg(PI): ', RadToDeg(PI):0:2);
  WriteLn('DegToRad(180): ', DegToRad(180.0):0:4);
  WriteLn;
end;

begin
  WriteLn('fafafa.core.math 示例程序');
  WriteLn('=========================');
  WriteLn;
  
  DemoOverflowDetection;
  DemoSaturating;
  DemoChecked;
  DemoOverflowing;
  DemoWrapping;
  DemoFloatFunctions;
  DemoIntegerUtils;
  DemoTrigFunctions;
  
  WriteLn('示例程序完成!');
end.

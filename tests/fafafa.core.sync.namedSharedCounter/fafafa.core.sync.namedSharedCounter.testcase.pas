{$CODEPAGE UTF8}
unit fafafa.core.sync.namedSharedCounter.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.namedSharedCounter, fafafa.core.sync.base;

type
  // 工厂函数测试
  TTestCase_Factory = class(TTestCase)
  published
    procedure Test_MakeNamedSharedCounter;
    procedure Test_MakeNamedSharedCounter_WithConfig;
    procedure Test_DefaultConfig;
    procedure Test_GlobalConfig;
    procedure Test_ConfigWithInitial;
  end;

  // 基础功能测试
  TTestCase_Basic = class(TTestCase)
  private
    FCounter: INamedSharedCounter;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_InitialValue_Zero;
    procedure Test_Increment;
    procedure Test_Decrement;
    procedure Test_Add;
    procedure Test_Sub;
    procedure Test_GetValue;
    procedure Test_SetValue;
    procedure Test_GetName;
  end;

  // 原子操作测试
  TTestCase_Atomic = class(TTestCase)
  private
    FCounter: INamedSharedCounter;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Exchange;
    procedure Test_CompareExchange_Success;
    procedure Test_CompareExchange_Failure;
  end;

  // 初始值测试
  TTestCase_InitialValue = class(TTestCase)
  published
    procedure Test_InitialValue_Custom;
    procedure Test_InitialValue_Negative;
    procedure Test_InitialValue_Large;
  end;

  // 边界条件测试
  TTestCase_Boundary = class(TTestCase)
  private
    FCounter: INamedSharedCounter;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Increment_Multiple;
    procedure Test_Decrement_ToNegative;
    procedure Test_Add_Large;
  end;

implementation

{ TTestCase_Factory }

procedure TTestCase_Factory.Test_MakeNamedSharedCounter;
var
  LCounter: INamedSharedCounter;
begin
  LCounter := MakeNamedSharedCounter('TestCounter_Factory1');
  CheckNotNull(LCounter, 'MakeNamedSharedCounter should return instance');
  CheckEquals('TestCounter_Factory1', LCounter.GetName, 'Name should match');
  CheckEquals(0, LCounter.GetValue, 'Initial value should be 0');
end;

procedure TTestCase_Factory.Test_MakeNamedSharedCounter_WithConfig;
var
  LCounter: INamedSharedCounter;
  LConfig: TNamedSharedCounterConfig;
begin
  LConfig := NamedSharedCounterConfigWithInitial(100);
  LCounter := MakeNamedSharedCounter('TestCounter_Factory2', LConfig);
  CheckNotNull(LCounter, 'MakeNamedSharedCounter with config should return instance');
  CheckEquals(100, LCounter.GetValue, 'Initial value should be 100');
end;

procedure TTestCase_Factory.Test_DefaultConfig;
var
  LConfig: TNamedSharedCounterConfig;
begin
  LConfig := DefaultNamedSharedCounterConfig;
  CheckFalse(LConfig.UseGlobalNamespace, 'Default should not use global namespace');
  CheckEquals(0, LConfig.InitialValue, 'Default initial value should be 0');
end;

procedure TTestCase_Factory.Test_GlobalConfig;
var
  LConfig: TNamedSharedCounterConfig;
begin
  LConfig := GlobalNamedSharedCounterConfig;
  CheckTrue(LConfig.UseGlobalNamespace, 'Global config should use global namespace');
end;

procedure TTestCase_Factory.Test_ConfigWithInitial;
var
  LConfig: TNamedSharedCounterConfig;
begin
  LConfig := NamedSharedCounterConfigWithInitial(42);
  CheckEquals(42, LConfig.InitialValue, 'Initial value should be 42');
end;

{ TTestCase_Basic }

procedure TTestCase_Basic.SetUp;
begin
  FCounter := MakeNamedSharedCounter('TestCounter_Basic_' + IntToStr(Random(100000)));
end;

procedure TTestCase_Basic.TearDown;
begin
  FCounter := nil;
end;

procedure TTestCase_Basic.Test_InitialValue_Zero;
begin
  CheckEquals(0, FCounter.GetValue, 'Initial value should be 0');
end;

procedure TTestCase_Basic.Test_Increment;
begin
  CheckEquals(1, FCounter.Increment, 'Increment should return 1');
  CheckEquals(1, FCounter.GetValue, 'Value should be 1');

  CheckEquals(2, FCounter.Increment, 'Increment should return 2');
  CheckEquals(2, FCounter.GetValue, 'Value should be 2');
end;

procedure TTestCase_Basic.Test_Decrement;
begin
  FCounter.SetValue(5);
  CheckEquals(4, FCounter.Decrement, 'Decrement should return 4');
  CheckEquals(4, FCounter.GetValue, 'Value should be 4');
end;

procedure TTestCase_Basic.Test_Add;
begin
  CheckEquals(10, FCounter.Add(10), 'Add(10) should return 10');
  CheckEquals(10, FCounter.GetValue, 'Value should be 10');

  CheckEquals(25, FCounter.Add(15), 'Add(15) should return 25');
  CheckEquals(25, FCounter.GetValue, 'Value should be 25');
end;

procedure TTestCase_Basic.Test_Sub;
begin
  FCounter.SetValue(100);
  CheckEquals(70, FCounter.Sub(30), 'Sub(30) should return 70');
  CheckEquals(70, FCounter.GetValue, 'Value should be 70');
end;

procedure TTestCase_Basic.Test_GetValue;
begin
  FCounter.SetValue(42);
  CheckEquals(42, FCounter.GetValue, 'GetValue should return 42');
end;

procedure TTestCase_Basic.Test_SetValue;
begin
  FCounter.SetValue(123);
  CheckEquals(123, FCounter.GetValue, 'Value should be 123 after SetValue');

  FCounter.SetValue(-50);
  CheckEquals(-50, FCounter.GetValue, 'Value should be -50 after SetValue');
end;

procedure TTestCase_Basic.Test_GetName;
begin
  CheckTrue(Pos('TestCounter_Basic_', FCounter.GetName) = 1, 'Name should start with expected prefix');
end;

{ TTestCase_Atomic }

procedure TTestCase_Atomic.SetUp;
begin
  FCounter := MakeNamedSharedCounter('TestCounter_Atomic_' + IntToStr(Random(100000)));
end;

procedure TTestCase_Atomic.TearDown;
begin
  FCounter := nil;
end;

procedure TTestCase_Atomic.Test_Exchange;
begin
  FCounter.SetValue(10);
  CheckEquals(10, FCounter.Exchange(20), 'Exchange should return old value 10');
  CheckEquals(20, FCounter.GetValue, 'Value should be 20 after Exchange');
end;

procedure TTestCase_Atomic.Test_CompareExchange_Success;
var
  LOld: Int64;
begin
  FCounter.SetValue(50);
  LOld := FCounter.CompareExchange(50, 100);
  CheckEquals(50, LOld, 'CompareExchange should return old value when successful');
  CheckEquals(100, FCounter.GetValue, 'Value should be 100 after successful CAS');
end;

procedure TTestCase_Atomic.Test_CompareExchange_Failure;
var
  LOld: Int64;
begin
  FCounter.SetValue(50);
  LOld := FCounter.CompareExchange(999, 100);  // 999 != 50，应该失败
  CheckEquals(50, LOld, 'CompareExchange should return current value on failure');
  CheckEquals(50, FCounter.GetValue, 'Value should still be 50 after failed CAS');
end;

{ TTestCase_InitialValue }

procedure TTestCase_InitialValue.Test_InitialValue_Custom;
var
  LConfig: TNamedSharedCounterConfig;
  LCounter: INamedSharedCounter;
begin
  LConfig := NamedSharedCounterConfigWithInitial(1000);
  LCounter := MakeNamedSharedCounter('TestCounter_Custom_' + IntToStr(Random(100000)), LConfig);
  CheckEquals(1000, LCounter.GetValue, 'Initial value should be 1000');
end;

procedure TTestCase_InitialValue.Test_InitialValue_Negative;
var
  LConfig: TNamedSharedCounterConfig;
  LCounter: INamedSharedCounter;
begin
  LConfig := NamedSharedCounterConfigWithInitial(-500);
  LCounter := MakeNamedSharedCounter('TestCounter_Neg_' + IntToStr(Random(100000)), LConfig);
  CheckEquals(-500, LCounter.GetValue, 'Initial value should be -500');
end;

procedure TTestCase_InitialValue.Test_InitialValue_Large;
var
  LConfig: TNamedSharedCounterConfig;
  LCounter: INamedSharedCounter;
  LLargeValue: Int64;
begin
  LLargeValue := Int64(1000000000) * 1000;  // 1 trillion
  LConfig := NamedSharedCounterConfigWithInitial(LLargeValue);
  LCounter := MakeNamedSharedCounter('TestCounter_Large_' + IntToStr(Random(100000)), LConfig);
  CheckEquals(LLargeValue, LCounter.GetValue, 'Initial value should be large number');
end;

{ TTestCase_Boundary }

procedure TTestCase_Boundary.SetUp;
begin
  FCounter := MakeNamedSharedCounter('TestCounter_Boundary_' + IntToStr(Random(100000)));
end;

procedure TTestCase_Boundary.TearDown;
begin
  FCounter := nil;
end;

procedure TTestCase_Boundary.Test_Increment_Multiple;
var
  I: Integer;
begin
  for I := 1 to 100 do
    FCounter.Increment;
  CheckEquals(100, FCounter.GetValue, 'Value should be 100 after 100 increments');
end;

procedure TTestCase_Boundary.Test_Decrement_ToNegative;
begin
  FCounter.Decrement;
  CheckEquals(-1, FCounter.GetValue, 'Value should be -1');

  FCounter.Decrement;
  CheckEquals(-2, FCounter.GetValue, 'Value should be -2');
end;

procedure TTestCase_Boundary.Test_Add_Large;
var
  LLargeValue: Int64;
begin
  LLargeValue := Int64(High(Int32)) + 1;  // 超过 Int32 范围
  FCounter.Add(LLargeValue);
  CheckEquals(LLargeValue, FCounter.GetValue, 'Should handle large values correctly');
end;

initialization
  Randomize;
  RegisterTest(TTestCase_Factory);
  RegisterTest(TTestCase_Basic);
  RegisterTest(TTestCase_Atomic);
  RegisterTest(TTestCase_InitialValue);
  RegisterTest(TTestCase_Boundary);

end.

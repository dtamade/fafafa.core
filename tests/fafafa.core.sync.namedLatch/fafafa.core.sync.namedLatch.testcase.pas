{$CODEPAGE UTF8}
unit fafafa.core.sync.namedLatch.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.namedLatch, fafafa.core.sync.base;

type
  // 工厂函数测试
  TTestCase_Factory = class(TTestCase)
  published
    procedure Test_MakeNamedLatch;
    procedure Test_MakeNamedLatch_WithConfig;
    procedure Test_DefaultConfig;
    procedure Test_GlobalConfig;
  end;

  // 基础功能测试
  TTestCase_Basic = class(TTestCase)
  private
    FLatch: INamedLatch;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_InitialCount;
    procedure Test_CountDown;
    procedure Test_CountDownBy;
    procedure Test_IsOpen_Initially_False;
    procedure Test_IsOpen_After_CountDown;
    procedure Test_GetName;
  end;

  // Wait 功能测试
  TTestCase_Wait = class(TTestCase)
  private
    FLatch: INamedLatch;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_TryWait_BeforeOpen;
    procedure Test_TryWait_AfterOpen;
    procedure Test_Wait_Timeout;
    procedure Test_Wait_Success;
  end;

  // 边界条件测试
  TTestCase_Boundary = class(TTestCase)
  published
    procedure Test_InitialCount_Zero;
    procedure Test_CountDownBy_ExceedsCount;
    procedure Test_CountDown_AlreadyZero;
  end;

implementation

{ TTestCase_Factory }

procedure TTestCase_Factory.Test_MakeNamedLatch;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('TestLatch_Factory1', 3);
  CheckNotNull(LLatch, 'MakeNamedLatch should return instance');
  CheckEquals('TestLatch_Factory1', LLatch.GetName, 'Name should match');
  CheckEquals(3, LLatch.GetCount, 'Initial count should be 3');
end;

procedure TTestCase_Factory.Test_MakeNamedLatch_WithConfig;
var
  LLatch: INamedLatch;
  LConfig: TNamedLatchConfig;
begin
  LConfig := NamedLatchConfigWithTimeout(5000);
  LLatch := MakeNamedLatch('TestLatch_Factory2', 5, LConfig);
  CheckNotNull(LLatch, 'MakeNamedLatch with config should return instance');
  CheckEquals(5, LLatch.GetCount, 'Count should be 5');
end;

procedure TTestCase_Factory.Test_DefaultConfig;
var
  LConfig: TNamedLatchConfig;
begin
  LConfig := DefaultNamedLatchConfig;
  CheckEquals(30000, LConfig.TimeoutMs, 'Default timeout should be 30000ms');
  CheckFalse(LConfig.UseGlobalNamespace, 'Default should not use global namespace');
end;

procedure TTestCase_Factory.Test_GlobalConfig;
var
  LConfig: TNamedLatchConfig;
begin
  LConfig := GlobalNamedLatchConfig;
  CheckTrue(LConfig.UseGlobalNamespace, 'Global config should use global namespace');
end;

{ TTestCase_Basic }

procedure TTestCase_Basic.SetUp;
begin
  FLatch := MakeNamedLatch('TestLatch_Basic_' + IntToStr(Random(100000)), 3);
end;

procedure TTestCase_Basic.TearDown;
begin
  FLatch := nil;
end;

procedure TTestCase_Basic.Test_InitialCount;
begin
  CheckEquals(3, FLatch.GetCount, 'Initial count should be 3');
end;

procedure TTestCase_Basic.Test_CountDown;
begin
  FLatch.CountDown;
  CheckEquals(2, FLatch.GetCount, 'Count should be 2 after CountDown');

  FLatch.CountDown;
  CheckEquals(1, FLatch.GetCount, 'Count should be 1 after second CountDown');

  FLatch.CountDown;
  CheckEquals(0, FLatch.GetCount, 'Count should be 0 after third CountDown');
end;

procedure TTestCase_Basic.Test_CountDownBy;
begin
  FLatch.CountDownBy(2);
  CheckEquals(1, FLatch.GetCount, 'Count should be 1 after CountDownBy(2)');
end;

procedure TTestCase_Basic.Test_IsOpen_Initially_False;
begin
  CheckFalse(FLatch.IsOpen, 'Latch should not be open initially');
end;

procedure TTestCase_Basic.Test_IsOpen_After_CountDown;
begin
  FLatch.CountDown;
  FLatch.CountDown;
  CheckFalse(FLatch.IsOpen, 'Latch should not be open with count=1');

  FLatch.CountDown;
  CheckTrue(FLatch.IsOpen, 'Latch should be open when count=0');
end;

procedure TTestCase_Basic.Test_GetName;
begin
  CheckTrue(Pos('TestLatch_Basic_', FLatch.GetName) = 1, 'Name should start with expected prefix');
end;

{ TTestCase_Wait }

procedure TTestCase_Wait.SetUp;
begin
  FLatch := MakeNamedLatch('TestLatch_Wait_' + IntToStr(Random(100000)), 2);
end;

procedure TTestCase_Wait.TearDown;
begin
  FLatch := nil;
end;

procedure TTestCase_Wait.Test_TryWait_BeforeOpen;
begin
  CheckFalse(FLatch.TryWait, 'TryWait should return false before latch is open');
end;

procedure TTestCase_Wait.Test_TryWait_AfterOpen;
begin
  FLatch.CountDown;
  FLatch.CountDown;
  CheckTrue(FLatch.TryWait, 'TryWait should return true after latch is open');
end;

procedure TTestCase_Wait.Test_Wait_Timeout;
begin
  CheckFalse(FLatch.Wait(100), 'Wait should return false on timeout');
end;

procedure TTestCase_Wait.Test_Wait_Success;
begin
  FLatch.CountDown;
  FLatch.CountDown;
  CheckTrue(FLatch.Wait(1000), 'Wait should return true when latch is open');
end;

{ TTestCase_Boundary }

procedure TTestCase_Boundary.Test_InitialCount_Zero;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('TestLatch_Zero_' + IntToStr(Random(100000)), 0);
  CheckTrue(LLatch.IsOpen, 'Latch with initial count 0 should be open');
  CheckTrue(LLatch.TryWait, 'TryWait should succeed immediately');
end;

procedure TTestCase_Boundary.Test_CountDownBy_ExceedsCount;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('TestLatch_Exceed_' + IntToStr(Random(100000)), 2);
  LLatch.CountDownBy(10);
  CheckEquals(0, LLatch.GetCount, 'Count should be 0, not negative');
  CheckTrue(LLatch.IsOpen, 'Latch should be open');
end;

procedure TTestCase_Boundary.Test_CountDown_AlreadyZero;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('TestLatch_AlreadyZero_' + IntToStr(Random(100000)), 1);
  LLatch.CountDown;
  CheckEquals(0, LLatch.GetCount, 'Count should be 0');

  // 再次 CountDown 不应该出错
  LLatch.CountDown;
  CheckEquals(0, LLatch.GetCount, 'Count should still be 0');
end;

initialization
  Randomize;
  RegisterTest(TTestCase_Factory);
  RegisterTest(TTestCase_Basic);
  RegisterTest(TTestCase_Wait);
  RegisterTest(TTestCase_Boundary);

end.

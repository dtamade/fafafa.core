{$CODEPAGE UTF8}
unit fafafa.core.sync.namedWaitGroup.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.namedWaitGroup, fafafa.core.sync.base;

type
  // 工厂函数测试
  TTestCase_Factory = class(TTestCase)
  published
    procedure Test_MakeNamedWaitGroup;
    procedure Test_MakeNamedWaitGroup_WithConfig;
    procedure Test_DefaultConfig;
    procedure Test_GlobalConfig;
  end;

  // 基础功能测试
  TTestCase_Basic = class(TTestCase)
  private
    FWG: INamedWaitGroup;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_InitialCount_Zero;
    procedure Test_Add;
    procedure Test_Add_Multiple;
    procedure Test_Done;
    procedure Test_Add_Done_Cycle;
    procedure Test_IsZero;
    procedure Test_GetName;
  end;

  // Wait 功能测试
  TTestCase_Wait = class(TTestCase)
  private
    FWG: INamedWaitGroup;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Wait_WhenZero;
    procedure Test_Wait_Timeout;
    procedure Test_Wait_AfterAddDone;
  end;

  // 错误处理测试
  TTestCase_ErrorHandling = class(TTestCase)
  private
    FWG: INamedWaitGroup;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Done_WhenZero_RaisesException;
  end;

implementation

{ TTestCase_Factory }

procedure TTestCase_Factory.Test_MakeNamedWaitGroup;
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('TestWG_Factory1');
  CheckNotNull(LWG, 'MakeNamedWaitGroup should return instance');
  CheckEquals('TestWG_Factory1', LWG.GetName, 'Name should match');
  CheckEquals(0, LWG.GetCount, 'Initial count should be 0');
end;

procedure TTestCase_Factory.Test_MakeNamedWaitGroup_WithConfig;
var
  LWG: INamedWaitGroup;
  LConfig: TNamedWaitGroupConfig;
begin
  LConfig := NamedWaitGroupConfigWithTimeout(5000);
  LWG := MakeNamedWaitGroup('TestWG_Factory2', LConfig);
  CheckNotNull(LWG, 'MakeNamedWaitGroup with config should return instance');
end;

procedure TTestCase_Factory.Test_DefaultConfig;
var
  LConfig: TNamedWaitGroupConfig;
begin
  LConfig := DefaultNamedWaitGroupConfig;
  CheckEquals(30000, LConfig.TimeoutMs, 'Default timeout should be 30000ms');
  CheckFalse(LConfig.UseGlobalNamespace, 'Default should not use global namespace');
end;

procedure TTestCase_Factory.Test_GlobalConfig;
var
  LConfig: TNamedWaitGroupConfig;
begin
  LConfig := GlobalNamedWaitGroupConfig;
  CheckTrue(LConfig.UseGlobalNamespace, 'Global config should use global namespace');
end;

{ TTestCase_Basic }

procedure TTestCase_Basic.SetUp;
begin
  FWG := MakeNamedWaitGroup('TestWG_Basic_' + IntToStr(Random(100000)));
end;

procedure TTestCase_Basic.TearDown;
begin
  FWG := nil;
end;

procedure TTestCase_Basic.Test_InitialCount_Zero;
begin
  CheckEquals(0, FWG.GetCount, 'Initial count should be 0');
end;

procedure TTestCase_Basic.Test_Add;
begin
  FWG.Add(1);
  CheckEquals(1, FWG.GetCount, 'Count should be 1 after Add(1)');
end;

procedure TTestCase_Basic.Test_Add_Multiple;
begin
  FWG.Add(3);
  CheckEquals(3, FWG.GetCount, 'Count should be 3 after Add(3)');

  FWG.Add(2);
  CheckEquals(5, FWG.GetCount, 'Count should be 5 after Add(2)');
end;

procedure TTestCase_Basic.Test_Done;
begin
  FWG.Add(2);
  FWG.Done;
  CheckEquals(1, FWG.GetCount, 'Count should be 1 after Done');

  FWG.Done;
  CheckEquals(0, FWG.GetCount, 'Count should be 0 after second Done');
end;

procedure TTestCase_Basic.Test_Add_Done_Cycle;
begin
  // 第一轮
  FWG.Add(2);
  FWG.Done;
  FWG.Done;
  CheckTrue(FWG.IsZero, 'Should be zero after first cycle');

  // 第二轮（WaitGroup 可重用）
  FWG.Add(1);
  CheckFalse(FWG.IsZero, 'Should not be zero after Add');
  FWG.Done;
  CheckTrue(FWG.IsZero, 'Should be zero after second cycle');
end;

procedure TTestCase_Basic.Test_IsZero;
begin
  CheckTrue(FWG.IsZero, 'Should be zero initially');

  FWG.Add(1);
  CheckFalse(FWG.IsZero, 'Should not be zero after Add');

  FWG.Done;
  CheckTrue(FWG.IsZero, 'Should be zero after Done');
end;

procedure TTestCase_Basic.Test_GetName;
begin
  CheckTrue(Pos('TestWG_Basic_', FWG.GetName) = 1, 'Name should start with expected prefix');
end;

{ TTestCase_Wait }

procedure TTestCase_Wait.SetUp;
begin
  FWG := MakeNamedWaitGroup('TestWG_Wait_' + IntToStr(Random(100000)));
end;

procedure TTestCase_Wait.TearDown;
begin
  FWG := nil;
end;

procedure TTestCase_Wait.Test_Wait_WhenZero;
begin
  // 当计数为 0 时，Wait 应该立即返回
  CheckTrue(FWG.Wait(100), 'Wait should return true immediately when count is 0');
end;

procedure TTestCase_Wait.Test_Wait_Timeout;
begin
  FWG.Add(1);
  // 不 Done，应该超时
  CheckFalse(FWG.Wait(100), 'Wait should return false on timeout');
end;

procedure TTestCase_Wait.Test_Wait_AfterAddDone;
begin
  FWG.Add(2);
  FWG.Done;
  FWG.Done;
  CheckTrue(FWG.Wait(1000), 'Wait should return true after all Done calls');
end;

{ TTestCase_ErrorHandling }

procedure TTestCase_ErrorHandling.SetUp;
begin
  FWG := MakeNamedWaitGroup('TestWG_Error_' + IntToStr(Random(100000)));
end;

procedure TTestCase_ErrorHandling.TearDown;
begin
  FWG := nil;
end;

procedure TTestCase_ErrorHandling.Test_Done_WhenZero_RaisesException;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    FWG.Done;  // 计数已经是 0，应该抛异常
  except
    on E: ELockError do
      LRaised := True;
  end;
  CheckTrue(LRaised, 'Done when count is 0 should raise ELockError');
end;

initialization
  Randomize;
  RegisterTest(TTestCase_Factory);
  RegisterTest(TTestCase_Basic);
  RegisterTest(TTestCase_Wait);
  RegisterTest(TTestCase_ErrorHandling);

end.

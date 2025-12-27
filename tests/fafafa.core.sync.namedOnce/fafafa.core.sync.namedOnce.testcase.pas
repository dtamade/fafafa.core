{$CODEPAGE UTF8}
unit fafafa.core.sync.namedOnce.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.namedOnce, fafafa.core.sync.base;

type
  // 工厂函数测试
  TTestCase_Factory = class(TTestCase)
  published
    procedure Test_MakeNamedOnce;
    procedure Test_MakeNamedOnce_WithConfig;
    procedure Test_DefaultConfig;
    procedure Test_GlobalConfig;
  end;

  // 基础功能测试
  TTestCase_Basic = class(TTestCase)
  private
    FOnce: INamedOnce;
    FExecuteCount: Integer;
    procedure IncrementCounter;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Execute_OnlyOnce;
    procedure Test_Execute_Multiple_Calls;
    procedure Test_IsDone_After_Execute;
    procedure Test_GetState;
    procedure Test_GetName;
  end;

  // ExecuteMethod 测试
  TTestCase_ExecuteMethod = class(TTestCase)
  private
    FOnce: INamedOnce;
    FCounter: Integer;
    procedure MethodCallback;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_ExecuteMethod_OnlyOnce;
  end;

  // Wait 功能测试
  TTestCase_Wait = class(TTestCase)
  private
    FOnce: INamedOnce;
    FExecuted: Boolean;
    procedure SlowCallback;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Wait_After_Execute;
    procedure Test_Wait_Timeout;
  end;

  // Poisoning 测试
  TTestCase_Poison = class(TTestCase)
  private
    FOnce: INamedOnce;
    procedure RaiseException;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_IsPoisoned_After_Exception;
  end;

  // Reset 测试
  TTestCase_Reset = class(TTestCase)
  private
    FOnce: INamedOnce;
    FCounter: Integer;
    procedure IncrementCounter;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Reset_AllowsReExecution;
  end;

implementation

var
  GTestCounter: Integer = 0;

procedure GlobalIncrement;
begin
  Inc(GTestCounter);
end;

{ TTestCase_Factory }

procedure TTestCase_Factory.Test_MakeNamedOnce;
var
  LOnce: INamedOnce;
begin
  LOnce := MakeNamedOnce('TestOnce_Factory1');
  CheckNotNull(LOnce, 'MakeNamedOnce should return instance');
  CheckEquals('TestOnce_Factory1', LOnce.GetName, 'Name should match');
end;

procedure TTestCase_Factory.Test_MakeNamedOnce_WithConfig;
var
  LOnce: INamedOnce;
  LConfig: TNamedOnceConfig;
begin
  LConfig := NamedOnceConfigWithTimeout(5000);
  LOnce := MakeNamedOnce('TestOnce_Factory2', LConfig);
  CheckNotNull(LOnce, 'MakeNamedOnce with config should return instance');
end;

procedure TTestCase_Factory.Test_DefaultConfig;
var
  LConfig: TNamedOnceConfig;
begin
  LConfig := DefaultNamedOnceConfig;
  CheckEquals(30000, LConfig.TimeoutMs, 'Default timeout should be 30000ms');
  CheckFalse(LConfig.UseGlobalNamespace, 'Default should not use global namespace');
  CheckTrue(LConfig.EnablePoisoning, 'Default should enable poisoning');
end;

procedure TTestCase_Factory.Test_GlobalConfig;
var
  LConfig: TNamedOnceConfig;
begin
  LConfig := GlobalNamedOnceConfig;
  CheckTrue(LConfig.UseGlobalNamespace, 'Global config should use global namespace');
end;

{ TTestCase_Basic }

procedure TTestCase_Basic.IncrementCounter;
begin
  Inc(FExecuteCount);
end;

procedure TTestCase_Basic.SetUp;
begin
  FOnce := MakeNamedOnce('TestOnce_Basic_' + IntToStr(Random(100000)));
  FExecuteCount := 0;
end;

procedure TTestCase_Basic.TearDown;
begin
  FOnce := nil;
end;

procedure TTestCase_Basic.Test_Execute_OnlyOnce;
begin
  GTestCounter := 0;
  FOnce.Execute(@GlobalIncrement);
  CheckEquals(1, GTestCounter, 'Execute should run callback once');
end;

procedure TTestCase_Basic.Test_Execute_Multiple_Calls;
begin
  GTestCounter := 0;
  FOnce.Execute(@GlobalIncrement);
  FOnce.Execute(@GlobalIncrement);
  FOnce.Execute(@GlobalIncrement);
  CheckEquals(1, GTestCounter, 'Multiple Execute calls should only run once');
end;

procedure TTestCase_Basic.Test_IsDone_After_Execute;
begin
  CheckFalse(FOnce.IsDone, 'IsDone should be false before Execute');
  FOnce.Execute(@GlobalIncrement);
  CheckTrue(FOnce.IsDone, 'IsDone should be true after Execute');
end;

procedure TTestCase_Basic.Test_GetState;
begin
  CheckEquals(Ord(nosNotStarted), Ord(FOnce.GetState), 'Initial state should be NotStarted');
  FOnce.Execute(@GlobalIncrement);
  CheckEquals(Ord(nosCompleted), Ord(FOnce.GetState), 'State after Execute should be Completed');
end;

procedure TTestCase_Basic.Test_GetName;
begin
  CheckTrue(Pos('TestOnce_Basic_', FOnce.GetName) = 1, 'Name should start with expected prefix');
end;

{ TTestCase_ExecuteMethod }

procedure TTestCase_ExecuteMethod.MethodCallback;
begin
  Inc(FCounter);
end;

procedure TTestCase_ExecuteMethod.SetUp;
begin
  FOnce := MakeNamedOnce('TestOnce_Method_' + IntToStr(Random(100000)));
  FCounter := 0;
end;

procedure TTestCase_ExecuteMethod.TearDown;
begin
  FOnce := nil;
end;

procedure TTestCase_ExecuteMethod.Test_ExecuteMethod_OnlyOnce;
begin
  FOnce.ExecuteMethod(@MethodCallback);
  FOnce.ExecuteMethod(@MethodCallback);
  CheckEquals(1, FCounter, 'ExecuteMethod should only run once');
end;

{ TTestCase_Wait }

procedure TTestCase_Wait.SlowCallback;
begin
  Sleep(50);
  FExecuted := True;
end;

procedure TTestCase_Wait.SetUp;
begin
  FOnce := MakeNamedOnce('TestOnce_Wait_' + IntToStr(Random(100000)));
  FExecuted := False;
end;

procedure TTestCase_Wait.TearDown;
begin
  FOnce := nil;
end;

procedure TTestCase_Wait.Test_Wait_After_Execute;
begin
  FOnce.Execute(@SlowCallback);
  CheckTrue(FOnce.Wait(1000), 'Wait should return true after execution');
  CheckTrue(FExecuted, 'Callback should have been executed');
end;

procedure TTestCase_Wait.Test_Wait_Timeout;
var
  LOnce: INamedOnce;
begin
  // 创建一个新的不执行的 Once
  LOnce := MakeNamedOnce('TestOnce_WaitTimeout_' + IntToStr(Random(100000)));
  // 不执行，直接等待 - 应该超时
  CheckFalse(LOnce.Wait(100), 'Wait should return false on timeout');
end;

{ TTestCase_Poison }

procedure TTestCase_Poison.RaiseException;
begin
  raise Exception.Create('Test exception');
end;

procedure TTestCase_Poison.SetUp;
begin
  FOnce := MakeNamedOnce('TestOnce_Poison_' + IntToStr(Random(100000)));
end;

procedure TTestCase_Poison.TearDown;
begin
  FOnce := nil;
end;

procedure TTestCase_Poison.Test_IsPoisoned_After_Exception;
begin
  CheckFalse(FOnce.IsPoisoned, 'Should not be poisoned initially');
  try
    FOnce.Execute(@RaiseException);
  except
    // 忽略异常
  end;
  CheckTrue(FOnce.IsPoisoned, 'Should be poisoned after exception');
  CheckEquals(Ord(nosPoisoned), Ord(FOnce.GetState), 'State should be Poisoned');
end;

{ TTestCase_Reset }

procedure TTestCase_Reset.IncrementCounter;
begin
  Inc(FCounter);
end;

procedure TTestCase_Reset.SetUp;
begin
  FOnce := MakeNamedOnce('TestOnce_Reset_' + IntToStr(Random(100000)));
  FCounter := 0;
end;

procedure TTestCase_Reset.TearDown;
begin
  FOnce := nil;
end;

procedure TTestCase_Reset.Test_Reset_AllowsReExecution;
begin
  FOnce.Execute(@IncrementCounter);
  CheckEquals(1, FCounter, 'First execute should increment');

  FOnce.Reset;
  CheckFalse(FOnce.IsDone, 'IsDone should be false after Reset');

  FOnce.Execute(@IncrementCounter);
  CheckEquals(2, FCounter, 'After Reset, execute should increment again');
end;

initialization
  Randomize;
  RegisterTest(TTestCase_Factory);
  RegisterTest(TTestCase_Basic);
  RegisterTest(TTestCase_ExecuteMethod);
  RegisterTest(TTestCase_Wait);
  RegisterTest(TTestCase_Poison);
  RegisterTest(TTestCase_Reset);

end.

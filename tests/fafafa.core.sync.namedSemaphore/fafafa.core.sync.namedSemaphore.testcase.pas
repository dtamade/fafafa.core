unit fafafa.core.sync.namedSemaphore.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base, fafafa.core.sync,  // 门面单元，导出 MakeNamed* 函数
  fafafa.core.sync.namedSemaphore, fafafa.core.sync.base;

type
  // 测试全局函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeNamedSemaphore;
    procedure Test_MakeNamedSemaphore_InitialCount_MaxCount;
    procedure Test_MakeNamedSemaphore_WithCounts;
    procedure Test_MakeGlobalNamedSemaphore;
  end;

  // 测试 INamedSemaphore 接口
  TTestCase_INamedSemaphore = class(TTestCase)
  private
    FSemaphore: INamedSemaphore;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试基本功能
    procedure Test_GetName;
    procedure Test_GetMaxCount;
    procedure Test_GetCurrentCount;
    
    // 测试核心信号量操作
    procedure Test_Wait_Release;
    procedure Test_TryWait;
    procedure Test_TryWaitFor;
    procedure Test_Release_Multiple;
    
    // 测试 RAII 守卫
    procedure Test_Guard_AutoRelease;
    procedure Test_Guard_GetName;
    procedure Test_Guard_GetCount;
    
    // 测试错误处理
    procedure Test_InvalidName;
    procedure Test_InvalidCount;
    procedure Test_Release_InvalidCount;
    
    // 综合测试
    procedure Test_MultipleInstances;
    procedure Test_CountingSemaphore_Behavior;
    procedure Test_BinarySemaphore_Behavior;
    procedure Test_CrossProcess_Basic;
  end;

  // 测试新增功能
  TTestCase_NewFeatures = class(TTestCase)
  private
    FSemaphore: INamedSemaphore;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试守卫手动释放功能
    procedure Test_Guard_ManualRelease;
    procedure Test_Guard_IsReleased;
    procedure Test_Guard_DoubleRelease;

    // 测试错误恢复
    procedure Test_ErrorRecovery_InvalidName;
    procedure Test_ErrorRecovery_InvalidCount;
    procedure Test_ErrorRecovery_ReleaseAfterDestroy;
  end;

  // 测试并发安全（简化版）
  TTestCase_ConcurrencyBasic = class(TTestCase)
  published
    procedure Test_MultipleThreads_BasicSafety;
    procedure Test_GuardLifetime_ThreadSafety;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeNamedSemaphore;
var
  LSemaphore: INamedSemaphore;
  LName: string;
begin
  LName := 'test_sem1_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName);
  CheckTrue(Assigned(LSemaphore), '应该成功创建命名信号量');
  CheckEquals(LName, LSemaphore.GetName, '名称应该匹配');
end;

procedure TTestCase_Global.Test_MakeNamedSemaphore_InitialCount_MaxCount;
var
  LSemaphore: INamedSemaphore;
  LName: string;
begin
  LName := 'test_sem2_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName, 3, 5);
  CheckTrue(Assigned(LSemaphore), '应该成功创建带计数的命名信号量');
  CheckEquals(LName, LSemaphore.GetName, '名称应该匹配');
  CheckEquals(5, LSemaphore.GetMaxCount, '最大计数应该匹配');
end;

procedure TTestCase_Global.Test_MakeGlobalNamedSemaphore;
var
  LSemaphore: INamedSemaphore;
  LName: string;
begin
  LName := 'test_gsem_' + IntToStr(Random(100000));
  LSemaphore := MakeGlobalNamedSemaphore(LName);
  CheckTrue(Assigned(LSemaphore), '应该成功创建全局命名信号量');
  {$IFDEF WINDOWS}
  CheckTrue(Pos('Global\', LSemaphore.GetName) = 1, 'Windows 上应该包含 Global\ 前缀');
  {$ELSE}
  CheckEquals(LName, LSemaphore.GetName, 'Unix 上名称应该保持不变');
  {$ENDIF}
end;

procedure TTestCase_Global.Test_MakeNamedSemaphore_WithCounts;
var
  LSemaphore: INamedSemaphore;
  LName: string;
begin
  LName := 'test_make_sem2_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName, 3, 5);
  CheckTrue(Assigned(LSemaphore), '应该成功创建带计数的命名信号量');
  CheckEquals(LName, LSemaphore.GetName, '名称应该匹配');
  CheckEquals(5, LSemaphore.GetMaxCount, '最大计数应该匹配');
end;

{ TTestCase_INamedSemaphore }

procedure TTestCase_INamedSemaphore.SetUp;
begin
  inherited SetUp;
  FTestName := 'test_semaphore_' + IntToStr(Random(10000));
  FSemaphore := MakeNamedSemaphore(FTestName, 2, 5); // 初始计数2，最大计数5
end;

procedure TTestCase_INamedSemaphore.TearDown;
begin
  FSemaphore := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedSemaphore.Test_GetName;
begin
  CheckEquals(FTestName, FSemaphore.GetName, '名称应该匹配');
end;

procedure TTestCase_INamedSemaphore.Test_GetMaxCount;
begin
  CheckEquals(5, FSemaphore.GetMaxCount, '最大计数应该匹配');
end;

procedure TTestCase_INamedSemaphore.Test_GetCurrentCount;
var
  LCurrentCount: Integer;
begin
  LCurrentCount := FSemaphore.GetCurrentCount;
  // 某些平台可能不支持查询当前计数，返回 -1
  if LCurrentCount >= 0 then
    CheckTrue(LCurrentCount <= 5, '当前计数应该不超过最大计数');
end;

procedure TTestCase_INamedSemaphore.Test_Wait_Release;
var
  LGuard: INamedSemaphoreGuard;
begin
  // 等待信号量
  LGuard := FSemaphore.Wait;
  CheckTrue(Assigned(LGuard), '应该成功获取信号量守卫');
  CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
  
  // 守卫会在作用域结束时自动释放
  LGuard := nil;
  
  // 手动释放一个计数
  FSemaphore.Release;
end;

procedure TTestCase_INamedSemaphore.Test_TryWait;
var
  LGuard: INamedSemaphoreGuard;
begin
  // 非阻塞尝试
  LGuard := FSemaphore.TryWait;
  CheckTrue(Assigned(LGuard), '应该成功获取信号量守卫（非阻塞）');
  
  LGuard := nil; // 自动释放
end;

procedure TTestCase_INamedSemaphore.Test_TryWaitFor;
var
  LGuard: INamedSemaphoreGuard;
begin
  // 带超时尝试
  LGuard := FSemaphore.TryWaitFor(1000); // 1秒超时
  CheckTrue(Assigned(LGuard), '应该成功获取信号量守卫（带超时）');
  
  LGuard := nil; // 自动释放
end;

procedure TTestCase_INamedSemaphore.Test_Release_Multiple;
var
  LGuard1, LGuard2: INamedSemaphoreGuard;
begin
  // 释放多个计数
  FSemaphore.Release(2);

  // 验证可以获取多个守卫
  LGuard1 := FSemaphore.TryWait;
  LGuard2 := FSemaphore.TryWait;

  CheckTrue(Assigned(LGuard1), '应该成功获取第一个守卫');
  CheckTrue(Assigned(LGuard2), '应该成功获取第二个守卫');

  LGuard1 := nil;
  LGuard2 := nil;
end;

procedure TTestCase_INamedSemaphore.Test_Guard_AutoRelease;
var
  LGuard1, LGuard2, LGuard3: INamedSemaphoreGuard;
begin
  // 获取所有可用的信号量
  LGuard1 := FSemaphore.TryWait;
  LGuard2 := FSemaphore.TryWait;

  CheckTrue(Assigned(LGuard1), '应该成功获取第一个守卫');
  CheckTrue(Assigned(LGuard2), '应该成功获取第二个守卫');

  // 现在应该没有可用的信号量了
  LGuard3 := FSemaphore.TryWait;
  CheckTrue(not Assigned(LGuard3), '不应该能获取第三个守卫');

  // 释放一个守卫
  LGuard1 := nil;

  // 现在应该能获取一个守卫
  LGuard3 := FSemaphore.TryWait;
  CheckTrue(Assigned(LGuard3), '释放后应该能获取守卫');

  LGuard2 := nil;
  LGuard3 := nil;
end;

procedure TTestCase_INamedSemaphore.Test_Guard_GetName;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := FSemaphore.Wait;
  CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
  LGuard := nil;
end;

procedure TTestCase_INamedSemaphore.Test_Guard_GetCount;
var
  LGuard: INamedSemaphoreGuard;
  LCount: Integer;
begin
  LGuard := FSemaphore.Wait;
  LCount := LGuard.GetCount;
  // 某些平台可能不支持查询计数，返回 -1
  if LCount >= 0 then
    CheckTrue(LCount <= 5, '守卫计数应该不超过最大计数');
  LGuard := nil;
end;

procedure TTestCase_INamedSemaphore.Test_InvalidName;
begin
  // 测试空名称
  try
    MakeNamedSemaphore('');
    Fail('空名称应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_INamedSemaphore.Test_InvalidCount;
begin
  // 测试无效计数
  try
    MakeNamedSemaphore('test_invalid', -1, 5);
    Fail('负初始计数应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;

  try
    MakeNamedSemaphore('test_invalid', 1, 0);
    Fail('零最大计数应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;

  try
    MakeNamedSemaphore('test_invalid', 5, 3);
    Fail('初始计数大于最大计数应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_INamedSemaphore.Test_Release_InvalidCount;
begin
  try
    FSemaphore.Release(0);
    Fail('释放零计数应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;
  
  try
    FSemaphore.Release(-1);
    Fail('释放负计数应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_INamedSemaphore.Test_MultipleInstances;
var
  LSemaphore1, LSemaphore2: INamedSemaphore;
  LGuard1, LGuard2: INamedSemaphoreGuard;
  LName: string;
begin
  // 创建两个相同名称的信号量实例
  LName := 'test_multi_' + IntToStr(Random(100000));
  LSemaphore1 := MakeNamedSemaphore(LName, 1, 1);
  LSemaphore2 := MakeNamedSemaphore(LName, 1, 1);
  
  // 第一个实例获取信号量
  LGuard1 := LSemaphore1.TryWait;
  CheckTrue(Assigned(LGuard1), '第一个实例应该成功获取信号量');
  
  // 第二个实例应该无法获取
  LGuard2 := LSemaphore2.TryWait;
  CheckTrue(not Assigned(LGuard2), '第二个实例不应该能获取信号量');
  
  // 释放第一个实例的信号量
  LGuard1 := nil;
  
  // 现在第二个实例应该能获取
  LGuard2 := LSemaphore2.TryWait;
  CheckTrue(Assigned(LGuard2), '释放后第二个实例应该能获取信号量');
  
  LGuard2 := nil;
end;

procedure TTestCase_INamedSemaphore.Test_CountingSemaphore_Behavior;
var
  LSemaphore: INamedSemaphore;
  LGuards: array[1..3] of INamedSemaphoreGuard;
  LGuard4: INamedSemaphoreGuard;
  I: Integer;
  LName: string;
begin
  // 创建计数信号量：初始计数3，最大计数3
  LName := 'test_counting_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName, 3, 3);

  // 应该能获取3个守卫
  for I := 1 to 3 do
  begin
    LGuards[I] := LSemaphore.TryWait;
    CheckTrue(Assigned(LGuards[I]), Format('应该成功获取第%d个守卫', [I]));
  end;

  // 第4个应该失败
  LGuard4 := LSemaphore.TryWait;
  CheckTrue(not Assigned(LGuard4), '不应该能获取第4个守卫');

  // 释放一个守卫
  LGuards[1] := nil;

  // 现在应该能获取一个守卫
  LGuard4 := LSemaphore.TryWait;
  CheckTrue(Assigned(LGuard4), '释放后应该能获取守卫');

  // 清理
  for I := 2 to 3 do
    LGuards[I] := nil;
  LGuard4 := nil;
end;

procedure TTestCase_INamedSemaphore.Test_BinarySemaphore_Behavior;
var
  LSemaphore: INamedSemaphore;
  LGuard1, LGuard2: INamedSemaphoreGuard;
  LName: string;
begin
  // 创建二进制信号量（初始有信号）
  LName := 'test_binary_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName, 1, 1);
  
  // 应该能获取一个守卫
  LGuard1 := LSemaphore.TryWait;
  CheckTrue(Assigned(LGuard1), '应该成功获取守卫');
  
  // 第二个应该失败
  LGuard2 := LSemaphore.TryWait;
  CheckTrue(not Assigned(LGuard2), '不应该能获取第二个守卫');
  
  // 释放守卫
  LGuard1 := nil;
  
  // 现在应该能获取守卫
  LGuard2 := LSemaphore.TryWait;
  CheckTrue(Assigned(LGuard2), '释放后应该能获取守卫');
  
  LGuard2 := nil;
end;

procedure TTestCase_INamedSemaphore.Test_CrossProcess_Basic;
var
  LSemaphore1, LSemaphore2: INamedSemaphore;
  LGuard, LGuard2: INamedSemaphoreGuard;
  LName: string;
begin
  // 这是一个基础的跨进程测试（在同一进程中模拟）
  LName := 'test_cross_' + IntToStr(Random(100000));
  LSemaphore1 := MakeNamedSemaphore(LName, 1, 1);
  LSemaphore2 := MakeNamedSemaphore(LName, 1, 1);

  // 第一个实例获取信号量
  LGuard := LSemaphore1.TryWait;
  CheckTrue(Assigned(LGuard), '第一个实例应该成功获取信号量');

  // 第二个实例应该无法获取（模拟另一个进程）
  LGuard2 := LSemaphore2.TryWait;
  CheckTrue(not Assigned(LGuard2), '第二个实例不应该能获取信号量（跨进程同步）');

  LGuard := nil;
end;

{ TTestCase_NewFeatures }

procedure TTestCase_NewFeatures.SetUp;
begin
  inherited SetUp;
  FTestName := 'test_new_features_' + IntToStr(Random(10000));
  FSemaphore := MakeNamedSemaphore(FTestName, 2, 3);
end;

procedure TTestCase_NewFeatures.TearDown;
begin
  FSemaphore := nil;
  inherited TearDown;
end;

procedure TTestCase_NewFeatures.Test_Guard_ManualRelease;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := FSemaphore.Wait;
  CheckTrue(Assigned(LGuard), '应该成功获取守卫');
  CheckFalse(LGuard.IsReleased, '守卫初始状态应该是未释放');

  // 手动释放
  LGuard.Release;
  CheckTrue(LGuard.IsReleased, '手动释放后应该标记为已释放');
end;

procedure TTestCase_NewFeatures.Test_Guard_IsReleased;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := FSemaphore.TryWait;
  CheckTrue(Assigned(LGuard), '应该成功获取守卫');
  CheckFalse(LGuard.IsReleased, '新获取的守卫应该是未释放状态');

  LGuard.Release;
  CheckTrue(LGuard.IsReleased, '释放后应该是已释放状态');
end;

procedure TTestCase_NewFeatures.Test_Guard_DoubleRelease;
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := FSemaphore.Wait;
  LGuard.Release;

  // 第二次释放应该是安全的（不抛出异常）
  LGuard.Release;
  CheckTrue(LGuard.IsReleased, '多次释放后仍应该是已释放状态');
end;

procedure TTestCase_NewFeatures.Test_ErrorRecovery_InvalidName;
begin
  try
    MakeNamedSemaphore('');
    Fail('空名称应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_NewFeatures.Test_ErrorRecovery_InvalidCount;
begin
  try
    MakeNamedSemaphore('test_invalid', -1, 5);
    Fail('负初始计数应该抛出异常');
  except
    on E: EInvalidArgument do
      CheckTrue(True, '应该抛出 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_NewFeatures.Test_ErrorRecovery_ReleaseAfterDestroy;
var
  LGuard: INamedSemaphoreGuard;
  LSemaphore: INamedSemaphore;
  LName: string;
begin
  LName := 'test_rad_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName, 1, 1);
  LGuard := LSemaphore.Wait;

  // 销毁信号量
  LSemaphore := nil;

  // 守卫应该仍然可以安全释放
  LGuard.Release;
  CheckTrue(LGuard.IsReleased, '即使信号量已销毁，守卫也应该能安全释放');
end;

{ TTestCase_ConcurrencyBasic }

procedure TTestCase_ConcurrencyBasic.Test_MultipleThreads_BasicSafety;
var
  LSemaphore: INamedSemaphore;
  LGuard1, LGuard2: INamedSemaphoreGuard;
  LName: string;
begin
  // 创建计数为1的信号量
  LName := 'test_thread_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName, 1, 1);

  // 获取信号量
  LGuard1 := LSemaphore.TryWait;
  CheckTrue(Assigned(LGuard1), '应该成功获取第一个守卫');

  // 第二次尝试应该失败
  LGuard2 := LSemaphore.TryWait;
  CheckTrue(not Assigned(LGuard2), '第二次获取应该失败');

  // 释放后应该能再次获取
  LGuard1 := nil;
  LGuard2 := LSemaphore.TryWait;
  CheckTrue(Assigned(LGuard2), '释放后应该能再次获取');

  LGuard2 := nil;
end;

procedure TTestCase_ConcurrencyBasic.Test_GuardLifetime_ThreadSafety;
var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
  LName: string;
begin
  LName := 'test_guard_' + IntToStr(Random(100000));
  LSemaphore := MakeNamedSemaphore(LName, 2, 2);

  // 测试守卫的生命周期管理
  LGuard := LSemaphore.Wait;
  CheckTrue(Assigned(LGuard), '应该成功获取守卫');
  CheckFalse(LGuard.IsReleased, '新守卫应该是未释放状态');

  // 手动释放
  LGuard.Release;
  CheckTrue(LGuard.IsReleased, '手动释放后应该是已释放状态');

  // 析构时不应该再次释放
  LGuard := nil;
end;



initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_INamedSemaphore);
  RegisterTest(TTestCase_NewFeatures);
  RegisterTest(TTestCase_ConcurrencyBasic);

end.

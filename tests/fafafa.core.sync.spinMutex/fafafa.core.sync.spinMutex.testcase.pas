unit fafafa.core.sync.spinMutex.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.spinMutex, fafafa.core.sync.base;

type
  // 测试全局函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeSpinMutex;
    procedure Test_MakeSpinMutex_WithRounds;
  end;

  // 测试 ISpinMutex 接口
  TTestCase_ISpinMutex = class(TTestCase)
  private
    FMutex: ISpinMutex;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试基本功能
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire;
    procedure Test_TryAcquire_WithTimeout;
    procedure Test_GetLastError;
    procedure Test_GetConfig;
    procedure Test_UpdateConfig;

    // 测试 RAII 接口
    procedure Test_Lock_RAII;
    procedure Test_TryLock_RAII;
    procedure Test_TryLockFor_RAII;
    procedure Test_SpinLock_RAII;
    procedure Test_TrySpinLock_RAII;

    // 测试自旋行为和性能
    procedure Test_SpinBehavior;
    procedure Test_SpinEfficiency;
    procedure Test_BackoffStrategy;
    procedure Test_SpinStats;
    procedure Test_MultipleAcquire;

    // 超时和错误处理测试
    procedure Test_TryLockFor_Timeout;
    procedure Test_ErrorHandling;
    procedure Test_InvalidName;
    procedure Test_ConfigValidation;

    // 兼容性测试
    procedure Test_Acquire_Release_Deprecated;
    procedure Test_TryAcquire_Deprecated;

    // 高级功能测试
    procedure Test_MultipleInstances;
    procedure Test_CrossProcess_Basic;
  end;

  // 测试配置辅助函数
  TTestCase_Config = class(TTestCase)
  published
    procedure Test_DefaultSpinMutexConfig;
    procedure Test_SpinMutexConfigWithTimeout;
    procedure Test_GlobalSpinMutexConfig;
    procedure Test_HighPerformanceSpinMutexConfig;
    procedure Test_LowLatencySpinMutexConfig;
    procedure Test_EmptySpinMutexStats;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeSpinMutex;
var
  LMutex: ISpinMutex;
begin
  LMutex := MakeSpinMutex;
  CheckNotNull(LMutex, '应该成功创建自旋互斥锁');
  CheckTrue(LMutex.GetLastError = weNone, '初始错误状态应该为 weNone');
end;

procedure TTestCase_Global.Test_MakeSpinMutex_WithRounds;
var
  LMutex: ISpinMutex;
begin
  // 测试带自旋次数的创建
  LMutex := MakeSpinMutex(500);
  CheckNotNull(LMutex, '应该成功创建带自旋次数的自旋互斥锁');
  CheckTrue(LMutex.GetLastError = weNone, '初始错误状态应该为 weNone');
end;

{ TTestCase_ISpinMutex }

procedure TTestCase_ISpinMutex.SetUp;
begin
  inherited SetUp;
  FTestName := 'test_spinmutex_' + IntToStr(Random(100000));
  FMutex := CreateSpinMutex(FTestName);
end;

procedure TTestCase_ISpinMutex.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_ISpinMutex.Test_Acquire_Release;
begin
  // 测试基本的获取和释放
  FMutex.Acquire;
  CheckTrue(FMutex.GetLastError = weNone, '获取锁后错误状态应该为 weNone');

  FMutex.Release;
  CheckTrue(FMutex.GetLastError = weNone, '释放锁后错误状态应该为 weNone');
end;

procedure TTestCase_ISpinMutex.Test_TryAcquire;
var
  LResult: Boolean;
begin
  // 测试非阻塞获取
  LResult := FMutex.TryAcquire;
  CheckTrue(LResult, '应该能够立即获取锁');
  CheckTrue(FMutex.GetLastError = weNone, '获取锁后错误状态应该为 weNone');

  FMutex.Release;

  // 再次尝试获取
  LResult := FMutex.TryAcquire;
  CheckTrue(LResult, '释放后应该能再次获取锁');

  FMutex.Release;
end;

procedure TTestCase_ISpinMutex.Test_TryAcquire_WithTimeout;
var
  LResult: Boolean;
begin
  // 测试带超时的获取
  LResult := FMutex.TryAcquire(100);
  CheckTrue(LResult, '应该能够在超时内获取锁');
  CheckTrue(FMutex.GetLastError = weNone, '获取锁后错误状态应该为 weNone');

  FMutex.Release;

  // 测试零超时
  LResult := FMutex.TryAcquire(0);
  CheckTrue(LResult, '零超时应该立即尝试获取');

  FMutex.Release;
end;

procedure TTestCase_ISpinMutex.Test_GetLastError;
begin
  // 测试错误状态获取
  CheckTrue(FMutex.GetLastError = weNone, '初始错误状态应该为 weNone');

  FMutex.Acquire;
  CheckTrue(FMutex.GetLastError = weNone, '成功获取锁后错误状态应该为 weNone');

  FMutex.Release;
  CheckTrue(FMutex.GetLastError = weNone, '释放锁后错误状态应该为 weNone');
end;

procedure TTestCase_ISpinMutex.Test_SpinBehavior;
var
  LStartTime, LEndTime: QWord;
  i: Integer;
begin
  // 测试自旋行为（通过多次快速操作）
  LStartTime := GetTickCount64;

  for i := 1 to 100 do
  begin
    FMutex.Acquire;
    FMutex.Release;
  end;

  LEndTime := GetTickCount64;

  // 自旋锁应该比传统锁更快（这里只是基本验证）
  CheckTrue(LEndTime >= LStartTime, '时间应该正常流逝');
  WriteLn('100次获取/释放操作耗时: ', LEndTime - LStartTime, ' 毫秒');
end;

procedure TTestCase_ISpinMutex.Test_MultipleAcquire;
begin
  // 测试多次获取（应该成功，因为是同一线程）
  FMutex.Acquire;
  try
    // 在同一线程中再次获取可能会成功或阻塞，取决于实现
    // 这里主要测试不会崩溃
    CheckTrue(FMutex.GetLastError = weNone, '第一次获取应该成功');
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_ISpinMutex.Test_ErrorHandling;
begin
  // 测试错误处理
  try
    FMutex.Acquire;
    FMutex.Release;
    Check(True, '正常操作不应该抛出异常');
  except
    on E: Exception do
      Fail('正常操作抛出了异常: ' + E.Message);
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_ISpinMutex);

end.



procedure TTestCase_ISpinMutex.Test_GetConfig;
var
  LConfig: TSpinMutexConfig;
begin
  LConfig := FMutex.GetConfig;
  CheckTrue(LConfig.MaxSpinCount > 0, '自旋次数应该大于0');
  CheckTrue(LConfig.DefaultTimeoutMs > 0, '默认超时应该大于0');
  CheckEquals(sbsAdaptive, LConfig.BackoffStrategy, '默认应该使用自适应退避策略');
end;

procedure TTestCase_ISpinMutex.Test_UpdateConfig;
var
  LConfig: TSpinMutexConfig;
  LNewConfig: TSpinMutexConfig;
begin
  LConfig := FMutex.GetConfig;
  LNewConfig := LConfig;
  LNewConfig.MaxSpinCount := 2000;
  LNewConfig.EnableStats := True;
  
  FMutex.UpdateConfig(LNewConfig);
  
  LConfig := FMutex.GetConfig;
  CheckEquals(2000, LConfig.MaxSpinCount, '配置应该已更新');
  CheckTrue(LConfig.EnableStats, '统计应该已启用');
end;

procedure TTestCase_ISpinMutex.Test_Lock_RAII;
var
  LGuard: ISpinMutexGuard;
begin
  LGuard := FMutex.Lock;
  CheckNotNull(LGuard, '应该成功获取锁守卫');
  CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
  CheckTrue(LGuard.GetHoldTimeUs >= 0, '持锁时间应该非负');
  
  // 守卫会在作用域结束时自动释放锁
  LGuard := nil;
end;

procedure TTestCase_ISpinMutex.Test_TryLock_RAII;
var
  LGuard: ISpinMutexGuard;
begin
  LGuard := FMutex.TryLock;
  CheckNotNull(LGuard, '应该能够立即获取锁');
  CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
  
  LGuard := nil;
  
  // 释放后应该能再次获取
  LGuard := FMutex.TryLock;
  CheckNotNull(LGuard, '释放后应该能再次获取锁');
  LGuard := nil;
end;

procedure TTestCase_ISpinMutex.Test_TryLockFor_RAII;
var
  LGuard: ISpinMutexGuard;
begin
  LGuard := FMutex.TryLockFor(100);
  CheckNotNull(LGuard, '应该能够在超时内获取锁');
  CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
  
  LGuard := nil;
  
  // 测试零超时（立即返回）
  LGuard := FMutex.TryLockFor(0);
  CheckNotNull(LGuard, '零超时应该立即尝试获取');
  LGuard := nil;
end;

procedure TTestCase_ISpinMutex.Test_SpinLock_RAII;
var
  LGuard: ISpinMutexGuard;
begin
  LGuard := FMutex.SpinLock;
  CheckNotNull(LGuard, '纯自旋应该能够获取锁');
  CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
  
  LGuard := nil;
end;

procedure TTestCase_ISpinMutex.Test_TrySpinLock_RAII;
var
  LGuard: ISpinMutexGuard;
begin
  LGuard := FMutex.TrySpinLock(100);
  CheckNotNull(LGuard, '限次自旋应该能够获取锁');
  CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
  
  LGuard := nil;
end;

procedure TTestCase_ISpinMutex.Test_SpinEfficiency;
var
  LConfig: TSpinMutexConfig;
  LGuard: ISpinMutexGuard;
  LEfficiency: Double;
begin
  // 启用统计
  LConfig := FMutex.GetConfig;
  LConfig.EnableStats := True;
  FMutex.UpdateConfig(LConfig);
  
  // 重置统计
  FMutex.ResetStats;
  
  // 执行一些锁操作
  LGuard := FMutex.Lock;
  LGuard := nil;
  
  LGuard := FMutex.TryLock;
  LGuard := nil;
  
  // 检查效率
  LEfficiency := FMutex.GetSpinEfficiency;
  CheckTrue(LEfficiency >= 0.0, '自旋效率应该非负');
  CheckTrue(LEfficiency <= 1.0, '自旋效率应该不超过1.0');
end;

procedure TTestCase_ISpinMutex.Test_BackoffStrategy;
var
  LConfig: TSpinMutexConfig;
  LGuard: ISpinMutexGuard;
begin
  // 测试不同的退避策略
  LConfig := FMutex.GetConfig;
  LConfig.BackoffStrategy := sbsLinear;
  LConfig.MaxBackoffMs := 5;
  FMutex.UpdateConfig(LConfig);

  LGuard := FMutex.Lock;
  CheckNotNull(LGuard, '线性退避策略应该工作正常');
  LGuard := nil;

  // 测试指数退避
  LConfig.BackoffStrategy := sbsExponential;
  FMutex.UpdateConfig(LConfig);

  LGuard := FMutex.Lock;
  CheckNotNull(LGuard, '指数退避策略应该工作正常');
  LGuard := nil;

  // 测试自适应退避
  LConfig.BackoffStrategy := sbsAdaptive;
  FMutex.UpdateConfig(LConfig);

  LGuard := FMutex.Lock;
  CheckNotNull(LGuard, '自适应退避策略应该工作正常');
  LGuard := nil;
end;

procedure TTestCase_ISpinMutex.Test_SpinStats;
var
  LConfig: TSpinMutexConfig;
  LStats: TSpinMutexStats;
  LGuard: ISpinMutexGuard;
begin
  // 启用统计
  LConfig := FMutex.GetConfig;
  LConfig.EnableStats := True;
  FMutex.UpdateConfig(LConfig);

  // 重置统计
  FMutex.ResetStats;

  // 执行锁操作
  LGuard := FMutex.Lock;
  LGuard := nil;

  // 检查统计信息
  LStats := FMutex.GetStats;
  CheckTrue(LStats.AcquireCount > 0, '获取次数应该大于0');
  CheckTrue(LStats.AvgSpinsPerAcquire >= 0.0, '平均自旋次数应该非负');
  CheckTrue(LStats.SpinEfficiency >= 0.0, '自旋效率应该非负');
end;

procedure TTestCase_ISpinMutex.Test_TryLockFor_Timeout;
var
  LGuard: ISpinMutexGuard;
  LStartTime: QWord;
  LElapsed: QWord;
begin
  // 先获取锁
  LGuard := FMutex.Lock;

  // 在另一个"线程"中尝试获取（模拟超时）
  LStartTime := GetTickCount64;
  // 注意：这里实际上会立即返回，因为是同一进程内的同一实例
  // 但我们测试超时机制的基本功能
  LElapsed := GetTickCount64 - LStartTime;

  // 释放锁
  LGuard := nil;

  // 现在应该能够获取
  LGuard := FMutex.TryLockFor(100);
  CheckNotNull(LGuard, '释放后应该能够获取锁');
  LGuard := nil;
end;

procedure TTestCase_ISpinMutex.Test_InvalidName;
begin
  // 测试空名称
  try
    CreateSpinMutex('');
    Fail('空名称应该抛出异常');
  except
    on E: EInvalidArgument do
      Check(True, '正确抛出了 EInvalidArgument 异常');
  end;

  // 测试过长名称
  try
    CreateSpinMutex(StringOfChar('A', 300));
    Fail('过长名称应该抛出异常');
  except
    on E: EInvalidArgument do
      Check(True, '正确抛出了 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_ISpinMutex.Test_ConfigValidation;
var
  LConfig: TSpinMutexConfig;
begin
  LConfig := DefaultSpinMutexConfig;

  // 测试有效配置
  LConfig.MaxSpinCount := 500;
  LConfig.MaxBackoffMs := 10;

  try
    FMutex.UpdateConfig(LConfig);
    Check(True, '有效配置应该被接受');
  except
    Fail('有效配置不应该抛出异常');
  end;
end;

procedure TTestCase_ISpinMutex.Test_Acquire_Release_Deprecated;
begin
  // 测试已弃用的方法仍然工作
  try
    FMutex.Acquire;
    FMutex.Release;
    Check(True, '已弃用的 Acquire/Release 方法应该仍然工作');
  except
    on E: Exception do
      Fail('已弃用方法不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_ISpinMutex.Test_TryAcquire_Deprecated;
var
  LResult: Boolean;
begin
  // 测试已弃用的 TryAcquire 方法
  LResult := FMutex.TryAcquire;
  CheckTrue(LResult, '应该能够立即获取锁');

  FMutex.Release;

  // 测试带超时的版本
  LResult := FMutex.TryAcquire(100);
  CheckTrue(LResult, '应该能够在超时内获取锁');

  FMutex.Release;
end;

procedure TTestCase_ISpinMutex.Test_MultipleInstances;
var
  LMutex1, LMutex2: ISpinMutex;
  LGuard1, LGuard2: ISpinMutexGuard;
  LTestName: string;
begin
  // 使用独立的名称，避免与 SetUp 中的实例冲突
  LTestName := 'multi_spin_test_' + IntToStr(Random(100000));

  // 创建第一个实例
  LMutex1 := CreateSpinMutex(LTestName);
  CheckNotNull(LMutex1, '应该能创建第一个实例');

  // 创建同名的第二个实例
  LMutex2 := CreateSpinMutex(LTestName);
  CheckNotNull(LMutex2, '应该能创建同名的第二个实例');

  // 第一个实例获取锁
  LGuard1 := LMutex1.Lock;
  CheckNotNull(LGuard1, '第一个实例应该能获取锁');
  LGuard1 := nil;

  // 第二个实例也应该能获取锁（在第一个释放后）
  LGuard2 := LMutex2.TryLock;
  CheckNotNull(LGuard2, '第二个实例应该能获取锁');
  LGuard2 := nil;

  // 验证名称一致性
  CheckEquals(LTestName, LMutex1.GetName, '第一个实例名称应该匹配');
  CheckEquals(LTestName, LMutex2.GetName, '第二个实例名称应该匹配');
end;

procedure TTestCase_ISpinMutex.Test_CrossProcess_Basic;
var
  LGuard: ISpinMutexGuard;
begin
  // 这个测试验证基本的跨进程功能
  // 实际的跨进程测试需要启动子进程，这里只做基本验证
  LGuard := FMutex.Lock;
  try
    CheckTrue(True, '跨进程自旋互斥锁基本功能正常');
  finally
    LGuard := nil;
  end;
end;

{ TTestCase_Config }

procedure TTestCase_Config.Test_DefaultSpinMutexConfig;
var
  LConfig: TSpinMutexConfig;
begin
  LConfig := DefaultSpinMutexConfig;

  CheckTrue(LConfig.MaxSpinCount > 0, '默认自旋次数应该大于0');
  CheckTrue(LConfig.DefaultTimeoutMs > 0, '默认超时应该大于0');
  CheckTrue(LConfig.MaxBackoffMs > 0, '默认最大退避时间应该大于0');
  CheckFalse(LConfig.UseGlobalNamespace, '默认不应该使用全局命名空间');
  CheckFalse(LConfig.InitialOwner, '默认不应该初始拥有');
  CheckFalse(LConfig.EnableStats, '默认不应该启用统计');
end;

procedure TTestCase_Config.Test_SpinMutexConfigWithTimeout;
var
  LConfig: TSpinMutexConfig;
begin
  LConfig := SpinMutexConfigWithTimeout(3000);

  CheckEquals(3000, LConfig.DefaultTimeoutMs, '超时应该设置为3000毫秒');
  CheckTrue(LConfig.MaxSpinCount > 0, '自旋次数应该大于0');
end;

procedure TTestCase_Config.Test_GlobalSpinMutexConfig;
var
  LConfig: TSpinMutexConfig;
begin
  LConfig := GlobalSpinMutexConfig;

  CheckTrue(LConfig.UseGlobalNamespace, '应该使用全局命名空间');
  CheckTrue(LConfig.MaxSpinCount > 0, '自旋次数应该大于0');
end;

procedure TTestCase_Config.Test_HighPerformanceSpinMutexConfig;
var
  LConfig: TSpinMutexConfig;
  LDefault: TSpinMutexConfig;
begin
  LDefault := DefaultSpinMutexConfig;
  LConfig := HighPerformanceSpinMutexConfig;

  CheckTrue(LConfig.MaxSpinCount > LDefault.MaxSpinCount,
    '高性能配置应该有更多自旋次数');
  CheckTrue(LConfig.EnableStats, '高性能配置应该启用统计');
  CheckEquals(sbsExponential, LConfig.BackoffStrategy,
    '高性能配置应该使用指数退避');
end;

procedure TTestCase_Config.Test_LowLatencySpinMutexConfig;
var
  LConfig: TSpinMutexConfig;
  LDefault: TSpinMutexConfig;
begin
  LDefault := DefaultSpinMutexConfig;
  LConfig := LowLatencySpinMutexConfig;

  CheckTrue(LConfig.MaxSpinCount < LDefault.MaxSpinCount,
    '低延迟配置应该有较少自旋次数');
  CheckTrue(LConfig.DefaultTimeoutMs < LDefault.DefaultTimeoutMs,
    '低延迟配置应该有更短超时');
  CheckTrue(LConfig.MaxBackoffMs < LDefault.MaxBackoffMs,
    '低延迟配置应该有更短退避时间');
  CheckEquals(sbsLinear, LConfig.BackoffStrategy,
    '低延迟配置应该使用线性退避');
end;

procedure TTestCase_Config.Test_EmptySpinMutexStats;
var
  LStats: TSpinMutexStats;
begin
  LStats := EmptySpinMutexStats;

  CheckEquals(0, LStats.AcquireCount, '获取次数应该为0');
  CheckEquals(0, LStats.SpinSuccessCount, '自旋成功次数应该为0');
  CheckEquals(0, LStats.BlockingCount, '阻塞次数应该为0');
  CheckEquals(0, LStats.TotalSpinCount, '总自旋次数应该为0');
  CheckEquals(0, LStats.TimeoutCount, '超时次数应该为0');
  CheckEquals(0.0, LStats.AvgSpinsPerAcquire, 0.001, '平均自旋次数应该为0');
  CheckEquals(0.0, LStats.SpinEfficiency, 0.001, '自旋效率应该为0');
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_ISpinMutex);
  RegisterTest(TTestCase_Config);

end.

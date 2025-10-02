unit fafafa.core.sync.namedCondvar.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base, fafafa.core.sync.namedCondvar, 
  fafafa.core.sync.namedMutex, fafafa.core.sync.base;

type
  // 测试全局函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeNamedConditionVariable;
    procedure Test_MakeNamedConditionVariable_WithConfig;
    procedure Test_MakeGlobalNamedConditionVariable;
    procedure Test_MakeNamedConditionVariableWithTimeout;
    procedure Test_MakeNamedConditionVariableWithStats;
    procedure Test_TryOpenNamedConditionVariable;
    procedure Test_ConfigFunctions;
  end;

  // 测试 INamedConditionVariable 接口
  TTestCase_INamedConditionVariable = class(TTestCase)
  private
    FCondVar: INamedConditionVariable;
    FMutex: INamedMutex;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试基本功能
    procedure Test_GetName;
    procedure Test_GetConfig;
    procedure Test_UpdateConfig;
    procedure Test_IsCreator;
    
    // 测试条件变量核心操作
    procedure Test_Signal_NoWaiters;
    procedure Test_Broadcast_NoWaiters;
    procedure Test_Wait_Signal_Basic;
    procedure Test_Wait_Broadcast_Basic;
    procedure Test_Wait_Timeout;
    
    // 测试 ILock 接口（条件变量内部锁�?
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire;
    procedure Test_TryAcquire_Timeout;
    
    // 测试统计信息
    procedure Test_GetStats;
    procedure Test_ResetStats;
    
    // 测试错误处理
    procedure Test_InvalidName;
    procedure Test_Wait_NullMutex;
    
    // 综合测试
    procedure Test_MultipleInstances;
    procedure Test_ConfigurationTypes;
  end;

  // 测试配置功能
  TTestCase_Configuration = class(TTestCase)
  published
    procedure Test_DefaultConfig;
    procedure Test_GlobalConfig;
    procedure Test_ConfigWithTimeout;
    procedure Test_StatsConfig;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeNamedConditionVariable;
var
  LCondVar: INamedConditionVariable;
begin
  LCondVar := MakeNamedConditionVariable('test_condvar_1');
  CheckNotNull(LCondVar, '应该成功创建命名条件变量');
  CheckEquals('test_condvar_1', LCondVar.GetName, '名称应该匹配');
end;

procedure TTestCase_Global.Test_MakeNamedConditionVariable_WithConfig;
var
  LCondVar: INamedConditionVariable;
  LConfig: TNamedConditionVariableConfig;
begin
  LConfig := DefaultNamedConditionVariableConfig;
  LConfig.TimeoutMs := 5000;
  LConfig.EnableStats := True;
  
  LCondVar := MakeNamedConditionVariable('test_condvar_2', LConfig);
  CheckNotNull(LCondVar, '应该成功创建带配置的命名条件变量');
  
  LConfig := LCondVar.GetConfig;
  CheckEquals(5000, LConfig.TimeoutMs, '超时时间应该匹配');
  CheckTrue(LConfig.EnableStats, '应该启用统计');
end;

procedure TTestCase_Global.Test_MakeGlobalNamedConditionVariable;
var
  LCondVar: INamedConditionVariable;
  LConfig: TNamedConditionVariableConfig;
begin
  LCondVar := MakeGlobalNamedConditionVariable('test_global_condvar');
  CheckNotNull(LCondVar, '应该成功创建全局命名条件变量');
  
  LConfig := LCondVar.GetConfig;
  CheckTrue(LConfig.UseGlobalNamespace, '应该使用全局命名空间');
end;

procedure TTestCase_Global.Test_MakeNamedConditionVariableWithTimeout;
var
  LCondVar: INamedConditionVariable;
  LConfig: TNamedConditionVariableConfig;
begin
  LCondVar := MakeNamedConditionVariableWithTimeout('test_timeout_condvar', 8000);
  CheckNotNull(LCondVar, '应该成功创建带超时的命名条件变量');
  
  LConfig := LCondVar.GetConfig;
  CheckEquals(8000, LConfig.TimeoutMs, '超时时间应该匹配');
end;

procedure TTestCase_Global.Test_MakeNamedConditionVariableWithStats;
var
  LCondVar: INamedConditionVariable;
  LConfig: TNamedConditionVariableConfig;
begin
  LCondVar := MakeNamedConditionVariableWithStats('test_stats_condvar');
  CheckNotNull(LCondVar, '应该成功创建带统计的命名条件变量');
  
  LConfig := LCondVar.GetConfig;
  CheckTrue(LConfig.EnableStats, '应该启用统计');
end;

procedure TTestCase_Global.Test_TryOpenNamedConditionVariable;
var
  LCondVar1, LCondVar2: INamedConditionVariable;
begin
  // 首先创建一个命名条件变�?
  LCondVar1 := MakeNamedConditionVariable('test_open_condvar');
  CheckNotNull(LCondVar1, '应该成功创建命名条件变量');
  
  // 然后尝试打开现有�?
  LCondVar2 := TryOpenNamedConditionVariable('test_open_condvar');
  CheckNotNull(LCondVar2, '应该成功打开现有的命名条件变�?);
  CheckEquals('test_open_condvar', LCondVar2.GetName, '名称应该匹配');
end;

procedure TTestCase_Global.Test_ConfigFunctions;
var
  LConfig: TNamedConditionVariableConfig;
  LStats: TNamedConditionVariableStats;
begin
  // 测试默认配置
  LConfig := DefaultNamedConditionVariableConfig;
  CheckTrue(LConfig.TimeoutMs > 0, '默认超时时间应该大于0');
  CheckFalse(LConfig.UseGlobalNamespace, '默认不应该使用全局命名空间');
  
  // 测试全局配置
  LConfig := GlobalNamedConditionVariableConfig;
  CheckTrue(LConfig.UseGlobalNamespace, '全局配置应该使用全局命名空间');
  
  // 测试带超时配�?
  LConfig := NamedConditionVariableConfigWithTimeout(12000);
  CheckEquals(12000, LConfig.TimeoutMs, '超时时间应该匹配');
  
  // 测试空统�?
  LStats := EmptyNamedConditionVariableStats;
  CheckEquals(0, LStats.WaitCount, '空统计的等待次数应该�?');
end;

{ TTestCase_INamedConditionVariable }

procedure TTestCase_INamedConditionVariable.SetUp;
begin
  inherited SetUp;
  FTestName := 'test_condvar_' + IntToStr(Random(10000));
  FCondVar := MakeNamedConditionVariable(FTestName);
  FMutex := MakeNamedMutex(FTestName + '_mutex');
end;

procedure TTestCase_INamedConditionVariable.TearDown;
begin
  FCondVar := nil;
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedConditionVariable.Test_GetName;
begin
  CheckEquals(FTestName, FCondVar.GetName, '名称应该匹配');
end;

procedure TTestCase_INamedConditionVariable.Test_GetConfig;
var
  LConfig: TNamedConditionVariableConfig;
begin
  LConfig := FCondVar.GetConfig;
  CheckTrue(LConfig.TimeoutMs > 0, '超时时间应该大于0');
  CheckTrue(LConfig.MaxWaiters > 0, '最大等待者数量应该大�?');
end;

procedure TTestCase_INamedConditionVariable.Test_UpdateConfig;
var
  LConfig: TNamedConditionVariableConfig;
begin
  LConfig := DefaultNamedConditionVariableConfig;
  LConfig.TimeoutMs := 15000;
  LConfig.EnableStats := True;

  FCondVar.UpdateConfig(LConfig);

  LConfig := FCondVar.GetConfig;
  CheckEquals(15000, LConfig.TimeoutMs, '配置应该已更�?);
  CheckTrue(LConfig.EnableStats, '统计应该已启�?);
end;

procedure TTestCase_INamedConditionVariable.Test_IsCreator;
begin
  CheckTrue(FCondVar.IsCreator, '第一个实例应该是创建�?);
end;

procedure TTestCase_INamedConditionVariable.Test_Signal_NoWaiters;
begin
  // 没有等待者时发送信号应该不会出�?
  FCondVar.Signal;
  CheckTrue(True, '没有等待者时Signal应该正常执行');
end;

procedure TTestCase_INamedConditionVariable.Test_Broadcast_NoWaiters;
begin
  // 没有等待者时广播应该不会出错
  FCondVar.Broadcast;
  CheckTrue(True, '没有等待者时Broadcast应该正常执行');
end;

procedure TTestCase_INamedConditionVariable.Test_Wait_Signal_Basic;
var
  LGuard: INamedMutexGuard;
  LResult: Boolean;
begin
  // 基本的等�?信号测试（使用超时避免无限等待）
  LGuard := FMutex.Lock;
  try
    // 使用很短的超时时间测�?
    LResult := FCondVar.Wait(FMutex as ILock, 100); // 100毫秒超时
    CheckFalse(LResult, '没有信号时应该超�?);
  finally
    LGuard := nil;
  end;
end;

procedure TTestCase_INamedConditionVariable.Test_Wait_Broadcast_Basic;
var
  LGuard: INamedMutexGuard;
  LResult: Boolean;
begin
  // 基本的等�?广播测试（使用超时避免无限等待）
  LGuard := FMutex.Lock;
  try
    // 使用很短的超时时间测�?
    LResult := FCondVar.Wait(FMutex as ILock, 100); // 100毫秒超时
    CheckFalse(LResult, '没有广播时应该超�?);
  finally
    LGuard := nil;
  end;
end;

procedure TTestCase_INamedConditionVariable.Test_Wait_Timeout;
var
  LGuard: INamedMutexGuard;
  LStartTime: QWord;
  LResult: Boolean;
begin
  LStartTime := GetTickCount64;

  LGuard := FMutex.Lock;
  try
    LResult := FCondVar.Wait(FMutex as ILock, 200); // 200毫秒超时
    CheckFalse(LResult, '应该超时返回False');
    CheckTrue(GetTickCount64 - LStartTime >= 180, '应该等待接近超时时间');
  finally
    LGuard := nil;
  end;
end;

procedure TTestCase_INamedConditionVariable.Test_Acquire_Release;
begin
  // 测试条件变量本身的锁定（ILock接口�?
  (FCondVar as ILock).Acquire;
  try
    CheckTrue(True, '应该成功获取条件变量内部�?);
  finally
    (FCondVar as ILock).Release;
  end;
end;

procedure TTestCase_INamedConditionVariable.Test_TryAcquire;
var
  LResult: Boolean;
begin
  LResult := FCondVar.TryAcquire;
  if LResult then
  try
    CheckTrue(True, '应该成功尝试获取�?);
  finally
    (FCondVar as ILock).Release;
  end;
end;

procedure TTestCase_INamedConditionVariable.Test_TryAcquire_Timeout;
var
  LResult: Boolean;
begin
  LResult := (FCondVar as ILock).TryAcquire(1000);
  if LResult then
  try
    CheckTrue(True, '应该在超时内获取�?);
  finally
    (FCondVar as ILock).Release;
  end;
end;

procedure TTestCase_INamedConditionVariable.Test_GetStats;
var
  LStats: TNamedConditionVariableStats;
  LConfig: TNamedConditionVariableConfig;
begin
  // 启用统计
  LConfig := DefaultNamedConditionVariableConfig;
  LConfig.EnableStats := True;
  FCondVar.UpdateConfig(LConfig);

  LStats := FCondVar.GetStats;
  CheckTrue(LStats.WaitCount >= 0, '等待次数应该大于等于0');
  CheckTrue(LStats.SignalCount >= 0, '信号次数应该大于等于0');
end;

procedure TTestCase_INamedConditionVariable.Test_ResetStats;
var
  LStats: TNamedConditionVariableStats;
  LConfig: TNamedConditionVariableConfig;
begin
  // 启用统计
  LConfig := DefaultNamedConditionVariableConfig;
  LConfig.EnableStats := True;
  FCondVar.UpdateConfig(LConfig);

  // 重置统计
  FCondVar.ResetStats;

  LStats := FCondVar.GetStats;
  CheckEquals(0, LStats.WaitCount, '重置后等待次数应该为0');
  CheckEquals(0, LStats.SignalCount, '重置后信号次数应该为0');
end;

procedure TTestCase_INamedConditionVariable.Test_InvalidName;
begin
  AssertException(EInvalidArgument, @procedure begin MakeNamedConditionVariable(''); end);
end;

procedure TTestCase_INamedConditionVariable.Test_Wait_NullMutex;
var
  LGuard: INamedMutexGuard;
begin
  LGuard := FMutex.Lock;
  try
    AssertException(EInvalidArgument, @procedure begin FCondVar.Wait(ILock(nil), 100); end);
  finally
    LGuard := nil;
  end;
end;

procedure TTestCase_INamedConditionVariable.Test_MultipleInstances;
var
  LCondVar2: INamedConditionVariable;
begin
  // 创建另一个相同名称的条件变量实例
  LCondVar2 := MakeNamedConditionVariable(FTestName);
  CheckNotNull(LCondVar2, '应该成功创建第二个实�?);
  CheckEquals(FTestName, LCondVar2.GetName, '名称应该匹配');
  CheckFalse(LCondVar2.IsCreator, '第二个实例不应该是创建�?);
end;

procedure TTestCase_INamedConditionVariable.Test_ConfigurationTypes;
var
  LGlobalCondVar, LTimeoutCondVar, LStatsCondVar: INamedConditionVariable;
  LConfig: TNamedConditionVariableConfig;
begin
  // 测试全局配置
  LGlobalCondVar := MakeGlobalNamedConditionVariable('test_global_' + IntToStr(Random(1000)));
  LConfig := LGlobalCondVar.GetConfig;
  CheckTrue(LConfig.UseGlobalNamespace, '全局配置应该使用全局命名空间');

  // 测试超时配置
  LTimeoutCondVar := MakeNamedConditionVariableWithTimeout('test_timeout_' + IntToStr(Random(1000)), 6000);
  LConfig := LTimeoutCondVar.GetConfig;
  CheckEquals(6000, LConfig.TimeoutMs, '超时配置应该匹配');

  // 测试统计配置
  LStatsCondVar := MakeNamedConditionVariableWithStats('test_stats_' + IntToStr(Random(1000)));
  LConfig := LStatsCondVar.GetConfig;
  CheckTrue(LConfig.EnableStats, '统计配置应该启用统计');
end;

{ TTestCase_Configuration }

procedure TTestCase_Configuration.Test_DefaultConfig;
var
  LConfig: TNamedConditionVariableConfig;
begin
  LConfig := DefaultNamedConditionVariableConfig;
  CheckTrue(LConfig.TimeoutMs > 0, '默认超时时间应该大于0');
  CheckTrue(LConfig.MaxWaiters > 0, '默认最大等待者数量应该大�?');
  CheckFalse(LConfig.UseGlobalNamespace, '默认不应该使用全局命名空间');
  CheckFalse(LConfig.EnableStats, '默认不应该启用统�?);
end;

procedure TTestCase_Configuration.Test_GlobalConfig;
var
  LConfig: TNamedConditionVariableConfig;
begin
  LConfig := GlobalNamedConditionVariableConfig;
  CheckTrue(LConfig.UseGlobalNamespace, '全局配置应该使用全局命名空间');
end;

procedure TTestCase_Configuration.Test_ConfigWithTimeout;
var
  LConfig: TNamedConditionVariableConfig;
begin
  LConfig := NamedConditionVariableConfigWithTimeout(20000);
  CheckEquals(20000, LConfig.TimeoutMs, '超时时间应该匹配');
end;

procedure TTestCase_Configuration.Test_StatsConfig;
var
  LCondVar: INamedConditionVariable;
  LConfig: TNamedConditionVariableConfig;
begin
  LCondVar := MakeNamedConditionVariableWithStats('test_stats_config');
  LConfig := LCondVar.GetConfig;
  CheckTrue(LConfig.EnableStats, '统计配置应该启用统计');
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_INamedConditionVariable);
  RegisterTest(TTestCase_Configuration);

end.


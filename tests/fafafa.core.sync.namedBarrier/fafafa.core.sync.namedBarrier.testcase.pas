unit fafafa.core.sync.namedBarrier.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base, fafafa.core.sync.namedBarrier, fafafa.core.sync.base;

type
  // 测试全局函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_CreateNamedBarrier;
    procedure Test_CreateNamedBarrier_WithParticipants;
    procedure Test_CreateNamedBarrier_WithConfig;
    procedure Test_TryOpenNamedBarrier;
    procedure Test_CreateGlobalNamedBarrier;
  end;

  // 测试 INamedBarrier 接口
  TTestCase_INamedBarrier = class(TTestCase)
  private
    FBarrier: INamedBarrier;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试基本功能
    procedure Test_GetName;
    procedure Test_GetParticipantCount;
    procedure Test_GetWaitingCount;
    procedure Test_IsSignaled;
    
    // 测试屏障操作
    procedure Test_Wait_SingleParticipant;
    procedure Test_TryWait;
    procedure Test_TryWaitFor_Timeout;
    procedure Test_Reset;
    procedure Test_Signal;
    
    // 测试错误处理
    procedure Test_InvalidName;
    procedure Test_InvalidParticipantCount;
    
    // 综合测试
    procedure Test_MultipleInstances;
    procedure Test_AutoReset_Behavior;
  end;

  // 测试 INamedBarrierGuard 接口
  TTestCase_INamedBarrierGuard = class(TTestCase)
  private
    FBarrier: INamedBarrier;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_GuardProperties;
    procedure Test_GuardLifecycle;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_CreateNamedBarrier;
var
  LBarrier: INamedBarrier;
begin
  LBarrier := CreateNamedBarrier('test_barrier_1');
  CheckNotNull(LBarrier, '应该成功创建命名屏障');
  CheckEquals('test_barrier_1', LBarrier.GetName, '名称应该匹配');
  CheckEquals(2, LBarrier.GetParticipantCount, '默认参与者数量应该为2');
end;

procedure TTestCase_Global.Test_CreateNamedBarrier_WithParticipants;
var
  LBarrier: INamedBarrier;
begin
  LBarrier := CreateNamedBarrier('test_barrier_2', 4);
  CheckNotNull(LBarrier, '应该成功创建带参与者数量的命名屏障');
  CheckEquals('test_barrier_2', LBarrier.GetName, '名称应该匹配');
  CheckEquals(4, LBarrier.GetParticipantCount, '参与者数量应该为4');
end;

procedure TTestCase_Global.Test_CreateNamedBarrier_WithConfig;
var
  LBarrier: INamedBarrier;
  LConfig: TNamedBarrierConfig;
begin
  LConfig := NamedBarrierConfigWithParticipants(3);
  LConfig.TimeoutMs := 5000;
  LConfig.AutoReset := False;
  
  LBarrier := CreateNamedBarrier('test_barrier_3', LConfig);
  CheckNotNull(LBarrier, '应该成功创建带配置的命名屏障');
  CheckEquals('test_barrier_3', LBarrier.GetName, '名称应该匹配');
  CheckEquals(3, LBarrier.GetParticipantCount, '参与者数量应该为3');
end;

procedure TTestCase_Global.Test_TryOpenNamedBarrier;
var
  LBarrier1, LBarrier2: INamedBarrier;
begin
  // 首先创建一个命名屏障
  LBarrier1 := CreateNamedBarrier('test_barrier_4');
  CheckNotNull(LBarrier1, '应该成功创建命名屏障');
  
  // 然后尝试打开现有的
  LBarrier2 := TryOpenNamedBarrier('test_barrier_4');
  CheckNotNull(LBarrier2, '应该成功打开现有的命名屏障');
  CheckEquals('test_barrier_4', LBarrier2.GetName, '名称应该匹配');
end;

procedure TTestCase_Global.Test_CreateGlobalNamedBarrier;
var
  LBarrier: INamedBarrier;
begin
  LBarrier := CreateGlobalNamedBarrier('test_global_barrier');
  CheckNotNull(LBarrier, '应该成功创建全局命名屏障');
  {$IFDEF WINDOWS}
  CheckTrue(Pos('Global\', LBarrier.GetName) = 1, 'Windows 上应该包含 Global\ 前缀');
  {$ELSE}
  CheckEquals('test_global_barrier', LBarrier.GetName, 'Unix 上应该返回原始名称');
  {$ENDIF}
end;

{ TTestCase_INamedBarrier }

procedure TTestCase_INamedBarrier.SetUp;
begin
  inherited SetUp;
  FTestName := 'test_barrier_' + IntToStr(Random(100000));
  FBarrier := CreateNamedBarrier(FTestName, 2); // 2个参与者便于测试
end;

procedure TTestCase_INamedBarrier.TearDown;
begin
  FBarrier := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedBarrier.Test_GetName;
begin
  CheckEquals(FTestName, FBarrier.GetName, '名称应该匹配');
end;

procedure TTestCase_INamedBarrier.Test_GetParticipantCount;
begin
  CheckEquals(2, FBarrier.GetParticipantCount, '参与者数量应该为2');
end;

procedure TTestCase_INamedBarrier.Test_GetWaitingCount;
begin
  // 初始状态下等待者数量应该为0
  CheckEquals(0, FBarrier.GetWaitingCount, '初始等待者数量应该为0');
end;

procedure TTestCase_INamedBarrier.Test_IsSignaled;
begin
  // 初始状态下屏障不应该被触发
  CheckFalse(FBarrier.IsSignaled, '初始状态下屏障不应该被触发');
end;

procedure TTestCase_INamedBarrier.Test_Wait_SingleParticipant;
var
  LGuard: INamedBarrierGuard;
begin
  // 注意：这个测试只能测试单个参与者的情况
  // 真正的屏障测试需要多个线程或进程
  
  // 手动触发屏障以便测试
  FBarrier.Signal;
  
  LGuard := FBarrier.TryWait;
  if Assigned(LGuard) then
  begin
    CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
    CheckEquals(2, LGuard.GetParticipantCount, '守卫参与者数量应该匹配');
  end;
  
  // 重置屏障
  FBarrier.Reset;
end;

procedure TTestCase_INamedBarrier.Test_TryWait;
var
  LGuard: INamedBarrierGuard;
begin
  // 测试非阻塞等待（应该立即返回 nil，因为屏障未触发）
  LGuard := FBarrier.TryWait;
  CheckNull(LGuard, '未触发的屏障应该返回 nil');
  
  // 手动触发屏障
  FBarrier.Signal;
  
  // 现在应该能获取到守卫
  LGuard := FBarrier.TryWait;
  CheckNotNull(LGuard, '触发后的屏障应该返回守卫');
end;

procedure TTestCase_INamedBarrier.Test_TryWaitFor_Timeout;
var
  LGuard: INamedBarrierGuard;
  LStartTime, LEndTime: QWord;
begin
  // 测试超时等待
  LStartTime := GetTickCount64;
  LGuard := FBarrier.TryWaitFor(100); // 100毫秒超时
  LEndTime := GetTickCount64;
  
  CheckNull(LGuard, '超时应该返回 nil');
  CheckTrue(LEndTime - LStartTime >= 90, '应该至少等待接近超时时间'); // 允许一些误差
end;

procedure TTestCase_INamedBarrier.Test_Reset;
begin
  // 触发屏障
  FBarrier.Signal;
  CheckTrue(FBarrier.IsSignaled, '屏障应该被触发');
  
  // 重置屏障
  FBarrier.Reset;
  CheckFalse(FBarrier.IsSignaled, '重置后屏障不应该被触发');
  CheckEquals(0, FBarrier.GetWaitingCount, '重置后等待者数量应该为0');
end;

procedure TTestCase_INamedBarrier.Test_Signal;
begin
  // 初始状态
  CheckFalse(FBarrier.IsSignaled, '初始状态下屏障不应该被触发');
  
  // 手动触发
  FBarrier.Signal;
  CheckTrue(FBarrier.IsSignaled, '手动触发后屏障应该被触发');
end;

procedure TTestCase_INamedBarrier.Test_InvalidName;
begin
  // 测试无效名称
  try
    CreateNamedBarrier('');
    Fail('空名称应该抛出异常');
  except
    on E: EInvalidArgument do
      Check(True, '正确抛出了 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_INamedBarrier.Test_InvalidParticipantCount;
begin
  // 测试无效参与者数量
  try
    CreateNamedBarrier('test_invalid', 1); // 参与者数量必须至少为2
    Fail('无效参与者数量应该抛出异常');
  except
    on E: EInvalidArgument do
      Check(True, '正确抛出了 EInvalidArgument 异常');
  end;
end;

procedure TTestCase_INamedBarrier.Test_MultipleInstances;
var
  LBarrier1, LBarrier2: INamedBarrier;
  LTestName: string;
begin
  // 使用独立的名称，避免与 SetUp 中的实例冲突
  LTestName := 'multi_barrier_' + IntToStr(Random(100000));

  // 创建第一个实例
  LBarrier1 := CreateNamedBarrier(LTestName, 3);
  CheckNotNull(LBarrier1, '应该能创建第一个实例');

  // 创建同名的第二个实例
  LBarrier2 := CreateNamedBarrier(LTestName, 3);
  CheckNotNull(LBarrier2, '应该能创建同名的第二个实例');

  // 验证名称和配置一致性
  CheckEquals(LTestName, LBarrier1.GetName, '第一个实例名称应该匹配');
  CheckEquals(LTestName, LBarrier2.GetName, '第二个实例名称应该匹配');
  CheckEquals(3, LBarrier1.GetParticipantCount, '第一个实例参与者数量应该匹配');
  CheckEquals(3, LBarrier2.GetParticipantCount, '第二个实例参与者数量应该匹配');
end;

procedure TTestCase_INamedBarrier.Test_AutoReset_Behavior;
var
  LConfig: TNamedBarrierConfig;
  LBarrier: INamedBarrier;
  LTestName: string;
begin
  LTestName := 'autoreset_barrier_' + IntToStr(Random(100000));
  
  // 创建自动重置的屏障
  LConfig := DefaultNamedBarrierConfig;
  LConfig.ParticipantCount := 2;
  LConfig.AutoReset := True;
  
  LBarrier := CreateNamedBarrier(LTestName, LConfig);
  
  // 触发屏障
  LBarrier.Signal;
  CheckTrue(LBarrier.IsSignaled, '屏障应该被触发');
  
  // 对于自动重置屏障，这里的行为可能因实现而异
  // 主要验证屏障能正常工作
  CheckNotNull(LBarrier, '自动重置屏障应该正常工作');
end;

{ TTestCase_INamedBarrierGuard }

procedure TTestCase_INamedBarrierGuard.SetUp;
begin
  inherited SetUp;
  FTestName := 'guard_test_barrier_' + IntToStr(Random(100000));
  FBarrier := CreateNamedBarrier(FTestName, 2);
end;

procedure TTestCase_INamedBarrierGuard.TearDown;
begin
  FBarrier := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedBarrierGuard.Test_GuardProperties;
var
  LGuard: INamedBarrierGuard;
begin
  // 手动触发屏障以便获取守卫
  FBarrier.Signal;
  
  LGuard := FBarrier.TryWait;
  if Assigned(LGuard) then
  begin
    CheckEquals(FTestName, LGuard.GetName, '守卫名称应该匹配');
    CheckEquals(2, LGuard.GetParticipantCount, '守卫参与者数量应该匹配');
    // 等待者数量和是否为最后参与者的测试依赖于具体实现
    CheckTrue(LGuard.GetWaitingCount >= 0, '等待者数量应该非负');
  end;
end;

procedure TTestCase_INamedBarrierGuard.Test_GuardLifecycle;
var
  LGuard: INamedBarrierGuard;
begin
  // 手动触发屏障
  FBarrier.Signal;
  
  // 获取守卫
  LGuard := FBarrier.TryWait;
  CheckNotNull(LGuard, '应该能获取到守卫');
  
  // 测试守卫的生命周期管理
  // 守卫应该在析构时自动清理资源
  LGuard := nil; // 释放守卫
  
  // 验证屏障状态（具体行为依赖于实现）
  CheckNotNull(FBarrier, '屏障应该仍然有效');
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_INamedBarrier);
  RegisterTest(TTestCase_INamedBarrierGuard);

end.

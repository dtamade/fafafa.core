program example_basic_usage;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.base, fafafa.core.sync.namedBarrier;

procedure BasicBarrierExample;
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  WriteLn('=== 基本屏障使用示例 ===');
  
  // 创建一个命名屏障，2个参与者
  LBarrier := CreateNamedBarrier('example_barrier', 2);
  WriteLn('创建屏障: ', LBarrier.GetName);
  WriteLn('参与者数量: ', LBarrier.GetParticipantCount);
  
  // 显示初始状态
  WriteLn('初始等待者数量: ', LBarrier.GetWaitingCount);
  WriteLn('初始是否触发: ', BoolToStr(LBarrier.IsSignaled, True));
  
  // 手动触发屏障（模拟所有参与者到达）
  WriteLn('手动触发屏障...');
  LBarrier.Signal;
  
  // 现在尝试等待
  LGuard := LBarrier.TryWait;
  if Assigned(LGuard) then
  begin
    WriteLn('成功通过屏障！');
    WriteLn('  - 屏障名称: ', LGuard.GetName);
    WriteLn('  - 参与者数量: ', LGuard.GetParticipantCount);
    WriteLn('  - 等待者数量: ', LGuard.GetWaitingCount);
    WriteLn('  - 是否最后参与者: ', BoolToStr(LGuard.IsLastParticipant, True));
  end
  else
    WriteLn('未能通过屏障');
    
  // 重置屏障
  WriteLn('重置屏障...');
  LBarrier.Reset;
  WriteLn('重置后是否触发: ', BoolToStr(LBarrier.IsSignaled, True));
  
  WriteLn('基本示例完成');
  WriteLn;
end;

procedure TimeoutExample;
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
  LStartTime, LEndTime: QWord;
begin
  WriteLn('=== 超时等待示例 ===');
  
  // 创建屏障
  LBarrier := CreateNamedBarrier('timeout_barrier', 3);
  WriteLn('创建屏障，需要3个参与者');
  
  // 测试超时等待
  WriteLn('测试1秒超时等待...');
  LStartTime := GetTickCount64;
  LGuard := LBarrier.TryWaitFor(1000);
  LEndTime := GetTickCount64;
  
  if Assigned(LGuard) then
    WriteLn('意外通过了屏障')
  else
  begin
    WriteLn('超时返回，耗时: ', LEndTime - LStartTime, ' 毫秒');
  end;
  
  // 测试立即返回
  WriteLn('测试立即返回...');
  LStartTime := GetTickCount64;
  LGuard := LBarrier.TryWait;
  LEndTime := GetTickCount64;
  
  if Assigned(LGuard) then
    WriteLn('意外通过了屏障')
  else
  begin
    WriteLn('立即返回，耗时: ', LEndTime - LStartTime, ' 毫秒');
  end;
  
  WriteLn('超时示例完成');
  WriteLn;
end;

procedure ConfigurationExample;
var
  LConfig: TNamedBarrierConfig;
  LBarrier: INamedBarrier;
begin
  WriteLn('=== 配置示例 ===');
  
  // 使用默认配置
  WriteLn('默认配置:');
  LConfig := DefaultNamedBarrierConfig;
  WriteLn('  - 超时时间: ', LConfig.TimeoutMs, ' 毫秒');
  WriteLn('  - 参与者数量: ', LConfig.ParticipantCount);
  WriteLn('  - 自动重置: ', BoolToStr(LConfig.AutoReset, True));
  WriteLn('  - 全局命名空间: ', BoolToStr(LConfig.UseGlobalNamespace, True));
  
  // 自定义配置
  WriteLn('自定义配置:');
  LConfig := NamedBarrierConfigWithParticipants(5);
  LConfig.TimeoutMs := 10000;  // 10秒超时
  LConfig.AutoReset := False;  // 手动重置
  
  LBarrier := CreateNamedBarrier('config_barrier', LConfig);
  WriteLn('  - 屏障名称: ', LBarrier.GetName);
  WriteLn('  - 参与者数量: ', LBarrier.GetParticipantCount);
  
  // 全局屏障示例
  WriteLn('全局屏障:');
  LBarrier := CreateGlobalNamedBarrier('global_barrier', 4);
  WriteLn('  - 屏障名称: ', LBarrier.GetName);
  WriteLn('  - 参与者数量: ', LBarrier.GetParticipantCount);
  
  WriteLn('配置示例完成');
  WriteLn;
end;

procedure MultipleInstanceExample;
var
  LBarrier1, LBarrier2: INamedBarrier;
  LBarrierName: string;
begin
  WriteLn('=== 多实例示例 ===');
  
  LBarrierName := 'shared_barrier';
  
  // 创建第一个实例
  LBarrier1 := CreateNamedBarrier(LBarrierName, 2);
  WriteLn('创建第一个实例: ', LBarrier1.GetName);
  
  // 创建第二个实例（应该连接到同一个屏障）
  LBarrier2 := CreateNamedBarrier(LBarrierName, 2);
  WriteLn('创建第二个实例: ', LBarrier2.GetName);
  
  // 验证它们引用同一个屏障
  WriteLn('两个实例参与者数量相同: ', 
    BoolToStr(LBarrier1.GetParticipantCount = LBarrier2.GetParticipantCount, True));
  
  // 从一个实例触发屏障
  WriteLn('从第一个实例触发屏障...');
  LBarrier1.Signal;
  
  // 从另一个实例检查状态
  WriteLn('第二个实例看到的状态: ', BoolToStr(LBarrier2.IsSignaled, True));
  
  // 从第二个实例重置
  WriteLn('从第二个实例重置屏障...');
  LBarrier2.Reset;
  
  // 从第一个实例检查状态
  WriteLn('第一个实例看到的状态: ', BoolToStr(LBarrier1.IsSignaled, True));
  
  WriteLn('多实例示例完成');
  WriteLn;
end;

procedure ErrorHandlingExample;
var
  LBarrier: INamedBarrier;
begin
  WriteLn('=== 错误处理示例 ===');
  
  // 测试无效名称
  try
    LBarrier := CreateNamedBarrier('');
    WriteLn('错误：应该抛出异常');
  except
    on E: EInvalidArgument do
      WriteLn('正确捕获无效名称异常: ', E.Message);
    on E: Exception do
      WriteLn('意外异常: ', E.ClassName, ' - ', E.Message);
  end;
  
  // 测试无效参与者数量
  try
    LBarrier := CreateNamedBarrier('test_barrier', 1);
    WriteLn('错误：应该抛出异常');
  except
    on E: EInvalidArgument do
      WriteLn('正确捕获无效参与者数量异常: ', E.Message);
    on E: Exception do
      WriteLn('意外异常: ', E.ClassName, ' - ', E.Message);
  end;
  
  // 测试尝试打开不存在的屏障
  LBarrier := TryOpenNamedBarrier('nonexistent_barrier');
  if Assigned(LBarrier) then
    WriteLn('成功打开屏障: ', LBarrier.GetName)
  else
    WriteLn('屏障不存在或无法打开');
  
  WriteLn('错误处理示例完成');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.namedBarrier 基本使用示例');
  WriteLn('==========================================');
  WriteLn;
  
  try
    BasicBarrierExample;
    TimeoutExample;
    ConfigurationExample;
    MultipleInstanceExample;
    ErrorHandlingExample;
    
    WriteLn('所有示例执行完成！');
    WriteLn;
    WriteLn('注意：');
    WriteLn('- 真正的屏障同步需要多个进程或线程');
    WriteLn('- 这些示例主要展示API的使用方法');
    WriteLn('- 实际应用中，多个进程会同时调用Wait()方法');
    WriteLn('- 当所有参与者都到达时，屏障会自动触发');
    
  except
    on E: Exception do
    begin
      WriteLn('示例执行出错: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.

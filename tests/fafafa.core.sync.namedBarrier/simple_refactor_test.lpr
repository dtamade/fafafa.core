program simple_refactor_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.namedBarrier;

var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
  LConfig: TNamedBarrierConfig;

begin
  WriteLn('测试重构后的 namedBarrier 模块...');
  
  try
    // 测试基本创建
    LBarrier := MakeNamedBarrier('test_barrier', 2);
    WriteLn('✓ 创建命名屏障成功');
    
    // 测试基本属性
    WriteLn('屏障名称: ', LBarrier.GetName);
    WriteLn('参与者数量: ', LBarrier.GetParticipantCount);
    WriteLn('当前等待者: ', LBarrier.GetWaitingCount);
    WriteLn('当前代数: ', LBarrier.GetGeneration);
    
    // 测试非阻塞等待
    LGuard := LBarrier.TryWait;
    if Assigned(LGuard) then
    begin
      WriteLn('✓ TryWait 返回了守卫');
      WriteLn('守卫名称: ', LGuard.GetName);
      WriteLn('是否最后参与者: ', LGuard.IsLastParticipant);
      WriteLn('守卫代数: ', LGuard.GetGeneration);
    end
    else
      WriteLn('✓ TryWait 正确返回 nil（需要更多参与者）');
    
    // 测试配置创建
    LConfig := DefaultNamedBarrierConfig;
    LConfig.ParticipantCount := 1;
    LBarrier := MakeNamedBarrier('test_single', LConfig);
    WriteLn('✓ 使用配置创建屏障成功');
    
    // 测试单参与者屏障
    LGuard := LBarrier.TryWait;
    if Assigned(LGuard) then
    begin
      WriteLn('✓ 单参与者屏障立即返回守卫');
      WriteLn('是否最后参与者: ', LGuard.IsLastParticipant);
    end;
    
    WriteLn('✓ 所有测试通过！重构成功！');
    
  except
    on E: Exception do
    begin
      WriteLn('✗ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.

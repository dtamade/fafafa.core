program simple_compile_test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.socket.poller;

{**
 * 简单的编译测试
 * 验证新增的轮询器代码能否正常编译
 *}

var
  LPoller: IAdvancedSocketPoller;
  LAvailable: TArray<string>;
  LRecommended: string;

begin
  WriteLn('fafafa.core.socket.poller 编译测试');
  WriteLn('==================================');
  WriteLn('');
  
  try
    // 测试工厂方法
    WriteLn('测试轮询器工厂...');
    
    LAvailable := TSocketPollerFactory.GetAvailablePollers;
    WriteLn('可用轮询器数量: ', Length(LAvailable));
    
    LRecommended := TSocketPollerFactory.GetRecommendedPoller;
    WriteLn('推荐轮询器: ', LRecommended);
    
    // 测试创建轮询器
    WriteLn('测试创建轮询器...');
    LPoller := TSocketPollerFactory.CreateBest(100);
    if Assigned(LPoller) then
    begin
      WriteLn('✓ 轮询器创建成功');
      WriteLn('轮询器类型: ', LPoller.GetPollerType);
      WriteLn('最大Socket数: ', LPoller.GetMaxSockets);
      WriteLn('高性能模式: ', IfThen(LPoller.IsHighPerformance, '是', '否'));
    end
    else
      WriteLn('✗ 轮询器创建失败');
    
    WriteLn('');
    WriteLn('✓ 编译测试通过！');
    
  except
    on E: Exception do
    begin
      WriteLn('✗ 测试失败: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.

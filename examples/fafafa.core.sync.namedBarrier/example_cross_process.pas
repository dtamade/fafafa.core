program example_cross_process;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.sync.namedBarrier;

const
  BARRIER_NAME = 'cross_process_barrier';
  PARTICIPANT_COUNT = 3;

procedure ShowUsage;
begin
  WriteLn('跨进程屏障同步示例');
  WriteLn('==================');
  WriteLn;
  WriteLn('用法:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' [participant_id]');
  WriteLn;
  WriteLn('参数:');
  WriteLn('  participant_id  参与者ID (1-', PARTICIPANT_COUNT, ')');
  WriteLn;
  WriteLn('示例:');
  WriteLn('  在第一个终端运行: ', ExtractFileName(ParamStr(0)), ' 1');
  WriteLn('  在第二个终端运行: ', ExtractFileName(ParamStr(0)), ' 2');
  WriteLn('  在第三个终端运行: ', ExtractFileName(ParamStr(0)), ' 3');
  WriteLn;
  WriteLn('所有参与者都到达屏障后，程序将继续执行。');
end;

procedure RunParticipant(AParticipantId: Integer);
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
  LStartTime: TDateTime;
  Info: TNamedBarrierInfo;
begin
  WriteLn('参与者 ', AParticipantId, ' 启动');
  WriteLn('屏障名称: ', BARRIER_NAME);
  WriteLn('需要参与者数量: ', PARTICIPANT_COUNT);
  WriteLn;
  
  try
    // 创建或连接到命名屏障
    LBarrier := MakeNamedBarrier(BARRIER_NAME, PARTICIPANT_COUNT);
    WriteLn('成功连接到屏障');
    
    // 显示当前状态
    Info := LBarrier.GetInfo;
    WriteLn('当前等待者数量: ', Info.CurrentWaitingCount);
    WriteLn('屏障是否已触发: ', BoolToStr(Info.IsSignaled, True));
    WriteLn;
    
    // 模拟一些工作
    WriteLn('参与者 ', AParticipantId, ' 正在执行准备工作...');
    Sleep(Random(2000) + 1000); // 1-3秒随机延迟
    WriteLn('参与者 ', AParticipantId, ' 准备工作完成，到达屏障');
    WriteLn;
    
    // 等待屏障
    WriteLn('等待其他参与者到达屏障...');
    LStartTime := Now;
    
    LGuard := LBarrier.Wait;
    
    if Assigned(LGuard) then
    begin
      WriteLn('*** 所有参与者已到达屏障！***');
      WriteLn('等待时间: ', FormatDateTime('ss.zzz', Now - LStartTime), ' 秒');
      WriteLn('参与者 ', AParticipantId, ' 的屏障信息:');
      WriteLn('  - 是否最后参与者: ', BoolToStr(LGuard.IsLastParticipant, True));
      WriteLn('  - 屏障代数: ', LGuard.GetGeneration);
      WriteLn('  - 等待耗时(ms): ', LGuard.GetWaitTime);
      WriteLn;
      
      // 屏障后的工作
      WriteLn('参与者 ', AParticipantId, ' 开始执行屏障后的工作...');
      Sleep(Random(1000) + 500); // 0.5-1.5秒随机延迟
      WriteLn('参与者 ', AParticipantId, ' 工作完成');
    end
    else
    begin
      WriteLn('错误：未能通过屏障');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('参与者 ', AParticipantId, ' 发生错误: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('参与者 ', AParticipantId, ' 退出');
end;

procedure RunCoordinator;
var
  LBarrier: INamedBarrier;
  LLastWaitingCount: Cardinal;
  LCurrentWaitingCount: Cardinal;
begin
  WriteLn('协调器模式');
  WriteLn('监控屏障状态: ', BARRIER_NAME);
  WriteLn('需要参与者数量: ', PARTICIPANT_COUNT);
  WriteLn;
  
  try
    // 创建屏障
    LBarrier := MakeNamedBarrier(BARRIER_NAME, PARTICIPANT_COUNT);
    WriteLn('屏障已创建，等待参与者...');
    WriteLn('按 Ctrl+C 退出监控');
    WriteLn;
    
    LLastWaitingCount := 0;
    
    // 监控循环
    while True do
    begin
      LCurrentWaitingCount := LBarrier.GetInfo.CurrentWaitingCount;
      
      if LCurrentWaitingCount <> LLastWaitingCount then
      begin
        WriteLn('[', FormatDateTime('hh:nn:ss', Now), '] ',
                '等待者数量: ', LCurrentWaitingCount, '/', PARTICIPANT_COUNT);
        
        if LCurrentWaitingCount >= PARTICIPANT_COUNT then
        begin
          WriteLn('[', FormatDateTime('hh:nn:ss', Now), '] ',
                  '所有参与者已到达，屏障触发！');
          Break;
        end;
        
        LLastWaitingCount := LCurrentWaitingCount;
      end;
      
      Sleep(100); // 100毫秒检查间隔
    end;
    
    WriteLn;
    WriteLn('监控完成');
    
  except
    on E: Exception do
    begin
      WriteLn('协调器发生错误: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

var
  LParticipantId: Integer;
  LParam: string;

begin
  Randomize;
  
  if ParamCount = 0 then
  begin
    ShowUsage;
    Exit;
  end;
  
  LParam := LowerCase(ParamStr(1));
  
  if (LParam = 'help') or (LParam = '-h') or (LParam = '--help') then
  begin
    ShowUsage;
    Exit;
  end;
  
  if LParam = 'coordinator' then
  begin
    RunCoordinator;
    Exit;
  end;
  
  // 解析参与者ID
  if not TryStrToInt(ParamStr(1), LParticipantId) then
  begin
    WriteLn('错误：无效的参与者ID "', ParamStr(1), '"');
    WriteLn;
    ShowUsage;
    ExitCode := 1;
    Exit;
  end;
  
  if (LParticipantId < 1) or (LParticipantId > PARTICIPANT_COUNT) then
  begin
    WriteLn('错误：参与者ID必须在 1-', PARTICIPANT_COUNT, ' 范围内');
    WriteLn;
    ShowUsage;
    ExitCode := 1;
    Exit;
  end;
  
  RunParticipant(LParticipantId);
end.

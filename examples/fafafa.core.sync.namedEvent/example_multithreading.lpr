{$CODEPAGE UTF8}
program example_multithreading;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.namedEvent;

type
  // 工作线程类
  TWorkerThread = class(TThread)
  private
    FThreadID: Integer;
    FEvent: INamedEvent;
    FSuccessCount: Integer;
    FErrorCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AThreadID: Integer; AEvent: INamedEvent);
    property SuccessCount: Integer read FSuccessCount;
    property ErrorCount: Integer read FErrorCount;
  end;

constructor TWorkerThread.Create(AThreadID: Integer; AEvent: INamedEvent);
begin
  FThreadID := AThreadID;
  FEvent := AEvent;
  FSuccessCount := 0;
  FErrorCount := 0;
  inherited Create(False);
end;

procedure TWorkerThread.Execute;
var
  LGuard: INamedEventGuard;
  I: Integer;
begin
  WriteLn('🚀 线程 ', FThreadID, ' 启动 (TID: ', ThreadID, ')');
  
  try
    for I := 1 to 10 do
    begin
      // 等待事件触发
      LGuard := FEvent.TryWaitFor(5000); // 5秒超时
      
      if Assigned(LGuard) then
      begin
        Inc(FSuccessCount);
        WriteLn('✅ 线程 ', FThreadID, ' 第 ', I, ' 次获取事件成功');
        
        // 模拟工作
        Sleep(50 + Random(100));
        
        LGuard := nil; // 释放守卫
      end
      else
      begin
        Inc(FErrorCount);
        WriteLn('⏰ 线程 ', FThreadID, ' 第 ', I, ' 次等待超时');
      end;
      
      // 短暂休息
      Sleep(10);
    end;
    
  except
    on E: Exception do
    begin
      Inc(FErrorCount);
      WriteLn('❌ 线程 ', FThreadID, ' 出错: ', E.Message);
    end;
  end;
  
  WriteLn('🏁 线程 ', FThreadID, ' 完成 (成功: ', FSuccessCount, ', 错误: ', FErrorCount, ')');
end;

procedure DemoManualResetBroadcast;
const
  THREAD_COUNT = 4;
var
  LEvent: INamedEvent;
  LThreads: array[0..THREAD_COUNT-1] of TWorkerThread;
  I: Integer;
  LTotalSuccess, LTotalErrors: Integer;
begin
  WriteLn('=== 手动重置事件广播示例 ===');
  WriteLn('创建 ', THREAD_COUNT, ' 个工作线程，使用手动重置事件');
  WriteLn;
  
  // 创建手动重置事件
  LEvent := MakeManualResetNamedEvent('MultiThreadDemo', False);
  WriteLn('✓ 创建手动重置事件: ', LEvent.GetName);
  
  // 创建工作线程
  for I := 0 to THREAD_COUNT-1 do
  begin
    LThreads[I] := TWorkerThread.Create(I+1, LEvent);
  end;
  
  WriteLn('✓ 创建了 ', THREAD_COUNT, ' 个工作线程');
  WriteLn;
  
  // 定期触发事件
  for I := 1 to 15 do
  begin
    WriteLn('📢 第 ', I, ' 次广播事件...');
    LEvent.SetEvent;
    
    // 让线程有时间处理
    Sleep(200);
    
    // 重置事件
    LEvent.ResetEvent;
    Sleep(100);
  end;
  
  WriteLn('⏳ 等待所有线程完成...');
  
  // 等待所有线程完成
  LTotalSuccess := 0;
  LTotalErrors := 0;
  for I := 0 to THREAD_COUNT-1 do
  begin
    LThreads[I].WaitFor;
    LTotalSuccess := LTotalSuccess + LThreads[I].SuccessCount;
    LTotalErrors := LTotalErrors + LThreads[I].ErrorCount;
    LThreads[I].Free;
  end;
  
  WriteLn;
  WriteLn('📊 统计结果:');
  WriteLn('  总成功次数: ', LTotalSuccess);
  WriteLn('  总错误次数: ', LTotalErrors);
  WriteLn('  平均每线程成功: ', LTotalSuccess / THREAD_COUNT:0:1);
  WriteLn;
end;

procedure DemoAutoResetCompetition;
const
  THREAD_COUNT = 3;
var
  LEvent: INamedEvent;
  LThreads: array[0..THREAD_COUNT-1] of TWorkerThread;
  I: Integer;
  LTotalSuccess, LTotalErrors: Integer;
begin
  WriteLn('=== 自动重置事件竞争示例 ===');
  WriteLn('创建 ', THREAD_COUNT, ' 个工作线程，使用自动重置事件');
  WriteLn;
  
  // 创建自动重置事件
  LEvent := MakeAutoResetNamedEvent('CompetitionDemo', False);
  WriteLn('✓ 创建自动重置事件: ', LEvent.GetName);
  
  // 创建工作线程
  for I := 0 to THREAD_COUNT-1 do
  begin
    LThreads[I] := TWorkerThread.Create(I+1, LEvent);
  end;
  
  WriteLn('✓ 创建了 ', THREAD_COUNT, ' 个竞争线程');
  WriteLn;
  
  // 定期触发事件（每次只有一个线程能获取）
  for I := 1 to 20 do
  begin
    WriteLn('🎯 第 ', I, ' 次触发事件（只有一个线程能获取）...');
    LEvent.SetEvent;
    
    // 让线程有时间竞争
    Sleep(150);
  end;
  
  WriteLn('⏳ 等待所有线程完成...');
  
  // 等待所有线程完成
  LTotalSuccess := 0;
  LTotalErrors := 0;
  for I := 0 to THREAD_COUNT-1 do
  begin
    LThreads[I].WaitFor;
    LTotalSuccess := LTotalSuccess + LThreads[I].SuccessCount;
    LTotalErrors := LTotalErrors + LThreads[I].ErrorCount;
    LThreads[I].Free;
  end;
  
  WriteLn;
  WriteLn('📊 竞争结果:');
  WriteLn('  总成功次数: ', LTotalSuccess, ' (应该接近20)');
  WriteLn('  总错误次数: ', LTotalErrors);
  for I := 0 to THREAD_COUNT-1 do
    WriteLn('  线程 ', I+1, ' 获胜次数: ', LThreads[I].SuccessCount);
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.namedEvent 多线程示例');
  WriteLn('======================================');
  WriteLn;
  
  // 初始化随机数种子
  Randomize;
  
  try
    DemoManualResetBroadcast;
    DemoAutoResetCompetition;
    
    WriteLn('🎉 多线程示例完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 示例运行出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.

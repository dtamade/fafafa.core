{$CODEPAGE UTF8}
program concurrent_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedEvent;

const
  THREAD_COUNT = 10;
  ITERATIONS_PER_THREAD = 100;
  EVENT_NAME = 'ConcurrentTest_Event';

type
  TTestThread = class(TThread)
  private
    FThreadId: Integer;
    FEvent: INamedEvent;
    FSuccessCount: Integer;
    FErrorCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AThreadId: Integer; AEvent: INamedEvent);
    property SuccessCount: Integer read FSuccessCount;
    property ErrorCount: Integer read FErrorCount;
  end;

constructor TTestThread.Create(AThreadId: Integer; AEvent: INamedEvent);
begin
  FThreadId := AThreadId;
  FEvent := AEvent;
  FSuccessCount := 0;
  FErrorCount := 0;
  inherited Create(False);
end;

procedure TTestThread.Execute;
var
  I: Integer;
  LGuard: INamedEventGuard;
begin
  for I := 1 to ITERATIONS_PER_THREAD do
  begin
    try
      // 随机操作：设置事件或等待事件
      if Random(2) = 0 then
      begin
        // 设置事件
        FEvent.SetEvent;
        Inc(FSuccessCount);
      end
      else
      begin
        // 尝试等待事件（短超时）
        LGuard := FEvent.TryWaitFor(10);
        if Assigned(LGuard) then
          Inc(FSuccessCount)
        else
          Inc(FSuccessCount); // 超时也算正常
        LGuard := nil;
      end;
      
      // 随机延迟
      if Random(10) = 0 then
        Sleep(1);
        
    except
      on E: Exception do
      begin
        Inc(FErrorCount);
        WriteLn('[Thread ', FThreadId, '] 错误: ', E.Message);
      end;
    end;
  end;
  
  WriteLn('[Thread ', FThreadId, '] 完成: 成功=', FSuccessCount, ', 错误=', FErrorCount);
end;

var
  LEvent: INamedEvent;
  LThreads: array[0..THREAD_COUNT-1] of TTestThread;
  I: Integer;
  LTotalSuccess, LTotalErrors: Integer;
begin
  WriteLn('开始多线程并发测试...');
  WriteLn('线程数: ', THREAD_COUNT);
  WriteLn('每线程迭代数: ', ITERATIONS_PER_THREAD);
  
  try
    // 创建手动重置事件
    LEvent := CreateManualResetNamedEvent(EVENT_NAME + '_' + IntToStr(GetProcessID), False);
    WriteLn('创建事件成功');
    
    // 创建并启动线程
    for I := 0 to THREAD_COUNT-1 do
    begin
      LThreads[I] := TTestThread.Create(I+1, LEvent);
    end;
    
    WriteLn('所有线程已启动，等待完成...');
    
    // 等待所有线程完成
    for I := 0 to THREAD_COUNT-1 do
    begin
      LThreads[I].WaitFor;
    end;
    
    // 统计结果
    LTotalSuccess := 0;
    LTotalErrors := 0;
    for I := 0 to THREAD_COUNT-1 do
    begin
      LTotalSuccess := LTotalSuccess + LThreads[I].SuccessCount;
      LTotalErrors := LTotalErrors + LThreads[I].ErrorCount;
      LThreads[I].Free;
    end;
    
    WriteLn('=== 并发测试结果 ===');
    WriteLn('总成功操作: ', LTotalSuccess);
    WriteLn('总错误操作: ', LTotalErrors);
    WriteLn('成功率: ', (LTotalSuccess * 100.0 / (LTotalSuccess + LTotalErrors)):0:2, '%');
    
    if LTotalErrors = 0 then
    begin
      WriteLn('✅ 并发测试通过！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('❌ 并发测试失败！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.

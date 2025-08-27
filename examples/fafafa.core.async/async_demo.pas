program AsyncDemo;

{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.async,
  fafafa.core.thread.types;

// 语法糖宏定义（模拟 await）
{$MACRO ON}
{$DEFINE await := .GetValue}

// 演示1: 简单的异步文件操作
procedure DemoFileOperations;
var
  Content: string;
  Success: Boolean;
begin
  WriteLn('=== 异步文件操作演示 ===');
  
  try
    // 异步读取文件
    WriteLn('读取文件...');
    Content := Async.ReadText('test.txt') await;
    WriteLn('文件内容: ', Copy(Content, 1, 50), '...');
    
    // 异步写入文件
    WriteLn('写入文件...');
    Success := Async.WriteText('output.txt', 'Hello from Async Pascal!') await;
    if Success then
      WriteLn('文件写入成功')
    else
      WriteLn('文件写入失败');
      
  except
    on E: Exception do
      WriteLn('文件操作错误: ', E.Message);
  end;
end;

// 演示2: 异步网络操作
procedure DemoNetworkOperations;
var
  Response: string;
begin
  WriteLn('=== 异步网络操作演示 ===');
  
  try
    // HTTP GET 请求
    WriteLn('发送 HTTP 请求...');
    Response := Async.HttpGet('https://httpbin.org/json') await;
    WriteLn('响应长度: ', Length(Response), ' 字节');
    WriteLn('响应内容: ', Copy(Response, 1, 100), '...');
    
  except
    on E: Exception do
      WriteLn('网络请求错误: ', E.Message);
  end;
end;

// 演示3: 并发操作
procedure DemoConcurrentOperations;
var
  Results: TArray<string>;
  URLs: array[0..2] of string;
  Futures: array[0..2] of IFuture<string>;
  i: Integer;
begin
  WriteLn('=== 并发操作演示 ===');
  
  // 准备多个 URL
  URLs[0] := 'https://httpbin.org/delay/1';
  URLs[1] := 'https://httpbin.org/delay/2';
  URLs[2] := 'https://httpbin.org/delay/3';
  
  try
    // 启动并发请求
    WriteLn('启动 3 个并发请求...');
    for i := 0 to 2 do
      Futures[i] := Async.HttpGet(URLs[i]);
    
    // 等待所有请求完成
    Results := Async.WhenAll<string>(Futures) await;
    
    WriteLn('所有请求完成:');
    for i := 0 to High(Results) do
      WriteLn('  请求 ', i + 1, ': ', Length(Results[i]), ' 字节');
      
  except
    on E: Exception do
      WriteLn('并发操作错误: ', E.Message);
  end;
end;

// 演示4: 定时器操作
procedure DemoTimerOperations;
var
  Timer: IAsyncTimer;
  DelayResult: Boolean;
begin
  WriteLn('=== 定时器操作演示 ===');
  
  try
    // 简单延时
    WriteLn('延时 2 秒...');
    DelayResult := Async.Delay(2000) await;
    WriteLn('延时完成');
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 定时器（需要匿名方法支持）
    WriteLn('启动定时器（每秒执行一次）...');
    Timer := Async.Interval(1000, procedure
      begin
        WriteLn('定时器触发: ', FormatDateTime('hh:nn:ss', Now));
      end);
    
    // 运行 5 秒后停止
    Async.Delay(5000) await;
    Timer.Stop await;
    WriteLn('定时器已停止');
    {$ENDIF}
    
  except
    on E: Exception do
      WriteLn('定时器操作错误: ', E.Message);
  end;
end;

// 演示5: 流式操作
procedure DemoStreamOperations;
var
  Numbers: IAsyncStream<Integer>;
  Results: TArray<Integer>;
begin
  WriteLn('=== 流式操作演示 ===');
  
  try
    // 创建数字流并进行转换
    Numbers := Async.Range(1, 20);
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 过滤偶数，取前 5 个
    Results := Numbers
      .Filter(function(const N: Integer): IFuture<Boolean>
        begin
          Result := TFuture<Boolean>.Completed(N mod 2 = 0);
        end)
      .Take(5)
      .ToArray await;
    {$ELSE}
    // 不支持匿名方法时的简化版本
    Results := Numbers.Take(5).ToArray await;
    {$ENDIF}
    
    WriteLn('流处理结果:');
    for var Num in Results do
      WriteLn('  ', Num);
      
  except
    on E: Exception do
      WriteLn('流操作错误: ', E.Message);
  end;
end;

// 演示6: 错误处理和超时
procedure DemoErrorHandling;
var
  Future: IFuture<string>;
  Result: string;
begin
  WriteLn('=== 错误处理和超时演示 ===');
  
  try
    // 创建一个会超时的请求
    Future := Async.HttpGet('https://httpbin.org/delay/10');
    
    // 设置 3 秒超时
    Result := Async.Timeout<string>(Future, 3000) await;
    WriteLn('请求成功: ', Length(Result), ' 字节');
    
  except
    on E: EAsyncTimeoutException do
      WriteLn('请求超时: ', E.Message);
    on E: Exception do
      WriteLn('其他错误: ', E.Message);
  end;
end;

// 演示7: 链式调用
procedure DemoChainedOperations;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
var
  FinalResult: string;
{$ENDIF}
begin
  WriteLn('=== 链式调用演示 ===');
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  try
    // 链式异步操作
    FinalResult := Async.ReadText('input.txt')
      .Then<string>(function(const Content: string): IFuture<string>
        begin
          // 转换为大写
          Result := TFuture<string>.Completed(UpperCase(Content));
        end)
      .Then<string>(function(const UpperContent: string): IFuture<string>
        begin
          // 添加前缀
          Result := TFuture<string>.Completed('PROCESSED: ' + UpperContent);
        end)
      .Catch(function(const Error: Exception): IFuture<string>
        begin
          // 错误处理
          Result := TFuture<string>.Completed('ERROR: ' + Error.Message);
        end)
      .Finally(procedure
        begin
          WriteLn('处理完成');
        end) await;
    
    WriteLn('最终结果: ', Copy(FinalResult, 1, 100));
    
  except
    on E: Exception do
      WriteLn('链式操作错误: ', E.Message);
  end;
  {$ELSE}
  WriteLn('链式调用需要匿名方法支持');
  {$ENDIF}
end;

// 主程序
begin
  WriteLn('FreePascal 高级异步 I/O 框架演示');
  WriteLn('=====================================');
  
  try
    // 可选：显式启动异步运行时
    // Async.Run;
    
    // 运行各种演示
    DemoFileOperations;
    WriteLn;
    
    DemoNetworkOperations;
    WriteLn;
    
    DemoConcurrentOperations;
    WriteLn;
    
    DemoTimerOperations;
    WriteLn;
    
    DemoStreamOperations;
    WriteLn;
    
    DemoErrorHandling;
    WriteLn;
    
    DemoChainedOperations;
    WriteLn;
    
    WriteLn('所有演示完成');
    
  except
    on E: Exception do
    begin
      WriteLn('程序错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  // 优雅关闭
  Async.Shutdown;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.

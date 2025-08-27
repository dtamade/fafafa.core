program example_poller_benchmark;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes, DateUtils,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.socket.poller;

{**
 * 轮询器性能基准测试
 * 
 * 本程序对比不同轮询器的性能：
 * 1. 连接建立性能
 * 2. 事件处理性能
 * 3. 内存使用情况
 * 4. CPU 使用率
 *}

type
  TBenchmarkResult = record
    PollerType: string;
    MaxConnections: Integer;
    ConnectionsPerSecond: Double;
    EventsPerSecond: Double;
    AverageLatencyMs: Double;
    MemoryUsageMB: Double;
    TestDurationSec: Double;
  end;

var
  GResults: array of TBenchmarkResult;

procedure AddResult(const AResult: TBenchmarkResult);
begin
  SetLength(GResults, Length(GResults) + 1);
  GResults[High(GResults)] := AResult;
end;

procedure PrintResults;
var
  I: Integer;
begin
  WriteLn('');
  WriteLn('轮询器性能基准测试结果');
  WriteLn('=====================================');
  WriteLn('轮询器类型    | 最大连接 | 连接/秒  | 事件/秒  | 延迟(ms) | 内存(MB) | 耗时(s)');
  WriteLn('--------------------------------------------------------------------------');
  
  for I := 0 to High(GResults) do
  begin
    with GResults[I] do
      WriteLn(Format('%-12s | %8d | %8.0f | %8.0f | %8.2f | %8.1f | %7.1f', 
        [PollerType, MaxConnections, ConnectionsPerSecond, EventsPerSecond, 
         AverageLatencyMs, MemoryUsageMB, TestDurationSec]));
  end;
  WriteLn('--------------------------------------------------------------------------');
end;

function BenchmarkPoller(const APollerType: string; AMaxConnections: Integer; ATestDurationSec: Integer): TBenchmarkResult;
var
  LPoller: IAdvancedSocketPoller;
  LListener: ISocketListener;
  LClients: array of ISocket;
  LStartTime: TDateTime;
  LConnectionCount: Integer;
  LEventCount: Integer;
  LMetrics: TPollerMetrics;
  I: Integer;
begin
  WriteLn('测试轮询器: ', APollerType);
  
  // 创建轮询器
  if APollerType = 'select' then
    LPoller := TSocketPollerFactory.CreateSelect(AMaxConnections)
  {$IFDEF WINDOWS}
  else if APollerType = 'iocp' then
    LPoller := TSocketPollerFactory.CreateIOCP(AMaxConnections)
  {$ENDIF}
  {$IFDEF LINUX}
  else if APollerType = 'epoll' then
    LPoller := TSocketPollerFactory.CreateEpoll(AMaxConnections)
  {$ENDIF}
  {$IFDEF DARWIN}
  else if APollerType = 'kqueue' then
    LPoller := TSocketPollerFactory.CreateKqueue(AMaxConnections)
  {$ENDIF}
  else
    LPoller := TSocketPollerFactory.CreateBest(AMaxConnections);
    
  try
    // 创建监听器
    LListener := TSocketListener.ListenTCP(8081);
    LListener.Start;
    
    // 注册监听器
    LPoller.RegisterSocket(LListener as ISocket, [seRead]);
    
    SetLength(LClients, 0);
    LConnectionCount := 0;
    LEventCount := 0;
    LStartTime := Now;
    
    // 启动客户端连接线程
    TThread.CreateAnonymousThread(procedure
      var
        LClient: ISocket;
        LConnectCount: Integer;
      begin
        LConnectCount := 0;
        while (SecondsBetween(Now, LStartTime) < ATestDurationSec) and 
              (LConnectCount < AMaxConnections) do
        begin
          try
            LClient := TSocket.CreateTCP;
            LClient.Connect(TSocketAddress.Localhost(8081));
            
            // 发送一些数据
            LClient.Send(TEncoding.UTF8.GetBytes('Hello World!'));
            
            Inc(LConnectCount);
            Sleep(1); // 控制连接速度
          except
            // 忽略连接错误
          end;
        end;
      end).Start;
      
    // 主轮询循环
    while SecondsBetween(Now, LStartTime) < ATestDurationSec do
    begin
      try
        // 接受新连接
        var LNewClient := LListener.AcceptClient(10);
        if Assigned(LNewClient) then
        begin
          SetLength(LClients, Length(LClients) + 1);
          LClients[High(LClients)] := LNewClient;
          
          // 注册客户端
          LPoller.RegisterSocket(LNewClient, [seRead, seError, seClose]);
          Inc(LConnectionCount);
        end;
        
        // 轮询事件
        var LEvents := LPoller.Poll(10);
        Inc(LEventCount, LEvents);
        
        // 处理客户端数据
        for I := 0 to High(LClients) do
        begin
          if Assigned(LClients[I]) then
          begin
            try
              var LData := LClients[I].Receive(1024);
              if Length(LData) > 0 then
                LClients[I].Send(LData); // 回显
            except
              // 客户端断开
              LPoller.UnregisterSocket(LClients[I]);
              LClients[I] := nil;
            end;
          end;
        end;
        
      except
        on E: Exception do
          WriteLn('轮询错误: ', E.Message);
      end;
    end;
    
    // 获取性能指标
    LMetrics := LPoller.GetPerformanceMetrics;
    
    // 清理
    for I := 0 to High(LClients) do
    begin
      if Assigned(LClients[I]) then
        LClients[I].Close;
    end;
    
    LListener.Stop;
    
    // 计算结果
    var LElapsedSec := (Now - LStartTime) * 24 * 3600;
    
    Result.PollerType := APollerType;
    Result.MaxConnections := LConnectionCount;
    Result.ConnectionsPerSecond := LConnectionCount / LElapsedSec;
    Result.EventsPerSecond := LEventCount / LElapsedSec;
    Result.AverageLatencyMs := LMetrics.AverageLatencyMs;
    Result.MemoryUsageMB := 0; // TODO: 实现内存使用监控
    Result.TestDurationSec := LElapsedSec;
    
    WriteLn('完成测试: ', APollerType, ', 连接数: ', LConnectionCount, ', 事件数: ', LEventCount);
    
  except
    on E: Exception do
    begin
      WriteLn('测试失败: ', E.Message);
      FillChar(Result, SizeOf(Result), 0);
      Result.PollerType := APollerType + ' (失败)';
    end;
  end;
end;

procedure RunBenchmarks;
const
  MAX_CONNECTIONS = 1000;
  TEST_DURATION = 30; // 秒
var
  LAvailablePollers: TArray<string>;
  LPoller: string;
  LResult: TBenchmarkResult;
begin
  WriteLn('开始轮询器性能基准测试');
  WriteLn('最大连接数: ', MAX_CONNECTIONS);
  WriteLn('测试时长: ', TEST_DURATION, ' 秒');
  WriteLn('');
  
  LAvailablePollers := TSocketPollerFactory.GetAvailablePollers;
  
  for LPoller in LAvailablePollers do
  begin
    LResult := BenchmarkPoller(LPoller, MAX_CONNECTIONS, TEST_DURATION);
    AddResult(LResult);
    
    // 测试间隔
    WriteLn('等待5秒后进行下一个测试...');
    Sleep(5000);
  end;
end;

procedure RunScalabilityTest;
const
  CONNECTION_COUNTS: array[0..4] of Integer = (100, 500, 1000, 2000, 5000);
  TEST_DURATION = 15; // 秒
var
  LBestPoller: string;
  I: Integer;
  LResult: TBenchmarkResult;
begin
  WriteLn('');
  WriteLn('可扩展性测试');
  WriteLn('=============');
  
  LBestPoller := TSocketPollerFactory.GetRecommendedPoller;
  WriteLn('使用推荐轮询器: ', LBestPoller);
  WriteLn('');
  
  for I := 0 to High(CONNECTION_COUNTS) do
  begin
    WriteLn('测试连接数: ', CONNECTION_COUNTS[I]);
    LResult := BenchmarkPoller(LBestPoller, CONNECTION_COUNTS[I], TEST_DURATION);
    AddResult(LResult);
    
    if I < High(CONNECTION_COUNTS) then
    begin
      WriteLn('等待3秒后进行下一个测试...');
      Sleep(3000);
    end;
  end;
end;

procedure RunLatencyTest;
const
  PING_COUNT = 1000;
var
  LPoller: IAdvancedSocketPoller;
  LListener: ISocketListener;
  LClient, LServer: ISocket;
  LStartTime, LEndTime: TDateTime;
  LTotalLatency: Double;
  I: Integer;
  LData: TBytes;
begin
  WriteLn('');
  WriteLn('延迟测试');
  WriteLn('=========');
  
  LPoller := TSocketPollerFactory.CreateBest(10);
  
  try
    // 创建测试环境
    LListener := TSocketListener.ListenTCP(8082);
    LListener.Start;
    
    LClient := TSocket.CreateTCP;
    LClient.Connect(TSocketAddress.Localhost(8082));
    
    LServer := LListener.AcceptClient;
    
    // 注册到轮询器
    LPoller.RegisterSocket(LServer, [seRead]);
    
    LData := TEncoding.UTF8.GetBytes('ping');
    LTotalLatency := 0;
    
    WriteLn('执行 ', PING_COUNT, ' 次ping测试...');
    
    for I := 1 to PING_COUNT do
    begin
      LStartTime := Now;
      
      // 发送ping
      LClient.Send(LData);
      
      // 等待响应
      LPoller.Poll(1000);
      var LResponse := LServer.Receive(1024);
      
      // 回复pong
      LServer.Send(LResponse);
      LClient.Receive(1024);
      
      LEndTime := Now;
      LTotalLatency := LTotalLatency + ((LEndTime - LStartTime) * 24 * 3600 * 1000);
      
      if I mod 100 = 0 then
        Write('.');
    end;
    
    WriteLn('');
    WriteLn('平均往返延迟: ', FormatFloat('0.000', LTotalLatency / PING_COUNT), ' ms');
    
    LClient.Close;
    LServer.Close;
    LListener.Stop;
    
  except
    on E: Exception do
      WriteLn('延迟测试失败: ', E.Message);
  end;
end;

begin
  WriteLn('fafafa.core.socket 轮询器性能基准测试');
  WriteLn('=====================================');
  WriteLn('');
  
  try
    // 显示系统信息
    WriteLn('系统信息:');
    WriteLn('CPU核心数: ', GetCPUCount);
    {$IFDEF WINDOWS}
    WriteLn('操作系统: Windows');
    {$ELSEIF LINUX}
    WriteLn('操作系统: Linux');
    {$ELSEIF DARWIN}
    WriteLn('操作系统: macOS');
    {$ELSE}
    WriteLn('操作系统: 其他');
    {$ENDIF}
    WriteLn('');
    
    // 运行基准测试
    RunBenchmarks;
    
    // 运行可扩展性测试
    RunScalabilityTest;
    
    // 运行延迟测试
    RunLatencyTest;
    
    // 打印结果
    PrintResults;
    
    WriteLn('');
    WriteLn('所有测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.

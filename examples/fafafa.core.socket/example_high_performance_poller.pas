program example_high_performance_poller;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes, DateUtils,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.socket.poller;

{**
 * 高性能轮询器示例
 * 
 * 本示例展示如何使用平台特定的高性能轮询器：
 * 1. 自动选择最佳轮询器（IOCP/epoll/kqueue）
 * 2. 高并发连接处理
 * 3. 性能指标监控
 * 4. 不同轮询器的性能对比
 *}

type
  THighPerformanceServer = class
  private
    FPoller: IAdvancedSocketPoller;
    FListener: ISocketListener;
    FClients: TArray<ISocket>;
    FRunning: Boolean;
    FStartTime: TDateTime;
    FTotalConnections: Integer;
    FTotalBytesReceived: Int64;
    
    procedure OnSocketEvent(const ASocket: ISocket; AEvents: TSocketEvents);
    procedure HandleNewConnection;
    procedure HandleClientData(const AClient: ISocket);
    procedure HandleClientDisconnect(const AClient: ISocket);
    procedure AddClient(const AClient: ISocket);
    procedure RemoveClient(const AClient: ISocket);
    procedure PrintStatistics;
    
  public
    constructor Create(APort: Word; APollerType: string = '');
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    procedure Run;
  end;

constructor THighPerformanceServer.Create(APort: Word; APollerType: string);
begin
  inherited Create;
  
  // 创建高性能轮询器
  if APollerType = '' then
  begin
    FPoller := TSocketPollerFactory.CreateBest(10000);
    WriteLn('使用推荐的轮询器: ', TSocketPollerFactory.GetRecommendedPoller);
  end
  else
  begin
    if APollerType = 'select' then
      FPoller := TSocketPollerFactory.CreateSelect(1024)
    {$IFDEF WINDOWS}
    else if APollerType = 'iocp' then
      FPoller := TSocketPollerFactory.CreateIOCP(10000)
    {$ENDIF}
    {$IFDEF LINUX}
    else if APollerType = 'epoll' then
      FPoller := TSocketPollerFactory.CreateEpoll(10000)
    {$ENDIF}
    {$IFDEF DARWIN}
    else if APollerType = 'kqueue' then
      FPoller := TSocketPollerFactory.CreateKqueue(10000)
    {$ENDIF}
    else
      FPoller := TSocketPollerFactory.CreateBest(10000);
      
    WriteLn('使用指定的轮询器: ', APollerType);
  end;
  
  // 创建监听器
  FListener := TSocketListener.ListenTCP(APort);
  FListener.ReuseAddress := True;
  
  SetLength(FClients, 0);
  FRunning := False;
  FTotalConnections := 0;
  FTotalBytesReceived := 0;
  
  WriteLn('高性能服务器创建完成');
  WriteLn('轮询器类型: ', FPoller.GetPollerType);
  WriteLn('最大Socket数: ', FPoller.GetMaxSockets);
  WriteLn('高性能模式: ', IfThen(FPoller.IsHighPerformance, '是', '否'));
end;

destructor THighPerformanceServer.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure THighPerformanceServer.Start;
begin
  if FRunning then Exit;
  
  try
    // 启动监听
    FListener.Start;
    WriteLn('服务器开始监听端口 ', FListener.LocalAddress.Port, '...');
    
    // 配置高性能选项
    {$IFDEF LINUX}
    if FPoller.GetPollerType = 'epoll' then
    begin
      FPoller.SetEdgeTriggered(True);  // 启用边缘触发模式
      WriteLn('已启用epoll边缘触发模式');
    end;
    {$ENDIF}
    
    FPoller.SetMaxEvents(1024);  // 设置最大事件数
    
    // 注册监听器到轮询器
    FPoller.RegisterSocket(FListener as ISocket, [seRead], @OnSocketEvent);
    
    FRunning := True;
    FStartTime := Now;
    WriteLn('高性能轮询器已启动');
    
  except
    on E: Exception do
    begin
      WriteLn('启动服务器失败: ', E.Message);
      raise;
    end;
  end;
end;

procedure THighPerformanceServer.Stop;
var
  I: Integer;
begin
  if not FRunning then Exit;
  
  FRunning := False;
  
  // 停止轮询器
  FPoller.Stop;
  
  // 关闭所有客户端连接
  for I := 0 to High(FClients) do
    FClients[I].Close;
  SetLength(FClients, 0);
  
  // 停止监听器
  FListener.Stop;
  
  WriteLn('高性能服务器已停止');
  PrintStatistics;
end;

procedure THighPerformanceServer.Run;
var
  LEventCount: Integer;
  LLastStatsTime: TDateTime;
begin
  WriteLn('高性能服务器运行中，按 Ctrl+C 停止...');
  WriteLn('');
  
  LLastStatsTime := Now;
  
  while FRunning do
  begin
    try
      // 高性能轮询，超时100ms
      LEventCount := FPoller.Poll(100);
      
      // 每5秒打印一次统计信息
      if SecondsBetween(Now, LLastStatsTime) >= 5 then
      begin
        PrintStatistics;
        LLastStatsTime := Now;
      end;
      
    except
      on E: Exception do
      begin
        WriteLn('轮询错误: ', E.Message);
        Break;
      end;
    end;
  end;
end;

procedure THighPerformanceServer.OnSocketEvent(const ASocket: ISocket; AEvents: TSocketEvents);
begin
  try
    // 检查是否是监听器的事件（新连接）
    if ASocket = (FListener as ISocket) then
    begin
      if seRead in AEvents then
        HandleNewConnection;
    end
    else
    begin
      // 客户端Socket事件
      if seRead in AEvents then
        HandleClientData(ASocket);
        
      if (seError in AEvents) or (seClose in AEvents) then
        HandleClientDisconnect(ASocket);
    end;
    
  except
    on E: Exception do
      WriteLn('处理Socket事件时出错: ', E.Message);
  end;
end;

procedure THighPerformanceServer.HandleNewConnection;
var
  LClient: ISocket;
begin
  try
    // 接受新连接
    LClient := FListener.AcceptClient;
    if Assigned(LClient) then
    begin
      Inc(FTotalConnections);
      
      // 设置非阻塞模式
      LClient.NonBlocking := True;
      
      // 添加到客户端列表
      AddClient(LClient);
      
      // 注册客户端的读写事件
      FPoller.RegisterSocket(LClient, [seRead, seError, seClose], @OnSocketEvent);
      
      if FTotalConnections mod 100 = 0 then
        WriteLn('已接受 ', FTotalConnections, ' 个连接，当前活跃: ', Length(FClients));
    end;
    
  except
    on E: Exception do
      WriteLn('处理新连接时出错: ', E.Message);
  end;
end;

procedure THighPerformanceServer.HandleClientData(const AClient: ISocket);
var
  LData: TBytes;
  LErrorCode: Integer;
  LBytesReceived: Integer;
begin
  try
    // 非阻塞接收数据
    SetLength(LData, 4096);
    LBytesReceived := AClient.TryReceive(@LData[0], Length(LData), LErrorCode);
    
    if LBytesReceived > 0 then
    begin
      Inc(FTotalBytesReceived, LBytesReceived);
      
      // 简单回显（在实际应用中可能需要缓冲）
      SetLength(LData, LBytesReceived);
      AClient.Send(LData);
    end
    else if LBytesReceived = 0 then
    begin
      // 连接已关闭
      HandleClientDisconnect(AClient);
    end
    else if LErrorCode <> {$IFDEF WINDOWS}WSAEWOULDBLOCK{$ELSE}EWOULDBLOCK{$ENDIF} then
    begin
      // 其他错误
      HandleClientDisconnect(AClient);
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('处理客户端数据时出错: ', E.Message);
      HandleClientDisconnect(AClient);
    end;
  end;
end;

procedure THighPerformanceServer.HandleClientDisconnect(const AClient: ISocket);
begin
  try
    // 从轮询器中移除
    FPoller.UnregisterSocket(AClient);
    
    // 从客户端列表中移除
    RemoveClient(AClient);
    
    // 关闭连接
    AClient.Close;
    
  except
    on E: Exception do
      WriteLn('处理客户端断开时出错: ', E.Message);
  end;
end;

procedure THighPerformanceServer.AddClient(const AClient: ISocket);
begin
  SetLength(FClients, Length(FClients) + 1);
  FClients[High(FClients)] := AClient;
end;

procedure THighPerformanceServer.RemoveClient(const AClient: ISocket);
var
  I, J: Integer;
begin
  for I := 0 to High(FClients) do
  begin
    if FClients[I] = AClient then
    begin
      for J := I to High(FClients) - 1 do
        FClients[J] := FClients[J + 1];
      SetLength(FClients, Length(FClients) - 1);
      Break;
    end;
  end;
end;

procedure THighPerformanceServer.PrintStatistics;
var
  LMetrics: TPollerMetrics;
  LElapsedSec: Double;
  LConnectionsPerSec: Double;
  LThroughputMBps: Double;
begin
  LMetrics := FPoller.GetPerformanceMetrics;
  LElapsedSec := (Now - FStartTime) * 24 * 3600;
  
  if LElapsedSec > 0 then
  begin
    LConnectionsPerSec := FTotalConnections / LElapsedSec;
    LThroughputMBps := (FTotalBytesReceived / 1024 / 1024) / LElapsedSec;
  end
  else
  begin
    LConnectionsPerSec := 0;
    LThroughputMBps := 0;
  end;
  
  WriteLn('=== 性能统计 ===');
  WriteLn('轮询器: ', LMetrics.PollerType);
  WriteLn('运行时间: ', FormatFloat('0.0', LElapsedSec), ' 秒');
  WriteLn('总连接数: ', FTotalConnections);
  WriteLn('当前活跃连接: ', Length(FClients));
  WriteLn('最大并发连接: ', LMetrics.MaxConcurrentSockets);
  WriteLn('连接/秒: ', FormatFloat('0.00', LConnectionsPerSec));
  WriteLn('总事件数: ', LMetrics.TotalEvents);
  WriteLn('事件/秒: ', FormatFloat('0.00', LMetrics.EventsPerSecond));
  WriteLn('平均延迟: ', FormatFloat('0.00', LMetrics.AverageLatencyMs), ' ms');
  WriteLn('总接收数据: ', FormatFloat('0.00', FTotalBytesReceived / 1024 / 1024), ' MB');
  WriteLn('吞吐量: ', FormatFloat('0.00', LThroughputMBps), ' MB/s');
  WriteLn('================');
  WriteLn('');
end;

var
  LServer: THighPerformanceServer;
  LPollerType: string;

begin
  WriteLn('fafafa.core.socket 高性能轮询器示例');
  WriteLn('=====================================');
  WriteLn('');
  
  // 显示可用的轮询器
  WriteLn('可用的轮询器类型:');
  var LAvailable := TSocketPollerFactory.GetAvailablePollers;
  for var LType in LAvailable do
    WriteLn('  - ', LType);
  WriteLn('推荐的轮询器: ', TSocketPollerFactory.GetRecommendedPoller);
  WriteLn('');
  
  // 获取轮询器类型参数
  if ParamCount > 0 then
    LPollerType := ParamStr(1)
  else
    LPollerType := '';
    
  try
    LServer := THighPerformanceServer.Create(8080, LPollerType);
    try
      LServer.Start;
      LServer.Run;
    finally
      LServer.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('程序结束');
end.

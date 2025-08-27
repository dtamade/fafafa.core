program example_event_polling;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.socket;

{**
 * 事件轮询示例
 * 
 * 本示例展示如何使用事件轮询器进行高效的网络编程：
 * 1. 创建事件轮询器
 * 2. 注册Socket事件监听
 * 3. 处理多个并发连接
 * 4. 事件驱动的数据处理
 *}

type
  TEventDrivenServer = class
  private
    FPoller: ISocketPoller;
    FListener: ISocketListener;
    FClients: array of ISocket;
    FRunning: Boolean;
    
    procedure OnSocketEvent(const ASocket: ISocket; AEvents: TSocketEvents);
    procedure HandleNewConnection;
    procedure HandleClientData(const AClient: ISocket);
    procedure HandleClientDisconnect(const AClient: ISocket);
    procedure AddClient(const AClient: ISocket);
    procedure RemoveClient(const AClient: ISocket);
    
  public
    constructor Create(APort: Word);
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    procedure Run;
  end;

constructor TEventDrivenServer.Create(APort: Word);
begin
  inherited Create;
  
  // 创建事件轮询器（跨平台默认实现）
  FPoller := CreateDefaultPoller;
  
  // 创建监听器
  FListener := TSocketListener.ListenTCP(APort);
  FListener.ReuseAddress := True;
  
  SetLength(FClients, 0);
  FRunning := False;
  
  WriteLn('事件驱动服务器创建完成，端口: ', APort);
end;

destructor TEventDrivenServer.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TEventDrivenServer.Start;
begin
  if FRunning then Exit;
  
  try
    // 启动监听
    FListener.Start;
    WriteLn('服务器开始监听...');
    
    // 注册监听器的读事件（新连接）
    FPoller.RegisterSocket(FListener as ISocket, [seRead], @OnSocketEvent);
    
    FRunning := True;
    WriteLn('事件轮询器已启动');
    
  except
    on E: Exception do
    begin
      WriteLn('启动服务器失败: ', E.Message);
      raise;
    end;
  end;
end;

procedure TEventDrivenServer.Stop;
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
  
  WriteLn('服务器已停止');
end;

procedure TEventDrivenServer.Run;
var
  LEventCount: Integer;
  LResults: TSocketPollResults;
  I: Integer;
begin
  WriteLn('服务器运行中，按 Ctrl+C 停止...');
  WriteLn('统计信息: ', FPoller.GetStatistics);
  
  while FRunning do
  begin
    try
      // 轮询事件，超时1秒
      LEventCount := FPoller.Poll(1000);
      
      if LEventCount > 0 then
      begin
        WriteLn('检测到 ', LEventCount, ' 个事件');
        
        // 获取就绪事件（如果需要手动处理）
        LResults := FPoller.GetReadyEvents;
        for I := 0 to High(LResults) do
        begin
          WriteLn('Socket事件: ', 
            IfThen(seRead in LResults[I].Events, 'READ ', ''),
            IfThen(seWrite in LResults[I].Events, 'WRITE ', ''),
            IfThen(seError in LResults[I].Events, 'ERROR ', ''),
            IfThen(seClose in LResults[I].Events, 'CLOSE ', ''));
        end;
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

procedure TEventDrivenServer.OnSocketEvent(const ASocket: ISocket; AEvents: TSocketEvents);
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

procedure TEventDrivenServer.HandleNewConnection;
var
  LClient: ISocket;
begin
  try
    // 接受新连接
    LClient := FListener.AcceptClient;
    if Assigned(LClient) then
    begin
      WriteLn('新客户端连接: ', LClient.RemoteAddress.ToString);
      
      // 设置非阻塞模式
      LClient.NonBlocking := True;
      
      // 添加到客户端列表
      AddClient(LClient);
      
      // 注册客户端的读写事件
      FPoller.RegisterSocket(LClient, [seRead, seError, seClose], @OnSocketEvent);
      
      // 发送欢迎消息
      var LWelcome := TEncoding.UTF8.GetBytes('欢迎连接到事件驱动服务器！' + #13#10);
      LClient.Send(LWelcome);
      
      WriteLn('客户端已注册到事件轮询器，当前客户端数: ', Length(FClients));
    end;
    
  except
    on E: Exception do
      WriteLn('处理新连接时出错: ', E.Message);
  end;
end;

procedure TEventDrivenServer.HandleClientData(const AClient: ISocket);
var
  LData: TBytes;
  LMessage: string;
  LResponse: TBytes;
  LErrorCode: Integer;
  LBytesReceived: Integer;
begin
  try
    // 非阻塞接收数据
    SetLength(LData, 1024);
    LBytesReceived := AClient.TryReceive(@LData[0], Length(LData), LErrorCode);
    
    if LBytesReceived > 0 then
    begin
      SetLength(LData, LBytesReceived);
      LMessage := TEncoding.UTF8.GetString(LData);
      WriteLn('收到客户端数据: ', Trim(LMessage));
      
      // 回显消息
      LResponse := TEncoding.UTF8.GetBytes('回显: ' + LMessage);
      AClient.Send(LResponse);
    end
    else if LBytesReceived = 0 then
    begin
      // 连接已关闭
      WriteLn('客户端连接已关闭');
      HandleClientDisconnect(AClient);
    end
    else if LErrorCode <> {$IFDEF WINDOWS}WSAEWOULDBLOCK{$ELSE}EWOULDBLOCK{$ENDIF} then
    begin
      // 其他错误
      WriteLn('接收数据错误: ', LErrorCode);
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

procedure TEventDrivenServer.HandleClientDisconnect(const AClient: ISocket);
begin
  try
    WriteLn('客户端断开连接: ', AClient.RemoteAddress.ToString);
    
    // 从轮询器中移除
    FPoller.UnregisterSocket(AClient);
    
    // 从客户端列表中移除
    RemoveClient(AClient);
    
    // 关闭连接
    AClient.Close;
    
    WriteLn('客户端已清理，当前客户端数: ', Length(FClients));
    
  except
    on E: Exception do
      WriteLn('处理客户端断开时出错: ', E.Message);
  end;
end;

procedure TEventDrivenServer.AddClient(const AClient: ISocket);
begin
  SetLength(FClients, Length(FClients) + 1);
  FClients[High(FClients)] := AClient;
end;

procedure TEventDrivenServer.RemoveClient(const AClient: ISocket);
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

var
  LServer: TEventDrivenServer;

begin
  WriteLn('fafafa.core.socket 事件轮询示例');
  WriteLn('=====================================');
  WriteLn('');
  
  try
    LServer := TEventDrivenServer.Create(8080);
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

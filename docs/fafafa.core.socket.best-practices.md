# fafafa.core.socket 最佳实践指南

## 📋 概述

本文档提供使用 `fafafa.core.socket` 模块的最佳实践建议，帮助开发者编写高质量、高性能的网络应用程序。

## 🎯 设计原则

### 1. 接口优先
```pascal
// ✅ 推荐：使用接口类型
procedure ProcessSocket(const ASocket: ISocket);
begin
  // 处理逻辑...
end;

// ❌ 不推荐：直接使用具体类
procedure ProcessSocket(ASocket: TSocket);
begin
  // 处理逻辑...
end;
```

### 2. 资源管理
```pascal
// ✅ 推荐：使用 try-finally 确保资源释放
var
  LSocket: ISocket;
begin
  LSocket := TSocket.CreateTCP;
  try
    LSocket.Connect(LAddress);
    // 使用 socket...
  finally
    if Assigned(LSocket) then
      LSocket.Close;
  end;
end;

// ✅ 更好：接口自动管理生命周期
var
  LSocket: ISocket;
begin
  LSocket := TSocket.CreateTCP;
  LSocket.Connect(LAddress);
  // 使用 socket...
  // 接口会自动释放资源
end;
```

### 3. 错误处理
```pascal
// ✅ 推荐：细粒度异常处理
try
  LSocket.Connect(LAddress);
except
  on E: ESocketConnectError do
  begin
    WriteLn('连接失败: ', E.GetDetailedMessage);
    // 特定的连接错误处理
  end;
  on E: ESocketError do
  begin
    WriteLn('Socket 错误: ', E.Message);
    // 通用 Socket 错误处理
  end;
end;
```

## 🚀 性能最佳实践

### 1. 缓冲区管理
```pascal
// ✅ 推荐：预分配缓冲区
var
  LBuffer: TBytes;
  LReceived: Integer;
begin
  SetLength(LBuffer, 8192);  // 预分配 8KB
  
  while True do
  begin
    LReceived := LSocket.Receive(@LBuffer[0], Length(LBuffer));
    if LReceived > 0 then
    begin
      // 处理接收到的数据
      ProcessData(@LBuffer[0], LReceived);
    end;
  end;
end;

// ❌ 不推荐：频繁分配
while True do
begin
  LData := LSocket.Receive(8192);  // 每次都分配新的 TBytes
  ProcessData(LData);
end;
```

### 2. 批量操作
```pascal
// ✅ 推荐：批量发送
{$IFDEF FAFAFA_SOCKET_ADVANCED}
var
  LAllData: TBytes;
begin
  // 合并多个小数据包
  LAllData := CombineData([LHeader, LBody, LFooter]);
  LSocket.SendAll(LAllData);
end;
{$ENDIF}

// ❌ 不推荐：多次小数据发送
LSocket.Send(LHeader);
LSocket.Send(LBody);
LSocket.Send(LFooter);
```

### 3. 非阻塞 I/O
```pascal
// ✅ 推荐：使用 Try* 方法
var
  LErrorCode: Integer;
  LResult: Integer;
begin
  LSocket.NonBlocking := True;
  
  LResult := LSocket.TrySend(@LData[0], Length(LData), LErrorCode);
  if LResult = -1 then
  begin
    case LErrorCode of
      SOCKET_EWOULDBLOCK: 
        // 缓冲区满，稍后重试
        AddToSendQueue(LData);
      else
        // 其他错误
        HandleError(LErrorCode);
    end;
  end;
end;
```

## 🌐 网络编程模式

### 1. 客户端模式
```pascal
// 简单客户端
function CreateSimpleClient(const AHost: string; APort: Word): ISocket;
begin
  Result := TSocket.CreateTCP;
  Result.ReuseAddress := True;
  Result.TcpNoDelay := True;
  Result.SendTimeout := 5000;
  Result.ReceiveTimeout := 5000;
  
  Result.Connect(TSocketAddress.IPv4(AHost, APort));
end;

// 使用示例
var
  LClient: ISocket;
  LResponse: TBytes;
begin
  LClient := CreateSimpleClient('127.0.0.1', 8080);
  try
    LClient.Send(TEncoding.UTF8.GetBytes('Hello Server'));
    LResponse := LClient.Receive(1024);
    WriteLn('服务器回复: ', TEncoding.UTF8.GetString(LResponse));
  finally
    LClient.Close;
  end;
end;
```

### 2. 服务器模式
```pascal
// 简单服务器
procedure RunSimpleServer(APort: Word);
var
  LListener: ISocketListener;
  LClient: ISocket;
  LData: TBytes;
begin
  LListener := TSocketListener.ListenTCP(APort);
  LListener.Backlog := 128;
  LListener.Start;
  
  WriteLn('服务器启动，监听端口: ', APort);
  
  while True do
  begin
    LClient := LListener.Accept;
    if Assigned(LClient) then
    begin
      try
        LData := LClient.Receive(1024);
        if Length(LData) > 0 then
        begin
          WriteLn('收到数据: ', TEncoding.UTF8.GetString(LData));
          LClient.Send(TEncoding.UTF8.GetBytes('Echo: ' + TEncoding.UTF8.GetString(LData)));
        end;
      finally
        LClient.Close;
      end;
    end;
  end;
end;
```

### 3. 多线程服务器
```pascal
// 多线程服务器
procedure RunMultiThreadServer(APort: Word);
var
  LListener: ISocketListener;
  LClient: ISocket;
begin
  LListener := TSocketListener.ListenTCP(APort);
  LListener.Start;
  
  while True do
  begin
    LClient := LListener.Accept;
    if Assigned(LClient) then
    begin
      // 为每个客户端创建独立线程
      TThread.CreateAnonymousThread(
        procedure
        begin
          HandleClientInThread(LClient);
        end).Start;
    end;
  end;
end;

procedure HandleClientInThread(const AClient: ISocket);
var
  LData: TBytes;
begin
  try
    while AClient.Connected do
    begin
      LData := AClient.Receive(1024);
      if Length(LData) > 0 then
      begin
        // 处理客户端数据
        ProcessClientData(AClient, LData);
      end
      else
        Break; // 客户端断开连接
    end;
  finally
    AClient.Close;
  end;
end;
```

## 🔧 配置建议

### 1. 开发环境配置
```pascal
// 开发环境：启用详细日志和调试
{$IFDEF DEBUG}
LSocket.SendTimeout := 30000;    // 30秒，便于调试
LSocket.ReceiveTimeout := 30000; // 30秒，便于调试
{$ELSE}
LSocket.SendTimeout := 5000;     // 5秒，生产环境
LSocket.ReceiveTimeout := 5000;  // 5秒，生产环境
{$ENDIF}
```

### 2. 生产环境配置
```pascal
// 生产环境：优化性能和稳定性
LSocket.ReuseAddress := True;
LSocket.KeepAlive := True;
LSocket.TcpNoDelay := True;
LSocket.SendBufferSize := 65536;    // 64KB
LSocket.ReceiveBufferSize := 65536; // 64KB
```

### 3. 高并发配置
```pascal
// 高并发场景
LListener.Backlog := 1024;  // 增加监听队列
LSocket.ReusePort := True;  // Linux 支持端口重用
```

## 📊 监控和诊断

### 1. 性能监控
```pascal
{$IFDEF FAFAFA_SOCKET_ADVANCED}
// 获取 Socket 统计信息
var
  LStats: TSocketStatistics;
begin
  LStats := LSocket.GetStatistics;
  WriteLn('发送字节数: ', LStats.BytesSent);
  WriteLn('接收字节数: ', LStats.BytesReceived);
  WriteLn('错误次数: ', LStats.ErrorCount);
end;
{$ENDIF}
```

### 2. 诊断信息
```pascal
{$IFDEF FAFAFA_SOCKET_ADVANCED}
// 获取诊断信息
WriteLn('Socket 诊断信息:');
WriteLn(LSocket.GetDiagnosticInfo);
{$ENDIF}
```

## ⚠️ 常见陷阱

### 1. 忘记设置超时
```pascal
// ❌ 危险：可能无限阻塞
LSocket.Connect(LAddress);

// ✅ 安全：设置合理超时
LSocket.SendTimeout := 5000;
LSocket.ReceiveTimeout := 5000;
LSocket.Connect(LAddress);
```

### 2. 不处理部分发送/接收
```pascal
// ❌ 错误：假设一次发送完成
LSocket.Send(LLargeData);

// ✅ 正确：处理部分发送
{$IFDEF FAFAFA_SOCKET_ADVANCED}
LSocket.SendAll(LLargeData);
{$ELSE}
// 手动循环发送
var
  LSent, LTotal: Integer;
begin
  LTotal := 0;
  while LTotal < Length(LLargeData) do
  begin
    LSent := LSocket.Send(@LLargeData[LTotal], Length(LLargeData) - LTotal);
    Inc(LTotal, LSent);
  end;
end;
{$ENDIF}
```

### 3. 混用阻塞和非阻塞模式
```pascal
// ❌ 错误：模式不一致
LSocket.NonBlocking := True;
LSocket.Send(LData);  // 可能抛异常

// ✅ 正确：使用对应的方法
LSocket.NonBlocking := True;
LResult := LSocket.TrySend(@LData[0], Length(LData), LErrorCode);
```

---

*遵循这些最佳实践，可以帮助您构建稳定、高性能的网络应用程序。*

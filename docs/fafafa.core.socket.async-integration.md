# fafafa.core.socket 异步集成设计

## 📋 概述

本文档描述了 `fafafa.core.socket` 模块与 `fafafa.core.async` 模块的集成设计，旨在提供高性能的异步网络编程能力。

## 🎯 设计目标

1. **无缝集成**：与现有同步API保持兼容，异步API作为扩展
2. **高性能**：基于事件轮询，支持大量并发连接
3. **易用性**：提供直观的异步编程模型
4. **跨平台**：支持 Windows (IOCP)、Linux (epoll)、BSD/macOS (kqueue)
5. **可扩展**：为未来的协议支持（HTTP/2、WebSocket等）做准备

## 🏗️ 架构设计

### 核心组件

```
┌─────────────────────────────────────────────────────────────┐
│                    fafafa.core.async                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   IAsyncResult  │  │  IAsyncRuntime  │  │  IAsyncTask  │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                 fafafa.core.socket (异步扩展)                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │  IAsyncSocket   │  │ ISocketPoller   │  │ IAsyncResult │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│              fafafa.core.socket (现有同步API)                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │    ISocket      │  │ ISocketAddress  │  │ISocketListener│ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 事件轮询层次

```
┌─────────────────────────────────────────────────────────────┐
│                    应用层异步API                            │
│  ConnectAsync, SendAsync, ReceiveAsync, AcceptAsync         │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                   事件轮询抽象层                            │
│              ISocketPoller (跨平台接口)                     │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                  平台特定实现层                             │
│  Windows: IOCP  │  Linux: epoll  │  BSD/macOS: kqueue      │
│  通用: select   │                │                         │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 接口设计

### IAsyncSocket 接口

```pascal
type IAsyncSocket = interface(ISocket)
  ['{D0A7F4C3-6E5F-4A4B-9C3D-0E9F8A7B6C5D}']
  
  // 异步连接
  function ConnectAsync(const AAddress: ISocketAddress): IAsyncResult<Boolean>;
  function ConnectAsync(const AAddress: ISocketAddress; ATimeoutMs: Integer): IAsyncResult<Boolean>;
  
  // 异步数据传输
  function SendAsync(const AData: TBytes): IAsyncResult<Integer>;
  function SendAsync(AData: Pointer; ASize: Integer): IAsyncResult<Integer>;
  function ReceiveAsync(AMaxSize: Integer): IAsyncResult<TBytes>;
  function ReceiveAsync(ABuffer: Pointer; ASize: Integer): IAsyncResult<Integer>;
  
  // 批量异步操作
  function SendAllAsync(const AData: TBytes): IAsyncResult<Integer>;
  function ReceiveExactAsync(ASize: Integer): IAsyncResult<TBytes>;
  
  // 事件轮询器集成
  procedure SetPoller(const APoller: ISocketPoller);
  function GetPoller: ISocketPoller;
  
  // 异步回调
  procedure OnConnected(ACallback: TProc<Boolean>);
  procedure OnDataReceived(ACallback: TProc<TBytes>);
  procedure OnDisconnected(ACallback: TProc);
  procedure OnError(ACallback: TProc<Exception>);
end;
```

### IAsyncSocketListener 接口

```pascal
type IAsyncSocketListener = interface(ISocketListener)
  ['{E1B8F5D4-7F6A-4B5C-8D3E-1F0A9B8C7D6E}']
  
  // 异步接受连接
  function AcceptAsync: IAsyncResult<IAsyncSocket>;
  function AcceptAsync(ATimeoutMs: Integer): IAsyncResult<IAsyncSocket>;
  
  // 批量接受
  function AcceptMultipleAsync(AMaxCount: Integer): IAsyncResult<TArray<IAsyncSocket>>;
  
  // 事件回调
  procedure OnClientConnected(ACallback: TProc<IAsyncSocket>);
  procedure OnError(ACallback: TProc<Exception>);
end;
```

### 高性能事件轮询器

```pascal
type IAdvancedSocketPoller = interface(ISocketPoller)
  ['{F2C9G6E5-8A7B-5C6D-9E4F-2A1B0C9D8E7F}']
  
  // 批量操作
  function RegisterMultiple(const ASockets: TArray<ISocket>; AEvents: TSocketEvents): Integer;
  function PollBatch(ATimeoutMs: Integer; AMaxEvents: Integer): TSocketPollResults;
  
  // 性能优化
  procedure SetEdgeTriggered(AEnabled: Boolean);  // epoll ET模式
  procedure SetOneShot(AEnabled: Boolean);        // epoll ONESHOT模式
  
  // 统计和监控
  function GetPerformanceMetrics: TPollerMetrics;
  procedure ResetMetrics;
end;

type TPollerMetrics = record
  TotalEvents: Int64;
  EventsPerSecond: Double;
  AverageLatencyMs: Double;
  RegisteredSockets: Integer;
  MaxConcurrentSockets: Integer;
end;
```

## 🚀 使用示例

### 异步客户端

```pascal
procedure AsyncClientExample;
var
  LSocket: IAsyncSocket;
  LConnectResult: IAsyncResult<Boolean>;
  LSendResult: IAsyncResult<Integer>;
  LReceiveResult: IAsyncResult<TBytes>;
begin
  // 创建异步Socket
  LSocket := TAsyncSocket.CreateTCP;
  
  // 异步连接
  LConnectResult := LSocket.ConnectAsync(TSocketAddress.Create('example.com', 80));
  LConnectResult.OnComplete := procedure(AConnected: Boolean)
    begin
      if AConnected then
      begin
        WriteLn('连接成功');
        
        // 异步发送数据
        LSendResult := LSocket.SendAsync(TEncoding.UTF8.GetBytes('GET / HTTP/1.1'#13#10#13#10));
        LSendResult.OnComplete := procedure(ABytesSent: Integer)
          begin
            WriteLn('发送了 ', ABytesSent, ' 字节');
            
            // 异步接收响应
            LReceiveResult := LSocket.ReceiveAsync(4096);
            LReceiveResult.OnComplete := procedure(AData: TBytes)
              begin
                WriteLn('收到响应: ', TEncoding.UTF8.GetString(AData));
                LSocket.Close;
              end;
          end;
      end
      else
        WriteLn('连接失败');
    end;
end;
```

### 异步服务器

```pascal
type TAsyncServer = class
private
  FListener: IAsyncSocketListener;
  FPoller: IAdvancedSocketPoller;
  
  procedure OnClientConnected(const AClient: IAsyncSocket);
  procedure OnClientData(const AClient: IAsyncSocket; const AData: TBytes);
  
public
  procedure Start(APort: Word);
  procedure Stop;
end;

procedure TAsyncServer.Start(APort: Word);
begin
  // 创建高性能轮询器
  FPoller := TIOCPSocketPoller.Create(10000);  // Windows
  // FPoller := TEpollSocketPoller.Create(10000);  // Linux
  
  // 创建异步监听器
  FListener := TAsyncSocketListener.Create(TSocketAddress.Any(APort));
  FListener.SetPoller(FPoller);
  
  // 设置回调
  FListener.OnClientConnected := @OnClientConnected;
  
  // 开始监听
  FListener.Start;
  
  WriteLn('异步服务器启动在端口 ', APort);
end;

procedure TAsyncServer.OnClientConnected(const AClient: IAsyncSocket);
begin
  WriteLn('新客户端连接: ', AClient.RemoteAddress.ToString);
  
  // 设置数据接收回调
  AClient.OnDataReceived := procedure(const AData: TBytes)
    begin
      OnClientData(AClient, AData);
    end;
    
  // 设置断开连接回调
  AClient.OnDisconnected := procedure
    begin
      WriteLn('客户端断开: ', AClient.RemoteAddress.ToString);
    end;
end;

procedure TAsyncServer.OnClientData(const AClient: IAsyncSocket; const AData: TBytes);
var
  LResponse: TBytes;
begin
  WriteLn('收到数据: ', TEncoding.UTF8.GetString(AData));
  
  // 异步回显
  LResponse := TEncoding.UTF8.GetBytes('Echo: ' + TEncoding.UTF8.GetString(AData));
  AClient.SendAsync(LResponse).OnComplete := procedure(ABytesSent: Integer)
    begin
      WriteLn('回显了 ', ABytesSent, ' 字节');
    end;
end;
```

## 🔄 集成策略

### 阶段1：基础异步支持
1. 实现 `IAsyncResult<T>` 接口
2. 扩展现有Socket类支持异步操作
3. 基于select的基础事件轮询器

### 阶段2：平台优化
1. Windows IOCP 实现
2. Linux epoll 实现
3. BSD/macOS kqueue 实现

### 阶段3：高级功能
1. 连接池异步支持
2. SSL/TLS 异步支持
3. HTTP/WebSocket 异步支持

## 📊 性能目标

- **并发连接数**：单进程支持 10,000+ 并发连接
- **吞吐量**：在千兆网络上达到线速传输
- **延迟**：事件响应延迟 < 1ms
- **内存效率**：每连接内存开销 < 4KB
- **CPU效率**：在高并发下CPU使用率 < 80%

## 🧪 测试策略

### 单元测试
- 异步操作的正确性测试
- 错误处理和异常传播测试
- 内存泄漏和资源清理测试

### 集成测试
- 与 fafafa.core.async 模块的集成测试
- 跨平台兼容性测试
- 性能回归测试

### 压力测试
- 大量并发连接测试
- 长时间运行稳定性测试
- 内存和CPU使用率监控

## 🔮 未来扩展

1. **协议支持**：HTTP/2、WebSocket、QUIC
2. **负载均衡**：多进程/多线程负载均衡
3. **服务发现**：与微服务架构集成
4. **监控集成**：性能指标和健康检查
5. **云原生支持**：容器化和Kubernetes集成

---

*本设计文档将随着实现进展持续更新和完善。*

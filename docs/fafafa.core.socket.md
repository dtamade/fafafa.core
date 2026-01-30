# fafafa.core.socket 模块文档

> Windows IPv6 注意事项（默认使用 IPv4，IPv6 为可选）
>
> - 示例与脚手架默认走 IPv4，避免本机策略/防火墙对 IPv6 回环造成干扰
> - 如需启用 IPv6：服务器使用 `--ipv6 --bind-host=::1`，客户端使用 `--ipv6 --host=::1`
> - 首次运行注意放行防火墙；若遇超时，请参见文末“IPv6 常见问题排查（Windows）”


## 📋 模块概述

`fafafa.core.socket` 是 fafafa.core 框架中的网络通信基础模块，提供跨平台的 Socket 编程接口。该模块封装了底层的 BSD Socket API，提供类型安全、面向对象的网络编程体验。

### 🎯 设计目标

- **跨平台兼容**: 统一的 API 接口，支持 Windows 和 Unix/Linux 平台
- **类型安全**: 强类型的地址、协议和选项定义，避免魔法数字
- **接口驱动**: 基于接口的设计，支持依赖注入和单元测试
- **现代化**: 借鉴 Rust、Go、Java 等现代语言的网络库设计理念
- **易用性**: 提供高级封装，简化常见网络编程任务

### 🏗️ 架构设计

```
fafafa.core.socket
├── 接口层 (Interfaces)
│   ├── ISocketAddress    # 地址抽象
│   ├── ISocket          # Socket 核心接口
│   └── ISocketListener  # 服务器监听器接口
├── 实现层 (Implementations)
│   ├── TSocketAddress   # 地址实现类
│   ├── TSocket         # Socket 实现类
│   └── TSocketListener # 监听器实现类
└── 平台层 (Platform)
    ├── Windows 实现     # Windows 特定代码
    └── Unix/Linux 实现  # Unix/Linux 特定代码
```

## 🔧 核心接口

### ISocketAddress - 网络地址接口

网络地址的抽象接口，支持 IPv4、IPv6 和 Unix 域套接字地址。

```pascal
ISocketAddress = interface(IInterface)
  // 基本属性
  function GetFamily: TAddressFamily;
  function GetHost: string;
  function GetPort: Word;
  function GetSize: Integer;

  // 转换方法
  function ToString: string;
  function ToNativeAddr: Pointer;
  procedure FromNativeAddr(aAddr: Pointer; aSize: Integer);

  // 验证方法
  function IsValid: Boolean;
  procedure Validate;
end;
```

**工厂方法**:
- `TSocketAddress.CreateIPv4(host, port)` - 创建 IPv4 地址
- `TSocketAddress.CreateIPv6(host, port)` - 创建 IPv6 地址
- `TSocketAddress.CreateUnix(path)` - 创建 Unix 域套接字地址

**便捷工厂方法**:
- `TSocketAddress.IPv4(host, port)` - 简洁的 IPv4 地址创建
- `TSocketAddress.IPv6(host, port)` - 简洁的 IPv6 地址创建
- `TSocketAddress.Localhost(port)` - 本地回环地址 (127.0.0.1)
- `TSocketAddress.LocalhostIPv6(port)` - IPv6 本地回环地址 (::1)
- `TSocketAddress.Any(port)` - 任意 IPv4 地址 (0.0.0.0) - 服务器绑定
- `TSocketAddress.AnyIPv6(port)` - 任意 IPv6 地址 (::) - 服务器绑定

### ISocket - Socket 核心接口

Socket 的核心操作接口，提供完整的网络通信功能。

```pascal
ISocket = interface(IInterface)
  // 生命周期管理
  procedure Bind(const aAddress: ISocketAddress);
  procedure Listen(aBacklog: Integer = 128);
  function Accept: ISocket;
  procedure Connect(const aAddress: ISocketAddress);
  procedure Shutdown(aHow: TShutdownMode);
  procedure Close;

  // 数据传输
  function Send(const aData: TBytes): Integer;
  function Receive(aMaxSize: Integer = 4096): TBytes;
  function SendTo(const aData: TBytes; const aAddress: ISocketAddress): Integer;
  function ReceiveFrom(aMaxSize: Integer; out aFromAddress: ISocketAddress): TBytes;

  // 状态查询
  function GetState: TSocketState;
  function IsValid: Boolean;
  function IsConnected: Boolean;
  function IsListening: Boolean;
  function IsClosed: Boolean;

  // Socket 选项
  property ReuseAddress: Boolean read GetReuseAddress write SetReuseAddress;
  property KeepAlive: Boolean read GetKeepAlive write SetKeepAlive;
  property TcpNoDelay: Boolean read GetTcpNoDelay write SetTcpNoDelay;
  property SendTimeout: Integer read GetSendTimeout write SetSendTimeout;
  property ReceiveTimeout: Integer read GetReceiveTimeout write SetReceiveTimeout;
end;
```

**工厂方法**:
- `TSocket.CreateTCP(family)` - 创建 TCP Socket
- `TSocket.CreateUDP(family)` - 创建 UDP Socket

**便捷工厂方法**:
- `TSocket.TCP` - 创建 IPv4 TCP Socket
- `TSocket.UDP` - 创建 IPv4 UDP Socket
- `TSocket.TCPv6` - 创建 IPv6 TCP Socket

### 🔩 选项矩阵（跨平台差异）
- Broadcast: UDP 常用；Windows/Unix 通常支持。TCP 上设置无意义但不报错。
- ReusePort: Unix 普遍支持（内核依赖）；Windows 历史兼容差，设置可能失败或读回 False（实现为尽力设置，不抛异常）。
- IPv6Only: 仅对 IPv6 套接字有效；控制是否仅允许 IPv6（禁用 IPv4-mapped）。
- Linger: 控制 Close 行为；Windows 使用 u_short 字段，POSIX 使用 int 字段，已做平台对齐；秒数溢出会被截断到平台上限。

注意：所有选项读取尽量从内核读回，个别平台不支持的选项将返回缺省值或抛出 NotSupported（当前 ReusePort 在 Windows 采取“尽力而为”策略）。

### 🚀 增强传输接口（最佳实践）
- SendAll(ptr,size)/SendAll(TBytes)/SendAll(TBytes,offset,count)：循环发送直到全部写完，期间对 EWOULDBLOCK/EAGAIN/EINTR 透明重试。
- ReceiveExact(ptr,size)/ReceiveExact(size): 循环接收直到满额，若对端关闭则抛出 ReceiveError。
- Send(TBytes,offset,count) 与 Receive(var TBytes,offset,count)：避免中间数组拷贝和分配。

建议：在高频路径选用指针重载配合 TrySend/TryReceive，以避免 TBytes 分配。对于跨平台行为差异（如 Windows 的非阻塞 Get 读回源于缓存），请参考“非阻塞与 Try* 语义”章节。

### ⚡ 快速开始（高性能用法）
- 参见 examples/fafafa.core.socket/example_socket.lpr：演示 NonBlocking + SendAll/ReceiveExact 的组合用法
- 并发回显示例：examples/fafafa.core.socket/echo_server_concurrent.pas 展示服务端并发处理
- Windows 运行示例：examples/fafafa.core.socket\run_example_socket.bat（自动构建并运行）


### 🧪 测试与示例：快速开始

- Windows
  - 主线测试：`tests\fafafa.core.socket\buildOrTest.bat test`
  - 性能套件：`tests\fafafa.core.socket\buildOrTest.bat test-perf`
  - ADV 专项：`tests\fafafa.core.socket\buildOrTest.bat adv`
  - ADV 仅跑某套件：`tests\fafafa.core.socket\buildOrTest.bat adv --suite=TTestCase_Socket_Advanced`
  - 快速冒烟：`tests\fafafa.core.socket\smoke.bat`
  - 日志位置（bin 目录）：`tests_socket.log`、`tests_socket_perf.log`、`tests_socket_adv.log`、`tests_socket_smoke.log`
  - 仅跑部分套件（示例）：`buildOrTest.bat test --suite=TTestCase_Socket_Advanced`

- Linux/macOS
  - 主线测试：`tests/fafafa.core.socket/buildOrTest.sh test`
  - 性能套件：`tests/fafafa.core.socket/buildOrTest.sh perf`
  - ADV 专项：`tests/fafafa.core.socket/buildOrTest.sh adv`
  - ADV 仅跑某套件：`tests/fafafa.core.socket/buildOrTest.sh adv --suite=TTestCase_Socket_Advanced`
  - 快速冒烟：`tests/fafafa.core.socket/smoke.sh`
  - 日志位置（bin 目录）：同上，分别生成对应 `.log`
  - 仅跑部分套件（示例）：`./buildOrTest.sh test --suite=TTestCase_Socket_Advanced`

- 示例工程
  - 一键构建示例：`examples/fafafa.core.socket/build_examples.bat`
  - 运行示例：`examples/fafafa.core.socket/bin/example_socket.exe ...`
  - 若 Debug/Release 模式不存在，脚本会自动回落到默认构建模式

- Best Practices 示例（长度前缀帧化 + 非阻塞/超时 循环范式）
  - Windows：`examples\fafafa.core.socket\bin\best_practices_nonblocking.exe --demo`
  - 仅服务器：`examples\fafafa.core.socket\bin\best_practices_nonblocking.exe --server-only 8080`
  - 仅客户端：`examples\fafafa.core.socket\bin\best_practices_nonblocking.exe --client-only 127.0.0.1 8080 hello`
  - Linux/macOS：`./examples/fafafa.core.socket/bin/best_practices_nonblocking --demo`


#### JUnit 报告输出（可选）

- 启用方式：设置环境变量 JUNIT=1（可选 JUNIT_OUT 指定输出路径）
- 默认输出路径（bin 目录）：
  - 主线：tests_socket.junit.xml
  - 性能：tests_socket_perf.junit.xml
  - ADV：tests_socket_adv.junit.xml
- Windows 示例：
  - 主线：`set JUNIT=1 && tests\fafafa.core.socket\buildOrTest.bat test`
  - ADV 自定义路径：`set JUNIT=1 && set JUNIT_OUT=D:\a\junit\socket-adv.xml && tests\fafafa.core.socket\buildOrTest.bat adv --suite=TTestCase_Socket_Advanced`
- Linux/macOS 示例：
  - 主线：`JUNIT=1 tests/fafafa.core.socket/buildOrTest.sh test`
  - Perf：`JUNIT=1 tests/fafafa.core.socket/buildOrTest.sh perf`
- 说明：启用 JUNIT 后使用 `--format=xml` 生成报告，控制台会打印 [JUnit] Summary 与 ExitCode。



示例命令：
- Windows: examples\fafafa.core.socket\run_example_socket.bat address-demo
- Windows: examples\fafafa.core.socket\run_example_socket.bat tcp-server 8080
- Windows: examples\fafafa.core.socket\run_example_socket.bat tcp-client localhost 8080
- Linux/macOS: ./examples/fafafa.core.socket/run_example_socket.sh address-demo
- Linux/macOS: ./examples/fafafa.core.socket/run_example_socket.sh tcp-server 8080
- Linux/macOS: ./examples/fafafa.core.socket/run_example_socket.sh tcp-client localhost 8080

- Windows: examples\fafafa.core.socket\run_example_socket.bat tcp-server-nb 8080
- Windows: examples\fafafa.core.socket\run_example_socket.bat tcp-client-nb localhost 8080
- Linux/macOS: ./examples/fafafa.core.socket/run_example_socket.sh tcp-server-nb 8080
- Linux/macOS: ./examples/fafafa.core.socket/run_example_socket.sh tcp-client-nb localhost 8080


- `TSocket.UDPv6` - 创建 IPv6 UDP Socket


一键 NB 往返演示：
- Windows: examples\fafafa.core.socket\run_example_socket_nb_demo.bat
- Linux/macOS: ./examples/fafafa.core.socket/run_example_socket_nb_demo.sh

### ISocketListener - 服务器监听器接口
参数说明：
- run_example_socket_nb_demo.(bat|sh) [port] [message]
  - port: 可选，默认 9099
  - message: 可选，默认使用内置演示文本


一键 UDP NB 往返演示：
- Windows: examples\fafafa.core.socket\run_example_socket_udp_nb_demo.bat [port] [message]
- Linux/macOS: ./examples/fafafa.core.socket/run_example_socket_udp_nb_demo.sh [port] [message]

高级的服务器端 Socket 封装，简化服务器开发。

```pascal
ISocketListener = interface(IInterface)
  // 监听控制
  procedure Start;
  procedure Stop;
  function Accept: ISocket;
  function AcceptWithTimeout(aTimeoutMs: Cardinal): ISocket;
  // Backward-compatible aliases (deprecated)
  function AcceptClient: ISocket; deprecated 'Use Accept instead';
  function AcceptClientTimeout(aTimeoutMs: Cardinal): ISocket; deprecated 'Use AcceptWithTimeout instead';

  // 配置
  property MaxConnections: Integer read GetMaxConnections write SetMaxConnections;
  property Backlog: Integer read GetBacklog write SetBacklog;

  // 状态查询
  property Active: Boolean read IsActive;
  property ListenAddress: ISocketAddress read GetListenAddress;
end;
```

## 📊 类型定义

### 地址族 (TAddressFamily)
```pascal
TAddressFamily = (
  afUnspec,        // 未指定
  afInet,          // IPv4
  afInet6,         // IPv6
  afUnix           // Unix域套接字
);
```

### Socket 类型 (TSocketType)
```pascal
TSocketType = (
  stStream,        // TCP流套接字
  stDgram,         // UDP数据报套接字
  stRaw            // 原始套接字
);
```

### 协议类型 (TProtocol)
```pascal
TProtocol = (
  pDefault,        // 默认协议
  pTCP,            // TCP协议
  pUDP,            // UDP协议
  pICMP            // ICMP协议
);
```

### Socket 状态 (TSocketState)
```pascal
TSocketState = (
  ssNotCreated,    // 未创建
  ssCreated,       // 已创建
  ssBound,         // 已绑定
  ssListening,     // 监听中
  ssConnecting,    // 连接中
  ssConnected,     // 已连接
  ssDisconnected,  // 已断开
  ssClosed         // 已关闭
);
```

## ⚙️ 平台行为与错误消息

- 超时选项实现差异
  - Windows：SO_SNDTIMEO / SO_RCVTIMEO 以整型毫秒设置与读取
  - Unix：SO_SNDTIMEO / SO_RCVTIMEO 以 timeval 结构设置与读取（秒+微秒）
  - API 语义：ISocket.SendTimeout / ReceiveTimeout 统一以毫秒表示，内部按平台转换
- 错误消息前缀统一（平台层）
  - Bind/Listen/Accept/Connect/Send/Receive failed: <platform-message>
  - Set/Get socket option failed: <platform-message>

## 行为矩阵（关键API语义速览）

- 约定说明：
  - 阻塞性：是否可能在默认 NonBlocking=False 下阻塞线程
  - 错误语义：异常式（抛异常）或返回式（返回 -1/0/>0 并输出错误码）
  - 超时：单位毫秒的含义；0/负值的语义

- 速览（节选）：
  - ISocket.Connect(addr): 阻塞性=可能阻塞；错误语义=异常式（ESocketConnectError/ESocketClosedError 等）
  - ISocket.ConnectWithTimeout(addr, timeoutMs): 非阻塞流程+等待可写；超时抛 ESocketConnectError
  - ISocket.Send(ptr,size): 阻塞性=可能阻塞；错误=异常式（ESocketSendError）
  - ISocket.Receive(ptr,size): 阻塞性=可能阻塞；错误=异常式（ESocketReceiveError）；返回=读到字节数；返回0=对端优雅关闭
  - ISocket.TrySend(ptr,size, out err): 非阻塞；返回>0=写入字节数；返回-1=错误（err=EWOULDBLOCK/EAGAIN/EINTR 视作可继续）
  - ISocket.TryReceive(ptr,size, out err): 非阻塞；>0=读取字节；-1=错误（同上）；0=对端优雅关闭
  - ISocket.WaitReadable/Writable(timeoutMs): 返回式；True 就绪/False 超时；不抛异常
  - ISocketListener.AcceptWithTimeout(timeoutMs): 返回式；超时返回 nil；不抛异常

- 推荐实践：
  - 高频路径采用：SetNonBlocking(True) + Wait* 或 Poll + Try* 组合，避免异常与阻塞开销
  - 阻塞风格仅在简单脚本或低频调用中使用

> 提示：从本版起，平台调用失败的异常大多携带 errorCode 与 handle，可用 ESocketError.GetDetailedMessage 查看；也可在代码中通过 ESocketError.CreateFromLastError('operation', handle) 构造一致的异常。


  - 说明：平台层统一英文前缀，便于跨平台日志解析；通用层的参数校验错误可保留中文提示

## 🔁 选项一致性与读取策略

- KeepAlive / TcpNoDelay
  - Set*: 先设置内核成功后更新缓存
  - Get*: 从内核读取真实值，并同步缓存
- SendTimeout / ReceiveTimeout
  - Set*: Windows 整数毫秒；Unix timeval
  - Get*: 统一换算成毫秒返回，保证行为一致
- Send/ReceiveBufferSize 的 Get 直接从内核读取实际值


## 🧵 非阻塞与 Try* 语义

- NonBlocking 属性
  - 默认 False（阻塞模式）。
  - 设为 True 后，常规 Send/Receive 在“会阻塞”场景抛出 ESocketSendError/ESocketReceiveError（不依赖具体错误消息文本）。
- TrySend/TryReceive（返回式）
  - 在非阻塞且内核缓冲区不可用/无数据可读时返回 -1，并通过输出错误码参数返回平台错误码（WSAEWOULDBLOCK/EWOULDBLOCK 等）。
  - 成功时返回已处理字节数（>0）。
  - 建议在高性能场景优先使用 Try* 族，结合外部轮询（如 select/fpSelect）。
- AcceptWithTimeout
  - 超时单位毫秒；0 表示“立即返回”（非阻塞轮询），无连接时返回 nil，不抛异常。

### 非阻塞接收与对端关闭（Windows 语义说明）

- 若对端已调用 Close 但本端内核接收缓冲区仍有剩余未读数据：
  - 第一次 Receive/TryReceive 仍会返回 "已读到的剩余字节数 (>0)"
  - 只有当剩余数据读尽后，下一次 Receive 才会返回 0（或 TryReceive 返回 -1 并给出 EWOULDBLOCK 之外的关闭类错误）
- 最佳实践：
  - 循环读取直至返回 0 或异常；若使用 TryReceive，则根据错误码判断是否继续轮询
  - 在高频路径中优先 Try* 族并结合外部轮询器，减少异常开销


### FAQ：为何对端关闭后第一次读仍返回 >0？

- 根因（Windows 行为）：
  - 当对端 Close 后，TCP 协议栈会先把已到达但未被应用读取的数据交付给本端内核接收缓冲区
  - 因此本端第一次 Receive/TryReceive 可能仍能读到“缓冲区剩余数据”，返回值 > 0
  - 只有在这些数据被读尽后，下一次 Receive 才会返回 0，表示对端已优雅关闭（FIN 已处理）
- 结论：
  - 这是正常语义，不应将“关闭后一读仍>0”视为异常
  - 应按“循环读取直至返回 0 或异常”的范式编写代码

### 示例：循环读取直至返回 0（阻塞 + 非阻塞 TryReceive 两种写法）

- 阻塞 Receive 范式（异常式错误处理）：
<augment_code_snippet path="docs/fafafa.core.socket.md" mode="EXCERPT">
````pascal
repeat
  n := Sock.Receive(@buf[0], SizeOf(buf));
  if n > 0 then Process(buf, n);
until n = 0; // 对端优雅关闭
````
</augment_code_snippet>

- 非阻塞 TryReceive 范式（返回式错误处理）：
<augment_code_snippet path="docs/fafafa.core.socket.md" mode="EXCERPT">
````pascal
repeat
  n := Sock.TryReceive(@buf[0], SizeOf(buf), err);
  if n > 0 then Process(buf, n)
  else if n = -1 then begin
    if err = SOCKET_EWOULDBLOCK then WaitReadableAndRetry
    else if IsPeerClosedError(err) then break
    else HandleError(err);
  end;
until false;
````
</augment_code_snippet>

### Select 轮询器的使用建议（Windows）

- 模式建议：
  - 单线程 Poll 循环；Register/Unregister/Modify 建议在同一线程或受控临界区内进行
  - 避免与 Poll 并发对同一 FD 集合进行修改，防止竞态
- 超时语义：
  - Poll(TimeoutMs) 的超时单位为毫秒，0 表示 "立即返回"，<0 表示无限等待
- 线程安全要点：
  - 如需跨线程注册/反注册，请使用同步原语（临界区/事件）保护 FDSet 修改与 Poll 调用的临界区
  - 推荐通过“事件队列 + 单线程 Poll”模型串行化 FD 集的修改

  - Windows 使用 select；Unix/Linux 使用 fpSelect 监听监听套接字可读。

### 平台差异速览（Windows vs Unix）

- 非阻塞错误码：
  - Windows：WSAEWOULDBLOCK
  - Unix/Linux：EWOULDBLOCK/EAGAIN（多数实现二者等价）
- 非阻塞接收在对端关闭后的行为：
  - Windows：若内核缓冲区仍有剩余数据，第一次读可能仍 >0；读尽后下一次返回 0
  - Unix：语义一致；实现细节依赖内核，但“剩余可读 -> >0；读尽 -> 0”同样成立
- 超时与轮询：
  - Windows：select（超时单位毫秒，0=立即返回）
  - Unix：fpSelect/Select（秒+微秒）；本库已做参数换算
- linger 行为：
  - Windows：u_short 字段表示 on/off 与秒数，秒数上限较小
  - Unix：int 字段；on/off + 秒数，语义相同，但读回值可能因平台舍入/截断不同
- 套接字选项读回：
  - 若平台不支持某选项：
    - Windows：可能返回默认值或失败；
    - Unix：可能返回 ENOPROTOOPT；本库统一转为 NotSupported 或尽力读回默认值


## 🖥️ 平台限制与注意事项

- Unix 域套接字（afUnix）
  - Windows 平台不支持；调用 CreateUnix/afUnix 相关能力将抛出 EInvalidArgument 或 ENotImplemented（视实现与版本而定）。
- 时间与缓冲区选项读回
  - 不同平台可能对超时/缓冲区大小取整或放大；Get* 返回值可能大于设置值，属预期行为。
- IPv6 文本规范化
  - 严格遵循 RFC 5952：最长零串压缩、并列取左、去前导零、统一小写；IPv4-mapped 使用 ::ffff:a.b.c.d；scope id（%N）保留。

## 🚀 使用示例

### 属性控制监听生命周期（简例）

```pascal
var L: ISocketListener;
begin
  L := TSocketListener.ListenTCP(8080);
  L.Active := True;   // 等价于 L.Start;
  // ... do work ...
  L.Active := False;  // 等价于 L.Stop;
end;
```

### TCP 服务器示例

```pascal
var
  LListener: ISocketListener;
  LClientSocket: ISocket;
  LData: TBytes;
  LMessage: string;
begin
  // 使用便捷方法创建监听器 - 在所有接口上监听
  LListener := TSocketListener.ListenTCP(8080);
  LListener.Backlog := 10;

  // 启动监听
  LListener.Start;
  WriteLn('服务器已启动，等待客户端连接...');

### 新增：AcceptWithTimeout 与 IPv6 文本格式化（原 AcceptClientTimeout 已作为别名保留）

- AcceptWithTimeout(aTimeoutMs)
  - Windows 使用 select，Unix/Linux 使用 fpSelect 等待可读；超时返回 nil（不抛异常）
  - aTimeoutMs=0 时为非阻塞轮询：若无连接则返回 nil（不抛异常）
- IPv6 文本输出（FromNativeAddr）
  - 全零地址 -> '::'；回环地址 -> '::1'
  - 严格遵循 RFC 5952：最长零串压缩、并列取左、去前导零、小写十六进制
  - 支持 IPv4 映射地址显示：'::ffff:a.b.c.d'（始终小写，例如 ::ffff:192.0.2.1）
## 🌐 地址解析策略详解

### 策略类型 (TAddressResolutionStrategy)

```pascal
TAddressResolutionStrategy = (
  arsDualStackFallback, // 首选IPv6，失败回退IPv4（默认）
  arsIPv6First,         // IPv6优先，失败时尝试IPv4
  arsIPv4First,         // IPv4优先，失败时尝试IPv6
  arsIPv6Only,          // 仅IPv6，不回退
  arsIPv4Only           // 仅IPv4，不回退
);
```

### 策略行为详解

#### 1. arsDualStackFallback（默认策略）
- **适用场景**：现代双栈网络环境，优先使用IPv6
- **解析顺序**：IPv6 → IPv4（失败时回退）
- **localhost处理**：解析为 `::1`
- **最佳实践**：推荐用于现代应用，兼容性最好

#### 2. arsIPv6First
- **适用场景**：IPv6优先环境，但允许IPv4回退
- **解析顺序**：IPv6 → IPv4（失败时回退）
- **localhost处理**：解析为 `::1`
- **与DualStackFallback区别**：行为基本相同，语义更明确

#### 3. arsIPv4First
- **适用场景**：传统IPv4网络或IPv4性能更优的环境
- **解析顺序**：IPv4 → IPv6（失败时回退）
- **localhost处理**：解析为 `127.0.0.1`
- **最佳实践**：适用于已知IPv4网络环境更稳定的场景

#### 4. arsIPv6Only
- **适用场景**：纯IPv6网络环境
- **解析顺序**：仅IPv6，失败不回退
- **localhost处理**：解析为 `::1`
- **注意事项**：在IPv4-only网络中会解析失败

#### 5. arsIPv4Only
- **适用场景**：传统IPv4网络或明确禁用IPv6的环境
- **解析顺序**：仅IPv4，失败不回退
- **localhost处理**：解析为 `127.0.0.1`
- **注意事项**：在IPv6-only网络中会解析失败

### 解析流程

#### 快速路径优化
1. **localhost特殊处理**：
   - IPv6族策略（IPv6Only/IPv6First/DualStackFallback）→ `::1`
   - IPv4族策略（IPv4Only/IPv4First）→ `127.0.0.1`

2. **字面量地址**：
   - IPv4地址（如 `192.168.1.1`）→ 直接使用
   - IPv6地址（如 `2001:db8::1`）→ 直接使用

#### 平台解析
- **IPv4解析**：使用 `gethostbyname`，取首条记录
- **IPv6解析**：使用 `getaddrinfo`，智能选择：
  - 优先选择非 link-local 地址（非 fe80::/16）
  - 无非 link-local 时接受 link-local 地址
  - 多记录时选择第一个符合条件的地址

#### 结果标准化
- IPv6地址通过 `FromNativeAddr` 标准化为 RFC 5952 格式
- 确保输出格式的一致性和规范性

### 使用示例

#### 基本用法
```pascal
var
  LAddr: ISocketAddress;
begin
  // 使用默认策略（DualStackFallback）
  LAddr := TSocketAddress.Create('example.com', 80, afInet6);

  // 显式设置策略
  LAddr := TSocketAddress.Create('example.com', 80, afInet6);
  TSocketAddress(LAddr).SetResolutionStrategy(arsIPv4First);
end;
```

#### 策略化localhost
```pascal
var
  LAddr: ISocketAddress;
begin
  // IPv6优先的localhost
  LAddr := TSocketAddress.LocalhostByStrategy(8080, arsDualStackFallback);
  // 结果：[::1]:8080

  // IPv4优先的localhost
  LAddr := TSocketAddress.LocalhostByStrategy(8080, arsIPv4First);
  // 结果：127.0.0.1:8080
end;
```

#### 服务器绑定策略
```pascal
// IPv6双栈服务器（推荐）
LListener := TSocketListener.Create(
  TSocketAddress.LocalhostByStrategy(8080, arsDualStackFallback)
);

// IPv4专用服务器
LListener := TSocketListener.Create(
  TSocketAddress.LocalhostByStrategy(8080, arsIPv4Only)
);
```

### 最佳实践建议

1. **现代应用**：使用 `arsDualStackFallback`（默认），确保IPv6优先且向后兼容
2. **传统环境**：使用 `arsIPv4First` 或 `arsIPv4Only`
3. **云原生应用**：考虑使用 `arsIPv6Only`，配合容器网络
4. **性能敏感**：根据网络环境选择单一协议族（IPv4Only/IPv6Only）
5. **测试环境**：使用 `LocalhostByStrategy` 确保一致的测试行为

### 平台兼容性
- **Windows**：完全支持所有策略
- **Linux**：完全支持所有策略
- **跨平台一致性**：解析行为在不同平台保持一致


  // 接受客户端连接
  LClientSocket := LListener.Accept;
  if Assigned(LClientSocket.RemoteAddress) then
    WriteLn('客户端已连接: ', LClientSocket.RemoteAddress.ToString)
  else
    WriteLn('客户端已连接');

  // 接收数据
  LData := LClientSocket.Receive(1024);
  LMessage := TEncoding.UTF8.GetString(LData);
  WriteLn('收到消息: ', LMessage);

  // 发送回复
  LData := TEncoding.UTF8.GetBytes('服务器收到消息');
  LClientSocket.Send(LData);

  // 清理资源
  LClientSocket.Close;
  LListener.Stop;
end;
```

### TCP 客户端示例

```pascal
var
  LSocket: ISocket;
  LAddress: ISocketAddress;
  LData: TBytes;
  LMessage: string;
begin
  // 使用便捷方法创建TCP客户端Socket
  LSocket := TSocket.TCP;

  // 设置Socket选项
  LSocket.ReuseAddress := True;
  LSocket.TcpNoDelay := True;
  LSocket.SendTimeout := 5000;
  LSocket.ReceiveTimeout := 5000;

  // 使用便捷方法创建服务器地址
  LAddress := TSocketAddress.Localhost(8080);
  LSocket.Connect(LAddress);
  WriteLn('已连接到服务器');

  // 发送消息
  LData := TEncoding.UTF8.GetBytes('你好，服务器！');
  LSocket.Send(LData);

  // 接收回复
  LData := LSocket.Receive(1024);
  WriteLn('收到回复: ', TEncoding.UTF8.GetString(LData));

  // 关闭连接
  LSocket.Close;
end;
```

### UDP 通信示例

```pascal
var
  LSocket: ISocket;
  LAddress: ISocketAddress;
  LFromAddress: ISocketAddress;
  LData: TBytes;
begin
  // 创建UDP Socket
  LSocket := TSocket.CreateUDP(afInet);

  // 发送数据
  LAddress := TSocketAddress.CreateIPv4('127.0.0.1', 9090);
  LData := TEncoding.UTF8.GetBytes('UDP消息');
  LSocket.SendTo(LData, LAddress);

  // 接收回复
  LData := LSocket.ReceiveFrom(1024, LFromAddress);
  WriteLn('收到来自 ', LFromAddress.ToString, ' 的回复: ',
          TEncoding.UTF8.GetString(LData));

  LSocket.Close;
end;
```

## ▶️ 示例运行说明

以下示例项目可用 lazbuild 一键构建，产物位于 examples/fafafa.core.socket/bin：

- 单线程 Echo 服务器
  - 构建：tools\lazbuild.bat examples\fafafa.core.socket\echo_server.lpi
  - 运行（IPv4）：examples\fafafa.core.socket\bin\echo_server.exe --port=8080 --timeout=500
  - 运行（IPv6）：examples\fafafa.core.socket\bin\echo_server.exe --ipv6 --port=8080 --timeout=500

- 并发 Echo 服务器（每连接一线程）
  - 构建：tools\lazbuild.bat examples\fafafa.core.socket\echo_server_concurrent.lpi
  - 运行（IPv4）：examples\fafafa.core.socket\bin\echo_server_concurrent.exe --port=8081 --timeout=200
  - 运行（IPv6）：examples\fafafa.core.socket\bin\echo_server_concurrent.exe --ipv6 --port=8081 --timeout=200

- 最小 Echo 客户端（新）
  - 构建：tools\lazbuild.bat examples\fafafa.core.socket\echo_client.lpi
  - 运行（IPv4）：examples\fafafa.core.socket\bin\echo_client.exe --host=127.0.0.1 --port=8080 --message=hello
  - 运行（IPv6）：examples\fafafa.core.socket\bin\echo_client.exe --ipv6 --host=::1 --port=8080 --message=hello

- UDP 服务器与客户端（新）
  - 构建：
    - tools\lazbuild.bat examples\fafafa.core.socket\udp_server.lpi
    - tools\lazbuild.bat examples\fafafa.core.socket\udp_client.lpi
  - 运行（IPv4）：
    - 服务器：examples\fafafa.core.socket\bin\udp_server.exe --port=9090
    - 客户端：examples\fafafa.core.socket\bin\udp_client.exe --host=127.0.0.1 --port=9090 --message=hello-udp
  - 运行（IPv6）：
    - 服务器：examples\fafafa.core.socket\bin\udp_server.exe --ipv6 --bind-host=::1 --port=9090
    - 客户端：examples\fafafa.core.socket\bin\udp_client.exe --ipv6 --host=::1 --port=9090 --message=hello-udp


### ℹ️ IPv6 常见问题排查（Windows）

- 确认本机 IPv6 启用：`ping ::1`
- 临时放宽/关闭防火墙后重试；首次运行注意 Windows 弹窗放行
- 显式绑定回环：服务器使用 `--bind-host=::1`，客户端 `--host=::1`
- 管理员权限运行一次做对照
- 若测试非回环地址，留意 link-local（fe80::/16）需要 scope id（如 `%3`）
- 在 Linux 环境验证 IPv6 较为稳定；若仅做功能演示，建议优先使用 IPv4 以减少环境变量干扰




### 💬 交互测试（快速验证）

- Linux/macOS（需安装 nc）
  - IPv4：`printf 'hello\n' | nc 127.0.0.1 8080`
  - IPv6：`printf 'hello\n' | nc -6 ::1 8080`
  - 并发示例（默认 8081）：`printf 'hello\n' | nc 127.0.0.1 8081`

- Windows
  - 若有 nc（nmap/Git Bash 等），可与上同
  - 纯 PowerShell（IPv4 127.0.0.1:8080，一次收发）：

```
powershell -NoProfile -Command "
  $c=New-Object System.Net.Sockets.TcpClient('127.0.0.1',8080);
  $s=$c.GetStream();
  $w=[IO.StreamWriter]::new($s);$w.AutoFlush=$true; $w.WriteLine('hello');
  $buf=New-Object byte[] 1024; $n=$s.Read($buf,0,$buf.Length);
  [Text.Encoding]::UTF8.GetString($buf,0,$n) | Write-Host; $c.Close()"
```


## ⚠️ 异常处理

模块定义了完整的异常体系：

- `ESocketError` - Socket 操作基础异常
- `ESocketCreateError` - Socket 创建失败
- `ESocketBindError` - Socket 绑定失败
- `ESocketListenError` - Socket 监听失败
- `ESocketConnectError` - Socket 连接失败
- `ESocketAcceptError` - Socket 接受连接失败
- `ESocketSendError` - Socket 发送数据失败
- `ESocketReceiveError` - Socket 接收数据失败
- `ESocketTimeoutError` - Socket 操作超时
- `ESocketClosedError` - 在已关闭的 Socket 上操作

## 🔗 模块依赖

### 直接依赖
- `fafafa.core.base` - 基础设施和异常类型

### 平台依赖
- **Windows**: WinSock2 API
- **Unix/Linux**: BSD Socket API

## 🧪 测试覆盖

模块包含完整的单元测试，覆盖：

- ✅ 地址解析和验证 (`test_socket_address.pas`)
- ✅ Socket 生命周期管理 (`test_socket.pas`)
- ✅ 数据传输功能 (`test_socket.pas`)
- ✅ 服务器监听器 (`test_socket_listener.pas`)
- ✅ 异常处理和边界条件
- ✅ 跨平台兼容性

## 📈 性能特性

- **零拷贝**: 支持指针直接操作，避免不必要的内存拷贝
- **平台优化**: 使用各平台最优的 Socket API
- **资源管理**: 自动的资源清理和生命周期管理
- **连接池**: 支持连接复用（通过 ISocketListener）
- **缓存优化**: Socket 选项缓存，减少系统调用

## ⚡ 事件轮询与异步支持

### 当前非阻塞支持

模块已提供基础的非阻塞操作支持：

```pascal
// 设置非阻塞模式
LSocket.NonBlocking := True;

// 非阻塞发送/接收
var
  LErrorCode: Integer;
  LBytesSent: Integer;
begin
  LBytesSent := LSocket.TrySend(LData, LErrorCode);
  if LBytesSent = -1 then
  begin
    if LErrorCode = WSAEWOULDBLOCK then
      // 缓冲区满，稍后重试
    else
      // 其他错误
  end;
end;
```

### 事件轮询接口设计（预留）

为未来的高性能异步支持，预留以下接口设计：

```pascal
// 事件类型
TSocketEvent = (
  seRead,     // 可读事件
  seWrite,    // 可写事件
  seError,    // 错误事件
  seClose     // 连接关闭事件
);

TSocketEvents = set of TSocketEvent;

// 事件轮询器接口（未来实现）
ISocketPoller = interface
  ['{GUID-FOR-SOCKET-POLLER}']

  // 注册Socket事件监听
  procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents);
  procedure UnregisterSocket(const ASocket: ISocket);

  // 轮询事件
  function Poll(ATimeoutMs: Integer): Integer;

  // 获取就绪事件
  function GetReadyEvents: TArray<TPair<ISocket, TSocketEvents>>;
end;

// 平台特定实现（未来）
// - Windows: IOCP (I/O Completion Ports)
// - Linux: epoll
// - BSD/macOS: kqueue
// - 通用: select/poll
```

### 异步集成方案

与 `fafafa.core.async` 模块的集成设计：

```pascal
// 异步Socket操作（未来实现）
function SendAsync(const AData: TBytes): IAsyncResult<Integer>;
function ReceiveAsync(AMaxBytes: Integer): IAsyncResult<TBytes>;
function ConnectAsync(const AAddress: ISocketAddress): IAsyncResult<Boolean>;
function AcceptAsync: IAsyncResult<ISocket>;

// 使用示例
var
  LResult: IAsyncResult<TBytes>;
begin
  LResult := LSocket.ReceiveAsync(1024);
  LResult.OnComplete := procedure(const AData: TBytes)
    begin
      // 处理接收到的数据
    end;
end;
```

## 🔮 未来规划

### 短期目标（1-2个月）
- **事件轮询实现**: epoll/kqueue/IOCP 支持
- **异步集成**: 与 `fafafa.core.async` 模块集成
- **性能优化**: 零拷贝和连接池支持

### 中期目标（3-6个月）
- **SSL/TLS**: 安全套接字支持
- **HTTP基础**: 基于Socket的HTTP客户端/服务器
- **WebSocket**: WebSocket协议支持

### 长期目标（6个月以上）
- **HTTP/2**: HTTP/2协议支持
- **QUIC**: QUIC协议实验性支持
- **微服务支持**: 服务发现和负载均衡

## 🔧 故障排除指南

### 常见编译问题

#### 1. 找不到 Socket 相关类型
**错误**: `Identifier not found "TSocketBuffer"`
**解决方案**: 检查是否启用了高级 Socket API
```pascal
// 在 fafafa.core.settings.inc 中启用
{$DEFINE FAFAFA_SOCKET_ADVANCED}
```

#### 2. 平台特定编译错误
**错误**: Windows 或 Linux 特定代码编译失败
**解决方案**: 确保包含了正确的平台实现文件
```pascal
{$IFDEF WINDOWS}
{$I fafafa.core.socket.windows.inc}
{$ENDIF}
{$IFDEF UNIX}
{$I fafafa.core.socket.linux.inc}
{$ENDIF}
```

### 运行时问题

#### 1. Socket 创建失败
**症状**: `ESocketCreateError` 异常
**可能原因**:
- 系统资源不足
- 权限不够（特别是原始套接字）
- 平台不支持指定的地址族

**解决方案**:
```pascal
try
  LSocket := TSocket.CreateTCP(afInet);
except
  on E: ESocketCreateError do
  begin
    WriteLn('Socket 创建失败: ', E.GetDetailedMessage);
    // 检查系统资源和权限
  end;
end;
```

#### 2. 地址绑定失败
**症状**: `ESocketBindError` 异常
**可能原因**:
- 端口已被占用
- 权限不足（端口 < 1024）
- 地址格式错误

**解决方案**:
```pascal
// 使用 ReuseAddress 选项
LSocket.ReuseAddress := True;
try
  LSocket.Bind(LAddress);
except
  on E: ESocketBindError do
  begin
    WriteLn('绑定失败: ', E.GetDetailedMessage);
    // 尝试其他端口或检查权限
  end;
end;
```

#### 3. 连接超时
**症状**: 连接操作长时间无响应
**解决方案**:
```pascal
// 设置连接超时
LSocket.SendTimeout := 5000;    // 5秒
LSocket.ReceiveTimeout := 5000; // 5秒

// 或使用非阻塞模式
LSocket.NonBlocking := True;
```

#### 4. IPv6 连接问题（Windows）
**症状**: IPv6 地址连接失败
**解决方案**:
- 确认 IPv6 已启用: `ping ::1`
- 检查防火墙设置
- 使用正确的 scope id: `fe80::1%3`

### 性能问题

#### 1. 低吞吐量
**症状**: 数据传输速度慢
**解决方案**:
```pascal
// 调整缓冲区大小
LSocket.SendBufferSize := 65536;    // 64KB
LSocket.ReceiveBufferSize := 65536; // 64KB

// 启用 TCP_NODELAY
LSocket.TcpNoDelay := True;

// 使用批量操作
{$IFDEF FAFAFA_SOCKET_ADVANCED}
LSocket.SendAll(LargeData);  // 确保全部发送
{$ENDIF}
```

#### 2. 高延迟
**症状**: 网络响应慢
**解决方案**:
```pascal
// 禁用 Nagle 算法
LSocket.TcpNoDelay := True;

// 使用 KeepAlive
LSocket.KeepAlive := True;

// 减少系统调用
// 使用更大的缓冲区进行批量操作
```

## 🚀 性能调优指南

### 基础优化

#### 1. 缓冲区调优
```pascal
// 根据应用场景调整缓冲区大小
// 高吞吐量应用
LSocket.SendBufferSize := 1024 * 1024;    // 1MB
LSocket.ReceiveBufferSize := 1024 * 1024; // 1MB

// 低延迟应用
LSocket.SendBufferSize := 8192;    // 8KB
LSocket.ReceiveBufferSize := 8192; // 8KB
```

#### 2. TCP 选项优化
```pascal
// 高吞吐量场景
LSocket.TcpNoDelay := False;  // 允许 Nagle 算法
LSocket.KeepAlive := True;    // 保持连接活跃

// 低延迟场景
LSocket.TcpNoDelay := True;   // 禁用 Nagle 算法
LSocket.KeepAlive := False;   // 减少开销
```

### 高级优化

#### 1. 非阻塞 I/O
```pascal
// 设置非阻塞模式
LSocket.NonBlocking := True;

// 使用 Try* 方法避免异常开销
var
  LErrorCode: Integer;
  LBytesSent: Integer;
begin
  LBytesSent := LSocket.TrySend(@LData[0], Length(LData), LErrorCode);
  if LBytesSent = -1 then
  begin
    if LErrorCode = SOCKET_EWOULDBLOCK then
      // 缓冲区满，稍后重试
    else
      // 处理其他错误
  end;
end;
```

#### 2. 连接复用
```pascal
// 使用连接池避免频繁创建/销毁连接
// 启用地址重用
LSocket.ReuseAddress := True;
LSocket.ReusePort := True;  // Linux 支持
```

#### 3. 批量操作
```pascal
{$IFDEF FAFAFA_SOCKET_ADVANCED}
// 使用向量化 I/O
var
  LVectors: TIOVectorArray;
begin
  SetLength(LVectors, 2);
  LVectors[0].Data := @LHeader[0];
  LVectors[0].Size := Length(LHeader);
  LVectors[1].Data := @LBody[0];
  LVectors[1].Size := Length(LBody);

  LSocket.SendVectorized(LVectors);
end;
{$ENDIF}
```

### 内存优化

#### 1. 避免频繁分配
```pascal
// 预分配缓冲区
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 4096);  // 预分配

  // 重复使用缓冲区
  while True do
  begin
    LReceived := LSocket.Receive(@LBuffer[0], Length(LBuffer));
    // 处理数据...
  end;
end;
```

#### 2. 使用缓冲区池
```pascal
{$IFDEF FAFAFA_SOCKET_ADVANCED}
var
  LPool: TSocketBufferPool;
  LBuffer: TSocketBuffer;
begin
  LPool := TSocketBufferPool.Create(8192, 64);
  try
    LBuffer := LPool.Acquire;
    try
      // 使用缓冲区...
    finally
      LPool.Release(LBuffer);
    end;
  finally
    LPool.Free;
  end;
end;
{$ENDIF}
```

### 并发优化

#### 1. 多线程服务器
```pascal
// 每连接一线程模式
procedure HandleClient(ASocket: ISocket);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        // 处理客户端请求...
      finally
        ASocket.Close;
      end;
    end).Start;
end;
```

#### 2. 事件驱动模式
```pascal
{$IFDEF FAFAFA_SOCKET_ADVANCED}
var
  LPoller: ISocketPoller;
begin
  // 推荐使用默认工厂，自动选择适合平台的轮询器（当前返回 select 实现）
  LPoller := CreateDefaultPoller;
  LPoller.RegisterSocket(LSocket, [seRead, seWrite]);

  while True do
  begin
    if LPoller.Poll(1000) > 0 then
    begin
      // 处理就绪事件...
    end;
  end;
end;
{$ENDIF}
```

## ❓ 常见问题（FAQ）

- 找不到 lazbuild
  - 现象：脚本提示“错误: 找不到 lazbuild 命令”
  - 处理：安装 Lazarus，并将 lazbuild 加入 PATH；或在 Windows 下使用仓库自带 tools\lazbuild.bat

- 构建模式 Debug/Release 不存在
  - 现象：examples 构建脚本在 Debug/Release 失败
  - 处理：脚本已内置回落到默认模式；如需新增模式，可在 .lpi 中添加 Build Modes 并重试

- ADV 目标无输出
  - 现象：执行 buildOrTest.bat adv 没有清晰日志
  - 处理：现已增强日志到 tests_socket_adv.log，并打印 [ADV] Summary 与 ExitCode；失败时自动展示末尾 50 行

- 仅跑某个测试套件/用例
  - 用法：
    - Windows：buildOrTest.bat test --suite=TTestCase_Socket
    - Linux/macOS：./buildOrTest.sh test --suite=TTestCase_Socket

- 端口占用
  - 现象：示例/测试偶发 bind 失败
  - 处理：确认没有残留进程占用端口；可改用随机端口（0）并通过 ListenAddress.Port 读取实际端口

- IPv6 示例无法回环
  - 现象：本地 IPv6 配置不一致导致连接失败
  - 处理：确保 ::1 可用，或使用明确的本机地址；Windows 需确认协议栈启用 IPv6

- 非阻塞读取对端关闭仍返回 >0
  - 说明：内核缓冲区剩余数据仍可读，直到读尽返回 0；详见“平台差异速览（Windows vs Unix）”



## 🧭 最佳实践（Best Practices）

### 1) 非阻塞与超时
- 建议：将超时与非阻塞结合，使用循环式 Connect/Send/Receive 模式
- 片段：ConnectWithTimeout / SendAll / ReceiveExact（示意）

```pascal
function ConnectWithTimeout(const Host: string; Port, TimeoutMs: Integer): ISocket;
var S: ISocket; DL: QWord;
begin
  S := TSocket.TCP;
  S.SetBlocking(False);
  DL := GetTickCount64 + QWord(TimeoutMs);
  S.Connect(TSocketAddress.Create(Host, Port));
  while not S.IsConnected do
  begin
    if GetTickCount64 >= DL then raise Exception.Create('connect timeout');
    Sleep(1);
  end;
  Result := S;
end;

procedure SendAll(S: ISocket; const P: PByte; L: Integer);
var Sent, N: Integer;
begin
  Sent := 0;
  while Sent < L do
  begin
    N := S.Send(@P[Sent], L - Sent);
    if N <= 0 then raise Exception.Create('send failed');
    Inc(Sent, N);
  end;
end;

procedure ReceiveExact(S: ISocket; const P: PByte; L: Integer);
var Read, N: Integer;
begin
  Read := 0;
  while Read < L do
  begin
    N := S.Receive(@P[Read], L - Read);
    if N = 0 then raise Exception.Create('peer closed');
    if N < 0 then raise Exception.Create('recv failed');
    Inc(Read, N);
  end;
end;
```

### 5.5) 非阻塞 + 轮询范式最佳实践清单（精要）
- 套路：SetNonBlocking(True) + TrySend/TryReceive + Wait*/Poll 外层退避循环
- 处理：
  - Try* = -1 且错误码为 EWOULDBLOCK/EAGAIN/EINTR → 继续轮询/重试
  - Try* > 0 → 正常推进；TryReceive=0 → 对端优雅关闭
- 发送：大块数据使用 SendAll（或循环 TrySend），避免一次性假设写满
- 接收：长度前缀帧化/上限校验（防御性编程），避免粘包/拆包问题
- 超时：将连接/发送/接收的超时放在“等待就绪 + 循环”外层，避免阻塞调用内部的不可控等待
- 轮询：单线程 Poll 驱动 + 事件队列串行化修改（Register/Unregister/Modify）
- 错误：EWOULDBLOCK/EAGAIN/EINTR 不是致命错误；真正错误才抛出/处理

### 5.6) 常见错误码对照（Windows vs Unix）
- WouldBlock：
  - Windows = WSAEWOULDBLOCK (10035)
  - Unix/Linux = EWOULDBLOCK (11) ≈ EAGAIN (11)
- Interrupted：
  - Windows = WSAEINTR (10004)
  - Unix/Linux = EINTR (4)
- SIGPIPE 防护：
  - Windows：无 SIGPIPE；一般不触发此类信号

### 错误码速查表（快速参考）

- Windows
  - 10035 WSAEWOULDBLOCK = WouldBlock（非阻塞不可用，重试/轮询）
  - 10004 WSAEINTR = 调用被中断
  - 10060 WSAETIMEDOUT = 超时
  - 10061 WSAECONNREFUSED = 连接被拒绝
  - 10054 WSAECONNRESET = 对端复位

- Unix/Linux/macOS
  - 11 EWOULDBLOCK/EAGAIN = WouldBlock（非阻塞不可用，重试/轮询）
  - 4 EINTR = 调用被中断
  - 110 ETIMEDOUT = 超时
  - 111 ECONNREFUSED = 连接被拒绝
  - 104 ECONNRESET = 对端复位

使用建议：
- Try* 返回 -1 且错误码为 WouldBlock/EINTR → 继续轮询/重试
- 连接类错误（拒绝/超时/不可达）→ 直接按异常路径处理

  - Linux：发送默认附加 MSG_NOSIGNAL；macOS/BSD：设置 SO_NOSIGPIPE
- 关闭语义：
  - Receive=0 代表对端优雅关闭；非阻塞下可能先读到缓冲区剩余数据再返回 0



### 5.7) 平台化占位策略与启用示例（实验）
- 策略：启用宏 FAFAFA_SOCKET_POLLER_EXPERIMENTAL 后，工厂 CreateDefaultPoller 按平台返回占位轮询器：
  - Windows → TIOCPPoller（stub，内部委托 select/fpSelect）
  - Linux → TEpollPoller（stub，内部委托 select/fpSelect）
  - macOS → TKqueuePoller（stub，内部委托 select/fpSelect）
  - 其他平台 → 回退 TSelectSocketPoller
- 目的：保持对外 API 与行为不变，逐步替换内部实现为 IOCP/epoll/kqueue 真实现。
- 启用步骤：
  1) 打开 src/fafafa.core.settings.inc，将“{.$DEFINE FAFAFA_SOCKET_POLLER_EXPERIMENTAL}”改为“{$DEFINE FAFAFA_SOCKET_POLLER_EXPERIMENTAL}”。
  2) 重新编译测试：tests/fafafa.core.socket/buildOrTest.bat test（或 smoke/adv/perf）。
  3) 通过 ISocketPoller.GetStatistics 可看到类似 "IOCP(stub)->..."/"epoll(stub)->..."/"kqueue(stub)->..." 前缀，表明当前为占位模式。
- 生产建议：默认保持该宏关闭，使用 select/fpSelect 的稳定实现。


### 2) 关闭与清理
- 建议：优先优雅关闭（shutdown write → 读至 0 → close）；谨慎使用 linger
- 片段：
```pascal
procedure GracefulClose(S: ISocket);
begin
  try
    S.Shutdown(shutWrite);
    // 读尽缓冲，直到返回 0
    while S.Receive(nil^, 0) > 0 do ;
  finally
    S.Close;
  end;
end;
```

### 3) I/O 模式与缓冲
- 指针/切片重载优先；大消息考虑向量化与 Buffer Pool
- 片段（示意）：
```pascal
var Vecs: TIOVectorArray;
SetLength(Vecs, 2);
Vecs[0] := TIOVector.FromBytes(Header);
Vecs[1] := TIOVector.FromBytes(Payload);
S.SendVectors(Vecs);
```

### 4) 轮询与多路复用（CreateDefaultPoller/select/fpSelect）
- 注意：超时单位、FD 集维护、空轮询开销；推荐“单线程 Poll + 事件队列”模型
- 片段：
```pascal
if WaitReadable(S, 1000) > 0 then
  N := S.Receive(@Buf[0], SizeOf(Buf));
```

### 5) 协议与健壮性（帧化）
- 长度前缀，处理粘包/拆包；限制 maxLen 防御异常输入
- 片段：
```pascal
procedure SendFrame(S: ISocket; const B: TBytes);
var H: array[0..3] of Byte; L: LongWord;
begin
  L := Length(B);
  Move(L, H[0], 4);
  SendAll(S, @H[0], 4);
  if L > 0 then SendAll(S, @B[0], L);
end;

function ReceiveFrame(S: ISocket; MaxLen: LongWord): TBytes;
var H: array[0..3] of Byte; L: LongWord;
begin
  ReceiveExact(S, @H[0], 4);
  Move(H[0], L, 4);
  if (L > MaxLen) then raise Exception.Create('frame too large');
  SetLength(Result, L);
  if L > 0 then ReceiveExact(S, @Result[0], L);
end;
```

### 6) Do / Don’t 清单
- Do：
  - 用循环完成 send/recv；检查 0（关闭）与负值（错误）
  - 将超时置于外层（等待就绪 + 循环）
  - 读尽后再 close；必要时启用超时/退避
- Don’t：
  - 假设一次 send/recv 即完成
  - 忽略 0 与错误码
  - 将长阻塞放在 UI 线程

## 📊 性能基准

### 典型性能指标

| 场景 | 吞吐量 | 延迟 | CPU 使用率 |
|------|--------|------|-----------|
| 本地回环 TCP | 1-10 GB/s | <1ms | <20% |
| 局域网 TCP | 100MB-1GB/s | 1-5ms | <30% |
| 广域网 TCP | 1-100MB/s | 10-100ms | <40% |
| UDP 本地 | 1-5 GB/s | <0.5ms | <15% |

### 性能测试示例

```pascal
// 吞吐量测试
procedure BenchmarkThroughput;
var
  LSocket: ISocket;
  LData: TBytes;
  LStart: TDateTime;
  LBytesSent: Int64;
begin
  SetLength(LData, 1024 * 1024); // 1MB
  LStart := Now;
  LBytesSent := 0;

  while (Now - LStart) < (1.0 / 24 / 60 / 60 * 10) do // 10秒
  begin
    LSocket.Send(LData);
    Inc(LBytesSent, Length(LData));
  end;

  WriteLn('吞吐量: ', LBytesSent div 10 div 1024 div 1024, ' MB/s');
end;
```

---

*本文档随模块更新而持续维护。如有疑问或建议，请参考示例代码或提交 Issue。*



## ⚙️ 构建/运行先决条件（lazbuild 配置）

- Windows 本仓库脚本通过 tools/lazbuild.bat 调用 lazbuild；若未安装到默认路径，请设置环境变量 LAZBUILD_EXE：
  - PowerShell：`$env:LAZBUILD_EXE='C:\Lazarus\lazbuild.exe'`
  - CMD：`set LAZBUILD_EXE=C:\Lazarus\lazbuild.exe`
- 然后执行：`tests\fafafa.core.socket\buildOrTest.bat test`
- 若仅运行已构建二进制：`tests\fafafa.core.socket\bin\tests_socket.exe --all --progress --format=plain`
- Linux/macOS 使用 `tests/fafafa.core.socket/buildOrTest.sh`，需确保 `lazbuild` 在 PATH 中。


## 🧪 极简 Poller 快速上手（select/fpSelect）

- 适用：需要在单线程内以最低成本进行事件轮询的 TCP 客户端/服务端
- 范式：非阻塞 + Try* + 轮询器 → 避免异常开销、避免阻塞

示例（片段）：

```pascal
{$mode objfpc}{$H+}

### 等待与超时 API（新）

- ISocket.WaitReadable(timeoutMs): Boolean
- ISocket.WaitWritable(timeoutMs): Boolean
- ISocket.ConnectWithTimeout(addr, timeoutMs)

用法要点：
- Wait* 返回是否就绪，不抛异常；结合 NonBlocking + Try* 更高效
- ConnectWithTimeout 采用“临时非阻塞 + 等待可写 + SO_ERROR 检查”的标准流程；超时抛出 ESocketConnectError
- Windows 下 select 的集合上限受 FD_SETSIZE 限制（常见为 64），本库在轮询器中对上限做了保护
- Linux 发送路径默认附加 MSG_NOSIGNAL，避免 SIGPIPE 中断进程

uses
  SysUtils,
  fafafa.core.socket;

procedure QuickPollerDemo;
var
  S: ISocket;
  Poller: ISocketPoller;
  Buf: array[0..1023] of byte;
  N, Err: Integer;
begin
  // 1) 建立连接并设为非阻塞
  S := TSocket.ConnectTo('127.0.0.1', 8080);
  S.SetNonBlocking(True);

  // 2) 创建默认轮询器并关注可读/可写
  Poller := CreateDefaultPoller;
  Poller.RegisterSocket(S, [seRead, seWrite]);

  // 3) 循环轮询 + Try* 非阻塞读写
  while True do
  begin
    if Poller.Poll(100) > 0 then
    begin
      for var E in Poller.GetReadyEvents do
      begin
        if (seWrite in E.Events) then
        begin
          // 尝试发送（无数据时可跳过）
          // var Msg: RawByteString := 'ping';
          // if S.TrySend(@Msg[1], Length(Msg), Err) = -1 then
          //   if (Err <> SOCKET_EWOULDBLOCK) and (Err <> SOCKET_EAGAIN) and (Err <> SOCKET_EINTR) then
          //     raise ESocketSendError.Create('send failed', Err, S.Handle);
        end;
        if (seRead in E.Events) then
        begin
          N := S.TryReceive(@Buf[0], SizeOf(Buf), Err);
          if N > 0 then
          begin
            // 处理收到的数据 N 字节
          end
          else if N = 0 then
          begin
            // 对端关闭
            Exit;
          end
          else if (Err <> SOCKET_EWOULDBLOCK) and (Err <> SOCKET_EAGAIN) and (Err <> SOCKET_EINTR) then
          begin
            // 真正错误
            raise ESocketReceiveError.Create('recv failed', Err, S.Handle);
          end;
        end;
      end;
    end;
  end;
end;
```

要点：
- 非阻塞：通过 SetNonBlocking(True) 配合 TrySend/TryReceive，避免阻塞与异常开销
- 轮询间隔：Poll(100) 只是示例，生产中建议采用“事件驱动 + 任务队列”模型
- 错误码：EWOULDBLOCK/EAGAIN/EINTR 视作“继续轮询”，其余错误才应处理/抛出


### 一键运行最小示例

- Windows：examples\fafafa.core.socket\run_example_min.bat
- Linux/macOS：./examples/fafafa.core.socket/run_example_min.sh

这两个脚本会在缺少可执行文件时自动触发构建，然后：
- 启动 echo_server（端口 8080）
- 运行 example_echo_min_poll_nb（非阻塞+轮询）
- 预期输出：客户端打印 recv: hello



## 🏭 默认轮询器工厂策略与宏矩阵

- 默认策略：CreateDefaultPoller 返回基于 select/fpSelect 的 ISocketPoller（跨平台稳定、零依赖）
- 注：当前仓库已加入该宏占位（FAFAFA_SOCKET_POLLER_EXPERIMENTAL），默认未启用，工厂始终回退到 select/fpSelect
- 宏开关（默认关闭）：
  - FAFAFA_SOCKET_POLLER_EXPERIMENTAL：预留高性能轮询器接入（epoll/kqueue/IOCP），当前未启用时或不可用时回退到 select
  - FAFAFA_SOCKET_ASYNC_EXPERIMENTAL：预留异步接口 IAsyncResult 等
  - FAFAFA_SOCKET_ADVANCED：开启高级能力（统计、零拷贝缓冲池、诊断）
- 平台目标映射（仅在 POLLER_EXPERIMENTAL 宏开启且实现就绪时生效，否则回退 select）：
  - Windows：优先 IOCP → 回退 select
  - Linux：优先 epoll → 回退 select
  - macOS/BSD：优先 kqueue → 回退 select
- 建议：生产环境默认使用 CreateDefaultPoller（select），在性能敏感业务中按平台灰度启用实验轮询器，配合回退路径保障稳定


## 平台差异对照表（精要）

- Windows

## 异常消息示例（含 errorCode/handle）

- 连接失败（ConnectWithTimeout 超时后 SO_ERROR 非 0）
  - 抛出：ESocketConnectError
  - 示例消息："Connect failed after wait"
  - 详细：GetDetailedMessage 可能显示为：

```
Connect failed after wait (ErrorCode: 10060) (Socket: 123456)
```

- 绑定失败（端口占用）
  - 抛出：ESocketBindError
  - 示例消息："Bind failed: 地址已被使用"
  - 详细：
```
Bind failed: 地址已被使用 (ErrorCode: 10048) (Socket: 987654)
```

> 注：具体错误码与句柄因平台/环境不同而异，以上为示例。

## select 上限对策（FD_SETSIZE）

- 背景：
  - Windows 上 FD_SETSIZE 常见为 64；Linux/macOS 在 select 的 fd 集合规模过大时也会有性能与限制问题
- 对策：
  - 分片轮询：按连接数将 fd 切分为多个 poller 分片，循环轮询各分片
  - 负载分摊：多线程或多进程将连接分配到不同的 poller/进程，缩小单个 select 的集合规模
  - 动态切换：在连接数超过阈值时，切换/启用实验轮询器（epoll/kqueue/IOCP），或者将高负载服务专用一个更高效的 poller
  - 优雅降级：实验实现不可用时回退 select（本库 CreateDefaultPoller 已默认回退）
- 建议：
  - 为每个分片设置合理的最大连接数（如 32/64），保证轮询延迟可控
  - 将阻塞式操作移出 Poll 主循环，用任务队列串行化 Register/Unregister/Modify 等操作

  - 非阻塞错误码：WSAEWOULDBLOCK (10035), WSAEINTR (10004)
  - 轮询：select（FD_SETSIZE 常见=64，注意上限）
  - SIGPIPE：无；Send 不会触发 SIGPIPE
  - 非阻塞设置：ioctlsocket(FIONBIO)

- Linux
  - 非阻塞错误码：EWOULDBLOCK/EAGAIN, EINTR
  - 轮询：fpSelect；生产建议 epoll（后续可切换实验实现）
  - SIGPIPE：默认存在；库内发送路径附加 MSG_NOSIGNAL 避免中断
  - 非阻塞设置：fcntl(O_NONBLOCK)


## 分片轮询示例（多 poller 调度）

- 调度图（多分片轮询，每个分片管理一部分连接）：

```mermaid
flowchart LR
  A[Accept/Assign] -->|hash(fd)%N| P1
  A -->|...| PN
  subgraph Shard1
    P1[Poller #1]
    P1 --> H1[Handle events]
  end
  subgraph ShardN
    PN[Poller #N]
    PN --> HN[Handle events]
  end
```

- 最小 Pascal 示例（核心思想）：

```pascal
const Shards = 4;
var Pollers: array[0..Shards-1] of ISocketPoller;
    Buckets: array[0..Shards-1] of array of ISocket;

procedure InitPollers;
var i: Integer;
begin
  for i := 0 to Shards-1 do Pollers[i] := CreateDefaultPoller;
end;

procedure AssignSocket(const S: ISocket);
var idx: Integer;
begin
  idx := PtrUInt(S.Handle) mod Shards;
  Pollers[idx].RegisterSocket(S, [seRead, seWrite]);
end;

procedure EventLoop;
var i: Integer; E: TPollerEvent;
begin
  while True do
  begin
    for i := 0 to Shards-1 do
      if Pollers[i].Poll(5) > 0 then
        for E in Pollers[i].GetReadyEvents do
          HandleEvent(E);
  end;
end;
```

- 要点：
  - 将 Register/Unregister/Modify 操作串行化到各分片线程/循环，避免竞争
  - 连接迁移（负载均衡）：在“无事件窗口”时进行迁移，先从 A 分片 Unregister 再到 B 分片 Register
  - 大规模连接：Shards 可按 CPU 核数或连接规模调整
```

### 多线程分片轮询（最佳实践）

- 设计：每个分片一个线程，独立 poller 与就绪队列。Accept/分配线程只负责将新连接按 hash(fd)%N 分派到对应分片队列。
- 线程数：默认 = CPU 核数；允许通过配置覆盖（环境变量或参数）。

```pascal
const Shards = {$IFDEF CPU_COUNT_DEFINED}CPU_COUNT{$ELSE}4{$ENDIF};
var Pollers: array[0..Shards-1] of ISocketPoller;
    Threads: array[0..Shards-1] of TThread;

procedure ShardLoop(idx: Integer);
var E: TPollerEvent;
begin
  while not Terminated do
  begin
    if Pollers[idx].Poll(10) > 0 then
      for E in Pollers[idx].GetReadyEvents do
        HandleEvent(E);
  end;
end;

procedure StartShards;
var i: Integer;
begin
  for i := 0 to Shards-1 do
  begin
    Pollers[i] := CreateDefaultPoller;
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        ShardLoop(i);
      end
    );
    Threads[i].Start;
  end;
end;

procedure StopShards;
var i: Integer;
begin
  for i := 0 to Shards-1 do
  begin
    Threads[i].Terminate;
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
end;

procedure AssignSocket(const S: ISocket);
var idx: Integer;
begin
  idx := PtrUInt(S.Handle) mod Shards;
  Pollers[idx].RegisterSocket(S, [seRead, seWrite]);
end;
```

- 注意事项：
  - 注册/注销必须在目标分片线程内执行（可通过分片线程安全队列串行化请求）
  - 跨分片迁移：先在源分片发 Unregister 请求，完成后再在目标分片 Register；避免双重注册
  - 处理背压：当某分片压力大时，优先在分配阶段做“轻量倾斜”或限速


- macOS/BSD
  - 非阻塞错误码：EWOULDBLOCK/EAGAIN, EINTR
  - 轮询：fpSelect；生产建议 kqueue（后续可切换实验实现）
  - SIGPIPE：通过 SO_NOSIGPIPE 抑制
  - 非阻塞设置：fcntl(O_NONBLOCK)

- 关闭语义（统一）
  - Receive 返回 0 表示对端优雅关闭；非阻塞下可能先读到缓冲区剩余数据，再返回 0

- 建议
  - 高并发：优先考虑 epoll/kqueue/IOCP（随实验实现成熟逐步切换），否则分片管理 fd 集，控制单轮 select 规模
  - 高性能：统一采用 NonBlocking + Wait*/Poll + Try* 的组合，避免异常与阻塞开销

示例：

````pascal
var Poller: ISocketPoller;
begin
  Poller := CreateDefaultPoller;
  Poller.RegisterSocket(S, [seRead, seWrite]);
  while Poller.Poll(100) > 0 do
  begin
    // 处理就绪事件...
  end;
end;
````

## 平台差异矩阵（精要）

- Windows
  - select 的集合容量受 FD_SETSIZE 限制（常见默认 64）。本库在轮询器中对上限做保护，注册到上限时会抛出包含上限值的错误提示
  - ConnectWithTimeout 会在 WaitWritable 后检查 SO_ERROR 确认连接结果
- Linux
  - 发送路径默认附加 MSG_NOSIGNAL，避免 SIGPIPE 中断进程
  - ConnectWithTimeout 同样通过 SO_ERROR 检查确认连接
- macOS (Darwin)
  - 发送路径设置 SO_NOSIGPIPE=1，规避 SIGPIPE
  - 其他行为同 Linux


### 分片线程安全队列骨架（推荐 TThreadedQueue）

- 目的：将跨线程的 Register/Unregister/Modify 操作串行化到目标分片线程，避免竞争。
- 操作类型：

```pascal
Type
  TShardOpKind = (opRegister, opUnregister, opModify);
  TShardOp = record
    Kind: TShardOpKind;
    S: ISocket;
    Events: TSocketEvents; // e.g. [seRead, seWrite]
  end;

var ShardQueues: array[0..Shards-1] of specialize TThreadedQueue<TShardOp>;

procedure PostOp(Idx: Integer; const Op: TShardOp);
begin
  ShardQueues[Idx].PushItem(Op);
end;

procedure ShardLoop(idx: Integer);
var E: TPollerEvent; Op: TShardOp;
begin
  while not Terminated do
  begin
    // 1) 先串行执行分片队列中的操作
    while ShardQueues[idx].PopItem(Op) = wrSignaled do
    begin
      case Op.Kind of
        opRegister:   Pollers[idx].RegisterSocket(Op.S, Op.Events);
        opUnregister: Pollers[idx].UnregisterSocket(Op.S);
        opModify:     Pollers[idx].ModifySocket(Op.S, Op.Events);
      end;
    end;

    // 2) 再 Poll 事件
    if Pollers[idx].Poll(10) > 0 then
      for E in Pollers[idx].GetReadyEvents do
        HandleEvent(E);
  end;
end;
```

- 迁移示例：

```pascal
procedure MigrateToShard(const S: ISocket; FromIdx, ToIdx: Integer; NewEvents: TSocketEvents);
var Op: TShardOp;
begin
  // 先在源分片注销
  Op.Kind := opUnregister; Op.S := S; ShardQueues[FromIdx].PushItem(Op);
  // 再在目标分片注册
  Op.Kind := opRegister; Op.Events := NewEvents; ShardQueues[ToIdx].PushItem(Op);
end;
```

- 后备方案（无 TThreadedQueue 时）：

```pascal
var Q: array[0..Shards-1] of TList; // 存放 ^TShardOp 动态分配
    QLock: array[0..Shards-1] of TCriticalSection;

procedure PostOp(Idx: Integer; const Op: TShardOp);
var P: PShardOp;
begin
  New(P); P^ := Op;
  EnterCriticalSection(QLock[Idx]);
  Q[Idx].Add(P);
  LeaveCriticalSection(QLock[Idx]);
end;

procedure DrainQueue(idx: Integer);
var I: Integer; P: PShardOp; Local: TList;
begin
  EnterCriticalSection(QLock[idx]);
  Local := TList.Create; Local.Assign(Q[idx]); Q[idx].Clear;
  LeaveCriticalSection(QLock[idx]);
  try
    for I := 0 to Local.Count-1 do
    begin
      P := PShardOp(Local[I]);
      case P^.Kind of
        opRegister:   Pollers[idx].RegisterSocket(P^.S, P^.Events);
        opUnregister: Pollers[idx].UnregisterSocket(P^.S);
        opModify:     Pollers[idx].ModifySocket(P^.S, P^.Events);
      end;
      Dispose(P);
    end;
  finally
    Local.Free;
  end;
end;
```

- 实战提示：
  - Assign 时不要跨线程直接 Register/Unregister，统一投递到目标分片队列
  - 队列拥塞时可限速或丢弃重复 Modify（合并最新事件）
  - 迁移尽量在“无事件窗口”进行，缩短双分片同时关注同一 fd 的时间


### 整合模板：DrainQueue + Poll 最小循环

- 将“队列出队执行（DrainQueue）”与“事件轮询（Poll）”整合到单个循环中，便于复制粘贴：

```pascal
Type
  TShardMetrics = record
    ProcessedOps: QWord;
    ProcessedEvents: QWord;
    LastLoopMs: Integer;
  end;

var Metrics: array[0..Shards-1] of TShardMetrics;

procedure ShardLoop(idx: Integer);
var T0: QWord; E: TPollerEvent; Op: TShardOp;
begin
  while not Terminated do
  begin
    T0 := GetTickCount64;

    // 1) 串行执行操作（从队列到 Poller）
    while ShardQueues[idx].PopItem(Op) = wrSignaled do
    begin
      case Op.Kind of
        opRegister:   Pollers[idx].RegisterSocket(Op.S, Op.Events);
        opUnregister: Pollers[idx].UnregisterSocket(Op.S);
        opModify:     Pollers[idx].ModifySocket(Op.S, Op.Events);
      end;
      Inc(Metrics[idx].ProcessedOps);
    end;

    // 2) 轮询事件
    if Pollers[idx].Poll(10) > 0 then
      for E in Pollers[idx].GetReadyEvents do
      begin
        HandleEvent(E);
        Inc(Metrics[idx].ProcessedEvents);
      end;

    Metrics[idx].LastLoopMs := Integer(GetTickCount64 - T0);
  end;
end;
```

### Modify 合并（去重）示例

- 避免同一 socket 的多次 Modify 在队列中堆积，可先合并为“最新的事件掩码”，仅保留一条：

```pascal
Type
  TPendingModify = specialize TFPGMap<QWord, TSocketEvents>; // key=PtrUInt(S.Handle)
var Pending: array[0..Shards-1] of TPendingModify;

procedure PostModify(Idx: Integer; const S: ISocket; Ev: TSocketEvents);
var K: QWord; POp: TShardOp;
begin
  K := PtrUInt(S.Handle);
  // 合并: 写入/覆盖最新事件集
  Pending[Idx].KeyData[K] := Ev;
  // 使用占位符触发分片线程在下一轮 Drain 时处理；避免为每次 Modify 都 PushItem
  POp.Kind := opModify; POp.S := S; POp.Events := [];
  ShardQueues[Idx].PushItem(POp);
end;

procedure DrainPending(idx: Integer);
var I: Integer; Key: QWord; Ev: TSocketEvents; S: ISocket;
begin
  for I := 0 to Pending[idx].Count-1 do
  begin
    Key := Pending[idx].Keys[I]; Ev := Pending[idx].Data[I];
    // 根据 Key 取回 ISocket（可维护 Handle->ISocket 的弱引用表）
    S := LookupSocketByHandle(Key);
    if S<>nil then Pollers[idx].ModifySocket(S, Ev);
  end;
  Pending[idx].Clear;
end;

// 在 ShardLoop 中：先 DrainQueues，再调用 DrainPending，然后 Poll
```

说明：
- 简化实现可直接在队列层做“去重”：若队列尾部已有同一句柄的 Modify，更新其事件掩码而不追加新项（需要自定义队列或加锁扫描）。

### 分片指标 JSON 示例

- 暴露每个分片的轻量指标 JSON（便于采集）：

```pascal
function GetShardMetricsJson(idx: Integer): string;
begin
  Result := '{' +
    '"idx":' + IntToStr(idx) + ',' +
    '"processedOps":' + IntToStr(Metrics[idx].ProcessedOps) + ',' +
    '"processedEvents":' + IntToStr(Metrics[idx].ProcessedEvents) + ',' +
    '"queueLen":' + IntToStr(ShardQueues[idx].NumItems) + ',' +
    '"lastLoopMs":' + IntToStr(Metrics[idx].LastLoopMs) +
  '}';
end;
```

- 聚合输出（所有分片）：

```pascal
function GetAllShardsMetricsJson: string;
var i: Integer;
begin
  Result := '[';
  for i := 0 to Shards-1 do
  begin
    if i>0 then Result := Result + ',';
    Result := Result + GetShardMetricsJson(i);
  end;
  Result := Result + ']';
end;
```

提示：
- 如需更丰富的指标，可扩展为：最大队列长度、平均/百分位轮询耗时、错误计数、迁移计数等
- 若担心 JSON 拼接开销，可按需导出或设置采样周期


### Handle -> ISocket 查找表（简版与弱引用思路）

- 简版（强引用 Map）：

```pascal
Type
  TSocketTable = specialize TFPGMap<QWord, ISocket>; // key=PtrUInt(S.Handle)
var SockTab: TSocketTable;

procedure RegisterSocketRef(const S: ISocket);
begin
  SockTab[PtrUInt(S.Handle)] := S; // 强引用：生命周期跟随表
end;

procedure UnregisterSocketRef(const S: ISocket);
begin
  SockTab.Delete(PtrUInt(S.Handle));
end;

function LookupSocketByHandle(Key: QWord): ISocket;
begin
  if SockTab.IndexOf(Key) >= 0 then Result := SockTab.KeyData[Key] else Result := nil;
end;
```

- 弱引用思路：使用“句柄->不持有接口引用的轻量记录（含弱 ID）”，并在 socket 析构/Close 阶段回调表删除；或者用自定义弱引用容器（需要额外基础设施）。

### Listener/Socket 扩展 JSON 聚合分片指标

- 在已有 Extended JSON 基础上追加分片指标：

```pascal
function GetSystemMetricsJson: string;
begin
  Result := '{' +
    '"listener":' + (Listener as TSocketListener).GetExtendedStatisticsJson + ',' +
    '"shards":' + GetAllShardsMetricsJson +
  '}';
end;
```

### 分片模块最小单元（API 骨架）

```pascal
Type
  IShardSystem = interface
    procedure Init(ShardCount: Integer);
    procedure Start;
    procedure Stop;
    procedure Assign(const S: ISocket; Events: TSocketEvents = [seRead, seWrite]);
    procedure Migrate(const S: ISocket; NewShard: Integer; NewEvents: TSocketEvents);
    function MetricsJson: string;
  end;

  TShardSystem = class(TInterfacedObject, IShardSystem)
  public
    procedure Init(ShardCount: Integer);
    procedure Start;
    procedure Stop;
    procedure Assign(const S: ISocket; Events: TSocketEvents = [seRead, seWrite]);
    procedure Migrate(const S: ISocket; NewShard: Integer; NewEvents: TSocketEvents);
    function MetricsJson: string;
  end;

procedure TShardSystem.Init(ShardCount: Integer);
begin
  // 分配 Pollers/Queues/Threads/Metrics；初始化 SockTab/Pending 等结构
end;

procedure TShardSystem.Start;
begin
  // 启动分片线程（CreateAnonymousThread+Start），线程内运行 ShardLoop(idx)
end;

procedure TShardSystem.Stop;
begin
  // Terminate+WaitFor；清理分片资源
end;

procedure TShardSystem.Assign(const S: ISocket; Events: TSocketEvents);
var idx: Integer; Op: TShardOp;
begin
  idx := PtrUInt(S.Handle) mod Shards;
  RegisterSocketRef(S);
  Op.Kind := opRegister; Op.S := S; Op.Events := Events; PostOp(idx, Op);
end;

procedure TShardSystem.Migrate(const S: ISocket; NewShard: Integer; NewEvents: TSocketEvents);
var oldIdx: Integer; Op: TShardOp;
begin
  oldIdx := PtrUInt(S.Handle) mod Shards;
  Op.Kind := opUnregister; Op.S := S; PostOp(oldIdx, Op);
  Op.Kind := opRegister; Op.Events := NewEvents; PostOp(NewShard, Op);
end;

function TShardSystem.MetricsJson: string;
begin
  Result := GetAllShardsMetricsJson;
end;
```

提示：
- 若需要“可扩缩容”的 ShardCount 动态调整，则需要分配期与迁移期的双轨流程，保证在切换窗口内的注册/注销顺序与幂等性。

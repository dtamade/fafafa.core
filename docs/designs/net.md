# fafafa.core.net 网络模块设计蓝图 (net.md)

本文档是 `fafafa.core.net` 模块的统一设计蓝图。该模块旨在提供一个从底层原始套接字 (Socket) 到上层应用协议的、全面的、高性能的网络编程框架。

---

## 核心设计哲学

*   **分层架构**: 模块内部分为清晰的层次：底层 Socket API -> DNS解析/异步句柄 -> 应用层协议。
*   **跨平台**: 封装不同操作系统在网络编程上的差异，提供统一的 API。
*   **异步优先**: 核心 API 设计将优先考虑与 `fafafa.core.async` 模块的无缝集成，同时兼顾传统的同步阻塞模式。
*   **类型安全**: 提供强类型的接口来处理地址、协议和 Socket 选项，避免直接操作底层整数常量。

---

## 阶段一: 底层 Socket API

*目标: 提供对底层 BSD Socket API 的一层薄的、类型安全的、跨平台的封装。这是整个网络模块的基石。*

- [ ] **1.1. 创建 `fafafa.core.net.socket.pas` 单元**

- [ ] **1.2. 定义基础枚举与记录体**
    - `TAddressFamily`: `afInet` (IPv4), `afInet6` (IPv6), `afUnix` (Unix aDomain Socket), `afUnspec` (未指定)。
    - `TSocketType`: `stStream` (TCP), `stDgram` (UDP), `stRaw`。
    - `TProtocol`: `pTCP`, `pUDP`。
    - `TSockAddr`: 封装 `sockaddr_in`, `sockaddr_in6` 等，并提供 `Create`, `ToString`, `From` 等辅助方法。

- [ ] **1.3. 设计 `TSocket` 核心类**
    - @desc: 此类不直接处理 I/O 操作，只负责 Socket 的生命周期、连接状态和选项设置。
    - ```pascal
      type
        TSocket = class
        private
          FHandle: TSocketHandle; // 操作系统原生的套接字句柄
        public
          constructor Create(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol);
          destructor Destroy; override;

          procedure Bind(const aAddress: TSockAddr);
          procedure Listen(aBacklog: Integer);
          function Accept: TSocket; // 返回一个新的 TSocket 实例
          procedure Connect(const aAddress: TSockAddr);

          procedure Shutdown(aHow: TShutdownMode); // aHow: sdRead, sdWrite, sdBoth
          procedure Close;

          // ... Socket 选项的 Get/Set 方法将在下一步定义 ...

          property Handle: TSocketHandle read FHandle;
        end;
      ```

- [ ] **1.4. 设计强类型的 Socket 选项 API**
    - @desc: 提供类型安全的 API 来替代 `setsockopt` 和 `getsockopt` 的魔术数字。
    - **API 设计** (在 `TSocket` 类中):
        ```pascal
        // 示例
        procedure SetReuseAddress(aValue: Boolean);
        function GetReuseAddress: Boolean;

        procedure SetTcpNoDelay(aValue: Boolean);
        function GetTcpNoDelay: Boolean;

        procedure SetSendTimeout(aMilliseconds: Integer);
        function GetSendTimeout: Integer;
        // ... etc. for SO_KEEPALIVE, SO_RCVBUF, etc.
        ```

- [ ] **1.5. 单元测试**
    - [ ] 编写 `testcase_socket.pas`。
    - [ ] 测试 TCP 的 `Bind` -> `Listen` -> `Accept` -> `Connect` 流程。
    - [ ] 测试 Socket 选项的设置和获取是否正确。

---

## 阶段二: DNS 解析与异步集成 (后续规划)

*目标: 将 Socket 与事件循环集成，并提供域名解析能力。*

- [ ] **2.1. 设计 `TDNS` 解析器 (`fafafa.core.net.dns.pas`)**
- [ ] **2.2. 设计 `TTcpSocket` 异步句柄 (`fafafa.core.net.tcp.pas`)**
- [ ] **2.3. 设计 `TUdpSocket` 异步句柄 (`fafafa.core.net.udp.pas`)**

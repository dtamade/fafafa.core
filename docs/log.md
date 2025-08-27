# fafafa.core.log 日志模块设计蓝图 (log.md)

本文档旨在规划和指导 `fafafa.core.log` 模块的实现。该模块的目标是提供一个高性能、结构化、可扩展的日志框架，以满足从开发调试到生产环境监控的全部需求。

---

## 核心设计哲学

*   **分级与分类**: 支持多种日志级别和按模块分类的日志记录器。
*   **结构化**: 日志消息应被视为数据，支持 JSON 等机器可读格式的输出。
*   **多路输出 (Sinks)**: 日志可以被路由到一个或多个后端，如控制台、文件、网络等。
*   **高性能**: 核心日志路径应避免阻塞。提供异步日志模式，将 I/O 操作转移到后台线程。
*   **易用性**: 提供一个简单、流畅的 API，方便开发者在代码中记录日志。

---

## 开发路线图

### 阶段一: 核心 API 与基础组件

*目标: 搭建日志系统的骨架，定义核心接口和最基础的同步日志功能。*

- [ ] **1.1. 创建核心单元**
    - `fafafa.core.log.pas`: 定义 `TLog` 全局访问类和核心接口。
    - `fafafa.core.log.logger.pas`: 定义 `TLogger` 类。
    - `fafafa.core.log.sink.pas`: 定义 `ILogSink` 接口和基础 Sink 实现。

- [ ] **1.2. 设计核心 API**
    - **日志级别 (`TLogLevel`)**: `Debug`, `Info`, `Warn`, `Error`, `Fatal`。
    - **日志记录 (`TLogRecord`)**: 一个 `record`，封装一条完整的日志信息，包括时间戳、级别、消息、分类、上下文数据等。
    - **全局访问类 (`TLog`)**:
        ```pascal
        type
          TLog = class abstract
          public
            class function GetLogger(const aName: string): TLogger;
            class procedure Info(const aMsg: string);
            class procedure Warn(const aMsg: string);
            // ... 为每个级别提供便捷的静态方法，内部使用根 Logger
          end;
        ```
    - **日志记录器 (`TLogger`)**:
        ```pascal
        type
          TLogger = class
          public
            procedure Log(aLevel: TLogLevel; const aMsg: string);
            procedure Info(const aMsg: string); // 便捷方法
            procedure Warn(const aMsg: string); // 便捷方法
            // ...
          end;
        ```

- [ ] **1.3. 设计 `ILogSink` (日志后端) 接口**
    - @desc: 所有日志输出目标的统一接口。
    - ```pascal
      type
        ILogSink = interface
          procedure Write(const aRecord: TLogRecord);
          procedure Flush;
        end;
      ```

- [ ] **1.4. 实现基础 Sinks**
    - `TConsoleSink`: 将日志以纯文本格式打印到标准输出/错误流。
    - `TFileSink`: 将日志以纯文本格式写入到文件，支持文件滚动（按大小或日期）。

---

### 阶段二: 结构化与异步日志

*目标: 提升日志系统的性能和在生产环境中的实用性。*

- [ ] **2.1. 设计日志格式化器 (`IFormatter`)**
    - @desc: 将 `TLogRecord` 格式化为字符串。Sink 将使用 Formatter 来决定最终的输出格式。
    - `IFormatter = interface function Format(const aRecord: TLogRecord): string; end;`
    - **实现**: `TPlainTextFormatter`, `TJsonFormatter`。

- [ ] **2.2. 实现异步日志 (`TAsyncLogger`)**
    - @desc: 这是提升性能的关键。`TLogger` 在调用 `Log` 方法时，不是直接将记录写入 Sink，而是将其放入一个线程安全的队列中。
    - **核心机制**: 
        - 使用一个后台工作线程。
        - 该线程从队列中取出日志记录，并批量写入到实际的 Sink 中。
        - 使用无锁或低锁队列是性能关键。

---

### 阶段三: 配置与扩展

*目标: 让日志系统变得灵活、易于配置。*

- [ ] **3.1. 设计日志系统配置**
    - @desc: 允许用户通过代码或配置文件来设置日志级别、Sinks 和 Formatters。
    - **示例 (代码配置)**:
        ```pascal
        TLog.Configure
          .SetLevel(TLogLevel.Info)
          .AddSink(TConsoleSink.Create(TPlainTextFormatter.Create))
          .AddSink(TFileSink.Create('app.log', TJsonFormatter.Create))
          .Apply;
        ```

- [ ] **3.2. (可选) 实现更多高级 Sinks**
    - `TSyslogSink`: 通过 UDP 将日志发送到 Syslog 服务器。
    - `TWindowsEventLogSink`: 写入 Windows 事件查看器。

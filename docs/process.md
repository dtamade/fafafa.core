# fafafa.core.process 进程模块设计蓝图 (process.md)

本文档旨在规划和指导 `fafafa.core.process` 模块的实现。该模块的目标是提供一个强大的、跨平台的接口，用于创建、管理子进程，并与其进行异步 I/O 通信。

---

## 核心设计哲学

*   **异步集成**: 进程的生命周期（启动、退出）和 I/O 流都应被无缝集成到 `fafafa.core.async` 的事件循环中。
*   **强大的流处理**: 提供对子进程标准输入、标准输出和标准错误流的完全控制和重定向能力。
*   **跨平台抽象**: 封装 Windows `CreateProcess` 和 POSIX `fork`/`exec` 系列函数在进程创建和管理上的巨大差异。
*   **清晰的 API**: 提供一个配置清晰、易于使用的 API 来启动和管理子进程。

---

## 开发路线图

### 阶段一: 核心进程类与同步执行

*目标: 建立模块的基础，实现进程的同步启动、等待和终止。*

- [ ] **1.1. 创建 `fafafa.core.process.pas` 单元**

- [ ] **1.2. 设计 `TProcessStartInfo` 配置类**
    - @desc: 用于在启动进程前对其进行详细配置。
    - **API 设计**:
        ```pascal
        type
          TProcessStartInfo = class
          public
            FileName: string;
            Arguments: string; // 或 TStringList
            WorkingDirectory: string;
            Environment: TStringList;
            RedirectStandardInput: Boolean;
            RedirectStandardOutput: Boolean;
            RedirectStandardError: Boolean;
            // ... 其他选项，如窗口样式等
          end;
        ```

- [ ] **1.3. 设计 `TProcess` 核心类 (同步部分)**
    - **API 设计**:
        ```pascal
        type
          TProcess = class
          public
            constructor Create(const aStartInfo: TProcessStartInfo);
            procedure Start;
            procedure WaitForExit(aTimeout: Cardinal = INFINITE): Boolean;
            procedure Kill;

            property HasExited: Boolean read GetHasExited;
            property ExitCode: Integer read GetExitCode;
            property ProcessId: TProcessID read GetProcessId;

            // 如果重定向，则提供同步的流访问
            property StandardInput: TStream read GetStandardInput;
            property StandardOutput: TStream read GetStandardOutput;
            property StandardError: TStream read GetStandardError;
          end;
        ```

---

### 阶段二: 异步生命周期与 I/O 集成

*目标: 将进程管理完全融入 `fafafa.core.async` 框架。*

- [ ] **2.1. 将 `TProcess` 改造为异步句柄**
    - @desc: 让 `TProcess` 继承自 `THandle`，以便能被 `TLoop` 管理。
    - **API 变更**:
        ```pascal
        type
          TProcessExitCallback = procedure(const aProcess: TProcess; aExitCode: Int64) of object;

          // TProcess 继承自 THandle
          TProcess = class(THandle)
          public
            constructor Create(aLoop: TLoop; const aStartInfo: TProcessStartInfo);
            procedure Start(aOnExit: TProcessExitCallback);
            // ... Kill 方法依然存在 ...
            // ... WaitForExit 方法可以移除或保留，但不再是主要使用方式 ...
          end;
        ```
    - @remark: `Start` 方法现在接受一个 `OnExit` 回调。当子进程终止时，事件循环会收到通知并执行此回调。

- [ ] **2.2. 实现异步 I/O 流**
    - @desc: 如果启动时配置了重定向，`TProcess` 应提供代表管道 (Pipe) 的异步流句柄。
    - **核心机制**: 在创建子进程时，需要创建匿名管道，并将子进程的标准句柄重定向到这些管道的写端，父进程则持有读端（或反之）。
    - **API 设计** (在 `TProcess` 中):
        ```pascal
        // 属性的类型应为异步流句柄，例如 TPipeStreamHandle (需另行设计)
        property StandardInput: TPipeStreamHandle read GetStandardInput;
        property StandardOutput: TPipeStreamHandle read GetStandardOutput;
        property StandardError: TPipeStreamHandle read GetStandardError;
        ```
    - @remark: `TPipeStreamHandle` 将是一个新的异步句柄类型，类似于 `TTcpSocket`，可以进行异步的 `Read` 和 `Write` 操作。

---

### 阶段三: 单元测试

- [ ] **3.1. 编写 `testcase_process.pas`**
    - [ ] 测试同步启动和 `WaitForExit`。
    - [ ] 测试异步启动和 `OnExit` 回调的正确触发。
    - [ ] 测试标准输出和错误的重定向，并能成功读取子进程的输出。
    - [ ] 测试通过标准输入向子进程写入数据。
    - [ ] 测试 `Kill` 方法。

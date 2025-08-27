# fafafa.core.thread 线程模块设计蓝图 (thread.md)

本文档旨在规划和指导 `fafafa.core.thread` 模块的实现。该模块的目标是提供一套现代化的、跨平台的、易于使用的并发编程工具集，包括线程管理、同步原语和原子操作。

---

## 核心设计哲学

*   **易用性**: 提供比原生 RTL 和操作系统 API 更简洁、更安全的接口。大量使用匿名方法和 RAII 模式简化并发编程。
*   **功能完备**: 涵盖从基础线程控制到高级同步原语和基于 Future/Promise 的线程池。
*   **性能**: 为关键部分（如自旋锁、原子操作）提供高性能实现。
*   **跨平台**: 封装 Windows 和 POSIX 线程 (pthreads) 的差异。

---

## 开发路线图

### 阶段一: 核心线程类与同步原语

*目标: 建立线程模块的基础，实现核心的 `TThread` 类和一套健壮、安全的同步原语。*

- [ ] **1.1. 创建 `fafafa.core.thread.pas` 单元并设计 `TThread` 类**
    - @desc: 对线程的创建、执行和生命周期进行封装，提供现代化的、易于使用的接口。
    - **API 设计**:
        ```pascal
        type
          TThreadProc = procedure;
          TThreadMethod = procedure of object;
          {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
          TThreadRefProc = reference to procedure;
          {$ENDIF}

          TThread = class
          public
            // 构造函数支持过程、对象方法和匿名方法
            constructor Create(const aProc: TThreadProc); overload;
            constructor Create(const aMethod: TThreadMethod); overload;
            {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
            constructor Create(const aRefProc: TThreadRefProc); overload;
            {$ENDIF}

            procedure Start;
            function Join(aTimeout: Cardinal = INFINITE): Boolean; // 等待线程结束，带超时

            property Name: string read GetName write SetName; // 用于在调试器中识别线程
            property ThreadId: TThreadID read GetThreadId;

            class procedure Sleep(aMilliseconds: Cardinal);
            class function GetCurrentThreadId: TThreadID;
          end;
        ```

- [ ] **1.2. 创建 `fafafa.core.thread.sync.pas` 并设计同步原语**
    - **`ILock` 接口**: 为所有锁提供一个统一的接口。
        ```pascal
        type
          ILock = interface
            procedure Acquire;
            procedure Release;
            function TryAcquire(aTimeout: Cardinal = 0): Boolean;
          end;
        ```
    - **`TAutoLock` (RAII)**: **(核心安全机制)** 利用 `record` 的自动生命周期管理，确保锁一定会被释放。
        ```pascal
        type
          TAutoLock = record
          private
            FLock: ILock;
          public
            constructor Create(const aLock: ILock);
            destructor Destroy;
          end;
        // 用法: var LGuard := TAutoLock.Create(MyMutex);
        ```
    - **锁实现**: 所有锁都实现 `ILock` 接口。
        - `TMutex`: 互斥锁。封装 `TCriticalSection` / `pthread_mutex_t`。
        - `TSpinLock`: 自旋锁。用于超短代码路径的保护。
        - `TReadWriteLock`: 读写锁。

---

### 阶段二: 高性能线程池与 Future/Promise 模型

*目标: 实现一个健壮、高效、功能完备的线程池，它不仅能执行简单的过程，还能处理带返回值的函数，并允许对任务进行取消和依赖管理。*

- [ ] **2.1. 创建 `fafafa.core.thread.future.pas` 并设计 Future/Promise**
    - **`IFuture<T>` 接口**: 代表异步操作的未来结果。
        ```pascal
        type
          IFuture<T> = interface
            function IsDone: Boolean;
            function IsCancelled: Boolean;
            function GetValue(aTimeout: Cardinal = INFINITE): T; // 阻塞等待结果
            procedure Cancel;
          end;
        ```
    - **`TPromise<T>` 类**: 用于在工作线程中设置 Future 的结果。
        ```pascal
        type
          TPromise<T> = class
          public
            procedure SetValue(const aValue: T);
            procedure SetException(aException: Exception);
            function GetFuture: IFuture<T>;
          end;
        ```

- [ ] **2.2. 创建 `fafafa.core.thread.pool.pas` 并重新设计 `TThreadPool`**
    - @desc: 维护一个动态伸缩的工作线程池，并能接受返回 `IFuture<T>` 的任务。
    - **API 设计**:
        ```pascal
        type
          TThreadPool = class
          public
            constructor Create(aCoreThreads, aMaxThreads: Integer; aKeepAliveTime: Cardinal);
            destructor Destroy; override;

            // 提交一个无返回值的任务
            procedure Execute(const aProc: TThreadProc);

            // 提交一个带返回值的任务，并立即返回其 Future
            function Submit<T>(const aFunc: TFunc<T>): IFuture<T>;

            property ActiveThreads: Integer read GetActiveThreads;
            property QueuedTasks: Integer read GetQueuedTasks;
          end;
        ```
    - **API 详解**:
        - `constructor`:
            - `aCoreThreads`: 核心线程数，线程池将始终维持至少这么多线程。
            - `aMaxThreads`: 最大线程数，当任务队列饱和时，线程池最多可以创建这么多线程。
            - `aKeepAliveTime`: 当线程数超过核心数时，空闲线程在被回收前可以存活的时间。
        - `Execute`: “即发即忘”式的任务提交，用于不需要返回值的操作。
        - `Submit`: **(核心功能)** 接受一个有返回值的函数，将其包装成一个任务放入队列，并返回一个 `IFuture<T>`。调用者可以随时通过这个 `IFuture<T>` 来获取任务状态或结果。

- [ ] **2.3. 单元测试**
    - [ ] 测试 `Submit` 能否正确返回计算结果。
    - [ ] 测试当工作函数中发生异常时，调用 `Future.GetValue` 能否正确地重新抛出该异常。
    - [ ] 测试 `Future.Cancel` 能否成功取消一个在队列中等待的任务。
    - [ ] 编写多线程压力测试，验证线程池在不同负载下的伸缩和稳定性。

---

### 阶段三: 高级同步原语与原子操作

*目标: 提供构建复杂并发逻辑所需的工具。*

- [ ] **3.1. 在 `fafafa.core.thread.sync.pas` 中实现更多同步原语**
    - `TEvent` / `TManualResetEvent` / `TAutoResetEvent`: 事件。用于线程间的信令通知。
    - `TSemaphore`: 信号量。用于控制对有限资源的并发访问数量。
    - `TConditionVariable`: 条件变量。与互斥锁配合使用，允许线程等待某个特定条件成立。

- [ ] **3.2. 创建 `fafafa.core.thread.atomic.pas` 并设计 `TAtomic` 静态类**
    - @desc: 提供一套跨平台的、无锁的原子操作。
    - **核心机制**: 
        - **Windows**: 使用 `Interlocked...` 系列函数。
        - **GCC/Clang (for POSIX)**: 使用 `__sync_...` 或 `__atomic_...` 内置函数。
    - **API 设计**:
        ```pascal
        type
          TAtomic = class abstract
          public
            class function Increment(var aTarget: Integer): Integer;
            class function Decrement(var aTarget: Integer): Integer;
            class function Add(var aTarget: Integer; aValue: Integer): Integer;
            class function CompareExchange(var aTarget: Pointer; aNewValue, aComperand: Pointer): Pointer;
            // ... 为不同整数类型 (Int32, Int64) 和指针提供重载 ...
          end;
        ```

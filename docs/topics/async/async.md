# fafafa.core.async_io 异步 I/O 框架设计蓝图 (async_io.md)

本文档旨在规划和指导 `fafafa.core` 框架中异步 I/O 功能的实现。其核心目标是借鉴业界顶级库 `libuv` 的设计思想，构建一个高性能、跨平台的事件驱动底层。

---

## 核心设计哲学

*   **事件循环驱动 (Event Loop Driven)**: 所有异步操作都将注册到一个事件循环中，由循环统一调度。
*   **平台抽象**: 封装不同操作系统底层最高效的 I/O 通知机制 (Windows IOCP, Linux epoll, macOS/BSD kqueue)。
*   **非阻塞操作**: 所有 I/O 操作本质上都是非阻塞的。
*   **回调驱动 API**: 初始 API 将以回调（对象方法、匿名方法）为核心，为未来实现 `async/await` 语法糖打下基础。
*   **句柄生命周期管理**: 所有异步对象（句柄）都有明确的、统一的生命周期（`Active` -> `Closing` -> `Closed`），由事件循环安全管理。

---

## 开发路线图

### 阶段一: 事件循环核心与基础设施

*目标: 基于libuv的设计理念，构建适合FreePascal的事件循环系统，提供统一的异步操作基础。*

- [ ] **1.1. 创建核心单元结构**
    - `fafafa.core.async.pas`: 主模块，导出所有公共接口
    - `fafafa.core.async.loop.pas`: 事件循环实现
    - `fafafa.core.async.handle.pas`: 异步句柄基类
    - `fafafa.core.async.timer.pas`: 定时器实现
    - `fafafa.core.async.work.pas`: 工作队列和线程池
    - `fafafa.core.async.future.pas`: Future/Promise实现

- [ ] **1.2. 设计事件循环接口 (`fafafa.core.async.loop.pas`)**

    ```pascal
    // 运行模式
    TLoopRunMode = (
      lrmDefault,    // 运行直到没有活跃句柄
      lrmOnce,       // 运行一次I/O轮询
      lrmNoWait      // 非阻塞运行
    );

    // 事件循环接口
    IEventLoop = interface(IInterface)
    ['{EVENT-LOOP-INTERFACE-GUID}']
      function Run(aMode: TLoopRunMode = lrmDefault): Boolean;
      procedure Stop;

      // 句柄管理
      procedure RegisterHandle(aHandle: IAsyncHandle);
      procedure UnregisterHandle(aHandle: IAsyncHandle);

      // 工作队列
      procedure QueueWork(aWork: IAsyncWork);
      procedure QueueCallback(aCallback: TAsyncCallback);

      // 定时器
      function CreateTimer: IAsyncTimer;

      // 状态查询
      function Now: UInt64;
      function IsAlive: Boolean;
      function GetHandleCount: SizeUInt;

      property HandleCount: SizeUInt read GetHandleCount;
    end;

    // 事件循环实现
    TEventLoop = class(TInterfacedObject, IEventLoop)
    private
      FHandles: TList<IAsyncHandle>;
      FWorkQueue: TQueue<IAsyncWork>;
      FCallbackQueue: TQueue<TAsyncCallback>;
      FTimers: TList<IAsyncTimer>;
      FRunning: Boolean;
      FStopped: Boolean;
      FThreadPool: TThreadPool;
    protected
      procedure ProcessHandles;
      procedure ProcessWork;
      procedure ProcessCallbacks;
      procedure ProcessTimers;
    public
      constructor Create(aThreadPoolSize: Integer = 4);
      destructor Destroy; override;

      function Run(aMode: TLoopRunMode = lrmDefault): Boolean;
      procedure Stop;
      // ... 其他方法实现
    end;
    ```

    *   **`Run(aMode)`**: 启动事件循环。
        *   `@desc`
        *   `lrmDefault`: 持续运行，直到没有任何活动的句柄或调用了 `Stop`。只要有活动句柄，此调用就会阻塞。
        *   `lrmOnce`: 阻塞等待至少一个 I/O 或定时器事件发生，处理与该事件关联的回调，然后返回。如果没有活动句柄，则立即返回 `False`。
        *   `lrmNoWait`: 处理所有已到期的事件，但不阻塞等待新事件。如果没有已到期的事件，则立即返回。
        *   `@return` 返回 `True` 表示循环因仍有活动句柄而退出（例如在 `lrmOnce` 模式下），返回 `False` 表示循环已自然结束（没有任何活动句柄）。
    *   **`Stop`**: 请求停止事件循环。这是一个线程安全的过程，可以从另一个线程调用，以优雅地终止一个正在 `Run` 中阻塞的循环。
    *   **`Now`**: 获取由事件循环缓存的高精度时间戳 (单位: 毫秒)。此时间戳在每次循环迭代开始时更新，在回调中调用可以避免多次查询系统时间，提升性能。
    *   **`IsAlive`**: 检查循环是否仍在运行（即仍有活动的、未关闭的句柄）。

- [ ] **1.3. 设计 `THandle` 基类 (`fafafa.core.async.handle.pas`)**

    ```pascal
    type
      THandle = class abstract
      public
        type
          THandleCallback = procedure(const aHandle: THandle) of object;
      private
        FLoop: TLoop;
        FOnClose: THandleCallback;
        // ... internal state flags
      public
        constructor Create(aLoop: TLoop);
        procedure Close(aOnClose: THandleCallback);

        function IsActive: Boolean;
        function IsClosing: Boolean;

        property Loop: TLoop read FLoop;
      end;
    ```

    *   **`constructor Create(aLoop: TLoop)`**: 所有句柄在创建时必须关联到一个事件循环。
    *   **`Close(aOnClose)`**: 请求关闭句柄。这是一个异步操作。
        *   `@remark` 调用此方法后，句柄立即进入“正在关闭”(`Closing`)状态，不再触发任何事件回调（除了 `aOnClose`）。事件循环将负责安全地释放句柄所占用的所有底层资源，当完全释放后，将调用 `aOnClose` 回调。**严禁**在句柄关闭完成前手动释放句柄对象。
    *   **`IsActive`**: 如果句柄正在运行且能够触发事件，则返回 `True`。
    *   **`IsClosing`**: 如果已经调用了 `Close` 但 `aOnClose` 回调尚未被触发，则返回 `True`。

- [ ] **1.4. 设计 `TTimer` 类 (`fafafa.core.async.timer.pas`)**

    ```pascal
    type
      TTimer = class(THandle)
      public
        type
          TTimerCallback = procedure(const aTimer: TTimer) of object;
      public
        constructor Create(aLoop: TLoop);

        procedure Start(aOnTimeout: TTimerCallback; aTimeout, aRepeat: UInt64);
        procedure Stop;
        procedure Again;
      end;
    ```

    *   **`Start(aOnTimeout; aTimeout; aRepeat)`**: 启动定时器。
        *   `@params`
        *   `aOnTimeout`: 定时器到期时触发的回调。
        *   `aTimeout`: 首次触发的超时时间 (单位: 毫秒)。
        *   `aRepeat`: 如果大于 0，则表示重复周期 (单位: 毫秒)。如果为 0，则定时器只触发一次。
    *   **`Stop`**: 停止定时器。定时器将变为非活动状态，不再触发回调。可以再次调用 `Start` 重启它。
    *   **`Again`**: 如果定时器是重复性的 (`aRepeat > 0`)，调用此方法会立即重置重复计时周期。对于非重复定时器无效。

- [ ] **1.5. 平台实现要点**
    *   **Windows**: 使用 `CreateIoCompletionPort` 作为事件循环核心。对于定时器，使用 `CreateWaitableTimer` 并将其句柄关联到 IOCP。
    *   **Linux**: 使用 `epoll_create1` 作为事件循环核心。对于定时器，使用 `timerfd_create` 创建一个与时间关联的文件描述符，并将其加入 epoll 实例。
    *   **macOS/BSD**: 使用 `kqueue` 作为事件循环核心。对于定时器，直接使用 `kqueue` 的 `EVFILT_TIMER` 事件过滤器，无需创建额外句柄。

- [ ] **1.6. 单元测试 (`testcase_async_timer.pas`)**
    *   [ ] **基础功能**: 测试单次定时器能够在大致准确的时间点触发。
    *   [ ] **重复功能**: 测试重复定时器能够以稳定的周期多次触发。
    *   [ ] **停止功能**: 测试 `TTimer.Stop` 能有效阻止下一次回调，并测试停止后可以被 `Start` 重新激活。
    *   [ ] **零超时**: 测试 `aTimeout = 0` 的定时器会在事件循环的下一个“tick”立即触发。
    *   [ ] **句柄生命周期**: 测试在定时器回调中安全地调用 `Close` 方法，并验证 `OnClose` 回调被正确执行。
    *   [ ] **循环控制**: 测试 `TLoop.Stop` 能否正常停止一个带有一或多个活动定时器的循环。
    *   [ ] **健壮性**: 测试创建大量定时器并随机启停的场景，检查是否存在资源泄露。
unit fafafa.core.sync.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.time.cpu;

type

  {**
   * ESyncError - 同步操作基础异常类
   *
   * @desc
   *   所有同步相关异常的基类。提供统一的异常处理接口，
   *   便于捕获和处理各种同步操作错误。
   *
   * @inheritance
   *   继承自 ECore 类，与框架异常体系保持一致。
   *
   * @usage
   *   try
   *     // 同步操作
   *   except
   *     on E: ESyncError do
   *       // 处理所有同步相关异常
   *   end;
   *}
  ESyncError = class(ECore);

  {**
   * ELockError - 锁操作异常类
   *
   * @desc
   *   锁相关操作的异常基类，包括获取锁失败、释放锁错误等。
   *   继承自 ESyncError，专门处理锁操作中的错误情况。
   *
   * @scenarios
   *   - 尝试释放未持有的锁
   *   - 锁状态不一致
   *   - 锁操作系统调用失败
   *}
  ELockError = class(ESyncError);

  {**
   * ESyncTimeoutError - 同步超时异常类
   *
   * @desc
   *   当同步操作超过指定的超时时间时抛出的异常。
   *   用于区分超时和其他类型的失败。
   *   注意：此类型专用于 sync 模块，与 fafafa.core.base.ETimeoutError 区分。
   *
   * @scenarios
   *   - 带超时的锁获取操作超时
   *   - 等待信号量超时
   *   - 条件变量等待超时
   *}
  ESyncTimeoutError = class(ESyncError);

  {**
   * EDeadlockError - 死锁检测异常类
   *
   * @desc
   *   当检测到潜在的死锁情况时抛出的异常。
   *   某些锁实现可能包含死锁检测机制。
   *
   * @scenarios
   *   - 检测到循环等待
   *   - 同一线程重复获取非重入锁
   *   - 锁获取顺序导致的死锁
   *}
  EDeadlockError = class(ESyncError);

  {**
   * EInvalidArgument - 无效参数异常类
   *
   * @desc
   *   当传递给同步操作的参数无效时抛出的异常。
   *   用于参数验证和错误处理。
   *
   * @scenarios
   *   - 传递 nil 指针
   *   - 超时值为负数
   *   - 无效的锁状态参数
   *}
  EInvalidArgument = class(ESyncError);

  {**
   * EOnceRecursiveCall - 一次性调用递归异常类
   *
   * @desc
   *   当一次性执行的操作被递归调用时抛出的异常。
   *   继承自 ELockError，专门处理 Once 模式的递归调用错误。
   *
   * @scenarios
   *   - Once 初始化函数中递归调用 Once
   *   - 单例模式中的递归初始化
   *   - 一次性资源的重复初始化
   *}
  EOnceRecursiveCall = class(ELockError);


  {**
   * TWaitResult - 等待操作结果枚举
   *
   * @desc
   *   定义同步等待操作的各种可能结果。这个枚举提供了
   *   统一的方式来表示不同类型的等待结果，便于调用者
   *   根据结果采取相应的处理措施。
   *
   * @cross_platform
   *   设计时考虑了跨平台兼容性，包含了 Windows 和 Unix 系统
   *   中可能出现的各种等待结果。
   *
   * @usage
   *   case WaitResult of
   *     wrSignaled: // 成功获取到信号
   *     wrTimeout: // 等待超时
   *     wrAbandoned: // 处理异常情况
   *     wrError: // 处理错误
   *     wrInterrupted: // 处理中断（主要在 Unix 系统）
   *   end;
   *}
  TWaitResult = (
    {**
     * wrSignaled - 信号状态
     *
     * @desc
     *   等待操作成功完成，获取到了期望的信号或资源。
     *   这是正常的成功结果，表示可以继续执行后续操作。
     *
     * @scenarios
     *   - 成功获取到锁
     *   - 信号量计数大于零
     *   - 条件变量被正确信号
     *   - 事件对象被设置为信号状态
     *}
    wrSignaled,

    {**
     * wrTimeout - 超时
     *
     * @desc
     *   等待操作在指定的超时时间内未能完成。
     *   这通常不是错误，而是一种预期的结果。
     *
     * @scenarios
     *   - 锁在超时时间内未被释放
     *   - 信号量在超时时间内计数仍为零
     *   - 条件变量在超时时间内未被信号
     *
     * @handling
     *   调用者应该根据业务逻辑决定是重试、放弃还是采取其他措施。
     *}
    wrTimeout,

    {**
     * wrAbandoned - 被放弃（拥有者异常终止）
     *
     * @desc
     *   等待的资源被其拥有者异常放弃，通常是因为拥有者线程
     *   或进程异常终止而未能正常释放资源。
     *
     * @scenarios
     *   - 持有锁的线程异常终止
     *   - 拥有信号量的进程崩溃
     *   - 互斥对象的拥有者异常退出
     *
     * @handling
     *   这种情况下资源状态可能不一致，需要特别小心处理。
     *   可能需要重新初始化或清理相关状态。
     *}
    wrAbandoned,

    {**
     * wrError - 一般错误
     *
     * @desc
     *   等待操作遇到了一般性错误，无法继续执行。
     *   这通常表示系统级别的问题或参数错误。
     *
     * @scenarios
     *   - 系统资源不足
     *   - 无效的句柄或参数
     *   - 权限不足
     *   - 系统调用失败
     *
     * @handling
     *   应该检查具体的错误原因，可能需要抛出异常或记录错误日志。
     *}
    wrError,

    {**
     * wrInterrupted - 被信号中断（主要用于 Unix 系统）
     *
     * @desc
     *   等待操作被系统信号中断。这主要在 Unix 系统中出现，
     *   当进程收到信号时，阻塞的系统调用可能被中断。
     *
     * @unix_specific
     *   这个结果主要针对 Unix 系统的信号处理机制。
     *   在 Windows 系统中较少使用。
     *
     * @scenarios
     *   - 收到 SIGINT、SIGTERM 等信号
     *   - 用户按 Ctrl+C 中断程序
     *   - 系统发送的其他信号
     *
     * @handling
     *   通常需要检查是否应该重新开始等待，或者优雅地退出程序。
     *}
    wrInterrupted
  );

  {**
   * TWaitError - 等待操作错误类型枚举
   *
   * @desc
   *   定义同步等待操作中可能出现的各种错误类型。
   *   提供比 TWaitResult 更详细的错误分类，便于错误处理和调试。
   *
   * @usage
   *   case LastError of
   *     weNone: // 无错误
   *     weTimeout: // 超时
   *     weInvalidHandle: // 无效句柄
   *     // ... 其他错误处理
   *   end;
   *}
  TWaitError = (
    {**
     * weNone - 无错误
     *
     * @desc 操作成功完成，没有发生任何错误
     *}
    weNone,

    {**
     * weTimeout - 超时
     *
     * @desc 等待操作在指定时间内未能完成
     *}
    weTimeout,

    {**
     * weInvalidHandle - 无效句柄
     *
     * @desc 传递的同步对象句柄无效或已被销毁
     *}
    weInvalidHandle,

    {**
     * weResourceExhausted - 资源耗尽
     *
     * @desc 系统资源不足，无法完成操作
     *}
    weResourceExhausted,

    {**
     * weAccessDenied - 访问被拒绝
     *
     * @desc 没有足够的权限执行操作
     *}
    weAccessDenied,

    {**
     * weDeadlock - 死锁
     *
     * @desc 检测到死锁情况
     *}
    weDeadlock,

    {**
     * weNotSupported - 功能不支持
     *
     * @desc 当前平台或配置不支持此功能
     *}
    weNotSupported,

    {**
     * weSystemError - 系统错误
     *
     * @desc 底层系统调用失败或其他未分类的错误
     *}
    weSystemError,

    {**
     * weInterrupted - 操作被中断
     *
     * @desc 等待操作被信号或其他机制中断
     *}
    weInterrupted,

    {**
     * weInvalidState - 无效状态
     *
     * @desc 对象处于不适合执行操作的状态
     *}
    weInvalidState,

    {**
     * weInvalidParameter - 无效参数
     *
     * @desc 传递的参数无效
     *}
    weInvalidParameter
  );

  {**
   * ISynchronizable - 基础同步原语接口
   *
   * @desc
   *   所有同步对象的基础接口。
   *
   * @warning
   *   Data 属性已标记为 deprecated，不建议在新代码中使用。
   *   如需关联用户数据，建议使用注解或外部映射。
   *}
  ISynchronizable = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']

    {**
     * GetData - 获取同步对象关联的用户数据
     *
     * @deprecated 此方法已废弃。裸指针非线程安全，且无生命周期管理。
     *   仅建议用于调试或初始化阶段的一次性设置。
     *
     * @return 当前关联的用户数据指针，如果未设置则返回 nil
     *
     * @thread_safety
     *   非线程安全。多线程并发读写需由调用方提供外部同步。
     *
     * @memory_management
     *   同步对象不负责管理指向数据的内存，用户需自行管理。
     *}
    function  GetData: Pointer; deprecated 'Unsafe raw pointer, use external mapping instead';

    {**
     * SetData - 设置同步对象关联的用户数据
     *
     * @deprecated 此方法已废弃。裸指针非线程安全，且无生命周期管理。
     *   仅建议用于调试或初始化阶段的一次性设置。
     *
     * @param aData 要关联的用户数据指针
     *
     * @thread_safety
     *   非线程安全。多线程并发写入需外部同步。
     *}
    procedure SetData(aData: Pointer); deprecated 'Unsafe raw pointer, use external mapping instead';

    { @deprecated 裸指针属性，非线程安全，建议使用外部映射 }
    property  Data: Pointer read GetData write SetData;
  end;

  TSynchronizable = class(TInterfacedObject, ISynchronizable)
  private
    FData: Pointer;  // 用户关联数据指针
  public
    // 内联实现：高性能的数据访问器方法
    function  GetData: Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    procedure SetData(aData: Pointer); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

  {**
   * IGuard - 通用守护接口（所有 Guard 的基接口）
   *
   * @desc
   *   为所有同步原语提供统一的 RAII 守护机制基接口。
   *   所有具体 Guard（如 ILockGuard, IRWLockReadGuard 等）都继承此接口。
   *
   * @rust_equivalent
   *   类似 Rust 各种 Guard 类型的公共 trait
   *
   * @usage
   *   var
   *     Guards: array of IGuard;
   *   begin
   *     // 支持多态：不同类型 Guard 可以存储在 IGuard 数组中
   *     SetLength(Guards, 2);
   *     Guards[0] := Mutex.Lock as IGuard;
   *     Guards[1] := RWLock.Read as IGuard;
   *   end;
   *}
  IGuard = interface
    ['{F1E2D3C4-B5A6-9780-CDEF-123456789ABC}']

    {**
     * IsLocked - 检查守护是否仍持有锁
     *
     * @return True 如果锁仍被持有，False 如果已释放
     *}
    function IsLocked: Boolean;

    {**
     * Release - 释放守护持有的锁
     *
     * @desc
     *   手动释放锁。多次调用是安全的（幂等）。
     *}
    procedure Release;

    {**
     * Unlock - 释放守护持有的锁（Release 的别名）
     *
     * @desc
     *   与 Release 功能相同，提供更直观的 API（与 Lock 对称）。
     *   多次调用是安全的（幂等）。
     *
     * @usage
     *   var guard := mutex.Lock();
     *   try
     *     // 临界区代码
     *   finally
     *     guard.Unlock();  // 或 guard.Release()
     *   end;
     *
     * @note
     *   此方法是 Release 的别名，两者功能完全相同。
     *   推荐使用 Unlock，因为它与 Lock 更对称。
     *}
    procedure Unlock;
  end;

  ILockGuard = interface(IGuard)
    ['{A8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    // 继承 IGuard 的 IsLocked 和 Release
  end;

  {**
   * ILock - 基础锁接口
   *
   * @desc
   *   定义了完整的锁操作功能，包括阻塞获取、非阻塞尝试和带超时尝试。
   *   这是所有锁类型的基础接口，提供传统 API 和现代 RAII API。
   *
   * @inheritance
   *   继承自 ISynchronizable，具备用户数据关联能力。
   *
   * @thread_model
   *   支持多线程环境下的互斥访问控制。
   *   一次只允许一个线程持有锁。
   *
   * @implementations
   *   - 互斥锁 (Mutex): 适合一般用途的锁
   *   - 自旋锁 (SpinLock): 适合短期持有的高性能锁
   *   - 读写锁 (RWLock): 支持多读单写的锁
   *
   * @modern_api
   *   推荐使用现代化 API（Rust 风格）：
   *   - Lock() / TryLock() / TryLockFor() 返回 Guard
   *   - 使用 RAII 模式自动管理锁的生命周期
   *
   * @usage_pattern
   *   // 现代用法 - 推荐
   *   var Guard := Lock.Lock;
   *   // 临界区代码
   *   // Guard 超出作用域时自动释放
   *
   *   // 带超时的现代用法
   *   var Guard := Lock.TryLockFor(1000);  // 1秒超时
   *   if Assigned(Guard) then
   *   begin
   *     // 临界区代码
   *   end;
   *
   *   // 传统用法 - 仍然支持
   *   Lock.Acquire;
   *   try
   *     // 临界区代码
   *   finally
   *     Lock.Release;
   *   end;
   *
   * @thread_safety 线程安全
   * @rust_equivalent std::sync::Mutex (部分)
   * @java_equivalent java.util.concurrent.locks.Lock
   *}
  ILock = interface(ISynchronizable)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']

    // ===== 现代化 API（Rust 风格）- 推荐使用 =====

    {**
     * Lock - 阻塞获取锁并返回 RAII 守卫
     *
     * @return 锁守卫接口，超出作用域时自动释放锁
     *
     * @desc
     *   阻塞式获取锁，返回 RAII 风格的守卫对象。
     *   这是推荐的锁获取方式，比 Acquire/Release 更安全。
     *
     * @blocking
     *   这是一个阻塞操作。如需非阻塞，使用 TryLock。
     *
     * @thread_safety
     *   线程安全。
     *
     * @rust_equivalent
     *   类似 Rust 的 Mutex::lock()
     *
     * @usage
     *   var Guard := Lock.Lock;
     *   // 临界区代码
     *   // Guard 超出作用域时自动释放
     *}
    function Lock: ILockGuard;

    {**
     * TryLock - 非阻塞尝试获取锁
     *
     * @return 成功返回锁守卫，失败返回 nil
     *
     * @desc
     *   尝试立即获取锁，不阻塞。成功返回 Guard，失败返回 nil。
     *
     * @nonblocking
     *   立即返回，不会阻塞线程。
     *
     * @rust_equivalent
     *   类似 Rust 的 Mutex::try_lock()
     *
     * @usage
     *   var Guard := Lock.TryLock;
     *   if Assigned(Guard) then
     *   begin
     *     // 成功获取锁
     *     // 临界区代码
     *   end
     *   else
     *     // 锁不可用，执行替代逻辑
     *}
    function TryLock: ILockGuard;

    {**
     * TryLockFor - 带超时的尝试获取锁
     *
     * @param ATimeoutMs 超时时间（毫秒），0 表示立即返回
     * @return 成功返回锁守卫，超时返回 nil
     *
     * @desc
     *   在指定时间内尝试获取锁。如果超时仍未获取到锁，返回 nil。
     *
     * @timeout
     *   超时时间以毫秒为单位。0 表示立即返回（等价于 TryLock）。
     *
     * @rust_equivalent
     *   类似 Rust 的 Mutex::try_lock_for()
     *
     * @usage
     *   var Guard := Lock.TryLockFor(1000);  // 1秒超时
     *   if Assigned(Guard) then
     *   begin
     *     // 成功获取锁
     *     // 临界区代码
     *   end
     *   else
     *     // 超时，锁不可用
     *}
    function TryLockFor(ATimeoutMs: Cardinal): ILockGuard;

    // ===== 传统 API - 为兼容性保留 =====

    {**
     * Acquire - 获取锁（传统 API）
     *
     * @desc
     *   阻塞式获取锁。如果锁当前被其他线程持有，
     *   当前线程将阻塞等待直到成功获取锁。
     *
     * @blocking
     *   这是一个阻塞操作，可能导致线程挂起。
     *   如果需要非阻塞操作，请使用 TryAcquire。
     *
     * @thread_safety
     *   线程安全，可以从多个线程同时调用。
     *   但同一时刻只有一个线程能成功获取锁。
     *
     * @reentrancy
     *   大多数实现不支持重入，同一线程重复调用可能导致死锁。
     *   具体行为取决于实现类型。
     *
     * @exception
     *   某些实现可能在错误情况下抛出异常，
     *   如系统资源不足或检测到死锁。
     *
     * @performance
     *   性能取决于具体实现：
     *   - 互斥锁：中等性能，适合一般用途
     *   - 自旋锁：高性能，适合短期持有
     *   - 读写锁：读操作高性能，写操作中等性能
     *
     * @usage
     *   Lock.Acquire;
     *   try
     *     // 临界区代码 - 只有一个线程能执行
     *     SharedResource.DoSomething;
     *   finally
     *     Lock.Release;  // 确保锁被释放
     *   end;
     *
     * @deprecated_hint
     *   推荐使用 Lock() 方法代替，它返回 RAII 守卫更安全。
     *}
    procedure Acquire;

    {**
     * Release - 释放锁（传统 API）
     *
     * @desc
     *   释放当前线程持有的锁，允许其他等待的线程获取锁。
     *   必须由持有锁的线程调用。
     *
     * @thread_safety
     *   线程安全，但必须由持有锁的线程调用。
     *   从非持有线程调用可能导致未定义行为。
     *
     * @precondition
     *   调用前当前线程必须已经通过 Acquire 获取了锁。
     *   在未持有锁的情况下调用可能导致异常或未定义行为。
     *
     * @postcondition
     *   调用后锁被释放，等待的线程可能被唤醒。
     *   当前线程不再持有锁。
     *
     * @exception
     *   某些实现可能在错误情况下抛出异常，
     *   如检测到非持有线程调用或重复释放。
     *
     * @performance
     *   通常是一个快速操作，但可能涉及线程唤醒开销。
     *
     * @usage
     *   Lock.Acquire;
     *   try
     *     // 临界区代码
     *   finally
     *     Lock.Release;  // 必须在 finally 中确保释放
     *   end;
     *
     * @best_practice
     *   总是在 try-finally 块中使用，确保异常情况下锁也能被释放。
     *   或者使用 RAII 模式的 Lock() 方法。
     *
     * @deprecated_hint
     *   推荐使用 Lock() 返回的 Guard，它会自动释放锁。
     *}
    procedure Release;

    {**
     * TryAcquire - 非阻塞尝试获取锁（传统 API）
     *
     * @return True 如果成功获取锁，False 如果锁当前被其他线程持有
     *
     * @desc
     *   尝试立即获取锁，不阻塞。成功返回 True，失败返回 False。
     *
     * @nonblocking
     *   立即返回，不会阻塞线程。
     *
     * @usage
     *   if Lock.TryAcquire then
     *   try
     *     // 成功获取锁，临界区代码
     *   finally
     *     Lock.Release;
     *   end
     *   else
     *     // 锁不可用，执行替代逻辑
     *
     * @deprecated_hint
     *   推荐使用 TryLock() 方法代替，它返回 RAII 守卫更安全。
     *}
    function TryAcquire: Boolean; overload;

    {**
     * TryAcquire - 带超时的尝试获取锁（传统 API）
     *
     * @param ATimeoutMs 超时时间（毫秒），0 表示立即返回
     * @return True 如果在超时时间内成功获取锁，False 如果超时
     *
     * @desc
     *   在指定时间内尝试获取锁。如果超时仍未获取到锁，返回 False。
     *
     * @timeout
     *   超时时间以毫秒为单位。0 表示立即返回（等价于 TryAcquire()）。
     *
     * @usage
     *   if Lock.TryAcquire(1000) then  // 1秒超时
     *   try
     *     // 成功获取锁，临界区代码
     *   finally
     *     Lock.Release;
     *   end
     *   else
     *     // 超时，锁不可用
     *
     * @deprecated_hint
     *   推荐使用 TryLockFor() 方法代替，它返回 RAII 守卫更安全。
     *}
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;

    {**
     * LockGuard - 创建 RAII 锁守卫（兼容别名）
     *
     * @return 锁守卫接口，自动管理锁的生命周期
     *
     * @desc
     *   等同于 Lock() 方法，为向后兼容保留。
     *   推荐使用 Lock() 方法，命名更符合现代风格。
     *
     * @rust_equivalent
     *   类似 Rust 的 Mutex::lock()
     *
     * @usage_simple
     *   // 简单用法 - 推荐
     *   with Lock.LockGuard do
     *   begin
     *     // 临界区代码
     *     // 锁在 with 块结束时自动释放
     *   end;
     *
     * @usage_variable
     *   // 变量用法 - 更灵活的控制
     *   var
     *     Guard: ILockGuard;
     *   begin
     *     Guard := Lock.LockGuard;
     *     try
     *       // 临界区代码
     *       if SomeCondition then
     *         Guard.Release;  // 可以提前释放
     *     finally
     *       Guard := nil;  // 确保释放（通常不需要）
     *     end;
     *   end;
     *
     * @vs_manual
     *   相比手动管理的优势：
     *   - 更安全：不会忘记释放锁
     *   - 更简洁：减少 try-finally 样板代码
     *   - 异常安全：异常情况下自动释放
     *   - 作用域绑定：锁的生命周期与代码块绑定
     *
     * @best_practice
     *   - 优先使用 with 语句，代码最简洁
     *   - 避免长时间持有守卫对象
     *   - 在需要条件释放时使用变量方式
     *   - 不要在多个线程间传递守卫对象
     *}
    function  LockGuard: ILockGuard;
  end;

  {**
   * TLock - 基础锁抽象类
   *
   * @desc
   *   实现 ILock 接口的抽象基类，提供锁的基本框架。
   *   继承自 TSynchronizable，具备用户数据关联能力。
   *   子类必须实现具体的 Acquire、Release 和 TryAcquire 方法。
   *
   * @abstract
   *   这是一个抽象类，不能直接实例化。
   *   Acquire、Release 和 TryAcquire 方法必须由子类实现。
   *
   * @inheritance_hierarchy
   *   TLock -> TTryLock -> 具体锁实现（如 TMutex, TSpinLock 等）
   *
   * @provided_functionality
   *   - 用户数据关联（继承自 TSynchronizable）
   *   - RAII 锁守卫创建（Lock、TryLock、TryLockFor 方法）
   *   - 接口实现框架
   *
   * @subclass_responsibility
   *   子类必须实现：
   *   - Acquire: 获取锁的具体逻辑
   *   - Release: 释放锁的具体逻辑
   *   - TryAcquire: 非阻塞尝试获取锁的具体逻辑
   *   - TryAcquire(ATimeoutMs): 带超时尝试获取锁的具体逻辑
   *}
  TLock = class(TSynchronizable, ILock)
  public
    {**
     * Acquire - 获取锁（抽象方法）
     *
     * @desc
     *   抽象方法，子类必须实现具体的锁获取逻辑。
     *   通常是阻塞式操作，直到成功获取锁为止。
     *
     * @abstract
     *   必须由子类重写实现。
     *}
    procedure Acquire; virtual; abstract;

    {**
     * Release - 释放锁（抽象方法）
     *
     * @desc
     *   抽象方法，子类必须实现具体的锁释放逻辑。
     *   必须由持有锁的线程调用。
     *
     * @abstract
     *   必须由子类重写实现。
     *}
    procedure Release; virtual; abstract;

    {**
     * TryAcquire - 非阻塞尝试获取锁（抽象方法）
     *
     * @return True 如果成功获取锁，False 如果锁当前被其他线程持有
     *
     * @desc
     *   抽象方法，子类必须实现具体的非阻塞尝试逻辑。
     *
     * @abstract
     *   必须由子类重写实现。
     *}
    function TryAcquire: Boolean; overload; virtual; abstract;

    {**
     * TryAcquire - 带超时的尝试获取锁（虚方法）
     *
     * @param ATimeoutMs 超时时间（毫秒），0 表示立即返回
     * @return True 如果在超时时间内成功获取锁，False 如果超时
     *
     * @desc
     *   基类实现使用简单的轮询策略。
     *   子类（如 TTryLock）应重写此方法提供更高效的实现。
     *}
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; virtual;

    {**
     * Lock - 阻塞获取锁并返回 RAII 守卫
     *
     * @return 锁守卫接口，超出作用域时自动释放锁
     *
     * @desc
     *   阻塞式获取锁，返回 RAII 风格的守卫对象。
     *   这是推荐的锁获取方式。
     *}
    function Lock: ILockGuard; virtual;

    {**
     * TryLock - 非阻塞尝试获取锁
     *
     * @return 成功返回锁守卫，失败返回 nil
     *
     * @desc
     *   尝试立即获取锁，不阻塞。成功返回 Guard，失败返回 nil。
     *}
    function TryLock: ILockGuard; virtual;

    {**
     * TryLockFor - 带超时的尝试获取锁
     *
     * @param ATimeoutMs 超时时间（毫秒），0 表示立即返回
     * @return 成功返回锁守卫，超时返回 nil
     *
     * @desc
     *   在指定时间内尝试获取锁。如果超时仍未获取到锁，返回 nil。
     *}
    function TryLockFor(ATimeoutMs: Cardinal): ILockGuard; virtual;

    {**
     * LockGuard - 创建 RAII 锁守卫（兼容别名）
     *
     * @return 锁守卫接口，自动管理锁的生命周期
     *
     * @desc
     *   等同于 Lock() 方法，为向后兼容保留。
     *
     * @deprecated 使用 Lock() 方法代替
     *}
    function  LockGuard: ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF} deprecated 'Use Lock() instead';
  end;

  {**
   * TLockClass - 锁类的类引用类型
   *
   * @desc
   *   TLock 类的类引用类型，用于动态创建锁实例。
   *   支持工厂模式和插件化的锁实现选择。
   *
   * @usage
   *   var
   *     LockClass: TLockClass;
   *     Lock: TLock;
   *   begin
   *     LockClass := TMutex; // 或其他锁实现
   *     Lock := LockClass.Create;
   *   end;
   *}
  TLockClass = class of TLock;

  {**
   * ITryLock - 支持超时尝试的锁接口（已废弃）
   *
   * @deprecated 使用 ILock 接口代替，ILock 现在包含所有锁操作
   *
   * @desc
   *   此接口已废弃，所有方法已移至 ILock 接口。
   *   为保持向后兼容性，此接口仍然存在，但新代码应使用 ILock。
   *
   * @migration
   *   将所有 ITryLock 引用替换为 ILock：
   *   - 旧代码：var Lock: ITryLock;
   *   - 新代码：var Lock: ILock;
   *   代码行为保持不变，编译器会发出废弃警告。
   *
   * @removal_timeline
   *   此接口将在未来版本中移除，请尽快迁移到 ILock。
   *}
  ITryLock = interface(ILock)
    ['{C8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    // 所有方法已移至 ILock 接口
    // 此接口保留仅为向后兼容
  end deprecated 'Use ILock instead - all methods are now in ILock';

  {**
   * ITryLockTuning - 三段式等待策略调优接口
   *
   * @desc
   *   提供对 ITryLock 内部三段式等待策略的精细调优控制。
   *   大多数用户不需要使用此接口，默认参数适合大多数场景。
   *
   * @usage
   *   var Lock: ITryLock := MakeMutex;
   *   // 如需调优：
   *   var Tuning: ITryLockTuning;
   *   if Supports(Lock, ITryLockTuning, Tuning) then
   *   begin
   *     Tuning.TightSpin := 5000;
   *     Tuning.BlockSleepIntervalMs := 2;
   *   end;
   *}
  ITryLockTuning = interface
    ['{D9E5A3F2-5B4C-4F3A-AB2E-9D8C7B6A5E4F}']

    function  GetTightSpin: UInt32;
    procedure SetTightSpin(Value: UInt32);
    function  GetTightTimeCheckIntervalSpin: UInt32;
    procedure SetTightTimeCheckIntervalSpin(Value: UInt32);
    function  GetBackOffSpin: UInt32;
    procedure SetBackOffSpin(Value: UInt32);
    function  GetBackOffTimeCheckIntervalSpin: UInt32;
    procedure SetBackOffTimeCheckIntervalSpin(Value: UInt32);
    function  GetBackOffYieldIntervalSpin: UInt32;
    procedure SetBackOffYieldIntervalSpin(Value: UInt32);
    function  GetBlockSpin: UInt32;
    procedure SetBlockSpin(Value: UInt32);
    function  GetBlockTimeCheckIntervalSpin: UInt32;
    procedure SetBlockTimeCheckIntervalSpin(Value: UInt32);
    function  GetBlockSleepIntervalMs: UInt32;
    procedure SetBlockSleepIntervalMs(Value: UInt32);

    { TightSpin - 紧密自旋阶段的最大自旋次数 (默认 2000) }
    property TightSpin: UInt32 read GetTightSpin write SetTightSpin;
    { TightTimeCheckIntervalSpin - 紧密自旋阶段的超时检查间隔 (默认 1023) }
    property TightTimeCheckIntervalSpin: UInt32 read GetTightTimeCheckIntervalSpin write SetTightTimeCheckIntervalSpin;
    { BackOffSpin - 退避阶段的最大自旋次数 (默认 50) }
    property BackOffSpin: UInt32 read GetBackOffSpin write SetBackOffSpin;
    { BackOffTimeCheckIntervalSpin - 退避阶段的超时检查间隔 (默认 1023) }
    property BackOffTimeCheckIntervalSpin: UInt32 read GetBackOffTimeCheckIntervalSpin write SetBackOffTimeCheckIntervalSpin;
    { BackOffYieldIntervalSpin - 退避阶段的 CPU 让出间隔 (默认 8191) }
    property BackOffYieldIntervalSpin: UInt32 read GetBackOffYieldIntervalSpin write SetBackOffYieldIntervalSpin;
    { BlockSpin - 阻塞阶段的最大自旋次数 (默认 1000) }
    property BlockSpin: UInt32 read GetBlockSpin write SetBlockSpin;
    { BlockTimeCheckIntervalSpin - 阻塞阶段的超时检查间隔 (默认 1023) }
    property BlockTimeCheckIntervalSpin: UInt32 read GetBlockTimeCheckIntervalSpin write SetBlockTimeCheckIntervalSpin;
    { BlockSleepIntervalMs - 阻塞阶段的睡眠间隔毫秒 (默认 1) }
    property BlockSleepIntervalMs: UInt32 read GetBlockSleepIntervalMs write SetBlockSleepIntervalMs;
  end;


  TTryLock = class(TLock, ITryLock, ITryLockTuning)
  private
    FTightSpin:                    UInt32;
    FTightTimeCheckIntervalSpin:   UInt32;

    FBackOffSpin:                  UInt32;
    FBackOffTimeCheckIntervalSpin: UInt32;
    FBackOffYieldIntervalSpin:     UInt32;

    FBlockSpin:                    UInt32;
    FBlockTimeCheckIntervalSpin:   UInt32;
    FBlockSleepIntervalMs:         UInt32;
  public
    // ===== 现代化 API 实现 =====

    {**
     * TryLock - 非阻塞尝试获取锁（重写基类）
     *
     * @return 成功返回锁守卫，失败返回 nil
     *}
    function TryLock: ILockGuard; override;

    {**
     * TryLockFor - 带超时的尝试获取锁
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return 成功返回锁守卫，超时返回 nil
     *}
    function TryLockFor(ATimeoutMs: Cardinal): ILockGuard; reintroduce; virtual;
  protected
    {**
     * GetDefaultTightSpin - 获取紧密自旋阶段的默认最大自旋次数
     *
     * @return 默认的紧密自旋次数，通常为 2000
     *
     * @desc
     *   返回紧密自旋阶段的默认配置值。子类可以重写此方法
     *   来提供针对特定锁类型优化的默认值。
     *
     * @virtual
     *   虚方法，允许子类根据锁的特性提供不同的默认值。
     *   例如，自旋锁可能使用更大的值，而互斥锁使用较小的值。
     *}
    function GetDefaultTightSpin: UInt32; virtual;

    {**
     * GetDefaultTightTimeCheckIntervalSpin - 获取紧密自旋阶段的默认超时检查间隔
     *
     * @return 默认的超时检查间隔，通常为 1023 (1024-1)
     *
     * @desc
     *   返回紧密自旋阶段超时检查的默认间隔。使用 2^n-1 的值
     *   可以利用位运算优化取模操作。
     *}
    function GetDefaultTightTimeCheckIntervalSpin: UInt32; virtual;

    {**
     * GetDefaultBackOffSpin - 获取退避阶段的默认最大自旋次数
     *
     * @return 默认的退避自旋次数，通常为 50
     *
     * @desc
     *   返回退避阶段的默认配置值。这个阶段的自旋次数通常
     *   比紧密自旋阶段少，以减少 CPU 占用。
     *}
    function GetDefaultBackOffSpin: UInt32; virtual;

    {**
     * GetDefaultBackOffTimeCheckIntervalSpin - 获取退避阶段的默认超时检查间隔
     *
     * @return 默认的超时检查间隔，通常为 1023 (1024-1)
     *}
    function GetDefaultBackOffTimeCheckIntervalSpin: UInt32; virtual;

    {**
     * GetDefaultBackOffYieldIntervalSpin - 获取退避阶段的默认 CPU 让出间隔
     *
     * @return 默认的 CPU 让出间隔，通常为 8191 (8192-1)
     *
     * @desc
     *   返回退避阶段 CPU 让出操作的默认间隔。较大的值意味着
     *   较少的 CPU 让出，可能提高性能但增加系统负载。
     *}
    function GetDefaultBackOffYieldIntervalSpin: UInt32; virtual;

    {**
     * GetDefaultBlockSpin - 获取阻塞阶段的默认最大自旋次数
     *
     * @return 默认的阻塞自旋次数，通常为 1000
     *
     * @desc
     *   返回阻塞阶段的默认配置值。这个阶段主要依赖睡眠，
     *   自旋只是睡眠间隙的补充尝试。
     *}
    function GetDefaultBlockSpin: UInt32; virtual;

    {**
     * GetDefaultBlockTimeCheckIntervalSpin - 获取阻塞阶段的默认超时检查间隔
     *
     * @return 默认的超时检查间隔，通常为 1023 (1024-1)
     *}
    function GetDefaultBlockTimeCheckIntervalSpin: UInt32; virtual;

    {**
     * GetDefaultBlockSleepIntervalMs - 获取阻塞阶段的默认睡眠间隔
     *
     * @return 默认的睡眠间隔（毫秒），通常为 1
     *
     * @desc
     *   返回阻塞阶段睡眠操作的默认间隔。1毫秒是一个平衡的选择，
     *   既保证了合理的响应性，又有效减少了 CPU 占用。
     *}
    function GetDefaultBlockSleepIntervalMs: UInt32; virtual;

    function DoTight: Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function DoTight(aEndTick: UInt64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

    function DoBackOffNoCheckNoYield: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function DoBackOffNoCheck: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function DoBackOffNoYield(aEndTick: UInt64): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function DoBackOff(aEndTick: UInt64): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

    function DoBlock: Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function DoBlock(aEndTick: UInt64) :Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  public
    constructor Create; virtual;

    function TryAcquire: Boolean; reintroduce; overload; virtual; abstract;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; reintroduce; overload; virtual;


    function  GetTightSpin: UInt32;
    procedure SetTightSpin(Value: UInt32);

    function  GetTightTimeCheckIntervalSpin: UInt32;
    procedure SetTightTimeCheckIntervalSpin(Value: UInt32);

    function  GetBackOffSpin: UInt32;
    procedure SetBackOffSpin(Value: UInt32);

    function  GetBackOffTimeCheckIntervalSpin: UInt32;
    procedure SetBackOffTimeCheckIntervalSpin(Value: UInt32);

    function  GetBackOffYieldIntervalSpin: UInt32;
    procedure SetBackOffYieldIntervalSpin(Value: UInt32);

    function  GetBlockSpin: UInt32;
    procedure SetBlockSpin(Value: UInt32);

    function  GetBlockTimeCheckIntervalSpin: UInt32;
    procedure SetBlockTimeCheckIntervalSpin(Value: UInt32);

    function  GetBlockSleepIntervalMs: UInt32;
    procedure SetBlockSleepIntervalMs(Value: UInt32);


    property TightSpin:                    UInt32 read GetTightSpin write SetTightSpin;
    property TightTimeCheckIntervalSpin:   UInt32 read GetTightTimeCheckIntervalSpin write SetTightTimeCheckIntervalSpin;

    property BackOffSpin:                  UInt32 read GetBackOffSpin write SetBackOffSpin;
    property BackOffTimeCheckIntervalSpin: UInt32 read GetBackOffTimeCheckIntervalSpin write SetBackOffTimeCheckIntervalSpin;
    property BackOffYieldIntervalSpin:     UInt32 read GetBackOffYieldIntervalSpin write SetBackOffYieldIntervalSpin;

    property BlockSpin:                    UInt32 read GetBlockSpin write SetBlockSpin;
    property BlockTimeCheckIntervalSpin:   UInt32 read GetBlockTimeCheckIntervalSpin write SetBlockTimeCheckIntervalSpin;
    property BlockSleepIntervalMs:         UInt32 read GetBlockSleepIntervalMs write SetBlockSleepIntervalMs;

  end;


  {**
   * TLockGuard - RAII 风格的锁守卫实现
   *
   * @desc
   *   实现 ILockGuard 接口的具体类，提供 RAII (Resource Acquisition Is Initialization)
   *   风格的锁管理。锁守卫在创建时自动获取锁，在析构时自动释放锁，
   *   确保即使在异常情况下锁也能被正确释放。
   *
   * @raii_pattern
   *   RAII 模式的核心优势：
   *   - 自动资源管理：构造时获取，析构时释放
   *   - 异常安全：即使发生异常也能正确释放资源
   *   - 作用域绑定：资源生命周期与对象作用域绑定
   *   - 减少错误：避免忘记释放资源的问题
   *
   * @thread_safety
   *   线程安全，但每个守卫实例只能在创建它的线程中使用。
   *   不要在多个线程间传递守卫对象。
   *
   * @usage_pattern
   *   // 推荐用法 - with 语句
   *   with Lock.LockGuard do
   *   begin
   *     // 临界区代码
   *   end; // 锁在此处自动释放
   *
   *   // 变量用法 - 更灵活的控制
   *   var Guard: ILockGuard;
   *   begin
   *     Guard := TLockGuard.Create(Lock);
   *     try
   *       // 临界区代码
   *     finally
   *       Guard := nil; // 触发析构，释放锁
   *     end;
   *   end;
   *}
  TLockGuard = class(TInterfacedObject, ILockGuard)
  private
    FLock: ILock;        // 被守卫的锁对象
    FReleased: Boolean;  // 标记锁是否已被释放，防止重复释放
  public
    function IsLocked: Boolean;
    {**
     * Create - 创建锁守卫并获取锁
     *
     * @param ALock 要守卫的锁对象
     *
     * @desc
     *   创建锁守卫并立即获取指定的锁。这是标准的 RAII 构造方式，
     *   适用于大多数场景。
     *
     * @blocking
     *   此构造函数会阻塞直到成功获取锁。
     *
     * @exception
     *   如果锁获取失败，可能抛出相应的异常。
     *}
    constructor Create(ALock: ILock);

    {**
     * CreateFromAcquired - 从已获取的锁创建守卫
     *
     * @param ALock 已经获取的锁对象
     *
     * @desc
     *   从已经获取的锁创建守卫。这种方式适用于锁已经通过其他方式获取，
     *   但希望使用 RAII 模式管理其释放的场景。
     *
     * @precondition
     *   调用前 ALock 必须已经被当前线程获取。
     *
     * @responsibility
     *   守卫将负责在析构时释放锁，即使锁不是由守卫获取的。
     *}
    constructor CreateFromAcquired(ALock: ILock);

    {**
     * Destroy - 析构函数，自动释放锁
     *
     * @desc
     *   析构时自动调用 Release 方法释放锁。这是 RAII 模式的核心，
     *   确保锁在守卫对象销毁时被正确释放。
     *
     * @automatic
     *   通常不需要手动调用，当守卫对象超出作用域或被设为 nil 时自动调用。
     *}
    destructor Destroy; override;

    {**
     * Release - 手动释放锁
     *
     * @desc
     *   手动释放守卫持有的锁。通常情况下锁会在析构时自动释放，
     *   但此方法允许提前手动释放。
     *
     * @idempotent
     *   多次调用是安全的，重复释放不会产生副作用。
     *
     * @inline
     *   使用内联优化，确保最佳性能。
     *}
    procedure Release; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

    {**
     * Unlock - 手动释放锁（Release 的别名）
     *
     * @desc
     *   与 Release 功能相同，提供更直观的 API（与 Lock 对称）。
     *   手动释放守卫持有的锁。
     *
     * @idempotent
     *   多次调用是安全的，重复释放不会产生副作用。
     *
     * @inline
     *   使用内联优化，确保最佳性能。
     *}
    procedure Unlock; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

{**
 * MakeLockGuard - 创建锁守卫的向后兼容函数
 *
 * @param ALock 要守卫的锁对象
 * @return 锁守卫接口
 *}
function MakeLockGuard(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF} // 向后兼容

{**
 * MakeLockGuardFromAcquired - 从已获取的锁创建守卫
 *
 * @param ALock 已经获取的锁对象
 * @return 锁守卫接口
 *
 * @desc
 *   从已经获取的锁创建守卫。适用于锁已经通过其他方式获取，
 *   但希望使用 RAII 模式管理其释放的场景。
 *
 * @precondition
 *   调用前 ALock 必须已经被当前线程获取。
 *
 * @usage
 *   Lock.Acquire;
 *   var Guard := MakeLockGuardFromAcquired(Lock);
 *   // 守卫将负责释放锁
 *
 * @inline
 *   使用内联优化，确保最佳性能。
 *}
function MakeLockGuardFromAcquired(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function MakeLockGuard(ALock: ILock): ILockGuard;
begin
  Result := TLockGuard.Create(ALock);
end;

function MakeLockGuardFromAcquired(ALock: ILock): ILockGuard;
begin
  Result := TLockGuard.CreateFromAcquired(ALock);
end;

{ TLockGuard }

constructor TLockGuard.Create(ALock: ILock);
begin
  inherited Create;
  FLock     := ALock;
  FReleased := False;
  FLock.Acquire;
end;

constructor TLockGuard.CreateFromAcquired(ALock: ILock);
begin
  inherited Create;
  FLock     := ALock;
  FReleased := False;
end;

destructor TLockGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

function TLockGuard.IsLocked: Boolean;
begin
  Result := (not FReleased) and Assigned(FLock);
end;

procedure TLockGuard.Release;
begin
  if not FReleased and Assigned(FLock) then
  begin
    FLock.Release;
    FReleased := True;
  end;
end;

procedure TLockGuard.Unlock;
begin
  // Unlock 是 Release 的别名，直接调用 Release
  Release;
end;


{ TSynchronizable - 基础同步对象实现 }

{**
 * TSynchronizable.GetData - 获取用户数据的内联实现
 *
 * @desc
 *   简单直接地返回存储的用户数据指针。
 *   使用内联优化，确保最佳性能。
 *}
function TSynchronizable.GetData: Pointer;
begin
  // 直接返回存储的用户数据指针
  Result := FData;
end;

{**
 * TSynchronizable.SetData - 设置用户数据的内联实现
 *
 * @desc
 *   简单直接地存储用户数据指针。
 *   不进行任何验证或内存管理，保持最高性能。
 *
 * @note
 *   此实现不是原子操作，如果需要线程安全的数据设置，
 *   子类应该重写此方法并添加适当的同步机制。
 *}
procedure TSynchronizable.SetData(aData: Pointer);
begin
  // 直接存储用户数据指针
  FData := aData;
end;

{ TLock - 基础锁抽象类实现 }

function TLock.Lock: ILockGuard;
begin
  Result := MakeLockGuard(Self);
end;

function TLock.TryLock: ILockGuard;
begin
  if TryAcquire then
    Result := MakeLockGuardFromAcquired(Self)
  else
    Result := nil;
end;

function TLock.TryLockFor(ATimeoutMs: Cardinal): ILockGuard;
begin
  if TryAcquire(ATimeoutMs) then
    Result := MakeLockGuardFromAcquired(Self)
  else
    Result := nil;
end;

function TLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LEndTime: UInt64;
  LSleepMs: Cardinal;
begin
  // 简单的轮询实现，子类应重写提供更高效的实现
  if ATimeoutMs = 0 then
    Exit(TryAcquire());

  LEndTime := GetTickCount64 + ATimeoutMs;
  LSleepMs := 1;

  repeat
    if TryAcquire() then
      Exit(True);

    Sleep(LSleepMs);

    // 渐进式增加睡眠时间：1ms -> 2ms -> 4ms -> 8ms -> 16ms -> 32ms (最大)
    if LSleepMs < 32 then
      LSleepMs := LSleepMs shl 1;

  until GetTickCount64 >= LEndTime;

  Result := False;
end;

function TLock.LockGuard: ILockGuard;
begin
  Result := Lock;
end;

{ TTryLock - 扩展锁实现 }

function TTryLock.TryLock: ILockGuard;
begin
  if TryAcquire then
    Result := MakeLockGuardFromAcquired(Self)
  else
    Result := nil;
end;

function TTryLock.TryLockFor(ATimeoutMs: Cardinal): ILockGuard;
begin
  if TryAcquire(ATimeoutMs) then
    Result := MakeLockGuardFromAcquired(Self)
  else
    Result := nil;
end;

{**
 * TTryLock.TryAcquire - 带超时的三段式等待策略实现
 *
 * @param ATimeoutMs 超时时间（毫秒），0 表示立即返回
 * @return True 如果在超时时间内成功获取锁，False 如果超时
 *
 * @desc
 *   实现了高度优化的三段式等待策略：
 *   1. 紧密自旋阶段：纯 CPU 自旋，适合短期锁竞争
 *   2. 退避自旋阶段：自旋 + CPU 让出，适合中期竞争
 *   3. 阻塞等待阶段：睡眠为主，适合长期竞争
 *
 * @algorithm
 *   三段式策略的设计理念：
 *   - 快速响应：优先使用高性能的自旋等待
 *   - 渐进退避：逐步降低 CPU 占用
 *   - 系统友好：长期等待时让出 CPU 资源
 *
 * @performance
 *   - 短期锁（微秒级）：主要在紧密自旋阶段完成，性能最优
 *   - 中期锁（毫秒级）：在退避阶段完成，平衡性能和资源占用
 *   - 长期锁（秒级）：在阻塞阶段完成，最小化系统影响
 *
 * @configuration
 *   每个阶段都可以通过属性进行精细调优：
 *   - TightSpin, TightTimeCheckIntervalSpin
 *   - BackOffSpin, BackOffTimeCheckIntervalSpin, BackOffYieldIntervalSpin
 *   - BlockSpin, BlockTimeCheckIntervalSpin, BlockSleepIntervalMs
 *}
function TTryLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LEndTime: UInt64;  // 超时时间点（绝对时间）
  LSleepMs: Cardinal; // 渐进式睡眠间隔
begin
  // 快速路径：立即尝试获取锁，避免不必要的计算开销
  if TryAcquire() then
    Exit(True);

  // 零超时：立即返回，不进行任何等待
  if ATimeoutMs = 0 then
    Exit(False);

  // 计算绝对超时时间点，避免在循环中重复计算
  LEndTime := GetTickCount64 + ATimeoutMs;

  // ===== 阶段1: 紧密自旋 =====
  // 使用纯 CPU 自旋，适合短期锁竞争（微秒级）
  if FTightSpin > 0 then
  begin
    if FTightTimeCheckIntervalSpin = 0 then
    begin
      // 无超时检查模式：将配置的自旋次数全部用完
      // 适合确信锁会很快释放的场景，避免时间检查开销
      if DoTight() then
        Exit(True);
    end
    else
    begin
      // 带超时检查模式：定期检查是否超时
      // 提供更精确的超时控制，但增加时间检查开销
      if DoTight(LEndTime) then
        Exit(True);
    end;
  end;

  // 紧密自旋阶段结束后检查超时
  if GetTickCount64 >= LEndTime then
    Exit(False);

  // ===== 阶段2: 退避自旋 =====
  // 使用更温和的自旋策略，适合中期锁竞争（毫秒级）
  // 可能包含 CPU 让出操作，减少对系统的影响
  if FBackOffSpin > 0 then
  begin
    if FBackOffTimeCheckIntervalSpin = 0 then
    begin
      if FBackOffYieldIntervalSpin = 0 then
      begin
        // 无超时检查，无 CPU 让出：纯自旋模式
        // 适合确信锁会在短时间内释放的场景
        if DoBackOffNoCheckNoYield() then
          Exit(True);
      end
      else
      begin
        // 无超时检查，有 CPU 让出：系统友好的自旋
        // 定期让出 CPU，减少对其他线程的影响
        if DoBackOffNoCheck() then
          exit(True);
      end;
    end
    else
    begin
      if FBackOffYieldIntervalSpin = 0 then
      begin
        // 有超时检查，无 CPU 让出：精确控制的自旋
        // 提供精确的超时控制，但不让出 CPU
        if DoBackOffNoYield(LEndTime) then
          exit(True);
      end
      else
      begin
        // 有超时检查，有 CPU 让出：完整的退避策略
        // 既提供超时控制，又保持系统友好性
        if DoBackOff(LEndTime) then
          exit(True);
      end;
    end;
  end;

  // 退避自旋阶段结束后检查超时
  if GetTickCount64 >= LEndTime then
    Exit(False);

  // ===== 阶段3: 阻塞等待 =====
  // 使用睡眠为主的等待策略，适合长期锁竞争（秒级）
  // 最小化 CPU 占用，对系统最友好
  if FBlockSpin > 0 then
  begin
    if FBlockTimeCheckIntervalSpin = 0 then
    begin
      // 无超时检查模式：依赖睡眠间隔来控制超时
      // 适合对超时精度要求不高的场景
      if DoBlock() then
        Exit(True);
    end
    else
    begin
      // 有超时检查模式：在睡眠间隙检查超时
      // 提供更精确的超时控制
      if DoBlock(LEndTime) then
        Exit(True);
    end;
  end;

  // ===== 最终处理 =====
  // 如果还有剩余的超时时间，使用渐进式退避策略
  // 这处理所有自旋阶段都被关闭的情况
  if GetTickCount64 < LEndTime then
  begin
    LSleepMs := 1;
    repeat
      if TryAcquire() then
        Exit(True);

      Sleep(LSleepMs);

      // 渐进式增加睡眠时间：1ms -> 2ms -> 4ms -> 8ms -> 16ms -> 32ms (最大)
      // 这样既保证短期锁的响应性，又避免长期等待时的CPU浪费
      if LSleepMs < 32 then
        LSleepMs := LSleepMs shl 1;

    until GetTickCount64 >= LEndTime;
  end;

  // 超时，返回失败
  Result := False;
end;


function TTryLock.GetDefaultTightSpin: UInt32;
begin
  Result := 2000;
end;

function TTryLock.GetDefaultTightTimeCheckIntervalSpin: UInt32;
begin
  Result := 1024-1;
end;


function TTryLock.GetDefaultBackOffSpin: UInt32;
begin
  Result := 50;
end;

function TTryLock.GetDefaultBackOffTimeCheckIntervalSpin: UInt32;
begin
  Result := 1024-1;
end;

function TTryLock.GetDefaultBackOffYieldIntervalSpin: UInt32;
begin
  Result := 8192-1;
end;


function TTryLock.GetDefaultBlockSpin: UInt32;
begin
  Result := 1000;
end;

function TTryLock.GetDefaultBlockTimeCheckIntervalSpin: UInt32;
begin
  Result := 1024-1;
end;

function TTryLock.GetDefaultBlockSleepIntervalMs: UInt32;
begin
  Result := 1;
end;


function TTryLock.DoTight: Boolean;
var
  i: UInt32;
begin
  for i := 1 to FTightSpin do
  begin
    if TryAcquire() then
      Exit(True);

    CpuRelax;
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;

function TTryLock.DoTight(aEndTick: UInt64): Boolean;
var
  i: UInt32;
begin
  for i := 1 to FTightSpin do
  begin
    if TryAcquire() then
      Exit(True);

    CpuRelax;

    if((i mod FTightTimeCheckIntervalSpin) = 0) and (GetTickCount64 >= aEndTick) then
      Exit(False);
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;

function TTryLock.DoBackOffNoCheckNoYield: Boolean;
var
  i: UInt32;
begin
  for i := 1 to FBackOffSpin do
  begin
    if TryAcquire() then
      Exit(True);

    CpuRelax;
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;

function TTryLock.DoBackOffNoCheck: Boolean;
var
  i: UInt32;
begin
  for i := 1 to FBackOffSpin do
  begin
    if TryAcquire() then
      Exit(True);

    CpuRelax;

    if ((i mod FBackOffYieldIntervalSpin) = 0) then
      SchedYield;
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;

function TTryLock.DoBackOffNoYield(aEndTick: UInt64): Boolean;
var
  i: UInt32;
begin
  for i := 1 to FBackOffSpin do
  begin
    if TryAcquire() then
      Exit(True);

    CpuRelax;

    if ((i mod FBackOffTimeCheckIntervalSpin) = 0) and (GetTickCount64 >= aEndTick) then
      Exit(False);
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;

function TTryLock.DoBackOff(aEndTick: UInt64): Boolean;
var
  i: UInt32;
begin
  for i := 1 to FBackOffSpin do
  begin
    if TryAcquire() then
      Exit(True);

    CpuRelax;

    if ((i mod FBackOffTimeCheckIntervalSpin) = 0) and (GetTickCount64 >= aEndTick) then
      Exit(False);

    if ((i mod FBackOffYieldIntervalSpin) = 0) then
      SchedYield;
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;

function TTryLock.DoBlock: Boolean;
var
  i: UInt32;
begin
  for i := 1 to FBlockSpin do
  begin
    if TryAcquire() then
      Exit(True);

    Sleep(FBlockSleepIntervalMs);
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;

function TTryLock.DoBlock(aEndTick: UInt64): Boolean;
var
  i: UInt32;
begin
  for i := 1 to FBlockSpin do
  begin
    if TryAcquire() then
      Exit(True);

    if ((i mod FBlockTimeCheckIntervalSpin) = 0) and (GetTickCount64 >= aEndTick) then
      Exit(False);

    Sleep(FBlockSleepIntervalMs);
  end;
  Result := False;  // ✅ P0-fix: 必须显式返回 False，避免未定义行为
end;


function TTryLock.GetTightSpin: UInt32;
begin
  Result := FTightSpin;
end;

procedure TTryLock.SetTightSpin(Value: UInt32);
begin
  FTightSpin := Value;
end;

function TTryLock.GetTightTimeCheckIntervalSpin: UInt32;
begin
  Result := FTightTimeCheckIntervalSpin;
end;

procedure TTryLock.SetTightTimeCheckIntervalSpin(Value: UInt32);
begin
  FTightTimeCheckIntervalSpin := Value;
end;


function TTryLock.GetBackOffSpin: UInt32;
begin
  Result := FBackOffSpin;
end;

procedure TTryLock.SetBackOffSpin(Value: UInt32);
begin
  FBackOffSpin := Value;
end;

function TTryLock.GetBackOffTimeCheckIntervalSpin: UInt32;
begin
  Result := FBackOffTimeCheckIntervalSpin;
end;

procedure TTryLock.SetBackOffTimeCheckIntervalSpin(Value: UInt32);
begin
  FBackOffTimeCheckIntervalSpin := Value;
end;

function TTryLock.GetBackOffYieldIntervalSpin: UInt32;
begin
  Result := FBackOffYieldIntervalSpin;
end;

procedure TTryLock.SetBackOffYieldIntervalSpin(Value: UInt32);
begin
  FBackOffYieldIntervalSpin := Value;
end;


function TTryLock.GetBlockSpin: UInt32;
begin
  Result := FBlockSpin;
end;

procedure TTryLock.SetBlockSpin(Value: UInt32);
begin
  FBlockSpin := Value;
end;

function TTryLock.GetBlockTimeCheckIntervalSpin: UInt32;
begin
  Result := FBlockTimeCheckIntervalSpin;
end;

procedure TTryLock.SetBlockTimeCheckIntervalSpin(Value: UInt32);
begin
  FBlockTimeCheckIntervalSpin := Value;
end;

function TTryLock.GetBlockSleepIntervalMs: UInt32;
begin
  Result := FBlockSleepIntervalMs;
end;

procedure TTryLock.SetBlockSleepIntervalMs(Value: UInt32);
begin
  FBlockSleepIntervalMs := Value;
end;

constructor TTryLock.Create;
begin
  inherited Create;
  // 初始化三段式等待策略的所有参数
  FTightSpin                    := GetDefaultTightSpin;
  FTightTimeCheckIntervalSpin   := GetDefaultTightTimeCheckIntervalSpin;

  FBackOffSpin                  := GetDefaultBackOffSpin;
  FBackOffTimeCheckIntervalSpin := GetDefaultBackOffTimeCheckIntervalSpin;
  FBackOffYieldIntervalSpin     := GetDefaultBackOffYieldIntervalSpin;

  FBlockSpin                    := GetDefaultBlockSpin;
  FBlockTimeCheckIntervalSpin   := GetDefaultBlockTimeCheckIntervalSpin;
  FBlockSleepIntervalMs         := GetDefaultBlockSleepIntervalMs;
end;


end.

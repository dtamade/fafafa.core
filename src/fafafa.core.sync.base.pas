unit fafafa.core.sync.base;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.cpu;

type
  // ===== Exceptions =====
  ESyncError = class(Exception);
  ELockError = class(ESyncError);
  ETimeoutError = class(ESyncError);
  EDeadlockError = class(ESyncError);
  EInvalidArgument = class(ESyncError);
  EOnceRecursiveCall = class(ELockError);


  TWaitResult = (
    wrSignaled,     // 信号状态
    wrTimeout,      // 超时
    wrAbandoned,    // 被放弃 (拥有者异常终止)
    wrError,        // 一般错误
    wrInterrupted   // 被信号中断 (Unix)
  );


  { 基础同步原语接口 - 所有同步对象的基础 }
  ISynchronizable = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    
    {**
     * GetData - 获取同步对象关联的用户数据
     *
     * @return 当前关联的用户数据指针，如果未设置则返回 nil
     *
     * @desc
     *   返回与此同步对象关联的用户自定义数据指针。
     *   这个数据可以是任何类型的指针，由用户自行管理其生命周期。
     *
     * @thread_safety
     *   线程安全，可以从多个线程同时调用。
     *   但用户需要确保指向的数据本身的线程安全性。
     *
     * @memory_management
     *   同步对象不负责管理指向数据的内存，用户需要自行管理。
     *   在销毁同步对象前，确保相关数据已正确释放。
     *
     * @usage
     *   var
     *     UserData: PMyData;
     *   begin
     *     UserData := PMyData(Lock.GetData);
     *     if Assigned(UserData) then
     *       // 使用用户数据
     *   end;
     *}
    function  GetData: Pointer;

    {**
     * SetData - 设置同步对象关联的用户数据
     *
     * @param aData 要关联的用户数据指针，可以为 nil
     *
     * @desc
     *   设置与此同步对象关联的用户自定义数据指针。
     *   这允许用户将任意数据与同步对象绑定，便于在不同上下文中传递信息。
     *
     * @thread_safety
     *   线程安全，可以从多个线程同时调用。
     *   但如果多个线程同时设置不同的数据，最后的设置会覆盖之前的。
     *
     * @memory_management
     *   同步对象不会自动释放之前关联的数据。
     *   如果需要替换数据，用户应先释放旧数据再设置新数据。
     *
     * @use_cases
     *   - 关联锁的拥有者信息
     *   - 存储调试或统计数据
     *   - 传递上下文相关信息
     *   - 实现自定义的锁管理策略
     *
     * @usage
     *   var
     *     MyData: PMyData;
     *   begin
     *     New(MyData);
     *     MyData^.Info := 'Lock context';
     *     Lock.SetData(MyData);
     *     // ... 使用锁
     *     // 记住在适当时候释放数据
     *     Dispose(MyData);
     *   end;
     *}
    procedure SetData(aData: Pointer);
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

  ILockGuard = interface
    ['{A8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']

    {**
     * Release - 释放锁守卫
     *
     * @desc
     *   手动释放锁守卫持有的锁。
     *   通常情况下锁守卫会在析构时自动释放锁，
     *   但此方法允许提前手动释放。
     *
     * @thread_safety
     *   线程安全，但应该只从持有锁的线程调用。
     *
     * @idempotent
     *   多次调用是安全的，重复释放不会产生副作用。
     *
     * @usage
     *   var Guard: ILockGuard;
     *   begin
     *     Guard := Lock.LockGuard;
     *     try
     *       // 临界区代码
     *       if SomeCondition then
     *         Guard.Release;  // 提前释放
     *     finally
     *       // Guard 析构时会检查是否已释放
     *     end;
     *   end;
     *}
    procedure Release;
  end;

  {**
   * ILock - 基础锁接口
   *
   * @desc
   *   定义了最基本的锁操作：获取和释放。
   *   这是所有锁类型的基础接口，提供阻塞式的锁操作。
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
   * @usage_pattern
   *   Lock.Acquire;
   *   try
   *     // 临界区代码
   *   finally
   *     Lock.Release;
   *   end;
   *}
  ILock = interface(ISynchronizable)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']

    {**
     * Acquire - 获取锁
     *
     * @desc
     *   阻塞式获取锁。如果锁当前被其他线程持有，
     *   当前线程将阻塞等待直到成功获取锁。
     *
     * @blocking
     *   这是一个阻塞操作，可能导致线程挂起。
     *   如果需要非阻塞操作，请使用 ITryLock.TryAcquire。
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
     *}
    procedure Acquire;

    {**
     * Release - 释放锁
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
     *   或者使用 RAII 模式的 LockGuard。
     *}
    procedure Release;
  
    {**
     * LockGuard - 创建 RAII 锁守卫
     *
     * @return 锁守卫接口，自动管理锁的生命周期
     *
     * @desc
     *   创建一个 RAII (Resource Acquisition Is Initialization) 风格的锁守卫。
     *   锁守卫在创建时自动获取锁，在析构时自动释放锁，
     *   确保即使在异常情况下锁也能被正确释放。
     *
     * @raii_pattern
     *   这是推荐的锁使用模式，比手动 Acquire/Release 更安全：
     *   - 自动获取：创建时立即获取锁
     *   - 自动释放：超出作用域时自动释放锁
     *   - 异常安全：即使发生异常也能正确释放锁
     *
     * @thread_safety
     *   线程安全，可以从多个线程同时调用。
     *   但每个锁守卫只能在创建它的线程中使用。
     *
     * @performance
     *   相比手动管理，RAII 模式几乎没有性能开销，
     *   但提供了更好的安全性和代码简洁性。
     *
     * @lifetime
     *   返回的锁守卫对象的生命周期决定了锁的持有时间。
     *   当守卫对象被销毁时（超出作用域或显式设为 nil），锁被释放。
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

  TLock =class(TSynchronizable, ILock)
  public
    // ILock 接口实现
    procedure Acquire; virtual; abstract;
    procedure Release; virtual; abstract;
    function  LockGuard: ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

  TLockClass = class of TLock;

  { ITryLock 支持三段式优化超时尝试的互斥锁接口 }
  ITryLock = interface(ILock)
    ['{C8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']

    {**
     * TryAcquire - 非阻塞尝试获取锁
     *
     * @return True 如果成功获取锁，False 如果锁当前被其他线程持有
     *
     * @desc
     *   尝试立即获取锁，不会阻塞当前线程。
     *   如果锁当前可用，则获取锁并返回 True；
     *   如果锁被其他线程持有，则立即返回 False。
     *
     * @thread_safety
     *   线程安全，可以从多个线程同时调用。
     *
     * @performance
     *   这是最快的获取方式，通常只需要一次原子操作。
     *   适用于不希望阻塞的场景，如轮询检查或条件获取。
     *
     * @usage
     *   if Lock.TryAcquire then
     *   try
     *     // 临界区代码
     *   finally
     *     Lock.Release;
     *   end
     *   else
     *     // 锁不可用，执行替代逻辑
     *}
    function TryAcquire: Boolean;

    {**
     * TryAcquire - 带超时的尝试获取锁
     *
     * @param ATimeoutMs 超时时间（毫秒），0 表示立即返回
     *
     * @return True 如果在超时时间内成功获取锁，False 如果超时
     *
     * @desc
     *   在指定的超时时间内尝试获取锁。
     *   如果在超时时间内获取到锁，返回 True；
     *   如果超时仍未获取到锁，返回 False。
     *
     * @timeout_behavior
     *   - ATimeoutMs = 0: 等同于 TryAcquire()，立即返回
     *   - ATimeoutMs > 0: 在超时时间内使用智能等待策略
     *
     * @wait_strategy
     *   使用渐进式等待策略：
     *   1. 初期：纯自旋等待（高性能）
     *   2. 中期：自旋 + CPU 让出（平衡性能）
     *   3. 后期：退避算法（减少 CPU 占用）
     *
     * @precision
     *   超时精度取决于 CheckTimeoutSpin 属性设置。
     *   较小的检查间隔提供更高的超时精度，但增加时间检查开销。
     *
     * @thread_safety
     *   线程安全，可以从多个线程同时调用。
     *
     * @usage
     *   if Lock.TryAcquire(1000) then  // 等待最多1秒
     *   try
     *     // 临界区代码
     *   finally
     *     Lock.Release;
     *   end
     *   else
     *     // 超时，执行超时处理逻辑
     *}
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;

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

    {**
     * TightSpin - 紧密自旋阶段的最大自旋次数
     *
     * @desc
     *   在三段式等待策略的第一阶段（紧密自旋）中，
     *   连续尝试获取锁的最大次数。这个阶段使用纯 CPU 自旋，
     *   适合锁持有时间很短的场景。
     *
     * @default 2000
     *
     * @performance
     *   - 较大值：提高短期锁竞争的响应速度，但增加 CPU 占用
     *   - 较小值：减少 CPU 占用，但可能降低短期锁的获取效率
     *
     * @tuning
     *   根据锁的典型持有时间调整：
     *   - 微秒级持有：可设置为 5000-10000
     *   - 毫秒级持有：建议 1000-3000
     *   - 更长持有：建议 500-1000
     *
     * @remark
     *   这个值对同步性能影响最大，应根据实际场景调整。设置为 `0` 则禁用紧密自旋阶段。
     *}
    property TightSpin: UInt32 read GetTightSpin write SetTightSpin;

    {**
     * TightTimeCheckIntervalSpin - 紧密自旋阶段的超时检查间隔
     *
     * @desc
     *   在紧密自旋阶段，每隔多少次自旋检查一次是否超时。
     *   较小的值提供更精确的超时控制，但增加时间检查开销。
     *
     * @default 1023 (1024-1，利用位运算优化取模操作)
     *
     * @precision
     *   影响超时精度：
     *   - 值越小：超时检查越频繁，精度越高，但开销越大
     *   - 值越大：减少检查开销，但超时精度降低
     *
     * @optimization
     *   建议使用 2^n-1 的值（如 1023, 2047, 4095），
     *   可以利用位运算优化取模操作。
     *
     * @remark
     *   设置为 `0` 则禁用超时检查，仅在 TightSpin 结束时检查一次。
     *}
    property TightTimeCheckIntervalSpin: UInt32 read GetTightTimeCheckIntervalSpin write SetTightTimeCheckIntervalSpin;

    {**
     * BackOffSpin - 退避阶段的最大自旋次数
     *
     * @desc
     *   在三段式等待策略的第二阶段（退避自旋）中，
     *   继续尝试获取锁的最大次数。这个阶段在紧密自旋失败后执行，
     *   使用更温和的自旋策略，适合中等竞争强度的场景。
     *
     * @default 50
     *
     * @strategy
     *   相比紧密自旋，退避阶段：
     *   - 自旋次数更少，减少 CPU 占用
     *   - 可能包含 CPU 让出操作
     *   - 为进入阻塞阶段做准备
     *
     * @tuning
     *   根据系统负载和竞争强度调整：
     *   - 高竞争环境：建议 20-50
     *   - 中等竞争：建议 50-100
     *   - 低竞争：可以设置更大值
     *
     * @remark
     *   设置为 `0` 则禁用退避自旋阶段，直接进入阻塞阶段。
     *}
    property BackOffSpin: UInt32 read GetBackOffSpin write SetBackOffSpin;

    {**
     * BackOffTimeCheckIntervalSpin - 退避阶段的超时检查间隔
     *
     * @desc
     *   在退避自旋阶段，每隔多少次自旋检查一次是否超时。
     *   由于退避阶段自旋次数较少，通常可以设置较小的检查间隔。
     *
     * @default 1023 (1024-1)
     *
     * @consideration
     *   退避阶段的特点：
     *   - 自旋次数相对较少
     *   - 可以承受更频繁的时间检查
     *   - 需要更精确的超时控制
     * @remark
     *   设置为 `0` 则禁用超时检查，仅在 BackOff 结束时检查一次。
     *}
    property BackOffTimeCheckIntervalSpin: UInt32 read GetBackOffTimeCheckIntervalSpin write SetBackOffTimeCheckIntervalSpin;

    {**
     * BackOffYieldIntervalSpin - 退避阶段的 CPU 让出间隔
     *
     * @desc
     *   在退避自旋阶段，每隔多少次自旋调用一次 CPU 让出操作。
     *   CPU 让出允许其他线程运行，减少对系统的影响。
     *
     * @default 8191 (8192-1)
     *
     * @cpu_yield
     *   CPU 让出的作用：
     *   - 允许操作系统调度其他线程
     *   - 减少对系统整体性能的影响
     *   - 在高竞争环境下提高公平性
     *
     * @balance
     *   需要在响应性和系统友好性之间平衡：
     *   - 较小值：更频繁让出，系统友好但可能影响响应性
     *   - 较大值：减少让出开销，但可能影响其他线程
     *}
    property BackOffYieldIntervalSpin: UInt32 read GetBackOffYieldIntervalSpin write SetBackOffYieldIntervalSpin;

    {**
     * BlockSpin - 阻塞阶段的最大自旋次数
     *
     * @desc
     *   在三段式等待策略的第三阶段（阻塞等待）中，
     *   在进入睡眠前的最后自旋尝试次数。这个阶段适合长期竞争的场景，
     *   主要通过睡眠来减少 CPU 占用。
     *
     * @default 1000
     *
     * @purpose
     *   阻塞阶段的设计目标：
     *   - 最小化 CPU 占用
     *   - 通过睡眠让出 CPU 时间
     *   - 适合长时间等待的场景
     *
     * @sleep_strategy
     *   与前两个阶段不同，这个阶段主要依赖睡眠而非自旋。
     *
     * @remark
     *   设置为 `0` 则禁用阻塞自旋阶段，直接进入最终的睡眠阶段。
     *}
    property BlockSpin:                    UInt32 read GetBlockSpin write SetBlockSpin;

    {**
     * BlockTimeCheckIntervalSpin - 阻塞阶段的超时检查间隔
     *
     * @desc
     *   在阻塞等待阶段，每隔多少次自旋检查一次是否超时。
     *   由于这个阶段主要依赖睡眠，时间检查相对不那么频繁。
     *
     * @default 1023 (1024-1)
     *
     * @sleep_priority
     *   在阻塞阶段，睡眠是主要的等待机制，
     *   自旋只是睡眠间隙的补充尝试。
     *}
    property BlockTimeCheckIntervalSpin:   UInt32 read GetBlockTimeCheckIntervalSpin write SetBlockTimeCheckIntervalSpin;

    {**
     * BlockSleepIntervalMs - 阻塞阶段的睡眠间隔（毫秒）
     *
     * @desc
     *   在阻塞等待阶段，每次睡眠的时间长度（毫秒）。
     *   这是三段式等待策略中最重要的参数之一，
     *   直接影响长期等待的 CPU 占用和响应性。
     *
     * @default 1 毫秒
     *
     * @trade_off
     *   睡眠时间的权衡：
     *   - 较短睡眠（1-5ms）：更好的响应性，但可能增加 CPU 占用
     *   - 较长睡眠（10-50ms）：更低的 CPU 占用，但响应性下降
     *
     * @system_impact
     *   1毫秒是一个平衡的选择：
     *   - 足够短，保证合理的响应性
     *   - 足够长，有效减少 CPU 占用
     *   - 符合大多数操作系统的调度粒度
     *
     * @tuning_guide
     *   根据应用场景调整：
     *   - 实时系统：建议 1-2ms
     *   - 一般应用：建议 1-10ms
     *   - 后台任务：可以设置 10-50ms
     *}
    property BlockSleepIntervalMs:         UInt32 read GetBlockSleepIntervalMs write SetBlockSleepIntervalMs;

  end;


  TTryLock = class(TLock, ITryLock)
  private
    FTightSpin:                    UInt32;
    FTightTimeCheckIntervalSpin:   UInt32;

    FBackOffSpin:                  UInt32;
    FBackOffTimeCheckIntervalSpin: UInt32;
    FBackOffYieldIntervalSpin:     UInt32;

    FBlockSpin:                    UInt32;
    FBlockTimeCheckIntervalSpin:   UInt32;
    FBlockSleepIntervalMs:         UInt32;
  protected
    function GetDefaultTightSpin: UInt32; virtual;
    function GetDefaultTightTimeCheckIntervalSpin: UInt32; virtual;

    function GetDefaultBackOffSpin: UInt32; virtual;
    function GetDefaultBackOffTimeCheckIntervalSpin: UInt32; virtual;
    function GetDefaultBackOffYieldIntervalSpin: UInt32; virtual;

    function GetDefaultBlockSpin: UInt32; virtual;
    function GetDefaultBlockTimeCheckIntervalSpin: UInt32; virtual;
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
    
    function TryAcquire: Boolean; overload; virtual; abstract;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; virtual;


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


  TLockGuard = class(TInterfacedObject, ILockGuard)
  private
    FLock: ILock;
    FReleased: Boolean;
  public
    constructor Create(ALock: ILock);
    constructor CreateFromAcquired(ALock: ILock);
    destructor Destroy; override;
    procedure Release; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

function MutexGuard(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function MakeLockGuard(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF} // 向后兼容
function MakeLockGuardFromAcquired(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation


function MutexGuard(ALock: ILock): ILockGuard;
begin
  Result := TLockGuard.Create(ALock);
end;

function MakeLockGuard(ALock: ILock): ILockGuard;
begin
  Result := MutexGuard(ALock); // 向后兼容，调用新函数
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

procedure TLockGuard.Release;
begin
  if not FReleased and Assigned(FLock) then
  begin
    FLock.Release;
    FReleased := True;
  end;
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

function TLock.LockGuard: ILockGuard;
begin
  Result := MakeLockGuard(Self);
end;

{ TTryLock - 扩展锁实现 }

function TTryLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  EndTime:   UInt64;
  i:         UInt32;
begin
   // 快速路径
  if TryAcquire then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  EndTime   := GetTickCount64 + ATimeoutMs; // 超时时间点

  // 阶段1: 紧密自旋
  if FTightSpin > 0 then
  begin
    if FTightTimeCheckIntervalSpin = 0 then
    begin
      if DoTight() then // 无超时检查,将自旋次数旋完为止
        Exit(True);
    end
    else
    begin
      if DoTight(EndTime) then
        Exit(True);
    end;
  end;  

  if GetTickCount64 >= EndTime then
    Exit(False);

  // 阶段2: 退避优化自旋
  if FBackOffSpin > 0 then
  begin
    if FBackOffTimeCheckIntervalSpin = 0 then
    begin
      if FBackOffYieldIntervalSpin = 0 then
      begin
        if DoBackOffNoCheckNoYield() then
          Exit(True); 
      end
      else
      begin
        if DoBackOffNoCheck() then
          exit(True);
      end;
    end
    else
    begin
      if FBackOffYieldIntervalSpin = 0 then
      begin
        if DoBackOffNoYield(EndTime) then
          exit(True);
      end
      else
      begin
        if DoBackOff(EndTime) then
          exit(True);
      end;
    end;
  end;

  if GetTickCount64 >= EndTime then
    Exit(False);

  // 阶段3: 睡眠式自旋
  if FBlockSpin > 0 then
  begin
    if FBlockTimeCheckIntervalSpin = 0 then
    begin
      if DoBlock() then
        Exit(True);
    end
    else
    begin
      if DoBlock(EndTime) then
        Exit(True);
    end;
  end;

  // 消费掉剩余的超时时间(如果有)
  if GetTickCount64 < EndTime then
    Sleep(EndTime - GetTickCount64); // 到这里不精确也没办法  

  Result := TryAcquire();
end;


function TTryLock.GetDefaultTightSpin: UInt32;
begin
  Result := 2000;  // 紧密自旋次数
end;

function TTryLock.GetDefaultTightTimeCheckIntervalSpin: UInt32;
begin
  Result := 1024-1;  // 紧密自旋检查时间间隔
end;


function TTryLock.GetDefaultBackOffSpin: UInt32;
begin
  Result := 50;  // 退避自旋次数
end;

function TTryLock.GetDefaultBackOffTimeCheckIntervalSpin: UInt32;
begin
  Result := 1024-1;  // 退避自旋检查时间间隔
end;

function TTryLock.GetDefaultBackOffYieldIntervalSpin: UInt32;
begin
  Result := 8192-1;  // 每 8192 次循环调用 SchedYield
end;


function TTryLock.GetDefaultBlockSpin: UInt32;
begin
  Result := 1000;  // 阻塞自旋次数
end;

function TTryLock.GetDefaultBlockTimeCheckIntervalSpin: UInt32;
begin
  Result := 1024-1;  // 每 1024 次循环检查一次时间
end;

function TTryLock.GetDefaultBlockSleepIntervalMs: UInt32;
begin
  Result := 1;  // 每次睡眠1毫秒
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


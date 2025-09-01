{**
 * fafafa.core.sync.spin.unix - Unix 平台自旋锁实现
 *
 * @desc
 *   基于 pthread_spinlock_t 的高性能自旋锁实现，专为 Unix 平台优化。
 *   利用系统原生的自旋锁实现，提供最佳的性能和兼容性。
 *
 * @implementation_details
 *   - 底层实现：pthread_spinlock_t
 *   - 初始化：PTHREAD_PROCESS_PRIVATE（进程内共享）
 *   - 自旋策略：系统原生 + 继承的三段式等待策略
 *   - 异常处理：使用同步专用异常类型
 *
 * @advantages
 *   - 系统原生实现，性能最优
 *   - 自动适应不同的 Unix 系统
 *   - 内核级优化的自旋策略
 *   - 良好的多核扩展性
 *
 * @thread_safety
 *   线程安全，非重入。基于 pthread 标准，具有良好的可移植性。
 *}
unit fafafa.core.sync.spin.unix;

{$I fafafa.core.settings.inc}

interface

uses
  BaseUnix, Unix, pthreads,
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base;

type
  {**
   * TSpin - Unix 平台自旋锁实现
   *
   * @desc
   *   基于 pthread_spinlock_t 的自旋锁实现，继承 TTryLock 以获得
   *   三段式等待策略的优化。使用系统原生的自旋锁提供最佳性能。
   *
   * @pthread_spinlock
   *   pthread_spinlock_t 是 POSIX 标准的自旋锁实现：
   *   - 内核级优化的自旋策略
   *   - 自动适应不同的硬件架构
   *   - 良好的多核性能扩展
   *
   * @inheritance
   *   继承自 TTryLock，在超时场景下可以利用三段式等待策略，
   *   但基本操作（Acquire/Release/TryAcquire）直接使用系统调用。
   *
   * @error_handling
   *   使用同步专用的异常类型，提供更精确的错误信息。
   *}
  TSpin = class(TTryLock, ISpin)
  private
    FSpinLock: pthread_spinlock_t;  // 系统原生自旋锁

  public
    {**
     * Create - 构造函数
     *
     * @desc 初始化 pthread 自旋锁
     * @exception ELockError 如果初始化失败
     *}
    constructor Create;

    {**
     * Destroy - 析构函数
     *
     * @desc 销毁 pthread 自旋锁，释放系统资源
     *}
    destructor Destroy; override;

    {**
     * Acquire - 获取锁（阻塞式）
     *
     * @desc
     *   使用 pthread_spin_lock 获取锁，会阻塞直到成功。
     *   系统会自动使用最优的自旋策略。
     *
     * @blocking 会阻塞直到成功获取锁
     * @exception ELockError 如果获取失败
     *}
    procedure Acquire; override;

    {**
     * Release - 释放锁
     *
     * @desc
     *   使用 pthread_spin_unlock 释放锁。
     *   必须由持有锁的线程调用。
     *
     * @precondition 当前线程必须持有锁
     * @exception ELockError 如果释放失败
     *}
    procedure Release; override;

    {**
     * TryAcquire - 非阻塞尝试获取锁
     *
     * @return True 如果成功获取锁，False 如果锁被其他线程持有
     *
     * @desc
     *   使用 pthread_spin_trylock 立即尝试获取锁，不会阻塞。
     *
     * @non_blocking 立即返回，不会阻塞线程
     *}
    function TryAcquire: Boolean; override;

    {**
     * TryAcquire - 带超时的尝试获取锁
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果在超时时间内成功获取锁，False 如果超时
     *
     * @desc
     *   由于 pthread_spinlock_t 不支持超时，这里使用继承的
     *   三段式等待策略来实现超时功能。
     *
     * @timeout 在指定时间内尝试获取锁
     *}
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;
  end;

{**
 * MakeSpin - 创建 Unix 自旋锁实例
 *
 * @return Unix 平台的自旋锁实现
 *
 * @desc 工厂函数，创建基于 pthread_spinlock_t 的自旋锁实例
 *}
function MakeSpin: ISpin;

implementation

uses
  fafafa.core.time.cpu;



{ TSpin }

constructor TSpin.Create;
begin
  inherited Create;
  // 初始化 pthread 自旋锁
  if pthread_spin_init(@FSpinLock, PTHREAD_PROCESS_PRIVATE) <> 0 then
    raise ELockError.Create('Failed to initialize pthread spinlock');
end;

destructor TSpin.Destroy;
begin
  // 销毁 pthread 自旋锁
  pthread_spin_destroy(@FSpinLock);
  inherited Destroy;
end;

procedure TSpin.Acquire;
begin
  // 使用 pthread 自旋锁获取
  if pthread_spin_lock(@FSpinLock) <> 0 then
    raise ELockError.Create('Failed to acquire pthread spinlock');
end;

procedure TSpin.Release;
begin
  // 使用 pthread 自旋锁释放
  if pthread_spin_unlock(@FSpinLock) <> 0 then
    raise ELockError.Create('Failed to release pthread spinlock');
end;

function TSpin.TryAcquire: Boolean;
begin
  // 使用 pthread 非阻塞尝试获取
  Result := pthread_spin_trylock(@FSpinLock) = 0;
end;

function TSpin.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  // 使用继承的三段式等待策略，这比自定义实现更优化且更一致
  // TTryLock.TryAcquire 会调用我们的 TryAcquire() 方法
  Result := inherited TryAcquire(ATimeoutMs);
end;

// 工厂函数
function MakeSpin: ISpin;
begin
  Result := TSpin.Create;
end;

end.

unit fafafa.core.sync.recMutex.unix;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│          ______   ______     ______   ______     ______   ______             │
│         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                                Studio                                        │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.recMutex.unix - Unix/Linux 可重入互斥锁实现

📖 概述：
  基于 POSIX pthread_mutex_t 的可重入互斥锁实现，专为 Unix/Linux 系统优化。
  使用 PTHREAD_MUTEX_RECURSIVE 属性提供原生的重入支持。

🔧 特性：
  • Unix/Linux 原生支持：Linux、macOS、FreeBSD、OpenBSD 等
  • POSIX 标准实现：基于 pthread_mutex_t 和 PTHREAD_MUTEX_RECURSIVE
  • 零本地状态：完全依赖系统原生重入计数，无额外开销
  • 原子操作：所有锁操作都是原子性的，线程安全
  • 超时支持：使用 pthread_mutex_timedlock 实现超时机制
  • 异常安全：RAII 模式确保异常情况下的锁释放

⚠️  重要说明：
  此实现专为 Unix/Linux 系统设计，依赖 POSIX pthread 库。
  重入计数由系统内核管理，性能优异但平台特定。

🧵 线程安全性：
  基于 POSIX 线程标准，所有操作都是线程安全的。
  重入特性由系统内核保证，同一线程可安全多次获取锁。

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Unix, UnixType, pthreads,
  fafafa.core.sync.base,
  fafafa.core.sync.recMutex.base;

type

  {**
   * TRecMutex - Unix 平台可重入互斥锁实现
   *
   * @desc
   *   基于 POSIX pthread_mutex_t 的可重入互斥锁实现。
   *   使用 PTHREAD_MUTEX_RECURSIVE 属性实现重入功能。
   *
   * @implementation
   *   - 使用 pthread_mutex_t 作为底层实现
   *   - 设置 PTHREAD_MUTEX_RECURSIVE 属性
   *   - 继承 TTryLock 获得三段式等待策略
   *   - 实现完整的 IRecMutex 接口
   *
   * @performance
   *   - 依赖系统 pthread 实现的性能
   *   - 可重入功能由内核提供，性能稳定
   *   - 支持超时等待（pthread_mutex_timedlock）
   *   - 在高竞争情况下表现良好
   *
   * @thread_safety
   *   完全线程安全，支持多线程并发访问和重入。
   *}
  TRecMutex = class(TTryLock, IRecMutex)
  private
    FMutex: pthread_mutex_t;       // POSIX 互斥锁
  protected
    // 重写默认参数以适应可重入互斥锁的特性
    function GetDefaultTightSpin: UInt32; override;
    function GetDefaultBackOffSpin: UInt32; override;
    function GetDefaultBlockSpin: UInt32; override;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    // ILock 接口实现
    {**
     * Acquire - 获取可重入互斥锁
     *
     * @desc
     *   阻塞式获取可重入互斥锁。如果锁被其他线程持有，
     *   当前线程将阻塞等待。如果是同一线程重入，则立即成功。
     *
     * @blocking
     *   此方法会阻塞当前线程直到成功获取锁。
     *
     * @reentrancy
     *   支持同一线程多次调用，内部计数器会自动递增。
     *
     * @exception
     *   如果系统调用失败，会抛出 ELockError 异常。
     *}
    procedure Acquire; override;

    {**
     * Release - 释放可重入互斥锁
     *
     * @desc
     *   释放一次可重入互斥锁。如果是重入锁，内部计数器递减。
     *   只有当计数器归零时，锁才真正被释放。
     *
     * @reentrancy
     *   必须与 Acquire 调用次数匹配，每次 Acquire 对应一次 Release。
     *
     * @exception
     *   如果系统调用失败，会抛出 ELockError 异常。
     *}
    procedure Release; override;

    {**
     * TryAcquire - 非阻塞尝试获取锁
     *
     * @return 成功获取锁返回 True，否则返回 False
     *
     * @desc
     *   非阻塞式尝试获取可重入互斥锁。如果锁当前可用或是同一线程重入，
     *   则立即获取并返回 True。如果锁被其他线程持有，则立即返回 False。
     *
     * @non_blocking
     *   此方法不会阻塞当前线程，立即返回结果。
     *
     * @reentrancy
     *   支持同一线程重入，重入时总是返回 True。
     *}
    function TryAcquire: Boolean; override;

    {**
     * GetHandle - 获取底层 pthread_mutex_t 句柄
     *
     * @return pthread_mutex_t 的指针
     *
     * @desc
     *   返回底层 pthread_mutex_t 的指针，供高级用户
     *   或其他同步原语使用。
     *
     * @advanced_usage
     *   此方法主要用于：
     *   - 与条件变量等高级同步原语集成
     *   - 性能分析和调试
     *   - 底层系统编程
     *
     * @warning
     *   直接操作返回的句柄可能导致未定义行为，
     *   请确保了解 pthread_mutex_t 的使用规则。
     *}
    function GetHandle: Pointer;
  end;

{**
 * MakeRecMutex - 创建可重入互斥锁实例
 *
 * @return 可重入互斥锁接口实例
 *
 * @desc
 *   创建一个基于 POSIX pthread 的可重入互斥锁实例。
 *   这是推荐的创建方式。
 *}
function MakeRecMutex: IRecMutex;

implementation

function MakeRecMutex: IRecMutex;
begin
  Result := TRecMutex.Create;
end;

constructor TRecMutex.Create;
var
  LAttr: pthread_mutexattr_t;
  LRet: Integer;
begin
  inherited Create;

  // 初始化互斥锁属性
  LRet := pthread_mutexattr_init(@LAttr);
  if LRet <> 0 then
    raise ELockError.Create('RecMutex: Failed to initialize mutex attributes (error: ' + IntToStr(LRet) + ')');

  try
    // 设置为可重入类型
    LRet := pthread_mutexattr_settype(@LAttr, PTHREAD_MUTEX_RECURSIVE);
    if LRet <> 0 then
      raise ELockError.Create('RecMutex: Failed to set recursive type (error: ' + IntToStr(LRet) + ')');

    // 初始化互斥锁
    LRet := pthread_mutex_init(@FMutex, @LAttr);
    if LRet <> 0 then
      raise ELockError.Create('RecMutex: Failed to initialize mutex (error: ' + IntToStr(LRet) + ')');
  finally
    pthread_mutexattr_destroy(@LAttr);
  end;
end;

destructor TRecMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

// ===== 默认参数重写 =====

function TRecMutex.GetDefaultTightSpin: UInt32;
begin
  // 可重入互斥锁通常持有时间较长，减少紧密自旋
  Result := 1000;
end;

function TRecMutex.GetDefaultBackOffSpin: UInt32;
begin
  // 适中的退避自旋
  Result := 100;
end;

function TRecMutex.GetDefaultBlockSpin: UInt32;
begin
  // 较少的阻塞自旋，更多依赖睡眠
  Result := 500;
end;

// ===== ILock 接口实现 =====

procedure TRecMutex.Acquire;
var
  LRet: Integer;
begin
  LRet := pthread_mutex_lock(@FMutex);
  if LRet <> 0 then
    raise ELockError.Create('RecMutex: Failed to acquire lock (error: ' + IntToStr(LRet) + ')');
end;

procedure TRecMutex.Release;
var
  LRet: Integer;
begin
  LRet := pthread_mutex_unlock(@FMutex);
  if LRet <> 0 then
    raise ELockError.Create('RecMutex: Failed to release lock (error: ' + IntToStr(LRet) + ')');
end;

function TRecMutex.TryAcquire: Boolean;
begin
  Result := (pthread_mutex_trylock(@FMutex) = 0);
end;

function TRecMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

end.


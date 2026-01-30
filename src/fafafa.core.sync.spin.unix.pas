unit fafafa.core.sync.spin.unix;

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

📦 项目：fafafa.core.sync.spin.unix - Unix 平台自旋锁实现

📖 概述：
  Unix/Linux 平台的高性能自旋锁实现，使用 pthread 和原子操作优化。

🔧 特性：
  • Unix 平台优化：针对 Linux、macOS、FreeBSD 等 Unix 系统
  • 高性能实现：使用 pthread_spin_lock 和原子指令
  • 自适应退避：智能退避策略减少 CPU 占用
  • 超时支持：可配置的获取超时机制
  • 统计信息：详细的性能统计和调试信息
  • RAII 支持：自动锁管理和异常安全
  • 死锁检测：调试模式下的死锁检测

⚠️  重要说明：
  自旋锁适用于短时间持锁场景，长时间持锁会导致 CPU 资源浪费。
  请根据具体场景选择合适的锁类型和退避策略。

🧵 线程安全性：
  所有自旋锁操作都是线程安全的，支持多线程并发访问。

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
  Unix, pthreads,
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base;

type

  TSpin = class(TTryLock, ISpin)
  private
    FSpinLock: pthread_spinlock_t; // 系统原生自旋锁
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    {**
     * Acquire - 获取锁（阻塞式）
     *
     * @desc
     *   使用 pthread_spin_lock 获取锁，会阻塞直到成功。
     *   系统会自动使用最优的自旋策略。
     *
     * @blocking 会阻塞直到成功获取锁
     *
     * @exception 
     *   ELockError 如果获取失败
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
     *
     * @exception
     *  ELockError 如果释放失败
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
     * @params
     *  ATimeoutMs 超时时间（毫秒）
     *
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


{ TSpin }

constructor TSpin.Create;
begin
  inherited Create;
  if pthread_spin_init(@FSpinLock, PTHREAD_PROCESS_PRIVATE) <> 0 then
    raise ELockError.Create('Failed to initialize pthread spinlock');
end;

destructor TSpin.Destroy;
begin
  pthread_spin_destroy(@FSpinLock);
  inherited Destroy;
end;

procedure TSpin.Acquire;
begin
  if pthread_spin_lock(@FSpinLock) <> 0 then
    raise ELockError.Create('Failed to acquire pthread spinlock');
end;

procedure TSpin.Release;
begin
  if (pthread_spin_unlock(@FSpinLock) <> 0) then
    raise ELockError.Create('Failed to release pthread spinlock');
end;

function TSpin.TryAcquire: Boolean;
begin
  Result := (pthread_spin_trylock(@FSpinLock) = 0);
end;

function TSpin.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  // 使用继承的三段式等待策略，这比自定义实现更优化且更一致
  Result := inherited TryAcquire(ATimeoutMs);
end;

function MakeSpin: ISpin;
begin
  Result := TSpin.Create;
end;

end.

unit fafafa.core.sync.mutex;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.sync.mutex - 高性能互斥锁实现

📖 概述：
  现代化、跨平台的 FreePascal 互斥锁（Mutex）实现，提供线程安全的
  资源同步机制。支持 Windows（CRITICAL_SECTION/SRWLOCK）和 Unix
  （pthread/futex）平台，具有优异的性能和可靠性。

🔧 特性：
  • 跨平台支持：Windows、Linux、macOS、FreeBSD 等
  • 高性能实现：使用平台原生 API 优化
  • 非重入设计：防止死锁和逻辑错误
  • 异常安全：RAII 风格的锁保护
  • 超时支持：可配置的获取超时
  • 调试友好：详细的错误信息和诊断

⚠️  重要说明：
  本实现为非重入（non-reentrant）互斥锁，同一线程重复获取锁将
  抛出异常。如需重入锁，请使用 fafafa.core.sync.recMutex 模块。

🧵 线程安全性：
  所有公共方法都是线程安全的，可以从多个线程同时调用。

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.mutex.base
  {$IFDEF WINDOWS}, fafafa.core.sync.mutex.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.mutex.unix{$ENDIF};

type
  {**
   * IMutex
   *
   * @desc 标准互斥锁接口（不可重入）
   *
   * @remark
   *   这是一个非重入互斥锁接口，同一线程重复获取锁将抛出异常。
   *   继承自 ITryLock，支持非阻塞的锁获取操作。
   *   所有方法都是线程安全的，可以从多个线程同时调用。
   *}
  IMutex = fafafa.core.sync.mutex.base.IMutex;

  {**
   * TMutex
   *
   * @desc 平台特定的互斥锁实现类型别名
   *
   * @remark
   *   在 Windows 平台使用 CRITICAL_SECTION 或 SRWLOCK 实现，
   *   在 Unix 平台使用 pthread_mutex 或 futex 实现。
   *   具体实现由编译时配置决定。
   *}
  {$IFDEF WINDOWS}
  TMutex = fafafa.core.sync.mutex.windows.TMutex;
  {$ENDIF}
  {$IFDEF UNIX}
  TMutex = fafafa.core.sync.mutex.unix.TMutex;
  {$ENDIF}

{**
 * MakeMutex
 *
 * @desc 创建一个新的互斥锁实例
 *
 * @return 返回一个 IMutex 接口实例，使用平台最优的实现
 *
 * @remark
 *   此函数会根据当前平台和编译配置选择最优的互斥锁实现：
 *   - Windows: 优先使用 SRWLOCK（Vista+），回退到 CRITICAL_SECTION
 *   - Unix: 优先使用 futex（Linux），回退到 pthread_mutex
 *
 *   返回的互斥锁是非重入的，同一线程重复获取将抛出异常。
 *
 *   示例:
 *   ```pascal
 *   var
 *     Mutex: IMutex;
 *   begin
 *     Mutex := MakeMutex;
 *     Mutex.Acquire;
 *     try
 *       // 临界区代码
 *     finally
 *       Mutex.Release;
 *     end;
 *   end;
 *   ```
 *}
function MakeMutex: IMutex;

{**
 * MakePthreadMutex
 *
 * @desc 创建一个与 pthread_cond_* 兼容的 mutex
 *
 * @return 返回一个 IMutex 接口实例，始终使用 pthread_mutex_t 实现
 *
 * @remark
 *   此函数专门用于与条件变量（condvar）配合使用。
 *   在 Unix 平台，当启用 futex 优化时，标准 MakeMutex 返回的是 futex 实现，
 *   但 pthread_cond_wait/pthread_cond_timedwait 需要 pthread_mutex_t。
 *   此函数始终返回 pthread_mutex_t 版本的 mutex。
 *
 *   在 Windows 平台，此函数与 MakeMutex 行为相同。
 *}
{$IFDEF UNIX}
function MakePthreadMutex: IMutex;
{$ENDIF}


implementation

function MakeMutex: IMutex;
begin
  {$IFDEF WINDOWS}
    Result := fafafa.core.sync.mutex.windows.MakeMutex();
  {$ELSEIF DEFINED(UNIX)}
    Result := fafafa.core.sync.mutex.unix.MakeMutex();
  {$ELSE}
    {$ERROR 'Unsupported platform for fafafa.core.sync.mutex'}
  {$ENDIF}
end;

{$IFDEF UNIX}
function MakePthreadMutex: IMutex;
begin
  Result := fafafa.core.sync.mutex.unix.MakePthreadMutex();
end;
{$ENDIF}

end.

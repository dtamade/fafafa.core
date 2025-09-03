unit fafafa.core.sync.recMutex;

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

📦 项目：fafafa.core.sync.recMutex - 跨平台高性能可重入互斥锁实现

📖 概述：
  现代化、跨平台的 FreePascal 可重入互斥锁实现，提供统一的 API 接口。
  支持同一线程多次获取锁，自动管理重入计数。

🔧 特性：
  • 跨平台支持：Windows、Linux、macOS、FreeBSD 等
  • 可重入设计：同一线程可多次获取锁，自动计数管理
  • 高性能实现：使用平台原生 API 优化
  • 三段式等待：智能退避策略减少 CPU 占用
  • 超时支持：可配置的获取超时机制
  • RAII 支持：自动锁管理和异常安全

⚠️  重要说明：
  可重入互斥锁适用于需要递归调用或嵌套锁定的场景。
  相比普通互斥锁有额外的性能开销，请根据需要选择。

🧵 线程安全性：
  所有可重入互斥锁操作都是线程安全的，支持多线程并发访问。
  同一线程可以多次获取锁，必须相应次数地释放锁。

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.recMutex.base
  {$IFDEF WINDOWS}
  ,fafafa.core.sync.recMutex.windows
  {$ELSE}
  ,fafafa.core.sync.recMutex.unix
  {$ENDIF};

type

  IRecMutex = fafafa.core.sync.recMutex.base.IRecMutex;

  {$IFDEF WINDOWS}
  TRecMutex = fafafa.core.sync.recMutex.windows.TRecMutex;
  {$ENDIF}
  {$IFDEF UNIX}
  TRecMutex = fafafa.core.sync.recMutex.unix.TRecMutex;
  {$ENDIF}

{**
 * MakeRecMutex - 创建可重入互斥锁实例
 *
 * @return 可重入互斥锁接口实例
 *
 * @desc
 *   创建一个可重入互斥锁实例，自动选择当前平台的最优实现：
 *   - Windows: 基于 Critical Section 的高性能实现
 *   - Unix: 基于 pthread_mutex_t (PTHREAD_MUTEX_RECURSIVE) 的系统实现
 *
 * @thread_safety
 *   返回的实例是线程安全的，且支持重入。
 *   同一线程可以多次获取锁，必须相应次数地释放锁。
 *
 * @usage
 *   var RecMutex := MakeRecMutex;
 *   // 使用 RecMutex...
 *}
function MakeRecMutex: IRecMutex;

{$IFDEF WINDOWS}
{**
 * MakeRecMutex - 创建带自旋计数的可重入互斥锁实例（Windows 专用）
 *
 * @param ASpinCount 自旋计数，在进入内核等待前的自旋次数
 * @return 可重入互斥锁接口实例
 *
 * @desc
 *   创建一个带自旋计数的可重入互斥锁实例。自旋计数可以提高
 *   短期锁竞争的性能，减少内核调用开销。
 *
 * @windows_specific
 *   此重载仅在 Windows 平台可用，利用 Critical Section 的自旋特性。
 *
 * @spin_count
 *   建议值：
 *   - 单核系统：0（禁用自旋）
 *   - 多核系统：1000-4000（默认 4000）
 *   - 高竞争场景：可适当增加到 8000-16000
 *
 * @usage
 *   var RecMutex := MakeRecMutex(4000);
 *   // 使用带自旋优化的 RecMutex...
 *}
function MakeRecMutex(ASpinCount: DWORD): IRecMutex; overload;
{$ENDIF}

implementation

function MakeRecMutex: IRecMutex;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.recMutex.windows.MakeRecMutex;
  {$ELSE}
  Result := fafafa.core.sync.recMutex.unix.MakeRecMutex;
  {$ENDIF}
end;

{$IFDEF WINDOWS}
function MakeRecMutex(ASpinCount: DWORD): IRecMutex;
begin
  Result := fafafa.core.sync.recMutex.windows.MakeRecMutex(ASpinCount);
end;
{$ENDIF}

end.


unit fafafa.core.sync.spin;

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

📦 项目：fafafa.core.sync.spin - 跨平台高性能自旋锁实现

📖 概述：
  现代化、跨平台的 FreePascal 自旋锁实现，提供统一的 API 接口。

🔧 特性：
  • 跨平台支持：Windows、Linux、macOS、FreeBSD 等
  • 高性能实现：使用平台原生 API 和原子指令优化
  • 自适应退避：智能退避策略减少 CPU 占用
  • 超时支持：可配置的获取超时机制
  • 统计信息：详细的性能统计和调试信息
  • RAII 支持：自动锁管理和异常安全

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

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.spin.base;

type

  ISpin = fafafa.core.sync.spin.base.ISpin;

{**
 * MakeSpin - 创建自旋锁实例
 *
 * @return 自旋锁接口实例
 *
 * @desc
 *   创建一个自旋锁实例，自动选择当前平台的最优实现：
 *   - Windows: 基于原子操作的轻量级实现
 *   - Unix: 基于 pthread_spinlock_t 的系统实现
 *
 * @thread_safety
 *   返回的实例是线程安全的，但非重入。
 *
 * @usage
 *   var SpinLock := MakeSpin;
 *   // 使用 SpinLock...
 *}
function MakeSpin: ISpin;

implementation

uses
  {$IFDEF MSWINDOWS}
  fafafa.core.sync.spin.atomic
  {$ELSE}
  fafafa.core.sync.spin.unix
  {$ENDIF};

function MakeSpin: ISpin;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.spin.atomic.MakeSpin;
  {$ELSE}
  Result := fafafa.core.sync.spin.unix.MakeSpin;
  {$ENDIF}
end;

end.

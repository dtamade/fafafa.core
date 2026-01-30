unit fafafa.core.sync.event;

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

📦 项目：fafafa.core.sync.event - 跨平台高性能事件同步实现

📖 概述：
  现代化、跨平台的 FreePascal 事件同步实现，提供统一的 API 接口。

🔧 特性：
  • 跨平台支持：Windows、Linux、macOS、FreeBSD 等
  • 高性能实现：使用平台原生 API 优化
  • 自动/手动重置：支持两种事件重置模式
  • 超时支持：可配置的等待超时机制
  • 简洁接口：专注核心功能，避免过度设计

⚠️  重要说明：
  事件适用于线程间信号通知场景，不同于互斥锁的排他性访问控制。
  请根据具体场景选择合适的同步原语类型。

🧵 线程安全性：
  所有事件操作都是线程安全的，支持多线程并发访问。

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
  fafafa.core.sync.base,
  fafafa.core.sync.event.base
  {$IFDEF WINDOWS}
  , fafafa.core.sync.event.windows
  {$ELSE}
  , fafafa.core.sync.event.unix
  {$ENDIF};

type
  // Re-export core types
  IEvent = fafafa.core.sync.event.base.IEvent;
  TWaitResult = fafafa.core.sync.base.TWaitResult;

  {$IFDEF WINDOWS}
  TEvent = fafafa.core.sync.event.windows.TEvent;
  {$ELSE}
  TEvent = fafafa.core.sync.event.unix.TEvent;
  {$ENDIF}

const
  // Re-export wait result constants
  wrSignaled = fafafa.core.sync.base.wrSignaled;
  wrTimeout = fafafa.core.sync.base.wrTimeout;
  wrAbandoned = fafafa.core.sync.base.wrAbandoned;
  wrError = fafafa.core.sync.base.wrError;
  wrInterrupted = fafafa.core.sync.base.wrInterrupted;

{**
 * MakeEvent - 创建事件实例
 *
 * @param AManualReset 是否为手动重置事件（默认：False，自动重置）
 * @param AInitialState 初始信号状态（默认：False，未信号状态）
 * @return 事件接口实例
 *
 * @desc
 *   创建一个事件实例，自动选择当前平台的最优实现：
 *   - Windows: 基于内核事件对象的高效实现
 *   - Unix: 基于 pthread_mutex + pthread_cond 的标准实现
 *
 * @thread_safety
 *   返回的实例是线程安全的，支持多线程并发访问。
 *
 * @usage
 *   var Event := MakeEvent(True, False);  // 手动重置，初始未信号
 *   // 使用 Event...
 *}
function MakeEvent(AManualReset: Boolean = False; AInitialState: Boolean = False): IEvent;

implementation

function MakeEvent(AManualReset: Boolean; AInitialState: Boolean): IEvent;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.event.windows.TEvent.Create(AManualReset, AInitialState);
  {$ELSE}
  Result := fafafa.core.sync.event.unix.TEvent.Create(AManualReset, AInitialState);
  {$ENDIF}
end;


end.


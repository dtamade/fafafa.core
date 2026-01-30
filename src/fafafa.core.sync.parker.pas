unit fafafa.core.sync.parker;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│ fafafa.core.sync.parker - Rust 风格的线程暂停/唤醒机制                        │
│                                                                              │
│ Copyright (c) 2024 fafafaStudio                                             │
│ All rights reserved.                                                        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.parker - 线程 Park/Unpark 机制

📖 概述：
  Parker 提供了一种轻量级的线程暂停/唤醒机制，类似于 Rust 的
  std::thread::park/unpark。它比条件变量更简单，适合简单的线程同步。

🔧 特性：
  ✓ Rust park/unpark 兼容语义
  ✓ 支持 permit 机制（unpark 可以在 park 之前调用）
  ✓ 低开销实现
  ✓ 支持超时
  ✓ 跨平台支持

📝 使用示例：

  // 线程 A（等待者）
  var Parker := MakeParker;
  // ...将 Parker 传递给线程 B...
  Parker.Park;  // 等待唤醒

  // 线程 B（唤醒者）
  Parker.Unpark;  // 唤醒线程 A

  // Permit 机制示例
  Parker.Unpark;  // 先发放许可
  Parker.Park;    // 立即返回（消费许可）

🧵 线程安全性：
  所有方法都是线程安全的。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.parker.base;

type
  IParker = fafafa.core.sync.parker.base.IParker;

{**
 * MakeParker - 创建 Parker 实例
 *
 * @return Parker 接口实例
 *
 * @desc
 *   创建一个新的 Parker，初始状态无许可。
 *   自动选择当前平台的最优实现。
 *
 * @thread_safety
 *   返回的实例是线程安全的。
 *}
function MakeParker: IParker;

implementation

uses
  {$IFDEF MSWINDOWS}
  fafafa.core.sync.parker.windows
  {$ELSE}
  fafafa.core.sync.parker.unix
  {$ENDIF};

function MakeParker: IParker;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.parker.windows.MakeParker;
  {$ELSE}
  Result := fafafa.core.sync.parker.unix.MakeParker;
  {$ENDIF}
end;

end.

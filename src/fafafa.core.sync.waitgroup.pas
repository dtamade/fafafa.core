unit fafafa.core.sync.waitgroup;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│ fafafa.core.sync.waitgroup - Go 风格的等待组同步原语                         │
│                                                                              │
│ Copyright (c) 2024 fafafaStudio                                             │
│ All rights reserved.                                                        │
│                                                                              │
│ This source code is licensed under the MIT license found in the             │
│ LICENSE file in the root directory of this source tree.                     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.waitgroup - Go 风格的等待组同步原语

📖 概述：
  WaitGroup 用于等待一组并发操作完成。主线程调用 Add 设置要等待的操作数量，
  每个操作完成时调用 Done，主线程调用 Wait 阻塞直到所有操作完成。

🔧 特性：
  ✓ Go sync.WaitGroup 兼容语义
  ✓ 线程安全的原子计数器
  ✓ 支持超时等待
  ✓ 跨平台支持（Windows/Unix）
  ✓ 高性能实现（基于条件变量）

📝 使用示例：

  // 等待多个工作线程完成
  var
    WG: IWaitGroup;
  begin
    WG := MakeWaitGroup;
    WG.Add(3);  // 3 个工作任务

    // 启动工作线程
    TThread.CreateAnonymousThread(procedure begin
      // 工作 1...
      WG.Done;
    end).Start;

    TThread.CreateAnonymousThread(procedure begin
      // 工作 2...
      WG.Done;
    end).Start;

    TThread.CreateAnonymousThread(procedure begin
      // 工作 3...
      WG.Done;
    end).Start;

    WG.Wait;  // 等待所有工作完成
    WriteLn('All done!');
  end;

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
  fafafa.core.sync.waitgroup.base;

type
  // 导出接口类型
  IWaitGroup = fafafa.core.sync.waitgroup.base.IWaitGroup;

{**
 * MakeWaitGroup - 创建等待组实例
 *
 * @return 等待组接口实例
 *
 * @desc
 *   创建一个新的 WaitGroup，初始计数为 0。
 *   自动选择当前平台的最优实现。
 *
 * @thread_safety
 *   返回的实例是线程安全的。
 *
 * @usage
 *   var WG := MakeWaitGroup;
 *   WG.Add(N);
 *   // ...spawn workers that call WG.Done...
 *   WG.Wait;
 *}
function MakeWaitGroup: IWaitGroup;

implementation

uses
  {$IFDEF MSWINDOWS}
  fafafa.core.sync.waitgroup.windows
  {$ELSE}
  fafafa.core.sync.waitgroup.unix
  {$ENDIF};

function MakeWaitGroup: IWaitGroup;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.waitgroup.windows.MakeWaitGroup;
  {$ELSE}
  Result := fafafa.core.sync.waitgroup.unix.MakeWaitGroup;
  {$ENDIF}
end;

end.

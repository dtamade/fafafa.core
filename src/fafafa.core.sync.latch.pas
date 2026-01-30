unit fafafa.core.sync.latch;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│ fafafa.core.sync.latch - Java 风格的一次性倒计数同步原语                      │
│                                                                              │
│ Copyright (c) 2024 fafafaStudio                                             │
│ All rights reserved.                                                        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.latch - CountDownLatch 同步原语

📖 概述：
  CountDownLatch 是一次性的同步原语，用于等待一组事件发生。
  与 WaitGroup 不同，Latch 的计数只能减少不能增加。

🔧 特性：
  ✓ Java CountDownLatch 兼容语义
  ✓ 一次性倒计数机制
  ✓ 支持超时等待
  ✓ 跨平台支持（Windows/Unix）
  ✓ 两种典型使用模式：门控启动和完成等待

📝 使用示例（门控启动）：
  var
    StartGate: ILatch;
  begin
    StartGate := MakeLatch(1);

    // 创建等待启动的工作线程
    for i := 1 to N do
      TThread.CreateAnonymousThread(procedure begin
        StartGate.Await;  // 等待启动信号
        // 开始工作...
      end).Start;

    // 准备工作完成
    StartGate.CountDown;  // 所有线程同时开始
  end;

📝 使用示例（完成等待）：
  var
    DoneLatch: ILatch;
  begin
    DoneLatch := MakeLatch(N);

    for i := 1 to N do
      TThread.CreateAnonymousThread(procedure begin
        // 工作...
        DoneLatch.CountDown;  // 完成
      end).Start;

    DoneLatch.Await;  // 等待所有工作完成
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
  fafafa.core.sync.latch.base;

type
  ILatch = fafafa.core.sync.latch.base.ILatch;

{**
 * MakeLatch - 创建倒计数锁存器实例
 *
 * @param ACount 初始计数值（必须 >= 0）
 * @return 锁存器接口实例
 *
 * @desc
 *   创建一个新的 CountDownLatch，初始计数为 ACount。
 *   自动选择当前平台的最优实现。
 *
 * @thread_safety
 *   返回的实例是线程安全的。
 *
 * @raises EInvalidArgument 如果 ACount < 0
 *}
function MakeLatch(ACount: Integer): ILatch;

implementation

uses
  {$IFDEF MSWINDOWS}
  fafafa.core.sync.latch.windows
  {$ELSE}
  fafafa.core.sync.latch.unix
  {$ENDIF};

function MakeLatch(ACount: Integer): ILatch;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.latch.windows.MakeLatch(ACount);
  {$ELSE}
  Result := fafafa.core.sync.latch.unix.MakeLatch(ACount);
  {$ENDIF}
end;

end.

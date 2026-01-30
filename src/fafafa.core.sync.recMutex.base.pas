unit fafafa.core.sync.recMutex.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│         ______   ______     ______   ______     ______   ______             │
│        /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│        \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│         \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│          \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                               Studio                                         │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.recMutex - 跨平台高性能可重入互斥锁实现

📖 概述�?
  现代化、跨平台�?FreePascal 可重入互斥锁实现，提供统一�?API 接口�?
  支持同一线程多次获取锁，自动管理重入计数�?

🔧 特性：
  �?跨平台支持：Windows、Linux、macOS、FreeBSD �?
  �?可重入设计：同一线程可多次获取锁，自动计数管�?
  �?高性能实现：使用平台原�?API 优化
  �?三段式等待：智能退避策略减�?CPU 占用
  �?超时支持：可配置的获取超时机�?
  �?RAII 支持：自动锁管理和异常安�?

⚠️  重要说明�?
  可重入互斥锁适用于需要递归调用或嵌套锁定的场景�?
  相比普通互斥锁有额外的性能开销，请根据需要选择�?

🧵 线程安全性：
  所有可重入互斥锁操作都是线程安全的，支持多线程并发访问�?
  同一线程可以多次获取锁，必须相应次数地释放锁�?

📜 声明�?
  转发或用于个�?商业项目时，请保留本项目的版权声明�?

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

interface

uses
  fafafa.core.sync.base;

type

  {**
   * IRecMutex - 可重入互斥锁接口
   *
   * @desc
   *   可重入互斥锁的统一接口定义，继承自 ITryLock 接口�?
   *   提供线程安全的可重入锁定机制，同一线程可以多次获取锁�?
   *
   * @inheritance
   *   继承�?ITryLock，获得以下功能：
   *   - Acquire: 阻塞式获取锁
   *   - Release: 释放�?
   *   - TryAcquire: 非阻塞尝试获取锁
   *   - TryAcquire(Timeout): 带超时的尝试获取�?
   *   - LockGuard: RAII 自动锁管�?
   *
   * @reentrancy
   *   可重入特性说明：
   *   - 同一线程可以多次调用 Acquire，内部维护重入计�?
   *   - 每次 Acquire 必须对应一�?Release
   *   - 只有当重入计数归零时，锁才真正被释放
   *   - 不同线程间仍然互斥，需要等待锁的释�?
   *
   * @thread_safety
   *   完全线程安全，支持多线程并发访问�?
   *   重入特性仅限于同一线程，不同线程间保持互斥�?
   *
   * @usage_example
   *   var RecMutex: IRecMutex := MakeRecMutex;
   *   RecMutex.Acquire;  // 第一次获�?
   *   try
   *     RecMutex.Acquire;  // 重入获取，计�?2
   *     try
   *       // 嵌套临界区代�?
   *     finally
   *       RecMutex.Release;  // 释放一次，计数=1
   *     end;
   *   finally
   *     RecMutex.Release;  // 最终释放，计数=0，锁可用
   *   end;
   *
   * @performance
   *   性能特点�?
   *   - Windows: 基于 Critical Section，用户态锁，性能优异
   *   - Unix: 基于 pthread_mutex_t，系统级锁，稳定可靠
   *   - 重入计数由系统内核管理，无额外开销
   *
   * @guid '4A8E4E2F-2F38-4B2A-BE39-4F7A6E5B3C28'
   *}
  IRecMutex = interface(ITryLock)
    ['{4A8E4E2F-2F38-4B2A-BE39-4F7A6E5B3C28}']
  end;

implementation

end.


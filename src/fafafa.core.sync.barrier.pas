unit fafafa.core.sync.barrier;

{
┌──────────────────────────────────────────────────────────────────────────────�?
�?                                                                             �?
�? fafafa.core.sync.barrier - 跨平台高性能屏障同步实现                        �?
�?                                                                             �?
�? Copyright (c) 2024 fafafaStudio                                            �?
�? All rights reserved.                                                       �?
�?                                                                             �?
�? This source code is licensed under the MIT license found in the            �?
�? LICENSE file in the root directory of this source tree.                    �?
�?                                                                             �?
└──────────────────────────────────────────────────────────────────────────────�?

📦 项目：fafafa.core.sync.barrier - 跨平台高性能屏障同步实现

📖 概述�?
  现代化、跨平台�?FreePascal 屏障同步实现，提供统一�?API 接口�?

🔧 特性：
  �?跨平台支持：Windows、Linux、macOS、FreeBSD �?
  �?高性能实现：使用平台原�?API 和优化算�?
  �?线程同步：支持多线程屏障同步
  �?串行线程识别：自动识别串行线�?
  �?重用机制：支持屏障重用和多轮同步
  �?异常安全：自动资源管理和异常安全

⚠️  重要说明�?
  屏障适用于多线程同步场景，所有参与线程必须调�?Wait 方法�?
  请根据具体场景选择合适的参与者数量�?

🧵 线程安全性：
  所有屏障操作都是线程安全的，支持多线程并发访问�?

📜 声明�?
  转发或用于个�?商业项目时，请保留本项目的版权声明�?

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.barrier.base;

type

  TBarrierWaitResult = fafafa.core.sync.barrier.base.TBarrierWaitResult;
  IBarrier = fafafa.core.sync.barrier.base.IBarrier;

{**
 * MakeBarrier - 创建屏障同步实例
 *
 * @param AParticipantCount 参与线程数量，必�?> 0
 * @return 屏障接口实例
 *
 * @desc
 *   创建一个屏障同步实例，自动选择当前平台的最优实现：
 *   - Windows: 基于 SynchronizationBarrier API �?fallback 实现
 *   - Unix: 基于 pthread_barrier_t �?fallback 实现
 *
 * @thread_safety
 *   返回的实例是线程安全的，支持多线程并发访问�?
 *
 * @usage
 *   var Barrier := MakeBarrier(4);  // 4个线程的屏障
 *   // 在每个线程中调用 Barrier.Wait()
 *}
function MakeBarrier(AParticipantCount: Integer): IBarrier;

implementation

uses
  {$IFDEF MSWINDOWS}
  fafafa.core.sync.barrier.windows
  {$ELSE}
  fafafa.core.sync.barrier.unix
  {$ENDIF};

function MakeBarrier(AParticipantCount: Integer): IBarrier;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.barrier.windows.MakeBarrier(AParticipantCount);
  {$ELSE}
  Result := fafafa.core.sync.barrier.unix.MakeBarrier(AParticipantCount);
  {$ENDIF}
end;

end.


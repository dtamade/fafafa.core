unit fafafa.core.sync.spin.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 自旋锁接口 =====
  ISpinLock = interface(ILock)
    ['{C7D8E9F0-1A2B-4C5D-8E9F-0A1B2C3D4E5F}']
    // 继承 ILock 的核心方法：Acquire, Release, TryAcquire
    // 额外提供带超时的 TryAcquire 重载
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  end;

implementation


end.

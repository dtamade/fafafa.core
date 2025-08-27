unit fafafa.core.sync.conditionVariable.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base; // for ILock

type
  // ===== 条件变量接口（与 mutex 模块同模式：各自 base 单元定义自身接口） =====
  IConditionVariable = interface(ILock)
    ['{F9CAE7D8-8A7B-4E5F-9C8D-7B6A5E4D3C2B}']
    // ILock methods inherited: Acquire, Release, TryAcquire
    // Wait uses an associated external mutex (IMutex) as the common denominator across pthread/Windows.
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

end.


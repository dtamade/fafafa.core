unit fafafa.core.sync.conditionVariable.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.mutex.base; // for ILock, IMutex

type

  IConditionVariable = interface(ISynchronizable)
    ['{F9CAE7D8-8A7B-4E5F-9C8D-7B6A5E4D3C2B}']
    // 等待方法 - 接受任何 ILock 实现（包括 IMutex）
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    // 通知
    procedure Signal;
    procedure Broadcast;
  end;

implementation

end.


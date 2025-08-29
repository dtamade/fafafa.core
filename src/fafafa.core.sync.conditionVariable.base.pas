unit fafafa.core.sync.conditionVariable.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.mutex.base; // for ILock, IMutex

type

  IConditionVariable = interface(ILock)
    ['{F9CAE7D8-8A7B-4E5F-9C8D-7B6A5E4D3C2B}']
    // ILock 版本（向后兼容）
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    // 推荐的 IMutex 版本
    procedure Wait(const AMutex: IMutex); overload;
    function Wait(const AMutex: IMutex; ATimeoutMs: Cardinal): Boolean; overload;
    // 通知
    procedure Signal;
    procedure Broadcast;
  end;

implementation

end.


unit fafafa.core.sync.mutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 互斥锁接口 =====
  IMutex = interface(ILock)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    // 继承 ILock 的核心方法：Acquire, Release, TryAcquire（无超时）

    // 互斥锁特有的方法
    function GetHandle: Pointer; // 返回平台特定的句柄，用于与条件变量等配合使用
  end;

implementation


end.

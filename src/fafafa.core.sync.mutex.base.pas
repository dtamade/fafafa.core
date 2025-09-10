unit fafafa.core.sync.mutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses fafafa.core.sync.base;

type

  IMutex = interface(ITryLock)
    ['{55391DAE-AC96-4911-B998-FC8D2675FA2A}']
    function GetHandle: Pointer; // 返回平台特定的句柄
  end;

implementation


end.

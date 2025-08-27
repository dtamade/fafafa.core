unit fafafa.core.sync.recMutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // 可重入互斥锁接口（同一线程可多次 Acquire）
  IRecMutex = interface(ILock)
    ['{4A8E4E2F-2F38-4B2A-BE39-4F7A6E5B3C28}']
  end;

implementation

end.


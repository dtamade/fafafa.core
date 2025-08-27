unit fafafa.core.sync.semaphore;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.semaphore.base
  {$IFDEF WINDOWS}, fafafa.core.sync.semaphore.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.semaphore.unix{$ENDIF};

type
  ISemaphore = fafafa.core.sync.semaphore.base.ISemaphore;

  {$IFDEF WINDOWS}
  TSemaphore = fafafa.core.sync.semaphore.windows.TSemaphore;
  {$ENDIF}

  {$IFDEF UNIX}
  TSemaphore = fafafa.core.sync.semaphore.unix.TSemaphore;
  {$ENDIF}

// 创建平台特定的信号量实例
function MakeSemaphore(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISemaphore;

implementation

function MakeSemaphore(AInitialCount: Integer; AMaxCount: Integer): ISemaphore;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.semaphore.unix.TSemaphore.Create(AInitialCount, AMaxCount);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.semaphore.windows.TSemaphore.Create(AInitialCount, AMaxCount);
  {$ENDIF}
end;

end.


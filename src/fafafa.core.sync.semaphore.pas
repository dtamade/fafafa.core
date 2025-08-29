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

  // 注意：不再导出平台具体类型 TSemaphore，避免外部直接依赖实现
  // 请通过 ISemaphore 接口与 MakeSemaphore 工厂使用
  // （如确需访问具体实现，请在各自平台单元中显式引用该实现单元）

// 创建平台特定的信号量实例
function MakeSemaphore(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISemaphore;

implementation

function MakeSemaphore(AInitialCount: Integer; AMaxCount: Integer): ISemaphore;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.semaphore.unix.TSemaphore.Create(AInitialCount, AMaxCount);
  {$ELSE}
    {$IFDEF WINDOWS}
    Result := fafafa.core.sync.semaphore.windows.TSemaphore.Create(AInitialCount, AMaxCount);
    {$ELSE}
      {$WARNING Platform not supported by MakeSemaphore}
      raise ESyncError.Create('MakeSemaphore: unsupported platform');
    {$ENDIF}
  {$ENDIF}
end;

end.


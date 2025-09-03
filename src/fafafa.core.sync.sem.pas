unit fafafa.core.sync.sem;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.sem.base
  {$IFDEF WINDOWS}, fafafa.core.sync.sem.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.sem.unix{$ENDIF};

type
  ISem = fafafa.core.sync.sem.base.ISem;
  ISemGuard = fafafa.core.sync.sem.base.ISemGuard;

  // 注意：不再导出平台具体类型 TSemaphore，避免外部直接依赖实现
  // 请通过 ISem 接口与 MakeSem 工厂使用
  // （如确需访问具体实现，请在各自平台单元中显式引用该实现单元）

// 创建平台特定的信号量实例
function MakeSem(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISem;

implementation

function MakeSem(AInitialCount: Integer; AMaxCount: Integer): ISem;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.sem.unix.TSemaphore.Create(AInitialCount, AMaxCount);
  {$ELSE}
    {$IFDEF WINDOWS}
    Result := fafafa.core.sync.sem.windows.TSemaphore.Create(AInitialCount, AMaxCount);
    {$ELSE}
      {$WARNING Platform not supported by MakeSem}
      raise ESyncError.Create('MakeSem: unsupported platform');
    {$ENDIF}
  {$ENDIF}
end;



end.


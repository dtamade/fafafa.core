unit fafafa.core.sync.sem;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.sem.base;

type
  ISem = fafafa.core.sync.sem.base.ISem;
  ISemGuard = fafafa.core.sync.sem.base.ISemGuard;

  // 注意：不再导出平台具体类�?TSemaphore，避免外部直接依赖实�?
  // 请通过 ISem 接口�?MakeSem 工厂使用
  // （如确需访问具体实现，请在各自平台单元中显式引用该实现单元）

// 创建平台特定的信号量实例
function MakeSem(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISem;

implementation

uses
  {$IFDEF MSWINDOWS}
  fafafa.core.sync.sem.windows
  {$ELSE}
  fafafa.core.sync.sem.unix
  {$ENDIF};

function MakeSem(AInitialCount: Integer; AMaxCount: Integer): ISem;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.sem.windows.TSemaphore.Create(AInitialCount, AMaxCount);
  {$ELSE}
  Result := fafafa.core.sync.sem.unix.TSemaphore.Create(AInitialCount, AMaxCount);
  {$ENDIF}
end;



end.


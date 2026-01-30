unit fafafa.core.sync.namedOnce;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.namedOnce.base;

// 重导出基础类型
type
  TNamedOnceState = fafafa.core.sync.namedOnce.base.TNamedOnceState;
  TNamedOnceConfig = fafafa.core.sync.namedOnce.base.TNamedOnceConfig;
  TOnceCallback = fafafa.core.sync.namedOnce.base.TOnceCallback;
  TOnceCallbackMethod = fafafa.core.sync.namedOnce.base.TOnceCallbackMethod;
  INamedOnce = fafafa.core.sync.namedOnce.base.INamedOnce;

const
  nosNotStarted = fafafa.core.sync.namedOnce.base.nosNotStarted;
  nosInProgress = fafafa.core.sync.namedOnce.base.nosInProgress;
  nosCompleted = fafafa.core.sync.namedOnce.base.nosCompleted;
  nosPoisoned = fafafa.core.sync.namedOnce.base.nosPoisoned;

// 工厂函数
function MakeNamedOnce(const AName: string): INamedOnce;
function MakeNamedOnce(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce;

// 配置辅助函数（重导出）
function DefaultNamedOnceConfig: TNamedOnceConfig; inline;
function NamedOnceConfigWithTimeout(ATimeoutMs: Cardinal): TNamedOnceConfig; inline;
function GlobalNamedOnceConfig: TNamedOnceConfig; inline;

implementation

uses
  {$IFDEF WINDOWS}
  fafafa.core.sync.namedOnce.windows;
  {$ELSE}
  fafafa.core.sync.namedOnce.unix;
  {$ENDIF}

function MakeNamedOnce(const AName: string): INamedOnce;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedOnce.windows.MakeNamedOnce(AName);
  {$ELSE}
  Result := fafafa.core.sync.namedOnce.unix.MakeNamedOnce(AName);
  {$ENDIF}
end;

function MakeNamedOnce(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedOnce.windows.MakeNamedOnce(AName, AConfig);
  {$ELSE}
  Result := fafafa.core.sync.namedOnce.unix.MakeNamedOnce(AName, AConfig);
  {$ENDIF}
end;

function DefaultNamedOnceConfig: TNamedOnceConfig;
begin
  Result := fafafa.core.sync.namedOnce.base.DefaultNamedOnceConfig;
end;

function NamedOnceConfigWithTimeout(ATimeoutMs: Cardinal): TNamedOnceConfig;
begin
  Result := fafafa.core.sync.namedOnce.base.NamedOnceConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedOnceConfig: TNamedOnceConfig;
begin
  Result := fafafa.core.sync.namedOnce.base.GlobalNamedOnceConfig;
end;

end.

unit fafafa.core.sync.namedWaitGroup;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.namedWaitGroup.base;

// 重导出基础类型
type
  TNamedWaitGroupConfig = fafafa.core.sync.namedWaitGroup.base.TNamedWaitGroupConfig;
  INamedWaitGroup = fafafa.core.sync.namedWaitGroup.base.INamedWaitGroup;

// 工厂函数
function MakeNamedWaitGroup(const AName: string): INamedWaitGroup;
function MakeNamedWaitGroup(const AName: string;
  const AConfig: TNamedWaitGroupConfig): INamedWaitGroup;

// 配置辅助函数（重导出）
function DefaultNamedWaitGroupConfig: TNamedWaitGroupConfig; inline;
function NamedWaitGroupConfigWithTimeout(ATimeoutMs: Cardinal): TNamedWaitGroupConfig; inline;
function GlobalNamedWaitGroupConfig: TNamedWaitGroupConfig; inline;

implementation

uses
  {$IFDEF WINDOWS}
  fafafa.core.sync.namedWaitGroup.windows;
  {$ELSE}
  fafafa.core.sync.namedWaitGroup.unix;
  {$ENDIF}

function MakeNamedWaitGroup(const AName: string): INamedWaitGroup;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedWaitGroup.windows.MakeNamedWaitGroup(AName);
  {$ELSE}
  Result := fafafa.core.sync.namedWaitGroup.unix.MakeNamedWaitGroup(AName);
  {$ENDIF}
end;

function MakeNamedWaitGroup(const AName: string;
  const AConfig: TNamedWaitGroupConfig): INamedWaitGroup;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedWaitGroup.windows.MakeNamedWaitGroup(AName, AConfig);
  {$ELSE}
  Result := fafafa.core.sync.namedWaitGroup.unix.MakeNamedWaitGroup(AName, AConfig);
  {$ENDIF}
end;

function DefaultNamedWaitGroupConfig: TNamedWaitGroupConfig;
begin
  Result := fafafa.core.sync.namedWaitGroup.base.DefaultNamedWaitGroupConfig;
end;

function NamedWaitGroupConfigWithTimeout(ATimeoutMs: Cardinal): TNamedWaitGroupConfig;
begin
  Result := fafafa.core.sync.namedWaitGroup.base.NamedWaitGroupConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedWaitGroupConfig: TNamedWaitGroupConfig;
begin
  Result := fafafa.core.sync.namedWaitGroup.base.GlobalNamedWaitGroupConfig;
end;

end.

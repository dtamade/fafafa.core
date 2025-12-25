unit fafafa.core.sync.namedLatch;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.namedLatch.base;

// 重导出基础类型
type
  TNamedLatchConfig = fafafa.core.sync.namedLatch.base.TNamedLatchConfig;
  INamedLatch = fafafa.core.sync.namedLatch.base.INamedLatch;

// 工厂函数
function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch;
function MakeNamedLatch(const AName: string; AInitialCount: Cardinal;
  const AConfig: TNamedLatchConfig): INamedLatch;

// 配置辅助函数（重导出）
function DefaultNamedLatchConfig: TNamedLatchConfig; inline;
function NamedLatchConfigWithTimeout(ATimeoutMs: Cardinal): TNamedLatchConfig; inline;
function GlobalNamedLatchConfig: TNamedLatchConfig; inline;

implementation

uses
  {$IFDEF WINDOWS}
  fafafa.core.sync.namedLatch.windows;
  {$ELSE}
  fafafa.core.sync.namedLatch.unix;
  {$ENDIF}

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedLatch.windows.MakeNamedLatch(AName, AInitialCount);
  {$ELSE}
  Result := fafafa.core.sync.namedLatch.unix.MakeNamedLatch(AName, AInitialCount);
  {$ENDIF}
end;

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal;
  const AConfig: TNamedLatchConfig): INamedLatch;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedLatch.windows.MakeNamedLatch(AName, AInitialCount, AConfig);
  {$ELSE}
  Result := fafafa.core.sync.namedLatch.unix.MakeNamedLatch(AName, AInitialCount, AConfig);
  {$ENDIF}
end;

function DefaultNamedLatchConfig: TNamedLatchConfig;
begin
  Result := fafafa.core.sync.namedLatch.base.DefaultNamedLatchConfig;
end;

function NamedLatchConfigWithTimeout(ATimeoutMs: Cardinal): TNamedLatchConfig;
begin
  Result := fafafa.core.sync.namedLatch.base.NamedLatchConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedLatchConfig: TNamedLatchConfig;
begin
  Result := fafafa.core.sync.namedLatch.base.GlobalNamedLatchConfig;
end;

end.

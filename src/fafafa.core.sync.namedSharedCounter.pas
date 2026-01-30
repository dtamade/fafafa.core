unit fafafa.core.sync.namedSharedCounter;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.namedSharedCounter.base;

// 重导出基础类型
type
  TNamedSharedCounterConfig = fafafa.core.sync.namedSharedCounter.base.TNamedSharedCounterConfig;
  INamedSharedCounter = fafafa.core.sync.namedSharedCounter.base.INamedSharedCounter;

// 工厂函数
function MakeNamedSharedCounter(const AName: string): INamedSharedCounter;
function MakeNamedSharedCounter(const AName: string;
  const AConfig: TNamedSharedCounterConfig): INamedSharedCounter;

// 配置辅助函数（重导出）
function DefaultNamedSharedCounterConfig: TNamedSharedCounterConfig; inline;
function NamedSharedCounterConfigWithInitial(AInitialValue: Int64): TNamedSharedCounterConfig; inline;
function GlobalNamedSharedCounterConfig: TNamedSharedCounterConfig; inline;

implementation

uses
  {$IFDEF WINDOWS}
  fafafa.core.sync.namedSharedCounter.windows;
  {$ELSE}
  fafafa.core.sync.namedSharedCounter.unix;
  {$ENDIF}

function MakeNamedSharedCounter(const AName: string): INamedSharedCounter;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedSharedCounter.windows.MakeNamedSharedCounter(AName);
  {$ELSE}
  Result := fafafa.core.sync.namedSharedCounter.unix.MakeNamedSharedCounter(AName);
  {$ENDIF}
end;

function MakeNamedSharedCounter(const AName: string;
  const AConfig: TNamedSharedCounterConfig): INamedSharedCounter;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedSharedCounter.windows.MakeNamedSharedCounter(AName, AConfig);
  {$ELSE}
  Result := fafafa.core.sync.namedSharedCounter.unix.MakeNamedSharedCounter(AName, AConfig);
  {$ENDIF}
end;

function DefaultNamedSharedCounterConfig: TNamedSharedCounterConfig;
begin
  Result := fafafa.core.sync.namedSharedCounter.base.DefaultNamedSharedCounterConfig;
end;

function NamedSharedCounterConfigWithInitial(AInitialValue: Int64): TNamedSharedCounterConfig;
begin
  Result := fafafa.core.sync.namedSharedCounter.base.NamedSharedCounterConfigWithInitial(AInitialValue);
end;

function GlobalNamedSharedCounterConfig: TNamedSharedCounterConfig;
begin
  Result := fafafa.core.sync.namedSharedCounter.base.GlobalNamedSharedCounterConfig;
end;

end.

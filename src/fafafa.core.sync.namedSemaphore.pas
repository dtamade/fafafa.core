unit fafafa.core.sync.namedSemaphore;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.namedSemaphore.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedSemaphore.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedSemaphore.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedSemaphoreGuard = fafafa.core.sync.namedSemaphore.base.INamedSemaphoreGuard;
  INamedSemaphore = fafafa.core.sync.namedSemaphore.base.INamedSemaphore;
  TNamedSemaphoreConfig = fafafa.core.sync.namedSemaphore.base.TNamedSemaphoreConfig;

  // 注意：TNamedSemaphore 具体类型不再公开导出
  // 用户应该只使�?INamedSemaphore 接口和工厂函�?

// ===== 现代化工厂函数 =====
// 主要工厂函数：使用配置创建命名信号量
function CreateNamedSemaphore(const AName: string; const AConfig: TNamedSemaphoreConfig): INamedSemaphore;

// 便利工厂函数
function CreateNamedSemaphore(const AName: string): INamedSemaphore; overload;
function CreateNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore; overload;
function CreateGlobalNamedSemaphore(const AName: string): INamedSemaphore;
function CreateGlobalNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;

implementation

// ===== 内部工厂函数实现 =====

function InternalMake(const AName: string; const AConfig: TNamedSemaphoreConfig): INamedSemaphore;
var
  LActualName: string;
begin
  // 处理全局命名空间（平台特定逻辑内部化）
  LActualName := AName;
  {$IFDEF WINDOWS}
  if AConfig.UseGlobalNamespace and (Pos('Global\', AName) <> 1) then
    LActualName := 'Global\' + AName;
  {$ENDIF}
  {$IFDEF UNIX}
  // Unix 平台：命名信号量默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedSemaphore.unix.TNamedSemaphore.Create(LActualName, AConfig);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedSemaphore.windows.TNamedSemaphore.Create(LActualName, AConfig);
  {$ENDIF}
end;

// ===== 主要工厂函数实现 =====

function CreateNamedSemaphore(const AName: string; const AConfig: TNamedSemaphoreConfig): INamedSemaphore;
begin
  Result := InternalMake(AName, AConfig);
end;

function CreateNamedSemaphore(const AName: string): INamedSemaphore;
begin
  Result := InternalMake(AName, DefaultNamedSemaphoreConfig);
end;

function CreateNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
begin
  Result := InternalMake(AName, NamedSemaphoreConfigWithCount(AInitialCount, AMaxCount));
end;

function CreateGlobalNamedSemaphore(const AName: string): INamedSemaphore;
begin
  Result := InternalMake(AName, GlobalNamedSemaphoreConfig);
end;

function CreateGlobalNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
var
  LConfig: TNamedSemaphoreConfig;
begin
  LConfig := GlobalNamedSemaphoreConfig;
  LConfig.InitialCount := AInitialCount;
  LConfig.MaxCount := AMaxCount;
  Result := InternalMake(AName, LConfig);
end;

end.

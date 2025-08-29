unit fafafa.core.sync.namedMutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.namedMutex.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedMutex.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedMutex.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedMutexGuard = fafafa.core.sync.namedMutex.base.INamedMutexGuard;
  INamedMutex = fafafa.core.sync.namedMutex.base.INamedMutex;
  TNamedMutexConfig = fafafa.core.sync.namedMutex.base.TNamedMutexConfig;

  // 注意：TNamedMutex 具体类型不再公开导出
  // 用户应该只使用 INamedMutex 接口和工厂函数

// ===== 现代化工厂函数 =====
// 主要工厂函数：使用配置创建命名互斥锁
function CreateNamedMutex(const AName: string; const AConfig: TNamedMutexConfig): INamedMutex;

// 便利工厂函数
function CreateNamedMutex(const AName: string): INamedMutex; overload;
function CreateNamedMutex(const AName: string; ATimeoutMs: Cardinal): INamedMutex; overload;
function CreateGlobalNamedMutex(const AName: string): INamedMutex;

// ===== 兼容性工厂函数（已弃用） =====
function MakeNamedMutex(const AName: string): INamedMutex; overload; deprecated 'Use CreateNamedMutex instead';
function MakeNamedMutex(const AName: string; AInitialOwner: Boolean): INamedMutex; overload; deprecated 'Use CreateNamedMutex instead';
function TryOpenNamedMutex(const AName: string): INamedMutex; deprecated 'Use CreateNamedMutex instead';
function MakeGlobalNamedMutex(const AName: string): INamedMutex; overload; deprecated 'Use CreateGlobalNamedMutex instead';
function MakeGlobalNamedMutex(const AName: string; AInitialOwner: Boolean): INamedMutex; overload; deprecated 'Use CreateGlobalNamedMutex instead';

implementation

// ===== 现代化工厂函数实现 =====

function CreateNamedMutex(const AName: string; const AConfig: TNamedMutexConfig): INamedMutex;
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
  // Unix 平台：命名互斥锁默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedMutex.unix.TNamedMutex.Create(LActualName, AConfig.InitialOwner);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedMutex.windows.TNamedMutex.Create(LActualName, AConfig.InitialOwner);
  {$ENDIF}
end;

function CreateNamedMutex(const AName: string): INamedMutex;
begin
  Result := CreateNamedMutex(AName, DefaultNamedMutexConfig);
end;

function CreateNamedMutex(const AName: string; ATimeoutMs: Cardinal): INamedMutex;
begin
  Result := CreateNamedMutex(AName, NamedMutexConfigWithTimeout(ATimeoutMs));
end;

function CreateGlobalNamedMutex(const AName: string): INamedMutex;
begin
  Result := CreateNamedMutex(AName, GlobalNamedMutexConfig);
end;

// ===== 兼容性工厂函数实现 =====

function MakeNamedMutex(const AName: string): INamedMutex;
begin
  Result := CreateNamedMutex(AName);
end;

function MakeNamedMutex(const AName: string; AInitialOwner: Boolean): INamedMutex;
var
  LConfig: TNamedMutexConfig;
begin
  LConfig := DefaultNamedMutexConfig;
  LConfig.InitialOwner := AInitialOwner;
  Result := CreateNamedMutex(AName, LConfig);
end;

function TryOpenNamedMutex(const AName: string): INamedMutex;
begin
  Result := CreateNamedMutex(AName);
end;

function MakeGlobalNamedMutex(const AName: string): INamedMutex;
begin
  Result := CreateGlobalNamedMutex(AName);
end;

function MakeGlobalNamedMutex(const AName: string; AInitialOwner: Boolean): INamedMutex;
var
  LConfig: TNamedMutexConfig;
begin
  LConfig := GlobalNamedMutexConfig;
  LConfig.InitialOwner := AInitialOwner;
  Result := CreateNamedMutex(AName, LConfig);
end;

end.

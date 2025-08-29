unit fafafa.core.sync.namedRWLock;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.namedRWLock.base
  {$IFDEF WINDOWS}, fafafa.core.sync.namedRWLock.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.namedRWLock.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  INamedRWLockReadGuard = fafafa.core.sync.namedRWLock.base.INamedRWLockReadGuard;
  INamedRWLockWriteGuard = fafafa.core.sync.namedRWLock.base.INamedRWLockWriteGuard;
  INamedRWLock = fafafa.core.sync.namedRWLock.base.INamedRWLock;
  TNamedRWLockConfig = fafafa.core.sync.namedRWLock.base.TNamedRWLockConfig;

  // 注意：TNamedRWLock 具体类型不再公开导出
  // 用户应该只使用 INamedRWLock 接口和工厂函数

// ===== 工厂函数 =====

{ 创建命名读写锁 - 推荐的现代化 API }
function CreateNamedRWLock(const AName: string; const AConfig: TNamedRWLockConfig): INamedRWLock; overload;
function CreateNamedRWLock(const AName: string): INamedRWLock; overload;

{ 便利函数 - 简化常用场景 }
function MakeNamedRWLock(const AName: string): INamedRWLock; inline;
function MakeNamedRWLock(const AName: string; AInitialOwner: Boolean): INamedRWLock; overload;
function MakeGlobalNamedRWLock(const AName: string): INamedRWLock;
function TryOpenNamedRWLock(const AName: string): INamedRWLock;

{ 配置辅助函数 - 重新导出 }
function DefaultNamedRWLockConfig: TNamedRWLockConfig; inline;
function NamedRWLockConfigWithTimeout(ATimeoutMs: Cardinal): TNamedRWLockConfig; inline;
function GlobalNamedRWLockConfig: TNamedRWLockConfig; inline;

implementation

function CreateNamedRWLock(const AName: string; const AConfig: TNamedRWLockConfig): INamedRWLock;
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
  // Unix 平台：命名读写锁默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedRWLock.unix.TNamedRWLock.Create(LActualName, AConfig.InitialOwner);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedRWLock.windows.TNamedRWLock.Create(LActualName, AConfig.InitialOwner);
  {$ENDIF}
end;

function CreateNamedRWLock(const AName: string): INamedRWLock;
begin
  Result := CreateNamedRWLock(AName, DefaultNamedRWLockConfig);
end;

function MakeNamedRWLock(const AName: string): INamedRWLock;
begin
  Result := CreateNamedRWLock(AName);
end;

function MakeNamedRWLock(const AName: string; AInitialOwner: Boolean): INamedRWLock;
var
  LConfig: TNamedRWLockConfig;
begin
  LConfig := DefaultNamedRWLockConfig;
  LConfig.InitialOwner := AInitialOwner;
  Result := CreateNamedRWLock(AName, LConfig);
end;

function MakeGlobalNamedRWLock(const AName: string): INamedRWLock;
begin
  Result := CreateNamedRWLock(AName, GlobalNamedRWLockConfig);
end;

function TryOpenNamedRWLock(const AName: string): INamedRWLock;
begin
  try
    // 尝试创建/打开现有的命名读写锁
    Result := CreateNamedRWLock(AName);
  except
    // 如果失败，返回 nil
    Result := nil;
  end;
end;

function DefaultNamedRWLockConfig: TNamedRWLockConfig;
begin
  Result := fafafa.core.sync.namedRWLock.base.DefaultNamedRWLockConfig;
end;

function NamedRWLockConfigWithTimeout(ATimeoutMs: Cardinal): TNamedRWLockConfig;
begin
  Result := fafafa.core.sync.namedRWLock.base.NamedRWLockConfigWithTimeout(ATimeoutMs);
end;

function GlobalNamedRWLockConfig: TNamedRWLockConfig;
begin
  Result := fafafa.core.sync.namedRWLock.base.GlobalNamedRWLockConfig;
end;

end.

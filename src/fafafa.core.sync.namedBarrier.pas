unit fafafa.core.sync.namedBarrier;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedBarrier.base;

// ===== 类型别名 =====
type
  INamedBarrier = fafafa.core.sync.namedBarrier.base.INamedBarrier;
  INamedBarrierGuard = fafafa.core.sync.namedBarrier.base.INamedBarrierGuard;
  TNamedBarrierConfig = fafafa.core.sync.namedBarrier.base.TNamedBarrierConfig;
  TNamedBarrierError = fafafa.core.sync.namedBarrier.base.TNamedBarrierError;
  TNamedBarrierResult = fafafa.core.sync.namedBarrier.base.TNamedBarrierResult;
  TNamedBarrierGuardResult = fafafa.core.sync.namedBarrier.base.TNamedBarrierGuardResult;
  TNamedBarrierBoolResult = fafafa.core.sync.namedBarrier.base.TNamedBarrierBoolResult;
  TNamedBarrierCardinalResult = fafafa.core.sync.namedBarrier.base.TNamedBarrierCardinalResult;
  TNamedBarrierVoidResult = fafafa.core.sync.namedBarrier.base.TNamedBarrierVoidResult;

// ===== 现代化工厂函数 =====

{ 创建命名屏障 - 推荐使用的现代化接口 }
function CreateNamedBarrier(const AName: string; const AConfig: TNamedBarrierConfig): INamedBarrier; overload;
function CreateNamedBarrier(const AName: string): INamedBarrier; overload;
function CreateNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier; overload;

{ 尝试打开现有的命名屏障 }
function TryOpenNamedBarrier(const AName: string): INamedBarrier;

// ===== 增量接口：基于 TResult 的现代化工厂函数 =====

{ 创建命名屏障 - 返回 TResult 包装的结果 }
function CreateNamedBarrierResult(const AName: string; const AConfig: TNamedBarrierConfig): TNamedBarrierResult; overload;
function CreateNamedBarrierResult(const AName: string): TNamedBarrierResult; overload;
function CreateNamedBarrierResult(const AName: string; AParticipantCount: Cardinal): TNamedBarrierResult; overload;

{ 尝试打开现有的命名屏障 - 返回 TResult 包装的结果 }
function TryOpenNamedBarrierResult(const AName: string): TNamedBarrierResult;

{ 创建全局命名屏障 - 返回 TResult 包装的结果 }
function CreateGlobalNamedBarrierResult(const AName: string): TNamedBarrierResult;
function CreateGlobalNamedBarrierResult(const AName: string; AParticipantCount: Cardinal): TNamedBarrierResult; overload;

// ===== 便利函数 =====

{ 创建命名屏障 - 兼容性接口 }
function MakeNamedBarrier(const AName: string): INamedBarrier; deprecated 'Use CreateNamedBarrier instead';
function MakeNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier; overload; deprecated 'Use CreateNamedBarrier instead';

{ 创建全局命名屏障 }
function MakeGlobalNamedBarrier(const AName: string): INamedBarrier; deprecated 'Use CreateNamedBarrier with GlobalNamedBarrierConfig instead';
function CreateGlobalNamedBarrier(const AName: string): INamedBarrier;
function CreateGlobalNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier; overload;

// ===== 配置函数重新导出 =====
function DefaultNamedBarrierConfig: TNamedBarrierConfig;
function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
function GlobalNamedBarrierConfig: TNamedBarrierConfig;

implementation

uses
  {$IFDEF UNIX}
  fafafa.core.sync.namedBarrier.unix;
  {$ENDIF}
  {$IFDEF WINDOWS}
  fafafa.core.sync.namedBarrier.windows;
  {$ENDIF}

// ===== 现代化工厂函数实现 =====

function CreateNamedBarrier(const AName: string; const AConfig: TNamedBarrierConfig): INamedBarrier;
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
  // Unix 平台：命名屏障默认就是全局的，无需特殊处理
  {$ENDIF}

  // 创建平台特定实例（完全隐藏实现细节）
  {$IFDEF UNIX}
  Result := fafafa.core.sync.namedBarrier.unix.TNamedBarrier.Create(LActualName, AConfig);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.namedBarrier.windows.TNamedBarrier.Create(LActualName, AConfig);
  {$ENDIF}
end;

function CreateNamedBarrier(const AName: string): INamedBarrier;
begin
  Result := CreateNamedBarrier(AName, DefaultNamedBarrierConfig);
end;

function CreateNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := DefaultNamedBarrierConfig;
  LConfig.ParticipantCount := AParticipantCount;
  Result := CreateNamedBarrier(AName, LConfig);
end;

function TryOpenNamedBarrier(const AName: string): INamedBarrier;
begin
  try
    // 尝试创建/打开屏障，如果失败返回 nil
    Result := CreateNamedBarrier(AName);
  except
    Result := nil;
  end;
end;

// ===== 便利函数实现 =====

function MakeNamedBarrier(const AName: string): INamedBarrier;
begin
  Result := CreateNamedBarrier(AName);
end;

function MakeNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier;
begin
  Result := CreateNamedBarrier(AName, AParticipantCount);
end;

function MakeGlobalNamedBarrier(const AName: string): INamedBarrier;
begin
  Result := CreateGlobalNamedBarrier(AName);
end;

function CreateGlobalNamedBarrier(const AName: string): INamedBarrier;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := GlobalNamedBarrierConfig;
  Result := CreateNamedBarrier(AName, LConfig);
end;

function CreateGlobalNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := GlobalNamedBarrierConfig;
  LConfig.ParticipantCount := AParticipantCount;
  Result := CreateNamedBarrier(AName, LConfig);
end;

// ===== 配置函数重新导出 =====

function DefaultNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.DefaultNamedBarrierConfig;
end;

function NamedBarrierConfigWithTimeout(ATimeoutMs: Cardinal): TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.NamedBarrierConfigWithTimeout(ATimeoutMs);
end;

function NamedBarrierConfigWithParticipants(AParticipantCount: Cardinal): TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.NamedBarrierConfigWithParticipants(AParticipantCount);
end;

function GlobalNamedBarrierConfig: TNamedBarrierConfig;
begin
  Result := fafafa.core.sync.namedBarrier.base.GlobalNamedBarrierConfig;
end;

// ===== 增量接口实现：基于 TResult 的现代化工厂函数 =====

function CreateNamedBarrierResult(const AName: string; const AConfig: TNamedBarrierConfig): TNamedBarrierResult;
begin
  try
    Result := TNamedBarrierResult.Ok(CreateNamedBarrier(AName, AConfig));
  except
    on E: EInvalidArgument do
      Result := TNamedBarrierResult.Err(nbeInvalidArgument);
    on E: ELockError do
      Result := TNamedBarrierResult.Err(nbeSystemError);
    on E: ETimeoutError do
      Result := TNamedBarrierResult.Err(nbeTimeout);
    on E: Exception do
      Result := TNamedBarrierResult.Err(nbeUnknownError);
  end;
end;

function CreateNamedBarrierResult(const AName: string): TNamedBarrierResult;
begin
  Result := CreateNamedBarrierResult(AName, DefaultNamedBarrierConfig);
end;

function CreateNamedBarrierResult(const AName: string; AParticipantCount: Cardinal): TNamedBarrierResult;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := DefaultNamedBarrierConfig;
  LConfig.ParticipantCount := AParticipantCount;
  Result := CreateNamedBarrierResult(AName, LConfig);
end;

function TryOpenNamedBarrierResult(const AName: string): TNamedBarrierResult;
begin
  try
    Result := TNamedBarrierResult.Ok(CreateNamedBarrier(AName));
  except
    on E: EInvalidArgument do
      Result := TNamedBarrierResult.Err(nbeInvalidArgument);
    on E: ELockError do
      Result := TNamedBarrierResult.Err(nbeNotFound);
    on E: Exception do
      Result := TNamedBarrierResult.Err(nbeUnknownError);
  end;
end;

function CreateGlobalNamedBarrierResult(const AName: string): TNamedBarrierResult;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := GlobalNamedBarrierConfig;
  Result := CreateNamedBarrierResult(AName, LConfig);
end;

function CreateGlobalNamedBarrierResult(const AName: string; AParticipantCount: Cardinal): TNamedBarrierResult;
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := GlobalNamedBarrierConfig;
  LConfig.ParticipantCount := AParticipantCount;
  Result := CreateNamedBarrierResult(AName, LConfig);
end;

end.

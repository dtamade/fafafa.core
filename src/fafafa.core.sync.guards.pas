unit fafafa.core.sync.guards;

{**
 * fafafa.core.sync.guards - 同步原语 Guard 基类
 *
 * @desc
 *   提供同步原语 RAII Guard 的公共基类和工具函数。
 *   消除各平台实现中的代码重复。
 *
 * @author fafafaStudio
 * @version 1.0.0
 * @since 2025-12
 *}

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fafafa.core.sync.base;

type
  {**
   * Guard 基类 - 提供 RAII Guard 的公共功能
   *
   * 派生类需要：
   * 1. 添加平台特定的句柄字段
   * 2. 重写 DoRelease 方法实现实际释放逻辑
   *}
  TNamedGuardBase = class(TInterfacedObject)
  private
    FName: string;
    FReleased: Boolean;
  protected
    {** 执行实际的资源释放，派生类必须重写 *}
    procedure DoRelease; virtual; abstract;

    {** 检查 Guard 是否已释放，未释放则抛出异常 *}
    procedure CheckNotReleased;

    {** 标记为已释放状态 *}
    procedure MarkReleased;

    {** 获取释放状态 *}
    function GetReleased: Boolean;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;

    {** 获取关联的资源名称 *}
    function GetName: string;

    {** 检查是否仍持有锁 *}
    function IsLocked: Boolean;

    {** 手动释放资源（通常由析构函数自动调用） *}
    procedure Release;

    property Name: string read FName;
    property Released: Boolean read FReleased;
  end;

  {**
   * 简单锁 Guard 基类 - 适用于 Mutex、Semaphore 等简单锁
   *
   * 使用泛型句柄类型以支持不同平台
   *}
  generic TTypedGuardBase<THandle> = class(TNamedGuardBase)
  private
    FHandle: THandle;
  protected
    property Handle: THandle read FHandle;
  public
    constructor Create(AHandle: THandle; const AName: string);
  end;

  {**
   * 读写锁 Guard 基类 - 适用于 RWLock 的读/写 Guard
   *}
  TRWLockGuardBase = class(TNamedGuardBase)
  private
    FLock: Pointer;  // 指向父 RWLock 对象
  protected
    property Lock: Pointer read FLock;
  public
    constructor Create(ALock: Pointer; const AName: string);
  end;

  {**
   * 屏障 Guard 基类 - 适用于 Barrier 的等待结果 Guard
   *}
  TBarrierGuardBase = class(TNamedGuardBase)
  private
    FBarrier: Pointer;
    FIsLastParticipant: Boolean;
    FGeneration: Cardinal;
    FWaitTime: Cardinal;
    FStartTime: QWord;
  protected
    procedure DoRelease; override;
    procedure UpdateWaitTime;
    property Barrier: Pointer read FBarrier;
  public
    constructor Create(ABarrier: Pointer; const AName: string;
      AIsLastParticipant: Boolean; AGeneration: Cardinal);

    function IsLastParticipant: Boolean;
    function GetGeneration: Cardinal;
    function GetWaitTime: Cardinal;
  end;

implementation

{ TNamedGuardBase }

constructor TNamedGuardBase.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FReleased := False;
end;

destructor TNamedGuardBase.Destroy;
begin
  if not FReleased then
    Release;
  inherited Destroy;
end;

function TNamedGuardBase.GetName: string;
begin
  Result := FName;
end;

function TNamedGuardBase.IsLocked: Boolean;
begin
  Result := not FReleased;
end;

procedure TNamedGuardBase.Release;
begin
  if not FReleased then
  begin
    DoRelease;
    FReleased := True;
  end;
end;

procedure TNamedGuardBase.CheckNotReleased;
begin
  if FReleased then
    raise ELockError.CreateFmt('Guard for "%s" has already been released', [FName]);
end;

procedure TNamedGuardBase.MarkReleased;
begin
  FReleased := True;
end;

function TNamedGuardBase.GetReleased: Boolean;
begin
  Result := FReleased;
end;

{ TTypedGuardBase }

constructor TTypedGuardBase.Create(AHandle: THandle; const AName: string);
begin
  inherited Create(AName);
  FHandle := AHandle;
end;

{ TRWLockGuardBase }

constructor TRWLockGuardBase.Create(ALock: Pointer; const AName: string);
begin
  inherited Create(AName);
  FLock := ALock;
end;

{ TBarrierGuardBase }

constructor TBarrierGuardBase.Create(ABarrier: Pointer; const AName: string;
  AIsLastParticipant: Boolean; AGeneration: Cardinal);
begin
  inherited Create(AName);
  FBarrier := ABarrier;
  FIsLastParticipant := AIsLastParticipant;
  FGeneration := AGeneration;
  FWaitTime := 0;
  FStartTime := GetTickCount64;
end;

procedure TBarrierGuardBase.DoRelease;
begin
  UpdateWaitTime;
  // Barrier Guard 不需要显式释放资源，只需记录等待时间
end;

procedure TBarrierGuardBase.UpdateWaitTime;
begin
  if FWaitTime = 0 then
    FWaitTime := GetTickCount64 - FStartTime;
end;

function TBarrierGuardBase.IsLastParticipant: Boolean;
begin
  Result := FIsLastParticipant;
end;

function TBarrierGuardBase.GetGeneration: Cardinal;
begin
  Result := FGeneration;
end;

function TBarrierGuardBase.GetWaitTime: Cardinal;
begin
  if Released then
    Result := FWaitTime
  else
    Result := GetTickCount64 - FStartTime;
end;

end.

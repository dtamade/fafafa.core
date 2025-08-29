unit fafafa.core.sync.base;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.cpu;

type
  // ===== Exceptions =====
  ESyncError = class(Exception);
  ELockError = class(ESyncError);
  ETimeoutError = class(ESyncError);
  EDeadlockError = class(ESyncError);
  EInvalidArgument = class(ESyncError);
  EOnceRecursiveCall = class(ELockError);


  TWaitResult = (
    wrSignaled,     // 信号状态
    wrTimeout,      // 超时
    wrAbandoned,    // 被放弃 (拥有者异常终止)
    wrError,        // 一般错误
    wrInterrupted   // 被信号中断 (Unix)
  );


  { 基础同步原语接口 - 所有同步对象的基础 }
  ISynchronizable = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function  GetData: Pointer;
    procedure SetData(aData: Pointer);
    property  Data: Pointer read GetData write SetData;
  end;

  TSynchronizable = class(TInterfacedObject, ISynchronizable)
  private
    FData: Pointer;
  public
    function  GetData: Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    procedure SetData(aData: Pointer); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

  ILockGuard = interface
    ['{A8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    procedure Release;
  end;

    { 互斥锁接口 }
  ILock = interface(ISynchronizable)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    procedure Acquire;
    procedure Release;
    function  LockGuard: ILockGuard;
  end;

  TLock =class(TSynchronizable, ILock)
  public
    // ILock 接口实现
    procedure Acquire; virtual; abstract;
    procedure Release; virtual; abstract;
    function  LockGuard: ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

  TLockClass = class of TLock;

  ITryLock = interface(ILock)
    ['{C8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  end;

  TTryLock = class(TLock, ITryLock)
  public
    function TryAcquire: Boolean; overload; virtual; abstract;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; virtual;
  end;


  TLockGuard = class(TInterfacedObject, ILockGuard)
  private
    FLock: ILock;
    FReleased: Boolean;
  public
    constructor Create(ALock: ILock);                    // 阻塞获取锁
    constructor CreateFromAcquired(ALock: ILock);        // 从已获取的锁创建
    destructor Destroy; override;
    procedure Release; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

function MutexGuard(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function MakeLockGuard(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF} // 向后兼容
function MakeLockGuardFromAcquired(ALock: ILock): ILockGuard; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation


function MutexGuard(ALock: ILock): ILockGuard;
begin
  Result := TLockGuard.Create(ALock);
end;

function MakeLockGuard(ALock: ILock): ILockGuard;
begin
  Result := MutexGuard(ALock); // 向后兼容，调用新函数
end;

function MakeLockGuardFromAcquired(ALock: ILock): ILockGuard;
begin
  Result := TLockGuard.CreateFromAcquired(ALock);
end;

{ TLockGuard }

constructor TLockGuard.Create(ALock: ILock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  FLock.Acquire;
end;

constructor TLockGuard.CreateFromAcquired(ALock: ILock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
end;

destructor TLockGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TLockGuard.Release;
begin
  if not FReleased and Assigned(FLock) then
  begin
    FLock.Release;
    FReleased := True;
  end;
end;


{ TSynchronizable }

function TSynchronizable.GetData: Pointer;
begin
  Result := FData;
end;

procedure TSynchronizable.SetData(aData: Pointer);
begin
  FData := aData;
end;

{ TLock - 基础锁抽象类实现 }

function TLock.LockGuard: ILockGuard;
begin
  Result := MakeLockGuard(Self);
end;

{ TTryLock - 扩展锁实现 }

function TTryLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  EndTime: QWord;
  SpinCount: Cardinal;
  YieldCount: Cardinal;
begin
  // 零超时，立即尝试
  if ATimeoutMs = 0 then
    Exit(TryAcquire());

  // 预计算结束时间，避免重复计算
  EndTime := GetTickCount64 + ATimeoutMs;

  // 阶段1: 紧密自旋（0延迟，适合短期竞争）
  for SpinCount := 1 to 2000 do
  begin
    if TryAcquire() then Exit(True);
    CpuRelax;  // 使用跨平台 CPU 暂停指令
  end;

  // 阶段2: 继续优化自旋（适合中期竞争）
  for YieldCount := 1 to 50 do
  begin
    if TryAcquire() then Exit(True);
    if GetTickCount64 >= EndTime then Exit(False);

    CpuRelax;  // 继续使用 CPU 暂停指令
  end;

  // 阶段3: 渐进式延迟（适合长期竞争）
  repeat
    if GetTickCount64 >= EndTime then Exit(False);
    if TryAcquire() then Exit(True);

    Sleep(1);  // 最小延迟，真正让出 CPU
  until False;
end;

end.


unit fafafa.core.sync.mutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  {$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  Windows,
  {$ENDIF}
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base;

type
  { 传统互斥锁实现 - 使用 CRITICAL_SECTION（兼容 Windows XP+）}
  TMutex = class(TTryLock, IMutex)
  private
    FCriticalSection: TRTLCriticalSection;
    FOwnerThreadId: DWORD;
    FIsLocked: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    // ITryLock 继承的方法
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;

    // IMutex 特有方法
    function GetHandle: Pointer;
  end;

{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  { 现代互斥锁实现 - 使用 SRWLOCK（要求 Windows Vista+）}
  TSRWMutex = class(TTryLock, IMutex)
  private
    FLock: SRWLOCK;
  public
    constructor Create;
    destructor Destroy; override;

    // ITryLock 继承的方法
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;

    // IMutex 特有方法
    function GetHandle: Pointer;
  end;
{$ENDIF}


function MakeMutex: IMutex; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}


implementation

function MakeMutex: IMutex;
begin
  {$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  Result := TSRWMutex.Create;
  {$ELSE}
  Result := TMutex.Create;
  {$ENDIF}
end;



{ TMutex - 传统 CRITICAL_SECTION 实现 }

constructor TMutex.Create;
begin
  inherited Create;
  FOwnerThreadId := 0;
  FIsLocked := False;
  InitializeCriticalSection(FCriticalSection);
end;

destructor TMutex.Destroy;
begin
  DeleteCriticalSection(FCriticalSection);
  inherited Destroy;
end;

procedure TMutex.Acquire;
var
  CurrentThreadId: DWORD;
begin
  CurrentThreadId := GetCurrentThreadId;

  // 使用 CRITICAL_SECTION + 重入检查
  EnterCriticalSection(FCriticalSection);
  try
    if FIsLocked and (FOwnerThreadId = CurrentThreadId) then
    begin
      // 检测到重入，需要先退出临界区再抛异常
      LeaveCriticalSection(FCriticalSection);
      raise ELockError.Create('Non-reentrant mutex: reentrancy detected');
    end;
    FOwnerThreadId := CurrentThreadId;
    FIsLocked := True;
  except
    LeaveCriticalSection(FCriticalSection);
    raise;
  end;
end;

procedure TMutex.Release;
begin
  // 在 CRITICAL_SECTION 保护下检查所有权
  EnterCriticalSection(FCriticalSection);
  try
    if not FIsLocked or (FOwnerThreadId <> GetCurrentThreadId) then
      raise ELockError.Create('Mutex not owned by current thread');
    FOwnerThreadId := 0;
    FIsLocked := False;
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
end;

function TMutex.TryAcquire: Boolean;
var
  CurrentThreadId: DWORD;
begin
  CurrentThreadId := GetCurrentThreadId;

  // 使用 TryEnterCriticalSection
  if TryEnterCriticalSection(FCriticalSection) then
  begin
    try
      if FIsLocked and (FOwnerThreadId = CurrentThreadId) then
      begin
        // 检测到重入
        LeaveCriticalSection(FCriticalSection);
        Result := False;
      end
      else
      begin
        FOwnerThreadId := CurrentThreadId;
        FIsLocked := True;
        Result := True;
      end;
    except
      LeaveCriticalSection(FCriticalSection);
      Result := False;
    end;
  end
  else
  begin
    Result := False;
  end;
end;


function TMutex.GetHandle: Pointer;
begin
  Result := @FCriticalSection;
end;

{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
{ TSRWMutex - 现代 SRWLOCK 实现 }

constructor TSRWMutex.Create;
begin
  inherited Create;
  InitializeSRWLock(FLock);
end;

destructor TSRWMutex.Destroy;
begin
  inherited Destroy;
end;

procedure TSRWMutex.Acquire;
begin
  // 使用 SRWLOCK（天然不可重入，重入会自动死锁）
  AcquireSRWLockExclusive(FLock);
end;

procedure TSRWMutex.Release;
begin
  ReleaseSRWLockExclusive(FLock);
end;

function TSRWMutex.TryAcquire: Boolean;
begin
  Result := TryAcquireSRWLockExclusive(FLock);
end;

function TSRWMutex.GetHandle: Pointer;
begin
  Result := @FLock;
end;
{$ENDIF}

end.
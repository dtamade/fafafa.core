unit fafafa.core.sync.mutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.mutex.base;

type
  TMutex = class(TInterfacedObject, IMutex)
  private
    FCS: TRTLCriticalSection;
  public
    constructor Create; overload;
    constructor Create(ASpinCount: DWORD); overload;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function GetHandle: Pointer;

    // Windows 特有的优化方法
    function SetSpinCount(ASpinCount: DWORD): DWORD; // 返回之前的自旋计数
  end;

implementation

{ TMutex }

constructor TMutex.Create;
begin
  Create(4000); // 使用默认自旋计数
end;

constructor TMutex.Create(ASpinCount: DWORD);
begin
  inherited Create;
  // 使用带自旋计数的初始化，在多核系统上性能更好
  // 自旋计数允许线程在进入内核等待前先自旋一段时间
  if not InitializeCriticalSectionAndSpinCount(FCS, ASpinCount) then
  begin
    // 如果失败，回退到基本初始化
    try
      InitializeCriticalSection(FCS);
    except
      raise ELockError.Create('Failed to initialize critical section');
    end;
  end;
end;

destructor TMutex.Destroy;
begin
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

procedure TMutex.Acquire;
begin
  try
    EnterCriticalSection(FCS);
  except
    raise ELockError.Create('Failed to acquire critical section');
  end;
end;

procedure TMutex.Release;
begin
  try
    LeaveCriticalSection(FCS);
  except
    raise ELockError.Create('Failed to release critical section');
  end;
end;

function TMutex.TryAcquire: Boolean;
begin
  try
    Result := TryEnterCriticalSection(FCS);
  except
    Result := False;
    raise ELockError.Create('Failed to try acquire critical section');
  end;
end;



function TMutex.GetHandle: Pointer;
begin
  Result := @FCS;
end;

function TMutex.SetSpinCount(ASpinCount: DWORD): DWORD;
begin
  // 注意：在多线程环境下调用此方法需要谨慎
  // 建议在没有其他线程使用此互斥锁时调用
  try
    Result := SetCriticalSectionSpinCount(FCS, ASpinCount);
  except
    Result := 0;
    raise ELockError.Create('Failed to set critical section spin count');
  end;
end;

end.


unit fafafa.core.sync.spinMutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.spinMutex.base,
  fafafa.core.sync.mutex;

type
  // 混合自旋互斥：先自旋若干次尝试 TryAcquire，失败后调用阻塞 Acquire
  TSpinMutex = class(TInterfacedObject, ILock)
  private
    FSpinRounds: Integer;
    FMutex: IMutex; // 底层实际互斥
    FLastError: TWaitError;
  public
    constructor Create(ASpinRounds: Integer = 1000);
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function GetLastError: TWaitError;
  end;

implementation

{ TSpinMutex }

{ TSpinMutex }

constructor TSpinMutex.Create(ASpinRounds: Integer);
begin
  inherited Create;
  if ASpinRounds <= 0 then ASpinRounds := 1000;
  FSpinRounds := ASpinRounds;
  FMutex := MakeMutex; // 底层互斥（不支持命名）
  FLastError := weNone;
end;

function TSpinMutex.TryAcquire: Boolean;
begin
  // 快速路径：底层互斥的 TryAcquire
  Result := FMutex.TryAcquire;
  if Result then FLastError := weNone else FLastError := FMutex.GetLastError;
end;

function TSpinMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var start: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  start := GetTickCount64;
  while GetTickCount64 - start < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;
  Result := False;
end;

procedure TSpinMutex.Acquire;
var spins, k: Integer;
begin
  // 先自旋若干次
  spins := 0;
  while spins < FSpinRounds do
  begin
    if FMutex.TryAcquire then Exit; // 自旋成功拿到锁
    // 退避：短暂停顿
    for k := 1 to (1 shl (spins and 7)) do ;
    Inc(spins);
    if (spins and $FF) = 0 then Sleep(0);
  end;
  // 自旋失败，走阻塞互斥
  FMutex.Acquire;
  FLastError := weNone;
end;

procedure TSpinMutex.Release;
begin
  // 直接释放底层互斥
  FMutex.Release;
  // 直接释放底层互斥（底层会设置自身错误码）
end;

function TSpinMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

end.






end.

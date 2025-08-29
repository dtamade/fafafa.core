unit fafafa.core.sync.spinMutex.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.spinMutex.base,
  fafafa.core.sync.mutex;

type
  // 简化的 Unix 平台自旋互斥锁实现
  TSpinMutex = class(TInterfacedObject, ISpinMutex)
  private
    FSpinRounds: Integer;
    FMutex: IMutex; // 底层实际互斥
    FLastError: TWaitError;
  public
    constructor Create(ASpinRounds: Integer = 1000);

    // ILock 接口
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function GetLastError: TWaitError;
  end;

implementation

{ TSpinMutex }

constructor TSpinMutex.Create(ASpinRounds: Integer);
begin
  inherited Create;
  if ASpinRounds <= 0 then ASpinRounds := 1000;
  FSpinRounds := ASpinRounds;
  FMutex := MakeMutex(); // 底层互斥
  FLastError := weNone;
end;

procedure TSpinMutex.Acquire;
var
  spins, k: Integer;
begin
  // 先自旋若干次
  spins := 0;
  while spins < FSpinRounds do
  begin
    if FMutex.TryAcquire then
    begin
      FLastError := weNone;
      Exit; // 自旋成功拿到锁
    end;

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
  FMutex.Release;
  FLastError := FMutex.GetLastError;
end;

function TSpinMutex.TryAcquire: Boolean;
begin
  Result := FMutex.TryAcquire;
  if Result then
    FLastError := weNone
  else
    FLastError := FMutex.GetLastError;
end;

function TSpinMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  start: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);

  start := GetTickCount64;
  while GetTickCount64 - start < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;

  FLastError := weTimeout;
  Result := False;
end;

function TSpinMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

end.
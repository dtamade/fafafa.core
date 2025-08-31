unit fafafa.core.sync.mutex.parkinglot.base;

{$I fafafa.core.settings.inc}

interface
  
uses
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base;


const
  LOCKED_BIT = $01;  // 0b01 - 锁定位
  PARKED_BIT = $02;  // 0b10 - 有线程等待位

type

  IParkingLotMutex = interface(IMutex)
    ['{C0A1B2C3-D4E5-F6A7-B8C9-D0E1F2A3B4C5}']
  end;

  TParkingLotMutex = class(TTryLock, IParkingLotMutex)
  protected
    FState: LongWord;  // 原子状态
  
    function  TryLockFast: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    procedure LockSlow(ATimeoutMs: Cardinal = INFINITE); virtual;
    procedure UnlockSlow(AForceFair: Boolean);
    function  ShouldSpin(var ASpinCount: Integer): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

    procedure ParkThread(ATimeoutMs: Cardinal = INFINITE); virtual; abstract;
    function  UnparkOneThread: Boolean; virtual; abstract;
  public
    constructor Create;
    procedure   Acquire; override;
    procedure   Release; override;
    function    TryAcquire: Boolean; override;
    function    TryAcquire(ATimeoutMs: Cardinal): Boolean; override;
  end;

implementation

uses
  fafafa.core.atomic;

{ TParkingLotMutex }

function TParkingLotMutex.TryLockFast: Boolean;
begin

end;

procedure TParkingLotMutex.LockSlow(ATimeoutMs: Cardinal);
begin

end;

procedure TParkingLotMutex.UnlockSlow(AForceFair: Boolean);
begin

end;

function TParkingLotMutex.ShouldSpin(var ASpinCount: Integer): Boolean;
begin

end;

constructor TParkingLotMutex.Create;
begin
  inherited Create;
  FState := 0;
end;

procedure TParkingLotMutex.Acquire;
begin
  if not TryLockFast then
    LockSlow(INFINITE);
end;

procedure TParkingLotMutex.Release;
begin
  if atomic_load(var FState) = LOCKED_BIT then
    Exit; // 快速路径：没有等待者

  UnlockSlow(False);
end;

function TParkingLotMutex.TryAcquire: Boolean;
begin
  Result := TryLockFast;
end;




  

  
end.
unit fafafa.core.lockfree.channel;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.atomic,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.blocking,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.michaelScottQueue,
  fafafa.core.lockfree.mpmcQueue;

type
  generic TLockFreeChannelBase<T, TQueue> = class(TInterfacedObject)
  strict protected
    FQueue: TQueue;
    FState: Int32;
    FBlockingPolicy: IBlockingPolicy;
    function InternalTrySend(constref aItem: T): Boolean; virtual; abstract;
    function InternalTryReceive(out aItem: T): Boolean; virtual; abstract;
    function QueueIsFull: Boolean; virtual; abstract;
    function QueueIsEmpty: Boolean; virtual; abstract;
    function QueueCount: SizeInt; virtual; abstract;
    function QueueCapacity: SizeInt; virtual; abstract;

    function DoSend(constref aItem: T; aTimeoutUs: Int64): TLockFreeSendResult;
    function DoReceive(out aItem: T; aTimeoutUs: Int64): TLockFreeRecvResult;
    function DoSendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
    function DoReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
    procedure DoComplete;
    procedure DoCancel;
    function DoWaitSendReady(aTimeoutUs: Int64): Boolean;
    function DoWaitReceiveReady(aTimeoutUs: Int64): Boolean;
    function CurrentState: TLockFreeChannelState; inline;

    constructor Create(const aQueue: TQueue; const aBlocking: IBlockingPolicy);
    procedure FreeQueue; virtual;
  private
    function GetStateValue: TLockFreeChannelState; inline;
    function TryTransition(aFrom, aTo: TLockFreeChannelState): Boolean; inline;
    function MakeDeadline(aTimeoutUs: Int64): Int64; inline;
    function DeadlineExpired(const aDeadline: Int64): Boolean; inline;
    procedure StepBlocking(var aSpinCount: Integer; const aDeadline: Int64; out aTimedOut: Boolean); inline;
  end;

  generic TLockFreeChannelMPMC<T> = class(specialize TLockFreeChannelBase<T, specialize TPreAllocMPMCQueue<T>>, specialize ILockFreeChannelMPMC<T>)
  protected
    function InternalTrySend(constref aItem: T): Boolean; override;
    function InternalTryReceive(out aItem: T): Boolean; override;
    function QueueIsFull: Boolean; override;
    function QueueIsEmpty: Boolean; override;
    function QueueCount: SizeInt; override;
    function QueueCapacity: SizeInt; override;
  public
    constructor Create(aCapacity: SizeInt = 1024; aBlocking: IBlockingPolicy = nil);
    destructor Destroy; override;
    function Send(constref aItem: T; aTimeoutUs: Int64 = -1): TLockFreeSendResult;
    function Receive(out aItem: T; aTimeoutUs: Int64 = -1): TLockFreeRecvResult;
    function TrySend(constref aItem: T): Boolean;
    function TryReceive(out aItem: T): Boolean;
    function SendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
    function ReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
    procedure Complete;
    procedure Cancel;
    function State: TLockFreeChannelState;
    function WaitSendReady(aTimeoutUs: Int64 = -1): Boolean;
    function WaitReceiveReady(aTimeoutUs: Int64 = -1): Boolean;
    function Count: SizeInt;
    function Capacity: SizeInt;
  end;

  generic TLockFreeChannelSPSC<T> = class(specialize TLockFreeChannelBase<T, specialize TSPSCQueue<T>>, specialize ILockFreeChannelSPSC<T>)
  protected
    function InternalTrySend(constref aItem: T): Boolean; override;
    function InternalTryReceive(out aItem: T): Boolean; override;
    function QueueIsFull: Boolean; override;
    function QueueIsEmpty: Boolean; override;
    function QueueCount: SizeInt; override;
    function QueueCapacity: SizeInt; override;
  public
    constructor Create(aCapacity: SizeInt = 1024; aBlocking: IBlockingPolicy = nil);
    destructor Destroy; override;
    function Send(constref aItem: T; aTimeoutUs: Int64 = -1): TLockFreeSendResult;
    function Receive(out aItem: T; aTimeoutUs: Int64 = -1): TLockFreeRecvResult;
    function TrySend(constref aItem: T): Boolean;
    function TryReceive(out aItem: T): Boolean;
    function SendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
    function ReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
    procedure Complete;
    procedure Cancel;
    function State: TLockFreeChannelState;
    function WaitSendReady(aTimeoutUs: Int64 = -1): Boolean;
    function WaitReceiveReady(aTimeoutUs: Int64 = -1): Boolean;
    function Count: SizeInt;
    function Capacity: SizeInt;
  end;

  generic TLockFreeChannelMPSC<T> = class(specialize TLockFreeChannelBase<T, specialize TMichaelScottQueue<T>>, specialize ILockFreeChannelMPSC<T>)
  protected
    function InternalTrySend(constref aItem: T): Boolean; override;
    function InternalTryReceive(out aItem: T): Boolean; override;
    function QueueIsFull: Boolean; override;
    function QueueIsEmpty: Boolean; override;
    function QueueCount: SizeInt; override;
    function QueueCapacity: SizeInt; override;
  public
    constructor Create(aBlocking: IBlockingPolicy = nil);
    destructor Destroy; override;
    function Send(constref aItem: T; aTimeoutUs: Int64 = -1): TLockFreeSendResult;
    function Receive(out aItem: T; aTimeoutUs: Int64 = -1): TLockFreeRecvResult;
    function TrySend(constref aItem: T): Boolean;
    function TryReceive(out aItem: T): Boolean;
    function SendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
    function ReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
    procedure Complete;
    procedure Cancel;
    function State: TLockFreeChannelState;
    function WaitSendReady(aTimeoutUs: Int64 = -1): Boolean;
    function WaitReceiveReady(aTimeoutUs: Int64 = -1): Boolean;
    function Count: SizeInt;
    function Capacity: SizeInt;
  end;

function CreateLockFreeChannelMPMC<T>(aCapacity: SizeInt = 1024): specialize ILockFreeChannelMPMC<T>;
function CreateLockFreeChannelSPSC<T>(aCapacity: SizeInt = 1024): specialize ILockFreeChannelSPSC<T>;
function CreateLockFreeChannelMPSC<T>: specialize ILockFreeChannelMPSC<T>;

implementation

const
  CHANNEL_STATE_MASK = Ord(High(TLockFreeChannelState));

function NowMicroseconds: Int64; inline;
begin
  Result := Int64(GetTickCount64) * 1000;
end;

{ TLockFreeChannelBase }

constructor TLockFreeChannelBase.Create(const aQueue: TQueue; const aBlocking: IBlockingPolicy);
begin
  inherited Create;
  if aQueue = nil then
    raise EArgumentNil.Create('Channel queue cannot be nil');
  FQueue := aQueue;
  FBlockingPolicy := aBlocking;
  if FBlockingPolicy = nil then
    FBlockingPolicy := GetDefaultBlockingPolicy;
  atomic_store(FState, Ord(csOpen), mo_release);
end;

procedure TLockFreeChannelBase.FreeQueue;
begin
  if TObject(FQueue) <> nil then
    TObject(FQueue).Free;
end;

function TLockFreeChannelBase.GetStateValue: TLockFreeChannelState;
begin
  Result := TLockFreeChannelState(atomic_load(FState, mo_acquire) and CHANNEL_STATE_MASK);
end;

function TLockFreeChannelBase.CurrentState: TLockFreeChannelState;
begin
  Result := GetStateValue;
end;

function TLockFreeChannelBase.TryTransition(aFrom, aTo: TLockFreeChannelState): Boolean;
var
  LExpected: Int32;
begin
  LExpected := Ord(aFrom);
  Result := atomic_compare_exchange_strong(FState, LExpected, Ord(aTo));
end;

function TLockFreeChannelBase.MakeDeadline(aTimeoutUs: Int64): Int64;
begin
  if aTimeoutUs < 0 then
    Exit(-1);
  Result := NowMicroseconds + aTimeoutUs;
end;

function TLockFreeChannelBase.DeadlineExpired(const aDeadline: Int64): Boolean;
begin
  Result := (aDeadline >= 0) and (NowMicroseconds >= aDeadline);
end;

procedure TLockFreeChannelBase.StepBlocking(var aSpinCount: Integer; const aDeadline: Int64; out aTimedOut: Boolean);
begin
  FBlockingPolicy.Step(aSpinCount);
  aTimedOut := DeadlineExpired(aDeadline);
end;

function TLockFreeChannelBase.DoSend(constref aItem: T; aTimeoutUs: Int64): TLockFreeSendResult;
var
  LDeadline: Int64;
  LSpin: Integer = 0;
  LTimedOut: Boolean;
  LState: TLockFreeChannelState;
begin
  LDeadline := MakeDeadline(aTimeoutUs);
  repeat
    LState := CurrentState;
    case LState of
      csOpen:
        begin
          if InternalTrySend(aItem) then
            Exit(srOk);
          if DeadlineExpired(LDeadline) then
            Exit(srTimedOut);
          StepBlocking(LSpin, LDeadline, LTimedOut);
          if LTimedOut then
            Exit(srTimedOut);
        end;
      csClosing, csClosed:
        Exit(srClosed);
      csFaulted:
        Exit(srCanceled);
    end;
  until False;
end;

function TLockFreeChannelBase.DoReceive(out aItem: T; aTimeoutUs: Int64): TLockFreeRecvResult;
var
  LDeadline: Int64;
  LSpin: Integer = 0;
  LTimedOut: Boolean;
  LState: TLockFreeChannelState;
begin
  LDeadline := MakeDeadline(aTimeoutUs);
  repeat
    if InternalTryReceive(aItem) then
      Exit(rrOk);

    LState := CurrentState;
    case LState of
      csClosing:
        begin
          if QueueIsEmpty and TryTransition(csClosing, csClosed) then
            Exit(rrClosed);
        end;
      csClosed:
        Exit(rrClosed);
      csFaulted:
        Exit(rrCanceled);
    end;

    if DeadlineExpired(LDeadline) then
      Exit(rrTimedOut);
    StepBlocking(LSpin, LDeadline, LTimedOut);
    if LTimedOut then
      Exit(rrTimedOut);
  until False;
end;

function TLockFreeChannelBase.DoSendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
var
  i: SizeInt;
  LResult: TLockFreeSendResult;
begin
  aSent := 0;
  if Length(aItems) = 0 then
    Exit(srOk);
  for i := 0 to High(aItems) do
  begin
    LResult := DoSend(aItems[i], -1);
    if LResult <> srOk then
      Exit(LResult);
    Inc(aSent);
  end;
  Result := srOk;
end;

function TLockFreeChannelBase.DoReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
var
  i: SizeInt;
  LResult: TLockFreeRecvResult;
begin
  aReceived := 0;
  if Length(aBuffer) = 0 then
    Exit(rrOk);
  for i := 0 to High(aBuffer) do
  begin
    LResult := DoReceive(aBuffer[i], 0);
    if LResult <> rrOk then
    begin
      if (LResult = rrTimedOut) and (aReceived > 0) then
        Exit(rrOk);
      Exit(LResult);
    end;
    Inc(aReceived);
  end;
  Result := rrOk;
end;

procedure TLockFreeChannelBase.DoComplete;
begin
  while True do
  begin
    case CurrentState of
      csOpen:
        if TryTransition(csOpen, csClosing) then Exit;
      csClosing, csClosed, csFaulted:
        Exit;
    end;
  end;
end;

procedure TLockFreeChannelBase.DoCancel;
begin
  atomic_store(FState, Ord(csFaulted), mo_release);
end;

function TLockFreeChannelBase.DoWaitSendReady(aTimeoutUs: Int64): Boolean;
var
  LDeadline: Int64;
  LSpin: Integer = 0;
  LTimedOut: Boolean;
begin
  LDeadline := MakeDeadline(aTimeoutUs);
  repeat
    if CurrentState <> csOpen then
      Exit(False);
    if not QueueIsFull then
      Exit(True);
    if DeadlineExpired(LDeadline) then
      Exit(False);
    StepBlocking(LSpin, LDeadline, LTimedOut);
    if LTimedOut then
      Exit(False);
  until False;
end;

function TLockFreeChannelBase.DoWaitReceiveReady(aTimeoutUs: Int64): Boolean;
var
  LDeadline: Int64;
  LSpin: Integer = 0;
  LTimedOut: Boolean;
  LState: TLockFreeChannelState;
begin
  LDeadline := MakeDeadline(aTimeoutUs);
  repeat
    if not QueueIsEmpty then
      Exit(True);
    LState := CurrentState;
    if LState in [csClosed, csFaulted] then
      Exit(False);
    if (LState = csClosing) and QueueIsEmpty then
      Exit(False);
    if DeadlineExpired(LDeadline) then
      Exit(False);
    StepBlocking(LSpin, LDeadline, LTimedOut);
    if LTimedOut then
      Exit(False);
  until False;
end;

{ TLockFreeChannelMPMC }

constructor TLockFreeChannelMPMC.Create(aCapacity: SizeInt; aBlocking: IBlockingPolicy);
begin
  if aCapacity <= 0 then
    raise EInvalidArgument.Create('Channel capacity must be positive');
  inherited Create(TPreAllocMPMCQueue<T>.Create(aCapacity), aBlocking);
end;

destructor TLockFreeChannelMPMC.Destroy;
begin
  FreeQueue;
  inherited Destroy;
end;

function TLockFreeChannelMPMC.InternalTrySend(constref aItem: T): Boolean;
begin
  Result := FQueue.Enqueue(aItem);
end;

function TLockFreeChannelMPMC.InternalTryReceive(out aItem: T): Boolean;
begin
  Result := FQueue.Dequeue(aItem);
end;

function TLockFreeChannelMPMC.QueueIsFull: Boolean;
begin
  Result := FQueue.IsFull;
end;

function TLockFreeChannelMPMC.QueueIsEmpty: Boolean;
begin
  Result := FQueue.IsEmpty;
end;

function TLockFreeChannelMPMC.QueueCount: SizeInt;
begin
  Result := FQueue.GetSize;
end;

function TLockFreeChannelMPMC.QueueCapacity: SizeInt;
begin
  Result := FQueue.GetCapacity;
end;

function TLockFreeChannelMPMC.Send(constref aItem: T; aTimeoutUs: Int64): TLockFreeSendResult;
begin
  Result := DoSend(aItem, aTimeoutUs);
end;

function TLockFreeChannelMPMC.Receive(out aItem: T; aTimeoutUs: Int64): TLockFreeRecvResult;
begin
  Result := DoReceive(aItem, aTimeoutUs);
end;

function TLockFreeChannelMPMC.TrySend(constref aItem: T): Boolean;
begin
  Result := (CurrentState = csOpen) and InternalTrySend(aItem);
end;

function TLockFreeChannelMPMC.TryReceive(out aItem: T): Boolean;
begin
  Result := InternalTryReceive(aItem);
end;

function TLockFreeChannelMPMC.SendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
begin
  Result := DoSendMany(aItems, aSent);
end;

function TLockFreeChannelMPMC.ReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
begin
  Result := DoReceiveMany(aBuffer, aReceived);
end;

procedure TLockFreeChannelMPMC.Complete;
begin
  DoComplete;
end;

procedure TLockFreeChannelMPMC.Cancel;
begin
  DoCancel;
end;

function TLockFreeChannelMPMC.State: TLockFreeChannelState;
begin
  Result := CurrentState;
end;

function TLockFreeChannelMPMC.WaitSendReady(aTimeoutUs: Int64): Boolean;
begin
  Result := DoWaitSendReady(aTimeoutUs);
end;

function TLockFreeChannelMPMC.WaitReceiveReady(aTimeoutUs: Int64): Boolean;
begin
  Result := DoWaitReceiveReady(aTimeoutUs);
end;

function TLockFreeChannelMPMC.Count: SizeInt;
begin
  Result := QueueCount;
end;

function TLockFreeChannelMPMC.Capacity: SizeInt;
begin
  Result := QueueCapacity;
end;

{ TLockFreeChannelSPSC }

constructor TLockFreeChannelSPSC.Create(aCapacity: SizeInt; aBlocking: IBlockingPolicy);
begin
  if aCapacity <= 0 then
    raise EInvalidArgument.Create('Channel capacity must be positive');
  inherited Create(TSPSCQueue<T>.Create(aCapacity), aBlocking);
end;

destructor TLockFreeChannelSPSC.Destroy;
begin
  FreeQueue;
  inherited Destroy;
end;

function TLockFreeChannelSPSC.InternalTrySend(constref aItem: T): Boolean;
begin
  Result := FQueue.Enqueue(aItem);
end;

function TLockFreeChannelSPSC.InternalTryReceive(out aItem: T): Boolean;
begin
  Result := FQueue.Dequeue(aItem);
end;

function TLockFreeChannelSPSC.QueueIsFull: Boolean;
begin
  Result := FQueue.IsFull;
end;

function TLockFreeChannelSPSC.QueueIsEmpty: Boolean;
begin
  Result := FQueue.IsEmpty;
end;

function TLockFreeChannelSPSC.QueueCount: SizeInt;
begin
  Result := FQueue.Size;
end;

function TLockFreeChannelSPSC.QueueCapacity: SizeInt;
begin
  Result := FQueue.Capacity;
end;

function TLockFreeChannelSPSC.Send(constref aItem: T; aTimeoutUs: Int64): TLockFreeSendResult;
begin
  Result := DoSend(aItem, aTimeoutUs);
end;

function TLockFreeChannelSPSC.Receive(out aItem: T; aTimeoutUs: Int64): TLockFreeRecvResult;
begin
  Result := DoReceive(aItem, aTimeoutUs);
end;

function TLockFreeChannelSPSC.TrySend(constref aItem: T): Boolean;
begin
  Result := (CurrentState = csOpen) and InternalTrySend(aItem);
end;

function TLockFreeChannelSPSC.TryReceive(out aItem: T): Boolean;
begin
  Result := InternalTryReceive(aItem);
end;

function TLockFreeChannelSPSC.SendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
begin
  Result := DoSendMany(aItems, aSent);
end;

function TLockFreeChannelSPSC.ReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
begin
  Result := DoReceiveMany(aBuffer, aReceived);
end;

procedure TLockFreeChannelSPSC.Complete;
begin
  DoComplete;
end;

procedure TLockFreeChannelSPSC.Cancel;
begin
  DoCancel;
end;

function TLockFreeChannelSPSC.State: TLockFreeChannelState;
begin
  Result := CurrentState;
end;

function TLockFreeChannelSPSC.WaitSendReady(aTimeoutUs: Int64): Boolean;
begin
  Result := DoWaitSendReady(aTimeoutUs);
end;

function TLockFreeChannelSPSC.WaitReceiveReady(aTimeoutUs: Int64): Boolean;
begin
  Result := DoWaitReceiveReady(aTimeoutUs);
end;

function TLockFreeChannelSPSC.Count: SizeInt;
begin
  Result := QueueCount;
end;

function TLockFreeChannelSPSC.Capacity: SizeInt;
begin
  Result := QueueCapacity;
end;

{ TLockFreeChannelMPSC }

constructor TLockFreeChannelMPSC.Create(aBlocking: IBlockingPolicy);
begin
  inherited Create(TMichaelScottQueue<T>.Create, aBlocking);
end;

destructor TLockFreeChannelMPSC.Destroy;
begin
  FreeQueue;
  inherited Destroy;
end;

function TLockFreeChannelMPSC.InternalTrySend(constref aItem: T): Boolean;
begin
  FQueue.Enqueue(aItem);
  Result := True;
end;

function TLockFreeChannelMPSC.InternalTryReceive(out aItem: T): Boolean;
begin
  Result := FQueue.Dequeue(aItem);
end;

function TLockFreeChannelMPSC.QueueIsFull: Boolean;
begin
  Result := False; // unbounded
end;

function TLockFreeChannelMPSC.QueueIsEmpty: Boolean;
begin
  Result := FQueue.IsEmpty;
end;

function TLockFreeChannelMPSC.QueueCount: SizeInt;
begin
  Result := -1; // not supported
end;

function TLockFreeChannelMPSC.QueueCapacity: SizeInt;
begin
  Result := -1;
end;

function TLockFreeChannelMPSC.Send(constref aItem: T; aTimeoutUs: Int64): TLockFreeSendResult;
begin
  Result := DoSend(aItem, aTimeoutUs);
end;

function TLockFreeChannelMPSC.Receive(out aItem: T; aTimeoutUs: Int64): TLockFreeRecvResult;
begin
  Result := DoReceive(aItem, aTimeoutUs);
end;

function TLockFreeChannelMPSC.TrySend(constref aItem: T): Boolean;
begin
  Result := (CurrentState = csOpen) and InternalTrySend(aItem);
end;

function TLockFreeChannelMPSC.TryReceive(out aItem: T): Boolean;
begin
  Result := InternalTryReceive(aItem);
end;

function TLockFreeChannelMPSC.SendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
begin
  Result := DoSendMany(aItems, aSent);
end;

function TLockFreeChannelMPSC.ReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;
begin
  Result := DoReceiveMany(aBuffer, aReceived);
end;

procedure TLockFreeChannelMPSC.Complete;
begin
  DoComplete;
end;

procedure TLockFreeChannelMPSC.Cancel;
begin
  DoCancel;
end;

function TLockFreeChannelMPSC.State: TLockFreeChannelState;
begin
  Result := CurrentState;
end;

function TLockFreeChannelMPSC.WaitSendReady(aTimeoutUs: Int64): Boolean;
begin
  Result := DoWaitSendReady(aTimeoutUs);
end;

function TLockFreeChannelMPSC.WaitReceiveReady(aTimeoutUs: Int64): Boolean;
begin
  Result := DoWaitReceiveReady(aTimeoutUs);
end;

function TLockFreeChannelMPSC.Count: SizeInt;
begin
  Result := QueueCount;
end;

function TLockFreeChannelMPSC.Capacity: SizeInt;
begin
  Result := QueueCapacity;
end;

function CreateLockFreeChannelMPMC<T>(aCapacity: SizeInt): specialize ILockFreeChannelMPMC<T>;
begin
  Result := specialize TLockFreeChannelMPMC<T>.Create(aCapacity);
end;

function CreateLockFreeChannelSPSC<T>(aCapacity: SizeInt): specialize ILockFreeChannelSPSC<T>;
begin
  Result := specialize TLockFreeChannelSPSC<T>.Create(aCapacity);
end;

function CreateLockFreeChannelMPSC<T>: specialize ILockFreeChannelMPSC<T>;
begin
  Result := specialize TLockFreeChannelMPSC<T>.Create;
end;

end.


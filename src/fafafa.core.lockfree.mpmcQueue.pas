unit fafafa.core.lockfree.mpmcQueue;


{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.lockfree.stats, fafafa.core.lockfree.util, fafafa.core.atomic,
  fafafa.core.lockfree.backoff,
  fafafa.core.collections.queue;

type
  generic TPreAllocMPMCQueue<T> = class(TInterfacedObject, specialize IQueue<T>)
  public
    type
      PSlot = ^TSlot;
      TSlot = record
        Data: T;
        Sequence: Int64;
      end;
  private
    FBuffer: array of TSlot;
    FCapacity: Integer;
    FMask: Integer;
    {$IFDEF FAFAFA_LOCKFREE_CACHELINE_PAD}
    FPad0: array[0..63] of Byte; // padding to avoid false sharing between mask and enqueue
    {$ENDIF}
    FEnqueuePos: Int64;
    {$IFDEF FAFAFA_LOCKFREE_CACHELINE_PAD}
    FPad1: array[0..63] of Byte; // padding between enqueue and dequeue positions
    {$ENDIF}
    FDequeuePos: Int64;
    {$IFDEF FAFAFA_LOCKFREE_CACHELINE_PAD}
    FPad2: array[0..63] of Byte; // padding between positions and stats
    {$ENDIF}
    FStats: TLockFreeStats;
  public
    constructor Create(ACapacity: Integer = 1024);
    destructor Destroy; override;
    function Enqueue(const AItem: T): Boolean;
    function Dequeue(out AItem: T): Boolean;
    function IsEmpty: Boolean;
    function IsFull: Boolean;
    function GetSize: Integer;
    function GetCapacity: Integer;

    // IQueue<T>
    procedure Push(const aElement: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    function  Pop(out aElement: T): Boolean; overload;
    function  Pop: T; overload;
    function  TryPeek(out aElement: T): Boolean; overload;
    function  Peek: T; overload;
    function  Count: SizeUInt;

    procedure EnqueueItem(const aElement: T);
    function DequeueItem: T;
    function TryDequeue(out aElement: T): Boolean;
    procedure PushItem(const aElement: T);
    function PopItem: T;
    function TryPop(out aElement: T): Boolean;
    function PeekItem: T;
    function EnqueueMany(const aElements: array of T): Integer;
    function DequeueMany(var aElements: array of T): Integer;
    procedure Clear;
    function GetStats: ILockFreeStats;
  end;

implementation

constructor TPreAllocMPMCQueue.Create(ACapacity: Integer);
var
  I: Integer;
begin
  inherited Create;
  if not IsPowerOfTwo(ACapacity) then
    ACapacity := NextPowerOfTwo(ACapacity);
  FCapacity := ACapacity;
  FMask := ACapacity - 1;
  SetLength(FBuffer, ACapacity);
  FEnqueuePos := 0;
  FDequeuePos := 0;
  for I := 0 to ACapacity - 1 do
    FBuffer[I].Sequence := I;
  FStats := TLockFreeStats.Create;
end;

destructor TPreAllocMPMCQueue.Destroy;
begin
  FStats.Free;
  SetLength(FBuffer, 0);
  inherited Destroy;
end;

function TPreAllocMPMCQueue.Enqueue(const AItem: T): Boolean;
var
  {$IFDEF FAFAFA_LOCKFREE_BACKOFF}
  LSpinCount: Integer = 0;
  {$ENDIF}
  LPos: Int64;
  LSlot: PSlot;
  LSequence: Int64;
begin
  repeat
    LPos := atomic_load_64(FEnqueuePos, mo_relaxed);
    LSlot := @FBuffer[LPos and FMask];
    LSequence := atomic_load_64(LSlot^.Sequence, mo_acquire);
    if LSequence = LPos then
    begin
      // attempt to reserve slot by incrementing enqueue pos
      if atomic_compare_exchange_strong_64(FEnqueuePos, LPos, LPos + 1) then
      begin
        LSlot^.Data := AItem;
        atomic_store_64(LSlot^.Sequence, LPos + 1, mo_release);
        FStats.IncEnqueue(True);
        Exit(True);
      end
      else
      begin
        // very light backoff on contention
        {$IFDEF FAFAFA_LOCKFREE_BACKOFF}
        BackoffStep(LSpinCount);
        {$ENDIF}
      end;
    end
    else if LSequence < LPos then
    begin
      FStats.IncEnqueue(False);
      Exit(False);
    end;
  until False;
end;

function TPreAllocMPMCQueue.Dequeue(out AItem: T): Boolean;
var
  {$IFDEF FAFAFA_LOCKFREE_BACKOFF}
  LSpinCount: Integer = 0;
  {$ENDIF}
  LPos: Int64;
  LSlot: PSlot;
  LSequence: Int64;
begin
  repeat
    LPos := atomic_load_64(FDequeuePos, mo_relaxed);
    LSlot := @FBuffer[LPos and FMask];
    LSequence := atomic_load_64(LSlot^.Sequence, mo_acquire);
    if LSequence = LPos + 1 then
    begin
      // attempt to claim slot by incrementing dequeue pos
      if atomic_compare_exchange_strong_64(FDequeuePos, LPos, LPos + 1) then
      begin
        AItem := LSlot^.Data;
        atomic_store_64(LSlot^.Sequence, LPos + FCapacity, mo_release);
        FStats.IncDequeue(True);
        Exit(True);
      end
      else
      begin
        {$IFDEF FAFAFA_LOCKFREE_BACKOFF}
        BackoffStep(LSpinCount);
        {$ENDIF}
      end;
    end
    else if LSequence < LPos + 1 then
    begin
      FStats.IncDequeue(False);
      Exit(False);
    end;
  until False;
end;

function TPreAllocMPMCQueue.IsEmpty: Boolean;
begin
  Result := atomic_load_64(FEnqueuePos, mo_relaxed) = atomic_load_64(FDequeuePos, mo_relaxed);
end;

function TPreAllocMPMCQueue.IsFull: Boolean;
begin
  Result := (atomic_load_64(FEnqueuePos, mo_relaxed) - atomic_load_64(FDequeuePos, mo_relaxed)) >= FCapacity;
end;

function TPreAllocMPMCQueue.GetSize: Integer;
begin
  Result := atomic_load_64(FEnqueuePos, mo_relaxed) - atomic_load_64(FDequeuePos, mo_relaxed);
end;

function TPreAllocMPMCQueue.GetCapacity: Integer;
begin
  Result := FCapacity;
end;

procedure TPreAllocMPMCQueue.EnqueueItem(const aElement: T);
begin
  if not Enqueue(aElement) then
    raise Exception.Create('Queue is full');
end;

function TPreAllocMPMCQueue.DequeueItem: T;
begin
  if not Dequeue(Result) then
    raise Exception.Create('Queue is empty');
end;

function TPreAllocMPMCQueue.TryDequeue(out aElement: T): Boolean;
begin
  Result := Dequeue(aElement);
end;

procedure TPreAllocMPMCQueue.PushItem(const aElement: T);
begin
  EnqueueItem(aElement);
end;

function TPreAllocMPMCQueue.PopItem: T;
begin
  Result := DequeueItem;
end;

function TPreAllocMPMCQueue.TryPop(out aElement: T): Boolean;
begin
  Result := TryDequeue(aElement);
end;

function TPreAllocMPMCQueue.PeekItem: T;
begin
  // 返回默认值以满足编译器，同时立即抛出异常
  Result := Default(T);
  raise Exception.Create('Peek operation not supported by lock-free queue');
end;


function TPreAllocMPMCQueue.EnqueueMany(const aElements: array of T): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(aElements) to High(aElements) do
  begin
    if Enqueue(aElements[I]) then
      Inc(Result)
    else
      Break;
  end;
end;

function TPreAllocMPMCQueue.DequeueMany(var aElements: array of T): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(aElements) to High(aElements) do
  begin
    if Dequeue(aElements[I]) then
      Inc(Result)
    else
      Break;
  end;
end;

procedure TPreAllocMPMCQueue.Clear;
var
  LDummy: T;
begin
  while Dequeue(LDummy) do ;
end;

{ IQueue<T> 显式实现 }

procedure TPreAllocMPMCQueue.Push(const aElement: T);
begin
  if not Enqueue(aElement) then
    raise Exception.Create('IQueue.Push: queue is full');
end;

procedure TPreAllocMPMCQueue.Push(const aSrc: array of T);
var i: SizeInt;
begin
  for i := Low(aSrc) to High(aSrc) do Push(aSrc[i]);
end;

procedure TPreAllocMPMCQueue.Push(const aSrc: Pointer; aElementCount: SizeUInt);
type PEl = ^T; var i: SizeUInt; p: PEl;
begin
  if (aSrc = nil) and (aElementCount > 0) then
    raise Exception.Create('IQueue.Push(pointer): aSrc is nil');
  p := PEl(aSrc);
  for i := 0 to aElementCount - 1 do begin Push(p^); Inc(p); end;
end;

function TPreAllocMPMCQueue.Pop(out aElement: T): Boolean;
begin
  Result := Dequeue(aElement);
end;

function TPreAllocMPMCQueue.Pop: T;
begin
  if not Dequeue(Result) then
    raise Exception.Create('IQueue.Pop: queue is empty');
end;

function TPreAllocMPMCQueue.TryPeek(out aElement: T): Boolean;
begin
  Result := TryPeek(aElement);
end;

function TPreAllocMPMCQueue.Peek: T;
begin
  Result := PeekItem; // 底层不支持时会抛异常
end;

function TPreAllocMPMCQueue.Count: SizeUInt;
begin
  Result := SizeUInt(GetSize);
end;


function TPreAllocMPMCQueue.GetStats: ILockFreeStats;
begin
  Result := FStats;
end;

end.


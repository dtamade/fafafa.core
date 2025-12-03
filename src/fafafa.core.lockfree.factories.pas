unit fafafa.core.lockfree.factories;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.channel,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.michaelScottQueue,
  fafafa.core.lockfree.mpmcQueue,
  fafafa.core.lockfree.stack,
  fafafa.core.lockfree.hashmap.openAddressing,
  fafafa.core.lockfree.hashmap,
  fafafa.core.lockfree.mapex.adapters,
  fafafa.core.lockfree.backoff,
  fafafa.core.lockfree.blocking;

{!
  Minimal factories returning interface types to decouple from concrete classes.
}

// Forward factory declarations (implementation section below)
generic function NewSpscQueue<T>(Capacity: SizeInt): specialize ILockFreeQueueSPSC<T>;
generic function NewMpscQueue<T>: specialize ILockFreeQueueMPSC<T>;
generic function NewMpmcQueue<T>(Capacity: SizeInt): specialize ILockFreeQueueMPMC<T>;

generic function NewChannelSPSC<T>(Capacity: SizeInt = 1024): specialize ILockFreeChannelSPSC<T>;
generic function NewChannelMPSC<T>: specialize ILockFreeChannelMPSC<T>;
generic function NewChannelMPMC<T>(Capacity: SizeInt = 1024): specialize ILockFreeChannelMPMC<T>;

generic function NewTreiberStack<T>: specialize ILockFreeStack<T>;

  { Queue Builder }
  type
    TBlockingPolicy = (bpNone, bpSpin, bpSleep);
    generic TQueueBuilder<T> = record
    public
      type
        TBackoffPolicy = (boNone, boYield, boSleep0);
        TPadding = (padNone, padCacheLine);
        TQueueIface = specialize ILockFreeQueue<T>;
  private
    FCapacity: SizeInt;
    FModel: (qbSPSC, qbMPSC, qbMPMC);
    FBackoff: TBackoffPolicy;
    FPad: TPadding;
    FBlocking: TBlockingPolicy;
    FBlockingPolicyInst: IBlockingPolicy;
    FStatsEnabled: Boolean;


  public
    class function New: TQueueBuilder; static;
    function Capacity(N: SizeInt): TQueueBuilder; inline;
    function ModelSPSC: TQueueBuilder; inline;
    function ModelMPSC: TQueueBuilder; inline;
    function ModelMPMC: TQueueBuilder; inline;
    // Planned options (no-op for now)
    function Backoff(Policy: TBackoffPolicy): TQueueBuilder; inline;
    function Padding(Pad: TPadding): TQueueBuilder; inline;
    function BlockingPolicy(Policy: TBlockingPolicy): TQueueBuilder; inline;
    function WithBlockingPolicy(const P: IBlockingPolicy): TQueueBuilder; inline;
    function EnableStats(Flag: Boolean): TQueueBuilder; inline;
    function Build: TQueueIface;
  end;

  { Map Builder (OA first) }
  generic TMapBuilder<K,V> = record
  private
    FCapacity: SizeInt;
    FImpl: (mbOA, mbMM);
    // OA comparer
    FHash: specialize TLockFreeHashMap<K,V>.THashFunc;
    FEqual: specialize TLockFreeHashMap<K,V>.TEqualFunc;
    FHasComparer: Boolean;
    // MM comparer
    FHashMM: specialize TMichaelHashMap<K,V>.THashFunction;
    FEqualMM: specialize TMichaelHashMap<K,V>.TKeyComparer;
    FHasComparerMM: Boolean;
  public
    class function New: TMapBuilder; static;
    function Capacity(N: SizeInt): TMapBuilder; inline;
    function ImplOA: TMapBuilder; inline;
    function ImplMM: TMapBuilder; inline;
    function WithComparer(AHash: specialize TLockFreeHashMap<K,V>.THashFunc;
      AEqual: specialize TLockFreeHashMap<K,V>.TEqualFunc): TMapBuilder; inline;
    function WithComparerMM(AHash: specialize TMichaelHashMap<K,V>.THashFunction;
      AEqual: specialize TMichaelHashMap<K,V>.TKeyComparer): TMapBuilder; inline;
    function BuildEx: specialize ILockFreeMapEx<K,V>;
  end;


generic function NewPreallocStack<T>(Capacity: SizeInt): specialize ILockFreeStack<T>;







  type
    generic TQueuePolicyWrapper<T> = class(TInterfacedObject, specialize ILockFreeQueue<T>)
    private
      FInner: specialize ILockFreeQueue<T>;
      FPolicy: TBlockingPolicy;
      FBlockingPolicy: IBlockingPolicy; // injectable
      procedure SpinStep; inline;
    public
      constructor Create(const Inner: specialize ILockFreeQueue<T>; Policy: TBlockingPolicy;
        const ABlocking: IBlockingPolicy = nil);
      // Try
      function Enqueue(constref Item: T): Boolean;
      function Dequeue(out Item: T): Boolean;
      function TryEnqueue(constref Item: T): Boolean;
      function TryDequeue(out Item: T): Boolean;
      // Blocking
      function EnqueueBlocking(constref Item: T; TimeoutMs: Integer = -1): Boolean;
      function DequeueBlocking(out Item: T; TimeoutMs: Integer = -1): Boolean;
      // Bulk
      function EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
      function DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
      // Lifecycle / introspection
      procedure Close;
      function IsClosed: Boolean;
      function IsEmpty: Boolean;
      function Size: SizeInt;
      function Capacity: SizeInt;
      function RemainingCapacity: SizeInt;
    end;

  // Adapter class declarations (moved to interface so generic factory templates can see them)
  type
    generic TSpscQueueAdapter<T> = class(TInterfacedObject, specialize ILockFreeQueueSPSC<T>)
    public type
      TSpscQ = specialize TSPSCQueue<T>;
    private
      FQ: TSpscQ;
      FClosed: Boolean;
    public
      constructor Create(Capacity: SizeInt);
      destructor Destroy; override;
      // Try semantics
      function Enqueue(constref Item: T): Boolean;
      function Dequeue(out Item: T): Boolean;
      function TryEnqueue(constref Item: T): Boolean;
      function TryDequeue(out Item: T): Boolean;
      // Blocking
      function EnqueueBlocking(constref Item: T; TimeoutMs: Integer = -1): Boolean;
      function DequeueBlocking(out Item: T; TimeoutMs: Integer = -1): Boolean;
      // Bulk
      function EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
      function DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
      // Lifecycle / introspection
      procedure Close;
      function IsClosed: Boolean;
      function IsEmpty: Boolean;
      function Size: SizeInt;
      function Capacity: SizeInt;
      function RemainingCapacity: SizeInt;
    end;

    generic TMpscQueueAdapter<T> = class(TInterfacedObject, specialize ILockFreeQueueMPSC<T>)
    public type
      TMSQ = specialize TMichaelScottQueue<T>;
    private
      FQ: TMSQ;
      FClosed: Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      // Try
      function Enqueue(constref Item: T): Boolean;
      function Dequeue(out Item: T): Boolean;
      function TryEnqueue(constref Item: T): Boolean;
      function TryDequeue(out Item: T): Boolean;
      // Blocking
      function EnqueueBlocking(constref Item: T; TimeoutMs: Integer = -1): Boolean;
      function DequeueBlocking(out Item: T; TimeoutMs: Integer = -1): Boolean;
      // Bulk
      function EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
      function DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
      // Lifecycle / introspection
      procedure Close;
      function IsClosed: Boolean;
      function IsEmpty: Boolean;
      function Size: SizeInt;
      function Capacity: SizeInt;
      function RemainingCapacity: SizeInt;
    end;

    generic TMpmcQueueAdapter<T> = class(TInterfacedObject, specialize ILockFreeQueueMPMC<T>)
    public type
      TMPMCQ = specialize TPreAllocMPMCQueue<T>;
    private
      FQ: TMPMCQ;
      FClosed: Boolean;
    public
      constructor Create(Capacity: SizeInt);
      destructor Destroy; override;
      // Try
      function Enqueue(constref Item: T): Boolean;
      function Dequeue(out Item: T): Boolean;
      function TryEnqueue(constref Item: T): Boolean;
      function TryDequeue(out Item: T): Boolean;
      // Blocking
      function EnqueueBlocking(constref Item: T; TimeoutMs: Integer = -1): Boolean;
      function DequeueBlocking(out Item: T; TimeoutMs: Integer = -1): Boolean;
      // Bulk
      function EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
      function DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
      // Lifecycle / introspection
      procedure Close;
      function IsClosed: Boolean;
      function IsEmpty: Boolean;
      function Size: SizeInt;
      function Capacity: SizeInt;
      function RemainingCapacity: SizeInt;
    end;

    generic TTreiberStackAdapter<T> = class(TInterfacedObject, specialize ILockFreeStack<T>)
    public type
      TTS = specialize TTreiberStack<T>;
    private
      FS: TTS;
    public
      constructor Create;
      destructor Destroy; override;
      function Push(constref Item: T): Boolean;
      function Pop(out Item: T): Boolean;
      function TryPeek(out Item: T): Boolean;
      procedure Clear;
      function IsEmpty: Boolean;
      function Size: SizeInt;
    end;

    generic TPreallocStackAdapter<T> = class(TInterfacedObject, specialize ILockFreeStack<T>)
    public type
      TPS = specialize TPreAllocStack<T>;
    private
      FS: TPS;
    public
      constructor Create(Capacity: SizeInt);
      destructor Destroy; override;
      function Push(constref Item: T): Boolean;
      function Pop(out Item: T): Boolean;
      function TryPeek(out Item: T): Boolean;
      procedure Clear;
      function IsEmpty: Boolean;
      function Size: SizeInt;
    end;

implementation

uses
  Math;





{ TSpscQueueAdapter }
constructor TSpscQueueAdapter.Create(Capacity: SizeInt);
begin
  inherited Create;
  FQ := TSpscQ.Create(Max(2, Capacity));
  FClosed := False;
end;

destructor TSpscQueueAdapter.Destroy;
begin
  FQ.Free;
  inherited Destroy;
end;

function TSpscQueueAdapter.Enqueue(constref Item: T): Boolean;
begin
  Result := TryEnqueue(Item);
end;

function TSpscQueueAdapter.Dequeue(out Item: T): Boolean;
begin
  Result := TryDequeue(Item);
end;

function TSpscQueueAdapter.IsEmpty: Boolean;
begin
  Result := FQ.IsEmpty;
end;

function TSpscQueueAdapter.Size: SizeInt;
begin
  Result := FQ.Size;
end;

function TSpscQueueAdapter.Capacity: SizeInt;
begin
  Result := FQ.Capacity;
end;

function TSpscQueueAdapter.RemainingCapacity: SizeInt;
begin
  Result := FQ.Capacity - FQ.Size;
end;

function TSpscQueueAdapter.TryEnqueue(constref Item: T): Boolean;
begin
  if FClosed then Exit(False);
  Result := FQ.Enqueue(Item);
end;

function TMpscQueueAdapter.TryEnqueue(constref Item: T): Boolean;
begin
  if FClosed then Exit(False);
  FQ.Enqueue(Item);
  Result := True;
end;

function TMpscQueueAdapter.TryDequeue(out Item: T): Boolean;
begin
  Result := FQ.Dequeue(Item);
end;

function TMpscQueueAdapter.EnqueueBlocking(constref Item: T; TimeoutMs: Integer): Boolean;
var
  Deadline: QWord;
begin
  if FClosed then Exit(False);
  if TimeoutMs < 0 then
  begin
    FQ.Enqueue(Item);
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  // Michael-Scott enqueue 总能推进；这里仅做轻量让出
  FQ.Enqueue(Item);
  Result := True;
end;

function TMpscQueueAdapter.DequeueBlocking(out Item: T; TimeoutMs: Integer): Boolean;
var
  Deadline: QWord;
begin
  if TimeoutMs < 0 then
  begin
    while not FQ.Dequeue(Item) do
    begin
      if FClosed then Exit(False);
      SysUtils.Sleep(0);
    end;
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  while GetTickCount64 < Deadline do
  begin
    if FQ.Dequeue(Item) then Exit(True);
    if FClosed then Exit(False);
    SysUtils.Sleep(0);
  end;
  Result := False;
end;

function TMpmcQueueAdapter.TryEnqueue(constref Item: T): Boolean;
begin
  if FClosed then Exit(False);
  Result := FQ.Enqueue(Item);
end;

function TMpmcQueueAdapter.TryDequeue(out Item: T): Boolean;
begin
  Result := FQ.Dequeue(Item);
end;

function TMpmcQueueAdapter.EnqueueBlocking(constref Item: T; TimeoutMs: Integer): Boolean;
var
  Deadline: QWord;
begin
  if FClosed then Exit(False);
  if TimeoutMs < 0 then
  begin
    while not FQ.Enqueue(Item) do SysUtils.Sleep(0);
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  while GetTickCount64 < Deadline do
  begin
    if FQ.Enqueue(Item) then Exit(True);
    SysUtils.Sleep(0);
  end;
  Result := False;
end;

function TMpmcQueueAdapter.DequeueBlocking(out Item: T; TimeoutMs: Integer): Boolean;
var
  Deadline: QWord;
begin
  if TimeoutMs < 0 then
  begin
    while not FQ.Dequeue(Item) do
    begin
      if FClosed and FQ.IsEmpty then Exit(False);
      SysUtils.Sleep(0);
    end;
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  while GetTickCount64 < Deadline do
  begin
    if FQ.Dequeue(Item) then Exit(True);
    if FClosed and FQ.IsEmpty then Exit(False);
    SysUtils.Sleep(0);
  end;
  Result := False;
end;

function TMpmcQueueAdapter.EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
var
  I: SizeInt;
begin
  Pushed := 0;
  for I := Low(Items) to High(Items) do
  begin
    if FClosed then Break;
    if FQ.Enqueue(Items[I]) then Inc(Pushed) else Break;
  end;
  Result := Pushed > 0;
end;

function TMpmcQueueAdapter.DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
var
  I: SizeInt;
begin
  Popped := 0;
  for I := Low(OutBuf) to High(OutBuf) do
  begin
    if FQ.Dequeue(OutBuf[I]) then Inc(Popped) else Break;
  end;
  Result := Popped > 0;
end;

procedure TMpmcQueueAdapter.Close;
begin
  FClosed := True;
end;

function TMpmcQueueAdapter.IsClosed: Boolean;
begin
  Result := FClosed;
end;

function TMpmcQueueAdapter.RemainingCapacity: SizeInt;
begin
  Result := FQ.GetCapacity - FQ.GetSize;
end;



function TMpscQueueAdapter.EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
var
  I: SizeInt;
begin
  if FClosed then begin Pushed := 0; Exit(False); end;
  for I := Low(Items) to High(Items) do
  begin
    FQ.Enqueue(Items[I]);
    Inc(Pushed);
  end;
  Result := Pushed > 0;
end;

function TMpscQueueAdapter.DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
var
  I: SizeInt;
begin
  Popped := 0;
  for I := Low(OutBuf) to High(OutBuf) do
  begin
    if FQ.Dequeue(OutBuf[I]) then Inc(Popped) else Break;
  end;
  Result := Popped > 0;
end;

procedure TMpscQueueAdapter.Close;
begin
  FClosed := True;
end;

function TMpscQueueAdapter.IsClosed: Boolean;
begin
  Result := FClosed;
end;


function TSpscQueueAdapter.TryDequeue(out Item: T): Boolean;
begin
  Result := FQ.Dequeue(Item);
end;

function TSpscQueueAdapter.EnqueueBlocking(constref Item: T; TimeoutMs: Integer): Boolean;
var
  Deadline: Int64;
begin
  if FClosed then Exit(False);
  if TimeoutMs < 0 then
  begin
    while not FQ.Enqueue(Item) do SysUtils.Sleep(0);
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  while GetTickCount64 < QWord(Deadline) do
  begin
    if FQ.Enqueue(Item) then Exit(True);
    SysUtils.Sleep(0);
  end;
  Result := False;
end;

function TSpscQueueAdapter.DequeueBlocking(out Item: T; TimeoutMs: Integer): Boolean;
var
  Deadline: Int64;
begin
  if TimeoutMs < 0 then
  begin
    while not FQ.Dequeue(Item) do
    begin
      if FClosed and FQ.IsEmpty then Exit(False);
      SysUtils.Sleep(0);
    end;
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  while GetTickCount64 < QWord(Deadline) do
  begin
    if FQ.Dequeue(Item) then Exit(True);
    if FClosed and FQ.IsEmpty then Exit(False);
    SysUtils.Sleep(0);
  end;
  Result := False;
end;

function TSpscQueueAdapter.EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
var
  I: SizeInt;
begin
  Pushed := 0;
  for I := Low(Items) to High(Items) do
  begin
    if FClosed then Break;
    if FQ.Enqueue(Items[I]) then Inc(Pushed) else Break;
  end;
  Result := Pushed > 0;
end;

function TSpscQueueAdapter.DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
var
  I: SizeInt;
begin
  Popped := 0;
  for I := Low(OutBuf) to High(OutBuf) do
  begin
    if FQ.Dequeue(OutBuf[I]) then Inc(Popped) else Break;
  end;
  Result := Popped > 0;
end;

procedure TSpscQueueAdapter.Close;
begin
  FClosed := True;
end;

function TSpscQueueAdapter.IsClosed: Boolean;
begin
  Result := FClosed;
end;



{ TMpscQueueAdapter }
constructor TMpscQueueAdapter.Create;
begin
  inherited Create;
  FQ := TMSQ.Create;
end;

destructor TMpscQueueAdapter.Destroy;
begin
  FQ.Free;
  inherited Destroy;
end;

function TMpscQueueAdapter.Enqueue(constref Item: T): Boolean;
begin
  Result := TryEnqueue(Item);
end;

function TMpscQueueAdapter.Dequeue(out Item: T): Boolean;
begin
  Result := TryDequeue(Item);
end;

function TMpscQueueAdapter.IsEmpty: Boolean;
begin
  Result := FQ.IsEmpty;
end;

function TMpscQueueAdapter.Size: SizeInt;
begin
  // MSQueue 常见无法常数时间返回 size，这里返回 -1 表示不支持
  Result := -1;
end;

function TMpscQueueAdapter.Capacity: SizeInt;
begin
  Result := -1; // Unbounded
end;

function TMpscQueueAdapter.RemainingCapacity: SizeInt;
begin
  Result := -1;
end;


{ TMpmcQueueAdapter }
constructor TMpmcQueueAdapter.Create(Capacity: SizeInt);
begin
  inherited Create;
  FQ := TMPMCQ.Create(Max(2, Capacity));
  FClosed := False;
end;

destructor TMpmcQueueAdapter.Destroy;
begin
  FQ.Free;
  inherited Destroy;
end;

function TMpmcQueueAdapter.Enqueue(constref Item: T): Boolean;
begin
  Result := TryEnqueue(Item);
end;

function TMpmcQueueAdapter.Dequeue(out Item: T): Boolean;
begin
  Result := TryDequeue(Item);
end;

function TMpmcQueueAdapter.IsEmpty: Boolean;
begin


  Result := FQ.IsEmpty;
end;


{ TQueuePolicyWrapper<T> }
constructor TQueuePolicyWrapper.Create(const Inner: specialize ILockFreeQueue<T>; Policy: TBlockingPolicy;
  const ABlocking: IBlockingPolicy);
begin
  inherited Create;
  FInner := Inner;
  FPolicy := Policy;
  if ABlocking <> nil then
    FBlockingPolicy := ABlocking
  else
    FBlockingPolicy := GetDefaultBlockingPolicy;
end;

procedure TQueuePolicyWrapper.SpinStep;
var Dummy: Integer;
begin
  case FPolicy of
    bpSpin:
      ; // pure spin
    bpSleep:
      begin
        Dummy := 0;
        if FBlockingPolicy <> nil then
          FBlockingPolicy.Step(Dummy)
        else
          BackoffStep(Dummy);
      end;
  else
    ;
  end;
end;

function TQueuePolicyWrapper.Enqueue(constref Item: T): Boolean;
begin
  Result := FInner.Enqueue(Item);
end;

function TQueuePolicyWrapper.Dequeue(out Item: T): Boolean;
begin
  Result := FInner.Dequeue(Item);
end;

function TQueuePolicyWrapper.TryEnqueue(constref Item: T): Boolean;
begin
  Result := FInner.TryEnqueue(Item);
end;

function TQueuePolicyWrapper.TryDequeue(out Item: T): Boolean;
begin
  Result := FInner.TryDequeue(Item);
end;

function TQueuePolicyWrapper.EnqueueBlocking(constref Item: T; TimeoutMs: Integer): Boolean;
var Deadline: QWord;
begin
  if FPolicy = bpNone then
    Exit(FInner.EnqueueBlocking(Item, TimeoutMs));
  if TimeoutMs < 0 then
  begin
    while not FInner.TryEnqueue(Item) do SpinStep;
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  while GetTickCount64 < Deadline do
  begin
    if FInner.TryEnqueue(Item) then Exit(True);
    SpinStep;
  end;
  Result := False;
end;

function TQueuePolicyWrapper.DequeueBlocking(out Item: T; TimeoutMs: Integer): Boolean;
var Deadline: QWord;
begin
  if FPolicy = bpNone then
    Exit(FInner.DequeueBlocking(Item, TimeoutMs));
  if TimeoutMs < 0 then
  begin
    while not FInner.TryDequeue(Item) do SpinStep;
    Exit(True);
  end;
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  while GetTickCount64 < Deadline do
  begin
    if FInner.TryDequeue(Item) then Exit(True);
    SpinStep;
  end;
  Result := False;
end;

function TQueuePolicyWrapper.EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
begin
  Result := FInner.EnqueueMany(Items, Pushed);
end;

function TQueuePolicyWrapper.DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;
begin
  Result := FInner.DequeueMany(OutBuf, Popped);
end;

procedure TQueuePolicyWrapper.Close;
begin
  FInner.Close;
end;

function TQueuePolicyWrapper.IsClosed: Boolean;
begin
  Result := FInner.IsClosed;
end;

function TQueuePolicyWrapper.IsEmpty: Boolean;
begin
  Result := FInner.IsEmpty;
end;

function TQueuePolicyWrapper.Size: SizeInt;
begin
  Result := FInner.Size;
end;

function TQueuePolicyWrapper.Capacity: SizeInt;
begin
  Result := FInner.Capacity;
end;

function TQueuePolicyWrapper.RemainingCapacity: SizeInt;
begin
  Result := FInner.RemainingCapacity;
end;

function TMpmcQueueAdapter.Size: SizeInt;
begin
  Result := FQ.GetSize;
end;

function TMpmcQueueAdapter.Capacity: SizeInt;
begin
  Result := FQ.GetCapacity;
end;

{ TTreiberStackAdapter }
constructor TTreiberStackAdapter.Create;
begin
  inherited Create;
  FS := TTS.Create;
end;

destructor TTreiberStackAdapter.Destroy;
begin
  FS.Free;
  inherited Destroy;
end;

function TTreiberStackAdapter.Push(constref Item: T): Boolean;
begin
  FS.Push(Item);
  Result := True;
end;

function TTreiberStackAdapter.Pop(out Item: T): Boolean;
begin
  Result := FS.Pop(Item);
end;

function TTreiberStackAdapter.TryPeek(out Item: T): Boolean;
begin
  Result := FS.TryPeek(Item);
end;

procedure TTreiberStackAdapter.Clear;
begin
  FS.Clear;
end;


function TTreiberStackAdapter.IsEmpty: Boolean;
begin
  Result := FS.IsEmpty;
end;

function TTreiberStackAdapter.Size: SizeInt;
begin
  Result := FS.GetSize;
end;

{ TQueueBuilder<T> }
class function TQueueBuilder.New: TQueueBuilder;
begin
  Result.FCapacity := 0;
  Result.FModel := qbSPSC;
  Result.FBackoff := boNone;
  Result.FPad := padNone;
  Result.FBlocking := bpNone;
  Result.FStatsEnabled := False;
  Result.FBlockingPolicyInst := nil;
end;

function TQueueBuilder.Capacity(N: SizeInt): TQueueBuilder;
begin
  Result := Self; Result.FCapacity := N;
end;

function TQueueBuilder.ModelSPSC: TQueueBuilder;
begin
  Result := Self; Result.FModel := qbSPSC;
end;

function TQueueBuilder.ModelMPSC: TQueueBuilder;
begin
  Result := Self; Result.FModel := qbMPSC;
end;

function TQueueBuilder.ModelMPMC: TQueueBuilder;
begin
  Result := Self; Result.FModel := qbMPMC;
end;

function TQueueBuilder.Backoff(Policy: TBackoffPolicy): TQueueBuilder;
begin
  Result := Self; Result.FBackoff := Policy;
end;

function TQueueBuilder.Padding(Pad: TPadding): TQueueBuilder;
begin
  Result := Self; Result.FPad := Pad;
end;

function TQueueBuilder.BlockingPolicy(Policy: TBlockingPolicy): TQueueBuilder;
begin
  Result := Self; Result.FBlocking := Policy;
end;

function TQueueBuilder.WithBlockingPolicy(const P: IBlockingPolicy): TQueueBuilder;
begin
  Result := Self; Result.FBlockingPolicyInst := P;
end;

function TQueueBuilder.EnableStats(Flag: Boolean): TQueueBuilder;
begin
  Result := Self; Result.FStatsEnabled := Flag;
end;

function TQueueBuilder.Build: TQueueIface;
var Base: TQueueIface;
begin
  case FModel of
    qbSPSC: Base := specialize NewSpscQueue<T>(Max(2, FCapacity));
    qbMPSC: Base := specialize NewMpscQueue<T>;
    qbMPMC: Base := specialize NewMpmcQueue<T>(Max(2, FCapacity));
  end;
  if FBlocking <> bpNone then
  begin
    if FBlockingPolicyInst = nil then
      Exit(specialize TQueuePolicyWrapper<T>.Create(Base, FBlocking, GetDefaultBlockingPolicy))
    else
      Exit(specialize TQueuePolicyWrapper<T>.Create(Base, FBlocking, FBlockingPolicyInst));
  end
  else
    Exit(Base);
end;

{ TMapBuilder<K,V> }
class function TMapBuilder.New: TMapBuilder;
begin
  Result.FCapacity := 0;
  Result.FImpl := mbOA;
  Result.FHasComparer := False;
  Result.FHash := nil;
  Result.FEqual := nil;
  Result.FHasComparerMM := False;
  Result.FHashMM := nil;
  Result.FEqualMM := nil;
end;

function TMapBuilder.Capacity(N: SizeInt): TMapBuilder;
begin
  Result := Self; Result.FCapacity := N;
end;

function TMapBuilder.ImplOA: TMapBuilder;
begin
  Result := Self; Result.FImpl := mbOA;
end;

function TMapBuilder.ImplMM: TMapBuilder;
begin
  Result := Self; Result.FImpl := mbMM;
end;

function TMapBuilder.WithComparer(AHash: specialize TLockFreeHashMap<K,V>.THashFunc;
  AEqual: specialize TLockFreeHashMap<K,V>.TEqualFunc): TMapBuilder;
begin
  Result := Self;
  Result.FHash := AHash;
  Result.FEqual := AEqual;
  Result.FHasComparer := Assigned(AHash) and Assigned(AEqual);
end;

function TMapBuilder.WithComparerMM(AHash: specialize TMichaelHashMap<K,V>.THashFunction;
  AEqual: specialize TMichaelHashMap<K,V>.TKeyComparer): TMapBuilder;
begin
  Result := Self;
  Result.FHashMM := AHash;
  Result.FEqualMM := AEqual;
  Result.FHasComparerMM := Assigned(AHash) and Assigned(AEqual);
end;

function TMapBuilder.BuildEx: specialize ILockFreeMapEx<K,V>;
  function AdaptHash(const Key: K): QWord; inline;
  begin
    if Assigned(FHash) then
      AdaptHash := QWord(FHash(Key))
    else
      AdaptHash := 0;
  end;
  function AdaptEqual(const L, R: K): Boolean; inline;
  begin
    if Assigned(FEqual) then
      AdaptEqual := FEqual(L, R)
    else
      AdaptEqual := False;
  end;
begin
  case FImpl of
    mbOA:
      if FHasComparer then
        Exit(specialize TMapExOAAdapter<K,V>.Create(Max(4, FCapacity), FHash, FEqual))
      else
        Exit(specialize TMapExOAAdapter<K,V>.Create(Max(4, FCapacity)));
    mbMM:
      begin
        if not FHasComparerMM then
          raise Exception.Create('MapBuilder.ImplMM requires comparer: provide hash & equal');
        Exit(specialize TMapExMMAdapter<K,V>.Create(Max(4, FCapacity), FHashMM, FEqualMM));
      end;
  end;
end;

{ TPreallocStackAdapter }
constructor TPreallocStackAdapter.Create(Capacity: SizeInt);
begin
  inherited Create;
  FS := TPS.Create(Max(2, Capacity));
end;

destructor TPreallocStackAdapter.Destroy;
begin
  FS.Free;
  inherited Destroy;
end;

function TPreallocStackAdapter.Push(constref Item: T): Boolean;
begin
  Result := FS.Push(Item);
end;

function TPreallocStackAdapter.Pop(out Item: T): Boolean;
begin
  Result := FS.Pop(Item);
end;

function TPreallocStackAdapter.TryPeek(out Item: T): Boolean;
begin
  // TPreAllocStack 不支持 TryPeek；best-effort 返回 False
  Result := False;
end;

procedure TPreallocStackAdapter.Clear;
var tmp: T;
begin
  while FS.Pop(tmp) do ;
end;


function TPreallocStackAdapter.IsEmpty: Boolean;
begin
  Result := FS.IsEmpty;
end;

function TPreallocStackAdapter.Size: SizeInt;
begin
  Result := FS.GetSize;
end;

{ Factories }

generic function NewSpscQueue<T>(Capacity: SizeInt): specialize ILockFreeQueueSPSC<T>;
begin
  Result := specialize TSpscQueueAdapter<T>.Create(Capacity);
end;

generic function NewMpscQueue<T>: specialize ILockFreeQueueMPSC<T>;
begin
  Result := specialize TMpscQueueAdapter<T>.Create;
end;

generic function NewMpmcQueue<T>(Capacity: SizeInt): specialize ILockFreeQueueMPMC<T>;
begin
  Result := specialize TMpmcQueueAdapter<T>.Create(Capacity);
end;

generic function NewChannelSPSC<T>(Capacity: SizeInt): specialize ILockFreeChannelSPSC<T>;
begin
  Result := specialize TLockFreeChannelSPSC<T>.Create(Capacity);
end;

generic function NewChannelMPSC<T>: specialize ILockFreeChannelMPSC<T>;
begin
  Result := specialize TLockFreeChannelMPSC<T>.Create;
end;

generic function NewChannelMPMC<T>(Capacity: SizeInt): specialize ILockFreeChannelMPMC<T>;
begin
  Result := specialize TLockFreeChannelMPMC<T>.Create(Capacity);
end;

generic function NewTreiberStack<T>: specialize ILockFreeStack<T>;
begin
  Result := specialize TTreiberStackAdapter<T>.Create;
end;

generic function NewPreallocStack<T>(Capacity: SizeInt): specialize ILockFreeStack<T>;
begin
  Result := specialize TPreallocStackAdapter<T>.Create(Capacity);
end;






end.

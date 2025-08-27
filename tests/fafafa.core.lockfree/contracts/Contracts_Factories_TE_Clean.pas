unit Contracts_Factories_TE_Clean;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{ TE（类型擦除）版契约工厂（干净实现）：桥接现有具体类型到扩展接口集 }

interface

uses
  SysUtils, Classes,
  fafafa.core.lockfree,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.michaelScottQueue,
  fafafa.core.lockfree.mpmcQueue,
  fafafa.core.lockfree.stack,
  fafafa.core.lockfree.hashmap,
  fafafa.core.lockfree.hashmap.openAddressing;

{$I Contracts_Factories_TE.inc}

function GetDefaultQueueFactory_Integer_TE: IQueueFactory_Integer;
function GetDefaultStackFactory_Integer_TE: IStackFactory_Integer;
function GetDefaultMapFactory_IntStr_TE: IMapFactory_IntStr;

implementation

type
  TQueueInt_SPSC = class(TInterfacedObject, IQueueInt)
  private
    FQ: TIntegerSPSCQueue;
  public
    constructor Create(ACapacity: SizeInt);
    destructor Destroy; override;
    function Enqueue(AValue: Integer): Boolean;
    function TryDequeue(out AValue: Integer): Boolean;
    function TryPeek(out AValue: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    function Bounded: Boolean;
    function EnqueueMany(const Values: array of Integer): Integer;
    function DequeueMany(var Values: array of Integer): Integer;
    procedure Clear;
    function HasStats: Boolean;
  end;

  TQueueInt_MPSC = class(TInterfacedObject, IQueueInt)
  private
    FQ: specialize TMichaelScottQueue<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    function Enqueue(AValue: Integer): Boolean;
    function TryDequeue(out AValue: Integer): Boolean;
    function TryPeek(out AValue: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    function Bounded: Boolean;
    function EnqueueMany(const Values: array of Integer): Integer;
    function DequeueMany(var Values: array of Integer): Integer;
    procedure Clear;
    function HasStats: Boolean;
  end;

  TQueueInt_MPMC = class(TInterfacedObject, IQueueInt)
  private
    FQ: specialize TPreAllocMPMCQueue<Integer>;
  public
    constructor Create(ACapacity: SizeInt);
    destructor Destroy; override;
    function Enqueue(AValue: Integer): Boolean;
    function TryDequeue(out AValue: Integer): Boolean;
    function TryPeek(out AValue: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    function Bounded: Boolean;
    function EnqueueMany(const Values: array of Integer): Integer;
    function DequeueMany(var Values: array of Integer): Integer;
    procedure Clear;
    function HasStats: Boolean;
  end;

    TStackInt_Treiber = class(TInterfacedObject, IStackInt)
  private
    FS: specialize TTreiberStack<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    function Push(AValue: Integer): Boolean;
    function TryPop(out AValue: Integer): Boolean;
    function TryPeek(out AValue: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    function Bounded: Boolean;
    function PushMany(const Values: array of Integer): Integer;
    function PopMany(var Values: array of Integer): Integer;
    procedure Clear;
    function HasStats: Boolean;
  end;

  TStackInt_PreAlloc = class(TInterfacedObject, IStackInt)
  private
    FS: specialize TPreAllocStack<Integer>;
  public
    constructor Create(ACapacity: SizeInt);
    destructor Destroy; override;
    function Push(AValue: Integer): Boolean;
    function TryPop(out AValue: Integer): Boolean;
    function TryPeek(out AValue: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    function Bounded: Boolean;
    function PushMany(const Values: array of Integer): Integer;
    function PopMany(var Values: array of Integer): Integer;
    procedure Clear;
    function HasStats: Boolean;
  end;

  TMap_IntStr_OA = class(TInterfacedObject, IMapIntStr)
  private
    FM: specialize TLockFreeHashMap<Integer, string>;
  public
    constructor Create(ACapacity: SizeInt);
    destructor Destroy; override;
    function Put(AKey: Integer; const AValue: string; out Replaced: Boolean): Boolean;
    function TryGetValue(AKey: Integer; out AValue: string): Boolean;
    function Remove(AKey: Integer; out OldValue: string): Boolean;
    function ContainsKey(AKey: Integer): Boolean;
    procedure Clear;
    function Size: SizeInt;
    function LoadFactorTimes1000: Integer;
    function BucketCount: Integer;
    function MaxLoadFactorTimes1000: Integer;
    function SetMaxLoadFactorTimes1000(Value: Integer): Boolean;
  end;

  TMap_IntStr_MM = class(TInterfacedObject, IMapIntStr)
  private
    FM: specialize TMichaelHashMap<Integer, string>;
  public
    constructor Create(ABucketCount: SizeInt);
    destructor Destroy; override;
    function Put(AKey: Integer; const AValue: string; out Replaced: Boolean): Boolean;
    function TryGetValue(AKey: Integer; out AValue: string): Boolean;
    function Remove(AKey: Integer; out OldValue: string): Boolean;
    function ContainsKey(AKey: Integer): Boolean;
    procedure Clear;
    function Size: SizeInt;
    function LoadFactorTimes1000: Integer;
    function BucketCount: Integer;
    function MaxLoadFactorTimes1000: Integer;
    function SetMaxLoadFactorTimes1000(Value: Integer): Boolean;
  end;

{ TQueueInt_SPSC }
constructor TQueueInt_SPSC.Create(ACapacity: SizeInt);
begin
  inherited Create;
  FQ := TIntegerSPSCQueue.Create(ACapacity);
end;

destructor TQueueInt_SPSC.Destroy;
begin
  FQ.Free;
  inherited Destroy;
end;

function TQueueInt_SPSC.Enqueue(AValue: Integer): Boolean; begin Result := FQ.Enqueue(AValue); end;
function TQueueInt_SPSC.TryDequeue(out AValue: Integer): Boolean; begin Result := FQ.Dequeue(AValue); end;
function TQueueInt_SPSC.TryPeek(out AValue: Integer): Boolean; begin AValue := 0; Result := False; end;
function TQueueInt_SPSC.IsEmpty: Boolean; begin Result := FQ.IsEmpty; end;
function TQueueInt_SPSC.Size: SizeInt; begin Result := FQ.Size; end;
function TQueueInt_SPSC.Capacity: SizeInt; begin Result := FQ.Capacity; end;
function TQueueInt_SPSC.Bounded: Boolean; begin Result := True; end;
function TQueueInt_SPSC.EnqueueMany(const Values: array of Integer): Integer; var i: Integer; begin Result := 0; for i := Low(Values) to High(Values) do if FQ.Enqueue(Values[i]) then Inc(Result) else Break; end;
function TQueueInt_SPSC.DequeueMany(var Values: array of Integer): Integer; var i: Integer; begin Result := 0; for i := Low(Values) to High(Values) do if FQ.Dequeue(Values[i]) then Inc(Result) else Break; end;
procedure TQueueInt_SPSC.Clear; var x: Integer; begin while FQ.Dequeue(x) do ; end;
function TQueueInt_SPSC.HasStats: Boolean; begin Result := False; end;

{ TQueueInt_MPSC }
constructor TQueueInt_MPSC.Create;
begin
  inherited Create;
  FQ := specialize TMichaelScottQueue<Integer>.Create;
end;

destructor TQueueInt_MPSC.Destroy;
begin
  FQ.Free;
  inherited Destroy;
end;
function TQueueInt_MPSC.Enqueue(AValue: Integer): Boolean; begin FQ.Enqueue(AValue); Result := True; end;
function TQueueInt_MPSC.TryDequeue(out AValue: Integer): Boolean; begin Result := FQ.Dequeue(AValue); end;
function TQueueInt_MPSC.TryPeek(out AValue: Integer): Boolean; begin AValue := 0; Result := False; end;
function TQueueInt_MPSC.IsEmpty: Boolean; begin Result := FQ.IsEmpty; end;
function TQueueInt_MPSC.Size: SizeInt; begin Result := 0; end;
function TQueueInt_MPSC.Capacity: SizeInt; begin Result := -1; end;
function TQueueInt_MPSC.Bounded: Boolean; begin Result := False; end;
function TQueueInt_MPSC.EnqueueMany(const Values: array of Integer): Integer; var i: Integer; begin Result := 0; for i := Low(Values) to High(Values) do begin FQ.Enqueue(Values[i]); Inc(Result); end; end;
function TQueueInt_MPSC.DequeueMany(var Values: array of Integer): Integer; var i: Integer; begin Result := 0; for i := Low(Values) to High(Values) do if FQ.Dequeue(Values[i]) then Inc(Result) else Break; end;
procedure TQueueInt_MPSC.Clear; var x: Integer; begin while FQ.Dequeue(x) do ; end;
function TQueueInt_MPSC.HasStats: Boolean; begin Result := False; end;

{ TQueueInt_MPMC }
constructor TQueueInt_MPMC.Create(ACapacity: SizeInt);
begin
  inherited Create;
  FQ := specialize TPreAllocMPMCQueue<Integer>.Create(ACapacity);
end;

destructor TQueueInt_MPMC.Destroy;
begin
  FQ.Free;
  inherited Destroy;
end;
function TQueueInt_MPMC.Enqueue(AValue: Integer): Boolean; begin Result := FQ.Enqueue(AValue); end;
function TQueueInt_MPMC.TryDequeue(out AValue: Integer): Boolean; begin Result := FQ.Dequeue(AValue); end;
function TQueueInt_MPMC.TryPeek(out AValue: Integer): Boolean; begin Result := FQ.TryPeek(AValue); end;
function TQueueInt_MPMC.IsEmpty: Boolean; begin Result := FQ.IsEmpty; end;
function TQueueInt_MPMC.Size: SizeInt; begin Result := FQ.GetSize; end;
function TQueueInt_MPMC.Capacity: SizeInt; begin Result := FQ.GetCapacity; end;
function TQueueInt_MPMC.Bounded: Boolean; begin Result := True; end;
function TQueueInt_MPMC.EnqueueMany(const Values: array of Integer): Integer; begin Result := FQ.EnqueueMany(Values); end;
function TQueueInt_MPMC.DequeueMany(var Values: array of Integer): Integer; begin Result := FQ.DequeueMany(Values); end;
procedure TQueueInt_MPMC.Clear; var x: Integer; begin while FQ.Dequeue(x) do ; end;
function TQueueInt_MPMC.HasStats: Boolean; begin Result := True; end;

{ TStackInt_Treiber }
constructor TStackInt_Treiber.Create;
begin
  inherited Create;
  FS := specialize TTreiberStack<Integer>.Create;
end;

destructor TStackInt_Treiber.Destroy;
begin
  FS.Free;
  inherited Destroy;
end;
function TStackInt_Treiber.Push(AValue: Integer): Boolean; begin FS.Push(AValue); Result := True; end;
function TStackInt_Treiber.TryPop(out AValue: Integer): Boolean; begin Result := FS.Pop(AValue); end;
function TStackInt_Treiber.TryPeek(out AValue: Integer): Boolean; begin Result := FS.TryPeek(AValue); end;
function TStackInt_Treiber.IsEmpty: Boolean; begin Result := FS.IsEmpty; end;
function TStackInt_Treiber.Size: SizeInt; begin Result := FS.GetSize; end;
function TStackInt_Treiber.Capacity: SizeInt; begin Result := -1; end;
function TStackInt_Treiber.Bounded: Boolean; begin Result := False; end;
function TStackInt_Treiber.PushMany(const Values: array of Integer): Integer; var i: Integer; begin Result := 0; for i := Low(Values) to High(Values) do begin FS.Push(Values[i]); Inc(Result); end; end;
function TStackInt_Treiber.PopMany(var Values: array of Integer): Integer; var i: Integer; begin Result := 0; for i := Low(Values) to High(Values) do if FS.Pop(Values[i]) then Inc(Result) else Break; end;
procedure TStackInt_Treiber.Clear; var x: Integer; begin while FS.Pop(x) do ; end;
function TStackInt_Treiber.HasStats: Boolean; begin Result := True; end;

{ TStackInt_PreAlloc }
constructor TStackInt_PreAlloc.Create(ACapacity: SizeInt);
begin
  inherited Create;
  FS := specialize TPreAllocStack<Integer>.Create(ACapacity);
end;

destructor TStackInt_PreAlloc.Destroy;
begin
  FS.Free;
  inherited Destroy;
end;
function TStackInt_PreAlloc.Push(AValue: Integer): Boolean; begin Result := FS.Push(AValue); end;
function TStackInt_PreAlloc.TryPop(out AValue: Integer): Boolean; begin Result := FS.Pop(AValue); end;
function TStackInt_PreAlloc.TryPeek(out AValue: Integer): Boolean; begin AValue := 0; Result := False; end;
function TStackInt_PreAlloc.IsEmpty: Boolean; begin Result := FS.IsEmpty; end;
function TStackInt_PreAlloc.Size: SizeInt; begin Result := FS.GetSize; end;
function TStackInt_PreAlloc.Capacity: SizeInt; begin Result := FS.GetCapacity; end;
function TStackInt_PreAlloc.Bounded: Boolean; begin Result := True; end;
function TStackInt_PreAlloc.PushMany(const Values: array of Integer): Integer; var i: Integer; var ok: Boolean; begin Result := 0; for i := Low(Values) to High(Values) do begin ok := FS.Push(Values[i]); if ok then Inc(Result) else Break; end; end;
function TStackInt_PreAlloc.PopMany(var Values: array of Integer): Integer; var i: Integer; begin Result := 0; for i := Low(Values) to High(Values) do if FS.Pop(Values[i]) then Inc(Result) else Break; end;
procedure TStackInt_PreAlloc.Clear; var x: Integer; begin while FS.Pop(x) do ; end;
function TStackInt_PreAlloc.HasStats: Boolean; begin Result := True; end;

{ TMap_IntStr_OA }
constructor TMap_IntStr_OA.Create(ACapacity: SizeInt);
begin
  inherited Create;
  FM := specialize TLockFreeHashMap<Integer, string>.Create(ACapacity);
end;

destructor TMap_IntStr_OA.Destroy;
begin
  FM.Free;
  inherited Destroy;
end;
function TMap_IntStr_OA.Put(AKey: Integer; const AValue: string; out Replaced: Boolean): Boolean; begin Replaced := FM.ContainsKey(AKey); Result := FM.Put(AKey, AValue); end;
function TMap_IntStr_OA.TryGetValue(AKey: Integer; out AValue: string): Boolean; begin Result := FM.Get(AKey, AValue); end;
function TMap_IntStr_OA.Remove(AKey: Integer; out OldValue: string): Boolean; begin if FM.Get(AKey, OldValue) then Exit(FM.Remove(AKey)) else Exit(False); end;
function TMap_IntStr_OA.ContainsKey(AKey: Integer): Boolean; begin Result := FM.ContainsKey(AKey); end;
procedure TMap_IntStr_OA.Clear; begin FM.Clear; end;
function TMap_IntStr_OA.Size: SizeInt; begin Result := FM.GetSize; end;
function TMap_IntStr_OA.LoadFactorTimes1000: Integer; begin Result := -1; end;
function TMap_IntStr_OA.BucketCount: Integer; begin Result := -1; end;
function TMap_IntStr_OA.MaxLoadFactorTimes1000: Integer; begin Result := -1; end;
function TMap_IntStr_OA.SetMaxLoadFactorTimes1000(Value: Integer): Boolean; begin Result := False; end;

{ TMap_IntStr_MM }
constructor TMap_IntStr_MM.Create(ABucketCount: SizeInt);
begin
  inherited Create;
  FM := CreateIntStrMMHashMap(ABucketCount);
end;

destructor TMap_IntStr_MM.Destroy;
begin
  FM.Free;
  inherited Destroy;
end;
function TMap_IntStr_MM.Put(AKey: Integer; const AValue: string; out Replaced: Boolean): Boolean;
var tmp: string;
begin
  if FM.find(AKey, tmp) then
  begin
    Replaced := True;
    Result := FM.update(AKey, AValue);
  end
  else
  begin
    Replaced := False;
    Result := FM.insert(AKey, AValue);
  end;
end;




function TMap_IntStr_MM.TryGetValue(AKey: Integer; out AValue: string): Boolean; begin Result := FM.find(AKey, AValue); end;
function TMap_IntStr_MM.Remove(AKey: Integer; out OldValue: string): Boolean; begin if FM.find(AKey, OldValue) then Exit(FM.erase(AKey)) else Exit(False); end;
function TMap_IntStr_MM.ContainsKey(AKey: Integer): Boolean; var dummy: string; begin Result := FM.find(AKey, dummy); end;
procedure TMap_IntStr_MM.Clear; begin FM.clear; end;
function TMap_IntStr_MM.Size: SizeInt; begin Result := FM.size; end;
function TMap_IntStr_MM.LoadFactorTimes1000: Integer; begin Result := Round(FM.load_factor * 1000); end;
function TMap_IntStr_MM.BucketCount: Integer; begin Result := FM.bucket_count; end;
function TMap_IntStr_MM.MaxLoadFactorTimes1000: Integer; begin Result := Round(FM.max_load_factor * 1000); end;
function TMap_IntStr_MM.SetMaxLoadFactorTimes1000(Value: Integer): Boolean; begin FM.max_load_factor(Value / 1000.0); Result := True; end;

type
  TQueueFactory_Integer_TE = class(TInterfacedObject, IQueueFactory_Integer)
  public
    function MakeSPSC(const ACapacity: SizeInt): IQueueInt;
    function MakeMPSC: IQueueInt;
    function MakeMPMC(const ACapacity: SizeInt): IQueueInt;
  end;

  TStackFactory_Integer_TE = class(TInterfacedObject, IStackFactory_Integer)
  public
    function MakeTreiber: IStackInt;
    function MakePreAlloc(const ACapacity: SizeInt): IStackInt;
  end;

  TMapFactory_IntStr_TE = class(TInterfacedObject, IMapFactory_IntStr)
  public
    function MakeOA(const ACapacity: SizeInt): IMapIntStr;
    function MakeMM(const ABucketCount: SizeInt): IMapIntStr;
  end;

































function TQueueFactory_Integer_TE.MakeSPSC(const ACapacity: SizeInt): IQueueInt; begin Result := TQueueInt_SPSC.Create(ACapacity); end;
function TQueueFactory_Integer_TE.MakeMPSC: IQueueInt; begin Result := TQueueInt_MPSC.Create; end;
function TQueueFactory_Integer_TE.MakeMPMC(const ACapacity: SizeInt): IQueueInt; begin Result := TQueueInt_MPMC.Create(ACapacity); end;
function TStackFactory_Integer_TE.MakeTreiber: IStackInt; begin Result := TStackInt_Treiber.Create; end;
function TStackFactory_Integer_TE.MakePreAlloc(const ACapacity: SizeInt): IStackInt; begin Result := TStackInt_PreAlloc.Create(ACapacity); end;
function TMapFactory_IntStr_TE.MakeOA(const ACapacity: SizeInt): IMapIntStr; begin Result := TMap_IntStr_OA.Create(ACapacity); end;
function TMapFactory_IntStr_TE.MakeMM(const ABucketCount: SizeInt): IMapIntStr; begin Result := TMap_IntStr_MM.Create(ABucketCount); end;

function GetDefaultQueueFactory_Integer_TE: IQueueFactory_Integer; begin Result := TQueueFactory_Integer_TE.Create; end;
function GetDefaultStackFactory_Integer_TE: IStackFactory_Integer; begin Result := TStackFactory_Integer_TE.Create; end;
function GetDefaultMapFactory_IntStr_TE: IMapFactory_IntStr; begin Result := TMapFactory_IntStr_TE.Create; end;



end.


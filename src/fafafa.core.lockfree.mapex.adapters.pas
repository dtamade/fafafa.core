unit fafafa.core.lockfree.mapex.adapters;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.hashmap.openAddressing,
  fafafa.core.lockfree.hashmap;

type
  generic TMapExOAAdapter<K,V> = class(TInterfacedObject, specialize ILockFreeMapEx<K,V>)
  public
    type
      TMap = specialize TLockFreeHashMap<K,V>;
      THashFunc = TMap.THashFunc;
      TEqualFunc = TMap.TEqualFunc;
  private
    FMap: TMap;
  public
    // OA adapter
    constructor Create(Capacity: SizeInt);
    constructor Create(Capacity: SizeInt; AHash: THashFunc; AEqual: TEqualFunc);
    destructor Destroy; override;
    // Base
    function Put(constref Key: K; constref Value: V): Boolean;
    function Get(constref Key: K; out Value: V): Boolean;
    function Remove(constref Key: K): Boolean;
    function ContainsKey(constref Key: K): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    // Ex
    function PutEx(constref Key: K; constref Value: V; out OldValue: V): TMapPutResult;
    function RemoveEx(constref Key: K; out OldValue: V): TMapRemoveResult;
    // Entry/Compute
    function PutIfAbsent(constref Key: K; constref Value: V; out Inserted: Boolean): Boolean;
    function GetOrAdd(constref Key: K; constref DefaultValue: V; out OutValue: V): Boolean;
    function Compute(constref Key: K; UpdateFn: specialize TMapComputeFunc<V>; out Updated: Boolean): Boolean;
  end;

  // MM adapter
  generic TMapExMMAdapter<K,V> = class(TInterfacedObject, specialize ILockFreeMapEx<K,V>)
  public
    type
      TMap = specialize TMichaelHashMap<K,V>;
      THashFunc = TMap.THashFunction;
      TEqualFunc = TMap.TKeyComparer;
  private
    FMap: TMap;
  public
    constructor Create(BucketCount: SizeInt; AHash: THashFunc; AEqual: TEqualFunc);
    destructor Destroy; override;
    // Base
    function Put(constref Key: K; constref Value: V): Boolean;
    function Get(constref Key: K; out Value: V): Boolean;
    function Remove(constref Key: K): Boolean;
    function ContainsKey(constref Key: K): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    // Ex
    function PutEx(constref Key: K; constref Value: V; out OldValue: V): TMapPutResult;
    function RemoveEx(constref Key: K; out OldValue: V): TMapRemoveResult;
    // Entry/Compute
    function PutIfAbsent(constref Key: K; constref Value: V; out Inserted: Boolean): Boolean;
    function GetOrAdd(constref Key: K; constref DefaultValue: V; out OutValue: V): Boolean;
    function Compute(constref Key: K; UpdateFn: specialize TMapComputeFunc<V>; out Updated: Boolean): Boolean;
  end;







implementation

{ TMapExOAAdapter }
constructor TMapExOAAdapter.Create(Capacity: SizeInt);
begin
  inherited Create;
  FMap := TMap.Create(Capacity);
end;


{ TMapExMMAdapter }
constructor TMapExMMAdapter.Create(BucketCount: SizeInt; AHash: THashFunc; AEqual: TEqualFunc);
begin
  inherited Create;
  FMap := TMap.Create(BucketCount, AHash, AEqual);
end;

destructor TMapExMMAdapter.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

function TMapExMMAdapter.Put(constref Key: K; constref Value: V): Boolean;
begin
  if not FMap.insert(Key, Value) then
    Result := FMap.update(Key, Value)
  else
    Result := True;
end;

function TMapExMMAdapter.Get(constref Key: K; out Value: V): Boolean;
begin
  Result := FMap.find(Key, Value);
end;

function TMapExMMAdapter.Remove(constref Key: K): Boolean;
begin
  Result := FMap.erase(Key);
end;

function TMapExMMAdapter.ContainsKey(constref Key: K): Boolean;
var Dummy: V;
begin
  Result := FMap.find(Key, Dummy);
end;

function TMapExMMAdapter.IsEmpty: Boolean;
begin
  Result := FMap.empty;
end;

function TMapExMMAdapter.Size: SizeInt;
begin
  Result := FMap.size;
end;

function TMapExMMAdapter.Capacity: SizeInt;
begin
  Result := FMap.bucket_count;
end;

function TMapExMMAdapter.PutEx(constref Key: K; constref Value: V; out OldValue: V): TMapPutResult;
begin
  if FMap.find(Key, OldValue) then
  begin
    if FMap.update(Key, Value) then
      Exit(mprUpdated)
    else
      Exit(mprFailed);
  end
  else
  begin
    OldValue := Default(V);
    if FMap.insert(Key, Value) then
      Exit(mprInserted)
    else
      Exit(mprFailed);
  end;
end;

function TMapExMMAdapter.RemoveEx(constref Key: K; out OldValue: V): TMapRemoveResult;
begin
  if FMap.find(Key, OldValue) then
  begin
    if FMap.erase(Key) then
      Exit(mrrRemoved)
    else
      Exit(mrrNotFound);
  end
  else
  begin
    OldValue := Default(V);
    Exit(mrrNotFound);
  end;
end;

function TMapExMMAdapter.PutIfAbsent(constref Key: K; constref Value: V; out Inserted: Boolean): Boolean;
begin
  Inserted := FMap.insert(Key, Value);
  Result := Inserted or FMap.update(Key, Value);
end;

function TMapExMMAdapter.GetOrAdd(constref Key: K; constref DefaultValue: V; out OutValue: V): Boolean;
begin
  if FMap.find(Key, OutValue) then
    Exit(True);
  if FMap.insert(Key, DefaultValue) then
  begin
    OutValue := DefaultValue;
    Exit(True);
  end
  else
  begin
    if FMap.find(Key, OutValue) then
      Exit(True)
    else
    begin
      OutValue := Default(V);
      Exit(False);
    end;
  end;
end;

function TMapExMMAdapter.Compute(constref Key: K; UpdateFn: specialize TMapComputeFunc<V>; out Updated: Boolean): Boolean;
var Cur, NewV: V;
begin
  if FMap.find(Key, Cur) then
  begin
    NewV := UpdateFn(Cur);
    Updated := FMap.update(Key, NewV);
    Result := Updated;
  end
  else
  begin
    Updated := False;
    Result := False;
  end;
end;

constructor TMapExOAAdapter.Create(Capacity: SizeInt; AHash: THashFunc; AEqual: TEqualFunc);
begin
  inherited Create;
  FMap := TMap.Create(Capacity, AHash, AEqual);
end;

destructor TMapExOAAdapter.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

function TMapExOAAdapter.Put(constref Key: K; constref Value: V): Boolean;
begin
  Result := FMap.Put(Key, Value);
end;

function TMapExOAAdapter.Get(constref Key: K; out Value: V): Boolean;
begin
  Result := FMap.Get(Key, Value);
end;

function TMapExOAAdapter.Remove(constref Key: K): Boolean;
begin
  Result := FMap.Remove(Key);
end;

function TMapExOAAdapter.ContainsKey(constref Key: K): Boolean;
begin
  Result := FMap.ContainsKey(Key);
end;

function TMapExOAAdapter.IsEmpty: Boolean;
begin
  Result := FMap.IsEmpty;
end;

function TMapExOAAdapter.Size: SizeInt;
begin
  Result := FMap.GetSize;
end;

function TMapExOAAdapter.Capacity: SizeInt;
begin
  Result := FMap.GetCapacity;
end;

function TMapExOAAdapter.PutEx(constref Key: K; constref Value: V; out OldValue: V): TMapPutResult;
var
  HadOld: Boolean;
begin
  HadOld := FMap.Get(Key, OldValue);
  if HadOld then
    Result := mprUpdated
  else
  begin
    OldValue := Default(V);
    Result := mprInserted;
  end;
  if not FMap.Put(Key, Value) then
    Result := mprFailed;
end;

function TMapExOAAdapter.RemoveEx(constref Key: K; out OldValue: V): TMapRemoveResult;
begin
  if FMap.Get(Key, OldValue) then
  begin
    if FMap.Remove(Key) then
      Exit(mrrRemoved)
    else
      Exit(mrrNotFound);
  end
  else
  begin
    OldValue := Default(V);
    Exit(mrrNotFound);
  end;
end;

function TMapExOAAdapter.PutIfAbsent(constref Key: K; constref Value: V; out Inserted: Boolean): Boolean;
var
  Dummy: V;
begin
  if FMap.Get(Key, Dummy) then
  begin
    Inserted := False;
    Exit(True);
  end;
  Inserted := FMap.Put(Key, Value);
  Result := Inserted;
end;

function TMapExOAAdapter.GetOrAdd(constref Key: K; constref DefaultValue: V; out OutValue: V): Boolean;
begin
  if FMap.Get(Key, OutValue) then
    Exit(True);
  if FMap.Put(Key, DefaultValue) then
  begin
    OutValue := DefaultValue;
    Exit(True);
  end
  else
  begin
    // Possible race: another thread inserted concurrently; re-read
    if FMap.Get(Key, OutValue) then
      Exit(True)
    else
    begin
      OutValue := Default(V);
      Exit(False);
    end;
  end;
end;

function TMapExOAAdapter.Compute(constref Key: K; UpdateFn: specialize TMapComputeFunc<V>; out Updated: Boolean): Boolean;
var
  Cur, NewV: V;
begin
  if FMap.Get(Key, Cur) then
  begin
    NewV := UpdateFn(Cur);
    Updated := FMap.Put(Key, NewV);
    Result := Updated;
  end
  else
  begin
    Updated := False;
    Result := False;
  end;
end;

end.


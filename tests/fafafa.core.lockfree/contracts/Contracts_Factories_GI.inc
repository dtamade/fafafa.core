{ GI（泛型接口）工厂声明占位 - 仅用于 FPC 3.3.1+ 的契约实验，不改 src }

{$IFNDEF Contracts_Factories_GI_Included}
{$DEFINE Contracts_Factories_GI_Included}

{$mode objfpc}{$H+}

{$IF FPC_FULLVERSION >= 030301}

generic IQueueGI<T> = interface
  function Enqueue(constref Item: T): Boolean;
  function TryDequeue(out Item: T): Boolean;
  function TryPeek(out Item: T): Boolean;
  function IsEmpty: Boolean;
  function Size: SizeInt;
  function Capacity: SizeInt;
  function Bounded: Boolean;
end;

generic IStackGI<T> = interface
  function Push(constref Item: T): Boolean;
  function TryPop(out Item: T): Boolean;
  function TryPeek(out Item: T): Boolean;
  function IsEmpty: Boolean;
  function Size: SizeInt;
  function Capacity: SizeInt;
  function Bounded: Boolean;
end;

generic IMapGI<K,V> = interface
  function Put(constref K: K; constref V: V; out Replaced: Boolean): Boolean;
  function TryGetValue(constref K: K; out V: V): Boolean;
  function Remove(constref K: K; out OldValue: V): Boolean;
  function ContainsKey(constref K: K): Boolean;
  procedure Clear;
  function Size: SizeInt;
end;

// 工厂接口（示例：Integer / Integer->string）
IQueueGIFactory_Integer = interface
  ['{0C1653A1-0A41-4DB2-9ECA-8F2C19E3A1D3}']
  function MakeSPSC(const ACapacity: SizeInt): specialize IQueueGI<Integer>;
  function MakeMPSC: specialize IQueueGI<Integer>;
  function MakeMPMC(const ACapacity: SizeInt): specialize IQueueGI<Integer>;
end;

IStackGIFactory_Integer = interface
  ['{7694FB4E-6B0E-43B1-9460-7A66F027B61E}']
  function MakeTreiber: specialize IStackGI<Integer>;
  function MakePreAlloc(const ACapacity: SizeInt): specialize IStackGI<Integer>;
end;

IMapGIFactory_IntStr = interface
  ['{1E78AD2D-5C34-4A36-9E50-5B8C6D930F0B}']
  function MakeOA(const ACapacity: SizeInt): specialize IMapGI<Integer,string>;
  function MakeMM(const ABucketCount: SizeInt): specialize IMapGI<Integer,string>;
end;

{$ENDIF}
{$ENDIF}


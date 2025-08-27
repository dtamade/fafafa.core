unit fafafa.core.collections;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  // 基础与通用抽象
  fafafa.core.base,
  fafafa.core.math,
  fafafa.core.mem.utils,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.arr,
  // 容器接口/实现
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.forwardList,
  fafafa.core.collections.deque,
  fafafa.core.collections.queue,
  fafafa.core.collections.stack,
  fafafa.core.collections.list,
  fafafa.core.collections.elementManager,
  // HashMap / HashSet (OA default)
  fafafa.core.collections.hashmap,
  // Ordered containers (RB)
  fafafa.core.collections.orderedset.rb,
  fafafa.core.collections.orderedmap.rb;

type
  // 统一对外导出的关键接口类型（非泛型别名；泛型类型请直接使用其本单元 uses 引入的原始定义）
  ICollection = fafafa.core.collections.base.ICollection;

  // 增长策略导出（接口优先 + 兼容类基实现）
  IGrowthStrategy          = fafafa.core.collections.base.IGrowthStrategy;
  TGrowthStrategy          = fafafa.core.collections.base.TGrowthStrategy;
  TGrowthStrategyClass     = fafafa.core.collections.base.TGrowthStrategyClass;
  TCustomGrowthStrategy    = fafafa.core.collections.base.TCustomGrowthStrategy;
  TDoublingGrowStrategy    = fafafa.core.collections.base.TDoublingGrowStrategy;
  TFixedGrowStrategy       = fafafa.core.collections.base.TFixedGrowStrategy;
  TFactorGrowStrategy      = fafafa.core.collections.base.TFactorGrowStrategy;
  TPowerOfTwoGrowStrategy  = fafafa.core.collections.base.TPowerOfTwoGrowStrategy;
  TGoldenRatioGrowStrategy = fafafa.core.collections.base.TGoldenRatioGrowStrategy;
  TAlignedWrapperStrategy  = fafafa.core.collections.base.TAlignedWrapperStrategy;

{$IFDEF FAFAFA_CORE_TYPE_ALIASES}
  // 可选：常用 specialization 的类型别名，避免重复 specialization（按需开启）
{$ENDIF}

// 工厂函数（TDD：先声明，后实现；优先 MakeVec/MakeVecDeque/MakeArray）
// 为减少调用方对实现细节的耦合，返回接口类型
// 约定：Capacity=0 表示按实现默认容量策略；GrowStrategy=nil 则使用默认策略

// ==== Vec / VecDeque (capacity-based) ====

generic function MakeVec<T>(aCapacity: SizeUInt = 0; aAllocator: IAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IVec<T>;



generic function MakeVecDeque<T>(aCapacity: SizeUInt = 0; aAllocator: IAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IDeque<T>;

generic function MakeArr<T>(aAllocator: IAllocator = nil): specialize IArray<T>; overload;
generic function MakeArr<T>(const aSrc: array of T; aAllocator: IAllocator = nil): specialize IArray<T>; overload;

generic function MakeArr<T>(const aSrcCollection: TCollection; aAllocator: IAllocator = nil): specialize IArray<T>; overload;

generic function MakeArr<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aData: Pointer): specialize IArray<T>; overload;

generic function MakeArr<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator = nil): specialize IArray<T>; overload;

// ==== HashMap / HashSet (OA default) ====
{$IFNDEF FAFAFA_COLLECTIONS_DISABLE_HASH}
  generic function MakeHashMap<K,V>(aCapacity: SizeUInt = 0; aHash: specialize THashFunc<K> = nil; aEquals: specialize TEqualsFunc<K> = nil; aAllocator: IAllocator = nil): specialize IHashMap<K,V>;
  generic function MakeHashSet<K>(aCapacity: SizeUInt = 0; aHash: specialize THashFunc<K> = nil; aEquals: specialize TEqualsFunc<K> = nil; aAllocator: IAllocator = nil): specialize IHashSet<K>;
{$ENDIF}



generic function MakeArr<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aData: Pointer): specialize IArray<T>; overload;

{$IFDEF FAFAFA_COLLECTIONS_FACADE}

// ==== Deque (source-based) ====

generic function MakeDeque<T>(const aSrc: array of T; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IDeque<T>; overload;

generic function MakeDeque<T>(const aSrcCollection: TCollection; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IDeque<T>; overload;

generic function MakeDeque<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IDeque<T>; overload;

generic function MakeDeque<T>(const aSrcCollection: TCollection; aAllocator: TAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IDeque<T>; overload;

generic function MakeDeque<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IDeque<T>; overload;

// ==== Queue (source-based) ====

generic function MakeQueue<T>(const aSrc: array of T; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IQueue<T>; overload;

generic function MakeQueue<T>(const aSrcCollection: TCollection; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IQueue<T>; overload;

generic function MakeQueue<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IQueue<T>; overload;

generic function MakeQueue<T>(const aSrcCollection: TCollection; aAllocator: TAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IQueue<T>; overload;

generic function MakeQueue<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IQueue<T>; overload;

// ==== Stack (source-based) ====

generic function MakeStack<T>(aCapacity: SizeUInt = 0; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IStack<T>; overload;

generic function MakeStack<T>(const aSrc: array of T; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IStack<T>; overload;

generic function MakeStack<T>(const aSrcCollection: TCollection; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IStack<T>; overload;

generic function MakeStack<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IStack<T>; overload;

generic function MakeStack<T>(const aSrcCollection: TCollection; aAllocator: TAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IStack<T>; overload;

generic function MakeStack<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IStack<T>; overload;

// ==== List (source-based + capacity) ====

generic function MakeList<T>(aAllocator: TAllocator = nil): specialize IList<T>; overload;

generic function MakeList<T>(const aSrc: array of T; aAllocator: TAllocator = nil): specialize IList<T>; overload;

generic function MakeList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator = nil): specialize IList<T>; overload;

generic function MakeList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aData: Pointer): specialize IList<T>; overload;

  // List (capacity-based)
  generic function MakeList<T>(aCapacity: SizeUInt = 0; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IList<T>; overload;

// ==== ForwardList (source-based) ====

generic function MakeForwardList<T>(aAllocator: TAllocator = nil): specialize IForwardList<T>; overload;

generic function MakeForwardList<T>(const aSrc: array of T; aAllocator: TAllocator = nil): specialize IForwardList<T>; overload;

generic function MakeForwardList<T>(const aSrcCollection: TCollection; aAllocator: TAllocator = nil): specialize IForwardList<T>; overload;

generic function MakeForwardList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator = nil): specialize IForwardList<T>; overload;

generic function MakeForwardList<T>(const aSrcCollection: TCollection; aAllocator: TAllocator; aData: Pointer): specialize IForwardList<T>; overload;

generic function MakeForwardList<T>(const aSrc: array of T; aAllocator: TAllocator; aData: Pointer): specialize IForwardList<T>; overload;

generic function MakeForwardList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aData: Pointer): specialize IForwardList<T>; overload;

generic function MakeDeque<T>(aCapacity: SizeUInt = 0; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IDeque<T>;

generic function MakeQueue<T>(aCapacity: SizeUInt = 0; aAllocator: TAllocator = nil; aGrowStrategy: TGrowthStrategy = nil): specialize IQueue<T>;



{$ENDIF}




implementation

// 工厂实现
// 说明：当前直接创建真实实例，返回接口以降低调用方耦合
generic function MakeVec<T>(aCapacity: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IVec<T>;
begin
  Exit(specialize TVec<T>.Create(aCapacity, aAllocator, aGrowStrategy));
end;


// Arr from pointer+count
generic function MakeArr<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IArray<T>;
begin
  Exit(specialize TArray<T>.Create(aSrc, aElementCount, aAllocator));
end;

generic function MakeArr<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IArray<T>;
begin
  Exit(specialize TArray<T>.Create(aSrc, aElementCount, aAllocator, aData));
end;



generic function MakeVecDeque<T>(aCapacity: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IDeque<T>;
begin
  // 支持传入增长策略；内部会将容量统一归一到 2 的幂
  Exit(specialize TVecDeque<T>.Create(aCapacity, aAllocator, aGrowStrategy));
end;


{$IFDEF FAFAFA_COLLECTIONS_FACADE}

// ForwardList factories
generic function MakeForwardList<T>(aAllocator: IAllocator): specialize IForwardList<T>;
var LI: specialize IForwardList<T>;
begin
  if aAllocator <> nil then LI := specialize TForwardList<T>.Create(aAllocator)
  else LI := specialize TForwardList<T>.Create;
  Result := LI;
end;

generic function MakeForwardList<T>(const aSrc: array of T; aAllocator: IAllocator): specialize IForwardList<T>;
var LI: specialize IForwardList<T>;
begin
  if aAllocator <> nil then LI := specialize TForwardList<T>.Create(aSrc, aAllocator)
  else LI := specialize TForwardList<T>.Create(aSrc);
  Result := LI;
end;

generic function MakeForwardList<T>(const aSrcCollection: TCollection; aAllocator: IAllocator): specialize IForwardList<T>;
var LI: specialize IForwardList<T>;
begin
  if aAllocator <> nil then LI := specialize TForwardList<T>.Create(aSrcCollection, aAllocator)
  else LI := specialize TForwardList<T>.Create(aSrcCollection);
  Result := LI;
end;

generic function MakeForwardList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IForwardList<T>;
var LI: specialize IForwardList<T>;
begin
  if aAllocator <> nil then LI := specialize TForwardList<T>.Create(aSrc, aElementCount, aAllocator)
  else LI := specialize TForwardList<T>.Create(aSrc, aElementCount, GetRtlAllocator());
  Result := LI;
end;

generic function MakeForwardList<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aData: Pointer): specialize IForwardList<T>;
var LI: specialize IForwardList<T>;
begin
  if aAllocator <> nil then LI := specialize TForwardList<T>.Create(aSrcCollection, aAllocator, aData)
  else LI := specialize TForwardList<T>.Create(aSrcCollection, GetRtlAllocator(), aData);
  Result := LI;
end;

generic function MakeForwardList<T>(const aSrc: array of T; aAllocator: IAllocator; aData: Pointer): specialize IForwardList<T>;
var LI: specialize IForwardList<T>;
begin
  if aAllocator <> nil then LI := specialize TForwardList<T>.Create(aSrc, aAllocator, aData)
  else LI := specialize TForwardList<T>.Create(aSrc, GetRtlAllocator(), aData);
  Result := LI;
end;

generic function MakeForwardList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IForwardList<T>;
var LI: specialize IForwardList<T>;
begin
  if aAllocator <> nil then LI := specialize TForwardList<T>.Create(aSrc, aElementCount, aAllocator, aData)
  else LI := specialize TForwardList<T>.Create(aSrc, aElementCount, GetRtlAllocator(), aData);
  Result := LI;
end;

// List factories
generic function MakeList<T>(aAllocator: IAllocator): specialize IList<T>;
var LObj: specialize TList<T>;
begin
  if aAllocator <> nil then LObj := specialize TList<T>.Create(aAllocator)
  else LObj := specialize TList<T>.Create;
  Result := LObj;
end;

generic function MakeList<T>(const aSrc: array of T; aAllocator: IAllocator): specialize IList<T>;
var LObj: specialize TList<T>;
begin
  if aAllocator <> nil then LObj := specialize TList<T>.Create(aSrc, aAllocator)
  else LObj := specialize TList<T>.Create(aSrc);
  Result := LObj;
end;

generic function MakeList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IList<T>;
var LObj: specialize TList<T>;
begin
  if aAllocator <> nil then LObj := specialize TList<T>.Create(aSrc, aElementCount, aAllocator)
  else LObj := specialize TList<T>.Create(aSrc, aElementCount, GetRtlAllocator());
  Result := LObj;
end;


// Deque factories (source-based)
generic function MakeDeque<T>(const aSrc: array of T; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IDeque<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrc, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVecDeque<T>.Create(aSrc, aAllocator));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrc));
end;

generic function MakeDeque<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IDeque<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrcCollection));
end;

generic function MakeDeque<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IDeque<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount));
end;

generic function MakeDeque<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IDeque<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator, aGrowStrategy, aData))
    else
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator, aData));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrcCollection, GetRtlAllocator(), aData));
end;

generic function MakeDeque<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IDeque<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator, aGrowStrategy, aData))
    else
      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator, aData));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, GetRtlAllocator(), aData));
end;

// Queue factories (delegate to Deque)
generic function MakeQueue<T>(const aSrc: array of T; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IQueue<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrc, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVecDeque<T>.Create(aSrc, aAllocator));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrc));
end;

generic function MakeQueue<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IQueue<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrcCollection));
end;

generic function MakeQueue<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IQueue<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount));
end;

generic function MakeQueue<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IQueue<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator, aGrowStrategy, aData))
    else
      Exit(specialize TVecDeque<T>.Create(aSrcCollection, aAllocator, aData));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrcCollection, GetRtlAllocator(), aData));
end;

generic function MakeQueue<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IQueue<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator, aGrowStrategy, aData))
    else

      Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, aAllocator, aData));
  end
  else
    Exit(specialize TVecDeque<T>.Create(aSrc, aElementCount, GetRtlAllocator(), aData));
end;

// Stack factories (based on TVec)
generic function MakeStack<T>(aCapacity: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IStack<T>;
begin
  Exit(specialize TVec<T>.Create(aCapacity, aAllocator, aGrowStrategy));
end;

generic function MakeStack<T>(const aSrc: array of T; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IStack<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVec<T>.Create(aSrc, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVec<T>.Create(aSrc, aAllocator));
  end
  else
    Exit(specialize TVec<T>.Create(aSrc));
end;

generic function MakeStack<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IStack<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVec<T>.Create(aSrcCollection, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVec<T>.Create(aSrcCollection, aAllocator));
  end
  else
    Exit(specialize TVec<T>.Create(aSrcCollection));
end;

generic function MakeStack<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IStack<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVec<T>.Create(aSrc, aElementCount, aAllocator, aGrowStrategy))
    else
      Exit(specialize TVec<T>.Create(aSrc, aElementCount, aAllocator));
  end
  else
    Exit(specialize TVec<T>.Create(aSrc, aElementCount));
end;

generic function MakeStack<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IStack<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVec<T>.Create(aSrcCollection, aAllocator, aGrowStrategy, aData))
    else
      Exit(specialize TVec<T>.Create(aSrcCollection, aAllocator, aData));
  end
  else
    Exit(specialize TVec<T>.Create(aSrcCollection, GetRtlAllocator(), aData));
end;

generic function MakeStack<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy; aData: Pointer): specialize IStack<T>;
begin
  if aAllocator <> nil then
  begin
    if aGrowStrategy <> nil then
      Exit(specialize TVec<T>.Create(aSrc, aElementCount, aAllocator, aGrowStrategy, aData))
    else
      Exit(specialize TVec<T>.Create(aSrc, aElementCount, aAllocator, aData));
  end
  else
    Exit(specialize TVec<T>.Create(aSrc, aElementCount, GetRtlAllocator(), aData));
end;

generic function MakeList<T>(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aData: Pointer): specialize IList<T>;
var LObj: specialize TList<T>;
begin
  if aAllocator <> nil then LObj := specialize TList<T>.Create(aSrc, aElementCount, aAllocator, aData)
  else LObj := specialize TList<T>.Create(aSrc, aElementCount, GetRtlAllocator(), aData);
  Result := LObj;
end;

{$ENDIF}




generic function MakeArr<T>(aAllocator: IAllocator): specialize IArray<T>;
begin
  Exit(specialize TArray<T>.Create(0, aAllocator));
end;

// From dynamic array (copy)
generic function MakeArr<T>(const aSrc: array of T; aAllocator: IAllocator): specialize IArray<T>;
begin
  Exit(specialize TArray<T>.Create(aSrc, aAllocator));
end;

// From another collection (copy)
generic function MakeArr<T>(const aSrcCollection: TCollection; aAllocator: IAllocator): specialize IArray<T>;
begin
  Exit(specialize TArray<T>.Create(aSrcCollection, aAllocator));
end;


// From another collection with data (copy)
generic function MakeArr<T>(const aSrcCollection: TCollection; aAllocator: IAllocator; aData: Pointer): specialize IArray<T>;
begin
  Exit(specialize TArray<T>.Create(aSrcCollection, aAllocator, aData));
end;


// Facade capacity-based factories (unconditionally compiled)




generic function MakeList<T>(aCapacity: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IList<T>;
begin
  // 当前 List 实现不区分容量，保持接口一致性
  if aAllocator <> nil then
    Exit(specialize TList<T>.Create(aAllocator))
  else
    Exit(specialize TList<T>.Create);
end;


generic function MakeDeque<T>(aCapacity: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IDeque<T>;
begin
  Exit(specialize TVecDeque<T>.Create(aCapacity, aAllocator, aGrowStrategy));
end;


generic function MakeQueue<T>(aCapacity: SizeUInt; aAllocator: IAllocator; aGrowStrategy: TGrowthStrategy): specialize IQueue<T>;
begin
  Exit(specialize TVecDeque<T>.Create(aCapacity, aAllocator, aGrowStrategy));
end;


{$IFNDEF FAFAFA_COLLECTIONS_DISABLE_HASH}
// HashMap / HashSet factories — implementation will be provided by hashmap unit

generic function MakeHashMap<K,V>(aCapacity: SizeUInt; aHash: specialize THashFunc<K>; aEquals: specialize TEqualsFunc<K>; aAllocator: IAllocator): specialize IHashMap<K,V>;
begin
  // Construct real HashMap instance
  Result := specialize THashMap<K,V>.Create(aCapacity, aHash, aEquals, aAllocator);
end;

generic function MakeHashSet<K>(aCapacity: SizeUInt; aHash: specialize THashFunc<K>; aEquals: specialize TEqualsFunc<K>; aAllocator: IAllocator): specialize IHashSet<K>;
begin
  Result := specialize THashSet<K>.Create(aCapacity, aHash, aEquals, aAllocator);
end;
{$ENDIF}




// end of capacity-based factories

end.
unit fafafa.core.lockfree;



{**
 * 模块: fafafa.core.lockfree
 * 描述: 无锁数据结构门面与常用别名/便捷构造器，统一对外接口
 *
 * 提供的数据结构:
 *   - 无锁哈希表 (hashmap)
 *   - 无锁优先队列 (priorityQueue)
 *   - 无锁双端队列 (deque)
 *   - 无锁环形缓冲区 (ringBuffer)
 *   - 单生产者单消费者队列 (spscQueue)
 *   - Michael-Scott 队列 (michaelScottQueue)
 *   - 预分配 MPMC 队列 (mpmcQueue)
 *   - 无锁栈 (stack)
 *
 * 设计要点:
 *   - 基于原子操作的无锁实现
 *   - 统一门面导出，便于使用和维护
 *   - 提供常用类型的别名与 Create… 便捷构造函数
 *
 * 提示: HashMap 选型指南请参见 docs/topics/lockfree/README_LOCKFREE.md（OA vs MM 的差异与选择）

 *
 * 作者: fafafa.core 开发团队
 * 版本: 1.2.0
 * 许可: MIT
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  // 原子统一到 fafafa.core.atomic
  fafafa.core.atomic,
  // 导入基础与子模块（按需引用）
  fafafa.core.lockfree.util,
  fafafa.core.lockfree.stats,
  fafafa.core.lockfree.perf, // 引入 perf 以满足别名引用
  // 导出所有无锁数据结构子模块
  fafafa.core.lockfree.hashmap,
  fafafa.core.lockfree.priorityQueue,
  fafafa.core.lockfree.deque,
  fafafa.core.lockfree.ringBuffer,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.michaelScottQueue,
  fafafa.core.lockfree.mpmcQueue,
  fafafa.core.lockfree.channel,
  fafafa.core.lockfree.channel.wait,
  fafafa.core.lockfree.channel.select,
  fafafa.core.lockfree.hashmap.openAddressing,
  fafafa.core.lockfree.stack
  {$IFDEF FAFAFA_CORE_IFACE_FACTORIES}
  ,fafafa.core.lockfree.ifaces
  ,fafafa.core.lockfree.factories
  {$ENDIF}
  ;

type
  // 重新导出统计相关类型
  ILockFreeStats = fafafa.core.lockfree.stats.ILockFreeStats;
  TLockFreeStats = fafafa.core.lockfree.stats.TLockFreeStats;

  {**
   * 重新导出子模块类型
   *}
  // 从 hashmap 模块重新导出
  TStringIntHashMap = fafafa.core.lockfree.hashmap.TStringIntHashMap;
  TIntStringHashMap = fafafa.core.lockfree.hashmap.TIntStringHashMap;

  // 从 priorityQueue 模块重新导出
  TIntegerPriorityQueue = fafafa.core.lockfree.priorityQueue.TIntegerPriorityQueue;
  TStringPriorityQueue = fafafa.core.lockfree.priorityQueue.TStringPriorityQueue;

  // 从 deque 模块重新导出
  TIntegerDeque = fafafa.core.lockfree.deque.TIntegerDeque;
  TStringDeque = fafafa.core.lockfree.deque.TStringDeque;

  // 从 ringBuffer 模块重新导出
  TIntegerRingBuffer = fafafa.core.lockfree.ringBuffer.TIntegerRingBuffer;
  TStringRingBuffer = fafafa.core.lockfree.ringBuffer.TStringRingBuffer;

  // 从 spscQueue 模块重新导出
  TIntegerSPSCQueue = fafafa.core.lockfree.spscQueue.TIntegerSPSCQueue;
  TStringSPSCQueue = fafafa.core.lockfree.spscQueue.TStringSPSCQueue;


  {**
   * 常用类型别名（用于便捷构造的返回类型；避免在 interface 段直接使用 specialize）
   *}
  // SPSC 队列
  TInt64SPSCQueue = specialize TSPSCQueue<Int64>;
  TDoubleSPSCQueue = specialize TSPSCQueue<Double>;

  // MPSCQueue 特化（Michael-Scott 实现；推荐对外名称）
  TIntMPSCQueue = specialize TMichaelScottQueue<Integer>;
  TStringMPSCQueue = specialize TMichaelScottQueue<string>;
  TInt64MPSCQueue = specialize TMichaelScottQueue<Int64>;
  TPtrMPSCQueue = specialize TMichaelScottQueue<Pointer>;
  TDoubleMPSCQueue = specialize TMichaelScottQueue<Double>;

  // MSQueue 同义别名（已弃用：请使用 *MPSCQueue 别名）
  TIntMSQueue = TIntMPSCQueue deprecated 'Use TIntMPSCQueue';
  TStringMSQueue = TStringMPSCQueue deprecated 'Use TStringMPSCQueue';
  TInt64MSQueue = TInt64MPSCQueue deprecated 'Use TInt64MPSCQueue';
  TPtrMSQueue = TPtrMPSCQueue deprecated 'Use TPtrMPSCQueue';
  TDoubleMSQueue = TDoubleMPSCQueue deprecated 'Use TDoubleMPSCQueue';

  // MPMC 特化
  TIntMPMCQueue = specialize TPreAllocMPMCQueue<Integer>;
  TStringMPMCQueue = specialize TPreAllocMPMCQueue<string>;
  TInt64MPMCQueue = specialize TPreAllocMPMCQueue<Int64>;
  TPtrMPMCQueue = specialize TPreAllocMPMCQueue<Pointer>;
  TDoubleMPMCQueue = specialize TPreAllocMPMCQueue<Double>;

  // Channel types are defined in fafafa.core.lockfree.channel.
  // NOTE: FPC does not support cross-unit generic type aliases (generic TA<T> = unit.TB<T>).

  // HashMap 特化（开放寻址 OA）
  TIntIntOAHashMap = specialize TLockFreeHashMap<Integer, Integer>;
  TIntStrOAHashMap = specialize TLockFreeHashMap<Integer, string>;
  TStrIntOAHashMap = specialize TLockFreeHashMap<string, Integer>;
  TStrStrOAHashMap = specialize TLockFreeHashMap<string, string>;

  // HashMap 特化（Michael & Michael MM）
  TIntIntMMHashMap = specialize TMichaelHashMap<Integer, Integer>;
  TIntStrMMHashMap = specialize TMichaelHashMap<Integer, string>;
  TStrIntMMHashMap = specialize TMichaelHashMap<string, Integer>;
  TStrStrMMHashMap = specialize TMichaelHashMap<string, string>;

  // Stack 门面别名
  TIntTreiberStack = specialize TTreiberStack<Integer>;
  TStringTreiberStack = specialize TTreiberStack<string>;
  TInt64TreiberStack = specialize TTreiberStack<Int64>;
  TPtrTreiberStack = specialize TTreiberStack<Pointer>;
  TDoubleTreiberStack = specialize TTreiberStack<Double>;

  TIntPreAllocStack = specialize TPreAllocStack<Integer>;
  TStringPreAllocStack = specialize TPreAllocStack<string>;
  TInt64PreAllocStack = specialize TPreAllocStack<Int64>;
  TPtrPreAllocStack = specialize TPreAllocStack<Pointer>;
  TDoublePreAllocStack = specialize TPreAllocStack<Double>;

  generic TLockFreeNode<T> = record
    Data: T;
    Next: Pointer; // 指向下一个节点的原子指针
  end;

  // 使用子模块中的性能监控器类型
  TPerformanceMonitor = fafafa.core.lockfree.perf.TPerformanceMonitor; // keep alias
type
  _perf_unit_ref_for_compiler = type pointer; // (remove if causing issues)

  {**
   * 实用工具函数
   *}

  // 计算下一个2的幂次方
  function NextPowerOfTwo(AValue: Integer): Integer;

  // 检查是否为2的幂次方
  function IsPowerOfTwo(AValue: Integer): Boolean;

  // 简单哈希函数
  function SimpleHash(const AData; ASize: Integer): Cardinal;

  // 重新导出子模块函数
  function DefaultStringHash(const AKey: string): QWord;
  function DefaultIntegerHash(const AKey: Integer): QWord;

  { 快捷构造器（对外导出） }
  function CreateIntSPSCQueue(ACapacity: Integer = 1024): TIntegerSPSCQueue;
  function CreateStrSPSCQueue(ACapacity: Integer = 1024): TStringSPSCQueue;
  // MSQueue 构造器（已弃用：请使用 Create* MPSCQueue）
  function CreateIntMSQueue: TIntMSQueue; deprecated 'Use CreateIntMPSCQueue';
  function CreateStrMSQueue: TStringMSQueue; deprecated 'Use CreateStrMPSCQueue';
  function CreateIntMPMCQueue(ACapacity: Integer = 1024): TIntMPMCQueue;

  // MPSC（Michael-Scott）— 推荐构造器
  function CreateIntMPSCQueue: TIntMPSCQueue;
  function CreateStrMPSCQueue: TStringMPSCQueue;
  function CreateInt64MPSCQueue: TInt64MPSCQueue;
  function CreatePtrMPSCQueue: TPtrMPSCQueue;
  function CreateDoubleMPSCQueue: TDoubleMPSCQueue;

  // 更多常用类型（SPSC）
  function CreateInt64SPSCQueue(ACapacity: Integer = 1024): TInt64SPSCQueue;
  function CreatePtrSPSCQueue(ACapacity: Integer = 1024): TPointerSPSCQueue;
  function CreateDoubleSPSCQueue(ACapacity: Integer = 1024): TDoubleSPSCQueue;

  // 更多常用类型（MSQueue）
  function CreateInt64MSQueue: TInt64MSQueue;
  function CreatePtrMSQueue: TPtrMSQueue;
  function CreateDoubleMSQueue: TDoubleMSQueue;

  // 更多常用类型（MPMC）
  function CreateInt64MPMCQueue(ACapacity: Integer = 1024): TInt64MPMCQueue;
  function CreatePtrMPMCQueue(ACapacity: Integer = 1024): TPtrMPMCQueue;
  function CreateStrMPMCQueue(ACapacity: Integer = 1024): TStringMPMCQueue;
  function CreateDoubleMPMCQueue(ACapacity: Integer = 1024): TDoubleMPMCQueue;

  generic function WaitAnyChannelReceiveReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64 = -1): SizeInt;
  generic function WaitAnyChannelSendReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64 = -1): SizeInt;
  generic function ChannelSelectReceive<T>(const aChannels: specialize TChannelArray<T>; out aValue: T; aTimeoutUs: Int64 = -1): SizeInt;
  generic function ChannelSelectSend<T>(const aChannels: specialize TChannelArray<T>; const aValues: array of T; aTimeoutUs: Int64 = -1): SizeInt;

  // Stack 便捷构造
  function CreateIntTreiberStack: TIntTreiberStack;
  function CreateStrTreiberStack: TStringTreiberStack;
  function CreateInt64TreiberStack: TInt64TreiberStack;
  function CreatePtrTreiberStack: TPtrTreiberStack;
  function CreateDoubleTreiberStack: TDoubleTreiberStack;

  function CreateIntPreAllocStack(ACapacity: Integer = 1024): TIntPreAllocStack;
  function CreateStrPreAllocStack(ACapacity: Integer = 1024): TStringPreAllocStack;
  function CreateInt64PreAllocStack(ACapacity: Integer = 1024): TInt64PreAllocStack;
  function CreatePtrPreAllocStack(ACapacity: Integer = 1024): TPtrPreAllocStack;
  // Deque 便捷构造
  function CreateIntDeque(AInitialCapacity: Integer = 1024): TIntegerDeque;
  function CreateStrDeque(AInitialCapacity: Integer = 1024): TStringDeque;
  function CreatePtrDeque(AInitialCapacity: Integer = 1024): TPointerDeque;

  // RingBuffer 便捷构造
  function CreateIntRingBuffer(ACapacity: Integer = 1024): TIntegerRingBuffer;
  function CreateStrRingBuffer(ACapacity: Integer = 1024): TStringRingBuffer;
  function CreatePtrRingBuffer(ACapacity: Integer = 1024): TPointerRingBuffer;

  // PriorityQueue 便捷构造（使用默认比较器）
  function CreateIntPriorityQueue: TIntegerPriorityQueue;
  function CreateStrPriorityQueue: TStringPriorityQueue;

  function CreateDoublePreAllocStack(ACapacity: Integer = 1024): TDoublePreAllocStack;

  // 开放寻址 HashMap（常用类型）
  function CreateIntIntOAHashMap(ACapacity: Integer = 1024): TIntIntOAHashMap;
  function CreateIntStrOAHashMap(ACapacity: Integer = 1024): TIntStrOAHashMap;
  function CreateStrIntOAHashMap(ACapacity: Integer = 1024): TStrIntOAHashMap;
  function CreateStrStrOAHashMap(ACapacity: Integer = 1024): TStrStrOAHashMap;
  function CreateStrIntOAHashMapStrict(ACapacity: Integer; AHash: TStrIntOAHashMap.THashFunc; AEqual: TStrIntOAHashMap.TEqualFunc): TStrIntOAHashMap;

  // Michael & Michael HashMap（常用类型）
  function CreateIntIntMMHashMap(ABucketCount: Integer = 1024): TIntIntMMHashMap;
  function CreateIntStrMMHashMap(ABucketCount: Integer = 1024): TIntStrMMHashMap;
  function CreateStrIntMMHashMap(ABucketCount: Integer = 1024): TStrIntMMHashMap;
  function CreateStrStrMMHashMap(ABucketCount: Integer = 1024): TStrStrMMHashMap;


implementation

function CreateIntSPSCQueue(ACapacity: Integer): TIntegerSPSCQueue;
begin
  Result := TIntegerSPSCQueue.Create(ACapacity);
end;

function CreateStrSPSCQueue(ACapacity: Integer): TStringSPSCQueue;
begin
  Result := TStringSPSCQueue.Create(ACapacity);
end;
function CreateInt64SPSCQueue(ACapacity: Integer): TInt64SPSCQueue;
begin
  Result := TInt64SPSCQueue.Create(ACapacity);
end;

function CreatePtrSPSCQueue(ACapacity: Integer): TPointerSPSCQueue;
begin
  Result := TPointerSPSCQueue.Create(ACapacity);
end;

function CreateDoubleSPSCQueue(ACapacity: Integer): TDoubleSPSCQueue;
begin
  Result := TDoubleSPSCQueue.Create(ACapacity);
end;

generic function WaitAnyChannelReceiveReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64): SizeInt;
begin
  Result := specialize WaitAnyReceiveReady<T>(aChannels, aTimeoutUs);
end;

generic function WaitAnyChannelSendReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64): SizeInt;
begin
  Result := specialize WaitAnySendReady<T>(aChannels, aTimeoutUs);
end;

generic function ChannelSelectReceive<T>(const aChannels: specialize TChannelArray<T>; out aValue: T; aTimeoutUs: Int64): SizeInt;
var
  LIndex: SizeInt;
begin
  LIndex := specialize WaitAnyReceiveReady<T>(aChannels, aTimeoutUs);
  if LIndex < 0 then
    Exit(-1);
  if (aChannels[LIndex] = nil) or (not aChannels[LIndex].TryReceive(aValue)) then
    Exit(-1);
  Result := LIndex;
end;

generic function ChannelSelectSend<T>(const aChannels: specialize TChannelArray<T>; const aValues: array of T; aTimeoutUs: Int64): SizeInt;
var
  LIndex: SizeInt;
begin
  if Length(aChannels) <> Length(aValues) then
    raise Exception.Create('ChannelSelectSend: channels and values length mismatch');

  LIndex := specialize WaitAnySendReady<T>(aChannels, aTimeoutUs);
  if LIndex < 0 then
    Exit(-1);
  if (aChannels[LIndex] = nil) or (not aChannels[LIndex].TrySend(aValues[LIndex])) then
    Exit(-1);
  Result := LIndex;
end;

function CreateInt64MSQueue: TInt64MSQueue;
begin
  Result := TInt64MSQueue.Create;
end;

function CreatePtrMSQueue: TPtrMSQueue;
begin
  Result := TPtrMSQueue.Create;
end;

function CreateDoubleMSQueue: TDoubleMSQueue;
begin
  Result := TDoubleMSQueue.Create;
end;

function CreateInt64MPMCQueue(ACapacity: Integer): TInt64MPMCQueue;
begin
  Result := TInt64MPMCQueue.Create(ACapacity);
end;

function CreatePtrMPMCQueue(ACapacity: Integer): TPtrMPMCQueue;
begin
  Result := TPtrMPMCQueue.Create(ACapacity);
end;

function CreateIntIntOAHashMap(ACapacity: Integer): TIntIntOAHashMap;
begin
  Result := TIntIntOAHashMap.Create(ACapacity);
end;

function CreateIntStrOAHashMap(ACapacity: Integer): TIntStrOAHashMap;
begin
  Result := TIntStrOAHashMap.Create(ACapacity);
end;

function CreateStrIntOAHashMap(ACapacity: Integer): TStrIntOAHashMap;
begin
  Result := TStrIntOAHashMap.Create(ACapacity);
end;

function CreateStrIntOAHashMapStrict(ACapacity: Integer; AHash: TStrIntOAHashMap.THashFunc; AEqual: TStrIntOAHashMap.TEqualFunc): TStrIntOAHashMap;
begin
  Result := TStrIntOAHashMap.NewStrict(ACapacity, AHash, AEqual);
end;

function CreateStrStrOAHashMap(ACapacity: Integer): TStrStrOAHashMap;
begin
  Result := TStrStrOAHashMap.Create(ACapacity);
end;

function CreateIntIntMMHashMap(ABucketCount: Integer): TIntIntMMHashMap;
begin
  Result := TIntIntMMHashMap.Create(ABucketCount, @fafafa.core.lockfree.hashmap.DefaultIntegerHash, @fafafa.core.lockfree.hashmap.DefaultIntegerComparer);
end;

function CreateIntStrMMHashMap(ABucketCount: Integer): TIntStrMMHashMap;
begin
  Result := TIntStrMMHashMap.Create(ABucketCount, @fafafa.core.lockfree.hashmap.DefaultIntegerHash, @fafafa.core.lockfree.hashmap.DefaultIntegerComparer);
end;

function CreateStrIntMMHashMap(ABucketCount: Integer): TStrIntMMHashMap;
begin
  Result := TStrIntMMHashMap.Create(ABucketCount, @fafafa.core.lockfree.hashmap.DefaultStringHash, @fafafa.core.lockfree.hashmap.DefaultStringComparer);
end;

// Deque convenience constructors
function CreateIntDeque(AInitialCapacity: Integer): TIntegerDeque;
begin
  Result := TIntegerDeque.Create(AInitialCapacity);
end;

function CreateStrDeque(AInitialCapacity: Integer): TStringDeque;
begin
  Result := TStringDeque.Create(AInitialCapacity);
end;

function CreatePtrDeque(AInitialCapacity: Integer): TPointerDeque;
begin
  Result := TPointerDeque.Create(AInitialCapacity);
end;

// RingBuffer convenience constructors
function CreateIntRingBuffer(ACapacity: Integer): TIntegerRingBuffer;
begin
  Result := TIntegerRingBuffer.Create(ACapacity);
end;

function CreateStrRingBuffer(ACapacity: Integer): TStringRingBuffer;
begin
  Result := TStringRingBuffer.Create(ACapacity);
end;

function CreatePtrRingBuffer(ACapacity: Integer): TPointerRingBuffer;
begin
  Result := TPointerRingBuffer.Create(ACapacity);
end;

// PriorityQueue convenience constructors
function CreateIntPriorityQueue: TIntegerPriorityQueue;
begin
  Result := TIntegerPriorityQueue.Create(@fafafa.core.lockfree.priorityQueue.DefaultIntegerComparer);
end;

function CreateStrPriorityQueue: TStringPriorityQueue;
begin
  Result := TStringPriorityQueue.Create(@fafafa.core.lockfree.priorityQueue.DefaultStringComparer);
end;


function CreateStrStrMMHashMap(ABucketCount: Integer): TStrStrMMHashMap;
begin
  Result := TStrStrMMHashMap.Create(ABucketCount, @fafafa.core.lockfree.hashmap.DefaultStringHash, @fafafa.core.lockfree.hashmap.DefaultStringComparer);
end;

function CreateStrMPMCQueue(ACapacity: Integer): TStringMPMCQueue;
begin
  Result := TStringMPMCQueue.Create(ACapacity);
end;

function CreateDoubleMPMCQueue(ACapacity: Integer): TDoubleMPMCQueue;
begin
  Result := TDoubleMPMCQueue.Create(ACapacity);
end;


function CreateIntMSQueue: TIntMSQueue;
begin
  Result := TIntMSQueue.Create;
end;

function CreateStrMSQueue: TStringMSQueue;
begin
  Result := TStringMSQueue.Create;
end;

function CreateIntMPMCQueue(ACapacity: Integer): TIntMPMCQueue;
begin
  Result := TIntMPMCQueue.Create(ACapacity);
end;

// MPSC 推荐便捷构造（Michael-Scott 实现）
function CreateIntMPSCQueue: TIntMPSCQueue;
begin
  Result := TIntMPSCQueue.Create;
end;

function CreateStrMPSCQueue: TStringMPSCQueue;
begin
  Result := TStringMPSCQueue.Create;
end;

function CreateInt64MPSCQueue: TInt64MPSCQueue;
begin
  Result := TInt64MPSCQueue.Create;
end;

function CreatePtrMPSCQueue: TPtrMPSCQueue;
begin
  Result := TPtrMPSCQueue.Create;
end;

function CreateDoubleMPSCQueue: TDoubleMPSCQueue;
begin
  Result := TDoubleMPSCQueue.Create;
end;

// Stack 便捷构造
function CreateIntTreiberStack: TIntTreiberStack;
begin
  Result := TIntTreiberStack.Create;
end;

function CreateStrTreiberStack: TStringTreiberStack;
begin
  Result := TStringTreiberStack.Create;
end;

function CreateInt64TreiberStack: TInt64TreiberStack;
begin
  Result := TInt64TreiberStack.Create;
end;

function CreatePtrTreiberStack: TPtrTreiberStack;
begin
  Result := TPtrTreiberStack.Create;
end;

function CreateDoubleTreiberStack: TDoubleTreiberStack;
begin
  Result := TDoubleTreiberStack.Create;
end;

function CreateIntPreAllocStack(ACapacity: Integer): TIntPreAllocStack;
begin
  Result := TIntPreAllocStack.Create(ACapacity);
end;

function CreateStrPreAllocStack(ACapacity: Integer): TStringPreAllocStack;
begin
  Result := TStringPreAllocStack.Create(ACapacity);
end;

function CreateInt64PreAllocStack(ACapacity: Integer): TInt64PreAllocStack;
begin
  Result := TInt64PreAllocStack.Create(ACapacity);
end;

function CreatePtrPreAllocStack(ACapacity: Integer): TPtrPreAllocStack;
begin
  Result := TPtrPreAllocStack.Create(ACapacity);
end;

function CreateDoublePreAllocStack(ACapacity: Integer): TDoublePreAllocStack;
begin
  Result := TDoublePreAllocStack.Create(ACapacity);
end;

{ 重新导出子模块函数 }

// 重新导出哈希函数
function DefaultStringHash(const AKey: string): QWord;
begin
  Result := fafafa.core.lockfree.hashmap.DefaultStringHash(AKey);
end;

function DefaultIntegerHash(const AKey: Integer): QWord;
begin
  Result := fafafa.core.lockfree.hashmap.DefaultIntegerHash(AKey);
end;

{ 实用工具函数 }

function NextPowerOfTwo(AValue: Integer): Integer;
begin
  Result := fafafa.core.lockfree.util.NextPowerOfTwo(AValue);
end;

function IsPowerOfTwo(AValue: Integer): Boolean;
begin
  Result := fafafa.core.lockfree.util.IsPowerOfTwo(AValue);
end;

function SimpleHash(const AData; ASize: Integer): Cardinal;
begin
  Result := fafafa.core.lockfree.util.SimpleHash(AData, ASize);
end;























end.

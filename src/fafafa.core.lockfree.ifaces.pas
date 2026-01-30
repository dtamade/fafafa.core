unit fafafa.core.lockfree.ifaces;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

type

generic TMapComputeFunc<V> = function(const OldValue: V): V;

{!
  Minimal lock-free interfaces for queues and stacks, aligned with the
  existing ILockFreeMap<K,V> style in this codebase.

  Notes:
  - Size/Capacity are best-effort; return -1 if unsupported by implementation
  - Marker interfaces denote concurrency model capability (SPSC/MPSC/MPMC)
}

generic ILockFreeQueue<T> = interface
  ['{B3A9C4D1-2F7D-4C59-9B3E-5F9D4C9E7F21}']
  { Non-blocking (try) semantics }
  function Enqueue(constref Item: T): Boolean;            // existing alias of TryEnqueue
  function Dequeue(out Item: T): Boolean;                 // existing alias of TryDequeue
  function TryEnqueue(constref Item: T): Boolean;         // explicit try alias
  function TryDequeue(out Item: T): Boolean;              // explicit try alias

  { Blocking variants (TimeoutMs < 0 for infinite wait) }
  function EnqueueBlocking(constref Item: T; TimeoutMs: Integer = -1): Boolean;
  function DequeueBlocking(out Item: T; TimeoutMs: Integer = -1): Boolean;

  { Lifecycle }
  procedure Close;
  function IsClosed: Boolean;

  { Bulk operations }
  function EnqueueMany(constref Items: array of T; out Pushed: SizeInt): Boolean;
  function DequeueMany(var OutBuf: array of T; out Popped: SizeInt): Boolean;

  { Introspection (best-effort) }
  function IsEmpty: Boolean;
  function Size: SizeInt;                                 // best-effort; -1 if unsupported
  function Capacity: SizeInt;                             // -1 if unbounded/unsupported
  function RemainingCapacity: SizeInt;                    // -1 if unbounded/unsupported
end;

// Capability markers

generic ILockFreeQueueSPSC<T> = interface(specialize ILockFreeQueue<T>)
  ['{8B00B5C2-0A6E-4B11-8A99-2E4B7CB9C1E4}']
end;

generic ILockFreeQueueMPSC<T> = interface(specialize ILockFreeQueue<T>)
  ['{C1A6C9E7-4D2B-4B3F-9F37-8D1C2A9B5E7F}']
end;

generic ILockFreeQueueMPMC<T> = interface(specialize ILockFreeQueue<T>)
  ['{2E7C9A1B-5D4F-4A3C-8B1F-7E9D2C4A6B3F}']
end;

type
  TLockFreeChannelState = (csOpen, csClosing, csClosed, csFaulted);
  TLockFreeSendResult   = (srOk, srClosed, srTimedOut, srCanceled);
  TLockFreeRecvResult   = (rrOk, rrClosed, rrTimedOut, rrCanceled, rrEmpty);

generic ILockFreeChannel<T> = interface
  ['{89C54A65-5F54-4C8F-9138-3A63E5B9875A}']
  { 单元素语义 }
  function Send(constref aItem: T; aTimeoutUs: Int64 = -1): TLockFreeSendResult;
  function Receive(out aItem: T; aTimeoutUs: Int64 = -1): TLockFreeRecvResult;
  function TrySend(constref aItem: T): Boolean;
  function TryReceive(out aItem: T): Boolean;

  { 批量语义 }
  function SendMany(constref aItems: array of T; out aSent: SizeInt): TLockFreeSendResult;
  function ReceiveMany(var aBuffer: array of T; out aReceived: SizeInt): TLockFreeRecvResult;

  { 状态控制 }
  procedure Complete;                  // 正常完成，发送端不可再推送
  procedure Cancel;                    // 异常终止，唤醒所有等待者
  function State: TLockFreeChannelState;

  { 等待/选择辅助 }
  function WaitSendReady(aTimeoutUs: Int64 = -1): Boolean;
  function WaitReceiveReady(aTimeoutUs: Int64 = -1): Boolean;

  { 诊断（best-effort） }
  function Count: SizeInt;
  function Capacity: SizeInt;
end;

generic ILockFreeChannelSPSC<T> = interface(specialize ILockFreeChannel<T>)
  ['{E9D71B5F-9F2B-4D7A-8F12-0C1D7AE5B61F}']
end;

generic ILockFreeChannelMPSC<T> = interface(specialize ILockFreeChannel<T>)
  ['{C47F9E59-1C73-4A02-9854-BD5F46D77E6A}']
end;

generic ILockFreeChannelMPMC<T> = interface(specialize ILockFreeChannel<T>)
  ['{9F12A87C-6B3E-4A5F-8D10-7A5C1B2D3E45}']
end;


generic ILockFreeStack<T> = interface
  ['{A7C5E3D9-1B2F-4C7E-8A9D-0E1F2A3B4C5D}']
  function Push(constref Item: T): Boolean;               // Try semantics
  function Pop(out Item: T): Boolean;                     // Try semantics
  function TryPeek(out Item: T): Boolean;                 // Non-blocking peek if supported
  procedure Clear;                                        // Drain all items (best-effort)
  function IsEmpty: Boolean;
  function Size: SizeInt;                                 // best-effort; -1 if unsupported
end;

// Extended Map interface with Ex methods returning old values/status
type
  TMapPutResult = (mprInserted, mprUpdated, mprFailed);
  TMapRemoveResult = (mrrRemoved, mrrNotFound);

generic ILockFreeMapEx<K, V> = interface
  ['{F2A8C1D3-4E5B-4C7A-9D8E-1F2A3B4C5D6E}']
  // Basic operations (inherited semantics)
  function Put(constref Key: K; constref Value: V): Boolean;
  function Get(constref Key: K; out Value: V): Boolean;
  function Remove(constref Key: K): Boolean;
  function ContainsKey(constref Key: K): Boolean;
  function IsEmpty: Boolean;
  function Size: SizeInt;
  function Capacity: SizeInt;

  // Extended operations returning old values/status
  function PutEx(constref Key: K; constref Value: V; out OldValue: V): TMapPutResult;
  function RemoveEx(constref Key: K; out OldValue: V): TMapRemoveResult;

  // Entry/Compute style helpers (Java/Rust-inspired)
  function PutIfAbsent(constref Key: K; constref Value: V; out Inserted: Boolean): Boolean;
  function GetOrAdd(constref Key: K; constref DefaultValue: V; out OutValue: V): Boolean;
  function Compute(constref Key: K; UpdateFn: specialize TMapComputeFunc<V>; out Updated: Boolean): Boolean;
end;

implementation

end.

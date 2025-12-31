unit fafafa.core.lockfree.spscQueue;

{**
 * fafafa.core.lockfree.spscQueue - 单生产者单消费者无锁队列
 *
 * @desc 基于环形缓冲区的高性能无锁队列
 *       专为单生产者单消费者场景优化
 *       使用序列号避免false sharing，提供极致性能
 *
 * @author fafafa.collections5 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *
 * @note 设计特性:
 *       - 单生产者单消费者优化
 *       - 基于环形缓冲区实现
 *       - 避免 CAS 操作开销
 *       - 使用简单的原子读写
 *       - 避免 false sharing
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.atomic,
  fafafa.core.collections.queue;

type
  {**
   * 单生产者单消费者无锁队列 (SPSC Queue)
   *
   * @desc 基于环形缓冲区的高性能无锁队列
   *       专为单生产者单消费者场景优化
   *       使用序列号避免false sharing，提供极致性能
   *
   * @note 这是SPSC场景下最优的实现方式
   *       避免了CAS操作的开销，使用简单的原子读写
   *}
  generic TSPSCQueue<T> = class(TInterfacedObject, specialize IQueue<T>)
  public
    type
      PNode = ^TNode;
      TNode = record
        Data: T;
        Sequence: Int64; // 使用Int64与原子操作兼容
      end;

  private
    FBuffer: array of TNode;
    FCapacity: Integer;
    FMask: Integer;
    {$IFDEF FAFAFA_LOCKFREE_CACHELINE_PAD}
    FPad0: array[0..63] of Byte; // padding to avoid false sharing between mask and enqueue
    {$ENDIF}
    FEnqueuePos: Int64;  // 生产者位置（仅生产者修改）
    {$IFDEF FAFAFA_LOCKFREE_CACHELINE_PAD}
    FPad1: array[0..63] of Byte; // padding between enqueue and dequeue positions
    {$ENDIF}
    FDequeuePos: Int64;  // 消费者位置（仅消费者修改）

  public
    constructor Create(ACapacity: Integer = 1024);
    destructor Destroy; override;

    // 入队操作（仅生产者线程调用，无锁）
    function Enqueue(const AItem: T): Boolean;

    // 出队操作（仅消费者线程调用，无锁）
    function Dequeue(out AItem: T): Boolean;

    // 查询操作（线程安全）
    function IsEmpty: Boolean;
    function IsFull: Boolean;
    function Size: Integer;

    // IQueue<T>
    procedure Push(const aElement: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    function  Pop(out aElement: T): Boolean; overload;
    function  Pop: T; overload;
    function  TryPeek(out aElement: T): Boolean; overload;
    function  Peek: T; overload;
    procedure Clear;
    function  Count: SizeUInt;

    function Capacity: Integer;
  end;

  // 常用类型别名
  TIntegerSPSCQueue = specialize TSPSCQueue<Integer>;
  TStringSPSCQueue = specialize TSPSCQueue<string>;
  TPointerSPSCQueue = specialize TSPSCQueue<Pointer>;

// 实用函数
function NextPowerOfTwo(AValue: Integer): Integer;

implementation


// 本地实用函数
function NextPowerOfTwo(AValue: Integer): Integer;
begin
  if AValue <= 1 then
    Exit(1);

  Result := 1;
  while Result < AValue do
    Result := Result shl 1;
end;

{ TSPSCQueue }

constructor TSPSCQueue.Create(ACapacity: Integer);
var
  I: Integer;
begin
  inherited Create;

  // 确保容量是2的幂，便于使用位运算优化
  FCapacity := NextPowerOfTwo(ACapacity);
  FMask := FCapacity - 1;

  SetLength(FBuffer, FCapacity);

  // 初始化序列号
  for I := 0 to FCapacity - 1 do
    FBuffer[I].Sequence := I;

  FEnqueuePos := 0;
  FDequeuePos := 0;
end;

destructor TSPSCQueue.Destroy;
begin
  SetLength(FBuffer, 0);
  inherited Destroy;
end;

function TSPSCQueue.Enqueue(const AItem: T): Boolean;
var
  LPos: QWord;
  LNode: PNode;
  LSequence: QWord;
begin
  LPos := FEnqueuePos;
  LNode := @FBuffer[LPos and FMask];
  LSequence := atomic_load_64(LNode^.Sequence, mo_acquire);

  // 检查是否可以写入
  if LSequence = LPos then
  begin
    LNode^.Data := AItem;
    atomic_store_64(LNode^.Sequence, LPos + 1, mo_release);
    FEnqueuePos := LPos + 1;
    Result := True;
  end
  else
    Result := False; // 队列已满
end;

function TSPSCQueue.Dequeue(out AItem: T): Boolean;
var
  LPos: QWord;
  LNode: PNode;
  LSequence: QWord;
begin
  LPos := FDequeuePos;
  LNode := @FBuffer[LPos and FMask];
  LSequence := atomic_load_64(LNode^.Sequence, mo_acquire);

  // 检查是否可以读取
  if LSequence = LPos + 1 then
  begin
    AItem := LNode^.Data;
    atomic_store_64(LNode^.Sequence, LPos + FCapacity, mo_release);
    FDequeuePos := LPos + 1;
    Result := True;
  end
  else
  begin
    // 初始化输出参数
    AItem := Default(T);
    Result := False; // 队列为空
  end;
end;

function TSPSCQueue.IsEmpty: Boolean;
begin
  Result := FDequeuePos = FEnqueuePos;
end;

function TSPSCQueue.IsFull: Boolean;
begin
  Result := (FEnqueuePos - FDequeuePos) >= FCapacity;
end;

function TSPSCQueue.Size: Integer;
begin
  Result := Integer(FEnqueuePos - FDequeuePos);
end;

{ IQueue<T> 显式实现 }

procedure TSPSCQueue.Push(const aElement: T);
begin
  if not Enqueue(aElement) then
    raise Exception.Create('IQueue.Push: queue is full');
end;

procedure TSPSCQueue.Push(const aSrc: array of T);
var i: SizeInt;
begin
  for i := Low(aSrc) to High(aSrc) do Push(aSrc[i]);
end;

procedure TSPSCQueue.Push(const aSrc: Pointer; aElementCount: SizeUInt);
type PEl = ^T; var i: SizeUInt; p: PEl;
begin
  if (aSrc = nil) and (aElementCount > 0) then
    raise Exception.Create('IQueue.Push(pointer): aSrc is nil');
  p := PEl(aSrc);
  for i := 0 to aElementCount - 1 do begin Push(p^); Inc(p); end;
end;

function TSPSCQueue.Pop(out aElement: T): Boolean;
begin
  Result := Dequeue(aElement);
end;

function TSPSCQueue.Pop: T;
begin
  if not Dequeue(Result) then
    raise Exception.Create('IQueue.Pop: queue is empty');
end;

function TSPSCQueue.TryPeek(out aElement: T): Boolean;
begin
  aElement := Default(T);
  Result := False; // SPSC 不支持 Peek
end;

function TSPSCQueue.Peek: T;
begin
  raise Exception.Create('IQueue.Peek: not supported');
end;

procedure TSPSCQueue.Clear;
var v: T;
begin
  while Dequeue(v) do ;
end;

function TSPSCQueue.Count: SizeUInt;
begin
  Result := SizeUInt(Size);
end;


function TSPSCQueue.Capacity: Integer;
begin
  Result := FCapacity;
end;

end.

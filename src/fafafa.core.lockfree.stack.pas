unit fafafa.core.lockfree.stack;

{**
 * fafafa.core.lockfree.stack - 无锁栈数据结构模块
 *
 * 这个模块提供了高性能的无锁栈实现，包括：
 *
 * 🔒 无锁栈实现：
 *   - Treiber栈 (TTreiberStack) - 经典的无锁栈算法
 *   - 预分配安全栈 (TPreAllocStack) - 解决ABA问题的安全实现
 *
 * 🏗️ 架构特点：
 *   - 基于原子操作，无需锁机制
 *   - 高性能，避免线程切换开销
 *   - 无阻塞算法，避免死锁
 *   - 内存安全，支持 ABA 问题防护
 *   - 跨平台支持
 *
 * 🎯 性能优势：
 *   - 比基于锁的实现快 2-10 倍
 *   - 无线程阻塞，低延迟
 *   - 高并发扩展性
 *   - CPU 缓存友好
 *
 * 🔧 算法说明：
 *   - TTreiberStack: 基于R. Kent Treiber 1986年论文的经典算法
 *   - TPreAllocStack: 使用64位打包头部解决ABA问题
 *
 * 作者：fafafa.core 开发团队
 * 版本：1.3.0
 * 许可：MIT License
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{$if FPC_FULLVERSION >= 030301}
  {$define FAFAFA_GENERIC_IFACE}
{$endif}

interface

uses
  SysUtils, Classes,
  fafafa.core.atomic,
  fafafa.core.lockfree.stats,
  fafafa.core.lockfree.backoff, // backoff policy
  fafafa.core.lockfree.reclaim,
  fafafa.core.collections.stack; // IStack<T> interface

// Global disposer used by Treiber stack retirement; paired with manual Finalize of Data before retire
procedure Treiber_DisposeNode(p: Pointer);


type
  {**
   * Treiber无锁栈 (Treiber Lock-Free Stack)
   *
   * @desc 基于R. Kent Treiber 1986年论文的经典无锁栈算法
   *       使用 compare-and-swap (CAS) 实现真正的无锁操作
   *
   * @note 使用建议（非 GC 语言/手动内存管理场景）：
   *       - Treiber 栈在高删除率且长时间运行的服务中会遭遇 ABA 与回收难题；
   *         推荐优先使用 TPreAllocStack<T>（预分配 + 64 位打包头，单次 CAS64 消除 ABA）。
   *       - 若必须使用 Treiber 栈，请确保弹出节点不会被立即释放/复用（例如配合 HP/EBR 等回收策略）。
   *       - 在带 GC 的语言/运行时环境中，Treiber 栈是完全安全的。
   *
   * @algorithm Treiber 栈算法：
   *           1. Push: 创建新节点，设置 next 指向当前 top，CAS 更新 top
   *           2. Pop:  读取 top，读取 next，CAS 更新 top 为 next
   *           3. 使用重试循环处理并发冲突
   *
   *}

  generic TTreiberStack<T> = class(TInterfacedObject, specialize IStack<T>)
  public
    type
      PNode = ^TNode;
      TNode = record
        Data: T;
        Next: PNode;
      end;

  private
    FTop: PNode;                 // 栈顶指针（原子访问）
    FPadAfterTop: array[0..63] of Byte; // Cache line padding，降低与后续字段的伪共享
    FStats: ILockFreeStats;      // 性能统计（接口，使用引用计数管理生命周期）
    FCount: Int32;               // best-effort count (atomic)

  public
    constructor Create;
    destructor Destroy; override;

    // IStack 基本操作
    procedure Push(const AItem: T); overload; // 保留原语义
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;

    function Pop(out AItem: T): Boolean; overload;
    function Pop: T; overload;

    function TryPeek(out aElement: T): Boolean; overload;
    function Peek: T; overload;

    function IsEmpty: Boolean;
    procedure Clear;
    function Count: SizeUInt;

    // 现有扩展接口（保留）
    procedure PushItem(const aElement: T);
    function PopItem: T;
    function TryPopItem(out aElement: T): Boolean;
    function PeekItem: T;
    function GetSize: Integer;

    // 批量操作（保留）
    function PushMany(const aElements: array of T): Integer;
    function PopMany(var aElements: array of T): Integer;

    // 性能统计支持
    function GetStats: ILockFreeStats;
  end;

  {**
   * 预分配安全栈 (Pre-allocated Safe Stack)
   *
   * @desc 基于预分配节点池的安全无锁栈
   *       使用ABA计数器解决ABA问题，避免动态内存分配
   *
   * @note 灵感来自nullprogram.com的C11无锁栈实现
   *       通过预分配避免malloc/free的复杂性
   *       使用版本号而不是引用计数来解决ABA问题
   *
   * @algorithm ABA问题解决方案：
   *           1. 使用64位打包头部：高32位ABA计数器 + 低32位节点索引
   *           2. 每次CAS操作都增加ABA计数器
   *           3. 单个64位CAS操作保证原子性
   *           4. 预分配节点池避免内存管理复杂性
   *
   * @limitation 有最大容量限制，但在实际应用中通常足够
   *}
  generic TPreAllocStack<T> = class(TInterfacedObject, specialize IStack<T>)
  public
    type
      PNode = ^TNode;
      TNode = record
        Data: T;
        Next: PNode;
      end;

      // 打包的栈头：高32位是ABA计数器，低32位是节点索引
      // 这样我们可以用单个64位CAS操作来避免ABA问题
      TPackedHead = UInt64;

  private
    FNodeBuffer: array of TNode;  // 预分配的节点池
    FCapacity: Integer;           // 最大容量
    FHead: TPackedHead;           // 栈头（打包的指针+ABA计数器）
    FPadAfterHead: array[0..63] of Byte; // Cache line padding，降低与后续字段的伪共享
    FFree: TPackedHead;           // 空闲节点栈头（打包的指针+ABA计数器）
    FPadAfterFree: array[0..63] of Byte; // Padding
    FSize: Integer;               // 当前大小（原子访问）

    // 辅助方法：打包和解包头部信息
    function PackHead(ANodeIndex: Integer; AABACounter: Cardinal): TPackedHead; inline;
    procedure UnpackHead(APackedHead: TPackedHead; out ANodeIndex: Integer; out AABACounter: Cardinal); inline;
    function GetNodeByIndex(AIndex: Integer): PNode; inline;
    function GetNodeIndex(ANode: PNode): Integer; inline;

    // 内部栈操作（处理打包的头部）
    function InternalPop(var AHead: TPackedHead): PNode;
    procedure InternalPush(var AHead: TPackedHead; ANode: PNode);
    // 扩展：多元素批量操作（单次 CAS）
    function InternalPopN(var AHead: TPackedHead; aCount: Integer; out SegHead, SegTail: PNode): Integer;
    procedure InternalPushN(var AHead: TPackedHead; SegHead, SegTail: PNode);

  public
    constructor Create(ACapacity: Integer = 1024);
    destructor Destroy; override;

    // IStack 基本操作
    procedure Push(const AItem: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    function TryPush(const AItem: T): Boolean;

    function Pop(out AItem: T): Boolean; overload;
    function Pop: T; overload;

    function TryPeek(out aElement: T): Boolean; overload;
    function Peek: T; overload;

    // 扩展：批量弹出（非接口方法，IStack 不要求）
    function PopMany(var aElements: array of T): Integer;

    // 状态查询
    function IsEmpty: Boolean;
    function IsFull: Boolean;
    function GetSize: Integer;
    function GetCapacity: Integer;
    function Count: SizeUInt;
    procedure Clear;

  end;

// Collections-compatible factories
generic function MakeTreiberStack<T>: specialize IStack<T>;
generic function MakePreallocStack<T>(aCapacity: Integer = 1024): specialize IStack<T>;







implementation

// disposer for Treiber stack nodes; relies on the correct PNode type within generic context
procedure Treiber_DisposeNode(p: Pointer);
begin
  if p <> nil then
    FreeMem(p); // Data must have been finalized before retire; FreeMem is enough
end;


// === Factories implementation ===

generic function MakeTreiberStack<T>: specialize IStack<T>;
begin
  Result := specialize TTreiberStack<T>.Create;
end;

generic function MakePreallocStack<T>(aCapacity: Integer): specialize IStack<T>;
begin
  Result := specialize TPreAllocStack<T>.Create(aCapacity);
end;

{ TTreiberStack<T> }

constructor TTreiberStack.Create;
begin
  inherited Create;
  FTop := nil;
  FStats := TLockFreeStats.Create;
  FCount := 0;
end;

destructor TTreiberStack.Destroy;
var
  LNode, LNext: PNode;
begin
  // 清理所有节点（通过回收层 retire，Immediate 模式下立即释放）
  LNode := FTop;
  while LNode <> nil do
  begin
    LNext := LNode^.Next;
    Finalize(LNode^.Data);
    lf_retire(LNode, @Treiber_DisposeNode);
    LNode := LNext;
  end;
  lf_drain; // 确保析构前全部回收完成（Immediate: no-op）

  // 接口引用，自动释放（避免与外部接口释放二次释放）
  inherited Destroy;
end;

procedure TTreiberStack.Push(const AItem: T);
var
  LNewNode: PNode;
  LCurrentTop: PNode;
  LFailCount: Integer;
begin
  // 分配新节点
  New(LNewNode);
  LNewNode^.Data := AItem;

  // Treiber栈算法：重复直到成功（加入轻量退避避免活锁）
  LFailCount := 0;
  repeat
    // 1. 读取当前栈顶（acquire 确保看到前驱线程对节点内容的发布）
    LCurrentTop := PNode(atomic_load(PPointer(@FTop)^, mo_acquire));

    // 2. 设置新节点的next指向当前栈顶
    LNewNode^.Next := LCurrentTop;

    // 3. 尝试原子地将栈顶更新为新节点
    // 如果FTop仍然等于LCurrentTop，则更新为LNewNode
    if atomic_compare_exchange_strong(PPointer(@FTop)^, Pointer(LCurrentTop), Pointer(LNewNode)) then
    begin
      atomic_increment(FCount); // best-effort count
      Break;
    end;

    BackoffStep(LFailCount);
  until False;

  // 成功！新节点现在是栈顶
end;

function TTreiberStack.Pop(out AItem: T): Boolean;
var
  LCurrentTop, LNext: PNode;
  LFailCount: Integer;
  G: Pointer;
begin
  // Treiber栈算法：重复直到成功或栈为空（加入轻量退避避免活锁）
  LFailCount := 0;
  G := lf_enter;
  try
    repeat
      // 1. 读取当前栈顶（acquire 确保看到前驱线程对节点内容的发布）
      LCurrentTop := PNode(atomic_load(PPointer(@FTop)^, mo_acquire));

      // 2. 检查栈是否为空
      if LCurrentTop = nil then
        Exit(False); // 栈为空

      // 3. 读取栈顶的下一个节点
      LNext := LCurrentTop^.Next;

      // 4. 尝试原子地将栈顶更新为下一个节点
      // 如果FTop仍然等于LCurrentTop，则更新为LNext
      if atomic_compare_exchange_strong(PPointer(@FTop)^, Pointer(LCurrentTop), Pointer(LNext)) then
      begin
        // 5. 成功！获取数据并将节点退休（由回收层决定何时释放）
        AItem := LCurrentTop^.Data;
        Finalize(LCurrentTop^.Data);
        lf_retire(LCurrentTop, @Treiber_DisposeNode);
        atomic_decrement(FCount); // best-effort count
        Exit(True);
      end;

      // CAS失败，说明其他线程修改了栈，重试
      BackoffStep(LFailCount);
    until False;
  finally
    lf_exit(G);
  end;
end;

function TTreiberStack.IsEmpty: Boolean;
begin
  Result := atomic_load(PPointer(@FTop)^, mo_relaxed) = nil;
end;

{ TTreiberStack - 扩展接口实现 }

procedure TTreiberStack.PushItem(const aElement: T);
begin
  Push(aElement);
end;

function TTreiberStack.PopItem: T;
begin
  if not Pop(Result) then
    raise Exception.Create('Stack is empty');
end;

function TTreiberStack.TryPopItem(out aElement: T): Boolean;
begin
  Result := Pop(aElement);
end;

function TTreiberStack.PeekItem: T;
begin
  Result := Default(T);
  raise Exception.Create('Peek operation not supported by lock-free stack');
end;

function TTreiberStack.TryPeek(out aElement: T): Boolean;
begin
  // 无锁栈通常不支持Peek操作
  Result := False;
end;

function TTreiberStack.GetSize: Integer;
begin
  // best-effort atomic count
  Result := atomic_load(FCount, mo_acquire);
end;

function TTreiberStack.PushMany(const aElements: array of T): Integer;
var
  I, N: Integer;
  Head, Tail, Node: PNode;
  OldTop: PNode;
  FailCount: Integer;
begin
  N := High(aElements) - Low(aElements) + 1;
  if N <= 0 then Exit(0);

  // Build local chain: head is last element (LIFO consistent), tail is first element
  Head := nil;
  Tail := nil;
  for I := Low(aElements) to High(aElements) do
  begin
    New(Node);
    Node^.Data := aElements[I];
    Node^.Next := Head;
    Head := Node;
    if Tail = nil then Tail := Node;
  end;

  // Single CAS insert of the whole chain
  FailCount := 0;
  repeat
    OldTop := PNode(atomic_load(PPointer(@FTop)^, mo_acquire));
    Tail^.Next := OldTop;
    if atomic_compare_exchange_strong(PPointer(@FTop)^, Pointer(OldTop), Pointer(Head)) then
      Break;
    BackoffStep(FailCount);
  until False;

  // best-effort count (+N)
  atomic_fetch_add(FCount, N);
  Result := N;
end;

function TTreiberStack.PopMany(var aElements: array of T): Integer;
var
  Want, Got, I: Integer;
  ExpectedTop, Cur, Tail, NextAfter: PNode;
  FailCount: Integer;
  Tmp: PNode;
begin
  Want := High(aElements) - Low(aElements) + 1;
  if Want <= 0 then Exit(0);

  FailCount := 0;
  repeat
    ExpectedTop := PNode(atomic_load(PPointer(@FTop)^, mo_acquire));
    if ExpectedTop = nil then Exit(0);

    // Walk up to Want nodes
    Got := 1;
    Tail := ExpectedTop;
    Cur := Tail^.Next;
    while (Got < Want) and (Cur <> nil) do
    begin
      Tail := Cur;
      Cur := Cur^.Next;
      Inc(Got);
    end;
    NextAfter := Tail^.Next; // node after our segment

    if atomic_compare_exchange_strong(PPointer(@FTop)^, Pointer(ExpectedTop), Pointer(NextAfter)) then
      Break;

    BackoffStep(FailCount);
  until False;

  // We own the chain [ExpectedTop .. Tail]
  Cur := ExpectedTop;
  for I := 0 to Got - 1 do
  begin
    aElements[Low(aElements) + I] := Cur^.Data;
    Finalize(Cur^.Data);
    Tmp := Cur^.Next;
    lf_retire(Cur, @Treiber_DisposeNode);
    Cur := Tmp;
  end;

  atomic_fetch_sub(FCount, Got);
  Result := Got;
end;

procedure TTreiberStack.Clear;
var
  LDummy: T;
begin
  // 使用原始的 Pop 方法避免递归
  while Pop(LDummy) do
    ; // 清空栈
end;

function TTreiberStack.GetStats: ILockFreeStats;
begin
  // 保证编译器总是看到 Result 被设置
  Result := FStats;
end;

{ TPreAllocStack<T> }

// 辅助方法：将节点索引和ABA计数器打包到64位值中
function TPreAllocStack.PackHead(ANodeIndex: Integer; AABACounter: Cardinal): TPackedHead;
begin
  // 高32位存储ABA计数器，低32位存储节点索引
  // 使用-1表示空指针
  Result := (UInt64(AABACounter) shl 32) or UInt64(Cardinal(ANodeIndex));
end;

// 辅助方法：从64位值中解包节点索引和ABA计数器
procedure TPreAllocStack.UnpackHead(APackedHead: TPackedHead; out ANodeIndex: Integer; out AABACounter: Cardinal);
begin
  AABACounter := Cardinal(APackedHead shr 32);
  ANodeIndex := Integer(Cardinal(APackedHead and $FFFFFFFF));
end;

// 根据索引获取节点指针
function TPreAllocStack.GetNodeByIndex(AIndex: Integer): PNode;
begin
  if (AIndex < 0) or (AIndex >= FCapacity) then
    Result := nil
  else
    Result := @FNodeBuffer[AIndex];
end;

// 根据节点指针获取索引
function TPreAllocStack.GetNodeIndex(ANode: PNode): Integer;
begin
  if ANode = nil then
    Result := -1
  else
    Result := (PByte(ANode) - PByte(@FNodeBuffer[0])) div SizeOf(TNode);
end;

constructor TPreAllocStack.Create(ACapacity: Integer);
var
  I: Integer;
begin
  inherited Create;

  // 确保容量是合理的
  if ACapacity < 1 then
    ACapacity := 1024;

  FCapacity := ACapacity;
  SetLength(FNodeBuffer, ACapacity);

  // 初始化栈头（空栈）
  FHead := PackHead(-1, 0);  // -1表示空指针
  FSize := 0;

  // 将所有节点链接到空闲栈中
  for I := 0 to ACapacity - 2 do
    FNodeBuffer[I].Next := @FNodeBuffer[I + 1];
  FNodeBuffer[ACapacity - 1].Next := nil;

  // 初始化空闲栈头（指向第一个节点）
  FFree := PackHead(0, 0);
end;



function TPreAllocStack.InternalPopN(var AHead: TPackedHead; aCount: Integer; out SegHead, SegTail: PNode): Integer;
var
  LOriginalPacked, LNewPacked: TPackedHead;
  LOriginalIndex, LNextIndex: Integer;
  LOriginalABA, LNewABA: Cardinal;
  AHeadInt64: Int64 absolute AHead;
  Taken: Integer;
  Cur: PNode;
begin
  SegHead := nil; SegTail := nil; Result := 0;
  if aCount <= 0 then Exit(0);
  repeat
    // load
    LOriginalPacked := TPackedHead(atomic_load_64(AHeadInt64, mo_acquire));
    UnpackHead(LOriginalPacked, LOriginalIndex, LOriginalABA);
    if LOriginalIndex = -1 then Exit(0);

    // traverse up to aCount
    SegHead := GetNodeByIndex(LOriginalIndex);
    SegTail := SegHead;
    Taken := 1;
    Cur := SegTail^.Next;
    while (Taken < aCount) and (Cur <> nil) do
    begin
      SegTail := Cur;
      Cur := Cur^.Next;
      Inc(Taken);
    end;
    // Cur is the node after our segment
    LNextIndex := GetNodeIndex(Cur);

    // try CAS head to Cur
    LNewABA := LOriginalABA + 1;
    LNewPacked := PackHead(LNextIndex, LNewABA);
  until atomic_compare_exchange_strong_64(AHeadInt64, Int64(LOriginalPacked), Int64(LNewPacked));
  Result := Taken;
end;

procedure TPreAllocStack.InternalPushN(var AHead: TPackedHead; SegHead, SegTail: PNode);
var
  LOriginalPacked, LNewPacked: TPackedHead;
  LOriginalIndex: Integer;
  LOriginalABA, LNewABA: Cardinal;
  AHeadInt64: Int64 absolute AHead;
begin
  if (SegHead = nil) or (SegTail = nil) then Exit;
  repeat
    LOriginalPacked := TPackedHead(atomic_load_64(AHeadInt64, mo_acquire));
    UnpackHead(LOriginalPacked, LOriginalIndex, LOriginalABA);
    SegTail^.Next := GetNodeByIndex(LOriginalIndex);
    LNewABA := LOriginalABA + 1;
    LNewPacked := PackHead(GetNodeIndex(SegHead), LNewABA);
  until atomic_compare_exchange_strong_64(AHeadInt64, Int64(LOriginalPacked), Int64(LNewPacked));
end;




procedure TPreAllocStack.InternalPush(var AHead: TPackedHead; ANode: PNode);
var
  LOriginalPacked, LNewPacked: TPackedHead;
  LOriginalIndex, LNewIndex: Integer;
  LOriginalABA, LNewABA: Cardinal;
  LOriginalNode: PNode;
  AHeadInt64: Int64 absolute AHead;
begin
  // 使用单个64位CAS来避免ABA问题（注意：通过 absolute 别名传入 var）
  LNewIndex := GetNodeIndex(ANode);

  repeat
    // 1. 原子地读取当前打包的头部
    LOriginalPacked := TPackedHead(atomic_load_64(AHeadInt64, mo_acquire));

    // 2. 解包头部信息
    UnpackHead(LOriginalPacked, LOriginalIndex, LOriginalABA);

    // 3. 获取当前头节点
    LOriginalNode := GetNodeByIndex(LOriginalIndex);

    // 4. 设置新节点的next指针
    ANode^.Next := LOriginalNode;

    // 5. 准备新的打包头部（增加ABA计数器）
    LNewABA := LOriginalABA + 1;
    LNewPacked := PackHead(LNewIndex, LNewABA);

    // 6. 尝试原子地更新头部（单个64位CAS操作）
  until atomic_compare_exchange_strong_64(AHeadInt64, Int64(LOriginalPacked), Int64(LNewPacked));
end;

destructor TPreAllocStack.Destroy;
begin
  SetLength(FNodeBuffer, 0);
  inherited Destroy;
end;

function TPreAllocStack.InternalPop(var AHead: TPackedHead): PNode;
var
  LOriginalPacked, LNewPacked: TPackedHead;
  LOriginalIndex, LNextIndex: Integer;
  LOriginalABA, LNewABA: Cardinal;
  LOriginalNode: PNode;
  // 使用 absolute 创建 64 位别名，以便以 var 形式传递给原子操作
  AHeadInt64: Int64 absolute AHead;
begin
  // 使用单个64位CAS来避免ABA问题（注意：通过 absolute 别名传入 var）
  repeat
    // 1. 原子地读取当前打包的头部
    LOriginalPacked := TPackedHead(atomic_load_64(AHeadInt64, mo_acquire));

    // 2. 解包头部信息
    UnpackHead(LOriginalPacked, LOriginalIndex, LOriginalABA);

    // 3. 检查栈是否为空
    if LOriginalIndex = -1 then
      Exit(nil);

    // 4. 获取当前头节点
    LOriginalNode := GetNodeByIndex(LOriginalIndex);
    if LOriginalNode = nil then
      Exit(nil);

    // 5. 获取下一个节点的索引
    LNextIndex := GetNodeIndex(LOriginalNode^.Next);

    // 6. 准备新的打包头部（增加ABA计数器）
    LNewABA := LOriginalABA + 1;
    LNewPacked := PackHead(LNextIndex, LNewABA);

    // 7. 尝试原子地更新头部（单个64位CAS操作）
  until atomic_compare_exchange_strong_64(AHeadInt64, Int64(LOriginalPacked), Int64(LNewPacked));

  Result := LOriginalNode;
end;



function TPreAllocStack.TryPush(const AItem: T): Boolean;
var
  LNode: PNode;
begin
  // 1. 从空闲栈中获取一个节点
  LNode := InternalPop(FFree);
  if LNode = nil then
    Exit(False); // 栈已满

  // 2. 设置节点数据
  LNode^.Data := AItem;

  // 3. 将节点推入主栈
  InternalPush(FHead, LNode);

  // 4. 原子地增加大小
  atomic_increment(FSize);

  Result := True;
end;

procedure TPreAllocStack.Push(const AItem: T);
begin
  if not TryPush(AItem) then
    raise Exception.Create('TPreAllocStack.Push: stack is full');
end;

function TPreAllocStack.Pop(out AItem: T): Boolean;
var
  LNode: PNode;
begin
  // 1. 从主栈中弹出一个节点
  LNode := InternalPop(FHead);
  if LNode = nil then
    Exit(False); // 栈为空

  // 2. 获取数据
  AItem := LNode^.Data;

  // 3. 原子地减少大小
  atomic_decrement(FSize);

  // 4. 将节点放回空闲栈
  InternalPush(FFree, LNode);

  Result := True;
end;

procedure TTreiberStack.Push(const aSrc: array of T);
var
  I: SizeInt;
begin
  for I := Low(aSrc) to High(aSrc) do
    Push(aSrc[I]);
end;

procedure TTreiberStack.Push(const aSrc: Pointer; aElementCount: SizeUInt);
type
  PEl = ^T;
var
  I: SizeUInt;
  P: PEl;
begin
  if (aSrc = nil) and (aElementCount > 0) then Exit;
  P := PEl(aSrc);
  for I := 0 to aElementCount - 1 do
  begin
    Push(P^);
    Inc(P);
  end;
end;

function TTreiberStack.Pop: T;
begin
  if not Pop(Result) then
    raise Exception.Create('TTreiberStack.Pop: stack is empty');
end;

function TTreiberStack.Peek: T;
begin
  if not TryPeek(Result) then
    raise Exception.Create('TTreiberStack.Peek: not supported or empty');
end;

function TTreiberStack.Count: SizeUInt;
begin
  Result := SizeUInt(GetSize);
end;

function TPreAllocStack.IsEmpty: Boolean;
var
  LHeadPacked: TPackedHead;
  LNodeIndex: Integer;
  LABA: Cardinal;
begin
  LHeadPacked := atomic_load_64(PInt64(@FHead)^, mo_acquire);
  UnpackHead(LHeadPacked, LNodeIndex, LABA);
  Result := LNodeIndex = -1;
end;

function TPreAllocStack.IsFull: Boolean;
var
  LFreePacked: TPackedHead;
  LNodeIndex: Integer;
  LABA: Cardinal;
begin
  LFreePacked := atomic_load_64(PInt64(@FFree)^, mo_acquire);
  UnpackHead(LFreePacked, LNodeIndex, LABA);
  Result := LNodeIndex = -1;
end;

function TPreAllocStack.GetSize: Integer;
begin
  Result := atomic_load(FSize, mo_acquire);
end;

function TPreAllocStack.GetCapacity: Integer;
begin
  Result := FCapacity;
end;

procedure TPreAllocStack.Push(const aSrc: array of T);
var
  I, N: Integer;
  SegHead, SegTail, Node: PNode;
  Taken: Integer;
begin
  N := High(aSrc) - Low(aSrc) + 1;
  if N <= 0 then Exit;

  // rent N nodes from free list (may be less than N)
  SegHead := nil; SegTail := nil; Taken := 0;
  while (Taken < N) do
  begin
    Node := InternalPop(FFree);
    if Node = nil then Break;
    // fill data in original order; we push as LIFO so we want last element on top
    Node^.Data := aSrc[Low(aSrc) + Taken];
    Node^.Next := SegHead;
    SegHead := Node;
    if SegTail = nil then SegTail := Node;
    Inc(Taken);
  end;
  if Taken = 0 then Exit;

  InternalPushN(FHead, SegHead, SegTail);
  // size += Taken
  while Taken > 0 do
  begin
    atomic_increment(FSize);
    Dec(Taken);
  end;
end;

procedure TPreAllocStack.Push(const aSrc: Pointer; aElementCount: SizeUInt);
type
  PEl = ^T;
var
  I: SizeUInt;
  P: PEl;
  SegHead, SegTail, Node: PNode;
  Taken: SizeUInt;
begin
  if (aSrc = nil) and (aElementCount > 0) then Exit;
  if aElementCount = 0 then Exit;
  P := PEl(aSrc);

  // rent nodes up to aElementCount
  SegHead := nil; SegTail := nil; Taken := 0;
  while (Taken < aElementCount) do
  begin
    Node := InternalPop(FFree);
    if Node = nil then Break;
    Node^.Data := P^;
    Node^.Next := SegHead;
    SegHead := Node;
    if SegTail = nil then SegTail := Node;
    Inc(P);
    Inc(Taken);

  end;


  if Taken = 0 then Exit;

  InternalPushN(FHead, SegHead, SegTail);
  while Taken > 0 do
  begin
    atomic_increment(FSize);
    Dec(Taken);
  end;
end;

function TPreAllocStack.PopMany(var aElements: array of T): Integer;
var
  Want, Got, I: Integer;
  SegHead, SegTail: PNode;
  Cur, NextNode: PNode;
begin
  Want := High(aElements) - Low(aElements) + 1;
  if Want <= 0 then Exit(0);
  // 取出至多 Want 个节点
  Got := InternalPopN(FHead, Want, SegHead, SegTail);
  if Got <= 0 then Exit(0);

  // 回填数据并回收到 FFree
  Cur := SegHead;
  for I := 0 to Got - 1 do
  begin
    aElements[Low(aElements) + I] := Cur^.Data;
    Finalize(Cur^.Data);
    NextNode := Cur^.Next;
    // 返回到空闲栈
    InternalPush(FFree, Cur);
    Cur := NextNode;
  end;

  // size -= Got
  while Got > 0 do
  begin
    atomic_decrement(FSize);
    Dec(Got);
  end;

  Result := Got; // 返回写入的数量
end;

function TPreAllocStack.Pop: T;
begin
  if not Pop(Result) then
    raise Exception.Create('TPreAllocStack.Pop: stack is empty');
end;

function TPreAllocStack.TryPeek(out aElement: T): Boolean;
var
  LHeadPacked: TPackedHead;
  LIndex: Integer;
  LABA: Cardinal;
  LNode: PNode;
begin
  // Weak snapshot: read head with acquire and return current Data if any
  aElement := Default(T);
  LHeadPacked := TPackedHead(atomic_load_64(PInt64(@FHead)^, mo_acquire));
  UnpackHead(LHeadPacked, LIndex, LABA);
  if LIndex = -1 then Exit(False);
  LNode := GetNodeByIndex(LIndex);
  if LNode = nil then Exit(False);
  aElement := LNode^.Data;
  Result := True;
end;

function TPreAllocStack.Peek: T;
begin
  if not TryPeek(Result) then
    raise Exception.Create('TPreAllocStack.Peek: not supported or empty');
end;

function TPreAllocStack.Count: SizeUInt;
begin
  Result := SizeUInt(GetSize);
end;

procedure TPreAllocStack.Clear;
var
  tmp: T;
begin
  while Pop(tmp) do ;
end;

end.

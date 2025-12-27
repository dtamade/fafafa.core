unit fafafa.core.time.timer.backend.heap;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{*
  fafafa.core.time.timer.backend.heap - 二叉堆后端实现

  基于二叉最小堆的定时器队列实现。
  特点:
  - 入队/出队: O(log n)
  - 查看堆顶: O(1)
  - 按 HeapIndex 移除: O(log n)
  - 适用于中小规模定时器（< 10000 个）

  实现细节:
  - 使用动态数组存储堆
  - 每个 Entry 的 HeapIndex 字段用于快速定位
  - 堆按 Deadline 升序排列（最早的在堆顶）
*}

interface

uses
  SysUtils,
  fafafa.core.time.instant,
  fafafa.core.time.timer.base,     // ✅ Phase 2: 共享类型 (PTimerEntry)
  fafafa.core.time.timer.backend;

{** 创建二叉堆后端 *}
function CreateBinaryHeapBackendImpl: ITimerQueueBackend;

implementation

type
  // ✅ Phase 2: TTimerEntry 已移至 fafafa.core.time.timer.base
  // 不再需要 TTimerEntryCompat 兼容层

  { TBinaryHeapBackend }
  TBinaryHeapBackend = class(TInterfacedObject, ITimerQueueBackend)
  private
    FHeap: array of PTimerEntry;
    FCount: Integer;
    FCapacity: Integer;

    procedure EnsureCapacity;
    procedure HeapSwap(A, B: Integer);
    procedure HeapifyUp(Index: Integer);
    procedure HeapifyDown(Index: Integer);
    function CompareDeadline(A, B: PTimerEntry): Integer; inline;
  public
    constructor Create;
    destructor Destroy; override;

    // ITimerQueueBackend
    procedure Enqueue(E: PTimerEntryOpaque);
    function Dequeue: PTimerEntryOpaque;
    function PopDue(const Now: TInstant; MaxCount: Integer; out DueEntries: array of PTimerEntryOpaque): Integer;
    function Peek: PTimerEntryOpaque;
    function PeekNextDeadline(out Dl: TInstant): Boolean;
    procedure Remove(E: PTimerEntryOpaque);
    procedure UpdateDeadline(E: PTimerEntryOpaque);
    function Count: Integer;
    function IsEmpty: Boolean;
    procedure Clear;
    function GetName: string;
  end;

{ TBinaryHeapBackend }

constructor TBinaryHeapBackend.Create;
begin
  inherited Create;
  FCount := 0;
  FCapacity := 0;
  SetLength(FHeap, 0);
end;

destructor TBinaryHeapBackend.Destroy;
begin
  // 不释放 Entry，只清空数组
  Clear;
  SetLength(FHeap, 0);
  inherited Destroy;
end;

procedure TBinaryHeapBackend.EnsureCapacity;
var
  NewCap: Integer;
begin
  if FCount >= FCapacity then
  begin
    if FCapacity = 0 then
      NewCap := 16
    else
      NewCap := FCapacity * 2;
    SetLength(FHeap, NewCap);
    FCapacity := NewCap;
  end;
end;

procedure TBinaryHeapBackend.HeapSwap(A, B: Integer);
var
  Tmp: PTimerEntry;
begin
  if A = B then Exit;
  Tmp := FHeap[A];
  FHeap[A] := FHeap[B];
  FHeap[B] := Tmp;
  // 更新 HeapIndex
  if FHeap[A] <> nil then
    FHeap[A]^.HeapIndex := A;
  if FHeap[B] <> nil then
    FHeap[B]^.HeapIndex := B;
end;

function TBinaryHeapBackend.CompareDeadline(A, B: PTimerEntry): Integer;
begin
  // 比较 Deadline（TInstant 内部是 FNanos: Int64）
  if A^.Deadline < B^.Deadline then
    Result := -1
  else if A^.Deadline > B^.Deadline then
    Result := 1
  else
    Result := 0;
end;

procedure TBinaryHeapBackend.HeapifyUp(Index: Integer);
var
  I, Parent: Integer;
begin
  I := Index;
  while I > 0 do
  begin
    Parent := (I - 1) shr 1;
    if (FHeap[I] = nil) or (FHeap[Parent] = nil) then
      Break;
    if CompareDeadline(FHeap[I], FHeap[Parent]) >= 0 then
      Break;
    HeapSwap(I, Parent);
    I := Parent;
  end;
end;

procedure TBinaryHeapBackend.HeapifyDown(Index: Integer);
var
  I, Left, Right, Smallest: Integer;
begin
  I := Index;
  while True do
  begin
    Left := (I shl 1) + 1;
    Right := Left + 1;
    Smallest := I;

    if (Left < FCount) and (FHeap[Left] <> nil) and (FHeap[Smallest] <> nil) then
    begin
      if CompareDeadline(FHeap[Left], FHeap[Smallest]) < 0 then
        Smallest := Left;
    end;

    if (Right < FCount) and (FHeap[Right] <> nil) and (FHeap[Smallest] <> nil) then
    begin
      if CompareDeadline(FHeap[Right], FHeap[Smallest]) < 0 then
        Smallest := Right;
    end;

    if Smallest = I then
      Break;

    HeapSwap(I, Smallest);
    I := Smallest;
  end;
end;

procedure TBinaryHeapBackend.Enqueue(E: PTimerEntryOpaque);
var
  Entry: PTimerEntry;
begin
  Entry := PTimerEntry(E);
  if Entry = nil then Exit;

  EnsureCapacity;
  Entry^.HeapIndex := FCount;
  Entry^.InHeap := True;
  FHeap[FCount] := Entry;
  Inc(FCount);
  HeapifyUp(Entry^.HeapIndex);
end;

function TBinaryHeapBackend.Dequeue: PTimerEntryOpaque;
begin
  if FCount = 0 then
    Exit(nil);

  Result := FHeap[0];
  Dec(FCount);

  if FCount > 0 then
  begin
    FHeap[0] := FHeap[FCount];
    if FHeap[0] <> nil then
      FHeap[0]^.HeapIndex := 0;
    FHeap[FCount] := nil;
    HeapifyDown(0);
  end
  else
    FHeap[0] := nil;

  if Result <> nil then
  begin
    PTimerEntry(Result)^.InHeap := False;
    PTimerEntry(Result)^.HeapIndex := -1;
  end;
end;

function TBinaryHeapBackend.PopDue(const Now: TInstant; MaxCount: Integer; out DueEntries: array of PTimerEntryOpaque): Integer;
var
  Entry: PTimerEntry;
  ArrayLen: Integer;
begin
  Result := 0;
  ArrayLen := Length(DueEntries);
  if ArrayLen = 0 then Exit;

  while (FCount > 0) and ((MaxCount = 0) or (Result < MaxCount)) and (Result < ArrayLen) do
  begin
    Entry := FHeap[0];
    if Entry = nil then Break;

    // 检查是否已到期（Deadline <= Now）
    if Entry^.Deadline > Now then
      Break;  // 堆顶未到期，后面的更不会到期

    // 出队
    DueEntries[Result] := Dequeue;
    Inc(Result);
  end;
end;

function TBinaryHeapBackend.Peek: PTimerEntryOpaque;
begin
  if FCount = 0 then
    Result := nil
  else
    Result := FHeap[0];
end;

function TBinaryHeapBackend.PeekNextDeadline(out Dl: TInstant): Boolean;
begin
  if FCount = 0 then
  begin
    Dl := TInstant.Zero;
    Result := False;
  end
  else
  begin
    Dl := FHeap[0]^.Deadline;
    Result := True;
  end;
end;

procedure TBinaryHeapBackend.Remove(E: PTimerEntryOpaque);
var
  Entry: PTimerEntry;
  Idx, LastIdx: Integer;
begin
  Entry := PTimerEntry(E);
  if Entry = nil then Exit;
  if not Entry^.InHeap then Exit;

  Idx := Entry^.HeapIndex;
  if (Idx < 0) or (Idx >= FCount) then Exit;

  LastIdx := FCount - 1;
  if Idx <> LastIdx then
  begin
    HeapSwap(Idx, LastIdx);
  end;

  Dec(FCount);
  FHeap[LastIdx] := nil;

  Entry^.InHeap := False;
  Entry^.HeapIndex := -1;

  if Idx < FCount then
  begin
    HeapifyDown(Idx);
    HeapifyUp(Idx);
  end;
end;

procedure TBinaryHeapBackend.UpdateDeadline(E: PTimerEntryOpaque);
var
  Entry: PTimerEntry;
  Idx: Integer;
begin
  Entry := PTimerEntry(E);
  if Entry = nil then Exit;
  if not Entry^.InHeap then Exit;

  Idx := Entry^.HeapIndex;
  if (Idx < 0) or (Idx >= FCount) then Exit;

  // Deadline 已经被调用者修改，这里只需要重新排序
  HeapifyDown(Idx);
  HeapifyUp(Idx);
end;

function TBinaryHeapBackend.Count: Integer;
begin
  Result := FCount;
end;

function TBinaryHeapBackend.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure TBinaryHeapBackend.Clear;
var
  I: Integer;
  Entry: PTimerEntry;
begin
  for I := 0 to FCount - 1 do
  begin
    Entry := FHeap[I];
    if Entry <> nil then
    begin
      Entry^.InHeap := False;
      Entry^.HeapIndex := -1;
    end;
    FHeap[I] := nil;
  end;
  FCount := 0;
end;

function TBinaryHeapBackend.GetName: string;
begin
  Result := 'BinaryHeap';
end;

{ Factory }

function CreateBinaryHeapBackendImpl: ITimerQueueBackend;
begin
  Result := TBinaryHeapBackend.Create;
end;

initialization
  RegisterBinaryHeapFactory(@CreateBinaryHeapBackendImpl);

end.

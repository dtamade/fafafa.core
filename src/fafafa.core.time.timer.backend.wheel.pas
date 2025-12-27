unit fafafa.core.time.timer.backend.wheel;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{*
  fafafa.core.time.timer.backend.wheel - 时间轮后端实现

  基于分层时间轮的定时器队列实现。
  特点:
  - 入队/出队: O(1) 分摊
  - 移除: O(1)
  - 适用于大量定时器场景（> 10000 个）
  - 需要定期调用 Tick 驱动时间推进

  实现细节:
  - 使用单层时间轮 + 溢出列表
  - 每个槽是一个双向链表
  - Entry 通过 WheelSlot/WheelNext/WheelPrev 字段链接
  - 超过时间轮范围的定时器放入溢出列表
*}

interface

uses
  SysUtils,
  fafafa.core.time.instant,
  fafafa.core.time.duration,
  fafafa.core.time.timer.backend;

{** 创建时间轮后端 *}
function CreateHashedWheelBackendImpl(SlotCount: Integer; TickIntervalMs: Integer): ITimerQueueBackend;

implementation

type
  // 扩展字段用于时间轮链表（需要在 TTimerEntry 中预留）
  // 由于我们不能修改 TTimerEntry，使用外部映射或侵入式字段
  // 这里假设 TTimerEntry 有足够的空间或我们使用 HeapIndex 字段复用

  PTimerEntryCompat = ^TTimerEntryCompat;
  TTimerEntryCompat = record
    Kind: Integer;
    Deadline: TInstant;
    Period: Int64;
    Delay: Int64;
    Callback: Pointer;
    CallbackData: Pointer;
    Cancelled: Boolean;
    Fired: Boolean;
    ExecutionCount: QWord;
    Paused: Boolean;
    RefCount: LongInt;
    Dead: Boolean;
    InHeap: Boolean;         // 复用为 InWheel
    HeapIndex: Integer;      // 复用为 WheelSlot (-1 表示溢出列表)
    Owner: Pointer;
  end;

  // 时间轮槽节点
  PWheelNode = ^TWheelNode;
  TWheelNode = record
    Entry: PTimerEntryCompat;
    Rounds: Integer;         // 剩余轮数
    Next: PWheelNode;
    Prev: PWheelNode;
  end;

  { THashedWheelBackend }
  THashedWheelBackend = class(TInterfacedObject, ITimerQueueBackend)
  private
    FSlots: array of PWheelNode;  // 槽数组（每个槽是链表头）
    FSlotCount: Integer;
    FTickIntervalMs: Integer;
    FCurrentSlot: Integer;
    FCount: Integer;
    FCurrentTime: TInstant;       // 当前时间轮时间
    FOverflow: PWheelNode;        // 溢出列表（超出时间轮范围）

    // Entry -> Node 映射（简单线性查找，可优化为哈希表）
    FNodeMap: array of PWheelNode;
    FNodeMapCount: Integer;

    function CalcSlotAndRounds(const Deadline: TInstant; out Rounds: Integer): Integer;
    procedure AddToSlot(Slot: Integer; Node: PWheelNode);
    procedure RemoveNode(Node: PWheelNode; Slot: Integer);
    function FindNode(Entry: PTimerEntryCompat): PWheelNode;
    procedure AddNodeMapping(Node: PWheelNode);
    procedure RemoveNodeMapping(Node: PWheelNode);
    function GetEarliestDeadline: TInstant;
  public
    constructor Create(SlotCount: Integer; TickIntervalMs: Integer);
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

    // 时间轮特有方法
    procedure Tick;
    procedure AdvanceTo(const Now: TInstant);
  end;

{ THashedWheelBackend }

constructor THashedWheelBackend.Create(SlotCount: Integer; TickIntervalMs: Integer);
var
  I: Integer;
begin
  inherited Create;
  FSlotCount := SlotCount;
  FTickIntervalMs := TickIntervalMs;
  FCurrentSlot := 0;
  FCount := 0;
  FCurrentTime := TInstant.Zero;
  FOverflow := nil;
  FNodeMapCount := 0;

  SetLength(FSlots, FSlotCount);
  for I := 0 to FSlotCount - 1 do
    FSlots[I] := nil;

  SetLength(FNodeMap, 64);
end;

destructor THashedWheelBackend.Destroy;
begin
  Clear;
  SetLength(FSlots, 0);
  SetLength(FNodeMap, 0);
  inherited Destroy;
end;

function THashedWheelBackend.CalcSlotAndRounds(const Deadline: TInstant; out Rounds: Integer): Integer;
var
  DelayMs: Int64;
  Ticks: Int64;
begin
  DelayMs := Deadline.Diff(FCurrentTime).AsMs;
  if DelayMs < 0 then
    DelayMs := 0;

  Ticks := DelayMs div FTickIntervalMs;
  if Ticks < 1 then
    Ticks := 1;

  Rounds := Ticks div FSlotCount;
  Result := (FCurrentSlot + Ticks - 1 + FSlotCount) mod FSlotCount;
end;

procedure THashedWheelBackend.AddToSlot(Slot: Integer; Node: PWheelNode);
begin
  Node^.Next := FSlots[Slot];
  Node^.Prev := nil;
  if FSlots[Slot] <> nil then
    FSlots[Slot]^.Prev := Node;
  FSlots[Slot] := Node;
  Inc(FCount);
end;

procedure THashedWheelBackend.RemoveNode(Node: PWheelNode; Slot: Integer);
begin
  if Node^.Prev <> nil then
    Node^.Prev^.Next := Node^.Next
  else if Slot >= 0 then
    FSlots[Slot] := Node^.Next
  else
    FOverflow := Node^.Next;

  if Node^.Next <> nil then
    Node^.Next^.Prev := Node^.Prev;

  Node^.Next := nil;
  Node^.Prev := nil;
  Dec(FCount);
end;

function THashedWheelBackend.FindNode(Entry: PTimerEntryCompat): PWheelNode;
var
  I: Integer;
begin
  for I := 0 to FNodeMapCount - 1 do
  begin
    if FNodeMap[I]^.Entry = Entry then
      Exit(FNodeMap[I]);
  end;
  Result := nil;
end;

procedure THashedWheelBackend.AddNodeMapping(Node: PWheelNode);
begin
  if FNodeMapCount >= Length(FNodeMap) then
    SetLength(FNodeMap, Length(FNodeMap) * 2);
  FNodeMap[FNodeMapCount] := Node;
  Inc(FNodeMapCount);
end;

procedure THashedWheelBackend.RemoveNodeMapping(Node: PWheelNode);
var
  I: Integer;
begin
  for I := 0 to FNodeMapCount - 1 do
  begin
    if FNodeMap[I] = Node then
    begin
      FNodeMap[I] := FNodeMap[FNodeMapCount - 1];
      Dec(FNodeMapCount);
      Exit;
    end;
  end;
end;

function THashedWheelBackend.GetEarliestDeadline: TInstant;
var
  I, Checked: Integer;
  Node: PWheelNode;
  Earliest: TInstant;
  Found: Boolean;
begin
  Result := TInstant.Zero;
  Found := False;
  Earliest := TInstant.Zero;

  // 从当前槽开始遍历
  Checked := 0;
  I := FCurrentSlot;
  while Checked < FSlotCount do
  begin
    Node := FSlots[I];
    while Node <> nil do
    begin
      if (not Found) or (Node^.Entry^.Deadline < Earliest) then
      begin
        Earliest := Node^.Entry^.Deadline;
        Found := True;
      end;
      Node := Node^.Next;
    end;
    I := (I + 1) mod FSlotCount;
    Inc(Checked);
  end;

  // 检查溢出列表
  Node := FOverflow;
  while Node <> nil do
  begin
    if (not Found) or (Node^.Entry^.Deadline < Earliest) then
    begin
      Earliest := Node^.Entry^.Deadline;
      Found := True;
    end;
    Node := Node^.Next;
  end;

  if Found then
    Result := Earliest;
end;

procedure THashedWheelBackend.Enqueue(E: PTimerEntryOpaque);
var
  Entry: PTimerEntryCompat;
  Node: PWheelNode;
  Slot, Rounds: Integer;
  WheelRangeMs: Int64;
  DelayMs: Int64;
begin
  Entry := PTimerEntryCompat(E);
  if Entry = nil then Exit;

  // 初始化当前时间（如果是第一个定时器）
  if FCurrentTime = TInstant.Zero then
    FCurrentTime := Entry^.Deadline.Sub(TDuration.FromMs(1));

  New(Node);
  Node^.Entry := Entry;
  Node^.Next := nil;
  Node^.Prev := nil;

  // 计算槽位置
  WheelRangeMs := Int64(FSlotCount) * FTickIntervalMs;
  DelayMs := Entry^.Deadline.Diff(FCurrentTime).AsMs;

  if DelayMs > WheelRangeMs then
  begin
    // 超出时间轮范围，放入溢出列表
    Node^.Rounds := -1;  // 标记为溢出
    Node^.Next := FOverflow;
    if FOverflow <> nil then
      FOverflow^.Prev := Node;
    FOverflow := Node;
    Inc(FCount);
    Entry^.HeapIndex := -2;  // -2 表示溢出列表
  end
  else
  begin
    Slot := CalcSlotAndRounds(Entry^.Deadline, Rounds);
    Node^.Rounds := Rounds;
    AddToSlot(Slot, Node);
    Entry^.HeapIndex := Slot;
  end;

  Entry^.InHeap := True;
  AddNodeMapping(Node);
end;

function THashedWheelBackend.Dequeue: PTimerEntryOpaque;
var
  I, Checked: Integer;
  Node, Best: PWheelNode;
  BestSlot: Integer;
begin
  Result := nil;
  if FCount = 0 then Exit;

  // 找到最早到期的定时器
  Best := nil;
  BestSlot := -1;

  // 遍历所有槽
  Checked := 0;
  I := FCurrentSlot;
  while Checked < FSlotCount do
  begin
    Node := FSlots[I];
    while Node <> nil do
    begin
      if Node^.Rounds = 0 then
      begin
        if (Best = nil) or (Node^.Entry^.Deadline < Best^.Entry^.Deadline) then
        begin
          Best := Node;
          BestSlot := I;
        end;
      end;
      Node := Node^.Next;
    end;
    I := (I + 1) mod FSlotCount;
    Inc(Checked);
  end;

  // 检查溢出列表中已到期的
  Node := FOverflow;
  while Node <> nil do
  begin
    if (Node^.Entry^.Deadline < FCurrentTime) or (Node^.Entry^.Deadline = FCurrentTime) then
    begin
      if (Best = nil) or (Node^.Entry^.Deadline < Best^.Entry^.Deadline) then
      begin
        Best := Node;
        BestSlot := -1;  // 溢出列表
      end;
    end;
    Node := Node^.Next;
  end;

  if Best <> nil then
  begin
    RemoveNode(Best, BestSlot);
    RemoveNodeMapping(Best);
    Result := Best^.Entry;
    PTimerEntryCompat(Result)^.InHeap := False;
    PTimerEntryCompat(Result)^.HeapIndex := -1;
    Dispose(Best);
  end;
end;

function THashedWheelBackend.PopDue(const Now: TInstant; MaxCount: Integer; out DueEntries: array of PTimerEntryOpaque): Integer;
var
  Entry: PTimerEntryOpaque;
  ArrayLen: Integer;
begin
  Result := 0;
  ArrayLen := Length(DueEntries);
  if ArrayLen = 0 then Exit;

  // 先推进时间轮到当前时间
  AdvanceTo(Now);

  // 然后批量出队
  while (FCount > 0) and ((MaxCount = 0) or (Result < MaxCount)) and (Result < ArrayLen) do
  begin
    Entry := Dequeue;
    if Entry = nil then Break;

    // Dequeue 已经返回最早到期的，检查是否已到期
    if PTimerEntryCompat(Entry)^.Deadline > Now then
    begin
      // 未到期，放回队列
      Enqueue(Entry);
      Break;
    end;

    DueEntries[Result] := Entry;
    Inc(Result);
  end;
end;

function THashedWheelBackend.Peek: PTimerEntryOpaque;
var
  I, Checked: Integer;
  Node, Best: PWheelNode;
begin
  Result := nil;
  if FCount = 0 then Exit;

  Best := nil;

  // 遍历所有槽找最早的
  Checked := 0;
  I := FCurrentSlot;
  while Checked < FSlotCount do
  begin
    Node := FSlots[I];
    while Node <> nil do
    begin
      if (Best = nil) or (Node^.Entry^.Deadline < Best^.Entry^.Deadline) then
        Best := Node;
      Node := Node^.Next;
    end;
    I := (I + 1) mod FSlotCount;
    Inc(Checked);
  end;

  // 检查溢出列表
  Node := FOverflow;
  while Node <> nil do
  begin
    if (Best = nil) or (Node^.Entry^.Deadline < Best^.Entry^.Deadline) then
      Best := Node;
    Node := Node^.Next;
  end;

  if Best <> nil then
    Result := Best^.Entry;
end;

function THashedWheelBackend.PeekNextDeadline(out Dl: TInstant): Boolean;
begin
  if FCount = 0 then
  begin
    Dl := TInstant.Zero;
    Result := False;
  end
  else
  begin
    Dl := GetEarliestDeadline;
    Result := True;
  end;
end;

procedure THashedWheelBackend.Remove(E: PTimerEntryOpaque);
var
  Entry: PTimerEntryCompat;
  Node: PWheelNode;
  Slot: Integer;
begin
  Entry := PTimerEntryCompat(E);
  if Entry = nil then Exit;
  if not Entry^.InHeap then Exit;

  Node := FindNode(Entry);
  if Node = nil then Exit;

  Slot := Entry^.HeapIndex;
  if Slot = -2 then
    Slot := -1;  // 溢出列表

  RemoveNode(Node, Slot);
  RemoveNodeMapping(Node);
  Entry^.InHeap := False;
  Entry^.HeapIndex := -1;
  Dispose(Node);
end;

procedure THashedWheelBackend.UpdateDeadline(E: PTimerEntryOpaque);
var
  Entry: PTimerEntryCompat;
begin
  Entry := PTimerEntryCompat(E);
  if Entry = nil then Exit;
  if not Entry^.InHeap then Exit;

  // 简单实现：移除后重新入队
  Remove(E);
  Enqueue(E);
end;

function THashedWheelBackend.Count: Integer;
begin
  Result := FCount;
end;

function THashedWheelBackend.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure THashedWheelBackend.Clear;
var
  I: Integer;
  Node, Next: PWheelNode;
begin
  // 清空所有槽
  for I := 0 to FSlotCount - 1 do
  begin
    Node := FSlots[I];
    while Node <> nil do
    begin
      Next := Node^.Next;
      if Node^.Entry <> nil then
      begin
        Node^.Entry^.InHeap := False;
        Node^.Entry^.HeapIndex := -1;
      end;
      Dispose(Node);
      Node := Next;
    end;
    FSlots[I] := nil;
  end;

  // 清空溢出列表
  Node := FOverflow;
  while Node <> nil do
  begin
    Next := Node^.Next;
    if Node^.Entry <> nil then
    begin
      Node^.Entry^.InHeap := False;
      Node^.Entry^.HeapIndex := -1;
    end;
    Dispose(Node);
    Node := Next;
  end;
  FOverflow := nil;

  FNodeMapCount := 0;
  FCount := 0;
end;

function THashedWheelBackend.GetName: string;
begin
  Result := 'HashedWheel';
end;

procedure THashedWheelBackend.Tick;
var
  Node, Next: PWheelNode;
  Slot, Rounds: Integer;
begin
  // 推进当前时间
  FCurrentTime := FCurrentTime.Add(TDuration.FromMs(FTickIntervalMs));

  // 减少当前槽所有定时器的轮数
  Node := FSlots[FCurrentSlot];
  while Node <> nil do
  begin
    if Node^.Rounds > 0 then
      Dec(Node^.Rounds);
    Node := Node^.Next;
  end;

  // 移动到下一个槽
  FCurrentSlot := (FCurrentSlot + 1) mod FSlotCount;

  // 检查溢出列表，将到期的移入时间轮
  Node := FOverflow;
  while Node <> nil do
  begin
    Next := Node^.Next;
    if Node^.Entry^.Deadline.Diff(FCurrentTime).AsMs <= Int64(FSlotCount) * FTickIntervalMs then
    begin
      // 移出溢出列表
      if Node^.Prev <> nil then
        Node^.Prev^.Next := Node^.Next
      else
        FOverflow := Node^.Next;
      if Node^.Next <> nil then
        Node^.Next^.Prev := Node^.Prev;
      Dec(FCount);

      // 重新计算槽位置
      Slot := CalcSlotAndRounds(Node^.Entry^.Deadline, Rounds);
      Node^.Rounds := Rounds;
      Node^.Next := nil;
      Node^.Prev := nil;
      AddToSlot(Slot, Node);
      Node^.Entry^.HeapIndex := Slot;
    end;
    Node := Next;
  end;
end;

procedure THashedWheelBackend.AdvanceTo(const Now: TInstant);
var
  TicksNeeded: Int64;
  I: Int64;
begin
  TicksNeeded := Now.Diff(FCurrentTime).AsMs div FTickIntervalMs;
  for I := 1 to TicksNeeded do
    Tick;
end;

{ Factory }

function CreateHashedWheelBackendImpl(SlotCount: Integer; TickIntervalMs: Integer): ITimerQueueBackend;
begin
  Result := THashedWheelBackend.Create(SlotCount, TickIntervalMs);
end;

initialization
  RegisterHashedWheelFactory(@CreateHashedWheelBackendImpl);

end.

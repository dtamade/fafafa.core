unit fafafa.core.collections.priorityqueue;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils;

type
  {**
   * TPriorityQueue - 泛型优先队列（最小堆）
   *
   * @desc
   *   基于二叉堆实现的优先队列，支持 O(log n) 插入和删除，
   *   O(1) 获取最小元素。
   *
   * @type_params
   *   T - 元素类型
   *   TComparer - 比较器类型，函数签名: function(const A, B: T): Integer
   *               返回值: < 0 表示 A < B, = 0 表示 A = B, > 0 表示 A > B
   *}
  generic TPriorityQueue<T> = record
  private
  type
    TComparerFunc = function(const A, B: T): Integer;
    TArray = array of T;
  private
    FItems: TArray;
    FCount: Integer;
    FComparer: TComparerFunc;
    
    procedure Grow;
    procedure SiftUp(AIndex: Integer);
    procedure SiftDown(AIndex: Integer);
    procedure Swap(AIndex1, AIndex2: Integer);
    function GetItem(AIndex: Integer): T;
    
  public
    // 初始化
    procedure Initialize(AComparer: TComparerFunc);
    procedure Initialize(AComparer: TComparerFunc; ACapacity: Integer);
    
    // 基本操作
    procedure Enqueue(constref AItem: T);  // O(log n)
    function Dequeue: T;                    // O(log n)
    function Peek: T;                       // O(1)
    function TryPeek(out AItem: T): Boolean; // O(1)
    
    // 容量和状态
    function Count: Integer;
    function IsEmpty: Boolean;
    procedure Clear;
    
    // 查找和删除特定元素
    function Contains(constref AItem: T): Boolean;  // O(n)
    function Remove(constref AItem: T): Boolean;    // O(n) + O(log n)
    
    // 批量操作
    function ToArray: TArray;
  end;

implementation

{ TPriorityQueue }

procedure TPriorityQueue.Initialize(AComparer: TComparerFunc);
begin
  Initialize(AComparer, 16); // 默认初始容量
end;

procedure TPriorityQueue.Initialize(AComparer: TComparerFunc; ACapacity: Integer);
begin
  if ACapacity < 4 then
    ACapacity := 4;
    
  SetLength(FItems, ACapacity);
  FCount := 0;
  FComparer := AComparer;
end;

procedure TPriorityQueue.Grow;
var
  newCap: Integer;
begin
  if Length(FItems) = 0 then
    newCap := 16
  else
    newCap := Length(FItems) * 2;
    
  SetLength(FItems, newCap);
end;

procedure TPriorityQueue.Swap(AIndex1, AIndex2: Integer);
var
  temp: T;
begin
  temp := FItems[AIndex1];
  FItems[AIndex1] := FItems[AIndex2];
  FItems[AIndex2] := temp;
end;

procedure TPriorityQueue.SiftUp(AIndex: Integer);
var
  parentIdx: Integer;
begin
  while AIndex > 0 do
  begin
    parentIdx := (AIndex - 1) div 2;
    
    // 如果当前节点 >= 父节点，堆性质已满足
    if FComparer(FItems[AIndex], FItems[parentIdx]) >= 0 then
      Break;
      
    // 交换并继续向上
    Swap(AIndex, parentIdx);
    AIndex := parentIdx;
  end;
end;

procedure TPriorityQueue.SiftDown(AIndex: Integer);
var
  leftIdx, rightIdx, smallestIdx: Integer;
begin
  while True do
  begin
    smallestIdx := AIndex;
    leftIdx := 2 * AIndex + 1;
    rightIdx := 2 * AIndex + 2;
    
    // 找到当前节点、左子节点、右子节点中最小的
    if (leftIdx < FCount) and (FComparer(FItems[leftIdx], FItems[smallestIdx]) < 0) then
      smallestIdx := leftIdx;
      
    if (rightIdx < FCount) and (FComparer(FItems[rightIdx], FItems[smallestIdx]) < 0) then
      smallestIdx := rightIdx;
    
    // 如果当前节点已经是最小的，堆性质已满足
    if smallestIdx = AIndex then
      Break;
      
    // 交换并继续向下
    Swap(AIndex, smallestIdx);
    AIndex := smallestIdx;
  end;
end;

function TPriorityQueue.GetItem(AIndex: Integer): T;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise Exception.CreateFmt('Index %d out of bounds (Count=%d)', [AIndex, FCount]);
    
  Result := FItems[AIndex];
end;

procedure TPriorityQueue.Enqueue(constref AItem: T);
begin
  // 扩容检查
  if FCount >= Length(FItems) then
    Grow;
    
  // 添加到末尾
  FItems[FCount] := AItem;
  Inc(FCount);
  
  // 上浮到正确位置
  SiftUp(FCount - 1);
end;

function TPriorityQueue.Dequeue: T;
begin
  if FCount = 0 then
    raise Exception.Create('Priority queue is empty');
    
  // 取堆顶元素
  Result := FItems[0];
  
  // 将最后一个元素移到堆顶
  Dec(FCount);
  if FCount > 0 then
  begin
    FItems[0] := FItems[FCount];
    SiftDown(0);
  end;
end;

function TPriorityQueue.Peek: T;
begin
  if FCount = 0 then
    raise Exception.Create('Priority queue is empty');
    
  Result := FItems[0];
end;

function TPriorityQueue.TryPeek(out AItem: T): Boolean;
begin
  Result := FCount > 0;
  if Result then
    AItem := FItems[0];
end;

function TPriorityQueue.Count: Integer;
begin
  Result := FCount;
end;

function TPriorityQueue.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure TPriorityQueue.Clear;
begin
  FCount := 0;
  // 可选：释放内存
  // SetLength(FItems, 0);
end;

function TPriorityQueue.Contains(constref AItem: T): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FCount - 1 do
  begin
    if FComparer(FItems[i], AItem) = 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TPriorityQueue.Remove(constref AItem: T): Boolean;
var
  i: Integer;
begin
  Result := False;
  
  // 线性查找要删除的元素
  for i := 0 to FCount - 1 do
  begin
    if FComparer(FItems[i], AItem) = 0 then
    begin
      // 找到了，删除它
      Dec(FCount);
      
      if i < FCount then
      begin
        // 将最后一个元素移到这个位置
        FItems[i] := FItems[FCount];
        
        // 需要同时尝试上浮和下沉
        // 因为新元素可能比原元素大或小
        SiftUp(i);
        SiftDown(i);
      end;
      
      Result := True;
      Exit;
    end;
  end;
end;

function TPriorityQueue.ToArray: TArray;
var
  i: Integer;
begin
  SetLength(Result, FCount);
  for i := 0 to FCount - 1 do
    Result[i] := FItems[i];
end;

end.

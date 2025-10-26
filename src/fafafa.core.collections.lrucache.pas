unit fafafa.core.collections.lrucache;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.math,
  fafafa.core.mem.utils,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.elementManager;

type
  {** THashFunc - 泛型哈希函数类型 }
  generic THashFunc<T> = function (const aValue: T; aData: Pointer): UInt64;

  {** TEqualsFunc - 泛型相等比较函数类型 }
  generic TEqualsFunc<T> = function (const aLeft, aRight: T; aData: Pointer): Boolean;

  {**
   * ILruCache<K,V>
   *
   * @desc 最近最少使用（LRU）缓存
   * @param K 键类型（必须支持哈希和比较）
   * @param V 值类型
   * @note
   *   - 当容量满时，自动淘汰最少使用的元素
   *   - 支持 Hit/Miss 统计
   *   - O(1) 查找、插入、更新
   *   - 纯数据管理，无并发安全（职责分离）
   *}
  generic ILruCache<K, V> = interface
    ['{C3D4E5F6-A7B8-4901-CDEF-345678901BCD}']

    {**
     * Get
     *
     * @desc 获取指定键的值（访问会将该键移到 MRU 位置）
     * @param aKey 要查找的键
     * @param aValue 返回的值
     * @return Boolean 是否找到（True=命中，False=未命中）
     *}
    function Get(const aKey: K; out aValue: V): Boolean;

    {**
     * Put
     *
     * @desc 插入或更新键值对
     * @param aKey 键
     * @param aValue 值
     * @note
     *   - 如果键已存在，会更新值并将该键移到 MRU 位置
     *   - 如果容量满，会淘汰 LRU 元素
     *}
    procedure Put(const aKey: K; const aValue: V);

    {**
     * SetMaxSize
     *
     * @desc 设置缓存的最大容量
     * @param aMaxSize 新的最大容量
     * @note 如果新容量小于当前大小，会淘汰多余元素
     *}
    procedure SetMaxSize(aMaxSize: SizeUInt);

    {**
     * GetMaxSize
     *
     * @desc 获取缓存的最大容量
     * @return SizeUInt 最大容量
     *}
    function GetMaxSize: SizeUInt;

    {**
     * GetSize
     *
     * @desc 获取当前缓存大小
     * @return SizeUInt 当前大小
     *}
    function GetSize: SizeUInt;

    {**
     * GetHitCount
     *
     * @desc 获取命中次数
     * @return UInt64 命中次数
     *}
    function GetHitCount: UInt64;

    {**
     * GetMissCount
     *
     * @desc 获取未命中次数
     * @return UInt64 未命中次数
     *}
    function GetMissCount: UInt64;

    {**
     * GetHitRate
     *
     * @desc 获取命中率
     * @return Double 命中率（0.0-1.0）
     *}
    function GetHitRate: Double;

    {**
     * Clear
     *
     * @desc 清空缓存
     *}
    procedure Clear;

    {**
     * Evict
     *
     * @desc 手动淘汰 LRU 元素
     * @return Boolean 是否成功淘汰
     *}
    function Evict: Boolean;

    {**
     * EvictLeastRecent
     *
     * @desc 淘汰指定数量的元素
     * @param aCount 要淘汰的数量
     * @return SizeUInt 实际淘汰的数量
     *}
    function EvictLeastRecent(aCount: SizeUInt): SizeUInt;

    {**
     * Peek
     *
     * @desc 查看指定键的值（不更新访问顺序）
     * @param aKey 要查找的键
     * @param aValue 返回的值
     * @return Boolean 是否找到
     *}
    function Peek(const aKey: K; out aValue: V): Boolean;

    {**
     * Remove
     *
     * @desc 移除指定键
     * @param aKey 要移除的键
     * @return Boolean 是否找到并移除
     *}
    function Remove(const aKey: K): Boolean;

    {**
     * Contains
     *
     * @desc 检查是否包含指定键
     * @param aKey 要查找的键
     * @return Boolean 是否包含
     *}
    function Contains(const aKey: K): Boolean;
  end;

  { TLruNode<K,V> LRU 缓存节点 }
  generic TLruNode<K, V> = record
    Key: K;
    Value: V;
    Prev: Pointer;
    Next: Pointer;
  end;

  {**
   * TLruCache<K,V>
   *
   * @desc 最近最少使用（LRU）缓存实现
   * @param K 键类型
   * @param V 值类型
   * @note
   *   - 使用哈希表 + 双向链表实现
   *   - O(1) 查找、插入、更新
   *   - MRU: Most Recently Used (最近最多使用)
   *   - LRU: Least Recently Used (最近最少使用)
   *}
  generic TLruCache<K, V> = class(TInterfacedObject, specialize ILruCache<K, V>)

  type
    PNode = ^specialize TLruNode<K, V>;
    TNodeType = specialize TLruNode<K, V>;
    THashMapNode = specialize THashMap<K, PNode>;

  private
    FMap: THashMapNode;
    FHead: PNode;  { 指向 MRU 端 }
    FTail: PNode;  { 指向 LRU 端 }
    FMaxSize: SizeUInt;
    FSize: SizeUInt;
    FHitCount: UInt64;
    FMissCount: UInt64;
    FAllocator: IAllocator;
    FHashFunc: specialize THashFunc<K>;
    FEqualsFunc: specialize TEqualsFunc<K>;

    { 链表操作 }
    procedure AddToMRU(aNode: PNode);
    procedure MoveToMRU(aNode: PNode);
    function RemoveFromLRU: PNode;
    procedure RemoveNode(aNode: PNode);

    { 辅助方法 }
    function CreateNode(const aKey: K; const aValue: V): PNode;
    procedure DestroyNode(aNode: PNode);

  public
    constructor Create(aMaxSize: SizeUInt; const aAllocator: IAllocator = nil;
      const aHash: specialize THashFunc<K> = nil; const aEquals: specialize TEqualsFunc<K> = nil);
    destructor Destroy; override;

    { ILruCache 接口实现 }
    function Get(const aKey: K; out aValue: V): Boolean;
    procedure Put(const aKey: K; const aValue: V);
    procedure SetMaxSize(aMaxSize: SizeUInt);
    function GetMaxSize: SizeUInt;
    function GetSize: SizeUInt;
    function GetHitCount: UInt64;
    function GetMissCount: UInt64;
    function GetHitRate: Double;
    procedure Clear;
    function Evict: Boolean;
    function EvictLeastRecent(aCount: SizeUInt): SizeUInt;
    function Peek(const aKey: K; out aValue: V): Boolean;
    function Remove(const aKey: K): Boolean;
    function Contains(const aKey: K): Boolean;
  end;

implementation

{ TLruCache }

constructor TLruCache.Create(aMaxSize: SizeUInt; const aAllocator: IAllocator;
  const aHash: specialize THashFunc<K>; const aEquals: specialize TEqualsFunc<K>);
begin
  inherited Create;

  if aMaxSize = 0 then
    aMaxSize := 100; { 默认容量 }

  FMaxSize := aMaxSize;
  FSize := 0;
  FHitCount := 0;
  FMissCount := 0;
  FAllocator := aAllocator;
  if FAllocator = nil then
    FAllocator := GetRtlAllocator;

  FHashFunc := aHash;
  FEqualsFunc := aEquals;

  FMap := THashMapNode.Create(aMaxSize * 2, nil, nil, FAllocator);
  FHead := nil;
  FTail := nil;
end;

destructor TLruCache.Destroy;
begin
  Clear;
  FMap.Free;
  inherited Destroy;
end;

function TLruCache.CreateNode(const aKey: K; const aValue: V): PNode;
begin
  Result := PNode(FAllocator.AllocMem(SizeOf(TNodeType)));
  Result^.Key := aKey;
  Result^.Value := aValue;
  Result^.Prev := nil;
  Result^.Next := nil;
end;

procedure TLruCache.DestroyNode(aNode: PNode);
begin
  if aNode <> nil then
    FAllocator.FreeMem(aNode);
end;

procedure TLruCache.AddToMRU(aNode: PNode);
begin
  if aNode = nil then Exit;

  { 添加到 MRU 端（头部） }
  aNode^.Next := FHead;
  aNode^.Prev := nil;

  if FHead <> nil then
    PNode(FHead)^.Prev := aNode;

  FHead := aNode;

  if FTail = nil then
    FTail := aNode;
end;

procedure TLruCache.MoveToMRU(aNode: PNode);
begin
  if aNode = nil then Exit;

  { 如果已在 MRU 端，不需要移动 }
  if aNode = FHead then Exit;

  { 从当前位置移除 }
  if aNode^.Prev <> nil then
    PNode(aNode^.Prev)^.Next := aNode^.Next;

  if aNode^.Next <> nil then
    PNode(aNode^.Next)^.Prev := aNode^.Prev;

  { 如果是 Tail，需要更新 Tail }
  if aNode = FTail then
  begin
    FTail := PNode(FTail)^.Prev;
    if FTail <> nil then
      PNode(FTail)^.Next := nil;
  end;

  { 添加到 MRU 端 }
  AddToMRU(aNode);
end;

function TLruCache.RemoveFromLRU: PNode;
begin
  { 从 LRU 端（尾部）移除 }
  if FTail = nil then
  begin
    Result := nil;
    Exit;
  end;

  Result := FTail;

  if FHead = FTail then
  begin
    { 只有一个节点 }
    FHead := nil;
    FTail := nil;
  end
  else
  begin
    FTail := PNode(FTail)^.Prev;
    PNode(FTail)^.Next := nil;
  end;

  Result^.Prev := nil;
  Result^.Next := nil;
end;

procedure TLruCache.RemoveNode(aNode: PNode);
begin
  if aNode = nil then Exit;

  { 从链表中移除 }
  if aNode^.Prev <> nil then
    PNode(aNode^.Prev)^.Next := aNode^.Next;

  if aNode^.Next <> nil then
    PNode(aNode^.Next)^.Prev := aNode^.Prev;

  { 更新 Head/Tail }
  if aNode = FHead then
    FHead := PNode(aNode^.Next);

  if aNode = FTail then
    FTail := PNode(aNode^.Prev);
end;

function TLruCache.Get(const aKey: K; out aValue: V): Boolean;
var
  LNode: PNode;
begin
  if FMap.TryGetValue(aKey, LNode) then
  begin
    { 命中 }
    aValue := LNode^.Value;
    Inc(FHitCount);

    { 移动到 MRU 端 }
    MoveToMRU(LNode);

    Result := True;
  end
  else
  begin
    { 未命中 }
    Inc(FMissCount);
    Result := False;
  end;
end;

procedure TLruCache.Put(const aKey: K; const aValue: V);
var
  LNode: PNode;
begin
  { 检查是否已存在 }
  if FMap.TryGetValue(aKey, LNode) then
  begin
    { 更新值并移动到 MRU 端 }
    LNode^.Value := aValue;
    MoveToMRU(LNode);
    Exit;
  end;

  { 创建新节点 }
  LNode := CreateNode(aKey, aValue);

  { 插入到哈希表 }
  FMap.Add(aKey, LNode);

  { 添加到 MRU 端 }
  AddToMRU(LNode);
  Inc(FSize);

  { 检查是否需要淘汰 }
  if FSize > FMaxSize then
  begin
    { 淘汰 LRU 元素 }
    Evict;
  end;
end;

procedure TLruCache.SetMaxSize(aMaxSize: SizeUInt);
begin
  FMaxSize := aMaxSize;

  { 如果新容量小于当前大小，需要淘汰 }
  while FSize > FMaxSize do
    Evict;
end;

function TLruCache.GetMaxSize: SizeUInt;
begin
  Result := FMaxSize;
end;

function TLruCache.GetSize: SizeUInt;
begin
  Result := FSize;
end;

function TLruCache.GetHitCount: UInt64;
begin
  Result := FHitCount;
end;

function TLruCache.GetMissCount: UInt64;
begin
  Result := FMissCount;
end;

function TLruCache.GetHitRate: Double;
begin
  if FHitCount + FMissCount = 0 then
    Result := 0.0
  else
    Result := FHitCount / (FHitCount + FMissCount);
end;

procedure TLruCache.Clear;
var
  LCurrent, LNext: PNode;
begin
  LCurrent := FHead;
  while LCurrent <> nil do
  begin
    LNext := PNode(LCurrent)^.Next;
    DestroyNode(LCurrent);
    LCurrent := LNext;
  end;

  FHead := nil;
  FTail := nil;
  FSize := 0;
  FHitCount := 0;
  FMissCount := 0;
  FMap.Clear;
end;

function TLruCache.Evict: Boolean;
var
  LNode: PNode;
begin
  LNode := RemoveFromLRU;
  if LNode <> nil then
  begin
    { 从哈希表中移除 }
    FMap.Remove(LNode^.Key);

    { 销毁节点 }
    DestroyNode(LNode);
    Dec(FSize);

    Result := True;
  end
  else
    Result := False;
end;

function TLruCache.EvictLeastRecent(aCount: SizeUInt): SizeUInt;
var
  i: SizeUInt;
begin
  Result := 0;
  for i := 1 to aCount do
  begin
    if Evict then
      Inc(Result)
    else
      Break;
  end;
end;

function TLruCache.Peek(const aKey: K; out aValue: V): Boolean;
var
  LNode: PNode;
begin
  Result := FMap.TryGetValue(aKey, LNode);
  if Result then
  begin
    aValue := LNode^.Value;
    { 注意：Peek 不更新访问顺序 }
  end;
end;

function TLruCache.Remove(const aKey: K): Boolean;
var
  LNode: PNode;
begin
  Result := FMap.TryGetValue(aKey, LNode);
  if Result then
  begin
    { 从链表中移除 }
    RemoveNode(LNode);

    { 从哈希表中移除 }
    FMap.Remove(aKey);

    { 销毁节点 }
    DestroyNode(LNode);
    Dec(FSize);
  end;
end;

function TLruCache.Contains(const aKey: K): Boolean;
begin
  Result := FMap.ContainsKey(aKey);
end;

end.

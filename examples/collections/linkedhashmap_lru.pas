program linkedhashmap_lru;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections,
  fafafa.core.collections.linkedhashmap;

{**
 * 简单 LRU (Least Recently Used) 缓存示例
 * 使用 LinkedHashMap 保持插入顺序，超出容量时删除最旧项
 *}
type
  generic TLRUCache<K, V> = class
  private
    FMap: specialize ILinkedHashMap<K, V>;
    FMaxSize: SizeUInt;
    
    procedure EvictOldest;
  public
    constructor Create(aMaxSize: SizeUInt);
    
    procedure Put(const aKey: K; const aValue: V);
    function TryGet(const aKey: K; out aValue: V): Boolean;
    function GetCount: SizeUInt;
  end;

{ TLRUCache }

constructor TLRUCache.Create(aMaxSize: SizeUInt);
begin
  FMaxSize := aMaxSize;
  FMap := specialize MakeLinkedHashMap<K, V>(aMaxSize);
end;

procedure TLRUCache.EvictOldest;
var
  LFirst: specialize TPair<K, V>;
begin
  if FMap.GetCount >= FMaxSize then
  begin
    // 获取最旧的项（链表头）并删除
    LFirst := FMap.First;
    FMap.Remove(LFirst.Key);
    WriteLn('  [Evicted] ', LFirst.Key);
  end;
end;

procedure TLRUCache.Put(const aKey: K; const aValue: V);
begin
  // 如果已存在，先删除（AddOrAssign会保持原位置）
  if FMap.ContainsKey(aKey) then
    FMap.Remove(aKey);
    
  // 检查是否需要淘汰
  EvictOldest;
  
  // 添加到末尾（最新）
  FMap.Add(aKey, aValue);
end;

function TLRUCache.TryGet(const aKey: K; out aValue: V): Boolean;
begin
  Result := FMap.TryGetValue(aKey, aValue);
end;

function TLRUCache.GetCount: SizeUInt;
begin
  Result := FMap.GetCount;
end;

{ 示例使用 }
var
  LCache: specialize TLRUCache<string, Integer>;
  LValue: Integer;
  LPair: specialize TPair<string, Integer>;
  LMap: specialize ILinkedHashMap<string, Integer>;
begin
  WriteLn('=== LinkedHashMap LRU 缓存示例 ===');
  WriteLn;
  
  // 创建容量为 3 的缓存
  LCache := specialize TLRUCache<string, Integer>.Create(3);
  try
    WriteLn('添加 3 个项目（容量限制为 3）...');
    LCache.Put('page1', 100);
    LCache.Put('page2', 200);
    LCache.Put('page3', 300);
    WriteLn('缓存大小: ', LCache.GetCount);
    WriteLn;
    
    WriteLn('添加第 4 个项目（会淘汰最旧的 page1）...');
    LCache.Put('page4', 400);
    WriteLn('缓存大小: ', LCache.GetCount);
    WriteLn;
    
    WriteLn('尝试获取已淘汰的 page1:');
    if LCache.TryGet('page1', LValue) then
      WriteLn('  找到: ', LValue)
    else
      WriteLn('  [未找到] page1 已被淘汰');
    WriteLn;
    
    WriteLn('获取 page2（仍在缓存中）:');
    if LCache.TryGet('page2', LValue) then
      WriteLn('  找到: ', LValue);
    WriteLn;
    
    WriteLn('--- 当前缓存顺序（从旧到新）---');
    LMap := LCache.FMap;
    LPair := LMap.First;
    WriteLn('最旧: ', LPair.Key, ' = ', LPair.Value);
    LPair := LMap.Last;
    WriteLn('最新: ', LPair.Key, ' = ', LPair.Value);
    
  finally
    LCache.Free;
  end;
  
  WriteLn;
  WriteLn('=== 示例完成 ===');
end.


unit Test_LruCache_Eviction;

{**
 * @desc TDD 测试：LruCache 淘汰策略测试
 * @purpose 验证 LRU 缓存的淘汰机制
 *
 * 测试内容:
 *   - 容量满时自动淘汰 LRU 元素
 *   - 访问元素将其移至 MRU 位置
 *   - Hit/Miss 统计
 *   - 手动淘汰
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.lrucache,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_LruCache_Eviction }
  TTestCase_LruCache_Eviction = class(TTestCase)
  private
    type
      TIntIntCache = specialize ILruCache<Integer, Integer>;
      TStrIntCache = specialize ILruCache<string, Integer>;
  published
    // 基本操作测试
    procedure Test_LruCache_Put_Get_Works;
    procedure Test_LruCache_MaxSize_Respected;
    procedure Test_LruCache_Eviction_RemovesLRU;
    
    // LRU 语义测试
    procedure Test_LruCache_Get_MovesToMRU;
    procedure Test_LruCache_Put_Existing_MovesToMRU;
    
    // 统计测试
    procedure Test_LruCache_HitMiss_Counting;
    procedure Test_LruCache_HitRate_Calculation;
    
    // 手动淘汰测试
    procedure Test_LruCache_Evict_RemovesOne;
    procedure Test_LruCache_EvictLeastRecent_RemovesMultiple;
    
    // 边界测试
    procedure Test_LruCache_Peek_DoesNotUpdateOrder;
    procedure Test_LruCache_Remove_Works;
    procedure Test_LruCache_Clear_Works;
    procedure Test_LruCache_SetMaxSize_EvictsExcess;
    
    // 托管类型测试
    procedure Test_LruCache_String_Keys_NoLeak;
  end;

implementation

{ TTestCase_LruCache_Eviction }

procedure TTestCase_LruCache_Eviction.Test_LruCache_Put_Get_Works;
var
  Cache: TIntIntCache;
  V: Integer;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(10);
  
  Cache.Put(1, 100);
  Cache.Put(2, 200);
  
  AssertTrue('应能获取键 1', Cache.Get(1, V));
  AssertEquals('键 1 的值应为 100', 100, V);
  
  AssertTrue('应能获取键 2', Cache.Get(2, V));
  AssertEquals('键 2 的值应为 200', 200, V);
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_MaxSize_Respected;
var
  Cache: TIntIntCache;
  I: Integer;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(5);
  
  // 插入 10 个元素
  for I := 1 to 10 do
    Cache.Put(I, I * 10);
  
  // 容量应限制在 5
  AssertEquals('Size 应为 5', 5, Cache.GetSize);
  AssertEquals('MaxSize 应为 5', 5, Cache.GetMaxSize);
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_Eviction_RemovesLRU;
var
  Cache: TIntIntCache;
  V: Integer;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(3);
  
  // 按顺序插入: 1, 2, 3
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  
  // 插入第 4 个，应淘汰 1 (LRU)
  Cache.Put(4, 40);
  
  AssertFalse('键 1 应已被淘汰', Cache.Contains(1));
  AssertTrue('键 2 应存在', Cache.Contains(2));
  AssertTrue('键 3 应存在', Cache.Contains(3));
  AssertTrue('键 4 应存在', Cache.Contains(4));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_Get_MovesToMRU;
var
  Cache: TIntIntCache;
  V: Integer;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(3);
  
  // 插入: 1, 2, 3 (LRU = 1)
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  
  // 访问 1，将其移到 MRU
  Cache.Get(1, V);
  
  // 插入 4，应淘汰 2 (现在的 LRU)
  Cache.Put(4, 40);
  
  AssertTrue('键 1 应存在 (已移到 MRU)', Cache.Contains(1));
  AssertFalse('键 2 应被淘汰', Cache.Contains(2));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_Put_Existing_MovesToMRU;
var
  Cache: TIntIntCache;
  V: Integer;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(3);
  
  // 插入: 1, 2, 3
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  
  // 更新 1 (移到 MRU)
  Cache.Put(1, 100);
  
  // 插入 4，应淘汰 2
  Cache.Put(4, 40);
  
  AssertTrue('键 1 应存在', Cache.Contains(1));
  AssertTrue(Cache.Get(1, V));
  AssertEquals('键 1 的值应更新为 100', 100, V);
  AssertFalse('键 2 应被淘汰', Cache.Contains(2));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_HitMiss_Counting;
var
  Cache: TIntIntCache;
  V: Integer;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(10);
  
  Cache.Put(1, 10);
  
  // 命中
  Cache.Get(1, V);
  Cache.Get(1, V);
  
  // 未命中
  Cache.Get(999, V);
  
  AssertEquals('命中次数应为 2', 2, Cache.GetHitCount);
  AssertEquals('未命中次数应为 1', 1, Cache.GetMissCount);
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_HitRate_Calculation;
var
  Cache: TIntIntCache;
  V: Integer;
  Rate: Double;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(10);
  
  Cache.Put(1, 10);
  
  // 3 次命中，1 次未命中 -> 命中率 = 75%
  Cache.Get(1, V);
  Cache.Get(1, V);
  Cache.Get(1, V);
  Cache.Get(999, V);
  
  Rate := Cache.GetHitRate;
  AssertTrue('命中率应约为 0.75', (Rate >= 0.74) and (Rate <= 0.76));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_Evict_RemovesOne;
var
  Cache: TIntIntCache;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(5);
  
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  
  AssertEquals('淘汰前 Size 应为 3', 3, Cache.GetSize);
  
  AssertTrue('Evict 应成功', Cache.Evict);
  
  AssertEquals('淘汰后 Size 应为 2', 2, Cache.GetSize);
  AssertFalse('键 1 (LRU) 应被淘汰', Cache.Contains(1));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_EvictLeastRecent_RemovesMultiple;
var
  Cache: TIntIntCache;
  Evicted: SizeUInt;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(10);
  
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  Cache.Put(4, 40);
  Cache.Put(5, 50);
  
  Evicted := Cache.EvictLeastRecent(3);
  
  AssertEquals('应淘汰 3 个', 3, Evicted);
  AssertEquals('剩余 Size 应为 2', 2, Cache.GetSize);
  
  // 1, 2, 3 是 LRU，应被淘汰
  AssertFalse('键 1 应被淘汰', Cache.Contains(1));
  AssertFalse('键 2 应被淘汰', Cache.Contains(2));
  AssertFalse('键 3 应被淘汰', Cache.Contains(3));
  AssertTrue('键 4 应存在', Cache.Contains(4));
  AssertTrue('键 5 应存在', Cache.Contains(5));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_Peek_DoesNotUpdateOrder;
var
  Cache: TIntIntCache;
  V: Integer;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(3);
  
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  
  // Peek 不应更新顺序
  AssertTrue('Peek 应成功', Cache.Peek(1, V));
  AssertEquals('Peek 值应为 10', 10, V);
  
  // 插入 4，应淘汰 1 (仍是 LRU)
  Cache.Put(4, 40);
  
  AssertFalse('键 1 应被淘汰 (Peek 不更新顺序)', Cache.Contains(1));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_Remove_Works;
var
  Cache: TIntIntCache;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(10);
  
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  
  AssertTrue('Remove 应成功', Cache.Remove(1));
  AssertFalse('键 1 应已移除', Cache.Contains(1));
  AssertEquals('Size 应为 1', 1, Cache.GetSize);
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_Clear_Works;
var
  Cache: TIntIntCache;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(10);
  
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  
  Cache.Clear;
  
  AssertEquals('Clear 后 Size 应为 0', 0, Cache.GetSize);
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_SetMaxSize_EvictsExcess;
var
  Cache: TIntIntCache;
begin
  Cache := specialize MakeLruCache<Integer, Integer>(10);
  
  Cache.Put(1, 10);
  Cache.Put(2, 20);
  Cache.Put(3, 30);
  Cache.Put(4, 40);
  Cache.Put(5, 50);
  
  // 缩小 MaxSize
  Cache.SetMaxSize(2);
  
  AssertEquals('MaxSize 应为 2', 2, Cache.GetMaxSize);
  AssertEquals('Size 应为 2', 2, Cache.GetSize);
  
  // 1, 2, 3 是 LRU，应被淘汰
  AssertFalse('键 1 应被淘汰', Cache.Contains(1));
  AssertFalse('键 2 应被淘汰', Cache.Contains(2));
  AssertFalse('键 3 应被淘汰', Cache.Contains(3));
  AssertTrue('键 4 应存在', Cache.Contains(4));
  AssertTrue('键 5 应存在', Cache.Contains(5));
end;

procedure TTestCase_LruCache_Eviction.Test_LruCache_String_Keys_NoLeak;
var
  Cache: TStrIntCache;
  V: Integer;
begin
  Cache := specialize MakeLruCache<string, Integer>(3);
  
  Cache.Put('apple', 1);
  Cache.Put('banana', 2);
  Cache.Put('cherry', 3);
  
  // 淘汰 apple
  Cache.Put('date', 4);
  
  AssertFalse('apple 应被淘汰', Cache.Contains('apple'));
  AssertTrue(Cache.Get('banana', V));
  AssertEquals('banana 值应为 2', 2, V);
  
  Cache.Clear;
  AssertEquals('Clear 后 Size 应为 0', 0, Cache.GetSize);
end;

initialization
  RegisterTest(TTestCase_LruCache_Eviction);

end.

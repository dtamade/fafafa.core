unit Test_PoolAllocator;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: TPoolAllocator
 * 
 * 测试目标:
 * 1. 基本分配和释放
 * 2. 与 TreeMap 集成
 * 3. 与 LinkedHashMap 集成
 * 4. 池满时的后备分配
 * 5. 内存泄漏检测
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.mem.pool.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.treemap,
  fafafa.core.collections.linkedhashmap,
  fafafa.core.collections;

type
  { TTestPoolAllocator }
  TTestPoolAllocator = class(TTestCase)
  published
    // 基本测试
    procedure Test_Create_ValidParams;
    procedure Test_GetMem_FreeMem_Basic;
    procedure Test_AllocMem_ZeroInitialized;
    procedure Test_Pool_Exhaustion_Fallback;
    
    // 与集合集成
    procedure Test_TreeMap_WithPoolAllocator;
    procedure Test_LinkedHashMap_WithPoolAllocator;
    
    // 性能验证（简单）
    procedure Test_ManyAllocations_NoLeak;
  end;

implementation

{ Callback functions for TreeMap }

function IntCompare(const A, B: Integer; aData: Pointer): SizeInt;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

function StrCompare(const A, B: String; aData: Pointer): SizeInt;
begin
  Result := CompareStr(A, B);
end;

{ Tests }

procedure TTestPoolAllocator.Test_Create_ValidParams;
var
  Pool: IAllocator;
begin
  Pool := MakePoolAllocator(64, 100);
  AssertTrue('Pool should be created', Pool <> nil);
end;

procedure TTestPoolAllocator.Test_GetMem_FreeMem_Basic;
var
  Pool: IAllocator;
  P1, P2, P3: Pointer;
begin
  Pool := MakePoolAllocator(32, 10);
  
  P1 := Pool.GetMem(32);
  AssertTrue('P1 should be allocated', P1 <> nil);
  
  P2 := Pool.GetMem(32);
  AssertTrue('P2 should be allocated', P2 <> nil);
  AssertTrue('P1 and P2 should be different', P1 <> P2);
  
  Pool.FreeMem(P1);
  
  P3 := Pool.GetMem(32);
  AssertTrue('P3 should be allocated', P3 <> nil);
  // P3 可能重用 P1 的位置
  AssertEquals('P3 should reuse P1 slot', PtrUInt(P1), PtrUInt(P3));
  
  Pool.FreeMem(P2);
  Pool.FreeMem(P3);
end;

procedure TTestPoolAllocator.Test_AllocMem_ZeroInitialized;
var
  Pool: IAllocator;
  P: PByte;
  i: Integer;
  AllZero: Boolean;
begin
  Pool := MakePoolAllocator(64, 10);
  
  P := Pool.AllocMem(64);
  AssertTrue('P should be allocated', P <> nil);
  
  AllZero := True;
  for i := 0 to 63 do
    if P[i] <> 0 then
    begin
      AllZero := False;
      Break;
    end;
  
  AssertTrue('Memory should be zero-initialized', AllZero);
  
  Pool.FreeMem(P);
end;

procedure TTestPoolAllocator.Test_Pool_Exhaustion_Fallback;
var
  Pool: IAllocator;
  Ptrs: array[0..9] of Pointer;
  ExtraPtr: Pointer;
  i: Integer;
begin
  Pool := MakePoolAllocator(32, 10);
  
  // 分配满池
  for i := 0 to 9 do
  begin
    Ptrs[i] := Pool.GetMem(32);
    AssertTrue('Ptr[' + IntToStr(i) + '] should be allocated', Ptrs[i] <> nil);
  end;
  
  // 池满后应使用后备分配器
  ExtraPtr := Pool.GetMem(32);
  AssertTrue('ExtraPtr should be allocated from fallback', ExtraPtr <> nil);
  
  // 释放所有
  Pool.FreeMem(ExtraPtr);
  for i := 0 to 9 do
    Pool.FreeMem(Ptrs[i]);
end;

procedure TTestPoolAllocator.Test_TreeMap_WithPoolAllocator;
type
  TIntIntTreeMap = specialize ITreeMap<Integer, Integer>;
  TIntIntTreeMapImpl = specialize TTreeMap<Integer, Integer>;
var
  Pool: IAllocator;
  Map: TIntIntTreeMap;
  V: Integer;
  i: Integer;
begin
  // 为 TreeMap 节点创建池分配器
  // TreeMap 节点大小约为 40-48 字节（取决于 K,V 类型）
  Pool := MakePoolAllocator(64, 1000);
  
  Map := TIntIntTreeMapImpl.Create(Pool, @IntCompare);
  
  // 插入数据
  for i := 1 to 500 do
    Map.Put(i, i * 10);
  
  // 验证数据
  for i := 1 to 500 do
  begin
    AssertTrue('Key should exist: ' + IntToStr(i), Map.ContainsKey(i));
    Map.Get(i, V);
    AssertEquals('Value should match', i * 10, V);
  end;
  
  // 删除部分数据
  for i := 1 to 250 do
    Map.Remove(i);
  
  AssertEquals('Count should be 250', 250, Map.GetKeyCount);
  
  // Map 释放时会归还所有节点到池
end;

procedure TTestPoolAllocator.Test_LinkedHashMap_WithPoolAllocator;
type
  TStrIntLinkedHashMap = specialize ILinkedHashMap<String, Integer>;
  TStrIntLinkedHashMapImpl = specialize TLinkedHashMap<String, Integer>;
var
  Pool: IAllocator;
  Map: TStrIntLinkedHashMap;
  V: Integer;
  i: Integer;
begin
  // LinkedHashMap 节点较大（包含链表指针）
  Pool := MakePoolAllocator(128, 1000);
  
  Map := TStrIntLinkedHashMapImpl.Create(1000, Pool);
  
  // 插入数据
  for i := 1 to 500 do
    Map.Put('key' + IntToStr(i), i);
  
  // 验证数据
  for i := 1 to 500 do
  begin
    AssertTrue('Key should exist', Map.ContainsKey('key' + IntToStr(i)));
    Map.TryGetValue('key' + IntToStr(i), V);
    AssertEquals('Value should match', i, V);
  end;
  
  AssertEquals('Count should be 500', 500, Map.Count);
end;

procedure TTestPoolAllocator.Test_ManyAllocations_NoLeak;
var
  Pool: IAllocator;
  Ptrs: array[0..999] of Pointer;
  i, j: Integer;
begin
  Pool := MakePoolAllocator(32, 1000);
  
  // 多轮分配和释放
  for j := 1 to 10 do
  begin
    for i := 0 to 999 do
      Ptrs[i] := Pool.GetMem(32);
    
    for i := 0 to 999 do
      Pool.FreeMem(Ptrs[i]);
  end;
  
  // HeapTrc 会报告泄漏
end;

initialization
  RegisterTest(TTestPoolAllocator);

end.

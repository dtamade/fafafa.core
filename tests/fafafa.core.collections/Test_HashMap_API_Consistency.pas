unit Test_HashMap_API_Consistency;

{**
 * @desc TDD 测试：HashMap API 一致性
 * @purpose 验证 HashMap 与 TreeMap API 命名统一
 * 
 * 新增 API:
 *   - Put(K, V): Boolean    => AddOrAssign 别名
 *   - Get(K, out V): Boolean => TryGetValue 别名
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.hashmap,
  fafafa.core.mem.allocator;

type
  { TTestCase_HashMap_API_Consistency }
  TTestCase_HashMap_API_Consistency = class(TTestCase)
  private
    type
      TIntIntMap = specialize THashMap<Integer, Integer>;
      TStrIntMap = specialize THashMap<string, Integer>;
  published
    // Put 方法测试 (应等价于 AddOrAssign)
    procedure Test_Put_NewKey_ReturnsTrue;
    procedure Test_Put_ExistingKey_ReturnsFalse_UpdatesValue;
    procedure Test_Put_MultipleKeys_AllAccessible;
    
    // Get 方法测试 (应等价于 TryGetValue)
    procedure Test_Get_ExistingKey_ReturnsTrue_OutputsValue;
    procedure Test_Get_NonExistingKey_ReturnsFalse;
    procedure Test_Get_AfterPut_ReturnsCorrectValue;
    
    // API 一致性验证：Put/Get 与 AddOrAssign/TryGetValue 行为相同
    procedure Test_Put_Get_Equivalence_AddOrAssign_TryGetValue;
  end;

implementation

{ TTestCase_HashMap_API_Consistency }

procedure TTestCase_HashMap_API_Consistency.Test_Put_NewKey_ReturnsTrue;
var
  Map: TIntIntMap;
  Result: Boolean;
begin
  Map := TIntIntMap.Create;
  try
    Result := Map.Put(1, 100);
    AssertTrue('Put 新键应返回 True', Result);
    AssertEquals('Count 应为 1', 1, Map.GetCount);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_API_Consistency.Test_Put_ExistingKey_ReturnsFalse_UpdatesValue;
var
  Map: TIntIntMap;
  Result: Boolean;
  Value: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    Result := Map.Put(1, 200);  // 更新现有键
    AssertFalse('Put 现有键应返回 False', Result);
    AssertTrue('键应存在', Map.Get(1, Value));
    AssertEquals('值应被更新', 200, Value);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_API_Consistency.Test_Put_MultipleKeys_AllAccessible;
var
  Map: TIntIntMap;
  Value: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 10);
    Map.Put(2, 20);
    Map.Put(3, 30);
    
    AssertEquals('Count 应为 3', 3, Map.GetCount);
    
    AssertTrue('键1应存在', Map.Get(1, Value));
    AssertEquals('键1值', 10, Value);
    
    AssertTrue('键2应存在', Map.Get(2, Value));
    AssertEquals('键2值', 20, Value);
    
    AssertTrue('键3应存在', Map.Get(3, Value));
    AssertEquals('键3值', 30, Value);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_API_Consistency.Test_Get_ExistingKey_ReturnsTrue_OutputsValue;
var
  Map: TIntIntMap;
  Value: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.AddOrAssign(42, 999);
    AssertTrue('Get 应返回 True', Map.Get(42, Value));
    AssertEquals('Get 应输出正确值', 999, Value);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_API_Consistency.Test_Get_NonExistingKey_ReturnsFalse;
var
  Map: TIntIntMap;
  Value: Integer;
begin
  Map := TIntIntMap.Create;
  try
    AssertFalse('Get 不存在的键应返回 False', Map.Get(999, Value));
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_API_Consistency.Test_Get_AfterPut_ReturnsCorrectValue;
var
  Map: TStrIntMap;
  Value: Integer;
begin
  Map := TStrIntMap.Create;
  try
    Map.Put('hello', 123);
    Map.Put('world', 456);
    
    AssertTrue('Get hello', Map.Get('hello', Value));
    AssertEquals('hello value', 123, Value);
    
    AssertTrue('Get world', Map.Get('world', Value));
    AssertEquals('world value', 456, Value);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_API_Consistency.Test_Put_Get_Equivalence_AddOrAssign_TryGetValue;
var
  Map1, Map2: TIntIntMap;
  V1, V2: Integer;
  R1, R2: Boolean;
  I: Integer;
begin
  // 验证 Put/Get 与 AddOrAssign/TryGetValue 行为完全一致
  Map1 := TIntIntMap.Create;
  Map2 := TIntIntMap.Create;
  try
    // 插入相同数据
    for I := 1 to 100 do
    begin
      R1 := Map1.Put(I, I * 10);
      R2 := Map2.AddOrAssign(I, I * 10);
      AssertEquals(Format('插入键%d返回值一致', [I]), R1, R2);
    end;
    
    // 更新相同数据
    for I := 1 to 50 do
    begin
      R1 := Map1.Put(I, I * 20);
      R2 := Map2.AddOrAssign(I, I * 20);
      AssertEquals(Format('更新键%d返回值一致', [I]), R1, R2);
    end;
    
    // 验证读取一致
    for I := 1 to 100 do
    begin
      R1 := Map1.Get(I, V1);
      R2 := Map2.TryGetValue(I, V2);
      AssertEquals(Format('Get键%d返回值一致', [I]), R1, R2);
      if R1 then
        AssertEquals(Format('Get键%d值一致', [I]), V1, V2);
    end;
    
    // 验证不存在的键
    R1 := Map1.Get(9999, V1);
    R2 := Map2.TryGetValue(9999, V2);
    AssertEquals('不存在键返回值一致', R1, R2);
    
  finally
    Map1.Free;
    Map2.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_HashMap_API_Consistency);

end.

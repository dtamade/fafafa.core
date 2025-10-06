{$mode objfpc}{$H+}
{$IFDEF FPC}
  {$IFDEF WINDOWS}
    {$APPTYPE CONSOLE}
  {$ENDIF}
{$ENDIF}

program test_hashmap_heaptrc;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.hashmap;

type
  TStringMap = specialize THashMap<string, string>;
  TIntMap = specialize THashMap<Integer, Integer>;
  TObjectMap = specialize THashMap<string, TObject>;

procedure TestBasicOperations;
var
  Map: TStringMap;
begin
  WriteLn('Testing basic operations...');
  Map := TStringMap.Create;
  try
    Map.AddOrAssign('key1', 'value1');
    Map.AddOrAssign('key2', 'value2');
    Map.AddOrAssign('key3', 'value3');
    
    if Map.ContainsKey('key1') then
      WriteLn('  [OK] ContainsKey works');
    
    Map.Remove('key2');
    
    if not Map.ContainsKey('key2') then
      WriteLn('  [OK] Remove works');
      
  finally
    Map.Free;
  end;
  WriteLn('  [OK] Basic operations test complete');
end;

procedure TestClearOperation;
var
  Map: TStringMap;
begin
  WriteLn('测试 Clear 操作...');
  Map := TStringMap.Create;
  try
    Map.AddOrAssign('a', 'A');
    Map.AddOrAssign('b', 'B');
    Map.AddOrAssign('c', 'C');
    Map.AddOrAssign('d', 'D');
    Map.AddOrAssign('e', 'E');
    
    Map.Clear;
    
    if Map.Count = 0 then
      WriteLn('  ✓ Clear 正常');
      
  finally
    Map.Free;
  end;
  WriteLn('  ✓ Clear 操作测试完成');
end;

procedure TestRehashing;
var
  Map: TIntMap;
  i: Integer;
begin
  WriteLn('测试 Rehash 操作（触发扩容）...');
  Map := TIntMap.Create;
  try
    // 插入足够多的元素以触发多次 rehash
    for i := 1 to 100 do
      Map.AddOrAssign(i, i * 10);
    
    if Map.Count = 100 then
      WriteLn('  ✓ Rehash 正常');
      
    // 删除一半元素
    for i := 1 to 50 do
      Map.Remove(i);
      
    if Map.Count = 50 then
      WriteLn('  ✓ 删除后计数正常');
      
  finally
    Map.Free;
  end;
  WriteLn('  ✓ Rehash 操作测试完成');
end;

procedure TestOverwriteKeys;
var
  Map: TStringMap;
begin
  WriteLn('测试键值覆盖...');
  Map := TStringMap.Create;
  try
    Map.AddOrAssign('key', 'value1');
    Map.AddOrAssign('key', 'value2');
    Map.AddOrAssign('key', 'value3');
    
    if Map.Count = 1 then
      WriteLn('  ✓ 覆盖键值计数正常');
      
  finally
    Map.Free;
  end;
  WriteLn('  ✓ 键值覆盖测试完成');
end;

procedure TestObjectValues;
var
  Map: TObjectMap;
  Obj1, Obj2, Obj3: TObject;
begin
  WriteLn('测试对象值（需要手动管理）...');
  Map := TObjectMap.Create;
  Obj1 := TObject.Create;
  Obj2 := TObject.Create;
  Obj3 := TObject.Create;
  try
    Map.AddOrAssign('obj1', Obj1);
    Map.AddOrAssign('obj2', Obj2);
    Map.AddOrAssign('obj3', Obj3);
    
    // 在删除前手动释放对象
    Obj2.Free;
    Map.Remove('obj2');
    
    if Map.Count = 2 then
      WriteLn('  ✓ 对象值操作正常');
      
  finally
    // 清理剩余对象
    Obj1.Free;
    Obj3.Free;
    Map.Free;
  end;
  WriteLn('  ✓ 对象值测试完成');
end;

procedure TestMultipleMaps;
var
  Map1, Map2, Map3: TStringMap;
begin
  WriteLn('测试多个 HashMap 实例...');
  Map1 := TStringMap.Create;
  Map2 := TStringMap.Create;
  Map3 := TStringMap.Create;
  try
    Map1.AddOrAssign('a', 'A1');
    Map2.AddOrAssign('b', 'B2');
    Map3.AddOrAssign('c', 'C3');
    
    if (Map1.Count = 1) and (Map2.Count = 1) and (Map3.Count = 1) then
      WriteLn('  ✓ 多实例操作正常');
      
  finally
    Map1.Free;
    Map2.Free;
    Map3.Free;
  end;
  WriteLn('  ✓ 多实例测试完成');
end;

procedure TestStressOperations;
var
  Map: TStringMap;
  i: Integer;
  Key, Value: string;
begin
  WriteLn('测试压力操作（大量插入/删除）...');
  Map := TStringMap.Create;
  try
    // 大量插入
    for i := 1 to 1000 do
    begin
      Key := 'key' + IntToStr(i);
      Value := 'value' + IntToStr(i);
      Map.AddOrAssign(Key, Value);
    end;
    
    if Map.Count = 1000 then
      WriteLn('  ✓ 大量插入正常');
    
    // 删除偶数键
    for i := 2 to 1000 do
      if (i mod 2) = 0 then
        Map.Remove('key' + IntToStr(i));
    
    if Map.Count = 500 then
      WriteLn('  ✓ 大量删除正常');
    
    // 清空
    Map.Clear;
    
    if Map.Count = 0 then
      WriteLn('  ✓ 清空后正常');
      
  finally
    Map.Free;
  end;
  WriteLn('  ✓ 压力操作测试完成');
end;

begin
  WriteLn('========================================');
  WriteLn('HashMap 内存泄漏检测测试');
  WriteLn('========================================');
  WriteLn;
  
  try
    TestBasicOperations;
    WriteLn;
    
    TestClearOperation;
    WriteLn;
    
    TestRehashing;
    WriteLn;
    
    TestOverwriteKeys;
    WriteLn;
    
    TestObjectValues;
    WriteLn;
    
    TestMultipleMaps;
    WriteLn;
    
    TestStressOperations;
    WriteLn;
    
    WriteLn('========================================');
    WriteLn('所有测试完成！');
    WriteLn('========================================');
    WriteLn;
    WriteLn('HeapTrc 将自动输出内存分配报告。');
    WriteLn('如果没有泄漏，应显示: "0 unfreed memory blocks"');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
